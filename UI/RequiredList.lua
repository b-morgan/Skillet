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

function Skillet:RequiredListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideRequiredList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["SkilletRequiredListButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletRequiredListButton"..i, SkilletRequiredListParent, "SkilletRequiredListItemTemplate")
		button:SetParent(SkilletRequiredListParent)
		button:SetPoint("TOPLEFT", "SkilletRequiredListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(SkilletRequiredListParent:GetFrameLevel() + 1)
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

SKILLET_REQUIRED_LIST_HEIGHT = 16
local function createRequiredListFrame(self)
	--DA.DEBUG(0,"createRequiredListFrame")
	local frame = SkilletRequiredList
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
	local titletext = title:CreateFontString("SkilletRequiredListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: Required Reagents")
	frame.titletext = titletext
	SkilletRequiredHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	SkilletRequiredHaveItems:SetChecked(Skillet.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = SkilletRequiredListParent
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
	local RequiredListLocation = {
		prefix = "RequiredListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, RequiredListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	Skillet:EnableResize(frame, 420, 240, Skillet.UpdateRequiredListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	SKILLET_REQUIRED_LIST_HEIGHT = math.max(SkilletRequiredListButton1:GetHeight(), SKILLET_REQUIRED_LIST_HEIGHT)
	return frame
end

--
-- Called to update the optional list window
--
function Skillet:UpdateRequiredListWindow()
	--DA.DEBUG(0,"UpdateRequiredListWindow()")
	self.InProgress.optional = true
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if self.cachedRequiredList then
		numItems = #self.cachedRequiredList.reagents
		--DA.DEBUG(1,"UpdateRequiredListWindow: cachedRequiredList= ",DA.DUMP1(self.cachedRequiredList))
	else
		return
	end
	local height = SkilletRequiredListParent:GetHeight() - 30 -- Allow for frame border
	local width = SkilletRequiredListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateRequiredListWindow: SkilletRequiredListParent height= "..tostring(height)..", SKILLET_REQUIRED_LIST_HEIGHT= "..tostring(SKILLET_REQUIRED_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateRequiredListWindow: SkilletRequiredListParent width= "..tostring(width))
	local button_count = height / SKILLET_REQUIRED_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateRequiredListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(SkilletRequiredListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							SKILLET_REQUIRED_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(SkilletRequiredListList)
	--DA.DEBUG(1,"UpdateRequiredListWindow: itemOffset= "..tostring(itemOffset))
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
			oreagentID = self.cachedRequiredList.reagents[itemIndex].itemID
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
			--DA.DEBUG(1,"UpdateRequiredListWindow: Hide unused button")
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
function Skillet:RequiredList_OnScroll()
	Skillet:UpdateRequiredListWindow()
end

--
-- Functions to show and hide the RequiredList
--
function Skillet:DisplayRequiredList()
	--DA.DEBUG(0,"DisplayRequiredList()")
	if not self.RequiredList then
		self.RequiredList = createRequiredListFrame(self)
	end
	if not self.RequiredList:IsVisible() then
		self.RequiredList.titletext:SetText("Skillet: Required Reagents")
		self.RequiredList:Show()
	end
end

function Skillet:HideRequiredList(clear)
	--DA.DEBUG(0,"HideRequiredList()")
	if self.RequiredList then
		self.RequiredList:Hide()
	end
	if clear then
		self.cachedRequiredList = nil
	end
end

--
-- Called when an required reagent button in the Skillet detail frame is clicked.
-- This required list is used for selecting Required reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:RequiredReagentOnClick(button, mouse, skillIndex, reagentIndex)
	DA.DEBUG(0,"RequiredReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	SkilletRequiredHaveItems:Hide()
	local thisRequired, index
--
-- Required reagents are identified with a negative index < -100.
-- Finishing reagents are identified with a +200 offset.
-- Note that this index is not the dataSlotIndex needed by C_TradeSkillUI.CraftRecipe
--
	index = (reagentIndex + 100) * -1
	thisRequired = recipe.requiredData[index]
	self.cachedRequiredIndex = index
	DA.DEBUG(1,"RequiredReagentOnClick: thisRequired= "..DA.DUMP(thisRequired))
	self.cachedRequiredList = thisRequired.schematic
	DA.DEBUG(1,"RequiredReagentOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", cachedRequiredList= "..DA.DUMP1(self.cachedRequiredList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateRequiredListWindow()
	elseif mouse == "RightButton" then
		if self.requiredSelected then
			self.requiredSelected[self.cachedRequiredIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the required reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function Skillet:GetRequiredItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetRequiredItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedRequiredList then
			oreagentID = self.cachedRequiredList.reagents[index].itemID
			local name, link = C_Item.GetItemInfo(oreagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a required button
--
function Skillet:RequiredButtonOnEnter(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"RequiredButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
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
	--DA.DEBUG(1,"RequiredButtonOnEnter: "..tostring(button.oreagentID))
	tip:SetHyperlink("item:"..button.oreagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an optional button
--
function Skillet:RequiredButtonOnLeave(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"RequiredButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
	local tip = SkilletTradeskillTooltip
	if Skillet.db.profile.scale_tooltip then
		tip:SetScale(Skillet.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an required reagent in the RequiredList is clicked.
-- This required list is used for selecting Required reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function Skillet:RequiredButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"RequiredButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"RequiredButtonOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", cachedRequiredList= "..DA.DUMP(self.cachedRequiredList))
	local oreagentID = self.cachedRequiredList.reagents[reagentIndex].itemID
	local oreagentSlot = self.cachedRequiredList.dataSlotIndex
	if not self.requiredSelected then
		self.requiredSelected = {}
	end
	if mouse == "LeftButton" then
		self.requiredSelected[self.cachedRequiredIndex] = { itemID = oreagentID, quantity = 1, dataSlotIndex = oreagentSlot, }
	elseif mouse == "RightButton" then
		self.requiredSelected[self.cachedRequiredIndex] = nil
	end
	--DA.DEBUG(1,"RequiredButtonOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", oreagentID= "..tostring(oreagentID)..", requiredSelected= "..DA.DUMP(self.requiredSelected))
	self:UpdateDetailWindow(skillIndex)
end
