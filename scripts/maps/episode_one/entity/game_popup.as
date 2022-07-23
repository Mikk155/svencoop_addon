/*  game_popup
by Outerbeast
Entity that creates a custom MOTD popup with title and text
MOTD code by Geigue

When triggered, the activator (if it is a player) will receive the popup on their screen.
Setting flag 1 will make the popup display for all players.

Keys:-
"classname" "game_popup"
"netname" "Title goes here" - Title key
"spawnflags" "1" - All players receive the popup, not just the activator

EDIT-: see how game_text_custom works and use this based on the same method.

"message" "Text goes here" - Main body text key.
"message_spanish". bla bla. etc. etc. same languages -Mikk
*/
void RegisterGamePopupEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "game_popup", "game_popup" );
}

enum EnumLanguage
{
	LANGUAGE_ENGLISH = 0, 
	LANGUAGE_SPANISH,
	LANGUAGE_PORTUGUESE,	
	LANGUAGE_GERMAN,
	LANGUAGE_FRENCH,
	LANGUAGE_ITALIAN,
	LANGUAGE_ESPERANTO	
}

enum EnumSpawnFlags
{
	SF_GP_ALL_PLAYERS = 1 << 0
}

class game_popup : ScriptBaseEntity
{
	private string_t message_spanish, message_portuguese, message_german, message_french, message_italian, message_esperanto;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "message_spanish")
		{
			message_spanish = szValue;
			return true;
		}
		else if(szKey == "message_portuguese")
		{
			message_portuguese = szValue;
			return true;
		}
		else if(szKey == "message_german")
		{
			message_german = szValue;
			return true;
		}
		else if(szKey == "message_french")
		{
			message_french = szValue;
			return true;
		}
		else if(szKey == "message_italian")
		{
			message_italian = szValue;
			return true;
		}
		else if(szKey == "message_esperanto")
		{
			message_esperanto = szValue;
			return true;
		}
		else 
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
	}
	
    void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.netname == "" )
            self.pev.netname = "Info";
		
        BaseClass.Spawn();
	}

    string ReadWholeFile(string strFileName)
    {
        string strText;
        File@ fileDat = g_FileSystem.OpenFile( strFileName, OpenFile::READ );

        if( fileDat is null || !fileDat.IsOpen() )
            return "";

        while( !fileDat.EOFReached() )
            fileDat.ReadLine( strText );

        fileDat.Close();

        return strText;
    }
    /* Shows a MOTD message to the player */ //Code by Geigue
    void ShowMOTD(EHandle hPlayer, const string& in szTitle, const string& in szMessage)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null )
            return;
        
        NetworkMessage title( MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict() );
        title.WriteString( szTitle );
        title.End();
        
        uint iChars = 0;
        string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        
        for( uint uChars = 0; uChars < szMessage.Length(); uChars++ )
        {
            szSplitMsg.SetCharAt( iChars, char( szMessage[ uChars ] ) );
            iChars++;
            if( iChars == 32 )
            {
                NetworkMessage message( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
                message.WriteByte( 0 );
                message.WriteString( szSplitMsg );
                message.End();
                
                iChars = 0;
            }
        }
        // If we reached the end, send the last letters of the message
        if( iChars > 0 )
        {
            szSplitMsg.Truncate( iChars );
            
            NetworkMessage fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
            fix.WriteByte( 0 );
            fix.WriteString( szSplitMsg );
            fix.End();
        }
        
        NetworkMessage endMOTD( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
        endMOTD.WriteByte( 1 );
        endMOTD.WriteString( "\n" );
        endMOTD.End();
        
        NetworkMessage restore( MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict() );
        restore.WriteString( g_EngineFuncs.CVarGetString( "hostname" ) );
        restore.End();
    }

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( self.pev.SpawnFlagBitSet(SF_GP_ALL_PLAYERS) )
		{
			for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
				CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
				int iLanguage = int(ckLenguageIs.GetFloat());	
						
				if( pPlayer is null || !pPlayer.IsConnected() )
					continue;

				if(iLanguage == LANGUAGE_ENGLISH)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( self.pev.message ) );
					
				if(iLanguage == LANGUAGE_SPANISH)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_spanish ) );

				if(iLanguage == LANGUAGE_PORTUGUESE)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_portuguese ) );

				if(iLanguage == LANGUAGE_GERMAN)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_german ) );

				if(iLanguage == LANGUAGE_FRENCH)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_french ) );

				if(iLanguage == LANGUAGE_ITALIAN)
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_italian ) );	

				if(iLanguage == LANGUAGE_ESPERANTO)	
					ShowMOTD(pPlayer, string( self.pev.netname ), string( message_esperanto ) );
			}
		}
		else if( pActivator !is null && pActivator.IsPlayer() )
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pActivator);
			CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
			CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
			int iLanguage = int(ckLenguageIs.GetFloat());

			if(iLanguage == LANGUAGE_ENGLISH)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( self.pev.message ) );

			if(iLanguage == LANGUAGE_SPANISH)	
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_spanish ) );

			if(iLanguage == LANGUAGE_PORTUGUESE)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_portuguese ) );

			if(iLanguage == LANGUAGE_GERMAN)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_german ) );

			if(iLanguage == LANGUAGE_FRENCH)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_french ) );

			if(iLanguage == LANGUAGE_ITALIAN)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_italian ) );

			if(iLanguage == LANGUAGE_ESPERANTO)
				ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( message_esperanto ) );
		}
		
        self.SUB_UseTargets( pActivator, USE_TOGGLE, 0.0f );
	}
}