class MMSkillManager extends SkillManager;

var byte SkillLevels[11];

var const float SkillWeaponValues[4];
var const float SkillDemolitionValues[4];
var const float SkillEnviroValues[4];
var const float SkillTechValues[4];
var const float SkillMedValues[4];
var const float SkillCompValues[4];
var const float SkillSwimValues[4];

var const int SkillCosts[11];

replication
{
    //variables server to client
	reliable if ((Role == ROLE_Authority) && (bNetOwner))
	    SkillLevels;

	reliable if (Role < ROLE_Authority)
		IncLevel;
}

static function int GetSkillGroupByClass(class<Skill> sclass)
{
	local int i;

	for (i = 0; i < 10; i++)
		if (default.skillClasses[i] == sclass) return ((i + 1) % 10);

	return -1;
}

simulated function bool IsPurchasePossible()
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels) - 1; skillIndex++)
	{
		if (SkillLevels[skillIndex] < 3 && Player.SkillPointsAvail >= SkillCosts[skillIndex])
			return true;
	}

	return false;
}



simulated function string GetSkillClassNameByIndex(byte index)
{
	if (index >= ArrayCount(skillClasses)) return "";

	if (index == 7) return class<SkillTech>(skillClasses[index]).default.MultitoolString;
	else return skillClasses[index].default.SkillName;
}

simulated function string GetSkillClassNameByClass(class<Skill> cskill)
{
	if (class<SkillTech>(cskill) != none) return class<SkillTech>(cskill).default.MultitoolString;
	else return cskill.default.SkillName;
}

function IncLevel(byte sindex)
{
	if (sindex >= ArrayCount(SkillLevels)) return;

	if (SkillLevels[sindex] < 3)
	{
		if (player.SkillPointsAvail >= SkillCosts[sindex])
		{
			player.SkillPointsAvail -= SkillCosts[sindex];
			SkillLevels[sindex]++;
			if (sindex == 5) SkillLevels[10]++; // if enviro, upgrade swimming too
		}
	}
}

function CreateSkills(DeusExPlayer newPlayer)
{
	FirstSkill = None;
	player = newPlayer;
	ResetSkills();
}

function bool SkillUse(class<Skill> sclass)
{
	local bool bDoIt;

	bDoIt = True;

	if (sclass.default.itemNeeded != None)
	{
		bDoIt = False;

		if ((Player.inHand != None) && (Player.inHand.Class == sclass.default.itemNeeded))
		{
			SkilledTool(Player.inHand).PlayUseAnim();

			// alert NPCs that I'm messing with stuff
			if (Player.FrobTarget != None)
				if (Player.FrobTarget.bOwned)
					Player.FrobTarget.AISendEvent('MegaFutz', EAITYPE_Visual);

			bDoIt = True;
		}
	}

	return bDoIt;
}

simulated function bool IsSkilled(class SkillClass, int TestLevel)
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels); skillIndex++)
	{
		if (skillClasses[skillIndex] == SkillClass) 
		{
			if (SkillUse(skillClasses[skillIndex]))
			{
				if (SkillLevels[skillIndex] >= TestLevel)
				{
					Player.ClientMessage(SuccessMessage);
					return True;
				}
				else
					Player.ClientMessage(Sprintf(NoSkillMessage, skillClasses[skillIndex].default.SkillName, 
						GetItemName(String(skillClasses[skillIndex].default.itemNeeded))));
			}
			else
				Player.ClientMessage(Sprintf(NoToolMessage, 
					GetItemName(String(skillClasses[skillIndex].default.itemNeeded))));

			break;
		}
	}

	return False;
}

simulated function Skill GetSkillFromClass(class SkillClass)
{
	return none;
}

simulated function float GetSkillLevelValue(class SkillClass)
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels); skillIndex++)
	{
		if (skillClasses[skillIndex] == SkillClass)
		{
			switch (skillIndex)
			{
			case 0:
			case 1:
			case 2:
			case 3:
				return SkillWeaponValues[SkillLevels[skillIndex]];
			case 4:
				return SkillDemolitionValues[SkillLevels[skillIndex]];
			case 5:
				return SkillEnviroValues[SkillLevels[skillIndex]];
			case 6:
			case 7:
				return SkillTechValues[SkillLevels[skillIndex]];
			case 8:
				return SkillMedValues[SkillLevels[skillIndex]];
			case 9:
				return SkillCompValues[SkillLevels[skillIndex]];
			case 10:
				return SkillSwimValues[SkillLevels[skillIndex]];
			}
		}
	}

	return 1.0;
}

simulated function float GetSkillLevel(class SkillClass)
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels); skillIndex++)
	{
		if (skillClasses[skillIndex] == SkillClass) return float(SkillLevels[skillIndex]);
	}

	return 0;
}

function AddSkill(Skill aNewSkill)
{
}

function SetPlayer(DeusExPlayer newPlayer)
{
	Player = newPlayer;
}

function AddAllSkills()
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels); skillIndex++)
	{
		SkillLevels[skillIndex] = 3;
	}
}

function ResetSkills()
{
	local int skillIndex;

	for(skillIndex=0; skillIndex<arrayCount(SkillLevels); skillIndex++)
	{
		SkillLevels[skillIndex] = Min(byte(DeusExMPGame(Level.Game).MPSkillStartLevel), 3);
	}
}

defaultproperties
{
     SkillWeaponValues(0)=-0.100000
     SkillWeaponValues(1)=-0.250000
     SkillWeaponValues(2)=-0.370000
     SkillWeaponValues(3)=-0.500000
     SkillDemolitionValues(1)=-0.100000
     SkillDemolitionValues(2)=-0.300000
     SkillDemolitionValues(3)=-0.500000
     SkillEnviroValues(0)=1.000000
     SkillEnviroValues(1)=0.750000
     SkillEnviroValues(2)=0.500000
     SkillEnviroValues(3)=0.250000
     SkillTechValues(0)=0.100000
     SkillTechValues(1)=0.400000
     SkillTechValues(2)=0.550000
     SkillTechValues(3)=0.950000
     SkillMedValues(0)=1.000000
     SkillMedValues(1)=1.000000
     SkillMedValues(2)=2.000000
     SkillMedValues(3)=3.000000
     SkillCompValues(0)=0.400000
     SkillCompValues(1)=0.400000
     SkillCompValues(2)=1.000000
     SkillCompValues(3)=5.000000
     SkillSwimValues(0)=1.000000
     SkillSwimValues(1)=1.250000
     SkillSwimValues(2)=1.500000
     SkillSwimValues(3)=2.250000
     SkillCosts(0)=2000
     SkillCosts(1)=2000
     SkillCosts(2)=2000
     SkillCosts(3)=2000
     SkillCosts(4)=1000
     SkillCosts(5)=1000
     SkillCosts(6)=1000
     SkillCosts(7)=1000
     SkillCosts(8)=1000
     SkillCosts(9)=1000
     NetPriority=1.400000
}
