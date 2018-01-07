#include "monsters"
#include "utils"

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
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
		
	g_Game.PrecacheModel("sprites/doom/BAL.spr");
	g_Game.PrecacheModel("sprites/doom/BAL7.spr");
	g_Game.PrecacheModel("models/doom/null.mdl");
	
	PrecacheSound("doom/DSFIRSHT.wav");
	PrecacheSound("doom/DSFIRXPL.wav");
}

void MapActivate()
{
	
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

void doTheStatic(CBaseEntity@ ent)
{
	//g_EngineFuncs.MakeStatic(ent.edict());
}

int frame = 0;
void doEffect(CBasePlayer@ plr)
{
	/*
	dictionary keys;
	keys["origin"] = Vector(256,256,128).ToString();
	keys["model"] = "d/t.spr";
	keys["framerate"] = "0";
	keys["vp_type"] = "3";
	CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("env_sprite", keys, false);
	g_EntityFuncs.DispatchSpawn(fireball.edict());
	g_Scheduler.SetTimeout("doTheStatic", 1.0f, @fireball);
	*/
	
	plr.pev.view_ofs.z -= 2048.0f;
	//plr.SetViewMode(ViewMode_ThirdPerson);
	println("OFSET: " + plr.pev.view_ofs.z);
	//g_EngineFuncs.SetView(plr.edict(), g_EntityFuncs.FindEntityByClassname(null, "monster_imp").edict());
	
	//te_projectile(plr.pev.origin + Vector(0, 0, 73), Vector(0, 0, -10), null, "*2", 10, MSG_ONE_UNRELIABLE, @plr.edict());
	//te_spray(plr.pev.origin + Vector(32, 0, 0), Vector(0, 0, -10), "*2", 1, 0, 0, 4, MSG_ONE_UNRELIABLE, @plr.edict());
	//te_explosion(plr.pev.origin, "*1", 10, 0, 15, MSG_ONE_UNRELIABLE, plr.edict());
}

bool doDoomCommand(CBasePlayer@ plr, const CCommand@ args)
{	
	if ( args.ArgC() > 0 )
	{
		if (args[0] == ".test")
		{
			CBaseEntity@ imp = @g_EntityFuncs.FindEntityByClassname(null, "monster_imp");
			g_Scheduler.SetInterval("doEffect", 0.05, -1, @plr);
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
