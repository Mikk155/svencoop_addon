
namespace UtilEnts {

	RGBA parseRgba(string s) {
		array<string> values = s.Split(" ");
		RGBA c(0,0,0,0);
		if (values.length() > 0) c.r = atoi( values[0] );
		if (values.length() > 1) c.g = atoi( values[1] );
		if (values.length() > 2) c.b = atoi( values[2] );
		if (values.length() > 3) c.a = atoi( values[3] );
		return c;
	}
	
	Vector parseVector(string s) {
		array<string> values = s.Split(" ");
		Vector v(0,0,0);
		if (values.length() > 0) v.x = atof( values[0] );
		if (values.length() > 1) v.y = atof( values[1] );
		if (values.length() > 2) v.z = atof( values[2] );
		return v;
	}
	
	array<CBaseEntity@> getTargetsByName(CBaseEntity@ pActivator, CBaseEntity@ pCaller, string target) {
		array<CBaseEntity@> targets;
	
		if (target == "!activator") {
			targets.insertLast(pActivator);
		} else if (target == "!caller") {
			targets.insertLast(pCaller);
		} else {
			CBaseEntity@ ent = null;
			do {
				@ent = g_EntityFuncs.FindEntityByTargetname(ent, target);
				if (ent !is null)
				{
					targets.insertLast(ent);
				}
			} while (ent !is null);
		}
		
		return targets;
	}
}