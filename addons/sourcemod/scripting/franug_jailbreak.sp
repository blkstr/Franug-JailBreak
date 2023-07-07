#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <franug_jb>
#include <scp>
#include <clientprefs>

#pragma newdecls required

#define VERSION               "v1.0"
#define AWARD_NAME_MAX_LENGTH 64
#define STRING(% 1)           % 1, sizeof(% 1)

Handle g_ArrayPremios;
Handle EnPremioComprado;

int g_iCreditos[MAXPLAYERS + 1];
bool g_bSpecial[MAXPLAYERS + 1];
bool g_bFD[MAXPLAYERS + 1];

Menu menus[MAXPLAYERS + 1];

char g_sRondaActual[128] = "none";

Handle c_GameCredits = INVALID_HANDLE;

enum struct Premio
{
  char nombre[AWARD_NAME_MAX_LENGTH];
  int precio;
  int team;
}

// new String:g_sFilePath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
  name        = "SM Franug JailBreak",
  author      = "Franc1sco steam: franug",
  description = "",
  version     = VERSION,
  url         = "http://steamcommunity.com/id/franug"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
  CreateNative("JB_AddAward", Native_AgregarPremio);
  CreateNative("JB_RemoveAward", Native_BorrarPremio);
  CreateNative("JB_ChooseRound", Native_ElegirRonda);
  CreateNative("JB_GetRound", Native_ObtenerRonda);
  CreateNative("JB_SetSpecial", Native_FijarEspecial);
  CreateNative("JB_GiveFD", Native_DarFD);
  CreateNative("JB_GetSpecial", Native_ObtenerEspecial);
  CreateNative("JB_GetFD", Native_ObtenerFD);
  CreateNative("JB_SetCredits", Native_FijarCreditos);
  CreateNative("JB_GetCredits", Native_ObtenerCreditos);
  CreateNative("JB_LoadTranslations", Native_Lengua);
  EnPremioComprado = CreateGlobalForward("JB_OnAwardBought", ET_Ignore, Param_Cell, Param_String);

  return APLRes_Success;
}

public void OnPluginStart()
{
  // BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "logs/prueba.log");

  c_GameCredits = RegClientCookie("FranugCredits", "FranugCredits", CookieAccess_Private);

  LoadTranslations("franug_jailbreak.phrases");
  g_ArrayPremios = CreateArray(sizeof(Premio));

  RegConsoleCmd("sm_awards", DOMenu);
  RegConsoleCmd("sm_tienda", DOMenu);
  RegConsoleCmd("sm_premios", DOMenu);
  // RegConsoleCmd("buyammo2", DOMenu);

  HookEvent("round_end", FinRonda);
  HookEvent("round_start", InicioRonda);
  HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

  RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_ROOT);

  CreateConVar("sm_FranugJailBreak", VERSION, "plugin info", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

  for (int client = 1; client <= MaxClients; client++)
  {
    if (IsClientInGame(client))
    {
      if (AreClientCookiesCached(client))
      {
        OnClientCookiesCached(client);
      }
    }
  }
}

public void OnClientCookiesCached(int client)
{
  char CreditsString[12];
  GetClientCookie(client, c_GameCredits, CreditsString, sizeof(CreditsString));
  g_iCreditos[client] = StringToInt(CreditsString);
}

public Action InicioRonda(Handle event, const char[] name, bool dontBroadcast)
{
  PrintToChatAll(" \x04[Franug-JailBreak] \x03%t", "Escribe !premios para gastar tus creditos en premios");
  return Plugin_Continue;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
  if (event == INVALID_HANDLE)
    return Plugin_Continue;

  int userId  = GetEventInt(event, "userid", -1);
  int oldTeam = GetEventInt(event, "oldteam", -1);
  int newTeam = GetEventInt(event, "team", -1);
  int client;

  if ((userId < 0) || (oldTeam == newTeam))
    return Plugin_Continue;

  client = GetClientOfUserId(userId);

  if (!IsValidClient(client))
    return Plugin_Continue;

  RenewClientMenu(client);

  return Plugin_Continue;
}

public void OnPluginEnd()
{
  CloseHandle(g_ArrayPremios);

  for (int client = 1; client <= MaxClients; client++)
  {
    if (IsClientInGame(client))
    {
      OnClientDisconnect(client);
    }
  }
}

void RenewMenus()
{
  for (int i = 1; i < MaxClients; i++)
  {
    if (IsClientInGame(i))
      RenewClientMenu(i);
  }
}

