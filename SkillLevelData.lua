local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
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

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

local PT = LibStub("LibPeriodicTable-3.1")

local skillColors = {
	["unknown"]			= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]			= { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]			= { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",	cstring = "|cffffff00"},
	["easy"]			= { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",	cstring = "|cff40c000"},
	["trivial"]			= { r = 0.60, g = 0.60, b = 0.60, level = 1, alttext="",	cstring = "|cff909090"},
	["header"]			= { r = 1.00, g = 0.82, b = 0,	  level = 0, alttext="",	cstring = "|cffffc800"},
	["unavailable"]		= { r = 0.3, g = 0.3, b = 0.3,	  level = 6, alttext="",	cstring = "|cff606060"},
}

--
-- function InitializeSkillLevels (which loads Skillet.db.global.SkillLevels) is 
-- at the end of this file.
--
-- Skillet-Classic table was scraped from https://wotlk.wowhead.com/, Skillet from https://www.wowhead.com/
-- using ScrapeWowhead.js (follow instructions in file)
-- provided and maintained by Matthew Hively, https://github.com/matthewhively, matthewhively@viz.com
--

--
-- Table of racial bonuses (including retail)
--
local racialList = {
	[4036]  = {["Gnome"] = 15,				-- engineering
			   ["KulTiran"] = 5},
	[7411]  = {["BloodElf"] = 10,			-- enchanting
			   ["KulTiran"] = 5},
	[25229] = {["Draenei"] = 5,				-- jewelcrafting
			   ["KulTiran"] = 5},
	[2259]  = {["Goblin"] = 15,				-- alchemy
			   ["KulTiran"] = 5},
	[2018]  = {["LightforgedDraenei"] = 15,	-- blacksmithing
			   ["DarkIronDwarf"] = 5,
			   ["KulTiran"] = 5},
	[45357] = {["Nightborne"] = 15,			-- inscription
			   ["KulTiran"] = 5},
	[2550]  = {["Pandaren"] = 15},			-- cooking
}

local function getSpellName(spell)
	if isRetail then
		return C_Spell.GetSpellName(spell)
	else
		return GetSpellInfo(spell)
	end
end

--
-- local function returns any racial bonus that may apply
--
local function getRacialBonus()
	local player = Skillet.currentPlayer
	local trade = Skillet.currentTrade
	local race = Skillet.db.realm.race[player]
	--DA.DEBUG(0,"getRacialBonus: trade = "..tostring(trade).." ("..tostring(getSpellName(trade)).."), race= "..tostring(race))
	if racialList[trade] then
		for r, bonus in pairs(racialList[trade]) do
			--DA.DEBUG(1,"getRacialBonus: r = "..tostring(r)..", bonus= "..tostring(bonus))
			if r == race then
			DA.DEBUG(1,"getRacialBonus: bonus = "..tostring(bonus))
				return bonus
			end
		end
	end
	return 0
end

local a,b,c,d,e,f,g,h

local function compareLevels(levelsWowhead, levelsByRecipe)
--
-- Compare the sources
--				
	DA.DEBUG(0,"compareLevels: levelsWowhead= "..tostring(levelsWowhead))
	DA.DEBUG(0,"compareLevels: levelsByRecipe= "..tostring(levelsByRecipe))
	local rb = getRacialBonus()
	if levelsWowhead and type(levelsWowhead) == 'string' then
		a,b,c,d = string.split("/", levelsWowhead)
		a = (tonumber(a) or 0) + rb
		b = (tonumber(b) or 0) + rb
		c = (tonumber(c) or 0) + rb
		d = (tonumber(d) or 0) + rb
		Skillet.sourceTradeSkillLevel = 1
	end
	if levelsByRecipe and type(levelsByRecipe) == 'string' then
		e,f,g,h = string.split("/", levelsByRecipe)
		e = (tonumber(e) or 0) + rb
		f = (tonumber(f) or 0) + rb
		g = (tonumber(g) or 0) + rb
		h = (tonumber(h) or 0) + rb
	end
--
-- For debugging, report the differences
--
	local diff = false
	if a ~= e then
		--DA.DEBUG(1,"compareLevels: a= "..tostring(a)..", e= "..tostring(e))
	end
	if b ~= f then
		--DA.DEBUG(1,"compareLevels: b= "..tostring(b)..", f= "..tostring(f))
		diff = true
	end
	if c ~= g then
		--DA.DEBUG(1,"compareLevels: c= "..tostring(c)..", g= "..tostring(g))
		diff = true
	end
	if d ~= h then
		--DA.DEBUG(1,"compareLevels: d= "..tostring(b)..", h= "..tostring(h))
		diff = true
	end
--
-- Choose the best value(s)
-- levelsWowhead will be nil if there is no Wowhead data
-- levelsByRecipe will be nil if CraftInfoAnywhere is not loaded or the Wago Tools table(s) have no data
-- if both values are available, Wowhead orange value is more accurate than the Wago Tools data
--
	if levelsWowhead and levelsByRecipe then
		if Skillet.db.profile.baseskilllevel then
			a = e
		end
		b = f
		c = g
		d = h
		--DA.DEBUG(1,"compareLevels: levelsReturned= "..tostring(a).."/"..tostring(b).."/"..tostring(c).."/"..tostring(d))
		Skillet.sourceTradeSkillLevel = 2
		return 1
	elseif levelsWowhead then
		--DA.DEBUG(1,"compareLevels: levelsReturned= "..tostring(a).."/"..tostring(b).."/"..tostring(c).."/"..tostring(d))
		Skillet.sourceTradeSkillLevel = 2
		return 1
	elseif levelsByRecipe then
		--DA.DEBUG(1,"compareLevels: levelsReturned= "..tostring(e).."/"..tostring(f).."/"..tostring(g).."/"..tostring(h))
		Skillet.sourceTradeSkillLevel = 2
		return 2
	end
	return 0
end

--
-- Get TradeSkill Difficulty Levels
--
-- Note: MainFrame.lua uses both inputs, other calls just use itemID.
--
function Skillet:GetTradeSkillLevels(itemID, spellID)
	DA.DEBUG(0,"GetTradeSkillLevels("..tostring(itemID)..", "..tostring(spellID)..")")
	local rb = getRacialBonus()
	local skillLevels = Skillet.db.global.SkillLevels
	local levels
	local SkillLineAbility = Skillet.db.global.SkillLineAbility
	local possibleRecipes, recipeID, levelsByRecipe
	if itemID and type(itemID) == 'number' and itemID ~= 0 then 
--
-- The CraftInfoAnywhere (https://www.curseforge.com/wow/addons/craft-info-anywhere) API
-- is used to get the recipeID that produces this itemID
--
-- (for now, use the last value returned)
--
		if CraftInfoAnywhere and CraftInfoAnywhere.API then
			possibleRecipes = CraftInfoAnywhere.API.GetRecipesForItem(itemID)
			if possibleRecipes ~= nil then
				recipeID = possibleRecipes[#possibleRecipes]
			end
--
-- Use the appropriate table to find the data
--
		end
		levelsByRecipe = SkillLineAbility[recipeID]
--
-- If there is an entry in our own table(s), use it
--
		if skillLevels then
--
-- The data from Wowhead is not specific to the game version
--
			if skillLevels[itemID] or skillLevels[-itemID] then
				if skillLevels[itemID] then
					levels = skillLevels[itemID]
				else
					levels = skillLevels[-itemID]
				end
				if type(levels) == 'table' then
					if spellID then
						if isRetail then
							levels = skillLevels[itemID][spellID]
						else
							for spell, strng in pairs(levels) do
								name = getSpellName(spell)
								--DA.DEBUG(1,"GetTradeSkillLevels: name= "..tostring(name))
								if name == spellID then
									levels = strng
									break
								end
							end
						end
					end
				end
			end
		end
		local r = compareLevels(levels,levelsByRecipe)
		if r == 1 then
			return a,b,c,d
		elseif r == 2 then
			return e,f,g,h
		end
--
-- The TradeskillInfo addon seems to be more accurate than LibPeriodicTable-3.1
--
		if isRetail and TradeskillInfo then
			local recipeSource = Skillet.db.global.itemRecipeSource[itemID]
			if not recipeSource then
				--DA.DEBUG(1,"GetTradeSkillLevels: itemID= "..tostring(itemID)..", recipeSource= "..tostring(recipeSource))
				recipeSource = Skillet.db.global.itemRecipeSource[-itemID]
			end
			if type(recipeSource) == 'table' then
				--DA.DEBUG(1,"GetTradeSkillLevels: itemID= "..tostring(itemID)..", recipeSource= "..DA.DUMP1(recipeSource))
				for recipeID in pairs(recipeSource) do
					--DA.DEBUG(2,"GetTradeSkillLevels: recipeID= "..tostring(recipeID))
					local TSILevels = TradeskillInfo:GetCombineDifficulty(recipeID)
					if type(TSILevels) == 'table' then
						--DA.DEBUG(2,"GetTradeSkillLevels: TSILevels="..DA.DUMP1(TSILevels))
						a = (tonumber(TSILevels[1]) or 0) + rb
						b = (tonumber(TSILevels[2]) or 0) + rb
						c = (tonumber(TSILevels[3]) or 0) + rb
						d = (tonumber(TSILevels[4]) or 0) + rb
						self.sourceTradeSkillLevel = 3
						return a, b, c, d
					end
				end
			else
				--DA.DEBUG(1,"GetTradeSkillLevels: itemID= "..tostring(itemID)..", recipeSource= "..tostring(recipeSource))
			end
		end
--
-- Check LibPeriodicTable
-- Note: The itemID for Enchants is negative
--
		if PT then
			local levels = PT:ItemInSet(itemID,"TradeskillLevels")
			--DA.DEBUG(1,"GetTradeSkillLevels (PT): itemID= "..tostring(itemID)..", levels= "..tostring(levels))
			if not levels then
				itemID = -itemID
				levels = PT:ItemInSet(itemID,"TradeskillLevels")
				--DA.DEBUG(1,"GetTradeSkillLevels (PT): itemID= "..tostring(itemID)..", levels= "..tostring(levels))
			end
			if levels then
				a,b,c,d = string.split("/",levels)
				a = (tonumber(a) or 0) + rb
				b = (tonumber(b) or 0) + rb
				c = (tonumber(c) or 0) + rb
				d = (tonumber(d) or 0) + rb
				self.sourceTradeSkillLevel = 4
				return a, b, c, d
			end
		end
	end
--
-- Since itemID didn't find anything, try the spellID.
-- On Classic Era, spellID is the name of the spell.
--
	if spellID then
		if type(spellID) == 'number' and spellID ~= 0 then
			levelsByRecipe = SkillLineAbility[spellID]
			DA.DEBUG(1,"GetTradeSkillLevels: spellID= "..tostring(spellID)..", levelsByRecipe= "..tostring(levelsByRecipe))
			if skillLevels and (skillLevels[spellID] or skillLevels[-spellID]) then
--
-- The data from Wowhead is not specific to the game version
--
				if skillLevels[spellID] then
					levels = skillLevels[spellID]
				else
					levels = skillLevels[-spellID]
				end
			end
		elseif type(spellID) == 'string' then
			local spellName = spellID
			spellID = Skillet.db.global.NameToSpellID[spellName] or 0
			levelsByRecipe = SkillLineAbility[spellID]
			DA.DEBUG(1,"GetTradeSkillLevels: spellName= "..tostring(spellName)..", spellID= "..tostring(spellID)..", levelsByRecipe= "..tostring(levelsByRecipe))
			if skillLevels and skillLevels[spellID] then
--
-- The data from Wowhead is not specific to the game version
--
				if skillLevels[spellID] then
					levels = skillLevels[spellID]
				end
			end
		end
		if type(levels) == 'table' then
			if isRetail then
				levels = skillLevels[itemID][spellID]
			else
				for spell, strng in pairs(levels) do
					name = getSpellName(spell)
					--DA.DEBUG(1,"GetTradeSkillLevels: name= "..tostring(name))
					if name == spellID then
						levels = strng
						break
					end
				end
			end
		end
		local r = compareLevels(levels,levelsByRecipe)
		if r == 1 then
			return a,b,c,d
		elseif r == 2 then
			return e,f,g,h
		end
	end
--
-- Searching for itemID and SpellID both failed.
-- Check the MissingSkillLevels table and add an entry if it isn't there.
-- This allows for manual editing of that table in the saved variables.
--
	if not self.db.global.MissingSkillLevels then
		self.db.global.MissingSkillLevels = {}
	end
	local index = 0
	if itemID and itemID ~= 0 then
		index = itemID
	elseif spellID and spellID ~= 0 then
		index = spellID
	end
	if not self.db.global.MissingSkillLevels[index] then
		self.db.global.MissingSkillLevels[index] = "0/0/0/0"
	end
	self.sourceTradeSkillLevel = 7
	a,b,c,d = string.split("/", self.db.global.MissingSkillLevels[index])
	a = (tonumber(a) or 0)
	b = (tonumber(b) or 0)
	c = (tonumber(c) or 0)
	d = (tonumber(d) or 0)
	return a, b, c, d
end

function Skillet:GetTradeSkillLevelColor(itemID, rank)
	--DA.DEBUG(0,"GetTradeSkillLevelColor("..tostring(itemID)..", "..tostring(rank)")")
	if itemID then
		local orange, yellow, green, gray = self:GetTradeSkillLevels(itemID)
		if rank >= gray then return skillColors["trivial"] end
		if rank >= green then return skillColors["easy"] end
		if rank >= yellow then return skillColors["moderate"] end
		if rank >= orange then return skillColors["optimal"] end
	end
	return skillColors["unknown"]
end

function Skillet:AddTradeSkillLevels(itemID, orange, yellow, green, gray, spellID)
	DA.DEBUG(0,"AddTradeSkillLevels("..tostring(itemID)..", "..tostring(orange)..", "..tostring(yellow)..", "..tostring(green)..", "..tostring(gray)..", "..tostring(spellID)..")")
	local skillLevels = Skillet.db.global.SkillLevels
--
-- We should add some sanity checking
--
	if itemID and spellID then
		if not skillLevels[itemID] then 
			skillLevels[itemID] = {}
		end
		skillLevels[itemID][spellID] = tostring(orange).."/"..tostring(yellow).."/"..tostring(green).."/"..tostring(gray)
	elseif itemID then
		skillLevels[itemID] = tostring(orange).."/"..tostring(yellow).."/"..tostring(green).."/"..tostring(gray)
	end
end

function Skillet:DelTradeSkillLevels(itemID)
	DA.DEBUG(0,"DelTradeSkillLevels("..tostring(itemID)..")")
	local skillLevels = Skillet.db.global.SkillLevels
	if itemID then
--
-- We could add some additional checking
--
		skillLevels[itemID] = nil
	end
end

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--
-- Print the TradeSkillLevels(itemID) result including the actual index and the source.
--
-- index will be itemID or if the current profession is Enchanting, -itemID
--
-- source will be:
--    1 if from Skillet.db.global.SkillLevels
--    2 if from SkillLineAbility
--    3 if from TradeskillInfo
--    4 if from LibPeriodicTable
--    5 if itemID is not a number (obsolete)
--    6 if itemID was missing (obsolete)
--    7 if it wasn't found (and was added to Skillet.db.global.MissingSkillLevels)
--
function Skillet:PrintTradeSkillLevels(itemID, spellID)
	--DA.DEBUG(0,"PrintTradeSkillLevels("..tostring(itemID)..", "..tostring(spellID)..")")
	DA.MARK3(Skillet.version..", "..Skillet.wowVersion..", "..Skillet.SkillLevelVersion..", "..GetLocale())
	DA.MARK3("PrintTradeSkillLevels: altskilllevels= "..tostring(self.db.profile.altskilllevels))
	DA.MARK3("PrintTradeSkillLevels: baseskilllevel= "..tostring(self.db.profile.baseskilllevel))
	DA.MARK3("PrintTradeSkillLevels: #SkillLevels= "..tostring(tablelength(self.db.global.SkillLevels)))
	DA.MARK3("PrintTradeSkillLevels: #SkillLineAbility= "..tostring(tablelength(self.db.global.SkillLineAbility)))
	DA.MARK3("PrintTradeSkillLevels: #NameToSpellID= "..tostring(tablelength(self.db.global.NameToSpellID)))
	if CraftInfoAnywhere then
		DA.MARK3("PrintTradeSkillLevels: #ItemsToRecipes= "..tostring(tablelength(CraftInfoAnywhere.Data.ItemsToRecipes)))
	end
	if itemID then
		local orange, yellow, green, gray = self:GetTradeSkillLevels(itemID, spellID)
		DA.MARK3("PrintTradeSkillLevels: itemID= "..tostring(itemID)..", spellID= "..tostring(spellID))
		DA.MARK3("PrintTradeSkillLevels: source= "..tostring(self.sourceTradeSkillLevel))
		DA.MARK3("PrintTradeSkillLevels: levels= "..tostring(orange).."/"..tostring(yellow).."/"..tostring(green).."/"..tostring(gray))
	end
end
