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

class Node {
    static [int]$dataSize = 28

    [Fixed]$x
    [Fixed]$y
    [Fixed]$dx
    [Fixed]$dy

    [Fixed[][]]$boundingBox
    [int[]]$children

    Node(
        [Fixed]$x,
        [Fixed]$y,
        [Fixed]$dx,
        [Fixed]$dy,
        [Fixed]$frontBoundingBoxTop,
        [Fixed]$frontBoundingBoxBottom,
        [Fixed]$frontBoundingBoxLeft,
        [Fixed]$frontBoundingBoxRight,
        [Fixed]$backBoundingBoxTop,
        [Fixed]$backBoundingBoxBottom,
        [Fixed]$backBoundingBoxLeft,
        [Fixed]$backBoundingBoxRight,
        [int]$frontChild,
        [int]$backChild
    ) {
        $this.x = $x
        $this.y = $y
        $this.dx = $dx
        $this.dy = $dy

        $frontBoundingBox = @($frontBoundingBoxTop, $frontBoundingBoxBottom, $frontBoundingBoxLeft, $frontBoundingBoxRight)
        $backBoundingBox = @($backBoundingBoxTop, $backBoundingBoxBottom, $backBoundingBoxLeft, $backBoundingBoxRight)

        $this.boundingBox = @($frontBoundingBox, $backBoundingBox)

        $this.children = @($frontChild, $backChild)
    }

    static [Node] FromData([byte[]]$data, [int]$offset) {
        $mx = [BitConverter]::ToInt16($data, $offset)
        $my = [BitConverter]::ToInt16($data, $offset + 2)
        $mdx = [BitConverter]::ToInt16($data, $offset + 4)
        $mdy = [BitConverter]::ToInt16($data, $offset + 6)
        $frontBoundingBoxTop = [BitConverter]::ToInt16($data, $offset + 8)
        $frontBoundingBoxBottom = [BitConverter]::ToInt16($data, $offset + 10)
        $frontBoundingBoxLeft = [BitConverter]::ToInt16($data, $offset + 12)
        $frontBoundingBoxRight = [BitConverter]::ToInt16($data, $offset + 14)
        $backBoundingBoxTop = [BitConverter]::ToInt16($data, $offset + 16)
        $backBoundingBoxBottom = [BitConverter]::ToInt16($data, $offset + 18)
        $backBoundingBoxLeft = [BitConverter]::ToInt16($data, $offset + 20)
        $backBoundingBoxRight = [BitConverter]::ToInt16($data, $offset + 22)
        $frontChild = [BitConverter]::ToInt16($data, $offset + 24)
        $backChild = [BitConverter]::ToInt16($data, $offset + 26)

        return [Node]::new(
            [Fixed]::FromInt($mx),
            [Fixed]::FromInt($my),
            [Fixed]::FromInt($mdx),
            [Fixed]::FromInt($mdy),
            [Fixed]::FromInt($frontBoundingBoxTop),
            [Fixed]::FromInt($frontBoundingBoxBottom),
            [Fixed]::FromInt($frontBoundingBoxLeft),
            [Fixed]::FromInt($frontBoundingBoxRight),
            [Fixed]::FromInt($backBoundingBoxTop),
            [Fixed]::FromInt($backBoundingBoxBottom),
            [Fixed]::FromInt($backBoundingBoxLeft),
            [Fixed]::FromInt($backBoundingBoxRight),
            $frontChild,
            $backChild
        )
    }

    static [Node[]] FromWad([Wad]$wad, [int]$lump, [Subsector[]]$subsectors) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Node]::dataSize -ne 0) {
            throw "Invalid data size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Node]::dataSize
        $nodes = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [Node]::dataSize * $i
            $nodes += [Node]::FromData($data, $offset)
        }

        return $nodes
    }

    static [bool] IsSubsector([int]$node) {
        return ($node -band 0xFFFF8000) -ne 0
    }

    static [int] GetSubsector([int]$node) {
        return $node -bxor 0xFFFF8000
    }
}