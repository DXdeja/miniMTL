class MMAugmentationManager extends CBPAugmentationManager;

var const class<MMAugmentation> mpAugs[18]; // 17 + 1 light
var byte mpStatus[18]; // 0 - do not have it, 1 = have it, 2 = active
var DeusExRootWindow root;
var MMAugDummy DummyAug;

var float CBPTargetingLevel;
var float CBPPowerRecLevel;
var float CBPVisionValue;

// aug variables
var float LastHealTime;
var bool bDefenseActive;
var float defenseSoundTime;
var float LastDefenseTime;
var float LastDroneTime;
var MMBeam LightBeam1, LightBeam2;
// 

replication
{
	reliable if (Role == ROLE_Authority && bNetOwner)
		mpStatus;

	reliable if (Role == Role_Authority)
		SetDefenseAugStatus, SetTargetingAugStatus, SetVisionAugStatus;
}

simulated function SetVisionAugStatus(int LevelValue, bool IsActive)
{
   if (player == None)
      return;
   if (root == None)
      return;

   if (IsActive)
   {
      if (++root.hud.augDisplay.activeCount == 1)      
         root.hud.augDisplay.bVisionActive = True;
   }
   else
   {
      if (--root.hud.augDisplay.activeCount == 0)
         root.hud.augDisplay.bVisionActive = False;
      root.hud.augDisplay.visionBlinder = None;
   }
   root.hud.augDisplay.visionLevel = 3;
   root.hud.augDisplay.visionLevelValue = LevelValue;
}

simulated function SetTargetingAugStatus(bool IsActive)
{
   if (player == None)
      return;
   if (root == None)
      return;

	root.hud.augDisplay.bTargetActive = IsActive;
	root.hud.augDisplay.targetLevel = 3;
}

simulated function SetDefenseAugStatus(DeusExProjectile defenseTarget)
{
	local bool bActive;

   if (player == None)
      return;
   if (root == None)
      return;

   if (defenseTarget != none) bActive = true;
   root.hud.augDisplay.bDefenseActive = bActive;
   root.hud.augDisplay.defenseLevel = 3;
   root.hud.augDisplay.defenseTarget = defenseTarget;
}

function PostBeginPlay()
{
	// spawn dummy aug to handle Deactivate calls
	DummyAug = Spawn(class'MMAugDummy', self);
	super.PostBeginPlay();
}

event Destroyed()
{
	if (DummyAug != none) DummyAug.Destroy();
	super.Destroyed();
}

function Tick(float DeltaTime)
{
	local int i;

	super.Tick(DeltaTime);

	if (player == none) return; // this is here, because MTL keeps augmanager alive for some time
								// to keep players stuff due to GPF
	for (i = 0; i < 18; i++)
	{
		mpAugs[i].static.StaticTick(player, DeltaTime);
	}
}

simulated function SetRootWindow()
{
	if (player != none) root = DeusExRootWindow(player.rootWindow);
}

function CreateAugmentations(DeusExPlayer newPlayer)
{
	player = newPlayer;
}

function AddDefaultAugmentations()
{
	// do nothing!
}

simulated function AddAugmentationDisplay(class<MMAugmentation> augc, bool enabled)
{
	if (augc != none)
	{
		if (root == none)
			SetRootWindow();
		if (root != none)
		{
			MMHUDActiveItemsDisplay(root.hud.activeItems).AddAug(augc, enabled);
		}
	}
}

simulated function RefreshAugDisplay()
{
	local int i;

	if (player == none || Role == ROLE_Authority) return;

	// First make sure there are no augs visible in the display
	player.ClearAugmentationDisplay();

	for (i = 0; i < 18; i++)
	{
		if (mpStatus[i] == 1 && player.bHUDShowAllAugs)
		{
			AddAugmentationDisplay(mpAugs[i], false);
		}
		else if (mpStatus[i] == 2)
		{
			AddAugmentationDisplay(mpAugs[i], true);
		}
	}
}

simulated function int NumAugsActive()
{
	local int i;
	local int count;

	if (player == None)
		return 0;

	for (i = 0; i < 18; i++)
	{
		if (mpStatus[i] == 2)
		{
			count++;
		}
	}

	return count;
}

