local addonName,addonTable = ...
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

local L = Skillet.L
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function capitalize(string)
	string = string or ""
	return string.upper(string.sub(string, 1,1)) .. string.lower(string.sub(string, 2))
end

local function ColorCodeText(text, color)
	return string.format("|cff%s%s|r", color, text)
end

local function InitializeDB(self)
	if not Skillet.db.global.NewsDB then
		Skillet.db.global.NewsDB = {}
	end
	self.db = Skillet.db.global.NewsDB
	if not self.db.show_news then
		self.db.show_news = 1
	end
	if not self.db.lastVersion then
		self.db.lastVersion = {}
	end
end

local function Create(self)
	local frame = AceGUI:Create("Window")
	Skillet.NewsFrame = frame
	frame:SetLayout("Flow")
	frame:SetWidth(600)
	local options = {
		type = "group",
		args = {}
	}
	options.args.show_news = {
		name = L["Show News"],
		desc = L["Show news when a new version is released"],
		type = "select",
		values = {
			[1] = "Always", 
			[2] = "Once per Account",
			[3] = "Once per Player",
			[4] = "Never",
		},
		set = function(i, v) self.db.show_news = v end,
		get = function(i) return self.db.show_news end,
		order = 1
	}
	local counter = options.args.show_news.order + 1
	for _,versionData in ipairs(Skillet.NewsData) do
		local args = {}
		for _, group in ipairs(versionData.data) do
			local name = group.name or ""
			args[name..counter..versionData.version.."bar"] = {
				name = capitalize(name),
				type = "header",
				order = counter
			}
			counter = counter + 1
			for i, data in pairs(group.data) do
				args[name..i..versionData.version.."header"] = {
					name = ColorCodeText(data.header,"6699ff"),
					type = "description",
					fontSize = "large",
					order = counter
				}
				counter = counter + 1
				args[name..i..versionData.version.."body"] = {
					name = data.body or "",
					type = "description",
					fontSize = "medium",
					order = counter
				}
				counter = counter + 1
			end
		end
		options.args["version"..counter..versionData.version.."header"] = {
			name = versionData.version,
			type = "group",
			order = counter,
			args = args
		}
		counter = counter + 1
	end
	AceConfigRegistry:RegisterOptionsTable(Skillet.NewsName, options)
	AceConfigDialog:Open(Skillet.NewsName, frame)
	return frame
end

local NewsGUI = {}
function NewsGUI:Initialize()
	DA.DEBUG(0,"NewsGUI:Initialize()")
	InitializeDB(self)
	self:Create()
	self._initialized = true
	self.top:SetWidth(700)
	self.top:SetHeight(500)
end

function NewsGUI:Create()
	DA.DEBUG(0,"NewsGUI:Create()")
	local f = Create(self)
	self.top = f
--
-- Display based on show_news dropdown:
--	[1] = "Always", 
--	[2] = "Once per Account",
--	[3] = "Once per Player",
--	[4] = "Never",
--
	local player = UnitName("player")
	local version = Skillet.version
	--DA.DEBUG(1,"NewsGUI:Create: show_news= "..tostring(self.db.show_news)..", player= "..tostring(player)..", version= "..tostring(version))
	--DA.DEBUG(1,"NewsGUI:Create: lastVersionA= "..tostring(self.db.lastVersionA)..", lastVersion[player]= "..tostring(self.db.lastVersion[player]))
	if self.db.show_news == 4 or
	  (self.db.show_news == 3 and self.db.lastVersion[player] and self.db.lastVersion[player] == version) or
	  (self.db.show_news == 2 and self.db.lastVersionA and self.db.lastVersionA == version) then
		f:Hide()
	end
	self.db.lastVersionA = version
	self.db.lastVersion[player] = version
end

function NewsGUI:Toggle()
	DA.DEBUG(0,"NewsGUI:Toggle()")
	if not self._initialized then return end
	if self.top:IsVisible() then
		self.top:Hide()
	else
		self.top:Show()
	end
end

function NewsGUI:Reset()
	DA.DEBUG(0,"NewsGUI:Reset()")
	self.top:ClearAllPoints()
	self.top:SetPoint("CENTER", 0, 0)
end

Skillet.NewsGUI = NewsGUI
