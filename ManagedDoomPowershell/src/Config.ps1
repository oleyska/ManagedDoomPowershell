class Config {
    [KeyBinding]$key_forward
    [KeyBinding]$key_backward
    [KeyBinding]$key_strafeleft
    [KeyBinding]$key_straferight
    [KeyBinding]$key_turnleft
    [KeyBinding]$key_turnright
    [KeyBinding]$key_fire
    [KeyBinding]$key_use
    [KeyBinding]$key_run
    [KeyBinding]$key_strafe

    [int]$mouse_sensitivity
    [bool]$mouse_disableyaxis
    [bool]$game_alwaysrun

    [int]$video_screenwidth
    [int]$video_screenheight
    [bool]$video_fullscreen
    [bool]$video_highresolution
    [bool]$video_displaymessage
    [int]$video_gamescreensize
    [int]$video_gammacorrection
    [int]$video_fpsscale

    [int]$audio_soundvolume
    [int]$audio_musicvolume
    [bool]$audio_randompitch
    [string]$audio_soundfont
    [bool]$audio_musiceffect

    [bool]$isRestoredFromFile
    #defaults
    [void] InitializeDefaults() {
        $this.key_forward = [KeyBinding]::new(@('Up', 'W'))
        $this.key_backward = [KeyBinding]::new(@('Down', 'S'))
        $this.key_strafeleft = [KeyBinding]::new(@('A'))
        $this.key_straferight = [KeyBinding]::new(@('D'))
        $this.key_turnleft = [KeyBinding]::new(@('Left'))
        $this.key_turnright = [KeyBinding]::new(@('Right'))
        $this.key_fire = [KeyBinding]::new(@('LControl', 'RControl'), @('Mouse1'))
        $this.key_use = [KeyBinding]::new(@('Space'), @('Mouse2'))
        $this.key_run = [KeyBinding]::new(@('LShift', 'RShift'))
        $this.key_strafe = [KeyBinding]::new(@('LAlt', 'RAlt'))

        $this.mouse_sensitivity = 8
        $this.mouse_disableyaxis = $false
        $this.game_alwaysrun = $true

        $this.video_screenwidth = 640
        $this.video_screenheight = 400
        $this.video_fullscreen = $false
        $this.video_highresolution = $false
        $this.video_gamescreensize = 7
        $this.video_displaymessage = $true
        $this.video_gammacorrection = 2
        $this.video_fpsscale = 1

        $this.audio_soundvolume = 8
        $this.audio_musicvolume = 8
        $this.audio_randompitch = $true
        $this.audio_soundfont = 'TimGM6mb.sf2'
        $this.audio_musiceffect = $true

        $this.isRestoredFromFile = $false
    }

    Config([string] $path) {
        $this.InitializeDefaults()
        try {
            [Console]::Write("Restore settings: ")

            $dic = @{}
            Get-Content $path | ForEach-Object {
                $split = $_ -split '=', 2
                if ($split.Count -eq 2) {
                    $dic[$split[0].Trim()] = $split[1].Trim()
                }
            }

            $this.key_forward = $this.GetKeyBinding($dic, "key_forward", $this.key_forward)
            $this.key_backward = $this.GetKeyBinding($dic, "key_backward", $this.key_backward)
            $this.key_strafeleft = $this.GetKeyBinding($dic, "key_strafeleft", $this.key_strafeleft)
            $this.key_straferight = $this.GetKeyBinding($dic, "key_straferight", $this.key_straferight)
            $this.key_turnleft = $this.GetKeyBinding($dic, "key_turnleft", $this.key_turnleft)
            $this.key_turnright = $this.GetKeyBinding($dic, "key_turnright", $this.key_turnright)
            $this.key_fire = $this.GetKeyBinding($dic, "key_fire", $this.key_fire)
            $this.key_use = $this.GetKeyBinding($dic, "key_use", $this.key_use)
            $this.key_run = $this.GetKeyBinding($dic, "key_run", $this.key_run)
            $this.key_strafe = $this.GetKeyBinding($dic, "key_strafe", $this.key_strafe)

            $this.mouse_sensitivity = $this.GetInt($dic, "mouse_sensitivity", $this.mouse_sensitivity)
            $this.mouse_disableyaxis = $this.GetBool($dic, "mouse_disableyaxis", $this.mouse_disableyaxis)

            $this.game_alwaysrun = $this.GetBool($dic, "game_alwaysrun", $this.game_alwaysrun)

            $this.video_screenwidth = $this.GetInt($dic, "video_screenwidth", $this.video_screenwidth)
            $this.video_screenheight = $this.GetInt($dic, "video_screenheight", $this.video_screenheight)
            $this.video_fullscreen = $this.GetBool($dic, "video_fullscreen", $this.video_fullscreen)
            $this.video_highresolution = $this.GetBool($dic, "video_highresolution", $this.video_highresolution)
            $this.video_displaymessage = $this.GetBool($dic, "video_displaymessage", $this.video_displaymessage)
            $this.video_gamescreensize = $this.GetInt($dic, "video_gamescreensize", $this.video_gamescreensize)
            $this.video_gammacorrection = $this.GetInt($dic, "video_gammacorrection", $this.video_gammacorrection)
            $this.video_fpsscale = $this.GetInt($dic, "video_fpsscale", $this.video_fpsscale)

            $this.audio_soundvolume = $this.GetInt($dic, "audio_soundvolume", $this.audio_soundvolume)
            $this.audio_musicvolume = $this.GetInt($dic, "audio_musicvolume", $this.audio_musicvolume)
            $this.audio_randompitch = $this.GetBool($dic, "audio_randompitch", $this.audio_randompitch)
            $this.audio_soundfont = $this.GetString($dic, "audio_soundfont", $this.audio_soundfont)
            $this.audio_musiceffect = $this.GetBool($dic, "audio_musiceffect", $this.audio_musiceffect)

            $this.isRestoredFromFile = $true

            [Console]::WriteLine("OK")
        }
        catch {
            [Console]::WriteLine("Failed")
        }
    }

    [void] Save([string]$path) {
        try {
            $out = @()
            $out += "$($this.key_forward) = $($this.key_forward)"
            $out += "$($this.key_backward) = $($this.key_backward)"
            $out += "$($this.key_strafeleft) = $($this.key_strafeleft)"
            $out += "$($this.key_straferight) = $($this.key_straferight)"
            $out += "$($this.key_turnleft) = $($this.key_turnleft)"
            $out += "$($this.key_turnright) = $($this.key_turnright)"
            $out += "$($this.key_fire) = $($this.key_fire)"
            $out += "$($this.key_use) = $($this.key_use)"
            $out += "$($this.key_run) = $($this.key_run)"
            $out += "$($this.key_strafe) = $($this.key_strafe)"
            $out += "mouse_sensitivity = $($this.mouse_sensitivity)"
            $out += "mouse_disableyaxis = $($this.BoolToString($this.mouse_disableyaxis))"
            $out += "game_alwaysrun = $($this.BoolToString($this.game_alwaysrun))"
            $out += "video_screenwidth = $($this.video_screenwidth)"
            $out += "video_screenheight = $($this.video_screenheight)"
            $out += "video_fullscreen = $($this.BoolToString($this.video_fullscreen))"
            $out += "video_highresolution = $($this.BoolToString($this.video_highresolution))"
            $out += "video_displaymessage = $($this.BoolToString($this.video_displaymessage))"
            $out += "video_gamescreensize = $($this.video_gamescreensize)"
            $out += "video_gammacorrection = $($this.video_gammacorrection)"
            $out += "video_fpsscale = $($this.video_fpsscale)"
            $out += "audio_soundvolume = $($this.audio_soundvolume)"
            $out += "audio_musicvolume = $($this.audio_musicvolume)"
            $out += "audio_randompitch = $($this.BoolToString($this.audio_randompitch))"
            $out += "audio_soundfont = $($this.audio_soundfont)"
            $out += "audio_musiceffect = $($this.BoolToString($this.audio_musiceffect))"
            Set-Content -Path $path -Value $out
        }
        catch {}
    }

    [int] GetInt([Hashtable]$dic, [string]$name, [int]$defaultValue) {
        if ($dic.ContainsKey($name)) {
            return [int]$dic[$name]
        }
        return $defaultValue
    }

    [bool] GetBool([Hashtable]$dic, [string]$name, [bool]$defaultValue) {
        if ($dic.ContainsKey($name)) {
            return $dic[$name] -eq "true"
        }
        return $defaultValue
    }

    [string] GetString([Hashtable]$dic, [string]$name, [string]$defaultValue) {
        if ($dic.ContainsKey($name)) {
            return $dic[$name]
        }
        return $defaultValue
    }

    [KeyBinding] GetKeyBinding([Hashtable]$dic, [string]$name, [KeyBinding]$defaultValue) {
        if ($dic.ContainsKey($name)) {
            return [KeyBinding]::Parse($dic[$name])
        }
        return $defaultValue
    }

    [string] BoolToString([bool]$value) {
        return $(if ($value) { "true" } else { "false" })
    }

}
