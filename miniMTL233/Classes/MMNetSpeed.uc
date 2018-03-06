class MMNetSpeed extends Info;

var miniMTLSettings SettingsRef;
var miniMTLPlayer PlayerToMod;

function PostBeginPlay()
{
	if (miniMTLDeathMatch(Level.Game) != none)
		SettingsRef = miniMTLDeathMatch(Level.Game).Settings;
	else if (miniMTLTeam(Level.Game) != none)
		SettingsRef = miniMTLTeam(Level.Game).Settings;

	if (SettingsRef != none && SettingsRef.bForceNetSpeed) SetTimer(2.0, false);
	else Destroy();
}

function Timer()
{
	if (PlayerToMod != none)
	{
		if (PlayerToMod.Player.CurrentNetSpeed < SettingsRef.MinNetSpeed)
			PlayerToMod.SetPlayerNetSpeed(SettingsRef.MinNetSpeed);
		else if (PlayerToMod.Player.CurrentNetSpeed > SettingsRef.MaxNetSpeed)
			PlayerToMod.SetPlayerNetSpeed(SettingsRef.MaxNetSpeed);
	}
	Destroy();
}

defaultproperties
{
    RemoteRole=0
}
