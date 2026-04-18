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

class Box {
    static [int] $Top = 0
    static [int] $Bottom = 1
    static [int] $Left = 2
    static [int] $Right = 3

    static [void] Clear([ref]$box) {
        $box.Value[[Box]::Top] = $box.Value[[Box]::Right] = [Fixed]::MinValue
        $box.Value[[Box]::Bottom] = $box.Value[[Box]::Left] = [Fixed]::MaxValue
    }

    static [void] AddPoint([ref]$box, [Fixed]$x, [Fixed]$y) {
        if ($x.ToFloat() -lt ($box.Value[[Box]::Left]).ToFloat()) {
            $box.Value[[Box]::Left] = $x
        } elseif ($x.ToFloat() -gt (($box.Value[[Box]::Right])).ToFloat()) {
            $box.Value[[Box]::Right] = $x
        }

        if ($y.ToFloat() -lt ($box.Value[[Box]::Bottom]).ToFloat()) {
            $box.Value[[Box]::Bottom] = $y
        } elseif ($y.ToFloat() -gt ($box.Value[[Box]::Top]).ToFloat()) {
            $box.Value[[Box]::Top] = $y
        }
    }
}