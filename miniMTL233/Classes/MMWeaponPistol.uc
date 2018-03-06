class MMWeaponPistol extends CBPWeaponPistol;

var float lastShotTime;
var float ffrtolerance;

function PostBeginPlay()
{
	super.PostBeginPlay();
	if (miniMTLTeam(Level.Game) != none) ffrtolerance = miniMTLTeam(Level.Game).Settings.FastFireRateTolerance;
	else if (miniMTLDeathmatch(Level.Game) != none) ffrtolerance = miniMTLDeathmatch(Level.Game).Settings.FastFireRateTolerance;
}

function Fire(float Value)
{
	local float diff;

	diff = Level.TimeSeconds - lastShotTime;
	diff -= 0.585 - ffrtolerance;;
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

simulated function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local Rotator rot;
	local actor Other;
	local float dist, alpha, degrade;
	local int i, numSlugs;
	local float volume, radius;

	// make noise if we are not silenced
	if (!bHasSilencer && !bHandToHand)
	{
		GetAIVolume(volume, radius);
		Owner.AISendEvent('WeaponFire', EAITYPE_Audio, volume, radius);
		Owner.AISendEvent('LoudNoise', EAITYPE_Audio, volume, radius);
		if (!Owner.IsA('PlayerPawn'))
			Owner.AISendEvent('Distress', EAITYPE_Audio, volume, radius);
	}

	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	StartTrace = ComputeProjectileStart(X, Y, Z);
	AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);

	// check to see if we are a shotgun-type weapon
	if (AreaOfEffect == AOE_Cone)
		numSlugs = 5;
	else
		numSlugs = 1;

	// if there is a scope, but the player isn't using it, decrease the accuracy
	// so there is an advantage to using the scope
	if (bHasScope && !bZoomed)
		Accuracy += 0.2;
	// if the laser sight is on, make this shot dead on
	// also, if the scope is on, zero the accuracy so the shake makes the shot inaccurate
	else if (bLasing || bZoomed)
		Accuracy = 0.0;


	for (i=0; i<numSlugs; i++)
	{
      // If we have multiple slugs, then lower our accuracy a bit after the first slug so the slugs DON'T all go to the same place
      if ((i > 0) && (Level.NetMode != NM_Standalone) && !(bHandToHand))
         if (Accuracy < MinSpreadAcc)
            Accuracy = MinSpreadAcc;

      // Let handtohand weapons have a better swing
      if ((bHandToHand) && (NumSlugs > 1) && (Level.NetMode != NM_Standalone))
      {
         StartTrace = ComputeProjectileStart(X,Y,Z);
         StartTrace = StartTrace + (numSlugs/2 - i) * SwingOffset;
      }

      EndTrace = StartTrace + Accuracy * (FRand()-0.5)*Y*1000 + Accuracy * (FRand()-0.5)*Z*1000 ;
      EndTrace += (FMax(1024.0, MaxRange) * vector(AdjustedAim));
      
      Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);

		// randomly draw a tracer for relevant ammo types
		// don't draw tracers if we're zoomed in with a scope - looks stupid
      // DEUS_EX AMSD In multiplayer, draw tracers all the time.
		if ( ((Level.NetMode == NM_Standalone) && (!bZoomed && (numSlugs == 1) && (FRand() < 0.5))) ||
           ((Level.NetMode != NM_Standalone) && (Role == ROLE_Authority) && (numSlugs == 1)) )
		{
			if ((AmmoName == Class'MMAmmo10mm') || (AmmoName == Class'MMAmmo3006') ||
				(AmmoName == Class'MMAmmo762mm'))
			{
				if (VSize(HitLocation - StartTrace) > 250)
				{
					rot = Rotator(EndTrace - StartTrace);
               if ((Level.NetMode != NM_Standalone) && (Self.IsA('WeaponRifle')))
                  Spawn(class'SniperTracer',,, StartTrace + 96 * Vector(rot), rot);
               else
					{
						if (Role == ROLE_Authority && miniMTLPlayer(Owner) != none)
							miniMTLPlayer(Owner).SpawnTracerFromWeapon(StartTrace + 96 * Vector(rot), rot);
					}
				}
			}
		}

		// check our range
		dist = Abs(VSize(HitLocation - Owner.Location));

		if (dist <= AccurateRange)		// we hit just fine
			ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
		else if (dist <= MaxRange)
		{
			// simulate gravity by lowering the bullet's hit point
			// based on the owner's distance from the ground
			alpha = (dist - AccurateRange) / (MaxRange - AccurateRange);
			degrade = 0.5 * Square(alpha);
			HitLocation.Z += degrade * (Owner.Location.Z - Owner.CollisionHeight);
			ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
		}
	}

	// otherwise we don't hit the target at all
}

defaultproperties
{
    ffrtolerance=0.01
    AmmoName=Class'MMAmmo10mm'
}
