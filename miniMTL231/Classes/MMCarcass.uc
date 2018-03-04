class MMCarcass extends CBPCarcass;

function SpawnFleshFragments()
{
	local miniMTLPlayer curplayer;

	foreach AllActors(class'miniMTLPlayer', curplayer)
	{
		if (curplayer.LineOfSightTo(self, true) || 
			(Pawn(curplayer.ViewTarget) != none && Pawn(curplayer.ViewTarget).LineOfSightTo(self, true))) 
			curplayer.ClientSpawnFleshFragments(Location);
	}
}

function ChunkUp(int Damage)
{
	SpawnFleshFragments();
	Super(Carcass).ChunkUp(Damage);
}

defaultproperties
{
}
