class ITextureLookup {
    hidden [Texture[]] $Textures

    ITextureLookup() {
        $this.Textures = @()
    }

    [int] GetNumber([string] $name) {
        throw "GetNumber must be implemented in derived class"
    }

    [int] get_Count() {
        throw "Count must be implemented in derived class"
    }

    [int[]] get_SwitchList() {
        throw "SwitchList must be implemented in derived class"
    }
}
