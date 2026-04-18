##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##

class QuitMessages {
    [DoomString[]] $Doom = @(
        [DoomString]::new("please don't leave, there's more`ndemons to toast!"),
        [DoomString]::new("let's beat it -- this is turning`ninto a bloodbath!"),
        [DoomString]::new("i wouldn't leave if i were you.`nDOS is much worse."),
        [DoomString]::new("you're trying to say you like DOS`nbetter than me, right?"),
        [DoomString]::new("don't leave yet -- there's a`ndemon around that corner!"),
        [DoomString]::new("ya know, next time you come in here`ni'm gonna toast ya."),
        [DoomString]::new("go ahead and leave. see if i care.")
    )

    [DoomString[]] $Doom2 = @(
        [DoomString]::new("you want to quit?`nthen, thou hast lost an eighth!"),
        [DoomString]::new("don't go now, there's a `ndimensional shambler waiting`nat the DOS prompt!"),
        [DoomString]::new("get outta here and go back`nto your boring programs."),
        [DoomString]::new("if i were your boss, i'd `n deathmatch ya in a minute!"),
        [DoomString]::new("look, bud. you leave now`nand you forfeit your body count!"),
        [DoomString]::new("just leave. when you come`nback, i'll be waiting with a bat."),
        [DoomString]::new("you're lucky i don't smack`nyou for thinking about leaving.")
    )

    [DoomString[]] $FinalDoom = @(
        [DoomString]::new("fuck you, pussy!`nget the fuck out!"),
        [DoomString]::new("you quit and i'll jizz`nin your cystholes!"),
        [DoomString]::new("if you leave, i'll make`nthe lord drink my jizz."),
        [DoomString]::new("hey, ron! can we say`n'fuck' in the game?"),
        [DoomString]::new("i'd leave: this is just`nmore monsters and levels.`nwhat a load."),
        [DoomString]::new("suck it down, asshole!`nyou're a fucking wimp!"),
        [DoomString]::new("don't quit now! we're `nstill spending your money!")
    )
}