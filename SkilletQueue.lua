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

local L = Skillet.L

local function tcopy(t)
	local u = {}
	if t then
		for k, v in pairs(t) do u[k] = v end
		return setmetatable(u, getmetatable(t))
	end
	return {}
end

--
-- Iterates through a list of reagentIDs and recalculates craftability
--
function Skillet:AdjustInventory()
	DA.DEBUG(0,"AdjustInventory()")
	-- update queue for faster response time
	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	self:CalculateCraftableCounts()
	-- update whole window to show craft counts
	self:UpdateTradeSkillWindow()
end

--
-- This is the simplest command:  iterate recipeID x count
--
function Skillet:QueueCommandIterate(recipeID, count)
	local recipe = self:GetRecipe(recipeID)
	DA.DEBUG(0,"QueueCommandIterate("..tostring(recipeID)..", "..tostring(count).."), name= "..tostring(recipe.name))
	--DA.DEBUG(0,"QueueCommandIterate: recipe= "..DA.DUMP1(recipe))
	local tradeID = recipe.tradeID
	local tradeName = self.tradeSkillNamesByID[tradeID]
	local newCommand = {}
	newCommand.op = "iterate"
	newCommand.tradeID = tradeID
	newCommand.tradeName = tradeName
	newCommand.recipeID = recipeID
	newCommand.recipeName = recipe.name
	newCommand.recipeType = recipe.recipeType
	newCommand.count = count
	newCommand.recipeLevel = self.recipeRank or 0
	if recipe.numModified and recipe.numModified ~= 0 then
		newCommand.complex = true
		newCommand.modified = true
		newCommand.modifiedReagents = {}
		for j=1,recipe.numModified do
			newCommand.modifiedReagents[j] = self:InitializeModifiedSelected(recipe.modifiedData[j])
		end
	end
	if recipe.numRequired and recipe.numRequired ~= 0 then
		newCommand.complex = true
		newCommand.requiredReagents = {}
		if recipe.numRequired == 1 and self.requiredSelected then
			newCommand.requiredReagents = self.requiredSelected
		else
			for j=1,recipe.numRequired do
				newCommand.requiredReagents[j] = { itemID = 0, quantity = 0, 
					dataSlotIndex = recipe.modifiedData[j].slot, name = recipe.modifiedData[j].name }
			end
			DA.DEBUG(0,"QueueCommandIterate: requiredReagents= "..DA.DUMP1(newCommand.requiredReagents))
		end
	end
	if recipe.numOptional and recipe.numOptional ~= 0 then
		if self.optionalSelected then
			newCommand.optionalReagents = self.optionalSelected
		end
	end
	if recipe.numFinishing and recipe.numFinishing ~= 0 then
		if self.finishingSelected then
			newCommand.finishingReagents = self.finishingSelected
		end
	end
	if recipe.recipeType == Enum.TradeskillRecipeType.Salvage then
		if self.salvageSelected then
			newCommand.salvageItem = self.salvageSelected[1]
		end
	end
	return newCommand
end

--
-- Reserve reagents
--
local function queueAppendReagent(command, reagentID, need, queueCraftables, mreagent)
	local reagentName = C_Item.GetItemInfo(reagentID)
	DA.DEBUG(0,"queueAppendReagent("..tostring(reagentID)..", "..tostring(need)..", "..tostring(queueCraftables).."), name= "..tostring(reagentName))
	local reagentsInQueue = Skillet.db.realm.reagentsInQueue[Skillet.currentPlayer]
	local skillIndexLookup = Skillet.data.skillIndexLookup
	local have = 0
	if not mreagent then
		local numInBoth = C_Item.GetItemCount(reagentID,true,false,true,true)
		local numInBags = C_Item.GetItemCount(reagentID)
		local numInBank =  numInBoth - numInBags
		local numInQueue = reagentsInQueue[reagentID] or 0
		--DA.DEBUG(1,"queueAppendReagent: numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank)..", numInQueue="..tostring(numInQueue))
		if Skillet.db.profile.ignore_queued_reagents then
			numInQueue = 0
		end
		if Skillet.db.profile.ignore_banked_reagents then
			have = numInBags + numInQueue
		else
			have = numInBoth + numInQueue
		end
	else
		--DA.DEBUG(2,"queueAppendReagent: mreagent= "..DA.DUMP(mreagent))
		for k=1, #mreagent.schematic.reagents, 1 do
			mitem = mreagent.schematic.reagents[k].itemID
			have = have + C_Item.GetItemCount(mitem,true,false,true,true)
		end
	end
	reagentsInQueue[reagentID] = (reagentsInQueue[reagentID] or 0) - need
	DA.DEBUG(1,"queueAppendReagent: queueCraftables= "..tostring(queueCraftables)..", need= "..tostring(need)..", have= "..tostring(have))
	if queueCraftables and need > have then
		local recipeSource = Skillet.db.global.itemRecipeSource[reagentID]
		--DA.DEBUG(2,"queueAppendReagent: recipeSource= "..DA.DUMP1(recipeSource))
		if recipeSource then
			for recipeSourceID in pairs(recipeSource) do
				local skillIndex = skillIndexLookup[recipeSourceID]
				--DA.DEBUG(3,"queueAppendReagent: recipeSourceID= "..tostring(recipeSourceID)..", skillIndex= "..tostring(skillIndex))
				if skillIndex then
--
-- Identify that this queue has craftable reagent requirements
--
					command.complex = true
					local recipeSource = Skillet:GetRecipe(recipeSourceID)
					local newCount = math.ceil((need - have)/recipeSource.numMade)
					local newCommand = Skillet:QueueCommandIterate(recipeSourceID, newCount)
					newCommand.level = (command.level or 0) + 1
--
-- Do not add IgnoredMats as it would cause loops
--
					if not Skillet.TradeSkillIgnoredMats[recipeSourceID] and
					  not Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeSourceID] then
						if newCommand.modified and Skillet.db.profile.queue_one_at_a_time then
							newCommand.count = 1
							for i=1, newCount, 1 do
								local c = tcopy(newCommand)
								Skillet:QueueAppendCommand(c, queueCraftables)
							end
						else
							Skillet:QueueAppendCommand(newCommand, queueCraftables)
						end
						break
					else
						DA.DEBUG(3,"queueAppendReagent: Did Not Queue "..tostring(recipeSourceID).." ("..tostring(recipeSource.name)..")")
					end
				end
			end -- for
		end
	end
end

