#include "weapons"
#include "monsters"
#include "items"
#include "utils"
#include "func_doom_door"
#include "func_doom_water"

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
	
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, @PlayerUse );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientJoin );
		
	g_Game.PrecacheModel("sprites/doom/objects.spr");
	g_Game.PrecacheModel("sprites/doom/BAL.spr");
	g_Game.PrecacheModel("sprites/doom/BAL7.spr");
	g_Game.PrecacheModel("sprites/doom/MISL.spr");
	g_Game.PrecacheModel("sprites/doom/BFE2.spr");
	g_Game.PrecacheModel("sprites/doom/PUFF.spr");
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
	PrecacheSound("doom/DSITMBK.wav"); // item respawn
	PrecacheSound("doom/DSITEMUP.wav"); // item collect
	
	g_Scheduler.SetInterval("heightCheck", 0.0);
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
				println("GOT INTERSECT " + buttons[i].pev.targetname + " " + doors[k].pev.targetname);
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
	//plr.RemoveAllItems(false);
	//animateDoomWeapon(plr);
}

bool doDoomCommand(CBasePlayer@ plr, const CCommand@ args)
{	
	if ( args.ArgC() > 0 )
	{
		if (args[0] == ".test")
		{
			//g_Scheduler.SetInterval("doEffect", 0.025, -1, @plr);
			//doEffect();
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
