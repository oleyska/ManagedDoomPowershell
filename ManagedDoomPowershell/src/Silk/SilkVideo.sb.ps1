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

Add-Type -AssemblyName System.Numerics

class SilkVideo : IVideo {
    [Renderer]$Renderer
    [TrippyGL.GraphicsDevice]$Device
    [Silk.NET.OpenGL.GL]$GL
    [int]$TextureWidth
    [int]$TextureHeight
    [uint]$UploadWidth
    [uint]$UploadHeight
    [Byte[]]$TextureData
    [TrippyGL.Texture2D]$Texture
    [TrippyGL.TextureBatcher]$Batcher
    [TrippyGL.SimpleShaderProgram]$Shader
    [int]$SilkWindowWidth
    [int]$SilkWindowHeight
    [float]$TextureU
    [float]$TextureV
    [TrippyGL.VertexColorTexture]$TopLeft
    [TrippyGL.VertexColorTexture]$TopRight
    [TrippyGL.VertexColorTexture]$BottomRight
    [TrippyGL.VertexColorTexture]$BottomLeft

    static [Silk.NET.Maths.Vector2D[int]] GetDrawableSize([Silk.NET.Windowing.IWindow]$window) {
        if ($null -eq $window) {
            return [Silk.NET.Maths.Vector2D[int]]::new(0, 0)
        }

        $windowType = $window.GetType()
        $initializedProp = $windowType.GetProperty('IsInitialized')
        $framebufferProp = $windowType.GetProperty('FramebufferSize')
        $sizeProp = $windowType.GetProperty('Size')

        $isInitialized = $false
        if ($null -ne $initializedProp) {
            $isInitialized = [bool]$initializedProp.GetValue($window)
        }

        if ($isInitialized -and $null -ne $framebufferProp) {
            return $framebufferProp.GetValue($window)
        }

        if ($null -ne $sizeProp) {
            return $sizeProp.GetValue($window)
        }

        return [Silk.NET.Maths.Vector2D[int]]::new(0, 0)
    }

    SilkVideo([Config]$config, [GameContent]$content, [Silk.NET.Windowing.IWindow]$window, [Silk.NET.OpenGL.GL]$gl) {
        try {
            [Console]::Write("Initialize video: ")

            $this.Renderer = [Renderer]::new($config, $content)
            $this.GL = $gl
            $this.Device = [TrippyGL.GraphicsDevice]::new($gl)

            $this.TextureWidth = $this.Renderer.Width()
            $this.TextureHeight = $this.Renderer.Height()
            $this.UploadWidth = [uint]$this.TextureWidth
            $this.UploadHeight = [uint]$this.TextureHeight
            $this.TextureU = 1.0
            $this.TextureV = 1.0

            #$this.TextureData = New-Object 'uint[]' ($this.Renderer.Width() * $this.Renderer.Height())
            $this.TextureData = New-Object 'byte[]' (4 * $this.Renderer.Width() * $this.Renderer.Height())


            #$this.Texture = [TrippyGL.Texture2D]::new($this.Device, [uint]$this.TextureHeight,[uint]$this.TextureWidth)
            $this.Texture = [TrippyGL.Texture2D]::new($this.Device, [uint]$this.TextureWidth, [uint]$this.TextureHeight)
            #$this.Texture.SetTextureFilters("Nearest", "Nearest")
            $this.Texture.SetTextureFilters(
                [TrippyGL.TextureMinFilter]::Nearest,
                [TrippyGL.TextureMagFilter]::Nearest
            )

            $this.Batcher = [TrippyGL.TextureBatcher]::new($this.Device)
            $createMethod = [TrippyGL.SimpleShaderProgram].GetMethod("Create")
            $genericMethod = $createMethod.MakeGenericMethod([TrippyGL.VertexColorTexture])
            $this.Shader = $genericMethod.Invoke($null, @($this.Device, 0, 0, $false))
            #$this.Shader = [TrippyGL.SimpleShaderProgram]::Create([TrippyGL.VertexColorTexture], $this.Device)
            $this.Batcher.SetShaderProgram($this.Shader)

            $this.Device.BlendingEnabled = $false

            $drawSize = [SilkVideo]::GetDrawableSize($window)
            if ($drawSize.X -gt 0 -and $drawSize.Y -gt 0) {
                $this.Resize($drawSize.X, $drawSize.Y)
            }

            [Console]::WriteLine("OK")
        } catch {
            $this.Dispose()
            throw
        }
    }

