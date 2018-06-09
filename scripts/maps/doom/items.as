
void invulnerability(EHandle h_plr, bool flicker)
{
	if (!h_plr.IsValid())
		return;
		
	CBaseEntity@ plr = h_plr;
	PlayerState@ state = getPlayerState(cast<CBasePlayer@>(plr));
		
	float timeLeft = state.godTimeLeft();
	if (timeLeft > 0 and plr.IsAlive())
	{
		Vector color(64, 255, 128);
		plr.pev.effects |= EF_BRIGHTLIGHT;
		plr.pev.takedamage = DAMAGE_NO;
		if (timeLeft < 5.0f and flicker)
		{
			color = Vector(255, 255, 255);
			plr.pev.effects &= ~EF_BRIGHTLIGHT;
		}
		flicker = !flicker;
		g_PlayerFuncs.ScreenFade(plr, color, 0.0f, 1.0f, 255, FFADE_MODULATE | FFADE_STAYOUT);
	}
	else
	{
		g_PlayerFuncs.ScreenFade(plr, Vector(255, 240, 64), 0.2f, 0, 0, FFADE_IN);
		plr.pev.effects &= ~EF_BRIGHTLIGHT;
		plr.pev.takedamage = DAMAGE_YES;
		return;
	}
		
	g_Scheduler.SetTimeout("invulnerability", 0.5f, h_plr, flicker);
}

void invisibility(EHandle h_plr, bool flicker)
{
	if (!h_plr.IsValid())
		return;
		
	CBaseEntity@ plr = h_plr;
	PlayerState@ state = getPlayerState(cast<CBasePlayer@>(plr));
		
	float timeLeft = state.invisTimeLeft();
	if (timeLeft > 0 and plr.IsAlive())
	{
		float renderAmt = 64;
		int renderMode = 2;
		if (timeLeft < 5.0f and flicker)
		{
			renderAmt = 255;
			renderMode = 2;
		}
		flicker = !flicker;
		plr.pev.rendermode = renderMode;
		plr.pev.renderamt = renderAmt;
	}
	else
	{
		plr.pev.rendermode = 0;
		plr.pev.renderamt = 0;
		return;
	}
		
	g_Scheduler.SetTimeout("invisibility", 0.5f, h_plr, flicker);
}

void suitprotect(EHandle h_plr, bool flicker)
{
	if (!h_plr.IsValid())
		return;
		
	CBaseEntity@ plr = h_plr;
	PlayerState@ state = getPlayerState(cast<CBasePlayer@>(plr));
	
	float timeLeft = state.suitTimeLeft();
	if (timeLeft > 0 and plr.IsAlive() and plr.pev.takedamage != DAMAGE_NO)
	{
		Vector color(0, 128, 0);
		if (timeLeft < 5.0f and flicker)
			color = Vector(0, 0, 0);
		flicker = !flicker;
		g_PlayerFuncs.ScreenFade(plr, color, 0.0f, 1.0f, 64, FFADE_STAYOUT);
	}
	else
	{
		g_PlayerFuncs.ScreenFade(plr, Vector(255, 240, 64), 0.2f, 0, 0, FFADE_IN);
		return;
	}
		
	g_Scheduler.SetTimeout("suitprotect", 0.5f, h_plr, flicker);
}

void goggles(EHandle h_plr, bool flicker)
{
	if (!h_plr.IsValid())
		return;
		
	CBaseEntity@ plr = h_plr;
	PlayerState@ state = getPlayerState(cast<CBasePlayer@>(plr));
		
	float timeLeft = state.goggleTimeLeft();
	if (timeLeft > 0 and plr.IsAlive())
	{
		plr.pev.effects |= EF_BRIGHTLIGHT;
		if (timeLeft < 5.0f and flicker)
			plr.pev.effects &= ~EF_BRIGHTLIGHT;
		flicker = !flicker;
	}
	else
	{
		plr.pev.effects &= ~EF_BRIGHTLIGHT;
		return;
	}
		
	g_Scheduler.SetTimeout("goggles", 0.5f, h_plr, flicker);
}

class item_barrel : ScriptBaseEntity
{
	int animFrameStart = 6;
	int animFrameMax = 7;
	
	bool dead = false;
	
	int animDir = 1;
	
