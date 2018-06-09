#include "weapons"
#include "monsters"
#include "items"
#include "utils"
#include "func_doom_door"
#include "func_doom_water"
#include "trigger_doom_teleport"
#include "info_node_sound"

// TODO:
// alert players that their movement will get rekt if they don't edit config
// add changelevel and to-never-be-continued message
// copy bug notice to ep2
// floating barrells in map2
// secrets not working in tunnels?
// invisible fireballs from hell knioghts

// TEST: teleport in tricks and traps
// TEST WITH LAG: teleport effects dont show when in different vis area

// TODO (bugs I'm ignoring cuz 2 lazy):
// pain elemental gets stuck when shooting shulls sometimes 
// revived monsters sometimes invisible until your view angle changes
// map11 souls trying to kill each other but hitting ceiling
// monsters aim too high
// somehow exceeding ammo limit for pistol (dropped weapons?)
// weapon sprites skip frames with high ping (need to redo everything with models :'<)
// fall through level in dead simple next to teleport at start
// cacdemon gets stuck at tiny lips when it could easily float around them
// player models should be doom guy sprite (colored?)
// doors that monsters can open
// monsters should open doors, react to sounds without sight
// health/armor/ammo hud?
// probably need to limit sound graph per level
// lite textures need editing (full bar)
// eye button needs updating in dead simple
// You got the "X"! messages
// items don't get correct brightness
// items sometimes sink into ground and u cant pickup
// solid fireballs bounce off each other (tried SOLID_TOUCH already, projectiles kinda have to be solid)
// crushers should go past monsters or go up after a while
// use MOVETYPE_FOLLOW to reduce net usage (tried it but monsters flicker because sprite stops following when nodraw applied)
// (doom door breaks regular doors): 10:11 AM - Streamfaux: Yeah better be waiting. Also you should investigate this just in case. Putting a door with a targetname and a button targgeting it should be enough to test. And I meanfunc_door and func_button.
// being revived breaks weapons with mp_weapon_droprules 1

float g_level_time = 0;
int g_secrets = 0;
int g_kills = 0;
int g_item_gets = 0;
int g_total_secrets = 0;
int g_total_monsters = 0;
int g_total_items = 0;
int g_keys = 0;
int g_map_num = 1;
bool g_strict_keys = false; // if false, only color of key matters when opening door

CCVar@ g_dmgScale;

array<int> g_par_times = {30, 90, 120, 120, 90, 150, 120, 120, 270, 90, 210};
array<string> g_map_music = {
	"doom/running_from_evil.ogg",
	"doom/the_healer_stalks.ogg",
	"doom/countdown_to_death.ogg",
	"doom/between_levels.ogg",
	"doom/doom.ogg",
	"doom/in_the_dark.ogg",
	"doom/shawn_shotgun.ogg",
	"doom/taylor_blues.ogg",
	"doom/sandy_city.ogg",
	"doom/the_demons_dead.ogg",
	"doom/the_healer_stalks.ogg",
};
string g_inter_music = "doom/intermission.ogg";
string g_ep_music = "doom/episode.ogg";

Vector g_spawn_room_pos;

enum key_types
{
	KEY_BLUE = 1,
	KEY_YELLOW = 2,
	KEY_RED = 4,
	SKULL_BLUE = 8,
	SKULL_YELLOW = 16,
	SKULL_RED = 32,
}

class VisEnt
{
	bool visible;
	EHandle sprite;
	
	VisEnt() {}
	
	VisEnt(bool visible, EHandle sprite) 
	{
		this.visible = visible;
		this.sprite = sprite;
	}
}

class PlayerState
{
	EHandle plr;
	CTextMenu@ menu;
	dictionary visible_ents;
	float lastAttack; // time this player last attacked with a weapon (used to temporarily disable invisibility)
	float lastSuit = 0; // last time suit was picked up
	float lastGoggles = 0; // last time suit was picked up
	float lastGod = 0;
	float lastInvis = 0;
	float lastHudKeys = 0; // last time key hud was updated
	int hudKeys = 0; // last key set displayed
	int uiScale = 1;
	PlayerViewMode viewMode = ViewMode_FirstPerson;
	SoundNode@ soundNode = null;
	bool acceptedStrafeBug = false;
	
	
	void initMenu(CBasePlayer@ plr, TextMenuPlayerSlotCallback@ callback)
	{
		CTextMenu temp(@callback);
		@menu = @temp;
	}
	
	void openMenu(CBasePlayer@ plr, int time=60) 
	{
		if ( menu.Register() == false ) {
			g_Game.AlertMessage( at_console, "Oh dear menu registration failed\n");
		}
		menu.Open(time, 0, plr);
	}
	
	void addVisibleEnt(string entName, EHandle sprite)
	{
		sprite.GetEntity().pev.colormap += 1;
		visible_ents[entName] = VisEnt(true, sprite);
	}
	
	void hideVisibleEnt(string entName)
	{
		if (visible_ents.exists(entName))
		{
			VisEnt@ vent = cast<VisEnt@>( visible_ents[entName] );
			if (vent.sprite) {
				vent.sprite.GetEntity().pev.colormap -= 1;
			}
			visible_ents.delete(entName);
		}
	}
	
