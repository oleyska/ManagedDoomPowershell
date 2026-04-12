class DoomString {
    static [hashtable] $ValueTable = @{}
    static [hashtable] $NameTable = @{}

    [string] $Original
    [string] $Replaced

    DoomString([string] $original) {
        $this.Original = $original
        $this.Replaced = $original

        if (-not [DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original] = $this
        }
    }

    DoomString([string] $name, [string] $original) {
        $this.Original = $original
        $this.Replaced = $original

        if (-not [DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original] = $this
        }

        [DoomString]::NameTable[$name] = $this
    }

    [string] ToString() {
        return $this.Replaced
    }

    [char] Get([int] $index) {
        return $this.Replaced[$index]
    }

    static [void] ReplaceByValue([string] $original, [string] $replaced) {
        if ([DoomString]::ValueTable.ContainsKey($original)) {
            [DoomString]::ValueTable[$original].Replaced = $replaced
        }
    }

    static [void] ReplaceByName([string] $name, [string] $value) {
        if ([DoomString]::NameTable.ContainsKey($name)) {
            [DoomString]::NameTable[$name].Replaced = $value
        }
    }
}