// Read current map .ent localization script.
const string EntFileLoad = "multi_language/localizations/" + string( g_Engine.mapname ) + ".ent";

// Multi-Language game_text entity.
#include "../../multi_language/game_text_custom"

void MapInit()
{
	RegisterCustomTextGame();
}

void MapActivate()
{
	if( !g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		g_EngineFuncs.ServerPrint( "Can't open multi-language script file " + EntFileLoad + "\n" );
	}
}