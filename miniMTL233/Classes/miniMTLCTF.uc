class miniMTLCTF extends miniMTLTeam;

var() globalconfig class<MMAugmentation> FlagDisabledAugs[17];

var() globalconfig int SkillsPerCapture; //number of skill points you get when you capture the enemy flag
var() globalconfig int SkillsPerScore; //number of skill points you get when you score the enemy flag
var() globalconfig int SkillsPerReturn; //number of skill points you get when you return own flag

var() globalconfig int AugsPerCapture; //number of augs you get when you capture the enemy flag
var() globalconfig int AugsPerScore; //number of augs you get when you score the enemy flag
var() globalconfig int AugsPerReturn; //number of augs you get when you return own flag

var() globalconfig int TeamSkillsPerCapture; //number of skill points team get when you capture the enemy flag
var() globalconfig int TeamSkillsPerScore; //number of skill points team get when you score the enemy flag
var() globalconfig int TeamSkillsPerReturn; //number of skill points team get when you return own flag

var() globalconfig int TeamAugsPerCapture; //number of augs team get when you capture the enemy flag
var() globalconfig int TeamAugsPerScore; //number of augs you get when team score the enemy flag
var() globalconfig int TeamAugsPerReturn; //number of augs team get when you return own flag

//how many seconds are u invisible to the team whos flag u took?
//(invisible as in no flag icon on their HUDs)
var globalconfig int flagEscapeTime;

//allow flag carriers to use augs?
var globalconfig bool bAugsWithFlag;

var float FixedRespawnTime;

var bool bRespawnIntervals;
var float RespawnInterval;
var float RespawnThreshold;

var float NextRespawnTime;

//how many seconds between flag pickups from base will gifts be awarded?
//var float flagScrumTime;

var int PtsPerKill;
var int PtsPerScore;
var int PtsPerCapture;
var int PtsPerReturn;

//the flags (one for each team)
var miniMTLCTFFlag Flags[2];

//bias to give to friendly flag when choosing a spawn point
// (i.e. how many 'teammates' does it represent)
var float friendlyFlagBias;
var float friendlyFlagRandomBias;


// only on client
var int FlagFlashCount;


struct FlagSpawnPoint
{
	var string MapName;
	var Vector Location0;
	var Vector Location1;
};

var FlagSpawnPoint FlagSpawnPoints[7];

replication
{
   //make sure players know about the flags
	reliable if (Role == ROLE_Authority)
   		Flags, FlagDisabledAugs;
}


function Tick(float deltaTime)
{
	if (Role == ROLE_Authority)
	{
		if (bRespawnIntervals)
		{
			NextRespawnTime -= deltaTime;
			if (NextRespawnTime < RespawnThreshold)
			{
				NextRespawnTime += RespawnInterval;
			}
		}
		else NextRespawnTime = FixedRespawnTime;
	}
	super.Tick(deltaTime);
}


function HandleDeathNotification( Pawn killer, Pawn killee )
{
	local bool killedSelf, valid;

	killedSelf = (killer == killee);

	if (( killee != None ) && killee.IsA('miniMTLPlayer'))
	{
		valid = DeusExPlayer(killee).killProfile.bValid;

		if ( killedSelf )
			valid = False;

		miniMTLPlayer(killee).MultiplayerDeathMsgCTF(killer, killedSelf, valid, DeusExPlayer(killee).killProfile.name, DeusExPlayer(killee).killProfile.methodStr, NextRespawnTime);
	}
}

function customizeFlag(miniMTLCTFFlag flag, int flagTextureNum)
{
	switch (flagTextureNum)
	{
		case 0:
		flag.skin = texture'DeusExDeco.Skins.FlagPoleTex5';
		break;
		case 1:
		flag.skin = texture'DeusExDeco.Skins.FlagPoleTex4';
		break;
	}
}


