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

class DrawScreen {
    [int] $Width
    [int] $Height
    [byte[]] $Data
    [Patch[]] $Chars
    [hashtable] $Scale2PatchColumns

    DrawScreen([Wad] $wad, [int] $width, [int] $height) {
        $this.Width = $width
        $this.Height = $height
        $this.Data = New-Object byte[] ($width * $height)
        $this.Scale2PatchColumns = @{}

        $this.Chars = New-Object Patch[] 128
        for ($i = 0; $i -lt $this.Chars.Length; $i++) {
            $name = "STCFN" + ("{0:D3}" -f $i)
            $lump = $wad.GetLumpNumber($name)
            if ($lump -ne -1) {
                $this.Chars[$i] = [Patch]::FromData($name, $wad.ReadLump($lump))
            }
        }
    }

    [void] DrawPatch([Patch] $patch, [int] $x, [int] $y, [int] $scale) {
        if ($null -eq $patch) {
            return
        }

        $drawX = $x - $scale * $patch.LeftOffset
        $drawY = $y - $scale * $patch.TopOffset
        $drawWidth = $scale * $patch.Width

        if ($scale -eq 2) {
            $scaledColumns = $this.GetScale2PatchColumns($patch)
            for ($col = 0; $col -lt $patch.Width; $col++) {
                $destX = $drawX + ($col -shl 1)

                if ($destX -ge $this.Width) {
                    break
                }

                if ($destX + 1 -lt 0) {
                    continue
                }

                $source = $scaledColumns[$col]

                if ($destX -ge 0 -and $destX + 1 -lt $this.Width) {
                    $this.DrawColumnPair1X($source, $destX, $drawY)
                    continue
                }

                if ($destX -ge 0) {
                    $this.DrawColumnBlit($source, $destX, $drawY)
                }

                if ($destX + 1 -ge 0 -and $destX + 1 -lt $this.Width) {
                    $this.DrawColumnBlit($source, $destX + 1, $drawY)
                }
            }
            return
        }

        $i = 0

        if ($drawX -lt 0) {
            $exceed = -$drawX
            $i += $exceed
        }

        if ($drawX + $drawWidth -gt $this.Width) {
            $exceed = $drawX + $drawWidth - $this.Width
            $drawWidth -= $exceed
        }

        for (; $i -lt $drawWidth; $i++) {
            $sourceColumn = [int]($i / $scale)
            $this.DrawColumn($patch.Columns[$sourceColumn], $drawX + $i, $drawY, $scale)
        }
    }

    [void] DrawPatchFlip([Patch] $patch, [int] $x, [int] $y, [int] $scale) {
        if ($null -eq $patch) {
            return
        }

        $drawX = $x - $scale * $patch.LeftOffset
        $drawY = $y - $scale * $patch.TopOffset
        $drawWidth = $scale * $patch.Width

        if ($scale -eq 2) {
            $scaledColumns = $this.GetScale2PatchColumns($patch)
            for ($col = 0; $col -lt $patch.Width; $col++) {
                $destX = $drawX + ($col -shl 1)

                if ($destX -ge $this.Width) {
                    break
                }

                if ($destX + 1 -lt 0) {
                    continue
                }

                $source = $scaledColumns[$patch.Width - $col - 1]

                if ($destX -ge 0 -and $destX + 1 -lt $this.Width) {
                    $this.DrawColumnPair1X($source, $destX, $drawY)
                    continue
                }

                if ($destX -ge 0) {
                    $this.DrawColumnBlit($source, $destX, $drawY)
                }

                if ($destX + 1 -ge 0 -and $destX + 1 -lt $this.Width) {
                    $this.DrawColumnBlit($source, $destX + 1, $drawY)
                }
            }
            return
        }

        $i = 0

        if ($drawX -lt 0) {
            $exceed = -$drawX
            $i += $exceed
        }

        if ($drawX + $drawWidth -gt $this.Width) {
            $exceed = $drawX + $drawWidth - $this.Width
            $drawWidth -= $exceed
        }

        for (; $i -lt $drawWidth; $i++) {
            $col = $patch.Width - [int]($i / $scale) - 1
            $this.DrawColumn($patch.Columns[$col], $drawX + $i, $drawY, $scale)
        }
    }

