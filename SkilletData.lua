local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
--[[
Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>
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
]]
local PT = LibStub("LibPeriodicTable-3.1")
local L = Skillet.L

-- a table of tradeskills by id (lowest qualifying skill only)
local TradeSkillList = {
	2259,       -- alchemy
	2018,       -- blacksmithing
	7411,       -- enchanting
	4036,       -- engineering
	45357,      -- inscription
	25229,      -- jewelcrafting
	2108,       -- leatherworking
	-- 2575,    -- mining (or smelting?)
	2656,       -- smelting (from mining)
	3908,       -- tailoring
	2550,       -- cooking
	3273,       -- first aid
	-- 2842,    -- poisons
	53428,      -- runeforging
	-- 5149,    -- beast training (not supported, but I think I need the number)
}
Skillet.TradeSkillAdditionalAbilities = {
	[7411]  = {13262,"Disenchant"},     -- enchanting = disenchant
	[2550]  = {818,"Basic_Campfire"},   -- cooking = basic campfire
	[45357] = {51005,"Milling"},        -- inscription = milling
	[25229] = {31252,"Prospecting"},    -- jewelcrafting = prospecting
	[2018]  = {87216,"Thermal Anvil"},  -- blacksmithing = thermal anvil
}
Skillet.AutoButtonsList = {}
Skillet.TradeSkillAutoTarget = {
	[7411] =  {   -- Enchanting
		[38682] = 1, -- Enchanting Vellum
	},
	[31252] = {
		[2770]  = 5, --Copper Ore
		[2771]  = 5, --Tin Ore
		[2772]  = 5, --Iron Ore
		[3858]  = 5, --Mithril Ore
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
	[51005] = {   -- Milling
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
		[39969] = 5, -- Fire Seed
		[22789] = 5, -- Terocone
		[22786] = 5, -- Dreaming Glory
		[22787] = 5, -- Ragveil
		[22785] = 5, -- Felweed
		[22790] = 5, -- Ancient Lichen
		[22792] = 5, -- Nightmare Vine
		[22793] = 5, -- Mana Thistle
		[22791] = 5, -- Netherbloom
		[36901] = 5, -- Goldclover
		[36907] = 5, -- Talandra\'s Rose
		[37921] = 5, -- Deadnettle
		[36904] = 5, -- Tiger Lily
		[36905] = 5, -- Lichbloom
		[36906] = 5, -- Icethorn
		[36903] = 5, -- Adder\'s Tongue
		[39970] = 5, -- Fire Leaf
		[52983] = 5, -- Cinderbloom
		[52984] = 5, -- Stormvine
		[52985] = 5, -- Azshara\'s Veil
		[52986] = 5, -- Heartblossom
		[52987] = 5, -- Twilight Jasmine
		[52988] = 5, -- Whiptail
		[52989] = 5, -- Deathspore Pod
		[79011] = 5, -- Fool's Cap
		[79010] = 5, -- Snow Lily
		[72235] = 5, -- Silkweed
		[72234] = 5, -- Green Tea Leaf
		[72237] = 5, -- Rain Poppy
	}
}
local TradeSkillRecipeCounts = {
	[3908] = 438,
	[7411] = 306,
	[2108] = 540,
	[2550] = 186,
	[25229] = 570,
	[3273] = 36,
	[45357] = 450,
	[4036] = 324,
	[2656] = 0,			-- can't link [Smelting]
	[2018] = 522,
	[2259] = 264,
	[53428] = 0,		-- can't link [Runeforging]
}
local TradeSkillIgnoredMats  = {
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
}

Skillet.TradeSkillIgnoredMats = TradeSkillIgnoredMats
SkilletData = {}				-- skillet data scanner
SkilletLink = {}
local TradeSkillIDsByName = {}		-- filled in with ids and names for reverse matching (since the same name has multiple id's based on level)
local DifficultyText = {
	x = "unknown",
	o = "optimal",
	m = "medium",
	e = "easy",
	t = "trivial",
}
local DifficultyChar = {
	unknown = "x",
	optimal = "o",
	medium = "m",
	easy = "e",
	trivial = "t",
}
local skill_style_type = {
	["unknown"]			= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]	        = { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]          = { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",  cstring = "|cffffff00"},
	["easy"]            = { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",   cstring = "|cff40c000"},
	["trivial"]	        = { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext="",    cstring = "|cff808080"},
	["header"]          = { r = 1.00, g = 0.82, b = 0,    level = 0, alttext="",    cstring = "|cffffc800"},
}
local lastAutoTarget = {}
local SkilletDataScanTooltip = CreateFrame("GameTooltip", "SkilletDataScanTooltip", nil, "GameTooltipTemplate")
SkilletDataScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local function FixedGetTradeSkillReagentItemLink(i,j)
	local tooltip = SkilletDataScanTooltip
	tooltip:ClearLines()
	tooltip:SetTradeSkillItem(i,j)
	return select(2,tooltip:GetItem())
end

function Skillet:GetAutoTargetItem(tradeID)
	if Skillet.TradeSkillAutoTarget[tradeID] then
		local itemID = lastAutoTarget[tradeID]
		if itemID then
			local limit  = Skillet.TradeSkillAutoTarget[tradeID][itemID]
			local count = GetItemCount(itemID)
			if count >= limit then
				return itemID
			end
		end
		for itemID,limit in pairs(Skillet.TradeSkillAutoTarget[tradeID]) do
			local count = GetItemCount(itemID)
			if count >= limit then
				lastAutoTarget[tradeID] = itemID
				return itemID
			end
		end
		lastAutoTarget[tradeID] = nil
	end
end

function Skillet:GetAutoTargetMacro(additionalSpellId)
	local itemID = Skillet:GetAutoTargetItem(additionalSpellId)
	if itemID then
		return "/cast "..(GetSpellInfo(additionalSpellId) or "").."\n/use "..(GetItemInfo(itemID) or "")
	else
		return "/cast "..(GetSpellInfo(additionalSpellId) or "")
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
	if not itemID or not recipeID then return end
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
		if reagengString ~= "-" then
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
--				local skillData = self:GetSkill(player, trade, i)
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
function Skillet:IsSupportedTradeskill(tradeID)
	if not tradeID or tradeID == 5419 or tradeID == 53428 then
		return false				-- beast training, runeforging
	end
	if IsShiftKeyDown() then
		return false
	end
	return true
end

local missingVendorItems = {
	[30817] = true,				-- simple flour
	[4539] = true,				-- Goldenbark Apple
	[17035] = true,				-- Stranglethorn seed
	[17034] = true, 			-- Maple seed
	[52188] = true,             -- Jeweler's Setting
	[4399]  = true,             -- Wooden Stock
	[38682] = true,             -- Enchanting Vellum
	[3857]  = true,   			-- Coal
}
local specialVendorItems = {
	[37101] = {1, 61978}, 			--Ivory Ink
	[39469] = {1, 61978}, 			--Moonglow Ink
	[39774] = {1, 61978}, 			--Midnight Ink
	[43116] = {1, 61978}, 			--Lions Ink
	[43118] = {1, 61978}, 			--Jadefire Ink
	[43120] = {1, 61978}, 			--Celestial Ink
	[43122] = {1, 61978}, 			--Shimmering Ink
	[43124] = {1, 61978},  			--Ethereal Ink
	[43126] = {1, 61978},  			--Ink of the Sea
	[43127] = {10, 61978},  		--Snowfall Ink
	[61981] = {10, 61978},  		--Inferno Ink
}
local specialVendorItemsMoP	 = {
	[37101] = {1, 79254}, 			--Ivory Ink
	[39469] = {1, 79254}, 			--Moonglow Ink
	[39774] = {1, 79254}, 			--Midnight Ink
	[43116] = {1, 79254}, 			--Lions Ink
	[43118] = {1, 79254}, 			--Jadefire Ink
	[43120] = {1, 79254}, 			--Celestial Ink
	[43122] = {1, 79254}, 			--Shimmering Ink
	[43124] = {1, 79254},  			--Ethereal Ink
	[43126] = {1, 79254},  			--Ink of the Sea
	[43127] = {10, 79254},  		--Snowfall Ink
	[61981] = {10, 79254},  		--Inferno Ink
	[79255] = {10, 79254},  		--Starlight Ink
}
function Skillet:VendorItemAvailable(itemID)
	if Skillet.wowVersion>50000 then
		specialVendorItems = specialVendorItemsMoP
	end
	if specialVendorItems[itemID] then
		local divider = specialVendorItems[itemID][1]
		local currency = specialVendorItems[itemID][2]
		local reagentAvailability, _, reagentAvailabilityBank = self:GetInventory(self.currentPlayer, currency)
		local reagentAvailabilityAlts = 0
		for player in pairs(self.db.realm.inventoryData) do
			local _,_, altBank = self:GetInventory(player, currency)
			reagentAvailabilityAlts = reagentAvailabilityAlts + (altBank or 0)
		end
		return math.floor(reagentAvailability / divider), math.floor(reagentAvailabilityBank / divider), math.floor(reagentAvailabilityAlts / divider)
	else
		return 100000, 100000, 100000
	end
end

-- queries periodic table for vendor info for a particual itemID
function Skillet:VendorSellsReagent(itemID)
	if PT then
		if Skillet.wowVersion>50000 then
			specialVendorItems = specialVendorItemsMoP
		end
		if missingVendorItems[itemID] or specialVendorItems[itemID] then
			return true
		end
		if itemID~=0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
end

-- resets the blizzard tradeskill search filters just to make sure no other addon has monkeyed with them
function SkilletData:ResetTradeSkillFilter()
	if (Skillet.wowVersion>50000) then
		if not GetTradeSkillCategoryFilter(0) then
			SetTradeSkillCategoryFilter(0, 1, 1)
		end
	else
		if not GetTradeSkillSubClassFilter(0) then
			SetTradeSkillSubClassFilter(0, 1, 1)
		end
	end
	SetTradeSkillItemNameFilter("")
	SetTradeSkillItemLevelFilter(0,0)
end

function SkilletLink:ResetTradeSkillFilter()
	if (Skillet.wowVersion>50000) then
		if not GetTradeSkillCategoryFilter(0) then
			SetTradeSkillCategoryFilter(0, 1, 1)
		end
	else
		if not GetTradeSkillSubClassFilter(0) then
			SetTradeSkillSubClassFilter(0, 1, 1)
		end
	end
	SetTradeSkillItemNameFilter("")
	SetTradeSkillItemLevelFilter(0,0)
end

function SkilletData:GetRecipeName(id)
	if not id then return "unknown" end
	local name = GetSpellInfo(id)
	--DA.DEBUG(0,"name "..(id or "nil").." "..(name or "nil"))
	if name then return name, id end
	return tostring(id), id
end

function Skillet:GetRecipeName(id)
	if not id then return "unknown" end
	local name = GetSpellInfo(id)
	--DA.DEBUG(0,"name "..(id or "nil").." "..(name or "nil"))
	if name then return name, id end
	id = tonumber(id)
	name = "unknown"
	for n,m in pairs(self.recipeDataModules) do
		if name == "unknown" then
			name = m.GetRecipeName(m, id)
		end
	end
	return name
end

function Skillet:GetRecipe(id)
--	DA.DEBUG(2,"Skillet:GetRecipe "..tostring(id))
	if not id or id == 0 then return self.unknownRecipe end
	local recipe = self.unknownRecipe
	id = tonumber(id)
	for n,m in pairs(self.recipeDataModules) do
		if recipe == self.unknownRecipe then
			recipe = m.GetRecipe(m, id)
		end
	end
	return recipe, id
end

-- reconstruct a recipe from a recipeString and cache it into our system for this session
function SkilletData:GetRecipe(id)
--	DA.DEBUG(3,"SkilletData:GetRecipe "..tostring(id))
	if not id or id == 0 then return self.unknownRecipe end
	if (not Skillet.data.recipeList[id]) and Skillet.db.global.recipeDB[id] then
		local recipeString = Skillet.db.global.recipeDB[id]
--		DA.DEBUG(3,"recipeString= "..tostring(recipeString))
		local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
		local itemID, numMade = 0, 1
		local slot = nil
		if itemString ~= "0" then
			local a, b = string.split(":",itemString)
--			DA.DEBUG(3,"itemString a= "..tostring(a)..", b= "..tostring(b))
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
		Skillet.data.recipeList[id] = {}
		Skillet.data.recipeList[id].spellID = tonumber(id)
		Skillet.data.recipeList[id].name = GetSpellInfo(tonumber(id))
		Skillet.data.recipeList[id].tradeID = tonumber(tradeID)
		Skillet.data.recipeList[id].itemID = tonumber(itemID)
		Skillet.data.recipeList[id].numMade = tonumber(numMade)
		Skillet.data.recipeList[id].slot = slot
		Skillet.data.recipeList[id].reagentData = {}
		if reagentString ~= "-" then
			local reagentList = { string.split(":",reagentString) }
			local numReagents = #reagentList / 2
			for i=1,numReagents do
				Skillet.data.recipeList[id].reagentData[i] = {}
				Skillet.data.recipeList[id].reagentData[i].id = tonumber(reagentList[1 + (i-1)*2])
				Skillet.data.recipeList[id].reagentData[i].numNeeded = tonumber(reagentList[2 + (i-1)*2])
			end
		end
		if toolString ~= "-" then
			Skillet.data.recipeList[id].tools = {}
			local toolList = { string.split(":",toolString) }
			for i=1,#toolList do
				Skillet.data.recipeList[id].tools[i] = string.gsub(toolList[i],"_"," ")
			end
		end
	end
	return Skillet.data.recipeList[id] or Skillet.unknownRecipe
end

function Skillet:GetNumSkills(player, trade)
	DA.DEBUG(2,"Skillet:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	local skillModule = self.dataGatheringModules[player]
	if skillModule then
		return skillModule.GetNumSkills(skillModule, player, trade)
	end
	return 0
end

function Skillet:GetSkillRanks(player, trade)
	local skillModule = self.dataGatheringModules[player]
	if skillModule then
		return skillModule.GetSkillRanks(skillModule, player, trade)
	end
end

function SkilletLink:GetSkillRanks(player, trade)
	local skillRanks = {}
	if Skillet.db.realm.tradeSkills[player] and Skillet.db.realm.tradeSkills[player][trade] then
		skillRanks.rank = Skillet.db.realm.tradeSkills[player][trade].rank
		skillRanks.maxRank = Skillet.db.realm.tradeSkills[player][trade].maxRank
		return skillRanks
	end
	local linkedSkill, linkedPlayer = Skillet:IsTradeSkillLinked()
	if linkedSkill then
		if linkedPlayer == player then
			local skill, rank, max = GetTradeSkillLine()
			if GetSpellInfo(trade) == skill then
				skillRanks.rank = rank
				skillRanks.maxRank = max
				return skillRanks
			end
		end
	end
end

function SkilletLink:GetNumSkills(player, trade)
--	DA.DEBUG(3,"SkilletLink:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	local linkedSkill, linkedPlayer = Skillet:IsTradeSkillLinked()
	if linkedSkill then
--		if linkedPlayer == player then
			local skill, rank, max = GetTradeSkillLine()
			if GetSpellInfo(trade) == skill then
				return GetNumTradeSkills()
			end
--		end
	end
	return 0
end

function SkilletData:GetSkillRanks(player, trade)
	if player and trade then
		if Skillet.db.realm.tradeSkills[player] then
			return Skillet.db.realm.tradeSkills[player][trade]
		end
	end
end

function SkilletData:GetNumSkills(player, trade)
--	DA.DEBUG(3,"SkilletData:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	if not Skillet.db.realm.skillDB[player] then return 0 end
	if not Skillet.db.realm.skillDB[player][trade] then return 0 end
	return #Skillet.db.realm.skillDB[player][trade]
end

function Skillet:GetSkill(player,trade,index)
--	DA.DEBUG(2,"Skillet:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	local skillModule = self.dataGatheringModules[player]
	if skillModule then
		return skillModule.GetSkill(skillModule, player,trade,index)
	else
		return self.unknownRecipe
	end
end

function SkilletLink:GetSkill(player,trade,index)
--	DA.DEBUG(3,"SkilletLink:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	if player and trade and index then
		local scanned = true
		if not Skillet.data.skillList[player] or not Skillet.data.skillList[player][trade] then
			scanned = self:RescanTrade()
		end
		if scanned then
			local skill = Skillet.data.skillList[player]
			if skill then
				local trade = skill[trade]
				if trade then
					return trade[index]
				end
			end
			return nil
		else
			return nil
		end
	end
end

function SkilletLink:GetRecipe(id)
--	DA.DEBUG(3,"SkilletLink:GetRecipe "..tostring(id))
	if not id or id == 0 then return self.unknownRecipe end
	if (not Skillet.data.recipeList[id]) then
		self:RescanTrade()
		--DA.DEBUG(0,"can't find recipe "..id);
	end
	return Skillet.data.recipeList[id] or Skillet.unknownRecipe
end

function SkilletLink:ScanTrade()
	DA.DEBUG(0,"ScanTrade")
	if self.scanInProgress == true then
		--DA.DEBUG(0,"SCAN BUSY!")
		return
	end
	self.scanInProgress = true
	local tradeID
	local API = {}
	local profession, rank, maxRank = GetTradeSkillLine()
	--DA.DEBUG(0,"GetTradeSkill: "..(profession or "nil"))
	-- get the tradeID from the profession name (data collected earlier).
	tradeID = TradeSkillIDsByName[profession] or 2656				-- "mining" doesn't exist as a spell, so instead use smelting (id 2656)
	if tradeID ~= Skillet.currentTrade then
		--DA.DEBUG(0,"TRADE MISMATCH for player "..(Skillet.currentPlayer or "nil").."!  "..(tradeID or "nil").." vs "..(Skillet.currentTrade or "nil"));
	end
	local player = Skillet.currentPlayer
	if not self.recacheRecipe then
		self.recacheRecipe = {}
	end
	if not self.alreadyScanned then
		self.alreadyScanned = {}
	end
	if not self.alreadyScanned[player] then
		self.alreadyScanned[player] = {}
	end
	if not self.alreadyScanned[player][tradeID] then
		self.alreadyScanned[player][tradeID] = 0
	end
	self:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
	local numSkills = GetNumTradeSkills()
	for i = 1, numSkills do
		local _, skillType, _, isExpanded = GetTradeSkillInfo(i)
		if skillType == "header" or skillType == "subheader" then
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
			end
		end
	end
	numSkills = GetNumTradeSkills()
	DA.DEBUG(0,"Scanning Trade "..tostring(profession)..":"..tostring(tradeID).." "..tostring(numSkills).." recipes")
	if not Skillet.data.skillIndexLookup[player] then
		Skillet.data.skillIndexLookup[player] = {}
	end
	if not Skillet.data.skillList[player] then
		Skillet.data.skillList[player] = {}
	end
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID] = {}
	end
	local skillData = Skillet.data.skillList[player][tradeID]
	local lastHeader = nil
	local gotNil = false
	local currentGroup = nil
	local mainGroup = Skillet:RecipeGroupNew(player,tradeID,"Blizzard")
	mainGroup.locked = true
	mainGroup.autoGroup = true
	Skillet:RecipeGroupClearEntries(mainGroup)
	local groupList = {}
	local numHeaders = 0
	local alreadyScannedThisRun = 0
	local parentGroup=nil
	for i = 1, numSkills, 1 do
		repeat
--			DA.DEBUG(0,"scanning index "..i)
			local subSpell, extra
			local skillName, skillType, _, isExpanded = GetTradeSkillInfo(i)
--			DA.DEBUG(0,("**** skill: "..(skillName or "nil").." "..i)
			gotNil = false
			if skillName then
				if skillType == "header" or skillType == "subheader" then
					numHeaders = numHeaders + 1
					if not isExpanded then
						ExpandTradeSkillSubClass(i)
					end
					local groupName
					if groupList[skillName] then
						groupList[skillName] = groupList[skillName]+1
						groupName = skillName.." "..groupList[skillName]
					else
						groupList[skillName] = 1
						groupName = skillName
					end
					skillData[i] = {}
					skillData[i].id = 0
					skillData[i].name = skillName
					currentGroup = Skillet:RecipeGroupNew(player, tradeID, "Blizzard", groupName)
					currentGroup.autoGroup = true
					if skillType == "header" then
						parentGroup = currentGroup
						Skillet:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
					else
						Skillet:RecipeGroupAddSubGroup(parentGroup, currentGroup, i)
					end
				else
					local recipeLink = GetTradeSkillRecipeLink(i)
					local recipeID = Skillet:GetItemIDFromLink(recipeLink)
					if not recipeID then
						gotNil = true
						break
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
					skillData[i].category = lastHeader
					local tools = { GetTradeSkillTools(i) }
					skillData[i].tools = {}
					local slot = 1
					for t=2,#tools,2 do
						skillData[i].tools[slot] = (tools[t] or 0)
						slot = slot + 1
					end
					local cd = GetTradeSkillCooldown(i)
					if cd then
						skillData[i].cooldown = cd + time()						-- this is when your cooldown will be up
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
					end
					Skillet.data.skillIndexLookup[player][recipeID] = i
					Skillet.data.recipeList[recipeID] = {}
					local recipe = Skillet.data.recipeList[recipeID]
					local recipeString
					local toolString = "-"
					recipe.tradeID = tradeID
					recipe.spellID = recipeID
					recipe.name = skillName
					if #tools >= 1 then
						recipe.tools = { tools[1] }
						toolString = string.gsub(tools[1]," ", "_")
						for t=3,#tools,2 do
							table.insert(recipe.tools, tools[t])
							toolString = toolString..":"..string.gsub(tools[t]," ", "_")
						end
					end
					local itemLink = GetTradeSkillItemLink(i)
					if not itemLink then
						gotNil = true
						break
					end
					local itemString = "0"
					if GetItemInfo(itemLink) then
						local itemID = Skillet:GetItemIDFromLink(itemLink)
						local minMade,maxMade = GetTradeSkillNumMade(i)
						recipe.itemID = itemID
						recipe.numMade = (minMade + maxMade)/2
						if recipe.numMade > 1 then
							itemString = itemID..":"..recipe.numMade
						else
							itemString = itemID
						end
						Skillet:ItemDataAddRecipeSource(itemID,recipeID)	-- add a cross reference for the source of particular items
					else
						recipe.numMade = 1
						if LSW and LSW.scrollData and LSW.scrollData[recipeID] then
							local itemID = LSW.scrollData[recipeID]
							recipe.itemID = itemID
							itemString = itemID
							Skillet:ItemDataAddRecipeSource(itemID,recipeID)	-- add a cross reference for the source of particular items
						else
							recipe.itemID = 0								-- indicates an enchant
						end
					end
					local reagentString = nil
					local reagentData = {}
					for j=1, GetTradeSkillNumReagents(i), 1 do
						local reagentName, _, numNeeded = GetTradeSkillReagentInfo(i,j)
						local reagentID = 0
						if reagentName then
							local reagentLink = FixedGetTradeSkillReagentItemLink(i,j)
							reagentID = Skillet:GetItemIDFromLink(reagentLink)
						else
							gotNil = true
							break
						end
						reagentData[j] = {}
						reagentData[j].id = reagentID
						reagentData[j].numNeeded = numNeeded
						Skillet:ItemDataAddUsedInRecipe(reagentID, recipeID)	-- add a cross reference for where a particular item is used
					end
					recipe.reagentData = reagentData
					if gotNil then
						self.recacheRecipe[recipeID] = true
					else
					end
				end
			else
				gotNil = true
			end
		until true
		if gotNil and recipeID then
			self.recacheRecipe[recipeID] = true
		else
			alreadyScannedThisRun = alreadyScannedThisRun + 1
		end
		if alreadyScannedThisRun > self.alreadyScanned[player][tradeID] then
			self.alreadyScanned[player][tradeID] = alreadyScannedThisRun
			local progress = math.ceil(alreadyScannedThisRun*100/numSkills)
			if progress < 100 then
				--Skillet:UpdateScanningText(L["Scanning tradeskill"]..": "..progress.."%")
			end
		end
	end
	DA.DEBUG(0,"Scan Complete")
	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	--DA.DEBUG(0,"all sorted")
	self.scanInProgress = false
	collectgarbage("collect")
	if numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	Skillet:UpdateScanningText()
	skillData.scanned = true
	return true
	-- Skillet:SendMessage("Skillet_Scan_Complete", profession)
end

-- reconstruct a skill from a skillString and cache it into our system for this session
function SkilletData:GetSkill(player,trade,index)
--	DA.DEBUG(0,"SkilletData:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
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
end

-- collects generic tradeskill data (id to name and name to id)
function Skillet:CollectTradeSkillData()
	for i=1,#TradeSkillList,1 do
		local id = TradeSkillList[i]
		local name, _, icon = GetSpellInfo(id)
		TradeSkillIDsByName[name] = id
	end
	self.tradeSkillIDsByName = TradeSkillIDsByName
	self.tradeSkillList = TradeSkillList
end

-- this routine collects the basic data (which tradeskills a player has)
-- clean = true means wipe the old data
function SkilletData:ScanPlayerTradeSkills(player, clean)
	if player == (UnitName("player")) then -- only for active player
		if clean or not Skillet.db.realm.tradeSkills[player] then
			Skillet.db.realm.tradeSkills[player] = {}
		end
		local skillRanksData = Skillet.db.realm.tradeSkills[player]
		for i=1,#TradeSkillList,1 do
			local id = TradeSkillList[i]
			local name = GetSpellInfo(id)									-- always returns data
			local _, rankName, icon = GetSpellInfo(name)					-- only returns data if you have this spell in your spellbook
			DA.DEBUG(0,"collecting tradeskill data for "..name.." "..(rank or "nil"))
			if rankName then
				if not skillRanksData[id] then
					skillRanksData[id] = {}
					skillRanksData[id].rank = 0
					skillRanksData[id].maxRank = 0
				end
			else
				skillRanksData[id] = nil
			end
		end
		if not Skillet.db.realm.faction then
			Skillet.db.realm.faction = {}
		end
		Skillet.db.realm.faction[player] = UnitFactionGroup("player")
	end
	return Skillet.db.realm.tradeSkills[player]
end

-- this routine collects the basic data (which tradeskills a player has)
-- clean = true means wipe the old data
function SkilletLink:ScanPlayerTradeSkills(player, clean)
	if Skillet.db.realm.tradeSkills[player] then
		return true
	end
	local isLinked, playerLinked = Skillet:IsTradeSkillLinked()
	if isLinked and player == playerLinked then
		return true
	end
end

-- [3273] = "|cffffd000|Htrade:3274:148:150:23F381A:zD<<t=|h[First Aid]|h|r",  -- >>
local allDataInitialized = false
function Skillet:InitializeAllDataLinks(name)
	if allDataInitialized then return end
	allDataInitialized = true
	if Skillet.wowVersion >= 50400 then -- patch 5.4 issue
		self.db.realm.tradeSkills[name] = nil
		return
	end
	if not self.db.realm.tradeSkills then
		self.db.realm.tradeSkills = {}
	end
	self.db.realm.tradeSkills[name] = {}
	local link = GetTradeSkillListLink()
	if not link then allDataInitialized = false return end
	local uid = UnitGUID("player"):gsub("0x0+","")
	for tradeID, bitmapLength in pairs(TradeSkillRecipeCounts) do
		local spellName = GetSpellInfo(tradeID)
		local link
		local encodingLength = floor((bitmapLength+5) / 6)
		local encodedString = string.rep("/",encodingLength)
		if Skillet.wowVersion >= 50400 then
			link = "|cffffd000|Htrade:"..(uid or "23F381A")..":"..tradeID..":333|h["..spellName.."]|h|r"
		elseif Skillet.wowVersion >= 50300 then
			link = "|cffffd00|Htrade:"..(uid or "23F381A")..":"..tradeID..":600:600:"..encodedString.."|h["..spellName.."]|h|r"
		else
			link = "|cffffd00|Htrade:"..tradeID..":375:450:"..(uid or "23F381A")..":"..encodedString.."|h["..spellName.."]|h|r"
		end
		DA.DEBUG(0,"AllData Link "..tradeID.." "..(uid or "nil").." "..(spellName or "nil").." "..link)
		self.db.realm.tradeSkills[name][tradeID] = {}
		self.db.realm.tradeSkills[name][tradeID].link = link
		self.db.realm.tradeSkills[name][tradeID].rank = 600
		self.db.realm.tradeSkills[name][tradeID].maxRank = 600
	end
	self:RegisterPlayerDataGathering(name,SkilletLink,"sk")
end

function Skillet:EnableUpdateEvents()
	self:RegisterEvent("CHAT_MSG_SKILL")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("TRADE_SKILL_UPDATE")
end

function Skillet:DisableUpdateEvents()
	self:UnregisterEvent("CHAT_MSG_SKILL")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent("TRADE_SKILL_UPDATE")
end

function Skillet:EnableDataGathering(addon)
	Skillet:EnableUpdateEvents()
	self.dataScanned = false
	self:CollectTradeSkillData()
	self:RegisterRecipeDatabase("sk",SkilletData)
	if self.db and self.db.realm and self.db.realm.tradeSkills then
		for player in pairs(self.db.realm.tradeSkills) do
			self:RegisterPlayerDataGathering(player,SkilletLink,"sk")
		end
	end
	self:RegisterPlayerDataGathering((UnitName("player")),SkilletData, "sk") -- make sure to add the current player as well
	SkilletARL:Enable()
end

function Skillet:EnableQueue(addon)
	assert(tostring(addon),"Usage: EnableDataGathering('addon')")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",   "ContinueCastCheckUnit")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED",      "StopCastCheckUnit")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "StopCastCheckUnit")
	self:RegisterEvent("UNIT_SPELLCAST_STOPPED",     "StopCastCheckUnit")
end

function Skillet:DisableQueue(addon)
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_STOPPED")
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
			-- local recipeData = self.db.global.recipeData[recipeID] or selfUnknownRecipe
			local recipeData = self:GetRecipe(recipeID)
			return recipeData, recipeData.spellID, recipeData.ItemID
		end
	end
	return self.unknownRecipe
end

function Skillet:ContinueCastCheckUnit(event, unit, spell, rank)
	--DA.DEBUG(0,"ContinueCastCheckUnit "..(unit or "nil"))
	if unit == "player" and spell==self.processingSpell then
		self:ContinueCast(spell)
		-- AceEvent:ScheduleEvent("Skillet_StopCast", self.StopCast, 0.1,self,event,spell)
	end
end

function Skillet:StopCastCheckUnit(event, unit, spell, rank)
	if unit == "player" then
		self:StopCast(spell)
		-- AceEvent:ScheduleEvent("Skillet_StopCast", self.StopCast, 0.1,self,event,spell)
	end
end

local rescan_time = 1
-- Internal
-- scan trade, if it fails, rescan after 1 sek, if it fails, rescan after 5 sek and give up
function Skillet:Skillet_AutoRescan()
	Skillet.scheduleRescan = false
	local start = GetTime()
	DA.DEBUG(0,"AUTO RESCAN START")
	if InCombatLockdown() or not SkilletFrame:IsVisible() then
		self.auto_rescan_timer = nil
		return
	end
	local scanResult = self:RescanTrade()
	if not scanResult or Skillet.scheduleRescan then
		if rescan_time > 5 then
			rescan_time = 1
			self.auto_rescan_timer = nil
			return
		end
		self.auto_rescan_timer = self:ScheduleTimer("Skillet_AutoRescan", rescan_time)
		rescan_time = rescan_time + 4
	else
		rescan_time = 1
		self.auto_rescan_timer = nil
		self:UpdateTradeSkillWindow()
	end
	local elapsed = GetTime() - start
	DA.DEBUG(0,"AUTO RESCAN COMPLETE")
	DA.DEBUG(0,"Skillet Auto-Rescan: "..(math.floor(elapsed*100+.5)/100).." seconds")
end

function Skillet:TRADE_SKILL_UPDATE()
	DA.DEBUG(0,"TRADE_SKILL_UPDATE "..(event or "nil").." "..(arg1 or "nil"))
	if not Skillet.scanInProgress and not self.auto_rescan_timer then
		self.auto_rescan_timer = self:ScheduleTimer("Skillet_AutoRescan", 0.5)
	else
		-- Skillet.scheduleRescan = true
	end
end

function Skillet:CHAT_MSG_SKILL()
	--DA.DEBUG(0,"CHAT_MSG_SKILL "..(event or "nil"))
	if not Skillet.scanInProgress and not self.auto_rescan_timer then
		self.auto_rescan_timer = self:ScheduleTimer("Skillet_AutoRescan", 0.5)
	else
		Skillet.scheduleRescan = true
	end
end

function Skillet:CHAT_MSG_SYSTEM(event,msg)
	--DA.DEBUG(0,"CHAT_MSG_SYSTEM "..(msg or "nil"))
	local cutString = string.sub(ERR_LEARN_RECIPE_S,1,(string.find(ERR_LEARN_RECIPE_S,"%%s")-1))
	--DA.DEBUG(0,"CHAT_MSG_SYSTEM "..(arg1 or "nil").." vs "..cutString)
	if msg and string.find(msg, cutString) then
		if not Skillet.scanInProgress and not self.auto_rescan_timer then
			self.auto_rescan_timer = self:ScheduleTimer("Skillet_AutoRescan", 0.5)
		else
			Skillet.scheduleRescan = true
		end
	end
end

function Skillet:CalculateCraftableCounts(playerOverride)
	DA.DEBUG(0,"CalculateCraftableCounts Start")
	local player = playerOverride or self.currentPlayer
	DA.DEBUG(0,(player or "nil").." "..(self.currentTrade or "nil"))
	DA.DEBUG(0,"recalculating crafting counts")
	self.visited = {}
	for i=1,self:GetNumSkills(player, self.currentTrade) do
		local skill = self:GetSkill(player, self.currentTrade, i)
		if skill then -- skip headers
			skill.numCraftable, skill.numCraftableVendor, skill.numCraftableBank, skill.numCraftableAlts = self:InventorySkillIterations(self.currentTrade, i, player)
		end
	end
	DA.DEBUG(0,"CalculateCraftableCounts Complete")
end

function Skillet:RescanTrade(force)
	DA.DEBUG(0,"RescanTrade")
	if not self.currentPlayer or not self.currentTrade then return end
	local dataModule = self.dataGatheringModules[self.currentPlayer]
	local val = true
	if dataModule and dataModule.RescanTrade then
		Skillet.scanInProgress = true
		Skillet:DisableUpdateEvents()
		val = dataModule.RescanTrade(dataModule, force)
		Skillet:EnableUpdateEvents()
		Skillet.scanInProgress = false
	end
	return val
end
-- Triggers a rescan of the currently selected tradeskill
function SkilletLink:RescanTrade(force)
	if not Skillet.currentPlayer or not Skillet.currentTrade then return end
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not Skillet.data.skillList[player] then
		Skillet.data.skillList[player] = {}
	end
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID]={}
	end
	if force then
		DA.DEBUG(0,"Forced Rescan")
		Skillet.data.skillList[player]={}
		Skillet:InitializeDatabase(player, true)
	end
	Skillet:ScanQueuedReagents()
	Skillet.dataScanned = self:ScanTrade()
	DA.DEBUG(0,"TRADESKILL HAS BEEN SCANNED")
	self:RecipeGroupGenerateAutoGroups()
	return Skillet.dataScanned
end
-- Triggers a rescan of the currently selected tradeskill
function SkilletData:RescanTrade(force)
	if not Skillet.currentPlayer or not Skillet.currentTrade then return end
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	-- self:InitializeDatabase(self.currentPlayer, false)
	if player == (UnitName("player")) then -- only allow actual skill rescans of current player data
		if not Skillet.data.skillList[player] then
			Skillet.data.skillList[player] = {}
		end
		if not Skillet.data.skillList[player][tradeID] then
			Skillet.data.skillList[player][tradeID]={}
		end
		if not Skillet.db.realm.skillDB[player] then
			Skillet.db.realm.skillDB[player] = {}
		end
		if not Skillet.db.realm.skillDB[player][tradeID] then
			Skillet.db.realm.skillDB[player][tradeID] = {}
		end
		if force then
			DA.DEBUG(0,"Forced Rescan")
			Skillet.data.skillList[player]={}
			Skillet:InitializeDatabase(player, true)
			local firstSkill
			for id,list in pairs(Skillet.db.realm.tradeSkills[player]) do
				if not firstSkill then
					firstSkill = id
				end
				Skillet.data.skillList[player][id] = {}
			end
			Skillet.data.skillIndexLookup[player] = {}
			if not Skillet.db.realm.tradeSkills[player] then
				Skillet.currentTrade = firstSkill
			end
		end
		Skillet:ScanQueuedReagents()
		Skillet.dataScanned = self:ScanTrade()
	else	-- it's an alt, just do the inventory and craftability update stuff
		Skillet:ScanQueuedReagents()
		Skillet:InventoryScan()
		Skillet:CalculateCraftableCounts()
		Skillet.dataScanned = true
	end
	self:RecipeGroupGenerateAutoGroups()
	DA.DEBUG(0,"TRADESKILL HAS BEEN SCANNED")
	return Skillet.dataScanned
end

function SkilletData:ScanTrade()
	DA.DEBUG(0,"ScanTrade")
	if self.scanInProgress == true then
		DA.DEBUG(0,"SCAN BUSY!")
		return
	end
	self.scanInProgress = true
	local tradeID
	local API = {}
	local link = GetTradeSkillListLink()
	local profession, rank, maxRank = GetTradeSkillLine()
	if link then
		DA.DEBUG(0,"GetTradeSkill: "..(profession or "nil").." link="..link.." "..string.gsub(link, "\124", "\124\124"))
	else
		DA.DEBUG(0,"GetTradeSkill: "..(profession or "nil").." non linkable")
	end
	API.GetNumSkills = GetNumTradeSkills
	API.ExpandLine = ExpandTradeSkillSubClass
	API.GetRecipeLink = GetTradeSkillRecipeLink
	API.GetTools = GetTradeSkillTools
	API.GetCooldown = GetTradeSkillCooldown
	API.GetItemLink = GetTradeSkillItemLink
	API.GetNumMade = GetTradeSkillNumMade
	API.GetNumReagents = GetTradeSkillNumReagents
	API.GetReagentInfo = GetTradeSkillReagentInfo
	-- API.GetReagentLink = GetTradeSkillReagentItemLink
	API.GetReagentLink = FixedGetTradeSkillReagentItemLink
	-- get the tradeID from the profession name (data collected earlier).
	tradeID = TradeSkillIDsByName[profession] or 2656	-- "mining" doesn't exist as a spell, so instead use smelting (id 2656)
	if tradeID ~= Skillet.currentTrade then
		DA.DEBUG(0,"TRADE MISMATCH for player "..(Skillet.currentPlayer or "nil").."!  "..(tradeID or "nil").." vs "..(Skillet.currentTrade or "nil"));
	end
	local player = Skillet.currentPlayer
	if not self.recacheRecipe then
		self.recacheRecipe = {}
	end
	if not self.alreadyScanned then
		self.alreadyScanned = {}
	end
	if not self.alreadyScanned[player] then
		self.alreadyScanned[player] = {}
	end
	if not self.alreadyScanned[player][tradeID] then
		self.alreadyScanned[player][tradeID] = 0
	end
	if not Skillet:IsTradeSkillLinked() then
		Skillet.db.realm.tradeSkills[player][tradeID] = {}
		Skillet.db.realm.tradeSkills[player][tradeID].rank = rank
		Skillet.db.realm.tradeSkills[player][tradeID].maxRank = maxRank
	end
		self:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
	local numSkills = API.GetNumSkills()
	for i = 1, numSkills do
		local _, skillType, _, isExpanded = GetTradeSkillInfo(i)
		if skillType == "header" or skillType == "subheader" then
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
			end
		end
	end
	numSkills = API.GetNumSkills()
	DA.DEBUG(0,"Scanning Trade "..(profession or "nil")..":"..(tradeID or "nil").." "..numSkills.." recipes")
	if not Skillet.data.skillIndexLookup[player] then
		Skillet.data.skillIndexLookup[player] = {}
	end
	local skillDB = Skillet.db.realm.skillDB[player][tradeID]
	local skillData = Skillet.data.skillList[player][tradeID]
	local recipeDB = Skillet.db.global.recipeDB
	if not skillData then
		self.scanInProgress = false
		return false
	end
	local lastHeader = nil
	local gotNil = false
	local currentGroup = nil
	local mainGroup = Skillet:RecipeGroupNew(player,tradeID,"Blizzard")
	mainGroup.locked = true
	mainGroup.autoGroup = true
	Skillet:RecipeGroupClearEntries(mainGroup)
	local groupList = {}
	if not Skillet.db.realm.tradeSkills[player] then
		Skillet.db.realm.tradeSkills[player] = {}
	end
	if not Skillet.db.realm.tradeSkills[player][tradeID] then
		Skillet.db.realm.tradeSkills[player][tradeID] = {}
	end
	local skillName, rank, maxRank = GetTradeSkillLine()
	Skillet.db.realm.tradeSkills[player][tradeID].link = link
	Skillet.db.realm.tradeSkills[player][tradeID].rank = rank
	Skillet.db.realm.tradeSkills[player][tradeID].maxRank = maxRank
	local numHeaders = 0
	local parentGroup
	local alreadyScannedThisRun = 0
	for i = 1, numSkills, 1 do
		repeat
			--DA.DEBUG(0,"scanning index "..i)
			local skillName, skillType, isExpanded, subSpell, extra
			local skillName, skillType, _, isExpanded = GetTradeSkillInfo(i)
			--DA.DEBUG(0,"**** skill: "..(skillName or "nil"))
			gotNil = false
			if skillName then
				if skillType == "header" or skillType == "subheader" then
					numHeaders = numHeaders + 1
					if not isExpanded then
						API.ExpandLine(i)
					end
					local groupName
					if groupList[skillName] then
						groupList[skillName] = groupList[skillName]+1
						groupName = skillName.." "..groupList[skillName]
					else
						groupList[skillName] = 1
						groupName = skillName
					end
					skillDB[i] = "header "..skillName
					skillData[i] = nil
					currentGroup = Skillet:RecipeGroupNew(player, tradeID, "Blizzard", groupName)
					currentGroup.autoGroup = true
					if skillType == "header" then
						parentGroup = currentGroup
						Skillet:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
					else
						Skillet:RecipeGroupAddSubGroup(parentGroup, currentGroup, i)
					end
				else
					local recipeLink = API.GetRecipeLink(i)
					local recipeID = Skillet:GetItemIDFromLink(recipeLink)
					if not recipeID then
						gotNil = true
						break
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
					skillData[i].category = lastHeader
					local skillDBString = DifficultyChar[skillType]..recipeID
					local tools = { API.GetTools(i) }
					skillData[i].tools = {}
					local slot = 1
					for t=2,#tools,2 do
						skillData[i].tools[slot] = (tools[t] or 0)
						slot = slot + 1
					end
					local cd = API.GetCooldown(i)
					if cd then
						skillData[i].cooldown = cd + time()		-- this is when your cooldown will be up
						skillDBString = skillDBString.." cd=" .. cd + time()
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
					if recipeDB[recipeID] and not self.recacheRecipe[recipeID] then
						-- presumably the data is the same, so there's not much that needs to happen here.
						-- potentially, however, i could see an instance where a mod might feed tradeskill info and then "better" tradeskill info
						-- might be retrieved from the server which should over-ride the earlier tradeskill info
						-- (eg, tradeskillinfo sends skillet some data and then we learn that data was not quite up-to-date)
					else
						Skillet.data.recipeList[recipeID] = {}
						local recipe = Skillet.data.recipeList[recipeID]
						local recipeString
						local toolString = "-"
						recipe.tradeID = tradeID
						recipe.spellID = recipeID
						recipe.name = skillName
						if #tools >= 1 then
							recipe.tools = { tools[1] }
							toolString = string.gsub(tools[1]," ", "_")
							for t=3,#tools,2 do
								table.insert(recipe.tools, tools[t])
								toolString = toolString..":"..string.gsub(tools[t]," ", "_")
							end
						end
						local itemLink = API.GetItemLink(i)
						if not itemLink then
							gotNil = true
							break
						end
						local itemString = "0"
						if GetItemInfo(itemLink) then
							local itemID = Skillet:GetItemIDFromLink(itemLink)
							local minMade,maxMade = API.GetNumMade(i)
							recipe.itemID = itemID
							recipe.numMade = (minMade + maxMade)/2
							if recipe.numMade > 1 then
								itemString = itemID..":"..recipe.numMade
							else
								itemString = itemID
							end
							Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of particular items
						else
							recipe.numMade = 1
							if LSW and LSW.scrollData and LSW.scrollData[recipeID] then
								local itemID = LSW.scrollData[recipeID]
								recipe.itemID = itemID
								itemString = itemID
								Skillet:ItemDataAddRecipeSource(itemID,recipeID)	-- add a cross reference for the source of particular items
							else
								recipe.itemID = 0									-- indicates an enchant
							end
						end
						local reagentString = "-"
						local reagentData = {}
						for j=1, API.GetNumReagents(i), 1 do
							local reagentName, _, numNeeded = API.GetReagentInfo(i,j)
							local reagentID = 0
							if reagentName then
								local reagentLink = API.GetReagentLink(i,j)
								reagentID = Skillet:GetItemIDFromLink(reagentLink)
							else
								gotNil = true
								break
							end
							reagentData[j] = {}
							reagentData[j].id = reagentID
							reagentData[j].numNeeded = numNeeded
							if reagentString ~= "-" then
								reagentString = reagentString..":"..reagentID..":"..numNeeded
							else
								reagentString = reagentID..":"..numNeeded
							end
							Skillet:ItemDataAddUsedInRecipe(reagentID, recipeID)	-- add a cross reference for where a particular item is used
						end
						recipe.reagentData = reagentData
						if gotNil then
							self.recacheRecipe[recipeID] = true
						else
							recipeString = tradeID.." "..itemString.." "..reagentString
							if #tools then
								recipeString = recipeString.." "..toolString
							end
							recipeDB[recipeID] = recipeString
						end
					end
				end
			else
				gotNil = true
			end
		until true
		if gotNil and recipeID then
			self.recacheRecipe[recipeID] = true
		else
			alreadyScannedThisRun = alreadyScannedThisRun + 1
		end
		if alreadyScannedThisRun > self.alreadyScanned[player][tradeID] then
			self.alreadyScanned[player][tradeID] = alreadyScannedThisRun
			local progress = math.ceil(alreadyScannedThisRun*100/numSkills)
			if progress < 100 then
				--Skillet:UpdateScanningText(L["Scanning tradeskill"]..": "..progress.."%")
			end
		end
	end
	-- Skillet:RecipeGroupConstructDBString(mainGroup)
	DA.DEBUG(0,"Scan Complete")
	--DA.DEBUG(0,"Scan Complete "..numHeaders)
	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	DA.DEBUG(0,"all sorted")
	self.scanInProgress = false
	collectgarbage("collect")
	if numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	Skillet:UpdateScanningText()
	skillData.scanned = true
	return true
	-- Skillet:SendMessage("Skillet_Scan_Complete", profession)
end

function SkilletData:EnchantingRecipeSlotAssign(recipeID, slot)
	local recipeString = Skillet.db.global.recipeDB[recipeID]
	local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
	if itemString == "0" then
		itemString = "0:"..slot
		Skillet.db.global.recipeDB[recipeID] = tradeID.." 0:"..slot.." "..reagentString.." "..toolString
		Skillet:GetRecipe(recipeID)
		--DA.DEBUG(0,(Skillet.data.recipeList[recipeID].name or "noName")
		Skillet.data.recipeList[recipeID].slot = slot
	end
end

local invSlotLookup = {
	["HEADSLOT"] = "HeadSlot",
	["NECKSLOT"] = "NeckSlot",
	["SHOULDERSLOT"] = "ShoulderSlot",
	["CHESTSLOT"] = "ChestSlot",
	["WAISTSLOT"] = "WaistSlot",
	["LEGSSLOT"] = "LegsSlot",
	["FEETSLOT"] = "FeetSlot",
	["WRISTSLOT"] = "WristSlot",
	["HANDSSLOT"] = "HandsSlot",
	["FINGER0SLOT"] = "Finger0Slot",
	["TRINKET0SLOT"] = "Trinket0Slot",
	["BACKSLOT"] =	"BackSlot",
	["ENCHSLOT_WEAPON"] = "MainHandSlot",
	["ENCHSLOT_2HWEAPON"] = "MainHandSlot",
	["SHIELDSLOT"] = "SecondaryHandSlot",
}

function SkilletData:ScanEnchantingGroups(mainGroup)
	local groupList = {}
	if mainGroup then
		local craftSlots = { GetCraftSlots() }
		Skillet:RecipeGroupClearEntries(mainGroup)
		for i=1,#craftSlots do
			local groupName
			local slotName = _G[craftSlots[i]]
			local invSlot
			if groupList[slotName] then
				groupList[slotName] = groupList[slotName]+1
				groupName = slotName.." "..groupList[slotName]
			else
				groupList[slotName] = 1
				groupName = slotName
			end
			local currentGroup = Skillet:RecipeGroupNew(Skillet.currentPlayer, 7411, "Blizzard", groupName)			-- 7411 = enchanting
			SetCraftFilter(i+1)
			for s=1,GetNumCrafts() do
				local recipeLink = GetCraftRecipeLink(s)
				local recipeID = Skillet:GetItemIDFromLink(recipeLink)
				if craftSlots[i] ~= "NONEQUIPSLOT" then
					invSlot = GetInventorySlotInfo(invSlotLookup[craftSlots[i]])
					self:EnchantingRecipeSlotAssign(recipeID, invSlot)
				end
				DA.DEBUG(0,"adding "..(recipeLink or "nil").." to "..groupName)
				Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, Skillet.data.skillIndexLookup[Skillet.currentPlayer][recipeID])
			end
			Skillet:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
		end
	end
	SetCraftFilter(1)
end

function Skillet:GenerateAltKnowledgeBase()
	local tradeID = Skillet.currentTrade
	local player = Skillet.currentPlayer
	local knownRecipes = {}
	local unknownRecipes = {}
	for label in pairs(Skillet.dataGatheringModules) do
		local rankData = Skillet:GetSkillRanks(label, tradeID)
		if label ~= "All Data" and rankData then
			Skillet:InitGroupList(player, tradeID, label, true)
			if label == Skillet.currentGroupLabel then
				local mainGroup =  Skillet:RecipeGroupNew(player, tradeID, label)
				if not mainGroup.initialized then
					local unknownCount = 0
					local knownCount = 0
					mainGroup.initialized = true
					local rank = rankData.rank
					-- first, accumulate all skill data
					for id, skill in pairs(Skillet.data.skillList[player][tradeID]) do
						if type(id) == "number" and type(skill) == "table" then
							local recipeID = skill.id
							if skill.id then
								local spellID = skill.id
								unknownRecipes[spellID] = spellID
								unknownCount = unknownCount + 1
							end
						end
					end
					-- then, move over all known recipes for this toon
					local numSkills = #Skillet.db.realm.skillDB[label][tradeID]
					for i=1, numSkills do
						local skill = Skillet:GetSkill(label, tradeID, i)
						if skill and skill.id ~= 0 then
							local spellID = skill.id
							knownRecipes[spellID] = spellID
							unknownRecipes[spellID] = nil
							unknownCount = unknownCount - 1
							knownCount = knownCount + 1
						end
					end
					if knownCount > 0 then
						local knownGroup = Skillet:RecipeGroupNew(player, tradeID, label, "Known Recipes")
						Skillet:RecipeGroupAddSubGroup(mainGroup, knownGroup, 1)
						for spellID,recipeID in pairs(knownRecipes) do
							local index = Skillet.data.skillIndexLookup[player][recipeID]
							local entry = Skillet:RecipeGroupAddRecipe(knownGroup, recipeID, index)
							entry.color = Skillet:GetTradeSkillLevelColor(spellID, rank)
							if entry.color then
								entry.difficulty = entry.color.level
							end
						end
					end
					if unknownCount > 0 then
						local unknownGroup = Skillet:RecipeGroupNew(player, tradeID, label, "Unknown Recipes")
						Skillet:RecipeGroupAddSubGroup(mainGroup, unknownGroup, 2)
						for spellID,recipeID in pairs(unknownRecipes) do
							local index = Skillet.data.skillIndexLookup[player][recipeID]
							local entry = Skillet:RecipeGroupAddRecipe(unknownGroup, recipeID, index)
							entry.color = Skillet:GetTradeSkillLevelColor(spellID, rank)
							if entry.color then
								entry.difficulty = entry.color.level
							end
						end
					end
				end
			end
		end
	end
	knownRecipes = nil
	unknownRecipes = nil
	DA.DEBUG(0,"done making groups")
end

function SkilletData:RecipeGroupGenerateAutoGroups()
	Skillet:GenerateAltKnowledgeBase()
end

function SkilletLink:RecipeGroupGenerateAutoGroups()
	Skillet:GenerateAltKnowledgeBase()
end

-- arl hooks
SkilletARL = {}
local function initFilterButton(name, icon, parent, slot)
	local b = CreateFrame("CheckButton", name)
	b:SetWidth(20)
	b:SetHeight(20)
	b:SetParent(parent)
	b:SetNormalTexture(icon)
	b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetFrameLevel(parent:GetFrameLevel()+5)
	b:SetScript("OnEnter", function(button) SkilletARL:RecipeFilterButton_OnEnter(button) end)
	b:SetScript("OnLeave", function(button) SkilletARL:RecipeFilterButton_OnLeave(button) end)
	b:SetScript("OnClick", function(button) SkilletARL:RecipeFilterButton_OnClick(button) end)
	b:SetScript("OnShow", function(button) SkilletARL:RecipeFilterButton_OnShow(button) end)
	b.slot = slot
	return b
end

function SkilletARL:RecipeFilterButtons_Hide()
	local b = self.arlRecipeSourceButton
	if b then
		b.trainerButton:Hide()
		b.vendorButton:Hide()
		b.questButton:Hide()
		b.dropButton:Hide()
		b.mobButton:Hide()
		b.unknownButton:Hide()
	end
end

function SkilletARL:RecipeFilterButtons_Show()
	local b = self.arlRecipeSourceButton
	if b then
		b.trainerButton:Show()
		b.vendorButton:Show()
		b.questButton:Show()
		b.dropButton:Show()
		b.mobButton:Show()
		b.unknownButton:Show()
	end
end

function SkilletARL:RecipeFilterButton_OnClick(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	Skillet:ToggleTradeSkillOption(option)
	self:RecipeFilterButton_OnEnter(button)
	self:RecipeFilterButton_OnShow(button)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function SkilletARL:RecipeFilterButton_OnEnter(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	local value = Skillet:GetTradeSkillOption(option)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	if value then
		GameTooltip:SetText(slot.." on")
	else
		GameTooltip:SetText(slot.." off")
	end
--	GameTooltip:AddLine(player,1,1,1)
	GameTooltip:Show()
end

function SkilletARL:RecipeFilterButton_OnLeave(button)
	GameTooltip:Hide()
end

function SkilletARL:RecipeFilterButton_OnShow(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	local value = Skillet:GetTradeSkillOption(option)
	if value then
		button:SetChecked(1)
	else
		button:SetChecked(0)
	end
end

function SkilletARL:RecipeFilterToggleButton_OnShow(button)
	local filter = Skillet:GetTradeSkillOption("recipeSourceFilter")
DA.CHAT("show filter toggle")
	if filter then
		button:SetChecked(1)
	else
		button:SetChecked(0)
	end
end

function SkilletARL:RecipeFilterToggleButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:SetText("Filter recipes by source", nil, nil, nil, nil, 1)
	GameTooltip:AddLine("Left-Click to toggle", .7, .7, .7)
	GameTooltip:AddLine("Right-Click for filtering options", .7, .7, .7)
	GameTooltip:Show()
	GameTooltip:Show()
end

function SkilletARL:RecipeFilterToggleButton_OnLeave(button)
	GameTooltip:Hide()
end

function SkilletARL:RecipeFilterToggleButton_OnClick(button, mouse)
	if mouse=="LeftButton" then
		SkilletARL:RecipeFilterButtons_Hide()
		if button:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn");
		end
		local before = Skillet:GetTradeSkillOption("recipeSourceFilter")
		Skillet:SetTradeSkillOption("recipeSourceFilter", not before)
		Skillet:SortAndFilterRecipes()
		Skillet:UpdateTradeSkillWindow()
	else
		if ARLRecipeSourceTrainerButton:IsVisible() then
			SkilletARL:RecipeFilterButtons_Hide()
		else
			SkilletARL:RecipeFilterButtons_Show()
		end
		if Skillet:GetTradeSkillOption("recipeSourceFilter") then
			button:SetChecked(1)
		else
			button:SetChecked(0)
		end
	end
end

function SkilletARL:RecipeSourceButtonInit()
	if not self.arlRecipeSourceButton then
		local b = CreateFrame("CheckButton", "ARLRecipeSourceFilterButton")
		b:SetWidth(20)
		b:SetHeight(20)
		b:SetNormalTexture("Interface\\Icons\\INV_Scroll_03")
		b:SetPushedTexture("Interface\\Icons\\INV_Scroll_03")
		b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
		b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		b:SetDisabledTexture("Interface\\Icons\\INV_Scroll_03")
		b:RegisterForClicks("LeftButtonUp", "RightButtonDown")
		self.arlRecipeSourceButton = b
		b:SetScript("OnClick", function(self,button) SkilletARL:RecipeFilterToggleButton_OnClick(self, button) end)
		b:SetScript("OnEnter", function(self) SkilletARL:RecipeFilterToggleButton_OnEnter(self) end)
		b:SetScript("OnLeave", function(self) SkilletARL:RecipeFilterToggleButton_OnLeave(self) end)
		b:SetScript("OnShow", function(self) SkilletARL:RecipeFilterToggleButton_OnShow(self) end)
		b.trainerButton = initFilterButton("ARLRecipeSourceTrainerButton", "Interface\\Addons\\Skillet\\Icons\\vendor_icon.tga", b, "trainer")
		b.trainerButton:SetPoint("TOP", b:GetName(), "BOTTOM", -50,0)
		b.trainerButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.vendorButton = initFilterButton("ARLRecipeSourceVendorButton", "Interface\\Addons\\Skillet\\Icons\\vendor_icon.tga", b, "vendor")
		b.vendorButton:SetPoint("LEFT", "ARLRecipeSourceTrainerButton", "RIGHT", 0,0)
		b.vendorButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.questButton = initFilterButton("ARLRecipeSourceQuestButton", "Interface\\Icons\\INV_Misc_Map_01", b, "quest")
		b.questButton:SetPoint("LEFT", "ARLRecipeSourceVendorButton", "RIGHT", 0,0)
		b.questButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.dropButton = initFilterButton("ARLRecipeSourceDropButton", "Interface\\Icons\\Ability_DualWield", b, "drop")
		b.dropButton:SetPoint("LEFT", "ARLRecipeSourceQuestButton", "RIGHT", 0,0)
		b.dropButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.mobButton = initFilterButton("ARLRecipeSourceMobButton", "Interface\\Icons\\INV_Scroll_06", b, "mob")
		b.mobButton:SetPoint("LEFT", "ARLRecipeSourceDropButton", "RIGHT", 0,0)
		b.mobButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.unknownButton = initFilterButton("ARLRecipeSourceUnknownButton", "Interface\\Icons\\INV_Misc_QuestionMark", b, "unknown")
		b.unknownButton:SetPoint("LEFT", "ARLRecipeSourceMobButton", "RIGHT", 0,0)
		b.unknownButton:SetFrameLevel(b:GetFrameLevel()+5)
	end
	local _,_,icon = GetSpellInfo(Skillet.currentTrade)
	if icon then
		self.arlRecipeSourceButton.trainerButton:SetNormalTexture(icon)
	end
	self:RecipeFilterButtons_Hide()
	return self.arlRecipeSourceButton
end

local ARLProfessionInitialized = {}
-- return true if the skill needs to be filtered out
function SkilletARL:RecipeFilterOperator(skillIndex)
	return false
end

function SkilletARL:RecipeFilterOperatorOLD(skillIndex)
	if Skillet:GetTradeSkillOption("recipeSourceFilter") then
		local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, skillIndex)
		local _, recipeList, mobList, trainerList = AckisRecipeList:InitRecipeData()
		local recipeData = AckisRecipeList:GetRecipeData(skill.id)
		if recipeData == nil and not ARLProfessionInitialized[Skillet.currentTrade] then
			local profession = GetSpellInfo(Skillet.currentTrade)
			AckisRecipeList:AddRecipeData(profession)
			ARLProfessionInitialized[Skillet.currentTrade] = true
			recipeData = AckisRecipeList:GetRecipeData(skill.id)
		end
		if recipeData then
			local recipeSource = recipeData["Acquire"]
			for i,data in pairs(recipeSource) do
				if data["Type"] == 1 and Skillet:GetTradeSkillOption("recipeSourceFilter-trainer") then
					return false
				end
				if data["Type"] == 2 and Skillet:GetTradeSkillOption("recipeSourceFilter-vendor") then
					return false
				end
				if data["Type"] == 3 and Skillet:GetTradeSkillOption("recipeSourceFilter-mob") then
					return false
				end
				if data["Type"] == 4 and Skillet:GetTradeSkillOption("recipeSourceFilter-quest") then
					return false
				end
				if data["Type"] == 5 and Skillet:GetTradeSkillOption("recipeSourceFilter-drop") then
					return false
				end
			end
		else
			if Skillet:GetTradeSkillOption("recipeSourceFilter-unknown") then
				return false
			end
		end
		return true
	end
	return false
end

function SkilletARL:Enable()
	-- if AckisRecipeList then
	if false then
		Skillet:RegisterRecipeFilter("arlRecipeSource", self, self.RecipeSourceButtonInit, self.RecipeFilterOperator)
		Skillet.defaultOptions["recipeSourceFilter"] = false
		Skillet.defaultOptions["recipeSourceFilter-drop"] = true
		Skillet.defaultOptions["recipeSourceFilter-vendor"] = true
		Skillet.defaultOptions["recipeSourceFilter-trainer"] = true
		Skillet.defaultOptions["recipeSourceFilter-quest"] = true
		Skillet.defaultOptions["recipeSourceFilter-mob"] = true
		Skillet.defaultOptions["recipeSourceFilter-unknown"] = true
	end
end
