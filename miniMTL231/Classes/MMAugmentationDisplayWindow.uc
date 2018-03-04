class MMAugmentationDisplayWindow extends CBPAugmentationDisplayWindow;

var string keyFreeMode, keyPersonView, keyMainMenu, keySkills;

const	skillListX	= 0.01;				// Screen multiplier
const skillListY	= 0.38;
const skillMsgY	= 0.7;
const	skillCostX	= 0.25;
const skillLevelX	= 0.19;
const levelBoxSize = 5;


var Color	colBlue1, colWhite;
var Color	colGreen1, colLtGreen;
var Color	colRed1, colLtRed;


function miniMTLPlayer getPlayer()
{
   return miniMTLPlayer(player);
}


function RefreshMultiplayerKeys()
{
	local String Alias, keyName;
	local int i;

	for ( i = 0; i < 255; i++ )
	{
		keyName = player.ConsoleCommand ( "KEYNAME "$i );
		if ( keyName != "" )
		{
			Alias = player.ConsoleCommand( "KEYBINDING "$keyName );
			if ( Alias ~= "DropItem" )
				keyDropItem = keyName;
			else if ( Alias ~= "Talk" )
				keyTalk = keyName;
			else if ( Alias ~= "TeamTalk" )
				keyTeamTalk = keyName;
			else if ( Alias ~= "ShowInventoryWindow" )
			    keyFreeMode = keyName;
            else if ( Alias ~= "ShowGoalsWindow" )
                keyPersonView = keyName;
            else if ( Alias ~= "ShowMainMenu" )
                keyMainMenu = keyName;
			else if ( Alias ~= "BuySkills" )
				keySkills = KeyName;;
		}
	}
	if ( keyDropItem ~= "" )
		keyDropItem = KeyNotBoundString;
	if ( keyTalk ~= "" )
		keyTalk = KeyNotBoundString;
	if ( keyTeamTalk ~= "" )
		keyTeamTalk = KeyNotBoundString;
	if ( keyFreeMode ~= "" )
	    keyFreeMode = KeyNotBoundString;
    if ( keyPersonView ~= "" )
        keyPersonView = KeyNotBoundString;
    if ( keyMainMenu ~= "" )
        keyMainMenu = KeyNotBoundString;
	if ( keySkills ~= "" )
		keySkills = KeyNotBoundString;
}


function float FacingActor(Pawn A, Pawn B)
{
    local vector X,Y,Z, Dir;

    if (B == None || A == None) return -1.0;
    GetAxes(B.ViewRotation, X, Y, Z);
    Dir = A.Location - B.Location;
    X.Z = 0;
    Dir.Z = 0;
    return Normal(Dir) dot Normal(X);
}


function NameAllViewedPlayers(GC gc, miniMTLPlayer mmp)
{
    local Actor target;
	local miniMTLPlayer P;
	local float x, y;
	local vector loc;
	local bool viewenemy;

	foreach mmp.VisibleCollidingActors(class'Actor', target, 3000.0, mmp.Location, false)
	{
	    if (target.IsA('miniMTLPlayer') && (FacingActor(Pawn(target), mmp) > 0.0))
        {
            P = miniMTLPlayer(target);
            if (P.PlayerReplicationInfo.bIsSpectator || (!mmp.bSpecEnemies && P.PlayerReplicationInfo.Team != mmp.PlayerReplicationInfo.Team)) continue;
            loc = P.Location;
            loc.Z -= P.CollisionHeight + 10.0;
            ConvertVectorToCoordinates(loc, x, y);
            DrawPlayerName(gc, x, y, (mmp.PlayerReplicationInfo.Team == P.PlayerReplicationInfo.Team) && mmp.GameReplicationInfo.bTeamGame, P.PlayerReplicationInfo.PlayerName);
        }
    }
}


function DrawPlayerName(GC gc, float x, float y, bool sameteam, string pname)
{
    local float w, h;

    gc.SetFont(Font'FontMenuSmall');
    gc.SetStyle(DSTY_Translucent);
    if (sameteam) gc.SetTextColor(colGreen);
    else gc.SetTextColor(colRed);
    gc.GetTextExtent(0, w, h, pname);
    x -= w * 0.5;
    y -= h * 0.5;
	gc.DrawText(x, y, w, h, pname);
	gc.SetStyle(DSTY_Normal);
}


function DrawLevel( GC gc, float x, float y, int level )
{
	local int i;

	if (( level < 0 ) || (level > 3 ))
	{
		log("Warning:Bad skill level:"$level$" " );
		return;
	}
	for ( i = 0; i < level; i++ )
	{
		gc.DrawTexture( x, y+2.0, levelBoxSize, levelBoxSize, 0, 0, Texture'Solid');
		x += (levelBoxSize + levelBoxSize/2);
	}
}


