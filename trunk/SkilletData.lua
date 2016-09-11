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

local PT = LibStub("LibPeriodicTable-3.1")
local L = Skillet.L

--[[ == Global Tables == ]]--

-- Table of tradeskills that should use the Blizzard frame
Skillet.BlizzardSkillList = {
	[5419]   = true,		-- ???
	[53428]  = true,		-- runeforging
	[194174] = true,		-- skinning skills
	[193290] = true,		-- herbalism skills
}

-- Table of follower (C_TradeSkillUI.IsNPCCrafting) tradeskills that should use the Blizzard frame
Skillet.FollowerSkillList = {
}

-- In case the previous table is too broad
-- Table of follower (C_TradeSkillUI.IsNPCCrafting) NPC IDs (from GUID) that should use the Blizzard frame 
Skillet.FollowerNPC = {
}

Skillet.TradeSkillAdditionalAbilities = {
	[7411]	= {13262,"Disenchant"},		-- enchanting = disenchant
	[2550]	= {818,"Basic_Campfire"},	-- cooking = basic campfire
	[45357] = {51005,"Milling"},		-- inscription = milling
	[25229] = {31252,"Prospecting"},	-- jewelcrafting = prospecting
	[2018]	= {126462,"Thermal_Anvil"},	 -- blacksmithing = thermal anvil (item:87216)
	[4036]	= {126462,"Thermal_Anvil"},	 -- engineering = thermal anvil (item:87216)
	[2575]	= {126462,"Thermal_Anvil"},	 -- smelting = thermal anvil (item:87216)
}

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
		[124105] = 5, -- Starlight-rose
		[124106] = 5, -- Felwort
		[128304] = 5, -- Yseralline-seed
	}
}

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
}

