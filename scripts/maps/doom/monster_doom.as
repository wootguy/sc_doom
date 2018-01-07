#include "utils"

enum activities {
	ANIM_IDLE,
	ANIM_MOVE,
	ANIM_ATTACK,
	ANIM_PAIN,
	ANIM_DEAD,
	ANIM_GIB,
}

array<string> light_suffix = {"_L3", "_L2", "_L1", "_L0"};

class fireball : ScriptBaseAnimating
{
	string fireSound = "doom/DSFIRSHT.wav";
	string boomSound = "doom/DSFIRXPL.wav";
	float moveSpeed = 400;
	bool dead = false;
	int deathFrameStart = 2;
	int deathFrameEnd = 4;
	int frameCounter = 0;
	
	void Spawn()
	{				
		pev.movetype = MOVETYPE_FLY;
		pev.solid = SOLID_TRIGGER;
		pev.effects = EF_DIMLIGHT;
		
		g_EntityFuncs.SetModel( self, "sprites/doom/BAL1.spr" );
		g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -8), Vector(8, 8, 8));
		
		g_EngineFuncs.MakeVectors(self.pev.angles);
		pev.velocity = g_Engine.v_forward*moveSpeed;
		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, fireSound, 1.0f, 0.5f, 0, 100);
		
		pev.scale = 1.4f;
		pev.frame = 0;
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.05;
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if (dead or (pOther.pev.classname == "fireball"))
			return;
			
		CBaseEntity@ owner = g_EntityFuncs.Instance( self.pev.owner );
		if (owner !is null and owner.entindex() == pOther.entindex())
			return;
			
		dead = true;
		pev.velocity = Vector(0,0,0);
		pev.solid = SOLID_NOT;
		pev.frame = 2;
		frameCounter = 2;
		pev.nextthink = g_Engine.time + 0.15;
		
		pOther.TakeDamage(self.pev, owner is null ? self.pev : owner.pev, 20.0f, DMG_BLAST);
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, boomSound, 1.0f, 0.5f, 0, 100);
	}
	
	void Think()
	{
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
			Color flash_color = Color(32, 8, 4);
			te_dlight(self.pev.origin, flash_size, flash_color, flash_life, flash_decay);
			
			pev.nextthink = g_Engine.time + 0.15;
		}
		else
		{
			pev.frame = (frameCounter / 3) % 2;
			
			int flash_size = 20;
			int flash_life = 1;
			int flash_decay = 8;
			Color flash_color = Color(255, 64, 32);
			te_dlight(self.pev.origin, flash_size, flash_color, flash_life, flash_decay);
			
			pev.nextthink = g_Engine.time + 0.05;
		}
		
		frameCounter++;
	}
}

class AnimInfo
{
	float framerate;
	bool looped;
	array<int> frameIndices;
	int attackFrameIdx; // frame index where attack is called
	
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
	uint brighten = 0; // if > 0 then draw full-bright. Decremented each frame
	
	uint frameCounter = 0;
	uint oldFrameCounter = 0;
	int animLoops = 0;
	int oldFrameIdx = 0;
	
	float walkSpeed = 8.0f;
	float meleeRange = 64.0f;
	float nextRangeAttack = 0;
	
	float lastWallReflect = 0;
	float lastDirChange = 0;
	float lastEnemy = 0;
	float deathRemoveDelay = 60.0f; // time before entity is destroyed after death
	float nextIdleSound = 0;
	bool dormant = true;
	EHandle h_enemy;
	
	array<EHandle> sprites;
	array<EHandle> renderShowEnts;
	array<EHandle> renderHideEnts;
	
