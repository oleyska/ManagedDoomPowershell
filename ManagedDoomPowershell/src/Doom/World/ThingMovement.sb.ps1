class ThingMovement {
    [World] $world

    ThingMovement([World] $world) {
        $this.world = $world

        $this.InitThingMovement()
        $this.InitSlideMovement()
        $this.InitTeleportMovement()
    }

    ############################################################
    # General thing movement
    ############################################################

    static [Fixed] $FloatSpeed = [Fixed]::FromInt(4)

    static [int] $maxSpecialCrossCount = 64
    static [Fixed] $maxMove = [Fixed]::FromInt(30)
    static [Fixed] $gravity = [Fixed]::One

    [Mobj] $currentThing
    [MobjFlags] $currentFlags
    [Fixed] $currentX
    [Fixed] $currentY
    [Fixed[]] $currentBox

    [Fixed] $currentFloorZ
    [Fixed] $currentCeilingZ
    [Fixed] $currentDropoffZ
    [bool] $floatOk

    [LineDef] $currentCeilingLine

    [int] $crossedSpecialCount
    [LineDef[]] $crossedSpecials

    [scriptblock] $checkLineFunc
    [scriptblock] $checkThingFunc

    [void] InitThingMovement() {
        $maxSpecial = [ThingMovement]::maxSpecialCrossCount
        $this.currentBox = New-Object Fixed[] 4
        $this.crossedSpecials = New-Object LineDef[] $maxSpecial
        $owner = $this
        $this.checkLineFunc = { param($line) $owner.CheckLine($line) }.GetNewClosure()
        $this.checkThingFunc = { param($thing) $owner.CheckThing($thing) }.GetNewClosure()
    }

    # Links a thing into both a block and a subsector based on
    # its x and y. Sets thing.Subsector properly.
    [void] SetThingPosition([Mobj] $thing) {
        $map = $this.world.Map

        $subsector = [Geometry]::PointInSubsector($thing.X, $thing.Y, $map)

        $thing.Subsector = $subsector

        # Invisible things don't go into the sector links.
        if (($thing.Flags -band [MobjFlags]::NoSector) -eq 0) {
            $sector = $subsector.Sector

            $thing.SectorPrev = $null
            $thing.SectorNext = $sector.ThingList

            if ($null -ne $sector.ThingList) {
                $sector.ThingList.SectorPrev = $thing
            }

            $sector.ThingList = $thing
        }

        # Inert things don't need to be in blockmap.
        if (($thing.Flags -band [MobjFlags]::NoBlockMap) -eq 0) {
            $index = $map.BlockMap.GetIndex($thing.X, $thing.Y)

            if ($index -ne -1) {
                $link = $map.BlockMap.ThingLists[$index]

                $thing.BlockPrev = $null
                $thing.BlockNext = $link

                if ($null -ne $link) {
                    $link.BlockPrev = $thing
                }

                $map.BlockMap.ThingLists[$index] = $thing
            } else {
                # Thing is off the map.
                $thing.BlockNext = $null
                $thing.BlockPrev = $null
            }
        }
    }
    # Unlinks a thing from block map and sectors.
    # On each position change, BLOCKMAP and other lookups
    # maintaining lists of things inside these structures
    # need to be updated.
    [void] UnsetThingPosition([Mobj] $thing) {
        $map = $this.world.Map

        # Invisible things don't go into the sector links.
        if (($thing.Flags -band [MobjFlags]::NoSector) -eq 0) {
            # Unlink from subsector.
            if ($null -ne $thing.SectorNext) {
                $thing.SectorNext.SectorPrev = $thing.SectorPrev
            }

            if ($null -ne $thing.SectorPrev) {
                $thing.SectorPrev.SectorNext = $thing.SectorNext
            } else {
                $thing.Subsector.Sector.ThingList = $thing.SectorNext
            }
        }

        # Inert things don't need to be in blockmap.
        if (($thing.Flags -band [MobjFlags]::NoBlockMap) -eq 0) {
            # Unlink from block map.
            if ($null -ne $thing.BlockNext) {
                $thing.BlockNext.BlockPrev = $thing.BlockPrev
            }

            if ($null -ne $thing.BlockPrev) {
                $thing.BlockPrev.BlockNext = $thing.BlockNext
            } else {
                $index = $map.BlockMap.GetIndex($thing.X, $thing.Y)

                if ($index -ne -1) {
                    $map.BlockMap.ThingLists[$index] = $thing.BlockNext
                }
            }
        }
    }
    # Adjusts currentFloorZ and currentCeilingZ as lines are contacted.
    [bool] CheckLine([LineDef] $line) {
        $mc = $this.world.MapCollision

        if ($this.currentBox[[Box]::Right].Data -le $line.BoundingBox[[Box]::Left].Data -or
            $this.currentBox[[Box]::Left].Data -ge $line.BoundingBox[[Box]::Right].Data -or
            $this.currentBox[[Box]::Top].Data -le $line.BoundingBox[[Box]::Bottom].Data -or
            $this.currentBox[[Box]::Bottom].Data -ge $line.BoundingBox[[Box]::Top].Data) {
            return $true
        }

        if ([Geometry]::BoxOnLineSide($this.currentBox, $line) -ne -1) {
            return $true
        }

        # A line has been hit.
        #
        # The moving thing's destination position will cross the given line.
        # If this should not be allowed, return false.
        # If the line is special, keep track of it to process later if the move is proven ok.
        #
        # NOTE:
        #     Specials are NOT sorted by order, so two special lines that are only 8 pixels
        #     apart could be crossed in either order.

        if ($null -eq $line.BackSector) {
            # One-sided line.
            return $false
        }

        if (($this.currentThing.Flags -band [MobjFlags]::Missile) -eq 0) {
            if (($line.Flags -band [LineFlags]::Blocking) -ne 0) {
                # Explicitly blocking everything.
                return $false
            }

            if ($null -eq $this.currentThing.Player -and ($line.Flags -band [LineFlags]::BlockMonsters) -ne 0) {
                # Block monsters only.
                return $false
            }
        }

        # Set openrange, opentop, openbottom.
        $mc.LineOpening($line)

        # Adjust floor / ceiling heights.
        if ($mc.OpenTop.Data -lt $this.currentCeilingZ.Data) {
            $this.currentCeilingZ = $mc.OpenTop
            $this.currentCeilingLine = $line
        }

        if ($mc.OpenBottom.Data -gt $this.currentFloorZ.Data) {
            $this.currentFloorZ = $mc.OpenBottom
        }

        if ($mc.LowFloor.Data -lt $this.currentDropoffZ.Data) {
            $this.currentDropoffZ = $mc.LowFloor
        }

        # If contacted a special line, add it to the list.
        if ($line.Special -ne 0) {
            $this.crossedSpecials[$this.crossedSpecialCount] = $line
            $this.crossedSpecialCount++
        }

        return $true
    }
    # Checks collision and interactions with other objects.
    [bool] CheckThing([Mobj] $thing) {
        if ([int]($thing.Flags -band ([MobjFlags]::Solid -bor [MobjFlags]::Special -bor [MobjFlags]::Shootable)) -eq 0) {
            return $true
        }

        $blockDist = $thing.Radius + $this.currentThing.Radius

        if ([Fixed]::Abs($thing.X - $this.currentX).Data -ge $blockDist.Data -or
            [Fixed]::Abs($thing.Y - $this.currentY).Data -ge $blockDist.Data) {
            # Didn't hit it.
            return $true
        }

        # Don't clip against self.
        if ($thing -eq $this.currentThing) {
            return $true
        }

        # Check for skulls slamming into things.
        if ([int]($this.currentThing.Flags -band [MobjFlags]::SkullFly) -ne 0) {
            $damage = ((($this.world.Random.Next() % 8) + 1) * $this.currentThing.Info.Damage)

            $this.world.ThingInteraction.DamageMobj($thing, $this.currentThing, $this.currentThing, $damage)

            $this.currentThing.Flags = $this.currentThing.Flags -band -bnot [MobjFlags]::SkullFly
            $this.currentThing.MomX = [Fixed]::Zero
            $this.currentThing.MomY = [Fixed]::Zero
            $this.currentThing.MomZ = [Fixed]::Zero

            $this.currentThing.SetState($this.currentThing.Info.SpawnState)

            # Stop moving.
            return $false
        }

        # Missiles can hit other things.
        if ([int]($this.currentThing.Flags -band [MobjFlags]::Missile) -ne 0) {
            # See if it went over / under.
            if ($this.currentThing.Z.Data -gt ($thing.Z + $thing.Height).Data) {
                # Overhead.
                return $true
            }

            if (($this.currentThing.Z + $this.currentThing.Height).Data -lt $thing.Z.Data) {
                # Underneath.
                return $true
            }

            if ($null -ne $this.currentThing.Target -and
                ($this.currentThing.Target.Type -eq $thing.Type -or
                ($this.currentThing.Target.Type -eq [MobjType]::Knight -and $thing.Type -eq [MobjType]::Bruiser) -or
                ($this.currentThing.Target.Type -eq [MobjType]::Bruiser -and $thing.Type -eq [MobjType]::Knight))) {
                
                # Don't hit same species as originator.
                if ($thing -eq $this.currentThing.Target) {
                    return $true
                }

                if ($thing.Type -ne [MobjType]::Player -and -not [DoomInfo]::DeHackEdConst.MonstersInfight) {
                    # Explode, but do no damage.
                    # Let players missile other players.
                    return $false
                }
            }

            if ([int]($thing.Flags -band [MobjFlags]::Shootable) -eq 0) {
                # Didn't do any damage.
                return ([int]($thing.Flags -band [MobjFlags]::Solid) -eq 0)
            }

            # Damage / explode.
            $damage = ((($this.world.Random.Next() % 8) + 1) * $this.currentThing.Info.Damage)
            $this.world.ThingInteraction.DamageMobj($thing, $this.currentThing, $this.currentThing.Target, $damage)

            # Don't traverse any more.
            return $false
        }

        # Check for special pickup.
        if ([int]($thing.Flags -band [MobjFlags]::Special) -ne 0) {
            $solid = ([int]($thing.Flags -band [MobjFlags]::Solid) -ne 0)
            if ([int]($this.currentFlags -band [MobjFlags]::PickUp) -ne 0) {
                # Can remove thing.
                $this.world.ItemPickup.TouchSpecialThing($thing, $this.currentThing)
            }
            return (-not $solid)
        }

        return ([int]($thing.Flags -band [MobjFlags]::Solid) -eq 0)
    }

    [bool] CheckPosition([Mobj] $thing, [Fixed] $x, [Fixed] $y) {
        $map = $this.world.Map
        $bm = $map.BlockMap

        $this.currentThing = $thing
        $this.currentFlags = $thing.Flags

        $this.currentX = $x
        $this.currentY = $y

        $this.currentBox[[Box]::Top] = $y + $this.currentThing.Radius
        $this.currentBox[[Box]::Bottom] = $y - $this.currentThing.Radius
        $this.currentBox[[Box]::Right] = $x + $this.currentThing.Radius
        $this.currentBox[[Box]::Left] = $x - $this.currentThing.Radius

        $newSubsector = [Geometry]::PointInSubsector($x, $y, $map)

        $this.currentCeilingLine = $null

        # The base floor / ceiling is from the subsector that contains the point.
        # Any contacted lines that step closer together will adjust them.
        $this.currentFloorZ = $this.currentDropoffZ = $newSubsector.Sector.FloorHeight
        $this.currentCeilingZ = $newSubsector.Sector.CeilingHeight

        $validCount = $this.world.GetNewValidCount()

        $this.crossedSpecialCount = 0

        if ([int]($this.currentFlags -band [MobjFlags]::NoClip) -ne 0) {
            return $true
        }

                # Check things first, possibly picking things up.
        # The bounding box is extended by MaxThingRadius because mobj_ts are grouped into
        # mapblocks based on their origin point, and can overlap into adjacent blocks by up
        # to MaxThingRadius units.
        $blockX1 = $bm.GetBlockX($this.currentBox[[Box]::Left] - [GameConst]::MaxThingRadius)
        $blockX2 = $bm.GetBlockX($this.currentBox[[Box]::Right] + [GameConst]::MaxThingRadius)
        $blockY1 = $bm.GetBlockY($this.currentBox[[Box]::Bottom] - [GameConst]::MaxThingRadius)
        $blockY2 = $bm.GetBlockY($this.currentBox[[Box]::Top] + [GameConst]::MaxThingRadius)
        for ($bx = $blockX1; $bx -le $blockX2; $bx++) {
            for ($by = $blockY1; $by -le $blockY2; $by++) {
                if (-not $map.BlockMap.IterateThings($bx, $by, $this.checkThingFunc)) {
                    return $false
                }
            }
        }

        # Check lines.
        $blockX1 = $bm.GetBlockX($this.currentBox[[Box]::Left])
        $blockX2 = $bm.GetBlockX($this.currentBox[[Box]::Right])
        $blockY1 = $bm.GetBlockY($this.currentBox[[Box]::Bottom])
        $blockY2 = $bm.GetBlockY($this.currentBox[[Box]::Top])
        for ($bx = $blockX1; $bx -le $blockX2; $bx++) {
            for ($by = $blockY1; $by -le $blockY2; $by++) {
                if (-not $map.BlockMap.IterateLines($bx, $by, $this.checkLineFunc, $validCount)) {
                    return $false
                }
            }
        }

        return $true
    }

    # Attempt to move to a new position, crossing special lines unless
    # MobjFlags.Teleport is set.
    [bool] TryMove([Mobj] $thing, [Fixed] $x, [Fixed] $y) {
        $this.floatOk = $false

        if (-not $this.CheckPosition($thing, $x, $y)) {
            # Solid wall or thing.
            return $false
        }

        if (($thing.Flags -band [MobjFlags]::NoClip) -eq 0) {
            if (($this.currentCeilingZ - $this.currentFloorZ).Data -lt $thing.Height.Data) {
                # Doesn't fit.
                return $false
            }

            $this.floatOk = $true

            if (($thing.Flags -band [MobjFlags]::Teleport) -eq 0 -and
                ($this.currentCeilingZ - $thing.Z).Data -lt $thing.Height.Data) {
                # Mobj must lower itself to fit.
                return $false
            }

            if (($thing.Flags -band [MobjFlags]::Teleport) -eq 0 -and
                ($this.currentFloorZ - $thing.Z).Data -gt [Fixed]::FromInt(24).Data) {
                # Too big a step up.
                return $false
            }

            if (($thing.Flags -band ([MobjFlags]::DropOff -bor [MobjFlags]::Float)) -eq 0 -and
                ($this.currentFloorZ - $this.currentDropoffZ).Data -gt [Fixed]::FromInt(24).Data) {
                # Don't stand over a dropoff.
                return $false
            }
        }

        # The move is ok,
        # so link the thing into its new position.
        $this.UnsetThingPosition($thing)

        $oldx = $thing.X
        $oldy = $thing.Y
        $thing.FloorZ = $this.currentFloorZ
        $thing.CeilingZ = $this.currentCeilingZ
        $thing.X = $x
        $thing.Y = $y

        $this.SetThingPosition($thing)

        # If any special lines were hit, do the effect.
        if (($thing.Flags -band ([MobjFlags]::Teleport -bor [MobjFlags]::NoClip)) -eq 0) {
            while ($this.crossedSpecialCount-- -gt 0) {
                # See if the line was crossed.
                $line = $this.crossedSpecials[$this.crossedSpecialCount]
                $newSide = [Geometry]::PointOnLineSide($thing.X, $thing.Y, $line)
                $oldSide = [Geometry]::PointOnLineSide($oldx, $oldy, $line)
                if ($newSide -ne $oldSide) {
                    if ($line.Special -ne 0) {
                        $this.world.MapInteraction.CrossSpecialLine($line, $oldSide, $thing)
                    }
                }
            }
        }
        return $true
    }

    static [Fixed] $stopSpeed = [Fixed]::new(0x1000)
    static [Fixed] $friction = [Fixed]::new(0xe800)
    [void] XYMovement([Mobj] $thing) {
        if ($thing.MomX.Data -eq [Fixed]::Zero.Data -and $thing.MomY.Data -eq [Fixed]::Zero.Data) {
            if (($thing.Flags -band [MobjFlags]::SkullFly) -ne 0) {
                # The skull slammed into something.
                $thing.Flags = $thing.Flags -band -bnot [MobjFlags]::SkullFly
                $thing.MomX = [Fixed]::Zero
                $thing.MomY = [Fixed]::Zero
                $thing.MomZ = [Fixed]::Zero

                $thing.SetState($thing.Info.SpawnState)
            }
            return
        }

        $player = $thing.Player
        $maxMoveData = [ThingMovement]::maxMove.Data
        $halfMaxMoveData = ([ThingMovement]::maxMove / 2).Data

        if ($thing.MomX.Data -gt $maxMoveData) {
            $thing.MomX = [ThingMovement]::maxMove
        } elseif ($thing.MomX.Data -lt (-$maxMoveData)) {
            $thing.MomX = -[ThingMovement]::maxMove
        }

        if ($thing.MomY.Data -gt $maxMoveData) {
            $thing.MomY = [ThingMovement]::maxMove
        } elseif ($thing.MomY.Data -lt (-$maxMoveData)) {
            $thing.MomY = -[ThingMovement]::maxMove
        }

        $moveX = $thing.MomX
        $moveY = $thing.MomY
        $pMoveX = [Fixed]::Zero
        $pMoveY = [Fixed]::Zero

        do {
            if ($moveX.Data -gt $halfMaxMoveData -or $moveY.Data -gt $halfMaxMoveData) {
                $pMoveX = $thing.X + ($moveX / 2)
                $pMoveY = $thing.Y + ($moveY / 2)
                $moveX = $moveX -shr 1
                $moveY = $moveY -shr 1
            } else {
                $pMoveX = $thing.X + $moveX
                $pMoveY = $thing.Y + $moveY
                $moveX = [Fixed]::Zero
                $moveY = [Fixed]::Zero
            }

            if (-not $this.TryMove($thing, $pMoveX, $pMoveY)) {
                # Blocked move.
                if ($null -ne $thing.Player) {
                    # Try to slide along it.
                    $this.SlideMove($thing)
                } elseif (($thing.Flags -band [MobjFlags]::Missile) -ne 0) {
                    # Explode a missile.
                    if ($null -ne $this.currentCeilingLine -and
                        $null -ne $this.currentCeilingLine.BackSector -and
                        $this.currentCeilingLine.BackSector.CeilingFlat -eq $this.world.Map.SkyFlatNumber) {
                        # Hack to prevent missiles exploding against the sky.
                        # Does not handle sky floors.
                        $this.world.ThingAllocation.RemoveMobj($thing)
                        return
                    }
                    $this.world.ThingInteraction.ExplodeMissile($thing)
                } else {
                    $thing.MomX = [Fixed]::Zero
                    $thing.MomY = [Fixed]::Zero
                }
            }
        } while ($moveX.Data -ne [Fixed]::Zero.Data -or $moveY.Data -ne [Fixed]::Zero.Data)

        # Slow down.
        if ($null -ne $player -and ($player.Cheats -band [CheatFlags]::NoMomentum) -ne 0) {
            # Debug option for no sliding at all.
            $thing.MomX = [Fixed]::Zero
            $thing.MomY = [Fixed]::Zero
            return
        }

        if (($thing.Flags -band ([MobjFlags]::Missile -bor [MobjFlags]::SkullFly)) -ne 0) {
            # No friction for missiles ever.
            return
        }

        if ($thing.Z.Data -gt $thing.FloorZ.Data) {
            # No friction when airborne.
            return
        }

        if (($thing.Flags -band [MobjFlags]::Corpse) -ne 0) {
            # Do not stop sliding if halfway off a step with some momentum.
            $quarterData = ([Fixed]::One / 4).Data
            if ($thing.MomX.Data -gt $quarterData -or
                $thing.MomX.Data -lt (-$quarterData) -or
                $thing.MomY.Data -gt $quarterData -or
                $thing.MomY.Data -lt (-$quarterData)) {
                if ($thing.FloorZ.Data -ne $thing.Subsector.Sector.FloorHeight.Data) {
                    return
                }
            }
        }

        $stopSpeedData = [ThingMovement]::stopSpeed.Data
        if ($thing.MomX.Data -gt (-$stopSpeedData) -and
            $thing.MomX.Data -lt $stopSpeedData -and
            $thing.MomY.Data -gt (-$stopSpeedData) -and
            $thing.MomY.Data -lt $stopSpeedData -and
            ($null -eq $player -or ($player.Cmd.ForwardMove -eq 0 -and $player.Cmd.SideMove -eq 0))) {
            # If in a walking frame, stop moving.
            if ($null -ne $player -and (($player.Mobj.State.Number - [int][MobjState]::PlayRun1) -lt 4)) {
                $player.Mobj.SetState([MobjState]::Play)
            }

            $thing.MomX = [Fixed]::Zero
            $thing.MomY = [Fixed]::Zero
        } else {
            $thing.MomX = $thing.MomX * [ThingMovement]::friction
            $thing.MomY = $thing.MomY * [ThingMovement]::friction
        }
    }
    [void] ZMovement([Mobj] $thing) {
        # Check for smooth step up.
        if ($null -ne $thing.Player -and $thing.Z.Data -lt $thing.FloorZ.Data) {
            $thing.Player.ViewHeight -= ($thing.FloorZ - $thing.Z)
            $thing.Player.DeltaViewHeight = ([Player]::NormalViewHeight - $thing.Player.ViewHeight) -shr 3
        }

        # Adjust height.
        $thing.Z += $thing.MomZ

        if (($thing.Flags -band [MobjFlags]::Float) -ne 0 -and $null -ne $thing.Target) {
            # Float down towards target if too close.
            if (($thing.Flags -band [MobjFlags]::SkullFly) -eq 0 -and
                ($thing.Flags -band [MobjFlags]::InFloat) -eq 0) {
                
                $dist = [Geometry]::AproxDistance($thing.X - $thing.Target.X, $thing.Y - $thing.Target.Y)
                $delta = ($thing.Target.Z + ($thing.Height -shr 1)) - $thing.Z

                if ($delta.Data -lt [Fixed]::Zero.Data -and $dist.Data -lt (-($delta * 3)).Data) {
                    $thing.Z -= [ThingMovement]::FloatSpeed
                } elseif ($delta.Data -gt [Fixed]::Zero.Data -and $dist.Data -lt ($delta * 3).Data) {
                    $thing.Z += [ThingMovement]::FloatSpeed
                }
            }
        }

        # Clip movement.
        if ($thing.Z.Data -le $thing.FloorZ.Data) {
            # Hit the floor.

            # The lost soul bounce fix below is based on Chocolate Doom's implementation.
            $correctLostSoulBounce = $this.world.Options.GameVersion -ge [GameVersion]::Ultimate

            if ($correctLostSoulBounce -and ($thing.Flags -band [MobjFlags]::SkullFly) -ne 0) {
                # The skull slammed into something.
                $thing.MomZ = -$thing.MomZ
            }

            if ($thing.MomZ.Data -lt [Fixed]::Zero.Data) {
                if ($null -ne $thing.Player -and $thing.MomZ.Data -lt (-([ThingMovement]::gravity * 8)).Data) {
                    # Squat down.
                    # Decrease viewheight for a moment after hitting the ground (hard),
                    # and utter appropriate sound.
                    $thing.Player.DeltaViewHeight = ($thing.MomZ -shr 3)
                    $this.world.StartSound($thing, [Sfx]::OOF, [SfxType]::Voice)
                }
                $thing.MomZ = [Fixed]::Zero
            }

            $thing.Z = $thing.FloorZ

            if (-not $correctLostSoulBounce -and ($thing.Flags -band [MobjFlags]::SkullFly) -ne 0) {
                $thing.MomZ = -$thing.MomZ
            }

            if (($thing.Flags -band [MobjFlags]::Missile) -ne 0 -and
                ($thing.Flags -band [MobjFlags]::NoClip) -eq 0) {
                $this.world.ThingInteraction.ExplodeMissile($thing)
                return
            }
        } elseif (($thing.Flags -band [MobjFlags]::NoGravity) -eq 0) {
            if ($thing.MomZ.Data -eq [Fixed]::Zero.Data) {
                $thing.MomZ = -([ThingMovement]::gravity * 2)
            } else {
                $thing.MomZ -= [ThingMovement]::gravity
            }
        }

        if (($thing.Z + $thing.Height).Data -gt $thing.CeilingZ.Data) {
            # Hit the ceiling.
            if ($thing.MomZ.Data -gt [Fixed]::Zero.Data) {
                $thing.MomZ = [Fixed]::Zero
            }

            $thing.Z = $thing.CeilingZ - $thing.Height

            if (($thing.Flags -band [MobjFlags]::SkullFly) -ne 0) {
                # The skull slammed into something.
                $thing.MomZ = -$thing.MomZ
            }

            if (($thing.Flags -band [MobjFlags]::Missile) -ne 0 -and
                ($thing.Flags -band [MobjFlags]::NoClip) -eq 0) {
                $this.world.ThingInteraction.ExplodeMissile($thing)
                return
            }
        }
    }

    [Fixed] get_CurrentFloorZ() { return $this.currentFloorZ }
    [Fixed] get_CurrentCeilingZ() { return $this.currentCeilingZ }
    [Fixed] get_CurrentDropoffZ() { return $this.currentDropoffZ }
    [bool] get_FloatOk() { return $this.floatOk }
    ############################################################
    # Player's slide movement
    ############################################################

    [Fixed] $bestSlideFrac
    [Fixed] $secondSlideFrac

    [LineDef] $bestSlideLine
    [LineDef] $secondSlideLine

    [Mobj] $slideThing
    [Fixed] $slideMoveX
    [Fixed] $slideMoveY

    [scriptblock] $slideTraverseFunc

    [void] InitSlideMovement() {
        $owner = $this
        $this.slideTraverseFunc = { param($intercept) $owner.SlideTraverse($intercept) }.GetNewClosure()
    }

    # Adjusts the x and y movement so that the next move will
    # slide along the wall.
    [void] HitSlideLine([LineDef] $line) {
        if ($line.SlopeType -eq [SlopeType]::Horizontal) {
            $this.slideMoveY = [Fixed]::Zero
            return
        }

        if ($line.SlopeType -eq [SlopeType]::Vertical) {
            $this.slideMoveX = [Fixed]::Zero
            return
        }

        $side = [Geometry]::PointOnLineSide($this.slideThing.X, $this.slideThing.Y, $line)

        $lineAngle = [Geometry]::PointToAngle([Fixed]::Zero, [Fixed]::Zero, $line.Dx, $line.Dy)
        if ($side -eq 1) {
            $lineAngle += [Angle]::Ang180
        }

        $moveAngle = [Geometry]::PointToAngle([Fixed]::Zero, [Fixed]::Zero, $this.slideMoveX, $this.slideMoveY)

        $deltaAngle = $moveAngle - $lineAngle
        if ($deltaAngle.Data -gt [Angle]::Ang180.Data) {
            $deltaAngle += [Angle]::Ang180
        }

        $moveDist = [Geometry]::AproxDistance($this.slideMoveX, $this.slideMoveY)
        $newDist = $moveDist * [Trig]::Cos($deltaAngle)

        $this.slideMoveX = $newDist * [Trig]::Cos($lineAngle)
        $this.slideMoveY = $newDist * [Trig]::Sin($lineAngle)
    }
    [bool] SlideTraverse([Intercept] $intercept) {
        $mc = $this.world.MapCollision

        if ($null -eq $intercept.Line) {
            throw "ThingMovement.SlideTraverse: Not a line?"
        }

        $line = $intercept.Line
        $isBlocking = $false

        if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) {
            if ([Geometry]::PointOnLineSide($this.slideThing.X, $this.slideThing.Y, $line) -ne 0) {
                # Don't hit the back side.
                return $true
            }
            $isBlocking = $true
        }
        else {
            # Set openrange, opentop, openbottom.
            $mc.LineOpening($line)

            if ($mc.OpenRange.Data -lt $this.slideThing.Height.Data) {
                # Doesn't fit.
                $isBlocking = $true
            }
            elseif (($mc.OpenTop - $this.slideThing.Z).Data -lt $this.slideThing.Height.Data) {
                # Mobj is too high.
                $isBlocking = $true
            }
            elseif (($mc.OpenBottom - $this.slideThing.Z).Data -gt [Fixed]::FromInt(24).Data) {
                # Too big a step up.
                $isBlocking = $true
            }
        }

        if (-not $isBlocking) {
            # This line doesn't block movement.
            return $true
        }

        # The line does block movement, see if it is closer than best so far.
        if ($intercept.Frac.Data -lt $this.bestSlideFrac.Data) {
            $this.secondSlideFrac = $this.bestSlideFrac
            $this.secondSlideLine = $this.bestSlideLine
            $this.bestSlideFrac = $intercept.Frac
            $this.bestSlideLine = $line
        }

        # Stop.
        return $false
    }

    # The MomX / MomY move is bad, so try to slide along a wall.
    # Find the first line hit, move flush to it, and slide along it.
    # This is a kludgy mess.
    [void] SlideMove([Mobj] $thing) {
        $pt = $this.world.PathTraversal

        $this.slideThing = $thing

        $hitCount = 0
        while ($true) {
            # Don't loop forever.
            $hitCount++
            if ($hitCount -eq 3) {
                # The move must have hit the middle, so stairstep.
                $this.StairStep($thing)
                return
            }

            # Trace along the three leading corners.
            if ($thing.MomX.Data -gt [Fixed]::Zero.Data) {
                $leadX = $thing.X + $thing.Radius
                $trailX = $thing.X - $thing.Radius
            } else {
                $leadX = $thing.X - $thing.Radius
                $trailX = $thing.X + $thing.Radius
            }

            if ($thing.MomY.Data -gt [Fixed]::Zero.Data) {
                $leadY = $thing.Y + $thing.Radius
                $trailY = $thing.Y - $thing.Radius
            } else {
                $leadY = $thing.Y - $thing.Radius
                $trailY = $thing.Y + $thing.Radius
            }

            $this.bestSlideFrac = [Fixed]::OnePlusEpsilon

            $pt.PathTraverse(
                $leadX, $leadY, $leadX + $thing.MomX, $leadY + $thing.MomY,
                [PathTraverseFlags]::AddLines, $this.slideTraverseFunc
            )

            $pt.PathTraverse(
                $trailX, $leadY, $trailX + $thing.MomX, $leadY + $thing.MomY,
                [PathTraverseFlags]::AddLines, $this.slideTraverseFunc
            )

            $pt.PathTraverse(
                $leadX, $trailY, $leadX + $thing.MomX, $trailY + $thing.MomY,
                [PathTraverseFlags]::AddLines, $this.slideTraverseFunc
            )

            # Move up to the wall.
            if ($this.bestSlideFrac.Data -eq [Fixed]::OnePlusEpsilon.Data) {
                # The move must have hit the middle, so stairstep.
                $this.StairStep($thing)
                return
            }

            # Fudge a bit to make sure it doesn't hit.
            $this.bestSlideFrac = [Fixed]::new($this.bestSlideFrac.Data - 0x800)
            if ($this.bestSlideFrac.Data -gt [Fixed]::Zero.Data) {
                $newX = $thing.MomX * $this.bestSlideFrac
                $newY = $thing.MomY * $this.bestSlideFrac

                if (-not $this.TryMove($thing, $thing.X + $newX, $thing.Y + $newY)) {
                    # The move must have hit the middle, so stairstep.
                    $this.StairStep($thing)
                    return
                }
            }

            # Now continue along the wall.
            # First calculate remainder.
            $this.bestSlideFrac = [Fixed]::new([Fixed]::FracUnit - ($this.bestSlideFrac.Data + 0x800))

            if ($this.bestSlideFrac.Data -gt [Fixed]::One.Data) {
                $this.bestSlideFrac = [Fixed]::One
            }

            if ($this.bestSlideFrac.Data -le [Fixed]::Zero.Data) {
                return
            }

            $this.slideMoveX = $thing.MomX * $this.bestSlideFrac
            $this.slideMoveY = $thing.MomY * $this.bestSlideFrac

            # Clip the moves.
            $this.HitSlideLine($this.bestSlideLine)

            $thing.MomX = $this.slideMoveX
            $thing.MomY = $this.slideMoveY

            if ($this.TryMove($thing, $thing.X + $this.slideMoveX, $thing.Y + $this.slideMoveY)) {
                return
            }
        }
    }
    [void] StairStep([Mobj] $thing) {
        if (-not $this.TryMove($thing, $thing.X, $thing.Y + $thing.MomY)) {
            $this.TryMove($thing, $thing.X + $thing.MomX, $thing.Y)
        }
    }

    ############################################################
    # Teleport movement
    ############################################################

    [scriptblock] $stompThingFunc

    [void] InitTeleportMovement() {
        $owner = $this
        $this.stompThingFunc = { param($thing) $owner.StompThing($thing) }.GetNewClosure()
    }

    [bool] StompThing([Mobj] $thing) {
        if (($thing.Flags -band [MobjFlags]::Shootable) -eq 0) {
            return $true
        }

        $blockDist = $thing.Radius + $this.currentThing.Radius
        $dx = [Fixed]::Abs($thing.X - $this.currentX)
        $dy = [Fixed]::Abs($thing.Y - $this.currentY)

        if ($dx -ge $blockDist -or $dy -ge $blockDist) {
            # Didn't hit it.
            return $true
        }

        # Don't clip against self.
        if ($thing -eq $this.currentThing) {
            return $true
        }

        # Monsters don't stomp things except on boss level.
        if ($null -eq $this.currentThing.Player -and $this.world.Options.Map -ne 30) {
            return $false
        }

        $this.world.ThingInteraction.DamageMobj($thing, $this.currentThing, $this.currentThing, 10000)

        return $true
    }

    [bool] TeleportMove([Mobj] $thing, [Fixed] $x, [Fixed] $y) {
        # Kill anything occupying the position.
        $this.currentThing = $thing
        $this.currentFlags = $thing.Flags

        $this.currentX = $x
        $this.currentY = $y

        $this.currentBox[[Box]::Top] = $y + $this.currentThing.Radius
        $this.currentBox[[Box]::Bottom] = $y - $this.currentThing.Radius
        $this.currentBox[[Box]::Right] = $x + $this.currentThing.Radius
        $this.currentBox[[Box]::Left] = $x - $this.currentThing.Radius

        $ss = [Geometry]::PointInSubsector($x, $y, $this.world.Map)

        $this.currentCeilingLine = $null

        # The base floor / ceiling is from the subsector that contains the point.
        # Any contacted lines that step closer together will adjust them.
        $this.currentFloorZ = $this.currentDropoffZ = $ss.Sector.FloorHeight
        $this.currentCeilingZ = $ss.Sector.CeilingHeight

        $validcount = $this.world.GetNewValidCount()

        $this.crossedSpecialCount = 0

        # Stomp on any things contacted.
        $bm = $this.world.Map.BlockMap
        $blockX1 = $bm.GetBlockX($this.currentBox[[Box]::Left] - [GameConst]::MaxThingRadius)
        $blockX2 = $bm.GetBlockX($this.currentBox[[Box]::Right] + [GameConst]::MaxThingRadius)
        $blockY1 = $bm.GetBlockY($this.currentBox[[Box]::Bottom] - [GameConst]::MaxThingRadius)
        $blockY2 = $bm.GetBlockY($this.currentBox[[Box]::Top] + [GameConst]::MaxThingRadius)

        for ($bx = $blockX1; $bx -le $blockX2; $bx++) {
            for ($by = $blockY1; $by -le $blockY2; $by++) {
                if (-not $bm.IterateThings($bx, $by, $this.stompThingFunc)) {
                    return $false
                }
            }
        }

        # The move is ok, so link the thing into its new position.
        $this.UnsetThingPosition($thing)

        $thing.FloorZ = $this.currentFloorZ
        $thing.CeilingZ = $this.currentCeilingZ
        $thing.X = $x
        $thing.Y = $y

        $this.SetThingPosition($thing)

        return $true
    }
}





