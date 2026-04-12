class SilkProgram {
    static [void] Main([string[]]$args) {
        [System.Console]::ForegroundColor = "White"
        [System.Console]::BackgroundColor = "DarkGreen"
        [Console]::WriteLine([ApplicationInfo]::Title)
        [System.Console]::ResetColor()

        try {
            $quitMessage = $null
            # $app = [SilkDoom]::new([CommandLineArgs]$($mArgs)) SHOULD have been the right way, powershell is stupid...
            $mArgs = [CommandLineArgs]::new($args)
            $app = [SilkDoom]::new($mArgs)
            

            try {
                $app.Run()
                $quitMessage = $app.QuitMessage
            } finally {
                $app.Dispose()
            }

            if ($null -ne $quitMessage) {
                [System.Console]::ForegroundColor = "Green"
                [Console]::WriteLine($quitMessage)
                [System.Console]::ResetColor()
                [Console]::WriteLine("Press any key to exit...")
                [System.Console]::ReadKey()
            }
        } catch {
            [System.Console]::ForegroundColor = "Red"
            [Console]::WriteLine($_.Exception.ToString())
            [System.Console]::ResetColor()
            [Console]::WriteLine("Press any key to exit...")
            [System.Console]::ReadKey()
        }
    }
}