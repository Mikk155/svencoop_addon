void RegisterEnvHurtZone() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "env_hurtzone", "env_hurtzone" );
}

enum env_hurtzone_flag
{
    SF_HZONE_START_OFF = 1 << 0
}

class env_hurtzone : ScriptBaseEntity
{
    private int m_ilRadius			= 0;
    private int m_ilType			= 0;
	private string m_slAmmoType		= "uranium";
    private int m_ilValue			= 1;
	private int m_ilHud				= 0; 
	private int m_ilHudAlt			= 0;
	private int m_ilBeamPointer		= 0;
	private int m_ilFadeScreen		= 0;
	private int m_ilGlowPlayers 	= 0;
	private int m_ilSpeedModifier 	= 0;
	private string m_slPlaySound	= "";
	private string m_ilAttachSpr	= "";
	private bool toggle 			= true;
	private bool Find 				= false;
	private float m_flThinkTime		= 0.1;
    private CBeam@ pBorderBeam;
	private dictionary g_Players;

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
            m_slAmmoType = szValue;
            return true;
        }
        else if( szKey == "value" || szKey == "wait" )
        {
            m_ilValue = atoi( szValue );
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
		else if( szKey == "beampointer" || szKey == "BeamPointer" )
        {
            m_ilBeamPointer = atoi( szValue );
            return true;
        }
        else if( szKey == "fadescreen" || szKey == "FadeScreen" )
        {
            m_ilFadeScreen = atoi( szValue );
            return true;
        }
        else if( szKey == "playersglow" || szKey == "PlayersGlow")
        {
            m_ilGlowPlayers = atoi(szValue);
            return true;
		}
        else if( szKey == "speedmodifier" || szKey == "Speedmodifier"  )
        {
            m_ilSpeedModifier = atoi( szValue );
            return true;
        }
		else if( szKey == "sound" || szKey == "sounds" )
        {
            m_slPlaySound = szValue;
            return true;
        }
		else if( szKey == "AttachSprites" )
        {
            m_ilAttachSpr = szValue;
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
		else if( szKey == "thinktime" || szKey == "ThinkTime" )
		{
			m_flThinkTime = atof(szValue);
			return true;	
		}
        else 
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        g_Game.PrecacheGeneric( "sprites/laserbeam.spr" );

		if( m_slPlaySound != "" )
		{
			g_SoundSystem.PrecacheSound( m_slPlaySound );
			g_Game.PrecacheGeneric( m_slPlaySound );
		}
		
		if( m_ilAttachSpr != "" )
		{
			g_Game.PrecacheModel( m_ilAttachSpr );
			g_Game.PrecacheGeneric( m_ilAttachSpr );
		}

        BaseClass.Precache();
    }

	void Spawn() 
	{
        self.Precache();
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_NOT;

        if( self.GetClassname() == "env_hurtzone" && string( self.pev.model )[0] == "*" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
		else if( m_ilRadius == 0 )
		{
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
		}
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		
        if( !self.pev.SpawnFlagBitSet( SF_HZONE_START_OFF ) )
		{		
			toggle = false;
			SetThink( ThinkFunction( this.FindEntity ) );
			self.pev.nextthink = g_Engine.time + m_flThinkTime;
		}
		
        BaseClass.Spawn();
	}

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
		if( toggle )
		{
			SetThink( ThinkFunction( this.FindEntity ) );
			self.pev.nextthink = g_Engine.time + m_flThinkTime;
		}
		else
		{
			SetThink( null );
			g_Scheduler.SetTimeout( this, "ResetValues", 0.25 );
		}

		toggle = !toggle;
	}

    void FindEntity()
    {
	//	array<char> Something { "Something" };
		
		//g_Game.AlertMessage( at_console, string(Some)+'\n' );
		FindTarget();

        for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            
            if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
                continue;

            if( m_ilRadius <= 0 && Inside( pPlayer ) || m_ilRadius >= 1 && ( self.pev.origin - pPlayer.pev.origin ).Length() <= m_ilRadius && self.FVisibleFromPos( pPlayer.pev.origin, self.pev.origin ) )
            {
                if( pPlayer.pev.health >= 0 && m_ilType == 0 ) // Just damage.
                {
					SaveSteamID( pPlayer );
					VerifyEffects( pPlayer );
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilValue * 1.2, DMG_SHOCK );
                }
                else if( pPlayer.pev.health < pPlayer.pev.max_health && m_ilType == 1 ) // Just heal.
                {
					SaveSteamID( pPlayer );
					VerifyEffects( pPlayer );
					pPlayer.TakeHealth( m_ilValue, DMG_GENERIC );
                }
                else if( pPlayer.pev.armorvalue < pPlayer.pev.armortype && m_ilType == 2 ) // Just recharge suit.
                {
					SaveSteamID( pPlayer );
					VerifyEffects( pPlayer );
                    pPlayer.pev.armorvalue = pPlayer.pev.armorvalue + m_ilValue;
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_SHOCK );
                }
                else if( pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( m_slAmmoType ) ) < pPlayer.GetMaxAmmo( m_slAmmoType ) && m_ilType == 3 ) // Just give ammo.
                {      
					SaveSteamID( pPlayer );           
					VerifyEffects( pPlayer );
                    pPlayer.GiveAmmo( m_ilValue, m_slAmmoType, pPlayer.GetMaxAmmo( m_slAmmoType ) );
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_RADIATION );
                }
            }
            else
            {
				// Return player rendermode.
				if( pPlayer.pev.rendercolor == self.pev.rendercolor && ExistSteamID( pPlayer ) )
				{
					pPlayer.pev.rendermode  = kRenderNormal;
					pPlayer.pev.renderfx    = kRenderFxNone;
					pPlayer.pev.renderamt   = 255;
					pPlayer.pev.rendercolor = Vector(0,0,0); 

					// Stop the sound.
					if( m_slPlaySound != "" )
					{
						g_SoundSystem.StopSound( pPlayer.edict(), CHAN_STATIC, m_slPlaySound ); // it is from the audio remaster
					}

					// Return default speed.
					pPlayer.SetMaxSpeedOverride( -1 );

					DeleteSteamID( pPlayer );
				}
            }
		}
        self.pev.nextthink = g_Engine.time + m_flThinkTime;
    }

	void FindTarget()
	{
        CBaseEntity@ pSource = null;
		while((@pSource = g_EntityFuncs.FindEntityByTargetname(pSource, self.pev.target)) !is null)
		{
			if( pSource.IsMonster() )
			{
				if( pSource.IsAlive() && pSource.pev.health >= 1 )
				{
					g_EntityFuncs.SetOrigin( self, pSource.Center());
					Find = true;
					return;	
				}
			}
			else
			{
				g_EntityFuncs.SetOrigin( self, pSource.Center());
				Find = true;
				return;			
			}
		}

		if( Find )
		{
			g_EntityFuncs.Remove( self );
		}
	}

    void UpdateOnRemove()
    {
		g_Game.AlertMessage( at_console, 'Activando ResetValues \n');

		g_Scheduler.SetTimeout( this, "ResetValues", 0.25 );
        BaseClass.UpdateOnRemove();
    }

	void ResetValues()
	{
        for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            
            if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
                continue;

			if( ExistSteamID( pPlayer ) )
			{
				pPlayer.pev.rendermode  = kRenderNormal;
				pPlayer.pev.renderfx    = kRenderFxNone;
				pPlayer.pev.renderamt   = 255;
				pPlayer.pev.rendercolor = Vector(0,0,0); 

				// Stop the sound.
				if( m_slPlaySound != "" )
				{
					g_SoundSystem.StopSound( pPlayer.edict(), CHAN_STATIC, m_slPlaySound ); // it is from the audio remaster
				}

				// Return default speed.
				pPlayer.SetMaxSpeedOverride( -1 );

				DeleteSteamID( pPlayer );
			}
		}
	}

    void VerifyEffects( CBasePlayer@ pPlayer )
    {	
		if( m_ilBeamPointer >= 1 ) // Add beam from this entity's origin to the affected player.
		{
			@pBorderBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
			pBorderBeam.SetFlags( BEAM_POINTS | SF_BEAM_SHADEIN );
			pBorderBeam.SetStartPos( self.Center() );
			pBorderBeam.SetEndPos( pPlayer.Center() );
			pBorderBeam.SetScrollRate( 100 );
			pBorderBeam.LiveForTime( 0.20 );
			pBorderBeam.pev.rendercolor = self.pev.rendercolor == g_vecZero ? Vector( 255, 0, 0 ) : self.pev.rendercolor;
		}

		if( m_ilFadeScreen >= 1  ) // Fade screen effect.
		{
			g_PlayerFuncs.ScreenFade( pPlayer, self.pev.rendercolor, 1.01f, 1.5f, 52, FFADE_IN );
		}

		if( m_ilGlowPlayers >= 1  ) // Add glow to the player
		{
			if( pPlayer.pev.rendercolor == g_vecZero )
			{
				pPlayer.pev.rendermode  = kRenderNormal;
				pPlayer.pev.renderfx    = kRenderFxGlowShell;
				pPlayer.pev.renderamt   = 4;
				pPlayer.pev.rendercolor = self.pev.rendercolor;
			}
		}
		
		if( m_slPlaySound != "" ) // Play sounds (specify custom sounds too)
		{
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, m_slPlaySound, 1.0f, 1.0f, 0, PITCH_NORM );
		}

		if( m_ilSpeedModifier >= 1 ) // Add glow to the player
		{
			pPlayer.SetMaxSpeedOverride( m_ilSpeedModifier );
		}

		if( m_ilAttachSpr >= 1 ) // Add Sprites to player
		{
			NetworkMessage firemsg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );

			firemsg.WriteByte(TE_PLAYERSPRITES);
			firemsg.WriteShort(pPlayer.entindex());
			firemsg.WriteShort(g_EngineFuncs.ModelIndex( m_ilAttachSpr )); // bubble"sprites/mommaspit.spr" 
			firemsg.WriteByte(16);
			firemsg.WriteByte(0);
			firemsg.End();
            return;
		}
		
		SendDeath( pPlayer );
		
		pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, m_ilHud | m_ilHudAlt );
    }
	
	void SendDeath( CBasePlayer@ pPlayer, const string& in strName, uint framenum = 0, float hold = 0.1 )
	{
		HUDSpriteParams params;
		params.channel = 14;
		params.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X; 
		params.spritename = "sprites/laserbeam.spr";
		params.x = 0;
		params.y = -128;
		params.framerate = 0;
		params.frame = framenum;
		params.holdTime = hold + 0.2;
		params.color1 = RGBA_RED;
		params.fadeoutTime = 0.1;
		g_PlayerFuncs.HudCustomSprite( pPlayer, params );
	}

	void SaveSteamID( CBasePlayer@ pPlayer )
	{
		string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if( !g_Players.exists(SteamID) )
		{
			g_Players[SteamID] = self.pev.rendermode;
		}
	}

	void DeleteSteamID( CBasePlayer@ pPlayer )
	{
		string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if( g_Players.exists(SteamID) )
		{
			g_Players.delete(SteamID);
		}
	}

	bool ExistSteamID( CBasePlayer@ pPlayer )
	{
		string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		return g_Players.exists(SteamID);
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

		return a;
	}
}