function SetPlayer(DeusExPlayer newPlayer)
{
	player = newPlayer;
}

function BoostAugs(bool bBoostEnabled, Augmentation augBoosting)
{
}

simulated function int GetClassLevel(class<Augmentation> augClass)
{
	local int i;

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.OldAugClass == augClass)
		{
			if (mpStatus[i] == 2) return 3;
			break;
		}
	}

	return -1;
}

simulated function float GetAugLevelValue(class<Augmentation> AugClass)
{
	local int i;

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.OldAugClass == AugClass || mpAugs[i] == AugClass)
		{
			if (mpStatus[i] == 2)
			{
				if (mpAugs[i] == class'MMAugTarget' && IsCBP()) return CBPTargetingLevel;
				else if (mpAugs[i] == class'MMAugPower' && IsCBP()) return CBPPowerRecLevel;
				else if (mpAugs[i] == class'MMAugVision' && IsCBP()) return CBPVisionValue;
				else return mpAugs[i].default.LevelValues[3];
			}
			else return -1.0;
		}
	}

	return -1.0;
}

simulated function float GetAugLevelValueWithIgnoredState(class<Augmentation> AugClass)
{
	local int i;

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.OldAugClass == AugClass || mpAugs[i] == AugClass)
		{
			if (mpAugs[i] == class'MMAugTarget' && IsCBP()) return CBPTargetingLevel;
			else if (mpAugs[i] == class'MMAugPower' && IsCBP()) return CBPPowerRecLevel;
			else if (mpAugs[i] == class'MMAugVision' && IsCBP()) return CBPVisionValue;
			else return mpAugs[i].default.LevelValues[3];
		}
	}

	return -1.0;
}

function ActivateAll()
{
	local int i;
	local bool bAugsWithFlag;

	bAugsWithFlag = AugsWithFlag();

	if ((player != None) && (player.Energy > 0))
	{
		for (i = 0; i < 17; i++) // without light aug
		{
			if (mpStatus[i] == 1 && (bAugsWithFlag || IsAllowedFlagAug(mpAugs[i])))
				mpAugs[i].static.AugActivate(player);
		}
	}
}

function DeactivateAll()
{
	local int i;

	for (i = 0; i < 18; i++)
	{
		if (mpStatus[i] == 2)
			mpAugs[i].static.AugDeactivate(player);
	}
}

// deprecated!
simulated function Augmentation FindAugmentation(Class<Augmentation> findClass)
{
	local int i;

	if (DummyAug == none) 
	{
		Log("WARNING: DummyAug is none!");
		return none;
	}

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.OldAugClass == findClass)
		{
			if (mpStatus[i] > 0)
			{
				DummyAug.AugAffected = mpAugs[i];
				return DummyAug;
			}
			break;
		}
	}

	return none;
}

// deprecated! do not call it!
function Augmentation GivePlayerAugmentation(Class<Augmentation> giveClass)
{
	return none;
}

function bool NewGivePlayerAugmentation(class<MMAugmentation> giveClass)
{
	local int i;

	if (giveClass == none) return false;

	// check if we already have aug @ that slot
	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.MPConflictSlot == giveClass.default.MPConflictSlot)
		{
			if (mpStatus[i] > 0) // already have it
				return false;
		}
	}

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i] == giveClass)
		{
			mpStatus[i] = 1;
			return true;
		}
	}

	return false;
}

function bool AugsWithFlag()
{
	local miniMTLCTF game;
	local miniMTLPlayer p;

	game = miniMTLCTF(level.game);
	if (game == none) return true;
   
	player = miniMTLPlayer(player);
   
	if (p.getPRI().Flag == none)
		return true;

	//player has a flag!
	//allow augs with flag + not escaping
	if (game.bAugsWithFlag)
	{
		if (!p.getPRI().flag.bEscaping)
		return true;
	}

	//player.serverConditionalNotifyMsg(player.MPMSG_NoAugsWithFlag);
   
	return false;
}

