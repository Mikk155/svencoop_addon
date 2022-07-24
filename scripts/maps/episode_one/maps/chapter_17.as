// Read current map .ent localization script.
const string EntFileLoad = "multi_language/localizations/" + string( g_Engine.mapname ) + ".ent";

// Count players and enable survival.
#include "../misc/player_count"

// Checkpoints & Player's lives
#include "../entity/game_save"

// BMS-like recharge crystals
#include "../entity/env_hurtzone"

// Trigger when in/out
#include "../entity/trigger_inout"

// Multi-Language game_text entity.
#include "../entity/game_text_custom"

// HLSP AMMUNITION
#include "../entity/ammo_individual"

// Solid zone that trigger something when player press a button
#include "../entity/zone_caller"

// trigger per percentage of players specified.
#include "../entity/trigger_once_mp"

// Precache and things
#include "../CallBacks"

void MapInit()
{
	InitializePlayersCount();
	RegisterTriggerAutoSave();
	RegisterEnvHurtZone();
	RegisterTriggerInOut();
	RegisterCustomTextGame();
	RegisterAmmoIndividual();
	RegisterZoneCaller();
	RegisterAntiRushEntity();
	CallBacksInitialize();
}

void MapActivate()
{
	if( !g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		g_EngineFuncs.ServerPrint( "Can't open multi-language script file " + EntFileLoad + "\n" );
	}
}