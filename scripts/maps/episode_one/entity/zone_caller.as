void RegisterZoneCaller()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "zone_caller", "zone_caller" );
}

class zone_caller : ScriptBaseEntity
{
    private int m_ilCallType			= 0;

	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
        if( szKey == "calltype" )
        {
            m_ilCallType = atoi( szValue );
            return true;
        }
		else
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
	}
	
    void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetModel( self, self.pev.model );
		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );

		SetThink( ThinkFunction( this.TriggerThink ) );
		self.pev.nextthink = g_Engine.time + 0.1f;

        BaseClass.Spawn();
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) 
	{
		self.SUB_UseTargets( pActivator, USE_TOGGLE, 0.0f );
	}
	
	void TriggerThink() 
	{
		for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
			
			if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
				continue;

			if( Inside( pPlayer ) )
			{
				if( m_ilCallType == 0 )
				{
					if( pPlayer.pev.button & IN_USE != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
						g_Game.AlertMessage(at_console, "Jugador " +pPlayer.pev.netname+ " Dentro :D\n"); 
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[E] What is this?\n");
				}
				else if( m_ilCallType == 1  )
				{
					if( pPlayer.pev.button & IN_DUCK != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[CONTROL]\n");
				}
				else if( m_ilCallType == 2 )
				{
					if( pPlayer.pev.button & IN_ATTACK != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[MOUSE 1]\n");
				}
				else if( m_ilCallType == 3 )
				{
					if( pPlayer.pev.button & IN_JUMP != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[SPACE]\n");
				}
				else if( m_ilCallType == 4 )
				{
					if( pPlayer.pev.button & IN_FORWARD != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[W]\n");
				}
				else if( m_ilCallType == 5 )
				{
					if( pPlayer.pev.button & IN_BACK != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[S]\n");
				}
				else if( m_ilCallType == 6 )
				{
					if( pPlayer.pev.button & IN_ATTACK2 != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[MOUSE 2]\n");
				}
				else if( m_ilCallType == 7 )
				{
					if( pPlayer.pev.button & IN_RUN != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[SHIFT]\n");
				}
				else if( m_ilCallType == 8 )
				{
					if( pPlayer.pev.button & IN_ALT1 != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[MOUSE 3]\n");
				}
				else if( m_ilCallType == 9 )
				{
					if( pPlayer.pev.button & IN_SCORE != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[TAB]\n");
				}
				else if( m_ilCallType == 10 )
				{
					if( pPlayer.pev.button & IN_RELOAD != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[R]\n");
				}
				else if( m_ilCallType == 11 )
				{
					if( pPlayer.pev.button & IN_MOVERIGHT != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[D]\n");
				}
				else if( m_ilCallType == 12 )
				{
					if( pPlayer.pev.button & IN_MOVELEFT != 0 )
					{
						self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );
					}
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER,"[A]\n");
				}
			}
		}

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