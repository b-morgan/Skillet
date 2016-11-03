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
Skillet.ATRPlugin.Vendor = { [133588] = 5000, [133589] = 2780, [133590] = 5000, [133591] = 5000, [133592] = 5000, [133593] = 5000 }

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
		useShort = {
			type = "toggle",
			name = "useShort",
			desc = "Use Short money format",
			get = function()
				return Skillet.db.profile.plugins.ATR.useShort
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useShort = value
				if value then
					Skillet.db.profile.plugins.ATR.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = "Only show positive values",
			get = function()
				return Skillet.db.profile.plugins.ATR.onlyPositive
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.onlyPositive = value
				if value then
					Skillet.db.profile.plugins.ATR.onlyPositive = value
				end
			end,
			order = 3
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
	if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
		local abacus = LibStub("LibAbacus-3.0")
		local value = ( Atr_GetAuctionBuyout(itemID) or 0 ) * recipe.numMade
		if value then
			extra_text = abacus:FormatMoneyFull(value, true)
			label = L["Buyout"]..":"
		end
	end
	return label, extra_text
end

function plugin.RecipeNamePrefix(skill, recipe)
	local text
	if not skill or not recipe then return end
	if Skillet.db.profile.plugins.ATR.enabled then
--		Processing goes here
		return text
	end
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if recipe then
		local itemID = recipe.itemID
		if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
			local abacus = LibStub("LibAbacus-3.0")
			local value = Atr_GetAuctionBuyout(itemID) or 0
			if value then
				value = value * recipe.numMade
				local matsum = 0
				for k,v in pairs(recipe.reagentData) do
					local iprice = Atr_GetAuctionBuyout(v.reagentID)
					if tContains(Skillet.ATRPlugin.Vendor,v.reagentID) then
						iprice = Skillet.ATRPlugin.Vendor[v.reagentID]
					end
					if iprice then
						matsum = matsum + v.numNeeded * iprice
					end
				end
				value = value - matsum
				if Skillet.db.profile.plugins.ATR.useShort then
					text = abacus:FormatMoneyShort(value, true)
				else
					text = abacus:FormatMoneyFull(value, true)
				end
				if Skillet.db.profile.plugins.ATR.onlyPositive and value <= 0 then
					text = nil
				end
			end
		end
	end
	return text
end

Skillet:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function
