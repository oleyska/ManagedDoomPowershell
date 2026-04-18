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

class ThingInteraction {
    [World] $World
    static [int] $BaseThreshold = 100

    [Mobj] $BombSource
    [Mobj] $BombSpot
    [int] $BombDamage

    [Func[Mobj, bool]] $RadiusAttackFunc

    ThingInteraction([World] $world) {
        $this.World = $world
        $this.InitRadiusAttack()
    }

    [void] KillMobj([Mobj] $source, [Mobj] $target) {
        $target.Flags = $target.Flags -band -bnot ([MobjFlags]::Shootable -bor [MobjFlags]::Float -bor [MobjFlags]::SkullFly)

        if ($target.Type -ne [MobjType]::Skull) {
            $target.Flags = $target.Flags -band -bnot [MobjFlags]::NoGravity
        }

        $target.Flags = $target.Flags -bor ([MobjFlags]::Corpse -bor [MobjFlags]::DropOff)
        $target.Height = [Fixed]::new($target.Height.Data -shr 2)

        if ($null -ne $source -and $null -ne $source.Player) {
            if ([int]($target.Flags -band [MobjFlags]::CountKill) -ne 0) {
                $source.Player.KillCount++
            }
            if ($null -ne $target.Player) {
                $source.Player.Frags[$target.Player.Number]++
            }
        } elseif (-not $this.World.Options.NetGame -and [int]($target.Flags -band [MobjFlags]::CountKill) -ne 0) {
            $this.World.Options.Players[0].KillCount++
        }

        if ($null -ne $target.Player) {
            if ($null -eq $source) {
                $target.Player.Frags[$target.Player.Number]++
            }

            $target.Flags = $target.Flags -band -bnot [MobjFlags]::Solid
            $target.Player.PlayerState = [PlayerState]::Dead
            $this.World.PlayerBehavior.DropWeapon($target.Player)

            if ($target.Player.Number -eq $this.World.Options.ConsolePlayer -and $this.World.AutoMap.Visible) {
                $this.World.AutoMap.Close()
            }
        }

        if ($target.Health -lt -$target.Info.SpawnHealth -and $target.Info.XdeathState -ne 0) {
            $target.SetState($target.Info.XdeathState)
        } else {
            $target.SetState($target.Info.DeathState)
        }

        $target.Tics -= $this.World.Random.Next() -band 3
        if ($target.Tics -lt 1) {
            $target.Tics = 1
        }

        [MobjType]$item = [MobjType]::Clip
        switch ($target.Type) {
            ([MobjType]::Wolfss) { $item = [MobjType]::Clip }
            ([MobjType]::Possessed) { $item = [MobjType]::Clip }
            ([MobjType]::Shotguy) { $item = [MobjType]::Shotgun }
            ([MobjType]::Chainguy) { $item = [MobjType]::Chaingun }
            default { return }
        }

        $mo = $this.World.ThingAllocation.SpawnMobj($target.X, $target.Y, [Mobj]::OnFloorZ, $item)
        $mo.Flags = $mo.Flags -bor [MobjFlags]::Dropped
    }

