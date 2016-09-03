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

Skillet.ARLPlugin = {}

local plugin = Skillet.ARLPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "AckisRecipeList",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.ARL.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ARL.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.ARL then
		Skillet.db.profile.plugins.ARL = {}
		Skillet.db.profile.plugins.ARL.enabled = true
	end
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet AckisRecipeList", plugin.options)
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet AckisRecipeList", "AckisRecipeList", "Skillet")
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if AckisRecipeList and AckisRecipeList.InitRecipeData and Skillet.db.profile.plugins.ARL.enabled then
		local _, recipeList, mobList, trainerList = AckisRecipeList:InitRecipeData()
		local recipeData = AckisRecipeList:GetRecipeData(skill.id)
		if recipeData == nil and not ARLProfessionInitialized[recipe.tradeID] then
			ARLProfessionInitialized[recipe.tradeID] = true
			local profession = GetSpellInfo(recipe.tradeID)
			AckisRecipeList:AddRecipeData(profession)
			recipeData = AckisRecipeList:GetRecipeData(skill.id)
		end
		if recipeData then
			extra_text = AckisRecipeList:GetRecipeLocations(skill.id)
			if extra_text == "" then extra_text = nil end
		end
		label = "Source:"
	end
	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("ARLPlugin")
