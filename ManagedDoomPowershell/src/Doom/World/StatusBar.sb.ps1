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

class StatusBar {
    [World] $World
    static [Face] $Face = [Face]::new()
    [int] $OldHealth
    [bool[]] $OldWeaponsOwned
    [int] $FaceCount
    [int] $FaceIndex
    [int] $RandomNumber
    [int] $Priority
    [int] $LastAttackDown
    [int] $LastPainOffset

    [DoomRandom] $Random

    StatusBar([World] $world) {
        $this.World = $world

        $this.OldHealth = -1
        $this.OldWeaponsOwned = New-Object 'bool[]' ([DoomInfo]::WeaponInfos.Length)
        if ($null -ne $this.World.ConsolePlayer.WeaponOwned) {
            [Array]::Copy($this.World.ConsolePlayer.WeaponOwned, $this.OldWeaponsOwned, [DoomInfo]::WeaponInfos.Length)
        }

        $this.FaceCount = 0
        $this.FaceIndex = 0
        $this.RandomNumber = 0
        $this.Priority = 0
        $this.LastAttackDown = -1
        $this.LastPainOffset = 0

        $this.Random = [DoomRandom]::new()
    }

    [void] Reset() {
        $this.OldHealth = -1
        $this.OldWeaponsOwned = New-Object 'bool[]' ([DoomInfo]::WeaponInfos.Length)
        if ($null -ne $this.World.ConsolePlayer.WeaponOwned) {
            [Array]::Copy($this.World.ConsolePlayer.WeaponOwned, $this.OldWeaponsOwned, [DoomInfo]::WeaponInfos.Length)
        }
        $this.FaceCount = 0
        $this.FaceIndex = 0
        $this.RandomNumber = 0
        $this.Priority = 0
        $this.LastAttackDown = -1
        $this.LastPainOffset = 0
    }

    [void] Update() {
        $this.RandomNumber = $this.Random.Next()
        $this.UpdateFace()
    }

    [bool] UpdateOwnedWeaponSnapshot([Player] $player) {
        if ($null -eq $player -or $null -eq $player.WeaponOwned) {
            return $false
        }

        if ($null -eq $this.OldWeaponsOwned -or $this.OldWeaponsOwned.Length -ne $player.WeaponOwned.Length) {
            $this.OldWeaponsOwned = New-Object 'bool[]' ($player.WeaponOwned.Length)
        }

        $gainedWeapon = $false
        for ($i = 0; $i -lt $player.WeaponOwned.Length; $i++) {
            $wasOwned = [bool]$this.OldWeaponsOwned[$i]
            $isOwned = [bool]$player.WeaponOwned[$i]
            if ($wasOwned -ne $isOwned) {
                if (-not $wasOwned -and $isOwned) {
                    $gainedWeapon = $true
                }
                $this.OldWeaponsOwned[$i] = $isOwned
            }
        }

        return $gainedWeapon
    }

