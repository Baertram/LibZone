--[========================================================================[
    This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.

    In jurisdictions that recognize copyright laws, the author or authors
    of this software dedicate any and all copyright interest in the
    software to the public domain. We make this dedication for the benefit
    of the public at large and to the detriment of our heirs and
    successors. We intend this dedication to be an overt act of
    relinquishment in perpetuity of all present and future rights to this
    software under copyright law.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

    For more information, please refer to <http://unlicense.org/>
--]========================================================================]

------------------------------------------------------------------------
-- 	Library identification and version
------------------------------------------------------------------------
local libZone = {}
--Addon/Library info
libZone.name                    = "LibZone"
libZone.version                 = 8.6
libZone.author                  = "Baertram"
libZone.url                     = "https://www.esoui.com/downloads/info2171-LibZone.html"

--SavedVariables info
libZone.svDataName              = "LibZone_SV_Data"
libZone.svLocalizedDataName     = "LibZone_Localized_SV_Data"
libZone.svGeoDebugDataName		= "LibZone_GeoDebug_SV_Data"
libZone.svVersion               = libZone.version -- Changing this will reset the SavedVariables!
libZone.svDataTableName         = "ZoneData"

local libraryName = libZone.name
local clientLang = GetCVar("language.2")

------------------------------------------------------------------------
-- Languages and translations
------------------------------------------------------------------------
--The supported languages of the library.
--Add new languages here or they won't be scanned nor added to any auto completion function!
local supportedLanguages = {
    [1] = "de",
    [2] = "en",
    [3] = "fr",
    [4] = "jp",
    [5] = "ru",
    [6] = "pl",
    [7] = "es",
    [8] = "zh",
}

