class MMGRI extends MTLGRI;

var int Captures[2];

replication
{
	reliable if (Role == ROLE_Authority)
		Captures;
}

defaultproperties
{
}
