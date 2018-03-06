class MMHUDMultiSkills extends HUDMultiSkills;

var float FirstDisplayTime;
var bool bMenuOpened;

function SkillMessage( GC gc )
{
	local float curx, cury, w, h, w2, offset;
	local String str;
	local miniMTLPlayer mmp;
    local bool forever;

	mmp = miniMTLPlayer(Player);
	if (mmp != none && mmp.bDisplaySkillMessageForever) forever = true;

	if ( curSkillPoints != Player.SkillPointsAvail )
		bNotifySkills = False;

	if (MMSkillManager(Player.SkillSystem) != None && MMSkillManager(Player.SkillSystem).IsPurchasePossible())
	{
		if (FirstDisplayTime == 0.0) FirstDisplayTime = Player.Level.TimeSeconds;
		if ( !bNotifySkills )
		{
			RefreshKey();
			timeToNotify = Player.Level.Timeseconds + TimeDelay;
			curSkillPoints = Player.SkillPointsAvail;
			Player.BuySkillSound( 3 );
			bNotifySkills = True;
		}
		if ( timeToNotify > Player.Level.Timeseconds || forever)
		{
			// Flash them to draw a little more attention 1.5 on .5 off
			if ( (Player.Level.Timeseconds % 1.5) < 1 )
			{
				offset = 0;
				str = PressString $ curKeyName $ PressEndString;

				if ((Player.Level.Timeseconds - FirstDisplayTime) < TimeDelay || bMenuOpened)
				{
					gc.SetFont(Font'FontMenuSmall_DS');
					cury = height * skillMsgY;
					curx = width * skillListX;
					gc.GetTextExtent( 0, w, h, SkillsAvailableString );
					gc.GetTextExtent( 0, w2, h, str );
				}
				else 
				{
					gc.SetFont(Font'FontMenuExtraLarge');
					cury = height * 0.6;
					gc.GetTextExtent( 0, w, h, SkillsAvailableString );
					gc.GetTextExtent( 0, w2, h, str );
					curx = (width - w) * 0.5;
				}

				if ( (curx + ((w-w2)*0.5)) < 0 ) offset = -(curx + ((w-w2)*0.5));
				gc.SetTextColor( colLtGreen );
				gc.GetTextExtent( 0, w, h, SkillsAvailableString );
				gc.DrawText( curx+offset, cury, w, h, SkillsAvailableString );
				cury +=  h;
				gc.GetTextExtent( 0, w2, h, str );
				curx += ((w-w2)*0.5);
				gc.DrawText( curx+offset, cury, w2, h, str );
			}
		}
	}
	else
		FirstDisplayTime = 0.0;
}

