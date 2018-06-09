
class NodeTarget
{
	int id = -1;
	array<EHandle> checkEntities;
	float lastCheck = 0;
	bool isClear = true;
}

class NodeReach
{
	bool hasPath = false;
	array<EHandle> checkEnts; // these parts of the path need to be traced
	float lastCheck = 0;
	bool isClear = false;
	
	bool isReachable()
	{
		if (!hasPath)
			return false;
			
		//println("CHECK " + checkEnts.length() + " DOORS");
		for (uint i = 0; i < checkEnts.length(); i++)
		{
			func_doom_door@ door = cast<func_doom_door@>(CastToScriptClass(checkEnts[i].GetEntity()));
			if (door !is null and door.m_toggle_state == TS_AT_BOTTOM)
			{
				//println("" + door.pev.targetname + " is blocking sound");
				return false;
			}
		}
		return true;
	}
}

class SoundNode
{
	int id;
	Vector pos;
	bool hitsEntity = false;
	array<NodeTarget> targets;
	dictionary reachability; // cached results of A* algorithm.
}

array<SoundNode> g_sound_nodes;

class info_node_sound : ScriptBaseEntity
{	
	void Spawn()
	{
		SoundNode node;
		node.pos = pev.origin;
		node.id = g_sound_nodes.length();
		g_sound_nodes.insertLast(node);
		g_EntityFuncs.Remove(self);
	}
}

SoundNode@ getSoundNode(Vector pos)
{
	TraceResult tr;
	for (uint i = 0; i < g_sound_nodes.length(); i++)
	{
		g_Utility.TraceLine( g_sound_nodes[i].pos, pos, ignore_monsters, null, tr );
		if (tr.flFraction >= 1.0f)
			return g_sound_nodes[i];
	}
	return null;
}

SoundNode@ getNodeByID(int id)
{
	if (id < 0 or id > int(g_sound_nodes.length()))
		return null;
	return g_sound_nodes[id];
}


bool canHearSound(SoundNode@ start, SoundNode@ end, Vector b=Vector(0,0,0), CBaseEntity@ listener=null)
{
	if (start is null or end is null)
		return false;
	
	if (start.reachability.exists(end.id))
	{
		// check reachability cache
		//println("CHECK REACH " + reach.hasPath + " " + start.id + " " + end.id);
		bool reachable = cast<NodeReach@>( start.reachability[end.id] ).isReachable();
		if (false and reachable)
		{
			array<SoundNode@> route = AStarRouteWaypoint(start, end, true);
			if (route.length() > 0 and listener !is null)
			{
				te_beampoints(route[0].pos, b, "sprites/laserbeam.spr", 0, 100, 40, 5, 0, PURPLE);
				te_beampoints(route[route.length()-1].pos, listener.pev.origin, "sprites/laserbeam.spr", 0, 100, 40, 5, 0, PURPLE);
				for (uint i = 0; i < route.length()-1; i++)
				{
					te_beampoints(route[i].pos, route[i+1].pos, "sprites/laserbeam.spr", 0, 100, 40, 5, 0, PURPLE);
				}
			}
		}
		return reachable;
	}
	
	array<SoundNode@> route = AStarRouteWaypoint(start, end, true);
	
	NodeReach reach;
	reach.hasPath = route.length() > 0;
	if (reach.hasPath)
	{
		route.reverse();
		for (uint i = 0; i < route.length()-1; i++)
		{
			SoundNode@ node = route[i];
			for (uint k = 0; k < node.targets.length(); k++)
			{
				if (node.targets[k].id == route[i+1].id)
				{
					for (uint c = 0; c < node.targets[k].checkEntities.length(); c++)
						reach.checkEnts.insertLast(node.targets[k].checkEntities[c]);
					//println("HAS A PATH " + start.id + " " + end.id + " with " + reach.checkEnts.length() + " blockers" );
				}
			}
		}
	}
	//else
	//	println("NO PATH " + start.id + " " + end.id);
	start.reachability[end.id] = reach;
	
	return route.length() > 0;
}

// cost to move to between these waypoints
float path_cost(SoundNode@ a, SoundNode@ b)
{
	Vector delta = a.pos - b.pos;
	if (abs(delta.Normalize().z) < 0.4)
		delta.z = 0; // vertical movement doesn't decrease speed unless its a ladder or something
	return delta.Length();
}

array<SoundNode@> reconstruct_path(dictionary&in cameFrom, int current)
{
    array<SoundNode@> path;
	path.insertLast(getNodeByID(current));
	
    while (cameFrom.exists(current))
	{
		cameFrom.get(current, current);
        path.insertLast(getNodeByID(current));
	}
	
    return path;
}

