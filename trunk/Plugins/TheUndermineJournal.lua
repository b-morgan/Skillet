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
	TUJMarketInfo(item,o)

The item can be identified by anything GetItemInfo takes (itemid, itemstring, itemlink) or a battlepet itemstring/itemlink.
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

	TUJTooltip()		-> returns a boolean whether TUJ tooltips are enabled
	TUJTooltip(true)	-> enables TUJ tooltips
	TUJTooltip(false)	-> disables TUJ tooltips
]]--

Skillet.TUJPlugin = {}

local plugin = Skillet.TUJPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "TheUndermineJournal",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.TUJ.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.TUJ.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.TUJ then
		Skillet.db.profile.plugins.TUJ = {}
		Skillet.db.profile.plugins.TUJ.enabled = true
	end
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet TheUndermineJournal", plugin.options)
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet TheUndermineJournal", "TheUndermineJournal", "Skillet")
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if TUJMarketInfo and Skillet.db.profile.plugins.TUJ.enabled and itemID then
		local abacus = LibStub("LibAbacus-3.0")
		local o={}
		TUJMarketInfo(itemID,o)
		local value = o['market']
		if value then
			extra_text = abacus:FormatMoneyFull(value, true);
			label = "Market"..":"
--			label = L["Market"]..":"
		end
	end
	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("TUJPlugin")
