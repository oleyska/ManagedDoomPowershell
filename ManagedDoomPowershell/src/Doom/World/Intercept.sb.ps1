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

class Intercept {
    [Fixed] $Frac
    [Mobj] $Thing
    [LineDef] $Line

    Intercept() {
        $this.Frac = [Fixed]::Zero
        $this.Thing = $null
        $this.Line = $null
    }

    [void] Make([Fixed] $frac, [Mobj] $thing) {
        $this.Frac = $frac
        $this.Thing = $thing
        $this.Line = $null
    }

    [void] Make([Fixed] $frac, [LineDef] $line) {
        $this.Frac = $frac
        $this.Thing = $null
        $this.Line = $line
    }

    [Mobj] getThing() { return $this.Thing }
    [LineDef] getLine() { return $this.Line }
}