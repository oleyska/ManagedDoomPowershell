class LumpInfo {
    [string]$name
    [System.IO.Stream]$stream
    [int]$position
    [int]$size

    LumpInfo([string]$name, [System.IO.Stream]$stream, [int]$position, [int]$size) {
        $this.name = $name
        $this.stream = $stream
        $this.position = $position
        $this.size = $size
    }

    [string]getName() {
        return $this.name
    }

    [System.IO.Stream]getStream() {
        return $this.stream
    }

    [int]getPosition() {
        return $this.position
    }

    [int]getSize() {
        return $this.size
    }
}