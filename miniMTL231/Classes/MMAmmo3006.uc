class MMAmmo3006 extends Ammo3006;

function bool UseAmmo(int AmountNeeded)
{
	local vector offset, tempvec, X, Y, Z;
	local ShellCasing shell;
	local DeusExWeapon W;

	if (Super(DeusExAmmo).UseAmmo(AmountNeeded))
	{
		GetAxes(Pawn(Owner).ViewRotation, X, Y, Z);
		offset = Owner.CollisionRadius * X + 0.3 * Owner.CollisionRadius * Y;
		tempvec = 0.8 * Owner.CollisionHeight * Z;
		offset.Z += tempvec.Z;

		// use silent shells if the weapon has been silenced
		W = DeusExWeapon(Pawn(Owner).Weapon);
      if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      {
         shell = None;
      }
      else
      {
         if ((W != None) && ((W.NoiseLevel < 0.1) || W.bHasSilencer))
			miniMTLPlayer(Owner).ClientSpawnShellCasing(Owner, Owner.Location + offset, true);
         else
			miniMTLPlayer(Owner).ClientSpawnShellCasing(Owner, Owner.Location + offset, false);
      }

		if (shell != None)
		{
			shell.Velocity = (FRand()*20+90) * Y + (10-FRand()*20) * X;
			shell.Velocity.Z = 0;
		}
		return True;
	}

	return False;
}

defaultproperties
{
}