function DrawRemotePlayerSkills(GC gc, miniMTLPlayer P)
{
	local float curx, cury, w, h;
	local String str, costStr;
	local int i;
	local float barLen, costx, levelx;
	local class<Skill> skillclass;
	local int level, cost;

    gc.SetTileColor(colWhite);
    gc.SetTextColor(colLtGreen);
    gc.SetFont(Font'FontMenuSmall_DS');

    if (!P.bBuySkills)
    {
        str = class'HUDMultiSkills'.default.PressString $ keySkills $ class'HUDMultiSkills'.default.PressEndString $ " to show skills.";
        cury = height * skillMsgY;
		curx = width * skillListX;
		gc.GetTextExtent(0, w, h, str);
		gc.DrawText(curx, cury, w, h, str);
        return;
    }

	cury = height * skillListY;
	curx = width * skillListX;
	costx = width * skillCostX;
	levelx = width * skillLevelX;
	gc.GetTextExtent( 0, w, h, class'HUDMultiSkills'.default.CostString);
	barLen = (costx+(w*1.33))-curx;
	gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
	cury += (h*0.25);

	str = class'HUDMultiSkills'.default.SkillPointsString $ P.TargetSkillsAvail;
	gc.GetTextExtent( 0, w, h, str );
	gc.DrawText( curx, cury, w, h, str );
	cury += h;

	gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
	cury += (h*0.25);

	str = class'HUDMultiSkills'.default.SkillString;
	gc.GetTextExtent( 0, w, h, str );
	gc.DrawText( curx, cury, w, h, str );

	str = class'HUDMultiSkills'.default.LevelString;
	gc.GetTextExtent( 0, w, h, str );
	gc.DrawText( levelx, cury, w, h, str );

	str = class'HUDMultiSkills'.default.CostString;
	gc.GetTextExtent( 0, w, h, str );
	gc.DrawText( costx, cury, w, h, str );

    cury += h;
	gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
	cury += (h*0.25);

    for (i = 0; i < 10; i++)
    {
        level = 1;
        if ((P.TargetSkills & (0x40000000 >> i)) == (0x40000000 >> i)) level = 3;
        else if ((P.TargetSkills & (1 << i)) == (1 << i)) level = 2;

        if (i <= 3) cost = 2000;
        else cost = 1000;

        skillclass = class'CBPSkillManager'.default.skillClasses[i];
        str = string(int((i + 1) % 10)) $ ". " $ skillclass.default.SkillName;
        gc.GetTextExtent( 0, w, h, str );
        if (level == 3)
        {
		    gc.SetTileColor(colBlue1);
			gc.SetTextColor(colBlue1);
			costStr = class'HUDMultiSkills'.default.NAString;
        }
        else if (P.TargetSkillsAvail >= cost)
        {
			if (level == 2)
        	{
				gc.SetTextColor(colLtGreen);
				gc.SetTileColor(colLtGreen);
			}
			else
			{
				gc.SetTextColor(colGreen1);
				gc.SetTileColor(colGreen1);
			}
			costStr = "" $ cost;
        }
		else
		{
			if (level == 2)
			{
			    gc.SetTileColor(colLtRed);
			    gc.SetTextColor(colLtRed);
			}
			else
			{
				gc.SetTileColor(colRed1);
				gc.SetTextColor(colRed1);
			}
			costStr = "" $ cost;
		}
		gc.DrawText( curx, cury, w, h, str );
		DrawLevel(gc, levelx, cury, level );
		gc.GetTextExtent(	0, w, h, costStr );
		gc.DrawText( costx, cury, w, h, costStr );
		cury += h;
    }

    gc.SetTileColor( colWhite );

    str = class'HUDMultiSkills'.default.PressString $ keySkills $ class'HUDMultiSkills'.default.ToExitString;
    gc.GetTextExtent( 0, w, h, str );
    gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
    cury += (h*0.25);

    gc.SetTextColor( colWhite );
    gc.DrawText( curx + ((barLen*0.5)-(w*0.5)), cury, w, h, str );
    cury += h;
    gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
}


function bool IsHeatSourceSpec(Actor A, miniMTLPlayer mmp)
{
   if ((A.bHidden) && (miniMTLPlayer(A) == none || !miniMTLPlayer(A).bBlockActors))
      return False;
   if (A.IsA('Pawn'))
   {
      if (A.IsA('ScriptedPawn'))
         return True;
      else if ( (A.IsA('DeusExPlayer')) && (A != mmp.ViewTarget) && (A != player) )
         return True;
      return False;
   }
	else if (A.IsA('DeusExCarcass'))
		return True;
	else if (A.IsA('FleshFragment'))
		return True;
   else
		return False;
}


