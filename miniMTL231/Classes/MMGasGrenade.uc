class MMGasGrenade extends GasGrenade;


simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector HitLocation, Vector Momentum, name damageType)
{
	local ParticleGenerator gen;

	if ((DamageType == 'TearGas') || (DamageType == 'PoisonGas') || (DamageType == 'Radiation'))
		return;

	if (DamageType == 'NanoVirus')
		return;

	if ( Role == ROLE_Authority )
	{
		// EMP damage disables explosives
		if (DamageType == 'EMP')
		{
			if (!bDisabled)
			{
				PlaySound(sound'EMPZap', SLOT_None,,, 1280);
				bDisabled = True;
				gen = Spawn(class'ParticleGenerator', Self,, Location, rot(16384,0,0));
				if (gen != None)
				{
					gen.checkTime = 0.25;
					gen.LifeSpan = 2;
					gen.particleDrawScale = 0.3;
					gen.bRandomEject = True;
					gen.ejectSpeed = 10.0;
					gen.bGravity = False;
					gen.bParticlesUnlit = True;
					gen.frequency = 0.5;
					gen.riseRate = 10.0;
					gen.spawnSound = Sound'Spark2';
					gen.particleTexture = Texture'Effects.Smoke.SmokePuff1';
					gen.SetBase(Self);
				}
			}
			return;
		}
		bDamaged = True;
	}
	if (instigatedBy != none)
	{
		SetOwner(instigatedBy);
		Instigator = instigatedBy;
	}
	Explode(Location, Vector(Rotation));
}


