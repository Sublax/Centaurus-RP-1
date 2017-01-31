 /*
**
*/
#if defined _INCLUDE_included
 #endinput
#endif
#define _INCLUDE_included

//---------------------------------------------
#define ACCESS_DENIED(%1) CPrintToChat(%1, "{lightgreen}[RP]{default} You don't have access to this command."); return Plugin_Handled
#define COLOR_RED(%1) SetEntityRenderColor(%1, 255, 0, 0, 0)
#define COLOR_DEFAULT(%1) SetEntityRenderColor(%1, 255, 255, 255, 255)
#define UNLOCK_DOOR "doors/latchunlocked1.wav"
#define LOCK_DOOR "doors/default_locked.wav"
//---------------------------------------------

enum int_client_data {
	i_JobID = 0, 
	i_Money, 
	i_Bank,
	i_Salary,
	i_LastSteal,
	i_TimeSteal,
	i_Action
};

enum bool_client_data {
	b_AllowedArmy,
	b_AllowedGuns, 
	b_LiscenceRebel,
	b_Phone,
	b_CanCallCop,
	b_Hack,
	b_Account,
	b_Census,
	b_ContactBoss
};

//---------------------------------------------
/**
* Take an integer property of a client
*
* @param  int    			 client
* @param  int_client_data    data_enum 
* @return int				 Integer property of a client
*/
native int GetClientInt(int client, int_client_data data);
/**
* Set an integer property of a client
*
* @param  int    			 client
* @param  int_client_data    data_enum 
* @param  int   			 valor 			 
*/
native void SetClientInt(int client, int_client_data data, int valor);
/**
* Get an boolean property of a client
*
* @param  int    			 client
* @param  bool_client_data   data_enum 
* @return bool     	         boolean property of a client 		 
*/
native bool GetClientBool(int client, bool_client_data data);
/**
* Set an boolean property of a client
*
* @param  int    			 client
* @param  bool_client_data   data_enum 
* @param  bool   			 valor 			 
*/
native void SetClientBool(int client, bool_client_data data, bool valor);
/**
* Check if a client is a valid client
*
* @param  int    		    client
* @return bool  			true if client is valid client, false otherwise 			 
*/

native bool IsValidClient(int client);
/**
* Check the job of a client
*
* @param  int    		    client
* @return int  			    id of the client job		 	
*/
native int GetClientJobId(int client);
/**
* Take the id of the target
*
* @param  int    		    client
* @return int  			    return the id of the target	 	
*/
native int GetClientTarget(int client);
/**
* Get a arg int 
*
* @param  int    		    id
* @return int  			    return the change from arg to integer	
*/
native int GetCmdArgInt(int id); 
/**
* Give an item to a client
*
* @param  int    		    client
* @param  int    		    id_item
*/
native void GiveClientItem(int client, int id_item);
/**
* Get the capital of a job
*
* @param  int    		    id_job (1, 2, 3 etc)
* @return int 				valor of capital
*/
native int GetCapital(int id_job);
/**
* Set a valor to the capital of a job
*
* @param  int    		    id_job (1, 2, 3 etc)
* @param  int    		    valor
*/
native void SetCapital(int id_job, int valor);
/**
* Check if the client is a boss or deputy
*
* @param  int    		    client
* @return bool              true if the client is a boss or deputy false otherwise
*/
native bool GetClientBoss(int client);
/**
* Get random capital
* @param  int    		   id capital of the client
* @return int              id of random capital
*/
native int GetRandomCapital(int id_capital);
/**
* Get if a job is in exchange
* @param  int    		  id of the job
* @return bool            true if the job is in exchange false otherwise
*/
native bool GetExchangeJob(int id_job);
/**
* Set a job in exchange or delete a job in exchange
* @param  int    		  id of the job
* @param  bool    		  valor
*/
native void SetExchangeJob(int id_job, bool valor);
/**
* Get the protection of a job
* @param  int    		  id of the job
* @return bool            true if the job is protect against the hack false otherwise
*/
native bool GetProtectJob(int id_job);
/**
* Set the protection of a job
* @param  int    		  id of the job
* @param  bool    		  valor
*/
native bool SetProtectJob(int id_job, bool valor=false);


//---------------------------------------------

stock Handle ConnectDB() {
	char error[256];
	Handle db = SQL_Connect("csgo", true, error, sizeof(error));
	
	if(db == INVALID_HANDLE) {
		PrintToServer("The connection to the database is a fail, %s", error);
	} else {
		PrintToServer("The connection to the database is a success.");
	}
	
	return db;
}

stock bool FilterTraceTarget(int entity, int contentsMask, any data){ 
	static char class[64];
	GetEdictClassname(entity, class, sizeof(class));
	
	if(data == entity)
		return false;
		
	return true;
}

//---------------------------------------------