    [void] DrawPatchExact([Patch] $patch, [int] $x, [int] $y, [int] $scale) {
        if ($null -eq $patch) {
            return
        }

        $drawX = $x - $scale * $patch.LeftOffset
        $drawY = $y - $scale * $patch.TopOffset
        $drawWidth = $scale * $patch.Width

        $i = 0
        $frac = [Fixed]::One / $scale - [Fixed]::Epsilon
        $step = [Fixed]::One / $scale

        if ($drawX -lt 0) {
            $exceed = -$drawX
            $frac += $exceed * $step
            $i += $exceed
        }

        if ($drawX + $drawWidth -gt $this.Width) {
            $exceed = $drawX + $drawWidth - $this.Width
            $drawWidth -= $exceed
        }

        for (; $i -lt $drawWidth; $i++) {
            $this.DrawColumnExact($patch.Columns[$frac.ToIntFloor()], $drawX + $i, $drawY, $scale)
            $frac += $step
        }
    }

    hidden [Column[][]] GetScale2PatchColumns([Patch] $patch) {
        if ($null -eq $patch) {
            return [Column[][]]::new(0)
        }

        $cacheKey = $patch.Name
        if (-not [string]::IsNullOrEmpty($cacheKey)) {
            $cached = $this.Scale2PatchColumns[$cacheKey]
            if ($null -ne $cached) {
                return $cached
            }
        }

        $scaledColumns = [Column[][]]::new($patch.Width)

        for ($x = 0; $x -lt $patch.Width; $x++) {
            $sourceColumns = $patch.Columns[$x]
            if ($null -eq $sourceColumns -or $sourceColumns.Length -eq 0) {
                $scaledColumns[$x] = [Column[]]::new(0)
                continue
            }

            $scaledPosts = [Column[]]::new($sourceColumns.Length)

            for ($i = 0; $i -lt $sourceColumns.Length; $i++) {
                $source = $sourceColumns[$i]
                $scaledLength = $source.Length -shl 1
                $scaledData = [byte[]]::new($scaledLength)

                $src = $source.Data
                $srcIndex = $source.Offset
                $dest = 0
                $srcEnd = $srcIndex + $source.Length

                for (; $srcIndex -lt $srcEnd; $srcIndex++) {
                    $value = $src[$srcIndex]
                    $scaledData[$dest] = $value
                    $scaledData[$dest + 1] = $value
                    $dest += 2
                }

                $scaledPosts[$i] = [Column]::new($source.TopDelta -shl 1, $scaledData, 0, $scaledLength)
            }

            $scaledColumns[$x] = $scaledPosts
        }

        if (-not [string]::IsNullOrEmpty($cacheKey)) {
            $this.Scale2PatchColumns[$cacheKey] = $scaledColumns
        }

        return $scaledColumns
    }

    hidden [void] DrawColumnBlit([Column[]] $source, [int] $x, [int] $y) {
        if ($null -eq $source -or $source.Length -eq 0) {
            return
        }

        $screenData = $this.Data
        $screenHeight = $this.Height
        $basePos = $screenHeight * $x

        $blitSourceColumnsEnumerable = $source
        if ($null -ne $blitSourceColumnsEnumerable) {
            $blitSourceColumnsEnumerator = $blitSourceColumnsEnumerable.GetEnumerator()
            for (; $blitSourceColumnsEnumerator.MoveNext(); ) {
                $column = $blitSourceColumnsEnumerator.Current
                $sourceIndex = $column.Offset
                $drawY = $y + $column.TopDelta
                $drawLength = $column.Length

                if ($drawY -lt 0) {
                    $exceed = -$drawY
                    $sourceIndex += $exceed
                    $drawY = 0
                    $drawLength -= $exceed
                }

                if ($drawY + $drawLength -gt $screenHeight) {
                    $exceed = $drawY + $drawLength - $screenHeight
                    $drawLength -= $exceed
                }

                if ($drawLength -gt 0) {
                    [Buffer]::BlockCopy($column.Data, $sourceIndex, $screenData, $basePos + $drawY, $drawLength)
                }

            }
        }
    }

    hidden [void] DrawColumnPair1X([Column[]] $source, [int] $x, [int] $y) {
        if ($null -eq $source -or $source.Length -eq 0) {
            return
        }

        $screenData = $this.Data
        $screenHeight = $this.Height
        $basePos1 = $screenHeight * $x
        $basePos2 = $basePos1 + $screenHeight

        $pairedSourceColumnsEnumerable = $source
        if ($null -ne $pairedSourceColumnsEnumerable) {
            $pairedSourceColumnsEnumerator = $pairedSourceColumnsEnumerable.GetEnumerator()
            for (; $pairedSourceColumnsEnumerator.MoveNext(); ) {
                $column = $pairedSourceColumnsEnumerator.Current
                $sourceIndex = $column.Offset
                $drawY = $y + $column.TopDelta
                $drawLength = $column.Length

                if ($drawY -lt 0) {
                    $exceed = -$drawY
                    $sourceIndex += $exceed
                    $drawY = 0
                    $drawLength -= $exceed
                }

                if ($drawY + $drawLength -gt $screenHeight) {
                    $exceed = $drawY + $drawLength - $screenHeight
                    $drawLength -= $exceed
                }

                if ($drawLength -gt 0) {
                    [Buffer]::BlockCopy($column.Data, $sourceIndex, $screenData, $basePos1 + $drawY, $drawLength)
                    [Buffer]::BlockCopy($column.Data, $sourceIndex, $screenData, $basePos2 + $drawY, $drawLength)
                }

            }
        }
    }

