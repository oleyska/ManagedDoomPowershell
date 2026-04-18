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

class World {
    [GameOptions]$Options;
    [DoomGame]$Game;
    [DoomRandom]$Random;

    [Map]$Map;

    [Thinkers]$Thinkers
    [Specials]$Specials
    [ThingAllocation]$ThingAllocation
    [ThingMovement]$ThingMovement
    [ThingInteraction]$ThingInteraction
    [MapCollision]$MapCollision
    [MapInteraction]$MapInteraction
    [PathTraversal]$PathTraversal
    [Hitscan]$Hitscan
    [VisibilityCheck]$VisibilityCheck
    [SectorAction]$SectorAction
    [PlayerBehavior]$PlayerBehavior
    [ItemPickup]$ItemPickup
    [WeaponBehavior]$WeaponBehavior
    [MonsterBehavior]$MonsterBehavior
    [LightingChange]$LightingChange
    [StatusBar]$StatusBar
    [AutoMap]$AutoMap
    [Cheat]$Cheat

    [int]$TotalKills
    [int]$TotalItems
    [int]$TotalSecrets

    [int]$LevelTime
    [bool]$DoneFirstTic
    [bool]$SecretExit
    [bool]$Completed

    [int]$ValidCount
    [int]$DisplayPlayerNumber
    [Player]$ConsolePlayer
    [Player]$DisplayPlayer

    [Mobj]$Dummy

    World([GameContent]$Resources, [GameOptions]$options, [DoomGame]$game) {
        $this.Options = $options
        $this.Game = $game
        $this.Random = $options.Random

        $this.Map = [Map]::new($Resources, $this)
        $this.Thinkers = [Thinkers]::new($this)
        $this.Specials = [Specials]::new($this)
        $this.ThingAllocation = [ThingAllocation]::new($this)
        $this.ThingMovement = [ThingMovement]::new($this)
        $this.ThingInteraction = [ThingInteraction]::new($this)
        $this.MapCollision = [MapCollision]::new($this)
        $this.MapInteraction = [MapInteraction]::new($this)
        $this.PathTraversal = [PathTraversal]::new($this)
        $this.Hitscan = [Hitscan]::new($this)
        $this.VisibilityCheck = [VisibilityCheck]::new($this)
        $this.SectorAction = [SectorAction]::new($this)
        $this.PlayerBehavior = [PlayerBehavior]::new($this)
        $this.ItemPickup = [ItemPickup]::new($this)
        $this.WeaponBehavior = [WeaponBehavior]::new($this)
        $this.MonsterBehavior = [MonsterBehavior]::new($this)
        $this.LightingChange = [LightingChange]::new($this)
        $this.StatusBar = [StatusBar]::new($this)
        $this.AutoMap = [AutoMap]::new($this)
        $this.Cheat = [Cheat]::new($this)

        $this.Options.IntermissionInfo.TotalFrags = 0
        $this.Options.IntermissionInfo.ParTime = 180

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.Options.Players[$i].KillCount = 0
            $this.Options.Players[$i].SecretCount = 0
            $this.Options.Players[$i].ItemCount = 0
        }

        $this.Options.Players[$this.Options.ConsolePlayer].ViewZ = [Fixed]::Epsilon
        $this.ConsolePlayer = $this.Options.Players[$this.Options.ConsolePlayer]

        $this.TotalKills = 0
        $this.TotalItems = 0
        $this.TotalSecrets = 0

        $this.LoadThings()

