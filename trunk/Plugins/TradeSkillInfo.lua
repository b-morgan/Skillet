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

]]--


Skillet.TSIPlugin = {}

local plugin = Skillet.TSIPlugin
local L = Skillet.L

function plugin.GetExtraText(skill, recipe)
	if not TradeskillInfo then return end
	if not skill or not recipe then return end

	local _, bop, extra_text
	local label = GRAY_FONT_COLOR_CODE..L["Source:"]..FONT_COLOR_CODE_CLOSE

	local tsiRecipeID = recipe.spellID

	if tsiRecipeID then
		local combineID = TradeskillInfo:GetCombineRecipe(tsiRecipeID)

		if combineID then
			_, extra_text = Skillet:TSIGetRecipeSources(combineID, false)

			if not extra_text then
				extra_text = L["Trained"].." ("..( TradeskillInfo:GetCombineLevel(tsiRecipeID) or "??" )..")"
			end

--			local _, link = GetItemInfo(combineID)
--			DEFAULT_CHAT_FRAME:AddMessage("recipe: "..(link or combineID))

			if TradeskillInfo:ShowingSkillAuctioneerProfit() then -- insert item value and reagent costs from Auctioneer
				local value, cost, profit = TradeskillInfo:GetCombineAuctioneerCost(tsiRecipeID)

				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Auction Profit:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..("%s - %s = %s"):format( TradeskillInfo:GetMoneyString(value), TradeskillInfo:GetMoneyString(cost), TradeskillInfo:GetMoneyString(profit) )
			end

			if TradeskillInfo:ShowingSkillProfit() then -- insert item value and reagent costs
				local value, cost, profit = TradeskillInfo:GetCombineCost(tsiRecipeID)

				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Vendor Profit:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..("%s - %s = %s"):format( TradeskillInfo:GetMoneyString(value), TradeskillInfo:GetMoneyString(cost), TradeskillInfo:GetMoneyString(profit) )
			end

			if TradeskillInfo:ShowingSkillLevel() then
				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Skill Levels:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..TradeskillInfo:GetColoredDifficulty(tsiRecipeID)
			end

			if Skillet:bopCheck(combineID) then
				bop = true
			end

		else
			extra_text = "|cffff0000"..L["Unknown"].."|r"
		end
	end

	if bop then
		label = label.."\n|cffff0000(*BOP*)|r"
	end

	return label, extra_text
end


Skillet:RegisterDisplayDetailPlugin("TSIPlugin")
