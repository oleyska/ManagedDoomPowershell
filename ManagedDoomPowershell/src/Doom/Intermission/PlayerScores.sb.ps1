class PlayerScores {
    # Whether the player is in game.
    [bool]$inGame
    
    # Player stats, kills, collected items etc.
    [int]$killCount
    [int]$itemCount
    [int]$secretCount
    [int]$time
    [int[]]$frags

    # Constructor to initialize frags array with MaxPlayerCount
    PlayerScores() {
        $this.frags = [int[]]::new([Player]::MaxPlayerCount)
    }
}