	bool isVisibleEnt(string entName)
	{
		return visible_ents.exists(entName);
	}
	
	float suitTimeLeft() { return lastSuit > 0 ? 60.0f - (g_Engine.time - lastSuit) : 0; }
	float goggleTimeLeft() { return lastGoggles > 0 ? 120.0f - (g_Engine.time - lastGoggles) : 0; }
	float godTimeLeft() { return lastGod > 0 ? 30.0f - (g_Engine.time - lastGod) : 0; }
	float invisTimeLeft() { return lastInvis > 0 ? 60.0f - (g_Engine.time - lastInvis) : 0; }
}

dictionary player_states;

array<string> sprite_angles = {
	"1", "2?8", "3?7", "4?6", "5", "6?4", "7?3", "8?2"
};

string beta_dir = "beta/";
string beta_dir2 = "/beta";

string fixPath(string asset)
{
	if (beta_dir.Length() > 0)
		return asset.Replace("doom/", "doom/" + beta_dir);
	return asset;
}

string PrecacheModel(string model)
{
	g_Game.PrecacheModel(fixPath(model));
	return fixPath(model);
}

string PrecacheGeneric(string thing)
{
	g_Game.PrecacheGeneric(fixPath(thing));
	return fixPath(thing);
}

string PrecacheSound(string sound)
{
	g_SoundSystem.PrecacheSound(fixPath(sound));
	PrecacheGeneric("sound/" + sound);
	return fixPath(sound);
}

string base36(int num)
{
	string b36;
	string charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	while (num != 0)
	{
		string c = charset[num % 36];
		b36 = c + b36;
		num /= 36; 
	}
	return b36;
}

