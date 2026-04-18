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

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$externalRoot = Join-Path $repoRoot "External/"
$nativeOpenAl =@()
if ($IsWindows) {
    $nativeOpenAl = ($externalRoot + "Silk.NET.OpenAL.Soft.Native.1.23.1/runtimes/win-x64/native/soft_oal.dll")
}
elseif ($IsLinux) {
    $nativeOpenAl = ($externalRoot + "Silk.NET.OpenAL.Soft.Native.1.23.1/runtimes/linux-x64/native/libopenal.so")
}
elseif ($IsMacOS) {
    $arch = (uname -m).trim()
    switch ($arch)
    {
        'x86_64' {$nativeOpenAl = ($externalRoot + "Silk.NET.OpenAL.Soft.Native.1.23.1/runtimes/osx-x64/native/libopenal.dylib")}
        'arm64' {$nativeOpenAl = ($externalRoot + "Silk.NET.OpenAL.Soft.Native.1.23.1/runtimes/osx-arm64/native/libopenal.dylib")}
    }   default {throw "unknown architecture for macos $($arch)"}
    
}
else {
    throw "Unsupported platform"
}
$pshomeunixcompat=$PSHOME.Replace('\','/')

function Load-RepoAssembly {
    param([string]$RelativePath)
    #this cannot be null, it's used for loading drippy and melty .cs helpers.
    [Reflection.Assembly]::LoadFrom((Join-Path $externalRoot $RelativePath))
}



Set-Location $repoRoot
[System.Environment]::CurrentDirectory = $repoRoot
$pathSeparator = [System.IO.Path]::PathSeparator
$nativeOpenAlRoot = Split-Path -Parent $nativeOpenAl
$env:PATH = "$externalRoot$pathSeparator$nativeOpenAlRoot$pathSeparator$env:PATH"
$silkCoreAssembly = Load-RepoAssembly "Silk.NET.Core.dll"
$silkOpenAlAssembly = Load-RepoAssembly "Silk.NET.OpenAL.dll"
$drippyAlAssembly = Load-RepoAssembly "DrippyAL.dll"
$meltySynthAssembly = Load-RepoAssembly "MeltySynth.dll"
$silkWindowingCommonAssembly = Load-RepoAssembly "Silk.NET.Windowing.Common.dll"
$silkWindowingGlfwAssembly = Load-RepoAssembly "Silk.NET.Windowing.Glfw.dll"
$silkInputGlfwAssembly = Load-RepoAssembly "Silk.NET.Input.Glfw.dll"
$silkGlfwAssembly = Load-RepoAssembly "Silk.NET.GLFW.dll"
$trippyGlAssembly = Load-RepoAssembly "TrippyGL.dll"
$silkOpenGlAssembly = Load-RepoAssembly "Silk.NET.OpenGL.dll"
$silkMathsAssembly = Load-RepoAssembly "Silk.NET.Maths.dll"
$silkInputCommonAssembly = Load-RepoAssembly "Silk.NET.Input.Common.dll"
$textureHelperAssembly = Load-RepoAssembly "TextureHelper/TextureHelper.dll"
$bufferHelpersAssembly = Load-RepoAssembly "BufferHelper/BufferHelpers.dll"
[System.Runtime.InteropServices.NativeLibrary]::Load($nativeOpenAl) | Out-Null
Add-Type -Path (Join-Path $externalRoot "MusicBridge.cs") -ReferencedAssemblies @(
    "$pshomeunixcompat/ref/netstandard.dll",
    "$pshomeunixcompat/ref/System.Runtime.dll",
    "$pshomeunixcompat/ref/System.Runtime.Extensions.dll",
    "$pshomeunixcompat/ref/System.Threading.dll",
    "$pshomeunixcompat/ref/System.Memory.dll",
    $drippyAlAssembly,
    $meltySynthAssembly
)
Add-Type -Path (Join-Path $externalRoot "SpanHelper.cs") -ReferencedAssemblies @(
    "$pshomeunixcompat/ref/netstandard.dll",
    "$pshomeunixcompat/ref/System.Runtime.dll",
    "$pshomeunixcompat/ref/System.Runtime.Extensions.dll",
    "$pshomeunixcompat/ref/System.Memory.dll",
    $meltySynthAssembly
)
