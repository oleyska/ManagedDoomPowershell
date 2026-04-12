class TexturePatch {
    static [int]$DataSize = 10

    [int]$OriginX
    [int]$OriginY
    [Patch]$Patch

    TexturePatch([int]$originX, [int]$originY, [Patch]$patch) {
        $this.OriginX = $originX
        $this.OriginY = $originY
        $this.Patch = $patch
    }

    static [TexturePatch] FromData([byte[]]$data, [int]$offset, [Patch[]]$patches) {
        $moriginX = [BitConverter]::ToInt16($data, $offset)
        $moriginY = [BitConverter]::ToInt16($data, $offset + 2)
        $patchNum = [BitConverter]::ToInt16($data, $offset + 4)

        return [TexturePatch]::new($moriginX, $moriginY, $patches[$patchNum])
    }

    [string] get_Name() {
        return $this.Patch.Name
    }

    [int] get_OriginX() {
        return $this.OriginX
    }

    [int] get_OriginY() {
        return $this.OriginY
    }

    [int] get_Width() {
        return $this.Patch.Width
    }

    [int] get_Height() {
        return $this.Patch.Height
    }

    [Column[][]] get_Columns() {
        return $this.Patch.Columns
    }
}