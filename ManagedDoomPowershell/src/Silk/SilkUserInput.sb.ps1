class SilkUserInput : IUserInput {
    [Config] $Config
    [Silk.NET.Windowing.IWindow] $Window
    [silkdoom] $Doom
    [Silk.NET.Input.IInputContext] $Input
    [Silk.NET.Input.IKeyboard] $Keyboard
    [Silk.NET.Input.Key[]] $TrackedKeys
    [hashtable] $PreviousKeyStates
    [bool[]] $WeaponKeys
    [int] $TurnHeld
    [int] $DebugCmdCount

    [Silk.NET.Input.IMouse] $Mouse
    [bool] $MouseGrabbed
    [float] $MouseX
    [float] $MouseY
    [float] $MousePrevX
    [float] $MousePrevY
    [float] $MouseDeltaX
    [float] $MouseDeltaY
    [int] $MaxMouseSensitivity = 15

    SilkUserInput([Config] $config, [Silk.NET.Windowing.IWindow] $window, [SilkDoom] $doom, [bool] $useMouse) {
        try {
            [Console]::Write("Initialize user input: ")

            $this.Config = $config
            $this.Window = $window
            $this.Doom = $doom

            $method = [Silk.NET.Input.InputWindowExtensions].GetMethod("CreateInput", [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
            $this.input = $method.Invoke($null, @($window))
            $this.Keyboard = $this.Input.Keyboards[0]
            $this.TrackedKeys = @()
            $this.PreviousKeyStates = @{}
            $doomKeysEnumerable = [enum]::GetValues([DoomKey])
            if ($null -ne $doomKeysEnumerable) {
                $doomKeysEnumerator = $doomKeysEnumerable.GetEnumerator()
                for (; $doomKeysEnumerator.MoveNext(); ) {
                    $doomKey = $doomKeysEnumerator.Current
                    if ($doomKey -in @([DoomKey]::Unknown, [DoomKey]::Count)) {
                        continue
                    }

                    $silkKey = [SilkUserInput]::DoomToSilk($doomKey)
                    if ($silkKey -eq [Silk.NET.Input.Key]::Unknown -or $silkKey -in $this.TrackedKeys) {
                        continue
                    }

                    $this.TrackedKeys += $silkKey
                    $this.PreviousKeyStates[$silkKey] = $false

                }
            }

            $this.WeaponKeys = New-Object 'bool[]' 7
            $this.TurnHeld = 0
            $this.DebugCmdCount = 0

            if ($useMouse) {
                $this.Mouse = $this.Input.Mice[0]
                $this.MouseGrabbed = $false
            }

            [Console]::WriteLine("OK")
        }
        catch {
            [Console]::WriteLine("Failed")
            $this.Dispose()
            throw $_
        }
    }
    [void] PollEvents() {
        if ($null -eq $this.Keyboard -or $null -eq $this.Doom) {
            return
        }

        $trackedKeysEnumerable = $this.TrackedKeys
        if ($null -ne $trackedKeysEnumerable) {
            $trackedKeysEnumerator = $trackedKeysEnumerable.GetEnumerator()
            for (; $trackedKeysEnumerator.MoveNext(); ) {
                $key = $trackedKeysEnumerator.Current
                $isPressed = $this.Keyboard.IsKeyPressed($key)
                $wasPressed = [bool]$this.PreviousKeyStates[$key]

                if ($isPressed -and -not $wasPressed) {
                    $this.Doom.KeyDown($key)
                } elseif (-not $isPressed -and $wasPressed) {
                    $this.Doom.KeyUp($key)
                }

                $this.PreviousKeyStates[$key] = $isPressed

            }
        }
    }
    [void] BuildTicCmd([TicCmd] $cmd) {
        $keyForward = $this.IsPressed($this.Keyboard, $this.Config.key_forward)
        $keyBackward = $this.IsPressed($this.Keyboard, $this.Config.key_backward)
        $keyStrafeLeft = $this.IsPressed($this.Keyboard, $this.Config.key_strafeleft)
        $keyStrafeRight = $this.IsPressed($this.Keyboard, $this.Config.key_straferight)
        $keyTurnLeft = $this.IsPressed($this.Keyboard, $this.Config.key_turnleft)
        $keyTurnRight = $this.IsPressed($this.Keyboard, $this.Config.key_turnright)
        $keyFire = $this.IsPressed($this.Keyboard, $this.Config.key_fire)
        $keyUse = $this.IsPressed($this.Keyboard, $this.Config.key_use)
        $keyRun = $this.IsPressed($this.Keyboard, $this.Config.key_run)
        $keyStrafe = $this.IsPressed($this.Keyboard, $this.Config.key_strafe)
    
        $this.WeaponKeys[0] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number1)
        $this.WeaponKeys[1] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number2)
        $this.WeaponKeys[2] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number3)
        $this.WeaponKeys[3] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number4)
        $this.WeaponKeys[4] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number5)
        $this.WeaponKeys[5] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number6)
        $this.WeaponKeys[6] = $this.Keyboard.IsKeyPressed([Silk.NET.Input.Key]::Number7)
    
        $cmd.Clear()
    
        $strafe = $keyStrafe
        $speed = if ($keyRun) { 1 } else { 0 }
        $forward = 0
        $side = 0
    
        if ($this.Config.game_alwaysrun) {
            $speed = 1 - $speed
        }
    
        if ($keyTurnLeft -or $keyTurnRight) {
            $this.TurnHeld++
        } else {
            $this.TurnHeld = 0
        }
    
        if ($this.TurnHeld -lt [PlayerBehavior]::SlowTurnTics) {
            $turnSpeed = 2
        } else {
            $turnSpeed = $speed
        }
    
        if ($strafe) {
            if ($keyTurnRight) { $side += [PlayerBehavior]::SideMove[$speed] }
            if ($keyTurnLeft) { $side -= [PlayerBehavior]::SideMove[$speed] }
        } else {
            if ($keyTurnRight) { $cmd.AngleTurn -= [short][PlayerBehavior]::AngleTurn[$turnSpeed] }
            if ($keyTurnLeft) { $cmd.AngleTurn += [short][PlayerBehavior]::AngleTurn[$turnSpeed] }
        }
    
        if ($keyForward) { $forward += [PlayerBehavior]::ForwardMove[$speed] }
        if ($keyBackward) { $forward -= [PlayerBehavior]::ForwardMove[$speed] }
    
        if ($keyStrafeLeft) { $side -= [PlayerBehavior]::SideMove[$speed] }
        if ($keyStrafeRight) { $side += [PlayerBehavior]::SideMove[$speed] }
    
        if ($keyFire) { $cmd.Buttons = $cmd.Buttons -bor [TicCmdButtons]::Attack }
        if ($keyUse) { $cmd.Buttons = $cmd.Buttons -bor [TicCmdButtons]::Use }

        # Check weapon keys
        for ($i = 0; $i -lt $this.WeaponKeys.Length; $i++) {
            if ($this.WeaponKeys[$i]) {
                $cmd.Buttons = $cmd.Buttons -bor [TicCmdButtons]::Change
                $cmd.Buttons = $cmd.Buttons -bor ([byte]($i -shl [TicCmdButtons]::WeaponShift))
                break
            }
        }
    
        $this.UpdateMouse()
        $ms = 0.5 * $this.Config.mouse_sensitivity
        $mx = [math]::Round($ms * $this.MouseDeltaX)
        $my = [math]::Round($ms * -$this.MouseDeltaY)
        $forward += $my
    
        if ($strafe) {
            $side += $mx * 2
        } else {
            $cmd.AngleTurn = [SilkUserInput]::ToInt16Unchecked(([int]$cmd.AngleTurn) - ($mx * 0x8))
        }
    
        $forward = [math]::Clamp($forward, -[PlayerBehavior]::MaxMove, [PlayerBehavior]::MaxMove)
        $side = [math]::Clamp($side, -[PlayerBehavior]::MaxMove, [PlayerBehavior]::MaxMove)
    
        $cmd.ForwardMove += [sbyte]$forward
        $cmd.SideMove += [sbyte]$side
    }
    
    [bool] IsPressed([Silk.NET.Input.IKeyboard] $keyboard, [KeyBinding] $keyBinding) {
        $bindingKeysEnumerable = $keyBinding.Keys
        if ($null -ne $bindingKeysEnumerable) {
            $bindingKeysEnumerator = $bindingKeysEnumerable.GetEnumerator()
            for (; $bindingKeysEnumerator.MoveNext(); ) {
                $key = $bindingKeysEnumerator.Current
                if ($keyboard.IsKeyPressed([SilkUserInput]::DoomToSilk($key))) {
                    return $true
                }

            }
        }
    
        if ($this.MouseGrabbed) {
            $bindingMouseButtonsEnumerable = $keyBinding.MouseButtons
            if ($null -ne $bindingMouseButtonsEnumerable) {
                $bindingMouseButtonsEnumerator = $bindingMouseButtonsEnumerable.GetEnumerator()
                for (; $bindingMouseButtonsEnumerator.MoveNext(); ) {
                    $mouseButton = $bindingMouseButtonsEnumerator.Current
                    if ($this.Mouse.IsButtonPressed([Silk.NET.Input.MouseButton]$mouseButton)) {
                        return $true
                    }

                }
            }
        }
    
        return $false
    }
    [void] Reset() {
        if ($null -eq $this.Mouse) {
            return
        }
    
        $this.MouseX = $this.Mouse.Position.X
        $this.MouseY = $this.Mouse.Position.Y
        $this.MousePrevX = $this.MouseX
        $this.MousePrevY = $this.MouseY
        $this.MouseDeltaX = 0
        $this.MouseDeltaY = 0
        $this.DebugCmdCount = 0
    }
    
    [void] GrabMouse() {
        if ($null -eq $this.Mouse) {
            return
        }
    
        if (-not $this.MouseGrabbed) {
            $this.Mouse.Cursor.CursorMode = [Silk.NET.Input.CursorMode]::Raw
            $this.MouseGrabbed = $true
            $this.MouseX = $this.Mouse.Position.X
            $this.MouseY = $this.Mouse.Position.Y
            $this.MousePrevX = $this.MouseX
            $this.MousePrevY = $this.MouseY
            $this.MouseDeltaX = 0
            $this.MouseDeltaY = 0
        }
    }
    
    [void] ReleaseMouse() {
        if ($null -eq $this.Mouse) {
            return
        }
    
        if ($this.MouseGrabbed) {
            $this.Mouse.Cursor.CursorMode = [Silk.NET.Input.CursorMode]::Normal
            $this.Mouse.Position = [System.Numerics.Vector2]::new($this.Window.Size.X - 10, $this.Window.Size.Y - 10)
            $this.MouseGrabbed = $false
        }
    }
    [void] UpdateMouse() {
        if ($null -eq $this.Mouse) {
            return
        }
    
        if ($this.MouseGrabbed) {
            $this.MousePrevX = $this.MouseX
            $this.MousePrevY = $this.MouseY
            $this.MouseX = $this.Mouse.Position.X
            $this.MouseY = $this.Mouse.Position.Y
            $this.MouseDeltaX = $this.MouseX - $this.MousePrevX
            $this.MouseDeltaY = $this.MouseY - $this.MousePrevY
    
            if ($this.Config.mouse_disableyaxis) {
                $this.MouseDeltaY = 0
            }
        }
    }
    
    [void] Dispose() {
        [Console]::WriteLine("Shutdown user input.")
    
        if ($null -ne $this.Input) {
            $this.Input.Dispose()
            $this.Input = $null
        }
    }

    static [Silk.NET.Input.Key] DoomToSilk([DoomKey] $doomKey) {
        switch ($doomKey) {
            ([DoomKey]::Space) { return [Silk.NET.Input.Key]::Space }
            ([DoomKey]::Comma) { return [Silk.NET.Input.Key]::Comma }
            ([DoomKey]::Subtract) { return [Silk.NET.Input.Key]::Minus }
            ([DoomKey]::Period) { return [Silk.NET.Input.Key]::Period }
            ([DoomKey]::Slash) { return [Silk.NET.Input.Key]::Slash }
            ([DoomKey]::Num0) { return [Silk.NET.Input.Key]::Number0 }
            ([DoomKey]::Num1) { return [Silk.NET.Input.Key]::Number1 }
            ([DoomKey]::Num2) { return [Silk.NET.Input.Key]::Number2 }
            ([DoomKey]::Num3) { return [Silk.NET.Input.Key]::Number3 }
            ([DoomKey]::Num4) { return [Silk.NET.Input.Key]::Number4 }
            ([DoomKey]::Num5) { return [Silk.NET.Input.Key]::Number5 }
            ([DoomKey]::Num6) { return [Silk.NET.Input.Key]::Number6 }
            ([DoomKey]::Num7) { return [Silk.NET.Input.Key]::Number7 }
            ([DoomKey]::Num8) { return [Silk.NET.Input.Key]::Number8 }
            ([DoomKey]::Num9) { return [Silk.NET.Input.Key]::Number9 }
            ([DoomKey]::Semicolon) { return [Silk.NET.Input.Key]::Semicolon }
            ([DoomKey]::Equal) { return [Silk.NET.Input.Key]::Equal }
            ([DoomKey]::A) { return [Silk.NET.Input.Key]::A }
            ([DoomKey]::B) { return [Silk.NET.Input.Key]::B }
            ([DoomKey]::C) { return [Silk.NET.Input.Key]::C }
            ([DoomKey]::D) { return [Silk.NET.Input.Key]::D }
            ([DoomKey]::E) { return [Silk.NET.Input.Key]::E }
            ([DoomKey]::F) { return [Silk.NET.Input.Key]::F }
            ([DoomKey]::G) { return [Silk.NET.Input.Key]::G }
            ([DoomKey]::H) { return [Silk.NET.Input.Key]::H }
            ([DoomKey]::I) { return [Silk.NET.Input.Key]::I }
            ([DoomKey]::J) { return [Silk.NET.Input.Key]::J }
            ([DoomKey]::K) { return [Silk.NET.Input.Key]::K }
            ([DoomKey]::L) { return [Silk.NET.Input.Key]::L }
            ([DoomKey]::M) { return [Silk.NET.Input.Key]::M }
            ([DoomKey]::N) { return [Silk.NET.Input.Key]::N }
            ([DoomKey]::O) { return [Silk.NET.Input.Key]::O }
            ([DoomKey]::P) { return [Silk.NET.Input.Key]::P }
            ([DoomKey]::Q) { return [Silk.NET.Input.Key]::Q }
            ([DoomKey]::R) { return [Silk.NET.Input.Key]::R }
            ([DoomKey]::S) { return [Silk.NET.Input.Key]::S }
            ([DoomKey]::T) { return [Silk.NET.Input.Key]::T }
            ([DoomKey]::U) { return [Silk.NET.Input.Key]::U }
            ([DoomKey]::V) { return [Silk.NET.Input.Key]::V }
            ([DoomKey]::W) { return [Silk.NET.Input.Key]::W }
            ([DoomKey]::X) { return [Silk.NET.Input.Key]::X }
            ([DoomKey]::Y) { return [Silk.NET.Input.Key]::Y }
            ([DoomKey]::Z) { return [Silk.NET.Input.Key]::Z }
            ([DoomKey]::LBracket) { return [Silk.NET.Input.Key]::LeftBracket }
            ([DoomKey]::Backslash) { return [Silk.NET.Input.Key]::BackSlash }
            ([DoomKey]::RBracket) { return [Silk.NET.Input.Key]::RightBracket }
            ([DoomKey]::Escape) { return [Silk.NET.Input.Key]::Escape }
            ([DoomKey]::Enter) { return [Silk.NET.Input.Key]::Enter }
            ([DoomKey]::Tab) { return [Silk.NET.Input.Key]::Tab }
            ([DoomKey]::Backspace) { return [Silk.NET.Input.Key]::Backspace }
            ([DoomKey]::Insert) { return [Silk.NET.Input.Key]::Insert }
            ([DoomKey]::Delete) { return [Silk.NET.Input.Key]::Delete }
            ([DoomKey]::Right) { return [Silk.NET.Input.Key]::Right }
            ([DoomKey]::Left) { return [Silk.NET.Input.Key]::Left }
            ([DoomKey]::Down) { return [Silk.NET.Input.Key]::Down }
            ([DoomKey]::Up) { return [Silk.NET.Input.Key]::Up }
            ([DoomKey]::PageUp) { return [Silk.NET.Input.Key]::PageUp }
            ([DoomKey]::PageDown) { return [Silk.NET.Input.Key]::PageDown }
            ([DoomKey]::Home) { return [Silk.NET.Input.Key]::Home }
            ([DoomKey]::End) { return [Silk.NET.Input.Key]::End }
            ([DoomKey]::Pause) { return [Silk.NET.Input.Key]::Pause }
            ([DoomKey]::F1) { return [Silk.NET.Input.Key]::F1 }
            ([DoomKey]::F2) { return [Silk.NET.Input.Key]::F2 }
            ([DoomKey]::F3) { return [Silk.NET.Input.Key]::F3 }
            ([DoomKey]::F4) { return [Silk.NET.Input.Key]::F4 }
            ([DoomKey]::F5) { return [Silk.NET.Input.Key]::F5 }
            ([DoomKey]::F6) { return [Silk.NET.Input.Key]::F6 }
            ([DoomKey]::F7) { return [Silk.NET.Input.Key]::F7 }
            ([DoomKey]::F8) { return [Silk.NET.Input.Key]::F8 }
            ([DoomKey]::F9) { return [Silk.NET.Input.Key]::F9 }
            ([DoomKey]::F10) { return [Silk.NET.Input.Key]::F10 }
            ([DoomKey]::F11) { return [Silk.NET.Input.Key]::F11 }
            ([DoomKey]::F12) { return [Silk.NET.Input.Key]::F12 }
            ([DoomKey]::Numpad0) { return [Silk.NET.Input.Key]::Keypad0 }
            ([DoomKey]::Numpad1) { return [Silk.NET.Input.Key]::Keypad1 }
            ([DoomKey]::Numpad2) { return [Silk.NET.Input.Key]::Keypad2 }
            ([DoomKey]::Numpad3) { return [Silk.NET.Input.Key]::Keypad3 }
            ([DoomKey]::Numpad4) { return [Silk.NET.Input.Key]::Keypad4 }
            ([DoomKey]::Numpad5) { return [Silk.NET.Input.Key]::Keypad5 }
            ([DoomKey]::Numpad6) { return [Silk.NET.Input.Key]::Keypad6 }
            ([DoomKey]::Numpad7) { return [Silk.NET.Input.Key]::Keypad7 }
            ([DoomKey]::Numpad8) { return [Silk.NET.Input.Key]::Keypad8 }
            ([DoomKey]::Numpad9) { return [Silk.NET.Input.Key]::Keypad9 }
            ([DoomKey]::LShift) { return [Silk.NET.Input.Key]::ShiftLeft }
            ([DoomKey]::RShift) { return [Silk.NET.Input.Key]::ShiftRight }
            ([DoomKey]::LControl) { return [Silk.NET.Input.Key]::ControlLeft }
            ([DoomKey]::RControl) { return [Silk.NET.Input.Key]::ControlRight }
            ([DoomKey]::LAlt) { return [Silk.NET.Input.Key]::AltLeft }
            ([DoomKey]::RAlt) { return [Silk.NET.Input.Key]::AltRight }
            ([DoomKey]::Menu) { return [Silk.NET.Input.Key]::Menu }
            default { return [Silk.NET.Input.Key]::Unknown }
        }
        return [Silk.NET.Input.Key]::Unknown
    }
    static [DoomKey] SilkToDoom([Silk.NET.Input.Key] $silkKey) {
        switch ($silkKey) {
            ([Silk.NET.Input.Key]::Space) { return [DoomKey]::Space }
            ([Silk.NET.Input.Key]::Comma) { return [DoomKey]::Comma }
            ([Silk.NET.Input.Key]::Minus) { return [DoomKey]::Subtract }
            ([Silk.NET.Input.Key]::Period) { return [DoomKey]::Period }
            ([Silk.NET.Input.Key]::Slash) { return [DoomKey]::Slash }
            ([Silk.NET.Input.Key]::Number0) { return [DoomKey]::Num0 }
            ([Silk.NET.Input.Key]::Number1) { return [DoomKey]::Num1 }
            ([Silk.NET.Input.Key]::Number2) { return [DoomKey]::Num2 }
            ([Silk.NET.Input.Key]::Number3) { return [DoomKey]::Num3 }
            ([Silk.NET.Input.Key]::Number4) { return [DoomKey]::Num4 }
            ([Silk.NET.Input.Key]::Number5) { return [DoomKey]::Num5 }
            ([Silk.NET.Input.Key]::Number6) { return [DoomKey]::Num6 }
            ([Silk.NET.Input.Key]::Number7) { return [DoomKey]::Num7 }
            ([Silk.NET.Input.Key]::Number8) { return [DoomKey]::Num8 }
            ([Silk.NET.Input.Key]::Number9) { return [DoomKey]::Num9 }
            ([Silk.NET.Input.Key]::Semicolon) { return [DoomKey]::Semicolon }
            ([Silk.NET.Input.Key]::Equal) { return [DoomKey]::Equal }
            ([Silk.NET.Input.Key]::A) { return [DoomKey]::A }
            ([Silk.NET.Input.Key]::B) { return [DoomKey]::B }
            ([Silk.NET.Input.Key]::C) { return [DoomKey]::C }
            ([Silk.NET.Input.Key]::D) { return [DoomKey]::D }
            ([Silk.NET.Input.Key]::E) { return [DoomKey]::E }
            ([Silk.NET.Input.Key]::F) { return [DoomKey]::F }
            ([Silk.NET.Input.Key]::G) { return [DoomKey]::G }
            ([Silk.NET.Input.Key]::H) { return [DoomKey]::H }
            ([Silk.NET.Input.Key]::I) { return [DoomKey]::I }
            ([Silk.NET.Input.Key]::J) { return [DoomKey]::J }
            ([Silk.NET.Input.Key]::K) { return [DoomKey]::K }
            ([Silk.NET.Input.Key]::L) { return [DoomKey]::L }
            ([Silk.NET.Input.Key]::M) { return [DoomKey]::M }
            ([Silk.NET.Input.Key]::N) { return [DoomKey]::N }
            ([Silk.NET.Input.Key]::O) { return [DoomKey]::O }
            ([Silk.NET.Input.Key]::P) { return [DoomKey]::P }
            ([Silk.NET.Input.Key]::Q) { return [DoomKey]::Q }
            ([Silk.NET.Input.Key]::R) { return [DoomKey]::R }
            ([Silk.NET.Input.Key]::S) { return [DoomKey]::S }
            ([Silk.NET.Input.Key]::T) { return [DoomKey]::T }
            ([Silk.NET.Input.Key]::U) { return [DoomKey]::U }
            ([Silk.NET.Input.Key]::V) { return [DoomKey]::V }
            ([Silk.NET.Input.Key]::W) { return [DoomKey]::W }
            ([Silk.NET.Input.Key]::X) { return [DoomKey]::X }
            ([Silk.NET.Input.Key]::Y) { return [DoomKey]::Y }
            ([Silk.NET.Input.Key]::Z) { return [DoomKey]::Z }
            ([Silk.NET.Input.Key]::LeftBracket) { return [DoomKey]::LBracket }
            ([Silk.NET.Input.Key]::BackSlash) { return [DoomKey]::Backslash }
            ([Silk.NET.Input.Key]::RightBracket) { return [DoomKey]::RBracket }
            ([Silk.NET.Input.Key]::Escape) { return [DoomKey]::Escape }
            ([Silk.NET.Input.Key]::Enter) { return [DoomKey]::Enter }
            ([Silk.NET.Input.Key]::Tab) { return [DoomKey]::Tab }
            ([Silk.NET.Input.Key]::Backspace) { return [DoomKey]::Backspace }
            ([Silk.NET.Input.Key]::Insert) { return [DoomKey]::Insert }
            ([Silk.NET.Input.Key]::Delete) { return [DoomKey]::Delete }
            ([Silk.NET.Input.Key]::Right) { return [DoomKey]::Right }
            ([Silk.NET.Input.Key]::Left) { return [DoomKey]::Left }
            ([Silk.NET.Input.Key]::Down) { return [DoomKey]::Down }
            ([Silk.NET.Input.Key]::Up) { return [DoomKey]::Up }
            ([Silk.NET.Input.Key]::PageUp) { return [DoomKey]::PageUp }
            ([Silk.NET.Input.Key]::PageDown) { return [DoomKey]::PageDown }
            ([Silk.NET.Input.Key]::Home) { return [DoomKey]::Home }
            ([Silk.NET.Input.Key]::End) { return [DoomKey]::End }
            ([Silk.NET.Input.Key]::Pause) { return [DoomKey]::Pause }
            ([Silk.NET.Input.Key]::F1) { return [DoomKey]::F1 }
            ([Silk.NET.Input.Key]::F2) { return [DoomKey]::F2 }
            ([Silk.NET.Input.Key]::F3) { return [DoomKey]::F3 }
            ([Silk.NET.Input.Key]::F4) { return [DoomKey]::F4 }
            ([Silk.NET.Input.Key]::F5) { return [DoomKey]::F5 }
            ([Silk.NET.Input.Key]::F6) { return [DoomKey]::F6 }
            ([Silk.NET.Input.Key]::F7) { return [DoomKey]::F7 }
            ([Silk.NET.Input.Key]::F8) { return [DoomKey]::F8 }
            ([Silk.NET.Input.Key]::F9) { return [DoomKey]::F9 }
            ([Silk.NET.Input.Key]::F10) { return [DoomKey]::F10 }
            ([Silk.NET.Input.Key]::F11) { return [DoomKey]::F11 }
            ([Silk.NET.Input.Key]::F12) { return [DoomKey]::F12 }
            ([Silk.NET.Input.Key]::Keypad0) { return [DoomKey]::Numpad0 }
            ([Silk.NET.Input.Key]::Keypad1) { return [DoomKey]::Numpad1 }
            ([Silk.NET.Input.Key]::Keypad2) { return [DoomKey]::Numpad2 }
            ([Silk.NET.Input.Key]::Keypad3) { return [DoomKey]::Numpad3 }
            ([Silk.NET.Input.Key]::Keypad4) { return [DoomKey]::Numpad4 }
            ([Silk.NET.Input.Key]::Keypad5) { return [DoomKey]::Numpad5 }
            ([Silk.NET.Input.Key]::Keypad6) { return [DoomKey]::Numpad6 }
            ([Silk.NET.Input.Key]::Keypad7) { return [DoomKey]::Numpad7 }
            ([Silk.NET.Input.Key]::Keypad8) { return [DoomKey]::Numpad8 }
            ([Silk.NET.Input.Key]::Keypad9) { return [DoomKey]::Numpad9 }
            ([Silk.NET.Input.Key]::ShiftLeft) { return [DoomKey]::LShift }
            ([Silk.NET.Input.Key]::ShiftRight) { return [DoomKey]::RShift }
            ([Silk.NET.Input.Key]::ControlLeft) { return [DoomKey]::LControl }
            ([Silk.NET.Input.Key]::ControlRight) { return [DoomKey]::RControl }
            ([Silk.NET.Input.Key]::AltLeft) { return [DoomKey]::LAlt }
            ([Silk.NET.Input.Key]::AltRight) { return [DoomKey]::RAlt }
            ([Silk.NET.Input.Key]::Menu) { return [DoomKey]::Menu }
            default { return [DoomKey]::Unknown }
        }
        return [DoomKey]::Unknown
    }
    [int] get_MouseSensitivity()
    {
        return $this.Config.mouse_sensitivity
    }

    [void] set_MouseSensitivity([int]$value)
    {
        $this.Config.mouse_sensitivity = $value
    }

    static [int16] ToInt16Unchecked([double] $value) {
        $wrapped = ([long][math]::Truncate($value)) -band 0xFFFFL
        if ($wrapped -ge 0x8000L) {
            return [int16]($wrapped - 0x10000L)
        }

        return [int16]$wrapped
    }
}
