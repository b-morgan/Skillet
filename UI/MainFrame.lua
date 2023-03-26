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

local COLORORANGE = "|cffff8040"
local COLORYELLOW = "|cffffff00"
local COLORGREEN =  "|cff40c040"
local COLORGRAY =   "|cff808080"
local COLORRED =    "|cffff0000"
local COLORWHITE =  "|cffffffff"
--
-- Colors used in the "0/0/0" strings and tooltips
--
local CGREY = "|cffb0b0b0"		-- Grey = "[", "/", "]"
local COWNED = "|cff95fcff"		-- Blue = How many you have in your inventory
local CBANK = "|cff95fcff"		-- Blue = How many you have in your bank
local CBAG = "|cff80ff80"		-- Green = How many you can make from materials you have
local CCRAFT =  "|cffffff80"	-- Yellow = How many you can make by crafting the reagents
local CVENDOR = "|cffffa050"	-- Orange = How many you can make if you purchase materials from a vendor
local CALTS = "|cffff80ff"		-- Purple = How many you can make using materials on your alts

-- min height for Skillet window
local SKILLET_MIN_HEIGHT = 580
--
-- height of the header portion
--
-- this value reflects the offsets of 
-- SkilletSkillListParent and SkilletReagentParent
--   (Y offset is either 110 or 130)
--   (we really should compute this from those values)
--
local SKILLET_HEADER_HEIGHT = 145		-- 125 if Filter is removed under Search

-- min width for skill list window
local SKILLET_SKILLLIST_MIN_WIDTH = 440

-- min/max width for the reagent window
local SKILLET_REAGENT_MIN_WIDTH = 350
local SKILLET_REAGENT_MAX_WIDTH = 400
local SKILLET_REAGENT_MIN_HEIGHT = 300
local reagent_height

-- min width of count text
local SKILLET_COUNT_MIN_WIDTH = 100

local nonLinkingTrade = { [2656] = true, [53428] = true , [193290] = true }				-- smelting, runeforging, herbalism

--
-- Stack of previsouly selected skills for use by the
-- "click on reagent, go to recipe" code and for clicking on Queue'd recipes
-- stack is stack of tables: { "player", "tradeID", "skillIndex"}
--
Skillet.skillStack = {}

--
-- Stolen from the Waterfall Ace2 addon.
--
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
local TSMBackdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	tile = true, tileSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

--
-- List of functions that are called before a button is shown
--
local pre_show_callbacks = {}

--
-- List of functions that are called before a button is hidden
--
local pre_hide_callbacks = {}

