class MMNextMap extends Mutator config(MiniMTL);

var config bool bCountSpectators;
var config int NextMap;
var config string Maps[32];
var config int MinPlayerCount[32];
var config int MaxPlayerCount[32];
var config int ScoreToWin[32];
var config string VictoryCondition[32];

var bool bInt;
var bool bDone;
var int LoadingTime;

var string ForcedNextMap;

function PostBeginPlay()
{
	if (bInt) return;
	bInt = true;
	bDone = false;

	log("NextMap mutator is active.", 'MiniMTL');
	SetTimer(1, true);

	SaveConfig();
	Super.PostBeginPlay();
}

function Timer()
{
	local miniMTLPlayer playermm;

	if ((DeusExMPGame(Level.Game) != None) && DeusExMPGame(Level.Game).bNewMap)
 	{
		if (!bDone)
		{
 			Level.Game.SetTimer(0, false);
			LoadingTime = 0;
			bDone = true;
		}

		if (bDone)
		{
			if (miniMTLTeam(Level.Game) != none) miniMTLTeam(Level.Game).NextMapText = GetNextMap();
			else if (miniMTLDeathMatch(Level.Game) != none) miniMTLDeathMatch(Level.Game).NextMapText = GetNextMap();
		}

 		if (LoadingTime++ == 11)
		{
			LoadNextMap();
			SetTimer(0, false);
		}
 	}
}

function int GetNumberOfPlayers()
{
	local Pawn P;
	local int c;

	if (bCountSpectators) return Level.Game.GameReplicationInfo.NumPlayers;
	else
	{
		P = Level.PawnList;
		c = 0;
		while (P != none)
		{
			if (PlayerPawn(P) != none && !PlayerPawn(P).PlayerReplicationInfo.bIsSpectator) c++;
			P = P.nextPawn;
		}
		return c;
	}
}


function string GetNextMap()
{
	local int nump, oldnm;
	local int localNextMap;

	if (ForcedNextMap != "")
	{
		return ForcedNextMap;
	}

	localNextMap = NextMap;
	nump = GetNumberOfPlayers();
	oldnm = localNextMap;
	localNextMap++;

	while (true)
	{
		if (localNextMap >= 32) localNextMap = 0;
		if (Maps[localNextMap] == "") localNextMap = 0;

		if (localNextMap == oldnm)
		{
			return "";
		}
		if (MinPlayerCount[localNextMap] != 0 && nump < MinPlayerCount[localNextMap])
		{
			// skip this map - too little players to play it
			localNextMap++;
			continue;
		}
		if (MaxPlayerCount[localNextMap] != 0 && nump > MaxPlayerCount[localNextMap])
		{
			// skip this map - too many players to play it
			localNextMap++;
			continue;
		}

		break;
	}

	return Maps[localNextMap];
}


function LoadNextMap()
{
	local int nump, oldnm;

	if (ForcedNextMap != "")
	{
		Level.ServerTravel(ForcedNextMap, false);
		return;
	}

	nump = GetNumberOfPlayers();
	oldnm = NextMap;
	NextMap++;

	while (true)
	{
		if (NextMap >= 32) NextMap = 0;
		if (Maps[NextMap] == "") NextMap = 0;

		if (NextMap == oldnm)
		{
			log("NextMap mutator is not properly configured. Check config!", 'MiniMTL');
			Level.ServerTravel("", false);
			return;
		}
		if (MinPlayerCount[NextMap] != 0 && nump < MinPlayerCount[NextMap])
		{
			// skip this map - too little players to play it
			NextMap++;
			continue;
		}
		if (MaxPlayerCount[NextMap] != 0 && nump > MaxPlayerCount[NextMap])
		{
			// skip this map - too many players to play it
			NextMap++;
			continue;
		}

		break;
	}

	if (ScoreToWin[NextMap] > 0.0)
	{
		DeusExMPGame(Level.Game).ScoreToWin = ScoreToWin[NextMap];
		Level.Game.SaveConfig();
	}
	if (VictoryCondition[NextMap] ~= "Time" || VictoryCondition[NextMap] ~= "Frags")
	{
		DeusExMPGame(Level.Game).VictoryCondition = VictoryCondition[NextMap];
		Level.Game.SaveConfig();
	}
	SaveConfig();
	Level.ServerTravel(Maps[NextMap], false);
}


function Mutate(string S, PlayerPawn P)
{
	local miniMTLPlayer dxp;
	Super.Mutate(S, P);

	dxp = miniMTLPlayer(P);
	if (P != None)
	{
		if ((dxp.bModerator || dxp.bAdmin) && S ~= "nextmap")
		{
			LoadNextMap();
		}
		else if (dxp.bAdmin && S ~= "clearnextmap")
		{
			ForcedNextMap = "";
			P.ClientMessage("Next map setting cleared!", , true);
		}
		else if (dxp.bAdmin && Left(S, InStr(S, " ")) ~= "setnextmap")
		{
			ForcedNextMap = Right(S, Len(S) - InStr(S, " "));
			P.ClientMessage("Next map set to: " $ ForcedNextMap, , true);
		}
	}
}

defaultproperties
{
     RemoteRole=ROLE_None
}
