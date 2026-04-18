##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##

class Mobj : Thinker {
    #
    # NOTES: mobj_t
    #
    # mobj_ts are used to tell the refresh where to draw an image,
    # tell the world simulation when objects are contacted,
    # and tell the sound driver how to position a sound.
    #
    # The refresh uses the next and prev links to follow
    # lists of things in sectors as they are being drawn.
    # The sprite, frame, and angle elements determine which patch_t
    # is used to draw the sprite if it is visible.
    # The sprite and frame values are allmost allways set
    # from state_t structures.
    # The statescr.exe utility generates the states.h and states.c
    # files that contain the sprite/frame numbers from the
    # statescr.txt source file.
    # The xyz origin point represents a point at the bottom middle
    # of the sprite (between the feet of a biped).
    # This is the default origin position for patch_ts grabbed
    # with lumpy.exe.
    # A walking creature will have its z equal to the floor
    # it is standing on.
    #
    # The sound code uses the x,y, and subsector fields
    # to do stereo positioning of any sound effited by the mobj_t.
    #
    # The play simulation uses the blocklinks, x,y,z, radius, height
    # to determine when mobj_ts are touching each other,
    # touching lines in the map, or hit by trace lines (gunshots,
    # lines of sight, etc).
    # The mobj_t->flags element has various bit flags
    # used by the simulation.
    #
    # Every mobj_t is linked into a single sector
    # based on its origin coordinates.
    # The subsector_t is found with R_PointInSubsector(x,y),
    # and the sector_t can be found with subsector->sector.
    # The sector links are only used by the rendering code,
    # the play simulation does not care about them at all.
    #
    # Any mobj_t that needs to be acted upon by something else
    # in the play world (block movement, be shot, etc) will also
    # need to be linked into the blockmap.
    # If the thing has the MF_NOBLOCK flag set, it will not use
    # the block links. It can still interact with other things,
    # but only as the instigator (missiles will run into other
    # things, but nothing can run into a missile).
    # Each block in the grid is 128*128 units, and knows about
    # every line_t that it contains a piece of, and every
    # interactable mobj_t that has its origin contained.  
    #
    # A valid mobj_t is a mobj_t that has the proper subsector_t
    # filled in for its xy coordinates and is linked into the
    # sector from which the subsector was made, or has the
    # MF_NOSECTOR flag set (the subsector_t needs to be valid
    # even if MF_NOSECTOR is set), and is linked into a blockmap
    # block or has the MF_NOBLOCKMAP flag set.
    # Links should only be modified by the P_[Un]SetThingPosition()
    # functions.
    # Do not change the MF_NO? flags while a thing is valid.
    #
    # Any questions?
    #


    static [Fixed] $OnFloorZ = [Fixed]::MinValue
    static [Fixed] $OnCeilingZ = [Fixed]::MaxValue

    [World] $world
    # Info for drawing: position.
    [Fixed] $x
    [Fixed] $y
    [Fixed] $z
    # More list: links in sector (if needed).
    [Mobj] $sectorNext
    [Mobj] $sectorPrev
    #More drawing info: to determine current sprite.
    [Angle] $angle
    [Sprite] $sprite
    [int] $frame

    [Mobj] $blockNext
    [Mobj] $blockPrev

    [Subsector] $subsector

    [Fixed] $floorZ
    [Fixed] $ceilingZ

    [Fixed] $radius
    [Fixed] $height

    [Fixed] $momX
    [Fixed] $momY
    [Fixed] $momZ

    [int] $validCount

    [MobjType] $type
    [MobjInfo] $info

    [int] $tics
    [MobjStateDef] $state
    [MobjFlags] $flags
    [int] $health

    [Direction] $moveDir
    [int] $moveCount

    [Mobj] $target

    [int] $reactionTime
    [int] $threshold

    [Player] $player
    [int] $lastLook

    [MapThing] $spawnPoint
    [Mobj] $tracer

    [bool] $interpolate
    [Fixed] $oldX
    [Fixed] $oldY
    [Fixed] $oldZ

    Mobj([World] $world) {
        $this.world = $world
    }

