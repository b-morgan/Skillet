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
local PT = LibStub("LibPeriodicTable-3.1")

-- recursive reagent craftability check
-- not considering alts
-- does consider queued recipes
function Skillet:InventoryReagentCraftability(reagentID)
	--DA.DEBUG(1,"InventoryReagentCraftability("..tostring(reagentID)..") -- "..tostring((GetItemInfo(reagentID))))
	if not reagentID or reagentID == 0 then
		return 0, 0
	end
	local player = Skillet.currentPlayer
	if player ~= UnitName("player") then
		return 0, 0
	end
	if self.visited[reagentID] then
		local reagentA, reagentC, reagentCV = self:GetInventory(player, reagentID)
		--DA.DEBUG(2,"     ReagentCraftability: visited reagentID= "..tostring(reagentID).." ("..tostring((GetItemInfo(reagentID))).."), Available= "..tostring(reagentA)..", Craftable= "..tostring(reagentC)..", CraftableVendor= "..tostring(reagentCV))
		return reagentC, reagentCV
	end
	self.visited[reagentID] = true
	local recipeSource = self.db.global.itemRecipeSource[reagentID]
	local numReagentsCrafted = 0
	local numReagentsCraftedVendor = 0
	local skillIndexLookup = self.data.skillIndexLookup
	if recipeSource then
		--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), recipeSource= "..DA.DUMP1(recipeSource))
		for childRecipeID in pairs(recipeSource) do
			local childRecipe = self:GetRecipe(childRecipeID)
			local childSkillIndex = skillIndexLookup[childRecipeID]
			if childSkillIndex and childRecipe and #childRecipe.reagentData > 0 and
			  not self.TradeSkillIgnoredMats[childRecipeID] and not self.db.realm.userIgnoredMats[player][childRecipeID] then
				local numCraftable = 100000
				local numCraftableVendor = 100000
				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]
					local numReagentOnHand = GetItemCount(childReagent.reagentID,true)
					local numReagentCraftable, numReagentCraftableVendor = self:InventoryReagentCraftability(childReagent.reagentID)
					--DA.DEBUG(2,"     ReagentCraftability: childID="..childReagent.reagentID.." ("..tostring((GetItemInfo(childReagent.reagentID))).."), numReagentOnHand="..tostring(numReagentOnHand)..", numReagentCraftable= "..tostring(numReagentCraftable)..", numReagentCraftableVendor= "..tostring(numReagentCraftableVendor))
					numReagentCraftable = numReagentCraftable + numReagentOnHand
					numReagentCraftableVendor = numReagentCraftableVendor + numReagentOnHand
					numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
					if not self:VendorSellsReagent(childReagent.reagentID) then
						numCraftableVendor = math.min(numCraftableVendor, math.floor(numReagentCraftableVendor/childReagent.numNeeded))
					else
						--DA.DEBUG(2,"     ReagentCraftability: VendorSellsReagent")
					end
				end
				numReagentsCrafted = numReagentsCrafted + numCraftable * childRecipe.numMade
				numReagentsCraftedVendor = numReagentsCraftedVendor + numCraftableVendor * childRecipe.numMade
			end
		end
	else
		--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), recipeSource= nil")
	end
	local queued = 0
	if self.db.realm.reagentsInQueue[player] then
		queued = self.db.realm.reagentsInQueue[player][reagentID] or 0
	end
	local numInBoth = self:GetInventory(player, reagentID)
	local numCrafted = numReagentsCrafted + queued
	local numCraftedVendor = numReagentsCraftedVendor + queued
	if numCraftedVendor == 0 then
		self.db.realm.inventoryData[player][reagentID] = numInBoth
	else
		self.db.realm.inventoryData[player][reagentID] = numInBoth.." "..numCrafted.." "..numCraftedVendor
	end
	--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), numInBoth= "..tostring(numInBoth)..", numCrafted= "..tostring(numCrafted)..", numCraftedVendor= "..tostring(numCraftedVendor))
	return numCrafted, numCraftedVendor
end

