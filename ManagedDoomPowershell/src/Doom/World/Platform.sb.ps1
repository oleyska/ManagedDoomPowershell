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
            "Up" {
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.High, $this.Crush, 0, 1)

                if ($this.Type -in @("RaiseAndChange", "RaiseToNearestAndChange")) {
                    if ((($this.World.LevelTime + $this.Sector.Number) -band 7) -eq 0) {
                        $this.World.StartSound($this.Sector.SoundOrigin, "STNMOV", "Misc")
                    }
                }

                if ($result -eq "Crushed" -and -not $this.Crush) {
                    $this.Count = $this.Wait
                    $this.Status = "Down"
                    $this.World.StartSound($this.Sector.SoundOrigin, "PSTART", "Misc")
                } elseif ($result -eq "PastDestination") {
                    $this.Count = $this.Wait
                    $this.Status = "Waiting"
                    $this.World.StartSound($this.Sector.SoundOrigin, "PSTOP", "Misc")

                    if ($this.Type -in @("BlazeDwus", "DownWaitUpStay", "RaiseAndChange", "RaiseToNearestAndChange")) {
                        $sa.RemoveActivePlatform($this)
                        $this.Sector.DisableFrameInterpolationForOneFrame()
                    }
                }
            }

            "Down" {
                $result = $sa.MovePlane($this.Sector, $this.Speed, $this.Low, $false, 0, -1)

                if ($result -eq "PastDestination") {
                    $this.Count = $this.Wait
                    $this.Status = "Waiting"
                    $this.World.StartSound($this.Sector.SoundOrigin, "PSTOP", "Misc")
                }
            }

            "Waiting" {
                if (--$this.Count -eq 0) {
                    if ($this.Sector.FloorHeight -eq $this.Low) {
                        $this.Status = "Up"
                    } else {
                        $this.Status = "Down"
                    }
                    $this.World.StartSound($this.Sector.SoundOrigin, "PSTART", "Misc")
                }
            }

            "InStasis" {
                # Do nothing
            }
        }
    }

}
