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
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	--DA.DEBUG(0,"MTSL Plugin OnInitialize")
	if not Skillet.db.profile.plugins.MTSL then
		Skillet.db.profile.plugins.MTSL = {}
		Skillet.db.profile.plugins.MTSL.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
--
-- Create the button that will be attached to Skillet-Classic's "Plugin" button
--
	if not plugin.moveMTSLButton then
		plugin.moveMTSLButton = CreateFrame("Button", nil, nil, "UIPanelButtonTemplate")
		plugin.moveMTSLButton:SetHeight(20)
		plugin.moveMTSLButton:RegisterForClicks("LeftButtonUp")
		plugin.moveMTSLButton:SetText(L["Move MTSL"])
		plugin.moveMTSLButton:SetScript("OnClick", function(self, mouseButton, isDown)
--
-- Only do something if the MTSLUI_ToggleButton button exists (i.e. the addon MissingTradeSkillsList exists)
--
			if MTSLUI_ToggleButton and Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
				plugin.nowPoint = {}
				plugin.nowPoint[1], plugin.nowPoint[2], plugin.nowPoint[3], plugin.nowPoint[4], plugin.nowPoint[5] = MTSLUI_ToggleButton:GetPoint(1)
				if not plugin.setupMTSL then
					plugin.oldPoint = {}
					plugin.oldPoint[1], plugin.oldPoint[2], plugin.oldPoint[3], plugin.oldPoint[4], plugin.oldPoint[5] = MTSLUI_ToggleButton:GetPoint(1)
					plugin.newPoint = {}
					plugin.newPoint[1] = plugin.oldPoint[1]
					plugin.newPoint[2] = SkilletPluginButton
					plugin.newPoint[3] = plugin.oldPoint[3]
					plugin.newPoint[4] = 0
					plugin.newPoint[5] = 4
					plugin.setupMTSL = true
					plugin.movedMTSL = false
				end
				if plugin.nowPoint[2] == plugin.newPoint[2] then
					MTSLUI_ToggleButton:SetParent(SkilletFrame)
					MTSLUI_ToggleButton:SetPoint(plugin.oldPoint[1], plugin.oldPoint[2], plugin.oldPoint[3], plugin.oldPoint[4], plugin.oldPoint[5])
					plugin.movedMTSL = false
				else
					MTSLUI_ToggleButton:SetParent(SkilletPluginButton)
					MTSLUI_ToggleButton:SetPoint(plugin.newPoint[1], plugin.newPoint[2], plugin.newPoint[3], plugin.newPoint[4], plugin.newPoint[5])
					plugin.movedMTSL = true
				end
			end
		end)
		if C_AddOns.IsAddOnLoaded("MissingTradeSkillsList_TBC") then
			Skillet:AddButtonToTradeskillWindow(plugin.moveMTSLButton)
		end
	end
	if not C_AddOns.IsAddOnLoaded("MissingTradeSkillsList_TBC") then
		Skillet.db.profile.plugins.MTSL.enabled = false
	end
end

--
-- This function is called within the Skillet:UpdateTradeSkillWindow function
--
function plugin.Update()
	--DA.DEBUG(0,"MTSL Plugin Update")
	if MTSLUI_ToggleButton and not MTSLUI_ToggleButton:IsVisible() then
		if MTSLUI_TOGGLE_BUTTON and MTSLUI_TOGGLE_BUTTON.Show then
			MTSLUI_TOGGLE_BUTTON:Show()
		end
	end
end

Skillet:RegisterUpdatePlugin("MTSLPlugin")		-- we have an Update function
