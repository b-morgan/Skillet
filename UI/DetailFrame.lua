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

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")

SKILLET_NUM_REAGENT_BUTTONS = 12

local COLORORANGE = "|cffff8040"
local COLORYELLOW = "|cffffff00"
local COLORGREEN =  "|cff40c040"
local COLORGRAY =   "|cff808080"
local COLORRED =    "|cffff0000"
local COLORWHITE =  "|cffffffff"
--
-- Colors used in the "0/0/0" strings and tooltips
--
local CGREY = "|cffb0b0b0"		-- Grey = "[", "/", "]"
local COWNED = "|cff95fcff"		-- Blue = How many you have in your inventory
local CBANK = "|cff95fcff"		-- Blue = How many you have in your bank
local CBAG = "|cff80ff80"		-- Green = How many you can make from materials you have
local CCRAFT =  "|cffffff80"	-- Yellow = How many you can make by crafting the reagents
local CVENDOR = "|cffffa050"	-- Orange = How many you can make if you purchase materials from a vendor
local CALTS = "|cffff80ff"		-- Purple = How many you can make using materials on your alts

function Skillet:SetReagentToolTip(reagentID, numNeeded, numCraftable)
	--DA.DEBUG(0,"SetReagentToolTip("..tostring(reagentID)..", "..tostring(numNeeded)..", "..tostring(numCraftable)..")")
	if not reagentID or type(reagentID) ~= "number" then return end
	GameTooltip:ClearLines()
	GameTooltip:SetHyperlink("item:"..reagentID)
	if self:VendorSellsReagent(reagentID) then
		GameTooltip:AppendText(GRAY_FONT_COLOR_CODE .. " (" .. L["buyable"] .. ")" .. FONT_COLOR_CODE_CLOSE)
	end
	if self.db.global.itemRecipeSource[reagentID] then
		GameTooltip:AppendText(GRAY_FONT_COLOR_CODE .. " (" .. L["craftable"] .. ")" .. FONT_COLOR_CODE_CLOSE)
		for recipeID in pairs(self.db.global.itemRecipeSource[reagentID]) do
			local recipe = self:GetRecipe(recipeID)
			GameTooltip:AddDoubleLine("Source: ",(self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..self:GetRecipeName(recipeID),0,1,0,1,1,1)
			local lookupTable = self.data.skillIndexLookup
			local player = self.currentPlayer
			if lookupTable[recipeID] then
				local rankData = self:GetSkillRanks(player, recipe.tradeID)
				if rankData then
					local rank, maxRank = rankData.rank, rankData.maxRank
					GameTooltip:AddDoubleLine("  "..player,"["..(rank or "?").."/"..(maxRank or "?").."]",1,1,1)
				else
					GameTooltip:AddDoubleLine("  "..player,"[???/???]",1,1,1)
				end
			end
		end
	end
	local inBoth = self:GetInventory(self.currentPlayer, reagentID)
	local surplus = inBoth - numNeeded * numCraftable
	if inBoth < 0 then
		GameTooltip:AddDoubleLine("in shopping list:",(-inBoth),1,1,0)
	end
	if surplus < 0 then
		GameTooltip:AddDoubleLine("to craft "..numCraftable.." you need:",(-surplus),1,0,0)
	end
	if self.db.realm.reagentsInQueue[self.currentPlayer] then
		local inQueue = self.db.realm.reagentsInQueue[self.currentPlayer][reagentID]
		if inQueue then
			if inQueue < 0 then
				GameTooltip:AddDoubleLine("used in queued skills:",-inQueue,1,1,1)
			else
				GameTooltip:AddDoubleLine("created from queued skills:",inQueue,1,1,1)
			end
		end
	end
end

function Skillet:HideDetailWindow()
	SkilletSkillName:SetText("")
	SkilletSkillCooldown:SetText("")
	SkilletDescriptionText:SetText("")
	SkilletFirstCraft:Hide()
	SkilletRequirementLabel:Hide()
	SkilletRequirementText:SetText("")
	SkilletSkillIcon:Hide()
	SkilletReagentLabel:Hide()
	SkilletOptionalLabel:Hide()
	SkilletFinishingLabel:Hide()
	SkilletRecipeNotesButton:Hide()
	SkilletPreviousItemButton:Hide()
	SkilletExtraDetailTextLeft:Hide()
	SkilletExtraDetailTextRight:Hide()
	SkilletAuctionatorButton:Hide()
	SkilletHighlightFrame:Hide()
	SkilletFrame.selectedSkill = -1;
--
-- Always want these set.
--
	SkilletItemCountInputBox:SetText("1");
	for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
		local button = _G["SkilletReagent"..i]
		button:Hide();
	end
	if SkilletRankFrame.subRanks then
		for c,s in pairs(SkilletRankFrame.subRanks) do
			s:Hide()
		end
	end
end

--
-- Called to get the item name appended with the quality icon (and the plain item name)
-- The DetailFrame will be refreshed unless modified is true
--
function Skillet:nameWithQuality(itemID, modified)
	--DA.DEBUG(0,"nameWithQuality("..tostring(itemID)..", "..tostring(modified)..")")
	local name, quality
	local bname, link = GetItemInfo(itemID)
	if not bname then
		if modified then
			self.modifiedDataNeeded = true
		else
			self.detailDataNeeded = true
		end
		C_Item.RequestLoadItemDataByID(itemID)
		bname = "item:"..tostring(itemID)
	end
	if link then
		quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(link)
	end
	if quality then
		name = bname..C_Texture.GetCraftingReagentQualityChatIcon(quality)
	else
		name = bname
	end
	--DA.DEBUG(0,"nameWithQuality: name= "..tostring(name)..", bname= "..tostring(bname))
	return name, bname
end

--
-- Updates the detail window with information about the currently selected skill
--
function Skillet:UpdateDetailWindow(skillIndex)
	--DA.DEBUG(0,"UpdateDetailWindow("..tostring(skillIndex)..")")
	SkilletReagentParent.StarsFrame:Hide()
	SkilletRecipeRankFrame:Hide()
	self.currentRecipeInfo = nil
	local recipeInfo = nil
	if not skillIndex or skillIndex < 0 then
		self:HideDetailWindow()
		return
	end
--
-- If the skillIndex has changed, clear all the special lists
--
	if self.currentSkillIndex ~= skillIndex then
		self.currentSkillIndex = skillIndex
		self.salvageSelected = {}
		self.modifiedSelected = {}
		self.optionalSelected = {}
		self.finishingSelected = {}
		self.recipeRank = 0
		self:HideSalvageList(true)
		self:HideModifiedList(true)
		self:HideOptionalList(true)
		self:HideFinishingList(true)
	end
	local texture
	local recipe
	local newInfo
	local recipeSchematic
	SkilletFrame.selectedSkill = skillIndex
	self.numItemsToCraft = 1
	if self.recipeNotesFrame then
		self.recipeNotesFrame:Hide()
	end
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
	if not skill or skill.spellID == 0 then
		self:HideDetailWindow()
		return
	else
		recipe = self:GetRecipe(skill.id)
		if not recipe or recipe.spellID == 0 then
			self:HideDetailWindow()
			return
		end
		newInfo = C_TradeSkillUI.GetRecipeInfo(recipe.spellID)
		recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipe.spellID, false)
		if not self.recipeDump[recipe.spellID] then
			self.recipeDump[recipe.spellID] = true
			--DA.DEBUG(0,"UpdateDetailWindow: skill= "..DA.DUMP1(skill))
			--DA.DEBUG(0,"UpdateDetailWindow: name= "..tostring(recipe.name)..", recipe= "..DA.DUMP(recipe))
			--DA.DEBUG(0,"UpdateDetailWindow: name= "..tostring(recipe.name)..", GetRecipeInfo= "..DA.DUMP(newInfo))
			--DA.DEBUG(0,"UpdateDetailWindow: name= "..tostring(recipe.name)..", GetRecipeSchematic= "..DA.DUMP(recipeSchematic))
		end
