#include "utils"

namespace GamePlayerHudSprite {

	enum X_POS_TYPES {
		X_RELATIVE_LEFT,
		X_RELATIVE_RIGHT,
		X_RELATIVE_CENTER,
		X_ABSOLUTE_LEFT,
		X_ABSOLUTE_RIGHT,
		X_ABSOLUTE_CENTER
	}

	enum Y_POS_TYPES {
		Y_RELATIVE_TOP,
		Y_RELATIVE_BOTTOM,
		Y_RELATIVE_CENTER,
		Y_ABSOLUTE_TOP,
		Y_ABSOLUTE_BOTTOM,
		Y_ABSOLUTE_CENTER
	}
	
	enum SPAWN_FLAGS {
		FL_ALL_PLAYERS = 1
	}

	// Flags that are controlled by a keyvalue other than spawnflags
	const int SPAWN_FLAGS_MASK = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;

	class game_player_hud_sprite : ScriptBaseEntity
	{
		int channel;
		string spritePath;
		uint8 top;
		uint8 left;
		int16 width; // Range: 0-512 (0 = auto)
		int16 height; // Range: 0-512 (0 = auto)
		float x;
		float y;
		RGBA color1;
		RGBA color2;
		uint8 numframes;
		float framerate;
		float fadeInTime;
		float fadeOutTime;
		float holdTime;
		float fxTime;
		uint8 effect;
		
		uint flags;
		bool invertX = false;
		bool invertY = false;
		bool allPlayers = false;
		
		bool KeyValue( const string& in szKey, const string& in szValue )
		{	
			if (szKey == "channel") channel = atoi(szValue);
			else if (szKey == "spritePath") spritePath = szValue;
			else if (szKey == "region") {
				array<string> values = szValue.Split(" ");
				if (values.length() > 0) left = atoi( values[0] );
				if (values.length() > 1) top = atoi( values[1] );
				if (values.length() > 2) width = atoi( values[2] );
				if (values.length() > 3) height = atoi( values[3] );
			}
			else if (szKey == "numframes") numframes = atoi(szValue);
			else if (szKey == "fadein") fadeInTime = atof(szValue);
			else if (szKey == "fadeout") fadeOutTime = atof(szValue);
			else if (szKey == "holdtime") holdTime = atof(szValue);
			else if (szKey == "effecttime") fxTime = atof(szValue);
			else if (szKey == "effect") effect = atoi(szValue);
			else if (szKey == "x") x = atof(szValue);
			else if (szKey == "y") y = atof(szValue);
			else if (szKey == "xtype") {
				flags &= ~(HUD_ELEM_ABSOLUTE_X | HUD_ELEM_SCR_CENTER_X);
				invertX = false;
				switch(atoi(szValue)) {
					case X_RELATIVE_LEFT:   break;
					case X_RELATIVE_RIGHT:  invertX = true; break;
					case X_RELATIVE_CENTER: flags |= HUD_ELEM_SCR_CENTER_X; break;
					case X_ABSOLUTE_LEFT:   flags |= HUD_ELEM_ABSOLUTE_X; break;
					case X_ABSOLUTE_RIGHT:  invertX = true; flags |= HUD_ELEM_ABSOLUTE_X; break;
					case X_ABSOLUTE_CENTER: invertX = true; flags |= HUD_ELEM_SCR_CENTER_X | HUD_ELEM_ABSOLUTE_X; break;
				}
			}
			else if (szKey == "ytype") {
				flags &= ~(HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y);
				invertY = false;
				switch(atoi(szValue)) {
					case Y_RELATIVE_TOP:   break;
					case Y_RELATIVE_BOTTOM: invertY = true; break;
					case Y_RELATIVE_CENTER: flags |= HUD_ELEM_SCR_CENTER_Y; break;
					case Y_ABSOLUTE_TOP:    flags |= HUD_ELEM_ABSOLUTE_Y; break;
					case Y_ABSOLUTE_BOTTOM: invertY = true; flags |= HUD_ELEM_ABSOLUTE_Y; break;
					case Y_ABSOLUTE_CENTER: invertY = true; flags |= HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_ABSOLUTE_Y; break;
				}
			}
			else if (szKey == "color1") color1 = UtilEnts::parseRgba(szValue);
			else if (szKey == "color2") color2 = UtilEnts::parseRgba(szValue);
			else return BaseClass.KeyValue( szKey, szValue );
			
			return true;
		}
		
		void Spawn()
		{
			Precache();
		}
		
		void Precache()
		{
			if (spritePath.Length() > 0)
				g_Game.PrecacheModel(spritePath);
		}
		
		void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
		{
			array<CBaseEntity@> targets;
			
			// calculating flags here since KeyValue ignores 'spawnflags'
			int sflags = self.pev.spawnflags;
			flags = (flags & SPAWN_FLAGS_MASK) | (sflags & ~SPAWN_FLAGS_MASK);
			allPlayers = sflags & FL_ALL_PLAYERS != 0;
			
			if (allPlayers) {
				CBaseEntity@ ent = null;
				do {
					@ent = g_EntityFuncs.FindEntityByClassname(ent, "player"); 
					if (ent !is null)
					{
						targets.insertLast(ent);
					}
				} while (ent !is null);
			}
			else {
				targets = UtilEnts::getTargetsByName(pActivator, pCaller, self.pev.target);
			}
			
			for (uint i = 0; i < targets.size(); i++) {
				CBasePlayer@ plr = cast<CBasePlayer@>(targets[i]);
				
				if (plr is null or !plr.IsConnected())
					continue;

				if (useType == USE_OFF) {
					g_PlayerFuncs.HudToggleElement(plr, channel, false);
					continue;
				}
				
				HUDSpriteParams params;
				params.channel = channel;
				params.flags = flags;
				params.spritename = spritePath;
				params.left = left;
				params.top = top;
				params.width = width;
				params.height = height;
				params.x = invertX ? -x : x;
				params.y = invertY ? -y : y;
				params.color1 = color1;
				params.color2 = color2;
				params.frame = int(self.pev.frame);
				params.numframes = numframes;
				params.framerate = self.pev.framerate;
				params.fadeinTime = fadeInTime;
				params.fadeoutTime = fadeOutTime;
				params.holdTime = holdTime;
				params.fxTime = fxTime;
				params.effect = effect;
				
				g_PlayerFuncs.HudCustomSprite(plr, params);
			}
		}

	};

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "GamePlayerHudSprite::game_player_hud_sprite", "game_player_hud_sprite" );
	}
}