void MapInit()
{
	@g_dmgScale = CCVar( "dmg_scale", 1, "Percentage of damage taken by players");
	
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_imp", "monster_imp" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombieman", "monster_zombieman" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_shotgunguy", "monster_shotgunguy" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_hwdude", "monster_hwdude" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_demon", "monster_demon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_cacodemon", "monster_cacodemon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_lostsoul", "monster_lostsoul" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_baron", "monster_baron" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_hellknight", "monster_hellknight" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_cyberdemon", "monster_cyberdemon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_spiderdemon", "monster_spiderdemon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_revenant", "monster_revenant" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_mancubus", "monster_mancubus" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_arachnotron", "monster_arachnotron" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_painelemental", "monster_painelemental" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_archvile", "monster_archvile" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "func_doom_door", "func_doom_door" );
	g_CustomEntityFuncs.RegisterCustomEntity( "func_doom_water", "func_doom_water" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_doom_teleport", "trigger_doom_teleport" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_barrel", "item_barrel" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_prop", "item_prop" );
	g_CustomEntityFuncs.RegisterCustomEntity( "info_node_sound", "info_node_sound" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_fist", "weapon_doom_fist" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_chainsaw", "weapon_doom_chainsaw" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_pistol", "weapon_doom_pistol" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_chaingun", "weapon_doom_chaingun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_shotgun", "weapon_doom_shotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_supershot", "weapon_doom_supershot" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_rpg", "weapon_doom_rpg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_plasmagun", "weapon_doom_plasmagun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_bfg", "weapon_doom_bfg" );
	g_ItemRegistry.RegisterWeapon( "weapon_doom_fist", "doom" + beta_dir2, "");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_chainsaw", "doom" + beta_dir2, "");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_pistol", "doom" + beta_dir2, "bullets", "", "ammo_doom_bullets");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_chaingun", "doom" + beta_dir2, "bullets", "", "ammo_doom_bullets");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_shotgun", "doom" + beta_dir2, "shells", "", "ammo_doom_shells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_supershot", "doom" + beta_dir2, "shells", "", "ammo_doom_shells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_rpg", "doom" + beta_dir2, "rockets", "", "ammo_doom_rocket");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_plasmagun", "doom" + beta_dir2, "cells", "", "ammo_doom_cells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_bfg", "doom" + beta_dir2, "cells", "", "ammo_doom_cells");
	
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_bullets", "ammo_doom_bullets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_bulletbox", "ammo_doom_bulletbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shells", "ammo_doom_shells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shellbox", "ammo_doom_shellbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_rocket", "ammo_doom_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_rocketbox", "ammo_doom_rocketbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_cells", "ammo_doom_cells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_cellbox", "ammo_doom_cellbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shotgun", "ammo_doom_shotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_chaingun", "ammo_doom_chaingun" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_stimpak", "item_doom_stimpak" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_medkit", "item_doom_medkit" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_potion", "item_doom_potion" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_armor_bonus", "item_doom_armor_bonus" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_armor", "item_doom_armor" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_megaarmor", "item_doom_megaarmor" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_megasphere", "item_doom_megasphere" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_soulsphere", "item_doom_soulsphere" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_god", "item_doom_god" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_berserk", "item_doom_berserk" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_invis", "item_doom_invis" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_suit", "item_doom_suit" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_goggles", "item_doom_goggles" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_backpack", "item_doom_backpack" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_red", "item_doom_key_red" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_blue", "item_doom_key_blue" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_yellow", "item_doom_key_yellow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_red", "item_doom_skull_red" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_blue", "item_doom_skull_blue" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_yellow", "item_doom_skull_yellow" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, @PlayerUse );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
		
	PrecacheModel("models/hlclassic/p_9mmhandgun.mdl");
	PrecacheModel("models/hlclassic/p_egon.mdl");
	PrecacheModel("models/hlclassic/p_gauss.mdl");
	PrecacheModel("models/hlclassic/p_rpg.mdl");
	PrecacheModel("models/hlclassic/p_shotgun.mdl");
	PrecacheModel("models/hlclassic/p_shotgun.mdl");
	PrecacheModel("models/custom_weapons/cs16/p_chainsaw.mdl");
	PrecacheModel("models/custom_weapons/cs16/p_m1887.mdl");
	
	PrecacheModel("sprites/doom/objects.spr");
	PrecacheModel("sprites/doom/keys.spr");
	PrecacheModel("sprites/doom/BAL.spr");
	PrecacheModel("sprites/doom/BAL7.spr");
	PrecacheModel("sprites/doom/MISL.spr");
	PrecacheModel("sprites/doom/BFE2.spr");
	PrecacheModel("sprites/doom/PUFF.spr");
	PrecacheModel("sprites/doom/BLUD.spr");
	PrecacheModel("sprites/doom/TFOG.spr");
	PrecacheModel("sprites/doom/FATB.spr");
	PrecacheModel("sprites/doom/MANF.spr");
	PrecacheModel("sprites/doom/FIRE.spr");
	PrecacheModel("models/doom/null.mdl");
	PrecacheModel("sprites/null.spr");
	
	PrecacheModel("sprites/doom/fist.spr");
	PrecacheModel("sprites/doom/chainsaw.spr");
	PrecacheModel("sprites/doom/pistol.spr");
	PrecacheModel("sprites/doom/chaingun.spr");
	PrecacheModel("sprites/doom/shotgun.spr");
	PrecacheModel("sprites/doom/supershot.spr");
	PrecacheModel("sprites/doom/rpg.spr");
	PrecacheModel("sprites/doom/plasmagun.spr");
	PrecacheModel("sprites/doom/bfg.spr");
	PrecacheModel("sprites/doom/TEXT.spr");
	
	PrecacheGeneric("sprites/doom/weapon_doom_fist.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_chainsaw.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_pistol.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_chaingun.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_shotgun.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_supershot.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_rpg.txt");
	PrecacheGeneric("sprites/doom/weapon_doom_bfg.txt");
	
	PrecacheSound("doom/DSFIRSHT.wav");
	PrecacheSound("doom/DSFIRXPL.wav");
	PrecacheSound("doom/DSRLAUNC.wav");
	PrecacheSound("doom/DSBAREXP.wav");
	PrecacheSound("doom/supershot.flac");
	PrecacheSound("doom/DSPUNCH.wav");
	PrecacheSound("doom/DSSAWUP.wav");
	PrecacheSound("doom/DSSAWIDL.wav");
	PrecacheSound("doom/DSSAWFUL.wav");
	PrecacheSound("doom/DSSAWHIT.wav");
	PrecacheSound("doom/DSPLASMA.wav");
	PrecacheSound("doom/DSSKEATK.wav");
	PrecacheSound("doom/DSRXPLOD.wav");
	PrecacheSound("doom/DSBFG.wav");
	PrecacheSound("doom/DSGETPOW.wav");
	PrecacheSound("doom/DSTELEPT.wav");
	PrecacheSound("doom/DSWPNUP.wav");
	PrecacheSound("doom/DSFLAME.wav");
	PrecacheSound("doom/DSSKLDTH.wav"); // player use
	PrecacheSound("doom/DSPLPAIN.wav"); // player pain
	PrecacheSound("doom/DSPLDETH.wav"); // player death
	PrecacheSound("doom/DSITMBK.wav"); // item respawn
	PrecacheSound("doom/DSITEMUP.wav"); // item collect
	PrecacheSound("doom/dssecret.flac"); // secret revealed
	
	for (uint i = 0; i < g_map_music.length(); i++)
		g_map_music[i] = PrecacheSound(g_map_music[i]);
		
	g_inter_music = PrecacheSound(g_inter_music);
	g_ep_music = PrecacheSound(g_ep_music);
}

void initSettings(EHandle h_plr)
{
	if (!h_plr.IsValid())
		return;
	CBasePlayer@ plr = cast<CBasePlayer@>(h_plr.GetEntity());
	
	PlayerState@ state = getPlayerState(plr);
	CustomKeyvalues@ customKeys = plr.GetCustomKeyvalues();
	if (customKeys.HasKeyvalue("uiscale"))
		state.uiScale = customKeys.GetKeyvalue("uiscale").GetInteger();
}

