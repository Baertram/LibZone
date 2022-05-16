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

LibZone = LibZone or {}

local lib = LibZone
local libZone = lib.libraryInfo
local libraryName = libZone.name

local apiVersion = GetAPIVersion()
local clientLang = lib.currentClientLanguage

--For SV update
local isAddonDevOfLibZone = (GetDisplayName() == '@Baertram' and true) or false

local pubDungeons
local poiDataTable = {}

------------------------------------------------------------------------
-- 	Helper functions
------------------------------------------------------------------------
local checkIfLanguageIsSupported = lib.checkIfLanguageIsSupported

--Get the maximum possible zoneIndex and zoneId
local function getMaxZoneIndicesAndIds()
    local numZoneIndices = GetNumZones()
    local maxZoneIds = 0
    for zoneIndex=0, numZoneIndices do
        local zoneId = GetZoneId(zoneIndex)
        if zoneId and zoneId > maxZoneIds then
            maxZoneIds = zoneId
        end
    end
    return numZoneIndices, maxZoneIds
end

--Load the SavedVariables and connect the tables of the library with the SavedVariable tables.
--The following table will be stored and read to/from the SavedVariables:
--LibZone.zoneData:             LibZone_SV_Data             -> zoneIds and parentZoneIds
--LibZone.localizedZoneData:    LibZone_Localized_SV_Data   -> zoneNames, with different languages
---> This table only helds the "delta" between the scanned zoneIds + language and the preloaded data in file LibZone_Data.lua, table preloadedZoneNames
local function librarySavedVariables()
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
--The preloaded zoneNames table LibZone.preloadedZoneNames in file LibZone_Data.lua (other languages e.g.) will be enriched with new scanned data from
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
        if checkIfLanguageIsSupported(clientLanguage) == true and localizedZoneDataSV and localizedZoneDataSV[clientLanguage] then
            --Get the preloaded data for the supported language (client language)
            local preloadedZoneNamesForLanguage = preloadedZoneNamesTable[clientLanguage]
            local localizedZoneDataSVForLanguage = localizedZoneDataSV[clientLanguage]
            if preloadedZoneNamesForLanguage and localizedZoneDataSVForLanguage then
                --Check for each zoneId in the zoneData table
                if not lib.maxZoneIds or lib.maxZoneIds == 0 then
                    lib.maxZoneIndices, lib.maxZoneIds = getMaxZoneIndicesAndIds()
                end
                local maxZoneIds = lib.maxZoneIds
                --Check for all possible zones now, from 0 to maximum
                for zoneId = 0, maxZoneIds, 1 do
                    --Check if zoneId is valid in zoneData and if the entries are missing in the preloaded data language table for the current client language
                    --but already scanned and given in the SavedVariables
                    if zoneData[zoneId] and (not preloadedZoneNamesForLanguage[zoneId] and localizedZoneDataSVForLanguage[zoneId]) then
                        --Add the entries to the preloadedZoneNames table for the client language
                        preloadedZoneNamesTable[clientLanguage][zoneId] = localizedZoneDataSVForLanguage[zoneId]
                    end
                end
            else
                --Table with the zoneNames in this language is missing in total
                --So get the data from the SavedVariables once (if it exists)
                if localizedZoneDataSV and localizedZoneDataSV[clientLanguage] then
                    preloadedZoneNamesForLanguage = localizedZoneDataSV[clientLanguage]
                    --Kyoma on 2020-04-13: Assigned table preloadedZoneNamesForLanguage is not updating referenced table preloadedZoneNamesTable[clientLanguage], so directly access it
                    --preloadedZoneNamesTable[clientLanguage] = localizedZoneDataSV[clientLanguage]
                end
            end
        end
    end
end

