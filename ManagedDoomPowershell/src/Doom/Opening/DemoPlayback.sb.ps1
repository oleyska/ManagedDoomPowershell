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

class DemoPlayback {
    static [int] $DebugStartFrame = 340
    static [int] $DebugEndFrame = 380

    [Demo] $demo
    [TicCmd[]] $cmds
    [DoomGame] $game

    [System.Diagnostics.Stopwatch] $stopwatch
    [int] $frameCount

    DemoPlayback([CommandLineArgs] $args, [GameContent] $content, [GameOptions] $options, [string] $demoName) {
        if (Test-Path $demoName) {
            $this.demo = [Demo]::new($demoName)
        }
        elseif (Test-Path ($demoName + ".lmp")) {
            $this.demo = [Demo]::new($demoName + ".lmp")
        }
        else {
            $lumpName = $demoName.ToUpper()
            if ($content.Wad.GetLumpNumber($lumpName) -eq -1) {
                throw [Exception]::new("Demo '$demoName' was not found!")
            }
            $this.demo = [Demo]::new($content.Wad.ReadLump($lumpName))
        }

        $this.demo.Options.GameVersion = $options.GameVersion
        $this.demo.Options.GameMode = $options.GameMode
        $this.demo.Options.MissionPack = $options.MissionPack
        $this.demo.Options.Video = $options.Video
        $this.demo.Options.Sound = $options.Sound
        $this.demo.Options.Music = $options.Music

        if ($args.solonet.Present) {
            $this.demo.Options.NetGame = $true
        }

        $this.cmds = New-Object 'TicCmd[]' ([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.cmds[$i] = [TicCmd]::new()
        }

        $this.game = [DoomGame]::new($content, $this.demo.Options)
        $this.game.DeferedInitNew()

        $this.stopwatch = [System.Diagnostics.Stopwatch]::new()
    }

    hidden [void] DumpDemoSync() {
        if ($this.frameCount -lt [DemoPlayback]::DebugStartFrame -or $this.frameCount -gt [DemoPlayback]::DebugEndFrame) {
            return
        }

        if ($null -eq $this.game -or $this.game.State -ne [GameState]::Level -or $null -eq $this.game.World) {
            return
        }

        $world = $this.game.World
        $player = $world.ConsolePlayer
        $mobj = if ($null -ne $player) { $player.Mobj } else { $null }
        $sector = if ($null -ne $mobj -and $null -ne $mobj.Subsector) { $mobj.Subsector.Sector } else { $null }
        $cmd = $this.cmds[$this.demo.Options.ConsolePlayer]

        $playerX = if ($null -ne $mobj) { $mobj.X.Data } else { 0 }
        $playerY = if ($null -ne $mobj) { $mobj.Y.Data } else { 0 }
        $playerZ = if ($null -ne $mobj) { $mobj.Z.Data } else { 0 }
        $playerAngle = if ($null -ne $mobj) { [uint32]$mobj.Angle.Data } else { 0 }
        $sectorNumber = if ($null -ne $sector) { $sector.Number } else { -1 }
        $sectorSpecial = if ($null -ne $sector) { [int]$sector.Special } else { -1 }
        $health = if ($null -ne $player) { $player.Health } else { 0 }
        $armor = if ($null -ne $player) { $player.ArmorPoints } else { 0 }
        $viewZ = if ($null -ne $player) { $player.ViewZ.Data } else { 0 }
        $weapon = if ($null -ne $player) { [int]$player.ReadyWeapon } else { -1 }
        $randomIndex = if ($null -ne $world.Random) { $world.Random.Index } else { -1 }
        $mobjHash = [DoomDebug]::GetMobjHash($world)
        $sectorHash = [DoomDebug]::GetSectorHash($world)

        [Console]::WriteLine(
            ("DemoSync frame={0} gameTic={1} levelTime={2} rng={3} cmd={4},{5},{6},{7} pos={8},{9},{10} viewZ={11} angle={12} health={13} armor={14} weapon={15} sector={16} special={17} mhash={18} shash={19}" -f
                $this.frameCount,
                $this.game.GameTic,
                $world.LevelTime,
                $randomIndex,
                $cmd.ForwardMove,
                $cmd.SideMove,
                $cmd.AngleTurn,
                $cmd.Buttons,
                $playerX,
                $playerY,
                $playerZ,
                $viewZ,
                $playerAngle,
                $health,
                $armor,
                $weapon,
                $sectorNumber,
                $sectorSpecial,
                $mobjHash,
                $sectorHash))
    }

    [UpdateResult] Update() {
        if (-not $this.stopwatch.IsRunning) {
            $this.stopwatch.Start()
        }

        if (-not $this.demo.ReadCmd($this.cmds)) {
            $this.stopwatch.Stop()
            return [UpdateResult]::Completed
        }
        else {
            $this.frameCount++
            $result = $this.game.Update($this.cmds)
            $this.DumpDemoSync()
            return $result
        }
    }

    [void] DoEvent([DoomEvent] $e) {
        $this.game.DoEvent($e)
    }


    [double] Fps() {
         return $this.frameCount / $this.stopwatch.Elapsed.TotalSeconds 
    }

    [DoomGame] get_Game() {
        return $this.game
    }
}
