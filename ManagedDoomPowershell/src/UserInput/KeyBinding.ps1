class KeyBinding {
    # -----------------
    # Simulate "public static readonly KeyBinding Empty = new KeyBinding();"
    # in PowerShell by using a static class variable.
    static [KeyBinding] $Empty = [KeyBinding]::new()

    # -----------------
    # Internal fields to store keys and mouse buttons.
    hidden [DoomKey[]] $keys
    hidden [DoomMouseButton[]] $mouseButtons

    # -----------------
    # Private-like default constructor, sets arrays to empty.
    hidden KeyBinding() {
        $this.keys = @()
        $this.mouseButtons = @()
    }

    # -----------------
    # Constructor that takes DoomKey[].
    KeyBinding([DoomKey[]] $keys) {
        $this.keys = $keys
        $this.mouseButtons = @()
    }

    # -----------------
    # Constructor that takes DoomKey[] and DoomMouseButton[].
    KeyBinding(
        [DoomKey[]] $keys,
        [DoomMouseButton[]] $mouseButtons
    ) {
        $this.keys = $keys
        $this.mouseButtons = $mouseButtons
    }

    # -----------------
    # Mimic C# 'public override string ToString()'.
    [string] ToString() {
        # Gather string representations of each DoomKey.
        $keyValues = $this.keys | ForEach-Object { [DoomKeyEx]::ToString($_) }
        # Gather string representations of each DoomMouseButton.
        $mouseValues = $this.mouseButtons | ForEach-Object { [DoomMouseButtonEx]::ToString($_) }

        $values = $keyValues + $mouseValues

        if ($values.Count -gt 0) {
            return [string]::Join(", ", $values)
        }
        else {
            return "none"
        }
    }

    # -----------------
    # Mimic C# 'public static KeyBinding Parse(string value)'.
    static [KeyBinding] Parse([string] $value) {
        if ($value -eq "none") {
            return [KeyBinding]::Empty
        }

        # PowerShell arrays instead of List<>
        $tKeys = @()
        $tMouseButtons = @()

        $split = $value.Split(',') | ForEach-Object { $_.Trim() }
        foreach ($s in $split) {
            $key = [DoomKeyEx]::Parse($s)
            if ($key -ne [DoomKey]::Unknown) {
                $tKeys += $key   # Append to array
                continue
            }

            $mouse = [DoomMouseButtonEx]::Parse($s)
            if ($mouse -ne [DoomMouseButton]::Unknown) {
                $tMouseButtons += $mouse   # Append to array
            }
        }

        return [KeyBinding]::new(
            $tKeys,
            $tMouseButtons
        )
    }

    # -----------------
    # Expose 'Keys' as a read-only property (array of DoomKey).
    [DoomKey[]] get_Keys() {
        return $this.keys
    }

    # -----------------
    # Expose 'MouseButtons' as a read-only property (array of DoomMouseButton).
    [DoomMouseButton[]] get_MouseButtons() {
        return $this.mouseButtons
    }
}