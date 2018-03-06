class miniMTLCustomSkin extends Info
	abstract
	config(CustomSkins);

function PostBeginPlay()
{
	super.PostBeginPlay();
	SaveConfig();
}

// override this
function class<miniMTLPlayer> GetSkinForDMPlayer(string password)
{
	return none;
}

function bool GetSkinForTeamPlayer(string password, out class<miniMTLPlayer> Team0, out class<miniMTLPlayer> Team1)
{
	return false;
}

// used for DM games
function bool IgnoreDefaultSkin(class<miniMTLPlayer> SkinToCheck)
{
	return false;
}

defaultproperties
{
    RemoteRole=0
}
