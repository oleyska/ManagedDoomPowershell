class VisibilityCheck {
    [World] $World

    # Eye z of looker.
    [Fixed] $SightZStart
    [Fixed] $BottomSlope
    [Fixed] $TopSlope

    # From looker to target.
    [DivLine] $Trace
    [Fixed] $TargetX
    [Fixed] $TargetY

    [DivLine] $Occluder

    VisibilityCheck([World] $world) {
        $this.World = $world
        $this.Trace = [DivLine]::new()
        $this.Occluder = [DivLine]::new()
    }

    [Fixed] InterceptVector([DivLine] $v2, [DivLine] $v1) {
        $den = ($v1.Dy -shr 8) * $v2.Dx - ($v1.Dx -shr 8) * $v2.Dy

        if ($den -eq [Fixed]::Zero) {
            return [Fixed]::Zero
        }

        $num = (($v1.X - $v2.X) -shr 8) * $v1.Dy + (($v2.Y - $v1.Y) -shr 8) * $v1.Dx

        return $num / $den
    }

    [bool] CrossSubsector([int] $subsectorNumber, [int] $validCount) {
        $map = $this.World.Map
        $subsector = $map.Subsectors[$subsectorNumber]
        $count = $subsector.SegCount

        for ($i = 0; $i -lt $count; $i++) {
            $seg = $map.Segs[$subsector.FirstSeg + $i]
            $line = $seg.LineDef

            if ($line.ValidCount -eq $validCount) { continue }

            $line.ValidCount = $validCount

            $v1 = $line.Vertex1
            $v2 = $line.Vertex2
            $s1 = [Geometry]::DivLineSide($v1.X, $v1.Y, $this.Trace)
            $s2 = [Geometry]::DivLineSide($v2.X, $v2.Y, $this.Trace)

            if ($s1 -eq $s2) { continue }

            $this.Occluder.MakeFrom($line)
            $s1 = [Geometry]::DivLineSide($this.Trace.X, $this.Trace.Y, $this.Occluder)
            $s2 = [Geometry]::DivLineSide($this.TargetX, $this.TargetY, $this.Occluder)

            if ($s1 -eq $s2) { continue }

            if ($null -eq $line.BackSector) { return $false }

            if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) { return $false }

            $front = $seg.FrontSector
            $back = $seg.BackSector

            if ($front.FloorHeight.Data -eq $back.FloorHeight.Data -and $front.CeilingHeight.Data -eq $back.CeilingHeight.Data) {
                continue
            }

            $openTop = [Fixed]::Zero
            if ($front.CeilingHeight.Data -lt $back.CeilingHeight.Data) {
                $openTop = $front.CeilingHeight
            } else {
                $openTop = $back.CeilingHeight
            }

            $openBottom = [Fixed]::Zero
            if ($front.FloorHeight.Data -gt $back.FloorHeight.Data) {
                $openBottom = $front.FloorHeight
            } else {
                $openBottom = $back.FloorHeight
            }

            if ($openBottom.Data -ge $openTop.Data) { return $false }

            $frac = $this.InterceptVector($this.Trace, $this.Occluder)

            if ($front.FloorHeight.Data -ne $back.FloorHeight.Data) {
                $slope = ($openBottom - $this.SightZStart) / $frac
                if ($slope.Data -gt $this.BottomSlope.Data) {
                    $this.BottomSlope = $slope
                }
            }

            if ($front.CeilingHeight.Data -ne $back.CeilingHeight.Data) {
                $slope = ($openTop - $this.SightZStart) / $frac
                if ($slope.Data -lt $this.TopSlope.Data) {
                    $this.TopSlope = $slope
                }
            }

            if ($this.TopSlope.Data -le $this.BottomSlope.Data) { return $false }
        }

        return $true
    }

    [bool] CrossBspNode([int] $nodeNumber, [int] $validCount) {
        if ([Node]::IsSubsector($nodeNumber)) {
            if ($nodeNumber -eq -1) {
                return $this.CrossSubsector(0, $validCount)
            } else {
                return $this.CrossSubsector([Node]::GetSubsector($nodeNumber), $validCount)
            }
        }

        $node = $this.World.Map.Nodes[$nodeNumber]
        $side = [Geometry]::DivLineSide($this.Trace.X, $this.Trace.Y, $node)

        if ($side -eq 2) { $side = 0 }

        if (-not $this.CrossBspNode($node.Children[$side], $validCount)) {
            return $false
        }

        if ($side -eq [Geometry]::DivLineSide($this.TargetX, $this.TargetY, $node)) {
            return $true
        }

        return $this.CrossBspNode($node.Children[$side -bxor 1], $validCount)
    }

    [bool] CheckSight([Mobj] $looker, [Mobj] $target) {
        $map = $this.World.Map

        if ($map.Reject.Check($looker.Subsector.Sector, $target.Subsector.Sector)) {
            return $false
        }

        $this.SightZStart = $looker.Z + $looker.Height - ($looker.Height -shr 2)
        $this.TopSlope = ($target.Z + $target.Height) - $this.SightZStart
        $this.BottomSlope = $target.Z - $this.SightZStart

        $this.Trace.X = $looker.X
        $this.Trace.Y = $looker.Y
        $this.Trace.Dx = $target.X - $looker.X
        $this.Trace.Dy = $target.Y - $looker.Y

        $this.TargetX = $target.X
        $this.TargetY = $target.Y

        return $this.CrossBspNode($map.Nodes.Length - 1, $this.World.GetNewValidCount())
    }
}