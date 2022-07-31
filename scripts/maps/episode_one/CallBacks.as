/* ====================================================================================== */
/*
	CallBack for trolling players
	
	mode: Think
*/
/* ====================================================================================== */
void pPlayersFlashlight(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
{
	for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		if( pPlayer.m_iFlashBattery >= 30)
		{
			pPlayer.m_iFlashBattery = 29;
		}
		if( pPlayer.FlashlightIsOn() )
		{
			pPlayer.FlashlightTurnOff();
			pPlayer.m_iFlashBattery = 1;
		}
		if( pPlayer.pev.armorvalue < pPlayer.pev.armortype )
		{
			pPlayer.pev.armorvalue = pPlayer.pev.armorvalue - 3;
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "fvox/hev_critical_fail.wav", 1.0f, 1.0f, 0, PITCH_NORM );
		}
		
	}

}
/* ====================================================================================== */
/*
	CallBack for spawning enemies around players. used in nihilanth's battle
	
	Code by Rick: https://github.com/RedSprend/svencoop_plugins/blob/master/svencoop/scripts/plugins/atele.as
	
	mode: Think
*/
/* ====================================================================================== */
void n_CallMonsters( CBaseEntity@ ){
	int iPlayerIndex = GetRandomPlayer();
	if( iPlayerIndex == -1)
		return;

	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );

	string szMonster = g_szMonsters[Math.RandomLong(0,g_szMonsters.length() - 1)];

	// TODO: keep some distance away from the player to prevent spawning the monster on (or too close) the player.
	Vector vecSrc = pPlayer.pev.origin;

	Vector vecEnd = vecSrc + Vector(Math.RandomLong(-512,512), Math.RandomLong(-512,512), 0);
	float flDir = Math.RandomLong(-360,360);

	vecEnd = vecEnd + g_Engine.v_right * flDir;

	TraceResult tr;
	g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
	if( tr.flFraction >= 1.0 ){
		CheckFreeSpace( szMonster, vecEnd, pPlayer);
	}
}
array<string> g_szMonsters = {
	"monster_alien_controller",
	"monster_alien_grunt",
	"monster_alien_slave"
};
void CheckFreeSpace( const string& in szClassname, Vector& in vecOrigin, CBaseEntity@ pPlayer ){
	TraceResult tr;
	HULL_NUMBER hullCheck = human_hull;
	
		hullCheck = head_hull;

	g_Utility.TraceHull( vecOrigin, vecOrigin, dont_ignore_monsters, hullCheck, pPlayer.edict(), tr );

	if( tr.fAllSolid == 1 || tr.fStartSolid == 1 || tr.fInOpen == 0 ){
		// Obstructed! Try again
		return;
	}
	else{
		// All clear! Spawn here
		CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( szClassname, null, true );
		if( pEntity !is null ){
			CreateSpawnEffect( szClassname, vecOrigin, EHandle(pPlayer) );
		}
		return;
	}
}
void CreateSpawnEffect( const string& in szClassname, Vector& in vecOrigin, EHandle hPlayer ){
	if( !hPlayer.IsValid() )
		return;

	int iBeamCount = 8;
	Vector vBeamColor = Vector(30, 150, 50);//Vector(217,226,146);
	int iBeamAlpha = 128;
	float flBeamRadius = 256;

	Vector vLightColor = Vector(39,209,137);
	float flLightRadius = 160;

	Vector vStartSpriteColor = Vector(65,209,61);
	float flStartSpriteScale = 1.0f;
	float flStartSpriteFramerate = 12;
	int iStartSpriteAlpha = 255;

	Vector vEndSpriteColor = Vector(159,240,214);
	float flEndSpriteScale = 1.0f;
	float flEndSpriteFramerate = 12;
	int iEndSpriteAlpha = 255;

	// create the clientside effect
	NetworkMessage msg( MSG_PVS, NetworkMessages::TE_CUSTOM, vecOrigin );
		msg.WriteByte( 2 );
		msg.WriteVector( vecOrigin );
		// for the beams
		msg.WriteByte( iBeamCount );
		msg.WriteVector( vBeamColor );
		msg.WriteByte( iBeamAlpha );
		msg.WriteCoord( flBeamRadius );
		// for the dlight
		msg.WriteVector( vLightColor );
		msg.WriteCoord( flLightRadius );
		// for the sprites
		msg.WriteVector( vStartSpriteColor );
		msg.WriteByte( int( flStartSpriteScale*10 ) );
		msg.WriteByte( int( flStartSpriteFramerate ) );
		msg.WriteByte( iStartSpriteAlpha );

		msg.WriteVector( vEndSpriteColor );
		msg.WriteByte( int( flEndSpriteScale*10 ) );
		msg.WriteByte( int( flEndSpriteFramerate ) );
		msg.WriteByte( iEndSpriteAlpha );
	msg.End();
	
	g_Scheduler.SetTimeout( "SpawnMonster", 0.8f, szClassname, vecOrigin, hPlayer );
}
void SpawnMonster( const string& in szClassname, Vector& in vecOrigin, EHandle hPlayer ){
	if( !hPlayer.IsValid() )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>(hPlayer.GetEntity());
	if( pPlayer is null )
		return;

	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( szClassname, null, true );
	if( pEntity !is null ){
		g_EntityFuncs.SetOrigin( pEntity, vecOrigin );
		Vector vecAngles = Math.VecToAngles( pPlayer.pev.origin - pEntity.pev.origin );
		pEntity.pev.angles.y = vecAngles.y;
	}
}
int GetRandomPlayer() {
	int[] iPlayer(g_Engine.maxClients + 1);
	int iPlayerCount = 0;
	for( int i = 1; i <= g_Engine.maxClients; i++ ){
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() || (pPlayer.pev.flags & FL_FROZEN) != 0 )
			continue;

		iPlayer[iPlayerCount] = i;
		iPlayerCount++;
	}
	return (iPlayerCount == 0) ? -1 : iPlayer[Math.RandomLong(0,iPlayerCount-1)];
}

void CallBacksInitialize()
{
	for( uint i = 0; i < g_szMonsters.length(); i++ )
	{
		g_Game.PrecacheMonster( g_szMonsters[i], false );
		g_Game.PrecacheMonster( g_szMonsters[i], true );
	}
}