class miniMTLPlayer extends MTLPlayer abstract;

var(Sounds)	sound	HitSound3;
var(Sounds) sound   SoundEyePain;
var(Sounds) sound   SoundDrown;
var(Sounds) sound   SoundWaterDeath;
var(Sounds) sound   SoundGasp;

var globalconfig bool bSpawnBlood;
var globalconfig bool bSpawnTracers;
var globalconfig bool bSpawnFlesh;
var globalconfig bool bSpawnShellCasings;
var globalconfig bool bSpawnOtherVisualEffects;

var globalconfig bool bDisplayAugMessages;
var globalconfig bool bDisplayPickupMessages;

// out of MTL
var byte MeshType;
var byte V68; // only JCDenton has this to 1, probably related to glasses (if Mesh=LodMesh'DeusExCharacters.GM_Trench')
var bool V7C;
var texture V6B[3];

var class<miniMTLPlayer> SkinClasses[2]; // in team game, both are populated, in DM, only first

var string notfMSG_Text;
var float notfMSG_Time;
var float notfMSG_EndTime;
var color notfMSG_Color;

var MMMOTD PlayerMOTDWindow;

var bool FreeSpecMode;
var bool ClientFreeSpecMode;
var float SpecPlayerChangedTime;

var int View_RotPitch;
var int View_RotYaw;

/* replicated to spectator */
var int TargetView_RotPitch;
var int TargetView_RotYaw;
var int TargetAugs; // augs packed into bits, lower ones - available, higher ones -> active slots
var bool bTargetAlive;
var int TargetSkillsAvail;
var int TargetSkills;
var byte TargetBioCells;
var byte TargetMedkits;
var byte TargetMultitools;
var byte TargetLockpicks;
var byte TargetLAMs;
var byte TargetGGs;
var byte TargetEMPs;
var class<DeusExWeapon> TargetWeapons[3];
var bool bSpecEnemies;
/* ---------------- */

var bool bExiting;
var bool bCTFWantsToPlay;
var float CTFRespawnTime;

// for newbies
var bool bDisplaySkillMessageForever;


// CTF
var bool bAugsDisabled;

var sound enemyCaptureSound;
var sound friendlyCaptureSound;
var sound enemyDropSound;
var sound friendlyDropSound;
var sound enemyReturnSound;
var sound friendlyReturnSound;
var sound friendlyTakeSound;

var string flagTakeString;
var string flagCaptureString;
var string flagReturnString;
var string flagDropString;


var float LastSpecChangeTime;

var globalconfig bool bPerformZoomOnRightClick;
var globalconfig bool bColoredTalkMessages;

var bool bModerator;

var MMLagoMeter LMActor;

var bool bFirstTimeReported;

var MMSpeedFix SFActor;

var bool bForceWhiteCrosshair;
var bool bAllowBehindView;

replication
{
    reliable if (ROLE == ROLE_Authority)
        clientStopFiring, SetPlayerNetSpeed, ClientSetTeam;
    unreliable if (ROLE == ROLE_Authority && bNetOwner)
        ShowNotification;
    reliable if (ROLE < ROLE_Authority)
        SpectateX, NewChangeTeam, ToggleFreeMode, NextPlayer, bExiting;
    reliable if (bNetOwner && ROLE == ROLE_Authority)
        PlayerMOTDWindow, FreeSpecMode, bSpecEnemies, bDisplaySkillMessageForever,
        ActivateAllHUDElements, bCTFWantsToPlay, SetClientStartTime;

   	unreliable if (Role < ROLE_Authority && bNetOwner)
		View_RotPitch, View_RotYaw;

   	reliable if (bNetOwner && Role==ROLE_Authority)
		TargetView_RotPitch, TargetView_RotYaw, TargetAugs, bTargetAlive,
        TargetSkillsAvail, TargetSkills, TargetBioCells, TargetMedkits,
        TargetMultitools, TargetLockpicks, TargetLAMs, TargetGGs, TargetEMPs,
        TargetWeapons;

	reliable if (role == ROLE_Authority)
		flagTake,
		flagDrop,
		flagCapture,
		flagReturn,
		flagEscape;

	reliable if (role < ROLE_Authority)
		dropFlag;

	reliable if (Role == ROLE_Authority)
		MeshType, MultiplayerDeathMsgCTF, DoSomeFixes;

	unreliable if (Role == ROLE_Authority)
		ClientSpawnBloodFromWeapon, ClientSpawnBloodFromProjectile,
		ClientSpawnTracerFromWeapon, ClientSpawnShellCasing,
		ClientSpawnFleshFragments, ClientSpawnSpark, ClientSpawnTurretEffects,
		ClientSpawnSniperTracerFromWeapon;

	reliable if (Role < ROLE_Authority)
		bPerformZoomOnRightClick, ModLogin, ModLogout, TempBan, Swap, ForceName, ServerLagoMeter, ServerReportNewPlayer;

	reliable if (Role == ROLE_Authority && bNetOwner)
		LMActor, SkinClasses, SFActor, bForceWhiteCrosshair, bAllowBehindView;

	reliable if (Role < ROLE_Authority)
		bDisplayAugMessages;
}

exec function BehindView(bool B)
{
	if (IsInState('PlayerWalking') || IsInState('PlayerSwimming'))
		if (B && !bAllowBehindView) return;
	
	super.BehindView(B);
}

exec function ToggleBehindView()
{
	if (IsInState('PlayerWalking') || IsInState('PlayerSwimming'))
		if (!bBehindView && !bAllowBehindView) return;

	super.ToggleBehindView();
}

function InitMMFixes()
{
	local miniMTLSettings SettingsRef;

	if (miniMTLDeathMatch(Level.Game) != none)
		SettingsRef = miniMTLDeathMatch(Level.Game).Settings;
	else if (miniMTLTeam(Level.Game) != none)
		SettingsRef = miniMTLTeam(Level.Game).Settings;

	if (SettingsRef != none)
	{
		if (SettingsRef.bSpeedFix && SFActor == none)
			SFActor = Spawn(class'MMSpeedFix', self);

		bForceWhiteCrosshair = SettingsRef.bForceWhiteCrosshair;
		bAllowBehindView = SettingsRef.bAllowBehindView;
	}
}

function byte GetSkinClassIndex()
{
	if (Level.Game.bTeamGame) return PlayerReplicationInfo.Team;
	else return 0;
}

function SetSkin()
{
	local int i;

	// reset skin to correct one
	//log("skin class is: " $ SkinClasses[PlayerReplicationInfo.Team]);
	if (SkinClasses[PlayerReplicationInfo.Team] != none)
	{
		for (i = 0; i < 8; i++)
		{
			MultiSkins[i] = SkinClasses[PlayerReplicationInfo.Team].default.MultiSkins[i];
		}

		// set sounds
		//JumpSound = SkinClasses[PlayerReplicationInfo.Team].default.JumpSound;
		//HitSound1 = SkinClasses[PlayerReplicationInfo.Team].default.HitSound1;
		//HitSound2 = SkinClasses[PlayerReplicationInfo.Team].default.HitSound2;
		//HitSound3 = SkinClasses[PlayerReplicationInfo.Team].default.HitSound3;
		//Die = SkinClasses[PlayerReplicationInfo.Team].default.Die;
		//SoundEyePain = SkinClasses[PlayerReplicationInfo.Team].default.SoundEyePain;
		//SoundDrown = SkinClasses[PlayerReplicationInfo.Team].default.SoundDrown;
		//SoundWaterDeath = SkinClasses[PlayerReplicationInfo.Team].default.SoundWaterDeath;
		//SoundGasp = SkinClasses[PlayerReplicationInfo.Team].default.SoundGasp;
	}
}

function ServerReportNewPlayer()
{
	log(PlayerReplicationInfo.PlayerName $ "(" $ PlayerReplicationInfo.PlayerID $ ") is first time player.");
}

simulated function bool AmINewPlayer()
{
	local int i;

	if (!bHelpMessages) return false;

	for (i = 0; i < 9; i++)
		if (AugPrefs[i] != class'menuscreenaugsetup'.default.AugPrefs[i]) return false;

	if (!bFirstTimeReported)
	{
		ServerReportNewPlayer();
		bFirstTimeReported = true;
	}

	return true;
}

function MultiplayerDeathMsgCTF( Pawn killer, bool killedSelf, bool valid, String killerName, String killerMethod, float respawnTime )
{
	local MMMultiplayerMessageWin	mmw;
	local DeusExRootWindow			root;

	myKiller = killer;
	if ( killProfile != None )
	{
		killProfile.bKilledSelf = killedSelf;
		killProfile.bValid = valid;
	}
	root = DeusExRootWindow(rootWindow);
	if ( root != None )
	{
		mmw = MMMultiplayerMessageWin(root.InvokeUIScreen(Class'MMMultiplayerMessageWin', True));
		if ( mmw != None )
		{
			mmw.SetRespawnTime(respawnTime);
			mmw.bKilled = true;
			mmw.killerName = killerName;
			mmw.killerMethod = killerMethod;
			mmw.bKilledSelf = killedSelf;
			mmw.bValidMethod = valid;
		}
	}
}


function HidePlayer()
{
	Super(Human).HidePlayer();
	MeshType=2;
}

function SetClientStartTime(float t) {}

function UpdateTranslucency(float VAE)
{
	local bool VC0;

	if (Level.NetMode == 0) return;
	super.UpdateTranslucency(VAE);

	VC0 = False;

	if (AugmentationSystem.GetAugLevelValue(Class'AugCloak') != -1.00 ) VC0 = True;

	if ((inHand != None) && inHand.IsA('DeusExWeapon') && VC0) VC0 = False;

	if (UsingChargedPickup(Class'AdaptiveArmor')) VC0 = True;

	if (bHidden)
	{
		MeshType = 2;
	}
	else
	{
		if (VC0)
		{
			MeshType = 1;
		}
		else
		{
			MeshType = 0;
		}
	}

	if (!V7C)
	{
		V6B[0] = MultiSkins[5];
		V6B[1] = MultiSkins[6];
		V6B[2] = MultiSkins[7];
		V7C = true;
	}

	if (VC0)
	{
		if (V68 == 1)
		{
			MultiSkins[6]=Texture'BlackMaskTex';
			MultiSkins[7]=Texture'BlackMaskTex';
		}
		//else
		//{
		//	if (V68 == 2)
		//	{
		//		MultiSkins[5]=Texture'BlackMaskTex';
		//		MultiSkins[6]=Texture'BlackMaskTex';
		//	}
		//}
	}
	else
	{
		if (V68 == 1)
		{
			MultiSkins[6] = V6B[1];
			MultiSkins[7] = V6B[2];
		}
		//else
		//{
		//	if (V68 == 2)
		//	{
		//		MultiSkins[5]=V6B[0];
		//		MultiSkins[6]=V6B[1];
		//	}
		//}
	}
}


function miniMTLCTF getCTFGame()
{
	return miniMTLCTF(Level.Game);
}


simulated function setAugsDisabled(bool bAugsDisabled)
{
   local Augmentation aug;

   self.bAugsDisabled = bAugsDisabled;

   //make sure the HUD updates itself (doh!)
   for (aug=augmentationSystem.firstAug; aug!=none; aug=aug.next)
      updateAugmentationDisplayStatus(aug);
}


exec function dropFlag()
{
   //the flag will figure it out sooner or later
   getPRI().Flag = none;
}


simulated function flagTake(miniMTLCTFFlag flag, int playerID, bool friendly)
{
   //if its me, set my augs disabled (is purely for aesthetic reasons,
   //you still cant actually USE the augs)
   if (playerID == playerReplicationInfo.playerID)
      setAugsDisabled(true);
   if (friendly) flagMsg(playerID, flagTakeString, flag, friendlyTakeSound, !friendly);
   else
   {
	  flagMsg(playerID, flagTakeString, flag, none, !friendly);
	  if (ROLE < ROLE_Authority) Spawn(class'miniMTLCTFAlarm');
   }
   if (role < ROLE_Authority)
      flag.CL_take(playerID);
}


simulated function flagEscape(miniMTLCTFFlag flag)
{
   //if (flag.carrierID == playerReplicationInfo.playerID)
   //   setAugsDisabled(false);
   if (role < ROLE_Authority)
      flag.CL_escape();
}


simulated function flagDrop(miniMTLCTFFlag flag, vector location, bool friendly)
{
	if (friendly) flagMsg(flag.carrierID, flagDropString, flag, friendlyDropSound);
	else flagMsg(flag.carrierID, flagDropString, flag, enemyDropSound);
   if (flag.carrierID == playerReplicationInfo.playerID)
      setAugsDisabled(false);
   if (role < ROLE_Authority)
      flag.CL_drop(location);
}


simulated function flagReturn(miniMTLCTFFlag flag, int playerID, bool friendly)
{
	if (friendly) flagMsg(playerID, flagReturnString, flag, friendlyReturnSound);
	else flagMsg(playerID, flagReturnString, flag, enemyReturnSound);
   if (role < ROLE_Authority)
      flag.CL_return(playerID);
}


simulated function flagCapture(miniMTLCTFFlag flag, bool friendly)
{
	if (friendly) flagMsg(flag.carrierID, flagCaptureString, flag, friendlyCaptureSound);
	else flagMsg(flag.carrierID, flagCaptureString, flag, enemyCaptureSound);
   if (flag.carrierID == playerReplicationInfo.playerID)
      setAugsDisabled(false);
   if (role < ROLE_Authority)
      flag.CL_capture();

}


