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

class DoomInterop {
    static [string] ToString([byte[]] $data, [int] $offset, [int] $maxLength) {
        $length = 0
        for ($i = 0; $i -lt $maxLength; $i++) {
            if ($data[$offset + $i] -eq 0) {
                break
            }
            $length++
        }

        $chars = New-Object char[] $length
        for ($i = 0; $i -lt $length; $i++) {
            $c = $data[$offset + $i]
            if ($c -ge 97 -and $c -le 122) { # 'a' <= c <= 'z'
                $c -= 0x20
            }
            $chars[$i] = [char]$c
        }

        return -join $chars
    }
}