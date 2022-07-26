namespace CXenTree
{
    EHandle TriggerCreate( edict_t@ pOwner, const Vector position )
    {
        CBaseEntity@ pTrigger = g_EntityFuncs.CreateEntity( "xen_ttrigger", null, false);

        g_EntityFuncs.SetSize(pTrigger.pev, Vector( -24, -24, 0 ), Vector( 24, 24, 128 ));
        pTrigger.pev.origin = position;
        pTrigger.pev.solid = SOLID_TRIGGER;
        pTrigger.pev.movetype = MOVETYPE_NONE;
        @pTrigger.pev.owner = pOwner;

        return pTrigger;
    }

    const int TREE_AE_ATTACK = 1;

    const array<string> pAttackHitSounds =
    {
        "zombie/claw_strike1.wav",
        "zombie/claw_strike2.wav",
        "zombie/claw_strike3.wav"
    };

    const array<string> pAttackMissSounds =
    {
        "zombie/claw_miss1.wav",
        "zombie/claw_miss2.wav"
    };


    class xen_custom_tree : ScriptBaseMonsterEntity
    {
        EHandle m_pTrigger;

        void Spawn()
        {
            Precache();

            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_BBOX;
            self.pev.takedamage = DAMAGE_YES;

            if(string(self.pev.model).IsEmpty()) 
                g_EntityFuncs.SetModel(self, "models/tree.mdl");
            else 
                g_EntityFuncs.SetModel(self, self.pev.model);

            g_EntityFuncs.SetOrigin(self, self.pev.origin);

            g_EntityFuncs.SetSize(self.pev, Vector(-30,-30,0), Vector(30,30,188));

            self.SetActivity( ACT_IDLE );
            self.pev.nextthink = g_Engine.time + 0.1;
            self.pev.frame = Math.RandomLong(0,255);
            self.pev.framerate = Math.RandomFloat(0.7,1.4);

            Vector triggerPosition;
            Vector Unused;
            g_EngineFuncs.AngleVectors( self.pev.angles, triggerPosition, Unused, Unused );
            triggerPosition = self.pev.origin + (triggerPosition * 64);
            // Create the trigger
            m_pTrigger = TriggerCreate( self.edict(), triggerPosition );
        }

        void Precache( void )
        {
            if( string(self.pev.model).IsEmpty() )
            {
                g_Game.PrecacheModel("models/tree.mdl");
            }
            else
            {
                g_Game.PrecacheModel(self.pev.model); 
            }

            for(uint i = 0; i < pAttackHitSounds.length();i++)
            {
                g_SoundSystem.PrecacheSound(pAttackHitSounds[i]);
            }

            for(uint i = 0; i < pAttackMissSounds.length();i++)
            {
                g_SoundSystem.PrecacheSound(pAttackMissSounds[i]);
            }

            BaseClass.Precache();
        }

        void Touch(CBaseEntity@ pOther)
        {
            if( !pOther.IsPlayer() && pOther.pev.classname == "monster_bigmomma")
                return;

            Attack();
        }

        void Attack()
        {
            if( self.m_Activity == ACT_IDLE )
            {
                self.SetActivity( ACT_MELEE_ATTACK1 );
                self.pev.framerate = Math.RandomFloat(1.0,1.4);
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, pAttackMissSounds[Math.RandomLong(0,pAttackMissSounds.length()-1)], 1.0, ATTN_NORM, 0, Math.RandomLong(95,105)); 
            }
        }

        int Classify()
        {
            return CLASS_BARNACLE;
        }

        void HandleAnimEvent( MonsterEvent@ pEvent )
        {
            switch( pEvent.event )
            {
                case TREE_AE_ATTACK:
                {    
                    bool sound = false;
                    array<EHandle> pList = Inside();

                    Vector forward;
                    Vector Unused;
                    g_EngineFuncs.AngleVectors( self.pev.angles, forward, Unused, Unused );

                    for( uint i = 0; i < pList.length(); ++i )
                    {
                        if( pList[i].GetEntity() !is null )
                        {
                            sound = true;
                            pList[i].GetEntity().TakeDamage( self.pev, self.pev, 25, DMG_CRUSH | DMG_SLASH );
                            pList[i].GetEntity().pev.punchangle.x = 15;
                            pList[i].GetEntity().pev.velocity = pList[i].GetEntity().pev.velocity + forward * 100;
                        }
                    }
                    
                    if( sound )
                    {
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, pAttackHitSounds[Math.RandomLong(0,pAttackHitSounds.length()-1)], 1.0, ATTN_NORM, 0, Math.RandomLong(95,105)); 
                    }
                }
                return;
            }

            BaseClass.HandleAnimEvent( pEvent );
        }

        int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
        {
            CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );

            if( pAttacker.IsPlayer() && pAttacker.pev.classname != "monster_bigmomma")
            {
                Attack();
            }
                
            return 0;
        }

        void Think()
        {
            float flInterval = self.StudioFrameAdvance();
            self.pev.nextthink = g_Engine.time + 0.1;
            self.DispatchAnimEvents( flInterval );

            switch(self.m_Activity)
            {
                case ACT_IDLE: break;

                case ACT_MELEE_ATTACK1:
                {
                    if( self.m_fSequenceFinished )
                    {
                        self.SetActivity( ACT_IDLE );
                        self.pev.framerate = Math.RandomFloat(0.6,1.4);
                    }
                    break;
                }
                default:
            }
        }

        array<EHandle> Inside()
        {
            array<CBaseEntity@> P_ENTITIES( 8 );
            int iNumEntities = g_EntityFuncs.Instance( 0 ).FindMonstersInWorld( @P_ENTITIES, FL_CLIENT | FL_MONSTER );

            array<EHandle> H_ENTITIES_INZONE;

            for( uint i = 0; i < P_ENTITIES.length(); i++ )
            {
                if( P_ENTITIES[i] is null || !P_ENTITIES[i].IsAlive() )
                    continue;

                if( EntitiesInside( P_ENTITIES[i] ) )
                    H_ENTITIES_INZONE.insertLast( EHandle( P_ENTITIES[i] ) );
            }

            return H_ENTITIES_INZONE;
        }

        bool EntitiesInside(EHandle hEntity)
        {
            if( !hEntity )
                return false;

            bool a = hEntity.GetEntity().pev.origin.x + hEntity.GetEntity().pev.maxs.x >= m_pTrigger.GetEntity().pev.origin.x + m_pTrigger.GetEntity().pev.mins.x;
            a = a && hEntity.GetEntity().pev.origin.y + hEntity.GetEntity().pev.maxs.y >= m_pTrigger.GetEntity().pev.origin.y + m_pTrigger.GetEntity().pev.mins.y;
            a = a && hEntity.GetEntity().pev.origin.z + hEntity.GetEntity().pev.maxs.z >= m_pTrigger.GetEntity().pev.origin.z + m_pTrigger.GetEntity().pev.mins.z;
            a = a && hEntity.GetEntity().pev.origin.x + hEntity.GetEntity().pev.mins.x <= m_pTrigger.GetEntity().pev.origin.x + m_pTrigger.GetEntity().pev.maxs.x;
            a = a && hEntity.GetEntity().pev.origin.y + hEntity.GetEntity().pev.mins.y <= m_pTrigger.GetEntity().pev.origin.y + m_pTrigger.GetEntity().pev.maxs.y;
            a = a && hEntity.GetEntity().pev.origin.z + hEntity.GetEntity().pev.mins.z <= m_pTrigger.GetEntity().pev.origin.z + m_pTrigger.GetEntity().pev.maxs.z;

            return a;
        }
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "CXenTree::xen_custom_tree", "xen_custom_tree" );
    }
}