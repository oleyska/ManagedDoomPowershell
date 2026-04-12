class Palette {
    static [int]$DamageStart = 1
    static [int]$DamageCount = 8

    static [int]$BonusStart = 9
    static [int]$BonusCount = 4

    static [int]$IronFeet = 13

    [byte[]]$Data
    [uint[][]]$Palettes

    Palette([wad]$wad) {
        try {
            [Console]::Write("Load palette: ")

            $this.Data = $wad.ReadLump("PLAYPAL")

            $count = $this.Data.Length / (3 * 256)
            $this.Palettes = New-Object 'uint[][]' $count
            for ($i = 0; $i -lt $this.Palettes.Length; $i++) {
                $this.Palettes[$i] = New-Object 'uint[]' 256
            }

            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            throw $_.Exception
        }
    }

    [void] ResetColors([double]$p) {
        for ($i = 0; $i -lt $this.Palettes.Length; $i++) {
            $paletteOffset = (3 * 256) * $i
            for ($j = 0; $j -lt 256; $j++) {
                $colorOffset = $paletteOffset + (3 * $j)

                $r = $this.Data[$colorOffset]
                $g = $this.Data[$colorOffset + 1]
                $b = $this.Data[$colorOffset + 2]

                $r = [byte]([math]::Round(255 * [Palette]::CorrectionCurve($r / 255.0, $p)))
                $g = [byte]([math]::Round(255 * [Palette]::CorrectionCurve($g / 255.0, $p)))
                $b = [byte]([math]::Round(255 * [Palette]::CorrectionCurve($b / 255.0, $p)))

                $packed =
                    ([uint]$r) -bor
                    (([uint]$g) -shl 8) -bor
                    (([uint]$b) -shl 16) -bor
                    (([uint]255) -shl 24)

                $this.Palettes[$i][$j] = $packed
            }
        }
    }

    static [double] CorrectionCurve([double]$x, [double]$p) {
        return [math]::Pow($x, $p)
    }

    [uint[]] get_Item([int]$paletteNumber) {
        return $this.Palettes[$paletteNumber]
    }
}
