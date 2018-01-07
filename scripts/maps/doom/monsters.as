#include "monster_doom"

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
	string meleeSound = "doom/DSSGTATK.wav";
	
	void Spawn()
	{
		bodySprite = "sprites/doom/SARG.spr";
		
		walkSpeed = 16.0f;
		
		animInfo.insertLast(AnimInfo(0, 1, 0.125f, true)); // ANIM_IDLE
		animInfo.insertLast(AnimInfo(0, 3, 0.5f, true)); // ANIM_MOVE
		animInfo.insertLast(AnimInfo(4, 6, 0.25f, true)); // ANIM_ATTACK
		animInfo.insertLast(AnimInfo(7, 7, 0.125f, true)); // ANIM_PAIN
		animInfo.insertLast(AnimInfo(64, 69, 0.5f, false)); // ANIM_DEAD
		animInfo.insertLast(AnimInfo(64, 69, 0.5f, false)); // ANIM_GIB		
		
		animInfo[ANIM_DEAD].frameIndices.insertAt(1, 65);
		animInfo[ANIM_DEAD].frameIndices.insertAt(0, 64);
		
		idleSounds.insertLast("doom/DSDMACT.wav");
		painSound = "doom/DSDMPAIN.wav";
		deathSounds.insertLast("doom/DSSGTDTH.wav");
		alertSounds.insertLast("doom/DSSGTSIT.wav");
		
		this.hasMelee = true;
		this.hasRanged = false;
		
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