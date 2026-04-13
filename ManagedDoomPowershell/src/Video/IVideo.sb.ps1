class IVideo {
    [void] Render([Doom]$doom, [Fixed]$frameFrac) {
        throw [System.NotImplementedException]::new("Render method not implemented.")
    }

    [void] InitializeWipe() {
        throw [System.NotImplementedException]::new("InitializeWipe method not implemented.")
    }

    [bool] HasFocus() {
        throw [System.NotImplementedException]::new("HasFocus method not implemented.")
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