--[[
Skillet.enchantingItemIDs = {
	-- "Borrowed" from TradeSkillMaster_Crafting\Modules\EnchantingInfo.lua
	-- Scraped from Wowhead (http://www.wowhead.com/items/consumables/item-enhancements-permanent?filter=86;4;0) using the following javascript:
	-- for (i=0; i<listviewitems.length; i++) console.log("["+listviewitems[i].sourcemore[0].ti+"] = \"i:"+listviewitems[i].id+"\",  -- "+listviewitems[i].name.substr(1));
	[158914] = "i:110638",  -- Enchant Ring - Gift of Critical Strike
	[158915] = "i:110639",  -- Enchant Ring - Gift of Haste
	[158916] = "i:110640",  -- Enchant Ring - Gift of Mastery
	[158917] = "i:110641",  -- Enchant Ring - Gift of Multistrike
	[158918] = "i:110642",  -- Enchant Ring - Gift of Versatility
	[158899] = "i:110645",  -- Enchant Neck - Gift of Critical Strike
	[158900] = "i:110646",  -- Enchant Neck - Gift of Haste
	[158901] = "i:110647",  -- Enchant Neck - Gift of Mastery
	[158902] = "i:110648",  -- Enchant Neck - Gift of Multistrike
	[158903] = "i:110649",  -- Enchant Neck - Gift of Versatility
	[158884] = "i:110652",  -- Enchant Cloak - Gift of Critical Strike
	[158885] = "i:110653",  -- Enchant Cloak - Gift of Haste
	[158886] = "i:110654",  -- Enchant Cloak - Gift of Mastery
	[158887] = "i:110655",  -- Enchant Cloak - Gift of Multistrike
	[158889] = "i:110656",  -- Enchant Cloak - Gift of Versatility
	[159235] = "i:110682",  -- Enchant Weapon - Mark of the Thunderlord
	[159236] = "i:112093",  -- Enchant Weapon - Mark of the Shattered Hand
	[159673] = "i:112115",  -- Enchant Weapon - Mark of Shadowmoon
	[159674] = "i:112160",  -- Enchant Weapon - Mark of Blackrock
	[159671] = "i:112164",  -- Enchant Weapon - Mark of Warsong
	[159672] = "i:112165",  -- Enchant Weapon - Mark of the Frostwolf
	[173323] = "i:118015",  -- Enchant Weapon - Mark of Bleeding Hollow
	[158907] = "i:110617",  -- Enchant Ring - Breath of Critical Strike
	[158908] = "i:110618",  -- Enchant Ring - Breath of Haste
	[158909] = "i:110619",  -- Enchant Ring - Breath of Mastery
	[158910] = "i:110620",  -- Enchant Ring - Breath of Multistrike
	[158911] = "i:110621",  -- Enchant Ring - Breath of Versatility
	[158892] = "i:110624",  -- Enchant Neck - Breath of Critical Strike
	[158893] = "i:110625",  -- Enchant Neck - Breath of Haste
	[158894] = "i:110626",  -- Enchant Neck - Breath of Mastery
	[158895] = "i:110627",  -- Enchant Neck - Breath of Multistrike
	[158896] = "i:110628",  -- Enchant Neck - Breath of Versatility
	[158877] = "i:110631",  -- Enchant Cloak - Breath of Critical Strike
	[158878] = "i:110632",  -- Enchant Cloak - Breath of Haste
	[158879] = "i:110633",  -- Enchant Cloak - Breath of Mastery
	[158880] = "i:110634",  -- Enchant Cloak - Breath of Multistrike
	[158881] = "i:110635",  -- Enchant Cloak - Breath of Versatility
	[104425] = "i:74723",  -- Enchant Weapon - Windsong
	[104427] = "i:74724",  -- Enchant Weapon - Jade Spirit
	[104430] = "i:74725",  -- Enchant Weapon - Elemental Force
	[104434] = "i:74726",  -- Enchant Weapon - Dancing Steel
	[104440] = "i:74727",  -- Enchant Weapon - Colossus
	[104442] = "i:74728",  -- Enchant Weapon - River's Song
	[104338] = "i:74700",  -- Enchant Bracer - Mastery
	[104385] = "i:74701",  -- Enchant Bracer - Major Dodge
	[104389] = "i:74703",  -- Enchant Bracer - Super Intellect
	[104390] = "i:74704",  -- Enchant Bracer - Exceptional Strength
	[104391] = "i:74705",  -- Enchant Bracer - Greater Agility
	[104392] = "i:74706",  -- Enchant Chest - Super Resilience
	[104393] = "i:74707",  -- Enchant Chest - Mighty Spirit
	[104395] = "i:74708",  -- Enchant Chest - Glorious Stats
	[104397] = "i:74709",  -- Enchant Chest - Superior Stamina
	[104398] = "i:74710",  -- Enchant Cloak - Accuracy
	[104401] = "i:74711",  -- Enchant Cloak - Greater Protection
	[104403] = "i:74712",  -- Enchant Cloak - Superior Intellect
	[104404] = "i:74713",  -- Enchant Cloak - Superior Critical Strike
	[104407] = "i:74715",  -- Enchant Boots - Greater Haste
	[104408] = "i:74716",  -- Enchant Boots - Greater Precision
	[104409] = "i:74717",  -- Enchant Boots - Blurred Speed
	[104414] = "i:74718",  -- Enchant Boots - Pandaren's Step
	[104416] = "i:74719",  -- Enchant Gloves - Greater Haste
	[104417] = "i:74720",  -- Enchant Gloves - Superior Haste
	[104419] = "i:74721",  -- Enchant Gloves - Super Strength
	[104420] = "i:74722",  -- Enchant Gloves - Superior Mastery
	[104445] = "i:74729",  -- Enchant Off-Hand - Major Intellect
	[130758] = "i:89737",  -- Enchant Shield - Greater Parry
	[74195] = "i:52747",  -- Enchant Weapon - Mending
	[96264] = "i:68784",  -- Enchant Bracer - Agility
	[96261] = "i:68785",  -- Enchant Bracer - Major Strength
	[96262] = "i:68786",  -- Enchant Bracer - Mighty Intellect
	[74132] = "i:52687",  -- Enchant Gloves - Mastery
	[74189] = "i:52743",  -- Enchant Boots - Earthen Vitality
	[74191] = "i:52744",  -- Enchant Chest - Mighty Stats
	[74192] = "i:52745",  -- Enchant Cloak - Lesser Power
	[74193] = "i:52746",  -- Enchant Bracer - Speed
	[74197] = "i:52748",  -- Enchant Weapon - Avalanche
	[74198] = "i:52749",  -- Enchant Gloves - Haste
	[74199] = "i:52750",  -- Enchant Boots - Haste
	[74200] = "i:52751",  -- Enchant Chest - Stamina
	[74201] = "i:52752",  -- Enchant Bracer - Critical Strike
	[74202] = "i:52753",  -- Enchant Cloak - Intellect
	[74207] = "i:52754",  -- Enchant Shield - Protection
	[74211] = "i:52755",  -- Enchant Weapon - Elemental Slayer
	[74212] = "i:52756",  -- Enchant Gloves - Exceptional Strength
	[74213] = "i:52757",  -- Enchant Boots - Major Agility
	[74214] = "i:52758",  -- Enchant Chest - Mighty Resilience
	[74220] = "i:52759",  -- Enchant Gloves - Greater Haste
	[74223] = "i:52760",  -- Enchant Weapon - Hurricane
	[74225] = "i:52761",  -- Enchant Weapon - Heartsong
	[74226] = "i:52762",  -- Enchant Shield - Mastery
	[74229] = "i:52763",  -- Enchant Bracer - Superior Dodge
	[74230] = "i:52764",  -- Enchant Cloak - Critical Strike
	[74231] = "i:52765",  -- Enchant Chest - Exceptional Spirit
	[74232] = "i:52766",  -- Enchant Bracer - Precision
	[74234] = "i:52767",  -- Enchant Cloak - Protection
	[74235] = "i:52768",  -- Enchant Off-Hand - Superior Intellect
	[74236] = "i:52769",  -- Enchant Boots - Precision
	[74237] = "i:52770",  -- Enchant Bracer - Exceptional Spirit
	[74238] = "i:52771",  -- Enchant Boots - Mastery
	[74239] = "i:52772",  -- Enchant Bracer - Greater Haste
	[74240] = "i:52773",  -- Enchant Cloak - Greater Intellect
	[74242] = "i:52774",  -- Enchant Weapon - Power Torrent
	[74244] = "i:52775",  -- Enchant Weapon - Windwalk
	[74246] = "i:52776",  -- Enchant Weapon - Landslide
	[74247] = "i:52777",  -- Enchant Cloak - Greater Critical Strike
	[74248] = "i:52778",  -- Enchant Bracer - Greater Critical Strike
	[74250] = "i:52779",  -- Enchant Chest - Peerless Stats
	[74251] = "i:52780",  -- Enchant Chest - Greater Stamina
	[74252] = "i:52781",  -- Enchant Boots - Assassin's Step
	[74253] = "i:52782",  -- Enchant Boots - Lavawalker
	[74254] = "i:52783",  -- Enchant Gloves - Mighty Strength
	[74255] = "i:52784",  -- Enchant Gloves - Greater Mastery
	[74256] = "i:52785",  -- Enchant Bracer - Greater Speed
	[95471] = "i:68134",  -- Enchant 2H Weapon - Mighty Agility
	[42974] = "i:38948",  -- Enchant Weapon - Executioner
	[44510] = "i:38963",  -- Enchant Weapon - Exceptional Spirit
	[44524] = "i:38965",  -- Enchant Weapon - Icebreaker
	[44576] = "i:38972",  -- Enchant Weapon - Lifeward
	[44595] = "i:38981",  -- Enchant 2H Weapon - Scourgebane
	[44621] = "i:38988",  -- Enchant Weapon - Giant Slayer
	[44629] = "i:38991",  -- Enchant Weapon - Exceptional Spellpower
	[44630] = "i:38992",  -- Enchant 2H Weapon - Greater Savagery
	[44633] = "i:38995",  -- Enchant Weapon - Exceptional Agility
	[46578] = "i:38998",  -- Enchant Weapon - Deathfrost
	[59625] = "i:43987",  -- Enchant Weapon - Black Magic
	[60621] = "i:44453",  -- Enchant Weapon - Greater Potency
	[60691] = "i:44463",  -- Enchant 2H Weapon - Massacre
	[60707] = "i:44466",  -- Enchant Weapon - Superior Potency
	[60714] = "i:44467",  -- Enchant Weapon - Mighty Spellpower
	[59621] = "i:44493",  -- Enchant Weapon - Berserking
	[59619] = "i:44497",  -- Enchant Weapon - Accuracy
	[62948] = "i:45056",  -- Enchant Staff - Greater Spellpower
	[62959] = "i:45060",  -- Enchant Staff - Spellpower
	[27958] = "i:38912",  -- Enchant Chest - Exceptional Mana
	[44484] = "i:38951",  -- Enchant Gloves - Haste
	[44488] = "i:38953",  -- Enchant Gloves - Precision
	[44489] = "i:38954",  -- Enchant Shield - Dodge
	[44492] = "i:38955",  -- Enchant Chest - Mighty Health
	[44500] = "i:38959",  -- Enchant Cloak - Superior Agility
	[44508] = "i:38961",  -- Enchant Boots - Greater Spirit
	[44509] = "i:38962",  -- Enchant Chest - Greater Mana Restoration
	[44513] = "i:38964",  -- Enchant Gloves - Greater Assault
	[44528] = "i:38966",  -- Enchant Boots - Greater Fortitude
	[44529] = "i:38967",  -- Enchant Gloves - Major Agility
	[44555] = "i:38968",  -- Enchant Bracer - Exceptional Intellect
	[60616] = "i:38971",  -- Enchant Bracer - Assault
	[44582] = "i:38973",  -- Enchant Cloak - Minor Power
	[44584] = "i:38974",  -- Enchant Boots - Greater Vitality
	[44588] = "i:38975",  -- Enchant Chest - Exceptional Resilience
	[44589] = "i:38976",  -- Enchant Boots - Superior Agility
	[44591] = "i:38978",  -- Enchant Cloak - Superior Dodge
	[44592] = "i:38979",  -- Enchant Gloves - Exceptional Spellpower
	[44593] = "i:38980",  -- Enchant Bracer - Major Spirit
	[44598] = "i:38984",  -- Enchant Bracer - Haste
	[60623] = "i:38986",  -- Enchant Boots - Icewalker
	[44616] = "i:38987",  -- Enchant Bracer - Greater Stats
	[44623] = "i:38989",  -- Enchant Chest - Super Stats
	[44625] = "i:38990",  -- Enchant Gloves - Armsman
	[44631] = "i:38993",  -- Enchant Cloak - Shadow Armor
	[44635] = "i:38997",  -- Enchant Bracer - Greater Spellpower
	[47672] = "i:39001",  -- Enchant Cloak - Mighty Stamina
	[47766] = "i:39002",  -- Enchant Chest - Greater Dodge
	[47898] = "i:39003",  -- Enchant Cloak - Greater Speed
	[47899] = "i:39004",  -- Enchant Cloak - Wisdom
	[47900] = "i:39005",  -- Enchant Chest - Super Health
	[47901] = "i:39006",  -- Enchant Boots - Tuskarr's Vitality
	[60606] = "i:44449",  -- Enchant Boots - Assault
	[60653] = "i:44455",  -- Shield Enchant - Greater Intellect
	[60609] = "i:44456",  -- Enchant Cloak - Speed
	[60663] = "i:44457",  -- Enchant Cloak - Major Agility
	[60668] = "i:44458",  -- Enchant Gloves - Crusher
	[60692] = "i:44465",  -- Enchant Chest - Powerful Stats
	[60763] = "i:44469",  -- Enchant Boots - Greater Assault
	[60767] = "i:44470",  -- Enchant Bracer - Superior Spellpower
	[44575] = "i:44815",  -- Enchant Bracer - Greater Assault
	[62256] = "i:44947",  -- Enchant Bracer - Major Stamina
	[27967] = "i:38917",  -- Enchant Weapon - Major Striking
	[27968] = "i:38918",  -- Enchant Weapon - Major Intellect
	[27971] = "i:38919",  -- Enchant 2H Weapon - Savagery
	[27972] = "i:38920",  -- Enchant Weapon - Potency
	[27975] = "i:38921",  -- Enchant Weapon - Major Spellpower
	[27977] = "i:38922",  -- Enchant 2H Weapon - Major Agility
	[27981] = "i:38923",  -- Enchant Weapon - Sunfire
	[27982] = "i:38924",  -- Enchant Weapon - Soulfrost
	[27984] = "i:38925",  -- Enchant Weapon - Mongoose
	[28003] = "i:38926",  -- Enchant Weapon - Spellsurge
	[28004] = "i:38927",  -- Enchant Weapon - Battlemaster
	[34010] = "i:38946",  -- Enchant Weapon - Major Healing
	[42620] = "i:38947",  -- Enchant Weapon - Greater Agility
	[27951] = "i:37603",  -- Enchant Boots - Dexterity
	[25086] = "i:38895",  -- Enchant Cloak - Dodge
	[27899] = "i:38897",  -- Enchant Bracer - Brawn
	[27905] = "i:38898",  -- Enchant Bracer - Stats
	[27906] = "i:38899",  -- Enchant Bracer - Greater Dodge
	[27911] = "i:38900",  -- Enchant Bracer - Superior Healing
	[27913] = "i:38901",  -- Enchant Bracer - Restore Mana Prime
	[27914] = "i:38902",  -- Enchant Bracer - Fortitude
	[27917] = "i:38903",  -- Enchant Bracer - Spellpower
	[27944] = "i:38904",  -- Enchant Shield - Lesser Dodge
	[27945] = "i:38905",  -- Enchant Shield - Intellect
	[27946] = "i:38906",  -- Enchant Shield - Parry
	[27948] = "i:38908",  -- Enchant Boots - Vitality
	[27950] = "i:38909",  -- Enchant Boots - Fortitude
	[27954] = "i:38910",  -- Enchant Boots - Surefooted
	[27957] = "i:38911",  -- Enchant Chest - Exceptional Health
	[27960] = "i:38913",  -- Enchant Chest - Exceptional Stats
	[27961] = "i:38914",  -- Enchant Cloak - Major Armor
	[33990] = "i:38928",  -- Enchant Chest - Major Spirit
	[33991] = "i:38929",  -- Enchant Chest - Restore Mana Prime
	[33992] = "i:38930",  -- Enchant Chest - Major Resilience
	[33993] = "i:38931",  -- Enchant Gloves - Blasting
	[33994] = "i:38932",  -- Enchant Gloves - Precise Strikes
	[33995] = "i:38933",  -- Enchant Gloves - Major Strength
	[33996] = "i:38934",  -- Enchant Gloves - Assault
	[33997] = "i:38935",  -- Enchant Gloves - Major Spellpower
	[33999] = "i:38936",  -- Enchant Gloves - Major Healing
	[34001] = "i:38937",  -- Enchant Bracer - Major Intellect
	[34002] = "i:38938",  -- Enchant Bracer - Lesser Assault
	[34003] = "i:38939",  -- Enchant Cloak - PvP Power
	[34004] = "i:38940",  -- Enchant Cloak - Greater Agility
	[34007] = "i:38943",  -- Enchant Boots - Cat's Swiftness
	[34008] = "i:38944",  -- Enchant Boots - Boar's Speed
	[34009] = "i:38945",  -- Enchant Shield - Major Stamina
	[44383] = "i:38949",  -- Enchant Shield - Resilience
	[46594] = "i:38999",  -- Enchant Chest - Dodge
	[47051] = "i:39000",  -- Enchant Cloak - Greater Dodge
	[7745] = "i:38772",  -- Enchant 2H Weapon - Minor Impact
	[7786] = "i:38779",  -- Enchant Weapon - Minor Beastslayer
	[7788] = "i:38780",  -- Enchant Weapon - Minor Striking
	[7793] = "i:38781",  -- Enchant 2H Weapon - Lesser Intellect
	[13380] = "i:38788",  -- Enchant 2H Weapon - Lesser Spirit
	[13503] = "i:38794",  -- Enchant Weapon - Lesser Striking
	[13529] = "i:38796",  -- Enchant 2H Weapon - Lesser Impact
	[13653] = "i:38813",  -- Enchant Weapon - Lesser Beastslayer
	[13655] = "i:38814",  -- Enchant Weapon - Lesser Elemental Slayer
	[13693] = "i:38821",  -- Enchant Weapon - Striking
	[13695] = "i:38822",  -- Enchant 2H Weapon - Impact
	[13898] = "i:38838",  -- Enchant Weapon - Fiery Weapon
	[13915] = "i:38840",  -- Enchant Weapon - Demonslaying
	[13937] = "i:38845",  -- Enchant 2H Weapon - Greater Impact
	[13943] = "i:38848",  -- Enchant Weapon - Greater Striking
	[20029] = "i:38868",  -- Enchant Weapon - Icy Chill
	[20030] = "i:38869",  -- Enchant 2H Weapon - Superior Impact
	[20031] = "i:38870",  -- Enchant Weapon - Superior Striking
	[20032] = "i:38871",  -- Enchant Weapon - Lifestealing
	[20033] = "i:38872",  -- Enchant Weapon - Unholy Weapon
	[20034] = "i:38873",  -- Enchant Weapon - Crusader
	[20035] = "i:38874",  -- Enchant 2H Weapon - Major Spirit
	[20036] = "i:38875",  -- Enchant 2H Weapon - Major Intellect
	[21931] = "i:38876",  -- Enchant Weapon - Winter's Might
	[22749] = "i:38877",  -- Enchant Weapon - Spellpower
	[22750] = "i:38878",  -- Enchant Weapon - Healing Power
	[23799] = "i:38879",  -- Enchant Weapon - Strength
	[23800] = "i:38880",  -- Enchant Weapon - Agility
	[23803] = "i:38883",  -- Enchant Weapon - Mighty Spirit
	[23804] = "i:38884",  -- Enchant Weapon - Mighty Intellect
	[27837] = "i:38896",  -- Enchant 2H Weapon - Agility
	[64441] = "i:46026",  -- Enchant Weapon - Blade Ward
	[64579] = "i:46098",  -- Enchant Weapon - Blood Draining
	[7418] = "i:38679",  -- Enchant Bracer - Minor Health
	[7420] = "i:38766",  -- Enchant Chest - Minor Health
	[7426] = "i:38767",  -- Enchant Chest - Minor Absorption
	[7428] = "i:38768",  -- Enchant Bracer - Minor Dodge
	[7443] = "i:38769",  -- Enchant Chest - Minor Mana
	[7457] = "i:38771",  -- Enchant Bracer - Minor Stamina
	[7748] = "i:38773",  -- Enchant Chest - Lesser Health
	[7766] = "i:38774",  -- Enchant Bracer - Minor Spirit
	[7771] = "i:38775",  -- Enchant Cloak - Minor Protection
	[7776] = "i:38776",  -- Enchant Chest - Lesser Mana
	[7779] = "i:38777",  -- Enchant Bracer - Minor Agility
	[7782] = "i:38778",  -- Enchant Bracer - Minor Strength
	[7857] = "i:38782",  -- Enchant Chest - Health
	[7859] = "i:38783",  -- Enchant Bracer - Lesser Spirit
	[7863] = "i:38785",  -- Enchant Boots - Minor Stamina
	[7867] = "i:38786",  -- Enchant Boots - Minor Agility
	[13378] = "i:38787",  -- Enchant Shield - Minor Stamina
	[13419] = "i:38789",  -- Enchant Cloak - Minor Agility
	[13421] = "i:38790",  -- Enchant Cloak - Lesser Protection
	[13464] = "i:38791",  -- Enchant Shield - Lesser Protection
	[13485] = "i:38792",  -- Enchant Shield - Lesser Spirit
	[13501] = "i:38793",  -- Enchant Bracer - Lesser Stamina
	[13536] = "i:38797",  -- Enchant Bracer - Lesser Strength
	[13538] = "i:38798",  -- Enchant Chest - Lesser Absorption
	[13607] = "i:38799",  -- Enchant Chest - Mana
	[13612] = "i:38800",  -- Enchant Gloves - Mining
	[13617] = "i:38801",  -- Enchant Gloves - Herbalism
	[13620] = "i:38802",  -- Enchant Gloves - Fishing
	[13622] = "i:38803",  -- Enchant Bracer - Lesser Intellect
	[13626] = "i:38804",  -- Enchant Chest - Minor Stats
	[13631] = "i:38805",  -- Enchant Shield - Lesser Stamina
	[13635] = "i:38806",  -- Enchant Cloak - Defense
	[13637] = "i:38807",  -- Enchant Boots - Lesser Agility
	[13640] = "i:38808",  -- Enchant Chest - Greater Health
	[13642] = "i:38809",  -- Enchant Bracer - Spirit
	[13644] = "i:38810",  -- Enchant Boots - Lesser Stamina
	[13646] = "i:38811",  -- Enchant Bracer - Lesser Dodge
	[13648] = "i:38812",  -- Enchant Bracer - Stamina
	[13659] = "i:38816",  -- Enchant Shield - Spirit
	[13661] = "i:38817",  -- Enchant Bracer - Strength
	[13663] = "i:38818",  -- Enchant Chest - Greater Mana
	[13687] = "i:38819",  -- Enchant Boots - Lesser Spirit
	[13689] = "i:38820",  -- Enchant Shield - Lesser Parry
	[13698] = "i:38823",  -- Enchant Gloves - Skinning
	[13700] = "i:38824",  -- Enchant Chest - Lesser Stats
	[13746] = "i:38825",  -- Enchant Cloak - Greater Defense
	[13815] = "i:38827",  -- Enchant Gloves - Agility
	[13817] = "i:38828",  -- Enchant Shield - Stamina
	[13822] = "i:38829",  -- Enchant Bracer - Intellect
	[13836] = "i:38830",  -- Enchant Boots - Stamina
	[13841] = "i:38831",  -- Enchant Gloves - Advanced Mining
	[13846] = "i:38832",  -- Enchant Bracer - Greater Spirit
	[13858] = "i:38833",  -- Enchant Chest - Superior Health
	[13868] = "i:38834",  -- Enchant Gloves - Advanced Herbalism
	[13882] = "i:38835",  -- Enchant Cloak - Lesser Agility
	[13887] = "i:38836",  -- Enchant Gloves - Strength
	[13890] = "i:38837",  -- Enchant Boots - Minor Speed
	[13905] = "i:38839",  -- Enchant Shield - Greater Spirit
	[13917] = "i:38841",  -- Enchant Chest - Superior Mana
	[13931] = "i:38842",  -- Enchant Bracer - Dodge
	[13935] = "i:38844",  -- Enchant Boots - Agility
	[13939] = "i:38846",  -- Enchant Bracer - Greater Strength
	[13941] = "i:38847",  -- Enchant Chest - Stats
	[13945] = "i:38849",  -- Enchant Bracer - Greater Stamina
	[13947] = "i:38850",  -- Enchant Gloves - Riding Skill
	[13948] = "i:38851",  -- Enchant Gloves - Minor Haste
	[20008] = "i:38852",  -- Enchant Bracer - Greater Intellect
	[20009] = "i:38853",  -- Enchant Bracer - Superior Spirit
	[20010] = "i:38854",  -- Enchant Bracer - Superior Strength
	[20011] = "i:38855",  -- Enchant Bracer - Superior Stamina
	[20012] = "i:38856",  -- Enchant Gloves - Greater Agility
	[20013] = "i:38857",  -- Enchant Gloves - Greater Strength
	[20015] = "i:38859",  -- Enchant Cloak - Superior Defense
	[20016] = "i:38860",  -- Enchant Shield - Vitality
	[20017] = "i:38861",  -- Enchant Shield - Greater Stamina
	[20020] = "i:38862",  -- Enchant Boots - Greater Stamina
	[20023] = "i:38863",  -- Enchant Boots - Greater Agility
	[20024] = "i:38864",  -- Enchant Boots - Spirit
	[20025] = "i:38865",  -- Enchant Chest - Greater Stats
	[20026] = "i:38866",  -- Enchant Chest - Major Health
	[20028] = "i:38867",  -- Enchant Chest - Major Mana
	[23801] = "i:38881",  -- Enchant Bracer - Mana Regeneration
	[23802] = "i:38882",  -- Enchant Bracer - Healing Power
	[25072] = "i:38885",  -- Enchant Gloves - Threat
	[25073] = "i:38886",  -- Enchant Gloves - Shadow Power
	[25074] = "i:38887",  -- Enchant Gloves - Frost Power
	[25078] = "i:38888",  -- Enchant Gloves - Fire Power
	[25079] = "i:38889",  -- Enchant Gloves - Healing Power
	[25080] = "i:38890",  -- Enchant Gloves - Superior Agility
	[25083] = "i:38893",  -- Enchant Cloak - Stealth
	[25084] = "i:38894",  -- Enchant Cloak - Subtlety
	[44506] = "i:38960",  -- Enchant Gloves - Gatherer
	[63746] = "i:45628",  -- Enchant Boots - Lesser Accuracy
	[71692] = "i:50816",  -- Enchant Gloves - Angler
	[190954] = "i:128554",  -- Enchant Shoulder - Boon of the Scavenger
	[190988] = "i:128558",  -- Enchant Gloves - Legion Herbalism
	[190989] = "i:128559",  -- Enchant Gloves - Legion Mining
	[190990] = "i:128560",  -- Enchant Gloves - Legion Skinning
	[190991] = "i:128561",  -- Enchant Gloves - Legion Surveying
	[190869] = "i:128540",  -- Enchant Ring - Word of Versatility Rank 1
	[190995] = "i:128540",  -- Enchant Ring - Word of Versatility Rank 2
	[191012] = "i:128540",  -- Enchant Ring - Word of Versatility Rank 3
	[190866] = "i:128537",  -- Enchant Ring - Word of Critical Strike Rank 1
	[190992] = "i:128537",  -- Enchant Ring - Word of Critical Strike Rank 2
	[191009] = "i:128537",  -- Enchant Ring - Word of Critical Strike Rank 3
	[190875] = "i:128546",  -- Enchant Cloak - Word of Agility Rank 1
	[191001] = "i:128546",  -- Enchant Cloak - Word of Agility Rank 2
	[191018] = "i:128546",  -- Enchant Cloak - Word of Agility Rank 3
	[190867] = "i:128538",  -- Enchant Ring - Word of Haste Rank 1
	[190993] = "i:128538",  -- Enchant Ring - Word of Haste Rank 2
	[191010] = "i:128538",  -- Enchant Ring - Word of Haste Rank 3
	[190876] = "i:128547",  -- Enchant Cloak - Word of Intellect Rank 1
	[191002] = "i:128547",  -- Enchant Cloak - Word of Intellect Rank 2
	[191019] = "i:128547",  -- Enchant Cloak - Word of Intellect Rank 3
	[190868] = "i:128539",  -- Enchant Ring - Word of Mastery Rank 1
	[190994] = "i:128539",  -- Enchant Ring - Word of Mastery Rank 2
	[191011] = "i:128539",  -- Enchant Ring - Word of Mastery Rank 3
	[190874] = "i:128545",  -- Enchant Cloak - Word of Strength Rank 1
	[191000] = "i:128545",  -- Enchant Cloak - Word of Strength Rank 2
	[191017] = "i:128545",  -- Enchant Cloak - Word of Strength Rank 3
	[228408] = "i:141910",  -- Enchant Neck - Mark Of The Ancient Priestess Rank 1
	[228409] = "i:141910",  -- Enchant Neck - Mark Of The Ancient Priestess Rank 2
	[228410] = "i:141910",  -- Enchant Neck - Mark Of The Ancient Priestess Rank 3
	[190892] = "i:128551",  -- Enchant Neck - Mark Of The Claw Rank 1
	[191006] = "i:128551",  -- Enchant Neck - Mark Of The Claw Rank 2
	[191023] = "i:128551",  -- Enchant Neck - Mark Of The Claw Rank 3
	[190893] = "i:128552",  -- Enchant Neck - Mark Of The Distant Army Rank 1
	[191007] = "i:128552",  -- Enchant Neck - Mark Of The Distant Army Rank 2
	[191024] = "i:128552",  -- Enchant Neck - Mark Of The Distant Army Rank 3
	[228402] = "i:141908",  -- Enchant Neck - Mark Of The Heavy Hide Rank 1
	[228403] = "i:141908",  -- Enchant Neck - Mark Of The Heavy Hide Rank 2
	[228404] = "i:141908",  -- Enchant Neck - Mark Of The Heavy Hide Rank 3
	[190894] = "i:128553",  -- Enchant Neck - Mark of the Hidden Satyr Rank 1
	[191008] = "i:128553",  -- Enchant Neck - Mark of the Hidden Satyr Rank 2
	[191025] = "i:128553",  -- Enchant Neck - Mark of the Hidden Satyr Rank 3
	[228405] = "i:141909",  -- Enchant Neck - Mark of the Trained Soldier Rank 1
	[228406] = "i:141909",  -- Enchant Neck - Mark of the Trained Soldier Rank 2
	[228407] = "i:141909",  -- Enchant Neck - Mark of the Trained Soldier Rank 3
	[190870] = "i:128541",  -- Enchant Ring - Binding Of Critical Strike Rank 1
	[190996] = "i:128541",  -- Enchant Ring - Binding Of Critical Strike Rank 2
	[191013] = "i:128541",  -- Enchant Ring - Binding Of Critical Strike Rank 3
	[190871] = "i:128542",  -- Enchant Ring - Binding Of Haste Rank 1
	[190997] = "i:128542",  -- Enchant Ring - Binding Of Haste Rank 2
	[191014] = "i:128542",  -- Enchant Ring - Binding Of Haste Rank 3
	[190872] = "i:128543",  -- Enchant Ring - Binding Of Mastery Rank 1
	[190998] = "i:128543",  -- Enchant Ring - Binding Of Mastery Rank 2
	[191015] = "i:128543",  -- Enchant Ring - Binding Of Mastery Rank 3
	[190873] = "i:128544",  -- Enchant Ring - Binding Of Versatility Rank 1
	[190999] = "i:128544",  -- Enchant Ring - Binding Of Versatility Rank 2
	[191016] = "i:128544",  -- Enchant Ring - Binding Of Versatility Rank 3
	[190877] = "i:128548",  -- Enchant Cloak - Binding Of Strength Rank 1
	[191003] = "i:128548",  -- Enchant Cloak - Binding Of Strength Rank 2
	[191020] = "i:128548",  -- Enchant Cloak - Binding Of Strength Rank 3
	[190878] = "i:128549",  -- Enchant Cloak - Binding Of Agility Rank 1
	[191004] = "i:128549",  -- Enchant Cloak - Binding Of Agility Rank 2
	[191021] = "i:128549",  -- Enchant Cloak - Binding Of Agility Rank 3
	[190879] = "i:128550",  -- Enchant Cloak - Binding Of Intellect Rank 1
	[191005] = "i:128550",  -- Enchant Cloak - Binding Of Intellect Rank 2
	[191022] = "i:128550",  -- Enchant Cloak - Binding Of Intellect Rank 3
}

-- The following function can be used (/run Skillet:CountEnchants()) to check for missing items
-- in either Skillet's or TradeSkillMaster's table of enchant recipe IDs to enchant (scroll) item IDs
Skillet.missing_enchantingItemIDs = {}
Skillet.missing_scrollData = {}
function Skillet:CountEnchants()
	local i,j = 0,0
	for rid,eid in pairs(Skillet.scrollData) do
		i = i + 1
		if not Skillet.enchantingItemIDs[rid] then
			table.insert(Skillet.missing_enchantingItemIDs, rid)
		end
	end
	for rid,eid in pairs(Skillet.enchantingItemIDs) do
		j = j + 1
		if not Skillet.scrollData[rid] then
			table.insert(Skillet.missing_scrollData, rid)
		end
	end
	DA.CHAT("scrollData count= "..tostring(i)..", missing= "..DA.DUMP1(Skillet.missing_scrollData))
	DA.CHAT("enchantingItemIDs count= "..tostring(j)..", missing= "..DA.DUMP1(Skillet.missing_enchantingItemIDs))
end
--]]

--[[
-- The following function can be used (/run Skillet:DumpRecipeInfo()) to get Blizzard's original recipeInfo
-- Note: The trade skill frame needs to be open to the correct set of recipes for this to work.
function Skillet:DumpRecipeInfo()
	local recipeInfoDump = {102698, 102699, 201683, 201684, 201685} -- two from First-aid, three from Cooking (unlearned in 7.0.3)
	if not Skillet.db.global.recipeInfoDump then
		Skillet.db.global.recipeInfoDump = {}
	end
	for i=1,#recipeInfoDump,1 do
		local id = recipeInfoDump[i]
		local info = C_TradeSkillUI.GetRecipeInfo(id)
		if info then
			Skillet.db.global.recipeInfoDump[id] = info
		end
	end
end
]]--

--[[ == Local Tables == ]]--

-- a table of tradeskills by id
local TradeSkillList = {
	2259,		-- alchemy
	2018,		-- blacksmithing
	7411,		-- enchanting
	4036,		-- engineering
	45357,		-- inscription
	25229,		-- jewelcrafting
	2108,		-- leatherworking
	2575,		-- mining
	2656,		-- mining skills, smelting (from mining, 2575)
	3908,		-- tailoring
	2550,		-- cooking
	3273,		-- first aid
--	194174,		-- skinning skills
--	193290,		-- herbalism skills
--	53428,		-- runeforging
}

-- Items in this list are ignored because they can cause infinite loops.
local TradeSkillIgnoredMats	 = {
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
	[45765] = 1 , -- Void Shatter
	[42615] = 1 , -- small prismatic shard
	[42613] = 1 , -- nexus transformation
	[28022] = 1 , -- large prismatic shard
	[118239] = 1 , -- sha shatter
	[118238] = 1 , -- ethereal shard shatter
	[118237] = 1 , -- mysterious diffusion
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
}
Skillet.TradeSkillIgnoredMats = TradeSkillIgnoredMats

local DifficultyText = {
	x = "unknown",
	o = "optimal",
	m = "medium",
	e = "easy",
	t = "trivial",
	u = "unavailable",
}
local DifficultyChar = {
	unknown = "x",
	optimal = "o",
	medium = "m",
	easy = "e",
	trivial = "t",
	unavailable = "u", 
}
local skill_style_type = {
	["unknown"]			= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]			= { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]			= { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",	cstring = "|cffffff00"},
	["easy"]			= { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",	cstring = "|cff40c000"},
	["trivial"]			= { r = 0.60, g = 0.60, b = 0.60, level = 1, alttext="",	cstring = "|cff909090"},
	["header"]			= { r = 1.00, g = 0.82, b = 0,	  level = 0, alttext="",	cstring = "|cffffc800"},
	["unavailable"]		= { r = 0.3, g = 0.3, b = 0.3,	  level = 6, alttext="",	cstring = "|cff606060"},
}

local topink = 129032				-- Roseate Pigmentd
local specialVendorItems = {
	[37101] = {1, topink},			--Ivory Ink
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
	[113111] = {1, topink},			--Warbinder's Inkms

	[43127] = {10, topink},			--Snowfall Ink
	[61981] = {10, topink},			--Inferno Ink
	[79255] = {10, topink},			--Starlight Ink
}

function Skillet:GetTradeSkillInfo(index)
	--DA.PROFILE("Skillet:GetTradeSkillInfo("..tostring(index)..")")
-- index is now a recipeID
-- GetTradeSkillInfo returned:
-- skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps, indentLevel, showProgressBar, currentRank, maxRank, startingRank
	if index then
		local info = C_TradeSkillUI.GetRecipeInfo(index)
		if info then
			local tradeSkillID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier = C_TradeSkillUI.GetTradeSkillLineForRecipe(index)
			return info.name, info.difficulty, info.numAvailable, false, info.alternateVerb, info.numSkillUps, info.numIndents, false, skillLineRank, skillLineMaxRank, nil
		end
	end
end

local lastAutoTarget = {}
function Skillet:GetAutoTargetItem(addSpellID)
	--DA.DEBUG(0,"GetAutoTargetItem("..tostring(addSpellID)..")")
	if Skillet.TradeSkillAutoTarget[addSpellID] then
		local itemID = lastAutoTarget[addSpellID]
		--DA.DEBUG(0,"itemID= "..tostring(itemID))
		if itemID then 
			local limit = Skillet.TradeSkillAutoTarget[addSpellID][itemID]
			local count = GetItemCount(itemID)
			if count >= limit then
				return itemID
			end
		end
		for itemID,limit in pairs(Skillet.TradeSkillAutoTarget[addSpellID]) do
			local count = GetItemCount(itemID)
			--DA.DEBUG(0,"itemID= "..tostring(itemID)..", limit= "..tostring(limit)..", count= "..tostring(count))
			if count >= limit then
				lastAutoTarget[addSpellID] = itemID
				return itemID
			end
		end
		lastAutoTarget[addSpellID] = nil
	end
end

function Skillet:GetAutoTargetMacro(addSpellID)
	--DA.DEBUG(0,"GetAutoTargetMacro("..tostring(addSpellID)..")")
	local itemID = Skillet:GetAutoTargetItem(addSpellID)
	if itemID then
		return "/cast "..(GetSpellInfo(addSpellID) or "").."\n/use "..(GetItemInfo(itemID) or "")
	else
		return "/cast "..(GetSpellInfo(addSpellID) or "")
	end
end

-- adds an recipe source for an itemID (recipeID produces itemID)
function Skillet:ItemDataAddRecipeSource(itemID,recipeID)
	if not itemID or not recipeID then return end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeSource[itemID] then
		self.db.global.itemRecipeSource[itemID] = {}
	end
	self.db.global.itemRecipeSource[itemID][recipeID] = true
end

-- adds a recipe usage for an itemID (recipeID uses itemID as a reagent)
function Skillet:ItemDataAddUsedInRecipe(itemID,recipeID)
	if not itemID or not recipeID or itemID == 0 then return end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
	if not self.db.global.itemRecipeUsedIn[itemID] then
		self.db.global.itemRecipeUsedIn[itemID] = {}
	end
	self.db.global.itemRecipeUsedIn[itemID][recipeID] = true
end

-- goes thru the stored recipe list and collects reagent and item information as well as skill lookups
function Skillet:CollectRecipeInformation()
	for recipeID, recipeString in pairs(self.db.global.recipeDB) do
		local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
		local itemID, numMade = 0, 1
		local slot = nil
		if itemString ~= "0" then
			local a, b = string.split(":",itemString)
			if a ~= "0" then
				itemID, numMade = a,b
			else
				itemID = 0
				numMade = 1
				slot = tonumber(b)
			end
			if not numMade then
				numMade = 1
			end
		end
		itemID = tonumber(itemID)
		if itemID ~= 0 then
			self:ItemDataAddRecipeSource(itemID, recipeID)
		end
		if reagentString ~= "-" then
			local reagentList = { string.split(":",reagentString) }
			local numReagents = #reagentList / 2
			for i=1,numReagents do
				local reagentID = tonumber(reagentList[1 + (i-1)*2])
				self:ItemDataAddUsedInRecipe(reagentID, recipeID)
			end
		end
	end
	for player,tradeList in pairs(self.db.realm.skillDB) do
		self.data.skillIndexLookup[player] = {}
		for trade,skillList in pairs(tradeList) do
			for i=1,#skillList do
				local skillString = self.db.realm.skillDB[player][trade][i]
				if skillString then
					local skillData = string.split(" ",skillString)
					if skillData ~= "header" or skillData ~= "subheader" then
						local recipeID = string.sub(skillData,2)
						recipeID = tonumber(recipeID) or 0
						self.data.skillIndexLookup[player][recipeID] = i
					end
				end
			end
		end
	end
end

-- Checks to see if the current trade is one that we support.
-- Control key says we do (even if we don't, debugging)
-- Shift key says we don't support it (even if we do)
function Skillet:IsSupportedTradeskill(tradeID)
	if tradeID and IsControlKeyDown() then
		return true
	end
	if IsShiftKeyDown() or not tradeID or self.BlizzardSkillList[tradeID] then
		return false
	end
	local ranks = self:GetSkillRanks(self.currentPlayer, tradeID)
	if not ranks then
		return false
	end
	return true
end

-- Checks to see if this trade follower can not use Skillet frame.
function Skillet:IsNotSupportedFollower(tradeID)
	--DA.DEBUG(0,"IsNotSupportedFollower("..tostring(tradeID)..")")
	Skillet.wasNPCCrafting = false
	if C_TradeSkillUI.IsNPCCrafting() then
		local guid = UnitGUID("target")
		local gtype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
		if guid then
			gtype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",guid);
		end
		DA.DEBUG(0,"IsNPCCrafting, gtype="..tostring(gtype)..", npc_id="..tostring(npc_id))
		if IsShiftKeyDown() then
			return true -- Use Blizzard frame
		end
		if IsControlKeyDown() then
			DA.DEBUG(0,"npc_id="..tostring(npc_id))
			Skillet.wasNPCCrafting = true
			return false -- Use Skillet frame (mostly for debugging)
		end
		if not tradeID then
			return true -- Unknown tradeskill, play it safe and use Blizzard frame
		end
		if Skillet.db.profile.use_blizzard_for_followers then
			return true -- Option makes this easy, use Blizzard frame
		end
		if Skillet.FollowerSkillList[tradeID] then
			return true -- Any NPC for this tradeskill uses Blizzard Frame
		end
		if gtype and gtype == "Creature" and Skillet.FollowerNPC[npc_id] then
			return true -- This specific NPC crafts things Skillet can't process, use Blizzard frame
		end
		Skillet.wasNPCCrafting = true
	end
	return false -- Use Skillet frame
end

function Skillet:VendorItemAvailable(itemID)
	if specialVendorItems[itemID] then
		local divider = specialVendorItems[itemID][1]
		local currency = specialVendorItems[itemID][2]
		local reagentAvailability = self:GetInventory(self.currentPlayer, currency)
		local reagentAvailableAlts = 0
		for alt in pairs(self.db.realm.inventoryData) do
			if alt ~= self.currentPlayer then
				local altBoth = self:GetInventory(alt, currency)
				reagentAvailableAlts = reagentAvailableAlts + (altBoth or 0)
			end
		end
		return math.floor(reagentAvailability / divider), math.floor(reagentAvailableAlts / divider)
	else
		return 100000, 100000
	end
end

-- queries for vendor info for a particular itemID
function Skillet:VendorSellsReagent(itemID)
-- Check our local data first
	if self.db.global.MissingVendorItems[itemID] or specialVendorItems[itemID] then
		return true
	end
-- Check the LibPeriodicTable data next
	if PT then
		if itemID~=0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
	return false
end

-- resets the blizzard tradeskill search filters just to make sure no other addon has monkeyed with them
function Skillet:ResetTradeSkillFilter()
	--DA.PROFILE("Skillet:ResetTradeSkillFilter()")
	C_TradeSkillUI.ClearInventorySlotFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()
	C_TradeSkillUI.ClearRecipeSourceTypeFilter()
	C_TradeSkillUI.SetRecipeItemNameFilter(nil)
	C_TradeSkillUI.SetRecipeItemLevelFilter(0, 0)
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(false)
	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(false)
end

function Skillet:SetTradeSkillLearned()
    Skillet:SetGroupSelection(nil)
	C_TradeSkillUI.SetOnlyShowLearnedRecipes(true);
	C_TradeSkillUI.SetOnlyShowUnlearnedRecipes(false);
	Skillet.unlearnedRecipes = false
	Skillet.selectedSkill = nil
	Skillet:NewFilterDropdown_OnShow()
end

function Skillet:SetTradeSkillUnlearned()
	Skillet:SetGroupSelection(nil)
	C_TradeSkillUI.SetOnlyShowLearnedRecipes(false);
	C_TradeSkillUI.SetOnlyShowUnlearnedRecipes(true);
	Skillet.unlearnedRecipes = true
	Skillet.selectedSkill = nil
	Skillet:NewFilterDropdown_OnShow()
end

function Skillet:ExpandTradeSkillSubClass(i)
	--DA.DEBUG(0,"Skillet:ExpandTradeSkillSubClass "..tostring(i))
end

function Skillet:GetRecipeName(id)
	if not id then return "unknown" end
	local name = GetSpellInfo(id)
	--DA.DEBUG(0,"name "..(id or "nil").." "..(name or "nil"))
	if name then 
		return name, id 
	end
end

function Skillet:GetRecipe(id)
	--DA.DEBUG(0,"Skillet:GetRecipe("..tostring(id)..")")
	if id and id ~= 0 then 
		if Skillet.data.recipeList[id] then
			return Skillet.data.recipeList[id]
		end
		if Skillet.db.global.recipeDB[id] then
			local recipeString = Skillet.db.global.recipeDB[id]
			--DA.DEBUG(0,"recipeString= "..tostring(recipeString))
			local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
			local itemID, numMade = 0, 1
			local slot = nil
			if itemString then
				if itemString ~= "0" then
					local a, b = string.split(":",itemString)
					--DA.DEBUG(0,"itemString a= "..tostring(a)..", b= "..tostring(b))
					if a ~= "0" then
						itemID, numMade = a,b
					else
						itemID = 0
						numMade = 1
						slot = tonumber(b)
					end
					if not numMade then
						numMade = 1
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			Skillet.data.recipeList[id] = {}
			Skillet.data.recipeList[id].spellID = tonumber(id)
			Skillet.data.recipeList[id].name = GetSpellInfo(tonumber(id))
			Skillet.data.recipeList[id].tradeID = tonumber(tradeID)
			Skillet.data.recipeList[id].itemID = tonumber(itemID)
			Skillet.data.recipeList[id].numMade = tonumber(numMade)
			Skillet.data.recipeList[id].slot = slot
			Skillet.data.recipeList[id].reagentData = {}
			if reagentString then
				if reagentString ~= "-" then
					local reagentList = { string.split(":",reagentString) }
					local numReagents = #reagentList / 2
					for i=1,numReagents do
						Skillet.data.recipeList[id].reagentData[i] = {}
						Skillet.data.recipeList[id].reagentData[i].reagentID = tonumber(reagentList[1 + (i-1)*2])
						Skillet.data.recipeList[id].reagentData[i].numNeeded = tonumber(reagentList[2 + (i-1)*2])
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			if toolString then
				if toolString ~= "-" then
					Skillet.data.recipeList[id].tools = {}
					local toolList = { string.split(":",toolString) }
					for i=1,#toolList do
						Skillet.data.recipeList[id].tools[i] = string.gsub(toolList[i],"_"," ")
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			return Skillet.data.recipeList[id]
		end
	end
	return Skillet.unknownRecipe
end

function Skillet:GetNumSkills(player, trade)
	--DA.PROFILE("Skillet:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	local r
	if not Skillet.db.realm.skillDB[player] then
		r = 0
	elseif not Skillet.db.realm.skillDB[player][trade] then
		r = 0
	else
		r = #Skillet.db.realm.skillDB[player][trade]
	end
	--DA.DEBUG(2,"r= "..tostring(r))
	return r
end

function Skillet:GetSkillRanks(player, trade)
	--DA.PROFILE("Skillet:GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	if player and trade then
		if Skillet.db.realm.tradeSkills[player] then
			return Skillet.db.realm.tradeSkills[player][trade]
		end
	end
end

function Skillet:GetSkill(player,trade,index)
	--DA.PROFILE("Skillet:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	if player and trade and index then
		if not Skillet.data.skillList[player] then
			Skillet.data.skillList[player] = {}
		end
		if not Skillet.data.skillList[player][trade] then
			Skillet.data.skillList[player][trade] = {}
		end
		if not Skillet.data.skillList[player][trade][index] and Skillet.db.realm.skillDB[player][trade][index] then
			local skillString = Skillet.db.realm.skillDB[player][trade][index]
			if skillString then
				local skill = {}
				local data = { string.split(" ",skillString) }
				if data[1] == "header" or data[1] == "subheader" then
					skill.id = 0
				else
					local difficulty = string.sub(data[1],1,1)
					local recipeID = string.sub(data[1],2)
					skill.id = tonumber(recipeID)
					skill.difficulty = DifficultyText[difficulty]
					skill.color = skill_style_type[DifficultyText[difficulty]]
					skill.tools = nil
					recipeID = tonumber(recipeID)
					for i=2,#data do
						local subData = { string.split("=",data[i]) }
						if subData[1] == "cd" then
							skill.cooldown = tonumber(subData[2])
						elseif subData[1] == "t" then
							local recipe = Skillet:GetRecipe(recipeID)
							skill.tools = {}
							for j=1,string.len(subData[2]) do
								local missingTool = tonumber(string.sub(subData[2],j,j))
								skill.tools[missingTool] = true
							end
						end
					end
				end
				Skillet.data.skillList[player][trade][index] = skill
			end
		end
		return Skillet.data.skillList[player][trade][index]
	end
	return self.unknownRecipe
end

-- collects generic tradeskill data (id to name and name to id)
function Skillet:CollectTradeSkillData()
	--DA.DEBUG(0,"CollectTradeSkillData()")
	self.tradeSkillIDsByName = {}
	self.tradeSkillNamesByID = {}
	for i=1,#TradeSkillList,1 do
		local id = TradeSkillList[i]
		local name, _, icon = GetSpellInfo(id)
		self.tradeSkillIDsByName[name] = id
		self.tradeSkillNamesByID[id] = name
	end
	self.tradeSkillList = TradeSkillList
end

-- this routine collects the basic data (which tradeskills a player has)
-- clean = true means wipe the old data
function Skillet:ScanPlayerTradeSkills(player)
	DA.DEBUG(0,"Skillet:ScanPlayerTradeSkills("..tostring(player)..")")
	if player == (UnitName("player")) then -- only for active player
		local skillRanksData = Skillet.db.realm.tradeSkills[player]
		for i=1,#TradeSkillList,1 do
			local id = TradeSkillList[i]
			local name = GetSpellInfo(id)					-- always returns data
			local _, rankName, icon = GetSpellInfo(name)	-- only returns data if you have this spell in your spellbook
			if rankName then
				if id == 2656 then id = 2575 end -- Ye old Smelting vs. Mining issue
				if not skillRanksData[id] then
					DA.DEBUG(0,"adding tradeskill data for "..tostring(name).." ("..tostring(id)..")")
					skillRanksData[id] = {}
					skillRanksData[id].rank = 0
					skillRanksData[id].maxRank = 0
					skillRanksData[id].name = name
				end
			end
		end
		if not Skillet.db.realm.faction then
			Skillet.db.realm.faction = {}
		end
		Skillet.db.realm.faction[player] = UnitFactionGroup("player")
	end
end

-- takes a profession and a skill index and returns the recipe
function Skillet:GetRecipeDataByTradeIndex(tradeID, index)
	if not tradeID or not index then
		return self.unknownRecipe
	end
	local skill = self:GetSkill(self.currentPlayer, tradeID, index)
	if skill then
		local recipeID = skill.id
		if recipeID then
			local recipeData = self:GetRecipe(recipeID)
			return recipeData, recipeData.spellID, recipeData.ItemID
		end
	end
	return self.unknownRecipe
end

function Skillet:CalculateCraftableCounts(playerOverride)
	--DA.DEBUG(0,"CalculateCraftableCounts("..tostring(playerOverride)..")")
	local player = playerOverride or self.currentPlayer
	--DA.DEBUG(0,tostring(player).." "..tostring(self.currentTrade))
	self.visited = {}
	local n = self:GetNumSkills(player, self.currentTrade)
	if n then
		for i=1,n do
			local skill = self:GetSkill(player, self.currentTrade, i)
			if skill then -- skip headers
				skill.numCraftable, skill.numRecursive, skill.numCraftableVendor, skill.numCraftableAlts = self:InventorySkillIterations(self.currentTrade, i, player)
				--DA.DEBUG(2,"name= "..tostring(skill.name)..", numCraftable= "..tostring(skill.numCraftable)..", numRecursive= "..tostring(skill.numRecursive)..", numCraftableVendor= "..tostring(skill.numCraftableVendor)..", numCraftableAlts= "..tostring(skill.numCraftableAlts))
			end
		end
	end
end

function Skillet:RescanTrade()
	--DA.PROFILE("Skillet:RescanTrade()")
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
	Skillet.scanInProgress = true
	if not Skillet.data.skillList[player] then
		Skillet.data.skillList[player] = {}
	end
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID]={}
	end
	if not Skillet.data.Filtered then
		Skillet.data.Filtered = {}
	end
	if not Skillet.data.Filtered[tradeID] then
		Skillet.data.Filtered[tradeID] = {}
	end
	if not Skillet.db.realm.skillDB[player] then
		Skillet.db.realm.skillDB[player] = {}
	end
	if not Skillet.db.realm.skillDB[player][tradeID] then
		Skillet.db.realm.skillDB[player][tradeID] = {}
	end
	if not Skillet.data.recipeInfo[tradeID] then
		Skillet.data.recipeInfo[tradeID] = {}
	end
	if not Skillet.db.global.Categories[tradeID] then
		Skillet.db.global.Categories[tradeID] = {}
	end
	Skillet.dataScanned = self:ScanTrade()
	Skillet.scanInProgress = false
	return Skillet.dataScanned
end

function Skillet:IsFavorite(recipeID)
	local info = self.data.recipeInfo
	return info and info[self.currentTrade] and info[self.currentTrade][recipeID] and info[self.currentTrade][recipeID].favorite
end

function Skillet:ToggleFavorite(recipeID)
	local recipeInfo = self.data.recipeInfo[self.currentTrade][recipeID]
	recipeInfo.favorite = not recipeInfo.favorite 
	C_TradeSkillUI.SetRecipeFavorite(recipeID, recipeInfo.favorite);
end

function Skillet:IsUpgradeHidden(recipeID) 
	local recipeInfo = Skillet.data.recipeInfo[Skillet.currentTrade][recipeID]
	--filter out upgrades
	if recipeInfo and recipeInfo.upgradeable then		
		if Skillet.unlearnedRecipes then
			-- for unlearned, show next upgrade to learn
			if recipeInfo.recipeUpgrade ~= recipeInfo.learnedUpgrade + 1 then
				return true
			end
	  	else
			-- for learned, show only highest upgrade learned
			if recipeInfo.recipeUpgrade ~= recipeInfo.learnedUpgrade then
				return true
			end
		end
	end
	return false
end	


function Skillet:SetUpgradeLevels(recipeInfo) 
	if recipeInfo.previousRecipeID or recipeInfo.nextRecipeID then
		local n,m = 1,1
		local firstRecipeInfo = recipeInfo
		if recipeInfo.previousRecipeID then
			-- Start by going backwards from this node until we find the first in the line
			local previousRecipeID = recipeInfo.previousRecipeID
			while previousRecipeID do
				local previousRecipeInfo = C_TradeSkillUI.GetRecipeInfo(previousRecipeID)
				firstRecipeInfo = previousRecipeInfo
				previousRecipeID = previousRecipeInfo.previousRecipeID
				n = n + 1
				m = m + 1
			end
		end
		if recipeInfo.nextRecipeID then
			-- Now move forward from this node until the end
			local nextRecipeID = recipeInfo.nextRecipeID
			while nextRecipeID do
				local nextRecipeInfo = C_TradeSkillUI.GetRecipeInfo(nextRecipeID)
				nextRecipeID = nextRecipeInfo.nextRecipeID
				m = m + 1
			end
		end
		local l = 0
		while firstRecipeInfo and firstRecipeInfo.learned do
			l = l + 1
			if firstRecipeInfo.nextRecipeID then
				firstRecipeInfo = C_TradeSkillUI.GetRecipeInfo(firstRecipeInfo.nextRecipeID)
			else
				firstRecipeInfo = nil
			end
		end
		recipeInfo.upgradeable = true
		recipeInfo.maxUpgrade = m
		recipeInfo.recipeUpgrade = n
		recipeInfo.learnedUpgrade = l
	end
	return recipeInfo
end

function Skillet:ScanTrade()
	--DA.PROFILE("Skillet:ScanTrade()")
	local link = C_TradeSkillUI.GetTradeSkillListLink()
	local _, profession, rank, maxRank = C_TradeSkillUI.GetTradeSkillLine()
	DA.DEBUG(0,"ScanTrade: profession= "..tostring(profession)..", rank= "..tostring(rank)..", maxRank= "..tostring(maxRank))
	if link then
		--DA.DEBUG(0,"ScanTrade: "..tostring(profession).." link="..link.." "..DA.PLINK(link))
	else
		DA.DEBUG(0,"ScanTrade: "..tostring(profession).." not linkable")
	end
	local player = Skillet.currentPlayer
	local tradeID = Skillet.tradeSkillIDsByName[profession]
	if not player or not tradeID then
		DA.DEBUG(0,"ScanTrade: abort! player= "..tostring(player)..", "..tostring(tradeID))
		Skillet.scanInProgress = false
		return false
	end
	Skillet.currentTrade = tradeID
	if not Skillet.data.skillIndexLookup[player] then
		Skillet.data.skillIndexLookup[player] = {}
	end
	if not Skillet.db.realm.tradeSkills[player] then
		Skillet.db.realm.tradeSkills[player] = {}
	end
	Skillet.db.realm.tradeSkills[player][tradeID] = {}
	Skillet.db.realm.tradeSkills[player][tradeID].link = link
	Skillet.db.realm.tradeSkills[player][tradeID].rank = rank
	Skillet.db.realm.tradeSkills[player][tradeID].maxRank = maxRank
	Skillet.db.realm.tradeSkills[player][tradeID].name = profession

	if #Skillet.db.global.Categories[tradeID] == 0 then
		local categories = { C_TradeSkillUI.GetCategories() }
		for i, categoryID in ipairs(categories) do
			Skillet.db.global.Categories[tradeID][categoryID] = C_TradeSkillUI.GetCategoryInfo(categoryID)
			local subCategories = { C_TradeSkillUI.GetSubCategories(categoryID) }
			for j, subCategory in ipairs(subCategories) do
				Skillet.db.global.Categories[tradeID][subCategory] = C_TradeSkillUI.GetCategoryInfo(subCategory)
				local subsubCategories = { C_TradeSkillUI.GetSubCategories(subCategory) }
				for k, subsubCategory in ipairs(subsubCategories) do
					Skillet.db.global.Categories[tradeID][subsubCategory] = C_TradeSkillUI.GetCategoryInfo(subsubCategory)
					local subsubsubCategories = { C_TradeSkillUI.GetSubCategories(subsubCategory) }
					if #subsubsubCategories > 0 then
						DA.DEBUG(0,"ScanTrade: too many subCategory levels")
					end
				end
			end
		end
	end

	self:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
	Skillet.hasProgressBar = {} -- table of (sub)headers in this list with progress bars (used in MainFrame.lua)
	Skillet.data.Filtered[tradeID] = C_TradeSkillUI.GetFilteredRecipeIDs()
	local numSkills = #C_TradeSkillUI.GetFilteredRecipeIDs()
	--DA.DEBUG(0,"ScanTrade: Expanding, "..tostring(profession)..":"..tostring(tradeID).." "..tostring(numSkills).." recipes")

-- Build a list of categories (headers) used for this set of filtered recipes
	local headerUsed = {}
	for i = 1, numSkills do
		local id = Skillet.data.Filtered[tradeID][i]
		local info = C_TradeSkillUI.GetRecipeInfo(id)
		headerUsed[info.categoryID] = false
		info = self:SetUpgradeLevels(info) 
		Skillet.data.recipeInfo[tradeID][id] = info
	end

	local skillDB = Skillet.db.realm.skillDB[player][tradeID]
	local skillData = Skillet.data.skillList[player][tradeID]
	local recipeDB = Skillet.db.global.recipeDB
	if not skillData then
		DA.DEBUG(0,"ScanTrade: no skillData")
		return false
	end
	local currentGroup = nil
	local mainGroup = Skillet:RecipeGroupNew(player,tradeID,"Blizzard")
	mainGroup.locked = true
	mainGroup.autoGroup = true
	Skillet:RecipeGroupClearEntries(mainGroup)
	local groupList = {}
	local numHeaders = 0
	local parentGroup
	--DA.DEBUG(0,"ScanTrade: Scanning, "..tostring(profession)..":"..tostring(tradeID).." "..tostring(numSkills).." recipes")
	local i = 1
	for j = 1, numSkills, 1 do
		local recipeID = Skillet.data.Filtered[tradeID][j]
		local recipeInfo = Skillet.data.recipeInfo[tradeID][recipeID]
		local skillName, skillType, _, isExpanded, _, _, _, _, _, _, _, displayAsUnavailable, _ = Skillet:GetTradeSkillInfo(recipeID);
		if displayAsUnavailable then skillType = "unavailable" end
		if not headerUsed[recipeInfo.categoryID] then
-- This category (header) hasn't been seen yet. Stack it (and its unseen parents)
			headerUsed[recipeInfo.categoryID] = true
			local headerType = Skillet.db.global.Categories[tradeID][recipeInfo.categoryID].type
			local headerName = Skillet.db.global.Categories[tradeID][recipeInfo.categoryID].name
			local category = recipeInfo.categoryID
			local numCat = 1
			local catStack = {}
			catStack[numCat] = category
			while headerType == "subheader" do
				category = Skillet.db.global.Categories[tradeID][category].parentCategoryID
				if not headerUsed[category] then
					headerUsed[category] = true
					numCat = numCat + 1
					catStack[numCat] = category
				end
				headerType = Skillet.db.global.Categories[tradeID][category].type
			end
			while numCat > 0 do
-- We have a stack of headers. Output them to the skillDB.
				category = catStack[numCat]
				headerType = Skillet.db.global.Categories[tradeID][category].type
				headerName = Skillet.db.global.Categories[tradeID][category].name
				--DA.DEBUG(2,"ScanTrade: headerType= "..tostring(headerType)..", headerName= "..tostring(headerName))
				local groupName
				if groupList[headerName] then
					groupList[headerName] = groupList[headerName]+1
					groupName = headerName.." "..groupList[headerName]
				else
					groupList[headerName] = 1
					groupName = headerName
				end
				if Skillet.db.global.Categories[tradeID][category].hasProgressBar then
					skillDB[i] = "header "..headerName..":"..tostring(category)
					Skillet.hasProgressBar[headerName] = category
				else
					skillDB[i] = "header "..headerName
				end
				skillData[i] = nil
				currentGroup = Skillet:RecipeGroupNew(player, tradeID, "Blizzard", groupName)
				currentGroup.autoGroup = true
				if headerType == "header" then
					parentGroup = currentGroup
					Skillet:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
				else
					Skillet:RecipeGroupAddSubGroup(parentGroup, currentGroup, i)
				end
				numHeaders = numHeaders + 1
				numCat = numCat - 1
				i = i + 1
			end
		end
		if currentGroup then
			Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, i)
		else
			Skillet:RecipeGroupAddRecipe(mainGroup, recipeID, i)
		end
		-- break recipes into lists by profession for ease of sorting
		skillData[i] = {}
		skillData[i].name = skillName
		skillData[i].id = recipeID
		skillData[i].difficulty = skillType
		skillData[i].color = skill_style_type[skillType]
		local skillDBString = DifficultyChar[skillType]..tostring(recipeID)

		recipeInfo.sourceText = C_TradeSkillUI.GetRecipeSourceText(recipeID); -- capture for later use

		local tools = { C_TradeSkillUI.GetRecipeTools(recipeID) }
		recipeInfo.tools = tools	-- save a copy for our records
		skillData[i].tools = {}
		local slot = 1
		for t=2,#tools,2 do
			skillData[i].tools[slot] = (tools[t] or 0)
			slot = slot + 1
		end
		local numTools = #tools+1
		if numTools > 1 then
			local toolString = ""
			local toolsAbsent = false
			local slot = 1
			for t=2,numTools,2 do
				if not tools[t] then
					toolsAbsent = true
					toolString = toolString..slot
				end
				slot = slot + 1
			end
			if toolsAbsent then										-- only point out missing tools
				skillDBString = skillDBString.." t="..toolString
			end
		end
		skillDB[i] = skillDBString
		Skillet.data.skillIndexLookup[player][recipeID] = i

		--DA.DEBUG(2,"recipeID= "..tostring(recipeID))
		Skillet.data.recipeList[recipeID] = {}
		local recipe = Skillet.data.recipeList[recipeID]
		local itemString = "-"
		local reagentString = "-"
		local toolString = "-"
		local recipeString = "-"
		recipe.tradeID = tradeID
		recipe.spellID = recipeID
		recipe.name = skillName
		recipe.itemID = 0		-- Make sure this value exists
		recipe.numMade = 1		-- Make sure this value exists

		local itemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		--DA.DEBUG(2,"itemLink = "..DA.PLINK(itemLink))
		recipeInfo.itemLink = itemLink	-- save a copy for our records
		if itemLink then
			local itemID = Skillet:GetItemIDFromLink(itemLink)
			--DA.DEBUG(2,"itemID= "..tostring(itemID))
			if (not itemID or tonumber(itemID) == 0) then
				DA.DEBUG(0,"recipeID= "..tostring(recipeID)..", itemID= "..tostring(itemID))
				itemID = 0
			end
			if not recipeInfo.alternateVerb then
				local minMade,maxMade = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID)
				recipeInfo.minMade = minMade	-- save a copy for our records
				recipeInfo.maxMade = maxMade	-- save a copy for our records
				recipeInfo.itemID = itemID		-- save a copy for our records
				recipe.itemID = itemID
				recipe.numMade = (minMade + maxMade)/2
			elseif recipeInfo.alternateVerb == ENSCRIBE then -- use the itemID of the scroll created by using the enchant on vellum
				--DA.DEBUG(2,"alternateVerb= "..tostring(recipeInfo.alternateVerb))
				recipeInfo.numMade = 1		-- save a copy for our records
				if Skillet.scrollData[recipeID] then	-- note that this table is maintained by datamining
					local itemID = Skillet.scrollData[recipeID]
					recipeInfo.itemID = itemID		-- save a copy for our records
					recipe.itemID = itemID
				else
					recipeInfo.itemID = recipe.itemID		-- save a copy for our records
				end
			else
				DA.DEBUG(0,"alternateVerb= "..tostring(recipeInfo.alternateVerb))
				recipeInfo.numMade = 1		-- save a copy for our records
				recipeInfo.itemID = recipe.itemID		-- save a copy for our records
				DA.TABLE("recipeInfo["..tostring(recipeID).."]", recipeInfo)
			end
			if recipe.numMade > 1 then
				itemString = itemID..":"..recipe.numMade
			else
				itemString = tostring(itemID)
			end
			Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of this item
		else
			DA.DEBUG(0,"recipeID= "..tostring(recipeID).." has no itemLink")
		end

		local reagentData = {}
		for k = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID), 1 do
			local reagentName, _, numNeeded = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, k)
			local reagentID = 0
			if reagentName then
				local reagentLink = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID,k)
				if reagentLink then
					reagentID = Skillet:GetItemIDFromLink(reagentLink)
				else
					DA.DEBUG(0,"recipeID= "..tostring(recipeID)..", reagentName= "..tostring(reagentName).." has no reagentLink")
				end
			else
				--DA.DEBUG(0,"recipeID= "..tostring(recipeID).."("..tostring(k)..") reagentName missing")
			end
			reagentData[k] = {}
			reagentData[k].reagentID = reagentID
			reagentData[k].numNeeded = numNeeded
			if reagentString ~= "-" then
				reagentString = reagentString..":"..reagentID..":"..numNeeded
			else
				reagentString = reagentID..":"..numNeeded
			end
			Skillet:ItemDataAddUsedInRecipe(reagentID, recipeID)	-- add a cross reference for where a particular item is used
		end
		recipe.reagentData = reagentData
		recipeString = tradeID.." "..itemString.." "..reagentString

		if #tools >= 1 then
			recipe.tools = { tools[1] }
			toolString = string.gsub(tools[1]," ", "_")
			for t=3,#tools,2 do
				table.insert(recipe.tools, tools[t])
				toolString = toolString..":"..string.gsub(tools[t]," ", "_")
			end
		end
		recipeString = recipeString.." "..toolString

		recipeDB[recipeID] = recipeString
		--DA.DEBUG(2,"recipeDB["..tostring(recipeID).."]= "..tostring(recipeDB[recipeID]))
		i = i + 1
	end

	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	--DA.DEBUG(0,"ScanTrade: Complete, numSkills= "..tostring(numSkills)..", numHeaders= "..tostring(numHeaders))
	if numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	skillData.scanned = true
	return true
end
