#include "weapons"
#include "monsters"
#include "utils"
#include "func_doom_door"

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
	g_ItemRegistry.RegisterWeapon( "weapon_doom_pistol", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_chaingun", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_shotgun", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_supershot", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_rpg", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_plasmagun", "doom", "556");
	g_ItemRegistry.RegisterWeapon( "weapon_doom_bfg", "doom", "556");
	
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, @PlayerUse );
		
	g_Game.PrecacheModel("sprites/doom/BAL.spr");
	g_Game.PrecacheModel("sprites/doom/BAL7.spr");
	g_Game.PrecacheModel("sprites/doom/MISL.spr");
	g_Game.PrecacheModel("sprites/doom/BFE2.spr");
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
			ent.pev.view_ofs.z = 20; // original == 28
			ent.pev.scale = 0.7f;
			//ent.pev.fuser4 = 2;
			//println("HEIGHT: " + (ent.pev.origin.z + ent.pev.view_ofs.z) + " " + ent.pev.view_ofs.z);
		}
	} while (ent !is null);
}

HookReturnCode PlayerUse( CBasePlayer@ plr, uint& out )
{	
	if (plr.m_afButtonPressed & IN_USE != 0)
	{
		TraceResult tr = TraceLook(plr, 64);
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
	//plr.RemoveAllItems(false);
	//animateDoomWeapon(plr);
}

bool doDoomCommand(CBasePlayer@ plr, const CCommand@ args)
{	
	if ( args.ArgC() > 0 )
	{
		if (args[0] == ".test")
		{
			g_Scheduler.SetInterval("doEffect", 0.025, -1, @plr);
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
