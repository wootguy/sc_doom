#include "utils"

const int FL_DISABLE_RESPAWN = 1024;

class FrameInfo
{
	int width, height;
	float offsetX;
	
	FrameInfo() {}
	
	FrameInfo(int width, int height, float offsetX)
	{
		this.width = width;
		this.height = height;
		this.offsetX = offsetX;
	}
}

class TileInfo
{
	int x, y;
	
	TileInfo() {}
	
	TileInfo(int x, int y)
	{
		this.x = x;
		this.y = y;
	}
}

array<float> g_spr_scales = {8, 5, 3.5f, 2.5f};

class weapon_doom : ScriptBasePlayerWeaponEntity
{
	string hud_sprite = "sprites/doom/pistol.spr";
	float m_flNextAnimTime;
	bool active = false;
	float lastAttack = 0;
	int scaleChoice = 0;
	float sprScale = 1;
	int itemFrame = 25;
	
	// frame info
	array<FrameInfo> frameInfo;
	array<TileInfo> tileInfo;
	array<int> shootFrames = {0, 1, 2, 3};
	int numFrames = 0;
	bool shooting = false;
	bool firstShot = false;
	bool accurateFirstShot = false;
	int attackFrame = 1;
	int frameIdx = 0;
	bool constantAttack = false; // attack every frame
	float lastAttackButton = 0; // attack button held? (needed for laggy players)
	int lastHudX, lastHudY, lastHudFrame, lastHudLightLevel, lastHudOpacity;
	
	// HUD sprite vars
	float wepx = 0;
	float wepy = 0;
	float wepMoveScale = 1.0f;
	float wepOffsetX = 0;
	int frameOffsetX = 0;
	int frameOffsetY = 0;
	int wepHeight;
	float r = 0;
	int frame = 0;
	int animFrame = 0;
	int tileFrame = 0;
	float frameTime = 0;
	float lastHud = 0;
	float lastHudUpdate = 0;
	float frameRate = 0.14f;
	float brighten = 0;
	float spread = 5.5f;
	float cooldown = 0.4;
	int ammoPerShot = 1;
	int unlockType = 0;
	
	bool shouldRespawn = false;
	
	string shootSound = "doom/dspistol.wav";
	string deploySound;
	
	string panims = "python";
	string pmodel = "models/doom/null.mdl";
	float reloadAnimSpeed = 0; // 0 for no anim
	float nextReloadAnim = 0;
	
	float nextViewToggle = 0;
	
	EHandle renderEnt;
	
	void Precache()
	{
		self.PrecacheCustomModels();
		shootSound = PrecacheSound(shootSound);
		deploySound = PrecacheSound(deploySound);
		hud_sprite = PrecacheModel(hud_sprite);
		PrecacheModel(pmodel);
	}
	
	void ChooseScale(int i)
	{
		scaleChoice = i;
		sprScale = g_spr_scales[i];
		SetFrame(animFrame);
	}
	
	void DoomSpawn()
	{
		ChooseScale(1);
		Precache();
		//g_EntityFuncs.SetModel( self, fixPath("sprites/doom/objects.spr") );
		g_EntityFuncs.SetModel( self, fixPath("models/doom/null.mdl") );
		self.m_iClip = -1;
		self.pev.frame = itemFrame;
		self.FallInit();
		
		pev.gravity = 4;
		
		// spawning now would cause wrong sprite to be used for some reason
		g_Scheduler.SetTimeout("delay_render_wep", 0, EHandle(self));
		
		shouldRespawn = true;
	}
	
