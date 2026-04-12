class Finale {
    [int]$TextSpeed = 3
    [int]$TextWait = 250

    [GameOptions]$options
    [int]$stage
    [int]$count
    [string]$flat
    [string]$text
    [int]$scrolled
    [bool]$showTheEnd
    [int]$theEndIndex
    [UpdateResult]$updateResult

    [int]$castNumber
    [MobjStateDef]$castState
    [int]$castTics
    [int]$castFrames
    [bool]$castDeath
    [bool]$castOnMelee
    [bool]$castAttacking

    [array]$castorder

    Finale([GameOptions]$options) {
        $this.options = $options
        $this.stage = 0
        $this.count = 0
        $this.scrolled = 0
        $this.showTheEnd = $false
        $this.theEndIndex = 0

        $this.castorder = @(
            [CastInfo]::new("Zombie", [MobjType]::Possessed),
            [CastInfo]::new("Shotgun", [MobjType]::Shotguy),
            [CastInfo]::new("Heavy", [MobjType]::Chainguy),
            [CastInfo]::new("Imp", [MobjType]::Troop),
            [CastInfo]::new("Demon", [MobjType]::Sergeant),
            [CastInfo]::new("Lost Soul", [MobjType]::Skull),
            [CastInfo]::new("Cacodemon", [MobjType]::Head),
            [CastInfo]::new("Hell Knight", [MobjType]::Knight),
            [CastInfo]::new("Baron", [MobjType]::Bruiser),
            [CastInfo]::new("Arachnotron", [MobjType]::Baby),
            [CastInfo]::new("Pain Elemental", [MobjType]::Pain),
            [CastInfo]::new("Revenant", [MobjType]::Undead),
            [CastInfo]::new("Mancubus", [MobjType]::Fatso),
            [CastInfo]::new("Archvile", [MobjType]::Vile),
            [CastInfo]::new("Spider Mastermind", [MobjType]::Spider),
            [CastInfo]::new("Cyberdemon", [MobjType]::Cyborg),
            [CastInfo]::new("Player", [MobjType]::Player)
        )

        # Set flat and text depending on mission pack and game mode
        $this.SetMissionPack()
        $this.SetGameMode()

        $this.castNumber = 0
        $this.castState = [DoomInfo]::States.all[0]
        $this.castTics = 0
        $this.castFrames = 0
        $this.castDeath = $false
        $this.castOnMelee = $false
        $this.castAttacking = $false
    }

    [void]SetMissionPack() {
        switch ($this.options.MissionPack) {
            "Plutonia" {
                $this.flat = "FLOOR4_8"
                $this.text = [DoomInfo]::Strings.P1TEXT
            }
            "Tnt" {
                $this.flat = "SFLR6_1"
                $this.text = [DoomInfo]::Strings.T1TEXT
            }
            default {
                $this.flat = "F_SKY1"
                $this.text = [DoomInfo]::Strings.C1TEXT
            }
        }
    }

    [void]SetGameMode() {
        switch ($this.options.GameMode) {
            "Commercial" {
                $this.flat = "RROCK14"
                $this.text = [DoomInfo]::Strings.C1TEXT
            }
            default {
                $this.flat = "FLOOR4_8"
                $this.text = [DoomInfo]::Strings.E1TEXT
            }
        }
    }

    [UpdateResult]Update() {
        $this.updateResult = [UpdateResult]::None
        if ($this.options.GameMode -eq "Commercial" -and $this.count -gt 50) {
            $this.CheckForSkip()
        }

        $this.count++

        if ($this.stage -eq 2) {
            $this.UpdateCast()
            return $this.updateResult
        }

        if ($this.stage -eq 0 -and $this.count -gt ($this.text.Length * $this.TextSpeed + $this.TextWait)) {
            $this.count = 0
            $this.stage = 1
            $this.updateResult = [UpdateResult]::NeedWipe
            if ($this.options.Episode -eq 3) {
                $this.options.Music.StartMusic([Bgm]::BUNNY, $true)
            }
        }

        if ($this.stage -eq 1 -and $this.options.Episode -eq 3) {
            $this.BunnyScroll()
        }

        return $this.updateResult
    }

    [UpdateResult]CheckForSkip() {
        $i = 0
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($this.options.Players[$i].Cmd.Buttons -ne 0) {
                break
            }
        }

        if ($i -lt [Player]::MaxPlayerCount -and $this.stage -ne 2) {
            if ($this.options.Map -eq 30) {
                $this.StartCast()
            }
            else {
                return [UpdateResult]::Completed
            }
        }
        return [UpdateResult]::None
    }

    [void]BunnyScroll() {
        $this.scrolled = 320 - (($this.count - 230) / 2)
        if ($this.scrolled -gt 320) {
            $this.scrolled = 320
        }
        if ($this.scrolled -lt 0) {
            $this.scrolled = 0
        }

        if ($this.count -lt 1130) {
            return
        }

        $this.showTheEnd = $true

        if ($this.count -lt 1180) {
            $this.theEndIndex = 0
            return
        }

        $tstage = (($this.count - 1180) / 5)
        if ($tstage -gt 6) {
            $tstage = 6
        }
        if ($tstage -gt $this.theEndIndex) {
            $this.StartSound([Sfx]::PISTOL)
            $this.theEndIndex = $tstage
        }
    }

    [void]StartCast() {
        $this.stage = 2
        $this.castNumber = 0
        $this.castState = [DoomInfo]::States.all[0]
        $this.castTics = $this.castState.Tics
        $this.castFrames = 0
        $this.castDeath = $false
        $this.castOnMelee = $false
        $this.castAttacking = $false

        $this.updateResult = [UpdateResult]::NeedWipe
        $this.options.Music.StartMusic([Bgm]::EVIL, $true)
    }

    [void]UpdateCast() {
        if (--$this.castTics -gt 0) {
            return
        }

        if ($this.castState.Tics -eq -1 -or $this.castState.Next -eq [MobjState]::Null) {
            $this.castNumber++
            $this.castDeath = $false
            if ($this.castNumber -eq $this.castorder.Length) {
                $this.castNumber = 0
            }
            if ([DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].SeeSound -ne 0) {
                $this.StartSound([DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].SeeSound)
            }
            $this.castState = [DoomInfo]::States.all[[DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].SeeState]
            $this.castFrames = 0
        }
        else {
            $st = $this.castState.Next
            $this.castState = [DoomInfo]::States.all[$st]
            $this.castFrames++
            $this.PlaySoundForState($st)
        }

        if ($this.castFrames -eq 12) {
            $this.castAttacking = $true
            $this.SwitchStateForAttack()
        }

        if ($this.castAttacking) {
            if ($this.castFrames -eq 24 -or $this.castState -eq [DoomInfo]::States.all[[DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].SeeState]) {
                $this.castAttacking = $false
                $this.castState = [DoomInfo]::States.all[[DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].SeeState]
                $this.castFrames = 0
            }
        }

        $this.castTics = $this.castState.Tics
        if ($this.castTics -eq -1) {
            $this.castTics = 15
        }
    }

    [void]StartSound([Sfx]$sfx) {
        $this.options.Sound.StartSound($sfx)
    }

    [void]PlaySoundForState([MobjState]$st) {
        $sfx = switch ($st) {
            [MobjState]::PlayAtk1 { [Sfx]::DSHTGN }
            [MobjState]::PossAtk2 { [Sfx]::PISTOL }
            [MobjState]::SposAtk2 { [Sfx]::SHOTGN }
            [MobjState]::VileAtk2 { [Sfx]::VILATK }
            default { 0 }
        }
        if ($sfx -ne 0) {
            $this.StartSound($sfx)
        }
    }

    [void]SwitchStateForAttack() {
        if ($this.castOnMelee) {
            $this.castState = [DoomInfo]::States.all[[DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].MeleeState]
        }
        else {
            $this.castState = [DoomInfo]::States.all[[DoomInfo]::MobjInfos[$this.castorder[$this.castNumber].Type].MissileState]
        }
        $this.castOnMelee = -not $this.castOnMelee
    }

    [string]CastName() {
         return $this.castorder[$this.castNumber].Name }
    
}

class CastInfo {
    [string] $Name
    [MobjType] $Type

    CastInfo([string] $name, [MobjType] $type) {
        $this.Name = $name
        $this.Type = $type
    }
}