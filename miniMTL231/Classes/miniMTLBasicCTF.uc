class miniMTLBasicCTF extends miniMTLCTF;

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
		// kills
		SkillsPerKill=0;
		AugsPerKill=0;

		// CTF
		SkillsPerCapture=0;
		SkillsPerScore=0;
		SkillsPerReturn=0;
		AugsPerCapture=0;
		AugsPerScore=0;
		AugsPerReturn=0;

		TeamSkillsPerCapture=0;
		TeamSkillsPerScore=0;
		TeamSkillsPerReturn=0;
		TeamAugsPerCapture=0;
		TeamAugsPerScore=0;
		TeamAugsPerReturn=0;

		// can players use augs when flag taken at all?
		bAugsWithFlag=false;

		// after that time, players would be allowed to use augs (under bAugsWithFlag=true condition)
		// but also displayed on radar for enemy players
		flagEscapeTime=0;

		// initial
		InitialAugs=9;
		MPSkillStartLevel=3;
		SkillsTotal=0;
		SkillsAvail=0;

		SaveConfig();
	}
}

defaultproperties
{
     bCustomizable=False
}
