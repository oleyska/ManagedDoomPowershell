class Geometry {
    static [int] $slopeRange = 2048
    static [int] $slopeBits = 11
    static [int] $fracToSlopeShift = 16 - 11  # Assuming Fixed.FracBits = 16





    static [double] ApproxDistance([double] $dx, [double] $dy) {
        $dx = [Math]::Abs($dx)
        $dy = [Math]::Abs($dy)
        return if ($dx -lt $dy) { $dx + $dy - ($dx / 2) } else { $dx + $dy - ($dy / 2) }
    }
    static [uint] SlopeDiv([int] $num, [int] $den) {
        if ($den -lt 512) {
            return [Geometry]::slopeRange
        }

        [uint64] $numUnsigned = [uint32]$num
        [uint64] $denUnsigned = [uint32]$den
        [uint64] $ans = ($numUnsigned -shl 3) / ($denUnsigned -shr 8)

        if ($ans -gt [Geometry]::slopeRange) {
            return [Geometry]::slopeRange
        }

        return [uint]$ans
    }
    ### <summary>
    ### Calculate the distance between the two points.
    ### </summary>
    static [Fixed] PointToDist([Fixed] $fromX, [Fixed] $fromY, [Fixed] $toX, [Fixed] $toY) {
        $dx = [Fixed]::Abs($toX - $fromX)
        $dy = [Fixed]::Abs($toY - $fromY)

        if ($dy.Data -gt $dx.Data) {
            $temp = $dx
            $dx = $dy
            $dy = $temp
        }

        [Fixed] $frac = $null
        if ($dx.Data -ne [Fixed]::Zero.Data) {
            $frac = $dy / $dx
        } else {
            $frac = [Fixed]::Zero
        }

        $angle = [Trig]::TanToAngle(([uint32]$frac.Data) -shr [Geometry]::fracToSlopeShift) + [Angle]::Ang90
        $dist = $dx / [Trig]::Sin($angle)
        return $dist
    }
    ### <summary>
    ### Calculate on which side of the node the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back).
    ### </returns>
    static [int] PointOnSide([Fixed] $x, [Fixed] $y, $node) {
        if ($node.Dx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -le $node.X.Data) {
                return $(if ($node.Dy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($node.Dy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        if ($node.Dy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -le $node.Y.Data) {
                return $(if ($node.Dx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($node.Dx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        $dx = ($x - $node.X)
        $dy = ($y - $node.Y)
        if ((([int]$node.Dy.data -bxor [int]$node.Dx.data -bxor [int]$dx.data -bxor [int]$dy.data) -band 0x80000000) -ne 0) {
            return $(if ((($node.Dy.data -bxor $dx.data) -band 0x80000000) -ne 0) { 1 } else { 0 })
        }

        $left = [Fixed]::new($node.Dy.Data -shr [Fixed]::FracBits) * $dx
        $right = $dy * [Fixed]::new($node.Dx.Data -shr [Fixed]::FracBits)

        return $(if ($right.Data -lt $left.Data) { 0 } else { 1 })
    }
    ### <summary>
    ### Calculate the angle of the line passing through the two points.
    ### </summary>
    static [Angle] PointToAngle([Fixed] $fromX, [Fixed] $fromY, [Fixed] $toX, [Fixed] $toY) {
        $x = $toX - $fromX
        $y = $toY - $fromY

        if ($x.Data -eq [Fixed]::Zero.Data -and $y.Data -eq [Fixed]::Zero.Data) {
            return [Angle]::Ang0
        }

        if ($x.Data -ge [Fixed]::Zero.Data) {
            # x >= 0
            if ($y.Data -ge [Fixed]::Zero.Data) {
                # y >= 0
                if ($x.Data -gt $y.Data) {
                    # octant 0
                    return [Trig]::TanToAngle([Geometry]::SlopeDiv($y.Data, $x.Data))
                } else {
                    # octant 1
                    return [Angle]::new([Angle]::Ang90.Data - 1) - [Trig]::TanToAngle([Geometry]::SlopeDiv($x.Data, $y.Data))
                }
            } else {
                # y < 0
                $y = -$y

                if ($x.Data -gt $y.Data) {
                    # octant 8
                    return -[Trig]::TanToAngle([Geometry]::SlopeDiv($y.Data, $x.Data))
                } else {
                    # octant 7
                    return [Angle]::Ang270 + [Trig]::TanToAngle([Geometry]::SlopeDiv($x.Data, $y.Data))
                }
            }
        } else {
            # x < 0
            $x = -$x

            if ($y.Data -ge [Fixed]::Zero.Data) {
                # y >= 0
                if ($x.Data -gt $y.Data) {
                    # octant 3
                    return [Angle]::new([Angle]::Ang180.Data - 1) - [Trig]::TanToAngle([Geometry]::SlopeDiv($y.Data, $x.Data))
                } else {
                    # octant 2
                    return [Angle]::Ang90 + [Trig]::TanToAngle([Geometry]::SlopeDiv($x.Data, $y.Data))
                }
            } else {
                # y < 0
                $y = -$y

                if ($x.Data -gt $y.Data) {
                    # octant 4
                    return [Angle]::Ang180 + [Trig]::TanToAngle([Geometry]::SlopeDiv($y.Data, $x.Data))
                } else {
                    # octant 5
                    return [Angle]::new([Angle]::Ang270.Data - 1) - [Trig]::TanToAngle([Geometry]::SlopeDiv($x.Data, $y.Data))
                }
            }
        }
    }
    ### <summary>
    ### Get the subsector which contains the point.
    ### </summary>
    static [Subsector] PointInSubsector([Fixed] $x, [Fixed] $y, $map) # should really be [map]$map
    #but ... Cannot convert argument "map", with value: "Map", for "PointInSubsector" to type "Map": "Cannot convert the "Map" value of type "Map" to type "Map"."
        {
        # Single subsector is a special case
        if ($map.Nodes.Count -eq 0) {
            return $map.Subsectors[0]
        }

        $nodeNumber = $map.Nodes.Count - 1

        while (-not [Node]::IsSubsector($nodeNumber)) {
            $node = $map.Nodes[$nodeNumber]
            $side = [Geometry]::PointOnSide($x, $y, $node)
            $nodeNumber = $node.Children[$side]
        }
        return $map.Subsectors[[Node]::GetSubsector($nodeNumber)]

    }
    ### <summary>
    ### Calculate on which side of the line the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back).
    ### </returns>
    static [int] PointOnSegSide([Fixed] $x, [Fixed] $y, [Seg] $line) {
        $lx = $line.Vertex1.X
        $ly = $line.Vertex1.Y

        $ldx = $line.Vertex2.X - $lx
        $ldy = $line.Vertex2.Y - $ly

        if ($ldx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -le $lx.Data) {
                return $(if ($ldy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($ldy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        if ($ldy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -le $ly.Data) {
                return $(if ($ldx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($ldx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        $dx = $x - $lx
        $dy = $y - $ly

        # Try to quickly decide by looking at sign bits.
        if ((($ldy.Data -bxor $ldx.Data -bxor $dx.Data -bxor $dy.Data) -band 0x80000000) -ne 0) {
            if ((($ldy.Data -bxor $dx.Data) -band 0x80000000) -ne 0) {
                # Left is negative.
                return 1
            } else {
                return 0
            }
        }

        $left = [Fixed]::new($ldy.Data -shr [Fixed]::FracBits) * $dx
        $right = $dy * [Fixed]::new($ldx.Data -shr [Fixed]::FracBits)

        if ($right.Data -lt $left.Data) {
            # Front side.
            return 0
        } else {
            # Back side.
            return 1
        }
    }
    ### <summary>
    ### Calculate on which side of the line the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back).
    ### </returns>
    static [int] PointOnLineSide([Fixed] $x, [Fixed] $y, [LineDef] $line) {
        if ($line.Dx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -le $line.Vertex1.X.Data) {
                return $(if ($line.Dy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($line.Dy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        if ($line.Dy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -le $line.Vertex1.Y.Data) {
                return $(if ($line.Dx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($line.Dx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        $dx = $x - $line.Vertex1.X
        $dy = $y - $line.Vertex1.Y

        $left = [Fixed]::new($line.Dy.Data -shr [Fixed]::FracBits) * $dx
        $right = $dy * [Fixed]::new($line.Dx.Data -shr [Fixed]::FracBits)

        if ($right.Data -lt $left.Data) {
            # Front side.
            return 0
        } else {
            # Back side.
            return 1
        }
    }
    ### <summary>
    ### Calculate on which side of the line the box is.
    ### </summary>
    ### <returns>
    ### 0 (front), 1 (back), or -1 if the box crosses the line.
    ### </returns>
    static [int] BoxOnLineSide([Fixed[]] $box, [LineDef] $line) {
        [int] $p1 = 0
        [int] $p2 = 0

        switch ($line.SlopeType) {
            "Horizontal" {
                $p1 = $(if ($box[[Box]::Top].Data -gt $line.Vertex1.Y.Data) { 1 } else { 0 })
                $p2 = $(if ($box[[Box]::Bottom].Data -gt $line.Vertex1.Y.Data) { 1 } else { 0 })
                if ($line.Dx.Data -lt [Fixed]::Zero.Data) {
                    $p1 = $p1 -bxor 1
                    $p2 = $p2 -bxor 1
                }
            }
            "Vertical" {
                $p1 = $(if ($box[[Box]::Right].Data -lt $line.Vertex1.X.Data) { 1 } else { 0 })
                $p2 = $(if ($box[[Box]::Left].Data -lt $line.Vertex1.X.Data) { 1 } else { 0 })
                if ($line.Dy.Data -lt [Fixed]::Zero.Data) {
                    $p1 = $p1 -bxor 1
                    $p2 = $p2 -bxor 1
                }
            }
            "Positive" {
                $p1 = [Geometry]::PointOnLineSide($box[[Box]::Left], $box[[Box]::Top], $line)
                $p2 = [Geometry]::PointOnLineSide($box[[Box]::Right], $box[[Box]::Bottom], $line)
            }
            "Negative" {
                $p1 = [Geometry]::PointOnLineSide($box[[Box]::Right], $box[[Box]::Top], $line)
                $p2 = [Geometry]::PointOnLineSide($box[[Box]::Left], $box[[Box]::Bottom], $line)
            }
            default {
                throw "Invalid SlopeType."
            }
        }

        if ($p1 -eq $p2) {
            return $p1
        } else {
            return -1
        }
    }
    ### <summary>
    ### Calculate on which side of the line the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back).
    ### </returns>
    static [int] PointOnDivLineSide([Fixed] $x, [Fixed] $y, [DivLine] $line) {
        if ($line.Dx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -le $line.X.Data) {
                return $(if ($line.Dy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($line.Dy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        if ($line.Dy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -le $line.Y.Data) {
                return $(if ($line.Dx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            } else {
                return $(if ($line.Dx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }
        }

        $dx = $x - $line.X
        $dy = $y - $line.Y

        # Try to quickly decide by looking at sign bits.
        if ((($line.Dy.Data -bxor $line.Dx.Data -bxor $dx.Data -bxor $dy.Data) -band 0x80000000) -ne 0) {
            if ((($line.Dy.Data -bxor $dx.Data) -band 0x80000000) -ne 0) {
                # Left is negative.
                return 1
            } else {
                return 0
            }
        }

        $left = [Fixed]::new($line.Dy.Data -shr 8) * [Fixed]::new($dx.Data -shr 8)
        $right = [Fixed]::new($dy.Data -shr 8) * [Fixed]::new($line.Dx.Data -shr 8)

        if ($right.Data -lt $left.Data) {
            # Front side.
            return 0
        } else {
            # Back side.
            return 1
        }
    }
    ### <summary>
    ### Gives an estimation of distance (not exact).
    ### </summary>
    static [Fixed] AproxDistance([Fixed] $dx, [Fixed] $dy) {
        $dx = [Fixed]::Abs($dx)
        $dy = [Fixed]::Abs($dy)

        if ($dx.Data -lt $dy.Data) {
            return $dx + $dy - ($dx -shr 1)
        } else {
            return $dx + $dy - ($dy -shr 1)
        }
    }
    ### <summary>
    ### Calculate on which side of the line the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back), or 2 if the box crosses the line.
    ### </returns>
    static [int] DivLineSide([Fixed] $x, [Fixed] $y, [DivLine] $line) {
        if ($line.Dx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -eq $line.X.Data) {
                return 2
            }

            if ($x.Data -le $line.X.Data) {
                return $(if ($line.Dy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }

            return $(if ($line.Dy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
        }

        if ($line.Dy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -eq $line.Y.Data) {
                return 2
            }

            if ($y.Data -le $line.Y.Data) {
                return $(if ($line.Dx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }

            return $(if ($line.Dx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
        }

        $dx = $x - $line.X
        $dy = $y - $line.Y

        $left = [Fixed]::new(($line.Dy.Data -shr [Fixed]::FracBits) * ($dx.Data -shr [Fixed]::FracBits))
        $right = [Fixed]::new(($dy.Data -shr [Fixed]::FracBits) * ($line.Dx.Data -shr [Fixed]::FracBits))

        if ($right.Data -lt $left.Data) {
            # Front side.
            return 0
        }

        if ($left.Data -eq $right.Data) {
            return 2
        } else {
            # Back side.
            return 1
        }
    }
    ### <summary>
    ### Calculate on which side of the line the point is.
    ### </summary>
    ### <returns>
    ### 0 (front) or 1 (back), or 2 if the box crosses the line.
    ### </returns>
    static [int] DivLineSide([Fixed] $x, [Fixed] $y, [Node] $node) {
        if ($node.Dx.Data -eq [Fixed]::Zero.Data) {
            if ($x.Data -eq $node.X.Data) {
                return 2
            }

            if ($x.Data -le $node.X.Data) {
                return $(if ($node.Dy.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
            }

            return $(if ($node.Dy.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
        }

        if ($node.Dy.Data -eq [Fixed]::Zero.Data) {
            if ($y.Data -eq $node.Y.Data) {
                return 2
            }

            if ($y.Data -le $node.Y.Data) {
                return $(if ($node.Dx.Data -lt [Fixed]::Zero.Data) { 1 } else { 0 })
            }

            return $(if ($node.Dx.Data -gt [Fixed]::Zero.Data) { 1 } else { 0 })
        }

        $dx = $x - $node.X
        $dy = $y - $node.Y

        $left = [Fixed]::new(($node.Dy.Data -shr [Fixed]::FracBits) * ($dx.Data -shr [Fixed]::FracBits))
        $right = [Fixed]::new(($dy.Data -shr [Fixed]::FracBits) * ($node.Dx.Data -shr [Fixed]::FracBits))

        if ($right.Data -lt $left.Data) {
            # Front side.
            return 0
        }

        if ($left.Data -eq $right.Data) {
            return 2
        } else {
            # Back side.
            return 1
        }
    }
}
