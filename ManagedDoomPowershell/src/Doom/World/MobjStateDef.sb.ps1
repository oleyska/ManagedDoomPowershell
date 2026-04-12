class MobjStateDef {
    [int]$Number
    [Sprite]$Sprite
    [int]$Frame
    [int]$Tics
    [object]$PlayerAction
    [object]$MobjAction
    [MobjState]$Next
    [int]$Misc1
    [int]$Misc2

    MobjStateDef(
        [int]$number,
        [Sprite]$sprite,
        [int]$frame,
        [int]$tics,
        [object]$playerAction,
        [object]$mobjAction,
        [MobjState]$next,
        [int]$misc1,
        [int]$misc2
    ) {
        $this.Number = $number
        $this.Sprite = $sprite
        $this.Frame = $frame
        $this.Tics = $tics
        $this.PlayerAction = $playerAction
        $this.MobjAction = $mobjAction
        $this.Next = $next
        $this.Misc1 = $misc1
        $this.Misc2 = $misc2
    }

    [void] ExecutePlayerAction([World]$world, [Player]$player, [PlayerSpriteDef]$playerSpriteDef) {
        if ($null -ne $this.PlayerAction) {
            if ($this.PlayerAction -is [scriptblock]) {
                & $this.PlayerAction $world $player $playerSpriteDef
            } else {
                $this.PlayerAction.Invoke($world, $player, $playerSpriteDef)
            }
        }
    }

    [void] ExecuteMobjAction([World]$world, [Mobj]$mobj) {
        if ($null -ne $this.MobjAction) {
            if ($this.MobjAction -is [scriptblock]) {
                & $this.MobjAction $world $mobj
            } else {
                $this.MobjAction.Invoke($world, $mobj)
            }
        }
    }
}