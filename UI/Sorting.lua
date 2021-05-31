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

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
--
-- Table of difficulty colors defined in SkilletData.lua
--
local skill_style_type = Skillet.skill_style_type
--
-- List of possible sorting methods
--
local sorters = {}
local recipe_sort_method = nil

local function NOSORT(tradeskill, a, b)
	return (a.skillIndex or 0) < (b.skillIndex or 0)
end

local function sort_recipe_by_name(tradeskill, a, b)
	if a.name == b.name then
		return (a.skillIndex or 0) < (b.skillIndex or 0)
	else
		return a.name < b.name
	end
end

local function sort_recipe_by_skill_level(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local leftDifficulty = 0
	local rightDifficulty = 0
	if a.skillData and a.skillData.difficulty and skill_style_type[a.skillData.difficulty] then
		leftDifficulty = skill_style_type[a.skillData.difficulty].level
	end
	if b.skillData and b.skillData.difficulty and skill_style_type[b.skillData.difficulty] then
		rightDifficulty = skill_style_type[b.skillData.difficulty].level
	end
	if leftDifficulty == rightDifficulty then
		local left = Skillet:GetTradeSkillLevels(a.spellID)
		local right = Skillet:GetTradeSkillLevels(b.spellID)
		if left == right then
			if a.subGroup and b.subGroup then
				return #a.subGroup.entries < #b.subGroup.entries
			else
				return (a.skillIndex or 0) < (b.skillIndex or 0)
			end
		else
			return left > right
		end
	else
		return leftDifficulty > rightDifficulty
	end
end

local function sort_recipe_by_item_level(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local left_r = Skillet:GetRecipe(a.recipeID)
	local right_r = Skillet:GetRecipe(b.recipeID)
	local left  = Skillet:GetLevelRequiredToUse(left_r.itemID)
	local right = Skillet:GetLevelRequiredToUse(right_r.itemID)
	if not left  then  left = 0 end
	if not right then right = 0 end
	if left == right then
--
-- Same level, try iLevel next
--
		local left = select(4,GetItemInfo(left_r.itemID)) or 0
		local right = select(4,GetItemInfo(right_r.itemID)) or 0
		if left == right then
--
-- Same level, sort by difficulty
--
			return sort_recipe_by_skill_level(tradeskill, a, b)
		else
			return left > right
		end
	else
		return left > right
	end
end

local function sort_recipe_by_item_quality(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local left_r = Skillet:GetRecipe(a.recipeID)
	local right_r = Skillet:GetRecipe(b.recipeID)
	local _,_, left = GetItemInfo(left_r.itemID)
	local _,_, right = GetItemInfo(right_r.itemID)
	if not left  then  left = 0 end
	if not right then right = 0 end
	if left == right then
--
-- Same level, sort by level required to use
--
		return sort_recipe_by_item_level(tradeskill, a, b)
	else
		return left > right
	end
end

local function sort_recipe_by_index(tradeskill, a, b)
	if a.subGroup and not b.subGroup then
		return true
	end
	if b.subGroup and not a.subGroup then
		return false
	end
	if (a.skillIndex or 0) == (b.skillIndex or 0) then
		return (a.name or "A") < (b.name or "B")
	else
		return (a.skillIndex or 0) < (b.skillIndex or 0)
	end
end

local function get_suffix(recipe, first)
	local ret = recipe.suffix
	if not ret and recipe.recipeData then
		ret = recipe.recipeData.suffix
	end
	if first and ret == nil and recipe.recipeID then
		actualRecipe = Skillet:GetRecipe(recipe.recipeID)
		Skillet:RecipeNameSuffix(tradeskill, actualRecipe)
		ret = get_suffix(actualRecipe, false)
	end
	return ret
end

local function sort_recipe_by_suffix(tradeskill, a, b)
	if a.subGroup or b.subGroup then
		return NOSORT(tradeskill, a, b)
	end
	local as = get_suffix(a, true)
	local bs = get_suffix(b, true)
	if as == bs then
		return (a.skillIndex or 0) < (b.skillIndex or 0)
	else
		return (as or 0) > (bs or 0)
	end
end

local function SkillIsFilteredOut(skillIndex)
	--DA.DEBUG(0,"SkillIsFilteredOut("..tostring(skillIndex)..")")
	local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, skillIndex)
	--DA.DEBUG(1,"SkillIsFilteredOut: skill = "..DA.DUMP1(skill,1))
	local recipe = Skillet:GetRecipe(skill.id)
	--DA.DEBUG(1,"SkillIsFilteredOut: recipe = "..DA.DUMP1(recipe,1))
	local recipeID = recipe.spellID or 0
	if recipeID == 0 then
--
-- It's a header, don't filter here
--
		return false
	end

	local recipeInfo = Skillet.data.recipeInfo[Skillet.currentTrade][recipeID]
	if recipeInfo then
		--DA.DEBUG(1,"SkillIsFilteredOut: unlearnedRecipes= "..tostring(Skillet.unlearnedRecipes)..", recipeInfo = "..DA.DUMP1(recipeInfo,1))
		if Skillet.unlearnedRecipes then
			if recipeInfo.learned then
				return true
			end
		elseif not recipeInfo.learned then
			return true
		end
	end

	if Skillet:IsUpgradeHidden(recipeID) then
		return true
	end

	if Skillet:GetTradeSkillOption("favoritesOnly") and not Skillet:IsFavorite(recipeID) then
		return true
	end
--
-- Are we hiding anything that is trivial (has no chance of giving a skill point)
--
	if skill_style_type[skill.difficulty] then
		if skill_style_type[skill.difficulty].level < (Skillet:GetTradeSkillOption("filterLevel") or 4) then
			return true
		end
	end
--
-- Are we hiding anything that can't be created with the mats on this character?
--
	if Skillet:GetTradeSkillOption("hideuncraftable") then
		if not (skill.numCraftable > 0 and Skillet:GetTradeSkillOption("filterInventory-bag")) and
		   not (skill.numRecursive > 0 and Skillet:GetTradeSkillOption("filterInventory-crafted")) and
		   not (skill.numCraftableVendor > 0 and Skillet:GetTradeSkillOption("filterInventory-vendor")) and
		   not (skill.numCraftableAlts > 0 and Skillet:GetTradeSkillOption("filterInventory-alts")) then
			return true
		end
	end
	if Skillet.recipeFilters then
		for _,f in pairs(Skillet.recipeFilters) do
			if f.filterMethod(f.namespace, skillIndex) then
				return true
			end
		end
	end
--
-- String search
--
	local searchtext = Skillet:GetTradeSkillOption("searchtext")
	if searchtext and searchtext ~= "" then
		local filter = string.lower(searchtext)
		local nameOnly = false
		if string.sub(filter,1,1) == "!" then
			filter = string.sub(filter,2)
			nameOnly = true
		end
		local word
		local name = ""
		local tooltip = _G["SkilletParsingTooltip"]
		if tooltip == nil then
			tooltip = CreateFrame("GameTooltip", "SkilletParsingTooltip", _G["ANCHOR_NONE"], "GameTooltipTemplate")
			tooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
		end
		local searchText = ""
		if nameOnly then
			searchText = recipe.name
		else
			if not Skillet.data.tooltipCache or Skillet.data.tooltipCachedTrade ~= Skillet.currentTrade then
				Skillet.data.tooltipCachedTrade = Skillet.currentTrade
				Skillet.data.tooltipCache = {}
			end
			if not Skillet.data.tooltipCache[recipeID] then
				tooltip:SetHyperlink("enchant:"..recipeID)
				local tiplines = tooltip:NumLines()
				for i=1, tiplines, 1 do
					searchText = searchText.. " " .. string.lower(_G["SkilletParsingTooltipTextLeft"..i]:GetText() or " ")
					searchText = searchText.. " " .. string.lower(_G["SkilletParsingTooltipTextRight"..i]:GetText() or " ")
				end
				Skillet.data.tooltipCache[recipeID] = searchText
			else
				searchText = Skillet.data.tooltipCache[recipeID]
			end
		end
		if searchText then
			searchText = string.lower(searchText)
			local wordList = { string.split(" ",filter) }
			for v,word in pairs(wordList) do
				if string.find(searchText, word, 1, true) == nil then
					return true
				end
			end
		end
	end
	return false
end

local function set_sort_desc(toggle)
	for _,entry in pairs(sorters) do
		if entry.sorter == recipe_sort_method then
			Skillet:SetTradeSkillOption("sortdesc-" .. entry.name, toggle)
			Skillet:SortAndFilterRecipes()
		end
	end
end

local function is_sort_desc()
	for _,entry in pairs(sorters) do
		if entry.sorter == recipe_sort_method then
			return Skillet:GetTradeSkillOption("sortdesc-" .. entry.name)
		end
	end
	return true
end

local function show_sort_toggle()
	SkilletSortDescButton:Hide()
	SkilletSortAscButton:Hide()
	if recipe_sort_method ~= NOSORT then
		if is_sort_desc() then
			SkilletSortDescButton:Show()
		else
			SkilletSortAscButton:Show()
		end
	end
end

function Skillet:ExpandAll()
	local skillListKey = Skillet.currentPlayer..":"..Skillet.currentTrade..":"..Skillet.currentGroupLabel
	if self.data.sortedSkillList[skillListKey] then
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		local numTradeSkills = sortedSkillList.count
		for i=1, numTradeSkills, 1 do
			local skill = sortedSkillList[i]
			if skill.subGroup then
				skill.subGroup.expanded = true
			end
		end
	end
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:CollapseAll()
	local skillListKey = Skillet.currentPlayer..":"..Skillet.currentTrade..":"..Skillet.currentGroupLabel
	if self.data.sortedSkillList[skillListKey] then
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		local numTradeSkills = sortedSkillList.count
		for i=1, numTradeSkills, 1 do
			local skill = sortedSkillList[i]
			if skill.subGroup then
				skill.subGroup.expanded = false
			end
		end
	end
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

--
-- Builds a sorted and filtered list of recipes for the
-- currently selected tradekskill and sorting method
-- if no sorting, then headers will be included
--
-- Adds the sorting routine to the list of sorting routines.
--
function Skillet:AddRecipeSorter(text, sorter)
	assert(text and tostring(text),
		"Usage Skillet:AddRecipeSorter(text, sorter), text must be a string")
	assert(sorter and type(sorter) == "function",
		"Usage Skillet:AddRecipeSorter(text, sorter), sorter must be a function")
	table.insert(sorters, {["name"]=text, ["sorter"]=sorter})
end

function Skillet:InitializeSorting()
--
-- Default sorting methods
-- We don't go through the public API for this as we want our methods
-- to appear first in the list, no matter what.
--
	table.insert(sorters, 1, {["name"]=L["None"], ["sorter"]=sort_recipe_by_index})
	table.insert(sorters, 2, {["name"]=L["By Name"], ["sorter"]=sort_recipe_by_name})
	table.insert(sorters, 3, {["name"]=L["By Difficulty"], ["sorter"]=sort_recipe_by_skill_level})
--	table.insert(sorters, 4, {["name"]=L["By Skill Level"], ["sorter"]=sort_recipe_by_skill_level})
	table.insert(sorters, 4, {["name"]=L["By Item Level"], ["sorter"]=sort_recipe_by_item_level})
	table.insert(sorters, 5, {["name"]=L["By Quality"], ["sorter"]=sort_recipe_by_item_quality})
	table.insert(sorters, 6, {["name"]=L["By Suffix"], ["sorter"]=sort_recipe_by_suffix})

	recipe_sort_method = sort_recipe_by_index
	SkilletSortAscButton:SetScript("OnClick", function()
		-- clicked the button will toggle sort ascending off
		set_sort_desc(true)
		SkilletSortAscButton:Hide()
		SkilletSortDescButton:Show()
		self:UpdateTradeSkillWindow()
	end)
	SkilletSortAscButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(SkilletSortAscButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SORTASC"])
	end)
	SkilletSortAscButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	SkilletSortDescButton:SetScript("OnClick", function()
		-- clicked the button will toggle sort descending off
		set_sort_desc(false)
		SkilletSortDescButton:Hide()
		SkilletSortAscButton:Show()
		self:UpdateTradeSkillWindow()
	end)
	SkilletSortDescButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(SkilletSortDescButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SORTDESC"])
	end)
	SkilletSortDescButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

--
-- Causes the list of recipes to be resorted
--
function Skillet:SortAndFilterRecipes()
	DA.DEBUG(0,"SortAndFilterRecipes()")
	local skillListKey = Skillet.currentPlayer..":"..Skillet.currentTrade..":"..Skillet.currentGroupLabel
	local numSkills = Skillet:GetNumSkills(Skillet.currentPlayer, Skillet.currentTrade)
	if not Skillet.data.sortedSkillList then
		--DA.DEBUG(1,"SortAndFilterRecipes: Skillet.data.sortedSkillList = {}")
		Skillet.data.sortedSkillList = {}
	end
	if not Skillet.data.sortedSkillList[skillListKey] then
		--DA.DEBUG(1,"SortAndFilterRecipes: Skillet.data.sortedSkillList[skillListKey] = {}")
		Skillet.data.sortedSkillList[skillListKey] = {}
	end
	local sortedSkillList = Skillet.data.sortedSkillList[skillListKey]
	local oldLength = #sortedSkillList
	--DA.DEBUG(1,"SortAndFilterRecipes: numSkills= "..tostring(numSkills)..", oldLength= ",tostring(oldLength))
	local button_index = 0
	local searchtext = Skillet:GetTradeSkillOption("searchtext")
	local groupLabel = Skillet.currentGroupLabel
	--DA.DEBUG(1,"SortAndFilterRecipes: searchtext="..tostring(searchtext)..", groupLabel="..tostring(groupLabel))
	if searchtext and searchtext ~= "" or groupLabel == "Flat" then
		--DA.DEBUG(1,"SortAndFilterRecipes: Flat")
		for i=1, numSkills, 1 do
			local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, i)
			if skill then
				local recipe = Skillet:GetRecipe(skill.id)
				if skill.id ~= 0 then							-- not a header
					local filtered = SkillIsFilteredOut(i)
					--DA.DEBUG(1,"SortAndFilterRecipes: SkillIsFilteredOut("..tostring(i)..")= "..tostring(filtered))
					if not filtered then
--
-- skill is not filtered out
--
						button_index = button_index + 1
						sortedSkillList[button_index] = {["recipeID"] = skill.id, ["spellID"] = recipe.spellID, ["name"] = recipe.name, ["skillIndex"] = i, ["recipeData"] = recipe, ["skillData"] = skill, ["depth"] = 0}
					elseif i == Skillet.selectedSkill then
--
-- if filtered out and selected - deselect
--
						Skillet.selectedSkill = nil
					end
				end
			end
		end
		if oldLength > button_index then
			while oldLength > button_index do
				sortedSkillList[oldLength] = nil
				oldLength = oldLength - 1
			end
		end
		if not is_sort_desc() then
			table.sort(sortedSkillList, function(a,b)
				return recipe_sort_method(Skillet.currentTrade, a, b)
			end)
		else
			table.sort(sortedSkillList, function(a,b)
				return recipe_sort_method(Skillet.currentTrade, b, a)
			end)
		end
	else
--
-- No search string and not Flat (i.e. Blizzard)
--
		local group = Skillet:RecipeGroupFind(Skillet.currentPlayer, Skillet.currentTrade, Skillet.currentGroupLabel, Skillet.currentGroup)
		--DA.DEBUG(1,"SortAndFilterRecipes: current grouping "..Skillet.currentGroupLabel.." "..(Skillet.currentGroup or "nil"))
		if recipe_sort_method ~= NOSORT then
			Skillet:RecipeGroupSort(group, recipe_sort_method, is_sort_desc())
		end
		if Skillet.currentGroup then
			Skillet:RecipeGroupInitFlatten(group, sortedSkillList)
			button_index = Skillet:RecipeGroupFlatten(group, 1, sortedSkillList, 1) + 1
		else
			button_index = Skillet:RecipeGroupFlatten(group, 0, sortedSkillList, 0)
		end
	end
	DA.DEBUG(1,"SortAndFilterRecipes: sorted "..button_index.." skills")
	sortedSkillList.count = button_index
	return button_index
end

--
-- called when the sort drop down is first loaded
--
function Skillet:SortDropdown_OnLoad()
	UIDropDownMenu_Initialize(SkilletSortDropdown, Skillet.SortDropdown_Initialize)
	SkilletSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	-- Find out which sort method is selected
	for i=1, #sorters, 1 do
		if recipe_sort_method == sorters[i].sorter then
			UIDropDownMenu_SetSelectedID(SkilletSortDropdown, i)
			break
		end
	end
--
-- Can't call show_sort_toggle() here as the sort
-- buttons have not been created yet
--
end

--
-- Called when the sort drop down is displayed
--
function Skillet:SortDropdown_OnShow()
	UIDropDownMenu_Initialize(SkilletSortDropdown, Skillet.SortDropdown_Initialize)
	SkilletSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	for i=1, #sorters, 1 do
		if recipe_sort_method == sorters[i].sorter then
			UIDropDownMenu_SetSelectedID(SkilletSortDropdown, i)
			break
		end
	end
	show_sort_toggle()
end

--
-- The method we use the initialize the sorting drop down.
--
function Skillet:SortDropdown_Initialize()
	recipe_sort_method = NOSORT
	local info
	for i=1, #sorters, 1 do
		local entry = sorters[i]
		info = UIDropDownMenu_CreateInfo()
		info.text = entry.name
		if entry.name == Skillet:GetTradeSkillOption("sortmethod") then
			recipe_sort_method = entry.sorter
		end
		info.func = Skillet.SortDropdown_OnClick
		info.value = i
		if self then
			info.owner = self:GetParent()
		end
		UIDropDownMenu_AddButton(info)
	end
--
-- Can't call show_sort_toggle() here as the sort
-- buttons have not been created yet
--
end

--
-- Called when the user selects an item in the sorting drop down
--
function Skillet:SortDropdown_OnClick()
	UIDropDownMenu_SetSelectedID(SkilletSortDropdown, self:GetID())
	local entry = sorters[self:GetID()]
	Skillet:SetTradeSkillOption("sortmethod", entry.name)
	recipe_sort_method = entry.sorter
	show_sort_toggle()
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end
