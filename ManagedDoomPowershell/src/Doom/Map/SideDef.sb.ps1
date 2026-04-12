class SideDef {
    # Static field for data size
    static [int]$dataSize = 30

    # Fields to store SideDef information
    [Fixed]$textureOffset
    [Fixed]$rowOffset
    [int]$topTexture
    [int]$bottomTexture
    [int]$middleTexture
    [Sector]$sector

    # Constructor to initialize SideDef object
    SideDef([Fixed]$textureOffset, [Fixed]$rowOffset, [int]$topTexture, [int]$bottomTexture, [int]$middleTexture, [Sector]$sector) {
        $this.textureOffset = $textureOffset
        $this.rowOffset = $rowOffset
        $this.topTexture = $topTexture
        $this.bottomTexture = $bottomTexture
        $this.middleTexture = $middleTexture
        $this.sector = $sector
    }

    # Static method to create SideDef from data
    static [SideDef] FromData([byte[]]$data, [int]$offset, [ITextureLookup]$textures, [Sector[]]$sectors) {
        $mTextureOffset = [BitConverter]::ToInt16($data, $offset)
        $mRowOffset = [BitConverter]::ToInt16($data, $offset + 2)
        $topTextureName = [DoomInterop]::ToString($data, $offset + 4, 8)
        $bottomTextureName = [DoomInterop]::ToString($data, $offset + 12, 8)
        $middleTextureName = [DoomInterop]::ToString($data, $offset + 20, 8)
        $sectorNum = [BitConverter]::ToInt16($data, $offset + 28)

        return [SideDef]::new(
            [Fixed]::FromInt($mTextureOffset),
            [Fixed]::FromInt($mRowOffset),
            $textures.GetNumber($topTextureName),
            $textures.GetNumber($bottomTextureName),
            $textures.GetNumber($middleTextureName),
            $(if ($sectorNum -ne -1) { $sectors[$sectorNum] } else { $null })
        )
    }

    # Static method to create SideDef array from Wad
    static [SideDef[]] FromWad([Wad]$wad, [int]$lump, [ITextureLookup]$textures, [Sector[]]$sectors) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [SideDef]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [SideDef]::dataSize
        $sides = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [SideDef]::dataSize * $i
            $sides += [SideDef]::FromData($data, $offset, $textures, $sectors)
        }

        return $sides
    }

}