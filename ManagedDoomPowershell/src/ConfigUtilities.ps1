class ConfigUtilities {
    # Static array equivalent to 'private static readonly string[] iwadNames'
    static [string[]] $iwadNames = @(
        "DOOM2.WAD",
        "PLUTONIA.WAD",
        "TNT.WAD",
        "DOOM.WAD",
        "DOOM1.WAD",
        "FREEDOOM2.WAD",
        "FREEDOOM1.WAD"
    )

    # Equivalent to 'public static string GetExeDirectory()'
    static [string] GetExeDirectory() {
        $basePath = $PSScriptRoot ?? (Get-Location).Path

        if ([string]::IsNullOrWhiteSpace($basePath)) {
            return (Get-Location).Path
        }

        if ([System.IO.Path]::GetFileName($basePath) -eq 'PowershellHandler') {
            return [System.IO.Directory]::GetParent($basePath).FullName
        }

        return $basePath
    }

    # Equivalent to 'public static string GetConfigPath()'
    static [string] GetConfigPath() {
        return [System.IO.Path]::Combine([ConfigUtilities]::GetExeDirectory(), "managed-doom.cfg")
    }

    # Equivalent to 'public static string GetDefaultIwadPath()'
    static [string] GetDefaultIwadPath() {
        $exeDirectory = [ConfigUtilities]::GetExeDirectory()

        $configIwadNamesEnumerable = [ConfigUtilities]::iwadNames
        if ($null -ne $configIwadNamesEnumerable) {
            $configIwadNamesEnumerator = $configIwadNamesEnumerable.GetEnumerator()
            for (; $configIwadNamesEnumerator.MoveNext(); ) {
                $name = $configIwadNamesEnumerator.Current
                $path = [System.IO.Path]::Combine($exeDirectory, $name)
                if (Test-Path $path) {
                    return $path
                }

            }
        }

        $currentDirectory = Get-Location
        $configIwadNamesEnumerable = [ConfigUtilities]::iwadNames
        if ($null -ne $configIwadNamesEnumerable) {
            $configIwadNamesEnumerator = $configIwadNamesEnumerable.GetEnumerator()
            for (; $configIwadNamesEnumerator.MoveNext(); ) {
                $name = $configIwadNamesEnumerator.Current
                $path = [System.IO.Path]::Combine($currentDirectory, $name)
                if (Test-Path $path) {
                    return $path
                }

            }
        }

        throw "No IWAD was found!"
    }

    # Equivalent to 'public static bool IsIwad(string path)'
    static [bool] IsIwad([string] $path) {
        $name = ([System.IO.Path]::GetFileName($path)).ToUpper()
        return [ConfigUtilities]::iwadNames -contains $name
    }

    # Equivalent to 'public static string[] GetWadPaths(CommandLineArgs args)'
    static [string[]] GetWadPaths($args) {
        $wadPaths = @()
        $mArgs = [CommandLineArgs]::new($args)

        if ($mArgs.iwad.Present) {
            $wadPaths += $mArgs.iwad.Value
        } else {
            $wadPaths += [ConfigUtilities]::GetDefaultIwadPath()
        }

        if ($mArgs.file.Present) {
            $wadPaths += $mArgs.file.Value
        }

        return $wadPaths
    }
}
