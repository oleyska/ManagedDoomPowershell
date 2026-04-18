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

class ThingAllocation {
    [World] $World

    [MapThing[]] $PlayerStarts
    [System.Collections.Generic.List[MapThing]] $DeathmatchStarts

    [Mobj[]] $BodyQue
    [int] $BodyQueSlot
    [MapThing[]] $ItemRespawnQue
    [int[]] $ItemRespawnTime
    [int] $ItemQueHead
    [int] $ItemQueTail

    static [int] $BodyQueSize = 32
    static [int] $ItemQueSize = 128

    ThingAllocation([World] $world) {
        $this.World = $world

        $this.InitSpawnMapThing()
        $this.InitMultiPlayerRespawn()
        $this.InitRespawnSpecials()
    }

    [void] InitSpawnMapThing() {
        $this.PlayerStarts = New-Object 'MapThing[]' ([Player]::MaxPlayerCount)
        $this.DeathmatchStarts = New-Object 'System.Collections.Generic.List[MapThing]'
    }
    [void] InitMultiPlayerRespawn()
    {
        $this.bodyQueSlot = 0
        $this.bodyQue = New-Object Mobj[] ([ThingAllocation]::bodyQueSize)
    }
    [void] InitRespawnSpecials()
    {
        $this.itemRespawnQue = New-Object MapThing[] ([ThingAllocation]::itemQueSize)
        $this.itemRespawnTime = New-Object int[] ([ThingAllocation]::itemQueSize)
        $this.itemQueHead = 0;
        $this.itemQueTail = 0;
    }

    [void] RespawnSpecials() {
        if ($this.World.Options.Deathmatch -ne 2) {
            return
        }

        if ($this.ItemQueHead -eq $this.ItemQueTail) {
            return
        }

        if (($this.World.LevelTime - $this.ItemRespawnTime[$this.ItemQueTail]) -lt (30 * 35)) {
            return
        }

        $mthing = $this.ItemRespawnQue[$this.ItemQueTail]
        $x = $mthing.X
        $y = $mthing.Y

        $ss = [Geometry]::PointInSubsector($x, $y, $this.World.Map)
        $mo = $this.SpawnMobj($x, $y, $ss.Sector.FloorHeight, [MobjType]::Ifog)
        $this.World.StartSound($mo, [Sfx]::ITMBK, [SfxType]::Misc)

        $i = 0
        while ($i -lt [DoomInfo]::MobjInfos.Length -and $mthing.Type -ne [DoomInfo]::MobjInfos[$i].DoomEdNum) {
            $i++
        }

        $z = if (([DoomInfo]::MobjInfos[$i].Flags -band [MobjFlags]::SpawnCeiling) -ne 0) {
            [Mobj]::OnCeilingZ
        } else {
            [Mobj]::OnFloorZ
        }

        $mo = $this.SpawnMobj($x, $y, $z, [MobjType]$i)
        $mo.SpawnPoint = $mthing
        $mo.Angle = $mthing.Angle

        $this.ItemQueTail = ($this.ItemQueTail + 1) -band ([ThingAllocation]::ItemQueSize - 1)
    }

    [void] SpawnMapThing([MapThing] $mt) {
        if ($mt.Type -eq 11) {
            if ($this.DeathmatchStarts.Count -lt 10) {
                $this.DeathmatchStarts.Add($mt)
            }
            return
        }

        if ($mt.Type -le 4) {
            $playerNumber = $mt.Type - 1
            if ($playerNumber -lt 0) { return }

            $this.PlayerStarts[$playerNumber] = $mt

            if ($this.World.Options.Deathmatch -eq 0) {
                $this.SpawnPlayer($mt)
            }
            return
        }

        if (-not $this.World.Options.NetGame -and (([int]($mt.Flags -band [ThingFlags]::MultiplayerOnly)) -ne 0)) { return }

        $bit = if ($this.World.Options.Skill -eq [GameSkill]::Baby) { 1 } elseif ($this.World.Options.Skill -eq [GameSkill]::Nightmare) { 4 } else { 1 -shl ($this.World.Options.Skill - 1) }

        if ((([int]$mt.Flags -band $bit) -eq 0)) { return }

        $i = 0
        while ($i -lt [DoomInfo]::MobjInfos.Length -and $mt.Type -ne [DoomInfo]::MobjInfos[$i].DoomEdNum) { $i++ }

        if ($i -eq [DoomInfo]::MobjInfos.Length) { throw "Unknown type!" }

        if ($this.World.Options.Deathmatch -ne 0 -and ([DoomInfo]::MobjInfos[$i].Flags -band [MobjFlags]::NotDeathmatch) -ne 0) { return }

        if ($this.World.Options.NoMonsters -and ($i -eq [MobjType]::Skull -or ([DoomInfo]::MobjInfos[$i].Flags -band [MobjFlags]::CountKill) -ne 0)) { return }

        $x = $mt.X
        $y = $mt.Y
        $z = if ([DoomInfo]::MobjInfos[$i].Flags -band [MobjFlags]::SpawnCeiling) { [Mobj]::OnCeilingZ } else { [Mobj]::OnFloorZ }

        $mobj = $this.SpawnMobj($x, $y, $z, [MobjType]$i)
        $mobj.SpawnPoint = $mt

        if ($mobj.Tics -gt 0) {
            $mobj.Tics = 1 + ($this.World.Random.Next() % $mobj.Tics)
        }

        if ($mobj.Flags -band [MobjFlags]::CountKill) { $this.World.TotalKills++ }
        if ($mobj.Flags -band [MobjFlags]::CountItem) { $this.World.TotalItems++ }

        $mobj.Angle = $mt.Angle
        if (([int]($mt.Flags -band [ThingFlags]::Ambush)) -ne 0) { $mobj.Flags = $mobj.Flags -bor [MobjFlags]::Ambush }
    }

