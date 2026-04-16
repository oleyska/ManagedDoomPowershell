class MenuItem {
    [int] $skullX
    [int] $skullY
    [MenuDef] $next

    MenuItem() {
    }


    MenuItem([int] $skullX, [int] $skullY, [MenuDef] $next) {
        $this.skullX = $skullX
        $this.skullY = $skullY
        $this.next = $next
    }
}