function int GetVisionTargetStatusSpec(Actor Target, miniMTLPlayer mmp)
{
   local DeusExPlayer PlayerTarget;
   local TeamDMGame TeamGame;

   if (Target == None)
      return VISIONNEUTRAL;

   if (player.Level.NetMode == NM_Standalone)
      return VISIONNEUTRAL;

   if (target.IsA('DeusExPlayer'))
   {
      if (target == mmp.ViewTarget)
         return VISIONNEUTRAL;

      TeamGame = TeamDMGame(player.DXGame);
      // In deathmatch, all players are hostile.
      if (TeamGame == None)
         return VISIONENEMY;

      PlayerTarget = DeusExPlayer(Target);

      if (TeamGame.ArePlayersAllied(PlayerTarget, DeusExPlayer(mmp.ViewTarget)))
         return VISIONALLY;
      else
         return VISIONENEMY;
   }
   else if ( (target.IsA('AutoTurretGun')) || (target.IsA('AutoTurret')) )
   {
      if (target.IsA('AutoTurretGun'))
         return GetVisionTargetStatusSpec(target.Owner, mmp);
      else if ((AutoTurret(Target).bDisabled))
         return VISIONNEUTRAL;
      else if (AutoTurret(Target).safetarget == Pawn(mmp.ViewTarget))
         return VISIONALLY;
      else if ((Player.DXGame.IsA('TeamDMGame')) && (AutoTurret(Target).team == -1))
         return VISIONNEUTRAL;
      else if ( (!Player.DXGame.IsA('TeamDMGame')) || (Pawn(mmp.ViewTarget).PlayerReplicationInfo.Team != AutoTurret(Target).team) )
          return VISIONENEMY;
      else if (Pawn(mmp.ViewTarget).PlayerReplicationInfo.Team == AutoTurret(Target).team)
         return VISIONALLY;
      else
         return VISIONNEUTRAL;
   }
   else if (target.IsA('SecurityCamera'))
   {
      if ( !SecurityCamera(target).bActive )
         return VISIONNEUTRAL;
      else if ( SecurityCamera(target).team == -1 )
         return VISIONNEUTRAL;
      else if (((Player.DXGame.IsA('TeamDMGame')) && (SecurityCamera(target).team==Pawn(mmp.ViewTarget).PlayerReplicationInfo.team)) ||
         ( (Player.DXGame.IsA('DeathMatchGame')) && (SecurityCamera(target).team==Pawn(mmp.ViewTarget).PlayerReplicationInfo.PlayerID)))
         return VISIONALLY;
      else
         return VISIONENEMY;
   }
   else
      return VISIONNEUTRAL;
}


function DrawVisionAugmentationSpec(GC gc, miniMTLPlayer mmp)
{
	local Vector loc;
	local float dist;
   local float BrightDot;
	local Actor A;
   local float DrawGlow;
   local float RadianView;
   local float OldFlash, NewFlash;
   local vector OldFog, NewFog;
	local Texture oldSkins[9];

	if (visionLevel >= 1)
	{
         gc.SetStyle(DSTY_Modulated);
         gc.DrawPattern(0, 0, width, height, 0, 0, Texture'VisionBlue');
         gc.DrawPattern(0, 0, width, height, 0, 0, Texture'VisionBlue');
         gc.SetStyle(DSTY_Translucent);

		// adjust for the player's eye height
		loc = mmp.ViewTarget.Location;
		loc.Z += Pawn(mmp.ViewTarget).BaseEyeHeight;

      foreach Player.AllActors(class'Actor', A)
      {
         if (A.bVisionImportant)
         {
            if (IsHeatSourceSpec(A, mmp) || ( (Player.Level.Netmode != NM_Standalone) && ((A.IsA('AutoTurret')) || (A.IsA('AutoTurretGun')) || (A.IsA('SecurityCamera')) ) ))
            {
               dist = VSize(A.Location - loc);
               //If within range of vision aug bit
               if ( ( ((Player.Level.Netmode != NM_Standalone) && (dist <= (visionLevelvalue / 2))) ||
                      ((Player.Level.Netmode == NM_Standalone) && (dist <= (visionLevelValue)))        ) && (IsHeatSourceSpec(A, mmp)))
               {
                  VisionTargetStatus = GetVisionTargetStatusSpec(A, mmp);
                  SetSkins(A, oldSkins);
                  gc.DrawActor(A, False, False, True, 1.0, 2.0, None);
                  ResetSkins(A, oldSkins);
               }
               else if ((Player.Level.Netmode != NM_Standalone) && (GetVisionTargetStatusSpec(A, mmp) == VISIONENEMY) && (A.Style == STY_Translucent))
               {
                  if ( (dist <= (visionLevelvalue)) && (Pawn(mmp.ViewTarget).LineOfSightTo(A,true)) )
                  {
                     VisionTargetStatus = GetVisionTargetStatusSpec(A, mmp);
                     SetSkins(A, oldSkins);
                     gc.DrawActor(A, False, False, True, 1.0, 2.0, None);
                     ResetSkins(A, oldSkins);
                  }
               }
               else if (Pawn(mmp.ViewTarget).LineOfSightTo(A,true))
               {
                  VisionTargetStatus = GetVisionTargetStatusSpec(A, mmp);
                  SetSkins(A, oldSkins);

                  if ((Player.Level.NetMode == NM_Standalone) || (dist < VisionLevelValue * 1.5) || (VisionTargetStatus != VISIONENEMY))
                  {
                     DrawGlow = 2.0;
                  }
                  else
                  {
                     // Fadeoff with distance square
                     DrawGlow = 2.0 / ((dist / (VisionLevelValue * 1.5)) * (dist / (VisionLevelValue * 1.5)));
                     DrawGlow = FMax(DrawGlow,0.15);
                  }
                  gc.DrawActor(A, False, False, True, 1.0, DrawGlow, None);
                  ResetSkins(A, oldSkins);
               }
            }
            else if ( (A != VisionBlinder) && (Player.Level.NetMode != NM_Standalone) && (A.IsA('ExplosionLight')) && (Pawn(mmp.ViewTarget).LineOfSightTo(A,True)) )
            {
               BrightDot = Normal(Vector(Pawn(mmp.ViewTarget).ViewRotation)) dot Normal(A.Location - Pawn(mmp.ViewTarget).Location);
               dist = VSize(A.Location - Pawn(mmp.ViewTarget).Location);

               if (dist > 3000)
                  DrawGlow = 0;
               else if (dist < 300)
                  DrawGlow = 1;
               else
                  DrawGlow = ( 3000 - dist ) / ( 3000 - 300 );

               // Calculate view angle in radians.
               RadianView = (Player.FovAngle / 180) * 3.141593;

               if ((BrightDot >= Cos(RadianView)) && (DrawGlow > 0.2) && (BrightDot * DrawGlow * 0.9 > 0.2))  //DEUS_EX AMSD .75 is approximately at our view angle edge.
               {
                  VisionBlinder = A;
                  NewFlash = 10.0 * BrightDot * DrawGlow;
                  NewFog = vect(1000,1000,900) * BrightDot * DrawGlow * 0.9;
                  OldFlash = player.DesiredFlashScale;
                  OldFog = player.DesiredFlashFog * 1000;

                  // Don't add increase the player's flash above the current newflash.
                  NewFlash = FMax(0,NewFlash - OldFlash);
                  NewFog.X = FMax(0,NewFog.X - OldFog.X);
                  NewFog.Y = FMax(0,NewFog.Y - OldFog.Y);
                  NewFog.Z = FMax(0,NewFog.Z - OldFog.Z);
                  player.ClientFlash(NewFlash,NewFog);
                  player.IncreaseClientFlashLength(4.0*BrightDot*DrawGlow*BrightDot);
               }
            }
         }
      }
	}

   gc.SetStyle(DSTY_Normal);
}

