class OpeningSequenceRenderer {
    [DrawScreen] $Screen
    [Renderer] $Parent
    [PatchCache] $Cache
    [byte[]] $TitleScreenData
    [byte[]] $CreditScreenData

    OpeningSequenceRenderer([Wad] $wad, [DrawScreen] $screen, [Renderer] $parent) {
        $this.Screen = $screen
        $this.Parent = $parent
        $this.Cache = [PatchCache]::new($wad)
        $this.TitleScreenData = $this.BuildStaticScreen($wad, "TITLEPIC")
        $this.CreditScreenData = $this.BuildStaticScreen($wad, "CREDIT")
    }

    hidden [byte[]] BuildStaticScreen([Wad] $wad, [string] $patchName) {
        $patch = $this.Cache.get_Item($patchName)
        if ($null -eq $patch) {
            return $null
        }

        $scratch = [DrawScreen]::new($wad, $this.Screen.Width, $this.Screen.Height)
        $scale = [int]($scratch.Width / 320)
        $scratch.DrawPatch($patch, 0, 0, $scale)

        $cached = [byte[]]::new($scratch.Data.Length)
        [Buffer]::BlockCopy($scratch.Data, 0, $cached, 0, $scratch.Data.Length)
        return $cached
    }

    hidden [void] CopyStaticScreen([byte[]] $source) {
        if ($null -eq $source -or $source.Length -ne $this.Screen.Data.Length) {
            return
        }

        [Buffer]::BlockCopy($source, 0, $this.Screen.Data, 0, $source.Length)
    }

    [void] Render([OpeningSequence] $sequence, [Fixed] $frameFrac) {
        switch ([OpeningSequenceState]$sequence.State) {
            ([OpeningSequenceState]::Title) {
                $this.CopyStaticScreen($this.TitleScreenData)
            }

            ([OpeningSequenceState]::Demo) {
                $this.Parent.RenderGame($sequence.Game, $frameFrac)
            }

            ([OpeningSequenceState]::Credit) {
                $this.CopyStaticScreen($this.CreditScreenData)
            }
        }
    }
}
