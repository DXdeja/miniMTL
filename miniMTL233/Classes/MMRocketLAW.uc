class MMRocketLAW extends RocketLAW;

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
}
