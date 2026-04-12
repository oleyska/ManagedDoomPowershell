class MapCollision {
    [World] $World

    [Fixed] $OpenTop
    [Fixed] $OpenBottom
    [Fixed] $OpenRange
    [Fixed] $LowFloor

    MapCollision([World] $world) {
        $this.World = $world
    }

    # Sets OpenTop and OpenBottom to the window through a two-sided line.
    [void] LineOpening([LineDef] $line) {
        if ($null -eq $line.BackSide) {
            # If the line is single-sided, nothing can pass through.
            $this.OpenRange = [Fixed]::Zero
            return
        }

        $front = $line.FrontSector
        $back = $line.BackSector

        if ($front.CeilingHeight.Data -lt $back.CeilingHeight.Data) {
            $this.OpenTop = $front.CeilingHeight
        } else {
            $this.OpenTop = $back.CeilingHeight
        }

        if ($front.FloorHeight.Data -gt $back.FloorHeight.Data) {
            $this.OpenBottom = $front.FloorHeight
            $this.LowFloor = $back.FloorHeight
        } else {
            $this.OpenBottom = $back.FloorHeight
            $this.LowFloor = $front.FloorHeight
        }

        $this.OpenRange = $this.OpenTop - $this.OpenBottom
    }
}