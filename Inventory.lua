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
-- not considering alts
-- does consider queued recipes
function Skillet:InventoryReagentCraftability(reagentID, playerOverride)
	--DA.DEBUG(0,"InventoryReagentCraftability("..tostring(reagentID)..", "..tostring(playerOverride)..") -- "..tostring((GetItemInfo(reagentID))))
	if not reagentID or reagentID == 0 then
		return 0 
	end
	local player = playerOverride or Skillet.currentPlayer
	if self.visited[reagentID] then
		local reagentA, reagentC = self:GetInventory(player, reagentID)
		--DA.DEBUG(0,"     ReagentCraftability: visited reagentID= "..tostring(reagentID).." ("..tostring((GetItemInfo(reagentID))).."), Available= "..tostring(reagentA)..", Craftable= "..tostring(reagentC))
		return reagentC
	end
	self.visited[reagentID] = true
	local recipeSource = self.db.global.itemRecipeSource[reagentID]
	local numReagentsCrafted = 0
	local skillIndexLookup = self.data.skillIndexLookup[player]
	if recipeSource then
		--DA.DEBUG(0,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), recipeSource= "..DA.DUMP1(recipeSource))
		for childRecipeID in pairs(recipeSource) do
			local childRecipe = self:GetRecipe(childRecipeID)
			local childSkillIndex = skillIndexLookup[childRecipeID]		-- only interested in current player for now
			if childSkillIndex and childRecipe and #childRecipe.reagentData > 0 and
			  not Skillet.TradeSkillIgnoredMats[childRecipeID] and not Skillet.db.realm.userIgnoredMats[player][childRecipeID] then
				local numCraftable = 100000
				for i=1,#childRecipe.reagentData,1 do
					local childReagent = childRecipe.reagentData[i]
					local numReagentOnHand = GetItemCount(childReagent.reagentID,true)
					local numReagentCraftable = self:InventoryReagentCraftability(childReagent.reagentID, player)
					--DA.DEBUG(1,"     ReagentCraftability: childID="..childReagent.reagentID.." ("..tostring((GetItemInfo(childReagent.reagentID))).."), numReagentOnHand="..tostring(numReagentOnHand)..", numReagentCraftable= "..tostring(numReagentCraftable))
					numReagentCraftable = numReagentCraftable + numReagentOnHand
					numCraftable = math.min(numCraftable, math.floor(numReagentCraftable/childReagent.numNeeded))
				end
				numReagentsCrafted = numReagentsCrafted + numCraftable * childRecipe.numMade
			end
		end
	else
		--DA.DEBUG(0,"     ReagentCraftability: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), recipeSource= nil")
	end
	local queued = 0
	if self.db.realm.reagentsInQueue[player] then
		queued = self.db.realm.reagentsInQueue[player][reagentID] or 0
	end
	local numInBoth = self:GetInventory(player, reagentID)
	local numCrafted = numReagentsCrafted + queued
	if numCrafted == 0 then
		Skillet.db.realm.inventoryData[player][reagentID] = numInBoth
	else
		Skillet.db.realm.inventoryData[player][reagentID] = numInBoth.." "..numCrafted
	end
	--DA.DEBUG(0,"     ReagentCraftability: numInBoth= "..tostring(numInBoth)..", numCrafted= "..tostring(numCrafted)..", reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID)))..")")
	return numCrafted
end

