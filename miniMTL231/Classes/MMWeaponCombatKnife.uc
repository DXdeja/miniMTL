class MMWeaponCombatKnife extends WeaponCombatKnife;

var float lastShotTime;
var float ffrtolerance;

var float CBPmpHitDamage;

function PostBeginPlay()
{
	super.PostBeginPlay();
	if (miniMTLTeam(Level.Game) != none) ffrtolerance = miniMTLTeam(Level.Game).Settings.FastFireRateTolerance;
	else if (miniMTLDeathmatch(Level.Game) != none) ffrtolerance = miniMTLDeathmatch(Level.Game).Settings.FastFireRateTolerance;

	if ((miniMTLTeam(Level.Game) != none && miniMTLTeam(Level.Game).bCBP) ||
		(miniMTLDeathMatch(Level.Game) != none && miniMTLDeathMatch(Level.Game).bCBP)) HitDamage = CBPmpHitDamage;
}

function Fire(float Value)
{
	local float diff;

	diff = Level.TimeSeconds - lastShotTime;
	diff -= 0.49 - ffrtolerance;
	if (diff < 0.0) return;
	lastShotTime = Level.TimeSeconds;

	super.Fire(value);
}

// fix bug related to firing when having no weapon in hand
simulated function bool ClientFire( float value )
{
	if (DeusExPlayer(Owner) != none && DeusExPlayer(Owner).inHand != self) return false;
	return super.ClientFire(value);
}

simulated function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local float        mult;
	local name         damageType;
	local DeusExPlayer dxPlayer;

	if (Other != None)
	{
		// AugCombat increases our damage if hand to hand
		mult = 1.0;
		if (bHandToHand && (DeusExPlayer(Owner) != None))
		{
			mult = DeusExPlayer(Owner).AugmentationSystem.GetAugLevelValue(class'AugCombat');
			if (mult == -1.0)
				mult = 1.0;
		}

		// skill also affects our damage
		// GetWeaponSkill returns 0.0 to -0.7 (max skill/aug)
		mult += -2.0 * GetWeaponSkill();

		// Determine damage type
		damageType = WeaponDamageType();

		if (Other != None)
		{
			if (Other.bOwned)
			{
				dxPlayer = DeusExPlayer(Owner);
				if (dxPlayer != None)
					dxPlayer.AISendEvent('Futz', EAITYPE_Visual);
			}
		}
		if ((Other == Level) || (Other.IsA('Mover')))
		{
			if ( Role == ROLE_Authority )
				Other.TakeDamage(HitDamage * mult, Pawn(Owner), HitLocation, 1000.0*X, damageType);

			SelectiveSpawnEffects( HitLocation, HitNormal, Other, HitDamage * mult);
		}
		else if ((Other != self) && (Other != Owner))
		{
			if ( Role == ROLE_Authority )
				Other.TakeDamage(HitDamage * mult, Pawn(Owner), HitLocation, 1000.0*X, damageType);
			if (bHandToHand)
				SelectiveSpawnEffects( HitLocation, HitNormal, Other, HitDamage * mult);

			if (Role == ROLE_Authority && miniMTLPlayer(Other) != none)
			{
				if (bPenetrating && Other.IsA('Pawn') && !Other.IsA('Robot'))
					miniMTLPlayer(Other).SpawnBloodFromWeapon(HitLocation, HitNormal);
			}
		}
	}
   if (DeusExMPGame(Level.Game) != None)
   {
      if (DeusExPlayer(Other) != None)
         DeusExMPGame(Level.Game).TrackWeapon(self,HitDamage * mult);
      else
         DeusExMPGame(Level.Game).TrackWeapon(self,0);
   }
}

defaultproperties
{
     ffrtolerance=0.015000
     CBPmpHitDamage=25.000000
}
