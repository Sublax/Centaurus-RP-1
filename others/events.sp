#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#include <roleplay>

#pragma newdecls required

//---------------------------------------------
//---------------------------------------------

public Plugin myinfo = 
{
	name = "Roleplay - Events", 
	author = "PastyBully", 
	description = "Roleplay - Events", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	ConnectDB();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if (StrContains(args, "/callcop") != -1) {
		return Cmd_CallCop(client, args);
	}
	
	if (StrEqual(args, "/sell"))
		return Cmd_Sell(client);
	
	return Plugin_Continue;
}


public Action Cmd_CallCop(int client, const char[] args) {
	#if defined DEBUG
	PrintToServer("Cmd_CallCop");
	#endif
	
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if (!GetClientBool(client, b_CanCallCop)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You haven't access to this command for the moment.");
		return Plugin_Handled;
	}
	
	if (strlen(args[9]) <= 0) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You have to write a message following /callcop to send a message to the police.");
		return Plugin_Handled;
	}
	
	char text[256];
	strcopy(text, sizeof(text), args);
	ReplaceString(text, sizeof(text), "/callcop", "");
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if (GetClientJobId(i) != 2)
			continue;
		
		CPrintToChatAll("{lightgreen}[COP]{default} {red}Alert !{default} A player sent you a distress message: %N: %s.", client, text);
	}
	
	SetClientBool(client, b_CanCallCop, false);
	
	return Plugin_Handled;
}
