class LightingChange {
    [World] $World

    LightingChange([World] $world) {
        $this.World = $world
    }

    [void] SpawnFireFlicker([Sector] $sector) {
        $sector.Special = 0  # Reset sector attributes

        $flicker = [FireFlicker]::new($this.World)
        $this.World.Thinkers.Add($flicker)

        $flicker.Sector = $sector
        $flicker.MaxLight = $sector.LightLevel
        $flicker.MinLight = $this.FindMinSurroundingLight($sector, $sector.LightLevel) + 16
        $flicker.Count = 4
    }

    [void] SpawnLightFlash([Sector] $sector) {
        $sector.Special = 0  # Reset sector attributes

        $light = [LightFlash]::new($this.World)
        $this.World.Thinkers.Add($light)

        $light.Sector = $sector
        $light.MaxLight = $sector.LightLevel
        $light.MinLight = $this.FindMinSurroundingLight($sector, $sector.LightLevel)
        $light.MaxTime = 64
        $light.MinTime = 7
        $light.Count = ($this.World.Random.Next() -band $light.MaxTime) + 1
    }

    [void] SpawnStrobeFlash([Sector] $sector, [int] $time, [bool] $inSync) {
        $strobe = [StrobeFlash]::new($this.World)
        $this.World.Thinkers.Add($strobe)

        $strobe.Sector = $sector
        $strobe.DarkTime = $time
        $strobe.BrightTime = [StrobeFlash]::StrobeBright
        $strobe.MaxLight = $sector.LightLevel
        $strobe.MinLight = $this.FindMinSurroundingLight($sector, $sector.LightLevel)

        if ($strobe.MinLight -eq $strobe.MaxLight) {
            $strobe.MinLight = 0
        }

        $sector.Special = 0  # Reset sector attributes

        if ($inSync) {
            $strobe.Count = 1
        } else {
            $strobe.Count = ($this.World.Random.Next() -band 7) + 1
        }
    }

    [void] SpawnGlowingLight([Sector] $sector) {
        $glowing = [GlowingLight]::new($this.World)
        $this.World.Thinkers.Add($glowing)

        $glowing.Sector = $sector
        $glowing.MinLight = $this.FindMinSurroundingLight($sector, $sector.LightLevel)
        $glowing.MaxLight = $sector.LightLevel
        $glowing.Direction = -1

        $sector.Special = 0
    }

    [int] FindMinSurroundingLight([Sector] $sector, [int] $max) {
        $min = $max
        foreach ($line in $sector.Lines) {
            $check = $this.GetNextSector($line, $sector)

            if ($null -ne $check -and $check.LightLevel -lt $min) {
                $min = $check.LightLevel
            }
        }
        return $min
    }

    [Sector] GetNextSector([LineDef] $line, [Sector] $sector) {
        if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) {
            return $null
        }

        if ($line.FrontSector -eq $sector) {
            return $line.BackSector
        }

        return $line.FrontSector
    }
}