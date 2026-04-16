class Player {
    static [int] $MaxPlayerCount = 4
    static [Fixed] $NormalViewHeight = [Fixed]::FromInt(41)
    static [string[]] $DefaultPlayerNames = @("Green", "Indigo", "Brown", "Red")

    [int] $Number
    [string] $Name
    [bool] $InGame
    
    [Mobj] $Mobj
    [PlayerState] $PlayerState
    [TicCmd] $Cmd
    
    [Fixed] $ViewZ
    [Fixed] $ViewHeight
    [Fixed] $DeltaViewHeight
    [Fixed] $Bob
    
    [int] $Health
    [int] $ArmorPoints
    [int] $ArmorType
    
    [int[]] $Powers
    [bool[]] $Cards
    [bool] $Backpack
    
    [int[]] $Frags
    
    [WeaponType] $ReadyWeapon
    [WeaponType] $PendingWeapon
    
    [bool[]] $WeaponOwned
    [int[]] $Ammo
    [int[]] $MaxAmmo
    
    [bool] $AttackDown
    [bool] $UseDown
    
    [CheatFlags] $Cheats
    [int] $Refire
    
    [int] $KillCount
    [int] $ItemCount
    [int] $SecretCount
    
    [string] $Message
    [int] $MessageTime
    
    [int] $DamageCount
    [int] $BonusCount
    
    [Mobj] $Attacker
    [int] $ExtraLight
    [int] $FixedColorMap
    [int] $ColorMap
    [bool] $interpolate
    [Fixed] $oldViewZ
    [Angle] $oldAngle
    
    [PlayerSpriteDef[]] $PlayerSprites
    
    [bool] $DidSecret
    
    Player([int] $number) {
        $this.Number = $number
        $this.Name = [Player]::DefaultPlayerNames[$number]
        
        $this.Cmd = [TicCmd]::new()
        
        $this.Powers = @(0) * [PowerType]::Count
        $this.Cards = @(0) * [CardType]::Count
        $this.Frags = @(0) * [Player]::MaxPlayerCount
        $this.WeaponOwned = @(0) * [WeaponType]::Count
        $this.Ammo = @(0) * [AmmoType]::Count
        $this.MaxAmmo = @(0) * [AmmoType]::Count
        
        $this.PlayerSprites = New-Object 'PlayerSpriteDef[]' ([PlayerSprite]::Count)
        for ($i = 0; $i -lt $this.PlayerSprites.Length; $i++) {
            $this.PlayerSprites[$i] = [PlayerSpriteDef]::new()
        }
    }
    [void] Reborn() {
        $this.Mobj = $null
        $this.PlayerState = [PlayerState]::Live
        $this.Cmd.Clear()

        $this.ViewZ = [Fixed]::Zero
        $this.ViewHeight = [Fixed]::Zero
        $this.DeltaViewHeight = [Fixed]::Zero
        $this.Bob = [Fixed]::Zero

        $this.Health = [DoomInfo]::DeHackEdConst.InitialHealth
        $this.ArmorPoints = 0
        $this.ArmorType = 0

        [Array]::Clear($this.Powers, 0, $this.Powers.Length)
        [Array]::Clear($this.Cards, 0, $this.Cards.Length)
        $this.Backpack = $false

        $this.ReadyWeapon = [WeaponType]::Pistol
        $this.PendingWeapon = [WeaponType]::Pistol

        [Array]::Clear($this.WeaponOwned, 0, $this.WeaponOwned.Length)
        [Array]::Clear($this.Ammo, 0, $this.Ammo.Length)
        [Array]::Clear($this.MaxAmmo, 0, $this.MaxAmmo.Length)

        $this.WeaponOwned[[int][WeaponType]::Fist] = $true
        $this.WeaponOwned[[int][WeaponType]::Pistol] = $true
        $this.Ammo[[int][AmmoType]::Clip] = [DoomInfo]::DeHackEdConst.InitialBullets

        for ($i = 0; $i -lt [int][AmmoType]::Count; $i++) {
            $this.MaxAmmo[$i] = [DoomInfo]::AmmoInfos.Max[$i] #broken.
        }

        # Reset controls
        $this.UseDown = $true
        $this.AttackDown = $true

        # Reset player status
        $this.Cheats = 0
        $this.Refire = 0
        $this.Message = $null
        $this.MessageTime = 0
        $this.DamageCount = 0
        $this.BonusCount = 0
        $this.Attacker = $null
        $this.ExtraLight = 0
        $this.FixedColorMap = 0
        $this.ColorMap = 0

        # Reset player sprites
        $playerSpritesEnumerable = $this.PlayerSprites
        if ($null -ne $playerSpritesEnumerable) {
            $playerSpritesEnumerator = $playerSpritesEnumerable.GetEnumerator()
            for (; $playerSpritesEnumerator.MoveNext(); ) {
                $psp = $playerSpritesEnumerator.Current
                $psp.Clear()

            }
        }

        $this.DidSecret = $false
        $this.Interpolate = $false
        $this.OldViewZ = [Fixed]::Zero
        $this.OldAngle = [Angle]::Ang0
    }

    [void] FinishLevel() {
        [Array]::Clear($this.Powers, 0, $this.Powers.Length)
        [Array]::Clear($this.Cards, 0, $this.Cards.Length)

        # Cancel invisibility
        $this.Mobj.Flags = $this.Mobj.Flags -band -bnot [MobjFlags]::Shadow

        # Cancel gun flashes
        $this.ExtraLight = 0

        # Cancel infrared goggles
        $this.FixedColorMap = 0

        # No palette changes
        $this.DamageCount = 0
        $this.BonusCount = 0
    }

    [void] SendMessage([object] $message) {
        $text = if ($message -is [DoomString]) {
            $message.ToString()
        } else {
            [string]$message
        }

        $msgOff = ([DoomInfo]::Strings.MSGOFF).ToString()
        $msgOn = ([DoomInfo]::Strings.MSGON).ToString()

        if ($this.Message -eq $msgOff -and $text -ne $msgOn) {
            return
        }

        $this.Message = $text
        $this.MessageTime = 4 * [GameConst]::TicRate
    }

    [void] Clear() {
        $this.Mobj = $null
        $this.PlayerState = 0
        $this.Cmd.Clear()

        $this.ViewZ = [Fixed]::Zero
        $this.ViewHeight = [Fixed]::Zero
        $this.DeltaViewHeight = [Fixed]::Zero
        $this.Bob = [Fixed]::Zero

        $this.Health = 0
        $this.ArmorPoints = 0
        $this.ArmorType = 0

        $this.Powers = @(0) * $this.Powers.Length
        $this.Cards = @(0) * $this.Cards.Length
        $this.Backpack = $false

        $this.Frags = @(0) * $this.Frags.Length

        $this.ReadyWeapon = 0
        $this.PendingWeapon = 0

        $this.WeaponOwned = @(0) * $this.WeaponOwned.Length
        $this.Ammo = @(0) * $this.Ammo.Length
        $this.MaxAmmo = @(0) * $this.MaxAmmo.Length

        $this.UseDown = $false
        $this.AttackDown = $false
        $this.Cheats = 0
        
        $this.Refire = 0
        
        $this.KillCount = 0
        $this.ItemCount = 0
        $this.SecretCount = 0
        
        $this.Message = $null
        $this.MessageTime = 0
        
        $this.DamageCount = 0
        $this.BonusCount = 0
        
        $this.Attacker = $null
        
        $this.ExtraLight = 0
        $this.FixedColorMap = 0
        $this.ColorMap = 0

        $playerSpritesEnumerable = $this.PlayerSprites
        if ($null -ne $playerSpritesEnumerable) {
            $playerSpritesEnumerator = $playerSpritesEnumerable.GetEnumerator()
            for (; $playerSpritesEnumerator.MoveNext(); ) {
                $psp = $playerSpritesEnumerator.Current
                $psp.Clear()

            }
        }

        $this.DidSecret = $false
    }

    [void] UpdateFrameInterpolationInfo() {
        $this.interpolate = $true
        $this.oldViewZ = $this.ViewZ
        $this.oldAngle = if ($null -ne $this.Mobj) { $this.Mobj.Angle } else { [Angle]::Ang0 }
    }

    [void] DisableFrameInterpolationForOneFrame() {
        $this.interpolate = $false
    }

    [Fixed] GetInterpolatedViewZ([Fixed] $frameFrac) {
        if ($this.interpolate -and $null -ne $this.Mobj -and $this.Mobj.World.LevelTime -gt 1) {
            return $this.oldViewZ + $frameFrac * ($this.ViewZ - $this.oldViewZ)
        } else {
            return $this.ViewZ
        }
    }

    [Angle] GetInterpolatedAngle([Fixed] $frameFrac) {
        if ($this.interpolate -and $null -ne $this.Mobj) {
            $delta = $this.Mobj.Angle - $this.oldAngle
            if ($delta.Data -lt [Angle]::Ang180.Data) {
                return $this.oldAngle + [Angle]::FromDegree($frameFrac.ToDouble() * $delta.ToDegree())
            } else {
                return $this.oldAngle - [Angle]::FromDegree($frameFrac.ToDouble() * (360.0 - $delta.ToDegree()))
            }
        } elseif ($null -ne $this.Mobj) {
            return $this.Mobj.Angle
        } else {
            return $this.oldAngle
        }
    }
}
