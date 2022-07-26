namespace CXenProp
{
    enum xen_custom_prop_flag
    {
        SF_HAIR_SYNC = 1 << 0
    }

    class xen_custom_prop : ScriptBaseAnimating
    {
			Vector	MinHullSize			= Vector(-80,-80,0);
			Vector 	MaxHullSize			= Vector(80,80,32);
			
			bool KeyValue( const string& in szKey, const string& in szValue )
			{
				if (szKey == "minhullsize")
				{
					g_Utility.StringToVector(MinHullSize,szValue);
					return true;
				}
				else if(szKey == "maxhullsize")
				{
					g_Utility.StringToVector(MaxHullSize,szValue);
					return true;
				}
				else
				{
					return BaseClass.KeyValue( szKey, szValue );
				}
			}
			
        void Spawn()
        {
            self.Precache();
            self.pev.solid		= SOLID_NOT;
            self.pev.movetype	= MOVETYPE_NONE;
		//	self.pev.skin		= self.pev.skin;
		//	self.pev.scale		= self.pev.scale;
			
            if(string(self.pev.model).IsEmpty()) 
                g_EntityFuncs.SetModel(self, "models/hair.mdl");
            else 
                g_EntityFuncs.SetModel(self, self.pev.model);

            g_EntityFuncs.SetOrigin(self, self.pev.origin);

            g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);

            if( !self.pev.SpawnFlagBitSet( SF_HAIR_SYNC ) )
            {
                self.pev.frame = Math.RandomFloat(0,255);
                self.pev.framerate = Math.RandomFloat(0.7,1.4);
            }
            self.ResetSequenceInfo();

            self.pev.nextthink = g_Engine.time + Math.RandomFloat(0.1,0.4);
        }

        void Precache()
        {
            if( string(self.pev.model).IsEmpty() )
            {
                g_Game.PrecacheModel("models/hair.mdl");
            }
            else
            {
                g_EntityFuncs.SetModel(self, self.pev.model);
            }

            BaseClass.Precache();
        }

        void Think()
        {
            self.pev.nextthink = g_Engine.time + 0.5;

            self.StudioFrameAdvance();
        }
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "CXenProp::xen_custom_prop", "xen_custom_prop" );
    }
}