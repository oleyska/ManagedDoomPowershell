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

###needs [IMusic]

class NullMusic : IMusic {
    static [NullMusic]$Instance
    [int]$volume
    NullMusic() {
        $this.Volume = 0
    }

    static [NullMusic] GetInstance() {
        if (-not [NullMusic]::Instance) {
            [NullMusic]::Instance = [NullMusic]::new()
        }
        return [NullMusic]::Instance
    }

    [void] StartMusic([Bgm]$bgm, [bool]$loop) {
        # No operation
    }

    static [int] $MaxVolume = 15

    [int] get_MaxVolume() {
        return [NullMusic]::MaxVolume
    }

    [int] get_Volume() {
        return $this.Volume
    }

    [void] set_Volume([int]$value) {
        $this.volume = [Math]::Clamp($value, 0, [NullMusic]::MaxVolume)
    }
}
