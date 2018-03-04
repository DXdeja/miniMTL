class MMAugmentation extends Augmentation
	abstract;

var class<Augmentation> OldAugClass;
var int ManagerIndex;

static function float NewGetEnergyRate()
{
	return default.EnergyRate;
}

static function MMAugmentationManager GetManager(DeusExPlayer dxp)
{
	return MMAugmentationManager(dxp.AugmentationSystem);
}

static function bool IsAugActive(DeusExPlayer dxp)
{
	local MMAugmentationManager manager;

	if (dxp == none) return false;

	manager = MMAugmentationManager(dxp.AugmentationSystem);
	if (manager == none) return false;
	if (manager.mpStatus[default.ManagerIndex] == 2) return true;
	else return false;
}

static function ToggleStatus(DeusExPlayer dxp)
{
	local MMAugmentationManager manager;

	manager = MMAugmentationManager(dxp.AugmentationSystem);
	if (manager.mpStatus[default.ManagerIndex] == 1) manager.mpStatus[default.ManagerIndex] = 2;
	else if (manager.mpStatus[default.ManagerIndex] == 2) manager.mpStatus[default.ManagerIndex] = 1;
}

static function bool AugToggle(DeusExPlayer dxp)
{
	local bool bActive;
	
	bActive = IsAugActive(dxp);
	if (bActive) 
	{
		AugDeactivate(dxp);
	}
	else 
	{
		AugActivate(dxp);
	}

	return !bActive;
}

static function AugActivate(DeusExPlayer dxp)
{
	if (IsAugActive(dxp)) return; // already activated

	dxp.PlaySound(default.ActivateSound, SLOT_None);
	if (dxp.AugmentationSystem.NumAugsActive() == 0)
		dxp.AmbientSound = default.LoopSound;

	if (miniMTLPlayer(dxp).bDisplayAugMessages)
		dxp.ClientMessage(dxp.Sprintf(default.OldAugClass.default.AugActivated, default.OldAugClass.default.AugmentationName)); // localized

	ToggleStatus(dxp);

	ActivateAction(dxp);
}

static function AugDeactivate(DeusExPlayer dxp)
{
	if (!IsAugActive(dxp)) return; // already deactivated

	ToggleStatus(dxp);

	DeactivateAction(dxp);

	if (miniMTLPlayer(dxp).bDisplayAugMessages)
		dxp.ClientMessage(dxp.Sprintf(default.OldAugClass.default.AugDeactivated, default.OldAugClass.default.AugmentationName)); // localized

	if (dxp.AugmentationSystem.NumAugsActive() == 0)
		dxp.AmbientSound = None;
	dxp.PlaySound(default.DeactivateSound, SLOT_None);
}

static function StaticTick(DeusExPlayer dxp, float deltaTime)
{
	if (IsAugActive(dxp))
	{
		TickAction(dxp, deltaTime);
	}
}

// specific functions
static function ActivateAction(DeusExPlayer dxp)
{
}

static function DeactivateAction(DeusExPlayer dxp)
{
}

static function TickAction(DeusExPlayer dxp, float deltaTime)
{
}

defaultproperties
{
}
