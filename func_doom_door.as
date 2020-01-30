const int SF_DOOR_START_OPEN = 1;
const int SF_DOOR_USE_ONLY = 256;
const int SF_DOOR_NO_AUTO_RETURN = 32;
const int FL_DOOR_BUTTON_DONT_MOVE = 2;

void reset_but(EHandle h_ent)
{
	if (!h_ent.IsValid())
		return;
	func_doom_door@ ent = cast<func_doom_door@>(CastToScriptClass(h_ent.GetEntity()));
	ent.ButtonReset();
}

void delay_use(EHandle button, EHandle pActivator, int useType, float value, bool wasShot)
{
	if (!button.IsValid() or !pActivator.IsValid())
		return;
		
	func_doom_door@ but = cast<func_doom_door@>(CastToScriptClass(button.GetEntity()));
	but.Useit(pActivator.GetEntity(), pActivator.GetEntity(), USE_TYPE(useType), value, wasShot);
}

class func_doom_door : ScriptBaseEntity
{	
	Vector m_vecPosition1;
	Vector m_vecPosition2;
	Vector m_vecFinalDest;
	int m_toggle_state;
	int dir;
	float m_flLip;
	float m_flWait;
	float lastCrush;
	bool m_bIsReopening;
	bool isButton;
	bool always_use;
	int lock = 0; // keys required to open (bitfield)
	int sounds = 0;
	bool touch_opens = false;
	bool isCrusher = false;
	bool shootable = false;
	Vector useDir;
	string sync;
	float attn = 0.6f;
	
	string switchSnd;
	string openSnd;
	string closeSnd;
	
	array<EHandle> sync_buttons; // buttons to move with the door
	EHandle parent;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{		
		if (szKey == "dir") dir = atoi(szValue) == 1 ? 1 : -1;
		else if (szKey == "lip") m_flLip = atof(szValue);
		else if (szKey == "wait") m_flWait = atof(szValue);
		else if (szKey == "speed") pev.speed = atof(szValue);
		else if (szKey == "sounds") sounds = atoi(szValue);
		else if (szKey == "sync") sync = szValue;
		else if (szKey == "always_use") always_use = atoi(szValue) != 0;
		else if (szKey == "touch_opens") touch_opens = atoi(szValue) != 0;
		else if (szKey == "crusher") isCrusher = atoi(szValue) != 0;
		else if (szKey == "lock") lock = atoi(szValue);
		else if (szKey == "use_dir") useDir = parseVector(szValue);
		else if (szKey == "shootable") shootable = atoi(szValue) != 0;
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Precache()
	{
		PrecacheSound("doom/dsbdcls.wav"); // close quick
		PrecacheSound("doom/dsdorcls.wav"); // close
		PrecacheSound("doom/dsbdopn.wav"); // open quick
		PrecacheSound("doom/dsdoropn.wav"); // open
		PrecacheSound("doom/dsswtchn.wav"); // switch sound
		PrecacheSound("doom/dsswtchx.wav"); // switch sound2
		PrecacheSound("doom/dspstop.wav"); // floor stop
		PrecacheSound("doom/dspstart.wav"); // floor start
		PrecacheSound("doom/dsstnmov.wav"); // floor move
	}
	
	void Spawn()
	{
		Precache();
		
		pev.movetype = MOVETYPE_PUSH;
		pev.solid = SOLID_BSP;
		pev.angles = g_vecZero;
		pev.takedamage = shootable ? DAMAGE_YES : DAMAGE_NO;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, pev.model);
		
		if (pev.speed == 0)
			pev.speed = 100;
			
		if (isCrusher)
			m_flWait = 0.001f;
			
		m_vecPosition1	= pev.origin;
		// Subtract 2 from size because the engine expands bboxes by 1 in all directions making the size too big
		m_vecPosition2	= m_vecPosition1 + Vector(0,0,(dir * (pev.size.z-2)) - dir*m_flLip);
			
		isButton = string(pev.target).Length() > 0;
		if (isButton)
		{
			if (sounds == 0)
				switchSnd = "doom/dsswtchn.wav";
			else
				switchSnd = "doom/dsswtchx.wav";
		}
		else
		{
			if (sounds == 0)
			{
				openSnd = "doom/dsdoropn.wav";
				closeSnd = "doom/dsdorcls.wav";
			}
			else if (sounds == 1)
			{
				openSnd = "doom/dsbdopn.wav";
				closeSnd = "doom/dsbdcls.wav";
			}
			else if (sounds == 2)
			{
				openSnd = "doom/dspstart.wav";
				closeSnd = "doom/dspstop.wav";
			}
			else if (sounds == 3)
			{
				openSnd = "doom/dsstnmov.wav";
				closeSnd = "doom/dspstop.wav";
			}
			else if (sounds == 4)
			{
				openSnd = "doom/dspstop.wav";
				closeSnd = "doom/dspstop.wav";
			}
		}
		
		switchSnd = fixPath(switchSnd);
		openSnd = fixPath(openSnd);
		closeSnd = fixPath(closeSnd);

		if ( pev.spawnflags & SF_DOOR_START_OPEN != 0 )
		{	// swap pos1 and pos2, put door at pos2
			pev.origin = m_vecPosition2;
			m_vecPosition2 = m_vecPosition1;
			m_vecPosition1 = pev.origin;
		}

		m_toggle_state = TS_AT_BOTTOM;
		
		m_bIsReopening = false;
		
		// if the door is flagged for USE button activation only, use NULL touch function
		if ( pev.spawnflags & SF_DOOR_USE_ONLY == 0 )
			SetTouch( TouchFunction(Touch) );
	}
	
