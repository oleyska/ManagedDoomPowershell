class DummyFlatLookup : IFlatLookup {
    [Flat[]]$flatList
    [System.Collections.Generic.Dictionary[string, Flat]]$nameToFlat
    [System.Collections.Generic.Dictionary[string, int]]$nameToNumber
    [int]$skyFlatNumber
    [Flat]$skyFlat

    DummyFlatLookup([Wad]$wad) {
        $firstFlat = $wad.GetLumpNumber("F_START") + 1
        $lastFlat = $wad.GetLumpNumber("F_END") - 1
        $count = $lastFlat - $firstFlat + 1

        $this.flatList = New-Object Flat[] $count
        $this.nameToFlat = New-Object 'System.Collections.Generic.Dictionary[string, Flat]'
        $this.nameToNumber = New-Object 'System.Collections.Generic.Dictionary[string, int]'

        for ($lump = $firstFlat; $lump -le $lastFlat; $lump++) {
            if ($wad.GetLumpSize($lump) -ne 4096) {
                continue
            }

            $number = $lump - $firstFlat
            $name = $wad.LumpInfos[$lump].Name
            $flat = if ($name -ne "F_SKY1") { [DummyData]::GetFlat() } else { [DummyData]::GetSkyFlat() }

            $this.flatList[$number] = $flat
            $this.nameToFlat[$name] = $flat
            $this.nameToNumber[$name] = $number
        }

        $this.skyFlatNumber = $this.nameToNumber["F_SKY1"]
        $this.skyFlat = $this.nameToFlat["F_SKY1"]
    }

    [int] GetNumber([string]$name) {
        if ($this.nameToNumber.ContainsKey($name)) {
            return $this.nameToNumber[$name]
        } else {
            return -1
        }
    }

    [System.Collections.IEnumerator] GetEnumerator() {
        return ($this.flatList).GetEnumerator()
    }

    [System.Collections.IEnumerator] IEnumerable_GetEnumerator() {
        return $this.flatList.GetEnumerator()
    }

}