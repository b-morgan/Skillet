local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
--[[
Skillet: A tradeskill window replacement.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

--[[ == Global Tables == ]]--

--
-- A table of SkillLineIDs returned by C_TradeSkillUI.GetTradeSkillLine() mapped to the Skill SpellID
--
Skillet.SkillLineIDList = {
	[171] = 2259,		-- alchemy
	[164] = 2018,		-- blacksmithing
	[333] = 7411,		-- enchanting
	[202] = 4036,		-- engineering
	[773] = 45357,		-- inscription
	[755] = 25229,		-- jewelcrafting
	[165] = 2108,		-- leatherworking
	[186] = 2575,		-- mining
	[197] = 3908,		-- tailoring
	[185] = 2550,		-- cooking
--	[129] = 3273,		-- first aid (removed in Battle for Azeroth)
-- Battle for Azeroth (not sure these are needed anymore)
	[2482] = 2259,		-- alchemy
	[2485] = 2259,		-- alchemy
	[2474] = 2018,		-- blacksmithing
	[2477] = 2018,		-- blacksmithing
	[2491] = 7411,		-- enchanting
	[2494] = 7411,		-- enchanting
	[2503] = 4036,		-- engineering
	[2506] = 4036,		-- engineering
	[2511] = 45357,		-- inscription
	[2514] = 45357,		-- inscription
	[2521] = 25229,		-- jewelcrafting
	[2524] = 25229,		-- jewelcrafting
	[2529] = 2108,		-- leatherworking
	[2532] = 2108,		-- leatherworking
	[2569] = 2575,		-- mining
	[2572] = 2575,		-- mining
	[2537] = 3908,		-- tailoring
	[2540] = 3908,		-- tailoring
	[2545] = 2550,		-- cooking
	[2548] = 2550,		-- cooking
}

--
-- Table of tradeskills that should use the Blizzard frame
--
Skillet.BlizzardSkillList = {
	[182]    = true,		-- herbalism skills
	[393]    = true,		-- skinning skills
	[356]    = true,		-- fishing skills
	[960]    = true,		-- runeforging
}

--
-- Table of follower (C_TradeSkillUI.IsNPCCrafting) tradeskills that should use the Blizzard frame
--
Skillet.FollowerSkillList = {
}

--
-- In case the previous table is too broad
-- Table of follower (C_TradeSkillUI.IsNPCCrafting) NPC IDs (from GUID) that should use the Blizzard frame
--
Skillet.FollowerNPC = {
	[79826] = true,  -- Pozzlow (Engineering, Horde)
	[77365] = true,  -- Zaren Hoffle (Engineering, Alliance)
}

--
-- Table of additional abilities used to create more buttons
-- after the trade skill buttons on the Skillet main frame.
--
-- Each entry is {spellID, "Name", isToy, isPet, isKnown}
--   isToy is true if the spellID is a toyID instead
--   isPet is true if the name is a pet
--   isKnown is true if the spellID must be known by the player.
-- use for testing:
--				{883,"Call Pet",false,true},	-- Hunter skill
--
Skillet.TradeSkillAdditionalAbilities = {
	[7411]	=	{13262,"Disenchant"},		-- enchanting = disenchant
	[2550]	=	{
				{818,"Basic_Campfire"},			-- cooking = basic campfire
				{117573,"Wayfarer's Bonfire",true,false}, -- cooking bonfire
				{138824,"Pierre",false,true},	-- cooking pet
				{95787,"Lil' Ragnaros",false,true}, -- cooking pet
				{134020,"Chef's_Hat",true,false}, -- cooking = Chef's Hat (toy)
				},
--	[45357] =	{51005,"Milling"},			-- inscription = milling
--	[25229] =	{31252,"Prospecting"},		-- jewelcrafting = prospecting
	[2018]	=	{
				{126462,"Thermal_Anvil"},	-- blacksmithing = thermal anvil (item:87216)
				{255650,"Forge_of_Light",false,false,true}, -- Lightforged Draenei racial skill
				},
	[4036]	=	{126462,"Thermal_Anvil"},	-- engineering = thermal anvil (item:87216)
	[2575]	=	{126462,"Thermal_Anvil"},	-- smelting = thermal anvil (item:87216)
}

--
-- Table of magic for Enchanting, Prospecting, Milling
--
Skillet.TradeSkillAutoTarget = {
	[7411] =  {	  -- Enchanting
		[38682] = 1, -- Enchanting Vellum
	},
	[31252] = {	  -- Prospecting
		[2770]	= 5, --Copper Ore
		[2771]	= 5, --Tin Ore
		[2772]	= 5, --Iron Ore
		[3858]	= 5, --Mithril Ore
		[10620] = 5, --Thorium Ore
		[23424] = 5, --Fel Iron Ore
		[23425] = 5, --Adamantite Ore
		[36909] = 5, --Cobalt Ore
		[36910] = 5, --Titanium Ore
		[36912] = 5, --Saronite Ore
		[53038] = 5, -- Obsidium Ore
		[52183] = 5, -- Pyrite Ore
		[52185] = 5, -- Elementium Ore
		[72092] = 5, -- Ghost Iron Ore
		[72103] = 5, -- White Trillium Ore
		[72094] = 5, -- Black Trillium Ore
		[152512] = 5, -- Monelite Ore
		[152513] = 5, -- Platinum Ore
		[152579] = 5, -- Storm Silver-ore
		[168185] = 5, -- Osmenite Ore
		[171829] = 5, -- Solenium Ore
		[171830] = 5, -- Oxxein Ore
		[171831] = 5, -- Phaedrum Ore
		[171832] = 5, -- Sinvyr Ore
	},
	[51005] = {	  -- Milling
		[765]  = 5, -- Silverleaf
		[2449] = 5, -- Earthroot
		[2447] = 5, -- Peacebloom
		[2450] = 5, -- Briarthorn
		[2453] = 5, -- Bruiseweed
		[785]  = 5, -- Mageroyal
		[3820] = 5, -- Stranglekelp
		[2452] = 5, -- Swiftthistle
		[3355] = 5, -- Wild Steelbloom
		[3369] = 5, -- Grave Moss
		[3357] = 5, -- Liferoot
		[3356] = 5, -- Kingsblood
		[3818] = 5, -- Fadeleaf
		[3821] = 5, -- Goldthorn
		[3358] = 5, -- Khadgar\'s Whisker
		[3819] = 5, -- Dragon\'s Teeth
		[8831] = 5, -- Purple Lotus
		[8836] = 5, -- Arthas\' Tears
		[8838] = 5, -- Sungrass
		[4625] = 5, -- Firebloom
		[8839] = 5, -- Blindweed
		[8845] = 5, -- Ghost Mushroom
		[8846] = 5, -- Gromsblood
		[13463] = 5, -- Dreamfoil
		[13464] = 5, -- Golden Sansam
		[13465] = 5, -- Mountain Silversage
		[13466] = 5, -- Sorrowmoss
		[13467] = 5, -- Icecap
		[39969] = 5, -- Fire Seed (no longer in game)
-- Added in the Burning Crusade
		[22789] = 5, -- Terocone
		[22786] = 5, -- Dreaming Glory
		[22787] = 5, -- Ragveil
		[22785] = 5, -- Felweed
		[22790] = 5, -- Ancient Lichen
		[22792] = 5, -- Nightmare Vine
		[22793] = 5, -- Mana Thistle
		[22791] = 5, -- Netherbloom
--Added in Wrath of the Lich King
		[36901] = 5, -- Goldclover
		[36907] = 5, -- Talandra\'s Rose
		[37921] = 5, -- Deadnettle
		[36904] = 5, -- Tiger Lily
		[36905] = 5, -- Lichbloom
		[36906] = 5, -- Icethorn
		[36903] = 5, -- Adder\'s Tongue
		[39970] = 5, -- Fire Leaf
-- Added in Cataclysm
		[52983] = 5, -- Cinderbloom
		[52984] = 5, -- Stormvine
		[52985] = 5, -- Azshara\'s Veil
		[52986] = 5, -- Heartblossom
		[52987] = 5, -- Twilight Jasmine
		[52988] = 5, -- Whiptail
		[52989] = 5, -- Deathspore Pod
-- Added in Mists of Pandaria
		[79011] = 5, -- Fool's Cap
		[79010] = 5, -- Snow Lily
		[72235] = 5, -- Silkweed
		[72234] = 5, -- Green Tea Leaf
		[72237] = 5, -- Rain Poppy
-- Added in Warlords of Draenor
		[109124] = 5, -- Frostweed
		[109125] = 5, -- Fireweed
		[109126] = 5, -- Gorgrond Flytrap
		[109127] = 5, -- Starflower
		[109128] = 5, -- Nagrand Arrowbloom
		[109129] = 5, -- Talador Orchid
		[109130] = 5, -- Chameleon Lotus
-- Added in Legion
		[124101] = 5, -- Aethril
		[124102] = 5, -- Dreamleaf
		[124103] = 5, -- Foxflower
		[124104] = 5, -- Fjarnskaggl
		[124105] = 5, -- Starlight Rose
		[124106] = 5, -- Felwort
		[128304] = 5, -- Yseralline Seed
-- Added in Battle for Azeroth
		[152505] = 5, -- Riverbud
		[152511] = 5, -- Sea Stalk
		[152506] = 5, -- Star Moss
		[152507] = 5, -- Akunda's Bite
		[152508] = 5, -- Winter's Kiss
		[152509] = 5, -- Siren's Pollen
		[152510] = 5, -- Anchor Weed
-- Added Rise of Azshara
		[168487] = 5, -- Zinanthid
-- Added in Shadowlands
		[168586] = 5, -- Rising Glory
		[168589] = 5, -- Marrowroot
		[170554] = 5, -- Vigils Torch
		[168583] = 5, -- Widowbloom
		[169701] = 5, -- Death Blossom
		[171315] = 5, -- Nightshade
	}
}

--
-- Table used by Enchanting to target Enchanting Vellum
--
Skillet.scrollData = {
	-- Scraped from WoWhead using the following javascript:
	-- for (i=0; i<listviewitems.length; i++) console.log("["+listviewitems[i].sourcemore[0].ti+"] = "+listviewitems[i].id+",
	-- "+listviewitems[i].name.substr(1));
	[158914] = 110638, -- Enchant Ring - Gift of Critical Strike
	[158915] = 110639, -- Enchant Ring - Gift of Haste
	[158916] = 110640, -- Enchant Ring - Gift of Mastery
	[158917] = 110641, -- Enchant Ring - Gift of Multistrike
	[158918] = 110642, -- Enchant Ring - Gift of Versatility
	[158899] = 110645, -- Enchant Neck - Gift of Critical Strike
	[158900] = 110646, -- Enchant Neck - Gift of Haste
	[158901] = 110647, -- Enchant Neck - Gift of Mastery
	[158902] = 110648, -- Enchant Neck - Gift of Multistrike
	[158903] = 110649, -- Enchant Neck - Gift of Versatility
	[158884] = 110652, -- Enchant Cloak - Gift of Critical Strike
	[158885] = 110653, -- Enchant Cloak - Gift of Haste
	[158886] = 110654, -- Enchant Cloak - Gift of Mastery
	[158887] = 110655, -- Enchant Cloak - Gift of Multistrike
	[158889] = 110656, -- Enchant Cloak - Gift of Versatility
	[159235] = 110682, -- Enchant Weapon - Mark of the Thunderlord
	[159236] = 112093, -- Enchant Weapon - Mark of the Shattered Hand
	[159673] = 112115, -- Enchant Weapon - Mark of Shadowmoon
	[159674] = 112160, -- Enchant Weapon - Mark of Blackrock
	[159671] = 112164, -- Enchant Weapon - Mark of Warsong
	[159672] = 112165, -- Enchant Weapon - Mark of the Frostwolf
	[173323] = 118015, -- Enchant Weapon - Mark of Bleeding Hollow
	[158907] = 110617, -- Enchant Ring - Breath of Critical Strike
	[158908] = 110618, -- Enchant Ring - Breath of Haste
	[158909] = 110619, -- Enchant Ring - Breath of Mastery
	[158910] = 110620, -- Enchant Ring - Breath of Multistrike
	[158911] = 110621, -- Enchant Ring - Breath of Versatility
	[158892] = 110624, -- Enchant Neck - Breath of Critical Strike
	[158893] = 110625, -- Enchant Neck - Breath of Haste
	[158894] = 110626, -- Enchant Neck - Breath of Mastery
	[158895] = 110627, -- Enchant Neck - Breath of Multistrike
	[158896] = 110628, -- Enchant Neck - Breath of Versatility
	[158877] = 110631, -- Enchant Cloak - Breath of Critical Strike
	[158878] = 110632, -- Enchant Cloak - Breath of Haste
	[158879] = 110633, -- Enchant Cloak - Breath of Mastery
	[158880] = 110634, -- Enchant Cloak - Breath of Multistrike
	[158881] = 110635, -- Enchant Cloak - Breath of Versatility
	[104425] = 74723, -- Enchant Weapon - Windsong
	[104427] = 74724, -- Enchant Weapon - Jade Spirit
	[104430] = 74725, -- Enchant Weapon - Elemental Force
	[104434] = 74726, -- Enchant Weapon - Dancing Steel
	[104440] = 74727, -- Enchant Weapon - Colossus
	[104442] = 74728, -- Enchant Weapon - River's Song
	[104338] = 74700, -- Enchant Bracer - Mastery
	[104385] = 74701, -- Enchant Bracer - Major Dodge
	[104389] = 74703, -- Enchant Bracer - Super Intellect
	[104390] = 74704, -- Enchant Bracer - Exceptional Strength
	[104391] = 74705, -- Enchant Bracer - Greater Agility
	[104392] = 74706, -- Enchant Chest - Super Resilience
	[104393] = 74707, -- Enchant Chest - Mighty Spirit
	[104395] = 74708, -- Enchant Chest - Glorious Stats
	[104397] = 74709, -- Enchant Chest - Superior Stamina
	[104398] = 74710, -- Enchant Cloak - Accuracy
	[104401] = 74711, -- Enchant Cloak - Greater Protection
	[104403] = 74712, -- Enchant Cloak - Superior Intellect
	[104404] = 74713, -- Enchant Cloak - Superior Critical Strike
	[104407] = 74715, -- Enchant Boots - Greater Haste
	[104408] = 74716, -- Enchant Boots - Greater Precision
	[104409] = 74717, -- Enchant Boots - Blurred Speed
	[104414] = 74718, -- Enchant Boots - Pandaren's Step
	[104416] = 74719, -- Enchant Gloves - Greater Haste
	[104417] = 74720, -- Enchant Gloves - Superior Haste
	[104419] = 74721, -- Enchant Gloves - Super Strength
	[104420] = 74722, -- Enchant Gloves - Superior Mastery
	[104445] = 74729, -- Enchant Off-Hand - Major Intellect
	[130758] = 89737, -- Enchant Shield - Greater Parry
	[74195] = 52747, -- Enchant Weapon - Mending
	[96264] = 68784, -- Enchant Bracer - Agility
	[96261] = 68785, -- Enchant Bracer - Major Strength
	[96262] = 68786, -- Enchant Bracer - Mighty Intellect
	[74132] = 52687, -- Enchant Gloves - Mastery
	[74189] = 52743, -- Enchant Boots - Earthen Vitality
	[74191] = 52744, -- Enchant Chest - Mighty Stats
	[74192] = 52745, -- Enchant Cloak - Lesser Power
	[74193] = 52746, -- Enchant Bracer - Speed
	[74197] = 52748, -- Enchant Weapon - Avalanche
	[74198] = 52749, -- Enchant Gloves - Haste
	[74199] = 52750, -- Enchant Boots - Haste
	[74200] = 52751, -- Enchant Chest - Stamina
	[74201] = 52752, -- Enchant Bracer - Critical Strike
	[74202] = 52753, -- Enchant Cloak - Intellect
	[74207] = 52754, -- Enchant Shield - Protection
	[74211] = 52755, -- Enchant Weapon - Elemental Slayer
	[74212] = 52756, -- Enchant Gloves - Exceptional Strength
	[74213] = 52757, -- Enchant Boots - Major Agility
	[74214] = 52758, -- Enchant Chest - Mighty Resilience
	[74220] = 52759, -- Enchant Gloves - Greater Haste
	[74223] = 52760, -- Enchant Weapon - Hurricane
	[74225] = 52761, -- Enchant Weapon - Heartsong
	[74226] = 52762, -- Enchant Shield - Mastery
	[74229] = 52763, -- Enchant Bracer - Superior Dodge
	[74230] = 52764, -- Enchant Cloak - Critical Strike
	[74231] = 52765, -- Enchant Chest - Exceptional Spirit
	[74232] = 52766, -- Enchant Bracer - Precision
	[74234] = 52767, -- Enchant Cloak - Protection
	[74235] = 52768, -- Enchant Off-Hand - Superior Intellect
	[74236] = 52769, -- Enchant Boots - Precision
	[74237] = 52770, -- Enchant Bracer - Exceptional Spirit
	[74238] = 52771, -- Enchant Boots - Mastery
	[74239] = 52772, -- Enchant Bracer - Greater Haste
	[74240] = 52773, -- Enchant Cloak - Greater Intellect
	[74242] = 52774, -- Enchant Weapon - Power Torrent
	[74244] = 52775, -- Enchant Weapon - Windwalk
	[74246] = 52776, -- Enchant Weapon - Landslide
	[74247] = 52777, -- Enchant Cloak - Greater Critical Strike
	[74248] = 52778, -- Enchant Bracer - Greater Critical Strike
	[74250] = 52779, -- Enchant Chest - Peerless Stats
	[74251] = 52780, -- Enchant Chest - Greater Stamina
	[74252] = 52781, -- Enchant Boots - Assassin's Step
	[74253] = 52782, -- Enchant Boots - Lavawalker
	[74254] = 52783, -- Enchant Gloves - Mighty Strength
	[74255] = 52784, -- Enchant Gloves - Greater Mastery
	[74256] = 52785, -- Enchant Bracer - Greater Speed
	[95471] = 68134, -- Enchant 2H Weapon - Mighty Agility
	[42974] = 38948, -- Enchant Weapon - Executioner
	[44510] = 38963, -- Enchant Weapon - Exceptional Spirit
	[44524] = 38965, -- Enchant Weapon - Icebreaker
	[44576] = 38972, -- Enchant Weapon - Lifeward
	[44595] = 38981, -- Enchant 2H Weapon - Scourgebane
	[44621] = 38988, -- Enchant Weapon - Giant Slayer
	[44629] = 38991, -- Enchant Weapon - Exceptional Spellpower
	[44630] = 38992, -- Enchant 2H Weapon - Greater Savagery
	[44633] = 38995, -- Enchant Weapon - Exceptional Agility
	[46578] = 38998, -- Enchant Weapon - Deathfrost
	[59625] = 43987, -- Enchant Weapon - Black Magic
	[60621] = 44453, -- Enchant Weapon - Greater Potency
	[60691] = 44463, -- Enchant 2H Weapon - Massacre
	[60707] = 44466, -- Enchant Weapon - Superior Potency
	[60714] = 44467, -- Enchant Weapon - Mighty Spellpower
	[59621] = 44493, -- Enchant Weapon - Berserking
	[59619] = 44497, -- Enchant Weapon - Accuracy
	[62948] = 45056, -- Enchant Staff - Greater Spellpower
	[62959] = 45060, -- Enchant Staff - Spellpower
	[27958] = 38912, -- Enchant Chest - Exceptional Mana
	[44484] = 38951, -- Enchant Gloves - Haste
	[44488] = 38953, -- Enchant Gloves - Precision
	[44489] = 38954, -- Enchant Shield - Dodge
	[44492] = 38955, -- Enchant Chest - Mighty Health
	[44500] = 38959, -- Enchant Cloak - Superior Agility
	[44508] = 38961, -- Enchant Boots - Greater Spirit
	[44509] = 38962, -- Enchant Chest - Greater Mana Restoration
	[44513] = 38964, -- Enchant Gloves - Greater Assault
	[44528] = 38966, -- Enchant Boots - Greater Fortitude
	[44529] = 38967, -- Enchant Gloves - Major Agility
	[44555] = 38968, -- Enchant Bracer - Exceptional Intellect
	[60616] = 38971, -- Enchant Bracer - Assault
	[44582] = 38973, -- Enchant Cloak - Minor Power
	[44584] = 38974, -- Enchant Boots - Greater Vitality
	[44588] = 38975, -- Enchant Chest - Exceptional Resilience
	[44589] = 38976, -- Enchant Boots - Superior Agility
	[44591] = 38978, -- Enchant Cloak - Superior Dodge
	[44592] = 38979, -- Enchant Gloves - Exceptional Spellpower
	[44593] = 38980, -- Enchant Bracer - Major Spirit
	[44598] = 38984, -- Enchant Bracer - Haste
	[60623] = 38986, -- Enchant Boots - Icewalker
	[44616] = 38987, -- Enchant Bracer - Greater Stats
	[44623] = 38989, -- Enchant Chest - Super Stats
	[44625] = 38990, -- Enchant Gloves - Armsman
	[44631] = 38993, -- Enchant Cloak - Shadow Armor
	[44635] = 38997, -- Enchant Bracer - Greater Spellpower
	[47672] = 39001, -- Enchant Cloak - Mighty Stamina
	[47766] = 39002, -- Enchant Chest - Greater Dodge
	[47898] = 39003, -- Enchant Cloak - Greater Speed
	[47899] = 39004, -- Enchant Cloak - Wisdom
	[47900] = 39005, -- Enchant Chest - Super Health
	[47901] = 39006, -- Enchant Boots - Tuskarr's Vitality
	[60606] = 44449, -- Enchant Boots - Assault
	[60653] = 44455, -- Shield Enchant - Greater Intellect
	[60609] = 44456, -- Enchant Cloak - Speed
	[60663] = 44457, -- Enchant Cloak - Major Agility
	[60668] = 44458, -- Enchant Gloves - Crusher
	[60692] = 44465, -- Enchant Chest - Powerful Stats
	[60763] = 44469, -- Enchant Boots - Greater Assault
	[60767] = 44470, -- Enchant Bracer - Superior Spellpower
	[44575] = 44815, -- Enchant Bracer - Greater Assault
	[62256] = 44947, -- Enchant Bracer - Major Stamina
	[27967] = 38917, -- Enchant Weapon - Major Striking
	[27968] = 38918, -- Enchant Weapon - Major Intellect
	[27971] = 38919, -- Enchant 2H Weapon - Savagery
	[27972] = 38920, -- Enchant Weapon - Potency
	[27975] = 38921, -- Enchant Weapon - Major Spellpower
	[27977] = 38922, -- Enchant 2H Weapon - Major Agility
	[27981] = 38923, -- Enchant Weapon - Sunfire
	[27982] = 38924, -- Enchant Weapon - Soulfrost
	[27984] = 38925, -- Enchant Weapon - Mongoose
	[28003] = 38926, -- Enchant Weapon - Spellsurge
	[28004] = 38927, -- Enchant Weapon - Battlemaster
	[34010] = 38946, -- Enchant Weapon - Major Healing
	[42620] = 38947, -- Enchant Weapon - Greater Agility
	[27951] = 37603, -- Enchant Boots - Dexterity
	[25086] = 38895, -- Enchant Cloak - Dodge
	[27899] = 38897, -- Enchant Bracer - Brawn
	[27905] = 38898, -- Enchant Bracer - Stats
	[27906] = 38899, -- Enchant Bracer - Greater Dodge
	[27911] = 38900, -- Enchant Bracer - Superior Healing
	[27913] = 38901, -- Enchant Bracer - Restore Mana Prime
	[27914] = 38902, -- Enchant Bracer - Fortitude
	[27917] = 38903, -- Enchant Bracer - Spellpower
	[27944] = 38904, -- Enchant Shield - Lesser Dodge
	[27945] = 38905, -- Enchant Shield - Intellect
	[27946] = 38906, -- Enchant Shield - Parry
	[27948] = 38908, -- Enchant Boots - Vitality
	[27950] = 38909, -- Enchant Boots - Fortitude
	[27954] = 38910, -- Enchant Boots - Surefooted
	[27957] = 38911, -- Enchant Chest - Exceptional Health
	[27960] = 38913, -- Enchant Chest - Exceptional Stats
	[27961] = 38914, -- Enchant Cloak - Major Armor
	[33990] = 38928, -- Enchant Chest - Major Spirit
	[33991] = 38929, -- Enchant Chest - Restore Mana Prime
	[33992] = 38930, -- Enchant Chest - Major Resilience
	[33993] = 38931, -- Enchant Gloves - Blasting
	[33994] = 38932, -- Enchant Gloves - Precise Strikes
	[33995] = 38933, -- Enchant Gloves - Major Strength
	[33996] = 38934, -- Enchant Gloves - Assault
	[33997] = 38935, -- Enchant Gloves - Major Spellpower
	[33999] = 38936, -- Enchant Gloves - Major Healing
	[34001] = 38937, -- Enchant Bracer - Major Intellect
	[34002] = 38938, -- Enchant Bracer - Lesser Assault
	[34003] = 38939, -- Enchant Cloak - PvP Power
	[34004] = 38940, -- Enchant Cloak - Greater Agility
	[34007] = 38943, -- Enchant Boots - Cat's Swiftness
	[34008] = 38944, -- Enchant Boots - Boar's Speed
	[34009] = 38945, -- Enchant Shield - Major Stamina
	[44383] = 38949, -- Enchant Shield - Resilience
	[46594] = 38999, -- Enchant Chest - Dodge
	[47051] = 39000, -- Enchant Cloak - Greater Dodge
	[7745] = 38772, -- Enchant 2H Weapon - Minor Impact
	[7786] = 38779, -- Enchant Weapon - Minor Beastslayer
	[7788] = 38780, -- Enchant Weapon - Minor Striking
	[7793] = 38781, -- Enchant 2H Weapon - Lesser Intellect
	[13380] = 38788, -- Enchant 2H Weapon - Lesser Spirit
	[13503] = 38794, -- Enchant Weapon - Lesser Striking
	[13529] = 38796, -- Enchant 2H Weapon - Lesser Impact
	[13653] = 38813, -- Enchant Weapon - Lesser Beastslayer
	[13655] = 38814, -- Enchant Weapon - Lesser Elemental Slayer
	[13693] = 38821, -- Enchant Weapon - Striking
	[13695] = 38822, -- Enchant 2H Weapon - Impact
	[13898] = 38838, -- Enchant Weapon - Fiery Weapon
	[13915] = 38840, -- Enchant Weapon - Demonslaying
	[13937] = 38845, -- Enchant 2H Weapon - Greater Impact
	[13943] = 38848, -- Enchant Weapon - Greater Striking
	[20029] = 38868, -- Enchant Weapon - Icy Chill
	[20030] = 38869, -- Enchant 2H Weapon - Superior Impact
	[20031] = 38870, -- Enchant Weapon - Superior Striking
	[20032] = 38871, -- Enchant Weapon - Lifestealing
	[20033] = 38872, -- Enchant Weapon - Unholy Weapon
	[20034] = 38873, -- Enchant Weapon - Crusader
	[20035] = 38874, -- Enchant 2H Weapon - Major Spirit
	[20036] = 38875, -- Enchant 2H Weapon - Major Intellect
	[21931] = 38876, -- Enchant Weapon - Winter's Might
	[22749] = 38877, -- Enchant Weapon - Spellpower
	[22750] = 38878, -- Enchant Weapon - Healing Power
	[23799] = 38879, -- Enchant Weapon - Strength
	[23800] = 38880, -- Enchant Weapon - Agility
	[23803] = 38883, -- Enchant Weapon - Mighty Spirit
	[23804] = 38884, -- Enchant Weapon - Mighty Intellect
	[27837] = 38896, -- Enchant 2H Weapon - Agility
	[64441] = 46026, -- Enchant Weapon - Blade Ward
	[64579] = 46098, -- Enchant Weapon - Blood Draining
	[7418] = 38679, -- Enchant Bracer - Minor Health
	[7420] = 38766, -- Enchant Chest - Minor Health
	[7426] = 38767, -- Enchant Chest - Minor Absorption
	[7428] = 38768, -- Enchant Bracer - Minor Dodge
	[7443] = 38769, -- Enchant Chest - Minor Mana
	[7457] = 38771, -- Enchant Bracer - Minor Stamina
	[7748] = 38773, -- Enchant Chest - Lesser Health
	[7766] = 38774, -- Enchant Bracer - Minor Spirit
	[7771] = 38775, -- Enchant Cloak - Minor Protection
	[7776] = 38776, -- Enchant Chest - Lesser Mana
	[7779] = 38777, -- Enchant Bracer - Minor Agility
	[7782] = 38778, -- Enchant Bracer - Minor Strength
	[7857] = 38782, -- Enchant Chest - Health
	[7859] = 38783, -- Enchant Bracer - Lesser Spirit
	[7863] = 38785, -- Enchant Boots - Minor Stamina
	[7867] = 38786, -- Enchant Boots - Minor Agility
	[13378] = 38787, -- Enchant Shield - Minor Stamina
	[13419] = 38789, -- Enchant Cloak - Minor Agility
	[13421] = 38790, -- Enchant Cloak - Lesser Protection
	[13464] = 38791, -- Enchant Shield - Lesser Protection
	[13485] = 38792, -- Enchant Shield - Lesser Spirit
	[13501] = 38793, -- Enchant Bracer - Lesser Stamina
	[13536] = 38797, -- Enchant Bracer - Lesser Strength
	[13538] = 38798, -- Enchant Chest - Lesser Absorption
	[13607] = 38799, -- Enchant Chest - Mana
	[13612] = 38800, -- Enchant Gloves - Mining
	[13617] = 38801, -- Enchant Gloves - Herbalism
	[13620] = 38802, -- Enchant Gloves - Fishing
	[13622] = 38803, -- Enchant Bracer - Lesser Intellect
	[13626] = 38804, -- Enchant Chest - Minor Stats
	[13631] = 38805, -- Enchant Shield - Lesser Stamina
	[13635] = 38806, -- Enchant Cloak - Defense
	[13637] = 38807, -- Enchant Boots - Lesser Agility
	[13640] = 38808, -- Enchant Chest - Greater Health
	[13642] = 38809, -- Enchant Bracer - Spirit
	[13644] = 38810, -- Enchant Boots - Lesser Stamina
	[13646] = 38811, -- Enchant Bracer - Lesser Dodge
	[13648] = 38812, -- Enchant Bracer - Stamina
	[13659] = 38816, -- Enchant Shield - Spirit
	[13661] = 38817, -- Enchant Bracer - Strength
	[13663] = 38818, -- Enchant Chest - Greater Mana
	[13687] = 38819, -- Enchant Boots - Lesser Spirit
	[13689] = 38820, -- Enchant Shield - Lesser Parry
	[13698] = 38823, -- Enchant Gloves - Skinning
	[13700] = 38824, -- Enchant Chest - Lesser Stats
	[13746] = 38825, -- Enchant Cloak - Greater Defense
	[13815] = 38827, -- Enchant Gloves - Agility
	[13817] = 38828, -- Enchant Shield - Stamina
	[13822] = 38829, -- Enchant Bracer - Intellect
	[13836] = 38830, -- Enchant Boots - Stamina
	[13841] = 38831, -- Enchant Gloves - Advanced Mining
	[13846] = 38832, -- Enchant Bracer - Greater Spirit
	[13858] = 38833, -- Enchant Chest - Superior Health
	[13868] = 38834, -- Enchant Gloves - Advanced Herbalism
	[13882] = 38835, -- Enchant Cloak - Lesser Agility
	[13887] = 38836, -- Enchant Gloves - Strength
	[13890] = 38837, -- Enchant Boots - Minor Speed
	[13905] = 38839, -- Enchant Shield - Greater Spirit
	[13917] = 38841, -- Enchant Chest - Superior Mana
	[13931] = 38842, -- Enchant Bracer - Dodge
	[13935] = 38844, -- Enchant Boots - Agility
	[13939] = 38846, -- Enchant Bracer - Greater Strength
	[13941] = 38847, -- Enchant Chest - Stats
	[13945] = 38849, -- Enchant Bracer - Greater Stamina
	[13947] = 38850, -- Enchant Gloves - Riding Skill
	[13948] = 38851, -- Enchant Gloves - Minor Haste
	[20008] = 38852, -- Enchant Bracer - Greater Intellect
	[20009] = 38853, -- Enchant Bracer - Superior Spirit
	[20010] = 38854, -- Enchant Bracer - Superior Strength
	[20011] = 38855, -- Enchant Bracer - Superior Stamina
	[20012] = 38856, -- Enchant Gloves - Greater Agility
	[20013] = 38857, -- Enchant Gloves - Greater Strength
	[20015] = 38859, -- Enchant Cloak - Superior Defense
	[20016] = 38860, -- Enchant Shield - Vitality
	[20017] = 38861, -- Enchant Shield - Greater Stamina
	[20020] = 38862, -- Enchant Boots - Greater Stamina
	[20023] = 38863, -- Enchant Boots - Greater Agility
	[20024] = 38864, -- Enchant Boots - Spirit
	[20025] = 38865, -- Enchant Chest - Greater Stats
	[20026] = 38866, -- Enchant Chest - Major Health
	[20028] = 38867, -- Enchant Chest - Major Mana
	[23801] = 38881, -- Enchant Bracer - Mana Regeneration
	[23802] = 38882, -- Enchant Bracer - Healing Power
	[25072] = 38885, -- Enchant Gloves - Threat
	[25073] = 38886, -- Enchant Gloves - Shadow Power
	[25074] = 38887, -- Enchant Gloves - Frost Power
	[25078] = 38888, -- Enchant Gloves - Fire Power
	[25079] = 38889, -- Enchant Gloves - Healing Power
	[25080] = 38890, -- Enchant Gloves - Superior Agility
	[25083] = 38893, -- Enchant Cloak - Stealth
	[25084] = 38894, -- Enchant Cloak - Subtlety
	[44506] = 38960, -- Enchant Gloves - Gatherer
	[63746] = 45628, -- Enchant Boots - Lesser Accuracy
	[71692] = 50816, -- Enchant Gloves - Angler
	[190954] = 128554, -- Enchant Shoulder - Boon of the Scavenger
	[190988] = 128558, -- Enchant Gloves - Legion Herbalism
	[190989] = 128559, -- Enchant Gloves - Legion Mining
	[190990] = 128560, -- Enchant Gloves - Legion Skinning
	[190991] = 128561, -- Enchant Gloves - Legion Surveying
	[190866] = 128537, -- Enchant Ring - Word of Critical Strike Rank 1
	[190992] = 128537, -- Enchant Ring - Word of Critical Strike Rank 2
	[191009] = 128537, -- Enchant Ring - Word of Critical Strike Rank 3
	[190867] = 128538, -- Enchant Ring - Word of Haste Rank 1
	[190993] = 128538, -- Enchant Ring - Word of Haste Rank 2
	[191010] = 128538, -- Enchant Ring - Word of Haste Rank 3
	[190868] = 128539, -- Enchant Ring - Word of Mastery Rank 1
	[190994] = 128539, -- Enchant Ring - Word of Mastery Rank 2
	[191011] = 128539, -- Enchant Ring - Word of Mastery Rank 3
	[190869] = 128540, -- Enchant Ring - Word of Versatility Rank 1
	[190995] = 128540, -- Enchant Ring - Word of Versatility Rank 2
	[191012] = 128540, -- Enchant Ring - Word of Versatility Rank 3
	[190870] = 128541, -- Enchant Ring - Binding of Critical Strike Rank 1
	[190996] = 128541, -- Enchant Ring - Binding of Critical Strike Rank 2
	[191013] = 128541, -- Enchant Ring - Binding of Critical Strike Rank 3
	[190871] = 128542, -- Enchant Ring - Binding of Haste Rank 1
	[190997] = 128542, -- Enchant Ring - Binding of Haste Rank 2
	[191014] = 128542, -- Enchant Ring - Binding of Haste Rank 3
	[190872] = 128543, -- Enchant Ring - Binding of Mastery Rank 1
	[190998] = 128543, -- Enchant Ring - Binding of Mastery Rank 2
	[191015] = 128543, -- Enchant Ring - Binding of Mastery Rank 3
	[190873] = 128544, -- Enchant Ring - Binding of Versatility Rank 1
	[190999] = 128544, -- Enchant Ring - Binding of Versatility Rank 2
	[191016] = 128544, -- Enchant Ring - Binding of Versatility Rank 3
	[190874] = 128545, -- Enchant Cloak - Word of Strength Rank 1
	[191000] = 128545, -- Enchant Cloak - Word of Strength Rank 2
	[191017] = 128545, -- Enchant Cloak - Word of Strength Rank 3
	[190875] = 128546, -- Enchant Cloak - Word of Agility Rank 1
	[191001] = 128546, -- Enchant Cloak - Word of Agility Rank 2
	[191018] = 128546, -- Enchant Cloak - Word of Agility Rank 3
	[190876] = 128547, -- Enchant Cloak - Word of Intellect Rank 1
	[191002] = 128547, -- Enchant Cloak - Word of Intellect Rank 2
	[191019] = 128547, -- Enchant Cloak - Word of Intellect Rank 3
	[190877] = 128548, -- Enchant Cloak - Binding of Strength Rank 1
	[191003] = 128548, -- Enchant Cloak - Binding of Strength Rank 2
	[191020] = 128548, -- Enchant Cloak - Binding of Strength Rank 3
	[190878] = 128549, -- Enchant Cloak - Binding of Agility Rank 1
	[191004] = 128549, -- Enchant Cloak - Binding of Agility Rank 2
	[191021] = 128549, -- Enchant Cloak - Binding of Agility Rank 3
	[190879] = 128550, -- Enchant Cloak - Binding of Intellect Rank 1
	[191005] = 128550, -- Enchant Cloak - Binding of Intellect Rank 2
	[191022] = 128550, -- Enchant Cloak - Binding of Intellect Rank 3
	[190892] = 128551, -- Enchant Neck - Mark of the Claw Rank 1
	[191006] = 128551, -- Enchant Neck - Mark of the Claw Rank 2
	[191023] = 128551, -- Enchant Neck - Mark of the Claw Rank 3
	[190893] = 128552, -- Enchant Neck - Mark of the Distant Army Rank 1
	[191007] = 128552, -- Enchant Neck - Mark of the Distant Army Rank 2
	[191024] = 128552, -- Enchant Neck - Mark of the Distant Army Rank 3
	[190894] = 128553, -- Enchant Neck - Mark of the Hidden Satyr Rank 1
	[191008] = 128553, -- Enchant Neck - Mark of the Hidden Satyr Rank 2
	[191025] = 128553, -- Enchant Neck - Mark of the Hidden Satyr Rank 3
	[228402] = 141908, -- Enchant Neck - Mark of the Heavy Hide Rank 1
	[228403] = 141908, -- Enchant Neck - Mark of the Heavy Hide Rank 2
	[228404] = 141908, -- Enchant Neck - Mark of the Heavy Hide Rank 3
	[228405] = 141909, -- Enchant Neck - Mark of the Trained Soldier Rank 1
	[228406] = 141909, -- Enchant Neck - Mark of the Trained Soldier Rank 2
	[228407] = 141909, -- Enchant Neck - Mark of the Trained Soldier Rank 3
	[228408] = 141910, -- Enchant Neck - Mark of the Ancient Priestess Rank 1
	[228409] = 141910, -- Enchant Neck - Mark of the Ancient Priestess Rank 2
	[228410] = 141910, -- Enchant Neck - Mark of the Ancient Priestess Rank 3
	[235698] = 144307, -- Enchant Neck - Mark of the Deadly Rank 1
	[235702] = 144307, -- Enchant Neck - Mark of the Deadly Rank 2
	[235706] = 144307, -- Enchant Neck - Mark of the Deadly Rank 3
	[235697] = 144306, -- Enchant Neck - Mark of the Quick Rank 1
	[235701] = 144306, -- Enchant Neck - Mark of the Quick Rank 2
	[235705] = 144306, -- Enchant Neck - Mark of the Quick Rank 3
	[235696] = 144305, -- Enchant Neck - Mark of the Versatile Rank 1
	[235700] = 144305, -- Enchant Neck - Mark of the Versatile Rank 2
	[235704] = 144305, -- Enchant Neck - Mark of the Versatile Rank 3
	[235695] = 144304, -- Enchant Neck - Mark of the Master Rank 1
	[235699] = 144304, -- Enchant Neck - Mark of the Master Rank 2
	[235703] = 144304, -- Enchant Neck - Mark of the Master Rank 3
-- Added in Battle for Azeroth (thanks to Tarkumi)
	[255103] = 153476, -- Enchant Weapon - Coastal Surge Rank 1
	[255104] = 153476, -- Enchant Weapon - Coastal Surge Rank 2
	[255105] = 153476, -- Enchant Weapon - Coastal Surge Rank 3
	[255141] = 153480, -- Enchant Weapon - Gale-Force Striking Rank 1
	[255142] = 153480, -- Enchant Weapon - Gale-Force Striking Rank 2
	[255143] = 153480, -- Enchant Weapon - Gale-Force Striking Rank 3
	[255129] = 153479, -- Enchant Weapon - Torrent of Elements Rank 1
	[255130] = 153479, -- Enchant Weapon - Torrent of Elements Rank 2
	[255131] = 153479, -- Enchant Weapon - Torrent of Elements Rank 3
	[255110] = 153478, -- Enchant Weapon - Siphoning Rank 1
	[255111] = 153478, -- Enchant Weapon - Siphoning Rank 2
	[255112] = 153478, -- Enchant Weapon - Siphoning Rank 3
	[268907] = 159785, -- Enchant Weapon - Deadly Navigation Rank 1
	[268908] = 159785, -- Enchant Weapon - Deadly Navigation Rank 2
	[268909] = 159785, -- Enchant Weapon - Deadly Navigation Rank 3
	[268901] = 159787, -- Enchant Weapon - Masterful Navigation Rank 1
	[268902] = 159787, -- Enchant Weapon - Masterful Navigation Rank 2
	[268903] = 159787, -- Enchant Weapon - Masterful Navigation Rank 3
	[268894] = 159786, -- Enchant Weapon - Quick Navigation Rank 1
	[268895] = 159786, -- Enchant Weapon - Quick Navigation Rank 2
	[268897] = 159786, -- Enchant Weapon - Quick Navigation Rank 3
	[268913] = 159789, -- Enchant Weapon - Stalwart Navigation Rank 1
	[268914] = 159789, -- Enchant Weapon - Stalwart Navigation Rank 2
	[268915] = 159789, -- Enchant Weapon - Stalwart Navigation Rank 3
	[268852] = 159788, -- Enchant Weapon - Versatile Navigation Rank 1
	[268878] = 159788, -- Enchant Weapon - Versatile Navigation Rank 2
	[268879] = 159788, -- Enchant Weapon - Versatile Navigation Rank 3
	[255071] = 153438, -- Enchant Ring - Seal of Critical Strike Rank 1
	[255086] = 153438, -- Enchant Ring - Seal of Critical Strike Rank 2
	[255094] = 153438, -- Enchant Ring - Seal of Critical Strike Rank 3
	[255072] = 153439, -- Enchant Ring - Seal of Haste Rank 1
	[255087] = 153439, -- Enchant Ring - Seal of Haste Rank 2
	[255095] = 153439, -- Enchant Ring - Seal of Haste Rank 3
	[255073] = 153440, -- Enchant Ring - Seal of Mastery Rank 1
	[255088] = 153440, -- Enchant Ring - Seal of Mastery Rank 2
	[255096] = 153440, -- Enchant Ring - Seal of Mastery Rank 3
	[255074] = 153441, -- Enchant Ring - Seal of Versatility Rank 1
	[255089] = 153441, -- Enchant Ring - Seal of Versatility Rank 2
	[255097] = 153441, -- Enchant Ring - Seal of Versatility Rank 3
	[255075] = 153442, -- Enchant Ring - Pact of Critical Strike Rank 1
	[255090] = 153442, -- Enchant Ring - Pact of Critical Strike Rank 2
	[255098] = 153442, -- Enchant Ring - Pact of Critical Strike Rank 3
	[255076] = 153443, -- Enchant Ring - Pact of Haste Rank 1
	[255091] = 153443, -- Enchant Ring - Pact of Haste Rank 2
	[255099] = 153443, -- Enchant Ring - Pact of Haste Rank 3
	[255077] = 153444, -- Enchant Ring - Pact of Mastery Rank 1
	[255092] = 153444, -- Enchant Ring - Pact of Mastery Rank 2
	[255100] = 153444, -- Enchant Ring - Pact of Mastery Rank 3
	[255078] = 153445, -- Enchant Ring - Pact of Versatility Rank 1
	[255093] = 153445, -- Enchant Ring - Pact of Versatility Rank 2
	[255101] = 153445, -- Enchant Ring - Pact of Versatility Rank 3
	[267498] = 159471, -- Enchant Gloves - Zandalari Crafting
	[267458] = 159464, -- Enchant Gloves - Zandalari Herbalism
	[267482] = 159466, -- Enchant Gloves - Zandalari Mining
	[267486] = 159467, -- Enchant Gloves - Zandalari Skinning
	[267490] = 159468, -- Enchant Gloves - Zandalari Surveying
	[255070] = 153437, -- Enchant Gloves - Kul Tiran Crafting
	[255035] = 153430, -- Enchant Gloves - Kul Tiran Herbalism
	[255040] = 153431, -- Enchant Gloves - Kul Tiran Mining
	[255065] = 153434, -- Enchant Gloves - Kul Tiran Skinning
	[255066] = 153435, -- Enchant Gloves - Kul Tiran Surveying}
-- Added in 8.2. Rise of Azshara (thanks to Tarkumi)
	[298009] = 168446, -- Enchant Ring - Accord of Critical Strike Rank 1
	[298010] = 168446, -- Enchant Ring - Accord of Critical Strike Rank 2
	[298011] = 168446, -- Enchant Ring - Accord of Critical Strike Rank 3
	[298989] = 168447, -- Enchant Ring - Accord of Haste Rank 1
	[297994] = 168447, -- Enchant Ring - Accord of Haste Rank 2
	[298016] = 168447, -- Enchant Ring - Accord of Haste Rank 3
	[297995] = 168448, -- Enchant Ring - Accord of Mastery Rank 1
	[298001] = 168448, -- Enchant Ring - Accord of Mastery Rank 2
	[298002] = 168448, -- Enchant Ring - Accord of Mastery Rank 3
	[297993] = 168449, -- Enchant Ring - Accord of Versatility Rank 1
	[297991] = 168449, -- Enchant Ring - Accord of Versatility Rank 2
	[297999] = 168449, -- Enchant Ring - Accord of Versatility Rank 3
	[298440] = 168596, -- Enchant Weapon - Force Multiplier Rank 1
	[298439] = 168596, -- Enchant Weapon - Force Multiplier Rank 2
	[300788] = 168596, -- Enchant Weapon - Force Multiplier Rank 3
	[298433] = 168593, -- Enchant Weapon - Machinist's Brilliance Rank 1
	[300769] = 168593, -- Enchant Weapon - Machinist's Brilliance Rank 2
	[300770] = 168593, -- Enchant Weapon - Machinist's Brilliance Rank 3
	[298442] = 168598, -- Enchant Weapon - Naga Hide Rank 1
	[298441] = 168598, -- Enchant Weapon - Naga Hide Rank 2
	[300789] = 168598, -- Enchant Weapon - Naga Hide Rank 3
	[298438] = 168592, -- Enchant Weapon - Oceanic Restoration Rank 1
	[298437] = 168592, -- Enchant Weapon - Oceanic Restoration Rank 2
	[298515] = 168592, -- Enchant Weapon - Oceanic Restoration Rank 3
-- Added in 9.0.2 Shadowlands (thanks to Tarkumi)
	[309524] = 172406, -- Enchant Gloves - Shadowlands Gathering
	[309525] = 172407, -- Enchant Gloves - Strength of Soul
	[309526] = 172408, -- Enchant Gloves - Eternal Strength
	[309528] = 172410, -- Enchant Cloak - Fortified Speed
	[309530] = 172411, -- Enchant Cloak - Fortified Avoidance
	[309531] = 172412, -- Enchant Cloak - Fortified Leech
	[309532] = 172413, -- Enchant Boots - Agile Soulwalker
	[309534] = 172419, -- Enchant Boots - Eternal Agility
	[309535] = 172418, -- Enchant Chest - Eternal Bulwark
	[309608] = 172414, -- Enchant Bracers - Illuminated Soul
	[309609] = 172415, -- Enchant Bracers - Eternal Intellect
	[309610] = 172416, -- Enchant Bracers - Shaded Hearthing
	[309612] = 172357, -- Enchant Ring - Bargain of Critical Strike
	[309613] = 172358, -- Enchant Ring - Bargain of Haste
	[309614] = 172359, -- Enchant Ring - Bargain of Mastery
	[309615] = 172360, -- Enchant Ring - Bargain of Versatility
	[309616] = 172361, -- Enchant Ring - Tenet of Critical Strike
	[309617] = 172362, -- Enchant Ring - Tenet of Haste
	[309618] = 172363, -- Enchant Ring - Tenet of Mastery
	[309619] = 172364, -- Enchant Ring - Tenet of Versatility
	[309620] = 172370, -- Enchant Weapon - Lightless Force
	[309621] = 172367, -- Enchant Weapon - Eternal Grace
	[309622] = 172365, -- Enchant Weapon - Ascended Vigor
	[309623] = 172368, -- Enchant Weapon - Sinful Revelation
	[309627] = 172366, -- Enchant Weapon - Celestial Guidance
	[323609] = 177661, -- Enchant Boots - Speed of Soul
	[323755] = 177660, -- Enchant Cloak - Soul Vitality
	[323760] = 177659, -- Enchant Chest - Eternal Skirmish
	[323761] = 177715, -- Enchant Chest - Eternal Bounds
	[323762] = 177716, -- Enchant Chest - Sacred Stats
	[324773] = 177962, -- Enchant Chest - Eternal Stats
	[342316] = 183738, -- Enchant Chest - Eternal Insight
}
--
-- Items in this list are ignored because they can cause infinite loops.
--
Skillet.TradeSkillIgnoredMats = {
	[11479] = 1 , -- Transmute: Iron to Gold
	[11480] = 1 , -- Transmute: Mithril to Truesilver
	[60350] = 1 , -- Transmute: Titanium
	[17559] = 1 , -- Transmute: Air to Fire
	[17560] = 1 , -- Transmute: Fire to Earth
	[17561] = 1 , -- Transmute: Earth to Water
	[17562] = 1 , -- Transmute: Water to Air
	[17563] = 1 , -- Transmute: Undeath to Water
	[17565] = 1 , -- Transmute: Life to Earth
	[17566] = 1 , -- Transmute: Earth to Life
	[28585] = 1 , -- Transmute: Primal Earth to Life
	[28566] = 1 , -- Transmute: Primal Air to Fire
	[28567] = 1 , -- Transmute: Primal Earth to Water
	[28568] = 1 , -- Transmute: Primal Fire to Earth
	[28569] = 1 , -- Transmute: Primal Water to Air
	[28580] = 1 , -- Transmute: Primal Shadow to Water
	[28581] = 1 , -- Transmute: Primal Water to Shadow
	[28582] = 1 , -- Transmute: Primal Mana to Fire
	[28583] = 1 , -- Transmute: Primal Fire to Mana
	[28584] = 1 , -- Transmute: Primal Life to Earth
	[53771] = 1 , -- Transmute: Eternal Life to Shadow
	[53773] = 1 , -- Transmute: Eternal Life to Fire
	[53774] = 1 , -- Transmute: Eternal Fire to Water
	[53775] = 1 , -- Transmute: Eternal Fire to Life
	[53776] = 1 , -- Transmute: Eternal Air to Water
	[53777] = 1 , -- Transmute: Eternal Air to Earth
	[53779] = 1 , -- Transmute: Eternal Shadow to Earth
	[53780] = 1 , -- Transmute: Eternal Shadow to Life
	[53781] = 1 , -- Transmute: Eternal Earth to Air
	[53782] = 1 , -- Transmute: Eternal Earth to Shadow
	[53783] = 1 , -- Transmute: Eternal Water to Air
	[53784] = 1 , -- Transmute: Eternal Water to Fire
	[181637] = 1 , -- Transmute: Sorcerous-air-to-earth
	[181633] = 1 , -- Transmute: Sorcerous-air-to-fire
	[181636] = 1 , -- Transmute: Sorcerous-air-to-water
	[181631] = 1 , -- Transmute: Sorcerous-earth-to-air
	[181632] = 1 , -- Transmute: Sorcerous-earth-to-fire
	[181635] = 1 , -- Transmute: Sorcerous-earth-to-water
	[181627] = 1 , -- Transmute: Sorcerous-fire-to-air
	[181625] = 1 , -- Transmute: Sorcerous-fire-to-earth
	[181628] = 1 , -- Transmute: Sorcerous-fire-to-water
	[181630] = 1 , -- Transmute: Sorcerous-water-to-air
	[181629] = 1 , -- Transmute: Sorcerous-water-to-earth
	[181634] = 1 , -- Transmute: Sorcerous-water-to-fire
	[181643] = 1 , -- Transmute: Savage Blood
	[42615] = 1 ,  -- Small Prismatic Shard
	[28022] = 1 ,  -- Large Prismatic Shard
	[118239] = 1 , -- Sha Shatter
	[116499] = 1 , -- Sha Crystal
	[118238] = 1 , -- Ethereal Shatter
	[116498] = 1 , -- Ethereal Shard
	[118237] = 1 , -- Mysterious Diffusion
	[116497] = 1 , -- Mysterious Essence
--	[45765] = 1 ,  -- Void Shatter
--	[252106] = 1 , -- Chaos Shatter
	[309644] = 1 , -- Shatter Sacred Shard
	[309645] = 1 , -- Shatter Eternal Crystal
	[323796] = 1 , -- Combine Soul Dust
	[323797] = 1 , -- Combine Sacred Shard
}

--
-- Table used by Inscription to convert inks
--
local topink = 173058				-- Umbral Ink
Skillet.SpecialVendorItems = {
	[37101] = {1, topink},			--Ivory Ink (obsolete?)
	[39469] = {1, topink},			--Moonglow Ink
	[39774] = {1, topink},			--Midnight Ink
	[43116] = {1, topink},			--Lions Ink
	[43118] = {1, topink},			--Jadefire Ink
	[43120] = {1, topink},			--Celestial Ink
	[43122] = {1, topink},			--Shimmering Ink
	[43124] = {1, topink},			--Ethereal Ink
	[43126] = {1, topink},			--Ink of the Sea
	[61978] = {1, topink},			--Blackfallow Ink
	[79254] = {1, topink},			--Ink of Dreams
	[113111] = {1, topink},			--Warbinder's Ink
	[129032] = {1, topink},			--Roseate Pigment
	[129034] = {1, topink},			--Sallow Pigment
	[168663] = {1, topink},			--Maroon Ink
	[158188] = {1, topink},			--Crimson Ink
	[158187] = {1, topink},			--Ultramarine Ink

	[43125] = {10, topink},			--Darkflame Ink
	[43127] = {10, topink},			--Snowfall Ink
	[61981] = {10, topink},			--Inferno Ink
	[79255] = {10, topink},			--Starlight Ink
	[158189] = {10, topink},		--Viridescent Ink
}

