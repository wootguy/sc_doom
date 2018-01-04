#include "anims"

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
	
	void Spawn()
	{				
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_TRIGGER;
		
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
		if (dead)
			return;
		dead = true;
		pev.velocity = Vector(0,0,0);
		pev.solid = SOLID_NOT;
		pev.frame = 2;
		pev.nextthink = g_Engine.time + 0.15;
		
		CBaseEntity@ owner = g_EntityFuncs.Instance( self.pev.owner );
		pOther.TakeDamage(self.pev, owner.pev, 20.0f, DMG_BLAST);
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, boomSound, 1.0f, 0.5f, 0, 100);
	}
	
	void Think()
	{
		pev.frame += 1;
		if (dead)
		{
			if (pev.frame > deathFrameEnd)
			{
				g_EntityFuncs.Remove(self);
				return;
			}
		}
		else
		{
			if (pev.frame > 1)
				pev.frame = 0;
		}
		pev.nextthink = g_Engine.time + 0.15;
	}
}

class monster_imp : ScriptBaseMonsterEntity
{
	array< array< array<string> > > anims = SPR_ANIM_TROO;
	
	int activity = ANIM_IDLE;
	
	int minFrame = 0;
	int maxFrame = 2;
	bool animLoop = true;
	uint frameCounter = 0;
	float framerate = 0.125f;
	int animLoops = 0;
	int oldFrame = 0;
	
	float walkSpeed = 8.0f;
	float meleeRange = 64.0f;
	float nextRangeAttack = 0;
	
	float lastWallReflect = 0;
	float lastDirChange = 0;
	float lastEnemy = 0;
	float nextIdleSound = 0;
	bool dormant = true;
	EHandle h_enemy;
	
