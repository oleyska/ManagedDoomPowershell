class LightFlash : Thinker {
    [World] $World
    [Sector] $Sector
    [int] $Count
    [int] $MaxLight
    [int] $MinLight
    [int] $MaxTime
    [int] $MinTime

    LightFlash([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        if (--$this.Count -gt 0) {
            return
        }

        if ($this.Sector.LightLevel -eq $this.MaxLight) {
            $this.Sector.LightLevel = $this.MinLight
            $this.Count = ($this.World.Random.Next() -band $this.MinTime) + 1
        } else {
            $this.Sector.LightLevel = $this.MaxLight
            $this.Count = ($this.World.Random.Next() -band $this.MaxTime) + 1
        }
    }
}
