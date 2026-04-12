class SilkConfigUtilities {
    static [Config] GetConfig() {
        $config = [Config]::new([ConfigUtilities]::GetConfigPath())

        if (-not $config.IsRestoredFromFile) {
            $vm = [SilkConfigUtilities]::GetDefaultVideoMode()
            $config.video_screenwidth = $vm.Resolution.X
            $config.video_screenheight = $vm.Resolution.Y
        }

        return $config
    }

    static [Silk.NET.Windowing.VideoMode] GetDefaultVideoMode() {
        $monitor = [Silk.NET.Windowing.Monitor]::GetMainMonitor($null)

        $baseWidth = 640
        $baseHeight = 400

        $currentWidth = $baseWidth
        $currentHeight = $baseHeight

        while ($true) {
            $nextWidth = $currentWidth + $baseWidth
            $nextHeight = $currentHeight + $baseHeight

            if ($nextWidth -ge (0.9 * $monitor.VideoMode.Resolution.X) -or
                $nextHeight -ge (0.9 * $monitor.VideoMode.Resolution.Y)) {
                break
            }

            $currentWidth = $nextWidth
            $currentHeight = $nextHeight
        }

        return [Silk.NET.Windowing.VideoMode]::new([Silk.Net.Maths.Vector2D[int]]::new($currentWidth, $currentHeight))
    }

    static [object] GetMusicInstance([object]$config, [object]$content, [object]$device) {
        $sfPath = [System.IO.Path]::Combine([ConfigUtilities]::GetExeDirectory(), $config.audio_soundfont)
        
        if ([System.IO.File]::Exists($sfPath)) {
            return [SilkMusic]::new($config, $content, $device, $sfPath)
        } else {
            [Console]::WriteLine("SoundFont '$($config.audio_soundfont)' was not found!")
            return $null
        }
    }
}