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

# This requires a special dance.
# is it a powershell bug or not ? it's related to the dynamic .net compiler from some minor debugging and no idea how to resolve it without add-type with C# code.
# Powershell unless explicitly required it is, so this dance is what you get.

class MobjInfo {
    [int] $DoomEdNum
    [MobjState] $SpawnState
    [int] $SpawnHealth
    [MobjState] $SeeState
    [Sfx] $SeeSound
    [int] $ReactionTime
    [Sfx] $AttackSound
    [MobjState] $PainState
    [int] $PainChance
    [Sfx] $PainSound
    [MobjState] $MeleeState
    [MobjState] $MissileState
    [MobjState] $DeathState
    [MobjState] $XdeathState
    [Sfx] $DeathSound
    [int] $Speed
    [Fixed] $Radius
    [Fixed] $Height
    [int] $Mass
    [int] $Damage
    [Sfx] $ActiveSound
    [MobjFlags] $Flags
    [MobjState] $RaiseState

    MobjInfo() {}
    # why do this dance you ask.. do not ask I have no idea.
    # Doing a simple constructor gives:
    # ParentContainsErrorRecordException: An error occurred while creating the pipeline.
    # replacing all types to string,int and bool works, all up to speed works so it's not the types..
    MobjInfo([hashtable]$params) {
        $parameterKeysEnumerable = $params.Keys
        if ($null -ne $parameterKeysEnumerable) {
            $parameterKeysEnumerator = $parameterKeysEnumerable.GetEnumerator()
            for (; $parameterKeysEnumerator.MoveNext(); ) {
                $key = $parameterKeysEnumerator.Current
                if ($this.PSObject.Properties.Name -contains $key) {
                    if ($key -eq "Flags") {
                        $this.$key = [MobjFlags]$params[$key]  # explicit casting.
                    } else {
                        $this.$key = $params[$key]
                    }
                }

            }
        }
    }
}