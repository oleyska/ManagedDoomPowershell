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

class PathTraversal {
    [World]$World
    [Intercept[]]$Intercepts
    [int]$InterceptCount
    [bool]$EarlyOut
    [DivLine]$Target
    [DivLine]$Trace
    [scriptblock]$LineInterceptFunc
    [scriptblock]$ThingInterceptFunc

    PathTraversal([World]$world) {
        $this.World = $world
        $this.Intercepts = New-Object 'Intercept[]' 256
        for ($i = 0; $i -lt $this.Intercepts.Length; $i++) {
            $this.Intercepts[$i] = [Intercept]::new()
        }
        $this.Target = [DivLine]::new()
        $this.Trace = [DivLine]::new()

        $owner = $this
        $this.LineInterceptFunc = { param($line) $owner.AddLineIntercepts($line) }.GetNewClosure()
        $this.ThingInterceptFunc = { param($thing) $owner.AddThingIntercepts($thing) }.GetNewClosure()
    }

    [bool] AddLineIntercepts([LineDef]$line) {
        [int]$s1 = 0
        [int]$s2 = 0

        if ($this.Trace.Dx.Data -gt [Fixed]::FromInt(16).Data -or
            $this.Trace.Dy.Data -gt [Fixed]::FromInt(16).Data -or
            $this.Trace.Dx.Data -lt (-[Fixed]::FromInt(16).Data) -or
            $this.Trace.Dy.Data -lt (-[Fixed]::FromInt(16).Data)) {
            $s1 = [Geometry]::PointOnDivLineSide($line.Vertex1.X, $line.Vertex1.Y, $this.Trace)
            $s2 = [Geometry]::PointOnDivLineSide($line.Vertex2.X, $line.Vertex2.Y, $this.Trace)
        } else {
            $s1 = [Geometry]::PointOnLineSide($this.Trace.X, $this.Trace.Y, $line)
            $s2 = [Geometry]::PointOnLineSide($this.Trace.X + $this.Trace.Dx, $this.Trace.Y + $this.Trace.Dy, $line)
        }

        if ($s1 -eq $s2) { return $true }

        $this.Target.MakeFrom($line)
        $frac = $this.InterceptVector($this.Trace, $this.Target)

        if ($frac.Data -lt [Fixed]::Zero.Data) { return $true }

        if ($this.EarlyOut -and $frac.Data -lt [Fixed]::One.Data -and $null -eq $line.BackSector) {
            return $false
        }

        $this.Intercepts[$this.InterceptCount].Make($frac, $line)
        $this.InterceptCount++

        return $true
    }

    [bool] AddThingIntercepts([Mobj]$thing) {
        $tracePositive = (($this.Trace.Dx.Data -bxor $this.Trace.Dy.Data) -gt 0)
        [Fixed]$x1 = [Fixed]::Zero
        [Fixed]$y1 = [Fixed]::Zero
        [Fixed]$x2 = [Fixed]::Zero
        [Fixed]$y2 = [Fixed]::Zero

        if ($tracePositive) {
            $x1 = $thing.X - $thing.Radius
            $y1 = $thing.Y + $thing.Radius
            $x2 = $thing.X + $thing.Radius
            $y2 = $thing.Y - $thing.Radius
        } else {
            $x1 = $thing.X - $thing.Radius
            $y1 = $thing.Y - $thing.Radius
            $x2 = $thing.X + $thing.Radius
            $y2 = $thing.Y + $thing.Radius
        }

        $s1 = [Geometry]::PointOnDivLineSide($x1, $y1, $this.Trace)
        $s2 = [Geometry]::PointOnDivLineSide($x2, $y2, $this.Trace)

        if ($s1 -eq $s2) { return $true }

        $this.Target.X = $x1
        $this.Target.Y = $y1
        $this.Target.Dx = $x2 - $x1
        $this.Target.Dy = $y2 - $y1

        $frac = $this.InterceptVector($this.Trace, $this.Target)

        if ($frac.Data -lt [Fixed]::Zero.Data) { return $true }

        $this.Intercepts[$this.InterceptCount].Make($frac, $thing)
        $this.InterceptCount++

        return $true
    }

    [Fixed] InterceptVector([DivLine]$v2, [DivLine]$v1) {
        $den = (($v1.Dy -shr 8) * $v2.Dx) - (($v1.Dx -shr 8) * $v2.Dy)
        if ($den.Data -eq [Fixed]::Zero.Data) { return [Fixed]::Zero }

        $num = ((($v1.X - $v2.X) -shr 8) * $v1.Dy) + ((($v2.Y - $v1.Y) -shr 8) * $v1.Dx)
        return $num / $den
    }

