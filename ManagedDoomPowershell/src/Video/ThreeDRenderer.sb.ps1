# ThreeDRenderer.ps1 - Ported from C# ThreeDRenderer.cs

class ThreeDRenderer {
    static [int] $MaxScreenSize = 9

    [ColorMap] $colorMap
    [ITextureLookup] $textures
    [IFlatLookup] $flats
    [Flat[]] $flatArray
    [byte[][]] $flatDataArray
    [byte[]] $emptyFlatData
    [int] $skyFlatNumber
    [ISpriteLookup] $sprites

    [DrawScreen] $screen
    [int] $screenWidth
    [int] $screenHeight
    [byte[]] $screenData
    [int[]] $columnBase
    [int] $drawScale
    [byte[]] $defaultColorMap
    [byte[]] $fuzzColorMap

    [int] $windowSize
    [Fixed] $frameFrac

    [int] $windowX
    [int] $windowY
    [int] $windowWidth
    [int] $windowHeight
    [int] $centerX
    [int] $centerY
    [Fixed] $centerXFrac
    [Fixed] $centerYFrac
    [Fixed] $projection
    [Column[][]] $renderSkyColumns
    [int] $renderSkyWidth
    [int] $renderSkyMask

    [int[]] $angleToX
    [Angle[]] $xToAngle
    [uint32[]] $xToAngleData
    [int[]] $viewColumnSinData
    [int[]] $viewColumnCosData
    [Angle] $clipAngle
    [Angle] $clipAngle2

    ThreeDRenderer([GameContent] $content, [DrawScreen] $screen, [int] $windowSize) {
        $this.colorMap = $content.ColorMap
        $this.textures = $content.Textures
        $this.flats = $content.Flats
        $concreteFlatLookup = $content.Flats -as [FlatLookup]
        if ($null -ne $concreteFlatLookup) {
            $this.flatArray = $concreteFlatLookup.Flats
            if ($null -ne $this.flatArray) {
                $this.flatDataArray = [byte[][]]::new($this.flatArray.Length)
                for ($i = 0; $i -lt $this.flatArray.Length; $i++) {
                    if ($null -ne $this.flatArray[$i]) {
                        $this.flatDataArray[$i] = $this.flatArray[$i].Data
                    }
                }
            }
        }
        $this.emptyFlatData = [byte[]]::new(4096)
        $this.skyFlatNumber = $content.Flats.SkyFlatNumber
        $this.sprites = $content.Sprites -as [ISpriteLookup]

        $this.screen = $screen
        $this.screenWidth = $screen.Width
        $this.screenHeight = $screen.Height
        $this.screenData = $screen.Data
        $this.defaultColorMap = $this.colorMap.get_Item(0)
        $this.fuzzColorMap = $this.colorMap.get_Item(6)
        if ($null -eq $this.fuzzColorMap) {
            $this.fuzzColorMap = $this.defaultColorMap
        }
        $this.drawScale = [math]::floor($screen.Width / 320)

        $this.windowSize = $windowSize

        $this.InitWallRendering()
        $this.InitPlaneRendering()
        $this.InitSkyRendering()
        $this.InitLighting()
        $this.InitRenderingHistory()
        $this.InitSpriteRendering()
        $this.InitWeaponRendering()
        $this.InitFuzzEffect()
        $this.InitColorTranslation()
        $this.InitWindowBorder($content.Wad)

        $this.SetWindowSize($windowSize)
    }

    [void] SetWindowSize([int] $size) {
        $this.windowSize = $size
        $scale = [math]::floor($this.screenWidth / 320)
        if ($size -lt 7) {
            $width = $scale * (96 + 32 * $size)
            $height = $scale * (48 + 16 * $size)
            $x = [math]::floor(($this.screenWidth - $width) / 2)
            $y = [math]::floor(($this.screenHeight - [StatusBarRenderer]::Height * $scale - $height) / 2)
            $this.ResetWindow($x, $y, $width, $height)
        } elseif ($size -eq 7) {
            $width = $this.screenWidth
            $height = $this.screenHeight - [StatusBarRenderer]::Height * $scale
            $this.ResetWindow(0, 0, $width, $height)
        } else {
            $width = $this.screenWidth
            $height = $this.screenHeight
            $this.ResetWindow(0, 0, $width, $height)
        }

        $this.ResetWallRendering()
        $this.ResetPlaneRendering()
        $this.ResetSkyRendering()
        $this.ResetLighting()
        $this.ResetRenderingHistory()
        $this.ResetWeaponRendering()
    }

    [void] ResetWindow([int] $x, [int] $y, [int] $width, [int] $height) {
        $this.windowX = $x
        $this.windowY = $y
        $this.windowWidth = $width
        $this.windowHeight = $height
        $this.centerX = [math]::floor($width / 2)
        $this.centerY = [math]::floor($height / 2)
        $this.centerXFrac = [Fixed]::FromInt($this.centerX)
        $this.centerYFrac = [Fixed]::FromInt($this.centerY)
        $this.projection = $this.centerXFrac
        $this.columnBase = [int[]]::new($width)
        $base = ($this.screenHeight * $x) + $y
        for ($i = 0; $i -lt $this.columnBase.Length; $i++) {
            $this.columnBase[$i] = $base
            $base += $this.screenHeight
        }
    }

    static [int] WrapColumnIndex([int] $value, [int] $width) {
        if ($width -le 0) {
            return 0
        }

        if (($width -band ($width - 1)) -eq 0) {
            return $value -band ($width - 1)
        }

        $wrapped = $value % $width
        if ($wrapped -lt 0) {
            $wrapped += $width
        }

        return $wrapped
    }

    [void] InitWallRendering() {
        $this.angleToX = New-Object int[] ([Trig]::FineAngleCount / 2)
        $this.xToAngle = New-Object Angle[] ($this.screenWidth)
        $this.xToAngleData = New-Object uint32[] ($this.screenWidth)
        $this.viewColumnSinData = New-Object int[] ($this.screenWidth)
        $this.viewColumnCosData = New-Object int[] ($this.screenWidth)
    }

    static [int] $fineFov = [Trig]::FineAngleCount / 4

    [void] ResetWallRendering() {
        $focalAngleFine = ([Trig]::FineAngleCount / 4) + ([ThreeDRenderer]::fineFov / 2)
        $focalAngle = [Angle]::new([uint32]($focalAngleFine -shl [Trig]::AngleToFineShift))
        $focalLength = $this.centerXFrac / [Trig]::Tan($focalAngle)

        for ($i = 0; $i -lt [Trig]::FineAngleCount / 2; $i++) {
            $tan = [Trig]::TanFromInt($i)
            $t = 0
            if ($tan.Data -gt ([Fixed]::FromInt(2)).Data) {
                $t = -1
            } elseif ($tan.Data -lt ([Fixed]::FromInt(-2)).Data) {
                $t = $this.windowWidth + 1
            } else {
                $t = ($this.centerXFrac - ($tan * $focalLength)).ToIntCeiling()

                if ($t -lt -1) {
                    $t = -1
                } elseif ($t -gt $this.windowWidth + 1) {
                    $t = $this.windowWidth + 1
                }
            }
            $this.angleToX[$i] = $t
        }

        for ($x = 0; $x -lt $this.windowWidth; $x++) {
            $i = 0
            while ($this.angleToX[$i] -gt $x) {
                $i++
            }
            $this.xToAngle[$x] = [Angle]::new([uint]([uint32]$i -shl [Trig]::AngleToFineShift)) - [Angle]::Ang90
            $this.xToAngleData[$x] = $this.xToAngle[$x].Data
        }

        for ($i = 0; $i -lt [Trig]::FineAngleCount / 2; $i++) {
            if ($this.angleToX[$i] -eq -1) {
                $this.angleToX[$i] = 0
            } elseif ($this.angleToX[$i] -eq $this.windowWidth + 1) {
                $this.angleToX[$i] = $this.windowWidth
            }
        }

        $this.clipAngle = $this.xToAngle[0]
        $this.clipAngle2 = [Angle]::new(2 * $this.clipAngle.Data)
    }

    [void] UpdateViewColumnTrigData() {
        [uint32] $localViewAngleData = $this.viewAngleData
        $localXToAngleData = $this.xToAngleData
        $localSinData = $this.viewColumnSinData
        $localCosData = $this.viewColumnCosData
        $fineSine = [Trig]::fineSine
        $angleToFineShift = [Trig]::AngleToFineShift
        $fineCosineOffset = [Trig]::fineCosineOffset

        for ($x = 0; $x -lt $this.windowWidth; $x++) {
            $angleData = [uint32]((([uint64]$localViewAngleData + [uint64]$localXToAngleData[$x]) -band 0xFFFFFFFFul))
            $fineIndex = [int]($angleData -shr $angleToFineShift)
            $localSinData[$x] = $fineSine[$fineIndex]
            $localCosData[$x] = $fineSine[$fineIndex + $fineCosineOffset]
        }
    }

    [int[]] $planeYSlope
    [int[]] $planeDistScale
    [int] $planeBaseXScale
    [int] $planeBaseYScale
    [Sector] $ceilingPrevSector
    [int] $ceilingPrevX
    [int] $ceilingPrevY1
    [int] $ceilingPrevY2
    [int[]] $ceilingXFrac
    [int[]] $ceilingYFrac
    [int[]] $ceilingXStep
    [int[]] $ceilingYStep
    [byte[][]] $ceilingLights

    [Sector] $floorPrevSector
    [int] $floorPrevX
    [int] $floorPrevY1
    [int] $floorPrevY2
    [int[]] $floorXFrac
    [int[]] $floorYFrac
    [int[]] $floorXStep
    [int[]] $floorYStep
    [byte[][]] $floorLights

    [void] InitPlaneRendering() {
        $this.planeYSlope = New-Object int[] ($this.screenHeight)
        $this.planeDistScale = New-Object int[] ($this.screenWidth)
        $this.ceilingXFrac = New-Object int[] ($this.screenHeight)
        $this.ceilingYFrac = New-Object int[] ($this.screenHeight)
        $this.ceilingXStep = New-Object int[] ($this.screenHeight)
        $this.ceilingYStep = New-Object int[] ($this.screenHeight)
        $this.ceilingLights = New-Object 'byte[][]' ($this.screenHeight)
        $this.floorXFrac = New-Object int[] ($this.screenHeight)
        $this.floorYFrac = New-Object int[] ($this.screenHeight)
        $this.floorXStep = New-Object int[] ($this.screenHeight)
        $this.floorYStep = New-Object int[] ($this.screenHeight)
        $this.floorLights = New-Object 'byte[][]' ($this.screenHeight)
    }

    [void] ResetPlaneRendering() {
        for ($i = 0; $i -lt $this.windowHeight; $i++) {
            $dy = [Fixed]::FromInt($i - $this.windowHeight / 2) + ([Fixed]::One / 2)
            $dy = [Fixed]::Abs($dy)
            $this.planeYSlope[$i] = ([Fixed]::FromInt($this.windowWidth / 2) / $dy).Data
        }

        for ($i = 0; $i -lt $this.windowWidth; $i++) {
            $cos = [Fixed]::Abs([Trig]::Cos($this.xToAngle[$i]))
            $this.planeDistScale[$i] = ([Fixed]::One / $cos).Data
        }
    }

    [void] ClearPlaneRendering() {
        $angle = $this.viewAngle - [Angle]::Ang90
        $this.planeBaseXScale = ([Trig]::Cos($angle) / $this.centerXFrac).Data
        $this.planeBaseYScale = (-([Trig]::Sin($angle) / $this.centerXFrac)).Data

        $this.ceilingPrevSector = $null
        $this.ceilingPrevX = [int]::MaxValue

        $this.floorPrevSector = $null
        $this.floorPrevX = [int]::MaxValue
    }

        ############################################################
    # Sky rendering
    ############################################################

    static [int] $angleToSkyShift = 22
    [Fixed] $skyTextureAlt
    [Fixed] $skyInvScale

    [void] InitSkyRendering() {
        $this.skyTextureAlt = [Fixed]::FromInt(100)
    }

    [void] ResetSkyRendering() {
        # The code below is based on PrBoom+'s sky rendering implementation.
        $num = [Fixed]::FracUnit * $this.screenWidth * 200
        $den = $this.windowWidth * $this.screenHeight
        $this.skyInvScale = [Fixed]::new([math]::floor($num / $den))
    }

    ############################################################
    # Lighting
    ############################################################

    static [int] $lightLevelCount = 16
    static [int] $lightSegShift = 4
    static [int] $scaleLightShift = 12
    static [int] $zLightShift = 20
    static [int] $colorMapCount = 32

    [int] $maxScaleLight
    static [int] $maxZLight = 128

    [byte[][][]] $diminishingScaleLight
    [byte[][][]] $diminishingZLight
    [byte[][][]] $fixedLight

    [byte[][][]] $scaleLight
    [byte[][][]] $zLight

    [int] $extraLight
    [int] $fixedColorMap
    [byte[]] $cachedFixedLightColorMap

    [void] InitLighting() {
        $this.maxScaleLight = 48 * [math]::floor($this.screenWidth / 320)

        $this.diminishingScaleLight = [byte[][][]]::new([ThreeDRenderer]::lightLevelCount)
        $this.diminishingZLight = [byte[][][]]::new([ThreeDRenderer]::lightLevelCount)
        $this.fixedLight = [byte[][][]]::new([ThreeDRenderer]::lightLevelCount)

        for ($i = 0; $i -lt [ThreeDRenderer]::lightLevelCount; $i++) {
            $this.diminishingScaleLight[$i] = [byte[][]]::new($this.maxScaleLight)
            $this.diminishingZLight[$i] = [byte[][]]::new([ThreeDRenderer]::maxZLight)
            $this.fixedLight[$i] = [byte[][]]::new([math]::Max($this.maxScaleLight, [ThreeDRenderer]::maxZLight))
        }

        $distMap = 2

        # Calculate the light levels to use for each level/distance combination.
        for ($i = 0; $i -lt [ThreeDRenderer]::lightLevelCount; $i++) {
            $start = ((([ThreeDRenderer]::lightLevelCount - 1 - $i) * 2) * [ThreeDRenderer]::colorMapCount) / [ThreeDRenderer]::lightLevelCount
            for ($j = 0; $j -lt [ThreeDRenderer]::maxZLight; $j++) {
                $scale = [Fixed]::FromInt(320 / 2) / [Fixed]::new(($j + 1) -shl [ThreeDRenderer]::zLightShift)
                $scale = [Fixed]::new($scale.Data -shr [ThreeDRenderer]::scaleLightShift)

                $level = $start - [math]::floor($scale.Data / $distMap)
                if ($level -lt 0) {
                    $level = 0
                } elseif ($level -ge [ThreeDRenderer]::colorMapCount) {
                    $level = [ThreeDRenderer]::colorMapCount - 1
                }

                $this.diminishingZLight[$i][$j] = $this.colorMap.get_Item($level)
            }
        }
    }

    [void] ResetLighting() {
        $distMap = 2

        # Calculate the light levels to use for each level/scale combination.
        for ($i = 0; $i -lt [ThreeDRenderer]::lightLevelCount; $i++) {
            $start = ((([ThreeDRenderer]::lightLevelCount - 1 - $i) * 2) * [ThreeDRenderer]::colorMapCount) / [ThreeDRenderer]::lightLevelCount
            for ($j = 0; $j -lt $this.maxScaleLight; $j++) {
                $level = $start - [math]::floor($j * 320 / $this.windowWidth / $distMap)
                if ($level -lt 0) {
                    $level = 0
                } elseif ($level -ge [ThreeDRenderer]::colorMapCount) {
                    $level = [ThreeDRenderer]::colorMapCount - 1
                }

                $this.diminishingScaleLight[$i][$j] = $this.colorMap.get_Item($level)
            }
        }
    }