-- recipe iteration check: calculate how many times a recipe can be iterated with materials available
-- (not to be confused with the reagent craftability which is designed to determine how many
-- craftable reagents are available for recipe iterations)
function Skillet:InventorySkillIterations(tradeID, recipe, playerOverride)
	--DA.DEBUG(0,"InventorySkillIterations("..tostring(tradeID)..", "..DA.DUMP1(recipe)..", "..tostring(playerOverride)..")")
	local player = playerOverride or Skillet.currentPlayer
	if recipe and recipe.reagentData and #recipe.reagentData > 0 then	-- make sure that recipe is in the database before continuing
		local recipeID = recipe.spellID
		local numMade = recipe.numMade
		local numCraft = 100000
		local numCraftable = 100000
		local numCraftable2 = 100000
		local numCraftVendor = 100000
		local numCraftAlts = 100000
		local vendorOnly = true
		for i=1,#recipe.reagentData do
			if recipe.reagentData[i].reagentID then
				local reagentID = recipe.reagentData[i].reagentID
				local numNeeded = recipe.reagentData[i].numNeeded
				local reagentAvailable = 0
				local reagentCraftable = 0
				local reagentAvailableAlts = 0
				reagentAvailable, reagentCraftable = self:GetInventory(player, reagentID)
				if reagentCraftable == 0 then
					reagentCraftable = self:InventoryReagentCraftability(reagentID, player)
				end
				--DA.DEBUG(0,"     SkillIterations: reagentID= "..tostring(reagentID).."("..tostring((GetItemInfo(reagentID))).."), reagentCraftable= "..tostring(reagentCraftable))
				numCraft = math.min(numCraft, math.floor(reagentAvailable/numNeeded))
				numCraftable = math.min(numCraftable, math.floor(reagentCraftable/numNeeded))
				numCraftable2 = math.min(numCraftable2, math.floor((reagentAvailable+reagentCraftable)/numNeeded))
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
				if self:VendorSellsReagent(reagentID) then	-- if it's available from a vendor, then only worry about bag inventory
					local vendorAvailable, vendorAvailableAlt = Skillet:VendorItemAvailable(reagentID)
					numCraftVendor = math.min(numCraftVendor, vendorAvailable)
					numCraftAlts = math.min(numCraftAlts, vendorAvailableAlt)
				else
					vendorOnly = false
					numCraftVendor = math.min(numCraftVendor, math.floor(reagentAvailable/numNeeded))
					numCraftAlts = math.min(numCraftAlts, math.floor(reagentAvailableAlts/numNeeded))
				end
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
		if numCraft == numCraftVendor then
			numCraftVendor = 0					-- only keep vendor count if different
		end
		if numCraftable == 100000 then
			numCraftable = 0					-- there were no craftable reagents
		end
		if numCraftable2 == 100000 then
			numCraftable2 = 0					-- there were no craftable reagents
		end
		if numCraftable == 0 and numCraftable2 ~= 0 and numCraftable2 ~= numCraft then
			numCraftable = numCraftable2
		end

		--DA.DEBUG(0,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name).."), numCraft="..tostring(numCraft)..", numCraftable="..tostring(numCraftable)..", numCraftVendor="..tostring(numCraftVendor)..", numCraftAlts="..tostring(numCraftAlts))
		return numCraft * numMade, numCraftable * numMade, numCraftVendor * numMade, numCraftAlts * numMade
	else
		DA.DEBUG(0,"     SkillIterations: recipeID= "..tostring(recipeID).."("..tostring(recipe.name)..") has no reagent data")
	end
	return 0, 0, 0, 0
end

function Skillet:InventoryScan(playerOverride)
	DA.DEBUG(0,"InventoryScan("..tostring(playerOverride)..")")
	if self.linkedSkill or self.isGuild then
		return
	end
	local player = playerOverride or self.currentPlayer
	local cachedInventory = self.db.realm.inventoryData[player]
	local inventoryData = {}
	local reagent
	local numInBoth
	if self.db.global.itemRecipeUsedIn then
		for reagentID in pairs(self.db.global.itemRecipeUsedIn) do
			local a = GetItemInfo(reagentID)
			local b = inventoryData[reagentID]
			--DA.DEBUG(2,"reagent "..tostring(a).." "..tostring(b))
			if reagentID and not inventoryData[reagentID] then				-- have we calculated this one yet?
				if self.currentPlayer == (UnitName("player")) then			-- if this is the current player, use the API
					--DA.DEBUG(2,"Using API")
					numInBoth = GetItemCount(reagentID,true)				-- both bank and bags
				elseif cachedInventory and cachedInventory[reagentID] then	-- otherwise, use what cached data is available
					--DA.DEBUG(2,"Using cachedInventory")
					local a,b,c,d = string.split(" ", cachedInventory[reagentID])
					numInBoth = a
				else
					--DA.DEBUG(2,"Using Zero")
					numInBoth = 0
				end
				inventoryData[reagentID] = tostring(numInBoth)	-- only what we have for now (no craftability info)
				--DA.DEBUG(2,"inventoryData["..reagentID.."]="..inventoryData[reagentID])
			end
		end
	end
	if not self.visited then
		self.visited = {} -- this is a simple infinite loop avoidance scheme: basically, don't visit the same node twice
	end
	if inventoryData then
		-- now calculate the craftability of these same reagents
		for reagentID,inventory in pairs(inventoryData) do
			numCrafted = self:InventoryReagentCraftability(reagentID, player)
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