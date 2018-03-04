class miniMTLReplacer extends CBPMutator;

var class<Actor> toReplace[32];
var class<Actor> replaceTo[32];

function AddMutator(Mutator M)
{
    if(M.Class != class)
      super.AddMutator(M);
}

function PostBeginPlay()
{
	local Actor act;

	super.PostBeginPlay();

	foreach AllActors(class'Actor', act)
	{
		ReplaceMapItem(act, act.class);
		ModifyNetParam(act);
	}
}


function ReplaceMapItem(out Actor in, Class<Actor> inClass)
{
    local Actor act;
    local Inventory inv;
    local int i;
    local bool bFound;

    for (i = 0; i < ArrayCount(toReplace); i++)
    {
        if (inClass == toReplace[i])
        {
            bFound = true;
            break;
        }
    }
    if (bFound)
    {
		if (replaceTo[i] != none)
		{
			act = Spawn(replaceTO[i],in.owner,in.tag,in.location,in.Rotation);
			if (act != none)
			{
				//log("replacing"@in@"with"@act);
				act.SetPhysics(in.Physics);
				inv = Inventory(act);
				if (inv != none) 
				{
            		inv.RespawnTime = Inventory(in).RespawnTime;
					if (Weapon(inv) != none && Weapon(in) != none)
						Weapon(inv).SetCollisionSize(in.CollisionRadius, in.CollisionHeight);
				}
				if (AutoTurret(act) != none)
					AutoTurret(act).titleString = AutoTurret(in).titleString;
				in.Destroy();
				in=act;
			}
		}
		else
		{
			in.Destroy();
			in = none;
			return;
		}
    }
}


function ModifyNetParam(Actor in)
{
	if (AmmoCrate(in) != none || Robot(in) != none || 
		Inventory(in) != none || /*DeusExMover(in) != none ||*/
		DeusExDecoration(in) != none)
	{
		if (miniMTLCTFFlag(in) == none)
			in.bAlwaysRelevant = false;
	}
}

/**
  Right spawns <i>ReplaceMapItem()</i>, because the right summoned Actor can be replaced like all required Actors at the begin too.
*/
function SpawnNotification(out Actor in, Class<Actor> inClass)
{
	ReplaceMapItem(in, inClass);
	ModifyNetParam(in);
	super.ReplaceMapItem(in, inClass);
    super.SpawnNotification(in, inClass);
}

defaultproperties
{
     toReplace(0)=Class'DeusEx.WeaponAssaultShotgun'
     toReplace(1)=Class'DXMTL152b1.CBPWeaponPistol'
     toReplace(2)=Class'DeusEx.WeaponStealthPistol'
     toReplace(3)=Class'DeusEx.WeaponAssaultGun'
     toReplace(4)=Class'DeusEx.WeaponPlasmaRifle'
     toReplace(5)=Class'DeusEx.WeaponNanoSword'
     toReplace(6)=Class'DXMTL152b1.CBPWeaponShuriken'
     toReplace(7)=Class'DeusEx.WeaponCombatKnife'
     toReplace(8)=Class'DeusEx.WeaponMiniCrossbow'
     toReplace(9)=Class'DeusEx.WeaponSawedOffShotgun'
     toReplace(10)=Class'DXMTL152b1.CBPWeaponGEPGun'
     toReplace(11)=Class'DeusEx.WeaponLAW'
     toReplace(12)=Class'DXMTL152b1.CBPWeaponRifle'
     toReplace(13)=Class'DeusEx.WeaponLAM'
     toReplace(14)=Class'DeusEx.WeaponGasGrenade'
     toReplace(15)=Class'DeusEx.WeaponEMPGrenade'
     toReplace(16)=Class'DeusEx.AutoTurret'
     toReplace(17)=Class'DeusEx.WeaponFlamethrower'
     replaceTo(0)=Class'MMWeaponAssaultShotgun'
     replaceTo(1)=Class'MMWeaponPistol'
     replaceTo(2)=Class'MMWeaponStealthPistol'
     replaceTo(3)=Class'MMWeaponAssaultGun'
     replaceTo(4)=Class'MMWeaponPlasmaRifle'
     replaceTo(5)=Class'MMWeaponNanoSword'
     replaceTo(6)=Class'MMWeaponShuriken'
     replaceTo(7)=Class'MMWeaponCombatKnife'
     replaceTo(8)=Class'MMWeaponMiniCrossbow'
     replaceTo(9)=Class'MMWeaponSawedOffShotgun'
     replaceTo(10)=Class'MMWeaponGEPGun'
     replaceTo(11)=Class'MMWeaponLAW'
     replaceTo(12)=Class'MMWeaponRifle'
     replaceTo(13)=Class'MMWeaponLAM'
     replaceTo(14)=Class'MMWeaponGasGrenade'
     replaceTo(15)=Class'MMWeaponEMPGrenade'
     replaceTo(16)=Class'MMAutoTurret'
     replaceTo(17)=Class'MMWeaponFlamethrower'
     LifeSpan=5.000000
}
