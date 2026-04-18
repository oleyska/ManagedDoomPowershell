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

class IntermissionInfo {
    # Episode number (0-2).
    [int]$episode

    # If true, splash the secret level.
    [bool]$didSecret

    # Previous and next levels, origin 0.
    [int]$lastLevel
    [int]$nextLevel

    [int]$maxKillCount
    [int]$maxItemCount
    [int]$maxSecretCount
    [int]$totalFrags


    # The par time.
    [int]$parTime

    [PlayerScores[]]$players

    # Constructor initializes players array
    IntermissionInfo() {
        $this.players = [PlayerScores[]]::new([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.players[$i] = [PlayerScores]::new()
        }
    }


    [int] MaxKillCount() { return [math]::Max($this.maxKillCount, 1) }
    [int] MaxItemCount() { return [math]::Max($this.maxItemCount, 1) }
    [int] MaxSecretCount() { return [math]::Max($this.maxSecretCount, 1) }
    [int] TotalFrags() { return [math]::Max($this.totalFrags, 1) }

}
