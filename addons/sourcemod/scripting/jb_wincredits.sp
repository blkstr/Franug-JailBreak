#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_jb>
#include <cstrike>

new Handle: gc_iMaxCredits		= INVALID_HANDLE;

public Plugin:myinfo =
{
  name        = "[SM Franug JailBreak] Win credits",
  author      = "Franc1sco steam: franug",
  description = "",
  version     = "1.0.0",
  url         = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	gc_iMaxCredits = CreateConVar("sm_jailbreak_max_credits", "1000", "Max amount of credits a player can earn", FCVAR_DONTRECORD, true, 0.0);

	HookEvent("player_death", EventPlayerDeath);
	//HookEvent("round_end", Event_RoundEnd);
	
	CreateTimer(300.0, Timer_GiveCredits, _, TIMER_REPEAT);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clients = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			clients++;
		}
	}
	
	if(clients < 2) 
		return Plugin_Handled;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) <= 1 || !IsPlayerAlive(client))
			continue;

		AddCredits(client, 4);
	}

	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!attacker) 
		return Plugin_Continue;
	
	new attackerTeam = GetClientTeam(attacker);
	new victimTeam = GetClientTeam(victim);
	
	if (attacker == victim || attackerTeam == CS_TEAM_CT || attackerTeam == victimTeam) 
		return Plugin_Continue;
	
	AddCredits(attacker, 1);
	
	return Plugin_Continue;
}

public Action:Timer_GiveCredits(Handle:timer)
{
	new clients = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			clients++;
		}
	}
	
	if(clients < 3) 
		return;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			AddCredits(client, 1);
		}
	}
}

public AddCredits(client, amount)
{
		int maxCredits = GetConVarInt(gc_iMaxCredits);
		int currentCredits = JB_GetCredits(client);
	
		if (currentCredits >= maxCredits)
			return;

		int updatedCredits = currentCredits + amount;
		updatedCredits = updatedCredits >= maxCredits ? maxCredits : updatedCredits;
		
		JB_SetCredits(client, updatedCredits);
}