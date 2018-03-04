class miniMTLCTFFlag extends DeusExDecoration;
   
var miniMTLPlayer carrier;
var int carrierID;
var int team;
//var int autoReturnTime;
var vector baseLoc;
var bool bUpdateBaseLoc;
var string teamString;
//what to put after the 'teamString' when displaying on the HUD
var string flagString, HQString;
var float lastTakeTime;
var vector loc;
var vector carrierLastLoc;
//how long after dropping the flag can a player pick it up again?
var float dropTakeTime;
//don't let the last carrier immediately pick up the flag again
var miniMTLPlayer lastCarrier;
var float lastDropTime;
//offset of flag to player when carried (from the floor)
//this is so we can raise the flag for smaller flag models etc. (or lower it?)
//so the ambrosia etc. looks as tho the player is carrying rather than dragging it
var float carrierAdjustHeight;
var int escapeTime;
var bool bEscaping;

enum flagEvent_e
{
   FEV_Take,
   FEV_TakeFromField,
   FEV_Drop,
   FEV_DropOnPurpose,
   FEV_Return,
   FEV_Capture,
   //FEV_AutoReturn,
   FEV_Escape
};

replication
{
   //server->client
   reliable if (role == ROLE_Authority)
      baseLoc, /*autoReturnTime,*/ teamString, flagString, HQString,
      team, escapeTime;
      
   //server->client, things which will change
   reliable if (role == ROLE_Authority)
      carrier; //only when carrier is relevant to player
               //(i.e. server will send it to player when the carrier
               //comes into view)

   //this needs to be sent out initially the get the simulated flags
   //into sync with that of the server
   reliable if (bNetInitial)
      carrierID, bEscaping; //got to send out the escaping?

   //when the flag is with player, server sends out location
   //but ONLY when the client can't actually see the carrier (if
   //carrier is valid, then we don't need to replicate the 'loc' variable)
   reliable if (role == ROLE_Authority && isInState('withPlayer') && !carrier.bNetRelevant)
      loc;
}


simulated function refreshItemName()
{
   //set the itemname
   itemName = teamString $ " " $ flagString;
}


simulated function postNetBeginPlay()
{
   super.postNetBeginPlay();

   refreshItemName();
}


simulated function beginPlay()
{
   super.beginPlay();
   
   if (role < ROLE_Authority)
      return;
      
   //set it now but it will re-adjust once flag hits floor
   baseLoc = location;
}


simulated function adjustToPlayer(miniMTLPlayer player)
{
   local vector newLoc;
   
   newLoc = (player.location)-(vector(player.rotation))*collisionRadius*1.25;
   newLoc.z += carrierAdjustHeight;

   setLocation(newLoc);
   setRotation(player.rotation + default.rotation);
   setBase(player);
   
   //server also needs to keep track of these, and replicate the location
   if (role == ROLE_Authority)
   {
      carrierLastLoc = carrier.location;
      loc = location;
   }
}


simulated function setMobile(bool mobile)
{
   if (mobile)
   {
      setCollision(false, false, false);
      bCollideWorld = false;
      setPhysics(PHYS_None);
   }
   else
   {
      setCollision(true, true, true);
      bCollideWorld = true;
      setPhysics(PHYS_Falling);
   }
}


