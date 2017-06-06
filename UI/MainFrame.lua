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

SKILLET_TRADE_SKILL_HEIGHT = 16
SKILLET_NUM_REAGENT_BUTTONS = 8

local COLORORANGE = "|cffff8040"
local COLORYELLOW = "|cffffff00"
local COLORGREEN =  "|cff40c040"
local COLORGRAY =   "|cff808080"

-- min height for Skillet window
local SKILLET_MIN_HEIGHT = 575
-- height of the header portion
local SKILLET_HEADER_HEIGHT = 145

-- min width for skill list window
local SKILLET_SKILLLIST_MIN_WIDTH = 440

-- min/max width for the reagent window
local SKILLET_REAGENT_MIN_WIDTH = 280
local SKILLET_REAGENT_MAX_WIDTH = 320
local SKILLET_REAGENT_MIN_HEIGHT = 300

-- min width of count text
local SKILLET_COUNT_MIN_WIDTH = 100

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

-- Stack of previsouly selected skills for use by the
-- "click on reagent, go to recipe" code and for clicking on Queue'd recipes
-- stack is stack of tables: { "player", "tradeID", "skillIndex"}
local skillStack = {}
local gearTexture

-- Stolen from the Waterfall Ace2 addon.
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
local FrameBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}
-- List of functions that are called before a button is shown
local pre_show_callbacks = {}
-- List of functions that are called before a button is hidden
local pre_hide_callbacks = {}

function Skillet:internal_AddPreButtonShowCallback(method)
	assert(method and type(method) == "function",
		   "Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
	table.insert(pre_show_callbacks, method)
end

function Skillet:internal_AddPreButtonHideCallback(method)
	assert(method and type(method) == "function",
		   "Usage: Skillet:AddPreButtonHideCallback(method). method must be a non-nil function")
	table.insert(pre_hide_callbacks, method)
end

-- Figures out how to display the craftable counts for a recipe.
-- Returns: num, num_with_vendor, num_with_alts
local function get_craftable_counts(skill, numMade)
	--DA.DEBUG(2,"get_craftable_counts, name= "..tostring(skill.name)..", numMade= "..tostring(numMade))
	--DA.DEBUG(3,"get_craftable_counts, skill= "..DA.DUMP1(skill,1))
	local factor = 1
	if Skillet.db.profile.show_craft_counts then
		factor = numMade or 1
	end
	local num          = math.floor((skill.numCraftable or 0) / factor)
	local numrecursive = math.floor((skill.numRecursive or 0) / factor)
	local numwvendor   = math.floor((skill.numCraftableVendor or 0) / factor)
	local numwalts     = math.floor((skill.numCraftableAlts or 0) / factor)
	--DA.DEBUG(2,"get_craftable_counts = "..tostring(num)..", "..tostring(numrecursive)..", "..tostring(numwvendor)..", "..tostring(numwalts))
	return num, numrecursive, numwvendor, numwalts
end

function Skillet:CreateTradeSkillWindow()
	-- The SkilletFrame is defined in the file main_frame.xml
	local frame = SkilletFrame
	if not frame then
		return frame
	end
	--DA.DEBUG(0,"oldWidth= "..tostring(frame:GetWidth())..", oldHeight= "..tostring(frame:GetHeight()))
	if frame:GetWidth() < 710 then
		frame:SetWidth(710)		-- Reset the window size to the new minimum
	end
	if frame:GetHeight() < 545 then
		frame:SetHeight(545)
	end
	frame:SetBackdrop(FrameBackdrop);
	frame:SetBackdropColor(0.1, 0.1, 0.1)

	-- A title bar stolen from the Ace2 Waterfall window.
	local r,g,b = 0, 0.7, 0; -- dark green
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")
	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)
	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)
	titlebar:SetGradientAlpha("VERTICAL",r*0.6,g*0.6,b*0.6,1,r,g,b,1)
	titlebar:SetTexture(r,g,b,1)
	titlebar2:SetGradientAlpha("VERTICAL",r*0.9,g*0.9,b*0.9,1,r*0.6,g*0.6,b*0.6,1)
	titlebar2:SetTexture(r,g,b,1)

	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)

	local titletext = title:CreateFontString("SkilletTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText(L["Skillet Trade Skills"].." "..Skillet.version)
	local label = _G["SkilletFilterLabel"]
	label:SetText(L["Filter"])
	local label = _G["SkilletFilterText"]
	label:SetText("")
	local label = _G["SkilletSearchLabel"]
	label:SetText(L["Search"])
	SkilletPluginButton:SetText(L["Plugins"])
	SkilletCreateAllButton:SetText(L["Create All"])
	SkilletQueueAllButton:SetText(L["Queue All"])
	SkilletCreateButton:SetText(L["Create"])
	SkilletQueueButton:SetText(L["Queue"])
	SkilletStartQueueButton:SetText(L["Process"])
	SkilletEmptyQueueButton:SetText(L["Clear"])
	SkilletEnchantButton:SetText(L["Enchant"])
	SkilletRecipeNotesButton:SetText(L["Notes"])
	SkilletRecipeNotesFrameLabel:SetText(L["Notes"])
	SkilletShoppingListButton:SetText(L["Shopping List"])
	SkilletSortLabel:SetText(L["Sorting"])
	SkilletGroupLabel:SetText(L["Grouping"])
	SkilletIgnoredMatsButton:SetText(L["Ignored List"])
	SkilletQueueManagementButton:SetText(L["Queues"])
	SkilletQueueLoadButton:SetText(L["Load"])
	SkilletQueueDeleteButton:SetText(L["Delete"])
	SkilletQueueSaveButton:SetText(L["Save"])
	SkilletQueueOnlyButton:SetText(">")

	-- Always want these visible.
	SkilletItemCountInputBox:SetText("1");

	-- Progression status bar
	SkilletRankFrame:SetStatusBarColor(0.2, 0.2, 1.0, 1.0)
	SkilletRankFrameBackground:SetVertexColor(0.0, 0.0, 0.5, 0.2)
	if not SkilletRankFrame.subRanks then
		SkilletRankFrame.subRanks = {}
		SkilletRankFrame.subRanks.red = CreateFrame("StatusBar", "SkilletRankFrameRed", SkilletFrame, "SkilletRankFrameTemplate")
		SkilletRankFrame.subRanks.red:SetStatusBarColor(1.00, 0.00, 0.00, 1.00);
		SkilletRankFrame.subRanks.red:SetFrameLevel(SkilletFrame:GetFrameLevel()+8)
		SkilletRankFrame.subRanks.orange = CreateFrame("StatusBar", "SkilletRankFrameOrange", SkilletFrame, "SkilletRankFrameTemplate")
		SkilletRankFrame.subRanks.orange:SetStatusBarColor(1.00, 0.50, 0.25, 1.00);
		SkilletRankFrame.subRanks.orange:SetFrameLevel(SkilletFrame:GetFrameLevel()+7)
		SkilletRankFrame.subRanks.yellow = CreateFrame("StatusBar", "SkilletRankFrameYellow", SkilletFrame, "SkilletRankFrameTemplate")
		SkilletRankFrame.subRanks.yellow:SetStatusBarColor(1.00, 1.00, 0.00, 1.00);
		SkilletRankFrame.subRanks.yellow:SetFrameLevel(SkilletFrame:GetFrameLevel()+6)
		SkilletRankFrame.subRanks.green  = CreateFrame("StatusBar", "SkilletRankFrameGreen" , SkilletFrame, "SkilletRankFrameTemplate")
		SkilletRankFrame.subRanks.green:SetStatusBarColor(0.25, 0.75, 0.25, 1.00);
		SkilletRankFrame.subRanks.green:SetFrameLevel(SkilletFrame:GetFrameLevel()+5)
		SkilletRankFrame.subRanks.gray   = CreateFrame("StatusBar", "SkilletRankFrameGray"  , SkilletFrame, "SkilletRankFrameTemplate")
		SkilletRankFrame.subRanks.gray:SetStatusBarColor(0.50, 0.50, 0.50, 1.00);
		SkilletRankFrame.subRanks.gray:SetFrameLevel(SkilletFrame:GetFrameLevel()+4)
	end
	SkilletFrameEmptySpace = CreateFrame("Button", nil, SkilletSkillListParent, "SkilletEmptySpaceTemplate")
	SkilletFrameEmptySpace.skill = { ["mainGroup"] = true, }
	SkilletFrameEmptySpace:SetPoint("TOPLEFT",SkilletSkillListParent,"TOPLEFT")
	SkilletFrameEmptySpace:SetPoint("BOTTOMRIGHT",SkilletSkillListParent,"BOTTOMRIGHT")
	SkilletFrameEmptySpace:Show()

	-- The frame enclosing the scroll list needs a border and a background .....
	local backdrop = SkilletSkillListParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)

	-- Frame enclosing the reagent list
	backdrop = SkilletReagentParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)

	-- Frame enclosing the queue
	backdrop = SkilletQueueParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)

	-- frame enclosing the pop out notes panel
	backdrop = SkilletRecipeNotesFrame
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropColor(0.1, 0.1, 0.1)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetResizable(true)
	backdrop:Hide() -- initially hidden
	backdrop = SkilletQueueManagementParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	backdrop = SkilletViewCraftersParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	gearTexture = SkilletReagentParent:CreateTexture(nil, "OVERLAY")
	gearTexture:SetTexture("Interface\\Icons\\Trade_Engineering")
	gearTexture:SetHeight(16)
	gearTexture:SetWidth(16)
	-- Ace Window manager library, allows the window position (and size)
	-- to be automatically saved
	local windowManger = LibStub("LibWindow-1.1")
	local tradeSkillLocation = {
		prefix = "tradeSkillLocation_"
	}
	windowManger.RegisterConfig(frame, self.db.profile, tradeSkillLocation)
	windowManger.RestorePosition(frame)  -- restores scale also
	windowManger.MakeDraggable(frame)
	-- lets play the resize me game!
	local minwidth = self:GetMinSkillButtonWidth()
	if not minwidth or minwidth < SKILLET_SKILLLIST_MIN_WIDTH then
		minwidth = SKILLET_SKILLLIST_MIN_WIDTH
	end
	minwidth = minwidth +                  -- minwidth of scroll button
			   20 +                        -- padding between sroll and detail
			   SKILLET_REAGENT_MIN_WIDTH + -- reagent window (fixed width)
			   10                          -- padding about window borders
	self:EnableResize(frame, minwidth, SKILLET_MIN_HEIGHT, Skillet.UpdateTradeSkillWindow)
	-- Set up the sorting methods here
	self:InitializeSorting()
	self:ConfigureRecipeControls(false)				-- initial setting
	self.skilletStandalonQueue=Skillet:CreateStandaloneQueueFrame()
	UIDropDownMenu_Initialize(SkilletFilterDropDown, Skillet.InitializeDropdown, "MENU");
	return frame
end

function Skillet:InitRecipeFilterButtons()
	local lastButton = SkilletRecipeDifficultyButton
	if self.recipeFilters then
		for name, filter in pairs(self.recipeFilters) do
			local newButton = filter.initMethod(filter.namespace)
			if newButton then
				newButton:SetParent(SkilletFrame)
				newButton:SetPoint("BOTTOMRIGHT", lastButton, "BOTTOMLEFT", -5, 0)
				lastButton = newButton
				newButton:Show()
			end
		end
	end
end

-- Resets all the sorting and filtering info for the window
-- This is called when the window has changed enough that
-- sorting or filtering may need to be updated.
function Skillet:ResetTradeSkillWindow()
	Skillet:SortDropdown_OnShow()
	-- Reset all the added buttons so that they look OK.
	local buttons = SkilletFrame.added_buttons
	if buttons then
		local last_button = SkilletPluginButton
		for i=1, #buttons, 1 do
			local button = buttons[i]
			if button then
				button:ClearAllPoints()
				button:SetParent("SkilletFrame")
				button:SetPoint("TOPLEFT", last_button, "BOTTOMLEFT", 0, -1)
				button:Hide()
				button:SetAlpha(0)
				button:SetFrameLevel(0)
				last_button = button
			end
		end
	 end
end

-- Something has changed in the tradeskills, and the window needs to be updated
function Skillet:TradeSkillRank_Updated()
	DA.DEBUG(0,"TradeSkillRank_Updated")
	local _, rank, maxRank = self:GetTradeSkillLine();
	if rank and maxRank then
		SkilletRankFrame:SetMinMaxValues(0, maxRank);
		SkilletRankFrame:SetValue(rank);
		SkilletRankFrameSkillRank:SetText(rank.."/"..maxRank);
		for c,s in pairs(SkilletRankFrame.subRanks) do
			s:SetMinMaxValues(0, maxRank)
		end
		SkilletRankFrame.subRanks.gray:SetValue(maxRank)
	end
	DA.DEBUG(0,"TradeSkillRank_Updated over")
end

function Skillet:ClickSkillButton(skillIndex)
	if skillIndex and self.button_count then
		for i=1, self.button_count, 1 do
			local button = _G["SkilletScrollButton"..i]
			if button and button.skill and button.skill.skillIndex and button.skill.skillIndex == skillIndex and button:IsVisible() and not button.skill.subGroup then
				button:Click("LeftButton", true);
			end
		end
	end
end

-- Called when the list of skills is scrolled
function Skillet:SkillList_OnScroll()
	Skillet:UpdateTradeSkillWindow()
end

-- Called when the list of queued items is scrolled
function Skillet:QueueList_OnScroll()
	Skillet:UpdateQueueWindow()
end

