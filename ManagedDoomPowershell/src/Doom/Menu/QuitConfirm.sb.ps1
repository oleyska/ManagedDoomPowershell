class QuitConfirm : MenuDef {
    static [Sfx[]] $DoomQuitSoundList = @(
        [Sfx]::PLDETH,
        [Sfx]::DMPAIN,
        [Sfx]::POPAIN,
        [Sfx]::SLOP,
        [Sfx]::TELEPT,
        [Sfx]::POSIT1,
        [Sfx]::POSIT3,
        [Sfx]::SGTATK
    )

    static [Sfx[]] $doom2QuitSoundList = [Sfx[]]@(
        [Sfx]::VILACT,
        [Sfx]::GETPOW,
        [Sfx]::BOSCUB,
        [Sfx]::SLOP,
        [Sfx]::SKESWG,
        [Sfx]::KNTDTH,
        [Sfx]::BSPACT,
        [Sfx]::SGTATK
    )

    [Doom] $app
    [DoomRandom] $random
    [string[]] $text
    [int] $endCount

    QuitConfirm([DoomMenu] $menu, [Doom] $app) : base($menu) {
        $this.app = $app
        $this.random = [DoomRandom]::new([DateTime]::Now.Millisecond)
        $this.endCount = -1
    }

    [void] Open() {
        if ($this.app.Options.GameMode -eq [GameMode]::Commercial) {
            if ($this.app.Options.MissionPack -eq [MissionPack]::Doom2) {
                $list = [DoomInfo]::QuitMessages.Doom2
            } else {
                $list = [DoomInfo]::QuitMessages.FinalDoom
            }
        } else {
            $list = [DoomInfo]::QuitMessages.Doom
        }

        $this.text = (($list[$this.random.Next() % $list.Count]).tostring() + "`n`n" + ([DoomInfo]::Strings.PRESSYN)) #split on \n ?
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($this.endCount -ne -1) {
            return $true
        }

        if ($e.Type -ne [EventType]::KeyDown) {
            return $true
        }

        if ($e.Key -eq [DoomKey]::Y -or $e.Key -eq [DoomKey]::Enter -or $e.Key -eq [DoomKey]::Space) {
            $this.endCount = 0
            $sfx = if ($this.Menu.Options.GameMode -eq [GameMode]::Commercial) {
                [QuitConfirm]::doom2QuitSoundList[$this.random.Next() % [QuitConfirm]::doom2QuitSoundList.Length]
            } else {
                [QuitConfirm]::DoomQuitSoundList[$this.random.Next() % [QuitConfirm]::DoomQuitSoundList.Length]
            }
            $this.Menu.StartSound($sfx)
        }

        if ($e.Key -eq [DoomKey]::N -or $e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }

    [void] Update() {
        if ($this.endCount -ne -1) {
            $this.endCount++
        }

        if ($this.endCount -eq 50) {
            $this.app.Quit()
        }
    }
}