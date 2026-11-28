local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
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

--
-- If the addon MissingTradeSkillsList is loaded,
-- this plugin adds a button to the SkilletPluginButton (via AddButtonToTradeskillWindow)
-- When clicked, this button will move the MTSL button (MTSLUI_ToggleButton)
-- from its default position above SkilletFrame to just above the SkilletPluginButton
-- when clicked again, it will move it back (its a toggle)
--
Skillet.MTSLPlugin = {}

local plugin = Skillet.MTSLPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "MissingTradeSkillsList",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.MTSL.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.MTSL.enabled = value
				if not value and plugin.setupMTSL then
					plugin.resetButton()
				end
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
		location = {
			type = "select",
			name = "location",
			desc = "MTSL button location",
			order = 1,
			get = function() 
				return Skillet.db.profile.plugins.MTSL.location
			end,
			set = function(_, value)
				Skillet.db.profile.plugins.MTSL.location = value
				Skillet.db.profile.plugins.MTSL.locationUL = (value == 1)
				Skillet.db.profile.plugins.MTSL.locationUR = (value == 2)
				Skillet.db.profile.plugins.MTSL.locationLL = (value == 3)
				Skillet.db.profile.plugins.MTSL.locationLR = (value == 4)
			end,
			values = {
			[1] = L["Upper Left"], 
			[2] = L["Upper Right"],
			[3] = L["Lower Left"],
			[4] = L["Lower Right"],
			},
			width = 0.6,
			style = "radio", -- "dropdown"
			order = 2
		},
	},
}

--
-- Only do something if the MTSLUI_ToggleButton button exists (i.e. the addon MissingTradeSkillsList exists)
--
function plugin.setupButton()
	DA.DEBUG(0,"MTSL Plugin setupButton")
	local button = MTSLUI_ToggleButton
--	local button = plugin.testButton
	if button and Skillet.tradeSkillFrame then
		if not plugin.setupMTSL then
			plugin.oldPoint = {}
			plugin.oldPoint[1], plugin.oldPoint[2], plugin.oldPoint[3], plugin.oldPoint[4], plugin.oldPoint[5] = button:GetPoint(1)
			plugin.oldSize = {}
			plugin.oldSize[1], plugin.oldSize[2] = button:GetSize()
			plugin.setupMTSL = true
		end
	end
end

function plugin.resetButton()
	DA.DEBUG(0,"MTSL Plugin resetButton")
	local button = MTSLUI_ToggleButton
--	local button = plugin.testButton
	if button and Skillet.tradeSkillFrame then
		if not plugin.setupMTSL then
			plugin.setupButton()
		end
		button:SetPoint(plugin.oldPoint[1], plugin.oldPoint[2], plugin.oldPoint[3], plugin.oldPoint[4], plugin.oldPoint[5])
		plugin.setupMTSL = false
	end
end

function plugin.moveButton()
	DA.DEBUG(0,"MTSL Plugin moveButton")
	local button = MTSLUI_ToggleButton
--	local button = plugin.testButton
	if button and Skillet.tradeSkillFrame then
		if not plugin.setupMTSL then
			plugin.setupButton()
		end
		Skillet.db.profile.plugins.MTSL.location = Skillet.db.profile.plugins.MTSL.location + 1
		if Skillet.db.profile.plugins.MTSL.location == 5 then
			Skillet.db.profile.plugins.MTSL.location = 1
		end
		local location = Skillet.db.profile.plugins.MTSL.location
		Skillet.db.profile.plugins.MTSL.locationUL = (location == 1)
		Skillet.db.profile.plugins.MTSL.locationUR = (location == 2)
		Skillet.db.profile.plugins.MTSL.locationLL = (location == 3)
		Skillet.db.profile.plugins.MTSL.locationLR = (location == 4)
		
		plugin.showButton()
	end
end

function plugin.showButton()
	DA.DEBUG(0,"MTSL Plugin showButton")
	local button = MTSLUI_ToggleButton
