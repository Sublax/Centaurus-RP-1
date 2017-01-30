#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#include <roleplay>

#pragma newdecls required

#define MODEL_ATM "models/props_unique/atm01.mdl"

public Plugin myinfo = 
{
	name = "Roleplay - ATM",
	author = "PastyBully",
	description = "Roleplay - ATM",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	ConnectDB();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if(buttons == IN_USE) {
		int target = GetClientAimTarget(client, false);

		if(target == 0 || !IsValidEdict(target) || !IsValidEntity(target)) 
			return Plugin_Handled;
		
		char model[256]; 
		GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));

		if(StrEqual(model, MODEL_ATM)) {
			float vec1[3];
			GetClientAbsOrigin(client, vec1);

			if(Entity_GetDistanceOrigin(target, vec1) <= 100.0) {	
				
				Handle menu = CreateMenu(Menu_ATM);
				SetMenuTitle(menu, "ATM");
				
				char info[128], nom[128];
				for (int i = 0; i < 2;i++) {	
					Format(info, sizeof(info), "%i", i);
					Format(nom, sizeof(nom), "%s", i == 0 ? "Withdraw money" : "Deposit money");
					
					AddMenuItem(menu, info, nom);
				}
				
				if(GetClientJobId(client) == 1) {
					if(GetClientInt(client, i_LastSteal) - GetGameTime() > 3600 || GetClientInt(client, i_LastSteal) == 0) {
						AddMenuItem(menu, "2", "Hack an bank account");
					}
				}
				
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 60);
			}
		}
	}
	
	return Plugin_Continue;	
}

public int Menu_ATM(Handle menu, MenuAction action, int client, int param2) {

	if(action == MenuAction_Select) {
		char items[64], array[2][32];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		ExplodeString(items, "_", array, sizeof(array), sizeof(array[]));
	
		int number = StringToInt(array[0]);
		
		switch(number) {
			case 0: {
				Handle Withdraw_Menu = CreateMenu(Withdraw);
				SetMenuPagination(Withdraw_Menu, MENU_NO_PAGINATION );
				SetMenuTitle(Withdraw_Menu, "Withdraw");
				AddMenuItem(Withdraw_Menu, "1", "Widthdraw all my money", GetClientInt(client, i_Bank) != 0  ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
				
				int x = 1;
				char name[128], id[64];
				for (int i = 1; i <= 6; i++) {
					Format(name, sizeof(name), "%i$", x);
					Format(id, sizeof(id), "%i", i+1);
					
					AddMenuItem(Withdraw_Menu, id, name, GetClientInt(client, i_Bank) >= x ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
					x *= 10;
				}
				
				SetMenuExitButton(Withdraw_Menu, true);
				DisplayMenu(Withdraw_Menu, client, MENU_TIME_FOREVER);
			} case 1: {
				
				Handle Deposit_Menu = CreateMenu(Deposit);
				SetMenuPagination(Deposit_Menu, MENU_NO_PAGINATION );
				SetMenuTitle(Deposit_Menu, "Deposit");
				AddMenuItem(Deposit_Menu, "1", "Deposit all money", GetClientInt(client, i_Money) != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
				
				int x = 1;
				char name[128], id[32];
				for (int i = 1; i <= 6; i++) {
					Format(name, sizeof(name), "%i$", x);
					Format(id, sizeof(id), "%i", i+1);
					
					AddMenuItem(Deposit_Menu, id, name, GetClientInt(client, i_Money) >= x ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
					x *= 10;
				}
				
				SetMenuExitButton(Deposit_Menu, true);
				DisplayMenu(Deposit_Menu, client, MENU_TIME_FOREVER);
				
			} case 2: {
				SetEntityMoveType(client, MOVETYPE_NONE);
				COLOR_RED(client);
				SetClientBool(client, b_Hack, true);
				SetClientInt(client, i_TimeSteal, RoundFloat(GetGameTime()));
				CreateTimer(20.0, Timer_Hack, client);
			}
		}
		
	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Timer_Hack(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Timer_Hack");
	#endif
	
	int capital = GetRandomCapital(GetClientJobId(client)), capital_client = GetCapital(GetClientJobId(client));
	int job = GetClientInt(client, i_JobID);
	int steal_max, steal;
	
	switch(job) {
		case 1: {
			steal_max = 1500;
		} case 2: {
			steal_max = 1250;
		} case 3: {
			steal_max = 1000;
		} case 4: {
			steal_max = 900;
		}
	}
	
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	COLOR_DEFAULT(client);
	
	steal = GetRandomInt(100, steal_max);
	SetClientInt(client, i_Money, GetClientInt(client, i_Money) + steal);
	SetCapital(capital, GetCapital(capital) - steal);
	SetCapital(GetClientJobId(client), capital_client + (steal / 2));
	
	CPrintToChat(client, "{lightgreen}[RP]{default} The banking hacking is a success you stole $%d.", steal);
	
	return Plugin_Continue;
}

public int Withdraw(Menu menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		int bank = GetClientInt(client, i_Bank);
		
		if(StrEqual(items, "1")) {
			SetClientInt(client, i_Bank, GetClientInt(client, i_Bank) - bank);
			SetClientInt(client, i_Money, GetClientInt(client, i_Money) + bank);
			CPrintToChat(client, "{lightgreen}[RP]{default} You have deposited all your money into your bank account(%i$).", bank);
		}
		
		int x = 1;
		char id[32];
		for (int i = 2; i <= 7; i++) {
			Format(id, sizeof(id), "%i", i);
			if(StrEqual(items, id)) {
				if(GetClientInt(client, i_Bank) < x) {
					CPrintToChat(client, "{lightgreen}[RP]{default} Do not possess $%d in your bank account.", x);
				} else {					
					SetClientInt(client, i_Bank, GetClientInt(client, i_Bank) - x);
					SetClientInt(client, i_Money, GetClientInt(client, i_Money) + x);
					CPrintToChat(client, "{lightgreen}[RP]{default} You have withdraw %i$.", x);
				}
			}
			
			x *= 10;
		}
		
		DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), 60); 
		
	} else if(action == MenuAction_Cancel) {
		CloseHandle(menu);
	}
	
	return 0;
}

public int Deposit(Menu menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		int money = GetClientInt(client, i_Money);
		
		if(StrEqual(items, "1")) {
			SetClientInt(client, i_Money, GetClientInt(client, i_Money) - money);
			SetClientInt(client, i_Bank, GetClientInt(client, i_Bank) + money);
			CPrintToChat(client, "{lightgreen}[RP]{default} You have deposited all your money into your bank account(%i$).", money);
		}
		
		int x = 1;
		char id[32];
		for (int i = 2; i <= 7; i++) {
			Format(id, sizeof(id), "%i", i);
			if(StrEqual(items, id)) {
				if(GetClientInt(client, i_Money) < x) {
					CPrintToChat(client, "{lightgreen}[RP]{default} Do not possess $%d on you.", x);
				} else {
					SetClientInt(client, i_Money, GetClientInt(client, i_Money) - x);
					SetClientInt(client, i_Bank, GetClientInt(client, i_Bank) + x);
					CPrintToChat(client, "{lightgreen}[RP]{default} You have deposited %i$.", x);
				}
			}
				
			x *= 10;
		}
		
		DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), 60); 
		
	} else if(action == MenuAction_Cancel) {
		CloseHandle(menu);
	}
}