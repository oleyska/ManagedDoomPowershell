class AnimationDef {
    [bool]$IsTexture
    [string]$EndName
    [string]$StartName
    [int]$Speed

    AnimationDef([bool]$isTexture, [string]$endName, [string]$startName, [int]$speed) {
        $this.IsTexture = $isTexture
        $this.EndName = $endName
        $this.StartName = $startName
        $this.Speed = $speed
    }
}