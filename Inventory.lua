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

--
-- recursive reagent craftability check
-- not considering alts
-- does consider queued recipes
--
function Skillet:InventoryReagentCraftability(reagentID)
	--DA.DEBUG(1,"InventoryReagentCraftability("..tostring(reagentID)..") -- "..tostring((C_Item.GetItemInfo(reagentID))))
	if not reagentID or type(reagentID) == "table" or reagentID == 0 then
		return 0, 0
	end
	local player = Skillet.currentPlayer
	if self.visited[reagentID] then
		local reagentA, reagentC, reagentCV = self:GetInventory(player, reagentID)
		return reagentC, reagentCV
	end
	self.visited[reagentID] = true
	local numReagentsCrafted = 0
	local numReagentsCraftedVendor = 0
	local skillIndexLookup = self.data.skillIndexLookup
	local recipeSource = self.db.global.itemRecipeSource[reagentID]
	if recipeSource then
		--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((C_Item.GetItemInfo(reagentID))).."), recipeSource= "..DA.DUMP1(recipeSource))
		for childRecipeID in pairs(recipeSource) do
			local childRecipe = self:GetRecipe(childRecipeID)
			local childSkillIndex = skillIndexLookup[childRecipeID]
			if childSkillIndex and childRecipe and #childRecipe.reagentData > 0 and
			  not self.TradeSkillIgnoredMats[childRecipeID] and not self.db.realm.userIgnoredMats[player][childRecipeID] then
				local numCraftable = 100000
				local numCraftableVendor = 100000
				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]
					local numReagentOnHand = C_Item.GetItemCount(childReagent.reagentID,true,false,true,true)
					local numReagentCraftable, numReagentCraftableVendor = self:InventoryReagentCraftability(childReagent.reagentID)
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
		--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((C_Item.GetItemInfo(reagentID))).."), recipeSource= nil")
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
	return numCrafted, numCraftedVendor
end

--
-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
-- (not to be confused with the reagent craftability which is designed to determine how many
-- craftable reagents are available for recipe iterations)
--
function Skillet:InventorySkillIterations(tradeID, recipe)
	--DA.DEBUG(1,"InventorySkillIterations("..tostring(tradeID)..", "..tostring(recipe.name)..")")
	local player = Skillet.currentPlayer
	local faction = self.db.realm.faction[player]
	if recipe then	-- make sure that recipe is in the database before continuing
		local recipeID = recipe.spellID
		local numMade = recipe.numMade
		local numCraft = 100000
		local numCraftable = 100000
		local numCraftableVendor = 100000
		local numCraftVendor = 100000
		local numCraftAlts = 100000
		local vendorOnly = true
		local reagents = {}
		for i=1,#recipe.reagentData do
			if recipe.reagentData[i].reagentID then
				table.insert(reagents, {reagentID = recipe.reagentData[i].reagentID, numNeeded = recipe.reagentData[i].numNeeded })
			end
		end
		if recipe.modifiedData then
			for i=1,#recipe.modifiedData do
				if recipe.modifiedData[i].reagentID then
--					table.insert(reagents, {reagentID = recipe.modifiedData[i].reagentID, numNeeded = recipe.modifiedData[i].numNeeded })
					table.insert(reagents, {reagentID = recipe.modifiedData[i].schematic.reagents, numNeeded = recipe.modifiedData[i].numNeeded })
				end
			end
		end
		for _,reagent in pairs(reagents) do
			local reagentID = reagent.reagentID
			local numNeeded = reagent.numNeeded
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
				if guildName and cachedGuildbank[guildName] then
					if type(reagentID) ~= "table" then
						reagentAvailableAlts = reagentAvailableAlts + (cachedGuildbank[guildName][reagentID] or 0)
					elseif type(reagentID) == "table" then
						for i=1,#reagentID do
							reagentAvailableAlts = reagentAvailableAlts + (cachedGuildbank[guildName][reagentID[i].itemID] or 0)
						end
					end
				end
			end
			if type(reagentID) ~= "table" and self:VendorSellsReagent(reagentID) then	-- if it's available from a vendor, then only worry about bag inventory
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
		end --for
		recipe.vendorOnly = vendorOnly
		if numCraftable == numCraftVendor then
			numCraftVendor = 0					-- only keep vendor count if different
		end
		if numCraft == numCraftable then
			numCraftable = 0					-- only keep craftable count if different
		end
		--DA.DEBUG(1,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name)..") numCraft= "..tostring(numCraft)..", numCraftable= "..tostring(numCraftable)..", numCraftVendor= "..tostring(numCraftVendor)..", numCraftAlts= "..tostring(numCraftAlts))
		return numCraft * numMade, numCraftable * numMade, numCraftVendor * numMade, numCraftAlts * numMade
	else
		--DA.DEBUG(1,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name)..") has no reagent data")
	end
	return 0, 0, 0, 0
