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

class Wad {
    [System.Collections.Generic.List[string]]$names
    [System.Collections.Generic.List[System.IO.Stream]]$streams
    [System.Collections.Generic.List[LumpInfo]]$lumpInfos
    [string]$gameVersion
    [string]$gameMode
    [string]$missionPack

    Wad([string[]]$fileNames) {
        try {
            [Console]::Write("Open WAD files: ")

            $this.names = [System.Collections.Generic.List[string]]::new()
            $this.streams = [System.Collections.Generic.List[System.IO.Stream]]::new()
            $this.lumpInfos = [System.Collections.Generic.List[LumpInfo]]::new()

            $wadFileNamesEnumerable = $fileNames
            if ($null -ne $wadFileNamesEnumerable) {
                $wadFileNamesEnumerator = $wadFileNamesEnumerable.GetEnumerator()
                for (; $wadFileNamesEnumerator.MoveNext(); ) {
                    $fileName = $wadFileNamesEnumerator.Current
                    $this.AddFile($fileName)

                }
            }

            $this.gameMode = $this.GetGameMode($this.names)
            $this.missionPack = $this.GetMissionPack($this.names)
            $this.gameVersion = $this.GetGameVersion($this.names)

            $displayFileNames = [System.Collections.Generic.List[string]]::new()
            for ($fileNameIndex = 0; $fileNameIndex -lt $fileNames.Count; $fileNameIndex++) {
                $displayFileNames.Add([System.IO.Path]::GetFileName($fileNames[$fileNameIndex]))
            }

            [Console]::WriteLine("OK ($($displayFileNames.ToArray() -join ', '))")
        } catch {
            [Console]::WriteLine("Failed")
            $this.Dispose()
            throw $_
        }
    }

    [void]AddFile([string]$fileName) {
        $this.names.Add([System.IO.Path]::GetFileNameWithoutExtension($fileName).ToLower())

        $stream = [System.IO.FileStream]::new($fileName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $this.streams.Add($stream)

        $data = New-Object byte[] 12
        if ($stream.Read($data, 0, $data.Length) -ne $data.Length) {
            throw "Failed to read the WAD file."
        }

        $identification = [System.Text.Encoding]::ASCII.GetString($data, 0, 4)
        $lumpCount = [BitConverter]::ToInt32($data, 4)
        $lumpInfoTableOffset = [BitConverter]::ToInt32($data, 8)
        if ($identification -ne "IWAD" -and $identification -ne "PWAD") {
            throw "The file is not a WAD file."
        }

        $data = New-Object byte[] ($lumpCount * 16)
        $stream.Seek($lumpInfoTableOffset, [System.IO.SeekOrigin]::Begin)
        if ($stream.Read($data, 0, $data.Length) -ne $data.Length) {
            throw "Failed to read the WAD file."
        }

        for ($i = 0; $i -lt $lumpCount; $i++) {
            $offset = $i * 16
            $lumpInfo = [LumpInfo]::new(
                [System.Text.Encoding]::ASCII.GetString($data, $offset + 8, 8).TrimEnd([char]0),
                $stream,
                [BitConverter]::ToInt32($data, $offset),
                [BitConverter]::ToInt32($data, $offset + 4)
            )
            $this.lumpInfos.Add($lumpInfo)
        }
    }

    [int]GetLumpNumber([string]$name) {
        for ($i = $this.lumpInfos.Count - 1; $i -ge 0; $i--) {
            if ($this.lumpInfos[$i].getName() -eq $name) {
                return $i
            }
        }
        return -1
    }

    [int]GetLumpSize([int]$number) {
        return $this.lumpInfos[$number].getSize()
    }

    [byte[]]ReadLump([int]$number) {
        $lumpInfo = $this.lumpInfos[$number]
        $data = New-Object byte[] $lumpInfo.getSize()

        $lumpInfo.getStream().Seek($lumpInfo.getPosition(), [System.IO.SeekOrigin]::Begin)
        $read = $lumpInfo.getStream().Read($data, 0, $lumpInfo.getSize())
        if ($read -ne $lumpInfo.getSize()) {
            throw "Failed to read the lump $number."
        }

        return $data
    }

    [byte[]]ReadLump([string]$name) {
        $lumpNumber = $this.GetLumpNumber($name)
        if ($lumpNumber -eq -1) {
            throw "The lump '$name' was not found."
        }
        return $this.ReadLump($lumpNumber)
    }

    [void]Dispose() {
        [Console]::WriteLine("Close WAD files.")
        $wadStreamsEnumerable = $this.streams
        if ($null -ne $wadStreamsEnumerable) {
            $wadStreamsEnumerator = $wadStreamsEnumerable.GetEnumerator()
            for (; $wadStreamsEnumerator.MoveNext(); ) {
                $stream = $wadStreamsEnumerator.Current
                $stream.Dispose()

            }
        }
        $this.streams.Clear()
    }

    [string]GetGameVersion([System.Collections.Generic.List[string]]$names) {
        $gameVersionNamesEnumerable = $names
        if ($null -ne $gameVersionNamesEnumerable) {
            $gameVersionNamesEnumerator = $gameVersionNamesEnumerable.GetEnumerator()
            for (; $gameVersionNamesEnumerator.MoveNext(); ) {
                $name = $gameVersionNamesEnumerator.Current
                switch ($name.ToLower()) {
                    "doom2"{ return "Version109" }
                    "freedoom2" { return "Version109" }
                    "doom" { return "Ultimate" }
                    "doom1" { return "Ultimate" }
                    "freedoom1" { return "Ultimate" }
                    "plutonia" { return "Final" }
                    "tnt" { return "Final" }
                }

            }
        }
        return "Version109"
    }

    [string]GetGameMode([System.Collections.Generic.List[string]]$names) {
        $gameModeNamesEnumerable = $names
        if ($null -ne $gameModeNamesEnumerable) {
            $gameModeNamesEnumerator = $gameModeNamesEnumerable.GetEnumerator()
            for (; $gameModeNamesEnumerator.MoveNext(); ) {
                $name = $gameModeNamesEnumerator.Current
                switch ($name.ToLower()) {
                    "doom2" { return "Commercial" }
                    "plutonia" { return "Commercial" }
                    "tnt" { return "Commercial" }
                    "freedoom2" { return "Commercial" }
                    "doom" { return "Retail" }
                    "freedoom1" { return "Retail" }
                    "doom1" { return "Shareware" }
                }

            }
        }
        return "Indetermined"
    }

    [string] GetMissionPack([System.Collections.Generic.List[string]]$names) {
        $missionPackNamesEnumerable = $names
        if ($null -ne $missionPackNamesEnumerable) {
            $missionPackNamesEnumerator = $missionPackNamesEnumerable.GetEnumerator()
            for (; $missionPackNamesEnumerator.MoveNext(); ) {
                $name = $missionPackNamesEnumerator.Current
                switch ($name.ToLower()) {
                    "plutonia" { return "Plutonia" }
                    "tnt" { return "Tnt" }
                }

            }
        }
        return "Doom2"
    }
}
