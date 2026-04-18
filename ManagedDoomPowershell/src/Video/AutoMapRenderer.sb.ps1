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

class AutoMapRenderer {
    
    static [float] $pr = 8 * [DoomInfo]::MobjInfos[[int][MobjType]::Player].Radius.ToFloat() / 7
    static [float[]] $playerArrow = @(
        [float](-[AutoMapRenderer]::pr + [AutoMapRenderer]::pr / 8), [float]0.0, [float][AutoMapRenderer]::pr, [float]0.0, # -----
        [float][AutoMapRenderer]::pr, [float]0.0, [float]([AutoMapRenderer]::pr - [AutoMapRenderer]::pr / 2), [float]([AutoMapRenderer]::pr / 4), # ----->
        [float][AutoMapRenderer]::pr, [float]0.0, [float]([AutoMapRenderer]::pr - [AutoMapRenderer]::pr / 2), [float](-[AutoMapRenderer]::pr / 4),
        [float](-[AutoMapRenderer]::pr + [AutoMapRenderer]::pr / 8), [float]0.0, [float](-[AutoMapRenderer]::pr - [AutoMapRenderer]::pr / 8), [float]([AutoMapRenderer]::pr / 4), # >---->
        [float](-[AutoMapRenderer]::pr + [AutoMapRenderer]::pr / 8), [float]0.0, [float](-[AutoMapRenderer]::pr - [AutoMapRenderer]::pr / 8), [float](-[AutoMapRenderer]::pr / 4),
        [float](-[AutoMapRenderer]::pr + 3 * [AutoMapRenderer]::pr / 8), [float]0.0, [float](-[AutoMapRenderer]::pr + [AutoMapRenderer]::pr / 8), [float]([AutoMapRenderer]::pr / 4), # >>--->
        [float](-[AutoMapRenderer]::pr + 3 * [AutoMapRenderer]::pr / 8), [float]0.0, [float](-[AutoMapRenderer]::pr + [AutoMapRenderer]::pr / 8), [float](-[AutoMapRenderer]::pr / 4)
    )

    static [float] $tr = 16
    static [float[]] $thingTriangle = @(
        [float](-0.5 * [AutoMapRenderer]::tr), [float](-0.7 * [AutoMapRenderer]::tr), [float][AutoMapRenderer]::tr, [float]0.0,
        [float][AutoMapRenderer]::tr, [float]0.0, [float](-0.5 * [AutoMapRenderer]::tr), [float](0.7 * [AutoMapRenderer]::tr),
        [float](-0.5 * [AutoMapRenderer]::tr), [float](0.7 * [AutoMapRenderer]::tr), [float](-0.5 * [AutoMapRenderer]::tr), [float](-0.7 * [AutoMapRenderer]::tr)
    )
    static [int] $reds = (256 - 5 * 16)
    static [int] $redRange = 16
    static [int] $greens = (7 * 16)
    static [int] $greenRange = 16
    static [int] $grays = (6 * 16)
    static [int] $grayRange = 16
    static [int] $browns = (4 * 16)
    static [int] $brownRange = 16
    static [int] $yellows = (256 - 32 + 7)
    static [int] $yellowRange = 1
    static [int] $black = 0
    static [int] $white = (256 - 47)

    static [int] $background = [AutoMapRenderer]::black
    static [int] $wallColors = [AutoMapRenderer]::reds
    static [int] $wallRange = [AutoMapRenderer]::redRange
    static [int] $tsWallColors = [AutoMapRenderer]::grays
    static [int] $tsWallRange = [AutoMapRenderer]::grayRange
    static [int] $fdWallColors = [AutoMapRenderer]::browns
    static [int] $fdWallRange = [AutoMapRenderer]::brownRange
    static [int] $cdWallColors = [AutoMapRenderer]::yellows
    static [int] $cdWallRange = [AutoMapRenderer]::yellowRange
    static [int] $thingColors = [AutoMapRenderer]::greens
    static [int] $thingRange = [AutoMapRenderer]::greenRange
    static [int] $secretWallColors = [AutoMapRenderer]::wallColors
    static [int] $secretWallRange = [AutoMapRenderer]::wallRange

    static [int[]] $playerColors = @(
        [AutoMapRenderer]::greens,
        [AutoMapRenderer]::grays,
        [AutoMapRenderer]::browns,
        [AutoMapRenderer]::reds
    )

