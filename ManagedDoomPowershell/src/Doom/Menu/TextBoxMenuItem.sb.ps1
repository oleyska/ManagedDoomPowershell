#needs [MenuItem]
class TextBoxMenuItem : MenuItem {
    [int] $itemX
    [int] $itemY

    [char[]] $text
    [TextInput] $activeEdit
    [char[]] $editOriginalText
    [bool] $editing

    TextBoxMenuItem([int] $skullX, [int] $skullY, [int] $itemX, [int] $itemY) : base($skullX, $skullY, $null) {
        $this.itemX = $itemX
        $this.itemY = $itemY
    }

    [TextInput] Edit([ScriptBlock] $finished) {
        $this.editOriginalText = if ($null -ne $this.text) { [char[]]$this.text.Clone() } else { $null }
        $initialText = if ($null -ne $this.editOriginalText) { $this.editOriginalText } else { @() }

        $item = $this
        $item.editing = $true
        $typedAction = { param($cs) $item.text = $cs }.GetNewClosure()
        $finishedAction = { param($cs) $item.text = $cs; $item.activeEdit = $null; $item.editOriginalText = $null; $item.editing = $false; & $finished }.GetNewClosure()
        $canceledAction = { $item.text = $item.editOriginalText; $item.activeEdit = $null; $item.editOriginalText = $null; $item.editing = $false }.GetNewClosure()
    
        $this.activeEdit = [TextInput]::new(
            $initialText,   # Pass precomputed value
            $typedAction,
            $finishedAction,
            $canceledAction
        )
    
        return $this.activeEdit
    }

    [void] SetText([string] $text) {
        if ($null -ne $text) {
            $this.text = $text.ToCharArray()
        }
    }

    [char[]] GetText() 
        {
        if ($null -eq $this.activeEdit) {
            return $this.text
        }
        else {
            return $this.activeEdit.Text
        }
    }

}
