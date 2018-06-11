#include "monster_doom"

class monster_imp : monster_doom
{	
	void Spawn()
	{
		bodySprite = "sprites/doom/troo.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(69, 76, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsbgact.wav");
		painSound = "doom/dspopain.wav";
		deathSounds.insertLast("doom/dsbgdth1.wav");
		deathSounds.insertLast("doom/dsbgdth2.wav");
		alertSounds.insertLast("doom/dsbgsit1.wav");
		alertSounds.insertLast("doom/dsbgsit2.wav");
		meleeSound = "doom/dsclaw.wav";
		
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
		keys["model"] = "sprites/doom/bal.spr";
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
		this.bodySprite = "sprites/doom/poss.spr";
		
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
		
		idleSounds.insertLast("doom/dsposact.wav");
		painSound = "doom/dspopain.wav";
		deathSounds.insertLast("doom/dspodth2.wav");
		deathSounds.insertLast("doom/dspodth3.wav");
		deathSounds.insertLast("doom/dspodth1.wav");
		alertSounds.insertLast("doom/dsposit1.wav");
		alertSounds.insertLast("doom/dsposit2.wav");
		alertSounds.insertLast("doom/dsposit3.wav");
		shootSound = "doom/dspistol.wav";
		
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
		bodySprite = "sprites/doom/spos.spr";
		
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
		
		idleSounds.insertLast("doom/dsposact.wav");
		painSound = "doom/dspopain.wav";
		deathSounds.insertLast("doom/dspodth2.wav");
		deathSounds.insertLast("doom/dspodth3.wav");
		deathSounds.insertLast("doom/dspodth1.wav");
		alertSounds.insertLast("doom/dsposit1.wav");
		alertSounds.insertLast("doom/dsposit2.wav");
		shootSound = "doom/dsshotgn.wav";
		
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
		this.bodySprite = "sprites/doom/cpos.spr";
		
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
		
		idleSounds.insertLast("doom/dsposact.wav");
		painSound = "doom/dspopain.wav";
		deathSounds.insertLast("doom/dspodth2.wav");
		deathSounds.insertLast("doom/dspodth3.wav");
		deathSounds.insertLast("doom/dspodth1.wav");
		alertSounds.insertLast("doom/dsposit1.wav");
		alertSounds.insertLast("doom/dsposit2.wav");
		alertSounds.insertLast("doom/dsposit3.wav");
		shootSound = "doom/dsshotgn.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.66f;
		this.constantAttack = true;
		this.hullModel = "models/doom/null_wide.mdl";
		
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
		bodySprite = "sprites/doom/sarg.spr";
		
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
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dssgtdth.wav");
		alertSounds.insertLast("doom/dssgtsit.wav");
		meleeSound = "doom/dssgtatk.wav";
		
		this.hasMelee = true;
		this.hasRanged = false;
		this.painChance = 0.7f;
		this.hullModel = "models/doom/null_wide.mdl";
		
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
		bodySprite = "sprites/doom/head.spr";
		
