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

# needs [IUserInput]

class NullUserInput : IUserInput {
    static [NullUserInput]$Instance

    NullUserInput() { }

    static [NullUserInput] GetInstance() {
        if ($null -eq [NullUserInput]::Instance) {
            [NullUserInput]::Instance = [NullUserInput]::new()
        }
        return [NullUserInput]::Instance
    }

    [void] PollEvents() { }

    [void] BuildTicCmd([TicCmd]$cmd) {
        $cmd.Clear()
    }

    [void] Reset() { }

    [void] GrabMouse() { }

    [void] ReleaseMouse() { }

    [int] get_MaxMouseSensitivity() {
        return 9
    }

    [int] get_MouseSensitivity() {
        return 3
    }

    [void] set_MouseSensitivity([int]$value) { }
}