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

class LineDef {
    static [int]$dataSize = 14

    [Vertex]$vertex1
    [Vertex]$vertex2
    [Fixed]$dx
    [Fixed]$dy
    [LineFlags]$flags
    [int]$special
    [short]$tag
    [SideDef]$frontSide
    [SideDef]$backSide
    [Fixed[]]$boundingBox
    [SlopeType]$slopeType
    [Sector]$frontSector
    [Sector]$backSector
    [int]$validCount
    [Thinker]$specialData
    [Mobj]$soundOrigin

    LineDef(
        [Vertex]$vertex1,
        [Vertex]$vertex2,
        [LineFlags]$flags,
        [int]$special,
        [short]$tag,
        [SideDef]$frontSide,
        [SideDef]$backSide
    ) {
        $this.vertex1 = $vertex1
        $this.vertex2 = $vertex2
        $this.flags = $flags
        $this.special = $special
        $this.tag = $tag
        $this.frontSide = $frontSide
        $this.backSide = $backSide

        $this.dx = $vertex2.X - $vertex1.X
        $this.dy = $vertex2.Y - $vertex1.Y

        if ($this.dx.Data -eq [Fixed]::Zero.Data) {
            $this.slopeType = [SlopeType]::Vertical
        } elseif ($this.dy.Data -eq [Fixed]::Zero.Data) {
            $this.slopeType = [SlopeType]::Horizontal
        } else {
            if (($this.dy / $this.dx).Data -gt [Fixed]::Zero.Data) {
                $this.slopeType = [SlopeType]::Positive
            } else {
                $this.slopeType = [SlopeType]::Negative
            }
        }

        $this.boundingBox = [Fixed[]]@([Fixed]::Max($vertex1.Y, $vertex2.Y), [Fixed]::Min($vertex1.Y, $vertex2.Y), [Fixed]::Min($vertex1.X, $vertex2.X), [Fixed]::Max($vertex1.X, $vertex2.X))
        $this.frontSector = $frontSide.Sector ?? $null
        $this.backSector = $backSide.Sector ?? $null
    }

    static [LineDef] FromData([byte[]]$data, [int]$offset, [Vertex[]]$vertices, [SideDef[]]$sides) {
        $vertex1Number = [BitConverter]::ToInt16($data, $offset)
        $vertex2Number = [BitConverter]::ToInt16($data, $offset + 2)
        $mflags = [BitConverter]::ToInt16($data, $offset + 4)
        $mspecial = [BitConverter]::ToInt16($data, $offset + 6)
        $mtag = [BitConverter]::ToInt16($data, $offset + 8)
        $side0Number = [BitConverter]::ToInt16($data, $offset + 10)
        $side1Number = [BitConverter]::ToInt16($data, $offset + 12)
        return [LineDef]::new(
            $vertices[$vertex1Number],
            $vertices[$vertex2Number],
            [LineFlags]$mflags,
            $mspecial,
            $mtag,
            $sides[$side0Number],
            $(if ($side1Number -ne -1) { $sides[$side1Number] } else { $null })
        )
    }

    static [LineDef[]] FromWad([Wad]$wad, [int]$lump, [Vertex[]]$vertices, [SideDef[]]$sides) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [LineDef]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [LineDef]::dataSize
        $lines = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = 14 * $i
            $lines += [LineDef]::FromData($data, $offset, $vertices, $sides)
        }

        return $lines
    }

}