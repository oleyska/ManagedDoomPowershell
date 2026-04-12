#needs [Thinker]
class VerticalDoor : Thinker {
    [World] $World
    [VerticalDoorType] $Type
    [Sector] $Sector
    [Fixed] $TopHeight
    [Fixed] $Speed
    [int] $Direction
    [int] $TopWait
    [int] $TopCountDown

    VerticalDoor([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        $sa = $this.World.SectorAction
        $result = $null

        switch ($this.Direction) {
            0 {
                # Waiting.
                if (--$this.TopCountDown -eq 0) {
                    switch ($this.Type) {
                        { $_ -eq [VerticalDoorType]::BlazeRaise } {
                            $this.Direction = -1
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::BDCLS, [SfxType]::Misc)
                        }
                        { $_ -eq [VerticalDoorType]::Normal } {
                            $this.Direction = -1
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::DORCLS, [SfxType]::Misc)
                        }
                        { $_ -eq [VerticalDoorType]::Close30ThenOpen } {
                            $this.Direction = 1
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                        }
                    }
                }
            }
            2 {
                # Initial wait.
                if (--$this.TopCountDown -eq 0) {
                    switch ($this.Type) {
                        { $_ -eq [VerticalDoorType]::RaiseIn5Mins } {
                            $this.Direction = 1
                            $this.Type = [VerticalDoorType]::Normal
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                        }
                    }
                }
            }
            -1 {
                # Down.
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.Sector.FloorHeight, $false, 1, $this.Direction)
                
                if ($result -eq [SectorActionResult]::PastDestination) {
                    switch ($this.Type) {
                        { $_ -in ([VerticalDoorType]::BlazeRaise, [VerticalDoorType]::BlazeClose) } {
                            $this.Sector.SpecialData = $null
                            $this.World.Thinkers.Remove($this)
                            $this.Sector.DisableFrameInterpolationForOneFrame()
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::BDCLS, [SfxType]::Misc)
                        }
                        { $_ -in ([VerticalDoorType]::Normal, [VerticalDoorType]::Close) } {
                            $this.Sector.SpecialData = $null
                            $this.World.Thinkers.Remove($this)
                            $this.Sector.DisableFrameInterpolationForOneFrame()
                        }
                        { $_ -eq [VerticalDoorType]::Close30ThenOpen } {
                            $this.Direction = 0
                            $this.TopCountDown = 35 * 30
                        }
                    }
                }
                elseif ($result -eq [SectorActionResult]::Crushed) {
                    switch ($this.Type) {
                        { $_ -notin ([VerticalDoorType]::BlazeClose, [VerticalDoorType]::Close) } {
                            $this.Direction = 1
                            $this.World.StartSound($this.Sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                        }
                    }
                }
            }
            1 {
                # Up.
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.TopHeight, $false, 1, $this.Direction)

                if ($result -eq [SectorActionResult]::PastDestination) {
                    switch ($this.Type) {
                        { $_ -in ([VerticalDoorType]::BlazeRaise, [VerticalDoorType]::Normal) } {
                            $this.Direction = 0
                            $this.TopCountDown = $this.TopWait
                        }
                        { $_ -in ([VerticalDoorType]::Close30ThenOpen, [VerticalDoorType]::BlazeOpen, [VerticalDoorType]::Open) } {
                            $this.Sector.SpecialData = $null
                            $this.World.Thinkers.Remove($this)
                            $this.Sector.DisableFrameInterpolationForOneFrame()
                        }
                    }
                }
            }
        }
    }
}
