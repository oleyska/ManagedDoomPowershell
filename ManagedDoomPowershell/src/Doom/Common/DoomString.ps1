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

class DoomString {
    static [hashtable] $ValueTable = @{}
    static [hashtable] $NameTable = @{}

    [string] $Original
    [string] $Replaced

    DoomString([string] $original) {
        $this.Original = $original
        $this.Replaced = $original

        if (-not [DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original] = $this
        }
    }

    DoomString([string] $name, [string] $original) {
        $this.Original = $original
        $this.Replaced = $original

        if (-not [DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original] = $this
        }

        [DoomString]::NameTable[$name] = $this
    }

    [string] ToString() {
        return $this.Replaced
    }

    [char] Get([int] $index) {
        return $this.Replaced[$index]
    }

    static [void] ReplaceByValue([string] $original, [string] $replaced) {
        if ([DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original].Replaced = $replaced
        }
    }

    static [void] ReplaceByName([string] $name, [string] $value) {
        if ([DoomString]::NameTable.ContainsKey($name)) {
            [DoomString]::NameTable[$name].Replaced = $value
        }
    }
}