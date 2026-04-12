class FireFlicker : Thinker {
    [World] $World
    [Sector] $Sector
    [int] $Count
    [int] $MaxLight
    [int] $MinLight

    FireFlicker([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        if (--$this.Count -gt 0) {
            return
        }

        $amount = ($this.World.Random.Next() -band 3) * 16

        if ($this.Sector.LightLevel - $amount -lt $this.MinLight) {
            $this.Sector.LightLevel = $this.MinLight
        } else {
            $this.Sector.LightLevel = $this.MaxLight - $amount
        }

        $this.Count = 4
    }
}