    [void] DrawColumn([Column[]] $source, [int] $x, [int] $y, [int] $scale) {
        if ($null -eq $source -or $source.Length -eq 0) {
            return
        }

        $screenData = $this.Data
        $screenHeight = $this.Height
        $step = [Fixed]::One / $scale

        if ($scale -eq 1) {
            $unitScaleSourceColumnsEnumerable = $source
            if ($null -ne $unitScaleSourceColumnsEnumerable) {
                $unitScaleSourceColumnsEnumerator = $unitScaleSourceColumnsEnumerable.GetEnumerator()
                for (; $unitScaleSourceColumnsEnumerator.MoveNext(); ) {
                    $column = $unitScaleSourceColumnsEnumerator.Current
                    $sourceIndex = $column.Offset
                    $drawY = $y + $column.TopDelta
                    $drawLength = $column.Length

                    if ($drawY -lt 0) {
                        $exceed = -$drawY
                        $sourceIndex += $exceed
                        $drawY = 0
                        $drawLength -= $exceed
                    }

                    if ($drawY + $drawLength -gt $screenHeight) {
                        $exceed = $drawY + $drawLength - $screenHeight
                        $drawLength -= $exceed
                    }

                    if ($drawLength -gt 0) {
                        [Buffer]::BlockCopy($column.Data, $sourceIndex, $screenData, $screenHeight * $x + $drawY, $drawLength)
                    }

                }
            }
            return
        }

        if ($scale -eq 2) {
            $this.DrawColumnBlit($this.GetScale2ColumnsForSource($source), $x, $y)
            return
        }

        $scaledSourceColumnsEnumerable = $source
        if ($null -ne $scaledSourceColumnsEnumerable) {
            $scaledSourceColumnsEnumerator = $scaledSourceColumnsEnumerable.GetEnumerator()
            for (; $scaledSourceColumnsEnumerator.MoveNext(); ) {
                $column = $scaledSourceColumnsEnumerator.Current
                $exTopDelta = $scale * $column.TopDelta
                $exLength = $scale * $column.Length

                $sourceIndex = $column.Offset
                $drawY = $y + $exTopDelta
                $drawLength = $exLength

                $i = 0
                $p = $screenHeight * $x + $drawY
                $frac = [Fixed]::One / $scale - [Fixed]::Epsilon

                if ($drawY -lt 0) {
                    $exceed = -$drawY
                    $p += $exceed
                    $frac += $exceed * $step
                    $i += $exceed
                }

                if ($drawY + $drawLength -gt $screenHeight) {
                    $exceed = $drawY + $drawLength - $screenHeight
                    $drawLength -= $exceed
                }

                for (; $i -lt $drawLength; $i++) {
                    $screenData[$p] = $column.Data[$sourceIndex + $frac.ToIntFloor()]
                    $p++
                    $frac += $step
                }

            }
        }
    }

    [void] DrawColumnExact([Column[]] $source, [int] $x, [int] $y, [int] $scale) {
        if ($null -eq $source -or $source.Length -eq 0) {
            return
        }

        $screenData = $this.Data
        $screenHeight = $this.Height
        $step = [Fixed]::One / $scale

        $exactSourceColumnsEnumerable = $source
        if ($null -ne $exactSourceColumnsEnumerable) {
            $exactSourceColumnsEnumerator = $exactSourceColumnsEnumerable.GetEnumerator()
            for (; $exactSourceColumnsEnumerator.MoveNext(); ) {
                $column = $exactSourceColumnsEnumerator.Current
                $exTopDelta = $scale * $column.TopDelta
                $exLength = $scale * $column.Length

                $sourceIndex = $column.Offset
                $drawY = $y + $exTopDelta
                $drawLength = $exLength

                $i = 0
                $p = $screenHeight * $x + $drawY
                $frac = [Fixed]::One / $scale - [Fixed]::Epsilon

                if ($drawY -lt 0) {
                    $exceed = -$drawY
                    $p += $exceed
                    $frac += $exceed * $step
                    $i += $exceed
                }

                if ($drawY + $drawLength -gt $screenHeight) {
                    $exceed = $drawY + $drawLength - $screenHeight
                    $drawLength -= $exceed
                }

                for (; $i -lt $drawLength; $i++) {
                    $screenData[$p] = $column.Data[$sourceIndex + $frac.ToIntFloor()]
                    $p++
                    $frac += $step
                }

            }
        }
    }

