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

class Animation {
    [Intermission]$im
    [int]$number
    [AnimationType]$type
    [int]$period
    [int]$frameCount
    [int]$locationX
    [int]$locationY
    [int]$data
    [string[]]$patches
    [int]$patchNumber
    [int]$nextTic

    Animation([Intermission]$intermission, [AnimationInfo]$info, [int]$number) {
        $this.im = $intermission
        $this.number = $number
        $this.type = $info.Type
        $this.period = $info.Period
        $this.frameCount = $info.Count
        $this.locationX = $info.X
        $this.locationY = $info.Y
        $this.data = $info.Data

        $this.patches = New-Object string[] $this.frameCount
        for ($i = 0; $i -lt $this.frameCount; $i++) {
            if ($this.im.Info.Episode -ne 1 -or $this.number -ne 8) {
                $this.patches[$i] = "WIA" + $this.im.Info.Episode + $this.number.ToString("00") + $i.ToString("00")
            }
            else {
                $this.patches[$i] = "WIA104" + $i.ToString("00")
            }
        }
    }

    [void]Reset([int]$bgCount) {
        $this.patchNumber = -1
        if ($this.type -eq [AnimationType]::Always) {
            $this.nextTic = $bgCount + 1 + ($this.im.Random.Next() % $this.period)
        }
        elseif ($this.type -eq [AnimationType]::Random) {
            $this.nextTic = $bgCount + 1 + ($this.im.Random.Next() % $this.data)
        }
        elseif ($this.type -eq [AnimationType]::Level) {
            $this.nextTic = $bgCount + 1
        }
    }

    [void]Update([int]$bgCount) {
        if ($bgCount -eq $this.nextTic) {
            switch ($this.type) {
                ([AnimationType]::Always) {
                    if (++$this.patchNumber -ge $this.frameCount) {
                        $this.patchNumber = 0
                    }
                    $this.nextTic = $bgCount + $this.period
                    break
                }

                ([AnimationType]::Random) {
                    $this.patchNumber++
                    if ($this.patchNumber -eq $this.frameCount) {
                        $this.patchNumber = -1
                        $this.nextTic = $bgCount + ($this.im.Random.Next() % $this.data)
                    }
                    else {
                        $this.nextTic = $bgCount + $this.period
                    }
                    break
                }

                ([AnimationType]::Level) {
                    if (!($this.im.State -eq [IntermissionState]::StatCount -and $this.number -eq 7) -and $this.im.Info.NextLevel -eq $this.Data) {
                        $this.patchNumber++
                        if ($this.patchNumber -eq $this.frameCount) {
                            $this.patchNumber--
                        }
                        $this.nextTic = $bgCount + $this.period
                    }
                    break
                }
            }
        }
    }
}