HookReturnCode ClientJoin( CBasePlayer@ plr )
{
	g_Scheduler.SetTimeout("initSettings", 0.05f, EHandle(plr));
	return HOOK_CONTINUE;
}

void MapActivate()
{
	array<CBaseEntity@> doors;
	array<CBaseEntity@> buttons;
	
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "func_doom_door");
		if (ent !is null)
		{
			func_doom_door@ door = cast<func_doom_door@>(CastToScriptClass(ent));
			if (door.isButton)
				buttons.insertLast(ent);
			else
				doors.insertLast(ent);
		}
	} while (ent !is null);
	
	@ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "env_sprite");
		if (ent !is null)
		{
			g_EntityFuncs.SetModel(ent, fixPath("sprites/doom/TEXT.spr"));
		}
	} while (ent !is null);
	
	for (uint i = 0; i < buttons.length(); i++)
	{
		for (uint k = 0; k < doors.length(); k++)
		{
			if (buttons[i].pev.spawnflags & FL_DOOR_BUTTON_DONT_MOVE == 0 and buttons[i].Intersects(doors[k]))
			{
				//println("GOT INTERSECT " + buttons[i].pev.targetname + " " + doors[k].pev.targetname);
				func_doom_door@ button = cast<func_doom_door@>(CastToScriptClass(buttons[i]));
				func_doom_door@ door = cast<func_doom_door@>(CastToScriptClass(doors[k]));
				button.dir = door.dir;
				button.m_flLip = door.m_flLip;
				button.pev.speed = door.pev.speed;
				button.m_vecPosition2 = button.pev.origin + Vector(0,0,(button.dir * (door.pev.size.z-2)) - button.dir*button.m_flLip);
				
				door.sync_buttons.insertLast(EHandle(buttons[i]));
				button.parent = ent;
			}
		}
	}
	
	CBaseEntity@ map_info = g_EntityFuncs.FindEntityByTargetname(null, "map_info");
	if (map_info !is null)
	{
		g_map_num += (map_info.pev.renderfx-1);
		println("INITIAL MAP: " + g_map_num);
	}
	
	CBaseEntity@ spawn_room = g_EntityFuncs.FindEntityByTargetname(null, "map_start");
	g_spawn_room_pos = spawn_room !is null ? spawn_room.pev.origin : Vector(0,0,0);
	
	dictionary keys;
	keys["origin"] = g_spawn_room_pos.ToString();
	keys["targetname"] = "secret_revealed";
	keys["m_iszScriptFile"] = "doom/doom.as";
	keys["m_iszScriptFunctionName"] = "secret_revealed";
	keys["m_iMode"] = "1";
	keys["delay"] = "0";
	g_EntityFuncs.CreateEntity("trigger_script", keys, true);
	

	keys["targetname"] = "inter_music";
	keys["volume"] = "10";
	keys["message"] = g_inter_music;
	keys["spawnflags"] = "3";
	g_EntityFuncs.CreateEntity("ambient_music", keys, true);
	
	keys["targetname"] = "ep_music";
	keys["volume"] = "10";
	keys["message"] = g_ep_music;
	keys["spawnflags"] = "3";
	g_EntityFuncs.CreateEntity("ambient_music", keys, true);
	
	createSoundGraph();
	
	g_Scheduler.SetTimeout("plugin_check", 2.0f);
}

void plugin_check()
{
	CBaseEntity@ ent = g_EntityFuncs.FindEntityByTargetname(null, "plugin_not_installed");
	if (ent !is null) {
		CBasePlayer@ anyPlr = getAnyPlayer();
		g_PlayerFuncs.SayTextAll(anyPlr, "Add doom_maps to default_plugins.txt to fix your installation.");
		g_PlayerFuncs.CenterPrintAll("Map installed incorrectly");
		g_PlayerFuncs.ShowMessageAll("Map installed incorrectly");
		g_Scheduler.SetTimeout("plugin_check", 2.0f);
	}
}

int getSpriteAngle(Vector spritePos, Vector spriteForward, Vector spriteRight, Vector lookPos)
{
	Vector delta = spritePos - lookPos;
	delta.z = 0;
	delta = delta.Normalize();
	
	float dot = DotProduct(spriteForward, delta);
	float dotR = DotProduct(spriteRight, delta);
	
	//println("DOTR: " + dotR);
	
	if (dot < -0.9f)
		return 0;
	else if (dot < -0.4f)
		return dotR > 0 ? 1 : 7;
	else if (dot < 0.4f)
		return dotR > 0 ? 2 : 6;
	else if (dot < 0.9f)
		return dotR > 0 ? 3 : 5;
		
	return 4;
}