simulated function flagMsg(int playerID, string msg, miniMTLCTFFlag flag,
   optional sound snd, optional bool red)
{
   local MMPRI pri;
   local Color col;

   pri = IDToPRI(playerID);
   if (pri == none) return;

   //clientMessage(sprintf(msg, pri.playerName, flag.itemName));
   if (red) col.R = 255;
   else col.G = 255;
   ShowNotification(sprintf(msg, pri.playerName, flag.itemName), 6.0, col);

   if (snd != none) logSound(snd);
}


simulated function logSound(sound snd)
{
   //no 'none' checks
   playOwnedSound(snd, SLOT_None, transientSoundVolume*1.5, , 2048);
   //DeusExRootWindow(rootWindow).hud.msgLog.playLogSound(snd);
}


function MMPRI getPRI()
{
   return MMPRI(playerReplicationInfo);
}


simulated function MMPRI IDToPRI(int playerID)
{
   local int i;

   for (i=0; i<32; i++)
   {
      if (gameReplicationInfo.priArray[i] != none)
      {
         if (gameReplicationInfo.priArray[i].playerID == playerID)
            return MMPRI(gameReplicationInfo.priArray[i]);
      }
   }

   return none;
}


event Possess()
{
	local MMNetSpeed netspeed;
    local DeusExRootWindow w;
    Super.Possess();
    w = DeusExRootWindow(RootWindow);
   	if (w != None)
	{
	    if (w.hud != None)
		{
			w.hud.Destroy();
		}
		w.hud = DeusExHUD(w.NewChild(Class'MMDeusExHUD'));
		w.hud.UpdateSettings(self);
		w.hud.SetWindowAlignments(HALIGN_Full,VALIGN_Full,0.00,0.00);
	}
	netspeed = Spawn(class'MMNetSpeed');
	netspeed.PlayerToMod = self;
}


simulated function CreatePlayerTracker()
{
   local MMMPlayerTrack PlayerTracker;

   PlayerTracker = Spawn(class'MMMPlayerTrack');
   PlayerTracker.AttachedPlayer = self;
}


function ShowNotification(string text, float timesec, color col)
{
    notfMSG_Color = col;
    notfMSG_Time = timesec;
    notfMSG_Text = text;
    notfMSG_EndTime = Level.TimeSeconds + timesec;
}


/**
  Spawning the Skin checker to reset the skin if required.
*/
function PostBeginPlay()
{
    super.PostBeginPlay();

    //if (level.Game.bTeamGame) Spawn(class'MMSkinReset',self);

    Spawn(class'_MMConsoleChecker',self);
    PlayerMOTDWindow = Spawn(class'MMMOTD',self);
	if (Role == ROLE_Authority)
	{
		InitMMFixes();
	}
}


function SetSpectatorStartPoint()
{
    local vector SpecLocation;
    local string str, map;
    local rotator rotr;
	local bool locset;
	local SpawnPoint sp;

	foreach AllActors(class'SpawnPoint', sp)
	{
		if (sp.Tag == 'Spectator')
		{
			SpecLocation = sp.Location;
			rotr = sp.Rotation;
			locset = true;
			break;
		}
	}

	if (!locset)
	{
		str = string(self);
		map = Left(str, InStr(str, "."));
		class'MMSpectatorStartPoints'.static.GetSpectatorStartPoint(map, SpecLocation, rotr);
	}

    SetLocation(SpecLocation);
    SetRotation(rotr);
    ViewRotation = rotr;
}


simulated function SetPlayerNetSpeed(int speed)
{
	ConsoleCommand(string('Netspeed') @ string(speed));
}


/**
  New <i>server -> client</i> function to tell the client to stop with firing.
  In this case the client is supposed to stop, if the player jumps into the water.
*/
simulated function clientStopFiring()
{
    DeusExWeapon(inHand).GotoState('SimFinishFire');
    DeusExWeapon(inHand).PlayIdleAnim();
}


/**
  Extended state swimming for fixing the water bug.
*/
state PlayerSwimming
{
    /**
      Checks if the weapon is able to work under water, if not it forces the client to stop with firing.
    */
    function BeginState()
    {
        super.BeginState();
        if(DeusExWeapon(inHand) != none)
          if ((DeusExWeapon(inHand).EnviroEffective == ENVEFF_Air) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_Vacuum) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_AirVacuum))
          {
             DeusExWeapon(inHand).GotoState('FinishFire');
             clientStopFiring();
          }

    }

    /**
      Modified fire command-function which just makes the weapon firing, if it's able to fire under water.
      So that the player caN't try to continue firing under water if he presses the fire button again.
    */
    exec function Fire(optional float F)
    {
        if(DeusExWeapon(inHand) != none)
          if((DeusExWeapon(inHand).EnviroEffective == ENVEFF_Air) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_Vacuum) || (DeusExWeapon(inHand).EnviroEffective == ENVEFF_AirVacuum))
            return;

        super.Fire(f);
    }

    function EndState()
    {
        super.EndState();
        SetSpectatorVariablesAtEnd();
    }

    function MultiplayerTick(float deltaTime)
    {
        SetSpectatorVariables();
        super.MultiplayerTick(deltaTime);
    }
}


// this is called after player logins
// fixes bug of grenades owner after gpf
function FixInventory()
{
    local Inventory inv;

    inv = Inventory;
    while (inv != none)
    {
        inv.Instigator = self;
        inv = inv.Inventory;
    }
}


function InitializeSubSystems()
{
	local Skill VAC;

	if ((Level.NetMode == 0) && (BarkManager == None))
	{
		BarkManager=Spawn(Class'BarkManager',self);
	}
	CreateColorThemeManager();
	if ( ThemeManager != None )	ThemeManager.SetOwner(self);

	if ( Level.NetMode != 0 )
	{
		if ((AugmentationSystem != None) && !AugmentationSystem.IsA('MMAugmentationManager'))
		{
			//AugmentationSystem.ResetAugmentations();
			AugmentationSystem.Destroy();
			AugmentationSystem=None;
		}
		if ((SkillSystem != None) && !SkillSystem.IsA('MMSkillManager'))
		{
			SkillSystem.Destroy();
			SkillSystem = none;
		}
	}
	if (AugmentationSystem == None)
	{
		AugmentationSystem = Spawn(Class'MMAugmentationManager', self);
		AugmentationSystem.CreateAugmentations(self);
		//AugmentationSystem.AddDefaultAugmentations();
	}
    else
    {
		AugmentationSystem.SetPlayer(self);
		AugmentationSystem.SetOwner(self);
	}
	if (SkillSystem == None)
	{
		SkillSystem=Spawn(Class'MMSkillManager',self);
		SkillSystem.CreateSkills(self);
	}
    else
    {
		SkillSystem.SetPlayer(self);
		SkillSystem.SetOwner(self);
	}
	if ((Level.NetMode == 0) || !bBeltIsMPInventory) CreateKeyRing();
}


exec function bool SwitchToBestWeapon()
{
    return false;
}


function SpectateX(int act)
{
	if ((Level.TimeSeconds - 1.0) < LastSpecChangeTime) return;
	LastSpecChangeTime = Level.TimeSeconds;
	if (act == 1) GotoState('Spectating');
}


exec function Spectate(int act)
{
	local MultiplayerMessageWin	mmw;
	local DeusExRootWindow		root;

    root = DeusExRootWindow(rootWindow);
    if (root != None)
    {
        if (root.GetTopWindow() != None)
			mmw = MultiplayerMessageWin(root.GetTopWindow());
        if (mmw == none) SpectateX(act);
    }
}


