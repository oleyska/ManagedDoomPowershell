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

class IUserInput {
    [void] PollEvents() {
        throw "Not Implemented"
    }

    [void] BuildTicCmd([TicCmd]$cmd) {
        throw "Not Implemented"
    }

    [void] Reset() {
        throw "Not Implemented"
    }

    [void] GrabMouse() {
        throw "Not Implemented"
    }

    [void] ReleaseMouse() {
        throw "Not Implemented"
    }

    [int] get_MaxMouseSensitivity() {
        throw "Not Implemented"
    }

    [int] get_MouseSensitivity() {
        throw "Not Implemented"
    }

    [void] set_MouseSensitivity([int]$value) {
        throw "Not Implemented"
    }
}