#include "utils"
#include "fireball"

enum activities {
	ANIM_IDLE,
	ANIM_MOVE,
	ANIM_ATTACK,
	ANIM_PAIN,
	ANIM_DEAD,
	ANIM_GIB,
}

array<string> light_suffix = {"_L3", "_L2", "_L1", "_L0"};

float g_monster_scale = 1.0f;
float g_world_scale = 0.7f;

class AnimInfo
{
	float framerate;
	bool looped;
	array<int> frameIndices;
	int attackFrameIdx; // frame index where attack is called (-1 = every frame)
	
	AnimInfo() {}
	
	AnimInfo(int min, int max, float rate, bool loop)
	{
		this.framerate = rate;
		this.looped = loop;
		this.attackFrameIdx = max - min;
		
		for (int i = min; i <= max; i++)
			frameIndices.insertLast(i);
	}
	
	int getFrameIdx(uint frameCounter, float oldCounter, bool &out looped)
	{
		int oldIdx = int(oldCounter*framerate) % frameIndices.length();
		int newIdx = int(frameCounter*framerate) % frameIndices.length();
		looped = oldIdx > newIdx or frameIndices.length() == 1;
		return newIdx;
	}
	
	int lastFrame()
	{
		return frameIndices[frameIndices.length()-1];
	}
}

uint g_monster_idx = 0;

class monster_doom : ScriptBaseMonsterEntity
{
	string bodySprite;
	array<AnimInfo> animInfo;
	AnimInfo currentAnim;
	
	int activity = ANIM_IDLE;
	bool hasMelee = true;
	bool hasRanged = true;
	bool isSpectre = false;
	bool canFly = false;
	bool fullBright = false;
	bool constantAttack = false; // attack until target is obscured
	int constantAttackMax = 0; // maximum attacks played in sequence
	float deathBoom = 0;
	
	uint frameCounter = 0;
	uint oldFrameCounter = 0;
	int animLoops = 0;
	int oldFrameIdx = 0;
	
	float walkSpeed = 8.0f;
	float painChance = 1.0f;
	float meleeRange = 64.0f;
	float minRangeAttackDelay = 1.0f;
	float maxRangeAttackDelay = 4.0f;
	float walkSoundFreq = 0.6f;
	
	float nextWalkSound = 0;
	float nextRangeAttack = 0;
	float lastWallReflect = 0;
	float lastDirChange = 0;
	float lastEnemy = 0;
	float deathRemoveDelay = 60.0f; // time before entity is destroyed after death
	float nextIdleSound = 0;
	bool dormant = true;
	bool isCorpse = false;
	uint brighten = 0; // if > 0 then draw full-bright. Decremented each frame
	bool dashing = false;
	Vector dashVel;
	float dashDamage = 0;
	float dashTimeout = 0;
	
	EHandle h_enemy;
	EHandle oldEnemy; // remember last enemy
	
	array<EHandle> sprites;
	array<EHandle> renderShowEnts;
	array<EHandle> renderHideEnts;
	
