//
// Author: Gaftherman
// Taken and ported from: https://github.com/SamVanheer/halflife-updated/blob/master/dlls/rat.cpp
//
// ===================================
//
// Why is this here?
// 1.- I use it as a base to create enemies.
// 2.- Do not really expect more point for which I stand out because I did it.
//
// Usage: In your map script include this
//	#include "../monster_rat_custom"
// and in your MapInit() {...}
//	"MonsterNihilanth::Register();"
//
// ===================================
//

namespace MonsterNihilanth
{
	//=========================================================
	// Monster's Anim Events Go Here
	//=========================================================

	class CNihilanth : ScriptBaseMonsterEntity
	{
		//=========================================================
		// Classify - indicates this monster's place in the 
		// relationship table.
		//=========================================================
		int	Classify()
		{
			return	self.GetClassification( CLASS_ALIEN_MILITARY );
		}

		//=========================================================
		// SetYawSpeed - allows each sequence to have a different
		// turn rate associated with it.
		//=========================================================
		void SetYawSpeed()
		{
			int ys;

			switch ( self.m_Activity )
			{
				case ACT_IDLE:

				default: ys = 45; break;
			}

			self.pev.yaw_speed = ys;
		}

		//=========================================================
		// Spawn
		//=========================================================
		void Spawn()
		{
			Precache( );

			g_EntityFuncs.SetModel( self, "models/nihilanth.mdl");
			g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, 0 ), Vector( 32, 32, 64 ) );

			pev.solid				= SOLID_BBOX;
			pev.movetype			= MOVETYPE_FLY;
			pev.flags 				!= FL_MONSTER;
			pev.view_ofs			= Vector ( 0, 0, 300 );	// position of the eyes relative to monster's origin.
			pev.takedamage			= DAMAGE_AIM;
			
			self.m_bloodColor		= BLOOD_COLOR_YELLOW;
			self.m_FormattedName	= "Nihilanth";
			self.m_flFieldOfView	= -1;	// 360 degrees
			
			if( self.pev.health != "" )
			{
				self.pev.health += int(g_EngineFuncs.CVarGetFloat( "sk_nihilanth_health" ));
			}
			
			
			self.m_MonsterState		= MONSTERSTATE_NONE;


			self.MonsterInit();
		}

		//=========================================================
		// Precache - precaches all resources this monster needs
		//=========================================================
		void Precache()
		{
			g_Game.PrecacheModel("models/nihilanth.mdl");
			g_Game.PrecacheGeneric( "models/nihilanth.mdl" );
			
			g_Game.PrecacheModel("sprites/lgtning.spr");
			g_Game.PrecacheGeneric( "sprites/lgtning.spr" );
			
			g_Game.PrecacheOther( "nihilanth_energy_ball" );
			g_Game.PrecacheOther( "monster_alien_controller" );
			g_Game.PrecacheOther( "monster_alien_slave" );
			
			g_SoundSystem.PrecacheSound( "debris/beamstart7.wav" );
			g_Game.PrecacheGeneric( "debris/beamstart7.wav" );
		}	

		//=========================================================
		// AI Schedules Specific to this monster
		//=========================================================
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("MonsterNihilanth::CNihilanth", "monster_nihilanth_custom");
	}
}