HookReturnCode PlayerPostThink(CBasePlayer@ plr)
{
	PlayerState@ state = getPlayerState(plr);
	
	HUDSpriteParams params;
	string hud_sprite = fixPath("sprites/doom/keys.spr"); 
	params.spritename = hud_sprite.SubString("sprites/".Length()); // so resguy doesn't get confused
	params.width = 0;
	params.flags = HUD_SPR_MASKED | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_ABSOLUTE_X;
	params.holdTime = 99999.0f;
	params.color1 = RGBA( 255, 255, 255, 255 );

	float sprScale = g_spr_scales[state.uiScale];
	int sprHeight = int(sprScale*6);
	float baseX = -sprScale*5*2;
	float baseY = 50;
	params.x = baseX;
	params.y = baseY;
	
	if (state.lastHudKeys + 10.0f < g_Engine.time or state.hudKeys != g_keys)
	{
		state.lastHudKeys = g_Engine.time;
		state.hudKeys = g_keys;
		for (uint i = 0; i < 6; i++)
		{
			params.channel = 9+i;
			params.frame = state.uiScale*6 + i;
			if (i == 3) // skull keys
			{
				params.y = baseY - sprScale*2;
				params.x = baseX + sprScale*9;
			}

			if (g_keys & (1 << i) == 0)
			{
				HUDSpriteParams offparams;
				offparams.channel = params.channel;
				g_PlayerFuncs.HudCustomSprite(plr, offparams);
				continue;
			}
			
			g_PlayerFuncs.HudCustomSprite(plr, params);
			
			params.y += sprScale*2 + sprHeight;
		}
	}
	
	//g_SoundSystem.StopSound(ent.edict(), CHAN_BODY, "player/pl_step3.wav");
	//g_SoundSystem.StopSound(ent.edict(), CHAN_BODY, "player/pl_step6.wav");
	
	//g_PlayerFuncs.HudToggleElement(plr, tile, false);
	
	//ent.pev.view_ofs.z = 20; // original == 28
	//ent.pev.scale = 0.7f;
	//ent.pev.fuser4 = 2;
	//println("HEIGHT: " + (ent.pev.origin.z + ent.pev.view_ofs.z) + " " + ent.pev.view_ofs.z);
	return HOOK_CONTINUE;
}

void player_killed(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if (!pCaller.IsPlayer())
		return;
	CBasePlayer@ plr = cast<CBasePlayer@>(pCaller);
	PlayerState@ state = getPlayerState(plr);
	state.lastSuit = state.lastGoggles = state.lastGod = state.lastInvis = 0;
}

void secret_revealed(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	g_SoundSystem.PlaySound(pActivator.edict(), CHAN_STATIC, fixPath("doom/dssecret.flac"), 1.0f, ATTN_NONE, 0, 100);
	g_PlayerFuncs.PrintKeyBindingStringAll("A SECRET IS REVEALED!\n");
	g_secrets += 1;
}

string getMapName()
{
	if (g_map_num < 10)
		return "map0" + g_map_num;
	return "map" + g_map_num;
}

void level_started(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	g_level_time = g_Engine.time;
	
	g_secrets = 0;
	g_kills = 0;
	g_item_gets = 0;
	g_total_secrets = 0;
	g_total_monsters = 0;
	g_total_items = 0;
	
	Vector level_min = g_EntityFuncs.FindEntityByTargetname(null, getMapName() + "_mins").pev.origin;
	Vector level_max = g_EntityFuncs.FindEntityByTargetname(null, getMapName() + "_maxs").pev.origin;
	
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "*");
		if (ent !is null)
		{
			if (ent.pev.absmin.x > level_min.x and ent.pev.absmin.y > level_min.y and ent.pev.absmin.z > level_min.z and
				ent.pev.absmax.x < level_max.x and ent.pev.absmax.y < level_max.y and ent.pev.absmax.z < level_max.z)
			{
				if (string(ent.pev.targetname).StartsWith("strobe"))
					continue; // HACK: fixes strobe arrows in tunnels
					
				// add prefix to entity names so multiple levels don't conflict
				string prefix = getMapName() + "_";
				if (string(ent.pev.targetname).Length() > 0)
					ent.pev.targetname = prefix + ent.pev.targetname;
				if (string(ent.pev.target).Length() > 0 and ent.pev.target != "secret_revealed" and ent.pev.target != "teleport_thing" and ent.pev.target != "exit_level")
					ent.pev.target = prefix + ent.pev.target;
				if (ent.pev.target == "teleport_thing")
					ent.pev.netname = prefix + ent.pev.netname;
					
				if (ent.pev.classname == "trigger_changevalue")
					ent.pev.message = prefix + ent.pev.message;
				
				if (ent.pev.classname == "trigger_once" and ent.pev.target == "secret_revealed")
					g_total_secrets += 1;
				
				if (string(ent.pev.classname).Find("monster_") == 0)
				{
					monster_doom@ mon = cast<monster_doom@>(CastToScriptClass(ent));
					CBaseMonster@ bmon = cast<CBaseMonster@>(ent);
					if (bmon !is null)
						bmon.m_iszTriggerTarget = prefix + bmon.m_iszTriggerTarget;
					if (mon !is null)
						mon.Setup();
					g_total_monsters += 1;
				}
					
				if (string(ent.pev.classname).Find("item_doom_") == 0)
				{
					item_doom@ item = cast<item_doom@>(CastToScriptClass(ent));
					if (item.intermission)
						g_total_items += 1;
				}
			}
		}
	} while(ent !is null);
	
	
	dictionary keys;
	keys["origin"] = g_spawn_room_pos.ToString();
	keys["targetname"] = "" + getMapName() + "_music";
	keys["volume"] = "10";
	keys["message"] = "" + g_map_music[g_map_num-1];
	keys["spawnflags"] = "3";
	g_EntityFuncs.CreateEntity("ambient_music", keys, true);
	
	g_EntityFuncs.FireTargets(getMapName() + "_spawns", null, null, USE_ON);
	g_EntityFuncs.FireTargets(getMapName() + "_music", null, null, USE_ON);
}