    [void] UpdateFace() {
        $player = $this.World.ConsolePlayer
        $gainedWeapon = $this.UpdateOwnedWeaponSnapshot($player)

        if ($this.Priority -lt 10) {
            if ($player.Health -eq 0) {
                $this.Priority = 9
                $this.FaceIndex = [StatusBar]::Face::DeadIndex
                $this.FaceCount = 1
            }
        }

        if ($this.Priority -lt 9) {
            if ($player.BonusCount -ne 0) {
                if ($gainedWeapon) {
                    $this.Priority = 8
                    $this.FaceCount = [StatusBar]::Face::EvilGrinDuration
                    $this.FaceIndex = $this.CalcPainOffset() + [StatusBar]::Face::EvilGrinOffset
                }
            }
        }

        if ($this.Priority -lt 8) {
            if ($player.DamageCount -ne 0 -and $null -ne $player.Attacker -and $player.Attacker -ne $player.Mobj) {
                $this.Priority = 7

                if ($player.Health - $this.OldHealth -gt [StatusBar]::Face::MuchPain) {
                    $this.FaceCount = [StatusBar]::Face::TurnDuration
                    $this.FaceIndex = $this.CalcPainOffset() + [StatusBar]::Face::OuchOffset
                } else {
                    $attackerAngle = [Geometry]::PointToAngle($player.Mobj.X, $player.Mobj.Y, $player.Attacker.X, $player.Attacker.Y)

                    if ($attackerAngle.Data -gt $player.Mobj.Angle.Data) {
                        $diff = $attackerAngle - $player.Mobj.Angle
                        $right = $diff.Data -gt [Angle]::Ang180.Data
                    } else {
                        $diff = $player.Mobj.Angle - $attackerAngle
                        $right = $diff.Data -le [Angle]::Ang180.Data
                    }

                    $this.FaceCount = [StatusBar]::Face::TurnDuration
                    $this.FaceIndex = $this.CalcPainOffset()

                    if ($diff.Data -lt [Angle]::Ang45.Data) {
                        $this.FaceIndex += [StatusBar]::Face::RampageOffset
                    } elseif ($right) {
                        $this.FaceIndex += [StatusBar]::Face::TurnOffset
                    } else {
                        $this.FaceIndex += [StatusBar]::Face::TurnOffset + 1
                    }
                }
            }
        }

        if ($this.Priority -lt 7) {
            if ($player.DamageCount -ne 0) {
                if ($player.Health - $this.OldHealth -gt [StatusBar]::Face::MuchPain) {
                    $this.Priority = 7
                    $this.FaceCount = [StatusBar]::Face::TurnDuration
                    $this.FaceIndex = $this.CalcPainOffset() + [StatusBar]::Face::OuchOffset
                } else {
                    $this.Priority = 6
                    $this.FaceCount = [StatusBar]::Face::TurnDuration
                    $this.FaceIndex = $this.CalcPainOffset() + [StatusBar]::Face::RampageOffset
                }
            }
        }

        if ($this.Priority -lt 6) {
            if ($player.AttackDown) {
                if ($this.LastAttackDown -eq -1) {
                    $this.LastAttackDown = [StatusBar]::Face::RampageDelay
                } elseif (--$this.LastAttackDown -eq 0) {
                    $this.Priority = 5
                    $this.FaceIndex = $this.CalcPainOffset() + [StatusBar]::Face::RampageOffset
                    $this.FaceCount = 1
                    $this.LastAttackDown = 1
                }
            } else {
                $this.LastAttackDown = -1
            }
        }

        if ($this.Priority -lt 5) {
            if (($player.Cheats -band [CheatFlags]::GodMode) -ne 0 -or $player.Powers[[PowerType]::Invulnerability] -ne 0) {
                $this.Priority = 4
                $this.FaceIndex = [StatusBar]::Face::GodIndex
                $this.FaceCount = 1
            }
        }

        if ($this.FaceCount -eq 0) {
            $this.FaceIndex = $this.CalcPainOffset() + ($this.RandomNumber % 3)
            $this.FaceCount = [StatusBar]::Face::StraightFaceDuration
            $this.Priority = 0
        }

        $this.FaceCount--
    }

    [int] CalcPainOffset() {
        $player = $this.World.Options.Players[$this.World.Options.ConsolePlayer]
        $health = if ($player.Health -gt 100) { 100 } else { $player.Health }

        if ($health -ne $this.OldHealth) {
            $painSlot = [int][Math]::Truncate(((100 - $health) * [StatusBar]::Face::PainFaceCount) / 101) #force integer math and not float.
            $this.LastPainOffset = [StatusBar]::Face::Stride * $painSlot
            $this.OldHealth = $health
        }

        return $this.LastPainOffset
    }
}
class Face {
    static [int] $PainFaceCount = 5
    static [int] $StraightFaceCount = 3
    static [int] $TurnFaceCount = 2
    static [int] $SpecialFaceCount = 3

    static [int] $Stride = [face]::StraightFaceCount + [face]::TurnFaceCount + [face]::SpecialFaceCount
    static [int] $ExtraFaceCount = 2
    static [int] $FaceCount = [face]::Stride * [face]::PainFaceCount + [face]::ExtraFaceCount

    static [int] $TurnOffset = [face]::StraightFaceCount
    static [int] $OuchOffset = [face]::TurnOffset + [face]::TurnFaceCount
    static [int] $EvilGrinOffset = [face]::OuchOffset + 1
    static [int] $RampageOffset = [face]::EvilGrinOffset + 1
    static [int] $GodIndex = [face]::PainFaceCount * [face]::Stride
    static [int] $DeadIndex = [face]::GodIndex + 1

    static [int] $EvilGrinDuration = (2 * [GameConst]::TicRate)
    static [int] $StraightFaceDuration = ([GameConst]::TicRate / 2)
    static [int] $TurnDuration = (1 * [GameConst]::TicRate)
    static [int] $OuchDuration = (1 * [GameConst]::TicRate)
    static [int] $RampageDelay = (2 * [GameConst]::TicRate)

    static [int] $MuchPain = 20
}



