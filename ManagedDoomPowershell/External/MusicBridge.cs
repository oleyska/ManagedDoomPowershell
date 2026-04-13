using System;
using System.IO;
using DrippyAL;
using MeltySynth;

public sealed class DoomMusicBridge : IDisposable
{
    private const int SampleRate = 44100;
    private const int SynthBlockLength = SampleRate / 140;

    private readonly object _gate = new object();
    private readonly int _maxVolume;
    private readonly AudioStream _audioStream;
    private readonly Synthesizer _synthesizer;
    private readonly float[] _left;
    private readonly float[] _right;
    private readonly Action<short[]> _fillCallback;

    private int _volume;
    private IDecoder _current;
    private IDecoder _reserved;

    public DoomMusicBridge(AudioDevice device, string soundFontPath, bool enableEffects, int initialVolume, int maxVolume, int latency = 200, int blockLength = 2048)
    {
        if (device == null) throw new ArgumentNullException(nameof(device));
        if (soundFontPath == null) throw new ArgumentNullException(nameof(soundFontPath));

        _maxVolume = maxVolume;
        _volume = Clamp(initialVolume, 0, maxVolume);

        var settings = new SynthesizerSettings(SampleRate)
        {
            BlockSize = SynthBlockLength,
            EnableReverbAndChorus = enableEffects
        };

        _synthesizer = new Synthesizer(soundFontPath, settings);
        _left = new float[blockLength];
        _right = new float[blockLength];
        _fillCallback = FillBlock;
        _audioStream = new AudioStream(device, SampleRate, 2, true, latency, blockLength);
    }

    public int Volume
    {
        get
        {
            lock (_gate)
            {
                return _volume;
            }
        }
        set
        {
            lock (_gate)
            {
                _volume = Clamp(value, 0, _maxVolume);
            }
        }
    }

    public void Start(byte[] data, bool loop)
    {
        if (data == null) throw new ArgumentNullException(nameof(data));

        lock (_gate)
        {
            _reserved = CreateDecoder(data, loop);

            if (_audioStream.State == PlaybackState.Stopped)
            {
                _audioStream.Play(_fillCallback);
            }
        }
    }

    public void Dispose()
    {
        lock (_gate)
        {
            _audioStream.Stop();
            _audioStream.Dispose();
        }
    }

    private void FillBlock(short[] samples)
    {
        lock (_gate)
        {
            if (_reserved != _current)
            {
                _synthesizer.Reset();
                _current = _reserved;
            }

            if (_current == null)
            {
                Array.Clear(samples, 0, samples.Length);
                return;
            }

            float amplitude = 32768f * (2f * _volume / _maxVolume);
            _current.RenderWaveform(_synthesizer, _left, _right);

            int pos = 0;
            for (int i = 0; i < _left.Length; i++)
            {
                int sampleLeft = Clamp((int)(amplitude * _left[i]), short.MinValue, short.MaxValue);
                int sampleRight = Clamp((int)(amplitude * _right[i]), short.MinValue, short.MaxValue);

                samples[pos++] = (short)sampleLeft;
                samples[pos++] = (short)sampleRight;
            }
        }
    }

    private static IDecoder CreateDecoder(byte[] data, bool loop)
    {
        if (data.Length >= 4 &&
            data[0] == (byte)'M' &&
            data[1] == (byte)'U' &&
            data[2] == (byte)'S' &&
            data[3] == 0x1A)
        {
            return new MusDecoder(data, loop);
        }

        if (data.Length >= 4 &&
            data[0] == (byte)'M' &&
            data[1] == (byte)'T' &&
            data[2] == (byte)'h' &&
            data[3] == (byte)'d')
        {
            return new MidiDecoder(data, loop);
        }

        throw new InvalidOperationException("Unknown music format.");
    }

