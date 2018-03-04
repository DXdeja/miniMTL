class MMHUDObjectBelt extends HUDObjectBelt;

var bool bVisible;

function CreateSlots()
{
	local RadioBoxWindow winRadio;
	local int i;

	winRadio=RadioBoxWindow(NewChild(Class'RadioBoxWindow'));
	winRadio.SetSize(504.00,54.00);
	winRadio.SetPos(10.00,6.00);
	winRadio.bOneCheck=False;
	winSlots=TileWindow(winRadio.NewChild(Class'TileWindow'));
	winSlots.SetMargins(0, 0);
	winSlots.SetMinorSpacing(0);
	winSlots.SetOrder(ORDER_LeftThenUp);

    for (i = 0; i < 10; i++ )
	{
		objects[i]=HUDObjectSlot(winSlots.NewChild(Class'MMHUDObjectSlot'));
		objects[i].SetObjectNumber(i);
		objects[i].Lower();
	}
	objects[0].SetWidth(44.00);
	objects[0].Lower();
}


function SetVisibility(bool bNewVisibility)
{
    local int i;

	bVisible = bNewVisibility;
	Show(bNewVisibility);
    //for (i = 0; i < 10; i++ ) objects[i].Show(bNewVisibility);
	for (i = 0; i < 10; i++ ) MMHUDObjectSlot(objects[i]).SetVisibility(bNewVisibility);
}

event DrawWindow(GC gc)
{
	if (!bVisible) return;
	super.DrawWindow(gc);
}

defaultproperties
{
}
