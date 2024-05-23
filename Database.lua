local addonName, AMT = ...

--Mythic Plus rewards. Key Level : Dungeon Rewards : Vault Rewards
BackdropInfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 40,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

function AMT:GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		if dungeon.challengeModeID == id then
			return dungeon.abbr
		end
	end
	return nil -- Return nil if no matching dungeon is found
end

local RewardsTable = {
	{ "2", "441", "454" },
	{ "3", "444", "457" },
	{ "4", "444", "460" },
	{ "5", "447", "460" },
	{ "6", "447", "463" },
	{ "7", "450", "463" },
	{ "8", "450", "467" },
	{ "9", "454", "467" },
	{ "10", "454", "470" },
	{ "11", "457", "470" },
	{ "12", "457", "473" },
	{ "13", "460", "473" },
	{ "14", "460", "473" },
	{ "15", "463", "476" },
	{ "16", "463", "476" },
	{ "17", "467", "476" },
	{ "18", "467", "480" },
	{ "19", "470", "480" },
	{ "20", "470", "483" },
}

AMT.Challenges_Teleports = {
	--Dragonflight
	{ spellID = 393256, mapID = 399 }, --Ruby Life Pools
	{ spellID = 393262, mapID = 400 }, --The Nokhud Offensive
	{ spellID = 393279, mapID = 401 }, --The Azure Vault
	{ spellID = 393273, mapID = 402 }, -- Algeth'ar Academy
	{ spellID = 393222, mapID = 403 }, --Uldaman:Legacy of Tyr
	{ spellID = 393276, mapID = 404 }, --Neltharus
	{ spellID = 393283, mapID = 406 }, --Halls of Infusion
	{ spellID = 393267, mapID = 405 }, -- Brakenhide Hollow
	{ spellID = 424197, mapID = 463 }, --Dawn of the infinite: Galakrond's Fall
	{ spellID = 424197, mapID = 464 }, --Dawn of the infinite: Murozond's Rise

	--Shadowlands
	{ spellID = 354464, mapID = 375 }, --Mist of Tirna Scithe
	{ spellID = 354462, mapID = 376 }, --Necrotic Wake
	{ spellID = 354468, mapID = 377 }, --De Other Side
	{ spellID = 354465, mapID = 378 }, --Halls of Atonement
	{ spellID = 354463, mapID = 379 }, --Plaguefall
	{ spellID = 354469, mapID = 380 }, --Sanguine Depths
	{ spellID = 354466, mapID = 381 }, --Spires of Ascension
	{ spellID = 354467, mapID = 382 }, --Theater of Pain
	{ spellID = 367416, mapID = 391 }, --Tazavesh, the Veiled Market: Streets of Wonder
	{ spellID = 367416, mapID = 392 }, --Tazavesh, the Veiled Market: So'leah's Gambit

	--Battle for Azeroth
	{ spellID = 424187, mapID = 244 }, --Atal'Dazar
	{ spellID = 410071, mapID = 245 }, --Freehold
	{ spellID = 424167, mapID = 248 }, --Waycrest Manor
	{ spellID = 410074, mapID = 251 }, --The Underrot
	{ spellID = 373274, mapID = 369 }, --Operation: Mechagon: Junkyard
	{ spellID = 373274, mapID = 370 }, --Operation: Mechagon: Workshop

	--Legion
	{ spellID = 424163, mapID = 198 }, --Darkheart Thicket
	{ spellID = 424153, mapID = 199 }, --Black Rook Hold
	{ spellID = 393764, mapID = 200 }, --Halls of Valor
	{ spellID = 410078, mapID = 206 }, --Neltharion's Lair
	{ spellID = 393766, mapID = 210 }, --Court of Stars
	{ spellID = 373262, mapID = 277 }, --Return to Karazhan: Lower
	{ spellID = 373262, mapID = 234 }, --Return to Karazhan: Upper

	--Warlords of Draenor
	{ spellID = 159898, mapID = 161 }, --Skyreach
	{ spellID = 159895, mapID = 163 }, --Bloodmaul Slag Mines
	{ spellID = 159897, mapID = 164 }, --Auchindoun
	{ spellID = 159899, mapID = 165 }, --Shadowmoon Burial Grounds
	{ spellID = 159900, mapID = 166 }, --Grimrail Depot
	{ spellID = 159902, mapID = 167 }, --Upper Blackrock Spire
	{ spellID = 159901, mapID = 168 }, --The Everbloom
	{ spellID = 159896, mapID = 169 }, --Iron Docks

	--Mist of Pandaria
	{ spellID = 131204, mapID = 2 }, --Temple of the Jade Serpent

	--Cataclysm
	{ spellID = 410080, mapID = 438 }, --The Vortex Pinnacle
	{ spellID = 424142, mapID = 456 }, --Throne of the Tides
}