simulated function bool IsAllowedFlagAug(class<MMAugmentation> aug)
{
	local int i;
	local miniMTLCTF ctfgame;

	ctfgame = miniMTLCTF(Level.Game);
	if (ctfgame == none) return true;

	for (i = 0; i < ArrayCount(ctfgame.FlagDisabledAugs); i++)
	{
		if (ctfgame.FlagDisabledAugs[i] == aug) return false;
	}

	return true;
}

function bool ActivateAugByKey(int keyNum)
{
	local int i;
	local class<MMAugmentation> faug;

	if ((keyNum < 0) || (keyNum > 9))
		return False;

	keyNum += 3;

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i].default.MPConflictSlot == keyNum)
		{
			if (mpStatus[i] > 0)
			{
				faug = mpAugs[i];
				break;
			}
		}
	}

	if (faug == none)
	{
		player.ClientMessage(NoAugInSlot);
		return false;
	}

	if (!AugsWithFlag() && !IsAllowedFlagAug(faug))
	{
		Player.ClientMessage("Cannot use this augmentation while carrying the flag!");
		return false;
	}

	return faug.static.AugToggle(player);
}

function DeactivateCTFAugs()
{
	local int i;

	for (i = 0; i < 18; i++)
	{
		if (mpStatus[i] == 2 && !IsAllowedFlagAug(mpAugs[i]))
			mpAugs[i].static.AugDeactivate(player);
	}
}

simulated function bool IsCBP()
{
	if ((miniMTLTeam(Level.Game) != none && miniMTLTeam(Level.Game).bCBP) || 
		(miniMTLDeathMatch(Level.Game) != none && miniMTLDeathMatch(Level.Game).bCBP))
		return true;
	else return false;
}

simulated function Float CalcEnergyUse(float deltaTime)
{
	local float energyUse, energyMult;
	local int i;
	local bool bHasPowerAug;
	local bool bPowerAugOn;

	energyUse = 0;
	energyMult = 1.0;

	for (i = 0; i < 18; i++)
	{
		if (mpAugs[i] == class'MMAugPower')
		{
			if (mpStatus[i] > 0) bHasPowerAug = true;
			if (mpStatus[i] == 2) bPowerAugOn = true;
		}

		if (mpStatus[i] == 2)
		{
			energyUse += ((mpAugs[i].static.NewGetEnergyRate() / 60) * deltaTime);
		}
	}

	if (bHasPowerAug)
	{
		if (energyUse > 0 && !bPowerAugOn)
			ActivateAugByKey(4);

		if (energyUse == 0 && bPowerAugOn)
			ActivateAugByKey(4);

		if (bPowerAugOn)
			energyMult = GetAugLevelValue(class'MMAugPower');
	}

	energyUse *= energyMult;

	return energyUse;
}

function ResetAugmentations()
{
	local int i;

	for (i = 0; i < 17; i++)
	{
		mpAugs[i].static.AugDeactivate(player);
		mpStatus[i] = 0;
	}

	// turn off light
	mpAugs[17].static.AugDeactivate(player);
	LastDroneTime = default.LastDroneTime;
}

defaultproperties
{
    mpAugs(0)=Class'MMAugSpeed'
    mpAugs(1)=Class'MMAugTarget'
    mpAugs(2)=Class'MMAugCloak'
    mpAugs(3)=Class'MMAugBallistic'
    mpAugs(4)=Class'MMAugRadarTrans'
    mpAugs(5)=Class'MMAugShield'
    mpAugs(6)=Class'MMAugEnviro'
    mpAugs(7)=Class'MMAugEMP'
    mpAugs(8)=Class'MMAugCombat'
    mpAugs(9)=Class'MMAugHealing'
    mpAugs(10)=Class'MMAugStealth'
    mpAugs(11)=Class'MMAugMuscle'
    mpAugs(12)=Class'MMAugVision'
    mpAugs(13)=Class'MMAugDrone'
    mpAugs(14)=Class'MMAugDefense'
    mpAugs(15)=Class'MMAugAqualung'
    mpAugs(16)=Class'MMAugPower'
    mpAugs(17)=Class'MMAugLight'
    mpStatus(17)=1
    CBPTargetingLevel=-0.15
    CBPPowerRecLevel=0.55
    CBPVisionValue=1000.00
    lastDroneTime=-30.00
    bTravel=False
    NetPriority=1.80
}
