void RegisterBloodPuddle()
{
	g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );
	g_Game.PrecacheGeneric( "models/mikk/misc/bloodpuddle.mdl" );
	
	SetThink( ThinkFunction( this.TriggerThink ) );
	self.pev.nextthink = g_Engine.time + 0.1f;
}

void TriggerThink()
{

	CBaseEntity@ pSource = null;
	while((@pSource = g_EntityFuncs.FindEntityByClassname( pSource, "monster_*" ) !is null)
	{
		if( !pSource.IsAlive() && pSource.pev.health >= 1 )
		{
			CreatePuddle( pSource );
		}
	}
	
	self.pev.nextthink = g_Engine.time + 0.1f;
}

void CreatePuddle( CBaseEntity@ pBloodPuddle )
{
	dictionary keyvalues;
	keyvalues ["origin"]					= pSource.GetOrigin().ToString();
	keyvalues ["model"]						= "models/mikk/misc/bloodpuddle.mdl";
	keyvalues ["sequence"]					= "2"; // Must change to 1 when monster is die and to 0 after the sequence 1 ends.
	keyvalues ["spawnflags"]				= "384";

	g_EntityFuncs.CreateEntity( "item_generic", keyvalues, true );
}

// Quizas es mejor y mas facil si es un nuevo class