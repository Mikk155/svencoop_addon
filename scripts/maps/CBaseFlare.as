void RegisterBnegal()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CFlare", "item_flare" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_flare", "weapon_flare" );
	g_ItemRegistry.RegisterWeapon( "weapon_flare", "hl_weapons", "weapon_flare", "", "weapon_flare" );
}

class CFlare : ScriptBaseMonsterEntity
{
	private CScheduledFunction@ FlareLightSchedule = null;
	private CScheduledFunction@ FlareSmokeSchedule = null;

	void Spawn()
	{
		Precache();
		
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetModel( self, "models/w_flare.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		FlareOn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/w_flare.mdl" );
        g_Game.PrecacheGeneric( "models/w_flare.mdl" );
		
		g_Game.PrecacheModel( "sprites/steam1.spr" );
        g_Game.PrecacheGeneric( "sprites/steam1.spr" );
	}

	void FlareOn()
	{
		g_Scheduler.SetTimeout( @this, "UpdateOnRemove", 62.0f );
		@FlareSmokeSchedule = @g_Scheduler.SetInterval( @this, "FlareSmoke", 2.5f, g_Scheduler.REPEAT_INFINITE_TIMES );
		@FlareLightSchedule = @g_Scheduler.SetInterval( @this, "FlareLight", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
	}
	
	void FlareOff()
	{
		g_Scheduler.RemoveTimer( FlareSmokeSchedule );
		@FlareSmokeSchedule = @null;

		g_Scheduler.RemoveTimer( FlareLightSchedule );
		@FlareLightSchedule = @null;
	}

    void FlareSmoke()
    {
		NetworkMessage FlareSmoke( MSG_ALL, NetworkMessages::SVC_TEMPENTITY, null );
            FlareSmoke.WriteByte( TE_SMOKE );
            FlareSmoke.WriteCoord( self.Center().x );
            FlareSmoke.WriteCoord( self.Center().y );
            FlareSmoke.WriteCoord( self.Center().z );
            FlareSmoke.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
            FlareSmoke.WriteByte( 15 );
            FlareSmoke.WriteByte( 5 );
        FlareSmoke.End();
	}

	void FlareLight()
	{
		NetworkMessage Flare( MSG_ALL, NetworkMessages::SVC_TEMPENTITY, null );
			Flare.WriteByte( TE_DLIGHT );
			Flare.WriteCoord( self.Center().x );
			Flare.WriteCoord( self.Center().y );
			Flare.WriteCoord( self.Center().z + 180 );
			Flare.WriteByte( 25 ); //Radius
			Flare.WriteByte( 255 ); //R
			Flare.WriteByte( 0 ); //G
			Flare.WriteByte( 0 ); //B
			Flare.WriteByte( 1 ); //Life
			Flare.WriteByte( 0 ); //Decay
		Flare.End();
    }

	void Touch( CBaseEntity@ pOther )
	{
		// don't hit the guy that launched this grenade
		if ( pOther.edict() is self.pev.owner )
			return;

		if( (pev.flags & FL_ONGROUND) != 0 )
		{
			// add a bit of static friction
			self.pev.velocity = self.pev.velocity * 0.8f;

			self.pev.sequence = Math.RandomLong(1, 1);
		}

		self.pev.framerate = self.pev.velocity.Length() / 200.0f;

		if( self.pev.framerate > 1.0f ) self.pev.framerate = 1;
		else if( self.pev.framerate < 0.5f ) self.pev.framerate = 0;
	}

	void Think()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
			
		if( pev.waterlevel != WATERLEVEL_DRY )
		{
			self.pev.velocity = self.pev.velocity * 0.5f;
			self.pev.framerate = 0.2f;
		}

		self.StudioFrameAdvance();
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void UpdateOnRemove()
	{
		FlareOff();
	}
}

CFlare@ CreateFlare( entvars_t@ pevOwner, Vector& in vecStart, Vector& in vecVelocity )
{
	CBaseEntity@ pre_pFlare = g_EntityFuncs.CreateEntity( "item_flare", null, false );
	CFlare@ pFlare = cast<CFlare@>(CastToScriptClass(pre_pFlare));
	
	pFlare.Spawn();
	
	pFlare.pev.origin = vecStart;
	pFlare.pev.velocity = vecVelocity;
	g_EngineFuncs.VecToAngles( pFlare.pev.velocity, pFlare.pev.angles );
	
	CBaseEntity@ pOwner = g_EntityFuncs.Instance( pevOwner );
	@pFlare.pev.owner = @pOwner.edict();

	pFlare.pev.sequence = Math.RandomLong( 3, 6 );
	pFlare.pev.framerate = 1.0;
	
	pFlare.pev.gravity = 0.5;
	pFlare.pev.friction = 0.8;
	
	return pFlare;
}

enum hlw_e
{
	ANIM_IDLE = 0,
	ANIM_FIDGET,
	ANIM_PINPULL,
	ANIM_THROW1,	// toss
	ANIM_THROW2,	// medium
	ANIM_THROW3,	// hard
	ANIM_HOLSTER,
	ANIM_DRAW
};

class weapon_flare : ScriptBasePlayerWeaponEntity
{
	private float m_flStartThrow;
	private float m_flReleaseThrow;
	private CBasePlayer@ pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, self.GetW_Model("models/w_grenade.mdl") );
		self.m_iDefaultAmmo = 1;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/w_grenade.mdl" );
		g_Game.PrecacheModel( "models/v_grenade.mdl" );
		g_Game.PrecacheModel( "models/p_grenade.mdl" );

