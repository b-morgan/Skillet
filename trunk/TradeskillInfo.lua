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

-- This file contains all the code I use to access recipe/tradeskill information

-- If an item requires a specific level before it can be used, then
-- the level is returned, otherwise 0 is returned
--
-- item can be: itemID or "itemString" or "itemName" or "itemLink"
function Skillet:GetLevelRequiredToUse(item)
    local level = select(5, GetItemInfo(item))
    if not level then level = 0 end
    return level
end

-- Extracts the numeric item id from an item link
function Skillet:GetItemIDFromLink(link)
    local id
    if link then
        _,_,id = string.find(link, "|Hitem:(%d+):")
    end

    if link and not id then
        -- might be an enchant ...
        _,_,id = string.find(link, "|Henchant:(%d+)|")
    end

    if id then id = tonumber(id) end

    return id
end

-- Wrapper that calls the correct Get*Info for crafts and trades as appropriate
function Skillet:GetTradeSkillInfo(index)
    if (not index) then return end

    return GetTradeSkillInfo(index)
end

--
-- Checks a link and returns the level of the that item's quality. If the link is
-- invalid, or not item quality could be found, nil is returned.
--
-- Handy info: getglobal("ITEM_QUALITY" .. level .. "_DESC") returns "Epic", etc (localized)
--
-- @return
--     level: from 0 (Poor) to 7 (Heirloom).
--     r, g, b: color code for the items color
--     hex: hexidecimal representation of the string, as well as "|c" in the beginning.
function Skillet:GetQualityFromLink(link)
    if (not link) then return end

    local _, _, rarity = GetItemInfo(link)
    if rarity then
        return rarity, GetItemQualityColor(rarity)
    end

    -- no match
end

-- Returns a link for the currently selected tradeskill item.
-- The input is an index into the currently selected tradeskill
-- or craft.
function Skillet:GetTradeskillItemLink(index)
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, index);
    local result = nil;

    if s then
        result = s.link
    end

    return result;
end

-- Returns a link for the reagent required to create the specified
-- item, the index'th reagent required for the item is returned
function Skillet:GetTradeSkillReagentItemLink(skill, index)
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill);
    local result = nil;

    if s then
        local reagent = s[index];
        if reagent then
            result = reagent.link
        end
    end

    return result;
end

-- Gets a link to the recipe (not the item creafted by the recipe)
-- for the current tradeskill
function Skillet:GetTradeSkillRecipeLink(index)
    return GetTradeSkillRecipeLink(index);
end

-- Gets the trade skill line, and knows how to do the right
-- thing depending on whether or not this is a craft.
function Skillet:GetTradeSkillLine()
    local tradeskillName, currentLevel, maxLevel = GetTradeSkillLine()
    if(tradeskillName==nil) then
        tradeskillName = "";
    end
    return tradeskillName, currentLevel, maxLevel;
end

-- Returns the number of trade or craft skills
function Skillet:GetNumTradeSkills()
    local stitch_count = self.stitch:GetNumSkills(self.currentTrade)
    if not stitch_count then
        stitch_count = 0
    end

    local blizz_count = GetNumTradeSkills()

    return math.max(stitch_count, blizz_count)
end

-- =====================================================================
--                      TradeSkill Query API
-- =====================================================================

local characters

local function build_reagents(self, s, reagent)
    local r = {
        name = reagent.name,
        link = reagent.link,
        needed = reagent.needed,
        texture = reagent.texture,
    }

    return r
end

local function build_skills(self, name, prof, skill_index)
    local s = self.stitch:DecodeRecipe(self.db.server.recipes[name][prof][skill_index])
    local c = {
        name = s.name,
        link = s.link,
        texture = s.texture,
        difficulty = s.difficulty,
        numname = s.nummade or 1,
        count = #s
    }

    for i=1, #s, 1 do
        table.insert(c, build_reagents(self, s, s[i]))
    end

    return c
end

local function build_profs(self, name, prof)
    local c = {name = prof}

    for skill, _ in pairs(self.db.server.recipes[name][prof]) do
        if self.db.server.recipes[name][prof][skill] ~= nil then
            table.insert(c, build_skills(self, name, prof, skill))
        end
    end

    return c
end

local function build_character(self, name)
    local c = {name = name}

    for prof, _ in pairs(self.db.server.recipes[name]) do
        if prof and prof ~= "" and prof ~= "UNKNOWN" then
            table.insert(c, build_profs(self, name, prof))
        end
    end

    return c
end

local function build_characters(self)
    local c = {}

    for name, _ in pairs(self.db.server.recipes) do
        table.insert(c, build_character(self, name))
    end

    return c
end

function Skillet:internal_ResetCharacterCache()
    characters = nil
    Skillet:internal_GetCharacters()
end

function Skillet:internal_GetCharacters()
    if not characters then
        characters = build_characters(self)
    end

    return characters
end

function Skillet:internal_GetCharacterProfessions(character_name)
    local chars = self:internal_GetCharacters()

    for i=1, #chars, 1 do
        if chars[i].name == character_name then
            return chars[i]
        end
    end
end

function  Skillet:internal_GetCharacterTradeskills(character_name, profession)
    local profs = self:internal_GetCharacterProfessions(character_name)

    if profs then
        for i=1, #profs, 1 do
            if profs[i].name == profession then
                return profs[i]
            end
        end
    end
end

function Skillet:internal_GetCraftersForItem(itemId)
	local crafters = nil

	local chars = self:internal_GetCharacters()
	for i=1, #chars, 1 do
		local profs = self:internal_GetCharacterProfessions(chars[i].name)
		local found = false

		for j=1,#profs,1 do
			local skills = self:internal_GetCharacterTradeskills(chars[i].name, profs[j].name)
			for k=1,#skills,1 do
				if self:GetItemIDFromLink(skills[k].link) == itemId then
					if not crafters then crafters = {} end
					table.insert(crafters, chars[i].name)
					found = true
					break
				end
			end
			if found then break end
		end

	end

	return crafters
end
