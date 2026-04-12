class Seg {
    # Static field for data size
    static [int]$dataSize = 12

    # Fields to store Seg information
    [Vertex]$vertex1
    [Vertex]$vertex2
    [Fixed]$offset
    [Angle]$angle
    [SideDef]$sideDef
    [LineDef]$lineDef
    [Sector]$frontSector
    [Sector]$backSector

    # Constructor to initialize Seg object
    Seg([Vertex]$vertex1, [Vertex]$vertex2, [Fixed]$offset, [Angle]$angle, [SideDef]$sideDef, [LineDef]$lineDef, [Sector]$frontSector, [Sector]$backSector) {
        $this.vertex1 = $vertex1
        $this.vertex2 = $vertex2
        $this.offset = $offset
        $this.angle = $angle
        $this.sideDef = $sideDef
        $this.lineDef = $lineDef
        $this.frontSector = $frontSector
        $this.backSector = $backSector
    }

    # Static method to create Seg from data
    static [Seg] FromData([byte[]]$data, [int]$offset, [Vertex[]]$vertices, [LineDef[]]$lines) {
        $vertex1Number = [BitConverter]::ToInt16($data, $offset)
        $vertex2Number = [BitConverter]::ToInt16($data, $offset + 2)
        $mAngle = [BitConverter]::ToInt16($data, $offset + 4)
        $lineNumber = [BitConverter]::ToInt16($data, $offset + 6)
        $side = [BitConverter]::ToInt16($data, $offset + 8)
        $segOffset = [BitConverter]::ToInt16($data, $offset + 10)

        $mLineDef = $lines[$lineNumber]
        $frontSide = if ($side -eq 0) { $mLineDef.FrontSide } else { $mLineDef.BackSide }
        $backSide = if ($side -eq 0) { $mLineDef.BackSide } else { $mLineDef.FrontSide }

        return [Seg]::new(
            $vertices[$vertex1Number],
            $vertices[$vertex2Number],
            [Fixed]::FromInt($segOffset),
            [Angle]::new(([uint32]($mAngle -band 0xFFFF)) -shl 16),
            $frontSide,
            $mLineDef,
            $frontSide.Sector,
            $(if (($mLineDef.Flags -band [LineFlags]::TwoSided) -ne 0) { $backSide.Sector } else { $null })
        )
    }

    # Static method to create Seg array from Wad
    static [Seg[]] FromWad([Wad]$wad, [int]$lump, [Vertex[]]$vertices, [LineDef[]]$lines) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Seg]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Seg]::dataSize
        $segs = @()

        for ($i = 0; $i -lt $count; $i++) {
            $mOffset = [Seg]::dataSize * $i
            $segs += [Seg]::FromData($data, $mOffset, $vertices, $lines)
        }

        return $segs
    }
}
