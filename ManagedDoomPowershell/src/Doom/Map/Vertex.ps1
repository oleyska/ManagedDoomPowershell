class Vertex {
    # Static field for data size
    static [int]$dataSize = 4

    # Fields to store the x and y coordinates
    [Fixed]$x
    [Fixed]$y

    # Constructor to initialize Vertex object
    Vertex([Fixed]$x, [Fixed]$y) {
        $this.x = $x
        $this.y = $y
    }

    # Static method to create Vertex from data
    static [Vertex] FromData([byte[]]$data, [int]$offset) {
        $mX = [BitConverter]::ToInt16($data, $offset)
        $mY = [BitConverter]::ToInt16($data, $offset + 2)

        return [Vertex]::new([Fixed]::FromInt($mX), [Fixed]::FromInt($mY))
    }


    static [Vertex[]] FromWad([Wad]$wad, [int]$lump) {
        $length = $wad.GetLumpSize($lump)
        if ($length % [vertex]::dataSize -ne 0) {
            throw "Invalid lump size"
        }

        $data = $wad.ReadLump($lump)
        $count = $length / [vertex]::dataSize
        $vertices = @()

        for ($i = 0; $i -lt $count; $i++) {
            $offset = [vertex]::dataSize * $i
            $vertices += [Vertex]::FromData($data, $offset)
        }

        return $vertices
    }
}