    [void] SpawnPlayer([MapThing] $mt) {
        $players = $this.World.Options.Players
        $playerNumber = $mt.Type - 1

        if (-not $players[$playerNumber].InGame) { return }

        $player = $players[$playerNumber]
        if ($player.PlayerState -eq [PlayerState]::Reborn -or $player.Health -le 0) { $player.Reborn() }

        $x = $mt.X
        $y = $mt.Y
        $z = [Mobj]::OnFloorZ
        $mobj = $this.SpawnMobj($x, $y, $z, [MobjType]::Player)

        if ($playerNumber -eq $this.World.Options.ConsolePlayer) {
            $this.World.StatusBar.Reset()
            $this.World.Options.Sound.SetListener($mobj)
        }

        if ($playerNumber -ge 1) {
            $mobj.Flags = $mobj.Flags -bor ($mt.Type - 1 -shl [MobjFlags]::TransShift)
        }

        $mobj.Angle = $mt.Angle
        $mobj.Player = $player
        $mobj.Health = $player.Health

        $player.Mobj = $mobj
        $player.PlayerState = [PlayerState]::Live
        $player.Refire = 0
        $player.Message = $null
        $player.MessageTime = 0
        $player.DamageCount = 0
        $player.BonusCount = 0
        $player.ExtraLight = 0
        $player.FixedColorMap = 0
        $player.ViewHeight = [Player]::NormalViewHeight

        $this.World.PlayerBehavior.SetupPlayerSprites($player)

        if ($this.World.Options.Deathmatch -ne 0) {
            for ($i = 0; $i -lt [CardType]::Count; $i++) {
                $player.Cards[$i] = $true
            }
        }
    }

    [Mobj] SpawnMobj([Fixed] $x, [Fixed] $y, [Fixed] $z, [MobjType] $type) {
        $mobj = [Mobj]::new($this.World)
        $info = [DoomInfo]::MobjInfos[[int]$type]

        $mobj.Type = $type
        $mobj.Info = $info
        $mobj.X = $x
        $mobj.Y = $y
        $mobj.Radius = $info.Radius
        $mobj.Height = $info.Height
        $mobj.Flags = $info.Flags
        $mobj.Health = $info.SpawnHealth

        if ($this.World.Options.Skill -ne [GameSkill]::Nightmare) {
            $mobj.ReactionTime = $info.ReactionTime
        }

        $mobj.LastLook = $this.World.Random.Next() % [Player]::MaxPlayerCount
        $st = [DoomInfo]::States.all[[int]$info.SpawnState]
        $mobj.State = $st
        $mobj.Tics = $st.Tics
        $mobj.Sprite = $st.Sprite
        $mobj.Frame = $st.Frame

        $this.World.ThingMovement.SetThingPosition($mobj)

        $mobj.FloorZ = $mobj.Subsector.Sector.FloorHeight
        $mobj.CeilingZ = $mobj.Subsector.Sector.CeilingHeight
        $mobj.Z = if ($z -eq [Mobj]::OnFloorZ) { $mobj.FloorZ } elseif ($z -eq [Mobj]::OnCeilingZ) { $mobj.CeilingZ - $mobj.Info.Height } else { $z }
        $global:thinkeradd = $mobj
        $this.World.Thinkers.Add($mobj)
        return $mobj
    }

    [void] CheckMissileSpawn([Mobj] $thing) {
        $thing.Tics -= $this.World.Random.Next() -band 3
        if ($thing.Tics -lt 1) {
            $thing.Tics = 1
        }

        # Managed Doom advances the missile first, then validates that new spot.
        # Using TryMove() from the spawn point changes immediate collision behavior.
        $thing.X += ($thing.MomX -shr 1)
        $thing.Y += ($thing.MomY -shr 1)
        $thing.Z += ($thing.MomZ -shr 1)

        if (-not $this.World.ThingMovement.TryMove($thing, $thing.X, $thing.Y)) {
            $this.World.ThingInteraction.ExplodeMissile($thing)
        }
    }

