/*
* trigger_once_mp
* Point Entity / Solid Entity
* Variable Hullsize and percentage of living people
*
*	Original Script by Cubemath, Modified by Mikk & Gaftherman
*/

enum trigger_once_flag
{
    SF_START_OFF = 1 << 0
}

class antirush : ScriptBaseEntity 
{
	private float m_flPercentage = 0.5f; //Percentage of living people to be inside trigger to trigger
	private float delayreset		= 0.0;
	private killtarget;
	
	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
		if( szKey == "m_flPercentage"/* Only for legacy */ || "count" ) 
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
        else if( szKey == "killtarget" /* Why this isn't a default key? */ )
		{
            killtarget = szValue;
			return true;
		}
        else if( szKey == "delayreset" /* only for legacy, use spawnflag 1 instead */)
		{
            delayreset = szValue;
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

        // self.pev.effects |= EF_NODRAW;

		g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
		
		CreateWall();

        if( !self.pev.SpawnFlagBitSet( SF_START_OFF ) )
		{
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

        BaseClass.Spawn();
	}
	
	void CreateWall()
	{
		dictionary values;
		values ["origin"]				= "" + self.GetOrigin().ToString();
		values ["model"]				= "" + self.pev.model;
		values ["targetname"]			= "" + self.pev.target;
		values ["rendermode"]			= "4";
		values ["renderamt"]			= "0";

		g_EntityFuncs.CreateEntity( "func_wall_toggle", values, true );
	}
	
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.SpawnFlagBitSet( SF_START_OFF ) )
		{	
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}
	
	void TriggerThink() 
	{
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
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"ANTI-RUSH: (" +int(m_flPercentage*100)+ "%%) needed to finish.\n Percent now (" +int(CurrentPercentage*100)+ "%%)" + "\n");
			}

			if( CurrentPercentage >= m_flPercentage ) 
			{			
				if( killtarget != "" && killtarget != self.GetTargetname() )
				{
					do g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, killtarget ) );
					while( g_EntityFuncs.FindEntityByTargetname( null, killtarget ) !is null );
				}
				
				if( delayreset >= 0 )
				{
					SetThink( null );
					g_Scheduler.SetTimeout( this, "ResetValues", delayreset );
				}
				else
				{
					g_EntityFuncs.Remove( self );
				}
				self.SUB_UseTargets( @self, USE_TOGGLE, 0 );
			}
		}

		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void(ResetValues)
	{
		SetThink( ThinkFunction( this.TriggerThink ) );
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

void RegisterTriggerOnceMpEntity() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "antirush", "antirush" );
}