-- This table contains parentZoneId modifiers for select zones.
local geographicalParentZoneId = {
	[678] = 181, -- Imperial City Prison, force the use of Cyrodiil
	[688] = 181, -- White-Gold Tower, force the use of Cyrodiil
	[1027] = 1027, -- Artaeum. Normally is Summerset.
	[1283] = 1283, -- The Shambles. Normally is Fargrave  City District.
--	[1283] = 1283, -- Fargrave. set to use Faregrave instead of Fargrave City District.
	
	-- The parentZoneId for the following normally are the same as zoneId.
	[1005] = 823, -- Linchal Grand Manor
	[1108] = 726, -- Lakemire Xanmeer Manor.
	[1200] = 92, -- Thieves' Oasis.
	[1264] = 1207, -- Stone Eagle Aerie
	[1109] = 101, -- Enchanted Snow Globe
	[1125] = 101, -- Frostvault Chasm
}
--Build the data table for poi indices to be added to subzone data.
-- Creates table:
-- poiDataTable = {
--   [tblIndex number or string] = {
--		[number] = {
--				["poiIndex"] = number,
--				["poiZoneIndex"] = number, zone index of zone the poi is on.
--			}
--    },
--}
local wayShrineString = GetString(SI_DEATH_PROMPT_WAYSHRINE)
local function buildPoiDataTable()
	-- The initial data is for zones that do not match up properly by name.
	poiDataTable = {
		[469] = { -- Tomb of Apostates
			{
				["poiIndex"] = 35,
				["poiZoneIndex"] = 11,
			}
		},
		[913] = { -- The Mage's Staff/Spellscar
			{
				["poiIndex"] = 9,
				["poiZoneIndex"] = 500,
			}
		},
		[915] = { -- Skyreach Temple. Located inside Loth'Na Caverns. This will point to Loth'Na Caverns to show where it is.
			{
				["poiIndex"] = 18,
				["poiZoneIndex"] = 500,
			}
		},
		[1080] = { -- Dungeon: Frostvault can get mistaken as Frostvault Chasm
			[101] = {
				["poiIndex"] = 60,
				["poiZoneIndex"] = 15,
			}
		},
		[1125] = { -- Frostvault Chasm to be safe.
			[101] = {
				["poiIndex"] = 61,
				["poiZoneIndex"] = 15,
			}
		},
	}

   --d("[LibZone]GetAllZoneDataById, reBuildNew: " ..tostring(reBuildNew) .. ", doReloadUI: " ..tostring(doReloadUI) .. ", lang: " .. tostring(lang))
    --Maximum of ZoneIds to check
    if lib.maxZoneIndices or lib.maxZoneIndices == 0 then
        --Get the maximum possible zoneIndex and zoneId
        lib.maxZoneIndices, lib.maxZoneIds = getMaxZoneIndicesAndIds()
    end
    local maxZoneIndices = lib.maxZoneIndices
    assert(maxZoneIndices ~= nil, "[\'" .. libraryName .. "\':GetAllZoneDataById]Error: Missing maxZoneIndices!")
	
    --for zoneId = 1, maxZoneId, 1 do
    for zoneIndexOfZoneId=0, maxZoneIndices do
		local poiCount = GetNumPOIs(zoneIndexOfZoneId)
	
		for poiIndex = 1, poiCount do
			local poiName = GetPOIInfo(zoneIndexOfZoneId, poiIndex)
			--Exclude wayshrines.
			if poiName ~= '' and not poiName:match(wayShrineString) then
				local zoneId = GetZoneId(zoneIndexOfZoneId)
				local zoneName = GetZoneNameById(zoneId)
				zoneName = zoneName:lower()
				
				local entry = {
					poiIndex = poiIndex,
					poiZoneIndex = zoneIndexOfZoneId, -- the parent zoneIndex
				}

				poiName = ZO_CachedStrFormat(SI_ZONE_NAME, poiName):lower()

				if poiDataTable[poiName] and poiName:find(' i$') ~= nil then
					-- we need to add an 'i' to darkshade caverns ii the other dungeons already have this for 2nd.
					poiName = poiName .. 'i'
				end

				local entryData = poiDataTable[poiName] or {}
				entryData[zoneId] = entry
				poiDataTable[poiName] = entryData
			end
		end
	end
end

