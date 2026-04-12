class GameOptions {
    [GameVersion] $GameVersion
    [GameMode] $GameMode
    [MissionPack] $MissionPack

    [Player[]] $Players
    [int] $ConsolePlayer

    [int] $Episode
    [int] $Map
    [GameSkill] $Skill

    [bool] $DemoPlayback
    [bool] $NetGame

    [int] $Deathmatch
    [bool] $FastMonsters
    [bool] $RespawnMonsters
    [bool] $NoMonsters

    [IntermissionInfo] $IntermissionInfo
    [DoomRandom] $Random

    [IVideo] $Video
    [ISound] $Sound
    [IMusic] $Music
    [IUserInput] $UserInput

    GameOptions() {
        $this.GameVersion = [GameVersion]::Version109
        $this.GameMode = [GameMode]::Commercial
        $this.MissionPack = [MissionPack]::Doom2

        $this.Players = [Player[]]::new([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.Players[$i] = [Player]::new($i)
        }
        $this.Players[0].InGame = $true
        $this.ConsolePlayer = 0

        $this.Episode = 1
        $this.Map = 1
        $this.Skill = [GameSkill]::Medium

        $this.DemoPlayback = $false
        $this.NetGame = $false

        $this.Deathmatch = 0
        $this.FastMonsters = $false
        $this.RespawnMonsters = $false
        $this.NoMonsters = $false

        $this.IntermissionInfo = [IntermissionInfo]::new()
        $this.Random = [DoomRandom]::new()

        $this.Video = [NullVideo]::GetInstance()
        $this.Sound = [NullSound]::GetInstance()
        $this.Music = [NullMusic]::GetInstance()
        $this.UserInput = [NullUserInput]::GetInstance()
    }

    GameOptionsArgs($args, [GameContent] $content) {
        #$this.GameOptions()
        $mArgs = [CommandLineArgs]::new($args)
        if ($mArgs.SoloNet.Present) {
            $this.NetGame = $true
        }
        
        $this.GameVersion = $content.Wad.GameVersion
        $this.GameMode = $content.Wad.GameMode
        $this.MissionPack = $content.Wad.MissionPack
    }
}