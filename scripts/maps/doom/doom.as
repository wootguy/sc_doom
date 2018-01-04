#include "anims"
#include "monster_imp"

class Color
{ 
	uint8 r, g, b, a;
	Color() { r = g = b = a = 0; }
	Color(uint8 r, uint8 g, uint8 b) { this.r = r; this.g = g; this.b = b; this.a = 255; }
	Color(uint8 r, uint8 g, uint8 b, uint8 a) { this.r = r; this.g = g; this.b = b; this.a = a; }
	Color(float r, float g, float b, float a) { this.r = uint8(r); this.g = uint8(g); this.b = uint8(b); this.a = uint8(a); }
	Color (Vector v) { this.r = uint8(v.x); this.g = uint8(v.y); this.b = uint8(v.z); this.a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
	Vector getRGB() { return Vector(r, g, b); }
}

Color RED    = Color(255,0,0);
Color GREEN  = Color(0,255,0);
Color BLUE   = Color(0,0,255);
Color YELLOW = Color(255,255,0);
Color ORANGE = Color(255,127,0);
Color PURPLE = Color(127,0,255);
Color PINK   = Color(255,0,127);
Color TEAL   = Color(0,255,255);
Color WHITE  = Color(255,255,255);
Color BLACK  = Color(0,0,0);
Color GRAY  = Color(127,127,127);

void te_projectile(Vector pos, Vector velocity, CBaseEntity@ owner=null, 
	string model="models/grenade.mdl", uint8 life=1, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	int ownerId = owner is null ? 0 : owner.entindex();
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PROJECTILE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(life);
	m.WriteByte(ownerId);
	m.End();
}
void te_explosion(Vector pos, string sprite="sprites/zerogxplode.spr", 
	int scale=10, int frameRate=15, int flags=0,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_EXPLOSION);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(frameRate);
	m.WriteByte(flags);
	m.End();
}
void te_beampoints(Vector start, Vector end, string sprite="sprites/laserbeam.spr", uint8 frameStart=0, uint8 frameRate=100, uint8 life=20, uint8 width=2, uint8 noise=0, Color c=GREEN, uint8 scroll=32, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_BEAMPOINTS);m.WriteCoord(start.x);m.WriteCoord(start.y);m.WriteCoord(start.z);m.WriteCoord(end.x);m.WriteCoord(end.y);m.WriteCoord(end.z);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(frameStart);m.WriteByte(frameRate);m.WriteByte(life);m.WriteByte(width);m.WriteByte(noise);m.WriteByte(c.r);m.WriteByte(c.g);m.WriteByte(c.b);m.WriteByte(c.a);m.WriteByte(scroll);m.End(); }


void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

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
	g_CustomEntityFuncs.RegisterCustomEntity( "fireball", "fireball" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	
	for (uint z = 0; z < SPR_ANIM_TROO.length(); z++)
		for (uint i = 0; i < SPR_ANIM_TROO[z].length(); i++)
			for (uint k = 0; k < SPR_ANIM_TROO[z][i].length(); k++)
				g_Game.PrecacheModel( SPR_ANIM_TROO[z][i][k] );

	g_Game.PrecacheModel("sprites/doom/BAL1.spr");
	g_Game.PrecacheModel("sprites/doom/TROO_L0.spr");
	g_Game.PrecacheModel("sprites/doom/TROO_L1.spr");
	g_Game.PrecacheModel("sprites/doom/TROO_L2.spr");
	g_Game.PrecacheModel("sprites/doom/TROO_L3.spr");
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
