local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
local PT = LibStub("LibPeriodicTable-3.1")

local skillColors = {
	["unknown"]		= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]		= { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]		= { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",  cstring = "|cffffff00"},
	["easy"]		= { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",   cstring = "|cff40c000"},
	["trivial"]		= { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext="",    cstring = "|cff808080"},
	["header"]		= { r = 1.00, g = 0.82, b = 0,    level = 0, alttext="",    cstring = "|cffffc800"},
}

function Skillet:GetTradeSkillLevels(spellID)
	DA.DEBUG(0,"Skillet:GetTradeSkillLevels("..tostring(spellID)..")")
	if spellID then 
		if spellID ~= 0 then
-- TradeskillInfo seems to be more accurate than LibPeriodicTable-3.1
			if TradeskillInfo then
				local recipeSource = Skillet.db.global.itemRecipeSource[spellID]
				for recipeID in pairs(recipeSource) do
					local TSILevels = TradeskillInfo:GetCombineDifficulty(recipeID)
					DA.DEBUG(0,"recipeID= "..tostring(recipeID))
					if type(TSILevels) == 'table' then
						DA.DEBUG(0,"TSILevels="..DA.DUMP1(TSILevels))
						return TSILevels[1], TSILevels[2], TSILevels[3], TSILevels[4] 
					end
				end
			end
			if PT then
				local levels = PT:ItemInSet(spellID,"TradeskillLevels")
				if levels then
					DA.DEBUG(0,"levels= "..tostring(levels))
					local a,b,c,d = string.split("/",levels)
					a = tonumber(a) or 0
					b = tonumber(b) or 0
					c = tonumber(c) or 0
					d = tonumber(d) or 0
					return a, b, c, d
				end
			end
		end
	end
	return 0,0,0,0 
end

function Skillet:GetTradeSkillLevelColor(spellID, rank)
	if spellID then
		local orange, yellow, green, gray = self:GetTradeSkillLevels(spellID)
		if rank >= gray then return skillColors["trivial"] end
		if rank >= green then return skillColors["easy"] end
		if rank >= yellow then return skillColors["moderate"] end
		if rank >= orange then return skillColors["optimal"] end
	end
	return skillColors["unknown"]
end