--
-- Name of the skill
--
		SkilletSkillName:SetText(recipe.name)
		SkilletRecipeNotesButton:Show()
		if recipe.spellID and recipe.itemID then
			local orange,yellow,green,gray = self:GetTradeSkillLevels(recipe.itemID, recipe.spellID)
			SkilletRankFrame.subRanks.green:SetValue(gray)
			SkilletRankFrame.subRanks.yellow:SetValue(green)
			SkilletRankFrame.subRanks.orange:SetValue(yellow)
			SkilletRankFrame.subRanks.red:SetValue(orange)
			for c,s in pairs(SkilletRankFrame.subRanks) do
				s:Show()
			end
		end
		recipeInfo = Skillet.data.recipeInfo[self.currentTrade][recipe.spellID]
		self.currentRecipeInfo = recipeInfo
		if recipeInfo and recipeInfo.upgradeable then
			for i, starFrame in ipairs(SkilletReagentParent.StarsFrame.Stars) do
				starFrame.EarnedStar:SetShown(i <= recipeInfo.learnedUpgrade);
				starFrame.UnearnedStar:SetShown(i <= recipeInfo.maxUpgrade);
			end
			SkilletReagentParent.StarsFrame:Show();
		elseif newInfo.unlockedRecipeLevel then
			self.recipeRankMax = newInfo.unlockedRecipeLevel
			if self.recipeRank == 0 then
				self.recipeRank = newInfo.unlockedRecipeLevel
				SkilletRecipeRankLabel:SetText("Rank "..tostring(self.recipeRank))
			end
			Skillet:RecipeRankSetExperience(newInfo.currentRecipeExperience, newInfo.nextLevelRecipeExperience, newInfo.unlockedRecipeLevel)
			SkilletRecipeRankFrame:Show()
		end
--
-- Description
--
		local description
		description = C_TradeSkillUI.GetRecipeDescription(skill.id, {})
		--DA.DEBUG(0,"UpdateDetailWindow: description= "..tostring(description))
		if description then
			description = description:gsub("\r","")	-- Skillet frame has less space than Blizzard frame, so
			description = description:gsub("\n","")	-- remove any extra blank lines, but
			SkilletDescriptionText:SetMaxLines(4)	-- don't let the text get too big.
			SkilletDescriptionText:SetText(description)
		else
			SkilletDescriptionText:SetText("")
		end
--
-- Is this recipe a First Craft
--
--[[
PROFESSIONS_FIRST_CRAFT = "First Craft";
PROFESSIONS_FIRST_CRAFT_DESCRIPTION = "Crafting this recipe for the first time will teach you something new.";
--]]
		if recipe.firstCraft then
			SkilletFirstCraft:Show()
		else
			SkilletFirstCraft:Hide()
		end
--
-- Whether or not it is on cooldown.
--
		local _, _, _, _, _, _, _, _, _, _, _, displayAsUnavailable, unavailableString = Skillet:GetTradeSkillInfo(skill.id)
		--DA.DEBUG(0,"UpdateDetailWindow: displayAsUnavailable="..tostring(displayAsUnavailable)..", unavailableString="..tostring(unavailableString))
		if displayAsUnavailable then
			local width = SkilletReagentParent:GetWidth()
			local iconw = SkilletSkillIcon:GetWidth()
			SkilletSkillCooldown:SetWidth(width - iconw - 15)
			SkilletSkillCooldown:SetMaxLines(3)
			SkilletSkillCooldown:SetText(unavailableString)
		else
			self:UpdateCooldown(skill.id, SkilletSkillCooldown)
		end
--
-- Are special tools needed for this skill?
--
		local requirements = C_TradeSkillUI.GetRecipeRequirements(skill.id)
		if requirements then
			local tools = ""
			local sep = ""
			for _, recipeRequirement in ipairs(requirements) do
				toolName = recipeRequirement.name
				if not recipeRequirement.met then
					toolName = COLORRED..toolName.."|r"
				end
				tools = tools..sep..toolName
				sep = ", "
			end
			SkilletRequirementText:SetText(tools)
			SkilletRequirementText:Show()
			SkilletRequirementLabel:Show()
		else
			SkilletRequirementText:Hide()
			SkilletRequirementLabel:Hide()
		end
	end

	if recipeInfo and recipeInfo.alternateVerb then
		texture = recipeInfo.icon
	end
	if recipe.itemID and recipe.itemID ~= 0 then
		texture = GetItemIcon(recipe.itemID)
	end
	SkilletSkillIcon:SetNormalTexture(texture)
	SkilletSkillIcon:Show()
	if AuctionHouseFrame and Auctionator and self.ATRPlugin and self.db.profile.plugins.ATR.enabled and self.auctionOpen then
		SkilletAuctionatorButton:Show()
	else
		SkilletAuctionatorButton:Hide()
	end