event DrawWindow(GC gc)
{
	local float curx, cury, w, h;
	local String str, costStr;
	local int index;
	local float barLen, costx, levelx;
	local MMSkillManager smanager;
	local int i;

	if (( Player == None ) || (!Player.PlayerIsClient()) )
		return;

	if (Player.Health <= 0) 
	{
		bMenuOpened = false;
		FirstDisplayTime = 0.0;
	}

    if (Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.bIsSpectator) 
    {
		bMenuOpened = false;
		FirstDisplayTime = 0.0;
    	return;
    }

	if ( Player.bBuySkills )
	{
		bMenuOpened = true;
		smanager = MMSkillManager(Player.SkillSystem);
		if (smanager != none)
		{
			gc.SetFont(Font'FontMenuSmall_DS');
			index = 1;
			cury = height * skillListY;
			curx = width * skillListX;
			costx = width * skillCostX;
			levelx = width * skillLevelX;
			gc.GetTextExtent( 0, w, h, CostString );
			barLen = (costx+(w*1.33))-curx;
			gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
			cury += (h*0.25);
			str = SkillPointsString $ Player.SkillPointsAvail;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( curx, cury, w, h, str );
			cury += h;
			gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
			cury += (h*0.25);
			str = SkillString;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( curx, cury, w, h, str );
			str = LevelString;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( levelx, cury, w, h, str );
			str = CostString;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawText( costx, cury, w, h, str );
			cury += h;
			gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
			cury += (h*0.25);

			for (i = 0; i < ArrayCount(smanager.SkillLevels) - 1; i++)
			{
				index = i + 1;
				if ( index == 10 )
					str = "0. " $ smanager.GetSkillClassNameByIndex(i);
				else
					str = index $ ". " $ smanager.GetSkillClassNameByIndex(i);

				gc.GetTextExtent( 0, w, h, str );
				if ( smanager.SkillLevels[i] == 3)
				{
					gc.SetTileColor( colBlue );
					gc.SetTextColor( colBlue );
					costStr = NAString;
				}
				else if ( Player.SkillPointsAvail >= smanager.SkillCosts[i] )
				{
					if ( smanager.SkillLevels[i] == 2)
					{
						gc.SetTextColor( colLtGreen );
						gc.SetTileColor( colLtGreen );
					}
					else
					{
						gc.SetTextColor( colGreen );
						gc.SetTileColor( colGreen );
					}
					costStr = "" $ smanager.SkillCosts[i];
				}
				else
				{
					if ( smanager.SkillLevels[i] == 2)
					{
						gc.SetTileColor( colLtRed );
						gc.SetTextColor( colLtRed );
					}
					else
					{
						gc.SetTileColor( colRed );
						gc.SetTextColor( colRed );
					}
					costStr = "" $ smanager.SkillCosts[i];
				}
				gc.DrawText( curx, cury, w, h, str );
				DrawLevel( gc, levelx, cury, smanager.SkillLevels[i] );
				gc.GetTextExtent(	0, w, h, costStr );
				gc.DrawText( costx, cury, w, h, costStr );
				cury += h;
				index += 1;
			}

			gc.SetTileColor( colWhite );
			if ( curKeyName ~= KeyNotBoundString )
				RefreshKey();
			str = PressString $ curKeyName $ ToExitString;
			gc.GetTextExtent( 0, w, h, str );
			gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
			cury += (h*0.25);
			gc.SetTextColor( colWhite );
			gc.DrawText( curx + ((barLen*0.5)-(w*0.5)), cury, w, h, str );
			cury += h;
			gc.DrawBox( curx, cury, barLen, 1, 0, 0, 1, Texture'Solid');
		}
	}
	else 
		SkillMessage( gc );

	Super(HUDBaseWindow).DrawWindow(gc);
}

function bool AttemptBuySkill2( DeusExPlayer thisPlayer, byte sindex)
{
	local MMSkillManager smanager;

	smanager = MMSkillManager(thisPlayer.SkillSystem);
	if (smanager == none) return false;

	if (sindex < ArrayCount(smanager.SkillLevels))
	{
		// Already master
		if ( smanager.SkillLevels[sindex] == 3 )
		{
			thisPlayer.BuySkillSound( 1 );
			return ( False );
		}
		else if ( thisPlayer.SkillPointsAvail >= smanager.SkillCosts[sindex] )
		{
			thisPlayer.BuySkillSound( 0 );
			smanager.IncLevel(sindex);
			return true;
		}
		else
		{
			thisPlayer.BuySkillSound( 1 );
			return( False );
		}
	}

	return false;
}

function bool OverrideBelt( DeusExPlayer thisPlayer, int objectNum )
{
	if ( !thisPlayer.bBuySkills )
		return False;

	// Zero indexed, but min element is 1, 0 is 10
	if ( objectNum == 0 )
		objectNum = 9;
	else
		objectNum -= 1;

	if ( AttemptBuySkill2( thisPlayer, objectNum ) )
		thisPlayer.bBuySkills = False; 		// Got our skill, exit out of menu

	if ( ( objectNum >= 0 ) && ( objectNum < 10) )
		return True;
	else
		return False;
}

defaultproperties
{
}
