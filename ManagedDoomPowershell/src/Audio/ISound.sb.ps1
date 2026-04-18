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

class ISound {
    [void] SetListener([Mobj]$listener) { throw "Not implemented" }
    [void] Update() { throw "Not implemented" }
    [void] StartSound([sfx]$sfx) { throw "Not implemented" }
    [void] StartSound([Mobj]$mobj, [sfx]$sfx, [SfxType]$type) { throw "Not implemented" }
    [void] StartSound([Mobj]$mobj, [sfx]$sfx, [SfxType]$type, [int]$volume) { throw "Not implemented" }
    [void] StopSound([Mobj]$mobj) { throw "Not implemented" }
    [void] Reset() { throw "Not implemented" }
    [void] Pause() { throw "Not implemented" }
    [void] Resume() { throw "Not implemented" }

   hidden [int] $volume = 0
   hidden [int] $MaxVolume = 15
}