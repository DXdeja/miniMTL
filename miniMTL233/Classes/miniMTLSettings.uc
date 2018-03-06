class miniMTLSettings extends Info config(MiniMTL);

var config bool bSpectateEnemy;
var config bool bDisplaySkillMessageForever;
var config float FastFireRateTolerance;
var config bool bForceNetSpeed;
var config int MinNetSpeed;
var config int MaxNetSpeed;
var config bool bReflectiveDamage;
var config string ModPassword;
var string ModVersion;
var config bool bSpeedFix;
var config bool bAllowBehindView;
var config bool bForceWhiteCrosshair;

defaultproperties
{
    FastFireRateTolerance=0.01
    bForceNetSpeed=True
    MinNetSpeed=10000
    MaxNetSpeed=20000
    ModVersion="233a2"
    bAllowBehindView=True
    RemoteRole=0
}
