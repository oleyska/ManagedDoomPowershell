class Map {
    hidden [ITextureLookup] $textures
    hidden [IFlatLookup] $flats
    hidden [TextureAnimation] $animation
    hidden [World] $world
    hidden [Vertex[]] $vertices
    hidden [Sector[]] $sectors
    hidden [SideDef[]] $sides
    hidden [LineDef[]] $lines
    hidden [Seg[]] $segs
    hidden [Subsector[]] $subsectors
    hidden [Node[]] $nodes
    hidden [MapThing[]] $things
    hidden [BlockMap] $blockMap
    hidden [Reject] $reject
    hidden [Texture] $skyTexture
    hidden [string] $title

    Map([GameContent]$resorces, [World]$world) {
        $this.textures = $resorces.Textures
        $this.flats = $resorces.Flats
        $this.animation = $resorces.Animation
        $this.world = $world
        #duplicate constructor and this.new doesn't quite work.
        $this.InitializeMap($resorces.Wad, $this.textures, $this.flats, $this.animation, $this.world)
    }

    hidden [void] InitializeMap([Wad]$wad, [ITextureLookup]$textures, [IFlatLookup]$flats, [TextureAnimation]$animation, [World]$world) {
        try {
            $this.textures = $textures
            $this.flats = $flats
            $this.animation = $animation
            $this.world = $world

            $options = $world.Options

            if ($wad.GameMode -eq [GameMode]::Commercial) {
                $name = "MAP$($options.Map.ToString('00'))"
            } else {
                $name = "E$($options.Episode)M$($options.Map)"
            }

            [Console]::Write("Load map '$name': ")

            $map = $wad.GetLumpNumber($name)

            if ($map -eq -1) {
                throw "Map '$name' was not found!"
            }

            $this.vertices = [Vertex]::FromWad($wad, $map + 4)
            $this.sectors = [Sector]::FromWad($wad, $map + 8, $flats)
            $this.sides = [SideDef]::FromWad($wad, $map + 3, $textures, $this.sectors)
            $this.lines = [LineDef]::FromWad($wad, $map + 2, $this.vertices, $this.sides)
            $this.segs = [Seg]::FromWad($wad, $map + 5, $this.vertices, $this.lines)
            $this.subsectors = [Subsector]::FromWad($wad, $map + 6, $this.segs)
            $this.nodes = [Node]::FromWad($wad, $map + 7, $this.subsectors)
            $this.things = [MapThing]::FromWad($wad, $map + 1)
            $this.blockMap = [BlockMap]::FromWad($wad, $map + 10, $this.lines)
            $this.reject = [Reject]::FromWad($wad, $map + 9, $this.sectors)

            $this.GroupLines()
            $this.skyTexture = $this.GetSkyTextureByMapName($name)

            if ($options.GameMode -eq [GameMode]::Commercial) {
                switch ($options.MissionPack) {
                    ([MissionPack]::Plutonia) { $this.title = [Map]::ResolveTitle([DoomInfo]::MapTitles.Plutonia[$options.Map - 1]) }
                    ([MissionPack]::Tnt) { $this.title = [Map]::ResolveTitle([DoomInfo]::MapTitles.Tnt[$options.Map - 1]) }
                    default { $this.title = [Map]::ResolveTitle([DoomInfo]::MapTitles.Doom2[$options.Map - 1]) }
                }
            } else {
                $this.title = [Map]::ResolveTitle([DoomInfo]::MapTitles.Doom[$options.Episode - 1][$options.Map - 1])
            }

            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_
        }
    }

    hidden static [string] ResolveTitle([object] $title) {
        $null = [DoomInfo]::Strings

        if ($title -is [DoomString]) {
            return $title.ToString()
        }

        $name = [string]$title
        if ([DoomString]::NameTable.ContainsKey($name)) {
            return [DoomString]::NameTable[$name].ToString()
        }

        return $name
    }

    hidden [void] GroupLines() {
        $sectorLines = New-Object 'System.Collections.Generic.List[LineDef]'
        $boundingBox = New-Object 'Fixed[]' 4

        $mapLinesEnumerable = $this.lines
        if ($null -ne $mapLinesEnumerable) {
            $mapLinesEnumerator = $mapLinesEnumerable.GetEnumerator()
            for (; $mapLinesEnumerator.MoveNext(); ) {
                $line = $mapLinesEnumerator.Current
                if ($line.Special -ne 0) {
                    $so = [Mobj]::new($this.world)
                    $so.X = ($line.Vertex1.X + $line.Vertex2.X) / 2
                    $so.Y = ($line.Vertex1.Y + $line.Vertex2.Y) / 2
                    $line.SoundOrigin = $so
                }

            }
        }

        $mapSectorsEnumerable = $this.sectors
        if ($null -ne $mapSectorsEnumerable) {
            $mapSectorsEnumerator = $mapSectorsEnumerable.GetEnumerator()
            for (; $mapSectorsEnumerator.MoveNext(); ) {
                $sector = $mapSectorsEnumerator.Current
                $sectorLines.Clear()
                [Box]::Clear($boundingBox)

                $sectorCandidateLinesEnumerable = $this.lines
                if ($null -ne $sectorCandidateLinesEnumerable) {
                    $sectorCandidateLinesEnumerator = $sectorCandidateLinesEnumerable.GetEnumerator()
                    for (; $sectorCandidateLinesEnumerator.MoveNext(); ) {
                        $line = $sectorCandidateLinesEnumerator.Current
                        if (($line.FrontSector -eq $sector) -or ($line.BackSector -eq $sector)) {
                            $sectorLines.Add($line)
                            [Box]::AddPoint($boundingBox, $line.Vertex1.X, $line.Vertex1.Y)
                            [Box]::AddPoint($boundingBox, $line.Vertex2.X, $line.Vertex2.Y)
                        }

                    }
                }

                $sector.Lines = $sectorLines.ToArray()
                $sector.SoundOrigin = [Mobj]::new($this.world)
                $sector.SoundOrigin.X = ($boundingBox[[Box]::Right] + $boundingBox[[Box]::Left]) / 2
                $sector.SoundOrigin.Y = ($boundingBox[[Box]::Top] + $boundingBox[[Box]::Bottom]) / 2

                $sector.BlockBox = New-Object int[] 4
                $block = ($boundingBox[[Box]::Top] - $this.blockMap.OriginY + [GameConst]::MaxThingRadius).Data -shr [BlockMap]::FracToBlockShift
                $sector.BlockBox[[Box]::Top] = [math]::Min($block, $this.blockMap.Height - 1)

                $block = ($boundingBox[[Box]::Bottom] - $this.blockMap.OriginY - [GameConst]::MaxThingRadius).Data -shr [BlockMap]::FracToBlockShift
                $sector.BlockBox[[Box]::Bottom] = [math]::Max($block, 0)

                $block = ($boundingBox[[Box]::Right] - $this.blockMap.OriginX + [GameConst]::MaxThingRadius).Data -shr [BlockMap]::FracToBlockShift
                $sector.BlockBox[[Box]::Right] = [math]::Min($block, $this.blockMap.Width - 1)

                $block = ($boundingBox[[Box]::Left] - $this.blockMap.OriginX - [GameConst]::MaxThingRadius).Data -shr [BlockMap]::FracToBlockShift
                $sector.BlockBox[[Box]::Left] = [math]::Max($block, 0)

            }
        }
    }

    hidden [Texture] GetSkyTextureByMapName([string]$name) {
        if ($name.Length -eq 4) {
            switch ($name[1]) {
                '1' { return $this.textures.get_Item("SKY1") }
                '2' { return $this.textures.get_Item("SKY2") }
                '3' { return $this.textures.get_Item("SKY3") }
                default { return $this.textures.get_Item("SKY4") }
            }
        } else {
            $number = [int]$name.Substring(3)
            if ($number -le 11) { return $this.textures.get_Item("SKY1") }
            elseif ($number -le 21) { return $this.textures.get_Item("SKY2") }
            else { return $this.textures.get_Item("SKY3") }
            
        }
        return $this.textures.get_Item("SKY3") # last resort, Powershell needs this...
    }
    static $e4BgmList = [Bgm[]]@(
    [Bgm]::E3M4 # American   e4m1
    [Bgm]::E3M2 # Romero     e4m2
    [Bgm]::E3M3 # Shawn      e4m3
    [Bgm]::E1M5 # American   e4m4
    [Bgm]::E2M7 # Tim        e4m5
    [Bgm]::E2M4 # Romero     e4m6
    [Bgm]::E2M6 # J.Anderson e4m7 CHIRON.WAD
    [Bgm]::E2M5 # Shawn      e4m8
    [Bgm]::E1M9 # Tim        e4m9
)

    [ITextureLookup] get_Textures() { return $this.textures }
    [IFlatLookup] get_Flats() { return $this.flats }
    [TextureAnimation] get_Animation() { return $this.animation }
    [Texture] get_SkyTexture() { return $this.skyTexture }
    [string] get_Title() { return $this.title }

    static [Bgm] GetMapBgm([GameOptions]$options) {
        if ($options.GameMode -eq [GameMode]::Commercial) {
            return [Bgm]::RUNNIN + $options.Map - 1
        } elseif ($options.Episode -lt 4) {
            return [Bgm]::E1M1 + ($options.Episode - 1) * 9 + $options.Map - 1
        } else {
            return [map]::e4BgmList[$options.Map - 1]
        }
    }
}
