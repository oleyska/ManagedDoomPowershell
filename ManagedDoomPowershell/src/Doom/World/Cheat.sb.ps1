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

class CheatInfo {
    [string] $Code
    [ScriptBlock] $Action
    [bool] $AvailableOnNightmare

    CheatInfo([string] $code, [ScriptBlock] $action, [bool] $availableOnNightmare) {
        $this.Code = $code
        $this.Action = $action
        $this.AvailableOnNightmare = $availableOnNightmare
    }
}

class Cheat {
    static [array] $List = @(
        [CheatInfo]::new("idfa", { param($cheat, $typed) $cheat.FullAmmo() }, $false),
        [CheatInfo]::new("idkfa", { param($cheat, $typed) $cheat.FullAmmoAndKeys() }, $false),
        [CheatInfo]::new("iddqd", { param($cheat, $typed) $cheat.GodMode() }, $false),
        [CheatInfo]::new("idclip", { param($cheat, $typed) $cheat.NoClip() }, $false),
        [CheatInfo]::new("idspispopd", { param($cheat, $typed) $cheat.NoClip() }, $false),
        [CheatInfo]::new("iddt", { param($cheat, $typed) $cheat.FullMap() }, $true),
        [CheatInfo]::new("idbehold", { param($cheat, $typed) $cheat.ShowPowerUpList() }, $false),
        [CheatInfo]::new("idbehold?", { param($cheat, $typed) $cheat.DoPowerUp($typed) }, $false),
        [CheatInfo]::new("idchoppers", { param($cheat, $typed) $cheat.GiveChainsaw() }, $false),
        [CheatInfo]::new("tntem", { param($cheat, $typed) $cheat.KillMonsters() }, $false),
        [CheatInfo]::new("killem", { param($cheat, $typed) $cheat.KillMonsters() }, $false),
        [CheatInfo]::new("fhhall", { param($cheat, $typed) $cheat.KillMonsters() }, $false),
        [CheatInfo]::new("idclev??", { param($cheat, $typed) $cheat.ChangeLevel($typed) }, $true),
        [CheatInfo]::new("idmus??", { param($cheat, $typed) $cheat.ChangeMusic($typed) }, $false)
    )

    [World] $World
    [char[]] $Buffer
    [int] $P

    Cheat([World] $world) {
        $this.World = $world
        $maxCodeLength = 0
        for ($i = 0; $i -lt [Cheat]::List.Length; $i++) {
            if ([Cheat]::List[$i].Code.Length -gt $maxCodeLength) {
                $maxCodeLength = [Cheat]::List[$i].Code.Length
            }
        }
        $this.Buffer = [char[]]::new($maxCodeLength)
        $this.P = 0
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($e.Type -eq [EventType]::KeyDown) {
            $ch = [DoomKeyEx]::GetChar($e.Key)
            if ($ch -ne [char]0) {
                $this.Buffer[$this.P] = $ch
                $this.P = ($this.P + 1) % $this.Buffer.Length
                $this.CheckBuffer()
            }
        }
        return $true
    }

    [void] CheckBuffer() {
        $cheatInfosEnumerable = [Cheat]::List
        if ($null -ne $cheatInfosEnumerable) {
            $cheatInfosEnumerator = $cheatInfosEnumerable.GetEnumerator()
            for (; $cheatInfosEnumerator.MoveNext(); ) {
                $cheatInfo = $cheatInfosEnumerator.Current
                $code = $cheatInfo.Code.ToCharArray()
                $q = $this.P
                $match = $true
                for ($j = 0; $j -lt $code.Length; $j++) {
                    $q--
                    if ($q -lt 0) { $q = $this.Buffer.Length - 1 }
                    if ($this.Buffer[$q] -ne $code[$code.Length - $j - 1] -and $code[$code.Length - $j - 1] -ne '?') {
                        $match = $false
                        break
                    }
                }
                if ($match) {
                    $typed = New-Object char[] $code.Length
                    $k = $code.Length
                    $q = $this.P
                    for ($j = 0; $j -lt $code.Length; $j++) {
                        $k--
                        $q--
                        if ($q -lt 0) { $q = $this.Buffer.Length - 1 }
                        $typed[$k] = $this.Buffer[$q]
                    }
                    if ($this.World.Options.Skill -ne [GameSkill]::Nightmare -or $cheatInfo.AvailableOnNightmare) {
                        $cheatInfo.Action.Invoke($this, -join $typed)
                    }
                }

            }
        }
    }