function flagEvent(flagEvent_e ev, /*optional */ miniMTLPlayer player)
{
   local miniMTLCTF game;
   local Pawn pawn;
   local miniMTLPlayer client;
   
   game = miniMTLCTF(level.game);
   if (game != none)
   {
      switch(ev)
      {
      case FEV_Take:
         game.flagTake(self, player, true);
         break;
      case FEV_TakeFromField:
         game.flagTake(self, player, false);
         break;
      case FEV_Drop:
         game.flagDrop(self, player, false);
         break;
      case FEV_DropOnPurpose:
         game.flagDrop(self, player, true);
         break;
      case FEV_Return:
         game.flagReturn(self, player);
         break;
      case FEV_Capture:
         game.flagCapture(self, carrier);
         break;
      //case FEV_AutoReturn:
      //   game.flagAutoReturn(self);
      //   break;
      }
   }
   
   //multicast the event out to all players
   for (pawn=level.pawnList; pawn!=none; pawn=pawn.nextPawn)
   {
      client = miniMTLPlayer(pawn);

      if (client != none)
      {
         switch(ev)
         {
         case FEV_Take:
         case FEV_TakeFromField:
            client.flagTake(self, player.playerReplicationInfo.playerID, Player.PlayerReplicationInfo.Team == client.PlayerReplicationInfo.Team);
            break;
         case FEV_Drop:
         case FEV_DropOnPurpose:
            client.flagDrop(self, carrierLastLoc, Player.PlayerReplicationInfo.Team == client.PlayerReplicationInfo.Team);
            break;
         case FEV_Return:
            client.flagReturn(self, player.playerReplicationInfo.playerID, Player.PlayerReplicationInfo.Team == client.PlayerReplicationInfo.Team);
            break;
         case FEV_Capture:
            client.flagCapture(self, Player.PlayerReplicationInfo.Team == client.PlayerReplicationInfo.Team);
            break;
         //case FEV_AutoReturn:
         //   client.flagAutoReturn(self);
         //   break;
         case FEV_Escape:
            client.flagEscape(self);
            break;
         }
      }
   }
}


function setCarrier(miniMTLPlayer player)
{
   if (player == none)
   {
      lastCarrier = carrier;
      carrier.getPRI().Flag = none;
      carrier = none;
   }
   else
   {
      carrier = player;
      carrier.getPRI().Flag = self;
   }
}

function int SV_CountEnemies(miniMTLPlayer player)
{
	local int c;
	local Pawn pwn;

	pwn = Level.PawnList;
	while (pwn != none)
	{
		if (pwn.PlayerReplicationInfo != none && 
			Player.PlayerReplicationInfo != none && !pwn.PlayerReplicationInfo.bIsSpectator &&
			pwn.PlayerReplicationInfo.Team != Player.PlayerReplicationInfo.Team) c++;
		pwn = pwn.NextPawn;
	}

	return c;
}


function SV_take(miniMTLPlayer player)
{
   //don't let dead people pick up the flag
   if (player.isInState('Dying')) return;

   //don't let invulnerable people pick up the flag
   if (player.bNintendoImmunity) return;

   //don't let them pick it up too quickly after just dropping it
   if (lastCarrier == player && ((level.timeSeconds - lastDropTime) < dropTakeTime)) return;

   // don't let it pickup if no enemies
   if (SV_CountEnemies(Player) == 0) return;

   setCarrier(player);

   if (IsInState('atBase')) flagEvent(FEV_Take, carrier);
   else flagEvent(FEV_TakeFromField, carrier);

   adjustToPlayer(carrier);
   //if (IsInState('atBase')) 
	 lastTakeTime = Level.timeSeconds;

   CL_take(player.PlayerReplicationInfo.PlayerID);
}


simulated function CL_take(int playerID)
{
   setMobile(true);
   carrierID = playerID;
   bEscaping = true;
   GotoState('withPlayer');
}


function SV_return(miniMTLPlayer player)
{
	lastCarrier = none;
   flagEvent(FEV_Return, player);
   CL_return(player.PlayerReplicationInfo.PlayerID);
}


simulated function CL_return(int playerID)
{
   SetLocation(baseLoc);
   GotoState('atBase');
}


function SV_drop(bool bOnPurpose)
{
   if (bOnPurpose) 
   {
		flagEvent(FEV_DropOnPurpose, carrier);
   }
   else 
   {
   		flagEvent(FEV_Drop, carrier);
		lastCarrier = none; // set lastcarrier to none, so if player died, 
							// he can recapture the flag immediatelly
   }

   setCarrier(none);
   lastDropTime = Level.timeSeconds;
   CL_drop(carrierLastLoc);
}


simulated function CL_drop(vector location)
{
   //log("CL_drop");
   setMobile(false);
   carrierID = -1;
   setBase(none);
   SetLocation(location);
   //bEscaping = false;
   GotoState('inField');
}


function SV_capture()
{
   flagEvent(FEV_Capture, carrier);
   SetCarrier(none);
   CL_capture();
}


