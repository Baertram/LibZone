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

local translations = lib.translations

local getZoneName

------------------------------------------------------------------------
-- 	Helper functions
------------------------------------------------------------------------
local checkIfLanguageIsSupported = lib.checkIfLanguageIsSupported

------------------------------------------------------------------------
-- 	Library - Chat autocomplete functions (using LibSlashCommander)
------------------------------------------------------------------------

--Build the autocompletion entries for zoneNames for a given language.
--You need to use the chat slash command for the current client language /lzt or for a desired target language /lzt<language>.
--You'll have to enter a space and then the zone name of the language e.g. Shadowfen.
--After that a space or press the auto completion key TABULATOR to see a list of the translated zone namesof other languages.
--Selecting an entry will take this translated zone name to your chat's editbox.
function lib:buildAutoComplete(command, langToUse)
    if self.LSC == nil then return nil end
    if command == nil or not checkIfLanguageIsSupported(langToUse) then return end

    local blacklistedZoneIdsForAutoCompletion = lib.blacklistedZoneIdsForAutoCompletion

    getZoneName = getZoneName or lib.GetZoneName

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
                        local otherLanguageZoneName = getZoneName(lib, zoneId, lang)
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

--If LibSlashCommander is present and activated: Build the auto completion entries for each supported language (/lzt<language>) + 1 major slash command (/lzt)
function lib:buildLSCZoneSearchAutoComplete()
    --Get/Create instance of LibSlashCommander
    if self.LSC == nil then
        SLASH_COMMANDS["/lzt"] = function() d("[\'" .. libZone.name .. "\'] " .. translations[self.currentClientLanguage]["libSlashCommanderMissing"]) end
        return nil
    end
    local libName = "[" .. libZone.name .."]"
    self.commandsLzt = {}
    self.commandsLzt["all"] = self.LSC:Register({"/lzt", "/transz"}, nil, libName .. translations[self.currentClientLanguage]["slashCommandDescriptionClient"])
    self:buildAutoComplete(self.commandsLzt["all"], self.currentClientLanguage)
    for _,lang in pairs(self.supportedLanguages) do
        local transForLang = translations[tostring(lang)]
        if transForLang~= nil and transForLang["slashCommandDescription"] ~= nil then
            self.commandsLzt[tostring(lang)] = self.LSC:Register({"/lzt" .. tostring(lang), "/transz" .. tostring(lang)}, nil, libName .. translations[tostring(lang)]["slashCommandDescription"])
            self:buildAutoComplete(self.commandsLzt[tostring(lang)], tostring(lang))
        end
    end
end