simulated function LocalGetTeamTotalsX(int teamSECnt, out float score, out float deaths, out float streak, DeusExPlayer thisPlayer, int team )
{
	local int i;
	local MMGRI gri;

	score = 0; deaths = -1; streak = -1;
	gri = MMGRI(thisPlayer.GameReplicationInfo);
	if (gri != none) score = gri.Captures[team];
}


function CalcTeamScores()
{
	local MMGRI gri;

	gri = MMGRI(GameReplicationInfo);
	if (gri != none)
	{
		TeamScore[TEAM_NSF] = gri.Captures[1];
		TeamScore[TEAM_UNATCO] = gri.Captures[0];
	}
}


simulated function HUD_CTF_drawFlagTexture(GC gc, float xloc, float yloc)
{
   gc.drawPattern(xloc-5, yloc-5, 10, 7, 0, 0, Texture'Solid');
   gc.drawPattern(xloc-5, yloc, 2, 8, 0, 0, Texture'Solid');
}


simulated function HUD_CTF_drawMiniFlagTexture(GC gc, float xloc, float yloc)
{
   gc.drawPattern(xloc+3, yloc-9, 5, 4, 0, 0, Texture'Solid');
   gc.drawPattern(xloc+3, yloc-9, 1, 7, 0, 0, Texture'Solid');
}


simulated function HUD_CTF_drawCarrierTexture(GC gc, float xloc, float yloc)
{
   gc.drawPattern(xloc-7,yloc,14,2,0,0, texture'solid');
   gc.drawPattern(xloc-1,yloc-6,2,13,0,0, texture'solid');
}


simulated function HUD_CTF_drawHQTexture(GC gc, float xloc, float yloc)
{
    gc.drawPattern(xloc-2, yloc-2, 5, 5, 0, 0, texture'Solid');
}


simulated function HUD_drawText(GC gc, string str, float xloc, float yloc)
{
   local float x, y, w, h;

   gc.setFont(font'FontMenuSmall_DS');
   gc.setStyle(DSTY_Normal);

   gc.getTextExtent(0, w, h, str);
   x = xloc - w/2;
   y = yloc + h;
   gc.drawText(x, y, w, h, str);
}


simulated function HUD_CTF_drawFlag(GC gc, miniMTLCTFFlag flag, miniMTLPlayer player, float xloc, float yloc)
{
   local string str;
   local float x, y, w, h;

   //if being carried, we draw a different image, someone please help me with this :))
   if (flag.isInState('withPlayer'))
   {
      //do a check for escape time (only if flag is on my team)
      if (player.playerReplicationInfo.team == flag.team && flag.bEscaping)
         return; //dont draw is escaping
   
      HUD_CTF_drawMiniFlagTexture(gc, xloc, yloc);

      //assume enemy carrier
      gc.setTileColor(redColor);
      if (flag.team != player.playerReplicationInfo.team)
      {
         //if the carrier is on my team, draw a green cross
         if ((player.IDToPRI(flag.carrierID)).team ==
            player.playerReplicationInfo.team)
         {
            gc.setTileColor(greenColor);
         }
      }
      
      HUD_CTF_drawCarrierTexture(gc, xloc, yloc);
   }
   else
   {
      HUD_CTF_drawFlagTexture(gc, xloc, yloc);
   }

   //if (player.bHUDText && flag.teamString != "")
   if (flag.teamString != "")
      HUD_drawText(gc, flag.teamString $ " " $ flag.flagString, xloc, yloc);
}


simulated function HUD_CTF_drawHQ(GC gc, miniMTLCTFFlag flag, miniMTLPlayer player, float xloc, float yloc)
{
   HUD_CTF_drawHQTexture(gc, xloc, yloc);

   //if (player.bHUDText && flag.teamString != "")
   if (flag.teamString != "")
      HUD_drawText(gc, flag.teamString $ " " $ flag.HQString, xloc, yloc);
}


