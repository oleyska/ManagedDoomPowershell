class ItemPickup {
    [World] $World
    static [int] $BonusAdd = 6

    ItemPickup([World] $world) {
        $this.World = $world
    }

    [bool] GiveAmmo([Player] $player, [AmmoType] $ammo, [int] $amount) {
        if ($ammo -eq [AmmoType]::NoAmmo) { return $false }
        if ($ammo -lt 0 -or [int]$ammo -gt [int][AmmoType]::Count) {
            throw "Bad ammo type: $ammo"
        }
        if ($player.Ammo[[int]$ammo] -eq $player.MaxAmmo[[int]$ammo]) { return $false }

        if ($amount -ne 0) {
            $amount *= [DoomInfo]::AmmoInfos.Clip[[int]$ammo]
        } else {
            $amount = [DoomInfo]::AmmoInfos.Clip[[int]$ammo] / 2
        }

        if ($this.World.Options.Skill -eq [GameSkill]::Baby -or
            $this.World.Options.Skill -eq [GameSkill]::Nightmare) {
            $amount *= 2
        }

        $oldAmmo = $player.Ammo[[int]$ammo]
        $player.Ammo[[int]$ammo] += $amount
        if ($player.Ammo[[int]$ammo] -gt $player.MaxAmmo[[int]$ammo]) {
            $player.Ammo[[int]$ammo] = $player.MaxAmmo[[int]$ammo]
        }

        if ($oldAmmo -ne 0) { return $true }

        switch ($ammo) {
            ([AmmoType]::Clip) {
                if ($player.ReadyWeapon -eq [WeaponType]::Fist) {
                    if ($player.WeaponOwned[[int][WeaponType]::Chaingun]) {
                        $player.PendingWeapon = [WeaponType]::Chaingun
                    } else {
                        $player.PendingWeapon = [WeaponType]::Pistol
                    }
                }
            }
            ([AmmoType]::Shell) {
                if ($player.ReadyWeapon -eq [WeaponType]::Fist -or
                    $player.ReadyWeapon -eq [WeaponType]::Pistol) {
                    if ($player.WeaponOwned[[int][WeaponType]::Shotgun]) {
                        $player.PendingWeapon = [WeaponType]::Shotgun
                    }
                }
            }
            ([AmmoType]::Cell) {
                if ($player.ReadyWeapon -eq [WeaponType]::Fist -or
                    $player.ReadyWeapon -eq [WeaponType]::Pistol) {
                    if ($player.WeaponOwned[[int][WeaponType]::Plasma]) {
                        $player.PendingWeapon = [WeaponType]::Plasma
                    }
                }
            }
            ([AmmoType]::Missile) {
                if ($player.ReadyWeapon -eq [WeaponType]::Fist) {
                    if ($player.WeaponOwned[[int][WeaponType]::Missile]) {
                        $player.PendingWeapon = [WeaponType]::Missile
                    }
                }
            }
        }

        return $true
    }

    [bool] GiveWeapon([Player] $player, [WeaponType] $weapon, [bool] $dropped) {
        if ($this.World.Options.NetGame -and ($this.World.Options.Deathmatch -ne 2) -and -not $dropped) {
            if ($player.WeaponOwned[[int]$weapon]) { return $false }
            $player.BonusCount += [ItemPickup]::BonusAdd
            $player.WeaponOwned[[int]$weapon] = $true

            if ($this.World.Options.Deathmatch -ne 0) {
                $this.GiveAmmo($player, [DoomInfo]::WeaponInfos[[int]$weapon].Ammo, 5)
            } else {
                $this.GiveAmmo($player, [DoomInfo]::WeaponInfos[[int]$weapon].Ammo, 2)
            }

            $player.PendingWeapon = $weapon
            if ($player.Number -eq $this.World.Options.ConsolePlayer) {
                $this.World.StartSound($player.Mobj, [Sfx]::WPNUP, [SfxType]::Misc)
            }
            return $false
        }

        $gaveAmmo = $false
        if ([DoomInfo]::WeaponInfos[[int]$weapon].Ammo -ne [AmmoType]::NoAmmo) {
            if ($dropped) {
                $gaveAmmo = $this.GiveAmmo($player, [DoomInfo]::WeaponInfos[[int]$weapon].Ammo, 1)
            } else {
                $gaveAmmo = $this.GiveAmmo($player, [DoomInfo]::WeaponInfos[[int]$weapon].Ammo, 2)
            }
        }

        $gaveWeapon = -not $player.WeaponOwned[[int]$weapon]
        if ($gaveWeapon) {
            $player.WeaponOwned[[int]$weapon] = $true
            $player.PendingWeapon = $weapon
        }

        return ($gaveWeapon -or $gaveAmmo)
    }

    [bool] GiveHealth([Player] $player, [int] $amount) {
        if ($player.Health -ge [DoomInfo]::DeHackEdConst.InitialHealth) { return $false }
        $player.Health += $amount
        if ($player.Health -gt [DoomInfo]::DeHackEdConst.InitialHealth) {
            $player.Health = [DoomInfo]::DeHackEdConst.InitialHealth
        }
        $player.Mobj.Health = $player.Health
        return $true
    }

    [bool] GiveArmor([Player] $player, [int] $type) {
        $hits = $type * 100
        if ($player.ArmorPoints -ge $hits) { return $false }
        $player.ArmorType = $type
        $player.ArmorPoints = $hits
        return $true
    }

    [void] GiveCard([Player] $player, [CardType] $card) {
        if ($player.Cards[[int]$card]) { return }
        $player.BonusCount = [ItemPickup]::BonusAdd
        $player.Cards[[int]$card] = $true
    }

    [bool] GivePower([Player] $player, [PowerType] $type) {
        switch ($type) {
            ([PowerType]::Invulnerability) {
                $player.Powers[[int]$type] = [DoomInfo]::PowerDuration.Invulnerability
                return $true
            }
            ([PowerType]::Invisibility) {
                $player.Powers[[int]$type] = [DoomInfo]::PowerDuration.Invisibility
                $player.Mobj.Flags = $player.Mobj.Flags -bor [MobjFlags]::Shadow
                return $true
            }
            ([PowerType]::Infrared) {
                $player.Powers[[int]$type] = [DoomInfo]::PowerDuration.Infrared
                return $true
            }
            ([PowerType]::IronFeet) {
                $player.Powers[[int]$type] = [DoomInfo]::PowerDuration.IronFeet
                return $true
            }
            ([PowerType]::Strength) {
                $this.GiveHealth($player, 100)
                $player.Powers[[int]$type] = 1
                return $true
            }
        }

        if ($player.Powers[[int]$type] -ne 0) { return $false }
        $player.Powers[[int]$type] = 1
        return $true
    }

    [void] TouchSpecialThing([Mobj] $special, [Mobj] $toucher) {
        $delta = $special.Z - $toucher.Z
        if ($delta.Data -gt $toucher.Height.Data -or $delta.Data -lt [Fixed]::FromInt(-8).Data) {
            return
        }

        $player = $toucher.Player
        if ($null -eq $player -or $toucher.Health -le 0) {
            return
        }

        $sound = [Sfx]::ITEMUP
        switch ($special.Sprite) {
            ([Sprite]::ARM1) {
                if (-not $this.GiveArmor($player, [DoomInfo]::DeHackEdConst.GreenArmorClass)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTARMOR)
                break
            }
            ([Sprite]::ARM2) {
                if (-not $this.GiveArmor($player, [DoomInfo]::DeHackEdConst.BlueArmorClass)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTMEGA)
                break
            }
            ([Sprite]::BON1) {
                $player.Health++
                if ($player.Health -gt [DoomInfo]::DeHackEdConst.MaxHealth) {
                    $player.Health = [DoomInfo]::DeHackEdConst.MaxHealth
                }
                $player.Mobj.Health = $player.Health
                $player.SendMessage([DoomInfo]::Strings.GOTHTHBONUS)
                break
            }
            ([Sprite]::BON2) {
                $player.ArmorPoints++
                if ($player.ArmorPoints -gt [DoomInfo]::DeHackEdConst.MaxArmor) {
                    $player.ArmorPoints = [DoomInfo]::DeHackEdConst.MaxArmor
                }
                if ($player.ArmorType -eq 0) {
                    $player.ArmorType = [DoomInfo]::DeHackEdConst.GreenArmorClass
                }
                $player.SendMessage([DoomInfo]::Strings.GOTARMBONUS)
                break
            }
            ([Sprite]::SOUL) {
                $player.Health += [DoomInfo]::DeHackEdConst.SoulsphereHealth
                if ($player.Health -gt [DoomInfo]::DeHackEdConst.MaxSoulsphere) {
                    $player.Health = [DoomInfo]::DeHackEdConst.MaxSoulsphere
                }
                $player.Mobj.Health = $player.Health
                $player.SendMessage([DoomInfo]::Strings.GOTSUPER)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::MEGA) {
                if ($this.World.Options.GameMode -ne [GameMode]::Commercial) { return }
                $player.Health = [DoomInfo]::DeHackEdConst.MegasphereHealth
                $player.Mobj.Health = $player.Health
                $this.GiveArmor($player, [DoomInfo]::DeHackEdConst.BlueArmorClass) > $null
                $player.SendMessage([DoomInfo]::Strings.GOTMSPHERE)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::BKEY) {
                if (-not $player.Cards[[int][CardType]::BlueCard]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTBLUECARD)
                }
                $this.GiveCard($player, [CardType]::BlueCard)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::YKEY) {
                if (-not $player.Cards[[int][CardType]::YellowCard]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTYELWCARD)
                }
                $this.GiveCard($player, [CardType]::YellowCard)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::RKEY) {
                if (-not $player.Cards[[int][CardType]::RedCard]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTREDCARD)
                }
                $this.GiveCard($player, [CardType]::RedCard)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::BSKU) {
                if (-not $player.Cards[[int][CardType]::BlueSkull]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTBLUESKUL)
                }
                $this.GiveCard($player, [CardType]::BlueSkull)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::YSKU) {
                if (-not $player.Cards[[int][CardType]::YellowSkull]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTYELWSKUL)
                }
                $this.GiveCard($player, [CardType]::YellowSkull)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::RSKU) {
                if (-not $player.Cards[[int][CardType]::RedSkull]) {
                    $player.SendMessage([DoomInfo]::Strings.GOTREDSKULL)
                }
                $this.GiveCard($player, [CardType]::RedSkull)
                if (-not $this.World.Options.NetGame) { break }
                return
            }
            ([Sprite]::STIM) {
                if (-not $this.GiveHealth($player, 10)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSTIM)
                break
            }
            ([Sprite]::MEDI) {
                if (-not $this.GiveHealth($player, 25)) { return }
                if ($player.Health -lt 25) {
                    $player.SendMessage([DoomInfo]::Strings.GOTMEDINEED)
                } else {
                    $player.SendMessage([DoomInfo]::Strings.GOTMEDIKIT)
                }
                break
            }
            ([Sprite]::PINV) {
                if (-not $this.GivePower($player, [PowerType]::Invulnerability)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTINVUL)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::PSTR) {
                if (-not $this.GivePower($player, [PowerType]::Strength)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTBERSERK)
                if ($player.ReadyWeapon -ne [WeaponType]::Fist) {
                    $player.PendingWeapon = [WeaponType]::Fist
                }
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::PINS) {
                if (-not $this.GivePower($player, [PowerType]::Invisibility)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTINVIS)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::SUIT) {
                if (-not $this.GivePower($player, [PowerType]::IronFeet)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSUIT)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::PMAP) {
                if (-not $this.GivePower($player, [PowerType]::AllMap)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTMAP)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::PVIS) {
                if (-not $this.GivePower($player, [PowerType]::Infrared)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTVISOR)
                $sound = [Sfx]::GETPOW
                break
            }
            ([Sprite]::CLIP) {
                if ([int]($special.Flags -band [MobjFlags]::Dropped) -ne 0) {
                    if (-not $this.GiveAmmo($player, [AmmoType]::Clip, 0)) { return }
                } else {
                    if (-not $this.GiveAmmo($player, [AmmoType]::Clip, 1)) { return }
                }
                $player.SendMessage([DoomInfo]::Strings.GOTCLIP)
                break
            }
            ([Sprite]::AMMO) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Clip, 5)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTCLIPBOX)
                break
            }
            ([Sprite]::ROCK) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Missile, 1)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTROCKET)
                break
            }
            ([Sprite]::BROK) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Missile, 5)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTROCKBOX)
                break
            }
            ([Sprite]::CELL) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Cell, 1)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTCELL)
                break
            }
            ([Sprite]::CELP) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Cell, 5)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTCELLBOX)
                break
            }
            ([Sprite]::SHEL) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Shell, 1)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSHELLS)
                break
            }
            ([Sprite]::SBOX) {
                if (-not $this.GiveAmmo($player, [AmmoType]::Shell, 5)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSHELLBOX)
                break
            }
            ([Sprite]::BPAK) {
                if (-not $player.Backpack) {
                    for ($i = 0; $i -lt [int][AmmoType]::Count; $i++) {
                        $player.MaxAmmo[$i] *= 2
                    }
                    $player.Backpack = $true
                }
                for ($i = 0; $i -lt [int][AmmoType]::Count; $i++) {
                    $this.GiveAmmo($player, [AmmoType]$i, 1) > $null
                }
                $player.SendMessage([DoomInfo]::Strings.GOTBACKPACK)
                break
            }
            ([Sprite]::BFUG) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Bfg, $false)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTBFG9000)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::MGUN) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Chaingun, ([int]($special.Flags -band [MobjFlags]::Dropped) -ne 0))) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTCHAINGUN)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::CSAW) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Chainsaw, $false)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTCHAINSAW)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::LAUN) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Missile, $false)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTLAUNCHER)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::PLAS) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Plasma, $false)) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTPLASMA)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::SHOT) {
                if (-not $this.GiveWeapon($player, [WeaponType]::Shotgun, ([int]($special.Flags -band [MobjFlags]::Dropped) -ne 0))) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSHOTGUN)
                $sound = [Sfx]::WPNUP
                break
            }
            ([Sprite]::SGN2) {
                if (-not $this.GiveWeapon($player, [WeaponType]::SuperShotgun, ([int]($special.Flags -band [MobjFlags]::Dropped) -ne 0))) { return }
                $player.SendMessage([DoomInfo]::Strings.GOTSHOTGUN2)
                $sound = [Sfx]::WPNUP
                break
            }
            default {
                throw "Unknown gettable thing!"
            }
        }

        if ([int]($special.Flags -band [MobjFlags]::CountItem) -ne 0) {
            $player.ItemCount++
        }

        $this.World.ThingAllocation.RemoveMobj($special)
        $player.BonusCount += [ItemPickup]::BonusAdd

        if ($player.Number -eq $this.World.Options.ConsolePlayer) {
            $this.World.StartSound($player.Mobj, $sound, [SfxType]::Misc)
        }
    }
}
