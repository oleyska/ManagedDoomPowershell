class SaveAndLoad {
    static [int] $DescriptionSize = 24
    static [int] $VersionSize = 16
    static [int] $SaveBufferSize = 360 * 1024

    static [void] Save([DoomGame] $game, [string] $description, [string] $path) {
        $sg = [SaveGame]::new($description)
        $sg.Save($game, $path)
    }

    static [void] Load([DoomGame] $game, [string] $path) {
        $options = $game.Options
        $game.InitNew($options.Skill, $options.Episode, $options.Map)

        $lg = [LoadGame]::new([System.IO.File]::ReadAllBytes($path))
        $lg.Load($game)
    }
}
enum ThinkerClass
{
    End
    Mobj
}

enum SpecialClass
{
    Ceiling
    Door
    Floor
    Plat
    Flash
    Strobe
    Glow
    EndSpecials
}
# Save Game
class SaveGame {
    [byte[]] $Data
    [int] $Ptr

    SaveGame([string] $description) {
        $this.Data = New-Object byte[] $([SaveAndLoad]::SaveBufferSize)
        $this.Ptr = 0

        $this.WriteDescription($description)
        $this.WriteVersion()
    }

    [void] Save([DoomGame] $game, [string] $path) {
        $options = $game.World.Options
        $this.Data[$this.Ptr++] = [byte]$options.Skill
        $this.Data[$this.Ptr++] = [byte]$options.Episode
        $this.Data[$this.Ptr++] = [byte]$options.Map

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $this.Data[$this.Ptr++] = if ($options.Players[$i].InGame) { 1 } else { 0 }
        }

        $this.Data[$this.Ptr++] = [byte]($game.World.LevelTime -shr 16)
        $this.Data[$this.Ptr++] = [byte]($game.World.LevelTime -shr 8)
        $this.Data[$this.Ptr++] = [byte]$game.World.LevelTime

        $this.ArchivePlayers($game.World)
        $this.ArchiveWorld($game.World)
        $this.ArchiveThinkers($game.World)
        $this.ArchiveSpecials($game.World)

        $this.Data[$this.Ptr++] = 0x1d

