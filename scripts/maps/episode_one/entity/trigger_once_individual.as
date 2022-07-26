void RegisterTOnceIndividual()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_once_individual", "trigger_once_individual" );
}

enum trigger_once_flag
{
    SF_TOI_START_OFF = 1 << 0
}

class trigger_once_individual : ScriptBaseEntity
{
    dictionary g_Players;
    
    void Spawn()
    {
        self.pev.movetype     = MOVETYPE_NONE;
        self.pev.solid         = SOLID_TRIGGER;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        g_EntityFuncs.SetModel( self, self.pev.model );
        g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        
        if( !self.pev.SpawnFlagBitSet( SF_TOI_START_OFF ) )
            SetTouchFunction( TouchFunction( this.TriggerTouch ) );

        BaseClass.Spawn();
    }
    
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) 
    {
        if( self.pev.SpawnFlagBitSet( SF_TOI_START_OFF ) )
        {    
            SetTouchFunction( TouchFunction( this.TriggerTouch ) );
        }
    }

    void Touch( CBaseEntity@ pOther )
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            return;

        string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        if( !g_Players.exists(SteamID) )
        {
            self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0.0f );

            g_Players[SteamID];
        }
    }
}