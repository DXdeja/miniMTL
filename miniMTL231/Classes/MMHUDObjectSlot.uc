class MMHUDObjectSlot extends CBPHUDObjectSlot;

var bool bVisible;

function SetVisibility(bool bNewVisibility)
{
	bVisible = bNewVisibility;
}

event DrawWindow(GC gc)
{
    //if (!bIsVisible) return;
	if (!bVisible) return;

	// First draw the background
    DrawHUDBackground(gc);

	// Now fill the area under the icon, which can be different
	// colors based on the state of the item.
	//
	// Don't waste time drawing the fill if the fillMode is set
	// to None

	if (fillMode != FM_None)
	{
		SetFillColor();
		gc.SetStyle(DSTY_Translucent);
		gc.SetTileColor(fillColor);
		gc.DrawPattern(
			slotIconX, slotIconY,
			slotFillWidth, slotFillHeight,
			0, 0, Texture'Solid' );
	}

	// Don't draw any of this if we're dragging
	if ((item != None) && (!item.bDeleteMe) && (item.Icon != None) && (!bDragging))
	{
		// Draw the icon
        DrawHUDIcon(gc);

		// Text defaults
		gc.SetAlignments(HALIGN_Center, VALIGN_Center);
		gc.EnableWordWrap(false);
		gc.SetTextColor(colObjectNum);

		// Draw the item description at the bottom
		gc.DrawText(1, 42, 42, 7, item.beltDescription);

		// If there's any additional text (say, for an ammo or weapon), draw it
		if (itemText != "")
			gc.DrawText(slotIconX, itemTextPosY, slotFillWidth, 8, itemText);

		// Draw selection border
		if (bButtonPressed)
		{
			gc.SetTileColor(colSelectionBorder);
			gc.SetStyle(DSTY_Masked);
			gc.DrawBorders(slotIconX - 1, slotIconY - 1, borderWidth, borderHeight, 0, 0, 0, 0, texBorders);
		}
	}
   else if ((item == None) && (player != None) && (player.Level.NetMode != NM_Standalone) && (player.bBeltIsMPInventory))
   {
		// Text defaults
		gc.SetAlignments(HALIGN_Center, VALIGN_Center);
		gc.EnableWordWrap(false);
		gc.SetTextColor(colObjectNum);

		if ((objectNum >=1) && (objectNum <=3))
      {
         gc.DrawText(1, 42, 42, 7, "WEAPONS");
      }
      else if ((objectNum >=4) && (objectNum <=6))
      {
         gc.DrawText(1, 42, 42, 7, "GRENADES");
      }
      else if ( ((objectNum >=7) && (objectNum <=9)) || (objectNum == 0) )
      {
         gc.DrawText(1, 42, 42, 7, "TOOLS");
      }
   }

	// Draw the Object Slot Number in upper-right corner
	gc.SetAlignments(HALIGN_Right, VALIGN_Center);
	gc.SetTextColor(colObjectNum);
	gc.DrawText(slotNumberX - 1, slotNumberY, 6, 7, objectNum);
}


function DrawHUDIcon(GC GC)
{
    GC.SetStyle(DSTY_Masked);
    GC.SetTileColorRGB(255,255,255);
	if ((Item != None) && (!Item.bDeleteMe) && (Item.Icon != None))
    {
        GC.DrawTexture(slotIconX,slotIconY,slotFillWidth,slotFillHeight,0.00,0.00,Item.Icon);
    }
}

defaultproperties
{
}
