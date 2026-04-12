class DoomEvent {
    [EventType] $Type
    [DoomKey] $Key

    DoomEvent([EventType] $type, [DoomKey] $key) {
        $this.Type = $type
        $this.Key = $key
    }
}