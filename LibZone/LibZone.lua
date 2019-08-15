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
-- 	Library identification
------------------------------------------------------------------------
local libZone = {}
--Addon/Library info
libZone.name        = "LibZone"
libZone.version     = 6.0
--SavedVariables info
libZone.svDataName  = "LibZone_SV_Data"
libZone.svLocalizedDataName = "LibZone_Localized_SV_Data"
libZone.svVersion   = 6.0 -- Changing this will reset the SavedVariables!
libZone.svDataTableName = "ZoneData"
--Maximum zoneIds to scan (as long as there is no constant or function for it we need to "hardcode" a maximum here
libZone.maxZoneIds  = 2500 -- API100028, Scalebraker

------------------------------------------------------------------------
-- 	Library creation
------------------------------------------------------------------------
assert(not _G[libZone.name], "\'" .. libZone.name .. "\' has already been loaded")
local lib = {}
local oldminor
if LibStub then
    lib, oldminor = LibStub:NewLibrary(libZone.name, libZone.version)
end
if not lib then return end -- the same or newer version of this lib is already loaded into memory

------------------------------------------------------------------------
-- 	Global variables
------------------------------------------------------------------------
--Assign LibStub created/or non LibStub global var library instance of LibZone (lib) to global variable (LibZone)
_G[libZone.name] = lib

lib.libraryInfo = libZone
lib.oldMinor    = oldminor

------------------------------------------------------------------------
-- 	Local variables, global for the library
------------------------------------------------------------------------
local LSC = LibSlashCommander
if LSC == nil and LibStub then LSC = LibStub("LibSlashCommander") end
if not LSC then d("[" .. libZone.name .. "]Library 'LibSlashCommander' is missing!") return nil end
lib.LSC = LSC
lib.searchDirty = true
lib.zoneData = {}
lib.localizedZoneData = {}
lib.worldName = ""
lib.searchTranslatedZoneResultList = {}
lib.searchTranslatedZoneLookupList = {}
lib.supportedLanguages = {
    [1] = "de",
    [2] = "en",
    [3] = "fr",
    [4] = "jp",
    [5] = "ru",
    [6] = "pl",
}
local translations = {
    ["de"] = {
        ["de"]  = "Deutsch",
        ["en"]  = "Englisch",
        ["fr"]  = "Französisch",
        ["jp"]  = "Japanisch",
        ["ru"]  = "Russisch",
        ["pl"]  = "Polnisch",
        ["slashCommandDescription"] = "Suche übersetzte Zonen Namen",
        ["slashCommandDescriptionClient"] = "Suche Zonen Namen (Spiel Sprache)",
    },
    ["en"] = {
        ["de"]  = "German",
        ["en"]  = "English",
        ["fr"]  = "French",
        ["jp"]  = "Japanese",
        ["ru"]  = "Russian",
        ["pl"]  = "Polish",
        ["slashCommandDescription"] = "Search translations of zone names",
        ["slashCommandDescriptionClient"] = "Search zone names (game client language)",
    },
    ["fr"] = {
        ["de"]  = "Allemand",
        ["en"]  = "Anglais",
        ["fr"]  = "Français",
        ["jp"]  = "Japonais",
        ["ru"]  = "Russe",
        ["pl"]  = "Polonais",
        ["slashCommandDescription"] = "Rechercher des traductions de noms de zones",
        ["slashCommandDescriptionClient"] = "Rechercher des noms de zones (langue du jeu)",
    },
    ["jp"] = {
        ["de"]  = "ドイツ語",
        ["en"]  = "英語",
        ["fr"]  = "フランス語",
        ["jp"]  = "日本語",
        ["ru"]  = "ロシア",
        ["pl"]  = "ポーランド語",
        ["slashCommandDescription"] = "ゾーン名の翻訳を検索する",
        ["slashCommandDescriptionClient"] = "ゾーン名（ゲームの言語）を検索する",
    },
    ["ru"] = {
        ["de"]  = "Нeмeцкий",
        ["en"]  = "Aнглийcкий",
        ["fr"]  = "Фpaнцузcкий",
        ["jp"]  = "Япoнcкий",
        ["ru"]  = "Pуccкий",
        ["pl"]  = "польский",
        ["slashCommandDescription"] = "Поиск переводов названий зон",
        ["slashCommandDescriptionClient"] = "Поиск по названию зоны (язык игры)",
    },
    ["pl"] = {
        ["de"] = "Niemiecki",
        ["en"] = "Angielski",
        ["fr"] = "Francuski",
        ["jp"] = "Japoński",
        ["ru"] = "Rosyjski",
        ["pl"] = "Polskie",
        ["slashCommandDescription"] = "Wyszukaj tłumaczenia nazw stref",
        ["slashCommandDescriptionClient"] = "Wyszukaj nazwy stref (język klienta gry)",
    },
}

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

------------------------------------------------------------------------
-- 	Helper functions
------------------------------------------------------------------------
--Check if the language is supported
local function checkIfLanguageIsSupported(lang)
    if lang == nil then return false end
    for _, langIsSupported in ipairs(lib.supportedLanguages) do
        if lang == langIsSupported then return true end
    end
    return false
end

--Load the SavedVariables and connect the tables of the library with the SavedVariable tables.
--The following table will be stored and read to/from the SavedVariables:
--LibZone.zoneData:             LibZone_SV_Data             -> zoneIds and parentZoneIds
--LibZone.localizedZoneData:    LibZone_Localized_SV_Data   -> zoneNames, with different languages
---> This table only helds the "delta" between the scanned zoneIds + language and the preloaded data in file LibZone_Data.lua, table preloadedZoneNames
local function librarySavedVariables()
    lib.worldName = GetWorldName()
    local svVersion         = libZone.svVersion
    local svDataTableName   = libZone.svDataTableName
    local worldName         = lib.worldName
    local defaultZoneData = {}
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    -->Save to "$AllAccounts" so the data is only once in the SavedVariables for all accounts, on each server!
    lib.zoneData            = ZO_SavedVars:NewAccountWide(libZone.svDataName,           svVersion, svDataTableName, defaultZoneData, worldName, "$AllAccounts")
    lib.localizedZoneData   = ZO_SavedVars:NewAccountWide(libZone.svLocalizedDataName,  svVersion, svDataTableName, defaultZoneData, worldName, "$AllAccounts")
end

--Check other langauges than the client language: Is there any zoneData given?
--The preloaded zoneNames table LibZone.preloadedZoneNames in from file LibZone_Data.lua (other languages e.g.) will be enriched with new scanned data from
--the SavedVariables table LibZone_Localized_SV_Data
local function checkOtherLanguagesZoneDataAndTransferFromSavedVariables()
    local clientLanguage = lib.currentClientLanguage
    local zoneData = lib.zoneData
    local localizedZoneDataSV = lib.localizedZoneData
    local preloadedZoneNamesTable = lib.preloadedZoneNames
    local supportedLanguages = lib.supportedLanguages
    --Is the preloaded data given and the zoneIds table as well?
    if preloadedZoneNamesTable ~= nil and zoneData ~= nil and supportedLanguages ~= nil then
        --Only check the currently active language as only this one might have been scanned and updated with function LibZone:GetAllZoneDataById() before!
        if supportedLanguages[clientLanguage] == true then
            --Get the preloaded data for the supported language (client language)
            local preloadedZoneNamesForLanguage = preloadedZoneNamesTable[clientLanguage]
            if preloadedZoneNamesForLanguage then
                --Check for each zoneId in the zoneData table
                for zoneId, _ in pairs(zoneData) do
                    --Check if zoneId entries are missing in the preloaded data language table for the current client language
                    if not preloadedZoneNamesForLanguage[zoneId] and localizedZoneDataSV[clientLanguage][zoneId] then
                        --Add the entries to the preloadedZoneNames table for the client language
                        preloadedZoneNamesForLanguage[zoneId] = localizedZoneDataSV[clientLanguage][zoneId]
                    end
                end
            else
                --Table with the zoneNames in this language is missing in total
                --So get the data from the SavedVariables once (if it exists)
                if localizedZoneDataSV[clientLanguage] then
                    preloadedZoneNamesForLanguage = localizedZoneDataSV[clientLanguage]
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- 	Library functions
------------------------------------------------------------------------
--Check and get all zone's IDs (zoneId and parentZoneId) and save them to the library's table zoneData.
--Check which zoneNames are already preloaded into the libraries table LibZone.preloadedZoneNames. For the missing ones (compared to entries in just updated table zoneData.zoneId):
---Check and get the zone's name for the zone ID.
-- New added entries will be saved to the SavedVariables table LibZone_Localized_SV_Data so they will not be scanned again next time, but just read from there until they get
-- manually transfered to the LibZone.preloadedZoneNames table (as the library gets updated).
--Parameters:
-->reBuildNew: Boolean [true=Rebuild the zoneData for all zones, even if they already exist / false=Skip already existing zoneIds]
-->doReloadUI: Boolean [true=If at least one zoneId was added/updated, do a ReloadUI() at the end to update the SavaedVariables now / false=No autoamtic ReloadUI()]
function lib:GetAllZoneDataById(reBuildNew, doReloadUI)
    reBuildNew = reBuildNew or false
    doReloadUI = doReloadUI or false
    --Client language
    local lang = self.currentClientLanguage
    if lang == nil then return false end
d("[LibZone]GetAllZoneDataById, reBuildNew: " ..tostring(reBuildNew) .. ", doReloadUI: " ..tostring(doReloadUI) .. ", lang: " .. tostring(lang))
    --Maximum of ZoneIds to check
    local maxZoneId = libZone.maxZoneIds
    --Local SavedVariable data
    local zoneData = self.zoneData
    if zoneData == nil then
        self.zoneData = {}
        zoneData = self.zoneData
    end
    local localizedZoneDataSV = self.localizedZoneData[lang]
    if zoneData == nil then return false end
    local preloadedZoneNamesTable = lib.preloadedZoneNames[lang]
    --The preloaded zoneData does not exist for the whole language
    local languageIsMissingInTotal = false
    if preloadedZoneNamesTable == nil then
        languageIsMissingInTotal = true
    end
--d(">languageIsMissingInTotal: " ..tostring(languageIsMissingInTotal))
    --Loop over all zone Ids and get it's data + name
    local addedAtLeastOne = false
    for zoneId = 1, maxZoneId, 1 do
        local wasCreatedNew = false
        local zoneIndexOfZoneId = GetZoneIndex(zoneId)
--d(">>Checking zoneId: " ..tostring(zoneId) .. ", preloadedZoneNamesTable[zoneId]: " .. tostring(preloadedZoneNamesTable[zoneId]) .. ", zoneIndexOfZoneId: " ..tostring(zoneIndexOfZoneId))
        if zoneIndexOfZoneId and zoneIndexOfZoneId ~= 1 then -- zoneIndex 1 is for all the zones which got no name (hopefully)
            --The preloaded zoneNames for the language is missing in total or the zoneName for the curent zoneId is missing?
            if languageIsMissingInTotal or (preloadedZoneNamesTable and preloadedZoneNamesTable[zoneId] == nil) then
                --Get the "delta" zoneName now and add it to the SavedVariables localizedZoneData -> LibZone_Localized_SV_Data[lang][zoneId]
                local zoneName = GetZoneNameById(zoneId)
                if zoneName and zoneName ~= "" then
                    if localizedZoneDataSV == nil then
                        self.localizedZoneData[lang] = {}
                        localizedZoneDataSV = self.localizedZoneData[lang]
                    end
                    localizedZoneDataSV[zoneId] = ZO_CachedStrFormat("<<C:1>>", zoneName)
                    wasCreatedNew = true
                end
            else
                --Check if the actual scanned zoneId is still in the SavedVariables and remove it there then
                if localizedZoneDataSV and localizedZoneDataSV[zoneId] then
--d(">zoneId was still in the SavedVars and got removed again")
                    localizedZoneDataSV[zoneId] = nil
                end
            end
            if reBuildNew or wasCreatedNew then
                if zoneData[zoneId] == nil then
                    zoneData[zoneId] = {}
                    wasCreatedNew = true
                end
                addedAtLeastOne = true
                local zoneDataForId = zoneData[zoneId]
                --Set zone index
                if zoneDataForId.zoneIndex == nil then
                    zoneDataForId.zoneIndex = zoneIndexOfZoneId
                end
                --Set zone parent
                if GetParentZoneId ~= nil then --> Function will be added with API100025 Murkmire
                    if zoneDataForId.parentZone == nil then
                        local zoneParentIdOfZoneId = GetParentZoneId(zoneId)
                        zoneDataForId.parentZone = zoneParentIdOfZoneId
                    end
                end
            end
        end
    end
    --Was at least one zoneId added/changed?
    if addedAtLeastOne then
        --Update the API version as the zone ID check was done
        local currentAPIVersion = self.currentAPIVersion
        --self.zoneData.lastZoneCheckAPIVersion = self.zoneData.lastZoneCheckAPIVersion or {}
        --self.zoneData.lastZoneCheckAPIVersion[lang] = currentAPIVersion
        --Reload the UI now to update teh SavedVariables?
        --Add the current API version to the language table so one knows when the data was collected
        if localizedZoneDataSV then
            localizedZoneDataSV["lastUpdate"] = GetTimeStamp()
            localizedZoneDataSV["APIVersionAtLastUpdate"] = currentAPIVersion
        end
        --and add a timestamp
        if doReloadUI then ReloadUI() end
    end
end

--Return the zoneData for all zones and all languages
-->Returns table:
--->returnTable = {
--->    [language] = {
----->    [zoneId] = "zoneName"
--->    },
--->}
function lib:GetAllZoneData()
    return lib.preloadedZoneNames
end

--Return the zoneData of a zone, determined by help of the subZone ID.
--Parameters:
--subZoneId: Number SubZoneId
--language: String Language for the ParentZoneName
-->Returns table:
--->returnTable[number SubZoneId] = {
--->    ["parentZoneId"] = number ParentZoneId,
--->    ["name]"         = String "ParentZoneName"
--->}
--If no parent zone can be found the return value will be nil.
function lib:GetZoneDataBySubZone(subZoneId, language)
    assert (subZoneId ~= nil, "[LibZone:GetZoneDataBySubZone]Error: Missing SubZoneId!")
    language = language or self.currentClientLanguage
    local retParentZoneTable = {}
    local parentZoneId = GetParentZoneId(subZoneId) or 0
    if parentZoneId == nil or parentZoneId == 0 then return nil end
    retParentZoneTable[subZoneId] = {}
    retParentZoneTable[subZoneId]["parentZoneId"] = parentZoneId
    retParentZoneTable[subZoneId]["name"] = self:GetZoneName(parentZoneId, language)
    return retParentZoneTable
end

--Return existing zone/their subZone data to variables.
-- Returns the zoneData, subZoneData tables
-->Contents of zoneData:
-->zoneData = { ["name"] = String "Zone Name^n"
-->             ["zoneIndex"] = number zoneIndex
-- }
-->Contents of subZoneData:
-->subZoneData = { ["name"] = String "Sub zone Name^n"
-->                ["parentZone"] = number zoneId}
-- }
function lib:GetZoneData(zoneId, subZoneId, language)
    assert (zoneId ~= nil, "[LibZone:GetZoneData]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local readZoneData, readSubZoneData
    local zoneData =  self.zoneData
    local localizedZoneData = self.lib.preloadedZoneNames[language]
    if zoneData ~= nil and localizedZoneData ~= nil then
        readZoneData = zoneData[zoneId] or nil
        local readZoneName = localizedZoneData[zoneId] or nil
        if readZoneData ~= nil and readZoneName ~= nil and readZoneName ~= "" then
            readZoneData["name"]= readZoneName
        end
        if subZoneId ~= nil and GetParentZoneId ~= nil then
            local parentZoneId = GetParentZoneId(subZoneId)
            if parentZoneId == zoneId then
                readSubZoneData = zoneData[subZoneId] or nil
                local readSubZoneName = localizedZoneData[subZoneId] or nil
                if readSubZoneData ~= nil then
                    readSubZoneData["name"] = readSubZoneName
                end
            end
        end
    else
        d("[LibZone:GetZoneData]Error: Missing zoneData for language \"" .. tostring(language) .. "\"!")
    end
    return readZoneData, readSubZoneData
end

--Show existing zone data to the chat now
--Output zone informtaion to the chat, using the zoneId, subZoneId (connected to zoneId via parentZoneId) and the language (e.g. "en" or "fr")
function lib:ShowZoneData(zoneId, subZoneId, language)
    assert (zoneId ~= nil, "[LibZone:ShowZoneData]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local zoneIdData, subZoneIdData = self:GetZoneData(zoneId, subZoneId, language)
    if zoneIdData ~= nil then
        d("[" .. libZone.name .. "]ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\", language: \"" .. tostring(language) .. "\"")
        d(">Zone name: " .. tostring(zoneIdData.name))
        if zoneIdData.zoneIndex ~= nil then d(">Zone index: " .. tostring(zoneIdData.zoneIndex)) end
        if subZoneIdData ~= nil then
            d(">>SubZone name: " .. tostring(subZoneIdData.name))
            if subZoneIdData.zoneIndex ~= nil then d(">SubZone index: " .. tostring(subZoneIdData.zoneIndex)) end
        end
    else
        d("[" .. libZone.name .. "]ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\"\nNo zone data was found for language \"" .. tostring(language) .. "\"!")
    end
end


--Get the localized zone name by help of a zoneId
--zoneId: Number containing zoneId
--language: The language to use for the zoneName
--->Returns localized String of the zoneName
function lib:GetZoneName(zoneId, language)
    assert(zoneId ~= nil, "[LibZone:GetZoneName]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local localizedZoneIdData = self.preloadedZoneNames[language]
    if localizedZoneIdData == nil then
        local retName = ""
        --Is the language the client language?
        if language == self.currentClientLanguage then
            --Get the zone name by the help of API function
            retName = ZO_CachedStrFormat("<<C:1>>", GetZoneNameById(zoneId))
        end
        return retName
    end
    local localizedZoneName = localizedZoneIdData[zoneId] or ""
    if localizedZoneName == nil then return "" end
    return localizedZoneName
end

--Get the localized zone names by help of a table containing the zoneIds
-->zoneIdsTable: Table containing a number index as key and the zoneId as value
-->e.g. zoneIdsTable = {2, 3, 36, 1200} or zoneIdsTable[1] = 1, zoneIdsTable[2] = 3, zoneIdsTable[3] = 36, zoneIdsTable[4] = 1200
--->Returns table containing the zone names
--->Key = zoneId
--->Value = table with the zoneData from the SavedVariables.
--->Example:
---->returnTable[2] = "Clean Test"
---->returnTable[3] = "Glenumbra"
function lib:GetZoneNamesByIds(zoneIdsTable, language)
    assert (zoneIdsTable ~= nil and type(zoneIdsTable) == "table", "[LibZone:GetZoneNamesByIds]Error: Missing zoneId table.\nTable's format must be \"[number TableIndex] = number ZoneId,\"!")
    language = language or self.currentClientLanguage
    local retNameTable = {}
    for _, zoneId in pairs(zoneIdsTable) do
        if zoneId ~= nil and type(zoneId) == "number" then
            local zoneName = self:GetZoneName(zoneId, language)
            if zoneName ~= nil and zoneName ~= "" then
                retNameTable[zoneId] = zoneName
            end
        end
    end
    return retNameTable
end

--Get the localized zone data by help of a table containing the zoneIds
-->zoneIdsTable: Table containing a number index as key and the zoneId as value
-->e.g. zoneIdsTable = {2, 3, 36, 1200} or zoneIdsTable[1] = 1, zoneIdsTable[2] = 3, zoneIdsTable[3] = 36, zoneIdsTable[4] = 1200
--->Returns table containing the zoneData
--->Key = zoneId
--->Value = table with the zoneData from the SavedVariables.
--->Example:
---->returnTable[2] = {
---->   ["name"] = "Clean Test",
---->   ["zoneIndex"] = 1,
---->},
---->returnTable[3] = {
---->   ["name"] = "Glenumbra",
---->   ["zoneIndex"] = 2,
---->}
function lib:GetZoneDataByIds(zoneIdsTable, language)
    assert (zoneIdsTable ~= nil and type(zoneIdsTable) == "table", "[LibZone:GetZoneDataByIds]Error: Missing zoneId table.\nTable's format must be \"[number TableIndex] = number ZoneId,\"!")
    language = language or self.currentClientLanguage
    local retZoneDataTable = {}
    for _, zoneId in pairs(zoneIdsTable) do
        if zoneId ~= nil and type(zoneId) == "number" then
            local zoneData = self:GetZoneData(zoneId, nil, language)
            if zoneData ~= nil then
                retZoneDataTable[zoneId] = zoneData
            end
        end
    end
    return retZoneDataTable
end

--Get the localized zone names matching to a localized search string
-->searchStr: The String with the search value of a zone name (using searchLanguage)
-->searchLanguage: The langauge to search the searchStr variable in Format example: "en". Can be nil (<nilable>)! If the searchLangauge is nil the client language will be taken as searchLanguage.
-->returnLanguage: The language for the translated results. e.g. you search for "Ostmar" with search language "de" and the return language "en". The result will be the "Eastmarch" zone.
--->Returns table containing the zoneId as table key and the localized (in language: returnLanguage) full zone name, matching to the search string, as table value
function lib:GetZoneNameByLocalizedSearchString(searchStr, searchLanguage, returnLanguage)
    assert (searchStr ~= nil and searchStr ~= "", "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing parameter \"searchStr\"!")
    assert (returnLanguage ~= nil and type(returnLanguage) == "string", "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing or wrong parameter \"returnLanguage\"!")
    local langIsSupported = checkIfLanguageIsSupported(returnLanguage) or false
    assert (langIsSupported == true, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Return language \"" .. tostring(returnLanguage) .. "\" is not supported!")
    langIsSupported = false
    searchLanguage = searchLanguage or self.currentClientLanguage
    assert (searchLanguage ~= returnLanguage, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Search language and returning language must be different!")
    langIsSupported = checkIfLanguageIsSupported(searchLanguage) or false
    assert (langIsSupported == true, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Search language \"" .. tostring(searchLanguage) .. "\" is not supported!")
    local retZoneIdsTable = {}
    local retZoneLocalizedZoneNamesTable = {}
    local localizedSearchZoneData = self.preloadedZoneNames[searchLanguage]
    assert (localizedSearchZoneData ~= nil, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing localized search zone data with language \"" .. tostring(searchLanguage) .. "\"!")
    local zoneReturnLocalizedData = self.preloadedZoneNames[returnLanguage]
    assert (zoneReturnLocalizedData ~= nil, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing localized return zone data with language \"" .. tostring(returnLanguage) .. "\"!")
    for zoneId, zoneName in pairs(localizedSearchZoneData) do
        if zoneName ~= "" and zo_plainstrfind(zoneName:lower(), searchStr:lower()) then
            table.insert(retZoneIdsTable, zoneId)
        end
    end
    if retZoneIdsTable ~= nil and #retZoneIdsTable > 0 then
        for _, zoneId in ipairs(retZoneIdsTable) do
            local returnLocalizedZoneName = zoneReturnLocalizedData[zoneId]
            if returnLocalizedZoneName ~= nil and returnLocalizedZoneName ~= "" then
                retZoneLocalizedZoneNamesTable[zoneId] = returnLocalizedZoneName
            end
        end
    end
    return retZoneLocalizedZoneNamesTable
end

------------------------------------------------------------------------
-- 	Library - Chat autocomplete functions (using LibSlashCommander)
------------------------------------------------------------------------

function lib:buildAutoComplete(command, langToUse)
    if command == nil or not checkIfLanguageIsSupported(langToUse) then return end
    --Add sub commands for the zoneNames
    local this = self
    local localizedZoneDataForLang = self.preloadedZoneNames[langToUse]
    if localizedZoneDataForLang ~= nil then
        local MyAutoCompleteProvider = {}
        MyAutoCompleteProvider = self.LSC.AutoCompleteProvider:Subclass()
        function MyAutoCompleteProvider:New(resultList, lookupList, lang)
            local obj = this.LSC.AutoCompleteProvider.New(self)
            obj.resultList = resultList
            obj.lookupList = lookupList
            obj.lang = langToUse
            return obj
        end

        function MyAutoCompleteProvider:GetResultList()
            return self.resultList
        end

        function MyAutoCompleteProvider:GetResultFromLabel(label)
            return self.lookupList[label] or label
        end

        local repStr = "·"
        local langUpper = translations[langToUse][langToUse]
        for zoneId, zoneName in pairs(localizedZoneDataForLang) do
            --Check if the zoneIds are blacklisted
            local isZoneBlacklisted = blacklistedZoneIdsForAutoCompletion[zoneId] or false
            if not isZoneBlacklisted then
                --Replace the spaces in the zone name so LibSlashCommander will find them with the auto complete properly
                --try to use %s instead of just a space. if that doesn't work use [\t-\r ] instead
                local zoneNameNoSpaces = string.gsub(zoneName, "%s+", repStr)
                if zoneNameNoSpaces == "" then zoneNameNoSpaces = zoneName end
                if not command:HasSubCommandAlias(zoneNameNoSpaces) then
                    --Add a zone entry as subcommand so the first auto complete will show all zone names as the user types /lzt into chat
                    local zoneSubCommand = command:RegisterSubCommand()
                    zoneSubCommand:AddAlias(zoneNameNoSpaces)
                    zoneSubCommand:SetDescription(langUpper)
                    zoneSubCommand:SetCallback(function(input)
                        StartChatInput(input)
                    end)
                    --Get the translated zone names
                    local otherLanguagesZoneName = {} -- Only a temp table
                    local otherLanguagesNoDuplicateZoneName = {} -- Only a temp table
                    local alreadyAddedCleanTranslatedZoneNames = {} -- The resultsList for the autocomplete provider
                    local alreadyAddedCleanTranslatedZoneNamesLookup = {} -- The lookupList for the autocomplete provider
                    for langIdx, lang in ipairs(self.supportedLanguages) do
                        local otherLanguageZoneName = lib:GetZoneName(zoneId, lang)
                        if otherLanguageZoneName ~= nil and otherLanguageZoneName ~= "" then
                            otherLanguagesZoneName[langIdx] = otherLanguageZoneName
                        end
                    end
                    if #otherLanguagesZoneName >= 1 then
                        local langStr = ""
                        for langIdx, cleanTranslatedZoneName in ipairs(otherLanguagesZoneName) do
                            local lang = self.supportedLanguages[langIdx]
                            local upperLangStr = translations[langToUse][lang]
                            if otherLanguagesNoDuplicateZoneName[cleanTranslatedZoneName] == nil then
                                langStr = ""
                            else
                                langStr = otherLanguagesNoDuplicateZoneName[cleanTranslatedZoneName]
                            end
                            if langStr == "" then
                                langStr = upperLangStr
                            else
                                langStr = langStr .. ", " .. upperLangStr
                            end
                            otherLanguagesNoDuplicateZoneName[cleanTranslatedZoneName] = langStr
                        end
                        for cleanTranslatedZoneNameLoop, langStrLoop in pairs(otherLanguagesNoDuplicateZoneName) do
                            local label = string.format("%s|caaaaaa - %s", cleanTranslatedZoneNameLoop, langStrLoop)
                            alreadyAddedCleanTranslatedZoneNames[zo_strlower(cleanTranslatedZoneNameLoop)] = label
                            alreadyAddedCleanTranslatedZoneNamesLookup[label] = cleanTranslatedZoneNameLoop
                        end
                    end
                    local autocomplete = MyAutoCompleteProvider:New(alreadyAddedCleanTranslatedZoneNames, alreadyAddedCleanTranslatedZoneNamesLookup, langToUse)
                    zoneSubCommand:SetAutoComplete(autocomplete)
                end
            end
        end
    end
end

function lib:buildLSCZoneSearchAutoComplete()
    --Get/Create instance of LibSlashCommander
    if self.LSC == nil then return nil end
    local libName = "[" .. libZone.name .."]"
    self.commandLzt     = self.LSC:Register({"/lzt", "/transz"}, nil, libName .. translations[self.currentClientLanguage]["slashCommandDescriptionClient"])
    self.commandLztDE   = self.LSC:Register({"/lztde", "/transzde"}, nil, libName .. translations["de"]["slashCommandDescription"])
    self.commandLztEN   = self.LSC:Register({"/lzten", "/transzen"}, nil, libName .. translations["en"]["slashCommandDescription"])
    self.commandLztFR   = self.LSC:Register({"/lztfr", "/transzfr"}, nil, libName .. translations["fr"]["slashCommandDescription"])
    self.commandLztJP   = self.LSC:Register({"/lztjp", "/transzjp"}, nil, libName .. translations["jp"]["slashCommandDescription"])
    self.commandLztRU   = self.LSC:Register({"/lztru", "/transzru"}, nil, libName .. translations["ru"]["slashCommandDescription"])
    self.commandLztPL   = self.LSC:Register({"/lztpl", "/transzpl"}, nil, libName .. translations["pl"]["slashCommandDescription"])
    self:buildAutoComplete(self.commandLzt, self.currentClientLanguage)
    self:buildAutoComplete(self.commandLztDE, "de")
    self:buildAutoComplete(self.commandLztEN, "en")
    self:buildAutoComplete(self.commandLztFR, "fr")
    self:buildAutoComplete(self.commandLztJP, "jp")
    self:buildAutoComplete(self.commandLztRU, "ru")
    self:buildAutoComplete(self.commandLztPL, "pl")
end

------------------------------------------------------------------------
-- 	Addon/Librray load functions
------------------------------------------------------------------------
--Addon loaded function
local function OnLibraryLoaded(event, name)
    --Only load lib if ingame
    if name:find("^ZO_") then return end
    if name  == libZone.name then
        EVENT_MANAGER:UnregisterForEvent(libZone.name, EVENT_ADD_ON_LOADED)

        --Load SavedVariables
        librarySavedVariables()

        --EVENT_MANAGER:RegisterForEvent(lib.name, EVENT_ZONE_CHANGED, OnZoneChanged)
        --Did the API version change since last zoneID check? Then rebuild the zoneIDs now!
        local currentAPIVersion = GetAPIVersion()
        lib.currentAPIVersion = currentAPIVersion
        lib.currentClientLanguage = GetCVar("language.2")
        --local lastCheckedZoneAPIVersion
        --local lastCheckedZoneAPIVersionOfLanguages = lib.zoneData.lastZoneCheckAPIVersion
        --if lastCheckedZoneAPIVersionOfLanguages ~= nil then
        --    lastCheckedZoneAPIVersion = lastCheckedZoneAPIVersionOfLanguages[lib.currentClientLanguage]
        --end
        local lastCheckedZoneAPIVersion = nil -- temporarily set to nil so the scan of missing names is always done
        --Get localized (client language) zone data and add missing deltat to SavedVariables (No reloadui!)
        local forceZoneIdUpdateDueToAPIChange = (lastCheckedZoneAPIVersion == nil or lastCheckedZoneAPIVersion ~= currentAPIVersion) or false
        lib:GetAllZoneDataById(forceZoneIdUpdateDueToAPIChange, false)
        --Do we have already datamined and localized zoneData given for other (non-client) languages? -> See file LibZone_Data.lua
        checkOtherLanguagesZoneDataAndTransferFromSavedVariables()
        --Build the libSlashCommander autocomplete stuff
        lib:buildLSCZoneSearchAutoComplete()
    end
end

--Load the addon now
EVENT_MANAGER:UnregisterForEvent(libZone.name, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(libZone.name, EVENT_ADD_ON_LOADED, OnLibraryLoaded)