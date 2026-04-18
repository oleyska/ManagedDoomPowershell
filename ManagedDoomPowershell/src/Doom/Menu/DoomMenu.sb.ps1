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

class DoomMenu {
    [Doom] $doom
    [SelectableMenu] $main
    [SelectableMenu] $episodeMenu
    [SelectableMenu] $skillMenu
    [SelectableMenu] $optionMenu
    [SelectableMenu] $volume
    [LoadMenu] $load
    [SaveMenu] $save
    [HelpScreen] $help
    [PressAnyKey] $thisIsShareware
    [PressAnyKey] $saveFailed
    [YesNoConfirm] $nightmareConfirm
    [YesNoConfirm] $endGameConfirm
    [QuitConfirm] $quitConfirm
    [MenuDef] $current
    [bool] $active
    [int] $tics
    [int] $selectedEpisode
    [SaveSlots] $saveSlots

    DoomMenu([Doom] $doom) {
        $this.doom = $doom
        $menu = $this
        $doomRef = $doom
        $sound = $doom.Options.Sound
        $music = $doom.Options.Music
        $video = $doom.Options.Video
        $userInput = $doom.Options.UserInput
        $this.thisIsShareware = [PressAnyKey]::new($this, [DoomInfo]::Strings.SWSTRING, $null)
        $this.saveFailed = [PressAnyKey]::new($this, [DoomInfo]::Strings.SAVEDEAD, $null)
        $this.nightmareConfirm = [YesNoConfirm]::new($this, [DoomInfo]::Strings.NIGHTMARE, [System.Action]({ $menu.doom.NewGame([GameSkill]::Nightmare, $menu.selectedEpisode, 1) }.GetNewClosure()))
        $this.endGameConfirm = [YesNoConfirm]::new($this, [DoomInfo]::Strings.ENDGAME, [System.Action]({ $menu.doom.EndGame() }.GetNewClosure()))
        $this.quitConfirm = [QuitConfirm]::new($this, $this.doom)

        $this.skillMenu = [SelectableMenu]::new($this, "M_NEWG", 96, 14, "M_SKILL", 54, 38, 2, 
            [MenuItem[]]@(
                [SimpleMenuItem]::new("M_JKILL", 16, 58, 48, 63, [System.Action]({ $menu.doom.NewGame([GameSkill]::Baby, $menu.selectedEpisode, 1) }.GetNewClosure()), $null),
                [SimpleMenuItem]::new("M_ROUGH", 16, 74, 48, 79, [System.Action]({ $menu.doom.NewGame([GameSkill]::Easy, $menu.selectedEpisode, 1) }.GetNewClosure()), $null),
                [SimpleMenuItem]::new("M_HURT", 16, 90, 48, 95, [System.Action]({ $menu.doom.NewGame([GameSkill]::Medium, $menu.selectedEpisode, 1) }.GetNewClosure()), $null),
                [SimpleMenuItem]::new("M_ULTRA", 16, 106, 48, 111, [System.Action]({ $menu.doom.NewGame([GameSkill]::Hard, $menu.selectedEpisode, 1) }.GetNewClosure()), $null),
                [SimpleMenuItem]::new("M_NMARE", 16, 122, 48, 127, $null, $this.nightmareConfirm)
            )
        )

        if ($doom.Options.GameMode -eq [GameMode]::Retail) {
            $this.episodeMenu = [SelectableMenu]::new($this, "M_EPISOD", 54, 38, 0,
                [MenuItem[]]@(
                    [SimpleMenuItem]::new("M_EPI1", 16, 58, 48, 63, [System.Action]({ $menu.selectedEpisode = 1 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI2", 16, 74, 48, 79, [System.Action]({ $menu.selectedEpisode = 2 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI3", 16, 90, 48, 95, [System.Action]({ $menu.selectedEpisode = 3 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI4", 16, 106, 48, 111, [System.Action]({ $menu.selectedEpisode = 4 }.GetNewClosure()), $this.skillMenu)
                )
            )
        } elseif ($doom.Options.GameMode -eq [GameMode]::Shareware) {
            $this.episodeMenu = [SelectableMenu]::new($this, "M_EPISOD", 54, 38, 0,
                [MenuItem[]]@(
                    [SimpleMenuItem]::new("M_EPI1", 16, 58, 48, 63, [System.Action]({ $menu.selectedEpisode = 1 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI2", 16, 74, 48, 79, $null, $this.thisIsShareware),
                    [SimpleMenuItem]::new("M_EPI3", 16, 90, 48, 95, $null, $this.thisIsShareware)
                )
            )
        } else {
            $this.episodeMenu = [SelectableMenu]::new($this, "M_EPISOD", 54, 38, 0,
                [MenuItem[]]@(
                    [SimpleMenuItem]::new("M_EPI1", 16, 58, 48, 63, [System.Action]({ $menu.selectedEpisode = 1 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI2", 16, 74, 48, 79, [System.Action]({ $menu.selectedEpisode = 2 }.GetNewClosure()), $this.skillMenu),
                    [SimpleMenuItem]::new("M_EPI3", 16, 90, 48, 95, [System.Action]({ $menu.selectedEpisode = 3 }.GetNewClosure()), $this.skillMenu)
                )
            )
        }

        $this.volume = [SelectableMenu]::new($this, "M_SVOL", 60, 38, 0,
            [MenuItem[]]@(
                [SliderMenuItem]::new("M_SFXVOL", 48, 59, 80, 64, ([int]$sound.GetSoundMaxVolume()) + 1, [Func[int]]({ $sound.GetSoundVolume() }.GetNewClosure()), [Action[int]]({ param($vol) $sound.SetSoundVolume($vol) }.GetNewClosure())),
                [SliderMenuItem]::new("M_MUSVOL", 48, 91, 80, 96, ([int]$music.get_MaxVolume()) + 1, [Func[int]]({ $music.get_Volume() }.GetNewClosure()), [Action[int]]({ param($vol) $music.set_Volume($vol) }.GetNewClosure()))
            )
        )

        $this.optionMenu = [SelectableMenu]::new($this, "M_OPTTTL", 108, 15, 0,
            [MenuItem[]]@(
                [SimpleMenuItem]::new("M_ENDGAM", 28, 32, 60, 37, $null, $this.endGameConfirm, [Func[bool]]({ -not ($doomRef.State -eq [DoomState]::Game -and $doomRef.Game.State -ne [GameState]::Level) }.GetNewClosure())),
                [ToggleMenuItem]::new("M_MESSG", 28, 48, 60, 53, "M_MSGON", "M_MSGOFF", 180, [Func[int]]({ if ($video.get_DisplayMessage()) { 0 } else { 1 } }.GetNewClosure()), [Action[int]]({ param($value) $video.set_DisplayMessage(($value -eq 0)) }.GetNewClosure())),
                [SliderMenuItem]::new("M_SCRNSZ", 28, 64, 60, 69, ([int]$video.get_MaxWindowSize()) + 1, [Func[int]]({ $video.get_WindowSize() }.GetNewClosure()), [Action[int]]({ param($size) $video.set_WindowSize($size) }.GetNewClosure())),
                [SliderMenuItem]::new("M_MSENS", 28, 96, 60, 101, ([int]$userInput.get_MaxMouseSensitivity()) + 1, [Func[int]]({ $userInput.get_MouseSensitivity() }.GetNewClosure()), [Action[int]]({ param($ms) $userInput.set_MouseSensitivity($ms) }.GetNewClosure())),
                [SimpleMenuItem]::new("M_SVOL", 28, 128, 60, 133, $null, $this.volume)
            )
        )

        $this.load = [LoadMenu]::new($this, "M_LOADG", 72, 28, 0,
            [TextBoxMenuItem[]]@(
                [TextBoxMenuItem]::new(48, 49, 72, 61),
                [TextBoxMenuItem]::new(48, 65, 72, 77),
                [TextBoxMenuItem]::new(48, 81, 72, 93),
                [TextBoxMenuItem]::new(48, 97, 72, 109),
                [TextBoxMenuItem]::new(48, 113, 72, 125),
                [TextBoxMenuItem]::new(48, 129, 72, 141)
            )
        )

        $this.save = [SaveMenu]::new($this, "M_SAVEG", 72, 28, 0,
            [TextBoxMenuItem[]]@(
                [TextBoxMenuItem]::new(48, 49, 72, 61),
                [TextBoxMenuItem]::new(48, 65, 72, 77),
                [TextBoxMenuItem]::new(48, 81, 72, 93),
                [TextBoxMenuItem]::new(48, 97, 72, 109),
                [TextBoxMenuItem]::new(48, 113, 72, 125),
                [TextBoxMenuItem]::new(48, 129, 72, 141)
            )
        )

        $this.help = [HelpScreen]::new($this)

        if ($doom.Options.GameMode -eq [GameMode]::Commercial) {
            $this.main = [SelectableMenu]::new($this, "M_DOOM", 94, 2, 0,
                [MenuItem[]]@(
                    [SimpleMenuItem]::new("M_NGAME", 65, 67, 97, 72, $null, $this.skillMenu),
                    [SimpleMenuItem]::new("M_OPTION", 65, 83, 97, 88, $null, $this.optionMenu),
                    [SimpleMenuItem]::new("M_LOADG", 65, 99, 97, 104, $null, $this.load),
                    [SimpleMenuItem]::new("M_SAVEG", 65, 115, 97, 120, $null, $this.save, [Func[bool]]({ -not ($doomRef.State -eq [DoomState]::Game -and $doomRef.Game.State -ne [GameState]::Level) }.GetNewClosure())),
                    [SimpleMenuItem]::new("M_QUITG", 65, 131, 97, 136, $null, $this.quitConfirm)
                )
            )
        } else {
            $this.main = [SelectableMenu]::new($this, "M_DOOM", 94, 2, 0,
                [MenuItem[]]@(
                    [SimpleMenuItem]::new("M_NGAME", 65, 59, 97, 64, $null, $this.episodeMenu),
                    [SimpleMenuItem]::new("M_OPTION", 65, 75, 97, 80, $null, $this.optionMenu),
                    [SimpleMenuItem]::new("M_LOADG", 65, 91, 97, 96, $null, $this.load),
                    [SimpleMenuItem]::new("M_SAVEG", 65, 107, 97, 112, $null, $this.save, [Func[bool]]({ -not ($doomRef.State -eq [DoomState]::Game -and $doomRef.Game.State -ne [GameState]::Level) }.GetNewClosure())),
                    [SimpleMenuItem]::new("M_RDTHIS", 65, 123, 97, 128, $null, $this.help),
                    [SimpleMenuItem]::new("M_QUITG", 65, 139, 97, 144, $null, $this.quitConfirm)
                )
            )
        }

        $this.current = $this.main
        $this.active = $false
        $this.tics = 0
        $this.selectedEpisode = 1
        $this.saveSlots = [SaveSlots]::new()
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($this.active) {
            if ($this.current.DoEvent($e)) {
                return $true
            }

            if ($e.Key -eq [DoomKey]::Escape -and $e.Type -eq [EventType]::KeyDown) {
                $this.Close()
            }

            return $true
        } else {
            if ($e.Key -eq [DoomKey]::Escape -and $e.Type -eq [EventType]::KeyDown) {
                $this.SetCurrent($this.main)
                $this.Open()
                $this.StartSound([Sfx]::SWTCHN) 
                return $true }
                if ($e.Type -eq [EventType]::KeyDown -and $this.doom.State -eq [DoomState]::Opening) {
                    if ($e.Key -in @([DoomKey]::Enter, [DoomKey]::Space, [DoomKey]::LControl, [DoomKey]::RControl, [DoomKey]::Escape)) {
                        $this.SetCurrent($this.main)
                        $this.Open()
                        $this.StartSound([Sfx]::SWTCHN)
                        return $true
                    }
                }
        
                return $false
            }
        }
        
        Update() {
            $this.tics++
        
            if ($null -ne $this.current) {
                $this.current.Update()
            }
        
            if ($this.active -and -not $this.doom.Options.NetGame) {
                $this.doom.PauseGame()
            }
        }
        
        SetCurrent([MenuDef] $next) {
            $this.current = $next
            $this.current.Open()
        }
        
        Open() {
            $this.active = $true
        }
        
        Close() {
            $this.active = $false
        
            if (-not $this.doom.Options.NetGame) {
                $this.doom.ResumeGame()
            }
        }
        
        StartSound([Sfx] $sfx) {
            $this.doom.Options.Sound.StartSound($sfx)
        }
        
        NotifySaveFailed() {
            $this.SetCurrent($this.saveFailed)
        }
        
        ShowHelpScreen() {
            $this.SetCurrent($this.help)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
        ShowSaveScreen() {
            $this.SetCurrent($this.save)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
        ShowLoadScreen() {
            $this.SetCurrent($this.load)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
        ShowVolumeControl() {
            $this.SetCurrent($this.volume)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
        QuickSave() {
            if ($this.save.LastSaveSlot -eq -1) {
                $this.ShowSaveScreen()
            } else {
                $desc = $this.saveSlots.Get_Item($this.save.LastSaveSlot)
                $menu = $this
                $confirm = [YesNoConfirm]::new(
                    $this,
                    ([DoomInfo]::Strings.QSPROMPT).Replace("%s", $desc),
                    [System.Action]({ $menu.save.DoSave($menu.save.LastSaveSlot) }.GetNewClosure()))
                $this.SetCurrent($confirm)
                $this.Open()
                $this.StartSound([Sfx]::SWTCHN)
            }
        }
        
        QuickLoad() {
            if ($this.save.LastSaveSlot -eq -1) {
                $pak = [PressAnyKey]::new($this, [DoomInfo]::Strings.QSAVESPOT, $null)
                $this.SetCurrent($pak)
                $this.Open()
                $this.StartSound([Sfx]::SWTCHN)
            } else {
                $desc = $this.saveSlots.Get_Item($this.save.LastSaveSlot)
                $menu = $this
                $confirm = [YesNoConfirm]::new(
                    $this,
                    ([DoomInfo]::Strings.QLPROMPT).Replace("%s", $desc),
                    [System.Action]({ $menu.load.DoLoad($menu.save.LastSaveSlot) }.GetNewClosure()))
                $this.SetCurrent($confirm)
                $this.Open()
                $this.StartSound([Sfx]::SWTCHN)
            }
        }
        
        EndGame() {
            $this.SetCurrent($this.endGameConfirm)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
        Quit() {
            $this.SetCurrent($this.quitConfirm)
            $this.Open()
            $this.StartSound([Sfx]::SWTCHN)
        }
        
    }
        

    class MenuDef {
        [DoomMenu]$menu
    
        MenuDef([DoomMenu]$menu) {
            $this.menu = $menu
        }
    

        [void] Open() {

        }
    
        [void] Update() {

        }
    
        [bool] DoEvent([DoomEvent]$e) {
            throw "DoEvent method must be implemented in derived classes."
        }
    
    }
    #needs MenuDef
class SelectableMenu : MenuDef {
    [string[]] $name
    [int[]] $titleX
    [int[]] $titleY
    [MenuItem[]] $items

    [int] $index
    [MenuItem] $choice

    [TextInput] $textInput

    SelectableMenu([DoomMenu] $menu, [string] $name, [int] $titleX, [int] $titleY, [int] $firstChoice, [MenuItem[]] $items) : base($menu) {
        $this.name = @($name)
        $this.titleX = @($titleX)
        $this.titleY = @($titleY)
        $this.items = $items

        $this.index = $firstChoice
        $this.choice = $items[$this.index]
    }

    SelectableMenu([DoomMenu] $menu, [string] $name1, [int] $titleX1, [int] $titleY1, [string] $name2, [int] $titleX2, [int] $titleY2, [int] $firstChoice, [MenuItem[]] $items) : base($menu) {
        $this.name = @($name1, $name2)
        $this.titleX = @($titleX1, $titleX2)
        $this.titleY = @($titleY1, $titleY2)
        $this.items = $items

        $this.index = $firstChoice
        $this.choice = $items[$this.index]
    }

    [void] Open() {
        $menuItemsEnumerable = $this.items
        if ($null -ne $menuItemsEnumerable) {
            $menuItemsEnumerator = $menuItemsEnumerable.GetEnumerator()
            for (; $menuItemsEnumerator.MoveNext(); ) {
                $item = $menuItemsEnumerator.Current
                if ($item -is [ToggleMenuItem]) {
                    $item.FReset()
                }

                if ($item -is [SliderMenuItem]) {
                    $item.FReset()
                }

            }
        }
    }

    [void] Up() {
        $this.index--
        if ($this.index -lt 0) {
            $this.index = $this.items.Length - 1
        }

        $this.choice = $this.items[$this.index]
    }

    [void] Down() {
        $this.index++
        if ($this.index -ge $this.items.Length) {
            $this.index = 0
        }

        $this.choice = $this.items[$this.index]
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($e.Type -ne [EventType]::KeyDown) {
            return $true
        }

        if ($null -ne $this.textInput) {
            $result = $this.textInput.DoEvent($e)

            if ($this.textInput.State -eq [TextInputState]::Canceled) {
                $this.textInput = $null
            } elseif ($this.textInput.State -eq [TextInputState]::Finished) {
                $this.textInput = $null
            }

            if ($result) {
                return $true
            }
        }

        if ($e.Key -eq [DoomKey]::Up) {
            $this.Up()
            $this.Menu.StartSound([Sfx]::PSTOP)
        }

        if ($e.Key -eq [DoomKey]::Down) {
            $this.Down()
            $this.Menu.StartSound([Sfx]::PSTOP)
        }

        if ($e.Key -eq [DoomKey]::Left) {
            if ($this.choice -is [ToggleMenuItem]) {
                $this.choice.Down()
                $this.Menu.StartSound([Sfx]::PISTOL)
            }

            if ($this.choice -is [SliderMenuItem]) {
                $this.choice.Down()
                $this.Menu.StartSound([Sfx]::STNMOV)
            }
        }

        if ($e.Key -eq [DoomKey]::Right) {
            if ($this.choice -is [ToggleMenuItem]) {
                $this.choice.Up()
                $this.Menu.StartSound([Sfx]::PISTOL)
            }

            if ($this.choice -is [SliderMenuItem]) {
                $this.choice.Up()
                $this.Menu.StartSound([Sfx]::STNMOV)
            }
        }

        if ($e.Key -eq [DoomKey]::Enter) {
            if ($this.choice -is [ToggleMenuItem]) {
                $this.choice.Up()
                $this.Menu.StartSound([Sfx]::PISTOL)
            }

            if ($this.choice -is [SimpleMenuItem]) {
                if ($this.choice.IsSelectable()) {
                    if ($null -ne $this.choice.Action) {
                        $this.choice.Action.Invoke()
                    }

                    if ($null -ne $this.choice.Next) {
                        $this.Menu.SetCurrent($this.choice.Next)
                    } else {
                        $this.Menu.Close()
                    }
                }
                $this.Menu.StartSound([Sfx]::PISTOL)
                return $true
            }

            if ($null -ne $this.choice.Next) {
                $this.Menu.SetCurrent($this.choice.Next)
                $this.Menu.StartSound([Sfx]::PISTOL)
            }
        }

        if ($e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }
}

class YesNoConfirm : MenuDef {
    [string[]]$text
    [System.Action]$action

    YesNoConfirm([DoomMenu]$menu, [string]$text, [System.Action]$action) : base($menu) {
                $this.text = $text.Split("`n")
                $this.action = $action
            }

    [bool] DoEvent([DoomEvent]$e) {
        if ($e.Type -ne [EventType]::KeyDown) {
            return $true
        }

        if ($e.Key -eq [DoomKey]::Y -or 
            $e.Key -eq [DoomKey]::Enter -or 
            $e.Key -eq [DoomKey]::Space) {
            $this.action.Invoke()
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::PISTOL)
        }

        # Check for key press to deny
        if ($e.Key -eq [DoomKey]::N -or 
            $e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }

}
class SimpleMenuItem : MenuItem {
    [string] $name
    [int] $itemX
    [int] $itemY
    [Action] $action
    [Func[bool]] $selectable

    SimpleMenuItem([string] $name, [int] $skullX, [int] $skullY, [int] $itemX, [int] $itemY, [Action] $action, [MenuDef] $next) : base($skullX, $skullY, $next) {
        $this.name = $name
        $this.itemX = $itemX
        $this.itemY = $itemY
        $this.action = $action
        $this.selectable = $null
    }

    SimpleMenuItem([string] $name, [int] $skullX, [int] $skullY, [int] $itemX, [int] $itemY, [Action] $action, [MenuDef] $next, [Func[bool]] $selectable) : base($skullX, $skullY, $next) {
        $this.name = $name
        $this.itemX = $itemX
        $this.itemY = $itemY
        $this.action = $action
        $this.selectable = $selectable
    }

    [bool] IsSelectable() {
        if ($null -eq $this.selectable) {
            return $true
        }

        return $this.selectable.Invoke()
    }

}
