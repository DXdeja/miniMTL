class miniMTLDMPlayer extends miniMTLPlayer;

function SetSkin()
{
	local int i;

	log("Skin class is : " $ SkinClasses[0]);
	if (SkinClasses[0] != none)
	{
		Mesh = SkinClasses[0].default.Mesh;
		DrawScale = SkinClasses[0].default.DrawScale;
		V68 = SkinClasses[0].default.V68;
		for (i = 0; i < 8; i++)
		{
			MultiSkins[i] = SkinClasses[0].default.MultiSkins[i];
		}

		// set sounds
		//JumpSound = SkinClasses[0].default.JumpSound;
		//HitSound1 = SkinClasses[0].default.HitSound1;
		//HitSound2 = SkinClasses[0].default.HitSound2;
		//HitSound3 = SkinClasses[0].default.HitSound3;
		//Die = SkinClasses[0].default.Die;
		//SoundEyePain = SkinClasses[0].default.SoundEyePain;
		//SoundDrown = SkinClasses[0].default.SoundDrown;
		//SoundWaterDeath = SkinClasses[0].default.SoundWaterDeath;
		//SoundGasp = SkinClasses[0].default.SoundGasp;
	}
}

defaultproperties
{
}
