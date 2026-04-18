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

class FloorMove : Thinker {
    [World] $World
    [FloorMoveType] $Type
    [bool] $Crush
    [Sector] $Sector
    [int] $Direction
    [SectorSpecial] $NewSpecial
    [int] $Texture
    [Fixed] $FloorDestHeight
    [Fixed] $Speed

    FloorMove([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        $sa = $this.World.SectorAction

        $result = $sa.MovePlane(
            $this.Sector,
            $this.Speed,
            $this.FloorDestHeight,
            $this.Crush,
            0,
            $this.Direction
        )

        if ((($this.World.LevelTime + $this.Sector.Number) -band 7) -eq 0) {
            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
        }

        if ($result -eq [SectorActionResult]::PastDestination) {
            $this.Sector.SpecialData = $null

            if ($this.Direction -eq 1) {
                if ($this.Type -eq [FloorMoveType]::DonutRaise) {
                    $this.Sector.Special = $this.NewSpecial
                    $this.Sector.FloorFlat = $this.Texture
                }
            }
            elseif ($this.Direction -eq -1) {
                if ($this.Type -eq [FloorMoveType]::LowerAndChange) {
                    $this.Sector.Special = $this.NewSpecial
                    $this.Sector.FloorFlat = $this.Texture
                }
            }

            $this.World.Thinkers.Remove($this)
            $this.Sector.DisableFrameInterpolationForOneFrame()

            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)
        }
    }
}