local num_recipe_buttons = 1
local function get_recipe_button(i)
	local button = _G["SkilletScrollButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletScrollButton"..i, SkilletSkillListParent, "SkilletSkillButtonTemplate")
		button:SetParent(SkilletSkillListParent)
		button:SetPoint("TOPLEFT", "SkilletScrollButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(SkilletSkillListParent:GetFrameLevel() + 3)
		num_recipe_buttons = i
	end
	local buttonDrag = _G["SkilletScrollButtonDrag"..i]
	if not buttonDrag then
		buttonDrag = CreateFrame("Frame", "SkilletScrollButtonDrag"..i, SkilletSkillListParent, "SkilletSkillButtonDragTemplate")
		buttonDrag:SetParent(SkilletSkillListParent)
		buttonDrag:SetPoint("TOPLEFT", "SkilletScrollButton"..i, "TOPLEFT")
		buttonDrag:SetFrameLevel(SkilletSkillListParent:GetFrameLevel() + 2)
		buttonDrag:Hide()
	end
	if not button.highlight then
		button.index = i
		button.highlight = CreateFrame("Frame", "SkilletScrollHightlight"..i, button)
		button.highlight:SetParent(button)
		button.highlight:SetWidth(290)
		button.highlight:SetHeight(16)
--		button.highlight:SetFrameStrata("HIGH")
		button.highlight:SetPoint("LEFT", button:GetName(), "LEFT")
		button.highlight:SetPoint("RIGHT", button:GetName(), "RIGHT")
		button:SetFrameLevel(SkilletSkillListParent:GetFrameLevel())
		local t = button.highlight:CreateTexture(nil,"ARTWORK")
		t:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2.blp")
		t:SetAllPoints(button.highlight)
		button.highlight.texture = t
		button.highlight:SetAlpha(.25)
		button.highlight:Hide()
	end
	if Skillet.customSkillButtons then
		for n, b in pairs(Skillet.customSkillButtons) do
			b.initMethod(b.namespace, button, i)
		end
	end
	return button, buttonDrag
end

-- shows a recipe button (in the scrolling list) after doing the
-- required callbacks.
local function show_button(button, trade, skill, index, recipeID)
	for i=1, #pre_show_callbacks, 1 do
		local new_button = pre_show_callbacks[i](button, trade, skill, index, recipeID)
		if new_button and new_button ~= button then
			button:Hide() -- hide the old one just in case ....
			button = new_button
		end
	end
	button:Show()
end

-- hides a recipe button (in the scrolling list) after doing the
-- required callbacks.
local function hide_button(button, trade, skill, index)
	for i=1, #pre_hide_callbacks, 1 do
		local new_button = pre_hide_callbacks[i](button, trade, skill, index)
		if new_button and new_button ~= button then
			button:Hide() -- hide the old one just in case ....
			button = new_button
		end
	end
	button:Hide()
end

function Skillet:ConfigureRecipeControls(enchant)
	-- hide UI components that cannot be used for crafts and show that
	-- that are only applicable to trade skills, as needed
	if enchant then
		SkilletQueueAllButton:Hide()
		SkilletQueueButton:Hide()
		SkilletCreateAllButton:Hide()
		SkilletCreateButton:Hide()
		SkilletItemCountInputBox:Hide()
		SkilletStartQueueButton:Hide()
		SkilletEmptyQueueButton:Hide()
		SkilletEnchantButton:Show();
	else
		SkilletQueueAllButton:Show()
		SkilletQueueButton:Show()
		SkilletCreateAllButton:Show()
		SkilletCreateButton:Show()
		SkilletItemCountInputBox:Show()
		SkilletQueueParent:Show()
		SkilletStartQueueButton:Show()
		SkilletEmptyQueueButton:Show()
		SkilletEnchantButton:Hide()
	end
	self:InitRecipeFilterButtons()
	if self.currentPlayer ~= (UnitName("player")) then		-- only allow processing for the current player
		SkilletStartQueueButton:Disable()
		SkilletCreateAllButton:Disable()
		SkilletCreateButton:Disable()
	else
		SkilletStartQueueButton:Enable()
		SkilletCreateAllButton:Enable()
		SkilletCreateButton:Enable()
	end
end

function Skillet:PlayerSelect_OnEnter(button)
--[[ (Blizzard removed required functionality in 5.4)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local player = _G[button:GetName().."Text"]:GetText()
	GameTooltip:AddLine(player,1,1,1)
	GameTooltip:AddLine("Click to select a different character",.7,.7,.7)
	GameTooltip:Show()
]]--
end

function Skillet:RecipeDifficultyButton_OnShow()
	local level = self:GetTradeSkillOption("filterLevel")
	local v = 1-level/4
	SkilletRecipeDifficultyButtonTexture:SetTexCoord(0,1,v,v+.25)
end

function Skillet:TradeButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local _, player, tradeID = string.split("-", button:GetName())
	GameTooltip:AddLine(GetSpellInfo(tradeID))
	tradeID = tonumber(tradeID)
	local data = self:GetSkillRanks(player, tradeID)
	if not data or data == {} then
		GameTooltip:AddLine(L["No Data"],1,0,0)
	else
		local rank, maxRank = data.rank, data.maxRank
		GameTooltip:AddLine("["..tostring(rank).."/"..tostring(maxRank).."]",0,1,0)
		if tradeID == self.currentTrade then
			GameTooltip:AddLine("shift-click to link")
		end
		local buttonIcon = _G[button:GetName().."Icon"]
		local r,g,b = buttonIcon:GetVertexColor()
		if g == 0 then
			GameTooltip:AddLine("scan incomplete...",1,0,0)
		end
		if nonLinkingTrade[tradeID] and player ~= UnitName("player") then
			GameTooltip:AddLine((GetSpellInfo(tradeID)).." not available for alts")
		end
	end
	GameTooltip:Show()
end

function Skillet:TradeButtonAdditional_OnEnter(button)
	--DA.DEBUG(0,"TradeButtonAdditional_OnEnter("..tostring(button)..")")
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local spellID = button:GetID()
	local spellInfo, _ = GetSpellInfo(spellID)
	if button.Toy then
		_, spellInfo = C_ToyBox.GetToyInfo(spellID)
	end
	--DA.DEBUG(0,"spellInfo= "..tostring(spellInfo))
	GameTooltip:AddLine(spellInfo)
	if not button.Toy then
		local itemID = Skillet:GetAutoTargetItem(spellID)
		if itemID and IsAltKeyDown() then
			GameTooltip:AddLine("/use "..GetItemInfo(itemID))
		end
	end
	GameTooltip:Show()
end

function Skillet:TradeButton_OnClick(this,button)
	local name = this:GetName()
	local _, player, tradeID = string.split("-", name)
	tradeID = tonumber(tradeID)
	local data =  self:GetSkillRanks(player, tradeID)
	DA.DEBUG(0,"TradeButton_OnClick "..(name or "nil").." "..(player or "nil").." "..(tradeID or "nil"))
	if button == "LeftButton" then
		if player == UnitName("player") or (data and data ~= nil) then
			if self.currentTrade == tradeID and IsShiftKeyDown() then
				local link=C_TradeSkillUI.GetTradeSkillListLink();
				local activeEditBox =  ChatEdit_GetActiveWindow();
				if activeEditBox or WIM_EditBoxInFocus ~= nil then
					ChatEdit_InsertLink(link)
				else
					DA.DEBUG(0, link)
				end
			end
			if player == UnitName("player") then
				self:SetTradeSkill(self.currentPlayer, tradeID)
			else
				local link = self.db.realm.tradeSkills[player][tradeID].link
				local _,tradeString
				if Skillet.wowVersion >= 50400 then
					_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:[a-zA-Z0-9+/:]+)")
				elseif Skillet.wowVersion >= 50300 then
					_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:%d+:%d+:[a-zA-Z0-9+/:]+)")
				else
					_,_,tradeString = string.find(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[a-zA-Z0-9+/]+)")
				end
				if tradeString then
					SetItemRef(tradeString,link,"LeftButton")
				end
			end
			this:SetChecked(true)
		else
			this:SetChecked(false)
		end
	else
		if this:GetChecked() then
			if IsShiftKeyDown() then
				Skillet:FlushAllData()
				if player == UnitName("player") then
					Skillet:InitializeDatabase(player)
				end
				Skillet:RescanTrade()
			else
				Skillet:RescanTrade()
			end
			Skillet:UpdateTradeSkillWindow()
		end
	end
	GameTooltip:Hide()
end

