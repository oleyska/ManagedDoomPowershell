##
## Copyright (C) 2026 Oleyska
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

#Requires -Version 7.1

function DeBundle ($sbfilelist,$bundlefilePath)
{
$bundlefile = Get-Content $bundlefilePath
$sbFileLookup = @{}
foreach ($item in $sbfilelist) {
    $sbFileLookup[$item.FileName] = $item
}

# Parse combined SB file into blocks
$currentFileName = $null
$currentLines = [System.Collections.Generic.List[string]]::new()
$parsedBlocks = @{}

foreach ($line in $bundlefile) {
    if ($line -match '^\s*#region\s+(.+)$') {
        $currentFileName = $matches[1].Trim()
        $currentLines = [System.Collections.Generic.List[string]]::new()
        continue
    }

    if ($line -match '^\s*#endregion\b') {
        if ($currentFileName) {
            $parsedBlocks[$currentFileName] = @($currentLines)
            $currentFileName = $null
            $currentLines = [System.Collections.Generic.List[string]]::new()
        }
        continue
    }

    if ($currentFileName) {
        $currentLines.Add($line)
    }
}

foreach ($fileName in $parsedBlocks.Keys) {
    if (-not $sbFileLookup.ContainsKey($fileName)) {
        Write-Warning "No dest mapping found for $fileName"
        continue
    }

    $target = $sbFileLookup[$fileName].FilePath
    $targetDir = Split-Path $target -Parent

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $parsedBlocks[$fileName] | Set-Content -Path $target -Encoding UTF8

    [Console]::WriteLine("Wrote: $target")
}
}

function Bundle ($sbfilelist,$bundlefilePath)
    {
    if (Test-Path $bundlefilePath) {
        Remove-Item $bundlefilePath -Force
    }

    $bundle = [System.Collections.Generic.List[string]]::new()

    foreach ($sbfile in ($sbfilelist | Sort-Object Order)) {
        if (-not (Test-Path ($rootpath + '/' + $sbfile.RelativePath))) {
            Write-Warning "Missing file: $(($rootpath + '/' + $sbfile.RelativePath))"
            continue
        }

        $bundle.Add("#region $($sbfile.FileName)")
        $bundle.AddRange([string[]](Get-Content ($rootpath + '/' + $sbfile.RelativePath)))
        $bundle.Add("")
        $bundle.Add("#endregion")
        $bundle.Add("")
    }

    $bundle | Set-Content -Path $bundlefilePath -Encoding UTF8
    }