class MMAugCombat extends MMAugmentation
	abstract;

defaultproperties
{
    OldAugClass=Class'DeusEx.AugCombat'
    ManagerIndex=8
    EnergyRate=20.00
    Icon=Texture'DeusExUI.UserInterface.AugIconCombat'
    smallIcon=Texture'DeusExUI.UserInterface.AugIconCombat_Small'
    AugmentationName="Combat Strength"
    LevelValues(0)=1.25
    LevelValues(1)=1.50
    LevelValues(2)=1.75
    LevelValues(3)=2.00
    AugmentationLocation=3
    MPConflictSlot=3
}
