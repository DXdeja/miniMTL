class miniMTLTeam extends MTLTeam;

var bool bCBP;

var class<miniMTLPlayer> Team0PlayerClass;
var class<miniMTLPlayer> Team1PlayerClass;
var int InitialTeam;

var int ReplMaxPlayers;

struct ScoreBoardInfo
{
    var string ServerName;
    var int NumPlayers;
    var int MaxPlayers;
    var string Map;
};

var ScoreBoardInfo SBInfo;
var int SpecCountUNATCO;
var int SpecCountNSF;

struct PlayerInfo
{
     var bool bAdmin;
     var int ping;
     var bool bIsSpectator;
 	 var int SpectatedPlayerID;
	 var string SpectatedPlayerName;
	 var bool bDead;
	 var bool bFlag;
	 var bool bModerator;
};

var PlayerInfo PInfo[32]; //Array of the additional structure for 32 players
/** @ignore */
var PlayerInfo PI[32];

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
var bool bReflectiveDamage;

var string TempBanAddr[32];

replication
{
    reliable if (Role == ROLE_Authority)
 		ReplMaxPlayers, bReflectiveDamage;

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

function bool ChangeTeam(Pawn Z61, int NewTeam)
{
	local miniMTLPlayer Z63;

	if (Super.ChangeTeam(Z61, NewTeam))
	{
		Z63 = miniMTLPlayer(Z61);
		if (Z63 != none)
		{
			Z63.SetSkin(); // fix skin in case of being incorrect
			Z63.V6B[0]=Z63.MultiSkins[5];
			Z63.V6B[1]=Z63.MultiSkins[6];
			Z63.V6B[2]=Z63.MultiSkins[7];
			Z63.V7C = True;
			Z63.V68 = 0;
			Z63.CarcassType = Z63.Default.CarcassType;
		}
		return true;
	}
	return false;
}


event InitGame( string Options, out string Error )
{
    super.InitGame(Options,Error);
	Settings = Spawn(class'miniMTLSettings', self);
	CBPMutator(level.Game.BaseMutator).AddCBPMutator(Spawn(ReplacerClass));
	Spawn(class'MMTeamBalancer');
	Spawn(class'MMNotifications');
	bReflectiveDamage = Settings.bReflectiveDamage;
}


function bool RestartPlayer( pawn aPlayer )
{
	local MMPRI pri;
	local bool res;
	res = super.RestartPlayer(aPlayer);
	if (res)
	{
		pri = MMPRI(aPlayer.PlayerReplicationInfo);
		if (pri != none) pri.bDead = false;
	}
	return res;
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

function GetTeamSkins(string URL, out class<miniMTLPlayer> Team0Skin, out class<miniMTLPlayer> Team1Skin)
{
	local class<miniMTLPlayer> pclass;
	local miniMTLCustomSkin cskinloader;
	local string InPassword;

	InPassword = Left(ParseOption(URL, "SkinPassword"), 32);

	// check if there are any CustomSkins actors
	foreach AllActors(class'miniMTLCustomSkin', cskinloader)
	{
		if (cskinloader.GetSkinForTeamPlayer(InPassword, Team0Skin, Team1Skin))
			return;
	}

	Team0Skin = Team0PlayerClass;
	Team1Skin = Team1PlayerClass;
}

event PlayerPawn Login(string Portal, string URL, out string Error, Class<PlayerPawn> SpawnClass)
{
	local MTLPlayer newPlayer;
	local int Z5C;
	local string Z5D;
	local miniMTLPlayer mmplayer;
	local class<miniMTLPlayer> Skins[2];

	if ( (MaxPlayers > 0) && (NumPlayers >= MaxPlayers) )
	{
		Error=TooManyPlayers;
		return None;
	}

	GetTeamSkins(URL, Skins[0], Skins[1]);

	Z5C = 128;
	if (HasOption(URL, "Team"))
	{
		Z5D = ParseOption(URL, "Team");
		if (Z5D != "") Z5C = int(Z5D);
	}
	if (Z5C != 1 && Z5C != 0) Z5C = GetAutoTeam();
	if (Z5C == 1) SpawnClass = Team1PlayerClass;
	else SpawnClass = Team0PlayerClass;
	InitialTeam = Z5C;

	ChangeOption(URL, "Class", string(SpawnClass));
	ChangeOption(URL, "Team", string(Z5C));
	newPlayer = MTLPlayer(Super(DeusExMPGame).Login(Portal, URL, Error, SpawnClass));
	mmplayer = miniMTLPlayer(newPlayer);
	if (mmplayer != None)
	{
		mmplayer.FixName(mmplayer.PlayerReplicationInfo.PlayerName);
		mmplayer.SkinClasses[0] = Skins[0];
		mmplayer.SkinClasses[1] = Skins[1];
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
        else 
        {
        	mmplayer.FixInventory();
        }
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


function SetTeam (DeusExPlayer Z5F)
{
	Z5F.PlayerReplicationInfo.Team = InitialTeam;
}


function int GetAutoTeam()
{
   local int NumUNATCO;
   local int NumNSF;
   local int CurTeam;
   local Pawn CurPawn;

   NumUNATCO = 0;
   NumNSF = 0;

   for (CurPawn = Level.Pawnlist; CurPawn != None; CurPawn = CurPawn.NextPawn)
   {
      if ((PlayerPawn(CurPawn) != None) && (PlayerPawn(CurPawn).PlayerReplicationInfo != None))
      {
         if (PlayerPawn(CurPawn).PlayerReplicationInfo.bIsSpectator) continue;

         CurTeam = PlayerPawn(CurPawn).PlayerReplicationInfo.Team;
         if (CurTeam == TEAM_UNATCO)
         {
            NumUNATCO++;
         }
         else if (CurTeam == TEAM_NSF)
         {
            NumNSF++;
         }
      }
   }

   if (NumUNATCO < NumNSF)
      return TEAM_UNATCO;
   else if (NumUNATCO > NumNSF)
      return TEAM_NSF;
   else
//      return TEAM_UNATCO;
     return Rand(2);
}


function Killed( pawn Killer, pawn Other, name damageType )
{
	local bool NotifyDeath;
	local DeusExPlayer otherPlayer;
	local Pawn CurPawn;

   if ( bFreezeScores )
      return;

	NotifyDeath = False;

	// Record the death no matter what, and reset the streak counter
	if ( Other.bIsPlayer )
	{
		otherPlayer = DeusExPlayer(Other);

		Other.PlayerReplicationInfo.Deaths += 1;
		Other.PlayerReplicationInfo.Streak = 0;
		// Penalize the player that commits suicide by losing a kill, but don't take them below zero
		if ((Killer == Other) || (Killer == None))
		{
			if ( Other.PlayerReplicationInfo.Score > 0 )
			{
				if (( DeusExProjectile(otherPlayer.myProjKiller) != None ) && DeusExProjectile(otherPlayer.myProjKiller).bAggressiveExploded )
				{
					// Don't dock them if it nano exploded in their face
				}
				else
					Other.PlayerReplicationInfo.Score -= 1;
			}
		}
		NotifyDeath = True;
	}

	if (Killer == none)
    {
        // deadly fall
        Killer = Other;
    }

   //both players...
   if ((Killer.bIsPlayer) && (Other.bIsPlayer))
   {
 	    //Add to console log as well (with pri id) so that kick/kickban can work better
 	    log(Killer.PlayerReplicationInfo.PlayerName$"("$Killer.PlayerReplicationInfo.PlayerID$") killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr);
		for (CurPawn = Level.PawnList; CurPawn != None; CurPawn = CurPawn.NextPawn)
		{
			if ((CurPawn.IsA('DeusExPlayer')) && (DeusExPlayer(CurPawn).bAdmin))
				DeusExPlayer(CurPawn).LocalLog(Killer.PlayerReplicationInfo.PlayerName$"("$Killer.PlayerReplicationInfo.PlayerID$") killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr);
		}

		if ( otherPlayer.killProfile.methodStr ~= "None" )
			BroadcastMessage(Killer.PlayerReplicationInfo.PlayerName$" killed "$Other.PlayerReplicationInfo.PlayerName$".",false,'DeathMessage');
		else
			BroadcastMessage(Killer.PlayerReplicationInfo.PlayerName$" killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr, false, 'DeathMessage');

		if (Killer != Other)
		{
			// Penalize for killing your teammates
			if (ArePlayersAllied(DeusExPlayer(Other),DeusExPlayer(Killer)))
			{
				if ( Killer.PlayerReplicationInfo.Score > 0 )
					Killer.PlayerReplicationInfo.Score -= 1;
				DeusExPlayer(Killer).MultiplayerNotifyMsg( DeusExPlayer(Killer).MPMSG_KilledTeammate, 0, "" );
			}
			else
			{
				// Grant the kill to the killer, and increase his streak
				Killer.PlayerReplicationInfo.Score += 1;
				Killer.PlayerReplicationInfo.Streak += 1;

				Reward(Killer);

				// Check for victory conditions and end the match if need be
				if (CheckVictoryConditions(Killer, Other, otherPlayer.killProfile.methodStr) )
                {
                    bFreezeScores = True;
                    NotifyDeath = False;
				}
			}
		}
		if ( NotifyDeath )
			HandleDeathNotification( Killer, Other );
   }
   else
   {
		if (NotifyDeath)
			HandleDeathNotification( Killer, Other );

      super(DeusExGameInfo).Killed(Killer,Other,damageType);
   }

   BaseMutator.ScoreKill(Killer, Other);
}


simulated function SetSpectatedPlayerNames()
{
	local int i, k;

	for (i = 0; i < scorePlayers; i++)
	{
		if (PI[i].bIsSpectator && PI[i].SpectatedPlayerID != -1)
		{
			for (k = 0; k < scorePlayers; k++)
			{
				if (scoreArray[k].PlayerID == PI[i].SpectatedPlayerID)
				{
					PI[i].SpectatedPlayerName = scoreArray[k].PlayerName;
					break;
				}
			}
		}
	}
}


simulated function RefreshScoreArray (DeusExPlayer P)
{
	local int i;
	local MMPRI lpri;
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
	scorePlayers = 0;
    SpecCountUNATCO = 0;
    SpecCountNSF = 0;

	for(i=0; i < 32; i++ )
	{
		lpri = MMPRI(pp.GameReplicationInfo.PRIArray[i]);
		//if ( (lpri != None) && ( !lpri.bIsSpectator || lpri.bWaitingPlayer) )
		if (lpri != None)
		{
			scoreArray[scorePlayers].PlayerName=lpri.PlayerName;
			scoreArray[scorePlayers].Score=lpri.Score;
			scoreArray[scorePlayers].Deaths=lpri.Deaths;
			scoreArray[scorePlayers].Streak=lpri.Streak;
			scoreArray[scorePlayers].Team=lpri.Team;
			scoreArray[scorePlayers].PlayerID=lpri.PlayerID;
            PI[scorePlayers].ping = lpri.ping;
            PI[scorePlayers].bAdmin = lpri.bAdmin;
            PI[scorePlayers].bIsSpectator = lpri.bIsSpectator;
			PI[scorePlayers].bModerator = lpri.bModerator;
            if (lpri.bIsSpectator)
            {
                if (lpri.Team == 0) SpecCountUNATCO++;
                else SpecCountNSF++;
				PI[scorePlayers].SpectatedPlayerID = lpri.SpectatingPlayerID;
            }
			else
			{
				PI[scorePlayers].bDead = lpri.bDead;
				if (lpri.Flag != none) PI[scorePlayers].bFlag = true;
				else PI[scorePlayers].bFlag = false;
			}
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


simulated function LocalGetTeamTotalsX( int teamSECnt, out float score, out float deaths, out float streak, DeusExPlayer thisPlayer, int team)
{
	local int i;

	score = 0; deaths = 0; streak = 0;
	for ( i = 0; i < teamSECnt; i++ )
	{
		score += teamSE[i].Score;
		deaths += teamSE[i].Deaths;
		streak += teamSE[i].Streak;
	}
}


simulated function string GetTeamNameForScoreboard(int number_of_specs, string AlliesString, string teamStr, DeusExPlayer thisPlayer, int team)
{
	return "(" $ string(number_of_specs) $ ") " $ AlliesString $ " (" $ teamStr $ ")";
}

simulated function ShowTeamDMScoreboard( DeusExPlayer thisPlayer, GC gc, float screenWidth, float screenHeight ) // modified by nil
{
     local float yoffset, ystart, xlen,ylen, w, h, w2;
     local bool bLocalPlayer;
     local int i, allyCnt, enemyCnt, barLen, t;
     local ScoreElement fakeSE;
     local String str, teamStr;
     local int CntNoSpec;

     if (!thisPlayer.PlayerIsClient())
          return;

     // Always use this font
     gc.SetFont(Font'FontMenuSmall');
     str = "TEST";
     gc.GetTextExtent( 0, xlen, ylen, str );

     // Refresh out local array
     RefreshScoreArray( thisPlayer );

     // Just allies
     allyCnt = GetTeamList( thisPlayer, true );
     SortTeamScores( allyCnt );

     ystart = screenHeight * PlayerY;
     yoffset = ystart;

     // Headers
     gc.SetTextColor( WhiteColor );
     ShowVictoryConditions( gc, screenWidth, ystart, thisPlayer );
     yoffset += (ylen * 2.0);
     DrawHeaders( gc, screenWidth, yoffset );
     yoffset += (ylen * 1.5);

     if (thisPlayer.PlayerReplicationInfo.team == TEAM_UNATCO )
     {
          teamStr = TeamUnatcoString;
          CntNoSpec = allyCnt - SpecCountUNATCO;
     }
     else
     {
          teamStr = TeamNsfString;
          CntNoSpec = allyCnt - SpecCountNSF;
     }

     // Allies
     gc.SetTextColor( GreenColor );
     //fakeSE.PlayerName = "(" $ string(CntNoSpec) $ ") " $ AlliesString $ " (" $ teamStr $ ")";
	 fakeSE.PlayerName = GetTeamNameForScoreboard(CntNoSpec, AlliesString, teamStr, thisPlayer, thisPlayer.PlayerReplicationInfo.Team);
     LocalGetTeamTotalsX( allyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak, thisPlayer, thisPlayer.PlayerReplicationInfo.Team);
	 //LocalGetTeamTotals( allyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak);
     DrawNameAndScore( gc, fakeSE, screenWidth, yoffset );
     gc.GetTextExtent( 0, w, h, "Ping" );
     barLen = (screenWidth * PINGX + w)-(IDX*screenWidth);
     gc.SetTileColorRGB(0,255,0);
     gc.DrawBox( IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
     yoffset += ( h * 0.25 );

     // draw all non-spectators
     for ( i = 0; i < allyCnt; i++ )
     {
          if (PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (teamSE[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);
          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( GreenColor );
          yoffset += ylen;
          DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

          gc.GetTextExtent(0, w2, h, "Ping");
          gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));

		  str = "";
		  if (PInfo[i].bDead) str = "[D]";
		  else if (PInfo[i].bFlag) str = "[F]";
		  if (str != "")
		  {
		      gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX - w - 2, yOffset, w, h, str);
		  }

		  str = "";

          if (PInfo[i].bAdmin) str = "Admin";
		  else if (PInfo[i].bModerator) str = "Mod";

		  if (str != "")
		  {
			  gc.SetTextColorRGB(0, 255, 255);
              gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX + ADMINX_OFFSET, yOffset, w, h, str);
              gc.SetTextColor(GreenColor);
		  }
     }

     // draw all spectators
     for ( i = 0; i < allyCnt; i++ )
     {
          if (!PInfo[i].bIsSpectator) continue;
          bLocalPlayer = (teamSE[i].PlayerID == thisPlayer.PlayerReplicationInfo.PlayerID);
          if ( bLocalPlayer )
               gc.SetTextColor( GoldColor );
          else
               gc.SetTextColor( GreenColor );
          yoffset += ylen;
          //DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

			// Draw Name
			str = teamSE[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText(screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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
              gc.SetTextColor(GreenColor);
		  }

		  if (PInfo[i].SpectatedPlayerID != -1)
			str = "Spectating: " $ PInfo[i].SpectatedPlayerName;
		  else str = "Spectator";

          gc.SetTextColorRGB(0, 255, 255);
          gc.GetTextExtent(0, w, h, str);
          //gc.DrawText(screenWidth * SPECTX,yOffset, w, h, str);
		  gc.DrawText(screenWidth * PlayerX + SPECTX_OFFSET, yOffset, w, h, str);
          gc.SetTextColor(GreenColor);
     }

     yoffset += (ylen*2);

     // Enemies
     enemyCnt = GetTeamList( thisPlayer, false );
     SortTeamScores( enemyCnt );

     if ( thisPlayer.PlayerReplicationInfo.team == TEAM_UNATCO )
     {
          teamStr = TeamNsfString;
          CntNoSpec = enemyCnt - SpecCountNSF;
		  t = 1;
     }
     else
     {
          teamStr = TeamUnatcoString;
          CntNoSpec = enemyCnt - SpecCountUNATCO;
		  t = 0;
     }

     gc.SetTextColor( RedColor );
     //fakeSE.PlayerName = "(" $ string(CntNoSpec) $ ") " $ EnemiesString $ " (" $ teamStr $ ")";
	 fakeSE.PlayerName = GetTeamNameForScoreboard(CntNoSpec, EnemiesString, teamStr, thisPlayer, t);
     LocalGetTeamTotalsX( enemyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak, thisPlayer, t);
	 //LocalGetTeamTotals( enemyCnt, fakeSE.score, fakeSE.deaths, fakeSE.streak);
     DrawNameAndScore( gc, fakeSE, screenWidth, yoffset );
     gc.SetTileColorRGB(255,0,0);
     gc.DrawBox( IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
     yoffset += ( h * 0.25 );

     // draw all non-spectators
     for ( i = 0; i < enemyCnt; i++ )
     {
         if (PInfo[i].bIsSpectator) continue;
          yoffset += ylen;
          DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

          gc.GetTextExtent(0, w2, h, "Ping");
          gc.GetTextExtent(0, w, h, string(PInfo[i].ping));
          gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(PInfo[i].ping));

		  str = "";
		  if (PInfo[i].bDead) str = "[D]";
		  else if (PInfo[i].bFlag) str = "[F]";
		  if (str != "")
		  {
		      gc.GetTextExtent(0, w, h, str);
			  gc.DrawText(screenWidth * PlayerX - w - 2, yOffset, w, h, str);
		  }

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

     // draw all spectators
     for ( i = 0; i < enemyCnt; i++ )
     {
         if (!PInfo[i].bIsSpectator) continue;
          yoffset += ylen;
          //DrawNameAndScore( gc, teamSE[i], screenWidth, yoffset );

		  	// Draw Name
			str = teamSE[i].PlayerName;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( screenWidth * PlayerX, yoffset, w, h, str );

          gc.GetTextExtent(0, w, h, string(teamSE[i].PlayerID));
          gc.DrawText(screenWidth * IDX, yOffset, w, h, string(teamSE[i].PlayerID));

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
          gc.SetTextColor(RedColor);
     }

     ShowServerInfo(gc, yoffset + 2 * ylen, ylen, screenWidth);
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

	str = "MiniMTL version: " $ class'miniMTLSettings'.default.ModVersion;
	gc.GetTextExtent(0, w, h, str);
	gc.DrawText((screenWidth * IDX) + tw, yoffset, w, h, str);
}

simulated function SortTeamScores( int PlayerCount )
{
     local ScoreElement tmpSE;
     local PlayerInfo tmpPI;
     local int i, j, max;

     for ( i = 0; i < PlayerCount-1; i++ )
     {
          max = i;
          for ( j = i+1; j < PlayerCount; j++ )
          {
               if ( teamSE[j].Score > teamSE[max].Score )
                    max = j;
               else if (( teamSE[j].Score == teamSE[max].Score) && (teamSE[j].Deaths < teamSE[max].Deaths))
                    max = j;
          }
          tmpSE = teamSE[max];
          tmpPI = PInfo[max];
          teamSE[max] = teamSE[i];
          PInfo[max] = PInfo[i];
          teamSE[i] = tmpSE;
          PInfo[i] = tmpPI;
     }
}


simulated function DrawHeaders( GC gc, float screenWidth, float yoffset )
{
     local float x, w, h;

     // Player header
     gc.GetTextExtent( 0, w, h, PlayerString );
     x = screenWidth * PlayerX;
     gc.DrawText(x, yoffset, w, h, PlayerString );

     gc.GetTextExtent(0, w,h, "ID");
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
	if (se.Score >= 0)
	{
		str = "00";
		gc.GetTextExtent( 0, w, h, KillsString );
		killcx = screenWidth * KillsX + w * 0.5;
		gc.GetTextExtent( 0, w, h, str );
		str = int(se.Score) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = killcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
	}

	// Draw Deaths
	if (se.Deaths >= 0)
	{
		gc.GetTextExtent( 0, w2, h, DeathsString );
		deathcx = screenWidth * DeathsX + w2 * 0.5;
		str = int(se.Deaths) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = deathcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
	}

	// Draw Streak
	if (se.Streak >= 0)
	{
		gc.GetTextExtent( 0, w2, h, StreakString );
		streakcx = screenWidth * StreakX + w2 * 0.5;
		str = int(se.Streak) $ "";
		gc.GetTextExtent( 0, w2, h, str );
		x = streakcx + (w * 0.5) - w2;
		gc.DrawText( x, yoffset, w2, h, str );
	}
}

simulated function int GetTeamList( DeusExPlayer player, bool Allies )
{
     local int i, numTeamList;

     if ( player == None )
          return(0);

     numTeamList = 0;

     for ( i = 0; i < scorePlayers; i++ )
     {
          if ( (Allies && (scoreArray[i].Team == player.PlayerReplicationInfo.Team) ) ||
                 (!Allies && (scoreArray[i].Team != player.PlayerReplicationInfo.Team) ) )
          {
                    teamSE[numTeamList] = scoreArray[i];
                    PInfo[numTeamList] = PI[i];
                    numTeamList += 1;
          }
     }
     return( numTeamList );
}

defaultproperties
{
     Team0PlayerClass=Class'miniMTLUNATCO'
     Team1PlayerClass=Class'miniMTLNSF'
     ReplacerClass=Class'miniMTLReplacer'
     StreakString="Streak"
     HUDType=Class'miniMTLHUD'
     GameReplicationInfoClass=Class'MMGRI'
}
