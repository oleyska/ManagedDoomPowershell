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

#Needs [MenuItem]
class SliderMenuItem : MenuItem {
    [string] $name
    [int] $itemX
    [int] $itemY

    [int] $sliderLength
    [int] $sliderPosition

    [Func[int]] $reset
    [Action[int]] $action

    SliderMenuItem([string] $name, [int] $skullX, [int] $skullY, [int] $itemX, [int] $itemY, [int] $sliderLength, [Func[int]] $reset, [Action[int]] $action) : base($skullX, $skullY, $null) {
        $this.name = $name
        $this.itemX = $itemX
        $this.itemY = $itemY

        $this.sliderLength = $sliderLength
        $this.sliderPosition = 0

        $this.action = $action
        $this.reset = $reset
    }

    [void] FReset() {
        if ($null -ne $this.reset) {
            $this.sliderPosition = $this.reset.Invoke()
        }
    }

    [void] Reset() {
        $this.FReset()
    }

    [int] get_SliderX() {
        return $this.itemX
    }

    [int] get_SliderY() {
        return $this.itemY + 16
    }

    [void] Up() {
        if ($this.sliderPosition -lt $this.SliderLength - 1) {
            $this.sliderPosition++
        }

        if ($null -ne $this.action) {
            $this.action.Invoke($this.sliderPosition)
        }
    }

    [void] Down() {
        if ($this.sliderPosition -gt 0) {
            $this.sliderPosition--
        }

        if ($null -ne $this.action) {
            $this.action.Invoke($this.sliderPosition)
        }
    }
}
