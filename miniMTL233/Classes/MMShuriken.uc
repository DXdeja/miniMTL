class MMShuriken extends CBPShuriken;

var float CBPSpeed;

simulated function PostBeginPlay()
{
	if ((miniMTLTeam(Level.Game) != none && miniMTLTeam(Level.Game).bCBP) || 
		(miniMTLDeathMatch(Level.Game) != none && miniMTLDeathMatch(Level.Game).bCBP))
	{
		speed = CBPSpeed;
		MaxSpeed = CBPSpeed;
	}
}

auto simulated state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bStuck)
			return;

		if ((Other != instigator) && (DeusExProjectile(Other) == None) &&
			(Other != Owner))
		{
			damagee = Other;
			Explode(HitLocation, Normal(HitLocation-damagee.Location));

         if (Role == ROLE_Authority)
			{
            if (bBlood && miniMTLPlayer(damagee) != none)
				miniMTLPlayer(damagee).SpawnBloodFromProjectile(HitLocation, Normal(HitLocation - damagee.Location), Damage);
			}
		}
	}
}

defaultproperties
{
    CBPSpeed=950.00
    spawnWeaponClass=Class'MMWeaponShuriken'
}
