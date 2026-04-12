class GlowingLight : Thinker {
    static [int] $GlowSpeed = 8

    [World] $World
    [Sector] $Sector
    [int] $MinLight
    [int] $MaxLight
    [int] $Direction

    GlowingLight([World] $world) {
        $this.World = $world
    }

    [void] Run() {
        switch ($this.Direction) {
            -1 {
                # Down.
                $this.Sector.LightLevel -= [GlowingLight]::GlowSpeed
                if ($this.Sector.LightLevel -le $this.MinLight) {
                    $this.Sector.LightLevel += [GlowingLight]::GlowSpeed
                    $this.Direction = 1
                }
            }
            1 {
                # Up.
                $this.Sector.LightLevel += [GlowingLight]::GlowSpeed
                if ($this.Sector.LightLevel -ge $this.MaxLight) {
                    $this.Sector.LightLevel -= [GlowingLight]::GlowSpeed
                    $this.Direction = -1
                }
            }
        }
    }
}
