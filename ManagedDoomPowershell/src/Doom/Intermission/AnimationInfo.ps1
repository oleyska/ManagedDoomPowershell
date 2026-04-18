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

class AnimationInfo {
    [AnimationType]$type
    [int]$period
    [int]$count
    [int]$x
    [int]$y
    [int]$data

    # Constructor 1
    AnimationInfo([AnimationType]$type, [int]$period, [int]$count, [int]$x, [int]$y) {
        $this.type = $type
        $this.period = $period
        $this.count = $count
        $this.x = $x
        $this.y = $y
    }

    # Constructor 2
    AnimationInfo([AnimationType]$type, [int]$period, [int]$count, [int]$x, [int]$y, [int]$data) {
        $this.type = $type
        $this.period = $period
        $this.count = $count
        $this.x = $x
        $this.y = $y
        $this.data = $data
    }

    static [AnimationInfo[][]] $Episodes = @(
        # Episode 0
        [AnimationInfo[]]@(
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 224, 104),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 184, 160),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 112, 136),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 72, 112),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 88, 96),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 64, 48),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 192, 40),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 136, 16),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 80, 16),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 64, 24)
        ),
        
        # Episode 1
        [AnimationInfo[]]@(
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 1),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 2),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 3),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 4),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 5),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 6),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 7),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 3, 192, 144, 8),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 8)
        ),
        
        # Episode 2
        [AnimationInfo[]]@(
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 104, 168),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 40, 136),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 160, 96),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 104, 80),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 120, 32),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 4, 3, 40, 0)
        )
    )
}
