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

class KeyBinding {

    static [KeyBinding] $Empty = [KeyBinding]::new()
    hidden [DoomKey[]] $keys
    hidden [DoomMouseButton[]] $mouseButtons


    hidden KeyBinding() {
        $this.keys = @()
        $this.mouseButtons = @()
    }

    KeyBinding([DoomKey[]] $keys) {
        $this.keys = $keys
        $this.mouseButtons = @()
    }

    KeyBinding(
        [DoomKey[]] $keys,
        [DoomMouseButton[]] $mouseButtons
    ) {
        $this.keys = $keys
        $this.mouseButtons = $mouseButtons
    }

    [string] ToString() {
        $values = [System.Collections.Generic.List[string]]::new()
        for ($keyIndex = 0; $keyIndex -lt $this.keys.Count; $keyIndex++) {
            $values.Add([DoomKeyEx]::ToString($this.keys[$keyIndex]))
        }

        for ($mouseButtonIndex = 0; $mouseButtonIndex -lt $this.mouseButtons.Count; $mouseButtonIndex++) {
            $values.Add([DoomMouseButtonEx]::ToString($this.mouseButtons[$mouseButtonIndex]))
        }

        if ($values.Count -gt 0) {
            return [string]::Join(", ", $values.ToArray())
        }
        else {
            return "none"
        }
    }

    static [KeyBinding] Parse([string] $value) {
        if ($value -eq "none") {
            return [KeyBinding]::Empty
        }


        $tKeys = @()
        $tMouseButtons = @()

        $split = $value.Split(',')
        for ($splitIndex = 0; $splitIndex -lt $split.Count; $splitIndex++) {
            $s = $split[$splitIndex].Trim()
            $key = [DoomKeyEx]::Parse($s)
            if ($key -ne [DoomKey]::Unknown) {
                $tKeys += $key  
                continue
            }

            $mouse = [DoomMouseButtonEx]::Parse($s)
            if ($mouse -ne [DoomMouseButton]::Unknown) {
                $tMouseButtons += $mouse  
            }
        }

        return [KeyBinding]::new(
            $tKeys,
            $tMouseButtons
        )
    }

    [DoomKey[]] get_Keys() {
        return $this.keys
    }

    [DoomMouseButton[]] get_MouseButtons() {
        return $this.mouseButtons
    }
}
