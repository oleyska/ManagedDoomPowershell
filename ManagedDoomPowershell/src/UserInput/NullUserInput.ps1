# needs [IUserInput]

class NullUserInput : IUserInput {
    static [NullUserInput]$Instance

    NullUserInput() { }

    static [NullUserInput] GetInstance() {
        if ($null -eq [NullUserInput]::Instance) {
            [NullUserInput]::Instance = [NullUserInput]::new()
        }
        return [NullUserInput]::Instance
    }

    [void] PollEvents() { }

    [void] BuildTicCmd([TicCmd]$cmd) {
        $cmd.Clear()
    }

    [void] Reset() { }

    [void] GrabMouse() { }

    [void] ReleaseMouse() { }

    [int] get_MaxMouseSensitivity() {
        return 9
    }

    [int] get_MouseSensitivity() {
        return 3
    }

    [void] set_MouseSensitivity([int]$value) { }
}