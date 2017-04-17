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

--[[ == Global Tables for Debugging == ]]--

-- This file is not included in the normal Skillet build.
-- If included, it is used to verify some of the tables in the normal build.

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