void episode_end()
{
	CBaseEntity@ trans = g_EntityFuncs.FindEntityByTargetname(null, "inter_fin_spr");
	CBaseEntity@ lvl = g_EntityFuncs.FindEntityByTargetname(null, "inter_lvl_spr");
	trans.pev.effects |= EF_NODRAW;
	lvl.pev.effects |= EF_NODRAW;
	g_EntityFuncs.FireTargets("ep_end", null, null, USE_TOGGLE);
}

void trigger_next_level()
{
	g_EntityFuncs.FireTargets("map_start", null, null, USE_TOGGLE);
}

void next_level()
{
	array<string> sprItems = {"kills", "items", "secret", "time", "par"};
	for (uint i = 0; i < sprItems.length(); i++)
	{
		CBaseEntity@ label = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + sprItems[i] + "_spr");
		if (label !is null)
			label.pev.effects |= EF_NODRAW;
		for (uint k = 0; k < 5; k++)
		{
			CBaseEntity@ spr = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + sprItems[i] + "_spr" + k);
			if (spr !is null)
				spr.pev.effects |= EF_NODRAW;
		}
	}
	
	CBaseEntity@ trans = g_EntityFuncs.FindEntityByTargetname(null, "inter_fin_spr");
	CBaseEntity@ lvl = g_EntityFuncs.FindEntityByTargetname(null, "inter_lvl_spr");
	
	Vector temp = trans.pev.origin;
	trans.pev.origin = lvl.pev.origin;
	lvl.pev.origin = temp;
	
	trans.pev.frame = 52;
	lvl.pev.frame += 1;
	
	g_EntityFuncs.FireTargets("next_level", null, null, USE_TOGGLE);
	
	g_map_num++;
	
	if (g_map_num == 7)
	{
		g_Scheduler.SetTimeout("episode_end", 1.0f);
	}
	else
		g_Scheduler.SetTimeout("trigger_next_level", 3.0f);
}

void tally_time(string item, int time, int targetTime, bool playSound)
{
	if (time > targetTime)
		time = targetTime;
		
	CBaseEntity@ minTens = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr0");
	CBaseEntity@ minOnes = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr1");
	CBaseEntity@ colon = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr2");
	CBaseEntity@ secTens = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr3");
	CBaseEntity@ secOnes = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr4");
	
	int numFrameStart = 57;
	
	colon.pev.effects &= ~EF_NODRAW;
	secOnes.pev.effects &= ~EF_NODRAW;
	secTens.pev.effects &= ~EF_NODRAW;
	minOnes.pev.effects &= ~EF_NODRAW;
	
	if (time >= 60*10)
		minTens.pev.effects &= ~EF_NODRAW;
	
	// don't loop around
	int showTime = time;
	if (showTime > 60*99 + 59)
		showTime = 60*99 + 59;
	
	colon.pev.frame = 51;
	secOnes.pev.frame = numFrameStart + ((showTime % 60) % 10);
	secTens.pev.frame = numFrameStart + (((showTime % 60) / 10) % 10);
	minOnes.pev.frame = numFrameStart + ((showTime / 60) % 10);
	minTens.pev.frame = numFrameStart + (((showTime / 60) / 10) % 10);
	
	if (time < targetTime)
	{
		if (playSound)
			g_SoundSystem.PlaySound(colon.edict(), CHAN_STATIC, fixPath("doom/DSPISTOL.wav"), 1.0f, 1.0f, 0, 100);
		int step = Math.max(targetTime / 15, 3);
		g_Scheduler.SetTimeout("tally_time", 0.05, item, time+step, targetTime, !playSound);
	}
	else
	{
		g_SoundSystem.PlaySound(secOnes.edict(), CHAN_STATIC, fixPath("doom/DSBAREXP.wav"), 1.0f, 1.0f, 0, 100);
		if (item == "time")
			g_Scheduler.SetTimeout("tally_time", 0.8, "par", 0, g_par_times[g_map_num-1], !playSound);
		if (item == "par")
			g_Scheduler.SetTimeout("next_level", 4.0);
	}
}