        if ($this.Options.Deathmatch -ne 0) {
            for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
                if ($this.Options.Players[$i].InGame) {
                    $this.Options.Players[$i].Mobj = $null
                    $this.ThingAllocation.DeathMatchSpawnPlayer($i)
                }
            }
        }

        $this.Specials.SpawnSpecials()

        $this.LevelTime = 0
        $this.DoneFirstTic = $false
        $this.SecretExit = $false
        $this.Completed = $false

        $this.ValidCount = 0
        $this.DisplayPlayerNumber = $this.Options.ConsolePlayer
        $this.DisplayPlayer = $this.Options.Players[$this.DisplayPlayerNumber]
        $this.Dummy = [Mobj]::new($this)

        $this.Options.Music.StartMusic([Map]::GetMapBgm($this.Options), $true)
    }

    [UpdateResult] Update() {
        $players = $this.Options.Players
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame) {
                $players[$i].UpdateFrameInterpolationInfo()
            }
        }
        $this.Thinkers.UpdateFrameInterpolationInfo()
        $worldSectorsEnumerable = $this.Map.Sectors
        if ($null -ne $worldSectorsEnumerable) {
            $worldSectorsEnumerator = $worldSectorsEnumerable.GetEnumerator()
            for (; $worldSectorsEnumerator.MoveNext(); ) {
                $sector = $worldSectorsEnumerator.Current
                $sector.UpdateFrameInterpolationInfo()

            }
        }
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame) {
                $this.PlayerBehavior.PlayerThink($players[$i])
            }
        }
        $this.Thinkers.Run()
        $this.Specials.Update()
        $this.ThingAllocation.RespawnSpecials()
        $this.StatusBar.Update()
        $this.AutoMap.Update()
        $this.LevelTime++

        if ($this.Completed) { return [UpdateResult]::Completed }
        if ($this.DoneFirstTic) { return [UpdateResult]::None }

        $this.DoneFirstTic = $true
        return [UpdateResult]::NeedWipe
    }

    [void] LoadThings() {
        $thingIndex = 0
        $mapThingsEnumerable = $this.Map.Things
        if ($null -ne $mapThingsEnumerable) {
            $mapThingsEnumerator = $mapThingsEnumerable.GetEnumerator()
            for (; $mapThingsEnumerator.MoveNext(); ) {
                $mt = $mapThingsEnumerator.Current
                $spawn = $true

                if ($this.Options.GameMode -ne [GameMode]::Commercial) {
                    switch ($mt.Type) {
                        68 { $spawn = $false }  # Arachnotron
                        64 { $spawn = $false }  # Archvile
                        88 { $spawn = $false }  # Boss Brain
                        89 { $spawn = $false }  # Boss Shooter
                        69 { $spawn = $false }  # Hell Knight
                        67 { $spawn = $false }  # Mancubus
                        71 { $spawn = $false }  # Pain Elemental
                        65 { $spawn = $false }  # Former Human Commando
                        66 { $spawn = $false }  # Revenant
                        84 { $spawn = $false }  # Wolf SS
                    }
                }

                if (-not $spawn) {
                    break
                }

                $this.ThingAllocation.SpawnMapThing($mt)
                $thingIndex++

            }
        }
    }

    [void] ExitLevel() {
        $this.SecretExit = $false
        $this.Completed = $true
    }

    [void] SecretExitLevel() {
        $this.SecretExit = $true
        $this.Completed = $true
    }
    [void] StartSound([Mobj]$mobj, [Sfx]$sfx, [SfxType]$type) {
        $this.Options.Sound.StartSound($mobj, $sfx, $type)
    }

    [void] StartSound([Mobj]$mobj, [Sfx]$sfx, [SfxType]$type, [int]$volume) {
        $this.Options.Sound.StartSound($mobj, $sfx, $type, $volume)
    }

    [void] StopSound([Mobj]$mobj) {
        $this.Options.Sound.StopSound($mobj)
    }


    [bool] DoEvent([DoomEvent]$e) {
        if (-not $this.Options.NetGame -and -not $this.Options.DemoPlayback) {
            $this.Cheat.DoEvent($e)
        }

        if ($this.AutoMap.Visible) {
            if ($this.AutoMap.DoEvent($e)) {
                return $true
            }
        }

        if ($e.Key -eq [DoomKey]::Tab -and $e.Type -eq [EventType]::KeyDown) {
            if ($this.AutoMap.Visible) {
                $this.AutoMap.Close()
            } else {
                $this.AutoMap.Open()
            }
            return $true
        }

        if ($e.Key -eq [DoomKey]::F12 -and $e.Type -eq [EventType]::KeyDown) {
            if ($this.Options.DemoPlayback -or $this.Options.Deathmatch -eq 0) {
                $this.ChangeDisplayPlayer()
            }
            return $true
        }

        return $false
    }

    [void] ChangeDisplayPlayer() {
        $this.DisplayPlayerNumber++
        if ($this.DisplayPlayerNumber -ge [Player]::MaxPlayerCount -or -not $this.Options.Players[$this.DisplayPlayerNumber].InGame) {
            $this.DisplayPlayerNumber = 0
        }
        $this.DisplayPlayer = $this.Options.Players[$this.DisplayPlayerNumber]
    }

    [int] GetNewValidCount() {
        $this.ValidCount++
        return $this.ValidCount
    }

    [Player] get_ConsolePlayer() {
        return $this.ConsolePlayer
    }

    [Player] get_DisplayPlayer() {
        return $this.DisplayPlayer
    }

    [Mobj] SubstNullMobj([Mobj]$mobj) {
        if ($null -eq $mobj) {
            $this.Dummy.X = [Fixed]::Zero
            $this.Dummy.Y = [Fixed]::Zero
            $this.Dummy.Z = [Fixed]::Zero
            $this.Dummy.Flags = 0
            return $this.Dummy
        }
        return $mobj
    }
}

