#needs [ISound]
class NullSound : ISound{
    static [NullSound] $instance
    [int] $volume = 0
    [int] $MaxVolume = 15
    static [NullSound] GetInstance() {
        if ($null -eq [NullSound]::instance) {
            [NullSound]::instance = [NullSound]::new()
        }
        return [NullSound]::instance
    }

    [void] SetListener([Mobj] $listener) { }

    [void] Update() { }

    [void] StartSound([Sfx] $sfx) { }

   [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type) { }

    [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type, [int] $volume) { }

    [void] StopSound([Mobj] $mobj) { }

    [void] Reset() { }

    [void] Pause() { }

    [void] Resume() { }

    [int] GetSoundVolume() {
        return $this.volume
    }

    [void] SetSoundVolume([int] $value) {
        $this.volume = [Math]::Clamp($value, 0, $this.MaxVolume)
    }

    [int] GetSoundMaxVolume() {
        return $this.MaxVolume
    }
}