simulated function HUD_CTF_drawMyFlag(GC gc, float width, float height)
{
	FlagFlashCount++;
	if (FlagFlashCount == 80) FlagFlashCount = 0;

	if (FlagFlashCount < 55)
	{
		gc.SetStyle(DSTY_Masked);
		GC.SetTileColorRGB(255,255,255);
		gc.DrawStretchedTexture(width - 32 - 5, height * 0.8, 32, 32, 0, 0, 64, 64, Texture'CTFItems100.HUD_Flag');
	}
}


simulated function drawHUD(miniMTLPlayer player, GC gc, Window window, float width, float height)
{
   local string str;
   local float x, y, w, h;
   local int i;
   local MMPRI pri;
   local miniMTLCTFFlag f;
   
   pri = MMPRI(Player.PlayerReplicationInfo);
   if (pri != none && pri.Flag != none) HUD_CTF_drawMyFlag(gc, width, height);
   //HUD_CTF_drawMyFlag(gc, width, height);

   // if we are spectator and we want to play
   if (pri != none && pri.bIsSpectator)
   {
		if (Player.bCTFWantsToPlay)
		{
			str = "Starting to play... Wait " $ string(int(Player.CTFRespawnTime - Player.Level.Timeseconds)) $ " seconds.";
			gc.SetTextColorRGB(255, 255, 255);
			gc.SetFont(Font'FontMenuTitle');
			gc.GetTextExtent(0, w, h, str);
			x = (width * 0.5) - (w * 0.5);
			y = height * 0.65;
			gc.DrawText( x, y, w, h, str );
		}
   }
   
   foreach AllActors(class'miniMTLCTFFlag', f)
   {
      if (player.playerReplicationInfo.team == f.team)
         gc.setTileColor(greenColor);
      else
         gc.setTileColor(redColor);
         
      if (!(f.isInState('atBase')))
         if (window.convertVectorToCoordinates(f.baseLoc, x, y))
            HUD_CTF_drawHQ(gc, f, player, x, y);

      if (window.convertVectorToCoordinates(f.location, x, y))
         HUD_CTF_drawFlag(gc, f, player, x, y);
   }
	//for (i=0; i<2; i++)
   //{
   //   if (flags[i] == none) continue;
         
   //   if (player.playerReplicationInfo.team == flags[i].team)
   //      gc.setTileColor(greenColor);
   //   else
   //      gc.setTileColor(redColor);
         
   //   if (!(flags[i].isInState('atBase')))
   //      if (window.convertVectorToCoordinates(flags[i].baseLoc, x, y))
   //         HUD_CTF_drawHQ(gc, flags[i], player, x, y);

   //   if (window.convertVectorToCoordinates(flags[i].location, x, y))
   //      HUD_CTF_drawFlag(gc, flags[i], player, x, y);
   //}
}


event InitGame(string Options, out string Error)
{
    super.InitGame(Options, Error);
	
	// spawn flags
	if (level.netMode != NM_Standalone)
      initFlags();

	if (bRespawnIntervals) NextRespawnTime = RespawnInterval;
	else NextRespawnTime = FixedRespawnTime;
}


function initFlags()
{
   local int i, k;
   local NavigationPoint point;
   local SpawnPoint flagSpawn;
   local string str, map;

   log("Initializing CTF flags...", 'MiniMTL');


   //check for 'flagStarts' (the new way we do it)
   foreach AllActors(class'SpawnPoint', flagSpawn)
   {
		if (flagSpawn.Tag == 'CTFFLAG')
		{
			if (flagSpawn.ownerTeam == '0')
				Flags[0] = spawnFlag(0, flagSpawn.Location);
			else if (flagSpawn.ownerTeam == '1')
				Flags[1] = spawnFlag(1, flagSpawn.Location);
		}
   }
               
   //now customize the flags
   for (i=0; i<2; i++)
   {
		if (Flags[i] == none)
		{
			str = string(self);
			map = Left(str, InStr(str, "."));

			for (k = 0; k < arrayCount(FlagSpawnPoints); k++)
			{
				if (FlagSpawnPoints[k].MapName ~= map)
				{
					if (i == 0) Flags[i] = spawnFlag(i, FlagSpawnPoints[k].Location0);
					else Flags[i] = spawnFlag(i, FlagSpawnPoints[k].Location1);
					break;
				}
			}
			if (Flags[i] == none)
			{
				log("ERROR: Not enough flag spawn points set!", 'MiniMTL');
				assert(false);
			}
		}
		if (i == 0) flags[i].teamString = "UNATCO";
		else flags[i].teamString = "NSF";
		flags[i].escapeTime = flagEscapeTime;
		customizeFlag(flags[i], i);
		flags[i].refreshItemName();
		log(sprintf("CTF: %s = %s", flags[i], flags[i].itemName), 'MiniMTL');
   }
}


