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

class Sector {
    static [int]$dataSize = 26

    [int]$number
    [Fixed]$floorHeight
    [Fixed]$ceilingHeight
    [int]$floorFlat
    [int]$ceilingFlat
    [int]$lightLevel
    [SectorSpecial]$special
    [int]$tag
    [int]$soundTraversed
    [Mobj]$soundTarget
    [int[]]$blockBox
    [Mobj]$soundOrigin
    [int]$validCount
    [Mobj]$thingList
    [Thinker]$specialData
    [LineDef[]]$lines
    [Fixed]$oldFloorHeight
    [Fixed]$oldCeilingHeight
    
    Sector([int]$number, [Fixed]$floorHeight, [Fixed]$ceilingHeight, [int]$floorFlat, 
           [int]$ceilingFlat, [int]$lightLevel, [SectorSpecial]$special, [int]$tag) {
        $this.number = $number
        $this.floorHeight = $floorHeight
        $this.ceilingHeight = $ceilingHeight
        $this.floorFlat = $floorFlat
        $this.ceilingFlat = $ceilingFlat
        $this.lightLevel = $lightLevel
        $this.special = $special
        $this.tag = $tag

        $this.oldFloorHeight = $floorHeight
        $this.oldCeilingHeight = $ceilingHeight
    }

        static [Sector] FromData([byte[]]$data, [int]$offset, [int]$number, [IFlatLookup]$flats) {
        $mFloorHeight = [BitConverter]::ToInt16($data, $offset)
        $mCeilingHeight = [BitConverter]::ToInt16($data, $offset + 2)
        $floorFlatName = [DoomInterop]::ToString($data, $offset + 4, 8)
        $ceilingFlatName = [DoomInterop]::ToString($data, $offset + 12, 8)
        $mLightLevel = [BitConverter]::ToInt16($data, $offset + 20)
        $mSpecial = [BitConverter]::ToInt16($data, $offset + 22)
        $mTag = [BitConverter]::ToInt16($data, $offset + 24)
        return [Sector]::new(
            $number,
            [Fixed]::FromInt($mFloorHeight),
            [Fixed]::FromInt($mCeilingHeight),
            $flats.GetNumber($floorFlatName),
            $flats.GetNumber($ceilingFlatName),
            $mLightLevel,
            [SectorSpecial]$mSpecial,
            $mTag
        )
    }

    static [Sector[]] FromWad([Wad]$wad, [int]$lump, [IFlatLookup]$flats) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Sector]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Sector]::dataSize
        $sectors = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [Sector]::dataSize * $i
            $sectors += [Sector]::FromData($data, $offset, $i, $flats)
        }

        return $sectors
    }

    [void] UpdateFrameInterpolationInfo() {
        $this.oldFloorHeight = $this.floorHeight
        $this.oldCeilingHeight = $this.ceilingHeight
    }

    [Fixed] GetInterpolatedFloorHeight([Fixed]$frameFrac) {
        return $this.oldFloorHeight + $frameFrac * ($this.floorHeight - $this.oldFloorHeight)
    }

    [Fixed] GetInterpolatedCeilingHeight([Fixed]$frameFrac) {
        return $this.oldCeilingHeight + $frameFrac * ($this.ceilingHeight - $this.oldCeilingHeight)
    }

    [void] DisableFrameInterpolationForOneFrame() {
        $this.oldFloorHeight = $this.floorHeight
        $this.oldCeilingHeight = $this.ceilingHeight
    }

    [ThingEnumerator] GetEnumerator() {
        return [ThingEnumerator]::new($this)
    }


}

class ThingEnumerator {
    [Sector]$sector
    [Mobj]$thing
    [Mobj]$current

    ThingEnumerator([Sector]$sector) {
        $this.sector = $sector
        $this.thing = $sector.thingList
        $this.current = $null
    }

    [bool] MoveNext() {
        if ($null -ne $this.thing) {
            $this.current = $this.thing
            $this.thing = $this.thing.SectorNext
            return $true
        } else {
            $this.current = $null
            return $false
        }
    }

    [void] Reset() {
        $this.thing = $this.sector.thingList
        $this.current = $null
    }

    [void] Dispose() {
    }
}
