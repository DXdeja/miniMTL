class MMAmmo762mm extends Ammo762mm;

simulated function bool SimUseAmmo()
{
	if ( AmmoAmount > 0 )
	{
		if (miniMTLPlayer(Owner) != none && miniMTLPlayer(Owner).bSpawnShellCasings)
			return super.SimUseAmmo();
		return True;
	}
	return False;
}

defaultproperties
{
}
