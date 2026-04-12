class ColorMap {
    static [int]$Inverse = 32
    [byte[][]]$Data

    ColorMap([wad]$wad) {
        try {
            [Console]::Write("Load color map: ")

            $raw = $wad.ReadLump("COLORMAP")
            $num = $raw.Length / 256
            $this.Data = New-Object 'byte[][]' $num

            for ($i = 0; $i -lt $num; $i++) {
                $this.Data[$i] = New-Object 'byte[]' 256
                $offset = 256 * $i
                for ($c = 0; $c -lt 256; $c++) {
                    $this.Data[$i][$c] = $raw[$offset + $c]
                }
            }

            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }

    [byte[]] get_Item([int]$index) {
        return $this.Data[$index]
    }

    [byte[]] get_FullBright() {
        return $this.Data[0]
    }
}