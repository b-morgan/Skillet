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
-- Called when the new filter drop down is displayed
--
function Skillet:FilterDropDown_OnShow()
	--DA.DEBUG(0,"FilterDropDown_OnShow()")
	UIDropDownMenu_Initialize(SkilletFilterDropdown, Skillet.FilterDropDown_Initialize)
	SkilletFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	if Skillet.unlearnedRecipes and Skillet.learnedRecipes then
		UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 3)
	elseif Skillet.unlearnedRecipes and not Skillet.learnedRecipes then
		UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 2)
	elseif Skillet.learnedRecipes and not Skillet.unlearnedRecipes then
		UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 1)
	end
end

--
-- The method we use the initialize the new filter drop down.
--
function Skillet:FilterDropDown_Initialize()
	--DA.DEBUG(0,"FilterDropDown_Initialize()")
	local info
	local i = 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Learned"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Unlearned"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Both"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1
end

--
-- Called when the user selects an item in the new filter drop down
--
function Skillet:FilterDropDown_OnClick()
	--DA.DEBUG(0,"FilterDropDown_OnClick()")
	UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, self:GetID())
	local index = self:GetID()
	if index == 1 then
		Skillet:SetTradeSkillLearned()
	elseif index == 2 then
		Skillet:SetTradeSkillUnlearned()
	elseif index == 3 then
		Skillet:SetTradeSkillBoth()
	end
	Skillet.dataScanned = false
	Skillet:RescanTrade()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet.InitializeFilterDropdown(self, level)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.text = L["Reset"]
		info.notCheckable = true
		info.func = function()
			Skillet:SetDefaultFilters()
			Skillet:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
			UIDropDownMenu_RefreshAll(SkilletFilterDropMenu, 3)
			SkilletFilterText:SetText("")
			Skillet.dataScanned = false
			Skillet:UpdateTradeSkillWindow()
		end
		UIDropDownMenu_AddButton(info, level)
		info.notCheckable = false

		info.text = CRAFT_IS_MAKEABLE
		info.func = function()
			C_TradeSkillUI.SetOnlyShowMakeableRecipes(not C_TradeSkillUI.GetOnlyShowMakeableRecipes())
			Skillet:SetTradeSkillOption("hideuncraftable", C_TradeSkillUI.GetOnlyShowMakeableRecipes())
			Skillet.dataScanned = false
			Skillet:UpdateTradeSkillWindow()
		end
		info.keepShownOnClick = true
		info.checked = C_TradeSkillUI.GetOnlyShowMakeableRecipes()
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		if not C_TradeSkillUI.IsTradeSkillGuild() and not C_TradeSkillUI.IsNPCCrafting() then
			info.text = TRADESKILL_FILTER_HAS_SKILL_UP
			info.func = function()
				C_TradeSkillUI.SetOnlyShowSkillUpRecipes(not C_TradeSkillUI.GetOnlyShowSkillUpRecipes())
				if C_TradeSkillUI.GetOnlyShowSkillUpRecipes() then
					Skillet:SetTradeSkillOption("filterLevel", 2)
				else
					Skillet:SetTradeSkillOption("filterLevel", 1)
				end
				Skillet.dataScanned = false
				Skillet:UpdateTradeSkillWindow()
			end
			info.keepShownOnClick = true
			info.checked = C_TradeSkillUI.GetOnlyShowSkillUpRecipes()
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
		end

		info.checked = 	nil
		info.isNotRadio = nil
		info.func =  nil
		info.notCheckable = true
		info.keepShownOnClick = false
		info.hasArrow = true

		info.text = TRADESKILL_FILTER_SLOTS
		info.value = 1
		info.disabled = true
		UIDropDownMenu_AddButton(info, level)

		info.text = TRADESKILL_FILTER_CATEGORY
		info.value = 2
		info.disabled = true
		UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 3
		info.disabled = true
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			local inventorySlots = {C_TradeSkillUI.GetAllFilterableInventorySlots()}
			for i, inventorySlot in ipairs(inventorySlots) do
				info.text = inventorySlot
				info.func = function()
					Skillet.SetSlotFilter(i)
				end
				info.notCheckable = true
				info.hasArrow = false
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
			local categories = {C_TradeSkillUI.GetCategories()}
			for i, categoryId in ipairs(categories) do
				local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryId)
				info.text = categoryData.name
				info.func = function()
					Skillet.SetSlotFilter(nil, categoryId, nil)
				end
				info.notCheckable = true
				info.hasArrow = select("#", C_TradeSkillUI.GetSubCategories(categoryId)) > 0
				info.keepShownOnClick = true;
				info.value = categoryId
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then
			info.hasArrow = false
			info.isNotRadio = true
			info.notCheckable = true
			info.keepShownOnClick = true
			info.text = CHECK_ALL
			info.func = function()
				C_TradeSkillUI.ClearRecipeSourceTypeFilter()
				UIDropDownMenu_Refresh(SkilletFilterDropMenu, 3, 2)
				Skillet.dataScanned = false
				Skillet:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				Skillet:SetDefaultFilters()
				UIDropDownMenu_Refresh(SkilletFilterDropMenu, 3, 2)
				Skillet.dataScanned = false
				Skillet:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_TradeSkillUI.IsAnyRecipeFromSource(i) then
					info.text = _G["BATTLE_PET_SOURCE_" .. i]
					info.func = function(_, _, _, value)
						C_TradeSkillUI.SetRecipeSourceTypeFilter(i, not value)
						Skillet.dataScanned = false
						Skillet:UpdateTradeSkillWindow()
					end
					info.checked = function()
						return not C_TradeSkillUI.IsRecipeSourceTypeFiltered(i)
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end

	elseif level == 3 then
		local categoryID = UIDROPDOWNMENU_MENU_VALUE
		local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)
		local subCategories = { C_TradeSkillUI.GetSubCategories(categoryID) }
		for i, subCategoryID in ipairs(subCategories) do
			local subCategoryData = C_TradeSkillUI.GetCategoryInfo(subCategoryID)
			info.text = subCategoryData.name
			info.func = function()
				Skillet.SetSlotFilter(nil, categoryID, subCategoryId)
			end
			info.notCheckable = true
			info.keepShownOnClick = true
			info.value = subCategoryId
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Skillet.SetSlotFilter(inventorySlotIndex, categoryId, subCategoryId)
	C_TradeSkillUI.ClearInventorySlotFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()

	if inventorySlotIndex then
		C_TradeSkillUI.SetInventorySlotFilter(inventorySlotIndex, true, true)
	end

	if categoryId or subCategoryId then
		C_TradeSkillUI.SetRecipeCategoryFilter(categoryId, subCategoryId)
	end
	Skillet.dataScanned = false
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:SetDefaultFilters()
	C_TradeSkillUI.SetShowLearned(true)
	C_TradeSkillUI.SetShowUnlearned(true)
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(false)
	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(false)
	C_TradeSkillUI.SetOnlyShowFirstCraftRecipes(false)
	C_TradeSkillUI.ClearInventorySlotFilter()
	Professions.SetAllSourcesFiltered(false)
	C_TradeSkillUI.ClearRecipeSourceTypeFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()