    [void] Run() {
        if ($this.momX -ne [Fixed]::Zero -or $this.momY -ne [Fixed]::Zero -or 
            ($this.flags -band [MobjFlags]::SkullFly) -ne 0) {
            $this.world.ThingMovement.XYMovement($this)

            if ($this.ThinkerState -eq [ThinkerState]::Removed) {
                return
            }
        }

        if (($this.z -ne $this.floorZ) -or $this.momZ -ne [Fixed]::Zero) {
            $this.world.ThingMovement.ZMovement($this)

            if ($this.ThinkerState -eq [ThinkerState]::Removed) {
                return
            }
        }

        if ($this.tics -ne -1) {
            $this.tics--

            if ($this.tics -eq 0) {
                if (-not $this.SetState($this.state.Next)) {
                    return
                }
            }
        } else {
            if (($this.flags -band [MobjFlags]::CountKill) -eq 0) {
                return
            }

            $options = $this.world.Options
            if (-not ($options.Skill -eq [GameSkill]::Nightmare -or $options.RespawnMonsters)) {
                return
            }

            $this.moveCount++

            if ($this.moveCount -lt 12 * 35) {
                return
            }

            if (($this.world.LevelTime -band 31) -ne 0) {
                return
            }

            if ($this.world.Random.Next() -gt 4) {
                return
            }

            $this.NightmareRespawn()
        }
    }

    [bool] SetState([MobjState] $inState) {
        do {
            if ($inState -eq [MobjState]::Null) {
                $this.state = [DoomInfo]::States.all[[int][MobjState]::Null]
                $this.world.ThingAllocation.RemoveMobj($this)
                return $false
            }

            $st = [DoomInfo]::States.all[[int]$inState]
            $this.state = $st
            $this.tics = $this.GetTics($st)
            $this.sprite = $st.Sprite
            $this.frame = $st.Frame

            if ($null -ne $st.MobjAction) {
                $st.MobjAction.Invoke($this.world, $this)
            }

            $inState = $st.Next
        } while ($this.tics -eq 0)

        return $true
    }

    [int] GetTics([MobjStateDef] $state) {
        $options = $this.world.Options
        if ($options.FastMonsters -or $options.Skill -eq [GameSkill]::Nightmare) {
            if (([int][MobjState]::SargRun1 -le $state.Number) -and 
                ($state.Number -le [int][MobjState]::SargPain2)) {
                return $state.Tics -shr 1
            } else {
                return $state.Tics
            }
        } else {
            return $state.Tics
        }
    }

    [void] NightmareRespawn() {
        $sp = if ($null -ne $this.spawnPoint) { $this.spawnPoint } else { [MapThing]::Empty }

        if (-not $this.world.ThingMovement.CheckPosition($this, $sp.X, $sp.Y)) {
            return
        }

        $ta = $this.world.ThingAllocation

        $fog1 = $ta.SpawnMobj($this.x, $this.y, $this.subsector.Sector.FloorHeight, [MobjType]::Tfog)
        $this.world.StartSound($fog1, [Sfx]::TELEPT, [SfxType]::Misc)

        $ss = [Geometry]::PointInSubsector($sp.X, $sp.Y, $this.world.Map)
        $fog2 = $ta.SpawnMobj($sp.X, $sp.Y, $ss.Sector.FloorHeight, [MobjType]::Tfog)

        $this.world.StartSound($fog2, [Sfx]::TELEPT, [SfxType]::Misc)
        [fixed]$mZ = if (($this.info.Flags -band [MobjFlags]::SpawnCeiling) -ne 0) { [Mobj]::OnCeilingZ } else { [Mobj]::OnFloorZ }

        $mobj = $ta.SpawnMobj($sp.X, $sp.Y, $mZ, $this.type)
        $mobj.SpawnPoint = $this.spawnPoint
        $mobj.Angle = $sp.Angle

        if (([int]($sp.Flags -band [ThingFlags]::Ambush)) -ne 0) {
            $mobj.Flags = $mobj.Flags -bor [MobjFlags]::Ambush
        }

        $mobj.ReactionTime = 18

        $this.world.ThingAllocation.RemoveMobj($this)
    }

    [void] UpdateFrameInterpolationInfo() {
        $this.interpolate = $true
        $this.oldX = $this.x
        $this.oldY = $this.y
        $this.oldZ = $this.z
    }

    [void] DisableFrameInterpolationForOneFrame() {
        $this.interpolate = $false
    }

    [Fixed] GetInterpolatedX([Fixed] $frameFrac) {
        if ($this.interpolate) {
            return $this.oldX + $frameFrac * ($this.x - $this.oldX)
        } else {
            return $this.x
        }
    }

    [Fixed] GetInterpolatedY([Fixed] $frameFrac) {
        if ($this.interpolate) {
            return $this.oldY + $frameFrac * ($this.y - $this.oldY)
        } else {
            return $this.y
        }
    }

    [Fixed] GetInterpolatedZ([Fixed] $frameFrac) {
        if ($this.interpolate) {
            return $this.oldZ + $frameFrac * ($this.z - $this.oldZ)
        } else {
            return $this.z
        }
    }

    
}
