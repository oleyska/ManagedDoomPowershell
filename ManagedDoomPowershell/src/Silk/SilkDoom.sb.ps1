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

class SilkDoom : IDisposable {
    hidden static [bool]$PlatformsRegistered = $false

    [CommandLineArgs] $inargs
    [Config] $config
    [GameContent] $content
    [Silk.NET.Windowing.IWindow] $window
    [Silk.NET.OpenGL.GL] $gl
    [SilkVideo] $video
    [DrippyAL.AudioDevice] $audioDevice
    [SilkSound] $sound
    [SilkMusic] $music
    [SilkUserInput] $userInput
    [Doom] $doom
    [int] $fpsScale
    [int] $frameCount
    [Exception] $lastException
    [int] $debugLoopCount
    [bool] $benchmarksEnabled
    [int] $benchmarkInterval
    [int] $benchmarkLoopCount
    [long] $benchmarkLoopTicks
    [long] $benchmarkDoEventsTicks
    [long] $benchmarkResizeTicks
    [long] $benchmarkUpdateTicks
    [long] $benchmarkRenderTicks
    [long] $benchmarkSleepTicks
    [long] $benchmarkPollTicks
    [long] $benchmarkDoomUpdateTicks
    [long] $benchmarkVideoRenderTicks
    [long] $benchmarkSwapTicks

    SilkDoom([CommandLineArgs] $inargs) #should be [CommandLineArgs]$inargs but powershell is broken shit.
     {
        try {
            #$this.inargs = [CommandLineArgs]::new($inargs)
            $this.inargs = $inargs
            if (-not [SilkDoom]::PlatformsRegistered) {
                [Silk.NET.Windowing.Glfw.GlfwWindowing]::RegisterPlatform()
                [Silk.NET.Input.Glfw.GlfwInput]::RegisterPlatform()
                [Silk.NET.Windowing.Window]::PrioritizeGlfw()
                [SilkDoom]::PlatformsRegistered = $true
            }
            if ($this.inargs -isnot [CommandLineArgs] -and $null -ne $this.inargs) {
                [Console]::WriteLine("Received args type: $($this.inargs.GetType().FullName)")
                throw "Failed to cast args to CommandLineArgs!"
            }

            $this.config = [SilkConfigUtilities]::GetConfig()
            $this.content = [GameContent]::new($this.inargs)
            $this.benchmarkInterval = 120
            $this.benchmarksEnabled = ($env:DOOM_POWERSHELL_BENCHMARKS -eq '1' -or $env:DOOM_POWERSHELL_BENCHMARKS -eq 'true')

            $this.config.video_screenwidth = [math]::Clamp($this.config.video_screenwidth, 320, 3200)
            $this.config.video_screenheight = [math]::Clamp($this.config.video_screenheight, 200, 2000)

            $windowOptions = [Silk.NET.Windowing.WindowOptions]::Default
            $windowOptions.Size = [Silk.NET.Maths.Vector2D[int]]::new($this.config.video_screenwidth, $this.config.video_screenheight)
            $windowOptions.Title = [ApplicationInfo]::Title
            $windowOptions.VSync = $false
            $windowOptions.WindowState = $(if ($this.config.video_fullscreen) { [Silk.NET.Windowing.WindowState]::Fullscreen } else { [Silk.NET.Windowing.WindowState]::Normal })
            $this.window = [Silk.NET.Windowing.Window]::Create($windowOptions)

        } catch {
            $this.Dispose()
            throw
        }
    }

    hidden [double] TicksToMilliseconds([long] $ticks) {
        if ($ticks -eq 0) {
            return 0.0
        }

        return ($ticks * 1000.0) / [System.Diagnostics.Stopwatch]::Frequency
    }

    hidden [void] ResetBenchmarks() {
        $this.benchmarkLoopCount = 0
        $this.benchmarkLoopTicks = 0
        $this.benchmarkDoEventsTicks = 0
        $this.benchmarkResizeTicks = 0
        $this.benchmarkUpdateTicks = 0
        $this.benchmarkRenderTicks = 0
        $this.benchmarkSleepTicks = 0
        $this.benchmarkPollTicks = 0
        $this.benchmarkDoomUpdateTicks = 0
        $this.benchmarkVideoRenderTicks = 0
        $this.benchmarkSwapTicks = 0
    }

