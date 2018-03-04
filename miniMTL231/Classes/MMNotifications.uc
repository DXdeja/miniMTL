class MMNotifications extends Actor config(MiniMTL);

var() config bool bEnabled;
var() config float MessageTime;
var() config float MessageDelay;
var() config string Messages[64];

const tTime = 1.0;

var bool bInit;
var int iMsg;
var float nextTime;

function PostBeginPlay()
{
    if (bInit) return;
    bInit = true;
    if (!bEnabled) return;
    nextTime = MessageDelay;
    log("Notifications are active.", 'miniMTL');
    SaveConfig();
    SetTimer(tTime, true);
}

function Timer()
{
    if (!bEnabled) return;
    if (Level.TimeSeconds >= nextTime)
    {
        if (Messages[iMsg] != "") ShowNotification();
        iMsg++;
        if (iMsg >= 64) iMsg = 0;
        if (Messages[iMsg] == "") iMsg = 0;
        nextTime += MessageTime + MessageDelay;
    }
}

function ShowNotification()
{
    local Pawn P;
    local int i;
    local miniMTLPlayer mmp;
    local color rgb;

    P = Level.PawnList;
    rgb.G = 255;
 	while (i < Level.Game.NumPlayers)
	{
		if (P.IsA('PlayerPawn'))
		{
            mmp = miniMTLPlayer(P);
            if (mmp != none) mmp.ShowNotification(Messages[iMsg], MessageTime, rgb);
			i++;
		}
		P = P.nextPawn;
	}
}

defaultproperties
{
     bEnabled=True
     MessageTime=5.000000
     MessageDelay=30.000000
     Messages(0)="Welcome"
     bHidden=True
     NetUpdateFrequency=1.000000
}
