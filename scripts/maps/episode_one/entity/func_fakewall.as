class func_fakewall : ScriptBaseEntity
{
    void Spawn()
    {
		CreateFakeWall();
    }

	void CreateFakeWall()
	{
		dictionary decalvalues;
		decalvalues ["origin"]				= "" + self.GetOrigin().ToString();
		decalvalues ["angles"]				= "" + self.pev.angles.ToString();
		decalvalues ["spawnflags"]			= "" + self.pev.spawnflags;
		decalvalues ["model"]				= "" + self.pev.model;
		decalvalues ["targetname"]			= "" + self.pev.targetname;
		decalvalues ["rendermode"]			= "4";
		decalvalues ["renderamt"]			= "0";

		g_EntityFuncs.CreateEntity( "func_wall_toggle", decalvalues, true );
	}
}

void RegisterFakeWall()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_fakewall", "func_fakewall" );
}