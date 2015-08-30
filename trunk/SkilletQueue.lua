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

Skillet.reagentsChanged = {}

-- iterates through a list of reagentIDs and recalculates craftability
function Skillet:AdjustInventory()
	DA.DEBUG(0,"AdjustInventory")
	-- update queue for faster response time
	self:UpdateQueueWindow()
	if self.reagentsChanged then
		for id,v in pairs(self.reagentsChanged) do
			self:InventoryReagentCraftability(id)
		end
	end
	self:CalculateCraftableCounts()
	self.dataScanned = false
	self.reagentsChanged = {}
	-- update whole window to show craft counts
	self:UpdateTradeSkillWindow()
end

-- this is the simplest command:  iterate recipeID x count
-- this is the only currently implemented queue command
function Skillet:QueueCommandIterate(recipeID, count)
	DA.DEBUG(0,"QueueCommandIterate("..tostring(recipeID)..", "..tostring(count)..")")
	local newCommand = {}
	newCommand.op = "iterate"
	newCommand.recipeID = recipeID
	newCommand.count = count
	return newCommand
end

-- command to craft "recipeID" until inventory has "count" "itemID"
-- not currently implemented
function Skillet:QueueCommandInventory(recipeID, itemID, count)
	DA.DEBUG(0,"QueueCommandInventory")
	local newCommand = {}
	newCommand.op = "inventory"
	newCommand.recipeID = recipeID
	newCommand.itemID = itemID
	newCommand.count = count
	return newCommand
end

-- command to craft "recipeID" until a certain crafting level has been reached
-- not currently implemented
function Skillet:QueueCommandSkillLevel(recipeID, level)
	DA.DEBUG(0,"QueueCommandSkillLevel")
	local newCommand = {}
	newCommand.op = "skillLevel"
	newCommand.recipeID = recipeID
	newCommand.count = level
	return newCommand
end

-- queue up the command and reserve reagents
function Skillet:QueueAppendCommand(command, queueCraftables, noWindowRefresh)
	DA.DEBUG(0,"QueueAppendCommand("..DA.DUMP1(command)..", "..tostring(queueCraftables)..", "..tostring(noWindowRefresh)..")")
	local recipe = Skillet:GetRecipe(command.recipeID)
	DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe)..", visited= "..tostring(self.visited[command.recipeID]))
	if recipe and not self.visited[command.recipeID] then
		self.visited[command.recipeID] = true
		local count = command.count
		local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
		local reagentsChanged = self.reagentsChanged
		local skillIndexLookup = self.data.skillIndexLookup[Skillet.currentPlayer]
		for i=1,#recipe.reagentData,1 do
			local reagent = recipe.reagentData[i]
			DA.DEBUG(1,"reagent= "..DA.DUMP1(reagent))
			local need = count * reagent.numNeeded
			local numInBoth = GetItemCount(reagent.id,true)
			local numInBags = GetItemCount(reagent.id)
			local numInBank =  numInBoth - numInBags
			DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
			local have = numInBoth + (reagentsInQueue[reagent.id] or 0);
			reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) - need;
			reagentsChanged[reagent.id] = true
			DA.DEBUG(1,"queueCraftables= "..tostring(queueCraftables)..", need= "..tostring(need)..", have= "..tostring(have))
			if queueCraftables and need > have and (Skillet.db.profile.queue_glyph_reagents or not recipe.name:match(Skillet.L["Glyph "])) then
				local recipeSource = self.db.global.itemRecipeSource[reagent.id]
				DA.DEBUG(1,"recipeSource= "..DA.DUMP1(recipeSource))
				if recipeSource then
					for recipeSourceID in pairs(recipeSource) do
						local skillIndex = skillIndexLookup[recipeSourceID]
						DA.DEBUG(1,"skillIndex= "..tostring(skillIndex))
						if skillIndex then
							command.complex = true						-- identify that this queue has craftable reagent requirements
							local recipeSource = Skillet:GetRecipe(recipeSourceID)
							local newCount = math.ceil((need - have)/recipeSource.numMade)
							local newCommand = self:QueueCommandIterate(recipeSourceID, newCount)
							newCommand.level = (command.level or 0) + 1
							-- do not add items from transmutation - this can create weird loops
							if not Skillet.TradeSkillIgnoredMats[recipeSourceID] and 
							  not Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeSourceID] then
								self:QueueAppendCommand(newCommand, queueCraftables, true)
							end
						end
					end
				end
			end
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) + command.count * recipe.numMade;
		reagentsChanged[recipe.itemID] = true
		Skillet:AddToQueue(command, noWindowRefresh)
		self.visited[command.recipeID] = nil
	end
end