	void Spawn()
	{
		// set the model we actually want
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		//g_EntityFuncs.SetModel(self, "models/w_357.mdl");
		g_EntityFuncs.SetModel( self, fixPath("sprites/doom/objects.spr") );
		
		//pev.frame = 5;
		pev.scale = g_monster_scale;
		
		pev.movetype = MOVETYPE_PUSHSTEP;
		pev.solid = SOLID_BBOX;
		pev.health = 20;
		pev.takedamage = DAMAGE_YES;
		
		int light_level = self.Illumination();
		//println("ILLUM " + light_level);
		pev.rendercolor = Vector(light_level, light_level, light_level);
		
		g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, -4), Vector(16, 16, 40));
		pev.nextthink = g_Engine.time;
		SetThink(ThinkFunction(Think));
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if (dead)
			return 0;
		Vector delta = (pevAttacker.origin - pev.origin).Normalize();
		pev.basevelocity = delta*-128;
		
		pev.health -= flDamage;
		
		if (pev.health <= 0)
		{
			dead = true;
			pev.frame = 9;
			animFrameStart = 9;
			animFrameMax = 11;
			animDir = 1;
			pev.nextthink = g_Engine.time + 0.17f;
			g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, fixPath("doom/DSBAREXP.wav"), 1.0f, 1.0f, 0, 100);
			
			te_dlight(pev.origin, 30, Color(64,40,32,255), 3, 16);
		}
		
		return 0;
	}
	
	void Precache()
	{
		BaseClass.Precache();
	}
	
	bool CustomPickup()
	{
		return false;
	}
	
	void Think()
	{
		pev.frame += animDir;
		if (dead and pev.frame > animFrameMax)
		{
			g_EntityFuncs.Remove(self);
			return;
		}
		if (pev.frame > animFrameMax)
		{
			pev.frame = animFrameMax-1;
			animDir = -1;
		}
		if (pev.frame < animFrameStart)
		{
			pev.frame = animFrameStart+1;
			animDir = 1;
		}
		if (dead and pev.frame == 11)
		{
			RadiusDamage(pev.origin, self.pev, self.pev, 128, 128*g_monster_scale, 0, DMG_BLAST);
		}
		pev.nextthink = g_Engine.time + 0.17f;
	}
}

class item_prop : ScriptBaseEntity
{
	int frameStart = 159;
	int frameMax = 159;
	int thing_type = 44;
	int animDir = 1;
	float animSpeed = 0.17f;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{		
		if (szKey == "thing_type") thing_type = atoi(szValue);
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Spawn()
	{
		// set the model we actually want
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		//g_EntityFuncs.SetModel(self, "models/w_357.mdl");
		g_EntityFuncs.SetModel( self, fixPath("sprites/doom/objects.spr") );
		
		//pev.frame = 5;
		pev.scale = g_monster_scale;
		
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;
		pev.takedamage = DAMAGE_NO;
		
		
		//println("ILLUM " + light_level);
		
		setFrames();
		
		if (frameStart != frameMax)
		{
			pev.nextthink = g_Engine.time;
			SetThink(ThinkFunction(Think));
		}
	}
	
	void setFrames()
	{
		int light_level = self.Illumination();
		
		switch(thing_type)
		{
			case 24:
				frameStart = frameMax = 107;
				break;
			case 26:
				frameStart = 108;
				frameMax = 109;
				animSpeed = 0.2f;
				break;
			case 27:
				frameStart = frameMax = 106;
				break;
			case 25:
				frameStart = frameMax = 102;
				break;
			case 30:
				frameStart = frameMax = 38;
				break;
			case 31:
				frameStart = frameMax = 39;
				break;
			case 34:
				frameStart = frameMax = 30;
				light_level = 255;
				break;
			case 43:
				frameStart = frameMax = 158;
				break;
			case 44:
				frameStart = 142;
				frameMax = 145;
				light_level = 255;
				break;
			case 45:
				frameStart = 146;
				frameMax = 149;
				light_level = 255;
				break;
			case 46:
				frameStart = 160;
				frameMax = 163;
				light_level = 255;
				break;
			case 47:
				frameStart = frameMax = 130;
				break;
			case 53:
				frameStart = frameMax = 60;
				break;
			case 54:
				frameStart = frameMax = 159;
				break;
			case 55:
				frameStart = 122;
				frameMax = 125;
				light_level = 255;
				break;
			case 56:
				frameStart = 126;
				frameMax = 129;
				light_level = 255;
				break;
			case 57:
				frameStart = 131;
				frameMax = 134;
				light_level = 255;
				break;
			case 70:
				frameStart = 48;
				frameMax = 50;
				light_level = 255;
				break;
			case 75:
				frameStart = frameMax = 63;
				break;
			case 78:
				frameStart = frameMax = 66;
				break;
			case 79: case 80:
				frameStart = 100;
				frameMax = 100;
				break;
			case 85:
				frameStart = 150;
				frameMax = 153;
				light_level = 255;
				break;
			case 86:
				frameStart = 154;
				frameMax = 157;
				light_level = 255;
				break;
			default:
				println("Unhandled prop type: " + thing_type);
				break;
		}
		
		pev.rendercolor = Vector(light_level, light_level, light_level);
		pev.frame = frameStart;
	}
	
	void Precache()
	{
		BaseClass.Precache();
	}
	
	bool CustomPickup()
	{
		return false;
	}
	
	void Think()
	{		
		pev.frame += animDir;
		if (pev.frame > frameMax)
			pev.frame = frameStart;
		pev.nextthink = g_Engine.time + animSpeed;
	}
}


class item_doom : ScriptBaseItemEntity
{	
	int itemFrame = 0;
	int itemFrameMax = -1;
	float giveHealth = 0;
	float giveHealthMax = 100;
	float giveArmor = 0;
	float giveArmorMax = 200;
	bool giveGod = false;
	bool giveBerserk = false;
	bool giveInvis = false;
	bool giveSuit = false;
	bool giveGoggles = false;
	bool intermission = false;
	bool giveBackpack = false;
	string pickupSnd = "doom/DSITEMUP.wav";
	
