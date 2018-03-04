class MMHUDActiveItemsDisplay expands HUDActiveItemsDisplay;

function CreateContainerWindows()
{
     winAugsContainer  = HUDActiveAugsBorder(NewChild(Class'MMHUDActiveAugsBorder'));
     winItemsContainer = HUDActiveItemsBorder(NewChild(Class'HUDActiveItemsBorder'));
}

function AddAug(class <MMAugmentation> augclass, bool enabled)
{
	MMHUDActiveAugsBorder(winAugsContainer).NewAddIcon(augclass, enabled);
	AskParentForReconfigure();
}

defaultproperties
{
}
