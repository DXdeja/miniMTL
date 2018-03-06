class MMAugBallistic extends MMAugmentation
	abstract;

defaultproperties
{
    OldAugClass=Class'DeusEx.AugBallistic'
    ManagerIndex=3
    EnergyRate=90.00
    Icon=Texture'DeusExUI.UserInterface.AugIconBallistic'
    smallIcon=Texture'DeusExUI.UserInterface.AugIconBallistic_Small'
    AugmentationName="Ballistic Protection"
    LevelValues(0)=0.80
    LevelValues(1)=0.65
    LevelValues(2)=0.50
    LevelValues(3)=0.60
    AugmentationLocation=5
    MPConflictSlot=6
}
