--[[

Skillet: A tradeskill window replacement.
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

local skill_style_type = {
    ["optimal"]         = { r = 1.00, g = 0.50, b = 0.25, level = 4},
    ["medium"]          = { r = 1.00, g = 1.00, b = 0.00, level = 3},
    ["easy"]            = { r = 0.25, g = 0.75, b = 0.25, level = 2},
    ["trivial"]         = { r = 0.50, g = 0.50, b = 0.50, level = 1},
    ["header"]          = { r = 1.00, g = 0.82, b = 0,    level = 0},
}

-- list of possible sorting methods
local sorters = {}

local recipe_sort_method = nil

local function sort_recipe_by_name(tradeskill, a, b, stitch_left, stitch_right)
    local  left_r = stitch_left  or Skillet.stitch:GetItemDataByIndex(tradeskill, a)
    local right_r = stitch_right or Skillet.stitch:GetItemDataByIndex(tradeskill, b)

    -- Theoretically, we should never get a nil here, but I'm
    -- still having fundemental problems getting recipe information
    -- from Blizzard sometimes ....
    if not left_r and right_r then
        return false
    elseif not right_r and left_r then
        return true
    elseif not left_r and not right_r then
        return true
    end

    return left_r.name < right_r.name
end

local function sort_recipe_by_difficulty(tradeskill, a, b, stitch_left, stitch_right)
    local __, left_skillType = Skillet:GetTradeSkillInfo(a)
    local _, right_skillType = Skillet:GetTradeSkillInfo(b)

    -- Theoretically, we should never get a nil here, but I'm
    -- still having fundemental problems getting recipe information
    -- from Blizzard sometimes ....
    if not left_skillType and right_skillType then
        return false
    elseif not right_skillType and left_skillType then
        return true
    elseif not left_skillType and not right_skillType then
        return true
    end

    local left  = skill_style_type[left_skillType].level
    local right = skill_style_type[right_skillType].level

    -- hardest recipes at the top
    if left == right then
        -- same level, sort by name
        return sort_recipe_by_name(tradeskill, a, b, stitch_left, stitch_right)
    else
        return left < right
    end
end

local function sort_by_required_level(tradeskill, a, b, stitch_left, stitch_right)
    local  left_r = stitch_left  or Skillet.stitch:GetItemDataByIndex(tradeskill, a)
    local right_r = stitch_right or Skillet.stitch:GetItemDataByIndex(tradeskill, b)

    -- Theoretically, we should never get a nil here, but I'm
    -- still having fundemental problems getting recipe information
    -- from Blizzard sometimes ....
    if not left_r and right_r then
        return false
    elseif not right_r and left_r then
        return true
    elseif not left_r and not right_r then
        return true
    end

    left  = Skillet:GetLevelRequiredToUse(left_r.link)
    right = Skillet:GetLevelRequiredToUse(right_r.link)

    if not left  then  left = 0 end
    if not right then right = 0 end

    if left == right then
        -- same level, sort by difficulty
        return sort_recipe_by_difficulty(tradeskill, a, b, left_r, right_r)
    else
        return left < right
    end
end

local function sort_by_item_quality(tradeskill, a, b, stitch_left, stitch_right)
    local  left_r = stitch_left  or Skillet.stitch:GetItemDataByIndex(tradeskill, a)
    local right_r = stitch_right or Skillet.stitch:GetItemDataByIndex(tradeskill, b)

    -- Theoretically, we should never get a nil here, but I'm
    -- still having fundemental problems getting recipe information
    -- from Blizzard sometimes ....
    if not left_r and right_r then
        return false
    elseif not right_r and left_r then
        return true
    elseif not left_r and not right_r then
        return true
    end

     left = select(1, Skillet:GetQualityFromLink(left_r.link))
    right = select(1, Skillet:GetQualityFromLink(right_r.link))

    if not left  then  left = 0 end
    if not right then right = 0 end

    if left == right then
        -- same level, sort by level required to use
        return sort_by_required_level(tradeskill, a, b, left_r, right_r)
    else
        return left < right
    end

end

local function NOSORT(tradeskill, a, b)
    return true
end

local sorted_recipes = {}
local last_num_trade_skills = 0
local last_trade_skill = nil
local last_recipe_sort_method = nil
-- Builds a sorted list of recipes (no headers) for the
-- currently selected tradekskill and sorting method
local function sort_recipes()

    local num_skills = Skillet:GetNumTradeSkills()

    if recipe_sort_method == last_recipe_sort_method then
        if last_trade_skill == Skillet.currentTrade then
            if num_skills <= last_num_trade_skills then
                -- because of the goofy way tradekskill window updates are
                -- done, we may get a 'redisplay' request for a new skill
                -- before the 'ResetWindow' is done.
                --
                -- We only care about the case where there are fewer skills in
                -- the new tradeksill as that will cause the sorting to blow up.
                -- if there are more, we don't care as that will leave us with a
                -- partially sorted list they we end up resorting anyway
                return
            end
        end
    end

    sorted_recipes = {}

    last_num_trade_skills = num_skills
    last_trade_skill = Skillet.currentTrade
    last_recipe_sort_method = recipe_sort_method

    local button_index = 1
    if Skillet:AreRecipesSorted() then
        for i=1, num_skills, 1 do
            local _, skillType = Skillet:GetTradeSkillInfo(i)
            if skillType ~= "header" then
                -- only add recipes, not headers. Headers are never displayed
                -- when we are showing a sorted list.
                sorted_recipes[button_index] = i
                button_index = button_index + 1
            end
        end

        table.sort(sorted_recipes, function(a,b)
            return recipe_sort_method(Skillet.currentTrade, a, b)
        end)

    end
end

local function set_sort_desc(toggle)
    for _,entry in pairs(sorters) do
        if entry.sorter == recipe_sort_method then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "sortdesc-" .. entry.name, toggle)
        end
    end
end

local function is_sort_desc()
    for _,entry in pairs(sorters) do
        if entry.sorter == recipe_sort_method then
            return Skillet:GetTradeSkillOption(Skillet.currentTrade, "sortdesc-" .. entry.name)
        end
    end

    -- default to true
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

--
-- Adds the sorting routine to the list of sorting routines.
--
function Skillet:internal_AddRecipeSorter(text, sorter)
    assert(text and tostring(text),
           "Usage Skillet:AddRecipeSorter(text, sorter), text must be a string")
    assert(sorter and type(sorter) == "function",
           "Usage Skillet:AddRecipeSorter(text, sorter), sorter must be a function")
    table.insert(sorters, {["name"]=text, ["sorter"]=sorter})
end

function Skillet:InitializeSorting()
    -- Default sorting methods
    -- We don't go through the public API for this as we want our methods
    -- to appear first in the list, no matter what.
    table.insert(sorters, 1, {["name"]=L["None"], ["sorter"]=NOSORT})
    table.insert(sorters, 2, {["name"]=L["By Name"], ["sorter"]=sort_recipe_by_name})
    table.insert(sorters, 3, {["name"]=L["By Difficulty"], ["sorter"]=sort_recipe_by_difficulty})
    table.insert(sorters, 4, {["name"]=L["By Level"], ["sorter"]=sort_by_required_level})
    table.insert(sorters, 5, {["name"]=L["By Quality"], ["sorter"]=sort_by_item_quality})

    recipe_sort_method = NOSORT

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
-- True if the list of recipes is sorted and false if it is not.
--
function Skillet:AreRecipesSorted()
    return recipe_sort_method and recipe_sort_method ~= NOSORT
end

--
-- Causes the list of recipes to be resorted
--
function Skillet:internal_ResortRecipes(force)
    if force then
        -- this will trigger a resort
        last_num_trade_skills = 0
    end

    sort_recipes()
end

--
-- If the recipe list is sorted, maps from the provided index to
-- the sorted index.
--
function Skillet:GetSortedRecipeIndex(index)
    if self:AreRecipesSorted() then
        if not is_sort_desc() then
            -- +1 is becuse lua arrays are 1-based, not 0-based.
            index = #sorted_recipes + 1 - index
        end
        return sorted_recipes[index]
    else
        return index
    end
end

--
-- Returns the list of sorted recipes for the current trade skill
--
function Skillet:GetSortedRecipes()
    return sorted_recipes
end

-- called when the sort drop down is first loaded
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

end

-- Called when the sort drop down is displayed
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

-- The method we use the initialize the sorting drop down.
function Skillet:SortDropdown_Initialize()
    recipe_sort_method = NOSORT

    local info
    local i = 0
    for i=1, #sorters, 1 do
        local entry = sorters[i]
        info = UIDropDownMenu_CreateInfo()

        info.text = entry.name
        if entry.name == Skillet:GetTradeSkillOption(Skillet.currentTrade, "sortmethod") then
            recipe_sort_method = entry.sorter
        end

        info.func = Skillet.SortDropdown_OnClick
        info.value = i
        i = i + 1
        info.owner = this:GetParent()
        UIDropDownMenu_AddButton(info)
    end

    -- can't calls show_sort_toggle() here as the sort
    -- buttons have not been created yet

end

-- Called when the user selects an item in the sorting drop down
function Skillet:SortDropdown_OnClick()
    UIDropDownMenu_SetSelectedID(SkilletSortDropdown, this:GetID())
    local entry = sorters[this:GetID()]

    Skillet:SetTradeSkillOption(Skillet.currentTrade, "sortmethod", entry.name)

    recipe_sort_method = entry.sorter

    show_sort_toggle()

    Skillet:ResortRecipes(force)
    Skillet:UpdateTradeSkillWindow()


end
