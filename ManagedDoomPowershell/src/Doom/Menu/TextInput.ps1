class TextInput {
    [System.Collections.Generic.List[char]]$text
    [ScriptBlock]$typed
    [ScriptBlock]$finished
    [ScriptBlock]$canceled
    [TextInputState]$state

    TextInput([char[]]$initialText, 
              [ScriptBlock]$typed, 
              [ScriptBlock]$finished, 
              [ScriptBlock]$canceled) {
        $this.text = [System.Collections.Generic.List[char]]::new()
        if ($null -ne $initialText) {
            $initialTextCharactersEnumerable = $initialText
            if ($null -ne $initialTextCharactersEnumerable) {
                $initialTextCharactersEnumerator = $initialTextCharactersEnumerable.GetEnumerator()
                for (; $initialTextCharactersEnumerator.MoveNext(); ) {
                    $ch = $initialTextCharactersEnumerator.Current
                    $this.text.Add($ch)

                }
            }
        }
        $this.typed = $typed
        $this.finished = $finished
        $this.canceled = $canceled
        $this.state = [TextInputState]::Typing
    }

    [bool] DoEvent([DoomEvent]$e) {
        $ch = [DoomKeyEx]::GetChar($e.Key)

        # If a character key was pressed
        if ($ch -ne 0) {
            $this.text.Add($ch)
            [void] $this.typed.Invoke($this.text)
            return $true
        }

        # If backspace key was pressed
        if ($e.Key -eq [DoomKey]::Backspace -and $e.Type -eq [EventType]::KeyDown) {
            if ($this.text.Count -gt 0) {
                $this.text.RemoveAt($this.text.Count - 1)
            }
            [void] $this.typed.Invoke($this.text)
            return $true
        }

        # If enter key was pressed
        if ($e.Key -eq [DoomKey]::Enter -and $e.Type -eq [EventType]::KeyDown) {
            [void] $this.finished.Invoke($this.text)
            $this.state = [TextInputState]::Finished
            return $true
        }

        # If escape key was pressed
        if ($e.Key -eq [DoomKey]::Escape -and $e.Type -eq [EventType]::KeyDown) {
            [void] $this.canceled.Invoke()
            $this.state = [TextInputState]::Canceled
            return $true
        }

        return $true
    }
}