	int animDir = 1;
	
	void ItemSpawn()
	{
		pickupSnd = fixPath(pickupSnd);
		
		// set the model we actually want
		g_EntityFuncs.SetModel( self, fixPath("sprites/doom/objects.spr") );
		BaseClass.Spawn();
		pev.frame = itemFrame;
		pev.scale = g_monster_scale;
		if (itemFrameMax == -1)
			itemFrameMax = itemFrame;
		
		//pev.movetype = MOVETYPE_NONE;
		//pev.solid = SOLID_NOT;
		
		int light_level = self.Illumination();
		//println("ILLUM " + light_level);
		pev.rendercolor = Vector(light_level, light_level, light_level);
		
		g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -4), Vector(8, 8, 8));
		
		if (itemFrameMax != itemFrame)
			pev.nextthink = g_Engine.time;
	}
	
	void Precache()
	{
		BaseClass.Precache();
	}
	
	bool CustomPickup()
	{
		return false;
	}
	
	void ItemThink()
	{
		pev.frame += animDir;
		if (pev.frame > itemFrameMax)
		{
			pev.frame = itemFrameMax-1;
			animDir = -1;
		}
		if (pev.frame < itemFrame)
		{
			pev.frame = itemFrame+1;
			animDir = 1;
		}
		pev.nextthink = g_Engine.time + 0.17f;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if (pActivator.IsPlayer())
		{
			TraceResult tr;
			g_Utility.TraceLine( pev.origin, pActivator.pev.origin, dont_ignore_monsters, pActivator.edict(), tr );
			if (tr.flFraction >= 1.0f)
				self.Touch(pActivator);
		}
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if (!pOther.IsPlayer())
			return;
		
		CBasePlayer@ plr = cast<CBasePlayer@>(pOther);
		PlayerState@ state = getPlayerState(plr);
		
		bool pickedUp = CustomPickup();
		if (giveHealth > 0)
		{
			if (pOther.pev.health < giveHealthMax)
			{
				pickedUp = true;
				pOther.pev.health += giveHealth;
				if (pOther.pev.health > giveHealthMax)
					pOther.pev.health = giveHealthMax;
			}
		}
		if (giveArmor > 0)
		{
			if (pOther.pev.armorvalue < giveArmorMax)
			{
				pickedUp = true;
				pOther.pev.armorvalue += giveArmor;
				if (pOther.pev.armorvalue > giveArmorMax)
					pOther.pev.armorvalue = giveArmorMax;
			}
		}
		
		if (giveBackpack)
		{
			plr.GiveAmmo(10, "bullets", 200, false);
			plr.GiveAmmo(4, "shells", 100, false);
			plr.GiveAmmo(1, "rockets", 100, false);
			plr.GiveAmmo(20, "cells", 400, false);
			pickedUp = true;
		}
		
		if (giveGod)
		{
			if (state.godTimeLeft() <= 0)
				g_Scheduler.SetTimeout("invulnerability", 0.0f, EHandle(pOther), true);
			state.lastGod = g_Engine.time;
			pickedUp = true;
		}
		if (giveBerserk)
		{
			CBasePlayerItem@ item = plr.HasNamedPlayerItem("weapon_doom_fist");
			if (item !is null)
			{
				plr.SelectItem("weapon_doom_fist");
				weapon_doom_fist@ fist = cast<weapon_doom_fist@>(CastToScriptClass(item));
				fist.damage_min = 20;
				fist.damage_max = 200;
				pickedUp = true;
			}
		}
		if (giveInvis)
		{
			if (state.godTimeLeft() <= 0)
				g_Scheduler.SetTimeout("invisibility", 0.0f, EHandle(pOther), true);
			state.lastInvis = g_Engine.time;
			pickedUp = true;
		}
		if (giveSuit)
		{
			if (state.suitTimeLeft() <= 0)
				g_Scheduler.SetTimeout("suitprotect", 0.0f, EHandle(pOther), true);
			state.lastSuit = g_Engine.time;
			pickedUp = true;
		}
		if (giveGoggles)
		{
			if (state.goggleTimeLeft() <= 0)
				g_Scheduler.SetTimeout("goggles", 0.0f, EHandle(pOther), true);
			state.lastGoggles = g_Engine.time;
			pickedUp = true;
		}
		
		if (pickedUp)
		{
			if (intermission)
				g_item_gets += 1;
			g_PlayerFuncs.ScreenFade(pOther, Vector(255, 240, 64), 0.2f, 0, 32, FFADE_IN);
			g_SoundSystem.PlaySound(pOther.edict(), CHAN_WEAPON, pickupSnd, 1.0f, 0.5f, 0, 100);
			g_EntityFuncs.Remove(self);
		}
		
		if (giveBerserk)
			g_PlayerFuncs.ScreenFade(pOther, Vector(255, 0, 0), 30.0f, 0, 32, FFADE_IN);
	}
}