-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
-- (not to be confused with the reagent craftability which is designed to determine how many
-- craftable reagents are available for recipe iterations)
function Skillet:InventorySkillIterations(tradeID, recipe)
	--DA.DEBUG(1,"InventorySkillIterations("..tostring(tradeID)..", "..tostring(recipe.name)..")")
	local player = Skillet.currentPlayer
	local faction = self.db.realm.faction[player]
	if player ~= UnitName("player") then
		return 0, 0, 0, 0
	end
	if recipe and recipe.reagentData and #recipe.reagentData > 0 then	-- make sure that recipe is in the database before continuing
		local recipeID = recipe.spellID
		local numMade = recipe.numMade
		local numCraft = 100000
		local numCraftable = 100000
		local numCraftableVendor = 100000
		local numCraftVendor = 100000
		local numCraftAlts = 100000
		local vendorOnly = true
		for i=1,#recipe.reagentData do
			if recipe.reagentData[i].reagentID then
				local reagentID = recipe.reagentData[i].reagentID
				local numNeeded = recipe.reagentData[i].numNeeded
				local reagentAvailable = 0
				local reagentCraftable = 0
				local reagentCraftableVendor = 0
				local reagentAvailableAlts = 0
				reagentAvailable, reagentCraftable, reagentCraftableVendor = self:GetInventory(player, reagentID)
				if reagentCraftable == 0 then
					reagentCraftable, reagentCraftableVendor = self:InventoryReagentCraftability(reagentID)
				end
				for alt in pairs(self.db.realm.inventoryData) do
					if alt ~= player and self.db.realm.faction[alt] == faction then
						local altBoth = self:GetInventory(alt, reagentID)
						reagentAvailableAlts = reagentAvailableAlts + altBoth
					end
				end
				if Skillet.db.profile.use_guildbank_as_alt then
					local guildName = GetGuildInfo("player")
					local cachedGuildbank = Skillet.db.global.cachedGuildbank
					if guildName and cachedGuildbank[guildName] and cachedGuildbank[guildName][reagentID] then
						reagentAvailableAlts = reagentAvailableAlts + cachedGuildbank[guildName][reagentID]
					end
				end
				--DA.DEBUG(2,"     SkillIterations: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), reagentAvailable= "..tostring(reagentAvailable)..", reagentCraftable= "..tostring(reagentCraftable)..", reagentCraftableVendor= "..tostring(reagentCraftableVendor)..", reagentAvailableAlts= "..tostring(reagentAvailableAlts)..", VendorSellsReagent= "..tostring(self:VendorSellsReagent(reagentID)))
				if self:VendorSellsReagent(reagentID) then	-- if it's available from a vendor, then only worry about bag inventory
					local vendorAvailable, vendorAvailableAlts = Skillet:VendorItemAvailable(reagentID)
					numCraft = math.min(numCraft, math.floor(reagentAvailable/numNeeded))
					numCraftable = math.min(numCraftable, math.floor((reagentAvailable+reagentCraftable)/numNeeded))
					numCraftVendor = math.min(numCraftVendor, math.floor(vendorAvailable/numNeeded))
					numCraftAlts = math.min(numCraftAlts, math.floor(vendorAvailableAlts/numNeeded))
				else
					vendorOnly = false
					numCraft = math.min(numCraft, math.floor(reagentAvailable/numNeeded))
					numCraftable = math.min(numCraftable, math.floor((reagentAvailable+reagentCraftable)/numNeeded))
					numCraftableVendor = math.min(numCraftableVendor, math.floor((reagentAvailable+reagentCraftableVendor)/numNeeded))
					numCraftVendor = math.min(numCraftVendor, numCraftableVendor)
					numCraftAlts = math.min(numCraftAlts, math.floor(reagentAvailableAlts/numNeeded))
				end
				--DA.DEBUG(2,"     SkillIterations:      numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftableVendor="..tostring(numCraftableVendor)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts))
			else								-- no data means no craftability
				DA.CHAT("reagent id seems corrupt!")
				DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe))
				numCraft = 0
				numCraftable = 0
				numCraftVendor = 0
				numCraftAlts = 0
				self.dataScanned = false		-- mark the data as needing to be rescanned since a reagent id seems corrupt
			end
		end --for
		recipe.vendorOnly = vendorOnly
		--DA.DEBUG(2,"      pre-adjustment: recipeID= "..tostring(recipeID).."("..tostring(recipe.name).."), numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts)..", vendorOnly="..tostring(vendorOnly))
		if numCraftable == numCraftVendor then
			numCraftVendor = 0					-- only keep vendor count if different
		end
		if numCraft == numCraftable then
			numCraftable = 0					-- only keep craftable count if different
		end
		--DA.DEBUG(2,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name).."), numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts)..", vendorOnly="..tostring(vendorOnly))
		return numCraft * numMade, numCraftable * numMade, numCraftVendor * numMade, numCraftAlts * numMade
	else
		DA.DEBUG(1,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name)..") has no reagent data")
	end
	return 0, 0, 0, 0
end

function Skillet:InventoryScan()
	DA.DEBUG(0,"InventoryScan()")
	local player = self.currentPlayer
	if self.linkedSkill or self.isGuild or player ~= UnitName("player") then
		return
	end
	local cachedInventory = self.db.realm.inventoryData[player]
	if not cachedInventory then
		cachedInventory = {}
	end
	local inventoryData = {}
	local reagent
	local numInBoth
	if self.db.global.itemRecipeUsedIn then
		for reagentID in pairs(self.db.global.itemRecipeUsedIn) do
			--DA.DEBUG(2,"reagent "..tostring(GetItemInfo(reagentID)).." "..tostring(inventoryData[reagentID]))
			if reagentID and not inventoryData[reagentID] then				-- have we calculated this one yet?
				if self.currentPlayer == (UnitName("player")) then			-- if this is the current player, use the API
					--DA.DEBUG(2,"Using API")
					numInBoth = GetItemCount(reagentID,true)				-- both bank and bags
				end
				inventoryData[reagentID] = tostring(numInBoth)	-- only what we have for now (no craftability info)
				--DA.DEBUG(2,"inventoryData["..reagentID.."]="..inventoryData[reagentID])
			end
		end
	end
	self.visited = {} -- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice
	if inventoryData then
