#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#include <roleplay>

#pragma newdecls required

//---------------------------------------------
bool canGiveMoney = false;
int id_target;

Handle DB = INVALID_HANDLE;
//---------------------------------------------

public Plugin myinfo = 
{
	name = "Roleplay - Bank", 
	author = "PastyBully", 
	description = "Roleplay - Bank", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	DB = ConnectDB();
	
	RegServerCmd("item_protection_hack", Cmd_ProtectionHack);
	RegServerCmd("item_account", Cmd_ItemAccount);
	RegServerCmd("item_check", Cmd_ItemCheck);
	RegServerCmd("item_census", Cmd_ItemCensus);
}

public void OnClientPostAdminCheck(int client) {
	if (GetClientBoss(client))
		CreateTimer(5.0, Timer_BossExchange, client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if (canGiveMoney) {
		if (StrContains(args, "/give") != -1) {
			return Cmd_Give(client, args);
		}
	}
	
	if (StrEqual(args, "/test"))
		return Cmd_Test(client);
	else if (StrEqual(args, "/exchange") || StrEqual(args, "/ex"))
		return Cmd_Exchange(client);
	else if(StrEqual(args, "/regexchange"))
		return Cmd_RegExchange(client);
	
	return Plugin_Continue;
}

public Action Cmd_Test(int client) {
	
	if (GetClientBool(client, b_Census))
		PrintToChatAll("ok");
	else
		PrintToChatAll("test");
	
	//ServerCommand("item_loan_money %d", client);
	
	return Plugin_Handled;
}

public Action Cmd_ProtectionHack(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ProtectionHack");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if (!GetClientBoss(client)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You are not a leader of your job.");
		GiveClientItem(client, 2);
		return Plugin_Handled;
	}
	
	if (GetProtectJob(GetClientJobId(client))) {
		CPrintToChat(client, "{lightgreen}[RP]{default} Your job already possesses a protection against the rebels hackings.");
		GiveClientItem(client, 2);
		return Plugin_Handled;
	}
	
	SetProtectJob(GetClientJobId(client), true);
	CPrintToChat(client, "{lightgreen}[RP]{default} Your job possesses from now on a protection against the rebels hackings. Rebels cannot extract from now on anymore some money from your capital and this for 2 days IRL.");
	
	return Plugin_Handled;
}

public Action Cmd_ItemAccount(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAccount");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if (GetClientBool(client, b_Account)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You already possess a bank account.");
		GiveClientItem(client, 3);
		return Plugin_Handled;
	}
	
	SetClientBool(client, b_Account, true);
	CPrintToChat(client, "{lightgreen}[RP]{default} You possess from now on a bank account. You can deposit/withdraw money from now on of your bank, as well as store items in this one.");
	
	return Plugin_Handled;
}

public Action Cmd_ItemCheck(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAccount");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	char info[128], tmp[128];
	
	Handle menu = CreateMenu(Menu_ListPlayer);
	SetMenuTitle(menu, "Please choose a player: ");
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if (i == client)
			continue;
		
		Format(info, sizeof(info), "%N", i);
		Format(tmp, sizeof(tmp), "%i", i);
		
		AddMenuItem(menu, tmp, info);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_ListPlayer(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		char items[64], array[2][32];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		ExplodeString(items, "_", array, sizeof(array), sizeof(array[]));
		
		int target = StringToInt(array[0]);
		id_target = target;
		CPrintToChat(client, "{lightgreen}[RP]{default} Please write in the chat: /give followed by the sum to be transferred to %N.", target);
		canGiveMoney = true;
		
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Cmd_Give(int client, const char[] args) {
	#if defined DEBUG
	PrintToServer("Cmd_Give");
	#endif
	
	if (strlen(args[5]) <= 0) {
		CPrintToChat(client, "{lightgreen}[RP]{default} Please enter an amount.");
		return Plugin_Handled;
	}
	
	int money = StringToInt(args[5]);
	
	if (money <= 0) {
		CPrintToChat(client, "{lightgreen}[RP]{default} The amount of your gifts must be upper to 0.");
		return Plugin_Handled;
	}
	
	if (GetClientInt(client, i_Money) < money) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You don't have $%d on you, please seize another amount.", money);
		return Plugin_Handled;
	}
	
	SetClientInt(client, i_Money, GetClientInt(client, i_Money) - money);
	SetClientInt(id_target, i_Money, GetClientInt(id_target, i_Money) + money);
	
	CPrintToChat(client, "{lightgreen}[RP]{default} You have just given $%d to %N.", money, id_target);
	CPrintToChat(id_target, "{lightgreen}[RP]{default} %N has just given you $%d.", client, money);
	
	return Plugin_Handled;
}

public Action Cmd_ItemCensus(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_Give");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if (GetClientBool(client, b_Census)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You are already listed in the inhabitants of this city.");
		return Plugin_Handled;
	}
	
	SetClientBool(client, b_Census, true);
	
	return Plugin_Handled;
}

