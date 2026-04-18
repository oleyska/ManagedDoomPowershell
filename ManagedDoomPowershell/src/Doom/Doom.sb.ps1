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

class Doom {
    [CommandLineArgs]$args
    [Config]$config
    [GameContent]$content
    [IVideo]$video
    [ISound]$sound
    [IMusic]$music
    [IUserInput]$userInput

    [System.Collections.Generic.List[DoomEvent]]$events

    [GameOptions]$options
    [DoomMenu]$menu
    [OpeningSequence]$opening
    [DemoPlayback]$demoPlayback
    [TicCmd[]]$cmds
    [DoomGame]$game
    [WipeEffect]$wipeEffect
    [bool]$wiping
    
    [DoomState]$currentState
    [DoomState]$state
    [DoomState]$nextState
    [bool]$needWipe

    [bool]$sendPause
    [bool]$isQuit 
    [string]$quitMessage
    [bool]$mouseGrabbed

    Doom($args, [Config] $config, [GameContent] $content, [IVideo] $video, [ISound] $sound, [IMusic] $music, [IUserInput] $userInput) {
        if ($video) {
            $this.Video = $video
        } else {
            $this.Video = [NullVideo]::GetInstance()
        }
        if ($Sound) {
            $this.Sound = $Sound
        } else {
            $this.Sound = [NullSound]::GetInstance()
        }
        if ($music) {
            $this.music = $music
        } else {
            $this.music = [NullMusic]::GetInstance()
        }
        if ($userInput) {
            $this.userInput = $userInput
        } else {
            $this.userInput = [NullUserInput]::GetInstance()
        }

        $this.Args = [CommandLineArgs]::new($args)
        $this.Config = $config
        $this.Content = $content

        $this.Events = @()

        $this.Options = [GameOptions]::new()
        $this.Options.GameOptionsArgs($args,$content)
        $this.Options.Video = $this.Video
        $this.Options.Sound = $this.Sound
        $this.Options.Music = $this.Music
        $this.Options.UserInput = $this.UserInput

        $this.Menu = [DoomMenu]::new($this)

        $this.Opening = [OpeningSequence]::new($content, $this.Options)

        $this.Cmds = New-Object TicCmd[] ([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.Cmds[$i] = [TicCmd]::new()
        }
        $this.Game = [DoomGame]::new($content, $this.Options)

        $this.WipeEffect = [WipeEffect]::new($this.Video.WipeBandCount(), $this.Video.WipeHeight())
        $this.Wiping = $false

        $this.CurrentState = [DoomState]::None
        $this.State = $this.CurrentState
        $this.NextState = [DoomState]::Opening
        $this.NeedWipe = $false
        $this.SendPause = $false
        $this.isQuit = $false
        $this.QuitMessage = $null
        $this.MouseGrabbed = $false

        $this.CheckGameArgs()
    }

    [void] CheckGameArgs() {
        if ($this.Args.warp.Present) {
            $this.NextState = [DoomState]::Game
            $this.Options.Episode = $this.Args.warp.Value.Item1
            $this.Options.Map = $this.Args.warp.Value.Item2
            $this.Game.DeferedInitNew()
        } elseif ($this.Args.episode.Present) {
            $this.NextState = [DoomState]::Game
            $this.Options.Episode = $this.Args.episode.Value
            $this.Options.Map = 1
            $this.Game.DeferedInitNew()
        }

        if ($this.Args.skill.Present) {
            $this.Options.Skill = [GameSkill]($this.Args.skill.Value - 1)
        }

        if ($this.Args.deathmatch.Present) {
            $this.Options.Deathmatch = 1
        }

        if ($this.Args.altdeath.Present) {
            $this.Options.Deathmatch = 2
        }

        if ($this.Args.fast.Present) {
            $this.Options.FastMonsters = $true
        }

        if ($this.Args.respawn.Present) {
            $this.Options.RespawnMonsters = $true
        }

        if ($this.Args.nomonsters.Present) {
            $this.Options.NoMonsters = $true
        }

        if ($this.Args.loadgame.Present) {
            $this.NextState = [DoomState]::Game
            $this.Game.LoadGame($this.Args.loadgame.Value)
        }

        if ($this.Args.playdemo.Present) {
            $this.NextState = [DoomState]::DemoPlayback
            $this.DemoPlayback = [DemoPlayback]::new($this.Args, $this.Content, $this.Options, $this.Args.playdemo.Value)
        }

        if ($this.Args.timedemo.Present) {
            $this.NextState = [DoomState]::DemoPlayback
            $this.DemoPlayback = [DemoPlayback]::new($this.Args, $this.Content, $this.Options, $this.Args.timedemo.Value)
        }
    }

    [void] NewGame([GameSkill]$skill, [int]$episode, [int]$map) {
        $this.game.DeferedInitNew($skill, $episode, $map)
        $this.nextState = [DoomState]::Game
    }

    [void] EndGame() {
        $this.nextState = [DoomState]::Opening
    }

    [void] DoEvents() {
        if ($this.wiping) {
            return
        }

        $doomEventsEnumerable = $this.events
        if ($null -ne $doomEventsEnumerable) {
            $doomEventsEnumerator = $doomEventsEnumerable.GetEnumerator()
            for (; $doomEventsEnumerator.MoveNext(); ) {
                $e = $doomEventsEnumerator.Current
                if ($this.menu.DoEvent($e)) {
                    continue
                }

                if ($e.Type -eq [EventType]::KeyDown) {
                    if ($this.CheckFunctionKey($e.Key)) {
                        continue
                    }
                }

                if ($this.currentState -eq [DoomState]::Game) {
                    if ($e.Key -eq [DoomKey]::Pause -and $e.Type -eq [EventType]::KeyDown) {
                        $this.sendPause = $true
                        continue
                    }

                    if ($this.game.DoEvent($e)) {
                        continue
                    }
                }
                elseif ($this.currentState -eq [DoomState]::DemoPlayback) {
                    $this.demoPlayback.DoEvent($e)
                }

            }
        }

        $this.events.Clear()
    }


    [bool] CheckFunctionKey([DoomKey]$key) {
        switch ($key) {
            [DoomKey]::F1 {
                $this.menu.ShowHelpScreen()
                return $true
            }

            [DoomKey]::F2 {
                $this.menu.ShowSaveScreen()
                return $true
            }

            [DoomKey]::F3 {
                $this.menu.ShowLoadScreen()
                return $true
            }

            [DoomKey]::F4 {
                $this.menu.ShowVolumeControl()
                return $true
            }

            [DoomKey]::F6 {
                $this.menu.QuickSave()
                return $true
            }

            [DoomKey]::F7 {
                if ($this.currentState -eq [DoomState]::Game) {
                    $this.menu.EndGame()
                } else {
                    $this.options.Sound.StartSound([Sfx]::OOF)
                }
                return $true
            }

            [DoomKey]::F8 {
                $displayMessage = -not $this.video.get_DisplayMessage()
                $this.video.set_DisplayMessage($displayMessage)
                if ($this.currentState -eq [DoomState]::Game -and $this.game.State -eq [GameState]::Level) {
                    $msg = if ($displayMessage) { [DoomInfo]::Strings.MSGON } else { [DoomInfo]::Strings.MSGOFF }
                    $this.game.World.ConsolePlayer.SendMessage($msg)
                }
                $this.menu.StartSound([Sfx]::SWTCHN)
                return $true
            }

            [DoomKey]::F9 {
                $this.menu.QuickLoad()
                return $true
            }

            [DoomKey]::F10 {
                $this.menu.Quit()
                return $true
            }

            [DoomKey]::F11 {
                $gcl = $this.video.get_GammaCorrectionLevel()
                $gcl++
                if ($gcl -gt $this.video.get_MaxGammaCorrectionLevel()) {
                    $gcl = 0
                }
                $this.video.set_GammaCorrectionLevel($gcl)
                if ($this.currentState -eq [DoomState]::Game -and $this.game.State -eq [GameState]::Level) {
                    $msg = if ($gcl -eq 0) { [DoomInfo]::Strings.GAMMALVL0 } else { "Gamma correction level $gcl" }
                    $this.game.World.ConsolePlayer.SendMessage($msg)
                }
                return $true
            }

            { $_ -in ([DoomKey]::Add, [DoomKey]::Quote, [DoomKey]::Equal) } {
                if ($this.currentState -eq [DoomState]::Game -and
                    $this.game.State -eq [GameState]::Level -and
                    $this.game.World.AutoMap.Visible) {
                    return $false
                } else {
                    $windowSize = [math]::Min($this.video.get_WindowSize() + 1, $this.video.get_MaxWindowSize())
                    $this.video.set_WindowSize($windowSize)
                    $this.sound.StartSound([Sfx]::STNMOV)
                    return $true
                }
            }

            { $_ -in ([DoomKey]::Subtract, [DoomKey]::Hyphen, [DoomKey]::Semicolon) } {
                if ($this.currentState -eq [DoomState]::Game -and
                    $this.game.State -eq [GameState]::Level -and
                    $this.game.World.AutoMap.Visible) {
                    return $false
                } else {
                    $windowSize = [math]::Max($this.video.get_WindowSize() - 1, 0)
                    $this.video.set_WindowSize($windowSize)
                    $this.sound.StartSound([Sfx]::STNMOV)
                    return $true
                }
            }

            default {
                return $false
            }
        }
        return $false
    }
    [UpdateResult] Update() {
        $this.DoEvents()

        if (-not $this.wiping) {
            $this.menu.Update()

            if ($this.nextState -ne $this.currentState) {
                if ($this.nextState -ne [DoomState]::Opening) {
                    $this.opening.Reset()
                }

                if ($this.nextState -ne [DoomState]::DemoPlayback) {
                    $this.demoPlayback = $null
                }

                $this.currentState = $this.nextState
                $this.state = $this.currentState
            }

            if ($this.isQuit) {
                return [UpdateResult]::Completed
            }

            if ($this.needWipe) {
                $this.needWipe = $false
                $this.StartWipe()
            }
        }

        if (-not $this.wiping) {
            [DoomState]$localState = [DoomState]$this.currentState
            switch ($localState) {
                ([DoomState]::Opening) {
                    if ($this.opening.Update() -eq [UpdateResult]::NeedWipe) {
                        $this.StartWipe()
                    }
                }

                ([DoomState]::DemoPlayback) {
                    $result = $this.demoPlayback.Update()
                    if ($result -eq [UpdateResult]::NeedWipe) {
                        $this.StartWipe()
                    }
                    elseif ($result -eq [UpdateResult]::Completed) {
                        $this.isQuit("FPS: " + [string]::Format("{0:0.0}", $this.demoPlayback.Fps))
                    }
                }
               

                ([DoomState]::Game) {
                    $this.userInput.BuildTicCmd($this.cmds[$this.options.ConsolePlayer])
                    if ($this.sendPause) {
                        $this.sendPause = $false
                        $this.cmds[$this.options.ConsolePlayer].Buttons = $this.cmds[$this.options.ConsolePlayer].Buttons -bor ([TicCmdButtons]::Special -bor [TicCmdButtons]::Pause)
                    }
                    if ($this.game.Update($this.cmds) -eq [UpdateResult]::NeedWipe) {
                        $this.StartWipe()
                    }
                }


                default {
                    throw "Invalid application state!"
                }
            }
        }

        if ($this.wiping) {
            $wipeResult = $this.wipeEffect.Update()
            if ($wipeResult -eq [UpdateResult]::Completed) {
                $this.wiping = $false
            }
        }

        $this.sound.Update()

        $this.CheckMouseState()

        return [UpdateResult]::None
    }

    [void] CheckMouseState() {
        [bool]$mouseShouldBeGrabbed = $false

        if (-not $this.video.HasFocus()) {
            $mouseShouldBeGrabbed = $false
        }
        elseif ($this.config.video_fullscreen) {
            $mouseShouldBeGrabbed = $true
        }
        else {
            $mouseShouldBeGrabbed = $this.currentState -eq [DoomState]::Game -and -not $this.menu.Active
        }

        if ($this.mouseGrabbed) {
            if (-not $mouseShouldBeGrabbed) {
                $this.userInput.ReleaseMouse()
                $this.mouseGrabbed = $false
            }
        }
        else {
            if ($mouseShouldBeGrabbed) {
                $this.userInput.GrabMouse()
                $this.mouseGrabbed = $true
            }
        }
    }
    [void] StartWipe() {
        $this.video.InitializeWipe()
        $this.wipeEffect.Start()
        $this.wiping = $true
    }

    [void] PauseGame() {
        if ($this.currentState -eq [DoomState]::Game -and
            $this.game.State -eq [GameState]::Level -and
            -not $this.game.Paused -and
            -not $this.sendPause) {
            $this.sendPause = $true
        }
    }

    [void] ResumeGame() {
        if ($this.currentState -eq [DoomState]::Game -and
            $this.game.State -eq [GameState]::Level -and
            $this.game.Paused -and
            -not $this.sendPause) {
            $this.sendPause = $true
        }
    }

    [bool] SaveGame([int]$slotNumber, [string]$description) {
        if ($this.currentState -eq [DoomState]::Game -and $this.game.State -eq [GameState]::Level) {
            $this.game.SaveGame($slotNumber, $description)
            return $true
        } else {
            return $false
        }
    }

    [void] LoadGame([int]$slotNumber) {
        $this.game.LoadGame($slotNumber)
        $this.nextState = [DoomState]::Game
    }

    [void] Quit() {
        $this.isQuit = $true
    }

    [void] Quit([string]$message) {
        $this.isQuit = $true
        $this.quitMessage = $message
    }

    [void] PostEvent([DoomEvent]$e) {
        if ($this.events.Count -lt 64) {
            $this.events.Add($e)
        }
    }

    [DoomState] get_State() {
        return $this.currentState
    }

    [DoomState] getState() {
        return $this.currentState
    }

    [OpeningSequence] get_Opening() {
        return $this.opening
    }

    [OpeningSequence] getOpening() {
        return $this.opening
    }

    [DemoPlayback] get_DemoPlayback() {
        return $this.demoPlayback
    }

    [DemoPlayback] getDemoPlayback() {
        return $this.demoPlayback
    }

    [GameOptions] get_Options() {
        return $this.options
    }

    [GameOptions] getOptions() {
        return $this.options
    }

    [DoomGame] get_Game() {
        return $this.game
    }

    [DoomGame] getGame() {
        return $this.game
    }

    [DoomMenu] get_Menu() {
        return $this.menu
    }

    [DoomMenu] getMenu() {
        return $this.menu
    }

    [WipeEffect] get_WipeEffect() {
        return $this.wipeEffect
    }

    [WipeEffect] getWipeEffect() {
        return $this.wipeEffect
    }

    [bool] get_Wiping() {
        return $this.wiping
    }

    [bool] getWiping() {
        return $this.wiping
    }

    [string] get_QuitMessage() {
        return $this.quitMessage
    }

    [string] getQuitMessage() {
        return $this.quitMessage
    }
}