        [System.IO.File]::WriteAllBytes($path, $this.Data[0..($this.Ptr - 1)])
    }

    [void] WriteDescription([string] $description) {
        if ($null -eq $description) {
            $description = ""
        }
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($description)
        $length = [math]::Min($bytes.Length, [SaveAndLoad]::DescriptionSize)
        [System.Array]::Copy($bytes, 0, $this.Data, 0, $length)
        $this.Ptr += [SaveAndLoad]::DescriptionSize
    }

    [void] WriteVersion() {
        $version = "VERSION 109"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($version)
        $length = [math]::Min($bytes.Length, [SaveAndLoad]::VersionSize)
        [System.Array]::Copy($bytes, 0, $this.Data, $this.Ptr, $length)
        $this.Ptr += [SaveAndLoad]::VersionSize
    }

    [void] PadPointer() {
        $this.Ptr += (4 - ($this.Ptr -band 3)) -band 3
    }

    [void] ArchivePlayers([World] $world) {
        $players = $world.Options.Players
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if (-not $players[$i].InGame) {
                continue
            }

            $this.PadPointer()
            $this.Ptr = [SaveGame]::ArchivePlayer($players[$i], $this.Data, $this.Ptr)
        }
    }

    [void] ArchiveWorld([World] $world) {
        # Archive sectors
        $sectors = $world.Map.Sectors
        for ($i = 0; $i -lt $sectors.Length; $i++) {
            $this.Ptr = [SaveGame]::ArchiveSector($sectors[$i], $this.Data, $this.Ptr)
        }

        # Archive lines
        $lines = $world.Map.Lines
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $this.Ptr = [SaveGame]::ArchiveLine($lines[$i], $this.Data, $this.Ptr)
        }
    }
    [void] ArchiveThinkers([World] $world) {
        $thinkers = $world.Thinkers

        # Read in saved thinkers.
        $thinker = $thinkers.Cap.Next
        while ($thinker -ne $thinkers.Cap) {
            $mobj = $thinker -as [Mobj]
            if ($null -ne $mobj) {
                $this.Data[$this.Ptr++] = [byte][ThinkerClass]::Mobj
                $this.PadPointer()

                [SaveGame]::WriteThinkerState($this.Data, $this.Ptr + 8, $mobj.ThinkerState)
                [SaveGame]::Write($this.Data, $this.Ptr + 12, $mobj.X.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 16, $mobj.Y.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 20, $mobj.Z.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 32, $mobj.Angle.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 36, [int]$mobj.Sprite)
                [SaveGame]::Write($this.Data, $this.Ptr + 40, $mobj.Frame)
                [SaveGame]::Write($this.Data, $this.Ptr + 56, $mobj.FloorZ.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 60, $mobj.CeilingZ.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 64, $mobj.Radius.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 68, $mobj.Height.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 72, $mobj.MomX.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 76, $mobj.MomY.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 80, $mobj.MomZ.Data)
                [SaveGame]::Write($this.Data, $this.Ptr + 88, [int]$mobj.Type)
                [SaveGame]::Write($this.Data, $this.Ptr + 96, $mobj.Tics)
                [SaveGame]::Write($this.Data, $this.Ptr + 100, $mobj.State.Number)
                [SaveGame]::Write($this.Data, $this.Ptr + 104, [int]$mobj.Flags)
                [SaveGame]::Write($this.Data, $this.Ptr + 108, $mobj.Health)
                [SaveGame]::Write($this.Data, $this.Ptr + 112, [int]$mobj.MoveDir)
                [SaveGame]::Write($this.Data, $this.Ptr + 116, $mobj.MoveCount)
                [SaveGame]::Write($this.Data, $this.Ptr + 124, $mobj.ReactionTime)
                [SaveGame]::Write($this.Data, $this.Ptr + 128, $mobj.Threshold)

                if ($null -eq $mobj.Player) {
                    [SaveGame]::Write($this.Data, $this.Ptr + 132, 0)
                } else {
                    [SaveGame]::Write($this.Data, $this.Ptr + 132, $mobj.Player.Number + 1)
                }

                [SaveGame]::Write($this.Data, $this.Ptr + 136, $mobj.LastLook)

                if ($null -eq $mobj.SpawnPoint) {
                    [SaveGame]::Write($this.Data, $this.Ptr + 140, [short]0)
                    [SaveGame]::Write($this.Data, $this.Ptr + 142, [short]0)
                    [SaveGame]::Write($this.Data, $this.Ptr + 144, [short]0)
                    [SaveGame]::Write($this.Data, $this.Ptr + 146, [short]0)
                    [SaveGame]::Write($this.Data, $this.Ptr + 148, [short]0)
                } else {
                    [SaveGame]::Write($this.Data, $this.Ptr + 140, [short]$mobj.SpawnPoint.X.ToIntFloor())
                    [SaveGame]::Write($this.Data, $this.Ptr + 142, [short]$mobj.SpawnPoint.Y.ToIntFloor())
                    [SaveGame]::Write($this.Data, $this.Ptr + 144, [short][math]::Round($mobj.SpawnPoint.Angle.ToDegree()))
                    [SaveGame]::Write($this.Data, $this.Ptr + 146, [short]$mobj.SpawnPoint.Type)
                    [SaveGame]::Write($this.Data, $this.Ptr + 148, [short]$mobj.SpawnPoint.Flags)
                }

                $this.Ptr += 154
            }

            $thinker = $thinker.Next
        }

        $this.Data[$this.Ptr++] = [byte][ThinkerClass]::End
    }
    [void] ArchiveSpecials([World] $world) {
        $thinkers = $world.Thinkers
        $sa = $world.SectorAction

        # Read in saved thinkers
        $thinker = $thinkers.Cap.Next
        while ($thinker -ne $thinkers.Cap) {
            $next = $thinker.Next
            if ($thinker.ThinkerState -eq [ThinkerState]::InStasis) {
                $ceiling = $thinker -as [CeilingMove]
                if ($null -ne $ceiling) {
                    if ($sa.CheckActiveCeiling($ceiling)) {
                        $this.Data[$this.Ptr++] = [byte][SpecialClass]::Ceiling
                        $this.PadPointer()
                        [SaveGame]::WriteThinkerState($this.Data, $this.Ptr + 8, $ceiling.ThinkerState)
                        [SaveGame]::Write($this.Data, $this.Ptr + 12, [int]$ceiling.Type)
                        [SaveGame]::Write($this.Data, $this.Ptr + 16, $ceiling.Sector.Number)
                        [SaveGame]::Write($this.Data, $this.Ptr + 20, $ceiling.BottomHeight.Data)
                        [SaveGame]::Write($this.Data, $this.Ptr + 24, $ceiling.TopHeight.Data)
                        [SaveGame]::Write($this.Data, $this.Ptr + 28, $ceiling.Speed.Data)
                        [SaveGame]::Write($this.Data, $this.Ptr + 32, ($ceiling.Crush -eq $true) ? 1 : 0)
                        [SaveGame]::Write($this.Data, $this.Ptr + 36, $ceiling.Direction)
                        [SaveGame]::Write($this.Data, $this.Ptr + 40, $ceiling.Tag)
                        [SaveGame]::Write($this.Data, $this.Ptr + 44, $ceiling.OldDirection)
                        $this.Ptr += 48
                    }
                    $thinker = $next
                    continue
                }
            }

            foreach ($type in @("CeilingMove", "VerticalDoor", "FloorMove", "Platform", "LightFlash", "StrobeFlash", "GlowingLight")) {
                $special = $thinker -as ([Type]$type)
                if ($null -ne $special) {
                    $specialClass = switch ($type) {
                        "CeilingMove" { [SpecialClass]::Ceiling }
                        "VerticalDoor" { [SpecialClass]::Door }
                        "FloorMove" { [SpecialClass]::Floor }
                        "Platform" { [SpecialClass]::Plat }
                        "LightFlash" { [SpecialClass]::Flash }
                        "StrobeFlash" { [SpecialClass]::Strobe }
                        "GlowingLight" { [SpecialClass]::Glow }
                    }
                    $this.Data[$this.Ptr++] = [byte]$specialClass
                    $this.PadPointer()
                    [SaveGame]::WriteThinkerState($this.Data, $this.Ptr + 8, $special.ThinkerState)
                    
                    switch ($type) {
                        "CeilingMove" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, [int]$special.Type)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.BottomHeight.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.TopHeight.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, $special.Speed.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, ($special.Crush -eq $true) ? 1 : 0)
                            [SaveGame]::Write($this.Data, $this.Ptr + 36, $special.Direction)
                            [SaveGame]::Write($this.Data, $this.Ptr + 40, $special.Tag)
                            [SaveGame]::Write($this.Data, $this.Ptr + 44, $special.OldDirection)
                            $this.Ptr += 48
                        }
                        "VerticalDoor" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, [int]$special.Type)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.TopHeight.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.Speed.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, $special.Direction)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, $special.TopWait)
                            [SaveGame]::Write($this.Data, $this.Ptr + 36, $special.TopCountDown)
                            $this.Ptr += 40
                        }
                        "FloorMove" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, [int]$special.Type)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, ($special.Crush -eq $true) ? 1 : 0)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.Direction)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, [int]$special.NewSpecial)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, $special.Texture)
                            [SaveGame]::Write($this.Data, $this.Ptr + 36, $special.FloorDestHeight.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 40, $special.Speed.Data)
                            $this.Ptr += 44
                        }
                        "Platform" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.Speed.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.Low.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.High.Data)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, $special.Wait)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, $special.Count)
                            [SaveGame]::Write($this.Data, $this.Ptr + 36, [int]$special.Status)
                            [SaveGame]::Write($this.Data, $this.Ptr + 40, [int]$special.OldStatus)
                            [SaveGame]::Write($this.Data, $this.Ptr + 44, ($special.Crush -eq $true) ? 1 : 0)
                            [SaveGame]::Write($this.Data, $this.Ptr + 48, $special.Tag)
                            [SaveGame]::Write($this.Data, $this.Ptr + 52, [int]$special.Type)
                            $this.Ptr += 56
                        }
                        "LightFlash" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.Count)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.MaxLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.MinLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, $special.MaxTime)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, $special.MinTime)
                            $this.Ptr += 36
                        }
                        "StrobeFlash" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.Count)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.MinLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.MaxLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 28, $special.DarkTime)
                            [SaveGame]::Write($this.Data, $this.Ptr + 32, $special.BrightTime)
                            $this.Ptr += 36
                        }
                        "GlowingLight" {
                            [SaveGame]::Write($this.Data, $this.Ptr + 12, $special.Sector.Number)
                            [SaveGame]::Write($this.Data, $this.Ptr + 16, $special.MinLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 20, $special.MaxLight)
                            [SaveGame]::Write($this.Data, $this.Ptr + 24, $special.Direction)
                            $this.Ptr += 28
                        }
                    }
                    continue
                }
            }

            $thinker = $next
        }

        $this.Data[$this.Ptr++] = [byte][SpecialClass]::EndSpecials
    }
    static [int] ArchivePlayer([Player] $player, [byte[]] $data, [int] $p) {
        [SaveGame]::Write($data, $p + 4, [int]$player.PlayerState)
        [SaveGame]::Write($data, $p + 16, $player.ViewZ.Data)
        [SaveGame]::Write($data, $p + 20, $player.ViewHeight.Data)
        [SaveGame]::Write($data, $p + 24, $player.DeltaViewHeight.Data)
        [SaveGame]::Write($data, $p + 28, $player.Bob.Data)
        [SaveGame]::Write($data, $p + 32, $player.Health)
        [SaveGame]::Write($data, $p + 36, $player.ArmorPoints)
        [SaveGame]::Write($data, $p + 40, $player.ArmorType)

        for ($i = 0; $i -lt [PowerType]::Count; $i++) {
            [SaveGame]::Write($data, $p + 44 + 4 * $i, $player.Powers[$i])
        }

        for ($i = 0; $i -lt [PowerType]::Count; $i++) {
            [SaveGame]::Write($data, $p + 68 + 4 * $i, $player.Cards[$i] ? 1 : 0)
        }

        [SaveGame]::Write($data, $p + 92, $player.Backpack ? 1 : 0)

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            [SaveGame]::Write($data, $p + 96 + 4 * $i, $player.Frags[$i])
        }

        [SaveGame]::Write($data, $p + 112, [int]$player.ReadyWeapon)
        [SaveGame]::Write($data, $p + 116, [int]$player.PendingWeapon)

        for ($i = 0; $i -lt [WeaponType]::Count; $i++) {
            [SaveGame]::Write($data, $p + 120 + 4 * $i, $player.WeaponOwned[$i] ? 1 : 0)
        }

        for ($i = 0; $i -lt [AmmoType]::Count; $i++) {
            [SaveGame]::Write($data, $p + 156 + 4 * $i, $player.Ammo[$i])
        }

        for ($i = 0; $i -lt [AmmoType]::Count; $i++) {
            [SaveGame]::Write($data, $p + 172 + 4 * $i, $player.MaxAmmo[$i])
        }

        [SaveGame]::Write($data, $p + 188, $player.AttackDown ? 1 : 0)
        [SaveGame]::Write($data, $p + 192, $player.UseDown ? 1 : 0)
        [SaveGame]::Write($data, $p + 196, [int]$player.Cheats)
        [SaveGame]::Write($data, $p + 200, $player.Refire)
        [SaveGame]::Write($data, $p + 204, $player.KillCount)
        [SaveGame]::Write($data, $p + 208, $player.ItemCount)
        [SaveGame]::Write($data, $p + 212, $player.SecretCount)
        [SaveGame]::Write($data, $p + 220, $player.DamageCount)
        [SaveGame]::Write($data, $p + 224, $player.BonusCount)
        [SaveGame]::Write($data, $p + 232, $player.ExtraLight)
        [SaveGame]::Write($data, $p + 236, $player.FixedColorMap)
        [SaveGame]::Write($data, $p + 240, $player.ColorMap)

        for ($i = 0; $i -lt [PlayerSprite]::Count; $i++) {
            if ($null -eq $player.PlayerSprites[$i].State) {
                [SaveGame]::Write($data, $p + 244 + 16 * $i, 0)
            } else {
                [SaveGame]::Write($data, $p + 244 + 16 * $i, $player.PlayerSprites[$i].State.Number)
            }

            [SaveGame]::Write($data, $p + 244 + 16 * $i + 4, $player.PlayerSprites[$i].Tics)
            [SaveGame]::Write($data, $p + 244 + 16 * $i + 8, $player.PlayerSprites[$i].Sx.Data)
            [SaveGame]::Write($data, $p + 244 + 16 * $i + 12, $player.PlayerSprites[$i].Sy.Data)
        }

        [SaveGame]::Write($data, $p + 276, $player.DidSecret ? 1 : 0)

        return $p + 280
    }
    static [int] ArchiveSector([Sector] $sector, [byte[]] $data, [int] $p) {
        [SaveGame]::Write($data, $p, [short]$sector.FloorHeight.ToIntFloor())
        [SaveGame]::Write($data, $p + 2, [short]$sector.CeilingHeight.ToIntFloor())
        [SaveGame]::Write($data, $p + 4, [short]$sector.FloorFlat)
        [SaveGame]::Write($data, $p + 6, [short]$sector.CeilingFlat)
        [SaveGame]::Write($data, $p + 8, [short]$sector.LightLevel)
        [SaveGame]::Write($data, $p + 10, [short]$sector.Special)
        [SaveGame]::Write($data, $p + 12, [short]$sector.Tag)

        return $p + 14
    }

    static [int] ArchiveLine([LineDef] $line, [byte[]] $data, [int] $p) {
        [SaveGame]::Write($data, $p, [short]$line.Flags)
        [SaveGame]::Write($data, $p + 2, [short]$line.Special)
        [SaveGame]::Write($data, $p + 4, [short]$line.Tag)
        $p += 6

        if ($null -ne $line.FrontSide) {
            $side = $line.FrontSide
            [SaveGame]::Write($data, $p, [short]$side.TextureOffset.ToIntFloor())
            [SaveGame]::Write($data, $p + 2, [short]$side.RowOffset.ToIntFloor())
            [SaveGame]::Write($data, $p + 4, [short]$side.TopTexture)
            [SaveGame]::Write($data, $p + 6, [short]$side.BottomTexture)
            [SaveGame]::Write($data, $p + 8, [short]$side.MiddleTexture)
            $p += 10
        }

        if ($null -ne $line.BackSide) {
            $side = $line.BackSide
            [SaveGame]::Write($data, $p, [short]$side.TextureOffset.ToIntFloor())
            [SaveGame]::Write($data, $p + 2, [short]$side.RowOffset.ToIntFloor())
            [SaveGame]::Write($data, $p + 4, [short]$side.TopTexture)
            [SaveGame]::Write($data, $p + 6, [short]$side.BottomTexture)
            [SaveGame]::Write($data, $p + 8, [short]$side.MiddleTexture)
            $p += 10
        }

        return $p
    }

    static [void] Write([byte[]] $data, [int] $p, [int] $value) {
        $data[$p] = [byte]($value -band 0xFF)
        $data[$p + 1] = [byte](($value -shr 8) -band 0xFF)
        $data[$p + 2] = [byte](($value -shr 16) -band 0xFF)
        $data[$p + 3] = [byte](($value -shr 24) -band 0xFF)
    }
    static [void] Write([byte[]] $data, [int] $p, [uint32] $value) {
        $data[$p] = [byte]($value -band 0xFF)
        $data[$p + 1] = [byte](($value -shr 8) -band 0xFF)
        $data[$p + 2] = [byte](($value -shr 16) -band 0xFF)
        $data[$p + 3] = [byte](($value -shr 24) -band 0xFF)
    }

    static [void] Write([byte[]] $data, [int] $p, [int16] $value) {
        $data[$p] = [byte]($value -band 0xFF)
        $data[$p + 1] = [byte](($value -shr 8) -band 0xFF)
    }

    static [void] WriteThinkerState([byte[]] $data, [int] $p, [ThinkerState] $state) {
        switch ($state) {
            ([ThinkerState]::InStasis) {
                [SaveGame]::Write($data, $p, 0)
                break
            }
            default {
                [SaveGame]::Write($data, $p, 1)
                break
            }
        }
    }
}
# Load game
class LoadGame {
    [byte[]] $Data
    [int] $Ptr

