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

#Needs [Thinker]

class Platform : Thinker {
    [World]$World
    [Sector]$Sector
    [Fixed]$Speed
    [Fixed]$Low
    [Fixed]$High
    [int]$Wait
    [int]$Count
    [PlatformState]$Status
    [PlatformState]$OldStatus
    [bool]$Crush
    [int]$Tag
    [PlatformType]$Type

    Platform([World]$world) {
        $this.World = $world
    }

    [void] Run() {
        $sa = $this.World.SectorAction
        $result = $null

        switch ($this.Status) {
            ([PlatformState]::Up) {
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.High, $this.Crush, 0, 1)

                if ($this.Type -in @([PlatformType]::RaiseAndChange, [PlatformType]::RaiseToNearestAndChange)) {
                    if ((($this.World.LevelTime + $this.Sector.Number) -band 7) -eq 0) {
                        $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
                    }
                }

                if ($result -eq [SectorActionResult]::Crushed -and -not $this.Crush) {
                    $this.Count = $this.Wait
                    $this.Status = [PlatformState]::Down
                    $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTART, [SfxType]::Misc)
                } elseif ($result -eq [SectorActionResult]::PastDestination) {
                    $this.Count = $this.Wait
                    $this.Status = [PlatformState]::Waiting
                    $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)

                    if ($this.Type -in @([PlatformType]::BlazeDwus, [PlatformType]::DownWaitUpStay, [PlatformType]::RaiseAndChange, [PlatformType]::RaiseToNearestAndChange)) {
                        $sa.RemoveActivePlatform($this)
                        $this.Sector.DisableFrameInterpolationForOneFrame()
                    }
                }
            }

            ([PlatformState]::Down) {
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.Low, $false, 0, -1)

                if ($result -eq [SectorActionResult]::PastDestination) {
                    $this.Count = $this.Wait
                    $this.Status = [PlatformState]::Waiting
                    $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)
                }
            }

            ([PlatformState]::Waiting) {
                $this.Count--
                if ($this.Count -eq 0) {
                    if ($this.Sector.FloorHeight.Data -eq $this.Low.Data) {
                        $this.Status = [PlatformState]::Up
                    } else {
                        $this.Status = [PlatformState]::Down
                    }
                    $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTART, [SfxType]::Misc)
                }
            }

            ([PlatformState]::InStasis) {
                # Do nothing
            }
        }
    }

}
