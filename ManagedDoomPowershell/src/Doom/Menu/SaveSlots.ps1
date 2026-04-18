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

class SaveSlots {
    [int]$slotCount = 6
    [int]$descriptionSize = 24


    [string[]]$slots


    [void] ReadSlots() {
        $this.slots = New-Object string[] $this.slotCount
        $directory = [ConfigUtilities]::GetExeDirectory()
        $buffer = New-Object byte[] $this.descriptionSize

        for ($i = 0; $i -lt $this.slots.Length; $i++) {
            $path = [System.IO.Path]::Combine($directory, "doomsav$i.dsg")
            if (Test-Path $path) {
                $reader = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $reader.Read($buffer, 0, $buffer.Length)
                $this.slots[$i] = [DoomInterop]::ToString($buffer, 0, $buffer.Length)
                $reader.Close()
            }
        }
    }

    [string] Get_Item([int]$number) {
        if ($null -eq $this.slots) {
            $this.ReadSlots()
        }
        return $this.slots[$number]
    }

    [void] Set_Item([int]$number, [string]$value) {
        if ($null -eq $this.slots) {
            $this.ReadSlots()
        }
        $this.slots[$number] = $value
    }

    [int] Count() {
         return $this.slots.Length 
    }
}
