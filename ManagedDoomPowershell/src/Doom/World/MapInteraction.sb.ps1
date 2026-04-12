class MapInteraction {
    static [Fixed] $UseRange = [Fixed]::FromInt(64)
    
    [World] $World
    [Mobj] $UseThing
    [ScriptBlock] $UseTraverseFunc

    MapInteraction([World] $world) {
        $this.World = $world
        $this.InitUse()
    }

    hidden [void] InitUse() {
        $owner = $this
        $this.UseTraverseFunc = { param([Intercept] $intercept) $owner.UseTraverse($intercept) }.GetNewClosure()
    }

    [bool] UseTraverse([Intercept] $intercept) {
        $mc = $this.World.MapCollision
        $player = if ($null -eq $this.UseThing -or $null -eq $this.UseThing.Player) { $null } else { $this.UseThing.Player }

        $side = 0
        if ([Geometry]::PointOnLineSide($this.UseThing.X, $this.UseThing.Y, $intercept.Line) -eq 1) {
            $side = 1
        }

        if ($intercept.Line.Special -eq 0) {
            $mc.LineOpening($intercept.Line)
            if ($mc.OpenRange.Data -le [Fixed]::Zero.Data) {
                $this.World.StartSound($this.UseThing, [Sfx]::NOWAY, [SfxType]::Voice)
                return $false  # Can't use through a wall
            }
            return $true  # Not a special line, keep checking
        }

        $this.UseSpecialLine($this.UseThing, $intercept.Line, $side)
        return $false  # Can't use more than one special line in a row
    }

    [void] UseLines([Player] $player) {
        $pt = $this.World.PathTraversal
        $this.UseThing = $player.Mobj
        $angle = $player.Mobj.Angle

        $x1 = $player.Mobj.X
        $y1 = $player.Mobj.Y
        $x2 = $x1 + [MapInteraction]::UseRange.ToIntFloor() * [Trig]::Cos($angle)
        $y2 = $y1 + [MapInteraction]::UseRange.ToIntFloor() * [Trig]::Sin($angle)

        $pt.PathTraverse($x1, $y1, $x2, $y2, [PathTraverseFlags]::AddLines, $this.UseTraverseFunc)
    }

    [bool] UseSpecialLine([Mobj] $thing, [LineDef] $line, [int] $side) {
        $specials = $this.World.Specials
        $sa = $this.World.SectorAction
        $player = if ($null -eq $thing -or $null -eq $thing.Player) { $null } else { $thing.Player }

        if ($side -ne 0) {
            switch ($line.Special) {
                124 { return $true }  # Sliding door open/close (unused)
                default { return $false }
            }
        }

        if ($null -eq $thing.Player) {
            if ($line.Flags -band [LineFlags]::Secret) { return $false }

            switch ($line.Special) {
                1 {}
                32 {}
                33 {}
                34 {}
                default { return $false }
            }
        }

        switch ($line.Special) {
            1   { $sa.DoLocalDoor($line, $thing) }
            26  { $sa.DoLocalDoor($line, $thing) }
            27  { $sa.DoLocalDoor($line, $thing) }
            28  { $sa.DoLocalDoor($line, $thing) }
            31  { $sa.DoLocalDoor($line, $thing) }
            32  { $sa.DoLocalDoor($line, $thing) }
            33  { $sa.DoLocalDoor($line, $thing) }
            34  { $sa.DoLocalDoor($line, $thing) }
            117 { $sa.DoLocalDoor($line, $thing) }
            118 { $sa.DoLocalDoor($line, $thing) }
            7   { if ($sa.BuildStairs($line, [StairType]::Build8)) { $specials.ChangeSwitchTexture($line, $false) } }
            9   { if ($sa.DoDonut($line)) { $specials.ChangeSwitchTexture($line, $false) } }
            11  { $specials.ChangeSwitchTexture($line, $false); $this.World.ExitLevel() }
            14  { if ($sa.DoPlatform($line, [PlatformType]::RaiseAndChange, 32)) { $specials.ChangeSwitchTexture($line, $false) } }
            15  { if ($sa.DoPlatform($line, [PlatformType]::RaiseAndChange, 24)) { $specials.ChangeSwitchTexture($line, $false) } }
            18  { if ($sa.DoFloor($line, [FloorMoveType]::RaiseFloorToNearest)) { $specials.ChangeSwitchTexture($line, $false) } }
            20  { if ($sa.DoPlatform($line, [PlatformType]::RaiseToNearestAndChange, 0)) { $specials.ChangeSwitchTexture($line, $false) } }
            21  { if ($sa.DoPlatform($line, [PlatformType]::DownWaitUpStay, 0)) { $specials.ChangeSwitchTexture($line, $false) } }
            23  { if ($sa.DoFloor($line, [FloorMoveType]::LowerFloorToLowest)) { $specials.ChangeSwitchTexture($line, $false) } }
            29  { if ($sa.DoDoor($line, [VerticalDoorType]::Normal)) { $specials.ChangeSwitchTexture($line, $false) } }
            41  { if ($sa.DoCeiling($line, [CeilingMoveType]::LowerToFloor)) { $specials.ChangeSwitchTexture($line, $false) } }
            71  { if ($sa.DoFloor($line, [FloorMoveType]::TurboLower)) { $specials.ChangeSwitchTexture($line, $false) } }
            49  { if ($sa.DoCeiling($line, [CeilingMoveType]::CrushAndRaise)) { $specials.ChangeSwitchTexture($line, $false) } }
            50  { if ($sa.DoDoor($line, [VerticalDoorType]::Close)) { $specials.ChangeSwitchTexture($line, $false) } }
            51  { $specials.ChangeSwitchTexture($line, $false); $this.World.SecretExitLevel() }
            55  { if ($sa.DoFloor($line, [FloorMoveType]::RaiseFloorCrush)) { $specials.ChangeSwitchTexture($line, $false) } }
            101 { if ($sa.DoFloor($line, [FloorMoveType]::RaiseFloor)) { $specials.ChangeSwitchTexture($line, $false) } }
            102 { if ($sa.DoFloor($line, [FloorMoveType]::LowerFloor)) { $specials.ChangeSwitchTexture($line, $false) } }
            103 { if ($sa.DoDoor($line, [VerticalDoorType]::Open)) { $specials.ChangeSwitchTexture($line, $false) } }
            111 { if ($sa.DoDoor($line, [VerticalDoorType]::BlazeRaise)) { $specials.ChangeSwitchTexture($line, $false) } }
            112 { if ($sa.DoDoor($line, [VerticalDoorType]::BlazeOpen)) { $specials.ChangeSwitchTexture($line, $false) } }
            113 { if ($sa.DoDoor($line, [VerticalDoorType]::BlazeClose)) { $specials.ChangeSwitchTexture($line, $false) } }
            127 { if ($sa.BuildStairs($line, [StairType]::Turbo16)) { $specials.ChangeSwitchTexture($line, $false) } }
            131 { if ($sa.DoFloor($line, [FloorMoveType]::RaiseFloorTurbo)) { $specials.ChangeSwitchTexture($line, $false) } }
            140 { if ($sa.DoFloor($line, [FloorMoveType]::RaiseFloor512)) { $specials.ChangeSwitchTexture($line, $false) } }
        }

        return $true
    }

    [void] CrossSpecialLine([LineDef] $line, [int] $side, [Mobj] $thing) {
        if ($null -eq $thing.Player) {
            switch ($thing.Type) {
                ([MobjType]::Rocket) { return }
                ([MobjType]::Plasma) { return }
                ([MobjType]::Bfg) { return }
                ([MobjType]::Troopshot) { return }
                ([MobjType]::Headshot) { return }
                ([MobjType]::Bruisershot) { return }
            }

            [bool]$ok = $false
            switch ($line.Special) {
                39 { $ok = $true }
                97 { $ok = $true }
                125 { $ok = $true }
                126 { $ok = $true }
                4 { $ok = $true }
                10 { $ok = $true }
                88 { $ok = $true }
            }

            if (-not $ok) {
                return
            }
        }

        $sa = $this.World.SectorAction

        switch ($line.Special) {
            2 { $sa.DoDoor($line, [VerticalDoorType]::Open); $line.Special = 0 }
            3 { $sa.DoDoor($line, [VerticalDoorType]::Close); $line.Special = 0 }
            4 { $sa.DoDoor($line, [VerticalDoorType]::Normal); $line.Special = 0 }
            5 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor); $line.Special = 0 }
            6 { $sa.DoCeiling($line, [CeilingMoveType]::FastCrushAndRaise); $line.Special = 0 }
            8 { $sa.BuildStairs($line, [StairType]::Build8); $line.Special = 0 }
            10 { $sa.DoPlatform($line, [PlatformType]::DownWaitUpStay, 0); $line.Special = 0 }
            12 { $sa.LightTurnOn($line, 0); $line.Special = 0 }
            13 { $sa.LightTurnOn($line, 255); $line.Special = 0 }
            16 { $sa.DoDoor($line, [VerticalDoorType]::Close30ThenOpen); $line.Special = 0 }
            17 { $sa.StartLightStrobing($line); $line.Special = 0 }
            19 { $sa.DoFloor($line, [FloorMoveType]::LowerFloor); $line.Special = 0 }
            22 { $sa.DoPlatform($line, [PlatformType]::RaiseToNearestAndChange, 0); $line.Special = 0 }
            25 { $sa.DoCeiling($line, [CeilingMoveType]::CrushAndRaise); $line.Special = 0 }
            30 { $sa.DoFloor($line, [FloorMoveType]::RaiseToTexture); $line.Special = 0 }
            35 { $sa.LightTurnOn($line, 35); $line.Special = 0 }
            36 { $sa.DoFloor($line, [FloorMoveType]::TurboLower); $line.Special = 0 }
            37 { $sa.DoFloor($line, [FloorMoveType]::LowerAndChange); $line.Special = 0 }
            38 { $sa.DoFloor($line, [FloorMoveType]::LowerFloorToLowest); $line.Special = 0 }
            39 { $sa.Teleport($line, $side, $thing); $line.Special = 0 }
            40 { $sa.DoCeiling($line, [CeilingMoveType]::RaiseToHighest); $sa.DoFloor($line, [FloorMoveType]::LowerFloorToLowest); $line.Special = 0 }
            44 { $sa.DoCeiling($line, [CeilingMoveType]::LowerAndCrush); $line.Special = 0 }
            52 { $this.World.ExitLevel() }
            53 { $sa.DoPlatform($line, [PlatformType]::PerpetualRaise, 0); $line.Special = 0 }
            54 { $sa.StopPlatform($line); $line.Special = 0 }
            56 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorCrush); $line.Special = 0 }
            57 { $sa.CeilingCrushStop($line); $line.Special = 0 }
            58 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor24); $line.Special = 0 }
            59 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor24AndChange); $line.Special = 0 }
            104 { $sa.TurnTagLightsOff($line); $line.Special = 0 }
            108 { $sa.DoDoor($line, [VerticalDoorType]::BlazeRaise); $line.Special = 0 }
            109 { $sa.DoDoor($line, [VerticalDoorType]::BlazeOpen); $line.Special = 0 }
            100 { $sa.BuildStairs($line, [StairType]::Turbo16); $line.Special = 0 }
            110 { $sa.DoDoor($line, [VerticalDoorType]::BlazeClose); $line.Special = 0 }
            119 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorToNearest); $line.Special = 0 }
            121 { $sa.DoPlatform($line, [PlatformType]::BlazeDwus, 0); $line.Special = 0 }
            124 { $this.World.SecretExitLevel() }
            125 { if ($null -eq $thing.Player) { $sa.Teleport($line, $side, $thing); $line.Special = 0 } }
            130 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorTurbo); $line.Special = 0 }
            141 { $sa.DoCeiling($line, [CeilingMoveType]::SilentCrushAndRaise); $line.Special = 0 }

            72 { $sa.DoCeiling($line, [CeilingMoveType]::LowerAndCrush) }
            73 { $sa.DoCeiling($line, [CeilingMoveType]::CrushAndRaise) }
            74 { $sa.CeilingCrushStop($line) }
            75 { $sa.DoDoor($line, [VerticalDoorType]::Close) }
            76 { $sa.DoDoor($line, [VerticalDoorType]::Close30ThenOpen) }
            77 { $sa.DoCeiling($line, [CeilingMoveType]::FastCrushAndRaise) }
            79 { $sa.LightTurnOn($line, 35) }
            80 { $sa.LightTurnOn($line, 0) }
            81 { $sa.LightTurnOn($line, 255) }
            82 { $sa.DoFloor($line, [FloorMoveType]::LowerFloorToLowest) }
            83 { $sa.DoFloor($line, [FloorMoveType]::LowerFloor) }
            84 { $sa.DoFloor($line, [FloorMoveType]::LowerAndChange) }
            86 { $sa.DoDoor($line, [VerticalDoorType]::Open) }
            87 { $sa.DoPlatform($line, [PlatformType]::PerpetualRaise, 0) }
            88 { $sa.DoPlatform($line, [PlatformType]::DownWaitUpStay, 0) }
            89 { $sa.StopPlatform($line) }
            90 { $sa.DoDoor($line, [VerticalDoorType]::Normal) }
            91 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor) }
            92 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor24) }
            93 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor24AndChange) }
            94 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorCrush) }
            95 { $sa.DoPlatform($line, [PlatformType]::RaiseToNearestAndChange, 0) }
            96 { $sa.DoFloor($line, [FloorMoveType]::RaiseToTexture) }
            97 { $sa.Teleport($line, $side, $thing) }
            98 { $sa.DoFloor($line, [FloorMoveType]::TurboLower) }
            105 { $sa.DoDoor($line, [VerticalDoorType]::BlazeRaise) }
            106 { $sa.DoDoor($line, [VerticalDoorType]::BlazeOpen) }
            107 { $sa.DoDoor($line, [VerticalDoorType]::BlazeClose) }
            120 { $sa.DoPlatform($line, [PlatformType]::BlazeDwus, 0) }
            126 { if ($null -eq $thing.Player) { $sa.Teleport($line, $side, $thing) } }
            128 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorToNearest) }
            129 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloorTurbo) }
        }
    }

    [void] ShootSpecialLine([Mobj] $thing, [LineDef] $line) {
        if ($null -eq $thing.Player -and $line.Special -ne 46) {
            return
        }

        $sa = $this.World.SectorAction
        $specials = $this.World.Specials

        switch ($line.Special) {
            24 { $sa.DoFloor($line, [FloorMoveType]::RaiseFloor); $specials.ChangeSwitchTexture($line, $false) }
            46 { $sa.DoDoor($line, [VerticalDoorType]::Open); $specials.ChangeSwitchTexture($line, $true) }
            47 { $sa.DoPlatform($line, [PlatformType]::RaiseToNearestAndChange, 0); $specials.ChangeSwitchTexture($line, $false) }
        }
    }
}