--	local button = plugin.testButton
	if button and Skillet.tradeSkillFrame then
		if not plugin.setupMTSL then
			plugin.setupButton()
		end
		if Skillet.db.profile.plugins.MTSL.locationUL then
			button:SetParent(SkilletFrame)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", SkilletFrame, "TOPLEFT", 0, 0)
			button:SetSize(plugin.oldSize[1], plugin.oldSize[2])
--			local w, h = button:GetSize()
--			DA.MARK3("location= "..tostring(Skillet.db.profile.plugins.MTSL.location)..", w="..tostring(w)..", h="..tostring(h))
		elseif Skillet.db.profile.plugins.MTSL.locationUR then
			button:SetParent(SkilletFrame)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMRIGHT", SkilletFrame, "TOPRIGHT", 0,0)
			button:SetSize(plugin.oldSize[1], plugin.oldSize[2])
--			local w, h = button:GetSize()
--			DA.MARK3("location= "..tostring(Skillet.db.profile.plugins.MTSL.location)..", w="..tostring(w)..", h="..tostring(h))
		elseif Skillet.db.profile.plugins.MTSL.locationLL then
			button:SetParent(SkilletFrame)
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", SkilletFrame, "BOTTOMLEFT", 0,0)
			button:SetSize(plugin.oldSize[1], plugin.oldSize[2])
--			local w, h = button:GetSize()
--			DA.MARK3("location= "..tostring(Skillet.db.profile.plugins.MTSL.location)..", w="..tostring(w)..", h="..tostring(h))
		elseif Skillet.db.profile.plugins.MTSL.locationLR then
			button:SetParent(SkilletFrame)
			button:ClearAllPoints()
			button:SetPoint("TOPRIGHT", SkilletFrame, "BOTTOMRIGHT", 0,0)
			button:SetSize(plugin.oldSize[1], plugin.oldSize[2])
--			local w, h = button:GetSize()
--			DA.MARK3("location= "..tostring(Skillet.db.profile.plugins.MTSL.location)..", w="..tostring(w)..", h="..tostring(h))
		end
		button:Show()
	end
end

function plugin.OnInitialize()
	DA.DEBUG(0,"MTSL Plugin OnInitialize")
	if not Skillet.db.profile.plugins.MTSL then
		Skillet.db.profile.plugins.MTSL = {}
		Skillet.db.profile.plugins.MTSL.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
--
-- Create the button that will be attached to Skillet-Classic's "Plugin" button
--
	if not Skillet.db.profile.plugins.MTSL.location then
		Skillet.db.profile.plugins.MTSL.location = 1
		Skillet.db.profile.plugins.MTSL.locationUL = true
	end
	if not plugin.moveMTSLButton then
		plugin.moveMTSLButton = CreateFrame("Button", nil, nil, "UIPanelButtonTemplate")
		plugin.moveMTSLButton:SetHeight(20)
		plugin.moveMTSLButton:RegisterForClicks("LeftButtonUp")
		plugin.moveMTSLButton:SetText(L["Move MTSL"])
		plugin.moveMTSLButton:SetScript("OnClick", function(self, mouseButton, isDown)
			plugin.moveButton(self, mouseButton, isDown)
		end)
		if C_AddOns.IsAddOnLoaded("MissingTradeSkillsList") then
			Skillet:AddButtonToTradeskillWindow(plugin.moveMTSLButton)
		end
	end
	if not plugin.testButton then
		plugin.testButton = CreateFrame("Button", nil, nil, "UIPanelButtonTemplate")
		plugin.testButton:SetWidth(40)
		plugin.testButton:SetHeight(20)
		plugin.testButton:SetText(L["TEST"])
	end
	if not C_AddOns.IsAddOnLoaded("MissingTradeSkillsList") then
		Skillet.db.profile.plugins.MTSL.enabled = false
	end
end

--
-- This function is called within the Skillet:UpdateTradeSkillWindow function
--
function plugin.Update()
	--DA.DEBUG(0,"MTSL Plugin Update")
	if not plugin.setupMTSL then
		plugin.setupButton()
	end
	plugin.showButton()
end

Skillet:RegisterUpdatePlugin("MTSLPlugin")		-- we have an Update function
