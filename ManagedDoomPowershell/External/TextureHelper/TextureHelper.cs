using System;
using System.Runtime.InteropServices;
using TrippyGL;
using Silk.NET.OpenGL;

public static class TextureHelper
{
    public static void SetTextureData(Texture2D texture, byte[] data, int x, int y, uint width, uint height, PixelFormat format)
    {
        if (texture == null)
            throw new ArgumentNullException(nameof(texture));
        if (data == null)
            throw new ArgumentNullException(nameof(data));

        GCHandle handle = GCHandle.Alloc(data, GCHandleType.Pinned);
        try
        {
            IntPtr ptr = Marshal.UnsafeAddrOfPinnedArrayElement(data, 0);

            unsafe
            {
                ReadOnlySpan<byte> span = new ReadOnlySpan<byte>(ptr.ToPointer(), data.Length);
                texture.SetData(span, x, y, width, height, format);
            }
        }
        finally
        {
            handle.Free();
        }
    }
}