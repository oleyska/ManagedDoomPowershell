class IFlatLookup {
    hidden [Flat[]] $Flats

    IFlatLookup() {
        $this.Flats = @()
    }

    [int] GetNumber([string] $name) {
        throw "GetNumber must be implemented in derived class"
    }

    [int] get_Count() {
        throw "Count must be implemented in derived class"
    }

    [Flat] get_Item([int] $num) {
        throw "Indexer must be implemented in derived class"
    }

    [Flat] get_Item([string] $name) {
        throw "Indexer must be implemented in derived class"
    }

    [int] get_SkyFlatNumber() {
        throw "SkyFlatNumber must be implemented in derived class"
    }

    [Flat] get_SkyFlat() {
        throw "SkyFlat must be implemented in derived class"
    }
}