function miniMTLCTFFlag spawnFlag(int team, vector location)
{
   local miniMTLCTFFlag flag;

   flag = spawn(class'miniMTLCTFFlag',,, location);
   if (flag != none)
   {
      //set the team anyway (even if it was done by default)
      flag.team = team;
      log(sprintf("CTF: Flag spawned %s at %s for team %i", flag, flag.location, team), 'MiniMTL');
   }
   else log(sprintf("CTF: Failed to spawn flag at %s for team %i", location, team), 'MiniMTL');
      
   return flag;
}


function float distanceCost(float dist)
{
   local float cost;

   if (dist < 200)
      cost = 300;
   else if (dist < 400)
       cost = 250;
   else if (dist < 800)
      cost = 175;
   else if (dist < 1600)
      cost = 100;
   else if (dist < 3200)
      cost = 25;
   else
      cost = 0;

   return cost;
}


function float EvaluatePlayerStart(Pawn player, PlayerStart pointToEvaluate, optional byte inTeam)
{
   local miniMTLCTFFlag flag;
   //the bias we give to a nearby friendly flag
   local float friendlyFlagBonus, bestFriendlyFlagBonus;
   local float dist;
   local int team;
   local Pawn CurPawn;
   local DeusExPlayer OtherPlayer;

   bestFriendlyFlagBonus = 0;
   
   if (player == none)
      team = inTeam;
   else if (player.playerReplicationInfo == none)
      team = inTeam;
   else
      team = player.playerReplicationInfo.team;

   // check so we do not spawn on another player & kill him
   for (CurPawn = Level.PawnList; CurPawn != None; CurPawn = CurPawn.NextPawn)
   {
      OtherPlayer = DeusExPlayer(CurPawn);
      if ((OtherPlayer != None) && (OtherPlayer != Player))
      {
		 //Get Dist
         dist = VSize(OtherPlayer.Location - PointToEvaluate.Location);
		 if (Dist < 75.0) return -100000;
      }
   }
   
   //evaluate our distance from enemy flag BASE locations (not the flag)
   foreach allActors(class'miniMTLCTFFlag', flag)
   {
      //if this player is NOT on the team of the flag
      if (team != flag.team)
         //would the player be too close??
         if (vsize(flag.baseLoc - pointToEvaluate.location) < 1500.0)
            return -100000; //don't spawn me here!

      //friendly flag! bias us towards it
      if (team == flag.team)
      {
         dist = vsize(flag.baseLoc - pointToEvaluate.location);
         friendlyFlagBonus = distanceCost(dist);
         if (friendlyFlagBonus > bestFriendlyFlagBonus)
            bestFriendlyFlagBonus = friendlyFlagBonus;
      }

   }
   

   //we dont even bother considering enemies now - ALWAYS spawn nearish flag
   return bestFriendlyFlagBonus * (friendlyFlagBias + frand() *
         friendlyFlagRandomBias);
}


