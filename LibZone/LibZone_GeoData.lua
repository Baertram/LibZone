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


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- v- Geographical parent zone Info
-- > By IsJustaGhost, 2022-05. Used by himself and Thal-J (https://gitter.im/esoui/esoui)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

--[[
HOWTO - Update Geo parent data after new patches:

You get the list of zones that have not yet been added using the function:
LibZone:DebugVerifyGeoData()
-- >Runs a series of functions to check if any zones have not been accounted for in lib.geoDataReferenceTable and lib.geoDebugData savedVariables.
-- >For all zones not accounted for, adds to a savedVariable based on if it was matched with a map pin or not.
>Manual tasks to do as following steps:
--
Copy the LibZone_GeoDebug_SV_Data to a blank document. Use regex to condense the savedVariable output.
--	[1318] = 														[1318] = {
--	{																	[1318] = 0, -- High Isle --> High Isle 
--		[1318] = 0,													},
--		["1318_target"] = "-- High Isle --> High Isle"
--	},
--
After condensing, verify "unverified" entries using the "zonePoiInfo" by comparing zoneNames to poiNames.
-- If no match, it may take some aditional research to determine if the zone has a poi pin on another map, 
-- can use a pin in relitive location, or is best to leave set to no pin (0).
-- Some pin names do not match the zone name they are associated with. Example: zoneName = The Mage's Staff, pinName = Spellscar
-- If the zone is inside another subzone that has a pin on the parent, use the subZone's pinIndex (pinIndex = poiIndex at
-- table lib.geoDataReferenceTable).
-- If there is no relevant pin, leave pinIndex/poiIndex at 0.
--
-- Minimal requirement is to ensure parentZoneId is correct. If no map pin just leave at 0.
-- Manually append verified and updated unverified entries to lib.geoDataReferenceTable.
-- LibZone:DebugClearGeoDataSv() to clear the geoDebugData savedVariables once complete.


--A sample of the GeoDebug SavedVariables to show the verified and unverified entries:
sample_LibZone_GeoDebug_SV_Data = {
	["verified"] = 
	{
		[1328] = -- < zoneId
		{
			[1318] = 5, -- < [parentZoneId] = poiIndex
			-- "--zoneName --> parentZoneName",
			["1318_target"] = "--Garick's Rest --> High Isle",
		},
	},
	["unverified"] = 
	{
		[1344] = 
		{
			[1318] = 0,
			["1318_target"] = "--Dreadsail Reef --> High Isle",
		},
		[1313] = 
		{
			[1318] = 0,
			["1318_target"] = "--Systres Sisters Vault --> High Isle",
		},
		[1319] =  {
			[1318] = 0,
			["1318_target"] = "--Gonfalon Bay Outlaws Refuge --> High Isle",
		},
	},
	["zonePoiInfo"] = 
	{
		[1318] = -- < [parentZoneId] detrermined by GetParentZoneId(zoneId)
		{
			[1] = "Gonfalon Bay", -- < [poiIndex] = poiName
			[2] = "Castle Navire",
			[3] = "Steadfast Manor",
			[4] = "Stonelore Grove",
		}
	}
}
]]


-- The harborage zoneIds for each alliance
local allianceZone2TheHarborage = {
    [ALLIANCE_ALDMERI_DOMINION] =		381,
    [ALLIANCE_DAGGERFALL_COVENANT] = 	3,
	[ALLIANCE_EBONHEART_PACT] =			41,
}

-- Adjusted parent zonIds for the geographical parentZone checks
lib.adjustedParentZoneIds = {
	[199] = 	allianceZone2TheHarborage[GetUnitAlliance("player")], -- The Harborage -- > Player alliance home
	[689] = 	684, -- Nikolvara's Kennel -- > Wrothgar
	[678] = 	584, -- Imperial City Prison -- > Imperial City
	[688] = 	584, -- White-Gold Tower -- > Imperial City
	[1209] = 	1208, -- Gloomreach -- > Blackreach: Arkthzand Cavern
}

