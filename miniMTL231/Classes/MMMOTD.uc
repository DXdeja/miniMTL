class MMMOTD extends Info config(MiniMTL);

var config string MOTDText[8];

replication
{
	reliable if (ROLE == ROLE_Authority)
 		OpenMenu;
	reliable if ((ROLE == ROLE_Authority) && (bNetOwner))
	    MOTDText;
}

function PostBeginPlay()
{
    SaveConfig();
    SetTimer(1.2, false);
}

function Timer()
{
    local miniMTLPlayer mmp;

    mmp = miniMTLPlayer(Owner);
    if (mmp != none && mmp.PlayerReplicationInfo.bIsSpectator)
    {
        OpenMenu(mmp);
    }
}

simulated function OpenMenu(miniMTLPlayer P)
{
    local DeusExRootWindow W;
    local MMEscWindow nw;

	P.ConsoleCommand("FLUSH");
    W = DeusExRootWindow(P.RootWindow);
    nw = MMEscWindow(W.InvokeMenuScreen(Class'MMEscWindow'));
    if (nw != none) nw.SetMOTDText(MOTDText);
}

defaultproperties
{
     MOTDText(0)="Hello..."
     MOTDText(7)="---"
     RemoteRole=ROLE_SimulatedProxy
     bAlwaysRelevant=True
     NetPriority=1.400000
     NetUpdateFrequency=2.000000
}