    [bool] TraverseIntercepts([scriptblock]$func, [Fixed]$maxFrac) {
        $count = $this.InterceptCount

        while ($count -gt 0) {
            $dist = [Fixed]::MaxValue
            $intercept = $null

            for ($i = 0; $i -lt $this.InterceptCount; $i++) {
                if ($this.Intercepts[$i].Frac.Data -lt $dist.Data) {
                    $dist = $this.Intercepts[$i].Frac
                    $intercept = $this.Intercepts[$i]
                }
            }

            if ($dist.Data -gt $maxFrac.Data) { return $true }
            if (-not (&$func $intercept)) { return $false }

            $intercept.Frac = [Fixed]::MaxValue
            $count--
        }

        return $true
    }

    [bool] PathTraverse([Fixed]$x1, [Fixed]$y1, [Fixed]$x2, [Fixed]$y2, [PathTraverseFlags]$flags, [scriptblock]$trav) {
        $this.EarlyOut = ($flags -band [PathTraverseFlags]::EarlyOut) -ne 0
        $validCount = $this.World.GetNewValidCount()
        $bm = $this.World.Map.BlockMap
        $this.InterceptCount = 0

        if (((($x1 - $bm.OriginX).Data) -band ([BlockMap]::BlockSize.Data - 1)) -eq 0) { $x1 += [Fixed]::One }
        if (((($y1 - $bm.OriginY).Data) -band ([BlockMap]::BlockSize.Data - 1)) -eq 0) { $y1 += [Fixed]::One }

        $this.Trace.X = $x1
        $this.Trace.Y = $y1
        $this.Trace.Dx = $x2 - $x1
        $this.Trace.Dy = $y2 - $y1

        $x1 -= $bm.OriginX
        $y1 -= $bm.OriginY
        $blockX1 = $x1.Data -shr [BlockMap]::FracToBlockShift
        $blockY1 = $y1.Data -shr [BlockMap]::FracToBlockShift

        $x2 -= $bm.OriginX
        $y2 -= $bm.OriginY
        $blockX2 = $x2.Data -shr [BlockMap]::FracToBlockShift
        $blockY2 = $y2.Data -shr [BlockMap]::FracToBlockShift

        [Fixed]$stepX = [Fixed]::Zero
        [Fixed]$stepY = [Fixed]::Zero
        [Fixed]$partial = [Fixed]::Zero
        [int]$blockStepX = 0
        [int]$blockStepY = 0

        if ($blockX2 -gt $blockX1) {
            $blockStepX = 1
            $partial = [Fixed]::new([Fixed]::FracUnit - (($x1.Data -shr [BlockMap]::BlockToFracShift) -band ([Fixed]::FracUnit - 1)))
            $stepY = ($y2 - $y1) / [Fixed]::Abs($x2 - $x1)
        } elseif ($blockX2 -lt $blockX1) {
            $blockStepX = -1
            $partial = [Fixed]::new(($x1.Data -shr [BlockMap]::BlockToFracShift) -band ([Fixed]::FracUnit - 1))
            $stepY = ($y2 - $y1) / [Fixed]::Abs($x2 - $x1)
        } else {
            $blockStepX = 0
            $partial = [Fixed]::One
            $stepY = [Fixed]::FromInt(256)
        }

        $interceptY = [Fixed]::new($y1.Data -shr [BlockMap]::BlockToFracShift) + ($partial * $stepY)

        if ($blockY2 -gt $blockY1) {
            $blockStepY = 1
            $partial = [Fixed]::new([Fixed]::FracUnit - (($y1.Data -shr [BlockMap]::BlockToFracShift) -band ([Fixed]::FracUnit - 1)))
            $stepX = ($x2 - $x1) / [Fixed]::Abs($y2 - $y1)
        } elseif ($blockY2 -lt $blockY1) {
            $blockStepY = -1
            $partial = [Fixed]::new(($y1.Data -shr [BlockMap]::BlockToFracShift) -band ([Fixed]::FracUnit - 1))
            $stepX = ($x2 - $x1) / [Fixed]::Abs($y2 - $y1)
        } else {
            $blockStepY = 0
            $partial = [Fixed]::One
            $stepX = [Fixed]::FromInt(256)
        }

        $interceptX = [Fixed]::new($x1.Data -shr [BlockMap]::BlockToFracShift) + ($partial * $stepX)

        $bx = $blockX1
        $by = $blockY1

        for ($count = 0; $count -lt 64; $count++) {
            if (($flags -band [PathTraverseFlags]::AddLines) -ne 0) {
                if (-not $bm.IterateLines($bx, $by, $this.LineInterceptFunc, $validCount)) { return $false }
            }

            if (($flags -band [PathTraverseFlags]::AddThings) -ne 0) {
                if (-not $bm.IterateThings($bx, $by, $this.ThingInterceptFunc)) { return $false }
            }

            if ($bx -eq $blockX2 -and $by -eq $blockY2) { break }

            if ($interceptY.ToIntFloor() -eq $by) {
                $interceptY += $stepY
                $bx += $blockStepX
            } elseif ($interceptX.ToIntFloor() -eq $bx) {
                $interceptX += $stepX
                $by += $blockStepY
            }
        }

        return $this.TraverseIntercepts($trav, [Fixed]::One)
    }

    [DivLine] get_Trace() { return $this.Trace }
}