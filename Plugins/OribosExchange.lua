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

--[[
	o={}
	OEMarketInfo(item,o)

The item can be identified by anything C_Item.GetItemInfo takes (itemid, itemstring, itemlink) or a battlepet itemstring/itemlink.
Prices are returned in copper, but accurate to the last *silver* (with coppers always 0).

	o['input']			-> the item/battlepet parameter you just passed in, verbatim
	o['itemid']			-> the ID of the item you just passed in
	o['bonuses']		-> if present, a colon-separated list of bonus IDs that were considered as uniquely identifying the item for pricing
	o['species']		-> the species of the battlepet you just passed in
	o['breed']			-> the numeric breed ID of the battlepet
	o['quality']		-> the numeric quality/rarity of the battlepet
	o['age']			-> number of seconds since data was compiled
	o['globalMedian']	-> median market price across all realms in this region
	o['globalMean']		-> mean market price across all realms in this region
	o['globalStdDev']	-> standard deviation of the market price across all realms in this region
	o['market']			-> average market price of the item on this AH over the past 14 days.
	o['stddev']			-> standard deviation of market price of the item on this AH over the past 14 days.
	o['recent']			-> average market price of the item on this AH over the past 3 days.
	o['days']			-> number of days since item was last seen on the auction house, when data was compiled. valid values 0 - 250.
		o['days'] = 251 means item was seen on this AH, but over 250 days ago
		o['days'] = 252 means the item is sold by vendors in unlimited quantities
		o['days'] = 255 means item was never seen on this AH (since 6.0 patch)

	OETooltip()		-> returns a boolean whether OE tooltips are enabled
	OETooltip(true)	-> enables OE tooltips
	OETooltip(false)	-> disables OE tooltips
]]--

Skillet.OEPlugin = {}

local plugin = Skillet.OEPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "OribosExchange",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.OE.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.OE.enabled = value
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
				return Skillet.db.profile.plugins.OE.useShort
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.OE.useShort = value
				if value then
					Skillet.db.profile.plugins.OE.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = "Only show positive values",
			get = function()
				return Skillet.db.profile.plugins.OE.onlyPositive
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.OE.onlyPositive = value
				if value then
					Skillet.db.profile.plugins.OE.onlyPositive = value
				end
			end,
			order = 3
		},
		colorCode = {
			type = "toggle",
			name = "colorCode",
			desc = "Add color to the results",
			get = function()
				return Skillet.db.profile.plugins.OE.colorCode
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.OE.colorCode = value
				if value then
					Skillet.db.profile.plugins.OE.colorCode = value
				end
			end,
			order = 4
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.OE then
		Skillet.db.profile.plugins.OE = {}
		Skillet.db.profile.plugins.OE.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if OEMarketInfo and Skillet.db.profile.plugins.OE.enabled and itemID then
		local o={}
		OEMarketInfo(itemID,o)
		local value = o['market']
		if value then
			extra_text = Skillet:FormatMoneyFull(value, true);
			label = "|r"..L["OEMarket"]..":"
		end
	end
	return label, extra_text
end

local function OEMarketValue(itemID)
	local o = {}
	OEMarketInfo(itemID,o)
	return o['market']
end

--
-- Returns a text representation of value, numerical value (for sorting purposes)
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if recipe then
		local itemID = recipe.itemID
		if OEMarketInfo and Skillet.db.profile.plugins.OE.enabled and itemID then
			local value = OEMarketValue(itemID)
			if value then
				value = value * recipe.numMade
				local matsum = 0
				for k,v in pairs(recipe.reagentData) do
					local iprice = OEMarketValue(v.reagentID)
					if iprice then
						matsum = matsum + v.numNeeded * iprice
					end
				end
				value = value - matsum
				if Skillet.db.profile.plugins.OE.useShort then
					text = Skillet:FormatMoneyShort(value, true, Skillet.db.profile.plugins.OE.colorCode)
				else
					text = Skillet:FormatMoneyFull(value, true, Skillet.db.profile.plugins.OE.colorCode)
				end
				if Skillet.db.profile.plugins.OE.onlyPositive and value <= 0 then
					text = nil
				end
			end
		end
	end
	recipe.suffix = value
	return text, value
end

Skillet:RegisterRecipeNamePlugin("OEPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("OEPlugin")	-- we have a GetExtraText function
