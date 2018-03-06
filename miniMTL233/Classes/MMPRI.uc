class MMPRI extends MTLPRI;

var int SpectatingPlayerID;
var miniMTLCTFFlag Flag;
var bool bDead;
var bool bModerator;

replication
{
	reliable if (Role == ROLE_Authority)
		SpectatingPlayerID, Flag, bDead, bModerator;
}

defaultproperties
{
    SpectatingPlayerID=-1
}
