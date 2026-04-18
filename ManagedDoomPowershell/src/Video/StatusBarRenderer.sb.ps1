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

class StatusBarRenderer {
    static [int] $Height = 32

    # Ammo number pos.
    static [int] $ammoWidth = 3
    static [int] $ammoX = 44
    static [int] $ammoY = 171

    # Health number pos.
    static [int] $healthX = 90
    static [int] $healthY = 171

    # Weapon pos.
    static [int] $armsX = 111
    static [int] $armsY = 172
    static [int] $armsBackgroundX = 104
    static [int] $armsBackgroundY = 168
    static [int] $armsSpaceX = 12
    static [int] $armsSpaceY = 10

    # Frags pos.
    static [int] $fragsWidth = 2
    static [int] $fragsX = 138
    static [int] $fragsY = 171

    # Armor number pos.
    static [int] $armorX = 221
    static [int] $armorY = 171

    # Key icon positions.
    static [int] $key0Width = 8
    static [int] $key0X = 239
    static [int] $key0Y = 171
    static [int] $key1Width = 8
    static [int] $key1X = 239
    static [int] $key1Y = 181
    static [int] $key2Width = 8
    static [int] $key2X = 239
    static [int] $key2Y = 191

    # Ammunition counter.
    static [int] $ammo0Width = 3
    static [int] $ammo0X = 288
    static [int] $ammo0Y = 173
    static [int] $ammo1Width = 3
    static [int] $ammo1X = 288
    static [int] $ammo1Y = 179
    static [int] $ammo2Width = 3
    static [int] $ammo2X = 288
    static [int] $ammo2Y = 191
    static [int] $ammo3Width = 3
    static [int] $ammo3X = 288
    static [int] $ammo3Y = 185

    # Indicate maximum ammunition.
    static [int] $maxAmmo0Width = 3
    static [int] $maxAmmo0X = 314
    static [int] $maxAmmo0Y = 173
    static [int] $maxAmmo1Width = 3
    static [int] $maxAmmo1X = 314
    static [int] $maxAmmo1Y = 179
    static [int] $maxAmmo2Width = 3
    static [int] $maxAmmo2X = 314
    static [int] $maxAmmo2Y = 191
    static [int] $maxAmmo3Width = 3
    static [int] $maxAmmo3X = 314
    static [int] $maxAmmo3Y = 185

    static [int] $faceX = 143
    static [int] $faceY = 168
    static [int] $faceBackgroundX = 143
    static [int] $faceBackgroundY = 169

    [DrawScreen] $screen
    [Patches] $patches
    [int] $scale

    [NumberWidget] $ready
    [PercentWidget] $health
    [PercentWidget] $armor

    [NumberWidget[]] $ammo
    [NumberWidget[]] $maxAmmo
    [MultIconWidget[]] $weapons
    [NumberWidget] $frags
    [MultIconWidget[]] $keys

