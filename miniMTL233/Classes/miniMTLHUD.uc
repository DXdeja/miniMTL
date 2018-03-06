class miniMTLHUD extends HUD;

var Font TestFont;

const LagoMeterX = 0.75;
const LagoMeterY = 0.7;

struct PastLMVars
{
	var int Ping;
	var byte Loss;
	var byte SLoad;
};

var PastLMVars LMVars[100];
var float LastLagometerUpdateTime;
var float LagometerUpdateInterval;

var Texture LagTexture;
var Texture LagometerBack;

simulated function ClearLagometer()
{
	local int i;

	for (i = 0; i < 100; i++)
	{
		LMVars[i].Loss = 0;
		LMVars[i].Ping = 0;
		LMVars[i].SLoad = 0;
	}
	LastLagometerUpdateTime = -999;
}

simulated function AddLagometerValue(int Ping, byte Loss, byte SLoad)
{
	local int i;

	for (i = 0; i < 99; i++)
	{
		LMVars[i].Loss = LMVars[i + 1].Loss;
		LMVars[i].Ping = LMVars[i + 1].Ping;
		LMVars[i].SLoad = LMVars[i + 1].SLoad;
	}
	LMVars[99].Loss = Loss;
	LMVars[99].Ping = Ping;
	LMVars[99].SLoad = SLoad;
}

simulated function DrawLagometer(Canvas canvas, MMLagoMeter LMActor)
{
	local int i, x, y, d;

	if ((Level.TimeSeconds - LagometerUpdateInterval) > LastLagometerUpdateTime)
	{
		LastLagometerUpdateTime = Level.TimeSeconds;
		AddLagometerValue(LMActor.Ping, LMActor.PacketLoss, LMActor.ServerLoad);
	}

	x = canvas.SizeX * LagoMeterX;
	y = canvas.SizeY * LagoMeterY;

	canvas.SetPos(x, y - 50);
	canvas.DrawColor = canvas.Default.DrawColor;
	canvas.DrawRect(LagometerBack, 100, 101);

	for (i = 0; i < 100; i++)
	{
		canvas.CurX = x;
		d = LMVars[i].Ping / 5;
		canvas.CurY = y - d;
		canvas.DrawColor.R = 0;
		canvas.DrawColor.G = 255;
		canvas.DrawColor.B = 0;
		canvas.DrawRect(LagTexture, 1, d);

		canvas.CurX = x;
		d = LMVars[i].Loss / 2;
		canvas.CurY = y - d;
		canvas.DrawColor.R = 255;
		canvas.DrawColor.G = 0;
		canvas.DrawColor.B = 0;
		canvas.DrawRect(LagTexture, 1, d);

		canvas.CurX = x;
		d = LMVars[i].SLoad / 5;
		canvas.CurY = y + 51 - d;
		canvas.DrawColor.R = 0;
		canvas.DrawColor.G = 0;
		canvas.DrawColor.B = 255;
		canvas.DrawRect(LagTexture, 1, d);

		x++;
	}
}

simulated function bool IsHUDVisible()
{
	local DeusExRootWindow root;
	root = DeusExRootWindow(miniMTLPlayer(Owner).rootWindow);
	return root.hud.bIsVisible;
}

simulated event PostRender(canvas Canvas)
{
	super.PostRender(canvas);

	if (miniMTLPlayer(Owner) != none && IsHUDVisible())
	{
		if (miniMTLPlayer(Owner).LMActor != none)
			DrawLagometer(canvas, miniMTLPlayer(Owner).LMActor);
	}
}

defaultproperties
{
    TestFont=Font'DeusExUI.FontMenuSmall_DS'
    LastLagometerUpdateTime=-999.00
    LagometerUpdateInterval=0.05
    LagTexture=Texture'Extension.Solid'
    LagometerBack=Texture'DeusExItems.Skins.BlackMaskTex'
}
