class IntermissionRenderer {
    # GLOBAL LOCATIONS
    static [int] $titleY = 2
    static [int] $spacingY = 33

    # SINGLE-PLAYER STUFF
    static [int] $spStatsX = 50
    static [int] $spStatsY = 50
    static [int] $spTimeX = 16
    static [int] $spTimeY = 200 - 32

    # NET GAME STUFF
    static [int] $ngStatsY = 50
    static [int] $ngSpacingX = 64

    # DEATHMATCH STUFF
    static [int] $dmMatrixX = 42
    static [int] $dmMatrixY = 68
    static [int] $dmSpacingX = 40
    static [int] $dmTotalsX = 269
    static [int] $dmKillersX = 10
    static [int] $dmKillersY = 100
    static [int] $dmVictimsX = 5
    static [int] $dmVictimsY = 50

    static [string[]] $mapPictures = @("WIMAP0", "WIMAP1", "WIMAP2")
    static [string[]] $playerBoxes = @("STPB0", "STPB1", "STPB2", "STPB3")
    static [string[]] $youAreHere = @("WIURH0", "WIURH1")

    static [string[][]] $doomLevels
    static [string[]] $doom2Levels

    static IntermissionRenderer() {
        [IntermissionRenderer]::doomLevels = New-Object 'string[][]' (4)
        for ($e = 0; $e -lt 4; $e++) {
            [IntermissionRenderer]::doomLevels[$e] = New-Object 'string[]' (9)
            for ($m = 0; $m -lt 9; $m++) {
                [IntermissionRenderer]::doomLevels[$e][$m] = "WILV$e$m"
            }
        }

        [IntermissionRenderer]::doom2Levels = New-Object 'string[]' (32)
        for ($m = 0; $m -lt 32; $m++) {
            [IntermissionRenderer]::doom2Levels[$m] = "CWILV" + ("{0:D2}" -f $m)
        }
    }

    [Wad] $wad
    [DrawScreen] $screen
    [PatchCache] $cache
    [Patch] $minus
    [Patch[]] $numbers
    [Patch] $percent
    [Patch] $colon
    [int] $scale

    IntermissionRenderer([Wad] $wad, [DrawScreen] $screen) {
        $this.wad = $wad
        $this.screen = $screen

        $this.cache = [PatchCache]::new($wad)

        $this.minus = [Patch]::FromWad($wad, "WIMINUS")
        $this.numbers = New-Object 'Patch[]' (10)
        for ($i = 0; $i -lt 10; $i++) {
            $this.numbers[$i] = [Patch]::FromWad($wad, "WINUM$i")
        }
        $this.percent = [Patch]::FromWad($wad, "WIPCNT")
        $this.colon = [Patch]::FromWad($wad, "WICOLON")

        $this.scale = $screen.Width / 320
    }
    [void] DrawPatch([Patch] $patch, [int] $x, [int] $y) {
        $this.screen.DrawPatch($patch, $this.scale * $x, $this.scale * $y, $this.scale)
    }

    [void] DrawPatch([string] $name, [int] $x, [int] $y) {
        $mScale = $this.screen.Width / 320
        $this.screen.DrawPatch($this.cache.get_Item($name), $mScale * $x, $mScale * $y, $mScale)
    }

    [int] GetWidth([string] $name) {
        return $this.cache.GetWidth($name)
    }

    [int] GetHeight([string] $name) {
        return $this.cache.GetHeight($name)
    }

    [void] Render([Intermission] $im) {
        switch ($im.State) {
            {$_ -eq [IntermissionState]::StatCount} {
                if ($im.Options.Deathmatch -ne 0) {
                    $this.DrawDeathmatchStats($im)
                }
                elseif ($im.Options.NetGame) {
                    $this.DrawNetGameStats($im)
                }
                else {
                    $this.DrawSinglePlayerStats($im)
                }
                break
            }

            {$_ -eq [IntermissionState]::ShowNextLoc} {
                $this.DrawShowNextLoc($im)
                break
            }

            {$_ -eq [IntermissionState]::NoState} {
                $this.DrawNoState($im)
                break
            }
        }
    }
    [void] DrawBackground([Intermission] $im) {
        if ($im.Options.GameMode -eq [GameMode]::Commercial) {
            $this.DrawPatch("INTERPIC", 0, 0)
        }
        else {
            $e = $im.Options.Episode - 1
            if ($e -lt $this.mapPictures.Length) {
                $this.DrawPatch($this.mapPictures[$e], 0, 0)
            }
            else {
                $this.DrawPatch("INTERPIC", 0, 0)
            }
        }
    }