--
-- How many of these items are produced at one time ..
--
	if recipe.numMade > 1 then
		--DA.DEBUG(0,"UpdateDetailWindow: recipe= "..DA.DUMP1(recipe,1))
		local text = tostring(recipe.numMade)
		local adjustNumMade = self.db.global.AdjustNumMade[recipe.spellID]
		--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", adjustNumMade= "..tostring(adjustNumMade))
		if adjustNumMade then
			text = string.format("|cffff8080%d|r",recipe.numMade)
		end
		SkilletSkillIconCount:SetText(text)
		SkilletSkillIconCount:Show()
	else
		SkilletSkillIconCount:SetText("")
		SkilletSkillIconCount:Hide()
	end
--
-- How many can we queue/create?
--
	SkilletItemCountInputBox:SetText("" .. self.numItemsToCraft);
	SkilletItemCountInputBox:HighlightText()
--
-- Required (Basic) Reagents
--
	local lastReagentIndex = 1
	local lastReagentButton = _G["SkilletReagent1"]
	local width = SkilletReagentParent:GetWidth()
	local numReagents = #recipe.reagentData
	--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numReagents="..tostring(numReagents))
	SkilletReagentLabel:SetText(SPELL_REAGENTS)
	SkilletReagentLabel:Show();
	for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
		local button = _G["SkilletReagent"..i]
		local   text = _G[button:GetName() .. "Text"]
		local   icon = _G[button:GetName() .. "Icon"]
		local  count = _G[button:GetName() .. "Count"]
		local needed = _G[button:GetName() .. "Needed"]

		button:SetID(i)
		local reagent = recipe.reagentData[i]
		--DA.DEBUG(0,"UpdateDetailWindow: reagent="..DA.DUMP(reagent))
--
-- Conditional debug output
--
		if reagent and newInfo.unlockedRecipeLevel and i <= numReagents then
			--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", skill.id= "..tostring(skill.id)..", i= "..tostring(i)..", recipeRank= "..tostring(self.recipeRank))
			local reagentName, reagentTexture, reagentCount
			reagentName = reagent.name
			reagentTexture = nil
			reagentCount = reagent.numNeeded
			--DA.DEBUG(0,"UpdateDetailWindow: reagentName= "..tostring(reagentName)..", reagentCount= "..tostring(reagentCount)..", reagent= "..DA.DUMP(reagent))
		end
--
-- Normal reagent processing
--
		if reagent then
			local reagentName
			if reagent.reagentID then
				reagentName	= GetItemInfo("item:"..reagent.reagentID) or reagent.reagentID
			else
				reagentName = "unknown"
			end
			local num, craftable = self:GetInventory(self.currentPlayer, reagent.reagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			if num < reagent.numNeeded then
--
-- Grey it out if we don't have it
--
				count:SetText(GRAY_FONT_COLOR_CODE .. count_text .. FONT_COLOR_CODE_CLOSE)
				text:SetText(GRAY_FONT_COLOR_CODE .. reagentName .. FONT_COLOR_CODE_CLOSE)
				if self:VendorSellsReagent(reagent.reagentID) then
					needed:SetTextColor(0,1,0)
				elseif reagent.modifiedReagent then
					needed:SetTextColor(1,0,1)
				else
					needed:SetTextColor(1,0,0)
				end
			else
--
-- Ungrey it
--
				count:SetText(count_text)
				text:SetText(reagentName)
				if reagent.modifiedReagent then
					needed:SetTextColor(1,1,0)
				else
					needed:SetTextColor(1,1,1)
				end
			end
			texture = GetItemIcon(reagent.reagentID)
			icon:SetNormalTexture(texture)
			needed:SetText(reagent.numNeeded.."x")
			button:SetWidth(width - 20)
			button:Enable()
			button:Show()
			lastReagentButton = button
			lastReagentIndex = i
		else
--
-- Out of basic reagents, don't need to show the button,
-- or any of the text.
--
			button:Hide()
			button:Disable()
		end
	end

--
-- Modified reagents
--
	if recipe.numModified and recipe.numModified > 0 then
		--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numModified="..tostring(recipe.numModified))
		local categoryInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID)
		while not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
			categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID)
		end
		local categorySkillRank = categoryInfo.skillLineCurrentLevel or 0
		--DA.DEBUG(0,"UpdateDetailWindow: categorySkillRank="..tostring(categorySkillRank))
		lastReagentIndex = lastReagentIndex + 1
		local j = 1
		for i= lastReagentIndex, SKILLET_NUM_REAGENT_BUTTONS, 1 do
			local button = _G["SkilletReagent"..i]
			local   text = _G[button:GetName() .. "Text"]
			local   icon = _G[button:GetName() .. "Icon"]
			local  count = _G[button:GetName() .. "Count"]
			local needed = _G[button:GetName() .. "Needed"]
--
-- Each modified reagent slot will be filled with the type of
-- reagent or the reagent that has been selected for that slot
-- This code assumes that the items are listed in quality order
--
			local mreagent = recipe.modifiedData[j]
			if mreagent then
				--DA.DEBUG(0,"UpdateDetailWindow: mreagent= "..DA.DUMP(mreagent))
				needed:SetText(mreagent.numNeeded.."x")
				local mselected
				local mitem, name, link
				local num = {}
				local craftable = {}
				local mtotal = 0
				local count_text
				for k=1, #mreagent.schematic.reagents, 1 do
					mitem = mreagent.schematic.reagents[k].itemID
					num[k], craftable[k] = self:GetInventory(self.currentPlayer, mitem)
					if craftable[k] > 0 then
						if count_text then
							count_text = count_text .. string.format("+%d/%d", num[k], craftable[k])
						else
							count_text = string.format("[%d/%d", num[k], craftable[k])
						end
					else
						if count_text then
							count_text = count_text .. string.format("+%d", num[k])
						else
							count_text = string.format("[%d", num[k])
						end
					end
					mtotal = mtotal + num[k]
				end
				if count_text then
					count_text = count_text .."]"
				end
				if self.db.char.best_quality then
					for k=#mreagent.schematic.reagents, 1 , -1 do
						if num[k] > 0 and not mselected then
							mselected = mreagent.schematic.reagents[k].itemID
						end
					end
				else
					for k=1, #mreagent.schematic.reagents, 1 do
						if num[k] > 0 and not mselected then
							mselected = mreagent.schematic.reagents[k].itemID
						end
					end
				end
				if not mselected then
					mselected = mreagent.schematic.reagents[1].itemID
				end
				local name = self:nameWithQuality(mselected)
				if mtotal < mreagent.numNeeded then
