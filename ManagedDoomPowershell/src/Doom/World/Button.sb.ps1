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

class Button {
    [LineDef] $Line
    [ButtonPosition] $Position
    [int] $Texture
    [int] $Timer
    [Mobj] $SoundOrigin

    Button() {
        $this.Clear()
    }

    [void] Clear() {
        $this.Line = $null
        $this.Position = 0
        $this.Texture = 0
        $this.Timer = 0
        $this.SoundOrigin = $null
    }
}