    [void] DrawSinglePlayerStats([Intermission] $im) {
        $this.DrawBackground($im)

        # Draw animated background
        $this.DrawBackgroundAnimation($im)

        # Draw level name
        $this.DrawFinishedLevelName($im)

        # Line height
        $lineHeight = (3 * $this.numbers[0].Height) / 2

        $this.DrawPatch(
            "WIOSTK",  # KILLS
            $this.spStatsX,
            $this.spStatsY
        )

        $this.DrawPercent(
            320 - $this.spStatsX,
            $this.spStatsY,
            $im.KillCount[0]
        )

        $this.DrawPatch(
            "WIOSTI",  # ITEMS
            $this.spStatsX,
            $this.spStatsY + $lineHeight
        )

        $this.DrawPercent(
            320 - $this.spStatsX,
            $this.spStatsY + $lineHeight,
            $im.ItemCount[0]
        )

        $this.DrawPatch(
            "WISCRT2",  # SECRET
            $this.spStatsX,
            $this.spStatsY + 2 * $lineHeight
        )

        $this.DrawPercent(
            320 - $this.spStatsX,
            $this.spStatsY + 2 * $lineHeight,
            $im.SecretCount[0]
        )

        $this.DrawPatch(
            "WITIME",  # TIME
            $this.spTimeX,
            $this.spTimeY
        )

        $this.DrawTime(
            (320 / 2) - $this.spTimeX,
            $this.spTimeY,
            $im.TimeCount
        )

        if ($im.Info.Episode -lt 3) {
            $this.DrawPatch(
                "WIPAR",  # PAR
                (320 / 2) + $this.spTimeX,
                $this.spTimeY
            )

            $this.DrawTime(
                320 - $this.spTimeX,
                $this.spTimeY,
                $im.ParCount
            )
        }
    }
    [void] DrawNetGameStats([Intermission] $im) {
        $this.DrawBackground($im)

        # Draw animated background.
        $this.DrawBackgroundAnimation($im)

        # Draw level name.
        $this.DrawFinishedLevelName($im)

        $ngStatsX = 32 + $this.GetWidth("STFST01") / 2
        if (-not $im.DoFrags) {
            $ngStatsX += 32
        }

        # Draw stat titles (top line).
        $this.DrawPatch(
            "WIOSTK",  # KILLS
            $ngStatsX + $this.ngSpacingX - $this.GetWidth("WIOSTK"),
            $this.ngStatsY
        )

        $this.DrawPatch(
            "WIOSTI",  # ITEMS
            $ngStatsX + 2 * $this.ngSpacingX - $this.GetWidth("WIOSTI"),
            $this.ngStatsY
        )

        $this.DrawPatch(
            "WIOSTS",  # SCRT
            $ngStatsX + 3 * $this.ngSpacingX - $this.GetWidth("WIOSTS"),
            $this.ngStatsY
        )

        if ($im.DoFrags) {
            $this.DrawPatch(
                "WIFRGS",  # FRAGS
                $ngStatsX + 4 * $this.ngSpacingX - $this.GetWidth("WIFRGS"),
                $this.ngStatsY
            )
        }

        # Draw stats.
        $y = $this.ngStatsY + $this.GetHeight("WIOSTK")

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if (-not $im.Options.Players[$i].InGame) {
                continue
            }

            $x = $ngStatsX

            $this.DrawPatch(
                $this.playerBoxes[$i],
                $x - $this.GetWidth($this.playerBoxes[$i]),
                $y
            )

            if ($i -eq $im.Options.ConsolePlayer) {
                $this.DrawPatch(
                    "STFST01",  # Player face
                    $x - $this.GetWidth($this.playerBoxes[$i]),
                    $y
                )
            }

            $x += $this.ngSpacingX

            $this.DrawPercent($x - $this.percent.Width, $y + 10, $im.KillCount[$i])
            $x += $this.ngSpacingX

            $this.DrawPercent($x - $this.percent.Width, $y + 10, $im.ItemCount[$i])
            $x += $this.ngSpacingX

            $this.DrawPercent($x - $this.percent.Width, $y + 10, $im.SecretCount[$i])
            $x += $this.ngSpacingX

            if ($im.DoFrags) {
                $this.DrawNumber($x, $y + 10, $im.FragCount[$i], -1)
            }

            $y += $this.spacingY
        }
    }

    [void] DrawDeathmatchStats([Intermission] $im) {
        $this.DrawBackground($im)

        # Draw animated background.
        $this.DrawBackgroundAnimation($im)

        # Draw level name.
        $this.DrawFinishedLevelName($im)

        # Draw stat titles (top line).
        $this.DrawPatch(
            "WIMSTT",  # TOTAL
            $this.dmTotalsX - $this.GetWidth("WIMSTT") / 2,
            $this.dmMatrixY - $this.spacingY + 10
        )

        $this.DrawPatch(
            "WIKILRS",  # KILLERS
            $this.dmKillersX,
            $this.dmKillersY
        )

        $this.DrawPatch(
            "WIVCTMS",  # VICTIMS
            $this.dmVictimsX,
            $this.dmVictimsY
        )

        # Draw player boxes.
        $x = $this.dmMatrixX + $this.dmSpacingX
        $y = $this.dmMatrixY

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($im.Options.Players[$i].InGame) {
                $this.DrawPatch(
                    $this.playerBoxes[$i],
                    $x - $this.GetWidth($this.playerBoxes[$i]) / 2,
                    $this.dmMatrixY - $this.spacingY
                )

                $this.DrawPatch(
                    $this.playerBoxes[$i],
                    $this.dmMatrixX - $this.GetWidth($this.playerBoxes[$i]) / 2,
                    $y
                )

                if ($i -eq $im.Options.ConsolePlayer) {
                    $this.DrawPatch(
                        "STFDEAD0",  # Player face (dead)
                        $x - $this.GetWidth($this.playerBoxes[$i]) / 2,
                        $this.dmMatrixY - $this.spacingY
                    )

                    $this.DrawPatch(
                        "STFST01",  # Player face
                        $this.dmMatrixX - $this.GetWidth($this.playerBoxes[$i]) / 2,
                        $y
                    )
                }
            }

            $x += $this.dmSpacingX
            $y += $this.spacingY
        }

        # Draw stats.
        $y = $this.dmMatrixY + 10
        $w = $this.numbers[0].Width

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $x = $this.dmMatrixX + $this.dmSpacingX

            if ($im.Options.Players[$i].InGame) {
                for ($j = 0; $j -lt [Player]::MaxPlayerCount; $j++) {
                    if ($im.Options.Players[$j].InGame) {
                        $this.DrawNumber($x + $w, $y, $im.DeathmatchFrags[$i][$j], 2)
                    }
                    $x += $this.dmSpacingX
                }

                $this.DrawNumber($this.dmTotalsX + $w, $y, $im.DeathmatchTotals[$i], 2)
            }

            $y += $this.spacingY
        }
    }

    [void] DrawNoState([Intermission] $im) {
        $this.DrawShowNextLoc($im)
    }
    [void] DrawShowNextLoc([Intermission] $im) {
        $this.DrawBackground($im)

        # Draw animated background.
        $this.DrawBackgroundAnimation($im)

        if ($im.Options.GameMode -ne [GameMode]::Commercial) {
            if ($im.Info.Episode -gt 2) {
                $this.DrawEnteringLevelName($im)
                return
            }

            $last = if ($im.Info.LastLevel -eq 8) { $im.Info.NextLevel - 1 } else { $im.Info.LastLevel }

            # Draw a splat on taken cities.
            for ($i = 0; $i -le $last; $i++) {
                $x = [WorldMap]::Locations[$im.Info.Episode][$i].X
                $y = [WorldMap]::Locations[$im.Info.Episode][$i].Y
                $this.DrawPatch("WISPLAT", $x, $y)
            }

            # Splat the secret level?
            if ($im.Info.DidSecret) {
                $x = [WorldMap]::Locations[$im.Info.Episode][8].X
                $y = [WorldMap]::Locations[$im.Info.Episode][8].Y
                $this.DrawPatch("WISPLAT", $x, $y)
            }

            # Draw "you are here".
            if ($im.ShowYouAreHere) {
                $x = [WorldMap]::Locations[$im.Info.Episode][$im.Info.NextLevel].X
                $y = [WorldMap]::Locations[$im.Info.Episode][$im.Info.NextLevel].Y
                $this.DrawSuitablePatch($this.youAreHere, $x, $y)
            }
        }

        # Draw next level name.
        if (($im.Options.GameMode -ne [GameMode]::Commercial) -or ($im.Info.NextLevel -ne 30)) {
            $this.DrawEnteringLevelName($im)
        }
    }

    [void] DrawFinishedLevelName([Intermission] $intermission) {
        $wbs = $intermission.Info
        $y = $this.titleY

        $levelName = if ($intermission.Options.GameMode -ne [GameMode]::Commercial) {
            $e = $intermission.Options.Episode - 1
            $this.doomLevels[$e][$wbs.LastLevel]
        } else {
            $this.doom2Levels[$wbs.LastLevel]
        }

        # Draw level name.
        $this.DrawPatch(
            $levelName,
            (320 - $this.GetWidth($levelName)) / 2,
            $y
        )

        # Draw "Finished!".
        $y += (5 * $this.GetHeight($levelName)) / 4

        $this.DrawPatch(
            "WIF",
            (320 - $this.GetWidth("WIF")) / 2,
            $y
        )
    }

    [void] DrawEnteringLevelName([Intermission] $im) {
        $wbs = $im.Info
        $y = $this.titleY

        $levelName = if ($im.Options.GameMode -ne [GameMode]::Commercial) {
            $e = $im.Options.Episode - 1
            $this.doomLevels[$e][$wbs.NextLevel]
        } else {
            $this.doom2Levels[$wbs.NextLevel]
        }

        # Draw "Entering".
        $this.DrawPatch(
            "WIENTER",
            (320 - $this.GetWidth("WIENTER")) / 2,
            $y
        )

        # Draw level name.
        $y += (5 * $this.GetHeight($levelName)) / 4

        $this.DrawPatch(
            $levelName,
            (320 - $this.GetWidth($levelName)) / 2,
            $y
        )
    }
    [int] DrawNumber([int] $x, [int] $y, [int] $n, [int] $digits) {
        if ($digits -lt 0) {
            if ($n -eq 0) {
                # Make variable-length zeros 1 digit long.
                $digits = 1
            } else {
                # Figure out number of digits.
                $digits = 0
                $temp = if ($n -lt 0) { -$n } else { $n }
                while ($temp -ne 0) {
                    $temp = [int][Math]::Truncate($temp / 10)
                    $digits++
                }
            }
        }

        $neg = $n -lt 0
        if ($neg) {
            $n = -$n
        }

        # If non-number, do not draw it.
        if ($n -eq 1994) {
            return 0
        }

        $fontWidth = $this.numbers[0].Width

        # Draw the new number.
        while ($digits-- -ne 0) {
            $x -= $fontWidth
            $this.DrawPatch($this.numbers[$n % 10], $x, $y)
            $n = [int][Math]::Truncate($n / 10)
        }

        # Draw a minus sign if necessary.
        if ($neg) {
            $x -= 8
            $this.DrawPatch($this.minus, $x, $y)
        }

        return $x
    }

    [void] DrawPercent([int] $x, [int] $y, [int] $p) {
        if ($p -lt 0) {
            return
        }

        $this.DrawPatch($this.percent, $x, $y)
        $this.DrawNumber($x, $y, $p, -1)
    }

    [void] DrawTime([int] $x, [int] $y, [int] $t) {
        if ($t -lt 0) {
            return
        }

        if ($t -le (61 * 59)) {
            $div = 1

            do {
                $n = ($t / $div) % 60
                $x = $this.DrawNumber($x, $y, $n, 2) - $this.colon.Width
                $div *= 60

                # Draw.
                if ($div -eq 60 -or $t / $div -ne 0) {
                    $this.DrawPatch($this.colon, $x, $y)
                }
            }
            while ($t / $div -ne 0)
        } else {
            $this.DrawPatch(
                "WISUCKS",  # SUCKS
                $x - $this.GetWidth("WISUCKS"),
                $y
            )
        }
    }

    [void] DrawBackgroundAnimation([Intermission] $im) {
        if ($im.Options.GameMode -eq [GameMode]::Commercial) {
            return
        }

        if ($im.Info.Episode -gt 2) {
            return
        }

        for ($i = 0; $i -lt $im.Animations.Length; $i++) {
            $a = $im.Animations[$i]
            if ($a.PatchNumber -ge 0) {
                $this.DrawPatch($a.Patches[$a.PatchNumber], $a.LocationX, $a.LocationY)
            }
        }
    }
    [void] DrawSuitablePatch([string[]] $candidates, [int] $x, [int] $y) {
        $fits = $false
        $i = 0

        do {
            $patch = $this.cache.get_Item($candidates[$i])

            $left = $x - $patch.LeftOffset
            $top = $y - $patch.TopOffset
            $right = $left + $patch.Width
            $bottom = $top + $patch.Height

            if ($left -ge 0 -and $right -lt 320 -and $top -ge 0 -and $bottom -lt 320) {
                $fits = $true
            } else {
                $i++
            }
        }
        while (-not $fits -and $i -ne 2)

        if ($fits -and $i -lt 2) {
            $this.DrawPatch($candidates[$i], $x, $y)
        } else {
            throw [System.Exception]::new("Could not place patch!")
        }
    }
}
