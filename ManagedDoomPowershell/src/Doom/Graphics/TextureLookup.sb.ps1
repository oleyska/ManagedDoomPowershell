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

#needs [ITextureLookup]
class TextureLookup : ITextureLookup {
    [System.Collections.Generic.List[Texture]]$Textures
    [System.Collections.Generic.Dictionary[string,Texture]]$NameToTexture
    [System.Collections.Generic.Dictionary[string,int]]$NameToNumber
    [int[]]$SwitchList

    TextureLookup([Wad]$wad) {
        $this.InitLookup($wad)
        $this.InitSwitchList()
    }

    TextureLookup([Wad]$wad, [bool]$useDummy) {
        $this.InitLookup($wad)
        $this.InitSwitchList()
    }

    [void] InitLookup([Wad]$wad) {
        $this.Textures = [System.Collections.Generic.List[Texture]]::new()
        $this.NameToTexture = [System.Collections.Generic.Dictionary[string,Texture]]::new()
        $this.NameToNumber = [System.Collections.Generic.Dictionary[string,int]]::new()

        $patches = [TextureLookup]::LoadPatches($wad)

        for ($n = 1; $n -le 2; $n++) {
            $lumpNumber = $wad.GetLumpNumber("TEXTURE" + $n)
            if ($lumpNumber -eq -1) {
                break
            }

            $data = $wad.ReadLump($lumpNumber)
            $count = [BitConverter]::ToInt32($data, 0)
            for ($i = 0; $i -lt $count; $i++) {
                $offset = [BitConverter]::ToInt32($data, 4 + 4 * $i)
                $texture = [Texture]::FromData($data, $offset, $patches)
                $this.NameToNumber.TryAdd($texture.Name, $this.Textures.Count) 
                $this.Textures.Add($texture)
                $this.NameToTexture.TryAdd($texture.Name, $texture)
            }
        }
    }

    [void] InitSwitchList() {
        $list = [System.Collections.Generic.List[int]]::new()
        $switchNameTuplesEnumerable = [DoomInfo]::SwitchNames
        if ($null -ne $switchNameTuplesEnumerable) {
            $switchNameTuplesEnumerator = $switchNameTuplesEnumerable.GetEnumerator()
            for (; $switchNameTuplesEnumerator.MoveNext(); ) {
                $tuple = $switchNameTuplesEnumerator.Current
                $texNum1 = $this.GetNumber($tuple[0])
                $texNum2 = $this.GetNumber($tuple[1])
                if ($texNum1 -ne -1 -and $texNum2 -ne -1) {
                    $list.Add($texNum1)
                    $list.Add($texNum2)
                }

            }
        }
        $this.SwitchList = $list.ToArray()
    }

    [int] GetNumber([string]$name) {
        if ($name[0] -eq '-') {
            return 0
        }

        if ($this.NameToNumber.ContainsKey($name)) {
            return $this.NameToNumber[$name]
        } else {
            return -1
        }
    }

    static [Patch[]] LoadPatches([Wad]$wad) {
        $patchNames = [TextureLookup]::LoadPatchNames($wad)
        $patches = [Patch[]]::new($patchNames.Length)

        for ($i = 0; $i -lt $patches.Length; $i++) {
            $name = $patchNames[$i]

            # This check is necessary to avoid crash in DOOM1.WAD.
            if ($wad.GetLumpNumber($name) -eq -1) {
                continue
            }

            $data = $wad.ReadLump($name)
            $patches[$i] = [Patch]::FromData($name, $data)
        }
        return $patches
    }

    static [string[]] LoadPatchNames([Wad]$wad) {
        $data = $wad.ReadLump("PNAMES")
        $count = [BitConverter]::ToInt32($data, 0)
        $names = New-Object string[] $count
        for ($i = 0; $i -lt $names.Length; $i++) {
            $names[$i] = [DoomInterop]::ToString($data, 4 + 8 * $i, 8)
        }
        return $names
    }

    [System.Collections.IEnumerator] GetEnumerator() {
        return $this.Textures.GetEnumerator()
    }

    [int] get_Count() {
        return $this.Textures.Count
    }

    [Texture] get_Item([int]$num) {
        return $this.Textures[$num]
    }

    [Texture] get_Item([string]$name) {
        return $this.NameToTexture[$name]
    }

    [int[]] get_SwitchList() {
        return $this.SwitchList
    }
}
