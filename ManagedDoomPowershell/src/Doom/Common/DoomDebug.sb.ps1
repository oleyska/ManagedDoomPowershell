class DoomDebug {
    static [int] CombineHash([int] $a, [int] $b) {
        [uint32]$ua = [BitConverter]::ToUInt32([BitConverter]::GetBytes($a), 0)
        [uint32]$ub = [BitConverter]::ToUInt32([BitConverter]::GetBytes($b), 0)
        [uint64]$mixed = ((3 * [uint64]$ua) -bxor [uint64]$ub)
        [uint32]$wrapped = [uint32]($mixed % 4294967296)
        return [BitConverter]::ToInt32([BitConverter]::GetBytes($wrapped), 0)
    }

    static [int] UInt32BitsToInt32([uint32] $value) {
        return [BitConverter]::ToInt32([BitConverter]::GetBytes($value), 0)
    }

    static [int] GetMobjHash([Mobj] $mobj) {
        $hash = 0

        $hash = [DoomDebug]::CombineHash($hash, $mobj.X.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Y.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Z.Data)

        $hash = [DoomDebug]::CombineHash($hash, [DoomDebug]::UInt32BitsToInt32($mobj.Angle.Data))
        $hash = [DoomDebug]::CombineHash($hash, [int]$mobj.Sprite)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Frame)

        $hash = [DoomDebug]::CombineHash($hash, $mobj.FloorZ.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.CeilingZ.Data)

        $hash = [DoomDebug]::CombineHash($hash, $mobj.Radius.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Height.Data)

        $hash = [DoomDebug]::CombineHash($hash, $mobj.MomX.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.MomY.Data)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.MomZ.Data)

        $hash = [DoomDebug]::CombineHash($hash, $mobj.Tics)
        $hash = [DoomDebug]::CombineHash($hash, [int]$mobj.Flags)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Health)

        $hash = [DoomDebug]::CombineHash($hash, [int]$mobj.MoveDir)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.MoveCount)

        $hash = [DoomDebug]::CombineHash($hash, $mobj.ReactionTime)
        $hash = [DoomDebug]::CombineHash($hash, $mobj.Threshold)

        return $hash
    }

    static [int] GetMobjHash([World] $world) {
        $hash = 0
        $current = $world.Thinkers.Cap.Next
        while ($current -ne $world.Thinkers.Cap) {
            if ($current -is [Mobj]) {
                $hash = [DoomDebug]::CombineHash($hash, [DoomDebug]::GetMobjHash($current))
            }
            $current = $current.Next
        }
        return $hash
    }

    static [string] GetMobjCsv([Mobj] $mobj) {
        return "$($mobj.X.Data),$($mobj.Y.Data),$($mobj.Z.Data)," +
               "$([uint32]$mobj.Angle.Data),$([int]$mobj.Sprite),$($mobj.Frame)," +
               "$($mobj.FloorZ.Data),$($mobj.CeilingZ.Data)," +
               "$($mobj.Radius.Data),$($mobj.Height.Data)," +
               "$($mobj.MomX.Data),$($mobj.MomY.Data),$($mobj.MomZ.Data)," +
               "$([int]$mobj.Tics),$([int]$mobj.Flags),$($mobj.Health)," +
               "$([int]$mobj.MoveDir),$($mobj.MoveCount)," +
               "$($mobj.ReactionTime),$($mobj.Threshold)"
    }

    static [void] DumpMobjCsv([string] $path, [World] $world) {
        $lines = @()
        $current = $world.Thinkers.Cap.Next
        while ($current -ne $world.Thinkers.Cap) {
            if ($current -is [Mobj]) {
                $lines += [DoomDebug]::GetMobjCsv($current)
            }
            $current = $current.Next
        }
        $lines | Out-File -Encoding utf8 -FilePath $path
    }

    static [int] GetSectorHash([Sector] $sector) {
        $hash = 0

        $hash = [DoomDebug]::CombineHash($hash, $sector.FloorHeight.Data)
        $hash = [DoomDebug]::CombineHash($hash, $sector.CeilingHeight.Data)
        $hash = [DoomDebug]::CombineHash($hash, $sector.LightLevel)

        return $hash
    }

    static [int] GetSectorHash([World] $world) {
        $hash = 0
        foreach ($sector in $world.Map.Sectors) {
            $hash = [DoomDebug]::CombineHash($hash, [DoomDebug]::GetSectorHash($sector))
        }
        return $hash
    }
}
