class MMEscWindow extends MenuUIScreenWindow;

struct S_MenuButton
{
	var int y;
	var int x;
	var EMenuActions action;
	var class invoke;
	var string key;
};

var MenuUIMenuButtonWindow winButtons[4];

var string ButtonNames[4];

var int buttonWidth;
var S_MenuButton buttonDefaults[4];

var bool isspec;

var bool IsExiting;

var string NewPlayerTitle;
var string NewPlayerContent;
var string NewPlayerContentAug;

var bool bShowAugWarning;
var bool bAugsConfigured;

event InitWindow()
{
	Super.InitWindow();

	if (Player.GameReplicationInfo != none && !Player.GameReplicationInfo.bTeamGame)
	{
		ButtonNames[0] = "Play";
		ButtonNames[1] = "";
		ButtonNames[2] = "";
	}

	IsExiting = true;

	CreateMenuButtons();

    if (Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.bIsSpectator) isspec = true;
    else isspec = false;
}


event FocusLeftDescendant(Window leaveWindow)
{
	super.FocusLeftDescendant(leaveWindow);

	if (bShowAugWarning)
	{
		bShowAugWarning = false;
		root.MessageBox(NewPlayerTitle, NewPlayerContentAug, 1, false, self);
	}
}

function SetMOTDText(string MOTDText[8])
{
	local int i;

	for (i = 0; i < 8; i++) CreateLabel(20, 20 + (i * 15), MOTDText[i]);

	if (miniMTLPlayer(player).AmINewPlayer())
		root.MessageBox(NewPlayerTitle, NewPlayerContent, 0, false, self);
}


event bool BoxOptionSelected(Window box, int buttonNumber)
{
	local MMMenuScreenAugSetup mmaugsetup;

	root.PopWindow();

	if (!bAugsConfigured && buttonNumber == 0)
	{
		mmaugsetup = MMMenuScreenAugSetup(root.InvokeMenuScreen(class'MMMenuScreenAugSetup'));
		mmaugsetup.ResetToDefaults();
		bShowAugWarning = true;
		bAugsConfigured = true;
	}

	return true;
}


final function MenuUISmallLabelWindow CreateLabel(int X, int Y, string S)
{
	local MenuUISmallLabelWindow W;

	W = MenuUISmallLabelWindow(winClient.NewChild(Class'MenuUISmallLabelWindow'));
	W.SetPos(X, Y);
	W.SetText(S);
	W.SetWordWrap(false);

	return W;
}


function CreateMenuButtons()
{
	local int buttonIndex;

	for (buttonIndex = 0; buttonIndex < arrayCount(buttonDefaults); buttonIndex++)
	{
		if (ButtonNames[buttonIndex] != "")
		{
			winButtons[buttonIndex] = MenuUIMenuButtonWindow(winClient.NewChild(Class'MenuUIMenuButtonWindow'));

			winButtons[buttonIndex].SetButtonText(ButtonNames[buttonIndex]);
			winButtons[buttonIndex].SetPos(buttonDefaults[buttonIndex].x, buttonDefaults[buttonIndex].y);
			winButtons[buttonIndex].SetWidth(buttonWidth);
		}
	}
}


function bool ButtonActivated(Window buttonPressed)
{
	local bool bHandled;
	local int  buttonIndex;

	bHandled = False;

	if (Super.ButtonActivated(buttonPressed)) return true;

	// Figure out which button was pressed
	for (buttonIndex = 0; buttonIndex < arrayCount(winButtons); buttonIndex++)
	{
		if (buttonPressed == winButtons[buttonIndex])
		{
			// Check to see if there's somewhere to go
			ProcessMenuAction(buttonDefaults[buttonIndex].action, buttonDefaults[buttonIndex].invoke, buttonDefaults[buttonIndex].key);

			bHandled = True;
			break;
		}
	}

	return bHandled;
}


function ProcessCustomMenuButton(string key)
{
    local miniMTLPlayer mmp;

    mmp = miniMTLPlayer(Player);
    isspec = false;
    if (mmp != none)
    {
        switch(key)
	    {
		    case "SPECTATE":
		        /*if (!mmp.IsInState('Spectating'))*/ mmp.Spectate(1);
		        isspec = true;
			    break;
		    case "JOIN_UNATCO":
		        mmp.NewChangeTeam(0);
		        break;
  		    case "JOIN_NSF":
  		        mmp.NewChangeTeam(1);
		        break;
            case "JOIN_AUTO":
                mmp.NewChangeTeam(2);
                break;
        }
	}

	CancelScreen();
}


function ProcessAction(String S)
{
    local miniMTLPlayer mmp;
    mmp = miniMTLPlayer(Player);

    Super.ProcessAction(S);
    switch (S)
    {
        case "AUGS":
            root.InvokeMenuScreen(class'MMMenuScreenAugSetup');
            break;
        case "DISC":
            Player.DisconnectPlayer();
            break;
         case "SET":
            root.InvokeMenuScreen(class'CBPMenuSettings');
            break;
         case "CANCEL":
			//if (isspec && mmp != none) mmp.ActivateAllHUDElements(false);
			CancelScreen();
        	//root.PopWindow();
            break;
    }
}


function CancelScreen()
{
	local MMDeusExHUD mmdxhud;
	if (isspec) 
	{
		mmdxhud = MMDeusExHUD(root.hud);
		if (mmdxhud.HUD_mode == 2) 
		{
			mmdxhud.HUD_mode = 0;
			mmdxhud.UpdateSettings(Player);
		}
	}

	// Play Cancel Sound
	PlaySound(Sound'Menu_Cancel', 0.25); 

	root.PopWindow();
}

defaultproperties
{
     ButtonNames(0)="Join UNATCO"
     ButtonNames(1)="Join NSF"
     ButtonNames(2)="Auto-assign"
     ButtonNames(3)="Spectate"
     buttonWidth=200
     buttonDefaults(0)=(Y=160,X=10,Action=MA_Custom,Key="JOIN_UNATCO")
     buttonDefaults(1)=(Y=200,X=10,Action=MA_Custom,Key="JOIN_NSF")
     buttonDefaults(2)=(Y=160,X=230,Action=MA_Custom,Key="JOIN_AUTO")
     buttonDefaults(3)=(Y=200,X=230,Action=MA_Custom,Key="SPECTATE")
     NewPlayerTitle="New player detected"
     NewPlayerContent="Server has detected, that you are playing DeusEx Multiplayer for the first time. Would you like to configure your augmentations now?"
     NewPlayerContentAug="Augmentations are very important part of the gameplay. You have to use them in order to be competitive against other players. Open settings menu and configure controlling keys for them."
     actionButtons(0)=(Action=AB_Other,Text="Disconnect",Key="DISC")
     actionButtons(1)=(Action=AB_Other,Text="Settings",Key="SET")
     actionButtons(2)=(Align=HALIGN_Right,Action=AB_Other,Text="Cancel",Key="CANCEL")
     actionButtons(3)=(Action=AB_Other,Text="Augmentations",Key="AUGS")
     Title="Welcome to MiniMTL Server"
     ClientWidth=440
     ClientHeight=240
     bUsesHelpWindow=False
     bEscapeSavesSettings=False
     ScreenType=ST_Menu
}
