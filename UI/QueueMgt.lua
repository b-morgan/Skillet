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

Skillet.selectedQueueName = ""

function Skillet:QueueLoadDropdown_OnShow()
	UIDropDownMenu_Initialize(SkilletQueueLoadDropdown, Skillet.SkilletQueueLoadDropdown_Initialize)
	SkilletSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, 1)
	local i=2
	for k,v in pairs(Skillet.db.profile.SavedQueues) do
		if Skillet.selectedQueueName and Skillet.selectedQueueName == k then
			UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, i)
		end
		i = i + 1
	end
end

function Skillet:SkilletQueueLoadDropdown_Initialize()
	local info
	local i=1
	info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.func = Skillet.QueueLoadDropdown_OnClick
	info.value = i
	i = i + 1
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	for k,v in pairs(Skillet.db.profile.SavedQueues) do
		info = UIDropDownMenu_CreateInfo()
		info.text = k
		info.func = Skillet.QueueLoadDropdown_OnClick
		info.value = i
		i = i + 1
		if self then
			info.owner = self:GetParent()
		end
		UIDropDownMenu_AddButton(info)
	end
end

-- Called when the user selects an item in the sorting drop down
function Skillet:QueueLoadDropdown_OnClick()
	UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, self:GetID())
	Skillet.selectedQueueName = self:GetText()
end
