void RegisterTest()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "", "" );
}

class  : ScriptBaseEntity 
{
	void Spawn() 
	{
        self.Precache();

        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
	}
}