end

function Skillet:InventoryScan()
	--DA.DEBUG(0,"InventoryScan()")
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
			--DA.DEBUG(2,"reagent "..tostring(C_Item.GetItemInfo(reagentID)).." "..tostring(inventoryData[reagentID]))
			if reagentID and not inventoryData[reagentID] then			-- have we calculated this one yet?
				--DA.DEBUG(2,"Using API")
				numInBoth = C_Item.GetItemCount(reagentID,true,false,true,true)		-- both bank and bags
				inventoryData[reagentID] = tostring(numInBoth)			-- only what we have for now (no craftability info)
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
	if player and reagentID then
		local have = 0
		local make = 0
		local wven = 0
		local found = false
		if self.db.realm.inventoryData[player] then
			if type(reagentID) ~= "table" then
				if self.db.realm.inventoryData[player][reagentID] then
					found = true
					--DA.DEBUG(1,"GetInventory: reagentID= "..tostring(reagentID)..", inventoryData= "..tostring(self.db.realm.inventoryData[player][reagentID]))
					have, make, wven = string.split(" ", self.db.realm.inventoryData[player][reagentID])
				end
			else
				--DA.DEBUG(2,"GetInventory(I): #reagentID= "..tostring(#reagentID)..", reagentID= "..DA.DUMP1(reagentID))
				for i = 1, #reagentID do
					if self.db.realm.inventoryData[player][reagentID[i].itemID] then
						found = true
						--DA.DEBUG(2,"GetInventory: itemID= "..tostring(reagentID[i].itemID)..", inventoryData= "..tostring(self.db.realm.inventoryData[player][reagentID[i].itemID]))
						local h, m, v = string.split(" ", self.db.realm.inventoryData[player][reagentID[i].itemID])
						have = have + (tonumber(h) or 0)
						make = make + (tonumber(m) or 0)
						wven = wven + (tonumber(v) or 0)
					end
				end
			end
			if found then
				return tonumber(have) or 0, tonumber(make) or 0, tonumber(wven) or 0
			end
		end
		if player == self.currentPlayer then
			if type(reagentID) ~= "table" then
				have = C_Item.GetItemCount(reagentID,true,false,true,true) or 0
			else
				--DA.DEBUG(2,"GetInventory(C): #reagentID= "..tostring(#reagentID)..", reagentID= "..DA.DUMP1(reagentID))
				for i = 1, #reagentID do
					--DA.DEBUG(2,"GetInventory: itemID= "..tostring(reagentID[i].itemID))
					have = have + (C_Item.GetItemCount(reagentID[i].itemID,true,false,true,true) or 0)
				end
			end
			return have, 0, 0
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
				--DA.DEBUG(1,"VendorSellsReagent: "..tostring(itemID))
				return true
			end
		else
				--DA.DEBUG(1,"VendorSellsReagent: "..tostring(itemID))
			return true
		end
	end
--
-- Check the LibPeriodicTable data next
--
	if PT then
		if itemID~=0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
				--DA.DEBUG(1,"VendorSellsReagent: "..tostring(itemID))
			return true
		end
	end
	return false
end

--
-- returns the number of items that can be bought limited by the amount of currency available
--
function Skillet:VendorItemAvailable(itemID)
	--DA.DEBUG(0,"VendorItemAvailable("..tostring(itemID)..")")
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
				--DA.DEBUG(1,"MissingVendorItem="..DA.DUMP1(MissingVendorItem))
				if MissingVendorItem[4] and MissingVendorItem[4] > 0 then
					currencyAvailable = self:GetInventory(self.currentPlayer, MissingVendorItem[4])
				elseif MissingVendorItem[4] then
					local cinfo = C_CurrencyInfo.GetCurrencyInfo(-1 * MissingVendorItem[4])
					if cinfo then
						--DA.DEBUG(1,"cinfo="..DA.DUMP1(cinfo))
						currencyAvailable = cinfo.quantity
					end
				else
					return 0, 0		-- vendor sells item for an alternate currency and we are ignoring it.
				end
				--DA.DEBUG(1,"currencyAvailable="..tostring(currencyAvailable))
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
