// func_autosave
#include "../entity/func_autosave"

// BMS-like recharge crystals
#include "../entity/env_crystal"

// Multi-Language game_text entity.
#include "../../multi_language/multi_language"

// Anti-Rush entity
#include "../entity/anti_rush"

// HLSP AMMUNITION
#include "../misc/ammo_individual"

void MapInit()
{
	// func_autosave
	RegisterTriggerPlayerSaveFunc();
	
	// BMS-like recharge crystals
	RegisterEnvCrystal();
	
	// Multi-Language entity.
	MultiLanguageInit();
	
	// Anti-Rush entity
	RegisterAntiRushEntity();
	
	// HLSP AMMUNITION
	RegisterAmmoIndividual();
}

void MapActivate()
{
	// Multi-Language entity.
	MultiLanguageActivate();
	
	// HLSP AMMUNITION
	AmmoIndividualRemap();
}