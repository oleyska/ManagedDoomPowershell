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

class SideDef {
    static [int]$dataSize = 30

    [Fixed]$textureOffset
    [Fixed]$rowOffset
    [int]$topTexture
    [int]$bottomTexture
    [int]$middleTexture
    [Sector]$sector

    SideDef([Fixed]$textureOffset, [Fixed]$rowOffset, [int]$topTexture, [int]$bottomTexture, [int]$middleTexture, [Sector]$sector) {
        $this.textureOffset = $textureOffset
        $this.rowOffset = $rowOffset
        $this.topTexture = $topTexture
        $this.bottomTexture = $bottomTexture
        $this.middleTexture = $middleTexture
        $this.sector = $sector
    }

    static [SideDef] FromData([byte[]]$data, [int]$offset, [ITextureLookup]$textures, [Sector[]]$sectors) {
        $mTextureOffset = [BitConverter]::ToInt16($data, $offset)
        $mRowOffset = [BitConverter]::ToInt16($data, $offset + 2)
        $topTextureName = [DoomInterop]::ToString($data, $offset + 4, 8)
        $bottomTextureName = [DoomInterop]::ToString($data, $offset + 12, 8)
        $middleTextureName = [DoomInterop]::ToString($data, $offset + 20, 8)
        $sectorNum = [BitConverter]::ToInt16($data, $offset + 28)

        return [SideDef]::new(
            [Fixed]::FromInt($mTextureOffset),
            [Fixed]::FromInt($mRowOffset),
            $textures.GetNumber($topTextureName),
            $textures.GetNumber($bottomTextureName),
            $textures.GetNumber($middleTextureName),
            $(if ($sectorNum -ne -1) { $sectors[$sectorNum] } else { $null })
        )
    }

    static [SideDef[]] FromWad([Wad]$wad, [int]$lump, [ITextureLookup]$textures, [Sector[]]$sectors) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [SideDef]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [SideDef]::dataSize
        $sides = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [SideDef]::dataSize * $i
            $sides += [SideDef]::FromData($data, $offset, $textures, $sectors)
        }

        return $sides
    }

}