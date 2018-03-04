class miniMTLAdvTeam extends miniMTLTeam;

/** @ignore */
function PreBeginPlay ()
{
	Super.PreBeginPlay();
	ResetNonCustomizableOptions();
}

function ResetNonCustomizableOptions ()
{
	Super.ResetNonCustomizableOptions();
	if( !bCustomizable )
	{
		SkillsTotal=2000;
		SkillsAvail=2000;
		SkillsPerKill=2000;
		InitialAugs=2;
		AugsPerKill=2;
		MPSkillStartLevel=1;
		SaveConfig();
	}
}

defaultproperties
{
     bCustomizable=False
}
