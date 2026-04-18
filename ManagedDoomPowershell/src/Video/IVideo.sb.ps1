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

class IVideo {
    [void] Render([Doom]$doom, [Fixed]$frameFrac) {
        throw [System.NotImplementedException]::new("Render method not implemented.")
    }

    [void] InitializeWipe() {
        throw [System.NotImplementedException]::new("InitializeWipe method not implemented.")
    }

    [bool] HasFocus() {
        throw [System.NotImplementedException]::new("HasFocus method not implemented.")
    }

    [int] get_MaxWindowSize() {
        return [ThreeDRenderer]::MaxScreenSize
    }

    [int] get_MaxGammaCorrectionLevel() {
        return 10
    }

    [int] WipeBandCount() {
        return 321
    }

    [int] WipeHeight() {
        return 200
    }

    [int] get_WindowSize() {
        return 0
    }

    [void] set_WindowSize([int] $value) {
    }

    [bool] get_DisplayMessage() {
        return $true
    }

    [void] set_DisplayMessage([bool] $value) {
    }

    [int] get_GammaCorrectionLevel() {
        return 0
    }

    [void] set_GammaCorrectionLevel([int] $value) {
    }
}
