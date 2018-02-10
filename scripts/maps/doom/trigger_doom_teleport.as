
class trigger_doom_teleport : ScriptBaseEntity
{
	dictionary lastTouches;
	
	void Spawn()
	{		
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_TRIGGER;
		pev.effects = EF_NODRAW;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, pev.model);
		
		SetTouch( TouchFunction(Touch) );
	}
	
	void Touch(CBaseEntity@ other)
	{
		if (!other.IsMonster() and !other.IsPlayer())
			return;
		int idx = other.entindex();
		float lastTouch = 0;
		if (lastTouches.exists(idx))
			lastTouches.get(idx, lastTouch);
		
		float diff = g_Engine.time - lastTouch;
		if (diff > 0.5f)
		{
			// just started touching (fire on enter)
			
			CBaseEntity@ target = g_EntityFuncs.FindEntityByTargetname(null, pev.target);
			if (target !is null)
			{
				Vector offset = other.IsPlayer() ? Vector(0,0,36) : Vector(0,0,0);
				te_explosion(other.pev.origin - offset, "sprites/doom/TFOG.spr", 10, 5, 15);
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
							tele.lastTouches[idx] = g_Engine.time;
						}
					}
				} while (ent !is null);
				
				g_EngineFuncs.MakeVectors(target.pev.angles);
				te_explosion(other.pev.origin - offset + g_Engine.v_forward*32, "sprites/doom/TFOG.spr", 10, 5, 15);
				
				g_SoundSystem.PlaySound(self.edict(), CHAN_STATIC, "doom/DSTELEPT.wav", 1.0f, 1.0f, 0, 100);
				g_SoundSystem.PlaySound(target.edict(), CHAN_STATIC, "doom/DSTELEPT.wav", 1.0f, 1.0f, 0, 100);
				
				other.pev.velocity = Vector(0,0,0);
				other.pev.angles = target.pev.angles;
				other.pev.v_angle = target.pev.angles;
				other.pev.fixangle = FAM_FORCEVIEWANGLES;
			}
			else
				println("Bad teleport destination: " + pev.target);
		}
		
		lastTouches[idx] = g_Engine.time;
	}
}