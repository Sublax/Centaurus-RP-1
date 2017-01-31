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
	name = "Roleplay - Rebel",
	author = "PastyBully",
	description = "Roleplay - Rebel",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegServerCmd("item_kit_rebel", Cmd_KitRebel);
}

public void OnMapStart() {
	PrecacheSound(UNLOCK_DOOR, true);
	PrecacheSound(LOCK_DOOR, true);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if(StrEqual(args, "/rebel") || StrEqual(args, "/r")) 
		return Cmd_Rebel(client);
	else if(StrEqual(args, "/trafic"))
		return Cmd_Trafic(client);
		
	return Plugin_Continue;
}


public Action Cmd_Rebel(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Rebel");
	#endif
	
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(!GetClientBool(client, b_LiscenceRebel)) {
		ACCESS_DENIED(client);
	}
		
	Menu menu = new Menu(Menu_Rebel);
	menu.SetTitle("Rebel menu");
	menu.AddItem("steal", "Antagonize a player");
	menu.AddItem("hold", "Hold a up a job");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
		
	return Plugin_Handled;
}

public int Menu_Rebel(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64];
		GetMenuItem(menu, param2, items, sizeof(items));
			
		if(StrEqual(items, "steal")) {
			char tmp[64], name[128];
			float vec1[3], vec2[3];
			GetClientAbsOrigin(client, vec1);
			
			Handle menu_steal = CreateMenu(Menu_Steal);
			SetMenuTitle(menu_steal, "Antagonize a player");
			for (int i = 1; i <= MaxClients; i++) {
				if(!IsValidClient(i))
					continue;
					
				if(i == client)
					continue;
					
				if(GetClientInt(i, i_LastSteal) <= 14400 && GetClientInt(i, i_LastSteal) > 0) // 4 hours in secondes
					continue;
					
				if(GetClientBool(i, b_LiscenceRebel))
					continue;
					
				GetClientAbsOrigin(i, vec2);
					
				if(GetVectorDistance(vec1, vec2) <= 350.0) {
					Format(tmp, sizeof(tmp), "%i_0", i);
					Format(name, sizeof(name), "%N", i);
					
					AddMenuItem(menu_steal, tmp, name);
				}
			}
			if(strlen(tmp) <= 0) 
				CPrintToChat(client, "{lightgreen}[RP]{default} You can't steal any player around you.");
			
			SetMenuExitButton(menu_steal, true);
			DisplayMenu(menu_steal, client, MENU_TIME_FOREVER);
		}

	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public int Menu_Steal(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64], array[2][32], info[64], content[32];
		GetMenuItem(menu, param2, items, sizeof(items));
		
		ExplodeString(items, "_", array, sizeof(array), sizeof(array[]));
		
		int target = StringToInt(array[0]);
		int number = StringToInt(array[1]);
		
		if(number == 0) {
			Handle menu_send = CreateMenu(Menu_Send);
			SetMenuTitle(menu_send, "Are you sure to want to steal %N", target);
			for (int i = 0; i < 2; i++) {
				Format(info, sizeof(info), "%i_%i", target, i);
				if(i == 0)
					Format(content, sizeof(content), "No");
				else 
					Format(content, sizeof(content), "Yes");
					
				AddMenuItem(menu_send, info, content);
			}
			SetMenuExitButton(menu_send, false);
			DisplayMenu(menu_send, client, MENU_TIME_FOREVER);
		}
	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public int Menu_Send(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_Select) {
		char items[64], array[2][32];
		GetMenuItem(menu, param2, items, sizeof(items));

		ExplodeString(items, "_", array, sizeof(array), sizeof(array[]));
		
		int target = StringToInt(array[0]);
		int number = StringToInt(array[1]);
		
		if(number == 0) {
			CPrintToChat(client, "{lightgreen}[RP]{default} You have canceled your steering on %N", target);
		} else {
			float vec1[3], vec2[3];
			GetClientAbsOrigin(client, vec1);
			GetClientAbsOrigin(target, vec2);
			
			if(GetVectorDistance(vec1, vec2) > 350.0) 
				return -1;
				
			CPrintToChat(client, "{lightgreen}[RP]{default} You search %N and you find his information.", target);
			CPrintToChat(client, "{lightgreen}[RP]{default} You have 3 minutes to bring to a successful conclusion this flight, if you exceed this time the aimed player will be able call the police.", target);
			Handle dp;
			CreateDataTimer(180.0, Timer_Steal, dp);
			WritePackCell(dp, target);
			
			char job[64], money[64], lastSteal[256], phone[64], title[64], allowed_army[64], allowed_guns[64], classname[64], weapons[64];
			int job_id = GetClientInt(target, i_JobID), money_i = GetClientInt(target, i_Money), last_steal = GetClientInt(target, i_LastSteal);
			
			//we stock the job in a char
			Format(title, sizeof(title), "Information of %N", target);
			switch(job_id) {
				case 0: 
					Format(job, sizeof(job), "Job: Sans emploi");
			}
			
			//We stock the last steal in a char
			if(GetClientInt(target, i_LastSteal) > 0) {
				if(last_steal / 60 != 0) {
					Format(lastSteal, sizeof(lastSteal), "Last steal: %dh%d", RoundFloat(last_steal / 60.0), last_steal % 60);
				}
			}
			
			//We stock money, phone, liscence1/2 and weapons in char.
			Format(money, sizeof(money), "Money: $%d", money_i);
			Format(phone, sizeof(phone), "Phone: %s", GetClientBool(target, b_Phone) ? "Yes" : "No");
			Format(allowed_army, sizeof(allowed_army), "Heavy weapon liscence: %s", GetClientBool(target, b_AllowedArmy) ? "Yes" : "No");
			Format(allowed_guns, sizeof(allowed_guns), "Light weapons license: %s", GetClientBool(target, b_AllowedGuns) ? "Yes" : "No");
			Format(weapons, sizeof(weapons), "Weapons:");
			
			int wepid;
			wepid = GetPlayerWeaponSlot(target, 1);
			if(wepid != -1) {
				GetEdictClassname(wepid, classname, sizeof(classname));
				ReplaceString(classname, sizeof(classname), "weapon_", "");
				Format(weapons, sizeof(weapons), "%s %s", weapons, classname);
			}
			wepid = GetPlayerWeaponSlot(target, 0);
			if(wepid != -1) {
				GetEdictClassname(wepid, classname, sizeof(classname));
				ReplaceString(classname, sizeof(classname), "weapon_", "");
				Format(weapons, sizeof(weapons), "%s, %s", weapons, classname);
			}
			
			if(GetPlayerWeaponSlot(target, 0) == -1 && GetPlayerWeaponSlot(target, 1) == -1) {
				Format(weapons, sizeof(weapons), "Weapons: No");
			}
			
			Handle panel = CreateMenu(Panel_Info);
			SetMenuTitle(panel, title);
			AddMenuItem(panel, "job", job, ITEMDRAW_DISABLED);
			AddMenuItem(panel, "money", money, ITEMDRAW_DISABLED);
			if(GetClientInt(target, i_LastSteal) > 0) {
				AddMenuItem(panel, "steal",  lastSteal, ITEMDRAW_DISABLED);
			}
		 	AddMenuItem(panel, "phone",  phone, ITEMDRAW_DISABLED);
		 	AddMenuItem(panel, "army",  allowed_army, ITEMDRAW_DISABLED);
		 	AddMenuItem(panel, "guns",  allowed_guns, ITEMDRAW_DISABLED);
		 	AddMenuItem(panel, "weapons", weapons, ITEMDRAW_DISABLED);
		 	
			DisplayMenu(panel, client, MENU_TIME_FOREVER);
			
			SetClientInt(client, i_LastSteal, RoundFloat(GetGameTime()));
			SetClientInt(target, i_LastSteal, RoundFloat(GetGameTime()));
			
			Handle datapack;
			char steam_id[128];
			GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id), false);
			CreateDataTimer(14400.0, Timer_ToNull, datapack, TIMER_DATA_HNDL_CLOSE);
			WritePackCell(datapack, client);
			WritePackString(datapack, steam_id);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
	
	return 0;
}