--
-- Grey it out if we don't have it
--
					count:SetText(GRAY_FONT_COLOR_CODE .. count_text .. FONT_COLOR_CODE_CLOSE)
					text:SetText(GRAY_FONT_COLOR_CODE .. name .. FONT_COLOR_CODE_CLOSE)
					--DA.DEBUG(0,"UpdateDetailWindow: (need) mreagent= "..DA.DUMP(mreagent))
					if mreagent.reagentID and self:VendorSellsReagent(mreagent.reagentID) then
						needed:SetTextColor(0,1,0)
					else
						needed:SetTextColor(1,0,1)
					end
				else
--
-- Ungrey it
--
					count:SetText(count_text)
					text:SetText(name)
					needed:SetTextColor(1,1,0)
					if not self.modifiedSelected[j] then
						self.modifiedSelected[j] = self:InitializeModifiedSelected(mreagent)
					end
				end
				texture = GetItemIcon(mselected)
				icon:SetNormalTexture(texture)
				icon:Show()
				button:SetID(j + 100)
				button:SetWidth(width - 20)
				button:Enable()
				button:Show()
				lastReagentButton = button
				lastReagentIndex = i
				j = j + 1
			else
--
-- Out of modified reagents, don't need to show the button,
-- or any of the text.
--
				button:Hide()
				button:Disable()
			end
		end
		--DA.DEBUG(0,"UpdateDetailWindow: self.modifiedSelected = "..DA.DUMP(self.modifiedSelected))
	else
--
-- Recipe has no modified reagents.
--
		--DA.DEBUG(0,"UpdateDetailWindow: (none) recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numModified="..tostring(recipe.numModified))
		self.modifiedSelected = {}
	end

--
-- Optional reagents
--
	if recipe.numOptional and recipe.numOptional > 0 then
		--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numOptional="..tostring(recipe.numOptional))
		local categoryInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID)
		while not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
			categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID)
		end
		local categorySkillRank = categoryInfo.skillLineCurrentLevel or 0
		--DA.DEBUG(0,"UpdateDetailWindow: categorySkillRank="..tostring(categorySkillRank))
		lastReagentIndex = lastReagentIndex + 1
		lastReagentButton = _G["SkilletReagent"..tostring(lastReagentIndex)]
		SkilletOptionalLabel:SetText(SPELL_REAGENTS_OPTIONAL.."  ("..tostring(recipe.numOptional)..")")
		SkilletOptionalLabel:SetPoint("TOPLEFT",lastReagentButton,"TOPLEFT",0,-10)
		SkilletOptionalLabel:Show()
		lastReagentIndex = lastReagentIndex + 1
		local j = 1
		for i= lastReagentIndex, SKILLET_NUM_REAGENT_BUTTONS, 1 do
			local button = _G["SkilletReagent"..i]
			local   text = _G[button:GetName() .. "Text"]
			local   icon = _G[button:GetName() .. "Icon"]
			local  count = _G[button:GetName() .. "Count"]
			local needed = _G[button:GetName() .. "Needed"]
--
-- Each optional reagent slot will be filled with the type of
-- reagent or the reagent that has been selected for that slot
--
			local oreagent = recipe.optionalData[j]
			if oreagent then
				--DA.DEBUG(0,"UpdateDetailWindow: oreagent="..DA.DUMP(oreagent))
				local oselected
				if self.optionalSelected then
					oselected = self.optionalSelected[j]
				end
				if oselected then
					--DA.DEBUG(0,"UpdateDetailWindow: oselected="..DA.DUMP(oselected))
--
-- An optional reagent has been selected for this slot
--
					local name = self:nameWithQuality(oselected.itemID)
					text:SetText(name)
					texture = GetItemIcon(oselected.itemID)
					icon:SetNormalTexture(texture)
					local num, craftable = self:GetInventory(self.currentPlayer, oselected.itemID)
					local count_text
					if craftable > 0 then
						count_text = string.format("[%d/%d]", num, craftable)
					else
						count_text = string.format("[%d]", num)
					end
					count:SetText(count_text)
				else
--
-- Show the type of reagent that can be used. The icon reflects useability.
-- (do we need to prevent locked slots from being filled?)
--
					if oreagent.schematic then
						--DA.DEBUG(0,"UpdateDetailWindow: slotText= "..tostring(oreagent.schematic.slotInfo.slotText)..", categorySkillRank="..tostring(categorySkillRank)..", requiredSkillRank= "..tostring(oreagent.schematic.slotInfo.requiredSkillRank))
						local locked, lockedReason = self:GetReagentSlotStatus(oreagent.schematic, newInfo)
						--DA.DEBUG(0,"UpdateDetailWindow: locked= "..tostring(locked)..", lockedReason="..tostring(lockedReason))
						text:SetText(oreagent.schematic.slotInfo.slotText or OPTIONAL_REAGENT_POSTFIX)
						if not locked and categorySkillRank >= oreagent.schematic.slotInfo.requiredSkillRank then
							icon:SetNormalAtlas("itemupgrade_greenplusicon")
						else
							icon:SetNormalAtlas("AdventureMapIcon-Lock")
						end
						count:SetText("")
					end
				end
				icon:Show()
				needed:SetText("")
				button:SetID(j * -1)
				button:SetWidth(width - 20)
				button:Enable()
				button:Show()
				lastReagentButton = button
				lastReagentIndex = i
				j = j + 1
			else
