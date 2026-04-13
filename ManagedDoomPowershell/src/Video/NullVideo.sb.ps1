class NullVideo : IVideo{
    static [NullVideo]$Instance

    NullVideo() {
    }

    static [NullVideo] GetInstance() {
        if (-not [NullVideo]::Instance) {
            [NullVideo]::Instance = [NullVideo]::new()
        }
        return [NullVideo]::Instance
    }

    [void] Render([Doom]$doom, [Fixed]$frameFrac) {
    }

    [void] InitializeWipe() {
    }

    [bool] HasFocus() {
        return $true
    }

    [int] get_MaxWindowSize() {
        return [ThreeDRenderer]::MaxScreenSize
    }

    [int] get_MaxGammaCorrectionLevel() {
        return 10
    }

    [int] WipeBandCount() {
        return 321
    }

    [int] WipeHeight() {
        return 200
    }

    [int] get_WindowSize() {
        return 0
    }

    [void] set_WindowSize([int] $value) {
    }

    [bool] get_DisplayMessage() {
        return $true
    }

    [void] set_DisplayMessage([bool] $value) {
    }

    [int] get_GammaCorrectionLevel() {
        return 0
    }

    [void] set_GammaCorrectionLevel([int] $value) {
    }
}
