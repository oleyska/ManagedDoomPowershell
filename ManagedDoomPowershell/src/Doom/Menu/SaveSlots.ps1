class SaveSlots {
    [int]$slotCount = 6
    [int]$descriptionSize = 24


    [string[]]$slots


    [void] ReadSlots() {
        $this.slots = New-Object string[] $this.slotCount
        $directory = [ConfigUtilities]::GetExeDirectory()
        $buffer = New-Object byte[] $this.descriptionSize

        for ($i = 0; $i -lt $this.slots.Length; $i++) {
            $path = [System.IO.Path]::Combine($directory, "doomsav$i.dsg")
            if (Test-Path $path) {
                $reader = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $reader.Read($buffer, 0, $buffer.Length)
                $this.slots[$i] = [DoomInterop]::ToString($buffer, 0, $buffer.Length)
                $reader.Close()
            }
        }
    }

    [string] Get_Item([int]$number) {
        if ($null -eq $this.slots) {
            $this.ReadSlots()
        }
        return $this.slots[$number]
    }

    [void] Set_Item([int]$number, [string]$value) {
        if ($null -eq $this.slots) {
            $this.ReadSlots()
        }
        $this.slots[$number] = $value
    }

    [int] Count() {
         return $this.slots.Length 
    }
}