void tally_score(string item, int percentage, int targetPercent, bool playSound)
{
	if (percentage > targetPercent)
		percentage = targetPercent;
		
	CBaseEntity@ hundreds = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr0");
	CBaseEntity@ tens = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr1");
	CBaseEntity@ ones = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr2");
	CBaseEntity@ percent = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + item + "_spr3");
	
	int numFrameStart = 40;
	
	percent.pev.effects &= ~EF_NODRAW;
	
	ones.pev.effects &= ~EF_NODRAW;
	if (percentage >= 10)
		tens.pev.effects &= ~EF_NODRAW;
	if (percentage >= 100)
		hundreds.pev.effects &= ~EF_NODRAW;
		
	percent.pev.frame = 50;
	hundreds.pev.frame = numFrameStart + ((percentage/100) % 10);
	tens.pev.frame = numFrameStart + ((percentage/10) % 10);
	ones.pev.frame = numFrameStart + (percentage % 10);
	
	if (percentage < targetPercent)
	{
		if (playSound)
			g_SoundSystem.PlaySound(ones.edict(), CHAN_STATIC, fixPath("doom/DSPISTOL.wav"), 1.0f, 1.0f, 0, 100);
		g_Scheduler.SetTimeout("tally_score", 0.05, item, percentage+13, targetPercent, !playSound);
	}
	else
	{
		g_SoundSystem.PlaySound(tens.edict(), CHAN_STATIC, fixPath("doom/DSBAREXP.wav"), 1.0f, 1.0f, 0, 100);
		
		if (item == "kills")
		{
			int itemPercentage = 100;
			if (g_total_items > 0)
				itemPercentage = int((g_item_gets / float(g_total_items))*100);
			g_Scheduler.SetTimeout("tally_score", 0.8f, "items", 0, itemPercentage, true);
		}
		if (item == "items")
		{
			int secretPercent = 100;
			if (g_total_secrets > 0)
				secretPercent = int((g_secrets / float(g_total_secrets))*100);
			g_Scheduler.SetTimeout("tally_score", 0.8f, "secret", 0, secretPercent, true);
		}
		if (item == "secret")
			g_Scheduler.SetTimeout("tally_time", 0.8, "time", 0, int(g_level_time), !playSound);
	}
}

void cleanup_level()
{
	Vector level_min = g_EntityFuncs.FindEntityByTargetname(null, getMapName() + "_mins").pev.origin;
	Vector level_max = g_EntityFuncs.FindEntityByTargetname(null, getMapName() + "_maxs").pev.origin;
	
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "*");
		if (ent !is null)
		{
			if (ent.pev.absmin.x > level_min.x and ent.pev.absmin.y > level_min.y and ent.pev.absmin.z > level_min.z and
				ent.pev.absmax.x < level_max.x and ent.pev.absmax.y < level_max.y and ent.pev.absmax.z < level_max.z)
			{
				g_EntityFuncs.Remove(ent);
			}
		}
	} while(ent !is null);
	
	g_keys = 0;
}

void intermission(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	g_EntityFuncs.FireTargets(getMapName() + "_spawns", null, null, USE_OFF);
	g_EntityFuncs.FireTargets(getMapName() + "_music", null, null, USE_OFF);
	
	g_Scheduler.SetTimeout("cleanup_level", 1.0f);
	
	CBaseEntity@ trans = g_EntityFuncs.FindEntityByTargetname(null, "inter_fin_spr");
	CBaseEntity@ lvl = g_EntityFuncs.FindEntityByTargetname(null, "inter_lvl_spr");
	trans.pev.effects &= ~EF_NODRAW;
	lvl.pev.effects &= ~EF_NODRAW;
	
	Vector temp = trans.pev.origin;
	trans.pev.origin = lvl.pev.origin;
	lvl.pev.origin = temp;
	lvl.pev.frame = g_map_num-1;
	trans.pev.frame = 53;
	
	array<string> sprItems = {"kills", "items", "secret", "time", "par"};
	for (uint i = 0; i < sprItems.length(); i++)
	{
		CBaseEntity@ label = g_EntityFuncs.FindEntityByTargetname(null, "inter_" + sprItems[i] + "_spr");
		if (label !is null)
			label.pev.effects &= ~EF_NODRAW;
	}
	
	g_level_time = g_Engine.time - g_level_time;
	
	int killPercent = 100;
	if (g_total_monsters > 0)
		killPercent = int((g_kills / float(g_total_monsters))*100);	
	
	g_Scheduler.SetTimeout("tally_score", 1.5f, "kills", 0, killPercent, true);
	//tally_time("time", 0, 60*8 + 26, true);
}

void ep_scroll_line(int lineNum, int stepsTaken, int maxStep)
{
	CBaseEntity@ scroll = g_EntityFuncs.FindEntityByTargetname(null, "ep_scroll" + lineNum);
	if (scroll is null)
		return;
	scroll.pev.origin.x += 0.1f;
	
	if (stepsTaken < maxStep)
	{
		g_Scheduler.SetTimeout("ep_scroll_line", 0.05f, lineNum, stepsTaken+1, 50);
	}
	else
	{
		g_Scheduler.SetTimeout("ep_scroll_line", 0, lineNum+1, 0, 50);
	}
}

