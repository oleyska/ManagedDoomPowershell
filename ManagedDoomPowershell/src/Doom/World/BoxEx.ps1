class BoxEx {
    # Methods for Fixed array
    static [Fixed] Top([Fixed[]]$box) {
        return $box[[Box]::Top]
    }

    static [Fixed] Bottom([Fixed[]]$box) {
        return $box[[Box]::Bottom]
    }

    static [Fixed] Left([Fixed[]]$box) {
        return $box[[Box]::Left]
    }

    static [Fixed] Right([Fixed[]]$box) {
        return $box[[Box]::Right]
    }

    # Methods for int array
    static [int] Top([int[]]$box) {
        return $box[[Box]::Top]
    }

    static [int] Bottom([int[]]$box) {
        return $box[[Box]::Bottom]
    }

    static [int] Left([int[]]$box) {
        return $box[[Box]::Left]
    }

    static [int] Right([int[]]$box) {
        return $box[[Box]::Right]
    }
}