state Spectating
{
    ignores SeePlayer, HearNoise, Bump, TakeDamage, Died, ZoneChange, FootZoneChange, ActivateAllAugs, ActivateAugmentation, ActivateBelt,
        DualmapF3, DualmapF4, DualmapF5, DualmapF6, DualmapF7, DualmapF8, DualmapF9, DualmapF10, DualmapF11, DualmapF12;

    exec function BuySkills()
    {
        if (FreeSpecMode || bBehindView) return;
        super.BuySkills();
    }

    simulated function HUDActiveAug FindAugWindowByKey(HUDActiveAugsBorder border, int HotKeyNum)
    {
    	local Window currentWindow;
    	local Window foundWindow;

    	// Loop through all our children and check to see if
    	// we have a match.

    	currentWindow = border.winIcons.GetTopChild(False);

    	while(currentWindow != None)
    	{
    		if (HUDActiveAug(currentWindow).HotKeyNum == HotKeyNum)
    		{
	    		foundWindow = currentWindow;
	    		break;
	    	}

	    	currentWindow = currentWindow.GetLowerSibling(False);
    	}

    	return HUDActiveAug(foundWindow);
    }


    simulated function DrawRemotePlayersAugIcon(HUDActiveAugsBorder border, int HotKeyNum, texture newIcon, bool active)
    {
    	local HUDActiveAug augItem;

    	augItem = FindAugWindowByKey(border, HotKeyNum);

    	if (augItem != None)
    	{
	    	augItem.SetIcon(newIcon);
		    augItem.SetKeyNum(HotKeyNum);
	    	if (active) augItem.colItemIcon = augItem.colAugActive;
		    else augItem.colItemIcon = augItem.colAugInactive;
		    augItem.Show();

		    // Hide if there are no icons visible
		    if (++border.iconCount == 1)
			    border.Show();

		    border.AskParentForReconfigure();
	    }
    }


    simulated function DrawRemotePlayersAugs(miniMTLPlayer P, bool fpv)
    {
        local DeusExRootWindow root;
        local MMDeusExHUD mmdxhud;
        local int i;
        local class<MMAugmentation> aug;
        local bool active;

        root = DeusExRootWindow(rootWindow);
	    if (root == none) return;
        mmdxhud = MMDeusExHUD(root.hud);
        if (mmdxhud == none) return;

        mmdxhud.activeItems.winAugsContainer.ClearAugmentationDisplay();

        if (!fpv) return;

        for (i = 0; i < ArrayCount(class'MMAugmentationManager'.default.mpAugs); i++)
        {
            if ((P.TargetAugs & (1 << i)) == (1 << i))
            {
/*                if (i == 11) aug = class'AugPower';
                else*/
            	aug = class'MMAugmentationManager'.default.mpAugs[i];
                active = (P.TargetAugs & (0x40000000 >> aug.default.MPConflictSlot)) == (0x40000000 >> aug.default.MPConflictSlot);
                DrawRemotePlayersAugIcon(mmdxhud.activeItems.winAugsContainer, aug.default.MPConflictSlot, aug.default.smallIcon, /*P.TargetAugs[i] == ACTIVE*/ active);
            }
        }
    }

   	event PlayerTick(float DeltaTime)
	{
	    RefreshSystems(DeltaTime);
		MultiplayerTick(DeltaTime);
		UpdateTimePlayed(DeltaTime);
		if (bUpdatePosition) ClientUpdatePosition();
		PlayerMove(DeltaTime);
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		//Acceleration = Normal(NewAccel);
		//Velocity = Normal(NewAccel) * 300;
	    //AutonomousPhysics(DeltaTime);
	    Acceleration = NewAccel * 0.5;
		MoveSmooth(Acceleration * DeltaTime);
	}

	function PlayerMove(float DeltaTime)
	{
		local rotator newRotation;
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		UpdateRotation(DeltaTime, 1);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
	}

	function FixElectronicDevices()
    {
        local ComputerSecurity cs;
	    local int cameraIndex;
	    local name tag;
	    local SecurityCamera camera;
        local AutoTurret turret;
        local DeusExMover door;

        foreach AllActors(class'ComputerSecurity', cs)
        {
            //cs.team = -1;
            //if (cs.Owner != self) continue;

            for (cameraIndex=0; cameraIndex<ArrayCount(cs.Views); cameraIndex++)
	        {
		        tag = cs.Views[cameraIndex].cameraTag;
		        if (tag != '')
                    foreach AllActors(class'SecurityCamera', camera, tag)
                    {
                        if (camera.safeTarget == self)
                        {
				            camera.team = -1;
				            camera.safeTarget = none;
                        }
		            }

                tag = cs.Views[cameraIndex].turretTag;
		        if (tag != '')
			        foreach AllActors(class'AutoTurret', turret, tag)
			        {
			            if (turret.safeTarget == self)
			            {
                            //turret.SetOwner(none);
                            turret.team = -1;
                            turret.safeTarget = none;
                        }
                    }
            }
  	    }
    }

	function BeginState()
	{
	    local DeusExRootWindow root;
	    local inventory anItem;
	    local Pawn P;
	    local AutoTurret turr;
		local MMPRI pri;

	    if (AugmentationSystem != None)
        {
            AugmentationSystem.DeactivateAll();
        }
	    StopZoom();
	    if (CarriedDecoration != None) DropDecoration();
	    if (PlayerReplicationInfo != none)
	    {
            PlayerReplicationInfo.Score = 0;
            PlayerReplicationInfo.Deaths = 0;
            PlayerReplicationInfo.Streak = 0;
            PlayerReplicationInfo.bIsSpectator = true;
        }
       	SetCollision(false, false, false);
       	bCollideWorld = false;
        bHidden = true;
        bDetectable = false;
		SetPhysics(PHYS_Flying);
		if (inHand != none)
		{
            inHand.Destroy();
            inHand = none;
        }

		if (invulnSph != None)
	    {
			invulnSph.Destroy();
			invulnSph=None;
		}

        bNintendoImmunity = false;
        NintendoImmunityTimeLeft = 0.0;
        bBehindView = false;
        KillShadow();
        if (ROLE == ROLE_Authority)
        {
           if (Shadow != None) Shadow.Destroy();
           Shadow = None;
        }
        UnderWaterTime = -1.0;
        FrobTarget = none;
        Visibility = 0;

        if (ROLE == ROLE_Authority)
        {
            ViewTarget = none;
            FreeSpecMode = true;
            bBehindView = false;
			pri = MMPRI(PlayerReplicationInfo);
			if (pri != none)
			{
				pri.SpectatingPlayerID = -1;
				pri.Flag = none;
				pri.bDead = false;
			}

            FixElectronicDevices();
			bCTFWantsToPlay = false;
        }

        InstantFlash = 0;
		InstantFog = vect(0,0,0);

       	while(Inventory != None)
	    {
		    anItem = Inventory;
		    DeleteInventory(anItem);
		    anItem.Destroy();
	    }

	    // Clear object belt
	    if (DeusExRootWindow(rootWindow) != None)
		    DeusExRootWindow(rootWindow).hud.belt.ClearBelt();

        DrawType = DT_None;
		Style = STY_Translucent;

		ActivateAllHUDElements(0);

        SetSpectatorStartPoint();

   	    if (ROLE == ROLE_Authority && Level.Game != none)
	    {
            Level.Game.BroadcastMessage("Player " $ PlayerReplicationInfo.PlayerName $ " is now spectator.");
	    }
	}

	simulated function MultiplayerTickSpec()
	{
	    local bool fpv;

		fpv = !FreeSpecMode && !bBehindView && (ViewTarget != none);

		if (fpv)
		{
			SetLocation(ViewTarget.Location);
			SetRotation(ViewTarget.Rotation);
		}

        DrawRemotePlayersAugs(self, fpv);

        if ((DeusExRootWindow(rootWindow).hud.hit.bVisible && !fpv) ||
            (!DeusExRootWindow(rootWindow).hud.hit.bVisible && fpv))
        {
             DeusExRootWindow(rootWindow).hud.hit.SetVisibility(fpv);
        }

        if ((DeusExRootWindow(rootWindow).hud.activeItems.bIsVisible && !fpv) ||
            (!DeusExRootWindow(rootWindow).hud.activeItems.bIsVisible && fpv))
        {
             DeusExRootWindow(rootWindow).hud.activeItems.SetVisibility(fpv);
        }

        return;
	}

	function MultiplayerTick(float DeltaTime)
	{
		local MMPRI pri;

        if (Role < ROLE_Authority)
        {
            MultiplayerTickSpec();
            return;
        }

		if (bCTFWantsToPlay && CTFRespawnTime <= Level.TimeSeconds)
		{
			GotoState('PlayerWalking');
			return;
		}

        bSpecEnemies = CanSpectateEnemy();

        // in case spectated player disconnects or swaps to spectator on his own
		if ((!FreeSpecMode && (ViewTarget == none)) ||
            ((Pawn(ViewTarget) != none) && (Pawn(ViewTarget).PlayerReplicationInfo.bIsSpectator)) ||
            (!bSpecEnemies && Pawn(ViewTarget) != none && Pawn(ViewTarget).PlayerReplicationInfo.Team != PlayerReplicationInfo.Team))
        {
            NextPlayer(false);
            if (ViewTarget == none)
            {
                FreeSpecMode = true;
                bBehindView = false;
				pri = MMPRI(PlayerReplicationInfo);
				if (pri != none) pri.SpectatingPlayerID = -1;
            }
        }

        if (lastRefreshTime < 0)
            lastRefreshTime = 0;

        lastRefreshTime = lastRefreshTime + DeltaTime;

        if (lastRefreshTime < 0.25) return;

       	if ( Level.Timeseconds > ServerTimeLastRefresh )
	    {
		    SetServerTimeDiff( Level.Timeseconds );
		    ServerTimeLastRefresh = Level.Timeseconds + 10.0;
        }

        lastRefreshTime = 0;
	}


	simulated function SetClientStartTime(float t)
	{
		CTFRespawnTime = Level.TimeSeconds + t;
	}


    function SpectateX(int act)
    {
		local miniMTLCTF ctfgame;

		if ((Level.TimeSeconds - 1.0) < LastSpecChangeTime) return;
		LastSpecChangeTime = Level.TimeSeconds;

		ctfgame = getCTFGame();

		if (act == 0)
		{
			if (ctfgame != none)
			{
				if (!bCTFWantsToPlay)
				{
					bCTFWantsToPlay = true;
					CTFRespawnTime = Level.TimeSeconds + ctfgame.NextRespawnTime;
					SetClientStartTime(ctfgame.NextRespawnTime);
				}
			}
			else GotoState('PlayerWalking');
		}
		else if (ctfgame != none)
		{
			bCTFWantsToPlay = false;
		}
    }


    exec function Fire(optional float F)
    {
        NextPlayer(false);
    }


    exec function AltFire(optional float F)
    {
        NextPlayer(true);
    }


    exec function ToggleBehindView()
    {
        if (FreeSpecMode) return;
        super.ToggleBehindView();
    }


   	function EndState()
	{
        local NavigationPoint StartSpot;

        //ActivateAllHUDElements(true);
		ActivateAllHUDElements(2);

        if (ROLE == ROLE_Authority)
        {
            if (bExiting) return; // if player is exiting directly from spectator mode...
            FreeSpecMode = true;
            bBehindView = false;
            ViewTarget = none;
        }

        DrawType = default.DrawType;
		Style = default.Style;
        Visibility = default.Visibility;
		SetCollision(true, true, true);
		bCollideWorld = default.bCollideWorld;
		SetPhysics(PHYS_None);
        bHidden = false;
        bDetectable = default.bDetectable;
	    CreateShadow();
	    UnderWaterTime = default.UnderWaterTime;

		if (ROLE == ROLE_Authority && Level.Game != none)
	    {
			if (TeamDMGame(Level.Game) != none)
			{
				if (PlayerReplicationInfo.Team == 0)
					Level.Game.BroadcastMessage("Spectator " $ PlayerReplicationInfo.PlayerName $ " joined UNATCO Team.");
				else Level.Game.BroadcastMessage("Spectator " $ PlayerReplicationInfo.PlayerName $ " joined NSF Team.");
			}
			else Level.Game.BroadcastMessage("Spectator " $ PlayerReplicationInfo.PlayerName $ " started playing.");

			if (PlayerReplicationInfo != none) PlayerReplicationInfo.bIsSpectator = false;
	    }

		if (!Level.Game.RestartPlayer(self))
			Level.Game.RestartPlayer(self); // try again
	}


	event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
    {
	    local Pawn PTarget;

	    if ( ViewTarget != None )
	    {
		    ViewActor = ViewTarget;
		    CameraLocation = ViewTarget.Location;
		    CameraRotation = ViewTarget.Rotation;
		    PTarget = Pawn(ViewTarget);
		    if ( PTarget != None )
		    {
			    if ( Level.NetMode == NM_Client )
			    {
				    if (PTarget.bIsPlayer)
				    {
					    //PTarget.ViewRotation = TargetViewRotation;
					    //PTarget.ViewRotation = TargetViewRotation3;
					    PTarget.ViewRotation.Pitch = TargetView_RotPitch;
					    PTarget.ViewRotation.Yaw = TargetView_RotYaw;
				    }
				    PTarget.EyeHeight = TargetEyeHeight;
				    if ( PTarget.Weapon != None )
					    PTarget.Weapon.PlayerViewOffset = TargetWeaponViewOffset;
			    }
			    if ( PTarget.bIsPlayer )
				    CameraRotation = PTarget.ViewRotation;
			    if ( !bBehindView )
				    CameraLocation.Z += PTarget.EyeHeight;
		    }
		    if ( bBehindView )
			    CalcBehindView(CameraLocation, CameraRotation, 180);
	    }
		else super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	}
}


exec function DisconnectPlayer()
{
    //NotifyExiting();
    bExiting = true;
    super.DisconnectPlayer();
}


function SetExactViewRotation(int p, int y)
{
    View_RotPitch = p;
    View_RotYaw = y;
}


state PlayerWalking
{
    function EndState()
    {
        super.EndState();
        SetSpectatorVariablesAtEnd();
    }

    function MultiplayerTick(float deltaTime)
    {
        SetSpectatorVariables();
        super.MultiplayerTick(deltaTime);
    }
}


function SetSpectatorVariablesAtEnd()
{
        local Pawn P;
        local miniMTLPlayer mmp;

        if (ROLE == ROLE_Authority)
        {
            P = Level.PawnList;
            while (P != none)
            {
                mmp = miniMTLPlayer(P);
                if (mmp != none)
                {
                    if (mmp.ViewTarget == self)
                    {
                        mmp.bTargetAlive = false;
                        mmp.HealthHead = 0;
                        mmp.HealthTorso = 0;
                        mmp.HealthArmLeft = 0;
                        mmp.HealthArmRight = 0;
                        mmp.HealthLegLeft = 0;
                        mmp.HealthLegRight = 0;
                    }
                }
                P = P.nextPawn;
            }
        }
}

function bool WillDisplaySkillMessageForever()
{
    local miniMTLTeam tgm;
	local miniMTLDeathMatch dmg;

    tgm = miniMTLTeam(Level.Game);
    if (tgm != none && tgm.Settings.bDisplaySkillMessageForever) return true;

	dmg = miniMTLDeathMatch(Level.Game);
	if (dmg != none && dmg.Settings.bDisplaySkillmessageForever) return true;

	return false;
}


function SetSpectatorVariables()
{
        local Pawn P;
        local miniMTLPlayer mmp;
        local Augmentation aug;
        local int i, index, indexa;
        local MMSkillManager smanager;
		local Inventory CurInventory;
		local MMAugmentationManager amanager;

        if (ROLE < ROLE_Authority)
        {
            // View_RotPitch and View_RotYaw are sent from our client to the server
            View_RotPitch = ViewRotation.Pitch;
            View_RotYaw = ViewRotation.Yaw;
        }
        else
        {
            // for newbies
            bDisplaySkillMessageForever = WillDisplaySkillMessageForever();

            P = Level.PawnList;
            while (P != none)
            {
                mmp = miniMTLPlayer(P);
                if (mmp != none)
                {
                    if (mmp.ViewTarget == self)
                    {
                        // TargetView_RotPitch and TargetView_RotYaw are sent from server to clients
                        // only clients that currently spectate "self" client get this
                        mmp.TargetView_RotPitch = View_RotPitch;
                        mmp.TargetView_RotYaw = View_RotYaw;

						// set inventory
						mmp.TargetBioCells = 0;
						mmp.TargetMedkits = 0;
						mmp.TargetMultitools = 0;
						mmp.TargetLockpicks = 0;
						mmp.TargetLAMs = 0;
						mmp.TargetGGs = 0;
						mmp.TargetEMPs = 0;
						mmp.TargetWeapons[0] = none;
						mmp.TargetWeapons[1] = none;
						mmp.TargetWeapons[2] = none;

						CurInventory = Inventory;
						i = 0;
						while (CurInventory != None)
						{
							if (CurInventory.IsA('BioelectricCell')) mmp.TargetBioCells = BioelectricCell(CurInventory).NumCopies;
							else if (CurInventory.IsA('MedKit')) mmp.TargetMedkits = MedKit(CurInventory).NumCopies;
							else if (CurInventory.IsA('Multitool')) mmp.TargetMultitools = Multitool(CurInventory).NumCopies;
							else if (CurInventory.IsA('Lockpick')) mmp.TargetLockpicks = Lockpick(CurInventory).NumCopies;
							else if (CurInventory.IsA('WeaponLAM')) mmp.TargetLAMs = WeaponLAM(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('WeaponGasGrenade')) mmp.TargetGGs = WeaponGasGrenade(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('WeaponEMPGrenade')) mmp.TargetEMPs = WeaponEMPGrenade(CurInventory).AmmoType.AmmoAmount;
							else if (CurInventory.IsA('DeusExWeapon') && i < 3)
							{
								mmp.TargetWeapons[i] = DeusExWeapon(CurInventory).class;
								i++;
							}
							CurInventory = CurInventory.Inventory;
						}

						// augs
						amanager = MMAugmentationManager(AugmentationSystem);
                        mmp.TargetAugs = 0;

						for (i = 0; i < ArrayCount(amanager.mpAugs); i++)
						{
							index = i;
                            if (amanager.mpStatus[i] > 0)
                            {
                            	mmp.TargetAugs = mmp.TargetAugs | (1 << index);
								if (amanager.mpStatus[i] == 2) mmp.TargetAugs = mmp.TargetAugs | (0x40000000 >> amanager.mpAugs[i].default.MPConflictSlot);
                            }
						}

                        // and health + bio
                        mmp.bTargetAlive = true;
                        mmp.HealthHead = HealthHead;
                        mmp.HealthTorso = HealthTorso;
                        mmp.HealthArmLeft = HealthArmLeft;
                        mmp.HealthArmRight = HealthArmRight;
                        mmp.HealthLegLeft = HealthLegLeft;
                        mmp.HealthLegRight = HealthLegRight;
                        mmp.Energy = Energy;

                        mmp.TargetSkillsAvail = SkillPointsAvail;
                        mmp.TargetSkills = 0;

						smanager = MMSkillManager(SkillSystem);
						if (smanager != none)
						{
							for (i = 0; i < ArrayCount(smanager.SkillLevels); i++)
							{
								if (smanager.SkillLevels[i] == 3) mmp.TargetSkills = mmp.TargetSkills | (0x40000000 >> i);
								else if (smanager.SkillLevels[i] == 2) mmp.TargetSkills = mmp.TargetSkills | (1 << i);
							}
                        }
                    }
                }
                P = P.nextPawn;
            }
        }
}


simulated function ActivateAllHUDElements(int hmode)
{
    local DeusExRootWindow root;
    local MMDeusExHUD mmdxhud;

    root = DeusExRootWindow(rootWindow);
	if (root != none)
    {
        mmdxhud = MMDeusExHUD(root.hud);
        if (mmdxhud != none)
        {
			mmdxhud.HUD_mode = hmode;
			mmdxhud.UpdateSettings(self);
            //mmdxhud.ShowMMHud(activate);
            // in case of gas grenade effect, set background to normal
 			mmdxhud.SetBackground(None);
			mmdxhud.SetBackgroundStyle(DSTY_Normal);
	    }
    }
}


