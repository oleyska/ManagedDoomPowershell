class PlayerSpriteDef {
    [object]$State
    [int]$Tics
    [Fixed]$Sx
    [Fixed]$Sy

    PlayerSpriteDef() {
        $this.Clear()
    }

    [void] Clear() {
        $this.State = $null
        $this.Tics = 0
        $this.Sx = [Fixed]::Zero
        $this.Sy = [Fixed]::Zero
    }
}