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

Skillet.CIMIPlugin = {}

local plugin = Skillet.CIMIPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "CanIMogIt",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.CIMI.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.CIMI.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.CIMI then
		Skillet.db.profile.plugins.CIMI = {}
		Skillet.db.profile.plugins.CIMI.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.RecipeNamePrefix(skill, recipe)
	if not skill or not recipe then return end
	if CanIMogIt and CanIMogIt.GetIconText then
		local itemLink = select(2, GetItemInfo(recipe.itemID))
		if itemLink then
			local icon = CanIMogIt:GetIconText(itemLink)
			if icon ~= "" then
				return icon
			end
		end
	end
end

function plugin.GetExtraText(skill, recipe)
	if CanIMogIt and CanIMogIt.GetIconText and Skillet.db.profile.plugins.CIMI.enabled then
		return "CanIMogIt:", (plugin.RecipeNamePrefix(skill, recipe) or "No")
	end
end

Skillet:RegisterRecipeNamePlugin("CIMIPlugin") -- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("CIMIPlugin") -- necessary for options