public Action Cmd_Exchange(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Exchange");
	#endif
	
	char sQuery[256], tmp[256], name[128], diff[128];
	int difference;
	
	Format(sQuery, sizeof(sQuery), "SELECT job.name, monday_classment.capital, job.id_job FROM job INNER JOIN monday_classment ON job.id_job=monday_classment.id_job ORDER BY job.capital DESC");
	Handle row = SQL_Query(DB, sQuery);
	
	Handle menu = CreateMenu(Menu_Classment);
	SetMenuTitle(menu, "Classification of the capital");
	
	while (SQL_FetchRow(row)) {
		difference = SQL_FetchInt(row, 1) - GetCapital(SQL_FetchInt(row, 2));
		Format(diff, sizeof(diff), "$%d", difference);
		ReplaceString(diff, sizeof(diff), "-", "");
		
		SQL_FetchString(row, 0, name, sizeof(name));
		Format(tmp, sizeof(tmp), "%s: $%d (%s%s)", name, GetCapital(SQL_FetchInt(row, 2)), difference < 0 ? "↘-" : "↗+", diff);
		
		AddMenuItem(menu, "1", tmp, ITEMDRAW_DISABLED);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_Classment(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Timer_BossExchange(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Timer_BossExchange");
	#endif
	
	if (GetClientBool(client, b_ContactBoss)) {
		if (!GetExchangeJob(GetClientJobId(client))) {
			if (GetCapital(GetClientJobId(client)) > 500000) {
				Handle menu = CreateMenu(Menu_BossAddJobToExchange);
				SetMenuTitle(menu, "Your job exceeded $500 000 of capital, do you \nwant to register him to the stock exchange?");
				AddMenuItem(menu, "advantage", "See the benefits");
				AddMenuItem(menu, "yes", "I want to register my job in stock exchange");
				AddMenuItem(menu, "no", "I am not interest for the moment");
				AddMenuItem(menu, "ask", "More do not ask me");
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
		}
	}
}

public int Menu_BossAddJobToExchange(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		Handle menu_second = CreateMenu(Menu_ManageIncriptionExchange);
		if (StrEqual(items, "advantage")) {
			SetMenuTitle(menu_second, "Advantage of the stock exchange");
			AddMenuItem(menu_second, "1", "If a person buys actions on your job, your capital wins 5% \nof the bought amount", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "2", "---------------------------", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "3", "The price of the objects which sold you increases by 5%", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "4", "---------------------------", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "5", "All the members of your job can put printers 3 in more", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "6", "---------------------------", ITEMDRAW_DISABLED);
			AddMenuItem(menu_second, "7", "A classification is made for the end of every week according \nto the biggest capital increase, the first one wins a random bonus", ITEMDRAW_DISABLED);
			SetMenuExitButton(menu_second, false);
			SetMenuExitBackButton(menu_second, true);
			DisplayMenu(menu_second, client, MENU_TIME_FOREVER);
			
		} else if (StrEqual(items, "yes")) {
			SetExchangeJob(GetClientJobId(client), true);
			CPrintToChat(client, "{lightgreen}[RP]{default} Your job is registered from now on on the stock exchange.");
			PutContactBoss(client, 1, GetClientJobId(client), 1);
		} else if (StrEqual(items, "no")) {
			CPrintToChat(client, "{lightgreen}[RP]{default} Your job was not register on the stock exchange.");
		} else if (StrEqual(items, "ask")) {
			PutContactBoss(client, 1, GetClientJobId(client), 0);
			CPrintToChat(client, "{lightgreen}[RP]{default} From now on, you will not be any more notified for your registration to the stock exchange, however you can bang /regexchange to join.");
		}
		
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public int Menu_ManageIncriptionExchange(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
	} else if(action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack) {
			Handle menu_first = CreateMenu(Menu_BossAddJobToExchange);
			SetMenuTitle(menu_first, "Your job exceeded $500 000 of capital, do you \nwant to register him to the stock exchange?");
			AddMenuItem(menu_first, "advantage", "See the benefits");
			AddMenuItem(menu_first, "yes", "I want to register my job in stock exchange");
			AddMenuItem(menu_first, "no", "I am not interest for the moment");
			AddMenuItem(menu_first, "ask", "More do not ask me");
			DisplayMenu(menu_first, client, MENU_TIME_FOREVER);
		} 
	}
} 

public Action Cmd_RegExchange(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_RegExchange");
	#endif
	
	CreateTimer(0.1, Timer_BossExchange, client);
	
	return Plugin_Handled;
}



public void PutContactBoss(int client, int valor, int id_job, int fac) {
	char uQuery[255], facQuery[256];
	Format(uQuery, sizeof(uQuery), "UPDATE job SET contact_boss='%d' WHERE id_job='%d'", valor, GetClientJobId(client));
	SQL_FastQuery(DB, uQuery);
	
	if(fac == 1) {
		Format(facQuery, sizeof(facQuery), "UPDATE job SET is_exchange=1 WHERE id_job='%d'", GetClientJobId(client));
		SQL_FastQuery(DB, facQuery);
	}
}