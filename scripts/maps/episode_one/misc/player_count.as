float flSurvivalStartDelay = g_EngineFuncs.CVarGetFloat( "mp_survival_startdelay" );

void InitializePlayersCount()
{
	g_SurvivalMode.Disable();
	g_Scheduler.SetTimeout( "SurvivalModeEnable", flSurvivalStartDelay );
}

void SurvivalModeEnable()
{
	CBaseEntity@ pEntity = null;
	while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "players_" + string(g_PlayerFuncs.GetNumPlayers()))) !is null)
	{
		g_EntityFuncs.FireTargets( "players_" + g_PlayerFuncs.GetNumPlayers(), null, null, USE_ON, 0.0f, 0.0f );
	}

	if( g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1 )
	{
		g_SurvivalMode.Activate( true );
	}
	
	g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 1 );
}