function Skillet:UpdateTradeButtons(player)
	--DA.DEBUG(0,"UpdateTradeButtons()")
	local position = 0 -- pixels
	local tradeSkillList = self.tradeSkillList
	local frameName = "SkilletFrameTradeButtons-"..player
	local frame = _G[frameName]
	if not frame then
		frame = CreateFrame("Frame", frameName, SkilletFrame)
	end
	frame:Show()
	for i=1,#tradeSkillList,1 do	-- iterate thru all skills in defined order for neatness (professions, secondary, class skills)
		local tradeID = tradeSkillList[i]
		local ranks = self:GetSkillRanks(player, tradeID)
		local tradeLink
		if self.db.realm.tradeSkills[player] then
			if nonLinkingTrade[tradeID] then
				tradeLink = nil
			else
				local tradePlayer = self.db.realm.tradeSkills[player][tradeID]
				if tradePlayer then
					tradeLink = tradePlayer.link
				end
			end
		end
		if ranks then
			local spellName, _, spellIcon = GetSpellInfo(tradeID)
			local buttonName = "SkilletFrameTradeButton-"..player.."-"..tradeID
			local button = _G[buttonName]
			if not button then
				DA.DEBUG(0,"CreateFrame for "..tostring(buttonName))
				button = CreateFrame("CheckButton", buttonName, frame, "SkilletTradeButtonTemplate")
			end
			if player ~= UnitName("player") and not tradeLink then		-- fade out buttons that don't have data collected
				button:SetAlpha(.4)
				button:SetHighlightTexture("")
				button:SetPushedTexture("")
				button:SetCheckedTexture("")
			end
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
			local buttonIcon = _G[buttonName.."Icon"]
			buttonIcon:SetTexture(spellIcon)
			position = position + button:GetWidth()
			if tradeID == self.currentTrade then
				button:SetChecked(true)
				if Skillet.data.skillList[tradeID].scanned then
					buttonIcon:SetVertexColor(1,1,1)
				else
					buttonIcon:SetVertexColor(1,0,0)
				end
			else
				button:SetChecked(false)
			end
			button:Show()
		end
	end
	position = position + 10
	--DA.DEBUG(0,"doing "..tostring(#Skillet.AutoButtonsList).." AutoButtonsList entries")
	for i=1,#Skillet.AutoButtonsList,1 do	-- iterate thru all skills in defined order for neatness (professions, secondary, class skills)
		local additionalSpellTab = Skillet.AutoButtonsList[i]
		local additionalSpellId = additionalSpellTab[1]
		local additionalSpellName = additionalSpellTab[2]
		local additionalToy = additionalSpellTab[3]
		local spellName, _, spellIcon
		if additionalToy then
			_, spellName, spellIcon = C_ToyBox.GetToyInfo(additionalSpellId)
		else
			spellName, _, spellIcon = GetSpellInfo(additionalSpellId)
		end
		--DA.DEBUG(0,"additionalSpellId= "..tostring(additionalSpellId)..", spellName= "..tostring(spellName)..", spellIcon= "..tostring(spellIcon))
		local buttonName = "SkilletDo"..additionalSpellName
		local button = _G[buttonName]
		if not button then
			DA.DEBUG(0,"CreateFrame for "..tostring(buttonName))
			button = CreateFrame("Button", buttonName, frame, "SkilletTradeButtonAdditionalTemplate")
			button:SetID(additionalSpellId)
			if additionalToy then
				button.Toy = true
			end
		end
		button:SetAttribute("type", "macro");
		local macrotext = Skillet:GetAutoTargetMacro(additionalSpellId, button.Toy)
		--DA.DEBUG(0,"macrotext= "..tostring(macrotext))
		button:SetAttribute("macrotext", macrotext)
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
		local buttonIcon = _G[buttonName.."Icon"]
		buttonIcon:SetTexture(spellIcon)
		position = position + button:GetWidth()
		button:Show()
		if additionalToy then
			--DA.DEBUG(0,"IsToyUsable= "..tostring(C_ToyBox.IsToyUsable(additionalSpellId)))
			if C_ToyBox.IsToyUsable(additionalSpellId) then
				button:Enable()
				button:SetAlpha(1.0)
			else
				button:Disable()
				button:SetAlpha(0.2)
			end
		end
	end
end

function Skillet:UpdateAutoTradeButtons()
	--DA.DEBUG(0,"UpdateAutoTradeButtons()")
	local tradeSkillList = self.tradeSkillList
	Skillet.AutoButtonsList = {}
	for i=1,#tradeSkillList,1 do
		local tradeID = tradeSkillList[i]
		local ranks = self:GetSkillRanks(UnitName("player"), tradeID)
		if ranks then	-- this player knows this skill
			local additionalSpellTab = Skillet.TradeSkillAdditionalAbilities[tradeID]
			if additionalSpellTab then -- this skill has additional abilities
				if type(additionalSpellTab[1]) == "table" then
					for j=1,#additionalSpellTab,1 do
						DA.DEBUG(0,"UpdateAutoTradeButtons: additionalSpellTab["..tostring(j).."]= "..DA.DUMP1(additionalSpellTab[j]))
						table.insert(Skillet.AutoButtonsList, additionalSpellTab[j])
					end
				else
					DA.DEBUG(0,"UpdateAutoTradeButtons: additionalSpellTab= "..DA.DUMP1(additionalSpellTab))
					table.insert(Skillet.AutoButtonsList, additionalSpellTab)
				end
			end
		end
	end
end

function SkilletPluginDropdown_OnClick(this)
	--DA.DEBUG(0,"SkilletPluginDropdown_OnClick()")
	local oldScript = this.oldButton:GetScript("OnClick")
	oldScript(this)
	for i=1,#SkilletFrame.added_buttons do
		local buttonName = "SkilletPluginDropdown"..i
		local button = _G[buttonName]
		if button then
			button:Hide()
		end
	end
end

function Skillet:PluginButton_OnClick(button)
	if SkilletFrame.added_buttons then
		for i=1,#SkilletFrame.added_buttons do
			local oldButton = SkilletFrame.added_buttons[i]
			local buttonName = "SkilletPluginDropdown"..i
			local button = _G[buttonName]
			if not button then
				button = CreateFrame("button", buttonName, SkilletPluginButton, "UIPanelButtonTemplate")
				button:Hide()
			end
			--DA.DEBUG(0,buttonName)
			button:SetText(oldButton:GetText())
			button:SetWidth(100)
			button:SetHeight(22)
			button:SetFrameLevel(SkilletFrame:GetFrameLevel()+10)
			button:SetScript("OnClick", SkilletPluginDropdown_OnClick)
			button:SetPoint("TOPLEFT", 0, -i*20)
			button.oldButton = oldButton
			oldButton:Hide()
			if button:IsVisible() then
				button:Hide()
			else
				button:Show()
			end
		end
	end
end

local updateWindowBusy = false
-- this window busy thing was something i added cuz i kept getting asynchronous updates
local updateWindowCount = 1
-- Updates the trade skill window whenever anything has changed,
-- number of skills, skill type, skill level, etc
function Skillet:internal_UpdateTradeSkillWindow()
	--DA.DEBUG(0,"internal_UpdateTradeSkillWindow()")
	self:NameEditSave()
	if not self.currentPlayer or not self.currentTrade then return end
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	if updateWindowBusy then
		return
	end
	updateWindowBusy = true
	local numTradeSkills = 0
	if not self.dataScanned then
		self.dataScanned = self:RescanTrade()
		self:SortAndFilterRecipes()
	end
	if not self.data.sortedSkillList[skillListKey] then
		numTradeSkills = self:SortAndFilterRecipes()
		if not numTradeSkills or numTradeSkills < 1 then
			numTradeSkills = 0
		end
	end
	self:ResetTradeSkillWindow()
	updateWindowCount = updateWindowCount + 1
	if self.data.sortedSkillList[skillListKey] then
		numTradeSkills = self.data.sortedSkillList[skillListKey].count
	else
		numTradeSkills = 0
	end
	self:UpdateDetailsWindow(self.selectedSkill)
	self:UpdateTradeButtons(self.currentPlayer)
	SkilletIgnoredMatsButton:Show()
	if not self.currentTrade then
		-- nothing to see, nothing to update
		self:SetSelectedSkill(nil)
		self.skillMainSelection = nil
		updateWindowBusy = false
		return
	end
	-- shopping list button always shown
	SkilletShoppingListButton:Show()
	SkilletFrame:SetAlpha(self.db.profile.transparency)
	SkilletFrame:SetScale(self.db.profile.scale)
	local uiScale = SkilletFrame:GetEffectiveScale()
	local width = SkilletFrame:GetWidth() - 20 -- for padding.
	local height = SkilletFrame:GetHeight()
	local reagent_width = width / 2
	local reagent_height = SKILLET_REAGENT_MIN_HEIGHT + (height - SKILLET_MIN_HEIGHT) * 2 / 3
	if reagent_width < SKILLET_REAGENT_MIN_WIDTH then
		reagent_width = SKILLET_REAGENT_MIN_WIDTH
	elseif reagent_width > SKILLET_REAGENT_MAX_WIDTH then
		reagent_width = SKILLET_REAGENT_MAX_WIDTH
	end
	SkilletReagentParent:SetWidth(reagent_width)
	SkilletReagentParent:SetHeight(reagent_height)
	SkilletQueueManagementParent:SetWidth(reagent_width)
	SkilletViewCraftersParent:SetWidth(reagent_width)
	local width = SkilletFrame:GetWidth() - reagent_width - 20 -- padding
	SkilletSkillListParent:SetWidth(width)
	-- Set the state of any craft specific options
	self:RecipeDifficultyButton_OnShow()
	SkilletHideUncraftableRecipes:SetChecked(self:GetTradeSkillOption("hideuncraftable"))
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(self:GetTradeSkillOption("hideuncraftable"))
	self:UpdateQueueWindow()
	self:UpdateShoppingListWindow()
	self:FavoritesOnlyRefresh()
	-- Window Title
	local tradeName = self:GetTradeName(self.currentTrade)
	local title = _G["SkilletTitleText"];
	if title then
		title:SetText(L["Skillet Trade Skills"] .. " "..self.version..": " .. self.currentPlayer .. "/" .. tradeName)
	end
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	local rank,maxRank = 0,0
	local skillRanks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
	if skillRanks then
		rank,maxRank = skillRanks.rank, skillRanks.maxRank
	end
	-- Progression status bar
	SkilletRankFrame:SetMinMaxValues(0, maxRank)
	SkilletRankFrame:SetValue(rank)
	SkilletRankFrameSkillRank:SetText(tradeName.."    "..rank.."/"..maxRank)
	SkilletRankFrame.subRanks.gray:SetValue(maxRank)
	for c,s in pairs(SkilletRankFrame.subRanks) do
		s:SetMinMaxValues(0, maxRank)
	end
--	SkilletPlayerSelectText:SetText(self.currentPlayer)
	SkilletPlayerSelect:Hide()		-- Currently doesn't do anything and the player name is in the title
	-- it seems the resize for the main skillet window happens before the resize for the skill list box
	local button_count = (SkilletFrame:GetHeight() - SKILLET_HEADER_HEIGHT) / SKILLET_TRADE_SKILL_HEIGHT
	button_count = math.floor(button_count)
	self.button_count = button_count
	-- Update the scroll frame
	FauxScrollFrame_Update(SkilletSkillList,				-- frame
							numTradeSkills,					-- num items
							button_count,					-- num to display
							SKILLET_TRADE_SKILL_HEIGHT)		-- value step (item height)
	-- Where in the list of skill to start counting.
	local skillOffset = FauxScrollFrame_GetOffset(SkilletSkillList);
	-- Remove any selected highlight, it will be added back as needed
	SkilletHighlightFrame:Hide();
	local nilFound = false
	width = SkilletSkillListParent:GetWidth() - 10
	if SkilletSkillList:IsVisible() then
		-- adjust for the width of the scroll bar, if it is visible.
		width = width - 20
	end
	local text, color, skillIndex
	local max_text_width = width
	local showOwned = self:GetTradeSkillOption("filterInventory-owned") -- count from Altoholic
	local showBag = self:GetTradeSkillOption("filterInventory-bag")
	local showCraft = self:GetTradeSkillOption("filterInventory-crafted")
	local showVendor = self:GetTradeSkillOption("filterInventory-vendor")
	local showAlts = self:GetTradeSkillOption("filterInventory-alts")
	local catstring = {}
	SkilletFrameEmptySpace.skill.subGroup = self:RecipeGroupFind(self.currentPlayer,self.currentTrade,self.currentGroupLabel,self.currentGroup)
	self.visibleSkillButtons = math.min(numTradeSkills - skillOffset, button_count)
	-- Iterate through all the buttons that make up the scroll window
	-- and fill them in with data or hide them, as necessary
	for i=1, button_count, 1 do
		local rawSkillIndex = i + skillOffset
		local button, buttonDrag = get_recipe_button(i)
		button.rawIndex = rawSkillIndex
		button:SetWidth(width)
		if rawSkillIndex <= numTradeSkills then
			local skill = sortedSkillList[rawSkillIndex]
			--DA.DEBUG(2,"rawSkillIndex= "..tostring(rawSkillIndex)..", name= "..tostring(skill.name))
			--DA.DEBUG(3,"skill= "..DA.DUMP1(skill,1))
			local skillIndex = skill.skillIndex
			local buttonText = _G[button:GetName() .. "Name"]
			local levelText = _G[button:GetName() .. "Level"]
			local countText = _G[button:GetName() .. "Counts"]
			local suffixText = _G[button:GetName() .. "Suffix"]
			local buttonExpand = _G[button:GetName() .. "Expand"]
			local buttonFavorite = _G[button:GetName() .. "Favorite"]
			local subSkillRankBar = _G[button:GetName() .. "SubSkillRankBar"]
			buttonText:SetText("")
			levelText:SetText("")
			countText:SetText("")
			countText:Hide()
			countText:SetWidth(10)
			suffixText:SetText("")
			suffixText:Hide()
			subSkillRankBar:Hide()
			if self.db.profile.display_required_level then
				levelText:SetWidth(skill.depth*8+20)
			else
				levelText:SetWidth(skill.depth*8)
			end
			buttonFavorite:Hide()
			local textAlpha = 1
			if self.dragEngaged then
				buttonDrag:SetWidth(width)
				button.highlight:Hide()
				if Skillet.mouseOver then
					if Skillet.mouseOver.skill.subGroup then
						if button == Skillet.mouseOver then
							button.highlight:Show()
						end
					elseif skill.subGroup == Skillet.mouseOver.skill.parent then
						button.highlight:Show()
					end
				end
				textAlpha = .75
				local dx = self.selectedTextOffsetXY[1] / uiScale
				local dy = self.selectedTextOffsetXY[2] / uiScale
				buttonDrag:SetPoint("TOPLEFT", button, "TOPLEFT", buttonDrag.skill.depth*8-8+dx, dy)
			else
				if skill.selected then
					button.highlight:Show()
				else
					button.highlight:Hide()
				end
			end
			if skill.subGroup then
				if SkillButtonNameEdit.originalButton ~= buttonText then
					buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, textAlpha)
					countText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, textAlpha)
					local expanded = skill.subGroup.expanded
					if expanded then
						buttonExpand:SetNormalTexture("Interface\\Addons\\Skillet\\Icons\\expand_arrow_open.tga")
						buttonExpand:SetHighlightTexture("Interface\\Addons\\Skillet\\Icons\\expand_arrow_open.tga")
					else
						buttonExpand:SetNormalTexture("Interface\\Addons\\Skillet\\Icons\\expand_arrow_closed.tga")
						buttonExpand:SetHighlightTexture("Interface\\Addons\\Skillet\\Icons\\expand_arrow_closed.tga")
					end
					local name = skill.name.." ("..#skill.subGroup.entries..")"
					buttonText:SetText(name)
					button:SetID(skillIndex or 0)
					buttonExpand.group = skill.subGroup
					button.skill = skill
					button:UnlockHighlight() -- headers never get highlighted
					buttonExpand:Show()
					local hasProgressBar = Skillet.hasProgressBar[skill.name]
					if hasProgressBar then
						local category = Skillet.db.global.Categories[self.currentTrade][hasProgressBar]
						local currentRank = category.skillLineCurrentLevel
						local startingRank = category.skillLineStartingRank
						local maxRank = category.skillLineMaxLevel
						subSkillRankBar:Show();
						subSkillRankBar:SetMinMaxValues(startingRank,maxRank);
						subSkillRankBar:SetValue(currentRank);
						subSkillRankBar.currentRank = currentRank;
						subSkillRankBar.maxRank = maxRank;
						subSkillRankBar.Rank:SetText(currentRank.."/"..maxRank);
					end
					local button_width = button:GetTextWidth()
					show_button(button, self.currentTrade, skillIndex, i)
				end
			else
				local recipe = self:GetRecipe(skill.recipeID)
				buttonExpand.group = nil
				button.skill = skill
				local skill_color = skill.color or skill.skillData.color or NORMAL_FONT_COLOR
				buttonText:SetTextColor(skill_color.r, skill_color.g, skill_color.b, textAlpha)
				countText:SetTextColor(skill_color.r, skill_color.g, skill_color.b, textAlpha)
				buttonExpand:Hide()
				buttonFavorite.skill = skill
				buttonFavorite.SetFavorite = function(self, state)
					if state then
						self:GetNormalTexture():SetAlpha(0.5)
					else
						self:GetNormalTexture():SetAlpha(0)
					end
				end
				buttonFavorite:SetFavorite(Skillet:IsFavorite(skill.recipeID))
				buttonFavorite:Show()
				-- if the item has a minimum level requirement, then print that here
				if self.db.profile.display_required_level then
					local level = self:GetLevelRequiredToUse(recipe.itemID)
					if level and level > 1 then
						local _, _, rarity = GetItemInfo("item:"..recipe.itemID)
						local r, g, b = GetItemQualityColor(rarity)
						if r and g and b then
							levelText:SetTextColor(r, g, b)
						end
						levelText:SetText(level)
					end
				end
				-- Get any additional text that ThirdPartyHooks (or plugins) might add
				text = (self:RecipeNamePrefix(skill, recipe) or "") .. (skill.name or "")
				if #recipe.reagentData > 0 then
					local num, numrecursive, numwvendor, numwalts = get_craftable_counts(skill.skillData, recipe.numMade)
					local cbag = "|cff80ff80" -- green
					local ccraft =  "|cffffff80" -- yellow
					local cvendor = "|cffffa050" -- orange
					local calts = "|cffff80ff" -- purple
					if (num > 0 and showBag) or (numrecursive > 0 and showCraft) or (numwvendor > 0 and showVendor) or (numwalts > 0 and showAlts) then
						local c = 1
						if showBag then
							if num >= 1000 then
								num = "##"
							end
							catstring[c] = cbag .. num
							c = c + 1
						end
						if showCraft then
							if numrecursive >= 1000 then
								numrecursive = "##"
							end
							catstring[c] = ccraft .. numrecursive
							c = c + 1
						end
						if showVendor then
							if numwvendor >= 1000 then
								numwvendor = "##"
							end
							catstring[c] = cvendor .. numwvendor
							c = c + 1
						end
						if showAlts then
							if numwalts >= 1000 then
								numwalts = "##"
							end
							catstring[c] = calts .. numwalts
							c = c + 1
						end
						local count = ""
						if c > 1 then
							count = "|cffa0a0a0[" -- blue
							for b=1,c-1 do
								count = count .. catstring[b]
								if b+1 < c then
									count = count .. "|cffa0a0a0/"
								end
							end
							count = count .. "|cffa0a0a0]|r"
						end
						countText:SetText(count)
						countText:Show()
					else
						countText:Hide()
					end
				else
					countText:Hide()
				end
				-- show the count of the item currently owned that the recipe will produce
				if showOwned and Skillet.currentPlayer == UnitName("player") then
					local numowned = (self.db.realm.auctionData[Skillet.currentPlayer][recipe.itemID] or 0) + GetItemCount(recipe.itemID,true)
					if numowned > 0 then
						if numowned >= 1000 then
							numowned = "##"
						end
						local count = "|cff95fcff("..numowned..") "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				if skill_color.alttext == "+++" then
					local _, _, _, _, _, numSkillUps  = Skillet:GetTradeSkillInfo(skill.recipeID)
					if numSkillUps and numSkillUps > 1 then
						local count = "<+"..numSkillUps.."> "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				countText:SetWidth(math.max(countText:GetStringWidth(),SKILLET_COUNT_MIN_WIDTH)) -- make end of buttonText have a fixed location
				Skillet:CustomizeCountsColumn(recipe, countText) -- ThirdPartyHook
				button:SetID(skillIndex or 0)
				-- If enhanced recipe display is enabled, show the difficulty as text,
				-- rather than as a colour. This should help used that have problems
				-- distinguishing between the difficulty colours we use.
				if self.db.profile.enhanced_recipe_display then
					text = text .. skill_color.alttext;
				end
				-- If this recipe is upgradable, append the current and maximum upgrade levels
				local recipeInfo = Skillet.data.recipeInfo[self.currentTrade][skill.recipeID]
				if recipeInfo and recipeInfo.upgradeable then
					if Skillet.db.profile.show_max_upgrade then
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade).."/"..tostring(recipeInfo.maxUpgrade)..")"
					else
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade)..")"
					end
				end
				-- Get any additional text that ThirdPartyHooks (or plugins) might add (right justified at end of text)
				suffixText:SetText(self:RecipeNameSuffix(skill, recipe) or "")
				suffixText:Show()
				buttonText:SetText(text)
				buttonText:SetWordWrap(false)
				buttonText:SetWidth(max_text_width - countText:GetWidth())
				if not self.dragEngaged and self.selectedSkill and self.selectedSkill == skillIndex then
					SkilletHighlightFrame:SetPoint("TOPLEFT", "SkilletScrollButton"..i, "TOPLEFT", 0, 0)
					SkilletHighlightFrame:SetWidth(button:GetWidth())
					SkilletHighlightFrame:SetFrameLevel(button:GetFrameLevel())
					if color then
						SkilletHighlight:SetTexture(color.r, color.g, color.b, 0.4)
					else
						SkilletHighlight:SetTexture(0.7, 0.7, 0.7, 0.4)
					end
					-- And update the details for this skill, just in case something
					-- has changed (mats consumed, etc)
					self:UpdateDetailsWindow(self.selectedSkill)
					SkilletHighlightFrame:Show()
					button:LockHighlight()
				else
					-- not selected
					button:SetBackdropColor(0.8, 0.2, 0.2)
					button:UnlockHighlight()
				end
				show_button(button, self.currentTrade, skillIndex, i, skill.recipeID)
			end
		else
			-- We have no data for you Mister Button .....
