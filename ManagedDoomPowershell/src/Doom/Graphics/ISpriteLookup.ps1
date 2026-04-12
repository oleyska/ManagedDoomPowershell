class ISpriteLookup {
    ISpriteLookup() {
    }

    [SpriteDef] get_Item([Sprite]$sprite) {
        throw [System.NotImplementedException]::new("Index accessor not implemented.")
    }
}