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

class Fixed {
    static [int] $FracBits = 16
    static [int] $FracUnit = 1 -shl 16

    static [Fixed] $Zero = [Fixed]::new(0)
    static [Fixed] $One = [Fixed]::new([Fixed]::FracUnit)

    static [Fixed] $MaxValue = [Fixed]::new([int]::MaxValue)
    static [Fixed] $MinValue = [Fixed]::new([int]::MinValue)

    static [Fixed] $Epsilon = [Fixed]::new(1)
    static [Fixed] $OnePlusEpsilon = [Fixed]::new([Fixed]::FracUnit + 1)
    static [Fixed] $OneMinusEpsilon = [Fixed]::new([Fixed]::FracUnit - 1)

    [int] $Data

    Fixed([int] $data) {
        $this.Data = $data
    }

    static [Fixed] FromInt([int] $value) {
        return [Fixed]::new($value -shl [Fixed]::FracBits)
    }

    static [Fixed] FromFloat([float] $value) {
        return [Fixed]::new([int][math]::Truncate([Fixed]::FracUnit * $value))
    }

    static [Fixed] FromDouble([double] $value) {
        return [Fixed]::new([int][math]::Truncate([Fixed]::FracUnit * $value))
    }

    [float] ToFloat() {
        return $this.Data / [Fixed]::FracUnit
    }

    [double] ToDouble() {
        return $this.Data / [Fixed]::FracUnit
    }

    static [int] ToInt32Unchecked([long] $value) {
        $masked = $value -band 0xFFFFFFFFL
        if ($masked -ge 0x80000000L) {
            return [int]($masked - 0x100000000L)
        }

        return [int]$masked
    }

    static [Fixed] Abs([Fixed] $a) {
        if ($a.Data -lt 0) {
            return [Fixed]::new([Fixed]::ToInt32Unchecked(-[long]$a.Data))
        }
        return $a
    }

    static [Fixed] op_UnaryPlus([Fixed] $a) { return $a }
    static [Fixed] op_UnaryNegation([Fixed] $a) { return [Fixed]::new([Fixed]::ToInt32Unchecked(-[long]$a.Data)) }

    static [Fixed] op_Addition([Fixed] $a, [Fixed] $b) { return [Fixed]::new([Fixed]::ToInt32Unchecked(([long]$a.Data) + ([long]$b.Data))) }
    static [Fixed] op_Subtraction([Fixed] $a, [Fixed] $b) { return [Fixed]::new([Fixed]::ToInt32Unchecked(([long]$a.Data) - ([long]$b.Data))) }
    
    static [Fixed] op_Multiply([Fixed] $a, [Fixed] $b) {
        return [Fixed]::new([Fixed]::ToInt32Unchecked((([long]$a.Data * [long]$b.Data) -shr [Fixed]::FracBits)))
    }

    static [Fixed] op_Multiply([int] $a, [Fixed] $b) { return [Fixed]::new([Fixed]::ToInt32Unchecked(([long]$a) * ([long]$b.Data))) }
    static [Fixed] op_Multiply([Fixed] $a, [int] $b) { return [Fixed]::new([Fixed]::ToInt32Unchecked(([long]$a.Data) * ([long]$b))) }

    static [Fixed] op_Division([Fixed] $a, [Fixed] $b) {
        if (([Fixed]::CIntAbs($a.Data) -shr 14) -ge [Fixed]::CIntAbs($b.Data)) {
            return [Fixed]::new(($a.Data -bxor $b.Data) -lt 0 ? [int]::MinValue : [int]::MaxValue)
        }
        return [Fixed]::FixedDiv2($a, $b)
    }

    static [int] CIntAbs([int] $n) {
        return ($n -lt 0) ? -$n : $n
    }

    static [Fixed] FixedDiv2([Fixed] $a, [Fixed] $b) {
        $c = ([double]$a.Data) / ([double]$b.Data) * [Fixed]::FracUnit
        if ($c -ge 2147483648.0 -or $c -lt -2147483648.0) {
            throw [DivideByZeroException]::new()
        }
        return [Fixed]::new([int][math]::Truncate($c))
    }

    static [Fixed] op_Division([int] $a, [Fixed] $b) { return [Fixed]::FromInt($a) / $b }
    static [Fixed] op_Division([Fixed] $a, [int] $b) { return [Fixed]::new([int][math]::Truncate(([double]$a.Data) / ([double]$b))) }

    static [Fixed] op_LeftShift([Fixed] $a, [int] $b) { return [Fixed]::new([Fixed]::ToInt32Unchecked(([long]$a.Data) -shl $b)) }
    static [Fixed] op_RightShift([Fixed] $a, [int] $b) { return [Fixed]::new($a.Data -shr $b) }

    static [bool] op_Equality([Fixed] $a, [Fixed] $b) { return $a.Data -eq $b.Data }
    static [bool] op_Inequality([Fixed] $a, [Fixed] $b) { return $a.Data -ne $b.Data }
    static [bool] op_LessThan([Fixed] $a, [Fixed] $b) { return $a.Data -lt $b.Data }
    static [bool] op_GreaterThan([Fixed] $a, [Fixed] $b) { return $a.Data -gt $b.Data }
    static [bool] op_LessThanOrEqual([Fixed] $a, [Fixed] $b) { return $a.Data -le $b.Data }
    static [bool] op_GreaterThanOrEqual([Fixed] $a, [Fixed] $b) { return $a.Data -ge $b.Data }

    static [Fixed] Min([Fixed] $a, [Fixed] $b) { return ($a.Data -lt $b.Data) ? $a : $b }
    static [Fixed] Max([Fixed] $a, [Fixed] $b) { return ($a.Data -gt $b.Data) ? $a : $b }

    [int] ToIntFloor() { return $this.Data -shr [Fixed]::FracBits }
    [int] ToIntCeiling() { return ($this.Data + [Fixed]::FracUnit - 1) -shr [Fixed]::FracBits }

    [string] ToString() { return ([double]$this.Data / [Fixed]::FracUnit).ToString() }
}