--			hide_button(button, self.currentTrade, skillIndex, i, skill.recipeID)
			hide_button(button, self.currentTrade, skillIndex, i)
			button:UnlockHighlight()
		end
	end
	-- Hide any of the buttons that we created but don't need right now
	for i = button_count+1, num_recipe_buttons, 1 do
		local button, buttonDrag = get_recipe_button(i)
		hide_button(button, self.currentTrade, 0, i)
	end
	if self.visibleSkillButtons > 0 then
		local button = get_recipe_button(self.visibleSkillButtons)
		SkilletFrameEmptySpace:SetPoint("TOPLEFT",button,"BOTTOMLEFT")
	else
		SkilletFrameEmptySpace:SetPoint("TOPLEFT",SkilletSkillListParent,"TOPLEFT")
	end
	SkilletFrameEmptySpace:SetPoint("BOTTOMRIGHT",SkilletSkillListParent,"BOTTOMRIGHT")
	updateWindowBusy = false
	--DA.DEBUG(0,"internal_UpdateTradeSkillWindow Complete")
end

-- Display an action packed tooltip when we are over
-- a recipe in the list of skills
function Skillet:SkillButton_OnEnter(button)
	local id = button:GetID()
	if not id then
		return
	end
	if button.locked then return end	-- it's possible that multiple onEnters might stack ontop of each other if you scroll really quickly, this is to avoid that problem
	button.locked = true
	local b = button:GetName()
	if not b then
		button.locked = false
		return
	end
	local buttonName = _G[b.."Name"]
	if button.skill.subGroup then			-- header
		buttonName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		button.locked = false
		return
	end
	if self.dragEngaged then		-- dragging a skill, don't highlight other buttons
		button.locked = false
		return
	end
	local skill = button.skill
	if not skill then
		button.locked = false
		return
	end
	if self.fencePickEngaged then
		self:SkillButton_ClearSelections()
		self:SkillButton_SetSelections(self.skillMainSelection, button.rawIndex)
		self:UpdateTradeSkillWindow()
		button.locked = false
		return
	end
	buttonName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	local recipe = self:GetRecipe(skill.recipeID) or Skillet.UnknownRecipe
	if not self.db.profile.show_detailed_recipe_tooltip then
		-- user does not want the tooltip displayed, it can get a bit big after all
		button.locked = false
		return
	end
	local tip = SkilletTradeskillTooltip
	ShoppingTooltip1:Hide()
	ShoppingTooltip2:Hide()
	tip:SetOwner(button, "ANCHOR_BOTTOMRIGHT",-300);
	tip:SetBackdropColor(0,0,0,1);
	tip:ClearLines();
	tip:SetClampedToScreen(true)
	-- Set the tooltip's scale to match that of the default UI
	local uiScale = 1.0;
	if ( GetCVar("useUiScale") == "1" ) then
		uiScale = tonumber(GetCVar("uiscale"))
	end
	tip:SetScale(uiScale)
	-- If not displaying full tooltips you have to press Ctrl to see them
	if IsControlKeyDown() or Skillet.db.profile.display_full_tooltip then
		local name, link, quality, quantity, altlink, _
		if recipe.itemID == 0 or not Skillet.db.profile.display_item_tooltip then
			link = GetSpellLink(skill.recipeID)
			name = GetSpellInfo(link)
			quality = nil
			quantity = nil
			if recipe.itemID ~= 0 then
				_, altlink = GetItemInfo(recipe.itemID)
			end
		else
			if recipe.itemID then
				name,link,quality = GetItemInfo(recipe.itemID)
			end
			altlink = GetSpellLink(skill.recipeID)
			quantity = recipe.numMade
		end
		if altlink and IsAltKeyDown() then
			tip:SetHyperlink(altlink)
		elseif link then
			tip:SetHyperlink(link)
		end
		if IsShiftKeyDown() then
			if recipe.itemID == 0 then
				Skillet:Tooltip_ShowCompareItem(tip, GetInventoryItemLink("player", recipe.slot), "left")
			else
				Skillet:Tooltip_ShowCompareItem(tip, link, "left")
			end
		end
	else
		-- Name of the recipe
		local color = Skillet.skill_style_type[skill.difficulty]
		if (color) then
			tip:AddLine(skill.name, color.r, color.g, color.b, false);
		else
			tip:AddLine(skill.name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false);
		end
	end
	local num, numrecursive, numwvendor, numwalts = 0, 0, 0, 0
	if skill.skillData then
		num, numrecursive, numwvendor, numwalts = get_craftable_counts(skill.skillData, recipe.numMade)
	end
	-- how many can be created with the reagents in the inventory
	if num > 0 then
		local text = "\n" .. num .. " " .. L["can be created from reagents in your inventory"];
		tip:AddLine(text, 1, 1, 1, false); -- (text, r, g, b, wrap)
	end
	-- how many can be created by crafting the reagents
	if numrecursive > 0 then
		local text = "\n" .. numrecursive .. " " .. L["can be created by crafting reagents"];
		tip:AddLine(text, 1, 1, 1, false); -- (text, r, g, b, wrap)
	end
	-- how many can be crafted with reagents on alts, excluding this one.
	if numwalts and numwalts > 0 and numwalts ~= num then
		local text =  "\n" .. numwalts .. " " .. L["can be created from reagents on other characters"];
		tip:AddLine(text, 1, 1, 1, false);	-- (text, r, g, b, wrap)
	end
	if numwvendor and numwvendor > 0 and numwvendor ~= num then
		local text =  "\n" .. numwvendor .. " " .. L["can be created with reagents bought at vendor"];
		tip:AddLine(text, 1, 1, 1, false);	-- (text, r, g, b, wrap)
	end
	Skillet:AddCustomTooltipInfo(tip, recipe)
	tip:AddLine("\n" .. (self:GetReagentLabel(self.currentTrade, id) or ""));
	-- now the list of regents for this recipe and some info about them
	for i=1, #recipe.reagentData, 1 do
		local reagent = recipe.reagentData[i]
		if not reagent then
			break
		end
		local numInBoth, numCraftable = self:GetInventory(self.currentPlayer, reagent.reagentID)
		local itemName = GetItemInfo(reagent.reagentID) or reagent.reagentID
		local text
		if self:VendorSellsReagent(reagent.reagentID) then
			text = string.format("  %d x %s  |cff808080(%s)|r", reagent.numNeeded, itemName, L["buyable"])
		else
			text = string.format("  %d x %s", reagent.numNeeded, itemName)
		end
		local counts = string.format("|cff808080[%d/%d]|r", numInBoth, numCraftable)
		tip:AddDoubleLine(text, counts, 1, 1, 1);
	end
	local text = string.format("[%s/%s]", L["Inventory"], L["craftable"]) -- match the case sometime
	tip:AddDoubleLine("\n", text)
	local text1 = string.format("recipeID= %d",skill.recipeID)
	local text = string.format("itemID= %d",recipe.itemID)
	tip:AddDoubleLine(text1, text)
	tip:Show()
	button.locked = false
end

-- Sets the game tooltip item to the selected skill
function Skillet:SetTradeSkillToolTip(skillIndex)
	--DA.DEBUG(2,"SetTradeSkillToolTip("..tostring(skillIndex)..")")
	GameTooltip:ClearLines()
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		if recipe.itemID ~= 0 then
			GameTooltip:SetHyperlink("item:"..recipe.itemID)
			if IsShiftKeyDown() then
				GameTooltip_ShowCompareItem()
			end
		else
			GameTooltip:SetHyperlink("enchant:"..recipe.spellID)				-- doesn't create an item, just tell us about the recipe
			if IsShiftKeyDown() then
				Skillet:Tooltip_ShowCompareItem(GameTooltip, GetInventoryItemLink("player", recipe.slot), "left")
			end
		end
	end
end