-- returns number based on string length difference.
local function comparePoiNames(poiName, zoneName)
	local reversePoiName = poiName:gsub('^(%S+) (.*)$', '%2 %1')
	local reverseZoneName = zoneName:gsub('^(%S+) (.*)$', '%2 %1')
	if poiName:find(zoneName, 1, true) ~= nil
		or reversePoiName:find(zoneName, 1, true) ~= nil
		or reverseZoneName:find(poiName, 1, true) ~= nil
		or zoneName:match('^' .. poiName .. '$') ~= nil then

		return math.abs(#poiName - #zoneName)
	end
end

-- Returns the table containing pin info that matches the zoneName.
local function getPinInfoByName(zoneName)
	local result, match

	for poiName, pinInfo in pairs(poiDataTable) do
		if type(poiName) == 'string' then
			local score = comparePoiNames(poiName, zoneName)

			if score then
				if not match or score < match then
					match = score
					result = pinInfo
				end
			end
		end
	end

	if match then
		return result
	end
end

-->Returns: number parentZoneId, table pinInfo
--->pinInfo = {
--		["poiIndex"] = number,
--		["poiZoneIndex"] = number,
--->}
local function getPinInfo(zoneId, parentZoneId)
	parentZoneId = geographicalParentZoneId[zoneId] or parentZoneId

	-- Get poiData base on zoneId. poiData is 1 or more tables of poi indices.
	local poiData = poiDataTable[zoneId]

	if not poiData and zoneId ~= parentZoneId then
		-- Get poiData base on zoneName.
		poiData = getPinInfoByName(GetZoneNameById(zoneId):lower())
	end
	
	local pinInfo
	if poiData then
		-- Get table of indices from poiData that match the parentZoneId
		pinInfo = poiData[parentZoneId]
		
		if not pinInfo then
			-- if the parentZoneId does not match the table, use first entry. The static entries use this.
			parentZoneId, pinInfo = next(poiData)
		end
	end
	
	return parentZoneId, pinInfo
end

------------------------------------------------------------------------
-- 	Library functions
------------------------------------------------------------------------
--Get the current map's zoneIndex and via the index get the zoneId, the parent zoneId, and return them
--+ the current zone's index and parent zone index
--> Returns: number currentZoneId, number currentZoneParentId, number currentZoneIndex, number currentZoneParentIndex, number mapId, number mapIndex
function lib:GetCurrentZoneIds()
    local currentZoneIndex = GetCurrentMapZoneIndex()
    local currentZoneId = GetZoneId(currentZoneIndex)
    local currentZoneParentId = GetParentZoneId(currentZoneId)
    local currentZoneParentIndex = GetZoneIndex(currentZoneParentId)
    local mapId = GetCurrentMapId()
    local mapIndex = GetCurrentMapIndex()
    return currentZoneId, currentZoneParentId, currentZoneIndex, currentZoneParentIndex, mapId, mapIndex
end

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
    --d("[LibZone]GetAllZoneDataById, reBuildNew: " ..tostring(reBuildNew) .. ", doReloadUI: " ..tostring(doReloadUI) .. ", lang: " .. tostring(lang))
    --Maximum of ZoneIds to check
    if self.maxZoneIndices or self.maxZoneIndices == 0 then
        --Get the maximum possible zoneIndex and zoneId
        self.maxZoneIndices, self.maxZoneIds = getMaxZoneIndicesAndIds()
    end
    local maxZoneIndices = self.maxZoneIndices
    assert(maxZoneIndices ~= nil, "[\'" .. libraryName .. "\':GetAllZoneDataById]Error: Missing maxZoneIndices!")
    --Local SavedVariable data
    local zoneData = self.zoneData
    if zoneData == nil then
        self.zoneData = {}
        zoneData = self.zoneData
    end
    local localizedZoneDataSV = self.localizedZoneData[lang]
    if zoneData == nil then return false end
    local preloadedZoneNamesTable = self.preloadedZoneNames[lang]
    --The preloaded zoneData does not exist for the whole language
    local languageIsMissingInTotal = false
    if preloadedZoneNamesTable == nil then
        languageIsMissingInTotal = true
    end
    --d(">languageIsMissingInTotal: " ..tostring(languageIsMissingInTotal))
    --Loop over all zone Ids and get it's data + name
    local addedAtLeastOne = false

	-- Create the table used to add poiInfo to zoneData
	buildPoiDataTable()

    --for zoneId = 1, maxZoneId, 1 do
    for zoneIndexOfZoneId=0, maxZoneIndices do
        local zoneId = GetZoneId(zoneIndexOfZoneId)
        --d(">>Checking zoneId: " ..tostring(zoneId) .. ", preloadedZoneNamesTable[zoneId]: " .. tostring(preloadedZoneNamesTable[zoneId]) .. ", zoneIndexOfZoneId: " ..tostring(zoneIndexOfZoneId))
        if zoneId and zoneIndexOfZoneId and zoneIndexOfZoneId ~= 1 then -- zoneIndex 1 is for all the zones which got no name (hopefully)
            local wasCreatedNew = false
            --local zoneIndexOfZoneId = GetZoneIndex(zoneId)
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
				-- Get parentZoneId and pinInfo.
				-- The parentZoneId is based on geographical location.
				-- pinInfo is table of map pin indices {poiIndex = number, poiZoneIndex = number}
				local parentZoneId, pinInfo = getPinInfo(zoneId, GetParentZoneId(zoneId))
                --Set zone parent
				if zoneDataForId.parentZone == nil then
					zoneDataForId.parentZone = parentZoneId
				end
				-- If pinInfo then add it to zone data.
				if pinInfo then
					zoneDataForId.pinInfo = pinInfo
				end
            end
        end
    end
    --Was at least one zoneId added/changed?
    if addedAtLeastOne then
        --Update the API version as the zoneIds check was done
        local currentAPIVersion = self.currentAPIVersion
        self.zoneData.lastZoneCheckAPIVersion = self.zoneData.lastZoneCheckAPIVersion or {}
        self.zoneData.lastZoneCheckAPIVersion[lang] = currentAPIVersion
        --Reload the UI now to update teh SavedVariables?
        --Add the current API version to the language table so one knows when the data was collected
        if localizedZoneDataSV then
            localizedZoneDataSV["lastUpdate"] = GetTimeStamp()
            localizedZoneDataSV["APIVersionAtLastUpdate"] = currentAPIVersion
        end
        --and add a timestamp
        if doReloadUI then ReloadUI() end
    end

	-- Clear the poiDataTable
	poiDataTable = nil
end


--Return the zoneData for all zones and all languages
-->Returns table:
--->returnTable = {
--->    [language] = {
----->    [zoneId] = "zoneName"
--->    },
--->}
function lib:GetAllZoneData()
    return self.preloadedZoneNames
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
    assert (subZoneId ~= nil, "[\'" .. libraryName .. "\':GetZoneDataBySubZone]Error: Missing SubZoneId!")
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
    assert (zoneId ~= nil, "[\'" .. libraryName .. "\':GetZoneData]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local readZoneData, readSubZoneData
    local zoneData =  self.zoneData
    local localizedZoneData = self.preloadedZoneNames[language]
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
        d("[\'".. libraryName .. "\':GetZoneData]Error: Missing zoneData for language \"" .. tostring(language) .. "\"!")
    end
    return readZoneData, readSubZoneData
end

--Show existing zone data to the chat now
--Output zone informtaion to the chat, using the zoneId, subZoneId (connected to zoneId via parentZoneId) and the language (e.g. "en" or "fr")
function lib:ShowZoneData(zoneId, subZoneId, language)
    assert (zoneId ~= nil, "[\'" .. libraryName .. "\':ShowZoneData]Error: Missing zoneId!")
    language = language or self.currentClientLanguage
    local zoneIdData, subZoneIdData = self:GetZoneData(zoneId, subZoneId, language)
    if zoneIdData ~= nil then
        d("[" .. libraryName .. "]ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\", language: \"" .. tostring(language) .. "\"")
        d(">Zone name: " .. tostring(zoneIdData.name))
        if zoneIdData.zoneIndex ~= nil then d(">Zone index: " .. tostring(zoneIdData.zoneIndex)) end
        if subZoneIdData ~= nil then
            d(">>SubZone name: " .. tostring(subZoneIdData.name))
            if subZoneIdData.zoneIndex ~= nil then d(">SubZone index: " .. tostring(subZoneIdData.zoneIndex)) end
        end
    else
        d("[\'" .. libraryName .. "\']ShowZoneData for zoneId \"".. tostring(zoneId) .. "\", subZoneId: \"".. tostring(subZoneId) .. "\"\nNo zone data was found for language \"" .. tostring(language) .. "\"!")
    end
end


--Get the localized zone name by help of a zoneId
--zoneId: Number containing zoneId
--language: The language to use for the zoneName
--->Returns localized String of the zoneName
function lib:GetZoneName(zoneId, language)
    assert(zoneId ~= nil, "[\'" .. libraryName .. "\':GetZoneName]Error: Missing zoneId!")
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
    assert (zoneIdsTable ~= nil and type(zoneIdsTable) == "table", "[\'" .. libraryName .. "\':GetZoneNamesByIds]Error: Missing zoneId table.\nTable's format must be \"[number TableIndex] = number ZoneId,\"!")
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
    assert (zoneIdsTable ~= nil and type(zoneIdsTable) == "table", "[\'" .. libraryName .. "\':GetZoneDataByIds]Error: Missing zoneId table.\nTable's format must be \"[number TableIndex] = number ZoneId,\"!")
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
    assert (searchStr ~= nil and searchStr ~= "", "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Missing parameter \"searchStr\"!")
    assert (returnLanguage ~= nil and type(returnLanguage) == "string", "[LibZone:GetZoneNameByLocalizedSearchString]Error: Missing or wrong parameter \"returnLanguage\"!")
    local langIsSupported = checkIfLanguageIsSupported(returnLanguage) or false
    assert (langIsSupported == true, "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Return language \"" .. tostring(returnLanguage) .. "\" is not supported!")
    langIsSupported = false
    searchLanguage = searchLanguage or self.currentClientLanguage
    --Disabled 2021-04-15, upon request of "SimonIllyan" here: https://www.esoui.com/downloads/info2171-LibZone.html#comments
    --assert (searchLanguage ~= returnLanguage, "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Search language and returning language must be different!")
    langIsSupported = checkIfLanguageIsSupported(searchLanguage) or false
    assert (langIsSupported == true, "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Search language \"" .. tostring(searchLanguage) .. "\" is not supported!")
    local retZoneIdsTable = {}
    local retZoneLocalizedZoneNamesTable = {}
    local localizedSearchZoneData = self.preloadedZoneNames[searchLanguage]
    assert (localizedSearchZoneData ~= nil, "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Missing localized search zone data with language \"" .. tostring(searchLanguage) .. "\"!")
    local zoneReturnLocalizedData = self.preloadedZoneNames[returnLanguage]
    assert (zoneReturnLocalizedData ~= nil, "[\'" .. libraryName .. "\':GetZoneNameByLocalizedSearchString]Error: Missing localized return zone data with language \"" .. tostring(returnLanguage) .. "\"!")
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

--Function to return the maximum zoneId and the maximum zoneIndex possible within the game
--> Returns: number maximumZoneId, number maximumZoneIndex
function lib:GetMaxZoneId()
    if self.maxZoneId == 0 or self.maxZoneIndices == 0 then
        --Get the maximum possible zoneIndex and zoneId
        self.maxZoneIndices, self.maxZoneIds = getMaxZoneIndicesAndIds()
    end
    return self.maxZoneIds, self.maxZoneIndices
end


--Get the zone and subZone string from the given map's tile texture (or the current's map's tile texture name)
--> Returns: string zoneName, string subZoneName, string mapTileTextureNameLowerCase, string mapTileTextureNameUnchangedComplete
function lib:GetZoneNameByMapTexture(mapTileTextureName, patternToUse, chatOutput)
    chatOutput = chatOutput or false
--[[
    Possible texture names are e.g.
    /art/maps/southernelsweyr/els_dragonguard_island05_base_8.dds
    /art/maps/murkmire/tsofeercavern01_1.dds
    /art/maps/housing/blackreachcrypts.base_0.dds
    /art/maps/housing/blackreachcrypts.base_1.dds
    Art/maps/skyrim/blackreach_base_0.dds
    Textures/maps/summerset/alinor_base.dds
]]
    mapTileTextureName = mapTileTextureName or GetMapTileTexture()
    if not mapTileTextureName or mapTileTextureName == "" then return end
    local mapTileTextureNameLower = mapTileTextureName:lower()
    mapTileTextureNameLower = mapTileTextureNameLower:gsub("ui_map_", "")
    --mapTileTextureNameLower = mapTileTextureNameLower:gsub(".base", "_base")
    --mapTileTextureNameLower = mapTileTextureNameLower:gsub("[_+%d]*%.dds$", "") -> Will remove the 01_1 at the end of tsofeercavern01_1
    mapTileTextureNameLower = mapTileTextureNameLower:gsub("%.dds$", "")
    mapTileTextureNameLower = mapTileTextureNameLower:gsub("_%d*$", "")
    local regexData = {}
    if not patternToUse or patternToUse == "" then patternToUse = "([%/]?.*%/maps%/)(%w+)%/(.*)" end
    regexData = {mapTileTextureNameLower:find(patternToUse)} --maps/([%w%-]+/[%w%-]+[%._][%w%-]+(_%d)?)
    local zoneName, subzoneName = regexData[4], regexData[5]
    if chatOutput == true then
        d("["..libraryName.."]GetZoneNameByMapTexture\nzone: " ..tostring(zoneName) .. ", subZone: " .. tostring(subzoneName) .. "\nmapTileTexture: " .. tostring(mapTileTextureNameLower))
    end
    return zoneName, subzoneName, mapTileTextureNameLower, mapTileTextureName
end

local function getCurrentZoneAndGroupStatus()
    local isInPublicDungeon = false
    local isInGroupDungeon = false
    local isInAnyDungeon = false
    local isInRaid = false
    local isInDelve = false
    local isInGroup = false
    local groupSize = 0
    local isInPVP = false
    local playerVar = "player"

    isInPVP = IsPlayerInAvAWorld()
    isInAnyDungeon = IsAnyGroupMemberInDungeon()  -- returned true if not in group and in solo dungeon/delve until patch API???? Now it returns false
    isInGroup = IsUnitGrouped(playerVar)
    groupSize = GetGroupSize() --SMALL_GROUP_SIZE_THRESHOLD (4) / RAID_GROUP_SIZE_THRESHOLD (12) / GROUP_SIZE_MAX (24)
    isInRaid = IsPlayerInRaid()
    local isNotInRaidChecks = (not isInRaid and groupSize <= SMALL_GROUP_SIZE_THRESHOLD) or false
    if not isInAnyDungeon then
        isInAnyDungeon = (IsUnitInDungeon(playerVar) or GetMapContentType() == MAP_CONTENT_DUNGEON) or false
    end

    --Check if user is in any dungeon
	if isInAnyDungeon and isNotInRaidChecks then
        --Difficulty will be 0 if not in a dungeon, 1 if in a delve, 2 if elsewhere
        local dungeonDifficulty = ZO_WorldMap_GetMapDungeonDifficulty()
		-- if Difficulty is anything other than zero; it's a Group Dungeon
		if dungeonDifficulty > DUNGEON_DIFFICULTY_NONE then
			isInGroupDungeon = true
		else
		-- if Difficulty is zero; it's either a Delve or a Public Dungeon
		-- check the Public Dungeons list first
			pubDungeons = pubDungeons or lib.publicDungeonMapIds
			local _, _, _, _, mapId, _ = lib:GetCurrentZoneIds()
            if mapId ~= nil then
                isInPublicDungeon = pubDungeons[mapId] or false
            end

		-- if it isn't a Public Dungeon, it's a Delve
			isInDelve = not isInPublicDungeon
		end
	end

    --[[
    --Check if user is in any dungeon
    --As there is no API to check for delves: We assume ungrouped + in normal dungeon = in delve
    --Difficulty in delves should be DUNGEON_DIFFICULTY_NONE
    isInGroupDungeon = (isInAnyDungeon and (dungeonDifficulty == DUNGEON_DIFFICULTY_NORMAL or DUNGEON_DIFFICULTY_VETERAN) and isNotInRaidChecks) or false
    isInDelve = (not isInGroupDungeon and (isInAnyDungeon and dungeonDifficulty == DUNGEON_DIFFICULTY_NONE) and isNotInRaidChecks) or false

    --Asuming we are in a delve: Check if the zoneId is the one of a public dungeon
    if isInAnyDungeon == true and not isInGroupDungeon then
        local pubDungeons = lib.publicDungeonMapIds
        local _, _, _, _, mapId, _ = lib:GetCurrentZoneIds()
        isInPublicDungeon = pubDungeons[mapId] or false
    end
    ]]

    --Get POI info for group and public dungeons
    --This wil only work if you are outside the PubDungeon, near it, where the map's POI is shown AND you are in the subzone of that map...
    --[[
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    --d(string.format(">zoneIndex: %s, poiIndex: %s", tostring(zoneIndex), tostring(poiIndex)))
    local abort = false
    if zoneIndex == nil then
        abort = true
    end
    if poiIndex == nil then
        abort = true
    end
    if not abort then
        local _, _, _, iconPath = GetPOIMapInfo(zoneIndex, poiIndex)
        local iconPathLower = iconPath:lower()
        --d(">iconPathLower: "..tostring(iconPathLower))
        if iconPathLower:find("poi_delve") then
            -- in a delve
            isInDelve = true
        end
        if not isInPublicDungeon then
            isInPublicDungeon = IsPOIPublicDungeon(zoneIndex, poiIndex)
        end
        if not isInGroupDungeon then
            isInGroupDungeon  = IsPOIGroupDungeon(zoneIndex, poiIndex)
        end
        if isInPublicDungeon then
            isInDelve = false
            isInGroupDungeon = false
        elseif isInGroupDungeon then
            isInDelve = false
            isInPublicDungeon = false
        end
    end
    ]]
    --d("[LibZone.getCurrentZoneAndGroupStatus] PvP: " .. tostring(isInPVP) .. ", Delve: " .. tostring(isInDelve) .. ", PubDun: " .. tostring(isInPublicDungeon) .. ", GroupDun: " .. tostring(isInGroupDungeon) .. ", inGroup: " .. tostring(isInGroup) .. ", groupSize: " .. groupSize)
    return isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize
end

--Check if we are grouped and where we currently are (inside any dungen, Ava area)
--returns 6 booleans: isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup
--        1 number: groupSize
function lib:GetCurrentZoneAndGroupStatus()
    local isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize = getCurrentZoneAndGroupStatus()
    return isInPVP, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, isInGroup, groupSize
end

--Check if we are in a delve
function lib:IsInDelve()
    local _, isInDelve, _, _, _, _, _ = getCurrentZoneAndGroupStatus()
    return isInDelve -- in a delve
end

--Check if we are in a public dungeon
function lib:IsInPublicDungeon()
    local _, _, isInPublicDungeon, _, _, _, _ = getCurrentZoneAndGroupStatus()
    return isInPublicDungeon -- in a public dungeon
end

--Check if we are in a group dungeon
function lib:IsInGroupDungeon()
    local _, _, _, isInGroupDungeon, _, _, _ = getCurrentZoneAndGroupStatus()
    return isInGroupDungeon -- in a group dungeon
end

--Check if we are in a raid/trial
function lib:IsInTrial()
    local _, _, _, _, isInRaid, _, _ = getCurrentZoneAndGroupStatus()
    return isInRaid -- in a raid/trial
end

--Check if we are in any dungeon
function lib:IsInAnyDungeon()
    local _, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, _, _ = getCurrentZoneAndGroupStatus()
    return isInDelve or isInPublicDungeon or isInGroupDungeon or isInRaid
end

--Check if we are in any dungeon
--returns 4 booleans: isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid
function lib:GetCurrentDungeonType()
    local _, isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid, _, _ = getCurrentZoneAndGroupStatus()
    return isInDelve, isInPublicDungeon, isInGroupDungeon, isInRaid
end

--Check if we are in a house
function lib:IsInHouse()
    local currentHouseOwner = GetCurrentHouseOwner()
    local inHouse = ((currentHouseOwner ~= nil and currentHouseOwner ~= "") and GetCurrentZoneHouseId() ~= 0) or false
    if not inHouse then
        local x,y,z,rotRad = GetPlayerWorldPositionInHouse()
        if x == 0 and y == 0 and z == 0 and rotRad == 0 then
            return false -- not in a house
        end
    end
    return true -- in a house
end


--Check if we are in Cyrodiil (AvA zone)
function lib:IsInCyrodiil()
    return IsInCyrodiil()
end

--Check if we are in Imperial City (AvA zone)
function lib:IsInImperialCity()
    return IsInImperialCity()
end

--Check if we are in a battleground (AvA zone)
function lib:IsInBattleground()
    return IsActiveWorldBattleground()
end

--Check if we are in AvA / PvP
function lib:IsInPVP()
    return IsPlayerInAvAWorld()
end


local mapNamesWereBuild = false
local mapId2Name = {}
--Gte the namse of all the maps
function lib:GetMapNames(override)
    override = override or false
    if mapNamesWereBuild and not override then return mapId2Name end
    for mapId = 1, lib.maxMapIds do
        local mapName = ZO_CachedStrFormat("<<C:1>>", GetMapNameById(mapId))
        if mapName and mapName ~= "" then
            mapId2Name[mapId] = mapName
        end
    end
    mapNamesWereBuild = true
    lib.mapId2Name = mapId2Name
    --Update the SavedVariables
    if isAddonDevOfLibZone then
        lib.localizedZoneData.mapNames = lib.localizedZoneData.mapNames or {}
        lib.localizedZoneData.mapNames[apiVersion] = lib.localizedZoneData.mapNames[apiVersion] or {}
        lib.localizedZoneData.mapNames[apiVersion][clientLang] = mapId2Name
    end
    return mapId2Name
end

------------------------------------------------------------------------
-- 	Addon/Librray load functions
------------------------------------------------------------------------
--Addon loaded function
local function OnLibraryLoaded(event, name)
    --Only load lib if ingame
    if name:find("^ZO_") then return end
    if name  == libraryName then
        EVENT_MANAGER:UnregisterForEvent(libraryName, EVENT_ADD_ON_LOADED)

        --Get the maximum possible zoneIndex and zoneId
        lib.maxZoneIndices, lib.maxZoneIds = getMaxZoneIndicesAndIds()

        --Load SavedVariables
        librarySavedVariables()
		
        --EVENT_MANAGER:RegisterForEvent(lib.name, EVENT_ZONE_CHANGED, OnZoneChanged)
        --Did the API version change since last zoneID check? Then rebuild the zoneIDs now!
        local currentAPIVersion = lib.currentAPIVersion
        lib.currentClientLanguage = lib.currentClientLanguage or GetCVar("language.2")
        local lastCheckedZoneAPIVersion
        local lastCheckedZoneAPIVersionOfLanguages = lib.zoneData.lastZoneCheckAPIVersion
        if lastCheckedZoneAPIVersionOfLanguages ~= nil then
            lastCheckedZoneAPIVersion = lastCheckedZoneAPIVersionOfLanguages[lib.currentClientLanguage]
        end
        --Get localized (client language) zone data and add missing deltat to SavedVariables (No reloadui!)
        local forceZoneIdUpdateDueToAPIChange = (lastCheckedZoneAPIVersion == nil or lastCheckedZoneAPIVersion ~= currentAPIVersion) or false
        lib:GetAllZoneDataById(forceZoneIdUpdateDueToAPIChange, false)
        --Do we have already datamined and localized zoneData given for other (non-client) languages? -> See file LibZone_Data.lua
        checkOtherLanguagesZoneDataAndTransferFromSavedVariables()

        --Optional: Build the libSlashCommander autocomplete stuff, if LibSlashCommander is present and activated
        -->See file LibZone_AutoCompletion.lua
        lib:buildLSCZoneSearchAutoComplete()
    end
end

--Load the addon now
EVENT_MANAGER:UnregisterForEvent(libraryName, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(libraryName, EVENT_ADD_ON_LOADED, OnLibraryLoaded)
