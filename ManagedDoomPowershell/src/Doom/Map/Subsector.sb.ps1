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

class Subsector {
    static [int]$dataSize = 4

    [Sector]$sector
    [int]$segCount
    [int]$firstSeg

    Subsector([Sector]$sector, [int]$segCount, [int]$firstSeg) {
        $this.sector = $sector
        $this.segCount = $segCount
        $this.firstSeg = $firstSeg
    }

    static [Subsector] FromData([byte[]]$data, [int]$offset, [Seg[]]$segs) {
        $mSegCount = [BitConverter]::ToInt16($data, $offset)
        $firstSegNumber = [BitConverter]::ToInt16($data, $offset + 2)

        return [Subsector]::new(
            $segs[$firstSegNumber].SideDef.Sector,
            $mSegCount,
            $firstSegNumber
        )
    }

    static [Subsector[]] FromWad([Wad]$wad, [int]$lump, [Seg[]]$segs) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Subsector]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Subsector]::dataSize
        $subsectors = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [Subsector]::dataSize * $i
            $subsectors += [Subsector]::FromData($data, $offset, $segs)
        }

        return $subsectors
    }

}