simulated function ClientSetTeam(int t)
{
	UpdateURL("Team", string(t), true);
	SaveConfig();
}


function NewChangeTeam(int t)
{
    local int old;
    local TeamDMGame tdm;

	if (!GameReplicationInfo.bTeamGame)
	{
		if (IsInState('Spectating')) Spectate(0);
		return;
	}

    if (t == 2)
    {
        tdm = TeamDMGame(Level.Game);
        if (tdm != none) t = tdm.GetAutoTeam();
    }

    if (t != 1 && t != 0) return;

    old = int(PlayerReplicationInfo.Team);
    if (old != t)
    {
		ClientSetTeam(t);
        //UpdateURL("Team", string(t), true);
        //SaveConfig();
    }

    if (IsInState('Spectating'))
    {
        PlayerReplicationInfo.Team = t;
		SetSkin();
        Spectate(0);
    }
    else ChangeTeam(t);
}


exec function ShowMainMenu()
{
    PlayerMOTDWindow.OpenMenu(self);
}


final simulated function DoSomeFixes()
{
	if (Level.NetMode != 3) return;
	Spawn(Class'_MMSomeFixes1', self);
}


event GainedChild(Actor Other)
{
    if (Other.class == class'DXMTL152b1.MTLMOTD')
    {
    	Other.Destroy();
		DoSomeFixes();
    }
}


exec function ToggleFreeMode()
{
    local miniMTLTeam g;
    local vector v;
	local MMPRI pri;

    if (!IsInState('Spectating')) return;
    if (ROLE < ROLE_Authority) return;

    if (FreeSpecMode)
    {
        FreeSpecMode = false;
        NextPlayer(false);
        if (ViewTarget != none) return;
    }
    if (ViewTarget != none)
    {
        v = ViewTarget.Location - (150 * (vect(1,0,0) >> ViewRotation));
        v.Z -= Pawn(ViewTarget).EyeHeight;
        SetLocation(v);
        ViewTarget = none;
    }

    //ClientMessage("Spectating in free mode");
    FreeSpecMode = true;
    bBehindView = false;
	pri = MMPRI(PlayerReplicationInfo);
	if (pri != none) pri.SpectatingPlayerID = -1;
}


function bool CanSpectateEnemy()
{
    local miniMTLTeam g;
	local miniMTLDeathMatch gdm;

    g = miniMTLTeam(Level.Game);
    if (g != none && g.Settings.bSpectateEnemy) return true;

	gdm = miniMTLDeathMatch(Level.Game);
	if (gdm != none) return true; // always allow spectating when DM

    return false;
}


function Pawn GetNextSpecPlayer(Pawn P)
{
    local bool enemyspec;

    enemyspec = CanSpectateEnemy();
    if (P == none) P = Level.PawnList;
    while (P != none)
    {
        //log("Checking: "$P.name);
        if (P.IsA('PlayerPawn') && !P.IsA('MessagingSpectator'))
		{
            if (!P.PlayerReplicationInfo.bIsSpectator)
            {
                if (enemyspec || P.PlayerReplicationInfo.Team == PlayerReplicationInfo.Team) break;
            }
        }
        P = P.nextPawn;
    }
    return P;
}


exec function NextPlayer(bool prev)
{
    local MMPRI pri;

    if (!IsInState('Spectating')) return;
    if (ROLE < ROLE_Authority) return;
    if (FreeSpecMode) return;
    if ((SpecPlayerChangedTime + 0.3) > Level.TimeSeconds) return;

    SpecPlayerChangedTime = Level.TimeSeconds;

    if (ViewTarget == none)
    {
        ViewTarget = GetNextSpecPlayer(none);
        //if (ViewTarget != none) log("Found: " $ Pawn(ViewTarget).PlayerReplicationInfo.PlayerName);
    }
    else
    {
        ViewTarget = GetNextSpecPlayer(Pawn(ViewTarget).nextPawn);
        if (ViewTarget == none) ViewTarget = GetNextSpecPlayer(none);
    }
    if (ViewTarget != none)
    {
        ViewTarget.BecomeViewTarget();
        //log("Player " $ self.PlayerReplicationInfo.PlayerName $ " spectating: " $ Pawn(ViewTarget).PlayerReplicationInfo.PlayerName);
		pri = MMPRI(PlayerReplicationInfo);
		if (pri != none) pri.SpectatingPlayerID = Pawn(ViewTarget).PlayerReplicationInfo.PlayerID;
    }
}


exec function ShowInventoryWindow()
{
    if (IsInState('Spectating'))
    {
        ToggleFreeMode();
    }
    else super.ShowInventoryWindow();
}


exec function ShowGoalsWindow()
{
    if (IsInState('Spectating'))
    {
        ToggleBehindView();
    }
	else super.ShowGoalsWindow();
}


function FixName(out string V92)
{
	V92=Left(V92,20);
	if (Level.NetMode == 0) return;
	FixName3(V92, False);
	if (V92 == "") V92="Player";
	if ( (V92 ~= "Player") || (V92 ~= "PIayer") || (V92 ~= "P1ayer")) V92 = V92 $ "_" $ string(Rand(999));
	else
    {
		if (FixName2(V92)) V92=Left(V92,17) $ "_" $ string(Rand(99));
	}
}


final function bool FixName2(string V92)
{
	local Pawn V9B;

	if ( Level.NetMode != 0 )
	{
		V9B=Level.PawnList;
		while (V9B != None)
		{
			if ( V9B.bIsPlayer && (V9B != self) && (V9B.PlayerReplicationInfo.PlayerName ~= V92) ) return True;
			V9B=V9B.nextPawn;
		}
	}
	return False;
}


final function FixName3(out string V92, bool VA6)
{
	local int VA7;

	V92=Left(V92,500);
	if (!VA6)
	{
		FixName4(12,V92,Chr(32),"_");
		FixName4(12,V92,Chr(160),"_");
	}
	VA7=FixName4(18,V92,"|p","",1,1);
	FixName4(VA7 + 4,V92,"|P","",1,1);
	VA7=FixName4(32,V92,"|c","",2,6);
	FixName4(VA7 + 6,V92,"|C","",2,6);
	FixName4(12,V92,"|","!");
}


final function int FixName4(int V9D, out string V92, string V9E, string V9F, optional byte VA0, optional byte VA1)
{
	local int VA2;
	local int VA3;
	local int VA4;
	local int VA5;
	local int V91;

	if ( V92 == "" )
	{
		return V9D;
	}
	VA3=Len(V9E);
	VA2=InStr(V92,V9E);
JL0031:
	if ( VA2 != -1 )
	{
		VA5=0;
		if ( VA0 != 0 )
		{
			VA4=Len(V92);
			if ( VA1 > 0 )
			{
				VA4=Min(VA4,VA2 + VA3 + VA1);
			}
			VA5=VA2 + VA3;
JL009F:
			if ( VA5 < VA4 )
			{
				V91=Asc(Caps(Mid(V92,VA5,1)));
				if ( (V91 < 48) || (V91 > 57) )
				{
					if ( (VA0 == 1) || (V91 < 65) || (V91 > 70) )
					{
						goto JL0114;
					}
				}
				VA5++;
				goto JL009F;
			}
JL0114:
			VA5 -= VA2 + VA3;
		}
		V92=Left(V92,VA2) $ V9F $ Mid(V92,VA2 + VA3 + VA5);
		V9D -= VA3 + VA5;
		if ( V9D <= 0 )
		{
			V92=Left(V92,VA2 + Len(V9F));
		} else {
			VA2=InStr(V92,V9E);
			goto JL0031;
		}
	}
	return V9D;
}

function CreateKillerProfile( Pawn killer, int damage, name damageType, String bodyPart )
{
	local DeusExPlayer pkiller;
	local DeusExProjectile proj;
	local DeusExDecoration decProj;
	local Augmentation anAug;
	local int augCnt;
	local DeusExWeapon w;
	local String wShortString;
	local int i;

	if ( killProfile == None )
	{
		log("Warning:"$Self$" has a killProfile that is None!" );
		return;
	}
	else
	{
		killProfile.methodStr=NoneString;
		killProfile.Reset();
	}

	pkiller = DeusExPlayer(killer);

	if ( pkiller != None )
	{
		killProfile.bValid = True;
		killProfile.name = pkiller.PlayerReplicationInfo.PlayerName;
		w = DeusExWeapon(pkiller.inHand);
		GetWeaponName( w, killProfile.activeWeapon );

		// What augs the killer was using
		if ( pkiller.AugmentationSystem != None )
		{
			killProfile.numActiveAugs = pkiller.AugmentationSystem.NumAugsActive();
			augCnt = 0;
			for (i = 0; i < ArrayCount(class'MMAugmentationManager'.default.mpAugs); i++)
			{
				if (MMAugmentationManager(pkiller.AugmentationSystem).mpStatus[i] == 2)
				{
					killProfile.activeAugs[augCnt] = class'MMAugmentationManager'.default.mpAugs[i].default.AugmentationName;
					augCnt++;
					if (augCnt == ArrayCount(killProfile.activeAugs)) augCnt--;
				}
			}
		}
		else
			killProfile.numActiveAugs = 0;

		// My weapon and skill
		GetWeaponName( DeusExWeapon(inHand), killProfile.myActiveWeapon );
		if ( DeusExWeapon(inHand) != None )
		{
			if ( SkillSystem != None )
			{
				killProfile.myActiveSkill = MMSkillManager(SkillSystem).GetSkillClassNameByClass(DeusExWeapon(inHand).GoverningSkill);
				killProfile.myActiveSkillLevel = SkillSystem.GetSkillLevel(DeusExWeapon(inHand).GoverningSkill);
			}
		}
		else
		{
			killProfile.myActiveWeapon = NoneString;
			killProfile.myActiveSkill = NoneString;
			killProfile.myActiveSkillLevel = 0;
		}
		// Fill in my own active augs
		if ( AugmentationSystem != None )
		{
			killProfile.myNumActiveAugs = AugmentationSystem.NumAugsActive();
			augCnt = 0;
			for (i = 0; i < ArrayCount(class'MMAugmentationManager'.default.mpAugs); i++)
			{
				if (MMAugmentationManager(AugmentationSystem).mpStatus[i] == 2)
				{
					killProfile.myActiveAugs[augCnt] = class'MMAugmentationManager'.default.mpAugs[i].default.AugmentationName;
					augCnt++;
					if (augCnt == ArrayCount(killProfile.myActiveAugs)) augCnt--;
				}
			}
		}
		killProfile.streak = (pkiller.PlayerReplicationInfo.Streak + 1);
		killProfile.healthLow = pkiller.HealthLegLeft;
		killProfile.healthMid =  pkiller.HealthTorso;
		killProfile.healthHigh = pkiller.HealthHead;
		killProfile.remainingBio = pkiller.Energy;
		killProfile.damage = damage;
		killProfile.bodyLoc = bodyPart;
		killProfile.killerLoc = pkiller.Location;
	}
	else
	{
		killProfile.bValid = False;
		return;
	}

	killProfile.methodStr = NoneString;

	switch( damageType )
	{
		case 'AutoShot':
			killProfile.methodStr = WithTheString $ AutoTurret(myTurretKiller).titleString  $ "!";
			killProfile.bTurretKilled = True;
			killProfile.killerLoc = AutoTurret(myTurretKiller).Location;
			if ( pkiller.SkillSystem != None )
			{
				killProfile.activeSkill = class'SkillComputer'.Default.skillName;
				killProfile.activeSkillLevel = pkiller.SkillSystem.GetSkillLevel(class'SkillComputer');
			}
			break;
		case 'PoisonEffect':
			killProfile.methodStr = PoisonString $ "!";
			killProfile.bPoisonKilled = True;
			killProfile.activeSkill = NoneString;
			killProfile.activeSkillLevel = 0;
			break;
		case 'Burned':
		case 'Flamed':
			if (( WeaponPlasmaRifle(w) != None ) || ( WeaponFlamethrower(w) != None ))
			{
				// Use the weapon if it's still in hand
			}
			else
			{
				killProfile.methodStr = BurnString $ "!";
				killProfile.bBurnKilled = True;
				killProfile.activeSkill = NoneString;
				killProfile.activeSkillLevel = 0;
			}
			break;
	}
	if ( killProfile.methodStr ~= NoneString )
	{
		proj = DeusExProjectile(myProjKiller);
		decProj = DeusExDecoration(myProjKiller);

		if (( killer != None ) && (proj != None) && (!(proj.itemName ~= "")) )
		{
			if ( (LAM(myProjKiller) != None) && (LAM(myProjKiller).bProximityTriggered) )
			{
				killProfile.bProximityKilled = True;
				killProfile.killerLoc = LAM(myProjKiller).Location;
				killProfile.myActiveSkill = class'SkillDemolition'.Default.skillName;
				if ( SkillSystem != None )
					killProfile.myActiveSkillLevel = SkillSystem.GetSkillLevel(class'SkillDemolition');
				else
					killProfile.myActiveSkillLevel = 0;
			}
			else
				killProfile.bProjKilled = True;
			killProfile.methodStr = WithString $ proj.itemArticle $ " " $ proj.itemName $ "!";
			GetSkillInfoFromProj( pkiller, myProjKiller );
		}
		else if (( killer != None ) && ( decProj != None ) && (!(decProj.itemName ~= "" )) )
		{
			killProfile.methodStr = WithString $ decProj.itemArticle $ " " $ decProj.itemName $ "!";
			killProfile.bProjKilled = True;
			GetSkillInfoFromProj( pkiller, myProjKiller );
		}
		else if ((killer != None) && (w != None))
		{
			GetWeaponName( w, wShortString );
			killProfile.methodStr = WithString $ w.itemArticle $ " " $ wShortString $ "!";
			killProfile.activeSkill = MMSkillManager(pkiller.SkillSystem).GetSkillClassNameByClass(w.GoverningSkill);
			killProfile.activeSkillLevel = pkiller.SkillSystem.GetSkillLevel(w.GoverningSkill);
		}
		else
			log("Warning: Failed to determine killer method killer:"$killer$" damage:"$damage$" damageType:"$damageType$" " );
	}
	// If we still failed dump this to log, and I'll see if there's a condition slipping through...
	if ( killProfile.methodStr ~= NoneString )
	{
		log("===>Warning: Failed to get killer method:"$Self$" damageType:"$damageType$" " );
		killProfile.bValid = False;
	}
}

