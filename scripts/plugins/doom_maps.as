
// The doom maps won't work properly without this plugin enabled.
// This plugin exists for 3 reasons:
// 1) sv_stepsize can't be changed in map scripts.
// 2) player settings can't easily be transferred across maps using map scripts
// 3) mp_footsteps doesn't work in the map cfg

bool isDoomMap = false;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "w00tguy" );
	g_Module.ScriptInfo.SetContactInfo( "w00tguy123 - forums.svencoop.com" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

void MapInit()
{
	string map = g_Engine.mapname;
	isDoomMap = map.Find("doom2_") == 0 or map == "out" or true;
	if (isDoomMap)
	{	
		g_EngineFuncs.ServerCommand("sv_stepsize 35; mp_footsteps 0\n");
		g_EngineFuncs.ServerExecute();
	}
}

HookReturnCode MapChange()
{
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
	
	// true if this player has accepted the consequences of playing the doom maps.
	// Let this player bypass the "Attention!" room next time.
	bool acceptsStrafeBug = false;
	
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

void clientCommand(CBaseEntity@ plr, string cmd)
{
	NetworkMessage m(MSG_ONE, NetworkMessages::NetworkMessageType(9), plr.edict());
		m.WriteString(cmd);
	m.End();
}

void printkeybind(EHandle h_plr, string msg)
{
	if (!h_plr.IsValid())
		return;
	CBasePlayer@ plr = cast<CBasePlayer@>(h_plr.GetEntity());
	
	g_PlayerFuncs.PrintKeyBindingString(plr, msg);
}

void letThemPlay(CBasePlayer@ plr)
{
	g_PlayerFuncs.RespawnPlayer(plr, true, true);
	plr.SetHasSuit(true);
	g_PlayerFuncs.ApplyMapCfgToPlayer(plr, true);
	
	PlayerState@ state = getPlayerState(plr);
	CustomKeyvalues@ customKeys = plr.GetCustomKeyvalues();
	customKeys.SetKeyvalue("uiscale", state.uiScale);
	
	string msg = "[Secondary Fire] = Toggle thirdperson\n\n[Tertiary Fire] = Change HUD scale";
	g_Scheduler.SetTimeout("printkeybind", 2.0f, EHandle(plr), msg);
	g_Scheduler.SetTimeout("printkeybind", 3.0f, EHandle(plr), msg);
	g_Scheduler.SetTimeout("printkeybind", 4.0f, EHandle(plr), msg);
	g_Scheduler.SetTimeout("printkeybind", 5.0f, EHandle(plr), msg);	
}

HookReturnCode ClientJoin( CBasePlayer@ plr )
{
	if (!isDoomMap or plr is null)
		return HOOK_CONTINUE;
		
	// remember that player accepted the movement bug. Don't spawn them in the "Attention!" room.
	PlayerState@ state = getPlayerState(plr);
	if (state !is null and state.acceptsStrafeBug or plr.pev.flags & FL_FAKECLIENT != 0) {
		plr.pev.targetname = "let_me_play_damnit";
		clientCommand(plr, "cl_forwardspeed 9000;cl_sidespeed 9000;cl_backspeed 9000");
		letThemPlay(plr);
	}
	
	g_EntityFuncs.Remove(g_EntityFuncs.FindEntityByTargetname(null, "plugin_not_installed"));
	
	return HOOK_CONTINUE;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	if (!isDoomMap)
		return HOOK_CONTINUE;
		
	CBasePlayer@ plr = pParams.GetPlayer();
	PlayerState@ state = getPlayerState(plr);
	const CCommand@ args = pParams.GetArguments();
	
	if (args.ArgC() > 0 and args[0].ToLowercase() == "accept")
	{
		if (state.acceptsStrafeBug)
			return HOOK_CONTINUE; // already accepted the bug, chat as normal
			
		state.acceptsStrafeBug = true;
		clientCommand(plr, "cl_forwardspeed 9000;cl_sidespeed 9000;cl_backspeed 9000");
		g_PlayerFuncs.SayText(plr, "Movement speeds updated. Enjoy the map!\n");
		plr.pev.targetname = "let_me_play_damnit"; // map script will wait for this before letting them start
		letThemPlay(plr);
		
		pParams.ShouldHide = true;
		return HOOK_HANDLED;
	}
	
	return HOOK_CONTINUE;
}