class ISound {
    [void] SetListener([Mobj]$listener) { throw "Not implemented" }
    [void] Update() { throw "Not implemented" }
    [void] StartSound([sfx]$sfx) { throw "Not implemented" }
    [void] StartSound([Mobj]$mobj, [sfx]$sfx, [SfxType]$type) { throw "Not implemented" }
    [void] StartSound([Mobj]$mobj, [sfx]$sfx, [SfxType]$type, [int]$volume) { throw "Not implemented" }
    [void] StopSound([Mobj]$mobj) { throw "Not implemented" }
    [void] Reset() { throw "Not implemented" }
    [void] Pause() { throw "Not implemented" }
    [void] Resume() { throw "Not implemented" }

   hidden [int] $volume = 0
   hidden [int] $MaxVolume = 15
}