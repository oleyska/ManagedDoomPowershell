using System;
using System.Runtime.InteropServices;

public static class BufferHelper
{
    public static void WritePixel(byte[] destination, int index, uint value)
    {
        // reinterpret byte[] as uint[]
        var span = MemoryMarshal.Cast<byte, uint>(destination);
        span[index] = value;
    }
    public static void WritePixels(byte[] destination, uint[] colors, byte[] screenData, int width, int height)
    {
        var span = MemoryMarshal.Cast<byte, uint>(destination);

        for (int x = 0; x < width; x++)
        {
            int srcColumnStart = height * x;
            int dstIndex = x;

            for (int y = 0; y < height; y++)
            {
                span[dstIndex] = colors[screenData[srcColumnStart + y]];
                dstIndex += width;
            }
        }
    }
}
