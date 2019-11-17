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

local OVERALL_PARENT_GROUP_NAME = "*ALL*"

local skillLevel = {
	["optimal"]	        = 4,
	["medium"]          = 3,
	["easy"]            = 2,
	["trivial"]	        = 1,
}

function Skillet:RecipeGroupRename(oldName, newName)
	--DA.DEBUG(0,"RecipeGroupRename("..tostring(oldName)..", "..tostring(newName)..")")
	if self.data.groupList[self.currentTrade][oldName] then
		self.data.groupList[self.currentTrade][newName] = self.data.groupList[self.currentTrade][oldName]
		self.data.groupList[self.currentTrade][oldName] = nil
		local list = self.data.groupList[self.currentTrade][newName]
		local oldKey =  self.currentPlayer..":"..self.currentTrade..":"..oldName
		local key = self.currentPlayer..":"..self.currentTrade..":"..newName
		self.db.realm.groupDB[key] = self.db.realm.groupDB[oldKey]
		self.db.realm.groupDB[oldKey] = nil
		for groupName, groupData in pairs(list) do
			groupData.key = key
		end
	end
end

function Skillet:RecipeGroupFind(player, tradeID, label, name)
	--DA.DEBUG(0,"RecipeGroupFind("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	if player and tradeID and label then
		local groupList = self.data.groupList
		if groupList and groupList[tradeID] and groupList[tradeID][label] then
			return self.data.groupList[tradeID][label][name or OVERALL_PARENT_GROUP_NAME]
		end
	end
end

function Skillet:RecipeGroupFindRecipe(group, recipeID)
	--DA.DEBUG(0,"RecipeGroupFindRecipe("..DA.DUMP1(group,1)..", "..tostring(recipeID)..")")
	if group then
		local entries = group.entries
		if entries then
			for i=1,#entries do
				if entries[i].recipeID then
					return entries[i]
				end
			end
		end
	end
end

-- creates a new recipe group
-- player = for whom the group is being created
-- tradeID = tradeID of the group
-- label = meta-group of groups.  for example, "blizzard" is defined for the standard blizzard groups.  this allows multiple group settings
-- name = new group name (optional -- not specified means the overall parent group)
--
-- returns the newly created group record
local serial = 0
function Skillet:RecipeGroupNew(player, tradeID, label, name)
	--DA.DEBUG(0,"RecipeGroupNew("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	local existingGroup = self:RecipeGroupFind(player, tradeID, label, name)
	if existingGroup then
		--DA.DEBUG(0,"group "..existingGroup.key.."/"..existingGroup.name.." exists")
		return existingGroup
	else
		--DA.DEBUG(0,"new group "..(name or OVERALL_PARENT_GROUP_NAME))
		local newGroup = {}
		local key = player..":"..tradeID..":"..label
		newGroup.expanded = true
		newGroup.key = key
		newGroup.name = name or OVERALL_PARENT_GROUP_NAME
		newGroup.entries = {}
		newGroup.skillIndex = serial
		newGroup.locked = nil
		serial = serial + 1
		if not self.data.groupList[tradeID] then
			self.data.groupList[tradeID] = {}
		end
		if not self.data.groupList[tradeID][label] then
			self.data.groupList[tradeID][label] = {}
		end
		self.data.groupList[tradeID][label][newGroup.name] = newGroup
		return newGroup
	end
end

function Skillet:RecipeGroupClearEntries(group)
	--DA.DEBUG(0,"RecipeGroupClearEntries("..DA.DUMP1(group,1))
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self:RecipeGroupClearEntries(group.entries[i].subGroup)
			end
		end
		group.entries = {}
	end
end

function Skillet:RecipeGroupCopy(s, d, noDB)
	--DA.DEBUG(0,"RecipeGroupCopy("..DA.DUMP1(s,1)..", "..DA.DUMP1(d,1)..", "..tostring(noDB)..")")
	if s and d then
		local player, tradeID, label = string.split(":", d.key)
		d.skillIndex = s.skillIndex
		d.expanded = s.expanded
		d.entries = {}
			for i=1,#s.entries do
			if s.entries[i].subGroup then
				local newGroup = self:RecipeGroupNew(player, tradeID, label, s.entries[i].name)
				self:RecipeGroupCopy(s.entries[i].subGroup, newGroup, noDB)
				self:RecipeGroupAddSubGroup(d, newGroup, s.entries[i].skillIndex, noDB)
			else
				self:RecipeGroupAddRecipe(d, s.entries[i].recipeID, s.entries[i].skillIndex, noDB)
			end
		end
	end
end

function Skillet:RecipeGroupAddRecipe(group, recipeID, skillIndex, noDB)
	--DA.DEBUG(0,"RecipeGroupAddRecipe("..DA.DUMP1(group,1)..", "..tostring(recipeID)..", "..tostring(skillIndex)..", "..tostring(noDB)..")")
	recipeID = tonumber(recipeID)
	if group and recipeID then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].recipeID == recipeID then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
			newEntry.recipeID = recipeID
			newEntry.name, newEntry.spellID = self:GetRecipeName(recipeID)
			newEntry.skillIndex = skillIndex
			newEntry.parent = group
			table.insert(group.entries, newEntry)
			currentEntry = newEntry
		else
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name, currentEntry.spellID = self:GetRecipeName(recipeID)
			currentEntry.parent = group
		end
		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end
		return currentEntry
	end
end

function Skillet:RecipeGroupAddSubGroup(group, subGroup, skillIndex, noDB)
	--DA.DEBUG(0,"RecipeGroupAddSubGroup("..DA.DUMP1(group,1)..", "..DA.DUMP1(subGroup,1)..", "..tostring(skillIndex)..", "..tostring(noDB)..")")
	if group and subGroup then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].subGroup == subGroup then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
			subGroup.parent = group
			subGroup.skillIndex = skillIndex
			newEntry.subGroup = subGroup
			newEntry.skillIndex = skillIndex
			newEntry.name = subGroup.name
			newEntry.parent = group
			table.insert(group.entries, newEntry)
		else
			subGroup.parent = group
			subGroup.skillIndex = skillIndex
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name = subGroup.name
			currentEntry.parent = group
		end
		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end
	end
