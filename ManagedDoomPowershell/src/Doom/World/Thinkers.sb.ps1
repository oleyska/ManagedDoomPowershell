##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##

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
