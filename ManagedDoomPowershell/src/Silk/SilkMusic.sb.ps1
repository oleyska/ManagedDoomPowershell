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

class SilkMusic : IMusic {
    [Config] $Config
    [Wad] $Wad
    [object] $Bridge
    [Bgm] $Current
    [int] $maxvolume = 15

    SilkMusic([Config] $config, [GameContent] $content, [DrippyAL.AudioDevice] $device, [string] $sfPath) {
        try {
            [Console]::Write("Initialize music: ")

            $this.Config = $config
            $this.Wad = $content.Wad
            $this.Config.audio_musicvolume = [math]::Clamp($this.Config.audio_musicvolume, 0, $this.MaxVolume)
            $this.Bridge = [DoomMusicBridge]::new($device, $sfPath, [bool]$config.audio_musiceffect, [int]$this.Config.audio_musicvolume, [int]$this.MaxVolume)
            $this.Current = [Bgm]::NONE
            [Console]::WriteLine("OK")
        } catch {
            [Console]::WriteLine("Failed")
            $this.Dispose()
            throw
        }
    }

    [void] StartMusic([Bgm] $bgm, [bool] $loop) {
        if ($bgm -eq $this.Current) {
            return
        }

        $lump = "D_" + ([DoomInfo]::BgmNames[[int]$bgm].ToString().ToUpper())
        $data = $this.Wad.ReadLump($lump)
        $this.Bridge.Start($data, $loop)

        $this.Current = $bgm
    }

    [int] get_Volume() {
        return [int]$this.Bridge.Volume
    }

    [void] set_Volume([int] $value) {
        $clamped = [math]::Clamp($value, 0, $this.MaxVolume)
        $this.Config.audio_musicvolume = $clamped
        $this.Bridge.Volume = $clamped
    }

    [int] get_MaxVolume() {
        return $this.maxvolume
    }

    [void] Dispose() {
        [Console]::WriteLine("Shutdown music.")
        if ($null -ne $this.Bridge) {
            $this.Bridge.Dispose()
            $this.Bridge = $null
        }
    }
}

class IDecoder {
    [void] RenderWaveform([MeltySynth.Synthesizer] $synthesizer, [float[]] $left, [float[]] $right) {
        throw "Method RenderWaveform must be implemented in a subclass."
    }
}
class MusStream {
    static [int] $Latency = 200
    static [int] $BlockLength = 2048

    [SilkMusic] $Parent
    [Config] $Config
    [MeltySynth.Synthesizer] $Synthesizer
    [DrippyAL.AudioStream] $AudioStream
    [float[]] $Left
    [float[]] $Right
    [IDecoder] $Current
    [IDecoder] $Reserved

    MusStream([SilkMusic] $parent, [Config] $config, [DrippyAL.AudioDevice] $device, [string] $sfPath) {
        $this.Parent = $parent
        $this.Config = $config

        $this.Config.audio_musicvolume = [math]::Clamp($this.Config.audio_musicvolume, 0, $parent.MaxVolume)

        $settings = [MeltySynth.SynthesizerSettings]::new([MusDecoder]::SampleRate)
        $settings.BlockSize = [MusDecoder]::BlockLength
        $settings.EnableReverbAndChorus = $config.audio_musiceffect
        $this.Synthesizer = [MeltySynth.Synthesizer]::new($sfPath, $settings)

        $this.Left = [float[]]::new([MusStream]::BlockLength)
        $this.Right = [float[]]::new([MusStream]::BlockLength)

        $this.AudioStream = [DrippyAL.AudioStream]::new($device, [MusDecoder]::SampleRate, 2, $true, [MusStream]::Latency, [MusStream]::BlockLength)
        
    }

    [void] SetDecoder([IDecoder] $decoder) {
        $this.Reserved = $decoder

        if ($this.AudioStream.State -eq [DrippyAL.PlaybackState]::Stopped) {
            $callback = [Action[short[]]] { param($samples) $this.OnGetData($samples) }
            $this.AudioStream.Play($callback)
        }
    }

    [void] OnGetData([short[]] $samples) {
        if ($this.Reserved -ne $this.Current) {
            $this.Synthesizer.Reset()
            $this.Current = $this.Reserved
        }

        $a = 32768 * ([float] 2.0 * $this.Config.audio_musicvolume / $this.Parent.MaxVolume)

        $this.Current.RenderWaveform($this.Synthesizer, $this.Left, $this.Right)

        $pos = 0

        for ($t = 0; $t -lt $this.BlockLength; $t++) {
            $sampleLeft = [math]::Clamp([int]($a * $this.Left[$t]), [int][short]::MinValue, [int][short]::MaxValue)
            $sampleRight = [math]::Clamp([int]($a * $this.Right[$t]), [int][short]::MinValue, [int][short]::MaxValue)
            
            $samples[$pos++] = [short]$sampleLeft
            $samples[$pos++] = [short]$sampleRight
        }
    }

    [void] Dispose() {
        if ($null -ne $this.AudioStream) {
            $this.AudioStream.Stop()
            $this.AudioStream.Dispose()
            $this.AudioStream = $null
        }
    }
}

