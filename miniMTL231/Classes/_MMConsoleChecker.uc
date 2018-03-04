//=============================================================================
//
//=============================================================================
class _MMConsoleChecker extends Actor;

replication
{
    reliable if(ROLE == ROLE_Authority)
       _clientGiveConsoleInfo;

    reliable if(ROLE < ROLE_Authority)
       _serverValidateConsole;
}

var private string _checkUID;
var private string _foundConsole;

/** @ignore */
var private bool _bCheckPassed;
var private bool _bInitalized;


simulated function PostBeginPlay()
{
    if(level.NetMode != NM_StandAlone && ROLE == ROLE_Authority)
    {
        SetTimer(10,false);
    }
}

final simulated function _Initalize()
{
    if(level.NetMode != NM_StandAlone && ROLE == ROLE_Authority)
    {
        if(DeusExPlayer(Owner) != none)
        {
            _checkUID=_generateUID();
            _clientGiveConsoleInfo(_checkUID);
            _bInitalized=true;
            SetTimer(10,false);
        }
    }
}

final simulated function _clientGiveConsoleInfo(string checkID)
{
    _serverValidateConsole(string(DeusExPlayer(Owner).Player.Console.class)$"|"$string(DeusExPlayer(Owner).RootWindow),checkID);
}

final function _serverValidateConsole(string in, string checkID)
{
    local string conStr,rootStr;

    if(checkID == _checkUID)
    {
        conStr=left(in,instr(in,"|"));
        _foundConsole=conStr;
        //rootStr=right(in,len(in)-len(conStr)-1); //nah.. i'll think about checking this too
        if(conStr ~= "Engine.Console")
          _bCheckPassed=true;

        //if(rootStr ~= "DeusEx.DeusExRootWindow")
        //  bCheckPassed=true;

    }
    else
    {
        log("ConsoleChecker -- Received invalid client answer from"@PlayerPawn(Owner).PlayerReplicationInfo.PlayerName);
    }
}

simulated function Timer()
{
    if(_bInitalized)
    {
        if(!_bCheckPassed)
        {
            Log("Possible cheat detected:", 'MiniMTL');
            Log("Player Caught:   " $ DeusExPlayer(Owner).PlayerReplicationInfo.PlayerName $ ".", 'MiniMTL');
            Log("Player Address:  " $ DeusExPlayer(Owner).GetPlayerNetworkAddress() $ ".", 'MiniMTL');
            Log("Cheat Found: Invalid Console class Detected. ("$_foundConsole$")", 'MiniMTL');
            DeusExPlayer(Owner).ForceDisconnect("Invalid console class, disconnecting; try again");
        }
        Destroy();
    }
    else
    {
        _Initalize();
    }
}

static function string _generateUID()
{
    local int i;
    local string UID;

    for(i=0;i<16;i++)
    {
        if(FRand() < 0.5)
        {
            UID=UID$string(Rand(9));
        }
        else
        {
            UID=UID$Chr(65+Rand(5));
        }
    }
    return UID;

}

defaultproperties
{
     bHidden=True
}
