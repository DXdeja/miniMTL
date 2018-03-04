class MMHUDActiveAugsBorder expands HUDActiveAugsBorder;

function CreateIcons()
{
     local int keyIndex;
     local HUDActiveAug iconWindow;

     for(keyIndex=FirstKeyNum; keyIndex<=LastKeyNum; keyIndex++)
     {
          iconWindow = HUDActiveAug(winIcons.NewChild(Class'MMHUDActiveAug'));
          iconWindow.SetKeyNum(keyIndex);
          iconWindow.Hide();
     }
}

function MMHUDActiveAug NewFindAugWindowByKey(int FKey)
{
	local Window currentWindow;
	local Window foundWindow;

	currentWindow = winIcons.GetTopChild(False);

	while (currentWindow != None)
	{
		if (MMHUDActiveAug(currentWindow).HotKeyNum == FKey)
		{
			foundWindow = currentWindow;
			break;
		}
		currentWindow = currentWindow.GetLowerSibling(False);
	}

	return MMHUDActiveAug(foundWindow);
}

function NewAddIcon(class<MMAugmentation> augclass, bool enabled)
{
	local MMHUDActiveAug augItem;
	local int FKey;

	FKey = augclass.default.MPConflictSlot;
	augItem = NewFindAugWindowByKey(FKey);

	if (augItem != None)
	{
		augItem.SetIcon(augclass.default.smallIcon);
		//augItem.SetClientObject(saveObject);
		//augItem.SetObject(saveObject);
		augItem.hotKeyNum = FKey;
		augItem.hotKeyString = "F" $ String(FKey);
		augItem.bEnabled = enabled;
		augItem.AugClass = augclass;
		augItem.Show();

		// Hide if there are no icons visible
		if (++iconCount == 1)
			Show();

		AskParentForReconfigure();

		augItem.UpdateAugIconStatus();
	}
}

function UpdateAugIconStatus(Augmentation aug)
{
	local HUDActiveAug iconWindow;

	iconWindow = HUDActiveAug(winIcons.GetTopChild());
	while(iconWindow != None)
	{
		iconWindow.UpdateAugIconStatus();
		iconWindow = HUDActiveAug(iconWindow.GetLowerSibling());
	}
}

defaultproperties
{
}
