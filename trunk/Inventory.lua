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
		return 0 
	end
	local player = Skillet.currentPlayer
	if player ~= UnitName("player") then
		return 0
	end
	if self.visited[reagentID] then
		local reagentA, reagentC = self:GetInventory(player, reagentID)
		--DA.DEBUG(2,"     ReagentCraftability: visited reagentID= "..tostring(reagentID).." ("..tostring((GetItemInfo(reagentID))).."), Available= "..tostring(reagentA)..", Craftable= "..tostring(reagentC))
		return reagentC
	end
	self.visited[reagentID] = true
	local recipeSource = self.db.global.itemRecipeSource[reagentID]
	local numReagentsCrafted = 0
	local skillIndexLookup = self.data.skillIndexLookup[player]
	if recipeSource then
		--DA.DEBUG(2,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), recipeSource= "..DA.DUMP1(recipeSource))
		for childRecipeID in pairs(recipeSource) do
			local childRecipe = self:GetRecipe(childRecipeID)
			local childSkillIndex = skillIndexLookup[childRecipeID]		-- only interested in current player for now
			if childSkillIndex and childRecipe and #childRecipe.reagentData > 0 and
			  not self.TradeSkillIgnoredMats[childRecipeID] and not self.db.realm.userIgnoredMats[player][childRecipeID] then
				local numCraftable = 100000
				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]
					local numReagentOnHand = GetItemCount(childReagent.reagentID,true)
					local numReagentCraftable = self:InventoryReagentCraftability(childReagent.reagentID)
					--DA.DEBUG(2,"     ReagentCraftability: childID="..childReagent.reagentID.." ("..tostring((GetItemInfo(childReagent.reagentID))).."), numReagentOnHand="..tostring(numReagentOnHand)..", numReagentCraftable= "..tostring(numReagentCraftable))
					numReagentCraftable = numReagentCraftable + numReagentOnHand
					if not self:VendorSellsReagent(childReagent.reagentID) then
						numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
					else
						--DA.DEBUG(2,"     ReagentCraftability: VendorSellsReagent")
					end
				end
				numReagentsCrafted = numReagentsCrafted + numCraftable * childRecipe.numMade
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
	if numCrafted == 0 then
		self.db.realm.inventoryData[player][reagentID] = numInBoth
	else
		self.db.realm.inventoryData[player][reagentID] = numInBoth.." "..numCrafted
	end
	--DA.DEBUG(2,"     ReagentCraftability: numInBoth= "..tostring(numInBoth)..", numCrafted= "..tostring(numCrafted)..", reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID)))..")")
	return numCrafted
end

