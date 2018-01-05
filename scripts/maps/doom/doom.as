#include "anims"
#include "monster_imp"
#include "utils"

EHandle zombo;

array<string> sprite_angles = {
	"1", "2?8", "3?7", "4?6", "5", "6?4", "7?3", "8?2"
};

void PrecacheSound(string sound)
{
	g_SoundSystem.PrecacheSound(sound);
	g_Game.PrecacheGeneric("sound/" + sound);
}

void MapInit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_imp", "monster_imp" );
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombieman", "monster_zombieman" );
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	
	for (uint z = 0; z < SPR_ANIM_TROO.length(); z++)
		for (uint i = 0; i < SPR_ANIM_TROO[z].length(); i++)
			for (uint k = 0; k < SPR_ANIM_TROO[z][i].length(); k++)
				g_Game.PrecacheModel( SPR_ANIM_TROO[z][i][k] );
				
	for (uint z = 0; z < SPR_ANIM_POSS.length(); z++)
		for (uint i = 0; i < SPR_ANIM_POSS[z].length(); i++)
			for (uint k = 0; k < SPR_ANIM_POSS[z][i].length(); k++)
				g_Game.PrecacheModel( SPR_ANIM_POSS[z][i][k] );

	g_Game.PrecacheModel("sprites/doom/BAL1.spr");
	g_Game.PrecacheModel("sprites/doom/imp/TROO_L0.spr");
	g_Game.PrecacheModel("sprites/doom/imp/TROO_L1.spr");
	g_Game.PrecacheModel("sprites/doom/imp/TROO_L2.spr");
	g_Game.PrecacheModel("sprites/doom/imp/TROO_L3.spr");
	g_Game.PrecacheModel("sprites/doom/zombieman/POSS_L0.spr");
	g_Game.PrecacheModel("sprites/doom/zombieman/POSS_L1.spr");
	g_Game.PrecacheModel("sprites/doom/zombieman/POSS_L2.spr");
	g_Game.PrecacheModel("sprites/doom/zombieman/POSS_L3.spr");
	g_Game.PrecacheModel("models/doom/null.mdl");
	
	PrecacheSound("doom/DSBGSIT1.wav");
	PrecacheSound("doom/DSBGSIT2.wav");
	PrecacheSound("doom/DSFIRSHT.wav");
	PrecacheSound("doom/DSFIRXPL.wav");
	PrecacheSound("doom/DSCLAW.wav");
	PrecacheSound("doom/DSBGACT.wav");
	PrecacheSound("doom/DSPOPAIN.wav");
	PrecacheSound("doom/DSBGDTH1.wav");
	PrecacheSound("doom/DSBGDTH2.wav");
	PrecacheSound("doom/DSSLOP.wav");
	PrecacheSound("doom/DSPOSACT.wav");
	PrecacheSound("doom/DSBGDTH1.wav");
	PrecacheSound("doom/DSBGDTH2.wav");
	PrecacheSound("doom/DSPODTH2.wav");
	PrecacheSound("doom/DSPODTH3.wav");
	PrecacheSound("doom/DSPODTH1.wav");
	PrecacheSound("doom/DSPOSIT1.wav");
	PrecacheSound("doom/DSPOSIT2.wav");
	PrecacheSound("doom/DSPISTOL.wav");
}

void MapActivate()
{
	CBaseEntity@ zombie = g_EntityFuncs.FindEntityByClassname(null, "monster_zombie");
	zombo = zombie;
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

int frame = 0;
void doEffect()
{
}

bool doDoomCommand(CBasePlayer@ plr, const CCommand@ args)
{	
	if ( args.ArgC() > 0 )
	{
		if (args[0] == ".test")
		{
			g_Scheduler.SetInterval("doEffect", 0.1, -1);
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