	void SpawnRenderEnt()
	{
		if (renderEnt)
			return;
		dictionary ckeys;
		ckeys["origin"] = pev.origin.ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
		ckeys["model"] = fixPath("sprites/doom/objects.spr");
		ckeys["spawnflags"] = "1";
		ckeys["rendermode"] = "2";
		ckeys["renderamt"] = "255";
		ckeys["rendercolor"] = "255 255 255";
		ckeys["scale"] = string(g_monster_scale);
		CBaseEntity@ sprite = g_EntityFuncs.CreateEntity("env_sprite", ckeys, true);
		g_EntityFuncs.SetSize(sprite.pev, Vector(0,0,0), Vector(0,0,0)); 
		sprite.pev.solid = SOLID_NOT;
		sprite.pev.frame = itemFrame;
		renderEnt = sprite;
		
		sprite.pev.movetype = MOVETYPE_TOSS;
		sprite.pev.velocity = pev.velocity;
		sprite.pev.friction = pev.friction;
		sprite.pev.gravity = pev.gravity;
		
		g_Scheduler.SetTimeout("delay_follow", 0.0, EHandle(sprite), EHandle(self));
		
		int light_level = self.Illumination();
		//println("ILLUM " + light_level);
		sprite.pev.rendercolor = Vector(light_level, light_level, light_level);
	}
	
	CBasePlayer@ getPlayer()
	{
		CBaseEntity@ e_plr = self.m_hPlayer;
		return cast<CBasePlayer@>(e_plr);
	}
	
	void RenderHUD()
	{
		CBasePlayer@ plr = getPlayer();
		PlayerState@ state = getPlayerState(plr);
		if (state.uiScale != scaleChoice)
			ChooseScale(state.uiScale);
		
		float delta = g_Engine.time - lastHud;
		float timeScale = delta / 0.025;
		
		frameTime += delta;
		while (shooting and frameTime > frameRate)
		{
			frameIdx += 1;
			if (frameIdx < int(shootFrames.length()))
			{
				SetFrame(shootFrames[frameIdx]);
				
				if (frameIdx == attackFrame or constantAttack)
				{
					EmitSound();
					Attack();
				}
			}
			else
			{
				SetFrame(0);
				shooting = false;
				break;
			}
			frameTime -= frameRate;
		}
		
		if (brighten > 0)
			brighten -= timeScale;
		
		wepx = cos(r)*16*sprScale;
		wepy = abs(sin(r)*16*sprScale);
		
		if (plr.pev.button & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) == 0 or plr.pev.velocity.Length() < 10 or shooting)
		{
			wepMoveScale -= 0.1f*timeScale;
			if (wepMoveScale < 0)
				wepMoveScale = 0;
		}
		else
		{
			r += 0.1f*timeScale;
			wepMoveScale += 0.1f*timeScale;
			if (wepMoveScale > 1.0f)
				wepMoveScale = 1.0f;
		}
		wepx *= wepMoveScale;
		wepy *= wepMoveScale;
		
		int wepOffsetXScaled = int(wepOffsetX*sprScale);
		
		if (frameOffsetY > 0)
		{
			frameOffsetY -= int( ((frameInfo[0].height*sprScale)/20)*timeScale );
			if (frameOffsetY < 0)
				frameOffsetY = 0;
		}
		
		int light_level = plr.Illumination();
		light_level += int(brighten*64);
		if (light_level > 255)
			light_level = 255;
			
		int opacity = plr.pev.rendermode == 0 ? 255 : int(plr.pev.renderamt);
		
		bool needsUpdate = true;
		if (lastHudX == int(wepx + wepOffsetXScaled) and lastHudY == int(wepy + frameOffsetY) and lastHudLightLevel == light_level and
			lastHudOpacity == opacity)
		{
			needsUpdate = false;
		}
		
