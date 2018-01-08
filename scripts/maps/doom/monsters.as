#include "monster_doom"

class monster_imp : monster_doom
{	
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
		alertSounds.insertLast("doom/DSPOSIT3.wav");
		shootSound = "doom/DSPISTOL.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.78f;
		
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
		shootSound = "doom/DSSHOTGN.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.66f;
		
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
		ShootBullet(aimDir, 22.0f, Math.RandomLong(3, 15));
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

class monster_lostsoul : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/SKUL.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(2, 3, 0.25f, true)); // ANIM_ATTACK
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
		Dash(aimDir.Normalize()*20, Math.RandomLong(3, 24), 1.0f);
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
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(69, 76, 0.5f, false)); // ANIM_GIB		
		
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
