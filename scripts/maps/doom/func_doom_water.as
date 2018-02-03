
void weird_think_bug_workaround(EHandle h_ent)
{
	if (!h_ent.IsValid())
		return;
	func_doom_water@ ent = cast<func_doom_water@>(CastToScriptClass(h_ent.GetEntity()));
	
	ent.WaterThink();
}

class func_doom_water : ScriptBaseEntity
{
	float damage = 0;
	int maxFrame = 2;
	dictionary lastTouches;
	dictionary lastPains;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{		
		if (szKey == "damage") damage = atof(szValue);
		if (szKey == "maxFrame") maxFrame = atoi(szValue);
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Spawn()
	{		
		pev.movetype = MOVETYPE_PUSH;
		pev.solid = SOLID_BSP;
		pev.effects = EF_FRAMEANIMTEXTURES;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, pev.model);
		
		SetTouch( TouchFunction(Touch) );
		SetThink( ThinkFunction(WaterThink) );
		WaterThink();
	}
	
	void WaterThink()
	{
		pev.frame += 1;
		if (pev.frame > maxFrame)
			pev.frame = 0;
		g_Scheduler.SetTimeout("weird_think_bug_workaround", 0.25f, EHandle(self));
		
	}
	
	void Touch(CBaseEntity@ other)
	{		
		if (!other.IsPlayer())
			return;
			
		int idx = other.entindex();
		PlayerState@ state = getPlayerState(cast<CBasePlayer@>(other));
		
		float lastTouch = 0;
		float lastPain = 0;
		lastTouches.get(idx, lastTouch);
		lastPains.get(idx, lastPain);
		
		float diff = g_Engine.time - lastTouch;
		if (diff > 0.5f)
		{
			println("JUST STARTED TOUCHING");
			lastPain = g_Engine.time - 0.5f; // player just started touching, don't hurt yet
		}
		else
		{
			diff = g_Engine.time - lastPain;
			if (state.suitTimeLeft() <= 0 and diff > 0.8f)
			{
				other.TakeDamage( pev, pev, damage, DMG_ACID);
				lastPain = g_Engine.time;
			}
		}
		
		lastPains[idx] = lastPain;
		lastTouches[idx] = g_Engine.time;
	}
}