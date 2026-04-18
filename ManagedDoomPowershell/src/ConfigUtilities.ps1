##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
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

class ConfigUtilities {
    static [string[]] $iwadNames = @(
        "DOOM2.WAD",
        "PLUTONIA.WAD",
        "TNT.WAD",
        "DOOM.WAD",
        "DOOM1.WAD",
        "FREEDOOM2.WAD",
        "FREEDOOM1.WAD"
    )


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

    static [string] GetConfigPath() {
        return [System.IO.Path]::Combine([ConfigUtilities]::GetExeDirectory(), "managed-doom.cfg")
    }

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

    static [bool] IsIwad([string] $path) {
        $name = ([System.IO.Path]::GetFileName($path)).ToUpper()
        return [ConfigUtilities]::iwadNames -contains $name
    }

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