-- command.complex means the queue entry requires additional crafting to take place prior to entering the queue.
-- we can't just increase the # of the first command if it happens to be the same recipe without making sure
-- the additional queue entry doesn't require some additional craftable reagents
function Skillet:AddToQueue(command, noWindowRefresh)
	DA.DEBUG(0,"AddToQueue("..DA.DUMP1(command)..", "..tostring(noWindowRefresh)..")")
	local queue = self.db.realm.queueData[self.currentPlayer]
	-- if self.linkedSkill then return end
	if (not command.complex) then		-- we can add this queue entry to any of the other entries
		local added
		for i=1,#queue,1 do
			if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID then
				queue[i].count = queue[i].count + command.count
				added = true
				break
			end
		end
		if not added then
			table.insert(queue, command)
		end
	elseif queue and #queue>0 then
		local i=#queue
		--check last item in queue - add current if they are the same
		if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID then
			queue[i].count = queue[i].count + command.count
		else
			table.insert(queue, command)
		end
	else
		table.insert(queue, command)
	end
	if not noWindowRefresh then
		self:AdjustInventory()
	end
	self:SendMessage("Skillet_Queue_Add")
end

function Skillet:RemoveFromQueue(index)
	--DA.DEBUG(0,"RemoveFromQueue")
	local queue = self.db.realm.queueData[self.currentPlayer]
	local command = queue[index]
	local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
	local reagentsChanged = self.reagentsChanged
	if command.op == "iterate" then
		local recipe = self:GetRecipe(command.recipeID)
		if not command.count then
			command.count = 1
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) - recipe.numMade * command.count
		reagentsChanged[recipe.itemID] = true
		for i=1,#recipe.reagentData,1 do
			local reagent = recipe.reagentData[i]
			reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) + reagent.numNeeded * command.count
			reagentsChanged[reagent.id] = true
		end
	end
	table.remove(queue, index)
	self:AdjustInventory()
end

function Skillet:ClearQueue()
	--DA.DEBUG(0,"ClearQueue")
	if #self.db.realm.queueData[self.currentPlayer]>0 then
		self.db.realm.queueData[self.currentPlayer] = {}
		self.db.realm.reagentsInQueue[self.currentPlayer] = {}
		self.dataScanned = false
		self:UpdateTradeSkillWindow()
	end
	--DA.DEBUG(0,"ClearQueue Complete")
	self:SendMessage("Skillet_Queue_Complete")
end

function Skillet:ProcessQueue(altMode)
	DA.DEBUG(0,"ProcessQueue");
	local queue = self.db.realm.queueData[self.currentPlayer]
	local qpos = 1
	local skillIndexLookup = self.data.skillIndexLookup[self.currentPlayer]
	self.processingPosition = nil
	self.processingCommand = nil
	if self.currentPlayer ~= (UnitName("player")) then
		DA.DEBUG(0,"trying to process from an alt!")
		return
	end
	local command
	repeat
		command = queue[qpos]
		DA.DEBUG(1,DA.DUMP1(command))
		if command and command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			local craftable = true
			local cooldown = GetTradeSkillCooldown(skillIndexLookup[command.recipeID])
			if cooldown then
				Skillet:Print(L["Skipping"],recipe.name,"-",L["has cooldown of"],SecondsToTime(cooldown))
				craftable = false
			else
				for i=1,#recipe.reagentData,1 do
					local reagent = recipe.reagentData[i]
					local reagentName = GetItemInfo(reagent.id) or reagent.id
					DA.DEBUG(1,"id= "..tostring(reagent.id)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(reagent.numNeeded))
					local numInBoth = GetItemCount(reagent.id,true)
					local numInBags = GetItemCount(reagent.id)
					local numInBank =  numInBoth - numInBags
					DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
					if numInBoth < reagent.numNeeded then
						Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],reagent.numNeeded,"x",reagentName,"("..L["have"],numInBoth..")")
						craftable = false
						break
					end
				end -- for
			end
			if craftable then break end
		end
		qpos = qpos + 1
	until qpos>#queue
	-- if we can't craft anything, show error from first item in queue
	if qpos > #queue then
		qpos = 1
		command = queue[qpos]
	end
	if command then
		if command.op == "iterate" then
			self.queuecasting = true
			local recipe = self:GetRecipe(command.recipeID)
			if self.currentTrade ~= recipe.tradeID and self:GetTradeName(recipe.tradeID) then
				CastSpellByName(self:GetTradeName(recipe.tradeID))					-- switch professions
			end
			self.processingSpell = self:GetRecipeName(command.recipeID)
			self.processingPosition = qpos
			self.processingCommand = command
			-- if alt down/right click - auto use items / like vellums
			if altMode then
				local itemID = Skillet:GetAutoTargetItem(recipe.tradeID)
				if itemID then
					DoTradeSkill(skillIndexLookup[command.recipeID],1)
					UseItemByName(itemID)
					self.queuecasting = false
				else
					DoTradeSkill(skillIndexLookup[command.recipeID],command.count)
				end
			else
				DoTradeSkill(skillIndexLookup[command.recipeID],command.count)
			end
			return
		else
			DA.DEBUG(0,"unsupported queue op: "..(command.op or "nil"))
		end
	else
		self.db.realm.queueData[self.currentPlayer] = {}
		self:SendMessage("Skillet_Queue_Complete")
	end
end

