class MMSpeedFix extends Info
	config(MiniMTL);

var config int CheckTicks;
var config float Tolerance;
var config bool bPlayerSideLogging;
var config float UpperTimeDilation;

var float cTime;
var int counter;

replication
{
	reliable if (Role == ROLE_Authority)
		SendServerTime, bPlayerSideLogging, UpperTimeDilation;
}

simulated function PostBeginPlay()
{
	log("MiniMTL: Speed fix init.");
}

simulated function Tick(float DeltaTime)
{
	cTime += DeltaTime;
	
	if (Role == ROLE_Authority)
	{
		if (CheckTicks < 10) 
		{
			CheckTicks = 10;
			SaveConfig();
		}
		counter++;
		if (counter >= CheckTicks)
		{
			if (Tolerance > 0.500)
			{
				Tolerance = 0.500;
				SaveConfig();
			}
			else if (Tolerance < 0.001)
			{
				Tolerance = 0.001;
				SaveConfig();
			}
			SendServerTime(cTime, Tolerance);
			counter = 0;
			cTime = 0.0;
		}
	}
}

simulated function SendServerTime(float STime, float t)
{
	if (Role < ROLE_Authority)
	{
		if ((STime > (cTime + t)) || (STime < (cTime - t)))
			SpeedFix(STime / cTime);
		cTime = 0;
	}
}

simulated function SpeedFix(float ddil)
{
	ddil = FClamp(ddil, 0.1, 10.0);
	Level.TimeDilation *= ddil;
	Level.TimeDilation = FClamp(Level.TimeDilation, 0.05, UpperTimeDilation);
	if (bPlayerSideLogging)
		log("MiniMTL: Time dilated to: " $ Level.TimeDilation);
}

defaultproperties
{
    CheckTicks=20
    Tolerance=0.02
    UpperTimeDilation=2.00
    RemoteRole=2
    bOnlyOwnerSee=True
    NetPriority=10.00
}
