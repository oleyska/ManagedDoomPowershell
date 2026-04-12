class SpriteLookup : ISpriteLookup {
    [SpriteDef[]]$spriteDefs

    SpriteLookup([Wad]$wad) {
        try {
            [Console]::Write("Load sprites: ")

            $temp = @{}

            [Enum]::GetValues([Sprite]) | ForEach-Object { 
                $key = [DoomInfo]::SpriteNames.names.Replaced[$_]
                if ($null -ne $key) {
                    $temp[$key] = New-Object 'System.Collections.Generic.List[SpriteInfo]'
                }
            }
            
            $cache = New-Object 'System.Collections.Generic.Dictionary[int, Patch]'

            foreach ($lump in [SpriteLookup]::EnumerateSprites($wad)) {
                $name = $wad.LumpInfos[$lump].Name.Substring(0, 4)

                if (-not $temp.ContainsKey($name)) {
                    continue
                }

                $list = $temp[$name]

                $frame = [byte][char]$wad.LumpInfos[$lump].Name[4] - [byte][char]'A'
                $rotation = [byte][char]$wad.LumpInfos[$lump].Name[5] - [byte][char]'0'
                
                # Ensure $list is a List[SpriteInfo]
                if (-not ($list -is [System.Collections.Generic.List[SpriteInfo]])) {
                    $list = [System.Collections.Generic.List[SpriteInfo]]::new()
                    $temp[$name] = $list  # Store back in the hashtable
                }
                
                # Ensure the list has enough elements
                while ($list.Count -lt ($frame + 1)) {
                    $list.Add([SpriteInfo]::new())
                }

                if ($rotation -eq 0) {
                    for ($i = 0; $i -lt 8; $i++) {
                        if ($null -eq $list[$frame].Patches[$i]) {
                            $list[$frame].Patches[$i] = [SpriteLookup]::CachedRead($lump, $wad, $cache)
                            $list[$frame].Flip[$i] = $false
                        }
                    }
                } else {
                    if ($null -eq $list[$frame].Patches[$rotation - 1]) {
                        $list[$frame].Patches[$rotation - 1] = [SpriteLookup]::CachedRead($lump, $wad, $cache)
                        $list[$frame].Flip[$rotation - 1] = $false
                    }
                }

                if ($wad.LumpInfos[$lump].Name.Length -eq 8) {
                    $frame = [byte][char]$wad.LumpInfos[$lump].Name[6] - [byte][char]'A'
                    $rotation = [byte][char]$wad.LumpInfos[$lump].Name[7] - [byte][char]'0'

                    while ($list.Count -lt ($frame + 1)) {
                        $list.Add([SpriteInfo]::new())
                    }

                    if ($rotation -eq 0) {
                        for ($i = 0; $i -lt 8; $i++) {
                            if ($null -eq $list[$frame].Patches[$i]) {
                                $list[$frame].Patches[$i] = [SpriteLookup]::CachedRead($lump, $wad, $cache)
                                $list[$frame].Flip[$i] = $true
                            }
                        }
                    } else {
                        if ($null -eq $list[$frame].Patches[$rotation - 1]) {
                            $list[$frame].Patches[$rotation - 1] = [SpriteLookup]::CachedRead($lump, $wad, $cache)
                            $list[$frame].Flip[$rotation - 1] = $true
                        }
                    }
                }
            }

            $this.spriteDefs = New-Object SpriteDef[] ([Enum]::GetValues([Sprite]).Count)
            for ($i = 0; $i -lt $this.spriteDefs.Length; $i++)
            {
                $spriteName = [DoomInfo]::SpriteNames.names.Replaced[$i]
                if ([string]::IsNullOrEmpty($spriteName)) {
                    continue
                }

                if (-not $temp.ContainsKey($spriteName)) {
                    continue
                }

                $list = $temp[$spriteName]
                if ($null -eq $list -or $list.Count -eq 0) {
                    continue
                }
                        
                $frames = New-Object 'SpriteFrame[]' $list.count
                for ($j = 0; $j -lt $frames.Length; $j++) {
                    $list[$j].CheckCompletion()
            
                    $frame = [SpriteFrame]::new($list[$j].HasRotation(), $list[$j].Patches, $list[$j].Flip)
                    $frames[$j] = $frame
                }
            
                # Ensure frames array is not empty
                if ($frames.Length -eq 0) {
                    #Write-Warning "Skipping sprite creation due to empty frames: $_"
                    continue
                }
                $this.spriteDefs[$i] = [SpriteDef]::new([SpriteFrame[]]$frames)
            }

            [Console]::WriteLine("OK ($($cache.Count) sprites)")
        } catch {

            [Console]::WriteLine("Failed")
            throw $_
        }
    }
    static [System.Collections.Generic.IEnumerable[int]] EnumerateSprites([Wad] $wad) {
        $spriteSection = $false
        $results = [System.Collections.Generic.List[int]]::new()
    
        for ($lump = $wad.LumpInfos.Count - 1; $lump -ge 0; $lump--) {
            $name = $wad.LumpInfos[$lump].Name
    
            if ($name.StartsWith("S")) {
                if ($name.EndsWith("_END")) {
                    $spriteSection = $true
                    continue
                } elseif ($name.EndsWith("_START")) {
                    $spriteSection = $false
                    continue
                }
            }
    
            if ($spriteSection -and ($wad.LumpInfos[$lump].Size -gt 0)) {
                $results.Add($lump)
            }
        }
    
        return $results
    }
    static [Patch] CachedRead([int]$lump, [Wad]$wad, [ref]$cache) {
        $cacheValue = $cache.Value  # Extract actual dictionary
    
        if (-not $cacheValue.ContainsKey($lump)) {
            $name = $wad.LumpInfos[$lump].Name

            $patch = [Patch]::FromData($name, $wad.ReadLump($lump))   
            $cacheValue.Add($lump, $patch)

        }
      
        $cache.Value = $cacheValue
    
        return $cacheValue[$lump] 
    }

    [SpriteDef] Get_Item([Sprite]$sprite) {
        return $this.spriteDefs[[int]$sprite]
    }

    
}
class SpriteInfo {
    [Patch[]]$Patches
    [bool[]]$Flip

    SpriteInfo() {
        $this.Patches = New-Object 'Patch[]' 8
        $this.Flip = New-Object 'bool[]' 8
    }

    [void] CheckCompletion() {
        for ($i = 0; $i -lt $this.Patches.Length; $i++) {
            if ($null -eq $this.Patches[$i]) {
                throw [Exception]::new("Missing sprite!")
            }
        }
    }

    [bool] HasRotation() {
        for ($i = 1; $i -lt $this.Patches.Length; $i++) {
            if ($this.Patches[$i] -ne $this.Patches[0]) {
                return $true
            }
        }

        return $false
    }
}