--Translations for this library
local translations = {
    --Localized "Wayshrine" string used to exclude wayshrine map pins.
    wayshrineString = GetString(SI_DEATH_PROMPT_WAYSHRINE),

    --------------------------------------------------------------------------------------------------------------------
    ["de"] = {
        ["de"]                              = "Deutsch",
        ["en"]                              = "Englisch",
        ["fr"]                              = "Französisch",
        ["jp"]                              = "Japanisch",
        ["ru"]                              = "Russisch",
        ["pl"]                              = "Polnisch",
        ["es"]                              = "Spanisch",
        ["zh"]                              = "Chinesisch",
        ["slashCommandDescription"]         = "Suche übersetzte Zonen Namen",
        ["slashCommandDescriptionClient"]   = "Suche Zonen Namen (Spiel Sprache)",
        ["libSlashCommanderMissing"]        = "Bitte Bibliothek 'LibSlashCommander' installieren!",
        ["LibraryAlreadyLoaded"]            = "Bibliothek \'%s\' ist bereits geladen!",
    },
    ["en"] = {
        ["de"]  = "German",
        ["en"]  = "English",
        ["fr"]  = "French",
        ["jp"]  = "Japanese",
        ["ru"]  = "Russian",
        ["pl"]  = "Polish",
        ["es"]  = "Spanish",
        ["zh"]  = "Chinese",
        ["slashCommandDescription"] = "Search translations of zone names",
        ["slashCommandDescriptionClient"] = "Search zone names (game client language)",
        ["libSlashCommanderMissing"] = "Please install library 'LibSlashCommander'!",
        ["LibraryAlreadyLoaded"]            = "Library \'%s\' has already been loaded!",
    },
    ["fr"] = {
        ["de"]  = "Allemand",
        ["en"]  = "Anglais",
        ["fr"]  = "Français",
        ["jp"]  = "Japonais",
        ["ru"]  = "Russe",
        ["pl"]  = "Polonais",
        ["es"]  = "Espagnol",
        ["zh"]  = "Chinois",
        ["slashCommandDescription"] = "Rechercher des traductions de noms de zones",
        ["slashCommandDescriptionClient"] = "Rechercher des noms de zones (langue du jeu)",
        ["libSlashCommanderMissing"] = "Svp installer la bibliothèque 'LibSlashCommander'!",
        ["LibraryAlreadyLoaded"]            = "La bibliothèque \'%s \' a déjà été chargée!",
    },
    ["ru"] = {
        ["de"]  = "Нeмeцкий",
        ["en"]  = "Aнглийcкий",
        ["fr"]  = "Фpaнцузcкий",
        ["jp"]  = "Япoнcкий",
        ["ru"]  = "Pуccкий",
        ["pl"]  = "польский",
        ["es"]  = "испанский",
        ["zh"]  = "Китайский",
        ["slashCommandDescription"] = "Поиск переводов названий зон",
        ["slashCommandDescriptionClient"] = "Поиск по названию зоны (язык игры)",
        ["libSlashCommanderMissing"] = "Пожалуйста, установите библиотеку 'LibSlashCommander'!",
        ["LibraryAlreadyLoaded"]            = "Библиотека \'%s\' уже загружена!",
    },
    ["es"] = {
        ["de"]  = "Alemán",
        ["en"]  = "Inglés",
        ["fr"]  = "Francés",
        ["jp"]  = "Japonés",
        ["ru"]  = "Ruso",
        ["pl"]  = "Polaco",
        ["es"]  = "Español",
        ["zh"]  = "Chino",
        ["slashCommandDescription"] = "Buscar traducciones de nombres de zona",
        ["slashCommandDescriptionClient"] = "Buscar nombres de zonas (idioma del cliente del juego)",
        ["libSlashCommanderMissing"] = "¡Instala la biblioteca 'LibSlashCommander'!",
        ["LibraryAlreadyLoaded"]            = "¡La biblioteca \'%s\' ya se ha cargado!",
    },
    ["zh"] = {
        ["de"]  = "German",
        ["en"]  = "English",
        ["fr"]  = "French",
        ["jp"]  = "Japanese",
        ["ru"]  = "Russian",
        ["pl"]  = "Polish",
        ["es"]  = "Spanish",
        ["zh"]  = "Chinese",
        ["slashCommandDescription"] = "Search translations of zone names",
        ["slashCommandDescriptionClient"] = "Search zone names (game client language)",
        ["libSlashCommanderMissing"] = "Please install library 'LibSlashCommander'!",
        ["LibraryAlreadyLoaded"]            = "Library \'%s\' has already been loaded!",
    },

    --Special client languages
    ["jp"] = {
        ["de"]  = "ドイツ語",
        ["en"]  = "英語",
        ["fr"]  = "フランス語",
        ["jp"]  = "日本語",
        ["ru"]  = "ロシア",
        ["pl"]  = "ポーランド語",
        ["es"]  = "スペイン語",
        ["zh"]  = "中国語",
        ["slashCommandDescription"] = "ゾーン名の翻訳を検索する",
        ["slashCommandDescriptionClient"] = "ゾーン名（ゲームの言語）を検索する",
        ["libSlashCommanderMissing"] = "ライブラリ'LibSlashCommander'をインストールしてください!",
        ["LibraryAlreadyLoaded"]            = "ライブラリ\'％s\'はすでにロードされています！",
    },

    --Custom languages
    ["pl"] = {
        ["de"] = "Niemiecki",
        ["en"] = "Angielski",
        ["fr"] = "Francuski",
        ["jp"] = "Japoński",
        ["ru"] = "Rosyjski",
        ["pl"] = "Polskie",
        ["es"] = "Hiszpański",
        ["zh"]  = "Chinese",
        ["slashCommandDescription"] = "Wyszukaj tłumaczenia nazw stref",
        ["slashCommandDescriptionClient"] = "Wyszukaj nazwy stref (język klienta gry)",
        ["libSlashCommanderMissing"] = "Zainstaluj bibliotekę „LibSlashCommander”!",
        ["LibraryAlreadyLoaded"]            = "Biblioteka \'%s\' została już załadowana!",
    },
}

