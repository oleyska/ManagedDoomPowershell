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