-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
-- (not to be confused with the reagent craftability which is designed to determine how many
-- craftable reagents are available for recipe iterations)
function Skillet:InventorySkillIterations(tradeID, recipe)
	DA.DEBUG(1,"InventorySkillIterations("..tostring(tradeID)..", "..tostring(recipe.name)..")")
	local player = Skillet.currentPlayer
	if player ~= UnitName("player") then
		return 0, 0, 0, 0
	end
	if recipe and recipe.reagentData and #recipe.reagentData > 0 then	-- make sure that recipe is in the database before continuing
		local recipeID = recipe.spellID
		local numMade = recipe.numMade
		local numCraft = 100000
		local numCraftable = 100000
		local numCraftable2 = 100000
		local numCraftVendor = 100000
		local numCraftAlts = 100000
		local vendorOnly = true
		local someVendor = false
		for i=1,#recipe.reagentData do
			if recipe.reagentData[i].reagentID then
				local reagentID = recipe.reagentData[i].reagentID
				local numNeeded = recipe.reagentData[i].numNeeded
				local reagentAvailable = 0
				local reagentCraftable = 0
				local reagentAvailableAlts = 0
				reagentAvailable, reagentCraftable = self:GetInventory(player, reagentID)
				if reagentCraftable == 0 then
					reagentCraftable = self:InventoryReagentCraftability(reagentID)
				end
				for alt in pairs(self.db.realm.inventoryData) do
					if alt ~= player then
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
				DA.DEBUG(2,"     SkillIterations: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), reagentAvailable= "..tostring(reagentAvailable)..", reagentCraftable= "..tostring(reagentCraftable)..", reagentAvailableAlts= "..tostring(reagentAvailableAlts)..", VendorSellsReagent= "..tostring(self:VendorSellsReagent(reagentID)))
				if self:VendorSellsReagent(reagentID) then	-- if it's available from a vendor, then only worry about bag inventory
					local vendorAvailable, vendorAvailableAlts = Skillet:VendorItemAvailable(reagentID)
					someVendor = true
					numCraftAlts = math.min(numCraftAlts, math.floor(vendorAvailableAlts/numNeeded))
					numCraftVendor = math.min(numCraftVendor, math.floor(vendorAvailable/numNeeded))
				else
					vendorOnly = false
					numCraft = math.min(numCraft, math.floor(reagentAvailable/numNeeded))
					numCraftable = math.min(numCraftable, math.floor((reagentAvailable+reagentCraftable)/numNeeded))
					numCraftAlts = math.min(numCraftAlts, math.floor(reagentAvailableAlts/numNeeded))
					numCraftVendor = math.min(numCraftVendor, math.max(numCraft, numCraftable))
				end
				DA.DEBUG(2,"     SkillIterations:      numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftAlts="..tostring(numCraftAlts)..", numCraftVendor="..tostring(numCraftVendor))
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
		recipe.someVendor = someVendor
		DA.DEBUG(2,"      pre-adjustment: recipeID= "..tostring(recipeID).."("..tostring(recipe.name).."), numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts)..", vendorOnly="..tostring(vendorOnly)..", someVendor="..tostring(someVendor))
		if not someVendor then
			numCraftVendor = 0					-- there were no vendor reagents
		end
		if someVendor and numCraft == numCraftVendor and numCraftable == numCraftVendor then
			numCraft = 0						-- only keep vendor count
			numCraftable = 0					-- only keep vendor count
		end
		if numCraft == numCraftable then
			numCraftable = 0					-- only keep craftable count if different
		end
		if numCraft == numCraftVendor then
			numCraftVendor = 0					-- only keep vendor count if different
		end
		if numCraftable == numCraftVendor then
			numCraftVendor = 0					-- only keep vendor count if different
		end
		DA.DEBUG(2,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name).."), numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts)..", vendorOnly="..tostring(vendorOnly)..", someVendor="..tostring(someVendor))
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
				if cachedInventory[reagentID] then
					local a,b,c,d = string.split(" ", cachedInventory[reagentID])
					if numInBoth then
						cachedInventory[reagentID] = tostring(numInBoth).." "..tostring(b or 0).." "..tostring(c or 0).." "..tostring(d or 0)
					else
						--DA.DEBUG(2,"Using cachedInventory")
						numInBoth = a
					end
				else
					--DA.DEBUG(2,"Using Zero")
					numInBoth = 0
				end
				inventoryData[reagentID] = tostring(numInBoth)	-- only what we have for now (no craftability info)
				--DA.DEBUG(2,"inventoryData["..reagentID.."]="..inventoryData[reagentID])
			end
		end
	end
	self.visited = {} -- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice
	if inventoryData then
		-- now calculate the craftability of these same reagents
		for reagentID,inventory in pairs(inventoryData) do
			numCrafted = self:InventoryReagentCraftability(reagentID)
			if numCrafted > 0 then
				inventoryData[reagentID] = tostring(inventoryData[reagentID]).." "..tostring(numCrafted)
			end
		end
		-- remove any reagents that don't show up in our inventory
		for reagentID,inventory in pairs(inventoryData) do
			if inventoryData[reagentID] == 0 or inventoryData[reagentID] == "0" or inventoryData[reagentID] == "0 0" then
				inventoryData[reagentID] = nil
			else
				self.db.realm.inventoryData[player][reagentID] = inventoryData[reagentID]
			end
		end
	end
	--DA.DEBUG(0,"InventoryScan: return")
end

function Skillet:GetInventory(player, reagentID)
	if player and reagentID then
		if self.db.realm.inventoryData[player] and self.db.realm.inventoryData[player][reagentID] then
			local data = { string.split(" ", self.db.realm.inventoryData[player][reagentID]) }
			if #data == 1 then			-- no craftability info yet
				return tonumber(data[1]) or 0, 0
			else
				return tonumber(data[1]) or 0, tonumber(data[2]) or 0
			end
		elseif player == UnitName("player") then
			local numInBoth = GetItemCount(reagentID,true)		-- both bank and bags
			return tonumber(numInBoth) or 0, 0
		end
	end
	return 0, 0		-- have, make
end

-- queries for vendor info for a particular itemID
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
-- Check the LibPeriodicTable data next
	if PT then
		if itemID~=0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
	return false
end

-- returns the number of items that can be bought limited by the amount of currency available
function Skillet:VendorItemAvailable(itemID)
	--DA.DEBUG(0,"VendorItemAvailable("..tostring(itemID)..")")
	local _, divider, currency, currencyAvailable, currencyAvailableAlts = 0
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
				if MissingVendorItem[4] > 0 then
					currencyAvailable = self:GetInventory(self.currentPlayer, MissingVendorItem[4])
				else
					_, currencyAvailable = GetCurrencyInfo(-1 * MissingVendorItem[4])
				end
				--DA.DEBUG(1,"currencyAvailable="..tostring(currencyAvailable))
-- compute how many this player can buy with alternate currency and return 0 for alts
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