function DrawRemoteInventory(GC gc, miniMTLPlayer mmp)
{
	local int xoff, yoff, ytoff, i;

	yoff = height - 48;
	ytoff = yoff + 32;
	xoff = width - 54;

	gc.SetStyle(DSTY_Masked);
	gc.SetTileColorRGB(255, 255, 255);

	gc.SetAlignments(HALIGN_Center, VALIGN_Center);
	gc.EnableWordWrap(false);
	gc.SetTextColorRGB(255, 255, 255);
	gc.SetFont(Font'FontTiny');

	// draw biocells
	if (mmp.TargetBioCells > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconBioCell');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetBioCells);
	}
	xoff -= 48;
	// draw medkit
	if (mmp.TargetMedkits > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconMedKit');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetMedkits);	
	}
	xoff -= 48;
	// draw multitool
	if (mmp.TargetMultitools > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconMultitool');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetMultitools);
	}
	xoff -= 48;
	// draw lockpick
	if (mmp.TargetLockpicks > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconLockPick');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetLockpicks);
	}
	xoff -= 48;
	// draw lam
	if (mmp.TargetLAMs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconLAM');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetLAMs);
	}

	xoff = 16;

	// draw weapons
	for (i = 0; i < 3; i++)
	{
		if (mmp.TargetWeapons[i] != none)
		{
			gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, mmp.TargetWeapons[i].default.Icon);
		}
		xoff += 48;
	}

	// draw emp
	if (mmp.TargetEMPs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconEMPGrenade');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetEMPs);
	}
	xoff += 48;
	// draw gas
	if (mmp.TargetGGs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconGasGrenade');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetGGs);
	}
}

