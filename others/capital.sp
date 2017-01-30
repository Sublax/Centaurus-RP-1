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
//---------------------------------------------

public Plugin myinfo = 
{
	name = "Roleplay - Capital",
	author = "PastyBully",
	description = "Roleplay - Capital",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	DB = ConnectDB();
	
	for (int i = 1; i <= 10; i++) {
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT capital FROM job WHERE id_job = '%d'", i);
		Handle row = SQL_Query(DB, sQuery);
		
		if(SQL_FetchRow(row)) {
			SetCapital(i, SQL_FetchInt(row, 0));
			SetMondayCapital(i, GetCapital(i));
		}
	}
	
	CreateTimer(25.0, Timer_UpdateInfo, TIMER_REPEAT);
	CreateTimer(10080.0, Timer_Census, TIMER_REPEAT);
}

public void OnPluginEnd() {
	/*int protect;
	for (int i = 1; i <= 10; i++) {
		char uQuery[256];
		if(GetProtectJob(i))
			protect = 1;
		else 
			protect = 2;
		Format(uQuery, sizeof(uQuery), "UPDATE job SET capital='%d', protect_hackind='%d' WHERE id_job = '%d'", GetCapital(GetClientJobId(i)), protect, i);
		SQL_FastQuery(DB, uQuery);
	}*/
}

public Action Timer_UpdateInfo(Handle timer) { 
	#if defined DEBUG
	PrintToServer("Timer_UpdateInfo");
	#endif
	
	char hour[12], minute[12], day[12];
	FormatTime(hour, sizeof(hour), "%H");
	FormatTime(minute, sizeof(minute), "%M");
	Format(day, sizeof(day), "%w");

	if((StringToInt(hour) == 18 && StringToInt(minute) == 00) || (StringToInt(hour) == 20 && StringToInt(minute) == 00) || (StringToInt(hour) == 23  && StringToInt(minute) == 00) || (StringToInt(hour) == 02 && StringToInt(minute) == 00) || (StringToInt(hour) == 04 && StringToInt(minute) == 00) || (StringToInt(hour) == 07 && StringToInt(minute) == 00) || (StringToInt(hour) == 08 && StringToInt(minute) == 00) || (StringToInt(hour) == 10 && StringToInt(minute) == 00) || (StringToInt(hour) == 12 && StringToInt(minute) == 00) || (StringToInt(hour) == 15 && StringToInt(minute) == 00)) {
		char uQuery[256];
		for (int i = 1; i <= 10; i++) {
			Format(uQuery, sizeof(uQuery), "UPDATE job SET capital='%d', protect_hacking='%d' WHERE id_job='%d'", GetCapital(i), GetProtectJob(i), i);
			SQL_FastQuery(DB, uQuery);
		}
	}	
	
	if(StringToInt(day) == 0 && (StringToInt(hour) == 00 && StringToInt(minute) == 00)) {
		char dropTable[128];
		Format(dropTable, sizeof(dropTable), "DROP TABLE IF EXISTS monday_classment");
		SQL_FastQuery(DB, dropTable);
		
		char putTable[256];
		Format(putTable, sizeof(putTable), "CREATE TABLE monday_classment AS SELECT id, id_job, capital FROM job WHERE capital > 500000");
		SQL_FastQuery(DB, putTable);
	}
	
	return Plugin_Continue;
}

public Action Timer_Census(Handle timer) {
	#if defined DEBUG
	PrintToServer("Timer_Census");
	#endif
	
	if(GetClientCount() <= 0) {
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		if(!GetClientBool(i, b_Census))
			continue;
		
		if(GetClientInt(i, i_Bank) < 100) {
			if(GetClientInt(i, i_Money) > 100) {
				SetClientInt(i, i_Money, GetClientInt(i, i_Money) - 100);
				CPrintToChat(i, "{lightgreen}[RP]{default} The municipality of Madison has just taken you a $100 tax.");
				return Plugin_Handled;
			}
		} else {
			SetClientInt(i, i_Bank, GetClientInt(i, i_Bank) - 100);
			CPrintToChat(i, "{lightgreen}[RP]{default} The municipality of Madison has just taken you a $100 tax.");
			return Plugin_Handled;
		}
	}
	
	// If the client isn't connected.
	int now = GetTime();
	char sQuery[256], uQuery[256], steam_id[128];
	Format(sQuery, sizeof(sQuery), "SELECT steam_id, bank, last_connexion FROM register WHERE census=1");
	Handle row = SQL_Query(DB, sQuery);

	while(SQL_FetchRow(row)) {
		SQL_FetchString(row, 0, steam_id, sizeof(steam_id));
		if(now - SQL_FetchInt(row, 2) <= 259200) {
			Format(uQuery, sizeof(uQuery), "UPDATE register SET bank='%d' WHERE steam_id='%s' AND last_connexion='%d'", SQL_FetchInt(row, 1) - 100, steam_id, now - SQL_FetchInt(row, 2));
		}
	}
	
	return Plugin_Continue; 
}