    StatusBarRenderer([Wad] $wad, [DrawScreen] $screen) {
        $this.screen = $screen

        $this.patches = [Patches]::new($wad)

        $this.scale = $screen.Width / 320

        $this.ready = [NumberWidget]::new()
        $this.ready.Patches = $this.patches.TallNumbers
        $this.ready.Width = [StatusBarRenderer]::ammoWidth
        $this.ready.X = [StatusBarRenderer]::ammoX
        $this.ready.Y = [StatusBarRenderer]::ammoY

        $this.health = [PercentWidget]::new()
        $this.health.NumberWidget = [NumberWidget]::new()
        $this.health.NumberWidget.Patches = $this.patches.TallNumbers
        $this.health.NumberWidget.Width = 3
        $this.health.NumberWidget.X = [StatusBarRenderer]::healthX
        $this.health.NumberWidget.Y = [StatusBarRenderer]::healthY
        $this.health.Patch = $this.patches.TallPercent

        $this.armor = [PercentWidget]::new()
        $this.armor.NumberWidget = [NumberWidget]::new()
        $this.armor.NumberWidget.Patches = $this.patches.TallNumbers
        $this.armor.NumberWidget.Width = 3
        $this.armor.NumberWidget.X = [StatusBarRenderer]::armorX
        $this.armor.NumberWidget.Y = [StatusBarRenderer]::armorY
        $this.armor.Patch = $this.patches.TallPercent

        $this.ammo = New-Object NumberWidget[] ([int][AmmoType]::Count)
        $this.ammo[0] = [NumberWidget]::new()
        $this.ammo[0].Patches = $this.patches.ShortNumbers
        $this.ammo[0].Width = [StatusBarRenderer]::ammo0Width
        $this.ammo[0].X = [StatusBarRenderer]::ammo0X
        $this.ammo[0].Y = [StatusBarRenderer]::ammo0Y

        $this.ammo[1] = [NumberWidget]::new()
        $this.ammo[1].Patches = $this.patches.ShortNumbers
        $this.ammo[1].Width = [StatusBarRenderer]::ammo1Width
        $this.ammo[1].X = [StatusBarRenderer]::ammo1X
        $this.ammo[1].Y = [StatusBarRenderer]::ammo1Y

        $this.ammo[2] = [NumberWidget]::new()
        $this.ammo[2].Patches = $this.patches.ShortNumbers
        $this.ammo[2].Width = [StatusBarRenderer]::ammo2Width
        $this.ammo[2].X = [StatusBarRenderer]::ammo2X
        $this.ammo[2].Y = [StatusBarRenderer]::ammo2Y

        $this.ammo[3] = [NumberWidget]::new()
        $this.ammo[3].Patches = $this.patches.ShortNumbers
        $this.ammo[3].Width = [StatusBarRenderer]::ammo3Width
        $this.ammo[3].X = [StatusBarRenderer]::ammo3X
        $this.ammo[3].Y = [StatusBarRenderer]::ammo3Y

        $this.maxAmmo = [Array]::CreateInstance([NumberWidget], ([int][AmmoType]::Count))
        $this.maxAmmo[0] = [NumberWidget]::new()
        $this.maxAmmo[0].Patches = $this.patches.ShortNumbers
        $this.maxAmmo[0].Width = [StatusBarRenderer]::maxAmmo0Width
        $this.maxAmmo[0].X = [StatusBarRenderer]::maxAmmo0X
        $this.maxAmmo[0].Y = [StatusBarRenderer]::maxAmmo0Y
        $this.maxAmmo[1] = [NumberWidget]::new()
        $this.maxAmmo[1].Patches = $this.patches.ShortNumbers
        $this.maxAmmo[1].Width = [StatusBarRenderer]::maxAmmo1Width
        $this.maxAmmo[1].X = [StatusBarRenderer]::maxAmmo1X
        $this.maxAmmo[1].Y = [StatusBarRenderer]::maxAmmo1Y
        $this.maxAmmo[2] = [NumberWidget]::new()
        $this.maxAmmo[2].Patches = $this.patches.ShortNumbers
        $this.maxAmmo[2].Width = [StatusBarRenderer]::maxAmmo2Width
        $this.maxAmmo[2].X = [StatusBarRenderer]::maxAmmo2X
        $this.maxAmmo[2].Y = [StatusBarRenderer]::maxAmmo2Y
        $this.maxAmmo[3] = [NumberWidget]::new()
        $this.maxAmmo[3].Patches = $this.patches.ShortNumbers
        $this.maxAmmo[3].Width = [StatusBarRenderer]::maxAmmo3Width
        $this.maxAmmo[3].X = [StatusBarRenderer]::maxAmmo3X
        $this.maxAmmo[3].Y = [StatusBarRenderer]::maxAmmo3Y



        $this.weapons = New-Object MultIconWidget[] 6
        for ($i = 0; $i -lt $this.weapons.Length; $i++) {
            $this.weapons[$i] = [MultIconWidget]::new()
            $this.weapons[$i].X = [StatusBarRenderer]::armsX + (($i % 3) * [StatusBarRenderer]::armsSpaceX)
            $this.weapons[$i].Y = [StatusBarRenderer]::armsY + ([int][Math]::Truncate($i / 3) * [StatusBarRenderer]::armsSpaceY)
            $this.weapons[$i].Patches = $this.patches.Arms[$i]
        }
    
        $this.frags = [NumberWidget]::new()
        $this.frags.Patches = $this.patches.TallNumbers
        $this.frags.Width = [StatusBarRenderer]::fragsWidth
        $this.frags.X = [StatusBarRenderer]::fragsX
        $this.frags.Y = [StatusBarRenderer]::fragsY
    
        $this.keys = New-Object MultIconWidget[] 3
        for ($i = 0; $i -lt 3; $i++) {
            $this.keys[$i] = [MultIconWidget]::new()
            switch ($i) {
                0 {
                    $this.keys[$i].X = [StatusBarRenderer]::key0X
                    $this.keys[$i].Y = [StatusBarRenderer]::key0Y
                }
                1 {
                    $this.keys[$i].X = [StatusBarRenderer]::key1X
                    $this.keys[$i].Y = [StatusBarRenderer]::key1Y
                }
                default {
                    $this.keys[$i].X = [StatusBarRenderer]::key2X
                    $this.keys[$i].Y = [StatusBarRenderer]::key2Y
                }
            }
            $this.keys[$i].Patches = $this.patches.Keys
        }
    }

