class TicCmd {

    hidden [System.SByte] $forwardMove
    hidden [System.SByte] $sideMove
    hidden [System.Int16] $angleTurn
    hidden [System.Byte]  $buttons

    TicCmd() {
        # Optional constructor logic
    }

    [void] Clear() {
        $this.forwardMove = 0
        $this.sideMove    = 0
        $this.angleTurn   = 0
        $this.buttons     = 0
    }

    [void] CopyFrom([TicCmd] $cmd) {
        $this.forwardMove = $cmd.ForwardMove
        $this.sideMove    = $cmd.SideMove
        $this.angleTurn   = $cmd.AngleTurn
        $this.buttons     = $cmd.Buttons
    }

    # Provide 'get_' and 'set_' methods so you can use them like properties:
    [System.SByte] get_ForwardMove() {
        return $this.forwardMove
    }
    [void] set_ForwardMove([System.SByte] $value) {
        $this.forwardMove = $value
    }

    [System.SByte] get_SideMove() {
        return $this.sideMove
    }
    [void] set_SideMove([System.SByte] $value) {
        $this.sideMove = $value
    }

    [System.Int16] get_AngleTurn() {
        return $this.angleTurn
    }
    [void] set_AngleTurn([System.Int16] $value) {
        $this.angleTurn = $value
    }

    [System.Byte] get_Buttons() {
        return $this.buttons
    }
    [void] set_Buttons([System.Byte] $value) {
        $this.buttons = $value
    }
}