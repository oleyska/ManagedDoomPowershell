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

class SilkProgram {
    static [void] Main([string[]]$args) {
        [System.Console]::ForegroundColor = "White"
        [System.Console]::BackgroundColor = "DarkGreen"
        [Console]::WriteLine([ApplicationInfo]::Title)
        [System.Console]::ResetColor()

        try {
            $quitMessage = $null
            # $app = [SilkDoom]::new([CommandLineArgs]$($mArgs)) SHOULD have been the right way, powershell is stupid...
            $mArgs = [CommandLineArgs]::new($args)
            $app = [SilkDoom]::new($mArgs)
            

            try {
                $app.Run()
                $quitMessage = $app.QuitMessage
            } finally {
                $app.Dispose()
            }

            if ($null -ne $quitMessage) {
                [System.Console]::ForegroundColor = "Green"
                [Console]::WriteLine($quitMessage)
                [System.Console]::ResetColor()
                [Console]::WriteLine("Press any key to exit...")
                [System.Console]::ReadKey()
            }
        } catch {
            [System.Console]::ForegroundColor = "Red"
            [Console]::WriteLine($_.Exception.ToString())
            [System.Console]::ResetColor()
            [Console]::WriteLine("Press any key to exit...")
            [System.Console]::ReadKey()
        }
    }
}