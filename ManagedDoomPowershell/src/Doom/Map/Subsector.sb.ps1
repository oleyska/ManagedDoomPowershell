class Subsector {
    static [int]$dataSize = 4

    [Sector]$sector
    [int]$segCount
    [int]$firstSeg

    Subsector([Sector]$sector, [int]$segCount, [int]$firstSeg) {
        $this.sector = $sector
        $this.segCount = $segCount
        $this.firstSeg = $firstSeg
    }

    static [Subsector] FromData([byte[]]$data, [int]$offset, [Seg[]]$segs) {
        $mSegCount = [BitConverter]::ToInt16($data, $offset)
        $firstSegNumber = [BitConverter]::ToInt16($data, $offset + 2)

        return [Subsector]::new(
            $segs[$firstSegNumber].SideDef.Sector,
            $mSegCount,
            $firstSegNumber
        )
    }

    static [Subsector[]] FromWad([Wad]$wad, [int]$lump, [Seg[]]$segs) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [Subsector]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [Subsector]::dataSize
        $subsectors = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [Subsector]::dataSize * $i
            $subsectors += [Subsector]::FromData($data, $offset, $segs)
        }

        return $subsectors
    }

}