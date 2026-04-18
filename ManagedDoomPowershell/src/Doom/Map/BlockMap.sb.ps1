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

class BlockMap {
    static [int]$IntBlockSize = 128
    static [Fixed]$BlockSize = [Fixed]::FromInt($IntBlockSize)
    static [int]$BlockMask = [BlockMap]::BlockSize.Data - 1
    static [int]$FracToBlockShift = [Fixed]::FracBits + 7
    static [int]$BlockToFracShift = [BlockMap]::FracToBlockShift - [Fixed]::FracBits

    [Fixed]$originX
    [Fixed]$originY
    [int]$width
    [int]$height
    [short[]]$table
    [LineDef[]]$lines
    [Mobj[]]$thingLists

    BlockMap(
        [Fixed]$originX,
        [Fixed]$originY,
        [int]$width,
        [int]$height,
        [short[]]$table,
        [LineDef[]]$lines
    ) {
        $this.originX = $originX
        $this.originY = $originY
        $this.width = $width
        $this.height = $height
        $this.table = $table
        $this.lines = $lines
        $this.thingLists = New-Object 'Mobj[]' ($width * $height)
    }

    static [BlockMap] FromWad([Wad]$wad, [int]$lump, [LineDef[]]$lines) {
        $data = $wad.ReadLump($lump)

        $mTable = New-Object int16[] ($data.Length / 2)
        for ($i = 0; $i -lt ($data.Length / 2); $i++) {
            $offset = 2 * $i
            $mTable[$i] = [BitConverter]::ToInt16($data, $offset)
        }

        $mOriginX = [Fixed]::FromInt($mTable[0])
        $mOriginY = [Fixed]::FromInt($mTable[1])
        $mWidth = $mTable[2]
        $mHeight = $mTable[3]

        return [BlockMap]::new($mOriginX, $mOriginY, $mWidth, $mHeight, $mTable, $lines)
    }

    [int] GetBlockX([Fixed]$x) {
        return ($x - $this.originX).Data -shr [BlockMap]::FracToBlockShift
    }

    [int] GetBlockY([Fixed]$y) {
        return ($y - $this.originY).Data -shr [BlockMap]::FracToBlockShift
    }

    [int] GetIndex([int]$blockX, [int]$blockY) {
        if ($blockX -ge 0 -and $blockX -lt $this.width -and $blockY -ge 0 -and $blockY -lt $this.height) {
            return $this.width * $blockY + $blockX
        } else {
            return -1
        }
    }

    [int] GetIndex([Fixed]$x, [Fixed]$y) {
        $blockX = $this.GetBlockX($x)
        $blockY = $this.GetBlockY($y)
        return $this.GetIndex($blockX, $blockY)
    }

    [bool] IterateLines([int]$blockX, [int]$blockY, [Func[LineDef, bool]]$func, [int]$validCount) {
        $index = $this.GetIndex($blockX, $blockY)

        if ($index -eq -1) {
            return $true
        }

        for ($offset = $this.table[4 + $index]; $this.table[$offset] -ne -1; $offset++) {
            $line = $this.lines[$this.table[$offset]]

            if ($line.ValidCount -eq $validCount) {
                continue
            }

            $line.ValidCount = $validCount

            if (-not ($func.Invoke($line))) {
                return $false
            }
        }

        return $true
    }

    [bool] IterateThings([int]$blockX, [int]$blockY, [Func[Mobj, bool]]$func) {
        $index = $this.GetIndex($blockX, $blockY)

        if ($index -eq -1) {
            return $true
        }

        $mobj = $this.thingLists[$index]
        $debugCount = 0
        while ($null -ne $mobj) {
            if (-not ($func.Invoke($mobj))) {
                return $false
            }
            $mobj = $mobj.BlockNext
            $debugCount++
            if ($debugCount -gt 2000) {
                throw ("IterateThings exceeded 2000 linked items at block index " + $index + ".")
            }
        }

        return $true
    }
}