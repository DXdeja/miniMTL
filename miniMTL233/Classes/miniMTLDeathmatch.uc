class miniMTLDeathMatch extends MTLDeathMatch;

var class<miniMTLPlayer> PlayerClass[13];
var int NextPlayerClass;

var bool bCBP;

var int ReplMaxPlayers;

struct ScoreBoardInfo
{
    var string ServerName;
    var int NumPlayers;
    var int MaxPlayers;
    var string Map;
};

var ScoreBoardInfo SBInfo;

/** A new structure which extends teh new Scoreboard with informations */
struct PlayerInfo
{
     var bool bAdmin;
     var int ping;
     var bool bIsSpectator;
	 var int SpectatedPlayerID;
	 var string SpectatedPlayerName;
	 var bool bModerator;
};

var PlayerInfo PInfo[32]; //Array of the additional structure for 32 players

const IDX       = 0.22;
const PlayerX	= 0.27;
const KillsX	= 0.53;
const DeathsX	= 0.60;
const StreakX	= 0.67;
const PINGX     = 0.74;

const ADMINX_OFFSET = 120;
const SPECTX_OFFSET = 150;

var miniMTLSettings Settings;
var Mutator CallDestroy;

var class<miniMTLReplacer> ReplacerClass;

var string NextMapText;

var string TempBanAddr[32];

replication
{
    reliable if (Role == ROLE_Authority)
 		ReplMaxPlayers;

	unreliable if (Role == ROLE_Authority)
		NextMapText;
}


simulated function ContinueMsg( GC gc, float screenWidth, float screenHeight )
{
	local String str;
	local float x, y, w, h;
	local int t;

	if ( bNewMap && !bClientNewMap)
	{
		NewMapTime = Level.Timeseconds + NewMapDelay - 0.5;
		bClientNewMap = True;
	}
	t = int(NewMapTime - Level.Timeseconds);
	if ( t < 0 )
		t = 0;

	str = t $ NewMapSecondsString;

	if (NextMapText != "")
	{
		str = Left(str, Len(str) - 1);
		str = str $ ": " $ NextMapText;
	}

	gc.SetTextColor( WhiteColor );
	gc.SetFont(Font'FontMenuTitle');
	gc.GetTextExtent( 0, w, h, str );
	x = (screenWidth * 0.5) - (w * 0.5);
	y = screenHeight * FireContY;
	gc.DrawText( x, y, w, h, str );

	y += (h*2.0);
	str = EscapeString;
	gc.GetTextExtent( 0, w, h, str );
	x = (screenWidth * 0.5) - (w * 0.5);
	gc.DrawText( x, y, w, h, str );
}


event InitGame( string Options, out string Error )
{
    super.InitGame(Options,Error);
	Settings = Spawn(class'miniMTLSettings', self);
	CBPMutator(level.Game.BaseMutator).AddCBPMutator(Spawn(ReplacerClass));
	Spawn(class'MMNotifications');
}

function ProcessServerTravel( string URL, bool bItems )
{
    if (CallDestroy != none) CallDestroy.Destroy();
    super.ProcessServerTravel(URL, bItems);
}

event PreLogin
(
	string Options,
	string Address,
	out string Error,
	out string FailCode
)
{
	local int j;
	local string ip;

	super.PreLogin(Options, Address, Error, FailCode);

	if (Error == "")
	{
		j = InStr(Address, ":");
		if(j != -1) Address = Left(Address, j);
		for (j = 0; j < 32; j++)
		{
			if (TempBanAddr[j] == "") break;
			if (TempBanAddr[j] == Address)
			{
				Error = IPBanned;
				return;
			}
		}
	}
}

