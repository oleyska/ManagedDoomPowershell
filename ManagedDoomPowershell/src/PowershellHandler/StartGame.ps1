##
## Copyright (C) 2026 Oleyska
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##

#Requires -Version 7.1
$rootpath = "C:/Code/Doom Powershell/"
if ($IsLinux)
    {
        $rootpath = "/home/ole/Code/Doom Powershell/"
    }

if ([string]::IsNullOrWhiteSpace($PSCommandPath) -eq $false) #we are calling it externally
    {
        if ($PSVersionTable.Platform -eq 'Unix')
            {
            $rootpath = $PSCommandPath.replace('/src/PowershellHandler/StartGame.ps1','')
            }
        else { #Windows
            $rootpath = $PSCommandPath.replace('\src\PowershellHandler\StartGame.ps1','')

        }
    }


function Invoke-MacMainThreadHost {
    param(
        [string] $RootPath,
        [string[]] $GameArgs
    )

    $hostProject = Join-Path $RootPath 'src/PowershellHandler/MacMainHost/MacMainHost.csproj'
    $hostSource = Join-Path $RootPath 'src/PowershellHandler/MacMainHost/MacMainHost.cs'
    $targetFramework = 'net8.0'
    $publishRoot = Join-Path $RootPath ".appdata/MacMainHost/$targetFramework"
    $baseOutputRoot = Join-Path $RootPath '.appdata/MacMainHost/bin/'
    $intermediateRoot = Join-Path $RootPath '.appdata/MacMainHost/obj/'
    $hostPath = Join-Path $publishRoot 'MacMainHost'
    $hostVersion = '2026-04-16-pshome-host-v2'
    $hostVersionPath = Join-Path $publishRoot 'MacMainHost.version'
    $powerShellRefRoot = Join-Path $PSHOME 'ref'
    $hostRefRoot = Join-Path $publishRoot 'ref'

    $needsBuild = -not (Test-Path -LiteralPath $hostPath)
    if (-not $needsBuild) {
        $hostItem = Get-Item -LiteralPath $hostPath
        $projectItem = Get-Item -LiteralPath $hostProject
        $sourceItem = Get-Item -LiteralPath $hostSource
        $needsBuild = $hostItem.LastWriteTimeUtc -lt $projectItem.LastWriteTimeUtc -or $hostItem.LastWriteTimeUtc -lt $sourceItem.LastWriteTimeUtc
        if (-not $needsBuild) {
            $needsBuild = -not (Test-Path -LiteralPath $hostVersionPath) -or (Get-Content -LiteralPath $hostVersionPath -Raw -ErrorAction SilentlyContinue).Trim() -ne $hostVersion
        }
    }

    if ($needsBuild) {
        $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
        if ($null -eq $dotnet) {
            throw "macOS main-thread host needs the .NET SDK so it can build '$hostProject'."
        }

        New-Item -ItemType Directory -Force -Path $publishRoot | Out-Null
        & $dotnet.Source publish $hostProject --configuration Release --nologo --output $publishRoot "/p:TargetFramework=$targetFramework" "/p:BaseOutputPath=$baseOutputRoot" "/p:BaseIntermediateOutputPath=$intermediateRoot"
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        Set-Content -LiteralPath $hostVersionPath -Value $hostVersion -Encoding UTF8
    }

    if (-not (Test-Path -LiteralPath (Join-Path $hostRefRoot 'System.Runtime.dll'))) {
        if (-not (Test-Path -LiteralPath (Join-Path $powerShellRefRoot 'System.Runtime.dll'))) {
            throw "Could not find PowerShell reference assemblies under '$powerShellRefRoot'."
        }

        New-Item -ItemType Directory -Force -Path $hostRefRoot | Out-Null
        $refItems = Get-ChildItem -LiteralPath $powerShellRefRoot -Force
        for ($i = 0; $i -lt $refItems.Count; $i++) {
            Copy-Item -LiteralPath $refItems[$i].FullName -Destination $hostRefRoot -Recurse -Force
        }
    }

    $previousRollForward = $env:DOTNET_ROLL_FORWARD
    $previousPSHome = $env:PSHOME
    $env:DOTNET_ROLL_FORWARD = 'LatestMajor'
    $env:MANAGED_DOOM_PS_HOME = $PSHOME
    $env:PSHOME = $PSHOME
    try {
        & $hostPath $PSCommandPath @GameArgs
        exit $LASTEXITCODE
    } finally {
        if ($null -eq $previousRollForward) {
            Remove-Item Env:/DOTNET_ROLL_FORWARD -ErrorAction SilentlyContinue
        } else {
            $env:DOTNET_ROLL_FORWARD = $previousRollForward
        }
        Remove-Item Env:/MANAGED_DOOM_PS_HOME -ErrorAction SilentlyContinue
        if ($null -eq $previousPSHome) {
            Remove-Item Env:/PSHOME -ErrorAction SilentlyContinue
        } else {
            $env:PSHOME = $previousPSHome
        }
    }
}

# Cocoa/GLFW needs the process main thread on macOS. Windows and Linux keep the existing pwsh path.
if ($IsMacOS -and -not $env:MANAGED_DOOM_MAC_MAIN_THREAD) {
    $macRootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Invoke-MacMainThreadHost -RootPath $macRootPath -GameArgs $args
}

if (-not $env:MANAGED_DOOM_FRESH_SESSION) {
    $env:MANAGED_DOOM_FRESH_SESSION = '1'
    try {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
        exit $LASTEXITCODE
    } finally {
        Remove-Item Env:/MANAGED_DOOM_FRESH_SESSION -ErrorAction SilentlyContinue
    }
}

#set root path as some subscripts may change directory.
#add warning if Windows check for RealtimeProtection.
[Console]::WriteLine("Loading DLL's into Powershell session")
Set-Location "$rootpath/src/PowershellHandler"
. ./PreReqs.ps1
[Console]::WriteLine("Loading Standalone Classes")
Set-Location "$rootpath/src/PowershellHandler"
. ./ClassManager.ps1
Set-Location "$rootpath/src/PowershellHandler"
. ./Bundler.ps1
[Console]::WriteLine("Creating Powershell Bundle")
$filelist = import-csv ./SBfiles.csv -Delimiter '|' -Encoding utf8
#Create a bundle cause circular class definitions in different files is unsupported.
bundle -sbfilelist $filelist -bundlefilePath (Join-Path $rootpath 'src/PowershellHandler/sb-bundle.ps1')
[Console]::WriteLine("Bundle created, Loading bundle")
. ./sb-bundle.ps1
Set-Location "$rootpath/src/PowershellHandler"

start-sleep 1s
Remove-Item sb-bundle.ps1
Set-Location $rootpath

[Console]::WriteLine("Starting Game")
$SilkDoom = [silkdoom]::new($cmdargs)
$SilkDoom.run()
