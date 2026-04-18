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

class Hitscan {
    [World] $World

    [Mobj] $LineTarget
    [Mobj] $CurrentShooter
    [Fixed] $CurrentShooterZ
    [Fixed] $CurrentRange
    [Fixed] $CurrentAimSlope
    [int] $CurrentDamage
    [Fixed] $TopSlope
    [Fixed] $BottomSlope

    Hitscan([World] $world) {
        $this.World = $world
    }

    [bool] AimTraverse([Intercept] $intercept) {
        if ($null -ne $intercept.Line) {
            $line = $intercept.Line

            if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) {
                return $false
            }

            $mc = $this.World.MapCollision
            $mc.LineOpening($line)

            if ($mc.OpenBottom.Data -ge $mc.OpenTop.Data) {
                return $false
            }

            $dist = $this.CurrentRange * $intercept.Frac

            if ($null -eq $line.BackSector -or $line.FrontSector.FloorHeight.Data -ne $line.BackSector.FloorHeight.Data) {
                $slope = ($mc.OpenBottom - $this.CurrentShooterZ) / $dist
                if ($slope.Data -gt $this.BottomSlope.Data) {
                    $this.BottomSlope = $slope
                }
            }

            if ($null -eq $line.BackSector -or $line.FrontSector.CeilingHeight.Data -ne $line.BackSector.CeilingHeight.Data) {
                $slope = ($mc.OpenTop - $this.CurrentShooterZ) / $dist
                if ($slope.Data -lt $this.TopSlope.Data) {
                    $this.TopSlope = $slope
                }
            }

            if ($this.TopSlope.Data -le $this.BottomSlope.Data) {
                return $false
            }

            return $true
        }

        $thing = $intercept.Thing
        if ($thing -eq $this.CurrentShooter) {
            return $true
        }

        if (([int]($thing.Flags -band [MobjFlags]::Shootable)) -eq 0) {
            return $true
        }

        $dist = $this.CurrentRange * $intercept.Frac
        $thingTopSlope = ($thing.Z + $thing.Height - $this.CurrentShooterZ) / $dist

        if ($thingTopSlope.Data -lt $this.BottomSlope.Data) {
            return $true
        }

        $thingBottomSlope = ($thing.Z - $this.CurrentShooterZ) / $dist

        if ($thingBottomSlope.Data -gt $this.TopSlope.Data) {
            return $true
        }

        if ($thingTopSlope.Data -gt $this.TopSlope.Data) {
            $thingTopSlope = $this.TopSlope
        }

        if ($thingBottomSlope.Data -lt $this.BottomSlope.Data) {
            $thingBottomSlope = $this.BottomSlope
        }

        $this.CurrentAimSlope = ($thingTopSlope + $thingBottomSlope) / 2
        $this.LineTarget = $thing

