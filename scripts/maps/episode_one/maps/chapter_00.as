// Checkpoints & Player's lives
#include "../hooks/Initsave"

// BMS-like recharge crystals
#include "../entity/env_hurtzone"

// Trigger when in/out
#include "../entity/trigger_inout"

// Multi-Language game_text entity.
#include "../../multi_language/multi_language"

// HLSP AMMUNITION
#include "../entity/ammo_individual"

void MapInit()
{
	// Checkpoints & Player's lives
	TriggerAutoSaveInit();

	// BMS-like recharge crystals
	RegisterEnvHurtZone();

	// Trigger when in/out
	RegisterTriggerInOut();

	// Multi-Language entity.
	MultiLanguageInit();

	// HLSP AMMUNITION
	RegisterAmmoIndividual();
}

void MapActivate()
{
	// Multi-Language entity.
	MultiLanguageActivate();
	
	// HLSP AMMUNITION
	// AmmoIndividualRemap(); dont remap. infiite ammo in some places.
}