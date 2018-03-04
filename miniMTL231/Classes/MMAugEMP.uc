class MMAugEMP extends MMAugmentation
	abstract;

defaultproperties
{
     OldAugClass=Class'DeusEx.AugEMP'
     ManagerIndex=7
     EnergyRate=5.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconEMP'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconEMP_Small'
     AugmentationName="EMP Shield"
     Description="Nanoscale EMP generators partially protect individual nanites and reduce bioelectrical drain by canceling incoming pulses.|n|nTECH ONE: Damage from EMP attacks is reduced slightly.|n|nTECH TWO: Damage from EMP attacks is reduced moderately.|n|nTECH THREE: Damage from EMP attacks is reduced significantly.|n|nTECH FOUR: An agent is nearly invulnerable to damage from EMP attacks."
     MPInfo="When active, you only take 5% damage from EMP attacks.  Energy Drain: Very Low"
     LevelValues(0)=0.750000
     LevelValues(1)=0.500000
     LevelValues(2)=0.250000
     LevelValues(3)=0.050000
     AugmentationLocation=LOC_Subdermal
     MPConflictSlot=5
}
