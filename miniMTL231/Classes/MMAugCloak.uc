class MMAugCloak extends MMAugmentation
	abstract;

static function ActivateAction(DeusExPlayer dxp)
{
	if ((dxp.inHand != None) && (dxp.inHand.IsA('DeusExWeapon')))
		dxp.ServerConditionalNotifyMsg(dxp.MPMSG_NoCloakWeapon);
	dxp.PlaySound(Sound'CloakUp', SLOT_Interact, 0.85, ,768,1.0);
}

static function DeactivateAction(DeusExPlayer dxp)
{
	dxp.PlaySound(Sound'CloakDown', SLOT_Interact, 0.85, ,768,1.0);
}

defaultproperties
{
     OldAugClass=Class'DeusEx.AugCloak'
     ManagerIndex=2
     EnergyRate=40.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconCloak'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconCloak_Small'
     AugmentationName="Cloak"
     LevelValues(0)=1.000000
     LevelValues(1)=0.830000
     LevelValues(2)=0.660000
     LevelValues(3)=1.000000
     AugmentationLocation=LOC_Eye
     MPConflictSlot=8
}
