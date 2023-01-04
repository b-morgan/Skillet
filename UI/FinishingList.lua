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

SKILLET_FINISHING_LIST_HEIGHT = 16

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")

function Skillet:FinishingListToggleHaveItems()
	self.db.char.hide_unowned = not self.db.char.hide_unowned
	self:HideFinishingList()
end

local num_buttons = 0

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local function get_button(i)
	local button = _G["SkilletFinishingListButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletFinishingListButton"..i, SkilletFinishingListParent, "SkilletFinishingListItemTemplate")
		button:SetParent(SkilletFinishingListParent)
		button:SetPoint("TOPLEFT", "SkilletFinishingListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(SkilletFinishingListParent:GetFrameLevel() + 1)
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

local function createFinishingListFrame(self)
	--DA.DEBUG(0,"createFinishingListFrame")
	local frame = SkilletFinishingList
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
	local titletext = title:CreateFontString("SkilletFinishingListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: Finishing Reagents")
	frame.titletext = titletext
	SkilletFinishingHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	SkilletFinishingHaveItems:SetChecked(Skillet.db.char.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = SkilletFinishingListParent
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
	local FinishingListLocation = {
		prefix = "FinishingListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, FinishingListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	Skillet:EnableResize(frame, 420, 240, Skillet.UpdateFinishingListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
	return frame
end

--
-- Called to update the finishing list window
--
function Skillet:UpdateFinishingListWindow()
	--DA.DEBUG(0,"UpdateFinishingListWindow()")
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if self.cachedFinishingList then
		--DA.DEBUG(1,"UpdateFinishingListWindow: cachedFinishingList= ",DA.DUMP1(self.cachedFinishingList))
		numItems = #self.cachedFinishingList.reagents
	else
		return
	end
	local height = SkilletFinishingListParent:GetHeight() - 30 -- Allow for frame border
	local width = SkilletFinishingListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateFinishingListWindow: SkilletFinishingListParent height= "..tostring(height))
	--DA.DEBUG(1,"UpdateFinishingListWindow: SkilletFinishingListParent width= "..tostring(width))
	local button_count = height / SKILLET_FINISHING_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateFinishingListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(SkilletFinishingListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							SKILLET_FINISHING_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(SkilletFinishingListList)
	--DA.DEBUG(1,"UpdateFinishingListWindow: itemOffset= "..tostring(itemOffset))
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
			freagentID = self.cachedFinishingList.reagents[itemIndex].itemID
			button.freagentID = freagentID
			local freagentName, freagentLink = GetItemInfo(freagentID)
			local freagentQuality
			if not freagentName then
				Skillet.finishingDataNeeded = true
				C_Item.RequestLoadItemDataByID(freagentID)
				freagentName = "item:"..tostring(freagentID)
			end
			if freagentLink then
				freagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(freagentLink)
			end
			needed:SetText("")
			needed:Show()
			local num, craftable = self:GetInventory(self.currentPlayer, freagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			if freagentQuality then
				freagentName = freagentName..C_Texture.GetCraftingReagentQualityChatIcon(freagentQuality)
			end
			text:SetText(freagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture = GetItemIcon(freagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:SetID(itemIndex)
			button:Show()
		else
			--DA.DEBUG(1,"UpdateFinishingListWindow: Hide unused button")
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
end

--
-- Updates the scrollbar when a scroll event happens
--
function Skillet:FinishingList_OnScroll()
	Skillet:UpdateFinishingListWindow()
end

--
-- Functions to show and hide the FinishingList
--
function Skillet:DisplayFinishingList()
	--DA.DEBUG(0,"DisplayFinishingList()")
	if not self.FinishingList then
		self.FinishingList = createFinishingListFrame(self)
	end
	if not self.FinishingList:IsVisible() then
		self.FinishingList.titletext:SetText("Skillet: Finishing Reagents")
		self.FinishingList:Show()
	end
end

function Skillet:HideFinishingList(clear)
	--DA.DEBUG(0,"HideFinishingList()")
	if self.FinishingList then
		self.FinishingList:Hide()
	end
	if clear then
		self.cachedFinishingList = nil
	end
end

--
-- Called when an finishing reagent button in the Skillet detail frame is clicked.
-- This finishing list is used for selecting Finishing reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:FinishingReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"FinishingReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	SkilletFinishingHaveItems:Hide()
	local thisFinishing
--
-- Optional reagents are identified with a negative index.
-- Finishing reagents are identified with a +200 offset.
-- Note that this index is not the dataSlotIndex needed by C_TradeSkillUI.CraftRecipe
--
	thisFinishing = recipe.finishingData[reagentIndex - 200]
	self.cachedFinishingIndex = reagentIndex - 200
	--DA.DEBUG(1,"FinishingReagentOnClick: thisFinishing= "..DA.DUMP(thisFinishing))
	self.cachedFinishingList = thisFinishing.schematic
	--DA.DEBUG(1,"FinishingReagentOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", cachedFinishingList= "..DA.DUMP1(self.cachedFinishingList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateFinishingListWindow()
	elseif mouse == "RightButton" then
		if self.finishingSelected then
			self.finishingSelected[self.cachedFinishingIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the finishing reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function Skillet:GetFinishingItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetFinishingItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedFinishingList then
			freagentID = self.cachedFinishingList.reagents[index].itemID
			local name, link = GetItemInfo(freagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a finishing button
--
function Skillet:FinishingButtonOnEnter(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
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
	--DA.DEBUG(1,"FinishingButtonOnEnter: "..tostring(button.freagentID))
	tip:SetHyperlink("item:"..button.freagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an finishing button
--
function Skillet:FinishingButtonOnLeave(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
	local tip = SkilletTradeskillTooltip
	if Skillet.db.profile.scale_tooltip then
		tip:SetScale(Skillet.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an finishing reagent in the FinishingList is clicked.
-- This finishing list is used for selecting Finishing and Finishing reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:FinishingButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"FinishingButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"FinishingButtonOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", cachedFinishingList= "..DA.DUMP(self.cachedFinishingList))
	local freagentID = self.cachedFinishingList.reagents[reagentIndex].itemID
	local freagentSlot = self.cachedFinishingList.dataSlotIndex
	if not self.finishingSelected then
		self.finishingSelected = {}
	end
	if mouse == "LeftButton" then
		self.finishingSelected[self.cachedFinishingIndex] = { itemID = freagentID, quantity = 1, dataSlotIndex = freagentSlot, }
	elseif mouse == "RightButton" then
		self.finishingSelected[self.cachedFinishingIndex] = nil
	end
	--DA.DEBUG(1,"FinishingButtonOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", freagentID= "..tostring(freagentID)..", finishingSelected= "..DA.DUMP(self.finishingSelected))
	self:UpdateDetailWindow(skillIndex)
end