--
-- Queue up the command and reserve reagents
--
function Skillet:QueueAppendCommand(command, queueCraftables, first)
	DA.DEBUG(0,"QueueAppendCommand("..DA.DUMP(command)..", "..tostring(queueCraftables).."), visited=  "..tostring(self.visited[command.recipeID]))
	local recipe = self:GetRecipe(command.recipeID)
	--DA.DEBUG(0,"QueueAppendCommand: recipe= "..DA.DUMP(recipe))
	if recipe and not self.visited[command.recipeID] then
		self.visited[command.recipeID] = true
		local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
		local modifiedInQueue = self.db.realm.modifiedInQueue[Skillet.currentPlayer]
		local skillIndexLookup = self.data.skillIndexLookup
		local queueGlyph = Skillet.db.profile.queue_glyph_reagents or not recipe.name:match(Skillet.L["Glyph "])
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if command.recipeLevel and command.recipeLevel > 0 then
				--DA.DEBUG(2,"QueueAppendCommand: recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(command.recipeLevel))
				local reagentName, reagentTexture, reagentCount, playerReagentCount = C_TradeSkillUI.GetRecipeReagentInfo(command.recipeID, i, command.recipeLevel)
				--DA.DEBUG(2,"QueueAppendCommand: reagentName= "..tostring(reagentName)..", reagentCount= "..tostring(reagentCount))
				local reagentLink = C_TradeSkillUI.GetRecipeReagentItemLink(command.recipeID, i)
				local reagentID = Skillet:GetItemIDFromLink(reagentLink)
				if reagent.reagentID == reagentID then
					reagent.numNeeded = reagentCount
				else
					DA.DEBUG(0,"QueueAppendCommand: Reagent Mismatch, i= "..tostring(i)..", reagentID= "..tostring(reagent.reagentID)..", mismatch= "..tostring(reagentID))
				end
			end
			DA.DEBUG(2,"QueueAppendCommand: reagent= "..DA.DUMP(reagent))
			queueAppendReagent(command, reagent.reagentID, command.count * reagent.numNeeded, queueCraftables and queueGlyph)
		end -- for
		if recipe.modifiedData then
			for i=1,#recipe.modifiedData do
				local reagent = recipe.modifiedData[i]
				--DA.DEBUG(2,"QueueAppendCommand: reagent= "..DA.DUMP(reagent))
				queueAppendReagent(command, reagent.reagentID, command.count * reagent.numNeeded, queueCraftables and queueGlyph, reagent)
				modifiedInQueue[reagent.reagentID] = reagent.schematic.reagents
			end
		end
		if command.requiredReagents then
			for i,reagent in pairs(command.requiredReagents) do
				DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
				queueAppendReagent(command, reagent.itemID, command.count, queueCraftables)
			end
		end
		if command.optionalReagents then
			for i,reagent in pairs(command.optionalReagents) do
				DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
				queueAppendReagent(command, reagent.itemID, command.count, queueCraftables)
			end
		end
		if command.finishingReagents then
			for i,reagent in pairs(command.finishingReagents) do
				DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
				queueAppendReagent(command, reagent.itemID, command.count, queueCraftables)
			end
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) + command.count * recipe.numMade;
		self:AddToQueue(command, first)
		self.visited[command.recipeID] = nil
		self:AdjustInventory()
	end
end

local function sameOptionals(a, b)
	--DA.DEBUG(0,"sameOptionals("..DA.DUMP1(a).."', "..DA.DUMP1(b)..")")
	if a.modifiedReagents or b.modifiedReagents then
		DA.DEBUG(0,"sameOptionals: modified reagents exist")
		return false
	end
	local ao = ""
	local bo = ""
	local af = ""
	local bf = ""
	local as = ""
	local bs = ""
	if a.optionalReagents then
		for i,reagentID in pairs(a.optionalReagents) do
			ao = ao..tostring(i).."="..tostring(reagentID).." "
		end
	end
	if b.optionalReagents then
		for i,reagentID in pairs(b.optionalReagents) do
			bo = bo..tostring(i).."="..tostring(reagentID).." "
		end
	end
	if a.finishingReagents then
		for i,reagentID in pairs(a.finishingReagents) do
			af = af..tostring(i).."="..tostring(reagentID).." "
		end
	end
	if b.finishingReagents then
		for i,reagentID in pairs(b.finishingReagents) do
			bf = bf..tostring(i).."="..tostring(reagentID).." "
		end
	end
	if a.salvageItem then
		as = a.salvageItem
	end
	if b.salvageItem then
		bs = b.salvageItem
	end
	--DA.DEBUG(0,"sameOptionals: ao= '"..tostring(ao).."', bo= '"..tostring(bo).."' == "..tostring(ao == bo))
	--DA.DEBUG(0,"sameOptionals: af= '"..tostring(af).."', bf= '"..tostring(bf).."' == "..tostring(af == bf))
	--DA.DEBUG(0,"sameOptionals: as= '"..tostring(as).."', bs= '"..tostring(bs).."' == "..tostring(as == bs))
	return (ao == bo and af == bf and as == bs)
end

--
-- command.complex means the queue entry requires additional crafting to take place prior to entering the queue.
-- we can't just increase the # of the first command if it happens to be the same recipe without making sure
-- the additional queue entry doesn't require some additional craftable reagents
--
function Skillet:AddToQueue(command, first)
	DA.DEBUG(0,"AddToQueue("..DA.DUMP1(command)..", "..tostring(first)..")")
	local queue = self.db.realm.queueData[self.currentPlayer]
	if (not command.complex) then
--
-- Check if we can add this queue entry to any of the other entries
-- Add a new entry to either the beginning or the end of the queue
--
		local added
		for i=1,#queue,1 do
			if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID and queue[i].recipeLevel == command.recipeLevel then
				queue[i].count = queue[i].count + command.count
				added = true
				break
			end
		end
		if not added then
			if first then
				table.insert(queue, 1, command)
			else
				table.insert(queue, command)
			end
		end
	elseif queue and #queue > 0 then
--
-- Complex command, check first or last item in queue - add to current entry if they are the same and
-- add to the beginning or the end of the queue if they are not the same.
--
		local i
		if first then
			i = 1
		else
			i = #queue
		end
		if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID and queue[i].recipeLevel == command.recipeLevel and sameOptionals(queue[i], command) then
			queue[i].count = queue[i].count + command.count
		else
			if first then
				table.insert(queue, 1, command)
			else
				table.insert(queue, command)
			end
		end
	else
		if first then
			table.insert(queue, 1, command)
		else
			table.insert(queue, command)
		end
	end
end