function SpawnBlood(Vector S30, float VC1)
{
	if (Level.NetMode == NM_DedicatedServer) return;

	else super.SpawnBlood(S30, VC1);
}

function SpawnInitialInventoryClass(class<Inventory> invclass)
{
	local Inventory anItem;

	anItem = spawn(invclass,self,,,rot(0,0,0));
	anItem.RespawnTime = 0.0;
	anItem.bHeldItem = true;
	anItem.GiveTo(self);
}

function GiveInitialInventory()
{
	SpawnInitialInventoryClass(class'MedKit');
	SpawnInitialInventoryClass(class'Lockpick');
	SpawnInitialInventoryClass(class'Multitool');
}

function SpawnBloodFromWeapon(Vector HitLocation, Vector HitNormal, optional Rotator rot)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer == self || curplayer.ViewTarget == self) continue;
		if (curplayer.LineOfSightTo(self, true)) curplayer.ClientSpawnBloodFromWeapon(self, HitLocation, HitNormal, rot);
	}
}


function SpawnBloodFromProjectile(Vector HitLocation, Vector HitNormal, float dmg)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer == self || curplayer.ViewTarget == self) continue;
		if (curplayer.LineOfSightTo(self, true)) curplayer.ClientSpawnBloodFromProjectile(self, HitLocation, HitNormal, byte(dmg / 7));
	}
}

function SpawnTracerFromWeapon(Vector loc, Rotator rot)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer == self || curplayer.ViewTarget == self || curplayer.LineOfSightTo(self, true))
			curplayer.ClientSpawnTracerFromWeapon(self, loc, rot);
	}
}

function SpawnSniperTracerFromWeapon(Vector loc, Rotator rot)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer == self || curplayer.ViewTarget == self || curplayer.LineOfSightTo(self, true))
			curplayer.ClientSpawnSniperTracerFromWeapon(self, loc, rot);
	}
}

function SpawnShellCasing(Vector loc, bool bsilent)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer == self || curplayer.ViewTarget == self || curplayer.LineOfSightTo(self, true))
			curplayer.ClientSpawnShellCasing(self, loc, bsilent);
	}
}

simulated function ClientSpawnBloodFromWeapon(miniMTLPlayer bleeder, Vector HitLocation, Vector HitNormal, Rotator rot)
{
	if (!bSpawnBlood || bleeder == none) return; // bleeder is not replicated to us, so just return

   spawn(class'MMBloodSpurt',,,HitLocation+HitNormal, rot);
	spawn(class'MMBloodDrop',,,HitLocation+HitNormal);
	if (FRand() < 0.5)
		spawn(class'MMBloodDrop',,,HitLocation+HitNormal);
}

simulated function ClientSpawnBloodFromProjectile(miniMTLPlayer bleeder, Vector HitLocation, Vector HitNormal, byte dmg)
{
	local int i;

	if (!bSpawnBlood || bleeder == none) return; // bleeder is not replicated to us, so just return

   spawn(class'MMBloodSpurt',,,HitLocation+HitNormal);
	for (i=0; i<dmg; i++)
	{
		if (FRand() < 0.5)
			spawn(class'MMBloodDrop',,,HitLocation+HitNormal*4);
	}
}

simulated function ClientSpawnTracerFromWeapon(Actor instigator, Vector loc, Rotator rot)
{
	if (!bSpawnTracers || instigator == none) return; // instigator is not replicated to us, so just return
	Spawn(class'MMTracer',,, loc, rot);
}

simulated function ClientSpawnSniperTracerFromWeapon(Actor instigator, Vector loc, Rotator rot)
{
	if (!bSpawnTracers || instigator == none) return; // instigator is not replicated to us, so just return
	Spawn(class'MMSniperTracer',,, loc, rot);
}

simulated function ClientSpawnShellCasing(Actor instigator, Vector loc, bool bsilent, optional Rotator rot)
{
	local ShellCasing sc;
	if (!bSpawnShellCasings || instigator == none) return; // instigator is not replicated to us, so just return
	if (bsilent) sc = spawn(class'MMShellCasingSilent',,, loc);
	else sc = spawn(class'MMShellCasing',,, loc);
	if (sc != none && rot.Yaw != 0 && rot.Pitch != 0 && rot.Roll != 0) sc.Velocity = Vector(rot) * 100 + VRand() * 30;
}

simulated function ClientSpawnFleshFragments(Vector spawnloc)
{
	local int i;
	local float size;
	local Vector loc;
	local FleshFragment chunk;

	if (!bSpawnFlesh) return;

	size = (class'MMCarcass'.default.CollisionRadius + class'MMCarcass'.default.CollisionHeight) / 2;
	if (size > 10.0)
	{
		for (i=0; i<size/4.0; i++)
		{
			loc.X = (1-2*FRand()) * class'MMCarcass'.default.CollisionRadius;
			loc.Y = (1-2*FRand()) * class'MMCarcass'.default.CollisionRadius;
			loc.Z = (1-2*FRand()) * class'MMCarcass'.default.CollisionHeight;
			loc += spawnloc;
			chunk = spawn(class'MMFleshFragment', none,, loc);
			if (chunk != None)
			{
				chunk.DrawScale = size / 25;
				chunk.SetCollisionSize(chunk.CollisionRadius / chunk.DrawScale, chunk.CollisionHeight / chunk.DrawScale);
				chunk.bFixedRotationDir = True;
				chunk.RotationRate = RotRand(False);
			}
		}
	}
}

simulated function SparkPlayHitSound(actor destActor, Actor hitActor)
{
	local float rnd;
	local sound snd;

	rnd = FRand();

	if (rnd < 0.25)
		snd = sound'Ricochet1';
	else if (rnd < 0.5)
		snd = sound'Ricochet2';
	else if (rnd < 0.75)
		snd = sound'Ricochet3';
	else
		snd = sound'Ricochet4';

	// play a different ricochet sound if the object isn't damaged by normal bullets
	if (hitActor != None)
	{
		if (hitActor.IsA('DeusExDecoration') && (DeusExDecoration(hitActor).minDamageThreshold > 10))
			snd = sound'ArmorRicochet';
		else if (hitActor.IsA('Robot'))
			snd = sound'ArmorRicochet';
	}

	if (destActor != None)
		destActor.PlaySound(snd, SLOT_None,,, 1024, 1.1 - 0.2*FRand());
}

simulated function ClientSpawnSpark(Actor instigator, Vector loc, Vector norm, Actor hit)
{
	local Spark spar;

	if (instigator == none) return; // instigator is not replicated to us, so just return
	spar = spawn(class'MMSpark',,,loc + norm, Rotator(norm));
	if (spar != none)
	{
		spar.DrawScale = 0.05;
		SparkPlayHitSound(spar, hit);
	}
}

simulated function name GetWallMaterial2(vector HitLocation, vector HitNormal)
{
	local vector EndTrace, StartTrace;
	local actor newtarget;
	local int texFlags;
	local name texName, texGroup;

	StartTrace = HitLocation + HitNormal*16;		// make sure we start far enough out
	EndTrace = HitLocation - HitNormal;

	foreach TraceTexture(class'Actor', newtarget, texName, texGroup, texFlags, StartTrace, HitNormal, EndTrace)
		if ((newtarget == Level) || newtarget.IsA('Mover'))
			break;

	return texGroup;
}

simulated function ClientSpawnTurretEffects(Actor instigator, Vector HitLocation, Vector HitNormal, Actor Other)
{
	local SmokeTrail puff;
	local int i;
	local BulletHole hole;
	local Rotator rot;

	if (!bSpawnOtherVisualEffects || instigator == none) return; // instigator is not replicated to us, so just return

   if (FRand() < 0.5)
	{
		puff = spawn(class'MMSmokeTrail',,,HitLocation+HitNormal, Rotator(HitNormal));
		if (puff != None)
		{
			puff.DrawScale *= 0.3;
			puff.OrigScale = puff.DrawScale;
			puff.LifeSpan = 0.25;
			puff.OrigLifeSpan = puff.LifeSpan;
		}
	}

	if (!Other.IsA('BreakableGlass'))
		for (i=0; i<2; i++)
			if (FRand() < 0.8)
				spawn(class'MMRockchip',,,HitLocation+HitNormal);

	hole = spawn(class'BulletHole', Other,, HitLocation, Rotator(HitNormal));

	// should we crack glass?
	if (GetWallMaterial2(HitLocation, HitNormal) == 'Glass')
	{
		if (FRand() < 0.5)
			hole.Texture = Texture'FlatFXTex29';
		else
			hole.Texture = Texture'FlatFXTex30';

		hole.DrawScale = 0.1;
		hole.ReattachDecal();
	}
}


function CreateColorThemeManager()
{
	Super.CreateColorThemeManager();
	if (ThemeManager != None)
	{
		if (ThemeManager.currentHUDTheme != none) ThemeManager.currentHUDTheme.RemoteRole = ROLE_None;
		if (ThemeManager.currentMenuTheme != none) ThemeManager.currentMenuTheme.RemoteRole = ROLE_None;
	}
}

exec function DumpAllNetActors()
{
	local Actor a;
	foreach AllActors(class'Actor', a)
	{
		if (a.Role == ROLE_SimulatedProxy || a.Role == ROLE_AutonomousProxy)
			log("Net actor:"@a);
	}
}

exec function CustomRecord()
{
	local string demoname;

	if (Level != none)
	{
		ConsoleCommand("stopdemo");
		demoname = sprintf("demo_%s-%s-%s", Level.Year, Level.Month, Level.Day);
		demoname = sprintf("%s_%s-%s-%s", demoname, Level.Hour, Level.Minute, Level.Second);
		ConsoleCommand("demorec " $ demoname);
		Super(PlayerPawn).ClientMessage("Started recording to: " $ demoname);
	}
}

exec function ParseRightClick()
{
	local DeusExWeapon W;

	if (!bPerformZoomOnRightClick || FrobTarget != none)
	{
		super.ParseRightClick();
		return;
	}

	if (RestrictInput())
		return;

	W = DeusExWeapon(Weapon);
	if (W != None && W.bHasScope)
		W.ScopeToggle();
	else super.ParseRightClick();
}