    [void] ClearLighting() {
        if ($null -eq $this.fixedLight -or $this.fixedLight.Length -ne [ThreeDRenderer]::lightLevelCount) {
            $this.fixedLight = [byte[][][]]::new([ThreeDRenderer]::lightLevelCount)
        }

        for ($i = 0; $i -lt [ThreeDRenderer]::lightLevelCount; $i++) {
            if ($null -eq $this.fixedLight[$i]) {
                $this.fixedLight[$i] = [byte[][]]::new([math]::Max($this.maxScaleLight, [ThreeDRenderer]::maxZLight))
            }
        }

        if ($this.fixedColorMap -eq 0) {
            $this.scaleLight = $this.diminishingScaleLight
            $this.zLight = $this.diminishingZLight
            $this.cachedFixedLightColorMap = $null
        } else {
            $targetColorMap = $this.colorMap.get_Item($this.fixedColorMap)

            if (-not [object]::ReferenceEquals($this.cachedFixedLightColorMap, $targetColorMap)) {
                for ($i = 0; $i -lt [ThreeDRenderer]::lightLevelCount; $i++) {
                for ($j = 0; $j -lt $this.fixedLight[$i].Length; $j++) {
                        $this.fixedLight[$i][$j] = $targetColorMap
                    }
                }

                $this.cachedFixedLightColorMap = $targetColorMap
            }

            $this.scaleLight = $this.fixedLight
            $this.zLight = $this.fixedLight
        }
    }
    
    ############################################################
    # Rendering history
    ############################################################

    [short[]] $upperClip
    [short[]] $lowerClip

    [int] $negOneArray
    [int] $windowHeightArray

    [int] $clipRangeCount
    [ClipRange[]] $clipRanges

    [int] $clipDataLength
    [short[]] $clipData

    [int] $visWallRangeCount
    [VisWallRange[]] $visWallRanges

    [void] InitRenderingHistory() {
        $this.upperClip = New-Object short[] $this.screenWidth
        $this.lowerClip = New-Object short[] $this.screenWidth

        $this.clipRanges = New-Object ClipRange[] 256
        for ($i = 0; $i -lt $this.clipRanges.Length; $i++) {
            $this.clipRanges[$i] = [ClipRange]::new()
        }

        $this.clipData = New-Object short[] (128 * $this.screenWidth)

        $this.visWallRanges = New-Object VisWallRange[] 512
        for ($i = 0; $i -lt $this.visWallRanges.Length; $i++) {
            $this.visWallRanges[$i] = [VisWallRange]::new()
        }
    }

    [void] ResetRenderingHistory() {
        for ($i = 0; $i -lt $this.windowWidth; $i++) {
            $this.clipData[$i] = -1
        }
        $this.negOneArray = 0

        for ($i = $this.windowWidth; $i -lt (2 * $this.windowWidth); $i++) {
            $this.clipData[$i] = [short] $this.windowHeight
        }
        $this.windowHeightArray = $this.windowWidth
    }

    [void] ClearRenderingHistory() {
        for ($x = 0; $x -lt $this.windowWidth; $x++) {
            $this.upperClip[$x] = -1
        }
        for ($x = 0; $x -lt $this.windowWidth; $x++) {
            $this.lowerClip[$x] = [short] $this.windowHeight
        }

        $this.clipRanges[0].First = -0x7fffffff
        $this.clipRanges[0].Last = -1
        $this.clipRanges[1].First = $this.windowWidth
        $this.clipRanges[1].Last = 0x7fffffff
        $this.clipRangeCount = 2

        $this.clipDataLength = 2 * $this.windowWidth

        $this.visWallRangeCount = 0
    }
    ############################################################
    # Sprite rendering
    ############################################################

    static [Fixed] $minZ = [Fixed]::FromInt(4)

    [int] $visSpriteCount
    [VisSprite[]] $visSprites

    [VisSpriteComparer] $visSpriteComparer

    [void] InitSpriteRendering() {
        $this.visSprites = New-Object VisSprite[] 256
        for ($i = 0; $i -lt $this.visSprites.Length; $i++) {
            $this.visSprites[$i] = [VisSprite]::new()
        }

        $this.visSpriteComparer = [VisSpriteComparer]::new()
    }

    [void] ClearSpriteRendering() {
        $this.visSpriteCount = 0
    }


    ############################################################
    # Weapon rendering
    ############################################################

    [VisSprite] $weaponSprite
    [Fixed] $weaponScale
    [Fixed] $weaponInvScale

    [void] InitWeaponRendering() {
        $this.weaponSprite = [VisSprite]::new()
    }

    [void] ResetWeaponRendering() {
        $this.weaponScale = [Fixed]::new([Fixed]::FracUnit * $this.windowWidth / 320)
        $this.weaponInvScale = [Fixed]::new([Fixed]::FracUnit * 320 / $this.windowWidth)
    }


    ############################################################
    # Fuzz effect
    ############################################################

    static [sbyte[]] $fuzzTable = @(
        1, -1,  1, -1,  1,  1, -1,
        1,  1, -1,  1,  1,  1, -1,
        1,  1,  1, -1, -1, -1, -1,
        1, -1, -1,  1,  1,  1,  1, -1,
        1, -1,  1,  1, -1, -1,  1,
        1, -1, -1, -1, -1,  1,  1,
        1,  1, -1,  1,  1, -1,  1
    )

    [int] $fuzzPos

    [void] InitFuzzEffect() {
        $this.fuzzPos = 0
    }


    ############################################################
    # Color translation
    ############################################################

    [byte[]] $greenToGray
    [byte[]] $greenToBrown
    [byte[]] $greenToRed

    [void] InitColorTranslation() {
        $this.greenToGray = New-Object byte[] 256
        $this.greenToBrown = New-Object byte[] 256
        $this.greenToRed = New-Object byte[] 256

        for ($i = 0; $i -lt 256; $i++) {
            $this.greenToGray[$i] = [byte]$i
            $this.greenToBrown[$i] = [byte]$i
            $this.greenToRed[$i] = [byte]$i
        }

        for ($i = 112; $i -lt 128; $i++) {
            $this.greenToGray[$i] -= 16
            $this.greenToBrown[$i] -= 48
            $this.greenToRed[$i] -= 80
        }
    }
    ############################################################
    # Window border
    ############################################################

    [Patch] $borderTopLeft
    [Patch] $borderTopRight
    [Patch] $borderBottomLeft
    [Patch] $borderBottomRight
    [Patch] $borderTop
    [Patch] $borderBottom
    [Patch] $borderLeft
    [Patch] $borderRight
    [Flat] $backFlat

    [void] InitWindowBorder([Wad] $wad) {
        $this.borderTopLeft = [Patch]::FromWad($wad, "BRDR_TL")
        $this.borderTopRight = [Patch]::FromWad($wad, "BRDR_TR")
        $this.borderBottomLeft = [Patch]::FromWad($wad, "BRDR_BL")
        $this.borderBottomRight = [Patch]::FromWad($wad, "BRDR_BR")
        $this.borderTop = [Patch]::FromWad($wad, "BRDR_T")
        $this.borderBottom = [Patch]::FromWad($wad, "BRDR_B")
        $this.borderLeft = [Patch]::FromWad($wad, "BRDR_L")
        $this.borderRight = [Patch]::FromWad($wad, "BRDR_R")

        if ($wad.GameMode -eq [GameMode]::Commercial) {
            $this.backFlat = $this.flats.get_Item("GRNROCK")
        } else {
            $this.backFlat = $this.flats.get_Item("FLOOR7_2")
        }
    }

    [void] FillBackScreen() {
        $fillHeight = $this.screenHeight - ($this.drawScale * [StatusBarRenderer]::Height)

        $this.FillRect(0, 0, $this.windowX, $fillHeight)
        $this.FillRect($this.screenWidth - $this.windowX, 0, $this.windowX, $fillHeight)
        $this.FillRect($this.windowX, 0, $this.screenWidth - (2 * $this.windowX), $this.windowY)
        $this.FillRect($this.windowX, $fillHeight - $this.windowY, $this.screenWidth - (2 * $this.windowX), $this.windowY)

        $step = 8 * $this.drawScale

        for ($x = $this.windowX; $x -lt ($this.screenWidth - $this.windowX); $x += $step) # integer addition
        {
            $this.screen.DrawPatch($this.borderTop, $x, $this.windowY - $step, $this.drawScale)
            $this.screen.DrawPatch($this.borderBottom, $x, $fillHeight - $this.windowY, $this.drawScale)
        }

        for ($y = $this.windowY; $y -lt ($fillHeight - $this.windowY); $y += $step) # integer addition
        {
            $this.screen.DrawPatch($this.borderLeft, $this.windowX - $step, $y, $this.drawScale)
            $this.screen.DrawPatch($this.borderRight, $this.screenWidth - $this.windowX, $y, $this.drawScale)
        }

        $this.screen.DrawPatch($this.borderTopLeft, $this.windowX - $step, $this.windowY - $step, $this.drawScale)
        $this.screen.DrawPatch($this.borderTopRight, $this.screenWidth - $this.windowX, $this.windowY - $step, $this.drawScale)
        $this.screen.DrawPatch($this.borderBottomLeft, $this.windowX - $step, $fillHeight - $this.windowY, $this.drawScale)
        $this.screen.DrawPatch($this.borderBottomRight, $this.screenWidth - $this.windowX, $fillHeight - $this.windowY, $this.drawScale)
    }

    [void] FillRect([int] $x, [int] $y, [int] $width, [int] $height) {
        $data = $this.backFlat.Data

        $srcX = [math]::floor($x / $this.drawScale)
        $srcY = [math]::floor($y / $this.drawScale)

        $invScale = [Fixed]::One / $this.drawScale
        $xFrac = $invScale - [Fixed]::Epsilon

        for ($i = 0; $i -lt $width; $i++) {
            $src = (($srcX + $xFrac.ToIntFloor()) -band 63) -shl 6
            $dst = ($this.screenHeight * ($x + $i)) + $y
            $yFrac = $invScale - [Fixed]::Epsilon

            for ($j = 0; $j -lt $height; $j++) {
                $this.screenData[$dst + $j] = $data[$src -bor (($srcY + $yFrac.ToIntFloor()) -band 63)]
                $yFrac += $invScale
            }
            $xFrac += $invScale
        }
    }
    ############################################################
    # Camera view
    ############################################################

    [World] $world

    [Fixed] $viewX
    [Fixed] $viewY
    [Fixed] $viewZ
    [Angle] $viewAngle

    [Fixed] $viewSin
    [Fixed] $viewCos
    [int] $viewXData
    [int] $viewYData
    [int] $viewZData
    [int] $viewNegYData
    [uint32] $viewAngleData

    [int] $validCount
    [int] $debugSubsectorCount
    [int] $debugSegCount
    [int] $debugSolidWallCount
    [int] $debugPassWallCount
    [bool] $perfThreeDSampleFrame
    [long] $PerfThreeDFrames
    [long] $PerfThreeDSampleFrames
    [long] $PerfThreeDTicksTotal
    [long] $PerfThreeDTicksSetup
    [long] $PerfThreeDTicksBsp
    [long] $PerfThreeDTicksSprites
    [long] $PerfThreeDTicksMasked
    [long] $PerfThreeDTicksPlayerSprites
    [long] $PerfThreeDTicksBackScreen
    [long] $PerfThreeDTicksDrawSeg
    [long] $PerfThreeDTicksSolidRange
    [long] $PerfThreeDTicksPassRange
    [long] $PerfThreeDTicksAddSprites
    [long] $PerfThreeDSubsectors
    [long] $PerfThreeDSegs
    [long] $PerfThreeDSolidWalls
    [long] $PerfThreeDPassWalls
    [long] $PerfThreeDVisWalls
    [long] $PerfThreeDVisSprites

    [void] Render([Player] $player, [Fixed] $frameFrac) {
        $perfThreeDStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.perfThreeDSampleFrame = (($this.PerfThreeDFrames % 30) -eq 0)
        $this.frameFrac = $frameFrac

        $this.world = $player.Mobj.World
        $skyTexture = $this.world.Map.SkyTexture
        if ($null -ne $skyTexture) {
            $this.renderSkyWidth = $skyTexture.Width
            if (($this.renderSkyWidth -gt 0) -and (($this.renderSkyWidth -band ($this.renderSkyWidth - 1)) -eq 0)) {
                $this.renderSkyMask = $this.renderSkyWidth - 1
            } else {
                $this.renderSkyMask = -1
            }
            $this.renderSkyColumns = $skyTexture.Composite.Columns
        } else {
            $this.renderSkyWidth = 0
            $this.renderSkyMask = -1
            $this.renderSkyColumns = $null
        }

        $this.viewX = $player.Mobj.GetInterpolatedX($frameFrac)
        $this.viewY = $player.Mobj.GetInterpolatedY($frameFrac)
        $this.viewZ = $player.GetInterpolatedViewZ($frameFrac)
        $this.viewAngle = $player.GetInterpolatedAngle($frameFrac)
        $this.viewXData = $this.viewX.Data
        $this.viewYData = $this.viewY.Data
        $this.viewZData = $this.viewZ.Data
        $this.viewNegYData = [Fixed]::ToInt32Unchecked(-[long]$this.viewYData)
        $this.viewAngleData = $this.viewAngle.Data

        $this.viewSin = [Trig]::Sin($this.viewAngle)
        $this.viewCos = [Trig]::Cos($this.viewAngle)
        $this.UpdateViewColumnTrigData()

        $this.validCount = $this.world.GetNewValidCount()

        $this.extraLight = $player.ExtraLight
        $this.fixedColorMap = $player.FixedColorMap

        $this.ClearPlaneRendering()
        $this.ClearLighting()
        $this.ClearRenderingHistory()
        $this.ClearSpriteRendering()
        $this.debugSubsectorCount = 0
        $this.debugSegCount = 0
        $this.debugSolidWallCount = 0
        $this.debugPassWallCount = 0
        $phaseStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.PerfThreeDTicksSetup += ($phaseStart - $perfThreeDStart)

        $bspStart = $phaseStart
        $this.RenderBspNode($this.world.Map.Nodes.Length - 1)
        $this.PerfThreeDTicksBsp += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $bspStart)

