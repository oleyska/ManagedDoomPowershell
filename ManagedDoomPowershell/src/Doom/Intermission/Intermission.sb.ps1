class Intermission {
    [GameOptions]$options
    [IntermissionInfo]$info
    [PlayerScores[]]$scores
    [bool]$accelerateStage
    [IntermissionState]$state
    [int[]]$killCount
    [int[]]$itemCount
    [int[]]$secretCount
    [int[]]$fragCount
    [int]$timeCount
    [int]$parCount
    [int]$pauseCount
    [int]$spState
    [int]$ngState
    [bool]$doFrags
    [int]$dmState
    [int[][]]$dmFragCount
    [int[]]$dmTotalCount
    [DoomRandom]$random
    [Animation[]]$animations
    [bool]$showYouAreHere
    [int]$count
    [int]$bgCount
    [bool]$completed

    Intermission([GameOptions]$options, [IntermissionInfo]$info) {
        $this.options = $options
        $this.info = $info
        $this.scores = $info.Players

        $this.killCount = @(0) * [Player]::MaxPlayerCount
        $this.itemCount = @(0) * [Player]::MaxPlayerCount
        $this.secretCount = @(0) * [Player]::MaxPlayerCount
        $this.fragCount = @(0) * [Player]::MaxPlayerCount

        $this.dmFragCount = @()
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.dmFragCount += @(@(0) * [Player]::MaxPlayerCount)
        }
        $this.dmTotalCount = @(0) * [Player]::MaxPlayerCount

        if ($options.Deathmatch -ne 0) {
            $this.InitDeathmatchStats()
        } elseif ($options.NetGame) {
            $this.InitNetGameStats()
        } else {
            $this.InitSinglePLayerStats()
        }

        $this.completed = $false
    }

    [void]InitSinglePLayerStats() {
        $this.state = [IntermissionState]::StatCount
        $this.accelerateStage = $false
        $this.spState = 1
        $this.killCount[0] = $this.itemCount[0] = $this.secretCount[0] = -1
        $this.timeCount = $this.parCount = -1
        $this.pauseCount = [GameConst]::TicRate
        $this.InitAnimatedBack()
    }

    [void]InitNetGameStats() {
        $this.state = [IntermissionState]::StatCount
        $this.accelerateStage = $false
        $this.ngState = 1
        $this.pauseCount = [GameConst]::TicRate

        $frags = 0
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if (-not $this.options.Players[$i].InGame) {
                continue
            }

            $this.killCount[$i] = $this.itemCount[$i] = $this.secretCount[$i] = $this.fragCount[$i] = 0
            $frags += $this.GetFragSum($i)
        }
        $this.doFrags = $frags -gt 0
        $this.InitAnimatedBack()
    }

    [void]InitDeathmatchStats() {
        $this.state = [IntermissionState]::StatCount
        $this.accelerateStage = $false
        $this.dmState = 1
        $this.pauseCount = [GameConst]::TicRate

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($this.options.Players[$i].InGame) {
                for ($j = 0; $j -lt [Player]::MaxPlayerCount; $j++) {
                    if ($this.options.Players[$j].InGame) {
                        $this.dmFragCount[$i][$j] = 0
                    }
                }
                $this.dmTotalCount[$i] = 0
            }
        }

        $this.InitAnimatedBack()
    }

    [void]InitNoState() {
        $this.state = [IntermissionState]::NoState
        $this.accelerateStage = $false
        $this.count = 10
    }

    [void]InitShowNextLoc() {
        $this.state = [IntermissionState]::ShowNextLoc
        $this.accelerateStage = $false
        $this.count = [Intermission]::showNextLocDelay * [GameConst]::TicRate
        $this.InitAnimatedBack()
    }

    [void]InitAnimatedBack() {
        if ($this.options.GameMode -eq [GameMode]::Commercial) {
            return
        }

        if ($this.info.Episode -gt 2) {
            return
        }

        if (-not $this.animations) {
            $this.animations = @()
            for ($i = 0; $i -lt [AnimationInfo]::Episodes[$this.info.Episode].Count; $i++) {
                $this.animations += [Animation]::new($this, [AnimationInfo]::Episodes[$this.info.Episode][$i], $i)
            }
            $this.random = [DoomRandom]::new()
        }

        foreach ($animation in $this.animations) {
            $animation.Reset($this.bgCount)
        }
    }

    [UpdateResult]Update() {
        $this.bgCount++

        $this.CheckForAccelerate()

        if ($this.bgCount -eq 1) {
            if ($this.options.GameMode -eq [GameMode]::Commercial) {
                $this.options.Music.StartMusic([Bgm]::DM2INT, $true)
            } else {
                $this.options.Music.StartMusic([Bgm]::INTER, $true)
            }
        }

        switch ($this.state) {
            [IntermissionState]::StatCount {
                if ($this.options.Deathmatch -ne 0) {
                    $this.UpdateDeathmatchStats()
                } elseif ($this.options.NetGame) {
                    $this.UpdateNetGameStats()
                } else {
                    $this.UpdateSinglePlayerStats()
                }
                break
            }

            [IntermissionState]::ShowNextLoc {
                $this.UpdateShowNextLoc()
                break
            }

            [IntermissionState]::NoState {
                $this.UpdateNoState()
                break
            }
        }

        if ($this.completed) {
            return [UpdateResult]::Completed
        } else {
            if ($this.bgCount -eq 1) {
                return [UpdateResult]::NeedWipe
            } else {
                return [UpdateResult]::None
            }
        }
    }

    [void]UpdateSinglePlayerStats() {
        $this.UpdateAnimatedBack()

        if ($this.accelerateStage -and $this.spState -ne 10) {
            $this.accelerateStage = $false
            $this.killCount[0] = ($this.scores[0].KillCount * 100) / $this.info.MaxKillCount
            $this.itemCount[0] = ($this.scores[0].ItemCount * 100) / $this.info.MaxItemCount
            $this.secretCount[0] = ($this.scores[0].SecretCount * 100) / $this.info.MaxSecretCount
            $this.timeCount = $this.scores[0].Time / [GameConst]::TicRate
            $this.parCount = $this.info.ParTime / [GameConst]::TicRate
            $this.StartSound([Sfx]::BAREXP)
            $this.spState = 10
        }

        switch ($this.spState) {
            2 {
                $this.killCount[0] += 2
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                if ($this.killCount[0] -ge ($this.scores[0].KillCount * 100) / $this.info.MaxKillCount) {
                    $this.killCount[0] = ($this.scores[0].KillCount * 100) / $this.info.MaxKillCount
                    $this.StartSound([Sfx]::BAREXP)
                    $this.spState++
                }
                break
            }
            4 {
                $this.itemCount[0] += 2
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                if ($this.itemCount[0] -ge ($this.scores[0].ItemCount * 100) / $this.info.MaxItemCount) {
                    $this.itemCount[0] = ($this.scores[0].ItemCount * 100) / $this.info.MaxItemCount
                    $this.StartSound([Sfx]::BAREXP)
                    $this.spState++
                }
                break
            }
            6 {
                $this.secretCount[0] += 2
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                if ($this.secretCount[0] -ge ($this.scores[0].SecretCount * 100) / $this.info.MaxSecretCount) {
                    $this.secretCount[0] = ($this.scores[0].SecretCount * 100) / $this.info.MaxSecretCount
                    $this.StartSound([Sfx]::BAREXP)
                    $this.spState++
                }
                break
            }
            8 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                $this.timeCount += 3
                if ($this.timeCount -ge $this.scores[0].Time / [GameConst]::TicRate) {
                    $this.timeCount = $this.scores[0].Time / [GameConst]::TicRate
                }

                $this.parCount += 3
                if ($this.parCount -ge $this.info.ParTime / [GameConst]::TicRate) {
                    $this.parCount = $this.info.ParTime / [GameConst]::TicRate
                    if ($this.timeCount -ge $this.scores[0].Time / [GameConst]::TicRate) {
                        $this.StartSound([Sfx]::BAREXP)
                        $this.spState++
                    }
                }
                break
            }
            10 {
                if ($this.accelerateStage) {
                    $this.StartSound([Sfx]::SGCOCK)

                    if ($this.options.GameMode -eq [GameMode]::Commercial) {
                        $this.InitNoState()
                    } else {
                        $this.InitShowNextLoc()
                    }
                }
                break
            }
            default {
                if (($this.spState -band 1) -ne 0) {
                    if (--$this.pauseCount -eq 0) {
                        $this.spState++
                        $this.pauseCount = [GameConst]::TicRate
                    }
                }
                break
            }
        }
    }

    [void]UpdateNetGameStats() {
        $this.UpdateAnimatedBack()

        $stillTicking = $false
        if ($this.accelerateStage -and $this.ngState -ne 10) {
            $this.accelerateStage = $false
            for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                if (-not $this.options.Players[$i].InGame) {
                    continue
                }

                $this.killCount[$i] = ($this.scores[$i].KillCount * 100) / $this.info.MaxKillCount
                $this.itemCount[$i] = ($this.scores[$i].ItemCount * 100) / $this.info.MaxItemCount
                $this.secretCount[$i] = ($this.scores[$i].SecretCount * 100) / $this.info.MaxSecretCount
            }
            $this.StartSound([Sfx]::BAREXP)
            $this.ngState = 10
        }

        switch ($this.ngState) {
            2 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }
                $stillTicking = $false
                for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                    if (-not $this.options.Players[$i].InGame) {
                        continue
                    }

                    $this.killCount[$i] += 2
                    if ($this.killCount[$i] -ge ($this.scores[$i].KillCount * 100) / $this.info.MaxKillCount) {
                        $this.killCount[$i] = ($this.scores[$i].KillCount * 100) / $this.info.MaxKillCount
                    } else {
                        $stillTicking = $true
                    }
                }

                if (-not $stillTicking) {
                    $this.StartSound([Sfx]::BAREXP)
                    $this.ngState++
                }
                break
            }
            4 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                $stillTicking = $false
                for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                    if (-not $this.options.Players[$i].InGame) {
                        continue
                    }

                    $this.itemCount[$i] += 2
                    if ($this.itemCount[$i] -ge ($this.scores[$i].ItemCount * 100) / $this.info.MaxItemCount) {
                        $this.itemCount[$i] = ($this.scores[$i].ItemCount * 100) / $this.info.MaxItemCount
                    } else {
                        $stillTicking = $true
                    }
                }

                if (-not $stillTicking) {
                    $this.StartSound([Sfx]::BAREXP)
                    $this.ngState++
                }
                break
            }
            6 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                $stillTicking = $false
                for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                    if (-not $this.options.Players[$i].InGame) {
                        continue
                    }

                    $this.secretCount[$i] += 2
                    if ($this.secretCount[$i] -ge ($this.scores[$i].SecretCount * 100) / $this.info.MaxSecretCount) {
                        $this.secretCount[$i] = ($this.scores[$i].SecretCount * 100) / $this.info.MaxSecretCount
                    } else {
                        $stillTicking = $true
                    }
                }

                if (-not $stillTicking) {
                    $this.StartSound([Sfx]::BAREXP)
                    if ($this.doFrags) {
                        $this.ngState++
                    } else {
                        $this.ngState += 3
                    }
                }
                break
            }
            8 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                $stillTicking = $false
                for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                    if (-not $this.options.Players[$i].InGame) {
                        continue
                    }

                    $this.fragCount[$i] += 1
                    $sum = $this.GetFragSum($i)
                    if ($this.fragCount[$i] -ge $sum) {
                        $this.fragCount[$i] = $sum
                    } else {
                        $stillTicking = $true
                    }
                }

                if (-not $stillTicking) {
                    $this.StartSound([Sfx]::PLDETH)
                    $this.ngState++
                }
                break
            }
            10 {
                if ($this.accelerateStage) {
                    $this.StartSound([Sfx]::SGCOCK)
                    if ($this.options.GameMode -eq [GameMode]::Commercial) {
                        $this.InitNoState()
                    } else {
                        $this.InitShowNextLoc()
                    }
                }
                break
            }
            default {
                if (($this.ngState -band 1) -ne 0) {
                    if (--$this.pauseCount -eq 0) {
                        $this.ngState++
                        $this.pauseCount = [GameConst]::TicRate
                    }
                }
                break
            }
        }
    }

    [void]UpdateDeathmatchStats() {
        $this.UpdateAnimatedBack()

        $stillticking = $false
        if ($this.accelerateStage -and $this.dmState -ne 4) {
            $this.accelerateStage = $false

            for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                if ($this.options.Players[$i].InGame) {
                    for ($j = 0; $j -lt [Player]::MaxPlayerCount; $j++) {
                        if ($this.options.Players[$j].InGame) {
                            $this.dmFragCount[$i][$j] = $this.scores[$i].Frags[$j]
                        }
                    }
                    $this.dmTotalCount[$i] = $this.GetFragSum($i)
                }
            }

            $this.StartSound([Sfx]::BAREXP)

            $this.dmState = 4
        }

        switch ($this.dmState) {
            2 {
                if (($this.bgCount -band 3) -eq 0) {
                    $this.StartSound([Sfx]::PISTOL)
                }

                $stillticking = $false
                for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                    if ($this.options.Players[$i].InGame) {
                        for ($j = 0; $j -lt [Player]::MaxPlayerCount; $j++) {
                            if ($this.options.Players[$j].InGame -and $this.dmFragCount[$i][$j] -ne $this.scores[$i].Frags[$j]) {
                                if ($this.scores[$i].Frags[$j] -lt 0) {
                                    $this.dmFragCount[$i][$j]--
                                } else {
                                    $this.dmFragCount[$i][$j]++
                                }

                                if ($this.dmFragCount[$i][$j] -gt 99) {
                                    $this.dmFragCount[$i][$j] = 99
                                }

                                if ($this.dmFragCount[$i][$j] -lt -99) {
                                    $this.dmFragCount[$i][$j] = -99
                                }

                                $stillticking = $true
                            }
                        }

                        $this.dmTotalCount[$i] = $this.GetFragSum($i)

                        if ($this.dmTotalCount[$i] -gt 99) {
                            $this.dmTotalCount[$i] = 99
                        }

                        if ($this.dmTotalCount[$i] -lt -99) {
                            $this.dmTotalCount[$i] = -99
                        }
                    }
                }

                if (-not $stillticking) {
                    $this.StartSound([Sfx]::BAREXP)
                    $this.dmState++
                }
                break
            }
            4 {
                if ($this.accelerateStage) {
                    $this.StartSound([Sfx]::SLOP)

                    if ($this.options.GameMode -eq [GameMode]::Commercial) {
                        $this.InitNoState()
                    } else {
                        $this.InitShowNextLoc()
                    }
                }
                break
            }
            default {
                if (($this.dmState -band 1) -ne 0) {
                    if (--$this.pauseCount -eq 0) {
                        $this.dmState++
                        $this.pauseCount = [GameConst]::TicRate
                    }
                }
                break
            }
        }
    }

    [void]UpdateShowNextLoc() {
        $this.UpdateAnimatedBack()

        if (--$this.count -eq 0 -or $this.accelerateStage) {
            $this.InitNoState()
        } else {
            $this.showYouAreHere = ($this.count -band 31) -lt 20
        }
    }

    [void]UpdateNoState() {
        $this.UpdateAnimatedBack()

        if (--$this.count -eq 0) {
            $this.completed = $true
        }
    }

    [void]UpdateAnimatedBack() {
        if ($this.options.GameMode -eq [GameMode]::Commercial) {
            return
        }

        if ($this.info.Episode -gt 2) {
            return
        }

        foreach ($animation in $this.animations) {
            $animation.Update($this.bgCount)
        }
    }

    [void]CheckForAccelerate() {
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $player = $this.options.Players[$i]
            if ($player.InGame) {
                if (($player.Cmd.Buttons -band [TicCmdButtons]::Attack) -ne 0) {
                    if (-not $player.AttackDown) {
                        $this.accelerateStage = $true
                    }
                    $player.AttackDown = $true
                } else {
                    $player.AttackDown = $false
                }

                if (($player.Cmd.Buttons -band [TicCmdButtons]::Use) -ne 0) {
                    if (-not $player.UseDown) {
                        $this.accelerateStage = $true
                    }
                    $player.UseDown = $true
                } else {
                    $player.UseDown = $false
                }
            }
        }
    }

    [int]GetFragSum([int]$playerNumber) {
        $frags = 0
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($this.options.Players[$i].InGame -and $i -ne $playerNumber) {
                $frags += $this.scores[$playerNumber].Frags[$i]
            }
        }
        $frags -= $this.scores[$playerNumber].Frags[$playerNumber]
        return $frags
    }

    [void]StartSound([Sfx]$sfx) {
        $this.options.Sound.StartSound($sfx)
    }

}