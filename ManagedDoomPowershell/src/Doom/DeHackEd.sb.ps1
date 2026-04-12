class DeHackEd {
    static [System.Tuple[ScriptBlock, ScriptBlock][]] $sourcePointerTable

    static [void] Initialize($args, [Wad] $wad) {
        $mArgs = [CommandLineArgs]::new($args)
        if ($mArgs.deh.Present) {
            [DeHackEd]::ReadFiles($mArgs.deh.Value)
        }

        if (-not $mArgs.nodeh.Present) {
            [DeHackEd]::ReadDeHackEdLump($wad)
        }
    }

    static [void] ReadFiles([string[]] $fileNames) {
        $lastFileName = $null
        try {
            # Ensure static members are initialized
            [DoomInfo]::Strings.PRESSKEY.GetHashCode() | Out-Null
            [Console]::Write("Load DeHackEd patches: ")

            foreach ($fileName in $fileNames) {
                $lastFileName = $fileName
                [DeHackEd]::ProcessLines((Get-Content $fileName))
            }

            [Console]::WriteLine("OK (" + ($fileNames | ForEach-Object { [System.IO.Path]::GetFileName($_) } -join ", ") + ")")
        }
        catch {
            [Console]::WriteLine("Failed")
            throw "Failed to apply DeHackEd patch: $lastFileName `n$_"
        }
    }

    static [void] ReadDeHackEdLump([Wad] $wad) {
        $lump = $wad.GetLumpNumber("DEHACKED")

        if ($lump -ne -1) {
            # Ensure static members are initialized
            [DoomInfo]::Strings.PRESSKEY.GetHashCode() | Out-Null

            try {
                [Console]::Write("Load DeHackEd patch from WAD: ")
                [DeHackEd]::ProcessLines([DeHackEd]::ReadLines($wad.ReadLump($lump)))
                [Console]::WriteLine("OK")
            }
            catch {
                [Console]::WriteLine("Failed")
                throw "Failed to apply DeHackEd patch! `n$_"
            }
        }
    }

    static [string[]] ReadLines([byte[]] $data) {
        $stream = [System.IO.MemoryStream]::new($data)
        $reader = [System.IO.StreamReader]::new($stream)
        $lines = @()
        
        while ($null -ne ($line = $reader.ReadLine())) {
            $lines += $line
        }
        return $lines
    }

    static [void] ProcessLines([string[]] $lines) {
        if ($null -eq [DeHackEd]::sourcePointerTable) {
            [DeHackEd]::sourcePointerTable = New-Object 'System.Tuple[ScriptBlock, ScriptBlock][]' ([DoomInfo]::States.all.Length)

            for ($i = 0; $i -lt [DeHackEd]::sourcePointerTable.Length; $i++) {
                $playerAction = [DoomInfo]::States.all[$i].PlayerAction
                $mobjAction = [DoomInfo]::States.all[$i].MobjAction
                [DeHackEd]::sourcePointerTable[$i] = [System.Tuple]::Create($playerAction, $mobjAction)
            }
        }

        $lineNumber = 0
        $data = @()
        $lastBlock = [Block]::None
        $lastBlockLine = 0

        foreach ($line in $lines) {
            $lineNumber++

            if ($line -match "^#") { continue }

            $split = $line -split ' '
            $blockType = [DeHackEd]::GetBlockType($split)

            if ($blockType -eq [Block]::None) {
                $data += $line
            } else {
                [DeHackEd]::ProcessBlock($lastBlock, $data, $lastBlockLine)
                $data = @($line)
                $lastBlock = $blockType
                $lastBlockLine = $lineNumber
            }
        }

        [DeHackEd]::ProcessBlock($lastBlock, $data, $lastBlockLine)
    }

    static [void] ProcessBlock([Block] $type, [string[]] $data, [int] $lineNumber) {
        try {
            switch ($type) {
                ([Block]::Thing) { [DeHackEd]::ProcessThingBlock($data) }
                ([Block]::Frame) { [DeHackEd]::ProcessFrameBlock($data) }
                ([Block]::Pointer) { [DeHackEd]::ProcessPointerBlock($data) }
                ([Block]::Sound) { [DeHackEd]::ProcessSoundBlock($data) }
                ([Block]::Ammo) { [DeHackEd]::ProcessAmmoBlock($data) }
                ([Block]::Weapon) { [DeHackEd]::ProcessWeaponBlock($data) }
                ([Block]::Cheat) { [DeHackEd]::ProcessCheatBlock($data) }
                ([Block]::Misc) { [DeHackEd]::ProcessMiscBlock($data) }
                ([Block]::Text) { [DeHackEd]::ProcessTextBlock($data) }
                ([Block]::Sprite) { [DeHackEd]::ProcessSpriteBlock($data) }
                ([Block]::BexStrings) { [DeHackEd]::ProcessBexStringsBlock($data) }
                ([Block]::BexPars) { [DeHackEd]::ProcessBexParsBlock($data) }
            }
        }
        catch {
            throw "Failed to process block: $type (line $lineNumber) `n$_"
        }
    }

    static [Block] GetBlockType([string[]] $split) {
        if ([dehacked]::IsThingBlockStart($split)) {
            return [Block]::Thing
        } elseif ([dehacked]::IsFrameBlockStart($split)) {
            return [Block]::Frame
        } elseif ([dehacked]::IsPointerBlockStart($split)) {
            return [Block]::Pointer
        } elseif ([dehacked]::IsSoundBlockStart($split)) {
            return [Block]::Sound
        } elseif ([dehacked]::IsAmmoBlockStart($split)) {
            return [Block]::Ammo
        } elseif ([dehacked]::IsWeaponBlockStart($split)) {
            return [Block]::Weapon
        } elseif ([dehacked]::IsCheatBlockStart($split)) {
            return [Block]::Cheat
        } elseif ([dehacked]::IsMiscBlockStart($split)) {
            return [Block]::Misc
        } elseif ([dehacked]::IsTextBlockStart($split)) {
            return [Block]::Text
        } elseif ([dehacked]::IsSpriteBlockStart($split)) {
            return [Block]::Sprite
        } elseif ([dehacked]::IsBexStringsBlockStart($split)) {
            return [Block]::BexStrings
        } elseif ([dehacked]::IsBexParsBlockStart($split)) {
            return [Block]::BexPars
        } else {
            return [Block]::None
        }
    }
    static [bool] IsThingBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Thing") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        return $true
    }
    static [bool] IsNumber([string] $value) {
        foreach ($ch in $value.ToCharArray()) {
            if ($ch -lt '0' -or $ch -gt '9') {
                return $false
            }
        }
        return $true
    }
    static [hashtable] GetKeyValuePairs([System.Collections.Generic.List[string]] $data) {
        $dic = @{}
    
        foreach ($line in $data) {
            $split = $line -split '='
            if ($split.Length -eq 2) {
                $dic[$split[0].Trim()] = $split[1].Trim()
            }
        }
    
        return $dic
    }
    static [bool] IsPointerBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Pointer") {
            return $false
        }
    
        return $true
    }
    static [bool] IsSoundBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Sound") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        return $true
    }
    
    static [bool] IsAmmoBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Ammo") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        return $true
    }
    static [bool] IsWeaponBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Weapon") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        return $true
    }
    
    static [bool] IsCheatBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Cheat") {
            return $false
        }
    
        if ($split[1] -ne "0") {
            return $false
        }
    
        return $true
    }
    
    static [bool] IsMiscBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Misc") {
            return $false
        }
    
        if ($split[1] -ne "0") {
            return $false
        }
    
        return $true
    }
    
    static [bool] IsTextBlockStart([string[]] $split) {
        if ($split.Length -lt 3) {
            return $false
        }
    
        if ($split[0] -ne "Text") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[2])) {
            return $false
        }
    
        return $true
    }
    
    static [bool] IsSpriteBlockStart([string[]] $split) {
        if ($split.Length -lt 2) {
            return $false
        }
    
        if ($split[0] -ne "Sprite") {
            return $false
        }
    
        if (-not [dehacked]::IsNumber($split[1])) {
            return $false
        }
    
        return $true
    }
    static [bool] IsBexStringsBlockStart([string[]] $split) {
        if ($split[0] -eq "[STRINGS]") {
            return $true
        } else {
            return $false
        }
    }
    
    static [bool] IsBexParsBlockStart([string[]] $split) {
        if ($split[0] -eq "[PARS]") {
            return $true
        } else {
            return $false
        }
    }
    
    static [int] GetInt([hashtable] $dic, [string] $key, [int] $defaultValue) {
        if ($dic.ContainsKey($key)) {
            $value = $dic[$key]
            if ($value -match "^\d+$") {
                return [int]$value
            }
        }
    
        return $defaultValue
    }
    

    
}

enum Block {
    None
    Thing
    Frame
    Pointer
    Sound
    Ammo
    Weapon
    Cheat
    Misc
    Text
    Sprite
    BexStrings
    BexPars
}
