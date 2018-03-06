class MMMPlayerTrack extends Actor;

var miniMTLPlayer MyPlayer;
var miniMTLPlayer AttachedPlayer;
var private float TimeSinceCloak;

function Tick (float VAE)
{
	MyPlayer = miniMTLPlayer(GetPlayerPawn());
	if ((AttachedPlayer == None) || (MyPlayer == None) || (AttachedPlayer == MyPlayer))
	{
		Destroy();
	} 
	else 
	{
		HandleNintendoEffect();
		HandlePlayerCloak(VAE);
	}
}

function HandleNintendoEffect()
{
	if (AttachedPlayer.NintendoImmunityTimeLeft > 0.00)
	{
		AttachedPlayer.DrawInvulnShield();
		if (AttachedPlayer.invulnSph != None)
		{
			AttachedPlayer.invulnSph.LifeSpan = AttachedPlayer.NintendoImmunityTimeLeft;
		}
	} 
	else 
	{
		if (AttachedPlayer.invulnSph != None)
		{
			AttachedPlayer.invulnSph.Destroy();
			AttachedPlayer.invulnSph = None;
		}
	}
}

function HandlePlayerCloak(float VAE)
{
	local DeusExRootWindow VAB;
	local Vector VC6;
	local float Z9E;

	if (AttachedPlayer.PlayerReplicationInfo != none && AttachedPlayer.PlayerReplicationInfo.bIsSpectator)
	{
		AttachedPlayer.KillShadow();
		AttachedPlayer.bHidden = true;
		AttachedPlayer.ScaleGlow = 0.0;
		return;
	}

	TimeSinceCloak = Abs(TimeSinceCloak) + VAE;

	AttachedPlayer.bHidden = False;

	if (AttachedPlayer.MeshType == 0)
	{
		TimeSinceCloak = 0.00;
		AttachedPlayer.CreateShadow();
		AttachedPlayer.ScaleGlow = AttachedPlayer.Default.ScaleGlow;
		return;
	}
	else 
	{
		AttachedPlayer.KillShadow();
		if (AttachedPlayer.MeshType >= 2)
		{
			AttachedPlayer.bHidden=True;
			return;
		}
	}
	if (((TeamDMGame(MyPlayer.DXGame) != None) && TeamDMGame(MyPlayer.DXGame).ArePlayersAllied(AttachedPlayer, MyPlayer)) ||
		(MyPlayer.PlayerReplicationInfo.bIsSpectator && MyPlayer.bSpecEnemies))
	{
		AttachedPlayer.ScaleGlow = 0.25;
	} 
	else 
	{
		AttachedPlayer.ScaleGlow = AttachedPlayer.Default.ScaleGlow * 0.01 / TimeSinceCloak;
		if (AttachedPlayer.ScaleGlow <= 0.02)
		{
			AttachedPlayer.ScaleGlow = 0.00;
			AttachedPlayer.bHidden = True;

			VAB=DeusExRootWindow(MyPlayer.RootWindow);
			if ((VAB != None) && (VAB.HUD != None) && (VAB.HUD.augDisplay != None) && VAB.HUD.augDisplay.bVisionActive)
			{
				VC6 = MyPlayer.Location;
				VC6.Z += MyPlayer.BaseEyeHeight;
				Z9E = VSize(AttachedPlayer.Location - VC6);
				if (Z9E <= VAB.HUD.augDisplay.visionLevelValue)
				{
					AttachedPlayer.bHidden = False;
				}
			}
		}
	}
}

defaultproperties
{
    TimeSinceCloak=10.00
    bHidden=True
}