--
-- Out of optional reagents, don't need to show the button,
-- or any of the text.
--
				button:Hide()
				button:Disable()
			end
		end
	else
--
-- Recipe has no optional reagents.
--
		--DA.DEBUG(0,"UpdateDetailWindow: (none) recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numOptional="..tostring(recipe.numOptional))
		SkilletOptionalLabel:SetText("")
		SkilletOptionalLabel:Hide()
		Skillet.optionalSelected = {}
	end

--
-- Finishing reagents
--
	if recipe.numFinishing and recipe.numFinishing > 0 then
		--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numFinishing="..tostring(recipe.numFinishing))
		local categoryInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID)
		while not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
			categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID)
		end
		local categorySkillRank = categoryInfo.skillLineCurrentLevel or 0
		--DA.DEBUG(0,"UpdateDetailWindow: categorySkillRank="..tostring(categorySkillRank))
		lastReagentIndex = lastReagentIndex + 1
		lastReagentButton = _G["SkilletReagent"..tostring(lastReagentIndex)]
		SkilletFinishingLabel:SetText(PROFESSIONS_CRAFTING_FINISHING_HEADER.."  ("..tostring(recipe.numFinishing)..")")
		SkilletFinishingLabel:SetPoint("TOPLEFT",lastReagentButton,"TOPLEFT",0,-10)
		SkilletFinishingLabel:Show()
		lastReagentIndex = lastReagentIndex + 1
		local j = 1
		for i= lastReagentIndex, SKILLET_NUM_REAGENT_BUTTONS, 1 do
			local button = _G["SkilletReagent"..i]
			local   text = _G[button:GetName() .. "Text"]
			local   icon = _G[button:GetName() .. "Icon"]
			local  count = _G[button:GetName() .. "Count"]
			local needed = _G[button:GetName() .. "Needed"]
--
-- Each finishing reagent slot will be filled with the type of
-- reagent or the reagent that has been selected for that slot
--
			local freagent = recipe.finishingData[j]
			if freagent then
				--DA.DEBUG(0,"UpdateDetailWindow: freagent="..DA.DUMP(freagent))
				local fselected
				if self.finishingSelected then
					fselected = self.finishingSelected[j]
				end
				if fselected then
					--DA.DEBUG(0,"UpdateDetailWindow: fselected="..DA.DUMP(fselected))
--
-- A finishing reagent has been selected for this slot
--
					local name = self:nameWithQuality(fselected.itemID)
					text:SetText(name)
					texture = GetItemIcon(fselected.itemID)
					icon:SetNormalTexture(texture)
					local num, craftable = self:GetInventory(self.currentPlayer, fselected.itemID)
					local count_text
					if craftable > 0 then
						count_text = string.format("[%d/%d]", num, craftable)
					else
						count_text = string.format("[%d]", num)
					end
					count:SetText(count_text)
				else
--
-- Show the type of reagent that can be used. The icon reflects useability.
-- (do we need to prevent locked slots from being filled?)
--
					if freagent.schematic then
						--DA.DEBUG(0,"UpdateDetailWindow: slotText= "..tostring(freagent.schematic.slotInfo.slotText)..", categorySkillRank="..tostring(categorySkillRank)..", requiredSkillRank= "..tostring(freagent.schematic.slotInfo.requiredSkillRank))
						local locked, lockedReason = self:GetReagentSlotStatus(freagent.schematic, newInfo)
						--DA.DEBUG(0,"UpdateDetailWindow: locked= "..tostring(locked)..", lockedReason="..tostring(lockedReason))
						text:SetText(freagent.schematic.slotInfo.slotText or OPTIONAL_REAGENT_POSTFIX)
						if not locked and categorySkillRank >= freagent.schematic.slotInfo.requiredSkillRank then
							icon:SetNormalAtlas("itemupgrade_greenplusicon")
						else
							icon:SetNormalAtlas("AdventureMapIcon-Lock")
						end
						count:SetText("")
					end
				end
				icon:Show()
				needed:SetText("")
				button:SetID(j + 200)
				button:SetWidth(width - 20)
				button:Enable()
				button:Show()
				lastReagentButton = button
				lastReagentIndex = i
				j = j + 1
			else
--
-- Out of finishing reagents, don't need to show the button,
-- or any of the text.
--
				button:Hide()
				button:Disable()
			end
		end
	else
--
-- Recipe has no finishing reagents.
--
		--DA.DEBUG(0,"UpdateDetailWindow: (none) recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numFinishing="..tostring(recipe.numFinishing))
		SkilletFinishingLabel:SetText("")
		SkilletFinishingLabel:Hide()
		self.finishingSelected = {}
	end

--
-- Salvage reagents. These recipes don't have any other types of reagents and 
-- use C_TradeSkillUI.CraftSalvage to process.
--
	if recipe.salvage then
		local numSalvage = #recipe.salvage
		--DA.DEBUG(0,"UpdateDetailWindow: recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name)..", numSalvage="..tostring(numSalvage))
		local categoryInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID)
		while not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
			categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID)
		end
		local categorySkillRank = categoryInfo.skillLineCurrentLevel or 0
		--DA.DEBUG(0,"UpdateDetailWindow: categorySkillRank="..tostring(categorySkillRank))
		--DA.DEBUG(0,"UpdateDetailWindow: lastReagentIndex="..tostring(lastReagentIndex))
		lastReagentIndex = lastReagentIndex + 1
		lastReagentButton = _G["SkilletReagent"..tostring(lastReagentIndex)]
		local j = 1
		for i= lastReagentIndex, SKILLET_NUM_REAGENT_BUTTONS, 1 do
			local button = _G["SkilletReagent"..i]
			local   text = _G[button:GetName() .. "Text"]
			local   icon = _G[button:GetName() .. "Icon"]
			local  count = _G[button:GetName() .. "Count"]
			local needed = _G[button:GetName() .. "Needed"]
--
-- Each salvage reagent slot will be filled with the type of
-- reagent or the reagent that has been selected for that slot
--
			if j == 1 then
				DA.DEBUG(0,"UpdateDetailWindow: salvageSelected= "..DA.DUMP1(self.salvageSelected))
				local sselected
				if self.salvageSelected then
					sselected = self.salvageSelected[j]
				end
				if sselected then
