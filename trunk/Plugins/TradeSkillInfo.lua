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
	local extra_text, label
	local bop

	if not skill or not recipe then return end

	if TradeskillInfo then
-- tsi uses itemIDs for skill indices instead of enchantID numbers.  for enchants, the enchantID is negated to avoid overlaps
		local tsiRecipeID = recipe.itemID

		if tsiRecipeID == 0 and recipe.spellID then
			tsiRecipeID = -recipe.spellID
		elseif tsiRecipeID then
			tsiRecipeID = TradeskillInfo:MakeSpecialCase(tsiRecipeID, recipe.spellID)
		end

		if tsiRecipeID then
			local combineID = TradeskillInfo:GetCombineRecipe(tsiRecipeID)


			if combineID then
				_, extra_text = Skillet:TSIGetRecipeSources(combineID, false)

				if not extra_text then
					extra_text = L["Trained"].." ("..(TradeskillInfo:GetCombineLevel(tsiRecipeID) or "??")..")"
				end

					--		SkilletExtraDetailText.dataSource = "TradeSkillInfo Mod - version "..(TradeskillInfo.version or "?")
--				local _, link = GetItemInfo(combineID)
--DEFAULT_CHAT_FRAME:AddMessage("recipe: "..(link or combineID))
				if Skillet:bopCheck(combineID) then
					bop = true
				end

			else
				extra_text = "|cffff0000"..L["Unknown"].."|r"
			end

		else
			--extra_text = "can't find recipeID for item "..recipe.itemID
			extra_text = ""
		end


		if bop then
			label = GRAY_FONT_COLOR_CODE..L["Source:"].."\n|cffff0000(*BOP*)|r"
			extra_text = extra_text.."\n"
		else
			label = GRAY_FONT_COLOR_CODE..L["Source:"]..FONT_COLOR_CODE_CLOSE
		end

	end

	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("TSIPlugin")