function Skillet:RemoveFromQueue(index)
	DA.DEBUG(0,"RemoveFromQueue("..tostring(index)..")")
	local queue = self.db.realm.queueData[self.currentPlayer]
	local command = queue[index]
	local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
	if command.op == "iterate" then
		local recipe = self:GetRecipe(command.recipeID)
		if not command.count then
			command.count = 1
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) - recipe.numMade * command.count
	end
	table.remove(queue, index)
	self:AdjustInventory()
	return #queue or 0
end

function Skillet:ClearQueue()
	--DA.DEBUG(0,"ClearQueue()")
	if #self.db.realm.queueData[self.currentPlayer] > 0 then
		if self.db.profile.confirm_queue_clear and not IsAltKeyDown() then
			return
		end
		self.db.realm.queueData[self.currentPlayer] = {}
		self.db.realm.reagentsInQueue[self.currentPlayer] = {}
		self.db.realm.modifiedInQueue[self.currentPlayer] = {}
		self:UpdateTradeSkillWindow()
	end
end

--
-- Prints a list of saved queues
--
function Skillet:PrintSaved()
	--DA.DEBUG(0,"PrintSaved()");
	local saved = self.db.profile.SavedQueues
	if saved then
		for name,queue in pairs(saved) do
			local size = 0
			for qpos,command in pairs(queue) do
				size = size + 1
			end
			DA.MARK2("name= "..tostring(name)..", size= "..tostring(size))
		end
	end
end

--
-- Prints the contents of the queue name or the current queue
--
function Skillet:PrintQueue(name, player)
	--DA.DEBUG(0,"PrintQueue("..tostring(name)..", "..tostring(player)..")")
	local queue
	if name then
		DA.MARK2("name= "..tostring(name))
		queue = self.db.profile.SavedQueues[name].queue
	elseif player then
		queue = self.db.realm.queueData[player]
	else
		queue = self.db.realm.queueData[self.currentPlayer]
	end
	if queue then
		for qpos,command in pairs(queue) do
			DA.MARK2("qpos= "..tostring(qpos)..", command= "..DA.DUMP(command))
		end
	end
end

function Skillet:PrintAllQueues()
	--DA.DEBUG(0,"PrintAllQueues()")
	for player,queue in pairs(self.db.realm.queueData) do
		if #queue > 0 then
			DA.MARK2("player= "..tostring(player))
			self:PrintQueue(nil,player)
		end
	end
end

--
-- Prints the list of reagentsInQueue
--
function Skillet:PrintRIQ()
	--DA.DEBUG(0,"PrintRIQ()");
	local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
	local modifiedInQueue = self.db.realm.modifiedInQueue[Skillet.currentPlayer]
	if reagentsInQueue then
		for id,count in pairs(reagentsInQueue) do
			local name = C_Item.GetItemInfo(id)
			DA.MARK2("reagent: "..id.." ("..tostring(name)..") x "..count)
			if modifiedInQueue[id] then
				DA.MARK2("    "..DA.DUMP1(modifiedInQueue[id]))
			end
		end
	end
end

local function ApplyAllocations(transaction, requiredReagents, modifiedReagents, optionalReagents, finishingReagents)
	local reagentsToQuantity = {}
	local haverequired = true
	if requiredReagents then
		for _, all in ipairs(requiredReagents) do
			for _, item in ipairs(all) do
				reagentsToQuantity[item.itemID] = item.quantity
			end
		end
	end
	if modifiedReagents then
		for _, all in ipairs(modifiedReagents) do
			for _, item in ipairs(all) do
				reagentsToQuantity[item.itemID] = item.quantity
			end
		end
	end
	if optionalReagents then
		for _, all in ipairs(optionalReagents) do
			for _, item in ipairs(all) do
				reagentsToQuantity[item.itemID] = item.quantity
			end
		end
	end
	if finishingReagents then
		for _, all in ipairs(finishingReagents) do
			for _, item in ipairs(all) do
				reagentsToQuantity[item.itemID] = item.quantity
			end
		end
	end
	--DA.DEBUG(0,"ApplyAllocations: reagentsToQuantity= "..DA.DUMP1(reagentsToQuantity))
	local schematic = transaction:GetRecipeSchematic()
	for slotID, s in ipairs(schematic.reagentSlotSchematics) do
		for _, r in ipairs(s.reagents) do
			if reagentsToQuantity[r.itemID] then
				transaction:OverwriteAllocation(slotID, r, reagentsToQuantity[r.itemID])
			end
		end
		if s.required and not transaction:HasAllAllocations(slotID, s.quantityRequired) then
			DA.DEBUG(0,"ApplyAllocations: missing required quantity, slotID= "..tostring(slotID)..", need= "..tostring(s.quantityRequired))
			haverequired = false
		end
	end
	return haverequired
end

function Skillet:ProcessQueue(altMode)
	DA.DEBUG(0,"ProcessQueue("..tostring(altMode)..")");
	local queue = self.db.realm.queueData[self.currentPlayer]
	--DA.DEBUG(1,"queue= "..DA.DUMP1(queue))
	local qpos = 1
	self.processingPosition = nil
	self.processingCommand = nil
	self.processingCount = nil
	if self.currentPlayer ~= (UnitName("player")) then
		DA.DEBUG(0,"trying to process from an alt!")
		return
	end
	local command, craftable
--
-- If any plugins have registered a ProcessQueue function, call it now
--
	self:ProcessQueuePlugins()
--
-- find the first queue entry that is craftable
--
	repeat
		command = queue[qpos]
		--DA.DEBUG(1,DA.DUMP1(command))
		if command and command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			craftable = true
			if self:IsRecipeOnCooldown(command.recipeID) then
				Skillet:Print(L["Skipping"],recipe.name,"-",PROFESSIONS_RECIPE_COOLDOWN) -- L["is on cooldown"], ON_COOLDOWN
				craftable = false
			else
				if command.recipeType == Enum.TradeskillRecipeType.Item or command.recipeType == Enum.TradeskillRecipeType.Enchant then