    [void] GiveWeapons() {
        $player = $this.World.ConsolePlayer
        if ($this.World.Options.GameMode -eq [GameMode]::Commercial) {
            for ($i = 0; $i -lt [int][WeaponType]::Count; $i++) {
                $player.WeaponOwned[$i] = $true
            }
        }
        else {
            for ($i = 0; $i -le [int][WeaponType]::Missile; $i++) {
                $player.WeaponOwned[$i] = $true
            }
            $player.WeaponOwned[[int][WeaponType]::Chainsaw] = $true
            if ($this.World.Options.GameMode -ne [GameMode]::Shareware) {
                $player.WeaponOwned[[int][WeaponType]::Plasma] = $true
                $player.WeaponOwned[[int][WeaponType]::Bfg] = $true
            }
        }

        $player.Backpack = $true
        for ($i = 0; $i -lt [int][AmmoType]::Count; $i++) {
            $player.MaxAmmo[$i] = 2 * [DoomInfo]::AmmoInfos.Max[$i]
            $player.Ammo[$i] = 2 * [DoomInfo]::AmmoInfos.Max[$i]
        }
    }

    [void] FullAmmo() {
        $this.GiveWeapons()
        $player = $this.World.ConsolePlayer
        $player.ArmorType = [DoomInfo]::DeHackEdConst.IdfaArmorClass
        $player.ArmorPoints = [DoomInfo]::DeHackEdConst.IdfaArmor
        $player.SendMessage([DoomInfo]::Strings.STSTR_FAADDED)
    }

    [void] FullAmmoAndKeys() {
        $this.GiveWeapons()
        $player = $this.World.ConsolePlayer
        $player.ArmorType = [DoomInfo]::DeHackEdConst.IdkfaArmorClass
        $player.ArmorPoints = [DoomInfo]::DeHackEdConst.IdkfaArmor
        for ($i = 0; $i -lt [CardType]::Count; $i++) {
            $player.Cards[$i] = $true
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_KFAADDED)
    }

    [void] GodMode() {
        $player = $this.World.ConsolePlayer
        if ($player.Cheats -band [CheatFlags]::GodMode) {
            $player.Cheats -= [CheatFlags]::GodMode
            $player.SendMessage([DoomInfo]::Strings.STSTR_DQDOFF)
        } else {
            $player.Cheats += [CheatFlags]::GodMode
            $player.Health = [Math]::Max([DoomInfo]::DeHackEdConst.GodModeHealth, $player.Health)
            $player.Mobj.Health = $player.Health
            $player.SendMessage([DoomInfo]::Strings.STSTR_DQDON)
        }
    }

    [void] NoClip() {
        $player = $this.World.ConsolePlayer
        if (($player.Cheats -band [CheatFlags]::NoClip) -ne 0) {
            $player.Cheats = [CheatFlags]([int]$player.Cheats -band (-bnot [int][CheatFlags]::NoClip))
            $player.Mobj.Flags = [MobjFlags]([int]$player.Mobj.Flags -band (-bnot [int][MobjFlags]::NoClip))
            $player.SendMessage([DoomInfo]::Strings.STSTR_NCOFF)
        } else {
            $player.Cheats = [CheatFlags]([int]$player.Cheats -bor [int][CheatFlags]::NoClip)
            $player.Mobj.Flags = [MobjFlags]([int]$player.Mobj.Flags -bor [int][MobjFlags]::NoClip)
            $player.SendMessage([DoomInfo]::Strings.STSTR_NCON)
        }
    }

    [void] FullMap() {
        $this.World.AutoMap.ToggleCheat()
    }