class item_doom_backpack : item_doom
{
	void Spawn()
	{
		giveBackpack = true;
		itemFrame = 25;
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_stimpak : item_doom
{
	void Spawn()
	{
		giveHealth = 10;
		itemFrame = 140;
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_medkit : item_doom
{
	void Spawn()
	{
		giveHealth = 25;
		itemFrame = 81;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_potion : item_doom
{
	void Spawn()
	{
		giveHealth = 1;
		giveHealthMax = 200;
		itemFrame = 17;
		itemFrameMax = 20;
		intermission = true;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_armor_bonus : item_doom
{
	void Spawn()
	{
		giveArmor = 1;
		giveArmorMax = 200;
		itemFrame = 21;
		itemFrameMax = 23;
		intermission = true;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_armor : item_doom
{
	void Spawn()
	{
		giveArmor = 100;
		giveArmorMax = 100;
		itemFrame = 1;
		itemFrameMax = 2;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_megaarmor : item_doom
{
	void Spawn()
	{
		giveArmor = 200;
		giveArmorMax = 200;
		itemFrame = 3;
		itemFrameMax = 4;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_megasphere : item_doom
{
	void Spawn()
	{
		giveHealth = 200;
		giveHealthMax = 200;
		giveArmor = 200;
		giveArmorMax = 200;
		itemFrame = 82;
		itemFrameMax = 85;
		intermission = true;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_soulsphere : item_doom
{
	void Spawn()
	{
		giveHealth = 100;
		giveHealthMax = 200;
		itemFrame = 136;
		itemFrameMax = 139;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_god : item_doom
{
	void Spawn()
	{
		giveGod = true;
		itemFrame = 91;
		itemFrameMax = 94;
		intermission = true;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_berserk : item_doom
{
	void Spawn()
	{
		giveHealth = 100;
		giveHealthMax = 100;
		giveBerserk = true;
		itemFrame = 110;
		intermission = true;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_invis : item_doom
{
	void Spawn()
	{
		giveInvis = true;
		itemFrame = 87;
		itemFrameMax = 90;
		intermission = true;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_suit : item_doom
{
	void Spawn()
	{
		giveSuit = true;
		itemFrame = 141;
		itemFrameMax = 141;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_goggles : item_doom
{
	void Spawn()
	{
		giveGoggles = true;
		itemFrame = 111;
		itemFrameMax = 112;
		intermission = true;
		pickupSnd = "doom/DSGETPOW.wav";
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}

class item_doom_key_red : item_doom
{
	void Spawn()
	{
		itemFrame = 113;
		itemFrameMax = 114;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= KEY_RED;
		return true;
	}
}

class item_doom_key_blue : item_doom
{
	void Spawn()
	{
		itemFrame = 15;
		itemFrameMax = 16;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= KEY_BLUE;
		return true;
	}
}

class item_doom_key_yellow : item_doom
{
	void Spawn()
	{
		itemFrame = 164;
		itemFrameMax = 165;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= KEY_YELLOW;
		return true;
	}
}

class item_doom_skull_red : item_doom
{
	void Spawn()
	{
		itemFrame = 116;
		itemFrameMax = 117;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= SKULL_RED;
		return true;
	}
}

class item_doom_skull_blue : item_doom
{
	void Spawn()
	{
		itemFrame = 28;
		itemFrameMax = 29;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= SKULL_BLUE;
		return true;
	}
}

class item_doom_skull_yellow : item_doom
{
	void Spawn()
	{
		itemFrame = 166;
		itemFrameMax = 167;
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
	
	bool CustomPickup()
	{
		g_keys |= SKULL_YELLOW;
		return true;
	}
}