		if (needsUpdate or lastHudFrame != frame)
		{
			HUDSpriteParams params;
			params.spritename = hud_sprite.SubString("sprites/".Length());
			params.width = 0;
			int renderFlag = opacity == 255 ? int(HUD_SPR_MASKED) : 0;
			params.flags = renderFlag | HUD_ELEM_SCR_CENTER_X | HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_NO_BORDER;
			params.holdTime = 99999.0f;
			params.color1 = RGBA( light_level, light_level, light_level, opacity );
			
			for (int y = 0; y < 2; y++)
			{
				for (int x = 0; x < 4; x++)
				{
					int tile = y*tileInfo[tileFrame].x + x;
					
					if (y < tileInfo[tileFrame].y and x < tileInfo[tileFrame].x and state.viewMode == ViewMode_FirstPerson)
					{
						int partOffsetX = Math.min(512, int(frameInfo[animFrame].width*sprScale - x*512)) / 2;
						//println("X OFFSET: " + wepx + " " + partOffsetX);
						int superOffsetX = int(frameInfo[animFrame].width*sprScale) / 2;
						int customOffsetX = int(frameInfo[animFrame].offsetX*sprScale);
						int subFrameOffsetX = partOffsetX - superOffsetX + x*512 + customOffsetX + wepOffsetXScaled;
						
						int heightAfter = Math.min(512, Math.max(0, wepHeight - 512*(y+1)) );
						int subOffsetY = -heightAfter + y*512;
						
						//println("EXTRA HEIGHT " + subOffsetY + " TILES " + frameInfo[animFrame].tilesY);
						params.channel = tile;
						params.frame = frame + tile;
						params.x = wepx + subFrameOffsetX;
						params.y = -0.1 + wepy + frameOffsetY + subOffsetY;
						params.height = wepHeight;
						if (params.y > 0)
						{
							params.height -= int(params.y) + 1;
							params.y -= int(params.y) + 1;
						}
						
						g_PlayerFuncs.HudCustomSprite(plr, params);
					}
					else
						g_PlayerFuncs.HudToggleElement(plr, tile, false);
				}
			}
			
			lastHudUpdate = g_Engine.time;
		}
		
		// keep attacking or else laggy players can't attack very fast
		if (lastAttackButton + 0.1f > g_Engine.time)
			PrimaryAttack();
		
		lastHudX = int(wepx + wepOffsetXScaled);
		lastHudY = int(wepy + frameOffsetY);
		lastHudFrame = frame;
		lastHudLightLevel = light_level;
		lastHudOpacity = opacity;
		
