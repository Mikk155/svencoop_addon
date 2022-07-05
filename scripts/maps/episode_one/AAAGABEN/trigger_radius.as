#include "utils"

namespace TriggerRadius {

	class trigger_radius : ScriptBaseEntity
	{
		string originTarget;
		float radius;
		int triggerType;
		
		bool KeyValue( const string& in szKey, const string& in szValue )
		{	
			if (szKey == "origintarget") originTarget = szValue;
			else if (szKey == "triggerstate") triggerType = atoi(szValue);
			else if (szKey == "radius") radius = atof(szValue);
			else return BaseClass.KeyValue( szKey, szValue );
			
			return true;
		}
		
		void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
		{
			array<CBaseEntity@> originTargets;
			
			if (originTarget.Length() > 0) {
				originTargets = UtilEnts::getTargetsByName(pActivator, pCaller, originTarget);
			} else {
				originTargets.insertLast(self);
			}
			
			for (uint i = 0; i < originTargets.size(); i++) {
				Vector ori = originTargets[i].pev.origin;

				CBaseEntity@ ent = null;
				do {
					@ent = g_EntityFuncs.FindEntityInSphere(ent, ori, radius, self.pev.target, "targetname");
					
					if (ent !is null) {
						// prevent casting errors crashing the script
						USE_TYPE actual_use_type = USE_TOGGLE;
						switch(triggerType) {
							case 0: actual_use_type = USE_OFF; break;
							case 1: actual_use_type = USE_ON; break;
							case 3: actual_use_type = USE_TOGGLE; break;
							case 4: actual_use_type = USE_KILL; break;
							default: break;
						}

						if (actual_use_type == USE_KILL)
							g_EntityFuncs.Remove(ent);
						else
							ent.Use(pActivator, self, actual_use_type);
					}
				} while (ent !is null);
			}
		}
	};

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "TriggerRadius::trigger_radius", "trigger_radius" );
	}
}