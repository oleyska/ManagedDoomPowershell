class Column {
    static [int]$Last = 0xFF

    [int]$TopDelta
    [byte[]]$Data
    [int]$Offset
    [int]$Length

    Column([int]$topDelta, [byte[]]$data, [int]$offset, [int]$length) {
        $this.TopDelta = $topDelta
        $this.Data = $data
        $this.Offset = $offset
        $this.Length = $length
    }
}