bool isPathClear(SoundNode@ currentNode, NodeTarget@ target)
{
	//println("TRACE " + currentNode.id + " " + target.id);
	SoundNode@ targetNode = g_sound_nodes[target.id];
	//te_beampoints(currentNode.pos, targetNode.pos, "sprites/laserbeam.spr", 0, 100, 40, 5, 0, PURPLE);
	if (target.lastCheck + 1.0f > g_Engine.time)
	{	
		// data is fresh
		if (!target.isClear)
			return false;
	}
	else
	{
		// check if a door is in the way
		TraceResult tr;
		//SoundNode@ targetNode = g_sound_nodes[target.id];
		g_Utility.TraceLine( currentNode.pos, targetNode.pos, ignore_monsters, null, tr );
		target.isClear = tr.flFraction >= 1.0f;
		target.lastCheck = g_Engine.time;
		
		for (uint k = 0; k < targetNode.targets.length(); k++)
		{
			if (targetNode.targets[k].id == currentNode.id)
			{
				targetNode.targets[k].isClear = target.isClear;
				targetNode.targets[k].lastCheck = target.lastCheck;
				break;
			}
		}
		
		//println("DOIN A TRACE");
		if (!target.isClear)
			return false;
	}
	return true;
}

// finds the shortest path between two waypoints
array<SoundNode@> AStarRouteWaypoint(SoundNode@ start, SoundNode@ goal, bool ignoreSolids)
{	
	dictionary closedSet;
	dictionary openSet;
	dictionary gScore;
	dictionary fScore;
	dictionary cameFrom;
	
	if (start is null or goal is null)
		return array<SoundNode@>();
	
	//println("ROUTE FROM " + start.id + " TO " + goal.id);
	 
	if (start is null)
		println("FAILED TO START");
	if (goal is null)
		println("FAILED TO GOAL");
		
	if (start.id == goal.id)
	{
		array<SoundNode@> route;
		route.insertLast(goal);
		return route;
	}
	
	openSet[start.id] = true;
	gScore[start.id] = 0;
	fScore[start.id] = path_cost(start, goal);
	
	while (!openSet.isEmpty())
	{
		// get node in openset with lowest cost
		int current = -1;
		float bestScore = 9e99;
		array<string>@ openKeys = openSet.getKeys();
		for (uint i = 0; i < openKeys.length(); i++)
		{
			float score;
			fScore.get(openKeys[i], score);
			//println("CHECK SCORE FOR " + openKeys[i] + " " + score);
			if (score < bestScore)
			{
				bestScore = score;
				current = atoi( openKeys[i] );
			}
		}
		
		//println("Current is " + current);
		
		if (current == goal.id)
		{
			//println("MAde it to the goal");			
			return reconstruct_path(cameFrom, current);
		}
		
		openSet.delete(current);
		closedSet[current] = true;
		
		SoundNode@ currentNode = g_sound_nodes[current];
		
		for (uint i = 0; i < currentNode.targets.length(); i++)
		{
			NodeTarget@ target = currentNode.targets[i];
			if (!ignoreSolids)
			{
				//if (target.checkEntity)
				//	continue;
				if (!isPathClear(currentNode, target))
					continue;
			}
			
			int neighbor = target.id;
			
			if (closedSet.exists(neighbor))
				continue;
				
			// discover a new node
			openSet[neighbor] = true;
			//println("DISCOVERED " + neighbor);
				
			// The distance from start to a neighbor
			SoundNode@ neighborNode = g_sound_nodes[neighbor];
			
			float tentative_gScore = 0;
			gScore.get(current, tentative_gScore);
			tentative_gScore += path_cost(currentNode, neighborNode);
			
			float neighbor_gScore = 9e99;
			if (gScore.exists(neighbor_gScore))
				gScore.get(neighbor, neighbor_gScore);
			
			if (tentative_gScore >= neighbor_gScore)
				continue; // not a better path
				
			//println("Route to neighbor " + neighbor);
				
			// This path is the best until now. Record it!
            cameFrom[neighbor] = current;
            gScore[neighbor] = tentative_gScore;
            fScore[neighbor] = tentative_gScore + path_cost(neighborNode, goal);
		}
	}
	return array<SoundNode@>();
}

void createSoundGraph()
{	
	for (uint i = 0; i < g_sound_nodes.length(); i++)
	{
		array<EHandle> checkEntities;
		SoundNode@ n1 = g_sound_nodes[i];
		for (uint k = 0; k < g_sound_nodes.length(); k++)
		{
			SoundNode@ n2 = g_sound_nodes[k];
			
			TraceResult tr;
			g_Utility.TraceLine( n1.pos, n2.pos, ignore_monsters, null, tr );
			CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
			if (tr.flFraction >= 1.0f)
			{
				NodeTarget target;
				target.id = k;
				target.checkEntities = checkEntities;
				n1.targets.insertLast(target);
			}
			else if (phit.pev.classname != "worldspawn" and phit.pev.solid == SOLID_BSP)
			{
				phit.pev.solid = SOLID_NOT;
				checkEntities.insertLast(EHandle(phit));
				k--;
				continue;
			}
			
			for (uint c = 0; c < checkEntities.length(); c++)
				checkEntities[c].GetEntity().pev.solid = SOLID_BSP;
			checkEntities.resize(0);
		}
	}
	
	// calculate reachability
	//println("Calc reachability");
	for (uint i = 0; i < g_sound_nodes.length(); i++)
	{
		SoundNode@ n1 = g_sound_nodes[i];
		for (uint k = 0; k < g_sound_nodes.length(); k++)
		{
			if (k != i)
				canHearSound(n1, g_sound_nodes[k]);
		}
	}
}