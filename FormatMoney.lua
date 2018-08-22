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

-- These FormatMoney* functions were shamelessly copied from LibAbacus-3.0

local L = Skillet.L

local gsub = string.gsub

local COPPER_ABBR
local SILVER_ABBR
local GOLD_ABBR
local GOLD, SILVER, COPPER = GOLD, SILVER, COPPER

if not COPPER and COPPER_AMOUNT then
	GOLD = GOLD_AMOUNT:gsub("%s*%%d%s*", "")
	SILVER = SILVER_AMOUNT:gsub("%s*%%d%s*", "")
	COPPER = COPPER_AMOUNT:gsub("%s*%%d%s*", "")
end

if (COPPER:byte(1) or 128) > 127 then
	-- non-western
	COPPER_ABBR = COPPER
	SILVER_ABBR = SILVER
	GOLD_ABBR = GOLD
else
	COPPER_ABBR = COPPER:sub(1, 1):lower()
	SILVER_ABBR = SILVER:sub(1, 1):lower()
	GOLD_ABBR = GOLD:sub(1, 1):lower()
end

local COLOR_WHITE = "ffffff"
local COLOR_GREEN = "00ff00"
local COLOR_RED = "ff0000"
local COLOR_COPPER = "eda55f"
local COLOR_SILVER = "c7c7cf"
local COLOR_GOLD = "ffd700"

local L_UNDETERMINED = "Undetermined"

if ( GetLocale() =="koKR" ) then
	L_UNDETERMINED = "측정불가"
elseif ( GetLocale() == "zhTW" ) then
	COPPER_ABBR = "銅"
	SILVER_ABBR = "銀"
	GOLD_ABBR = "金"

	L_UNDETERMINED = "未定義的"
	
--***************************************
-- zhCN Chinese Simplify
-- 2007/09/19 CN3羽月 雪夜之狼
-- 请保留本翻译作者名 谢谢
-- E=mail:xionglingfeng@Gmail.com
-- Website:http://www.wowtigu.org  (Chs)
--***************************************
elseif ( GetLocale() == "zhCN" ) then
	COPPER_ABBR = "铜"
	SILVER_ABBR = "银"
	GOLD_ABBR = "金"

	L_UNDETERMINED = "未定义的"
--***************************************
-- ruRU Russian, 2008-08-04
-- Author: SLA80, sla80x at Gmail com
--***************************************
elseif ( GetLocale() == "ruRU" ) then
	GOLD, SILVER, COPPER = "золота", "серебра", "меди"
	GOLD_ABBR, SILVER_ABBR, COPPER_ABBR = "з", "с", "м"

	L_UNDETERMINED = "Неопределено"
end

local inf = math.huge

function Skillet:FormatMoneyExtended(value, colorize, textColor)
	local gold = abs(value / 10000)
	local silver = abs(mod(value / 100, 100))
	local copper = abs(mod(value, 100))
	
	local negl = ""
	local color = COLOR_WHITE
	if value > 0 then
		if textColor then
			color = COLOR_GREEN
		end
	elseif value < 0 then
		negl = "-"
		if textColor then
			color = COLOR_RED
		end
	end
	if colorize then
		if value == inf or value == -inf then
			return format("|cff%s%s|r", color, value)
		elseif value ~= value then
			return format("|cff%s0|r|cff%s %s|r", COLOR_WHITE, COLOR_COPPER, COPPER)
		elseif value >= 10000 or value <= -10000 then
			return format("|cff%s%s%d|r|cff%s %s|r |cff%s%d|r|cff%s %s|r |cff%s%d|r|cff%s %s|r", color, negl, gold, COLOR_GOLD, GOLD, color, silver, COLOR_SILVER, SILVER, color, copper, COLOR_COPPER, COPPER)
		elseif value >= 100 or value <= -100 then
			return format("|cff%s%s%d|r|cff%s %s|r |cff%s%d|r|cff%s %s|r", color, negl, silver, COLOR_SILVER, SILVER, color, copper, COLOR_COPPER, COPPER)
		else
			return format("|cff%s%s%d|r|cff%s %s|r", color, negl, copper, COLOR_COPPER, COPPER)
		end
	else
		if value == inf or value == -inf then
			return format("%s", value)
		elseif value ~= value then
			return format("0 %s", COPPER)
		elseif value >= 10000 or value <= -10000 then
			return format("%s%d %s %d %s %d %s", negl, gold, GOLD, silver, SILVER, copper, COPPER)
		elseif value >= 100 or value <= -100 then
			return format("%s%d %s %d %s", negl, silver, SILVER, copper, COPPER)
		else
			return format("%s%d %s", negl, copper, COPPER)
		end
	end
end

