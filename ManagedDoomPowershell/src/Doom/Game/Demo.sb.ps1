class Demo {
    [int] $p
    [byte[]] $data
    [GameOptions] $options
    [int] $playerCount

    Demo([byte[]] $data) {
        $this.p = 0

        if ($data[$this.p++] -ne 109) {
            throw "Demo is from a different game version!"
        }

        $this.data = $data

        $this.options = [GameOptions]::new()
        $this.options.Skill = [GameSkill]$data[$this.p++]
        $this.options.Episode = $data[$this.p++]
        $this.options.Map = $data[$this.p++]
        $this.options.Deathmatch = $data[$this.p++]
        $this.options.RespawnMonsters = $data[$this.p++] -ne 0
        $this.options.FastMonsters = $data[$this.p++] -ne 0
        $this.options.NoMonsters = $data[$this.p++] -ne 0
        $this.options.ConsolePlayer = $data[$this.p++]

        $this.options.Players[0].InGame = $data[$this.p++] -ne 0
        $this.options.Players[1].InGame = $data[$this.p++] -ne 0
        $this.options.Players[2].InGame = $data[$this.p++] -ne 0
        $this.options.Players[3].InGame = $data[$this.p++] -ne 0

        $this.options.DemoPlayback = $true

        $this.playerCount = 0
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($this.options.Players[$i].InGame) {
                $this.playerCount++
            }
        }
        if ($this.playerCount -ge 2) {
            $this.options.NetGame = $true
        }
    }

    Demo([string] $fileName) {
        $this.new([System.IO.File]::ReadAllBytes($fileName)) }

    [bool] ReadCmd([TicCmd[]] $cmds) {
        if ($this.p -eq $this.data.Length) {
            return $false
        }

        if ($this.data[$this.p] -eq 0x80) {
            return $false
        }

        if ($this.p + 4 * $this.playerCount -gt $this.data.Length) {
            return $false
        }

        $players = $this.options.Players
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if ($players[$i].InGame) {
                $cmd = $cmds[$i]

                $value = [byte]$this.data[$this.p++]
                $cmd.ForwardMove = if ($value -gt 127) { [sbyte]($value - 256) } else { [sbyte]$value }

                $value = [byte]$this.data[$this.p++]
                $cmd.SideMove = if ($value -gt 127) { [sbyte]($value - 256) } else { [sbyte]$value }

                $highByte = [byte]$this.data[$this.p++]
                $signedHighByte = if ($highByte -gt 127) { [int]$highByte - 256 } else { [int]$highByte }
                $cmd.AngleTurn = [int16]($signedHighByte -shl 8)

                $cmd.Buttons = $this.data[$this.p++]
            }
        }

        return $true
    }

    [GameOptions] get_Options() {
        return $this.options
    }
}