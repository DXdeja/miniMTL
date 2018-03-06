class MMWeaponMiniCrossbow extends WeaponMiniCrossbow;

var float lastShotTime;
var float ffrtolerance;

function PostBeginPlay()
{
	super.PostBeginPlay();
	if (miniMTLTeam(Level.Game) != none) ffrtolerance = miniMTLTeam(Level.Game).Settings.FastFireRateTolerance;
	else if (miniMTLDeathmatch(Level.Game) != none) ffrtolerance = miniMTLDeathmatch(Level.Game).Settings.FastFireRateTolerance;
}

function Fire(float Value)
{
	local float diff;

	diff = Level.TimeSeconds - lastShotTime;
	diff -= 1.0 - ffrtolerance;
	if (diff < 0.0) return;
	lastShotTime = Level.TimeSeconds;
	
	super.Fire(value);
}

// fix bug related to firing when having no weapon in hand
simulated function bool ClientFire( float value )
{
	if (DeusExPlayer(Owner) != none && DeusExPlayer(Owner).inHand != self) return false;
	return super.ClientFire(value);
}

defaultproperties
{
    ffrtolerance=0.01
    ProjectileNames=Class'MMDartPoison'
    ProjectileClass=Class'MMDartPoison'
}
