# This requires a special dance.
# is it a powershell bug or not ? it's related to the dynamic .net compiler from some minor debugging and no idea how to resolve it without add-type with C# code.
# Powershell unless explicitly required it is, so this dance is what you get.

class MobjInfo {
    [int] $DoomEdNum
    [MobjState] $SpawnState
    [int] $SpawnHealth
    [MobjState] $SeeState
    [Sfx] $SeeSound
    [int] $ReactionTime
    [Sfx] $AttackSound
    [MobjState] $PainState
    [int] $PainChance
    [Sfx] $PainSound
    [MobjState] $MeleeState
    [MobjState] $MissileState
    [MobjState] $DeathState
    [MobjState] $XdeathState
    [Sfx] $DeathSound
    [int] $Speed
    [Fixed] $Radius
    [Fixed] $Height
    [int] $Mass
    [int] $Damage
    [Sfx] $ActiveSound
    [MobjFlags] $Flags
    [MobjState] $RaiseState

    MobjInfo() {}
    # why do this dance you ask.. do not ask I have no idea.
    # Doing a simple constructor gives:
    # ParentContainsErrorRecordException: An error occurred while creating the pipeline.
    # replacing all types to string,int and bool works, all up to speed works so it's not the types..
    MobjInfo([hashtable]$params) {
        foreach ($key in $params.Keys) {
            if ($this.PSObject.Properties.Name -contains $key) {
                if ($key -eq "Flags") {
                    $this.$key = [MobjFlags]$params[$key]  # explicit casting.
                } else {
                    $this.$key = $params[$key]
                }
            }
        }
    }
}