function Skillet:SetReagentToolTip(reagentID, numNeeded, numCraftable)
	GameTooltip:ClearLines()
	GameTooltip:SetHyperlink("item:"..reagentID)
	if self:VendorSellsReagent(reagentID) then
		GameTooltip:AppendText(GRAY_FONT_COLOR_CODE .. " (" .. L["buyable"] .. ")" .. FONT_COLOR_CODE_CLOSE)
	end
	if self.db.global.itemRecipeSource[reagentID] then
		GameTooltip:AppendText(GRAY_FONT_COLOR_CODE .. " (" .. L["craftable"] .. ")" .. FONT_COLOR_CODE_CLOSE)
		for recipeID in pairs(self.db.global.itemRecipeSource[reagentID]) do
			local recipe = self:GetRecipe(recipeID)
			GameTooltip:AddDoubleLine("Source: ",(self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..self:GetRecipeName(recipeID),0,1,0,1,1,1)
			local lookupTable = self.data.skillIndexLookup
			local player = self.currentPlayer
			if lookupTable[recipeID] then
				local rankData = self:GetSkillRanks(player, recipe.tradeID)
				if rankData then
					local rank, maxRank = rankData.rank, rankData.maxRank
					GameTooltip:AddDoubleLine("  "..player,"["..(rank or "?").."/"..(maxRank or "?").."]",1,1,1)
				else
					GameTooltip:AddDoubleLine("  "..player,"[???/???]",1,1,1)
				end
			end
		end
	end
	local inBoth = self:GetInventory(self.currentPlayer, reagentID)
	local surplus = inBoth - numNeeded * numCraftable
	if inBoth < 0 then
		GameTooltip:AddDoubleLine("in shopping list:",(-inBoth),1,1,0)
	end
	if surplus < 0 then
		GameTooltip:AddDoubleLine("to craft "..numCraftable.." you need:",(-surplus),1,0,0)
	end
	if self.db.realm.reagentsInQueue[self.currentPlayer] then
		local inQueue = self.db.realm.reagentsInQueue[self.currentPlayer][reagentID]
		if inQueue then
			if inQueue < 0 then
				GameTooltip:AddDoubleLine("used in queued skills:",-inQueue,1,1,1)
			else
				GameTooltip:AddDoubleLine("created from queued skills:",inQueue,1,1,1)
			end
		end
	end
end

local bopCache = {}
function Skillet:bopCheck(item)
	if bopCache[item] == 1 then
		return true
	end
	if bopCache[item] == 0 then
		return false
	end
	local _,link = GetItemInfo(item)
	local tooltip = _G["SkilletParsingTooltip"]
	if tooltip == nil then
		tooltip = CreateFrame("GameTooltip", "SkilletParsingTooltip", _G["ANCHOR_NONE"], "GameTooltipTemplate")
		tooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
	end
	tooltip:SetHyperlink("item:"..item)
	local tiplines = tooltip:NumLines()
	--DA.DEBUG(0,(link or "nil"))
	for i=1, tiplines, 1 do
		local lineText = string.lower(_G["SkilletParsingTooltipTextLeft"..i]:GetText() or " ")
		--DA.DEBUG(0,lineText)
		if (string.find(lineText, "binds when picked up")) then
			bopCache[item] = 1
			--DA.DEBUG(0,"bop")
			return true
		end
	end
	bopCache[item] = 0
	--DA.DEBUG(0,"boe")
end

function Skillet:HideDetailWindow()
	SkilletSkillName:SetText("")
	SkilletSkillCooldown:SetText("")
	SkilletDescriptionText:SetText("")
	SkilletRequirementLabel:Hide()
	SkilletRequirementText:SetText("")
	SkilletSkillIcon:Hide()
	SkilletReagentLabel:Hide()
	SkilletRecipeNotesButton:Hide()
	SkilletPreviousItemButton:Hide()
	SkilletExtraDetailTextLeft:Hide()
	SkilletExtraDetailTextRight:Hide()
	SkilletAuctionatorButton:Hide()
	SkilletHighlightFrame:Hide()
	SkilletFrame.selectedSkill = -1;
	-- Always want these set.
	SkilletItemCountInputBox:SetText("1");
--	SkilletCreateCountSlider:SetMinMaxValues(1, 20);
--	SkilletCreateCountSlider:SetValue(1);
	for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
		local button = _G["SkilletReagent"..i]
		button:Hide();
	end
	if SkilletRankFrame.subRanks then
		for c,s in pairs(SkilletRankFrame.subRanks) do
			s:Hide()
		end
	end
end

local lastUpdateSpellID = nil
local ARLProfessionInitialized = {}
-- Updates the details window with information about the currently selected skill
function Skillet:UpdateDetailsWindow(skillIndex)
	--DA.DEBUG(0,"UpdateDetailsWindow("..tostring(skillIndex)..")")
	SkilletReagentParent.StarsFrame:Hide()
	self.currentRecipeInfo = nil
	local recipeInfo = nil
	if not skillIndex or skillIndex < 0 then
		Skillet:HideDetailWindow()
		return
	end
	local texture;
	SkilletFrame.selectedSkill = skillIndex
	self.numItemsToCraft = 1
	if self.recipeNotesFrame then
		self.recipeNotesFrame:Hide()
	end
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
	local recipe = Skillet.UnknownRecipe
	if skill then
		lastUpdateSpellID = skill.id
		recipe = self:GetRecipe(skill.id) or Skillet.UnknownRecipe
		--DA.DEBUG(0,"skill= "..DA.DUMP1(skill))
		--DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe))
		-- Name of the skill
		SkilletSkillName:SetText(recipe.name)
		SkilletRecipeNotesButton:Show()
		if recipe.spellID and recipe.itemID then
			local orange,yellow,green,gray = self:GetTradeSkillLevels((recipe.itemID > 0 and recipe.itemID))
			SkilletRankFrame.subRanks.green:SetValue(gray)
			SkilletRankFrame.subRanks.yellow:SetValue(green)
			SkilletRankFrame.subRanks.orange:SetValue(yellow)
			SkilletRankFrame.subRanks.red:SetValue(orange)
			for c,s in pairs(SkilletRankFrame.subRanks) do
				s:Show()
			end
		end
		recipeInfo = Skillet.data.recipeInfo[self.currentTrade][recipe.spellID]
		self.currentRecipeInfo = recipeInfo
		if recipeInfo and recipeInfo.upgradeable then
			for i, starFrame in ipairs(SkilletReagentParent.StarsFrame.Stars) do
				starFrame.EarnedStar:SetShown(i <= recipeInfo.learnedUpgrade);
				starFrame.UnearnedStar:SetShown(i <= recipeInfo.maxUpgrade);
			end
			SkilletReagentParent.StarsFrame:Show();
		end
		local description = C_TradeSkillUI.GetRecipeDescription(skill.id)
		--DA.DEBUG(0,"description="..tostring(description))
		if description then
			description = description:gsub("\r","")	-- Skillet frame has less space than Blizzard frame, so
			description = description:gsub("\n","")	-- remove any extra blank lines, but
			SkilletDescriptionText:SetMaxLines(4)	-- don't let the text get too big.
			SkilletDescriptionText:SetText(description)
		else
			SkilletDescriptionText:SetText("")
		end
		-- Whether or not it is on cooldown.
		local _, _, _, _, _, _, _, _, _, _, _, displayAsUnavailable, unavailableString = Skillet:GetTradeSkillInfo(skill.id)
		--DA.DEBUG(0,"displayAsUnavailable="..tostring(displayAsUnavailable)..", unavailableString="..tostring(unavailableString))
		local cd, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(skill.id)
		--DA.DEBUG(0,"cd= "..tostring(cd))
		local cooldown = (cd or 0)
		if cooldown > 0 then
			SkilletSkillCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(cooldown))
		elseif displayAsUnavailable then
			local width = SkilletReagentParent:GetWidth()
			local iconw = SkilletSkillIcon:GetWidth()
			SkilletSkillCooldown:SetWidth(width - iconw - 15)
			SkilletSkillCooldown:SetMaxLines(3)
			SkilletSkillCooldown:SetText(unavailableString)
		else
			SkilletSkillCooldown:SetText("")
		end
	else
		recipe = Skillet.UnknownRecipe
		SkilletSkillName:SetText("unknown")
	end
	-- Are special tools needed for this skill?
	if recipe.tools then
		local toolList = {}
		for i=1,#recipe.tools do
			--DA.DEBUG(0,"tool: "..(recipe.tools[i] or "nil"))
			toolList[i*2-1] = recipe.tools[i]
			if skill.tools then
			--DA.DEBUG(0,"arg: "..(skill.tools[i] or "nil"))
				toolList[i*2] = skill.tools[i]
			else
				toolList[i*2] = 1
			end
		end
		SkilletRequirementText:SetText(BuildColoredListString(unpack(toolList)))
		SkilletRequirementText:Show()
		SkilletRequirementLabel:Show()
	else
		SkilletRequirementText:Hide()
		SkilletRequirementLabel:Hide()
	end
	if recipeInfo and recipeInfo.alternateVerb then
		texture = recipeInfo.icon
	end
	if recipe.itemID and recipe.itemID ~= 0 then
		texture = GetItemIcon(recipe.itemID)
	end
	SkilletSkillIcon:SetNormalTexture(texture)
	SkilletSkillIcon:Show()
	if AuctionatorLoaded and AuctionFrame then
		SkilletAuctionatorButton:Show()
	end
	-- How many of these items are produced at one time ..
	if recipe.numMade > 1 then
		--DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe,1))
		local text = tostring(recipe.numMade)
		local adjustNumMade = self.db.global.AdjustNumMade[recipe.spellID]
		--DA.DEBUG(0,"recipeID= "..tostring(recipe.spellID)..", adjustNumMade= "..tostring(adjustNumMade))
		if adjustNumMade then
			text = string.format("|cffff8080%d|r",recipe.numMade)
		end
		SkilletSkillIconCount:SetText(text)
		SkilletSkillIconCount:Show()
	else
		SkilletSkillIconCount:SetText("")
		SkilletSkillIconCount:Hide()
	end
	-- How many can we queue/create?
--	SkilletCreateCountSlider:SetValue(self.numItemsToCraft);
	SkilletItemCountInputBox:SetText("" .. self.numItemsToCraft);
	SkilletItemCountInputBox:HighlightText()
