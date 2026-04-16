class SectorAction {
    [World] $world

    [bool] $crushChange
    [bool] $noFit
    [Func[Mobj, bool]] $crushThingFunc

    static [Fixed] $doorSpeed = [Fixed]::FromInt(2)
    static [int] $doorWait = 150

    SectorAction([World] $world) {
        $this.world = $world
        $this.InitSectorChange()
        $this.PlatformAction()
    }

    [void] InitSectorChange() {
        $owner = $this
        $callback = {
            param($thing)
            return $owner.CrushThing($thing)
        }.GetNewClosure()
        $this.crushThingFunc = [Func[Mobj, bool]]$callback
    }

    [bool] ThingHeightClip([Mobj] $thing) {
        $onFloor = ($thing.Z.Data -eq $thing.FloorZ.Data)

        $tm = $this.world.ThingMovement

        $tm.CheckPosition($thing, $thing.X, $thing.Y)
        # What about stranding a monster partially off an edge?

        $thing.FloorZ = $tm.CurrentFloorZ
        $thing.CeilingZ = $tm.CurrentCeilingZ

        if ($onFloor) {
            # Walking monsters rise and fall with the floor.
            $thing.Z = $thing.FloorZ
        } else {
            # Don't adjust a floating monster unless forced to.
            if (($thing.Z + $thing.Height).Data -gt $thing.CeilingZ.Data) {
                $thing.Z = $thing.CeilingZ - $thing.Height
            }
        }

        if (($thing.CeilingZ - $thing.FloorZ).Data -lt $thing.Height.Data) {
            return $false
        }

        return $true
    }

    [bool] CrushThing([Mobj] $thing) {
        if ($this.ThingHeightClip($thing)) {
            # Keep checking.
            return $true
        }

        # Crunch bodies to giblets.
        if ($thing.Health -le 0) {
            $thing.SetState([MobjState]::Gibs)
            $thing.Flags = $thing.Flags -band (-bnot [MobjFlags]::Solid)
            $thing.Height = [Fixed]::Zero
            $thing.Radius = [Fixed]::Zero

            # Keep checking.
            return $true
        }

        # Crunch dropped items.
        if ([int]($thing.Flags -band [MobjFlags]::Dropped) -ne 0) {
            $this.world.ThingAllocation.RemoveMobj($thing)

            # Keep checking.
            return $true
        }

        if ([int]($thing.Flags -band [MobjFlags]::Shootable) -eq 0) {
            # Assume it is bloody gibs or something.
            return $true
        }

        $this.noFit = $true

        if ($this.crushChange -and ($this.world.LevelTime -band 3) -eq 0) {
            $this.world.ThingInteraction.DamageMobj($thing, $null, $null, 10)

            # Spray blood in a random direction.
            $blood = $this.world.ThingAllocation.SpawnMobj(
                $thing.X,
                $thing.Y,
                $thing.Z + $thing.Height / 2,
                [MobjType]::Blood
            )

            $random = $this.world.Random
            $blood.MomX = [Fixed]::new(($random.Next() - $random.Next()) -shl 12)
            $blood.MomY = [Fixed]::new(($random.Next() - $random.Next()) -shl 12)
        }

        # Keep checking (crush other things).	
        return $true
    }

    [bool] ChangeSector([Sector] $sector, [bool] $crunch) {
        $this.noFit = $false
        $this.crushChange = $crunch

        $bm = $this.world.Map.BlockMap
        $blockBox = $sector.BlockBox

        # Re-check heights for all things near the moving sector.
        for ($x = $blockBox[[Box]::Left]; $x -le $blockBox[[Box]::Right]; $x++) {
            for ($y = $blockBox[[Box]::Bottom]; $y -le $blockBox[[Box]::Top]; $y++) {
                $bm.IterateThings($x, $y, $this.crushThingFunc)
            }
        }

        return $this.noFit
    }

    [SectorActionResult] MovePlane([Sector] $sector, [Fixed] $speed, [Fixed] $dest, [bool] $crush, [int] $floorOrCeiling, [int] $direction) {
        switch ($floorOrCeiling) {
            0 { # Floor.
                switch ($direction) {
                    -1 { # Down.
                        if (($sector.FloorHeight - $speed).Data -lt $dest.Data) {
                            $lastPos = $sector.FloorHeight
                            $sector.FloorHeight = $dest
                            if ( $this.ChangeSector($sector, $crush) ) {
                                $sector.FloorHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                            }
                            return [SectorActionResult]::PastDestination
                        } else {
                            $lastPos = $sector.FloorHeight
                            $sector.FloorHeight -= $speed
                            if ( $this.ChangeSector($sector, $crush) ) {
                                $sector.FloorHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                                return [SectorActionResult]::Crushed
                            }
                        }
                        break
                    }

                    1 { # Up.
                        if (($sector.FloorHeight + $speed).Data -gt $dest.Data) {
                            $lastPos = $sector.FloorHeight
                            $sector.FloorHeight = $dest
                            if ($this.ChangeSector($sector, $crush)) {
                                $sector.FloorHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                            }
                            return [SectorActionResult]::PastDestination
                        } else {
                            # Could get crushed.
                            $lastPos = $sector.FloorHeight
                            $sector.FloorHeight += $speed
                            if ($this.ChangeSector($sector, $crush)) {
                                if ($crush) {
                                    return [SectorActionResult]::Crushed
                                }
                                $sector.FloorHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                                return [SectorActionResult]::Crushed
                            }
                        }
                        break
                    }
                }
                break
            }

            1 { # Ceiling.
                switch ($direction) {
                    -1 { # Down.
                        if (($sector.CeilingHeight - $speed).Data -lt $dest.Data) {
                            $lastPos = $sector.CeilingHeight
                            $sector.CeilingHeight = $dest
                            if ($this.ChangeSector($sector, $crush)) {
                                $sector.CeilingHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                            }
                            return [SectorActionResult]::PastDestination
                        } else {
                            # Could get crushed.
                            $lastPos = $sector.CeilingHeight
                            $sector.CeilingHeight -= $speed
                            if ($this.ChangeSector($sector, $crush)) {
                                if ($crush) {
                                    return [SectorActionResult]::Crushed
                                }
                                $sector.CeilingHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                                return [SectorActionResult]::Crushed
                            }
                        }
                        break
                    }

                    1 { # Up
                        if (($sector.CeilingHeight + $speed).Data -gt $dest.Data) {
                            $lastPos = $sector.CeilingHeight
                            $sector.CeilingHeight = $dest
                            if ($this.ChangeSector($sector, $crush)) {
                                $sector.CeilingHeight = $lastPos
                                $this.ChangeSector($sector, $crush)
                            }
                            return [SectorActionResult]::PastDestination
                        } else {
                            $sector.CeilingHeight += $speed
                            $this.ChangeSector($sector, $crush)
                        }
                        break
                    }
                }
                break
            }
        }

        return [SectorActionResult]::OK
    }

    [Sector] GetNextSector([LineDef] $line, [Sector] $sector) {
        if (($line.Flags -band [LineFlags]::TwoSided) -eq 0) {
            return $null
        }

        if ($line.FrontSector -eq $sector) {
            return $line.BackSector
        }

        return $line.FrontSector
    }

    [Fixed] FindLowestFloorSurrounding([Sector] $sector) {
        $floor = $sector.FloorHeight

        for ($i = 0; $i -lt $sector.Lines.Length; $i++) {
            $check = $sector.Lines[$i]

            $other = $this.GetNextSector($check, $sector)
            if ($null -eq $other) {
                continue
            }

            if ($other.FloorHeight.Data -lt $floor.Data) {
                $floor = $other.FloorHeight
            }
        }

        return $floor
    }

    [Fixed] FindHighestFloorSurrounding([Sector] $sector) {
        $floor = [Fixed]::FromInt(-500)

        for ($i = 0; $i -lt $sector.Lines.Length; $i++) {
            $check = $sector.Lines[$i]

            $other = $this.GetNextSector($check, $sector)
            if ($null -eq $other) {
                continue
            }

            if ($other.FloorHeight.Data -gt $floor.Data) {
                $floor = $other.FloorHeight
            }
        }

        return $floor
    }

    [Fixed] FindLowestCeilingSurrounding([Sector] $sector) {
        $height = [Fixed]::MaxValue

        for ($i = 0; $i -lt $sector.Lines.Length; $i++) {
            $check = $sector.Lines[$i]

            $other = $this.GetNextSector($check, $sector)
            if ($null -eq $other) {
                continue
            }

            if ($other.CeilingHeight.Data -lt $height.Data) {
                $height = $other.CeilingHeight
            }
        }

        return $height
    }

    [Fixed] FindHighestCeilingSurrounding([Sector] $sector) {
        $height = [Fixed]::Zero

        for ($i = 0; $i -lt $sector.Lines.Length; $i++) {
            $check = $sector.Lines[$i]

            $other = $this.GetNextSector($check, $sector)
            if ($null -eq $other) {
                continue
            }

            if ($other.CeilingHeight.Data -gt $height.Data) {
                $height = $other.CeilingHeight
            }
        }

        return $height
    }

    [int] FindSectorFromLineTag([LineDef] $line, [int] $start) {
        $sectors = $this.world.Map.Sectors

        for ($i = $start + 1; $i -lt $sectors.Length; $i++) {
            if ($sectors[$i].Tag -eq $line.Tag) {
                return $i
            }
        }

        return -1
    }

    [void] DoLocalDoor([LineDef] $line, [Mobj] $thing) {
        # Check for locks.
        $player = $thing.Player
    
        switch ($line.Special) {
            # Blue Lock.
            {$_ -eq 26 -or $_ -eq 32} {
                if ($null -eq $player) {
                    return
                }
    
                if (-not ($player.Cards[[CardType]::BlueCard] -or $player.Cards[[CardType]::BlueSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_BLUEK)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return
                }
                break
            }
    
            # Yellow Lock.
            {$_ -eq 27 -or $_ -eq 34} {
                if ($null -eq $player) {
                    return
                }
    
                if (-not ($player.Cards[[CardType]::YellowCard] -or $player.Cards[[CardType]::YellowSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_YELLOWK)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return
                }
                break
            }
    
            # Red Lock.
            {$_ -eq 28 -or $_ -eq 33} {
                if ($null -eq $player) {
                    return
                }
    
                if (-not ($player.Cards[[CardType]::RedCard] -or $player.Cards[[CardType]::RedSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_REDK)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return
                }
                break
            }
        }
    
        $sector = $line.BackSide.Sector
    
        # If the sector has an active thinker, use it.
        if ($null -ne $sector.SpecialData) {
            $door = $sector.SpecialData -as [VerticalDoor]
            switch ($line.Special) {
                # Only for "raise" doors, not "open"s.
                {$_ -eq 1 -or $_ -eq 26 -or $_ -eq 27 -or $_ -eq 28 -or $_ -eq 117} {
                    if ($door.Direction -eq -1) {
                        # Go back up.
                        $door.Direction = 1
                    } else {
                        if ($null -eq $thing.Player) {
                            # Bad guys never close doors.
                            return
                        }
    
                        # Start going down immediately.
                        $door.Direction = -1
                    }
                    return
                }
            }
        }
    
        # For proper sound.
        switch ($line.Special) {
            # Blazing door raise.
            117 { break }
    
            # Blazing door open.
            118 {
                $this.world.StartSound($sector.SoundOrigin, [Sfx]::BDOPN, [SfxType]::Misc)
                break
            }
    
            # Normal door sound.
            {$_ -eq 1 -or $_ -eq 31} {
                $this.world.StartSound($sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                break
            }
    
            # Locked door sound (default case).
            default {
                $this.world.StartSound($sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                break
            }
        }
    
        # New door thinker.
        $newDoor = [VerticalDoor]::new($this.world)
        $this.world.Thinkers.GetType().GetMethod("Add").Invoke($this.world.Thinkers, @($newDoor))
        $sector.SpecialData = $newDoor
        $newDoor.Sector = $sector
        $newDoor.Direction = 1
        $newDoor.Speed = [SectorAction]::doorSpeed
        $newDoor.TopWait = [SectorAction]::doorWait
    
        switch ($line.Special) {
            {$_ -eq 1 -or $_ -eq 26 -or $_ -eq 27 -or $_ -eq 28} {
                $newDoor.Type = [VerticalDoorType]::Normal
                break
            }
    
            {$_ -eq 31 -or $_ -eq 32 -or $_ -eq 33 -or $_ -eq 34} {
                $newDoor.Type = [VerticalDoorType]::Open
                $line.Special = 0
                break
            }
    
            # Blazing door raise.
            117 {
                $newDoor.Type = [VerticalDoorType]::BlazeRaise
                $newDoor.Speed = [SectorAction]::doorSpeed * 4
                break
            }
    
            # Blazing door open.
            118 {
                $newDoor.Type = [VerticalDoorType]::BlazeOpen
                $line.Special = 0
                $newDoor.Speed = [SectorAction]::doorSpeed * 4
                break
            }
        }
    
        # Find the top and bottom of the movement range.
        $newDoor.TopHeight = $this.FindLowestCeilingSurrounding($sector)
        $newDoor.TopHeight -= [Fixed]::FromInt(4)
    }
   
    

    static [Fixed]$CeilingSpeed = [Fixed]::One
    static [int]$CeilingWwait = 150

    static [int]$maxCeilingCount = 30

    [CeilingMove[]]$activeCeilings = (New-Object CeilingMove[] ([SectorAction]::maxCeilingCount))

    [void] AddActiveCeiling([CeilingMove]$ceiling)
    {
        for ($i = 0; $i -lt $this.activeCeilings.Length; $i++)
        {
            if ($null -eq $this.activeCeilings[$i])
            {
                $this.activeCeilings[$i] = $ceiling
                return
            }
        }
    }

    [void] RemoveActiveCeiling([CeilingMove]$ceiling)
    {
        for ($i = 0; $i -lt $this.activeCeilings.Length; $i++)
        {
            if ($this.activeCeilings[$i] -eq $ceiling)
            {
                $this.activeCeilings[$i].Sector.SpecialData = $null
                $this.world.Thinkers.Remove($this.activeCeilings[$i])
                $this.activeCeilings[$i] = $null
                break
            }
        }
    }

    [bool]CheckActiveCeiling([CeilingMove]$ceiling)
    {
        if ($null -eq $ceiling)
        {
            return $false
        }

        for ($i = 0; $i -lt $this.activeCeilings.Length; $i++)
        {
            if ($this.activeCeilings[$i] -eq $ceiling)
            {
                return $true
            }
        }

        return $false
    }

    [void] ActivateInStasisCeiling([LineDef]$line)
    {
        for ($i = 0; $i -lt $this.activeCeilings.Length; $i++)
        {
            if ($null -ne $this.activeCeilings[$i] -and $this.activeCeilings[$i].Tag -eq $line.Tag -and $this.activeCeilings[$i].Direction -eq 0)
            {
                $this.activeCeilings[$i].Direction = $this.activeCeilings[$i].OldDirection
                $this.activeCeilings[$i].ThinkerState = [ThinkerState]::Active
            }
        }
    }
    # Active platforms array and max count

    [Platform[]]$activePlatforms

    PlatformAction() {
        [int]$maxPlatformCount = 60
        $this.activePlatforms = [Platform[]]::new($maxPlatformCount)
    }

    [bool]CeilingCrushStop([LineDef]$line)
    {
        $result = $false

        for ($i = 0; $i -lt $this.activeCeilings.Length; $i++)
        {
            if ($null -ne $this.activeCeilings[$i] -and $this.activeCeilings[$i].Tag -eq $line.Tag -and $this.activeCeilings[$i].Direction -ne 0)
            {
                $this.activeCeilings[$i].OldDirection = $this.activeCeilings[$i].Direction
                $this.activeCeilings[$i].ThinkerState = [ThinkerState]::InStasis
                $this.activeCeilings[$i].Direction = 0
                $result = $true
            }
        }

        return $result
    }

    [bool]Teleport([LineDef]$line, [int]$side, [Mobj]$thing)
    {
        # Don't teleport missiles.
        if (($thing.Flags -band [MobjFlags]::Missile) -ne 0)
        {
            return $false
        }

        # Don't teleport if hit back of line, so you can get out of teleporter.
        if ($side -eq 1)
        {
            return $false
        }

        $sectors = $this.world.Map.Sectors
        $tag = $line.Tag

        for ($i = 0; $i -lt $sectors.Length; $i++)
        {
            if ($sectors[$i].Tag -eq $tag)
            {
                $teleportThinkersEnumerable = $this.world.Thinkers
                if ($null -ne $teleportThinkersEnumerable) {
                    $teleportThinkersEnumerator = $teleportThinkersEnumerable.GetEnumerator()
                    for (; $teleportThinkersEnumerator.MoveNext(); ) {
                        $thinker = $teleportThinkersEnumerator.Current
                        $dest = $thinker -as [Mobj]

                        if ($null -eq $dest)
                        {
                            # Not a mobj.
                            continue
                        }

                        if ($dest.Type -ne [MobjType]::Teleportman)
                        {
                            # Not a teleportman.
                            continue
                        }

                        $sector = $dest.Subsector.Sector

                        if ($sector.Number -ne $i)
                        {
                            # Wrong sector.
                            continue
                        }

                        $oldX = $thing.X
                        $oldY = $thing.Y
                        $oldZ = $thing.Z

                        if (-not $this.world.ThingMovement.TeleportMove($thing, $dest.X, $dest.Y))
                        {
                            return $false
                        }

                        # Compatibility fix for Chocolate Doom's implementation.
                        if ($this.world.Options.GameVersion -ne [GameVersion]::Final)
                        {
                            $thing.Z = $thing.FloorZ
                        }

                        if ($null -ne $thing.Player)
                        {
                            $thing.Player.ViewZ = $thing.Z + $thing.Player.ViewHeight
                        }

                        $ta = $this.world.ThingAllocation

                        # Spawn teleport fog at source position.
                        $fog1 = $ta.SpawnMobj($oldX, $oldY, $oldZ, [MobjType]::Tfog)
                        $this.world.StartSound($fog1, [Sfx]::TELEPT, [SfxType]::Misc)

                        # Destination position.
                        $angle = $dest.Angle
                        $fog2 = $ta.SpawnMobj($dest.X + 20 * [Trig]::Cos($angle), $dest.Y + 20 * [Trig]::Sin($angle), $thing.Z, [MobjType]::Tfog)
                        $this.world.StartSound($fog2, [Sfx]::TELEPT, [SfxType]::Misc)

                        if ($null -ne $thing.Player)
                        {
                            # Don't move for a bit.
                            $thing.ReactionTime = 18
                        }

                        $thing.Angle = $dest.Angle
                        $thing.MomX = $thing.MomY = $thing.MomZ = [Fixed]::Zero

                        $thing.DisableFrameInterpolationForOneFrame()
                        if ($null -ne $thing.Player)
                        {
                            $thing.Player.DisableFrameInterpolationForOneFrame()
                        }

                        return $true

                    }
                }
            }
        }

        return $false
    }

    [bool] DoDoor([LineDef] $line, [VerticalDoorType] $type) {
        $sectors = $this.world.Map.Sectors
        $setcorNumber = -1
        $result = $false

        while (($setcorNumber = $this.FindSectorFromLineTag($line, $setcorNumber)) -ge 0) {
            $sector = $sectors[$setcorNumber]
            if ($null -ne $sector.SpecialData) {
                continue
            }

            $result = $true

            # New door thinker
            $door = [VerticalDoor]::new($this.world)
            $this.world.Thinkers.GetType().GetMethod("Add").Invoke($this.world.Thinkers, @($door))
            $sector.SpecialData = $door
            $door.Sector = $sector
            $door.Type = $type
            $door.TopWait = [SectorAction]::doorWait
            $door.Speed = [SectorAction]::doorSpeed

            switch ($type) {
                [VerticalDoorType]::BlazeClose {
                    $door.TopHeight = $this.FindLowestCeilingSurrounding($sector)
                    $door.TopHeight -= [Fixed]::FromInt(4)
                    $door.Direction = -1
                    $door.Speed = [Fixed]::FromInt(8)
                    $this.world.StartSound($door.Sector.SoundOrigin, [Sfx]::BDCLS, [SfxType]::Misc)
                    break
                }

                [VerticalDoorType]::Close {
                    $door.TopHeight = $this.FindLowestCeilingSurrounding($sector)
                    $door.TopHeight -= [Fixed]::FromInt(4)
                    $door.Direction = -1
                    $this.world.StartSound($door.Sector.SoundOrigin, [Sfx]::DORCLS, [SfxType]::Misc)
                    break
                }

                [VerticalDoorType]::Close30ThenOpen {
                    $door.TopHeight = $sector.CeilingHeight
                    $door.Direction = -1
                    $this.world.StartSound($door.Sector.SoundOrigin, [Sfx]::DORCLS, [SfxType]::Misc)
                    break
                }

                [VerticalDoorType]::BlazeRaise {}
                [VerticalDoorType]::BlazeOpen {
                    $door.Direction = 1
                    $door.TopHeight = $this.FindLowestCeilingSurrounding($sector)
                    $door.TopHeight -= [Fixed]::FromInt(4)
                    $door.Speed = [Fixed]::FromInt(8)
                    if ($door.TopHeight -ne $sector.CeilingHeight) {
                        $this.world.StartSound($door.Sector.SoundOrigin, [Sfx]::BDOPN, [SfxType]::Misc)
                    }
                    break
                }

                [VerticalDoorType]::Normal {}
                [VerticalDoorType]::Open {
                    $door.Direction = 1
                    $door.TopHeight = $this.FindLowestCeilingSurrounding($sector)
                    $door.TopHeight -= [Fixed]::FromInt(4)
                    if ($door.TopHeight -ne $sector.CeilingHeight) {
                        $this.world.StartSound($door.Sector.SoundOrigin, [Sfx]::DOROPN, [SfxType]::Misc)
                    }
                    break
                }

                default { break }
            }
        }

        return $result
    }

    [bool] DoLockedDoor([LineDef] $line, [VerticalDoorType] $type, [Mobj] $thing) {
        $player = $thing.Player
        if ($null -eq $player) {
            return $false
        }

        switch ($line.Special) {
            99 {}
            133 {
                if (-not ($player.Cards[[CardType]::BlueCard] -or $player.Cards[[CardType]::BlueSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_BLUEO)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return $false
                }
                break
            }

            134 {}
            135 {
                if (-not ($player.Cards[[CardType]::RedCard] -or $player.Cards[[CardType]::RedSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_REDO)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return $false
                }
                break
            }

            136 {}
            137 {
                if (-not ($player.Cards[[CardType]::YellowCard] -or $player.Cards[[CardType]::YellowSkull])) {
                    $player.SendMessage([DoomInfo]::Strings.PD_YELLOWO)
                    $this.world.StartSound($player.Mobj, [Sfx]::OOF, [SfxType]::Voice)
                    return $false
                }
                break
            }
        }

        return $this.DoDoor($line, $type)
    }

    [Fixed] FindNextHighestFloor([Sector] $sector, [Fixed] $currentHeight) {
        $height = $currentHeight
        $h = 0

        for ($i = 0; $i -lt $sector.Lines.Length; $i++) {
            $check = $sector.Lines[$i]

            $other = $this.GetNextSector($check, $sector)
            if ($null -eq $other) {
                continue
            }

            if ($other.FloorHeight.Data -gt $height.Data) {
                $function:heightList[$h++] = $other.FloorHeight
            }

            if ($h -ge $function:heightList.Length) {
                throw [System.Exception]::new("Too many adjoining sectors!")
            }
        }

        if ($h -eq 0) {
            return $currentHeight
        }

        $min = $function:heightList[0]
        for ($i = 1; $i -lt $h; $i++) {
            if ($function:heightList[$i].Data -lt $min.Data) {
                $min = $function:heightList[$i]
            }
        }

        return $min
    }
    [bool]DoPlatform([LineDef]$line, [PlatformType]$type, [int]$amount) {
        # Activate all <type> plats that are in stasis
        switch ($type) {
            [PlatformType]::PerpetualRaise {
                $this.ActivateInStasis($line.Tag)
                break
            }

            default { break }
        }

        $sectors = $this.world.Map.Sectors
        $sectorNumber = -1
        $result = $false

        while (($sectorNumber = $this.FindSectorFromLineTag($line, $sectorNumber)) -ge 0) {
            $sector = $sectors[$sectorNumber]
            if ($null -ne $sector.SpecialData) {
                continue
            }

            $result = $true

            # Find lowest and highest floors around sector
            $plat = [Platform]::new($this.world)
            $this.world.Thinkers.Add($plat)
            $plat.Type = $type
            $plat.Sector = $sector
            $plat.Sector.SpecialData = $plat
            $plat.Crush = $false
            $plat.Tag = $line.Tag

            switch ($type) {
                [PlatformType]::RaiseToNearestAndChange {
                    $plat.Speed = $this.platformSpeed / 2
                    $sector.FloorFlat = $line.FrontSide.Sector.FloorFlat
                    $plat.High = $this.FindNextHighestFloor($sector, $sector.FloorHeight)
                    $plat.Wait = 0
                    $plat.Status = [PlatformState]::Up
                    $sector.Special = 0
                    $this.world.StartSound($sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
                    break
                }

                [PlatformType]::RaiseAndChange {
                    $plat.Speed = $this.platformSpeed / 2
                    $sector.FloorFlat = $line.FrontSide.Sector.FloorFlat
                    $plat.High = $sector.FloorHeight + $amount * [Fixed]::One
                    $plat.Wait = 0
                    $plat.Status = [PlatformState]::Up
                    $this.world.StartSound($sector.SoundOrigin, [Sfx]::STNMOV, [SfxType]::Misc)
                    break
                }

                [PlatformType]::DownWaitUpStay {
                    $plat.Speed = $this.platformSpeed * 4
                    $plat.Low = $this.FindLowestFloorSurrounding($sector)
                    if ($plat.Low -gt $sector.FloorHeight) {
                        $plat.Low = $sector.FloorHeight
                    }
                    $plat.High = $sector.FloorHeight
                    $plat.Wait = 35 * $this.platformWait
                    $plat.Status = [PlatformState]::Down
                    $this.world.StartSound($sector.SoundOrigin, [Sfx]::PSTART, [SfxType]::Misc)
                    break
                }

                [PlatformType]::BlazeDwus {
                    $plat.Speed = $this.platformSpeed * 8
                    $plat.Low = $this.FindLowestFloorSurrounding($sector)
                    if ($plat.Low -gt $sector.FloorHeight) {
                        $plat.Low = $sector.FloorHeight
                    }
                    $plat.High = $sector.FloorHeight
                    $plat.Wait = 35 * $this.platformWait
                    $plat.Status = [PlatformState]::Down
                    $this.world.StartSound($sector.SoundOrigin, [Sfx]::PSTART, [SfxType]::Misc)
                    break
                }

                [PlatformType]::PerpetualRaise {
                    $plat.Speed = $this.platformSpeed
                    $plat.Low = $this.FindLowestFloorSurrounding($sector)
                    if ($plat.Low -gt $sector.FloorHeight) {
                        $plat.Low = $sector.FloorHeight
                    }
                    $plat.High = $this.FindHighestFloorSurrounding($sector)
                    if ($plat.High -lt $sector.FloorHeight) {
                        $plat.High = $sector.FloorHeight
                    }
                    $plat.Wait = 35 * $this.platformWait
                    $plat.Status = [PlatformState]($this.world.Random.Next() -band 1)
                    $this.world.StartSound($sector.SoundOrigin, [Sfx]::PSTART, [SfxType]::Misc)
                    break
                }
            }

            $this.AddActivePlatform($plat)
        }

        return $result
    }
    

    # Activate platforms that are in stasis
    [void]ActivateInStasis([int]$tag) {
        for ($i = 0; $i -lt $this.activePlatforms.Length; $i++) {
            if ($null -ne $this.activePlatforms[$i] -and $this.activePlatforms[$i].Tag -eq $tag -and $this.activePlatforms[$i].Status -eq [PlatformState]::InStasis) {
                $this.activePlatforms[$i].Status = $this.activePlatforms[$i].OldStatus
                $this.activePlatforms[$i].ThinkerState = [ThinkerState]::Active
            }
        }
    }

    # Stop platform movement and put it in stasis
    [void]StopPlatform([LineDef]$line) {
        for ($j = 0; $j -lt $this.activePlatforms.Length; $j++) {
            if ($null -ne $this.activePlatforms[$j] -and $this.activePlatforms[$j].Status -ne [PlatformState]::InStasis -and $this.activePlatforms[$j].Tag -eq $line.Tag) {
                $this.activePlatforms[$j].OldStatus = $this.activePlatforms[$j].Status
                $this.activePlatforms[$j].Status = [PlatformState]::InStasis
                $this.activePlatforms[$j].ThinkerState = [ThinkerState]::InStasis
            }
        }
    }

    # Add active platform to array
    [void]AddActivePlatform([Platform]$platform) {
        for ($i = 0; $i -lt $this.activePlatforms.Length; $i++) {
            if ($null -eq $this.activePlatforms[$i]) {
                $this.activePlatforms[$i] = $platform
                return
            }
        }

        throw [System.Exception]::new("Too many active platforms!")
    }

    # Remove platform from active platforms array
    [void]RemoveActivePlatform([Platform]$platform) {
        for ($i = 0; $i -lt $this.activePlatforms.Length; $i++) {
            if ($platform -eq $this.activePlatforms[$i]) {
                $this.activePlatforms[$i].Sector.SpecialData = $null
                $this.world.Thinkers.Remove($this.activePlatforms[$i])
                $this.activePlatforms[$i] = $null
                return
            }
        }

        throw [System.Exception]::new("The platform was not found!")
    }
    
    # Floor Movement
    static [Fixed]$floorSpeed = [Fixed]::One

    [bool] DoFloor([LineDef]$line, [FloorMoveType]$type)
    {
        $sectors = $this.world.Map.Sectors
        $sectorNumber = -1
        $result = $false

        while (($sectorNumber = $this.FindSectorFromLineTag($line, $sectorNumber)) -ge 0)
        {
            $sector = $sectors[$sectorNumber]

            # Already moving? If so, keep going...
            if ($null -ne $sector.SpecialData)
            {
                continue
            }

            $result = $true

            # New floor thinker
            $floor = [FloorMove]::new($this.world)
            $this.world.Thinkers.Add($floor)
            $sector.SpecialData = $floor
            $floor.Type = $type
            $floor.Crush = $false

            switch ($type)
            {
                [FloorMoveType]::LowerFloor {
                    $floor.Direction = -1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $this.FindHighestFloorSurrounding($sector)
                    break
                }

                [FloorMoveType]::LowerFloorToLowest {
                    $floor.Direction = -1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $this.FindLowestFloorSurrounding($sector)
                    break
                }

                [FloorMoveType]::TurboLower {
                    $floor.Direction = -1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed * 4
                    $floor.FloorDestHeight = $this.FindHighestFloorSurrounding($sector)
                    if ($floor.FloorDestHeight -ne $sector.FloorHeight)
                    {
                        $floor.FloorDestHeight += [Fixed]::FromInt(8)
                    }
                    break
                }

                [FloorMoveType]::RaiseFloorCrush {}
                [FloorMoveType]::RaiseFloor {
                    if ($type -eq [FloorMoveType]::RaiseFloorCrush)
                    {
                        $floor.Crush = $true
                    }
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $this.FindLowestCeilingSurrounding($sector)
                    if ($floor.FloorDestHeight -gt $sector.CeilingHeight)
                    {
                        $floor.FloorDestHeight = $sector.CeilingHeight
                    }
                    if ($type -eq [FloorMoveType]::RaiseFloorCrush) {
                        $floor.FloorDestHeight -= [Fixed]::FromInt(8)
                    }

                    break
                }

                [FloorMoveType]::RaiseFloorTurbo {
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed * 4
                    $floor.FloorDestHeight = $this.FindNextHighestFloor($sector, $sector.FloorHeight)
                    break
                }

                [FloorMoveType]::RaiseFloorToNearest {
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $this.FindNextHighestFloor($sector, $sector.FloorHeight)
                    break
                }

                [FloorMoveType]::RaiseFloor24 {
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $floor.Sector.FloorHeight + [Fixed]::FromInt(24)
                    break
                }

                [FloorMoveType]::RaiseFloor512 {
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $floor.Sector.FloorHeight + [Fixed]::FromInt(512)
                    break
                }

                [FloorMoveType]::RaiseFloor24AndChange {
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $floor.Sector.FloorHeight + [Fixed]::FromInt(24)
                    $sector.FloorFlat = $line.FrontSector.FloorFlat
                    $sector.Special = $line.FrontSector.Special
                    break
                }

                [FloorMoveType]::RaiseToTexture {
                    $min = [int]::MaxValue
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $textures = $this.world.Map.Textures
                    for ($i = 0; $i -lt $sector.Lines.Length; $i++)
                    {
                        if (($sector.Lines[$i].Flags -band [LineFlags]::TwoSided) -ne 0)
                        {
                            $frontSide = $sector.Lines[$i].FrontSide
                            if ($frontSide.BottomTexture -ge 0)
                            {
                                if ($textures[$frontSide.BottomTexture].Height -lt $min)
                                {
                                    $min = $textures[$frontSide.BottomTexture].Height
                                }
                            }
                            $backSide = $sector.Lines[$i].BackSide
                            if ($backSide.BottomTexture -ge 0)
                            {
                                if ($textures[$backSide.BottomTexture].Height -lt $min)
                                {
                                    $min = $textures[$backSide.BottomTexture].Height
                                }
                            }
                        }
                    }
                    $floor.FloorDestHeight = $floor.Sector.FloorHeight + [Fixed]::FromInt($min)
                    break
                }

                [FloorMoveType]::LowerAndChange {
                    $floor.Direction = -1
                    $floor.Sector = $sector
                    $floor.Speed = [sectoraction]::floorSpeed
                    $floor.FloorDestHeight = $this.FindLowestFloorSurrounding($sector)
                    $floor.Texture = $sector.FloorFlat
                    for ($i = 0; $i -lt $sector.Lines.Length; $i++)
                    {
                        if (($sector.Lines[$i].Flags -band [LineFlags]::TwoSided) -ne 0)
                        {
                            if ($sector.Lines[$i].FrontSide.Sector.Number -eq $sectorNumber)
                            {
                                $sector = $sector.Lines[$i].BackSide.Sector
                                if ($sector.FloorHeight -eq $floor.FloorDestHeight)
                                {
                                    $floor.Texture = $sector.FloorFlat
                                    $floor.NewSpecial = $sector.Special
                                    break
                                }
                            }
                            else
                            {
                                $sector = $sector.Lines[$i].FrontSide.Sector
                                if ($sector.FloorHeight -eq $floor.FloorDestHeight)
                                {
                                    $floor.Texture = $sector.FloorFlat
                                    $floor.NewSpecial = $sector.Special
                                    break
                                }
                            }
                        }
                    }
                    break
                }
            }
        }

        return $result
    }

    [bool]BuildStairs([LineDef]$line, [StairType]$type)
    {
        $sectors = $this.world.Map.Sectors
        $sectorNumber = -1
        $result = $false

        while (($sectorNumber = $this.FindSectorFromLineTag($line, $sectorNumber)) -ge 0)
        {
            $sector = $sectors[$sectorNumber]

            # Already moving? If so, keep going...
            if ($null -ne $sector.SpecialData)
            {
                continue
            }

            $result = $true

            # New floor thinker
            $floor = [FloorMove]::new($this.world)
            $this.world.Thinkers.Add($floor)
            $sector.SpecialData = $floor
            $floor.Direction = 1
            $floor.Sector = $sector

            
            
            switch ($type)
            {
                [StairType]::Build8 {
                    [Fixed]$function:speed = $this.floorSpeed / 4
                    [Fixed]$function:stairSize = [Fixed]::FromInt(8)
                    break
                }
                [StairType]::Turbo16 {
                    [Fixed]$function:speed = $this.floorSpeed * 4
                    [Fixed]$function:stairSize = [Fixed]::FromInt(16)
                    break
                }
                default {
                    throw [System.Exception]::new("Unknown stair type!")
                }
            }

            $floor.Speed = [Fixed]$function:speed
            $height = $sector.FloorHeight + [Fixed]$function:stairSize
            $floor.FloorDestHeight = $height

            $texture = $sector.FloorFlat

            # Find next sector to raise
            $ok = $false
            do
            {
                $ok = $false

                for ($i = 0; $i -lt $sector.Lines.Length; $i++)
                {
                    if (($sector.Lines[$i]).Flags -band [LineFlags]::TwoSided -eq 0)
                    {
                        continue
                    }

                    $target = ($sector.Lines[$i]).FrontSector
                    $newSectorNumber = $target.Number

                    if ($sectorNumber -ne $newSectorNumber)
                    {
                        continue
                    }

                    $target = ($sector.Lines[$i]).BackSector
                    $newSectorNumber = $target.Number

                    if ($target.FloorFlat -ne $texture)
                    {
                        continue
                    }

                    $height += [Fixed]$function:stairSize

                    if ($null -ne $target.SpecialData)
                    {
                        continue
                    }

                    $sector = $target
                    $sectorNumber = $newSectorNumber
                    $floor = [FloorMove]::new($this.world)

                    $this.world.Thinkers.Add($floor)
                    $sector.SpecialData = $floor
                    $floor.Direction = 1
                    $floor.Sector = $sector
                    $floor.Speed = $function:speed
                    $floor.FloorDestHeight = $height
                    $ok = $true
                    break
                }
            } while ($ok)
        }

        return $result
    }
    
    [bool] DoCeiling([LineDef] $line, [CeilingMoveType] $type) {
        # Reactivate in-stasis ceilings...for certain types.
        switch ($type) {
            {$_ -eq [CeilingMoveType]::FastCrushAndRaise -or
             $_ -eq [CeilingMoveType]::SilentCrushAndRaise -or
             $_ -eq [CeilingMoveType]::CrushAndRaise} {
                $this.ActivateInStasisCeiling($line)
                break
            }
            default { break }
        }
    
        $sectors = $this.world.Map.Sectors
        $sectorNumber = -1
        $result = $false
    
        while (($sectorNumber = $this.FindSectorFromLineTag($line, $sectorNumber)) -ge 0) {
            $sector = $sectors[$sectorNumber]
            if ($null -ne $sector.SpecialData) {
                continue
            }
    
            $result = $true
    
            # New ceiling thinker.
            $ceiling = [CeilingMove]::new($this.world)
            $this.world.Thinkers.Add($ceiling)
            $sector.SpecialData = $ceiling
            $ceiling.Sector = $sector
            $ceiling.Crush = $false
    
            switch ($type) {
                {$_ -eq [CeilingMoveType]::FastCrushAndRaise} {
                    $ceiling.Crush = $true
                    $ceiling.TopHeight = $sector.CeilingHeight
                    $ceiling.BottomHeight = $sector.FloorHeight + [Fixed]::FromInt(8)
                    $ceiling.Direction = -1
                    $ceiling.Speed = $this.CeilingSpeed * 2
                    break
                }
    
                {$_ -eq [CeilingMoveType]::SilentCrushAndRaise -or
                 $_ -eq [CeilingMoveType]::CrushAndRaise -or
                 $_ -eq [CeilingMoveType]::LowerAndCrush -or
                 $_ -eq [CeilingMoveType]::LowerToFloor} {
                    if ($type -eq [CeilingMoveType]::SilentCrushAndRaise -or
                        $type -eq [CeilingMoveType]::CrushAndRaise) {
                        $ceiling.Crush = $true
                        $ceiling.TopHeight = $sector.CeilingHeight
                    }
                    $ceiling.BottomHeight = $sector.FloorHeight
                    if ($type -ne [CeilingMoveType]::LowerToFloor) {
                        $ceiling.BottomHeight += [Fixed]::FromInt(8)
                    }
                    $ceiling.Direction = -1
                    $ceiling.Speed = $this.CeilingSpeed
                    break
                }
    
                {$_ -eq [CeilingMoveType]::RaiseToHighest} {
                    $ceiling.TopHeight = $this.FindHighestCeilingSurrounding($sector)
                    $ceiling.Direction = 1
                    $ceiling.Speed = $this.CeilingSpeed
                    break
                }
            }
    
            $ceiling.Tag = $sector.Tag
            $ceiling.Type = $type
            $this.AddActiveCeiling($ceiling)
        }
    
        return $result
    }
}