	array<string> idleSounds;
	array<string> deathSounds;
	array<string> alertSounds;
	string painSound;
	string meleeSound;
	string shootSound;
	string walkSound;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "spectre") isSpectre = atoi(szValue) != 0;
		else return BaseClass.KeyValue( szKey, szValue );
		return true;
	}
	
	void Precache()
	{
		for (uint i = 0; i < idleSounds.length(); i++)
			PrecacheSound(idleSounds[i]);
		for (uint i = 0; i < deathSounds.length(); i++)
			PrecacheSound(deathSounds[i]);
		for (uint i = 0; i < alertSounds.length(); i++)
			PrecacheSound(alertSounds[i]);
		PrecacheSound(meleeSound);
		PrecacheSound(shootSound);
		PrecacheSound(painSound);
		PrecacheSound(walkSound);
		PrecacheSound("doom/DSSLOP.wav");
	}
	
	void DoomTouched(CBaseEntity@ ent)
	{
		//println("ZOMG TOUCHED " + ent.pev.classname);
	}
	
	void DoomSpawn()
	{
		Precache();
		
		pev.movetype = canFly ? MOVETYPE_FLY : MOVETYPE_STEP;
		pev.solid = SOLID_SLIDEBOX;
		
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		//g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 72));
		
		self.m_bloodColor = BLOOD_COLOR_RED;
		self.pev.scale = g_monster_scale;
		pev.takedamage = DAMAGE_YES;
		
		self.MonsterInit();
		
		g_monster_idx++;
		
		for (uint i = 0; i < 8; i++)
		{
			dictionary ckeys;
			ckeys["origin"] = pev.origin.ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
			ckeys["model"] = bodySprite;
			ckeys["spawnflags"] = "1";
			ckeys["rendermode"] = "2";
			ckeys["renderamt"] = "0";
			ckeys["rendercolor"] = isSpectre ? "1 1 1" : "255 255 255";
			ckeys["scale"] = string(pev.scale);
			ckeys["targetname"] = "m" + g_monster_idx + "s" + i;
			CBaseEntity@ client_sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
			//println("MAKE LE SPRITE " + client_sprite.pev.targetname);
			sprites.insertLast(EHandle(client_sprite));
			
			dictionary rkeys;
			rkeys["target"] = string(client_sprite.pev.targetname);
			rkeys["spawnflags"] = "" + (1 | 4 | 8 | 64);
			rkeys["renderamt"] = isSpectre ? "32" : "255";
			CBaseEntity@ show = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			renderShowEnts.insertLast(EHandle(show));
			
			rkeys["renderamt"] = "0";
			CBaseEntity@ hide = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			renderHideEnts.insertLast(EHandle(hide));
		}
		
		g_EntityFuncs.SetSize(self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
		self.SetClassification(CLASS_ALIEN_MONSTER);
		SetActivity(ANIM_IDLE);
		
		//g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -30), Vector(8, 8, 42));
		g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -16), Vector(8, 8, 42));
	}
	
	void SetActivity(int act)
	{
		if (act < 0 or act >= int(animInfo.length()))
			println("Bad activity: " + act);
		else
			currentAnim = animInfo[act];
		
		//println("ACT " + activity);
		animLoops = 0;
		oldFrameCounter = frameCounter = 0;
		activity = act;
	}
	
	void Wakeup()
	{
		if (!dormant)
			return;
		SetActivity(ANIM_MOVE);
		//println("IM AWAKE");
		if (alertSounds.length() > 0)
		{
			string snd = alertSounds[Math.RandomLong(0, alertSounds.size()-1)];
			g_SoundSystem.PlaySound(self.edict(), CHAN_BODY, snd, 1.0f, 0.5f, 0, 100);
		}
						
		dormant = false;
		nextIdleSound = g_Engine.time + Math.RandomFloat(5.0f, 10.0f);
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if (!self.IsAlive() or flDamage == 0)
			return 0;
		pev.health -= flDamage;
		if (pev.health <= 0)
		{
			g_EntityFuncs.SetModel(self, bodySprite);
			killClientSprites();
			pev.renderamt = 255;
			pev.rendermode = 2;
			if (isSpectre)
			{
				pev.renderamt = 32;
				pev.rendercolor = Vector(1, 1, 1);
			}
			pev.solid = SOLID_NOT;
			bool gib = (bitsDamageType & DMG_BLAST) != 0 or pev.health < -100;
			SetActivity(gib ? ANIM_GIB : ANIM_DEAD);
			h_enemy = null;
			pev.deadflag = DEAD_DYING;
			
			if (canFly and deathBoom == 0)
			{
				pev.movetype = MOVETYPE_TOSS;
				pev.velocity.z = -0.1f;
			}
			g_EntityFuncs.SetSize(self.pev, Vector(-1, -1, -1), Vector(1, 1, 1));
			
			string snd = deathSounds[Math.RandomLong(0, deathSounds.size()-1)];
			if (gib)
				snd = "doom/DSSLOP.wav";
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, snd, 1.0f, 0.5f, 0, 100);
		}
		else
		{
			if (Math.RandomFloat(0, 1) <= painChance)
			{
				SetActivity(ANIM_PAIN);
				g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, painSound, 1.0f, 0.5f, 0, 100);
			}
			
			CBaseEntity@ attacker = g_EntityFuncs.Instance(pevAttacker.get_pContainingEntity());
			SetEnemy( attacker );
		}
		
		return 0;
	}
	
	void SetEnemy(CBaseEntity@ ent)
	{
		if (!ent.IsAlive() or (ent.pev.flags & FL_NOTARGET) != 0 or ent.entindex() == self.entindex())
			return;
		// only switch targets after chasing current one for a while
		if (!h_enemy.IsValid() or lastEnemy + 1.0f < g_Engine.time)
		{
			oldEnemy = h_enemy;
			if (oldEnemy)
				println("I will remember to attack " + oldEnemy.GetEntity().pev.classname);
			h_enemy = EHandle(ent);
			lastEnemy = g_Engine.time;
			Wakeup();
		}
	}
	
	void ClearEnemy()
	{
		h_enemy = oldEnemy;
		if (h_enemy)
			println("I will go back to attacking " + h_enemy.GetEntity().pev.classname);
		oldEnemy = null;
		if (!h_enemy.IsValid())
			Sleep();
	}
	
	void Sleep()
	{
		if (dormant)
			return;
			
		h_enemy = null;
		dormant = true;
		SetActivity(ANIM_IDLE);
	}
	
	Vector BodyPos()
	{
		return pev.origin + Vector(0,0,36*g_world_scale);
	}
	
	void RangeAttack(Vector aimDir)
	{
		println("Range attack not implemented!");
	}
	
	void MeleeAttack(Vector aimDir)
	{
		println("Melee attack not implemented!");
	}
	
	void ShootBullet(Vector dir, float spread, float damage, bool flash=true)
	{
		Vector vecSrc = BodyPos();
		float range = 16384;
		
		if (flash)
		{
			int flash_size = 20;
			int flash_life = 1;
			int flash_decay = 0;
			Color flash_color = Color(255, 160, 64);
			te_dlight(vecSrc, flash_size, flash_color, flash_life, flash_decay);
			brighten = 4;
		}
		
		Vector vecAiming = spreadDir(dir.Normalize(), spread, SPREAD_GAUSSIAN);
	
		// Do the bullet collision
		TraceResult tr;
		Vector vecEnd = vecSrc + vecAiming * range;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		// do more fancy effects
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit !is null ) 
				{			
					
					CBaseEntity@ ent = g_EntityFuncs.Instance( tr.pHit );
						
					Vector attackDir = (tr.vecEndPos - vecSrc).Normalize();
					Vector angles = Math.VecToAngles(attackDir);
					Math.MakeVectors(angles);
						
					// damage done before hitgroup multipliers
					
					g_WeaponFuncs.ClearMultiDamage(); // fixes TraceAttack() crash for some reason
					pHit.TraceAttack(self.pev, damage, attackDir, tr, DMG_BULLET);
					
					Vector oldVel = pHit.pev.velocity;
					
					// set both classes in case this a pvp map where classes are always changing
					int oldClass1 = self.GetClassification(0);
					int oldClass2 = pHit.GetClassification(0);
					self.SetClassification(CLASS_PLAYER);
					pHit.SetClassification(CLASS_ALIEN_MILITARY);
					
					g_WeaponFuncs.ApplyMultiDamage(self.pev, self.pev);
					
					self.SetClassification(oldClass1);
					pHit.SetClassification(oldClass2);
					
					pHit.pev.velocity = oldVel; // prevent high damage from launching unless we ask for it (unless DMG_LAUNCH)

					knockBack(pHit, g_Engine.v_forward*(100+damage)*g_world_scale);
					
					if (pHit.IsBSPModel()) 
					{
						//te_gunshotdecal(tr.vecEndPos, pHit, getDecal(DECAL_SMALLSHOT));
						te_decal(tr.vecEndPos, pHit, getDecal(DECAL_SMALLSHOT));
					}
				}
			}
		}
		
		// bullet tracer effects
		te_tracer(vecSrc, tr.vecEndPos);
	}

	bool Slash(Vector dir, float damage)
	{
		Vector bodyPos = BodyPos();
		TraceResult tr;
		Vector attackDir = dir.Normalize();
		g_Utility.TraceHull( bodyPos, bodyPos + attackDir*meleeRange*g_world_scale, dont_ignore_monsters, head_hull, self.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		//te_beampoints(bodyPos, bodyPos + delta.Normalize()*meleeRange);
		
		if (phit !is null)
		{
			g_WeaponFuncs.ClearMultiDamage();
			phit.TraceAttack(pev, damage, attackDir, tr, DMG_SLASH);
			g_WeaponFuncs.ApplyMultiDamage(self.pev, self.pev);
			knockBack(phit, attackDir*(100+damage)*g_world_scale);
			return true;
		}
		return false;
	}
	
	void Dash(Vector velocity, float damage, float timeout)
	{
		dashVel = velocity;
		dashing = true;
		dashDamage = damage;
		dashTimeout = g_Engine.time + timeout;
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
	
	void DoomThink()
	{
		//te_beampoints(pev.origin, pev.origin + Vector(0,0,72));
		
		if (isCorpse)
		{
			g_EntityFuncs.Remove(self);			
			return;
		}
		
		int light_level = 255;
		if (!fullBright)
		{
			light_level = self.Illumination() + 32;
			if (brighten > 0)
			{
				brighten--;
				light_level += brighten*64;
				if (light_level > 255)
					light_level = 255;
			}
			//light_level = 255;
		}
		Vector lightColor = Vector(light_level, light_level, light_level);
		
		//pev.rendercolor = lightColor;
		//println("LIGHT " + g_EngineFuncs.GetEntityIllum(self.edict()) + " " + pev.light_level);
		
		pev.velocity.z += -0.001f; // prevents floating and fixes fireballs not getting Touched by monsters that don't move
		
		//println("CURENT ANIM: " + currentAnim.frameIndices[0] + " " + currentAnim.lastFrame());
		frameCounter += 1;
		bool looped = false;
		int frameIdx = currentAnim.getFrameIdx(frameCounter, oldFrameCounter, looped);
		int frame = currentAnim.frameIndices[frameIdx];

		if (looped)
			animLoops += 1;
		
		if (activity == ANIM_MOVE and walkSound.Length() > 0 and nextWalkSound < g_Engine.time)
		{
			nextWalkSound = g_Engine.time + walkSoundFreq;
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, walkSound, 1.0f, 0.5f, 0, 100);
		}
		
		//println("FRAME " + frame + " " + currentAnim.minFrame + " " + currentAnim.maxFrame);
	
		g_EngineFuncs.MakeVectors(pev.angles);
		Vector forward = g_Engine.v_forward;
		Vector right = g_Engine.v_right;
		forward.z = 0;
		right.z = 0;
		forward = forward.Normalize();
		right = right.Normalize();
		
		if (activity == ANIM_PAIN and animLoops > 3)
			SetActivity(ANIM_MOVE);
		
		if (pev.health > 0)
			pev.deadflag = 0;
		
		if (!self.IsAlive())
		{
			if (looped)
			{
				isCorpse = true;
				pev.frame = currentAnim.lastFrame();
				if (deathBoom > 0)
				{
					g_EntityFuncs.Remove(self);
					return;
				}
				pev.nextthink = g_Engine.time + deathRemoveDelay;
				return;
			}
			else
				pev.frame = frame;
			pev.rendercolor = lightColor;
		}
		
		if (!dormant and self.IsAlive())
		{
			Vector bodyPos = BodyPos();
			
			if (dashing and g_Engine.time > dashTimeout)
			{
				dashing = false;
				SetActivity(ANIM_MOVE);
			}
			
			if (activity == ANIM_MOVE or dashing)
			{
				int canWalk = 0;
				
				Vector verticalMove = Vector(0,0,0);					
				if (canFly and h_enemy.IsValid())
				{
					CBaseEntity@ enemy = h_enemy;
					if (enemy.pev.origin.z > bodyPos.z + 36)
						verticalMove = Vector(0,0,4);
					else if (enemy.pev.origin.z < bodyPos.z - 36)
						verticalMove = Vector(0,0,-4);
				}
				else if (false)
					canWalk = g_EngineFuncs.WalkMove(self.edict(), pev.angles.y, walkSpeed*g_monster_scale, int(WALKMOVE_NORMAL));
					
				if (canWalk != 1)
				{
					TraceResult tr;
					Vector moveVel = forward*walkSpeed + verticalMove;
					if (dashing)
						moveVel = dashVel;
					Vector hullPos = bodyPos;
					g_Utility.TraceHull( hullPos, hullPos + moveVel*g_monster_scale, dont_ignore_monsters, human_hull, self.edict(), tr );
					if (tr.fAllSolid != 0)
						println("ALL SOLID");
						
					//te_beampoints(hullPos, hullPos + moveVel*g_monster_scale);
					te_beampoints(hullPos + Vector(0,0,36*g_world_scale), hullPos + Vector(0,0,36*g_world_scale) + moveVel*g_monster_scale);
					te_beampoints(hullPos + Vector(0,0,-36*g_world_scale), hullPos + Vector(0,0,-36*g_world_scale) + moveVel*g_monster_scale);
					
					if (tr.flFraction >= 1.0f and tr.fAllSolid == 0)
					{
						// walkmove doesn't like stepping down things, but this is a legal move
						Vector stepPos = tr.vecEndPos;
						// TODO: Don't step if this is actually a cliff
						pev.origin = stepPos + Vector(0,0,-36*g_world_scale);
						if (!dashing and canFly)
							pev.velocity = pev.velocity*0.1f;
						//pev.origin = stepPos + Vector(0,0,8);
					}
					else
					{
						if (dashing)
						{
							dashing = false;
							CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
							if (pHit !is null)
							{
								nextRangeAttack = g_Engine.time + Math.RandomFloat(minRangeAttackDelay, maxRangeAttackDelay);
								Vector oldVel = pHit.pev.velocity;
								pHit.TakeDamage(self.pev, self.pev, dashDamage, DMG_BURN);
								pHit.pev.velocity = oldVel; // prevent vertical launching
								
								knockBack(pHit, dashVel.Normalize()*(100 + dashDamage)*g_world_scale);
							}
						}
						if (lastWallReflect + 0.2f < g_Engine.time)
						{
							pev.angles.y += Math.RandomFloat(90, 270);
							lastWallReflect = g_Engine.time;
							lastDirChange = g_Engine.time;
						}
					}
				}
			}
			
			if (h_enemy and h_enemy.GetEntity().pev.flags & FL_NOTARGET != 0)
				ClearEnemy();
		
			if (h_enemy.IsValid() and !dashing)
			{
				CBaseEntity@ enemy = h_enemy;
				
				Vector enemyPos = enemy.pev.origin;
				if (!enemy.IsPlayer())
				{
					if (g_world_scale == 1)
						enemyPos.z += (enemy.pev.maxs.z - enemy.pev.mins.z)*0.5f;
					else
						enemyPos.z += 36*g_world_scale;
				}
				Vector delta = enemyPos - bodyPos;
				if (activity == ANIM_MOVE and lastDirChange + 1.0f < g_Engine.time)
				{
					float idealYaw = g_EngineFuncs.VecToYaw(delta);
					pev.angles.y = idealYaw;
					if (Math.RandomLong(0,3) <= 1) // zig zag towards target
					{
						if (Math.RandomLong(0,1) == 0)
							pev.angles.y += 45;
						else
							pev.angles.y -= 45;
					}
					
					lastDirChange = g_Engine.time;
				}
				
				bool inMeleeRange = hasMelee and delta.Length() < meleeRange*g_world_scale;
				if (activity == ANIM_ATTACK or inMeleeRange or (nextRangeAttack < g_Engine.time and hasRanged))
				{
					pev.angles.y = g_EngineFuncs.VecToYaw(delta);
					if (activity != ANIM_ATTACK)
					{
						SetActivity(ANIM_ATTACK);
					}
					else
					{
						if ((frameIdx == currentAnim.attackFrameIdx or currentAnim.attackFrameIdx == -1) and oldFrameIdx != frameIdx)
						{
							if (inMeleeRange)
								MeleeAttack(delta);
							else if (hasRanged)			
							{
								te_beampoints(bodyPos, enemyPos);
								RangeAttack(delta);
							}
						}
						
						if (animLoops > 0)
						{
							if (inMeleeRange)
								SetActivity(ANIM_ATTACK);
							else
							{
								bool keepAttacking = false;
								if (constantAttack and (animLoops < constantAttackMax or constantAttackMax == 0))
								{
									TraceResult tr;
									g_Utility.TraceLine( bodyPos, enemy.pev.origin, dont_ignore_monsters, self.edict(), tr );
									CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
									keepAttacking = pHit !is null and pHit.entindex() == enemy.entindex();
									
								}
								if (!keepAttacking)
								{
									nextRangeAttack = g_Engine.time + Math.RandomFloat(minRangeAttackDelay, maxRangeAttackDelay);
									SetActivity(ANIM_MOVE);
								}
							}
						}
					}
				}
				
				if (!enemy.IsAlive())
					ClearEnemy();
			}
			
			if (nextIdleSound < g_Engine.time)
			{
				string snd = idleSounds[Math.RandomLong(0, idleSounds.size()-1)];
				g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, snd, 1.0f, 0.5f, 0, 100);
				nextIdleSound = g_Engine.time + Math.RandomFloat(5.0f, 10.0f);
			}
		}
		
		// render sprite for each player
		if (self.IsAlive())
		{
			CBaseEntity@ ent = null;
			do {
				@ent = g_EntityFuncs.FindEntityByClassname(ent, "player");
				if (ent !is null)
				{
					Vector pos = pev.origin + Vector(0,0,0);
					
					Vector delta = pos - ent.pev.origin;
					delta = delta.Normalize();
					int angleIdx = getSpriteAngle(pos, forward, right, ent.pev.origin);
						
					if (dormant and ent.IsAlive() and DotProduct(forward, delta) < -0.3f and ent.FVisible(self, true))
						SetEnemy(ent);
					
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
					client_sprite.pev.origin = pev.origin;
					client_sprite.pev.frame = frame*8 + i;
					if (!isSpectre)
						client_sprite.pev.rendercolor = lightColor;
				}
				else
					client_sprite.pev.effects |= EF_NODRAW;
				
			}
		}
		
		// react to sounds
		if (dormant and false)
		{
			CSoundEnt@ sndent = GetSoundEntInstance();
			int activeList = sndent.ActiveList();
			while (activeList > -1)
			{
				CSound@ snd = sndent.SoundPointerForIndex(activeList);
				if (snd is null)
					break;
				CBaseEntity@ owner = snd.hOwner;
				if (snd.m_iVolume > 0)
				{
					Vector delta = snd.m_vecOrigin - pev.origin;
					if (delta.Length() < snd.m_iVolume)
					{
						delta.z = 0;
						g_EngineFuncs.VecToAngles(delta.Normalize(), pev.angles);
					}
				}
					
				activeList = snd.m_iNext;
			}
		}
		
		oldFrameCounter = frameCounter;
		oldFrameIdx = frameIdx;
		pev.nextthink = g_Engine.time + 0.0572;
		//pev.nextthink = g_Engine.time + 0.02857;
	}
};
