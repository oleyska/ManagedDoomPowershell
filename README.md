# ManagedDoomPowershell
A port of Managed Doom to Powershell, hence the name "Managed Doom Powershell" to highlight it comes from Managed Doom.
I stand on their shoulders.

All the code will be uploaded when I feel it's ready.

* Audio, Music, Render, Menu works at this point just slow.


Performance is poor as expected, below is a screenshot from Windows 11 running without Realtime Protection.
Linux is considerably faster but still slow, this is due to Anti Malware Scan Interface on Windows powershell build (AMSI)

![Teaser-Poor performance](Screenshots/1.png)

## License

Managed Doom Powershell is distributed under the [GPLv2 license](licenses/LICENSE_ManagedDoomPwsh.txt).  
Managed Doom Powershell uses the following libraries:

* [Silk.NET](https://github.com/dotnet/Silk.NET) by the the Silk.NET team ([MIT License](licenses/LICENSE_SilkNET.txt))
* [TrippyGL](https://github.com/SilkCommunity/TrippyGL) by Thomas Mizrahi ([MIT License](licenses/LICENSE_TrippyGL.txt))
* [TimGM6mb](https://musescore.org/en/handbook/soundfonts-and-sfz-files#gm_soundfonts) by Tim Brechbill ([GPLv2 license](licenses/LICENSE_TimGM6mb.txt))
* [DrippyAL](https://github.com/sinshu/DrippyAL) ([MIT License](licenses/LICENSE_DrippyAL.txt))
* [MeltySynth](https://github.com/sinshu/meltysynth/) ([MIT license](licenses/LICENSE_MeltySynth.txt))

Silk.NET uses the following native libraries:

* [GLFW](https://www.glfw.org/) ([zlib/libpng license](licenses/LICENSE_GLFW.txt))
* [OpenAL Soft](https://openal-soft.org/) ([LGPL license](licenses/LICENSE_OpenALSoft.txt))

## References


* [Managed-Doom](https://github.com/sinshu/managed-doom)
