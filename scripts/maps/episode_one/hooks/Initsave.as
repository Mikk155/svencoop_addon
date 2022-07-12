#include "../entity/game_save"

void TriggerAutoSaveInit()
{
	RegisterTriggerGameSave();

	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
}

dictionary g_WhoSpawn;

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ) 
{
	string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	g_Game.AlertMessage( at_console, 'El client se connecto correctamente \n');

	if( g_SurvivalMode.IsActive() && !g_WhoSpawn.exists(SteamID) )
	{
		g_Game.AlertMessage( at_console, 'El surivival esta activado \n');
		g_WhoSpawn[SteamID] = @pPlayer;
		g_Game.AlertMessage( at_console, 'Guardando el SteamID ... \n');

		CBaseEntity@ pFindSpawn = null;
		while((@pFindSpawn = g_EntityFuncs.FindEntityByClassname( pFindSpawn, "info_player_deathmatch" )) !is null )
		{
			g_Game.AlertMessage( at_console, 'Buscando la entidad \n');
			if( pFindSpawn.pev.targetname == "game_player_joined" && pFindSpawn.pev.SpawnFlagBitSet( 2 ) )
			{
				g_Game.AlertMessage( at_console, 'Se encontro la entidad + la condicion \n');
				pPlayer.SetOrigin( pFindSpawn.pev.origin ); //Move the player to the center of the brush
				pPlayer.Revive(); //Revive the player
			}
		}
	}

    return HOOK_CONTINUE;
}