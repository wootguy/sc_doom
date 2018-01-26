#include "weapon_doom"

class weapon_doom_pistol : weapon_doom
{
	void Spawn()
	{
		array<FrameInfo> frameInfo = {
			FrameInfo(57, 62, 0),
			FrameInfo(79, 102, -11),
			FrameInfo(66, 81, -2),
			FrameInfo(79, 82, -11),
		};
		array<TileInfo> tileInfo = {
			TileInfo(1, 1), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 2), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		numFrames = 4;
		array<int> shootFrames = {0, 1, 2, 3};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = -5.5;

		accurateFirstShot = true;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 5;
		info.iMaxClip 	= -1;
		info.iSlot 		= 1;
		info.iPosition 	= 10;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 8;
		ShootBullet();
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_shotgun : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/shotgun.spr";
		shootSound = "doom/DSSHOTGN.wav";
		itemFrame = 121;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(79, 60, 0),
			FrameInfo(79, 82, 0),
			FrameInfo(79, 73, 0),
			FrameInfo(119, 121, -78),
			FrameInfo(87, 151, -91),
			FrameInfo(113, 131, -92),
		};
		array<TileInfo> tileInfo = {
			TileInfo(2, 1), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 3), TileInfo(2, 3),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(2, 2), TileInfo(1, 2), TileInfo(2, 2),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 2), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		array<int> shootFrames = {0, 1, 2, 3, 4, 5, 4, 3};
		numFrames = 6;
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = -2.5;
		
		spread = 9.8f;
		cooldown = 1.0f;
		frameRate = 0.12;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 4;
		info.iMaxClip 	= -1;
		info.iSlot 		= 2;
		info.iPosition 	= 10;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 11;
		
		for (int i = 0; i < 6; i++)
			ShootBullet(i > 0);
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_supershot : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/supershot.spr";
		shootSound = "doom/supershot.flac";
		itemFrame = 119;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(59, 55, 0),
			FrameInfo(59, 80, 0),
			FrameInfo(65, 80, 0),
			FrameInfo(83, 103, -34),
			FrameInfo(121, 130, -109),
			FrameInfo(81, 80, -16),
			FrameInfo(201, 63, -134),
			FrameInfo(88, 51, -29),
			FrameInfo(77, 85, -16),
		};
		array<TileInfo> tileInfo = {
			TileInfo(1, 1), TileInfo(1, 2), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 3), TileInfo(2, 2),
			TileInfo(4, 1), TileInfo(2, 1), TileInfo(2, 2), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 2), TileInfo(2, 2), TileInfo(1, 1), TileInfo(2, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(2, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		numFrames = 9;
		array<int> shootFrames = {0, 1, 2, 3, 4, 5, 6, 7, 5, 8};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = -1;
		
		spread = 18.0f;
		cooldown = 1.4f;
		frameRate = 0.15;
		ammoPerShot = 2;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 4;
		info.iMaxClip 	= -1;
		info.iSlot 		= 2;
		info.iPosition 	= 11;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 12;
		
		for (int i = 0; i < 19; i++)
			ShootBullet(i > 0);
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_rpg : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/rpg.spr";
		shootSound = "doom/DSSHOTGN.wav";
		itemFrame = 80;

		array<FrameInfo> frameInfo = {
			FrameInfo(87, 47, 0),
			FrameInfo(87, 63, 0),
			FrameInfo(102, 67, 0),
			FrameInfo(102, 74, 0),
			FrameInfo(105, 75, 1.5),
			FrameInfo(102, 43, 0),
		};
		array<TileInfo> tileInfo = {
			TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(2, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		numFrames = 6;
		array<int> shootFrames = {0, 1, 2, 3, 4, 5};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = 0;
		
		spread = 9.8f;
		cooldown = 0.5f;
		frameRate = 0.1;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 4;
		info.iPosition 	= 10;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 16;
		
		CBasePlayer@ plr = getPlayer();
		Vector vecSrc = plr.pev.origin + Vector(0,0,6);
		Vector angles = plr.pev.v_angle;
		
		dictionary keys;
		keys["origin"] = vecSrc.ToString();
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
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @plr.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
		
		int ammoLeft = plr.m_rgAmmo(self.m_iPrimaryAmmoType);
		plr.m_rgAmmo(self.m_iPrimaryAmmoType, ammoLeft-ammoPerShot);
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_fist : weapon_doom
{
	int damage_min = 2;
	int damage_max = 20;
	void Spawn()
	{
		hud_sprite = "sprites/doom/fist.spr";
		shootSound = "doom/DSPUNCH.wav";
		
		array<FrameInfo> frameInfo = {
			FrameInfo(113, 42, 0),
			FrameInfo(80, 41, -84),
			FrameInfo(107, 52, -99),
			FrameInfo(147, 76, -115),
		};
		array<TileInfo> tileInfo = {
			TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(3, 2), TileInfo(2, 1), TileInfo(1, 1),
			TileInfo(2, 1), TileInfo(2, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(2, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		array<int> shootFrames = {1, 2, 3, 2, 1};
		attackFrame = 1;
		numFrames = 4;
		this.tileInfo = tileInfo;
		this.shootFrames = shootFrames;
		this.frameInfo = frameInfo;
		wepOffsetX = 60;
		
		spread = 0;
		cooldown = 0.48f;
		frameRate = 0.1;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 0;
		info.iPosition 	= 10;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		if (Slash(Math.RandomLong(damage_min, damage_max)))
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_chainsaw : weapon_doom
{
	string missSound = "doom/DSSAWFUL.wav";
	string idleSound = "doom/DSSAWIDL.wav";
	float nextIdleSound = 0;
	float nextFrame = 0;
	int idleFrame = 0;
	
	void Spawn()
	{
		hud_sprite = "sprites/doom/chainsaw.spr";
		shootSound = "doom/DSSAWHIT.wav";
		deploySound = "doom/DSSAWUP.wav";
		itemFrame = 46;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(153, 89, 0),
			FrameInfo(154, 89, -2),
			FrameInfo(140, 55, 0),
			FrameInfo(140, 55, 0),
		};
		array<TileInfo> tileInfo = {
			TileInfo(3, 2), TileInfo(3, 2), TileInfo(3, 1), TileInfo(3, 1), TileInfo(2, 1), TileInfo(2, 1),
			TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		array<int> shootFrames = {2, 3, 2};
		attackFrame = 1;
		numFrames = 4;
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = -5;
		
		constantAttack = true;
		
		spread = 0;
		cooldown = 0.2f;
		frameRate = 0.1f;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 200;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 200;
		info.iSlot 		= 0;
		info.iPosition 	= 11;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		nextIdleSound = g_Engine.time + cooldown;
		CBasePlayer@ plr = getPlayer();
		if (Slash(Math.RandomLong(2,20)))
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		else
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, missSound, 1.0f, 0.5f, 0, 100);
		
	}
	
	void Think()
	{
		WeaponThink();
	}
	
	void WeaponIdle()
	{
		if (nextIdleSound < g_Engine.time)
		{
			CBasePlayer@ plr = getPlayer();
			nextIdleSound = g_Engine.time + 0.22f;
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, idleSound, 1.0f, 0.5f, 0, 100);
		}
		
		if (!shooting and nextFrame < g_Engine.time)
		{
			nextFrame = g_Engine.time + frameRate*2;
			SetFrame(idleFrame++ % 2 == 0 ? 1 : 0);
		}
	}
}

class weapon_doom_chaingun : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/chaingun.spr";
		itemFrame = 86;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(114, 51, 0),
			FrameInfo(114, 70, 0),
			FrameInfo(114, 71, 0),
		};
		array<TileInfo> tileInfo = {
			TileInfo(2, 1), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		numFrames = 3;
		array<int> shootFrames = {1, 2};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		this.frameInfo = frameInfo;
		wepOffsetX = -1;
		
		constantAttack = true;
		frameRate = 0.12;
		cooldown = 0.22f;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 5;
		info.iMaxClip 	= -1;
		info.iSlot 		= 3;
		info.iPosition 	= 10;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 5;
		ShootBullet();
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_plasmagun : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/plasmagun.spr";
		shootSound = "doom/DSPLASMA.wav";
		itemFrame = 95;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(83, 61, 0),
			FrameInfo(83, 75, 0),
			FrameInfo(85, 73, 0),
			FrameInfo(104, 111, 0),
		};
		array<TileInfo> tileInfo = {
			TileInfo(2, 1), TileInfo(2, 2), TileInfo(2, 2), TileInfo(2, 2), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(2, 2), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		numFrames = 4;
		array<int> shootFrames = {1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		attackFrame = 0;
		this.frameInfo = frameInfo;
		wepOffsetX = 0;
		
		spread = 9.8f;
		cooldown = 0.075f;
		frameRate = 0.05f;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 20;
		info.iMaxClip 	= -1;
		info.iSlot 		= 5;
		info.iPosition 	= 11;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void Attack()
	{
		brighten = 8;
		
		CBasePlayer@ plr = getPlayer();
		g_EngineFuncs.MakeVectors(plr.pev.v_angle);
		Vector vecSrc = plr.pev.origin + Vector(0,0,6);
		Vector angles = plr.pev.v_angle;
		
		dictionary keys;
		keys["origin"] = vecSrc.ToString();
		keys["angles"] = angles.ToString();
		keys["model"] = "sprites/doom/BAL.spr";
		keys["speed"] = "" + 875;
		keys["moveFrameStart"] = "13";
		keys["moveFrameEnd"] = "14";
		keys["deathFrameStart"] = "15";
		keys["deathFrameEnd"] = "19";
		keys["flash_color"] = "64 64 255";
		keys["damage_min"] = "5";
		keys["damage_max"] = "40";
		keys["spawn_sound"] = "";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @plr.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
		
		int ammoLeft = plr.m_rgAmmo(self.m_iPrimaryAmmoType);
		plr.m_rgAmmo(self.m_iPrimaryAmmoType, ammoLeft-ammoPerShot);
		
		g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, shootSound, 0.8f, 0.5f, 0, 100);
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class weapon_doom_bfg : weapon_doom
{
	void Spawn()
	{
		hud_sprite = "sprites/doom/bfg.spr";
		shootSound = "doom/DSBFG.wav";
		numFrames = 4;
		itemFrame = 14;
		
		array<FrameInfo> frameInfo = {
			FrameInfo(170, 52, 0),
			FrameInfo(170, 70, 0),
			FrameInfo(170, 91, 0),
			FrameInfo(170, 52, 0),
		};
		array<TileInfo> tileInfo = {
			TileInfo(3, 1), TileInfo(3, 2), TileInfo(3, 2), TileInfo(3, 1), TileInfo(2, 1), TileInfo(2, 1),
			TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1), TileInfo(2, 1),
			TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1), TileInfo(1, 1),
		};
		array<int> shootFrames = {0, 0, 0, 1, 1, 2, 3, 3, 3};
		this.shootFrames = shootFrames;
		this.tileInfo = tileInfo;
		attackFrame = 5;
		this.frameInfo = frameInfo;
		wepOffsetX = -0.5;
		
		spread = 9.8f;
		cooldown = 1.1f;
		frameRate = 0.2f;
		ammoPerShot = 40;
		
		DoomSpawn();
		
		SetThink( ThinkFunction( Think ) );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 999999;
		info.iMaxAmmo2 	= -1;
		info.iAmmo1Drop	= 20;
		info.iMaxClip 	= -1;
		info.iSlot 		= 5;
		info.iPosition 	= 12;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	void FrameUpdated()
	{
		if (frameIdx == 1)
		{
			CBasePlayer@ plr = getPlayer();
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, shootSound, 0.8f, 0.5f, 0, 100);
		}
		if (animFrame == 1 or animFrame == 2)
			brighten = 12;
	}
	
	void Attack()
	{
		brighten = 8;
		
		CBasePlayer@ plr = getPlayer();
		g_EngineFuncs.MakeVectors(plr.pev.v_angle);
		Vector vecSrc = plr.pev.origin + Vector(0,0,6) + g_Engine.v_forward*22;
		Vector angles = plr.pev.v_angle;
		
		dictionary keys;
		keys["origin"] = vecSrc.ToString();
		keys["angles"] = angles.ToString();
		keys["model"] = "sprites/doom/BAL.spr";
		keys["speed"] = "" + 875;
		keys["moveFrameStart"] = "20";
		keys["moveFrameEnd"] = "21";
		keys["deathFrameStart"] = "22";
		keys["deathFrameEnd"] = "27";
		keys["flash_color"] = "64 255 64";
		keys["damage_min"] = "100";
		keys["damage_max"] = "800";
		keys["bbox_size"] = "8";
		keys["spawn_sound"] = "";
		keys["is_bfg"] = "1";
		keys["death_sound"] = "doom/DSRXPLOD.wav";
		
		CBaseEntity@ fireball = g_EntityFuncs.CreateEntity("fireball", keys, false);
		@fireball.pev.owner = @plr.edict();
		g_EntityFuncs.DispatchSpawn(fireball.edict());
		
		int ammoLeft = plr.m_rgAmmo(self.m_iPrimaryAmmoType);
		plr.m_rgAmmo(self.m_iPrimaryAmmoType, ammoLeft-ammoPerShot);
	}
	
	void Think()
	{
		WeaponThink();
	}
}

class ammo_doom_bullets : ammo_doom
{
	void Spawn()
	{
		ammoType = "bullets";
		giveAmmo = 5;
		maxAmmo = 200;
		itemFrame = 37;
		AmmoSpawn();
	}
}

class ammo_doom_bulletbox : ammo_doom
{
	void Spawn()
	{
		ammoType = "bullets";
		giveAmmo = 50;
		maxAmmo = 200;
		itemFrame = 0;
		AmmoSpawn();
	}
}

class ammo_doom_shells : ammo_doom
{
	void Spawn()
	{
		ammoType = "shells";
		giveAmmo = 4;
		maxAmmo = 100;
		itemFrame = 120;
		AmmoSpawn();
	}
}

class ammo_doom_shellbox : ammo_doom
{
	void Spawn()
	{
		ammoType = "shells";
		giveAmmo = 20;
		maxAmmo = 100;
		itemFrame = 118;
		AmmoSpawn();
	}
}

class ammo_doom_rocket : ammo_doom
{
	void Spawn()
	{
		ammoType = "rockets";
		giveAmmo = 1;
		maxAmmo = 100;
		itemFrame = 115;
		AmmoSpawn();
	}
}

class ammo_doom_rocketbox : ammo_doom
{
	void Spawn()
	{
		ammoType = "rockets";
		giveAmmo = 5;
		maxAmmo = 100;
		itemFrame = 26;
		AmmoSpawn();
	}
}

class ammo_doom_cells : ammo_doom
{
	void Spawn()
	{
		ammoType = "cells";
		giveAmmo = 20;
		maxAmmo = 600;
		itemFrame = 32;
		AmmoSpawn();
	}
}

class ammo_doom_cellbox : ammo_doom
{
	void Spawn()
	{
		ammoType = "cells";
		giveAmmo = 100;
		maxAmmo = 600;
		itemFrame = 33;
		AmmoSpawn();
	}
}