end

function Skillet:GetCurrentFilterSet()
	local filterSet =
	{
		textFilter = C_TradeSkillUI.GetRecipeItemNameFilter(),
		showOnlyMakeable = C_TradeSkillUI.GetOnlyShowMakeableRecipes(),
		showOnlySkillUps = C_TradeSkillUI.GetOnlyShowSkillUpRecipes(),
		showOnlyFirstCraft = C_TradeSkillUI.GetOnlyShowFirstCraftRecipes(),
		professionInfo = C_TradeSkillUI.GetChildProfessionInfo(),
		showUnlearned = C_TradeSkillUI.GetShowUnlearned(),
		showLearned = C_TradeSkillUI.GetShowLearned(),
		sourceTypeFilter = C_TradeSkillUI.GetSourceTypeFilter(),
	}
	filterSet.invTypeFilters = {}
	for idx = 1, C_TradeSkillUI.GetAllFilterableInventorySlotsCount() do
		filterSet.invTypeFilters[idx] = C_TradeSkillUI.IsInventorySlotFiltered(idx)
	end
	return filterSet
end

function Skillet:ApplyfilterSet(filterSet)
	if filterSet then
		C_TradeSkillUI.SetShowLearned(filterSet.showLearned)
		C_TradeSkillUI.SetShowUnlearned(filterSet.showUnlearned)
		C_TradeSkillUI.SetOnlyShowMakeableRecipes(filterSet.showOnlyMakeable)
		C_TradeSkillUI.SetOnlyShowSkillUpRecipes(filterSet.showOnlySkillUps)
		C_TradeSkillUI.SetOnlyShowFirstCraftRecipes(filterSet.showOnlyFirstCraft)
		C_TradeSkillUI.SetSourceTypeFilter(filterSet.sourceTypeFilter)
		for idx, filtered in ipairs(filterSet.invTypeFilters) do
			C_TradeSkillUI.SetInventorySlotFilter(idx, not filtered)
		end
	else
		Professions.OnRecipeListSearchTextChanged("")
		Professions.SetDefaultFilters();
	end
end
