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

--
-- Called when the grouping operators drop down is displayed
--
function Skillet:RecipeRankSelector_OnClick(this)
	if not Skillet.RecipeRankMenu then
		Skillet.RecipeRankMenu = CreateFrame("Frame", "RecipeRankMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(SkilletRecipeRankDropMenu, Skillet.InitializeRecipeRankDropdown, "MENU")
	ToggleDropDownMenu(1, nil, SkilletRecipeRankDropMenu, this, this:GetWidth(), 0)
end

--
-- The method we use the initialize the group ops drop down.
--
function Skillet.InitializeRecipeRankDropdown(menuFrame,level)
	if level == 1 then
		local entry = {}
		local null = {}
		null.text = ""
		null.disabled = true

		entry.text = "Rank 1"
		entry.value = 1
		entry.func = Skillet.RecipeRankChange
		entry.arg1 = 1
		entry.arg2 = "Rank 1"
		UIDropDownMenu_AddButton(entry)
		if Skillet.recipeRankMax > 1 then
			entry.text = "Rank 2"
			entry.value = 2
			entry.func = Skillet.RecipeRankChange
			entry.arg1 = 2
			entry.arg2 = "Rank 2"
			UIDropDownMenu_AddButton(entry)
		end
		if Skillet.recipeRankMax > 2 then
			entry.text = "Rank 3"
			entry.value = 3
			entry.func = Skillet.RecipeRankChange
			entry.arg1 = 3
			entry.arg2 = "Rank 3"
			UIDropDownMenu_AddButton(entry)
		end
		if Skillet:RecipeRankIsMaxLevel() then  -- Skillet.recipeRankMax > 3
			entry.text = "Rank 4"
			entry.value = 4
			entry.func = Skillet.RecipeRankChange
			entry.arg1 = 4
			entry.arg2 = "Rank 4"
			UIDropDownMenu_AddButton(entry)
		end
	end
end

function Skillet:RecipeRankChange(rank, text)
	DA.DEBUG(0,"RecipeRankChange("..tostring(rank)..", '"..tostring(text).."')")
	Skillet.recipeRank = rank
	SkilletRecipeRankLabel:SetText(text)
	Skillet:UpdateDetailWindow(Skillet.currentSkillIndex)
end

function Skillet:RecipeRankOnEnter(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	if ( self:RecipeRankIsMaxLevel() ) then
		GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK, NORMAL_FONT_COLOR)
		GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK_EXPLANATION, GREEN_FONT_COLOR)
	else
		local experiencePercent = math.floor((self.currentExperience / self.maxExperience) * 100)
		GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_RANK_FORMAT:format(self.recipeRank), NORMAL_FONT_COLOR)
		GameTooltip_AddHighlightLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_EXPERIENCE_FORMAT:format(self.currentExperience, self.maxExperience, experiencePercent))
		GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_LEVELING_FORMAT:format(self.recipeRank + 1), GREEN_FONT_COLOR)
	end
	GameTooltip:Show()
end

function Skillet:RecipeRankOnLeave()
	GameTooltip_Hide()
end

function Skillet:RecipeRankSetExperience(currentExperience, maxExperience, currentLevel)
	self.currentExperience = currentExperience
	self.maxExperience = maxExperience

	if ( self:RecipeRankIsMaxLevel() ) then
		SkilletRecipeRankSkill:SetMinMaxValues(0, 1)
		SkilletRecipeRankSkill:SetValue(1)
		SkilletRecipeRankSkill.Rank:SetText(TRADESKILL_RECIPE_LEVEL_MAXIMUM)
	else
		SkilletRecipeRankSkill:SetMinMaxValues(0, maxExperience)
		SkilletRecipeRankSkill:SetValue(currentExperience)
		SkilletRecipeRankSkill.Rank:SetFormattedText(GENERIC_FRACTION_STRING, currentExperience, maxExperience)
	end
end

function Skillet:RecipeRankIsMaxLevel()
	return self.currentExperience == nil
end

