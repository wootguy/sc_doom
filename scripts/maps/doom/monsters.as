#include "monster_doom"

class monster_imp : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/TROO.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(69, 76, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSBGACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSBGDTH1.wav");
		deathSounds.insertLast("doom/DSBGDTH2.wav");
		alertSounds.insertLast("doom/DSBGSIT1.wav");
		alertSounds.insertLast("doom/DSBGSIT2.wav");
		meleeSound = "doom/DSCLAW.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.78f;
		
		self.m_FormattedName = "Imp";
		self.pev.health = 60;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		if (Slash(aimDir, Math.RandomLong(3, 24)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
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
		keys["model"] = "sprites/doom/BAL.spr";
		keys["speed"] = "" + 350;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "1";
		keys["deathFrameStart"] = "2";
		keys["deathFrameEnd"] = "4";
		keys["flash_color"] = "255 64 32";
		keys["damage_min"] = "3";
		keys["damage_max"] = "24";
		
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
	void Spawn()
	{
		this.bodySprite = "sprites/doom/POSS.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 60, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(61, 69, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(2);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(5);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSPODTH2.wav");
		deathSounds.insertLast("doom/DSPODTH3.wav");
		deathSounds.insertLast("doom/DSPODTH1.wav");
		alertSounds.insertLast("doom/DSPOSIT1.wav");
		alertSounds.insertLast("doom/DSPOSIT2.wav");
		alertSounds.insertLast("doom/DSPOSIT3.wav");
		shootSound = "doom/DSPISTOL.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.78f;
		this.dropItem = "ammo_doom_bullets";
		
		self.m_FormattedName = "Zombie Man";
		self.pev.health = 20;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15));
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_shotgunguy : monster_doom
{
	void Spawn()
	{
		bodySprite = "sprites/doom/SPOS.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 4, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 60, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(61, 69, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(2);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(5);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSPODTH2.wav");
		deathSounds.insertLast("doom/DSPODTH3.wav");
		deathSounds.insertLast("doom/DSPODTH1.wav");
		alertSounds.insertLast("doom/DSPOSIT1.wav");
		alertSounds.insertLast("doom/DSPOSIT2.wav");
		shootSound = "doom/DSSHOTGN.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.66f;
		this.dropItem = "ammo_doom_shotgun";
		
		self.m_FormattedName = "Shotgun Guy";
		self.pev.health = 30;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15));
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15), false);
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15), false);
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_hwdude : monster_doom
{
	void Spawn()
	{
		this.bodySprite = "sprites/doom/CPOS.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 5, 0.5f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 5, 0.5f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 62, 0.5f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(63, 68, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(3);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(4);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 4);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 4);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 4);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		this.constantAttackLoopFrame = 3;
		//animInfo[ANIM_ATTACK].frameIndices.insertLast(5);
		//animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSPODTH2.wav");
		deathSounds.insertLast("doom/DSPODTH3.wav");
		deathSounds.insertLast("doom/DSPODTH1.wav");
		alertSounds.insertLast("doom/DSPOSIT1.wav");
		alertSounds.insertLast("doom/DSPOSIT2.wav");
		alertSounds.insertLast("doom/DSPOSIT3.wav");
		shootSound = "doom/DSSHOTGN.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.66f;
		this.constantAttack = true;
		
		this.dropItem = "ammo_doom_chaingun";
		
		self.m_FormattedName = "Heavy Weapon Dude";
		self.pev.health = 70;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15));
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_demon : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/SARG.spr";
		
		walkSpeed = 10.0f;
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.5f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.0125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 69, 0.5f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 69, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_DEAD].frameIndices.insertAt(1, 65);
		animInfo[ANIM_DEAD].frameIndices.insertAt(0, 64);
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSSGTDTH.wav");
		alertSounds.insertLast("doom/DSSGTSIT.wav");
		meleeSound = "doom/DSSGTATK.wav";
		
		this.hasMelee = true;
		this.hasRanged = false;
		this.painChance = 0.7f;
		
		self.m_FormattedName = "Demon";
		self.pev.health = 150;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		if (Slash(aimDir, Math.RandomLong(4, 40)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_cacodemon : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/HEAD.spr";
		
		animInfo.insertLast(AnimInfo(0, 0, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 0, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(1, 3, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(1, 3, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(4, 4, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(48, 53, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(48, 53, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSCACDTH.wav");
		alertSounds.insertLast("doom/DSCACSIT.wav");
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.canFly = true;
		this.painChance = 0.5f;
		
		self.m_FormattedName = "Cacodemon";
		self.pev.health = 400;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		Slash(aimDir, Math.RandomLong(10, 60));
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
		keys["model"] = "sprites/doom/BAL.spr";
		keys["speed"] = "" + 350;
		keys["moveFrameStart"] = "5";
		keys["moveFrameEnd"] = "6";
		keys["deathFrameStart"] = "7";
		keys["deathFrameEnd"] = "9";
		keys["flash_color"] = "255 32 64";
		keys["damage_min"] = "5";
		keys["damage_max"] = "40";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_painelemental : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/PAIN.spr";
		
		animInfo.insertLast(AnimInfo(0, 0, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 2, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(3, 5, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(3, 5, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 61, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(56, 61, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSPEPAIN.wav";
		deathSounds.insertLast("doom/DSPEDTH.wav");
		alertSounds.insertLast("doom/DSPESIT.wav");
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.canFly = true;
		this.painChance = 0.5f;
		this.deathBoom = 3;
		
		self.m_FormattedName = "Pain Elemental";
		self.pev.health = 40;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		Slash(aimDir, Math.RandomLong(10, 60));
	}
	
	void DeathBoom()
	{
		println("ZOMG BOOM");
		
		g_EngineFuncs.MakeVectors(pev.angles);
		Vector forward = g_Engine.v_forward;
		Vector right = g_Engine.v_right;
		ShootSoul(forward, false);
		ShootSoul((forward + right).Normalize(), false);
		ShootSoul((forward - right).Normalize(), false);
	}
	
	int CountSouls()
	{
		int count = 0;
		CBaseEntity@ ent = null;
		do {
			@ent = g_EntityFuncs.FindEntityByClassname(ent, "monster_lostsoul");
			if (ent !is null)
			{
				monster_lostsoul@ mon = cast<monster_lostsoul@>(CastToScriptClass(ent));
				if (!mon.superDormant)
					count++;
			}
		} while (ent !is null);
		return count;
	}
	
	void ShootSoul(Vector aimDir, bool atEnemy)
	{
		if (CountSouls() >= 21)
		{
			println("Too many lost souls in level. Aborting attack.");
			return;
		}
		Vector flatAim = Vector(aimDir.x, aimDir.y, 0).Normalize();
		Vector spawnPos = BodyPos() + flatAim*18;
		Vector angles;
		g_EngineFuncs.VecToAngles(aimDir, angles);
		angles.x = -angles.x;
		
		dictionary keys;
		keys["origin"] = spawnPos.ToString();
		keys["angles"] = angles.ToString();
		
		CBaseEntity@ soul = g_EntityFuncs.CreateEntity("monster_lostsoul", keys, false);
		//@soul.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(soul.edict());
		
		monster_lostsoul@ mon = cast<monster_lostsoul@>(CastToScriptClass(soul));
		mon.Setup();
		mon.dormant = false;
		
		Vector soulDir = aimDir;
		if (atEnemy) 
		{
			Vector enemyPos = h_enemy.GetEntity().pev.origin + h_enemy.GetEntity().pev.view_ofs;
			soulDir = (enemyPos - soul.pev.origin).Normalize();
			mon.SetEnemy(h_enemy);
		}
		
		
		mon.RangeAttack(soulDir);
	}
	
	void RangeAttack(Vector aimDir)
	{
		brighten = 8;
		ShootSoul(aimDir, true);
	}
	
	void Think()
	{
		DoomThink();
	}
}


class monster_lostsoul : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/SKUL.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(2, 3, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(2, 3, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(4, 4, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(40, 45, 0.5f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(40, 45, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSFIRXPL.wav");
		this.meleeSound = "doom/DSSKLATK.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.canFly = true;
		this.fullBright = true;
		this.painChance = 1.0f;
		this.deathBoom = 1;
		
		self.m_FormattedName = "Lost Soul";
		self.pev.health = 100;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		SetTouch( TouchFunction( Touched ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{
		Dash(aimDir.Normalize()*20*g_monster_scale, Math.RandomLong(3, 24), 1.0f);
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
	}
	
	void Touched(CBaseEntity@ ent)
	{
		DoomTouched(ent);
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_baron : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/BOSS.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 68, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSBRSDTH.wav");
		alertSounds.insertLast("doom/DSBRSSIT.wav");
		meleeSound = "doom/DSCLAW.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.20f;
		
		self.m_FormattedName = "Baron of Hell";
		self.pev.health = 1000;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		if (Slash(aimDir, Math.RandomLong(10, 80)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
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
		keys["model"] = "sprites/doom/BAL7.spr";
		keys["speed"] = "" + 525;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "1";
		keys["deathFrameStart"] = "16";
		keys["deathFrameEnd"] = "18";
		keys["flash_color"] = "64 255 64";
		keys["damage_min"] = "8";
		keys["damage_max"] = "64";
		keys["oriented"] = "1";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_hellknight : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/BOS2.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 68, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSKNTDTH.wav");
		alertSounds.insertLast("doom/DSKNTSIT.wav");
		meleeSound = "doom/DSCLAW.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.50f;
		
		self.m_FormattedName = "Hell Knight";
		self.pev.health = 500;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		if (Slash(aimDir, Math.RandomLong(10, 80)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
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
		keys["model"] = "sprites/doom/BAL7.spr";
		keys["speed"] = "" + 525;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "1";
		keys["deathFrameStart"] = "16";
		keys["deathFrameEnd"] = "18";
		keys["flash_color"] = "64 255 64";
		keys["damage_min"] = "8";
		keys["damage_max"] = "64";
		keys["oriented"] = "1";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_revenant : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/SKEL.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 5, 0.5f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(6, 8, 1.0f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(9, 10, 0.5f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(11, 11, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(96, 100, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(96, 100, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].frameIndices.insertLast(8);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(8);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(1, 7);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(1, 7);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(6);
		
		animInfo[ANIM_ATTACK2].frameIndices.insertLast(10);
		animInfo[ANIM_ATTACK2].frameIndices.insertLast(10);
		animInfo[ANIM_ATTACK2].frameIndices.insertAt(0, 9);
		animInfo[ANIM_ATTACK2].frameIndices.insertAt(0, 9);
		animInfo[ANIM_ATTACK2].attackFrames.resize(0);
		animInfo[ANIM_ATTACK2].attackFrames.insertLast(3);
		
		idleSounds.insertLast("doom/DSSKEACT.wav");
		painSound = "doom/DSPOPAIN.wav";
		deathSounds.insertLast("doom/DSSKEDTH.wav");
		alertSounds.insertLast("doom/DSSKESIT.wav");
		meleeSound = "doom/DSSKEPCH.wav";
		meleeWindupSound = "doom/DSSKESWG.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.39f;
		this.walkSpeed = 10.0f;
		this.rangeWhenMeleeFails = false;
		
		self.m_FormattedName = "Revenant";
		self.pev.health = 300;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttackStart()
	{
		brighten = 8;
	}
	
	void MeleeAttack(Vector aimDir)
	{
		if (Slash(aimDir, Math.RandomLong(8, 64)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
	}
	
	void RangeAttack(Vector aimDir)
	{		
		Vector bodyPos = BodyPos();
		Vector angles;
		g_EngineFuncs.VecToAngles(aimDir, angles);
		angles.x = -angles.x;
		
		dictionary keys;
		keys["origin"] = bodyPos.ToString();
		keys["angles"] = angles.ToString();
		keys["model"] = "sprites/doom/FATB.spr";
		keys["speed"] = "" + 350;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "1";
		keys["deathFrameStart"] = "16";
		keys["deathFrameEnd"] = "18";
		keys["flash_color"] = "255 64 32";
		keys["damage_min"] = "10";
		keys["damage_max"] = "80";
		keys["oriented"] = "1";
		keys["spawn_sound"] = "doom/DSSKEATK.wav";
		keys["death_sound"] = "doom/DSBAREXP.wav";
		keys["trail_sprite"] = "sprites/doom/PUFF.spr";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
		
		fireball@ ball = cast<fireball@>(CastToScriptClass(fireball));
		ball.h_followEnt = h_enemy;
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_mancubus : monster_doom
{
	int rangeCombo = 0;
	
	void Spawn()
	{
		bodySprite = "sprites/doom/FATT.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 5, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(6, 8, 0.375f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 8, 0.375f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(9, 9, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(80, 89, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(80, 89, 0.5f, false)); // ANIM_GIB		
		
		
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(4);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		this.constantAttackLoopFrame = 2;
		
		idleSounds.insertLast("doom/DSPOSACT.wav");
		painSound = "doom/DSMNPAIN.wav";
		deathSounds.insertLast("doom/DSMANDTH.wav");
		alertSounds.insertLast("doom/DSMANSIT.wav");
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.31f;
		this.walkSpeed = 8.0f;
		this.constantAttack = true;
		this.constantAttackMax = 3;
		
		self.m_FormattedName = "Mancubus";
		self.pev.health = 600;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void ShootFireball(Vector origin, Vector addangles)
	{
		Vector enemyPos = h_enemy.GetEntity().pev.origin + h_enemy.GetEntity().pev.view_ofs;
		Vector aimDir = (enemyPos - origin).Normalize();
		
		Vector angles;
		g_EngineFuncs.VecToAngles(aimDir, angles);
		angles.x = -angles.x;
		angles = angles + addangles;
		
		dictionary keys;
		keys["origin"] = origin.ToString();
		keys["angles"] = angles.ToString();
		keys["model"] = "sprites/doom/MANF.spr";
		keys["speed"] = "" + 700;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "0";
		keys["deathFrameStart"] = "16";
		keys["deathFrameEnd"] = "18";
		keys["flash_color"] = "255 80 32";
		keys["damage_min"] = "8";
		keys["damage_max"] = "64";
		keys["oriented"] = "1";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void RangeAttack(Vector aimDir)
	{
		brighten = 8;
		g_EngineFuncs.MakeVectors(pev.angles);
		
		Vector left = BodyPos() - g_Engine.v_right*32;
		Vector right = BodyPos() + g_Engine.v_right*32;
		if (rangeCombo == 0)
		{
			ShootFireball(right, Vector(0,0,0));
			ShootFireball(left, Vector(0,15,0));
		}
		else if (rangeCombo == 1)
		{
			ShootFireball(right, Vector(0,-15,0));
			ShootFireball(left, Vector(0,0,0));
		}
		else
		{
			ShootFireball(right, Vector(0,-5,0));
			ShootFireball(left, Vector(0,5,0));
		}
		
		if (++rangeCombo >= 3)
			rangeCombo = 0;
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_arachnotron : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/BSPI.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 5, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(6, 7, 1.0f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 7, 1.0f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(8, 8, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(72, 78, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(72, 78, 0.5f, false)); // ANIM_GIB		
		
		
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertAt(0, 6);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(7);
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(4);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		this.constantAttackLoopFrame = 3;
		
		idleSounds.insertLast("doom/DSBSPACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSBSPDTH.wav");
		alertSounds.insertLast("doom/DSBSPSIT.wav");
		walkSound = "doom/DSBSPWLK.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.50f;
		this.walkSpeed = 12.0f;
		this.constantAttack = true;
		
		self.m_FormattedName = "Arachnotron";
		self.pev.health = 500;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
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
		keys["model"] = "sprites/doom/BAL.spr";
		keys["speed"] = "" + 875;
		keys["moveFrameStart"] = "28";
		keys["moveFrameEnd"] = "29";
		keys["deathFrameStart"] = "30";
		keys["deathFrameEnd"] = "34";
		keys["flash_color"] = "32 255 32";
		keys["damage_min"] = "5";
		keys["damage_max"] = "40";
		keys["spawn_sound"] = "doom/DSPLASMA.wav";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_cyberdemon : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/CYBR.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 5, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 5, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 64, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(56, 64, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].frameIndices.insertLast(4);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(1);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSCYBDTH.wav");
		alertSounds.insertLast("doom/DSCYBSIT.wav");
		meleeSound = "doom/DSCLAW.wav";
		walkSound = "doom/DSHOOF.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.08f;
		this.walkSpeed = 16.0f;
		this.constantAttack = true;
		this.constantAttackMax = 3;
		
		self.m_FormattedName = "Cyberdemon";
		self.pev.health = 4000;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
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
		keys["model"] = "sprites/doom/MISL.spr";
		keys["speed"] = "" + 700;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "0";
		keys["deathFrameStart"] = "8";
		keys["deathFrameEnd"] = "10";
		keys["flash_color"] = "255 128 32";
		keys["damage_min"] = "20";
		keys["damage_max"] = "160";
		keys["oriented"] = "1";
		keys["spawn_sound"] = "doom/DSRLAUNC.wav";
		keys["death_sound"] = "doom/DSBAREXP.wav";
		keys["radius_dmg"] = "128";
		keys["trail_sprite"] = "sprites/doom/PUFF.spr";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @self.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
	}
	
	void Think()
	{
		DoomThink();
	}
}

class monster_spiderdemon : monster_doom
{
	void Spawn()
	{
		this.bodySprite = "sprites/doom/SPID.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 5, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(6, 7, 0.5f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 7, 0.5f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(8, 8, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(72, 81, 0.18f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(72, 81, 0.18f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK].attackFrames.resize(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(0);
		animInfo[ANIM_ATTACK].attackFrames.insertLast(1);
		animInfo[ANIM_ATTACK2] = animInfo[ANIM_ATTACK];
		
		animInfo[ANIM_DEAD].frameIndices.insertAt(1, 73);
		animInfo[ANIM_DEAD].frameIndices.insertAt(0, 72);
		animInfo[ANIM_GIB].frameIndices = animInfo[ANIM_DEAD].frameIndices;
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSSPIDTH.wav");
		alertSounds.insertLast("doom/DSSPISIT.wav");
		shootSound = "doom/DSSHOTGN.wav";
		walkSound = "doom/DSMETAL.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.16f;
		this.walkSpeed = 12.0f;
		this.constantAttack = true;
		
		self.m_FormattedName = "Spiderdemon";
		self.pev.health = 3000;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void RangeAttack(Vector aimDir)
	{		
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15));
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15), false);
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15), false);
	}
	
	void Think()
	{
		DoomThink();
	}
}