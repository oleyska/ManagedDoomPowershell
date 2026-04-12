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