function flagCapture(miniMTLCTFFlag flag, miniMTLPlayer player)
{
   local MMPRI pri;
   local MMGRI gri;
   local Pawn P;

   //count the capture (so he/she cant swap team and take cap with em lol)
   gri = MMGRI(gameReplicationInfo);
   if (gri != none) gri.Captures[player.PlayerReplicationInfo.team]++;

    CTFReward(player, SkillsPerScore, AugsPerScore, PtsPerScore);
    if (TeamSkillsPerScore > 0) CTFRewardTeamSkills(player.PlayerReplicationInfo.Team, TeamSkillsPerScore);
	if (TeamAugsPerScore > 0) CTFRewardTeamAugs(player.PlayerReplicationInfo.Team, TeamAugsPerScore);

   //check for end of game
   if (CheckVictoryConditions(player, none, flag.itemName))
       bFreezeScores = True;
}


function flagTake(miniMTLCTFFlag flag, miniMTLPlayer player, bool bFromBase)
{
   //if (!bAugsWithFlag)
   if (bFromBase || flag.bEscaping || !bAugsWithFlag)
   {
	//player.AugmentationSystem.DeactivateAll();
	  if (MMAugmentationManager(Player.AugmentationSystem) != none)
	  {
		MMAugmentationManager(Player.AugmentationSystem).DeactivateCTFAugs();
	  }
   }	
   if (bFromBase)
   {
		CTFReward(player, SkillsPerCapture, AugsPerCapture, PtsPerCapture);
		if (TeamSkillsPerCapture > 0) CTFRewardTeamSkills(player.PlayerReplicationInfo.Team, TeamSkillsPerCapture);
		if (TeamAugsPerCapture > 0) CTFRewardTeamAugs(player.PlayerReplicationInfo.Team, TeamAugsPerCapture);
   }
}


function flagReturn(miniMTLCTFFlag flag, miniMTLPlayer player)
{
   CTFReward(player, SkillsPerReturn, AugsPerReturn, PtsPerReturn);
	if (TeamSkillsPerReturn > 0) CTFRewardTeamSkills(player.PlayerReplicationInfo.Team, TeamSkillsPerReturn);
	if (TeamAugsPerReturn > 0) CTFRewardTeamAugs(player.PlayerReplicationInfo.Team, TeamAugsPerReturn);
}


function flagDrop(miniMTLCTFFlag flag, miniMTLPlayer player, bool bOnPurpose)
{
   return;
}


function CTFReward(DeusExPlayer PlayerToReward, int skills, int augs, int pts)
{
	if (PlayerToReward != None)
	{
		if (skills > 0) PlayerToReward.SkillPointsAdd(skills);
		if (augs > 0) PlayerToReward.GrantAugs(augs);
		PlayerToReward.PlayerReplicationInfo.Score += pts;
		PlayerToReward.PlayerReplicationInfo.Streak += pts;
	}
}


function CTFRewardTeamSkills(int team, int skills)
{
	local DeusExPlayer dxp;
	local Pawn p;
	local MMPRI pri;
	
	p = Level.PawnList;
	while (p != none)
	{
		dxp = DeusExPlayer(p);
		if (dxp != none)
		{
			pri = MMPRI(dxp.PlayerReplicationInfo);
			if (pri != none && pri.Team == team && !pri.bIsSpectator && !pri.bDead)
				dxp.SkillPointsAdd(skills);
		}
		p = p.NextPawn;
	}
}


function CTFRewardTeamAugs(int team, int augs)
{
	local DeusExPlayer dxp;
	local Pawn p;
	local MMPRI pri;
	
	p = Level.PawnList;
	while (p != none)
	{
		dxp = DeusExPlayer(p);
		if (dxp != none)
		{
			pri = MMPRI(dxp.PlayerReplicationInfo);
			if (pri != none && pri.Team == team && !pri.bIsSpectator && !pri.bDead)
				dxp.GrantAugs(augs);
		}
		p = p.NextPawn;
	}
}


