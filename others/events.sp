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
	if(StrContains(args, "/callcop") != -1) {
		return Cmd_CallCop(client, args);
	}
	
	if(StrEqual(args, "/sell")) 
		return Cmd_Sell(client);
	
	return Plugin_Continue;
}


public Action Cmd_CallCop(int client, const char[] args) {
	#if defined DEBUG
	PrintToServer("Cmd_CallCop");
	#endif
	
	if(!IsValidClient(client))
		return Plugin_Handled;

	if(!GetClientBool(client, b_CanCallCop)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You haven't access to this command for the moment.");
		return Plugin_Handled;
	}
	
	if(strlen(args[9]) <= 0) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You have to write a message following /callcop to send a message to the police.");
		return Plugin_Handled;
	}
	
	char text[256];
	strcopy(text, sizeof(text), args);
	ReplaceString(text, sizeof(text), "/callcop", "");
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		
		if(GetClientJobId(i) != 2)
			continue;
			
		CPrintToChatAll("{lightgreen}[COP]{default} {red}Alert !{default} A player sent you a distress message: %N: %s.", client, text);
	}
	
	SetClientBool(client, b_CanCallCop, false);
	
	return Plugin_Handled;
}

public Action Cmd_Sell(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_CallCop");
	#endif
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(GetClientJobId(client) == 1) { //TODO : Add army
		ACCESS_DENIED(client);
	}	
		
	int job = GetClientJobId(client);
	
	switch(job) {
		case 2: {
			Handle menu = CreateMenu(Menu_Exchange);
			SetMenuTitle(menu, "Choose an object to be sold");
			AddMenuItem(menu, "action", "Shares on the market");
			AddMenuItem(menu, "account", "Opening a bank account");
			AddMenuItem(menu, "protec", "Protection against hacking");
			AddMenuItem(menu, "check", "Check");
			AddMenuItem(menu, "loan", "Make a loan of money");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
		
	return Plugin_Handled;
}

public int Menu_Exchange(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		if(StrEqual(items, "action")) {
			int target = GetClientTarget(client);
			
			if(!IsValidClient(target))
				return -1;
			
			Handle menu_1 = CreateMenu(Menu_ActionJob);
			AddMenuItem(menu_1, "rebel", "Rebel");
			AddMenuItem(menu_1, "bank", "Bank", GetCapital(2) > 500000 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
	
	return 0;
}

public int Menu_ActionJob(Handle menu, MenuAction action, int client, int param2) {

}