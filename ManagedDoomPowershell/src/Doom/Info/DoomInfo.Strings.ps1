
class Strings {
    #    static [hashtable]$Strings = @{}

        [doomstring]$PRESSKEY = [DoomString]::new("PRESSKEY", "press a key.")
        [doomstring]$PRESSYN = [DoomString]::new("PRESSYN", "press y or n.")
        [doomstring]$QUITMSG = [DoomString]::new("QUITMSG", "are you sure you want to`nquit this great game?")
        [doomstring]$LOADNET = [DoomString]::new("LOADNET", "you can't do load while in a net game!`n`n" + [doomstring]$PRESSKEY.Message)
        [doomstring]$QLOADNET = [DoomString]::new("QLOADNET", "you can't quickload during a netgame!`n`n" + [doomstring]$PRESSKEY.Message)
        [doomstring]$QSAVESPOT = [DoomString]::new("QSAVESPOT", "you haven't picked a quicksave slot yet!`n`n" + [doomstring]$PRESSKEY.Message)
        [doomstring]$SAVEDEAD = [DoomString]::new("SAVEDEAD", "you can't save if you aren't playing!`n`n" + [doomstring]$PRESSKEY.Message)
        [doomstring]$QSPROMPT = [DoomString]::new("QSPROMPT", "quicksave over your game named`n`n'%s'`n`n" + [doomstring]$PRESSYN.Message)
        [doomstring]$QLPROMPT = [DoomString]::new("QLPROMPT", "do you want to quickload the game named`n`n'%s'`n`n" + [doomstring]$PRESSYN.Message)
        [doomstring]$NEWGAME = [DoomString]::new("NEWGAME", "you can't start a new game`nwhile in a network game.`n`n" + [doomstring]$PRESSKEY.Message)
        [doomstring]$NIGHTMARE = [DoomString]::new("NIGHTMARE", "are you sure? this skill level`nisn't even remotely fair.`n`n" + [doomstring]$PRESSYN.Message)
        [doomstring]$SWSTRING = [DoomString]::new("SWSTRING", "this is the shareware version of doom.`nyou need to order the entire trilogy.`n`n" + [doomstring]$PRESSYN.Message)
        [doomstring]$MSGOFF = [DoomString]::New("MSGOFF", "Messages OFF")
        [doomstring]$MSGON = [DoomString]::New("MSGON", "Messages ON")
        [doomstring]$NETEND = [DoomString]::New("NETEND", "you can't end a netgame!`n`n" + [doomstring]$PRESSKEY)
        [doomstring]$ENDGAME = [DoomString]::New("ENDGAME", "are you sure you want to end the game?`n`n" + [doomstring]$PRESSYN)
        [doomstring]$DOSY = [DoomString]::New("DOSY", "(press y to quit)")
        [doomstring]$GAMMALVL0 = [DoomString]::New("GAMMALVL0", "Gamma correction OFF")
        [doomstring]$GAMMALVL1 = [DoomString]::New("GAMMALVL1", "Gamma correction level 1")
        [doomstring]$GAMMALVL2 = [DoomString]::New("GAMMALVL2", "Gamma correction level 2")
        [doomstring]$GAMMALVL3 = [DoomString]::New("GAMMALVL3", "Gamma correction level 3")
        [doomstring]$GAMMALVL4 = [DoomString]::New("GAMMALVL4", "Gamma correction level 4")
        [doomstring]$EMPTYSTRING = [DoomString]::New("EMPTYSTRING", "empty slot")
        [doomstring]$GOTARMOR = [DoomString]::New("GOTARMOR", "Picked up the armor.")
        [doomstring]$GOTMEGA = [DoomString]::New("GOTMEGA", "Picked up the MegaArmor!")
        [doomstring]$GOTHTHBONUS = [DoomString]::New("GOTHTHBONUS", "Picked up a health bonus.")
        [doomstring]$GOTARMBONUS = [DoomString]::New("GOTARMBONUS", "Picked up an armor bonus.")
        [doomstring]$GOTSTIM = [DoomString]::New("GOTSTIM", "Picked up a stimpack.")
        [doomstring]$GOTMEDINEED = [DoomString]::New("GOTMEDINEED", "Picked up a medikit that you REALLY need!")
        [doomstring]$GOTMEDIKIT = [DoomString]::New("GOTMEDIKIT", "Picked up a medikit.")
        [doomstring]$GOTSUPER = [DoomString]::New("GOTSUPER", "Supercharge!")
        [doomstring]$GOTBLUECARD = [DoomString]::New("GOTBLUECARD", "Picked up a blue keycard.")
        [doomstring]$GOTYELWCARD = [DoomString]::New("GOTYELWCARD", "Picked up a yellow keycard.")
        [doomstring]$GOTREDCARD = [DoomString]::New("GOTREDCARD", "Picked up a red keycard.")
        [doomstring]$GOTBLUESKUL = [DoomString]::New("GOTBLUESKUL", "Picked up a blue skull key.")
        [doomstring]$GOTYELWSKUL = [DoomString]::New("GOTYELWSKUL", "Picked up a yellow skull key.")
        [doomstring]$GOTREDSKULL = [DoomString]::New("GOTREDSKULL", "Picked up a red skull key.")
        [doomstring]$GOTINVUL = [DoomString]::New("GOTINVUL", "Invulnerability!")
        [doomstring]$GOTBERSERK = [DoomString]::New("GOTBERSERK", "Berserk!")
        [doomstring]$GOTINVIS = [DoomString]::New("GOTINVIS", "Partial Invisibility")
        [doomstring]$GOTSUIT = [DoomString]::New("GOTSUIT", "Radiation Shielding Suit")
        [doomstring]$GOTMAP = [DoomString]::New("GOTMAP", "Computer Area Map")
        [doomstring]$GOTVISOR = [DoomString]::New("GOTVISOR", "Light Amplification Visor")
        [doomstring]$GOTMSPHERE = [DoomString]::New("GOTMSPHERE", "MegaSphere!")
        [doomstring]$GOTCLIP = [DoomString]::New("GOTCLIP", "Picked up a clip.")
        [doomstring]$GOTCLIPBOX = [DoomString]::New("GOTCLIPBOX", "Picked up a box of bullets.")
        [doomstring]$GOTROCKET = [DoomString]::New("GOTROCKET", "Picked up a rocket.")
        [doomstring]$GOTROCKBOX = [DoomString]::New("GOTROCKBOX", "Picked up a box of rockets.")
        [doomstring]$GOTCELL = [DoomString]::New("GOTCELL", "Picked up an energy cell.")
        [doomstring]$GOTCELLBOX = [DoomString]::New("GOTCELLBOX", "Picked up an energy cell pack.")
        [doomstring]$GOTSHELLS = [DoomString]::New("GOTSHELLS", "Picked up 4 shotgun shells.")
        [doomstring]$GOTSHELLBOX = [DoomString]::New("GOTSHELLBOX", "Picked up a box of shotgun shells.")
        [doomstring]$GOTBACKPACK = [DoomString]::New("GOTBACKPACK", "Picked up a backpack full of ammo!")
        [doomstring]$GOTBFG9000 = [DoomString]::New("GOTBFG9000", "You got the BFG9000!  Oh, yes.")
        [doomstring]$GOTCHAINGUN = [DoomString]::New("GOTCHAINGUN", "You got the chaingun!")
        [doomstring]$GOTCHAINSAW = [DoomString]::New("GOTCHAINSAW", "A chainsaw!  Find some meat!")
        [doomstring]$GOTLAUNCHER = [DoomString]::New("GOTLAUNCHER", "You got the rocket launcher!")
        [doomstring]$GOTPLASMA = [DoomString]::New("GOTPLASMA", "You got the plasma gun!")
        [doomstring]$GOTSHOTGUN = [DoomString]::New("GOTSHOTGUN", "You got the shotgun!")
        [doomstring]$GOTSHOTGUN2 = [DoomString]::New("GOTSHOTGUN2", "You got the super shotgun!")
        [doomstring]$PD_BLUEO = [DoomString]::New("PD_BLUEO", "You need a blue key to activate this object")
        [doomstring]$PD_REDO = [DoomString]::New("PD_REDO", "You need a red key to activate this object")
        [doomstring]$PD_YELLOWO = [DoomString]::New("PD_YELLOWO", "You need a yellow key to activate this object")
        [doomstring]$PD_BLUEK = [DoomString]::New("PD_BLUEK", "You need a blue key to open this door")
        [doomstring]$PD_REDK = [DoomString]::New("PD_REDK", "You need a red key to open this door")
        [doomstring]$PD_YELLOWK = [DoomString]::New("PD_YELLOWK", "You need a yellow key to open this door")
        [doomstring]$GGSAVED = [DoomString]::New("GGSAVED", "game saved.")
        [doomstring]$HUSTR_E1M1 = [DoomString]::New("HUSTR_E1M1", "E1M1: Hangar")
        [doomstring]$HUSTR_E1M2 = [DoomString]::New("HUSTR_E1M2", "E1M2: Nuclear Plant")
        [doomstring]$HUSTR_E1M3 = [DoomString]::New("HUSTR_E1M3", "E1M3: Toxin Refinery")
        [doomstring]$HUSTR_E1M4 = [DoomString]::New("HUSTR_E1M4", "E1M4: Command Control")
        [doomstring]$HUSTR_E1M5 = [DoomString]::New("HUSTR_E1M5", "E1M5: Phobos Lab")
        [doomstring]$HUSTR_E1M6 = [DoomString]::New("HUSTR_E1M6", "E1M6: Central Processing")
        [doomstring]$HUSTR_E1M7 = [DoomString]::New("HUSTR_E1M7", "E1M7: Computer Station")
        [doomstring]$HUSTR_E1M8 = [DoomString]::New("HUSTR_E1M8", "E1M8: Phobos Anomaly")
        [doomstring]$HUSTR_E1M9 = [DoomString]::New("HUSTR_E1M9", "E1M9: Military Base")
        [doomstring]$HUSTR_E2M1 = [DoomString]::New("HUSTR_E2M1", "E2M1: Deimos Anomaly")
        [doomstring]$HUSTR_E2M2 = [DoomString]::New("HUSTR_E2M2", "E2M2: Containment Area")
        [doomstring]$HUSTR_E2M3 = [DoomString]::New("HUSTR_E2M3", "E2M3: Refinery")
        [doomstring]$HUSTR_E2M4 = [DoomString]::New("HUSTR_E2M4", "E2M4: Deimos Lab")
        [doomstring]$HUSTR_E2M5 = [DoomString]::New("HUSTR_E2M5", "E2M5: Command Center")
        [doomstring]$HUSTR_E2M6 = [DoomString]::New("HUSTR_E2M6", "E2M6: Halls of the Damned")
        [doomstring]$HUSTR_E2M7 = [DoomString]::New("HUSTR_E2M7", "E2M7: Spawning Vats")
        [doomstring]$HUSTR_E2M8 = [DoomString]::New("HUSTR_E2M8", "E2M8: Tower of Babel")
        [doomstring]$HUSTR_E2M9 = [DoomString]::New("HUSTR_E2M9", "E2M9: Fortress of Mystery")
        [doomstring]$HUSTR_E3M1 = [DoomString]::New("HUSTR_E3M1", "E3M1: Hell Keep")
        [doomstring]$HUSTR_E3M2 = [DoomString]::New("HUSTR_E3M2", "E3M2: Slough of Despair")
        [doomstring]$HUSTR_E3M3 = [DoomString]::New("HUSTR_E3M3", "E3M3: Pandemonium")
        [doomstring]$HUSTR_E3M4 = [DoomString]::New("HUSTR_E3M4", "E3M4: House of Pain")
        [doomstring]$HUSTR_E3M5 = [DoomString]::New("HUSTR_E3M5", "E3M5: Unholy Cathedral")
        [doomstring]$HUSTR_E3M6 = [DoomString]::New("HUSTR_E3M6", "E3M6: Mt. Erebus")
        [doomstring]$HUSTR_E3M7 = [DoomString]::New("HUSTR_E3M7", "E3M7: Limbo")
        [doomstring]$HUSTR_E3M8 = [DoomString]::New("HUSTR_E3M8", "E3M8: Dis")
        [doomstring]$HUSTR_E3M9 = [DoomString]::New("HUSTR_E3M9", "E3M9: Warrens")
        [doomstring]$HUSTR_E4M1 = [DoomString]::New("HUSTR_E4M1", "E4M1: Hell Beneath")
        [doomstring]$HUSTR_E4M2 = [DoomString]::New("HUSTR_E4M2", "E4M2: Perfect Hatred")
        [doomstring]$HUSTR_E4M3 = [DoomString]::New("HUSTR_E4M3", "E4M3: Sever The Wicked")
        [doomstring]$HUSTR_E4M4 = [DoomString]::New("HUSTR_E4M4", "E4M4: Unruly Evil")
        [doomstring]$HUSTR_E4M5 = [DoomString]::New("HUSTR_E4M5", "E4M5: They Will Repent")
        [doomstring]$HUSTR_E4M6 = [DoomString]::New("HUSTR_E4M6", "E4M6: Against Thee Wickedly")
        [doomstring]$HUSTR_E4M7 = [DoomString]::New("HUSTR_E4M7", "E4M7: And Hell Followed")
        [doomstring]$HUSTR_E4M8 = [DoomString]::New("HUSTR_E4M8", "E4M8: Unto The Cruel")
        [doomstring]$HUSTR_E4M9 = [DoomString]::New("HUSTR_E4M9", "E4M9: Fear")
        [doomstring]$HUSTR_1 = [DoomString]::New("HUSTR_1", "level 1: entryway")
        [doomstring]$HUSTR_2 = [DoomString]::New("HUSTR_2", "level 2: underhalls")
        [doomstring]$HUSTR_3 = [DoomString]::New("HUSTR_3", "level 3: the gantlet")
        [doomstring]$HUSTR_4 = [DoomString]::New("HUSTR_4", "level 4: the focus")
        [doomstring]$HUSTR_5 = [DoomString]::New("HUSTR_5", "level 5: the waste tunnels")
        [doomstring]$HUSTR_6 = [DoomString]::New("HUSTR_6", "level 6: the crusher")
        [doomstring]$HUSTR_7 = [DoomString]::New("HUSTR_7", "level 7: dead simple")
        [doomstring]$HUSTR_8 = [DoomString]::New("HUSTR_8", "level 8: tricks and traps")
        [doomstring]$HUSTR_9 = [DoomString]::New("HUSTR_9", "level 9: the pit")
        [doomstring]$HUSTR_10 = [DoomString]::New("HUSTR_10", "level 10: refueling base")
        [doomstring]$HUSTR_11 = [DoomString]::New("HUSTR_11", "level 11: 'o' of destruction!")
        [doomstring]$HUSTR_12 = [DoomString]::New("HUSTR_12", "level 12: the factory")
        [doomstring]$HUSTR_13 = [DoomString]::New("HUSTR_13", "level 13: downtown")
        [doomstring]$HUSTR_14 = [DoomString]::New("HUSTR_14", "level 14: the inmost dens")
        [doomstring]$HUSTR_15 = [DoomString]::New("HUSTR_15", "level 15: industrial zone")
        [doomstring]$HUSTR_16 = [DoomString]::New("HUSTR_16", "level 16: suburbs")
        [doomstring]$HUSTR_17 = [DoomString]::New("HUSTR_17", "level 17: tenements")
        [doomstring]$HUSTR_18 = [DoomString]::New("HUSTR_18", "level 18: the courtyard")
        [doomstring]$HUSTR_19 = [DoomString]::New("HUSTR_19", "level 19: the citadel")
        [doomstring]$HUSTR_20 = [DoomString]::New("HUSTR_20", "level 20: gotcha!")
        [doomstring]$HUSTR_21 = [DoomString]::New("HUSTR_21", "level 21: nirvana")
        [doomstring]$HUSTR_22 = [DoomString]::New("HUSTR_22", "level 22: the catacombs")
        [doomstring]$HUSTR_23 = [DoomString]::New("HUSTR_23", "level 23: barrels o' fun")
        [doomstring]$HUSTR_24 = [DoomString]::New("HUSTR_24", "level 24: the chasm")
        [doomstring]$HUSTR_25 = [DoomString]::New("HUSTR_25", "level 25: bloodfalls")
        [doomstring]$HUSTR_26 = [DoomString]::New("HUSTR_26", "level 26: the abandoned mines")
        [doomstring]$HUSTR_27 = [DoomString]::New("HUSTR_27", "level 27: monster condo")
        [doomstring]$HUSTR_28 = [DoomString]::New("HUSTR_28", "level 28: the spirit world")
        [doomstring]$HUSTR_29 = [DoomString]::New("HUSTR_29", "level 29: the living end")
        [doomstring]$HUSTR_30 = [DoomString]::New("HUSTR_30", "level 30: icon of sin")
        [doomstring]$HUSTR_31 = [DoomString]::New("HUSTR_31", "level 31: wolfenstein")
        [doomstring]$HUSTR_32 = [DoomString]::New("HUSTR_32", "level 32: grosse")
        [doomstring]$PHUSTR_1 = [DoomString]::New("PHUSTR_1", "level 1: congo")
        [doomstring]$PHUSTR_2 = [DoomString]::New("PHUSTR_2", "level 2: well of souls")
        [doomstring]$PHUSTR_3 = [DoomString]::New("PHUSTR_3", "level 3: aztec")
        [doomstring]$PHUSTR_4 = [DoomString]::New("PHUSTR_4", "level 4: caged")
        [doomstring]$PHUSTR_5 = [DoomString]::New("PHUSTR_5", "level 5: ghost town")
        [doomstring]$PHUSTR_6 = [DoomString]::New("PHUSTR_6", "level 6: baron's lair")
        [doomstring]$PHUSTR_7 = [DoomString]::New("PHUSTR_7", "level 7: caughtyard")
        [doomstring]$PHUSTR_8 = [DoomString]::New("PHUSTR_8", "level 8: realm")
        [doomstring]$PHUSTR_9 = [DoomString]::New("PHUSTR_9", "level 9: abattoire")
        [doomstring]$PHUSTR_10 = [DoomString]::New("PHUSTR_10", "level 10: onslaught")
        [doomstring]$PHUSTR_11 = [DoomString]::New("PHUSTR_11", "level 11: hunted")
        [doomstring]$PHUSTR_12 = [DoomString]::New("PHUSTR_12", "level 12: speed")
        [doomstring]$PHUSTR_13 = [DoomString]::New("PHUSTR_13", "level 13: the crypt")
        [doomstring]$PHUSTR_14 = [DoomString]::New("PHUSTR_14", "level 14: genesis")
        [doomstring]$PHUSTR_15 = [DoomString]::New("PHUSTR_15", "level 15: the twilight")
        [doomstring]$PHUSTR_16 = [DoomString]::New("PHUSTR_16", "level 16: the omen")
        [doomstring]$PHUSTR_17 = [DoomString]::New("PHUSTR_17", "level 17: compound")
        [doomstring]$PHUSTR_18 = [DoomString]::New("PHUSTR_18", "level 18: neurosphere")
        [doomstring]$PHUSTR_19 = [DoomString]::New("PHUSTR_19", "level 19: nme")
        [doomstring]$PHUSTR_20 = [DoomString]::New("PHUSTR_20", "level 20: the death domain")
        [doomstring]$PHUSTR_21 = [DoomString]::New("PHUSTR_21", "level 21: slayer")
        [doomstring]$PHUSTR_22 = [DoomString]::New("PHUSTR_22", "level 22: impossible mission")
        [doomstring]$PHUSTR_23 = [DoomString]::New("PHUSTR_23", "level 23: tombstone")
        [doomstring]$PHUSTR_24 = [DoomString]::New("PHUSTR_24", "level 24: the final frontier")
        [doomstring]$PHUSTR_25 = [DoomString]::New("PHUSTR_25", "level 25: the temple of darkness")
        [doomstring]$PHUSTR_26 = [DoomString]::New("PHUSTR_26", "level 26: bunker")
        [doomstring]$PHUSTR_27 = [DoomString]::New("PHUSTR_27", "level 27: anti-christ")
        [doomstring]$PHUSTR_28 = [DoomString]::New("PHUSTR_28", "level 28: the sewers")
        [doomstring]$PHUSTR_29 = [DoomString]::New("PHUSTR_29", "level 29: odyssey of noises")
        [doomstring]$PHUSTR_30 = [DoomString]::New("PHUSTR_30", "level 30: the gateway of hell")
        [doomstring]$PHUSTR_31 = [DoomString]::New("PHUSTR_31", "level 31: cyberden")
        [doomstring]$PHUSTR_32 = [DoomString]::New("PHUSTR_32", "level 32: go 2 it")
        [doomstring]$THUSTR_1 = [DoomString]::New("THUSTR_1", "level 1: system control")
        [doomstring]$THUSTR_2 = [DoomString]::New("THUSTR_2", "level 2: human bbq")
        [doomstring]$THUSTR_3 = [DoomString]::New("THUSTR_3", "level 3: power control")
        [doomstring]$THUSTR_4 = [DoomString]::New("THUSTR_4", "level 4: wormhole")
        [doomstring]$THUSTR_5 = [DoomString]::New("THUSTR_5", "level 5: hanger")
        [doomstring]$THUSTR_6 = [DoomString]::New("THUSTR_6", "level 6: open season")
        [doomstring]$THUSTR_7 = [DoomString]::New("THUSTR_7", "level 7: prison")
        [doomstring]$THUSTR_8 = [DoomString]::New("THUSTR_8", "level 8: metal")
        [doomstring]$THUSTR_9 = [DoomString]::New("THUSTR_9", "level 9: stronghold")
        [doomstring]$THUSTR_10 = [DoomString]::New("THUSTR_10", "level 10: redemption")
        [doomstring]$THUSTR_11 = [DoomString]::New("THUSTR_11", "level 11: storage facility")
        [doomstring]$THUSTR_12 = [DoomString]::New("THUSTR_12", "level 12: crater")
        [doomstring]$THUSTR_13 = [DoomString]::New("THUSTR_13", "level 13: nukage processing")
        [doomstring]$THUSTR_14 = [DoomString]::New("THUSTR_14", "level 14: steel works")
        [doomstring]$THUSTR_15 = [DoomString]::New("THUSTR_15", "level 15: dead zone")
        [doomstring]$THUSTR_16 = [DoomString]::New("THUSTR_16", "level 16: deepest reaches")
        [doomstring]$THUSTR_17 = [DoomString]::New("THUSTR_17", "level 17: processing area")
        [doomstring]$THUSTR_18 = [DoomString]::New("THUSTR_18", "level 18: mill")
        [doomstring]$THUSTR_19 = [DoomString]::New("THUSTR_19", "level 19: shipping/respawning")
        [doomstring]$THUSTR_20 = [DoomString]::New("THUSTR_20", "level 20: central processing")
        [doomstring]$THUSTR_21 = [DoomString]::New("THUSTR_21", "level 21: administration center")
        [doomstring]$THUSTR_22 = [DoomString]::New("THUSTR_22", "level 22: habitat")
        [doomstring]$THUSTR_23 = [DoomString]::New("THUSTR_23", "level 23: lunar mining project")
        [doomstring]$THUSTR_24 = [DoomString]::New("THUSTR_24", "level 24: quarry")
        [doomstring]$THUSTR_25 = [DoomString]::New("THUSTR_25", "level 25: baron's den")
        [doomstring]$THUSTR_26 = [DoomString]::New("THUSTR_26", "level 26: ballistyx")
        [doomstring]$THUSTR_27 = [DoomString]::New("THUSTR_27", "level 27: mount pain")
        [doomstring]$THUSTR_28 = [DoomString]::New("THUSTR_28", "level 28: heck")
        [doomstring]$THUSTR_29 = [DoomString]::New("THUSTR_29", "level 29: river styx")
        [doomstring]$THUSTR_30 = [DoomString]::New("THUSTR_30", "level 30: last call")
        [doomstring]$THUSTR_31 = [DoomString]::New("THUSTR_31", "level 31: pharaoh")
        [doomstring]$THUSTR_32 = [DoomString]::New("THUSTR_32", "level 32: caribbean")
        [doomstring]$AMSTR_FOLLOWON = [DoomString]::New("AMSTR_FOLLOWON", "Follow Mode ON")
        [doomstring]$AMSTR_FOLLOWOFF = [DoomString]::New("AMSTR_FOLLOWOFF", "Follow Mode OFF")
        [doomstring]$AMSTR_GRIDON = [DoomString]::New("AMSTR_GRIDON", "Grid ON")
        [doomstring]$AMSTR_GRIDOFF = [DoomString]::New("AMSTR_GRIDOFF", "Grid OFF")
        [doomstring]$AMSTR_MARKEDSPOT = [DoomString]::New("AMSTR_MARKEDSPOT", "Marked Spot")
        [doomstring]$AMSTR_MARKSCLEARED = [DoomString]::New("AMSTR_MARKSCLEARED", "All Marks Cleared")
        [doomstring]$STSTR_MUS = [DoomString]::New("STSTR_MUS", "Music Change")
        [doomstring]$STSTR_NOMUS = [DoomString]::New("STSTR_NOMUS", "IMPOSSIBLE SELECTION")
        [doomstring]$STSTR_DQDON = [DoomString]::New("STSTR_DQDON", "Degreelessness Mode On")
        [doomstring]$STSTR_DQDOFF = [DoomString]::New("STSTR_DQDOFF", "Degreelessness Mode Off")
        [doomstring]$STSTR_KFAADDED = [DoomString]::New("STSTR_KFAADDED", "Very Happy Ammo Added")
        [doomstring]$STSTR_FAADDED = [DoomString]::New("STSTR_FAADDED", "Ammo (no keys) Added")
        [doomstring]$STSTR_NCON = [DoomString]::New("STSTR_NCON", "No Clipping Mode ON")
        [doomstring]$STSTR_NCOFF = [DoomString]::New("STSTR_NCOFF", "No Clipping Mode OFF")
        [doomstring]$STSTR_BEHOLD = [DoomString]::New("STSTR_BEHOLD", "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp")
        [doomstring]$STSTR_BEHOLDX = [DoomString]::New("STSTR_BEHOLDX", "Power-up Toggled")
        [doomstring]$STSTR_CHOPPERS = [DoomString]::New("STSTR_CHOPPERS", "... doesn't suck - GM")
        [doomstring]$STSTR_CLEV = [DoomString]::New("STSTR_CLEV", "Changing Level...")
                
