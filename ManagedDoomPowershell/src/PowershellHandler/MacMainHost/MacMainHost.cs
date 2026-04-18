using System.Collections;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Loader;

namespace ManagedDoom.PowerShellHost;

internal static class MacMainHost
{
    private const string FreshSessionEnv = "MANAGED_DOOM_FRESH_SESSION";
    private const string MainThreadEnv = "MANAGED_DOOM_MAC_MAIN_THREAD";
    private const string PowerShellHomeEnv = "MANAGED_DOOM_PS_HOME";

    public static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("MacMainHost needs the StartGame.ps1 path as its first argument.");
            return 64;
        }

        var scriptPath = Path.GetFullPath(args[0]);
        if (!File.Exists(scriptPath))
        {
            Console.Error.WriteLine($"StartGame.ps1 was not found: {scriptPath}");
            return 66;
        }

        var powerShellHome = Environment.GetEnvironmentVariable(PowerShellHomeEnv);
        if (string.IsNullOrWhiteSpace(powerShellHome))
        {
            powerShellHome = Environment.GetEnvironmentVariable("PSHOME");
        }

        if (string.IsNullOrWhiteSpace(powerShellHome))
        {
            Console.Error.WriteLine("PowerShell home was not provided. Set MANAGED_DOOM_PS_HOME before launching MacMainHost.");
            return 69;
        }

        powerShellHome = Path.GetFullPath(powerShellHome);
        var automationPath = Path.Combine(powerShellHome, "System.Management.Automation.dll");
        if (!File.Exists(automationPath))
        {
            Console.Error.WriteLine($"System.Management.Automation.dll was not found: {automationPath}");
            return 69;
        }

        AppContext.SetData("APP_CONTEXT_BASE_DIRECTORY", EnsureTrailingDirectorySeparator(powerShellHome));
        Environment.SetEnvironmentVariable(FreshSessionEnv, "1");
        Environment.SetEnvironmentVariable(MainThreadEnv, "1");
        Environment.SetEnvironmentVariable(PowerShellHomeEnv, powerShellHome);
        Environment.SetEnvironmentVariable("PSHOME", powerShellHome);

        RegisterPowerShellAssemblyResolvers(powerShellHome);

        try
        {
            return InvokePowerShell(scriptPath, args.Skip(1).ToArray(), automationPath, powerShellHome);
        }
        catch (TargetInvocationException ex) when (ex.InnerException is not null)
        {
            Console.Error.WriteLine(ex.InnerException);
            return 1;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return 1;
        }
    }

    private static string EnsureTrailingDirectorySeparator(string path)
    {
        return Path.EndsInDirectorySeparator(path) ? path : path + Path.DirectorySeparatorChar;
    }

    private static void RegisterPowerShellAssemblyResolvers(string powerShellHome)
    {
        AssemblyLoadContext.Default.Resolving += (context, assemblyName) =>
        {
            if (assemblyName.Name is null)
            {
                return null;
            }

            var candidate = Path.Combine(powerShellHome, assemblyName.Name + ".dll");
            return File.Exists(candidate) ? context.LoadFromAssemblyPath(candidate) : null;
        };

        AssemblyLoadContext.Default.ResolvingUnmanagedDll += (_, libraryName) =>
        {
            foreach (var candidate in GetNativeLibraryCandidates(powerShellHome, libraryName))
            {
                if (File.Exists(candidate))
                {
                    return NativeLibrary.Load(candidate);
                }
            }

            return IntPtr.Zero;
        };
    }

    private static IEnumerable<string> GetNativeLibraryCandidates(string powerShellHome, string libraryName)
    {
        yield return Path.Combine(powerShellHome, libraryName);
        yield return Path.Combine(powerShellHome, libraryName + ".dylib");
        yield return Path.Combine(powerShellHome, "lib" + libraryName + ".dylib");
    }

    private static int InvokePowerShell(string scriptPath, string[] scriptArgs, string automationPath, string powerShellHome)
    {
        var automationAssembly = AssemblyLoadContext.Default.LoadFromAssemblyPath(automationPath);
        var runspaceFactoryType = GetRequiredType(automationAssembly, "System.Management.Automation.Runspaces.RunspaceFactory");
        var runspaceType = GetRequiredType(automationAssembly, "System.Management.Automation.Runspaces.Runspace");
        var threadOptionsType = GetRequiredType(automationAssembly, "System.Management.Automation.Runspaces.PSThreadOptions");
        var powerShellType = GetRequiredType(automationAssembly, "System.Management.Automation.PowerShell");

        using var runspace = (IDisposable)InvokeStatic(runspaceFactoryType, "CreateRunspace");
        var useCurrentThread = Enum.Parse(threadOptionsType, "UseCurrentThread");
        runspaceType.GetProperty("ThreadOptions")!.SetValue(runspace, useCurrentThread);
        runspaceType.GetMethod("Open", Type.EmptyTypes)!.Invoke(runspace, null);

        using (var setupPowerShell = (IDisposable)InvokeStatic(powerShellType, "Create"))
        {
            powerShellType.GetProperty("Runspace")!.SetValue(setupPowerShell, runspace);
            powerShellType.GetMethod("AddScript", new[] { typeof(string) })!.Invoke(
                setupPowerShell,
                new object[]
                {
                    "$env:MANAGED_DOOM_FRESH_SESSION = '1'; " +
                    "$env:MANAGED_DOOM_MAC_MAIN_THREAD = '1'; " +
                    "$env:MANAGED_DOOM_PS_HOME = " + ToPowerShellSingleQuotedString(powerShellHome) + "; " +
                    "$env:PSHOME = " + ToPowerShellSingleQuotedString(powerShellHome)
                });

            var setupResults = GetPowerShellInvokeMethod(powerShellType).Invoke(setupPowerShell, null);
            WriteOutput(setupResults);

            if ((bool)powerShellType.GetProperty("HadErrors")!.GetValue(setupPowerShell)!)
            {
                WritePowerShellErrors(setupPowerShell, powerShellType);
                return 1;
            }
        }

        using var powerShell = (IDisposable)InvokeStatic(powerShellType, "Create");
        powerShellType.GetProperty("Runspace")!.SetValue(powerShell, runspace);

        powerShellType.GetMethod("AddCommand", new[] { typeof(string) })!.Invoke(powerShell, new object[] { scriptPath });

        var addArgument = powerShellType.GetMethod("AddArgument", new[] { typeof(object) })!;
        foreach (var arg in scriptArgs)
        {
            addArgument.Invoke(powerShell, new object[] { arg });
        }

        var results = GetPowerShellInvokeMethod(powerShellType).Invoke(powerShell, null);
        WriteOutput(results);

        if ((bool)powerShellType.GetProperty("HadErrors")!.GetValue(powerShell)!)
        {
            WritePowerShellErrors(powerShell, powerShellType);
            return 1;
        }

        return 0;
    }

    private static string ToPowerShellSingleQuotedString(string value)
    {
        return "'" + value.Replace("'", "''") + "'";
    }

    private static MethodInfo GetPowerShellInvokeMethod(Type powerShellType)
    {
        return powerShellType.GetMethods()
            .Single(method => method.Name == "Invoke" && !method.IsGenericMethodDefinition && method.GetParameters().Length == 0);
    }

    private static Type GetRequiredType(Assembly assembly, string typeName)
    {
        return assembly.GetType(typeName, throwOnError: true)!;
    }

    private static object InvokeStatic(Type type, string methodName)
    {
        return type.GetMethod(methodName, Type.EmptyTypes)!.Invoke(null, null)!;
    }

    private static void WriteOutput(object? results)
    {
        if (results is not IEnumerable items)
        {
            return;
        }

        foreach (var item in items)
        {
            if (item is not null)
            {
                Console.WriteLine(item);
            }
        }
    }

    private static void WritePowerShellErrors(object powerShell, Type powerShellType)
    {
        var streams = powerShellType.GetProperty("Streams")!.GetValue(powerShell);
        var errors = streams!.GetType().GetProperty("Error")!.GetValue(streams);
        if (errors is not IEnumerable items)
        {
            return;
        }

        foreach (var item in items)
        {
            Console.Error.WriteLine(item);
        }
    }
}