function class<miniMTLPlayer> GetSkin(string URL)
{
	local class<miniMTLPlayer> pclass;
	local miniMTLCustomSkin cskinloader;
	local string InPassword;

	InPassword = Left(ParseOption(URL, "SkinPassword"), 32);

	// check if there are any CustomSkins actors
	foreach AllActors(class'miniMTLCustomSkin', cskinloader)
	{
		pclass = cskinloader.GetSkinForDMPlayer(InPassword);
		if (pclass != none) return pclass;
	}

	// if no matches found, continue here...
	while (pclass == none)
	{
		pclass = PlayerClass[NextPlayerClass];
		NextPlayerClass++;
		if (NextPlayerClass == ArrayCount(PlayerClass)) NextPlayerClass = 0;
		foreach AllActors(class'miniMTLCustomSkin', cskinloader)
		{
			if (cskinloader.IgnoreDefaultSkin(pclass))
			{
				pclass = none;
				break;
			}
		}
	}

	return pclass;
}

event PlayerPawn Login (string Portal, string URL, out string Error, Class<PlayerPawn> SpawnClass)
{
 	local MTLPlayer newPlayer;
	local miniMTLPlayer mmplayer;
	local class<miniMTLPlayer> Skin;

	if ((MaxPlayers > 0) && (NumPlayers >= MaxPlayers))
	{
		Error=TooManyPlayers;
		return None;
	}

	Skin = GetSkin(URL);
	SpawnClass = DefaultPlayerClass;
	ChangeOption(URL, "Class", string(SpawnClass));

	newPlayer=MTLPlayer(super(DeathMatchGame).Login(Portal, URL, Error, SpawnClass));
	mmplayer = miniMTLPlayer(newPlayer);
	if (mmplayer != none)
	{
	    mmplayer.FixName(mmplayer.PlayerReplicationInfo.PlayerName);
		mmplayer.SkinClasses[0] = Skin;
		mmplayer.SetSkin();
    }

	return newPlayer;
}


event PostLogin(PlayerPawn Z5F)
{
	local miniMTLPlayer mmplayer;

    Super.PostLogin(Z5F);
	mmplayer = miniMTLPlayer(Z5F);
	if (mmplayer != none)
	{
	    if (mmplayer.PlayerReplicationInfo.Score == 0 && mmplayer.PlayerReplicationInfo.Deaths == 0
            && mmplayer.PlayerReplicationInfo.Streak == 0)
        {
            mmplayer.Spectate(1);
        }
        else mmplayer.FixInventory();
	}
}


function Logout(pawn Exiting)
{
   	super(TeamDMGame).Logout(Exiting);
	if (Exiting.IsA('PlayerPawn') && (PlayerPawn(Exiting).GameReplicationInfo == None))
	{
		NumPlayers++;
	}
}


function SetupAbilities(DeusExPlayer aPlayer)
{
    if (aPlayer == None) return;
    super.SetupAbilities(aPlayer);

    if (aPlayer.PlayerReplicationInfo.bIsSpectator)
    {
        aPlayer.SkillPointsAvail = 0;
        aPlayer.SkillPointsTotal = 0;
    }
}


function PostBeginPlay()
{
    super.PostBeginPlay();
    ReplMaxPlayers = MaxPlayers;
}


simulated function SetSpectatedPlayerNames()
{
	local int i, k;

	for (i = 0; i < scorePlayers; i++)
	{
		if (PInfo[i].bIsSpectator && PInfo[i].SpectatedPlayerID != -1)
		{
			for (k = 0; k < scorePlayers; k++)
			{
				if (scoreArray[k].PlayerID == PInfo[i].SpectatedPlayerID)
				{
					PInfo[i].SpectatedPlayerName = scoreArray[k].PlayerName;
					break;
				}
			}
		}
	}
}


