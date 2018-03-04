class miniMTLBasicDM extends miniMTLDeathMatch;

function PreBeginPlay()
{
	Super.PreBeginPlay();
	ResetNonCustomizableOptions();
}

function ResetNonCustomizableOptions()
{
	Super.ResetNonCustomizableOptions();
	if( !bCustomizable )
	{
		SkillsTotal=0;
		SkillsAvail=0;
		SkillsPerKill=0;
		InitialAugs=9;
		AugsPerKill=0;
		MPSkillStartLevel=3;
		SaveConfig();
	}
}

defaultproperties
{
     bCustomizable=False
}
