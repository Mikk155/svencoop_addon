/*Original Script by Cubemath*/
enum trigger_once_flag
{
    SF_AR_START_OFF = 1 << 0
}

class ar_trigger_once : ScriptBaseEntity 
{
	private float m_flPercentage = 0.5f; //Percentage of living people to be inside trigger to trigger
	private string killtarget, master;
	private bool debug = true, Verify = false;
	
	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
		if( szKey == "m_flPercentage" ) 
		{
			m_flPercentage = atof( szValue );
			return true;
		} 
		else if( szKey == "minhullsize" ) 
		{
			g_Utility.StringToVector( self.pev.vuser1, szValue );
			return true;
		} 
		else if( szKey == "maxhullsize" ) 
		{
			g_Utility.StringToVector( self.pev.vuser2, szValue );
			return true;
		} 
        else if( szKey == "killtarget" )
		{
            killtarget = szValue;
			return true;
		}
        else if( szKey == "master" )
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

		if( !debug )
        	self.pev.effects |= EF_NODRAW;

        if( self.GetClassname() == "ar_trigger_once" && string( self.pev.model )[0] == "*" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
		else
		{
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );		
		}

		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( !self.pev.SpawnFlagBitSet( SF_AR_START_OFF ) )
		{
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

        BaseClass.Spawn();
	}
	
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.SpawnFlagBitSet( SF_AR_START_OFF ) )
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

		float TotalPlayers = 0, PlayersTrigger = 0, CurrentPercentage = 0;

		for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				
			if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
				continue;

			if( Inside( pPlayer ) )
				PlayersTrigger = PlayersTrigger + 1.0f;
					
			TotalPlayers = TotalPlayers + 1.0f;	
		}
				
		if(TotalPlayers > 0) 
		{
			CurrentPercentage = PlayersTrigger / TotalPlayers + 0.00001f;

			for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

				if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
					continue;

				if( Inside( pPlayer ) )
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"ANTI-RUSH: (" +int(m_flPercentage*100)+ "%) needed.\n Percent now (" +int(CurrentPercentage*100)+ "%)" + "\n");
			}

			if( CurrentPercentage >= m_flPercentage ) 
			{			
				if( killtarget != "" && killtarget != self.GetTargetname() )
				{
					do g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, killtarget ) );
					while( g_EntityFuncs.FindEntityByTargetname( null, killtarget ) !is null );
				}

				self.SUB_UseTargets( @self, USE_TOGGLE, 0 );
				g_EntityFuncs.Remove( self );
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

class ar_func_wall : ScriptBaseEntity
{
    void Spawn()
    {
		CreateFakeWall();
    }

	void CreateFakeWall()
	{
		dictionary decalvalues;
		decalvalues ["origin"]				= "" + self.GetOrigin().ToString();
		decalvalues ["spawnflags"]			= "" + self.pev.spawnflags;
		decalvalues ["model"]				= "" + self.pev.model;
		decalvalues ["targetname"]			= "" + self.pev.targetname;
		decalvalues ["rendermode"]			= "4";
		decalvalues ["renderamt"]			= "0";

		g_EntityFuncs.CreateEntity( "func_wall_toggle", decalvalues, true );
	}
}

void RegisterAntiRushEntity() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ar_trigger_once", "ar_trigger_once" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ar_func_wall", "ar_func_wall" );
}