    [void] Render([Player] $player, [bool] $drawBackground) {
        if ($drawBackground) {
            $this.DrawHudPatch($this.patches.Background, 0, $this.scale * (200 - [StatusBarRenderer]::Height))
        }

        if ([DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo -ne [AmmoType]::NoAmmo) {
            $num = $player.Ammo[[int][DoomInfo]::WeaponInfos[[int]$player.ReadyWeapon].Ammo]
            $this.DrawNumber($this.ready, $num)
        }

        $this.DrawPercent($this.health, $player.Health)
        $this.DrawPercent($this.armor, $player.ArmorPoints)

        for ($i = 0; $i -lt [int][AmmoType]::Count; $i++) {
            $this.DrawNumber($this.ammo[$i], $player.Ammo[$i])
            $this.DrawNumber($this.maxAmmo[$i], $player.MaxAmmo[$i])
        }

        if ($player.Mobj.World.Options.Deathmatch -eq 0) {
            if ($drawBackground) {
                $this.DrawHudPatch($this.patches.ArmsBackground, $this.scale * [StatusBarRenderer]::armsBackgroundX, $this.scale * [StatusBarRenderer]::armsBackgroundY)
            }

            for ($i = 0; $i -lt $this.weapons.Length; $i++) {
                $this.DrawMultIcon($this.weapons[$i], $(if ($player.WeaponOwned[$i + 1]) { 1 } else { 0 }))
            }
        } else {
            $sum = 0
            for ($i = 0; $i -lt $player.Frags.Length; $i++) {
                $sum += $player.Frags[$i]
            }
            $this.DrawNumber($this.frags, $sum)
        }

        if ($drawBackground) {
            if ($player.Mobj.World.Options.NetGame) {
                $this.DrawHudPatch($this.patches.FaceBackground[$player.Number], $this.scale * [StatusBarRenderer]::faceBackgroundX, $this.scale * [StatusBarRenderer]::faceBackgroundY)
            }

            $this.DrawHudPatch($this.patches.Faces[$player.Mobj.World.StatusBar.FaceIndex], $this.scale * [StatusBarRenderer]::faceX, $this.scale * [StatusBarRenderer]::faceY)
        }

        for ($i = 0; $i -lt 3; $i++) {
            if ($player.Cards[$i + 3]) {
                $this.DrawMultIcon($this.keys[$i], $i + 3)
            } elseif ($player.Cards[$i]) {
                $this.DrawMultIcon($this.keys[$i], $i)
            }
        }
    }

    [void] DrawNumber([NumberWidget] $widget, [int] $num) {
        $digits = $widget.Width
        $w = $widget.Patches[0].Width
        $h = $widget.Patches[0].Height
        $x = $widget.X

        $neg = $num -lt 0

        if ($neg) {
            if ($digits -eq 2 -and $num -lt -9) {
                $num = -9
            } elseif ($digits -eq 3 -and $num -lt -99) {
                $num = -99
            }
            $num = -$num
        }

        if ($num -eq 1994) {
            return
        }

        if ($num -eq 0) {
            $this.DrawHudPatch($widget.Patches[0], $this.scale * ($x - $w), $this.scale * $widget.Y)
        }

        while ($num -ne 0 -and $digits-- -ne 0) {
            $x -= $w
            $this.DrawHudPatch($widget.Patches[$num % 10], $this.scale * $x, $this.scale * $widget.Y)
            $num = [int][Math]::Truncate($num / 10)
        }

        if ($neg) {
            $this.DrawHudPatch($this.patches.TallMinus, $this.scale * ($x - 8), $this.scale * $widget.Y)
        }
    }

    [void] DrawPercent([PercentWidget] $per, [int] $value) {
        $this.DrawHudPatch($per.Patch, $this.scale * $per.NumberWidget.X, $this.scale * $per.NumberWidget.Y)
        $this.DrawNumber($per.NumberWidget, $value)
    }

    [void] DrawMultIcon([MultIconWidget] $mi, [int] $value) {
        $this.DrawHudPatch($mi.Patches[$value], $this.scale * $mi.X, $this.scale * $mi.Y)
    }

    hidden [void] DrawHudPatch([Patch] $patch, [int] $x, [int] $y) {
        $this.screen.DrawPatchExact($patch, $x, $y, $this.scale)
    }
    
    
}

class NumberWidget {
    [int] $X
    [int] $Y
    [int] $Width
    [Patch[]] $Patches
}

class PercentWidget {
    [NumberWidget] $NumberWidget = [NumberWidget]::new()
    [Patch] $Patch
}

class MultIconWidget {
    [int] $X
    [int] $Y
    [Patch[]] $Patches
}

class Patches {
    [Patch] $Background
    [Patch[]] $TallNumbers
    [Patch[]] $ShortNumbers
    [Patch] $TallMinus
    [Patch] $TallPercent
    [Patch[]] $Keys
    [Patch] $ArmsBackground
    [Patch[][]] $Arms
    [Patch[]] $FaceBackground
    [Patch[]] $Faces

