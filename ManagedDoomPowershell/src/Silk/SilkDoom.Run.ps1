class SilkDoom {
    [object]$Config
    [object]$Args
    [object]$Window

    SilkDoom([object]$config, [object]$args, [object]$window) {
        $this.Config = $config
        $this.Args = $args
        $this.Window = $window
    }

    [void] Run() {
        $this.Config.video_fpsscale = [math]::Max(1, [math]::Min($this.Config.video_fpsscale, 100))
        $targetFps = 35 * $this.Config.video_fpsscale

        $this.Window.FramesPerSecond = 0
        $this.Window.UpdatesPerSecond = 0

        if ($this.Args.timedemo.Present) {
            $this.Window.Run()
        } else {
            $this.Window.Initialize()

            $gameTime = [TimeSpan]::Zero
            $gameTimeStep = [TimeSpan]::FromSeconds(1.0 / $targetFps)

            $sw = [System.Diagnostics.Stopwatch]::new()
            $sw.Start()

            while ($true) {
                $this.Window.DoEvents()

                if (-not $this.Window.IsClosing) {
                    $this.Window.DoUpdate()
                    $gameTime += $gameTimeStep
                }

                if (-not $this.Window.IsClosing) {
                    if ($sw.Elapsed -lt $gameTime) {
                        $this.Window.DoRender()
                        $sleepTime = $gameTime - $sw.Elapsed
                        $ms = [int]$sleepTime.TotalMilliseconds
                        if ($ms -gt 0) {
                            [WinMmTimer]::Sleep($ms)
                        }
                    }
                } else {
                    break
                }
            }

            $this.Window.DoEvents()
            $this.Window.Reset()
        }

        $this.Quit()
    }

    [void] Quit() {
        [Console]::WriteLine("Quitting SilkDoom...")
    }
}