    hidden [void] LogBenchmarksIfNeeded() {
        if (-not $this.benchmarksEnabled) {
            return
        }

        if ($this.benchmarkLoopCount -lt $this.benchmarkInterval) {
            return
        }

        $count = [double]$this.benchmarkLoopCount
        $line = "Bench loops={0} avgMs total={1:N2} events={2:N2} resize={3:N2} update={4:N2} poll={5:N2} doom={6:N2} render={7:N2} video={8:N2} swap={9:N2} sleep={10:N2}" -f `
            $this.benchmarkLoopCount, `
            ($this.TicksToMilliseconds($this.benchmarkLoopTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkDoEventsTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkResizeTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkUpdateTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkPollTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkDoomUpdateTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkRenderTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkVideoRenderTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkSwapTicks) / $count), `
            ($this.TicksToMilliseconds($this.benchmarkSleepTicks) / $count)
        [Console]::WriteLine($line)

        $this.ResetBenchmarks()
    }

    [void] Quit() {
        if ($null -ne $this.lastException) {
            [Console]::WriteLine("Stored exception type: " + $this.lastException.GetType().FullName)
            [Console]::WriteLine("Stored exception text: " + $this.lastException.ToString())
            throw $this.lastException
        }
    }

    [void] OnLoad() {
        $this.gl = [Silk.NET.OpenGL.GL]::GetApi($this.window)
        if ($null -eq $this.gl) {
            throw "Failed to initialize OpenGL!"
        }

        $this.gl.ClearColor(0.15, 0.15, 0.15, 1)
        $this.gl.Clear([Silk.NET.OpenGL.ClearBufferMask]::ColorBufferBit)
        $this.window.GLContext.SwapBuffers()

        $this.video = [SilkVideo]::new($this.config, $this.content, $this.window, $this.gl)

        if (-not $this.inargs.nosound.Present -and -not ($this.inargs.nosfx.Present -and $this.inargs.nomusic.Present)) {
            $this.audioDevice = [DrippyAL.AudioDevice]::new()
            if (-not $this.inargs.nosfx.Present) {
                $this.sound = [SilkSound]::new($this.config, $this.content, $this.audioDevice)
            }
            if (-not $this.inargs.nomusic.Present) {
                $this.music = [SilkConfigUtilities]::GetMusicInstance($this.config, $this.content, $this.audioDevice)
            }
        }

        $this.userInput = [SilkUserInput]::new($this.config, $this.window, $this, -not $this.inargs.nomouse.Present)

        $this.doom = [Doom]::new($this.inargs, $this.config, $this.content, $this.video, $this.sound, $this.music, $this.userInput)

        $this.fpsScale = $(if ($this.inargs.timedemo.Present) { 1 } else { $this.config.video_fpsscale })
        $this.frameCount = -1
    }

    hidden [void] OnUpdate([double] $obj) {
        try {
            if (-not $this.benchmarksEnabled) {
                $this.frameCount++
                $this.userInput.PollEvents()
                if ($this.frameCount % $this.fpsScale -eq 0) {
                    $updateResult = $this.doom.Update()
                    if ($updateResult -eq [UpdateResult]::Completed) {
                        $this.window.Close()
                    }
                }
            } else {
                $pollStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.frameCount++
                $this.userInput.PollEvents()
                $this.benchmarkPollTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $pollStart
                if ($this.frameCount % $this.fpsScale -eq 0) {
                    $updateStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                    $updateResult = $this.doom.Update()
                    $this.benchmarkDoomUpdateTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $updateStart
                    if ($updateResult -eq [UpdateResult]::Completed) {
                        $this.window.Close()
                    }
                }
            }
        } catch {
            [Console]::WriteLine("OnUpdate exception: " + $_.Exception.ToString())
            if ($null -ne $_.InvocationInfo) {
                [Console]::WriteLine("OnUpdate position: " + $_.InvocationInfo.PositionMessage)
            }
            if ($null -ne $_.ScriptStackTrace) {
                [Console]::WriteLine("OnUpdate stack: " + $_.ScriptStackTrace)
            }
            $this.lastException = $_.Exception
        }

        if ($null -ne $this.lastException) {
            $this.window.Close()
        }
    }
    
    

    hidden [void] OnRender([double] $obj) {
        try {
            $frameFrac = [Fixed]::FromInt(($this.frameCount % $this.fpsScale) + 1) / $this.fpsScale
            if (-not $this.benchmarksEnabled) {
                $this.video.Render($this.doom, $frameFrac)
                $this.window.GLContext.SwapBuffers()
            } else {
                $renderStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.video.Render($this.doom, $frameFrac)
                $this.benchmarkVideoRenderTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $renderStart
                $swapStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.window.GLContext.SwapBuffers()
                $this.benchmarkSwapTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $swapStart
            }
        } catch {
            [Console]::WriteLine("OnRender exception: " + $_.Exception.ToString())
            if ($null -ne $_.InvocationInfo) {
                [Console]::WriteLine("OnRender position: " + $_.InvocationInfo.PositionMessage)
            }
            if ($null -ne $_.ScriptStackTrace) {
                [Console]::WriteLine("OnRender stack: " + $_.ScriptStackTrace)
            }
            $this.lastException = $_.Exception
        }
    }

    hidden [void] OnResize([Silk.NET.Maths.Vector2D[int]] $obj) {
        if ($null -ne $this.video) {
            $drawSize = $this.GetDrawableSize()
            if ($drawSize.X -gt 0 -and $drawSize.Y -gt 0) {
                $this.video.Resize($drawSize.X, $drawSize.Y)
            }
        }
    }

    hidden [Silk.NET.Maths.Vector2D[int]] GetDrawableSize() {
        if ($null -eq $this.window) {
            return [Silk.NET.Maths.Vector2D[int]]::new(0, 0)
        }

        $windowType = $this.window.GetType()
        $initializedProp = $windowType.GetProperty('IsInitialized')
        $framebufferProp = $windowType.GetProperty('FramebufferSize')
        $sizeProp = $windowType.GetProperty('Size')

        $isInitialized = $false
        if ($null -ne $initializedProp) {
            $isInitialized = [bool]$initializedProp.GetValue($this.window)
        }

        if ($isInitialized -and $null -ne $framebufferProp) {
            return $framebufferProp.GetValue($this.window)
        }

        if ($null -ne $sizeProp) {
            return $sizeProp.GetValue($this.window)
        }

        return [Silk.NET.Maths.Vector2D[int]]::new(0, 0)
    }

    hidden [void] OnClose() {
        if ($null -ne $this.userInput) {
            $this.userInput.Dispose()
            $this.userInput = $null
        }

        if ($null -ne $this.music) {
            $this.music.Dispose()
            $this.music = $null
        }

        if ($null -ne $this.sound) {
            $this.sound.Dispose()
            $this.sound = $null
        }

        if ($null -ne $this.audioDevice) {
            $this.audioDevice.Dispose()
            $this.audioDevice = $null
        }

        if ($null -ne $this.video) {
            $this.video.Dispose()
            $this.video = $null
        }

        if ($null -ne $this.gl) {
            $this.gl.Dispose()
            $this.gl = $null
        }

        $this.config.Save([ConfigUtilities]::GetConfigPath())
    }

    [void] KeyDown([Silk.NET.Input.Key] $key) {
        $this.doom.PostEvent([DoomEvent]::new([EventType]::KeyDown, [SilkUserInput]::SilkToDoom($key)))
    }

    [void] KeyUp([Silk.NET.Input.Key] $key) {
        $this.doom.PostEvent([DoomEvent]::new([EventType]::KeyUp, [SilkUserInput]::SilkToDoom($key)))
    }

    [void] Dispose() {
        if ($null -ne $this.window) {
            $this.window.Close()
            $this.window.Dispose()
            $this.window = $null
        }
    }
    [void] Run() {
        $this.config.video_fpsscale = [Math]::Clamp($this.config.video_fpsscale, 1, 100)
        $targetFps = 35 * $this.config.video_fpsscale

        $this.window.FramesPerSecond = 0
        $this.window.UpdatesPerSecond = 0

        if ($this.window.IsInitialized -eq $false) {
            [Console]::WriteLine("Initializing Window")
            $this.window.Initialize()
            $this.window.ShouldSwapAutomatically = $false
            $this.OnLoad()
        }

        [Console]::WriteLine("Window Initialized? $($this.window.IsInitialized)")
        [Console]::WriteLine("Calling while loop...")

        $gameTime = [TimeSpan]::Zero
        $gameTimeStep = [TimeSpan]::FromSeconds(1.0 / $targetFps)

        $sw = [System.Diagnostics.Stopwatch]::new()
        $sw.Start()
        if ($this.benchmarksEnabled) {
            $this.ResetBenchmarks()
        }

        while (-not $this.window.IsClosing) {
            if (-not $this.benchmarksEnabled) {
                $this.window.DoEvents()

                if (-not $this.window.IsClosing) {
                    $this.OnResize([Silk.NET.Maths.Vector2D[int]]::new(0, 0))
                    $this.OnUpdate(0)
                    $gameTime += $gameTimeStep
                }

                if (-not $this.window.IsClosing) {
                    $this.OnRender(0)
                    $sleepTime = $gameTime - $sw.Elapsed
                    $ms = [int]$sleepTime.TotalMilliseconds
                    if ($ms -gt 0) {
                        [System.Threading.Thread]::Sleep($ms)
                    }
                } else {
                    break
                }

                continue
            }

            $loopStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
            $doEventsStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
            $this.window.DoEvents()
            $this.benchmarkDoEventsTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $doEventsStart

            if (-not $this.window.IsClosing) {
                $resizeStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.OnResize([Silk.NET.Maths.Vector2D[int]]::new(0, 0))
                $this.benchmarkResizeTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $resizeStart
                $updateStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.OnUpdate(0)
                $this.benchmarkUpdateTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $updateStart
                $gameTime += $gameTimeStep
            }

            if (-not $this.window.IsClosing) {
                $renderStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                $this.OnRender(0)
                $this.benchmarkRenderTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $renderStart
                $sleepTime = $gameTime - $sw.Elapsed
                $ms = [int]$sleepTime.TotalMilliseconds
                if ($ms -gt 0) {
                    $sleepStart = [System.Diagnostics.Stopwatch]::GetTimestamp()
                    [System.Threading.Thread]::Sleep($ms)
                    $this.benchmarkSleepTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $sleepStart
                }
            } else {
                break
            }

            $this.benchmarkLoopTicks += [System.Diagnostics.Stopwatch]::GetTimestamp() - $loopStart
            $this.benchmarkLoopCount++
            $this.LogBenchmarksIfNeeded()
        }

        $this.window.DoEvents()
        $this.OnClose()
        $this.window.Reset()

        $this.Quit()
    }
    

    [string] get_QuitMessage() { return $this.doom.QuitMessage }
    [Exception] get_Exception() { return $this.lastException }
}
