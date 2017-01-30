#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#include <roleplay>

#pragma newdecls required

//---------------------------------------------
Handle DB = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Roleplay - Commands",
	author = "PastyBully",
	description = "Roleplay - Commands",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	DB = ConnectDB();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if(StrEqual(args, "/inventory") || StrEqual(args, "/bag") || StrEqual(args, "/b") || StrEqual(args, "/i")) {
		return Cmd_Inventory(client);
	}
	return Plugin_Continue;
}

public Action Cmd_Inventory(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Inventory");
	#endif

	if(!IsValidClient(client)) 
		return Plugin_Handled;
		
	char sQuery[256], steam_id[256], inventory[256], items[256], id_item[128];
	GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id), false);
	Format(sQuery, sizeof(sQuery), "SELECT name, number, id_item FROM inventory WHERE steam_id='%s' AND number <> 0", steam_id);
	Handle row = SQL_Query(DB, sQuery);
	
	if(SQL_GetRowCount(row) == 0) {
		CPrintToChat(client, "{lightgreen}[RP]{default} Your inventory is empty.");
		return Plugin_Handled;
	}

	Menu menu = new Menu(Menu_Inventory);
	menu.SetTitle("Your inventory");

	while(SQL_FetchRow(row)) {
		int number = SQL_FetchInt(row, 1);	
		int id = SQL_FetchInt(row, 2);
		SQL_FetchString(row, 0, items, sizeof(items));
		Format(inventory, sizeof(inventory), "%s [%i]", items, number);
		Format(id_item, sizeof(id_item), "%i_%i", id, number);
		menu.AddItem(id_item, inventory);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_Inventory(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64], array[2][32];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		ExplodeString(items, "_", array, sizeof(array), sizeof(array[]));
		
		int id_item = StringToInt(array[0]);
		int number = StringToInt(array[1]);
	
		if(id_item == 1) 
			ServerCommand("item_kit_rebel %d", client);
			
		char uQuery[256], steam_id[256];
		GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id), false);
		Format(uQuery, sizeof(uQuery), "UPDATE inventory SET number='%d' WHERE id_item='%d' AND steam_id='%s'", number - 1, id_item, steam_id);
		SQL_FastQuery(DB, uQuery);
		
	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}


