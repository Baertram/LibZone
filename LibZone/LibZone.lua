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
libZone.version     = 0.3
--SavedVariables info
libZone.svDataName  = "LibZone_SV_Data"
libZone.svLocalizedDataName = "LibZone_Localized_SV_Data"
libZone.svVersion   = 0.3
libZone.maxZoneIds  = 3000 -- API100025, Murkmire

------------------------------------------------------------------------
-- 	Library creation
------------------------------------------------------------------------
local lib, oldminor = LibStub:NewLibrary(libZone.name, libZone.version)
if not lib then return end -- the same or newer version of this lib is already loaded into memory

------------------------------------------------------------------------
-- 	Global variables
------------------------------------------------------------------------
LibZone = LibZone or {}
--Assign LibStub created library instance of LibZone (lib) to global variable (LibZone)
LibZone = lib
LibZone.libraryInfo = libZone
LibZone.oldMinor = oldminor

------------------------------------------------------------------------
-- 	Local variables, global for the library
------------------------------------------------------------------------
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
}
local translations = {
    ["de"] = {
        ["de"]  = "Deutsch",
        ["en"]  = "Englisch",
        ["fr"]  = "Französisch",
        ["jp"]  = "Japanisch",
        ["ru"]  = "Russisch",
        ["slashCommandDescription"] = "Suche übersetzte Zonen Namen",
    },
    ["en"] = {
        ["de"]  = "German",
        ["en"]  = "English",
        ["fr"]  = "French",
        ["jp"]  = "Japanese",
        ["ru"]  = "Russian",
        ["slashCommandDescription"] = "Search translations of zone names",
    },
    ["fr"] = {
        ["de"]  = "Allemand",
        ["en"]  = "Anglais",
        ["fr"]  = "Français",
        ["jp"]  = "Japonais",
        ["ru"]  = "Russe",
        ["slashCommandDescription"] = "Rechercher des traductions de noms de zones",
    },
    ["jp"] = {
        ["de"]  = "ドイツ語",
        ["en"]  = "英語",
        ["fr"]  = "フランス語",
        ["jp"]  = "日本語",
        ["ru"]  = "ロシア",
        ["slashCommandDescription"] = "ゾーン名の翻訳を検索する",
    },
    ["ru"] = {
        ["de"]  = "Нeмeцкий",
        ["en"]  = "Aнглийcкий",
        ["fr"]  = "Фpaнцузcкий",
        ["jp"]  = "Япoнcкий",
        ["ru"]  = "Pуccкий",
        ["slashCommandDescription"] = "Поиск переводов названий зон",
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

--Load the SavedVariables
local function librarySavedVariables()
    lib.worldName = GetWorldName()
    local defaultZoneData = {}
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    lib.zoneData = ZO_SavedVars:NewAccountWide(libZone.svDataName, libZone.svVersion, "ZoneData", defaultZoneData, lib.worldName)
    lib.localizedZoneData = ZO_SavedVars:NewAccountWide(libZone.svLocalizedDataName, libZone.svVersion, "ZoneData", defaultZoneData, lib.worldName)
end

--Check other langauges than the client language: Is there any zoneData given?
local function checkOtherLanguagesZoneDataAndTransferToSavedVariables()
    local givenZoneDataTable = lib.givenZoneData
    if givenZoneDataTable ~= nil then
        local clientLanguage = lib.currentClientLanguage
        --Check each given language data
        for givenZoneDataLanguage, givenZoneDataForLanguage in pairs(givenZoneDataTable) do
            --Do not check the current client language data as this will be automatically in the SavedVariables already
            --> Each other language needs to be added manually via a SetCVar("language.2", "fr") e.g., or will be taken from
            --> the given datamined localized zone data
            if givenZoneDataLanguage ~= clientLanguage then
                --Check if the data is inside the SavedVariables already
                local zoneDataForLanguage = lib.localizedZoneData[givenZoneDataLanguage]
                --SavedVars got no entry with this language so far
                if zoneDataForLanguage == nil then
                    --Add the givenZoneData for the currently checked givenZoneData language to the SavedVars now
                    lib.localizedZoneData[givenZoneDataLanguage] = {}
                    lib.localizedZoneData[givenZoneDataLanguage] = givenZoneDataForLanguage
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- 	Library functions
------------------------------------------------------------------------
--Check and get all zone's data and save them to the SavedVariables. This will only use the current client's language!
--Parameters:
-->reBuildNew: Boolean [true=Rebuild the zoneData for all zones, even if they already exist / false=Skip already existing zoneIds]
-->doReloadUI: Boolean [true=If at least one zoneId was added/updated, do a ReloadUI() at the end to update the SavaedVariables now / false=No autoamtic ReloadUI()]
function lib:GetAllZoneDataById(reBuildNew, doReloadUI)
    reBuildNew = reBuildNew or false
    doReloadUI = doReloadUI or false
    --Maximum of ZoneIds to check
    local maxZoneId = libZone.maxZoneIds
    --Client language
    local lang = self.currentClientLanguage
    if lang == nil then return false end
    --Local SavedVariable data
    local zoneData = self.zoneData
    local localizedZoneData = self.zoneData[lang]
    if zoneData == nil then
        self.zoneData = {}
        zoneData = self.zoneData
    end
    if localizedZoneData == nil then
        self.localizedZoneData[lang] = {}
        localizedZoneData = self.localizedZoneData[lang]
    end
    if zoneData == nil or localizedZoneData == nil then return false end
    --Loop over all zone Ids and get it's data + name
    local addedAtLeastOne = false
    for zoneId = 1, maxZoneId, 1 do
        local zoneName = GetZoneNameById(zoneId)
        if zoneName ~= nil and zoneName ~= "" then
            local wasCreatedNew = false
            if zoneData[zoneId] == nil then
                wasCreatedNew = true
                zoneData[zoneId] = {}
            end
            if localizedZoneData[zoneId] == nil then
                wasCreatedNew = true
                localizedZoneData[zoneId] = {}
            end
            if reBuildNew or wasCreatedNew then
                addedAtLeastOne = true
                local zoneDataForId = zoneData[zoneId]
                --Set localized zone name
                localizedZoneData[zoneId] = ZO_CachedStrFormat("<<C:1>>", zoneName)
                --Set zone index
                if zoneDataForId.zoneIndex == nil then
                    local zoneIndexOfZoneId = GetZoneIndex(zoneId)
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
        self.zoneData.lastZoneCheckAPIVersion = currentAPIVersion
        --Reload the UI now to update teh SavedVariables?
        if doReloadUI then ReloadUI() end
    end
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
    local localizedZoneData = self.localizedZoneData[language]
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
        d("[LibZone]ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\", language: \"" .. tostring(language) .. "\"")
        d(">Zone name: " .. tostring(zoneIdData.name))
        if zoneIdData.zoneIndex ~= nil then d(">Zone index: " .. tostring(zoneIdData.zoneIndex)) end
        if subZoneIdData ~= nil then
            d(">>SubZone name: " .. tostring(subZoneIdData.name))
            if subZoneIdData.zoneIndex ~= nil then d(">SubZone index: " .. tostring(subZoneIdData.zoneIndex)) end
        end
    else
        d("[LibZone]ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\"\nNo zone data was found for language \"" .. tostring(language) .. "\"!")
    end
end


--Get the localized zone name by help of a zoneId
--zoneId: Number containing zoneId
--language: The language to use for the zoneName
--->Returns localized String of the zoneName
function lib:GetZoneName(zoneId, language)
    assert(zoneId ~= nil, "[LibZone:GetZoneName]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local localizedZoneIdData = self.localizedZoneData[language]
    if localizedZoneIdData == nil then
        local retName = ""
        --Is the language the client language?
        if language == self.currentClientLanguage then
            --Get the zone name by the help of API function
            retName = GetZoneNameById(zoneId)
            if retName ~= nil and retName ~= "" then
                --Add the name to the SavedVariables now
                if self.localizedZoneData[language] == nil then self.localizedZoneData[language] = {} end
                if self.localizedZoneData[language] ~= nil then
                    if self.localizedZoneData[language][zoneId] == nil then
                        self.localizedZoneData[language][zoneId] = retName
                    end
                end
            end
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
    local localizedSearchZoneData = self.localizedZoneData[searchLanguage]
    assert (localizedSearchZoneData ~= nil, "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing localized search zone data with language \"" .. tostring(searchLanguage) .. "\"!")
    local zoneReturnLocalizedData = self.localizedZoneData[returnLanguage]
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

function lib:buildLSCZoneSearchAutoComplete()
    --Get/Create instance of LibSlashCommander
    local LSC = LibStub("LibSlashCommander")
    if LSC == nil then return nil end
    self.command = LSC:Register({"/lzt", "/transz"}, nil, "[LibZone]" .. translations[self.currentClientLanguage]["slashCommandDescription"])

    local MyAutoCompleteProvider = LSC.AutoCompleteProvider:Subclass()
    function MyAutoCompleteProvider:New(resultList, lookupList)
        local obj = LSC.AutoCompleteProvider.New(self)
        obj.resultList = resultList
        obj.lookupList = lookupList
        return obj
    end

    function MyAutoCompleteProvider:GetResultList()
        return self.resultList
    end

    function MyAutoCompleteProvider:GetResultFromLabel(label)
        return self.lookupList[label] or label
    end

    --Add sub commands for the zoneNames
    local localizedZoneDataForClientLang = self.localizedZoneData[self.currentClientLanguage]
    if localizedZoneDataForClientLang ~= nil then
        local clientLangUpper = translations[self.currentClientLanguage][self.currentClientLanguage]
        for zoneId, zoneName in pairs(localizedZoneDataForClientLang) do
            --Check if the zoneIds are blacklisted
            local isZoneBlacklisted = blacklistedZoneIdsForAutoCompletion[zoneId] or false
            if not isZoneBlacklisted then
                --Replace the spaces in the zone name so LibSlashCommander will find them with the auto complete properly
                local repStr = "·"
                local zoneNameNoSpaces = string.gsub(zoneName, " ", repStr)
                --Add a zone entry as subcommand so the first auto complete will show all zone names as the user types /lzt into chat
                local zoneSubCommand = self.command:RegisterSubCommand()
                zoneSubCommand:AddAlias(zoneNameNoSpaces)
                zoneSubCommand:SetDescription(clientLangUpper)
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
                        local upperLangStr = translations[self.currentClientLanguage][lang]
                        if otherLanguagesNoDuplicateZoneName[cleanTranslatedZoneName] == nil then
                            langStr = ""
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
                local autocomplete = MyAutoCompleteProvider:New(alreadyAddedCleanTranslatedZoneNames, alreadyAddedCleanTranslatedZoneNamesLookup)
                zoneSubCommand:SetAutoComplete(autocomplete)
            end
        end
    end
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
        local lastCheckedZoneAPIVersion = lib.zoneData.lastZoneCheckAPIVersion
        local currentAPIVersion = GetAPIVersion()
        lib.currentAPIVersion = currentAPIVersion
        lib.currentClientLanguage = GetCVar("language.2")

        --Get localized (client language) zone data to SavedVariables (No reloadui!)
        local forceZoneIdUpdateDueToAPIChange = (lastCheckedZoneAPIVersion == nil or lastCheckedZoneAPIVersion ~= currentAPIVersion) or false
        lib:GetAllZoneDataById(forceZoneIdUpdateDueToAPIChange, false)
        --Do we have already datamined and localized zoneData given for other (non-client) languages?
        checkOtherLanguagesZoneDataAndTransferToSavedVariables()
        --Build the libSlashCommander autocomplete stuff
        lib:buildLSCZoneSearchAutoComplete()
    end
end

--Load the addon now
EVENT_MANAGER:UnregisterForEvent(libZone.name, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(libZone.name, EVENT_ADD_ON_LOADED, OnLibraryLoaded)
