void MapInit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_barnacle", "weapon_barnacle" );
	g_ItemRegistry.RegisterWeapon( "weapon_barnacle", "hl_weapons", "weapon_barnacle", "", "weapon_barnacle" );
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

class weapon_barnacle : ScriptBasePlayerWeaponEntity
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