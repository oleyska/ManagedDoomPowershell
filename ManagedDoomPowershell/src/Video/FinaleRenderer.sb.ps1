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

class FinaleRenderer {
    [Wad] $wad
    [IFlatLookup] $flats
    [ISpriteLookup] $sprites

    [DrawScreen] $screen
    [int] $scale

    [PatchCache] $cache

    FinaleRenderer([GameContent] $content, [DrawScreen] $screen) {
        $this.wad = $content.Wad
        $this.flats = $content.Flats
        $this.sprites = $content.Sprites -as [ISpriteLookup]

        $this.screen = $screen
        $this.scale = $screen.Width / 320

        $this.cache = [PatchCache]::new($this.wad)
    }

    [void] Render([Finale] $finale) {
        if ($finale.Stage -eq 2) {
            $this.RenderCast($finale)
            return
        }

        if ($finale.Stage -eq 0) {
            $this.RenderTextScreen($finale)
        } else {
            switch ($finale.Options.Episode) {
                1 { $this.DrawPatch("CREDIT", 0, 0) }
                2 { $this.DrawPatch("VICTORY2", 0, 0) }
                3 { $this.BunnyScroll($finale) }
                4 { $this.DrawPatch("ENDPIC", 0, 0) }
            }
        }
    }

    [void] RenderTextScreen([Finale] $finale) {
        $this.FillFlat($this.flats.get_Item($finale.Flat))

        # Draw some of the text onto the screen.
        $cx = 10 * $this.scale
        $cy = 17 * $this.scale
        $ch = 0

        $count = ($finale.Count - 10) / [Finale]::TextSpeed
        if ($count -lt 0) { $count = 0 }

        for (; $count -gt 0; $count--) {
            if ($ch -eq $finale.Text.Length) { break }

            $c = $finale.Text[$ch++]

            if ($c -eq "`n") {
                $cx = 10 * $this.scale
                $cy += 11 * $this.scale
                continue
            }

            $this.screen.DrawChar($c, $cx, $cy, $this.scale)
            $cx += $this.screen.MeasureChar($c, $this.scale)
        }
    }

    [void] BunnyScroll([Finale] $finale) {
        $scroll = 320 - $finale.Scrolled
        $this.DrawPatch("PFUB2", $scroll - 320, 0)
        $this.DrawPatch("PFUB1", $scroll, 0)

        if ($finale.ShowTheEnd) {
            $patch = switch ($finale.TheEndIndex) {
                1 { "END1" }
                2 { "END2" }
                3 { "END3" }
                4 { "END4" }
                5 { "END5" }
                6 { "END6" }
                default { "END0" }
            }

            $this.DrawPatch(
                $patch,
                (320 - 13 * 8) / 2,
                (240 - 8 * 8) / 2
            )
        }
    }

    [void] FillFlat([Flat] $flat) {
        $src = $flat.Data
        $dst = $this.screen.Data
        $mScale = $this.screen.Width / 320
        $xFrac = [Fixed]::One / $mScale - [Fixed]::Epsilon
        $step = [Fixed]::One / $mScale

        for ($x = 0; $x -lt $this.screen.Width; $x++) {
            $yFrac = [Fixed]::One / $mScale - [Fixed]::Epsilon
            $p = $this.screen.Height * $x

            for ($y = 0; $y -lt $this.screen.Height; $y++) {
                $spotX = $xFrac.ToIntFloor() -band 0x3F
                $spotY = $yFrac.ToIntFloor() -band 0x3F
                $dst[$p] = $src[($spotY -shl 6) + $spotX]
                $yFrac += $step
                $p++
            }
            $xFrac += $step
        }
    }

    [void] DrawPatch([string] $name, [int] $x, [int] $y) {
        $mScale = $this.screen.Width / 320
        $this.screen.DrawPatch($this.cache.get_Item($name), $mScale * $x, $mScale * $y, $mScale)
    }

    [void] RenderCast([Finale] $finale) {
        $this.DrawPatch("BOSSBACK", 0, 0)

        $frame = $finale.CastState.Frame -band 0x7fff
        $spriteDef = $this.sprites.Get_Item($finale.CastState.Sprite)
        $patch = $spriteDef.Frames[$frame].Patches[0]

        if ($spriteDef.Frames[$frame].Flip[0]) {
            $this.screen.DrawPatchFlip(
                $patch,
                $this.screen.Width / 2,
                $this.screen.Height - $this.scale * 30,
                $this.scale
            )
        } else {
            $this.screen.DrawPatch(
                $patch,
                $this.screen.Width / 2,
                $this.screen.Height - $this.scale * 30,
                $this.scale
            )
        }

        $width = $this.screen.MeasureText($finale.CastName, $this.scale)
        $this.screen.DrawText(
            $finale.CastName,
            ($this.screen.Width - $width) / 2,
            $this.screen.Height - $this.scale * 13,
            $this.scale
        )
    }
}
