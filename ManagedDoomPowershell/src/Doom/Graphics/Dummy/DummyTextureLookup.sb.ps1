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

class DummyTextureLookup : ITextureLookup {

    [System.Collections.Generic.List[Texture]]$textureList
    [System.Collections.Generic.Dictionary[string, Texture]]$nameToTexture
    [System.Collections.Generic.Dictionary[string, int]]$nameToNumber
    [int[]]$switchList

    DummyTextureLookup([Wad]$wad) {
        $this.InitLookup($wad)
        $this.InitSwitchList()
    }

    [void] InitLookup([Wad]$wad) {
        $this.textureList = New-Object 'System.Collections.Generic.List[Texture]'
        $this.nameToTexture = New-Object 'System.Collections.Generic.Dictionary[string, Texture]'
        $this.nameToNumber = New-Object 'System.Collections.Generic.Dictionary[string, int]'

        for ($n = 1; $n -le 2; $n++) {
            $lumpNumber = $wad.GetLumpNumber("TEXTURE" + $n)
            if ($lumpNumber -eq -1) {
                break
            }

            $data = $wad.ReadLump($lumpNumber)
            $count = [BitConverter]::ToInt32($data, 0)
            for ($i = 0; $i -lt $count; $i++) {
                $offset = [BitConverter]::ToInt32($data, 4 + 4 * $i)
                $name = [Texture]::GetName($data, $offset)
                $height = [Texture]::GetHeight($data, $offset)
                $texture = [DummyData]::GetTexture($height)

                $this.nameToNumber[$name] = $this.textureList.Count
                $this.textureList.Add($texture)
                $this.nameToTexture[$name] = $texture
            }
        }
    }

    [void] InitSwitchList() {
        $list = New-Object 'System.Collections.Generic.List[int]'
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
        $this.switchList = $list.ToArray()
    }

    # Get texture number by name
    [int] GetNumber([string]$name) {
        if ($name[0] -eq '-') {
            return 0
        }

        if ($this.nameToNumber.ContainsKey($name)) {
            return $this.nameToNumber[$name]
        } else {
            return -1
        }
    }


    [System.Collections.Generic.IEnumerator[Texture]] GetEnumerator() {
        return $this.textureList.GetEnumerator()
    }

    [System.Collections.IEnumerator] IEnumerable_GetEnumerator() {
        return $this.textureList.GetEnumerator()
    }

}
