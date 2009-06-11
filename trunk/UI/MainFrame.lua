--[[ Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

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

local L = AceLibrary("AceLocale-2.2"):new("Skillet")

SKILLET_TRADE_SKILL_HEIGHT = 16
SKILLET_NUM_REAGENT_BUTTONS = 8

-- min/max width for the reagent window
local SKILLET_REAGENT_MIN_WIDTH = 240
local SKILLET_REAGENT_MAX_WIDTH = 320

local skill_style_type = {
    ["optimal"]         = { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++"},
    ["medium"]          = { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++"},
    ["easy"]            = { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+"},
    ["trivial"]         = { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext=""},
    ["header"]          = { r = 1.00, g = 0.82, b = 0,    level = 0, alttext=""},
}

-- Events
local AceEvent = AceLibrary("AceEvent-2.0")

-- Stack of porevisouly selected recipes for use by the
-- "click on reagent, go to recipe" code
local previousRecipies = {}
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
-- Returns: num, num_with_bank, num_with_alts
local function get_craftable_counts(recipe)
    local factor = 1
    if Skillet.db.profile.show_craft_counts then
        factor = recipe.nummade or 1
    end

    local num      = math.floor(recipe.numcraftable / factor)
    local numwbank = math.floor(recipe.numcraftablewbank / factor)
    local numwalts = nil
    if recipe.numcraftablewalts then
        numwalts = math.floor(recipe.numcraftablewalts / factor)
    end

    return num, numwbank, numwalts
end

function Skillet:CreateTradeSkillWindow()

    -- The SkilletFrame is defined in the file main_frame.xml
    local frame = SkilletFrame
    if not frame then
        return frame
    end

    if TradeJunkieMain and TJ_OpenButtonTradeSkill then
        self:AddButtonToTradeskillWindow(TJ_OpenButtonTradeSkill)
    end
    if AC_Craft and AC_UseButton and AC_ToggleButton then
        self:AddButtonToTradeskillWindow(AC_ToggleButton)
        self:AddButtonToTradeskillWindow(AC_UseButton)
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
    titletext:SetText(L["Skillet Trade Skills"]);

    local label = getglobal("SkilletFilterLabel");
    label:SetText(L["Filter"]);
    
    local label = getglobal("SkilletSortLabel");
    label:SetText(L["Sorting"]);

    SkilletCreateAllButton:SetText(L["Create All"])
    SkilletQueueAllButton:SetText(L["Queue All"])
    SkilletCreateButton:SetText(L["Create"])
    SkilletQueueButton:SetText(L["Queue"])
    SkilletStartQueueButton:SetText(L["Start"])
    SkilletEmptyQueueButton:SetText(L["Clear"])
    SkilletShowOptionsButton:SetText(L["Options"])
    SkilletRescanButton:SetText(L["Rescan"])
    SkilletRecipeNotesButton:SetText(L["Notes"])
    SkilletRecipeNotesButton:SetNormalFontObject("GameFontNormalSmall")
    SkilletRecipeNotesFrameLabel:SetText(L["Notes"])
    SkilletShoppingListButton:SetText(L["Shopping List"])

    SkilletHideUncraftableRecipesText:SetText(L["Hide uncraftable"])
    SkilletHideTrivialRecipesText:SetText(L["Hide trivial"])

    -- Always want these visible.
    SkilletItemCountInputBox:SetText("1");
    SkilletCreateCountSlider:SetMinMaxValues(1, 20);
    SkilletCreateCountSlider:SetValue(1);
    SkilletCreateCountSlider:Show();
    SkilletCreateCountSliderThumb:Show();

    -- Progression status bar
    SkilletRankFrame:SetStatusBarColor(0.2, 0.2, 1.0, 1.0);
    SkilletRankFrameBackground:SetVertexColor(0.0, 0.0, 0.5, 0.2);

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

    gearTexture = SkilletReagentParent:CreateTexture(nil, "OVERLAY")
    gearTexture:SetTexture("Interface\\Icons\\Trade_Engineering")
    gearTexture:SetHeight(16)
    gearTexture:SetWidth(16)

    -- Ace Window manager library, allows the window position (and size)
    -- to be automatically saved
    local windowManger = AceLibrary("Window-1.0")
    local tradeSkillLocation = {
        prefix = "tradeSkillLocation_"
    }
    windowManger:RegisterConfig(frame, self.db.char, tradeSkillLocation)
    windowManger:RestorePosition(frame)  -- restores scale also
    windowManger:MakeDraggable(frame)

    -- lets play the resize me game!
    local minwidth = self:GetMinSkillButtonWidth()
    if not minwidth or minwidth < 165 then
        minwidth = 165
    end
    minwidth = minwidth +                  -- minwidth of scroll button
               20 +                        -- padding between sroll and detail
               SKILLET_REAGENT_MIN_WIDTH + -- reagent window (fixed width)
               10                          -- padding about window borders

    self:EnableResize(frame, minwidth, 480, Skillet.UpdateTradeSkillWindow)

    -- Set up the sorting methods here
    self:InitializeSorting()

    return frame
end

-- Resets all the sorting and filtering info for the window
-- This is called when the window has changed enough that
-- sorting or filtering may need to be updated.
function Skillet:ResetTradeSkillWindow()
    Skillet:SortDropdown_OnShow()

    -- Reset all the added buttons so that they look OK.
    local buttons = SkilletFrame.added_buttons
    if buttons then
        local last_button = SkilletRescanButton
        for i=1, #buttons, 1 do
            local button = buttons[i]
            if button then
                button:ClearAllPoints()
                button:SetParent("SkilletFrame")
                button:SetPoint("TOPRIGHT", last_button, "TOPLEFT", -5, 0)
                last_button = button
            end
        end
     end
end

-- Something has changed in the tradeskills, and the window needs to be updated
function Skillet:TradeSkillRank_Updated()
    local _, rank, maxRank = self:GetTradeSkillLine();

    if rank and maxRank then
        SkilletRankFrame:SetMinMaxValues(0, maxRank);
        SkilletRankFrame:SetValue(rank);
        SkilletRankFrameSkillRank:SetText(rank.."/"..maxRank);
    end

end

-- Someone dragged the slider or set the value programatically.
function Skillet:UpdateNumItemsSlider(item_count, clicked)
    local value = floor(item_count + 0.5);

    self.numItemsToCraft = value

    if SkilletCreateCountSlider:IsVisible() then
        SkilletItemCountInputBox:SetText(tostring(value))
        if not clicked then
            SkilletCreateCountSlider:SetValue(value)
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

-- Figures out whether or not the section a recipe
-- is in has been hidden (collapsed or filtered).
-- Headers are, by definition never hidden
local function is_hidden_skill(parent, skill_index)

    -- look up the info in stitch to avoid spamming the server with
    -- GetTradeSkillInfo() calls. It does not seem to like that
    local s = Skillet.stitch:GetItemDataByIndex(parent.currentTrade, skill_index)

    if not s then
        -- it's a header, headers are not skills and can never be hidden
        return false
    end

    -- it's a recipe, is it filtered out?
    -- plain text search only
    local filtertext = parent:GetTradeSkillOption(parent.currentTrade, "filtertext")
    if filtertext and filtertext ~= "" then
        local matched = false
        local filter = string.lower(filtertext)

        local name = string.lower(s.name)
        if string.find(name, filter, 1, true) == nil then
            -- no match against the filter for the item name, check the reagents
            for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
                if s[i] then
                    name = string.lower(s[i].name)
                    if string.find(name, filter, 1, true) ~= nil then
                        -- matched a reagent name
                        matched = true
                        break
                    end
                end
            end
        else
            matched = true
        end


        if not matched then
            -- no name match means that this is filtered
            return true
        end

    end

    -- it's a recipe, work backwards to find the section it's
    -- in and see if that has been collapsed.
    for i=skill_index-1, 0, -1 do
        if Skillet.stitch:GetItemDataByIndex(parent.currentTrade, i) == nil then
            -- found the header
            local skillName, _ = Skillet:GetTradeSkillInfo(i);
            if (parent.headerCollapsedState and parent.headerCollapsedState[skillName]) then
                return true
            end
            break
        end
    end

    -- are we hiding anything that can't be created with the mats on this character?
    if s.numcraftablewbank == 0 and parent:GetTradeSkillOption(parent.currentTrade, "hideuncraftable") then
        return true
    end

    -- are we hiding anything that is trivial (has no chance of giving a skill point)
    if s.difficulty == "trivial" and parent:GetTradeSkillOption(parent.currentTrade, "hidetrivial") then
        return true
    end

    return false

end

local function Skillet_redo_the_update(self)
    AceEvent:CancelScheduledEvent("Skillet_redo_the_update")
    self:UpdateTradeSkillWindow()
end

local num_recipe_buttons = 0
local function get_recipe_button(i)
    local button = getglobal("SkilletScrollButton"..i)
    if not button then
        button = CreateFrame("Button", "SkilletScrollButton"..i, SkilletSkillListParent, "SkilletSkillButtonTemplate")
        button:SetParent(SkilletSkillListParent)
        button:SetPoint("TOPLEFT", "SkilletScrollButton"..(i-1), "BOTTOMLEFT")
        button:SetFrameLevel(SkilletSkillListParent:GetFrameLevel() + 1)
    end
    return button
end

-- shows a recipe button (in the scrolling list) after doing the
-- required callbacks.
local function show_button(button, trade, skill, index)

    -- legacy method
    local before = Skillet:BeforeRecipeButtonShow(button, trade, skill, index)
    if before and before ~= button then
        button:Hide()
        button = before
    end

    for i=1, #pre_show_callbacks, 1 do
        local new_button = pre_show_callbacks[i](button, trade, skill, index)
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

    -- legacy method
    local before = Skillet:BeforeRecipeButtonHide(button, trade, skill, index)
    if before and before ~= button then
        button:Hide()
        button = before
    end

    for i=1, #pre_hide_callbacks, 1 do
        local new_button = pre_hide_callbacks[i](button, trade, skill, index)
        if new_button and new_button ~= button then
            button:Hide() -- hide the old one just in case ....
            button = new_button
        end
    end

    button:Hide()
end

-- Updates the trade skill window whenever anything has changed,
-- number of skills, skill type, skill level, etc
function Skillet:internal_UpdateTradeSkillWindow()
    if not self.currentTrade or self.currentTrade == "UNKNOWN" then
        -- nothing to see, nothing to update
        self:SetSelectedSkill(nil)
        return
    end

    -- If it's link-able, show the link button.
    if GetTradeSkillListLink() then
        SkilletTradeSkillLinkButton:Show()
    else
        SkilletTradeSkillLinkButton:Hide()
    end

    SkilletFrame:SetAlpha(self.db.profile.transparency)
    SkilletFrame:SetScale(self.db.profile.scale)

    SkilletQueueAllButton:Show()
    SkilletQueueButton:Show()
    SkilletCreateAllButton:Show()
    SkilletCreateButton:Show()
    SkilletCreateCountSlider:Show()
    SkilletCreateCountSliderThumb:Show()
    SkilletItemCountInputBox:Show()
    SkilletQueueParent:Show()
    SkilletStartQueueButton:Show()
    SkilletEmptyQueueButton:Show()

    -- shopping list button always shown
    SkilletShoppingListButton:Show()

    local width = SkilletFrame:GetWidth() - 20 -- for padding.
    local reagent_width = width / 2
    if reagent_width < SKILLET_REAGENT_MIN_WIDTH then
        reagent_width = SKILLET_REAGENT_MIN_WIDTH
    elseif reagent_width > SKILLET_REAGENT_MAX_WIDTH then
        reagent_width = SKILLET_REAGENT_MAX_WIDTH
    end

    SkilletReagentParent:SetWidth(reagent_width)
    SkilletQueueParent:SetWidth(reagent_width)

    local width = SkilletFrame:GetWidth() - reagent_width - 20 -- padding
    SkilletSkillListParent:SetWidth(width)

    -- Set the state of any craft specific options
    SkilletHideTrivialRecipes:SetChecked(self:GetTradeSkillOption(self.currentTrade, "hidetrivial"))
    SkilletHideUncraftableRecipes:SetChecked(self:GetTradeSkillOption(self.currentTrade, "hideuncraftable"))

    self:UpdateQueueWindow()

    local _, rank, maxRank = self:GetTradeSkillLine();

    -- Window Title
    local title = getglobal("SkilletTitleText");
    if title then
        title:SetText(L["Skillet Trade Skills"] .. ": " .. self.currentTrade)
    end

    local numTradeSkills = self:GetNumTradeSkills()
    -- Will only sort recipes if something has changed
    -- and there is a sorting method selected.
    self:ResortRecipes()

    -- List of all the reagents we need for all queued recipies
    -- for this player. This is used to ajust the craftable item
    -- count
    local queued_reagents = self:GetReagentsForQueuedRecipes(UnitName("player"));
    -- Tell the Stitch library about the queued items so it knows how
    -- to adjust its item counts.
    self.stitch:SetReservedReagentsList(queued_reagents);

    -- Progression status bar
    SkilletRankFrame:SetMinMaxValues(0, maxRank)
    SkilletRankFrame:SetValue(rank)
    SkilletRankFrameSkillRank:SetText(rank.."/"..maxRank)

    local button_count = SkilletSkillList:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
    button_count = math.floor(button_count)

    -- Update the scroll frame
    FauxScrollFrame_Update(SkilletSkillList,                -- frame
                           numTradeSkills,                  -- num items
                           button_count,                    -- num to display
                           SKILLET_TRADE_SKILL_HEIGHT)      -- value step (item height)

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
    local max_text_width = width

    -- Iterate through all the buttons that make up the scroll window
    -- and fill them in with data or hide them, as necessary
    for i=1, button_count, 1 do
        num_recipe_buttons = math.max(num_recipe_buttons, i)

        local skillIndex = i + skillOffset
        local button = get_recipe_button(i)

        button:SetWidth(width)

        -- skip over any hidden skills
        while (skillIndex <= numTradeSkills) do
            -- want to check the mapped name to see it it is hidden
            local mapped_index = self:GetSortedRecipeIndex(skillIndex)

            -- mapped index may be nil as the sorted_table is smaller than
            -- the standard table (all headers removed)

            if mapped_index and not is_hidden_skill(self, mapped_index) then
                -- nope, not skipping this one
                break
            end

            skillOffset = skillOffset + 1
            skillIndex = i + skillOffset
        end

        if ( skillIndex <= numTradeSkills ) then

            skillIndex = self:GetSortedRecipeIndex(skillIndex)

            local skillName, skillType = self:GetTradeSkillInfo(skillIndex)
            if not skillName then
                local s = self.stitch:GetItemDataByIndex(self.currentTrade, skillIndex)
                if s == nil then
                    skillType = "header"
                    skillName = ""
                    nilFound = true
                else
                    skillName = s.name
                end
            end

            local buttonText = getglobal(button:GetName() .. "Name")
            local levelText = getglobal(button:GetName() .. "Level")
            local countText = getglobal(button:GetName() .. "Counts")

            buttonText:SetText("")
            levelText:SetText("")
            countText:SetText("")

            levelText:Hide()
            countText:Hide()

            local skill_color = skill_style_type[skillType]
            if skill_color then
                buttonText:SetTextColor(skill_color.r, skill_color.g, skill_color.b)
                countText:SetTextColor(skill_color.r, skill_color.g, skill_color.b)
            else
                buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                countText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            end

            if skillType == "header" then
                local collapsed = false;
                if self.headerCollapsedState and self.headerCollapsedState[skillName] then
                    collapsed = self.headerCollapsedState[skillName]
                end

                if collapsed then
                    -- Collapsed
                    button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                else
                    -- expanded
                    button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                end

                buttonText:SetText(skillName)
                levelText:SetWidth(20)
                buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

                button:SetID(-1)
                button:UnlockHighlight() -- headers never get highlighted

                local button_width = button:GetTextWidth()
                while button_width > max_text_width do
                    text = string.sub(text, 0, -2)
                    buttonText:SetText(text .. "..")
                    button_width = button:GetTextWidth()
                end

                show_button(button, self.currentTrade, skillIndex, i)

            else

                button:SetNormalTexture("")
                getglobal(button:GetName() .. "Highlight"):SetTexture("")

                local s = self.stitch:GetItemDataByIndex(self.currentTrade, skillIndex)

                local text = ""
                if s then
                    text = text .. (self:GetRecipeNamePrefix(self.currentTrade, skillIndex) or "")

                    -- if the item has a minimum level requirement, then print that here
                    if self.db.profile.display_required_level then
                        local level = self:GetLevelRequiredToUse(s.link)

                        if level and level > 1 then
                            local _, r, g, b = self:GetQualityFromLink(s.link)
                            if r and g and b then
                                levelText:SetTextColor(r, g, b)
                            end
                            levelText:SetText("[" .. level .. "]")
                        end

                        levelText:Show()
                        levelText:SetWidth(25)
                    else
                        levelText:SetWidth(10)
                    end

                    text = text .. s.name
                    local num, numwbank, numwalts = get_craftable_counts(s)
                    if num > 0 or numwbank > 0 or (numwalts and numwalts > 0) then
                        local count = "[" .. num
                        -- only show bank and alt counts if it has been enabled
                        -- through the options.
                        if self.db.profile.show_bank_alt_counts then
                            count = count .. "/" .. numwbank
                            if numwalts then
                                -- only show this if there is a mod installed that
                                -- allows Stitch to collect the information.
                                count = count .. "/" .. numwalts
                            end
                        end
                        count = count .. "]"
                        countText:SetText(count)
                        countText:Show()
                    end
                    button:SetID(skillIndex)

                    -- If enhanced recipe display is eanbled, show the difficulty as text,
                    -- rather than as a colour. This should help used that have problems
                    -- distinguishing between the difficulty colours we use.
                    if self.db.profile.enhanced_recipe_display then
                        text = text .. skill_color.alttext;
                    end

                    text = text .. (self:GetRecipeNameSuffix(self.currentTrade, skillIndex) or "")
                else
                    nilFound = true
                    -- not cached yet
                end

                buttonText:SetText(text)

                -- update the width we use for checking for text truncation
                local button_width = button:GetTextWidth()
                while button_width > max_text_width do
                    text = string.sub(text, 0, -2)
                    button:SetText(text .. "..")
                    button_width = button:GetTextWidth()
                end

                if ( self.selectedSkill and self.selectedSkill == skillIndex ) then
                    -- user has this skill selected

                    -- This is so mods that call GetTradeSkillSelectionIndex() will work
                    -- tested with ArmorCraft.
                    SelectTradeSkill(self.selectedSkill)

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
                    button:SetBackdropColor(0.8, 0.2, 0.2);
                    button:UnlockHighlight();
                end

                show_button(button, self.currentTrade, skillIndex, i)

            end
        else
            -- We have no data for you Mister Button .....
            hide_button(button, self.currentTrade, skillIndex, i)
            button:UnlockHighlight()
        end
    end

    -- Hide any of the buttons that we created but don't need right now
    for i = button_count+1, num_recipe_buttons, 1 do
        local button = get_recipe_button(i)
        hide_button(button, self.currentTrade, 0, i)
    end

    if nilFound then
        if not AceEvent:IsEventScheduled("Skillet_redo_the_update") then
            AceEvent:ScheduleEvent("Skillet_redo_the_update", 0.25, self)
        end
    end

end

-- Display an action packed tooltip when we are over
-- a recipe in the list of skills
--
-- id is the index of the skill in the currently selected trade.
function Skillet:DisplayTradeskillTooltip(id)

    if id < 0 then
        -- it's header or not cached yet.
        return
    end

    if not self.db.profile.show_detailed_recipe_tooltip then
        -- user does not want the tooltip displayed, it can get a bit big after all
        return
    end

    SkilletTradeskillTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT",-300);
    SkilletTradeskillTooltip:SetBackdropColor(0,0,0,1);
    SkilletTradeskillTooltip:ClearLines();
    SkilletTradeskillTooltip:SetClampedToScreen(true)

    -- Set the tooltip's scale to match that of the default UI
    local uiScale = 1.0;
    if ( GetCVar("useUiScale") == "1" ) then
        uiScale = tonumber(GetCVar("uiscale"))
    end
    SkilletTradeskillTooltip:SetScale(uiScale)

    local s = self.stitch:GetItemDataByIndex(self.currentTrade, id)
    if not s then
        -- this can happen when the recipe is not yet cached
        return
    end

    -- Hyper link for the recipe name, allows a full view of the item without
    -- having to mouse over the item in the detail pane.
    SkilletTradeskillTooltip:SetHyperlink(s.link)

    local num, numwbank, numwalts = get_craftable_counts(s)

    -- how many can be created with the reagents in the inventory
    if num > 0 then
        local text = "\n" .. num .. " " .. L["can be created from reagents in your inventory"];
        SkilletTradeskillTooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end
    -- how many can be created with the reagent in your inv + bank
    if self.db.profile.show_bank_alt_counts and numwbank > 0 and numwbank ~= num then
        local text = numwbank .. " " .. L["can be created from reagents in your inventory and bank"];
        if num == 0 then
            text = "\n" .. text;
        end
        SkilletTradeskillTooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end
    -- how many can be crafted with reagents on *all* alts, including this one.
    if self.db.profile.show_bank_alt_counts and numwalts and numwalts > 0 and numwalts ~= num then
        local text = numwalts .. " " .. L["can be created from reagents on all characters"];
        if num and numwbank == 0 then
            text = "\n" .. text;
        end
        SkilletTradeskillTooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end

    SkilletTradeskillTooltip:AddLine("\n" .. self:GetReagentLabel(self.currentTrade, id));

    -- now the list of regents for this recipe and some info about them
    for i=1, 20, 1 do
        local reagent = s[i];
        if not reagent then
            break
        end

        local text = "  " .. reagent.needed .. " x " .. reagent.name;
        local reagent_counts = GRAY_FONT_COLOR_CODE .. " (" .. reagent.num .. " / " .. (reagent.numwbank - reagent.num)
        if reagent.numwalts then
            -- numwalts includes this character, we want only alts
            reagent_counts = reagent_counts .. " / " .. math.max(0, reagent.numwalts - reagent.numwbank)
        end
        reagent_counts = reagent_counts .. ")" .. FONT_COLOR_CODE_CLOSE
        if reagent.vendor == true then
            text = text .. GRAY_FONT_COLOR_CODE .. "  (" .. L["buyable"] .. ")" .. FONT_COLOR_CODE_CLOSE;
        end

        SkilletTradeskillTooltip:AddDoubleLine(text, reagent_counts, 1, 1, 1);
    end

    -- The legend at the bottom
    text =  "(" .. L["reagents in inventory"] .. " / " .. L["bank"]
    if s.numcraftablewalts ~= nil then
        text = text .. " / " .. L["alts"]
    end
    text = text .. ")"
    SkilletTradeskillTooltip:AddDoubleLine("\n", text)

    -- Do any mods want to add extra info about this recipe?
    local extra_text = self:GetExtraItemDetailText(self.currentTrade, id)
    if extra_text then
        SkilletTradeskillTooltip:AddLine("\n" .. extra_text)
    end

    SkilletTradeskillTooltip:Show();

end

-- Sets the game tooltip item to the selected skill
-- (and reagent at index if not nil)
function Skillet:SetTradeSkillToolTip(skill, index)
    GameTooltip:ClearLines();

    if index then
        GameTooltip:SetTradeSkillItem(skill, index)
    else
        GameTooltip:SetTradeSkillItem(skill)
    end

    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill);

    -- Can the item be obtained from a vendor? Let the user know!
    if s and index and s[index].vendor == true then
        GameTooltip:AppendText(GRAY_FONT_COLOR_CODE .. " (" .. L["buyable"] .. ")" .. FONT_COLOR_CODE_CLOSE);
    end

end

-- Updates the details window with information about the currently selected skill
function Skillet:UpdateDetailsWindow(skill_index)
    if not skill_index or skill_index < 0 then
        SkilletSkillName:SetText("")
        SkilletSkillCooldown:SetText("")
        SkilletRequirementLabel:Hide()
        SkilletRequirementText:SetText("")
        SkilletSkillIcon:Hide()
        SkilletReagentLabel:Hide()
        SkilletRecipeNotesButton:Hide()
        SkilletPreviousItemButton:Hide()
        SkilletExtraDetailText:Hide()

        SkilletHighlightFrame:Hide()
        SkilletFrame.selectedSkill = -1;


        -- Always want these set.
        SkilletItemCountInputBox:SetText("1");
        SkilletCreateCountSlider:SetMinMaxValues(1, 20);
        SkilletCreateCountSlider:SetValue(1);

        for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
            local button = getglobal("SkilletReagent"..i)
            button:Hide();
        end
        return
    end

    SkilletFrame.selectedSkill = skill_index;
    self.numItemsToCraft = 1;

    if self.recipeNotesFrame then
        self.recipeNotesFrame:Hide()
    end

    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill_index)

    -- Name of the skill
    SkilletSkillName:SetText(s.name);
    SkilletRecipeNotesButton:Show();

    -- Whether or not it is in cooldown.
    local cooldown = GetTradeSkillCooldown(skill_index)
    if cooldown and cooldown > 0 then
        SkilletSkillCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(cooldown))
    else
        SkilletSkillCooldown:SetText("")
    end

    -- Are special tools needed for this skill?
    if s.tools then
        -- can't use s.tools here as GetCraftSpellFocus() needs an
        -- index rather than a name so it can do the lookups to see
        -- if we have the required item
        local text = BuildColoredListString(GetTradeSkillTools(skill_index))

        SkilletRequirementText:SetText(text)
        SkilletRequirementLabel:Show()
    else
        SkilletRequirementLabel:Hide()
    end

    SkilletSkillIcon:SetNormalTexture(s.texture)
    SkilletSkillIcon:Show()

    -- How many of these items are produced at one time ..
    if s.nummade > 1 then
        SkilletSkillIconCount:SetText(s.nummade)
        SkilletSkillIconCount:Show()
    else
        SkilletSkillIconCount:SetText("")
        SkilletSkillIconCount:Hide()
    end

    -- How many can we queue/create?
    SkilletCreateCountSlider:SetMinMaxValues(1, max(20, s.numcraftablewbank));
    SkilletCreateCountSlider:SetValue(self.numItemsToCraft);
    SkilletItemCountInputBox:SetText("" .. self.numItemsToCraft);
    SkilletCreateCountSlider.tooltipText = L["Number of items to queue/create"];

    -- Reagents required ...
    SkilletReagentLabel:SetText(self:GetReagentLabel(SkilletFrame.selectedSkill));
    SkilletReagentLabel:Show();

    local width = SkilletReagentParent:GetWidth()

    for i=1, SKILLET_NUM_REAGENT_BUTTONS, 1 do
        local button = getglobal("SkilletReagent"..i)
        local   text = getglobal(button:GetName() .. "Text");
        local   icon = getglobal(button:GetName() .. "Icon");
        local  count = getglobal(button:GetName() .. "Count");

        local reagent = s[i];

        if reagent then
            local num = reagent.num

            local count_text = string.format("%d/%d", num, reagent.needed)
            if ( num < reagent.needed ) then
                -- grey it out if we don't have it.
                count:SetText(GRAY_FONT_COLOR_CODE .. count_text .. FONT_COLOR_CODE_CLOSE)
                text:SetText(GRAY_FONT_COLOR_CODE .. reagent.name .. FONT_COLOR_CODE_CLOSE)
            else
                -- ungrey it
                count:SetText(count_text)
                text:SetText(reagent.name)
            end

            icon:SetNormalTexture(reagent.texture)

            button:SetWidth(width - 20)
            button:Show()
        else
            -- out of necessary reagents, don't need to show the button,
            -- or any or the text.
            button:Hide()
        end

    end

    if self.db.profile.link_craftable_reagents and #previousRecipies > 0 then
        SkilletPreviousItemButton:Show()
    else
        SkilletPreviousItemButton:Hide()
    end

    -- Do any mods want to add extra info to the details window?
    local extra_text = self:GetExtraItemDetailText(self.currentTrade, skill_index)
    if extra_text then
        SkilletExtraDetailText:SetText(extra_text)
        SkilletExtraDetailText:Show()
    else
        SkilletExtraDetailText:Hide()
    end

end

local num_queue_buttons = 0
local function get_queue_button(i)
    local button = getglobal("SkilletQueueButton"..i)
    if not button then
        button = CreateFrame("Button", "SkilletQueueButton"..i, SkilletQueueParent, "SkilletQueueItemButtonTemplate")
        button:SetParent(SkilletQueueParent)
        button:SetPoint("TOPLEFT", "SkilletQueueButton"..(i-1), "BOTTOMLEFT")
        button:SetFrameLevel(SkilletQueueParent:GetFrameLevel() + 1)
    end
    return button
end

-- Updates the window/scroll list displaying queue of items
-- that are waiting to be crafted.
function Skillet:UpdateQueueWindow()
    local queue = self.stitch:GetQueueInfo();
    if not queue then
        SkilletStartQueueButton:SetText(L["Start"])
        SkilletEmptyQueueButton:Disable()
        SkilletStartQueueButton:Disable()
        return
    end

    local numItems = #queue;

    if numItems > 0 then
        SkilletStartQueueButton:Enable()
        SkilletEmptyQueueButton:Enable()
    else
        SkilletStartQueueButton:Disable()
        SkilletEmptyQueueButton:Disable()
    end

    if self.stitch.queuecasting then
        SkilletStartQueueButton:SetText(L["Pause"])
    else
        SkilletStartQueueButton:SetText(L["Start"])
    end

    local button_count = SkilletQueueList:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
    button_count = math.floor(button_count)

    -- Update the scroll frame
    FauxScrollFrame_Update(SkilletQueueList,                -- frame
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
        local countFrame   = getglobal(button:GetName() .. "Count")
        local queueCount   = getglobal(button:GetName() .. "CountText")
        local nameFrame    = getglobal(button:GetName() .. "Name")
        local queueName    = getglobal(button:GetName() .. "NameText")
        local deleteButton = getglobal(button:GetName() .. "DeleteButton")

        button:SetWidth(width)

        -- Stick this on top of the button we use for displaying queue contents.
        deleteButton:SetFrameLevel(button:GetFrameLevel() + 1)

        local fixed_width = countFrame:GetWidth() + deleteButton:GetWidth()
        fixed_width = width - fixed_width - 10 -- 10 for the padding between items

        queueName:SetWidth(fixed_width);
        nameFrame:SetWidth(fixed_width);

        if itemIndex <= numItems then

            deleteButton:SetID(itemIndex)

            local s = self.stitch:GetQueueItemInfo(itemIndex)

            if s then
                queueName:SetText(s.name)
                queueCount:SetText(queue[itemIndex]["numcasts"]) --ick, can't find an API call for this.
            end

            nameFrame:Show()
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

-- When one of the skill buttons in the left scroll pane is clicked
function Skillet:SkillButton_OnClick(button)
    if(button=="LeftButton") then
        local id = this:GetID();
        if id == -1 then
            -- header clicked / toggle collapsed state
            local buttonText = getglobal(this:GetName() .. "Name")
            local header = buttonText:GetText()
            local state = self.headerCollapsedState[header]

            if not state or state == false then
                self.headerCollapsedState[header] = true
            else
                self.headerCollapsedState[header] = false
            end
        else
            -- skill clicked
            self:SetSelectedSkill(id, true);

            -- if it was shift-left clicked *and* there is a chat edit
            -- window open, insert the recipe link.
            if IsShiftKeyDown() and (ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus ~= nil) then
                ChatEdit_InsertLink(self:GetTradeSkillRecipeLink(id));
            end
        end

        self:UpdateTradeSkillWindow()
    end
end

-- Go to the previous recipe in the history list.
function Skillet:GoToPreviousRecipe()
    local itemID = table.remove(previousRecipies)
    if itemID then
        self:SetSelectedSkill(itemID);
    end
end

-- Called when then mouse enters a reagent button
function Skillet:ReagentButtonOnEnter(button, skill, index)
    if not self.db.profile.link_craftable_reagents then
        return
    end

    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill)
    local reagent = s[index];

    local can_craft = self.stitch:GetItemDataByName(reagent.name);

    if can_craft then
        local icon = getglobal(button:GetName() .. "Icon")
        gearTexture:SetParent(icon)
        gearTexture:ClearAllPoints()
        gearTexture:SetPoint("TOPLEFT", icon)
        gearTexture:Show()
    end
end

-- called then the mouse leaves a reagent button
function Skillet:ReagentButtonOnLeave(button, skill, index)
    gearTexture:Hide()
end

-- Called when the reagent button is clicked
function Skillet:ReagentButtonOnClick(button, skill, index)
    if not self.db.profile.link_craftable_reagents then
        return
    end

    -- current recipe -> selected reagent --> reagent item link
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill)

    local reagent = self.stitch:GetItemDataByName(s[index].name);

    if reagent then
        -- we know how to make this, we just need to figure out
        -- what the *index* of the item is. That is not stored in
        -- the stitch library.

        for i=1, self:GetNumTradeSkills(), 1 do
            local item = self.stitch:GetItemDataByIndex(self.currentTrade, i)
            if item and item.link == reagent.link then
                table.insert(previousRecipies, skill)
                gearTexture:Hide()
                self:SetSelectedSkill(i)
                return
            end
        end
    end
end

-- The start/pause queue button.
function Skillet:StartQueue_OnClick(button)
    if self.stitch.queuecasting then
        self.stitch.queuecasting = false
        self.stitch:CancelCast() -- next update will reset the text
        button:Disable()
    else
        button:SetText(L["Pause"])
        self:ProcessQueue()
    end
end

-- Updates the "Scanning tradeskill" text area with provided text
-- Set nil/empty text to hide the area
function Skillet:UpdateScanningText(text)
    local area = getglobal("SkilletFrameScanningText")
    if area then
        if text and string.len(text) > 0 then
            area:SetText(text)
            area:Show()
        else
            area:Hide()
        end
    end
end

local old_CloseSpecialWindows

local orig_tradeskill_settings = {}
local orig_craft_settings = {}

-- Hides a Blizzard tradeskill or craft skill frame by making
-- it transparent, setting it to the background, and attaching
-- it to the Skillet frame
local function hide_blizz(frame, settings)
    settings["strata"] = frame:GetFrameStrata()
    settings["alpha"]  = frame:GetAlpha()
    settings["width"]  = frame:GetWidth()
    settings["height"]  = frame:GetHeight()

    frame:SetAlpha(0)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetPoint("TOPLEFT", SkilletFrame, "TOPLEFT", 5, -5)
    frame:SetWidth(5)
    frame:SetHeight(5)
end

-- restores a Blizzard trade or craft skill frame from the
-- provided settings.
local function restore_blizz(frame, settings)
    if settings["alpha"] then
        frame:SetAlpha(settings["alpha"])
    end
    if settings["strata"] then
        frame:SetFrameStrata(settings["strata"])
    end
    if settings["width"] then
        frame:SetWidth(settings["width"])
    end
    if settings["height"] then
        frame:SetHeight(settings["height"])
    end
    frame:ClearAllPoints()
end

-- Called when the trade skill window is shown
function Skillet:Tradeskill_OnShow()
    -- Get rid of Blizzards windows. This can happen when the user
    -- changes from a skill that we do not support to one that we do.
    if TradeSkillFrame and TradeSkillFrame:IsVisible() then
        -- Can't really hide the frame as that has some nasty side effects
        -- like setting the current craft to UNKNOWN and causing bad results
        -- from GetTradeSkillLine() et al.
        hide_blizz(TradeSkillFrame, orig_tradeskill_settings)
    end

    -- Need to hook this so that hitting [ESC] will close the Skillet window(s).
    if not old_CloseSpecialWindows then
        old_CloseSpecialWindows = CloseSpecialWindows
        CloseSpecialWindows = function()
            local found = old_CloseSpecialWindows()
            return self:HideAllWindows() or found
        end
    end
end

-- Called when the trade skill window is hidden
function Skillet:Tradeskill_OnHide()
    if TradeSkillFrame then
        restore_blizz(TradeSkillFrame, orig_tradeskill_settings)
    end
end
