//=============================================================================
// Some fixes of the game on client side.
//=============================================================================
class _MMSomeFixes1 extends Actor;

var bool _bFixedLevel;
var float _WeaponShotTimes[10];

simulated function PreBeginPlay()
{
	_WeaponShotTimes[0] = 0.5; // default (class'MMWeaponCombatKnife', class'MMWeaponNanoSword', class'MMWeaponPlasmaRifle')
	_WeaponShotTimes[1] = 0.1; // class'MMWeaponAssaultGun'
	_WeaponShotTimes[2] = 0.7; // class'MMWeaponAssaultShotGun'
	_WeaponShotTimes[3] = 0.8; // class'MMWeaponMiniCrossbow'
	_WeaponShotTimes[4] = 0.6; // class'MMWeaponPistol'
	_WeaponShotTimes[5] = 0.3; // class'MMWeaponSawedOffShotgun'
	_WeaponShotTimes[6] = 0.2; // class'MMWeaponShuriken'
	_WeaponShotTimes[7] = 0.15; // class'MMWeaponStealthPistol'
}

simulated function Tick(float VC5)
{
	local DeusExLevelInfo Z52;

	if (!_bFixedLevel)
	{
		foreach AllActors(Class'DeusExLevelInfo',Z52)
		{
			Z52.missionNumber=7;
			Z52.bMultiPlayerMap=True;
			Z52.ConversationPackage=Class'DeusExLevelInfo'.Default.ConversationPackage;
		}
		_bFixedLevel = true;
	}

	_CheckWeapons();
}

final simulated function _CheckWeapons()
{
	local miniMTLPlayer Player;
	local DeusExWeapon dxw;
	local int index;
	
	Player = miniMTLPlayer(Owner);
	
	if (Player == none) return;
	dxw = DeusExWeapon(Player.Weapon);
	if (dxw == none) return;
	else 
	{
		switch (dxw.Class)
		{
		case class'MMWeaponAssaultGun':
			index = 1;
			break;
		case class'MMWeaponAssaultShotGun':
			index = 2;
			break;
		case class'MMWeaponCombatKnife':
		case class'MMWeaponNanoSword':
		case class'MMWeaponPlasmaRifle':
			index = 0;
			break;
		case class'MMWeaponMiniCrossbow':
			index = 3;
			break;
		case class'MMWeaponPistol':
			index = 4;
			break;
		case class'MMWeaponSawedOffShotgun':
			index = 5;
			break;
		case class'MMWeaponShuriken':
			index = 6;
			break;
		case class'MMWeaponStealthPistol':
			index = 7;
			break;
		default:
			return;
		}

		// kick if shottime is not correct
		if (dxw.ShotTime < _WeaponShotTimes[index]) Player.ConsoleCommand("disconnect");
	}
}

defaultproperties
{
    bHidden=True
    RemoteRole=0
    bAlwaysTick=True
}