--
-- A salvage reagent has been selected for this slot
--
					DA.DEBUG(0,"UpdateDetailWindow: sselected= "..tostring(sselected))
					local name = self:nameWithQuality(sselected)
					text:SetText(name)
					texture = GetItemIcon(sselected)
					icon:SetNormalTexture(texture)
					local num, craftable = self:GetInventory(self.currentPlayer, sselected)
					local count_text
					if craftable > 0 then
						count_text = string.format("[%d/%d]", num, craftable)
					else
						count_text = string.format("[%d]", num)
					end
					count:SetText(count_text)
				else
--
-- Show the type of reagent that can be used. The icon reflects useability.
-- (do we need to prevent locked slots from being filled?)
--
					--DA.DEBUG(0,"UpdateDetailWindow: salvage= "..DA.DUMP1(recipe.salvage))
					text:SetText(PROFESSIONS_ADD_SALVAGE)
					icon:SetNormalAtlas("itemupgrade_greenplusicon")
					count:SetText("")
				end
				icon:Show()
				needed:SetText("")
				button:SetID(j * -1)
				button:SetWidth(width - 20)
				button:Enable()
				button:Show()
				lastReagentButton = button
				lastReagentIndex = i
				j = j + 1
			else
--
-- Out of salvage reagents, don't need to show the button,
-- or any of the text.
--
				button:Hide()
				button:Disable()
			end
		end
	else
--
-- Recipe has no salvage reagents
--
		--DA.DEBUG(0,"UpdateDetailWindow: (no salvage) recipeID= "..tostring(recipe.spellID)..", name= "..tostring(recipe.name))
		self.salvageSelected = {}
	end
--
-- If we have stack of recipes, show the button pop the stack.
--
	if #self.skillStack > 0 then
		SkilletPreviousItemButton:Show()
	else
		SkilletPreviousItemButton:Hide()
	end
--
-- Generate any extra text 
--
	local label, extra_text
--
--	Do any plugins want to add extra info to the details window?
--
	if not Skillet.db.profile.recipe_source_first then
		label, extra_text = Skillet:GetExtraText(skill, recipe)
	end
--
-- Is there any source info from the recipe?
--
	local sourceText
	if Skillet.db.profile.show_recipe_source_for_learned then
		sourceText = C_TradeSkillUI.GetRecipeSourceText(skill.id)
	else
		local recipeInfo = C_TradeSkillUI.GetRecipeInfo(skill.id)
		if recipeInfo and not recipeInfo.learned then
			sourceText = C_TradeSkillUI.GetRecipeSourceText(skill.id)
		end
	end
	if sourceText then
		local c = 0
		local e = ""
		for l in string.gmatch(sourceText,"|n") do
			c = c + 1
			e = e.."\n"
		end
		--DA.DEBUG(0,"UpdateDetailWindow: sourceText= "..sourceText..", c= "..tostring(c))
		if label then
			label = label.."\n"..sourceText
		else
			label = sourceText
		end
		if extra_text then
			extra_text = extra_text.."\n"..e
		else
			extra_text = e
		end
	end
--
--	Do any plugins want to add extra info to the details window?
--
	if Skillet.db.profile.recipe_source_first then
		local l, e = Skillet:GetExtraText(skill, recipe)
		if label then
			label = label.."\n\n"..l
		else
			label = l
		end
		if extra_text then
			extra_text = extra_text.."\n\n"..e
		else
			extra_text = e
		end
	end
--
-- Output any extra text 
--
	if label then
		SkilletExtraDetailTextLeft:SetPoint("TOPLEFT",lastReagentButton,"BOTTOMLEFT",0,-10)
--		SkilletExtraDetailTextLeft:SetText(GRAY_FONT_COLOR_CODE..label)
		SkilletExtraDetailTextLeft:SetText(label)
		SkilletExtraDetailTextLeft:Show()
	else
		SkilletExtraDetailTextLeft:Hide()
	end
	if extra_text then
		SkilletExtraDetailTextRight:SetPoint("TOPLEFT",lastReagentButton,"BOTTOMLEFT",50,-10)
		SkilletExtraDetailTextRight:SetText(extra_text)
		SkilletExtraDetailTextRight:Show()
	else
		SkilletExtraDetailTextRight:Hide()
	end
	--DA.DEBUG(3,"UpdateDetailWindow Complete")
end

function Skillet:ChangeItemCount(this, button, count)
	local val = SkilletItemCountInputBox:GetNumber()
	if button == "RightButton" then
		count = count * 10
	end
	if val == 1 and count > 1 then
		val = 0
	end
	val = val + count
	if val < 1 then
		val = 1
	end
	SkilletItemCountInputBox:SetText(val)
end