	array<string> idleSounds;
	string painSound;
	array<string> deathSounds;
	array<string> alertSounds;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		return BaseClass.KeyValue( szKey, szValue );
	}
	
	void DoomSpawn()
	{		
		pev.movetype = MOVETYPE_STEP;
		pev.solid = SOLID_SLIDEBOX;
		
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		
		self.m_bloodColor = BLOOD_COLOR_RED;
		self.pev.scale = 1.5f;
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
			ckeys["rendercolor"] = "255 255 255";
			ckeys["scale"] = string(pev.scale);
			ckeys["targetname"] = "m" + g_monster_idx + "s" + i;
			CBaseEntity@ client_sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
			//println("MAKE LE SPRITE " + client_sprite.pev.targetname);
			sprites.insertLast(EHandle(client_sprite));
			
			dictionary rkeys;
			rkeys["target"] = string(client_sprite.pev.targetname);
			rkeys["spawnflags"] = "75";
			rkeys["rendermode"] = "0";
			CBaseEntity@ show = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			renderShowEnts.insertLast(EHandle(show));
			
			rkeys["rendermode"] = "2";
			CBaseEntity@ hide = g_EntityFuncs.CreateEntity("env_render_individual", rkeys, true);
			renderHideEnts.insertLast(EHandle(hide));
		}
		
		g_EntityFuncs.SetSize(self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
		self.SetClassification(CLASS_ALIEN_MONSTER);
		SetActivity(ANIM_IDLE);
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
		println("IM AWAKE");
		string snd = alertSounds[Math.RandomLong(0, alertSounds.size()-1)];
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, snd, 1.0f, 0.5f, 0, 100);
						
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
			pev.rendermode = 0;
			pev.solid = SOLID_NOT;
			bool gib = (bitsDamageType & DMG_BLAST) != 0 or pev.health < -100;
			SetActivity(gib ? ANIM_GIB : ANIM_DEAD);
			h_enemy = null;
			pev.deadflag = DEAD_DYING;
			
			string snd = deathSounds[Math.RandomLong(0, deathSounds.size()-1)];
			if (gib)
				snd = "doom/DSSLOP.wav";
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, snd, 1.0f, 0.5f, 0, 100);
		}
		else
		{
			SetActivity(ANIM_PAIN);
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, painSound, 1.0f, 0.5f, 0, 100);
			
			CBaseEntity@ attacker = g_EntityFuncs.Instance(pevAttacker.get_pContainingEntity());
			SetEnemy( attacker );
		}
		
		return 0;
	}
	
	void SetEnemy(CBaseEntity@ ent)
	{
		if (!ent.IsAlive() or (ent.pev.flags & FL_NOTARGET) != 0)
			return;
		// only switch targets after chasing current one for a while
		if (!h_enemy.IsValid() or lastEnemy + 10.0f < g_Engine.time)
			h_enemy = EHandle(ent);
		Wakeup();
		lastEnemy = g_Engine.time;
	}
	
	void ClearEnemy()
	{
		h_enemy = null;
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
		return pev.origin + Vector(0,0,36);
	}
	
	void RangeAttack(Vector aimDir)
	{
		println("Range attack not implemented!");
	}
	
	void MeleeAttack(Vector aimDir)
	{
		println("Melee attack not implemented!");
	}
	
	void ShootBullet(Vector dir, float spread, float damage)
	{
		Vector vecSrc = BodyPos();
		float range = 16384;
		
		int flash_size = 20;
		int flash_life = 1;
		int flash_decay = 0;
		Color flash_color = Color(255, 160, 64);
		te_dlight(vecSrc, flash_size, flash_color, flash_life, flash_decay);
		brighten = 4;
		
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
					
					Vector knockDir = Vector(0,0,100);
					Vector knockVel = g_Engine.v_forward*knockDir.z +
									  g_Engine.v_up*knockDir.y +
									  g_Engine.v_right*knockDir.x;
					knockBack(pHit, knockVel);
					
					if (pHit.IsBSPModel()) 
					{
						te_gunshotdecal(tr.vecEndPos, pHit, getDecal(DECAL_SMALLSHOT));
						//te_decal(tr.vecEndPos, pHit, decal);
					}
				}
			}
		}
		
		// bullet tracer effects
		te_tracer(vecSrc, tr.vecEndPos);
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
		if (pev.deadflag == DEAD_DEAD)
		{
			g_EntityFuncs.Remove(self);
			return;
		}
		
		int light_level = self.Illumination() + 32;
		if (brighten > 0)
		{
			brighten--;
			light_level += brighten*64;
			if (light_level > 255)
				light_level = 255;
		}
		Vector lightColor = Vector(light_level, light_level, light_level);
		//pev.rendercolor = lightColor;
		//println("LIGHT " + g_EngineFuncs.GetEntityIllum(self.edict()) + " " + pev.light_level);
		
		pev.velocity.z += -0.1f; // prevents floating and fixes fireballs not getting Touched by monsters that don't move
		
		//println("CURENT ANIM: " + currentAnim.frameIndices[0] + " " + currentAnim.lastFrame());
		frameCounter += 1;
		bool looped = false;
		int frameIdx = currentAnim.getFrameIdx(frameCounter, oldFrameCounter, looped);
		int frame = currentAnim.frameIndices[frameIdx];

		if (looped)
			animLoops += 1;
		
		//println("FRAME " + frame + " " + currentAnim.minFrame + " " + currentAnim.maxFrame);
	
		g_EngineFuncs.MakeVectors(pev.angles);
		Vector forward = g_Engine.v_forward;
		Vector right = g_Engine.v_right;
		forward.z = 0;
		right.z = 0;
		forward = forward.Normalize();
		right = right.Normalize();
		
		if (activity == ANIM_PAIN and animLoops > 2)
			SetActivity(ANIM_MOVE);
		
		if (pev.health > 0)
			pev.deadflag = 0;
		
		if (!self.IsAlive())
		{
			if (looped or pev.deadflag == DEAD_DEAD)
			{
				pev.deadflag = DEAD_DEAD;
				pev.frame = currentAnim.lastFrame();
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
			
			if (activity == ANIM_MOVE)
			{
				int canWalk = g_EngineFuncs.WalkMove(self.edict(), pev.angles.y, walkSpeed, int(WALKMOVE_NORMAL));
				if (canWalk != 1)
				{
					TraceResult tr;
					g_Utility.TraceHull( bodyPos, bodyPos + forward*walkSpeed, dont_ignore_monsters, human_hull, self.edict(), tr );
					if (tr.flFraction >= 1.0f and tr.fAllSolid == 0)
					{
						// walkmove doesn't like stepping down things, but this is a legal move
						Vector stepPos = tr.vecEndPos;
						// TODO: Don't step if this is actually a cliff
						pev.origin = stepPos + Vector(0,0,-36);
					}
					else
					{
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
		
			if (h_enemy)
			{
				CBaseEntity@ enemy = h_enemy;
				
				Vector enemyPos = enemy.pev.origin;
				if (!enemy.IsPlayer())
					enemyPos.z += (enemy.pev.maxs.z - enemy.pev.mins.z)*0.5f;
				Vector delta = enemyPos - bodyPos;
				if (activity == ANIM_MOVE and lastDirChange + 1.0f < g_Engine.time)
				{
					float idealYaw = g_EngineFuncs.VecToYaw(delta);
					pev.angles.y = idealYaw;
					if (Math.RandomLong(0,2) <= 1) // zig zag towards target
					{
						if (Math.RandomLong(0,1) == 0)
							pev.angles.y += 45;
						else
							pev.angles.y -= 45;
					}
					
					lastDirChange = g_Engine.time;
				}
				
				bool inMeleeRange = hasMelee and delta.Length() < meleeRange;
				if (activity == ANIM_ATTACK or inMeleeRange or nextRangeAttack < g_Engine.time)
				{
					pev.angles.y = g_EngineFuncs.VecToYaw(delta);
					if (activity != ANIM_ATTACK)
					{
						SetActivity(ANIM_ATTACK);
						nextRangeAttack = g_Engine.time + Math.RandomFloat(1.0f, 4.0f);
					}
					else
					{
						if (frameIdx == currentAnim.attackFrameIdx and oldFrameIdx != frameIdx)
						{
							if (inMeleeRange)
							{
								MeleeAttack(delta);
							}
							else
							{								
								RangeAttack(delta);
							}
						}
						
						if (animLoops > 0)
						{
							if (inMeleeRange)
								SetActivity(ANIM_ATTACK);
							else
								SetActivity(ANIM_MOVE);
						}
					}
				}
				
				if (!enemy.IsAlive())
				{
					Sleep();
				}
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
						
					if (dormant and ent.IsAlive())
					{
						float dot = DotProduct(forward, delta);
						if (dot < -0.3f)
						{
							SetEnemy(ent);
						}
					}
					
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
					client_sprite.pev.frame = frame*8 + i;
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
		pev.nextthink = g_Engine.time + 0.05;
	}
};

class monster_imp : monster_doom
{
	string meleeSound = "doom/DSCLAW.wav";
	
	void Spawn()
	{
		bodySprite = "sprites/doom/TROO.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(69, 76, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSBGACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSBGDTH1.wav");
		deathSounds.insertLast("doom/DSBGDTH2.wav");
		alertSounds.insertLast("doom/DSBGSIT1.wav");
		alertSounds.insertLast("doom/DSBGSIT2.wav");
		
		this.hasMelee = true;
		
		self.m_FormattedName = "Imp";
		self.pev.health = 100;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		Vector bodyPos = BodyPos();
		TraceResult tr;
		Vector attackDir = aimDir.Normalize();
		g_Utility.TraceHull( bodyPos, bodyPos + attackDir*meleeRange, dont_ignore_monsters, head_hull, self.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		//te_beampoints(bodyPos, bodyPos + delta.Normalize()*meleeRange);
		
		if (phit !is null)
		{
			g_WeaponFuncs.ClearMultiDamage();
			phit.TraceAttack(pev, 15.0f, attackDir, tr, DMG_SLASH);
			g_WeaponFuncs.ApplyMultiDamage(self.pev, self.pev);
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
		}
	}
	
	void RangeAttack(Vector aimDir)
	{
		brighten = 8;
		
		Vector bodyPos = BodyPos();
		Vector angles;
		g_EngineFuncs.VecToAngles(aimDir, angles);
		angles.x = -angles.x;
		
		dictionary keys;
		keys["origin"] = bodyPos.ToString();
		keys["angles"] = angles.ToString();
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_zombieman : monster_doom
{
	string shootSnd = "doom/DSPISTOL.wav";

	void Spawn()
	{
		this.bodySprite = "sprites/doom/POSS.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 60, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(61, 69, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrameIdx = 2;
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(5);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSPODTH2.wav");
		deathSounds.insertLast("doom/DSPODTH3.wav");
		deathSounds.insertLast("doom/DSPODTH1.wav");
		alertSounds.insertLast("doom/DSPOSIT1.wav");
		alertSounds.insertLast("doom/DSPOSIT2.wav");
		
		this.hasMelee = false;
		
		self.m_FormattedName = "Zombie Man";
		self.pev.health = 50;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSnd, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, 5.0f);
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_shotgunguy : monster_doom
{
	string shootSnd = "doom/DSSHOTGN.wav";

	void Spawn()
	{
		bodySprite = "sprites/doom/TROO.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(0, 4, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(5, 13, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrameIdx = 2;
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(5);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSPODTH2.wav");
		deathSounds.insertLast("doom/DSPODTH3.wav");
		deathSounds.insertLast("doom/DSPODTH1.wav");
		alertSounds.insertLast("doom/DSPOSIT1.wav");
		alertSounds.insertLast("doom/DSPOSIT2.wav");
		
		this.hasMelee = false;
		
		self.m_FormattedName = "Shotgun Guy";
		self.pev.health = 50;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSnd, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, 5.0f);
		ShootBullet(aimDir, 22.0f, 5.0f);
		ShootBullet(aimDir, 22.0f, 5.0f);
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_demon : monster_doom
{
	string meleeSound = "doom/DSCLAW.wav";
	
	void Spawn()
	{
		bodySprite = "sprites/doom/TROO.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(0, 4, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(5, 12, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSBGACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSBGDTH1.wav");
		deathSounds.insertLast("doom/DSBGDTH2.wav");
		alertSounds.insertLast("doom/DSBGSIT1.wav");
		alertSounds.insertLast("doom/DSBGSIT2.wav");
		
		this.hasMelee = true;
		
		self.m_FormattedName = "Demon";
		self.pev.health = 200;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		Vector bodyPos = BodyPos();
		TraceResult tr;
		Vector attackDir = aimDir.Normalize();
		g_Utility.TraceHull( bodyPos, bodyPos + attackDir*meleeRange, dont_ignore_monsters, head_hull, self.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		//te_beampoints(bodyPos, bodyPos + delta.Normalize()*meleeRange);
		
		if (phit !is null)
		{
			g_WeaponFuncs.ClearMultiDamage();
			phit.TraceAttack(pev, 15.0f, attackDir, tr, DMG_SLASH);
			g_WeaponFuncs.ApplyMultiDamage(self.pev, self.pev);
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
		}
	}
	
	void Think()
	{
		DoomThink();
	}
}