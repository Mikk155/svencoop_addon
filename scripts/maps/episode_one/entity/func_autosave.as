// Idk que xuxa haces leyendo esto. -pavotherman

/*
	A Custom brush entity that has been used for ESHQ Port.
	it are supposed to work as a "trigger_autosave" but mommentaneous
	every player life will be saved Once per zone
	when a player touch it. his steamID will be saved
	and then when he dies. he will be resurrected at the origins
	of any keyvalue from this entity. (add origins to kvs)
	
	Know-Issues:
	a player using more than 4 zones (at same time) will "bug" it
	
	Credits:
	Mikk idea
	Sparks for help
	Gaftherman Script
*/

enum FuncAutoSaveFlags
{
	SF_AUTOSAVE_OFF	= 1 << 0, // Iniciar apagado
	SF_AUTOSAVE_HA = 1 << 1, // Guardar la vida y la armadura del jugador
	SF_AUTOSAVE_O = 1 << 2 // Guardar el origin del jugador
}

class PlayerKeepData
{
	Vector origin;
	float health;
	float max_health;
	float armor;
	float max_armor;
}

class func_autosave : ScriptBaseEntity  
{
    private dictionary g_OriginPlayers, g_OriginPlayers2, g_HAPlayers, g_IDPlayers, g_IDPlayers2;
	private Vector PrimerSpawn, SegundoSpawn, TercerSpawn, CuartoSpawn;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "PrimerSpawn" )
		{
			g_Utility.StringToVector( PrimerSpawn, szValue );
			return true;
		}
		else if( szKey == "SegundoSpawn" )
		{
			g_Utility.StringToVector( SegundoSpawn, szValue );
			return true;
		}
		else if( szKey == "TercerSpawn" )
		{
			g_Utility.StringToVector( TercerSpawn, szValue );
			return true;
		}
		else if( szKey == "CuartoSpawn" )
		{
			g_Utility.StringToVector( CuartoSpawn, szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

    void Spawn()
    {
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_TRIGGER;

		g_EntityFuncs.SetModel( self, self.pev.model );
		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		if( !self.pev.SpawnFlagBitSet( SF_AUTOSAVE_OFF ) )
		{
			SetThink( ThinkFunction( this.SpawnThink ) );
			SetTouch( TouchFunction( this.SpawnTouch ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

	    BaseClass.Spawn();
    }

	void AddPlayer( CBasePlayer@ pPlayer )
	{	
        string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        if( pPlayer is null || g_IDPlayers.exists(SteamID) || g_IDPlayers2.exists(SteamID)  )
			return;

        g_IDPlayers[SteamID] = @pPlayer;

        //	g_Game.AlertMessage( at_console, "DEBUG- SteamID has been saved \n" );

		if( self.pev.SpawnFlagBitSet( SF_AUTOSAVE_O ) )
		{
			PlayerKeepData pData;
			pData.origin = pPlayer.pev.origin;
			g_OriginPlayers2[SteamID] = pData;

			//	g_Game.AlertMessage( at_console, "DEBUG- Origin saved \n" );
		}

		if( self.pev.SpawnFlagBitSet( SF_AUTOSAVE_HA ) )
		{
			PlayerKeepData pData;

			pData.health = pPlayer.pev.health;
			pData.max_health = pPlayer.pev.max_health;
			pData.armor = pPlayer.pev.armorvalue;
			pData.max_armor = pPlayer.pev.armortype;

			g_HAPlayers[SteamID] = pData;

			//	g_Game.AlertMessage( at_console, "DEBUG- armor/healt saved \n" );
		}
			
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
    {
		SetThink( ThinkFunction( this.SpawnThink ) );
		SetTouch( TouchFunction( this.SpawnTouch ) );

		self.pev.nextthink = g_Engine.time + 0.1f;
	}

	void SpawnTouch( CBaseEntity@ pOther )
	{
		if( pOther is null || !pOther.IsPlayer() || !pOther.IsAlive() )
			return;

		AddPlayer( cast<CBasePlayer@>( pOther ) );
	}

	void SpawnThink()
	{	
		array<Vector> Spawns = { PrimerSpawn, SegundoSpawn, TercerSpawn, CuartoSpawn };

		for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

			if( pPlayer is null or !pPlayer.IsConnected() )
				continue;

            string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

			if( g_IDPlayers.exists(SteamID) && !pPlayer.IsAlive() && pPlayer.GetObserver().IsObserver() && pPlayer.pev.button & IN_USE != 0)
            {
                //Revive player and move to this checkpoint
				pPlayer.GetObserver().RemoveDeadBody();

				if( !g_OriginPlayers2.exists(SteamID) )
				{
					if( Spawns[0] != Vector(0,0,0) && Spawns[1] != Vector(0,0,0) && Spawns[2] != Vector(0,0,0) && Spawns[3] != Vector(0,0,0) )
						pPlayer.SetOrigin( Spawns[Math.RandomLong( 0, 3 )] );
					else if( Spawns[0] != Vector(0,0,0) && Spawns[1] != Vector(0,0,0) && Spawns[2] != Vector(0,0,0) && Spawns[3] == Vector(0,0,0) )
						pPlayer.SetOrigin( Spawns[Math.RandomLong( 0, 2 )] );
					else if( Spawns[0] != Vector(0,0,0) && Spawns[1] != Vector(0,0,0) && Spawns[2] == Vector(0,0,0) && Spawns[3] == Vector(0,0,0) )
						pPlayer.SetOrigin( Spawns[Math.RandomLong( 0, 1 )] );
					else if( Spawns[0] != Vector(0,0,0) && Spawns[1] == Vector(0,0,0) && Spawns[2] == Vector(0,0,0) && Spawns[3] == Vector(0,0,0) )
						pPlayer.SetOrigin( Spawns[0] );
					else
						pPlayer.SetOrigin( self.Center() );

					pPlayer.Revive();
				}
				else
				{
					PlayerKeepData@ pData = cast<PlayerKeepData@>(g_OriginPlayers2[SteamID]);
					pPlayer.SetOrigin( pData.origin );
					
					pPlayer.Revive();
				}

				if( g_HAPlayers.exists(SteamID) )
				{
					PlayerKeepData@ pData = cast<PlayerKeepData@>(g_HAPlayers[SteamID]);

					pPlayer.pev.health = Math.max( 1, pData.health );
					pPlayer.pev.max_health = Math.max( 100, pData.max_health );
					pPlayer.pev.armorvalue = Math.max( 0, pData.armor );
					pPlayer.pev.armortype = Math.max( 100, pData.max_armor );
				}

				//	g_Game.AlertMessage( at_console, "DEBUG- Player: | " + pPlayer.pev.netname + " | has been respawned \n" );
				//	g_Game.AlertMessage( at_console, "DEBUG- Player: | " + "X: " + pPlayer.pev.origin.x + " Y: " + pPlayer.pev.origin.y + " Z: " + pPlayer.pev.origin.z + " | \n" );
				//	g_Game.AlertMessage( at_console, "DEBUG- Player: | " + "HP: " + pPlayer.pev.health + " Armor: " + pPlayer.pev.armorvalue + " | \n" );
		
				g_IDPlayers2[SteamID] = @pPlayer;
				g_IDPlayers.delete(SteamID);
            }
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f; //per frame
    }
}

void RegisterTriggerPlayerSaveFunc() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_autosave", "func_autosave" );
}