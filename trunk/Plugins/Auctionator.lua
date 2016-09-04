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

Skillet.ATRPlugin = {}

local plugin = Skillet.ATRPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "Auctionator",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.ATR.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.ATR then
		Skillet.db.profile.plugins.ATR = {}
		Skillet.db.profile.plugins.ATR.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.TUJ.enabled and itemID then
		local abacus = LibStub("LibAbacus-3.0")
		local value = Atr_GetAuctionBuyout(itemID)
		if value then
			extra_text = abacus:FormatMoneyFull(value, true);
			label = "Buyout"..":"
--			label = L["Buyout"]..":"
		end
	end
	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")
