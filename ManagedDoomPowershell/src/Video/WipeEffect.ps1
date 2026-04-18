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

class WipeEffect {
    [int[]]$Y
    [int]$Height
    [DoomRandom]$Random

    WipeEffect([int]$width, [int]$height) {
        $this.Y = New-Object int[] $width
        $this.Height = $height
        $this.Random = [DoomRandom]::new()
    }

    [void] Start() {
        $this.Y[0] = -($this.Random.Next() % 16)
        for ($i = 1; $i -lt $this.Y.Length; $i++) {
            $r = ($this.Random.Next() % 3) - 1
            $this.Y[$i] = $this.Y[$i - 1] + $r
            if ($this.Y[$i] -gt 0) {
                $this.Y[$i] = 0
            } elseif ($this.Y[$i] -eq -16) {
                $this.Y[$i] = -15
            }
        }
    }

    [UpdateResult] Update() {
        $done = $true

        for ($i = 0; $i -lt $this.Y.Length; $i++) {
            if ($this.Y[$i] -lt 0) {
                $this.Y[$i]++
                $done = $false
            } elseif ($this.Y[$i] -lt $this.Height) {
                $dy = if ($this.Y[$i] -lt 16) { $this.Y[$i] + 1 } else { 8 }
                if ($this.Y[$i] + $dy -ge $this.Height) {
                    $dy = $this.Height - $this.Y[$i]
                }
                $this.Y[$i] += $dy
                $done = $false
            }
        }

        if ($done) {
            return [UpdateResult]::Completed
        } else {
            return [UpdateResult]::None
        }
    }
}