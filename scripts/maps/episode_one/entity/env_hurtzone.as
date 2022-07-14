enum env_hurtzone_flag
{
    SF_HZONE_START_OFF = 1 << 0,
}

class env_hurtzone : ScriptBaseEntity
{
    private int m_ilRadius			= 0;
    private int m_ilType			= 0;
	private int m_ilAmmoType		= 0;
    private int m_ilwait			= 1;
	private int m_ilHud				= DMG_GENERIC;
	private int m_ilHudAlt			= DMG_GENERIC;
	private int m_ilBeamPointer		= 0;
    private CBeam@ pBorderBeam;
	private int m_ilFadeScreen		= 0;
	private int m_ilPlaySound		= 0;
	private int m_ilSpeedModifier	= 0;
	private int m_ilGlowPlayers		= 0;

	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
        if( szKey == "radius" )
        {
            m_ilRadius = atoi( szValue );
            return true;
        }
        else if( szKey == "type" )
        {
            m_ilType = atoi( szValue );
            return true;
        }
        else if( szKey == "ammotype" )
        {
            m_ilAmmoType = atoi( szValue );
            return true;
        }
        else if( szKey == "wait" )
        {
            m_ilwait = atoi( szValue );
            return true;
        }
        else if( szKey == "damagehud" )
        {
            m_ilHud = atoi( szValue );
            return true;
        }
        else if( szKey == "damagehudalt" )
        {
            m_ilHudAlt = atoi( szValue );
            return true;
        }
		else if( szKey == "BeamPointer" )
        {
            m_ilBeamPointer = atoi( szValue );
            return true;
        }
        else if( szKey == "FadeScreen" )
        {
            m_ilFadeScreen = atoi( szValue );
            return true;
        }
		else if( szKey == "sounds" )
        {
            m_ilPlaySound = atoi( szValue );
            return true;
        }
        else if( szKey == "Speedmodifier" )
        {
            m_ilSpeedModifier = atoi( szValue );
            return true;
        }
        else if( szKey == "PlayersGlow" )
        {
            m_ilGlowPlayers = atoi( szValue );
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
        else 
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        g_Game.PrecacheGeneric( "sprites/laserbeam.spr" );

		g_SoundSystem.PrecacheSound( "ambience/alien_beacon.wav" );
		g_Game.PrecacheGeneric( "ambience/alien_beacon.wav" );

        BaseClass.Precache();
    }

