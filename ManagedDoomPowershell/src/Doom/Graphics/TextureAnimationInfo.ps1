class TextureAnimationInfo {
    [bool]$IsTexture
    [int]$PicNum
    [int]$BasePic
    [int]$NumPics
    [int]$Speed

    TextureAnimationInfo([bool]$isTexture, [int]$picNum, [int]$basePic, [int]$numPics, [int]$speed) {
        $this.IsTexture = $isTexture
        $this.PicNum = $picNum
        $this.BasePic = $basePic
        $this.NumPics = $numPics
        $this.Speed = $speed
    }
}