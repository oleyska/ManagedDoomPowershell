class Box {
    static [int] $Top = 0
    static [int] $Bottom = 1
    static [int] $Left = 2
    static [int] $Right = 3

    static [void] Clear([ref]$box) {
        $box.Value[[Box]::Top] = $box.Value[[Box]::Right] = [Fixed]::MinValue
        $box.Value[[Box]::Bottom] = $box.Value[[Box]::Left] = [Fixed]::MaxValue
    }

    static [void] AddPoint([ref]$box, [Fixed]$x, [Fixed]$y) {
        if ($x.ToFloat() -lt ($box.Value[[Box]::Left]).ToFloat()) {
            $box.Value[[Box]::Left] = $x
        } elseif ($x.ToFloat() -gt (($box.Value[[Box]::Right])).ToFloat()) {
            $box.Value[[Box]::Right] = $x
        }

        if ($y.ToFloat() -lt ($box.Value[[Box]::Bottom]).ToFloat()) {
            $box.Value[[Box]::Bottom] = $y
        } elseif ($y.ToFloat() -gt ($box.Value[[Box]::Top]).ToFloat()) {
            $box.Value[[Box]::Top] = $y
        }
    }
}