	void Spawn() 
	{
        self.Precache();
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_NOT;
		
		// Asign bspmodel if it is, ignore radius n hullsizes
		if( self.GetClassname() == "env_hurtzone" && string( self.pev.model )[0] == "*" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
		// Asign hullsizes if radius is 0.
		else if(m_ilRadius == 0)
		{
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
		}
		// otherwhise use radius.
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( !self.pev.SpawnFlagBitSet( SF_HZONE_START_OFF ) )
		{	
			SetThink( ThinkFunction( this.FindEntity ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
		
        BaseClass.Spawn();
	}

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.SpawnFlagBitSet( SF_HZONE_START_OFF ) )
		{	
			SetThink( ThinkFunction( this.FindEntity ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}

    void FindEntity()
    {
        for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            
            if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
                continue;

			// Check if radius is 0, if yes use hullsizes or BSP Model.
			if( m_ilRadius == 0 && Inside( pPlayer ) or ( self.pev.origin - pPlayer.pev.origin ).Length() <= m_ilRadius && self.FVisibleFromPos( pPlayer.pev.origin, self.pev.origin ) )
            {
                if( pPlayer.pev.health >= 0 && m_ilType == 0 )
                {
					// Damage
					VerifyEffects( pPlayer );
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilwait * 1.2, DMG_GENERIC );
                }
                else if( pPlayer.pev.health < pPlayer.pev.max_health && m_ilType == 1 ) // Just heal.
                {
					// Heal
					VerifyEffects( pPlayer );
                    pPlayer.pev.health = pPlayer.pev.health + m_ilwait;
                }
                else if( pPlayer.pev.armorvalue < pPlayer.pev.armortype && m_ilType == 2 ) // Just recharge suit.
                {
					// Charge suit
					VerifyEffects( pPlayer );
                    pPlayer.pev.armorvalue = pPlayer.pev.armorvalue + m_ilwait;
                }
                else if( pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( m_ilAmmoType ) ) < pPlayer.GetMaxAmmo( m_ilAmmoType ) && m_ilType == 3 )
                {                  
					// Give ammunition. (specify keyvalue)
					VerifyEffects( pPlayer );
                    pPlayer.GiveAmmo( m_ilwait, m_ilAmmoType, pPlayer.GetMaxAmmo( m_ilAmmoType ) );
                }
				
				if( m_ilSpeedModifier >= 1)
				{ // not sure why i can't put this in VerifyEffects();
					pPlayer.pev.velocity = pPlayer.pev.velocity * 0.9;
					pPlayer.SetMaxSpeedOverride( m_ilSpeedModifier );
				}
            }
            else
            {
				// Return player rendermode.
				pPlayer.pev.rendermode  = kRenderNormal;
				pPlayer.pev.renderfx    = kRenderFxNone;
				pPlayer.pev.renderamt   = 255;
				pPlayer.pev.rendercolor = Vector(0,0,0); 
				// Stop the sound.
				g_SoundSystem.StopSound( pPlayer.edict(), CHAN_STATIC, "ambience/alien_beacon.wav" ); // it is from the audio remaster
				// Return default speed.
				pPlayer.SetMaxSpeedOverride( -1 );
            }
        }

        CBaseEntity@ pSource = null;
        while((@pSource = g_EntityFuncs.FindEntityByTargetname(pSource, self.pev.target)) !is null)
        {
			pSource.GetOrigin();
			g_EntityFuncs.SetOrigin( self, pSource.pev.origin );
			
			// i dont know how to check if this bastard died. should improve this for using non-monster entities. "if pSource doesn't exist -> Remove self"
			if( pSource.pev.health <= 1 )
			{
				g_EntityFuncs.Remove( self );
			}
		}
		
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void VerifyEffects( CBaseEntity@ pPlayer )
    {
		if( m_ilBeamPointer == 1 ) // Add beam from this entity's origin to the affected player.
		{
			@pBorderBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
			pBorderBeam.SetFlags( BEAM_POINTS  | SF_BEAM_SHADEIN );
			pBorderBeam.SetStartPos( self.pev.origin );
			pBorderBeam.SetEndPos( pPlayer.Center() );
			pBorderBeam.SetScrollRate( 100 );
			pBorderBeam.LiveForTime( 0.10 );
			pBorderBeam.pev.rendercolor = self.pev.rendercolor == g_vecZero ? Vector( 255, 0, 0 ) : self.pev.rendercolor;
		}
		if( m_ilFadeScreen == 1) // Fade screen effect.
		{
			g_PlayerFuncs.ScreenFade( pPlayer, self.pev.rendercolor, 1.01f, 1.5f, 52, FFADE_IN );
		}
		if( m_ilPlaySound == 1) // Play sounds (specify custom sounds too)
		{
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "ambience/alien_beacon.wav", 1.0f, 1.0f, 0, PITCH_NORM );
		}
		if( m_ilGlowPlayers == 1)
		{
			pPlayer.pev.rendermode  = kRenderNormal;
			pPlayer.pev.renderfx    = kRenderFxGlowShell;
			pPlayer.pev.renderamt   = 4;
			pPlayer.pev.rendercolor = self.pev.rendercolor;
		}
		
		// For hud DMG types.
		pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, m_ilHud | m_ilHudAlt );
		return;   
    }

	// For hullsizes n BSPModel.
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

void RegisterEnvHurtZone() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "env_hurtzone", "env_hurtzone" );
}