    [DrawScreen] $screen
    [int] $scale
    [int] $amWidth
    [int] $amHeight
    [float] $ppu

    [float] $minX
    [float] $maxX
    [float] $width
    [float] $minY
    [float] $maxY
    [float] $height

    [float] $actualViewX
    [float] $actualViewY
    [float] $zoom

    [float] $renderViewX
    [float] $renderViewY

    [Patch[]] $markNumbers

    AutoMapRenderer([Wad] $wad, [DrawScreen] $screen) {
        $this.screen = $screen
        $this.scale = $screen.Width / 320
        $this.amWidth = $screen.Width
        $this.amHeight = $screen.Height - $this.scale * [StatusBarRenderer]::Height
        $this.ppu = [float]$this.scale / 16

        $this.markNumbers = New-Object Patch[] 10
        for ($i = 0; $i -lt $this.markNumbers.Length; $i++) {
            $this.markNumbers[$i] = [Patch]::FromWad($wad, "AMMNUM$i")
        }
            #>
    }
    [void] Render([Player] $player) {
        $this.screen.FillRect(0, 0, $this.amWidth, $this.amHeight, [AutoMapRenderer]::background)
    
        $world = $player.Mobj.World
        $am = $world.AutoMap
    
        $this.minX = $am.MinX.ToFloat()
        $this.maxX = $am.MaxX.ToFloat()
        $this.width = $this.maxX - $this.minX
        $this.minY = $am.MinY.ToFloat()
        $this.maxY = $am.MaxY.ToFloat()
        $this.height = $this.maxY - $this.minY
    
        $this.actualViewX = $am.ViewX.ToFloat()
        $this.actualViewY = $am.ViewY.ToFloat()
        $this.zoom = $am.Zoom.ToFloat()
    
        # Align view to reduce line shake
        $this.renderViewX = [Math]::Round($this.zoom * $this.ppu * $this.actualViewX) / ($this.zoom * $this.ppu)
        $this.renderViewY = [Math]::Round($this.zoom * $this.ppu * $this.actualViewY) / ($this.zoom * $this.ppu)
    
        $autoMapLinesEnumerable = $world.Map.Lines
        if ($null -ne $autoMapLinesEnumerable) {
            $autoMapLinesEnumerator = $autoMapLinesEnumerable.GetEnumerator()
            for (; $autoMapLinesEnumerator.MoveNext(); ) {
                $line = $autoMapLinesEnumerator.Current
                $v1 = $this.ToScreenPos($line.Vertex1)
                $v2 = $this.ToScreenPos($line.Vertex2)

                $cheating = $am.State -ne [AutoMapState]::None

                if ($cheating -or ($line.Flags -band [LineFlags]::Mapped) -ne 0) {
                    if (($line.Flags -band [LineFlags]::DontDraw) -ne 0 -and -not $cheating) {
                        continue
                    }

                    if ($null -eq $line.BackSector) {
                        $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::wallColors)
                    } else {
                        if ($line.Special -eq 39) {
                            # Teleporters
                            $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::wallColors + [AutoMapRenderer]::wallRange / 2)
                        } elseif (($line.Flags -band [LineFlags]::Secret) -ne 0) {
                            # Secret doors
                            if ($cheating) {
                                $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::secretWallColors)
                            } else {
                                $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::wallColors)
                            }
                        } elseif ($line.BackSector.FloorHeight.Data -ne $line.FrontSector.FloorHeight.Data) {
                            # Floor level change
                            $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::fdWallColors)
                        } elseif ($line.BackSector.CeilingHeight.Data -ne $line.FrontSector.CeilingHeight.Data) {
                            # Ceiling level change
                            $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::cdWallColors)
                        } elseif ($cheating) {
                            $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::tsWallColors)
                        }
                    }
                } elseif ($player.Powers[[int][PowerType]::AllMap] -gt 0) {
                    if (($line.Flags -band [LineFlags]::DontDraw) -eq 0) {
                        $this.screen.DrawLine($v1.X, $v1.Y, $v2.X, $v2.Y, [AutoMapRenderer]::grays + 3)
                    }
                }

            }
        }
    
        for ($i = 0; $i -lt $am.Marks.Count; $i++) {
            $pos = $this.ToScreenPos($am.Marks[$i])
            $this.screen.DrawPatch(
                $this.markNumbers[$i],
                [Math]::Round($pos.X),
                [Math]::Round($pos.Y),
                $this.scale
            )
        }
    
        if ($am.State -eq [AutoMapState]::AllThings) {
            $this.DrawThings($world)
        }
    
        $this.DrawPlayers($world)
    
        if (-not $am.Follow) {
            $this.screen.DrawLine(
                $this.amWidth / 2 - 2 * $this.scale, $this.amHeight / 2,
                $this.amWidth / 2 + 2 * $this.scale, $this.amHeight / 2,
                [AutoMapRenderer]::grays
            )
    
            $this.screen.DrawLine(
                $this.amWidth / 2, $this.amHeight / 2 - 2 * $this.scale,
                $this.amWidth / 2, $this.amHeight / 2 + 2 * $this.scale,
                [AutoMapRenderer]::grays
            )
        }
    
        $this.screen.DrawText(
            $world.Map.Title,
            0,
            $this.amHeight - $this.scale,
            $this.scale
        )
    }
    [void] DrawPlayers([World] $world) {
        $options = $world.Options
        $players = $options.Players
        $consolePlayer = $world.ConsolePlayer
        $am = $world.AutoMap
    
        if (-not $options.NetGame) {
            $this.DrawCharacter($consolePlayer.Mobj, [AutoMapRenderer]::playerArrow, [AutoMapRenderer]::white)
            return
        }
    
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $player = $players[$i]
    
            if ($options.Deathmatch -ne 0 -and -not $options.DemoPlayback -and $player -ne $consolePlayer) {
                continue
            }
    
            if (-not $player.InGame) {
                continue
            }
    
            $color = if ($player.Powers[[int][PowerType]::Invisibility] -gt 0) { 246 } else { [AutoMapRenderer]::playerColors[$i] }
    
            $this.DrawCharacter($player.Mobj, [AutoMapRenderer]::playerArrow, $color)
        }
    }
    
    [void] DrawThings([World] $world) {
        $autoMapThinkersEnumerable = $world.Thinkers
        if ($null -ne $autoMapThinkersEnumerable) {
            $autoMapThinkersEnumerator = $autoMapThinkersEnumerable.GetEnumerator()
            for (; $autoMapThinkersEnumerator.MoveNext(); ) {
                $thinker = $autoMapThinkersEnumerator.Current
                $mobj = $thinker -as [Mobj]
                if ($null -ne $mobj) {
                    $this.DrawCharacter($mobj, [AutoMapRenderer]::thingTriangle, [AutoMapRenderer]::greens)
                }

            }
        }
    }
    
    [void] DrawCharacter([Mobj] $mobj, [float[]] $data, [int] $color) {
        $pos = $this.ToScreenPos($mobj.X, $mobj.Y)
        $sin = [Math]::Sin($mobj.Angle.ToRadian())
        $cos = [Math]::Cos($mobj.Angle.ToRadian())
    
        for ($i = 0; $i -lt $data.Length; $i += 4) {
            $x1 = $pos.X + $this.zoom * $this.ppu * ($cos * $data[$i] - $sin * $data[$i + 1])
            $y1 = $pos.Y - $this.zoom * $this.ppu * ($sin * $data[$i] + $cos * $data[$i + 1])
            $x2 = $pos.X + $this.zoom * $this.ppu * ($cos * $data[$i + 2] - $sin * $data[$i + 3])
            $y2 = $pos.Y - $this.zoom * $this.ppu * ($sin * $data[$i + 2] + $cos * $data[$i + 3])
            $this.screen.DrawLine($x1, $y1, $x2, $y2, $color)
        }
    }
    
    [DrawPos] ToScreenPos([Fixed] $x, [Fixed] $y) {
        $posX = $this.zoom * $this.ppu * ($x.ToFloat() - $this.renderViewX) + $this.amWidth / 2
        $posY = -$this.zoom * $this.ppu * ($y.ToFloat() - $this.renderViewY) + $this.amHeight / 2
        return [DrawPos]::new($posX, $posY)
    }
    
    [DrawPos] ToScreenPos([Vertex] $v) {
        $posX = $this.zoom * $this.ppu * ($v.X.ToFloat() - $this.renderViewX) + $this.amWidth / 2
        $posY = -$this.zoom * $this.ppu * ($v.Y.ToFloat() - $this.renderViewY) + $this.amHeight / 2
        return [DrawPos]::new($posX, $posY)
    }
}

class DrawPos {
    [float] $X
    [float] $Y

    DrawPos([float] $x, [float] $y) {
        $this.X = $x
        $this.Y = $y
    }
}