    LoadGame([byte[]] $data) {
        $this.Data = $data
        $this.Ptr = 0

        $this.ReadDescription()

        $version = $this.ReadVersion()
        if ($version -ne "VERSION 109") {
            throw "Unsupported version!"
        }
    }

    [void] Load([DoomGame] $game) {
        $options = $game.World.Options
        $options.Skill = [GameSkill]$this.Data[$this.Ptr++]
        $options.Episode = $this.Data[$this.Ptr++]
        $options.Map = $this.Data[$this.Ptr++]

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $options.Players[$i].InGame = $this.Data[$this.Ptr++] -ne 0
        }

        $game.InitNew($options.Skill, $options.Episode, $options.Map)

        $a = $this.Data[$this.Ptr++]
        $b = $this.Data[$this.Ptr++]
        $c = $this.Data[$this.Ptr++]
        $levelTime = ($a -shl 16) + ($b -shl 8) + $c

        $this.UnArchivePlayers($game.World)
        $this.UnArchiveWorld($game.World)
        $this.UnArchiveThinkers($game.World)
        $this.UnArchiveSpecials($game.World)

        if ($this.Data[$this.Ptr] -ne 0x1d) {
            throw "Bad savegame!"
        }

        $game.World.LevelTime = $levelTime

        $options.Sound.SetListener($game.World.ConsolePlayer.Mobj)
    }
    [void] PadPointer() {
        $this.Ptr += (4 - ($this.Ptr -band 3)) -band 3
    }

    [string] ReadDescription() {
        $value = [DoomInterop]::ToString($this.Data, $this.Ptr, [SaveAndLoad]::DescriptionSize)
        $this.Ptr += [SaveAndLoad]::DescriptionSize
        return $value
    }

    [string] ReadVersion() {
        $value = [DoomInterop]::ToString($this.Data, $this.Ptr, [SaveAndLoad]::VersionSize)
        $this.Ptr += [SaveAndLoad]::VersionSize
        return $value
    }

    [void] UnArchivePlayers([World] $world) {
        $players = $world.Options.Players
        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            if (-not $players[$i].InGame) {
                continue
            }

            $this.PadPointer()
            $this.Ptr = [LoadGame]::UnArchivePlayer($players[$i], $this.Data, $this.Ptr)
        }
    }

    [void] UnArchiveWorld([World] $world) {
        $sectors = $world.Map.Sectors
        for ($i = 0; $i -lt $sectors.Length; $i++) {
            $this.Ptr = [LoadGame]::UnArchiveSector($sectors[$i], $this.Data, $this.Ptr)
        }

        $lines = $world.Map.Lines
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $this.Ptr = [LoadGame]::UnArchiveLine($lines[$i], $this.Data, $this.Ptr)
        }
    }
    [void] UnArchiveThinkers([World] $world) {
        $thinkers = $world.Thinkers
        $ta = $world.ThingAllocation

        # Remove all the current thinkers.
        $thinker = $thinkers.Cap.Next
        while ($thinker -ne $thinkers.Cap) {
            $next = $thinker.Next
            $mobj = $thinker -as [Mobj]
            if ($null -ne $mobj) {
                $ta.RemoveMobj($mobj)
            }
            $thinker = $next
        }
        $thinkers.Reset()

        # Read in saved thinkers.
        while ($true) {
            $tclass = [ThinkerClass]$this.Data[$this.Ptr++]
            switch ($tclass) {
                ([ThinkerClass]::End) {
                    # End of list.
                    return
                }

                ([ThinkerClass]::Mobj) {
                    $this.PadPointer()
                    $mobj = [Mobj]::new($world)
                    $mobj.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $mobj.X = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 12))
                    $mobj.Y = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 16))
                    $mobj.Z = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 20))
                    $mobj.Angle = [Angle]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 32))
                    $mobj.Sprite = [Sprite][BitConverter]::ToInt32($this.Data, $this.Ptr + 36)
                    $mobj.Frame = [BitConverter]::ToInt32($this.Data, $this.Ptr + 40)
                    $mobj.FloorZ = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 56))
                    $mobj.CeilingZ = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 60))
                    $mobj.Radius = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 64))
                    $mobj.Height = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 68))
                    $mobj.MomX = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 72))
                    $mobj.MomY = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 76))
                    $mobj.MomZ = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 80))
                    $mobj.Type = [MobjType][BitConverter]::ToInt32($this.Data, $this.Ptr + 88)
                    $mobj.Info = [DoomInfo]::MobjInfos[[int]$mobj.Type]
                    $mobj.Tics = [BitConverter]::ToInt32($this.Data, $this.Ptr + 96)
                    $mobj.State = [DoomInfo]::States.all[[BitConverter]::ToInt32($this.Data, $this.Ptr + 100)]
                    $mobj.Flags = [MobjFlags][BitConverter]::ToInt32($this.Data, $this.Ptr + 104)
                    $mobj.Health = [BitConverter]::ToInt32($this.Data, $this.Ptr + 108)
                    $mobj.MoveDir = [Direction][BitConverter]::ToInt32($this.Data, $this.Ptr + 112)
                    $mobj.MoveCount = [BitConverter]::ToInt32($this.Data, $this.Ptr + 116)
                    $mobj.ReactionTime = [BitConverter]::ToInt32($this.Data, $this.Ptr + 124)
                    $mobj.Threshold = [BitConverter]::ToInt32($this.Data, $this.Ptr + 128)

                    $playerNumber = [BitConverter]::ToInt32($this.Data, $this.Ptr + 132)
                    if ($playerNumber -ne 0) {
                        $mobj.Player = $world.Options.Players[$playerNumber - 1]
                        $mobj.Player.Mobj = $mobj
                    }

                    $mobj.LastLook = [BitConverter]::ToInt32($this.Data, $this.Ptr + 136)
                    $mobj.SpawnPoint = [MapThing]::new(
                        [Fixed]::FromInt([BitConverter]::ToInt16($this.Data, $this.Ptr + 140)),
                        [Fixed]::FromInt([BitConverter]::ToInt16($this.Data, $this.Ptr + 142)),
                        [Angle]::new([Angle]::Ang45.Data * [uint]([BitConverter]::ToInt16($this.Data, $this.Ptr + 144) / 45)),
                        [BitConverter]::ToInt16($this.Data, $this.Ptr + 146),
                        [ThingFlags][BitConverter]::ToInt16($this.Data, $this.Ptr + 148)
                    )

                    $this.Ptr += 154

                    $world.ThingMovement.SetThingPosition($mobj)
                    $thinkers.Add($mobj)
                    break
                }

                default {
                    throw "Unknown thinker class in savegame!"
                }
            }
        }
    }
    [void] UnArchiveSpecials([World] $world) {
        $thinkers = $world.Thinkers
        $sa = $world.SectorAction

        # Read in saved thinkers.
        while ($true) {
            $tclass = [SpecialClass]$this.Data[$this.Ptr++]
            switch ($tclass) {
                ([SpecialClass]::EndSpecials) {
                    # End of list.
                    return
                }

                ([SpecialClass]::Ceiling) {
                    $this.PadPointer()
                    $ceiling = [CeilingMove]::new($world)
                    $ceiling.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $ceiling.Type = [CeilingMoveType][BitConverter]::ToInt32($this.Data, $this.Ptr + 12)
                    $ceiling.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 16)]
                    $ceiling.Sector.SpecialData = $ceiling
                    $ceiling.BottomHeight = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 20))
                    $ceiling.TopHeight = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 24))
                    $ceiling.Speed = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 28))
                    $ceiling.Crush = ([BitConverter]::ToInt32($this.Data, $this.Ptr + 32) -ne 0)
                    $ceiling.Direction = [BitConverter]::ToInt32($this.Data, $this.Ptr + 36)
                    $ceiling.Tag = [BitConverter]::ToInt32($this.Data, $this.Ptr + 40)
                    $ceiling.OldDirection = [BitConverter]::ToInt32($this.Data, $this.Ptr + 44)
                    $this.Ptr += 48

                    $thinkers.Add($ceiling)
                    $sa.AddActiveCeiling($ceiling)
                    break
                }

                ([SpecialClass]::Door) {
                    $this.PadPointer()
                    $door = [VerticalDoor]::new($world)
                    $door.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $door.Type = [VerticalDoorType][BitConverter]::ToInt32($this.Data, $this.Ptr + 12)
                    $door.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 16)]
                    $door.Sector.SpecialData = $door
                    $door.TopHeight = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 20))
                    $door.Speed = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 24))
                    $door.Direction = [BitConverter]::ToInt32($this.Data, $this.Ptr + 28)
                    $door.TopWait = [BitConverter]::ToInt32($this.Data, $this.Ptr + 32)
                    $door.TopCountDown = [BitConverter]::ToInt32($this.Data, $this.Ptr + 36)
                    $this.Ptr += 40

                    $thinkers.Add($door)
                    break
                }

                ([SpecialClass]::Floor) {
                    $this.PadPointer()
                    $floor = [FloorMove]::new($world)
                    $floor.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $floor.Type = [FloorMoveType][BitConverter]::ToInt32($this.Data, $this.Ptr + 12)
                    $floor.Crush = ([BitConverter]::ToInt32($this.Data, $this.Ptr + 16) -ne 0)
                    $floor.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 20)]
                    $floor.Sector.SpecialData = $floor
                    $floor.Direction = [BitConverter]::ToInt32($this.Data, $this.Ptr + 24)
                    $floor.NewSpecial = [SectorSpecial][BitConverter]::ToInt32($this.Data, $this.Ptr + 28)
                    $floor.Texture = [BitConverter]::ToInt32($this.Data, $this.Ptr + 32)
                    $floor.FloorDestHeight = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 36))
                    $floor.Speed = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 40))
                    $this.Ptr += 44

                    $thinkers.Add($floor)
                    break
                }

                ([SpecialClass]::Plat) {
                    $this.PadPointer()
                    $plat = [Platform]::new($world)
                    $plat.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $plat.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 12)]
                    $plat.Sector.SpecialData = $plat
                    $plat.Speed = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 16))
                    $plat.Low = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 20))
                    $plat.High = [Fixed]::new([BitConverter]::ToInt32($this.Data, $this.Ptr + 24))
                    $plat.Wait = [BitConverter]::ToInt32($this.Data, $this.Ptr + 28)
                    $plat.Count = [BitConverter]::ToInt32($this.Data, $this.Ptr + 32)
                    $plat.Status = [PlatformState][BitConverter]::ToInt32($this.Data, $this.Ptr + 36)
                    $plat.OldStatus = [PlatformState][BitConverter]::ToInt32($this.Data, $this.Ptr + 40)
                    $plat.Crush = ([BitConverter]::ToInt32($this.Data, $this.Ptr + 44) -ne 0)
                    $plat.Tag = [BitConverter]::ToInt32($this.Data, $this.Ptr + 48)
                    $plat.Type = [PlatformType][BitConverter]::ToInt32($this.Data, $this.Ptr + 52)
                    $this.Ptr += 56

                    $thinkers.Add($plat)
                    $sa.AddActivePlatform($plat)
                    break
                }

                ([SpecialClass]::Flash) {
                    $this.PadPointer()
                    $flash = [LightFlash]::new($world)
                    $flash.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $flash.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 12)]
                    $flash.Count = [BitConverter]::ToInt32($this.Data, $this.Ptr + 16)
                    $flash.MaxLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 20)
                    $flash.MinLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 24)
                    $flash.MaxTime = [BitConverter]::ToInt32($this.Data, $this.Ptr + 28)
                    $flash.MinTime = [BitConverter]::ToInt32($this.Data, $this.Ptr + 32)
                    $this.Ptr += 36

                    $thinkers.Add($flash)
                    break
                }

                ([SpecialClass]::Strobe) {
                    $this.PadPointer()
                    $strobe = [StrobeFlash]::new($world)
                    $strobe.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $strobe.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 12)]
                    $strobe.Count = [BitConverter]::ToInt32($this.Data, $this.Ptr + 16)
                    $strobe.MinLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 20)
                    $strobe.MaxLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 24)
                    $strobe.DarkTime = [BitConverter]::ToInt32($this.Data, $this.Ptr + 28)
                    $strobe.BrightTime = [BitConverter]::ToInt32($this.Data, $this.Ptr + 32)
                    $this.Ptr += 36

                    $thinkers.Add($strobe)
                    break
                }

                ([SpecialClass]::Glow) {
                    $this.PadPointer()
                    $glow = [GlowingLight]::new($world)
                    $glow.ThinkerState = [LoadGame]::ReadThinkerState($this.Data, $this.Ptr + 8)
                    $glow.Sector = $world.Map.Sectors[[BitConverter]::ToInt32($this.Data, $this.Ptr + 12)]
                    $glow.MinLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 16)
                    $glow.MaxLight = [BitConverter]::ToInt32($this.Data, $this.Ptr + 20)
                    $glow.Direction = [BitConverter]::ToInt32($this.Data, $this.Ptr + 24)
                    $this.Ptr += 28

                    $thinkers.Add($glow)
                    break
                }

                default {
                    throw "Unknown special in savegame!"
                }
            }
        }
    }
    static [ThinkerState] ReadThinkerState([byte[]] $data, [int] $p) {
        switch ([BitConverter]::ToInt32($data, $p)) {
            0 { return [ThinkerState]::InStasis }
            default { return [ThinkerState]::Active }
        }
        return [ThinkerState]::Active 
    }

    static [int] UnArchivePlayer([Player] $player, [byte[]] $data, [int] $p) {
        $player.Clear()

        $player.PlayerState = [PlayerState][BitConverter]::ToInt32($data, $p + 4)
        $player.ViewZ = [Fixed]::new([BitConverter]::ToInt32($data, $p + 16))
        $player.ViewHeight = [Fixed]::new([BitConverter]::ToInt32($data, $p + 20))
        $player.DeltaViewHeight = [Fixed]::new([BitConverter]::ToInt32($data, $p + 24))
        $player.Bob = [Fixed]::new([BitConverter]::ToInt32($data, $p + 28))
        $player.Health = [BitConverter]::ToInt32($data, $p + 32)
        $player.ArmorPoints = [BitConverter]::ToInt32($data, $p + 36)
        $player.ArmorType = [BitConverter]::ToInt32($data, $p + 40)
        
        for ($i = 0; $i -lt [PowerType]::Count; $i++) {
            $player.Powers[$i] = [BitConverter]::ToInt32($data, $p + 44 + 4 * $i)
        }

        for ($i = 0; $i -lt [PowerType]::Count; $i++) {
            $player.Cards[$i] = ([BitConverter]::ToInt32($data, $p + 68 + 4 * $i) -ne 0)
        }

        $player.Backpack = ([BitConverter]::ToInt32($data, $p + 92) -ne 0)

        for ($i = 0; $i -lt [Player]::MaxPlayerCount; $i++) {
            $player.Frags[$i] = [BitConverter]::ToInt32($data, $p + 96 + 4 * $i)
        }

        $player.ReadyWeapon = [WeaponType][BitConverter]::ToInt32($data, $p + 112)
        $player.PendingWeapon = [WeaponType][BitConverter]::ToInt32($data, $p + 116)

        for ($i = 0; $i -lt [WeaponType]::Count; $i++) {
            $player.WeaponOwned[$i] = ([BitConverter]::ToInt32($data, $p + 120 + 4 * $i) -ne 0)
        }

        for ($i = 0; $i -lt [AmmoType]::Count; $i++) {
            $player.Ammo[$i] = [BitConverter]::ToInt32($data, $p + 156 + 4 * $i)
        }

        for ($i = 0; $i -lt [AmmoType]::Count; $i++) {
            $player.MaxAmmo[$i] = [BitConverter]::ToInt32($data, $p + 172 + 4 * $i)
        }

        $player.AttackDown = ([BitConverter]::ToInt32($data, $p + 188) -ne 0)
        $player.UseDown = ([BitConverter]::ToInt32($data, $p + 192) -ne 0)
        $player.Cheats = [CheatFlags][BitConverter]::ToInt32($data, $p + 196)
        $player.Refire = [BitConverter]::ToInt32($data, $p + 200)
        $player.KillCount = [BitConverter]::ToInt32($data, $p + 204)
        $player.ItemCount = [BitConverter]::ToInt32($data, $p + 208)
        $player.SecretCount = [BitConverter]::ToInt32($data, $p + 212)
        $player.DamageCount = [BitConverter]::ToInt32($data, $p + 220)
        $player.BonusCount = [BitConverter]::ToInt32($data, $p + 224)
        $player.ExtraLight = [BitConverter]::ToInt32($data, $p + 232)
        $player.FixedColorMap = [BitConverter]::ToInt32($data, $p + 236)
        $player.ColorMap = [BitConverter]::ToInt32($data, $p + 240)

        for ($i = 0; $i -lt [PlayerSprite]::Count; $i++) {
            $player.PlayerSprites[$i].State = [DoomInfo]::States.all[[BitConverter]::ToInt32($data, $p + 244 + 16 * $i)]
            if ($player.PlayerSprites[$i].State.Number -eq [MobjState]::Null) {
                $player.PlayerSprites[$i].State = $null
            }
            $player.PlayerSprites[$i].Tics = [BitConverter]::ToInt32($data, $p + 244 + 16 * $i + 4)
            $player.PlayerSprites[$i].Sx = [Fixed]::new([BitConverter]::ToInt32($data, $p + 244 + 16 * $i + 8))
            $player.PlayerSprites[$i].Sy = [Fixed]::new([BitConverter]::ToInt32($data, $p + 244 + 16 * $i + 12))
        }

        $player.DidSecret = ([BitConverter]::ToInt32($data, $p + 276) -ne 0)

        return $p + 280
    }

    static [int] UnArchiveSector([Sector] $sector, [byte[]] $data, [int] $p) {
        $sector.FloorHeight = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p))
        $sector.CeilingHeight = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p + 2))
        $sector.FloorFlat = [BitConverter]::ToInt16($data, $p + 4)
        $sector.CeilingFlat = [BitConverter]::ToInt16($data, $p + 6)
        $sector.LightLevel = [BitConverter]::ToInt16($data, $p + 8)
        $sector.Special = [SectorSpecial][BitConverter]::ToInt16($data, $p + 10)
        $sector.Tag = [BitConverter]::ToInt16($data, $p + 12)
        $sector.SpecialData = $null
        $sector.SoundTarget = $null
        return $p + 14
    }

    static [int] UnArchiveLine([LineDef] $line, [byte[]] $data, [int] $p) {
        $line.Flags = [LineFlags][BitConverter]::ToInt16($data, $p)
        $line.Special = [BitConverter]::ToInt16($data, $p + 2)
        $line.Tag = [BitConverter]::ToInt16($data, $p + 4)
        $p += 6

        if ($null -ne $line.FrontSide) {
            $side = $line.FrontSide
            $side.TextureOffset = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p))
            $side.RowOffset = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p + 2))
            $side.TopTexture = [BitConverter]::ToInt16($data, $p + 4)
            $side.BottomTexture = [BitConverter]::ToInt16($data, $p + 6)
            $side.MiddleTexture = [BitConverter]::ToInt16($data, $p + 8)
            $p += 10
        }

        if ($null -ne $line.BackSide) {
            $side = $line.BackSide
            $side.TextureOffset = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p))
            $side.RowOffset = [Fixed]::FromInt([BitConverter]::ToInt16($data, $p + 2))
            $side.TopTexture = [BitConverter]::ToInt16($data, $p + 4)
            $side.BottomTexture = [BitConverter]::ToInt16($data, $p + 6)
            $side.MiddleTexture = [BitConverter]::ToInt16($data, $p + 8)
            $p += 10
        }

        return $p
    }
}
