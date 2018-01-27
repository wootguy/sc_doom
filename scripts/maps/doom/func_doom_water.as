
class func_doom_water : ScriptBaseEntity
{
	float damage = 0;
	dictionary lastTouches;
	dictionary lastPains;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{		
		if (szKey == "damage") damage = atof(szValue);
		else return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Spawn()
	{		
		pev.movetype = MOVETYPE_PUSH;
		pev.solid = SOLID_BSP;
		
		g_EntityFuncs.SetOrigin(self, pev.origin);
		g_EntityFuncs.SetModel(self, pev.model);
		
		SetTouch( TouchFunction(Touch) );
		SetThink( ThinkFunction(Think) );
		pev.nextthink = g_Engine.time;
	}
	
	void Think()
	{
		pev.frame += 1;
		pev.nextthink = g_Engine.time + 0.5f;
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