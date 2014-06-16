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

Skillet.TSMPlugin = {}

local plugin = Skillet.TSMPlugin
local L = Skillet.L

function plugin.OnInitialize()
	DA.DEBUG(0,"TSMPlugin.OnInitialize()")
	plugin.TSM = {}
	plugin.GUI = {}
	local TSM = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	if TSM then
		plugin.TSM = TSM
	end
	if plugin.TSM and plugin.TSM.moduleObjects then
		local GUI = plugin.TSM.moduleObjects["CraftingGUI"]
		if GUI then
			plugin.GUI = GUI
		end
	end
	DA.DEBUG("TSM= "..tostring(TSM))
	DA.DEBUG("GUI= "..tostring(GUI))
end

function plugin.GetExtraText(skill, recipe)
end

function plugin.TSMHide()
	DA.DEBUG(0,"TSMHide()")
	plugin.TSM = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	if plugin.TSM and plugin.TSM.moduleObjects then
		plugin.GUI = plugin.TSM.moduleObjects["CraftingGUI"]
		if plugin.TSM and plugin.GUI and plugin.GUI.frame then
			plugin.GUI.frame:Hide();
		end
	end
end

function plugin.TSMShow()
	DA.DEBUG(0,"TSMShow()")
	if plugin.TSM and plugin.GUI and plugin.GUI.frame then
		plugin.GUI.frame:Show();
	end
end

Skillet:RegisterDisplayDetailPlugin("TSMPlugin")
