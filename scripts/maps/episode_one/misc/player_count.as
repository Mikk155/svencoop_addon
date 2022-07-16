const bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;

float flSurvivalStartDelay = g_EngineFuncs.CVarGetFloat( "mp_survival_startdelay" );

void RegisterMapInitialize()
{
	g_SurvivalMode.Disable();
	g_Scheduler.SetTimeout( "SurvivalModeEnable", flSurvivalStartDelay );

	g_EngineFuncs.CVarSetFloat( "mp_survival_startdelay", 0 );
	g_EngineFuncs.CVarSetFloat( "mp_survival_starton", 0 );
	g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 0 );
}

void SurvivalModeEnable()
{
	CBaseEntity@ pEntity = null;
	while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "players_" + string(g_PlayerFuncs.GetNumPlayers()))) !is null)
    {
		g_EntityFuncs.FireTargets( "players_" + g_PlayerFuncs.GetNumPlayers(), null, null, USE_ON, 0.0f, 0.0f );
	}
	
    g_SurvivalMode.Activate( true );
    g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 1 );
    NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
    message.WriteString( "spk buttons/bell1" );
    message.End();
}