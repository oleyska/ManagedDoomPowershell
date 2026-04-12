class PatchCache {
    [wad]$Wad
    [hashtable]$Cache

    PatchCache([wad]$wad) {
        $this.Wad = $wad
        $this.Cache = @{}
    }

    [Patch] get_Item([string]$name) {
        if (-not $this.Cache.ContainsKey($name)) {
            $this.Cache[$name] = [Patch]::FromWad($this.Wad, $name)
        }
        return $this.Cache[$name]
    }

    [int] GetWidth([string]$name) {
        return $this.get_Item($name).Width
    }

    [int] GetHeight([string]$name) {
        return $this.get_Item($name).Height
    }
}