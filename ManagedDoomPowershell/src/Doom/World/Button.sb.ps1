class Button {
    [LineDef] $Line
    [ButtonPosition] $Position
    [int] $Texture
    [int] $Timer
    [Mobj] $SoundOrigin

    Button() {
        $this.Clear()
    }

    [void] Clear() {
        $this.Line = $null
        $this.Position = 0
        $this.Texture = 0
        $this.Timer = 0
        $this.SoundOrigin = $null
    }
}