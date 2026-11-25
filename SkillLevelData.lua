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
	if Skillet.isRetail then
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
			--DA.DEBUG(1,"getRacialBonus: bonus = "..tostring(bonus))
				return bonus
			end
		end
	end
	return 0
end

--
-- Get TradeSkill Difficulty Levels
--
function Skillet:GetTradeSkillLevels(spellID)
	--DA.DEBUG(0,"GetTradeSkillLevels("..tostring(spellID)..")")
	local rb = getRacialBonus()
	local SkillLineAbility = Skillet.db.global.SkillLineAbility
	local levelsByRecipe
--
-- a,a1 = orange, b,b1 = yellow, c,c1 = green, d,d1 = gray
-- bonus is from Forever Legacy option "Working Overtime" 
--
	local a, b, c, d
	local a1, b1, c1, d1
	local bonus = 0
	if spellID then
		if type(spellID) == 'number' and spellID ~= 0 then
			levelsByRecipe = SkillLineAbility[spellID]
			DA.DEBUG(1,"GetTradeSkillLevels: spellID= "..tostring(spellID)..", levelsByRecipe= "..tostring(levelsByRecipe))
		elseif type(spellID) == 'string' then
			local spellName = spellID
			spellID = Skillet.db.global.NameToSpellID[spellName] or 0
			levelsByRecipe = SkillLineAbility[spellID]
			DA.DEBUG(1,"GetTradeSkillLevels: spellName= "..tostring(spellName)..", spellID= "..tostring(spellID)..", levelsByRecipe= "..tostring(levelsByRecipe))
		end
		if levelsByRecipe and type(levelsByRecipe) == 'string' then
			a,b,c,d = string.split("/", levelsByRecipe)
--
-- if the SkillLevelLearned exists for this recipe, it is a better a1 value than 1.
--
			if tonumber(a) == 1 and Skillet.db.global.SkillLevelLearned and Skillet.db.global.SkillLevelLearned[spellID] then
				a = Skillet.db.global.SkillLevelLearned[spellID]
			end
		end
--
-- if the addon SkillUpForever is available, get its data
--   orange (a1) is probably better than ours and bonus is from Forever Legacy option "Working Overtime". 
--
		if 	SkillUpForever and SkillUpForever.API.RecipeSkill then
			local r = SkillUpForever.API.RecipeSkill(spellID)
			DA.DEBUG(1,"GetTradeSkillLevels: spellID= "..tostring(spellID)..", r= "..DA.DUMP(r))
			a1 = r.orange
--			b1 = r.yellow
--			c1 = r.green
--			d1 = r.grey
			bonus = r.chanceBonus
			if a1 ~= 1 then
				a = a1
			end
		end
--
-- 
--
		a = (tonumber(a) or 0) + rb
		b = (tonumber(b) or 0) + rb
		c = (tonumber(c) or 0) + rb
		d = (tonumber(d) or 0) + rb
		return a, b, c, d, bonus or 0
	end -- spellID
--
-- Searching SpellID failed.
-- Check the MissingSkillLevels table and add an entry if it isn't there.
-- This allows for manual editing of that table in the saved variables.
--
	if not self.db.global.MissingSkillLevels then
		self.db.global.MissingSkillLevels = {}
	end
	local index = 0
	if spellID and spellID ~= 0 then
		index = spellID
	end
	if not self.db.global.MissingSkillLevels[index] then
		self.db.global.MissingSkillLevels[index] = "0/0/0/0"
	end
	self.sourceTradeSkillLevel = 7
	local a,b,c,d = string.split("/", self.db.global.MissingSkillLevels[index])
	a = (tonumber(a) or 0)
	b = (tonumber(b) or 0)
	c = (tonumber(c) or 0)
	d = (tonumber(d) or 0)
	return a, b, c, d, bonus or 0
end -- Skillet:GetTradeSkillLevels

function Skillet:GetTradeSkillLevelColor(itemID, rank)
	--DA.DEBUG(0,"GetTradeSkillLevelColor("..tostring(itemID)..", "..tostring(rank)")")
	if itemID then
		local a, b, c, d = self:GetTradeSkillLevels(itemID)
		if rank >= d then return skillColors["trivial"] end
		if rank >= c then return skillColors["easy"] end
		if rank >= b then return skillColors["moderate"] end
		if rank >= a then return skillColors["optimal"] end
	end
	return skillColors["unknown"]
end

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--
-- Print the TradeSkillLevels(spellID) result
--
--
function Skillet:PrintTradeSkillLevel(spellID)
	--DA.DEBUG(0,"PrintTradeSkillLevel("..tostring(spellID)..")")
	DA.MARK3(Skillet.version..", "..Skillet.wowVersion..", "..Skillet.SkillLevelVersion..", "..Skillet.SkillLevelBuild..", "..GetLocale())
	DA.MARK3("altskilllevels= "..tostring(Skillet.db.profile.altskilllevels))
	DA.MARK3("PrintTradeSkillLevel: #SkillLineAbility= "..tostring(tablelength(self.db.global.SkillLineAbility)))
	DA.MARK3("PrintTradeSkillLevel: #NameToSpellID= "..tostring(tablelength(self.db.global.NameToSpellID)))
	if spellID then
		local a1, b1, c1, d1, bonus = self:GetTradeSkillLevels(spellID)
		DA.MARK3("PrintTradeSkillLevel: spellID= "..tostring(spellID))
		DA.MARK3("PrintTradeSkillLevel: levels= "..tostring(a1).."/"..tostring(b1).."/"..tostring(c1).."/"..tostring(d1))
		DA.MARK3("PrintTradeSkillLevel: bonus= "..tostring(bonus))
		local SkillLineAbility = Skillet.db.global.SkillLineAbility
		if SkillLineAbility and SkillLineAbility[spellID] then
			DA.MARK3("PrintTradeSkillLevel: SkillLineAbility= "..tostring(SkillLineAbility[spellID]))
			if 	SkillUpForever and SkillUpForever.API.RecipeSkill then
				a1, b1, c1, d1, bonus = SkillUpForever.API.RecipeSkill(spellID)
				DA.MARK3("PrintTradeSkillLevel: a1= "..tostring(a1)..", b1= "..tostring(b1)..", c1= "..tostring(c1)..", d1= "..tostring(d1)..", bonus= "..tostring(bonus))
			end
		end
	end
end

function Skillet:PrintTradeSkillLevelByName(spellName)
	if Skillet.db.global.NameToSpellID then
		local spellID = Skillet.db.global.NameToSpellID[spellName]
		if spellID then
			self:PrintTradeSkillLevel(spellID)
		end
	end
end
				