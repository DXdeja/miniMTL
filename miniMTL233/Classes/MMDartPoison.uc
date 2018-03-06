class MMDartPoison extends DartPoison;

var float CBPmpDamage;

simulated function PostBeginPlay()
{
	if ((miniMTLTeam(Level.Game) != none && miniMTLTeam(Level.Game).bCBP) || 
		(miniMTLDeathMatch(Level.Game) != none && miniMTLDeathMatch(Level.Game).bCBP)) Damage = CBPmpDamage;
}

defaultproperties
{
    CBPmpDamage=16.00
}
