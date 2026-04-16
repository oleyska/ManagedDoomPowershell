class MonsterBehavior {
    [World] $world

    MonsterBehavior([World] $world) {
        $this.world = $world

        $this.InitVile()
        $this.InitBossDeath()
        $this.InitBrain()
    }
    # Sleeping monster
    [bool] LookForPlayers([Mobj] $actor, [bool] $allAround) {
        try {
            $players = $this.world.Options.Players
            
            $count = 0
            $stop = ($actor.LastLook - 1) -band 3
            
            while ($true) {
                if (-not $players[$actor.LastLook].InGame) {
                    $actor.LastLook = ($actor.LastLook + 1) -band 3
                    continue
                }

                if ($count++ -eq 2 -or $actor.LastLook -eq $stop) {
                    return $false
                }

                $player = $players[$actor.LastLook]
                
                if ($player.Health -le 0) {
                    $actor.LastLook = ($actor.LastLook + 1) -band 3
                    continue
                }

                if (-not $this.world.VisibilityCheck.CheckSight($actor, $player.Mobj)) {
                    $actor.LastLook = ($actor.LastLook + 1) -band 3
                    continue
                }

                if (-not $allAround) {
                    $angle = [Geometry]::PointToAngle($actor.X, $actor.Y, $player.Mobj.X, $player.Mobj.Y) - $actor.Angle
                    
                    if ($angle.Data -gt [Angle]::Ang90.Data -and $angle.Data -lt [Angle]::Ang270.Data) {
                        $dist = [Geometry]::AproxDistance($player.Mobj.X - $actor.X, $player.Mobj.Y - $actor.Y)
                        
                        if ($dist.Data -gt [WeaponBehavior]::MeleeRange.Data) {
                            $actor.LastLook = ($actor.LastLook + 1) -band 3
                            continue
                        }
                    }
                }
                
                $actor.Target = $player.Mobj
                return $true
            }
            return $false
        } catch {
            [Console]::WriteLine(("LookForPlayers exception: " + $_.Exception))
            if ($null -ne $_.InvocationInfo) { [Console]::WriteLine(("LookForPlayers position: " + $_.InvocationInfo.PositionMessage.Trim())) }
            throw
        }
    }

    Look([Mobj] $actor) {
        try {
            $actor.Threshold = 0
            
            $target = $actor.Subsector.Sector.SoundTarget
            
            [bool]$seeYou = $false

            if ($null -ne $target -and [int]($target.Flags -band [MobjFlags]::Shootable) -ne 0) {
                $actor.Target = $target
                
                if ([int]($actor.Flags -band [MobjFlags]::Ambush) -ne 0) {
                    if ($this.world.VisibilityCheck.CheckSight($actor, $actor.Target)) {
                        $seeYou = $true
                    }
                } else {
                    $seeYou = $true
                }
            }

            if (-not $seeYou -and -not $this.LookForPlayers($actor, $false)) {
                return
            }
            if ([int]$actor.Info.SeeSound -ne 0) {
                [int] $sound = 0
                
                switch ($actor.Info.SeeSound) {
                    ([Sfx]::POSIT1) { $sound = [int][Sfx]::POSIT1 + ($this.world.Random.Next() % 3) }
                    ([Sfx]::POSIT2) { $sound = [int][Sfx]::POSIT1 + ($this.world.Random.Next() % 3) }
                    ([Sfx]::POSIT3) { $sound = [int][Sfx]::POSIT1 + ($this.world.Random.Next() % 3) }
                    ([Sfx]::BGSIT1) { $sound = [int][Sfx]::BGSIT1 + ($this.world.Random.Next() % 2) }
                    ([Sfx]::BGSIT2) { $sound = [int][Sfx]::BGSIT1 + ($this.world.Random.Next() % 2) }
                    default { $sound = [int]$actor.Info.SeeSound }
                }
                
                if ([int]$actor.Type -eq [int][MobjType]::Spider -or [int]$actor.Type -eq [int][MobjType]::Cyborg) {
                    $this.world.StartSound($actor, [Sfx]$sound, [SfxType]::Diffuse)
                } else {
                    $this.world.StartSound($actor, [Sfx]$sound, [SfxType]::Voice)
                }
            }
            
            $actor.SetState($actor.Info.SeeState)
        } catch {
            [Console]::WriteLine("Look exception: " + $_.Exception)
            if ($null -ne $_.InvocationInfo) { [Console]::WriteLine("Look position: " + $_.InvocationInfo.PositionMessage.Trim()) }
            throw
        }
    }
    # Monster AI

    static [Fixed[]] $xSpeed = @(
        [Fixed]::new([Fixed]::FracUnit),
        [Fixed]::new(47000),
        [Fixed]::new(0),
        [Fixed]::new(-47000),
        [Fixed]::new(-[Fixed]::FracUnit),
        [Fixed]::new(-47000),
        [Fixed]::new(0),
        [Fixed]::new(47000)
    )

    static [Fixed[]] $ySpeed = @(
        [Fixed]::new(0),
        [Fixed]::new(47000),
        [Fixed]::new([Fixed]::FracUnit),
        [Fixed]::new(47000),
        [Fixed]::new(0),
        [Fixed]::new(-47000),
        [Fixed]::new(-[Fixed]::FracUnit),
        [Fixed]::new(-47000)
    )

    [bool] Move([Mobj] $actor) {
        if ($actor.MoveDir -eq [Direction]::None) {
            return $false
        }

        if ([int]$actor.MoveDir -ge 8) {
            throw "Weird actor->movedir!"
        }

        $tryX = $actor.X + ($actor.Info.Speed * [MonsterBehavior]::xSpeed[[int]$actor.MoveDir])
        $tryY = $actor.Y + ($actor.Info.Speed * [MonsterBehavior]::ySpeed[[int]$actor.MoveDir])

        $tm = $this.world.ThingMovement
        $tryOk = $tm.TryMove($actor, $tryX, $tryY)

        if (-not $tryOk) {
            if ([int]($actor.Flags -band [MobjFlags]::Float) -ne 0 -and $tm.FloatOk) {
                if ($actor.Z.Data -lt $tm.CurrentFloorZ.Data) {
                    $actor.Z += [ThingMovement]::FloatSpeed
                } else {
                    $actor.Z -= [ThingMovement]::FloatSpeed
                }

                $actor.Flags = $actor.Flags -bor [MobjFlags]::InFloat
                return $true
            }

            if ($tm.crossedSpecialCount -eq 0) {
                return $false
            }

            $actor.MoveDir = [Direction]::None
            $good = $false

            while ($tm.crossedSpecialCount-- -gt 0) {
                $line = $tm.crossedSpecials[$tm.crossedSpecialCount]
                if ($this.world.MapInteraction.UseSpecialLine($actor, $line, 0)) {
                    $good = $true
                }
            }
            return $good
        } else {
            $actor.Flags = $actor.Flags -band (-bnot [MobjFlags]::InFloat)
        }

        if ([int]($actor.Flags -band [MobjFlags]::Float) -eq 0) {
            $actor.Z = $actor.FloorZ
        }

        return $true
    }

    [bool] TryWalk([Mobj] $actor) {
        if (-not $this.Move($actor)) {
            return $false
        }

        $actor.MoveCount = $this.world.Random.Next() -band 15
        return $true
    }

    [bool] CheckMeleeRange([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return $false
        }

        $target = $actor.Target
        $dist = [Geometry]::AproxDistance($target.X - $actor.X, $target.Y - $actor.Y)
        $limit = [WeaponBehavior]::MeleeRange - [Fixed]::FromInt(20) + $target.Info.Radius

        if ($dist.Data -ge $limit.Data) {
            return $false
        }

        return $this.world.VisibilityCheck.CheckSight($actor, $target)
    }

    [bool] CheckMissileRange([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return $false
        }

        $target = $actor.Target
        if (-not $this.world.VisibilityCheck.CheckSight($actor, $target)) {
            return $false
        }

        if ([int]($actor.Flags -band [MobjFlags]::JustHit) -ne 0) {
            $actor.Flags = $actor.Flags -band (-bnot [MobjFlags]::JustHit)
            return $true
        }

        if ($actor.ReactionTime -gt 0) {
            return $false
        }

        $dist = [Geometry]::AproxDistance($target.X - $actor.X, $target.Y - $actor.Y) - [Fixed]::FromInt(64)
        if ([int]$actor.Info.MeleeState -eq [int][MobjState]::Null) {
            $dist -= [Fixed]::FromInt(128)
        }

        [int]$distInt = $dist.ToIntFloor()

        if ([int]$actor.Type -eq [int][MobjType]::Vile) {
            if ($distInt -gt 14 * 64) {
                return $false
            }
        }

        if ([int]$actor.Type -eq [int][MobjType]::Undead) {
            if ($distInt -lt 196) {
                return $false
            }
            $distInt = $distInt -shr 1
        }

        if ([int]$actor.Type -eq [int][MobjType]::Cyborg -or
            [int]$actor.Type -eq [int][MobjType]::Spider -or
            [int]$actor.Type -eq [int][MobjType]::Skull) {
            $distInt = $distInt -shr 1
        }

        if ($distInt -gt 200) {
            $distInt = 200
        }

        if ([int]$actor.Type -eq [int][MobjType]::Cyborg -and $distInt -gt 160) {
            $distInt = 160
        }

        if ($distInt -lt 0) {
            $distInt = 0
        }

        return $this.world.Random.Next() -ge $distInt
    }

    [void] NewChaseDir([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            $actor.MoveDir = [Direction]::None
            return
        }

        $opposite = @(
            [Direction]::west,
            [Direction]::Southwest,
            [Direction]::South,
            [Direction]::Southeast,
            [Direction]::East,
            [Direction]::Northeast,
            [Direction]::North,
            [Direction]::Northwest
        )
        $diags = @(
            [Direction]::Northwest,
            [Direction]::Northeast,
            [Direction]::Southwest,
            [Direction]::Southeast
        )
        $allDirs = @(
            [Direction]::East,
            [Direction]::Northeast,
            [Direction]::North,
            [Direction]::Northwest,
            [Direction]::west,
            [Direction]::Southwest,
            [Direction]::South,
            [Direction]::Southeast
        )

        $deltaX = $actor.Target.X - $actor.X
        $deltaY = $actor.Target.Y - $actor.Y
        $oldDir = $actor.MoveDir
        $turnaround = [Direction]::None
        if ([int]$oldDir -lt [int][Direction]::None) {
            $turnaround = $opposite[[int]$oldDir]
        }

        $threshold = [Fixed]::FromInt(10).Data

        $d1 = [Direction]::None
        if ($deltaX.Data -gt $threshold) {
            $d1 = [Direction]::East
        } elseif ($deltaX.Data -lt -$threshold) {
            $d1 = [Direction]::west
        }

        $d2 = [Direction]::None
        if ($deltaY.Data -gt $threshold) {
            $d2 = [Direction]::North
        } elseif ($deltaY.Data -lt -$threshold) {
            $d2 = [Direction]::South
        }

        if ($d1 -ne [Direction]::None -and $d2 -ne [Direction]::None) {
            $diagIndex = 0
            if ($deltaY.Data -lt 0) {
                $diagIndex += 2
            }
            if ($deltaX.Data -gt 0) {
                $diagIndex += 1
            }

            $actor.MoveDir = $diags[$diagIndex]
            if ($actor.MoveDir -ne $turnaround -and $this.TryWalk($actor)) {
                return
            }
        }

        if ($this.world.Random.Next() -gt 200 -or [math]::Abs($deltaY.Data) -gt [math]::Abs($deltaX.Data)) {
            $temp = $d1
            $d1 = $d2
            $d2 = $temp
        }

        if ($d1 -eq $turnaround) {
            $d1 = [Direction]::None
        }
        if ($d2 -eq $turnaround) {
            $d2 = [Direction]::None
        }

        if ($d1 -ne [Direction]::None) {
            $actor.MoveDir = $d1
            if ($this.TryWalk($actor)) {
                return
            }
        }

        if ($d2 -ne [Direction]::None) {
            $actor.MoveDir = $d2
            if ($this.TryWalk($actor)) {
                return
            }
        }

        if ($oldDir -ne [Direction]::None) {
            $actor.MoveDir = $oldDir
            if ($this.TryWalk($actor)) {
                return
            }
        }

        if (($this.world.Random.Next() -band 1) -ne 0) {
            $candidateDirectionsEnumerable = $allDirs
            if ($null -ne $candidateDirectionsEnumerable) {
                $candidateDirectionsEnumerator = $candidateDirectionsEnumerable.GetEnumerator()
                for (; $candidateDirectionsEnumerator.MoveNext(); ) {
                    $dir = $candidateDirectionsEnumerator.Current
                    if ($dir -eq $turnaround) {
                        continue
                    }

                    $actor.MoveDir = $dir
                    if ($this.TryWalk($actor)) {
                        return
                    }

                }
            }
        } else {
            for ($i = $allDirs.Length - 1; $i -ge 0; $i--) {
                $dir = $allDirs[$i]
                if ($dir -eq $turnaround) {
                    continue
                }

                $actor.MoveDir = $dir
                if ($this.TryWalk($actor)) {
                    return
                }
            }
        }

        if ($turnaround -ne [Direction]::None) {
            $actor.MoveDir = $turnaround
            if ($this.TryWalk($actor)) {
                return
            }
        }

        $actor.MoveDir = [Direction]::None
    }

    Chase([Mobj] $actor) {
        try {
            if ($actor.ReactionTime -gt 0) {
                $actor.ReactionTime--
            }

            if ($actor.Threshold -gt 0) {
                if ($null -eq $actor.Target -or $actor.Target.Health -le 0) {
                    $actor.Threshold = 0
                } else {
                    $actor.Threshold--
                }
            }

            if ([int]$actor.MoveDir -lt [int][Direction]::None) {
                $angleBits = ([BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$actor.Angle.Data), 0)) -band (7 -shl 29)
                $actor.Angle = [Angle]::new($angleBits)

                $deltaBits = [uint32]($actor.Angle - [Angle]::new(([int]$actor.MoveDir) -shl 29)).Data
                $delta = [BitConverter]::ToInt32([BitConverter]::GetBytes($deltaBits), 0)

                if ($delta -gt 0) {
                    $actor.Angle -= [Angle]::new([int]([Angle]::Ang90.Data / 2))
                } elseif ($delta -lt 0) {
                    $actor.Angle += [Angle]::new([int]([Angle]::Ang90.Data / 2))
                }
            }

            if ($null -eq $actor.Target -or [int]($actor.Target.Flags -band [MobjFlags]::Shootable) -eq 0) {
                if ($this.LookForPlayers($actor, $true)) {
                    return
                }

                $null = $actor.SetState($actor.Info.SpawnState)
                return
            }

            if ([int]($actor.Flags -band [MobjFlags]::JustAttacked) -ne 0) {
                $actor.Flags = $actor.Flags -band (-bnot [MobjFlags]::JustAttacked)

                if (-not ($this.world.Options.FastMonsters -or $this.world.Options.Skill -eq [GameSkill]::Nightmare)) {
                    $this.NewChaseDir($actor)
                    return
                }
            }

            if ([int]$actor.Info.MeleeState -ne [int][MobjState]::Null -and $this.CheckMeleeRange($actor)) {
                if ([int]$actor.Info.AttackSound -ne [int][Sfx]::NONE -and [int]$actor.Info.AttackSound -ne 0) {
                    $this.world.StartSound($actor, $actor.Info.AttackSound, [SfxType]::Weapon)
                }

                $null = $actor.SetState($actor.Info.MeleeState)
                return
            }

            if ([int]$actor.Info.MissileState -ne [int][MobjState]::Null) {
                $canMissile = $true

                if (-not ($this.world.Options.FastMonsters -or $this.world.Options.Skill -eq [GameSkill]::Nightmare) -and $actor.MoveCount -ne 0) {
                    $canMissile = $false
                }

                if ($canMissile -and $this.CheckMissileRange($actor)) {
                    $null = $actor.SetState($actor.Info.MissileState)
                    $actor.Flags = $actor.Flags -bor [MobjFlags]::JustAttacked
                    return
                }
            }

            if ($this.world.Options.NetGame -and $actor.Threshold -eq 0 -and -not $this.world.VisibilityCheck.CheckSight($actor, $actor.Target)) {
                if ($this.LookForPlayers($actor, $true)) {
                    return
                }
            }

            $actor.MoveCount--
            if ($actor.MoveCount -lt 0 -or -not $this.Move($actor)) {
                $this.NewChaseDir($actor)
            }

            if ([int]$actor.Info.ActiveSound -ne [int][Sfx]::NONE -and $this.world.Random.Next() -lt 3) {
                if ([int]$actor.Type -eq [int][MobjType]::Spider -or [int]$actor.Type -eq [int][MobjType]::Cyborg) {
                    $this.world.StartSound($actor, $actor.Info.ActiveSound, [SfxType]::Diffuse)
                } else {
                    $this.world.StartSound($actor, $actor.Info.ActiveSound, [SfxType]::Voice)
                }
            }
        } catch {
            [Console]::WriteLine("Chase exception: {0}" -f $_.Exception)
            if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
                [Console]::WriteLine("Chase position: {0}" -f $_.InvocationInfo.PositionMessage)
            }
            throw
        }
    }
    # Monster death

    Pain([Mobj] $actor) {
        if ($actor.Info.PainSound -ne 0) {
            $this.world.StartSound($actor, $actor.Info.PainSound, [SfxType]::Voice)
        }
    }

    Scream([Mobj] $actor) {
        [int] $sound = 0

        switch ($actor.Info.DeathSound) {
            0 { return }

            ([Sfx]::PODTH1) { $sound = [int][Sfx]::PODTH1 + ($this.world.Random.Next() % 3) }
            ([Sfx]::PODTH2) { $sound = [int][Sfx]::PODTH1 + ($this.world.Random.Next() % 3) }
            ([Sfx]::PODTH3) { $sound = [int][Sfx]::PODTH1 + ($this.world.Random.Next() % 3) }
            ([Sfx]::BGDTH1) { $sound = [int][Sfx]::BGDTH1 + ($this.world.Random.Next() % 2) }
            ([Sfx]::BGDTH2) { $sound = [int][Sfx]::BGDTH1 + ($this.world.Random.Next() % 2) }
            default { $sound = [int]$actor.Info.DeathSound }
        }

        if ($actor.Type -eq [MobjType]::Spider -or $actor.Type -eq [MobjType]::Cyborg) {
            $this.world.StartSound($actor, [Sfx]$sound, [SfxType]::Diffuse)
        } else {
            $this.world.StartSound($actor, [Sfx]$sound, [SfxType]::Voice)
        }
    }

    XScream([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::SLOP, [SfxType]::Voice)
    }

    Fall([Mobj] $actor) {
        $actor.Flags = $actor.Flags -band (-bnot [MobjFlags]::Solid)
    }
    # Monster attack

    FaceTarget([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $actor.Flags = $actor.Flags -band (-bnot [MobjFlags]::Ambush)

        $actor.Angle = [Geometry]::PointToAngle(
            $actor.X, $actor.Y,
            $actor.Target.X, $actor.Target.Y
        )

        $random = $this.world.Random

        if ([int]($actor.Target.Flags -band [MobjFlags]::Shadow) -ne 0) {
            $actor.Angle += [Angle]::new(($random.Next() - $random.Next()) -shl 21)
        }
    }

    PosAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        $angle = $actor.Angle
        $slope = $this.world.Hitscan.AimLineAttack($actor, $angle, [WeaponBehavior]::MissileRange)

        $this.world.StartSound($actor, [Sfx]::PISTOL, [SfxType]::Weapon)

        $random = $this.world.Random
        $angle += [Angle]::new(($random.Next() - $random.Next()) -shl 20)
        $damage = (($random.Next() % 5) + 1) * 3

        $this.world.Hitscan.LineAttack($actor, $angle, [WeaponBehavior]::MissileRange, $slope, $damage)
    }

    SPosAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.world.StartSound($actor, [Sfx]::SHOTGN, [SfxType]::Weapon)

        $this.FaceTarget($actor)

        $center = $actor.Angle
        $slope = $this.world.Hitscan.AimLineAttack($actor, $center, [WeaponBehavior]::MissileRange)

        $random = $this.world.Random

        for ($i = 0; $i -lt 3; $i++) {
            $angle = $center + [Angle]::new(($random.Next() - $random.Next()) -shl 20)
            $damage = (($random.Next() % 5) + 1) * 3

            $this.world.Hitscan.LineAttack($actor, $angle, [WeaponBehavior]::MissileRange, $slope, $damage)
        }
    }

    CPosAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.world.StartSound($actor, [Sfx]::SHOTGN, [SfxType]::Weapon)

        $this.FaceTarget($actor)

        $center = $actor.Angle
        $slope = $this.world.Hitscan.AimLineAttack($actor, $center, [WeaponBehavior]::MissileRange)

        $random = $this.world.Random
        $angle = $center + [Angle]::new(($random.Next() - $random.Next()) -shl 20)
        $damage = (($random.Next() % 5) + 1) * 3

        $this.world.Hitscan.LineAttack($actor, $angle, [WeaponBehavior]::MissileRange, $slope, $damage)
    }
    # Monster attack

    CPosRefire([Mobj] $actor) {
        $this.FaceTarget($actor)

        if ($this.world.Random.Next() -lt 40) {
            return
        }

        if ($null -eq $actor.Target -or $actor.Target.Health -le 0 -or -not $this.world.VisibilityCheck.CheckSight($actor, $actor.Target)) {
            $actor.SetState($actor.Info.SeeState)
        }
    }

    TroopAttack([Mobj] $actor) {
        try {
            if ($null -eq $actor.Target) {
                return
            }

            $this.FaceTarget($actor)

            if ($this.CheckMeleeRange($actor)) {
                $this.world.StartSound($actor, [Sfx]::CLAW, [SfxType]::Weapon)
                $damage = (($this.world.Random.Next() % 8) + 1) * 3
                $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, $damage)
                return
            }

            $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Troopshot)
        } catch {
            [Console]::WriteLine("TroopAttack exception: {0}" -f $_.Exception)
            if ($null -ne $_.InvocationInfo) {
                [Console]::WriteLine("TroopAttack position: {0}" -f $_.InvocationInfo.PositionMessage.Trim())
            }
            throw
        }
    }

    SargAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        if ($this.CheckMeleeRange($actor)) {
            $damage = (($this.world.Random.Next() % 10) + 1) * 4
            $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, $damage)
        }
    }

    HeadAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        if ($this.CheckMeleeRange($actor)) {
            $damage = (($this.world.Random.Next() % 6) + 1) * 10
            $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, $damage)
            return
        }

        $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Headshot)
    }

    BruisAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        if ($this.CheckMeleeRange($actor)) {
            $this.world.StartSound($actor, [Sfx]::CLAW, [SfxType]::Weapon)
            $damage = (($this.world.Random.Next() % 8) + 1) * 10
            $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, $damage)
            return
        }

        $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Bruisershot)
    }

    static [Fixed] $skullSpeed = [Fixed]::FromInt(20)

    SkullAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $dest = $actor.Target
        $actor.Flags = $actor.Flags -bor [MobjFlags]::SkullFly

        $this.world.StartSound($actor, $actor.Info.AttackSound, [SfxType]::Voice)
        $this.FaceTarget($actor)

        $angle = $actor.Angle
        $actor.MomX = [MonsterBehavior]::skullSpeed * [Trig]::Cos($angle)
        $actor.MomY = [MonsterBehavior]::skullSpeed * [Trig]::Sin($angle)

        $dist = [Geometry]::AproxDistance($dest.X - $actor.X, $dest.Y - $actor.Y)
        $num = ($dest.Z + ($dest.Height -shr 1) - $actor.Z).Data
        $den = $dist.Data / [MonsterBehavior]::skullSpeed.Data
        if ($den -lt 1) { $den = 1 }

        $actor.MomZ = [Fixed]::new($num / $den)
    }

    FatRaise([Mobj] $actor) {
        $this.FaceTarget($actor)
        $this.world.StartSound($actor, [Sfx]::MANATK, [SfxType]::Voice)
    }

    static [Angle] $fatSpread = [Angle]::Ang90 / 8

    FatAttack1([Mobj] $actor) {
        $this.FaceTarget($actor)

        $ta = $this.world.ThingAllocation
        $actor.Angle += [MonsterBehavior]::fatSpread
        $target = $this.world.SubstNullMobj($actor.Target)
        $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)

        $missile = $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)
        $missile.Angle += [MonsterBehavior]::fatSpread
        $angle = $missile.Angle
        $missile.MomX = [Fixed]::new($missile.Info.Speed) * [Trig]::Cos($angle)
        $missile.MomY = [Fixed]::new($missile.Info.Speed) * [Trig]::Sin($angle)
    }

    FatAttack2([Mobj] $actor) {
        $this.FaceTarget($actor)

        $ta = $this.world.ThingAllocation
        $actor.Angle -= [MonsterBehavior]::fatSpread
        $target = $this.world.SubstNullMobj($actor.Target)
        $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)

        $missile = $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)
        $missile.Angle -= [MonsterBehavior]::fatSpread * 2
        $angle = $missile.Angle
        $missile.MomX = [Fixed]::new($missile.Info.Speed) * [Trig]::Cos($angle)
        $missile.MomY = [Fixed]::new($missile.Info.Speed) * [Trig]::Sin($angle)
    }
    FatAttack3([Mobj] $actor) {
        $this.FaceTarget($actor)
    
        $ta = $this.world.ThingAllocation
        $target = $this.world.SubstNullMobj($actor.Target)
    
        $missile1 = $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)
        $missile1.Angle -= [MonsterBehavior]::fatSpread / 2
        $angle1 = $missile1.Angle
        $missile1.MomX = [Fixed]::new($missile1.Info.Speed) * [Trig]::Cos($angle1)
        $missile1.MomY = [Fixed]::new($missile1.Info.Speed) * [Trig]::Sin($angle1)
    
        $missile2 = $ta.SpawnMissile($actor, $target, [MobjType]::Fatshot)
        $missile2.Angle += [MonsterBehavior]::fatSpread / 2
        $angle2 = $missile2.Angle
        $missile2.MomX = [Fixed]::new($missile2.Info.Speed) * [Trig]::Cos($angle2)
        $missile2.MomY = [Fixed]::new($missile2.Info.Speed) * [Trig]::Sin($angle2)
    }
    
    BspiAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }
    
        $this.FaceTarget($actor)
    
        $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Arachplaz)
    }
    
    SpidRefire([Mobj] $actor) {
        $this.FaceTarget($actor)
    
        if ($this.world.Random.Next() -lt 10) {
            return
        }
    
        if ($null -eq $actor.Target -or $actor.Target.Health -le 0 -or -not $this.world.VisibilityCheck.CheckSight($actor, $actor.Target)) {
            $actor.SetState($actor.Info.SeeState)
        }
    }
    
    CyberAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }
    
        $this.FaceTarget($actor)
    
        $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Rocket)
    }
    # Miscellaneous

    Explode([Mobj] $actor) {
        $this.world.ThingInteraction.RadiusAttack($actor, $actor.Target, 128)
    }

    Metal([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::METAL, [SfxType]::Footstep)
        $this.Chase($actor)
    }

    BabyMetal([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::BSPWLK, [SfxType]::Footstep)
        $this.Chase($actor)
    }

    Hoof([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::HOOF, [SfxType]::Footstep)
        $this.Chase($actor)
    }

    # Arch vile

    [Func[Mobj, bool]] $vileCheckFunc
    [Mobj] $vileTargetCorpse
    [Fixed] $vileTryX
    [Fixed] $vileTryY

    InitVile() {
        $this.vileCheckFunc = { param ($thing) $this.VileCheck($thing) }
    }

    [bool] VileCheck([Mobj] $thing) {
        if (($thing.Flags -band [MobjFlags]::Corpse) -eq 0) {
            return $true
        }

        if ($thing.Tics -ne -1) {
            return $true
        }

        if ($thing.Info.Raisestate -eq [MobjState]::Null) {
            return $true
        }

        $maxDist = $thing.Info.Radius + [DoomInfo]::MobjInfos[[int][MobjType]::Vile].Radius

        if ([Fixed]::Abs($thing.X - $this.vileTryX).Data -gt $maxDist.Data -or
            [Fixed]::Abs($thing.Y - $this.vileTryY).Data -gt $maxDist.Data) {
            return $true
        }

        $this.vileTargetCorpse = $thing
        $this.vileTargetCorpse.MomX = [Fixed]::Zero
        $this.vileTargetCorpse.MomY = [Fixed]::Zero
        $this.vileTargetCorpse.Height = $this.vileTargetCorpse.Height -shl 2

        $check = $this.world.ThingMovement.CheckPosition(
            $this.vileTargetCorpse,
            $this.vileTargetCorpse.X,
            $this.vileTargetCorpse.Y
        )

        $this.vileTargetCorpse.Height = $this.vileTargetCorpse.Height -shr 2

        return -not $check
    }

    VileChase([Mobj] $actor) {
        if ($actor.MoveDir -ne [Direction]::None) {
            $this.vileTryX = $actor.X + ($actor.Info.Speed * [MonsterBehavior]::xSpeed[[int]$actor.MoveDir])
            $this.vileTryY = $actor.Y + ($actor.Info.Speed * [MonsterBehavior]::ySpeed[[int]$actor.MoveDir])

            $bm = $this.world.Map.BlockMap
            $maxRadius = [GameConst]::MaxThingRadius * 2
            $blockX1 = $bm.GetBlockX($this.vileTryX - $maxRadius)
            $blockX2 = $bm.GetBlockX($this.vileTryX + $maxRadius)
            $blockY1 = $bm.GetBlockY($this.vileTryY - $maxRadius)
            $blockY2 = $bm.GetBlockY($this.vileTryY + $maxRadius)

            for ($bx = $blockX1; $bx -le $blockX2; $bx++) {
                for ($by = $blockY1; $by -le $blockY2; $by++) {
                    if (-not $bm.IterateThings($bx, $by, $this.vileCheckFunc)) {
                        $temp = $actor.Target
                        $actor.Target = $this.vileTargetCorpse
                        $this.FaceTarget($actor)
                        $actor.Target = $temp
                        $actor.SetState([MobjState]::VileHeal1)

                        $this.world.StartSound($this.vileTargetCorpse, [Sfx]::SLOP, [SfxType]::Misc)

                        $info = $this.vileTargetCorpse.Info
                        $this.vileTargetCorpse.SetState($info.Raisestate)
                        $this.vileTargetCorpse.Height = $this.vileTargetCorpse.Height -shl 2
                        $this.vileTargetCorpse.Flags = $info.Flags
                        $this.vileTargetCorpse.Health = $info.SpawnHealth
                        $this.vileTargetCorpse.Target = $null

                        return
                    }
                }
            }
        }

        $this.Chase($actor)
    }

    VileStart([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::VILATK, [SfxType]::Weapon)
    }

    StartFire([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::FLAMST, [SfxType]::Weapon)
        $this.Fire($actor)
    }

    FireCrackle([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::FLAME, [SfxType]::Weapon)
        $this.Fire($actor)
    }

    Fire([Mobj] $actor) {
        $dest = $actor.Tracer
        if ($null -eq $dest) {
            return
        }

        $target = $this.world.SubstNullMobj($actor.Target)

        if (-not $this.world.VisibilityCheck.CheckSight($target, $dest)) {
            return
        }

        $this.world.ThingMovement.UnsetThingPosition($actor)

        $angle = $dest.Angle
        $actor.X = $dest.X + ([Fixed]::FromInt(24) * [Trig]::Cos($angle))
        $actor.Y = $dest.Y + ([Fixed]::FromInt(24) * [Trig]::Sin($angle))
        $actor.Z = $dest.Z

        $this.world.ThingMovement.SetThingPosition($actor)
    }

    VileTarget([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        $fog = $this.world.ThingAllocation.SpawnMobj(
            $actor.Target.X,
            $actor.Target.Y,
            $actor.Target.Z,
            [MobjType]::Fire
        )

        $actor.Tracer = $fog
        $fog.Target = $actor
        $fog.Tracer = $actor.Target
        $this.Fire($fog)
    }

    VileAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        if (-not $this.world.VisibilityCheck.CheckSight($actor, $actor.Target)) {
            return
        }

        $this.world.StartSound($actor, [Sfx]::BAREXP, [SfxType]::Weapon)
        $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, 20)
        $actor.Target.MomZ = [Fixed]::FromInt(1000) / $actor.Target.Info.Mass

        $fire = $actor.Tracer
        if ($null -eq $fire) {
            return
        }

        $angle = $actor.Angle
        $fire.X = $actor.Target.X - ([Fixed]::FromInt(24) * [Trig]::Cos($angle))
        $fire.Y = $actor.Target.Y - ([Fixed]::FromInt(24) * [Trig]::Sin($angle))
        $this.world.ThingInteraction.RadiusAttack($fire, $actor, 70)
    }
    # Revenant

    SkelMissile([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        # Missile spawns higher.
        $actor.Z += [Fixed]::FromInt(16)

        $missile = $this.world.ThingAllocation.SpawnMissile($actor, $actor.Target, [MobjType]::Tracer)

        # Back to normal.
        $actor.Z -= [Fixed]::FromInt(16)

        $missile.X += $missile.MomX
        $missile.Y += $missile.MomY
        $missile.Tracer = $actor.Target
    }

    static [Angle] $traceAngle = [Angle]::new(0xc000000)

    Tracer([Mobj] $actor) {
        if (($this.world.GameTic -band 3) -ne 0) {
            return
        }

        # Spawn a puff of smoke behind the rocket.
        $this.world.Hitscan.SpawnPuff($actor.X, $actor.Y, $actor.Z)

        $smoke = $this.world.ThingAllocation.SpawnMobj(
            $actor.X - $actor.MomX,
            $actor.Y - $actor.MomY,
            $actor.Z,
            [MobjType]::Smoke
        )

        $smoke.MomZ = [Fixed]::One
        $smoke.Tics -= ($this.world.Random.Next() -band 3)
        if ($smoke.Tics -lt 1) {
            $smoke.Tics = 1
        }

        # Adjust direction.
        $dest = $actor.Tracer

        if ($null -eq $dest -or $dest.Health -le 0) {
            return
        }

        # Change angle.
        $exact = [Geometry]::PointToAngle($actor.X, $actor.Y, $dest.X, $dest.Y)

        if ($exact -ne $actor.Angle) {
            if ($exact - $actor.Angle -gt [Angle]::Ang180) {
                $actor.Angle -= [MonsterBehavior]::traceAngle
                if ($exact - $actor.Angle -lt [Angle]::Ang180) {
                    $actor.Angle = $exact
                }
            } else {
                $actor.Angle += [MonsterBehavior]::traceAngle
                if ($exact - $actor.Angle -gt [Angle]::Ang180) {
                    $actor.Angle = $exact
                }
            }
        }

        $exact = $actor.Angle
        $actor.MomX = [Fixed]::new($actor.Info.Speed) * [Trig]::Cos($exact)
        $actor.MomY = [Fixed]::new($actor.Info.Speed) * [Trig]::Sin($exact)

        # Change slope.
        $dist = [Geometry]::AproxDistance($dest.X - $actor.X, $dest.Y - $actor.Y)

        $num = ($dest.Z + [Fixed]::FromInt(40) - $actor.Z).Data
        $den = $dist.Data / $actor.Info.Speed
        if ($den -lt 1) {
            $den = 1
        }

        $slope = [Fixed]::new($num / $den)

        if ($slope.Data -lt $actor.MomZ.Data) {
            $actor.MomZ -= [Fixed]::One / 8
        } else {
            $actor.MomZ += [Fixed]::One / 8
        }
    }

    SkelWhoosh([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)
        $this.world.StartSound($actor, [Sfx]::SKESWG, [SfxType]::Weapon)
    }

    SkelFist([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)

        if ($this.CheckMeleeRange($actor)) {
            $damage = (($this.world.Random.Next() % 10) + 1) * 6
            $this.world.StartSound($actor, [Sfx]::SKEPCH, [SfxType]::Weapon)
            $this.world.ThingInteraction.DamageMobj($actor.Target, $actor, $actor, $damage)
        }
    }

    # Pain Elemental

    PainShootSkull([Mobj] $actor, [Angle] $angle) {
        # Count total number of skulls currently on the level.
        $count = 0

        $skullCountThinkersEnumerable = $this.world.Thinkers
        if ($null -ne $skullCountThinkersEnumerable) {
            $skullCountThinkersEnumerator = $skullCountThinkersEnumerable.GetEnumerator()
            for (; $skullCountThinkersEnumerator.MoveNext(); ) {
                $thinker = $skullCountThinkersEnumerator.Current
                $mobj = $thinker -as [Mobj]
                if ($null -ne $mobj -and $mobj.Type -eq [MobjType]::Skull) {
                    $count++
                }

            }
        }

        # If there are already 20 skulls on the level, don't spawn another.
        if ($count -gt 20) {
            return
        }

        # Compute the spawn position.
        $preStep = [Fixed]::FromInt(4) + (3 * ($actor.Info.Radius + [DoomInfo]::MobjInfos[[int][MobjType]::Skull].Radius) / 2)

        $x = $actor.X + ($preStep * [Trig]::Cos($angle))
        $y = $actor.Y + ($preStep * [Trig]::Sin($angle))
        $z = $actor.Z + [Fixed]::FromInt(8)

        $skull = $this.world.ThingAllocation.SpawnMobj($x, $y, $z, [MobjType]::Skull)

        # Check for movement.
        if (-not $this.world.ThingMovement.TryMove($skull, $skull.X, $skull.Y)) {
            $this.world.ThingInteraction.DamageMobj($skull, $actor, $actor, 10000)
            return
        }

        $skull.Target = $actor.Target
        $this.SkullAttack($skull)
    }

    PainAttack([Mobj] $actor) {
        if ($null -eq $actor.Target) {
            return
        }

        $this.FaceTarget($actor)
        $this.PainShootSkull($actor, $actor.Angle)
    }

    PainDie([Mobj] $actor) {
        $this.Fall($actor)

        $this.PainShootSkull($actor, $actor.Angle + [Angle]::Ang90)
        $this.PainShootSkull($actor, $actor.Angle + [Angle]::Ang180)
        $this.PainShootSkull($actor, $actor.Angle + [Angle]::Ang270)
    }
    # Boss death

    [LineDef] $junk

    InitBossDeath() {
        $v = [Vertex]::new([Fixed]::Zero, [Fixed]::Zero)
        $this.junk = [LineDef]::new($v, $v, [LineFlags]::Unknown, 0, 0, $null, $null)
    }

    BossDeath([Mobj] $actor) {
        $options = $this.world.Options

        if ($options.GameMode -eq [GameMode]::Commercial) {
            if ($options.Map -ne 7) {
                return
            }

            if (($actor.Type -ne [MobjType]::Fatso) -and ($actor.Type -ne [MobjType]::Baby)) {
                return
            }
        } else {
            switch ($options.Episode) {
                1 {
                    if ($options.Map -ne 8 -or $actor.Type -ne [MobjType]::Bruiser) {
                        return
                    }
                }
                2 {
                    if ($options.Map -ne 8 -or $actor.Type -ne [MobjType]::Cyborg) {
                        return
                    }
                }
                3 {
                    if ($options.Map -ne 8 -or $actor.Type -ne [MobjType]::Spider) {
                        return
                    }
                }
                4 {
                    switch ($options.Map) {
                        6 { if ($actor.Type -ne [MobjType]::Cyborg) { return } }
                        8 { if ($actor.Type -ne [MobjType]::Spider) { return } }
                        default { return }
                    }
                }
                default {
                    if ($options.Map -ne 8) {
                        return
                    }
                }
            }
        }

        # Make sure there is a player alive for victory.
        $players = $this.world.Options.Players
        $i = 0
        while ($i -lt [Player]::MaxPlayerCount) {
            if ($players[$i].InGame -and $players[$i].Health -gt 0) {
                break
            }
            $i++
        }

        if ($i -eq [Player]::MaxPlayerCount) {
            return
        }

        # Scan the remaining thinkers to see if all bosses are dead.
        $bossDeathThinkersEnumerable = $this.world.Thinkers
        if ($null -ne $bossDeathThinkersEnumerable) {
            $bossDeathThinkersEnumerator = $bossDeathThinkersEnumerable.GetEnumerator()
            for (; $bossDeathThinkersEnumerator.MoveNext(); ) {
                $thinker = $bossDeathThinkersEnumerator.Current
                $mo2 = $thinker -as [Mobj]
                if ($null -ne $mo2 -and $mo2 -ne $actor -and $mo2.Type -eq $actor.Type -and $mo2.Health -gt 0) {
                    return
                }

            }
        }

        # Victory!
        if ($options.GameMode -eq [GameMode]::Commercial) {
            if ($options.Map -eq 7) {
                if ($actor.Type -eq [MobjType]::Fatso) {
                    $this.junk.Tag = 666
                    $this.world.SectorAction.DoFloor($this.junk, [FloorMoveType]::LowerFloorToLowest)
                    return
                }

                if ($actor.Type -eq [MobjType]::Baby) {
                    $this.junk.Tag = 667
                    $this.world.SectorAction.DoFloor($this.junk, [FloorMoveType]::RaiseToTexture)
                    return
                }
            }
        } else {
            switch ($options.Episode) {
                1 {
                    $this.junk.Tag = 666
                    $this.world.SectorAction.DoFloor($this.junk, [FloorMoveType]::LowerFloorToLowest)
                    return
                }
                4 {
                    switch ($options.Map) {
                        6 {
                            $this.junk.Tag = 666
                            $this.world.SectorAction.DoDoor($this.junk, [VerticalDoorType]::BlazeOpen)
                            return
                        }
                        8 {
                            $this.junk.Tag = 666
                            $this.world.SectorAction.DoFloor($this.junk, [FloorMoveType]::LowerFloorToLowest)
                            return
                        }
                    }
                }
            }
        }

        $this.world.ExitLevel()
    }

    KeenDie([Mobj] $actor) {
        $this.Fall($actor)

        # Scan the remaining thinkers to see if all Keens are dead.
        $keenDeathThinkersEnumerable = $this.world.Thinkers
        if ($null -ne $keenDeathThinkersEnumerable) {
            $keenDeathThinkersEnumerator = $keenDeathThinkersEnumerable.GetEnumerator()
            for (; $keenDeathThinkersEnumerator.MoveNext(); ) {
                $thinker = $keenDeathThinkersEnumerator.Current
                $mo2 = $thinker -as [Mobj]
                if ($null -ne $mo2 -and $mo2 -ne $actor -and $mo2.Type -eq $actor.Type -and $mo2.Health -gt 0) {
                    return
                }

            }
        }

        $this.junk.Tag = 666
        $this.world.SectorAction.DoDoor($this.junk, [VerticalDoorType]::Open)
    }
    # Icon of Sin

    [Mobj[]] $brainTargets = @()
    [int] $brainTargetCount = 0
    [int] $currentBrainTarget = 0
    [bool] $easy = $false

    InitBrain() {
        $this.brainTargets = New-Object 'Mobj[]' 32
        $this.brainTargetCount = 0
        $this.currentBrainTarget = 0
        $this.easy = $false
    }

    BrainAwake([Mobj] $actor) {
        $this.brainTargetCount = 0
        $this.currentBrainTarget = 0

        $brainTargetThinkersEnumerable = $this.world.Thinkers
        if ($null -ne $brainTargetThinkersEnumerable) {
            $brainTargetThinkersEnumerator = $brainTargetThinkersEnumerable.GetEnumerator()
            for (; $brainTargetThinkersEnumerator.MoveNext(); ) {
                $thinker = $brainTargetThinkersEnumerator.Current
                $mobj = $thinker -as [Mobj]
                if ($null -ne $mobj -and $mobj.Type -eq [MobjType]::Bosstarget) {
                    $this.brainTargets[$this.brainTargetCount] = $mobj
                    $this.brainTargetCount++
                }

            }
        }

        $this.world.StartSound($actor, [Sfx]::BOSSIT, [SfxType]::Diffuse)
    }

    BrainPain([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::BOSPN, [SfxType]::Diffuse)
    }

    BrainScream([Mobj] $actor) {
        $random = $this.world.Random

        for ($x = $actor.X - [Fixed]::FromInt(196); $x -lt $actor.X + [Fixed]::FromInt(320); $x += [Fixed]::FromInt(8)) {
            $y = $actor.Y - [Fixed]::FromInt(320)
            $z = [Fixed]::new(128) + $random.Next() * [Fixed]::FromInt(2)

            $explosion = $this.world.ThingAllocation.SpawnMobj($x, $y, $z, [MobjType]::Rocket)
            $explosion.MomZ = [Fixed]::new($random.Next() * 512)
            $explosion.SetState([MobjState]::Brainexplode1)
            $explosion.Tics -= $random.Next() -band 7
            if ($explosion.Tics -lt 1) { $explosion.Tics = 1 }
        }

        $this.world.StartSound($actor, [Sfx]::BOSDTH, [SfxType]::Diffuse)
    }

    BrainExplode([Mobj] $actor) {
        $random = $this.world.Random

        $x = $actor.X + [Fixed]::new(($random.Next() - $random.Next()) * 2048)
        $y = $actor.Y
        $z = [Fixed]::new(128) + $random.Next() * [Fixed]::FromInt(2)

        $explosion = $this.world.ThingAllocation.SpawnMobj($x, $y, $z, [MobjType]::Rocket)
        $explosion.MomZ = [Fixed]::new($random.Next() * 512)
        $explosion.SetState([MobjState]::Brainexplode1)
        $explosion.Tics -= $random.Next() -band 7
        if ($explosion.Tics -lt 1) { $explosion.Tics = 1 }
    }

    BrainDie([Mobj] $actor) {
        $this.world.ExitLevel()
    }

    BrainSpit([Mobj] $actor) {
        $this.easy = -not $this.easy
        if ($this.world.Options.Skill -le [GameSkill]::Easy -and -not $this.easy) {
            return
        }

        if ($this.brainTargetCount -eq 0) {
            $this.BrainAwake($actor)
        }

        $target = $this.brainTargets[$this.currentBrainTarget]
        $this.currentBrainTarget = ($this.currentBrainTarget + 1) % $this.brainTargetCount

        $missile = $this.world.ThingAllocation.SpawnMissile($actor, $target, [MobjType]::Spawnshot)
        $missile.Target = $target
        $missile.ReactionTime = (($target.Y - $actor.Y).Data / $missile.MomY.Data) / $missile.State.Tics

        $this.world.StartSound($actor, [Sfx]::BOSPIT, [SfxType]::Diffuse)
    }

    SpawnSound([Mobj] $actor) {
        $this.world.StartSound($actor, [Sfx]::BOSCUB, [SfxType]::Misc)
        $this.SpawnFly($actor)
    }

    SpawnFly([Mobj] $actor) {
        if (--$actor.ReactionTime -gt 0) {
            return
        }

        $target = $actor.Target

        if ($null -eq $target) {
            $target = $actor
            $actor.Z = $actor.Subsector.Sector.FloorHeight
        }

        $ta = $this.world.ThingAllocation

        $fog = $ta.SpawnMobj($target.X, $target.Y, $target.Z, [MobjType]::Spawnfire)
        $this.world.StartSound($fog, [Sfx]::TELEPT, [SfxType]::Misc)

        $r = $this.world.Random.Next()
        #[MobjType]$function:type is needed because I cannot declare a empty value, and I need to access to value outside the scriptscopes of if's so I didn't want to add enum none.
        if ($r -lt 50) {
            [MobjType]$function:type = [MobjType]::Troop 
        } elseif ($r -lt 90) {
            [MobjType]$function:type = [MobjType]::Sergeant
        } elseif ($r -lt 120) {
            [MobjType]$function:type = [MobjType]::Shadows
        } elseif ($r -lt 130) {
            [MobjType]$function:type = [MobjType]::Pain
        } elseif ($r -lt 160) {
            [MobjType]$function:type = [MobjType]::Head
        } elseif ($r -lt 162) {
            [MobjType]$function:type = [MobjType]::Vile
        } elseif ($r -lt 172) {
            [MobjType]$function:type = [MobjType]::Undead
        } elseif ($r -lt 192) {
            [MobjType]$function:type = [MobjType]::Baby
        } elseif ($r -lt 222) {
            [MobjType]$function:type = [MobjType]::Fatso
        } elseif ($r -lt 246) {
            [MobjType]$function:type = [MobjType]::Knight
        } else {
            [MobjType]$function:type = [MobjType]::Bruiser
        }

        $monster = $ta.SpawnMobj($target.X, $target.Y, $target.Z, $function:type)
        if ($this.LookForPlayers($monster, $true)) {
            $monster.SetState($monster.Info.SeeState)
        }

        $this.world.ThingMovement.TeleportMove($monster, $monster.X, $monster.Y)

        $this.world.ThingAllocation.RemoveMobj($actor)
    }


}



