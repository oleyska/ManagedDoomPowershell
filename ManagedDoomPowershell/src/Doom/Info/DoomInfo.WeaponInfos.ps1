class Weaponinfos {
    static [WeaponInfo[]] $WeaponInfos = @(
        # Fist
        [WeaponInfo]::new(
            [AmmoType]::NoAmmo,
            [MobjState]::Punchup,
            [MobjState]::Punchdown,
            [MobjState]::Punch,
            [MobjState]::Punch1,
            [MobjState]::Null
        ),

        # Pistol
        [WeaponInfo]::new(
            [AmmoType]::Clip,
            [MobjState]::Pistolup,
            [MobjState]::Pistoldown,
            [MobjState]::Pistol,
            [MobjState]::Pistol1,
            [MobjState]::Pistolflash
        ),

        # Shotgun
        [WeaponInfo]::new(
            [AmmoType]::Shell,
            [MobjState]::Sgunup,
            [MobjState]::Sgundown,
            [MobjState]::Sgun,
            [MobjState]::Sgun1,
            [MobjState]::Sgunflash1
        ),

        # Chaingun
        [WeaponInfo]::new(
            [AmmoType]::Clip,
            [MobjState]::Chainup,
            [MobjState]::Chaindown,
            [MobjState]::Chain,
            [MobjState]::Chain1,
            [MobjState]::Chainflash1
        ),

        # Missile Launcher
        [WeaponInfo]::new(
            [AmmoType]::Missile,
            [MobjState]::Missileup,
            [MobjState]::Missiledown,
            [MobjState]::Missile,
            [MobjState]::Missile1,
            [MobjState]::Missileflash1
        ),

        # Plasma Rifle
        [WeaponInfo]::new(
            [AmmoType]::Cell,
            [MobjState]::Plasmaup,
            [MobjState]::Plasmadown,
            [MobjState]::Plasma,
            [MobjState]::Plasma1,
            [MobjState]::Plasmaflash1
        ),

        # BFG 9000
        [WeaponInfo]::new(
            [AmmoType]::Cell,
            [MobjState]::Bfgup,
            [MobjState]::Bfgdown,
            [MobjState]::Bfg,
            [MobjState]::Bfg1,
            [MobjState]::Bfgflash1
        ),

        # Chainsaw
        [WeaponInfo]::new(
            [AmmoType]::NoAmmo,
            [MobjState]::Sawup,
            [MobjState]::Sawdown,
            [MobjState]::Saw,
            [MobjState]::Saw1,
            [MobjState]::Null
        ),

        # Super Shotgun
        [WeaponInfo]::new(
            [AmmoType]::Shell,
            [MobjState]::Dsgunup,
            [MobjState]::Dsgundown,
            [MobjState]::Dsgun,
            [MobjState]::Dsgun1,
            [MobjState]::Dsgunflash1
        )
    )
}