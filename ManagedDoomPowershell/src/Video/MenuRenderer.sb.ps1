class MenuRenderer {
    static [char[]] $Cursor = @('_')

    [Wad] $Wad
    [DrawScreen] $Screen
    [PatchCache] $Cache

    MenuRenderer([Wad] $wad, [DrawScreen] $screen) {
        $this.Wad = $wad
        $this.Screen = $screen
        $this.Cache = [PatchCache]::new($wad)
    }

    [void] Render([DoomMenu] $menu) {
        if ($menu.Current -is [SelectableMenu]) {
            $this.DrawSelectableMenu([SelectableMenu]$menu.Current)
        }

        if ($menu.Current -is [SaveMenu]) {
            $this.DrawSaveMenu([SaveMenu]$menu.Current)
        }

        if ($menu.Current -is [LoadMenu]) {
            $this.DrawLoadMenu([LoadMenu]$menu.Current)
        }

        if ($menu.Current -is [YesNoConfirm]) {
            $this.DrawText($menu.Current.Text)
        }

        if ($menu.Current -is [PressAnyKey]) {
            $this.DrawText($menu.Current.Text)
        }

        if ($menu.Current -is [QuitConfirm]) {
            $this.DrawText($menu.Current.Text)
        }

        if ($menu.Current -is [HelpScreen]) {
            $this.DrawHelp([HelpScreen]$menu.Current)
        }
    }

    [void] DrawSelectableMenu([SelectableMenu] $selectable) {
        for ($i = 0; $i -lt $selectable.Name.Count; $i++) {
            $this.DrawMenuPatch(
                $selectable.Name[$i],
                $selectable.TitleX[$i],
                $selectable.TitleY[$i]
            )
        }

        $selectableItemsEnumerable = $selectable.Items
        if ($null -ne $selectableItemsEnumerable) {
            $selectableItemsEnumerator = $selectableItemsEnumerable.GetEnumerator()
            for (; $selectableItemsEnumerator.MoveNext(); ) {
                $item = $selectableItemsEnumerator.Current
                $this.DrawMenuItem($selectable.Menu, $item)

            }
        }

        $choice = $selectable.Choice
        $skull = if (($selectable.Menu.Tics / 8) % 2 -eq 0) { "M_SKULL1" } else { "M_SKULL2" }
        $this.DrawMenuPatch($skull, $choice.SkullX, $choice.SkullY)
    }
    [void] DrawSaveMenu([SaveMenu] $save) {
        for ($i = 0; $i -lt $save.Name.Count; $i++) {
            $this.DrawMenuPatch(
                $save.Name[$i],
                $save.TitleX[$i],
                $save.TitleY[$i]
            )
        }

        $saveMenuItemsEnumerable = $save.Items
        if ($null -ne $saveMenuItemsEnumerable) {
            $saveMenuItemsEnumerator = $saveMenuItemsEnumerable.GetEnumerator()
            for (; $saveMenuItemsEnumerator.MoveNext(); ) {
                $item = $saveMenuItemsEnumerator.Current
                $this.DrawMenuItem($save.Menu, $item)

            }
        }

        $choice = $save.Choice
        $skull = if (($save.Menu.Tics / 8) % 2 -eq 0) { "M_SKULL1" } else { "M_SKULL2" }
        $this.DrawMenuPatch($skull, $choice.SkullX, $choice.SkullY)
    }

    [void] DrawLoadMenu([LoadMenu] $load) {
        for ($i = 0; $i -lt $load.Name.Count; $i++) {
            $this.DrawMenuPatch(
                $load.Name[$i],
                $load.TitleX[$i],
                $load.TitleY[$i]
            )
        }

        $loadMenuItemsEnumerable = $load.Items
        if ($null -ne $loadMenuItemsEnumerable) {
            $loadMenuItemsEnumerator = $loadMenuItemsEnumerable.GetEnumerator()
            for (; $loadMenuItemsEnumerator.MoveNext(); ) {
                $item = $loadMenuItemsEnumerator.Current
                $this.DrawMenuItem($load.Menu, $item)

            }
        }

        $choice = $load.Choice
        $skull = if (($load.Menu.Tics / 8) % 2 -eq 0) { "M_SKULL1" } else { "M_SKULL2" }
        $this.DrawMenuPatch($skull, $choice.SkullX, $choice.SkullY)
    }

    [void] DrawMenuItem([DoomMenu] $menu, [MenuItem] $item) {
        if ($item -is [SimpleMenuItem]) {
            $this.DrawSimpleMenuItem([SimpleMenuItem]$item)
        }

        if ($item -is [ToggleMenuItem]) {
            $this.DrawToggleMenuItem([ToggleMenuItem]$item)
        }

        if ($item -is [SliderMenuItem]) {
            $this.DrawSliderMenuItem([SliderMenuItem]$item)
        }

        if ($item -is [TextBoxMenuItem]) {
            $this.DrawTextBoxMenuItem([TextBoxMenuItem]$item, $menu.Tics)
        }
    }
    [void] DrawMenuPatch([string] $name, [int] $x, [int] $y) {
        $scale = $this.screen.Width / 320
        $this.screen.DrawPatch($this.cache.get_Item($name), $scale * $x, $scale * $y, $scale)
    }

    [void] DrawMenuText([char[]] $text, [int] $x, [int] $y) {
        $scale = $this.screen.Width / 320
        $this.screen.DrawText($text, $scale * $x, $scale * $y, $scale)
    }

    [void] DrawSimpleMenuItem([SimpleMenuItem] $item) {
        $this.DrawMenuPatch($item.Name, $item.ItemX, $item.ItemY)
    }

    [void] DrawToggleMenuItem([ToggleMenuItem] $item) {
        $this.DrawMenuPatch($item.Name, $item.ItemX, $item.ItemY)
        $this.DrawMenuPatch($item.get_State(), $item.StateX, $item.ItemY)
    }

    [void] DrawSliderMenuItem([SliderMenuItem] $item) {
        $sliderX = $item.get_SliderX()
        $sliderY = $item.get_SliderY()

        $this.DrawMenuPatch($item.Name, $item.ItemX, $item.ItemY)
        $this.DrawMenuPatch("M_THERML", $sliderX, $sliderY)

        for ($i = 0; $i -lt $item.SliderLength; $i++) {
            $x = $sliderX + 8 * (1 + $i)
            $this.DrawMenuPatch("M_THERMM", $x, $sliderY)
        }

        $end = $sliderX + 8 * (1 + $item.SliderLength)
        $this.DrawMenuPatch("M_THERMR", $end, $sliderY)

        $pos = $sliderX + 8 * (1 + $item.SliderPosition)
        $this.DrawMenuPatch("M_THERMO", $pos, $sliderY)
    }

    [char[]] $emptyText = "EMPTY SLOT".ToCharArray()
    [void] DrawTextBoxMenuItem([TextBoxMenuItem] $item, [int] $tics) {
        $length = 24
        $this.DrawMenuPatch("M_LSLEFT", $item.ItemX, $item.ItemY)
        for ($i = 0; $i -lt $length; $i++) {
            $x = $item.ItemX + 8 * (1 + $i)
            $this.DrawMenuPatch("M_LSCNTR", $x, $item.ItemY)
        }
        $this.DrawMenuPatch("M_LSRGHT", $item.ItemX + 8 * (1 + $length), $item.ItemY)

        if (-not $item.Editing) {
            $text = if ($null -ne $item.Text) { $item.Text } else { $this.emptyText }
            $this.DrawMenuText($text, $item.ItemX + 8, $item.ItemY)
        } else {
            $this.DrawMenuText($item.Text, $item.ItemX + 8, $item.ItemY)
            if (($tics / 3) % 2 -eq 0) {
                $textWidth = $this.screen.MeasureText($item.Text, 1)
                $this.DrawMenuText($this.cursor, $item.ItemX + 8 + $textWidth, $item.ItemY)
            }
        }
    }

    [void] DrawText([string[]] $text) {
        $scale = $this.screen.Width / 320
        $lines = [System.Collections.Generic.List[string]]::new()
        $textEntriesEnumerable = $text
        if ($null -ne $textEntriesEnumerable) {
            $textEntriesEnumerator = $textEntriesEnumerable.GetEnumerator()
            for (; $textEntriesEnumerator.MoveNext(); ) {
                $entry = $textEntriesEnumerator.Current
                $textEntryLinesEnumerable = (([string]$entry) -split "(?:`r`n|`n|`r)")
                if ($null -ne $textEntryLinesEnumerable) {
                    $textEntryLinesEnumerator = $textEntryLinesEnumerable.GetEnumerator()
                    for (; $textEntryLinesEnumerator.MoveNext(); ) {
                        $line = $textEntryLinesEnumerator.Current
                        $lines.Add($line)

                    }
                }

            }
        }

        $height = 7 * $scale * $lines.Count

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $x = ($this.screen.Width - $this.screen.MeasureText($lines[$i], $scale)) / 2
            $y = ($this.screen.Height - $height) / 2 + 7 * $scale * ($i + 1)
            $this.screen.DrawText($lines[$i], $x, $y, $scale)
        }
    }

    [void] DrawHelp([HelpScreen] $help) {
        $skull = if (($help.Menu.Tics / 8) % 2 -eq 0) { "M_SKULL1" } else { "M_SKULL2" }

        if ($help.Menu.Options.GameMode -eq [GameMode]::Commercial) {
            $this.DrawMenuPatch("HELP", 0, 0)
            $this.DrawMenuPatch($skull, 298, 160)
        } else {
            if ($help.Page -eq 0) {
                $this.DrawMenuPatch("HELP1", 0, 0)
                $this.DrawMenuPatch($skull, 298, 170)
            } else {
                $this.DrawMenuPatch("HELP2", 0, 0)
                $this.DrawMenuPatch($skull, 248, 180)
            }
        }
    }
}
