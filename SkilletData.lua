local addonName,addonTable = ...
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

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end
local PT = LibStub("LibPeriodicTable-3.1")
local L = Skillet.L

--[[ == Global Tables == ]]--
-- (moved to SkilletTables.lua) --

--[[ == Local Tables == ]]--

--
-- A table of tradeskills by id. This local table will be converted by
-- Skillet:CollectTradeSkillData() into localized tables tradeSkillIDsByName and tradeSkillNamesByID
--
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
}

local DifficultyNum = {
	[0] = "optimal",
	[1] = "medium",
	[2] = "easy",
	[3] = "trivial",
}

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
Skillet.skill_style_type = skill_style_type

function Skillet:GetTradeSkillInfo(index)
	--DA.PROFILE("Skillet:GetTradeSkillInfo("..tostring(index)..")")
-- index is now a recipeID
-- GetTradeSkillInfo returned:
-- skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps, indentLevel, showProgressBar, currentRank, maxRank, startingRank
	if index then
		local info = C_TradeSkillUI.GetRecipeInfo(index)
		if info then
			--DA.DEBUG(0,"GetTradeSkillInfo: index= "..tostring(index)..", info= "..DA.DUMP1(info))
			local tradeSkillID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier = C_TradeSkillUI.GetTradeSkillLineForRecipe(index)
			--DA.DEBUG(0,"GetTradeSkillInfo: tradeSkillID= "..tostring(tradeSkillID)..", skillLineName= "..tostring(skillLineName)..", skillLineRank= "..tostring(skillLineRank)..", skillLineMaxRank= "..tostring(skillLineMaxRank)..", skillLineModifier= "..tostring(skillLineModifier))
			return info.name, DifficultyNum[info.relativeDifficulty], info.numAvailable, false, info.alternateVerb, info.numSkillUps, info.numIndents, false, skillLineRank, skillLineMaxRank, nil
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

function Skillet:GetAutoTargetMacro(addSpellID, toy, pet, petGUID)
	DA.DEBUG(0,"GetAutoTargetMacro("..tostring(addSpellID)..", "..tostring(toy)..", "..tostring(pet)..", "..tostring(petGUID)..")")
	if toy then
		local _, name = C_ToyBox.GetToyInfo(addSpellID)
		return "/cast "..(name or "")
	elseif pet then
		return "/run C_PetJournal.SummonPetByGUID('"..tostring(petGUID).."')"
	else
		local itemID = Skillet:GetAutoTargetItem(addSpellID)
		if itemID then
			return "/cast "..(GetSpellInfo(addSpellID) or "").."\n/use "..(GetItemInfo(itemID) or "")
		else
			return "/cast "..(GetSpellInfo(addSpellID) or "")
		end
	end
end

--
-- Adds an recipe source for an itemID (recipeID produces itemID)
--
function Skillet:ItemDataAddRecipeSource(itemID,recipeID)
	if not itemID or not recipeID then return end
--	if not self.db.global.itemRecipeSource then
--		self.db.global.itemRecipeSource = {}
--	end
	if not self.db.global.itemRecipeSource[itemID] then
		self.db.global.itemRecipeSource[itemID] = {}
	end
	if itemID == recipeID then
		--DA.DEBUG(0,"ItemDataAddRecipeSource: (itemID == recipeID)="..tostring(itemID))
	end
	self.db.global.itemRecipeSource[itemID][recipeID] = true
end

--
-- Adds a recipe usage for an itemID (recipeID uses itemID as a reagent)
--
function Skillet:ItemDataAddUsedInRecipe(itemID,recipeID)
	if not itemID or not recipeID or itemID == 0 then return end
--	if not self.db.global.itemRecipeUsedIn then
--		self.db.global.itemRecipeUsedIn = {}
--	end
	if not self.db.global.itemRecipeUsedIn[itemID] then
		self.db.global.itemRecipeUsedIn[itemID] = {}
	end
	self.db.global.itemRecipeUsedIn[itemID][recipeID] = true
end

--
-- Goes thru the stored recipe list and collects reagent and item information as well as skill lookups
--
function Skillet:CollectRecipeInformation()
	for recipeID, recipeString in pairs(self.db.global.recipeDB) do
		local tradeID, itemString, reagentString, toolString, numOptional = string.split(" ",recipeString)
		local itemID = 0
		local numMade = 1
		if itemString ~= "0" then
			local a, b = string.split(":",itemString)
			if a ~= "0" then
				itemID, numMade = a,b
			else
				itemID = 0
				numMade = 1
			end
			if not numMade then
				numMade = 1
			end
		end
		itemID = tonumber(itemID)
		if itemID ~= 0 then
			if itemID == recipeID then
				--DA.DEBUG(0,"CollectRecipeInformation: (itemID == recipeID)="..tostring(itemID))
			end
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
		self.data.skillIndexLookup = {}
		for trade,skillList in pairs(self.data.skillDB) do
			for i=1,#skillList do
				local skillString = self.data.skillDB[trade][i]
				if skillString then
					local skillData = string.split(" ",skillString)
					if skillData ~= "header" or skillData ~= "subheader" then
						local recipeID = string.sub(skillData,2)
						recipeID = tonumber(recipeID) or 0
						self.data.skillIndexLookup[recipeID] = i
					end
				end
			end
		end
end

