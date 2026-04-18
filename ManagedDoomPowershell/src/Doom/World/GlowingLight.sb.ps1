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

class GlowingLight : Thinker {
    static [int] $GlowSpeed = 8

    [World] $World
    [Sector] $Sector
    [int] $MinLight
    [int] $MaxLight
    [int] $Direction

    GlowingLight([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        switch ($this.Direction) {
            -1 {
                # Down.
                $this.Sector.LightLevel -= [GlowingLight]::GlowSpeed
                if ($this.Sector.LightLevel -le $this.MinLight) {
                    $this.Sector.LightLevel += [GlowingLight]::GlowSpeed
                    $this.Direction = 1
                }
            }
            1 {
                # Up.
                $this.Sector.LightLevel += [GlowingLight]::GlowSpeed
                if ($this.Sector.LightLevel -ge $this.MaxLight) {
                    $this.Sector.LightLevel -= [GlowingLight]::GlowSpeed
                    $this.Direction = -1
                }
            }
        }
    }
}