    hidden [Column[]] GetScale2ColumnsForSource([Column[]] $source) {
        if ($null -eq $source -or $source.Length -eq 0) {
            return $source
        }

        $scaledPosts = [Column[]]::new($source.Length)

        for ($i = 0; $i -lt $source.Length; $i++) {
            $item = $source[$i]
            $scaledLength = $item.Length -shl 1
            $scaledData = [byte[]]::new($scaledLength)

            $src = $item.Data
            $srcIndex = $item.Offset
            $dest = 0
            $srcEnd = $srcIndex + $item.Length

            for (; $srcIndex -lt $srcEnd; $srcIndex++) {
                $value = $src[$srcIndex]
                $scaledData[$dest] = $value
                $scaledData[$dest + 1] = $value
                $dest += 2
            }

            $scaledPosts[$i] = [Column]::new($item.TopDelta -shl 1, $scaledData, 0, $scaledLength)
        }

        return $scaledPosts
    }



    [void] DrawChar([char] $ch, [int] $x, [int] $y, [int] $scale) {
        $drawX = $x
        $drawY = $y - 7 * $scale

        if ([int][char]$ch -ge $this.Chars.Length) {
            return
        }

        if ($ch -eq " ") {
            return
        }

        $index = [int][char]$ch
        if ($index -ge [int][char]'a' -and $index -le [int][char]'z') {
            $index = $index - [int][char]'a' + [int][char]'A'
        }

        $patch = $this.Chars[$index]
        if ($null -eq $patch) {
            return
        }

        $this.DrawPatch($patch, $drawX, $drawY, $scale)
    }
    [void] DrawText([string] $text, [int] $x, [int] $y, [int] $scale) {
        $drawX = $x
        $drawY = $y - 7 * $scale

        $textCharactersEnumerable = $text.ToCharArray()
        if ($null -ne $textCharactersEnumerable) {
            $textCharactersEnumerator = $textCharactersEnumerable.GetEnumerator()
            for (; $textCharactersEnumerator.MoveNext(); ) {
                $ch = $textCharactersEnumerator.Current
                if ([int][char]$ch -ge $this.Chars.Length) {
                    continue
                }

                if ($ch -eq " ") {
                    $drawX += 4 * $scale
                    continue
                }

                $index = [int][char]$ch
                if ($index -ge [int][char]'a' -and $index -le [int][char]'z') {
                    $index = $index - [int][char]'a' + [int][char]'A'
                }

                $patch = $this.Chars[$index]
                if ($null -eq $patch) {
                    continue
                }

                $this.DrawPatch($patch, $drawX, $drawY, $scale)

                $drawX += $scale * $patch.Width

            }
        }
    }
    
    [int] MeasureChar([char] $ch, [int] $scale) {
        if ([int][char]$ch -ge $this.Chars.Length) {
            return 0
        }
    
        if ($ch -eq " ") {
            return 4 * $scale
        }
    
        $index = [int][char]$ch
        if ($index -ge [int][char]'a' -and $index -le [int][char]'z') {
            $index = $index - [int][char]'a' + [int][char]'A'
        }
    
        $patch = $this.Chars[$index]
        if ($null -eq $patch) {
            return 0
        }
    
        return $scale * $patch.Width
    }
    
    [int] MeasureText([string] $text, [int] $scale) {
        $mWidth = 0
    
        $textCharactersEnumerable = $text.ToCharArray()
        if ($null -ne $textCharactersEnumerable) {
            $textCharactersEnumerator = $textCharactersEnumerable.GetEnumerator()
            for (; $textCharactersEnumerator.MoveNext(); ) {
                $ch = $textCharactersEnumerator.Current
                if ([int][char]$ch -ge $this.Chars.Length) {
                    continue
                }

                if ($ch -eq " ") {
                    $mWidth += 4 * $scale
                    continue
                }

                $index = [int][char]$ch
                if ($index -ge [int][char]'a' -and $index -le [int][char]'z') {
                    $index = $index - [int][char]'a' + [int][char]'A'
                }

                $patch = $this.Chars[$index]
                if ($null -eq $patch) {
                    continue
                }

                $mWidth += $scale * $patch.Width

            }
        }
    
        return $mWidth
    }
    