/**
  Updates the score array with the latest information about the players.
*/
simulated function RefreshScoreArray (DeusExPlayer P)
{
	local int i;
	local PlayerReplicationInfo lpri;
	local PlayerPawn pp;
	local string str;

	if ( P == None )
	{
		return;
	}
	pp=P.GetPlayerPawn();
	if ( (pp == None) || (pp.GameReplicationInfo == None) )
	{
		return;
	}
	scorePlayers=0;

	for(i=0; i < 32; i++ )
	{
		lpri=pp.GameReplicationInfo.PRIArray[i];
		if ( lpri != None )
		{
			scoreArray[scorePlayers].PlayerName=lpri.PlayerName;
			scoreArray[scorePlayers].Score=lpri.Score;
			scoreArray[scorePlayers].Deaths=lpri.Deaths;
			scoreArray[scorePlayers].Streak=lpri.Streak;
			scoreArray[scorePlayers].Team=lpri.Team;
			scoreArray[scorePlayers].PlayerID=lpri.PlayerID;
            PInfo[scorePlayers].ping = lpri.ping;
            PInfo[scorePlayers].bAdmin = lpri.bAdmin;
            PInfo[scorePlayers].bIsSpectator = lpri.bIsSpectator;
			PInfo[scorePlayers].bModerator = MMPRI(lpri).bModerator;
			if (lpri.bIsSpectator && MMPRI(lpri) != none)
				PInfo[scorePlayers].SpectatedPlayerID = MMPRI(lpri).SpectatingPlayerID;
			scorePlayers++;
		}
	}

	SetSpectatedPlayerNames();

	SBInfo.ServerName = pp.GameReplicationInfo.ServerName;
	SBInfo.NumPlayers = scorePlayers;
	SBInfo.MaxPlayers = ReplMaxPlayers;
	str = string(self);
	SBInfo.Map = Left(str, InStr(str, "."));
}

