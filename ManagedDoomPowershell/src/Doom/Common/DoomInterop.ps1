class DoomInterop {
    static [string] ToString([byte[]] $data, [int] $offset, [int] $maxLength) {
        $length = 0
        for ($i = 0; $i -lt $maxLength; $i++) {
            if ($data[$offset + $i] -eq 0) {
                break
            }
            $length++
        }

        $chars = New-Object char[] $length
        for ($i = 0; $i -lt $length; $i++) {
            $c = $data[$offset + $i]
            if ($c -ge 97 -and $c -le 122) { # 'a' <= c <= 'z'
                $c -= 0x20
            }
            $chars[$i] = [char]$c
        }

        return -join $chars
    }
}