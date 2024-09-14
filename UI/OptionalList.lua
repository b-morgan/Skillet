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

function Skillet:OptionalListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideOptionalList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["SkilletOptionalListButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletOptionalListButton"..i, SkilletOptionalListParent, "SkilletOptionalListItemTemplate")
		button:SetParent(SkilletOptionalListParent)
		button:SetPoint("TOPLEFT", "SkilletOptionalListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(SkilletOptionalListParent:GetFrameLevel() + 1)
	end
	return button
end

--
-- Stolen from the Waterfall Ace2 addon.  Used for the backdrop of the scrollframe
--
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}-- Additional things to used to modify the XML created frame
local FrameBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

SKILLET_OPTIONAL_LIST_HEIGHT = 16
local function createOptionalListFrame(self)
	--DA.DEBUG(0,"createOptionalListFrame")
	local frame = SkilletOptionalList
	if not frame then
		return nil
	end
	if TSM_API and Skillet.db.profile.tsm_compat then
		frame:SetFrameStrata("TOOLTIP")
	else
		frame:SetFrameStrata("HIGH")
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0.1, 0.1, 0.1)
--
-- A title bar stolen from the Ace2 Waterfall window.
--
	local r,g,b = 0, 0.7, 0; -- dark green
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")
	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)
	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)
	titlebar:SetColorTexture(r,g,b,1)
	titlebar2:SetColorTexture(r,g,b,1)
	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)
	local titletext = title:CreateFontString("SkilletOptionalListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: Optional Reagents")
	frame.titletext = titletext
	SkilletOptionalHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	SkilletOptionalHaveItems:SetChecked(Skillet.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = SkilletOptionalListParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	if TSM_API and Skillet.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	local OptionalListLocation = {
		prefix = "OptionalListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, OptionalListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	Skillet:EnableResize(frame, 420, 240, Skillet.UpdateOptionalListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	SKILLET_OPTIONAL_LIST_HEIGHT = math.max(SkilletOptionalListButton1:GetHeight(), SKILLET_OPTIONAL_LIST_HEIGHT)
	return frame
end

--
-- Called to update the optional list window
--
function Skillet:UpdateOptionalListWindow()
	--DA.DEBUG(0,"UpdateOptionalListWindow()")
	self.InProgress.optional = true
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if self.cachedOptionalList then
		--DA.DEBUG(1,"UpdateOptionalListWindow: cachedOptionalList= ",DA.DUMP1(self.cachedOptionalList))
		numItems = #self.cachedOptionalList.reagents
	else
		return
	end
	local height = SkilletOptionalListParent:GetHeight()
	local buttonH = SkilletOptionalListButton1:GetHeight()
	local width = SkilletOptionalListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateOptionalListWindow: height= "..tostring(height)..", buttonH= "..tostring(buttonH))
	--DA.DEBUG(1,"UpdateOptionalListWindow: width= "..tostring(width))
	local button_count = height / buttonH
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateOptionalListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count)..", num_buttons= "..tostring(num_buttons))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(SkilletOptionalListList,		-- frame
							numItems,					-- num items
							button_count,				-- num to display
							buttonH)					-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(SkilletOptionalListList)
	--DA.DEBUG(1,"UpdateOptionalListWindow: itemOffset= "..tostring(itemOffset))
	for i=1, button_count, 1 do
		num_buttons = math.max(num_buttons, i)
		local itemIndex = i + itemOffset
		local  button = get_button(i)
		local    text = _G[button:GetName() .. "Text"]
		local    icon = _G[button:GetName() .. "Icon"]
		local   count = _G[button:GetName() .. "Count"]
		local  needed = _G[button:GetName() .. "Needed"]
		button:SetWidth(width)
		if itemIndex <= numItems then
			oreagentID = self.cachedOptionalList.reagents[itemIndex].itemID
			button.oreagentID = oreagentID
			local oreagentName, oreagentLink = C_Item.GetItemInfo(oreagentID)
			local oreagentQuality
			if not oreagentName then
				Skillet.optionalDataNeeded = true
				C_Item.RequestLoadItemDataByID(oreagentID)
				oreagentName = "item:"..tostring(oreagentID)
			end
			if oreagentLink then
				oreagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(oreagentLink)
			end
			needed:SetText("")
			needed:Show()
			local num, craftable = self:GetInventory(self.currentPlayer, oreagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			if oreagentQuality then
				oreagentName = oreagentName..C_Texture.GetCraftingReagentQualityChatIcon(oreagentQuality)
			end
			text:SetText(oreagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture = GetItemIcon(oreagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:SetID(itemIndex)
			button:Show()
		else
			--DA.DEBUG(1,"UpdateOptionalListWindow: Hide unused button")
			text:SetText("")
			text:Hide()
			icon:Hide()
			count:SetText("")
			count:Hide()
			needed:SetText("")
			needed:Hide()
			button:SetID(itemIndex * 100)
			button:Hide()
		end
	end
--
-- Hide any of the buttons that we created, but don't need right now
--
	for i = button_count+1, num_buttons, 1 do
		local button = get_button(i)
		button:Hide()
	end
	self.InProgress.optional = false
end

--
-- Updates the scrollbar when a scroll event happens
--
function Skillet:OptionalList_OnScroll()
	Skillet:UpdateOptionalListWindow()
end

--
-- Functions to show and hide the OptionalList
--
function Skillet:DisplayOptionalList()
	--DA.DEBUG(0,"DisplayOptionalList()")
	if not self.OptionalList then
		self.OptionalList = createOptionalListFrame(self)
	end
	if not self.OptionalList:IsVisible() then
		self.OptionalList.titletext:SetText("Skillet: Optional Reagents")
		self.OptionalList:Show()
	end
end

function Skillet:HideOptionalList(clear)
	--DA.DEBUG(0,"HideOptionalList()")
	if self.OptionalList then
		self.OptionalList:Hide()
	end
	if clear then
		self.cachedOptionalList = nil
	end
end

--
-- Called when an optional reagent button in the Skillet detail frame is clicked.
-- This optional list is used for selecting Optional reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:OptionalReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"OptionalReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	SkilletOptionalHaveItems:Hide()
	local thisOptional
--
-- Optional reagents are identified with a negative index.
-- Finishing reagents are identified with a +200 offset.
-- Note that this index is not the dataSlotIndex needed by C_TradeSkillUI.CraftRecipe
--
	thisOptional = recipe.optionalData[reagentIndex * -1]
	self.cachedOptionalIndex = reagentIndex * -1
	--DA.DEBUG(1,"OptionalReagentOnClick: thisOptional= "..DA.DUMP(thisOptional))
	self.cachedOptionalList = thisOptional.schematic
	--DA.DEBUG(1,"OptionalReagentOnClick: cachedOptionalIndex= "..tostring(self.cachedOptionalIndex)..", cachedOptionalList= "..DA.DUMP1(self.cachedOptionalList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateOptionalListWindow()
	elseif mouse == "RightButton" then
		if self.optionalSelected then
			self.optionalSelected[self.cachedOptionalIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the optional reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function Skillet:GetOptionalItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetOptionalItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedOptionalList then
			oreagentID = self.cachedOptionalList.reagents[index].itemID
			local name, link = C_Item.GetItemInfo(oreagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a optional button
--
function Skillet:OptionalButtonOnEnter(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"OptionalButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
	local tip = SkilletTradeskillTooltip
	tip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
	if Skillet.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if Skillet.db.profile.ttscale then
			uiScale = uiScale * Skillet.db.profile.ttscale
		end
		tip:SetScale(uiScale)
	end
	--DA.DEBUG(1,"OptionalButtonOnEnter: "..tostring(button.oreagentID))
	tip:SetHyperlink("item:"..button.oreagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an optional button
--
function Skillet:OptionalButtonOnLeave(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"OptionalButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
	local tip = SkilletTradeskillTooltip
	if Skillet.db.profile.scale_tooltip then
		tip:SetScale(Skillet.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an optional reagent in the OptionalList is clicked.
-- This optional list is used for selecting Optional reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:OptionalButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"OptionalButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"OptionalButtonOnClick: cachedOptionalIndex= "..tostring(self.cachedOptionalIndex)..", cachedOptionalList= "..DA.DUMP(self.cachedOptionalList))
	local oreagentID = self.cachedOptionalList.reagents[reagentIndex].itemID
	local oreagentSlot = self.cachedOptionalList.dataSlotIndex
	if not self.optionalSelected then
		self.optionalSelected = {}
	end
	if mouse == "LeftButton" then
		self.optionalSelected[self.cachedOptionalIndex] = { itemID = oreagentID, quantity = 1, dataSlotIndex = oreagentSlot, }
	elseif mouse == "RightButton" then
		self.optionalSelected[self.cachedOptionalIndex] = nil
	end
	--DA.DEBUG(1,"OptionalButtonOnClick: cachedOptionalIndex= "..tostring(self.cachedOptionalIndex)..", oreagentID= "..tostring(oreagentID)..", optionalSelected= "..DA.DUMP(self.optionalSelected))
	self:UpdateDetailWindow(skillIndex)
end
