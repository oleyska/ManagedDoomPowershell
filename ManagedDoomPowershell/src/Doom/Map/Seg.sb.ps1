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

class Seg {
    static [int]$dataSize = 12

    [Vertex]$vertex1
    [Vertex]$vertex2
    [Fixed]$offset
    [Angle]$angle
    [SideDef]$sideDef
    [LineDef]$lineDef
    [Sector]$frontSector
    [Sector]$backSector

    Seg([Vertex]$vertex1, [Vertex]$vertex2, [Fixed]$offset, [Angle]$angle, [SideDef]$sideDef, [LineDef]$lineDef, [Sector]$frontSector, [Sector]$backSector) {
        $this.vertex1 = $vertex1
        $this.vertex2 = $vertex2
        $this.offset = $offset
        $this.angle = $angle
        $this.sideDef = $sideDef
        $this.lineDef = $lineDef
        $this.frontSector = $frontSector
        $this.backSector = $backSector
    }

    static [Seg] FromData([byte[]]$data, [int]$offset, [Vertex[]]$vertices, [LineDef[]]$lines) {
        $vertex1Number = [BitConverter]::ToInt16($data, $offset)
        $vertex2Number = [BitConverter]::ToInt16($data, $offset + 2)
        $mAngle = [BitConverter]::ToInt16($data, $offset + 4)
        $lineNumber = [BitConverter]::ToInt16($data, $offset + 6)
        $side = [BitConverter]::ToInt16($data, $offset + 8)
        $segOffset = [BitConverter]::ToInt16($data, $offset + 10)

        $mLineDef = $lines[$lineNumber]
        $frontSide = if ($side -eq 0) { $mLineDef.FrontSide } else { $mLineDef.BackSide }
        $backSide = if ($side -eq 0) { $mLineDef.BackSide } else { $mLineDef.FrontSide }

        return [Seg]::new(
            $vertices[$vertex1Number],
            $vertices[$vertex2Number],
            [Fixed]::FromInt($segOffset),
            [Angle]::new(([uint32]($mAngle -band 0xFFFF)) -shl 16),
            $frontSide,
            $mLineDef,
            $frontSide.Sector,
            $(if (($mLineDef.Flags -band [LineFlags]::TwoSided) -ne 0) { $backSide.Sector } else { $null })
        )
    }

    static [Seg[]] FromWad([Wad]$wad, [int]$lump, [Vertex[]]$vertices, [LineDef[]]$lines) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Seg]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Seg]::dataSize
        $segs = @()

        for ($i = 0; $i -lt $count; $i++) {
            $mOffset = [Seg]::dataSize * $i
            $segs += [Seg]::FromData($data, $mOffset, $vertices, $lines)
        }

        return $segs
    }
}
