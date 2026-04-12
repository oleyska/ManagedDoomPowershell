enum DoomKey {
    Unknown = -1
    A = 0
    B = 1
    C = 2
    D = 3
    E = 4
    F = 5
    G = 6
    H = 7
    I = 8
    J = 9
    K = 10
    L = 11
    M = 12
    N = 13
    O = 14
    P = 15
    Q = 16
    R = 17
    S = 18
    T = 19
    U = 20
    V = 21
    W = 22
    X = 23
    Y = 24
    Z = 25
    Num0 = 26
    Num1 = 27
    Num2 = 28
    Num3 = 29
    Num4 = 30
    Num5 = 31
    Num6 = 32
    Num7 = 33
    Num8 = 34
    Num9 = 35
    Escape = 36
    LControl = 37
    LShift = 38
    LAlt = 39
    LSystem = 40
    RControl = 41
    RShift = 42
    RAlt = 43
    RSystem = 44
    Menu = 45
    LBracket = 46
    RBracket = 47
    Semicolon = 48
    Comma = 49
    Period = 50
    Quote = 51
    Slash = 52
    Backslash = 53
    Tilde = 54
    Equal = 55
    Hyphen = 56
    Space = 57
    Enter = 58
    Backspace = 59
    Tab = 60
    PageUp = 61
    PageDown = 62
    End = 63
    Home = 64
    Insert = 65
    Delete = 66
    Add = 67
    Subtract = 68
    Multiply = 69
    Divide = 70
    Left = 71
    Right = 72
    Up = 73
    Down = 74
    Numpad0 = 75
    Numpad1 = 76
    Numpad2 = 77
    Numpad3 = 78
    Numpad4 = 79
    Numpad5 = 80
    Numpad6 = 81
    Numpad7 = 82
    Numpad8 = 83
    Numpad9 = 84
    F1 = 85
    F2 = 86
    F3 = 87
    F4 = 88
    F5 = 89
    F6 = 90
    F7 = 91
    F8 = 92
    F9 = 93
    F10 = 94
    F11 = 95
    F12 = 96
    F13 = 97
    F14 = 98
    F15 = 99
    Pause = 100
    Count = 101
}

class DoomKeyEx {
    
    static [char] GetChar([DoomKey]$key) {
        switch ($key) {
            'A' { return 'a' }
            'B' { return 'b' }
            'C' { return 'c' }
            'D' { return 'd' }
            'E' { return 'e' }
            'F' { return 'f' }
            'G' { return 'g' }
            'H' { return 'h' }
            'I' { return 'i' }
            'J' { return 'j' }
            'K' { return 'k' }
            'L' { return 'l' }
            'M' { return 'm' }
            'N' { return 'n' }
            'O' { return 'o' }
            'P' { return 'p' }
            'Q' { return 'q' }
            'R' { return 'r' }
            'S' { return 's' }
            'T' { return 't' }
            'U' { return 'u' }
            'V' { return 'v' }
            'W' { return 'w' }
            'X' { return 'x' }
            'Y' { return 'y' }
            'Z' { return 'z' }
            'Num0' { return '0' }
            'Num1' { return '1' }
            'Num2' { return '2' }
            'Num3' { return '3' }
            'Num4' { return '4' }
            'Num5' { return '5' }
            'Num6' { return '6' }
            'Num7' { return '7' }
            'Num8' { return '8' }
            'Num9' { return '9' }
            'LBracket' { return '[' }
            'RBracket' { return ']' }
            'Semicolon' { return ';' }
            'Comma' { return ',' }
            'Period' { return '.' }
            'Quote' { return '"' }
            'Slash' { return '/' }
            'Backslash' { return '\\' }
            'Equal' { return '=' }
            'Hyphen' { return '-' }
            'Space' { return ' ' }
            'Add' { return '+' }
            'Subtract' { return '-' }
            'Multiply' { return '*' }
            'Divide' { return '/' }
            'Numpad0' { return '0' }
            'Numpad1' { return '1' }
            'Numpad2' { return '2' }
            'Numpad3' { return '3' }
            'Numpad4' { return '4' }
            'Numpad5' { return '5' }
            'Numpad6' { return '6' }
            'Numpad7' { return '7' }
            'Numpad8' { return '8' }
            'Numpad9' { return '9' }
            default { return [char]0 }
        }
        return [char]0
    }
    
    static [string] ToString([DoomKey]$key) {
        switch ($key) {
            'A' { return "a" }
            'B' { return "b" }
            'C' { return "c" }
            'D' { return "d" }
            'E' { return "e" }
            'F' { return "f" }
            'G' { return "g" }
            'H' { return "h" }
            'I' { return "i" }
            'J' { return "j" }
            'K' { return "k" }
            'L' { return "l" }
            'M' { return "m" }
            'N' { return "n" }
            'O' { return "o" }
            'P' { return "p" }
            'Q' { return "q" }
            'R' { return "r" }
            'S' { return "s" }
            'T' { return "t" }
            'U' { return "u" }
            'V' { return "v" }
            'W' { return "w" }
            'X' { return "x" }
            'Y' { return "y" }
            'Z' { return "z" }
            'Num0' { return "num0" }
            'Num1' { return "num1" }
            'Num2' { return "num2" }
            'Num3' { return "num3" }
            'Num4' { return "num4" }
            'Num5' { return "num5" }
            'Num6' { return "num6" }
            'Num7' { return "num7" }
            'Num8' { return "num8" }
            'Num9' { return "num9" }
            default { return "unknown" }
        }
        return [DoomKey]::Unknown
    }
    
    static [DoomKey] Parse([string]$value) {
        switch ($value.ToLower()) {
            'a' { return [DoomKey]::A }
            'b' { return [DoomKey]::B }
            'c' { return [DoomKey]::C }
            'd' { return [DoomKey]::D }
            'e' { return [DoomKey]::E }
            'f' { return [DoomKey]::F }
            'g' { return [DoomKey]::G }
            'h' { return [DoomKey]::H }
            'i' { return [DoomKey]::I }
            'j' { return [DoomKey]::J }
            'k' { return [DoomKey]::K }
            'l' { return [DoomKey]::L }
            'm' { return [DoomKey]::M }
            'n' { return [DoomKey]::N }
            'o' { return [DoomKey]::O }
            'p' { return [DoomKey]::P }
            'q' { return [DoomKey]::Q }
            'r' { return [DoomKey]::R }
            's' { return [DoomKey]::S }
            't' { return [DoomKey]::T }
            'u' { return [DoomKey]::U }
            'v' { return [DoomKey]::V }
            'w' { return [DoomKey]::W }
            'x' { return [DoomKey]::X }
            'y' { return [DoomKey]::Y }
            'z' { return [DoomKey]::Z }
            default { return [DoomKey]::Unknown }
        }
        return [DoomKey]::Unknown
    }
}