end

function Skillet:RecipeGroupPasteEntry(entry, group)
	--DA.DEBUG(0,"RecipeGroupPasteEntry("..DA.DUMP1(entry,1)..", "..DA.DUMP1(group,1)..")")
	if entry and group and entry.parent ~= group then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		--DA.DEBUG(0,"paste "..entry.name.." into "..group.name)
--		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		local parentGroup = group
		if entry.subGroup then
			 if entry.subGroup == group then
			 	return
			end
			local newName, newIndex = self:RecipeGroupNewName(group.key, entry.name)
			local newGroup = self:RecipeGroupNew(player, tradeID, label, newName)
			self:RecipeGroupAddSubGroup(parentGroup, newGroup, newIndex)
			if entry.subGroup.entries then
				--DA.DEBUG(0,(entry.subGroup.name or "nil") .. " " .. #entry.subGroup.entries)
				for i=1,#entry.subGroup.entries do
					--DA.DEBUG(1,(entry.subGroup.entries[i].name or "nil") .. " " .. newGroup.name)
					self:RecipeGroupPasteEntry(entry.subGroup.entries[i], newGroup)
				end
			end
		else
			local newIndex = self.data.skillIndexLookup[entry.recipeID]
			if not newIndex then
				newIndex = #self.data.skillDB[tradeID]+1
				self.data.skillDB[tradeID][newIndex] = "x"..entry.recipeID
			end
			self:RecipeGroupAddRecipe(parentGroup, entry.recipeID, newIndex)
		end
	end
end

function Skillet:RecipeGroupMoveEntry(entry, group)
	--DA.DEBUG(0,"RecipeGroupMoveEntry("..DA.DUMP1(entry,1)..", "..DA.DUMP1(group,1)..")")
	if entry and group and entry.parent ~= group then
		if entry.subGroup then
			if entry.subGroup == group then
				return
			end
		end
		local entryGroup = entry.parent
		if entryGroup then
			local loc
			for i=1,#entryGroup.entries do
				if entryGroup.entries[i] == entry then
					loc = i
					break
				end
			end
			table.remove(entryGroup.entries, loc)
			table.insert(group.entries, entry)
			entry.parent = group
			Skillet:RecipeGroupConstructDBString(group)
			Skillet:RecipeGroupConstructDBString(entryGroup)
		end
	end
end

function Skillet:RecipeGroupDeleteGroup(group)
	--DA.DEBUG(0,"RecipeGroupDeleteGroup("..DA.DUMP1(group,1)..")")
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self.RecipeGroupDeleteGroup(group.entries[i].subGroup)
			end
		end
		group.entries = nil
		self.db.realm.groupDB[group.key][group.name] = nil
	end
end

function Skillet:RecipeGroupDeleteEntry(entry)
	--DA.DEBUG(0,"RecipeGroupDeleteEntry("..DA.DUMP1(entry,1)..")")
	if entry then
		local entryGroup = entry.parent
		local loc
		if not entryGroup.entries then return end
		for i=1,#entryGroup.entries do
			if entryGroup.entries[i] == entry then
				loc = i
				break
			end
		end
		table.remove(entryGroup.entries, loc)
		if entry.subGroup then
			self:RecipeGroupDeleteGroup(entry.subGroup)
		end
		Skillet:RecipeGroupConstructDBString(entryGroup)
	end
end

function Skillet:RecipeGroupNewName(key, name)
	--DA.DEBUG(0,"RecipeGroupNewName("..tostring(key)..", "..tostring(name)..")")
	local index = 1
	if key and name then
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		local groupList = self.data.groupList[tradeID][label]
		for v in pairs(groupList) do
			index = index + 1
		end
		if groupList[name] then
			local tempName = name..":"
			local suffix = 2
			while groupList[tempName..suffix] do
				suffix = suffix + 1
			end
			name = tempName..suffix
		end
	end
	--DA.DEBUG(0,"RecipeGroupNewName: name= "..tostring(name)..", index= "..tostring(index))
	return name, index
end

function Skillet:RecipeGroupRenameEntry(entry, name)
	--DA.DEBUG(0,"RecipeGroupRenameEntry("..DA.DUMP1(entry,1)..", "..tostring(name)..")")
	if entry and name then
		local key = entry.parent.key
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		if entry.subGroup then
			local oldName = entry.subGroup.name
			local groupList = self.data.groupList[tradeID][label]
			if oldName ~= name then
				name = self:RecipeGroupNewName(key, name)
				entry.subGroup.name = name
				groupList[name] = groupList[oldName]
				groupList[oldName] = nil
				entry.name = name
			end
		end
		self:RecipeGroupConstructDBString(entry.parent)
	end
end

function Skillet:RecipeGroupSort(group, sortMethod, reverse)
	--DA.DEBUG(0,"RecipeGroupSort("..tostring(group.skillIndex)..", "..tostring(sortMethod)..","..tostring(reverse)..")")
	if group then
		for v, entry in pairs(group.entries) do
			if entry.subGroup and entry.subGroup ~= group then
				self:RecipeGroupSort(entry.subGroup, sortMethod, reverse)
			end
		end
		if group.entries and #group.entries>1 then
			if reverse then
				table.sort(group.entries, function(a,b)
					return sortMethod(Skillet.currentTrade, b, a)
				end)
			else
				table.sort(group.entries, function(a,b)
					return sortMethod(Skillet.currentTrade, a, b)
				end)
			end
		end
	end
end

function Skillet:RecipeGroupInitFlatten(group, list)
	--DA.DEBUG(0,"RecipeGroupInitFlatten("..DA.DUMP1(group,1)..", "..DA.DUMP1(list,1)..")")
	if group and list then
		local newSkill = {}
		newSkill.name = group.name
		newSkill.skillIndex = group.skillIndex
		newSkill.subGroup = group
		newSkill.expanded = true
		newSkill.depth = 0
		newSkill.parent = group.parent
		--DA.DEBUG(1,"newSkill= "..DA.DUMP1(newSkill,1))
		list[1] = newSkill
	end
end

function Skillet:RecipeGroupFlatten(group, depth, list, index)
	--DA.DEBUG(0,"RecipeGroupFlatten("..DA.DUMP1(entry,1)..", "..tostring(depth)..", "..DA.DUMP1(list,1)..", "..tostring(index)..")")
	--DA.DEBUG(0,"group= "..DA.DUMP1(group,2))
	--DA.DEBUG(0,"list= "..DA.DUMP1(list,2))
	local num = 0
	if group and list then
		for v, entry in pairs(group.entries) do
			if entry.subGroup then
				local newSkill = entry
				local inSub = 0
				newSkill.depth = depth
				if (index>0) then
					newSkill.parentIndex = index
				else
					newSkill.parentIndex = nil
				end
				num = num + 1
				list[num + index] = newSkill
				if entry.subGroup.expanded then
					inSub = self:RecipeGroupFlatten(entry.subGroup, depth+1, list, num+index)
				end
				if inSub == 0 and entry.subGroup.expanded then -- empty group - remove the header
				  table.remove(list, num + index)
				  num = num - 1
				else
				  num = num + inSub
				end
			else
				local skillData = self:GetSkill(self.currentPlayer, self.currentTrade, entry.skillIndex)
				local recipe = self:GetRecipe(entry.recipeID)
				if skillData then
					local filterLevel = ((skillLevel[entry.difficulty] or skillLevel[skillData.difficulty] or 0) < (self:GetTradeSkillOption("filterLevel")))
					local filterCraftable = false
					local filterFavoritesOnly = self:GetTradeSkillOption("favoritesOnly") and not Skillet:IsFavorite(entry.recipeID)
					if Skillet:GetTradeSkillOption("hideuncraftable") then
						--DA.DEBUG(1,"name="..tostring(skillData.name)..", numCraftable="..tostring(skillData.numCraftable)..", numRecursive="..tostring(skillData.numRecursive)..", numCraftableVendor="..tostring(skillData.numCraftableVendor)..", numCraftableAlts="..tostring(skillData.numCraftableAlts))
						if not (skillData.numCraftable and skillData.numCraftable > 0 and Skillet:GetTradeSkillOption("filterInventory-bag")) and
						   not (skillData.numRecursive and skillData.numRecursive > 0 and Skillet:GetTradeSkillOption("filterInventory-crafted")) and
						   not (skillData.numCraftableVendor and skillData.numCraftableVendor > 0 and Skillet:GetTradeSkillOption("filterInventory-vendor")) and
						   not (skillData.numCraftableAlts and skillData.numCraftableAlts > 0 and Skillet:GetTradeSkillOption("filterInventory-alts")) then
							filterCraftable = true
						end
					end
					if Skillet.recipeFilters then
						for _,f in pairs(Skillet.recipeFilters) do
							if f.filterMethod(f.namespace, entry.skillIndex) then
								filterCraftable = true
							end
						end
					end
					local newSkill = entry
					newSkill.depth = depth
					newSkill.skillData = skillData
					newSkill.spellID = recipe.spellID
					if (index>0) then
						newSkill.parentIndex = index
					else
						newSkill.parentIndex = nil
					end
					if not (filterLevel or filterCraftable or filterFavoritesOnly or Skillet:IsUpgradeHidden(newSkill.spellID)) then
						num = num + 1
						list[num + index] = newSkill
					end
				end
			end
		end
	end
	return num
end

function Skillet:RecipeGroupDump(group)
	if group then
		local groupString = group.key.."/"..group.name.."="..group.skillIndex
		for v,entry in pairs(group.entries) do
			if not entry.subGroup then
				groupString = groupString..":"..entry.recipeID
			else
				groupString = groupString..":"..entry.subGroup.name
				self:RecipeGroupDump(entry.subGroup)
			end
		end
		--DA.DEBUG(0,groupString)
	else
		--DA.DEBUG(0,"no match")
	end
end

-- make a db string for saving groups
function Skillet:RecipeGroupConstructDBString(group)
	--DA.DEBUG(0,"RecipeGroupConstructDBString("..DA.DUMP1(group,1)..")")
	if group and not group.autoGroup then
		local key = group.key
		local player, tradeID, label = string.split(":",key)
		tradeID = tonumber(tradeID)
		if not self.data.groupList[tradeID][label].autoGroup then
			local groupString = group.skillIndex
			for v,entry in pairs(group.entries) do
				if not entry.subGroup then
					groupString = groupString..":"..entry.recipeID
				else
					groupString = groupString..":g"..entry.skillIndex	-- entry.subGroup.name
					self:RecipeGroupConstructDBString(entry.subGroup)
				end
			end
			if not self.db.realm.groupDB[key] then
				self.db.realm.groupDB[key] = {}
			end
			self.db.realm.groupDB[key][group.name] = groupString
		end
	end
end

function Skillet:RecipeGroupPruneList(player)
	--DA.DEBUG(0,"RecipeGroupPruneList("..tostring(player)..")")
	if self.data.groupList then
		for trade, perTradeList in pairs(self.data.groupList) do
			for label, perLabelList in pairs(perTradeList) do
				for name, group in pairs(perLabelList) do
					if type(group)=="table" and name ~= OVERALL_PARENT_GROUP_NAME and group.parent == nil then
						perLabelList[name] = nil
						if self.db.realm.groupDB and self.db.realm.groupDB[player..":"..trade..":"..label] then
							self.db.realm.groupDB[player..":"..trade..":"..label][name] = nil
						end
					end
				end
			end
		end
	end
end

function Skillet:InitGroupList(player, tradeID, label, autoGroup)
	--DA.DEBUG(0,"InitGroupList("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(autoGroup)..")")
	if not self.data.groupList[tradeID] then
		self.data.groupList[tradeID] = {}
	end
	if not self.data.groupList[tradeID][label] then
		self.data.groupList[tradeID][label] = {}
	end
	self.data.groupList[tradeID][label].autoGroup = autoGroup
end

function Skillet:RecipeGroupDeconstructDBStrings()
	--DA.DEBUG(0,"RecipeGroupDeconstructDBStrings()")
	local groupNames = {}
	local serial = 1
	for key, groupList in pairs(self.db.realm.groupDB) do
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then
			self:InitGroupList(player, tradeID, label)
			for name,list in pairs(groupList) do
				local group = self:RecipeGroupNew(player, tradeID, label, name)
				local groupContents = { string.split(":",list) }
				local groupIndex = tonumber(groupContents[1]) or serial
				serial = serial + 1
				group.skillIndex = groupIndex
				groupNames[groupIndex] = name
			end
		end
	end
	for key, groupList in pairs(self.db.realm.groupDB) do
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then
			for name,list in pairs(groupList) do
				local group = self:RecipeGroupFind(player, tradeID, label, name)
				local groupIndex = group.skillIndex
				if not group.initialized then
					group.initialized = true
					local groupContents = { string.split(":",list) }
					--DA.DEBUG(0,groupContents)
					for j=2,#groupContents do
						local recipeID = groupContents[j]
						if not tonumber(recipeID) then
							local id = tonumber(string.sub(recipeID,2))
							local subGroup = self:RecipeGroupFind(player, tradeID, label, groupNames[id])
							if subGroup then
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.skillIndex, true)
							end
						else
							recipeID = tonumber(recipeID)
							--DA.DEBUG(0,recipeID)
							local skillIndex = self.data.skillIndexLookup[recipeID]
							if skillIndex then
								--DA.DEBUG(0,"adding recipe "..recipeID.." to "..group.name.."/"..player..":"..skillIndex)
								self:RecipeGroupAddRecipe(group, recipeID, skillIndex, true)
							end
						end
					end
				end
			end
			self:RecipeGroupPruneList(player)
		end
	end
