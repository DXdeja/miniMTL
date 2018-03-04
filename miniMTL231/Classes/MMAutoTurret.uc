class MMAutoTurret extends AutoTurret;

function SpawnTracerFromWeapon(Vector loc, Rotator rot)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer.LineOfSightTo(self, true) || 
			(Pawn(curplayer.ViewTarget) != none && Pawn(curplayer.ViewTarget).LineOfSightTo(self, true)))
			curplayer.ClientSpawnTracerFromWeapon(self, loc, rot);
	}
}

function SpawnBlood2(Vector HitLocation, Vector HitNormal, Actor hit)
{
	local rotator rot;
	local miniMTLPlayer hitplayer;

	rot = Rotator(Location - HitLocation);
	rot.Pitch = 0;
	rot.Roll = 0;

	hitplayer = miniMTLPlayer(hit);
	if (hitplayer == none) return;

	if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
		return;

	hitplayer.SpawnBloodFromWeapon(HitLocation, HitNormal, rot);
}

function SpawnShellCasing(Vector loc, Rotator rot)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer.LineOfSightTo(self, true) || 
			(Pawn(curplayer.ViewTarget) != none && Pawn(curplayer.ViewTarget).LineOfSightTo(self, true))) 
			curplayer.ClientSpawnShellCasing(self, loc, false, rot);
	}
}

function SpawnSpark(Vector loc, Vector norm, Actor hit)
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer.LineOfSightTo(self, true) || 
			(Pawn(curplayer.ViewTarget) != none && Pawn(curplayer.ViewTarget).LineOfSightTo(self, true))) 
			curplayer.ClientSpawnSpark(self, loc, norm, hit);
	}
}

simulated function SpawnEffects(Vector HitLocation, Vector HitNormal, Actor Other)
{
	local miniMTLPlayer curplayer;

    if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      return;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer.LineOfSightTo(self, true) || 
			(Pawn(curplayer.ViewTarget) != none && Pawn(curplayer.ViewTarget).LineOfSightTo(self, true))) 
			curplayer.ClientSpawnTurretEffects(self, HitLocation, HitNormal, Other);
	}
}

function Fire()
{
	local Vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local Rotator rot;
	local Actor hit;
	//local ShellCasing shell;
	//local Spark spark;
	local Pawn attacker;

	if (!gun.IsAnimating())
		gun.LoopAnim('Fire');

	// CNN - give turrets infinite ammo
//	if (ammoAmount > 0)
//	{
//		ammoAmount--;
		GetAxes(gun.Rotation, X, Y, Z);
		StartTrace = gun.Location;
		EndTrace = StartTrace + gunAccuracy * (FRand()-0.5)*Y*1000 + gunAccuracy * (FRand()-0.5)*Z*1000 ;
		EndTrace += 10000 * X;
		hit = Trace(HitLocation, HitNormal, EndTrace, StartTrace, True);

		// spawn some effects
      if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      {
         //shell = None;
      }
      else
      {
         //shell = Spawn(class'ShellCasing',,, gun.Location);
		SpawnShellCasing(gun.Location, gun.Rotation - rot(0,16384,0));
      }
		//if (shell != None)
		//	shell.Velocity = Vector(gun.Rotation - rot(0,16384,0)) * 100 + VRand() * 30;

		MakeNoise(1.0);
		PlaySound(sound'PistolFire', SLOT_None);
		AISendEvent('LoudNoise', EAITYPE_Audio);

		// muzzle flash
		gun.LightType = LT_Steady;
		gun.MultiSkins[2] = Texture'FlatFXTex34';
		SetTimer(0.1, False);

		// randomly draw a tracer
		if (FRand() < 0.5)
		{
			if (VSize(HitLocation - StartTrace) > 250)
			{
				rot = Rotator(EndTrace - StartTrace);
				//Spawn(class'Tracer',,, StartTrace + 96 * Vector(rot), rot);
				SpawnTracerFromWeapon(StartTrace + 96 * Vector(rot), rot);
			}
		}

		if (hit != None)
		{
         if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
         {
            //spark = None;
         }
         else
         {
			// spawn a little spark and make a ricochet sound if we hit something
			SpawnSpark(HitLocation, HitNormal, hit);
         }

			attacker = None;
			if ((curTarget == hit) && !curTarget.IsA('PlayerPawn'))
				attacker = GetPlayerPawn();
         if (Level.NetMode != NM_Standalone)
            attacker = safetarget;
			if ( hit.IsA('DeusExPlayer') && ( Level.NetMode != NM_Standalone ))
				DeusExPlayer(hit).myTurretKiller = Self;
			hit.TakeDamage(gunDamage, attacker, HitLocation, 1000.0*X, 'AutoShot');

			if (hit.IsA('Pawn') && !hit.IsA('Robot'))
				SpawnBlood2(HitLocation, HitNormal, hit);
			else if ((hit == Level) || hit.IsA('Mover'))
				SpawnEffects(HitLocation, HitNormal, hit);
		}
//	}
//	else
//	{
//		PlaySound(sound'DryFire', SLOT_None);
//	}
}

function PreBeginPlay()
{
	local Vector v1, v2;
	local class<AutoTurretGun> gunClass;
	local Rotator rot;

	Super(DeusExDecoration).PreBeginPlay();

	if (gun == none)
	{
		if (IsA('AutoTurretSmall'))
			gunClass = class'AutoTurretGunSmall';
		else
			gunClass = class'AutoTurretGun';

		rot = Rotation;
		rot.Pitch = 0;
		rot.Roll = 0;
		origRot = rot;
		gun = Spawn(gunClass, Self,, Location, rot);
		if (gun != None)
		{
			v1.X = 0;
			v1.Y = 0;
			v1.Z = CollisionHeight + gun.Default.CollisionHeight;
			v2 = v1 >> Rotation;
			v2 += Location;
			gun.SetLocation(v2);
			gun.SetBase(Self);
		}
	}

	// set up the alarm listeners
	AISetEventCallback('Alarm', 'AlarmHeard');

	if ( Level.NetMode != NM_Standalone )
	{
		maxRange = mpTurretRange;
		gunDamage = mpTurretDamage;
		bInvincible = True;
      bDisabled = !bActive;
	}
}

defaultproperties
{
}
