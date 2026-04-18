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

class OpeningSequence {
    [GameContent] $content
    [GameOptions] $options

    [OpeningSequenceState] $state

    [int] $currentStage
    [int] $nextStage

    [int] $count
    [int] $timer

    [TicCmd[]] $cmds
    [Demo] $demo
    [DoomGame] $game

    [bool] $needsReset
    [int] $debugLastHealth
    [int] $debugLastArmor
    [int] $debugLastDamageCount

    OpeningSequence([GameContent] $content, [GameOptions] $options) {
        $this.content = $content
        $this.options = $options

        $this.cmds = New-Object 'TicCmd[]' ([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.cmds[$i] = [TicCmd]::new()
        }

        $this.currentStage = 0
        $this.nextStage = 0
        $this.needsReset = $false
        $this.debugLastHealth = -1
        $this.debugLastArmor = -1
        $this.debugLastDamageCount = -1

        $this.StartTitleScreen()
    }

    [void] Reset() {
        $this.currentStage = 0
        $this.nextStage = 0

        $this.demo = $null
        $this.game = $null

        $this.needsReset = $true
        $this.debugLastHealth = -1
        $this.debugLastArmor = -1
        $this.debugLastDamageCount = -1

        $this.StartTitleScreen()
    }

    hidden [void] DumpDemoState() {
        if ($null -eq $this.game -or $this.game.State -ne [GameState]::Level -or $null -eq $this.game.World) {
            return
        }

        $player = $this.game.World.ConsolePlayer
        if ($null -eq $player -or $null -eq $player.Mobj) {
            return
        }

        $tic = $this.game.World.LevelTime
        $alwaysTrace = ($tic -ge 170 -and $tic -le 220) -or
            ($tic -ge 318 -and $tic -le 342) -or
            ($tic -ge 410 -and $tic -le 446) -or
            ($tic -ge 613 -and $tic -le 650)
        if (-not $alwaysTrace -and
            $player.Health -eq $this.debugLastHealth -and
            $player.ArmorPoints -eq $this.debugLastArmor -and
            $player.DamageCount -eq $this.debugLastDamageCount) {
            return
        }

        $attackerType = if ($null -eq $player.Attacker) { -1 } else { [int]$player.Attacker.Type }
        $cmd = $this.cmds[0]
        $label = if ($alwaysTrace) { 'OpeningDemoSync' } else { 'OpeningDemoState' }
        $mobjHash = [DoomDebug]::GetMobjHash($this.game.World)
        $sectorHash = [DoomDebug]::GetSectorHash($this.game.World)
        $rngIndex = $this.game.World.Random.Index
        $line = ("{0} time={1} health={2} armor={3} armorType={4} damageCount={5} viewZ={6} viewHeight={7} deltaView={8} bob={9} floorZ={10} ceilZ={11} mom={12},{13},{14} pos={15},{16},{17} angle={18} attacker={19} cmd={20},{21},{22},{23} rngIndex={24} mobjHash={25} sectorHash={26}" -f
            $label,
            $tic,
            $player.Health,
            $player.ArmorPoints,
            $player.ArmorType,
            $player.DamageCount,
            $player.ViewZ.Data,
            $player.ViewHeight.Data,
            $player.DeltaViewHeight.Data,
            $player.Bob.Data,
            $player.Mobj.FloorZ.Data,
            $player.Mobj.CeilingZ.Data,
            $player.Mobj.MomX.Data,
            $player.Mobj.MomY.Data,
            $player.Mobj.MomZ.Data,
            $player.Mobj.X.Data,
            $player.Mobj.Y.Data,
            $player.Mobj.Z.Data,
            [uint32]$player.Mobj.Angle.Data,
            $attackerType,
            $cmd.ForwardMove,
            $cmd.SideMove,
            $cmd.AngleTurn,
            [int]$cmd.Buttons,
            $rngIndex,
            $mobjHash,
            $sectorHash)
        [Console]::WriteLine($line)
        $this.DumpShadowState()

        $this.debugLastHealth = $player.Health
        $this.debugLastArmor = $player.ArmorPoints
        $this.debugLastDamageCount = $player.DamageCount
    }

    hidden [void] DumpShadowState() {
        if ($null -eq $this.game -or $null -eq $this.game.World) {
            return
        }

        $world = $this.game.World
        $tic = $world.LevelTime
        $dumpShadows = $tic -ge 191 -and $tic -le 193
        $dumpNearby = $dumpShadows -or
            ($tic -ge 210 -and $tic -le 227) -or
            ($tic -ge 318 -and $tic -le 342) -or
            ($tic -ge 410 -and $tic -le 446)
        $dumpTroops = $tic -ge 410 -and $tic -le 430
        if (-not $dumpNearby) {
            return
        }

        $blockMap = $world.Map.BlockMap
        $player = $world.ConsolePlayer
        $playerX = $player.Mobj.X
        $playerY = $player.Mobj.Y
        $shadowTypeCount = 0
        $shadowFlagCount = 0
        $totalMobjCount = 0
        $nearbyEntries = [System.Collections.Generic.List[object]]::new()
        $nearestDist = [Fixed]::MaxValue
        $nearestLine = $null
        $current = $world.Thinkers.Cap.Next
        while ($current -ne $world.Thinkers.Cap) {
            $typeProp = $current.PSObject.Properties['Type']
            if ($null -ne $typeProp) {
                $typeValue = [int]$typeProp.Value
                $x = $current.PSObject.Properties['X'].Value
                $y = $current.PSObject.Properties['Y'].Value
                $z = $current.PSObject.Properties['Z'].Value
                $flags = [int]$current.PSObject.Properties['Flags'].Value
                $blockPrev = $current.PSObject.Properties['BlockPrev'].Value
                $blockNext = $current.PSObject.Properties['BlockNext'].Value
                $index = $blockMap.GetIndex($x, $y)
                $prevType = if ($null -eq $blockPrev) { -1 } else { [int]$blockPrev.Type }
                $nextType = if ($null -eq $blockNext) { -1 } else { [int]$blockNext.Type }
                $mobjState = $current.PSObject.Properties['State'].Value
                $stateNumber = if ($null -eq $mobjState) { -1 } else { [int]$mobjState.Number }
                $tics = $current.PSObject.Properties['Tics'].Value
                $moveCountProp = $current.PSObject.Properties['MoveCount']
                $moveCount = if ($null -eq $moveCountProp) { 0 } else { [int]$moveCountProp.Value }
                $moveDirProp = $current.PSObject.Properties['MoveDir']
                $moveDir = if ($null -eq $moveDirProp) { -1 } else { [int]$moveDirProp.Value }
                $reactionTimeProp = $current.PSObject.Properties['ReactionTime']
                $reactionTime = if ($null -eq $reactionTimeProp) { 0 } else { [int]$reactionTimeProp.Value }
                $thresholdProp = $current.PSObject.Properties['Threshold']
                $threshold = if ($null -eq $thresholdProp) { 0 } else { [int]$thresholdProp.Value }
                $targetProp = $current.PSObject.Properties['Target']
                $target = if ($null -eq $targetProp) { $null } else { $targetProp.Value }
                $targetType = if ($null -eq $target) { -1 } else { [int]$target.Type }
                $srcX = if ($null -eq $target) { 0 } else { $target.X.Data }
                $srcY = if ($null -eq $target) { 0 } else { $target.Y.Data }
                $srcZ = if ($null -eq $target) { 0 } else { $target.Z.Data }
                $dist = [Geometry]::AproxDistance($x - $playerX, $y - $playerY)

                $totalMobjCount++
                if (($flags -band [int][MobjFlags]::Shadow) -ne 0) {
                    $shadowFlagCount++
                }
                if ($typeValue -ne [int][MobjType]::Player) {
                    $null = $nearbyEntries.Add([pscustomobject]@{
                        Type = $typeValue
                        State = $stateNumber
                        Tics = [int]$tics
                        MoveCount = $moveCount
                        MoveDir = $moveDir
                        ReactionTime = $reactionTime
                        Threshold = $threshold
                        TargetType = $targetType
                        SrcX = $srcX
                        SrcY = $srcY
                        SrcZ = $srcZ
                        X = $x.Data
                        Y = $y.Data
                        Z = $z.Data
                        Flags = $flags
                        BlockIndex = $index
                        PrevType = $prevType
                        NextType = $nextType
                        Dist = $dist.Data
                    })
                }

                if ($dumpShadows -and $typeValue -eq [int][MobjType]::Shadows) {
                    if ($dist.Data -lt $nearestDist.Data) {
                        $nearestDist = $dist
                        $nearestLine = ("ShadowNearest time={0} pos={1},{2},{3} dist={4} blockIndex={5} prevType={6} nextType={7} flags={8}" -f $tic, $x.Data, $y.Data, $z.Data, $dist.Data, $index, $prevType, $nextType, $flags)
                    }
                    if ($shadowTypeCount -lt 8) {
                        [Console]::WriteLine(("ShadowDump time={0} idx={1} pos={2},{3},{4} flags={5} blockIndex={6} prevType={7} nextType={8} dist={9}" -f $tic, $shadowTypeCount, $x.Data, $y.Data, $z.Data, $flags, $index, $prevType, $nextType, $dist.Data))
                    }
                    $shadowTypeCount++
                }
            }
            $current = $current.Next
        }

        if ($dumpShadows) {
            [Console]::WriteLine(("ShadowCount time={0} typeCount={1} flagCount={2} totalMobjs={3}" -f $tic, $shadowTypeCount, $shadowFlagCount, $totalMobjCount))
        }
        $nearestMobjs = $nearbyEntries | Sort-Object Dist, Type, X, Y, Z | Select-Object -First 8
        if ($null -eq $nearestMobjs -or $nearestMobjs.Count -eq 0) {
            [Console]::WriteLine(("MobjDump time={0} none" -f $tic))
        } else {
            $nearbyIndex = 0
            $nearestMobjEntriesEnumerable = $nearestMobjs
            if ($null -ne $nearestMobjEntriesEnumerable) {
                $nearestMobjEntriesEnumerator = $nearestMobjEntriesEnumerable.GetEnumerator()
                for (; $nearestMobjEntriesEnumerator.MoveNext(); ) {
                    $entry = $nearestMobjEntriesEnumerator.Current
                    [Console]::WriteLine(("MobjDump time={0} idx={1} type={2} state={3} tics={4} moveCount={5} moveDir={6} reaction={7} threshold={8} targetType={9} pos={10},{11},{12} flags={13} blockIndex={14} prevType={15} nextType={16} dist={17}" -f
                        $tic,
                        $nearbyIndex,
                        $entry.Type,
                        $entry.State,
                        $entry.Tics,
                        $entry.MoveCount,
                        $entry.MoveDir,
                        $entry.ReactionTime,
                        $entry.Threshold,
                        $entry.TargetType,
                        $entry.X,
                        $entry.Y,
                        $entry.Z,
                        $entry.Flags,
                        $entry.BlockIndex,
                        $entry.PrevType,
                        $entry.NextType,
                        $entry.Dist))
                    $nearbyIndex++

                }
            }
        }
        if ($dumpTroops) {
            $troopEntries = $nearbyEntries |
                Where-Object { $_.Type -eq [int][MobjType]::Troop -or $_.Type -eq [int][MobjType]::Troopshot } |
                Sort-Object Dist, Type, X, Y, Z |
                Select-Object -First 12

            if ($null -eq $troopEntries -or $troopEntries.Count -eq 0) {
                [Console]::WriteLine(("TroopDump time={0} none" -f $tic))
            } else {
                $troopIndex = 0
                $troopEntriesEnumerable = $troopEntries
                if ($null -ne $troopEntriesEnumerable) {
                    $troopEntriesEnumerator = $troopEntriesEnumerable.GetEnumerator()
                    for (; $troopEntriesEnumerator.MoveNext(); ) {
                        $entry = $troopEntriesEnumerator.Current
                        [Console]::WriteLine(("TroopDump time={0} idx={1} type={2} state={3} tics={4} moveCount={5} moveDir={6} reaction={7} threshold={8} targetType={9} pos={10},{11},{12} flags={13} dist={14} src={15},{16},{17}" -f
                            $tic,
                            $troopIndex,
                            $entry.Type,
                            $entry.State,
                            $entry.Tics,
                            $entry.MoveCount,
                            $entry.MoveDir,
                            $entry.ReactionTime,
                            $entry.Threshold,
                            $entry.TargetType,
                            $entry.X,
                            $entry.Y,
                            $entry.Z,
                            $entry.Flags,
                            $entry.Dist,
                            $entry.SrcX,
                            $entry.SrcY,
                            $entry.SrcZ))
                        $troopIndex++

                    }
                }
            }
        }
        if ($dumpShadows) {
            if ($null -ne $nearestLine) {
                [Console]::WriteLine($nearestLine)
            } else {
                [Console]::WriteLine(("ShadowDump time={0} none" -f $tic))
            }
        }
    }

    [UpdateResult] Update() {
        [UpdateResult]$updateResult = [UpdateResult]::None

        if ($this.nextStage -ne $this.currentStage) {
            switch ($this.nextStage) {
                0 { $this.StartTitleScreen() }
                1 { $this.StartDemo("DEMO1") }
                2 { $this.StartCreditScreen() }
                3 { $this.StartDemo("DEMO2") }
                4 { $this.StartTitleScreen() }
                5 { $this.StartDemo("DEMO3") }
                6 { $this.StartCreditScreen() }
                7 { $this.StartDemo("DEMO4") }
            }

            $this.currentStage = $this.nextStage
            [UpdateResult]$updateResult = [UpdateResult]::NeedWipe
        }

        switch ($this.currentStage) {
            0 {
                $this.count++
                if ($this.count -eq $this.timer) {
                    $this.nextStage = 1
                }
            }
            1 {
                $hasCmd = $this.demo.ReadCmd($this.cmds)
                if (-not $hasCmd) {
                    $this.nextStage = 2
                } else {
                    $this.game.Update($this.cmds)
                }
            }
            2 {
                $this.count++
                if ($this.count -eq $this.timer) {
                    $this.nextStage = 3
                }
            }
            3 {
                $hasCmd = $this.demo.ReadCmd($this.cmds)
                if (-not $hasCmd) {
                    $this.nextStage = 4
                } else {
                    $this.game.Update($this.cmds)
                }
            }
            4 {
                $this.count++
                if ($this.count -eq $this.timer) {
                    $this.nextStage = 5
                }
            }
            5 {
                $hasCmd = $this.demo.ReadCmd($this.cmds)
                if (-not $hasCmd) {
                    if ($this.content.Wad.GetLumpNumber("DEMO4") -eq -1) {
                        $this.nextStage = 0
                    } else {
                        $this.nextStage = 6
                    }
                } else {
                    $this.game.Update($this.cmds)
                }
            }
            6 {
                $this.count++
                if ($this.count -eq $this.timer) {
                    $this.nextStage = 7
                }
            }
            7 {
                $hasCmd = $this.demo.ReadCmd($this.cmds)
                if (-not $hasCmd) {
                    $this.nextStage = 0
                } else {
                    $this.game.Update($this.cmds)
                }
            }
        }

        if ($this.state -eq [OpeningSequenceState]::Title -and $this.count -eq 1) {
            if ($this.options.GameMode -eq [GameMode]::Commercial) {
                $this.options.Music.StartMusic([Bgm]::DM2TTL, $false)
            } else {
                $this.options.Music.StartMusic([Bgm]::INTRO, $false)
            }
        }

        if ($this.needsReset) {
            $this.needsReset = $false
            return [UpdateResult]::NeedWipe
        } else {
            return [UpdateResult]$updateResult
        }
    }

    [void] StartTitleScreen() {
        $this.state = [OpeningSequenceState]::Title

        $this.count = 0
        if ($this.options.GameMode -eq [GameMode]::Commercial) {
            $this.timer = 35 * 11
        } else {
            $this.timer = 170
        }
    }

    [void] StartCreditScreen() {
        $this.state = [OpeningSequenceState]::Credit

        $this.count = 0
        $this.timer = 200
    }

    [void] StartDemo([string] $lump) {
        $this.state = [OpeningSequenceState]::Demo

        $this.demo = [Demo]::new($this.content.Wad.ReadLump($lump))
        $this.demo.Options.GameVersion = $this.options.GameVersion
        $this.demo.Options.GameMode = $this.options.GameMode
        $this.demo.Options.MissionPack = $this.options.MissionPack
        $this.demo.Options.Video = $this.options.Video
        $this.demo.Options.Sound = $this.options.Sound
        $this.demo.Options.Music = $this.options.Music

        $this.game = [DoomGame]::new($this.content, $this.demo.Options)
        $this.game.DeferedInitNew()
    }

    [OpeningSequenceState] get_State() {
        return $this.state
    }

    [DoomGame] get_DemoGame() {
        return $this.game
    }

    [int] get_Count() {
        return $this.count
    }

    [int] get_Timer() {
        return $this.timer
    }
}









