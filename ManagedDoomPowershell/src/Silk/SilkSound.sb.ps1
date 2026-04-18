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

Add-Type -Path (Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "System.Numerics.Vectors.dll")

class SilkSound : ISound{
    static [int] $channelCount = 8

    static [float] $fastDecay = [Math]::Pow(0.5, 1.0 / (35 / 5))
    static [float] $slowDecay = [Math]::Pow(0.5, 1.0 / 35)

    static [float] $clipDist = 1200
    static [float] $closeDist = 160
    static [float] $attenuator = 1040

    hidden [int] $soundVolumeLimit = 15

    [Config] $config
    [DrippyAL.AudioClip[]] $buffers
    [float[]] $amplitudes

    [DoomRandom] $random
    [DrippyAL.AudioChannel[]] $channels
    [ChannelInfo[]] $infos

    [DrippyAL.AudioChannel] $uiChannel
    [Sfx] $uiReserved

    [Mobj] $listener

    [float] $masterVolumeDecay
    [DateTime] $lastUpdate
    [int] $debugWorldSoundCount
    [int] $debugWorldPlayCount
    [int] $debugInterestingSoundCount

    SilkSound([config] $config, [GameContent] $content, [DrippyAL.AudioDevice] $device) {
        try {
            [Console]::Write("Initialize sound: ")

            $this.config = $config

            $config.audio_soundvolume = [Math]::Clamp([int]$config.audio_soundvolume, 0, $this.soundVolumeLimit)

            $this.buffers = New-Object 'DrippyAL.AudioClip[]' ([DoomInfo]::SfxNames.Names.Length)
            $this.amplitudes = New-Object float[] ([DoomInfo]::SfxNames.Names.Length)

            if ($config.audio_randompitch) {
                $this.random = New-Object DoomRandom
            }

            for ($i = 0; $i -lt [DoomInfo]::SfxNames.Names.Length; $i++) {
                $name = "DS" + ([DoomInfo]::SfxNames.Names[$i].ToString().ToUpper())
                $lump = $content.Wad.GetLumpNumber($name)
                if ($lump -eq -1) { continue }

                [int] $sampleRate = 0
                [int] $sampleCount = 0
                $samples = [SilkSound]::GetSamples($content.Wad, $name, [ref]$sampleRate, [ref]$sampleCount)

                if (-not $samples.IsEmpty) {
                    $this.buffers[$i] = [DrippyAlBridge]::CreateAudioClip($device, $sampleRate, 1, $samples)
                    $this.amplitudes[$i] = [SilkSound]::GetAmplitude($samples, $sampleRate, $sampleCount)
                }
            }
            $this.channels = [DrippyAL.AudioChannel[]]::new([SilkSound]::channelCount)

            $this.infos = [ChannelInfo[]]::new([SilkSound]::channelCount)

            for ($i = 0; $i -lt $this.channels.Length; $i++) {
                $this.channels[$i] = [DrippyAL.AudioChannel]::new($device)
                $this.infos[$i] = [ChannelInfo]::new()
            }

            $this.uiChannel = [DrippyAL.AudioChannel]::new($device)
            $this.uiReserved = [Sfx]::NONE

            $this.masterVolumeDecay = [float]$config.audio_soundvolume / [float]$this.soundVolumeLimit
            $this.lastUpdate = [DateTime]::MinValue
            $this.debugWorldSoundCount = 0
            $this.debugWorldPlayCount = 0

            [Console]::WriteLine("OK")
        }
        catch {
            [Console]::WriteLine("Failed")
            $this.Dispose()
            throw $_.Exception
        }
    }

    [int] GetSoundVolume() {
        return [int]$this.config.audio_soundvolume
    }

    [void] SetSoundVolume([int] $value) {
        $clamped = [Math]::Clamp($value, 0, $this.soundVolumeLimit)
        $this.config.audio_soundvolume = $clamped
        $this.masterVolumeDecay = [float]$clamped / [float]$this.soundVolumeLimit
    }

