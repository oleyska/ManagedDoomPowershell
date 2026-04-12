class PressAnyKey : MenuDef {
    [string[]] $text
    [Action] $action

    PressAnyKey([DoomMenu] $menu, [string] $text, [Action] $action) : base($menu) {
        $this.text = $text.Split('`n')  # Split the input text into lines (equivalent to C# Split('\n'))
        $this.action = $action
    }

    [bool] DoEvent([DoomEvent] $e) {
        if ($e.Type -eq [EventType]::KeyDown) {
            if ($this.action) {
                $this.action.Invoke()
            }

            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)

            return $true
        }

        return $true
    }
}