class MMDeusExHUD extends DeusExHUD;

var int HUD_mode;

event InitWindow()
{
	local DeusExPlayer player;
	super.InitWindow();

	player = DeusExPlayer(DeusExRootWindow(GetRootWindow()).parentPawn);

	if ( belt != None ) belt.Destroy();
	belt = HUDObjectBelt(NewChild(Class'MMHUDObjectBelt'));
	if (augDisplay != None)	augDisplay.Destroy();
	augDisplay = AugmentationDisplayWindow(NewChild(Class'MMAugmentationDisplayWindow'));
	augDisplay.SetWindowAlignments(HALIGN_Full,VALIGN_Full);
	if (hms != none) hms.Destroy();
	hms = HUDMultiSkills(NewChild(class'MMHUDMultiSkills'));

	if (activeItems != none) activeItems.Destroy();
	activeItems = HUDActiveItemsDisplay(NewChild(Class'MMHUDActiveItemsDisplay'));

	if (frobDisplay != none) frobDisplay.Destroy();
	frobDisplay = FrobDisplayWindow(NewChild(Class'MMFrobDisplayWindow'));
	frobDisplay.SetWindowAlignments(HALIGN_Full, VALIGN_Full);

	if (msgLog != none) msgLog.Destroy();
	msgLog = HUDLogDisplay(NewChild(Class'MMHUDLogDisplay', False));
	msgLog.SetLogTimeout(player.GetLogTimeout());
}


function UpdateSettings( DeusExPlayer player )
{
	if (HUD_mode > 0)
	{
		// spectating another player
		hit.SetVisibility(player.bHitDisplayVisible);
		activeItems.SetVisibility(player.bAugDisplayVisible);
		damageDisplay.SetVisibility(player.bHitDisplayVisible);
		cross.SetCrosshair(player.bCrosshairVisible);
		if (HUD_mode > 1)
		{
			// playing
			compass.SetVisibility(player.bCompassVisible);
			ammo.SetVisibility(player.bAmmoDisplayVisible);
			belt.SetVisibility(player.bObjectBeltVisible);
		}
		else
		{
			// spectating another player, hide these
			compass.SetVisibility(false);
			ammo.SetVisibility(false);
			belt.SetVisibility(false);
			ResetCrosshair();
		}
	}
	else
	{
		// spectating in free mode, hide all
		hit.SetVisibility(false);
		activeItems.SetVisibility(false);
		damageDisplay.SetVisibility(false);
		cross.SetCrosshair(false);
		compass.SetVisibility(false);
		ammo.SetVisibility(false);
		belt.SetVisibility(false);
		ResetCrosshair();
	}
}


function ResetCrosshair()
{
	local color col;
    col.R = 255;
    col.G = 255;
    col.B = 255;
    cross.SetCrosshairColor(col);
}

defaultproperties
{
    HUD_mode=2
}
