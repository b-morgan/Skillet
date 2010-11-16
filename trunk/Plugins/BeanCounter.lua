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


Skillet.BCPlugin = {}

local plugin = Skillet.BCPlugin
local L = Skillet.L

plugin.options =
{
        type = 'group',
        name = "BeanCounter",
        order = 1,
        args = {
            enabled = {
                type = "toggle",
                name = L["Enabled"],
                get = function()
                    return Skillet.db.profile.plugins.beancounter.enabled
                end,
                set = function(self,value)
                    Skillet.db.profile.plugins.beancounter.enabled = value
                    Skillet:UpdateTradeSkillWindow()
                end,
				width = "double",
                order = 1
            },
            days = {
                type = "range",
                name = L["Sells for "].."x"..L[" days"],
                min = 1, max = 180, step = 1, isPercent = false,
                get = function()
                    return Skillet.db.profile.plugins.beancounter.days
                end,
                set = function(self,t)
                    Skillet.db.profile.plugins.beancounter.days = t
                    Skillet:UpdateTradeSkillWindow()
                end,
				width = "double",
                order = 2,
            },
        },
}


	function plugin.SortGoldEarned(skill,a,b)
		while a.subGroup and #a.subGroup.entries>0 do
			a = a.subGroup.entries[1]
		end

		while b.subGroup and #b.subGroup.entries>0 do
			b = b.subGroup.entries[1]
		end

		local _, _, _, _, itemValueA = plugin.GetBCValues(a.itemID) or 0
		local _, _, _, _, itemValueB = plugin.GetBCValues(b.itemID) or 0

		itemValueA = itemValueA or 0
		itemValueB = itemValueB or 0

		return (itemValueA > itemValueB)
	end

	function plugin.SortSoldAmount(skill,a,b)
		while a.subGroup and #a.subGroup.entries>0 do
			a = a.subGroup.entries[1]
		end

		while b.subGroup and #b.subGroup.entries>0 do
			b = b.subGroup.entries[1]
		end

		local _, _, itemValueA = plugin.GetBCValues(a.recipeData.itemID)
		local _, _, itemValueB = plugin.GetBCValues(a.recipeData.itemID)

		itemValueA = itemValueA or 0
		itemValueB = itemValueB or 0

		--DEFAULT_CHAT_FRAME:AddMessage(a.name.." "..itemValueA.." "..(a.recipeData.itemID or 0))
		--DEFAULT_CHAT_FRAME:AddMessage(b.name.." "..itemValueB.." "..(a.recipeData.itemID or 0))

		return (itemValueA > itemValueB)
	end

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.beancounter then
		Skillet.db.profile.plugins.beancounter = {}
	end
	if not Skillet.db.profile.plugins.beancounter.enabled then
		Skillet.db.profile.plugins.beancounter.enabled = true
	end
	if not Skillet.db.profile.plugins.beancounter.days then
		Skillet.db.profile.plugins.beancounter.days = 30
	end
	local acecfg = LibStub("AceConfig-3.0")
    acecfg:RegisterOptionsTable("Skillet BeanCounter", plugin.options)

	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet BeanCounter", "BeanCounter", "Skillet")

	--Skillet:AddRecipeSorter("BC: "..L["Sold amount"], plugin.SortSoldAmount)
	--Skillet:AddRecipeSorter("BC: "..L["Gold earned"], plugin.SortGoldEarned)
end


function plugin.GetBCValues(itemID)
		local success, failed, sucessStack, failedStack, earned = 0, 0, 0, 0, 0
		local daysNum = Skillet.db.profile.plugins.beancounter.days or 0
		local server = GetRealmName()

		local now = time()
		local days = daysNum * 86400 --days to seconds

		if itemID and BeanCounterDB[server] then
			itemID = tostring(itemID)
			for _, playerData in pairs(BeanCounterDB[server]) do
				if playerData["completedAuctions"][itemID] then
					for key in pairs(playerData["completedAuctions"][itemID] ) do
						for i, text in pairs(playerData["completedAuctions"][itemID][key]) do
							local stack, money, deposit, _, _, _, _, auctime = strsplit(";", text)
							auctime, stack, deposit, money = tonumber(auctime), tonumber(stack), tonumber(deposit), tonumber(money)

							if (now - auctime) < (days) then
								success = success + 1
								sucessStack = sucessStack + stack
								earned = earned + money - deposit
							end
						end
					end
				end
				if playerData["failedAuctions"][itemID] then
					for key in pairs(playerData["failedAuctions"][itemID]) do
						for i, text in pairs(playerData["failedAuctions"][itemID][key]) do
							local stack, _, deposit, _, _, _, _, auctime = strsplit(";", text)
							auctime, stack, deposit = tonumber(auctime), tonumber(stack), tonumber(deposit)

							if (now - auctime) < (days) then
								failed = failed + 1
								failedStack = failedStack + stack
								earned = earned - deposit
							end
						end
					end
				end
			end

		end
		return success, failed, sucessStack, failedStack, earned
end

function plugin.GetExtraText(skill, recipe)
	local extra_text, label

	if not skill or not recipe then return end


	local itemID = recipe.itemID

	local L = Skillet.L

	if BeanCounterDB and itemID and Skillet.db.profile.plugins.beancounter.enabled then

		if BeanCounter and BeanCounterUiFrame and BeanCounterUiFrame:IsVisible() then
				name = GetItemInfo(itemID)
				if name then
					BeanCounter.API.search(name)
				end
		end

		label="\n"..GRAY_FONT_COLOR_CODE;
		label=label..L["Sold amount"]..":\n";
		label=label..L["Gold earned"]..":"..FONT_COLOR_CODE_CLOSE;

		local success, failed, sucessStack, failedStack, earned  = plugin.GetBCValues(itemID)

		local abacus = LibStub("LibAbacus-3.0")

		extra_text = L["Sells for "]..(Skillet.db.profile.plugins.beancounter.days or 0)..L[" days"].."\n"
		extra_text = extra_text..GREEN_FONT_COLOR_CODE..sucessStack..FONT_COLOR_CODE_CLOSE.." / "..RED_FONT_COLOR_CODE..failedStack.."\n"
		extra_text = extra_text..FONT_COLOR_CODE_CLOSE..abacus:FormatMoneyFull(earned, true);
	end

	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("BCPlugin")
