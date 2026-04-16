class Specials {
    static [int] $MaxButtonCount = 32
    static [int] $ButtonTime = 35

    [World] $World
    [bool] $LevelTimer
    [int] $LevelTimeCount
    [Button[]] $ButtonList
    [int[]] $TextureTranslation
    [int[]] $FlatTranslation
    [LineDef[]] $ScrollLines

    Specials([World] $world) {
        $this.World = $world
        $this.LevelTimer = $false
        $this.ButtonList = @()

        for ($i = 0; $i -lt [Specials]::MaxButtonCount; $i++) {
            $this.ButtonList += [Button]::new()
        }

        $this.EnsureTranslationTables()
    }

    hidden [int] GetTextureLookupCount() {
        $textureLookup = $this.World.Map.Textures -as [TextureLookup]
        if ($null -ne $textureLookup -and $null -ne $textureLookup.Textures) {
            return $textureLookup.Textures.Count
        }

        return $this.World.Map.Textures.get_Count()
    }

    hidden [int] GetFlatLookupCount() {
        $flatLookup = $this.World.Map.Flats -as [FlatLookup]
        if ($null -ne $flatLookup -and $null -ne $flatLookup.Flats) {
            return $flatLookup.Flats.Length
        }

        return $this.World.Map.Flats.get_Count()
    }

    hidden [void] EnsureTranslationTables() {
        $textureCount = $this.GetTextureLookupCount()
        if ($null -eq $this.TextureTranslation -or $this.TextureTranslation.Length -ne $textureCount) {
            $this.TextureTranslation = [int[]]::new($textureCount)
            for ($i = 0; $i -lt $textureCount; $i++) {
                $this.TextureTranslation[$i] = $i
            }
        }

        $flatCount = $this.GetFlatLookupCount()
        if ($null -eq $this.FlatTranslation -or $this.FlatTranslation.Length -ne $flatCount) {
            $this.FlatTranslation = [int[]]::new($flatCount)
            for ($i = 0; $i -lt $flatCount; $i++) {
                $this.FlatTranslation[$i] = $i
            }
        }
    }

    [void] SpawnSpecials([int] $levelTimeCount) {
        $this.LevelTimer = $true
        $this.LevelTimeCount = $levelTimeCount
        $this.SpawnSpecials()
    }

    [void] SpawnSpecials() {
        $lc = $this.World.LightingChange
        $sa = $this.World.SectorAction

        $specialSectorsEnumerable = $this.World.Map.Sectors
        if ($null -ne $specialSectorsEnumerable) {
            $specialSectorsEnumerator = $specialSectorsEnumerable.GetEnumerator()
            for (; $specialSectorsEnumerator.MoveNext(); ) {
                $sector = $specialSectorsEnumerator.Current
                if ($sector.Special -eq 0) { continue }

                switch ([int]$sector.Special) {
                    1 { $lc.SpawnLightFlash($sector) }
                    2 { $lc.SpawnStrobeFlash($sector, [StrobeFlash]::FastDark, $false) }
                    3 { $lc.SpawnStrobeFlash($sector, [StrobeFlash]::SlowDark, $false) }
                    4 {
                        $lc.SpawnStrobeFlash($sector, [StrobeFlash]::FastDark, $false)
                        $sector.Special = 4
                    }
                    8 { $lc.SpawnGlowingLight($sector) }
                    9 { $this.World.TotalSecrets++ }
                    10 { $sa.SpawnDoorCloseIn30($sector) }
                    12 { $lc.SpawnStrobeFlash($sector, [StrobeFlash]::SlowDark, $true) }
                    13 { $lc.SpawnStrobeFlash($sector, [StrobeFlash]::FastDark, $true) }
                    14 { $sa.SpawnDoorRaiseIn5Mins($sector) }
                    17 { $lc.SpawnFireFlicker($sector) }
                }

            }
        }

        $scrollList = @()
        $scrollSourceLinesEnumerable = $this.World.Map.Lines
        if ($null -ne $scrollSourceLinesEnumerable) {
            $scrollSourceLinesEnumerator = $scrollSourceLinesEnumerable.GetEnumerator()
            for (; $scrollSourceLinesEnumerator.MoveNext(); ) {
                $line = $scrollSourceLinesEnumerator.Current
                if ($line.Special -eq 48) {
                    $scrollList += $line
                }

            }
        }
        $this.ScrollLines = $scrollList
    }

    [void] ChangeSwitchTexture([LineDef] $line, [bool] $useAgain) {
        if (-not $useAgain) { $line.Special = 0 }

        $frontSide = $line.FrontSide
        $topTexture = $frontSide.TopTexture
        $middleTexture = $frontSide.MiddleTexture
        $bottomTexture = $frontSide.BottomTexture

        $sound = [Sfx]::SWTCHN
        if ($line.Special -eq 11) { $sound = [Sfx]::SWTCHX }

        $switchList = $this.World.Map.Textures.SwitchList

        for ($i = 0; $i -lt $switchList.Length; $i++) {
            if ($switchList[$i] -eq $topTexture) {
                $this.World.StartSound($line.SoundOrigin, $sound, [SfxType]::Misc)
                $frontSide.TopTexture = $switchList[$i -bxor 1]
                if ($useAgain) { $this.StartButton($line, [ButtonPosition]::Top, $switchList[$i], [Specials]::ButtonTime) }
                return
            }
            elseif ($switchList[$i] -eq $middleTexture) {
                $this.World.StartSound($line.SoundOrigin, $sound, [SfxType]::Misc)
                $frontSide.MiddleTexture = $switchList[$i -bxor 1]
                if ($useAgain) { $this.StartButton($line, [ButtonPosition]::Middle, $switchList[$i], [Specials]::ButtonTime) }
                return
            }
            elseif ($switchList[$i] -eq $bottomTexture) {
                $this.World.StartSound($line.SoundOrigin, $sound, [SfxType]::Misc)
                $frontSide.BottomTexture = $switchList[$i -bxor 1]
                if ($useAgain) { $this.StartButton($line, [ButtonPosition]::Bottom, $switchList[$i], [Specials]::ButtonTime) }
                return
            }
        }
    }

    [void] StartButton([LineDef] $line, [ButtonPosition] $w, [int] $texture, [int] $time) {
        for ($i = 0; $i -lt [Specials]::MaxButtonCount; $i++) {
            if ($this.ButtonList[$i].Timer -ne 0 -and $this.ButtonList[$i].Line -eq $line) { return }
        }

        for ($i = 0; $i -lt [Specials]::MaxButtonCount; $i++) {
            if ($this.ButtonList[$i].Timer -eq 0) {
                $this.ButtonList[$i].Line = $line
                $this.ButtonList[$i].Position = $w
                $this.ButtonList[$i].Texture = $texture
                $this.ButtonList[$i].Timer = $time
                $this.ButtonList[$i].SoundOrigin = $line.SoundOrigin
                return
            }
        }

        throw "No button slots left!"
    }

    [void] Update() {
        $this.EnsureTranslationTables()

        if ($this.LevelTimer) {
            $this.LevelTimeCount--
            if ($this.LevelTimeCount -eq 0) { $this.World.ExitLevel() }
        }

        $animations = $this.World.Map.Animation.Animations
        for ($k = 0; $k -lt $animations.Length; $k++) {
            $anim = $animations[$k]
            for ($i = $anim.BasePic; $i -lt ($anim.BasePic + $anim.NumPics); $i++) {
                $pic = $anim.BasePic + (($this.World.LevelTime / $anim.Speed + $i) % $anim.NumPics)
                if ($anim.IsTexture) {
                    $this.TextureTranslation[$i] = $pic
                } else {
                    $this.FlatTranslation[$i] = $pic
                }
            }
        }

        $scrollingLinesEnumerable = $this.ScrollLines
        if ($null -ne $scrollingLinesEnumerable) {
            $scrollingLinesEnumerator = $scrollingLinesEnumerable.GetEnumerator()
            for (; $scrollingLinesEnumerator.MoveNext(); ) {
                $line = $scrollingLinesEnumerator.Current
                $line.FrontSide.TextureOffset += [Fixed]::One

            }
        }

        for ($i = 0; $i -lt [Specials]::MaxButtonCount; $i++) {
            if ($this.ButtonList[$i].Timer -gt 0) {
                $this.ButtonList[$i].Timer--
                if ($this.ButtonList[$i].Timer -eq 0) {
                    switch ($this.ButtonList[$i].Position) {
                        ButtonPosition::Top { $this.ButtonList[$i].Line.FrontSide.TopTexture = $this.ButtonList[$i].Texture }
                        ButtonPosition::Middle { $this.ButtonList[$i].Line.FrontSide.MiddleTexture = $this.ButtonList[$i].Texture }
                        ButtonPosition::Bottom { $this.ButtonList[$i].Line.FrontSide.BottomTexture = $this.ButtonList[$i].Texture }
                    }
                    $this.World.StartSound($this.ButtonList[$i].SoundOrigin, [Sfx]::SWTCHN, [SfxType]::Misc, 50)
                    $this.ButtonList[$i].Clear()
                }
            }
        }
    }
}
