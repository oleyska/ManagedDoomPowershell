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

class ColorMap {
    static [int]$Inverse = 32
    [byte[][]]$Data

    ColorMap([wad]$wad) {
        try {
            [Console]::Write("Load color map: ")

            $raw = $wad.ReadLump("COLORMAP")
            $num = $raw.Length / 256
            $this.Data = New-Object 'byte[][]' $num

            for ($i = 0; $i -lt $num; $i++) {
                $this.Data[$i] = New-Object 'byte[]' 256
                $offset = 256 * $i
                for ($c = 0; $c -lt 256; $c++) {
                    $this.Data[$i][$c] = $raw[$offset + $c]
                }
            }

            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }

    [byte[]] get_Item([int]$index) {
        return $this.Data[$index]
    }

    [byte[]] get_FullBright() {
        return $this.Data[0]
    }
}