--
-- Called to set the tooltip when the mouse enters a reagent button
--
function Skillet:ReagentButtonOnEnter(button, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ReagentButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	if Skillet.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if Skillet.db.profile.ttscale then
			uiScale = uiScale * Skillet.db.profile.ttscale
		end
		GameTooltip:SetScale(uiScale)
	end
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
	if skill then
		local recipe = self:GetRecipe(skill.id)
		local reagent
		if recipe then
			if reagentIndex > 0 and reagentIndex < 100 then
--
-- Basic reagent
--
				reagent = recipe.reagentData[reagentIndex]
				if reagent then
					self:SetReagentToolTip(reagent.reagentID, reagent.numNeeded, skill.numCraftable or 0)
					if self.db.profile.link_craftable_reagents then
						if self.db.global.itemRecipeSource[reagent.reagentID] then
							local icon = _G[button:GetName() .. "Icon"]
							self.gearTexture:SetParent(icon)
							self.gearTexture:ClearAllPoints()
							self.gearTexture:SetPoint("TOPLEFT", icon)
							self.gearTexture:Show()
						end
					end
				end
			elseif reagentIndex <= 0 then
				if not recipe.salvage then
--
-- Optional reagent
--
					reagent = recipe.optionalData[-1 * reagentIndex]
					--DA.DEBUG(1,"ReagentButtonOnEnter(O): reagent= "..DA.DUMP1(reagent))
					--DA.DEBUG(1,"ReagentButtonOnEnter(O): index="..tostring(reagentIndex)..", optionalSelected= "..DA.DUMP1(self.optionalSelected))
					if self.optionalSelected[-1 * reagentIndex] then
						self:SetReagentToolTip(self.optionalSelected[-1 * reagentIndex].itemID, 0, 0)
					end
					if reagent.lockedReason then
						GameTooltip:AddLine(reagent.lockedReason, 1,0,0)
					end
				elseif self.salvageSelected[1] then
--
-- Salvage reagent
--
					--DA.DEBUG(1,"ReagentButtonOnEnter(S): index= "..tostring(reagentIndex)..", salvageSelected= "..DA.DUMP1(self.salvageSelected))
					self:SetReagentToolTip(self.salvageSelected[1], 0, 0)
				end
			elseif reagentIndex > 200 then
--
-- Finishing reagent
--
				reagent = recipe.finishingData[reagentIndex - 200]
				--DA.DEBUG(1,"ReagentButtonOnEnter(F): reagent= "..DA.DUMP1(reagent))
				--DA.DEBUG(1,"ReagentButtonOnEnter(F): index= "..tostring(reagentIndex)..", finishingSelected= "..DA.DUMP1(self.finishingSelected))
				if self.finishingSelected[reagentIndex - 200] then
					self:SetReagentToolTip(self.finishingSelected[reagentIndex - 200].itemID, 0, 0)
				end
				if reagent.lockedReason then
					GameTooltip:AddLine(reagent.lockedReason, 1,0,0)
				end
			elseif reagentIndex > 100 then
--
-- Modified reagent (use the default first one)
--
				reagent = recipe.modifiedData[reagentIndex - 100]
				--DA.DEBUG(1,"ReagentButtonOnEnter(M): reagent= "..DA.DUMP1(reagent))
				self:SetReagentToolTip(reagent.reagentID, 0, 0)
				if reagent.lockedReason then
					GameTooltip:AddLine(reagent.lockedReason, 1,0,0)
				end
			end
		end
	end
	GameTooltip:Show()
	CursorUpdate(button)
end

--
-- Called then the mouse leaves a reagent button
--
function Skillet:ReagentButtonOnLeave(button, skillIndex, reagentIndex)
	--DA.DEBUG(1,"ReagentButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	self.gearTexture:Hide()
	if Skillet.db.profile.scale_tooltip then
		GameTooltip:SetScale(Skillet.gttScale)
	end
	GameTooltip:Hide()
	ResetCursor()
end

function Skillet:ReagentButtonSkillSelect(player, id)
	--DA.DEBUG(0,"ReagentButtonSkillSelect("..tostring(player)..", "..tostring(id)..")")
	if player == Skillet.currentPlayer then -- Blizzard's 5.4 update prevents us from changing away from the current player
		local skillIndexLookup = Skillet.data.skillIndexLookup
		self.gearTexture:Hide()
		GameTooltip:Hide()
		local newRecipe = Skillet:GetRecipe(id)
		--DA.DEBUG(0,"ReagentButtonSkillSelect: newRecipe= "..DA.DUMP1(newRecipe))
		if newRecipe then
			Skillet:PushSkill(Skillet.currentPlayer, Skillet.currentTrade, Skillet.selectedSkill)
			Skillet:SetTradeSkill(player, newRecipe.tradeID, skillIndexLookup[id])
		end
	end
end

--
-- Called when the reagent button is shift-clicked
--
function Skillet:ReagentButtonShiftClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ReagentButtonShiftClick("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local link = Skillet:GetRecipeReagentItemLink(skillIndex, reagentIndex)
	if not ChatEdit_InsertLink(link) then
		--DA.DEBUG(1,"ReagentButtonShiftClick: ChatEdit_InsertLink returned false. link= "..tostring(link))
		local name = GetItemInfo(link)
		if SkilletSearchBox:HasFocus() then
			SkilletSearchBox:SetText(name)
		end
	end
end

--
-- Called when the reagent button is right-clicked
--
function Skillet:ReagentButtonRightClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ReagentButtonRightClick("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if not recipe then
		--DA.WARN("ReagentButtonRightClick: recipe is nil. "..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex))
		return
	end
	if reagentIndex < 0 then
		if recipe.salvage then
--
-- Salvage reagent (reagentIndex < 0 and recipe.salvage)
--
			Skillet:DisplaySalvageList()
			Skillet:SalvageReagentOnClick(button, mouse, skillIndex, reagentIndex)
			return
		else
--
-- Optional reagent (reagentIndex < 0)
--
			Skillet:DisplayOptionalList()
			Skillet:OptionalReagentOnClick(button, mouse, skillIndex, reagentIndex)
			return
		end
	elseif reagentIndex > 100 and reagentIndex < 200 then
--
-- Modified reagent (reagentIndex + 100)
--
		Skillet:DisplayModifiedList()
		Skillet:ModifiedReagentOnClick(button, mouse, skillIndex, reagentIndex)
		return
	else
--
-- Finishing reagent (reagentIndex + 200)
--
		Skillet:DisplayFinishingList()
		Skillet:FinishingReagentOnClick(button, mouse, skillIndex, reagentIndex)
		return
	end
--
-- Basic reagent (does nothing)
--
	if mouse == "RightButton" then
		--DA.DEBUG(0,"ReagentButtonRightClick: RightButton, skillIndex= "..tostring(skillIndex)..", reagentIndex= "..tostring(reagentIndex))
		return
	end
end

--
-- Called when the reagent button is left-clicked
--
function Skillet:ReagentButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ReagentButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if not recipe then
		--DA.WARN("ReagentButtonRightClick: recipe is nil. "..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex))
		return
	end
	if reagentIndex < 0 then
		if recipe.salvage then
--
-- Salvage reagent (reagentIndex < 0 and recipe.salvage)
--
			Skillet:DisplaySalvageList()
			Skillet:SalvageReagentOnClick(button, mouse, skillIndex, reagentIndex)
			return
		else
--
-- Optional reagent (reagentIndex < 0)
--
			Skillet:DisplayOptionalList()
			Skillet:OptionalReagentOnClick(button, mouse, skillIndex, reagentIndex)
			return
		end
	elseif reagentIndex > 100 and reagentIndex < 200 then
--
-- Modified reagent (reagentIndex + 100)
--
		Skillet:DisplayModifiedList()
		Skillet:ModifiedReagentOnClick(button, mouse, skillIndex, reagentIndex)
		return
	else
--
-- Finishing reagent (reagentIndex + 200)
--
		Skillet:DisplayFinishingList()
		Skillet:FinishingReagentOnClick(button, mouse, skillIndex, reagentIndex)
		return
	end
--
-- Basic reagent
--
	if not self.db.profile.link_craftable_reagents then
		return
	end
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if not recipe then
		--DA.WARN("ReagentButtonOnClick: recipe is nil. "..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex))
		return
	end
	local reagent = recipe.reagentData[reagentIndex]
	if not reagent then
		--DA.DEBUG(0,"ReagentButtonOnClick: recipe= "..DA.DUMP1(recipe))
		--DA.WARN("ReagentButtonOnClick: reagent is nil. "..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex))
		return
	end
	local newRecipeTable = self.db.global.itemRecipeSource[reagent.reagentID]
	local skillIndexLookup = self.data.skillIndexLookup
	local player = self.currentPlayer
	local myRecipeID
	local newRecipeID
	local newPlayer
	if newRecipeTable then
		local newRecipe
		local recipeCount = 0
		self.data.recipeMenuTable = {}
		if not self.recipeMenu then
			self.recipeMenu = CreateFrame("Frame", "SkilletRecipeMenu", _G["UIParent"], "UIDropDownMenuTemplate")
		end
