// Count players and enable survival.
#include "../misc/player_count"

// Checkpoints & Player's lives
#include "../hooks/Initsave"

// Debuggin triggers
#include "../debugger"

// BMS-like recharge crystals
#include "../entity/env_hurtzone"

// Trigger when in/out
#include "../entity/trigger_inout"

// Multi-Language game_text entity.
#include "../../multi_language/multi_language"

// HLSP AMMUNITION
#include "../entity/ammo_individual"

// Custom motd for information
#include "../entity/game_popup"

// Solid zone that trigger something when player press a button
#include "../entity/zone_caller"

void MapInit()
{
	InitializePlayersCount();
	TriggerAutoSaveInit();
	RegisterEnvHurtZone();
	RegisterTriggerInOut();
	MultiLanguageInit();
	RegisterAmmoIndividual();
	RegisterGamePopupEntity();
	RegisterZoneCaller();
}

void MapActivate()
{
	MultiLanguageActivate();
	// AmmoIndividualRemap(); dont remap. infiite ammo is in some places.
}