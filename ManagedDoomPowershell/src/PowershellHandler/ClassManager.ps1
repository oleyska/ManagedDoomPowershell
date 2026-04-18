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

$PowershellFiles = gci ..\ -Recurse | select name,fullname,psiscontainer,extension,DirectoryName | ? {$_.psiscontainer -eq $false -and $_.fullname -notlike '*PowershellHandler*' -and $_.fullname -notlike "*pwshtestlab*" -and $_.extension -eq '.ps1' -and $_.name -notlike '*.sb.ps1'}

class ScriptFiles {
    [ScriptFile[]] $files =@()
}
class ScriptFile {
    [string] $filename
    [string] $fullpath
    [bool] $hasDependency = $false
    [Dependency[]] $dependencies = @()
    [Definition[]] $definitions = @()

    ScriptFile([string]$filename,[string]$fullpath)
        {
            $this.filename = $filename 
            $this.fullpath = $fullpath
            $this.dependencies = @()
            $this.definitions = @()
        }
}
class Dependency{
    [string] $name

    Dependency($name)  
        {
            $this.name = $name
        }
}

Class Definition {
    [string] $name
    Definition($name)  
    {
        $this.name = $name
    }
}

$excludedTypes = [AppDomain]::CurrentDomain.GetAssemblies() |
    ForEach-Object {
        try {
            $_.GetTypes()
        }
        catch {
        }
    } | Select-Object -ExpandProperty FullName |
    ForEach-Object { "[{0}]" -f $_ } |
    Sort-Object -Unique

function Get-TypesFromFile {
    param (
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    $content = Get-Content -Path $FilePath -Raw
    if ($content -match '\[\]') 
        {
        $content = $content -replace '\[\]', ''  # Remove `[]` if we have an array of type
        }

    if ($content -notmatch '\[') {
        return
    }
    
    $matches = [regex]::Matches($content, '\[\s*([a-zA-Z0-9_\.]+)\s*\]')


    $types = @()
    foreach ($match in $matches) {
        $typeWithoutBrackets = $match.Groups[1].Value


        if ($typeWithoutBrackets -match '^\d+$') {
            continue
        }
        #skip system.
        if ($match.value -like '*system.*')
            {continue}
        $types += $match.Value
    }

    return $types | Sort-Object -Unique
}
function Get-ClassOrEnumFromFile {
    param (
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    $content = Get-Content -Path $FilePath -Raw
    if ($content -notlike '*{*') {
        return
    }
    
    $regexPattern = '(?im)^\s*(?:class|enum)\s+([a-zA-Z_][a-zA-Z0-9_]*)'
    $matchess = [regex]::Matches($content, $regexPattern)

    $definitions = @()
    foreach ($match in $matchess) {
        $definitions += "[" + $match.Groups[1].Value + "]"
    }

    return $definitions | Sort-Object -Unique
}

$loadedDependencies = @()
$loadedfiles = @()
$failedFiles = @()

$files = [ScriptFiles]::new()
foreach ($file in $PowershellFiles)
    {
        $types = Get-TypesFromFile $file.FullName
        $definitions = Get-ClassOrEnumFromFile $file.FullName
        $scriptfile = [ScriptFile]::new($file.Name,$file.FullName)

        foreach ($type in $types | ? {$_ -notin $excludedTypes})
            {
               $dependency = [Dependency]::new($type)
               $scriptfile.dependencies+=$dependency
            }
        if ($scriptfile.dependencies -and $scriptfile.dependencies.count -ge 1)
            {
                $scriptfile.hasDependency = $true
            }
        if ($definitions)
            {
                foreach ($definition in $definitions)
                    {
                        $def = [Definition]::new($definition)
                        $scriptfile.definitions += $def
                    }
            }
        $files.files += $scriptfile
    }

foreach ($dependency in $files.files.dependencies.name)
    {
        if ($dependency -in $files.files.definitions.name -or $dependency -in $loadedDependencies)
            {continue}
            $sb=[scriptblock]::create($dependency)
            try{
            & $sb | Out-Null 
            $loadedDependencies += $dependency
            }
            catch{
                [Console]::WriteLine($error[0].Exception)
            }       
    }

# load all without dependencies or dependency and definition are equal.
foreach ($file in $files.files | ? {$_.hasDependency -eq $false -and $_.fullpath -notin $loadedfiles})
    {
    try {
        . $file.fullpath
        foreach ($definition in $file.definitions)
            {
            $loadedDependencies +=  $definition.name 
            }
        $loadedfiles += $file.fullpath
        }
        catch {
            [Console]::WriteLine("unable to load $($file.filename) - $($file.fullpath)")
            $failedFiles += $file.fullpath
        }
}

$Loopcounter = 0
while ($Loopcounter -lt 6)
{
foreach ($file in $files.files |  ? {$_.hasDependency -eq $true -and $_.fullpath -notin $loadedfiles})
    {

        $missingDeps = $file.dependencies.name | Where-Object { $_ -notin $loadedDependencies -and $_ -notin $file.definitions.name }
        if ($missingDeps.count -gt 0)
            {continue}
            try {
            . $file.fullpath
            foreach ($definition in $file.definitions)
                {
                $loadedDependencies +=  $definition.name 
                }
            $loadedfiles += $file.fullpath
            }
            catch {
                [Console]::WriteLine("unable to load - $($file.fullpath)")
            }
    }
$Loopcounter++
}