end

function Skillet:RecipeGroupGenerateAutoGroups()
	--DA.DEBUG(0,"RecipeGroupGenerateAutoGroups()")
end

-- Called when the grouping drop down is displayed
function Skillet:RecipeGroupDropdown_OnShow()
	UIDropDownMenu_Initialize(SkilletRecipeGroupDropdown, SkilletRecipeGroupDropdown_Initialize)
	SkilletRecipeGroupDropdown.displayMode = "MENU"
	Skillet:RecipeGroupDeconstructDBStrings()
	local groupLabel = self:GetTradeSkillOption("grouping") or self.currentGroupLabel
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, groupLabel, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, groupLabel)
end

-- The method we use the initialize the grouping drop down.
function SkilletRecipeGroupDropdown_Initialize(menuFrame,level)
	--DA.DEBUG(0,"SkilletRecipeGroupDropdown_Initialize("..tostring(menuFrame)..", "..tostring(level)..")")
	if level == 1 then  -- group labels
		local entry = {}
		entry.text = "Flat"
		entry.value = "Flat"
		entry.func = Skillet.RecipeGroupSelect
		entry.arg1 = Skillet
		entry.arg2 = "Flat"
		entry.icon = "Interface\\Addons\\Skillet\\Icons\\locked.tga"
		if Skillet.currentGroupLabel == "Flat" then
			entry.checked = true
		else
			entry.checked = false
		end
		UIDropDownMenu_AddButton(entry)
		if Skillet.data.groupList then
			local numGroupsAdded = 0
			if Skillet.data.groupList[Skillet.currentTrade] then
				for labelName, groupData in pairs(Skillet.data.groupList[Skillet.currentTrade]) do
					entry.text = labelName
					entry.value = labelName
					entry.func = Skillet.RecipeGroupSelect
					entry.arg1 = Skillet
					entry.arg2 = labelName
					if labelName == "Blizzard" or Skillet:GetTradeSkillOption(labelName.."-locked") then
						entry.icon = "Interface\\Addons\\Skillet\\Icons\\locked.tga"
					else
						entry.icon = nil -- "Interface\\Addons\\Skillet\\Icons\\unlocked.tga"
					end
					if Skillet.currentGroupLabel == labelName then
						entry.checked = true
					else
						entry.checked = false
					end
					UIDropDownMenu_AddButton(entry)
					numGroupsAdded = numGroupsAdded + 1
				end
			end
		end
	end
