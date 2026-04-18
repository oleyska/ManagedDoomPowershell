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

class Reject {
    [byte[]]$data
    [int]$sectorCount

    Reject([byte[]]$data, [int]$sectorCount) {
        # If the reject table is too small, expand it to avoid crash.
        # https://doomwiki.org/wiki/Reject#Reject_Overflow
        $expectedLength = [math]::Ceiling($sectorCount * $sectorCount / 8.0)
        if ($data.Length -lt $expectedLength) {
            [Array]::Resize([ref]$data, $expectedLength)
        }

        $this.data = $data
        $this.sectorCount = $sectorCount
    }

    [Reject] static FromWad([Wad]$wad, [int]$lump, [Sector[]]$sectors) {
        return [Reject]::new($wad.ReadLump($lump), $sectors.Length)
    }

    [bool] Check([Sector]$sector1, [Sector]$sector2) {
        $s1 = $sector1.Number
        $s2 = $sector2.Number

        $p = $s1 * $this.sectorCount + $s2
        $byteIndex = [math]::Floor($p / 8)
        $bitIndex = 1 -shl ($p % 8)

        return (($this.data[$byteIndex] -band $bitIndex) -ne 0)
    }
}