class Arg {
    [bool] $Present = $false

    Arg() { }

    Arg([bool] $present) {
        $this.Present = $present
    }
}

# PowerShell doesn't support generics, so create specific versions
class ArgString {
    [bool] $Present = $false
    [string] $Value

    ArgString() { }

    ArgString([string] $value) {
        $this.Present = $true
        $this.Value = $value
    }
}

class ArgStringArray {
    [bool] $Present = $false
    [string[]] $Value = @()

    ArgStringArray() { }

    ArgStringArray([string[]] $value) {
        $this.Present = $true
        $this.Value = $value
    }
}

class ArgInt {
    [bool] $Present = $false
    [int] $Value = 0

    ArgInt() { }

    ArgInt([int] $value) {
        $this.Present = $true
        $this.Value = $value
    }
}

class ArgTuple {
    [bool] $Present = $false
    [int] $Episode
    [int] $Map

    ArgTuple() { }

    ArgTuple([int] $episode, [int] $map) {
        $this.Present = $true
        $this.Episode = $episode
        $this.Map = $map
    }
}

class CommandLineArgs {
    [ArgString] $iwad
    [ArgStringArray] $file
    [ArgStringArray] $deh
    
    [ArgTuple] $warp
    [ArgInt] $episode
    [ArgInt] $skill

    [Arg] $deathmatch
    [Arg] $altdeath
    [Arg] $fast
    [Arg] $respawn
    [Arg] $nomonsters
    [Arg] $solonet

    [ArgString] $playdemo
    [ArgString] $timedemo
    
    [ArgInt] $loadgame

    [Arg] $nomouse
    [Arg] $nosound
    [Arg] $nosfx
    [Arg] $nomusic

    [Arg] $nodeh

    CommandLineArgs([string[]] $args) {
        $this.iwad = [CommandLineArgs]::GetString($args, "-iwad")
        $this.file = [CommandLineArgs]::Check_file($args) 
        $this.deh = [CommandLineArgs]::Check_deh($args)

        $this.warp = [CommandLineArgs]::Check_warp($args)
        $this.episode = [CommandLineArgs]::GetInt($args, "-episode")
        $this.skill = [CommandLineArgs]::GetInt($args, "-skill")

        # Handle switches (flags) properly
        $this.deathmatch = [Arg]::new($args -contains "-deathmatch")
        $this.altdeath = [Arg]::new($args -contains "-altdeath")
        $this.fast = [Arg]::new($args -contains "-fast")
        $this.respawn = [Arg]::new($args -contains "-respawn")
        $this.nomonsters = [Arg]::new($args -contains "-nomonsters")
        $this.solonet = [Arg]::new($args -contains "-solo-net")

        $this.playdemo = [CommandLineArgs]::GetString($args, "-playdemo")
        $this.timedemo = [CommandLineArgs]::GetString($args, "-timedemo")

        $this.loadgame = [CommandLineArgs]::GetInt($args, "-loadgame")

        $this.nomouse = [Arg]::new($args -contains "-nomouse")
        $this.nosound = [Arg]::new($args -contains "-nosound")
        $this.nosfx = [Arg]::new($args -contains "-nosfx")
        $this.nomusic = [Arg]::new($args -contains "-nomusic")

        $this.nodeh = [Arg]::new($args -contains "-nodeh")
    }

    static [ArgStringArray] Check_file([string[]] $args) {
        $values = [CommandLineArgs]::GetValues($args, "-file")
        if ($values.Count -ge 1) {
            return [ArgStringArray]::new($values)
        }
        return [ArgStringArray]::new()
    }

    static [ArgStringArray] Check_deh([string[]] $args) {
        $values = [CommandLineArgs]::GetValues($args, "-deh")
        if ($values.Count -ge 1) {
            return [ArgStringArray]::new($values)
        }
        return [ArgStringArray]::new()
    }

    static [ArgTuple] Check_warp([string[]] $args) {
        $values = [CommandLineArgs]::GetValues($args, "-warp")
    
        if ($values.Count -eq 1) {
            $localMap = 0
            if ([int]::TryParse($values[0], [ref]$localMap)) {
                return [ArgTuple]::new(1, $localMap)
            }
        } elseif ($values.Count -eq 2) {
            $localEpisode = 0
            $localMap = 0
            if ([int]::TryParse($values[0], [ref]$localEpisode) -and [int]::TryParse($values[1], [ref]$localMap)) {
                return [ArgTuple]::new($localEpisode, $localMap)
            }
        }
    
        return [ArgTuple]::new()
    }
    

    static [ArgString] GetString([string[]] $args, [string] $name) {
        $values = [CommandLineArgs]::GetValues($args, $name)
        if ($values.Count -eq 1) {
            return [ArgString]::new($values[0])
        }
        return [ArgString]::new()
    }

    static [ArgInt] GetInt([string[]] $args, [string] $name) {
        $values = [CommandLineArgs]::GetValues($args, $name)
        if ($values.Count -eq 1) {
            [int]$result = 0
            if ([int]::TryParse($values[0], [ref]$result)) {
                return [ArgInt]::new($result)
            }
        }
        return [ArgInt]::new()
    }

    static [string[]] GetValues([string[]] $args, [string] $name) {
        $index = [Array]::IndexOf($args, $name)
        if ($index -ge 0 -and $index -lt ($args.Length - 1)) {
            return $args[($index + 1)..($args.Length - 1)] | Where-Object { $_ -notmatch '^-' }
        }
        return @()

    }
}