    [void] Render([Doom]$doom, [Fixed]$frameFrac) {
        $this.Renderer.Render($doom, $this.TextureData, $frameFrac)

        [TextureHelper]::SetTextureData($this.Texture, $this.TextureData, 0, 0,     
        $this.UploadWidth,
        $this.UploadHeight,
        [Silk.NET.OpenGL.PixelFormat]::RGBA)

        $tl = $this.TopLeft
        $tr = $this.TopRight
        $br = $this.BottomRight
        $bl = $this.BottomLeft

        $this.Batcher.Begin()
        $this.Batcher.DrawRaw($this.Texture, [ref]$tl, [ref]$tr, [ref]$br, [ref]$bl)
        $this.Batcher.End()
    }

    [void] Resize([int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) {
            return
        }
        $this.SilkWindowWidth = $width
        $this.SilkWindowHeight = $height
        $this.Device.SetViewport(0, 0, [uint]$width, [uint]$height)
        $this.Shader.Projection = [System.Numerics.Matrix4x4]::CreateOrthographicOffCenter(0, $width, $height, 0, 0, 1)
        $this.UpdateQuadVertices()
    }

    [void] UpdateQuadVertices() {
        $this.TopLeft = [TrippyGL.VertexColorTexture]::new(
            [System.Numerics.Vector3]::new(0, 0, 0),
            [TrippyGL.Color4b]::White,
            [System.Numerics.Vector2]::new(0, 0))
        $this.TopRight = [TrippyGL.VertexColorTexture]::new(
            [System.Numerics.Vector3]::new($this.SilkWindowWidth, 0, 0),
            [TrippyGL.Color4b]::White,
            [System.Numerics.Vector2]::new($this.TextureU, 0))
        $this.BottomRight = [TrippyGL.VertexColorTexture]::new(
            [System.Numerics.Vector3]::new($this.SilkWindowWidth, $this.SilkWindowHeight, 0),
            [TrippyGL.Color4b]::White,
            [System.Numerics.Vector2]::new($this.TextureU, $this.TextureV))
        $this.BottomLeft = [TrippyGL.VertexColorTexture]::new(
            [System.Numerics.Vector3]::new(0, $this.SilkWindowHeight, 0),
            [TrippyGL.Color4b]::White,
            [System.Numerics.Vector2]::new(0, $this.TextureV))
    }

    [void] InitializeWipe() {
        $this.Renderer.InitializeWipe()
    }

    [bool] HasFocus() {
        return $true
    }

    [void] Dispose() {
        [Console]::WriteLine("Shutdown video.")

        if ($null -ne $this.Shader) {
            $this.Shader.Dispose()
            $this.Shader = $null
        }

        if ($null -ne $this.Batcher) {
            $this.Batcher.Dispose()
            $this.Batcher = $null
        }

        if ($null -ne $this.Texture) {
            $this.Texture.Dispose()
            $this.Texture = $null
        }

        if ($null -ne $this.Device) {
            $this.Device.Dispose()
            $this.Device = $null
        }
    }

    [int] get_WipeBandCount() {
        return $this.Renderer.WipeBandCount()
    }

    [int] get_WipeHeight() {
        return $this.Renderer.WipeHeight()
    }

    [int] get_MaxWindowSize() {
        return $this.Renderer.MaxWindowSize()
    }

    [int] get_WindowSize() {
        return $this.Renderer.GetWindowSize()
    }

    [void] set_WindowSize([int]$value) {
        $this.Renderer.SetWindowSize($value)
    }

    [bool] get_DisplayMessage() {
        return $this.Renderer.GetDisplayMessage()
    }

    [void] set_DisplayMessage([bool]$value) {
        $this.Renderer.SetDisplayMessage($value)
    }

    [int] get_MaxGammaCorrectionLevel() {
        return $this.Renderer.MaxGammaCorrectionLevel()
    }

    [int] get_GammaCorrectionLevel() {
        return $this.Renderer.GetGammaCorrectionLevel()
    }

    [void] set_GammaCorrectionLevel([int]$value) {
        $this.Renderer.SetGammaCorrectionLevel($value)
    }
}