    [int] GetSoundMaxVolume() {
        return $this.soundVolumeLimit
    }

    [void] Dispose() {
        [Console]::WriteLine("Shutdown sound.")
    
        if ($null -ne $this.channels) {
            for ($i = 0; $i -lt $this.channels.Length; $i++) {
                if ($null -ne $this.channels[$i]) {
                    $this.channels[$i].Stop()
                    $this.channels[$i].Dispose()
                    $this.channels[$i] = $null
                }
            }
            $this.channels = $null
        }
    
        if ($null -ne $this.buffers) {
            for ($i = 0; $i -lt $this.buffers.Length; $i++) {
                if ($null -ne $this.buffers[$i]) {
                    $this.buffers[$i].Dispose()
                    $this.buffers[$i] = $null
                }
            }
            $this.buffers = $null
        }
    
        if ($null -ne $this.uiChannel) {
            $this.uiChannel.Dispose()
            $this.uiChannel = $null
        }
    }
    
        # Reads sound data from a WAD lump and extracts sample information.
        static [byte[]] GetSamples([Wad] $wad, [string] $name, [ref] $sampleRate, [ref] $sampleCount) {
            $data = $wad.ReadLump($name)
    
            if ($data.Length -lt 8) {
                $sampleRate.Value = -1
                $sampleCount.Value = -1
                return $null
            }
    
            $sampleRate.Value = [BitConverter]::ToUInt16($data, 2)
            $sampleCount.Value = [BitConverter]::ToInt32($data, 4)
    
            $offset = 8
            if ([SilkSound]::ContainsDmxPadding($data)) {
                $offset += 16
                $sampleCount.Value -= 32
            }
    
            if ($sampleCount.Value -gt 0) {
                return $data[$offset..($offset + $sampleCount.Value - 1)]
            }
            else {
                return @()
            }
        }
    
        # Check if the data contains pad bytes.
        # If the first and last 16 samples are the same, the data should contain pad bytes.
        # https://doomwiki.org/wiki/Sound
        static [bool] ContainsDmxPadding([byte[]] $data) {
            $sampleCount = [BitConverter]::ToInt32($data, 4)
            if ($sampleCount -lt 32) {
                return $false
            }
    
            $first = $data[8]
            for ($i = 1; $i -lt 16; $i++) {
                if ($data[8 + $i] -ne $first) {
                    return $false
                }
            }
    
            $last = $data[8 + $sampleCount - 1]
            for ($i = 1; $i -lt 16; $i++) {
                if ($data[8 + $sampleCount - $i - 1] -ne $last) {
                    return $false
                }
            }
    
            return $true
        }
            # Calculates the amplitude of a given audio sample set.
    static [float] GetAmplitude([byte[]] $samples, [int] $sampleRate, [int] $sampleCount) {
        $max = 0
        if ($sampleCount -gt 0) {
            $count = [Math]::Min($sampleRate / 5, $sampleCount)
            for ($t = 0; $t -lt $count; $t++) {
                $a = $samples[$t] - 128
                if ($a -lt 0) { $a = -$a }
                if ($a -gt $max) { $max = $a }
            }
        }
        return [float]$max / 128
    }

    # Sets the listener object for positional audio.
    [void] SetListener([Mobj] $listener) {
        $this.listener = $listener
    }

