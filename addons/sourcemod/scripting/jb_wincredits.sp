#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_jb>
#include <cstrike>

new Handle: gc_iMaxCredits		= INVALID_HANDLE;

public OnPluginStart()
{
	gc_iMaxCredits = CreateConVar("sm_jailbreak_max_credits", "1000", "Max amount of credits a player can earn", FCVAR_DONTRECORD, true, 0.0);

	HookEvent("player_death", EventPlayerDeath);
	
	HookEvent("round_end", FinRonda);
	
	CreateTimer(60.0, ResetAmmo2, _, TIMER_REPEAT);
}

public Action:FinRonda(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clients = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			clients++;
		}
	}
	
	if(clients < 3) return;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) <= 1 || !IsPlayerAlive(client))
			continue;

		AddCredits(client, 4);
	}
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!attacker) return;
	if (attacker == client || GetClientTeam(attacker) == CS_TEAM_CT) return;
	
	AddCredits(attacker, 2);
}

public Action:ResetAmmo2(Handle:timer)
{
	new clients = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			clients++;
		}
	}
	
	if(clients < 3) return;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
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