AMT.KeyScore_Colors = {
	{ "1", "ffffff" },
	{ "2", "eeffe7" },
	{ "3", "d8ffc9" },
	{ "4", "c0ffaa" },
	{ "5", "a5ff8b" },
	{ "6", "86ff69" },
	{ "7", "5cff41" },
	{ "8", "27fd16" },
	{ "9", "40f03e" },
	{ "10", "4ee455" },
	{ "11", "57d868" },
	{ "12", "5ccb78" },
	{ "13", "5fbf87" },
	{ "14", "5fb395" },
	{ "15", "5da8a2" },
	{ "16", "589caf" },
	{ "17", "5090bb" },
	{ "18", "4384c7" },
	{ "19", "2e79d3" },
	{ "20", "286dde" },
	{ "21", "695ee4" },
	{ "22", "8f49ea" },
	{ "23", "ac38e4" },
	{ "24", "bf40cd" },
	{ "25", "ce49b5" },
	{ "26", "da529d" },
	{ "27", "e55b86" },
	{ "28", "ed646e" },
	{ "29", "f46d54" },
	{ "30", "fa7737" },
	{ "31", "ff8000" },
}

AMT.SeasonalDungeons = {
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 206,
		mapId = 1458,
		spellID = 410078,
		time = 0,
		abbr = "NL",
		name = "Neltharion's Lair",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 245,
		mapId = 1754,
		spellID = 410071,
		time = 0,
		abbr = "FH",
		name = "Freehold",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 251,
		mapId = 1841,
		spellID = 410074,
		time = 0,
		abbr = "UNDR",
		name = "The Underrot",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 403,
		mapId = 2451,
		spellID = 393222,
		time = 0,
		abbr = "ULD",
		name = "Uldaman: Legacy of Tyr",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 404,
		mapId = 2519,
		spellID = 393276,
		time = 0,
		abbr = "NELT",
		name = "Neltharus",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 405,
		mapId = 2520,
		spellID = 393267,
		time = 0,
		abbr = "BH",
		name = "Brackenhide Hollow",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 406,
		mapId = 2527,
		spellID = 393283,
		time = 0,
		abbr = "HOI",
		name = "Halls of Infusion",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 438,
		mapId = 657,
		spellID = 410080,
		time = 0,
		abbr = "VP",
		name = "The Vortex Pinnacle",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 168,
		mapId = 1279,
		spellID = 159901,
		time = 0,
		abbr = "EB",
		name = "The Everbloom",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 198,
		mapId = 1466,
		spellID = 424163,
		time = 0,
		abbr = "DHT",
		name = "Darkheart Thicket",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 199,
		mapId = 1501,
		spellID = 424153,
		time = 0,
		abbr = "BRH",
		name = "Black Rook Hold",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 244,
		mapId = 1763,
		spellID = 424187,
		time = 0,
		abbr = "AD",
		name = "Atal'Dazar",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 248,
		mapId = 1862,
		spellID = 424167,
		time = 0,
		abbr = "WM",
		name = "Waycrest Manor",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 456,
		mapId = 643,
		spellID = 424142,
		time = 0,
		abbr = "TOTT",
		name = "Throne of the Tides",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 463,
		mapId = 2579,
		spellID = 424197,
		time = 0,
		abbr = "FALL",
		name = "Dawn of the Infinite: Galakrond's Fall",
		short = "DOTI: Galakrond's Fall",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 464,
		mapId = 2579,
		spellID = 424197,
		time = 0,
		abbr = "RISE",
		name = "Dawn of the Infinite: Murozond's Rise",
		short = "DOTI: Murozond's Rise",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 399,
		mapId = 2521,
		spellID = 393256,
		time = 0,
		abbr = "RLP",
		name = "Ruby Life Pools",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 400,
		mapId = 2516,
		spellID = 393262,
		time = 0,
		abbr = "NO",
		name = "The Nokhud Offensive",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 401,
		mapId = 2515,
		spellID = 393279,
		time = 0,
		abbr = "AV",
		name = "The Azure Vault",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 402,
		mapId = 2526,
		spellID = 393273,
		time = 0,
		abbr = "AA",
		name = "Algeth'ar Academy",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 403,
		mapId = 2451,
		spellID = 393222,
		time = 0,
		abbr = "ULD",
		name = "Uldaman: Legacy of Tyr",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 404,
		mapId = 2519,
		spellID = 393276,
		time = 0,
		abbr = "NELT",
		name = "Neltharus",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 405,
		mapId = 2520,
		spellID = 393267,
		time = 0,
		abbr = "BH",
		name = "Brackenhide Hollow",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 406,
		mapId = 2527,
		spellID = 393283,
		time = 0,
		abbr = "HOI",
		name = "Halls of Infusion",
	},
}

