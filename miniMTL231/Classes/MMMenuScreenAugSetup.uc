class MMMenuScreenAugSetup extends CBPMenuScreenAugSetup;

function CreateAugButtons()
{
	local int iButtonIndex;
	local bool bShiftRight;
	local class<MMAugmentation> CurAug;
	local int i;

	for (i = 0; i < ArrayCount(class'MMAugmentationManager'.default.mpAugs) - 1; i++)
	{
		CurAug = class'MMAugmentationManager'.default.mpAugs[i];
		iButtonIndex = (CurAug.default.mpConflictSlot - 3) * 2;
		bShiftRight = btnAugChoice[iButtonIndex] != None;
		if (bShiftRight)
			iButtonIndex++;

		if (btnAugChoice[iButtonIndex] == None)
		{
			btnAugChoice[iButtonIndex] = MenuUIChoiceButton(winClient.NewChild(Class'MenuUIChoiceButton'));
			btnaugChoice[iButtonIndex].SetButtonText(curAug.default.OldAugClass.default.augmentationName); // this name will be localized... better

			if (CurAug != class'MMAugAqualung')
			{
				if (!bShiftRight)
				{
					btnAugChoice[iButtonIndex].SetPos(6, 4 + 23 * (CurAug.default.mpConflictSlot - 2));
				}
				else
				{
					btnAugChoice[iButtonIndex].SetPos(172, 4 + 23 * (CurAug.default.mpConflictSlot - 2));
				}
			}
			else // Last button is aqualung, centered
			{
				btnAugChoice[iButtonIndex].SetPos(92, 4 + 23 * (CurAug.default.mpConflictSlot - 2));
			}

			btnAugChoice[iButtonIndex].SetWidth(163);
			btnAugChoice[iButtonIndex].SetHelpText(curAug.default.OldAugClass.default.MPInfo);         
			btnAugChoice[iButtonIndex].fontButtonText = font'FontMenuSmall';

			ChoiceNames[iButtonIndex] = String(CurAug.default.OldAugClass.Name);
		}
	}
}

function class<Augmentation> NewGetAugFromStringName(string AugStringName)
{
   local int i;

   if (AugStringName == "")
      return None;

   for (i = 0; i < ArrayCount(class'MMAugmentationManager'.default.mpAugs) - 1; i++)
   {
		log("aug name: " $ string(class'MMAugmentationManager'.default.mpAugs[i].default.OldAugClass.Name));
		if (string(class'MMAugmentationManager'.default.mpAugs[i].default.OldAugClass.Name) == AugStringName)
			return class'MMAugmentationManager'.default.mpAugs[i].default.OldAugClass;
   }

   return none;
}

function string AugFamiliarName(string AugStringName)
{
	local class<Augmentation> anAug;

   if (AugStringName == "")
      return "";
   else   
   {
		anAug = NewGetAugFromStringName(AugStringName);
      if (anAug == None)
         return "";
      else
         return anAug.default.AugmentationName;
   }
}

function SaveSettings()
{
	local DeusExPlayer p;
	local LevelInfo Z3D;
	local int VD3;

	local int AugIndex;
	local class<Augmentation> CurAug;

	// Clear player augprefs, copy Chosen augs over
	for (AugIndex = 0; AugIndex < ArrayCount(player.AugPrefs); AugIndex++)
	{
		player.AugPrefs[AugIndex] = '';
	}

	for (AugIndex = 0; ((AugIndex < ArrayCount(ChosenAugs)) && (AugIndex < ArrayCount(player.AugPrefs))); AugIndex++)
	{
		log("chosen aug: " $ ChosenAugs[AugIndex]);
		CurAug = NewGetAugFromStringName(ChosenAugs[AugIndex]);
		if (CurAug != none)
			player.AugPrefs[AugIndex] = CurAug.Name;
	}

	player.SaveConfig();

	Z3D=Player.GetEntryLevel();
	if (Z3D != none)
	{
		foreach Z3D.AllActors(Class'DeusExPlayer', p)
		{
			VD3=0;
JL0046:
			if ( VD3 < 9 )
			{
				p.AugPrefs[VD3]=Player.AugPrefs[VD3];
				VD3++;
				goto JL0046;
			}
			p.SaveConfig();
		}
	}

	Super(MenuUIScreenWindow).SaveSettings();
}

defaultproperties
{
     AugPrefs(0)=AugSpeed
     AugPrefs(1)=AugCloak
     AugPrefs(2)=AugBallistic
     AugPrefs(4)=AugHealing
}