-- Adds the currently selected number of items to the queue
function Skillet:QueueItems(count)
	DA.DEBUG(0,"QueueItems");
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
	if not skill then return 0 end
	local recipe = self:GetRecipe(skill.id)
	local recipeID = skill.id
	if not count then
		count = skill.numCraftable / (recipe.numMade or 1)
		if count == 0 then
			count = (skill.numCraftableVendor or 0)/ (recipe.numMade or 1)
		end
		if count == 0 then
			count = (skill.numCraftableAlts or 0) / (recipe.numMade or 1)
		end
	end
	count = math.min(count, 9999)
	self.visited = {}
	if count > 0 then
		if self.currentTrade and self.selectedSkill then
			if recipe then
				local queueCommand = self:QueueCommandIterate(recipeID, count)
				self:QueueAppendCommand(queueCommand, Skillet.db.profile.queue_craftable_reagents)
			end
		end
	end
	return count
end

-- Queue the max number of craftable items for the currently selected skill
function Skillet:QueueAllItems()
	DA.DEBUG(0,"QueueAllItems");
	local count = self:QueueItems()						-- no argument means queue em all
	self:UpdateNumItemsSlider(0, false)
	return count
end

-- Adds the currently selected number of items to the queue and then starts the queue
function Skillet:CreateItems(count, mouse)
	DA.DEBUG(0,"CreateItems");
	if self:QueueItems(count) > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

-- Queue and create the max number of craftable items for the currently selected skill
function Skillet:CreateAllItems(mouse)
	DA.DEBUG(0,"CreateAllItems");
	if self:QueueAllItems() > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

function Skillet:ContinueCast(spell)
	Skillet:StopCast(spell, true)
end

function Skillet:StopCast(spell, success)
	local spellBeingCast = UnitCastingInfo("player")
	if not self.db.realm.queueData then
		self.db.realm.queueData = {}
	end
	local queue = self.db.realm.queueData[self.currentPlayer]
	if spell == self.processingSpell then
		if success then
			local qpos = self.processingPosition or 1
			local command = nil
			if not queue[qpos] or queue[qpos] ~= self.processingCommand then
				for i=1,#queue,1 do
					if queue[i] == self.processingCommand then
						command = queue[i]
						qpos = i
						break
					end
				end
			else
				command = queue[qpos]
			end
			-- empty queue or command not found (removed?)
			if not queue[1] or not command then
--				self:SendMessage("Skillet_Queue_Complete")
				self.queuecasting = false
				self.processingSpell = nil
				self.processingPosition = nil
				self.processingCommand = nil
				self:UpdateTradeSkillWindow()
				return
			end
			if command.op == "iterate" then
				command.count = command.count - 1
				if command.count < 1 then
					self.queuecasting = false
					self.processingSpell = nil
					self.processingPosition = nil
					self.processingCommand = nil
					self.reagentsChanged = {}
					self:RemoveFromQueue(qpos)		-- implied queued reagent inventory adjustment in remove routine
					self:RescanTrade()
--					DA.CHAT("removed queue command")
				end
			end
		else
			self.processingSpell = nil
			self.processingPosition = nil
			self.processingCommand = nil
			self.queuecasting = false
		end
--		DA.CHAT("STOP CAST IS UPDATING WINDOW")
		self:InventoryScan()
		self:UpdateTradeSkillWindow()
	end
end

-- Stop a trade skill currently in prograess. We cannot cancel the current
-- item as that requires a "SpellStopCasting" call which can only be
-- made from secure code. All this does is stop repeating after the current item
function Skillet:CancelCast()
	StopTradeSkillRepeat()
end

-- Removes an item from the queue
function Skillet:RemoveQueuedCommand(queueIndex)
	if queueIndex == 1 then
		self:CancelCast()
	end
	self.reagentsChanged = {}
	self:RemoveFromQueue(queueIndex)
	self:UpdateQueueWindow()
	self:UpdateTradeSkillWindow()
end

-- Rebuilds reagentsInQueue list
function Skillet:ScanQueuedReagents()
DA.DEBUG(0,"ScanQueuedReagents")
	if self.linkedSkill or self.isGuild then
		return
	end
	local reagentsInQueue = {}
	for i,command in pairs(self.db.realm.queueData[self.currentPlayer]) do
		if command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			if not command.count then
				command.count = 1
			end
			if recipe.numMade > 0 then
				reagentsInQueue[recipe.itemID] = command.count * recipe.numMade + (reagentsInQueue[recipe.itemID] or 0)
			end
			for i=1,#recipe.reagentData,1 do
				local reagent = recipe.reagentData[i]
				reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) - reagent.numNeeded * command.count
			end
		end
	end
	self.db.realm.reagentsInQueue[self.currentPlayer] = reagentsInQueue
end

function Skillet:QueueMoveToTop(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>1 and index<=#queue then
		table.insert(queue, 1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveUp(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>1 and index<=#queue then
		table.insert(queue, index-1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveDown(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>0 and index<#queue then
		table.insert(queue, index+2, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveToBottom(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>0 and index<#queue then
		table.insert(queue, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

local function tcopy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

function Skillet:SaveQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	local reagents = self.db.realm.reagentsInQueue[self.currentPlayer]
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