--
-- now calculate the craftability of these same reagents
--
		for reagentID,inventory in pairs(inventoryData) do
			local numCrafted, numCraftedVendor = self:InventoryReagentCraftability(reagentID)
			if numCraftedVendor > 0 then
				inventoryData[reagentID] = tostring(inventoryData[reagentID]).." "..tostring(numCrafted).." "..tostring(numCraftedVendor)
			end
		end
--
-- remove any reagents that don't show up in our inventory
--
		for reagentID,inventory in pairs(inventoryData) do
			if inventoryData[reagentID] == 0 or inventoryData[reagentID] == "0" or inventoryData[reagentID] == "0 0" or inventoryData[reagentID] == "0 0 0" then
				inventoryData[reagentID] = nil
				cachedInventory[reagentID] = nil
			else
				cachedInventory[reagentID] = inventoryData[reagentID]
			end
		end
	end
	--DA.DEBUG(0,"InventoryScan: return")
end

function Skillet:GetInventory(player, reagentID)
	--DA.DEBUG(0,"GetInventory("..tostring(player)..", "..tostring(reagentID)..")")
	local numCanUse
	if player and reagentID then
		if player == self.currentPlayer then			-- UnitName("player")
			numCanUse = GetItemCount(reagentID,true)
		end
		if self.db.realm.inventoryData[player] and self.db.realm.inventoryData[player][reagentID] then
			--DA.DEBUG(1,"inventoryData= "..tostring(self.db.realm.inventoryData[player][reagentID]))
			local data = { string.split(" ", self.db.realm.inventoryData[player][reagentID]) }
			if numCanUse and data[1] and tonumber(numCanUse) ~= tonumber(data[1]) then
				DA.DEBUG(0,"inventoryData is stale")
			end
			if #data == 1 then			-- no craftability info yet
				return tonumber(data[1]) or 0, 0, 0
			else
				return tonumber(data[1]) or 0, tonumber(data[2]) or 0, tonumber(data[3]) or 0
			end
		elseif player == self.currentPlayer then	-- UnitName("player")
			return tonumber(numCanUse) or 0, 0, 0
		end
	end
	return 0, 0, 0		-- have, make, make with vendor
end

--
-- queries for vendor info for a particular itemID
--
function Skillet:VendorSellsReagent(itemID)
	--DA.DEBUG(0,"VendorSellsReagent("..tostring(itemID)..")")
	if self.db.global.MissingVendorItems[itemID] then
		if type(self.db.global.MissingVendorItems[itemID]) == 'table' then
			if Skillet.db.profile.use_altcurrency_vendor_items then
				return true
			end
		else
			return true
		end
	end
--
-- Check the LibPeriodicTable data next
--
	if PT then
		if itemID~=0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
	return false
end

--
-- returns the number of items that can be bought limited by the amount of currency available
--
function Skillet:VendorItemAvailable(itemID)
	DA.DEBUG(0,"VendorItemAvailable("..tostring(itemID)..")")
	local _, divider, currency
	local currencyAvailable = 0
	local currencyAvailableAlts = 0
	if self.SpecialVendorItems[itemID] then
		divider = self.SpecialVendorItems[itemID][1]
		currency = self.SpecialVendorItems[itemID][2]
		currencyAvailable = self:GetInventory(self.currentPlayer, currency)
		for alt in pairs(self.db.realm.inventoryData) do
			if alt ~= self.currentPlayer then
				local altBoth = self:GetInventory(alt, currency)
				currencyAvailableAlts = currencyAvailableAlts + (altBoth or 0)
			end
		end
		return math.floor(currencyAvailable / divider), math.floor(currencyAvailableAlts / divider)
	elseif self.db.global.MissingVendorItems[itemID] then
		local MissingVendorItem = self.db.global.MissingVendorItems[itemID]
		if type(MissingVendorItem) == 'table' then	-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
			if Skillet.db.profile.use_altcurrency_vendor_items then
				DA.DEBUG(1,"MissingVendorItem="..DA.DUMP1(MissingVendorItem))
				if MissingVendorItem[4] > 0 then
					currencyAvailable = self:GetInventory(self.currentPlayer, MissingVendorItem[4])
				else
					local cinfo = C_CurrencyInfo.GetCurrencyInfo(-1 * MissingVendorItem[4])
					if cinfo then
						DA.DEBUG(1,"cinfo="..DA.DUMP1(cinfo))
						currencyAvailable = cinfo.quantity
					end
				end
				DA.DEBUG(1,"currencyAvailable="..tostring(currencyAvailable))
--
-- compute how many this player can buy with alternate currency and return 0 for alts
--
				return math.floor(MissingVendorItem[2] * currencyAvailable / (MissingVendorItem[5] or 1)), 0
			else
				return 0, 0		-- vendor sells item for an alternate currency and we are ignoring it.
			end
		else
			return 100000, 100000	-- vendor sells item for gold, price is not available so assume lots of gold
		end
	else
		return 100000, 100000	-- vendor sells item for gold, price is not available so assume lots of gold
	end
end
