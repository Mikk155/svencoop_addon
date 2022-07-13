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
		if( szKey == "minhullsize" ) 
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

        if( self.GetClassname() == "env_crystal" && string( self.pev.model )[0] == "*" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
		else if( self.GetClassname() == "env_crystal" && string( self.pev.minhullsize )[0] == "" && self.IsBSPModel() )
		{
			g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );		
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
                if( pPlayer.pev.health >= 0 && m_ilType == 0 ) // Just damage.
                {
					RenderBeams( pPlayer );
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilValue * 1.2, DMG_SHOCK );
                }
                else if( pPlayer.pev.health < pPlayer.pev.max_health && m_ilType == 1 ) // Just heal.
                {
					RenderBeams( pPlayer );
                    pPlayer.pev.health = pPlayer.pev.health + m_ilValue;
                }
                else if( pPlayer.pev.armorvalue < pPlayer.pev.armortype && m_ilType == 2 ) // Just recharge suit.
                {
					RenderBeams( pPlayer );
                    pPlayer.pev.armorvalue = pPlayer.pev.armorvalue + m_ilValue;
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_SHOCK );
                }
                else if( pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "uranium" ) ) < pPlayer.GetMaxAmmo( "uranium" ) && m_ilType == 3 ) // Just give uranium.
                {                  
					RenderBeams( pPlayer );
                    pPlayer.GiveAmmo( m_ilValue, "uranium", pPlayer.GetMaxAmmo( "uranium" ) );
                    pPlayer.TakeDamage( self.pev, self.pev, 0 * 0.0, DMG_RADIATION );
                }
				else if( pPlayer.pev.health >= 0 && m_ilType == 4 )
                {
                    pPlayer.TakeDamage( self.pev, self.pev, m_ilValue * 1.2, DMG_PARALYZE ); // Paralize spores.
					pPlayer.pev.velocity = pPlayer.pev.velocity * 0.9;
					pPlayer.SetMaxSpeedOverride( 80 );
					PlayerFX( pPlayer );
                }
				else if( pPlayer.pev.health >= 0 && m_ilType == 5 )
                {
					pPlayer.TakeDamage( self.pev, self.pev, 1 * 1.0, DMG_SLOWBURN | DMG_BURN ); // Burn player.
					RenderFire(pPlayer);
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

	void RenderFire(CBasePlayer@ pPlayer)
    {
		NetworkMessage firemsg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
		
		firemsg.WriteByte(TE_PLAYERSPRITES);
		firemsg.WriteShort(pPlayer.entindex());
		firemsg.WriteShort(g_EngineFuncs.ModelIndex( "sprites/fire.spr" ));
		firemsg.WriteByte(16);
		firemsg.WriteByte(0);
		firemsg.End();
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

void RegisterEnvCrystal() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "env_crystal", "env_crystal" );
}