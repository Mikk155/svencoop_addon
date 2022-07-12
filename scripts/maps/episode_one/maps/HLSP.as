#include "../../point_checkpoint"
#include "../../HLSPClassicMode"

// Create the vote
const string EntFileLoad = "episode_one/store/" + string( g_Engine.mapname ) + ".ent";

void MapInit()
{
	RegisterPointCheckPointEntity();
	
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 0 );
	
	ClassicModeMapInit();
	
	CBaseEntity@ pEntity = null;

	if( !g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		g_EngineFuncs.ServerPrint( "Can't open " + EntFileLoad + "\n" );
	}
	else
	{
		// Delete modified entities
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
		// Delete modified entities
		while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "Deleteme" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
	}
}