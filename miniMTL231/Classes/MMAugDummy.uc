class MMAugDummy extends Augmentation;

var class<MMAugmentation> AugAffected;

function Deactivate()
{
	AugAffected.static.AugDeactivate(MMAugmentationManager(Owner).player);
}

defaultproperties
{
     RemoteRole=ROLE_None
}
