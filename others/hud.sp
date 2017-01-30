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
	name = "Roleplay - HUD",
	author = "PastyBully",
	description = "Roleplay - HUD",
	version = "1.0",
	url = ""
};

//---------------------------------------------
int heures1 = 0, heures2 = 0, minutes1 = 0, minutes2 = 0, day = 0; //1 january 1970(in second)
//---------------------------------------------

public void OnPluginStart()
{
	DB = ConnectDB();
	SelectTime();
	CreateTimer(1.0, Timer_Time, _, TIMER_REPEAT);
}

public void SelectTime() {
	char time_sQuery[256];
	Format(time_sQuery, sizeof(time_sQuery), "SELECT heures1, heures2, minutes1, minutes2, day FROM time");
	Handle row = SQL_Query(DB, time_sQuery);
	
	if(SQL_FetchRow(row)) {
		heures1 = SQL_FetchInt(row, 0);
		heures2 = SQL_FetchInt(row, 1);
		minutes1 = SQL_FetchInt(row, 2);
		minutes2 = SQL_FetchInt(row, 3);
		day = SQL_FetchInt(row, 4);
	}
	
	CloseHandle(row);
}

public void OnPluginEnd() {
	char time_uQuery[256];
	Format(time_uQuery, sizeof(time_uQuery), "UPDATE time SET heures1='%d', heures2='%d', minutes1='%d', minutes2='%d', day='%d' WHERE id=1",
	heures1, heures2, minutes1, minutes2, day);
	SQL_FastQuery(DB, time_uQuery);
}

public void OnClientPostAdminCheck(int client) {
	CreateTimer(0.2, Timer_Hud, client, TIMER_REPEAT);
}

public Action Timer_Hud(Handle timer, any client) {
	if(GetClientMenu(client, INVALID_HANDLE) == MenuSource_Normal) {
		return Plugin_Handled;
	}
	
	int money = GetClientInt(client, i_Money), bank = GetClientInt(client, i_Bank), job_id = GetClientInt(client, i_JobID),
	salary = GetClientInt(client, i_Salary), capital = GetCapital(GetClientJobId(client));
	char tmp[512], job[128], date[256], cap[64], hack[128];
	
	FormatTime(date, sizeof(date), "Date: %d %B %Y", day);
	
	switch (job_id) {
		case 0:
			Format(job, sizeof(job), "Sans emploi");
		case 1:
			Format(job, sizeof(job), "Rebel Leader");
		case 2:
			Format(job, sizeof(job), "Rebel Officer");
		case 3:
			Format(job, sizeof(job), "Rebel");
		case 4:
			Format(job, sizeof(job), "Henchman");
		case 5:
			Format(job, sizeof(job), "Manager - Exchange");
		case 6:
			Format(job, sizeof(job), "Treasurer");
		case 7:
			Format(job, sizeof(job), "Economist");
		case 8:
			Format(job, sizeof(job), "Trader");
	}
	
	Format(cap, sizeof(cap), "Capital: $%d", capital);
	
	if(GetClientBool(client, b_Hack)) {
		int purcent = RoundFloat(GetGameTime());
		int purcent1 = GetClientInt(client, i_TimeSteal);
		purcent -= purcent1;
		purcent *= 5;
		Format(hack, sizeof(hack), "Crocheting in yard...%d%", purcent);
		
		if(purcent >= 100) {
			SetClientBool(client, b_Hack, false);
			SetClientInt(client, i_TimeSteal, 0);
			Format(hack, sizeof(hack), "");
		}
	}
	
	Format(tmp, sizeof(tmp), "Time: %i%ih%i%i\nMoney: $%d\nBank: $%d\nJob: %s\nSalary: $%d\n%s\n%s\n", heures1, heures2, 
	minutes1, minutes2, money, bank, job, salary, GetClientBoss(client) ? cap : "", strlen(hack) > 0 ? hack : "");
	Handle panel = CreatePanel();
	SetPanelTitle(panel, "[RP] My Information");
	DrawPanelText(panel, date);
	DrawPanelText(panel, tmp);
	SendPanelToClient(panel, client, Panel_Hud, 1);
	CloseHandle(panel);
	
	return Plugin_Continue;
}

public int Panel_Hud(Handle panel, MenuAction action, int client, int param2) {}

public Action Timer_Time(Handle timer, any client) {
	if(heures1 >= 2 && heures2 >= 3 && minutes1 >= 5 && minutes2 >= 9) {
		heures1 = 0;
		heures2 = 0;
		minutes1 = 0;
		minutes2 = 0;
	} else {
		if(minutes2 < 10) {
			minutes2++;
		}
		
		if(minutes2 == 10) {
			minutes2 = 0;
			minutes1++;
		}
		
		if(minutes1 == 6 && minutes2 == 0) {
			heures2++;
			minutes1 = 0;
			minutes2 = 0;
		}
		
		if(heures2 == 9) {
			heures1++;
			heures2 = 0;
		}
	}
	
	if(heures1 == 0 && heures2 == 0 && minutes1 == 0 && minutes2 == 0) {
		SendSalaray();
		day += 86400;
	}
}

public void SendSalaray() {
	int salary, random;
	for (int i = 1; i <= MaxClients; i++) {
		
		if(!IsValidClient(i))
			return;
		
		salary = GetClientInt(i, i_Salary);
		//TODO : Add check, if the client is in jail
		if(GetClientInt(i, i_JobID) != 0) 
			SetCapital(GetClientJobId(i), GetCapital(GetClientJobId(i)) - salary);
		else {
			random = GetRandomCapital(GetClientJobId(i));
			SetCapital(random, GetCapital(random) - salary);
		}
		
		SetClientInt(i, i_Bank, GetClientInt(i, i_Bank) + salary);
		CPrintToChat(i, "{lightgreen}[RP]{default} You have just received your salary of %d$.", salary);
	}	
}