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
                        ([CeilingMoveType]::SilentCrushAndRaise) {}
                        ([CeilingMoveType]::FastCrushAndRaise){}
                        ([CeilingMoveType]::CrushAndRaise) {
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
                        ([CeilingMoveType]::SilentCrushAndRaise){}
                        ([CeilingMoveType]::CrushAndRaise){}
                        ([CeilingMoveType]::FastCrushAndRaise) {
                            if ($this.Type -eq [CeilingMoveType]::SilentCrushAndRaise) {
                                $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::PSTOP, [SfxType]::Misc)
                                $this.Speed = [SectorAction]::CeilingSpeed
                            }
                            if ($this.Type -eq [CeilingMoveType]::CrushAndRaise) {
                                $this.Speed = [SectorAction]::CeilingSpeed
                            }
                            $this.Direction = 1
                        }
                        ([CeilingMoveType]::LowerAndCrush){}
                        ([CeilingMoveType]::LowerToFloor) {
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