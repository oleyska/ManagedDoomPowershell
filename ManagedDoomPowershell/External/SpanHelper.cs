using System;
using MeltySynth;

public static class SpanHelper
{
    public static void RenderSynthesizer(Synthesizer synthesizer, float[] left, float[] right, int start, int length)
    {
        if (synthesizer is null || left is null || right is null)
            throw new ArgumentNullException();

        if (start < 0 || length < 0 || start + length > left.Length || start + length > right.Length)
            throw new ArgumentOutOfRangeException();

        synthesizer.Render(new Span<float>(left, start, length), new Span<float>(right, start, length));
    }

    public static void RenderSequencer(MidiFileSequencer sequencer, float[] left, float[] right)
    {
        if (sequencer is null || left is null || right is null)
            throw new ArgumentNullException();

        sequencer.Render(new Span<float>(left), new Span<float>(right));
    }
}
