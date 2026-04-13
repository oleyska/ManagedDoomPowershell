class WipeEffect {
    [int[]]$Y
    [int]$Height
    [DoomRandom]$Random

    WipeEffect([int]$width, [int]$height) {
        $this.Y = New-Object int[] $width
        $this.Height = $height
        $this.Random = [DoomRandom]::new()
    }

    [void] Start() {
        $this.Y[0] = -($this.Random.Next() % 16)
        for ($i = 1; $i -lt $this.Y.Length; $i++) {
            $r = ($this.Random.Next() % 3) - 1
            $this.Y[$i] = $this.Y[$i - 1] + $r
            if ($this.Y[$i] -gt 0) {
                $this.Y[$i] = 0
            } elseif ($this.Y[$i] -eq -16) {
                $this.Y[$i] = -15
            }
        }
    }

    [UpdateResult] Update() {
        $done = $true

        for ($i = 0; $i -lt $this.Y.Length; $i++) {
            if ($this.Y[$i] -lt 0) {
                $this.Y[$i]++
                $done = $false
            } elseif ($this.Y[$i] -lt $this.Height) {
                $dy = if ($this.Y[$i] -lt 16) { $this.Y[$i] + 1 } else { 8 }
                if ($this.Y[$i] + $dy -ge $this.Height) {
                    $dy = $this.Height - $this.Y[$i]
                }
                $this.Y[$i] += $dy
                $done = $false
            }
        }

        if ($done) {
            return [UpdateResult]::Completed
        } else {
            return [UpdateResult]::None
        }
    }
}