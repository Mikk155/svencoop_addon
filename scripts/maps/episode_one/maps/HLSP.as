#include "../../point_checkpoint"
#include "../../HLSPClassicMode"

// Create the vote
const string EntFileLoad = "episode_one/store/" + string( g_Engine.mapname ) + ".ent";

void MapInit()
{
	RegisterPointCheckPointEntity();
	
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 0 );
	
	ClassicModeMapInit();
}

void MapActivate()
{
	CBaseEntity@ pEntity = null;

	if( !g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		g_EngineFuncs.ServerPrint( "Can't open " + EntFileLoad + ". Can't play 'Half-Life: Episode-One' campaign.\n" );
	}
	else
	{
		// Rename Changelevel entity.
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			edict_t@ pEdict = pEntity.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "changelevel_voted" );
		}
		// Rename Gman's entities
		while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "start_train_mm" ) ) !is null )
		{
			edict_t@ pEdict = pEntity.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "start_loser_mm", "NullPointer_DoNothing" );
		}
	}
}