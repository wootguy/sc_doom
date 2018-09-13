
// The doom maps won't work properly without this plugin enabled.
// This plugin exists for 3 reasons:
// 1) sv_stepsize can't be changed in map scripts.
// 2) player settings can't easily be transferred across maps using map scripts
// 3) mp_footsteps doesn't work in the map cfg

bool isDoomMap = false;
bool loaded_unlocks = false;
int g_rewards = 0;
int g_unlocks = 0;
CScheduledFunction@ unlock_poll = null;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "w00tguy" );
	g_Module.ScriptInfo.SetContactInfo( "w00tguy123 - forums.svencoop.com" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

void MapInit()
{
	bool oldDoomMap = isDoomMap;
	string map = g_Engine.mapname;
	isDoomMap = map.Find("doom2_") == 0;
	if (isDoomMap)
	{
		loaded_unlocks = false;
		g_EngineFuncs.ServerCommand("sv_stepsize 35; mp_footsteps 0\n");
		g_EngineFuncs.ServerExecute();
		
		if (map.Find("doom2_ep1") == 0) {
			g_unlocks = 0; // don't keep unlocks if restarting the compaign
			g_rewards = 0;
		}
	} else {
		if (oldDoomMap)
		{
			println("Re-enabled footstep sounds");
			g_EngineFuncs.ServerCommand(";mp_footsteps 1;\n");
			g_EngineFuncs.ServerExecute();
		}
		g_unlocks = 0;
		g_rewards = 0;
	}
}

// for some reason I can't get the counter value on MapChange, so I have to poll for updates...
void save_unlocks() {
	if (!isDoomMap) {
		return;
	}
	CBaseEntity@ count = g_EntityFuncs.FindEntityByTargetname(null, "unlock_counter");
	if (count !is null) {
		g_rewards = int(count.pev.frags);
		g_unlocks = int(count.pev.health);
	}
	
	@unlock_poll = g_Scheduler.SetTimeout("save_unlocks", 1);
}

HookReturnCode MapChange()
{
	g_Scheduler.RemoveTimer(unlock_poll);
	@unlock_poll = null;
	
	array<string>@ stateKeys = player_states.getKeys();
	for (uint i = 0; i < stateKeys.length(); i++)
	{
		PlayerState@ state = cast<PlayerState@>( player_states[stateKeys[i]] );
		if (!state.h_plr.IsValid())
			continue;
		
		CBasePlayer@ plr = cast<CBasePlayer@>(state.h_plr.GetEntity());
		CustomKeyvalues@ customKeys = plr.GetCustomKeyvalues();
		if (customKeys.HasKeyvalue("uiscale"))
			state.uiScale = customKeys.GetKeyvalue("uiscale").GetInteger();
	}
	return HOOK_CONTINUE;
}

class PlayerState
{
	EHandle h_plr;
	
	// keep uiScale across maps (CPersistance doesn't work last I tried, and global states can't store steamids)
	int uiScale = 1;
}
dictionary player_states;

PlayerState@ getPlayerState(CBasePlayer@ plr)
{
	string steamId = g_EngineFuncs.GetPlayerAuthId( plr.edict() );
	if (steamId == 'STEAM_ID_LAN' or steamId == 'BOT') {
		steamId = plr.pev.netname;
	}
	
	if ( !player_states.exists(steamId) )
	{
		PlayerState state;
		state.h_plr = plr;
		player_states[steamId] = state;
	}
	return cast<PlayerState@>( player_states[steamId] );
}

void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

HookReturnCode ClientJoin( CBasePlayer@ plr )
{
	if (!isDoomMap or plr is null)
		return HOOK_CONTINUE;
		
	if (!loaded_unlocks) {
		loaded_unlocks = true;
		CBaseEntity@ count = g_EntityFuncs.FindEntityByTargetname(null, "unlock_counter");
		if (count !is null) {
			count.pev.frags = g_rewards;
			count.pev.health = g_unlocks;
			println("doom_maps: loaded " + g_unlocks + " unlocks and " + g_rewards + " rewards");
			g_unlocks = 0;
			g_rewards = 0;
			g_Scheduler.SetTimeout("save_unlocks", 1);
		}		
	}
	
	g_EntityFuncs.Remove(g_EntityFuncs.FindEntityByTargetname(null, "plugin_not_installed"));
	
	return HOOK_CONTINUE;
}