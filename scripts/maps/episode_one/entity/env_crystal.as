class env_crystal : ScriptBaseEntity
{
    private int m_ilRadius			= 128;
    private int m_ilType			= 0;
    private int m_ilValue			= 1;
    private CBeam@ pBorderBeam;

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
        else if( szKey == "value" )
        {
            m_ilValue = atoi( szValue );
            return true;
        }
        else 
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        g_Game.PrecacheGeneric( "sprites/laserbeam.spr" );
		g_Game.PrecacheModel( "sprites/mikk/episode_one/hud_spored.spr" );
		g_Game.PrecacheGeneric( "sprites/mikk/episode_one/hud_spored.spr" );

		g_SoundSystem.PrecacheSound( "mikk/episode_one/ambience/alien_beacon.wav" );
		g_Game.PrecacheGeneric( "sound/mikk/episode_one/ambience/alien_beacon.wav" );

        BaseClass.Precache();
    }

	void Spawn() 
	{
        self.Precache();
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_NOT;
		
        CBaseEntity@ pSourceMonster = null;
        while((@pSourceMonster = g_EntityFuncs.FindEntityByTargetname(pSourceMonster, self.pev.target)) !is null)
        {
			g_Game.AlertMessage(at_console, "Se encontro el npc\n"); 
			g_Game.AlertMessage(at_console, "iniciando setorigin\n"); 
			CopyPointer( pSourceMonster );
			//SetThink( ThinkFunction( this.CopyPointer( pSourceMonster ) ) ); <- dice error.
			//self.pev.nextthink = g_Engine.time + 0.1f;
		}
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		
		SetThink( ThinkFunction( this.FindEntity ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
        BaseClass.Spawn();
	}

	void CopyPointer(CBaseEntity@ pSourceMonster)
	{
		//g_EntityFuncs.SetOrigin(pSourceMonster.pev.origin); <- copiar origin del zombie y pegarlo en esta entidad.
		g_Game.AlertMessage(at_console, "Registrado\n"); 
		
		/*if( si el zombie muere se elimina el env_crystal)
		{
			g_EntityFuncs.Remove( self );
		}*/
		
		self.pev.nextthink = g_Engine.time + 0.5f;
	}
	
    void FindEntity()
    {
        for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            
            if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
                continue;

            if( ( self.pev.origin - pPlayer.pev.origin ).Length() <= m_ilRadius && self.FVisibleFromPos( pPlayer.pev.origin, self.pev.origin ) )
            {
                if( pPlayer.pev.health >= 0 && m_ilType == 0 )
                {
					RenderBeams( pPlayer );
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilValue * 1.2, DMG_SHOCK );
                }
                else if( pPlayer.pev.health < pPlayer.pev.max_health && m_ilType == 1 )
                {
					RenderBeams( pPlayer );
                    pPlayer.pev.health = pPlayer.pev.health + m_ilValue;
                }
                else if( pPlayer.pev.armorvalue < pPlayer.pev.armortype && m_ilType == 2 )
                {
					RenderBeams( pPlayer );
                    pPlayer.pev.armorvalue = pPlayer.pev.armorvalue + m_ilValue;
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_SHOCK );
                }
                else if( pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "uranium" ) ) < pPlayer.GetMaxAmmo( "uranium" ) && m_ilType == 3 )
                {                  
					RenderBeams( pPlayer );
                    pPlayer.GiveAmmo( m_ilValue, "uranium", pPlayer.GetMaxAmmo( "uranium" ) );
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_RADIATION );
                }
				else if( pPlayer.pev.health >= 0 && m_ilType == 4 )
                {
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilValue * 1.2, DMG_PARALYZE );
					pPlayer.pev.velocity = pPlayer.pev.velocity * 0.9;
					pPlayer.SetMaxSpeedOverride( 80 );
					PlayerFX( pPlayer );
                }
            }
            else
            {
                if( pPlayer.pev.rendercolor == self.pev.rendercolor )
                {
                    pPlayer.pev.rendermode  = kRenderNormal;
                    pPlayer.pev.renderfx    = kRenderFxNone;
                    pPlayer.pev.renderamt   = 255;
                    pPlayer.pev.rendercolor = Vector(0,0,0); 
					g_SoundSystem.StopSound( pPlayer.edict(), CHAN_STATIC, "mikk/episode_one/ambience/alien_beacon.wav" ); // it is from the audio remaster :p
					pPlayer.SetMaxSpeedOverride( -1 );
                }
            }
        }

        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void RenderBeams( CBaseEntity@ pPlayer )
    {
		PlayerFX( pPlayer );
		
		@pBorderBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
		pBorderBeam.SetFlags( BEAM_POINTS  | SF_BEAM_SHADEIN );
		pBorderBeam.SetStartPos( self.pev.origin );
		pBorderBeam.SetEndPos( pPlayer.Center() );
		pBorderBeam.SetScrollRate( 100 );
		pBorderBeam.LiveForTime( 0.10 );
		pBorderBeam.pev.rendercolor = self.pev.rendercolor == g_vecZero ? Vector( 255, 0, 0 ) : self.pev.rendercolor;
		
		g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "mikk/episode_one/ambience/alien_beacon.wav", 1.0f, 1.0f, 0, PITCH_NORM );
		return;   
    }

    void PlayerFX( CBaseEntity@ pPlayer )
    {
		//RenderSpriteHud( pPlayer );
		
		if( pPlayer.pev.rendercolor == g_vecZero )
		{
			pPlayer.pev.rendermode  = kRenderNormal;
			pPlayer.pev.renderfx    = kRenderFxGlowShell;
			pPlayer.pev.renderamt   = 4;
			pPlayer.pev.rendercolor = self.pev.rendercolor;
		}

		g_PlayerFuncs.ScreenFade( pPlayer, self.pev.rendercolor, 1.01f, 1.5f, 52, FFADE_IN );
		return;   
    }

	/*void RenderSpriteHud( CBaseEntity@ pPlayer )
    {
		HUDSpriteParams params;
		params.channel = 8;

		// Default mode is additive, so no flag is needed to assign it
		params.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_DYNAMIC_ALPHA;
		params.spritename = "sprites/mikk/episode_one/hud_spored.spr";
		params.left = 0;
		params.top = 0;
		params.width = 512;
		params.height = 512;
		params.color1 = RGBA_YELLOW;
		params.frame = 0;
		params.numframes = 1;
		params.framerate = 0;
		params.fadeinTime = 0;
		params.fadeoutTime = 0;
		params.holdTime = 1;
		params.effect = HUD_EFFECT_NONE;
		
//		g_PlayerFuncs.HudCustomSprite( pPlayer, params ); // idk por que no anda

		return;   
    }*/
}

void RegisterEnvCrystal() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "env_crystal", "env_crystal" );
}