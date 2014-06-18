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

function plugin.OnEnable()
	plugin.TSM = LibStub("AceAddon-3.0"):GetAddon("TSM_Crafting", true)
	if plugin.TSM and plugin.TSM.CraftingGUI then
		plugin.GUI = plugin.TSM.CraftingGUI
		plugin.ShowProfessionWindow = plugin.GUI.ShowProfessionWindow
		plugin.GUI.ShowProfessionWindow = function () end
	end
end

function plugin.GetExtraText(skill, recipe)
end

function plugin.TSMShow()
	DA.DEBUG(0,"TSMShow()")
	if plugin.TSM and plugin.GUI and plugin.ShowProfessionWindow then
		plugin.ShowProfessionWindow();
	end
end

Skillet:RegisterDisplayDetailPlugin("TSMPlugin")