		g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );

		g_Game.PrecacheOther( "item_flare" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@pPlayer = pPlayer;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		return true;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 5;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
		info.iPosition = 9;
		info.iWeight = 6;
		info.iFlags = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;

		return true;
	}

	void Touch( CBaseEntity@ pOther ) 
	{
		if( !pOther.IsPlayer() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if( pPlayer.HasNamedPlayerItem("weapon_flare") !is null )
		{
	  		if( pPlayer.GiveAmmo(1, "weapon_flare", 5) != -1 )
			{
				self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );

				g_EntityFuncs.Remove( self );
	  		}

	  		return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
	  		self.AttachToPlayer( pPlayer );
	  		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
		}
	}

	bool Deploy()
	{
		m_flReleaseThrow = -1;
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/v_grenade.mdl"), self.GetP_Model("models/p_grenade.mdl"), ANIM_DRAW, "crowbar" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			return bResult;
		}
	}

	bool CanHolster()
	{
		// can only holster hand grenades when not primed!
		return (m_flStartThrow == 0);
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		pPlayer.m_flNextAttack = g_Engine.time + 0.5;
		self.SendWeaponAnim( ANIM_HOLSTER );
		
		m_flStartThrow = 0;
		m_flReleaseThrow = -1;
	}

	void InactiveItemPostFrame()
	{
		if ( pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
		{
			self.DestroyItem();
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void PrimaryAttack()
	{
		if ( m_flStartThrow == 0 && pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
		{
			m_flStartThrow = g_Engine.time;
			m_flReleaseThrow = 0;
			
			self.SendWeaponAnim( ANIM_PINPULL );
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
		}
	}

	void WeaponIdle()
	{
		if( m_flReleaseThrow == 0 and m_flStartThrow > 0 )
			 m_flReleaseThrow = g_Engine.time;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_flStartThrow > 0 )
		{
			Vector angThrow = pPlayer.pev.v_angle + pPlayer.pev.punchangle;

			if( angThrow.x < 0 )
				angThrow.x = -10 + angThrow.x * ((90 - 10) / 90.0f);
			else
				angThrow.x = -10 + angThrow.x * (( 90 + 10) / 90.0f);

			float flVel = (90 - angThrow.x) * 4;
			if( flVel > 500 )
				flVel = 500;

			Math.MakeVectors( angThrow );

			Vector vecSrc = pPlayer.pev.origin + pPlayer.pev.view_ofs + g_Engine.v_forward * 16;

			Vector vecThrow = g_Engine.v_forward * flVel + pPlayer.pev.velocity;

			CreateFlare( pPlayer.pev, vecSrc, vecThrow );

			if( flVel < 500 )
				self.SendWeaponAnim( ANIM_THROW1 );
			else if( flVel < 1000 )
				self.SendWeaponAnim( ANIM_THROW2 );
			else
				self.SendWeaponAnim( ANIM_THROW3 );

			// player "shoot" animation
			pPlayer.SetAnimation( PLAYER_ATTACK1 );

			m_flReleaseThrow = 0;
			m_flStartThrow = 0;
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5f; //GetNextAttackDelay
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f; //UTIL_WeaponTimeBase

			pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

			if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			{
				// just threw last grenade
				// set attack times in the future, and weapon idle in the future so we can see the whole throw
				// animation, weapon idle will automatically retire the weapon for us.
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;// ensure that the animation can finish playing
			}

			return;
		}
		else if( m_flReleaseThrow > 0 )
		{
			// we've finished the throw, restart.
			m_flStartThrow = 0;

			if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
			{
				self.SendWeaponAnim( ANIM_DRAW );
			}
			else
			{
				self.RetireWeapon();
				return;
			}

			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( pPlayer.random_seed, 10, 15 );
			m_flReleaseThrow = -1;
			return;
		}

		if( pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			int iAnim;
			float flRand = g_PlayerFuncs.SharedRandomFloat( pPlayer.random_seed, 0, 1 );
			if( flRand <= 0.75 )
			{
				iAnim = ANIM_IDLE;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( pPlayer.random_seed, 10, 15 );// how long till we do this again.
			}
			else 
			{
				iAnim = ANIM_FIDGET;
				self.m_flTimeWeaponIdle = g_Engine.time + 75.0f / 30.0f;
			}

			self.SendWeaponAnim( iAnim );
		}
	}	
}