	void Touch(CBaseEntity@ other)
	{
		if (isButton)
			return;
		if (m_toggle_state != TS_AT_BOTTOM and m_toggle_state != TS_AT_TOP)
			return;
			
		// Ignore touches by anything but players
		if (!other.IsPlayer())
			return;
		
		// If door is somebody's target, then touching does nothing.
		// You have to activate the owner (e.g. button).
		if (string(pev.targetname).Length() > 0)
			return;
			
		if (!touch_opens)
			return; // never touch open
			
		DoorActivate();
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if (!shootable)
			return 0;
		if (bitsDamageType & DMG_BLAST == 0)
		{
			CBaseEntity@ activator = g_EntityFuncs.Instance( pevAttacker );
			//Useit(activator, activator, USE_TOGGLE, 0, true);
			
			// for some reason button won't activate if triggered now so have to wait a frame
			g_Scheduler.SetTimeout("delay_use", 0.0f, EHandle(self), EHandle(activator), int(USE_TOGGLE), 0, true);
		}
		return 0;
	}
	
	void ButtonReset()
	{
		g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, switchSnd, 1.0f, attn, 0, 100);
		pev.frame = 0;
	}
	
	void Useit(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value, bool wasShot=false)
	{
		if (shootable and !wasShot)
			return;

		int haveKey = g_keys;
		if (!g_strict_keys)
		{
			// allow skull keys to activate normal-key doors and vice versa
			lock = (lock | (lock >> 3)) & (KEY_BLUE | KEY_YELLOW | KEY_RED);
			haveKey = g_keys | (g_keys >> 3);
		}
		if (lock != 0 and lock & haveKey != lock)
		{
			if (pActivator.IsPlayer())
			{
				string keyname = "blue";
				if (lock & (KEY_YELLOW | SKULL_YELLOW) != 0)
					keyname = "yellow";
				if (lock & (KEY_RED | SKULL_RED) != 0)
					keyname = "red";
				g_PlayerFuncs.PrintKeyBindingString(cast<CBasePlayer@>(pActivator), "You need a " + keyname + " key to activate this\n");
			}
			return;
		}
		
		if (pCaller.IsPlayer())
		{
			if (useDir != g_vecZero)
			{
				Vector doorOri = pev.absmin + (pev.absmax - pev.absmin)*0.5f;
				Vector delta = (doorOri - pCaller.pev.origin).Normalize();
				//println("USE DIR: " + useDir.ToString() + " == " + delta.ToString());
				if (DotProduct(delta, useDir) > 0)
					return;
			}
			//println("Z DELTA: " + (pev.absmax.z-pCaller.pev.absmin.z));
			if (pCaller.pev.absmin.z + 4 > pev.absmax.z)
			{
				return; // don't allow using floors from above (MAP05 secret)
			}
		}
		
		// if not ready to be used, ignore "use" command.
		if (isButton)
		{
			if (pev.frame == 0 and m_toggle_state == TS_AT_BOTTOM)
			{
				pev.frame = 1;
				g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, switchSnd, 1.0f, attn, 0, 100);
				g_EntityFuncs.FireTargets(pev.target, pActivator, self, USE_TOGGLE);
				if (m_flWait > 0)
					g_Scheduler.SetTimeout("reset_but", m_flWait, EHandle(self));
			}
		}
		else if ((m_toggle_state == TS_AT_BOTTOM and useType != USE_OFF) or 
				(pev.spawnflags & SF_DOOR_NO_AUTO_RETURN != 0) and m_toggle_state == TS_AT_TOP or useType == USE_OFF)
		{
			if ((string(pev.targetname).Length() == 0 or always_use) or !pCaller.IsPlayer())
			{
				if (string(pev.targetname).Length() != 0 and always_use)
				{
					// door synced with others
					CBaseEntity@ ent = null;
					do {
						@ent = g_EntityFuncs.FindEntityByTargetname(ent, pev.targetname);
						if (ent !is null)
						{
							func_doom_door@ door = cast<func_doom_door@>(CastToScriptClass(ent));
							door.DoorActivate(useType);
						}
					} while (ent !is null);
				}
				else
					DoorActivate(useType);
			}
		}
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		Useit(pActivator, pCaller, useType, value, false);
	}
	
	int DoorActivate(int useType=USE_TOGGLE)
	{
		if (m_flWait == -1)
		{
			if (m_toggle_state == TS_AT_TOP and (useType == USE_TOGGLE or useType == USE_ON))
				return 1;
		}
			
		if (isCrusher and useType == USE_OFF)
		{
			if (pev.nextthink != -1 and (sounds == 2 or sounds == 3 or sounds == 4) and closeSnd.Length() > 0)
				g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, closeSnd, 1.0f, attn, 0, 100);
			pev.nextthink = -1;
			return 1;
		}
			
		if ((pev.spawnflags & SF_DOOR_NO_AUTO_RETURN != 0) and m_toggle_state == TS_AT_TOP or useType == USE_OFF)
		{
			if (m_toggle_state != TS_AT_BOTTOM and m_toggle_state != TS_GOING_DOWN)
				DoorGoDown();
		}
		else
			DoorGoUp();
			
		return 1;
	}
	
	void DoorGoUp()
	{
		if (!isButton and openSnd.Length() > 0)
			g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, openSnd, 1.0f, attn, sounds == 3 ? int(SND_FORCE_LOOP) : 0, 100);
		m_toggle_state = TS_GOING_UP;
		LinearMove(m_vecPosition2, pev.speed);
		
		for (uint i = 0; i < sync_buttons.length(); i++)
		{
			if (!sync_buttons[i].IsValid())
				continue;
			
			func_doom_door@ but = cast<func_doom_door@>(CastToScriptClass(sync_buttons[i].GetEntity()));
			but.DoorGoUp();
		}
	}
	
	void DoorHitTop()
	{
		if ((sounds == 2 or sounds == 3 or sounds == 4) and closeSnd.Length() > 0)
			g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, closeSnd, 1.0f, attn, 0, 100);
		m_toggle_state = TS_AT_TOP;
		m_bIsReopening = false;
		
		// toggle-doors don't come down automatically, they wait for refire.
		if (!isButton and pev.spawnflags & SF_DOOR_NO_AUTO_RETURN == 0)
		{
			// In flWait seconds, DoorGoDown will fire, unless wait is -1, then door stays open
			pev.nextthink = pev.ltime + m_flWait;				
			SetThink( ThinkFunction(DoorGoDown) );

			if ( m_flWait == -1 )
				pev.nextthink = -1;
		}
	}
	
	void DoorGoDown()
	{
		if (!isButton)
		{
			if (sounds == 2 or sounds == 3)
			{
				if (openSnd.Length() > 0)
					g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, openSnd, 1.0f, attn, sounds == 3 ? int(SND_FORCE_LOOP) : 0, 100);
			}
			else if (closeSnd.Length() > 0)
				g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, closeSnd, 1.0f, attn, 0, 100);
		}
		m_toggle_state = TS_GOING_DOWN;
		LinearMove( m_vecPosition1, pev.speed);
		
		for (uint i = 0; i < sync_buttons.length(); i++)
		{
			if (!sync_buttons[i].IsValid())
				continue;
			
			func_doom_door@ but = cast<func_doom_door@>(CastToScriptClass(sync_buttons[i].GetEntity()));
			but.DoorGoDown();
		}
	}

	void DoorHitBottom()
	{
		if ((sounds == 2 or sounds == 3) and closeSnd.Length() > 0)
			g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, closeSnd, 1.0f, attn, 0, 100);
		m_toggle_state = TS_AT_BOTTOM;
		
		if (isCrusher)
			DoorActivate();
	}
	
	void Blocked( CBaseEntity@ pOther )
	{
		if (isButton and parent.IsValid())
		{
			parent.GetEntity().Blocked(pOther);
			return;
		}
		
		// Hurt the blocker a little.
		if ( pev.dmg != 0 and lastCrush + 0.0572f < g_Engine.time)
		{
			lastCrush = g_Engine.time;
			doomTakeDamage( pOther, pev, pev, pev.dmg, DMG_CRUSH );
			te_bloodsprite(pOther.pev.origin + pOther.pev.view_ofs, fixPath("sprites/doom/blud.spr"), "sprites/blood.spr", 70, 5);
		}

		// if a door has a negative wait, it would never come back if blocked,
		// so let it just squash the object to death real fast

		if (m_flWait >= 0 and !isCrusher)
		{
			if (m_toggle_state == TS_GOING_DOWN)
				DoorGoUp();
			else
				DoorGoDown();
		}
	}

	void LinearMove(Vector vecDest, float flSpeed)
	{
		m_vecFinalDest = vecDest;
		
		// Already there?
		if (vecDest == pev.origin)
		{
			LinearMoveDone();
			return;
		}
			
		// set destdelta to the vector needed to move
		Vector vecDestDelta = vecDest - pev.origin;
		
		// divide vector length by speed to get time to reach dest
		float flTravelTime = vecDestDelta.Length() / flSpeed;

		// set nextthink to trigger a call to LinearMoveDone when dest is reached
		pev.nextthink = pev.ltime + flTravelTime;
		SetThink( ThinkFunction(LinearMoveDone) );

		// scale the destdelta vector by the time spent traveling to get velocity
		pev.velocity = vecDestDelta / flTravelTime;
	}
	
	void LinearMoveDone()
	{
		Vector delta = m_vecFinalDest - pev.origin;
		float error = delta.Length();
		if ( error > 0.03125 )
		{
			LinearMove( m_vecFinalDest, 100 );
			return;
		}

		pev.origin = m_vecFinalDest;
		pev.velocity = g_vecZero;
		pev.nextthink = -1;
		
		if (m_toggle_state == TS_GOING_UP)
			DoorHitTop();
		else
			DoorHitBottom();
	}
	
	void SetToggleState( int state )
	{
		if ( state == TS_AT_TOP )
			g_EntityFuncs.SetOrigin( self, m_vecPosition2 );
		else
			g_EntityFuncs.SetOrigin( self, m_vecPosition1 );
	}
}