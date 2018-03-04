class MMAugMuscle extends MMAugmentation
	abstract;

static function DeactivateAction(DeusExPlayer dxp)
{
	if (dxp.CarriedDecoration != None)
		if (!dxp.CanBeLifted(dxp.CarriedDecoration))
			dxp.DropDecoration();
}

defaultproperties
{
     OldAugClass=Class'DeusEx.AugMuscle'
     ManagerIndex=11
     EnergyRate=20.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconMuscle'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconMuscle_Small'
     AugmentationName="Microfibral Muscle"
     Description="Muscle strength is amplified with ionic polymeric gel myofibrils that allow the agent to push and lift extraordinarily heavy objects.|n|nTECH ONE: Strength is increased slightly.|n|nTECH TWO: Strength is increased moderately.|n|nTECH THREE: Strength is increased significantly.|n|nTECH FOUR: An agent is inhumanly strong."
     MPInfo="When active, you can pick up large crates.  Energy Drain: Low"
     LevelValues(0)=1.250000
     LevelValues(1)=1.500000
     LevelValues(2)=1.750000
     LevelValues(3)=2.000000
     AugmentationLocation=LOC_Leg
     MPConflictSlot=10
}