end

-- Called when the user selects an item in the sorting drop down
function Skillet:RecipeGroupSelect(menuFrame,label)
	--DA.DEBUG(0,"RecipeGroupSelect("..tostring(menuFrame)..", "..tostring(label)..")")
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	Skillet.currentGroup = nil
	Skillet:RecipeGroupDropdown_OnShow()
	Skillet:RecipeGroupGenerateAutoGroups()
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:RecipeGroupIsLocked()
	if self.currentGroupLabel == "Flat" or self.currentGroupLabel == "Blizzard" then
		return true
	end
	return Skillet:GetTradeSkillOption(self.currentGroupLabel.."-locked")
end

function Skillet:ToggleTradeSkillOptionDropDown(option)
	self:ToggleTradeSkillOption(option)
	self:RecipeGroupDropdown_OnShow()
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

-- Called when the grouping operators drop down is displayed
function Skillet:RecipeGroupOperations_OnClick(this)
	if not RecipeGroupOpsMenu then
		RecipeGroupOpsMenu = CreateFrame("Frame", "RecipeGroupOpsMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(RecipeGroupOpsMenu, SkilletRecipeGroupOpsMenu_Init, "MENU")
	ToggleDropDownMenu(1, nil, RecipeGroupOpsMenu, this, this:GetWidth(), 0)
end

-- The method we use the initialize the group ops drop down.
function SkilletRecipeGroupOpsMenu_Init(menuFrame,level)
	if level == 1 then
		local entry = {}
		local null = {}
		null.text = ""
		null.disabled = true
		entry.text = "New"
		entry.value = "New"
		entry.func = Skillet.RecipeGroupOpNew
		UIDropDownMenu_AddButton(entry)
		entry.text = "Copy"
		entry.value = "Copy"
		entry.func = Skillet.RecipeGroupOpCopy
		UIDropDownMenu_AddButton(entry)
		entry.text = "Rename"
		entry.value = "Rename"
		entry.func = Skillet.RecipeGroupOpRename
		UIDropDownMenu_AddButton(entry)
		entry.text = "Lock/Unlock"
		entry.value = "Lock/Unlock"
		entry.func = Skillet.RecipeGroupOpLock
		UIDropDownMenu_AddButton(entry)
		entry.text = "Delete"
		entry.value = "Delete"
		entry.func = Skillet.RecipeGroupOpDelete
		UIDropDownMenu_AddButton(entry)
	end
end

function Skillet:RecipeGroupOpNew()
	--DA.DEBUG(0,"RecipeGroupOpNew()")
	local label = "Custom"
	local serial = 1
	local player = Skillet.currentPlayer
	local tradeID = Skillet.currentTrade
	local groupList = Skillet.data.groupList
	while groupList[tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end
	local newMain = Skillet:RecipeGroupNew(player, tradeID, label)
	Skillet:RecipeGroupConstructDBString(newMain)
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:RecipeGroupOpCopy()
	--DA.DEBUG(0,"RecipeGroupOpCopy()")
	local label = "Custom"
	local serial = 1
	local player = Skillet.currentPlayer
	local tradeID = Skillet.currentTrade
	local groupList = Skillet.data.groupList
	while sk[tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end
	local newMain = Skillet:RecipeGroupNew(player, tradeID, label)
	local oldMain = Skillet:RecipeGroupFind(player, tradeID, Skillet.currentGroupLabel)
	Skillet:RecipeGroupCopy(oldMain, newMain, false)
	Skillet:RecipeGroupConstructDBString(newMain)
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:GroupNameEditSave()
	--DA.DEBUG(0,"GroupNameEditSave()")
	local newName = GroupButtonNameEdit:GetText()
	Skillet:RecipeGroupRename(Skillet.currentGroupLabel, newName)
	GroupButtonNameEdit:Hide()
	SkilletRecipeGroupDropdownText:Show()
	SkilletRecipeGroupDropdownText:SetText(newName)
	Skillet.currentGroupLabel = newName
end

function Skillet:RecipeGroupOpRename()
	--DA.DEBUG(0,"RecipeGroupOpRename()")
	if not Skillet:RecipeGroupIsLocked() then
		GroupButtonNameEdit:SetText(Skillet.currentGroupLabel)
		GroupButtonNameEdit:SetParent(SkilletRecipeGroupDropdownText:GetParent())
		local numPoints = SkilletRecipeGroupDropdownText:GetNumPoints()
		for p=1,numPoints do
			GroupButtonNameEdit:SetPoint(SkilletRecipeGroupDropdownText:GetPoint(p))
		end
		GroupButtonNameEdit:Show()
		SkilletRecipeGroupDropdownText:Hide()
	end
end

function Skillet:RecipeGroupOpLock()
	--DA.DEBUG(0,"RecipeGroupOpLock()")
	local label = Skillet.currentGroupLabel
	if label ~= "Blizzard" and label ~= "Flat" then
		Skillet:ToggleTradeSkillOption(label.."-locked")
	end
end

function Skillet:RecipeGroupOpDelete()
	--DA.DEBUG(0,"RecipeGroupOpDelete()")
	if not Skillet:RecipeGroupIsLocked() then
		local player = Skillet.currentPlayer
		local tradeID = Skillet.currentTrade
		local label = Skillet.currentGroupLabel
		Skillet.data.groupList[tradeID][label] = nil
		Skillet.db.realm.groupDB[player..":"..tradeID..":"..label] = nil
		label = "Blizzard"
		Skillet:SetTradeSkillOption("grouping", label)
		Skillet.currentGroupLabel = label
			UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
		UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
		Skillet:SortAndFilterRecipes()
		Skillet:UpdateTradeSkillWindow()
	end
end
