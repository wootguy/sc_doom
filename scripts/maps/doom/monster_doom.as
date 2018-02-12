#include "utils"
#include "fireball"

enum activities {
	ANIM_IDLE,
	ANIM_MOVE,
	ANIM_ATTACK,
	ANIM_ATTACK2, // range attack
	ANIM_PAIN,
	ANIM_DEAD,
	ANIM_GIB,
}

array<string> light_suffix = {"_L3", "_L2", "_L1", "_L0"};

float g_monster_scale = 1.42857f; // 1 / 0.7
float g_world_scale = 1.0f;
float g_monster_center_z = 34;
float g_monster_think_delay = 0.0572f;

int FL_MONSTER_DEAF = 8;

class AnimInfo
{
	float framerate;
	bool looped;
	array<int> frameIndices;
	array<int> attackFrames; // frame index where attack is called (-1 = every frame)
	
	AnimInfo() {}
	
	AnimInfo(int min, int max, float rate, bool loop)
	{
		this.framerate = rate;
		this.looped = loop;
		this.attackFrames.insertLast(max - min);
		
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
	
	bool isAttackFrame(int idx)
	{
		for (uint i = 0; i < attackFrames.length(); i++)
		{
			if (attackFrames[i] == idx)
				return true;
		}
		return false;
	}
	
	int lastFrame()
	{
		return frameIndices[frameIndices.length()-1];
	}
}

uint g_monster_idx = 0;
float g_stagger_think = 0;

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
	int constantAttackLoopFrame = 0; // restart at this frame when attacking again
	bool rangeWhenMeleeFails = true; // do a range attack if the melee attack fails
	float deathBoom = 0;
	bool didDeathBoom = false;
	string dropItem; // item spawned on death
	string hullModel = "models/doom/null.mdl"; // model used for hitboxes
	bool isDeaf; // doesn't target player when heard unless in line of sight
	
	uint frameCounter = 0;
	uint oldFrameCounter = 0;
	int animLoops = 0;
	int oldFrameIdx = 0;
	int dmgImmunity = 0;
	
	float walkSpeed = 8.0f;
	float painChance = 1.0f;
	float meleeRange = 64.0f*g_monster_scale;
	float minRangeAttackDelay = 1.0f;
	float maxRangeAttackDelay = 3.0f;
	float walkSoundFreq = 0.6f;
	
	float nextWalkSound = 0;
	float nextRangeAttack = 0;
	float lastWallReflect = 0;
	float lastDirChange = 0;
	float lastEnemy = 0;
	float deathRemoveDelay = 60.0f; // time before entity is destroyed after death
	float nextIdleSound = 0;
	bool dormant = true;
	bool superDormant = true; // not even loaded yet
	bool isCorpse = false;
	uint brighten = 0; // if > 0 then draw full-bright. Decremented each frame
	bool dashing = false;
	Vector dashVel;
	float dashDamage = 0;
	float dashTimeout = 0;
	bool largeHull = false;
	Vector gunPos = Vector(0,0,8); // offset relative to body position
	
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
	string meleeWindupSound;
	string shootSound;
	string walkSound;
	
	dictionary plrViewAngles; // maps player to view angle
	
