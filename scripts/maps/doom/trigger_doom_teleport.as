const int FL_TP_IGNORE_PLAYERS = 2;
const int FL_TP_ON_EXIT = 32;

class trigger_doom_teleport : ScriptBaseEntity
{
	bool ignore_players = false;
	bool tele_on_exit = false;
	dictionary lastTouches;
	float touchDelay = 0.5f;
	Vector teleDir = Vector(0,0,0); // ent must be moving in this general direction or else will be ignored
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{		
		if (szKey == "tele_dir") teleDir = parseVector(szValue).Normalize();
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Spawn()
	{		
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_TRIGGER;
		pev.effects = EF_NODRAW;
		
		ignore_players = pev.spawnflags & FL_TP_IGNORE_PLAYERS != 0;
		tele_on_exit = pev.spawnflags & FL_TP_ON_EXIT != 0;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, pev.model);
		
		SetTouch( TouchFunction(Touch) );
	}
	
	void Teleport(CBaseEntity@ other)
	{
		CBaseEntity@ target = g_EntityFuncs.FindEntityByTargetname(null, pev.target);
		if (target !is null)
		{
			Vector offset = other.IsPlayer() ? Vector(0,0,36) : Vector(0,0,0);
			Vector targetPos = target.pev.origin + offset;
			Vector testPos = target.pev.origin + Vector(0,0,36);
			
			// telefrag
			TraceResult tr;
			g_Utility.TraceHull( testPos, testPos + Vector(0,0,1.0f), dont_ignore_monsters, human_hull, self.edict(), tr );

			CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
			if (phit !is null and (phit.IsMonster() or phit.IsPlayer()))
				doomTakeDamage(phit, other.pev, other.pev, phit.pev.health + 100, DMG_CRUSH);
				
			if (other.IsMonster())
			{
				monster_doom@ mon = cast<monster_doom@>(CastToScriptClass(other));
				if (mon !is null)
					mon.DelayAttack(); // get out of the way for other monsters
			}
			
			te_explosion(other.pev.origin - offset, fixPath("sprites/doom/TFOG.spr"), 10, 5, 15);
			g_EntityFuncs.SetOrigin(other, target.pev.origin + offset);
			
			CBaseEntity@ ent = null;
			do {
				@ent = g_EntityFuncs.FindEntityByClassname(ent, "trigger_doom_teleport");
				if (ent !is null)
				{
					if (ent.Intersects(other))
					{
						// if ent will land inside another teleport trigger, then prevent it 
						// from teleporting without re-entering the brush
						trigger_doom_teleport@ tele = cast<trigger_doom_teleport@>(CastToScriptClass(ent));
						tele.lastTouches[other.entindex()] = g_Engine.time;
					}
				}
			} while (ent !is null);
			
			g_EngineFuncs.MakeVectors(target.pev.angles);
			te_explosion(other.pev.origin - offset + g_Engine.v_forward*32, fixPath("sprites/doom/TFOG.spr"), 10, 5, 15);
			
			g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, fixPath("doom/DSTELEPT.wav"), 1.0f, 1.0f, 0, 100);
			g_SoundSystem.PlaySound(target.edict(), CHAN_STATIC, fixPath("doom/DSTELEPT.wav"), 1.0f, 1.0f, 0, 100);
			
			other.pev.velocity = Vector(0,0,0);
			other.pev.angles = target.pev.angles;
			other.pev.v_angle = target.pev.angles;
			other.pev.fixangle = FAM_FORCEVIEWANGLES;
		}
		else
			println("Bad teleport destination: " + pev.target);
	}
	
	void Touch(CBaseEntity@ other)
	{
		if (!other.IsMonster() and !other.IsPlayer())
			return;
			
		if (ignore_players and other.IsPlayer())
			return;
			
		bool newToucher = true;
		float lastTouch = -1;
		if (lastTouches.exists(other.entindex()))
			lastTouches.get(other.entindex(), lastTouch);
		lastTouches[other.entindex()] = g_Engine.time;
		
		float diff = g_Engine.time - lastTouch;
		bool hasDir = teleDir != g_vecZero;
		if (diff > touchDelay and !tele_on_exit or hasDir)
		{
			bool validDir = false;
			if (hasDir)
			{
				Vector moveDir;
				if (other.IsPlayer())
					moveDir = other.pev.velocity.Normalize();
				else
					moveDir = (other.pev.origin - other.pev.oldorigin).Normalize();
				validDir = DotProduct(moveDir, teleDir) > 0.1;
				println("DOT: " + DotProduct(moveDir, teleDir) + " " + validDir + " " + other.IsMonster());
			}
			if (!hasDir or validDir)
			{
				// just started touching (fire on enter)
				Teleport(other);
			}	
		}
	}
}