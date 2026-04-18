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

class DummySpriteLookup : ISpriteLookup {
    [SpriteDef[]]$spriteDefs

    DummySpriteLookup([Wad]$wad) {
        $temp = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[SpriteInfo]]]::new()
        for ($i = 0; $i -lt [int][Sprite]::Count; $i++) {
            $temp.Add(([DoomInfo]::SpriteNames.Names[$i]).ToString(), [System.Collections.Generic.List[SpriteInfo]]::new())
        }

        $cache = New-Object 'System.Collections.Generic.Dictionary[int, Patch]'

        $dummySpriteLumpsEnumerable = [DummySpriteLookup]::EnumerateSprites($wad)
        if ($null -ne $dummySpriteLumpsEnumerable) {
            $dummySpriteLumpsEnumerator = $dummySpriteLumpsEnumerable.GetEnumerator()
            for (; $dummySpriteLumpsEnumerator.MoveNext(); ) {
                $lump = $dummySpriteLumpsEnumerator.Current
                $name = $wad.LumpInfos[$lump].Name.Substring(0, 4)

                if (-not $temp.ContainsKey($name)) {
                    continue
                }

                $list = $temp[$name]

                $frame = ([int][char]$wad.LumpInfos[$lump].Name[4]) - ([int][char]'A')
                $rotation = ([int][char]$wad.LumpInfos[$lump].Name[5]) - ([int][char]'0')

                while ($list.Count -lt $frame + 1) {
                    $list.Add([SpriteInfo]::new())
                }

                if ($rotation -eq 0) {
                    for ($i = 0; $i -lt 8; $i++) {
                        if ($null -eq $list[$frame].Patches[$i]) {
                            $list[$frame].Patches[$i] = [DummyData]::GetPatch()
                            $list[$frame].Flip[$i] = $false
                        }
                    }
                }
                else {
                    if ($null -eq $list[$frame].Patches[$rotation - 1]) {
                        $list[$frame].Patches[$rotation - 1] = [DummyData]::GetPatch()
                        $list[$frame].Flip[$rotation - 1] = $false
                    }
                }

                if ($wad.LumpInfos[$lump].Name.Length -eq 8) {
                    $frame = ([int][char]$wad.LumpInfos[$lump].Name[6]) - ([int][char]'A')
                    $rotation = ([int][char]$wad.LumpInfos[$lump].Name[7]) - ([int][char]'0')

                    while ($list.Count -lt $frame + 1) {
                        $list.Add([SpriteInfo]::new())
                    }

                    if ($rotation -eq 0) {
                        for ($i = 0; $i -lt 8; $i++) {
                            if ($null -eq $list[$frame].Patches[$i]) {
                                $list[$frame].Patches[$i] = [DummyData]::GetPatch()
                                $list[$frame].Flip[$i] = $true
                            }
                        }
                    }
                    else {
                        if ($null -eq $list[$frame].Patches[$rotation - 1]) {
                            $list[$frame].Patches[$rotation - 1] = [DummyData]::GetPatch()
                            $list[$frame].Flip[$rotation - 1] = $true
                        }
                    }
                }

            }
        }

        $this.spriteDefs = New-Object 'SpriteDef[]' $temp.Count

        for ($i = 0; $i -lt $this.spriteDefs.Length; $i++) {
            $list = $temp[([DoomInfo]::SpriteNames.Names[$i]).ToString()]

            $frames = New-Object 'SpriteFrame[]' $list.Count
            for ($j = 0; $j -lt $frames.Length; $j++) {
                $list[$j].CheckCompletion()

                $frame = New-Object 'SpriteFrame'($list[$j].HasRotation(), $list[$j].Patches, $list[$j].Flip)
                $frames[$j] = $frame
            }

            $this.spriteDefs[$i] = [SpriteDef]::new($frames)
        }
    }

    static [int[]] EnumerateSprites([Wad]$wad) {
        $spriteSection = $false
        $lumpList = @()
    
        for ($lump = $wad.LumpInfos.Count - 1; $lump -ge 0; $lump--) {
            $name = $wad.LumpInfos[$lump].Name
    
            if ($name.StartsWith("S")) {
                if ($name.EndsWith("_END")) {
                    $spriteSection = $true
                    continue
                }
                elseif ($name.EndsWith("_START")) {
                    $spriteSection = $false
                    continue
                }
            }
    
            if ($spriteSection) {
                if ($wad.LumpInfos[$lump].Size -gt 0) {
                    $lumpList += $lump  # Collect all values in an array
                }
            }
        }
    
        return $lumpList  # Return as an array instead of streaming values
    }

    [SpriteDef] Get_Item([Sprite]$sprite) {
        return $this.spriteDefs[[int]$sprite]
    }
    
}