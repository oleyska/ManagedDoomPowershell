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

class Patch {
    [string]$Name
    [int]$Width
    [int]$Height
    [int]$LeftOffset
    [int]$TopOffset
    [Column[][]]$Columns

    Patch([string]$name, [int]$width, [int]$height, [int]$leftOffset, [int]$topOffset, [Column[][]]$columns) {
        $this.Name = $name
        $this.Width = $width
        $this.Height = $height
        $this.LeftOffset = $leftOffset
        $this.TopOffset = $topOffset
        $this.Columns = $columns
    }

    static [Patch] FromData([string]$name, [byte[]]$data) {
        $mwidth = [BitConverter]::ToInt16($data, 0)
        $mheight = [BitConverter]::ToInt16($data, 2)
        $mleftOffset = [BitConverter]::ToInt16($data, 4)
        $mtopOffset = [BitConverter]::ToInt16($data, 6)

        [Patch]::PadData([ref]$data, $mwidth)

        $mcolumns = New-Object 'Column[][]' $mwidth
        for ($x = 0; $x -lt $mwidth; $x++) {
            $cs = @()
            $p = [BitConverter]::ToInt32($data, 8 + (4 * $x))
            while ($true) {
                $topDelta = $data[$p]
                if ($topDelta -eq [Column]::Last) {
                    break
                }
                $length = $data[$p + 1]
                $offset = $p + 3
                $cs += [Column]::new($topDelta, $data, $offset, $length)
                $p += $length + 4
            }
            $mcolumns[$x] = $cs
        }

        return [Patch]::new($name, $mwidth, $mheight, $mleftOffset, $mtopOffset, $mcolumns)
    }

    static [Patch] FromWad([wad]$wad, [string]$name) {
        return [Patch]::FromData($name, $wad.ReadLump($name))
    }

    static [void] PadData([ref]$data, [int]$width) {
        $need = 0
        for ($x = 0; $x -lt $width; $x++) {
            $p = [BitConverter]::ToInt32($data.Value, 8 + (4 * $x))
            while ($true) {
                $topDelta = $data.Value[$p]
                if ($topDelta -eq [Column]::Last) {
                    break
                }
                $length = $data.Value[$p + 1]
                $offset = $p + 3
                $need = [math]::Max($offset + 128, $need)
                $p += $length + 4
            }
        }

        if ($data.Value.Length -lt $need) {
            $tempArray = New-Object 'byte[]' $need
            [System.Array]::Copy($data.Value, $tempArray, $data.Value.Length)
            $data.Value = $tempArray
        }
    }

    [string] ToString() {
        return $this.Name
    }
}