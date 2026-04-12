
class MobjActions {
    MobjActions() {}

    [void] BFGSpray($world, $actor) { $world.WeaponBehavior.BFGSpray($actor) }
    [void] Explode($world, $actor) { $world.MonsterBehavior.Explode($actor) }
    [void] Pain($world, $actor) { $world.MonsterBehavior.Pain($actor) }
    [void] PlayerScream($world, $actor) { $world.PlayerBehavior.PlayerScream($actor) }
    [void] Fall($world, $actor) { $world.MonsterBehavior.Fall($actor) }
    [void] XScream($world, $actor) { $world.MonsterBehavior.XScream($actor) }
    [void] Look($world, $actor) {
        try {
            $world.MonsterBehavior.Look($actor)
        } catch {
            [Console]::WriteLine(("MobjActions.Look exception: " + $_.Exception))
            if ($null -ne $_.InvocationInfo) { [Console]::WriteLine(("MobjActions.Look position: " + $_.InvocationInfo.PositionMessage.Trim())) }
            throw
        }
    }
    [void] Chase($world, $actor) { $world.MonsterBehavior.Chase($actor) }
    [void] FaceTarget($world, $actor) { $world.MonsterBehavior.FaceTarget($actor) }
    [void] PosAttack($world, $actor) { $world.MonsterBehavior.PosAttack($actor) }
    [void] Scream($world, $actor) { $world.MonsterBehavior.Scream($actor) }
    [void] SPosAttack($world, $actor) { $world.MonsterBehavior.SPosAttack($actor) }
    [void] VileChase($world, $actor) { $world.MonsterBehavior.VileChase($actor) }
    [void] VileStart($world, $actor) { $world.MonsterBehavior.VileStart($actor) }
    [void] VileTarget($world, $actor) { $world.MonsterBehavior.VileTarget($actor) }
    [void] VileAttack($world, $actor) { $world.MonsterBehavior.VileAttack($actor) }
    [void] StartFire($world, $actor) { $world.MonsterBehavior.StartFire($actor) }
    [void] Fire($world, $actor) { $world.MonsterBehavior.Fire($actor) }
    [void] FireCrackle($world, $actor) { $world.MonsterBehavior.FireCrackle($actor) }
    [void] Tracer($world, $actor) { $world.MonsterBehavior.Tracer($actor) }
    [void] SkelWhoosh($world, $actor) { $world.MonsterBehavior.SkelWhoosh($actor) }
    [void] SkelFist($world, $actor) { $world.MonsterBehavior.SkelFist($actor) }
    [void] SkelMissile($world, $actor) { $world.MonsterBehavior.SkelMissile($actor) }
    [void] FatRaise($world, $actor) { $world.MonsterBehavior.FatRaise($actor) }
    [void] FatAttack1($world, $actor) { $world.MonsterBehavior.FatAttack1($actor) }
    [void] FatAttack2($world, $actor) { $world.MonsterBehavior.FatAttack2($actor) }
    [void] FatAttack3($world, $actor) { $world.MonsterBehavior.FatAttack3($actor) }
    [void] BossDeath($world, $actor) { $world.MonsterBehavior.BossDeath($actor) }
    [void] CPosAttack($world, $actor) { $world.MonsterBehavior.CPosAttack($actor) }
    [void] CPosRefire($world, $actor) { $world.MonsterBehavior.CPosRefire($actor) }
    [void] TroopAttack($world, $actor) { $world.MonsterBehavior.TroopAttack($actor) }
    [void] SargAttack($world, $actor) { $world.MonsterBehavior.SargAttack($actor) }
    [void] HeadAttack($world, $actor) { $world.MonsterBehavior.HeadAttack($actor) }
    [void] BruisAttack($world, $actor) { $world.MonsterBehavior.BruisAttack($actor) }
    [void] SkullAttack($world, $actor) { $world.MonsterBehavior.SkullAttack($actor) }
    [void] Metal($world, $actor) { $world.MonsterBehavior.Metal($actor) }
    [void] SpidRefire($world, $actor) { $world.MonsterBehavior.SpidRefire($actor) }
    [void] BabyMetal($world, $actor) { $world.MonsterBehavior.BabyMetal($actor) }
    [void] BspiAttack($world, $actor) { $world.MonsterBehavior.BspiAttack($actor) }
    [void] Hoof($world, $actor) { $world.MonsterBehavior.Hoof($actor) }
    [void] CyberAttack($world, $actor) { $world.MonsterBehavior.CyberAttack($actor) }
    [void] PainAttack($world, $actor) { $world.MonsterBehavior.PainAttack($actor) }
    [void] PainDie($world, $actor) { $world.MonsterBehavior.PainDie($actor) }
    [void] KeenDie($world, $actor) { $world.MonsterBehavior.KeenDie($actor) }
    [void] BrainPain($world, $actor) { $world.MonsterBehavior.BrainPain($actor) }
    [void] BrainScream($world, $actor) { $world.MonsterBehavior.BrainScream($actor) }
    [void] BrainDie($world, $actor) { $world.MonsterBehavior.BrainDie($actor) }
    [void] BrainAwake($world, $actor) { $world.MonsterBehavior.BrainAwake($actor) }
    [void] BrainSpit($world, $actor) { $world.MonsterBehavior.BrainSpit($actor) }
    [void] SpawnSound($world, $actor) { $world.MonsterBehavior.SpawnSound($actor) }
    [void] SpawnFly($world, $actor) { $world.MonsterBehavior.SpawnFly($actor) }
    [void] BrainExplode($world, $actor) { $world.MonsterBehavior.BrainExplode($actor) }
}