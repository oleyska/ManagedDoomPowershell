class AnimationInfo {
    [AnimationType]$type
    [int]$period
    [int]$count
    [int]$x
    [int]$y
    [int]$data

    # Constructor 1
    AnimationInfo([AnimationType]$type, [int]$period, [int]$count, [int]$x, [int]$y) {
        $this.type = $type
        $this.period = $period
        $this.count = $count
        $this.x = $x
        $this.y = $y
    }

    # Constructor 2
    AnimationInfo([AnimationType]$type, [int]$period, [int]$count, [int]$x, [int]$y, [int]$data) {
        $this.type = $type
        $this.period = $period
        $this.count = $count
        $this.x = $x
        $this.y = $y
        $this.data = $data
    }

    # Static property for Episodes
    static [System.Collections.Generic.IReadOnlyList[System.Collections.Generic.IReadOnlyList[AnimationInfo]]] $Episodes = @(
        # Episode 0
        @(
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 224, 104),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 184, 160),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 112, 136),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 72, 112),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 88, 96),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 64, 48),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 192, 40),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 136, 16),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 80, 16),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 64, 24)
        ),
        
        # Episode 1
        @(
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 1),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 2),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 3),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 4),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 5),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 6),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 7),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 3, 192, 144, 8),
            [AnimationInfo]::new([AnimationType]::Level, [GameConst]::TicRate / 3, 1, 128, 136, 8)
        ),
        
        # Episode 2
        @(
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 104, 168),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 40, 136),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 160, 96),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 104, 80),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 3, 3, 120, 32),
            [AnimationInfo]::new([AnimationType]::Always, [GameConst]::TicRate / 4, 3, 40, 0)
        )
    )
}