-- Parent zoneIds which expand over multiple real zone IDs (like Ragnthar, the "virtual" Dwarven region which is located
-- at Malabal Tor, Eastmarch and Alik'r Desert the same time -> Allthough the region is said to be "outside of Nirn", once
-- entered)
lib.adjustedParentMultiZoneIds = {
	[385] = { -- Ragnthar
		[58] = 	true, -- >> Malabal Tor
		[101] = true, -- >> Eastmarch
		[104] = true, -- >> Alik'r Desert
	}
}


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Verified geographic info by zoneId.
--[zoneId] = {[parentZoneId] = poiIndex}
lib.geoDataReferenceTable = {
	[2] = {
		[2] = 0, -- Clean Test -- > Clean Test 
	},
	[3] = {
		[3] = 0, -- Glenumbra -- > Glenumbra 
	},
	[11] = {
		[347] = 39, -- Vaults of Madness -- > Coldharbour 
	},
	[19] = {
		[19] = 0, -- Stormhaven -- > Stormhaven 
	},
	[20] = {
		[20] = 0, -- Rivenspire -- > Rivenspire 
	},
	[22] = {
		[104] = 42, -- Volenfell -- > Alik'r Desert 
	},
	[31] = {
		[382] = 29, -- Selene's Web -- > Reaper's March 
	},
	[38] = {
		[92] = 36, -- Blackheart Haven -- > Bangkorai 
	},
	[41] = {
		[41] = 0, -- Stonefalls -- > Stonefalls 
	},
	[57] = {
		[57] = 0, -- Deshaan -- > Deshaan 
	},
	[58] = {
		[58] = 0, -- Malabal Tor -- > Malabal Tor 
	},
	[63] = {
		[57] = 21, -- Darkshade Caverns I -- > Deshaan 
	},
	[64] = {
		[103] = 42, -- Blessed Crucible -- > The Rift 
	},
	[92] = {
		[92] = 0, -- Bangkorai -- > Bangkorai 
	},
	[101] = {
		[101] = 0, -- Eastmarch -- > Eastmarch 
	},
	[103] = {
		[103] = 0, -- The Rift -- > The Rift 
	},
	[104] = {
		[104] = 0, -- Alik'r Desert -- > Alik'r Desert 
	},
	[108] = {
		[108] = 0, -- Greenshade -- > Greenshade 
	},
	[117] = {
		[117] = 0, -- Shadowfen -- > Shadowfen 
	},
	[124] = {
		[383] = 2, -- Root Sunder Ruins -- > Grahtwood 
	},
	[126] = {
		[383] = 8, -- Elden Hollow I -- > Grahtwood 
	},
	[130] = {
		[20] = 17, -- Crypt of Hearts I -- > Rivenspire 
	},
	[131] = {
		[58] = 41, -- Tempest Island -- > Malabal Tor 
	},
	[134] = {
		[117] = 40, -- Sanguine's Demesne -- > Shadowfen 
	},
	[137] = {
		[108] = 1, -- Rulanyil's Fall -- > Greenshade 
	},
	[138] = {
		[58] = 37, -- Crimson Cove -- > Malabal Tor 
	},
	[142] = {
		[19] = 21, -- Bonesnap Ruins -- > Stormhaven 
	},
	[144] = {
		[3] = 42, -- Spindleclutch I -- > Glenumbra 
	},
	[146] = {
		[19] = 20, -- Wayrest Sewers I -- > Stormhaven 
	},
	[148] = {
		[117] = 39, -- Arx Corinium -- > Shadowfen 
	},
	[159] = {
		[19] = 0, -- Emeric's Dream -- > Stormhaven 
	},
	[162] = {
		[20] = 16, -- Obsidian Scar -- > Rivenspire 
	},
	[166] = {
		[3] = 17, -- Cath Bedraud -- > Glenumbra 
	},
	[168] = {
		[92] = 0, -- Bisnensel -- > Bangkorai 
	},
	[169] = {
		[92] = 16, -- Razak's Wheel -- > Bangkorai 
	},
	[176] = {
		[108] = 39, -- City of Ash I -- > Greenshade 
	},
	[181] = {
		[181] = 0, -- Cyrodiil -- > Cyrodiil 
	},
	[187] = {
		[117] = 32, -- Loriasel -- > Shadowfen 
	},
	[188] = {
		[57] = 0, -- The Apothecarium -- > Deshaan 
	},
	[189] = {
		[57] = 13, -- Tribunal Temple -- > Deshaan 
	},
	[190] = {
		[57] = 0, -- Reservoir of Souls -- > Deshaan 
	},
	[191] = {
		[41] = 17, -- Ash Mountain -- > Stonefalls 
	},
	[192] = {
		[41] = 0, -- Virak Keep -- > Stonefalls 
	},
	[193] = {
		[41] = 16, -- Tormented Spire -- > Stonefalls 
	},
	[199] = {
		[41] = 46, -- The Harborage -- > Stonefalls 
		[381] = 42, -- The Harborage -- > Auridon 
		[3] = 46, -- The Harborage -- > Glenumbra 
	},
	[200] = {
		[199] = 0, -- The Foundry of Woe -- > The Harborage 
	},
	[201] = {
		[199] = 0, -- Castle of the Worm -- > The Harborage 
	},
	[203] = {
		[267] = 0, -- Cheesemonger's Hollow -- > Eyevea
	},
	[207] = {
		[208] = 0, -- Mzeneldt -- > The Earth Forge 
	},
	[208] = {
		[208] = 0, -- The Earth Forge -- > The Earth Forge 
	},
	[209] = {
		[208] = 0, -- Halls of Submission -- > The Earth Forge 
	},
	[212] = {
		[57] = 0, -- Mournhold Sewers -- > Deshaan 
	},
	[213] = {
		[117] = 0, -- Sunscale Ruins -- > Shadowfen 
	},
	[214] = {
		[117] = 0, -- Lair of the Skin Stealer -- > Shadowfen 
	},
	[215] = {
		[117] = 0, -- Vision of the Hist -- > Shadowfen 
	},
	[216] = {
		[41] = 18, -- Crow's Wood -- > Stonefalls 
	},
	[217] = {
		[199] = 0, -- The Halls of Torment -- > The Harborage 
	},
	[218] = {
		[267] = 0, -- Circus of Cheerful Slaughter -- > Eyevea 
	},
	[219] = {
		[267] = 0, -- Chateau of the Ravenous Rodent -- > Eyevea 
	},
	[222] = {
		[3] = 18, -- Dresan Keep -- > Glenumbra 
	},
	[223] = {
		[3] = 15, -- Tomb of Lost Kings -- > Glenumbra 
	},
	[224] = {
		[20] = 12, -- Breagha-Fin -- > Rivenspire 
	},
	[227] = {
		[92] = 50, -- The Sunken Road -- > Bangkorai 
	},
	[228] = {
		[92] = 12, -- Bangkorai Garrison -- > Bangkorai 
	},
	[229] = {
		[92] = 6, -- Nilata Ruins -- > Bangkorai 
	},
	[231] = {
		[92] = 7, -- Hall of Heroes -- > Bangkorai 
	},
	[232] = {
		[117] = 0, -- Silyanorn Ruins -- > Shadowfen 
	},
	[233] = {
		[117] = 0, -- Ruins of Ten-Maur-Wolk -- > Shadowfen 
	},
	[234] = {
		[117] = 0, -- Odious Chapel -- > Shadowfen 
	},
	[235] = {
		[117] = 0, -- Temple of Sul -- > Shadowfen 
	},
	[236] = {
		[117] = 0, -- White Rose Prison Dungeon -- > Shadowfen 
	},
	[237] = {
		[104] = 0, -- Impervious Vault -- > Alik'r Desert 
	},
	[238] = {
		[104] = 15, -- Salas En -- > Alik'r Desert 
	},
	[239] = {
		[104] = 6, -- Kulati Mines -- > Alik'r Desert 
	},
	[241] = {
		[41] = 0, -- House Indoril Crypt -- > Stonefalls 
	},
	[242] = {
		[41] = 0, -- Fort Arand Dungeons -- > Stonefalls 
	},
	[243] = {
		[41] = 0, -- Coral Heart Chamber -- > Stonefalls 
	},
	[245] = {
		[41] = 0, -- Heimlyn Keep Reliquary -- > Stonefalls 
	},
	[246] = {
		[41] = 0, -- Iliath Temple Mines -- > Stonefalls 
	},
	[247] = {
		[41] = 0, -- House Dres Crypts -- > Stonefalls 
	},
	[248] = {
		[57] = 8, -- Mzithumz -- > Deshaan 
	},
	[249] = {
		[57] = 0, -- Tal'Deic Crypts -- > Deshaan 
	},
	[250] = {
		[57] = 0, -- Narsis Ruins -- > Deshaan 
	},
	[252] = {
		[57] = 0, -- The Hollow Cave -- > Deshaan 
	},
	[253] = {
		[57] = 0, -- Shad Astula Underhalls -- > Deshaan 
	},
	[254] = {
		[57] = 4, -- Deepcrag Den -- > Deshaan 
	},
	[255] = {
		[57] = 39, -- Bthanual -- > Deshaan 
	},
	[256] = {
		[3] = 0, -- Crosswych Mine -- > Glenumbra 
	},
	[257] = {
		[103] = 0, -- Vaults of Vernim -- > The Rift 
	},
	[258] = {
		[103] = 0, -- Arcwind Point -- > The Rift 
	},
	[259] = {
		[103] = 12, -- Trolhetta -- > The Rift 
	},
	[260] = {
		[101] = 33, -- Lost Knife Cave -- > Eastmarch 
	},
	[261] = {
		[101] = 0, -- Bonestrewn Barrow -- > Eastmarch 
	},
	[262] = {
		[101] = 0, -- Wittestadr Crypts -- > Eastmarch 
	},
	[263] = {
		[101] = 0, -- Mistwatch Crevasse -- > Eastmarch 
	},
	[264] = {
		[101] = 8, -- Fort Morvunskar -- > Eastmarch 
	},
	[265] = {
		[101] = 10, -- Mzulft -- > Eastmarch 
	},
	[266] = {
		[101] = 34, -- Cragwallow -- > Eastmarch 
	},
	[267] = {
		[267] = 0, -- Eyevea -- > Eyevea 
	},
	[268] = {
		[58] = 0, -- Stormwarden Undercroft -- > Malabal Tor 
	},
	[269] = {
		[58] = 0, -- Abamath Ruins -- > Malabal Tor 
	},
	[270] = {
		[117] = 33, -- Shrine of the Black Maw -- > Shadowfen 
	},
	[271] = {
		[117] = 34, -- Broken Tusk -- > Shadowfen 
	},
	[272] = {
		[117] = 35, -- Atanaz Ruins -- > Shadowfen 
	},
	[273] = {
		[117] = 37, -- Chid-Moska Ruins -- > Shadowfen 
	},
	[274] = {
		[117] = 36, -- Onkobra Kwama Mine -- > Shadowfen 
	},
	[275] = {
		[117] = 38, -- Gandranen Ruins -- > Shadowfen 
	},
	[279] = {
		[279] = 0, -- Pregame -- > Pregame 
	},
	[280] = {
		[280] = 0, -- Bleakrock Isle -- > Bleakrock Isle 
	},
	[281] = {
		[281] = 0, -- Bal Foyen -- > Bal Foyen 
	},
	[283] = {
		[41] = 34, -- Fungal Grotto I -- > Stonefalls 
	},
	[284] = {
		[3] = 41, -- Bad Man's Hallows -- > Glenumbra 
	},
	[287] = {
		[41] = 35, -- Inner Sea Armature -- > Stonefalls 
	},
	[288] = {
		[41] = 36, -- Mephala's Nest -- > Stonefalls 
	},
	[289] = {
		[41] = 37, -- Softloam Cavern -- > Stonefalls 
	},
	[290] = {
		[41] = 41, -- Hightide Hollow -- > Stonefalls 
	},
	[291] = {
		[41] = 42, -- Sheogorath's Tongue -- > Stonefalls 
	},
	[296] = {
		[41] = 38, -- Emberflint Mine -- > Stonefalls 
	},
	[306] = {
		[57] = 20, -- Forgotten Crypts -- > Deshaan 
	},
	[308] = {
		[104] = 28, -- Lost City of the Na-Totambu -- > Alik'r Desert 
	},
	[309] = {
		[3] = 20, -- Ilessan Tower -- > Glenumbra 
	},
	[310] = {
		[3] = 21, -- Silumm -- > Glenumbra 
	},
	[311] = {
		[3] = 22, -- The Mines of Khuras -- > Glenumbra 
	},
	[312] = {
		[3] = 23, -- Enduum -- > Glenumbra 
	},
	[313] = {
		[3] = 24, -- Ebon Crypt -- > Glenumbra 
	},
	[314] = {
		[3] = 25, -- Cryptwatch Fort -- > Glenumbra 
	},
	[315] = {
		[19] = 29, -- Portdun Watch -- > Stormhaven 
	},
	[316] = {
		[19] = 30, -- Koeglin Mine -- > Stormhaven 
	},
	[317] = {
		[19] = 31, -- Pariah Catacombs -- > Stormhaven 
	},
	[318] = {
		[19] = 32, -- Farangel's Delve -- > Stormhaven 
	},
	[319] = {
		[19] = 33, -- Bearclaw Mine -- > Stormhaven 
	},
	[320] = {
		[19] = 34, -- Norvulk Ruins -- > Stormhaven 
	},
	[321] = {
		[20] = 31, -- Crestshade Mine -- > Rivenspire 
	},
	[322] = {
		[20] = 32, -- Flyleaf Catacombs -- > Rivenspire 
	},
	[323] = {
		[20] = 33, -- Tribulation Crypt -- > Rivenspire 
	},
	[324] = {
		[20] = 34, -- Orc's Finger Ruins -- > Rivenspire 
	},
	[325] = {
		[20] = 35, -- Erokii Ruins -- > Rivenspire 
	},
	[326] = {
		[20] = 36, -- Hildune's Secret Refuge -- > Rivenspire 
	},
	[327] = {
		[104] = 22, -- Santaki -- > Alik'r Desert 
	},
	[328] = {
		[104] = 23, -- Divad's Chagrin Mine -- > Alik'r Desert 
	},
	[329] = {
		[104] = 24, -- Aldunz -- > Alik'r Desert 
	},
	[330] = {
		[104] = 25, -- Coldrock Diggings -- > Alik'r Desert 
	},
	[331] = {
		[104] = 26, -- Sandblown Mine -- > Alik'r Desert 
	},
	[332] = {
		[104] = 27, -- Yldzuun -- > Alik'r Desert 
	},
	[333] = {
		[92] = 30, -- Torog's Spite -- > Bangkorai 
	},
	[334] = {
		[92] = 31, -- Troll's Toothpick -- > Bangkorai 
	},
	[335] = {
		[92] = 32, -- Viridian Watch -- > Bangkorai 
	},
	[336] = {
		[92] = 33, -- Crypt of the Exiles -- > Bangkorai 
	},
	[337] = {
		[92] = 34, -- Klathzgar -- > Bangkorai 
	},
	[338] = {
		[92] = 35, -- Rubble Butte -- > Bangkorai 
	},
	[339] = {
		[101] = 37, -- Hall of the Dead -- > Eastmarch 
	},
	[341] = {
		[103] = 31, -- The Lion's Den -- > The Rift 
	},
	[346] = {
		[101] = 36, -- Skuldafn -- > Eastmarch 
	},
	[347] = {
		[347] = 0, -- Coldharbour -- > Coldharbour 
	},
	[353] = {
		[101] = 0, -- Hall of Trials -- > Eastmarch 
	},
	[354] = {
		[101] = 0, -- Cradlecrush Arena -- > Eastmarch 
	},
	[359] = {
		[101] = 26, -- The Chill Hollow -- > Eastmarch 
	},
	[360] = {
		[101] = 27, -- Icehammer's Vault -- > Eastmarch 
	},
	[361] = {
		[101] = 28, -- Old Sord's Cave -- > Eastmarch 
	},
	[362] = {
		[101] = 29, -- The Frigid Grotto -- > Eastmarch 
	},
	[363] = {
		[101] = 30, -- Stormcrag Crypt -- > Eastmarch 
	},
	[364] = {
		[101] = 31, -- The Bastard's Tomb -- > Eastmarch 
	},
	[365] = {
		[347] = 31, -- Library of Dusk -- > Coldharbour 
	},
	[366] = {
		[347] = 33, -- Lightless Oubliette -- > Coldharbour 
	},
	[367] = {
		[347] = 0, -- Lightless Cell -- > Coldharbour 
	},
	[368] = {
		[347] = 28, -- The Black Forge -- > Coldharbour 
	},
	[369] = {
		[347] = 30, -- The Vile Laboratory -- > Coldharbour 
	},
	[370] = {
		[347] = 0, -- Reaver Citadel Pyramid -- > Coldharbour 
	},
	[371] = {
		[347] = 0, -- The Mooring -- > Coldharbour 
	},
	[372] = {
		[347] = 34, -- Manor of Revelry -- > Coldharbour 
	},
	[374] = {
		[347] = 38, -- The Endless Stair -- > Coldharbour 
	},
	[375] = {
		[347] = 0, -- Chapel of Light -- > Coldharbour 
	},
	[376] = {
		[347] = 0, -- Grunda's Gatehouse -- > Coldharbour 
	},
	[377] = {
		[58] = 23, -- Dra'bul -- > Malabal Tor 
	},
	[378] = {
		[58] = 0, -- Shrine of Mauloch -- > Malabal Tor 
	},
	[379] = {
		[58] = 0, -- Silvenar's Audience Hall -- > Malabal Tor 
	},
	[380] = {
		[381] = 41, -- The Banished Cells I -- > Auridon 
	},
	[381] = {
		[381] = 0, -- Auridon -- > Auridon 
	},
	[382] = {
		[382] = 0, -- Reaper's March -- > Reaper's March 
	},
	[383] = {
		[383] = 0, -- Grahtwood -- > Grahtwood 
	},
	[385] = {
		[104] = 53, -- Ragnthar -- > Alik'r Desert 
		[101] = 50, -- Ragnthar -- > Eastmarch 
		[58] = 55, -- Ragnthar -- > Malabal Tor 
	},
	[386] = {
		[41] = 19, -- Fort Virak Ruin -- > Stonefalls 
	},
	[387] = {
		[381] = 0, -- Tower of the Vale -- > Auridon 
	},
	[388] = {
		[381] = 0, -- Phaer Catacombs -- > Auridon 
	},
	[389] = {
		[383] = 0, -- Reliquary Ruins -- > Grahtwood 
	},
	[390] = {
		[381] = 0, -- The Veiled Keep -- > Auridon 
	},
	[392] = {
		[381] = 0, -- The Vault of Exile -- > Auridon 
	},
	[393] = {
		[381] = 0, -- Saltspray Cave -- > Auridon 
	},
	[394] = {
		[381] = 0, -- Ezduiin Undercroft -- > Auridon 
	},
	[395] = {
		[381] = 0, -- The Refuge of Dread -- > Auridon 
	},
	[396] = {
		[381] = 6, -- Ondil -- > Auridon 
	},
	[397] = {
		[381] = 5, -- Del's Claim -- > Auridon 
	},
	[398] = {
		[381] = 7, -- Entila's Folly -- > Auridon 
	},
	[399] = {
		[381] = 8, -- Wansalen -- > Auridon 
	},
	[400] = {
		[381] = 10, -- Mehrunes' Spite -- > Auridon 
	},
	[401] = {
		[381] = 11, -- Bewan -- > Auridon 
	},
	[402] = {
		[103] = 0, -- Shor's Stone Mine -- > The Rift 
	},
	[403] = {
		[103] = 7, -- Northwind Mine -- > The Rift 
	},
	[404] = {
		[103] = 0, -- Fallowstone Vault -- > The Rift 
	},
	[405] = {
		[57] = 33, -- Lady Llarel's Shelter -- > Deshaan 
	},
	[406] = {
		[57] = 34, -- Lower Bthanual -- > Deshaan 
	},
	[407] = {
		[57] = 35, -- The Triple Circle Mine -- > Deshaan 
	},
	[408] = {
		[57] = 36, -- Taleon's Crag -- > Deshaan 
	},
	[409] = {
		[57] = 37, -- Knife Ear Grotto -- > Deshaan 
	},
	[410] = {
		[57] = 38, -- The Corpse Garden -- > Deshaan 
	},
	[411] = {
		[58] = 0, -- The Hunting Grounds -- > Malabal Tor 
	},
	[412] = {
		[103] = 0, -- Nimalten Barrow -- > The Rift 
	},
	[413] = {
		[103] = 35, -- Avanchnzel -- > The Rift 
	},
	[414] = {
		[103] = 0, -- Pinepeak Caverns -- > The Rift 
	},
	[415] = {
		[103] = 0, -- Trolhetta Cave -- > The Rift 
	},
	[416] = {
		[381] = 2, -- Inner Tanzelwil -- > Auridon 
	},
	[417] = {
		[347] = 16, -- Aba-Loria -- > Coldharbour 
	},
	[418] = {
		[347] = 19, -- The Vault of Haman Forgefire -- > Coldharbour 
	},
	[419] = {
		[347] = 17, -- The Grotto of Depravity -- > Coldharbour 
	},
	[420] = {
		[347] = 18, -- Cave of Trophies -- > Coldharbour 
	},
	[421] = {
		[347] = 20, -- Mal Sorra's Tomb -- > Coldharbour 
	},
	[422] = {
		[347] = 21, -- The Wailing Maw -- > Coldharbour 
	},
	[424] = {
		[3] = 0, -- Camlorn Keep -- > Glenumbra 
	},
	[425] = {
		[3] = 0, -- Daggerfall Castle -- > Glenumbra 
	},
	[426] = {
		[3] = 0, -- Angof's Sanctum -- > Glenumbra 
	},
	[429] = {
		[3] = 0, -- Glenumbra Moors Cave -- > Glenumbra 
	},
	[430] = {
		[19] = 0, -- Aphren's Tomb -- > Stormhaven 
	},
	[431] = {
		[103] = 0, -- Taarengrav Barrow -- > The Rift 
	},
	[433] = {
		[383] = 0, -- Nairume's Prison -- > Grahtwood 
	},
	[434] = {
		[383] = 0, -- The Orrery -- > Grahtwood 
	},
	[435] = {
		[383] = 0, -- Cathedral of the Golden Path -- > Grahtwood 
	},
	[436] = {
		[383] = 0, -- Reliquary Vault -- > Grahtwood 
	},
	[437] = {
		[383] = 0, -- Laeloria Ruins -- > Grahtwood 
	},
	[438] = {
		[383] = 7, -- Cave of Broken Sails -- > Grahtwood 
	},
	[439] = {
		[383] = 11, -- Ossuary of Telacar -- > Grahtwood 
	},
	[440] = {
		[383] = 0, -- The Aquifer -- > Grahtwood 
	},
	[442] = {
		[383] = 34, -- Ne Salas -- > Grahtwood 
	},
	[444] = {
		[383] = 37, -- Burroot Kwama Mine -- > Grahtwood 
	},
	[447] = {
		[383] = 39, -- Mobar Mine -- > Grahtwood 
	},
	[449] = {
		[101] = 41, -- Direfrost Keep -- > Eastmarch 
	},
	[451] = {
		[382] = 5, -- Senalana -- > Reaper's March 
	},
	[452] = {
		[382] = 0, -- Temple to the Divines -- > Reaper's March 
	},
	[453] = {
		[382] = 0, -- Halls of Ichor -- > Reaper's March 
	},
	[454] = {
		[382] = 0, -- Do'Krin Temple -- > Reaper's March 
	},
	[455] = {
		[382] = 0, -- Rawl'kha Temple -- > Reaper's March 
	},
	[456] = {
		[382] = 0, -- Five Finger Dance -- > Reaper's March 
	},
	[457] = {
		[382] = 0, -- Moonmont Temple -- > Reaper's March 
	},
	[458] = {
		[382] = 40, -- Fort Sphinxmoth -- > Reaper's March 
	},
	[459] = {
		[382] = 14, -- Thizzrini Arena -- > Reaper's March 
	},
	[460] = {
		[382] = 0, -- The Demi-Plane of Jode -- > Reaper's March 
	},
	[461] = {
		[382] = 0, -- Den of Lorkhaj -- > Reaper's March 
	},
	[462] = {
		[382] = 16, -- Thibaut's Cairn -- > Reaper's March 
	},
	[463] = {
		[382] = 15, -- Kuna's Delve -- > Reaper's March 
	},
	[464] = {
		[382] = 19, -- Fardir's Folly -- > Reaper's March 
	},
	[465] = {
		[382] = 18, -- Claw's Strike -- > Reaper's March 
	},
	[466] = {
		[382] = 17, -- Weeping Wind Cave -- > Reaper's March 
	},
	[467] = {
		[382] = 20, -- Jode's Light -- > Reaper's March 
	},
	[468] = {
		[58] = 29, -- Dead Man's Drop -- > Malabal Tor 
	},
	[469] = {
		[58] = 35, -- Tomb of Apostates -- > Malabal Tor 
	},
	[470] = {
		[58] = 34, -- Hoarvor Pit -- > Malabal Tor 
	},
	[471] = {
		[58] = 32, -- Shael Ruins -- > Malabal Tor 
	},
	[472] = {
		[58] = 31, -- Roots of Silvenar -- > Malabal Tor 
	},
	[473] = {
		[58] = 30, -- Black Vine Ruins -- > Malabal Tor 
	},
	[475] = {
		[383] = 35, -- The Scuttle Pit -- > Grahtwood 
	},
	[477] = {
		[383] = 36, -- Vinedeath Cave -- > Grahtwood 
	},
	[478] = {
		[383] = 38, -- Wormroot Depths -- > Grahtwood 
	},
	[480] = {
		[103] = 36, -- Snapleg Cave -- > The Rift 
	},
	[481] = {
		[103] = 33, -- Fort Greenwall -- > The Rift 
	},
	[482] = {
		[103] = 37, -- Shroud Hearth Barrow -- > The Rift 
	},
	[484] = {
		[103] = 34, -- Faldar's Tooth -- > The Rift 
	},
	[485] = {
		[103] = 32, -- Broken Helm Hollow -- > The Rift 
	},
	[486] = {
		[381] = 40, -- Toothmaul Gully -- > Auridon 
	},
	[487] = {
		[382] = 23, -- The Vile Manse -- > Reaper's March 
	},
	[492] = {
		[41] = 0, -- Tormented Spire Summit -- > Stonefalls 
	},
	[493] = {
		[181] = 42, -- Breakneck Cave -- > Cyrodiil 
	},
	[494] = {
		[181] = 24, -- Capstone Cave -- > Cyrodiil 
	},
	[495] = {
		[181] = 37, -- Cracked Wood Cave -- > Cyrodiil 
	},
	[496] = {
		[181] = 31, -- Echo Cave -- > Cyrodiil 
	},
	[497] = {
		[181] = 9, -- Haynote Cave -- > Cyrodiil 
	},
	[498] = {
		[181] = 38, -- Kingscrest Cavern -- > Cyrodiil 
	},
	[499] = {
		[181] = 36, -- Lipsand Tarn -- > Cyrodiil 
	},
	[500] = {
		[181] = 39, -- Muck Valley Cavern -- > Cyrodiil 
	},
	[501] = {
		[181] = 12, -- Newt Cave -- > Cyrodiil 
	},
	[502] = {
		[181] = 15, -- Nisin Cave -- > Cyrodiil 
	},
	[503] = {
		[181] = 11, -- Pothole Caverns -- > Cyrodiil 
	},
	[504] = {
		[181] = 40, -- Quickwater Cave -- > Cyrodiil 
	},
	[505] = {
		[181] = 23, -- Red Ruby Cave -- > Cyrodiil 
	},
	[506] = {
		[181] = 43, -- Serpent Hollow Cave -- > Cyrodiil 
	},
	[507] = {
		[181] = 21, -- Bloodmayne Cave -- > Cyrodiil 
	},
	[508] = {
		[849] = 89, -- Foyada Quarry -- > Vvardenfell 
	},
	[509] = {
		[849] = 87, -- Ald Carac -- > Vvardenfell 
	},
	[510] = {
		[849] = 88, -- Ularra -- > Vvardenfell 
	},
	[511] = {
		[511] = 0, -- Arcane University -- > Arcane University 
	},
	[512] = {
		[512] = 0, -- Deeping Drome -- > Deeping Drome 
	},
	[513] = {
		[1160] = 6, -- Mor Khazgur -- > Western Skyrim 
	},
	[514] = {
		[514] = 0, -- Istirus Outpost -- > Istirus Outpost 
	},
	[515] = {
		[515] = 0, -- Istirus Outpost Arena -- > Istirus Outpost Arena 
	},
	[516] = {
		[849] = 87, -- Ald Carac -- > Vvardenfell 
	},
	[517] = {
		[517] = 0, -- Eld Angavar -- > Eld Angavar 
	},
	[518] = {
		[518] = 0, -- Eld Angavar -- > Eld Angavar 
	},
	[525] = {
		[181] = 0, -- Cheesemonger Hollow -- > Cyrodiil 
	},
	[526] = {
		[382] = 11, -- Greenhill Catacombs -- > Reaper's March 
	},
	[527] = {
		[199] = 0, -- Sancre Tor -- > The Harborage 
	},
	[529] = {
		[267] = 0, -- Eyevea Mages Guild -- > Eyevea 
	},
	[530] = {
		[347] = 0, -- Haj Uxith Corridors -- > Coldharbour 
	},
	[531] = {
		[181] = 95, -- Toadstool Hollow -- > Cyrodiil 
	},
	[532] = {
		[181] = 41, -- Vahtacen -- > Cyrodiil 
	},
	[533] = {
		[181] = 90, -- Underpall Cave -- > Cyrodiil 
	},
	[534] = {
		[534] = 0, -- Stros M'Kai -- > Stros M'Kai 
	},
	[535] = {
		[535] = 0, -- Betnikh -- > Betnikh 
	},
	[537] = {
		[537] = 0, -- Khenarthi's Roost -- > Khenarthi's Roost 
	},
	[539] = {
		[535] = 7, -- Carzog's Demise -- > Betnikh 
	},
	[541] = {
		[267] = 0, -- Glade of the Divines -- > Eyevea 
	},
	[542] = {
		[208] = 0, -- Buraniim -- > The Earth Forge 
	},
	[543] = {
		[208] = 0, -- Dourstone Vault -- > The Earth Forge 
	},
	[544] = {
		[208] = 0, -- Stonefang Cavern -- > The Earth Forge 
	},
	[545] = {
		[19] = 17, -- Alcaire Keep -- > Stormhaven 
	},
	[546] = {
		[19] = 0, -- Wayrest Castle -- > Stormhaven 
	},
	[547] = {
		[108] = 0, -- Shrouded Hollow -- > Greenshade 
	},
	[548] = {
		[548] = 1, -- Silatar -- > Silatar 
	},
	[549] = {
		[383] = 0, -- The Middens -- > Grahtwood 
	},
	[551] = {
		[108] = 0, -- Imperial Underground -- > Greenshade 
	},
	[552] = {
		[108] = 0, -- Shademist Enclave -- > Greenshade 
	},
	[553] = {
		[108] = 0, -- Ilmyris -- > Greenshade 
	},
	[554] = {
		[108] = 11, -- Serpent's Grotto -- > Greenshade 
	},
	[555] = {
		[108] = 0, -- Abecean Sea -- > Greenshade 
	},
	[556] = {
		[108] = 0, -- Nereid Temple Cave -- > Greenshade 
	},
	[557] = {
		[347] = 40, -- Village of the Lost -- > Coldharbour 
	},
	[558] = {
		[108] = 0, -- Hectahame Grotto -- > Greenshade 
	},
	[559] = {
		[108] = 0, -- Valenheart -- > Greenshade 
	},
	[560] = {
		[103] = 0, -- Nimalten Barrow -- > The Rift 
	},
	[561] = {
		[108] = 0, -- Isles of Torment -- > Greenshade 
	},
	[562] = {
		[382] = 0, -- Khaj Rawlith -- > Reaper's March 
	},
	[565] = {
		[382] = 0, -- Ren-dro Caverns -- > Reaper's March 
	},
	[566] = {
		[3] = 0, -- Heart of the Wyrd Tree -- > Glenumbra 
	},
	[567] = {
		[103] = 0, -- The Hunting Grounds -- > The Rift 
	},
	[569] = {
		[104] = 0, -- Ash'abah Pass -- > Alik'r Desert 
	},
	[570] = {
		[104] = 0, -- Tu'whacca's Sanctum -- > Alik'r Desert 
	},
	[571] = {
		[104] = 0, -- Suturah's Crypt -- > Alik'r Desert 
	},
	[572] = {
		[572] = 1, -- Stirk -- > Stirk 
	},
	[573] = {
		[199] = 0, -- The Worm's Retreat -- > The Harborage 
	},
	[574] = {
		[199] = 0, -- The Valley of Blades -- > The Harborage 
	},
	[575] = {
		[108] = 34, -- Carac Dena -- > Greenshade 
	},
	[576] = {
		[108] = 33, -- Gurzag's Mine -- > Greenshade 
	},
	[577] = {
		[108] = 36, -- The Underroot -- > Greenshade 
	},
	[578] = {
		[108] = 35, -- Naril Nagaia -- > Greenshade 
	},
	[579] = {
		[108] = 37, -- Harridan's Lair -- > Greenshade 
	},
	[580] = {
		[108] = 38, -- Barrow Trench -- > Greenshade 
	},
	[581] = {
		[199] = 0, -- Heart's Grief -- > The Harborage 
	},
	[582] = {
		[381] = 0, -- Temple of Auri-El -- > Auridon 
	},
	[584] = {
		[584] = 0, -- Imperial City -- > Imperial City 
	},
	[585] = {
		[92] = 0, -- Nchu Duabthar Threshold -- > Bangkorai 
	},
	[586] = {
		[586] = 0, -- The Wailing Prison -- > The Wailing Prison 
	},
	[587] = {
		[20] = 0, -- Fevered Mews -- > Rivenspire 
	},
	[588] = {
		[20] = 14, -- Doomcrag -- > Rivenspire 
	},
	[589] = {
		[20] = 4, -- Northpoint -- > Rivenspire 
	},
	[590] = {
		[20] = 0, -- Edrald Undercroft -- > Rivenspire 
	},
	[591] = {
		[20] = 0, -- Lorkrata Ruins -- > Rivenspire 
	},
	[592] = {
		[20] = 48, -- Shadowfate Cavern -- > Rivenspire 
	},
	[593] = {
		[92] = 12, -- Bangkorai Garrison -- > Bangkorai 
	},
	[594] = {
		[92] = 0, -- The Far Shores -- > Bangkorai 
	},
	[595] = {
		[208] = 0, -- Abagarlas -- > The Earth Forge 
	},
	[596] = {
		[103] = 0, -- Blood Matron's Crypt -- > The Rift 
	},
	[598] = {
		[199] = 0, -- The Colored Rooms -- > The Harborage 
	},
	[599] = {
		[383] = 24, -- Elden Root -- > Grahtwood 
	},
	[600] = {
		[57] = 12, -- Mournhold -- > Deshaan 
	},
	[601] = {
		[572] = 0, -- Wayrest -- > Stirk 
	},
	[628] = {
		[20] = 14, -- Doomcrag -- > Rivenspire 
	},
	[632] = {
		[888] = 36, -- Skyreach Hold -- > Craglorn 
	},
	[635] = {
		[888] = 11, -- Dragonstar Arena -- > Craglorn 
	},
	[636] = {
		[888] = 31, -- Hel Ra Citadel -- > Craglorn 
	},
	[637] = {
		[57] = 0, -- Quarantine Serk Catacombs -- > Deshaan 
	},
	[638] = {
		[888] = 32, -- Aetherian Archive -- > Craglorn 
	},
	[639] = {
		[888] = 33, -- Sanctum Ophidia -- > Craglorn 
	},
	[640] = {
		[19] = 0, -- Godrun's Dream -- > Stormhaven 
	},
	[641] = {
		[3] = 0, -- Themond Mine -- > Glenumbra 
	},
	[642] = {
		[642] = 0, -- The Earth Forge -- > The Earth Forge 
	},
	[643] = {
		[584] = 0, -- Imperial Sewers -- > Imperial City 
	},
	[649] = {
		[584] = 0, -- The Dragonfire Cathedral -- > Imperial City 
	},
	[676] = {
		[816] = 1, -- Shark's Teeth Grotto -- > Hew's Bane 
	},
	[677] = {
		[684] = 55, -- Maelstrom Arena -- > Wrothgar 
	},
	[678] = {
		[584] = 31, -- Imperial City Prison -- > Imperial City 
		[181] = 104, -- Imperial City Prison -- > Cyrodiil 
	},
	[681] = {
		[108] = 58, -- City of Ash II -- > Greenshade 
	},
	[684] = {
		[684] = 0, -- Wrothgar -- > Wrothgar 
	},
	[688] = {
		[181] = 105, -- White-Gold Tower -- > Cyrodiil 
		[643] = 52, -- White-Gold Tower -- > Imperial Sewers 
	},
	[689] = {
		[684] = 21, -- Nikolvara's Kennel -- > Wrothgar 
		[689] = 1, -- Nikolvara's Kennel -- > Nikolvara's Kennel 
	},
	[691] = {
		[684] = 8, -- Thukhozod's Sanctum -- > Wrothgar 
	},
	[692] = {
		[684] = 3, -- Watcher's Hold -- > Wrothgar 
	},
	[693] = {
		[684] = 24, -- Coldperch Cavern -- > Wrothgar 
	},
	[694] = {
		[684] = 19, -- Argent Mine -- > Wrothgar 
	},
	[695] = {
		[684] = 0, -- Coldwind's Den -- > Wrothgar 
	},
	[697] = {
		[684] = 23, -- Zthenganaz -- > Wrothgar 
	},
	[698] = {
		[684] = 0, -- Morkul Descent -- > Wrothgar 
	},
	[699] = {
		[684] = 4, -- Honor's Rest -- > Wrothgar 
	},
	[700] = {
		[684] = 28, -- Exile's Barrow -- > Wrothgar 
	},
	[701] = {
		[684] = 0, -- Graystone Quarry Depths -- > Wrothgar 
	},
	[702] = {
		[684] = 11, -- Frostbreak Fortress -- > Wrothgar 
	},
	[703] = {
		[684] = 1, -- Paragon's Remembrance -- > Wrothgar 
	},
	[704] = {
		[684] = 25, -- Bonerock Cavern -- > Wrothgar 
	},
	[705] = {
		[684] = 29, -- Rkindaleft -- > Wrothgar 
	},
	[706] = {
		[684] = 2, -- Old Orsinium -- > Wrothgar 
	},
	[707] = {
		[684] = 0, -- Ice-Heart's Lair -- > Wrothgar 
	},
	[708] = {
		[684] = 0, -- Temple Library -- > Wrothgar 
	},
	[710] = {
		[684] = 0, -- Fharun Prison -- > Wrothgar 
	},
	[711] = {
		[684] = 0, -- Temple Rectory -- > Wrothgar 
	},
	[712] = {
		[684] = 0, -- Chambers of Loyalty -- > Wrothgar 
	},
	[715] = {
		[684] = 0, -- Sanctum of Prowess -- > Wrothgar 
	},
	[719] = {
		[1011] = 0, -- Time-Lost Throne Room -- > Summerset 
	},
	[723] = {
		[199] = 0, -- Heart's Grief -- > The Harborage 
	},
	[724] = {
		[684] = 7, -- Sorrow -- > Wrothgar 
	},
	[725] = {
		[382] = 57, -- Maw of Lorkhaj -- > Reaper's March 
	},
	[726] = {
		[726] = 0, -- Murkmire -- > Murkmire 
	},
	[745] = {
		[41] = 0, -- Charred Ridge -- > Stonefalls 
	},
	[746] = {
		[381] = 0, -- Vulkhel Guard Outlaws Refuge -- > Auridon 
	},
	[747] = {
		[383] = 0, -- Elden Root Outlaws Refuge -- > Grahtwood 
	},
	[748] = {
		[108] = 0, -- Marbruk Outlaws Refuge -- > Greenshade 
	},
	[749] = {
		[58] = 0, -- Velyn Harbor Outlaws Refuge -- > Malabal Tor 
	},
	[750] = {
		[382] = 0, -- Rawl'kha Outlaws Refuge -- > Reaper's March 
	},
	[751] = {
		[888] = 0, -- Belkarth Outlaws Refuge -- > Craglorn 
	},
	[752] = {
		[19] = 0, -- Wayrest Outlaws Refuge -- > Stormhaven 
	},
	[753] = {
		[3] = 0, -- Daggerfall Outlaws Refuge -- > Glenumbra 
	},
	[754] = {
		[92] = 0, -- Evermore Outlaws Refuge -- > Bangkorai 
	},
	[755] = {
		[20] = 0, -- Shornhelm Outlaws Refuge -- > Rivenspire 
	},
	[756] = {
		[104] = 0, -- Sentinel Outlaws Refuge -- > Alik'r Desert 
	},
	[757] = {
		[41] = 0, -- Davon's Watch Outlaws Refuge -- > Stonefalls 
	},
	[758] = {
		[101] = 0, -- Windhelm Outlaws Refuge -- > Eastmarch 
	},
	[759] = {
		[117] = 0, -- Stormhold Outlaws Refuge -- > Shadowfen 
	},
	[760] = {
		[57] = 0, -- Mournhold Outlaws Refuge -- > Deshaan 
	},
	[761] = {
		[103] = 0, -- Riften Outlaws Refuge -- > The Rift 
	},
	[763] = {
		[816] = 0, -- Secluded Sewers -- > Hew's Bane 
	},
	[764] = {
		[816] = 0, -- Underground Sepulcher -- > Hew's Bane 
	},
	[765] = {
		[823] = 0, -- Smuggler's Den -- > Gold Coast 
	},
	[766] = {
		[823] = 0, -- Trader's Cove -- > Gold Coast 
	},
	[767] = {
		[816] = 0, -- Deadhollow Halls -- > Hew's Bane 
	},
	[769] = {
		[823] = 0, -- Sewer Tenement -- > Gold Coast 
	},
	[770] = {
		[816] = 0, -- The Hideaway -- > Hew's Bane 
	},
	[771] = {
		[816] = 0, -- Glittering Grotto -- > Hew's Bane 
	},
	[773] = {
		[117] = 0, -- Cold-Blood Cavern -- > Shadowfen 
	},
	[774] = {
		[1086] = 0, -- Sugar-Slinger's Den -- > Northern Elsweyr 
	},
	[780] = {
		[684] = 0, -- Orsinium Outlaws Refuge -- > Wrothgar 
	},
	[808] = {
		[1160] = 0, -- Dragon Bridge Smuggler Caves -- > Western Skyrim 
	},
	[809] = {
		[199] = 0, -- The Wailing Prison -- > The Harborage 
	},
	[810] = {
		[381] = 0, -- Smuggler's Tunnel -- > Auridon 
	},
	[811] = {
		[535] = 7, -- Ancient Carzog's Demise -- > Betnikh 
	},
	[814] = {
		[684] = 0, -- Temple of Ire -- > Wrothgar 
	},
	[815] = {
		[684] = 0, -- Scarp Keep -- > Wrothgar 
	},
	[816] = {
		[816] = 0, -- Hew's Bane -- > Hew's Bane 
	},
	[817] = {
		[816] = 2, -- Bahraha's Gloom -- > Hew's Bane 
	},
	[818] = {
		[816] = 0, -- Iron Wheel Headquarters -- > Hew's Bane 
	},
	[819] = {
		[816] = 0, -- Al-Danobia Tomb -- > Hew's Bane 
	},
	[820] = {
		[816] = 0, -- Hubalajad Palace -- > Hew's Bane 
	},
	[821] = {
		[816] = 0, -- Thieves Den -- > Hew's Bane
	},
	[823] = {
		[823] = 0, -- Gold Coast -- > Gold Coast 
	},
	[824] = {
		[823] = 7, -- Hrota Cave -- > Gold Coast 
	},
	[825] = {
		[823] = 8, -- Garlas Agea -- > Gold Coast 
	},
	[826] = {
		[823] = 22, -- Dark Brotherhood Sanctuary -- > Gold Coast 
	},
	[827] = {
		[823] = 14, -- Jarol Estate -- > Gold Coast 
	},
	[828] = {
		[823] = 11, -- At-Himah Estate -- > Gold Coast 
	},
	[829] = {
		[823] = 9, -- Knightsgrave -- > Gold Coast 
	},
	[831] = {
		[823] = 0, -- Anvil Castle -- > Gold Coast 
	},
	[832] = {
		[823] = 5, -- Castle Kvatch -- > Gold Coast 
	},
	[833] = {
		[823] = 13, -- Enclave of the Hourglass -- > Gold Coast 
	},
	[834] = {
		[816] = 0, -- Fulstrom Homestead -- > Hew's Bane 
	},
	[836] = {
		[823] = 0, -- Cathedral of Akatosh -- > Gold Coast 
	},
	[837] = {
		[823] = 0, -- Anvil Outlaws Refuge -- > Gold Coast 
	},
	[841] = {
		[823] = 0, -- Jerall Mountains Logging Track -- > Gold Coast 
	},
	[842] = {
		[823] = 0, -- Blackwood Borderlands -- > Gold Coast 
	},
	[843] = {
		[117] = 62, -- Ruins of Mazzatun -- > Shadowfen 
	},
	[844] = {
		[816] = 0, -- Sulima Mansion -- > Hew's Bane 
	},
	[845] = {
		[816] = 0, -- Velmont Mansion -- > Hew's Bane 
	},
	[848] = {
		[117] = 61, -- Cradle of Shadows -- > Shadowfen 
	},
	[849] = {
		[849] = 0, -- Vvardenfell -- > Vvardenfell 
	},
	[852] = {
		[3] = 67, -- Captain Margaux's Place -- > Glenumbra 
	},
	[853] = {
		[20] = 59, -- Ravenhurst -- > Rivenspire 
	},
	[854] = {
		[92] = 62, -- Mournoth Keep -- > Bangkorai 
	},
	[855] = {
		[19] = 65, -- Hammerdeath Bungalow -- > Stormhaven 
	},
	[856] = {
		[92] = 63, -- Twin Arches -- > Bangkorai 
	},
	[857] = {
		[104] = 63, -- House of the Silent Magnifico -- > Alik'r Desert 
	},
	[858] = {
		[108] = 59, -- Cliffshade -- > Greenshade 
	},
	[859] = {
		[58] = 60, -- Black Vine Villa -- > Malabal Tor 
	},
	[860] = {
		[383] = 60, -- Snugpod -- > Grahtwood 
	},
	[861] = {
		[108] = 60, -- Bouldertree Refuge -- > Greenshade 
	},
	[862] = {
		[382] = 61, -- Sleek Creek House -- > Reaper's March 
	},
	[863] = {
		[537] = 17, -- Moonmirth House -- > Khenarthi's Roost 
	},
	[864] = {
		[103] = 62, -- Autumn's-Gate -- > The Rift 
	},
	[865] = {
		[101] = 58, -- Grymharth's Woe -- > Eastmarch 
	},
	[866] = {
		[57] = 62, -- Velothi Reverie -- > Deshaan 
	},
	[867] = {
		[41] = 67, -- Kragenhome -- > Stonefalls 
	},
	[868] = {
		[281] = 9, -- Humblemud -- > Bal Foyen 
	},
	[869] = {
		[117] = 64, -- The Ample Domicile -- > Shadowfen 
	},
	[870] = {
		[888] = 72, -- Domus Phrasticus -- > Craglorn 
	},
	[871] = {
		[58] = 61, -- Cyrodilic Jungle House -- > Malabal Tor 
	},
	[872] = {
		[382] = 59, -- Strident Springs Demesne -- > Reaper's March 
	},
	[873] = {
		[117] = 63, -- Stay-Moist Mansion -- > Shadowfen 
	},
	[874] = {
		[57] = 61, -- Quondam Indorilia -- > Deshaan 
	},
	[875] = {
		[103] = 61, -- Old Mistveil Manor -- > The Rift 
	},
	[876] = {
		[382] = 60, -- Dawnshadow -- > Reaper's March 
	},
	[877] = {
		[383] = 59, -- The Gorinir Estate -- > Grahtwood 
	},
	[878] = {
		[381] = 64, -- Mathiisen Manor -- > Auridon 
	},
	[879] = {
		[534] = 11, -- Hunding's Palatial Hall -- > Stros M'Kai 
	},
	[880] = {
		[92] = 61, -- Forsaken Stronghold -- > Bangkorai 
	},
	[881] = {
		[19] = 64, -- Gardner House -- > Stormhaven 
	},
	[882] = {
		[383] = 61, -- Grand Topal Hideaway -- > Grahtwood 
	},
	[883] = {
		[888] = 73, -- Earthtear Cavern -- > Craglorn 
	},
	[888] = {
		[888] = 0, -- Craglorn -- > Craglorn 
	},
	[889] = {
		[888] = 13, -- Molavar -- > Craglorn 
	},
	[890] = {
		[888] = 14, -- Rkundzelft -- > Craglorn 
	},
	[891] = {
		[888] = 15, -- Serpent's Nest -- > Craglorn 
	},
	[892] = {
		[888] = 17, -- Ilthag's Undertower -- > Craglorn 
	},
	[893] = {
		[888] = 16, -- Ruins of Kardala -- > Craglorn 
	},
	[894] = {
		[888] = 18, -- Loth'Na Caverns -- > Craglorn 
	},
	[895] = {
		[888] = 19, -- Rkhardahrk -- > Craglorn 
	},
	[896] = {
		[888] = 20, -- Haddock's Market -- > Craglorn 
	},
	[897] = {
		[888] = 21, -- Chiselshriek Mine -- > Craglorn 
	},
	[898] = {
		[888] = 22, -- Buried Sands -- > Craglorn 
	},
	[899] = {
		[888] = 23, -- Mtharnaz -- > Craglorn 
	},
	[900] = {
		[888] = 24, -- The Howling Sepulchers -- > Craglorn 
	},
	[901] = {
		[888] = 25, -- Balamath -- > Craglorn 
	},
	[902] = {
		[888] = 26, -- Fearfangs Cavern -- > Craglorn 
	},
	[903] = {
		[888] = 27, -- Exarch's Stronghold -- > Craglorn 
	},
	[904] = {
		[888] = 28, -- Zalgaz's Den -- > Craglorn 
	},
	[905] = {
		[888] = 29, -- Tombs of the Na-Totambu -- > Craglorn 
	},
	[906] = {
		[888] = 30, -- Hircine's Haunt -- > Craglorn 
	},
	[907] = {
		[888] = 5, -- Rahni'Za, School of Warriors -- > Craglorn 
	},
	[908] = {
		[888] = 7, -- Shada's Tear -- > Craglorn 
	},
	[909] = {
		[888] = 6, -- Seeker's Archive -- > Craglorn 
	},
	[910] = {
		[888] = 8, -- Elinhir Sewerworks -- > Craglorn 
	},
	[911] = {
		[888] = 0, -- Reinhold's Retreat -- > Craglorn 
	},
	[913] = {
		[888] = 9, -- The Mage's Staff -- > Craglorn 
	},
	[914] = {
		[888] = 35, -- Skyreach Catacombs -- > Craglorn 
	},
	[915] = {
		[888] = 18, -- Skyreach Temple -- > Craglorn 
	},
	[916] = {
		[888] = 34, -- Skyreach Pinnacle -- > Craglorn 
	},
	[917] = {
		[917] = 0, -- zTestBarbershop -- > zTestBarbershop 
	},
	[918] = {
		[849] = 34, -- Nchuleftingth -- > Vvardenfell 
	},
	[919] = {
		[849] = 35, -- Forgotten Wastes -- > Vvardenfell 
	},
	[920] = {
		[849] = 0, -- Inanius Egg Mine -- > Vvardenfell 
	},
	[921] = {
		[849] = 2, -- Khartag Point -- > Vvardenfell 
	},
	[922] = {
		[849] = 4, -- Zainsipilu -- > Vvardenfell 
	},
	[923] = {
		[849] = 5, -- Matus-Akin Egg Mine -- > Vvardenfell 
	},
	[924] = {
		[849] = 6, -- Pulk -- > Vvardenfell 
	},
	[925] = {
		[849] = 7, -- Nchuleft -- > Vvardenfell 
	},
	[926] = {
		[849] = 0, -- Pinsun -- > Vvardenfell 
	},
	[927] = {
		[849] = 47, -- Vassir-Didanat Mine -- > Vvardenfell 
	},
	[928] = {
		[849] = 0, -- Zalkin-Sul Egg Mine -- > Vvardenfell 
	},
	[929] = {
		[849] = 0, -- Gnisis Egg Mine -- > Vvardenfell 
	},
	[930] = {
		[57] = 60, -- Darkshade Caverns II -- > Deshaan 
	},
	[931] = {
		[383] = 58, -- Elden Hollow II -- > Grahtwood 
	},
	[932] = {
		[20] = 58, -- Crypt of Hearts II -- > Rivenspire 
	},
	[933] = {
		[19] = 62, -- Wayrest Sewers II -- > Stormhaven 
	},
	[934] = {
		[41] = 66, -- Fungal Grotto II -- > Stonefalls 
	},
	[935] = {
		[381] = 61, -- The Banished Cells II -- > Auridon 
	},
	[936] = {
		[3] = 66, -- Spindleclutch II -- > Glenumbra 
	},
	[937] = {
		[57] = 63, -- Flaming Nix Deluxe Garret -- > Deshaan 
	},
	[938] = {
		[104] = 62, -- Sisters of the Sands Apartment -- > Alik'r Desert 
	},
	[939] = {
		[381] = 62, -- Barbed Hook Private Room -- > Auridon 
	},
	[940] = {
		[381] = 63, -- Mara's Kiss Public House -- > Auridon 
	},
	[941] = {
		[41] = 68, -- The Ebony Flask Inn Room -- > Stonefalls 
	},
	[942] = {
		[3] = 68, -- The Rosy Lion -- > Glenumbra 
	},
	[943] = {
		[3] = 69, -- Daggerfall Overlook -- > Glenumbra 
	},
	[944] = {
		[382] = 58, -- Serenity Falls Estate -- > Reaper's March 
	},
	[945] = {
		[41] = 69, -- Ebonheart Chateau -- > Stonefalls 
	},
	[946] = {
		[849] = 0, -- Bal Ur -- > Vvardenfell 
	},
	[947] = {
		[849] = 0, -- Ramimilk -- > Vvardenfell 
	},
	[948] = {
		[849] = 0, -- Tusenend -- > Vvardenfell 
	},
	[949] = {
		[849] = 0, -- Dreudurai Glass Mine -- > Vvardenfell 
	},
	[950] = {
		[849] = 0, -- Zaintiraris -- > Vvardenfell 
	},
	[951] = {
		[849] = 0, -- Vassamsi Mine -- > Vvardenfell 
	},
	[952] = {
		[849] = 0, -- Shulk Ore Mine -- > Vvardenfell 
	},
	[953] = {
		[849] = 0, -- Arkngthunch-Sturdumz -- > Vvardenfell 
	},
	[954] = {
		[849] = 0, -- Galom Daeus -- > Vvardenfell 
	},
	[955] = {
		[849] = 0, -- Mallapi Cave -- > Vvardenfell 
	},
	[956] = {
		[849] = 0, -- Kaushtarari -- > Vvardenfell 
	},
	[957] = {
		[849] = 90, -- Dreloth Ancestral Tomb -- > Vvardenfell 
	},
	[958] = {
		[849] = 64, -- Veloth Ancestral Tomb -- > Vvardenfell 
	},
	[959] = {
		[849] = 0, -- Andrano Ancestral Tomb -- > Vvardenfell 
	},
	[960] = {
		[849] = 0, -- Hleran Ancestral Tomb -- > Vvardenfell 
	},
	[961] = {
		[849] = 3, -- Ashalmawia -- > Vvardenfell 
	},
	[962] = {
		[849] = 0, -- Library of Andule -- > Vvardenfell 
	},
	[963] = {
		[849] = 0, -- Barilzar's Tower -- > Vvardenfell 
	},
	[964] = {
		[849] = 0, -- Ashimanu Cave -- > Vvardenfell 
	},
	[965] = {
		[849] = 0, -- Skar -- > Vvardenfell 
	},
	[966] = {
		[849] = 0, -- Cavern of the Incarnate -- > Vvardenfell 
	},
	[967] = {
		[849] = 0, -- Clockwork City Vault -- > Vvardenfell 
	},
	[968] = {
		[849] = 0, -- Firemoth Island -- > Vvardenfell 
	},
	[969] = {
		[849] = 0, -- Ashurnibibi -- > Vvardenfell 
	},
	[970] = {
		[849] = 0, -- Redoran Garrison -- > Vvardenfell 
	},
	[971] = {
		[849] = 0, -- Vivec City Outlaws Refuge -- > Vvardenfell 
	},
	[972] = {
		[849] = 0, -- Kudanat Mine -- > Vvardenfell 
	},
	[973] = {
		[888] = 74, -- Bloodroot Forge -- > Craglorn 
	},
	[974] = {
		[888] = 75, -- Falkreath Hold -- > Craglorn 
	},
	[975] = {
		[849] = 12, -- Halls of Fabrication -- > Vvardenfell 
	},
	[977] = {
		[849] = 0, -- Prison of Xykenaz -- > Vvardenfell 
	},
	[979] = {
		[849] = 0, -- Clockwork City Vault -- > Vvardenfell 
	},
	[980] = {
		[980] = 0, -- Clockwork City -- > Clockwork City 
	},
	[981] = {
		[980] = 17, -- The Brass Fortress -- > Clockwork City 
	},
	[982] = {
		[980] = 0, -- Slag Town Outlaws Refuge -- > Clockwork City 
	},
	[983] = {
		[980] = 0, -- Mechanical Fundament -- > Clockwork City 
	},
	[984] = {
		[980] = 0, -- Machine District -- > Clockwork City 
	},
	[985] = {
		[980] = 1, -- Halls of Regulation -- > Clockwork City 
	},
	[986] = {
		[980] = 2, -- The Shadow Cleft -- > Clockwork City 
	},
	[988] = {
		[980] = 0, -- Clockwork City Vaults -- > Clockwork City 
	},
	[989] = {
		[980] = 12, -- Ventral Terminus -- > Clockwork City 
	},
	[990] = {
		[980] = 0, -- Incarnatorium -- > Clockwork City 
	},
	[991] = {
		[980] = 0, -- Cogitum Centralis -- > Clockwork City 
	},
	[992] = {
		[980] = 6, -- Everwound Wellspring -- > Clockwork City 
	},
	[993] = {
		[980] = 7, -- Mnemonic Planisphere -- > Clockwork City 
	},
	[994] = {
		[849] = 36, -- Saint Delyn Penthouse -- > Vvardenfell 
	},
	[995] = {
		[849] = 37, -- Amaya Lake Lodge -- > Vvardenfell 
	},
	[996] = {
		[849] = 68, -- Tel Galen -- > Vvardenfell 
	},
	[997] = {
		[849] = 38, -- Ald Velothi Harbor House -- > Vvardenfell 
	},
	[998] = {
		[381] = 0, -- Dranil Kir -- > Auridon 
	},
	[999] = {
		[980] = 0, -- Evergloam -- > Clockwork City 
	},
	[1000] = {
		[981] = 4, -- Asylum Sanctorium -- > The Brass Fortress 
	},
	[1004] = {
		[980] = 0, -- The Serviflume -- > Clockwork City 
	},
	[1005] = {
		[823] = 23, -- Linchal Grand Manor -- > Gold Coast 
	},
	[1006] = {
		[3] = 70, -- Exorcised Coven Cottage -- > Glenumbra 
	},
	[1007] = {
		[888] = 76, -- Hakkvild's High Hall -- > Craglorn 
	},
	[1008] = {
		[347] = 57, -- Coldharbour Surreal Estate -- > Coldharbour 
	},
	[1009] = {
		[92] = 64, -- Fang Lair -- > Bangkorai 
	},
	[1010] = {
		[19] = 66, -- Scalecaller Peak -- > Stormhaven 
	},
	[1011] = {
		[1011] = 0, -- Summerset -- > Summerset 
	},
	[1012] = {
		[381] = 0, -- The Spiral Skein -- > Auridon 
	},
	[1013] = {
		[1011] = 0, -- Eldbur Sanctuary -- > Summerset 
	},
	[1014] = {
		[1011] = 23, -- Tor-Hame-Khard -- > Summerset 
	},
	[1015] = {
		[1011] = 21, -- Eton Nir Grotto -- > Summerset 
	},
	[1016] = {
		[1027] = 4, -- Traitor's Vault -- > Artaeum 
	},
	[1017] = {
		[1011] = 22, -- Archon's Grove -- > Summerset 
	},
	[1018] = {
		[1011] = 20, -- King's Haven Pass -- > Summerset 
	},
	[1019] = {
		[1011] = 24, -- Wasten Coraldale -- > Summerset 
	},
	[1020] = {
		[1011] = 26, -- Karnwasten -- > Summerset 
	},
	[1021] = {
		[1011] = 25, -- Sunhold -- > Summerset 
	},
	[1022] = {
		[1011] = 10, -- Direnni Acropolis -- > Summerset 
	},
	[1023] = {
		[1011] = 8, -- Shimmerene Waterworks -- > Summerset 
	},
	[1024] = {
		[1011] = 50, -- Eldbur Ruins -- > Summerset 
	},
	[1280] = {
		[108] = 0, -- Waking Flame Fargrave Conclave -- > Greenshade 
	},
	[1025] = {
		[1011] = 14, -- Cey-Tarn Keep -- > Summerset 
	},
	[1026] = {
		[1011] = 0, -- The Vaults of Heinarwe -- > Summerset 
	},
	[1027] = {
		[1027] = 0, -- Artaeum -- > Artaeum 
	},
	[1028] = {
		[1011] = 0, -- Alinor Outlaws Refuge -- > Summerset 
	},
	[1029] = {
		[1011] = 0, -- Ebon Sanctum -- > Summerset 
	},
	[1030] = {
		[1011] = 18, -- Corgrad Wastes -- > Summerset 
	},
	[1031] = {
		[1011] = 0, -- Illumination Academy Stacks -- > Summerset 
	},
	[1032] = {
		[1011] = 16, -- Sea Keep -- > Summerset 
	},
	[1033] = {
		[1011] = 0, -- Red Temple Catacombs -- > Summerset 
	},
	[1034] = {
		[1011] = 0, -- College of Sapiarchs -- > Summerset 
	},
	[1035] = {
		[1011] = 0, -- The Spiral Skein -- > Summerset 
	},
	[1036] = {
		[1011] = 35, -- Cathedral of Webs -- > Summerset 
	},
	[1037] = {
		[1011] = 0, -- The Crystal Tower -- > Summerset 
	},
	[1038] = {
		[1011] = 0, -- Rellenthil Sinkhole -- > Summerset 
	},
	[1039] = {
		[1011] = 0, -- Psijic Relic Vaults -- > Summerset 
	},
	[1040] = {
		[1011] = 0, -- Evergloam -- > Summerset 
	},
	[1297] = {
		[1286] = 11, -- The Brandfire Reformatory -- > The Deadlands 
	},
	[1042] = {
		[684] = 58, -- Pariah's Pinnacle -- > Wrothgar 
	},
	[1043] = {
		[980] = 8, -- The Orbservatory Prior -- > Clockwork City 
	},
	[1044] = {
		[823] = 24, -- The Erstwhile Sanctuary -- > Gold Coast 
	},
	[1045] = {
		[816] = 25, -- Princely Dawnlight Palace -- > Hew's Bane 
	},
	[1046] = {
		[1011] = 0, -- Saltbreeze Cave -- > Summerset 
	},
	[1047] = {
		[1011] = 0, -- Monastery of Serene Harmony -- > Summerset 
	},
	[1048] = {
		[1011] = 0, -- Alinor Royal Palace -- > Summerset 
	},
	[1306] = {
		[58] = 62, -- Doomchar Plateau -- > Malabal Tor 
	},
	[1051] = {
		[1011] = 54, -- Cloudrest -- > Summerset 
	},
	[1052] = {
		[382] = 62, -- Moon Hunter Keep -- > Reaper's March 
	},
	[1310] = {
		[1286] = 0, -- Atoll of Immolation -- > The Deadlands 
	},
	[1055] = {
		[108] = 61, -- March of Sacrifices -- > Greenshade 
	},
	[1312] = {
		[849] = 0, -- Sareloth Grotto -- > Vvardenfell 
	},
	[1314] = {
		[3] = 0, -- Sword's Rest Isle -- > Glenumbra 
	},
	[1059] = {
		[1011] = 59, -- Golden Gryphon Garret -- > Summerset 
	},
	[1060] = {
		[1011] = 60, -- Alinor Crest Townhouse -- > Summerset 
	},
	[1061] = {
		[1011] = 61, -- Colossal Aldmeri Grotto -- > Summerset 
	},
	[1063] = {
		[1027] = 6, -- Grand Psijic Villa -- > Artaeum 
	},
	[1064] = {
		[103] = 63, -- Hunter's Glade -- > The Rift 
	},
	[1065] = {
		[726] = 0, -- Blight Bog Sump -- > Murkmire 
	},
	[1066] = {
		[726] = 11, -- Tsofeer Cavern -- > Murkmire 
	},
	[1067] = {
		[726] = 0, -- The Dreaming Nest -- > Murkmire 
	},
	[1068] = {
		[726] = 0, -- Ixtaxh Xanmeer -- > Murkmire 
	},
	[1069] = {
		[726] = 0, -- Tomb of Many Spears -- > Murkmire 
	},
	[1070] = {
		[726] = 0, -- Lilmoth Outlaws Refuge -- > Murkmire 
	},
	[1071] = {
		[726] = 0, -- Xul-Thuxis -- > Murkmire 
	},
	[1072] = {
		[117] = 0, -- Norg-Tzel -- > Shadowfen 
	},
	[1073] = {
		[726] = 12, -- Teeth of Sithis -- > Murkmire 
	},
	[1074] = {
		[41] = 0, -- The Sunless Hollow -- > Stonefalls 
	},
	[1075] = {
		[381] = 0, -- The Sunless Hollow -- > Auridon 
	},
	[1076] = {
		[3] = 0, -- The Sunless Hollow -- > Glenumbra 
	},
	[1077] = {
		[726] = 0, -- The Swallowed Grove -- > Murkmire 
	},
	[1078] = {
		[726] = 0, -- Remnant of Argon -- > Murkmire 
	},
	[1079] = {
		[726] = 0, -- Vakka-Bok Xanmeer -- > Murkmire 
	},
	[1080] = {
		[101] = 60, -- Frostvault -- > Eastmarch 
	},
	[1081] = {
		[823] = 25, -- Depths of Malatar -- > Gold Coast 
	},
	[1082] = {
		[726] = 8, -- Blackrose Prison -- > Murkmire 
	},
	[1083] = {
		[726] = 0, -- Deep-Root -- > Murkmire 
	},
	[1345] = {
		[535] = 10, -- Seaveil Spire -- > Betnikh 
	},
	[1085] = {
		[1086] = 0, -- Halls of Colossus -- > Northern Elsweyr 
	},
	[1086] = {
		[1086] = 0, -- Northern Elsweyr -- > Northern Elsweyr 
	},
	[1343] = {
		[1286] = 21, -- Agony's Ascent -- > The Deadlands 
	},
	[1088] = {
		[1086] = 0, -- Rimmen Outlaws Refuge -- > Northern Elsweyr 
	},
	[1089] = {
		[1086] = 13, -- Rimmen Necropolis -- > Northern Elsweyr 
	},
	[1090] = {
		[1086] = 14, -- Orcrest -- > Northern Elsweyr 
	},
	[1091] = {
		[1086] = 7, -- Abode of Ignominy -- > Northern Elsweyr 
	},
	[1092] = {
		[1086] = 8, -- Predator Mesa -- > Northern Elsweyr 
	},
	[1342] = {
		[1282] = 3, -- Ossa Accentium -- > Fargrave 
	},
	[1094] = {
		[1086] = 10, -- Tomb of the Serpents -- > Northern Elsweyr 
	},
	[1095] = {
		[1086] = 11, -- Darkpool Mine -- > Northern Elsweyr 
	},
	[1096] = {
		[1086] = 12, -- The Tangle -- > Northern Elsweyr 
	},
	[1097] = {
		[1086] = 35, -- Sleepy Senche Mine -- > Northern Elsweyr 
	},
	[1098] = {
		[1086] = 15, -- Riverhold -- > Northern Elsweyr 
	},
	[1099] = {
		[1086] = 16, -- Rimmen Palace -- > Northern Elsweyr 
	},
	[1311] = {
		[849] = 0, -- Ascendant Order Hideout -- > Vvardenfell 
	},
	[1101] = {
		[1086] = 0, -- Rimmen Palace Recesses -- > Northern Elsweyr 
	},
	[1102] = {
		[1086] = 0, -- Sepulcher of Mischance -- > Northern Elsweyr 
	},
	[1103] = {
		[1086] = 34, -- Moon Gate of Anequina -- > Northern Elsweyr 
	},
	[1307] = {
		[1261] = 77, -- Sweetwater Cascades -- > Blackwood 
	},
	[1105] = {
		[1086] = 0, -- Skooma Cat's Cloister -- > Northern Elsweyr 
	},
	[1106] = {
		[1086] = 32, -- Star Haven Adeptorium -- > Northern Elsweyr 
	},
	[1107] = {
		[1107] = 0, -- zWicksTest -- > zWicksTest 
	},
	[1108] = {
		[726] = 24, -- Lakemire Xanmeer Manor -- > Murkmire 
	},
	[1109] = {
		[101] = 59, -- Enchanted Snow Globe Home -- > Eastmarch 
	},
	[1110] = {
		[1086] = 0, -- Dov-Vahl Shrine -- > Northern Elsweyr 
	},
	[1111] = {
		[1086] = 0, -- Cicatrice Caverns -- > Northern Elsweyr 
	},
	[1112] = {
		[1086] = 0, -- Tenarr Zalviit Ossuary -- > Northern Elsweyr 
	},
	[1113] = {
		[1086] = 0, -- Hidden Moon Crypts -- > Northern Elsweyr 
	},
	[1114] = {
		[1086] = 0, -- Hakoshae Tombs -- > Northern Elsweyr 
	},
	[1115] = {
		[1086] = 0, -- Merryvale Sugar Farm Caves -- > Northern Elsweyr 
	},
	[1116] = {
		[1116] = 0, -- Moon Gate -- > Moon Gate 
	},
	[1117] = {
		[1086] = 0, -- Shadow Dance Temple -- > Northern Elsweyr 
	},
	[1118] = {
		[1086] = 0, -- Vault of the Heavenly Scourge -- > Northern Elsweyr 
	},
	[1119] = {
		[1086] = 45, -- Desert Wind Caverns -- > Northern Elsweyr 
	},
	[1120] = {
		[1086] = 0, -- Meirvale Keep -- > Northern Elsweyr 
	},
	[1121] = {
		[1086] = 47, -- Sunspire -- > Northern Elsweyr 
	},
	[1122] = {
		[1086] = 48, -- Moongrave Fane -- > Northern Elsweyr 
	},
	[1123] = {
		[383] = 62, -- Lair of Maarselok -- > Grahtwood 
	},
	[1304] = {
		[1283] = 3, -- The Bathhouse -- > The Shambles 
	},
	[1125] = {
		[101] = 61, -- Frostvault Chasm -- > Eastmarch 
	},
	[1126] = {
		[888] = 77, -- Elinhir Private Arena -- > Craglorn 
	},
	[1302] = {
		[20] = 61, -- Shipwright's Regret -- > Rivenspire 
	},
	[1128] = {
		[1086] = 49, -- Sugar Bowl Suite -- > Northern Elsweyr 
	},
	[1129] = {
		[1086] = 51, -- Hall of the Lunar Champion -- > Northern Elsweyr 
	},
	[1130] = {
		[1086] = 50, -- Jode's Embrace -- > Northern Elsweyr 
	},
	[1301] = {
		[1011] = 62, -- Coral Aerie -- > Summerset 
	},
	[1300] = {
		[1286] = 0, -- Fort Grief -- > The Deadlands 
	},
	[1133] = {
		[1133] = 0, -- Southern Elsweyr -- > Southern Elsweyr 
	},
	[1134] = {
		[1133] = 10, -- Forsaken Citadel -- > Southern Elsweyr 
	},
	[1135] = {
		[1133] = 9, -- Moonlit Cove -- > Southern Elsweyr 
	},
	[1136] = {
		[1133] = 16, -- Zazaradi's Quarry and Mine -- > Southern Elsweyr 
	},
	[1137] = {
		[1133] = 0, -- Path of Pride -- > Southern Elsweyr 
	},
	[1138] = {
		[1133] = 0, -- Dragonhold -- > Southern Elsweyr 
	},
	[1139] = {
		[1133] = 0, -- Senchal Outlaws Refuge -- > Southern Elsweyr 
	},
	[1140] = {
		[104] = 0, -- Wind Scour Temple -- > Alik'r Desert 
	},
	[1141] = {
		[101] = 0, -- Dark Water Temple -- > Eastmarch 
	},
	[1142] = {
		[1142] = 0, -- The Valley of Blades -- > The Valley of Blades 
	},
	[1143] = {
		[19] = 0, -- Storm Talon Temple -- > Stormhaven 
	},
	[1144] = {
		[1144] = 0, -- Vahlokzin's Lair -- > Vahlokzin's Lair 
	},
	[1145] = {
		[1133] = 0, -- Passage of Dad'na Ghaten -- > Southern Elsweyr 
	},
	[1146] = {
		[1133] = 0, -- Tideholm -- > Southern Elsweyr 
	},
	[1147] = {
		[1133] = 0, -- New Moon Fortress -- > Southern Elsweyr 
	},
	[1148] = {
		[1133] = 0, -- Halls of the Highmane -- > Southern Elsweyr 
	},
	[1149] = {
		[1133] = 18, -- Doomstone Keep -- > Southern Elsweyr 
	},
	[1150] = {
		[1133] = 0, -- Doomstone Caverns -- > Southern Elsweyr 
	},
	[1151] = {
		[1133] = 0, -- Dragonhold Ruins -- > Southern Elsweyr 
	},
	[1152] = {
		[684] = 59, -- Icereach -- > Wrothgar 
	},
	[1153] = {
		[92] = 65, -- Unhallowed Grave -- > Bangkorai 
	},
	[1154] = {
		[1086] = 53, -- Moon-Sugar Meadow -- > Northern Elsweyr 
	},
	[1155] = {
		[20] = 60, -- Wraithhome -- > Rivenspire 
	},
	[1298] = {
		[1286] = 15, -- False Martyrs' Folly -- > The Deadlands 
	},
	[1296] = {
		[1286] = 0, -- Fort Sundercliff -- > The Deadlands 
	},
	[1295] = {
		[1286] = 12, -- Destruction's Solace -- > The Deadlands 
	},
	[1294] = {
		[1286] = 0, -- Isle of Joys -- > The Deadlands 
	},
	[1160] = {
		[1160] = 0, -- Western Skyrim -- > Western Skyrim 
	},
	[1161] = {
		[1161] = 0, -- Blackreach: Greymoor Caverns -- > Blackreach: Greymoor Caverns 
	},
	[1293] = {
		[1282] = 0, -- Fargrave Outlaws Refuge -- > Fargrave 
	},
	[1292] = {
		[1286] = 0, -- The Path of Cinders -- > The Deadlands 
	},
	[1291] = {
		[1286] = 9, -- Ardent Hope -- > The Deadlands 
	},
	[1165] = {
		[1161] = 14, -- The Scraps -- > Blackreach: Greymoor Caverns 
	},
	[1166] = {
		[1160] = 10, -- Chillwind Depths -- > Western Skyrim 
	},
	[1167] = {
		[1160] = 11, -- Dragonhome -- > Western Skyrim 
	},
	[1168] = {
		[1160] = 8, -- Frozen Coast -- > Western Skyrim 
	},
	[1169] = {
		[1161] = 13, -- Midnight Barrow -- > Blackreach: Greymoor Caverns 
	},
	[1170] = {
		[1160] = 9, -- Shadowgreen -- > Western Skyrim 
	},
	[1171] = {
		[1161] = 0, -- Not Used/REUSE? -- > Blackreach: Greymoor Caverns 
	},
	[1172] = {
		[1161] = 2, -- Greymoor Keep -- > Blackreach: Greymoor Caverns 
	},
	[1173] = {
		[1161] = 0, -- Greymoor Keep: West Wing -- > Blackreach: Greymoor Caverns 
	},
	[1174] = {
		[1160] = 0, -- Verglas Hollow -- > Western Skyrim 
	},
	[1175] = {
		[1175] = 0, -- Not used/REUSE? -- > Not used/REUSE? 
	},
	[1176] = {
		[1160] = 5, -- Kilkreath Temple -- > Western Skyrim 
	},
	[1177] = {
		[1160] = 0, -- Bleakridge Barrow -- > Western Skyrim 
	},
	[1178] = {
		[1160] = 0, -- Solitude Outlaws Refuge -- > Western Skyrim 
	},
	[1179] = {
		[1160] = 0, -- Mor Khazgur Mine -- > Western Skyrim 
	},
	[1180] = {
		[383] = 0, -- Imperial Cache Annex -- > Grahtwood 
	},
	[1181] = {
		[1161] = 0, -- Kagnthamz -- > Blackreach: Greymoor Caverns 
	},
	[1182] = {
		[1160] = 0, -- Morthal Barrow -- > Western Skyrim 
	},
	[1183] = {
		[1161] = 0, -- Tzinghalis's Tower -- > Blackreach: Greymoor Caverns 
	},
	[1184] = {
		[1161] = 0, -- Castle Dour -- > Blackreach: Greymoor Caverns 
	},
	[1185] = {
		[1160] = 0, -- Deepwood Vale -- > Western Skyrim 
	},
	[1186] = {
		[1160] = 12, -- Labyrinthian -- > Western Skyrim 
	},
	[1187] = {
		[1161] = 17, -- Nchuthnkarst -- > Blackreach: Greymoor Caverns 
	},
	[1188] = {
		[101] = 0, -- Palace of Kings -- > Eastmarch 
	},
	[1189] = {
		[101] = 0, -- Palace of Kings -- > Eastmarch 
	},
	[1190] = {
		[103] = 21, -- Riften Ratway -- > The Rift 
	},
	[1191] = {
		[101] = 0, -- Blackreach -- > Eastmarch 
	},
	[1192] = {
		[1133] = 23, -- Lucky Cat Landing -- > Southern Elsweyr 
	},
	[1193] = {
		[1133] = 24, -- Potentate's Retreat -- > Southern Elsweyr 
	},
	[1290] = {
		[1286] = 0, -- Deadlight -- > The Deadlands 
	},
	[1195] = {
		[1195] = 13, -- The Undergrove -- > in Midnight Barrow -- > Blackreach: Greymoor Caverns 
	},
	[1196] = {
		[1160] = 39, -- Kyne's Aegis -- > Western Skyrim 
	},
	[1197] = {
		[1161] = 30, -- Stone Garden -- > Blackreach: Greymoor Caverns 
	},
	[1289] = {
		[1286] = 0, -- Fort Grief Citadel -- > The Deadlands 
	},
	[1199] = {
		[684] = 60, -- Forgemaster Falls -- > Wrothgar 
	},
	[1200] = {
		[92] = 66, -- Thieves' Oasis -- > Bangkorai 
	},
	[1201] = {
		[1160] = 57, -- Castle Thorn -- > Western Skyrim 
	},
	[1287] = {
		[1286] = 16, -- Wretched Spire -- > The Deadlands 
	},
	[1286] = {
		[1286] = 0, -- The Deadlands -- > The Deadlands 
	},
	[1204] = {
		[1204] = 0, -- RTeaser1 -- > RTeaser1 
	},
	[1205] = {
		[20] = 0, -- Grayhome -- > Rivenspire 
	},
	[1206] = {
		[20] = 0, -- Grayhome Ritual Chamber -- > Rivenspire 
	},
	[1207] = {
		[1207] = 0, -- The Reach -- > The Reach 
	},
	[1208] = {
		[1208] = 0, -- Blackreach: Arkthzand Cavern -- > Blackreach: Arkthzand Cavern 
	},
	[1209] = {
		[1208] = 6, -- Gloomreach -- > Blackreach: Arkthzand Cavern 
		[1207] = 23, -- Gloomreach -- > The Reach 
	},
	[1210] = {
		[1207] = 3, -- Briar Rock Ruins -- > The Reach 
	},
	[1211] = {
		[1207] = 0, -- Markarth Outlaws Refuge -- > The Reach 
	},
	[1212] = {
		[1208] = 0, -- Arkthzand Research Wing -- > Blackreach: Arkthzand Cavern 
	},
	[1213] = {
		[1207] = 0, -- Sanuarach Mine -- > The Reach 
	},
	[1214] = {
		[1208] = 3, -- Bthar-Zel -- > Blackreach: Arkthzand Cavern 
	},
	[1215] = {
		[1207] = 0, -- Bthar-Zel Vaults -- > The Reach 
	},
	[1216] = {
		[1207] = 0, -- The Dark Descent -- > The Reach 
	},
	[1217] = {
		[1208] = 0, -- The Arkthzand Orrery -- > Blackreach: Arkthzand Cavern 
	},
	[1218] = {
		[1160] = 56, -- Snowmelt Suite -- > Western Skyrim 
	},
	[1219] = {
		[1160] = 55, -- Proudspire Manor -- > Western Skyrim 
	},
	[1220] = {
		[1161] = 29, -- Bastion Sanguinaris -- > Blackreach: Greymoor Caverns 
	},
	[1221] = {
		[1207] = 0, -- Grayhaven -- > The Reach 
	},
	[1222] = {
		[1207] = 21, -- Valthume -- > The Reach 
	},
	[1223] = {
		[1207] = 22, -- Lost Valley Redoubt -- > The Reach 
	},
	[1224] = {
		[1208] = 5, -- Nighthollow Keep -- > Blackreach: Arkthzand Cavern 
	},
	[1225] = {
		[1208] = 1, -- Nchuand-Zel -- > Blackreach: Arkthzand Cavern 
	},
	[1226] = {
		[1207] = 18, -- Reachwind Depths -- > The Reach 
	},
	[1227] = {
		[1207] = 19, -- Vateshran Hollows -- > The Reach 
	},
	[1228] = {
		[823] = 26, -- Black Drake Villa -- > Gold Coast 
	},
	[1229] = {
		[57] = 64, -- The Cauldron -- > Deshaan 
	},
	[1285] = {
		[1286] = 8, -- Burning Gyre Keep -- > The Deadlands 
	},
	[1284] = {
		[1282] = 0, -- The Collector's Villa -- > Fargrave 
	},
	[1283] = {
		[1283] = 0, -- The Shambles -- > The Shambles 
	},
	[1233] = {
		[1160] = 60, -- Antiquarian's Alpine Gallery -- > Western Skyrim 
	},
	[1234] = {
		[1160] = 61, -- Stillwaters Retreat -- > Western Skyrim 
	},
	[1235] = {
		[383] = 0, -- Ne Salas Cache Annex -- > Grahtwood 
	},
	[1236] = {
		[383] = 0, -- Imperial Sewers -- > Grahtwood 
	},
	[1237] = {
		[383] = 0, -- The Deadlands: Testing Grounds -- > Grahtwood 
	},
	[1238] = {
		[1261] = 7, -- Tidewater Cave -- > Blackwood 
	},
	[1239] = {
		[1261] = 21, -- Welke -- > Blackwood 
	},
	[1240] = {
		[1261] = 0, -- Leyawiin Castle -- > Blackwood 
	},
	[1241] = {
		[1261] = 0, -- Doomvault Capraxus -- > Blackwood 
	},
	[1242] = {
		[1261] = 0, -- Vandacia's Deadlands Keep -- > Blackwood 
	},
	[1243] = {
		[1261] = 14, -- Fort Redmane -- > Blackwood 
	},
	[1244] = {
		[1261] = 0, -- Isle of Balfiera -- > Blackwood 
	},
	[1245] = {
		[1261] = 0, -- Borderwatch Ruins -- > Blackwood 
	},
	[1246] = {
		[1261] = 8, -- Deepscorn Hollow -- > Blackwood 
	},
	[1247] = {
		[1261] = 12, -- Veyond -- > Blackwood 
	},
	[1248] = {
		[1261] = 15, -- Doomvault Vulpinaz -- > Blackwood 
	},
	[1249] = {
		[1261] = 0, -- Twyllbek Ruins -- > Blackwood 
	},
	[1250] = {
		[1261] = 0, -- Glenbridge Xanmeer -- > Blackwood 
	},
	[1251] = {
		[1261] = 0, -- Xynaa's Sanctuary -- > Blackwood 
	},
	[1252] = {
		[1261] = 0, -- Leyawiin Outlaws Refuge -- > Blackwood 
	},
	[1253] = {
		[1261] = 3, -- Undertow Cavern -- > Blackwood 
	},
	[1254] = {
		[1261] = 17, -- Arpenia -- > Blackwood 
	},
	[1255] = {
		[1261] = 22, -- Bloodrun Cave -- > Blackwood 
	},
	[1256] = {
		[1261] = 29, -- Doomvault Porcixid -- > Blackwood 
	},
	[1257] = {
		[1261] = 42, -- Xi-Tsei -- > Blackwood 
	},
	[1258] = {
		[1261] = 34, -- Vunalk -- > Blackwood 
	},
	[1259] = {
		[1261] = 19, -- Zenithar's Abbey -- > Blackwood 
	},
	[1260] = {
		[1261] = 32, -- The Silent Halls -- > Blackwood 
	},
	[1261] = {
		[1261] = 0, -- Blackwood -- > Blackwood 
	},
	[1262] = {
		[19] = 0, -- Festival Arena -- > Stormhaven 
	},
	[1263] = {
		[1261] = 38, -- Rockgrove -- > Blackwood 
	},
	[1264] = {
		[1207] = 35, -- Stone Eagle Aerie -- > The Reach 
	},
	[1265] = {
		[1160] = 62, -- Shalidor's Shrouded Realm -- > Western Skyrim 
	},
	[1266] = {
		[1261] = 0, -- Xal Irasotl -- > Blackwood 
	},
	[1267] = {
		[3] = 71, -- Red Petal Bastion -- > Glenumbra 
	},
	[1268] = {
		[1261] = 67, -- The Dread Cellar -- > Blackwood 
	},
	[1282] = {
		[1283] = 5, -- Fargrave -- > The Shambles 
	},
	[1270] = {
		[849] = 91, -- Kushalit Sanctuary -- > Vvardenfell 
	},
	[1271] = {
		[823] = 27, -- Varlaisvea Ayleid Ruins -- > Gold Coast 
	},
	[1272] = {
		[1261] = 0, -- Atoll of Immolation -- > Blackwood 
	},
	[1281] = {
		[108] = 0, -- Waking Flame Fargrave Conclave -- > Greenshade 
	},
	[1274] = {
		[3] = 0, -- Garden of Shadows -- > Glenumbra 
	},
	[1275] = {
		[1261] = 53, -- Pilgrim's Rest -- > Blackwood 
	},
	[1276] = {
		[1261] = 54, -- Water's Edge -- > Blackwood 
	},
	[1277] = {
		[1261] = 55, -- Pantherfang Chapel -- > Blackwood 
	},
	[1278] = {
		[108] = 0, -- Lyranth's Hidden Lair -- > Greenshade 
	},
	[1279] = {
		[108] = 0, -- Waking Flame Camp -- > Greenshade 
	},
	
	-- add zones for HighIsle
	[1318] =  {
		[1318] = 0, -- High Isle -- > High Isle
	},
	[1328] =  {
		[1318] = 5, -- Garick's Rest -- > High Isle
	},
	[1329] =  {
		[1318] = 2, -- Castle Navire -- > High Isle
	},
	[1330] =  {
		[1318] = 9, -- Brokerock Mine -- > High Isle
	},
	[1331] =  {
		[1318] = 15, -- Death's Valor Keep -- > High Isle
	},
	[1332] =  {
		[1318] = 14, -- The Firepot -- > High Isle
	},
	[1317] =  {
		[1318] = 6, -- All Flags Islet -- > High Isle
	},
	[1334] =  {
		[1318] = 17, -- Whalefall -- > High Isle
	},
	[1335] =  {
		[1318] = 16, -- Shipwreck Shoals -- > High Isle
	},
	[1336] =  {
		[1318] = 18, -- Coral Cliffs -- > High Isle
	},
	[1337] =  {
		[1318] = 11, -- Spire of the Crimson Coin -- > High Isle
	},
	[1338] =  {
		[1318] = 12, -- Ghost Haven Bay -- > High Isle
	},
	[1364] =  {
		[1318] = 76, -- Ancient Anchor Berth -- > High Isle
	},
	[1324] =  {
		[1318] = 3, -- Steadfast Manor -- > High Isle
	},
	[1363] =  {
		[1318] = 77, -- Highhallow Hold -- > High Isle
	},
	[1326] =  {
		[1318] = 2, -- Castle Navire -- > High Isle
	},
	[1333] =  {
		[1318] = 13, -- Breakwater Cave -- > High Isle
	},
	[1344] =  {
		[1318] = 40, -- Dreadsail Reef -- > High Isle
	},
	[1315] =  {
		[1318] = 56, -- Abhain Chapel Crypts -- > High Isle
	},
	[1319] =  {
		[1318] = 1, -- Gonfalon Bay Outlaws Refuge -- > High Isle
	},
	-- unmarked?
	[1313] =  {
		[1318] = 0, -- Systres Sisters Vault -- > High Isle
	},
	[1316] =  {
		[1318] = 0, -- Old Coin Fort -- > High Isle
	},
	[1320] =  {
		[1318] = 0, -- Tarnished Grotto -- > High Isle
	},
	[1321] =  {
		[1318] = 0, -- Navire Dungeons -- > High Isle
	},
	[1322] =  { 
		[1318] = 0, -- Mistmouth Cave -- > High Isle
	},
	[1327] =  {
		[1318] = 0, -- The Undergrove -- > High Isle
	},

	-- add zones for Update:35 High Isle
	[1360] =
	{
		[1318] = 74, -- Earthen Root Enclave --> High Isle
	},
	[1361] =
	{
		[1318] = 75, -- Graven Deep --> High Isle
	},


	-- TODO: Investigate these locations.
	[1366] =
	{
		[92] = 0, -- Glenmoril Ritual Site --> Bangkorai
	},
	[1365] =
	{
		[3] = 0, -- Eimhir's Cavern --> Glenumbra
	},

	-- add zones for api:######
	--[[
	[zoneId] = {
		[parentZoneId] = poiIndex or 0, -- zone Name -- > parent zone name
	},
	]]
}




--[[ Locate
	During witches festival
		Olyve's Brewery in Auridon,Glenumbra,Stonefalls
			add entries to geoDataReferenceTable
			1274 - Garden of Shadows
				copy Olyve's Brewerys to Garden of Shadows

]]