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

enum DoomMouseButton {
    Unknown = -1
    Mouse1 = 0
    Mouse2
    Mouse3
    Mouse4
    Mouse5
    Count
}

class DoomMouseButtonEx {
    hidden DoomMouseButtonEx() { }

    static [string] ToString([DoomMouseButton] $button) {
        switch ($button) {
            'Mouse1' { return "mouse1" }
            'Mouse2' { return "mouse2" }
            'Mouse3' { return "mouse3" }
            'Mouse4' { return "mouse4" }
            'Mouse5' { return "mouse5" }
        }
        return "unknown"
    }

    static [DoomMouseButton] Parse([string] $value) {
        switch ($value.ToLower()) {
            "mouse1" { return [DoomMouseButton]::Mouse1 }
            "mouse2" { return [DoomMouseButton]::Mouse2 }
            "mouse3" { return [DoomMouseButton]::Mouse3 }
            "mouse4" { return [DoomMouseButton]::Mouse4 }
            "mouse5" { return [DoomMouseButton]::Mouse5 }
        }
        return [DoomMouseButton]::Unknown
    }
}