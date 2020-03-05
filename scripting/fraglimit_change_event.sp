#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR     "Arkarr And Cloman"
#define PLUGIN_VERSION     "2.5.0"
#define TF_TEAM_RED     2
#define TF_TEAM_BLU     3

new Handle:CVAR_KillLimit = INVALID_HANDLE;
new Handle:CVAR_KillLimitIgnore = INVALID_HANDLE;
//new Handle:CVAR_ToggleAfterChat = INVALID_HANDLE;
new Handle:CV_chattag = INVALID_HANDLE;

new bool:enablePlugin = false;
new String:mapName[60];
new String:CHATTAG[60];

new killsR = 0;
new killsB = 0;
new roundWon = 0;
new iWinningTeam = -1;

new Handle:HUD;

public Plugin myinfo = 
{
    name = "[FragLimit] Round Frag Limiter",
    author = PLUGIN_AUTHOR,
    description = "End the round until a certain ammount of kills is reached.",
    version = PLUGIN_VERSION,
    url = "http://www.google.com"
};

public OnConfigsExecuted()
{
	TagsCheck("FragLimit");
}

public void OnPluginStart()
{
    CVAR_KillLimit = CreateConVar("dm_fraglimit", "30", "Set after how much kill the round end.", _, true, 1.0, false, _);
    CVAR_KillLimitIgnore = CreateConVar("dm_fraglimit_Ignore", "0", "Ignore map prefix filter to enable fraglimiter.");
    //CVAR_ToggleAfterChat = CreateConVar("dm_toggle", "1", "Toggle After Death on chat");
    CV_chattag = CreateConVar("dm_fraglimit_chattag","FragLimit","Set the Chattag");
    GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG));
    
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_round_win", Event_RoundEnd);
    HookEvent("teamplay_round_stalemate", Event_RoundEnd);
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);

    CreateTimer(1.0, ClockTimer);
    HUD = CreateHudSynchronizer();

}

public Action:ClockTimer(Handle:timer)
{
    CreateTimer(1.0, ClockTimer);

    
    //decl String:time[30];
    //FormatTime(time, sizeof(time), "%I:%M:%S %p");
    for (new z = 1; z <= MaxClients; z++)
    {
        if (!IsClientInGame(z)) continue;
        if (IsFakeClient(z)) continue;

        if(GetConVarInt(CVAR_KillLimit) - killsB > 0 && GetConVarInt(CVAR_KillLimit) - killsB > 0){
            SetHudTextParams(-1.0, 0.05, 5.0, 255, 255, 255, 255);
            ShowSyncHudText(z, HUD, "%i : %i",GetConVarInt(CVAR_KillLimit) - killsB, GetConVarInt(CVAR_KillLimit) - killsR);

        }
        
        if(killsR >= GetConVarInt(CVAR_KillLimit)){

            SetHudTextParams(-1.0, 0.05, 5.0, 255, 0, 0, 255);
            ShowSyncHudText(z, HUD, "RED WIN");

        }else if(killsB >= GetConVarInt(CVAR_KillLimit)){
            
            SetHudTextParams(-1.0, 0.05, 5.0, 0, 0, 255, 255);
            ShowSyncHudText(z, HUD, "BLU WIN");
            
        }
    }
} 

public OnPluginEnd()
{
    //dont need to do anything but is needed for onpluginstart().
}

public void OnMapStart()
{
    roundWon = 0;
    enablePlugin = false;
    GetCurrentMap(mapName, 60);
}

public void OnMapEnd()
{
    //reset all counters as round is over and to be able to call OnMapStart() again
    roundWon = 0;
    killsR = 0;
    killsB = 0;
    iWinningTeam = -1;
    enablePlugin = false;
}
 
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!enablePlugin){
        return Plugin_Handled;
    }
        
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new deathflags = GetEventInt(event, "death_flags");
    new bool:nofakekill = true;
    
    if (deathflags & 32)
    {
        nofakekill = false;
    }
    
    if (nofakekill == false)
    {
        return Plugin_Handled;
    }
    
    if(attacker != 0 && victim != attacker)
    {
        if(GetClientTeam(attacker) == TF_TEAM_RED){
            killsR++;
        }
        else if(GetClientTeam(attacker) == TF_TEAM_BLU){
            killsB++;
        }
    }
    else{
        return Plugin_Handled;
    }

    for (new z = 1; z <= MaxClients; z++)
    {
        if (!IsClientInGame(z)) continue;
        if (IsFakeClient(z)) continue;

        if(GetConVarInt(CVAR_KillLimit) - killsB > 0 && GetConVarInt(CVAR_KillLimit) - killsB > 0){
            SetHudTextParams(-1.0, 0.05, 5.0, 255, 255, 255, 255);
            ShowSyncHudText(z, HUD, "%i : %i",GetConVarInt(CVAR_KillLimit) - killsB, GetConVarInt(CVAR_KillLimit) - killsR);

        }
        
        if(killsR >= GetConVarInt(CVAR_KillLimit)){

            iWinningTeam = TF_TEAM_RED;
            SetHudTextParams(-1.0, 0.05, 5.0, 255, 0, 0, 255);
            ShowSyncHudText(z, HUD, "RED WIN");

        }else if(killsB >= GetConVarInt(CVAR_KillLimit)){

            iWinningTeam = TF_TEAM_BLU;
            SetHudTextParams(-1.0, 0.05, 5.0, 0, 0, 255, 255);
            ShowSyncHudText(z, HUD, "BLU WIN");
            
        }
    }
        
    if(iWinningTeam == -1){
        return Plugin_Handled;
    }

    new iFlags = GetCommandFlags("mp_forcewin");
    SetCommandFlags( "mp_forcewin", iFlags & ~FCVAR_CHEAT );
    ServerCommand( "mp_forcewin %i", iWinningTeam ); 

    return Plugin_Handled;
}


public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
    if(enablePlugin){
        enablePlugin = false;
    }
    
    if(iWinningTeam > 0){
        roundWon = GetTeamScore(iWinningTeam) + 1;
        SetTeamScore(iWinningTeam, roundWon);
    }
}
    
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(StrContains(mapName, "dm_", false) == 0){
        enablePlugin = true;
    }
    else if(StrContains(mapName, "trade_", false) == 0){
        enablePlugin = true;
    }
    else if(StrContains(mapName, "duel_", false) == 0){
        enablePlugin = true;
    }
    
    if(GetConVarInt(CVAR_KillLimitIgnore) == 1){
        enablePlugin = true;
    }
    
    if(enablePlugin){
        killsR = 0;
        killsB = 0;
        iWinningTeam = -1;
    }

    return Plugin_Handled;
}

public Action:Command_Say(client, args)
{

    if (client == 0){
        return Plugin_Continue;
    }

    if (!IsClientInGame(client)){
        return Plugin_Continue;
    }

    new String:text[512];

    GetCmdArg(1, text, sizeof(text));

    if (StrEqual(text, "!frags", false) || StrEqual(text, "frags", false))
    {
        PrintToChat(client, "\x04[\x03%s\x04]\x01 레드팀의 승리까지 \x05%i\x01 처치 남았습니다.", CHATTAG, GetConVarInt(CVAR_KillLimit) - killsR);
        PrintToChat(client, "\x04[\x03%s\x04]\x01 블루팀의 승리까지 \x05%i\x01 처치 남았습니다.", CHATTAG, GetConVarInt(CVAR_KillLimit) - killsB);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

TagsCheck(const String:tag[])
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	CloseHandle(hTags);
}