		lastHud = g_Engine.time;
	}
	
	bool Deploy()
	{
		bool bResult = self.DefaultDeploy( self.GetV_Model( fixPath("models/doom/null.mdl") ), 
											self.GetP_Model( fixPath(pmodel) ), 3, panims );
		active = true;
		pev.nextthink = g_Engine.time;
		SetFrame(0);
		frameOffsetY = int(frameInfo[0].height*sprScale);
		lastHud = g_Engine.time;
		
		CBasePlayer@ plr = getPlayer();
		PlayerState@ state = getPlayerState(plr);
		ChooseScale(state.uiScale);
		
		if (deploySound.Length() > 0)
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, deploySound, 1.0f, 0.5f, 0, 100);
		
		return true;
	}
	
	void Holster(int iSkipLocal = 0) 
	{
		CBasePlayer@ plr = getPlayer();
		for (int i = 0; i < 8; i++)
		{
			HUDSpriteParams params;
			params.channel = i;
			g_PlayerFuncs.HudCustomSprite(plr, params);
		}
		
		active = false;
	}
	
	void SetFrame(int f)
	{
		animFrame = f;
		frame = 0;
		// skip scaled up sets
		int k = 0;
		for (k = 0; k < scaleChoice; k++)
			for (int i = 0; i < numFrames; i++)
				frame += tileInfo[k*numFrames + i].x * tileInfo[k*numFrames + i].y;
				
		tileFrame = k*numFrames;
			
		for (int i = 0; i < f; i++)
			frame += tileInfo[tileFrame + i].x * tileInfo[tileFrame + i].y;
			
		tileFrame += f;
		
		//println("Tiles: " + tileInfo[tileFrame].x + " " + tileInfo[tileFrame].y);
			
		wepHeight = int(frameInfo[f].height*sprScale);
		//frameOffsetX = int((frameInfo[f].width/2 + frameInfo[f].offsetX)*sprScale);
		frameOffsetX = frameInfo[f].width/2;
		FrameUpdated();
	}
	
	void Attack()
	{
		println("Attack not implemented!");
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if (pActivator.IsPlayer())
		{
			TraceResult tr;
			g_Utility.TraceLine( pev.origin, pActivator.pev.origin, dont_ignore_monsters, pActivator.edict(), tr );
			if (tr.flFraction >= 1.0f)
				self.Touch(pActivator);
		}
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
			
			// add to ammo if clip is not used (grenades, snarks, etc.)
			int ammoType = self.m_iPrimaryAmmoType;
			if (ammoType != -1)
			{
				int ammoLeft = pPlayer.m_rgAmmo(ammoType);
				pPlayer.m_rgAmmo(ammoType, ammoLeft + self.m_iDefaultAmmo);
			}
			
			g_EntityFuncs.Remove(renderEnt);
			unlock_item(true, unlockType);
			
			return true;
		}
		return false;
	}
	
	bool AddWeapon()
	{
		if (shouldRespawn and (pev.spawnflags & FL_DISABLE_RESPAWN) == 0)
		{
			CBaseEntity@ ent = g_EntityFuncs.Create(pev.classname, pev.origin, pev.angles, false); 
			//g_SoundSystem.EmitSoundDyn( ent.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM, 0, 150 );
			weapon_doom@ wep = cast<weapon_doom@>(CastToScriptClass(ent));
			wep.shouldRespawn = true; // respawn this one, too
		}
		
		return true;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}
	
	void FrameUpdated()
	{
		
	}
	
	void EmitSound()
	{
		CBasePlayer@ plr = getPlayer();
		PlayerState@ state = getPlayerState(plr);
		int dist = 2018;
		@state.soundNode = getSoundNode(plr.pev.origin);
		GetSoundEntInstance().InsertSound(4, plr.pev.origin, dist, 0.0f, plr);
	}
	
	void Shoot()
	{
		CBasePlayer@ plr = getPlayer();
		PlayerState@ state = getPlayerState(plr);
		state.lastAttack = g_Engine.time;
		
		frameIdx = 0;
		SetFrame(shootFrames[0]);
		
		frameTime = frameRate*0.25f;
		lastHud = g_Engine.time;
		pev.nextthink = g_Engine.time;
		
		if (constantAttack or attackFrame == 0)
		{
			EmitSound();
			Attack();
		}
		
		shooting = true;
	}
	
	void PrimaryAttack()
	{
		CBasePlayer@ plr = getPlayer();
		if (plr.pev.button & IN_ATTACK != 0)
			lastAttackButton = g_Engine.time;
		
		if (lastAttack + cooldown < g_Engine.time and (plr.pev.button & IN_ATTACK != 0 or lastAttackButton + 0.1f > g_Engine.time))
		{			
			if (self.m_iPrimaryAmmoType != -1)
			{
				int ammoLeft = plr.m_rgAmmo(self.m_iPrimaryAmmoType);
				if (ammoLeft < ammoPerShot)
					return;
			}
			
			firstShot = accurateFirstShot and g_Engine.time - lastAttack > cooldown + 0.1f;
			lastAttack = g_Engine.time;
			
			if (reloadAnimSpeed > 0) {
				nextReloadAnim = g_Engine.time + 0.4;
			}
			Shoot();
		}
	}
	
	void toggleThirdPerson()
	{
		if (nextViewToggle > g_Engine.time) {
			return;
		}
		nextViewToggle = g_Engine.time + 0.5f;
		PlayerState@ state = getPlayerState(getPlayer());
		
		if (state.viewMode == ViewMode_FirstPerson) {
			state.viewMode = ViewMode_ThirdPerson;
		} else {
			state.viewMode = ViewMode_FirstPerson;
		}
		lastHudLightLevel = -1234; // force a hud update
	}
	
	void SecondaryAttack()
	{
		toggleThirdPerson();
	}
	
	void TertiaryAttack()
	{
		openPlayerMenu(getPlayer());
	}
	
	void WeaponThink()
	{
		if (pev.movetype != MOVETYPE_FOLLOW)
			SpawnRenderEnt();
				
		if (!active)
			return;
	
		RenderHUD();
		
		CBasePlayer@ plr = getPlayer();
		if (nextReloadAnim != 0 and nextReloadAnim < g_Engine.time) {
			nextReloadAnim = 0;
			
			plr.m_Activity = ACT_RELOAD;
			plr.pev.frame = 0;
			plr.pev.sequence = 66;
			
			plr.ResetSequenceInfo();
			plr.pev.framerate = reloadAnimSpeed;
		}
		
		PlayerState@ state = getPlayerState(plr);
		plr.SetViewMode(state.viewMode);
		
		pev.nextthink = g_Engine.time;
	}
	
	void ShootBullet(bool extraShot=false)
	{
		CBasePlayer@ plr = getPlayer();
		
		Vector vecSrc = plr.GetGunPosition();
		
		Math.MakeVectors( plr.pev.v_angle );
		
		float damage = Math.RandomLong(5, 15);
		HitScan(plr, vecSrc, g_Engine.v_forward, firstShot ? 0 : spread, damage);

		plr.SetAnimation( PLAYER_ATTACK1 );
		
		if (!extraShot)
		{
			int ammoLeft = plr.m_rgAmmo(self.m_iPrimaryAmmoType);
			plr.m_rgAmmo(self.m_iPrimaryAmmoType, ammoLeft-ammoPerShot);
		
			int flash_size = 20;
			int flash_life = 1;
			int flash_decay = 0;
			Color flash_color = Color(255, 160, 64);
			te_dlight(pev.origin, flash_size, flash_color, flash_life, flash_decay);
			
			g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, shootSound, 1.0f, 0.5f, 0, 100);
		}
	}

	bool Slash(float damage)
	{
		CBasePlayer@ plr = getPlayer();
		Math.MakeVectors( plr.pev.v_angle );
		Vector vecSrc = plr.GetGunPosition();
		TraceResult tr;
		Vector attackDir = g_Engine.v_forward;
		g_Utility.TraceLine( vecSrc, vecSrc + attackDir*80*g_world_scale, dont_ignore_monsters, plr.edict(), tr );
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		plr.SetAnimation( PLAYER_ATTACK1 );
		
		if (phit !is null and tr.flFraction < 1.0f)
		{
			if (phit.IsBSPModel())
				doomBulletImpact(tr.vecEndPos, tr.vecPlaneNormal, phit);
			g_WeaponFuncs.ClearMultiDamage();
			TraceAttack(phit, plr.pev, damage, attackDir, tr, DMG_SLASH);
			g_WeaponFuncs.ApplyMultiDamage(plr.pev, plr.pev);
			return !phit.IsBSPModel();
		}
		return false;
	}
}

