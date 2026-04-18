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

#needs [ISound]
class NullSound : ISound{
    static [NullSound] $instance
    [int] $volume = 0
    [int] $MaxVolume = 15
    static [NullSound] GetInstance() {
        if ($null -eq [NullSound]::instance) {
            [NullSound]::instance = [NullSound]::new()
        }
        return [NullSound]::instance
    }

    [void] SetListener([Mobj] $listener) { }

    [void] Update() { }

    [void] StartSound([Sfx] $sfx) { }

   [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type) { }

    [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type, [int] $volume) { }

    [void] StopSound([Mobj] $mobj) { }

    [void] Reset() { }

    [void] Pause() { }

    [void] Resume() { }

    [int] GetSoundVolume() {
        return $this.volume
    }

    [void] SetSoundVolume([int] $value) {
        $this.volume = [Math]::Clamp($value, 0, $this.MaxVolume)
    }

    [int] GetSoundMaxVolume() {
        return $this.MaxVolume
    }
}
