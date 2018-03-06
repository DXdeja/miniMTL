class MMMultiplayerMessageWin extends MultiplayerMessageWin;

var float RespawnTime;
var string RespawnString1, RespawnString2;
var float oldlockoutTime;

event InitWindow()
{
	Super.InitWindow();
}

function SetRespawnTime(float t)
{
	oldlockoutTime = lockoutTime - 2.0;
	lockoutTime = Player.Level.Timeseconds + t;
}

event DrawWindow(GC gc)
{
	local float w, h, x, y;
	local string str;

	super.DrawWindow(gc);

	if (( DeusExMPGame(Player.DXGame) != None ) && DeusExMPGame(Player.DXGame).bClientNewMap )
		return;

	if (bKilled &&  Player.Level.Timeseconds < lockoutTime)
	{
		str = RespawnString1 $ string(int(lockoutTime - Player.Level.Timeseconds)) $ RespawnString2;
		gc.SetTextColor( whiteColor );
		gc.SetFont(Font'FontMenuTitle');
		gc.GetTextExtent( 0, w, h, str );
		x = (width * 0.5) - (w * 0.5);
		y = height * 0.88;
		gc.DrawText( x, y, w, h, str );
		if ( !Player.bKillerProfile && Player.killProfile.bValid && (!Player.killProfile.bKilledSelf))
		{
			y += h;
			str = Detail1String $ curDetailKeyName $ Detail2String;
			gc.GetTextExtent( 0, w, h, str );
			x = (width * 0.5) - (w * 0.5);
			gc.DrawText( x, y, w, h, str );
		}
	}
}


event bool VirtualKeyPressed(EInputKey key, bool bRepeat)
{
	local bool bKeyHandled;
	local String KeyName, Alias;

	bKeyHandled = False;

   if ((key == IK_F10) && (bDisplayProgress))
   {
      Player.ConsoleCommand("CANCEL");
      return True;
   }

	// Let them send chat messages
	KeyName = player.ConsoleCommand("KEYNAME "$key );
	Alias = 	player.ConsoleCommand( "KEYBINDING "$KeyName );

	if ( Alias ~= "Talk" )
		Player.Player.Console.Talk();
	else if ( Alias ~= "TeamTalk" )
		Player.Player.Console.TeamTalk();

	if ( Player.Level.Timeseconds < oldlockoutTime )
		return True;

	if ( Alias ~= "KillerProfile" )
	{
		Player.bKillerProfile = True;
		return True;
	}
	else
		return Super.VirtualKeyPressed(key, bRepeat);
}

defaultproperties
{
    RespawnString1="Respawning... you have to wait "
    RespawnString2=" seconds."
}
