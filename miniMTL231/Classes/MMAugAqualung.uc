class MMAugAqualung extends MMAugmentation
	abstract;

static function ActivateAction(DeusExPlayer dxp)
{
	local float mult, pct;

	mult = dxp.SkillSystem.GetSkillLevelValue(class'SkillSwimming');
	pct = dxp.swimTimer / dxp.swimDuration;
	dxp.UnderWaterTime = default.LevelValues[3];
	dxp.swimDuration = dxp.UnderWaterTime * mult;
	dxp.swimTimer = dxp.swimDuration * pct;

	if (Human(dxp) != none)
	{
		dxp.WaterSpeed = Human(dxp).Default.mpWaterSpeed * 2.0 * mult;
	}
}

static function DeactivateAction(DeusExPlayer dxp)
{
	local float mult, pct;

	mult = dxp.SkillSystem.GetSkillLevelValue(class'SkillSwimming');
	pct = dxp.swimTimer / dxp.swimDuration;
	dxp.UnderWaterTime = dxp.Default.UnderWaterTime;
	dxp.swimDuration = dxp.UnderWaterTime * mult;
	dxp.swimTimer = dxp.swimDuration * pct;

	if (Human(dxp) != none)
	{
		dxp.WaterSpeed = Human(dxp).Default.mpWaterSpeed * mult;
	}
}

defaultproperties
{
     OldAugClass=Class'DeusEx.AugAqualung'
     ManagerIndex=15
     EnergyRate=10.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconAquaLung'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconAquaLung_Small'
     AugmentationName="Aqualung"
     LevelValues(0)=30.000000
     LevelValues(1)=60.000000
     LevelValues(2)=120.000000
     LevelValues(3)=240.000000
     AugmentationLocation=LOC_Torso
     MPConflictSlot=11
}
