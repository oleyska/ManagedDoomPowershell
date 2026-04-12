class Flat {
    [string]$Name
    [byte[]]$Data

    Flat([string]$name, [byte[]]$data) {
        $this.Name = $name
        $this.Data = $data
    }

    static [Flat] FromData([string]$name, [byte[]]$data) {
        return [Flat]::new($name, $data)
    }

    [string] ToString() {
        return $this.Name
    }
}