    # Updates the state of the audio system.
    [void] Update() {
        $now = [DateTime]::Now
        $doParamUpdate = ($now - $this.lastUpdate).TotalSeconds -ge 0.01

        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $info = $this.infos[$i]
            $channel = $this.channels[$i]

            if ($info.Playing -ne [Sfx]::NONE) {
                if ($channel.State -ne [DrippyAL.PlaybackState]::Stopped) {
                    if ($doParamUpdate) {
                        if ($info.Type -eq [SfxType]::Diffuse) {
                            $info.Priority *= [SilkSound]::slowDecay
                        }
                        else {
                            $info.Priority *= [SilkSound]::fastDecay
                        }
                        $this.SetParam($channel, $info)
                    }
                }
                else {
                    $info.Playing = [Sfx]::NONE
                    if ($info.Reserved -eq [Sfx]::NONE) {
                        $info.Source = $null
                    }
                }
            }

            if ($info.Reserved -ne [Sfx]::NONE) {
                if ($info.Playing -ne [Sfx]::NONE) {
                    $channel.Stop()
                }

                $channel.AudioClip = $this.buffers[[int]$info.Reserved]
                $this.SetParam($channel, $info)
                $channel.Pitch = $this.GetPitch($info.Type, $info.Reserved)
                $channel.Play()
                $info.Playing = $info.Reserved
                $info.Reserved = [Sfx]::NONE
            }
        }

        if ($this.uiReserved -ne [Sfx]::NONE) {
            if ($this.uiChannel.State -eq [DrippyAL.PlaybackState]::Playing) {
                $this.uiChannel.Stop()
            }
            $this.uiChannel.Position = [System.Numerics.Vector3]::new(0, 0, -1)
            $this.uiChannel.Volume = $this.masterVolumeDecay
            $this.uiChannel.AudioClip = $this.buffers[[int]$this.uiReserved]
            $this.uiChannel.Play()
            $this.uiReserved = [Sfx]::NONE
        }

