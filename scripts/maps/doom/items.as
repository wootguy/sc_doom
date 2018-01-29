
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
			color = Vector(255, 255, 255);
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
	
	int animDir = 1;
	
	void ItemSpawn()
	{
		// set the model we actually want
		g_EntityFuncs.SetModel( self, "sprites/doom/objects.spr" );
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
	
	void Touch( CBaseEntity@ pOther )
	{
		if (!pOther.IsPlayer())
			return;
		
		CBasePlayer@ plr = cast<CBasePlayer@>(pOther);
		PlayerState@ state = getPlayerState(plr);
		
		bool pickedUp = false;
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
			g_PlayerFuncs.ScreenFade(pOther, Vector(255, 240, 64), 0.2f, 0, 32, FFADE_IN);
			g_SoundSystem.PlaySound(pOther.edict(), CHAN_WEAPON, "doom/DSITEMUP.wav", 1.0f, 0.5f, 0, 100);
			g_EntityFuncs.Remove(self);
		}
		
		if (giveBerserk)
			g_PlayerFuncs.ScreenFade(pOther, Vector(255, 0, 0), 30.0f, 0, 32, FFADE_IN);
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
		SetThink(ThinkFunction(Think));
		ItemSpawn();
	}
	
	void Think()
	{
		ItemThink();
	}
}
