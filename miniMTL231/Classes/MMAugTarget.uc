class MMAugTarget extends MMAugmentation
	abstract;

static function ActivateAction(DeusExPlayer dxp)
{
	local MMAugmentationManager manager;
	manager = GetManager(dxp);
	manager.SetTargetingAugStatus(true);
}

static function DeactivateAction(DeusExPlayer dxp)
{
	local MMAugmentationManager manager;
	manager = GetManager(dxp);
	manager.SetTargetingAugStatus(false);
}

defaultproperties
{
     OldAugClass=Class'DeusEx.AugTarget'
     ManagerIndex=1
     EnergyRate=40.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconTarget'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconTarget_Small'
     AugmentationName="Targeting"
     Description="Image-scaling and recognition provided by multiplexing the optic nerve with doped polyacetylene 'quantum wires' not only increases accuracy, but also delivers limited situational info about a target.|n|nTECH ONE: Slight increase in accuracy and general target information.|n|nTECH TWO: Additional increase in accuracy and more target information.|n|nTECH THREE: Additional increase in accuracy and specific target information.|n|nTECH FOUR: Additional increase in accuracy and telescopic vision."
     MPInfo="When active, all weapon skills are effectively increased by one level, and you can see an enemy's health.  The skill increases allow you to effectively surpass skill level 3.  Energy Drain: Moderate"
     LevelValues(0)=-0.050000
     LevelValues(1)=-0.100000
     LevelValues(2)=-0.150000
     LevelValues(3)=-0.125000
     AugmentationLocation=LOC_Subdermal
     MPConflictSlot=6
}