        $spritesStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.RenderSprites()
        $this.PerfThreeDTicksSprites += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $spritesStart)

        $maskedStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.RenderMaskedTextures()
        $this.PerfThreeDTicksMasked += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $maskedStart)

        $playerSpritesStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.DrawPlayerSprites($player)
        $this.PerfThreeDTicksPlayerSprites += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $playerSpritesStart)

        if ($this.windowSize -lt 7) {
            $backScreenStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
            $this.FillBackScreen()
            $this.PerfThreeDTicksBackScreen += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $backScreenStart)
        }

        $this.PerfThreeDTicksTotal += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $perfThreeDStart)
        $this.PerfThreeDFrames++
        if ($this.perfThreeDSampleFrame) {
            $this.PerfThreeDSampleFrames++
        }
        $this.PerfThreeDSubsectors += $this.debugSubsectorCount
        $this.PerfThreeDSegs += $this.debugSegCount
        $this.PerfThreeDSolidWalls += $this.debugSolidWallCount
        $this.PerfThreeDPassWalls += $this.debugPassWallCount
        $this.PerfThreeDVisWalls += $this.visWallRangeCount
        $this.PerfThreeDVisSprites += $this.visSpriteCount

        if (($this.PerfThreeDFrames % 30) -eq 0) {
            $sampleFrames = [double]$this.PerfThreeDSampleFrames
            if ($sampleFrames -lt 1.0) {
                $sampleFrames = 1.0
            }
            [Console]::WriteLine(
                ("ThreeDPerf frames={0} avgTicks total={1:N0} setup={2:N0} bsp={3:N0} sprites={4:N0} masked={5:N0} player={6:N0} back={7:N0} avgSubsectors={8:N1} avgSegs={9:N1} avgSolid={10:N1} avgPass={11:N1} avgWalls={12:N1} avgSprites={13:N1}" -f
                    $this.PerfThreeDFrames,
                    ($this.PerfThreeDTicksTotal / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksSetup / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksBsp / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksSprites / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksMasked / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksPlayerSprites / $this.PerfThreeDFrames),
                    ($this.PerfThreeDTicksBackScreen / $this.PerfThreeDFrames),
                    ($this.PerfThreeDSubsectors / [double]$this.PerfThreeDFrames),
                    ($this.PerfThreeDSegs / [double]$this.PerfThreeDFrames),
                    ($this.PerfThreeDSolidWalls / [double]$this.PerfThreeDFrames),
                    ($this.PerfThreeDPassWalls / [double]$this.PerfThreeDFrames),
                    ($this.PerfThreeDVisWalls / [double]$this.PerfThreeDFrames),
                    ($this.PerfThreeDVisSprites / [double]$this.PerfThreeDFrames)))
            [Console]::WriteLine(
                ("ThreeDPerfBsp frames={0} avgTicks drawSeg={1:N0} solidRange={2:N0} passRange={3:N0} addSprites={4:N0}" -f
                    $this.PerfThreeDFrames,
                    ($this.PerfThreeDTicksDrawSeg / $sampleFrames),
                    ($this.PerfThreeDTicksSolidRange / $sampleFrames),
                    ($this.PerfThreeDTicksPassRange / $sampleFrames),
                    ($this.PerfThreeDTicksAddSprites / $sampleFrames)))
        }
    }

    [Flat] GetFlatForRender([int] $flatNumber) {
        if ($flatNumber -lt 0) {
            return $null
        }

        $localFlatArray = $this.flatArray
        if ($null -ne $localFlatArray) {
            if ($flatNumber -lt $localFlatArray.Length) {
                return $localFlatArray[$flatNumber]
            }

            return $null
        }

        try {
            return $this.flats.get_Item($flatNumber)
        } catch {
            return $null
        }
    }

    hidden [byte[]] GetFlatDataForRender([int] $flatNumber) {
        if ($flatNumber -ge 0) {
            $localFlatDataArray = $this.flatDataArray
            if ($null -ne $localFlatDataArray -and $flatNumber -lt $localFlatDataArray.Length) {
                $flatData = $localFlatDataArray[$flatNumber]
                if ($null -ne $flatData) {
                    return $flatData
                }
            }

            $flat = $this.GetFlatForRender($flatNumber)
            if ($null -ne $flat -and $null -ne $flat.Data) {
                return $flat.Data
            }
        }

        return $this.emptyFlatData
    }

    [void] RenderBspNode([int] $node) {
        if ([Node]::IsSubsector($node)) {
            if ($node -eq -1) {
                $this.DrawSubsector(0)
            } else {
                $this.DrawSubsector([Node]::GetSubsector($node))
            }
            return
        }

        $bsp = $this.world.Map.Nodes[$node]

        # Decide which side the view point is on.
        $side = [Geometry]::PointOnSide($this.viewX, $this.viewY, $bsp)

        # Recursively divide front space.
        $this.RenderBspNode($bsp.Children[$side])

        # Possibly divide back space.
        if ($this.IsPotentiallyVisible($bsp.BoundingBox[$side -bxor 1])) {
            $this.RenderBspNode($bsp.Children[$side -bxor 1])
        }
    }

    [void] DrawSubsector([int] $subsector) {
        $target = $this.world.Map.Subsectors[$subsector]
        $this.debugSubsectorCount++
        $this.debugSegCount += $target.SegCount
        $samplePerfFrame = $this.perfThreeDSampleFrame

        if ($samplePerfFrame) {
            $perfAddSpritesStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
            $this.AddSprites($target.Sector, $this.validCount)
            $this.PerfThreeDTicksAddSprites += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $perfAddSpritesStart)
            $perfDrawSegStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
            for ($i = 0; $i -lt $target.SegCount; $i++) {
                $this.DrawSeg($this.world.Map.Segs[$target.FirstSeg + $i])
            }
            $this.PerfThreeDTicksDrawSeg += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $perfDrawSegStart)
        } else {
            $this.AddSprites($target.Sector, $this.validCount)
            for ($i = 0; $i -lt $target.SegCount; $i++) {
                $this.DrawSeg($this.world.Map.Segs[$target.FirstSeg + $i])
            }
        }
    }

    static [int[][]] $viewPosToFrustumTangent = @(
        @(3, 0, 2, 1),
        @(3, 0, 2, 0),
        @(3, 1, 2, 0),
        @(0),
        @(2, 0, 2, 1),
        @(0, 0, 0, 0),
        @(3, 1, 3, 0),
        @(0),
        @(2, 0, 3, 1),
        @(2, 1, 3, 1),
        @(2, 1, 3, 0)
    )

    [bool] IsPotentiallyVisible([Fixed[]] $bbox) {
        [int] $bx = 0
        [int] $by = 0

        # Find the corners of the box that define the edges from current viewpoint.
        if ($this.viewXData -le $bbox[[Box]::Left].Data) {
            $bx = 0
        } elseif ($this.viewXData -lt $bbox[[Box]::Right].Data) {
            $bx = 1
        } else {
            $bx = 2
        }

        if ($this.viewYData -ge $bbox[[Box]::Top].Data) {
            $by = 0
        } elseif ($this.viewYData -gt $bbox[[Box]::Bottom].Data) {
            $by = 1
        } else {
            $by = 2
        }

        $viewPos = ($by -shl 2) + $bx
        if ($viewPos -eq 5) {
            return $true
        }

        $x1 = $bbox[[ThreeDRenderer]::viewPosToFrustumTangent[$viewPos][0]]
        $y1 = $bbox[[ThreeDRenderer]::viewPosToFrustumTangent[$viewPos][1]]
        $x2 = $bbox[[ThreeDRenderer]::viewPosToFrustumTangent[$viewPos][2]]
        $y2 = $bbox[[ThreeDRenderer]::viewPosToFrustumTangent[$viewPos][3]]

        # Check clip list for an open space.
        $angle1 = [Geometry]::PointToAngle($this.viewX, $this.viewY, $x1, $y1) - $this.viewAngle
        $angle2 = [Geometry]::PointToAngle($this.viewX, $this.viewY, $x2, $y2) - $this.viewAngle

        $span = $angle1 - $angle2

        # Sitting on a line?
        if ($span.Data -ge [Angle]::Ang180.Data) {
            return $true
        }

        $tSpan1 = $angle1 + $this.clipAngle

        if ($tSpan1.Data -gt $this.clipAngle2.Data) {
            $tSpan1 -= $this.clipAngle2

            # Totally off the left edge?
            if ($tSpan1.Data -ge $span.Data) {
                return $false
            }

            $angle1 = $this.clipAngle
        }

        $tSpan2 = $this.clipAngle - $angle2
        if ($tSpan2.Data -gt $this.clipAngle2.Data) {
            $tSpan2 -= $this.clipAngle2

            # Totally off the left edge?
            if ($tSpan2.Data -ge $span.Data) {
                return $false
            }

            $angle2 = -$this.clipAngle
        }

        # Find the first clippost that touches the source post (adjacent pixels are touching).
        $sx1 = $this.angleToX[($angle1 + [Angle]::Ang90).Data -shr [Trig]::AngleToFineShift]
        $sx2 = $this.angleToX[($angle2 + [Angle]::Ang90).Data -shr [Trig]::AngleToFineShift]

        # Does not cross a pixel.
        if ($sx1 -eq $sx2) {
            return $false
        }

        $sx2--

        $start = 0
        while ($this.clipRanges[$start].Last -lt $sx2) {
            $start++
        }

        if ($sx1 -ge $this.clipRanges[$start].First -and $sx2 -le $this.clipRanges[$start].Last) {
            # The clippost contains the new span.
            return $false
        }

        return $true
    }
    ############################################################
    # Segment rendering
    ############################################################

    [void] DrawSeg([Seg] $seg) {
        # OPTIMIZE: quickly reject orthogonal back sides.
        $angle1 = [Geometry]::PointToAngle($this.viewX, $this.viewY, $seg.Vertex1.X, $seg.Vertex1.Y)
        $angle2 = [Geometry]::PointToAngle($this.viewX, $this.viewY, $seg.Vertex2.X, $seg.Vertex2.Y)

        # Clip to view edges.
        $span = $angle1 - $angle2

        # Backface culling.
        if ($span.Data -ge [Angle]::Ang180.Data) {
            return
        }

        # Global angle needed by segcalc.
        $rwAngle1 = $angle1

        $angle1 -= $this.viewAngle
        $angle2 -= $this.viewAngle

        $tSpan1 = $angle1 + $this.clipAngle
        if ($tSpan1.Data -gt $this.clipAngle2.Data) {
            $tSpan1 -= $this.clipAngle2

            if ($tSpan1.Data -ge $span.Data) {
                return
            }

            $angle1 = $this.clipAngle
        }

        $tSpan2 = $this.clipAngle - $angle2
        if ($tSpan2.Data -gt $this.clipAngle2.Data) {
            $tSpan2 -= $this.clipAngle2

            if ($tSpan2.Data -ge $span.Data) {
                return
            }

            $angle2 = -$this.clipAngle
        }

        # Determine x-coordinates in screen space.
        $x1 = $this.angleToX[($angle1 + [Angle]::Ang90).Data -shr [Trig]::AngleToFineShift]
        $x2 = $this.angleToX[($angle2 + [Angle]::Ang90).Data -shr [Trig]::AngleToFineShift]

        if ($x1 -eq $x2) {
            return
        }

        $frontSector = $seg.FrontSector
        $backSector = $seg.BackSector

        $frontSectorFloorHeight = $frontSector.GetInterpolatedFloorHeight($this.frameFrac)
        $frontSectorCeilingHeight = $frontSector.GetInterpolatedCeilingHeight($this.frameFrac)

        if ($null -eq $backSector) {
            $this.DrawSolidWall($seg, $rwAngle1, $x1, $x2 - 1)
            return
        }

        $backSectorFloorHeight = $backSector.GetInterpolatedFloorHeight($this.frameFrac)
        $backSectorCeilingHeight = $backSector.GetInterpolatedCeilingHeight($this.frameFrac)

        if ($backSectorCeilingHeight.Data -le $frontSectorFloorHeight.Data -or
            $backSectorFloorHeight.Data -ge $frontSectorCeilingHeight.Data) {
            $this.DrawSolidWall($seg, $rwAngle1, $x1, $x2 - 1)
            return
        }

        if ($backSectorCeilingHeight.Data -ne $frontSectorCeilingHeight.Data -or
            $backSectorFloorHeight.Data -ne $frontSectorFloorHeight.Data) {
            $this.DrawPassWall($seg, $rwAngle1, $x1, $x2 - 1)
            return
        }

        if ($backSector.CeilingFlat -eq $frontSector.CeilingFlat -and
            $backSector.FloorFlat -eq $frontSector.FloorFlat -and
            $backSector.LightLevel -eq $frontSector.LightLevel -and
            $seg.SideDef.MiddleTexture -eq 0) {
            return
        }

        $this.DrawPassWall($seg, $rwAngle1, $x1, $x2 - 1)
    }

    [void] DrawSolidWall([Seg] $seg, [Angle] $rwAngle1, [int] $x1, [int] $x2) {
        $start = 0
        while ($this.clipRanges[$start].Last -lt ($x1 - 1)) {
            $start++
        }

        if ($x1 -lt $this.clipRanges[$start].First) {
            if ($x2 -lt ($this.clipRanges[$start].First - 1)) {
                $this.DrawSolidWallRange($seg, $rwAngle1, $x1, $x2)
                $next = $this.clipRangeCount
                $this.clipRangeCount++

                while ($next -ne $start) {
                    $this.clipRanges[$next].CopyFrom($this.clipRanges[$next - 1])
                    $next--
                }
                $this.clipRanges[$next].First = $x1
                $this.clipRanges[$next].Last = $x2
                return
            }

            $this.DrawSolidWallRange($seg, $rwAngle1, $x1, $this.clipRanges[$start].First - 1)
            $this.clipRanges[$start].First = $x1
        }

        if ($x2 -le $this.clipRanges[$start].Last) {
            return
        }

        $next = $start
        while ($x2 -ge ($this.clipRanges[$next + 1].First - 1)) {
            $this.DrawSolidWallRange($seg, $rwAngle1, $this.clipRanges[$next].Last + 1, $this.clipRanges[$next + 1].First - 1)
            $next++

            if ($x2 -le $this.clipRanges[$next].Last) {
                $this.clipRanges[$start].Last = $this.clipRanges[$next].Last
                break
            }
        }
        if ($x2 -gt $this.clipRanges[$next].Last) {
            $this.DrawSolidWallRange($seg, $rwAngle1, $this.clipRanges[$next].Last + 1, $x2)
            $this.clipRanges[$start].Last = $x2
        }

        if ($next -eq $start) {
            return
        }

        while ($next -ne $this.clipRangeCount) {
            $next++
            $start++
            $this.clipRanges[$start].CopyFrom($this.clipRanges[$next])
        }

        $this.clipRangeCount = $start + 1
    }

    [void] DrawPassWall([Seg] $seg, [Angle] $rwAngle1, [int] $x1, [int] $x2) {
        $start = 0
        while ($this.clipRanges[$start].Last -lt ($x1 - 1)) {
            $start++
        }

        if ($x1 -lt $this.clipRanges[$start].First) {
            if ($x2 -lt ($this.clipRanges[$start].First - 1)) {
                $this.DrawPassWallRange($seg, $rwAngle1, $x1, $x2, $false)
                return
            }
            $this.DrawPassWallRange($seg, $rwAngle1, $x1, $this.clipRanges[$start].First - 1, $false)
        }

        if ($x2 -le $this.clipRanges[$start].Last) {
            return
        }

        while ($x2 -ge ($this.clipRanges[$start + 1].First - 1)) {
            $this.DrawPassWallRange($seg, $rwAngle1, $this.clipRanges[$start].Last + 1, $this.clipRanges[$start + 1].First - 1, $false)
            $start++

            if ($x2 -le $this.clipRanges[$start].Last) {
                return
            }
        }

        $this.DrawPassWallRange($seg, $rwAngle1, $this.clipRanges[$start].Last + 1, $x2, $false)
    }
    ############################################################
    # Scale Calculation
    ############################################################

    [Fixed] ScaleFromGlobalAngle([Angle] $visAngle, [Angle] $viewAngle, [Angle] $rwNormal, [Fixed] $rwDistance) {
        $num = $this.projection * [Trig]::Sin([Angle]::Ang90 + ($visAngle - $rwNormal))
        $den = $rwDistance * [Trig]::Sin([Angle]::Ang90 + ($visAngle - $viewAngle))

        if ($den.Data -gt ($num.Data -shr 16)) {
            $scale = $num / $den

            if ($scale.Data -gt [Fixed]::FromInt(64).Data) {
                return [Fixed]::FromInt(64)
            } elseif ($scale.Data -lt 256) {
                return [Fixed]::new(256)
            } else {
                return $scale
            }
        } else {
            return [Fixed]::FromInt(64)
        }
    }

    ############################################################
    # Wall Rendering
    ############################################################

    static [int] $heightBits = 12
    static [int] $heightUnit = 1 -shl 12
    static [int] ClampZLightIndex([Fixed] $distance) {
        $index = $distance.Data -shr [ThreeDRenderer]::zLightShift
        if ($index -lt 0) {
            return 0
        }
        if ($index -ge [ThreeDRenderer]::maxZLight) {
            return [ThreeDRenderer]::maxZLight - 1
        }
        return $index
    }

    [void] DrawSolidWallRange([Seg] $seg, [Angle] $rwAngle1, [int] $x1, [int] $x2) {
        if ($x2 -lt $x1) {
            return
        }

        if ($null -ne $seg.BackSector) {
            $this.DrawPassWallRange($seg, $rwAngle1, $x1, $x2, $true)
            return
        }

        if ($this.visWallRangeCount -eq $this.visWallRanges.Length) {
            # Too many visible walls.
            return
        }

        $samplePerfFrame = $this.perfThreeDSampleFrame
        [long] $perfSolidRangeStart = 0
        if ($samplePerfFrame) {
            $perfSolidRangeStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        }

        # Make some aliases to shorten the following code.
        $line = $seg.LineDef
        $side = $seg.SideDef
        $frontSector = $seg.FrontSector

        $frontSectorFloorHeight = $frontSector.GetInterpolatedFloorHeight($this.frameFrac)
        $frontSectorCeilingHeight = $frontSector.GetInterpolatedCeilingHeight($this.frameFrac)

        # Mark the segment as visible for auto map.
        $line.Flags = $line.Flags -bor [LineFlags]::Mapped

        # Calculate the relative plane heights of front and back sector.
        $worldFrontZ1 = $frontSectorCeilingHeight - $this.viewZ
        $worldFrontZ2 = $frontSectorFloorHeight - $this.viewZ

        # Check which parts must be rendered.
        $drawWall = $side.MiddleTexture -ne 0
        $drawCeiling = $worldFrontZ1.Data -gt [Fixed]::Zero.Data -or $frontSector.CeilingFlat -eq $this.skyFlatNumber
        $drawFloor = $worldFrontZ2.Data -lt [Fixed]::Zero.Data

        # Determine how the wall textures are vertically aligned.
        $wallTexture = $this.textures.get_Item($this.world.Specials.TextureTranslation[$side.MiddleTexture])
        $wallWidth = $wallTexture.Width

        if (($line.Flags -band [LineFlags]::DontPegBottom) -ne 0) {
            $vTop = $frontSectorFloorHeight + [Fixed]::FromInt($wallTexture.Height)
            $middleTextureAlt = $vTop - $this.viewZ
        } else {
            $middleTextureAlt = $worldFrontZ1
        }
        $middleTextureAlt += $side.RowOffset
        [int] $middleTextureAltData = $middleTextureAlt.Data

        # Calculate the scaling factors of the left and right edges of the wall range.
        $rwNormalAngle = $seg.Angle + [Angle]::Ang90

        $offsetAngle = [Angle]::Abs($rwNormalAngle - $rwAngle1)
        if ($offsetAngle.Data -gt [Angle]::Ang90.Data) {
            $offsetAngle = [Angle]::Ang90
        }

        $distAngle = [Angle]::Ang90 - $offsetAngle
        $hypotenuse = [Geometry]::PointToDist($this.viewX, $this.viewY, $seg.Vertex1.X, $seg.Vertex1.Y)
        $rwDistance = $hypotenuse * [Trig]::Sin($distAngle)

        $rwScale = $this.ScaleFromGlobalAngle($this.viewAngle + $this.xToAngle[$x1], $this.viewAngle, $rwNormalAngle, $rwDistance)

        $scale1 = $rwScale
        if ($x2 -gt $x1) {
            $scale2 = $this.ScaleFromGlobalAngle($this.viewAngle + $this.xToAngle[$x2], $this.viewAngle, $rwNormalAngle, $rwDistance)
            $rwScaleStep = ($scale2 - $rwScale) / ($x2 - $x1)
        } else {
            $scale2 = $scale1
            $rwScaleStep = [Fixed]::Zero
        }

        # Determine horizontal alignment of textures and color maps.
        $textureOffsetAngle = $rwNormalAngle - $rwAngle1
        if ($textureOffsetAngle.Data -gt [Angle]::Ang180.Data) {
            $textureOffsetAngle = -$textureOffsetAngle
        }
        if ($textureOffsetAngle.Data -gt [Angle]::Ang90.Data) {
            $textureOffsetAngle = [Angle]::Ang90
        }

        $rwOffset = $hypotenuse * [Trig]::Sin($textureOffsetAngle)
        if (($rwNormalAngle - $rwAngle1).Data -lt [Angle]::Ang180.Data) {
            $rwOffset = -$rwOffset
        }
        $rwOffset += $seg.Offset + $side.TextureOffset
        [int] $rwOffsetData = $rwOffset.Data

        $rwCenterAngle = [Angle]::Ang90 + $this.viewAngle - $rwNormalAngle
        [uint32] $rwCenterAngleData = $rwCenterAngle.Data

        $wallLightLevel = ($frontSector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
        if ($seg.Vertex1.Y -eq $seg.Vertex2.Y) {
            $wallLightLevel--
        } elseif ($seg.Vertex1.X -eq $seg.Vertex2.X) {
            $wallLightLevel++
        }

        [byte[][]] $wallLights = $this.scaleLight[[math]::Clamp($wallLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]
        [int] $planeLightLevel = ($frontSector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
        [byte[][]] $planeLights = $this.zLight[[math]::Clamp($planeLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]
        [int] $translatedCeilingFlatNumber = [int]($this.world.Specials.FlatTranslation[$frontSector.CeilingFlat])
        [int] $translatedFloorFlatNumber = [int]($this.world.Specials.FlatTranslation[$frontSector.FloorFlat])
        [bool] $ceilingIsSky = $translatedCeilingFlatNumber -eq $this.skyFlatNumber
        [bool] $floorIsSky = $translatedFloorFlatNumber -eq $this.skyFlatNumber
        [byte[]] $ceilingFlatData = $null
        [byte[]] $floorFlatData = $null
        if ($drawCeiling -and -not $ceilingIsSky) {
            $ceilingFlatData = $this.GetFlatDataForRender($translatedCeilingFlatNumber)
        }
        if ($drawFloor -and -not $floorIsSky) {
            $floorFlatData = $this.GetFlatDataForRender($translatedFloorFlatNumber)
        }

        # Determine where on the screen the wall is drawn.
        $worldFrontZ1Data = ($worldFrontZ1 -shr 4).Data
        $worldFrontZ2Data = ($worldFrontZ2 -shr 4).Data
        $fracBits = [Fixed]::FracBits
        $centerYFracShiftedData = ($this.centerYFrac -shr 4).Data
        $rwScaleData = $rwScale.Data
        $rwScaleStepData = $rwScaleStep.Data

        $wallY1FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$worldFrontZ1Data * [long]$rwScaleData) -shr $fracBits)))
        $wallY1StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$worldFrontZ1Data) -shr $fracBits)))))
        $wallY2FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$worldFrontZ2Data * [long]$rwScaleData) -shr $fracBits)))
        $wallY2StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$worldFrontZ2Data) -shr $fracBits)))))

        # Record rendering history.
        $visWallRange = $this.visWallRanges[$this.visWallRangeCount]
        $this.visWallRangeCount++
        $this.debugSolidWallCount++

        $visWallRange.Seg = $seg
        $visWallRange.X1 = $x1
        $visWallRange.X2 = $x2
        $visWallRange.Scale1 = $scale1
        $visWallRange.Scale2 = $scale2
        $visWallRange.ScaleStep = $rwScaleStep
        $visWallRange.Silhouette = [Silhouette]::Both
        $visWallRange.LowerSilHeight = [Fixed]::MaxValue
        $visWallRange.UpperSilHeight = [Fixed]::MinValue
        $visWallRange.MaskedTextureColumn = -1
        $visWallRange.UpperClip = $this.windowHeightArray
        $visWallRange.LowerClip = $this.negOneArray
        $visWallRange.FrontSectorFloorHeight = $frontSectorFloorHeight
        $visWallRange.FrontSectorCeilingHeight = $frontSectorCeilingHeight
        
        $localUpperClip = $this.upperClip
        $localLowerClip = $this.lowerClip
        $localXToAngleData = $this.xToAngleData
        $localHeightUnit = [ThreeDRenderer]::heightUnit
        $localHeightBits = [ThreeDRenderer]::heightBits
        $localScaleLightShift = [ThreeDRenderer]::scaleLightShift
        $localMaxScaleLight = $this.maxScaleLight
        $wallColumns = $wallTexture.Composite.Columns
        [int] $wallWrapMask = -1
        if (($wallWidth -gt 0) -and (($wallWidth -band ($wallWidth - 1)) -eq 0)) {
            $wallWrapMask = $wallWidth - 1
        }
        $rwDistanceData = $rwDistance.Data

        for ($x = $x1; $x -le $x2; $x++) {
            $drawWallY1 = ($wallY1FracData + $localHeightUnit - 1) -shr $localHeightBits
            $drawWallY2 = $wallY2FracData -shr $localHeightBits
            $clipTop = $localUpperClip[$x] + 1
            $clipBottom = $localLowerClip[$x] - 1

            [int] $textureColumn = 0
            [int] $lightIndex = 0
            [int] $invScaleData = 0
            if ($drawCeiling) {
                $cy1 = $clipTop
                $cy2 = $drawWallY1 - 1
                if ($cy2 -gt $clipBottom) {
                    $cy2 = $clipBottom
                }
                if ($cy1 -le $cy2) {
                    $this.DrawCeilingColumn($frontSector, $ceilingFlatData, $ceilingIsSky, $planeLights, $x, $cy1, $cy2, $frontSectorCeilingHeight)
                }
            }

            if ($drawWall) {
                $wy1 = $drawWallY1
                if ($wy1 -lt $clipTop) {
                    $wy1 = $clipTop
                }
                $wy2 = $drawWallY2
                if ($wy2 -gt $clipBottom) {
                    $wy2 = $clipBottom
                }

                if ($wy1 -le $wy2) {
                    $angleData = [uint32]((([uint64]$rwCenterAngleData + [uint64]$localXToAngleData[$x]) -band 0xFFFFFFFFul) -band 0x7FFFFFFFul)
                    $tanData = [Trig]::TanData($angleData)
                    $textureColumnData = [Fixed]::ToInt32Unchecked(([long]$rwOffsetData) - ((([long]$tanData * [long]$rwDistanceData) -shr $fracBits)))
                    $textureColumn = $textureColumnData -shr $fracBits
                    if ($wallWrapMask -ge 0) {
                        $wallColumnIndex = $textureColumn -band $wallWrapMask
                    } else {
                        $wallColumnIndex = [ThreeDRenderer]::WrapColumnIndex($textureColumn, $wallWidth)
                    }
                    $source = $wallColumns[$wallColumnIndex]
                    if ($null -ne $source -and $source.Length -gt 0) {
                        $lightIndex = $rwScaleData -shr $localScaleLightShift
                        if ($lightIndex -ge $localMaxScaleLight) {
                            $lightIndex = $localMaxScaleLight - 1
                        }
                        $invScaleData = [int](0xFFFFFFFFu / [uint]$rwScaleData)
                        $this.DrawColumnData($source[0], $wallLights[$lightIndex], $x, $wy1, $wy2, $invScaleData, $middleTextureAltData)
                    }
                }
            }

            if ($drawFloor) {
                $fy1 = $drawWallY2 + 1
                if ($fy1 -lt $clipTop) {
                    $fy1 = $clipTop
                }
                $fy2 = $clipBottom
                if ($fy1 -le $fy2) {
                    $this.DrawFloorColumn($frontSector, $floorFlatData, $floorIsSky, $planeLights, $x, $fy1, $fy2, $frontSectorFloorHeight)
                }
            }

            $rwScaleData = [Fixed]::ToInt32Unchecked(([long]$rwScaleData + [long]$rwScaleStepData))
            $wallY1FracData = [Fixed]::ToInt32Unchecked(([long]$wallY1FracData + [long]$wallY1StepData))
            $wallY2FracData = [Fixed]::ToInt32Unchecked(([long]$wallY2FracData + [long]$wallY2StepData))
        }

        if ($samplePerfFrame) {
            $this.PerfThreeDTicksSolidRange += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $perfSolidRangeStart)
        }
    }

    ############################################################
    # Pass Wall Rendering
    ############################################################

    [void] DrawPassWallRange([Seg] $seg, [Angle] $rwAngle1, [int] $x1, [int] $x2, [bool] $drawAsSolidWall) {
        if ($x2 -lt $x1) {
            return
        }

        if ($this.visWallRangeCount -eq $this.visWallRanges.Length) {
            # Too many visible walls.
            return
        }

        $range = $x2 - $x1 + 1

        if ($this.clipDataLength + (3 * $range) -ge $this.clipData.Length) {
            # Clip info buffer is not sufficient.
            return
        }

        # Make some aliases to shorten the following code.
        $line = $seg.LineDef
        $side = $seg.SideDef
        $frontSector = $seg.FrontSector
        $backSector = $seg.BackSector

        $frontSectorFloorHeight = $frontSector.GetInterpolatedFloorHeight($this.frameFrac)
        $frontSectorCeilingHeight = $frontSector.GetInterpolatedCeilingHeight($this.frameFrac)
        $backSectorFloorHeight = $backSector.GetInterpolatedFloorHeight($this.frameFrac)
        $backSectorCeilingHeight = $backSector.GetInterpolatedCeilingHeight($this.frameFrac)

        # Mark the segment as visible for auto map.
        $line.Flags = $line.Flags -bor [LineFlags]::Mapped

        # Calculate the relative plane heights of front and back sector.
        $worldFrontZ1 = $frontSectorCeilingHeight - $this.viewZ
        $worldFrontZ2 = $frontSectorFloorHeight - $this.viewZ
        $worldBackZ1 = $backSectorCeilingHeight - $this.viewZ
        $worldBackZ2 = $backSectorFloorHeight - $this.viewZ

        # The hack below enables ceiling height change in outdoor area without showing the upper wall.
        if ($frontSector.CeilingFlat -eq $this.skyFlatNumber -and
            $backSector.CeilingFlat -eq $this.skyFlatNumber) {
            $worldFrontZ1 = $worldBackZ1
        }

        #
        # Check which parts must be rendered.
        #

        [bool] $drawUpperWall  = $false
        [bool] $drawCeiling  = $false
        if ($drawAsSolidWall -or
            $worldFrontZ1.Data -ne $worldBackZ1.Data -or
            $frontSector.CeilingFlat -ne $backSector.CeilingFlat -or
            $frontSector.LightLevel -ne $backSector.LightLevel) {
            $drawUpperWall = $side.TopTexture -ne 0 -and $worldBackZ1.Data -lt $worldFrontZ1.Data
            $drawCeiling = $worldFrontZ1.Data -ge [Fixed]::Zero.Data -or $frontSector.CeilingFlat -eq $this.skyFlatNumber
        } else {
            $drawUpperWall = $false
            $drawCeiling = $false
        }

        [bool] $drawLowerWall = $false
        [bool] $drawFloor = $false
        if ($drawAsSolidWall -or
            $worldFrontZ2.Data -ne $worldBackZ2.Data -or
            $frontSector.FloorFlat -ne $backSector.FloorFlat -or
            $frontSector.LightLevel -ne $backSector.LightLevel) {
            $drawLowerWall = $side.BottomTexture -ne 0 -and $worldBackZ2.Data -gt $worldFrontZ2.Data
            $drawFloor = $worldFrontZ2.Data -le [Fixed]::Zero.Data
        } else {
            $drawLowerWall = $false
            $drawFloor = $false
        }

        $drawMaskedTexture = $side.MiddleTexture -ne 0

        # If nothing must be rendered, we can skip this seg.
        if (-not $drawUpperWall -and -not $drawCeiling -and -not $drawLowerWall -and -not $drawFloor -and -not $drawMaskedTexture) {
            return
        }

        $samplePerfFrame = $this.perfThreeDSampleFrame
        [long] $perfPassRangeStart = 0
        if ($samplePerfFrame) {
            $perfPassRangeStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
        }

        $segTextured = $drawUpperWall -or $drawLowerWall -or $drawMaskedTexture

        #
        # Determine how the wall textures are vertically aligned (if necessary).
        #

        [Texture] $upperWallTexture = $null
        [int] $upperWallWidth = 0
        [Fixed] $uperTextureAlt = $null
        if ($drawUpperWall) {
            $upperWallTexture = $this.textures.get_Item($this.world.Specials.TextureTranslation[$side.TopTexture])
            $upperWallWidth = $upperWallTexture.Width

            if (($line.Flags -band [LineFlags]::DontPegTop) -ne 0) {
                $uperTextureAlt = $worldFrontZ1
            } else {
                $vTop = $backSectorCeilingHeight + [Fixed]::FromInt($upperWallTexture.Height)
                $uperTextureAlt = $vTop - $this.viewZ
            }
            $uperTextureAlt += $side.RowOffset
        }
        [int] $upperTextureAltData = 0
        if ($drawUpperWall) {
            $upperTextureAltData = $uperTextureAlt.Data
        }

        [Texture] $lowerWallTexture = $null
        [int] $lowerWallWidth = 0
        [Fixed] $lowerTextureAlt = $null
        if ($drawLowerWall) {
            $lowerWallTexture = $this.textures.get_Item($this.world.Specials.TextureTranslation[$side.BottomTexture])
            $lowerWallWidth = $lowerWallTexture.Width

            if (($line.Flags -band [LineFlags]::DontPegBottom) -ne 0) {
                $lowerTextureAlt = $worldFrontZ1
            } else {
                $lowerTextureAlt = $worldBackZ2
            }
            $lowerTextureAlt += $side.RowOffset
        }
        [int] $lowerTextureAltData = 0
        if ($drawLowerWall) {
            $lowerTextureAltData = $lowerTextureAlt.Data
        }
        #
        # Calculate the scaling factors of the left and right edges of the wall range.
        #

        $rwNormalAngle = $seg.Angle + [Angle]::Ang90

        $offsetAngle = [Angle]::Abs($rwNormalAngle - $rwAngle1)
        if ($offsetAngle.Data -gt [Angle]::Ang90.Data) {
            $offsetAngle = [Angle]::Ang90
        }

        $distAngle = [Angle]::Ang90 - $offsetAngle

        $hypotenuse = [Geometry]::PointToDist($this.viewX, $this.viewY, $seg.Vertex1.X, $seg.Vertex1.Y)

        $rwDistance = $hypotenuse * [Trig]::Sin($distAngle)

        $rwScale = $this.ScaleFromGlobalAngle($this.viewAngle + $this.xToAngle[$x1], $this.viewAngle, $rwNormalAngle, $rwDistance)

        [Fixed] $scale1 = $rwScale
        [Fixed] $scale2 = $null
        [Fixed] $rwScaleStep = $null
        if ($x2 -gt $x1) {
            $scale2 = $this.ScaleFromGlobalAngle($this.viewAngle + $this.xToAngle[$x2], $this.viewAngle, $rwNormalAngle, $rwDistance)
            $rwScaleStep = ($scale2 - $rwScale) / ($x2 - $x1)
        } else {
            $scale2 = $scale1
            $rwScaleStep = [Fixed]::Zero
        }

        #
        # Determine how the wall textures are horizontally aligned
        # and which color map is used according to the light level (if necessary).
        #

        [Fixed] $rwOffset = $null
        [int] $rwOffsetData = 0
        [Angle] $rwCenterAngle = $null
        [uint32] $rwCenterAngleData = 0
        [byte[][]] $wallLights = $null
        if ($segTextured) {
            $textureOffsetAngle = $rwNormalAngle - $rwAngle1
            if ($textureOffsetAngle.Data -gt [Angle]::Ang180.Data) {
                $textureOffsetAngle = -$textureOffsetAngle
            }
            if ($textureOffsetAngle.Data -gt [Angle]::Ang90.Data) {
                $textureOffsetAngle = [Angle]::Ang90
            }

            $rwOffset = $hypotenuse * [Trig]::Sin($textureOffsetAngle)
            if (($rwNormalAngle - $rwAngle1).Data -lt [Angle]::Ang180.Data) {
                $rwOffset = -$rwOffset
            }
            $rwOffset += $seg.Offset + $side.TextureOffset
            $rwOffsetData = $rwOffset.Data

            $rwCenterAngle = [Angle]::Ang90 + $this.viewAngle - $rwNormalAngle
            $rwCenterAngleData = $rwCenterAngle.Data

            $wallLightLevel = ($frontSector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
            if ($seg.Vertex1.Y -eq $seg.Vertex2.Y) {
                $wallLightLevel--
            } elseif ($seg.Vertex1.X -eq $seg.Vertex2.X) {
                $wallLightLevel++
            }

            $wallLights = $this.scaleLight[[math]::Clamp($wallLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]
        }

        #
        # Determine where on the screen the wall is drawn.
        #

        # These values are right shifted to avoid overflow in the following process.
        $worldFrontZ1Data = ($worldFrontZ1 -shr 4).Data
        $worldFrontZ2Data = ($worldFrontZ2 -shr 4).Data
        $worldBackZ1Data = ($worldBackZ1 -shr 4).Data
        $worldBackZ2Data = ($worldBackZ2 -shr 4).Data

        $fracBits = [Fixed]::FracBits
        $centerYFracShiftedData = ($this.centerYFrac -shr 4).Data
        $rwScaleData = $rwScale.Data
        $rwScaleStepData = $rwScaleStep.Data

        # The Y positions of the top / bottom edges of the wall on the screen.
        $wallY1FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$worldFrontZ1Data * [long]$rwScaleData) -shr $fracBits)))
        $wallY1StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$worldFrontZ1Data) -shr $fracBits)))))
        $wallY2FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$worldFrontZ2Data * [long]$rwScaleData) -shr $fracBits)))
        $wallY2StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$worldFrontZ2Data) -shr $fracBits)))))

        # The Y position of the top edge of the portal (if visible).
        [int] $portalY1FracData = 0
        [int] $portalY1StepData = 0
        if ($drawUpperWall) {
            [int] $portalTopWorldData = 0
            if ($worldBackZ1Data -gt $worldFrontZ2Data) {
                $portalTopWorldData = $worldBackZ1Data
            } else {
                $portalTopWorldData = $worldFrontZ2Data
            }
            $portalY1FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$portalTopWorldData * [long]$rwScaleData) -shr $fracBits)))
            $portalY1StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$portalTopWorldData) -shr $fracBits)))))
        }

        # The Y position of the bottom edge of the portal (if visible).
        [int] $portalY2FracData = 0
        [int] $portalY2StepData = 0
        if ($drawLowerWall) {
            [int] $portalBottomWorldData = 0
            if ($worldBackZ2Data -lt $worldFrontZ1Data) {
                $portalBottomWorldData = $worldBackZ2Data
            } else {
                $portalBottomWorldData = $worldFrontZ1Data
            }
            $portalY2FracData = [Fixed]::ToInt32Unchecked([long]$centerYFracShiftedData - ((([long]$portalBottomWorldData * [long]$rwScaleData) -shr $fracBits)))
            $portalY2StepData = [Fixed]::ToInt32Unchecked(-((((([long]$rwScaleStepData * [long]$portalBottomWorldData) -shr $fracBits)))))
        }
        #
        # Determine which color map is used for the plane according to the light level.
        #

        $planeLightLevel = ($frontSector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
        $planeLights = $this.zLight[[math]::Clamp($planeLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]

        #
        # Prepare to record the rendering history.
        #

        $visWallRange = $this.visWallRanges[$this.visWallRangeCount]
        $this.visWallRangeCount++
        $this.debugPassWallCount++

        $visWallRange.Seg = $seg
        $visWallRange.X1 = $x1
        $visWallRange.X2 = $x2
        $visWallRange.Scale1 = $scale1
        $visWallRange.Scale2 = $scale2
        $visWallRange.ScaleStep = $rwScaleStep

        $visWallRange.UpperClip = -1
        $visWallRange.LowerClip = -1
        $visWallRange.Silhouette = 0

        if ($frontSectorFloorHeight.Data -gt $backSectorFloorHeight.Data) {
            $visWallRange.Silhouette = [Silhouette]::Lower
            $visWallRange.LowerSilHeight = $frontSectorFloorHeight
        } elseif ($backSectorFloorHeight.Data -gt $this.viewZData) {
            $visWallRange.Silhouette = [Silhouette]::Lower
            $visWallRange.LowerSilHeight = [Fixed]::MaxValue
        }

        if ($frontSectorCeilingHeight.Data -lt $backSectorCeilingHeight.Data) {
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Upper
            $visWallRange.UpperSilHeight = $frontSectorCeilingHeight
        } elseif ($backSectorCeilingHeight.Data -lt $this.viewZData) {
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Upper
            $visWallRange.UpperSilHeight = [Fixed]::MinValue
        }

        if ($backSectorCeilingHeight.Data -le $frontSectorFloorHeight.Data) {
            $visWallRange.LowerClip = $this.negOneArray
            $visWallRange.LowerSilHeight = [Fixed]::MaxValue
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Lower
        }

        if ($backSectorFloorHeight.Data -ge $frontSectorCeilingHeight.Data) {
            $visWallRange.UpperClip = $this.windowHeightArray
            $visWallRange.UpperSilHeight = [Fixed]::MinValue
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Upper
        }

        [int] $maskedTextureColumn = 0
        if ($drawMaskedTexture) {
            $maskedTextureColumn = $this.clipDataLength - $x1
            $visWallRange.MaskedTextureColumn = $maskedTextureColumn
            $this.clipDataLength += $range
        } else {
            $visWallRange.MaskedTextureColumn = -1
        }

        $visWallRange.FrontSectorFloorHeight = $frontSectorFloorHeight
        $visWallRange.FrontSectorCeilingHeight = $frontSectorCeilingHeight
        $visWallRange.BackSectorFloorHeight = $backSectorFloorHeight
        $visWallRange.BackSectorCeilingHeight = $backSectorCeilingHeight
        #
        # Floor and ceiling.
        #

        [int] $translatedCeilingFlatNumber = [int]($this.world.Specials.FlatTranslation[$frontSector.CeilingFlat])
        [int] $translatedFloorFlatNumber = [int]($this.world.Specials.FlatTranslation[$frontSector.FloorFlat])
        [bool] $ceilingIsSky = $translatedCeilingFlatNumber -eq $this.skyFlatNumber
        [bool] $floorIsSky = $translatedFloorFlatNumber -eq $this.skyFlatNumber
        [byte[]] $ceilingFlatData = $null
        [byte[]] $floorFlatData = $null
        if ($drawCeiling -and -not $ceilingIsSky) {
            $ceilingFlatData = $this.GetFlatDataForRender($translatedCeilingFlatNumber)
        }
        if ($drawFloor -and -not $floorIsSky) {
            $floorFlatData = $this.GetFlatDataForRender($translatedFloorFlatNumber)
        }

        #
        # Now the rendering is carried out.
        #

        $localUpperClip = $this.upperClip
        $localLowerClip = $this.lowerClip
        $localClipData = $this.clipData
        $localXToAngleData = $this.xToAngleData
        $localHeightUnit = [ThreeDRenderer]::heightUnit
        $localHeightBits = [ThreeDRenderer]::heightBits
        $localScaleLightShift = [ThreeDRenderer]::scaleLightShift
        $localMaxScaleLight = $this.maxScaleLight
        $upperWallColumns = $null
        [int] $upperWallWrapMask = -1
        if ($drawUpperWall) {
            $upperWallColumns = $upperWallTexture.Composite.Columns
            if (($upperWallWidth -gt 0) -and (($upperWallWidth -band ($upperWallWidth - 1)) -eq 0)) {
                $upperWallWrapMask = $upperWallWidth - 1
            }
        }
        $lowerWallColumns = $null
        [int] $lowerWallWrapMask = -1
        if ($drawLowerWall) {
            $lowerWallColumns = $lowerWallTexture.Composite.Columns
            if (($lowerWallWidth -gt 0) -and (($lowerWallWidth -band ($lowerWallWidth - 1)) -eq 0)) {
                $lowerWallWrapMask = $lowerWallWidth - 1
            }
        }
        $rwDistanceData = $rwDistance.Data

        for ($x = $x1; $x -le $x2; $x++) {
            $drawWallY1 = ($wallY1FracData + $localHeightUnit - 1) -shr $localHeightBits
            $drawWallY2 = $wallY2FracData -shr $localHeightBits
            $clipTop = $localUpperClip[$x] + 1
            $clipBottom = $localLowerClip[$x] - 1

            [int] $textureColumn = 0
            [int] $lightIndex = 0
            [int] $invScaleData = 0
            if ($segTextured) {
                $angleData = [uint32]((([uint64]$rwCenterAngleData + [uint64]$localXToAngleData[$x]) -band 0xFFFFFFFFul) -band 0x7FFFFFFFul)
                $tanData = [Trig]::TanData($angleData)
                $textureColumnData = [Fixed]::ToInt32Unchecked(([long]$rwOffsetData) - ((([long]$tanData * [long]$rwDistanceData) -shr $fracBits)))
                $textureColumn = $textureColumnData -shr $fracBits

                $lightIndex = $rwScaleData -shr $localScaleLightShift
                if ($lightIndex -ge $localMaxScaleLight) {
                    $lightIndex = $localMaxScaleLight - 1
                }

                $invScaleData = [int](0xFFFFFFFFu / [uint]$rwScaleData)
            }

            if ($drawUpperWall) {
                $drawUpperWallY1 = $drawWallY1
                $drawUpperWallY2 = $portalY1FracData -shr $localHeightBits

                if ($drawCeiling) {
                    $cy1 = $clipTop
                    $cy2 = $drawWallY1 - 1
                    if ($cy2 -gt $clipBottom) {
                        $cy2 = $clipBottom
                    }
                    if ($cy1 -le $cy2) {
                        $this.DrawCeilingColumn($frontSector, $ceilingFlatData, $ceilingIsSky, $planeLights, $x, $cy1, $cy2, $frontSectorCeilingHeight)
                    }
                }

                $wy1 = $drawUpperWallY1
                if ($wy1 -lt $clipTop) {
                    $wy1 = $clipTop
                }
                $wy2 = $drawUpperWallY2
                if ($wy2 -gt $clipBottom) {
                    $wy2 = $clipBottom
                }
                if ($wy1 -le $wy2) {
                    if ($upperWallWrapMask -ge 0) {
                        $wallColumnIndex = $textureColumn -band $upperWallWrapMask
                    } else {
                        $wallColumnIndex = [ThreeDRenderer]::WrapColumnIndex($textureColumn, $upperWallWidth)
                    }
                    $source = $upperWallColumns[$wallColumnIndex]
                    if ($null -ne $source -and $source.Length -gt 0) {
                        $this.DrawColumnData($source[0], $wallLights[$lightIndex], $x, $wy1, $wy2, $invScaleData, $upperTextureAltData)
                    }
                }

                if ($localUpperClip[$x] -lt $wy2) {
                    $localUpperClip[$x] = [short]$wy2
                    $clipTop = $wy2 + 1
                }

                $portalY1FracData = [Fixed]::ToInt32Unchecked(([long]$portalY1FracData + [long]$portalY1StepData))
            } elseif ($drawCeiling) {
                $cy1 = $clipTop
                $cy2 = $drawWallY1 - 1
                if ($cy2 -gt $clipBottom) {
                    $cy2 = $clipBottom
                }
                if ($cy1 -le $cy2) {
                    $this.DrawCeilingColumn($frontSector, $ceilingFlatData, $ceilingIsSky, $planeLights, $x, $cy1, $cy2, $frontSectorCeilingHeight)
                }

                if ($localUpperClip[$x] -lt $cy2) {
                    $localUpperClip[$x] = [short]$cy2
                    $clipTop = $cy2 + 1
                }
            }

            if ($drawLowerWall) {
                $drawLowerWallY1 = ($portalY2FracData + $localHeightUnit - 1) -shr $localHeightBits
                $drawLowerWallY2 = $drawWallY2

                $wy1 = $drawLowerWallY1
                if ($wy1 -lt $clipTop) {
                    $wy1 = $clipTop
                }
                $wy2 = $drawLowerWallY2
                if ($wy2 -gt $clipBottom) {
                    $wy2 = $clipBottom
                }
                if ($wy1 -le $wy2) {
                    if ($lowerWallWrapMask -ge 0) {
                        $wallColumnIndex = $textureColumn -band $lowerWallWrapMask
                    } else {
                        $wallColumnIndex = [ThreeDRenderer]::WrapColumnIndex($textureColumn, $lowerWallWidth)
                    }
                    $source = $lowerWallColumns[$wallColumnIndex]
                    if ($null -ne $source -and $source.Length -gt 0) {
                        $this.DrawColumnData($source[0], $wallLights[$lightIndex], $x, $wy1, $wy2, $invScaleData, $lowerTextureAltData)
                    }
                }

                if ($drawFloor) {
                    $fy1 = $drawWallY2 + 1
                    if ($fy1 -lt $clipTop) {
                        $fy1 = $clipTop
                    }
                    $fy2 = $clipBottom
                    if ($fy1 -le $fy2) {
                        $this.DrawFloorColumn($frontSector, $floorFlatData, $floorIsSky, $planeLights, $x, $fy1, $fy2, $frontSectorFloorHeight)
                    }
                }

                if ($localLowerClip[$x] -gt $wy1) {
                    $localLowerClip[$x] = [short]$wy1
                }

                $portalY2FracData = [Fixed]::ToInt32Unchecked(([long]$portalY2FracData + [long]$portalY2StepData))
            } elseif ($drawFloor) {
                $fy1 = $drawWallY2 + 1
                if ($fy1 -lt $clipTop) {
                    $fy1 = $clipTop
                }
                $fy2 = $clipBottom
                if ($fy1 -le $fy2) {
                    $this.DrawFloorColumn($frontSector, $floorFlatData, $floorIsSky, $planeLights, $x, $fy1, $fy2, $frontSectorFloorHeight)
                }

                if ($localLowerClip[$x] -gt ($drawWallY2 + 1)) {
                    $localLowerClip[$x] = [short]$fy1
                }
            }

            if ($drawMaskedTexture) {
                $localClipData[$maskedTextureColumn + $x] = [short]$textureColumn
            }

            $rwScaleData = [Fixed]::ToInt32Unchecked(([long]$rwScaleData + [long]$rwScaleStepData))
            $wallY1FracData = [Fixed]::ToInt32Unchecked(([long]$wallY1FracData + [long]$wallY1StepData))
            $wallY2FracData = [Fixed]::ToInt32Unchecked(([long]$wallY2FracData + [long]$wallY2StepData))
        }
        #
        # Save sprite clipping info.
        #

        if ((($visWallRange.Silhouette -band [Silhouette]::Upper) -ne 0 -or $drawMaskedTexture) -and 
            ($visWallRange.UpperClip -eq -1)) {
            [Array]::Copy($this.upperClip, $x1, $this.clipData, $this.clipDataLength, $range)
            $visWallRange.UpperClip = $this.clipDataLength - $x1
            $this.clipDataLength += $range #integer
        }

        if ((($visWallRange.Silhouette -band [Silhouette]::Lower) -ne 0 -or $drawMaskedTexture) -and 
            ($visWallRange.LowerClip -eq -1)) {
            [Array]::Copy($this.lowerClip, $x1, $this.clipData, $this.clipDataLength, $range)
            $visWallRange.LowerClip = $this.clipDataLength - $x1
            $this.clipDataLength += $range #integer
        }

        if ($drawMaskedTexture -and ($visWallRange.Silhouette -band [Silhouette]::Upper) -eq 0) {
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Upper
            $visWallRange.UpperSilHeight = [Fixed]::MinValue
        }

        if ($drawMaskedTexture -and ($visWallRange.Silhouette -band [Silhouette]::Lower) -eq 0) {
            $visWallRange.Silhouette = $visWallRange.Silhouette -bor [Silhouette]::Lower
            $visWallRange.LowerSilHeight = [Fixed]::MaxValue
        }

        if ($samplePerfFrame) {
            $this.PerfThreeDTicksPassRange += ([System.Diagnostics.Stopwatch]::GetTimestamp() - $perfPassRangeStart)
        }
    }
    [void] RenderMaskedTextures() {
        for ($i = $this.visWallRangeCount - 1; $i -ge 0; $i--) {
            $drawSeg = $this.visWallRanges[$i]
            if ($drawSeg.MaskedTextureColumn -ne -1) {
                $this.DrawMaskedRange($drawSeg, $drawSeg.X1, $drawSeg.X2)
            }
        }
    }

    [void] DrawMaskedRange([VisWallRange] $drawSeg, [int] $x1, [int] $x2) {
        $seg = $drawSeg.Seg
        $localClipData = $this.clipData

        $wallLightLevel = ($seg.FrontSector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
        if ($seg.Vertex1.Y -eq $seg.Vertex2.Y) {
            $wallLightLevel--
        } elseif ($seg.Vertex1.X -eq $seg.Vertex2.X) {
            $wallLightLevel++
        }

        $wallLights = $this.scaleLight[[math]::Clamp($wallLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]

        $wallTexture = $this.textures.get_Item($this.world.Specials.TextureTranslation[$seg.SideDef.MiddleTexture])
        $wallWidth = $wallTexture.Width
        $wallColumns = $wallTexture.Composite.Columns
        [int] $wallWrapMask = -1
        if (($wallWidth -gt 0) -and (($wallWidth -band ($wallWidth - 1)) -eq 0)) {
            $wallWrapMask = $wallWidth - 1
        }

        [Fixed] $midTextureAlt = $null
        if (($seg.LineDef.Flags -band [LineFlags]::DontPegBottom) -ne 0) {
            $midTextureAlt = if ($drawSeg.FrontSectorFloorHeight.Data -gt $drawSeg.BackSectorFloorHeight.Data) {
                $drawSeg.FrontSectorFloorHeight
            } else {
                $drawSeg.BackSectorFloorHeight
            }
            $midTextureAlt = $midTextureAlt + [Fixed]::FromInt($wallTexture.Height) - $this.viewZ
        } else {
            $midTextureAlt = if ($drawSeg.FrontSectorCeilingHeight.Data -lt $drawSeg.BackSectorCeilingHeight.Data) {
                $drawSeg.FrontSectorCeilingHeight
            } else {
                $drawSeg.BackSectorCeilingHeight
            }
            $midTextureAlt = $midTextureAlt - $this.viewZ
        }
        $midTextureAlt += $seg.SideDef.RowOffset #integer

        $scaleStep = $drawSeg.ScaleStep
        $scale = $drawSeg.Scale1 + (($x1 - $drawSeg.X1) * $scaleStep)
        $maskedTextureColumnBase = $drawSeg.MaskedTextureColumn
        $upperClipBase = $drawSeg.UpperClip
        $lowerClipBase = $drawSeg.LowerClip
        $localScaleLightShift = [ThreeDRenderer]::scaleLightShift
        $localMaxScaleLight = $this.maxScaleLight

        for ($x = $x1; $x -le $x2; $x++) {
            $index = $scale.Data -shr $localScaleLightShift
            if ($index -ge $localMaxScaleLight) {
                $index = $localMaxScaleLight - 1
            }

            $col = $localClipData[$maskedTextureColumnBase + $x]

            if ($col -ne [short]::MaxValue) {
                $topY = $this.centerYFrac - ($midTextureAlt * $scale)
                $invScale = [Fixed]::new([int](0xFFFFFFFFu / [uint]$scale.Data))
                $ceilClip = $localClipData[$upperClipBase + $x]
                $floorClip = $localClipData[$lowerClipBase + $x]
                if ($wallWrapMask -ge 0) {
                    $wallColumnIndex = $col -band $wallWrapMask
                } else {
                    $wallColumnIndex = [ThreeDRenderer]::WrapColumnIndex($col, $wallWidth)
                }

                $this.DrawMaskedColumn(
                    $wallColumns[$wallColumnIndex],
                    $wallLights[$index],
                    $x,
                    $topY,
                    $scale,
                    $invScale,
                    $midTextureAlt,
                    $ceilClip,
                    $floorClip
                )

                $localClipData[$maskedTextureColumnBase + $x] = [short]::MaxValue
            }

            $scale += $scaleStep #integer
        }
    }
    [void] DrawCeilingColumn(
        [Sector] $sector,
        [byte[]] $flatData,
        [bool] $drawSky,
        [byte[][]] $planeLights,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [Fixed] $ceilingHeight
    ) {
        if ($drawSky) {
            $this.DrawSkyColumn($x, $y1, $y2)
            return
        }

        if (($y2 - $y1) -lt 0) {
            return
        }

        if ($null -eq $flatData) {
            $flatData = $this.emptyFlatData
        }

        [int] $heightData = $ceilingHeight.Data - $this.viewZData
        if ($heightData -lt 0) {
            $heightData = -$heightData
        }
        $localScreenData = $this.screenData
        $screenBasePos = $this.columnBase[$x]
        $localPlaneYSlope = $this.planeYSlope
        $planeDistScaleXData = $this.planeDistScale[$x]
        $cosAngleData = $this.viewColumnCosData[$x]
        $sinAngleData = $this.viewColumnSinData[$x]
        $localViewXData = $this.viewXData
        $negLocalViewYData = $this.viewNegYData
        $localPlaneBaseXScaleData = $this.planeBaseXScale
        $localPlaneBaseYScaleData = $this.planeBaseYScale
        $localCeilingXStep = $this.ceilingXStep
        $localCeilingYStep = $this.ceilingYStep
        $localCeilingXFrac = $this.ceilingXFrac
        $localCeilingYFrac = $this.ceilingYFrac
        $localCeilingLights = $this.ceilingLights
        $defaultMap = $this.defaultColorMap
        $spotYMask = 63 * 64
        $fracBits = [Fixed]::FracBits
        $localZLightShift = [ThreeDRenderer]::zLightShift
        $localMaxZLight = [ThreeDRenderer]::maxZLight

        [int] $lightIndex = 0
        [int] $distanceData = 0
        [int] $xFracData = 0
        [int] $yFracData = 0
        if ($sector -eq $this.ceilingPrevSector -and $this.ceilingPrevX -eq ($x - 1)) {
            $p1 = $y1
            if ($p1 -lt $this.ceilingPrevY1) {
                $p1 = $this.ceilingPrevY1
            }
            $p2 = $y2
            if ($p2 -gt $this.ceilingPrevY2) {
                $p2 = $this.ceilingPrevY2
            }

            $pos = $screenBasePos + $y1

            for ($y = $y1; $y -lt $p1; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localCeilingXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localCeilingYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localCeilingXFrac[$y] = $xFracData
                $localCeilingYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $mColorMap = $planeLights[$lightIndex]
                if ($null -eq $mColorMap) {
                    $mColorMap = $defaultMap
                }
                $localCeilingLights[$y] = $mColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $mColorMap[$flatData[$spot]]
                $pos++
            }

            for ($y = $p1; $y -le $p2; $y++) {
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localCeilingXFrac[$y] + [long]$localCeilingXStep[$y]))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$localCeilingYFrac[$y] + [long]$localCeilingYStep[$y]))

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $localCeilingLights[$y][$flatData[$spot]]
                $pos++

                $localCeilingXFrac[$y] = $xFracData
                $localCeilingYFrac[$y] = $yFracData
            }

            for ($y = $p2 + 1; $y -le $y2; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localCeilingXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localCeilingYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localCeilingXFrac[$y] = $xFracData
                $localCeilingYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $mColorMap = $planeLights[$lightIndex]
                if ($null -eq $mColorMap) {
                    $mColorMap = $defaultMap
                }
                $localCeilingLights[$y] = $mColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $mColorMap[$flatData[$spot]]
                $pos++
            }
        } else {
            $pos = $screenBasePos + $y1

            for ($y = $y1; $y -le $y2; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localCeilingXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localCeilingYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localCeilingXFrac[$y] = $xFracData
                $localCeilingYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $mColorMap = $planeLights[$lightIndex]
                if ($null -eq $mColorMap) {
                    $mColorMap = $defaultMap
                }
                $localCeilingLights[$y] = $mColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $mColorMap[$flatData[$spot]]
                $pos++
            }
        }

        $this.ceilingPrevSector = $sector
        $this.ceilingPrevX = $x
        $this.ceilingPrevY1 = $y1
        $this.ceilingPrevY2 = $y2

    }
    [void] DrawFloorColumn(
        [Sector] $sector,
        [byte[]] $flatData,
        [bool] $drawSky,
        [byte[][]] $planeLights,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [Fixed] $floorHeight
    ) {
        if ($drawSky) {
            $this.DrawSkyColumn($x, $y1, $y2)
            return
        }

        if (($y2 - $y1) -lt 0) {
            return
        }

        if ($null -eq $flatData) {
            $flatData = $this.emptyFlatData
        }

        [int] $heightData = $floorHeight.Data - $this.viewZData
        if ($heightData -lt 0) {
            $heightData = -$heightData
        }
        $localScreenData = $this.screenData
        $screenBasePos = $this.columnBase[$x]
        $localPlaneYSlope = $this.planeYSlope
        $planeDistScaleXData = $this.planeDistScale[$x]
        $cosAngleData = $this.viewColumnCosData[$x]
        $sinAngleData = $this.viewColumnSinData[$x]
        $localViewXData = $this.viewXData
        $negLocalViewYData = $this.viewNegYData
        $localPlaneBaseXScaleData = $this.planeBaseXScale
        $localPlaneBaseYScaleData = $this.planeBaseYScale
        $localFloorXStep = $this.floorXStep
        $localFloorYStep = $this.floorYStep
        $localFloorXFrac = $this.floorXFrac
        $localFloorYFrac = $this.floorYFrac
        $localFloorLights = $this.floorLights
        $defaultMap = $this.defaultColorMap
        $spotYMask = 63 * 64
        $fracBits = [Fixed]::FracBits
        $localZLightShift = [ThreeDRenderer]::zLightShift
        $localMaxZLight = [ThreeDRenderer]::maxZLight

        [int] $lightIndex = 0
        [int] $distanceData = 0
        [int] $xFracData = 0
        [int] $yFracData = 0
        if ($sector -eq $this.floorPrevSector -and $this.floorPrevX -eq ($x - 1)) {
            $p1 = $y1
            if ($p1 -lt $this.floorPrevY1) {
                $p1 = $this.floorPrevY1
            }
            $p2 = $y2
            if ($p2 -gt $this.floorPrevY2) {
                $p2 = $this.floorPrevY2
            }

            $pos = $screenBasePos + $y1

            for ($y = $y1; $y -lt $p1; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localFloorXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localFloorYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localFloorXFrac[$y] = $xFracData
                $localFloorYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $MColorMap = $planeLights[$lightIndex]
                if ($null -eq $MColorMap) {
                    $MColorMap = $defaultMap
                }
                $localFloorLights[$y] = $MColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $MColorMap[$flatData[$spot]]
                $pos++
            }

            for ($y = $p1; $y -le $p2; $y++) {
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localFloorXFrac[$y] + [long]$localFloorXStep[$y]))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$localFloorYFrac[$y] + [long]$localFloorYStep[$y]))

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $localFloorLights[$y][$flatData[$spot]]
                $pos++

                $localFloorXFrac[$y] = $xFracData
                $localFloorYFrac[$y] = $yFracData
            }

            for ($y = $p2 + 1; $y -le $y2; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localFloorXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localFloorYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localFloorXFrac[$y] = $xFracData
                $localFloorYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $MColorMap = $planeLights[$lightIndex]
                if ($null -eq $MColorMap) {
                    $MColorMap = $defaultMap
                }
                $localFloorLights[$y] = $MColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $MColorMap[$flatData[$spot]]
                $pos++
            }
        } else {
            $pos = $screenBasePos + $y1

            for ($y = $y1; $y -le $y2; $y++) {
                $distanceData = [Fixed]::ToInt32Unchecked((([long]$heightData * [long]$localPlaneYSlope[$y]) -shr $fracBits))
                $localFloorXStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseXScaleData) -shr $fracBits))
                $localFloorYStep[$y] = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$localPlaneBaseYScaleData) -shr $fracBits))

                $lengthData = [Fixed]::ToInt32Unchecked((([long]$distanceData * [long]$planeDistScaleXData) -shr $fracBits))
                $xFracData = [Fixed]::ToInt32Unchecked(([long]$localViewXData + ((([long]$cosAngleData * [long]$lengthData) -shr $fracBits))))
                $yFracData = [Fixed]::ToInt32Unchecked(([long]$negLocalViewYData - ((([long]$sinAngleData * [long]$lengthData) -shr $fracBits))))
                $localFloorXFrac[$y] = $xFracData
                $localFloorYFrac[$y] = $yFracData

                $lightIndex = $distanceData -shr $localZLightShift
                if ($lightIndex -lt 0) {
                    $lightIndex = 0
                } elseif ($lightIndex -ge $localMaxZLight) {
                    $lightIndex = $localMaxZLight - 1
                }
                $mColorMap = $planeLights[$lightIndex]
                if ($null -eq $mColorMap) {
                    $mColorMap = $defaultMap
                }
                $localFloorLights[$y] = $mColorMap

                $spot = ((($yFracData -shr 10) -band $spotYMask) + (($xFracData -shr 16) -band 63))
                $localScreenData[$pos] = $mColorMap[$flatData[$spot]]
                $pos++
            }
        }

        $this.floorPrevSector = $sector
        $this.floorPrevX = $x
        $this.floorPrevY1 = $y1
        $this.floorPrevY2 = $y2

    }
    hidden [void] DrawColumnData(
        [Column] $column,
        [byte[]] $map,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [int] $fracStepData,
        [int] $textureAltData
    ) {
        if (($y2 - $y1) -lt 0) {
            return
        }
        # Framebuffer destination address.
        # Use ylookup LUT to avoid multiply with ScreenWidth.
        # Use columnofs LUT for subwindows? 
        $pos1 = $this.columnBase[$x] + $y1
        $pos2 = $pos1 + ($y2 - $y1)

        # Determine scaling, which is the only mapping to be done.
        [int] $fracData = $textureAltData + (($y1 - $this.centerY) * $fracStepData)

        # Inner loop that does the actual texture mapping,
        # e.g. a DDA-like scaling.
        # This is as fast as it gets.
        $localScreenData = $this.screenData
        $source = $column.Data
        $offset = $column.Offset
        $fracBits = [Fixed]::FracBits
        for ($pos = $pos1; $pos -le $pos2; $pos++) {
            # Re-map color indices from wall texture column
            # using a lighting/special effects LUT.
            $localScreenData[$pos] = $map[$source[$offset + (($fracData -shr $fracBits) -band 127)]]
            $fracData += $fracStepData
        }
    }

    [void] DrawColumn(
        [Column] $column,
        [byte[]] $map,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [Fixed] $invScale,
        [Fixed] $textureAlt
    ) {
        $this.DrawColumnData($column, $map, $x, $y1, $y2, $invScale.Data, $textureAlt.Data)
    }

    hidden [void] DrawColumnTranslationData(
        [Column] $column,
        [byte[]] $translation,
        [byte[]] $map,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [int] $fracStepData,
        [int] $textureAltData
    ) {
        if (($y2 - $y1) -lt 0) {
            return
        }

        # Framebuffer destination address.
        # Use ylookup LUT to avoid multiply with ScreenWidth.
        # Use columnofs LUT for subwindows? 
        $pos1 = $this.columnBase[$x] + $y1
        $pos2 = $pos1 + ($y2 - $y1)

        # Determine scaling, which is the only mapping to be done.
        [int] $fracData = $textureAltData + (($y1 - $this.centerY) * $fracStepData)

        # Inner loop that does the actual texture mapping,
        # e.g. a DDA-like scaling.
        $localScreenData = $this.screenData
        $source = $column.Data
        $offset = $column.Offset
        $fracBits = [Fixed]::FracBits
        for ($pos = $pos1; $pos -le $pos2; $pos++) {
            # Re-map color indices from wall texture column
            # using a lighting/special effects LUT.
            $localScreenData[$pos] = $map[$translation[$source[$offset + (($fracData -shr $fracBits) -band 127)]]]
            $fracData += $fracStepData
        }
    }

    [void] DrawColumnTranslation(
        [Column] $column,
        [byte[]] $translation,
        [byte[]] $map,
        [int] $x,
        [int] $y1,
        [int] $y2,
        [Fixed] $invScale,
        [Fixed] $textureAlt
    ) {
        $this.DrawColumnTranslationData($column, $translation, $map, $x, $y1, $y2, $invScale.Data, $textureAlt.Data)
    }

    [void] DrawFuzzColumn(
        [Column] $column,
        [int] $x,
        [int] $y1,
        [int] $y2
    ) {
        if (($y2 - $y1) -lt 0) {
            return
        }

        if ($y1 -eq 0) {
            $y1 = 1
        }

        if ($y2 -eq ($this.windowHeight - 1)) {
            $y2 = $this.windowHeight - 2
        }

        $pos1 = $this.columnBase[$x] + $y1
        $pos2 = $pos1 + ($y2 - $y1)

        $map = $this.fuzzColorMap
        $localScreenData = $this.screenData
        $screenDataLength = $localScreenData.Length
        $localFuzzTable = [ThreeDRenderer]::fuzzTable
        if ($null -eq $localFuzzTable -or $localFuzzTable.Length -eq 0) {
            return
        }
        $localFuzzPos = $this.fuzzPos
        for ($pos = $pos1; $pos -le $pos2; $pos++) {
            $samplePos = $pos + [int]$localFuzzTable[$localFuzzPos]
            if ($samplePos -lt 0 -or $samplePos -ge $screenDataLength) {
                $samplePos = $pos
            }
            $localScreenData[$pos] = $map[$localScreenData[$samplePos]]

            if ((++$localFuzzPos) -eq $localFuzzTable.Length) {
                $localFuzzPos = 0
            }
        }
        $this.fuzzPos = $localFuzzPos
    }

    [void] DrawSkyColumn(
        [int] $x,
        [int] $y1,
        [int] $y2
    ) {
        $angleData = [uint32]((([uint64]$this.viewAngleData + [uint64]$this.xToAngleData[$x]) -band 0xFFFFFFFFul))
        $angle = $angleData -shr [ThreeDRenderer]::angleToSkyShift
        $skyColumns = $this.renderSkyColumns
        if ($null -eq $skyColumns -or $this.renderSkyWidth -le 0) {
            return
        }

        if ($this.renderSkyMask -ge 0) {
            $source = $skyColumns[$angle -band $this.renderSkyMask]
        } else {
            $source = $skyColumns[[ThreeDRenderer]::WrapColumnIndex($angle, $this.renderSkyWidth)]
        }
        if ($null -ne $source -and $source.Length -gt 0) {
            $this.DrawColumnData($source[0], $this.defaultColorMap, $x, $y1, $y2, $this.skyInvScale.Data, $this.skyTextureAlt.Data)
        }
    }
    [void] DrawMaskedColumn(
        [Column[]] $columns,
        [byte[]] $map,
        [int] $x,
        [Fixed] $topY,
        [Fixed] $scale,
        [Fixed] $invScale,
        [Fixed] $textureAlt,
        [int] $upperClip,
        [int] $lowerClip
    ) {
        [int] $topYData = $topY.Data
        [int] $scaleData = $scale.Data
        [int] $textureAltData = $textureAlt.Data
        [int] $invScaleData = $invScale.Data
        [int] $fracUnit = [Fixed]::FracUnit
        [int] $fracBits = [Fixed]::FracBits
        [int] $clipTop = $upperClip + 1
        [int] $clipBottom = $lowerClip - 1
        $maskedColumnsEnumerable = $columns
        if ($null -ne $maskedColumnsEnumerable) {
            $maskedColumnsEnumerator = $maskedColumnsEnumerable.GetEnumerator()
            for (; $maskedColumnsEnumerator.MoveNext(); ) {
                $column = $maskedColumnsEnumerator.Current
                $y1FracData = $topYData + ($scaleData * $column.TopDelta)
                $y2FracData = $y1FracData + ($scaleData * $column.Length)
                $y1 = ($y1FracData + $fracUnit - 1) -shr $fracBits
                $y2 = ($y2FracData - 1) -shr $fracBits

                if ($y1 -lt $clipTop) {
                    $y1 = $clipTop
                }
                if ($y2 -gt $clipBottom) {
                    $y2 = $clipBottom
                }

                if ($y1 -le $y2) {
                    $altData = $textureAltData - ($column.TopDelta -shl $fracBits)
                    $this.DrawColumnData($column, $map, $x, $y1, $y2, $invScaleData, $altData)
                }

            }
        }
    }

    [void] DrawMaskedColumnTranslation(
        [Column[]] $columns,
        [byte[]] $translation,
        [byte[]] $map,
        [int] $x,
        [Fixed] $topY,
        [Fixed] $scale,
        [Fixed] $invScale,
        [Fixed] $textureAlt,
        [int] $upperClip,
        [int] $lowerClip
    ) {
        [int] $topYData = $topY.Data
        [int] $scaleData = $scale.Data
        [int] $textureAltData = $textureAlt.Data
        [int] $invScaleData = $invScale.Data
        [int] $fracUnit = [Fixed]::FracUnit
        [int] $fracBits = [Fixed]::FracBits
        [int] $clipTop = $upperClip + 1
        [int] $clipBottom = $lowerClip - 1
        $translatedMaskedColumnsEnumerable = $columns
        if ($null -ne $translatedMaskedColumnsEnumerable) {
            $translatedMaskedColumnsEnumerator = $translatedMaskedColumnsEnumerable.GetEnumerator()
            for (; $translatedMaskedColumnsEnumerator.MoveNext(); ) {
                $column = $translatedMaskedColumnsEnumerator.Current
                $y1FracData = $topYData + ($scaleData * $column.TopDelta)
                $y2FracData = $y1FracData + ($scaleData * $column.Length)
                $y1 = ($y1FracData + $fracUnit - 1) -shr $fracBits
                $y2 = ($y2FracData - 1) -shr $fracBits

                if ($y1 -lt $clipTop) {
                    $y1 = $clipTop
                }
                if ($y2 -gt $clipBottom) {
                    $y2 = $clipBottom
                }

                if ($y1 -le $y2) {
                    $altData = $textureAltData - ($column.TopDelta -shl $fracBits)
                    $this.DrawColumnTranslationData($column, $translation, $map, $x, $y1, $y2, $invScaleData, $altData)
                }

            }
        }
    }
    [void] DrawMaskedFuzzColumn(
        [Column[]] $columns,
        [int] $x,
        [Fixed] $topY,
        [Fixed] $scale,
        [int] $upperClip,
        [int] $lowerClip
    ) {
        [int] $topYData = $topY.Data
        [int] $scaleData = $scale.Data
        [int] $fracUnit = [Fixed]::FracUnit
        [int] $fracBits = [Fixed]::FracBits
        [int] $clipTop = $upperClip + 1
        [int] $clipBottom = $lowerClip - 1
        $fuzzColumnsEnumerable = $columns
        if ($null -ne $fuzzColumnsEnumerable) {
            $fuzzColumnsEnumerator = $fuzzColumnsEnumerable.GetEnumerator()
            for (; $fuzzColumnsEnumerator.MoveNext(); ) {
                $column = $fuzzColumnsEnumerator.Current
                $y1FracData = $topYData + ($scaleData * $column.TopDelta)
                $y2FracData = $y1FracData + ($scaleData * $column.Length)
                $y1 = ($y1FracData + $fracUnit - 1) -shr $fracBits
                $y2 = ($y2FracData - 1) -shr $fracBits

                if ($y1 -lt $clipTop) {
                    $y1 = $clipTop
                }
                if ($y2 -gt $clipBottom) {
                    $y2 = $clipBottom
                }

                if ($y1 -le $y2) {
                    $this.DrawFuzzColumn($column, $x, $y1, $y2)
                }

            }
        }
    }

    [void] AddSprites(
        [Sector] $sector,
        [int] $validCount
    ) {
        # BSP is traversed by subsector.
        # A sector might have been split into several subsectors during BSP building.
        # Thus we check whether it's already added.
        if ($sector.ValidCount -eq $validCount) {
            return
        }

        # Well, now it will be done.
        $sector.ValidCount = $validCount

        $spriteLightLevel = ($sector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight
        $spriteLights = $this.scaleLight[[math]::Clamp($spriteLightLevel, 0, [ThreeDRenderer]::lightLevelCount - 1)]

        # PowerShell does not reliably honor the custom Sector enumerator here.
        # Walk the linked mobj list explicitly so only real mobjs reach ProjectSprite().
        $thing = $sector.ThingList
        while ($null -ne $thing) {
            $nextThing = $thing.SectorNext
            $this.ProjectSprite($thing, $spriteLights)
            $thing = $nextThing
        }
    }
    [void] ProjectSprite(
        [Mobj] $thing,
        [byte[][]] $spriteLights
    ) {
        if ($this.visSpriteCount -eq $this.visSprites.Length) {
            # Too many sprites.
            return
        }

        $thingX = $thing.GetInterpolatedX($this.frameFrac)
        $thingY = $thing.GetInterpolatedY($this.frameFrac)
        $thingZ = $thing.GetInterpolatedZ($this.frameFrac)

        # Transform the origin point.
        $trX = $thingX - $this.viewX
        $trY = $thingY - $this.viewY

        $gxt = ($trX * $this.viewCos)
        $gyt = -($trY * $this.viewSin)

        $tz = $gxt - $gyt

        # Thing is behind view plane?
        [int] $tzData = $tz.Data
        [int] $minZData = [ThreeDRenderer]::minZ.Data
        if ($tzData -lt $minZData) {
            return
        }

        $xScale = $this.projection / $tz

        $gxt = -$trX * $this.viewSin
        $gyt = $trY * $this.viewCos
        $tx = -($gyt + $gxt)

        # Too far off the side?
        [int] $absTxData = ([Fixed]::Abs($tx)).Data
        [int] $tzLimitData = (($tz -shl 2)).Data
        if ($absTxData -gt $tzLimitData) {
            return
        }

        $spriteDef = $this.sprites.Get_Item($thing.Sprite)
        if ($null -eq $spriteDef) {
            return
        }

        $frameNumber = $thing.Frame -band 0x7F
        if ($frameNumber -ge $spriteDef.Frames.Length) {
            return
        }

        $spriteFrame = $spriteDef.Frames[$frameNumber]
        if ($null -eq $spriteFrame) {
            return
        }

        $lump = $null
        [bool] $flip = $false
        [int] $rot = 0

        if ($spriteFrame.Rotate) {
            # Choose a different rotation based on player view.
            $ang = [Geometry]::PointToAngle($this.viewX, $this.viewY, $thingX, $thingY)
            # Doom does this with unsigned wraparound. PowerShell's default arithmetic
            # can turn this into signed shifts, which picks the wrong rotation when mobs
            # swing through back-facing angles.
            [uint64] $rotOffset = [uint64]([uint32](([Angle]::Ang45.Data / 2) * 9))
            [uint64] $rotBase = [uint64]$ang.Data + $rotOffset + 0x100000000 - [uint64]$thing.Angle.Data
            [uint32] $rotData = [uint32]($rotBase % 0x100000000)
            $rot = [int]($rotData -shr 29)
            $lump = $spriteFrame.Patches[$rot]
            $flip = $spriteFrame.Flip[$rot]
        } else {
            # Use single rotation for all views.
            $lump = $spriteFrame.Patches[0]
            $flip = $spriteFrame.Flip[0]
        }

        if ($null -eq $lump) {
            return
        }

        # Calculate edges of the shape.
        $tx -= [Fixed]::FromInt($lump.LeftOffset)
        $x1 = ($this.centerXFrac + ($tx * $xScale)).Data -shr [Fixed]::FracBits

        # Off the right side?
        if ($x1 -gt $this.windowWidth) {
            return
        }

        $tx += [Fixed]::FromInt($lump.Width) #integer
        $x2 = (($this.centerXFrac + ($tx * $xScale)).Data -shr [Fixed]::FracBits) - 1

        # Off the left side?
        if ($x2 -lt 0) {
            return
        }

        # Store information in a vissprite.
        $vis = $this.visSprites[$this.visSpriteCount]
        $this.visSpriteCount++

        $vis.MobjFlags = $thing.Flags
        $vis.Scale = $xScale
        $vis.GlobalX = $thingX
        $vis.GlobalY = $thingY
        $vis.GlobalBottomZ = $thingZ
        $vis.GlobalTopZ = $thingZ + [Fixed]::FromInt($lump.TopOffset)
        $vis.TextureAlt = $vis.GlobalTopZ - $this.viewZ
        $vis.X1 = if ($x1 -lt 0) { 0 } else { $x1 }
        $vis.X2 = if ($x2 -ge $this.windowWidth) { $this.windowWidth - 1 } else { $x2 }

        $invScale = [Fixed]::One / $xScale

        if ($flip) {
            $vis.StartFrac = [Fixed]::new([Fixed]::FromInt($lump.Width).Data - 1)
            $vis.InvScale = -$invScale
        } else {
            $vis.StartFrac = [Fixed]::Zero
            $vis.InvScale = $invScale
        }

        if ($vis.X1 -gt $x1) {
            $vis.StartFrac += $vis.InvScale * ($vis.X1 - $x1) #integer
        }

        $vis.Patch = $lump

        if ($this.fixedColorMap -eq 0) {
            if (($thing.Frame -band 0x8000) -eq 0) {
                $spriteLightIndex = $xScale.Data -shr [ThreeDRenderer]::scaleLightShift
                if ($spriteLightIndex -ge $this.maxScaleLight) {
                    $spriteLightIndex = $this.maxScaleLight - 1
                }
                $vis.ColorMap = $spriteLights[$spriteLightIndex]
            } else {
                $vis.ColorMap = $this.colorMap.get_FullBright()
            }
        } else {
            $vis.ColorMap = $this.colorMap.get_Item($this.fixedColorMap)
        }
    }
    [void] RenderSprites() {
        [Array]::Sort($this.visSprites, 0, $this.visSpriteCount, $this.visSpriteComparer)

        for ($i = $this.visSpriteCount - 1; $i -ge 0; $i--) {
            $this.DrawSprite($this.visSprites[$i])
        }
    }
    [void] DrawSprite([VisSprite] $sprite) {
        $localLowerClip = $this.lowerClip
        $localUpperClip = $this.upperClip
        $localClipData = $this.clipData
        $localSpriteX1 = $sprite.X1
        $localSpriteX2 = $sprite.X2
        $localSpriteScaleData = $sprite.Scale.Data
        $localSpriteBottomZData = $sprite.GlobalBottomZ.Data
        $localSpriteTopZData = $sprite.GlobalTopZ.Data
        $localSpritePatchColumns = $sprite.Patch.Columns
        $localSpriteScale = $sprite.Scale
        $localSpriteTextureAlt = $sprite.TextureAlt
        $localSpriteColorMap = $sprite.ColorMap
        $localSpriteColumnMax = $localSpritePatchColumns.Length - 1
        $localSpriteTopY = $this.centerYFrac - ($localSpriteTextureAlt * $localSpriteScale)
        $localAbsInvScale = [Fixed]::Abs($sprite.InvScale)
        $localFracData = $sprite.StartFrac.Data
        $localInvScaleData = $sprite.InvScale.Data
        $fracBits = [Fixed]::FracBits

        for ($x = $localSpriteX1; $x -le $localSpriteX2; $x++) {
            $localLowerClip[$x] = -2
            $localUpperClip[$x] = -2
        }

        for ($i = $this.visWallRangeCount - 1; $i -ge 0; $i--) {
            $wall = $this.visWallRanges[$i]

            if ($wall.X1 -gt $localSpriteX2 -or
                $wall.X2 -lt $localSpriteX1 -or
                ($wall.Silhouette -eq 0 -and $wall.MaskedTextureColumn -eq -1)) {
                continue
            }

            $r1 = if ($wall.X1 -lt $localSpriteX1) { $localSpriteX1 } else { $wall.X1 }
            $r2 = if ($wall.X2 -gt $localSpriteX2) { $localSpriteX2 } else { $wall.X2 }
            $lowScale = [Fixed]::Zero
            $scale = [Fixed]::Zero

            if ($wall.Scale1.Data -gt $wall.Scale2.Data) {
                $lowScale = $wall.Scale2
                $scale = $wall.Scale1
            } else {
                $lowScale = $wall.Scale1
                $scale = $wall.Scale2
            }

            if ($scale.Data -lt $localSpriteScaleData -or
                ($lowScale.Data -lt $localSpriteScaleData -and
                    [Geometry]::PointOnSegSide($sprite.GlobalX, $sprite.GlobalY, $wall.Seg) -eq 0)) {
                
                if ($wall.MaskedTextureColumn -ne -1) {
                    $this.DrawMaskedRange($wall, $r1, $r2)
                }
                continue
            }

            $silhouette = $wall.Silhouette

            if ($localSpriteBottomZData -ge $wall.LowerSilHeight.Data) {
                $silhouette = $silhouette -band -bnot [Silhouette]::Lower
            }

            if ($localSpriteTopZData -le $wall.UpperSilHeight.Data) {
                $silhouette = $silhouette -band -bnot [Silhouette]::Upper
            }

            if ($silhouette -eq [Silhouette]::Lower) {
                for ($x = $r1; $x -le $r2; $x++) {
                    if ($localLowerClip[$x] -eq -2) {
                        $localLowerClip[$x] = $localClipData[$wall.LowerClip + $x]
                    }
                }
            } elseif ($silhouette -eq [Silhouette]::Upper) {
                for ($x = $r1; $x -le $r2; $x++) {
                    if ($localUpperClip[$x] -eq -2) {
                        $localUpperClip[$x] = $localClipData[$wall.UpperClip + $x]
                    }
                }
            } elseif ($silhouette -eq [Silhouette]::Both) {
                for ($x = $r1; $x -le $r2; $x++) {
                    if ($localLowerClip[$x] -eq -2) {
                        $localLowerClip[$x] = $localClipData[$wall.LowerClip + $x]
                    }
                    if ($localUpperClip[$x] -eq -2) {
                        $localUpperClip[$x] = $localClipData[$wall.UpperClip + $x]
                    }
                }
            }
        }

        for ($x = $localSpriteX1; $x -le $localSpriteX2; $x++) {
            if ($localLowerClip[$x] -eq -2) {
                $localLowerClip[$x] = [short]$this.windowHeight
            }
            if ($localUpperClip[$x] -eq -2) {
                $localUpperClip[$x] = -1
            }
        }

        if (($sprite.MobjFlags -band [MobjFlags]::Shadow) -ne 0) {
            for ($x = $localSpriteX1; $x -le $localSpriteX2; $x++) {
                $textureColumn = $localFracData -shr $fracBits
                if ($textureColumn -lt 0) {
                    $textureColumn = 0
                } elseif ($textureColumn -gt $localSpriteColumnMax) {
                    $textureColumn = $localSpriteColumnMax
                }
                $this.DrawMaskedFuzzColumn(
                    $localSpritePatchColumns[$textureColumn],
                    $x,
                    $localSpriteTopY,
                    $localSpriteScale,
                    $localUpperClip[$x],
                    $localLowerClip[$x]
                )
                $localFracData += $localInvScaleData
            }
        } elseif ((([int]($sprite.MobjFlags -band [MobjFlags]::Translation)) -shr [int][MobjFlags]::TransShift) -ne 0) {
            [byte[]] $translation = 0
            switch (([int]($sprite.MobjFlags -band [MobjFlags]::Translation)) -shr [int][MobjFlags]::TransShift) {
                1 { $translation = $this.greenToGray }
                2 { $translation = $this.greenToBrown }
                default { $translation = $this.greenToRed }
            }
            $localFracData = $sprite.StartFrac.Data
            for ($x = $localSpriteX1; $x -le $localSpriteX2; $x++) {
                $textureColumn = $localFracData -shr $fracBits
                if ($textureColumn -lt 0) {
                    $textureColumn = 0
                } elseif ($textureColumn -gt $localSpriteColumnMax) {
                    $textureColumn = $localSpriteColumnMax
                }
                $this.DrawMaskedColumnTranslation(
                    $localSpritePatchColumns[$textureColumn],
                    $translation,
                    $localSpriteColorMap,
                    $x,
                    $localSpriteTopY,
                    $localSpriteScale,
                    $localAbsInvScale,
                    $localSpriteTextureAlt,
                    $localUpperClip[$x],
                    $localLowerClip[$x]
                )
                $localFracData += $localInvScaleData
            }
        } else {
            $localFracData = $sprite.StartFrac.Data
            for ($x = $localSpriteX1; $x -le $localSpriteX2; $x++) {
                $textureColumn = $localFracData -shr $fracBits
                if ($textureColumn -lt 0) {
                    $textureColumn = 0
                } elseif ($textureColumn -gt $localSpriteColumnMax) {
                    $textureColumn = $localSpriteColumnMax
                }
                $this.DrawMaskedColumn(
                    $localSpritePatchColumns[$textureColumn],
                    $localSpriteColorMap,
                    $x,
                    $localSpriteTopY,
                    $localSpriteScale,
                    $localAbsInvScale,
                    $localSpriteTextureAlt,
                    $localUpperClip[$x],
                    $localLowerClip[$x]
                )
                $localFracData += $localInvScaleData
            }
        }
    }
    [void] DrawPlayerSprite(
        [PlayerSpriteDef] $psp,
        [byte[][]] $spriteLights,
        [bool] $fuzz
    ) {
        # Decide which patch to use.
        $spriteDef = $this.sprites.Get_Item($psp.State.Sprite)

        $spriteFrame = $spriteDef.Frames[$psp.State.Frame -band 0x7FFF]

        $lump = $spriteFrame.Patches[0]
        $flip = $spriteFrame.Flip[0]

        # Calculate edges of the shape.
        $tx = $psp.Sx - [Fixed]::FromInt(160)
        $tx -= [Fixed]::FromInt($lump.LeftOffset)
        $x1 = ($this.centerXFrac + ($tx * $this.weaponScale)).Data -shr [Fixed]::FracBits

        # Off the right side?
        if ($x1 -gt $this.windowWidth) {
            return
        }

        $tx += [Fixed]::FromInt($lump.Width)
        $x2 = (($this.centerXFrac + ($tx * $this.weaponScale)).Data -shr [Fixed]::FracBits) - 1

        # Off the left side?
        if ($x2 -lt 0) {
            return
        }

        # Store information in a vissprite.
        $vis = $this.weaponSprite
        $vis.MobjFlags = 0
        # The code below is based on Crispy Doom's weapon rendering code.
        $vis.TextureAlt = [Fixed]::FromInt(100) + ([Fixed]::One / 4) - ($psp.Sy - [Fixed]::FromInt($lump.TopOffset))
        $vis.X1 = if ($x1 -lt 0) { 0 } else { $x1 }
        $vis.X2 = if ($x2 -ge $this.windowWidth) { $this.windowWidth - 1 } else { $x2 }
        $vis.Scale = $this.weaponScale

        if ($flip) {
            $vis.InvScale = -$this.weaponInvScale
            $vis.StartFrac = [Fixed]::FromInt($lump.Width) - [Fixed]::new(1)
        } else {
            $vis.InvScale = $this.weaponInvScale
            $vis.StartFrac = [Fixed]::Zero
        }

        if ($vis.X1 -gt $x1) {
            $vis.StartFrac += $vis.InvScale * ($vis.X1 - $x1)
        }

        $vis.Patch = $lump

        if ($this.fixedColorMap -eq 0) {
            if (($psp.State.Frame -band 0x8000) -eq 0) {
                $vis.ColorMap = $spriteLights[$this.maxScaleLight - 1]
            } else {
                $vis.ColorMap = $this.colorMap.get_FullBright()
            }
        } else {
            $vis.ColorMap = $this.colorMap.get_Item($this.fixedColorMap)
        }

        $localWeaponPatchColumns = $vis.Patch.Columns
        $localWeaponScale = $vis.Scale
        $localWeaponTextureAlt = $vis.TextureAlt
        $localWeaponColorMap = $vis.ColorMap
        $localWeaponColumnMax = $localWeaponPatchColumns.Length - 1
        $localWeaponTopY = $this.centerYFrac - ($localWeaponTextureAlt * $localWeaponScale)
        $localWeaponInvScaleData = $vis.InvScale.Data
        $localWeaponAbsInvScale = [Fixed]::Abs($vis.InvScale)
        $fracBits = [Fixed]::FracBits

        if ($fuzz) {
            $localFracData = $vis.StartFrac.Data
            for ($x = $vis.X1; $x -le $vis.X2; $x++) {
                $textureColumn = $localFracData -shr $fracBits
                if ($textureColumn -lt 0) {
                    $textureColumn = 0
                } elseif ($textureColumn -gt $localWeaponColumnMax) {
                    $textureColumn = $localWeaponColumnMax
                }
                $this.DrawMaskedFuzzColumn(
                    $localWeaponPatchColumns[$textureColumn],
                    $x,
                    $localWeaponTopY,
                    $localWeaponScale,
                    -1,
                    $this.windowHeight
                )
                $localFracData += $localWeaponInvScaleData
            }
        } else {
            $localFracData = $vis.StartFrac.Data
            for ($x = $vis.X1; $x -le $vis.X2; $x++) {
                $textureColumn = $localFracData -shr $fracBits
                if ($textureColumn -lt 0) {
                    $textureColumn = 0
                } elseif ($textureColumn -gt $localWeaponColumnMax) {
                    $textureColumn = $localWeaponColumnMax
                }
                $this.DrawMaskedColumn(
                    $localWeaponPatchColumns[$textureColumn],
                    $localWeaponColorMap,
                    $x,
                    $localWeaponTopY,
                    $localWeaponScale,
                    $localWeaponAbsInvScale,
                    $localWeaponTextureAlt,
                    -1,
                    $this.windowHeight
                )
                $localFracData += $localWeaponInvScaleData
            }
        }
    }

    [void] DrawPlayerSprites([Player] $player) {
        # Get light level.
        $spriteLightLevel = ($player.Mobj.Subsector.Sector.LightLevel -shr [ThreeDRenderer]::lightSegShift) + $this.extraLight

        [byte[][]] $spriteLights = 0
        if ($spriteLightLevel -lt 0) {
            $spriteLights = $this.scaleLight[0]
        } elseif ($spriteLightLevel -ge [ThreeDRenderer]::lightLevelCount) {
            $spriteLights = $this.scaleLight[[ThreeDRenderer]::lightLevelCount - 1]
        } else {
            $spriteLights = $this.scaleLight[$spriteLightLevel]
        }

        [bool] $fuzz = $false
        if ($player.Powers[[int][PowerType]::Invisibility] -gt (4 * 32) -or
            ($player.Powers[[int][PowerType]::Invisibility] -band 8) -ne 0) {
            # Shadow draw.
            $fuzz = $true
        } else {
            $fuzz = $false
        }

        # Add all active psprites.
        for ($i = 0; $i -lt [int][PlayerSprite]::Count; $i++) {
            $psp = $player.PlayerSprites[$i]
            if ($null -ne $psp.State) {
                $this.DrawPlayerSprite($psp, $spriteLights, $fuzz)
            }
        }
    }

}

