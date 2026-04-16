class PlayerBehavior {
    static [int[]]$ForwardMove = @(0x19, 0x32)
    static [int[]]$SideMove = @(0x18, 0x28)
    static [int[]]$AngleTurn = @(640, 1280, 320) # For slow turn
    static [int]$MaxMove = [PlayerBehavior]::ForwardMove[1]
    static [int]$SlowTurnTics = 6
    static [Fixed]$maxBob = [Fixed]::new(0x100000)

    [world]$World
    [bool] $onGround

    PlayerBehavior([World]$world) {
        $this.World = $world
        $this.onGround = $false
    }

    [void] PlayerThink([Player]$player) {
        if ($player.MessageTime -gt 0) {
            $player.MessageTime--
        }

        if ($player.Cheats -band [CheatFlags]::NoClip) {
            $player.Mobj.Flags = $player.Mobj.Flags -bor [MobjFlags]::NoClip
        } else {
            $player.Mobj.Flags = $player.Mobj.Flags -band (-bnot [MobjFlags]::NoClip)
        }

        # Chainsaw run forward
        $cmd = $player.Cmd
        if ($player.Mobj.Flags -band [MobjFlags]::JustAttacked) {
            $cmd.AngleTurn = 0
            $cmd.ForwardMove = 0xC800 / 512
            $cmd.SideMove = 0
            $player.Mobj.Flags = $player.Mobj.Flags -band (-bnot [MobjFlags]::JustAttacked)
        }

        if ($player.PlayerState -eq [PlayerState]::Dead) {
            $this.DeathThink($player)
            return
        }

        if ($player.Mobj.ReactionTime -gt 0) {
            $player.Mobj.ReactionTime--
        } else {
            $this.MovePlayer($player)
        }

        $this.CalcHeight($player)

        if ($player.Mobj.Subsector.Sector.Special -ne 0) {
            $this.PlayerInSpecialSector($player)
        }

        # Handle weapon change
        if ($cmd.Buttons -band [TicCmdButtons]::Special) {
            $cmd.Buttons = 0
        }

        if ($cmd.Buttons -band [TicCmdButtons]::Change) {
            $this.ChangeWeapon($player, $cmd.Buttons)
        }

        if ($cmd.Buttons -band [TicCmdButtons]::Use) {
            if (-not $player.UseDown) {
                $this.World.MapInteraction.UseLines($player)
                $player.UseDown = $true
            }
        } else {
            $player.UseDown = $false
        }

        $this.MovePlayerSprites($player)
        $this.HandlePowerups($player)
    }

    [void] MovePlayer([Player]$player) {
        $cmd = $player.Cmd
        $player.Mobj.Angle += (([int]$cmd.AngleTurn) -shl 16)
        $this.onGround = ($player.Mobj.Z.Data -le $player.Mobj.FloorZ.Data)

        if ($cmd.ForwardMove -ne 0 -and $this.onGround) {
            $this.Thrust($player, $player.Mobj.Angle, $cmd.ForwardMove * 2048)
        }
        if ($cmd.SideMove -ne 0 -and $this.onGround) {
            $this.Thrust($player, $player.Mobj.Angle - [Angle]::Ang90, $cmd.SideMove * 2048)
        }

        if (($cmd.ForwardMove -ne 0 -or $cmd.SideMove -ne 0) -and
            $player.Mobj.State -eq [DoomInfo]::States.all[[int][MobjState]::Play]) {
            $player.Mobj.SetState([MobjState]::PlayRun1)
        }
    }

    [void] ChangeWeapon([player]$player, [int]$buttons) {
        $newWeapon = ($buttons -band [TicCmdButtons]::WeaponMask) -shr [TicCmdButtons]::WeaponShift

        if ($newWeapon -eq [WeaponType]::Fist -and 
            $player.WeaponOwned[[WeaponType]::Chainsaw] -and 
            !($player.ReadyWeapon -eq [WeaponType]::Chainsaw -and $player.Powers[[PowerType]::Strength] -ne 0)) {
            $newWeapon = [WeaponType]::Chainsaw
        }

        if (($this.World.Options.GameMode -eq [GameMode]::Commercial) -and 
            $newWeapon -eq [WeaponType]::Shotgun -and 
            $player.WeaponOwned[[WeaponType]::SuperShotgun] -and 
            $player.ReadyWeapon -ne [WeaponType]::SuperShotgun) {
            $newWeapon = [WeaponType]::SuperShotgun
        }

        if ($player.WeaponOwned[$newWeapon] -and $newWeapon -ne $player.ReadyWeapon) {
            if (($newWeapon -ne [WeaponType]::Plasma -and $newWeapon -ne [WeaponType]::Bfg) -or 
                ($this.World.Options.GameMode -ne [GameMode]::Shareware)) {
                $player.PendingWeapon = $newWeapon
            }
        }
    }

    [void] Thrust([Player]$player, [Angle]$angle, [int]$move) {
        $thrust = [Fixed]::new($move)
        $player.Mobj.MomX += $thrust * [Trig]::Cos($angle)
        $player.Mobj.MomY += $thrust * [Trig]::Sin($angle)
    }

    [void] CalcHeight([Player]$player) {
        $player.Bob = ($player.Mobj.MomX * $player.Mobj.MomX) + ($player.Mobj.MomY * $player.Mobj.MomY)
        $player.Bob = [Fixed]::new($player.Bob.Data -shr 2)
        if ($player.Bob.Data -gt [PlayerBehavior]::maxBob.Data) {
            $player.Bob = [PlayerBehavior]::maxBob
        }

        if (($player.Cheats -band [CheatFlags]::NoMomentum) -ne 0 -or -not $this.onGround) {
            $player.ViewZ = $player.Mobj.Z + [Player]::NormalViewHeight
            $ceilingLimit = $player.Mobj.CeilingZ - [Fixed]::FromInt(4)
            if ($player.ViewZ.Data -gt $ceilingLimit.Data) {
                $player.ViewZ = $ceilingLimit
            }

            $player.ViewZ = $player.Mobj.Z + $player.ViewHeight
            return
        }

        $angle = (([Trig]::FineAngleCount / 20) * $this.World.LevelTime) -band [Trig]::FineMask
        $bob = ($player.Bob / 2) * [Trig]::SinFromInt($angle)

        if ($player.PlayerState -eq [PlayerState]::Live) {
            $player.ViewHeight += $player.DeltaViewHeight

            if ($player.ViewHeight.Data -gt [Player]::NormalViewHeight.Data) {
                $player.ViewHeight = [Player]::NormalViewHeight
                $player.DeltaViewHeight = [Fixed]::Zero
            }

            $minViewHeight = [Player]::NormalViewHeight / 2
            if ($player.ViewHeight.Data -lt $minViewHeight.Data) {
                $player.ViewHeight = $minViewHeight
                if ($player.DeltaViewHeight.Data -le [Fixed]::Zero.Data) {
                    $player.DeltaViewHeight = [Fixed]::new(1)
                }
            }

            if ($player.DeltaViewHeight.Data -ne [Fixed]::Zero.Data) {
                $player.DeltaViewHeight += [Fixed]::One / 4
                if ($player.DeltaViewHeight.Data -eq [Fixed]::Zero.Data) {
                    $player.DeltaViewHeight = [Fixed]::new(1)
                }
            }
        }

        $player.ViewZ = $player.Mobj.Z + $player.ViewHeight + $bob
        $ceilingLimit = $player.Mobj.CeilingZ - [Fixed]::FromInt(4)
        if ($player.ViewZ.Data -gt $ceilingLimit.Data) {
            $player.ViewZ = $ceilingLimit
        }
    }

    [void] HandlePowerups([Player]$player) {
        if ($player.Powers[[int][PowerType]::Strength] -ne 0) {
            $player.Powers[[int][PowerType]::Strength]++
        }

        if ($player.Powers[[int][PowerType]::Invulnerability] -gt 0) {
            $player.Powers[[int][PowerType]::Invulnerability]--
        }

        if ($player.Powers[[int][PowerType]::Invisibility] -gt 0) {
            $player.Powers[[int][PowerType]::Invisibility]--
            if ($player.Powers[[int][PowerType]::Invisibility] -eq 0) {
                $player.Mobj.Flags = $player.Mobj.Flags -band (-bnot [MobjFlags]::Shadow)
            }
        }

        if ($player.Powers[[int][PowerType]::Infrared] -gt 0) {
            $player.Powers[[int][PowerType]::Infrared]--
        }

        if ($player.Powers[[int][PowerType]::IronFeet] -gt 0) {
            $player.Powers[[int][PowerType]::IronFeet]--
        }

        if ($player.DamageCount -gt 0) {
            $player.DamageCount--
        }

        if ($player.BonusCount -gt 0) {
            $player.BonusCount--
        }

        if ($player.Powers[[int][PowerType]::Invulnerability] -gt 0) {
            if ($player.Powers[[int][PowerType]::Invulnerability] -gt (4 * 32) -or
                (($player.Powers[[int][PowerType]::Invulnerability] -band 8) -ne 0)) {
                $player.FixedColorMap = [ColorMap]::Inverse
            } else {
                $player.FixedColorMap = 0
            }
        } elseif ($player.Powers[[int][PowerType]::Infrared] -gt 0) {
            if ($player.Powers[[int][PowerType]::Infrared] -gt (4 * 32) -or
                (($player.Powers[[int][PowerType]::Infrared] -band 8) -ne 0)) {
                $player.FixedColorMap = 1
            } else {
                $player.FixedColorMap = 0
            }
        } else {
            $player.FixedColorMap = 0
        }
    }

    [void] MovePlayerSprites([Player]$player) {
        for ($i = 0; $i -lt [int][PlayerSprite]::Count; $i++) {
            $psp = $player.PlayerSprites[$i]
            if ($null -ne $psp.State -and $psp.Tics -ne -1) {
                $psp.Tics--
                if ($psp.Tics -eq 0) {
                    $this.SetPlayerSprite($player, $i, $psp.State.Next)
                }
            }
        }

        $player.PlayerSprites[[int][PlayerSprite]::Flash].Sx = $player.PlayerSprites[[int][PlayerSprite]::Weapon].Sx
        $player.PlayerSprites[[int][PlayerSprite]::Flash].Sy = $player.PlayerSprites[[int][PlayerSprite]::Weapon].Sy
    }

    [void] SetPlayerSprite([Player]$player, [int]$position, [MobjState]$state) {
        $psp = $player.PlayerSprites[$position]
        [MobjState] $inState = $state

        do {
            if ($inState -eq [MobjState]::Null) {
                $psp.State = $null
                return
            }

            $st = [DoomInfo]::States.all[[int]$inState]
            $psp.State = $st
            $psp.Tics = $st.Tics

            if ($st.Misc1 -ne 0 -or $st.Misc2 -ne 0) {
                $psp.Sx = [Fixed]::new($st.Misc1)
                $psp.Sy = [Fixed]::new($st.Misc2)
            }

            $st.ExecutePlayerAction($this.World, $player, $psp)
            $inState = $st.Next
        } while ($psp.Tics -eq 0)
    }

    [void] PlayerScream([object]$playerOrMobj) {
        [Mobj]$mobj = if ($playerOrMobj -is [Player]) { $playerOrMobj.Mobj } else { $playerOrMobj }
        [int]$health = if ($playerOrMobj -is [Player]) {
            $playerOrMobj.Health
        } elseif ($null -ne $mobj.Player) {
            $mobj.Player.Health
        } else {
            $mobj.Health
        }

        $sound = [Sfx]::PLDETH
        if ($this.World.Options.GameMode -eq [GameMode]::Commercial -and $health -lt -50) {
            $sound = [Sfx]::PDIEHI
        }
        $this.World.StartSound($mobj, $sound, [SfxType]::Voice)
    }

    [void] DeathThink([Player]$player) {
        $this.MovePlayerSprites($player)
        $deathViewHeight = [Fixed]::FromInt(6)
        $deathTurn = [Angle]::new(5)
        $negativeDeathTurn = [Angle]::new(-5)
    
        # Fall to the ground
        if ($player.ViewHeight.Data -gt $deathViewHeight.Data) {
            $player.ViewHeight -= [Fixed]::One
        }
        if ($player.ViewHeight.Data -lt $deathViewHeight.Data) {
            $player.ViewHeight = $deathViewHeight
        }
    
        $player.DeltaViewHeight = [Fixed]::Zero
        $this.onGround = ($player.Mobj.Z.Data -le $player.Mobj.FloorZ.Data)
        $this.CalcHeight($player)
    
        if ($null -ne $player.Attacker -and $player.Attacker -ne $player.Mobj) {
            $angle = [Geometry]::PointToAngle(
                $player.Mobj.X, $player.Mobj.Y,
                $player.Attacker.X, $player.Attacker.Y)
            $delta = $angle - $player.Mobj.Angle
    
            if ($delta.Data -lt $deathTurn.Data -or $delta.Data -gt $negativeDeathTurn.Data) {
                $player.Mobj.Angle = $angle
                if ($player.DamageCount -gt 0) {
                    $player.DamageCount--
                }
            } elseif ($delta.Data -lt [Angle]::Ang180.Data) {
                $player.Mobj.Angle += $deathTurn
            } else {
                $player.Mobj.Angle -= $deathTurn
            }
        } elseif ($player.DamageCount -gt 0) {
            $player.DamageCount--
        }
    
        if ($player.Cmd.Buttons -band [TicCmdButtons]::Use) {
            $player.PlayerState = [PlayerState]::Reborn
        }
    }
    [void] PlayerInSpecialSector([Player]$player) {
        $sector = $player.Mobj.Subsector.Sector
    
        if ($player.Mobj.Z.Data -ne $sector.FloorHeight.Data) {
            return
        }
    
        $ti = $this.World.ThingInteraction
    
        switch ([int]$sector.Special) {
            5 {
                if ($player.Powers[[PowerType]::IronFeet] -eq 0 -and ($this.World.LevelTime -band 0x1f) -eq 0) {
                    $ti.DamageMobj($player.Mobj, $null, $null, 10)
                }
            }
            7 {
                if ($player.Powers[[PowerType]::IronFeet] -eq 0 -and ($this.World.LevelTime -band 0x1f) -eq 0) {
                    $ti.DamageMobj($player.Mobj, $null, $null, 5)
                }
            }
            16{}
            4 {
                if ($player.Powers[[PowerType]::IronFeet] -eq 0 -or ($this.World.Random.Next() -lt 5)) {
                    if (($this.World.LevelTime -band 0x1f) -eq 0) {
                        $ti.DamageMobj($player.Mobj, $null, $null, 20)
                    }
                }
            }
            9 {
                $player.SecretCount++
                $sector.Special = 0
            }
            11 {
                $player.Cheats = $player.Cheats -band (-bnot [CheatFlags]::GodMode)
                if (($this.World.LevelTime -band 0x1f) -eq 0) {
                    $ti.DamageMobj($player.Mobj, $null, $null, 20)
                }
                if ($player.Health -le 10) {
                    $this.World.ExitLevel()
                }
            }
            default {
                return
            }
        }
    }
    
    [void] SetupPlayerSprites([Player]$player) {
        for ($i = 0; $i -lt [PlayerSprite]::Count; $i++) {
            $player.PlayerSprites[$i].State = $null
        }
        $player.PendingWeapon = $player.ReadyWeapon
        $this.BringUpWeapon($player)
    }
    
    [void] BringUpWeapon([Player]$player) {
        if ($player.PendingWeapon -eq [WeaponType]::NoChange) {
            $player.PendingWeapon = $player.ReadyWeapon
        }
    
        if ($player.PendingWeapon -eq [WeaponType]::Chainsaw) {
            $this.World.StartSound($player.Mobj, "SAWUP", "Weapon")
        }

        $newState = [DoomInfo]::WeaponInfos[$player.PendingWeapon].UpState
        $player.PendingWeapon = [WeaponType]::NoChange
        $player.PlayerSprites[[int][PlayerSprite]::Weapon].Sy = [WeaponBehavior]::WeaponBottom
        $this.SetPlayerSprite($player, [PlayerSprite]::Weapon, $newState)
    }
    
    [void] DropWeapon([player]$player) {
        $this.SetPlayerSprite(
            $player,
            [PlayerSprite]::Weapon,
            [DoomInfo]::WeaponInfos[$player.ReadyWeapon].DownState
        )
    }
}


