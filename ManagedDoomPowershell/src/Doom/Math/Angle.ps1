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

class Angle {
    static [Angle] $Ang0
    static [Angle] $Ang45
    static [Angle] $Ang90
    static [Angle] $Ang180
    static [Angle] $Ang270

    [uint32] $Data

    Angle([uint32] $inputData) {
        $this.Data = $inputData
    }

    Angle([int] $inputData) {
        $this.Data = [BitConverter]::ToUInt32([BitConverter]::GetBytes($inputData), 0)
    }
    static Angle() {
    
        try {
            [Angle]::Ang0 = [Angle]::new([uint32] 0x00000000)
            [Angle]::Ang45 = [Angle]::new([uint32] 0x20000000)
            [Angle]::Ang90 = [Angle]::new([uint32] 0x40000000)
            # Convert negative values correctly for UInt32
            [Angle]::Ang180 = [Angle]::new([BitConverter]::ToUInt32([BitConverter]::GetBytes(0x80000000), 0))
            [Angle]::Ang270 = [Angle]::new([BitConverter]::ToUInt32([BitConverter]::GetBytes(0xC0000000), 0))

        } catch {
            [Console]::WriteLine("Error initializing static Angle fields: $_")
            throw $_
        }
    }

    static [Angle] FromRadian([double] $radian) {
        $calculatedData = [uint32]([math]::Round(0x100000000 * ($radian / (2 * [math]::PI))))
        return [Angle]::new($calculatedData)
    }

    static [Angle] FromDegree([double] $degree) {
        $calculatedData = [uint32]([math]::Round(0x100000000 * ($degree / 360)))
        return [Angle]::new($calculatedData)
    }

    [double] ToRadian() {
        return 2 * [math]::PI * ($this.Data / 0x100000000)
    }

    [double] ToDegree() {
        return 360 * ($this.Data / 0x100000000)
    }

    static [Angle] Abs([Angle] $angle) {
        $angleData = [BitConverter]::ToInt32([BitConverter]::GetBytes($angle.Data), 0)
        if ($angleData -lt 0) {
            return -$angle
        }
        return $angle
    }

    static [Angle] op_UnaryPlus([Angle] $a) { return $a }
    static [Angle] op_UnaryNegation([Angle] $a) {
        $wrapped = (0x100000000ul - [uint64]$a.Data) -band 0xFFFFFFFFul
        return [Angle]::new([uint32]$wrapped)
    }

    static [Angle] op_Addition([Angle] $a, [Angle] $b) {
        $wrapped = ([uint64]$a.Data + [uint64]$b.Data) -band 0xFFFFFFFFul
        return [Angle]::new([uint32]$wrapped)
    }

    static [Angle] op_Subtraction([Angle] $a, [Angle] $b) {
        $wrapped = ([uint64]$a.Data + 0x100000000ul - [uint64]$b.Data) -band 0xFFFFFFFFul
        return [Angle]::new([uint32]$wrapped)
    }

    static [Angle] op_Multiply([uint32] $a, [Angle] $b) {
        return [Angle]::new([uint32]($a * $b.Data))
    }

    static [Angle] op_Multiply([Angle] $a, [uint32] $b) {
        return [Angle]::new([uint32]($a.Data * $b))
    }

    static [Angle] op_Division([Angle] $a, [uint32] $b) {
        return [Angle]::new([uint32]($a.Data / $b))
    }

    static [bool] op_Equality([Angle] $a, [Angle] $b) { return $a.Data -eq $b.Data }
    static [bool] op_Inequality([Angle] $a, [Angle] $b) { return $a.Data -ne $b.Data }
    static [bool] op_LessThan([Angle] $a, [Angle] $b) { return $a.Data -lt $b.Data }
    static [bool] op_GreaterThan([Angle] $a, [Angle] $b) { return $a.Data -gt $b.Data }
    static [bool] op_LessThanOrEqual([Angle] $a, [Angle] $b) { return $a.Data -le $b.Data }
    static [bool] op_GreaterThanOrEqual([Angle] $a, [Angle] $b) { return $a.Data -ge $b.Data }

    [string] ToString() { return $this.ToDegree().ToString() }
}