class ClipRange {
    [int]$First
    [int]$Last

    [void] CopyFrom([ClipRange]$range) {
        $this.First = $range.First
        $this.Last = $range.Last
    }
}

class VisWallRange {
    [Seg]$Seg

    [int]$X1
    [int]$X2

    [Fixed]$Scale1
    [Fixed]$Scale2
    [Fixed]$ScaleStep

    [Silhouette]$Silhouette
    [Fixed]$UpperSilHeight
    [Fixed]$LowerSilHeight

    [int]$UpperClip
    [int]$LowerClip
    [int]$MaskedTextureColumn

    [Fixed]$FrontSectorFloorHeight
    [Fixed]$FrontSectorCeilingHeight
    [Fixed]$BackSectorFloorHeight
    [Fixed]$BackSectorCeilingHeight
}

class VisSprite {
    [int]$X1
    [int]$X2

    # For line side calculation.
    [Fixed]$GlobalX
    [Fixed]$GlobalY

    # Global bottom / top for silhouette clipping.
    [Fixed]$GlobalBottomZ
    [Fixed]$GlobalTopZ

    # Horizontal position of x1.
    [Fixed]$StartFrac

    [Fixed]$Scale

    # Negative if flipped.
    [Fixed]$InvScale

    [Fixed]$TextureAlt
    [Patch]$Patch

    # For color translation and shadow draw.
    [byte[]]$ColorMap

    [MobjFlags]$MobjFlags
}

class VisSpriteComparer : System.Collections.IComparer {
    [int] Compare([object] $x, [object] $y) {
        $left = $x -as [VisSprite]
        $right = $y -as [VisSprite]

        if ($null -eq $left -and $null -eq $right) {
            return 0
        }
        if ($null -eq $left) {
            return -1
        }
        if ($null -eq $right) {
            return 1
        }

        # Avoid subtraction overflow so sprite ordering stays stable.
        if ($left.Scale.Data -gt $right.Scale.Data) {
            return -1
        }
        if ($left.Scale.Data -lt $right.Scale.Data) {
            return 1
        }

        return 0
    }
}

enum Silhouette
{
    None = 0
    Upper = 1
    Lower = 2
    Both = 3
}