    [void] FillRect([int] $x, [int] $y, [int] $w, [int] $h, [int] $color) {
        $x1 = $x
        $x2 = $x + $w
    
        for ($drawX = $x1; $drawX -lt $x2; $drawX++) {
            $pos = $this.Height * $drawX + $y
            for ($i = 0; $i -lt $h; $i++) {
                $this.Data[$pos] = [byte]$color
                $pos++
            }
        }
    }
    [OutCode] ComputeOutCode([float] $x, [float] $y) {
        $code = [OutCode]::Inside
    
        if ($x -lt 0) {
            $code = $code -bor [OutCode]::Left
        } elseif ($x -gt $this.Width) {
            $code = $code -bor [OutCode]::Right
        }
    
        if ($y -lt 0) {
            $code = $code -bor [OutCode]::Bottom
        } elseif ($y -gt $this.Height) {
            $code = $code -bor [OutCode]::Top
        }
    
        return $code
    }
    [void] DrawLine([float] $x1, [float] $y1, [float] $x2, [float] $y2, [int] $color) {
        $outCode1 = $this.ComputeOutCode($x1, $y1)
        $outCode2 = $this.ComputeOutCode($x2, $y2)
    
        $accept = $false
    
        while ($true) {
            if (($outCode1 -bor $outCode2) -eq 0) {
                $accept = $true
                break
            } elseif (($outCode1 -band $outCode2) -ne 0) {
                break
            } else {
                $x = 0.0
                $y = 0.0
    
                $outcodeOut = if ($outCode2 -gt $outCode1) { $outCode2 } else { $outCode1 }
    
                if (($outcodeOut -band [OutCode]::Top) -ne 0) {
                    $x = $x1 + ($x2 - $x1) * ($this.Height - $y1) / ($y2 - $y1)
                    $y = $this.Height
                } elseif (($outcodeOut -band [OutCode]::Bottom) -ne 0) {
                    $x = $x1 + ($x2 - $x1) * (0 - $y1) / ($y2 - $y1)
                    $y = 0
                } elseif (($outcodeOut -band [OutCode]::Right) -ne 0) {
                    $y = $y1 + ($y2 - $y1) * ($this.Width - $x1) / ($x2 - $x1)
                    $x = $this.Width
                } elseif (($outcodeOut -band [OutCode]::Left) -ne 0) {
                    $y = $y1 + ($y2 - $y1) * (0 - $x1) / ($x2 - $x1)
                    $x = 0
                }
    
                if ($outcodeOut -eq $outCode1) {
                    $x1 = $x
                    $y1 = $y
                    $outCode1 = $this.ComputeOutCode($x1, $y1)
                } else {
                    $x2 = $x
                    $y2 = $y
                    $outCode2 = $this.ComputeOutCode($x2, $y2)
                }
            }
        }
    
        if ($accept) {
            $bx1 = [Math]::Clamp([int]$x1, 0, $this.Width - 1)
            $by1 = [Math]::Clamp([int]$y1, 0, $this.Height - 1)
            $bx2 = [Math]::Clamp([int]$x2, 0, $this.Width - 1)
            $by2 = [Math]::Clamp([int]$y2, 0, $this.Height - 1)
            $this.Bresenham($bx1, $by1, $bx2, $by2, $color)
        }
    }
    [void] Bresenham([int] $x1, [int] $y1, [int] $x2, [int] $y2, [int] $color) {
        $dx = $x2 - $x1
        $ax = 2 * [Math]::Abs($dx)
        $sx = if ($dx -lt 0) { -1 } else { 1 }
    
        $dy = $y2 - $y1
        $ay = 2 * [Math]::Abs($dy)
        $sy = if ($dy -lt 0) { -1 } else { 1 }
    
        $x = $x1
        $y = $y1
    
        if ($ax -gt $ay) {
            $d = $ay - [math]::Floor($ax / 2)
    
            while ($true) {
                $this.data[$this.Height * $x + $y] = [byte]$color
    
                if ($x -eq $x2) {
                    return
                }
    
                if ($d -ge 0) {
                    $y += $sy
                    $d -= $ax
                }
    
                $x += $sx
                $d += $ay
            }
        } else {
            $d = $ax - [math]::Floor($ay / 2)
    
            while ($true) {
                $this.data[$this.Height * $x + $y] = [byte]$color
    
                if ($y -eq $y2) {
                    return
                }
    
                if ($d -ge 0) {
                    $x += $sx
                    $d -= $ay
                }
    
                $y += $sy
                $d += $ax
            }
        }
    }
            
}

[Flags()]
enum OutCode {
    Inside = 0
    Left = 1
    Right = 2
    Bottom = 4
    Top = 8
}
