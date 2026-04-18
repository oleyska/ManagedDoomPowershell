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

class Renderer {
    static [double[]] $GammaCorrectionParameters = @(
        1.00, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50
    )

    [Config] $Config
    [Palette] $Palette
    [DrawScreen] $Screen

    [MenuRenderer] $Menu
    [ThreeDRenderer] $ThreeD
    [StatusBarRenderer] $StatusBar
    [IntermissionRenderer] $Intermission
    [OpeningSequenceRenderer] $OpeningSequence
    [AutoMapRenderer] $AutoMap
    [FinaleRenderer] $Finale

    [Patch] $Pause

    [int] $WipeBandWidth
    [int] $WipeBandCount
    [int] $WipeHeight
    [byte[]] $WipeBuffer
    Renderer([Config] $config, [GameContent] $content) {
        $this.Config = $config
        $this.Palette = $content.Palette

        if ($config.video_highresolution) {
            $this.Screen = [DrawScreen]::new($content.Wad, 640, 400)
        } else {
            $this.Screen = [DrawScreen]::new($content.Wad, 320, 200)
        }


        $config.video_gamescreensize = [Math]::Clamp($config.video_gamescreensize, 0, [ThreeDRenderer]::MaxScreenSize)
        $config.video_gammacorrection = [Math]::Clamp($config.video_gammacorrection, 0, [Renderer]::GammaCorrectionParameters.Length - 1)

        $this.Menu = [MenuRenderer]::new($content.Wad, $this.Screen)
        $this.ThreeD = [ThreeDRenderer]::new($content, $this.Screen, $config.video_gamescreensize)
        $this.StatusBar = [StatusBarRenderer]::new($content.Wad, $this.Screen)
        $this.Intermission = [IntermissionRenderer]::new($content.Wad, $this.Screen)
        $this.OpeningSequence = [OpeningSequenceRenderer]::new($content.Wad, $this.Screen, $this)
        $this.AutoMap = [AutoMapRenderer]::new($content.Wad, $this.Screen)
        $this.Finale = [FinaleRenderer]::new($content, $this.Screen)

        $this.Pause = [Patch]::FromWad($content.Wad, "M_PAUSE")

        $scale = $this.Screen.Width / 320
        $this.WipeBandWidth = 2 * $scale
        $this.WipeBandCount = $this.Screen.Width / $this.WipeBandWidth + 1
        $this.WipeHeight = $this.Screen.Height / $scale
        $this.WipeBuffer = New-Object byte[] ($this.Screen.Data.Length)

        $this.Palette.ResetColors([Renderer]::GammaCorrectionParameters[$config.video_gammacorrection])
    }
    [void] RenderDoom([Doom] $doom, [Fixed] $frameFrac) {
        if ($doom.State -eq [DoomState]::Opening) {
            $this.OpeningSequence.Render($doom.Opening, $frameFrac)
        } elseif ($doom.State -eq [DoomState]::DemoPlayback) {
            $this.RenderGame($doom.DemoPlayback.Game, $frameFrac)
        } elseif ($doom.State -eq [DoomState]::Game) {
            $this.RenderGame($doom.Game, $frameFrac)
        }

        if (-not $doom.Menu.Active) {
            if ($doom.State -eq [DoomState]::Game -and
                $doom.Game.State -eq [GameState]::Level -and
                $doom.Game.Paused) {

                $scale = $this.Screen.Width / 320
                $this.Screen.DrawPatch(
                    $this.Pause,
                    ($this.Screen.Width - $scale * $this.Pause.Width) / 2,
                    4 * $scale,
                    $scale
                )
            }
        }
    }

    [void] RenderMenu([Doom] $doom) {
        if ($doom.Menu.Active) {
            $this.Menu.Render($doom.Menu)
        }
    }

    [void] RenderGame([DoomGame] $game, [Fixed] $frameFrac) {
        if ($game.Paused) {
            $frameFrac = [Fixed]::One
        }

        if ($game.State -eq [GameState]::Level) {
            $consolePlayer = $game.World.ConsolePlayer
            $displayPlayer = $game.World.DisplayPlayer
            
            if ($game.World.AutoMap.Visible) {
                $this.AutoMap.Render($consolePlayer)
                $this.StatusBar.Render($consolePlayer, $true)
            } else {
                $this.ThreeD.Render($displayPlayer, $frameFrac)
                if ($this.ThreeD.WindowSize -lt 8) {
                    $this.StatusBar.Render($consolePlayer, $true)
                } elseif ($this.ThreeD.WindowSize -eq [ThreeDRenderer]::MaxScreenSize) {
                    $this.StatusBar.Render($consolePlayer, $false)
                }
            }

            if ($this.Config.video_displaymessage -or [object]::ReferenceEquals($consolePlayer.Message, [DoomInfo]::Strings.MSGOFF)) {
                if ($consolePlayer.MessageTime -gt 0) {
                    $scale = $this.Screen.Width / 320
                    $this.Screen.DrawText($consolePlayer.Message, 0, 7 * $scale, $scale)
                }
            }
        } elseif ($game.State -eq [GameState]::Intermission) {
            $this.Intermission.Render($game.Intermission)
        } elseif ($game.State -eq [GameState]::Finale) {
            $this.Finale.Render($game.Finale)
        }
    }
    [void] Render([Doom] $doom, [Byte[]] $destination, [Fixed] $frameFrac) {
        if ($doom.Wiping) {
            $this.RenderWipe($doom, $destination)
            return
        }

        $this.RenderDoom($doom, $frameFrac)

        $this.RenderMenu($doom)

        $colors = $this.Palette.get_Item(0)

        if ($doom.State -eq [DoomState]::Game -and
            $doom.Game.State -eq [GameState]::Level) {
            $colors = $this.Palette.get_Item([Renderer]::GetPaletteNumber($doom.Game.World.ConsolePlayer))
        }
        elseif ($doom.State -eq [DoomState]::Opening -and
                $doom.Opening.State -eq [OpeningSequenceState]::Demo -and
                $doom.Opening.Game.State -eq [GameState]::Level) {
            $colors = $this.Palette.get_Item([Renderer]::GetPaletteNumber($doom.Opening.Game.World.ConsolePlayer))
        }
        elseif ($doom.State -eq [DoomState]::DemoPlayback -and
                $doom.DemoPlayback.Game.State -eq [GameState]::Level) {
            $colors = $this.Palette.get_Item([Renderer]::GetPaletteNumber($doom.DemoPlayback.Game.World.ConsolePlayer))
        }
        
        $this.WriteData($colors, $destination)
    }

