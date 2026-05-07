local addonName,addonTable = ...
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE -- 1
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC -- 2
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC -- 5
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC -- 11
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC -- 14
local isMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC -- 19
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end
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
	--DA.DEBUG(0,"CIMI:OnInitialize()")
	if not Skillet.db.profile.plugins.CIMI then
		Skillet.db.profile.plugins.CIMI = {}
		Skillet.db.profile.plugins.CIMI.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.RecipeNamePrefix(skill, recipe)
	--DA.DEBUG(0,"CIMI:RecipeNamePrefix("..tostring(skill)..", "..tostring(recipe)..")")
	if not skill or not recipe then return end
	if CanIMogIt and CanIMogIt.GetIconText and Skillet.db.profile.plugins.CIMI.enabled then
		local itemLink = select(2, C_Item.GetItemInfo(recipe.itemID))
		if itemLink then
			local icon = CanIMogIt:GetIconText(itemLink)
			if icon ~= "" then
				return icon
			end
		end
	end
end

function plugin.GetExtraText(skill, recipe)
	--DA.DEBUG(0,"CIMI:GetExtraText("..tostring(skill)..", "..tostring(recipe)..")")
	if CanIMogIt and CanIMogIt.GetIconText and Skillet.db.profile.plugins.CIMI.enabled then
		return "|rCanIMogIt:", (plugin.RecipeNamePrefix(skill, recipe) or "No")
	end
end

Skillet:RegisterRecipeNamePlugin("CIMIPlugin") -- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("CIMIPlugin") -- necessary for options