AMT.RaidDifficulty_Levels = {
	{ id = 16, color = LEGENDARY_ORANGE_COLOR, order = 1, label = "M - ", name = "Mythic", abbr = "M" },
	{ id = 15, color = EPIC_PURPLE_COLOR, order = 2, label = "H - ", name = "Heroic", abbr = "H" },
	{ id = 14, color = RARE_BLUE_COLOR, order = 3, label = "N - ", name = "Normal", abbr = "N" },
	{ id = 17, color = UNCOMMON_GREEN_COLOR, order = 4, label = "LFR - ", name = "Looking For Raid", abbr = "LFR" },
}

AMT.SeasonalRaids = {
	{
		seasonID = 9,
		seasonDisplayID = 1,
		journalInstanceID = 1200,
		instanceID = 2522,
		order = 1,
		numEncounters = 8,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "VOTI",
		name = "Vault of the Incarnates",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		journalInstanceID = 1208,
		instanceID = 2569,
		order = 2,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		journalInstanceID = 1207,
		instanceID = 2549,
		order = 3,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1200,
		instanceID = 2522,
		order = 1,
		numEncounters = 8,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "VOTI",
		name = "Vault of the Incarnates",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1208,
		instanceID = 2569,
		order = 2,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1207,
		instanceID = 2549,
		order = 3,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
	},
}

AMT.Weekly_KillCount = {
	{ name = "M", kills = 0 },
	{ name = "H", kills = 0 },
	{ name = "N", kills = 0 },
	{ name = "LFR", kills = 0 },
}

AMT.DungeonAbbr = {
	-- Cata
	{ mapID = 438, Abbr = "VP" },

	-- MOP
	{ mapID = 2, Abbr = "TJS" },

	-- WoD
	{ mapID = 165, Abbr = "SBG" },
	{ mapID = 166, Abbr = "GD" },
	{ mapID = 169, Abbr = "ID" },

	-- Legion
	{ mapID = 200, Abbr = "HoV" },
	{ mapID = 206, Abbr = "NL" },
	{ mapID = 210, Abbr = "CoS" },
	{ mapID = 227, Abbr = "LOWR" },
	{ mapID = 234, Abbr = "UPPR" },

	-- BFA
	{ mapID = 245, Abbr = "FH" },
	{ mapID = 251, Abbr = "UR" },
	{ mapID = 369, Abbr = "Yard" },
	{ mapID = 370, Abbr = "Work" },

	-- SL
	{ mapID = 375, Abbr = "MotS" },
	{ mapID = 376, Abbr = "NW" },
	{ mapID = 377, Abbr = "DoS" },
	{ mapID = 378, Abbr = "HoA" },
	{ mapID = 379, Abbr = "PF" },
	{ mapID = 380, Abbr = "SD" },
	{ mapID = 381, Abbr = "SoA" },
	{ mapID = 382, Abbr = "ToP" },
	{ mapID = 391, Abbr = "Strt" },
	{ mapID = 392, Abbr = "Gmbt" },

	-- DF
	{ mapID = 399, Abbr = "RLP" },
	{ mapID = 400, Abbr = "NO" },
	{ mapID = 401, Abbr = "AV" },
	{ mapID = 402, Abbr = "AA" },
	{ mapID = 405, Abbr = "BH" },
	{ mapID = 404, Abbr = "NELT" },
	{ mapID = 403, Abbr = "ULD" },
	{ mapID = 406, Abbr = "HOI" },
}

AMT.GetCurrentAffixesTable = {}
AMT.CurrentWeek_AffixTable = {}
AMT.NextWeek_AffixTable = {}

AMT.AffixRotation = {
	{ rotation = { 9, 124, 6 }, rank = "(S)" },
	{ rotation = { 10, 134, 7 }, rank = "(S)" },
	{ rotation = { 9, 136, 123 }, rank = "(S)" },
	{ rotation = { 10, 135, 6 }, rank = "(S)" },
	{ rotation = { 9, 3, 8 }, rank = "(S)" },
	{ rotation = { 10, 124, 11 }, rank = "(S)" },
	{ rotation = { 9, 135, 7 }, rank = "(S)" },
	{ rotation = { 10, 136, 8 }, rank = "(S)" },
	{ rotation = { 9, 134, 11 }, rank = "(S)" },
	{ rotation = { 10, 3, 123 }, rank = "(S)" },
}

Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
Player_Mplus_ScoreColor = nil
--Set up a table that'll store the raw completed run keys from Blizz API
AMT.RunHistory = {}
--Set up a table that'll store all of our weekly keys
AMT.KeysDone = {}
--Set up the table that will hold the Season's dungeon info
AMT.Current_SeasonalDung_Info = {}
--Set up the table that'll store highest keys done per dungeon
AMT.BestKeys_per_Dungeon = {}