    [void] ShowPowerUpList() {
        $player = $this.World.ConsolePlayer
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLD)
    }

    [void] DoPowerUp([string] $typed) {
        $last = $typed[$typed.Length - 1]
        if ($last -eq [char]'v') {
            $this.ToggleInvulnerability()
        }
        elseif ($last -eq [char]'s') {
            $this.ToggleStrength()
        }
        elseif ($last -eq [char]'i') {
            $this.ToggleInvisibility()
        }
        elseif ($last -eq [char]'r') {
            $this.ToggleIronFeet()
        }
        elseif ($last -eq [char]'a') {
            $this.ToggleAllMap()
        }
        elseif ($last -eq [char]'l') {
            $this.ToggleInfrared()
        }
    }

    [void] ToggleInvulnerability() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::Invulnerability] -gt 0) {
            $player.Powers[[int][PowerType]::Invulnerability] = 0
        }
        else {
            $player.Powers[[int][PowerType]::Invulnerability] = [DoomInfo]::PowerDuration.Invulnerability
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] ToggleStrength() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::Strength] -ne 0) {
            $player.Powers[[int][PowerType]::Strength] = 0
        }
        else {
            $player.Powers[[int][PowerType]::Strength] = 1
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] ToggleInvisibility() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::Invisibility] -gt 0) {
            $player.Powers[[int][PowerType]::Invisibility] = 0
            $player.Mobj.Flags = [MobjFlags]([int]$player.Mobj.Flags -band (-bnot [int][MobjFlags]::Shadow))
        }
        else {
            $player.Powers[[int][PowerType]::Invisibility] = [DoomInfo]::PowerDuration.Invisibility
            $player.Mobj.Flags = [MobjFlags]([int]$player.Mobj.Flags -bor [int][MobjFlags]::Shadow)
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] ToggleIronFeet() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::IronFeet] -gt 0) {
            $player.Powers[[int][PowerType]::IronFeet] = 0
        }
        else {
            $player.Powers[[int][PowerType]::IronFeet] = [DoomInfo]::PowerDuration.IronFeet
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] ToggleAllMap() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::AllMap] -ne 0) {
            $player.Powers[[int][PowerType]::AllMap] = 0
        }
        else {
            $player.Powers[[int][PowerType]::AllMap] = 1
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] ToggleInfrared() {
        $player = $this.World.ConsolePlayer
        if ($player.Powers[[int][PowerType]::Infrared] -gt 0) {
            $player.Powers[[int][PowerType]::Infrared] = 0
        }
        else {
            $player.Powers[[int][PowerType]::Infrared] = [DoomInfo]::PowerDuration.Infrared
        }
        $player.SendMessage([DoomInfo]::Strings.STSTR_BEHOLDX)
    }

    [void] GiveChainsaw() {
        $player = $this.World.ConsolePlayer
        $player.WeaponOwned[[WeaponType]::Chainsaw] = $true
        $player.SendMessage([DoomInfo]::Strings.STSTR_CHOPPERS)
    }

    [void] KillMonsters() {
        $player = $this.World.ConsolePlayer
        $count = 0
        $monsterThinkersEnumerable = $this.World.Thinkers
        if ($null -ne $monsterThinkersEnumerable) {
            $monsterThinkersEnumerator = $monsterThinkersEnumerable.GetEnumerator()
            for (; $monsterThinkersEnumerator.MoveNext(); ) {
                $thinker = $monsterThinkersEnumerator.Current
                if ($thinker -is [Mobj] -and $null -eq $thinker.Player -and ($thinker.Flags -band [MobjFlags]::CountKill -or $thinker.Type -eq [MobjType]::Skull) -and $thinker.Health -gt 0) {
                    $this.World.ThingInteraction.DamageMobj($thinker, $null, $player.Mobj, 10000)
                    $count++
                }

            }
        }
        $player.SendMessage("$count monsters killed")
    }

    [void] ChangeLevel([string] $typed) {
        if ($this.World.Options.GameMode -eq [GameMode]::Commercial) {
            [int]$map = 0
            if (-not [int]::TryParse($typed.Substring($typed.Length - 2, 2), [ref]$map)) {
                return
            }

            $skill = $this.World.Options.Skill
            $this.World.Game.DeferedInitNew($skill, 1, $map)
        }
        else {
            [int]$episode = 0
            if (-not [int]::TryParse($typed.Substring($typed.Length - 2, 1), [ref]$episode)) {
                return
            }

            [int]$map = 0
            if (-not [int]::TryParse($typed.Substring($typed.Length - 1, 1), [ref]$map)) {
                return
            }

            $skill = $this.World.Options.Skill
            $this.World.Game.DeferedInitNew($skill, $episode, $map)
        }
    }

    [void] ChangeMusic([string] $typed) {
        $options = [gameoptions]::new()
        $options.GameMode = $this.World.Options.GameMode
         if ($this.World.Options.GameMode -eq [GameMode]::Commercial) {
        [int]$map = 0
        if (-not [int]::TryParse($typed.Substring($typed.Length - 2, 2), [ref]$map)) {
            return
        }
        $options.Map = $map
    }
    else {
        [int]$episode = 0
        if (-not [int]::TryParse($typed.Substring($typed.Length - 2, 1), [ref]$episode)) {
            return
        }

        [int]$map = 0
        if (-not [int]::TryParse($typed.Substring($typed.Length - 1, 1), [ref]$map)) {
            return
        }

        $options.Episode = $episode
        $options.Map = $map
    }

    $this.World.Options.Music.StartMusic([Map]::GetMapBgm($options), $true)
    $this.World.ConsolePlayer.SendMessage([DoomInfo]::Strings.STSTR_MUS)
    }
}