    [int] GetMissileSpeed([MobjType] $type) {
        if ($this.World.Options.FastMonsters -or $this.World.Options.Skill -eq [GameSkill]::Nightmare) {
            switch ($type) {
                ([MobjType]::Bruisershot) { return 20 * [Fixed]::FracUnit }
                ([MobjType]::Headshot) { return 20 * [Fixed]::FracUnit }
                ([MobjType]::Troopshot) { return 20 * [Fixed]::FracUnit }
                default { return [DoomInfo]::MobjInfos[[int]$type].Speed }
            }
        }

        return [DoomInfo]::MobjInfos[[int]$type].Speed
    }

    [Mobj] SpawnMissile([Mobj] $source, [Mobj] $dest, [MobjType] $type) {
        $dest = $this.World.SubstNullMobj($dest)

        $spawnZ = $source.Z + [Fixed]::FromInt(32)
        $thing = $this.SpawnMobj($source.X, $source.Y, $spawnZ, $type)

        if ($thing.Info.SeeSound -ne 0) {
            $this.World.StartSound($thing, $thing.Info.SeeSound, [SfxType]::Weapon)
        }

        $thing.Target = $source

        $angle = [Geometry]::PointToAngle($source.X, $source.Y, $dest.X, $dest.Y)
        if ([int]($dest.Flags -band [MobjFlags]::Shadow) -ne 0) {
            $angle += [Angle]::new(($this.World.Random.Next() - $this.World.Random.Next()) -shl 20)
        }

        $thing.Angle = $angle

        $speedData = $this.GetMissileSpeed($thing.Type)
        $speed = [Fixed]::new($speedData)
        $thing.MomX = $speed * [Trig]::Cos($angle)
        $thing.MomY = $speed * [Trig]::Sin($angle)

        $dist = [Geometry]::AproxDistance($dest.X - $source.X, $dest.Y - $source.Y)
        [int]$den = ($dist / $speedData).Data
        if ($den -lt 1) {
            $den = 1
        }

        [int]$num = ($dest.Z - $source.Z).Data
        $thing.MomZ = [Fixed]::new([int][math]::Truncate(([double]$num) / ([double]$den)))

        $this.CheckMissileSpawn($thing)
        return $thing
    }

    [Mobj] SpawnPlayerMissile([Mobj] $source, [MobjType] $type) {
        $hitscan = $this.World.Hitscan
        $angle = $source.Angle
        $range = [Fixed]::FromInt(16 * 64)
        $slope = $hitscan.AimLineAttack($source, $angle, $range)

        if ($null -eq $hitscan.LineTarget) {
            $angle += [Angle]::new(1 -shl 26)
            $slope = $hitscan.AimLineAttack($source, $angle, $range)

            if ($null -eq $hitscan.LineTarget) {
                $angle -= [Angle]::new(2 -shl 26)
                $slope = $hitscan.AimLineAttack($source, $angle, $range)

                if ($null -eq $hitscan.LineTarget) {
                    $angle = $source.Angle
                    $slope = [Fixed]::Zero
                }
            }
        }

        $spawnZ = $source.Z + [Fixed]::FromInt(32)
        $thing = $this.SpawnMobj($source.X, $source.Y, $spawnZ, $type)

        if ($thing.Info.SeeSound -ne 0) {
            $this.World.StartSound($thing, $thing.Info.SeeSound, [SfxType]::Weapon)
        }

        $thing.Target = $source
        $thing.Angle = $angle

        $speed = [Fixed]::new($thing.Info.Speed)
        $thing.MomX = $speed * [Trig]::Cos($angle)
        $thing.MomY = $speed * [Trig]::Sin($angle)
        $thing.MomZ = $speed * $slope

        $this.CheckMissileSpawn($thing)
        return $thing
    }

    [void] RemoveMobj([Mobj] $mobj) {
        if ([int]($mobj.Flags -band [MobjFlags]::Special) -ne 0 -and
            [int]($mobj.Flags -band [MobjFlags]::Dropped) -eq 0 -and
            $mobj.Type -ne [MobjType]::Inv -and
            $mobj.Type -ne [MobjType]::Ins) {
            $this.ItemRespawnQue[$this.ItemQueHead] = $mobj.SpawnPoint
            $this.ItemRespawnTime[$this.ItemQueHead] = $this.World.LevelTime
            $this.ItemQueHead = ($this.ItemQueHead + 1) -band ([ThingAllocation]::ItemQueSize - 1)

            if ($this.ItemQueHead -eq $this.ItemQueTail) {
                $this.ItemQueTail = ($this.ItemQueTail + 1) -band ([ThingAllocation]::ItemQueSize - 1)
            }
        }

        $this.World.ThingMovement.UnsetThingPosition($mobj)
        $this.World.StopSound($mobj)
        $this.World.Thinkers.Remove($mobj)
    }
}
