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

-- recursive reagent craftability check
-- not considering alts at the moment
-- does consider queued recipes
function Skillet:InventoryReagentCraftability(reagentID, playerOverride)
	if self.visited[reagentID] then
		return 0, 0			-- we've been here before, so bail out to avoid infinite loop
	end
	local player = playerOverride or Skillet.currentPlayer
	self.visited[reagentID] = true
	local recipeSource = self.db.global.itemRecipeSource[reagentID]
	local numReagentsCrafted = 0
	local skillIndexLookup = self.data.skillIndexLookup[player]
	if recipeSource then
		for childRecipeID in pairs(recipeSource) do
			local childRecipe = self:GetRecipe(childRecipeID)
			local childSkillIndex = skillIndexLookup[childRecipeID]		-- only interested in current player for now
			if childSkillIndex and childRecipe and #childRecipe.reagentData > 0 and
			  not Skillet.TradeSkillIgnoredMats[childRecipeID] and not Skillet.db.realm.userIgnoredMats[player][childRecipeID] then
				local numCraftable = 100000
				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]
					local numReagentCraftable = self:InventoryReagentCraftability(childReagent.id, player)
					DA.DEBUG(2,"id="..childReagent.id..", numReagentCraftable="..numReagentCraftable)
					numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
					DA.DEBUG(2,"numCraftable="..numCraftable)
				end
				numReagentsCrafted = numReagentsCrafted + numCraftable * childRecipe.numMade
				DA.DEBUG(2,"numReagentsCrafted="..numReagentsCrafted)
			end
		end
	end
	local queued = 0
	if self.db.realm.reagentsInQueue[player] then
		queued = self.db.realm.reagentsInQueue[player][reagentID] or 0
	end
	local numInBoth = self:GetInventory(player, reagentID)
	local numCraftable = numReagentsCrafted + queued
	local invCount = 4			-- number of records to keep (1 = bag, 2 = bag/bank, 4 = bag/bank/craftBag/craftBank)
	if numCraftable == 0 then
		Skillet.db.realm.inventoryData[player][reagentID] = numInBoth
	else
		Skillet.db.realm.inventoryData[player][reagentID] = numInBoth.." "..numCraftable
	end
	self.visited[reagentID] = false -- okay to calculate this reagent again
	return numCraftable
end

-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
-- (not to be confused with the reagent craftability which is designed to determine how many 
-- craftable reagents are available for recipe iterations)
function Skillet:InventorySkillIterations(tradeID, skillIndex, playerOverride)
	local player = playerOverride or Skillet.currentPlayer
	local skill = self:GetSkill(player, tradeID, skillIndex)
	local recipe = self:GetRecipe(skill.id)
--	if recipe and recipe.reagentData and #recipe.reagentData > 0 then	-- make sure that recipe is in the database before continuing
	if recipe and recipe.reagentData then	-- make sure that recipe is in the database before continuing
		local numCraftable = 100000
		local numCraftableVendor = 100000
		local numCraftableAlts = 100000
		local vendorOnly = true
		for i=1,#recipe.reagentData,1 do
			if recipe.reagentData[i].id then
				local reagentID = recipe.reagentData[i].id
				local numNeeded = recipe.reagentData[i].numNeeded
				local reagentAvailability = 0
				local reagentAvailabilityAlts = 0
				reagentAvailability = self:GetInventory(player, reagentID)
				for player in pairs(self.db.realm.inventoryData) do
					local altBoth = self:GetInventory(player, reagentID)
					reagentAvailabilityAlts = reagentAvailabilityAlts + (altBoth or 0)
				end
				if self:VendorSellsReagent(reagentID) then	-- if it's available from a vendor, then only worry about bag inventory
					numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
					local vendorAvailable, vendorAvailableAlt = Skillet:VendorItemAvailable(reagentID)
					numCraftableVendor = math.min(numCraftableVendor, vendorAvailable)
					numCraftableAlts = math.min(numCraftableAlts, vendorAvailableAlt)
				else
					vendorOnly = false
					numCraftable = math.min(numCraftable, math.floor(reagentAvailability/numNeeded))
					numCraftableVendor = math.min(numCraftableVendor, math.floor(reagentAvailability/numNeeded))
					numCraftableAlts = math.min(numCraftableAlts, math.floor(reagentAvailabilityAlts/numNeeded))
				end
				if (numCraftableAlts == 0) then
					break
				end
			else								-- no data means no craftability
				numCraftable = 0
				numCraftableVendor = 0
				numCraftableAlts = 0
				self.dataScanned = false		-- mark the data as needing to be rescanned since a reagent id seems corrupt
			end
		end --for
		recipe.vendorOnly = vendorOnly
		return math.max(0,numCraftable * recipe.numMade), math.max(0,numCraftableVendor * recipe.numMade), math.max(0,numCraftableAlts * recipe.numMade)
	else
		DA.CHAT("can't calc craft iterations!")
	end
	return 0, 0, 0
