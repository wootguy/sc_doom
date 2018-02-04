#include "weapons"
#include "monsters"
#include "items"
#include "utils"
#include "func_doom_door"
#include "func_doom_water"

// TODO:
// monsters should open doors, react to sounds without sight
// items don't get correct brightness
// player models should be doom guy sprite (colored?)
// rocket trails
// hitboxes aren't quite right
// rewrite takedamage+traceattack :<
// health/armor/ammo hud?
// weapon picksound is shotgun?

float g_level_time = 0;
int g_secrets = 0;
int g_kills = 0;
int g_item_gets = 0;
int g_total_secrets = 0;
int g_total_monsters = 0;
int g_total_items = 0;
int g_keys = 0;

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
	int uiScale = 1;
	
	
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
			vent.sprite.GetEntity().pev.colormap -= 1;
			visible_ents.delete(entName);
		}
	}
	
	bool isVisibleEnt(string entName)
	{
		return visible_ents.exists(entName);
	}
	
	float suitTimeLeft() { return 60.0f - (g_Engine.time - lastSuit); }
	float goggleTimeLeft() { return 120.0f - (g_Engine.time - lastGoggles); }
	float godTimeLeft() { return 30.0f - (g_Engine.time - lastGod); }
	float invisTimeLeft() { return 60.0f - (g_Engine.time - lastInvis); }
}

dictionary player_states;

array<string> sprite_angles = {
	"1", "2?8", "3?7", "4?6", "5", "6?4", "7?3", "8?2"
};