void RenewClientMenu(int client)
{
  if (menus[client] != INVALID_HANDLE)
    CloseHandle(menus[client]);

  menus[client] = INVALID_HANDLE;
  CreateMenuClient(client);
}

public void OnClientDisconnect(int client)
{
  if (menus[client] != INVALID_HANDLE) CloseHandle(menus[client]);

  menus[client] = INVALID_HANDLE;

  if (AreClientCookiesCached(client))
  {
    char CreditsString[12];
    Format(CreditsString, sizeof(CreditsString), "%i", g_iCreditos[client]);
    SetClientCookie(client, c_GameCredits, CreditsString);
  }
}

public Action DOMenu2(int client, int args)
{
  PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "Tus creditos", g_iCreditos[client]);
  return Plugin_Handled;
}

public Action DOMenu(int client, int args)
{
  if (menus[client] == INVALID_HANDLE)
    return Plugin_Handled;

  CreateMenuClient(client);
  DisplayMenu(menus[client], client, MENU_TIME_FOREVER);
  PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "Tus creditos", g_iCreditos[client]);

  return Plugin_Handled;
}

void CreateMenuClient(int clientId)
{
  menus[clientId] = CreateMenu(DIDMenuHandler);
  SetMenuTitle(menus[clientId], "JailBreak by Franug");
  char menuItem[128];
  char awardNamePhrase[64];
  char creditsPhrase[32];
  Premio premio;

  for (int i = 0; i < GetArraySize(g_ArrayPremios); i++)
  {
    GetArrayArray(g_ArrayPremios, i, premio);

    Format(awardNamePhrase, sizeof(awardNamePhrase),"%T", premio.nombre, clientId);
    Format(creditsPhrase, sizeof(creditsPhrase), "%T", "Creditos", clientId);
    Format(menuItem, sizeof(menuItem), "%s - %d %s", awardNamePhrase, premio.precio, creditsPhrase);

    if ((premio.team == JB_GUARDS) && (GetClientTeam(clientId) != CS_TEAM_CT))
      continue;
    if ((premio.team == JB_PRISIONERS) && (GetClientTeam(clientId) != CS_TEAM_T))
      continue;

    AddMenuItem(menus[clientId], premio.nombre, menuItem);
  }

  SetMenuExitButton(menus[clientId], true);
}

public int DIDMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
  if (action == MenuAction_Select)
  {
    char info[AWARD_NAME_MAX_LENGTH];
    Premio premio;

    GetMenuItem(menu, itemNum, info, sizeof(info));

    for (int i = 0; i < GetArraySize(g_ArrayPremios); i++)
    {
      GetArrayArray(g_ArrayPremios, i, premio);
      if (StrEqual(premio.nombre, info))
        break;
    }

    if (g_iCreditos[client] < premio.precio)
    {
      PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "Necesitas creditos", g_iCreditos[client], premio.precio);
      return 1;
    }

    if (!IsPlayerAlive(client))
    {
      PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "Tienes que estar vivo para poder comprar premios");
      return 1;
    }

    if (
      (GetClientTeam(client) == CS_TEAM_T) && (premio.team != JB_PRISIONERS)
      || (GetClientTeam(client) == CS_TEAM_CT) && (premio.team != JB_GUARDS))
    {
      PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "Este premio no esta disponible para tu equipo");
    }

    if (g_bSpecial[client])
    {
      PrintToChat(client, " \x04[Franug-JailBreak] \x05%t", "No puedes comprar cosas siendo un ser especial");
      return 1;
    }

    g_iCreditos[client] -= premio.precio;

    Call_StartForward(EnPremioComprado);
    Call_PushCell(client);
    Call_PushString(info);
    Call_Finish();

    DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
  }

  return 0;
}

public void OnClientPostAdminCheck(int client)
{
  // g_iCreditos[client] = 0;
  g_bSpecial[client] = false;
  g_bFD[client]      = false;
}

public Action FinRonda(Handle event, const char[] name, bool dontBroadcast)
{
  Format(g_sRondaActual, sizeof(g_sRondaActual), "none");

  for (int i = 1; i < MaxClients; i++)
  {
    if (IsClientInGame(i))
    {
      g_bSpecial[i] = false;
      g_bFD[i]      = false;
    }
  }

  return Plugin_Continue;
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message)
{
  if (g_bFD[author])
  {
    Format(name, MAXLENGTH_NAME, " \x01(\x04LIBRE\x01) %s", name);
    return Plugin_Changed;
  }

  return Plugin_Continue;
}

