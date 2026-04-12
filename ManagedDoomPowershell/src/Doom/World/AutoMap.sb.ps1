class AutoMap {
    [World] $world

    [Fixed] $minX
    [Fixed] $maxX
    [Fixed] $minY
    [Fixed] $maxY

    [Fixed] $viewX
    [Fixed] $viewY

    [bool] $visible
    [AutoMapState] $state

    [Fixed] $zoom
    [bool] $follow

    [bool] $zoomIn
    [bool] $zoomOut

    [bool] $left
    [bool] $right
    [bool] $up
    [bool] $down

    [System.Collections.Generic.List[Vertex]] $marks
    [int] $nextMarkNumber

    AutoMap([World] $world) {
        $this.world = $world

        $this.minX = [Fixed]::MaxValue
        $this.maxX = [Fixed]::MinValue
        $this.minY = [Fixed]::MaxValue
        $this.maxY = [Fixed]::MinValue

        foreach ($vertex in $world.Map.Vertices) {
            if ($vertex.X.toFloat() -lt $this.minX.toFloat()) { $this.minX = $vertex.X }
            if ($vertex.X.toFloat() -gt $this.maxX.toFloat()) { $this.maxX = $vertex.X }
            if ($vertex.Y.toFloat() -lt $this.minY.toFloat()) { $this.minY = $vertex.Y }
            if ($vertex.Y.toFloat() -gt $this.maxY.toFloat()) { $this.maxY = $vertex.Y }
        }

        $this.viewX = $this.minX + ($this.maxX - $this.minX) / 2
        $this.viewY = $this.minY + ($this.maxY - $this.minY) / 2

        $this.visible = $false
        $this.state = [AutoMapState]::None

        $this.zoom = [Fixed]::One
        $this.follow = $true

        $this.zoomIn = $false
        $this.zoomOut = $false
        $this.left = $false
        $this.right = $false
        $this.up = $false
        $this.down = $false

        $this.marks = New-Object 'System.Collections.Generic.List[Vertex]'
        $this.nextMarkNumber = 0
    }

    [void] Update() {
        if ($this.zoomIn) { $this.zoom += $this.zoom / 16 }
        if ($this.zoomOut) { $this.zoom -= $this.zoom / 16 }

        if ($this.zoom.Data -lt ([Fixed]::One / 2).Data) { $this.zoom = [Fixed]::One / 2 }
        elseif ($this.zoom.Data -gt ([Fixed]::One * 32).Data) { $this.zoom = [Fixed]::One * 32 }

        if ($this.left) { $this.viewX -= 64 / $this.zoom }
        if ($this.right) { $this.viewX += 64 / $this.zoom }
        if ($this.up) { $this.viewY += 64 / $this.zoom }
        if ($this.down) { $this.viewY -= 64 / $this.zoom }

        if ($this.viewX.Data -lt $this.minX.Data) { $this.viewX = $this.minX }
        elseif ($this.viewX.Data -gt $this.maxX.Data) { $this.viewX = $this.maxX }

        if ($this.viewY.Data -lt $this.minY.Data) { $this.viewY = $this.minY }
        elseif ($this.viewY.Data -gt $this.maxY.Data) { $this.viewY = $this.maxY }

        if ($this.follow) {
            $player = $this.world.ConsolePlayer.Mobj
            $this.viewX = $player.X
            $this.viewY = $player.Y
        }
    }

    [bool] DoEvent([DoomEvent] $e) {
        switch ($e.Key) {
            { $_ -in [DoomKey]::Add, [DoomKey]::Quote, [DoomKey]::Equal } {
                $this.zoomIn = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -in [DoomKey]::Subtract, [DoomKey]::Hyphen, [DoomKey]::Semicolon } {
                $this.zoomOut = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -eq [DoomKey]::Left } {
                $this.left = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -eq [DoomKey]::Right } {
                $this.right = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -eq [DoomKey]::Up } {
                $this.up = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -eq [DoomKey]::Down } {
                $this.down = ($e.Type -eq [EventType]::KeyDown)
                return $true
            }
            { $_ -eq [DoomKey]::F -and $e.Type -eq [EventType]::KeyDown } {
                $this.follow = -not $this.follow
                if ($this.follow) {
                    $this.world.ConsolePlayer.SendMessage([DoomInfo]::Strings.AMSTR_FOLLOWON)
                } else {
                    $this.world.ConsolePlayer.SendMessage([DoomInfo]::Strings.AMSTR_FOLLOWOFF)
                }
                return $true
            }
            { $_ -eq [DoomKey]::M -and $e.Type -eq [EventType]::KeyDown } {
                if ($this.marks.Count -lt 10) {
                    $this.marks.Add([Vertex]::new($this.viewX, $this.viewY))
                } else {
                    $this.marks[$this.nextMarkNumber] = [Vertex]::new($this.viewX, $this.viewY)
                }
                $this.nextMarkNumber++
                if ($this.nextMarkNumber -eq 10) { $this.nextMarkNumber = 0 }
                $this.world.ConsolePlayer.SendMessage([DoomInfo]::Strings.AMSTR_MARKEDSPOT)
                return $true
            }
            { $_ -eq [DoomKey]::C -and $e.Type -eq [EventType]::KeyDown } {
                $this.marks.Clear()
                $this.nextMarkNumber = 0
                $this.world.ConsolePlayer.SendMessage([DoomInfo]::Strings.AMSTR_MARKSCLEARED)
                return $true
            }
        }
        return $false
    }

    [void] Open() {
        $this.visible = $true
    }

    [void] Close() {
        $this.visible = $false
        $this.zoomIn = $false
        $this.zoomOut = $false
        $this.left = $false
        $this.right = $false
        $this.up = $false
        $this.down = $false
    }

    [void] ToggleCheat() {
        $this.state = [AutoMapState]($this.state + 1)
        if ($this.state -eq 3) {
            $this.state = [AutoMapState]::None
        }
    }

    [Fixed] get_MinX() { return $this.minX }
    [Fixed] get_MaxX() { return $this.maxX }
    [Fixed] get_MinY() { return $this.minY }
    [Fixed] get_MaxY() { return $this.maxY }
    [Fixed] get_ViewX() { return $this.viewX }
    [Fixed] get_ViewY() { return $this.viewY }
    [Fixed] get_Zoom() { return $this.zoom }
    [bool] get_Follow() { return $this.follow }
    [bool] get_Visible() { return $this.visible }
    [AutoMapState] get_State() { return $this.state }
    [System.Collections.Generic.List[Vertex]] get_Marks() { return $this.marks }
}