function TakeDamage (int Damage, Pawn instigatedBy, Vector HitLocation, Vector Momentum, name DamageType)
{
	local byte VBE;
	local int actualDamage;
	local int MPHitLoc;
	local bool bAlreadyDead;
	local bool bPlayAnim;
	local bool bDamageGotReduced;
	local Vector Offset;
	local Vector dst;
	local float origHealth;
	local float fdst;
	local DeusExLevelInfo Info;
	local WeaponRifle VBF;
	local string bodyString;
	local int ReflDamage;

	if (miniMTLTeam(Level.Game) != none)
	{
		if (miniMTLTeam(Level.Game).bReflectiveDamage &&
			instigatedBy != self &&
			miniMTLTeam(Level.Game).ArePlayersAllied(self, DeusExPlayer(instigatedBy)))
		{
			ReflDamage = Damage;
			if (DamageType == 'exploded') ReflDamage *= 2;
			instigatedBy.TakeDamage(ReflDamage * miniMTLTeam(Level.Game).fFriendlyFireMult, instigatedBy, HitLocation, Momentum, DamageType);
			return;
		}
	}

	bodyString="";
	origHealth=Health;
	if ( Level.NetMode != 0 )
	{
		Damage *= MPDamageMult;
	}
	Offset=HitLocation - Location << Rotation;
	bDamageGotReduced=DXReduceDamage(Damage,DamageType,HitLocation,actualDamage,False);
	if ( ReducedDamageType == DamageType )
	{
		actualDamage=actualDamage * (1.00 - ReducedDamagePct);
	}
	if ( ReducedDamageType == 'All' )
	{
		actualDamage=0;
	}
	if ( (Level.Game != None) && (Level.Game.DamageMutator != None) )
	{
		Level.Game.DamageMutator.MutatorTakeDamage(actualDamage,self,instigatedBy,HitLocation,Momentum,DamageType);
	}
	if ( bNintendoImmunity || (actualDamage == 0) && (NintendoImmunityTimeLeft > 0.00) )
	{
		return;
	}
	if ( actualDamage < 0 )
	{
		return;
	}
	if ( DamageType == 'NanoVirus' )
	{
		return;
	}
	if ( (DamageType == 'Poison') || (DamageType == 'PoisonEffect') )
	{
		AddDamageDisplay('PoisonGas',Offset);
	} else {
		AddDamageDisplay(DamageType,Offset);
	}
	if ( (DamageType == 'Poison') || (Level.NetMode != 0) && (DamageType == 'TearGas') )
	{
		if ( Level.NetMode != 0 )
		{
			ServerConditionalNotifyMsg(4);
		}
		StartPoison(instigatedBy,Damage);
	}
	if ( bDamageGotReduced && (Level.NetMode != 0) )
	{
		ShieldStatus=SS_Strong;
		ShieldTimer=1.00;
	}
	if ( (Level.NetMode != 0) && (DeusExPlayer(instigatedBy) != None) )
	{
		VBF=WeaponRifle(DeusExPlayer(instigatedBy).Weapon);
		if ( (VBF != None) && !VBF.bZoomed && ((VBF.Class == Class'CBPWeaponRifle') || (VBF.Class == Class'WeaponRifle') || (VBF.Class == class'MMWeaponRifle')) )
		{
			actualDamage *= VBF.mpNoScopeMult;
		}
		if ( (TeamDMGame(DXGame) != None) && (DeusExPlayer(instigatedBy) != self) && TeamDMGame(DXGame).ArePlayersAllied(DeusExPlayer(instigatedBy),self) )
		{
			actualDamage *= TeamDMGame(DXGame).fFriendlyFireMult;
			if ( (DamageType != 'TearGas') && (DamageType != 'PoisonEffect') )
			{
				DeusExPlayer(instigatedBy).MultiplayerNotifyMsg(2);
			}
		}
	}
	if ( DamageType == 'EMP' )
	{
		EnergyDrain += actualDamage;
		EnergyDrainTotal += actualDamage;
		PlayTakeHitSound(actualDamage,DamageType,1);
		return;
	}
	bPlayAnim=True;
	if ( (DamageType == 'Burned') || PlayerReplicationInfo.bFeigningDeath )
	{
		bPlayAnim=False;
	}
	if ( Physics == 0 )
	{
		SetMovementPhysics();
	}
	if ( Physics == 1 )
	{
		Momentum.Z=0.40 * VSize(Momentum);
	}
	if ( instigatedBy == self )
	{
		Momentum *= 0.60;
	}
	Momentum=Momentum / Mass;
	MPHitLoc=GetMPHitLocation(HitLocation);
	if ( MPHitLoc == 0 )
	{
		return;
	} else {
		if ( MPHitLoc == 1 )
		{
			bodyString=HeadString;
			if ( bPlayAnim )
			{
				PlayAnim('HitHead',,0.10);
			}
			if ( Level.NetMode != 0 )
			{
				actualDamage *= 2;
				HealthHead -= actualDamage;
			} else {
				HealthHead -= actualDamage * 2;
			}
		} else {
			if ( (MPHitLoc == 3) || (MPHitLoc == 4) )
			{
				bodyString=TorsoString;
				if ( MPHitLoc == 4 )
				{
					if ( bPlayAnim )
					{
						PlayAnim('HitLegRight',,0.10);
					}
				} else {
					if ( bPlayAnim )
					{
						PlayAnim('HitLegLeft',,0.10);
					}
				}
				if ( Level.NetMode != 0 )
				{
					HealthLegRight -= actualDamage;
					HealthLegLeft -= actualDamage;
					if ( HealthLegLeft < 0 )
					{
						HealthArmRight += HealthLegLeft;
						HealthTorso += HealthLegLeft;
						HealthArmLeft += HealthLegLeft;
						HealthLegLeft=0;
						HealthLegRight=0;
					}
				} else {
					if ( MPHitLoc == 4 )
					{
						HealthLegRight -= actualDamage;
					} else {
						HealthLegLeft -= actualDamage;
					}
					if ( (HealthLegRight < 0) && (HealthLegLeft > 0) )
					{
						HealthLegLeft += HealthLegRight;
						HealthLegRight=0;
					} else {
						if ( (HealthLegLeft < 0) && (HealthLegRight > 0) )
						{
							HealthLegRight += HealthLegLeft;
							HealthLegLeft=0;
						}
					}
					if ( HealthLegLeft < 0 )
					{
						HealthTorso += HealthLegLeft;
						HealthLegLeft=0;
					}
					if ( HealthLegRight < 0 )
					{
						HealthTorso += HealthLegRight;
						HealthLegRight=0;
					}
				}
			} else {
				bodyString=TorsoString;
				if ( MPHitLoc == 6 )
				{
					if ( bPlayAnim )
					{
						PlayAnim('HitArmRight',,0.10);
					}
				} else {
					if ( MPHitLoc == 5 )
					{
						if ( bPlayAnim )
						{
							PlayAnim('HitArmLeft',,0.10);
						}
					} else {
						if ( bPlayAnim )
						{
							PlayAnim('HitTorso',,0.10);
						}
					}
				}
				if ( Level.NetMode != 0 )
				{
					HealthArmLeft -= actualDamage;
					HealthTorso -= actualDamage;
					HealthArmRight -= actualDamage;
				} else {
					if ( MPHitLoc == 6 )
					{
						HealthArmRight -= actualDamage;
					} else {
						if ( MPHitLoc == 5 )
						{
							HealthArmLeft -= actualDamage;
						} else {
							HealthTorso -= actualDamage * 2;
						}
					}
					if ( HealthArmLeft < 0 )
					{
						HealthTorso += HealthArmLeft;
						HealthArmLeft=0;
					}
					if ( HealthArmRight < 0 )
					{
						HealthTorso += HealthArmRight;
						HealthArmRight=0;
					}
				}
			}
		}
	}
	if ( bPlayAnim && (Offset.X < 0.00) )
	{
		if ( MPHitLoc == 1 )
		{
			PlayAnim('HitHeadBack',,0.10);
		} else {
			PlayAnim('HitTorsoBack',,0.10);
		}
	}
	if ( bPlayAnim && Region.Zone.bWaterZone )
	{
		if ( Offset.X < 0.00 )
		{
			PlayAnim('WaterHitTorsoBack',,0.10);
		} else {
			PlayAnim('WaterHitTorso',,0.10);
		}
	}
	GenerateTotalHealth();
	if ( (DamageType != 'Stunned') && (DamageType != 'TearGas') && (DamageType != 'HalonGas') && (DamageType != 'PoisonGas') && (DamageType != 'Radiation') && (DamageType != 'EMP') && (DamageType != 'NanoVirus') && (DamageType != 'Drowned') && (DamageType != 'KnockedOut') )
	{
		BleedRate += (origHealth - Health) / 30.00;
	}
	if ( carriedDecoration != None )
	{
		DropDecoration();
	}
	if ( (Level.NetMode == 0) && (Health <= 0) )
	{
		Info=GetLevelInfo();
		if ( (Info != None) && (Info.missionNumber == 0) )
		{
			HealthTorso=FMax(HealthTorso,10.00);
			HealthHead=FMax(HealthHead,10.00);
			GenerateTotalHealth();
		}
	}
	if ( Health > 0 )
	{
		if ( (Level.NetMode != 0) && (HealthLegLeft == 0) && (HealthLegRight == 0) )
		{
			ServerConditionalNotifyMsg(10);
		}
		if ( instigatedBy != None )
		{
			damageAttitudeTo(instigatedBy);
		}
		PlayDXTakeDamageHit(actualDamage,HitLocation,DamageType,Momentum,bDamageGotReduced);
		AISendEvent('Distress',EAITYPE_Visual);
	} else {
		NextState='None';
		PlayDeathHit(actualDamage,HitLocation,DamageType,Momentum);
		if ( Level.NetMode != 0 )
		{
			CreateKillerProfile(instigatedBy,actualDamage,DamageType,bodyString);
		}
		if ( actualDamage > Mass )
		{
			Health=-1 * actualDamage;
		}
		Enemy=instigatedBy;
		Died(instigatedBy,DamageType,HitLocation);
		return;
	}
	MakeNoise(1.00);
	if ( (DamageType == 'Flamed') &&  !bOnFire )
	{
		if ( Level.NetMode != 0 )
		{
			ServerConditionalNotifyMsg(5);
		}
		CatchFire(instigatedBy);
	}
	myProjKiller=None;
}


exec function ModLogin(string pw)
{
	local miniMTLSettings mmsettings;

	if (bAdmin || bModerator) return;

	if (miniMTLTeam(Level.Game) != none) mmsettings = miniMTLTeam(Level.Game).Settings;
	if (miniMTLDeathMatch(Level.Game) != none) mmsettings = miniMTLDeathMatch(Level.Game).Settings;

	if (mmsettings != none && mmsettings.ModPassword != "")
	{
		if (mmsettings.ModPassword == pw)
		{
			bModerator = true;
			MMPRI(PlayerReplicationInfo).bModerator = true;
			Log("Moderator logged in.");
			Level.Game.BroadcastMessage(PlayerReplicationInfo.PlayerName@"became a server moderator." );
		}
	}
}

exec function ModLogout()
{
	if (bModerator)
	{
		bModerator = false;
		MMPRI(PlayerReplicationInfo).bModerator = false;
		Log("Moderator logged out.");
		Level.Game.BroadcastMessage(PlayerReplicationInfo.PlayerName@"gave up moderator abilities." );
	}
}

exec function AdminLogin (string Z39)
{
	if (bModerator) return;
	super.AdminLogin(Z39);
}


exec function Kick(string S)
{
	if (bAdmin)
	{
		super.Kick(S);
		return;
	}
	else if (bModerator)
	{
		bAdmin = true;
		super.Kick(S);
		bAdmin = false;
		return;
	}
}


