#Needs [MenuDef]
class HelpScreen : MenuDef {
    [int]$pageCount
    [int]$page

    HelpScreen([DoomMenu]$menu) : base($menu) {
        if ($menu.Options.GameMode -eq [GameMode]::Shareware) {
            $this.pageCount = 2
        } else {
            $this.pageCount = 1
        }
    }

    [void] Open() {
        $this.page = $this.pageCount - 1
    }

    [bool] DoEvent([DoomEvent]$e) {
        if ($e.Type -ne [EventType]::KeyDown) {
            return $true
        }

        if ($e.Key -eq [DoomKey]::Enter -or
            $e.Key -eq [DoomKey]::Space -or
            $e.Key -eq [DoomKey]::LControl -or
            $e.Key -eq [DoomKey]::RControl) {
            $this.page--

            if ($this.page -eq -1) {
                $this.Menu.Close()
            }
            $this.Menu.StartSound([Sfx]::PISTOL)
        }

        if ($e.Key -eq [DoomKey]::Escape) {
            $this.Menu.Close()
            $this.Menu.StartSound([Sfx]::SWTCHX)
        }

        return $true
    }
}