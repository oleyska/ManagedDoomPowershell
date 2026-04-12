class WeaponBehavior {
    static [Fixed] $MeleeRange = [Fixed]::FromInt(64)
    static [Fixed] $MissileRange = [Fixed]::FromInt(32 * 64)

    static [Fixed] $WeaponTop = [Fixed]::FromInt(32)
    static [Fixed] $WeaponBottom = [Fixed]::FromInt(128)

    static [Fixed] $RaiseSpeed = [Fixed]::FromInt(6)
    static [Fixed] $LowerSpeed = [Fixed]::FromInt(6)

    [World] $world
    [Fixed] $currentBulletSlope

    WeaponBehavior([World] $world) {
        $this.world = $world
    }

    [void] Light0([Player] $player) {
        $player.ExtraLight = 0
    }

    [void] WeaponReady([Player] $player, [PlayerSpriteDef] $psp) {
        $pb = $this.world.PlayerBehavior

        # Get out of attack state.
        if ($player.Mobj.State -eq [DoomInfo]::States.all[[int][MobjState]::PlayAtk1] -or
            $player.Mobj.State -eq [DoomInfo]::States.all[[int][MobjState]::PlayAtk2]) {
            $player.Mobj.SetState([MobjState]::Play)
        }

        if ($player.ReadyWeapon -eq [WeaponType]::Chainsaw -and
            $psp.State -eq [DoomInfo]::States.all[[int][MobjState]::Saw]) {
            $this.world.StartSound($player.Mobj, [Sfx]::SAWIDL, [SfxType]::Weapon)
        }

        # Check for weapon change.
        # If player is dead, put the weapon away.
        if ($player.PendingWeapon -ne [WeaponType]::NoChange -or $player.Health -eq 0) {
            # Change weapon.
            # Pending weapon should already be validated.
            $newState = [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].DownState
            $pb.SetPlayerSprite($player, [PlayerSprite]::Weapon, $newState)
            return
        }

        # Check for fire.
        # The missile launcher and BFG do not auto fire.
        if (($player.Cmd.Buttons -band [TicCmdButtons]::Attack) -ne 0) {
            if (-not $player.AttackDown -or
                ($player.ReadyWeapon -ne [WeaponType]::Missile -and $player.ReadyWeapon -ne [WeaponType]::Bfg)) {
                $player.AttackDown = $true
                $this.FireWeapon($player)
                return
            }
        } else {
            $player.AttackDown = $false
        }

        # Bob the weapon based on movement speed.
        $angle = (128 * $player.Mobj.World.LevelTime) -band [Trig]::FineMask
        $psp.Sx = [Fixed]::One + ($player.Bob * [Trig]::Cos($angle))

        $angle = $angle -band ([Trig]::FineAngleCount / 2 - 1)
        $psp.Sy = [WeaponBehavior]::WeaponTop + ($player.Bob * [Trig]::Sin($angle))
    }

    [bool] CheckAmmo([Player] $player) {
        $ammo = [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo

        # Minimal amount for one shot varies.
        [int] $count = 0
        if ($player.ReadyWeapon -eq [WeaponType]::Bfg) {
            $count = [DoomInfo]::DeHackEdConst.BfgCellsPerShot
        } elseif ($player.ReadyWeapon -eq [WeaponType]::SuperShotgun) {
            # Double barrel.
            $count = 2
        } else {
            # Regular.
            $count = 1
        }

        # Some do not need ammunition anyway.
        # Return if current ammunition is sufficient.
        if ($ammo -eq [AmmoType]::NoAmmo -or $player.Ammo[[int]$ammo] -ge $count) {
            return $true
        }

        # Out of ammo, pick a weapon to change to.
        # Preferences are set here.
        do {
            if ($player.WeaponOwned[[int][WeaponType]::Plasma] -and
                $player.Ammo[[int][AmmoType]::Cell] -gt 0 -and
                $this.world.Options.GameMode -ne [GameMode]::Shareware) {
                $player.PendingWeapon = [WeaponType]::Plasma
            } elseif ($player.WeaponOwned[[int][WeaponType]::SuperShotgun] -and
                $player.Ammo[[int][AmmoType]::Shell] -gt 2 -and
                $this.world.Options.GameMode -eq [GameMode]::Commercial) {
                $player.PendingWeapon = [WeaponType]::SuperShotgun
            } elseif ($player.WeaponOwned[[int][WeaponType]::Chaingun] -and
                $player.Ammo[[int][AmmoType]::Clip] -gt 0) {
                $player.PendingWeapon = [WeaponType]::Chaingun
            } elseif ($player.WeaponOwned[[int][WeaponType]::Shotgun] -and
                $player.Ammo[[int][AmmoType]::Shell] -gt 0) {
                $player.PendingWeapon = [WeaponType]::Shotgun
            } elseif ($player.Ammo[[int][AmmoType]::Clip] -gt 0) {
                $player.PendingWeapon = [WeaponType]::Pistol
            } elseif ($player.WeaponOwned[[int][WeaponType]::Chainsaw]) {
                $player.PendingWeapon = [WeaponType]::Chainsaw
            } elseif ($player.WeaponOwned[[int][WeaponType]::Missile] -and
                $player.Ammo[[int][AmmoType]::Missile] -gt 0) {
                $player.PendingWeapon = [WeaponType]::Missile
            } elseif ($player.WeaponOwned[[int][WeaponType]::Bfg] -and
                $player.Ammo[[int][AmmoType]::Cell] -gt [DoomInfo]::DeHackEdConst.BfgCellsPerShot -and
                $this.world.Options.GameMode -ne [GameMode]::Shareware) {
                $player.PendingWeapon = [WeaponType]::Bfg
            } else {
                # If everything fails.
                $player.PendingWeapon = [WeaponType]::Fist
            }
        } while ($player.PendingWeapon -eq [WeaponType]::NoChange)

        # Now set appropriate weapon overlay.
        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Weapon,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].DownState
        )

        return $false
    }

    [void] RecursiveSound([Sector] $sec, [int] $soundblocks, [Mobj] $soundtarget, [int] $validCount) {
        # Wake up all monsters in this sector.
        if ($sec.ValidCount -eq $validCount -and $sec.SoundTraversed -le $soundblocks + 1) {
            # Already flooded.
            return
        }

        $sec.ValidCount = $validCount
        $sec.SoundTraversed = $soundblocks + 1
        $sec.SoundTarget = $soundtarget

        $mc = $this.world.MapCollision

        for ($i = 0; $i -lt $sec.Lines.Length; $i++) {
            $check = $sec.Lines[$i]
            if (($check.Flags -band [LineFlags]::TwoSided) -eq 0) {
                continue
            }

            $mc.LineOpening($check)

            if ($mc.OpenRange.Data -le [Fixed]::Zero.Data) {
                # Closed door.
                continue
            }

            
            [Sector] $other = if ($check.FrontSide.Sector -eq $sec) {
                $check.BackSide.Sector
            } else {
                $check.FrontSide.Sector
            }

            if (($check.Flags -band [LineFlags]::SoundBlock) -ne 0) {
                if ($soundblocks -eq 0) {
                    $this.RecursiveSound($other, 1, $soundtarget, $validCount)
                }
            } else {
                $this.RecursiveSound($other, $soundblocks, $soundtarget, $validCount)
            }
        }
    }
    [void] NoiseAlert([Mobj] $target, [Mobj] $emmiter) {
        $this.RecursiveSound(
            $emmiter.Subsector.Sector,
            0,
            $target,
            $this.world.GetNewValidCount()
        )
    }

    [void] FireWeapon([Player] $player) {
        if (-not $this.CheckAmmo($player)) {
            return
        }

        $player.Mobj.SetState([MobjState]::PlayAtk1)

        $newState = [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].AttackState
        $this.world.PlayerBehavior.SetPlayerSprite($player, [PlayerSprite]::Weapon, $newState)

        $this.NoiseAlert($player.Mobj, $player.Mobj)
    }

    [void] Lower([Player] $player, [PlayerSpriteDef] $psp) {
        $psp.Sy = $psp.Sy + [WeaponBehavior]::LowerSpeed

        # Is already down.
        if ($psp.Sy.Data -lt [WeaponBehavior]::WeaponBottom.Data) {
            return
        }

        # Player is dead.
        if ($player.PlayerState -eq [PlayerState]::Dead) {
            $psp.Sy = [WeaponBehavior]::WeaponBottom

            # Don't bring weapon back up.
            return
        }

        $pb = $this.world.PlayerBehavior

        # The old weapon has been lowered off the screen,
        # so change the weapon and start raising it.
        if ($player.Health -eq 0) {
            # Player is dead, so keep the weapon off screen.
            $pb.SetPlayerSprite($player, [PlayerSprite]::Weapon, [MobjState]::Null)
            return
        }

        $player.ReadyWeapon = $player.PendingWeapon

        $pb.BringUpWeapon($player)
    }

    [void] Raise([Player] $player, [PlayerSpriteDef] $psp) {
        $psp.Sy = $psp.Sy - [WeaponBehavior]::RaiseSpeed

        if ($psp.Sy.Data -gt [WeaponBehavior]::WeaponTop.Data) {
            return
        }

        $psp.Sy = [WeaponBehavior]::WeaponTop

        # The weapon has been raised all the way, so change to the ready state.
        $newState = [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].ReadyState

        $this.world.PlayerBehavior.SetPlayerSprite($player, [PlayerSprite]::Weapon, $newState)
    }
    [void] Punch([Player] $player) {
        $random = $this.world.Random

        $damage = (($random.Next() % 10 + 1) -shl 1)

        if ($player.Powers[[int][PowerType]::Strength] -ne 0) {
            $damage *= 10
        }

        $hs = $this.world.Hitscan

        $angle = $player.Mobj.Angle
        $angle += [Angle]::new(($random.Next() - $random.Next()) -shl 18)

        $slope = $hs.AimLineAttack($player.Mobj, $angle, [WeaponBehavior]::MeleeRange)
        $hs.LineAttack($player.Mobj, $angle, [WeaponBehavior]::MeleeRange, $slope, $damage)

        # Turn to face target.
        if ($null -ne $hs.LineTarget) {
            $this.world.StartSound($player.Mobj, [Sfx]::PUNCH, [SfxType]::Weapon)

            $player.Mobj.Angle = [Geometry]::PointToAngle(
                $player.Mobj.X, $player.Mobj.Y,
                $hs.LineTarget.X, $hs.LineTarget.Y
            )
        }
    }

    [void] Saw([Player] $player) {
        $damage = 2 * ($this.world.Random.Next() % 10 + 1)

        $random = $this.world.Random

        $attackAngle = $player.Mobj.Angle
        $attackAngle += [Angle]::new(($random.Next() - $random.Next()) -shl 18)

        $hs = $this.world.Hitscan

        # Use MeleeRange + Fixed.Epsilon so that the puff doesn't skip the flash.
        $slope = $hs.AimLineAttack($player.Mobj, $attackAngle, [WeaponBehavior]::MeleeRange + [Fixed]::Epsilon)
        $hs.LineAttack($player.Mobj, $attackAngle, [WeaponBehavior]::MeleeRange + [Fixed]::Epsilon, $slope, $damage)

        if ($null -eq $hs.LineTarget) {
            $this.world.StartSound($player.Mobj, [Sfx]::SAWFUL, [SfxType]::Weapon)
            return
        }

        $this.world.StartSound($player.Mobj, [Sfx]::SAWHIT, [SfxType]::Weapon)

        # Turn to face target.
        $targetAngle = [Geometry]::PointToAngle(
            $player.Mobj.X, $player.Mobj.Y,
            $hs.LineTarget.X, $hs.LineTarget.Y
        )

        if ($targetAngle - $player.Mobj.Angle -gt [Angle]::Ang180) {
            # The code below is based on Mocha Doom's implementation.
            # It is still unclear for me why this code works like the original version...
            if ([int]($targetAngle - $player.Mobj.Angle).Data -lt -([Angle]::Ang90.Data / 20)) {
                $player.Mobj.Angle = $targetAngle + ([Angle]::Ang90 / 21)
            } else {
                $player.Mobj.Angle -= ([Angle]::Ang90 / 20)
            }
        } else {
            if ($targetAngle - $player.Mobj.Angle -gt ([Angle]::Ang90 / 20)) {
                $player.Mobj.Angle = $targetAngle - ([Angle]::Ang90 / 21)
            } else {
                $player.Mobj.Angle += ([Angle]::Ang90 / 20)
            }
        }

        $player.Mobj.Flags = $player.Mobj.Flags -bor [MobjFlags]::JustAttacked
    }
    [void] ReFire([Player] $player) {
        # Check for fire.
        # If a weapon change is pending, let it go through instead.
        if (($player.Cmd.Buttons -band [TicCmdButtons]::Attack) -ne 0 -and
            $player.PendingWeapon -eq [WeaponType]::NoChange -and
            $player.Health -ne 0) {
            $player.Refire++
            $this.FireWeapon($player)
        } else {
            $player.Refire = 0
            $this.CheckAmmo($player)
        }
    }

    [void] BulletSlope([Mobj] $mo) {
        $hs = $this.world.Hitscan

        # See which target is to be aimed at.
        $angle = $mo.Angle

        $this.currentBulletSlope = $hs.AimLineAttack($mo, $angle, [Fixed]::FromInt(1024))

        if ($null -eq $hs.LineTarget) {
            $angle += [Angle]::new(1 -shl 26)
            $this.currentBulletSlope = $hs.AimLineAttack($mo, $angle, [Fixed]::FromInt(1024))

            if ($null -eq $hs.LineTarget) {
                $angle -= [Angle]::new(2 -shl 26)
                $this.currentBulletSlope = $hs.AimLineAttack($mo, $angle, [Fixed]::FromInt(1024))
            }
        }
    }

    [void] GunShot([Mobj] $mo, [bool] $accurate) {
        $random = $this.world.Random

        $damage = 5 * ($random.Next() % 3 + 1)

        $angle = $mo.Angle

        if (-not $accurate) {
            $angle += [Angle]::new(($random.Next() - $random.Next()) -shl 18)
        }

        $this.world.Hitscan.LineAttack($mo, $angle, [WeaponBehavior]::MissileRange, $this.currentBulletSlope, $damage)
    }

    [void] FirePistol([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::PISTOL, [SfxType]::Weapon)

        $player.Mobj.SetState([MobjState]::PlayAtk2)

        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]--

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState
        )

        $this.BulletSlope($player.Mobj)

        $this.GunShot($player.Mobj, $player.Refire -eq 0)
    }

    [void] Light1([Player] $player) {
        $player.ExtraLight = 1
    }

    [void] FireShotgun([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::SHOTGN, [SfxType]::Weapon)

        $player.Mobj.SetState([MobjState]::PlayAtk2)

        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]--

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState
        )

        $this.BulletSlope($player.Mobj)

        for ($i = 0; $i -lt 7; $i++) {
            $this.GunShot($player.Mobj, $false)
        }
    }

    [void] Light2([Player] $player) {
        $player.ExtraLight = 2
    }
    [void] FireCGun([Player] $player, [PlayerSpriteDef] $psp) {
        $this.world.StartSound($player.Mobj, [Sfx]::PISTOL, [SfxType]::Weapon)

        if ($player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo] -eq 0) {
            return
        }

        $player.Mobj.SetState([MobjState]::PlayAtk2)

        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]--

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState +
            $psp.State.Number - [DoomInfo]::States.all[[int][MobjState]::Chain1].Number
        )

        $this.BulletSlope($player.Mobj)

        $this.GunShot($player.Mobj, $player.Refire -eq 0)
    }

    [void] FireShotgun2([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::DSHTGN, [SfxType]::Weapon)

        $player.Mobj.SetState([MobjState]::PlayAtk2)

        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo] -= 2

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState
        )

        $this.BulletSlope($player.Mobj)

        $random = $this.world.Random
        $hs = $this.world.Hitscan

        for ($i = 0; $i -lt 20; $i++) {
            $damage = 5 * ($random.Next() % 3 + 1)
            $angle = $player.Mobj.Angle
            $angle += [Angle]::new(($random.Next() - $random.Next()) -shl 19)
            
            $hs.LineAttack(
                $player.Mobj,
                $angle,
                [WeaponBehavior]::MissileRange,
                $this.currentBulletSlope + [Fixed]::new(($random.Next() - $random.Next()) -shl 5),
                $damage
            )
        }
    }

    [void] CheckReload([Player] $player) {
        $this.CheckAmmo($player)
    }

    [void] OpenShotgun2([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::DBOPN, [SfxType]::Weapon)
    }

    [void] LoadShotgun2([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::DBLOAD, [SfxType]::Weapon)
    }

    [void] CloseShotgun2([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::DBCLS, [SfxType]::Weapon)
        $this.ReFire($player)
    }

    [void] GunFlash([Player] $player) {
        $player.Mobj.SetState([MobjState]::PlayAtk2)

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState
        )
    }

    [void] FireMissile([Player] $player) {
        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]--

        $this.world.ThingAllocation.SpawnPlayerMissile($player.Mobj, [MobjType]::Rocket)
    }
    [void] FirePlasma([Player] $player) {
        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]--

        $this.world.PlayerBehavior.SetPlayerSprite(
            $player,
            [PlayerSprite]::Flash,
            [DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].FlashState + ($this.world.Random.Next() -band 1)
        )

        $this.world.ThingAllocation.SpawnPlayerMissile($player.Mobj, [MobjType]::Plasma)
    }

    [void] A_BFGsound([Player] $player) {
        $this.world.StartSound($player.Mobj, [Sfx]::BFG, [SfxType]::Weapon)
    }

    [void] FireBFG([Player] $player) {
        $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo] -= [DoomInfo]::DeHackEdConst.BfgCellsPerShot

        $this.world.ThingAllocation.SpawnPlayerMissile($player.Mobj, [MobjType]::Bfg)
    }

    [void] BFGSpray([Mobj] $bfgBall) {
        $hs = $this.world.Hitscan
        $random = $this.world.Random

        # Offset angles from its attack angle.
        for ($i = 0; $i -lt 40; $i++) {
            $an = $bfgBall.Angle - ([Angle]::Ang90 / 2) + ([Angle]::Ang90 / 40) * [uint]$i

            # bfgBall.Target is the originator (player) of the missile.
            $hs.AimLineAttack($bfgBall.Target, $an, [Fixed]::FromInt(16 * 64))

            if ($null -eq $hs.LineTarget) {
                continue
            }

            $this.world.ThingAllocation.SpawnMobj(
                $hs.LineTarget.X,
                $hs.LineTarget.Y,
                $hs.LineTarget.Z + ($hs.LineTarget.Height -shr 2),
                [MobjType]::Extrabfg
            )

            $damage = 0
            for ($j = 0; $j -lt 15; $j++) {
                $damage += ($random.Next() -band 7) + 1
            }

            $this.world.ThingInteraction.DamageMobj(
                $hs.LineTarget,
                $bfgBall.Target,
                $bfgBall.Target,
                $damage
            )
        }
    }

}