		animInfo.insertLast(AnimInfo(0, 0, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 0, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(1, 3, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(1, 3, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(4, 4, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(48, 53, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(48, 53, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dscacdth.wav");
		alertSounds.insertLast("doom/dscacsit.wav");
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.canFly = true;
		this.painChance = 0.5f;
		this.hullModel = "models/doom/null_fat.mdl";
		this.largeHull = true;
		
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
		keys["model"] = "sprites/doom/bal.spr";
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
		bodySprite = "sprites/doom/pain.spr";
		
		animInfo.insertLast(AnimInfo(0, 0, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 2, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(3, 5, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(3, 5, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(6, 6, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(56, 61, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(56, 61, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dspepain.wav";
		deathSounds.insertLast("doom/dspedth.wav");
		alertSounds.insertLast("doom/dspesit.wav");
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.canFly = true;
		this.painChance = 0.5f;
		this.deathBoom = 3;
		this.hullModel = "models/doom/null_fat.mdl";
		this.largeHull = true;
		
		self.m_FormattedName = "Pain Elemental";
		self.pev.health = 400;
		
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
				if (!mon.superDormant and !mon.killPoints)
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
		Vector spawnPos = BodyPos() + flatAim*64;
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
		mon.killPoints = false;
		
		Vector soulDir = aimDir;
		if (atEnemy) 
		{
			Vector enemyPos = h_enemy.GetEntity().pev.origin + h_enemy.GetEntity().pev.view_ofs;
			soulDir = (enemyPos - soul.pev.origin).Normalize();
			mon.SetEnemy(h_enemy);
		}
		
		TraceResult tstuck;
		Vector bodyPos = mon.BodyPos();
		g_Utility.TraceHull( bodyPos, bodyPos, dont_ignore_monsters, human_hull, soul.edict(), tstuck );
		if (tstuck.fAllSolid == 1)
		{
			// blow up if got stuck/spawned inside something
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tstuck.pHit );
			if (pHit !is null)
				doomTakeDamage(pHit, mon.pev, mon.pev, mon.dashDamage, DMG_BURN);
			mon.TakeDamage(mon.pev, mon.pev, mon.pev.health, 0);
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
		bodySprite = "sprites/doom/skul.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 1, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(2, 3, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(2, 3, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(4, 4, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(40, 45, 0.5f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(40, 45, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dsfirxpl.wav");
		this.meleeSound = "doom/dssklatk.wav";
		
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
		bodySprite = "sprites/doom/boss.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 68, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dsbrsdth.wav");
		alertSounds.insertLast("doom/dsbrssit.wav");
		meleeSound = "doom/dsclaw.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.20f;
		this.hullModel = "models/doom/null_tall.mdl";
		
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
		keys["model"] = "sprites/doom/bal7.spr";
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
		bodySprite = "sprites/doom/bos2.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.25f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 68, 0.25f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 68, 0.5f, false)); // ANIM_GIB		
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dskntdth.wav");
		alertSounds.insertLast("doom/dskntsit.wav");
		meleeSound = "doom/dsclaw.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.50f;
		this.hullModel = "models/doom/null_tall.mdl";
		
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
		keys["model"] = "sprites/doom/bal7.spr";
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

class monster_archvile : monster_doom
{	
	EHandle flame;

	void Spawn()
	{
		bodySprite = "sprites/doom/vile.spr";
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 5, 0.5f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(17, 19, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(6, 15, 0.25f, true)); // ANIM_ATTACK2
		animInfo.insertLast(AnimInfo(16, 16, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(160, 168, 0.375f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(160, 168, 0.375f, false)); // ANIM_GIB		
		
		animInfo[ANIM_ATTACK2].attackFrames.resize(0);
		animInfo[ANIM_ATTACK2].attackFrames.insertLast(8);
		animInfo[ANIM_ATTACK2].frameIndices.insertLast(15);
		animInfo[ANIM_ATTACK2].frameIndices.insertLast(15);
		
		idleSounds.insertLast("doom/dsvilact.wav");
		painSound = "doom/dsvipain.wav";
		deathSounds.insertLast("doom/dsvildth.wav");
		alertSounds.insertLast("doom/dsvilsit.wav");
		meleeSound = "doom/dsvilatk.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.04f;
		this.walkSpeed = 15.0f;
		this.canRevive = true;
		this.hullModel = "models/doom/null_tall.mdl";
		
		self.m_FormattedName = "Arche-vile";
		self.pev.health = 700;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
		pev.nextthink = g_Engine.time + 0.1;
	}
	
	void CastFire()
	{
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, meleeSound, 1.0f, 0.5f, 0, 100);
		
		CBaseEntity@ enemy = h_enemy;
		
		brighten = 46;
		
		Vector bodyPos = BodyPos();
		
		dictionary keys;
		keys["origin"] = enemy.pev.origin.ToString();
		keys["model"] = "sprites/doom/fire.spr";
		keys["speed"] = "0";
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "7";
		keys["deathFrameStart"] = "7";
		keys["deathFrameEnd"] = "7";
		keys["flash_color"] = "255 255 64";
		keys["damage_min"] = "20";
		keys["damage_max"] = "64";
		keys["is_vile_fire"] = "64";
		keys["radius_dmg"] = "70";
		keys["death_sound"] = "doom/dsbarexp.wav";
		keys["spawn_sound"] = "doom/dsflame.wav";
		
		CBaseEntity@ fire = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fire.pev.owner = @self.edict();
		fireball@ ball = cast<fireball@>(CastToScriptClass(fire));
		ball.h_followEnt = self;
		ball.h_aimEnt = h_enemy;
		
		g_EntityFuncs.DispatchSpawn(fire.edict());
		fire.pev.solid = SOLID_NOT;
		fire.pev.movetype = MOVETYPE_NONE;
		fire.pev.rendermode = kRenderTransAdd;
		fire.pev.rendermode = kRenderTransTexture;
		fire.pev.renderamt = 180;
		
		flame = fire;
	}
	
	void RangeAttackStart()
	{
		CastFire();
	}
	
	void RangeAttack(Vector aimDir)
	{
		if (!flame.IsValid())
			return;
			
		fireball@ ball = cast<fireball@>(CastToScriptClass(flame.GetEntity()));
		ball.Touch(h_enemy);
		//ball.Remove();
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
		bodySprite = "sprites/doom/skel.spr";
		
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
		
		idleSounds.insertLast("doom/dsskeact.wav");
		painSound = "doom/dspopain.wav";
		deathSounds.insertLast("doom/dsskedth.wav");
		alertSounds.insertLast("doom/dsskesit.wav");
		meleeSound = "doom/dsskepch.wav";
		meleeWindupSound = "doom/dsskeswg.wav";
		
		this.hasMelee = true;
		this.hasRanged = true;
		this.painChance = 0.39f;
		this.walkSpeed = 10.0f;
		this.rangeWhenMeleeFails = false;
		this.hullModel = "models/doom/null_tall.mdl";
		
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
		keys["model"] = "sprites/doom/fatb.spr";
		keys["speed"] = "" + 350;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "1";
		keys["deathFrameStart"] = "16";
		keys["deathFrameEnd"] = "18";
		keys["flash_color"] = "255 64 32";
		keys["damage_min"] = "10";
		keys["damage_max"] = "80";
		keys["oriented"] = "1";
		keys["spawn_sound"] = "doom/dsskeatk.wav";
		keys["death_sound"] = "doom/dsbarexp.wav";
		keys["trail_sprite"] = "sprites/doom/puff.spr";
		
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
		bodySprite = "sprites/doom/fatt.spr";
		
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
		
		idleSounds.insertLast("doom/dsposact.wav");
		painSound = "doom/dsmnpain.wav";
		deathSounds.insertLast("doom/dsmandth.wav");
		alertSounds.insertLast("doom/dsmansit.wav");
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.31f;
		this.walkSpeed = 8.0f;
		this.constantAttack = true;
		this.constantAttackMax = 3;
		this.hullModel = "models/doom/null_fat.mdl";
		this.largeHull = true;
		
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
		keys["model"] = "sprites/doom/manf.spr";
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
		bodySprite = "sprites/doom/bspi.spr";
		
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
		
		idleSounds.insertLast("doom/dsbspact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dsbspdth.wav");
		alertSounds.insertLast("doom/dsbspsit.wav");
		walkSound = "doom/dsbspwlk.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.50f;
		this.walkSpeed = 12.0f;
		this.constantAttack = true;
		this.largeHull = true;
		this.hullModel = "models/doom/null_spider.mdl";
		
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
		keys["model"] = "sprites/doom/bal.spr";
		keys["speed"] = "" + 875;
		keys["moveFrameStart"] = "28";
		keys["moveFrameEnd"] = "29";
		keys["deathFrameStart"] = "30";
		keys["deathFrameEnd"] = "34";
		keys["flash_color"] = "32 255 32";
		keys["damage_min"] = "5";
		keys["damage_max"] = "40";
		keys["spawn_sound"] = "doom/dsplasma.wav";
		
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
		bodySprite = "sprites/doom/cybr.spr";
		
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
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dscybdth.wav");
		alertSounds.insertLast("doom/dscybsit.wav");
		meleeSound = "doom/dsclaw.wav";
		walkSound = "doom/dshoof.wav";
		hullModel = "models/doom/null_large.mdl";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.08f;
		this.walkSpeed = 16.0f;
		this.constantAttack = true;
		this.constantAttackMax = 3;
		this.dmgImmunity = DMG_BLAST;
		this.largeHull = true;
		this.minRangeAttackDelay = 0.5f;
		this.maxRangeAttackDelay = 1.5f;
		
		
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
		keys["model"] = "sprites/doom/misl.spr";
		keys["speed"] = "" + 700;
		keys["moveFrameStart"] = "0";
		keys["moveFrameEnd"] = "0";
		keys["deathFrameStart"] = "8";
		keys["deathFrameEnd"] = "10";
		keys["flash_color"] = "255 128 32";
		keys["damage_min"] = "20";
		keys["damage_max"] = "160";
		keys["oriented"] = "1";
		keys["spawn_sound"] = "doom/dsrlaunc.wav";
		keys["death_sound"] = "doom/dsbarexp.wav";
		keys["radius_dmg"] = "128";
		keys["trail_sprite"] = "sprites/doom/puff.spr";
		
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
		this.bodySprite = "sprites/doom/spid.spr";
		
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
		
		idleSounds.insertLast("doom/dsdmact.wav");
		painSound = "doom/dsdmpain.wav";
		deathSounds.insertLast("doom/dsspidth.wav");
		alertSounds.insertLast("doom/dsspisit.wav");
		shootSound = "doom/dsshotgn.wav";
		walkSound = "doom/dsmetal.wav";
		
		this.hasMelee = false;
		this.hasRanged = true;
		this.painChance = 0.16f;
		this.walkSpeed = 12.0f;
		this.constantAttack = true;
		this.largeHull = true;
		this.hullModel = "models/doom/null_huge.mdl";
		this.dmgImmunity = DMG_BLAST;
		
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