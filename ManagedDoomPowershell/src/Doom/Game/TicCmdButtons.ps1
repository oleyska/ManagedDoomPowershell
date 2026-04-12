class TicCmdButtons {
    static [byte] $Attack = 1

    # Use button, to open doors, activate switches.
    static [byte] $Use = 2

    # Flag: game events, not really buttons.
    static [byte] $Special = 128
    static [byte] $SpecialMask = 3

    # Flag, weapon change pending.
    # If true, the next 3 bits hold weapon num.
    static [byte] $Change = 4

    # The 3-bit weapon mask and shift, convenience.
    static [byte] $WeaponMask = 8 + 16 + 32
    static [byte] $WeaponShift = 3

    # Pause the game.
    static [byte] $Pause = 1
}