    [void] DamageMobj([Mobj] $target, [Mobj] $inflictor, [Mobj] $source, [int] $damage) {
        if ([int]($target.Flags -band [MobjFlags]::Shootable) -eq 0 -or $target.Health -le 0) {
            return
        }

        if ([int]($target.Flags -band [MobjFlags]::SkullFly) -ne 0) {
            $target.MomX = $target.MomY = $target.MomZ = [Fixed]::Zero
        }

        $player = $target.Player
        if ($null -ne $player -and $this.World.Options.Skill -eq [GameSkill]::Baby) {
            $damage = $damage -shr 1
        }

        if ($null -ne $inflictor -and [int]($target.Flags -band [MobjFlags]::NoClip) -eq 0 -and
            ($null -eq $source -or $null -eq $source.Player -or $source.Player.ReadyWeapon -ne [WeaponType]::Chainsaw)) {
            $ang = [Geometry]::PointToAngle($inflictor.X, $inflictor.Y, $target.X, $target.Y)
            $thrustNumerator = $damage * ([Fixed]::FracUnit -shr 3) * 100
            $thrustValue = [int][Math]::Truncate(([double]$thrustNumerator) / ([double]$target.Info.Mass))
            $thrust = [Fixed]::new($thrustValue)

            if ($damage -lt 40 -and $damage -gt $target.Health -and
                ($target.Z - $inflictor.Z).Data -gt [Fixed]::FromInt(64).Data -and ($this.World.Random.Next() -band 1) -ne 0) {
                $ang += [Angle]::Ang180 #Integer
                $thrust *= 4
            }

            $target.MomX += $thrust * [Trig]::Cos($ang) #Integer
            $target.MomY += $thrust * [Trig]::Sin($ang) #Integer
        }

        if ($null -ne $player) {
            $saved = 0

            if ([int]$target.Subsector.Sector.Special -eq 11 -and $damage -ge $target.Health) {
                $damage = $target.Health - 1
            }

            if ($damage -lt 1000 -and
                (([int]($player.Cheats -band [CheatFlags]::GodMode) -ne 0) -or
                 $player.Powers[[int][PowerType]::Invulnerability] -gt 0)) {
                return
            }

            if ($player.ArmorType -ne 0) {
                if ($player.ArmorType -eq 1) {
                    $saved = [int][Math]::Truncate($damage / 3)
                } else {
                    $saved = [int][Math]::Truncate($damage / 2)
                }

                if ($player.ArmorPoints -le $saved) {
                    $saved = $player.ArmorPoints
                    $player.ArmorType = 0
                }

                $player.ArmorPoints -= $saved
                $damage -= $saved
            }

            $player.Health -= $damage
            if ($player.Health -lt 0) {
                $player.Health = 0
            }

            $player.Attacker = $source
            $player.DamageCount += $damage #Integer

            if ($player.DamageCount -gt 100) {
                $player.DamageCount = 100
            }
        }

        $target.Health -= $damage
        if ($target.Health -le 0) {
            $this.KillMobj($source, $target)
            return
        }

        if (($this.World.Random.Next() -lt $target.Info.PainChance) -and
            [int]($target.Flags -band [MobjFlags]::SkullFly) -eq 0) {
            $target.Flags = $target.Flags -bor [MobjFlags]::JustHit
            $target.SetState($target.Info.PainState)
        }

        $target.ReactionTime = 0

        if (($target.Threshold -eq 0 -or $target.Type -eq [MobjType]::Vile) -and
            $null -ne $source -and $source -ne $target -and $source.Type -ne [MobjType]::Vile) {
            $target.Target = $source
            $target.Threshold = [ThingInteraction]::BaseThreshold

            if ($target.State -eq [DoomInfo]::States.all[[int]$target.Info.SpawnState] -and
                $target.Info.SeeState -ne [MobjState]::Null) {
                $target.SetState($target.Info.SeeState)
            }
        }
    }

    [void] ExplodeMissile([Mobj] $thing) {
        $thing.MomX = $thing.MomY = $thing.MomZ = [Fixed]::Zero
        $thing.SetState([DoomInfo]::MobjInfos[[int]$thing.Type].DeathState)
        $thing.Tics -= $this.World.Random.Next() -band 3
        if ($thing.Tics -lt 1) {
            $thing.Tics = 1
        }
        $thing.Flags = $thing.Flags -band -bnot [MobjFlags]::Missile

        if ($thing.Info.DeathSound -ne 0) {
            $this.World.StartSound($thing, $thing.Info.DeathSound, [SfxType]::Misc)
        }
    }

    [void] InitRadiusAttack() {
        $owner = $this
        $callback = {
            param($thing)
            return $owner.DoRadiusAttack($thing)
        }.GetNewClosure()
        $this.RadiusAttackFunc = [Func[Mobj, bool]]$callback
    }

    [bool] DoRadiusAttack([Mobj] $thing) {
        if ([int]($thing.Flags -band [MobjFlags]::Shootable) -eq 0 -or
            $thing.Type -eq [MobjType]::Cyborg -or $thing.Type -eq [MobjType]::Spider) {
            return $true
        }

        $dx = [Fixed]::Abs($thing.X - $this.BombSpot.X)
        $dy = [Fixed]::Abs($thing.Y - $this.BombSpot.Y)
        $dist = if ($dx.Data -gt $dy.Data) { $dx } else { $dy }
        $dist = [Fixed]::new(($dist - $thing.Radius).Data -shr [Fixed]::FracBits)

        if ($dist.Data -lt [Fixed]::Zero.Data) { $dist = [Fixed]::Zero }

        if ($dist.Data -ge $this.BombDamage) {
            return $true
        }

        if ($this.World.VisibilityCheck.CheckSight($thing, $this.BombSpot)) {
            $this.DamageMobj($thing, $this.BombSpot, $this.BombSource, $this.BombDamage - $dist.Data)
        }

        return $true
    }

    [void] RadiusAttack([Mobj] $spot, [Mobj] $source, [int] $damage) {
        $bm = $this.World.Map.BlockMap

        $dist = [Fixed]::FromInt($damage + [GameConst]::MaxThingRadius.Data)

        $blockY1 = $bm.GetBlockY($spot.Y - $dist)
        $blockY2 = $bm.GetBlockY($spot.Y + $dist)
        $blockX1 = $bm.GetBlockX($spot.X - $dist)
        $blockX2 = $bm.GetBlockX($spot.X + $dist)

        $this.BombSpot = $spot
        $this.BombSource = $source
        $this.BombDamage = $damage

        for ($by = $blockY1; $by -le $blockY2; $by++) {
            for ($bx = $blockX1; $bx -le $blockX2; $bx++) {
                [void]$bm.IterateThings($bx, $by, $this.RadiusAttackFunc)
            }
        }
    }
}
