###needs [IMusic]

class NullMusic : IMusic {
    static [NullMusic]$Instance
    [int]$volume
    NullMusic() {
        $this.Volume = 0
    }

    static [NullMusic] GetInstance() {
        if (-not [NullMusic]::Instance) {
            [NullMusic]::Instance = [NullMusic]::new()
        }
        return [NullMusic]::Instance
    }

    [void] StartMusic([Bgm]$bgm, [bool]$loop) {
        # No operation
    }

    static [int] $MaxVolume = 15

    [int] get_MaxVolume() {
        return [NullMusic]::MaxVolume
    }

    [int] get_Volume() {
        return $this.Volume
    }

    [void] set_Volume([int]$value) {
        $this.volume = [Math]::Clamp($value, 0, [NullMusic]::MaxVolume)
    }
}
