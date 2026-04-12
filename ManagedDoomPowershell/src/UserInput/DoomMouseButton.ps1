enum DoomMouseButton {
    Unknown = -1
    Mouse1 = 0
    Mouse2
    Mouse3
    Mouse4
    Mouse5
    Count
}

class DoomMouseButtonEx {
    # Hidden constructor to mimic a static class pattern.
    hidden DoomMouseButtonEx() { }

    static [string] ToString([DoomMouseButton] $button) {
        switch ($button) {
            'Mouse1' { return "mouse1" }
            'Mouse2' { return "mouse2" }
            'Mouse3' { return "mouse3" }
            'Mouse4' { return "mouse4" }
            'Mouse5' { return "mouse5" }
        }
        return "unknown"
    }

    static [DoomMouseButton] Parse([string] $value) {
        switch ($value.ToLower()) {
            "mouse1" { return [DoomMouseButton]::Mouse1 }
            "mouse2" { return [DoomMouseButton]::Mouse2 }
            "mouse3" { return [DoomMouseButton]::Mouse3 }
            "mouse4" { return [DoomMouseButton]::Mouse4 }
            "mouse5" { return [DoomMouseButton]::Mouse5 }
        }
        return [DoomMouseButton]::Unknown
    }
}