--	SkilletCreateCountSlider.tooltipText = L["Number of items to queue/create"];
	-- Reagents required ...
	SkilletReagentLabel:SetText(self:GetReagentLabel(SkilletFrame.selectedSkill) or "");
	SkilletReagentLabel:Show();
	local width = SkilletReagentParent:GetWidth()
	local lastReagentButton = _G["SkilletReagent1"]
	for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
		local button = _G["SkilletReagent"..i]
		local   text = _G[button:GetName() .. "Text"]
		local   icon = _G[button:GetName() .. "Icon"]
		local  count = _G[button:GetName() .. "Count"]
		local needed = _G[button:GetName() .. "Needed"]
		local reagent = recipe.reagentData[i]
		if reagent then
			local reagentName
			if reagent.reagentID then
				reagentName	= GetItemInfo("item:"..reagent.reagentID) or reagent.reagentID
			else
				reagentName = "unknown"
			end
			local num, craftable = self:GetInventory(self.currentPlayer, reagent.reagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			if num < reagent.numNeeded then
				-- grey it out if we don't have it
				count:SetText(GRAY_FONT_COLOR_CODE .. count_text .. FONT_COLOR_CODE_CLOSE)
				text:SetText(GRAY_FONT_COLOR_CODE .. reagentName .. FONT_COLOR_CODE_CLOSE)
				if self:VendorSellsReagent(reagent.reagentID) then
					needed:SetTextColor(0,1,0)
				else
					needed:SetTextColor(1,0,0)
				end
			else
				-- ungrey it
				count:SetText(count_text)
				text:SetText(reagentName)
				needed:SetTextColor(1,1,1)
			end
			texture = GetItemIcon(reagent.reagentID)
			icon:SetNormalTexture(texture)
			needed:SetText(reagent.numNeeded.."x")
			button:SetWidth(width - 20)
			button:Show()
			lastReagentButton = button
		else
			button:Hide()
		end
	end
	if #skillStack > 0 then
		SkilletPreviousItemButton:Show()
	else
		SkilletPreviousItemButton:Hide()
	end
--	Do any plugins want to add extra info to the details window?
	local label, extra_text = Skillet:GetExtraText(skill, recipe)

	-- Is there any source info from the recipe?
	local sourceText
	if Skillet.db.profile.show_recipe_source_for_learned then
		sourceText = C_TradeSkillUI.GetRecipeSourceText(skill.id)
	else
		local recipeInfo = C_TradeSkillUI.GetRecipeInfo(skill.id)
		if recipeInfo and not recipeInfo.learned then
			sourceText = C_TradeSkillUI.GetRecipeSourceText(skill.id)
		end
	end
	if label then
		if sourceText then
			label = label.."\n\n"..sourceText
		end
	else
		if sourceText then
			label = sourceText
			extra_text = ""
		end
	end
	if label then
		SkilletExtraDetailTextLeft:SetPoint("TOPLEFT",lastReagentButton,"BOTTOMLEFT",0,-10)
		SkilletExtraDetailTextLeft:SetText(GRAY_FONT_COLOR_CODE..label)
		SkilletExtraDetailTextLeft:Show()
	else
		SkilletExtraDetailTextLeft:Hide()
	end
	if extra_text then
		SkilletExtraDetailTextRight:SetPoint("TOPLEFT",lastReagentButton,"BOTTOMLEFT",50,-10)
		SkilletExtraDetailTextRight:SetText(extra_text)
		SkilletExtraDetailTextRight:Show()
	else
		SkilletExtraDetailTextRight:Hide()
	end
end

local num_queue_buttons = 0
local function get_queue_button(i)
	local button = _G["SkilletQueueButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletQueueButton"..i, SkilletQueueParent, "SkilletQueueItemButtonTemplate")
		button:SetParent(SkilletQueueParent)
		button:SetPoint("TOPLEFT", "SkilletQueueButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(SkilletQueueParent:GetFrameLevel() + 1)
	end
	return button
end

function Skillet:IncreaseItemCount(this, button, count)
	local val = SkilletItemCountInputBox:GetNumber()
	if button == "RightButton" then
		count = count * 10
	end
	if val == 1 and count > 1 then
		val = 0
	end
	val = val + count
	if val < 1 then
		val = 1
	end
	SkilletItemCountInputBox:SetText(val)
end
function Skillet:QueueItemButton_OnClick(this, button)
	local queue = self.db.realm.queueData[self.currentPlayer]
	local index = this:GetID()
	if button == "LeftButton" then
		Skillet:QueueManagementToggle(true)
		local recipeID = queue[index].recipeID
		local recipe = self:GetRecipe(recipeID)
		local tradeID = recipe.tradeID
		local newSkillIndex = self.data.skillIndexLookup[recipeID]
		DA.DEBUG(0,"selecting new skill "..tradeID..":"..(newSkillIndex or "nil"))
		self:SetTradeSkill(self.currentPlayer, tradeID, newSkillIndex)
		DA.DEBUG(0,"done selecting new skill")
	elseif button == "RightButton" then
		Skillet:SkilletQueueMenu_Show(this)
	end
end

-- Updates the window/scroll list displaying queue of items
-- that are waiting to be crafted.
function Skillet:UpdateQueueWindow()
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not queue then
		SkilletStartQueueButton:SetText(L["Process"])
		SkilletEmptyQueueButton:Disable()
		SkilletStartQueueButton:Disable()
		return
	end
	local numItems = #queue
	if numItems > 0 then
		SkilletStartQueueButton:Enable()
		SkilletEmptyQueueButton:Enable()
	else
		SkilletStartQueueButton:Disable()
		SkilletEmptyQueueButton:Disable()
	end
	if self.queuecasting and UnitCastingInfo("player") then
		SkilletStartQueueButton:SetText(L["Pause"])
	else
		SkilletStartQueueButton:SetText(L["Process"])
	end
	local button_count = SkilletQueueList:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
	button_count = math.floor(button_count)
	-- Update the scroll frame
	FauxScrollFrame_Update(SkilletQueueList,				-- frame
						   numItems,                        -- num items
						   button_count,                    -- num to display
						   SKILLET_TRADE_SKILL_HEIGHT)      -- value step (item height)
	-- Where in the list of skill to start counting.
	local itemOffset = FauxScrollFrame_GetOffset(SkilletQueueList)
	local width = SkilletQueueList:GetWidth()
	-- Iterate through all the buttons that make up the scroll window
	-- and fill then in with data or hide them, as necessary
	for i=1, button_count, 1 do
		local itemIndex = i + itemOffset
		num_queue_buttons = math.max(num_queue_buttons, i)
		local button       = get_queue_button(i)
		local countFrame   = _G[button:GetName() .. "Count"]
		local queueCount   = _G[button:GetName() .. "CountText"]
		local nameButton   = _G[button:GetName() .. "Name"]
		local queueName    = _G[button:GetName() .. "NameText"]
		local deleteButton = _G[button:GetName() .. "DeleteButton"]
		button:SetWidth(width)
		-- Stick this on top of the button we use for displaying queue contents.
		deleteButton:SetFrameLevel(button:GetFrameLevel() + 1)
		local fixed_width = countFrame:GetWidth() + deleteButton:GetWidth()
		fixed_width = width - fixed_width - 10 -- 10 for the padding between items
		queueName:SetWidth(fixed_width);
		nameButton:SetWidth(fixed_width);
		if itemIndex <= numItems then
			deleteButton:SetID(itemIndex)
			nameButton:SetID(itemIndex)
			local queueCommand = queue[itemIndex]
			if queueCommand then
				local recipe = self:GetRecipe(queueCommand.recipeID)
				queueName:SetText((self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..(recipe.name or recipe.recipeID))
				queueCount:SetText(queueCommand.count)
			end
			nameButton:Show()
			queueName:Show()
			countFrame:Show()
			queueCount:Show()
			button:Show()
		else
			button:Hide()
			queueName:Hide()
			queueCount:Hide()
		end
	end
	-- Hide any of the buttons that we created, but don't need right now
	for i = button_count+1, num_queue_buttons, 1 do
	   local button = get_queue_button(i)
	   button:Hide()
	end
end

function Skillet:SkillButton_SetSelections(id1, id2)
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	if id1 > id2 then id1,id2 = id2,id1 end
	for i=1,sortedSkillList.count do
		if i>=id1 and i<=id2 then
			sortedSkillList[i].selected = true
		else
			sortedSkillList[i].selected = false
		end
	end
end

function Skillet:SkillButton_SetAllSelections(toggle)
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	for i=1,sortedSkillList.count do
		sortedSkillList[i].selected = toggle
	end
end

function Skillet:SkillButton_ClearSelections()
	self:SkillButton_SetAllSelections(false)
end

function Skillet:NameEditSave()
	if SkillButtonNameEdit:IsVisible() and SkillButtonNameEdit.originalButton then
		SkillButtonNameEdit.originalButton:SetText(SkillButtonNameEdit:GetText())
		self:RecipeGroupRenameEntry(SkillButtonNameEdit.skill, SkillButtonNameEdit:GetText())
	end
	SkillButtonNameEdit:ClearFocus()
end

function Skillet:SkillButton_OnMouseDown(button)
	self.dragStartXY = { GetCursorPosition() }
	self.selectedTextOffsetXY = { 0, 0 }
end

function Skillet:SkillButton_OnMouseUp(button)
	--DA.DEBUG(0, "up")
end

function Skillet:SkillButton_DragUpdate()
	if self.dragEngaged then
		local x,y = GetCursorPosition()
		self.selectedTextOffsetXY[1] = x - self.dragStartXY[1]
		self.selectedTextOffsetXY[2] = y - self.dragStartXY[2]
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_OnDragStop(button, mouse)
	Skillet:SkillButton_OnReceiveDrag(Skillet.mouseOver, mouse)
	for i=1,num_recipe_buttons do
		local button, buttonDrag = get_recipe_button(i)
		buttonDrag:Hide()
	end
	self.dragEngaged = false
	self.fencePickEngaged = false
	self:UpdateTradeSkillWindow()
end

function Skillet:SkillButton_OnDragStart(button, mouse)
	local skill = button.skill
	if skill.selected and skill then
		if not self:RecipeGroupIsLocked() then
			for i=1,self.visibleSkillButtons do
				local button, buttonDrag = get_recipe_button(i)
				local buttonText = _G[button:GetName().."Name"]
				local buttonDragText = _G[buttonDrag:GetName().."Name"]
				buttonDrag.skill = button.skill
				local r,g,b = buttonText:GetTextColor()
				buttonDragText:SetText(buttonText:GetText())
				buttonDragText:SetTextColor(r,g,b,.4)
				if button.skill and button.skill.selected then
					buttonDrag:Show()
				else
					buttonDrag:Hide()
				end
			end
			self.dragEngaged = true
			self.fencePickEngaged = false
		end
	else
		self.skillMainSelection = button.rawIndex
		self:SetSelectedSkill(button:GetID())
		self.dragEngaged = false
		self.fencePickEngaged = true
		if skill then skill.selected = true end
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:SkillButton_OnReceiveDrag(button, mouse)
	if not self:RecipeGroupIsLocked() then
		local skill = nil
		local destinationGroup = nil
		if button then
			skill = button.skill
			if skill.subGroup then
				destinationGroup = button.skill.subGroup
			else
				if skill.parent ~= nil then
					destinationGroup = skill.parent
				else
					destinationGroup = skill
				end
			end
		else
			destinationGroup = self:RecipeGroupFind(self.currentPlayer, self.currentTrade, self.currentGroupLabel)
		end
		if self.dragEngaged and (skill == nil or not skill.selected) then
			local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
			local sortedSkillList = self.data.sortedSkillList[skillListKey]
			for i=1,sortedSkillList.count do
				if sortedSkillList[i].selected then
					self:RecipeGroupMoveEntry(sortedSkillList[i], destinationGroup)
				end
			end
			self.dragEngaged = false
			self:SortAndFilterRecipes()
			self:UpdateTradeSkillWindow()
		end
	end
end

function Skillet:SkillButton_CopySelected()
	DA.DEBUG(0,"SkillButton_CopySelected()")
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	if not self.skillListCopyBuffer then
		self.skillListCopyBuffer = {}
	end
	self.skillListCopyBuffer[self.currentTrade] = {}
	local d = 1
	for i=1,sortedSkillList.count do
		if sortedSkillList[i].selected and not (sortedSkillList[i].parentIndex and sortedSkillList[sortedSkillList[i].parentIndex].selected) then
			self.skillListCopyBuffer[self.currentTrade][d] = sortedSkillList[i]
			--DA.DEBUG(1,"copying "..(sortedSkillList[i].name or "nil"))
			d = d + 1
		end
	end
end

function Skillet:SkillButton_PasteSelected(button)
	DA.DEBUG(0,"SkillButton_PasteSelected("..tostring(button)..")")
	if not self:RecipeGroupIsLocked() then
		local parentGroup
		if button then
			parentGroup = button.skill.subGroup or button.skill.parent
		else
			parentGroup = self:RecipeGroupFind(self.currentPlayer, self.currentTrade, self.currentGroupLabel, self.currentGroup)
		end
		if self.skillListCopyBuffer and self.skillListCopyBuffer[self.currentTrade] then
			for d=1,#self.skillListCopyBuffer[self.currentTrade] do
				--DA.DEBUG(1,"pasting "..(self.skillListCopyBuffer[self.currentTrade][d].name or "nil").." to "..parentGroup.name)
				self:RecipeGroupPasteEntry(self.skillListCopyBuffer[self.currentTrade][d], parentGroup)
			end
		end
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_DeleteSelected()
	DA.DEBUG(0,"SkillButton_DeleteSelected()")
	if not self:RecipeGroupIsLocked() then
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		for i=1,sortedSkillList.count do
			if sortedSkillList[i].selected and not (sortedSkillList[i].parent and sortedSkillList[i].parent.selected) then
				self:RecipeGroupDeleteEntry(sortedSkillList[i])
			end
		end
		self.selectedSkill = nil
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_CutSelected()
	DA.DEBUG(0,"SkillButton_CutSelected()")
	Skillet:SkillButton_CopySelected()
	Skillet:SkillButton_DeleteSelected()
end

function Skillet:SkillButton_NewGroup()
	DA.DEBUG(0,"SkillButton_NewGroup()")
	if not self:RecipeGroupIsLocked() then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		local name, index = self:RecipeGroupNewName(player..":"..tradeID..":"..label, "New Group")
		local newGroup = self:RecipeGroupNew(player, tradeID, label, name)
		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		self:RecipeGroupAddSubGroup(parentGroup, newGroup, index)
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_MakeGroup()
	DA.DEBUG(0,"SkillButton_MakeGroup()")
	if not self:RecipeGroupIsLocked() then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		local name, index = self:RecipeGroupNewName(player..":"..tradeID..":"..label, "New Group")
		local newGroup = self:RecipeGroupNew(player, tradeID, label, name)
		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		for i=1,sortedSkillList.count do
			if sortedSkillList[i].selected and not (sortedSkillList[i].parent and sortedSkillList[i].parent.selected) then
				self:RecipeGroupMoveEntry(sortedSkillList[i], newGroup)
			end
		end
		self:RecipeGroupAddSubGroup(parentGroup, newGroup, index)
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_OnKeyDown(button, key)
	--DA.DEBUG(0,key)
	if key == "D" then
		self:SkillButton_SetAllSelections(false)
	elseif key == "A" then
		self:SkillButton_SetAllSelections(true)
	elseif key == "C" then
		self:SkillButton_CopySelected()
	elseif key == "X" then
		self:SkillButton_CutSelected()
	elseif key == "V" then
		self:SkillButton_PasteSelected(self.mouseOver)
	elseif key == "DELETE" or key == "BACKSPACE" then
		self:SkillButton_DeleteSelected()
	elseif key == "N" then
		self:SkillButton_NewGroup()
	elseif key == "G" then
		self:SkillButton_MakeGroup()
	else
		return
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:SkillButton_NameEditEnable(button)
	if not self:RecipeGroupIsLocked() then
		SkillButtonNameEdit:SetText(button.skill.name)
		SkillButtonNameEdit:SetParent(button:GetParent())
		local buttonText = _G[button:GetName().."Name"]
		local numPoints = button:GetNumPoints()
		for p=1,numPoints do
			SkillButtonNameEdit:SetPoint(buttonText:GetPoint(p))
		end
		SkillButtonNameEdit.originalButton = buttonText
		SkillButtonNameEdit.skill = button.skill
		SkillButtonNameEdit:Show()
		buttonText:Hide()
		button:UnregisterEvent("MODIFIER_STATE_CHANGED")
	end
end

function Skillet:FavoriteButton_OnClick(button, mouse)
	if (mouse=="LeftButton") then
	  if button.skill then
			Skillet:ToggleFavorite(button.skill.recipeID)
			button:SetFavorite(Skillet:IsFavorite(button.skill.recipeID))
		end
	end
end

function Skillet:FavoritesOnlyRefresh()
	if Skillet:GetTradeSkillOption("favoritesOnly") then
		SkilletFavoritesOnlyButton:LockHighlight()
	else
		SkilletFavoritesOnlyButton:UnlockHighlight()
	end
end

function Skillet:SetGroupSelection(skillName)
	self.currentGroup = skillName
	Skillet:SetTradeSkillOption("group", skillName)
end

local lastClick = 0
-- When one of the skill buttons in the left scroll pane is clicked
function Skillet:SkillButton_OnClick(button, mouse)
	if (mouse=="LeftButton") then
		Skillet:QueueManagementToggle(true)
		local doubleClicked = false
		local thisClick = GetTime()
		local delay = thisClick - lastClick
		lastClick = thisClick
		if delay < .25 then
			doubleClicked = true
		end
		if doubleClicked then
			if button.skill.subGroup then
				if button.skill.mainGroup or self.currentGroup == button.skill.name then
					Skillet:SetGroupSelection(nil)
					button.skill.subGroup.expanded = true
				else
					Skillet:SetGroupSelection(button.skill.name)
					button.skill.subGroup.expanded = true
				end
				self:SortAndFilterRecipes()
			else
				local skill = button.skill
				if skill and skill.recipeID then
					local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
					if (ChatEdit_GetLastActiveWindow():IsVisible() or WIM_EditBoxInFocus ~= nil) then
						ChatEdit_InsertLink(spellLink)
					end
				end
			end
		elseif not button.skill.mainGroup then
			if IsShiftKeyDown() and self.skillMainSelection then
				self:SkillButton_ClearSelections()
				self:SkillButton_SetSelections(self.skillMainSelection, button.rawIndex)
			else
				if not IsControlKeyDown() then
					if not button.skill.subGroup then
						if not button.skill.selected then
							self:SkillButton_ClearSelections()
						end
						self:SetSelectedSkill(button:GetID())
						button.skill.selected = true
					else
						if button.skill.selected and not self:RecipeGroupIsLocked() then
							self:SkillButton_NameEditEnable(button)
							return			-- avoid window update
						else
							self:SkillButton_ClearSelections()
							self.selectedSkill = nil
							button.skill.selected = true
						end
					end
					self.skillMainSelection = button.rawIndex
				else
					button.skill.selected = not button.skill.selected
				end
			end
		end
		self:UpdateTradeSkillWindow()
	elseif (mouse=="RightButton") then
		self:SkilletSkillMenu_Show(button)
	end
end

-- When one of the skill buttons in the left scroll pane is clicked
function Skillet:SkillExpandButton_OnClick(button, mouse, doubleClicked)
	if (mouse=="LeftButton") then
		if button.group then
			button.group.expanded = not button.group.expanded
			self:SortAndFilterRecipes()
			self:UpdateTradeSkillWindow()
		end
	end
end

-- this function assures that a recipe that is indirectly selected (via reagent clicks, for example)
-- will be visible in the skill list (ie, not scrolled off the top/bottom)
function Skillet:ScrollToSkillIndex(skillIndex)
	--DA.DEBUG(0,"ScrollToSkillIndex("..tostring(skillIndex)..")")
	if skillIndex == nil then
		return
	end
	-- scroll the skill list to make sure the new skill is revealed
	if SkilletSkillList:IsVisible() then
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		if sortedSkillList then
			local sortedIndex
			for i=1,#sortedSkillList,1 do
				if sortedSkillList[i].skillIndex == skillIndex then
					sortedIndex = i
					break
				end
			end
			sortedIndex = sortedIndex or 1
			local scrollbar = _G["SkilletSkillListScrollBar"]
			local button_count = SkilletSkillList:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
			button_count = math.floor(button_count)
			local skillOffset = FauxScrollFrame_GetOffset(SkilletSkillList)
			--DA.DEBUG(0, (skillOffset or "nil").." > "..(sortedIndex or "nil"))
			if skillOffset > sortedIndex then
				sortedIndex = sortedIndex - 1
				FauxScrollFrame_SetOffset(SkilletSkillList, sortedIndex)
				scrollbar:SetValue(sortedIndex * SKILLET_TRADE_SKILL_HEIGHT)
			elseif (skillOffset + button_count) < sortedIndex then
				sortedIndex = sortedIndex - button_count
				FauxScrollFrame_SetOffset(SkilletSkillList, sortedIndex)
				scrollbar:SetValue(sortedIndex * SKILLET_TRADE_SKILL_HEIGHT)
			end
		end
	end
	self:UpdateTradeSkillWindow()
end

-- Go to the previous recipe in the history list.
function Skillet:GoToPreviousSkill()
	local entry = table.remove(skillStack)
	if entry then
		self:SetTradeSkill(entry.player,entry.tradeID,entry.skillIndex)
	end
end

function Skillet:PushSkill(player, tradeID, skillIndex)
	local entry = { ["player"] = player, ["tradeID"] = tradeID, ["skillIndex"] = skillIndex }
	table.insert(skillStack, entry)
end

function Skillet:getLvlUpChance()
	-- icy: 03.03.2012:
	-- according to pope (http://www.wowhead.com/spell=83949#comments)
	-- % to level up with this receipt is calculated by: (greySkill - yourSkill) / (greySkill - yellowSkill
	-- Lets add this information to skillet :)
	local skilRanks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
	local currentLevel, maxLevel = 0, 0
	if skilRanks then
		currentLevel, maxLevel = skilRanks.rank, skilRanks.maxRank
	end
	local gray = tonumber(SkilletRankFrame.subRanks.green:GetValue())
	local yellow = tonumber(SkilletRankFrame.subRanks.orange:GetValue())
	--DA.DEBUG(0,"currentLevel= "..tostring(currentLevel)..", gray= "..tostring(gray)..", yellow= "..tostring(yellow))
	if (currentLevel > gray) then
		return 0
	elseif (gray - yellow) == 0 then
		return 100
	else
		local percent = ((gray - currentLevel) / ( gray - yellow )) * 100
		if percent > 100 then
			percent = 100
		end
		return percent
	end
end

-- Called when then mouse enters the rank status bar
function Skillet:RankFrame_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
	local r,g,b = SkilletSkillName:GetTextColor()
	GameTooltip:AddLine(SkilletSkillName:GetText(),r,g,b)
	local gray = SkilletRankFrame.subRanks.green:GetValue()
	local green = SkilletRankFrame.subRanks.yellow:GetValue()
	local yellow = SkilletRankFrame.subRanks.orange:GetValue()
	local orange = SkilletRankFrame.subRanks.red:GetValue()
	-- lets add the chance to level up that skill with that receipt
	local chance = Skillet:getLvlUpChance()
	GameTooltip:AddLine(COLORORANGE..orange.."|r/"..COLORYELLOW..yellow.."|r/"..COLORGREEN..green.."|r/"..COLORGRAY..gray.."|r/ Chance:"..chance.."|r%")
	GameTooltip:Show()
end

-- Called when then mouse enters the rank status bar
function Skillet:RankFrame_OnLeave(button)
	GameTooltip:Hide()
end

-- Called when then mouse enters a reagent button
function Skillet:ReagentButtonOnEnter(button, skillIndex, reagentIndex)
	--DA.DEBUG(1,"Skillet:ReagentButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
	if skill then
		local recipe = self:GetRecipe(skill.id)
		if recipe then
			local reagent = recipe.reagentData[reagentIndex]
			if reagent then
				Skillet:SetReagentToolTip(reagent.reagentID, reagent.numNeeded, skill.numCraftable or 0)
				if self.db.profile.link_craftable_reagents then
					if self.db.global.itemRecipeSource[reagent.reagentID] then
						local icon = _G[button:GetName() .. "Icon"]
						gearTexture:SetParent(icon)
						gearTexture:ClearAllPoints()
						gearTexture:SetPoint("TOPLEFT", icon)
						gearTexture:Show()
					end
				end
			else
				GameTooltip:AddLine("unknown", 1,0,0)
			end
		end
	end
	GameTooltip:Show()
	CursorUpdate(button)
end

-- called then the mouse leaves a reagent button
function Skillet:ReagentButtonOnLeave(button, skillIndex, reagentIndex)
	gearTexture:Hide()
end

function Skillet:ReagentButtonSkillSelect(player, id)
	DA.DEBUG(0,"Skillet:ReagentButtonSkillSelect("..tostring(player)..", "..tostring(id)..")")
	if player == Skillet.currentPlayer then -- Blizzard's 5.4 update prevents us from changing away from the current player
		local skillIndexLookup = Skillet.data.skillIndexLookup
		gearTexture:Hide()
		GameTooltip:Hide()
		local newRecipe = Skillet:GetRecipe(id)
		--DA.DEBUG(0,"newRecipe= "..DA.DUMP1(newRecipe))
		if newRecipe then
			Skillet:PushSkill(Skillet.currentPlayer, Skillet.currentTrade, Skillet.selectedSkill)
			Skillet:SetTradeSkill(player, newRecipe.tradeID, skillIndexLookup[id])
		end
	end
end

-- Called when the reagent button is clicked
function Skillet:ReagentButtonOnClick(button, skillIndex, reagentIndex)
	DA.DEBUG(0,"Skillet:ReagentButtonOnClick("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	if not self.db.profile.link_craftable_reagents then
		return
	end
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	local reagent = recipe.reagentData[reagentIndex]
	local newRecipeTable = self.db.global.itemRecipeSource[reagent.reagentID]
	local skillIndexLookup = self.data.skillIndexLookup
	local player = self.currentPlayer
	local myRecipeID
	local newRecipeID
	local newPlayer
	if newRecipeTable then
		local newRecipe
		local recipeCount = 0
		self.data.recipeMenuTable = {}
		if not self.recipeMenu then
			self.recipeMenu = CreateFrame("Frame", "SkilletRecipeMenu", _G["UIParent"], "UIDropDownMenuTemplate")
		end
		-- popup with selection if there is more than 1 potential recipe source for the reagent (small prismatic shards, for example)
		for id in pairs(newRecipeTable) do
			if skillIndexLookup[id] then
				recipeCount = recipeCount + 1
				newRecipe = self:GetRecipe(id)
				local skillID = skillIndexLookup[id]
				local newSkill = self:GetSkill(player, newRecipe.tradeID, skillID)
				self.data.recipeMenuTable[recipeCount] = {}
				self.data.recipeMenuTable[recipeCount].text = player .." : " .. newRecipe.name or "Unknown"
				self.data.recipeMenuTable[recipeCount].arg1 = player
				self.data.recipeMenuTable[recipeCount].arg2 = id
				self.data.recipeMenuTable[recipeCount].func = function(arg1,arg2) Skillet.ReagentButtonSkillSelect(arg1,arg2) end
				myRecipeID = id
				self.data.recipeMenuTable[recipeCount].textr = 1.0
				self.data.recipeMenuTable[recipeCount].textg = 1.0
				self.data.recipeMenuTable[recipeCount].textb = 1.0
				newPlayer = player
				newRecipeID = id
			end
		end
		--DA.DEBUG(0,"recipeMenuTable= "..DA.DUMP1(self.data.recipeMenuTable))
		if myRecipeID then
			newPlayer = player
			newRecipeID = myRecipeID
		end
		if recipeCount == 1 or myRecipeID then
			gearTexture:Hide()
			GameTooltip:Hide()
			button:Hide()	-- hide the button so that if a new button is shown in this slot, a new "OnEnter" event will fire
			newRecipe = self:GetRecipe(newRecipeID)
			self:PushSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
			self:SetTradeSkill(newPlayer, newRecipe.tradeID, skillIndexLookup[newRecipeID])
		else
			local x, y = GetCursorPosition()
			local uiScale = UIParent:GetEffectiveScale()
			EasyMenu(self.data.recipeMenuTable, self.recipeMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
		end
	end
end

function Skillet:SkilletFrameForceClose()
	if self.dataSource == "api" then
		self.dataSource = "none"
		self:HideAllWindows()
		C_TradeSkillUI.CloseTradeSkill()
		return true
	else
		local x = self:HideAllWindows()
		C_TradeSkillUI.CloseTradeSkill()
		return x
	end
end

-- The start/pause queue button.
function Skillet:StartQueue_OnClick(button,mouse)
	if self.queuecasting then
		DA.CHAT("Cancel incomplete processing")
		self:CancelCast() -- next update will reset the text
--		button:Disable()
		self.queuecasting = false
	else
		button:SetText(L["Pause"])
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
	self:UpdateQueueWindow()
end

local old_CloseSpecialWindows
-- Called when the trade skill window is shown
function Skillet:Tradeskill_OnShow()
	DA.DEBUG(0,"Tradeskill_OnShow")
	-- Need to hook this so that hitting [ESC] will close the Skillet window(s).
	if not old_CloseSpecialWindows then
		old_CloseSpecialWindows = CloseSpecialWindows
		CloseSpecialWindows = function()
			local found = old_CloseSpecialWindows()
			return self:SkilletFrameForceClose() or found
		end
	end
end

-- Called when the trade skill window is hidden
function Skillet:Tradeskill_OnHide()
end

function Skillet:InventoryFilterButton_OnClick(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	self:ToggleTradeSkillOption(option)
	self:InventoryFilterButton_OnEnter(button)
	self:InventoryFilterButton_OnShow(button)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

function Skillet:InventoryFilterButton_OnEnter(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	local value = self:GetTradeSkillOption(option)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	if value then
		GameTooltip:SetText(slot.." on")
	else
		GameTooltip:SetText(slot.." off")
	end
	GameTooltip:Show()
end

function Skillet:InventoryFilterButton_OnLeave(button)
	GameTooltip:Hide()
end

function Skillet:InventoryFilterButton_OnShow(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	local value = self:GetTradeSkillOption(option)
	if value then
		button:SetChecked(true)
	else
		button:SetChecked(false)
	end
end

function Skillet:InventoryFilterButtons_Show()
	SkilletInventoryFilterBag:Show()
	SkilletInventoryFilterCraft:Show()
	SkilletInventoryFilterVendor:Show()
	SkilletInventoryFilterAlts:Show()
	SkilletInventoryFilterOwned:Show()
end

function Skillet:InventoryFilterButtons_Hide()
	SkilletInventoryFilterBag:Hide()
	SkilletInventoryFilterCraft:Hide()
	SkilletInventoryFilterVendor:Hide()
	SkilletInventoryFilterAlts:Hide()
	SkilletInventoryFilterOwned:Hide()
end

local skillMenuSelection = {
	{
		text = L["Select All"],
		func = function() Skillet:SkillButton_SetAllSelections(true) Skillet:UpdateTradeSkillWindow() end,
	},
	{
		text = L["Select None"],
		func = function() Skillet:SkillButton_SetAllSelections(false) Skillet:UpdateTradeSkillWindow() end,
	},
}
local skillMenuGroup = {
	{
		text = L["Empty Group"],
		func = function() Skillet:SkillButton_NewGroup() end,
	},
	{
		text = L["From Selection"],
		func = function() Skillet:SkillButton_MakeGroup() end,
	},
}
local favoriteMenu = {
		text = "",
		func = function()
					local recipeID = Skillet.menuButton.skill.recipeID
					local favoriteButton = _G[Skillet.menuButton:GetName() .. "Favorite"]
					Skillet:ToggleFavorite(recipeID)
					favoriteButton:SetFavorite(Skillet:IsFavorite(recipeID))
				end,
}
local skillMenuList = {
	{
		text = L["Link Recipe"],
		func = function()
					local skill = Skillet.menuButton.skill
					if skill and skill.recipeID then
						local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
						if (ChatEdit_GetLastActiveWindow():IsVisible() or WIM_EditBoxInFocus ~= nil) then
							ChatEdit_InsertLink(spellLink)
						end
					end
				end,
	},
	{
		text = L["Add to Ignore Materials"],
		func = function()
					local skill = Skillet.menuButton.skill
					if skill and skill.recipeID then
						local recipeID = skill.recipeID
						local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
						Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeID] = spellLink
						if Skillet.ignoreList and Skillet.ignoreList:IsVisible() then
							Skillet:UpdateIgnoreListWindow()
						end
					end
				end,
	},
	favoriteMenu,
	{
		text = "",
		disabled = true,
	},
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "",
		disabled = true,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
	{
		text = L["Cut"],
		func = function() Skillet:SkillButton_CutSelected() end,
	},
	{
		text = L["Paste"],
		func = function() Skillet:SkillButton_PasteSelected(Skillet.menuButton) end,
	},
}
local skillMenuListLocked = {
	{
		text = L["Link Recipe"],
		func = function()
					local skill = Skillet.menuButton.skill
					if skill and skill.recipeID then
						local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
						if (ChatEdit_GetLastActiveWindow():IsVisible() or WIM_EditBoxInFocus ~= nil) then
							ChatEdit_InsertLink(spellLink)
						end
					end
				end,
	},
	{
		text = L["Add to Ignore Materials"],
		func = function()
					local skill = Skillet.menuButton.skill
					if skill and skill.recipeID then
						local recipeID = skill.recipeID
						local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
						Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeID] = spellLink
						if Skillet.ignoreList and Skillet.ignoreList:IsVisible() then
							Skillet:UpdateIgnoreListWindow()
						end
					end
				end,
	},
	favoriteMenu,
	{
		text = "",
		disabled = true,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}
local headerMenuList = {
	{
		text = L["Rename Group"],
		func = function() Skillet:SkillButton_NameEditEnable(Skillet.menuButton) end,
	},
	{
		text = "",
		disabled = true,
	},
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "",
		disabled = true,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
	{
		text = L["Cut"],
		func = function() Skillet:SkillButton_CutSelected() end,
	},
	{
		text = L["Paste"],
		func = function() Skillet:SkillButton_PasteSelected(Skillet.menuButton) end,
	},
}
local headerMenuListLocked = {
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}
local headerMenuListMainGroup = {
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "",
		disabled = true,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
	{
		text = L["Cut"],
		func = function() Skillet:SkillButton_CutSelected() end,
	},
	{
		text = L["Paste"],
		func = function() Skillet:SkillButton_PasteSelected(Skillet.menuButton) end,
	},
}
local headerMenuListMainGroupLocked = {
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}
local queueMenuList = {
	{
		text = L["Move to Top"],
		func = function()
					Skillet:QueueMoveToTop(Skillet.queueMenuButton:GetID())
				end,
	},
	{
		text = L["Move Up"],
		func = function()
					Skillet:QueueMoveUp(Skillet.queueMenuButton:GetID())
				end,
	},
	{
		text = L["Move Down"],
		func = function()
					Skillet:QueueMoveDown(Skillet.queueMenuButton:GetID())
				end,
	},
	{
		text = L["Move to Bottom"],
		func = function()
					Skillet:QueueMoveToBottom(Skillet.queueMenuButton:GetID())
				end,
	},
}

-- Called when the skill operators drop down is displayed
function Skillet:SkilletSkillMenu_Show(button)
	if not SkilletSkillMenu then
		SkilletSkillMenu = CreateFrame("Frame", "SkilletSkillMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	local locked = Skillet:RecipeGroupIsLocked()
	self.menuButton = button
	if button.skill.subGroup then
		if button.skill.mainGroup then
			if locked then
				EasyMenu(headerMenuListMainGroupLocked, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
			else
				EasyMenu(headerMenuListMainGroup, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
			end
		else
			if locked then
				EasyMenu(headerMenuListLocked, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
			else
				EasyMenu(headerMenuList, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
			end
		end
	else
		GameTooltip:Hide() --hide tooltip, because it may be over the menu, sometimes it still fails
		favoriteMenu["text"] = L["Set Favorite"]
		if Skillet:IsFavorite(button.skill.recipeID) then
			favoriteMenu["text"] = L["Remove Favorite"]
		end
		if locked then
			EasyMenu(skillMenuListLocked, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
		else
			EasyMenu(skillMenuList, SkilletSkillMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
		end
	end
end

function Skillet:SkilletQueueMenu_Show(button)
	if not SkilletQueueMenu then
		SkilletQueueMenu = CreateFrame("Frame", "SkilletQueueMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	self.queueMenuButton = button
	EasyMenu(queueMenuList, SkilletQueueMenu, _G["UIParent"], x/uiScale,y/uiScale, "MENU", 5)
end

function Skillet:ReAnchorButtons(newFrame)
	SkilletRecipeNotesButton:SetPoint("BOTTOMRIGHT",newFrame,"TOPRIGHT",0,0)
	SkilletQueueAllButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
	SkilletEnchantButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
	SkilletQueueButton:SetPoint("TOPRIGHT",newFrame,"BOTTOMRIGHT",0,-2)
end

function Skillet:ShowReagentDetails()
		SkilletQueueManagementParent:Hide();
		SkilletViewCraftersParent:Hide()
		SkilletReagentParent:Show()
		SkilletReagentParent:SetHeight(260)
		SkilletQueueManagementParent:SetHeight(260)
		SkilletViewCraftersParent:SetHeight(260)
		Skillet:ReAnchorButtons(SkilletReagentParent)
end

function Skillet:QueueManagementToggle(showDetails)
	if SkilletQueueManagementParent:IsVisible() or showDetails then
		Skillet:ShowReagentDetails()
	else
		SkilletQueueManagementParent:Show();
		SkilletQueueManagementParent:SetHeight(100)
		SkilletViewCraftersParent:Hide()
		SkilletViewCraftersParent:SetHeight(100)
		SkilletReagentParent:Hide()
		SkilletReagentParent:SetHeight(100)
		Skillet:ReAnchorButtons(SkilletQueueManagementParent)
	end
end

function Skillet:ViewCraftersClicked()
	if SkilletViewCraftersParent:IsVisible() then
		Skillet:ShowReagentDetails()
	else
		self.queriedSkill = self.selectedSkill
		SelectTradeSkill(self.selectedSkill);
		QueryGuildMembersForRecipe();
	end
end

function Skillet:SkilletShowGuildCrafters()
	if ( self.queriedSkill == self.selectedSkill ) then
		Skillet:ShowViewCrafters()
	end
end

function Skillet:ShowViewCrafters()
		SkilletQueueManagementParent:SetHeight(260)
		SkilletQueueManagementParent:Hide();
		SkilletViewCraftersParent:SetHeight(260)
		SkilletViewCraftersParent:Show()
		SkilletReagentParent:SetHeight(260)
		SkilletReagentParent:Hide()
		Skillet:ReAnchorButtons(SkilletViewCraftersParent)
		SkilletViewCraftersScrollFrameScrollBar:SetValue(0);
		Skillet.ViewCraftersUpdate()
end

function Skillet:ViewCraftersToggle(showDetails)
	if SkilletViewCraftersParent:IsVisible() or showDetails then
		Skillet:ShowReagentDetails()
	else
		Skillet:ShowViewCrafters()
	end
end

function Skillet.ViewCraftersUpdate()
	local skillLineID, recipeID, numMembers = GetGuildRecipeInfoPostQuery();
	local offset = FauxScrollFrame_GetOffset(SkilletViewCraftersScrollFrame);
	local index, button, name, online;
	local SKILLET_CRAFTERS_DISPLAYED = 15
	--DA.DEBUG(0, "Skillet.ViewCraftersUpdate "..numMembers.." - "..offset)
	for i = 1, SKILLET_CRAFTERS_DISPLAYED, 1 do
		index = i + offset;
		button = _G["SkilletGuildCrafter"..i];
		if ( index > numMembers ) then
			button:Hide();
		else
			name, online = GetGuildRecipeMember(index);
			button:SetText(name);
			if ( online ) then
				button:Enable();
			else
				button:Disable();
			end
			button:Show();
			button.name = name;
		end
	end
	FauxScrollFrame_Update(SkilletViewCraftersScrollFrame, numMembers, SKILLET_CRAFTERS_DISPLAYED, TRADE_SKILL_HEIGHT);
end

Skillet.fullView = true
function Skillet:ShowFullView()
	Skillet.fullView = true
	SkilletQueueParentBase:SetParent(SkilletFrame)
	SkilletQueueParentBase:SetPoint("TOPLEFT",SkilletCreateAllButton,"BOTTOMLEFT",0,-3)
	SkilletQueueParentBase:SetPoint("BOTTOMRIGHT",SkilletFrame,"BOTTOMRIGHT",-10,32)
	SkilletStandalonQueue:Hide()
	SkilletQueueOnlyButton:SetText(">")
	Skillet:UpdateQueueWindow()
end

function Skillet:ShowQueueView()
	Skillet.fullView = false
	SkilletQueueParentBase:SetParent(SkilletStandalonQueue)
	SkilletQueueParentBase:SetPoint("TOPLEFT",SkilletStandalonQueue,"TOPLEFT",5,-32)
	SkilletQueueParentBase:SetPoint("BOTTOMRIGHT",SkilletStandalonQueue,"BOTTOMRIGHT",-5,30)
	SkilletStandalonQueue:Show()
	SkilletQueueOnlyButton:SetText("<")
	Skillet:UpdateQueueWindow()
end

function Skillet:QueueOnlyViewToggle()
	Skillet.fullView = not Skillet.fullView
	if Skillet.fullView then
		Skillet:ShowFullView()
		SkilletFrame:Show()
	else
		Skillet:ShowQueueView()
		SkilletFrame:Hide()
	end
end

function Skillet:StandaloneQueueClose()
	Skillet:ShowFullView()
	Skillet:SkilletFrameForceClose()
end

function Skillet:HideStandaloneQueue()
	if not self.skilletStandalonQueue or not self.skilletStandalonQueue:IsVisible() then
		return
	end
	SkilletStandalonQueue:Hide()
end

-- Creates and sets up the shopping list window
function Skillet:CreateStandaloneQueueFrame()
	local frame = SkilletStandalonQueue
	if not frame then
		return nil
	end
	frame:SetBackdrop(FrameBackdrop);
	frame:SetBackdropColor(0.1, 0.1, 0.1)
	-- A title bar stolen from the Ace2 Waterfall window.
	local r,g,b = 0, 0.7, 0; -- dark green
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")
	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)
	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)
	titlebar:SetGradientAlpha("VERTICAL",r*0.6,g*0.6,b*0.6,1,r,g,b,1)
	titlebar:SetTexture(r,g,b,1)
	titlebar2:SetGradientAlpha("VERTICAL",r*0.9,g*0.9,b*0.9,1,r*0.6,g*0.6,b*0.6,1)
	titlebar2:SetTexture(r,g,b,1)
	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)
	local titletext = title:CreateFontString("SkilletStandalonQueueTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: " .. L["Queue"])
	-- The frame enclosing the scroll list needs a border and a background .....
	local backdrop = SkilletShoppingListParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	-- Ace Window manager library, allows the window position (and size)
	-- to be automatically saved
	local windowManger = LibStub("LibWindow-1.1")
	local standaloneQueueLocation = {
		prefix = "standaloneQueueLocation_"
	}
	windowManger.RegisterConfig(frame, self.db.profile, standaloneQueueLocation)
	windowManger.RestorePosition(frame)  -- restores scale also
	windowManger.MakeDraggable(frame)
	-- lets play the resize me game!
	Skillet:EnableResize(frame, 320, 165, Skillet.UpdateStandaloneQueueWindow)
	-- so hitting [ESC] will close the window
	--tinsert(UISpecialFrames, frame:GetName())
	return frame
end

function Skillet:UpdateStandaloneQueueWindow()
	if not self.skilletStandalonQueue or not self.skilletStandalonQueue:IsVisible() then
		return
	end
	SkilletStandalonQueue:SetAlpha(self.db.profile.transparency)
	SkilletStandalonQueue:SetScale(self.db.profile.scale)
end

-- Add Auctionator support
function Skillet:AuctionatorSearch()
	if not AuctionatorLoaded or not AuctionFrame then
		return
	end
	if not AuctionFrame:IsShown() then
		Atr_Error_Display (ZT("When the Auction House is open\nclicking this button tells Auctionator\nto scan for the item and all its reagents."))
		return
	end
	local recipe, recipeId = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if not recipe then
		return
	end
	local BUY_TAB = 3;
	Atr_SelectPane (BUY_TAB);
	local numReagents = #recipe.reagentData
	local shoppingListName = GetItemInfo(recipe.itemID)
	if (shoppingListName == nil) then
		shoppingListName = self:GetRecipeName(recipeId)
	end
	local reagentIndex
	local items = {}
	if (shoppingListName) then
		table.insert (items, shoppingListName)
	end
	for reagentIndex = 1, numReagents do
		local reagentId = recipe.reagentData[reagentIndex].reagentID
		if (reagentId and (reagentId ~= 3371)) then
			local reagentName = GetItemInfo(reagentId)
			if (reagentName) then
				table.insert (items, reagentName)
				-- DA.DEBUG(0, "Reagent num "..reagentIndex.." ("..reagentId..") "..reagentName.." added")
			end
		end
	end
	Atr_SearchAH (shoppingListName, items)
end

function Skillet:ReagentStarsFrame_OnMouseEnter(starsFrame)
	GameTooltip:SetOwner(starsFrame, "ANCHOR_TOPLEFT");
	GameTooltip:SetRecipeRankInfo(self.currentRecipeInfo.recipeID, self.currentRecipeInfo.learnedUpgrade);
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

function Skillet.InitializeDropdown(self, level)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.text = L["Reset"]
		info.notCheckable = true
		info.func = function()
			TradeSkillFrame_SetAllSourcesFiltered(true)
			Skillet:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
			UIDropDownMenu_RefreshAll(SkilletFilterDropDown, 3)
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
		UIDropDownMenu_AddButton(info, level)

		info.text = TRADESKILL_FILTER_CATEGORY
		info.value = 2
		UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 3
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
				TradeSkillFrame_SetAllSourcesFiltered(false)
				UIDropDownMenu_Refresh(SkilletFilterDropDown, 3, 2)
				Skillet.dataScanned = false
				Skillet:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				TradeSkillFrame_SetAllSourcesFiltered(true)
				UIDropDownMenu_Refresh(SkilletFilterDropDown, 3, 2)
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
