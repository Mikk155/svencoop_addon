// Include game_text_custom
#include "game_text_custom"

void MapInit()
{
	// Register game_text_custom
	RegisterCustomTextGame();
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Gaftherman" );
	g_Module.ScriptInfo.SetContactInfo( "https://github.com/Mikk155/Sven-Coop-Multi-language-localizations" );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
    g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
    g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
}

// Read current map .ent localization script.
const string EntFileLoad = " scripts/plugins/multi_language/localizations/" + string( g_Engine.mapname ) + ".ent";

void MapActivated()
{
	CBaseEntity@ pEntity = null;
	
	if ( g_EntityLoader.LoadFromFile( EntFileLoad ) )
	{
		g_EngineFuncs.ServerPrint( "Can't open multi-language script file " + EntFileLoad + ".ent\n" );
	}
	else
	{
		g_EngineFuncs.ServerPrint( "multi-language script file " + EntFileLoad + ".ent opened\n" );
		// SetInterval for spamming messages.
		g_Scheduler.SetInterval( "SpamsMultilanguage", 100, g_Scheduler.REPEAT_INFINITE_TIMES );
		
		g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
		
		for( int i = 0; i < g_Engine.maxEntities; ++i )
		{
			edict_t@ edict = @g_EntityFuncs.IndexEnt( i );
			CBaseEntity@ FindGameText = g_EntityFuncs.Instance( edict );
		}
		// Delete old text entities if .ent file exist.
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_message" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
	}
}

void SpamsMultilanguage()
{
	string Available;

    for( int i = 0; i < g_Engine.maxEntities; ++i )
    {
        edict_t@ edict = @g_EntityFuncs.IndexEnt( i );
        CBaseEntity@ FindGameText = g_EntityFuncs.Instance( edict );

        if( FindGameText is null && FindGameText.GetClassname() != "game_text_custom" )
            continue;

		bool English = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message", "" );
		bool Spanish = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_spanish", "" );
		bool Portuguese = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_portuguese", "" );
		bool German = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_german", "" );
		bool French = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_french", "" );
		bool Italian = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_italian", "" );
		bool Esperanto = g_EntityFuncs.DispatchKeyValue( FindGameText.edict(), "message_esperanto", "" );

		if( !English )
			Available = "English";

		if( !Spanish )
			Available = Available + " || Spanish";

		if( !Portuguese )
			Available = Available + " || Portuguese";

		if( !German )
			Available = Available + " || German";

		if( !French )
			Available = Available + " || French";

		if( !Italian )
			Available = Available + " || Italian";

		if( !Esperanto )
			Available = Available + " || Esperanto";
    }

	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Multi-Language] This map supports multi-language, use /language (language).\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Available:" +Available+ "\n" );
}

dictionary g_PlayerKeepLenguage;

class PlayerKeepLenguageData
{
	int lenguage;
}

HookReturnCode MapChange()
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null or !pPlayer.IsConnected() )
			continue;

		string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

		CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
        CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
        int iLanguage = int(ckLenguageIs.GetFloat());

		PlayerKeepLenguageData pData;
		pData.lenguage = iLanguage;
		g_PlayerKeepLenguage[SteamID] = pData;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

	string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	if( g_PlayerKeepLenguage.exists(SteamID) )
	{
        PlayerLoadLenguage( g_EngineFuncs.IndexOfEdict(pPlayer.edict()), SteamID );
	}
    else
    {
     	CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
	    ckLenguage.SetKeyvalue("$f_lenguage", 0.0);   

        PlayerKeepLenguageData pData;
		pData.lenguage = 0.0;
		g_PlayerKeepLenguage[SteamID] = pData;
    }

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if(pPlayer is null)
		return HOOK_CONTINUE;

    string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

	CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
    CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
    int iLanguage = int(ckLenguageIs.GetFloat());

    PlayerKeepLenguageData pData;
	pData.lenguage = iLanguage;
	g_PlayerKeepLenguage[SteamID] = pData;   

    return HOOK_CONTINUE;
}

void PlayerLoadLenguage( int &in iIndex, string &in SteamID )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iIndex);

	if( pPlayer is null )
		return;

	PlayerKeepLenguageData@ pData = cast<PlayerKeepLenguageData@>(g_PlayerKeepLenguage[SteamID]);

	CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
	ckLenguage.SetKeyvalue("$f_lenguage", int(pData.lenguage));
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();

    if(args[0] == "/language" || args[0] == "/lenguaje" || args[0] == "/idioma") 
    {
        if(args.ArgC() < 2)
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Multi-Language] Select a language, you can use: 'english' or '0'; 'spanish' or '1'; and so on.\n" );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Example: /language english\n" );
		}
		else
        {
			CustomKeyvalues@ ckLenguage = pPlayer.GetCustomKeyvalues();
            CustomKeyvalue ckLenguageIs = ckLenguage.GetKeyvalue("$f_lenguage");
            int iLanguage = int(ckLenguageIs.GetFloat());

			if(args[1] == "esperanto" || args[1] == "6")
			{
				if(iLanguage == 5)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Vi aktivigis ci tiun lingvon\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Esperonton aktivigis\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 6);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "italian" || args[1] == "5")
			{
				if(iLanguage == 5)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "hai gia questa lingua\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Lingua in italiano attivata\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 5);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "french" || args[1] == "4")
			{
				if(iLanguage == 4)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "vous avez deja cette langue\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Langue en francais activee\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 4);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "german" || args[1] == "3")
			{
				if(iLanguage == 3)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Sie haben diese Sprache bereits\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "deutsche sprache aktiviert\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 3);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "portuguese" || args[1] == "2")
			{
				if(iLanguage == 2)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voce ativou este idioma\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Idioma em portugues ativado\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 2);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "spanish" || args[1] == "1")
			{
				if(iLanguage == 1)
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Ya tienes activado este lenguaje\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Lenguaje en español activado\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 1);
				}

				pParams.ShouldHide = true;
			}
			else if(args[1] == "english" || args[1] == "0")
			{
				if(iLanguage == 0)
				{
                    g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You have activated this laguage\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Language in english activated\n" );
					ckLenguage.SetKeyvalue("$f_lenguage", 0);
				}

				pParams.ShouldHide = true;
			}
			else
			{		
        		pParams.ShouldHide = false;
			}
        }

        return HOOK_HANDLED;
    }

    return HOOK_CONTINUE;
}
