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
        $this.Buffer = [char[]]::new(([Cheat]::List | Measure-Object -Property Code -Maximum).Maximum.Length)
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
        foreach ($cheatInfo in [Cheat]::List) {
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
                    & $cheatInfo.Action.Invoke($this, -join $typed)
                }
            }
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
        if ($player.Cheats -band [CheatFlags]::NoClip) {
            $player.Cheats -= [CheatFlags]::NoClip
            $player.SendMessage([DoomInfo]::Strings.STSTR_NCOFF)
        } else {
            $player.Cheats += [CheatFlags]::NoClip
            $player.SendMessage([DoomInfo]::Strings.STSTR_NCON)
        }
    }

    [void] FullMap() {
        $this.World.AutoMap.ToggleCheat()
    }

    [void] GiveChainsaw() {
        $player = $this.World.ConsolePlayer
        $player.WeaponOwned[[WeaponType]::Chainsaw] = $true
        $player.SendMessage([DoomInfo]::Strings.STSTR_CHOPPERS)
    }

    [void] KillMonsters() {
        $player = $this.World.ConsolePlayer
        $count = 0
        foreach ($thinker in $this.World.Thinkers) {
            if ($thinker -is [Mobj] -and $null -eq $thinker.Player -and ($thinker.Flags -band [MobjFlags]::CountKill -or $thinker.Type -eq [MobjType]::Skull) -and $thinker.Health -gt 0) {
                $this.World.ThingInteraction.DamageMobj($thinker, $null, $player.Mobj, 10000)
                $count++
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