--
-- Resets the blizzard tradeskill search filters just to make sure no other addon has monkeyed with them
--
function Skillet:ResetTradeSkillFilter()
	--DA.PROFILE("Skillet:ResetTradeSkillFilter()")
	Skillet:SetTradeSkillOption("hideuncraftable", false)
	Skillet:SetTradeSkillOption("filterLevel", 1)
end

function Skillet:SetTradeSkillLearned()
	Skillet:SetGroupSelection(nil)
	Skillet.unlearnedRecipes = false
	Skillet.selectedSkill = nil
	Skillet:FilterDropDown_OnShow()
end

function Skillet:SetTradeSkillUnlearned()
	Skillet:SetGroupSelection(nil)
	Skillet.unlearnedRecipes = true
	Skillet.selectedSkill = nil
	Skillet:FilterDropDown_OnShow()
end

local function GetUnfilteredSubCategoryName(categoryID, ...)
	local anyAreFiltered = false
	for i = 1, select("#", ...) do
		local subCategoryID = select(i, ...)
		if C_TradeSkillUI.IsRecipeCategoryFiltered(categoryID, subCategoryID) then
			anyAreFiltered = true
			break
		end
	end
	if anyAreFiltered then
		for i = 1, select("#", ...) do
			local subCategoryID = select(i, ...)
			if not C_TradeSkillUI.IsRecipeCategoryFiltered(categoryID, subCategoryID) then
				local subCategoryData
				if Skillet.db.global.Categories and tradeID then
					subCategoryData = Skillet.db.global.Categories[tradeID][subCategoryID]
				else
					subCategoryData = C_TradeSkillUI.GetCategoryInfo(subCategoryID)
				end
				return subCategoryData.name
			end
		end
	end
	return nil
end

local function GetUnfilteredCategoryName(...)
	for i = 1, select("#", ...) do
		local categoryID = select(i, ...)
		local subCategoryName = GetUnfilteredSubCategoryName(categoryID, C_TradeSkillUI.GetSubCategories(categoryID))
		if subCategoryName then
			return subCategoryName
		end
	end
	for i = 1, select("#", ...) do
		local categoryID = select(i, ...)
		if not C_TradeSkillUI.IsRecipeCategoryFiltered(categoryID) then
			local categoryData
			if Skillet.db.global.Categories and tradeID then
				categoryData = Skillet.db.global.Categories[tradeID][categoryID]
			else
				categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)
			end
			return categoryData.name
		end
	end
	return nil
end

local function GetUnfilteredInventorySlotName(...)
	for i = 1, select("#", ...) do
		if not C_TradeSkillUI.IsInventorySlotFiltered(i) then
			local inventorySlot = select(i, ...);
			return inventorySlot;
		end
	end
	return nil;
end

function Skillet:PrintTradeSkillFilter()
	DA.DEBUG(0,"PrintTradeSkillFilter()")
end

function Skillet:ExpandTradeSkillSubClass(i)
	--DA.DEBUG(0,"ExpandTradeSkillSubClass("..tostring(i)..")")
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
	--DA.DEBUG(0,"GetRecipe("..tostring(id)..")")
	if id and id ~= 0 then
		if Skillet.data.recipeList[id] then
			return Skillet.data.recipeList[id]
		end
		if Skillet.db.global.recipeDB[id] then
			local recipeString = Skillet.db.global.recipeDB[id]
			--DA.DEBUG(0,"recipeString= "..tostring(recipeString))
			local tradeID, itemString, reagentString, toolString, numOptional = string.split(" ",recipeString)
			--DA.DEBUG(0,"numOptional= "..tostring(numOptional))
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
				--DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			Skillet.data.recipeList[id] = {}
			Skillet.data.recipeList[id].spellID = tonumber(id)
			Skillet.data.recipeList[id].name = GetSpellInfo(tonumber(id))
			Skillet.data.recipeList[id].tradeID = tonumber(tradeID)
			Skillet.data.recipeList[id].itemID = tonumber(itemID)
			if Skillet.db.global.AdjustNumMade and Skillet.db.global.AdjustNumMade[id] then
				Skillet.data.recipeList[id].numMade = Skillet.db.global.AdjustNumMade[id]
			else
				Skillet.data.recipeList[id].numMade = tonumber(numMade)
			end
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
				--DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
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
				--DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			if numOptional then
				Skillet.data.recipeList[id].numOptional = numOptional
				--DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..DA.DUMP1(Skillet.data.recipeList[id]))
			else
				--DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			return Skillet.data.recipeList[id]
		end
	end
	return Skillet.unknownRecipe
end