void PrecacheSound(string sound)
{
	g_SoundSystem.PrecacheSound(sound);
	g_Game.PrecacheGeneric("sound/" + sound);
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
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_imp", "monster_imp" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombieman", "monster_zombieman" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_shotgunguy", "monster_shotgunguy" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_demon", "monster_demon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_cacodemon", "monster_cacodemon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_lostsoul", "monster_lostsoul" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_baron", "monster_baron" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_cyberdemon", "monster_cyberdemon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_spiderdemon", "monster_spiderdemon" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "func_doom_door", "func_doom_door" );
	g_CustomEntityFuncs.RegisterCustomEntity( "func_doom_water", "func_doom_water" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_barrel", "item_barrel" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_fist", "weapon_doom_fist" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_chainsaw", "weapon_doom_chainsaw" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_pistol", "weapon_doom_pistol" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_chaingun", "weapon_doom_chaingun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_shotgun", "weapon_doom_shotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_supershot", "weapon_doom_supershot" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_rpg", "weapon_doom_rpg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_plasmagun", "weapon_doom_plasmagun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_doom_bfg", "weapon_doom_bfg" );
	g_ItemRegistry.RegisterWeapon( "weapon_doom_fist", "doom", "");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_chainsaw", "doom", "");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_pistol", "doom", "bullets", "", "ammo_doom_bullets");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_chaingun", "doom", "bullets", "", "ammo_doom_bullets");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_shotgun", "doom", "shells", "", "ammo_doom_shells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_supershot", "doom", "shells", "", "ammo_doom_shells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_rpg", "doom", "rockets", "", "ammo_doom_rocket");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_plasmagun", "doom", "cells", "", "ammo_doom_cells");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_bfg", "doom", "cells", "", "ammo_doom_cells");
	
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_bullets", "ammo_doom_bullets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_bulletbox", "ammo_doom_bulletbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shells", "ammo_doom_shells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shellbox", "ammo_doom_shellbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_rocket", "ammo_doom_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_rocketbox", "ammo_doom_rocketbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_cells", "ammo_doom_cells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_cellbox", "ammo_doom_cellbox" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_doom_shotgun", "ammo_doom_shotgun" );
	
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
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_red", "item_doom_key_red" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_blue", "item_doom_key_blue" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_key_yellow", "item_doom_key_yellow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_red", "item_doom_skull_red" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_blue", "item_doom_skull_blue" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_doom_skull_yellow", "item_doom_skull_yellow" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, @PlayerUse );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
		
	g_Game.PrecacheModel("sprites/doom/objects.spr");
	g_Game.PrecacheModel("sprites/doom/keys.spr");
	g_Game.PrecacheModel("sprites/doom/BAL.spr");
	g_Game.PrecacheModel("sprites/doom/BAL7.spr");
	g_Game.PrecacheModel("sprites/doom/MISL.spr");
	g_Game.PrecacheModel("sprites/doom/BFE2.spr");
	g_Game.PrecacheModel("sprites/doom/PUFF.spr");
	g_Game.PrecacheModel("sprites/doom/BLUD.spr");
	g_Game.PrecacheModel("sprites/doom/TFOG.spr");
	g_Game.PrecacheModel("models/doom/null.mdl");
	
	g_Game.PrecacheModel("sprites/doom/fist.spr");
	g_Game.PrecacheModel("sprites/doom/chainsaw.spr");
	g_Game.PrecacheModel("sprites/doom/pistol.spr");
	g_Game.PrecacheModel("sprites/doom/chaingun.spr");
	g_Game.PrecacheModel("sprites/doom/shotgun.spr");
	g_Game.PrecacheModel("sprites/doom/supershot.spr");
	g_Game.PrecacheModel("sprites/doom/rpg.spr");
	g_Game.PrecacheModel("sprites/doom/plasmagun.spr");
	g_Game.PrecacheModel("sprites/doom/bfg.spr");
	
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_fist.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_chainsaw.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_pistol.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_chaingun.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_shotgun.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_supershot.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_rpg.txt");
	g_Game.PrecacheGeneric("sprites/doom/weapon_doom_bfg.txt");
	
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
	PrecacheSound("doom/DSRXPLOD.wav");
	PrecacheSound("doom/DSBFG.wav");
	PrecacheSound("doom/DSGETPOW.wav");
	PrecacheSound("doom/DSTELEPT.wav");
	PrecacheSound("doom/DSSKLDTH.wav"); // player use
	PrecacheSound("doom/DSPLPAIN.wav"); // player pain
	PrecacheSound("doom/DSPLDETH.wav"); // player death
	PrecacheSound("doom/DSITMBK.wav"); // item respawn
	PrecacheSound("doom/DSITEMUP.wav"); // item collect
	PrecacheSound("doom/dssecret.flac"); // secret revealed
	
	g_Scheduler.SetInterval("heightCheck", 0.0);
	
	dictionary keys;
	keys["origin"] = Vector(0,0,0).ToString();
	keys["targetname"] = "secret_revealed";
	keys["m_iszScriptFile"] = "doom/doom.as";
	keys["m_iszScriptFunctionName"] = "secret_revealed";
	keys["m_iMode"] = "1";
	keys["delay"] = "0";
	g_EntityFuncs.CreateEntity("trigger_script", keys, true);
	
	keys["targetname"] = "teleport_thing";
	keys["m_iszScriptFunctionName"] = "teleport_thing";
	g_EntityFuncs.CreateEntity("trigger_script", keys, true);
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
	
	for (uint i = 0; i < buttons.length(); i++)
	{
		for (uint k = 0; k < doors.length(); k++)
		{
			if (buttons[i].Intersects(doors[k]))
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

void heightCheck()
{
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "player");
		if (ent !is null)
		{
			CBasePlayer@ plr = cast<CBasePlayer@>(ent);
			PlayerState@ state = getPlayerState(plr);
			
			HUDSpriteParams params;
			string hud_sprite = "sprites/doom/keys.spr"; 
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
					continue;
				
				g_PlayerFuncs.HudCustomSprite(plr, params);
				
				params.y += sprScale*2 + sprHeight;
			}
			
			//g_SoundSystem.StopSound(ent.edict(), CHAN_BODY, "player/pl_step3.wav");
			//g_SoundSystem.StopSound(ent.edict(), CHAN_BODY, "player/pl_step6.wav");
			
			//g_PlayerFuncs.HudToggleElement(plr, tile, false);
			
			//ent.pev.view_ofs.z = 20; // original == 28
			//ent.pev.scale = 0.7f;
			//ent.pev.fuser4 = 2;
			//println("HEIGHT: " + (ent.pev.origin.z + ent.pev.view_ofs.z) + " " + ent.pev.view_ofs.z);
		}
	} while (ent !is null);
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
	g_SoundSystem.PlaySound(pActivator.edict(), CHAN_STATIC, "doom/dssecret.flac", 1.0f, ATTN_NONE, 0, 100);
	g_PlayerFuncs.PrintKeyBindingStringAll("A SECRET IS REVEALED!\n");
	g_secrets += 1;
}

void teleport_thing(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	CBaseEntity@ target = g_EntityFuncs.FindEntityByTargetname(null, pCaller.pev.netname);
	if (target !is null)
	{
		
		Vector offset = pActivator.IsPlayer() ? Vector(0,0,36) : Vector(0,0,0);
		te_explosion(pActivator.pev.origin - offset, "sprites/doom/TFOG.spr", 10, 5, 15);
		g_EntityFuncs.SetOrigin(pActivator, target.pev.origin + offset);
		
		g_EngineFuncs.MakeVectors(target.pev.angles);
		te_explosion(pActivator.pev.origin - offset + g_Engine.v_forward*32, "sprites/doom/TFOG.spr", 10, 5, 15);
		
		g_SoundSystem.PlaySound(pCaller.edict(), CHAN_STATIC, "doom/DSTELEPT.wav", 1.0f, 1.0f, 0, 100);
		g_SoundSystem.PlaySound(target.edict(), CHAN_STATIC, "doom/DSTELEPT.wav", 1.0f, 1.0f, 0, 100);
		
		pActivator.pev.velocity = Vector(0,0,0);
		pActivator.pev.angles = target.pev.angles;
		pActivator.pev.v_angle = target.pev.angles;
		pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
	}
	else
		println("Bad teleport destination: " + pCaller.pev.netname);
}