end

local invscan = 1
function Skillet:InventoryScan(playerOverride)
	DA.DEBUG(0,"InventoryScan "..invscan..", "..tostring(playerOverride))
	invscan = invscan + 1
	local player = playerOverride or self.currentPlayer
	local cachedInventory = self.db.realm.inventoryData[player]
	local inventoryData = {}
	local reagent
	if self.db.global.itemRecipeUsedIn then
		for reagentID in pairs(self.db.global.itemRecipeUsedIn) do
			local i = GetItemInfo(reagentID) 								-- force the item into local cache
			DA.TRACE("reagent "..tostring(a).." "..tostring(b))
			if reagentID and not inventoryData[reagentID] then				-- have we calculated this one yet?
				if self.currentPlayer == (UnitName("player")) then			-- if this is the current player, use the API
					DA.TRACE("Using API")
					numInBoth = GetItemCount(reagentID,true)				-- both bank and bags
				elseif cachedInventory and cachedInventory[reagentID] then	-- otherwise, use what cached data is available
					DA.TRACE("Using cachedInventory")
					local a,b,c,d = string.split(" ", cachedInventory[reagentID])
					numInBoth = a
				else
					DA.TRACE("Using Zero")
					numInBoth = 0
				end
				inventoryData[reagentID] = tostring(numInBoth)	-- only what we have for now (no craftability info)
				DA.TRACE("inventoryData["..reagentID.."]="..inventoryData[reagentID])
			end
		end
	end
	self.db.realm.inventoryData[player] = inventoryData
	self.visited = {} -- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice
	if inventoryData then
		-- now calculate the craftability of these same reagents
		for reagentID,inventory in pairs(inventoryData) do
			self:InventoryReagentCraftability(reagentID, player)
		end
		-- remove any reagents that don't show up in our inventory
		for reagentID,inventory in pairs(inventoryData) do
			if inventoryData[reagentID] == 0 or inventoryData[reagentID] == "0" or 
			  inventoryData[reagentID] == "0 0" or inventoryData[reagentID] == "0 0 0 0" then
				inventoryData[reagentID] = nil
			end
		end
	end
		DA.DEBUG(0,"InventoryScan Complete")
end

function Skillet:GetInventory(player, reagentID)
	if player and reagentID then
--		if self.db.realm.inventoryData[player] and self.db.realm.inventoryData[player][reagentID] and 
--		  type(self.db.realm.inventoryData[player][reagentID]) == "string" then
		if self.db.realm.inventoryData[player] and self.db.realm.inventoryData[player][reagentID] then 
			local data = { string.split(" ", self.db.realm.inventoryData[player][reagentID]) }
			if #data == 1 then			-- no craftability info yet
				return tonumber(data[1]) or 0, 0, 0, 0
			elseif #data == 2 then
				return tonumber(data[1]) or 0, tonumber(data[2]) or 0, 0, 0
			else
				return tonumber(data[1]) or 0, tonumber(data[2]) or 0, tonumber(data[3]) or 0, tonumber(data[4]) or 0
			end
		elseif player == self.currentPlayer then
			local numInBoth = GetItemCount(reagentID,true)				-- both bank and bags
			return tonumber(numInBoth) or 0, 0, 0, 0
		end
	end
	return 0, 0, 0, 0			-- have, make, <unassigned>, <unassigned>
end

function Skillet:AuctionScan()
	local player = Skillet.currentPlayer
	local auctionData = {}
	for i = 1, GetNumAuctionItems("owner") do
		local _, _, count, _, _, _, _, _, _, _, _, _, _, _, _, saleStatus, itemID, _ =  GetAuctionItemInfo("owner", i);
		if saleStatus ~= 1 then
			auctionData[itemID] = (auctionData[itemID] or 0) + count
		end
	end
	self.db.realm.auctionData[player] = auctionData
end