void ep_text(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{	
	g_Scheduler.SetTimeout("ep_scroll_line", 0.0f, 1, 0, 10);
}


HookReturnCode PlayerUse( CBasePlayer@ plr, uint& out )
{	
	if (plr.m_afButtonPressed & IN_USE != 0)
	{
		TraceResult tr = TraceLook(plr, 90);
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		/*
		CBaseEntity@ ent = null;
		do {
			@ent = g_EntityFuncs.FindEntityByClassname(ent, "func_doom_door");
			if (ent !is null)
			{
				func_doom_door@ door = cast<func_doom_door@>(CastToScriptClass(ent));
				if (!door.isButton)
					continue;
				
				Vector p = tr.vecEndPos;
				if (p.x > door.pev.absmin.x and p.x < door.pev.absmax.x and
					p.y > door.pev.absmin.y and p.y < door.pev.absmax.y and 
					p.z > door.pev.absmin.z and p.z < door.pev.absmax.z)
				{
					println("LE DOOM DOOR");
					ent.Use(plr, plr, USE_TOGGLE);
				}
			}
		} while (ent !is null);
		*/
		phit.Use(plr, plr, USE_TOGGLE);
	}
	return HOOK_CONTINUE;
}

void doTheStatic(CBaseEntity@ ent)
{
	//g_EngineFuncs.MakeStatic(ent.edict());
}

void doEffect(CBasePlayer@ plr)
{
	CBaseEntity@ ent = null;
	int numMonsters = 0;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "*");
		if (ent !is null)
		{
			if (string(ent.pev.classname).Find("monster_") == 0)
			{
				monster_doom@ mon = cast<monster_doom@>(CastToScriptClass(ent));
				if (mon !is null)
				{
					mon.Setup();
					numMonsters++;
				}
			}
		}
	} while(ent !is null);
	
	println("Setup " + numMonsters + " monsters");
}

void playerMenuCallback(CTextMenu@ menu, CBasePlayer@ plr, int page, const CTextMenuItem@ item)
{
	if (item is null)
		return;
	string action;
	item.m_pUserData.retrieve(action);
	PlayerState@ state = getPlayerState(plr);
	
	if (action == "scale-tiny")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("HUD Scale:\n\nTINY\n");
		state.uiScale = 3;
	}
	if (action == "scale-small")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("HUD Scale:\n\nSMALL\n");
		state.uiScale = 2;
	}
	if (action == "scale-large")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("HUD Scale:\n\nLARGE\n");
		state.uiScale = 1;
	}
	if (action == "scale-xl")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("HUD Scale:\n\nX-LARGE\n");
		state.uiScale = 0;
	}
	
	CustomKeyvalues@ customKeys = plr.GetCustomKeyvalues();
	customKeys.SetKeyvalue("uiscale", state.uiScale);
	
	g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr);
	menu.Unregister();
	@menu = null;
}

void openPlayerMenu(CBasePlayer@ plr)
{
	PlayerState@ state = getPlayerState(plr);
	state.initMenu(plr, playerMenuCallback);

	state.menu.SetTitle("HUD Scale:\n");
	state.menu.AddItem("Tiny       (for resolutions near 800x600)", any("scale-tiny"));
	state.menu.AddItem("Small     (for resolutions near 1024x768)", any("scale-small"));
	state.menu.AddItem("Large     (for resolutions near 1920x1080)", any("scale-large"));
	state.menu.AddItem("X-Large  (for resolutions near 2560x1440)", any("scale-xl"));
	
	state.openMenu(plr);
}

bool doDoomCommand(CBasePlayer@ plr, const CCommand@ args)
{	
	if ( args.ArgC() > 0 )
	{
		if (args[0] == ".test")
		{
			//g_Scheduler.SetInterval("doEffect", 0.025, -1, @plr);
			doEffect(plr);
			return true;
		}
		if (args[0] == ".options")
		{
			openPlayerMenu(plr);
			return true;
		}
		if (args[0] == "idkfa")
		{
			g_keys = 0xff;
			
			plr.GiveNamedItem("weapon_doom_fist", 0, 0);
			plr.GiveNamedItem("weapon_doom_chainsaw", 0, 0);
			plr.GiveNamedItem("weapon_doom_pistol", 0, 0);
			plr.GiveNamedItem("weapon_doom_chaingun", 0, 0);
			plr.GiveNamedItem("weapon_doom_shotgun", 0, 0);
			plr.GiveNamedItem("weapon_doom_supershot", 0, 0);
			plr.GiveNamedItem("weapon_doom_rpg", 0, 0);
			plr.GiveNamedItem("weapon_doom_plasmagun", 0, 0);
			plr.GiveNamedItem("weapon_doom_bfg", 0, 0);
			plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("cells"), 1000000);
			plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bullets"), 1000000);
			plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("shells"), 1000000);
			plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"), 1000000);
			return true;
		}
	}
	return false;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ plr = pParams.GetPlayer();
	const CCommand@ args = pParams.GetArguments();	
	if (doDoomCommand(plr, args))
	{
		pParams.ShouldHide = true;
		return HOOK_HANDLED;
	}
	return HOOK_CONTINUE;
}
