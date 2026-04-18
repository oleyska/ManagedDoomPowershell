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

class DummyFlatLookup : IFlatLookup {
    [Flat[]]$flatList
    [System.Collections.Generic.Dictionary[string, Flat]]$nameToFlat
    [System.Collections.Generic.Dictionary[string, int]]$nameToNumber
    [int]$skyFlatNumber
    [Flat]$skyFlat

    DummyFlatLookup([Wad]$wad) {
        $firstFlat = $wad.GetLumpNumber("F_START") + 1
        $lastFlat = $wad.GetLumpNumber("F_END") - 1
        $count = $lastFlat - $firstFlat + 1

        $this.flatList = New-Object Flat[] $count
        $this.nameToFlat = New-Object 'System.Collections.Generic.Dictionary[string, Flat]'
        $this.nameToNumber = New-Object 'System.Collections.Generic.Dictionary[string, int]'

        for ($lump = $firstFlat; $lump -le $lastFlat; $lump++) {
            if ($wad.GetLumpSize($lump) -ne 4096) {
                continue
            }

            $number = $lump - $firstFlat
            $name = $wad.LumpInfos[$lump].Name
            $flat = if ($name -ne "F_SKY1") { [DummyData]::GetFlat() } else { [DummyData]::GetSkyFlat() }

            $this.flatList[$number] = $flat
            $this.nameToFlat[$name] = $flat
            $this.nameToNumber[$name] = $number
        }

        $this.skyFlatNumber = $this.nameToNumber["F_SKY1"]
        $this.skyFlat = $this.nameToFlat["F_SKY1"]
    }

    [int] GetNumber([string]$name) {
        if ($this.nameToNumber.ContainsKey($name)) {
            return $this.nameToNumber[$name]
        } else {
            return -1
        }
    }

    [System.Collections.IEnumerator] GetEnumerator() {
        return ($this.flatList).GetEnumerator()
    }

    [System.Collections.IEnumerator] IEnumerable_GetEnumerator() {
        return $this.flatList.GetEnumerator()
    }

}