void level_started(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	g_level_time = g_Engine.time;
	g_secrets = 0;
	
	Vector level_min = g_EntityFuncs.FindEntityByTargetname(null, "map01_mins").pev.origin;
	Vector level_max = g_EntityFuncs.FindEntityByTargetname(null, "map01_maxs").pev.origin;
	
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "*");
		if (ent !is null)
		{
			if (ent.pev.absmin.x > level_min.x and ent.pev.absmin.y > level_min.y and ent.pev.absmin.z > level_min.z and
				ent.pev.absmax.x < level_max.x and ent.pev.absmax.y < level_max.y and ent.pev.absmax.z < level_max.z)
			{
				if (ent.pev.classname == "trigger_once" and ent.pev.target == "secret_revealed")
					g_total_secrets += 1;
				
				if (string(ent.pev.classname).Find("monster_") == 0)
					g_total_monsters += 1;
					
				if (string(ent.pev.classname).Find("item_doom_") == 0)
				{
					item_doom@ item = cast<item_doom@>(CastToScriptClass(ent));
					if (item.intermission)
						g_total_items += 1;
				}
			}
		}
	} while(ent !is null);
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
			g_SoundSystem.PlaySound(colon.edict(), CHAN_STATIC, "doom/DSPISTOL.wav", 1.0f, 1.0f, 0, 100);
		int step = Math.max(targetTime / 15, 3);
		g_Scheduler.SetTimeout("tally_time", 0.05, item, time+step, targetTime, !playSound);
	}
	else
	{
		g_SoundSystem.PlaySound(secOnes.edict(), CHAN_STATIC, "doom/DSBAREXP.wav", 1.0f, 1.0f, 0, 100);
		if (item == "time")
			g_Scheduler.SetTimeout("tally_time", 0.8, "par", 0, 30, !playSound);
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
			g_SoundSystem.PlaySound(ones.edict(), CHAN_STATIC, "doom/DSPISTOL.wav", 1.0f, 1.0f, 0, 100);
		g_Scheduler.SetTimeout("tally_score", 0.05, item, percentage+13, targetPercent, !playSound);
	}
	else
	{
		g_SoundSystem.PlaySound(tens.edict(), CHAN_STATIC, "doom/DSBAREXP.wav", 1.0f, 1.0f, 0, 100);
		
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

void intermission(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	CBaseEntity@ trans = g_EntityFuncs.FindEntityByTargetname(null, "inter_fin_spr");
	CBaseEntity@ lvl = g_EntityFuncs.FindEntityByTargetname(null, "inter_lvl_spr");
	trans.pev.effects &= ~EF_NODRAW;
	lvl.pev.effects &= ~EF_NODRAW;
	
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

void clientCommand(CBaseEntity@ plr, string cmd)
{
	NetworkMessage m(MSG_ONE, NetworkMessages::NetworkMessageType(9), plr.edict());
		m.WriteString(cmd);
	m.End();
}

HookReturnCode ClientJoin( CBasePlayer@ plr )
{
	clientCommand(plr, "cl_forwardspeed 9000;cl_sidespeed 9000;cl_backspeed 9000");
	return HOOK_CONTINUE;
}

void doTheStatic(CBaseEntity@ ent)
{
	//g_EngineFuncs.MakeStatic(ent.edict());
}

void doEffect(CBasePlayer@ plr)
{

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
		g_PlayerFuncs.PrintKeyBindingStringAll("UI Scale:\n\nTINY\n");
		state.uiScale = 3;
	}
	if (action == "scale-small")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("UI Scale:\n\nSMALL\n");
		state.uiScale = 2;
	}
	if (action == "scale-large")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("UI Scale:\n\nLARGE\n");
		state.uiScale = 1;
	}
	if (action == "scale-xl")
	{
		g_PlayerFuncs.PrintKeyBindingStringAll("UI Scale:\n\nX-LARGE\n");
		state.uiScale = 0;
	}
	
	g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr);
	menu.Unregister();
	@menu = null;
}

void openPlayerMenu(CBasePlayer@ plr)
{
	PlayerState@ state = getPlayerState(plr);
	state.initMenu(plr, playerMenuCallback);

	state.menu.SetTitle("UI Scale:\n");
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
