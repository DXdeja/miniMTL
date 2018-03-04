//-----------------------------------------------------------
//
//-----------------------------------------------------------
class MMHUDActiveAug expands HUDActiveAug;

var color colAugDisabled;

var bool bEnabled;
var class<MMAugmentation> AugClass;

function miniMTLPlayer getPlayer()
{
   return miniMTLPlayer(player);
}

function UpdateAugIconStatus()
{
	local miniMTLPlayer mmp;

	if (bEnabled) colItemIcon = colAugActive;
	else colItemIcon = colAugInactive;
     
	mmp = getPlayer();
	if (mmp != none)
	{
		if (mmp.bAugsDisabled && !MMAugmentationManager(mmp.AugmentationSystem).IsAllowedFlagAug(AugClass)) colItemIcon = colAugDisabled;
	}
}

defaultproperties
{
     colAugDisabled=(R=25,G=25,B=25)
}