function Skillet:FormatMoneyFull(value, colorize, textColor)
	local gold = abs(value / 10000)
	local silver = abs(mod(value / 100, 100))
	local copper = abs(mod(value, 100))
	
	local negl = ""
	local color = COLOR_WHITE
	if value > 0 then
		if textColor then
			color = COLOR_GREEN
		end
	elseif value < 0 then
		negl = "-"
		if textColor then
			color = COLOR_RED
		end
	end
	if colorize then
		if value == inf or value == -inf then
			return format("|cff%s%s|r", color, value)
		elseif value ~= value then
			return format("|cff%s0|r|cff%s%s|r", COLOR_WHITE, COLOR_COPPER, COPPER_ABBR)
		elseif value >= 10000 or value <= -10000 then
			return format("|cff%s%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r", color, negl, gold, COLOR_GOLD, GOLD_ABBR, color, silver, COLOR_SILVER, SILVER_ABBR, color, copper, COLOR_COPPER, COPPER_ABBR)
		elseif value >= 100 or value <= -100 then
			return format("|cff%s%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r", color, negl, silver, COLOR_SILVER, SILVER_ABBR, color, copper, COLOR_COPPER, COPPER_ABBR)
		else
			return format("|cff%s%s%d|r|cff%s%s|r", color, negl, copper, COLOR_COPPER, COPPER_ABBR)
		end
	else
		if value == inf or value == -inf then
			return format("%s", value)
		elseif value ~= value then
			return format("0%s", COPPER_ABBR)
		elseif value >= 10000 or value <= -10000 then
			return format("%s%d%s %d%s %d%s", negl, gold, GOLD_ABBR, silver, SILVER_ABBR, copper, COPPER_ABBR)
		elseif value >= 100 or value <= -100 then
			return format("%s%d%s %d%s", negl, silver, SILVER_ABBR, copper, COPPER_ABBR)
		else
			return format("%s%d%s", negl, copper, COPPER_ABBR)
		end
	end
end

function Skillet:FormatMoneyShort(copper, colorize, textColor)
	local color = COLOR_WHITE
	if textColor then
		if copper > 0 then
			color = COLOR_GREEN
		elseif copper < 0 then
			color = COLOR_RED
		end
	end
	if colorize then
		if copper == inf or copper == -inf then
			return format("|cff%s%s|r", color, copper)
		elseif copper ~= copper then
			return format("|cff%s0|r|cff%s%s|r", COLOR_WHITE, COLOR_COPPER, COPPER_ABBR)
		elseif copper >= 10000 or copper <= -10000 then
			return format("|cff%s%.1f|r|cff%s%s|r", color, copper / 10000, COLOR_GOLD, GOLD_ABBR)
		elseif copper >= 100 or copper <= -100 then
			return format("|cff%s%.1f|r|cff%s%s|r", color, copper / 100, COLOR_SILVER, SILVER_ABBR)
		else
			return format("|cff%s%d|r|cff%s%s|r", color, copper, COLOR_COPPER, COPPER_ABBR)
		end
	else
		if value == copper or value == -copper then
			return format("%s", copper)
		elseif copper ~= copper then
			return format("0%s", COPPER_ABBR)
		elseif copper >= 10000 or copper <= -10000 then
			return format("%.1f%s", copper / 10000, GOLD_ABBR)
		elseif copper >= 100 or copper <= -100 then
			return format("%.1f%s", copper / 100, SILVER_ABBR)
		else
			return format("%.0f%s", copper, COPPER_ABBR)
		end
	end
end

function Skillet:FormatMoneyCondensed(value, colorize, textColor)
	local negl = ""
	local negr = ""
	if value < 0 then
		if colorize and textColor then
			negl = "|cffff0000-(|r"
			negr = "|cffff0000)|r"
		else
			negl = "-("
			negr = ")"
		end
	end
	local gold = floor(math.abs(value) / 10000)
	local silver = mod(floor(math.abs(value) / 100), 100)
	local copper = mod(floor(math.abs(value)), 100)
	if colorize then
		if value == inf or value == -inf then
			return format("%s|cff%s%s|r%s", negl, COLOR_COPPER, math.abs(value), negr)
		elseif value ~= value then
			return format("|cff%s0|r", COLOR_COPPER)
		elseif gold ~= 0 then
			return format("%s|cff%s%d|r.|cff%s%02d|r.|cff%s%02d|r%s", negl, COLOR_GOLD, gold, COLOR_SILVER, silver, COLOR_COPPER, copper, negr)
		elseif silver ~= 0 then
			return format("%s|cff%s%d|r.|cff%s%02d|r%s", negl, COLOR_SILVER, silver, COLOR_COPPER, copper, negr)
		else
			return format("%s|cff%s%d|r%s", negl, COLOR_COPPER, copper, negr)
		end
	else
		if value == inf or value == -inf then
			return tostring(value)
		elseif value ~= value then
			return "0"
		elseif gold ~= 0 then
			return format("%s%d.%02d.%02d%s", negl, gold, silver, copper, negr)
		elseif silver ~= 0 then
			return format("%s%d.%02d%s", negl, silver, copper, negr)
		else
			return format("%s%d%s", negl, copper, negr)
		end
	end
end
