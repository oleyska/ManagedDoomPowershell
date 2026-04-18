##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##

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
