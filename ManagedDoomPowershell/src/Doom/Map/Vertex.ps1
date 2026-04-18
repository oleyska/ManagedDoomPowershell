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

class Vertex {
    static [int]$dataSize = 4

    [Fixed]$x
    [Fixed]$y

    Vertex([Fixed]$x, [Fixed]$y) {
        $this.x = $x
        $this.y = $y
    }

    static [Vertex] FromData([byte[]]$data, [int]$offset) {
        $mX = [BitConverter]::ToInt16($data, $offset)
        $mY = [BitConverter]::ToInt16($data, $offset + 2)

        return [Vertex]::new([Fixed]::FromInt($mX), [Fixed]::FromInt($mY))
    }


    static [Vertex[]] FromWad([Wad]$wad, [int]$lump) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [vertex]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [vertex]::dataSize
        $vertices = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [vertex]::dataSize * $i
            $vertices += [Vertex]::FromData($data, $offset)
        }

        return $vertices
    }
}