--
-- Check required reagents
--
					for i=1,#recipe.reagentData do
						local reagent = recipe.reagentData[i]
						if command.recipeLevel and command.recipeLevel > 0 then
							--DA.DEBUG(2,"ProcessQueue: recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(command.recipeLevel))
							local reagentName, reagentTexture, reagentCount, playerReagentCount = C_TradeSkillUI.GetRecipeReagentInfo(command.recipeID, i, command.recipeLevel)
							--DA.DEBUG(2,"ProcessQueue: reagentName= "..tostring(reagentName)..", reagentCount= "..tostring(reagentCount))
							local reagentLink = C_TradeSkillUI.GetRecipeReagentItemLink(command.recipeID, i)
							local reagentID = Skillet:GetItemIDFromLink(reagentLink)
							if reagent.reagentID == reagentID then
								reagent.numNeeded = reagentCount
							else
								DA.DEBUG(0,"ProcessQueue: Reagent Mismatch, i= "..tostring(i)..", reagentID= "..tostring(reagent.reagentID)..", mismatch= "..tostring(reagentID))
							end
						end
						local reagentName = C_Item.GetItemInfo(reagent.reagentID) or reagent.reagentID
						--DA.DEBUG(2,"ProcessQueue: id= "..tostring(reagent.reagentID)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(reagent.numNeeded))
						local numInBoth = C_Item.GetItemCount(reagent.reagentID,true,false,true,true)
						local numInBags = C_Item.GetItemCount(reagent.reagentID)
						local numInBank =  numInBoth - numInBags
						--DA.DEBUG(2,"ProcessQueue: numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
						if numInBoth < reagent.numNeeded then
							Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],reagent.numNeeded*command.count,"x",reagentName,"("..L["have"],numInBoth..")")
							craftable = false
							break
						end
					end -- for
--
-- Modified reagents
--
					if command.modifiedReagents then
						for j=1,recipe.numModified do
							command.modifiedReagents[j], craftable = self:InitializeModifiedSelected(recipe.modifiedData[j])
							if not craftable then
								DA.DEBUG(2,"ProcessQueue: j= "..tostring(j)..", modifiedReagent="..DA.DUMP(command.modifiedReagents[j]))
								break
							end
						end
						if not craftable then
							Skillet:Print(L["Skipping"],recipe.name)
							DA.DEBUG(2,"ProcessQueue: craftable= "..tostring(craftable)..", modifiedReagents="..DA.DUMP(command.modifiedReagents))
							break
						end
					end
--
-- Required reagents
--
					if command.requiredReagents then
						for i,reagent in pairs(command.requiredReagents) do
							--DA.DEBUG(2,"ProcessQueue(R): i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							local reagentID = reagent.itemID
							local reagentName = C_Item.GetItemInfo(reagentID) or reagentID
							--DA.DEBUG(2,"ProcessQueue(R): oid= "..tostring(reagentID)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(command.count))
							local numInBoth = C_Item.GetItemCount(reagentID,true,false,true,true)
							local numInBags = C_Item.GetItemCount(reagentID)
							local numInBank =  numInBoth - numInBags
							--DA.DEBUG(2,"ProcessQueue(R): numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
							if numInBoth < command.count then
								Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],command.count,"x",reagentName,"("..L["have"],numInBoth..")")
								craftable = false
								break
							end
						end -- for
					end
--
-- Optional reagents
--
					if command.optionalReagents then
						for i,reagent in pairs(command.optionalReagents) do
							--DA.DEBUG(2,"ProcessQueue(O): i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							local reagentID = reagent.itemID
							local reagentName = C_Item.GetItemInfo(reagentID) or reagentID
							--DA.DEBUG(2,"ProcessQueue(O): oid= "..tostring(reagentID)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(command.count))
							local numInBoth = C_Item.GetItemCount(reagentID,true,false,true,true)
							local numInBags = C_Item.GetItemCount(reagentID)
							local numInBank =  numInBoth - numInBags
							--DA.DEBUG(2,"ProcessQueue(O): numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
							if numInBoth < command.count then
								Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],command.count,"x",reagentName,"("..L["have"],numInBoth..")")
								craftable = false
								break
							end
						end -- for
					end
--
-- Finishing reagents
--
					if command.finishingReagents then
						for i,reagent in pairs(command.finishingReagents) do
							--DA.DEBUG(2,"ProcessQueue(F): i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							local reagentID = reagent.itemID
							local reagentName = C_Item.GetItemInfo(reagentID) or reagentID
							--DA.DEBUG(2,"ProcessQueue(F): oid= "..tostring(reagentID)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(command.count))
							local numInBoth = C_Item.GetItemCount(reagentID,true,false,true,true)
							local numInBags = C_Item.GetItemCount(reagentID)
							local numInBank =  numInBoth - numInBags
							--DA.DEBUG(2,"ProcessQueue(F): numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
							if numInBoth < command.count then
								Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],command.count,"x",reagentName,"("..L["have"],numInBoth..")")
								craftable = false
								break
							end
						end -- for
					end
--
-- Check for type Recraft
--
				elseif command.recipeType == Enum.TradeskillRecipeType.Recraft then
					DA.DEBUG(1,"ProcessQueue(Re): command= "..DA.DUMP(command))
					DA.DEBUG(1,"ProcessQueue(Re): recipe= "..DA.DUMP(recipe))
--					result = C_TradeSkillUI.RecraftRecipe(itemGUID [, craftingReagents [, removedModifications [, applyConcentration]]])
					craftable = false
					break
--
-- Check for type Salvage
--
				elseif command.recipeType ~= Enum.TradeskillRecipeType.Salvage then
					DA.DEBUG(1,"ProcessQueue(S): command= "..DA.DUMP(command))
					DA.DEBUG(1,"ProcessQueue(S): recipe= "..DA.DUMP(recipe))
--					C_TradeSkillUI.CraftSalvage(recipeSpellID, [numCasts], itemTarget [, craftingReagents [, applyConcentration]])
					craftable = false
					break
				end
			end
			if craftable then break end
		end
		qpos = qpos + 1
	until qpos > #queue
--
-- If we can't craft anything, show error from first item in queue
--
	if qpos > #queue then
		qpos = 1
		command = queue[qpos]
	end
	if command and craftable then
		if command.op == "iterate" then
			if self.currentTrade ~= command.tradeID then
				self:Print(L["Changing profession to"],tradeName,L["Press Process to continue"])
				local tradeID = command.tradeID
				local tradeName = command.tradeName
				self.queuecasting = false
				self:ChangeTradeSkill(tradeID, tradeName)
				self:QueueMoveToTop(qpos)
				return
			end
			local recipe = self:GetRecipe(command.recipeID)
			if command.recipeType == Enum.TradeskillRecipeType.Item or command.recipeType == Enum.TradeskillRecipeType.Enchant then
				local numAvailable = C_TradeSkillUI.GetCraftableCount(command.recipeID) or 0
				if numAvailable > 0 then
					self.processingSpell = self:GetRecipeName(command.recipeID)
					self.processingSpellID = command.recipeID
					self.processingPosition = qpos
					self.processingCommand = command
					self.adjustInventory = true