function PostDrawWindow(GC gc)
{
	local PlayerPawn pp;
	local miniMTLPlayer mmp;
	local color col;
	local string str;
	local color colGold;
	local int tmpVisionLevel, tmpVisionLevelValue;

	pp = Player.GetPlayerPawn();
	mmp = miniMTLPlayer(pp);
	if (mmp == none) return;
	if (mmp.PlayerReplicationInfo == none) return;
    if (!mmp.PlayerReplicationInfo.bIsSpectator) 
    {
    	super(AugmentationDisplayWindow).PostDrawWindow(gc);
    }
    else
    {
		if (!mmp.FreeSpecMode && mmp.ViewTarget != none && !mmp.bBehindView &&
			(mmp.TargetAugs & (0x40000000 >> class'MMAugVision'.default.MPConflictSlot)) == (0x40000000 >> class'MMAugVision'.default.MPConflictSlot) &&
			(mmp.TargetAugs & (1 << class'MMAugVision'.default.ManagerIndex)) == (1 << class'MMAugVision'.default.ManagerIndex))
		{
			tmpVisionLevel = visionLevel;
			tmpVisionLevelValue = visionLevelValue;
			visionLevel = 3;
			visionLevelValue = MMAugmentationManager(mmp.AugmentationSystem).GetAugLevelValueWithIgnoredState(class'MMAugVision');
			DrawVisionAugmentationSpec(gc, mmp);
			visionLevel = tmpVisionLevel;
			visionLevelValue = tmpVisionLevelValue;
		}

        colGold.R = 255;
        colGold.G = 255;

        if (mmp.FreeSpecMode)
        {
            NameAllViewedPlayers(gc, mmp);
            DrawStaticText(gc, "Free spectator mode.", 0.93, colGold, false);
            DrawStaticText(gc, "Press <" $ keyFreeMode $ "> to spectate players.", 0.95, colGold, false);
        }
        else if (mmp.ViewTarget != none)
        {
            if (PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo.Team != mmp.PlayerReplicationInfo.Team ||
            	!mmp.GameReplicationInfo.bTeamGame) col = colRed;
            else col = colGreen;
            str = "Spectating: " $ PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo.PlayerName;
            if (!mmp.bTargetAlive || 
            	(MMPRI(PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo) != none && MMPRI(PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo).bDead)) 
            	str = str $ " (dead)";
            DrawStaticText(gc, str, 0.85, col, true);
            DrawStaticText(gc, "Press <FIRE> to spectate next player.", 0.89, colGold, false);
            if (mmp.bBehindView) DrawStaticText(gc, "Press <" $ keyPersonView $ "> for 1st person view.", 0.93, colGold, false);
            else
            {
                DrawRemotePlayerSkills(gc, mmp);
				DrawRemoteInventory(gc, mmp);
                DrawStaticText(gc, "Press <" $ keyPersonView $ "> for 3rd person view.", 0.93, colGold, false);
            }
            DrawStaticText(gc, "Press <" $ keyFreeMode $ "> to go into free spectator mode.", 0.95, colGold, false);
        }

	    DrawStaticText(gc, "Press <" $ keyMainMenu $ "> to start playing.", 0.97, colGold, false);

        gc.SetFont(Font'FontMenuSmall_DS');
	    gc.SetTextColor(colHeaderText);
	    gc.SetStyle(DSTY_Normal);
	    gc.SetTileColor(colBorder);

        if (mmp.bShowScores)
	    {
            if (DeathMatchGame(mmp.DXGame) != None)
			    DeathMatchGame(mmp.DXGame).ShowDMScoreboard(mmp, gc, width, height);
		    else if (TeamDMGame(mmp.DXGame) != None)
			    TeamDMGame(mmp.DXGame).ShowTeamDMScoreboard(mmp, gc, width, height);
	    }
	}

	if (getPlayer().GetCTFGame() != none)
	{
		getPlayer().getCTFGame().drawHUD(getPlayer(), gc, self, width, height);
	}

    if (Player.Level.NetMode != NM_Standalone)
    {
        if (!mmp.bShowScores)
        {
            DrawNotificationText(gc, mmp);
        }
    }
}


function DrawStaticText(GC gc, string text, float y_ratio, color col, bool big)
{
    local float x, y, w, h;

    if (big) gc.SetFont(Font'FontMenuTitle');
    else gc.SetFont(Font'FontMenuSmall');
    gc.SetStyle(DSTY_Translucent);
    gc.SetTextColor(col);
    gc.GetTextExtent(0, w, h, text);
    x = (width * 0.5) - (w * 0.5);
	y = height * y_ratio;
	gc.DrawText(x, y, w, h, text);
	gc.SetStyle(DSTY_Normal);
}


function DrawNotificationText(GC gc, miniMTLPlayer mmp)
{
	local float mul, x, y, w, h;
	local color adj;

    mul = FClamp((mmp.notfMSG_EndTime - Player.Level.Timeseconds) / mmp.notfMSG_Time, 0.0, 1.0);
    EnableTranslucentText(True);
	gc.SetFont(Font'FontMenuTitle');
	gc.SetStyle(DSTY_Translucent);
	adj.r = mul * mmp.notfMSG_Color.r;
	adj.g = mul * mmp.notfMSG_Color.g;
	adj.b = mul * mmp.notfMSG_Color.b;
	gc.SetTextColor(adj);
	gc.GetTextExtent(0, w, h, mmp.notfMSG_Text);
	x = (width * 0.5) - (w * 0.5);
	y = height * 0.75;
	gc.DrawText(x, y, w, h, mmp.notfMSG_Text);
	gc.SetStyle(DSTY_Normal);
	EnableTranslucentText(False);
}