function Skillet:GetNumSkills(player, trade)
	--DA.DEBUG(0,"GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	--DA.PROFILE("Skillet:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	local r
	if not Skillet.data.skillDB then
		r = 0
	elseif not Skillet.data.skillDB[trade] then
		r = 0
	else
		r = #Skillet.data.skillDB[trade]
	end
	--DA.DEBUG(2,"r= "..tostring(r))
	return r
end

function Skillet:GetSkillRanks(player, trade)
	--DA.DEBUG(0,"Skillet:GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	--DA.PROFILE("Skillet:GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	if player and trade then
		if Skillet.db.realm.tradeSkills[player] then
			return Skillet.db.realm.tradeSkills[player][trade]
		end
	end
end

function Skillet:GetSkill(player,trade,index)
	--DA.DEBUG(0,"GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	--DA.PROFILE("Skillet:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	if player and trade and index then
		if not Skillet.data.skillList[trade] then
			Skillet.data.skillList[trade] = {}
		end
		if not Skillet.data.skillList[trade][index] and Skillet.data.skillDB[trade][index] then
			local skillString = Skillet.data.skillDB[trade][index]
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
				Skillet.data.skillList[trade][index] = skill
			end
		end
		return Skillet.data.skillList[trade][index]
	end
	return self.unknownRecipe
end

--
-- Collects generic tradeskill data (id to name and name to id)
--
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
	--DA.DEBUG(1,"tradeSkillIDsByName= "..DA.DUMP(self.tradeSkillIDsByName))
	--DA.DEBUG(1,"tradeSkillNamesByID= "..DA.DUMP(self.tradeSkillNamesByID))
end

--
-- Collects currency data (id to name and name to id)
--
function Skillet:CollectCurrencyData()
	DA.DEBUG(0,"CollectCurrencyData()")
	self.currencyIDsByName = {}
	self.currencyNamesByID = {}
	local maxCurrency = C_CurrencyInfo.GetCurrencyListSize()
	for i=1,maxCurrency,1 do
		local info = C_CurrencyInfo.GetCurrencyListInfo(i)
		--DA.DEBUG(1,"CollectCurrencyData: info= "..DA.DUMP1(info))
		local name = info.name
		local isHeader = info.isHeader
		local currencyLink = C_CurrencyInfo.GetCurrencyListLink(i)
		local currencyID = Skillet:GetItemIDFromLink(currencyLink)
		if not isHeader and currencyID and name then
			self.currencyIDsByName[name] = currencyID
			self.currencyNamesByID[currencyID] = name
		end
	end
end

--
-- Collects the basic data (which tradeskills a player has)
--
function Skillet:ScanPlayerTradeSkills(player)
	DA.DEBUG(0,"Skillet:ScanPlayerTradeSkills("..tostring(player)..")")
	if player == (UnitName("player")) then -- only for active player
		if not self.db.realm.tradeSkills then
			self.db.realm.tradeSkills = {}
		end
		if not self.db.realm.tradeSkills[player] then
			self.db.realm.tradeSkills[player] = {}
		end
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		--DA.DEBUG(3,"ScanPlayerTradeSkills: prof1= "..tostring(prof1)..", prof2= "..tostring(prof2)..", archaeology= "..tostring(archaeology)..", fishing= "..tostring(fishing)..", cooking= "..tostring(cooking)..", firstAid= "..tostring(firstAid))
		if prof1 then
			local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof1)
			--DA.DEBUG(3,"ScanPlayerTradeSkills: prof1 name= "..tostring(name)..", icon= "..tostring(icon)..", skillLevel= "..tostring(skillLevel)..", maxSkillLevel= "..tostring(maxSkillLevel)..", numAbilities= "..tostring(numAbilities)..", spelloffset= "..tostring(spelloffset)..", skillLine= "..tostring(skillLine)..", skillModifier= "..tostring(skillModifier)..", specializationIndex= "..tostring(specializationIndex)..", specializationOffset= "..tostring(specializationOffset))
		end
		if prof2 then
			local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof2)
			--DA.DEBUG(3,"ScanPlayerTradeSkills: prof2 name= "..tostring(name)..", icon= "..tostring(icon)..", skillLevel= "..tostring(skillLevel)..", maxSkillLevel= "..tostring(maxSkillLevel)..", numAbilities= "..tostring(numAbilities)..", spelloffset= "..tostring(spelloffset)..", skillLine= "..tostring(skillLine)..", skillModifier= "..tostring(skillModifier)..", specializationIndex= "..tostring(specializationIndex)..", specializationOffset= "..tostring(specializationOffset))
		end
		if cooking then
			local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(cooking)
			--DA.DEBUG(3,"ScanPlayerTradeSkills: cooking name= "..tostring(name)..", icon= "..tostring(icon)..", skillLevel= "..tostring(skillLevel)..", maxSkillLevel= "..tostring(maxSkillLevel)..", numAbilities= "..tostring(numAbilities)..", spelloffset= "..tostring(spelloffset)..", skillLine= "..tostring(skillLine)..", skillModifier= "..tostring(skillModifier)..", specializationIndex= "..tostring(specializationIndex)..", specializationOffset= "..tostring(specializationOffset))
		end
		local skillRanksData = Skillet.db.realm.tradeSkills[player]
		for i=1,#TradeSkillList,1 do
			local id = TradeSkillList[i]
			--DA.DEBUG(3,"ScanPlayerTradeSkills: id= "..tostring(id))
			local name = GetSpellInfo(id)			-- always returns data
			local name = GetSpellInfo(name)			-- only returns data if you have this spell in your spellbook
			--DA.DEBUG(3,"ScanPlayerTradeSkills: name= "..tostring(name))
			if name then
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
	end
end

--
-- Takes a profession and a skill index and returns the recipe
--
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

function Skillet:CalculateCraftableCounts()
	DA.DEBUG(0,"CalculateCraftableCounts()")
	local player = self.currentPlayer
	if player ~= UnitName("player") then
		return
	end
	self.visited = {}
	local n = self:GetNumSkills(player, self.currentTrade)
	if n then
		for i=1,n do
			local skill = self:GetSkill(player, self.currentTrade, i)
			if skill and skill.id ~= 0 then -- skip headers
				local recipe = self:GetRecipe(skill.id)
				if recipe and recipe.reagentData and #recipe.reagentData > 0 then	-- make sure that recipe is in the database before continuing
					skill.numCraftable, skill.numRecursive, skill.numCraftableVendor, skill.numCraftableAlts = self:InventorySkillIterations(self.currentTrade, recipe)
					--DA.DEBUG(2,"name= "..tostring(skill.name)..", numCraftable= "..tostring(skill.numCraftable)..", numRecursive= "..tostring(skill.numRecursive)..", numCraftableVendor= "..tostring(skill.numCraftableVendor)..", numCraftableAlts= "..tostring(skill.numCraftableAlts))
				end
			end
		end
	end
	--DA.DEBUG(0,"CalculateCraftableCounts: #visited= "..tostring(#self.visited))
end

function Skillet:IsFavorite(recipeID)
	local info = self.data.recipeInfo
	return info and info[self.currentTrade] and info[self.currentTrade][recipeID] and info[self.currentTrade][recipeID].favorite
end

function Skillet:ToggleFavorite(recipeID)
	local recipeInfo = self.data.recipeInfo[self.currentTrade][recipeID]
	if C_TradeSkillUI.GetOnlyShowLearnedRecipes() then
		recipeInfo.favorite = not recipeInfo.favorite
		C_TradeSkillUI.SetRecipeFavorite(recipeID, recipeInfo.favorite)
	end
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
--
-- Start by going backwards from this node until we find the first in the line
--
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
--
-- Now move forward from this node until the end
--
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

--
-- Get the Categories this player knows
-- (should probably be moved to the realm database)
--
local function GetMyCategories(player, tradeID)
	DA.DEBUG(0,"GetMyCategories("..tostring(player)..", "..tostring(tradeID)..")")
	if not Skillet.db.global.Categories[tradeID] then
		Skillet.db.global.Categories[tradeID] = {}
	end
	local categories = { C_TradeSkillUI.GetCategories() }
	--DA.DEBUG(1,"GetMyCategories: categories= "..DA.DUMP1(categories))
	for i, categoryID in ipairs(categories) do
		local catInfo = C_TradeSkillUI.GetCategoryInfo(categoryID)
		--DA.DEBUG(2,"GetMyCategories: i= "..tostring(i)..", categoryID= "..tostring(categoryID)..", catInfo.name= "..tostring(catInfo.name))
		--DA.DEBUG(3,"GetMyCategories: catInfo= "..DA.DUMP1(catInfo))
		Skillet.db.global.Categories[tradeID][categoryID] = catInfo
		local subCategories = { C_TradeSkillUI.GetSubCategories(categoryID) }
		--DA.DEBUG(4,"GetMyCategories: subCategories= "..DA.DUMP1(subCategories))
		for j, subCategory in ipairs(subCategories) do
			local subCatInfo = C_TradeSkillUI.GetCategoryInfo(subCategory)
			--DA.DEBUG(3,"GetMyCategories: j= "..tostring(j)..", subCategory= "..tostring(subCategory)..", subCatInfo.name= "..tostring(subCatInfo.name))
			--DA.DEBUG(4,"GetMyCategories: subCatInfo= "..DA.DUMP1(subCatInfo))
			Skillet.db.global.Categories[tradeID][subCategory] = subCatInfo

			local subsubCategories = { C_TradeSkillUI.GetSubCategories(subCategory) }
			--DA.DEBUG(5,"GetMyCategories: subsubCategories= "..DA.DUMP1(subsubCategories))
			for k, subsubCategory in ipairs(subsubCategories) do
				local subsubCatInfo = C_TradeSkillUI.GetCategoryInfo(subsubCategory)
				--DA.DEBUG(4,"GetMyCategories: k= "..tostring(k)..", subsubCategory= "..tostring(subsubCategory)..", subsubCatInfo.name= "..tostring(subsubCatInfo.name))
				--DA.DEBUG(5,"GetMyCategories: subsubCatInfo= "..DA.DUMP1(subsubCatInfo))
				Skillet.db.global.Categories[tradeID][subsubCategory] = subsubCatInfo

				local subsubsubCategories = { C_TradeSkillUI.GetSubCategories(subsubCategory) }
				if #subsubsubCategories > 0 then
					DA.DEBUG(0,"GetMyCategories: too many subCategory levels")
				end
			end
		end
	end
end

local function GetEmptyCategories(player,tradeID)
	--DA.DEBUG(0,"GetEmptyCategories("..tostring(player)..", "..tostring(tradeID)..")")
	Skillet.emptyCategoriesToAdd = {}
	local count = 0
	--DA.DEBUG(0,"GetEmptyCategories: "..tostring(count).." emptyCategoriesToAdd= "..DA.DUMP(Skillet.emptyCategoriesToAdd))
end

--
-- Builds a list of categories and recipes based on the current filter
--
local function GetRecipeList(player, tradeID)
	DA.DEBUG(0,"GetRecipeList("..tostring(player)..", "..tostring(tradeID)..")")
	local numLearned = 0
	local numUnlearned = 0
	local dataList = {}
	local currentCategoryID, currentParentCategoryID
	local categoryData, parentCategoryData
	local isCurrentCategoryEnabled, isCurrentParentCategoryEnabled = true, true
	Skillet.recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
--	Skillet.invertedRecipeIDs = tInvert(recipeIDs)
	local recipeIDs = Skillet.recipeIDs
--	local invertedRecipeIDs = Skillet.invertedRecipeIDs
	DA.DEBUG(0,"GetRecipeList: #recipeIDs= "..tostring(#recipeIDs))
	for i, recipeID in ipairs(recipeIDs) do
		local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
		DA.DEBUG(3,"GetRecipeList: i= "..tostring(i)..", recipeID= "..tostring(recipeID)..", recipeInfo.name= "..tostring(recipeInfo.name))
		if recipeInfo.learned then
			numLearned = numLearned + 1
			--DA.DEBUG(3,"GetRecipeList: i= "..tostring(i)..", recipeID= "..tostring(recipeID)..", recipeInfo= "..DA.DUMP1(recipeInfo))
			if recipeInfo.categoryID ~= currentCategoryID then
				currentCategoryID = recipeInfo.categoryID
				categoryData = Skillet.db.global.Categories[tradeID][currentCategoryID]
				--DA.DEBUG(3,"GetRecipeList: categoryData= "..DA.DUMP1(categoryData))
				--DA.DEBUG(3,"GetRecipeList: categoryData.name= "..tostring(categoryData.name)..", type= "..tostring(categoryData.type)..", uiOrder= "..tostring(categoryData.uiOrder))
				isCurrentCategoryEnabled = categoryData.enabled
				if categoryData.parentCategoryID ~= currentParentCategoryID then
					--DA.DEBUG(3,"GetRecipeList: categoryData.parentCategoryID= "..tostring(categoryData.parentCategoryID))
					currentParentCategoryID = categoryData.parentCategoryID
					if currentParentCategoryID then
						parentCategoryData = Skillet.db.global.Categories[tradeID][currentParentCategoryID]
						--DA.DEBUG(3,"GetRecipeList: parentCategoryData= "..DA.DUMP1(parentCategoryData))
						--DA.DEBUG(3,"GetRecipeList: parentCategoryData.name= "..tostring(parentCategoryData.name)..", type= "..tostring(parentCategoryData.type)..", uiOrder= "..tostring(parentCategoryData.uiOrder))
						isCurrentParentCategoryEnabled = parentCategoryData.enabled
					else
						isCurrentParentCategoryEnabled = true
					end
				else
					--DA.DEBUG(3,"GetRecipeList: categoryData.parentCategoryID equals currentParentCategoryID")
				end
			end
			if isCurrentCategoryEnabled and isCurrentParentCategoryEnabled then
				--DA.DEBUG(3,"GetRecipeList: insert recipeID= "..tostring(recipeID)..", recipeInfo.name= "..tostring(recipeInfo.name))
				table.insert(dataList, recipeID)
			end
		else
			numUnlearned = numUnlearned + 1
		end
	end
	DA.DEBUG(0,"GetRecipeList: numLearned= "..tostring(numLearned)..", numUnlearned= "..tostring(numUnlearned))
	Skillet.dataList = dataList
	return dataList
	
end

--
-- Called by RescanTrade after initializing the tables
--
local function ScanTrade()
	--DA.PROFILE("ScanTrade()")
	DA.DEBUG(0,"ScanTrade()")
	local tradeID
	local link = C_TradeSkillUI.GetTradeSkillListLink()
	local parentSkillLineID, parentSkillLineName, skillLineRank, skillLineMaxRank
	local baseInfo = C_TradeSkillUI.GetBaseProfessionInfo()
	local childInfo = C_TradeSkillUI.GetChildProfessionInfo()
	DA.DEBUG(1,"ScanTrade: GetBaseProfessionInfo()= "..DA.DUMP1(baseInfo))
	DA.DEBUG(1,"ScanTrade: GetChildProfessionInfo()= "..DA.DUMP1(childInfo))
	if childInfo and childInfo.parentProfessionID then 
		parentSkillLineID = childInfo.parentProfessionID
		parentSkillLineName = childInfo.parentProfessionName
		skillLineRank = childInfo.skillLevel
		skillLineMaxRank = childInfo.maxSkillLevel
	elseif baseInfo and baseInfo.professionID then
		parentSkillLineID = baseInfo.professionID
		parentSkillLineName = baseInfo.professionName
		skillLineRank = baseInfo.skillLevel
		skillLineMaxRank = baseInfo.maxSkillLevel
	else
		return false
	end

	if Skillet.BlizzardSkillList[parentSkillLineID] then
		DA.CHAT("Skillet cannot display "..tostring(parentSkillLineName)..", use the Blizzard UI")
		Skillet.useBlizzard = true
		Skillet.currentTrade = nil
		Skillet:SkilletClose()
		return false
	end
	tradeID = Skillet.SkillLineIDList[parentSkillLineID]	-- names are localized so use a table to translate
	local profession = Skillet.tradeSkillNamesByID[tradeID]
	DA.DEBUG(1,"ScanTrade: tradeID= "..tostring(tradeID)..", profession= "..tostring(profession))
	if link then
		DA.DEBUG(1,"ScanTrade: "..tostring(skillLineName).." link="..link.." "..DA.PLINK(link))
	else
		DA.DEBUG(1,"ScanTrade: "..tostring(skillLineName).." not linkable")
	end
	local player = Skillet.currentPlayer
	if not player or not tradeID then
		DA.CHAT("ScanTrade: abort! player= "..tostring(player)..", tradeID= "..tostring(tradeID)..
			", parentSkillLineID= "..tostring(parentSkillLineID)..", parentSkillLineName= "..tostring(parentSkillLineName))
		Skillet.scanInProgress = false
		Skillet.currentTrade = nil
		return false
	end
	Skillet.currentTrade = tradeID
	if not Skillet.data.skillList[tradeID] then
		Skillet.data.skillList[tradeID]={}
	end
	if not Skillet.data.Filtered[tradeID] then
		Skillet.data.Filtered[tradeID] = {}
	end
	if not Skillet.data.skillDB[tradeID] then
		Skillet.data.skillDB[tradeID] = {}
	end
	if not Skillet.data.recipeInfo[tradeID] then
		Skillet.data.recipeInfo[tradeID] = {}
	end
	if not Skillet.db.global.Categories[tradeID] then
		Skillet.db.global.Categories[tradeID] = {}
	end
	Skillet.db.realm.tradeSkills[player][tradeID] = {}
	Skillet.db.realm.tradeSkills[player][tradeID].link = link
	--DA.DEBUG(1,"ScanTrade: skillLineRank= "..tostring(skillLineRank)..", skillLineMaxRank= "..tostring(skillLineMaxRank)..", profession= "..tostring(profession))
	Skillet.db.realm.tradeSkills[player][tradeID].rank = skillLineRank
	Skillet.db.realm.tradeSkills[player][tradeID].maxRank = skillLineMaxRank
	Skillet.db.realm.tradeSkills[player][tradeID].name = profession
--
-- Capture Category data
--
	GetMyCategories(player, tradeID)
	GetEmptyCategories(player,tradeID)
	Skillet.hasProgressBar = {} -- table of (sub)headers in this list with progress bars (used in MainFrame.lua)

	Skillet:PrintTradeSkillFilter()
	local firstPass = {}
	firstPass = GetRecipeList(player, tradeID)
	local numSkills = #firstPass

	DA.DEBUG(0,"ScanTrade: Compressing, "..tostring(profession)..":"..tostring(tradeID).." "..tostring(numSkills).." recipes")
--
-- Build the Filtered list by removing all but the current upgradeable recipe (if we are looking at learned recipes)
-- Build a list of categories (headers) used for this set of filtered recipes
--
	Skillet.data.Filtered[tradeID] = {}
	local i = 0
	local headerUsed = {}
	for j = 1, numSkills do
		local id = firstPass[j]
		if id then
			local info = C_TradeSkillUI.GetRecipeInfo(id)
			if info then
				headerUsed[info.categoryID] = false
				info = Skillet:SetUpgradeLevels(info)
				if not Skillet.unlearnedRecipes and info.upgradeable then		-- for upgradeable recipes
					if info.recipeUpgrade == info.learnedUpgrade then		-- only keep the current one
						i = i + 1
						--DA.DEBUG(1,"ScanTrade: Adding upgradable recipe "..tostring(id)..", i= "..tostring(j))
						Skillet.data.recipeInfo[tradeID][id] = info
						Skillet.data.Filtered[tradeID][i] = id
					else
						--DA.DEBUG(1,"ScanTrade: Skipping upgradable recipe "..tostring(id)..", i= "..tostring(j))
					end
				else		-- not upgradeable
					i = i + 1
					--DA.DEBUG(1,"ScanTrade: Adding recipe "..tostring(id)..", i= "..tostring(j))
					Skillet.data.recipeInfo[tradeID][id] = info
					Skillet.data.Filtered[tradeID][i] = id
				end
			else		-- no info? probably never get here
				i = i + 1
				DA.DEBUG(1,"ScanTrade: Adding recipe with no info "..tostring(id)..", i= "..tostring(j))
				Skillet.data.Filtered[tradeID][i] = id
			end
		end
	end
	numSkills = i

	DA.DEBUG(0,"ScanTrade: Processing, "..tostring(profession)..":"..tostring(tradeID).." "..tostring(numSkills).." recipes")
	local skillDB = Skillet.data.skillDB[tradeID]
	local skillData = Skillet.data.skillList[tradeID]
	local recipeDB = Skillet.db.global.recipeDB
	local nameDB = Skillet.db.global.recipeNameDB
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
	local parent, parentGroup
	local i = 1
	for j = 1, numSkills, 1 do
		local recipeID = Skillet.data.Filtered[tradeID][j]
		local recipeInfo = Skillet.data.recipeInfo[tradeID][recipeID]
		--DA.DEBUG(1,"ScanTrade: j= "..tostring(j)..", tradeID= "..tostring(tradeID)..", recipeID= "..tostring(recipeID))
		--DA.DEBUG(1,"ScanTrade: j= "..tostring(j)..", tradeID= "..tostring(tradeID)..", recipeID= "..tostring(recipeID)..", recipeInfo= "..DA.DUMP1(recipeInfo))
		local skillName, skillType, _, isExpanded, _, _, _, _, _, _, _, displayAsUnavailable, _ = Skillet:GetTradeSkillInfo(recipeID);
		if displayAsUnavailable then skillType = "unavailable" end
		if not headerUsed[recipeInfo.categoryID] then
--
-- This category (header) hasn't been seen yet. Stack it (and its unseen parents)
--
			local category = recipeInfo.categoryID
			headerUsed[category] = true
			local headerType = Skillet.db.global.Categories[tradeID][category].type
			local headerName = Skillet.db.global.Categories[tradeID][category].name
			local headerUIOrder = Skillet.db.global.Categories[tradeID][category].uiOrder
			--DA.DEBUG(2,"ScanTrade: category="..tostring(category))
			local numCat = 1
			local catStack = {}
			catStack[numCat] = category
			while headerType == "subheader" do
				if Skillet.db.global.Categories[tradeID][category].parentCategoryID then
					parent = Skillet.db.global.Categories[tradeID][category].parentCategoryID
					if Skillet.db.global.Categories[tradeID][parent] then
						if not headerUsed[parent] then
							headerUsed[parent] = true
							numCat = numCat + 1
							catStack[numCat] = parent
						end
						--DA.DEBUG(3,"ScanTrade: tradeID= "..tostring(tradeID)..", parent="..tostring(parent)..", recipeID="..tostring(recipeID))
						--DA.DEBUG(3,"ScanTrade: Categories= "..DA.DUMP(Skillet.db.global.Categories[tradeID][parent]))
						headerType = Skillet.db.global.Categories[tradeID][parent].type
					else
						Skillet.db.global.Categories[tradeID][category].type = "header"
						headerType = "header"
					end
				end
				category = parent
			end -- while
			--DA.DEBUG(2,"ScanTrade: numCat= "..tostring(numCat)..", catStack= "..DA.DUMP1(catStack))
--
-- Make sure any base-level empty categories with higher priority are added.
--
			local emptyCategoriesToAdd = Skillet.emptyCategoriesToAdd
			if emptyCategoriesToAdd then
				--DA.DEBUG(2,"ScanTrade: emptyCategory= "..DA.DUMP1(emptyCategoriesToAdd[1]))
				local lastCat = catStack[numCat]
				--DA.DEBUG(2,"ScanTrade: catStack["..tostring(numCat).."]= "..DA.DUMP1(Skillet.db.global.Categories[tradeID][lastCat]))
				while (#emptyCategoriesToAdd > 0) and (emptyCategoriesToAdd[1].uiOrder < Skillet.db.global.Categories[tradeID][lastCat].uiOrder) do
					--DA.DEBUG(3,"ScanTrade: adding emptyCategory= "..tostring(emptyCategoriesToAdd[1].name)..", type= "..tostring(emptyCategoriesToAdd[1].type))
					parent = emptyCategoriesToAdd[1].categoryID
					if not headerUsed[parent] then
						headerUsed[parent] = true
						numCat = numCat + 1
						catStack[numCat] = parent
					end
					table.remove(emptyCategoriesToAdd, 1)
				end
				--DA.DEBUG(2,"ScanTrade: emptyCat= "..tostring(numCat)..", catStack= "..DA.DUMP1(catStack))
			end

			while numCat > 0 do
--
-- We have a stack of headers. Output them to the skillDB.
--
				category = catStack[numCat]
				headerType = Skillet.db.global.Categories[tradeID][category].type
				headerName = Skillet.db.global.Categories[tradeID][category].name
				--DA.DEBUG(2,"ScanTrade: headerType= "..tostring(headerType)..", headerName= "..tostring(headerName))
				local groupName
				if groupList[headerName] then
					groupList[headerName] = groupList[headerName]+1
					groupName = headerName..":"..groupList[headerName]
				else
					groupList[headerName] = 1
					groupName = headerName
				end
				--DA.DEBUG(2,"ScanTrade: groupList[headerName]= "..tostring(groupList[headerName])..", groupName= "..tostring(groupName))
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
			end -- while
		end -- headerUsed
		if currentGroup then
			Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, i)
		else
			Skillet:RecipeGroupAddRecipe(mainGroup, recipeID, i)
		end

--
-- break recipes into lists by profession for ease of sorting
--
		skillData[i] = {}
		skillData[i].name = skillName
		skillData[i].id = recipeID
		skillData[i].difficulty = skillType
		skillData[i].color = skill_style_type[skillType]
		--DA.DEBUG(0,"skillType= "..tostring(skillType)..", recipeID= "..tostring(recipeID))
		local skillDBString = (DifficultyChar[skillType] or "")..tostring(recipeID)
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
		Skillet.data.skillIndexLookup[recipeID] = i
		Skillet.data.recipeList[recipeID] = {}
		local itemString = "-"
		local reagentString = "-"
		local toolString = "-"
		local recipeString = "-"
		local recipe = Skillet.data.recipeList[recipeID]
		recipe.tradeID = tradeID
		recipe.spellID = recipeID
		recipe.name = skillName
		recipe.itemID = 0		-- Make sure this value exists
		recipe.numMade = 1		-- Make sure this value exists

		local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
		--DA.DEBUG(2,"recipeSchematic= "..DA.DUMP(recipeSchematic))
		local itemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		--DA.DEBUG(2,"recipeID= "..tostring(recipeID)..", itemLink = "..DA.PLINK(itemLink))
		recipeInfo.itemLink = itemLink	-- save a copy for our records
		if itemLink then
			local itemID = Skillet:GetItemIDFromLink(itemLink)
			--DA.DEBUG(2,"itemID= "..tostring(itemID))
			if (not itemID or tonumber(itemID) == 0) then
				DA.DEBUG(0,"recipeID= "..tostring(recipeID)..", itemID= "..tostring(itemID))
				itemID = 0
			end
			recipe.itemID = itemID
			recipeInfo.itemID = itemID		-- save a copy for our records
			if not recipeInfo.alternateVerb then
				local minMade = recipeSchematic.quantityMin
				local maxMade = recipeSchematic.quantityMax
				recipeInfo.minMade = minMade	-- save a copy for our records
				recipeInfo.maxMade = maxMade	-- save a copy for our records
				recipe.numMade = (minMade + maxMade)/2
				local adjustNumMade = Skillet.db.global.AdjustNumMade[recipeID]
				if adjustNumMade then
					if recipe.numMade ~= adjustNumMade then
						recipe.numMade = adjustNumMade
					else
						adjustNumMade = nil
					end
				end
			elseif recipeInfo.alternateVerb == ENSCRIBE then -- use the itemID of the scroll created by using the enchant on vellum
				DA.DEBUG(2,"ScanTrade: recipeID= "..tostring(recipeID)..", alternateVerb= "..tostring(recipeInfo.alternateVerb))
				recipeInfo.numMade = 1		-- save a copy for our records
				if Skillet.scrollData[recipeID] then					-- note that this table is maintained by datamining
					recipeInfo.itemID = Skillet.scrollData[recipeID]	-- save a copy for our records
					recipe.itemID = Skillet.scrollData[recipeID]
					itemID = Skillet.scrollData[recipeID]
				else
					DA.DEBUG(0,"ScanTrade: recipeID= "..tostring(recipeID).." has no scrollData")
				end
			else
				DA.DEBUG(2,"ScanTrade: recipeID= "..tostring(recipeID)..", alternateVerb= "..tostring(recipeInfo.alternateVerb))
				recipeInfo.numMade = 1		-- save a copy for our records
			end
			if recipe.numMade > 1 then
				itemString = itemID..":"..recipe.numMade
			else
				itemString = tostring(itemID)
			end
			if itemID == recipeID then
				DA.DEBUG(2,"ScanTrade: (itemID == recipeID)= "..tostring(itemID))
			end
			Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of this item
		else
			DA.DEBUG(2,"ScanTrade: recipeID= "..tostring(recipeID).." has no itemLink")
		end

		local basicData = {}
		local numBasic = 0
		local optionalData = {}
		local numOptional = 0
		local reagentString = "-"
		local numReagents = #recipeSchematic.reagentSlotSchematics
		for k = 1, numReagents do
			local schematic = recipeSchematic.reagentSlotSchematics[k]
			local reagentID = schematic.reagents[1].itemID
			local numNeeded = schematic.quantityRequired
			if schematic.reagentType == Enum.CraftingReagentType.Basic then
				numBasic = numBasic + 1
				basicData[numBasic] = {}
				basicData[numBasic].reagentID = reagentID
				basicData[numBasic].numNeeded = numNeeded
				basicData[numBasic].name = GetItemInfo(reagentID)
				basicData[numBasic].schematic = schematic
				if reagentString ~= "-" then
					reagentString = reagentString..":"..reagentID..":"..numNeeded
				else
					reagentString = reagentID..":"..numNeeded
				end
				Skillet:ItemDataAddUsedInRecipe(reagentID, recipeID)	-- add a cross reference for where a particular item is used
			elseif schematic.reagentType == Enum.CraftingReagentType.Optional then
				numOptional = numOptional + 1
				optionalData[numOptional] = {}
				optionalData[numOptional].numNeeded = numNeeded
				optionalData[numOptional].name = schematic.slotInfo.slotText
				optionalData[numOptional].schematic = schematic
			end
		end
		--DA.DEBUG(2,"ScanTrade: basicData= "..DA.DUMP(basicData))
		recipe.reagentData = basicData
		recipe.numBasic = numBasic
		--DA.DEBUG(2,"ScanTrade: optionalData= "..DA.DUMP(optionalData))
		recipe.optionalData = optionalData
		recipe.numOptional = numOptional
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
		recipeString = recipeString.." "..tostring(numOptionalReagentSlots)
		recipeDB[recipeID] = recipeString
		nameDB[recipeID] = recipeInfo.name		-- for debugging
		--DA.DEBUG(2,"recipeDB["..tostring(recipeID).."] ("..tostring(recipeInfo.name)..") = "..tostring(recipeDB[recipeID]))
		i = i + 1
	end -- for

	Skillet.visited = {}
	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	DA.DEBUG(2,"ScanTrade: Complete, numSkills= "..tostring(numSkills)..", numHeaders= "..tostring(numHeaders))
	if numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	skillData.scanned = true
	return true
end

--
-- Called when this profession needs to be rescaned
-- Initializes tables and calls ScanTrade to do all the work.
--
function Skillet:RescanTrade()
	--DA.PROFILE("Skillet:RescanTrade()")
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
	if not Skillet.data.skillIndexLookup then
		Skillet.data.skillIndexLookup = {}
	end
	if not Skillet.data.Filtered then
		Skillet.data.Filtered = {}
	end
	if not Skillet.data.skillDB then
		Skillet.data.skillDB = {}
	end
	if not Skillet.db.realm.tradeSkills[player] then
		Skillet.db.realm.tradeSkills[player] = {}
	end
	Skillet.scanInProgress = true
	Skillet.dataScanned = ScanTrade()
	Skillet.scanInProgress = false
	return Skillet.dataScanned
end
