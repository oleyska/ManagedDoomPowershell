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

#needs [IFlatLookup]
class FlatLookup : IFlatLookup{
    [Flat[]]$Flats
    [hashtable]$NameToFlat
    [hashtable]$NameToNumber
    [int]$SkyFlatNumber
    [Flat]$SkyFlat

    FlatLookup([wad]$wad) {
        $fStartCount = [FlatLookup]::CountLump($wad, "F_START")
        $fEndCount = [FlatLookup]::CountLump($wad, "F_END")
        $ffStartCount = [FlatLookup]::CountLump($wad, "FF_START")
        $ffEndCount = [FlatLookup]::CountLump($wad, "FF_END")

        $standard = ($fStartCount -eq 1 -and $fEndCount -eq 1 -and $ffStartCount -eq 0 -and $ffEndCount -eq 0)
        $customFlatTrick = ($fStartCount -eq 1 -and $fEndCount -ge 2)
        $deutexMerge = ($fStartCount + $ffStartCount -ge 2 -and $fEndCount + $ffEndCount -ge 2)

        if ($standard -or $customFlatTrick) {
            $this.InitStandard($wad)
        } elseif ($deutexMerge) {
            $this.InitDeuTexMerge($wad)
        } else {
            throw "Failed to read flats."
        }
    }

    [void] InitStandard([wad]$wad) {
        try {
            [Console]::Write("Load flats: ")

            $firstFlat = $wad.GetLumpNumber("F_START") + 1
            $lastFlat = $wad.GetLumpNumber("F_END") - 1
            $count = $lastFlat - $firstFlat + 1

            $this.Flats = New-Object Flat[] $count
            $this.NameToFlat = @{}
            $this.NameToNumber = @{}

            for ($lump = $firstFlat; $lump -le $lastFlat; $lump++) {
                if ($wad.GetLumpSize($lump) -ne 4096) { continue }

                $number = $lump - $firstFlat
                $name = $wad.LumpInfos[$lump].Name
                $flat = [Flat]::new($name, $wad.ReadLump($lump))

                $this.Flats[$number] = $flat
                $this.NameToFlat[$name] = $flat
                $this.NameToNumber[$name] = $number
            }

            $this.SkyFlatNumber = $this.NameToNumber["F_SKY1"]
            $this.SkyFlat = $this.NameToFlat["F_SKY1"]

            [Console]::WriteLine("OK ($($this.NameToFlat.Count) flats)")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }

    [void] InitDeuTexMerge([wad]$wad) {
        try {
            [Console]::Write("Load flats: ")

            $allFlats = @()
            $flatZone = $false

            for ($lump = 0; $lump -lt $wad.LumpInfos.Count; $lump++) {
                $name = $wad.LumpInfos[$lump].Name
                if ($flatZone) {
                    if ($name -eq "F_END" -or $name -eq "FF_END") {
                        $flatZone = $false
                    } else {
                        $allFlats += $lump
                    }
                } elseif ($name -eq "F_START" -or $name -eq "FF_START") {
                    $flatZone = $true
                }
            }

            [Array]::Reverse($allFlats)

            $dupCheck = @{}
            $distinctFlats = @()
            $flatLumpsEnumerable = $allFlats
            if ($null -ne $flatLumpsEnumerable) {
                $flatLumpsEnumerator = $flatLumpsEnumerable.GetEnumerator()
                for (; $flatLumpsEnumerator.MoveNext(); ) {
                    $lump = $flatLumpsEnumerator.Current
                    if (-not $dupCheck.ContainsKey($wad.LumpInfos[$lump].Name)) {
                        $distinctFlats += $lump
                        $dupCheck[$wad.LumpInfos[$lump].Name] = $true
                    }

                }
            }
            [Array]::Reverse($distinctFlats)

            $this.Flats = New-Object Flat[] $distinctFlats.Count
            $this.NameToFlat = @{}
            $this.NameToNumber = @{}

            for ($number = 0; $number -lt $distinctFlats.Count; $number++) {
                $lump = $distinctFlats[$number]

                if ($wad.GetLumpSize($lump) -ne 4096) { continue }

                $name = $wad.LumpInfos[$lump].Name
                $flat = [Flat]::new($name, $wad.ReadLump($lump))

                $this.Flats[$number] = $flat
                $this.NameToFlat[$name] = $flat
                $this.NameToNumber[$name] = $number
            }

            $this.SkyFlatNumber = $this.NameToNumber["F_SKY1"]
            $this.SkyFlat = $this.NameToFlat["F_SKY1"]

            [Console]::WriteLine("OK ($($this.NameToFlat.Count) flats)")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }

    [int] GetNumber([string]$name) {
        return $(if ($this.NameToNumber.ContainsKey($name)) { $this.NameToNumber[$name] } else { -1 })
    }

    [Flat[]] GetEnumerator() {
        return $this.Flats
    }

    static [int] CountLump([wad]$wad, [string]$name) {
        return ($wad.LumpInfos | Where-Object { $_.Name -eq $name }).Count
    }

    [int] get_Count() {
        return $this.Flats.Length
    }

    [Flat] get_Item([int]$num) {
        return $this.Flats[$num]
    }

    [Flat] get_Item([string]$name) {
        return $this.NameToFlat[$name]
    }

    [int] get_SkyFlatNumber() {
        return $this.SkyFlatNumber
    }

    [Flat] get_SkyFlat() {
        return $this.SkyFlat
    }
}