void delay_render_ammo(EHandle h_ent)
{
	if (!h_ent.IsValid())
		return;
		
	ammo_doom@ ent = cast<ammo_doom@>(CastToScriptClass(h_ent.GetEntity()));		
	ent.SpawnRenderEnt();
}

void delay_render_wep(EHandle h_ent)
{
	if (!h_ent.IsValid())
		return;
		
	weapon_doom@ ent = cast<weapon_doom@>(CastToScriptClass(h_ent.GetEntity()));		
	ent.SpawnRenderEnt();
}

void delay_follow(EHandle h_ent, EHandle h_follow)
{
	if (!h_ent.IsValid())
		return;
	if (!h_follow.IsValid() or h_follow.GetEntity().pev.effects & EF_NODRAW != 0)
	{
		g_EntityFuncs.Remove(h_ent);
		return;
	}
	
	CBaseEntity@ ent = h_ent;
	CBaseEntity@ follow = h_follow;

	if ( ((ent.pev.origin - follow.pev.origin)).Length() > 8)
	{
		ent.pev.origin = follow.pev.origin;
		ent.pev.velocity = follow.pev.velocity;
	}
	
	g_Scheduler.SetTimeout("delay_follow", follow.pev.velocity.Length() > 0 ? 0.05f : 0.5f, h_ent, h_follow);
}

