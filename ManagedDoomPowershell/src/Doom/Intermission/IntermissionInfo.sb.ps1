class IntermissionInfo {
    # Episode number (0-2).
    [int]$episode

    # If true, splash the secret level.
    [bool]$didSecret

    # Previous and next levels, origin 0.
    [int]$lastLevel
    [int]$nextLevel

    [int]$maxKillCount
    [int]$maxItemCount
    [int]$maxSecretCount
    [int]$totalFrags


    # The par time.
    [int]$parTime

    [PlayerScores[]]$players

    # Constructor initializes players array
    IntermissionInfo() {
        $this.players = [PlayerScores[]]::new([Player]::MaxPlayerCount)
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.players[$i] = [PlayerScores]::new()
        }
    }


    [int] MaxKillCount() { return [math]::Max($this._maxKillCount, 1) }
    [int] MaxItemCount() { return [math]::Max($this._maxItemCount, 1) }
    [int] MaxSecretCount() { return [math]::Max($this._maxSecretCount, 1) }
    [int] TotalFrags() { return [math]::Max($this._totalFrags, 1) }

}