--Check if the language is supported
local function checkIfLanguageIsSupported(lang)
    if lang == nil then return false end
    for _, langIsSupported in ipairs(supportedLanguages) do
        if lang == langIsSupported then return true end
    end
    return false
end

------------------------------------------------------------------------
-- 	Library creation and "already loaded" checks
------------------------------------------------------------------------
--Is the client language supported? If not: Use English as fallback language
if not checkIfLanguageIsSupported(clientLang) then
    clientLang = "en"
end

--Is the library already loaded?
assert(not _G[libraryName], string.format(translations[clientLang]["LibraryAlreadyLoaded"], tostring(libZone.name)))
local lib = {}
local oldminor
if not lib then return end -- the same or newer version of this lib is already loaded into memory

------------------------------------------------------------------------
-- 	Variables of the library
------------------------------------------------------------------------
--Library information and version
lib.libraryInfo = libZone
lib.oldMinor    = oldminor

--The APIversion
lib.currentAPIVersion = GetAPIVersion()

--The server name variable
lib.worldName = GetWorldName()

--Zone data
lib.zoneData = {}
lib.localizedZoneData = {}
lib.publicDungeonMapIds = {}

--Search variables
lib.searchDirty = true
lib.searchTranslatedZoneResultList = {}
lib.searchTranslatedZoneLookupList = {}

--Maximum zoneIds to scan (as long as there is no constant or function for it we need to "hardcode" a maximum here
lib.maxZoneIndices = 0
lib.maxZoneIds = 0
lib.maxMapIds = 3500 -- Currently there are around 2100 -> API101031 Waking Flame, 20210728 -> Increase this number if there will be added more maps!

--Language and translation
lib.currentClientLanguage = clientLang
lib.supportedLanguages = supportedLanguages
lib.translations = translations


--Blacklisted zoneIds which will not be added to the scanned (and thus not added to the auto completion) lists
local blacklistedZoneIdsForAutoCompletion = {
    [2]     = true, -- Clean Test
    [279]   = true, -- Pregame
    [774]   = true, -- Unterschlüpfe/Hideouts: Bandit 13 - Bandit 18
    [775]   = true,
    [776]   = true,
    [777]   = true,
    [778]   = true,
    [779]   = true,
    [781]   = true,  -- Unterschlüpfe/Hideouts: Bandit 20 - Bandit 47
    [782]   = true,
    [783]   = true,
    [784]   = true,
    [785]   = true,
    [786]   = true,
    [787]   = true,
    [788]   = true,
    [789]   = true,
    [790]   = true,
    [791]   = true,
    [792]   = true,
    [793]   = true,
    [794]   = true,
    [795]   = true,
    [796]   = true,
    [797]   = true,
    [798]   = true,
    [799]   = true,
    [800]   = true,
    [801]   = true,
    [802]   = true,
    [803]   = true,
    [804]   = true,
    [805]   = true,
    [806]   = true,
    [807]   = true,
    [808]   = true,
    [917]   = true, -- zTestBarbershop
    [1107]  = true, -- zWicksTest
}
lib.blacklistedZoneIdsForAutoCompletion = blacklistedZoneIdsForAutoCompletion

------------------------------------------------------------------------
-- 	Functions of the library
------------------------------------------------------------------------
lib.checkIfLanguageIsSupported = checkIfLanguageIsSupported

------------------------------------------------------------------------
-- Other libraries
------------------------------------------------------------------------
--LibSlashCommaner for the auto completion and zone translation search
local LSC = LibSlashCommander
--if not LSC then d("[" .. libZone.name .. "]Library 'LibSlashCommander' is missing!") return nil end
if LSC then
    lib.LSC = LSC
end

------------------------------------------------------------------------
-- 	Global variable for the lib: LibZone
------------------------------------------------------------------------
--Assign LibStub created/or non LibStub global var library instance of LibZone (lib) to global variable (LibZone)
_G[libraryName] = lib
