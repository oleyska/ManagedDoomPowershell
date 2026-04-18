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

class TicCmd {

    hidden [System.SByte] $forwardMove
    hidden [System.SByte] $sideMove
    hidden [System.Int16] $angleTurn
    hidden [System.Byte]  $buttons

    TicCmd() {
    }

    [void] Clear() {
        $this.forwardMove = 0
        $this.sideMove    = 0
        $this.angleTurn   = 0
        $this.buttons     = 0
    }

    [void] CopyFrom([TicCmd] $cmd) {
        $this.forwardMove = $cmd.ForwardMove
        $this.sideMove    = $cmd.SideMove
        $this.angleTurn   = $cmd.AngleTurn
        $this.buttons     = $cmd.Buttons
    }

    [System.SByte] get_ForwardMove() {
        return $this.forwardMove
    }
    [void] set_ForwardMove([System.SByte] $value) {
        $this.forwardMove = $value
    }

    [System.SByte] get_SideMove() {
        return $this.sideMove
    }
    [void] set_SideMove([System.SByte] $value) {
        $this.sideMove = $value
    }

    [System.Int16] get_AngleTurn() {
        return $this.angleTurn
    }
    [void] set_AngleTurn([System.Int16] $value) {
        $this.angleTurn = $value
    }

    [System.Byte] get_Buttons() {
        return $this.buttons
    }
    [void] set_Buttons([System.Byte] $value) {
        $this.buttons = $value
    }
}