class Thinkers {
    [World]$World
    [Thinker]$Cap

    Thinkers([World]$world) {
        $this.World = $world
        $this.InitThinkers()
    }

    [void] InitThinkers() {
        $this.Cap = [Thinker]::new()
        $this.Cap.Prev = $this.Cap
        $this.Cap.Next = $this.Cap
    }

    [void] Add([Thinker]$thinker) {
        $this.Cap.Prev.Next = $thinker
        $thinker.Next = $this.Cap
        $thinker.Prev = $this.Cap.Prev
        $this.Cap.Prev = $thinker
    }

    [void] Remove([Thinker]$thinker) {
        $thinker.ThinkerState = [ThinkerState]::Removed
    }

    [void] Run() {
        $current = $this.Cap.Next
        $debugCount = 0
        while ($current -ne $this.Cap) {
            if ($current.ThinkerState -eq [ThinkerState]::Removed) {
                $current.Next.Prev = $current.Prev
                $current.Prev.Next = $current.Next
            } elseif ($current.ThinkerState -eq [ThinkerState]::Active) {
                $current.Run()
            }
            $current = $current.Next
            $debugCount++
            if ($this.World.LevelTime -lt 1 -and $debugCount -gt 2000) {
                throw "Thinkers.Run exceeded 2000 items on first tic."
            }
        }
    }

    [void] UpdateFrameInterpolationInfo() {
        $current = $this.Cap.Next
        while ($current -ne $this.Cap) {
            $current.UpdateFrameInterpolationInfo()
            $current = $current.Next
        }
    }

    [void] Reset() {
        $this.Cap.Prev = $this.Cap
        $this.Cap.Next = $this.Cap
    }

    [ThinkerEnumerator] GetEnumerator() {
        return [ThinkerEnumerator]::new($this)
    }
}

class ThinkerEnumerator {
    [Thinkers]$Thinkers
    [Thinker]$Current

    ThinkerEnumerator([Thinkers]$thinkers) {
        $this.Thinkers = $thinkers
        $this.Current = $thinkers.Cap
    }

    [bool] MoveNext() {
        while ($true) {
            $this.Current = $this.Current.Next
            if ($this.Current -eq $this.Thinkers.Cap) {
                return $false
            } elseif ($this.Current.ThinkerState -ne [ThinkerState]::Removed) {
                return $true
            }
        }
        return $false 
    }

    [void] Reset() {
        $this.Current = $this.Thinkers.Cap
    }

    [void] Dispose() {
    }
}