function GetTargetReticleColor2( Actor target, out Color xcolor, out Color col )
{
	local DeusExPlayer safePlayer;
	local AutoTurret turret;
	local bool bDM, bTeamDM;
	local Vector dist;
	local float SightDist;
	local DeusExWeapon w;
	local int team;
	local String titleString;
	local bool bdiff;

	if (Player == none || Player.PlayerReplicationInfo == none) return;

	if (target.IsA('DeusExPlayer') && DeusExPlayer(target).PlayerReplicationInfo == none) return;

	bDM = (DeathMatchGame(player.DXGame) != None);
	bTeamDM = (TeamDMGame(player.DXGame) != None);

	if ( target.IsA('DeusExPlayer') && (target != player) )	// Other players IFF
	{
		if ( bTeamDM && (TeamDMGame(player.DXGame).ArePlayersAllied(DeusExPlayer(target),player)) )
		{ 
			xcolor = colGreen;
			if ( (Player.mpMsgFlags & Player.MPFLAG_FirstSpot) != Player.MPFLAG_FirstSpot )
				Player.MultiplayerNotifyMsg( Player.MPMSG_TeamSpot );
		}
		else
		{
			if (miniMTLPlayer(Player) != none && miniMTLPlayer(Player).bForceWhiteCrosshair)
				bdiff = true;

			xcolor = colRed;
		}

		SightDist = VSize(target.Location - Player.Location);

		if ( ( bTeamDM && (TeamDMGame(player.DXGame).ArePlayersAllied(DeusExPlayer(target),player))) ||
			  (target.Style != STY_Translucent) || (bVisionActive && (Sightdist <= visionLevelvalue)) )              
		{
			targetPlayerName = DeusExPlayer(target).PlayerReplicationInfo.PlayerName;
        // DEUS_EX AMSD Show health of enemies with the target active.
        if (bTargetActive)
           TargetPlayerHealthString = "(" $ int(100 * (DeusExPlayer(target).Health / Float(DeusExPlayer(target).Default.Health))) $ "%)";
			targetOutOfRange = False;
			w = DeusExWeapon(player.Weapon);
			if (( w != None ) && ( xcolor != colGreen ))
			{
				dist = player.Location - target.Location;
				if ( VSize(dist) > w.maxRange ) 
				{
					if (!(( WeaponAssaultGun(w) != None ) && ( Ammo20mm(WeaponAssaultGun(w).AmmoType) != None )))
					{
						targetRangeTime = Player.Level.Timeseconds + 0.1;
						targetOutOfRange = True;
					}
				}
			}
			targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
			targetPlayerColor = xcolor;
		}
		else
			xcolor = colWhite;	// cloaked enemy
	}
	else if (target.IsA('ThrownProjectile'))	// Grenades IFF
	{
		if ( ThrownProjectile(target).bDisabled )
			xcolor = colWhite;
		else if ( (bTeamDM && (ThrownProjectile(target).team == player.PlayerReplicationInfo.team)) || 
			(player == DeusExPlayer(target.Owner)) )
			xcolor = colGreen;
		else
			xcolor = colRed;
	}
	else if ( target.IsA('AutoTurret') || target.IsA('AutoTurretGun') ) // Autoturrets IFF
	{
		if ( target.IsA('AutoTurretGun') )
		{
			team = AutoTurretGun(target).team;
			titleString = AutoTurretGun(target).titleString;
		}
		else
		{
			team = AutoTurret(target).team;
			titleString = AutoTurret(target).titleString;
		}
		if ( (bTeamDM && (player.PlayerReplicationInfo.team == team)) ||
			  (!bTeamDM && (player.PlayerReplicationInfo.PlayerID == team)) )
			xcolor = colGreen;
		else if (team == -1)
			xcolor = colWhite;
		else
			xcolor = colRed;

		targetPlayerName = titleString;
		targetOutOfRange = False;
		targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
		targetPlayerColor = xcolor;
	}
	else if ( target.IsA('ComputerSecurity'))
	{
		if ( ComputerSecurity(target).team == -1 )
			xcolor = colWhite;
		else if ((bTeamDM && (ComputerSecurity(target).team==player.PlayerReplicationInfo.team)) ||
					 (bDM && (ComputerSecurity(target).team==player.PlayerReplicationInfo.PlayerID)))
			xcolor = colGreen;
		else
			xcolor = colRed;
	}
	else if ( target.IsA('SecurityCamera'))
	{
     if ( !SecurityCamera(target).bActive )
        xcolor = colWhite;
		else if ( SecurityCamera(target).team == -1 )
			xcolor = colWhite;
		else if ((bTeamDM && (SecurityCamera(target).team==player.PlayerReplicationInfo.team)) ||
					 (bDM && (SecurityCamera(target).team==player.PlayerReplicationInfo.PlayerID)))
			xcolor = colGreen;
		else
			xcolor = colRed;
	}

	col = xcolor;
	if (bdiff)
		xcolor = colWhite;	
}

