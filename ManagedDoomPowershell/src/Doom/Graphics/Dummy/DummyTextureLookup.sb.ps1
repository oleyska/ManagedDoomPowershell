#needs [ITextureLookup]

class DummyTextureLookup : ITextureLookup {
    # Fields for textures and lookups
    [System.Collections.Generic.List[Texture]]$textureList
    [System.Collections.Generic.Dictionary[string, Texture]]$nameToTexture
    [System.Collections.Generic.Dictionary[string, int]]$nameToNumber
    [int[]]$switchList

    # Constructor
    DummyTextureLookup([Wad]$wad) {
        $this.InitLookup($wad)
        $this.InitSwitchList()
    }

    # Initialize textures and lookups
    [void] InitLookup([Wad]$wad) {
        $this.textureList = New-Object 'System.Collections.Generic.List[Texture]'
        $this.nameToTexture = New-Object 'System.Collections.Generic.Dictionary[string, Texture]'
        $this.nameToNumber = New-Object 'System.Collections.Generic.Dictionary[string, int]'

        for ($n = 1; $n -le 2; $n++) {
            $lumpNumber = $wad.GetLumpNumber("TEXTURE" + $n)
            if ($lumpNumber -eq -1) {
                break
            }

            $data = $wad.ReadLump($lumpNumber)
            $count = [BitConverter]::ToInt32($data, 0)
            for ($i = 0; $i -lt $count; $i++) {
                $offset = [BitConverter]::ToInt32($data, 4 + 4 * $i)
                $name = [Texture]::GetName($data, $offset)
                $height = [Texture]::GetHeight($data, $offset)
                $texture = [DummyData]::GetTexture($height)

                $this.nameToNumber[$name] = $this.textureList.Count
                $this.textureList.Add($texture)
                $this.nameToTexture[$name] = $texture
            }
        }
    }

    # Initialize switch list
    [void] InitSwitchList() {
        $list = New-Object 'System.Collections.Generic.List[int]'
        $switchNameTuplesEnumerable = [DoomInfo]::SwitchNames
        if ($null -ne $switchNameTuplesEnumerable) {
            $switchNameTuplesEnumerator = $switchNameTuplesEnumerable.GetEnumerator()
            for (; $switchNameTuplesEnumerator.MoveNext(); ) {
                $tuple = $switchNameTuplesEnumerator.Current
                $texNum1 = $this.GetNumber($tuple.Item1)
                $texNum2 = $this.GetNumber($tuple.Item2)
                if ($texNum1 -ne -1 -and $texNum2 -ne -1) {
                    $list.Add($texNum1)
                    $list.Add($texNum2)
                }

            }
        }
        $this.switchList = $list.ToArray()
    }

    # Get texture number by name
    [int] GetNumber([string]$name) {
        if ($name[0] -eq '-') {
            return 0
        }

        if ($this.nameToNumber.ContainsKey($name)) {
            return $this.nameToNumber[$name]
        } else {
            return -1
        }
    }

    # Get enumerator for textures
    [System.Collections.Generic.IEnumerator[Texture]] GetEnumerator() {
        return $this.textureList.GetEnumerator()
    }

    # Get enumerator for IEnumerable interface
    [System.Collections.IEnumerator] IEnumerable_GetEnumerator() {
        return $this.textureList.GetEnumerator()
    }

}