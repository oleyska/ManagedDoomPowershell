class WorldMap {
    # Define the static Locations array
    static [System.Collections.Generic.List[System.Collections.Generic.List[Point]]]$Locations = @(
        # Episode 0 world map.
        @(
            [Point]::new(185, 164),  # location of level 0 (CJ)
            [Point]::new(148, 143),  # location of level 1 (CJ)
            [Point]::new(69, 122),   # location of level 2 (CJ)
            [Point]::new(209, 102),  # location of level 3 (CJ)
            [Point]::new(116, 89),   # location of level 4 (CJ)
            [Point]::new(166, 55),   # location of level 5 (CJ)
            [Point]::new(71, 56),    # location of level 6 (CJ)
            [Point]::new(135, 29),   # location of level 7 (CJ)
            [Point]::new(71, 24)     # location of level 8 (CJ)
        ),
        
        # Episode 1 world map should go here.
        @(
            [Point]::new(254, 25),   # location of level 0 (CJ)
            [Point]::new(97, 50),    # location of level 1 (CJ)
            [Point]::new(188, 64),   # location of level 2 (CJ)
            [Point]::new(128, 78),   # location of level 3 (CJ)
            [Point]::new(214, 92),   # location of level 4 (CJ)
            [Point]::new(133, 130),  # location of level 5 (CJ)
            [Point]::new(208, 136),  # location of level 6 (CJ)
            [Point]::new(148, 140),  # location of level 7 (CJ)
            [Point]::new(235, 158)   # location of level 8 (CJ)
        ),

        # Episode 2 world map should go here.
        @(
            [Point]::new(156, 168),  # location of level 0 (CJ)
            [Point]::new(48, 154),   # location of level 1 (CJ)
            [Point]::new(174, 95),   # location of level 2 (CJ)
            [Point]::new(265, 75),   # location of level 3 (CJ)
            [Point]::new(130, 48),   # location of level 4 (CJ)
            [Point]::new(279, 23),   # location of level 5 (CJ)
            [Point]::new(198, 48),   # location of level 6 (CJ)
            [Point]::new(140, 25),   # location of level 7 (CJ)
            [Point]::new(281, 136)   # location of level 8 (CJ)
        )
    )


}
    # Define the Point class
    class Point {
        [int]$x
        [int]$y

        Point([int]$x, [int]$y) {
            $this.x = $x
            $this.y = $y
        }
    }