simulated function ShowDMScoreboard( DeusExPlayer thisPlayer, GC gc, float screenWidth, float screenHeight )
{
     local float yoffset, ystart, xlen, ylen, w2;
     local String str;
     local bool bLocalPlayer;
     local int i;
     local float w, h;

     if ( !thisPlayer.PlayerIsClient() )
          return;

     gc.SetFont(Font'FontMenuSmall');

     RefreshScoreArray( thisPlayer );

     SortScores();

     str = "TEST";
     gc.GetTextExtent( 0, xlen, ylen, str );

     ystart = screenHeight * PlayerY;
     yoffset = ystart;

     gc.SetTextColor( WhiteColor );
     ShowVictoryConditions( gc, screenWidth, ystart, thisPlayer );
     yoffset += (ylen * 2.0);
     DrawHeaders( gc, screenWidth, yoffset );
     yoffset += (ylen * 1.5);

	 // draw non-spectators first
     for ( i = 0; i < scorePlayers; i++ )
     {
		  if (PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (scoreArray[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);

          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( WhiteColor );

          yoffset += ylen;
          DrawNameAndScore( gc, scoreArray[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(scoreArray[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(scoreArray[i].PlayerID));

          gc.GetTextExtent(0, w2, h, "Ping");
          gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));

		  str = "";

          if (PInfo[i].bAdmin) str = "Admin";
		  else if (PInfo[i].bModerator) str = "Mod";

		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(RedColor);
		  }
     }

	 // draw spectators
     for ( i = 0; i < scorePlayers; i++ )
     {
		  if (!PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (scoreArray[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);

          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( WhiteColor );

          yoffset += ylen;
          //DrawNameAndScore( gc, scoreArray[i], screenWidth, yoffset );
		  	str = scoreArray[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(scoreArray[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(scoreArray[i].PlayerID));

          gc.GetTextExtent(0, w2, h, "Ping");
          gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));

		  str = "";

          if (PInfo[i].bAdmin) str = "Admin";
		  else if (PInfo[i].bModerator) str = "Mod";

		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(RedColor);
		  }

		  if (PInfo[i].SpectatedPlayerID != -1)
			  str = "Spectating: " $ PInfo[i].SpectatedPlayerName;
		  else str = "Spectator";

		  gc.SetTextColorRGB(0, 255, 255);
		  gc.GetTextExtent(0, w, h, str);
		  //gc.DrawText(screenWidth * SPECTX, yOffset, w, h, str);
		  gc.DrawText(screenWidth * PlayerX + SPECTX_OFFSET, yOffset, w, h, str);
		  gc.SetTextColor(GreenColor);
     }

     ShowServerInfo(gc, yoffset + 2 * ylen, ylen, screenWidth);
}

simulated function string ComposeTime()
{
	local string ltime;

	if (Level.Hour < 10) ltime = "0";
	else ltime = "";

	ltime = ltime $ string(Level.Hour) $ ":";

	if (Level.Minute < 10) ltime = ltime $ "0";
	
	ltime = ltime $ string(Level.Minute);

	return ltime;
}

simulated function ShowServerInfo(GC gc, float yoffset, float ylen, float screenWidth)
{
    local float w, h, tw;
    local string str;

    gc.GetTextExtent(0, w, h, "Ping");
    gc.SetTileColorRGB(255,255,255);
    tw = ((screenWidth * PINGX) + w) - (IDX * screenWidth);
    gc.DrawBox(IDX * screenWidth, yoffset, tw, 1, 0, 0, 1, Texture'Solid');
    yoffset += ylen;

    str = "Server: " $ SBInfo.ServerName $ "     Map: " $ SBInfo.Map $ "     Players: " $ string(SBInfo.NumPlayers) $ "/" $ string(SBInfo.MaxPlayers);
    gc.SetTextColorRGB(255, 255, 255);
    gc.GetTextExtent(0, w, h, str);
    tw = (tw - w) / 2;
    gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
	yoffset += h + 2;

	str = "MiniMTL version: " $ class'miniMTLSettings'.default.ModVersion $ "     Current time: " $ ComposeTime();;
	gc.GetTextExtent(0, w, h, str);
	gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
}

simulated function SortScores()
{
     local PlayerReplicationInfo tmpri;
     local int i, j, max;
     local ScoreElement tmpSE;
     local PlayerInfo tmpPI;

     for ( i = 0; i < scorePlayers-1; i++ )
     {
          max = i;
          for ( j = i+1; j < scorePlayers; j++ )
          {
               if ( scoreArray[j].score > scoreArray[max].score )
                    max = j;
               else if (( scoreArray[j].score == scoreArray[max].score) && (scoreArray[j].deaths < scoreArray[max].deaths))
                    max = j;
          }
          tmpSE = scoreArray[max];
          tmpPI = PInfo[max];
          scoreArray[max] = scoreArray[i];
          PInfo[max] = PInfo[i];
          scoreArray[i] = tmpSE;
          PInfo[i] = tmpPI;
     }
}

simulated function DrawHeaders( GC gc, float screenWidth, float yoffset )
{
     local float x, w, h;

     gc.GetTextExtent( 0, w, h, PlayerString );
     x = screenWidth * PlayerX;
     gc.DrawText( x, yoffset, w, h, PlayerString );

     gc.GetTextExtent(0, w, h, "ID");
     x = screenWidth * IDX;
     gc.DrawText(x, yOffset, w, h, "ID");

     gc.GetTextExtent( 0, w, h, KillsString );
     x = screenWidth * KillsX;
     gc.DrawText( x, yoffset, w, h, KillsString );

     gc.GetTextExtent( 0, w, h, DeathsString );
     x = screenWidth * DeathsX;
     gc.DrawText( x, yoffset, w, h, DeathsString );

     gc.GetTextExtent( 0, w, h, StreakString );
     x = screenWidth * StreakX;
     gc.DrawText( x, yoffset, w, h, StreakString );

     gc.GetTextExtent(0, w, h, "Ping");
     x = screenWidth * PINGX;
     gc.DrawText(x, yOffset, w, h, "Ping");

     gc.SetTileColorRGB(255,255,255);
     gc.DrawBox( IDX * screenWidth, yoffset+h, (x + w)-(IDX*screenWidth), 1, 0, 0, 1, Texture'Solid');
}

simulated function DrawNameAndScore( GC gc, ScoreElement se, float screenWidth, float yoffset )
{
	local float x, w, h, w2, xoffset, killcx, deathcx, streakcx;
	local String str;

	// Draw Name
	str = se.PlayerName;
	gc.GetTextExtent( 0, w, h, str );
	x = screenWidth * PlayerX;
	gc.DrawText( x, yoffset, w, h, str );

	// Draw Kills
	str = "00";
	gc.GetTextExtent( 0, w, h, KillsString );
	killcx = screenWidth * KillsX + w * 0.5;
	gc.GetTextExtent( 0, w, h, str );
	str = int(se.Score) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = killcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );

	// Draw Deaths
	gc.GetTextExtent( 0, w2, h, DeathsString );
	deathcx = screenWidth * DeathsX + w2 * 0.5;
	str = int(se.Deaths) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = deathcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );

	// Draw Streak
	gc.GetTextExtent( 0, w2, h, StreakString );
	streakcx = screenWidth * StreakX + w2 * 0.5;
	str = int(se.Streak) $ "";
	gc.GetTextExtent( 0, w2, h, str );
	x = streakcx + (w * 0.5) - w2;
	gc.DrawText( x, yoffset, w2, h, str );
}

function bool CheckVictoryConditions( Pawn Killer, Pawn Killee, String Method )
{
	local Pawn winner;

	if ( VictoryCondition ~= "Frags" )
	{
		GetWinningPlayer( winner );

		if ( winner != None )
		{
			if (( winner.PlayerReplicationInfo.Score == ScoreToWin-(ScoreToWin/5)) && ( ScoreToWin >= 10 ))
				NotifyGameStatus( ScoreToWin/5, winner.PlayerReplicationInfo.PlayerName, False, False );
			else if (( winner.PlayerReplicationInfo.Score == (ScoreToWin - 1) ) && (ScoreTowin >= 2 ))
				NotifyGameStatus( 1, winner.PlayerReplicationInfo.PlayerName, False, True );

			if ( winner.PlayerReplicationInfo.Score >= ScoreToWin )
			{
				PlayerHasWon( winner, Killer, Killee, Method );
				return True;
			}
		}
	}
	else if ( VictoryCondition ~= "Time" )
	{
		timeLimit = float(ScoreToWin)*60.0;

		if (( Level.Timeseconds >= timeLimit-NotifyMinutes*60.0 ) && ( timeLimit > NotifyMinutes*60.0*2.0 ))
		{
			GetWinningPlayer( winner );
			if ( winner != none) NotifyGameStatus( int(NotifyMinutes), winner.PlayerReplicationInfo.PlayerName, True, True );
			else NotifyGameStatus( int(NotifyMinutes), "", True, True );
		}

		if ( Level.Timeseconds >= timeLimit )
		{
			GetWinningPlayer( winner );
			PlayerHasWon( winner, Killer, Killee, Method );
			return true;
		}
	}
	return false;
}

function string GetInfo()
{
	if (Settings != none)
		return super.GetInfo() $ "\\mod\\miniMTL" $ Settings.ModVersion;
	else return super.GetInfo();
}

defaultproperties
{
    PlayerClass(0)=Class'miniMTLBumMale'
    PlayerClass(1)=Class'miniMTLDoctor'
    PlayerClass(2)=Class'miniMTLMechanic'
    PlayerClass(3)=Class'miniMTLTracerTong'
    PlayerClass(4)=Class'miniMTLRiotCop'
    PlayerClass(5)=Class'miniMTLJoseph'
    PlayerClass(6)=Class'miniMTLSmuggler'
    PlayerClass(7)=Class'miniMTLThugMale'
    PlayerClass(8)=Class'miniMTLWaltonSimons'
    PlayerClass(9)=Class'miniMTLJCDenton'
    PlayerClass(10)=Class'miniMTLNSF'
    PlayerClass(12)=Class'miniMTLMJ12'
    ReplacerClass=Class'miniMTLReplacer'
    StreakString="Streak"
    DefaultPlayerClass=Class'miniMTLDMPlayer'
    HUDType=Class'miniMTLHUD'
    GameReplicationInfoClass=Class'MMGRI'
}
