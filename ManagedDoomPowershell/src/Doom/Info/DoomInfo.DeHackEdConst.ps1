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


class DeHackEdConst {
    [int] $InitialHealth = 100
    [int] $InitialBullets = 50
    [int] $MaxHealth = 200
    [int] $MaxArmor = 200
    [int] $GreenArmorClass = 1
    [int] $BlueArmorClass = 2
    [int] $MaxSoulsphere = 200
    [int] $SoulsphereHealth = 100
    [int] $MegasphereHealth = 200
    [int] $GodModeHealth = 100
    [int] $IdfaArmor = 200
    [int] $IdfaArmorClass = 2
    [int] $IdkfaArmor = 200
    [int] $IdkfaArmorClass = 2
    [int] $BfgCellsPerShot = 40
    [bool] $MonstersInfight = $false
}