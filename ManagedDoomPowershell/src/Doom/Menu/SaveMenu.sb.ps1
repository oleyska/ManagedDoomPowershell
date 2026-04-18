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

class SaveMenu : MenuDef {
    [string[]] $name
    [int[]] $titleX
    [int[]] $titleY
    [TextBoxMenuItem[]] $items

    [int] $index
    [TextBoxMenuItem] $choice

    [TextInput] $textInput

    [int] $lastSaveSlot

    SaveMenu([DoomMenu] $menu, [string] $name, [int] $titleX, [int] $titleY, [int] $firstChoice, [TextBoxMenuItem[]] $items) : base($menu) {
        $this.name = @($name)
        $this.titleX = @($titleX)
        $this.titleY = @($titleY)
        $this.items = $items

        $this.index = $firstChoice
        $this.choice = $items[$this.index]

        $this.lastSaveSlot = -1
    }

    [void] Open() {
        if ($this.Menu.Doom.State -ne [DoomState]::Game -or $this.Menu.Doom.Game.State -ne [GameState]::Level) {
            $this.Menu.NotifySaveFailed()
            return
        }

        for ($i = 0; $i -lt $this.items.Length; $i++) {
            $this.items[$i].SetText($this.Menu.SaveSlots.Get_Item($i))
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

        if ($e.Key -eq [DoomKey]::Enter) {
            $saveMenu = $this
            $slotNumber = $this.index
            $this.textInput = $this.choice.Edit({ $saveMenu.DoSave($slotNumber) }.GetNewClosure())
            $this.Menu.StartSound([Sfx]::PISTOL)
        }

        if ($e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }

    [void] DoSave([int] $slotNumber) {
        $description = -join $this.items[$slotNumber].Text
        $this.Menu.SaveSlots.Set_Item($slotNumber, $description)
        if ($this.Menu.Doom.SaveGame($slotNumber, $description)) {
            $this.Menu.Close()
            $this.lastSaveSlot = $slotNumber
        } else {
            $this.Menu.NotifySaveFailed()
        }
        $this.Menu.StartSound([Sfx]::PISTOL)
    }

}
