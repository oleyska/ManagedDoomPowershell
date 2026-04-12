class Intercept {
    [Fixed] $Frac
    [Mobj] $Thing
    [LineDef] $Line

    Intercept() {
        $this.Frac = [Fixed]::Zero
        $this.Thing = $null
        $this.Line = $null
    }

    [void] Make([Fixed] $frac, [Mobj] $thing) {
        $this.Frac = $frac
        $this.Thing = $thing
        $this.Line = $null
    }

    [void] Make([Fixed] $frac, [LineDef] $line) {
        $this.Frac = $frac
        $this.Thing = $null
        $this.Line = $line
    }

    [Mobj] getThing() { return $this.Thing }
    [LineDef] getLine() { return $this.Line }
}