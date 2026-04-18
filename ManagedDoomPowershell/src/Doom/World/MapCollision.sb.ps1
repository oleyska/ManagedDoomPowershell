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

class MapCollision {
    [World] $World

    [Fixed] $OpenTop
    [Fixed] $OpenBottom
    [Fixed] $OpenRange
    [Fixed] $LowFloor

    MapCollision([World] $world) {
        $this.World = $world
    }

    # Sets OpenTop and OpenBottom to the window through a two-sided line.
    [void] LineOpening([LineDef] $line) {
        if ($null -eq $line.BackSide) {
            # If the line is single-sided, nothing can pass through.
            $this.OpenRange = [Fixed]::Zero
            return
        }

        $front = $line.FrontSector
        $back = $line.BackSector

        if ($front.CeilingHeight.Data -lt $back.CeilingHeight.Data) {
            $this.OpenTop = $front.CeilingHeight
        } else {
            $this.OpenTop = $back.CeilingHeight
        }

        if ($front.FloorHeight.Data -gt $back.FloorHeight.Data) {
            $this.OpenBottom = $front.FloorHeight
            $this.LowFloor = $back.FloorHeight
        } else {
            $this.OpenBottom = $back.FloorHeight
            $this.LowFloor = $front.FloorHeight
        }

        $this.OpenRange = $this.OpenTop - $this.OpenBottom
    }
}