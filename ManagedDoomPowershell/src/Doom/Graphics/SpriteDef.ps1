class SpriteDef {
    [SpriteFrame[]]$Frames

    SpriteDef([SpriteFrame[]]$frames) {
        $this.Frames = $frames
    }
}