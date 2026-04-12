class Reject {
    [byte[]]$data
    [int]$sectorCount

    Reject([byte[]]$data, [int]$sectorCount) {
        # If the reject table is too small, expand it to avoid crash.
        # https://doomwiki.org/wiki/Reject#Reject_Overflow
        $expectedLength = [math]::Ceiling($sectorCount * $sectorCount / 8.0)
        if ($data.Length -lt $expectedLength) {
            [Array]::Resize([ref]$data, $expectedLength)
        }

        $this.data = $data
        $this.sectorCount = $sectorCount
    }

    # Static method to create a Reject object from Wad
    [Reject] static FromWad([Wad]$wad, [int]$lump, [Sector[]]$sectors) {
        # Static method: No need for $this
        return [Reject]::new($wad.ReadLump($lump), $sectors.Length)
    }

    # Instance method to check the reject table
    [bool] Check([Sector]$sector1, [Sector]$sector2) {
        $s1 = $sector1.Number
        $s2 = $sector2.Number

        $p = $s1 * $this.sectorCount + $s2
        $byteIndex = [math]::Floor($p / 8)
        $bitIndex = 1 -shl ($p % 8)

        return (($this.data[$byteIndex] -band $bitIndex) -ne 0)
    }
}