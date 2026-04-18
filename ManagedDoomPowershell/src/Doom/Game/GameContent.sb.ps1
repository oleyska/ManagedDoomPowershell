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

class GameContent {
    [Wad] $Wad
    [Palette] $Palette
    [ColorMap] $ColorMap
    [ITextureLookup] $Textures
    [IFlatLookup] $Flats
    [ISpriteLookup] $Sprites
    [TextureAnimation] $Animation

    GameContent() {
    }

    GameContent($args) {
        $mArgs = [CommandLineArgs]::new($args)
        $this.Wad = [Wad]::new([ConfigUtilities]::GetWadPaths($mArgs))

        [DeHackEd]::Initialize($mArgs, $this.Wad)

        $this.Palette = [Palette]::new($this.Wad)
        $this.ColorMap = [ColorMap]::new($this.Wad)
        $this.Textures = [TextureLookup]::new($this.Wad)
        $this.Flats = [FlatLookup]::new($this.Wad)
        $this.Sprites = [SpriteLookup]::new($this.Wad)
        $this.Animation = [TextureAnimation]::new($this.Textures, $this.Flats)
    }

    static [GameContent] CreateDummy([string[]] $wadPaths) {
        $gc = [GameContent]::new()

        $gc.Wad = [Wad]::new($wadPaths)
        $gc.Palette = [Palette]::new($gc.Wad)
        $gc.ColorMap = [ColorMap]::new($gc.Wad)
        $gc.Textures = [DummyTextureLookup]::new($gc.Wad)
        $gc.Flats = [DummyFlatLookup]::new($gc.Wad)
        $gc.Sprites = [DummySpriteLookup]::new($gc.Wad)
        $gc.Animation = [TextureAnimation]::new($gc.Textures, $gc.Flats)

        return $gc
    }

    [void] Dispose() {
        if ($null -ne $this.Wad) {
            $this.Wad.Dispose()
            $this.Wad = $null
        }
    }
}