	SoundNode@ dormantNode = null; // save this to reduce CPU usage
	Vector lastDormantPos;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "spectre") isSpectre = atoi(szValue) != 0;
		if (szKey == "doom_flags") isDeaf = (atoi(szValue) & FL_MONSTER_DEAF) != 0;
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
		PrecacheSound(meleeWindupSound);
		PrecacheSound(meleeSound);
		PrecacheSound(shootSound);
		PrecacheSound(painSound);
		PrecacheSound(walkSound);
		PrecacheSound("doom/DSSLOP.wav");
		g_Game.PrecacheModel(bodySprite);
		g_Game.PrecacheModel(hullModel);
	}
	
	void DoomTouched(CBaseEntity@ ent)
	{
		//println("ZOMG TOUCHED " + ent.pev.classname);
	}
	
	void DelayAttack()
	{
		nextRangeAttack = g_Engine.time + Math.RandomFloat(minRangeAttackDelay, maxRangeAttackDelay);
	}
	
	void DoomSpawn()
	{
		Precache();
		
		pev.movetype = canFly ? MOVETYPE_FLY : MOVETYPE_STEP;
		pev.solid = SOLID_NOT;
		
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		g_EntityFuncs.SetModel(self, hullModel);
		//g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 72));
		
		self.m_bloodColor = BLOOD_COLOR_RED;
		self.pev.scale = g_monster_scale;
		pev.takedamage = DAMAGE_YES;
		pev.flags |= FL_MONSTERCLIP;
		
		self.MonsterInit();
		
		g_EntityFuncs.SetSize(self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
		self.SetClassification(CLASS_ALIEN_MONSTER);
		SetActivity(ANIM_IDLE);
		
		pev.view_ofs = Vector(0,0,28);
		
		if (canFly)
			pev.origin.z -= 16;
		
		//g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -30), Vector(8, 8, 42));
		if (largeHull)
		{
			//g_EntityFuncs.SetSize(self.pev, Vector(-32, -32, -7), Vector(32, 32, 42));
			g_EntityFuncs.SetSize(self.pev, Vector(-32, -32, -7), Vector(32, 32, 72));
		}
		else
		{
			g_EntityFuncs.SetSize(self.pev, Vector(-12, -12, -7), Vector(12, 12, 42));
		}
		
	}
	
	void Setup()
	{
		superDormant = false;
		pev.solid = SOLID_SLIDEBOX;
		CreateRenderSprites();
		pev.nextthink = g_Engine.time + g_stagger_think;

		g_stagger_think += 0.01f;
		if (g_stagger_think >= g_monster_think_delay)
			g_stagger_think = 0;
			
		lastDormantPos = pev.origin;
		@dormantNode = getSoundNode(pev.origin);
	}
	
	void CreateRenderSprites()
	{
		for (uint i = 0; i < 8; i++)
		{
			dictionary ckeys;
			ckeys["origin"] = pev.origin.ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
			ckeys["model"] = bodySprite;
			ckeys["spawnflags"] = "1";
			ckeys["rendermode"] = "2";
			ckeys["renderamt"] = "0";
			ckeys["rendercolor"] = "255 255 255";
			ckeys["scale"] = string(pev.scale);
			ckeys["targetname"] = "m" + g_monster_idx + "s" + i;
			CBaseEntity@ client_sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
			//println("MAKE LE SPRITE " + client_sprite.pev.targetname);
			g_EntityFuncs.SetOrigin(client_sprite, pev.origin);
			sprites.insertLast(EHandle(client_sprite));

			dictionary rkeys;
			rkeys["target"] = string(client_sprite.pev.targetname);
			rkeys["spawnflags"] = "" + (1 | 4 | 8 | 64);
			rkeys["renderamt"] = isSpectre ? "48" : "255";
			CBaseEntity@ show = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			g_EntityFuncs.SetOrigin(show, pev.origin);
			renderShowEnts.insertLast(EHandle(show));
			
			rkeys["renderamt"] = "0";
			CBaseEntity@ hide = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			g_EntityFuncs.SetOrigin(hide, pev.origin);
			renderHideEnts.insertLast(EHandle(hide));
		}
		
		g_monster_idx++;
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
			g_SoundSystem.PlaySound(self.edict(), CHAN_BODY, snd, 1.0f, 1.0f, 0, 100);
		}
		
		dormant = false;
		nextIdleSound = g_Engine.time + Math.RandomFloat(5.0f, 10.0f);
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if (!self.IsAlive() or flDamage == 0)
			return 0;
		if (dmgImmunity & bitsDamageType != 0)
			return 0;
		
		pev.health -= flDamage;
		if (pev.health <= 0)
		{
			if (self.m_iTriggerCondition == 4)
				g_EntityFuncs.FireTargets(self.m_iszTriggerTarget, null, null, USE_TOGGLE);
			
			g_EntityFuncs.SetModel(self, bodySprite);
			killClientSprites();
			pev.renderamt = 255;
			pev.rendermode = 2;
			if (isSpectre)
			{
				pev.renderamt = 48;
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
			
			if (dropItem.Length() > 0)
			{
				Vector delta = (pevAttacker.origin - pev.origin).Normalize()*32;
				dictionary keys;
				keys["origin"] = (pev.origin + Vector(0,0,8)).ToString();
				keys["velocity"] = Vector(delta.x,delta.y,512).ToString();
				g_EntityFuncs.CreateEntity(dropItem, keys, true);
			}
			
			g_kills += 1;
			
			string snd = deathSounds[Math.RandomLong(0, deathSounds.size()-1)];
			bool canGib = animInfo[ANIM_DEAD].frameIndices[0] != animInfo[ANIM_GIB].frameIndices[0];
			if (gib and canGib)
				snd = "doom/DSSLOP.wav";
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, snd, 1.0f, 0.5f, 0, 100);
			
			DoomThink();
		}
		else
		{
			if (Math.RandomFloat(0, 1) <= painChance)
			{
				SetActivity(ANIM_PAIN);
				//DelayAttack();
				g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, painSound, 1.0f, 0.5f, 0, 100);
			}
			
			CBaseEntity@ attacker = g_EntityFuncs.Instance(pevAttacker.get_pContainingEntity());
			SetEnemy( attacker );
		}
		
		return 0;
	}
	
	void SetEnemy(CBaseEntity@ ent)
	{
		if (ent is null or !ent.IsAlive() or (ent.pev.flags & FL_NOTARGET) != 0 or ent.entindex() == self.entindex())
			return;
		// only switch targets after chasing current one for a while
		if (!h_enemy.IsValid() or lastEnemy + 10.0f < g_Engine.time)
		{
			if (h_enemy.IsValid() and h_enemy.GetEntity().IsPlayer())
				oldEnemy = h_enemy;
			//if (oldEnemy)
			//	println("I will remember to attack " + oldEnemy.GetEntity().pev.netname);
			h_enemy = EHandle(ent);
			lastEnemy = g_Engine.time;
			DelayAttack();
			Wakeup();
		}
	}
	
	void ClearEnemy()
	{
		h_enemy = oldEnemy;
		//if (h_enemy)
		//	println("I will go back to attacking " + h_enemy.GetEntity().pev.classname);
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
		return pev.origin + Vector(0,0,g_monster_center_z*g_world_scale);
	}
	
	void RangeAttack(Vector aimDir)
	{
		println("Range attack not implemented!");
	}
	
	void MeleeAttackStart() {}
	
	void RangeAttackStart() {}
	
	void MeleeAttack(Vector aimDir)
	{
		println("Melee attack not implemented!");
	}
	
	void ShootBullet(Vector dir, float spread, float damage, bool flash=true)
	{
		Vector vecSrc = BodyPos() + gunPos;
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
	
		//te_beampoints(vecSrc, vecSrc + dir.Normalize()*range);
	
		HitScan(self, vecSrc, dir, spread, damage);
	}

	bool Slash(Vector dir, float damage)
	{
		Vector bodyPos = BodyPos() + gunPos;
		TraceResult tr;
		Vector attackDir = dir.Normalize();
		g_Utility.TraceHull( bodyPos, bodyPos + attackDir*meleeRange*g_world_scale, dont_ignore_monsters, head_hull, self.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		//te_beampoints(bodyPos, bodyPos + delta.Normalize()*meleeRange);
		
		if (phit !is null)
		{
			g_WeaponFuncs.ClearMultiDamage();
			TraceAttack(phit, pev, damage, attackDir, tr, DMG_SLASH);
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
	
	bool isAttacking()
	{
		return activity == ANIM_ATTACK || activity == ANIM_ATTACK2;
	}
	
	void DeathBoom() {}
	
	void DoomThink()
	{
		if (superDormant)
			return;
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
		
		//pev.velocity.z += -0.001f; // prevents floating and fixes fireballs not getting Touched by monsters that don't move
		g_EntityFuncs.SetOrigin(self, pev.origin);
		
		//println("CURENT ANIM: " + currentAnim.frameIndices[0] + " " + currentAnim.lastFrame());
		
		frameCounter += 1;
		bool looped = false;
		int frameIdx = currentAnim.getFrameIdx(frameCounter, oldFrameCounter, looped);
		int frame = currentAnim.frameIndices[frameIdx];

		if (looped)
		{
			if (isAttacking() and constantAttack)
			{
				// increment frame until we get to the one we want
				int failsafe = 256;
				while (frameIdx != constantAttackLoopFrame)
				{
					frameCounter += 1;
					frameIdx = currentAnim.getFrameIdx(frameCounter, oldFrameCounter, looped);
					frame = currentAnim.frameIndices[frameIdx];
					failsafe -= 1;
					if (failsafe <= 0)
					{
						println("FAILED TO FIND CONSTANT ATTACK FRAME");
						break;
					}
				}
				looped = true;
			}
			animLoops += 1;
		}
		
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
			{
				pev.frame = frame;
				if (deathBoom > 0 and frameIdx == deathBoom and !didDeathBoom)
				{
					didDeathBoom = true;
					DeathBoom();
				}
			}
			pev.rendercolor = lightColor;
		}
		
		if (!dormant and self.IsAlive())
		{
			Vector bodyPos = BodyPos();
			
			if (dashing)
			{
				if (g_Engine.time > dashTimeout)
				{
					dashing = false;
					SetActivity(ANIM_MOVE);
				}
				else if (activity != ANIM_ATTACK)
					SetActivity(ANIM_ATTACK);
			}
			
			
			Vector eyePos = pev.origin + pev.view_ofs;
			bool lineOfSight = false;
			if (h_enemy.IsValid())
			{
				CBaseEntity@ enemy = h_enemy;
				TraceResult tr_sight;
				g_Utility.TraceLine( eyePos, enemy.pev.origin, ignore_monsters, self.edict(), tr_sight );
				lineOfSight = tr_sight.flFraction >= 1.0f;
			}
			
			
			if (activity == ANIM_MOVE or dashing)
			{
				int canWalk = 0;
				
				Vector verticalMove = Vector(0,0,0);					
				if (canFly)
				{
					if (h_enemy.IsValid())
					{
						CBaseEntity@ enemy = h_enemy;
						
						//println("HEIGHT DIFF: " + (enemy.pev.origin.z - bodyPos.z));
						
						float enemyZ = enemy.pev.origin.z + enemy.pev.view_ofs.z;
						if (enemyZ > bodyPos.z + g_monster_center_z or !lineOfSight)
							verticalMove = Vector(0,0,4);
						else if (enemyZ < bodyPos.z - g_monster_center_z)
							verticalMove = Vector(0,0,-4);
					}
						
					TraceResult tVert;
					g_Utility.TraceHull( bodyPos, bodyPos + verticalMove*2, dont_ignore_monsters, human_hull, self.edict(), tVert );
					if (tVert.flFraction < 1.0f)
					{
						verticalMove = Vector(0,0,0);
						//println("NOT OK TO MOVE VERT");
					}
					else
					{
						//println("OK TO MOVE VERT");
					}
					
					TraceResult tr;
					Vector moveVel = forward*walkSpeed + verticalMove;
					if (dashing)
						moveVel = dashVel;
					Vector targetPos = bodyPos + moveVel*g_monster_scale;
					g_Utility.TraceHull( bodyPos, targetPos, dont_ignore_monsters, human_hull, self.edict(), tr );
					if (tr.flFraction >= 1.0f and tr.fAllSolid == 0)
					{
						canWalk = 1;
						Vector flyPos = tr.vecEndPos + Vector(0,0,-g_monster_center_z);
						g_EntityFuncs.SetOrigin(self, flyPos);
					}
					else if (dashing)
					{
						dashing = false;
						SetActivity(ANIM_MOVE);
						CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
						if (pHit !is null)
						{
							DelayAttack();
							Vector oldVel = pHit.pev.velocity;
							doomTakeDamage(pHit, self.pev, self.pev, dashDamage, DMG_BURN);
							pHit.pev.velocity = oldVel; // prevent vertical launching
							
							knockBack(pHit, dashVel.Normalize()*(100 + dashDamage)*g_world_scale);
						}
					}
				}
				else
				{
					canWalk = g_EngineFuncs.WalkMove(self.edict(), pev.angles.y, walkSpeed*g_monster_scale, int(WALKMOVE_NORMAL));
				}
				
				if (canWalk != 1)
				{
					TraceResult tr;
					
					TraceResult tr_fall;
					Vector moveVel = forward*walkSpeed + verticalMove;
					
					Vector targetPos = bodyPos + moveVel*g_monster_scale;
					g_Utility.TraceHull( bodyPos, targetPos, dont_ignore_monsters, human_hull, self.edict(), tr );
					
					g_Utility.TraceHull( bodyPos, bodyPos + Vector(0,0,-0.1f), dont_ignore_monsters, human_hull, self.edict(), tr_fall );
					if (tr.fAllSolid != 0)
					{
						//te_beampoints(bodyPos, targetPos);
						//println("ALL SOLID");
					}
						
					//if (tr_fall.flFraction >= 1.0f and pev.velocity.z == 0)
					//	pev.velocity.z = -0.1f;
						
					//te_beampoints(bodyPos, bodyPos + moveVel*g_monster_scale);
					//te_beampoints(bodyPos + Vector(0,0,g_monster_center_z*g_world_scale), bodyPos + Vector(0,0,g_monster_center_z*g_world_scale) + moveVel*g_monster_scale);
					//te_beampoints(bodyPos + Vector(0,0,-g_monster_center_z*g_world_scale), bodyPos + Vector(0,0,-g_monster_center_z*g_world_scale) + moveVel*g_monster_scale);
									
					
					if (lastWallReflect + 0.2f < g_Engine.time)
					{
						pev.angles.y += Math.RandomFloat(90, 270);
						lastWallReflect = g_Engine.time;
						lastDirChange = g_Engine.time;
					}
				}
			}
			
			if (h_enemy and h_enemy.GetEntity().pev.flags & FL_NOTARGET != 0)
				ClearEnemy();
		
			if (h_enemy.IsValid() and !dashing)
			{
				CBaseEntity@ enemy = h_enemy;
				
				Vector enemyPos = enemy.pev.origin + enemy.pev.view_ofs;
				if (!enemy.IsPlayer())
				{
					if (g_world_scale == 1)
						enemyPos.z += (enemy.pev.maxs.z - enemy.pev.mins.z)*0.5f;
					else
						enemyPos.z += g_monster_center_z*g_world_scale;
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
				
				if (nextRangeAttack + 0.5f < g_Engine.time)
					DelayAttack(); // don't attack immediately when enemy comes back into view
				
				if (isAttacking() or inMeleeRange or (nextRangeAttack < g_Engine.time and hasRanged and lineOfSight))
				{
					pev.angles.y = g_EngineFuncs.VecToYaw(delta);
					if (!isAttacking())
					{
						if (inMeleeRange)
						{
							if (meleeWindupSound.Length() > 0)
								g_SoundSystem.PlaySound(self.edict(), CHAN_BODY, meleeWindupSound, 1.0f, 0.5f, 0, 100);
							SetActivity(ANIM_ATTACK);
							MeleeAttackStart();
						}
						else
						{
							SetActivity(ANIM_ATTACK2);
							RangeAttackStart();
						}
					}
					else
					{
						if ((currentAnim.isAttackFrame(frameIdx)) and oldFrameIdx != frameIdx)
						{
							if (inMeleeRange)
								MeleeAttack(delta);
							else if (hasRanged)			
							{
								//te_beampoints(bodyPos, enemyPos);		
								if (rangeWhenMeleeFails or activity == ANIM_ATTACK2)
									RangeAttack(delta);
							}
						}
						
						if (animLoops > 0)
						{
							if (inMeleeRange)
							{
								if (meleeWindupSound.Length() > 0)
									g_SoundSystem.PlaySound(self.edict(), CHAN_BODY, meleeWindupSound, 1.0f, 0.5f, 0, 100);
								SetActivity(ANIM_ATTACK);
							}
							else
							{
								bool keepAttacking = false;
								if (constantAttack and (animLoops < constantAttackMax or constantAttackMax == 0))
								{
									TraceResult tr;
									g_Utility.TraceLine( eyePos, enemy.pev.origin, dont_ignore_monsters, self.edict(), tr );
									CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
									keepAttacking = pHit !is null and pHit.entindex() == enemy.entindex();
								}
								if (!keepAttacking)
								{
									DelayAttack();
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
		bool visibleToAnyone = false;
		if (self.IsAlive())
		{			
			edict_t@ edt = g_EngineFuncs.FindClientInPVS(self.edict());
			while (edt !is null)
			{
				CBasePlayer@ plr = cast<CBasePlayer@>(g_EntityFuncs.Instance( edt ));
				if (plr !is null)
				{
					@edt = @plr.pev.chain;
					visibleToAnyone = true;
					
					int angleIdx = getSpriteAngle(pev.origin, forward, right, plr.pev.origin);
						
					if (!h_enemy.IsValid() and plr.IsAlive())
					{
						Vector delta = pev.origin - plr.pev.origin;
						delta = delta.Normalize();
						if (DotProduct(forward, delta) < -0.3f and plr.FVisible(self, true))
						{
							bool visible = true;
							PlayerState@ state = getPlayerState(plr);
							visible = plr.pev.rendermode == 0 or state.lastAttack + 1.0f > g_Engine.time;
							visible = visible and g_EngineFuncs.PointContents(plr.pev.origin) != CONTENTS_SOLID;

							if (visible)
								SetEnemy(plr);
						}
					}
					
					string steamId = getSteamID(plr);
					PlayerState@ state = getPlayerState(plr);
					
					int lastAngle = -1;
					if (plrViewAngles.exists(steamId))
						plrViewAngles.get(steamId, lastAngle);
					plrViewAngles[steamId] = angleIdx;
					
					if (lastAngle == angleIdx)
						continue;
					
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
								renderent.Use(plr, plr, USE_TOGGLE);
								state.addVisibleEnt(client_sprite.pev.targetname, EHandle(client_sprite));
							}
							else
							{
								CBaseEntity@ renderent = renderHideEnts[i];
								renderent.Use(plr, plr, USE_TOGGLE);
								state.hideVisibleEnt(client_sprite.pev.targetname);
							}
						}
					}
				}
				else
					break;
			}
			
			if (visibleToAnyone or !dormant)
			{
				// update directional sprites + hide angles not visible to anyone
				for (uint i = 0; i < 8; i++)
				{
					CBaseEntity@ client_sprite = sprites[i];
					bool canAnyoneSeeThis = client_sprite.pev.colormap > 0;
					if (canAnyoneSeeThis)
					{
						client_sprite.pev.effects &= ~EF_NODRAW;
						//client_sprite.pev.origin = pev.origin;
						g_EntityFuncs.SetOrigin(client_sprite, pev.origin);
						client_sprite.pev.frame = frame*8 + i;
						client_sprite.pev.rendercolor = lightColor;
					}
					else
						client_sprite.pev.effects |= EF_NODRAW;
				}
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
				bool gunshot = snd.m_iVolume == 2018;
				CBaseEntity@ owner = snd.hOwner;
				
				if (gunshot and owner !is null and owner.IsPlayer())
				{
					Vector delta = snd.m_vecOrigin - pev.origin;
					if (delta.Length() < snd.m_iVolume)
					{
						delta.z = 0;
						bool moved = (lastDormantPos - pev.origin).Length() > 1.0f;
						if (moved)
						{
							lastDormantPos = pev.origin;
							@dormantNode = getSoundNode(lastDormantPos);
							//println("NEW DORMANT NODE");
						}
						
						if (dormantNode !is null)
						{
							PlayerState@ state = getPlayerState(cast<CBasePlayer@>(owner));
							if (canHearSound(dormantNode, state.soundNode, owner.pev.origin, self))
							{
								if (isDeaf)
									g_EngineFuncs.VecToAngles(delta.Normalize(), pev.angles);
								else
									SetEnemy(owner);
							}
						}
						else
							g_EngineFuncs.VecToAngles(delta.Normalize(), pev.angles);
					}
				}
					
				activeList = snd.m_iNext;
			}
		}
		
		oldFrameCounter = frameCounter;
		oldFrameIdx = frameIdx;
		pev.nextthink = g_Engine.time + g_monster_think_delay;
		//pev.nextthink = g_Engine.time + 0.02857;
	}
};