function DrawTargetAugmentation(GC gc)
{
	local String str;
	local Actor target;
	local float boxCX, boxCY, boxTLX, boxTLY, boxBRX, boxBRY, boxW, boxH;
	local float x, y, w, h, mult;
	local Vector v1, v2;
	local int i, j, k;
	local DeusExWeapon weapon;
	local bool bUseOldTarget;
	local Color crossColor, tcolor;
	local DeusExPlayer own;
	local vector AimLocation;
	local int AimBodyPart;


	crossColor.R = 255; crossColor.G = 255; crossColor.B = 255;
	tcolor.R = 255; tcolor.G = 255; tcolor.B = 255;

	// check 500 feet in front of the player
	target = TraceLOS(8000,AimLocation);

   targetplayerhealthstring = "";
   targetplayerlocationstring = "";

	if ( target != None )
	{
		GetTargetReticleColor2( target, crossColor, tcolor );

		if ((DeusExPlayer(target) != None) && (bTargetActive))
		{
			AimBodyPart = DeusExPlayer(target).GetMPHitLocation(AimLocation);
			if (AimBodyPart == 1)
				TargetPlayerLocationString = "("$msgHead$")";
			else if ((AimBodyPart == 2) || (AimBodyPart == 5) || (AimBodyPart == 6))
				TargetPlayerLocationString = "("$msgTorso$")";
			else if ((AimBodyPart == 3) || (AimBodyPart == 4))
				TargetPlayerLocationString = "("$msgLegs$")";
		}

		weapon = DeusExWeapon(Player.Weapon);
		if ((weapon != None) && !weapon.bHandToHand && !bUseOldTarget)
		{
			// if the target is out of range, don't draw the reticle
			if (weapon.MaxRange >= VSize(target.Location - Player.Location))
			{
				w = width;
				h = height;
				x = int(w * 0.5)-1;
				y = int(h * 0.5)-1;

				// scale based on screen resolution - default is 640x480
				mult = FClamp(weapon.currentAccuracy * 80.0 * (width/640.0), corner, 80.0);

				// make sure it's not too close to the center unless you have a perfect accuracy
				mult = FMax(mult, corner+4.0);
				if (weapon.currentAccuracy == 0.0)
					mult = corner;

				// draw the drop shadowed reticle
				gc.SetTileColorRGB(0,0,0);
				for (i=1; i>=0; i--)
				{
					gc.DrawBox(x+i, y-mult+i, 1, corner, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x+i, y+mult-corner+i, 1, corner, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x-(corner-1)/2+i, y-mult+i, corner, 1, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x-(corner-1)/2+i, y+mult+i, corner, 1, 0, 0, 1, Texture'Solid');

					gc.DrawBox(x-mult+i, y+i, corner, 1, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x+mult-corner+i, y+i, corner, 1, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x-mult+i, y-(corner-1)/2+i, 1, corner, 0, 0, 1, Texture'Solid');
					gc.DrawBox(x+mult+i, y-(corner-1)/2+i, 1, corner, 0, 0, 1, Texture'Solid');

					gc.SetTileColor(tcolor);
				}
			}
		}
		// movers are invalid targets for the aug
		if (target.IsA('DeusExMover'))
			target = None;
	}

	// let there be a 0.5 second delay before losing a target
	if (target == None)
	{
		if ((Player.Level.TimeSeconds - lastTargetTime < 0.5) && IsActorValid(lastTarget))
		{
			target = lastTarget;
			bUseOldTarget = True;
		}
		else
		{
			RemoveActorRef(lastTarget);
			lastTarget = None;
		}
	}
	else
	{
		lastTargetTime = Player.Level.TimeSeconds;
		bUseOldTarget = False;
		if (lastTarget != target)
		{
			RemoveActorRef(lastTarget);
			lastTarget = target;
			AddActorRef(lastTarget);
		}
	}

	if (target != None)
	{
		// draw a cornered targetting box
		v1.X = target.CollisionRadius;
		v1.Y = target.CollisionRadius;
		v1.Z = target.CollisionHeight;

		if (ConvertVectorToCoordinates(target.Location, boxCX, boxCY))
		{
			boxTLX = boxCX;
			boxTLY = boxCY;
			boxBRX = boxCX;
			boxBRY = boxCY;

			// get the smallest box to enclose actor
			// modified from Scott's ActorDisplayWindow
			for (i=-1; i<=1; i+=2)
			{
				for (j=-1; j<=1; j+=2)
				{
					for (k=-1; k<=1; k+=2)
					{
						v2 = v1;
						v2.X *= i;
						v2.Y *= j;
						v2.Z *= k;
						v2.X += target.Location.X;
						v2.Y += target.Location.Y;
						v2.Z += target.Location.Z;

						if (ConvertVectorToCoordinates(v2, x, y))
						{
							boxTLX = FMin(boxTLX, x);
							boxTLY = FMin(boxTLY, y);
							boxBRX = FMax(boxBRX, x);
							boxBRY = FMax(boxBRY, y);
						}
					}
				}
			}

			boxTLX = FClamp(boxTLX, margin, width-margin);
			boxTLY = FClamp(boxTLY, margin, height-margin);
			boxBRX = FClamp(boxBRX, margin, width-margin);
			boxBRY = FClamp(boxBRY, margin, height-margin);

			boxW = boxBRX - boxTLX;
			boxH = boxBRY - boxTLY;

			if ((bTargetActive) && (Player.Level.Netmode == NM_Standalone))
			{
				// set the coords of the zoom window, and draw the box
				// even if we don't have a zoom window
				x = width/8 + margin;
				y = height/2;
				w = width/4;
				h = height/4;

				DrawDropShadowBox(gc, x-w/2, y-h/2, w, h);

				boxCX = width/8 + margin;
				boxCY = height/2;
				boxTLX = boxCX - width/8;
				boxTLY = boxCY - height/8;
				boxBRX = boxCX + width/8;
				boxBRY = boxCY + height/8;

				if (targetLevel > 2)
				{
					if (winZoom != None)
					{
						mult = (target.CollisionRadius + target.CollisionHeight);
						v1 = Player.Location;
						v1.Z += Player.BaseEyeHeight;
						v2 = 1.5 * Player.Normal(target.Location - v1);
						winZoom.SetViewportLocation(target.Location - mult * v2);
						winZoom.SetWatchActor(target);
					}
					// window construction now happens in Tick()
				}
				else
				{
					// black out the zoom window and draw a "no image" message
					gc.SetStyle(DSTY_Normal);
					gc.SetTileColorRGB(0,0,0);
					gc.DrawPattern(boxTLX, boxTLY, w, h, 0, 0, Texture'Solid');

					gc.SetTextColorRGB(255,255,255);
					gc.GetTextExtent(0, w, h, msgNoImage);
					x = boxCX - w/2;
					y = boxCY - h/2;
					gc.DrawText(x, y, w, h, msgNoImage);
				}

				// print the name of the target above the box
				if (target.IsA('Pawn'))
					str = target.BindName;
				else if (target.IsA('DeusExDecoration'))
					str = DeusExDecoration(target).itemName;
				else if (target.IsA('DeusExProjectile'))
					str = DeusExProjectile(target).itemName;
				else
					str = target.GetItemName(String(target.Class));

				// print disabled robot info
				if (target.IsA('Robot') && (Robot(target).EMPHitPoints == 0))
					str = str $ " (" $ msgDisabled $ ")";
				gc.SetTextColor(tcolor);

				// print the range to target
				mult = VSize(target.Location - Player.Location);
				str = str $ CR() $ msgRange @ Int(mult/16) @ msgRangeUnits;

				gc.GetTextExtent(0, w, h, str);
				x = boxTLX + margin;
				y = boxTLY - h - margin;
				gc.DrawText(x, y, w, h, str);

				// level zero gives very basic health info
				if (target.IsA('Pawn'))
					mult = Float(Pawn(target).Health) / Float(Pawn(target).Default.Health);
				else if (target.IsA('DeusExDecoration'))
					mult = Float(DeusExDecoration(target).HitPoints) / Float(DeusExDecoration(target).Default.HitPoints);
				else
					mult = 1.0;

				if (targetLevel == 0)
				{
					// level zero only gives us general health readings
					if (mult >= 0.66)
					{
						str = msgHigh;
						mult = 1.0;
					}
					else if (mult >= 0.33)
					{
						str = msgMedium;
						mult = 0.5;
					}
					else
					{
						str = msgLow;
						mult = 0.05;
					}

					str = str @ msgHealth;
				}
				else
				{
					// level one gives exact health readings
					str = Int(mult * 100.0) $ msgPercent;
					if (target.IsA('Pawn') && !target.IsA('Robot') && !target.IsA('Animal'))
					{
						x = mult;		// save this for color calc
						str = str @ msgOverall;
						mult = Float(Pawn(target).HealthHead) / Float(Pawn(target).Default.HealthHead);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgHead;
						mult = Float(Pawn(target).HealthTorso) / Float(Pawn(target).Default.HealthTorso);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgTorso;
						mult = Float(Pawn(target).HealthArmLeft) / Float(Pawn(target).Default.HealthArmLeft);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgLeftArm;
						mult = Float(Pawn(target).HealthArmRight) / Float(Pawn(target).Default.HealthArmRight);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgRightArm;
						mult = Float(Pawn(target).HealthLegLeft) / Float(Pawn(target).Default.HealthLegLeft);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgLeftLeg;
						mult = Float(Pawn(target).HealthLegRight) / Float(Pawn(target).Default.HealthLegRight);
						str = str $ CR() $ Int(mult * 100.0) $ msgPercent @ msgRightLeg;
						mult = x;
					}
					else
					{
						str = str @ msgHealth;
					}
				}

				gc.GetTextExtent(0, w, h, str);
				x = boxTLX + margin;
				y = boxTLY + margin;
				gc.SetTextColor(GetColorScaled(mult));
				gc.DrawText(x, y, w, h, str);
				gc.SetTextColor(colHeaderText);

				if (targetLevel > 1)
				{
					// level two gives us weapon info as well
					if (target.IsA('Pawn'))
					{
						str = msgWeapon;
	
						if (Pawn(target).Weapon != None)
							str = str @ target.GetItemName(String(Pawn(target).Weapon.Class));
						else
							str = str @ msgNone;

						gc.GetTextExtent(0, w, h, str);
						x = boxTLX + margin;
						y = boxBRY - h - margin;
						gc.DrawText(x, y, w, h, str);
					}
				}
			}
			else
			{
				// display disabled robots
				if (target.IsA('Robot') && (Robot(target).EMPHitPoints == 0))
				{
					str = msgDisabled;
					gc.SetTextColor(tcolor);
					gc.GetTextExtent(0, w, h, str);
					x = boxCX - w/2;
					y = boxTLY - h - margin;
					gc.DrawText(x, y, w, h, str);
				}
			}
		}
	}
	else if ((bTargetActive) && (Player.Level.NetMode == NM_Standalone))
	{
		if (Player.Level.TimeSeconds % 1.5 > 0.75)
			str = msgScanning1;
		else
			str = msgScanning2;
		gc.GetTextExtent(0, w, h, str);
		x = width/2 - w/2;
		y = (height/2 - h) - 20;
		gc.DrawText(x, y, w, h, str);
	}

	// set the crosshair colors
	DeusExRootWindow(player.rootWindow).hud.cross.SetCrosshairColor(crossColor);
}

defaultproperties
{
     colBlue1=(B=255)
     colWhite=(R=255,G=255,B=255)
     colGreen1=(G=128)
     colLtGreen=(G=255)
     colRed1=(R=128)
     colLtRed=(R=255)
}