    [string] GetFaceName([int] $index) {
        if ($index -eq [StatusBar]::Face::GodIndex) {
            return "STFGOD0"
        }

        if ($index -eq [StatusBar]::Face::DeadIndex) {
            return "STFDEAD0"
        }

        $pain = [int][Math]::Floor($index / [StatusBar]::Face::Stride)
        $offset = $index % [StatusBar]::Face::Stride

        switch ($offset) {
            0 { return "STFST${pain}0" }
            1 { return "STFST${pain}1" }
            2 { return "STFST${pain}2" }
            3 { return "STFTR${pain}0" }
            4 { return "STFTL${pain}0" }
            5 { return "STFOUCH$pain" }
            6 { return "STFEVL$pain" }
            7 { return "STFKILL$pain" }
        }

        return "<bad-face-index:$index>"
    }

    Patches([Wad] $wad) {
        $this.Background = [Patch]::FromWad($wad, "STBAR")

        $this.TallNumbers = New-Object Patch[] 10
        $this.ShortNumbers = New-Object Patch[] 10
        for ($i = 0; $i -lt 10; $i++) {
            $this.TallNumbers[$i] = [Patch]::FromWad($wad, "STTNUM$i")
            $this.ShortNumbers[$i] = [Patch]::FromWad($wad, "STYSNUM$i")
        }

        $this.TallMinus = [Patch]::FromWad($wad, "STTMINUS")
        $this.TallPercent = [Patch]::FromWad($wad, "STTPRCNT")

        $this.Keys = New-Object Patch[] ([int][CardType]::Count)
        for ($i = 0; $i -lt $this.Keys.Length; $i++) {
            $this.Keys[$i] = [Patch]::FromWad($wad, "STKEYS$i")
        }

        $this.ArmsBackground = [Patch]::FromWad($wad, "STARMS")
        $this.Arms = New-Object Patch[][] 6
        for ($i = 0; $i -lt 6; $i++) {
            $num = $i + 2
            $this.Arms[$i] = New-Object Patch[] 2
            $this.Arms[$i][0] = [Patch]::FromWad($wad, "STGNUM$num")
            $this.Arms[$i][1] = $this.ShortNumbers[$num]
        }

        $this.FaceBackground = [Array]::CreateInstance([Patch], ([int][Player]::MaxPlayerCount))
        for ($i = 0; $i -lt $this.FaceBackground.Length; $i++) {
            $this.FaceBackground[$i] = [Patch]::FromWad($wad, "STFB$i")
        }

        $this.Faces = [Array]::CreateInstance([Patch], [int]([StatusBar]::face::FaceCount))
        $faceCount = 0
        for ($i = 0; $i -lt [StatusBar]::face::PainFaceCount; $i++) {
            for ($j = 0; $j -lt [StatusBar]::face::StraightFaceCount; $j++) {
                $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFST$i$j")
            }
            $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFTR${i}0")
            $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFTL${i}0")
            $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFOUCH$i")
            $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFEVL$i")
            $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFKILL$i")
        }
        $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFGOD0")
        $this.Faces[$faceCount++] = [Patch]::FromWad($wad, "STFDEAD0")
    }
}

