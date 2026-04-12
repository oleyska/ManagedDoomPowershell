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

            foreach ($fileName in $fileNames) {
                $this.AddFile($fileName)
            }

            $this.gameMode = $this.GetGameMode($this.names)
            $this.missionPack = $this.GetMissionPack($this.names)
            $this.gameVersion = $this.GetGameVersion($this.names)

            [Console]::WriteLine("OK ($(($fileNames | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '))")
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
        foreach ($stream in $this.streams) {
            $stream.Dispose()
        }
        $this.streams.Clear()
    }

    [string]GetGameVersion([System.Collections.Generic.List[string]]$names) {
        foreach ($name in $names) {
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
        return "Version109"
    }

    [string]GetGameMode([System.Collections.Generic.List[string]]$names) {
        foreach ($name in $names) {
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
        return "Indetermined"
    }

    [string] GetMissionPack([System.Collections.Generic.List[string]]$names) {
        foreach ($name in $names) {
            switch ($name.ToLower()) {
                "plutonia" { return "Plutonia" }
                "tnt" { return "Tnt" }
            }
        }
        return "Doom2"
    }
}