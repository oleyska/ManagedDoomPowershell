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

#Needs [MenuDef]
class HelpScreen : MenuDef {
    [int]$pageCount
    [int]$page

    HelpScreen([DoomMenu]$menu) : base($menu) {
        if ($menu.Options.GameMode -eq [GameMode]::Shareware) {
            $this.pageCount = 2
        } else {
            $this.pageCount = 1
        }
    }

    [void] Open() {
        $this.page = $this.pageCount - 1
    }

    [bool] DoEvent([DoomEvent]$e) {
        if ($e.Type -ne [EventType]::KeyDown) {
            return $true
        }

        if ($e.Key -eq [DoomKey]::Enter -or
            $e.Key -eq [DoomKey]::Space -or
            $e.Key -eq [DoomKey]::LControl -or
            $e.Key -eq [DoomKey]::RControl) {
            $this.page--

            if ($this.page -eq -1) {
                $this.Menu.Close()
            }
            $this.Menu.StartSound([Sfx]::PISTOL)
        }

        if ($e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }
}