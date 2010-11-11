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

function plugin.GetExtraText(skill, recipe)
	local extra_text, label
	
	if not skill or not recipe then return end
	
	local daysNum = 30
	local itemID = recipe.itemID

	local L = Skillet.L

	if BeanCounterDB and itemID then

		local server = GetRealmName()

		label="\n"..GRAY_FONT_COLOR_CODE;
		label=label..L["Sold amount:"].."\n";
		label=label..L["Gold earned:"]..FONT_COLOR_CODE_CLOSE;

		if not BeanCounterDB[server] then return end

		local now = time()
		local success, failed, sucessStack, failedStack, earned = 0, 0, 0, 0, 0
		local days = daysNum * 86400 --days to seconds

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

		local abacus = LibStub("LibAbacus-3.0")

		extra_text = L["Sells for "]..daysNum..L[" days"].."\n"
		extra_text = extra_text..GREEN_FONT_COLOR_CODE..sucessStack..FONT_COLOR_CODE_CLOSE.." / "..RED_FONT_COLOR_CODE..failedStack.."\n"
		extra_text = extra_text..FONT_COLOR_CODE_CLOSE..abacus:FormatMoneyFull(earned, true);
	end

	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("BCPlugin")
