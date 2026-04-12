class DoomAnimation {
    [AnimationDef[]]$TextureAnimation = @()

    DoomAnimation() {
        $animations = @(
            $false, "NUKAGE3", "NUKAGE1", 8,
            $false, "FWATER4", "FWATER1", 8,
            $false, "SWATER4", "SWATER1", 8,
            $false, "LAVA4", "LAVA1", 8,
            $false, "BLOOD3", "BLOOD1", 8,
            # DOOM II flat animations
            $false, "RROCK08", "RROCK05", 8,
            $false, "SLIME04", "SLIME01", 8,
            $false, "SLIME08", "SLIME05", 8,
            $false, "SLIME12", "SLIME09", 8,
            $true, "BLODGR4", "BLODGR1", 8,
            $true, "SLADRIP3", "SLADRIP1", 8,
            $true, "BLODRIP4", "BLODRIP1", 8,
            $true, "FIREWALL", "FIREWALA", 8,
            $true, "GSTFONT3", "GSTFONT1", 8,
            $true, "FIRELAVA", "FIRELAV3", 8,
            $true, "FIREMAG3", "FIREMAG1", 8,
            $true, "FIREBLU2", "FIREBLU1", 8,
            $true, "ROCKRED3", "ROCKRED1", 8,
            $true, "BFALL4", "BFALL1", 8,
            $true, "SFALL4", "SFALL1", 8,
            $true, "WFALL4", "WFALL1", 8,
            $true, "DBRAIN4", "DBRAIN1", 8
        )

        for ($i = 0; $i -lt $animations.Count; $i += 4) {
            [DoomAnimation]::TextureAnimation += [AnimationDef]::new($animations[$i], $animations[$i+1], $animations[$i+2], $animations[$i+3])
        }
    }
}