    [void] RenderWipe([Doom] $doom, [byte[]] $destination) {
        $this.RenderDoom($doom, [Fixed]::One)

        $wipe = $doom.WipeEffect
        $scale = $this.Screen.Width / 320

        for ($i = 0; $i -lt ($this.WipeBandCount - 1); $i++) {
            $x1 = $this.WipeBandWidth * $i
            $x2 = $x1 + $this.WipeBandWidth
            $y1 = [Math]::Max($scale * $wipe.Y[$i], 0)
            $y2 = [Math]::Max($scale * $wipe.Y[$i + 1], 0)
            $dy = [float]($y2 - $y1) / $this.WipeBandWidth

            for ($x = $x1; $x -lt $x2; $x++) {
                $y = [int][MathF]::Round($y1 + $dy * ([int](($x - $x1) / 2) * 2)) #careful with int division
                $copyLength = $this.Screen.Height - $y

                if ($copyLength -gt 0) {
                    $srcPos = $this.Screen.Height * $x
                    $dstPos = $this.Screen.Height * $x + $y
                    [Array]::Copy($this.WipeBuffer, $srcPos, $this.Screen.Data, $dstPos, $copyLength)
                }
            }
        }

        $this.RenderMenu($doom)
        $this.WriteData($this.Palette.get_Item(0), $destination)
    }
    [void] InitializeWipe() {
        [Array]::Copy($this.Screen.Data, $this.WipeBuffer, $this.Screen.Data.Length)
    }

    [void] WriteData([uint[]] $colors, [byte[]] $destination) {
        $screenData = $this.screen.Data
        [BufferHelper]::WritePixels($destination, $colors, $screenData, $this.Screen.Width, $this.Screen.Height)
    }

    static [int] GetPaletteNumber([Player] $player) {
        $count = $player.DamageCount

        if ($player.Powers[[int][PowerType]::Strength] -ne 0) {
            # Slowly fade the berzerk out.
            $bzc = 12 - ($player.Powers[[int][PowerType]::Strength] -shr 6)
            if ($bzc -gt $count) {
                $count = $bzc
            }
        }

        [int] $mPalette = 0

        if ($count -ne 0) {
            $mPalette = ($count + 7) -shr 3
            if ($mPalette -ge [Palette]::DamageCount) {
                $mPalette = [Palette]::DamageCount - 1
            }
            $mPalette += [Palette]::DamageStart
        }
        elseif ($player.BonusCount -ne 0) {
            $mPalette = ($player.BonusCount + 7) -shr 3
            if ($mPalette -ge [Palette]::BonusCount) {
                $mPalette = [Palette]::BonusCount - 1
            }
            $mPalette += [Palette]::BonusStart
        }
        elseif ($player.Powers[[int][PowerType]::IronFeet] -gt 4 * 32 -or
                ($player.Powers[[int][PowerType]::IronFeet] -band 8) -ne 0) {
            $mPalette = [Palette]::IronFeet
        }
        else {
            $mPalette = 0
        }

        return $mPalette
    }
    [int] Width() {
        return $this.Screen.Width
    }

    [int] Height() {
        return $this.Screen.Height
    }

    [int] MaxWindowSize() {
        return [ThreeDRenderer]::MaxScreenSize
    }

    [int] GetWindowSize() {
        return $this.ThreeD.WindowSize
    }

    [void] SetWindowSize([int] $value) {
        $this.Config.video_gamescreensize = $value
        $this.ThreeD.SetWindowSize($value)
    }

    [bool] GetDisplayMessage() {
        return $this.Config.video_displaymessage
    }

    [void] SetDisplayMessage([bool] $value) {
        $this.Config.video_displaymessage = $value
    }

    [int] MaxGammaCorrectionLevel() {
        return $this.GammaCorrectionParameters.Length - 1
    }

    [int] GetGammaCorrectionLevel() {
        return $this.Config.video_gammacorrection
    }

    [void] SetGammaCorrectionLevel([int] $value) {
        $this.Config.video_gammacorrection = $value
        $this.Palette.ResetColors($this.GammaCorrectionParameters[$this.Config.video_gammacorrection])
    }
}
