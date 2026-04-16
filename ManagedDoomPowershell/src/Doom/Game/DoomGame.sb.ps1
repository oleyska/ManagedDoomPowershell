class DoomGame {
    [GameContent] $content
    [GameOptions] $options
    [GameAction] $gameAction = [GameAction]::Nothing
    [GameState] $gameState
    [GameState] $State
    [int] $gameTic = 0
    [World] $world
    [Intermission] $intermission
    [Finale] $finale
    [bool] $paused = $false
    [int] $loadGameSlotNumber
    [int] $saveGameSlotNumber
    [string] $saveGameDescription

    DoomGame([GameContent] $content, [GameOptions] $options) {
        $this.content = $content
        $this.options = $options
        $this.gameAction = [GameAction]::Nothing
        $this.gameState = [GameState]::Level
        $this.State = $this.gameState
        $this.gameTic = 0
    }

    [void] DeferedInitNew() {
        $this.gameAction = [GameAction]::NewGame
    }

    [void] DeferedInitNew([GameSkill] $skill, [int] $episode, [int] $map) {
        $this.options.Skill = $skill
        $this.options.Episode = $episode
        $this.options.Map = $map
        $this.gameAction = [GameAction]::NewGame
    }

    [void] LoadGame([int] $slotNumber) {
        $this.loadGameSlotNumber = $slotNumber
        $this.gameAction = [GameAction]::LoadGame
    }

    [void] SaveGame([int] $slotNumber, [string] $description) {
        $this.saveGameSlotNumber = $slotNumber
        $this.saveGameDescription = $description
        $this.gameAction = [GameAction]::SaveGame
    }

    [UpdateResult] Update([TicCmd[]] $cmds) {
        $players = $this.options.Players
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame -and $players[$i].PlayerState -eq [PlayerState]::Reborn) {
                $this.DoReborn($i)
            }
        }

        while ($this.gameAction -ne [GameAction]::Nothing) {
            switch ($this.gameAction) {
                ([GameAction]::LoadLevel) { $this.DoLoadLevel() }
                ([GameAction]::NewGame) { $this.DoNewGame() }
                ([GameAction]::LoadGame) { $this.DoLoadGame() }
                ([GameAction]::SaveGame) { $this.DoSaveGame() }
                ([GameAction]::Completed) { $this.DoCompleted() }
                ([GameAction]::Victory) { $this.DoFinale() }
                ([GameAction]::WorldDone) { $this.DoWorldDone() }
            }
        }

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame) {
                $players[$i].Cmd.CopyFrom($cmds[$i])
            }
        }

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame -and (($players[$i].Cmd.Buttons -band [TicCmdButtons]::Special) -ne 0)) {
                if (($players[$i].Cmd.Buttons -band [TicCmdButtons]::SpecialMask) -eq [TicCmdButtons]::Pause) {
                    $this.paused = -not $this.paused
                    if ($this.paused) {
                        $this.options.Sound.Pause()
                    }
                    else {
                        $this.options.Sound.Resume()
                    }
                }
            }
        }

        $updateResult = [UpdateResult]::None

        switch ($this.gameState) {
            ([GameState]::Level) {
                if (-not $this.paused -or -not $this.world.DoneFirstTic) {
                    $updateResult = $this.world.Update()
                    if ($updateResult -eq [UpdateResult]::Completed) {
                        $this.gameAction = [GameAction]::Completed
                        $updateResult = [UpdateResult]::None
                    }
                }
            }

            ([GameState]::Intermission) {
                $updateResult = $this.intermission.Update()
                if ($updateResult -eq [UpdateResult]::Completed) {
                    if ($this.options.GameMode -eq [GameMode]::Commercial -and $this.options.Map -eq 30) {
                        $this.gameAction = [GameAction]::Victory
                    }
                    else {
                        $this.gameAction = [GameAction]::WorldDone
                    }
                    $updateResult = [UpdateResult]::None
                }
            }

            ([GameState]::Finale) {
                $updateResult = $this.finale.Update()
            }
        }

        while ($this.gameAction -ne [GameAction]::Nothing) {
            switch ($this.gameAction) {
                ([GameAction]::LoadLevel) { $this.DoLoadLevel() }
                ([GameAction]::NewGame) { $this.DoNewGame() }
                ([GameAction]::LoadGame) { $this.DoLoadGame() }
                ([GameAction]::SaveGame) { $this.DoSaveGame() }
                ([GameAction]::Completed) { $this.DoCompleted() }
                ([GameAction]::Victory) { $this.DoFinale() }
                ([GameAction]::WorldDone) { $this.DoWorldDone() }
            }
        }

        $this.gameTic++
        return $updateResult
    }

    [void] DoLoadLevel() {
        $this.gameAction = [GameAction]::Nothing
        $this.gameState = [GameState]::Level
        $this.State = $this.gameState

        $optionsPlayersEnumerable = $this.options.Players
        if ($null -ne $optionsPlayersEnumerable) {
            $optionsPlayersEnumerator = $optionsPlayersEnumerable.GetEnumerator()
            for (; $optionsPlayersEnumerator.MoveNext(); ) {
                $player = $optionsPlayersEnumerator.Current
                if ($player.InGame -and $player.PlayerState -eq [PlayerState]::Dead) {
                    $player.PlayerState = [PlayerState]::Reborn
                }

            }
        }

        $this.intermission = $null
        $this.options.Sound.Reset()
        $this.world = [World]::new($this.content, $this.options, $this)
        $this.options.UserInput.Reset()
    }

    [void] DoNewGame() {
        $this.gameAction = [GameAction]::Nothing
        $this.InitNew($this.options.Skill, $this.options.Episode, $this.options.Map)
    }

    [void] DoLoadGame() {
        $this.gameAction = [GameAction]::Nothing
        $path = [System.IO.Path]::Combine([ConfigUtilities]::GetExeDirectory(), "doomsav$($this.loadGameSlotNumber).dsg")
        [SaveAndLoad]::Load($this, $path)
    }

    [void] DoSaveGame() {
        $this.gameAction = [GameAction]::Nothing
        $path = [System.IO.Path]::Combine([ConfigUtilities]::GetExeDirectory(), "doomsav$($this.saveGameSlotNumber).dsg")
        [SaveAndLoad]::Save($this, $this.saveGameDescription, $path)
        $this.world.ConsolePlayer.SendMessage([DoomInfo]::Strings.GGSAVED)
    }

    [void] DoCompleted() {
        $this.gameAction = [GameAction]::Nothing
        $optionsPlayersEnumerable = $this.options.Players
        if ($null -ne $optionsPlayersEnumerable) {
            $optionsPlayersEnumerator = $optionsPlayersEnumerable.GetEnumerator()
            for (; $optionsPlayersEnumerator.MoveNext(); ) {
                $player = $optionsPlayersEnumerator.Current
                if ($player.InGame) {
                    $player.FinishLevel()
                }

            }
        }
        $this.gameState = [GameState]::Intermission
        $this.State = $this.gameState
        $this.intermission = [Intermission]::new($this.options, $this.options.IntermissionInfo)
    }

    [void] DoWorldDone() {
        $this.gameAction = [GameAction]::Nothing
        $this.gameState = [GameState]::Level
        $this.State = $this.gameState
        $this.options.Map = $this.options.IntermissionInfo.NextLevel + 1
        $this.DoLoadLevel()
    }

    [void] DoFinale() {
        $this.gameAction = [GameAction]::Nothing
        $this.gameState = [GameState]::Finale
        $this.State = $this.gameState
        $this.finale = [Finale]::new($this.options)
    }

    [void] InitNew([GameSkill] $skill, [int] $episode, [int] $map) {
        $this.options.Skill = [math]::Clamp([int]$skill, [int][GameSkill]::Baby, [int][GameSkill]::Nightmare)
        $this.options.Episode = [math]::Clamp($episode, 1, 4)
        $this.options.Map = [math]::Clamp($map, 1, 32)
        $this.options.Random.Clear()

        $optionsPlayersEnumerable = $this.options.Players
        if ($null -ne $optionsPlayersEnumerable) {
            $optionsPlayersEnumerator = $optionsPlayersEnumerable.GetEnumerator()
            for (; $optionsPlayersEnumerator.MoveNext(); ) {
                $player = $optionsPlayersEnumerator.Current
                $player.PlayerState = [PlayerState]::Reborn

            }
        }

        $this.DoLoadLevel()
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($this.gameState -eq [GameState]::Level) {
            return $this.world.DoEvent($e)
        } elseif ($this.gameState -eq [GameState]::Finale) {
            return $this.finale.DoEvent($e)
        }
        return $false
    }

    [void] DoReborn([int] $playerNumber) {
        if (-not $this.options.NetGame) {
            $this.gameAction = [GameAction]::LoadLevel
        } else {
            $this.options.Players[$playerNumber].Mobj.Player = $null
            $ta = $this.world.ThingAllocation

            if ($this.options.Deathmatch -ne 0) {
                $ta.DeathMatchSpawnPlayer($playerNumber)
                return
            }

            if ($ta.CheckSpot($playerNumber, $ta.PlayerStarts[$playerNumber])) {
                $ta.SpawnPlayer($ta.PlayerStarts[$playerNumber])
                return
            }

            for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                if ($ta.CheckSpot($playerNumber, $ta.PlayerStarts[$i])) {
                    $ta.PlayerStarts[$i].Type = $playerNumber + 1
                    $this.world.ThingAllocation.SpawnPlayer($ta.PlayerStarts[$i])
                    $ta.PlayerStarts[$i].Type = $i + 1
                    return
                }
            }

            $this.world.ThingAllocation.SpawnPlayer($ta.PlayerStarts[$playerNumber])
        }
    }

    [GameOptions] get_Options() { return $this.options }
    [GameState] get_State() { return $this.gameState }
    [int] get_GameTic() { return $this.gameTic }
    [World] get_World() { return $this.world }
    [Intermission] get_Intermission() { return $this.intermission }
    [Finale] get_Finale() { return $this.finale }
    [bool] get_Paused() { return $this.paused }
}

enum GameAction
{
    Nothing
    LoadLevel
    NewGame
    LoadGame
    SaveGame
    Completed
    Victory
    WorldDone
}