        return $false
    }

    [void] SpawnPuff([Fixed] $x, [Fixed] $y, [Fixed] $z) {
        $random = $this.World.Random
        $z += [Fixed]::new(($random.Next() - $random.Next()) -shl 10)

        $thing = $this.World.ThingAllocation.SpawnMobj($x, $y, $z, [MobjType]::Puff)
        $thing.MomZ = [Fixed]::One
        $thing.Tics -= $random.Next() -band 3

        if ($thing.Tics -lt 1) {
            $thing.Tics = 1
        }

        if ($this.CurrentRange.Data -eq [WeaponBehavior]::MeleeRange.Data) {
            $thing.SetState([MobjState]::Puff3)
        }
    }

    [void] SpawnBlood([Fixed] $x, [Fixed] $y, [Fixed] $z, [int] $damage) {
        $random = $this.World.Random
        $z += [Fixed]::new(($random.Next() - $random.Next()) -shl 10)

        $thing = $this.World.ThingAllocation.SpawnMobj($x, $y, $z, [MobjType]::Blood)
        $thing.MomZ = [Fixed]::FromInt(2)
        $thing.Tics -= $random.Next() -band 3

        if ($thing.Tics -lt 1) {
            $thing.Tics = 1
        }

        if ($damage -le 12 -and $damage -ge 9) {
            $thing.SetState([MobjState]::Blood2)
        } elseif ($damage -lt 9) {
            $thing.SetState([MobjState]::Blood3)
        }
    }

    [Fixed] AimLineAttack([Mobj] $shooter, [Angle] $angle, [Fixed] $range) {
        $shooter = $this.World.SubstNullMobj($shooter)

        $this.CurrentShooter = $shooter
        $this.CurrentShooterZ = $shooter.Z + ($shooter.Height -shr 1) + [Fixed]::FromInt(8)
        $this.CurrentRange = $range

        $targetX = $shooter.X + $range.ToIntFloor() * [Trig]::Cos($angle)
        $targetY = $shooter.Y + $range.ToIntFloor() * [Trig]::Sin($angle)

        $this.TopSlope = [Fixed]::FromInt(100) / 160
        $this.BottomSlope = [Fixed]::FromInt(-100) / 160

        $this.LineTarget = $null

        $owner = $this

        $this.World.PathTraversal.PathTraverse(
            $shooter.X, $shooter.Y, $targetX, $targetY,
            [PathTraverseFlags]::AddLines -bor [PathTraverseFlags]::AddThings,
            { param($intercept) $owner.AimTraverse($intercept) }.GetNewClosure()
        )

        if ($null -ne $this.LineTarget) {
            return $this.CurrentAimSlope
        }

        return [Fixed]::Zero
    }

    [void] LineAttack([Mobj] $shooter, [Angle] $angle, [Fixed] $range, [Fixed] $slope, [int] $damage) {
        $this.CurrentShooter = $shooter
        $this.CurrentShooterZ = $shooter.Z + ($shooter.Height -shr 1) + [Fixed]::FromInt(8)
        $this.CurrentRange = $range
        $this.CurrentAimSlope = $slope
        $this.CurrentDamage = $damage

        $targetX = $shooter.X + $range.ToIntFloor() * [Trig]::Cos($angle)
        $targetY = $shooter.Y + $range.ToIntFloor() * [Trig]::Sin($angle)

        $owner = $this

        $this.World.PathTraversal.PathTraverse(
            $shooter.X, $shooter.Y, $targetX, $targetY,
            [PathTraverseFlags]::AddLines -bor [PathTraverseFlags]::AddThings,
            { param($intercept) $owner.ShootTraverse($intercept) }.GetNewClosure()
        )
    }
    # Fire a hitscan bullet along the aiming line.
    [bool] ShootTraverse([Intercept] $intercept) {
        $mi = $this.world.MapInteraction
        $pt = $this.world.PathTraversal

        if ($null -ne $intercept.Line) {
            $line = $intercept.Line
            $hitLine = $false

            if ($line.Special -ne 0) {
                $mi.ShootSpecialLine($this.currentShooter, $line)
            }

            if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) {
                $hitLine = $true
            }

            $mc = $this.world.MapCollision

            # Crosses a two-sided line.
            $mc.LineOpening($line)

            $dist = $this.currentRange * $intercept.Frac

            # Similar to AimTraverse, the code below is imported from Chocolate Doom.
            if (-not $hitLine -and $null -eq $line.BackSector) {
                $slope = ($mc.OpenBottom - $this.currentShooterZ) / $dist
                if ($slope.Data -gt $this.currentAimSlope.Data) {
                    $hitLine = $true
                }

                $slope = ($mc.OpenTop - $this.currentShooterZ) / $dist
                if ($slope.Data -lt $this.currentAimSlope.Data) {
                    $hitLine = $true
                }
            } elseif (-not $hitLine) {
                if ($line.FrontSector.FloorHeight.Data -ne $line.BackSector.FloorHeight.Data) {
                    $slope = ($mc.OpenBottom - $this.currentShooterZ) / $dist
                    if ($slope.Data -gt $this.currentAimSlope.Data) {
                        $hitLine = $true
                    }
                }

                if (-not $hitLine -and $line.FrontSector.CeilingHeight.Data -ne $line.BackSector.CeilingHeight.Data) {
                    $slope = ($mc.OpenTop - $this.currentShooterZ) / $dist
                    if ($slope.Data -lt $this.currentAimSlope.Data) {
                        $hitLine = $true
                    }
                }
            }

            # Shot continues.
            if (-not $hitLine) {
                return $true
            }

            # Position a bit closer.
            $frac = $intercept.Frac - ([Fixed]::FromInt(4) / $this.currentRange)
            $x = $pt.Trace.X + ($pt.Trace.Dx * $frac)
            $y = $pt.Trace.Y + ($pt.Trace.Dy * $frac)
            $z = $this.currentShooterZ + ($this.currentAimSlope * ($frac * $this.currentRange))

            if ($line.FrontSector.CeilingFlat -eq $this.world.Map.SkyFlatNumber) {
                # Don't shoot the sky!
                if ($z.Data -gt $line.FrontSector.CeilingHeight.Data) {
                    return $false
                }

                # It's a sky hack wall.
                if ($null -ne $line.BackSector -and $line.BackSector.CeilingFlat -eq $this.world.Map.SkyFlatNumber) {
                    return $false
                }
            }

            # Spawn bullet puffs.
            $this.SpawnPuff($x, $y, $z)

            # Don't go any farther.
            return $false
        }

        # Shoot a thing.
        $thing = $intercept.Thing
        if ($thing -eq $this.currentShooter) {
            # Can't shoot self.
            return $true
        }

        if (([int]($thing.Flags -band [MobjFlags]::Shootable)) -eq 0) {
            # Corpse or something.
            return $true
        }

        # Check angles to see if the thing can be aimed at.
        $dist = $this.currentRange * $intercept.Frac
        $thingTopSlope = ($thing.Z + $thing.Height - $this.currentShooterZ) / $dist

        if ($thingTopSlope.Data -lt $this.currentAimSlope.Data) {
            # Shot over the thing.
            return $true
        }

        $thingBottomSlope = ($thing.Z - $this.currentShooterZ) / $dist

        if ($thingBottomSlope.Data -gt $this.currentAimSlope.Data) {
            # Shot under the thing.
            return $true
        }

        # Hit thing.
        # Position a bit closer.
        $frac = $intercept.Frac - ([Fixed]::FromInt(10) / $this.currentRange)
        $x = $pt.Trace.X + ($pt.Trace.Dx * $frac)
        $y = $pt.Trace.Y + ($pt.Trace.Dy * $frac)
        $z = $this.currentShooterZ + ($this.currentAimSlope * ($frac * $this.currentRange))

        # Spawn bullet puffs or blood spots, depending on target type.
        if (([int]($intercept.Thing.Flags -band [MobjFlags]::NoBlood)) -ne 0) {
            $this.SpawnPuff($x, $y, $z)
        } else {
            $this.SpawnBlood($x, $y, $z, $this.currentDamage)
        }

        if ($this.currentDamage -ne 0) {
            $this.world.ThingInteraction.DamageMobj($thing, $this.currentShooter, $this.currentShooter, $this.currentDamage)
        }

        # Don't go any farther.
        return $false
    }

}