    private static int Clamp(int value, int min, int max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private interface IDecoder
    {
        void RenderWaveform(Synthesizer synthesizer, float[] left, float[] right);
    }

    private sealed class MidiDecoder : IDecoder
    {
        private readonly MidiFile _midi;
        private readonly bool _loop;
        private MidiFileSequencer _sequencer;

        public MidiDecoder(byte[] data, bool loop)
        {
            _midi = new MidiFile(new MemoryStream(data));
            _loop = loop;
        }

        public void RenderWaveform(Synthesizer synthesizer, float[] left, float[] right)
        {
            if (_sequencer == null)
            {
                _sequencer = new MidiFileSequencer(synthesizer);
                _sequencer.Play(_midi, _loop);
            }

            _sequencer.Render(new Span<float>(left), new Span<float>(right));
        }
    }

    private sealed class MusDecoder : IDecoder
    {
        private readonly byte[] _data;
        private readonly bool _loop;
        private readonly MusEvent[] _events;
        private readonly int[] _lastVolume;
        private readonly int _scoreStart;
        private int _eventCount;
        private int _position;
        private int _delay;
        private int _blockWrote;

        public MusDecoder(byte[] data, bool loop)
        {
            _data = data ?? throw new ArgumentNullException(nameof(data));
            _loop = loop;

            _scoreStart = BitConverter.ToUInt16(data, 6);
            _events = new MusEvent[128];
            for (int i = 0; i < _events.Length; i++)
            {
                _events[i] = new MusEvent();
            }

            _lastVolume = new int[16];
            Reset();
            _blockWrote = SynthBlockLength;
        }

        public void RenderWaveform(Synthesizer synthesizer, float[] left, float[] right)
        {
            int wrote = 0;
            while (wrote < left.Length)
            {
                if (_blockWrote == synthesizer.BlockSize)
                {
                    ProcessMidiEvents(synthesizer);
                    _blockWrote = 0;
                }

                int srcRem = synthesizer.BlockSize - _blockWrote;
                int dstRem = left.Length - wrote;
                int rem = Math.Min(srcRem, dstRem);

                synthesizer.Render(new Span<float>(left, wrote, rem), new Span<float>(right, wrote, rem));

                _blockWrote += rem;
                wrote += rem;
            }
        }

        private void ProcessMidiEvents(Synthesizer synthesizer)
        {
            if (_delay > 0)
            {
                _delay--;
            }

            if (_delay != 0)
            {
                return;
            }

            _delay = ReadSingleEventGroup();
            SendEvents(synthesizer);

            if (_delay == -1)
            {
                synthesizer.NoteOffAll(false);

                if (_loop)
                {
                    Reset();
                }
            }
        }

        private void Reset()
        {
            Array.Clear(_lastVolume, 0, _lastVolume.Length);
            _position = _scoreStart;
            _delay = 0;
        }

        private int ReadSingleEventGroup()
        {
            _eventCount = 0;

            while (true)
            {
                var result = ReadSingleEvent();
                if (result == ReadResult.EndOfGroup)
                {
                    break;
                }

                if (result == ReadResult.EndOfFile)
                {
                    return -1;
                }
            }

            int time = 0;
            while (true)
            {
                byte value = _data[_position++];
                time = time * 128 + (value & 127);
                if ((value & 128) == 0)
                {
                    break;
                }
            }

            return time;
        }

        private ReadResult ReadSingleEvent()
        {
            int channelNumber = _data[_position] & 0xF;
            if (channelNumber == 15)
            {
                channelNumber = 9;
            }
            else if (channelNumber >= 9)
            {
                channelNumber++;
            }

            int eventType = (_data[_position] & 0x70) >> 4;
            bool last = (_data[_position] >> 7) != 0;

            _position++;

            var me = _events[_eventCount++];

            switch (eventType)
            {
                case 0:
                    me.Type = 0;
                    me.Channel = channelNumber;
                    me.Data1 = _data[_position++];
                    me.Data2 = 0;
                    break;

                case 1:
                    me.Type = 1;
                    me.Channel = channelNumber;

                    int playNote = _data[_position++];
                    int noteNumber = playNote & 127;
                    int noteVolume = (playNote & 128) != 0 ? _data[_position++] : -1;

                    me.Data1 = noteNumber;
                    if (noteVolume == -1)
                    {
                        me.Data2 = _lastVolume[channelNumber];
                    }
                    else
                    {
                        me.Data2 = noteVolume;
                        _lastVolume[channelNumber] = noteVolume;
                    }
                    break;

                case 2:
                    me.Type = 2;
                    me.Channel = channelNumber;

                    int pitchWheel = _data[_position++];
                    int pw2 = (pitchWheel << 7) / 2;
                    int pw1 = pw2 & 127;
                    pw2 >>= 7;
                    me.Data1 = pw1;
                    me.Data2 = pw2;
                    break;

                case 3:
                    me.Type = 3;
                    me.Channel = channelNumber;
                    me.Data1 = _data[_position++];
                    me.Data2 = 0;
                    break;

                case 4:
                    me.Type = 4;
                    me.Channel = channelNumber;
                    me.Data1 = _data[_position++];
                    me.Data2 = _data[_position++];
                    break;

                case 6:
                    return ReadResult.EndOfFile;

                default:
                    throw new InvalidOperationException("Unknown MUS event type.");
            }

            return last ? ReadResult.EndOfGroup : ReadResult.Ongoing;
        }

        private void SendEvents(Synthesizer synthesizer)
        {
            for (int i = 0; i < _eventCount; i++)
            {
                var me = _events[i];
                switch (me.Type)
                {
                    case 0:
                        synthesizer.NoteOff(me.Channel, me.Data1);
                        break;

                    case 1:
                        synthesizer.NoteOn(me.Channel, me.Data1, me.Data2);
                        break;

                    case 2:
                        synthesizer.ProcessMidiMessage(me.Channel, 0xE0, me.Data1, me.Data2);
                        break;

                    case 3:
                        switch (me.Data1)
                        {
                            case 11:
                                synthesizer.NoteOffAll(me.Channel, false);
                                break;
                            case 14:
                                synthesizer.ResetAllControllers(me.Channel);
                                break;
                        }
                        break;

                    case 4:
                        switch (me.Data1)
                        {
                            case 0:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xC0, me.Data2, 0);
                                break;
                            case 1:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x00, me.Data2);
                                break;
                            case 2:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x01, me.Data2);
                                break;
                            case 3:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x07, me.Data2);
                                break;
                            case 4:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x0A, me.Data2);
                                break;
                            case 5:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x0B, me.Data2);
                                break;
                            case 6:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x5B, me.Data2);
                                break;
                            case 7:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x5D, me.Data2);
                                break;
                            case 8:
                                synthesizer.ProcessMidiMessage(me.Channel, 0xB0, 0x40, me.Data2);
                                break;
                        }
                        break;
                }
            }
        }
    }

    private enum ReadResult
    {
        Ongoing,
        EndOfGroup,
        EndOfFile
    }

    private sealed class MusEvent
    {
        public int Type;
        public int Channel;
        public int Data1;
        public int Data2;
    }
}

public static class DrippyAlBridge
{
    public static AudioClip CreateAudioClip(AudioDevice device, int sampleRate, int channels, byte[] samples)
    {
        if (device == null) throw new ArgumentNullException(nameof(device));
        if (samples == null) throw new ArgumentNullException(nameof(samples));

        return new AudioClip(device, sampleRate, channels, new Span<byte>(samples));
    }
}
