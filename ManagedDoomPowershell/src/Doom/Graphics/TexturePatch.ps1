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

class TexturePatch {
    static [int]$DataSize = 10

    [int]$OriginX
    [int]$OriginY
    [Patch]$Patch

    TexturePatch([int]$originX, [int]$originY, [Patch]$patch) {
        $this.OriginX = $originX
        $this.OriginY = $originY
        $this.Patch = $patch
    }

    static [TexturePatch] FromData([byte[]]$data, [int]$offset, [Patch[]]$patches) {
        $moriginX = [BitConverter]::ToInt16($data, $offset)
        $moriginY = [BitConverter]::ToInt16($data, $offset + 2)
        $patchNum = [BitConverter]::ToInt16($data, $offset + 4)

        return [TexturePatch]::new($moriginX, $moriginY, $patches[$patchNum])
    }

    [string] get_Name() {
        return $this.Patch.Name
    }

    [int] get_OriginX() {
        return $this.OriginX
    }

    [int] get_OriginY() {
        return $this.OriginY
    }

    [int] get_Width() {
        return $this.Patch.Width
    }

    [int] get_Height() {
        return $this.Patch.Height
    }

    [Column[][]] get_Columns() {
        return $this.Patch.Columns
    }
}