public int Panel_Info(Handle menu, MenuAction action, int client, int param2) {
	if(action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action Timer_ToNull(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("Timer_ToNull");
	#endif
	
	char steam_id[256], steam_client[256];
	ResetPack(dp);
	int client = ReadPackCell(dp);
	ReadPackString(dp, steam_id, sizeof(steam_id));
	GetClientAuthId(client, AuthId_Engine, steam_client, sizeof(steam_client), false);
	
	if(IsClientConnected(client) && StrEqual(steam_id, steam_client)) {	
		SetClientInt(client, i_LastSteal, 0);
	}
}

public Action Timer_Steal(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("Timer_Steal");
	#endif
	
	ResetPack(dp);
	int target = ReadPackCell(dp);
	
	SetClientBool(target, b_CanCallCop, true);
	CPrintToChat(target, "{lightgreen}[RP]{default} From now on you can call the police, for it write in the chat /callcop followed by your message. Warning you can't send a single message to the policeman.");
}

public Action Cmd_KitRebel(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_KitRebel");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if(!IsValidClient(client)) {
		GiveClientItem(client, 1);
		return Plugin_Handled;
	}

	int ent = GetClientAimTarget(client, false);
	
	if(ent == 0 || !(IsValidEdict(ent)) || !(IsValidEntity(ent))) {
		GiveClientItem(client, 1);
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	
	if(!(StrEqual(classname, "prop_door_rotating"))) {
		GiveClientItem(client, 1);
		return Plugin_Handled;
	}
	
	if(Entity_GetDistance(client, ent) > 70) {
		CPrintToChat(client, "{lightgreen}[RP]{default} You are too much far from the door to be able to pick it.");
		GiveClientItem(client, 1);
		return Plugin_Handled;
	}
	
	if(!Entity_IsLocked(ent)) {
		CPrintToChat(client, "{lightgreen}[RP]{default} This door is already open.");
		GiveClientItem(client, 1);
		return Plugin_Handled;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	COLOR_RED(client);
	int job = GetClientInt(client, i_JobID);
	Handle dp;
	switch(job) {
		case 1: {
			CreateDataTimer(6.0, Timer_Kit, dp, TIMER_DATA_HNDL_CLOSE);
		} case 2: {
			CreateDataTimer(7.0, Timer_Kit, dp, TIMER_DATA_HNDL_CLOSE);
		} case 3: {
			CreateDataTimer(8.0, Timer_Kit, dp, TIMER_DATA_HNDL_CLOSE);
		} case 4: {
			CreateDataTimer(9.0, Timer_Kit, dp, TIMER_DATA_HNDL_CLOSE);
		}
	}
	WritePackCell(dp, client);
	WritePackCell(dp, ent);	
		
	return Plugin_Handled;
}

public Action Timer_Kit(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("Timer_Kit");
	#endif
	
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int ent = ReadPackCell(dp);
	int job = GetClientInt(client, i_JobID);
	
	switch(job) {
		case 1: {
			if(GetRandomInt(1, 10) == 10) {
				CPrintToChat(client, "{lightgreen}[RP]{default} The unlock picking of the door failed.");
				GiveClientItem(client, 1);
				return Plugin_Handled;
			}
		} case 2: {
			if(GetRandomInt(1, 9) == 9) {
				CPrintToChat(client, "{lightgreen}[RP]{default} The unlock picking of the door failed.");
				GiveClientItem(client, 1);
				return Plugin_Handled;
			}
		} case 3: {
			if(GetRandomInt(1, 8) == 8) {
				CPrintToChat(client, "{lightgreen}[RP]{default} The unlock picking of the door failed.");
				GiveClientItem(client, 1);
				return Plugin_Handled;
			}
		} case 4: {
			if(GetRandomInt(1, 7) == 7) {
				CPrintToChat(client, "{lightgreen}[RP]{default} The unlock picking of the door failed.");
				GiveClientItem(client, 1);
				return Plugin_Handled;
			}
		}	
	}
	
	CPrintToChat(client, "{lightgreen}[RP]{default} The unlock picking of the door is a success, the door opened.");
	
	Entity_UnLock(ent);
	
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	COLOR_DEFAULT(client);
	
	return Plugin_Continue;
}
