class SpriteFrame {
    [bool]$Rotate
    [Patch[]]$Patches
    [bool[]]$Flip

    SpriteFrame([bool]$rotate, [Patch[]]$patches, [bool[]]$flip) {
        $this.Rotate = $rotate
        $this.Patches = $patches
        $this.Flip = $flip
    }
}