function Killed( pawn Killer, pawn Other, name damageType )
{
	local bool NotifyDeath;
	local DeusExPlayer otherPlayer;
	local Pawn CurPawn;
	local MMPRI pri;

   if ( bFreezeScores )
      return;

	NotifyDeath = False;

	// Record the death no matter what, and reset the streak counter
	if ( Other.bIsPlayer )
	{
		otherPlayer = DeusExPlayer(Other);

		pri = MMPRI(otherPlayer.PlayerReplicationInfo);
		if (pri != none) pri.bDead = true;

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
		else if ( Killer != Other)
			BroadcastMessage(Killer.PlayerReplicationInfo.PlayerName$" killed "$Other.PlayerReplicationInfo.PlayerName $ otherPlayer.killProfile.methodStr, false, 'DeathMessage');

		if (Killer != Other)
		{
			// Penalize for killing your teammates
			if (ArePlayersAllied(DeusExPlayer(Other),DeusExPlayer(Killer)))
			{
				if ( Killer.PlayerReplicationInfo.Score > 0 )
					Killer.PlayerReplicationInfo.Score -= PtsPerKill;
				DeusExPlayer(Killer).MultiplayerNotifyMsg( DeusExPlayer(Killer).MPMSG_KilledTeammate, 0, "" );
			}
			else
			{
				// Grant the kill to the killer, and increase his streak
				Killer.PlayerReplicationInfo.Score += PtsPerKill;
				Killer.PlayerReplicationInfo.Streak += PtsPerKill;

				Reward(Killer);
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

defaultproperties
{
    FlagDisabledAugs(0)=Class'MMAugSpeed'
    FlagDisabledAugs(1)=Class'MMAugCloak'
    FlagDisabledAugs(2)=Class'MMAugDefense'
    FlagDisabledAugs(3)=Class'MMAugAqualung'
    AugsPerCapture=1
    AugsPerScore=2
    AugsPerReturn=1
    flagEscapeTime=30
    FixedRespawnTime=10.00
    bRespawnIntervals=True
    RespawnInterval=8.00
    RespawnThreshold=6.00
    PtsPerKill=1
    PtsPerScore=10
    PtsPerCapture=2
    PtsPerReturn=2
    friendlyFlagBias=1.00
    friendlyFlagRandomBias=10.00
    FlagSpawnPoints(0)=(MapName="DXMP_Smuggler",Location0=(X=-724.07,Y=17.84,Z=-16.90),,Location1=(X=1819.08,Y=1666.54,Z=-144.90),),
    FlagSpawnPoints(1)=(MapName="DXMP_Area51Bunker",Location0=(X=-1554.33,Y=3170.65,Z=400.10),,Location1=(X=770.20,Y=-1665.88,Z=-512.90),),
    FlagSpawnPoints(2)=(MapName="DXMP_Silo",Location0=(X=1649.73,Y=-2575.41,Z=1457.10),,Location1=(X=-1727.36,Y=-5728.13,Z=1629.11),),
    FlagSpawnPoints(3)=(MapName="DXMP_Cmd",Location0=(X=763.23,Y=1723.05,Z=-2064.90),,Location1=(X=-418.00,Y=4882.98,Z=-2122.88),),
    FlagSpawnPoints(4)=(MapName="DXMP_Cathedral_GOTY",Location0=(X=1694.11,Y=-1887.49,Z=-368.90),,Location1=(X=3259.80,Y=-107.45,Z=-16.90),),
    FlagSpawnPoints(5)=(MapName="DXMP_Paris_Cathedral",Location0=(X=1694.11,Y=-1887.49,Z=-368.90),,Location1=(X=3259.80,Y=-107.45,Z=-16.90),),
    FlagSpawnPoints(6)=(MapName="DXMP_Cathedral",Location0=(X=1694.11,Y=-1887.49,Z=-368.90),,Location1=(X=3259.80,Y=-107.45,Z=-16.90),),
    VictoryConString2=" captures wins the match."
    TimeLimitString1="Objective: Score the most captures before the clock ( "
    StreakString="Power"
    KillsString="Score"
    MatchEnd2String=" capturing the"
}
