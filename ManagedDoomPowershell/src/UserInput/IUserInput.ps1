class IUserInput {
    [void] PollEvents() {
        throw "Not Implemented"
    }

    [void] BuildTicCmd([TicCmd]$cmd) {
        throw "Not Implemented"
    }

    [void] Reset() {
        throw "Not Implemented"
    }

    [void] GrabMouse() {
        throw "Not Implemented"
    }

    [void] ReleaseMouse() {
        throw "Not Implemented"
    }

    [int] get_MaxMouseSensitivity() {
        throw "Not Implemented"
    }

    [int] get_MouseSensitivity() {
        throw "Not Implemented"
    }

    [void] set_MouseSensitivity([int]$value) {
        throw "Not Implemented"
    }
}