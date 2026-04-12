class DoomSwitches {
    static [array]$SwitchNames = @()

    static DoomSwitches() {
        $switchPairs = @(
            "SW1BRCOM", "SW2BRCOM",
            "SW1BRN1", "SW2BRN1",
            "SW1BRN2", "SW2BRN2",
            "SW1BRNGN", "SW2BRNGN",
            "SW1BROWN", "SW2BROWN",
            "SW1COMM", "SW2COMM",
            "SW1COMP", "SW2COMP",
            "SW1DIRT", "SW2DIRT",
            "SW1EXIT", "SW2EXIT",
            "SW1GRAY", "SW2GRAY",
            "SW1GRAY1", "SW2GRAY1",
            "SW1METAL", "SW2METAL",
            "SW1PIPE", "SW2PIPE",
            "SW1SLAD", "SW2SLAD",
            "SW1STARG", "SW2STARG",
            "SW1STON1", "SW2STON1",
            "SW1STON2", "SW2STON2",
            "SW1STONE", "SW2STONE",
            "SW1STRTN", "SW2STRTN",
            "SW1BLUE", "SW2BLUE",
            "SW1CMT", "SW2CMT",
            "SW1GARG", "SW2GARG",
            "SW1GSTON", "SW2GSTON",
            "SW1HOT", "SW2HOT",
            "SW1LION", "SW2LION",
            "SW1SATYR", "SW2SATYR",
            "SW1SKIN", "SW2SKIN",
            "SW1VINE", "SW2VINE",
            "SW1WOOD", "SW2WOOD",
            "SW1PANEL", "SW2PANEL",
            "SW1ROCK", "SW2ROCK",
            "SW1MET2", "SW2MET2",
            "SW1WDMET", "SW2WDMET",
            "SW1BRIK", "SW2BRIK",
            "SW1MOD1", "SW2MOD1",
            "SW1ZIM", "SW2ZIM",
            "SW1STON6", "SW2STON6",
            "SW1TEK", "SW2TEK",
            "SW1MARB", "SW2MARB",
            "SW1SKULL", "SW2SKULL"
        )

        for ($i = 0; $i -lt $switchPairs.Count; $i += 2) {
            [DoomSwitches]::SwitchNames += ,@([DoomString]::new($switchPairs[$i]), [DoomString]::new($switchPairs[$i+1]))
        }
    }
}