class DummyData {
    # Static variables
    static [Patch]$dummyPatch
    static [System.Collections.Generic.Dictionary[int, Texture]]$dummyTextures = @{}
    static [Flat] $dummyFlat
    static [Flat] $dummySkyFlat

    # GetPatch method
    static [Patch] GetPatch() {
        if ($null -ne [dummydata]::dummyPatch) {
            return [dummydata]::dummyPatch
        }
        else {
            $width = 64
            $height = 128

            $data = New-Object byte[] ($height + 32)
            for ($y = 0; $y -lt $data.Length; $y++) {
                $data[$y] = if ($y / 32 % 2 -eq 0) { 80 } else { 96 }
            }

            $columns = New-Object 'Column[]' $width
            $c1 = [Column[]]@([Column]::new(0, $data, 0, $height))
            $c2 = [Column[]]@([Column]::new(0, $data, 32, $height))

            for ($x = 0; $x -lt $width; $x++) {
                $columns[$x] = if ($x / 32 % 2 -eq 0) { $c1 } else { $c2 }
            }

            $tdummyPatch = [Patch]::new("DUMMY", $width, $height, 32, 128, $columns)

            return $tdummyPatch
        }
    }

    # GetTexture method
    static [Texture] GetTexture([int]$height) {
        if ([DummyData]::dummyTextures.ContainsKey($height)) {
            return [DummyData]::dummyTextures[$height]
        }
        else {
            $patch = [TexturePatch[]]@([TexturePatch]::new(0, 0, [DummyData]::GetPatch()))
            [DummyData]::dummyTextures.Add($height, [Texture]::new("DUMMY", $false, 64, $height, $patch))
            return [DummyData]::dummyTextures[$height]
        }
    }

    # GetFlat method
    static [Flat] GetFlat() {
        if ($null -ne [dummydata]::dummyFlat ) {
            return [dummydata]::dummyFlat
        }
        else {
            $data = New-Object byte[] (64 * 64)
            $spot = 0
            for ($y = 0; $y -lt 64; $y++) {
                for ($x = 0; $x -lt 64; $x++) {
                    $data[$spot] = if ((($x / 32) -bxor ($y / 32)) -eq 0) { 80 } else { 96 }
                    $spot++
                }
            }

            [dummydata]::dummyFlat = [Flat]::new("DUMMY", $data)

            return [dummydata]::dummyFlat
        }
    }

    # GetSkyFlat method
    static [Flat] GetSkyFlat() {
        if ($null -ne [dummydata]::dummySkyFlat) {
            return [dummydata]::dummySkyFlat
        }
        else {
            [dummydata]::dummySkyFlat = [Flat]::new("DUMMY", [DummyData]::GetFlat().Data)
            return [dummydata]::dummySkyFlat
        }
    }
}