        [doomstring]$E1TEXT = [DoomString]::new("E1TEXT",@"
        Once you beat the big badasses and 
        clean out the moon base you're supposed 
        to win, aren't you? Aren't you? Where's 
        your fat reward and ticket home? What 
        the hell is this? It's not supposed to 
        end this way! 
         
        It stinks like rotten meat, but looks 
        like the lost Deimos base.  Looks like 
        you're stuck on The Shores of Hell. 
        The only way out is through. 
         
        To continue the DOOM experience, play 
        The Shores of Hell and its amazing 
        sequel, Inferno!
"@)

    [doomstring]$E2TEXT = [DoomString]::new("E2TEXT",@"
        You've done it! The hideous cyber- 
        demon lord that ruled the lost Deimos 
        moon base has been slain and you 
        are triumphant! But ... where are 
        you? You clamber to the edge of the 
        moon and look down to see the awful 
        truth. 
         
        Deimos floats above Hell itself! 
        You've never heard of anyone escaping 
        from Hell, but you'll make the bastards 
        sorry they ever heard of you! Quickly, 
        you rappel down to  the surface of 
        Hell. 
         
        Now, it's on to the final chapter of 
        DOOM! -- Inferno.
"@)

    [doomstring]$E3TEXT = [DoomString]::new("E3TEXT",@"
        The loathsome spiderdemon that 
        masterminded the invasion of the moon 
        bases and caused so much death has had 
        its ass kicked for all time. 
         
        A hidden doorway opens and you enter. 
        You've proven too tough for Hell to 
        contain, and now Hell at last plays 
        fair -- for you emerge from the door 
        to see the green fields of Earth! 
        Home at last. 
         
        You wonder what's been happening on 
        Earth while you were battling evil 
        unleashed. It's good that no Hell- 
        spawn could have come through that 
        door with you ...
"@)

    [doomstring]$E4TEXT = [DoomString]::new("E4TEXT",@"
        the spider mastermind must have sent forth 
        its legions of hellspawn before your 
        final confrontation with that terrible 
        beast from hell.  but you stepped forward 
        and brought forth eternal damnation and 
        suffering upon the horde as a true hero 
        would in the face of something so evil. 
         
        besides, someone was gonna pay for what 
        happened to daisy, your pet rabbit. 
         
        but now, you see spread before you more 
        potential pain and gibbitude as a nation 
        of demons run amok among our cities. 
         
        next stop, hell on earth!
"@)

    [doomstring]$C1TEXT = [DoomString]::new("C1TEXT",@"
        YOU HAVE ENTERED DEEPLY INTO THE INFESTED 
        STARPORT. BUT SOMETHING IS WRONG. THE 
        MONSTERS HAVE BROUGHT THEIR OWN REALITY 
        WITH THEM, AND THE STARPORT'S TECHNOLOGY 
        IS BEING SUBVERTED BY THEIR PRESENCE. 
         
        AHEAD, YOU SEE AN OUTPOST OF HELL, A 
        FORTIFIED ZONE. IF YOU CAN GET PAST IT, 
        YOU CAN PENETRATE INTO THE HAUNTED HEART 
        OF THE STARBASE AND FIND THE CONTROLLING 
        SWITCH WHICH HOLDS EARTH'S POPULATION 
        HOSTAGE.
"@)

    [doomstring]$C2TEXT = [DoomString]::new("C2TEXT",@"
        YOU HAVE WON! YOUR VICTORY HAS ENABLED 
        HUMANKIND TO EVACUATE EARTH AND ESCAPE 
        THE NIGHTMARE.  NOW YOU ARE THE ONLY 
        HUMAN LEFT ON THE FACE OF THE PLANET. 
        CANNIBAL MUTATIONS, CARNIVOROUS ALIENS, 
        AND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS. 
        YOU SIT BACK AND WAIT FOR DEATH, CONTENT 
        THAT YOU HAVE SAVED YOUR SPECIES. 
         
        BUT THEN, EARTH CONTROL BEAMS DOWN A 
        MESSAGE FROM SPACE: \SENSORS HAVE LOCATED 
        THE SOURCE OF THE ALIEN INVASION. IF YOU 
        GO THERE, YOU MAY BE ABLE TO BLOCK THEIR 
        ENTRY.  THE ALIEN BASE IS IN THE HEART OF 
        YOUR OWN HOME CITY, NOT FAR FROM THE 
        STARPORT.\ SLOWLY AND PAINFULLY YOU GET 
        UP AND RETURN TO THE FRAY.
"@)

    [doomstring]$C3TEXT = [DoomString]::new("C3TEXT",@"
        YOU ARE AT THE CORRUPT HEART OF THE CITY, 
        SURROUNDED BY THE CORPSES OF YOUR ENEMIES. 
        YOU SEE NO WAY TO DESTROY THE CREATURES' 
        ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR 
        TEETH AND PLUNGE THROUGH IT. 
         
        THERE MUST BE A WAY TO CLOSE IT ON THE 
        OTHER SIDE. WHAT DO YOU CARE IF YOU'VE 
        GOT TO GO THROUGH HELL TO GET TO IT?
"@)

    [doomstring]$C4TEXT = [DoomString]::new("C4TEXT",@"
        THE HORRENDOUS VISAGE OF THE BIGGEST 
        DEMON YOU'VE EVER SEEN CRUMBLES BEFORE 
        YOU, AFTER YOU PUMP YOUR ROCKETS INTO 
        HIS EXPOSED BRAIN. THE MONSTER SHRIVELS 
        UP AND DIES, ITS THRASHING LIMBS 
        DEVASTATING UNTOLD MILES OF HELL'S 
        SURFACE. 
         
        YOU'VE DONE IT. THE INVASION IS OVER. 
        EARTH IS SAVED. HELL IS A WRECK. YOU 
        WONDER WHERE BAD FOLKS WILL GO WHEN THEY 
        DIE, NOW. WIPING THE SWEAT FROM YOUR 
        FOREHEAD YOU BEGIN THE LONG TREK BACK 
        HOME. REBUILDING EARTH OUGHT TO BE A 
        LOT MORE FUN THAN RUINING IT WAS.
"@)

    [doomstring]$C5TEXT = [DoomString]::new("C5TEXT",@"

        CONGRATULATIONS, YOU'VE FOUND THE SECRET 
        LEVEL! LOOKS LIKE IT'S BEEN BUILT BY 
        HUMANS, RATHER THAN DEMONS. YOU WONDER 
        WHO THE INMATES OF THIS CORNER OF HELL 
        WILL BE.
"@)

    [doomstring]$C6TEXT = [DoomString]::new("C6TEXT",@"

        CONGRATULATIONS, YOU'VE FOUND THE 
        SUPER SECRET LEVEL!  YOU'D BETTER 
        BLAZE THROUGH THIS ONE!
"@)

    [doomstring]$P1TEXT = [DoomString]::new("P1TEXT",@"
        You gloat over the steaming carcass of the 
        Guardian.  With its death, you've wrested 
        the Accelerator from the stinking claws 
        of Hell.  You relax and glance around the 
        room.  Damn!  There was supposed to be at 
        least one working prototype, but you can't 
        see it. The demons must have taken it. 
         
        You must find the prototype, or all your 
        struggles will have been wasted. Keep 
        moving, keep fighting, keep killing. 
        Oh yes, keep living, too.
"@)

    [doomstring]$P2TEXT = [DoomString]::new("P2TEXT",@"
        Even the deadly Arch-Vile labyrinth could 
        not stop you, and you've gotten to the 
        prototype Accelerator which is soon 
        efficiently and permanently deactivated. 
         
        You're good at that kind of thing.
"@)

    [doomstring]$P3TEXT = [DoomString]::new("P3TEXT",@"
        You've bashed and battered your way into 
        the heart of the devil-hive.  Time for a 
        Search-and-Destroy mission, aimed at the 
        Gatekeeper, whose foul offspring is 
        cascading to Earth.  Yeah, he's bad. But 
        you know who's worse! 
         
        Grinning evilly, you check your gear, and 
        get ready to give the bastard a little Hell 
        of your own making!
"@)

    [doomstring]$P4TEXT = [DoomString]::new("P4TEXT", @"
        The Gatekeeper's evil face is splattered 
        all over the place.  As its tattered corpse 
        collapses, an inverted Gate forms and 
        sucks down the shards of the last 
        prototype Accelerator, not to mention the 
        few remaining demons.  You're done. Hell 
        has gone back to pounding bad dead folks  
        instead of good live ones.  Remember to 
        tell your grandkids to put a rocket 
        launcher in your coffin. If you go to Hell 
        when you die, you'll need it for some 
        final cleaning-up ...
"@)

    [doomstring]$P5TEXT = [DoomString]::new("P5TEXT",@"
        You've found the second-hardest level we 
        got. Hope you have a saved game a level or 
        two previous.  If not, be prepared to die 
        aplenty. For master marines only.
"@)

    [doomstring]$P6TEXT = [DoomString]::new("P6TEXT",@"
        Betcha wondered just what WAS the hardest 
        level we had ready for ya?  Now you know. 
        No one gets out alive.
"@)

    [doomstring]$T1TEXT = [DoomString]::new("T1TEXT",@"
        You've fought your way out of the infested 
        experimental labs.   It seems that UAC has 
        once again gulped it down.  With their 
        high turnover, it must be hard for poor 
        old UAC to buy corporate health insurance 
        nowadays.. 
         
        Ahead lies the military complex, now 
        swarming with diseased horrors hot to get 
        their teeth into you. With luck, the 
        complex still has some warlike ordnance 
        laying around.
"@)

    [doomstring]$T2TEXT = [DoomString]::new("T2TEXT", @"
        You hear the grinding of heavy machinery 
        ahead.  You sure hope they're not stamping 
        out new hellspawn, but you're ready to 
        ream out a whole herd if you have to. 
        They might be planning a blood feast, but 
        you feel about as mean as two thousand 
        maniacs packed into one mad killer. 
         
        You don't plan to go down easy.
"@)

    [doomstring]$T3TEXT = [DoomString]::new("T3TEXT", @"
        The vista opening ahead looks real damn 
        familiar. Smells familiar, too -- like 
        fried excrement. You didn't like this 
        place before, and you sure as hell ain't 
        planning to like it now. The more you 
        brood on it, the madder you get. 
        Hefting your gun, an evil grin trickles 
        onto your face. Time to take some names.
"@)

    [doomstring]$T4TEXT = [DoomString]::new("T4TEXT",@"
        Suddenly, all is silent, from one horizon 
        to the other. The agonizing echo of Hell 
        fades away, the nightmare sky turns to 
        blue, the heaps of monster corpses start  
        to evaporate along with the evil stench  
        that filled the air. Jeeze, maybe you've 
        done it. Have you really won? 
         
        Something rumbles in the distance. 
        A blue light begins to glow inside the 
        ruined skull of the demon-spitter.
"@)

    [doomstring]$T5TEXT = [DoomString]::new("T5TEXT",@"
        What now? Looks totally different. Kind 
        of like King Tut's condo. Well, 
        whatever's here can't be any worse 
        than usual. Can it?  Or maybe it's best 
        to let sleeping gods lie..
"@)

    [doomstring]$T6TEXT = [DoomString]::new("T6TEXT",@"
        Time for a vacation. You've burst the 
        bowels of hell and by golly you're ready 
        for a break. You mutter to yourself, 
        Maybe someone else can kick Hell's ass 
        next time around. Ahead lies a quiet town, 
        with peaceful flowing water, quaint 
        buildings, and presumably no Hellspawn. 
         
        As you step off the transport, you hear 
        the stomp of a cyberdemon's iron shoe.
"@)

        [doomstring]$CC_ZOMBIE = [DoomString]::New("CC_ZOMBIE", "ZOMBIEMAN")
        [doomstring]$CC_SHOTGUN = [DoomString]::New("CC_SHOTGUN", "SHOTGUN GUY")
        [doomstring]$CC_HEAVY = [DoomString]::New("CC_HEAVY", "HEAVY WEAPON DUDE")
        [doomstring]$CC_IMP = [DoomString]::New("CC_IMP", "IMP")
        [doomstring]$CC_DEMON = [DoomString]::New("CC_DEMON", "DEMON")
        [doomstring]$CC_LOST = [DoomString]::New("CC_LOST", "LOST SOUL")
        [doomstring]$CC_CACO = [DoomString]::New("CC_CACO", "CACODEMON")
        [doomstring]$CC_HELL = [DoomString]::New("CC_HELL", "HELL KNIGHT")
        [doomstring]$CC_BARON = [DoomString]::New("CC_BARON", "BARON OF HELL")
        [doomstring]$CC_ARACH = [DoomString]::New("CC_ARACH", "ARACHNOTRON")
        [doomstring]$CC_PAIN = [DoomString]::New("CC_PAIN", "PAIN ELEMENTAL")
        [doomstring]$CC_REVEN = [DoomString]::New("CC_REVEN", "REVENANT")
        [doomstring]$CC_MANCU = [DoomString]::New("CC_MANCU", "MANCUBUS")
        [doomstring]$CC_ARCH = [DoomString]::New("CC_ARCH", "ARCH-VILE")
        [doomstring]$CC_SPIDER = [DoomString]::New("CC_SPIDER", "THE SPIDER MASTERMIND")
        [doomstring]$CC_CYBER = [DoomString]::New("CC_CYBER", "THE CYBERDEMON")
        [doomstring]$CC_HERO = [DoomString]::New("CC_HERO", "OUR HERO")
    
    }