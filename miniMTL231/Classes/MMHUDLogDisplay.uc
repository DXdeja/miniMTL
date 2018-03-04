class MMHUDLogDisplay extends HUDLogDisplay;

function AddLog(coerce String newLog, Color linecol)
{
	if (newLog != "" && miniMTLPlayer(Player).bColoredTalkMessages)
	{
		if (InStr(newLog, Player.PlayerReplicationInfo.PlayerName) != -1 && linecol.R != 200)
		{
			if (linecol.R == 0) // teamsay
			{
				linecol.R = 255;
			}
			else // say
			{
				linecol.R = 0;
			}
		}
	}
	super.AddLog(newLog, linecol);
}

defaultproperties
{
}
