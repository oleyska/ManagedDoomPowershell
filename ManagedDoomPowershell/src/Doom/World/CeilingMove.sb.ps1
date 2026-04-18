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

class CeilingMove : Thinker{
    [World] $World
    [CeilingMoveType] $Type
    [Sector] $Sector
    [Fixed] $BottomHeight
    [Fixed] $TopHeight
    [Fixed] $Speed
    [bool] $Crush
    [int] $Direction
    [int] $Tag
    [int] $OldDirection

    CeilingMove([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        $sa = $this.World.SectorAction
        $result = $null

        switch ($this.Direction) {
            0 {
                # In statis
            }
            1 {
                # Up
                $result = $sa.MovePlane(
                    $this.Sector,
                    $this.Speed,
                    $this.TopHeight,
                    $false,
                    1,
                    $this.Direction
                )

                if ((($this.World.LevelTime + $this.Sector.Number) -band 7) -eq 0) {
                    if ($this.Type -ne [CeilingMoveType]::SilentCrushAndRaise) {
                        $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
                    }
                }

                if ($result -eq [SectorActionResult]::PastDestination) {
                    switch ($this.Type) {
                        ([CeilingMoveType]::RaiseToHighest) {
                            $sa.RemoveActiveCeiling($this)
                            $this.Sector.DisableFrameInterpolationForOneFrame()
                        }
                        { $_ -eq [CeilingMoveType]::SilentCrushAndRaise -or
                          $_ -eq [CeilingMoveType]::FastCrushAndRaise -or
                          $_ -eq [CeilingMoveType]::CrushAndRaise } {
                            if ($this.Type -eq [CeilingMoveType]::SilentCrushAndRaise) {
                                $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)
                            }
                            $this.Direction = -1
                        }
                    }
                }
            }
            -1 {
                # Down
                $result = $sa.MovePlane(
                    $this.Sector,
                    $this.Speed,
                    $this.BottomHeight,
                    $this.Crush,
                    1,
                    $this.Direction
                )

                if ((($this.World.LevelTime + $this.Sector.Number) -band 7) -eq 0) {
                    if ($this.Type -ne [CeilingMoveType]::SilentCrushAndRaise) {
                        $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
                    }
                }

                if ($result -eq [SectorActionResult]::PastDestination) {
                    switch ($this.Type) {
                        { $_ -eq [CeilingMoveType]::SilentCrushAndRaise -or
                          $_ -eq [CeilingMoveType]::CrushAndRaise -or
                          $_ -eq [CeilingMoveType]::FastCrushAndRaise } {
                            if ($this.Type -eq [CeilingMoveType]::SilentCrushAndRaise) {
                                $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)
                                $this.Speed = [SectorAction]::CeilingSpeed
                            }
                            if ($this.Type -eq [CeilingMoveType]::CrushAndRaise) {
                                $this.Speed = [SectorAction]::CeilingSpeed
                            }
                            $this.Direction = 1
                        }
                        { $_ -eq [CeilingMoveType]::LowerAndCrush -or
                          $_ -eq [CeilingMoveType]::LowerToFloor } {
                            $sa.RemoveActiveCeiling($this)
                            $this.Sector.DisableFrameInterpolationForOneFrame()
                        }
                    }
                } elseif ($result -eq [SectorActionResult]::Crushed) {
                    if ($this.Type -in @([CeilingMoveType]::SilentCrushAndRaise, [CeilingMoveType]::CrushAndRaise, [CeilingMoveType]::LowerAndCrush)) {
                        $this.Speed = [SectorAction]::CeilingSpeed / 8
                    }
                }
            }
        }
    }
}
