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

# needs [MenuItem]
class ToggleMenuItem : MenuItem {
    [string] $name
    [int] $itemX
    [int] $itemY

    [string[]] $states
    [int] $stateX

    [int] $stateNumber

    [Func[int]] $reset
    [Action[int]] $action

    ToggleMenuItem([string] $name,
                   [int] $skullX, [int] $skullY,
                   [int] $itemX, [int] $itemY,
                   [string] $state1, [string] $state2,
                   [int] $stateX,
                   [Func[int]] $reset,
                   [Action[int]] $action)
        : base($skullX, $skullY, $null) {

        $this.name = $name
        $this.itemX = $itemX
        $this.itemY = $itemY

        $this.states = @($state1, $state2)
        $this.stateX = $stateX

        $this.stateNumber = 0

        $this.action = $action
        $this.reset = $reset
    }

    [void] FReset() {
        if ($null -ne $this.reset) {
            $this.stateNumber = $this.reset.Invoke()
        }
    }

    [string] get_State() {
        return $this.states[$this.stateNumber]
    }

    [void] Up() {
        $this.stateNumber++
        if ($this.stateNumber -eq $this.states.Length) {
            $this.stateNumber = 0
        }

        if ($null -ne $this.action) {
            $this.action.Invoke($this.stateNumber)
        }
    }

    [void] Down() {
        $this.stateNumber--
        if ($this.stateNumber -eq -1) {
            $this.stateNumber = $this.states.Length - 1
        }

        if ($null -ne $this.action) {
            $this.action.Invoke($this.stateNumber)
        }
    }

}
