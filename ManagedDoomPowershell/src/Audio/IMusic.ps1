
class IMusic {
    [void]StartMusic([Bgm]$bgm, [bool]$loop) {
        throw [System.NotImplementedException]::new("StartMusic method not implemented.")
    }

    [int]get_MaxVolume() {
        throw [System.NotImplementedException]::new("MaxVolume property not implemented.")
    }

    [int]get_Volume() {
        throw [System.NotImplementedException]::new("Volume property not implemented.")
    }

    [void]set_Volume([int]$value) {
        throw [System.NotImplementedException]::new("Volume property not implemented.")
    }
}
