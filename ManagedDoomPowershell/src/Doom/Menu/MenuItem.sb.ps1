class MenuItem {
    [int] $skullX
    [int] $skullY
    [MenuDef] $next

    # Default constructor (private)
    MenuItem() {
    }

    # Constructor with parameters
    MenuItem([int] $skullX, [int] $skullY, [MenuDef] $next) {
        $this.skullX = $skullX
        $this.skullY = $skullY
        $this.next = $next
    }
}