	array<string> idleSounds = {"doom/DSBGACT.wav"};
	string clawSound = "doom/DSCLAW.wav";
	string painSound = "doom/DSPOPAIN.wav";
	array<string> deathSounds = {"doom/DSBGDTH1.wav", "doom/DSBGDTH2.wav"};
	array<string> alertSounds = {"doom/DSBGSIT1.wav", "doom/DSBGSIT2.wav"};
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{		
		pev.movetype = MOVETYPE_STEP;
		pev.solid = SOLID_SLIDEBOX;
		
		//g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		g_EntityFuncs.SetModel(self, "models/doom/null.mdl");
		
		self.m_FormattedName = "Imp";
		self.m_bloodColor = BLOOD_COLOR_RED;
		self.pev.health = 100;
		self.pev.scale = 1.2f;
		pev.takedamage = DAMAGE_YES;
		
		g_EntityFuncs.SetSize(self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
		self.SetClassification(CLASS_ALIEN_MONSTER);
		
		//self.MonsterInit();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void SetActivity(int act)
	{
		switch(act)
		{
			case ANIM_IDLE:
				minFrame = 0;
				maxFrame = 2;
				framerate = 0.125f;
				animLoop = true;
				break;
			case ANIM_MOVE:
				minFrame = 0;
				maxFrame = 4;
				framerate = 0.25f;
				animLoop = true;
				break;
			case ANIM_ATTACK:
				minFrame = 4;
				maxFrame = 7;
				framerate = 0.25f;
				animLoop = true;
				break;
			case ANIM_PAIN:
				minFrame = 7;
				maxFrame = 8;
				framerate = 0.125;
				break;
			case ANIM_DEAD:
				minFrame = 0;
				maxFrame = 5;
				animLoop = false;
				framerate = 0.25f;
				break;
			case ANIM_GIB:
				minFrame = 5;
				maxFrame = 13;
				animLoop = false;
				framerate = 0.5f;
				break;
		}
		
		println("ACT " + activity);
		animLoops = 0;
		frameCounter = 0;
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
		if (!self.IsAlive())
			return 0;
		pev.health -= flDamage;
		if (pev.health <= 0)
		{
			println("I R DEAD");
			g_EntityFuncs.SetModel(self, "sprites/doom/TROO" + light_suffix[pev.light_level] + ".spr");
			pev.renderamt = 255;
			pev.rendermode = 0;
			pev.solid = SOLID_NOT;
			bool gib = (bitsDamageType & DMG_BLAST) != 0 or pev.health < -100;
			SetActivity(gib ? ANIM_GIB : ANIM_DEAD);
			h_enemy = null;
			pev.deadflag = DEAD_DYING;
			
			string snd = deathSounds[Math.RandomLong(0, deathSounds.size()-1)];
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, snd, 1.0f, 0.5f, 0, 100);
		}
		else
		{
			SetActivity(ANIM_PAIN);
			g_SoundSystem.PlaySound(self.edict(), CHAN_ITEM, painSound, 1.0f, 0.5f, 0, 100);
			
			CBaseEntity@ attacker = g_EntityFuncs.Instance(pevAttacker.get_pContainingEntity());
			println("ATTACKER IS " + attacker.pev.classname);
			SetEnemy( attacker );
		}
		
		return 0;
	}
	
	void SetEnemy(CBaseEntity@ ent)
	{
		// only switch targets after chasing current one for a while
		if (!h_enemy.IsValid() or lastEnemy + 0.0f < g_Engine.time)
			h_enemy = EHandle(ent);
		Wakeup();
		lastEnemy = g_Engine.time;
	}
	
	void Sleep()
	{
		if (dormant)
			return;
			
		h_enemy = null;
		println("SLEEPY TIME");
		dormant = true;
		SetActivity(ANIM_IDLE);
	}
	
	void Think()
	{
		frameCounter += 1;
		int frame = minFrame + (int(frameCounter*framerate) % (maxFrame - minFrame));
		
		if (oldFrame > frame or minFrame == maxFrame-1)
			animLoops += 1;
		
		//println("FRAME " + frame + " " + minFrame + " " + maxFrame);
	
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
		
		if (!self.IsAlive() and frame >= maxFrame-1 or pev.deadflag == DEAD_DEAD)
		{
			pev.deadflag = DEAD_DEAD;
			pev.frame = maxFrame-1;
		}
		else
			pev.frame = frame;
		
		if (!dormant and self.IsAlive())
		{
			if (activity == ANIM_MOVE)
			{
				bool canWalk = g_EngineFuncs.WalkMove(self.edict(), pev.angles.y, walkSpeed, int(WALKMOVE_NORMAL)) == 1;
				if (!canWalk)
				{
					println("HIT WALL");
					if (lastWallReflect + 0.2f < g_Engine.time)
					{
						pev.angles.y += Math.RandomFloat(90, 270);
						lastWallReflect = g_Engine.time;
						lastDirChange = g_Engine.time;
					}
				}
			}
		
			if (h_enemy)
			{
				CBaseEntity@ enemy = h_enemy;
				
				Vector bodyPos = pev.origin + Vector(0,0,36);
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
				
				bool inMeleeRange = delta.Length() < meleeRange;
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
						if (frame == maxFrame-1 and oldFrame != frame)
						{
							if (inMeleeRange)
							{
								TraceResult tr;
								Vector attackDir = delta.Normalize();
								g_Utility.TraceHull( bodyPos, bodyPos + attackDir*meleeRange, dont_ignore_monsters, head_hull, self.edict(), tr );
								CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
								//te_beampoints(bodyPos, bodyPos + delta.Normalize()*meleeRange);
								
								if (phit !is null)
								{
									g_WeaponFuncs.ClearMultiDamage();
									phit.TraceAttack(pev, 15.0f, attackDir, tr, DMG_SLASH);
									g_WeaponFuncs.ApplyMultiDamage(self.pev, self.pev);
									g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, clawSound, 1.0f, 0.5f, 0, 100);
								}
							}
							else
							{								
								Vector angles;
								
								g_EngineFuncs.VecToAngles(delta, angles);
								angles.x = -angles.x;
								
								dictionary keys;
								keys["origin"] = bodyPos.ToString();
								keys["angles"] = angles.ToString();
								CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
								@fireball.pev.owner = @self.edict();
								g_EntityFuncs.DispatchSpawn(fireball.edict());
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
		
		pev.light_level = ((self.Illumination() + 32) / 64);
		pev.light_level = 3 - pev.light_level;
		//println("LIGHT " + g_EngineFuncs.GetEntityIllum(self.edict()) + " " + pev.light_level);
		
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
					if (angleIdx >= int(SPR_ANIM_TROO[pev.light_level][frame].length()))
						angleIdx = 0;
						
					if (dormant and ent.IsAlive())
					{
						float dot = DotProduct(forward, delta);
						if (dot < -0.3f)
						{
							SetEnemy(ent);
						}
					}
					
					string spr = SPR_ANIM_TROO[pev.light_level][frame][angleIdx];
					
					int scale = 14;
					int fps = 15;
					te_explosion(pos, spr, scale, fps, 15, MSG_ONE_UNRELIABLE, ent.edict());
				}
			} while (ent !is null);
		}
		
		oldFrame = frame;
		pev.nextthink = g_Engine.time + 0.05;
	}
};