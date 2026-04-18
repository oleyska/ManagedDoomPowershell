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

class MapThing {
    static [int] $dataSize = 10
    [Fixed]$x
    [Fixed]$y
    [Angle]$angle
    [int]$type
    [ThingFlags]$flags

    static [MapThing]$Empty = [MapThing]::new([Fixed]::Zero, [Fixed]::Zero, [Angle]::Ang0, 0, 0)

    MapThing([Fixed]$x, [Fixed]$y, [Angle]$angle, [int]$type, [ThingFlags]$flags) {
        $this.x = $x
        $this.y = $y
        $this.angle = $angle
        $this.type = $type
        $this.flags = $flags
    }

    static [MapThing] FromData([byte[]]$data, [int]$offset) {
        $mx = [BitConverter]::ToInt16($data, $offset)
        $my = [BitConverter]::ToInt16($data, $offset + 2)
        $mAngle = [BitConverter]::ToInt16($data, $offset + 4)
        $mtype = [BitConverter]::ToInt16($data, $offset + 6)
        $mflags = [BitConverter]::ToInt16($data, $offset + 8)

        return [MapThing]::new(
            [Fixed]::FromInt($mx),
            [Fixed]::FromInt($my),
            [Angle]::new([Angle]::Ang45.Data * [uint]($mAngle / 45)),
            $mtype,
            [ThingFlags]$mflags
        )
    }

    static [MapThing[]] FromWad([Wad]$wad, [int]$lump) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [MapThing]::dataSize -ne 0) {
            throw "Invalid data size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [MapThing]::dataSize
        $things = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [MapThing]::dataSize * $i
            $things += [MapThing]::FromData($data, $offset)
        }

        return $things
    }

}