        if ($doParamUpdate) {
            $this.lastUpdate = $now
        }
    }
    [void] StartSound([Sfx] $sfx) {
        if ($null -eq $this.buffers[[int]$sfx]) {
            return
        }

        $this.uiReserved = $sfx
    }

    [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type) {
        $this.StartSound($mobj, $sfx, $type, 100)
    }

    [void] StartSound([Mobj] $mobj, [Sfx] $sfx, [SfxType] $type, [int] $volume) {
        $hasClip = $null -ne $this.buffers[[int]$sfx]

        if (-not $hasClip) {
            return
        }

        if ($null -eq $this.listener) {
            return
        }

        $x = ($mobj.X - $this.listener.X).ToFloat()
        $y = ($mobj.Y - $this.listener.Y).ToFloat()
        $dist = [MathF]::Sqrt($x * $x + $y * $y)

        
        if ($type -eq [SfxType]::Diffuse) {
            [float]$priority = $volume
        }
        else {
            [float]$priority = $this.amplitudes[[int]$sfx] * $this.GetDistanceDecay($dist) * $volume
        }

        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $info = $this.infos[$i]
            if ($info.Source -eq $mobj -and $info.Type -eq $type) {
                $info.Reserved = $sfx
                $info.Priority = $priority
                $info.Volume = $volume
                return
            }
        }

        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $info = $this.infos[$i]
            if ($info.Reserved -eq [Sfx]::NONE -and $info.Playing -eq [Sfx]::NONE) {
                $info.Reserved = $sfx
                $info.Priority = $priority
                $info.Source = $mobj
                $info.Type = $type
                $info.Volume = $volume
                return
            }
        }

        [float] $minPriority = [float]::MaxValue
        [int] $minChannel = -1
        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $info = $this.infos[$i]
            if ($info.Priority -lt $minPriority) {
                $minPriority = $info.Priority
                $minChannel = $i
            }
        }

        if ($priority -ge $minPriority) {
            $info = $this.infos[$minChannel]
            $info.Reserved = $sfx
            $info.Priority = $priority
            $info.Source = $mobj
            $info.Type = $type
            $info.Volume = $volume
        }
    }
    [void] StopSound([Mobj] $mobj) {
        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $info = $this.infos[$i]
            if ($info.Source -eq $mobj) {
                $info.LastX = $info.Source.X
                $info.LastY = $info.Source.Y
                $info.Source = $null
                $info.Volume /= 5
            }
        }
    }

    [void] Reset() {
        if ($null -ne $this.random) {
            $this.random.Clear()
        }

        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $this.channels[$i].Stop()
            $this.infos[$i].Clear()
        }

        $this.listener = $null
        $this.debugWorldSoundCount = 0
        $this.debugWorldPlayCount = 0
    }

    [void] Pause() {
        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $channel = $this.channels[$i]

            if ($channel.State -eq [DrippyAL.PlaybackState]::Playing -and 
                ($channel.AudioClip.Duration - $channel.PlayingOffset) -gt [TimeSpan]::FromMilliseconds(200)) {
                $this.channels[$i].Pause()
            }
        }
    }

    [void] Resume() {
        for ($i = 0; $i -lt $this.infos.Length; $i++) {
            $channel = $this.channels[$i]

            if ($channel.State -eq [DrippyAL.PlaybackState]::Paused) {
                $channel.Play()
            }
        }
    }

    [void] SetParam([DrippyAL.AudioChannel] $sound, [ChannelInfo] $info) {
        if ($info.Type -eq [SfxType]::Diffuse) {
            $sound.Position = [System.Numerics.Vector3]::New(0, 0, -1)
            $sound.Volume = 0.01 * $this.masterVolumeDecay * $info.Volume
        }
        else {
            [Fixed] $sourceX = [Fixed]::Zero
            [Fixed] $sourceY = [Fixed]::Zero
            if ($null -eq $info.Source) {
                $sourceX = $info.LastX
                $sourceY = $info.LastY
            }
            else {
                $sourceX = $info.Source.X
                $sourceY = $info.Source.Y
            }

            $x = ($sourceX - $this.listener.X).ToFloat()
            $y = ($sourceY - $this.listener.Y).ToFloat()

            if ([Math]::Abs($x) -lt 16 -and [Math]::Abs($y) -lt 16) {
                $sound.Position = [System.Numerics.Vector3]::New(0, 0, -1)
                $sound.Volume = 0.01 * $this.masterVolumeDecay * $info.Volume
            }
            else {
                $dist = [MathF]::Sqrt($x * $x + $y * $y)
                $angle = [MathF]::Atan2($y, $x) - [float]$this.listener.Angle.ToRadian()
                $sound.Position = [System.Numerics.Vector3]::New(-[MathF]::Sin($angle), 0, -[MathF]::Cos($angle))
                $sound.Volume = 0.01 * $this.masterVolumeDecay * $this.GetDistanceDecay($dist) * $info.Volume
            }
        }
    }

    [float] GetDistanceDecay([float] $dist) {
        if ($dist -lt [SilkSound]::closeDist) {
            return 1.0
        }
        else {
            return [Math]::Max(([SilkSound]::clipDist - $dist) / [SilkSound]::attenuator, 0.0)
        }
    }

    [float] GetPitch([SfxType] $type, [Sfx] $sfx) {
        if ($null -ne $this.random) {
            if ($sfx -eq [Sfx]::ITEMUP -or $sfx -eq [Sfx]::TINK -or $sfx -eq [Sfx]::RADIO) {
                return 1.0
            }
            elseif ($type -eq [SfxType]::Voice) {
                return 1.0 + 0.075 * ($this.random.Next() - 128) / 128
            }
            else {
                return 1.0 + 0.025 * ($this.random.Next() - 128) / 128
            }
        }
        else {
            return 1.0
        }
    }
}
class ChannelInfo {
    [Sfx] $Reserved
    [Sfx] $Playing
    [float] $Priority

    [Mobj] $Source
    [SfxType] $Type
    [int] $Volume
    [Fixed] $LastX
    [Fixed] $LastY

    ChannelInfo() {
        $this.Clear()
    }

    [void] Clear() {
        $this.Reserved = [Sfx]::NONE
        $this.Playing = [Sfx]::NONE
        $this.Priority = 0.0
        $this.Source = $null
        $this.Type = 0
        $this.Volume = 0
        $this.LastX = [Fixed]::Zero
        $this.LastY = [Fixed]::Zero
    }
}
