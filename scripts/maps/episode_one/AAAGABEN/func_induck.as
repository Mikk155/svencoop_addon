/*
	Custom Brush entity used for the campaign Hardcore-Life on a certain maps that are supposed
	to implement a "stealth" system, players holding control into the brush will receive notarget mode
	use this brush where you have placed shadow/leaves/brushes etc
	
	Credits:
	Mikk idea
	Sparks for help
	Gaftherman Script
*/
enum func_induck_flag
{
    SF_FUNC_INDUCK_START_OFF = 1 << 0
}

class func_induck : ScriptBaseEntity 
{
	private string master;
	private bool Verify = false;
	
	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
		if( szKey == "master" ) // Obsolete.
		{
            master = szValue;
			return true;
		}
		else 
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn() 
	{
        self.Precache();

        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
		self.pev.effects |= EF_NODRAW;

        g_EntityFuncs.SetModel( self, self.pev.model );
        g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );

		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( !self.pev.SpawnFlagBitSet( SF_FUNC_INDUCK_START_OFF ) )
		{
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

        BaseClass.Spawn();
	}
	
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.SpawnFlagBitSet( SF_FUNC_INDUCK_START_OFF ) )
		{	
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}
	
	void TriggerThink() 
	{	
		if( !Verify )
		{
			if( !g_EntityFuncs.IsMasterTriggered( master, null ) )
			{
				self.pev.nextthink = g_Engine.time + 0.1f;
				return;
			}
		}

		for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				
			if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
				continue;

			if( Inside( pPlayer ) && pPlayer.pev.button & IN_DUCK != 0 )
			{
				pPlayer.pev.solid = SOLID_NOT;
				pPlayer.pev.rendermode = kRenderTransTexture;
				pPlayer.pev.renderamt = 128;
				pPlayer.pev.flags |= FL_NOTARGET;
				pPlayer.BlockWeapons( null ); //Idk how this works xdn't
			}
		}

		Verify = true;

		self.pev.nextthink = g_Engine.time + 0.1f;
	}

	bool Inside(CBasePlayer@ pPlayer)
	{
		bool a = true;
		a = a && pPlayer.pev.origin.x + pPlayer.pev.maxs.x >= self.pev.origin.x + self.pev.mins.x;
		a = a && pPlayer.pev.origin.y + pPlayer.pev.maxs.y >= self.pev.origin.y + self.pev.mins.y;
		a = a && pPlayer.pev.origin.z + pPlayer.pev.maxs.z >= self.pev.origin.z + self.pev.mins.z;
		a = a && pPlayer.pev.origin.x + pPlayer.pev.mins.x <= self.pev.origin.x + self.pev.maxs.x;
		a = a && pPlayer.pev.origin.y + pPlayer.pev.mins.y <= self.pev.origin.y + self.pev.maxs.y;
		a = a && pPlayer.pev.origin.z + pPlayer.pev.mins.z <= self.pev.origin.z + self.pev.maxs.z;

		if(a)
			return true;
		else
			return false;
	}
}

void FuncInDuck() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_induck", "func_induck" );
}