class ammo_doom : ScriptBasePlayerAmmoEntity
{	
	int itemFrame;
	int giveAmmo;
	string ammoType;
	int maxAmmo;
	string giveWeapon; // give this weapon if player doesn't have it already
	EHandle renderEnt;
	
	void AmmoSpawn()
	{
		g_EntityFuncs.SetModel( self, fixPath("models/doom/null.mdl") ); // game crashes if this is a sprite
		BaseClass.Spawn();

		// set the model we actually want
		//g_EntityFuncs.SetModel( self, fixPath("sprites/doom/objects.spr") );
		pev.frame = itemFrame;
		pev.scale = g_monster_scale;
		pev.gravity = 4;
		
		int light_level = self.Illumination();
		//println("ILLUM " + light_level);
		pev.rendercolor = Vector(light_level, light_level, light_level);
		
		g_EntityFuncs.SetSize(self.pev, Vector(-8, -8, -4), Vector(8, 8, 8));
		
		// spawning now would cause wrong sprite to be used for some reason
		g_Scheduler.SetTimeout("delay_render_ammo", 0.0, EHandle(self));
	}
	
	void SpawnRenderEnt()
	{
		if (renderEnt)
			return;
			
		dictionary ckeys;
		ckeys["origin"] = pev.origin.ToString(); // sprite won't spawn if origin is in a bad place (outside world?)
		ckeys["model"] = fixPath("sprites/doom/objects.spr");
		ckeys["spawnflags"] = "1";
		ckeys["rendermode"] = "2";
		ckeys["renderamt"] = "255";
		ckeys["rendercolor"] = "255 255 255";
		ckeys["scale"] = string(g_monster_scale);
		CBaseEntity@ sprite = g_EntityFuncs.CreateEntity("item_generic", ckeys, true);
		g_EntityFuncs.SetSize(sprite.pev, Vector(0,0,0), Vector(0,0,0));
		sprite.pev.solid = SOLID_NOT;
		sprite.pev.frame = itemFrame;
		renderEnt = sprite;
		
		sprite.pev.movetype = MOVETYPE_TOSS;
		sprite.pev.velocity = pev.velocity;
		sprite.pev.friction = pev.friction;
		sprite.pev.gravity = pev.gravity;
		
		g_Scheduler.SetTimeout("delay_follow", 0.0, EHandle(sprite), EHandle(self));
		
		int light_level = self.Illumination();
		//println("ILLUM " + light_level);
		sprite.pev.rendercolor = Vector(light_level, light_level, light_level);
	}
	
	void Precache()
	{
		BaseClass.Precache();
	}
	
	bool AddAmmo( CBaseEntity@ pOther ) 
	{
		if (!pOther.IsPlayer())
			return false;

		CBasePlayer@ plr = cast<CBasePlayer@>(pOther);
		
		bool playPickupSound = true;
		if (giveWeapon.Length() > 0)
		{
			if (@plr.HasNamedPlayerItem(giveWeapon) == null)
			{
				plr.GiveNamedItem(giveWeapon, 0, 0);
				playPickupSound = false;
			}
		}
		
		// I don't like that you have to code a max ammo in each weapon. So I'm doing the math here.
		int should_give = giveAmmo;
		int total_ammo = plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex(ammoType));
		if (total_ammo >= maxAmmo)
			return false;
		else
			should_give = Math.min(maxAmmo - total_ammo, giveAmmo);
		
		int ret = pOther.GiveAmmo( should_give, ammoType, maxAmmo );
		if (ret != -1)
		{
			g_PlayerFuncs.ScreenFade(plr, Vector(255, 240, 64), 0.2f, 0, 32, FFADE_IN);
			if (playPickupSound)
			{
				string pickupSound = giveWeapon.Length() > 0 ? "doom/dswpnup.wav" : "doom/dsitemup.wav";
				g_SoundSystem.PlaySound(plr.edict(), CHAN_WEAPON, fixPath(pickupSound), 1.0f, 0.5f, 0, 100);
			}
			g_EntityFuncs.Remove(renderEnt);
			g_EntityFuncs.Remove(self);
			return true;
		}
		return false;
	}
}