class MusDecoder : IDecoder{
    # Constants
    static [int] $SampleRate = 44100
    static [int] $BlockLength = [MusDecoder]::SampleRate / 140

    static [byte[]] $MusHeader = @(
        [byte][char]'M',
        [byte][char]'U',
        [byte][char]'S',
        0x1A
    )

    [byte[]] $Data
    [bool] $Loop

    [int] $ScoreLength
    [int] $ScoreStart
    [int] $ChannelCount
    [int] $ChannelCount2
    [int] $InstrumentCount
    [int[]] $Instruments

    [MusEvent[]] $Events
    [int] $EventCount

    [int[]] $LastVolume
    [int] $P
    [int] $Delay
    [int] $BlockWrote

    MusDecoder([byte[]] $data, [bool] $loop) {
        [MusDecoder]::CheckHeader($data)

        $this.Data = $data
        $this.Loop = $loop

        $this.ScoreLength = [BitConverter]::ToUInt16($data, 4)
        $this.ScoreStart = [BitConverter]::ToUInt16($data, 6)
        $this.ChannelCount = [BitConverter]::ToUInt16($data, 8)
        $this.ChannelCount2 = [BitConverter]::ToUInt16($data, 10)
        $this.InstrumentCount = [BitConverter]::ToUInt16($data, 12)

        $this.Instruments = New-Object int[]($this.InstrumentCount)
        for ($i = 0; $i -lt $this.Instruments.Length; $i++) {
            $this.Instruments[$i] = [BitConverter]::ToUInt16($data, 16 + 2 * $i)
        }

        $this.Events = New-Object MusEvent[] 128
        for ($i = 0; $i -lt $this.Events.Length; $i++) {
            $this.Events[$i] = [MusEvent]::new()
        }
        $this.EventCount = 0

        $this.LastVolume = New-Object int[] 16

        $this.Reset()

        $this.BlockWrote = [MusDecoder]::BlockLength
    }

    [void] RenderWaveform([MeltySynth.Synthesizer] $synthesizer, [float[]] $left, [float[]] $right) {
        $wrote = 0
        while ($wrote -lt $left.Length) {
            if ($this.BlockWrote -eq $synthesizer.BlockSize) {
                $this.ProcessMidiEvents($synthesizer)
                $this.BlockWrote = 0
            }

            $srcRem = $synthesizer.BlockSize - $this.BlockWrote
            $dstRem = $left.Length - $wrote
            $rem = [Math]::Min($srcRem, $dstRem)
   
            [SpanHelper]::RenderSynthesizer($synthesizer, $left, $right, $wrote, $rem)
            $this.BlockWrote += $rem #Integer
            $wrote += $rem #Integer
        }
    }

    [void] ProcessMidiEvents([MeltySynth.Synthesizer] $synthesizer) {
        if ($this.Delay -gt 0) {
            $this.Delay--
        }

        if ($this.Delay -eq 0) {
            $this.Delay = $this.ReadSingleEventGroup()
            $this.SendEvents($synthesizer)

            if ($this.Delay -eq -1) {
                $synthesizer.NoteOffAll($false)

                if ($this.Loop) {
                    $this.Reset()
                }
            }
        }
    }
    static [void] CheckHeader([byte[]] $data) {
        for ($mP = 0; $mP -lt [MusDecoder]::MusHeader.Length; $mP++) {
            if ($data[$mP] -ne [MusDecoder]::MusHeader[$mP]) {
                throw [System.Exception]::new("Invalid format!")
            }
        }
    }
    [void] Reset() {
        for ($i = 0; $i -lt $this.LastVolume.Length; $i++) {
            $this.LastVolume[$i] = 0
        }

        $this.P = $this.ScoreStart
        $this.Delay = 0
    }

