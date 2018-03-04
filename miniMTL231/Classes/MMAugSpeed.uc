class MMAugSpeed extends MMAugmentation
	abstract;

static function ActivateAction(DeusExPlayer dxp)
{
	dxp.GroundSpeed *= default.LevelValues[3];
	dxp.JumpZ *= default.LevelValues[3];
	if (Human(dxp) != None)
		Human(dxp).UpdateAnimRate(default.LevelValues[3]);
}

static function DeactivateAction(DeusExPlayer dxp)
{
	if (dxp.IsA('Human'))
		dxp.GroundSpeed = Human(dxp).Default.mpGroundSpeed;
	else
		dxp.GroundSpeed = dxp.Default.GroundSpeed;

	dxp.JumpZ = dxp.Default.JumpZ;
	if (Human(dxp) != None)
		Human(dxp).UpdateAnimRate(-1.0);
}

defaultproperties
{
     OldAugClass=Class'DeusEx.AugSpeed'
     EnergyRate=180.000000
     Icon=Texture'DeusExUI.UserInterface.AugIconSpeedJump'
     smallIcon=Texture'DeusExUI.UserInterface.AugIconSpeedJump_Small'
     AugmentationName="Speed Enhancement"
     Description="Ionic polymeric gel myofibrils are woven into the leg muscles, increasing the speed at which an agent can run and climb, the height they can jump, and reducing the damage they receive from falls.|n|nTECH ONE: Speed and jumping are increased slightly, while falling damage is reduced.|n|nTECH TWO: Speed and jumping are increased moderately, while falling damage is further reduced.|n|nTECH THREE: Speed and jumping are increased significantly, while falling damage is substantially reduced.|n|nTECH FOUR: An agent can run like the wind and leap from the tallest building."
     MPInfo="When active, you move twice as fast and jump twice as high.  Energy Drain: Very High"
     LevelValues(0)=1.200000
     LevelValues(1)=1.400000
     LevelValues(2)=1.600000
     LevelValues(3)=2.000000
     AugmentationLocation=LOC_Torso
     MPConflictSlot=7
}
