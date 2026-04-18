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

class Texture {
    [string]$Name
    [bool]$Masked
    [int]$Width
    [int]$Height
    [TexturePatch[]]$Patches
    [Patch]$Composite

    Texture([string]$name, [bool]$masked, [int]$width, [int]$height, [TexturePatch[]]$patches) {
        $this.Name = $name
        $this.Masked = $masked
        $this.Width = $width
        $this.Height = $height
        $this.Patches = $patches
        $this.Composite = [Texture]::GenerateComposite($name, $width, $height, $patches)
    }

    static [Texture] FromData([byte[]]$data, [int]$offset, [Patch[]]$patchLookup) {
        $mname = [DoomInterop]::ToString($data, $offset, 8)
        $mmasked = [BitConverter]::ToInt32($data, $offset + 8)
        $mwidth = [BitConverter]::ToInt16($data, $offset + 12)
        $mheight = [BitConverter]::ToInt16($data, $offset + 14)
        $patchCount = [BitConverter]::ToInt16($data, $offset + 20)
        
        $mpatches = New-Object 'TexturePatch[]' $patchCount
        for ($i = 0; $i -lt $patchCount; $i++) {
            $patchOffset = $offset + 22 + [TexturePatch]::DataSize * $i
            $mpatches[$i] = [TexturePatch]::FromData($data, $patchOffset, $patchLookup)
        }

        $texture = [Texture]::new($mname, $mmasked -ne 0, $mwidth, $mheight, $mpatches)

        return $texture
    }

    static [string] GetName([byte[]]$data, [int]$offset) {
        return [DoomInterop]::ToString($data, $offset, 8)
    }

    static [int] GetHeight([byte[]]$data, [int]$offset) {
        return [BitConverter]::ToInt16($data, $offset + 14)
    }

    static [Patch] GenerateComposite([string]$name, [int]$width, [int]$height, [TexturePatch[]]$patches) {
        $patchCount = New-Object 'int[]' $width
        $columns = New-Object 'Column[][]' $width
        $compositeColumnCount = 0

        $texturePatchesEnumerable = $patches
        if ($null -ne $texturePatchesEnumerable) {
            $texturePatchesEnumerator = $texturePatchesEnumerable.GetEnumerator()
            for (; $texturePatchesEnumerator.MoveNext(); ) {
                $patch = $texturePatchesEnumerator.Current
                if ($null -eq $patch -or $null -eq $patch.Patch) {
                    continue
                }

                $left = $patch.OriginX
                $patchWidth = $patch.Patch.Width
                $patchColumns = $patch.Patch.Columns
                $right = $left + $patchWidth

                $start = [Math]::Max($left, 0)
                $end = [Math]::Min($right, $width)

                for ($x = $start; $x -lt $end; $x++) {
                    $patchCount[$x]++
                    if ($patchCount[$x] -eq 2) {
                        $compositeColumnCount++
                    }
                    $columns[$x] = $patchColumns[$x - $patch.OriginX]
                }

            }
        }

        $padding = [Math]::Max(128 - $height, 0)
        $data = New-Object 'byte[]' ($height * $compositeColumnCount + $padding)
        $i = 0
        for ($x = 0; $x -lt $width; $x++) {
            if ($patchCount[$x] -eq 0) {
                $columns[$x] = [Column[]]@()
                continue
            }

            if ($patchCount[$x] -ge 2) {
                $column = [Column]::new(0, $data, $height * $i, $height)

                $overlapTexturePatchesEnumerable = $patches
                if ($null -ne $overlapTexturePatchesEnumerable) {
                    $overlapTexturePatchesEnumerator = $overlapTexturePatchesEnumerable.GetEnumerator()
                    for (; $overlapTexturePatchesEnumerator.MoveNext(); ) {
                        $patch = $overlapTexturePatchesEnumerator.Current
                        if ($null -eq $patch -or $null -eq $patch.Patch) {
                            continue
                        }

                        $patchWidth = $patch.Patch.Width
                        $patchColumns = $patch.Patch.Columns
                        $px = $x - $patch.OriginX
                        if ($px -lt 0 -or $px -ge $patchWidth) {
                            continue
                        }

                        $patchColumn = $patchColumns[$px]
                        [Texture]::DrawColumnInCache(
                            $patchColumn,
                            $column.Data,
                            $column.Offset,
                            $patch.OriginY,
                            $height
                        )

                    }
                }

                $columns[$x] = @($column)
                $i++
            }
        }

        return [Patch]::new($name, $width, $height, 0, 0, $columns)
    }

    static [void] DrawColumnInCache([Column[]]$source, [byte[]]$destination, [int]$destinationOffset, [int]$destinationY, [int]$destinationHeight) {
        $sourceColumnsEnumerable = $source
        if ($null -ne $sourceColumnsEnumerable) {
            $sourceColumnsEnumerator = $sourceColumnsEnumerable.GetEnumerator()
            for (; $sourceColumnsEnumerator.MoveNext(); ) {
                $column = $sourceColumnsEnumerator.Current
                $sourceIndex = $column.Offset
                $destinationIndex = $destinationOffset + $destinationY + $column.TopDelta
                $length = $column.Length

                $topExceedance = -($destinationY + $column.TopDelta)
                if ($topExceedance -gt 0) {
                    $sourceIndex += $topExceedance
                    $destinationIndex += $topExceedance
                    $length -= $topExceedance
                }

                $bottomExceedance = $destinationY + $column.TopDelta + $column.Length - $destinationHeight
                if ($bottomExceedance -gt 0) {
                    $length -= $bottomExceedance
                }

                if ($length -gt 0) {
                    [Array]::Copy($column.Data, $sourceIndex, $destination, $destinationIndex, $length)
                }

            }
        }
    }

    [string] ToString() {
        return $this.Name
    }
}
