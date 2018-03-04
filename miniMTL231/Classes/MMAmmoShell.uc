class MMAmmoShell extends AmmoShell;

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
