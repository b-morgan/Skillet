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

-- This file contains all the code I use to access recipe/tradeskill information

-- If an item requires a specific level before it can be used, then
-- the level is returned, otherwise 0 is returned
--
-- item can be: itemID or "itemString" or "itemName" or "itemLink"

function Skillet:GetLevelRequiredToUse(item)
	if not item then return end
		local level = select(5, GetItemInfo(item))
	if not level then level = 0 end
	return level
end

function Skillet:GetItemIDFromLink(link)	-- works with items or enchants
	if (link) then
		local linktype, id = string.match(link, "|H([^:]+):(%d+)")
		if id then
			return tonumber(id);
		else
			return nil
		end
	end
end

-- return GetItemInfo and automatically query server if not cached
function Skillet:GetItemInfo(id)
	if id then
		local name = GetItemInfo(id)
		if not name then
			GameTooltip:SetHyperlink("item:"..id)
			GameTooltip:SetHyperlink("enchant:"..id)
		end
		return GetItemInfo(id)
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
		local _, link = GetItemInfo(recipe.itemID)
		return link
	end
		return nil
end

function Skillet:AdjustNumberMade(index, adjust)
	--DA.DEBUG(0,"AdjustNumberMade("..tostring(index)..", adjust= "..tostring(adjust)..")")
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, index)
	local minMade,maxMade = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID)
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

function Skillet:GetTradeSkillNumReagents(skillIndex)
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		return #recipe.reagentData
	end
end

-- Returns a link for the reagent required to create the specified
-- item, the index'th reagent required for the item is returned
function Skillet:GetRecipeReagentItemLink(skillIndex, index)
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and recipe.reagentData[index] then
			local _, link = GetItemInfo(recipe.reagentData[index].reagentID)
			return link;
		end
	end
		return nil
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
	DA.DEBUG(0,"GetTradeSkillLine "..(tradeName or "nil").." "..(rank or "nil").." "..(maxRank or "nil"))	
	return tradeName, rank, maxRank
end
