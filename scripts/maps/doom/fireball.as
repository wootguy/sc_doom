#include "utils"

class fireball : ScriptBaseAnimating
{
	string spawnSound = "doom/DSFIRSHT.wav";
	string deathSound = "doom/DSFIRXPL.wav";
	string trailSprite;
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
	float size = 4;
	Vector lastVelocity;
	bool is_bfg = false;
	bool is_vile_fire = false;
	int fire_state = 0;
	bool trailFrame = false;
	float deathTime = 0;
	Vector flash_color = Vector(255, 64, 32);
	Vector sprOffset = Vector(0,0,11);
	EHandle h_followEnt;
	EHandle h_aimEnt;
	
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
		else if (szKey == "is_bfg") is_bfg = atoi(szValue) != 0;
		else if (szKey == "is_vile_fire") is_vile_fire = atoi(szValue) != 0;
		else if (szKey == "spawn_sound") spawnSound = szValue;
		else if (szKey == "death_sound") deathSound = szValue;
		else if (szKey == "radius_dmg") radiusDamage = atof(szValue);
		else if (szKey == "bbox_size") size = atof(szValue);
		else if (szKey == "trail_sprite") trailSprite = szValue;
		else return BaseClass.KeyValue( szKey, szValue );
		return true;
	}
	
	void Spawn()
	{				
		pev.movetype = MOVETYPE_BOUNCE;
		pev.gravity = 0.000001f;
		pev.solid = SOLID_BBOX;
		
		self.pev.model = fixPath(self.pev.model);
		spawnSound = fixPath(spawnSound);
		deathSound = fixPath(deathSound);
		trailSprite = fixPath(trailSprite);
		
		g_EntityFuncs.SetModel( self, self.pev.model );
		size *= g_world_scale;
		g_EntityFuncs.SetSize(self.pev, Vector(-size, -size, -size), Vector(size, size, size));
		
		g_EngineFuncs.MakeVectors(self.pev.angles);
		pev.velocity = g_Engine.v_forward*pev.speed*g_monster_scale;
		lastVelocity = pev.velocity;
		
		if (spawnSound.Length() > 0)
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, spawnSound, 1.0f, 0.5f, is_vile_fire ? int(SND_FORCE_LOOP) : 0, 100);
		
		if (is_vile_fire)
			deathTime = g_Engine.time + 2.2f;
		
		pev.scale = g_monster_scale;
		pev.frame = moveFrameStart;
		
		if (oriented)
		{
			g_monster_idx++;
			
			for (uint i = 0; i < 8; i++)
			{
				dictionary ckeys;
				ckeys["origin"] = (pev.origin + sprOffset).ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
				ckeys["model"] = string(pev.model);
				ckeys["spawnflags"] = "1";
				ckeys["rendermode"] = "2";
				ckeys["renderamt"] = "0";
				ckeys["rendercolor"] = "255 255 255";
				ckeys["scale"] = string(pev.scale);
				ckeys["targetname"] = "m" + g_monster_idx + "s" + i;
				CBaseEntity@ client_sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
				sprites.insertLast(EHandle(client_sprite));
				g_EntityFuncs.SetSize(client_sprite.pev, Vector(0,0,0), Vector(0,0,0)); 
				client_sprite.pev.solid = SOLID_NOT;
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
	
	void Remove()
	{
		g_SoundSystem.StopSound(self.edict(), CHAN_WEAPON, spawnSound);
		killClientSprites();
		g_EntityFuncs.Remove(self);
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
		//if (dead or (pOther.pev.classname == "fireball"))
		if (dead)
			return;
			
		if (is_vile_fire)
		{
			if (!FireThink())
			{
				Remove();
				return;
			}
			g_SoundSystem.StopSound(self.edict(), CHAN_WEAPON, spawnSound);
			is_vile_fire = false; // back to the normal think code
		}
			
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
		pOther.TakeDamage(self.pev, owner is null ? self.pev : owner.pev, damage, DMG_GENERIC);
		pOther.pev.velocity = oldVel; // prevent vertical launching
		knockBack(pOther, pev.velocity.Normalize()*(100 + damage*2)*g_world_scale);
		
		if (radiusDamage > 0)
			RadiusDamage(pev.origin, self.pev, owner is null ? self.pev : owner.pev, radiusDamage, radiusDamage*g_monster_scale, 0, DMG_BLAST);
		
		if (is_bfg and owner !is null)
		{
			// do weird bfg tracer stuff
			float range = 1024;
			float spread = 45.0f;
			Vector dir = pev.velocity.Normalize();
			Vector vecSrc = owner.pev.origin;
			dictionary targets;
			
			for (uint i = 0; i < 40; i++)
			{
				Vector vecAiming = spreadDir(dir, spread, SPREAD_UNIFORM);

				// Do the bullet collision
				TraceResult tr;
				Vector vecEnd = vecSrc + vecAiming * range;
				g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, owner.edict(), tr );
				
				// do more fancy effects
				if( tr.flFraction < 1.0 )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if( pHit !is null and !pHit.IsBSPModel()) 
					{
						float rayDamage = Math.RandomLong(47, 87);
						Vector oldRayVel = pHit.pev.velocity;	
						pHit.TakeDamage(owner.pev, owner.pev, rayDamage, DMG_SHOCK);
						pHit.pev.velocity = oldRayVel; // prevent high damage from launching unless we ask for it (unless DMG_LAUNCH)
						
						if (!targets.exists(pHit.entindex()))
						{
							targets[pHit.entindex()] = true; // only 1 effect per monstie
							te_explosion(tr.vecEndPos, fixPath("sprites/doom/BFE2.spr"), 10, 5, 15);
						}
					}
				}
			}
			
		}
		
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
				if (((client_sprite.pev.origin + sprOffset) - pev.origin).Length() > 32)
				{
					println("ZOMG SYNC " + ((client_sprite.pev.origin + sprOffset) - pev.origin).Length());
					g_EntityFuncs.SetOrigin(client_sprite, pev.origin + sprOffset); // + Vector(0,0,64 + i*32)
					client_sprite.pev.velocity = pev.velocity;
					
				}
				client_sprite.pev.frame = pev.frame*8 + i;
			}
			else
				client_sprite.pev.effects |= EF_NODRAW;
			
		}
	}
	
	bool FireThink()
	{
		if (deathTime < g_Engine.time)
		{
			Remove();
			return false;
		}
		if (fire_state % 2 == 0)
		{
			if (fire_state == 10)
				frameCounter++;
			frameCounter++;
		}
		else if (fire_state % 2 == 1)
			frameCounter--;
			
		fire_state = (fire_state+1) % 11;
		
		CBaseEntity@ target = h_aimEnt;
		TraceResult tr;
		g_Utility.TraceLine( target.pev.origin, h_followEnt.GetEntity().pev.origin, ignore_monsters, null, tr );
		bool targetVisible = tr.flFraction >= 1.0f;
		if (targetVisible)
		{
			g_EngineFuncs.MakeVectors(target.IsPlayer() ? target.pev.v_angle : target.pev.angles);
			Vector offset = target.IsPlayer() ? Vector(0,0,-35) : Vector(0,0,0);
			g_EntityFuncs.SetOrigin(self, target.pev.origin + g_Engine.v_forward*16 + offset);
		}

		pev.frame = moveFrameStart + (frameCounter) % ((moveFrameEnd-moveFrameStart) + 1);
		pev.nextthink = g_Engine.time + 0.05;
		return targetVisible;
	}
	
	void Think()
	{
		if (is_vile_fire) {
			FireThink();
			return;
		}
		frameCounter++;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		
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
				
			if (h_followEnt)
			{
				CBaseEntity@ followEnt = h_followEnt;
				Vector dir = pev.velocity.Normalize();
				Vector targetDir = ((followEnt.pev.origin + followEnt.pev.view_ofs) - pev.origin).Normalize();
			
				float speed = pev.velocity.Length();	
	
				Vector axis = CrossProduct(dir, targetDir).Normalize();
				
				float dot = DotProduct(targetDir, dir);
				float angle = -acos(dot);
				if (dot == -1)
					angle = Math.PI / 2.0f;
				if (dot == 1 or angle != angle)
					angle = 0;
				float maxAngle = 10.0f * Math.PI / 180.0f;
				angle = Math.max(-maxAngle, Math.min(maxAngle, angle));
				
				if (abs(angle) > 0.001f)
				{
					// Apply rotation around arbitrary axis
					array<float> rotMat = rotationMatrix(axis, angle);
					dir = matMultVector(rotMat, dir).Normalize();
					pev.velocity = dir*speed;
					g_EngineFuncs.VecToAngles(pev.velocity, pev.angles);	
				}
			}
			
			if (trailSprite.Length() > 0)
			{
				if (trailFrame)
					te_explosion(pev.origin+Vector(0,0,8) - pev.velocity.Normalize(), trailSprite, 14, 10, 15);
				trailFrame = !trailFrame;
			}
			
			pev.nextthink = g_Engine.time + 0.05;
		}
		
		if (!h_followEnt.IsValid() and (pev.velocity - lastVelocity).Length() > 1)
		{
			Touch(g_EntityFuncs.Instance(0));
		}
		lastVelocity = pev.velocity;
	}
}