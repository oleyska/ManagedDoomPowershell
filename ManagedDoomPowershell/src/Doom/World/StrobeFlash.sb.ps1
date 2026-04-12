class StrobeFlash : Thinker {
    static [int] $StrobeBright = 5
    static [int] $FastDark = 15
    static [int] $SlowDark = 35

    [World] $World
    [Sector] $Sector
    [int] $Count
    [int] $MinLight
    [int] $MaxLight
    [int] $DarkTime
    [int] $BrightTime

    StrobeFlash([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        if (--$this.Count -gt 0) {
            return
        }

        if ($this.Sector.LightLevel -eq $this.MinLight) {
            $this.Sector.LightLevel = $this.MaxLight
            $this.Count = $this.BrightTime
        } else {
            $this.Sector.LightLevel = $this.MinLight
            $this.Count = $this.DarkTime
        }
    }
}