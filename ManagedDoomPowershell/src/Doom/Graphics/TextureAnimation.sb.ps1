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

class TextureAnimation {
    [TextureAnimationInfo[]]$Animations

    TextureAnimation([ITextureLookup]$textures, [IFlatLookup]$flats) {
        try {
            [Console]::Write("Load texture animation info: ")

            #$list = @()
            $list = [System.Collections.Generic.List[TextureAnimationInfo]]::new()

            $textureAnimationDefinitionsEnumerable = [DoomInfo]::TextureAnimation
            if ($null -ne $textureAnimationDefinitionsEnumerable) {
                $textureAnimationDefinitionsEnumerator = $textureAnimationDefinitionsEnumerable.GetEnumerator()
                for (; $textureAnimationDefinitionsEnumerator.MoveNext(); ) {
                    $animDef = $textureAnimationDefinitionsEnumerator.Current
                    $picNum = 0
                    $basePic = 0

                    if ($animDef.IsTexture) {
                        if ($textures.GetNumber($animDef.StartName) -eq -1) {
                            continue
                        }

                        $picNum = $textures.GetNumber($animDef.EndName)
                        $basePic = $textures.GetNumber($animDef.StartName)
                    } else {
                        if ($flats.GetNumber($animDef.StartName) -eq -1) {
                            continue
                        }

                        $picNum = $flats.GetNumber($animDef.EndName)
                        $basePic = $flats.GetNumber($animDef.StartName)
                    }

                    $anim = [TextureAnimationInfo]::new(
                        $animDef.IsTexture,
                        $picNum,
                        $basePic,
                        $picNum - $basePic + 1,
                        $animDef.Speed
                    )

                    if ($anim.NumPics -lt 2) {
                        throw "Bad animation cycle from $($animDef.StartName) to $($animDef.EndName)!"
                    }

                    #$list += $anim
                    $list.Add($anim)

                }
            }

            $this.Animations = $list

            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }
}