simulated function Tick(float deltaTime)
{
	local ScriptedPawn P;
	local DeusExPlayer Player;
	local Vector dist, HitLocation, HitNormal;
	local float blinkRate, mult, skillDiff;
	local float proxRelevance;
	local Pawn curPawn;
	local bool pass;
	local Actor HitActor;

	time += deltaTime;

	if ( Role == ROLE_Authority )
	{
		super(DeusExProjectile).Tick(deltaTime);

		if (bDisabled)
			return;

		if ( (Owner == None) && ((Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer)) )
		{
			// Owner has logged out
			bDisabled = True;
			team = -1;
		}

		if (( Owner != None ) && (DeusExPlayer(Owner) != None ))
		{
			if ( TeamDMGame(DeusExPlayer(Owner).DXGame) != None )
			{
				// If they switched sides disable the grenade
				if ( DeusExPlayer(Owner).PlayerReplicationInfo.team != team )
				{
					bDisabled = True;
					team = -1;
				}

				//
				// MINIMTL ADDED - planted granades ignore spectators!
				//
				else if (DeusExPlayer(Owner).PlayerReplicationInfo.bIsSpectator)
				{
				    bDisabled = true;
				    team = -1;
				}
				//
				//
				//
			}
		}

		// check for proximity
		if (bProximityTriggered)
		{
			if (bArmed)
			{
				proxCheckTime += deltaTime;

				// beep based on skill
				if (skillTime != 0)
				{
					if (time > fuseLength)
					{
						if (skillTime % 0.3 > 0.25)
							PlayBeepSound( 1280, 2.0, 3.0 );
					}
				}

				// if we have been triggered, count down based on skill
				if (skillTime > 0)
					skillTime -= deltaTime;

				// explode if time < 0
				if (skillTime < 0)
				{
					bDoExplode = True;
					bArmed = False;
				}
				// DC - new ugly way of doing it - old way was "if (proxCheckTime > 0.25)"
				// new way: weight the check frequency based on distance from player
				proxRelevance=DistanceFromPlayer/2000.0;  // at 500 units it behaves as it did before
				if (proxRelevance<0.25)
					proxRelevance=0.25;               // low bound 1/4
				else if (proxRelevance>10.0)
					proxRelevance=20.0;               // high bound 30
				else
					proxRelevance=proxRelevance*2;    // out past 1.0s, double the timing
				if (proxCheckTime>proxRelevance)
				{
					proxCheckTime = 0;

					// pre-placed explosives are only prox triggered by the player
					if (Owner == None)
					{
						foreach RadiusActors(class'DeusExPlayer', Player, proxRadius*4)
						{
							// the owner won't set it off, either
							if (Player != Owner)
							{
								dist = Player.Location - Location;
								if (VSize(dist) < proxRadius)
									if (skillTime == 0)
										skillTime = FClamp(-20.0 * Player.SkillSystem.GetSkillLevelValue(class'SkillDemolition'), 1.0, 10.0);
							}
						}
					}
					else
					{
						// If in multiplayer, check other players
						if (( Level.NetMode == NM_DedicatedServer) || ( Level.NetMode == NM_ListenServer))
						{
							curPawn = Level.PawnList;

							while ( curPawn != None )
							{
								pass = False;

								if ( curPawn.IsA('DeusExPlayer') )
								{
									Player = DeusExPlayer( curPawn );

									// Pass on owner
									if ( Player == Owner )
										pass = True;

									//
									// MINIMTL ADDED - planted granades ignore spectators!
									//
									else if (Player.PlayerReplicationInfo.bIsSpectator)
									{
									    //log("spectator proximity:"$Player.PlayerReplicationInfo.PlayerName, 'MMLAM');
									    pass = True;
					                }
					                //
					                //
					                //

									// Pass on team member
									else if ( (TeamDMGame(Player.DXGame) != None) && (team == player.PlayerReplicationInfo.team) )
										pass = True;
									// Pass if radar transparency on
									else if ( Player.AugmentationSystem.GetClassLevel( class'AugRadarTrans' ) == 3 )
										pass = True;

									// Finally, make sure we can see them (no exploding through thin walls)
									if ( !pass )
									{
										// Only players we can see : changed this to Trace from FastTrace so doors are included
										HitActor = Trace( HitLocation, HitNormal, Player.Location, Location, True );
										if (( HitActor == None ) || (DeusExPlayer(HitActor) == Player))
										{
										}
										else
											pass = True;
									}

									if ( !pass )
									{
										dist = Player.Location - Location;
										if ( VSize(dist) < proxRadius )
										{
											if (skillTime == 0)
											{
												skillDiff = -skillAtSet + Player.SkillSystem.GetSkillLevelValue(class'SkillDemolition');
												if ( skillDiff >= 0.0 ) // Scale goes 1.0, 1.6, 2.8, 4.0
													skillTime = FClamp( 1.0 + skillDiff * 6.0, 1.0, 2.5 );
												else	// Scale goes 1.0, 1.4, 2.2, 3.0
													skillTime = FClamp( 1.0	+ (-Player.SkillSystem.GetSkillLevelValue(class'SkillDemolition') * 4.0), 1.0, 3.0 );
											}
										}
									}
								}
								curPawn = curPawn.nextPawn;
							}
						}
						else	// Only have scripted pawns set off promixity grenades in single player
						{
							foreach RadiusActors(class'ScriptedPawn', P, proxRadius*4)
							{
								// only "heavy" pawns will set this off
								if ((P != None) && (P.Mass >= 40))
								{
									// the owner won't set it off, either
									if (P != Owner)
									{
										dist = P.Location - Location;
										if (VSize(dist) < proxRadius)
											if (skillTime == 0)
												skillTime = 1.0;
									}
								}
							}
						}
					}
				}
			}
		}

		// beep faster as the time expires
		beepTime += deltaTime;

		if (fuseLength - time <= 0.75)
			blinkRate = 0.1;
		else if (fuseLength - time <= fuseLength * 0.5)
			blinkRate = 0.3;
		else
			blinkRate = 0.5;

		if (time < fuseLength)
		{
			if (beepTime > blinkRate)
			{
				beepTime = 0;
				PlayBeepSound( 1280, 1.0, 0.5 );
			}
		}
	}
	if ( bDoExplode )	// Keep the simulated chain going
		Explode(Location, Vector(Rotation));
}

defaultproperties
{
     spawnWeaponClass=Class'MMWeaponGasGrenade'
}
