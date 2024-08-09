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

-- This file contains code used to access recipe/tradeskill information

-- If an item requires a specific level before it can be used, then
-- the level is returned, otherwise 0 is returned
--
-- item can be: itemID or "itemString" or "itemName" or "itemLink"

function Skillet:GetLevelRequiredToUse(item)
	if not item then return end
		local level = select(5, C_Item.GetItemInfo(item))
	if not level then level = 0 end
	return level
end

function Skillet:GetItemIDFromLink(link)	-- works with items or enchants
	--DA.DEBUG(3,"GetItemIDFromLink("..tostring(DA.PLINK(link))..")")
	if (link) then
		local linktype, id = string.match(link, "|H([^:]+):(%d+)")
		--DA.DEBUG(3,"linktype= "..tostring(linktype)..", id= "..tostring(id))
		if id then
			return tonumber(id), tostring(linktype)
		end
	end
end

--
-- return GetItemInfo and automatically query server if not cached
--
function Skillet:GetItemInfo(id)
	if id then
		local name = C_Item.GetItemInfo(id)
		if not name then
			GameTooltip:SetHyperlink("item:"..id)
			GameTooltip:SetHyperlink("enchant:"..id)
		end
		return C_Item.GetItemInfo(id)
	end
end

-- Returns the name of the current trade skill
function Skillet:GetTradeName(tradeID)
	local tradeName = GetSpellInfo(tonumber(tradeID))
	return tradeName
end

-- Returns a link for the currently selected tradeskill item.
-- The input is an index into the currently selected tradeskill
-- or craft.
function Skillet:GetRecipeItemLink(index)
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, index)
		if recipe then
		local _, link = C_Item.GetItemInfo(recipe.itemID)
		return link
	end
		return nil
end

function Skillet:AdjustNumberMade(index, adjust)
	--DA.DEBUG(0,"AdjustNumberMade("..tostring(index)..", "..tostring(adjust)..")")
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, index)
	local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
	--DA.DEBUG(2,"recipeSchematic= "..DA.DUMP1(recipeSchematic))
	local minMade = recipeSchematic.quantityMin
	local maxMade = recipeSchematic.quantityMax
	local origNumMade = (minMade + maxMade)/2
	--DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe,1))
	if recipe then
		recipe.numMade = math.max(recipe.numMade + adjust, 1)
		if recipe.numMade ~= origNumMade then
			self.db.global.AdjustNumMade[recipeID] = recipe.numMade
		else
			self.db.global.AdjustNumMade[recipeID] = nil
		end
		--DA.DEBUG(0,"recipeID= "..tostring(recipeID)..", recipe.numMade= "..tostring(recipe.numMade))
		self:UpdateTradeSkillWindow()
	end
end

--
-- Returns a link for the reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function Skillet:GetRecipeReagentItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetRecipeReagentItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		--DA.DEBUG(1,"GetRecipeReagentItemLink: recipe= "..DA.DUMP1(recipe,1))
		if recipe then
			if index > 0 and index < 100 and recipe.reagentData[index] then
				DA.DEBUG(1,"GetRecipeReagentItemLink: reagentID= "..tostring(recipe.reagentData[index].reagentID))
				local _, link = C_Item.GetItemInfo(recipe.reagentData[index].reagentID)
				return link
			elseif index > 100 and index < 200 and recipe.modifiedData[index-100] then
				DA.DEBUG(1,"GetRecipeReagentItemLink: reagentID= "..tostring(recipe.modifiedData[index-100].reagentID))
				local _, link = C_Item.GetItemInfo(recipe.modifiedData[index-100].reagentID)
				return link
			end
--
-- Optional (index < 0) and Finishing (index > 200) reagents have no link for now.
--
		end
	end
end

-- Gets the trade skill line, and knows how to do the right
-- thing depending on whether or not this is a craft.
function Skillet:GetTradeSkillLine()
	local tradeName = GetSpellInfo(self.currentTrade)
	local ranks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
	local rank, maxRank
	if ranks then
		rank, maxRank = ranks.rank, ranks.maxRank
	else
		rank, maxRank = 0, 0
	end
	DA.DEBUG(0,"GetTradeSkillLine "..tostring(tradeName).." "..tostring(rank).." "..tostring(maxRank))
	return tradeName, rank, maxRank
end

function Skillet:IsRecipeOnCooldown(recipeID)
	local cooldown, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(recipeID);
	if not cooldown then
		return false;
	end
	if charges > 0 then
		return false;
	end
	return true;
end

function Skillet:UpdateCooldown(recipeID, recipeInfo, fontString)
	local cooldown, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(recipeID);
	if maxCharges and charges and maxCharges > 0 and (charges > 0 or not cooldown) then
		fontString:SetFormattedText(TRADESKILL_CHARGES_REMAINING, charges, maxCharges);
		fontString:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	elseif recipeInfo.disabled then
		fontString:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		fontString:SetText(recipeInfo.disabledReason);
	else
		local function SetCooldownRemaining(cooldown)
			fontString:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(cooldown));
		end
		fontString:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		if not cooldown then
			fontString:SetText("");
		elseif not isDayCooldown then
--			cooldownFormatter:SetMinInterval(SecondsFormatter.Interval.Seconds);
			SetCooldownRemaining(cooldown);
		elseif cooldown > SECONDS_PER_DAY then
--			cooldownFormatter:SetMinInterval(SecondsFormatter.Interval.Days);
			SetCooldownRemaining(cooldown);
		else
			fontString:SetText(COOLDOWN_EXPIRES_AT_MIDNIGHT);
		end
	end
end
