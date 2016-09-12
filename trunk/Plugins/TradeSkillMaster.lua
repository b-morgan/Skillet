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

Skillet.TSMPlugin = {}

local plugin = Skillet.TSMPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "TradeskillMaster",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.TSM.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.TSM.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.TSM then
		Skillet.db.profile.plugins.TSM = {}
		Skillet.db.profile.plugins.TSM.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.OnEnable()
	plugin.TSM = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	--DA.DEBUG(0,"plugin.TSM= "..tostring(plugin.TSM))
	if plugin.TSM and plugin.TSM.CraftingGUI then
		plugin.GUI = plugin.TSM.CraftingGUI
		plugin.ShowProfessionWindow = plugin.GUI.ShowProfessionWindow
		plugin.GUI.ShowProfessionWindow = function () end
	end
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if TSMAPI and TSMAPI.GetItemValue and Skillet.db.profile.plugins.TSM.enabled and itemID then
		local abacus = LibStub("LibAbacus-3.0")
		local value = TSMAPI:GetItemValue(itemID, "DBMarket")
		if value then
			extra_text = abacus:FormatMoneyFull(value, true);
			label = "DBMarket"..":"
--			label = L["DBMarket"]..":"
		end
	end
	return label, extra_text
end

function plugin.TSMShow()
	DA.DEBUG(0,"TSMShow()")
	if plugin.TSM and plugin.GUI and plugin.ShowProfessionWindow then
		plugin.ShowProfessionWindow();
	end
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if recipe then
		local itemID = recipe.itemID
		if TSMAPI and TSMAPI.GetItemValue and Skillet.db.profile.plugins.TSM.enabled and itemID then
			local abacus = LibStub("LibAbacus-3.0")
			local value = TSMAPI:GetItemValue(itemID, "DBMarket")
			if value then
				text = abacus:FormatMoneyFull(value, true);
			end
		end
	end
	return text
end

Skillet:RegisterRecipeNamePlugin("TSMPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("TSMPlugin")