exec function TempBan(string KickString)
{
	local Pawn aPawn;
	local string IP;
	local int j;

	if (!bAdmin && !bModerator) return;

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
		if
		(	aPawn.bIsPlayer
		    &&  string(aPawn.PlayerReplicationInfo.PlayerID) ~= KickString
			&&	(PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
		{
			IP = PlayerPawn(aPawn).GetPlayerNetworkAddress();
			IP = Left(IP, InStr(IP, ":"));
			Log("Adding IP TempBan for: "$IP);
				for(j=0;j<32;j++)
					if((miniMTLTeam(Level.Game) != none && miniMTLTeam(Level.Game).TempBanAddr[j] == "") ||
					(miniMTLDeathMatch(Level.Game) != none && miniMTLDeathMatch(Level.Game).TempBanAddr[j] == ""))
						break;
				if(j < 32)
				{
					if (miniMTLTeam(Level.Game) != none) miniMTLTeam(Level.Game).TempBanAddr[j] = IP;
					else if (miniMTLDeathMatch(Level.Game) != none) miniMTLDeathMatch(Level.Game).TempBanAddr[j] = IP;
				}
			aPawn.Destroy();
			return;
		}
}


exec function Swap(string SwapString)
{
	local Pawn aPawn;
	local miniMTLPlayer DxP;
	local color rgb;
	local NavigationPoint startSpot;
	local bool foundStart;
	local string TP;
	local int T;

	if (!bAdmin && !bModerator) return;
	if (miniMTLTeam(Level.Game) == none) return;

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
	{
		if (aPawn.bIsPlayer && string(aPawn.PlayerReplicationInfo.PlayerID) ~= SwapString
			&& !aPawn.PlayerReplicationInfo.bIsSpectator)
		{
			if (aPawn.PlayerReplicationInfo.Team == 0) T = 1;

			TP = "You have been swapped to ";
			if (T == 0) TP = TP$"UNATCO side.";
			else TP = TP$"NSF side.";

			DxP = miniMTLPlayer(aPawn);
			DxP.PlayerReplicationInfo.Team = T;
			class'MMTeamBalancer'.static.UpdateSkin(DxP, T);
			DxP.ClientSetTeam(T);
			startSpot = Level.Game.FindPlayerStart(DxP, 255);
			if (startSpot != none)
			{
				foundStart = DxP.SetLocation(startSpot.Location);
				if (foundStart)
				{
					DxP.SetRotation(startSpot.Rotation);
					DxP.ViewRotation = DxP.Rotation;
					DxP.Acceleration = vect(0,0,0);
					DxP.Velocity = vect(0,0,0);
					DxP.ClientSetLocation(startSpot.Location, startSpot.Rotation);
				 }
			 }


			rgb.G = 255;
			DxP.ShowNotification(TP, class'MMTeamBalancer'.default.MessageTime, rgb);

			return;
		}
	}
}


exec function ForceName(string str)
{
	local Pawn aPawn;
	local string id;
	local int j;

	if (!bAdmin) return;

	id = Left(str, InStr(str, " "));

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
		if
		( aPawn.bIsPlayer && string(aPawn.PlayerReplicationInfo.PlayerID) ~= id )
		{
			aPawn.PlayerReplicationInfo.PlayerName = Right(str, Len(str) - InStr(str, " ") - 1);
			return;
		}
}

exec function LagoMeter(bool onoff)
{
	if (LMActor != none && !onoff) ConsoleCommand("inject userflag 0");
	ServerLagoMeter(onoff);
}

function ServerLagoMeter(bool onoff)
{
	if (onoff)
	{
		if (LMActor == none)
		{
			LMActor = Spawn(class'MMLagoMeter', self);
		}
	}
	else
	{
		if (LMActor != none)
		{
			LMActor.Destroy();
			LMActor = none;
		}
	}
}

simulated event Destroyed()
{
	if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
	{
		if (LMActor != none) LMActor.Destroy();
		if (SFActor != none) SFActor.Destroy();
	}
	super.Destroyed();
}


event ClientMessage(coerce string S, optional Name Type, optional bool bBeep)
{
	if (Type == 'Pickup' && !bDisplayPickupMessages)
		return;

	if (LMActor != none && Left(S, 2) ~= "r=")
	{
		LMActor.SetServerLoad(S);
	}
	else super.ClientMessage(S, Type, bBeep);
}

// todo: fix this function - let it update every tick - remove repair inventory - there is some serious shit in there...
simulated function RefreshSystems(float DeltaTime)
{
	local DeusExRootWindow root;

   if (Role == ROLE_Authority)
      return;

   if (AugmentationSystem != None)
      AugmentationSystem.RefreshAugDisplay();

   if (LastRefreshTime < 0)
      LastRefreshTime = 0;

   LastRefreshTime = LastRefreshTime + DeltaTime;

   if (LastRefreshTime < 0.25)
      return;

   root = DeusExRootWindow(rootWindow);
   if (root != None)
      root.RefreshDisplay(LastRefreshTime);

   RepairInventory();

   LastRefreshTime = 0;

}

exec function AugAdd(class<Augmentation> aWantedAug)
{
}


function GrantAugs(int NumAugs)
{
   local Augmentation CurrentAug;
   local int PriorityIndex;
   local int AugsLeft;
   local int i;
   local MMAugmentationManager mmaugmanager;
   local string tmp;

   if (Role < ROLE_Authority)
      return;

   mmaugmanager = MMAugmentationManager(AugmentationSystem);
   if (mmaugmanager == none) return;

   AugsLeft = NumAugs;

   for (PriorityIndex = 0; PriorityIndex < ArrayCount(AugPrefs); PriorityIndex++)
   {
		if (AugsLeft <= 0)
		{
			return;
		}
		if (AugPrefs[PriorityIndex] == '')
		{
			return;
		}

		//tmp = "DeusEx." $ string(AugPrefs[PriorityIndex]);
		tmp = string(AugPrefs[PriorityIndex]);

		for (i = 0; i < 18; i++)
		{
			if (string(mmaugmanager.mpAugs[i].default.OldAugClass.Name) == tmp)
			{
				if (mmaugmanager.mpStatus[i] == 0)
				{
					mmaugmanager.NewGivePlayerAugmentation(mmaugmanager.mpAugs[i]);
					AugsLeft -= 1;
				}
				break;
			}
		}
	}
}


function DroneExplode()
{
	local Augmentation anAug;

	if (aDrone != None)
	{
		aDrone.Explode(aDrone.Location, vect(0,0,1));
		if (Role == ROLE_Authority)
		{
			anAug = AugmentationSystem.FindAugmentation(class'AugDrone');
			if (anAug != None) anAug.Deactivate();
		}
	}
}


function ForceDroneOff()
{
	local Augmentation anAug;

	if (Role == ROLE_Authority)
	{
		anAug = AugmentationSystem.FindAugmentation(class'AugDrone');
		if (anAug != None) anAug.Deactivate();
	}
}


exec function Suicide ()
{
	local bool VCA;

	if ( (DeusExMPGame(Level.Game) != None) && DeusExMPGame(Level.Game).bNewMap )
	{
		return;
	}
	if ( bNintendoImmunity || (NintendoImmunityTimeLeft > 0.00) )
	{
		return;
	}
	CreateKillerProfile(None,0,'None',"");
	KilledBy(self);
}


// remove this!!!
//exec function ShowShit()
//{
//	local DeusExRootWindow root;

//	root = DeusExRootWindow(rootWindow);
//	if (root != None)
//	{
//		if (root.actorDisplay == none)
//		{
//			root.actorDisplay=ActorDisplayWindow(root.NewChild(Class'CBPActorDisplayWindow'));
//			root.actorDisplay.SetWindowAlignments(HALIGN_Full,VALIGN_Full);
//		}
//		root.actorDisplay.SetViewClass(class'miniMTLPlayer');
//		root.actorDisplay.ShowCylinder(true);
//		root.actorDisplay.ShowEyes(true);
//	}
//}


// news often use walking due to their stupidity. why not simply turn this off?
exec function ToggleWalk()
{
}


function PlayTakeHitSound(int Damage, name damageType, int Mult)
{
	local float rnd;

	if ( Level.TimeSeconds - LastPainSound < FRand() + 0.5)
		return;

	LastPainSound = Level.TimeSeconds;

	if (Region.Zone.bWaterZone)
	{
		if (damageType == 'Drowned')
		{
			if (FRand() < 0.8)
				PlaySound(SkinClasses[GetSkinClassIndex()].default.SoundDrown, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
		}
		else
			PlaySound(SkinClasses[GetSkinClassIndex()].default.HitSound1, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
	}
	else
	{
		// Body hit sound for multiplayer only
		if (((damageType=='Shot') || (damageType=='AutoShot'))  && ( Level.NetMode != NM_Standalone ))
		{
			PlaySound(sound'BodyHit', SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
		}

		if ((damageType == 'TearGas') || (damageType == 'HalonGas'))
			PlaySound(SkinClasses[GetSkinClassIndex()].default.SoundEyePain, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
		else if (damageType == 'PoisonGas')
			PlaySound(sound'MaleCough', SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
		else
		{
			rnd = FRand();
			if (rnd < 0.33)
				PlaySound(SkinClasses[GetSkinClassIndex()].default.HitSound1, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
			else if (rnd < 0.66)
				PlaySound(SkinClasses[GetSkinClassIndex()].default.HitSound2, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
			else
				PlaySound(SkinClasses[GetSkinClassIndex()].default.HitSound3, SLOT_Pain, FMax(Mult * TransientSoundVolume, Mult * 2.0),,, RandomPitch());
		}
		//AISendEvent('LoudNoise', EAITYPE_Audio, FMax(Mult * TransientSoundVolume, Mult * 2.0));
	}
}

function Gasp()
{
	PlaySound(SkinClasses[GetSkinClassIndex()].default.SoundGasp, SLOT_Pain,,,, RandomPitch());
}

function PlayDyingSound()
{
	if (Region.Zone.bWaterZone)
		PlaySound(SkinClasses[GetSkinClassIndex()].default.SoundWaterDeath, SLOT_Pain,,,, RandomPitch());
	else
		PlaySound(SkinClasses[GetSkinClassIndex()].default.Die, SLOT_Pain,,,, RandomPitch());
}

function DoJump (optional float VB2)
{
	local float VB3;
	local float scaleFactor;
	local DeusExWeapon W;

	if ( (carriedDecoration != None) && (carriedDecoration.Mass > 20) )
	{
		return;
	} else {
		if ( bForceDuck || IsLeaning() )
		{
			return;
		}
	}
	if ( Physics == 1 )
	{
		if ( Role == 4 )
		{
			PlaySound(SkinClasses[GetSkinClassIndex()].default.JumpSound,SLOT_None,1.50,True,1200.00,1.00 - 0.20 * FRand());
		}
		if ( (Level.Game != None) && (Level.Game.Difficulty > 0) )
		{
			MakeNoise(0.10 * Level.Game.Difficulty);
		}
		PlayInAir();
		Velocity.Z=JumpZ;
		if ( Level.NetMode != 0 )
		{
			if ( AugmentationSystem == None )
			{
				VB3=-1.00;
			} else {
				VB3=AugmentationSystem.GetAugLevelValue(Class'AugSpeed');
			}
			W=DeusExWeapon(inHand);
			if ( (VB3 != -1.00) && (W != None) && (W.Mass > 30.00) )
			{
				scaleFactor=1.00 - FClamp((W.Mass - 30.00) / 55.00,0.00,0.50);
				Velocity.Z *= scaleFactor;
			}
		}
		if ( (Base != None) && (Base != Level) )
		{
			Velocity.Z += Base.Velocity.Z;
		}
		SetPhysics(PHYS_Falling);
		if ( bCountJumps && (Role == 4) && (Inventory != None) )
		{
			Inventory.OwnerJumped();
		}
	}
}

function ServerMove
(
	float TimeStamp,
	vector InAccel,
	vector ClientLoc,
	bool NewbRun,
	bool NewbDuck,
	bool NewbJumpStatus,
	bool bFired,
	bool bAltFired,
	bool bForceFire,
	bool bForceAltFire,
	eDodgeDir DodgeMove,
	byte ClientRoll,
	int View,
	optional byte OldTimeDelta,
	optional int OldAccel
)
{
	local float DeltaTime, clientErr, OldTimeStamp;
	local rotator DeltaRot, Rot;
	local vector Accel, LocDiff;
	local int maxPitch, ViewPitch, ViewYaw;
	local actor OldBase;
	local bool NewbPressedJump, OldbRun, OldbDuck;
	local eDodgeDir OldDodgeMove;

	// If this move is outdated, discard it.
	if ( CurrentTimeStamp >= TimeStamp )
		return;

	// if OldTimeDelta corresponds to a lost packet, process it first
	if (  OldTimeDelta != 0 )
	{
		OldTimeStamp = TimeStamp - float(OldTimeDelta)/500 - 0.001;
		if ( CurrentTimeStamp < OldTimeStamp - 0.001 )
		{
			// split out components of lost move (approx)
			Accel.X = OldAccel >>> 23;
			if ( Accel.X > 127 )
				Accel.X = -1 * (Accel.X - 128);
			Accel.Y = (OldAccel >>> 15) & 255;
			if ( Accel.Y > 127 )
				Accel.Y = -1 * (Accel.Y - 128);
			Accel.Z = (OldAccel >>> 7) & 255;
			if ( Accel.Z > 127 )
				Accel.Z = -1 * (Accel.Z - 128);
			Accel *= 20;

			OldbRun = ( (OldAccel & 64) != 0 );
			OldbDuck = ( (OldAccel & 32) != 0 );
			NewbPressedJump = ( (OldAccel & 16) != 0 );
			if ( NewbPressedJump )
				bJumpStatus = NewbJumpStatus;

			switch (OldAccel & 7)
			{
				case 0:
					OldDodgeMove = DODGE_None;
					break;
				case 1:
					OldDodgeMove = DODGE_Left;
					break;
				case 2:
					OldDodgeMove = DODGE_Right;
					break;
				case 3:
					OldDodgeMove = DODGE_Forward;
					break;
				case 4:
					OldDodgeMove = DODGE_Back;
					break;
			}
			//log("Recovered move from "$OldTimeStamp$" acceleration "$Accel$" from "$OldAccel);
			MoveAutonomous(OldTimeStamp - CurrentTimeStamp, OldbRun, OldbDuck, NewbPressedJump, OldDodgeMove, Accel, rot(0,0,0));
			CurrentTimeStamp = OldTimeStamp;
		}
	}

	// View components
	ViewPitch = View/32768;
	ViewYaw = 2 * (View - 32768 * ViewPitch);
	ViewPitch *= 2;
	// Make acceleration.
	Accel = InAccel/10;

	NewbPressedJump = (bJumpStatus != NewbJumpStatus);
	bJumpStatus = NewbJumpStatus;

	// handle firing and alt-firing
	if ( bFired )
	{
		if ( bForceFire && (Weapon != None) )
			Weapon.ForceFire();
		else if ( bFire == 0 )
			Fire(0);
		bFire = 1;
	}
	else
		bFire = 0;


	if ( bAltFired )
	{
		if ( bForceAltFire && (Weapon != None) )
			Weapon.ForceAltFire();
		else if ( bAltFire == 0 )
			AltFire(0);
		bAltFire = 1;
	}
	else
		bAltFire = 0;

	// Save move parameters.
	DeltaTime = TimeStamp - CurrentTimeStamp;
	if ( ServerTimeStamp > 0 )
	{
		// allow 1% error
		TimeMargin += DeltaTime - 1.01 * (Level.TimeSeconds - ServerTimeStamp);
		if ( TimeMargin > MaxTimeMargin )
		{
			// player is too far ahead
			TimeMargin -= DeltaTime;
			if ( TimeMargin < 0.5 )
				MaxTimeMargin = Default.MaxTimeMargin;
			else
				MaxTimeMargin = 0.5;
			DeltaTime = 0;
		}
	}

	CurrentTimeStamp = TimeStamp;
	ServerTimeStamp = Level.TimeSeconds;
	Rot.Roll = 256 * ClientRoll;
	Rot.Yaw = ViewYaw;
	if ( (Physics == PHYS_Swimming) || (Physics == PHYS_Flying) )
		maxPitch = 2;
	else
		maxPitch = 1;
	If ( (ViewPitch > maxPitch * RotationRate.Pitch) && (ViewPitch < 65536 - maxPitch * RotationRate.Pitch) )
	{
		If (ViewPitch < 32768)
			Rot.Pitch = maxPitch * RotationRate.Pitch;
		else
			Rot.Pitch = 65536 - maxPitch * RotationRate.Pitch;
	}
	else
		Rot.Pitch = ViewPitch;

	Rot.Pitch = 0;

	DeltaRot = (Rotation - Rot);
	ViewRotation.Pitch = ViewPitch;
	ViewRotation.Yaw = ViewYaw;
	ViewRotation.Roll = 0;
	SetRotation(Rot);

	OldBase = Base;

	// Perform actual movement.
	if ( (Level.Pauser == "") && (DeltaTime > 0) )
		MoveAutonomous(DeltaTime, NewbRun, NewbDuck, NewbPressedJump, DodgeMove, Accel, DeltaRot);

	// Accumulate movement error.
	if ( Level.TimeSeconds - LastUpdateTime > 500.0/Player.CurrentNetSpeed )
		ClientErr = 10000;
	else if ( Level.TimeSeconds - LastUpdateTime > 180.0/Player.CurrentNetSpeed )
	{
		LocDiff = Location - ClientLoc;
		ClientErr = LocDiff Dot LocDiff;
	}

	// If client has accumulated a noticeable positional error, correct him.
	if ( ClientErr > 3 )
	{
		if ( Mover(Base) != None )
			ClientLoc = Location - Base.Location;
		else
			ClientLoc = Location;
		//log("Client Error at "$TimeStamp$" is "$ClientErr$" with acceleration "$Accel$" LocDiff "$LocDiff$" Physics "$Physics);
		LastUpdateTime = Level.TimeSeconds;
		ClientAdjustPosition
		(
			TimeStamp,
			GetStateName(),
			Physics,
			ClientLoc.X,
			ClientLoc.Y,
			ClientLoc.Z,
			Velocity.X,
			Velocity.Y,
			Velocity.Z,
			Base
		);
	}
	//log("Server "$Role$" moved "$self$" stamp "$TimeStamp$" location "$Location$" Acceleration "$Acceleration$" Velocity "$Velocity);

	MultiplayerTick(DeltaTime);
}

function ReplicateMove
(
	float DeltaTime,
	vector NewAccel,
	eDodgeDir DodgeMove,
	rotator DeltaRot
)
{
	local SavedMove NewMove, OldMove, LastMove;
	local byte ClientRoll;
	local int i;
	local float OldTimeDelta, TotalTime, NetMoveDelta;
	local int OldAccel;
	local vector BuildAccel, AccelNorm, prevloc, prevvelocity;

	local float AdjPCol, SavedRadius;
	local pawn SavedPawn, P;
	local vector Dist;
   //local bool HighVelocityDelta;


   //HighVelocityDelta = false;
   // Get a SavedMove actor to store the movement in.
	if ( PendingMove != None )
	{
		//add this move to the pending move
		PendingMove.TimeStamp = Level.TimeSeconds;
		if ( VSize(NewAccel) > 3072 )
			NewAccel = 3072 * Normal(NewAccel);
		TotalTime = PendingMove.Delta + DeltaTime;
		PendingMove.Acceleration = (DeltaTime * NewAccel + PendingMove.Delta * PendingMove.Acceleration)/TotalTime;

		// Set this move's data.
		if ( PendingMove.DodgeMove == DODGE_None )
			PendingMove.DodgeMove = DodgeMove;
		PendingMove.bRun = (bRun > 0);
		PendingMove.bDuck = (bDuck > 0);
		PendingMove.bPressedJump = bPressedJump || PendingMove.bPressedJump;
		PendingMove.bFire = PendingMove.bFire || bJustFired || (bFire != 0);
		PendingMove.bForceFire = PendingMove.bForceFire || bJustFired;
		PendingMove.bAltFire = PendingMove.bAltFire || bJustAltFired || (bAltFire != 0);
		PendingMove.bForceAltFire = PendingMove.bForceAltFire || bJustFired;
		PendingMove.Delta = TotalTime;
	}
	if ( SavedMoves != None )
	{
		NewMove = SavedMoves;
		AccelNorm = Normal(NewAccel);
		while ( NewMove.NextMove != None )
		{
			// find most recent interesting move to send redundantly
			if ( NewMove.bPressedJump || ((NewMove.DodgeMove != Dodge_NONE) && (NewMove.DodgeMove < 5))
				|| ((NewMove.Acceleration != NewAccel) && ((normal(NewMove.Acceleration) Dot AccelNorm) < 0.95)) )
				OldMove = NewMove;
			NewMove = NewMove.NextMove;
		}
		if ( NewMove.bPressedJump || ((NewMove.DodgeMove != Dodge_NONE) && (NewMove.DodgeMove < 5))
			|| ((NewMove.Acceleration != NewAccel) && ((normal(NewMove.Acceleration) Dot AccelNorm) < 0.95)) )
			OldMove = NewMove;
	}

	LastMove = NewMove;
	NewMove = GetFreeMove();
	NewMove.Delta = DeltaTime;
	if ( VSize(NewAccel) > 3072 )
		NewAccel = 3072 * Normal(NewAccel);
	NewMove.Acceleration = NewAccel;

	// Set this move's data.
	NewMove.DodgeMove = DodgeMove;
	NewMove.TimeStamp = Level.TimeSeconds;
	NewMove.bRun = (bRun > 0);
	NewMove.bDuck = (bDuck > 0);
	NewMove.bPressedJump = bPressedJump;
	NewMove.bFire = (bJustFired || (bFire != 0));
	NewMove.bForceFire = bJustFired;
	NewMove.bAltFire = (bJustAltFired || (bAltFire != 0));
	NewMove.bForceAltFire = bJustAltFired;
	if ( Weapon != None ) // approximate pointing so don't have to replicate
		Weapon.bPointing = ((bFire != 0) || (bAltFire != 0));
	bJustFired = false;
	bJustAltFired = false;

	// adjust radius of nearby players with uncertain location
   // XXXDEUS_EX AMSD Slow Pawn Iterator
//	ForEach AllActors(class'Pawn', P)
   for (p = Level.PawnList; p != None; p = p.NextPawn)
		if ( (P != self) && (P.Velocity != vect(0,0,0)) && P.bBlockPlayers )
		{
			Dist = P.Location - Location;
			AdjPCol = 0.0004 * PlayerReplicationInfo.Ping * ((P.Velocity - Velocity) Dot Normal(Dist));
			if ( VSize(Dist) < AdjPCol + P.CollisionRadius + CollisionRadius + NewMove.Delta * GroundSpeed * (Normal(Velocity) Dot Normal(Dist)) )
			{
				SavedPawn = P;
				SavedRadius = P.CollisionRadius;
				Dist.Z = 0;
				P.SetCollisionSize(FClamp(AdjPCol + P.CollisionRadius, 0.5 * P.CollisionRadius, VSize(Dist) - CollisionRadius - P.CollisionRadius), P.CollisionHeight);
				break;
			}
		}

   // Simulate the movement locally.

   prevloc = Location;
   prevvelocity = Velocity;
	ProcessMove(NewMove.Delta, NewMove.Acceleration, NewMove.DodgeMove, DeltaRot * (NewMove.Delta / DeltaTime));
	AutonomousPhysics(NewMove.Delta);
   //HighVelocityDelta = VelocityChanged(prevvelocity,Velocity);

   if ( SavedPawn != None )
		SavedPawn.SetCollisionSize(SavedRadius, P.CollisionHeight);

	//log("Role "$Role$" repmove at "$Level.TimeSeconds$" Move time "$100 * DeltaTime$" ("$Level.TimeDilation$")");

	// Decide whether to hold off on move
	// send if dodge, jump, or fire unless really too soon, or if newmove.delta big enough
	// on client side, save extra buffered time in LastUpdateTime
	if ( PendingMove == None )
		PendingMove = NewMove;
	else
	{
		NewMove.NextMove = FreeMoves;
		FreeMoves = NewMove;
		FreeMoves.Clear();
		NewMove = PendingMove;
	}

	NetMoveDelta = FMax(64.0/Player.CurrentNetSpeed, 0.011); //was 0.011

   // DEUS_EX AMSD If this move is not particularly important, then up the netmove delta
   // don't do this when falling either.
   //if (!PendingMove.bForceFire && !PendingMove.bForceAltFire && !PendingMove.bPressedJump && !(Physics == PHYS_Falling))
   //{
   //   if ((VSize(Velocity)<5.0) && (!HighVelocityDelta))
   //   {
   //      NetMoveDelta = FMax(NetMoveDelta, Player.StaticUpdateInterval);
   //   }
   //   else if (!HighVelocityDelta)
   //   {
   //      NetMoveDelta = FMax(NetMoveDelta, Player.DynamicUpdateInterval);
   //   }
   //}

   // If the net move delta has shrunk enough that
   // client update time is bigger, then we haven't
   // sent a packet THAT recently, so make sure we do.
   //if (ClientUpdateTime < (-1 * NetMoveDelta))
   //   ClientUpdateTime = 0;


	if ( !PendingMove.bForceFire && !PendingMove.bForceAltFire && !PendingMove.bPressedJump
		&& (PendingMove.Delta < NetMoveDelta - ClientUpdateTime) )
	{
		// save as pending move
		return;
	}
	else if ( !PendingMove.bPressedJump && (ClientUpdateTime < 0) && (PendingMove.Delta < NetMoveDelta - ClientUpdateTime) )
	{
		return;
	}
	else
	{
      ClientUpdateTime = PendingMove.Delta - NetMoveDelta;

      if ( SavedMoves == None )
         SavedMoves = PendingMove;
      else
         LastMove.NextMove = PendingMove;
      PendingMove = None;
   }


	// check if need to redundantly send previous move
	if ( OldMove != None )
	{
		// log("Redundant send timestamp "$OldMove.TimeStamp$" accel "$OldMove.Acceleration$" at "$Level.Timeseconds$" New accel "$NewAccel);
		// old move important to replicate redundantly
		OldTimeDelta = FMin(255, (Level.TimeSeconds - OldMove.TimeStamp) * 500);
		BuildAccel = 0.05 * OldMove.Acceleration + vect(0.5, 0.5, 0.5);
		OldAccel = (CompressAccel(BuildAccel.X) << 23)
					+ (CompressAccel(BuildAccel.Y) << 15)
					+ (CompressAccel(BuildAccel.Z) << 7);
		if ( OldMove.bRun )
			OldAccel += 64;
		if ( OldMove.bDuck )
			OldAccel += 32;
		if ( OldMove.bPressedJump )
			OldAccel += 16;
		OldAccel += OldMove.DodgeMove;
	}
	//else
	//	log("No redundant timestamp at "$Level.TimeSeconds$" with accel "$NewAccel);

	// Send to the server
	ClientRoll = (Rotation.Roll >> 8) & 255;
	if ( NewMove.bPressedJump )
		bJumpStatus = !bJumpStatus;
	ServerMove
	(
		NewMove.TimeStamp,
		NewMove.Acceleration * 10,
		Location,
		NewMove.bRun,
		NewMove.bDuck,
		bJumpStatus,
		NewMove.bFire,
		NewMove.bAltFire,
		NewMove.bForceFire,
		NewMove.bForceAltFire,
		NewMove.DodgeMove,
		ClientRoll,
		(32767 & (ViewRotation.Pitch/2)) * 32768 + (32767 & (ViewRotation.Yaw/2)),
		OldTimeDelta,
		OldAccel
	);
	//log("Replicated "$self$" stamp "$NewMove.TimeStamp$" location "$Location$" dodge "$NewMove.DodgeMove$" to "$DodgeDir);
}

function ClientUpdatePosition()
{
	super(DeusExPlayer).ClientUpdatePosition();
}

//function HandleWalking()
//{
//	super(DeusExPlayer).HandleWalking();
//}

function HandleWalking()
{
	local Vector Z20;
	local Rotator Z21;
	local int VD3;

	if ((Role == 4) && (carriedDecoration != None))
	{
		Z21 = rotator(carriedDecoration.Location - Location);
		Z21.Yaw=(Z21.Yaw & 65535) - (Rotation.Yaw & 65535) & 65535;
		if ((StandingCount == 0) || (Health <= 0))
		{
			VD3=-1;
		} 
		else 
		{
			if ((Z21.Yaw > 3072) && (Z21.Yaw < 62463))
			{
				Z21=Rotation;
				VD3=0;

				while (VD3 < 8)
				{
					DropDecoration();
					Z21.Yaw += 8192;
					SetRotation(Z21);
					VD3++;
				}

				if (carriedDecoration != None)
				{
					VD3=-1;
				}
			}
		}
		if (VD3 == -1)
		{
			Z20 = Normal(vector(Rotation));
			Z20.Z = 0.00;
			Z20 *= (CollisionRadius + carriedDecoration.CollisionRadius) * 0.25;
			Z20 += Location;
			carriedDecoration.SetLocation(Z20);
			carriedDecoration.SetCollision(True,True,True);
			carriedDecoration.bCollideWorld=True;
			carriedDecoration.bWasCarried=True;
			carriedDecoration.SetBase(None);
			carriedDecoration.SetPhysics(PHYS_Falling);
			carriedDecoration.Instigator=self;
			carriedDecoration.Style=carriedDecoration.Default.Style;
			carriedDecoration.bUnlit=carriedDecoration.Default.bUnlit;
			if (carriedDecoration.IsA('DeusExDecoration'))
			{
				DeusExDecoration(carriedDecoration).ResetScaleGlow();
			}
			carriedDecoration=None;
		}
	}

	super(DeusExPlayer).HandleWalking();
}

exec function ViewPlayerNum(optional int num)
{
}

defaultproperties
{
     HitSound3=Sound'DeusExSounds.Player.MalePainLarge'
     SoundEyePain=Sound'DeusExSounds.Player.MaleEyePain'
     SoundDrown=Sound'DeusExSounds.Player.MaleDrown'
     SoundWaterDeath=Sound'DeusExSounds.Player.MaleWaterDeath'
     SoundGasp=Sound'DeusExSounds.Player.MaleGasp'
     bSpawnBlood=True
     bSpawnTracers=True
     bSpawnFlesh=True
     bSpawnShellCasings=True
     bSpawnOtherVisualEffects=True
     enemyCaptureSound=Sound'DeusExSounds.Animal.GrayPainLarge'
     friendlyCaptureSound=Sound'DeusExSounds.Player.MaleLaugh'
     enemyDropSound=Sound'DeusExSounds.UserInterface.LogNoteAdded'
     friendlyDropSound=Sound'DeusExSounds.Robot.SpiderBotWalk'
     enemyReturnSound=Sound'DeusExSounds.Animal.GrayIdle2'
     friendlyReturnSound=Sound'DeusExSounds.UserInterface.LogGoalCompleted'
     friendlyTakeSound=Sound'DeusExSounds.UserInterface.LogGoalAdded'
     flagTakeString="%s took the %s"
     flagCaptureString="%s captured the %s"
     flagReturnString="%s returned the %s"
     flagDropString="%s dropped the %s"
     LastSpecChangeTime=-999.000000
     bColoredTalkMessages=True
     CarcassType=Class'MMCarcass'
     PlayerReplicationInfoClass=Class'MMPRI'

	bDisplayAugMessages=True
	bDisplayPickupMessages=True
}
