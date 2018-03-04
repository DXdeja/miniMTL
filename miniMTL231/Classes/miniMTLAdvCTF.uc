class miniMTLAdvCTF extends miniMTLCTF;

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
		SkillsPerKill=2000;
		AugsPerKill=0;

		// CTF
		SkillsPerCapture=0;
		SkillsPerScore=0;
		SkillsPerReturn=0;
		AugsPerCapture=1;
		AugsPerScore=1;
		AugsPerReturn=1;

		TeamSkillsPerCapture=0;
		TeamSkillsPerScore=2000;
		TeamSkillsPerReturn=0;
		TeamAugsPerCapture=0;
		TeamAugsPerScore=1;
		TeamAugsPerReturn=0;

		// can players use augs when flag taken at all?
		bAugsWithFlag=false;

		// after that time, players would be allowed to use augs (under bAugsWithFlag=true condition)
		// but also displayed on radar for enemy players
		flagEscapeTime=30;

		// initial
		InitialAugs=2;
		MPSkillStartLevel=1;
		SkillsTotal=2000;
		SkillsAvail=2000;

		SaveConfig();
	}
}

defaultproperties
{
     bCustomizable=False
}
