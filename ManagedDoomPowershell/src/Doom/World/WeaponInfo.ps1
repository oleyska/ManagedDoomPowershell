class WeaponInfo {
    [AmmoType]$Ammo
    [MobjState]$UpState
    [MobjState]$DownState
    [MobjState]$ReadyState
    [MobjState]$AttackState
    [MobjState]$FlashState

    WeaponInfo([AmmoType]$ammo, [MobjState]$upState, [MobjState]$downState, [MobjState]$readyState, [MobjState]$attackState, [MobjState]$flashState) {
        $this.Ammo = $ammo
        $this.UpState = $upState
        $this.DownState = $downState
        $this.ReadyState = $readyState
        $this.AttackState = $attackState
        $this.FlashState = $flashState
    }
}