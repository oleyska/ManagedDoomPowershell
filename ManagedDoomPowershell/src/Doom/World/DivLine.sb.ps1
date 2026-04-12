class DivLine {
    [Fixed] $X
    [Fixed] $Y
    [Fixed] $Dx
    [Fixed] $Dy

    DivLine() { }

    [void] MakeFrom([LineDef] $line) {
        $this.X = $line.Vertex1.X
        $this.Y = $line.Vertex1.Y
        $this.Dx = $line.Dx
        $this.Dy = $line.Dy
    }
}