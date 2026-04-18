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

class PlayerActions {
    PlayerActions() {}

    [void] Light0([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Light0($player)
    }

    [void] WeaponReady([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.WeaponReady($player, $psp)
    }

    [void] Lower([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Lower($player, $psp)
    }

    [void] Raise([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Raise($player, $psp)
    }

    [void] Punch([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Punch($player)
    }

    [void] ReFire([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.ReFire($player)
    }

    [void] FirePistol([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FirePistol($player)
    }

    [void] Light1([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Light1($player)
    }

    [void] FireShotgun([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FireShotgun($player)
    }

    [void] Light2([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Light2($player)
    }

    [void] FireShotgun2([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FireShotgun2($player)
    }

    [void] CheckReload([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.CheckReload($player)
    }

    [void] OpenShotgun2([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.OpenShotgun2($player)
    }

    [void] LoadShotgun2([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.LoadShotgun2($player)
    }

    [void] CloseShotgun2([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.CloseShotgun2($player)
    }

    [void] FireCGun([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FireCGun($player, $psp)
    }

    [void] GunFlash([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.GunFlash($player)
    }

    [void] FireMissile([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FireMissile($player)
    }

    [void] Saw([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.Saw($player)
    }

    [void] FirePlasma([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FirePlasma($player)
    }

    [void] BFGsound([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.A_BFGsound($player)
    }

    [void] FireBFG([object]$world, [object]$player, [object]$psp) {
        $world.WeaponBehavior.FireBFG($player)
    }
}