function Skillet:AddPreButtonShowCallback(method)
	assert(method and type(method) == "function",
		   "Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
	table.insert(pre_show_callbacks, method)
end

function Skillet:AddPreButtonHideCallback(method)
	assert(method and type(method) == "function",
		   "Usage: Skillet:AddPreButtonHideCallback(method). method must be a non-nil function")
	table.insert(pre_hide_callbacks, method)
end

--
-- Figures out how to display the craftable counts for a recipe.
-- Returns: num, num_with_vendor, num_with_alts
--
local function get_craftable_counts(skill, numMade)
	--DA.DEBUG(2,"get_craftable_counts: name= "..tostring(skill.name)..", numMade= "..tostring(numMade))
	--DA.DEBUG(3,"get_craftable_counts: skill= "..DA.DUMP1(skill,1))
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
--
-- The SkilletFrame is defined in the file MainFrame.xml
--
	local frame = SkilletFrame
	if not frame then
		return frame
	end
	--DA.DEBUG(0,"CreateTradeSkillWindow: oldWidth= "..tostring(frame:GetWidth())..", oldHeight= "..tostring(frame:GetHeight()))
	if frame:GetWidth() < 710 then
		frame:SetWidth(710)		-- Reset the window size to the new minimum
	end
	if frame:GetHeight() < 545 then
		frame:SetHeight(545)
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	if TSM_API and Skillet.db.profile.tsm_compat then
		frame:SetFrameStrata("HIGH")
		frame:SetBackdrop(TSMBackdrop)
	else
		frame:SetBackdrop(FrameBackdrop)
	end
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
	titlebar:SetGradient("VERTICAL", CreateColor(r*0.6,g*0.6,b*0.6,1), CreateColor(r,g,b,1))
	titlebar:SetColorTexture(r,g,b,1)
	titlebar2:SetGradient("VERTICAL", CreateColor(r*0.9,g*0.9,b*0.9,1), CreateColor(r*0.6,g*0.6,b*0.6,1))
	titlebar2:SetColorTexture(r,g,b,1)

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
	SkilletPluginButton:Hide()
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
--
-- Always want these visible.
--
	SkilletItemCountInputBox:SetText("1");
--
-- Progression status bar
--
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
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = SkilletSkillListParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
--
-- Frame enclosing the reagent list
--
	backdrop = SkilletReagentParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
--
-- Frame enclosing the queue
--
	backdrop = SkilletQueueParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
--
-- Frame enclosing the pop out notes panel
--
	backdrop = SkilletRecipeNotesFrame
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropColor(0.1, 0.1, 0.1)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetResizable(true)
	backdrop:Hide() -- initially hidden
	backdrop = SkilletQueueManagementParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	self.gearTexture = SkilletReagentParent:CreateTexture(nil, "OVERLAY")
	self.gearTexture:SetTexture("Interface\\Icons\\Trade_Engineering")
	self.gearTexture:SetHeight(16)
	self.gearTexture:SetWidth(16)
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local tradeSkillLocation = {
		prefix = "tradeSkillLocation_"
	}
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, tradeSkillLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- Lets play the resize me game!
--
	local minwidth = SKILLET_SKILLLIST_MIN_WIDTH
	minwidth = minwidth +                  -- minwidth of scroll button
			   20 +                        -- padding between sroll and detail
			   SKILLET_REAGENT_MIN_WIDTH + -- reagent window (fixed width)
			   10                          -- padding about window borders
	self:EnableResize(frame, minwidth, SKILLET_MIN_HEIGHT, Skillet.UpdateTradeSkillWindow)
--
-- Set up the sorting methods here
--
	self:InitializeSorting()
	self:ConfigureRecipeControls(false)				-- initial setting
	self.skilletStandaloneQueue=Skillet:CreateStandaloneQueueFrame()
	self.fullView = true
	self.saved_full_button_count = 0
	self.saved_SA_button_count = 0
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

--
-- Resets all the sorting and filtering info for the window
-- This is called when the window has changed enough that
-- sorting or filtering may need to be updated.
--
function Skillet:ResetTradeSkillWindow()
	--DA.DEBUG(0,"ResetTradeSkillWindow()")
	Skillet:SortDropdown_OnShow()
	local buttons = SkilletFrame.added_buttons
	if buttons then
		local last_button = SkilletPluginButton
		for i=1, #buttons, 1 do
			local button = buttons[i]
			if button then
				button:ClearAllPoints()
				button:SetParent(SkilletFrame)
				button:SetPoint("TOPLEFT", last_button, "BOTTOMLEFT", 0, -1)
				button:Hide()
				button:SetAlpha(0)
				button:SetFrameLevel(0)
				last_button = button
			end
		end
	 end
end

--
-- Something has changed in the tradeskills, and the window needs to be updated
--
function Skillet:TradeSkillRank_Updated()
	--DA.DEBUG(0,"TradeSkillRank_Updated()")
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
	--DA.DEBUG(0,"TradeSkillRank_Updated over")
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

--
-- Called when the list of skills is scrolled
--
function Skillet:SkillList_OnScroll()
	Skillet:UpdateTradeSkillWindow()
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

--
-- Shows a recipe button (in the scrolling list) after doing the
-- required callbacks.
--
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

--
-- Hides a recipe button (in the scrolling list) after doing the
-- required callbacks.
--
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

--
-- Hide UI components that cannot be used for crafts and show that
-- that are only applicable to trade skills, as needed
--
function Skillet:ConfigureRecipeControls(enchant)
	--DA.DEBUG(0,"ConfigureRecipeControls("..tostring(enchant)..")")
	if enchant then
		SkilletQueueAllButton:Hide()
		SkilletQueueButton:Hide()
		SkilletCreateAllButton:Hide()
		SkilletCreateButton:Hide()
		SkilletQueueParent:Hide()
		SkilletStartQueueButton:Hide()
		SkilletEmptyQueueButton:Hide()
		SkilletItemCountInputBox:Hide()
		SkilletSub10Button:Hide()
		SkilletSub1Button:Hide()
		SkilletAdd1Button:Hide()
		SkilletAdd10Button:Hide()
		SkilletClearNumButton:Hide()
		SkilletQueueOnlyButton:Hide()
		SkilletEnchantButton:Show();
	else
		SkilletQueueAllButton:Show()
		SkilletQueueButton:Show()
		SkilletCreateAllButton:Show()
		SkilletCreateButton:Show()
		SkilletQueueParent:Show()
		SkilletStartQueueButton:Show()
		SkilletEmptyQueueButton:Show()
		SkilletItemCountInputBox:Show()
		SkilletSub10Button:Show()
		SkilletSub1Button:Show()
		SkilletAdd1Button:Show()
		SkilletAdd10Button:Show()
		SkilletClearNumButton:Show()
		SkilletQueueOnlyButton:Show()
		SkilletEnchantButton:Hide()
	end
	self:InitRecipeFilterButtons()
	if self.currentPlayer ~= (UnitName("player")) then
--
-- Disable processing because this is not the current player
--
		SkilletStartQueueButton:Disable()
		SkilletCreateAllButton:Disable()
		SkilletCreateButton:Disable()
	else
		SkilletStartQueueButton:Enable()
		SkilletCreateAllButton:Enable()
		SkilletCreateButton:Enable()
	end
end

function Skillet:RecipeDifficultyButton_OnShow()
	local level = self:GetTradeSkillOption("filterLevel")
	local v = 1-level/4
	SkilletRecipeDifficultyButtonTexture:SetTexCoord(0,1,v,v+.25)
end

function Skillet:TradeButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local bName = button:GetName()
	local _, player, tradeID = string.split("-", bName)
	local sInfo = GetSpellInfo(tradeID)
	--DA.DEBUG(3,"TradeButton_OnEnter("..tostring(bName).."), player= "..tostring(player)..", tradeID= "..tostring(tradeID)..", sInfo= "..tostring(sInfo))
	GameTooltip:AddLine(sInfo)
	tradeID = tonumber(tradeID)
	local data
	data = self:GetSkillRanks(player, tradeID)
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
	--DA.DEBUG(0,"TradeButtonAdditional_OnEnter: button= "..DA.DUMP1(button))
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local spellID = button:GetID()
	local spellInfo, _ = GetSpellInfo(spellID)
	if button.Toy then
		_, spellInfo = C_ToyBox.GetToyInfo(spellID)
	end
	--DA.DEBUG(1,"TradeButtonAdditional_OnEnter: spellInfo= "..tostring(spellInfo))
	GameTooltip:AddLine(spellInfo)
	if not button.Toy then
		local itemID = Skillet:GetAutoTargetItem(self.currentTrade, spellID)
		if itemID and IsAltKeyDown() then
			GameTooltip:AddLine("/use "..GetItemInfo(itemID))
		end
	end
--[[
	local type0 = button:GetAttribute("type")
	local type1 = button:GetAttribute("type1")
	local spell = button:GetAttribute("spell")
	local spell1 = button:GetAttribute("spell1")
	local macrotext = button:GetAttribute("macrotext")
	DA.DEBUG(1,"TradeButtonAdditional_OnEnter: type= "..tostring(type0)..", spell= "..tostring(spell))
	DA.DEBUG(1,"TradeButtonAdditional_OnEnter: type1= "..tostring(type1)..", spell1= "..tostring(spell1))
	DA.DEBUG(1,"TradeButtonAdditional_OnEnter: macrotext= "..tostring(macrotext))
	GameTooltip:AddLine("type= "..tostring(type0))
	GameTooltip:AddLine("spell= "..tostring(spell))
	GameTooltip:AddLine("type1= "..tostring(type1))
	GameTooltip:AddLine("spell1= "..tostring(spell1))
	GameTooltip:AddLine("macrotext= "..tostring(macrotext))
--]]
	GameTooltip:Show()
end

function Skillet:BlizzardUIButton_OnEnter(button)
	--DA.DEBUG(0,"BlizzardUIButton_OnEnter("..tostring(button)..")")
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Toggle Blizzard UI")
	GameTooltip:Show()
end

function Skillet:TradeButton_OnClick(this,button)
	--DA.DEBUG(0,"TradeButton_OnClick("..DA.DUMP1(this)..", "..tostring(button)..")")
	local name = this:GetName()
	local _, player, tradeID = string.split("-", name)
	tradeID = tonumber(tradeID)
	local data =  self:GetSkillRanks(player, tradeID)
	--DA.DEBUG(0,"TradeButton_OnClick "..(name or "nil").." "..(player or "nil").." "..(tradeID or "nil"))
	if button == "LeftButton" then
		if player == UnitName("player") or (data and data ~= nil) then
			if self.currentTrade == tradeID and IsShiftKeyDown() then
				local link = C_TradeSkillUI.GetTradeSkillListLink()
				if not ChatEdit_InsertLink(link) then
					DA.DEBUG(0,"TradeButton_OnClick: link= "..DA.PLINK(link))
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
			end
			Skillet:UpdateTradeSkillWindow()
		end
	end
	GameTooltip:Hide()
end

--
-- A SecureActionButtonTemplate button can't override the OnClick so 
-- this function will never be called.
--
function Skillet:TradeButtonAdditional_OnClick(this,button)
	--DA.DEBUG(0,"TradeButtonAdditional_OnClick("..DA.DUMP1(this)..", "..tostring(button)..")")
	local name = this:GetName()
	--DA.DEBUG(0,"TradeButtonAdditional_OnClick: name= "..tostring(name))
	GameTooltip:Hide()
end

function Skillet:BlizzardUIButton_OnClick(this,button)
	--DA.DEBUG(0,"BlizzardUIButton_OnClick")
	GameTooltip:Hide()
	if Skillet.BlizzardUIshowing then
		HideUIPanel(ProfessionsFrame)
		Skillet.BlizzardUIshowing = false
	else
		ShowUIPanel(ProfessionsFrame)
		Skillet.BlizzardUIshowing = true
		ProfessionsFrame.CloseButton:HookScript("OnClick",function(...) Skillet.BlizzardUIshowing = false end)
		ProfessionsFrame:Refresh()
		if SkilletFrame.selectedSkill and SkilletFrame.selectedSkill ~= -1 then
			Skillet:SetSelectedSkill(SkilletFrame.selectedSkill)
		end
	end
end

function Skillet:CreateAdditionalButtonsList()
	--DA.DEBUG(0,"CreateAdditionalButtonsList()")
	Skillet.AdditionalButtonsList = {}
	local seenButtons = {}
	local tradeSkillList = self.tradeSkillList
	for i=1,#tradeSkillList,1 do
		local tradeID = tradeSkillList[i]
		local ranks = self:GetSkillRanks(Skillet.currentPlayer, tradeID)
		if ranks then	-- this player knows this skill
			local additionalSpellTab = Skillet.TradeSkillAdditionalAbilities[tradeID]
			if additionalSpellTab then -- this skill has additional abilities
				if type(additionalSpellTab[1]) == "table" then
					for j=1,#additionalSpellTab,1 do
						--DA.DEBUG(1,"CreateAdditionalButtonsList: tradeID= "..tostring(tradeID)..", additionalSpellTab["..tostring(j).."]= "..DA.DUMP1(additionalSpellTab[j]))
						local spellID = additionalSpellTab[j][1]
						if not seenButtons[spellID] then
							if additionalSpellTab[j][5] then
								local name = GetSpellInfo(spellID)	-- always returns data
								local name = GetSpellInfo(name)		-- only returns data if you have this spell in your spellbook
								--DA.DEBUG(1,"CreateAdditionalButtonsList: name= "..tostring(name))
								if name then
									table.insert(Skillet.AdditionalButtonsList, additionalSpellTab[j])
								end
							else
								table.insert(Skillet.AdditionalButtonsList, additionalSpellTab[j])
							end
							seenButtons[spellID] = true
						end
					end
				else
					local spellID = additionalSpellTab[1]
					if not seenButtons[spellID] then
						--DA.DEBUG(1,"CreateAdditionalButtonsList: tradeID= "..tostring(tradeID)..", additionalSpellTab= "..DA.DUMP1(additionalSpellTab))
						table.insert(Skillet.AdditionalButtonsList, additionalSpellTab)
						seenButtons[spellID] = true
					end
				end
			end		-- additionalSpellTab
		end		-- ranks
	end		-- for
	--DA.DEBUG(0,"CreateAdditionalButtonsList: AdditionalButtonsList= "..DA.DUMP(Skillet.AdditionalButtonsList))
end

function Skillet:UpdateTradeButtons(player)
	--DA.DEBUG(0,"UpdateTradeButtons("..tostring(player)..")")
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
				--DA.DEBUG(1,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
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
	end -- for
--
-- Add some space
--
	position = position + 10
--
-- Create list of additional skills (if it doesn't exist)
--
	if not Skillet.AdditionalButtonsList then
		self:CreateAdditionalButtonsList()
	end
--
-- Iterate thru the list of additional skills and add buttons for each one
--
-- Each entry is {spellID, "Name", isToy, isPet, isKnown}
--   isToy is true if the spellID is a toyID instead
--   isPet is true if the name is a pet
--   isKnown is true if the spellID must be known by the player.
--
	--DA.DEBUG(1,"UpdateTradeButtons: doing "..tostring(#Skillet.AdditionalButtonsList).." AdditionalButtonsList entries")
	for i=1,#Skillet.AdditionalButtonsList,1 do
		local additionalSpellTab = Skillet.AdditionalButtonsList[i]
		local additionalSpellId = additionalSpellTab[1]
		local additionalSpellName = additionalSpellTab[2]
		local additionalToy = additionalSpellTab[3]
		local additionalPet = additionalSpellTab[4]
		local spellName, _, spellIcon, petGUID
		if additionalToy then
			if (PlayerHasToy(additionalSpellId) and C_ToyBox.IsToyUsable(additionalSpellId)) then
				_, spellName, spellIcon = C_ToyBox.GetToyInfo(additionalSpellId)
			else
				spellName = nil
			end
		else
			spellName, _, spellIcon = GetSpellInfo(additionalSpellId)
		end
		if additionalPet then
			_, petGUID = C_PetJournal.FindPetIDByName(additionalSpellName)
			if petGUID then
				spellName = additionalSpellName
			else
				spellName = nil
			end
		end
		if spellName then
			--DA.DEBUG(1,"UpdateTradeButtons: i= "..tostring(i)..", additionalSpellId= "..tostring(additionalSpellId)..", spellName= "..tostring(spellName)..", spellIcon= "..tostring(spellIcon))
			local buttonName = "SkilletDo"..additionalSpellName
			local button = _G[buttonName]
			if not button then
				--DA.DEBUG(0,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
				button = CreateFrame("Button", buttonName, frame, "SkilletTradeButtonAdditionalTemplate")
				button:SetID(additionalSpellId)
				if additionalToy then
					button.Toy = true
				end
				if additionalPet then
					button.Pet = true
					button.PetGUID = petGUID
				end
			end
--
-- https://wowpedia.fandom.com/wiki/SecureActionButtonTemplate 
--
--[[
--
-- pure spell on left-click
--
			local spellName, _, texture = GetSpellInfo(additionalSpellId)
			DA.DEBUG(1,"UpdateTradeButtons: additionalSpellId= "..tostring(additionalSpellId)..", spellName= "..tostring(spellName))
			button:SetAttribute("type1", "spell")
			button:SetAttribute("spell1", spellName)
--]]
--
-- execute a macro on any click
--
			button:SetAttribute("type", "macro");
			local macrotext = Skillet:GetAutoTargetMacro(additionalSpellId, button.Toy, button.Pet, petGUID)
			--DA.DEBUG(1,"UpdateTradeButtons: macrotext= "..tostring(macrotext))
			button:SetAttribute("macrotext", macrotext)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
			local buttonIcon = _G[buttonName.."Icon"]
			buttonIcon:SetTexture(spellIcon)
			position = position + button:GetWidth()
			button:Show()
			if additionalToy then
				local isToyUsable = C_ToyBox.IsToyUsable(additionalSpellId)
				--DA.DEBUG(1,"UpdateTradeButtons: IsToyUsable("..tostring(additionalSpellId)..")= "..tostring(isToyUsable))
				if isToyUsable then
					button:Enable()
					button:SetAlpha(1.0)
				else
					button:Disable()
					button:SetAlpha(0.2)
				end
			end
			if additionalPet then
				--DA.DEBUG(1,"UpdateTradeButtons: petName= "..tostring(additionalSpellName)..", petGUID= "..tostring(petGUID))
				if petGUID then
					button:Enable()
					button:SetAlpha(1.0)
				else
					button:Disable()
					button:SetAlpha(0.2)
				end
			end
		end
	end
--
-- One more button to toggle the Blizzard TradeSkillFrame
--
--	if Skillet.db.profile.use_blizzard_for_optional then
		position = position + 10	-- Add some space
		local buttonName = "SkilletBlizzardUI"
		local button = _G[buttonName]
		if not button then
			--DA.DEBUG(0,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
			button = CreateFrame("Button", buttonName, frame, "SkilletBlizzardUITemplate")
			button:SetID(2)
		end
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
		local buttonIcon = _G[buttonName.."Icon"]
		buttonIcon:SetTexture(3573824)
		position = position + button:GetWidth()
		button:Show()
--	end
end

function Skillet.PluginDropdown_OnClick(this)
	--DA.DEBUG(0,"PluginDropdown_OnClick()")
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
	--DA.DEBUG(0,"PluginButton_OnClick()")
	if SkilletFrame.added_buttons then
		for i=1,#SkilletFrame.added_buttons do
			local oldButton = SkilletFrame.added_buttons[i]
			local buttonName = "SkilletPluginDropdown"..i
			local button = _G[buttonName]
			if not button then
				button = CreateFrame("button", buttonName, SkilletPluginButton, "UIPanelButtonTemplate")
				button:Hide()
			end
			--DA.DEBUG(1,"PluginButton_OnClick: "..buttonName)
			button:SetText(oldButton:GetText())
			button:SetWidth(100)
			button:SetHeight(22)
			button:SetFrameLevel(SkilletFrame:GetFrameLevel()+10)
			button:SetScript("OnClick", Skillet.PluginDropdown_OnClick)
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

function Skillet:ShowReagentDetails()
	--DA.DEBUG(0,"ShowReagentDetails()")
	SkilletQueueManagementParent:Hide();
	SkilletReagentParent:Show()
	SkilletReagentParent:SetHeight(reagent_height)
	Skillet:ReAnchorButtons(SkilletReagentParent)
end

--
-- Updates the trade skill window whenever anything has changed,
-- number of skills, skill type, skill level, etc
--
function Skillet:UpdateTradeSkillWindow()
	--DA.DEBUG(0,"UpdateTradeSkillWindow()")
--[[
	if self.InProgress.main then 
		self.InProgress.mainDepth = self.InProgress.mainDepth + 1
		self.InProgress.mainMax = max(self.InProgress.mainMax,self.InProgress.mainDepth)
--		return
	else
		self.InProgress.mainDepth = 1
		self.InProgress.mainMax = 1
	end
--]]
	self.InProgress.main = true
	self:NameEditSave()
	if not self.currentPlayer or not self.currentTrade then 
		--DA.DEBUG(0,"UpdateTradeSkillWindow: leaving early, no player or no trade")
		return
	end
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
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
	if self.data.sortedSkillList[skillListKey] then
		numTradeSkills = self.data.sortedSkillList[skillListKey].count
	else
		numTradeSkills = 0
	end
	self:UpdateDetailWindow(self.selectedSkill)
	self:UpdateTradeButtons(self.currentPlayer)
	self:UpdateIgnoredMatsButton()
	SkilletIgnoredMatsButton:Show()
--
-- Plugin button only shows if any plugins have registered
--
	if SkilletPluginButton and SkilletFrame.added_buttons and #SkilletFrame.added_buttons > 0 then
		SkilletPluginButton:Show()
	else
		SkilletPluginButton:Hide()
	end
--
-- If any plugins have registered an Update function, call it now
--
	self:UpdatePlugins()
--
-- shopping list button always shown
--
	SkilletShoppingListButton:Show()
	SkilletFrame:SetAlpha(self.db.profile.transparency)
	SkilletFrame:SetScale(self.db.profile.scale)
	local uiScale = SkilletFrame:GetEffectiveScale()
	local width = SkilletFrame:GetWidth() - 20 -- for padding.
	local height = SkilletFrame:GetHeight()
	local reagent_width = width / 2
	reagent_height = SKILLET_REAGENT_MIN_HEIGHT + ((height - SKILLET_MIN_HEIGHT) * 2) / 3
	--DA.DEBUG(0,"UpdateTradeSkillWindow: fullView="..tostring(self.fullView)..", reagent_height="..string.format("%.0d", reagent_height))
	if not self.fullView then
		reagent_height = SKILLET_REAGENT_MIN_HEIGHT + height - SKILLET_MIN_HEIGHT + 85
		--DA.DEBUG(0,"UpdateTradeSkillWindow: new_reagent_height="..string.format("%.0d", reagent_height))
	end
	if reagent_width < SKILLET_REAGENT_MIN_WIDTH then
		reagent_width = SKILLET_REAGENT_MIN_WIDTH
	elseif reagent_width > SKILLET_REAGENT_MAX_WIDTH then
		reagent_width = SKILLET_REAGENT_MAX_WIDTH
	end
	SkilletReagentParent:SetWidth(reagent_width)
	SkilletReagentParent:SetHeight(reagent_height)
	SkilletQueueManagementParent:SetWidth(reagent_width)
	width = SkilletFrame:GetWidth() - reagent_width - 20 -- padding
	SkilletSkillListParent:SetWidth(width)
	--DA.DEBUG(0,"UpdateTradeSkillWindow: width= "..string.format("%.0d", width)..", height= "..string.format("%.0d", height)..", reagent_width= "..string.format("%.0d", reagent_width)..", reagent_height= "..string.format("%.0d", reagent_height))
--
-- Set the state of any craft specific options
--
	self:RecipeDifficultyButton_OnShow()
	SkilletUseHighestQuality:SetChecked(self.db.char.best_quality)
	SkilletUseHighestQuality:Show()
	SkilletHideUncraftableRecipes:SetChecked(self:GetTradeSkillOption("hideuncraftable"))
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(self:GetTradeSkillOption("hideuncraftable"))
	self:UpdateQueueWindow()
	self:UpdateShoppingListWindow()
	self:FavoritesOnlyRefresh()
--
-- Window Title
--
	local tradeName = self:GetTradeName(self.currentTrade)
	if not tradeName then tradeName = "" end
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
--
-- Progression status bar
--
	SkilletRankFrame:SetMinMaxValues(0, maxRank)
	SkilletRankFrame:SetValue(rank)
	SkilletRankFrameSkillRank:SetText(tradeName.."    "..rank.."/"..maxRank)
	SkilletRankFrame.subRanks.gray:SetValue(maxRank)
	for c,s in pairs(SkilletRankFrame.subRanks) do
		s:SetMinMaxValues(0, maxRank)
	end
--
-- it seems the resize for the main skillet window happens before the resize for the skill list box
--
	local button_count = (SkilletFrame:GetHeight() - SKILLET_HEADER_HEIGHT) / SKILLET_TRADE_SKILL_HEIGHT
	button_count = math.floor(button_count)
	self.button_count = button_count
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(SkilletSkillList,				-- frame
							numTradeSkills,					-- num items
							button_count,					-- num to display
							SKILLET_TRADE_SKILL_HEIGHT)		-- value step (item height)
--
-- Where in the list of skill to start counting.
--
	local skillOffset = FauxScrollFrame_GetOffset(SkilletSkillList);
--
-- Remove any selected highlight, it will be added back as needed
--
	SkilletHighlightFrame:Hide();
	local nilFound = false
	width = SkilletSkillListParent:GetWidth() - 10
	if SkilletSkillList:IsVisible() then
--
-- Adjust for the width of the scroll bar, if it is visible.
--
		width = width - 20
	end
	local text, color, skillIndex
	local pretext, preid, prelink
	local max_text_width = width
	local showOwned = self:GetTradeSkillOption("filterInventory-owned") -- count from Altoholic
	local showBag = self:GetTradeSkillOption("filterInventory-bag")
	local showCraft = self:GetTradeSkillOption("filterInventory-crafted")
	local showVendor = self:GetTradeSkillOption("filterInventory-vendor")
	local showAlts = self:GetTradeSkillOption("filterInventory-alts")
	local catstring = {}
	SkilletFrameEmptySpace.skill.subGroup = self:RecipeGroupFind(self.currentPlayer,self.currentTrade,self.currentGroupLabel,self.currentGroup)
	--DA.DEBUG(0,"UpdateTradeSkillWindow: GroupLabel= "..tostring(self.currentGroupLabel)..", Group= "..tostring(self.currentGroup))
	self.visibleSkillButtons = math.min(numTradeSkills - skillOffset, button_count)
--
-- Iterate through all the buttons that make up the scroll window
-- and fill them in with data or hide them, as necessary
--
	--DA.DEBUG(0,"UpdateTradeSkillWindow: Start for loop, button_count= "..tostring(button_count))
	for i=1, button_count, 1 do
		local rawSkillIndex = i + skillOffset
		local button, buttonDrag = get_recipe_button(i)
		button.rawIndex = rawSkillIndex
		button:SetWidth(width)
		if rawSkillIndex <= numTradeSkills then
			local skill = sortedSkillList[rawSkillIndex]
			--DA.DEBUG(2,"UpdateTradeSkillWindow: rawSkillIndex= "..tostring(rawSkillIndex)..", name= "..tostring(skill.name))
			--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
			local skillIndex = skill.skillIndex
			local buttonText = _G[button:GetName() .. "Name"]
			local levelText = _G[button:GetName() .. "Level"]
			local countText = _G[button:GetName() .. "Counts"]
			local suffixText = _G[button:GetName() .. "Suffix"]
			local buttonExpand = _G[button:GetName() .. "Expand"]
			local buttonFavorite = _G[button:GetName() .. "Favorite"]
			local subSkillRankBar = _G[button:GetName() .. "SubSkillRankBar"]
--
-- Blizzard's Cooking database is FUBAR, fix it
--
			if self.FixBugs then
				if skill.name == "Food of Draenor - Header" then 
					DA.DEBUG(2,"UpdateTradeSkillWindow: FixBugs")
					--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
					skill.name = "Food of Draenor"
				elseif skill.name == "Cucina di Draenor - Titolo" then 
					DA.DEBUG(2,"UpdateTradeSkillWindow: FixBugs")
					--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
					skill.name = "Cucina di Draenor"
				end
			end
--
-- end of FUBAR fixes
--
			local hasProgressBar = Skillet.hasProgressBar[skill.name]
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
			if self.currentGroupLabel ~= "Blizzard" then 
				DA.DEBUG(0,"UpdateTradeSkillWindow: skill.subGroup = "..tostring(skill.subGroup))
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
					local name = string.split(":", skill.name).." ("..#skill.subGroup.entries..")"
					buttonText:SetText(name)
					button:SetID(skillIndex or 0)
					buttonExpand.group = skill.subGroup
					button.skill = skill
					button:UnlockHighlight() -- headers never get highlighted
					buttonExpand:Show()
					if hasProgressBar then
						local category = Skillet.db.global.Categories[self.currentTrade][hasProgressBar]
						local currentRank = category.skillLineCurrentLevel
						local startingRank = category.skillLineStartingRank
						local maxRank = category.skillLineMaxLevel
						--DA.DEBUG(0,"UpdateTradeSkillWindow: "..tostring(skill.name).." ("..tostring(hasProgressBar)..")"..", category= "..DA.DUMP1(category))
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
				--DA.DEBUG(0,"UpdateTradeSkillWindow: currentTrade= "..tostring(self.currentTrade)..", Process '"..tostring(skill.name).."'("..tostring(skill.recipeID).."), skillIndex= "..tostring(skillIndex))
				local recipe = self:GetRecipe(skill.recipeID)
				buttonExpand.group = nil
				button.skill = skill
				local skill_color = Skillet.skill_style_type[recipe.difficulty] or skill.color or skill.skillData.color or NORMAL_FONT_COLOR
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
--
-- If the item has a minimum level requirement, then print that here
--
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
--
-- Check for prefix information returned from a plugin. Most will return just text (which could be an icon)
-- Some may return additional information so store that in the button for later use.
--
				pretext, preid, prelink = self:RecipeNamePrefix(skill, recipe)
				if pretext then
					button.pretext = pretext
				end
				if preid then
					button.preid = preid
				end
				if prelink then
					button.prelink = prelink
				end
--
-- Set the prefix and name of the recipe
--
				text = (pretext or "") .. (skill.name or "")
--
-- Prepare the counts (displayed on the right)
--
				local num, numrecursive, numwvendor, numwalts = get_craftable_counts(skill.skillData, recipe.numMade)
				if (num > 0 and showBag) or (numrecursive > 0 and showCraft) or (numwvendor > 0 and showVendor) or (numwalts > 0 and showAlts) then
					local c = 1
					if showBag then
						if num >= 1000 then
							num = "##"
						end
						catstring[c] = CBAG..num
						c = c + 1
					end
					if showCraft then
						if numrecursive >= 1000 then
							numrecursive = "##"
						end
						catstring[c] = CCRAFT..numrecursive
						c = c + 1
					end
					if showVendor then
						if numwvendor >= 1000 then
							numwvendor = "##"
						end
						catstring[c] = CVENDOR..numwvendor
						c = c + 1
					end
					if showAlts then
						if numwalts >= 1000 then
							numwalts = "##"
						end
						catstring[c] = CALTS..numwalts
						c = c + 1
					end
					local count = ""
					if c > 1 then
						count = CGREY.."["
						for b=1,c-1 do
							count = count..catstring[b]
							if b+1 < c then
								count = count..CGREY.."/"
							end
						end
						count = count..CGREY.."]|r"
					end
					countText:SetText(count)
					countText:Show()
				else
					countText:Hide()
				end
--
-- Show the count of the item currently owned that the recipe will produce
--
				if showOwned and self.currentPlayer == UnitName("player") then
					local numowned = (self.db.realm.auctionData[self.currentPlayer][recipe.itemID] or 0) + GetItemCount(recipe.itemID,true)
					if numowned > 0 then
						if numowned >= 1000 then
							numowned = "##"
						end
						local count = COWNED.."("..numowned..") "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				if skill_color.alttext == "+++" then
					local numSkillUps = recipe.numSkillUps
					if numSkillUps and numSkillUps > 1 then
						local count = "<+"..numSkillUps.."> "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				countText:SetWidth(math.max(countText:GetStringWidth(),SKILLET_COUNT_MIN_WIDTH)) -- make end of buttonText have a fixed location
				button:SetID(skillIndex or 0)
--
-- If enhanced recipe display is enabled, show the difficulty as text,
-- rather than as a colour. This should help used that have problems
-- distinguishing between the difficulty colours we use.
--
				if self.db.profile.enhanced_recipe_display then
					text = text .. skill_color.alttext;
				end
--
-- If this recipe is upgradable, append the current and maximum upgrade levels
--
				--DA.DEBUG(0,"UpdateTradeSkillWindow: skill= "..DA.DUMP1(skill,1))
				local recipeInfo = Skillet.data.recipeInfo[self.currentTrade][skill.recipeID]
				--DA.DEBUG(0,"UpdateTradeSkillWindow: recipeInfo= "..DA.DUMP1(recipeInfo))
				if recipeInfo and recipeInfo.upgradeable then
					if Skillet.db.profile.show_max_upgrade then
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade).."/"..tostring(recipeInfo.maxUpgrade)..")"
					else
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade)..")"
					end
				end
--
-- Check for suffix information returned from a plugin
--
				suffixText:SetText(self:RecipeNameSuffix(skill, recipe) or "")
				suffixText:Show()
--
-- When displaying both learned and unlearned, add a "-" to the name of unlearned recipes
--
				if self.learnedRecipes and self.unlearnedRecipes then
					if recipeInfo and not recipeInfo.learned then
						text = "-"..text
					end
				end
				buttonText:SetText(text)
				buttonText:SetWordWrap(false)
--
-- Adjust the width of this line
--
				buttonText:SetWidth(max_text_width - countText:GetWidth())
--
-- Set this line's highlight and color
--
				if not self.dragEngaged and self.selectedSkill and self.selectedSkill == skillIndex then
					SkilletHighlightFrame:SetPoint("TOPLEFT", "SkilletScrollButton"..i, "TOPLEFT", 0, 0)
					SkilletHighlightFrame:SetWidth(button:GetWidth())
					SkilletHighlightFrame:SetFrameLevel(button:GetFrameLevel())
					if color then
						SkilletHighlight:SetColorTexture(color.r, color.g, color.b, 0.4)
					else
						SkilletHighlight:SetColorTexture(0.7, 0.7, 0.7, 0.4)
					end
--
-- Update the details for this skill, just in case something
-- has changed (mats consumed, etc)
--
					self:UpdateDetailWindow(self.selectedSkill)
					SkilletHighlightFrame:Show()
					button:LockHighlight()
				else
--
-- Not selected
--
					button:UnlockHighlight()
				end
				--DA.DEBUG(0,"UpdateTradeSkillWindow: show_button, skillIndex= "..tostring(skillIndex))
				show_button(button, self.currentTrade, skillIndex, i, skill.recipeID)
			end
		else -- rawSkillIndex > numTradeSkills 
			--DA.DEBUG(0,"UpdateTradeSkillWindow: hide_button, skillIndex= "..tostring(skillIndex))
			hide_button(button, self.currentTrade, skillIndex, i)
			button:UnlockHighlight()
		end
	end -- for
--
-- Hide any of the buttons that we created but don't need right now
--
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
	self.InProgress.main = false
--	self.InProgress.mainDepth = self.InProgress.mainDepth - 1
	--DA.DEBUG(3,"UpdateTradeSkillWindow Complete")
end

--
-- Display an action packed tooltip when we are over
-- a recipe in the list of skills
--
function Skillet:SkillButton_OnEnter(button)
	--DA.DEBUG(0,"SkillButton_OnEnter("..tostring(button)..")")
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
	--DA.DEBUG(1,"SkillButton_OnEnter: skill= "..DA.DUMP1(skill,1))
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
	local recipe = self:GetRecipe(skill.recipeID) or Skillet.unknownRecipe
	if not self.db.profile.show_detailed_recipe_tooltip then
--
-- User does not want the tooltip displayed, it can get a bit big after all
--
		button.locked = false
		return
	end
	local tip = SkilletTradeskillTooltip
	ShoppingTooltip1:Hide()
	ShoppingTooltip2:Hide()
	if not tip.SetBackdrop then
		Mixin(tip, BackdropTemplateMixin)
	end
	tip:SetOwner(button, "ANCHOR_BOTTOMRIGHT",-300);
	tip:SetBackdropColor(0,0,0,1);
	tip:ClearLines();
	tip:SetClampedToScreen(true)
--
-- Set the tooltip's scale to match that of the default UI
--
	local uiScale = 1.0;
	if ( GetCVar("useUiScale") == "1" ) then
		uiScale = tonumber(GetCVar("uiscale"))
	end
	if Skillet.db.profile.ttscale then
		uiScale = uiScale * Skillet.db.profile.ttscale
	end
	tip:SetScale(uiScale)
--
-- Name of the recipe
--
		local color = Skillet.skill_style_type[skill.difficulty]
		if (color) then
			tip:AddLine(skill.name, color.r, color.g, color.b, false)
		else
			tip:AddLine(skill.name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
		end
--
--	Add Skillet specific information to the tooltip
--
	local num, numrecursive, numwvendor, numwalts, numowned = 0, 0, 0, 0, 0
	if skill.skillData then
		num, numrecursive, numwvendor, numwalts = get_craftable_counts(skill.skillData, recipe.numMade)
	end
	numowned = GetItemCount(recipe.itemID,true,false,true)
--
-- How many are there already
--
	if numowned > 0 then
		local text = "\n" .. COWNED..numowned .. "|r " .. L["in your inventory"]
		tip:AddLine(text, 1, 1, 1, false) -- (text, r, g, b, wrap)
	end
--
-- How many can be created with the reagents in the inventory
--
	if num > 0 then
		local text = "\n" .. CBAG..num .. "|r " .. L["can be created from reagents in your inventory"]
		tip:AddLine(text, 1, 1, 1, false) -- (text, r, g, b, wrap)
	end
--
-- How many can be created by crafting the reagents
--
	if numrecursive > 0 then
		local text = "\n" .. CCRAFT..numrecursive .. "|r " .. L["can be created by crafting reagents"]
		tip:AddLine(text, 1, 1, 1, false) -- (text, r, g, b, wrap)
	end
--
-- How many can be created with reagents bought at vendor
--
	if numwvendor and numwvendor > 0 and numwvendor ~= num then
		if numwvendor >= 1000 then
			numwvendor = "##"
		end
		local text =  "\n" .. CVENDOR..numwvendor .. "|r " .. L["can be created with reagents bought at vendor"]
		tip:AddLine(text, 1, 1, 1, false) -- (text, r, g, b, wrap)
	end
--
-- How many can be crafted with reagents on *all* alts, including this one.
--
	if numwalts and numwalts > 0 and numwalts ~= num then
		if numwalts >= 1000 then
			numwalts = "##"
		end
		local text = "\n" .. CALTS..numwalts .. "|r " .. L["can be created from reagents on all characters"]
		tip:AddLine(text, 1, 1, 1, false)	-- (text, r, g, b, wrap)
	end
--
-- Now the list of regents for this recipe and some info about them
--
	tip:AddLine("\n" .. SPELL_REAGENTS)
	for i=1,#recipe.reagentData do
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
		local counts
		counts = string.format("|cff808080[%d/%d]|r", numInBoth, numCraftable)
		tip:AddDoubleLine(text, counts, 1, 1, 1)
	end
	if recipe.modifiedData then
		for i=1,#recipe.modifiedData do
			local numInBoth, numCraftable = self:GetInventory(self.currentPlayer, recipe.modifiedData[i].schematic.reagents)
			local itemName = GetItemInfo(recipe.modifiedData[i].reagentID) or recipe.modifiedData[i].reagentID
			local text
			text = string.format("  %d x %s", recipe.modifiedData[i].numNeeded, itemName)
			local counts
			counts = string.format("|cff808080[%d/%d]|r", numInBoth, numCraftable)
			tip:AddDoubleLine(text, counts, 1, 1, 1)
		end
	end
	local text = string.format("[%s/%s]", L["Inventory"], L["craftable"]) -- match the case sometime
	tip:AddDoubleLine("\n", text)
	local text1 = string.format("recipeID= %d",skill.recipeID)
	local text = string.format("itemID= %d",recipe.itemID)
	tip:AddDoubleLine(text1, text)
	tip:Show()
	button.locked = false
end

--
-- Sets the game tooltip item to the selected skill
--
function Skillet:SetTradeSkillToolTip(skillIndex)
	--DA.DEBUG(2,"SetTradeSkillToolTip("..tostring(skillIndex)..", "..tostring(onEvent)..")")
	GameTooltip:ClearLines()
	if Skillet.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if Skillet.db.profile.ttscale then
			uiScale = uiScale * Skillet.db.profile.ttscale
		end
		GameTooltip:SetScale(uiScale)
	end
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		if recipe.itemID ~= 0 then
			if self.currentTrade == 7411 then		-- Enchanting
				GameTooltip:SetHyperlink("item:"..recipe.itemID)
			else
				GameTooltip:SetHyperlink(C_TradeSkillUI.GetRecipeItemLink(recipeID))
			end
			if IsShiftKeyDown() then
				GameTooltip_ShowCompareItem()
			end
		else
			--DA.DEBUG(2,"SetTradeSkillToolTip: Using SetHyperlink (spellID)")
			GameTooltip:SetHyperlink("enchant:"..recipe.spellID)				-- doesn't create an item, just tell us about the recipe
		end
	end
	GameTooltip:Show()
	CursorUpdate(self)
end

--
-- Clears any changes and hides the game tooltip
--
function Skillet:ClearTradeSkillToolTip(skillIndex)
	if Skillet.db.profile.scale_tooltip then
		GameTooltip:SetScale(Skillet.gttScale)
	end
	GameTooltip:Hide()
	ResetCursor()
end

Skillet.bopCache = {}
function Skillet:bopCheck(item)
	--DA.DEBUG(0,"bopCheck("..tostring(item)..")")
	if not self.bopCache[item] then
		local _, link, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = GetItemInfo(item)
		--DA.DEBUG(0,"bopCheck: bindType= "..tostring(bindType))
		self.bopCache[item] = bindType or 0	-- Item binding type: 0 - none; 1 - on pickup; 2 - on equip; 3 - on use; 4 - quest
	end
	if self.bopCache[item] == 1 then
		return true
	end
	return false
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
	--DA.DEBUG(0, "SkillButton_OnMouseUp")
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

function Skillet:SkillButton_LinkRecipe()
	--DA.DEBUG(0,"SkillButton_LinkRecipe()")
	local skill = Skillet.menuButton.skill
	if skill and skill.recipeID then
		local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
		if not ChatEdit_InsertLink(spellLink) then
			DA.DEBUG(0,"SkillButton_LinkRecipe: spellLink= "..DA.PLINK(spellLink))
		end
	end
end

function Skillet:SkillButton_CopySelected()
	--DA.DEBUG(0,"SkillButton_CopySelected()")
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
			--DA.DEBUG(1,"SkillButton_CopySelected: "..(sortedSkillList[i].name or "nil"))
			d = d + 1
		end
	end
end

function Skillet:SkillButton_PasteSelected(button)
	--DA.DEBUG(0,"SkillButton_PasteSelected("..tostring(button)..")")
	if not self:RecipeGroupIsLocked() then
		local parentGroup
		if button then
			parentGroup = button.skill.subGroup or button.skill.parent
		else
			parentGroup = self:RecipeGroupFind(self.currentPlayer, self.currentTrade, self.currentGroupLabel, self.currentGroup)
		end
		if self.skillListCopyBuffer and self.skillListCopyBuffer[self.currentTrade] then
			for d=1,#self.skillListCopyBuffer[self.currentTrade] do
				--DA.DEBUG(1,"SkillButton_PasteSelected: "..(self.skillListCopyBuffer[self.currentTrade][d].name or "nil").." to "..parentGroup.name)
				self:RecipeGroupPasteEntry(self.skillListCopyBuffer[self.currentTrade][d], parentGroup)
			end
		end
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkillButton_DeleteSelected()
	--DA.DEBUG(0,"SkillButton_DeleteSelected()")
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
	--DA.DEBUG(0,"SkillButton_CutSelected()")
	Skillet:SkillButton_CopySelected()
	Skillet:SkillButton_DeleteSelected()
end

function Skillet:SkillButton_NewGroup()
	--DA.DEBUG(0,"SkillButton_NewGroup()")
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
	--DA.DEBUG(0,"SkillButton_MakeGroup()")
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
	--DA.DEBUG(3,"SkillButton_OnKeyDown("..tostring(button)..", "..tostring(key)..")")
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
	--DA.DEBUG(3,"SkillButton_NameEditEnable("..tostring(button)..")")
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

--
-- When one of the skill buttons in the left scroll pane is clicked
--
local lastClick = 0
function Skillet:SkillButton_OnClick(button, mouse)
	if (mouse == "LeftButton") then
		Skillet:QueueManagementToggle(true)
		local doubleClicked = false
		local thisClick = GetTime()
		local delay = thisClick - lastClick
		lastClick = thisClick
		if delay < .25 then
			doubleClicked = true
			DA.DEBUG(1,"SkillButton_OnClick: double click")
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
					if not ChatEdit_InsertLink(spellLink) then
						DA.DEBUG(0,"SkillButton_OnClick: spellLink= "..DA.PLINK(spellLink))
					end
				end
			end
		elseif not button.skill.mainGroup then
			if IsShiftKeyDown() and self.skillMainSelection then
				self:SkillButton_ClearSelections()
				self:SkillButton_SetSelections(self.skillMainSelection, button.rawIndex)
			elseif IsControlKeyDown() then
				button.skill.selected = not button.skill.selected
			elseif IsAltKeyDown() then
--
-- Some plugins may return extra information from RecipeNamePrefix so deal with it here
-- Currently, only the Overachiever plugin returns the achievement id and a link
--
				if button.prelink then
					DA.MARK3(button.prelink)
				end
			else
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
			end
		end
		self:UpdateTradeSkillWindow()
	elseif (mouse == "RightButton") then
--
-- The following options are primarily for debugging.
--
		if IsShiftKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Shift is down")
		elseif IsControlKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Ctrl is down")
		elseif IsAltKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Alt is down")
			local skill = self:GetSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
			local recipe = self:GetRecipe(skill.id)
			local requirements = C_TradeSkillUI.GetRecipeRequirements(recipe.spellID)
			local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipe.spellID)
			local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipe.spellID, false)
			DA.DEBUG(1,"SkillButton_OnClick: name= "..tostring(recipe.name)..", skill.id= "..tostring(skill.id)..", recipe.spellID= "..tostring(recipe.spellID))
			DA.DEBUG(1,"SkillButton_OnClick: skill= "..DA.DUMP1(skill))
			DA.DEBUG(1,"SkillButton_OnClick: recipe= "..DA.DUMP(recipe))
			DA.DEBUG(1,"SkillButton_OnClick: requirements= "..DA.DUMP(requirements))
			DA.DEBUG(1,"SkillButton_OnClick: GetRecipeInfo= "..DA.DUMP(recipeInfo))
			DA.DEBUG(1,"SkillButton_OnClick: GetRecipeSchematic= "..DA.DUMP(recipeSchematic))
		else
--
-- Currently the only "useful" option.
--
			self:SkilletSkillMenu_Show(button)
		end
	end
end

--
-- When one of the skill buttons in the left scroll pane is clicked
--
function Skillet:SkillExpandButton_OnClick(button, mouse, doubleClicked)
	--DA.DEBUG(3,"SkillExpandButton_OnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(doubleClicked))
	if (mouse=="LeftButton") then
		if button.group then
			button.group.expanded = not button.group.expanded
			self:SortAndFilterRecipes()
			self:UpdateTradeSkillWindow()
		end
	end
end

--
-- This function assures that a recipe that is indirectly selected (via reagent clicks, for example)
-- will be visible in the skill list (ie, not scrolled off the top/bottom)
--
function Skillet:ScrollToSkillIndex(skillIndex)
	--DA.DEBUG(0,"ScrollToSkillIndex("..tostring(skillIndex)..")")
	if skillIndex == nil then
		return
	end
--
-- Scroll the skill list to make sure the new skill is revealed
--
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
			--DA.DEBUG(0,"ScrollToSkillIndex: "..(skillOffset or "nil").." > "..(sortedIndex or "nil"))
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

--
-- Go to the previous recipe in the history list.
--
function Skillet:GoToPreviousSkill()
	local entry = table.remove(self.skillStack)
	if entry then
		self:SetTradeSkill(entry.player,entry.tradeID,entry.skillIndex)
	end
end

function Skillet:PushSkill(player, tradeID, skillIndex)
	local entry = { ["player"] = player, ["tradeID"] = tradeID, ["skillIndex"] = skillIndex }
	table.insert(self.skillStack, entry)
end

function Skillet:getLvlUpChance()
--
-- icy: 03.03.2012:
-- according to pope (http://www.wowhead.com/spell=83949#comments)
-- % to level up with this receipt is calculated by: (greySkill - yourSkill) / (greySkill - yellowSkill
--
	local skilRanks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
	local currentLevel, maxLevel = 0, 0
	if skilRanks then
		currentLevel, maxLevel = skilRanks.rank, skilRanks.maxRank
	end
	local gray = tonumber(SkilletRankFrame.subRanks.green:GetValue())
	local yellow = tonumber(SkilletRankFrame.subRanks.orange:GetValue())
	--DA.DEBUG(0,"getLvlUpChance: currentLevel= "..tostring(currentLevel)..", gray= "..tostring(gray)..", yellow= "..tostring(yellow))
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

--
-- Called when then mouse enters the rank status bar
--
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
	chance = math.floor(chance*10)/10		-- one decimal is enough
	GameTooltip:AddLine(COLORORANGE..orange.."|r/"..COLORYELLOW..yellow.."|r/"..COLORGREEN..green.."|r/"..COLORGRAY..gray.."|r/ Chance:"..chance.."|r%")
	GameTooltip:Show()
end

--
-- Called when then mouse leaves the rank status bar
--
function Skillet:RankFrame_OnLeave(button)
	GameTooltip:Hide()
end

function Skillet:SkilletFrameForceClose()
	--DA.DEBUG(0,"SkilletFrameForceClose()")
--
-- Skillet's Close (X) button just hides our frames to avoid crashing TSM
--
	if TSM_API and Skillet.db.profile.tsm_compat then
		if TSM_API.IsUIVisible("CRAFTING") then
			return self:HideAllWindows()
		end
	end
	C_TradeSkillUI.CloseTradeSkill()
	return self:HideAllWindows()
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

--
-- Easymenus for the left (recipe) side
--
--  The internal name of the menus are only
--  shown in alpha releases. Lines similar to the 
--  following could be added for additional clarity:
--		tooltipWhileDisabled = 1,
--		tooltipOnButton = 1,
--		tooltipTitle = L["Selection functions"],
--		tooltipText = L["Internal Menu Name"],
--

local skillMenuSelection = {
--[[
	{
		text = "skillMenuSelection",
		isTitle = true,
		notCheckable = true,
	},
--]]
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
--[[
	{
		text = "skillMenuGroup",
		isTitle = true,
		notCheckable = true,
	},
--]]
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
--[[
	{
		text = "favoriteMenu",
		isTitle = true,
		notCheckable = true,
	},
--]]
		text = "",
		func = function()
					local recipeID = Skillet.menuButton.skill.recipeID
					local favoriteButton = _G[Skillet.menuButton:GetName() .. "Favorite"]
					Skillet:ToggleFavorite(recipeID)
					favoriteButton:SetFavorite(Skillet:IsFavorite(recipeID))
				end,
}

local skillMenuIgnore = {
--[[
	{
		text = "skillMenuIgnore",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Add Recipe to Ignored List"],
		func = function()
					local index = Skillet.menuButton:GetID()
					local skillDB = Skillet.db.realm.skillDB[Skillet.currentPlayer][Skillet.currentTrade][index]
					local recipeID = string.sub(skillDB,2)
					local print=(tostring(index)..", "..tostring(skillDB)..", "..tostring(recipeID))
					Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeID] = Skillet.currentTrade
					if Skillet.ignoreList and Skillet.ignoreList:IsVisible() then
						Skillet:UpdateIgnoreListWindow()
					end
				end,
	},
	{
		text = L["Remove Recipe from Ignored List"],
		func = function()
					local index = Skillet.menuButton:GetID()
					local skillDB = Skillet.db.realm.skillDB[Skillet.currentPlayer][Skillet.currentTrade][index]
					local recipeID = string.sub(skillDB,2)
					local print=(tostring(index)..", "..tostring(skillDB)..", "..tostring(recipeID))
					Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeID] = nil
					if Skillet.ignoreList and Skillet.ignoreList:IsVisible() then
						Skillet:UpdateIgnoreListWindow()
					end
				end,
	},
}

local skillMenuList = {
--[[
	{
		text = "skillMenuList",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Link Recipe"],
		func = function() Skillet:SkillButton_LinkRecipe() end,
	},
	favoriteMenu,
	{
		text = L["Ignore"],
		hasArrow = true,
		menuList = skillMenuIgnore,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
	},
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
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
--[[
	{
		text = "skillMenuListLocked",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Link Recipe"],
		func = function() Skillet:SkillButton_LinkRecipe() end,
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
		text = "-----",
		isTitle = true,
		notCheckable = true,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}

local headerMenuList = {
--[[
	{
		text = "headerMenuList",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Rename Group"],
		func = function() Skillet:SkillButton_NameEditEnable(Skillet.menuButton) end,
	},
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
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
--[[
	{
		text = "headerMenuListLocked",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}

local headerMenuListMainGroup = {
--[[
	{
		text = "headerMenuListMainGroup",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["New Group"],
		hasArrow = true,
		menuList = skillMenuGroup,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
	},
	{
		text = L["Selection"],
		hasArrow = true,
		menuList = skillMenuSelection,
	},
	{
		text = "-----",
		isTitle = true,
		notCheckable = true,
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
--[[
	{
		text = "headerMenuListMainGroupLocked",
		isTitle = true,
		notCheckable = true,
	},
--]]
	{
		text = L["Copy"],
		func = function() Skillet:SkillButton_CopySelected() end,
	},
}

--
-- Called when the skill operators drop down is displayed
--
function Skillet:SkilletSkillMenu_Show(button)
	if not SkilletSkillMenu then
		SkilletSkillMenu = CreateFrame("Frame", "SkilletSkillMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	local locked = self:RecipeGroupIsLocked()
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
		if C_TradeSkillUI.GetShowLearned() then
			favoriteMenu["text"] = L["Set Favorite"]
		else
			favoriteMenu["text"] = L["Cannot Set Favorite"]
		end
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

function Skillet:ReAnchorButtons(newFrame)
	--DA.DEBUG(0,"ReAnchorButtons("..tostring(newFrame)..")")
	SkilletRecipeNotesButton:SetPoint("BOTTOMRIGHT",newFrame,"TOPRIGHT",0,0)
	SkilletQueueAllButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
	SkilletEnchantButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
--	SkilletQueueButton:SetPoint("TOPRIGHT",newFrame,"BOTTOMRIGHT",0,-2)
end

function Skillet:ViewCraftersClicked()
	if SkilletViewCraftersParent:IsVisible() then
		Skillet:ShowReagentDetails()
	else
		self.queriedSkill = self.selectedSkill
		SelectTradeSkill(self.selectedSkill)
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
		SkilletViewCraftersScrollFrameScrollBar:SetValue(0)
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
	--DA.DEBUG(0, "ViewCraftersUpdate: "..numMembers.." - "..offset)
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

--
-- The SkilletQueue and StandaloneQueue functions start here
--
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

--
-- The start/pause queue button.
--
function Skillet:StartQueue_OnClick(button, mouse)
	if self.queuecasting then
		DA.MARK3("Cancel incomplete processing")
		self:CancelCast()
		self.queuecasting = false
	else
		button:SetText(L["Pause"])
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
	self:UpdateQueueWindow()
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

function Skillet:QueueManagementToggle(showDetails)
	--DA.DEBUG(0,"QueueManagementToggle("..tostring(showDetails)..")")
	if SkilletQueueManagementParent:IsVisible() or showDetails then
		Skillet:ShowReagentDetails()
	else
		SkilletQueueManagementParent:Show();
		SkilletQueueManagementParent:SetHeight(100)
		SkilletReagentParent:Hide()
		Skillet:ReAnchorButtons(SkilletQueueManagementParent)
	end
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
		--DA.DEBUG(0,"QueueItemButton_OnClick: selecting new skill "..tradeID..":"..(newSkillIndex or "nil"))
		self:SetTradeSkill(self.currentPlayer, tradeID, newSkillIndex)
		--DA.DEBUG(0,"QueueItemButton_OnClick: done selecting new skill")
	elseif button == "RightButton" then
		Skillet:SkilletQueueMenu_Show(this)
	end
end

--
-- Called when the list of queued items is scrolled
--
function Skillet:QueueList_OnScroll()
	Skillet:UpdateQueueWindow()
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

--
-- Updates the window/scroll list displaying queue of items
-- that are waiting to be crafted.
--
function Skillet:UpdateQueueWindow()
	--DA.DEBUG(0,"UpdateQueueWindow()")
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
	local button_count = SkilletQueueParentBase:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
	button_count = math.max(0, (math.floor(button_count) - 1))
	--DA.DEBUG(0,"UpdateQueueWindow: button_count="..button_count)
	if button_count == 0 then
		if self.fullView then
			button_count = self.saved_full_button_count
		else
			button_count = self.saved_SA_button_count
		end
	else
		if self.fullView then
			self.saved_full_button_count = button_count
		else
			self.saved_SA_button_count = button_count
		end
	end
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(SkilletQueueList,				-- frame
						   numItems,                        -- num items
						   button_count,                    -- num to display
						   SKILLET_TRADE_SKILL_HEIGHT)      -- value step (item height)
--
-- Where in the list of skill to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(SkilletQueueList)
	--DA.DEBUG(0,"UpdateQueueWindow: itemOffset="..itemOffset)
	local width = SkilletQueueList:GetWidth()
--
-- Iterate through all the buttons that make up the scroll window
-- and fill then in with data or hide them, as necessary
--
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
--
-- Stick this on top of the button we use for displaying queue contents.
--
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
				--DA.DEBUG(0,"UpdateQueueWindow: queueCommand= "..DA.DUMP1(queueCommand))
				local recipe = self:GetRecipe(queueCommand.recipeID)
				local optionals = ""
				local c = 0
				if queueCommand.optionalReagents then
					for i,r in pairs(queueCommand.optionalReagents) do
						c = c + 1
					end
					if c > 0 then
						optionals = " +"..tostring(c)
					end
				end
				queueName:SetText((self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..(recipe.name or recipe.recipeID)..optionals)
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
--
-- Hide any of the buttons that we created, but don't need right now
--
	for i = button_count + 1, num_queue_buttons, 1 do
	   local button = get_queue_button(i)
	   button:Hide()
	end
end

function Skillet:ShowFullView()
	Skillet.fullView = true
	SkilletQueueParentBase:SetParent(SkilletFrame)
	SkilletQueueParentBase:ClearAllPoints()
	SkilletQueueParentBase:SetPoint("TOPLEFT",SkilletCreateAllButton,"BOTTOMLEFT",0,-3)
	SkilletQueueParentBase:SetPoint("BOTTOMRIGHT",SkilletFrame,"BOTTOMRIGHT",-10,32)
	SkilletStandaloneQueue:Hide()
	SkilletQueueOnlyButton:SetText(">")
	Skillet:UpdateQueueWindow()
end

function Skillet:ShowQueueView()
	--DA.DEBUG(0,"ShowQueueView()")
	Skillet.fullView = false
	SkilletQueueParentBase:SetParent(SkilletStandaloneQueue)
	SkilletQueueParentBase:ClearAllPoints()
	SkilletQueueParentBase:SetPoint("TOPLEFT",SkilletStandaloneQueue,"TOPLEFT",5,-32)
	SkilletQueueParentBase:SetPoint("BOTTOMRIGHT",SkilletStandaloneQueue,"BOTTOMRIGHT",-5,30)
	SkilletStandaloneQueue:Show()
	SkilletQueueOnlyButton:SetText("<")
	Skillet:UpdateQueueWindow()
end

function Skillet:QueueOnlyViewToggle()
	--DA.DEBUG(0,"QueueOnlyViewToggle()")
	FauxScrollFrame_SetOffset(SkilletQueueList, 0)
	self.fullView = not self.fullView
	if self.fullView then
		self:ShowFullView()
		if self.db.profile.queue_only_view then
			SkilletFrame:Show()
		else
			self:UpdateTradeSkillWindow()
		end
	else
		self:ShowQueueView()
		if self.db.profile.queue_only_view then
			SkilletFrame:Hide()
		end
	end
end

function Skillet:StandaloneQueueClose()
	--DA.DEBUG(0,"StandaloneQueueClose()")
	self:ShowFullView()
	if self.db.profile.queue_only_view then
		self:SkilletFrameForceClose()
	end
end

function Skillet:HideStandaloneQueue()
	--DA.DEBUG(0,"HideStandaloneQueue()")
	local closed
	if self.skilletStandaloneQueue and self.skilletStandaloneQueue:IsVisible() then
		SkilletStandaloneQueue:Hide()
		closed = true
	end
	return closed
end

--
-- Creates and sets up the Standalone Queue Frame
--
function Skillet:CreateStandaloneQueueFrame()
	--DA.DEBUG(0,"CreateStandaloneQueueFrame()")
	local frame = SkilletStandaloneQueue
	if not frame then
		return nil
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	if TSM_API and Skillet.db.profile.tsm_compat then
		frame:SetFrameStrata("HIGH")
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
	titlebar:SetGradient("VERTICAL", CreateColor(r*0.6,g*0.6,b*0.6,1), CreateColor(r,g,b,1))
	titlebar:SetColorTexture(r,g,b,1)
	titlebar2:SetGradient("VERTICAL", CreateColor(r*0.9,g*0.9,b*0.9,1), CreateColor(r*0.6,g*0.6,b*0.6,1))
	titlebar2:SetColorTexture(r,g,b,1)
	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)
	local titletext = title:CreateFontString("SkilletStandaloneQueueTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: " .. L["Queue"])

--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local standaloneQueueLocation = {
		prefix = "standaloneQueueLocation_"
	}
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, standaloneQueueLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	Skillet:EnableResize(frame, 385, 170, Skillet.UpdateStandaloneQueueWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
	return frame
end

function Skillet:UpdateStandaloneQueueWindow()
	--DA.DEBUG(0,"UpdateStandaloneQueueWindow()")
	if not self.skilletStandaloneQueue or not self.skilletStandaloneQueue:IsVisible() then
		return
	end
	SkilletStandaloneQueue:SetAlpha(self.db.profile.transparency)
	SkilletStandaloneQueue:SetScale(self.db.profile.scale)
	self:UpdateQueueWindow()
end

--
-- Adds a button to the tradeskill window. The button will be
-- reparented and placed appropriately in the window.
--
-- The frame representing the main tradeskill window will be
-- returned in case you need to pop up a frame attached to it.
--
function Skillet:AddButtonToTradeskillWindow(button)
	--DA.DEBUG(0,"AddButtonToTradeskillWindow("..tostring(button)..")")
	if not SkilletFrame.added_buttons then
		SkilletFrame.added_buttons = {}
	end
	button:Hide()
--
-- See if this button has already been added ...
--
	for i=1, #SkilletFrame.added_buttons, 1 do
		if SkilletFrame.added_buttons[i] == button then
			return	-- ... yup
		end
	end
	table.insert(SkilletFrame.added_buttons, button)	-- ... nope
	if SkilletPluginButton then
		SkilletPluginButton:Show()
	end
	return SkilletFrame
end