--
-- If alt down/right click - auto use items / like vellums
--
					if altMode then
						local itemID = Skillet:GetAutoTargetItem(command.tradeID)
						if itemID then
							self.processingCount = 1
							DA.DEBUG(1,"altMode Crafting: "..tostring(self.processingSpell).." ("..tostring(command.recipeID)..") and using "..tostring(itemID))
							self.queuecasting = true
							self.processingCount = 1
							C_TradeSkillUI.CraftRecipe(command.recipeID, 1)
							UseItemByName(itemID)
							self.queuecasting = false
							return
						end
					end
					if command.count > numAvailable then
						command.count = numAvailable
					end
					DA.DEBUG(1,"Crafting: "..tostring(command.count).." of "..tostring(self.processingSpell).." ("..tostring(command.recipeID)..")")
					self.queuecasting = true
					self.processingCount = command.count
					local recipeLevel = 0
					if command.recipeLevel then
						recipeLevel = command.recipeLevel
					end
					self.processingLevel = recipeLevel
--
-- Prepare to craft one item at a time.
--
					self.optionalReagentsArray = {}
					if command.modifiedReagents then
						for i,items in pairs(command.modifiedReagents) do
							for j,reagent in pairs(items) do
								DA.DEBUG(2,"Modified: i= "..tostring(i)..", j= "..tostring(j)..", item= "..DA.DUMP1(reagent))
								if reagent.quantity ~= 0 then
									table.insert(self.optionalReagentsArray, reagent)
								end
							end
						end -- for
					end
					if command.requiredReagents then
						local required = 0
						for i,reagent in pairs(command.requiredReagents) do
							DA.DEBUG(2,"Required: i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							table.insert(self.optionalReagentsArray, reagent)
							required = required + 1
						end -- for
						if required == 0 then
							DA.MARK3(L["Required reagents missing"])
						end
					end
					if command.optionalReagents then
						for i,reagent in pairs(command.optionalReagents) do
							DA.DEBUG(2,"Optional: i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							table.insert(self.optionalReagentsArray, reagent)
						end -- for
					end
					if command.finishingReagents then
						for i,reagent in pairs(command.finishingReagents) do
							DA.DEBUG(2,"Finishing: i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
							table.insert(self.optionalReagentsArray, reagent)
						end -- for
					end
					command.optionalReagentsArray = self.optionalReagentsArray
--
-- Prepare to craft all items in this queue entry at once.
--					
					self.recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(command.recipeID, false, recipeLevel)
					--DA.DEBUG(1,"ProcessQueue: recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(recipeLevel)..", recipeSchematic= "..DA.DUMP(self.recipeSchematic))
					self.recipeTransaction = CreateProfessionsRecipeTransaction(self.recipeSchematic)
					ApplyAllocations(self.recipeTransaction, command.requiredReagents, command.modifiedReagents, command.optionalReagents, command.finishingReagents)
					--DA.DEBUG(1,"ProcessQueue: recipeID= "..tostring(command.recipeID)..", recipeTransaction= "..DA.DUMP(self.recipeTransaction))
					self.reagentInfoTbl = self.recipeTransaction:CreateCraftingReagentInfoTbl()
					DA.DEBUG(1,"ProcessQueue: reagentInfoTbl= "..DA.DUMP(self.reagentInfoTbl))
					command.reagentInfoTbl = self.reagentInfoTbl
--
-- For debugging, save the command and TraceLog setting. Restored in ContinueCast.
-- FakeIt is used to test the creation of the CraftRecipe parameters without wasting materials.
--
					self.command = command
					self.oldTraceLog = DA.TraceLog
					--DA.TraceLog = true
					if self.FakeIt then
						if self.db.profile.queue_one_at_a_time then
							DA.DEBUG(1,"ProcessQueue: recipeID= "..tostring(command.recipeID)..",recipeLevel= "..tostring(recipeLevel)..", optionalReagentsArray= "..DA.DUMP(command.optionalReagentsArray))
						else
							DA.DEBUG(1,"ProcessQueue: recipeID= "..tostring(command.recipeID)..",recipeLevel= "..tostring(recipeLevel)..", recipeTransaction= "..DA.DUMP(self.recipeTransaction))
							DA.DEBUG(1,"ProcessQueue: reagentInfoTbl= "..DA.DUMP(self.reagentInfoTbl))
							DA.DEBUG(1,"ProcessQueue: HasAllAllocations= "..tostring(self.recipeTransaction:HasAllAllocations(command.count)))
							DA.DEBUG(1,"ProcessQueue: HasMetQuantityRequirements= "..tostring(self.recipeTransaction:HasMetQuantityRequirements()))
							if not self.recipeTransaction:HasMetQuantityRequirements() then
								DA.MARK3("Insufficient Materials available")
							end
						end
					else
						if command.recipeType == Enum.TradeskillRecipeType.Item then
							if self.db.profile.queue_one_at_a_time then
								--DA.DEBUG(1,"ProcessQueue(1I) recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(recipeLevel)..", optionalReagentsArray= "..DA.DUMP(command.optionalReagentsArray))
--								C_TradeSkillUI.CraftRecipe(recipeSpellID [, numCasts [, craftingReagents [, recipeLevel [, orderID [, applyConcentration]]]]])
								C_TradeSkillUI.CraftRecipe(command.recipeID, command.count, command.optionalReagentsArray, recipeLevel, nil, self.db.profile.use_concentration)
							else
								DA.DEBUG(1,"ProcessQueue(I): recipeID= "..tostring(command.recipeID))
								C_TradeSkillUI.CraftRecipe(command.recipeID, command.count, reagentInfoTbl, recipeLevel, nil, self.db.profile.use_concentration)
							end
						elseif command.recipeType == Enum.TradeskillRecipeType.Enchant then
							if self.db.profile.queue_one_at_a_time then
								--DA.DEBUG(1,"ProcessQueue(1E) recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(recipeLevel)..", optionalReagentsArray= "..DA.DUMP(command.optionalReagentsArray))
--								C_TradeSkillUI.CraftRecipe(recipeSpellID [, numCasts [, craftingReagents [, recipeLevel [, orderID [, applyConcentration]]]]])
								C_TradeSkillUI.CraftRecipe(command.recipeID, command.count, command.optionalReagentsArray, recipeLevel, _, self.db.profile.use_concentration)
							else							
								if command.count > 1 then
									local itemID = Skillet:GetAutoTargetItem(command.tradeID)
									DA.DEBUG(1,"ProcessQueue(E): itemID= "..tostring(itemID))
									self.itemLocation = self:GetItemLocationFromItemID(itemID)
									DA.DEBUG(1,"ProcessQueue(E): itemLocation= "..DA.DUMP(self.itemLocation))
--									C_TradeSkillUI.CraftEnchant(recipeSpellID [, numCasts [, craftingReagents [, itemTarget [, applyConcentration]]]])
									DA.DEBUG(1,"ProcessQueue(E): recipeID= "..tostring(command.recipeID))
									C_TradeSkillUI.CraftEnchant(command.recipeID, command.count, reagentInfoTbl, self.itemLocation, self.db.profile.use_concentration)
								else
--									C_TradeSkillUI.CraftRecipe(recipeSpellID [, numCasts [, craftingReagents [, recipeLevel [, orderID [, applyConcentration]]]]])
									DA.DEBUG(1,"ProcessQueue(E1): recipeID= "..tostring(command.recipeID))
									C_TradeSkillUI.CraftRecipe(command.recipeID, command.count, reagentInfoTbl, recipeLevel, nil, self.db.profile.use_concentration)
								end
							end
						end
					end
				else
--
-- C_TradeSkillUI.GetCraftableCount failed
--
					DA.MARK3(L["Insufficient materials available"].." count= "..tostring(command.count)..", numAvailable= "..tostring(numAvailable))
					self.queuecasting = false
				end
			elseif command.recipeType == Enum.TradeskillRecipeType.Recraft then
				DA.DEBUG(1,"ProcessQueue(Re): command= "..DA.DUMP(command))
				DA.DEBUG(1,"ProcessQueue(Re): recipe= "..DA.DUMP(recipe))
				DA.MARK3(L["Recraft not supported"])
			elseif command.recipeType == Enum.TradeskillRecipeType.Salvage then
				if command.salvageItem then
					local numAvailable = 0
					DA.DEBUG(1,"ProcessQueue(S): salvageItem= "..tostring(command.salvageItem))
					local targetItems = C_TradeSkillUI.GetCraftingTargetItems(recipe.salvage)
					DA.DEBUG(2,"ProcessQueue(S): targetItems= "..DA.DUMP1(targetItems))
					for i,targetItem in pairs(targetItems) do
						if targetItem.itemID == command.salvageItem then
							self.itemTarget = C_Item.GetItemLocation(targetItem.itemGUID)
							numAvailable = targetItem.quantity / (recipe.numUsed or 1)
						end
					end
					DA.DEBUG(1,"ProcessQueue(S): itemTarget= "..DA.DUMP1(self.itemTarget))
					command.itemTarget = self.itemTarget
					if command.count > numAvailable then
						command.count = numAvailable
					end
					self.command = command
					self.processingSpell = self:GetRecipeName(command.recipeID)
					self.processingSpellID = command.recipeID
					self.processingPosition = qpos
					self.processingCommand = command
					self.processingCount = command.count
					self.salvageItem = command.salvageItem
					self.queuecasting = true
--					C_TradeSkillUI.CraftSalvage(recipeSpellID, [numCasts], itemTarget [, craftingReagents [, applyConcentration]])
					C_TradeSkillUI.CraftSalvage(command.recipeID, command.count, command.itemTarget, nil, self.db.profile.use_concentration)
				end
			else
				DA.MARK3(L["Salvage reagent missing"])
			end
		else
			DA.DEBUG(0,"Unsupported queue op: "..tostring(command.op))
		end
	end
end

--
-- Adds the currently selected number of items to the queue
--
function Skillet:QueueItems(button, count)
	DA.DEBUG(0,"QueueItems("..tostring(button)..", "..tostring(count)..")")
	if self.currentTrade and self.selectedSkill then
		local skill = self:GetSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
		if not skill then return 0 end
		--DA.DEBUG(1,"QueueItems: skill= "..DA.DUMP1(skill))
		local recipe = self:GetRecipe(skill.id)
		--DA.DEBUG(1,"QueueItems: recipe= "..DA.DUMP1(recipe))
		if not count then
			if recipe.recipeType ~= Enum.TradeskillRecipeType.Salvage then
				count = (skill.numCraftable or 0) / (recipe.numMade or 1)
				if count == 0 then
					count = (skill.numCraftableVendor or 0) / (recipe.numMade or 1)
				end
				if count == 0 then
					count = (skill.numCraftableAlts or 0) / (recipe.numMade or 1)
				end
			else
				count = 0
				local salvageItem = self.salvageSelected[1]
				local targetItems = C_TradeSkillUI.GetCraftingTargetItems(recipe.salvage)
				--DA.DEBUG(2,"QueueItems: targetItems= "..DA.DUMP1(targetItems))
				for i,targetItem in pairs(targetItems) do
					if targetItem.itemID == salvageItem then
						count = targetItem.quantity / (recipe.numUsed or 1)
					end
				end
			end
		end
		count = math.min(count, 9999)
		self.visited = {}
		if count > 0 then
			if recipe then
				local first = false
				if button == "RightButton" then
					first = true
				end
				local queueCommand = self:QueueCommandIterate(recipe.spellID, count)
				if self.db.profile.queue_one_at_a_time and queueCommand.modified then
					queueCommand.count = 1
					for i=1, count, 1 do
						local c = tcopy(queueCommand)
						self:QueueAppendCommand(c, Skillet.db.profile.queue_craftable_reagents, first)
					end
				else
					self:QueueAppendCommand(queueCommand, Skillet.db.profile.queue_craftable_reagents, first)
				end
				self.requiredSelected = {}
				self.optionalSelected = {}
				self.finishingSelected = {}
				self:HideOptionalList()
				self.modifiedSelected = {}
				self:HideModifiedList()
				self:UpdateDetailWindow(self.selectedSkill)
			end
		end
		return count
	end
	return 0
end

--
-- Queue the max number of craftable items for the currently selected skill
--
function Skillet:QueueAllItems(button)
	DA.DEBUG(0,"QueueAllItems("..tostring(button)..")");
	local count = self:QueueItems(button)
	return count
end

--
-- Adds the currently selected number of items to the queue and then starts the queue
--
function Skillet:CreateItems(button, count)
	DA.DEBUG(0,"CreateItems("..tostring(button)..", "..tostring(count)..")")
	if self:QueueItems(button, count) > 0 then
		self:ProcessQueue(button == "RightButton" or IsAltKeyDown())
	end
end

--
-- Queue and create the max number of craftable items for the currently selected skill
--
function Skillet:CreateAllItems(button)
	DA.DEBUG(0,"CreateAllItems("..tostring(button)..")")
	if self:QueueAllItems(button) > 0 then
		self:ProcessQueue(button == "RightButton" or IsAltKeyDown())
	end
end

--
-- Events associated with crafting spells
--
function Skillet:UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_SENT("..tostring(unit)..", "..tostring(target)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unit == "player" then
		self:IgnoreCast(spellID)
	end
end

function Skillet:UNIT_SPELLCAST_START(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_START("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		self:IgnoreCast(spellID)
	end
end

function Skillet:UNIT_SPELLCAST_SUCCEEDED(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_SUCCEEDED("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		if self.processingLevel and self.processingLevel ~= 0 and self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_SUCCEEDED: "..tostring(unitTarget)..", "..tostring(spellID)..", "..tostring(self.processingSpellID))
			self:ContinueCast(self.processingSpellID)
		elseif spellID == self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_SUCCEEDED: "..tostring(unitTarget)..", "..tostring(spellID))
			self:ContinueCast(spellID)
		else
			self:IgnoreCast(spellID)
		end
	end
end

function Skillet:UNIT_SPELLCAST_FAILED(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_FAILED("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		if self.processingLevel and self.processingLevel ~= 0 and self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_FAILED: "..tostring(castGUID)..", "..tostring(spellID)..", "..tostring(self.processingSpellID))
			self:StopCast(self.processingSpellID)
		elseif spellID == self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_FAILED: "..tostring(unitTarget)..", "..tostring(spellID))
			self:StopCast(spellID)
		else
			self:IgnoreCast(spellID)
		end
	end
end

function Skillet:UNIT_SPELLCAST_FAILED_QUIET(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_FAILED_QUIET("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		if self.processingLevel and self.processingLevel ~= 0 and self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_FAILED_QUIET: "..tostring(unitTarget)..", "..tostring(spellID)..", "..tostring(self.processingSpellID))
			self:StopCast(self.processingSpellID)
		elseif spellID == self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_FAILED_QUIET: "..tostring(unitTarget)..", "..tostring(spellID))
			self:StopCast(spellID)
		else
			self:IgnoreCast(spellID)
		end
	end
end

function Skillet:UNIT_SPELLCAST_INTERRUPTED(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_INTERRUPTED("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		if self.processingLevel and self.processingLevel ~= 0 and self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_INTERRUPTED: "..tostring(unitTarget)..", "..tostring(spellID)..", "..tostring(self.processingSpellID))
			self:StopCast(self.processingSpellID)
		elseif spellID == self.processingSpellID then
			DA.DEBUG(0,"UNIT_SPELLCAST_INTERRUPTED: "..tostring(unitTarget)..", "..tostring(spellID))
			self:StopCast(spellID)
		else
			self:IgnoreCast(spellID)
		end
	end
end

function Skillet:UNIT_SPELLCAST_DELAYED(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_DELAYED("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		self:IgnoreCast(spellID)
	end
end

function Skillet:UNIT_SPELLCAST_STOP(event, unitTarget, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_STOP("..tostring(unitTarget)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	if unitTarget == "player" then
		self:IgnoreCast(spellID)
	end
end

function Skillet:UPDATE_TRADESKILL_CAST_COMPLETE(event, isScrapping)
	DA.TRACE("UPDATE_TRADESKILL_CAST_COMPLETE("..tostring(isScrapping)..")")
end

function Skillet:UPDATE_TRADESKILL_RECAST(event)
	DA.TRACE("UPDATE_TRADESKILL_RECAST")
end

function Skillet:ITEM_COUNT_CHANGED(event,itemID)
	DA.TRACE3("ITEM_COUNT_CHANGED("..tostring(itemID)..")")
--[[
	if itemID == self.salvageItem then
		DA.DEBUG(0,"ITEM_COUNT_CHANGED: itemID= "..tostring(itemID))
		self:ContinueCast(self.processingSpellID)
	else
		self:IgnoreCast(self.processingSpellID)
	end
--]]
end

function Skillet:TRADE_SKILL_ITEM_CRAFTED_RESULT(event, CraftingItemResultData)
	DA.TRACE("TRADE_SKILL_ITEM_CRAFTED_RESULT("..DA.DUMP(CraftingItemResultData)..")")
end

--
-- Continue a trade skill currently in progress. Called from UNIT_SPELLCAST_SUCCEEDED when that event applies to us
-- Counts down each successful completion of the current command and does finish processing when the count reaches zero
--
function Skillet:ContinueCast(spellID)
	if self.enabledState then
		name = C_Spell.GetSpellName(spellID)
		DA.DEBUG(0,"ContinueCast("..tostring(spellID).."), "..tostring(name))
		if spellID == self.processingSpellID then
			DA.DEBUG(1,"ContinueCast: processingCount= "..tostring(Skillet.processingCount))
			local queue = self.db.realm.queueData[self.currentPlayer]
			local qpos = self.processingPosition
			if queue[qpos] and queue[qpos] == self.processingCommand then
				local command = queue[qpos]
				if command.op == "iterate" then
					command.count = command.count - 1
					if command.count == 0 then
						local qsize = self:RemoveFromQueue(qpos)
--
-- Sound IDs can be found at https://www.wowhead.com/sounds 
--
						if self.db.profile.sound_on_empty_queue and qsize == 0 then
							PlaySoundFile(558132, "Master") -- PeonBuildingComplete
							if self.db.profile.flash_on_empty_queue then FlashClientIcon() end
						end
						if self.db.profile.sound_on_remove_queue and qsize ~= 0 then
							PlaySoundFile(558147, "Master") -- PeonYes3"
--							PlaySoundFile(567473, "Master") -- UnsheathMetal
							if self.db.profile.flash_on_remove_queue then FlashClientIcon() end
						end
					elseif command.modifiedReagents then
						DA.DEBUG(2,"ContinueCast: command= "..DA.DUMP(command))
					end
				end
			else
				DA.DEBUG(1,"ContinueCast: queued command and processingCommand don't match")
			end
			Skillet.processingCount = Skillet.processingCount - 1
			if Skillet.processingCount == 0 then
				self.queuecasting = false
				self.processingSpell = nil
				self.processingSpellID = nil
				self.processingPosition = nil
				self.processingCommand = nil
				self.processingLevel = nil
				self.salvageItem = nil
--
-- Restore the TraceLog setting.
--
				DA.TraceLog = self.oldTraceLog
			end
		end
	end
end

--
-- Stop a trade skill currently in progress. Called from UNIT_SPELLCAST_* events that indicate failure
--
function Skillet:StopCast(spellID)
	if self.enabledState then
		name = C_Spell.GetSpellName(spellID)
		--DA.DEBUG(0,"StopCast("..tostring(spellID).."), "..tostring(name))
		DA.MARK3(L["Crafting error"]..", spell= "..tostring(spellID)..", "..tostring(name))
		self.queuecasting = false
		self.processingSpell = nil
		self.processingSpellID = nil
		self.processingPosition = nil
		self.processingCommand = nil
		self.processingLevel = nil
		self.processingCount = nil
		self.salvageItem = nil
	end
end

--
-- Ignore a trade skill event directed at the player. Called from UNIT_SPELLCAST_* events that 
-- don't meet expected criteria
--
function Skillet:IgnoreCast(spellID)
	if self.enabledState then
		name = C_Spell.GetSpellName(spellID)
		DA.DEBUG(4,"IgnoreCast("..tostring(spellID).."), "..tostring(name))
	end
end

--
-- Cancel a trade skill currently in progress. We cannot cancel the current
-- item as that requires a "SpellStopCasting" call which can only be
-- made from secure code. All this does is stop repeating after the current item
--
function Skillet:CancelCast()
	if self.enabledState then
		DA.DEBUG(0,"CancelCast()")
--		C_TradeSkillUI.StopRecipeRepeat()
	end
end

--
-- Removes an item from the queue
--
function Skillet:RemoveQueuedCommand(queueIndex)
	DA.DEBUG(0,"RemoveQueuedCommand("..tostring(queueIndex)..")")
	self:RemoveFromQueue(queueIndex)
	self:UpdateTradeSkillWindow()
end

--
-- Rebuilds reagentsInQueue list
--
function Skillet:ScanQueuedReagents()
	DA.DEBUG(0,"ScanQueuedReagents()")
	if self.linkedSkill or self.isGuild then
		return
	end
	local reagentsInQueue = {}
	local modifiedInQueue = {}
	for i,command in pairs(self.db.realm.queueData[self.currentPlayer]) do
		if command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			if not command.count then
				command.count = 1
			end
			if recipe.numMade > 0 then
				reagentsInQueue[recipe.itemID] = command.count * recipe.numMade + (reagentsInQueue[recipe.itemID] or 0)
			end
			for i=1,#recipe.reagentData do
				local reagent = recipe.reagentData[i]
				if command.recipeLevel and command.recipeLevel > 0 then
					--DA.DEBUG(2,"ScanQueuedReagents: recipeID= "..tostring(command.recipeID)..", recipeLevel= "..tostring(command.recipeLevel))
					local reagentName, reagentTexture, reagentCount, playerReagentCount = C_TradeSkillUI.GetRecipeReagentInfo(command.recipeID, i, command.recipeLevel)
					--DA.DEBUG(2,"ScanQueuedReagents: reagentName= "..tostring(reagentName)..", reagentCount= "..tostring(reagentCount))
					local reagentLink = C_TradeSkillUI.GetRecipeReagentItemLink(command.recipeID, i)
					local reagentID = Skillet:GetItemIDFromLink(reagentLink)
					if reagent.reagentID == reagentID then
						reagent.numNeeded = reagentCount
					else
						DA.DEBUG(0,"ScanQueuedReagents: Reagent Mismatch, i= "..tostring(i)..", reagentID= "..tostring(reagent.reagentID)..", mismatch= "..tostring(reagentID))
					end
				end
				reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
			end
			if recipe.modifiedData then
				for i=1,#recipe.modifiedData do
					local reagent = recipe.modifiedData[i]
					--DA.DEBUG(2,"QueueAppendCommand: reagent= "..DA.DUMP(reagent))
					reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
					modifiedInQueue[reagent.reagentID] = reagent.schematic.reagents
				end
			end
--[[
			if command.requiredReagents then
				for i,reagent in pairs(command.requiredReagents) do
					DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
					reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
				end
			end
			if command.optionalReagents then
				for i,reagent in pairs(command.optionalReagents) do
					DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
					reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
				end
			end
			if command.finishingReagents then
				for i,reagent in pairs(command.finishingReagents) do
					DA.DEBUG(2,"QueueAppendCommand: i= "..tostring(i)..", reagent= "..DA.DUMP(reagent))
					reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
				end
			end
--]]
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) + command.count * recipe.numMade;
		end
	end
	self.db.realm.reagentsInQueue[self.currentPlayer] = reagentsInQueue
	self.db.realm.modifiedInQueue[self.currentPlayer] = modifiedInQueue
end

function Skillet:QueueMoveToTop(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index > 1 and index <= #queue then
		table.insert(queue, 1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveUp(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index > 1 and index <= #queue then
		table.insert(queue, index-1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveDown(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index > 0 and index <# queue then
		table.insert(queue, index+2, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveToBottom(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index > 0 and index < #queue then
		table.insert(queue, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:SaveQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	local reagents = self.db.realm.reagentsInQueue[self.currentPlayer]
	local reagents = self.db.realm.modifiedInQueue[self.currentPlayer]
	if not name or name == "" then return end
	if not queue or #queue == 0 then
		Skillet:MessageBox(L["Queue is empty"])
		return
	end
	if self.db.profile.SavedQueues[name] and not overwrite then
		Skillet:AskFor(L["Queue with this name already exsists. Overwrite?"],
			function() Skillet:SaveQueue(name, true)  end
			)
		return
	end
	self.db.profile.SavedQueues[name] = {}
	self.db.profile.SavedQueues[name].queue = tcopy(queue)
	self.db.profile.SavedQueues[name].reagents = tcopy(reagents)
	self.db.profile.SavedQueues[name].modified = tcopy(modified)
	Skillet.selectedQueueName = name
	Skillet:QueueLoadDropdown_OnShow()
	SkilletQueueSaveEditBox:SetText("")
end

function Skillet:LoadQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not name or name == "" then return end
	if not self.db.profile.SavedQueues[name] then
		Skillet:MessageBox(L["No such queue saved"])
		return
	end
	if queue and #queue > 0 and not overwrite then
		Skillet:AskFor(L["Queue is not empty. Overwrite?"],
			function() Skillet:LoadQueue(name, true)  end
			)
		return
	end
	self.db.realm.queueData[self.currentPlayer] = tcopy(self.db.profile.SavedQueues[name].queue)
	self.db.realm.reagentsInQueue[self.currentPlayer] = tcopy(self.db.profile.SavedQueues[name].reagents)
	self.db.realm.modifiedInQueue[self.currentPlayer] = tcopy(self.db.profile.SavedQueues[name].modified)
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:DeleteQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not name or name == "" then return end
	if not self.db.profile.SavedQueues[name] then
		Skillet:MessageBox(L["No such queue saved"])
		return
	end
	if not overwrite then
		Skillet:AskFor(L["Really delete this queue?"],
			function() Skillet:DeleteQueue(name, true)  end
			)
		return
	end
	self.db.profile.SavedQueues[name] = nil
	Skillet.selectedQueueName = ""
	Skillet:QueueLoadDropdown_OnShow()
	Skillet:UpdateTradeSkillWindow()
end
