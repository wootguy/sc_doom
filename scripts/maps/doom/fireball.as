#include "utils"

class fireball : ScriptBaseAnimating
{
	string spawnSound = "doom/DSFIRSHT.wav";
	string deathSound = "doom/DSFIRXPL.wav";
	bool dead = false;
	bool oriented = false;
	int moveFrameStart = 0;
	int moveFrameEnd = 1;
	int deathFrameStart = 2;
	int deathFrameEnd = 4;
	int frameCounter = 0;
	int damageMin = 3;
	int damageMax = 24;
	float radiusDamage = 0;
	Vector flash_color = Vector(255, 64, 32);
	
	array<EHandle> sprites;
	array<EHandle> renderShowEnts;
	array<EHandle> renderHideEnts;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "deathFrameStart") deathFrameStart = atoi(szValue);
		else if (szKey == "deathFrameEnd") deathFrameEnd = atoi(szValue);
		else if (szKey == "moveFrameStart") moveFrameStart = atoi(szValue);
		else if (szKey == "moveFrameEnd") moveFrameEnd = atoi(szValue);
		else if (szKey == "moveFrameEnd") moveFrameEnd = atoi(szValue);
		else if (szKey == "flash_color") flash_color = parseVector(szValue);
		else if (szKey == "damage_min") damageMin = atoi(szValue);
		else if (szKey == "damage_max") damageMax = atoi(szValue);
		else if (szKey == "oriented") oriented = atoi(szValue) != 0;
		else if (szKey == "spawn_sound") spawnSound = szValue;
		else if (szKey == "death_sound") deathSound = szValue;
		else if (szKey == "radius_dmg") radiusDamage = atof(szValue);
		else return BaseClass.KeyValue( szKey, szValue );
		return true;
	}
	
	void Spawn()
	{				
		pev.movetype = MOVETYPE_FLY;
		pev.solid = SOLID_TRIGGER;
		
		g_EntityFuncs.SetModel( self, self.pev.model );
		float size = 8*g_world_scale;
		g_EntityFuncs.SetSize(self.pev, Vector(-size, -size, -size), Vector(size, size, size));
		
		g_EngineFuncs.MakeVectors(self.pev.angles);
		pev.velocity = g_Engine.v_forward*pev.speed*g_monster_scale;
		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, spawnSound, 1.0f, 0.5f, 0, 100);
		
		pev.scale = g_monster_scale;
		pev.frame = moveFrameStart;
		
		if (oriented)
		{
			g_monster_idx++;
			
			for (uint i = 0; i < 8; i++)
			{
				dictionary ckeys;
				ckeys["origin"] = pev.origin.ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
				ckeys["model"] = string(pev.model);
				ckeys["spawnflags"] = "1";
				ckeys["rendermode"] = "2";
				ckeys["renderamt"] = "0";
				ckeys["rendercolor"] = "255 255 255";
				ckeys["scale"] = string(pev.scale);
				ckeys["targetname"] = "m" + g_monster_idx + "s" + i;
				CBaseEntity@ client_sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
				sprites.insertLast(EHandle(client_sprite));
				client_sprite.pev.movetype = MOVETYPE_FLY;
				client_sprite.pev.velocity = pev.velocity;
				
				dictionary rkeys;
				rkeys["target"] = string(client_sprite.pev.targetname);
				rkeys["spawnflags"] = "" + (1 | 4 | 8 | 64);
				rkeys["renderamt"] = "255";
				CBaseEntity@ show = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
				renderShowEnts.insertLast(EHandle(show));
				
				rkeys["renderamt"] = "0";
				CBaseEntity@ hide = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
				renderHideEnts.insertLast(EHandle(hide));
			}
			pev.effects |= EF_NODRAW;
		}
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.05;
	}
	
	void killClientSprites()
	{
		array<string>@ stateKeys = player_states.getKeys();
		for (uint i = 0; i < stateKeys.size(); i++)
		{
			PlayerState@ state = cast<PlayerState@>(player_states[ stateKeys[i] ]);
			for (uint k = 0; k < sprites.length(); k++)
			{
				if (sprites[k])
				{
					CBaseEntity@ client_sprite = sprites[k];
					state.hideVisibleEnt(client_sprite.pev.targetname);
				}
			}
		}
		
		for (uint k = 0; k < sprites.length(); k++)
		{
			g_EntityFuncs.Remove(sprites[k]);
			g_EntityFuncs.Remove(renderShowEnts[k]);
			g_EntityFuncs.Remove(renderHideEnts[k]);
		}
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if (dead or (pOther.pev.classname == "fireball"))
			return;
			
		CBaseEntity@ owner = g_EntityFuncs.Instance( self.pev.owner );
		if (owner !is null and owner.entindex() == pOther.entindex())
			return;
			
		dead = true;
		pev.solid = SOLID_NOT;
		pev.frame = deathFrameStart;
		frameCounter = deathFrameStart;
		pev.nextthink = g_Engine.time + 0.15;
		killClientSprites();
		pev.effects &= ~EF_NODRAW;
		
		int damage = Math.RandomLong(damageMin, damageMax);
		Vector oldVel = pOther.pev.velocity;
		pOther.TakeDamage(self.pev, owner is null ? self.pev : owner.pev, damage, DMG_BLAST);
		pOther.pev.velocity = oldVel; // prevent vertical launching
		knockBack(pOther, pev.velocity.Normalize()*(100 + damage*2)*g_world_scale);
		
		if (radiusDamage > 0)
			g_WeaponFuncs.RadiusDamage(pev.origin, self.pev, owner is null ? self.pev : owner.pev, radiusDamage, radiusDamage, 0, DMG_BLAST);
		
		pev.velocity = Vector(0,0,0);
		g_SoundSystem.PlaySound(self.edict(), CHAN_BODY, deathSound, 1.0f, 0.5f, 0, 100);
	}
	
	void RenderOriented()
	{
		g_EngineFuncs.MakeVectors(self.pev.angles);
		Vector forward = g_Engine.v_forward;
		Vector right = g_Engine.v_right;
		
		// render sprite for each player
		CBaseEntity@ ent = null;
		do {
			@ent = g_EntityFuncs.FindEntityByClassname(ent, "player");
			if (ent !is null)
			{
				Vector pos = pev.origin + Vector(0,0,0);
				
				Vector delta = pos - ent.pev.origin;
				delta = delta.Normalize();
				int angleIdx = getSpriteAngle(pos, forward, right, ent.pev.origin);
				
				PlayerState@ state = getPlayerState(cast<CBasePlayer@>(ent));
				
				for (int i = 0; i < 8; i++)
				{
					CBaseEntity@ client_sprite = sprites[i];
					bool shouldVisible = i == angleIdx;
					
					if (shouldVisible != state.isVisibleEnt(client_sprite.pev.targetname))
					{
						//println("SET VISIBLE " + client_sprite.pev.targetname + " " + shouldVisible);
						if (shouldVisible)
						{
							CBaseEntity@ renderent = renderShowEnts[i];
							renderent.Use(ent, ent, USE_TOGGLE);
							state.addVisibleEnt(client_sprite.pev.targetname, EHandle(client_sprite));
						}
						else
						{
							CBaseEntity@ renderent = renderHideEnts[i];
							renderent.Use(ent, ent, USE_TOGGLE);
							state.hideVisibleEnt(client_sprite.pev.targetname);
						}
					}
				}
			}
		} while (ent !is null);
		
		for (uint i = 0; i < 8; i++)
		{
			CBaseEntity@ client_sprite = sprites[i];
			bool canAnyoneSeeThis = client_sprite.pev.colormap > 0;
			if (canAnyoneSeeThis)
			{
				client_sprite.pev.effects &= ~EF_NODRAW;
				client_sprite.pev.origin = pev.origin + Vector(0,0,11);// + Vector(0,0,64 + i*32)
				client_sprite.pev.frame = pev.frame*8 + i;
			}
			else
				client_sprite.pev.effects |= EF_NODRAW;
			
		}
	}
	
	void Think()
	{
		frameCounter++;
		
		if (dead)
		{
			pev.frame = frameCounter;
			if (pev.frame > deathFrameEnd)
			{
				g_EntityFuncs.Remove(self);
				return;
			}
			
			int flash_size = 30;
			int flash_life = 3;
			int flash_decay = 8;
			Color color = Color(int(flash_color.x/8), int(flash_color.y/8), int(flash_color.z/8));
			te_dlight(self.pev.origin, flash_size, color, flash_life, flash_decay);
			
			pev.nextthink = g_Engine.time + 0.15;
		}
		else
		{
			pev.frame = moveFrameStart + (frameCounter / 3) % ((moveFrameEnd-moveFrameStart) + 1);
			
			int flash_size = 20;
			int flash_life = 1;
			int flash_decay = 8;
			Color color = Color(flash_color);
			te_dlight(self.pev.origin, flash_size, color, flash_life, flash_decay);
			
			if (oriented)
				RenderOriented();
			
			pev.nextthink = g_Engine.time + 0.05;
		}
	}
}