    [int] ReadSingleEventGroup() {
        $this.EventCount = 0

        while ($true) {
            $result = $this.ReadSingleEvent()
            if ($result -eq [ReadResult]::EndOfGroup) {
                break
            } elseif ($result -eq [ReadResult]::EndOfFile) {
                return -1
            }
        }

        $time = 0
        while ($true) {
            $value = $this.Data[$this.P++]
            $time = $time * 128 + ($value -band 127)
            if (($value -band 128) -eq 0) {
                break
            }
        }

        return $time
    }
    [ReadResult] ReadSingleEvent() {
        $channelNumber = $this.Data[$this.P] -band 0xF

        if ($channelNumber -eq 15) {
            $channelNumber = 9
        } elseif ($channelNumber -ge 9) {
            $channelNumber++
        }

        $eventType = ($this.Data[$this.P] -band 0x70) -shr 4
        $last = ($this.Data[$this.P] -shr 7) -ne 0

        $this.P++

        $me = $this.Events[$this.EventCount]
        $this.EventCount++

        switch ($eventType) {
            0 {  # RELEASE NOTE
                $me.Type = 0
                $me.Channel = $channelNumber

                $releaseNote = $this.Data[$this.P++]
                $me.Data1 = $releaseNote
                $me.Data2 = 0
            }

            1 {  # PLAY NOTE
                $me.Type = 1
                $me.Channel = $channelNumber

                $playNote = $this.Data[$this.P++]
                $noteNumber = $playNote -band 127
                $noteVolume = if (($playNote -band 128) -ne 0) { $this.Data[$this.P++] } else { -1 }

                $me.Data1 = $noteNumber
                if ($noteVolume -eq -1) {
                    $me.Data2 = $this.LastVolume[$channelNumber]
                } else {
                    $me.Data2 = $noteVolume
                    $this.LastVolume[$channelNumber] = $noteVolume
                }
            }

            2 {  # PITCH WHEEL
                $me.Type = 2
                $me.Channel = $channelNumber

                $pitchWheel = $this.Data[$this.P++]
                $pw2 = ($pitchWheel -shl 7) / 2
                $pw1 = $pw2 -band 127
                $pw2 = $pw2 -shr 7
                $me.Data1 = $pw1
                $me.Data2 = $pw2
            }

            3 {  # SYSTEM EVENT
                $me.Type = 3
                $me.Channel = $channelNumber

                $systemEvent = $this.Data[$this.P++]
                $me.Data1 = $systemEvent
                $me.Data2 = 0
            }

            4 {  # CONTROL CHANGE
                $me.Type = 4
                $me.Channel = $channelNumber

                $controllerNumber = $this.Data[$this.P++]
                $controllerValue = $this.Data[$this.P++]

                $me.Data1 = $controllerNumber
                $me.Data2 = $controllerValue
            }

            6 {  # END OF FILE
                return [ReadResult]::EndOfFile
            }

            default {
                throw "Unknown event type!"
            }
        }

        if ($last) {
            return [ReadResult]::EndOfGroup
        } else {
            return [ReadResult]::Ongoing
        }
    }
    [void] SendEvents([MeltySynth.Synthesizer] $synthesizer) {
        for ($i = 0; $i -lt $this.EventCount; $i++) {
            $me = $this.Events[$i]

            switch ($me.Type) {
                0 {  # RELEASE NOTE
                    $synthesizer.NoteOff($me.Channel, $me.Data1)
                }

                1 {  # PLAY NOTE
                    $synthesizer.NoteOn($me.Channel, $me.Data1, $me.Data2)
                }

                2 {  # PITCH WHEEL
                    $synthesizer.ProcessMidiMessage($me.Channel, 0xE0, $me.Data1, $me.Data2)
                }

                3 {  # SYSTEM EVENT
                    switch ($me.Data1) {
                        11 { $synthesizer.NoteOffAll($me.Channel, $false) }   # ALL NOTES OFF
                        14 { $synthesizer.ResetAllControllers($me.Channel) } # RESET ALL CONTROLS
                    }
                }

                4 {  # CONTROL CHANGE
                    switch ($me.Data1) {
                        0  { $synthesizer.ProcessMidiMessage($me.Channel, 0xC0, $me.Data2, 0) }  # PROGRAM CHANGE
                        1  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x00, $me.Data2) }  # BANK SELECTION
                        2  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x01, $me.Data2) }  # MODULATION
                        3  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x07, $me.Data2) }  # VOLUME
                        4  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x0A, $me.Data2) }  # PAN
                        5  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x0B, $me.Data2) }  # EXPRESSION
                        6  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x5B, $me.Data2) }  # REVERB
                        7  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x5D, $me.Data2) }  # CHORUS
                        8  { $synthesizer.ProcessMidiMessage($me.Channel, 0xB0, 0x40, $me.Data2) }  # PEDAL
                    }
                }
            }
        }
    }
}

enum ReadResult
{
    Ongoing
    EndOfGroup
    EndOfFile
}

class MusEvent {
    [int] $Type
    [int] $Channel
    [int] $Data1
    [int] $Data2

    MusEvent() {
        $this.Type = 0
        $this.Channel = 0
        $this.Data1 = 0
        $this.Data2 = 0
    }
}

class MidiDecoder : IDecoder {
    static [byte[]] $MidiHeader = @(
        [byte][char]'M',
        [byte][char]'T',
        [byte][char]'h',
        [byte][char]'d'
    )

    [MeltySynth.MidiFile] $Midi
    [MeltySynth.MidiFileSequencer] $Sequencer
    [bool] $Loop

    MidiDecoder([byte[]] $data, [bool] $loop) {
        $this.Midi = [MeltySynth.MidiFile]::new([System.IO.MemoryStream]::new($data))
        $this.Loop = $loop
    }

    [void] RenderWaveform([MeltySynth.Synthesizer] $synthesizer, [float[]] $left, [float[]] $right) {
        if ($null -eq $this.Sequencer) {
            $this.Sequencer = [MeltySynth.MidiFileSequencer]::new($synthesizer)
            $this.Sequencer.Play($this.Midi, $this.Loop)
        }

        [SpanHelper]::RenderSequencer($this.Sequencer, $left, $right)
    }
}