--
-- Popup with selection if there is more than 1 potential recipe source for the reagent (small prismatic shards, for example)
--
		for id in pairs(newRecipeTable) do
			if skillIndexLookup[id] then
				recipeCount = recipeCount + 1
				newRecipe = self:GetRecipe(id)
				local skillID = skillIndexLookup[id]
				local newSkill = self:GetSkill(player, newRecipe.tradeID, skillID)
				self.data.recipeMenuTable[recipeCount] = {}
				self.data.recipeMenuTable[recipeCount].text = player .." : " .. newRecipe.name or "Unknown"
				self.data.recipeMenuTable[recipeCount].arg1 = player
				self.data.recipeMenuTable[recipeCount].arg2 = id
				self.data.recipeMenuTable[recipeCount].func = function(arg1,arg2) Skillet.ReagentButtonSkillSelect(arg1,arg2) end
				myRecipeID = id
				self.data.recipeMenuTable[recipeCount].textr = 1.0
				self.data.recipeMenuTable[recipeCount].textg = 1.0
				self.data.recipeMenuTable[recipeCount].textb = 1.0
				newPlayer = player
				newRecipeID = id
			end
		end
		--DA.DEBUG(0,"ReagentButtonOnClick: recipeMenuTable= "..DA.DUMP1(self.data.recipeMenuTable))
		if myRecipeID then
			newPlayer = player
			newRecipeID = myRecipeID
		end
		if recipeCount == 1 or myRecipeID then
			self.gearTexture:Hide()
			GameTooltip:Hide()
			button:Hide()	-- hide the button so that if a new button is shown in this slot, a new "OnEnter" event will fire
			newRecipe = self:GetRecipe(newRecipeID)
			self:PushSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
			self:SetTradeSkill(newPlayer, newRecipe.tradeID, skillIndexLookup[newRecipeID])
		else
			local x, y = GetCursorPosition()
			local uiScale = UIParent:GetEffectiveScale()
			EasyMenu(self.data.recipeMenuTable, self.recipeMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
		end
	end
end

--
-- Called when the icon button is clicked
--
function Skillet:ReagentsLinkOnClick(button, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ReagentLinkOnClick("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	if not self.db.profile.link_craftable_reagents then
		--DA.DEBUG(1,"ReagentsLinkOnClick: link_craftable_reagents= "..tostring(self.db.profile.link_craftable_reagents))
		return
	end
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	--DA.DEBUG(1,"ReagentsLinkOnClick: recipe= "..DA.DUMP1(recipe))
	local sep = " "
	for i=1,#recipe.reagentData do
		local reagent = recipe.reagentData[i]
		--DA.DEBUG(1,"ReagentsLinkOnClick: reagent= "..DA.DUMP1(reagent))
		if reagent then
			local reagentName, reagentLink
			if reagent.reagentID then
				reagentName, reagentLink = GetItemInfo(reagent.reagentID)
			end
			--DA.DEBUG(1,"ReagentsLinkOnClick: reagentLink= "..DA.DUMP1(reagentLink))
			if reagentLink then
				ChatEdit_InsertLink(sep .. reagent.numNeeded .. "x" .. reagentLink)
			end
		sep = ", "
		end
	end
end

function Skillet:ReagentStarsFrame_OnMouseEnter(starsFrame)
	GameTooltip:SetOwner(starsFrame, "ANCHOR_TOPLEFT");
	GameTooltip:SetRecipeRankInfo(self.currentRecipeInfo.recipeID, self.currentRecipeInfo.learnedUpgrade);
end

function Skillet:GetReagentSlotStatus(reagentSlotSchematic, recipeInfo)
	--DA.DEBUG(0,"GetReagentSlotStatus("..tostring(reagentSlotSchematic)..", "..tostring(recipeInfo)..")")
	--DA.DEBUG(1,"GetReagentSlotStatus("..DA.DUMP1(reagentSlotSchematic)..", "..DA.DUMP1(recipeInfo)..")")
	local slotInfo = reagentSlotSchematic.slotInfo;
	local locked, lockedReason = C_TradeSkillUI.GetReagentSlotStatus(slotInfo.mcrSlotID, recipeInfo.recipeID, recipeInfo.skillLineAbilityID);
	if not locked then
		local categoryInfo = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID);
		while categoryInfo and not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
			categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID);
		end
		if categoryInfo and categoryInfo.skillLineCurrentLevel then
			local requiredSkillRank = slotInfo.requiredSkillRank;
			locked = categoryInfo.skillLineCurrentLevel < requiredSkillRank;
			if locked then
				lockedReason = OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT:format(requiredSkillRank);
			end
		end
	end
	return locked, lockedReason;
end