public void OnMapStart()
{
  Format(g_sRondaActual, sizeof(g_sRondaActual), "none");
}

public Action FijarCreditos(int client, int args)
{
  if (client == 0)
  {
    return Plugin_Handled;
  }

  if (args < 2)  // Not enough parameters
  {
    ReplyToCommand(client, "[SM] Use: sm_setcredits <#userid|name> [amount]");
    return Plugin_Handled;
  }

  char arg2[10];
  GetCmdArg(2, arg2, sizeof(arg2));

  int amount = StringToInt(arg2);
  char strTarget[32];
  GetCmdArg(1, strTarget, sizeof(strTarget));

  // Process the targets
  char strTargetName[MAX_TARGET_LENGTH];
  int TargetList[MAXPLAYERS];
  int TargetCount;
  bool TargetTranslate;

  if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
                                         strTargetName, sizeof(strTargetName), TargetTranslate))
      <= 0)
  {
    ReplyToTargetError(client, TargetCount);
    return Plugin_Handled;
  }

  // Apply to all targets
  for (int i = 0; i < TargetCount; i++)
  {
    int iClient = TargetList[i];
    if (IsClientInGame(iClient))
    {
      g_iCreditos[iClient] = amount;
      PrintToChat(client, "Set %i credits in the player %N", amount, iClient);
    }
  }

  return Plugin_Continue;
}

// Natives

any Native_AgregarPremio(Handle plugin, int argc)
{
  Premio premio;
  GetNativeString(1, premio.nombre, AWARD_NAME_MAX_LENGTH);
  premio.precio = GetNativeCell(2);
  premio.team   = GetNativeCell(3);

  PushArrayArray(g_ArrayPremios, premio);
  SortADTArrayCustom(g_ArrayPremios, PriceComparator);

  RenewMenus();
}

stock int PriceComparator(int index1, int index2, Handle array, Handle hndl)
{
  Premio premio1;
  Premio premio2;
  GetArrayArray(array, index1, premio1, sizeof(premio1));
  GetArrayArray(array, index2, premio2, sizeof(premio2));

  if (premio1.precio == premio2.precio)
    return 0;
  else if (premio1.precio > premio2.precio)
    return 1;
  else
    return -1;
}

any Native_BorrarPremio(Handle plugin, int argc)
{
  char buscado[AWARD_NAME_MAX_LENGTH];
  GetNativeString(1, buscado, sizeof(buscado));
  
  Premio premio;
  int removeIndex = -1;

  for (int i = 0; i < GetArraySize(g_ArrayPremios); i++)
  {
    GetArrayArray(g_ArrayPremios, i, premio);
    if (StrEqual(premio.nombre, buscado))
    {
      removeIndex = i;
      break;
    }
  }

  if (removeIndex >= 0)
    RemoveFromArray(g_ArrayPremios, removeIndex);

  RenewMenus();
}

any Native_ElegirRonda(Handle plugin, int argc)
{
  char buscado[AWARD_NAME_MAX_LENGTH];
  GetNativeString(1, buscado, sizeof(buscado));

  Format(g_sRondaActual, sizeof(g_sRondaActual), buscado);
}

any Native_FijarEspecial(Handle plugin, int argc)
{
  g_bSpecial[GetNativeCell(1)] = GetNativeCell(2);
}

any Native_DarFD(Handle plugin, int argc)
{
  int client    = GetNativeCell(1);
  g_bFD[client] = true;

  SetEntityRenderColor(client, 0, 255, 0, 255);
}

int Native_ObtenerFD(Handle plugin, int argc)
{
  return g_bFD[GetNativeCell(1)];
}

int Native_ObtenerEspecial(Handle plugin, int argc)
{
  return g_bSpecial[GetNativeCell(1)];
}

int Native_ObtenerCreditos(Handle plugin, int argc)
{
  return g_iCreditos[GetNativeCell(1)];
}

any Native_ObtenerRonda(Handle plugin, int argc)
{
  SetNativeString(1, g_sRondaActual, sizeof(g_sRondaActual));

  if (StrEqual(g_sRondaActual, "none", false))
    return false;

  return true;
}

any Native_FijarCreditos(Handle plugin, int argc)
{
  g_iCreditos[GetNativeCell(1)] = GetNativeCell(2);
}

any Native_Lengua(Handle plugin, int argc)
{
  char buscado[AWARD_NAME_MAX_LENGTH];
  GetNativeString(1, buscado, sizeof(buscado));

  LoadTranslations(buscado);
}

public bool IsValidClient(int client)
{
  if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
    return false;

  return true;
}