// Multi-Language script/plugin
#include "../../multi_language/multi_language"

// Anti-Rush entity
#include "../entity/trigger_once_mp"
#include "../entity/func_fakewall"

// func_autosave
#include "../entity/func_autosave"

// HLSP AMMUNITION
#include "../misc/ammo_individual"

void MapInit()
{
	// Multi-Language script/plugin
	MultiLanguageInit();
	
	// Anti-Rush entity
	RegisterTriggerOnceMpEntity();
	RegisterFakeWall();
	
	// func_autosave
	RegisterTriggerPlayerSaveFunc();
	
	// HLSP AMMUNITION
	RegisterAmmoIndividual();
}

void MapActivate()
{
	// Multi-Language script/plugin
	MultiLanguageActivate();
	
	// HLSP AMMUNITION
	AmmoIndividualRemap();
}