simulated function CL_capture()
{
   carrierID = -1;
   setMobile(false);
   setBase(none);
   SetLocation(baseLoc);
   bEscaping = false;
   GotoState('atBase');
}


simulated function CL_escape()
{
   //has escaped
   bEscaping = false;
}


simulated function tick(float deltaTime)
{
   //never EVER go into stasis... EVER
   bStasis = false;
}


auto simulated state atBase
{
   simulated function Tick(float deltaTime)
   {
      global.Tick(deltaTime);
   
      //if simulated, and carrierID is sent out as different from -1
      //then we are actually being carried so change to that state
      //(this will happen when u first connect to the server)
      if (role < ROLE_Authority)
         if (carrierID != -1)
         {
            setMobile(true);
            GotoState('withPlayer');
         }
   
      //if the flag is on server, and has finished falling then update the baseloc
      if (role == ROLE_Authority)
      {
         if (bUpdateBaseLoc && vsize(velocity) == 0)
         {
            baseLoc = location;
            bUpdateBaseLoc = false;
         }
      }
   }


   function Bump(Actor other)
   {
      local miniMTLPlayer player;
      local MMPRI pri;
      
      player = miniMTLPlayer(other);
      if (player == none) return;
         
      pri = player.getPRI();
      if (pri == none) return;
      
      //enemy player, allow pickup
      if (pri.team != team) SV_take(player);
         
      //friendly player, and friendly player has an enemy flag, so cap
      if (pri.team == team)
         if (pri.flag != none)
            pri.flag.SV_capture();
   }

}


simulated state inField
{
   simulated function tick(float deltaTime)
   {
      global.Tick(deltaTime);
   }


   function Bump(Actor other)
   {
      local miniMTLPlayer player;
      local MMPRI pri;
      
      player = miniMTLPlayer(other);
      if (player == none) return;

      pri = player.getPRI();
      if (pri == none) return;

      //enemy player, allow pickup
      if (pri.team != team) SV_take(player);
         
      //friendly player, allow return
      if (pri.team == team) SV_return(player);
   }
}


simulated state withPlayer
{
   simulated function Tick(float deltaTime)
   {
      global.Tick(deltaTime);
   
      //serverside
      if (role == ROLE_Authority)
      {
         //carrier left the game
         if (carrier == none) SV_drop(true); //class as a deliberate drop

         //carrier dropped flag on purpose
         if (carrier.getPRI().Flag != self) SV_drop(true);

         //carrier dropped flag due to death
         else if (carrier.isInState('Dying')) SV_drop(false);
         else
            //carrier still has flag, so put on back
            adjustToPlayer(carrier);
            
         if (bEscaping && ((level.timeSeconds - lastTakeTime) > escapeTime))
         {
            //escape is complete, flag now becomes visible to all players
            //so they can hunt down the carrier!
            flagEvent(FEV_Escape, none);
            CL_escape();
         }
      }
      //clientside
      else
      {
         //adjust onto players back (IF carrier is relevant)
         if (carrier != none)
            adjustToPlayer(carrier);
         else if (carrierID != -1)
         {
            //else just put it where the server keeps telling us
            setBase(none);
            SetLocation(loc);
         }
      }
   }
}

defaultproperties
{
     carrierID=-1
     bUpdateBaseLoc=True
     teamString="US Army"
     flagString="flag"
     HQString="HQ"
     dropTakeTime=60.000000
     carrierAdjustHeight=2.500000
     escapeTime=30
     bInvincible=True
     FragType=Class'DeusEx.WoodFragment'
     bPushable=False
     RemoteRole=ROLE_SimulatedProxy
     Skin=Texture'DeusExDeco.Skins.FlagPoleTex2'
     Mesh=LodMesh'DeusExDeco.FlagPole'
     DrawScale=0.750000
     ScaleGlow=1.500000
     AmbientGlow=150
     bAlwaysRelevant=True
     bAlwaysTick=True
     bGameRelevant=True
     CollisionRadius=10.000000
     CollisionHeight=42.292500
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightBrightness=255
     LightHue=255
     LightSaturation=255
     LightRadius=4
     Mass=40.000000
     Buoyancy=30.000000
     bVisionImportant=True
     NetPriority=4.000000
}
