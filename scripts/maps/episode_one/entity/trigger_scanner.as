enum trigger_scanner_flag
{
    SF_TRIGGER_SCANNER_START_OFF = 1 << 0,
    SF_TRIGGER_SCANNER_JUST_MONSTERS = 1 << 1
}

class trigger_scanner : ScriptBaseEntity
{
    private string m_slMaster = "", m_slKillTarget = "";
    private int m_ilMaxCount = 5, Count = 0, m_flRadius = 125;
    private bool Activated = false;

	bool KeyValue( const string& in szKey, const string& in szValue ) 
	{
		if( szKey == "delay" ) 
		{
			m_ilMaxCount= atoi( szValue );
			return true;
		} 
        else if( szKey == "radius" )
		{
            m_flRadius = atoi( szValue );
			return true;
		}
        else if( szKey == "master" ) // Obsoleto
		{
            m_slMaster = szValue;
			return true;
		}
        else if( szKey == "killtarget" )
		{
            m_slKillTarget = szValue;
			return true;
		}
		else 
			return BaseClass.KeyValue( szKey, szValue );
    }

	void Spawn() 
	{
        self.Precache();
        g_SoundSystem.PrecacheSound("buttons/blip1.wav");
		g_SoundSystem.PrecacheSound("buttons/blip2.wav");
        g_SoundSystem.PrecacheSound("buttons/button11.wav");

		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_BBOX;

        g_EntityFuncs.SetModel( self, self.pev.model );
        g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( !self.pev.SpawnFlagBitSet( SF_TRIGGER_SCANNER_START_OFF ) )
        {
		    SetThink( ThinkFunction( this.TriggerThink ) );
            self.pev.nextthink = g_Engine.time + 0.1f;
        }

        BaseClass.Spawn();
	}

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.SpawnFlagBitSet( SF_TRIGGER_SCANNER_START_OFF ) && !Activated )
		{	
            Activated = true;
			SetThink( ThinkFunction( this.TriggerThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}
    
	void TriggerThink() 
	{	
        if( Count >= m_ilMaxCount)
        {
            g_Game.AlertMessage(at_console, "Limite del Count : " +m_ilMaxCount+ "\n"); 

			if( m_slKillTarget != "" && m_slKillTarget != self.GetTargetname() )
			{
				do g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, m_slKillTarget ) );
				while( g_EntityFuncs.FindEntityByTargetname( null, m_slKillTarget ) !is null );
			}

            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, "buttons/blip2.wav", VOL_NORM, ATTN_NORM);
			self.SUB_UseTargets( @self, USE_TOGGLE, 0 );
            self.pev.nextthink = 0.0f;
            return;
        }

        CBaseEntity@ pEnt = @FindEntity();// call our entity finding function

        if( pEnt !is null )
        {
            // check it was a player and that they're not dead (don't let dead bodies fall into triggers!)
            if( pEnt.IsAlive() )
            {
                Count++;
                g_Game.AlertMessage(at_console, "El jugador esta a la distancia necesaria para contar |sumando| : " +Count+ "\n"); 
                g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, "buttons/blip1.wav", VOL_NORM, ATTN_NORM);
            }
        }
        else
        {
            if( Count != 0 )
            {
                /*if( Count <= 0 )
                    Count++;
                else  
                    Count--;
                    
                g_Game.AlertMessage(at_console, "El jugador no esta a la distancia necesaria para contar |restando| : " +Count+ "\n"); 
                */
                
                Count = 0;

                g_Game.AlertMessage(at_console, "El jugador no esta a la distancia necesaria para contar |reseteado| : " +Count+ "\n"); 
                g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, "buttons/button11.wav", VOL_NORM, ATTN_NORM);
            }
        }

		self.pev.nextthink = g_Engine.time + 1.0f;// por segundo
	}

    CBaseEntity@ FindEntity()
    {
        CBaseEntity@ pEntity = null;

        // run through all the entities in a sphere (size set by radius in hammer)
        while (( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, self.Center(), m_flRadius, "*", "classname" ) ) !is null)
        {
            // and return then if they're clients
            if ( FBitSet( pEntity.pev.flags, self.pev.SpawnFlagBitSet( SF_TRIGGER_SCANNER_START_OFF ) ?  FL_MONSTER : FL_CLIENT ) )
            {
                return @pEntity;
            }
        }

        return @null;// if we don't find any, return NULL
    }

    bool FBitSet( uint iTargetBits, uint iFlags )
    {
        if( ( iTargetBits & iFlags ) != 0 )
            return true;
        else
            return false;
    }
}

void RegisterTriggerScannerEntity() 
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_scanner", "trigger_scanner" );
}