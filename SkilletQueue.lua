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

-- iterates through a list of reagentIDs and recalculates craftability
function Skillet:AdjustInventory()
	DA.DEBUG(0,"AdjustInventory()")
	-- update queue for faster response time
	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	self:CalculateCraftableCounts()
	-- update whole window to show craft counts
	self:UpdateTradeSkillWindow()
end

-- this is the simplest command:  iterate recipeID x count
function Skillet:QueueCommandIterate(recipeID, count)
	DA.DEBUG(0,"QueueCommandIterate("..tostring(recipeID)..", "..tostring(count)..")")
	local recipe = self:GetRecipe(recipeID)
	--DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe))
	local tradeID = recipe.tradeID
	local tradeName = self.tradeSkillNamesByID[tradeID]
	local newCommand = {}
	newCommand.op = "iterate"
	newCommand.recipeID = recipeID
	newCommand.count = count
	newCommand.tradeID = tradeID
	newCommand.tradeName = tradeName
	return newCommand
end

-- queue up the command and reserve reagents
function Skillet:QueueAppendCommand(command, queueCraftables, noWindowRefresh)
	DA.DEBUG(0,"QueueAppendCommand("..DA.DUMP1(command)..", "..tostring(queueCraftables)..", "..tostring(noWindowRefresh)..")")
	local recipe = Skillet:GetRecipe(command.recipeID)
	--DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe)..", visited= "..tostring(self.visited[command.recipeID]))
	if recipe and not self.visited[command.recipeID] then
		self.visited[command.recipeID] = true
		local count = command.count
		local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
		local skillIndexLookup = self.data.skillIndexLookup
		for i=1,#recipe.reagentData,1 do
			local reagent = recipe.reagentData[i]
			--DA.DEBUG(1,"reagent= "..DA.DUMP1(reagent))
			local need = count * reagent.numNeeded
			local numInBoth = GetItemCount(reagent.reagentID,true)
			local numInBags = GetItemCount(reagent.reagentID)
			local numInBank =  numInBoth - numInBags
			--DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
			local have = numInBoth + (reagentsInQueue[reagent.reagentID] or 0);
			reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - need;
			--DA.DEBUG(1,"queueCraftables= "..tostring(queueCraftables)..", need= "..tostring(need)..", have= "..tostring(have))
			if queueCraftables and need > have and (Skillet.db.profile.queue_glyph_reagents or not recipe.name:match(Skillet.L["Glyph "])) then
				local recipeSource = self.db.global.itemRecipeSource[reagent.reagentID]
				--DA.DEBUG(1,"recipeSource= "..DA.DUMP1(recipeSource))
				if recipeSource then
					for recipeSourceID in pairs(recipeSource) do
						local skillIndex = skillIndexLookup[recipeSourceID]
						--DA.DEBUG(1,"skillIndex= "..tostring(skillIndex))
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
end

function Skillet:ClearQueue()
	--DA.DEBUG(0,"ClearQueue()")
	if #self.db.realm.queueData[self.currentPlayer] > 0 then
		self.db.realm.queueData[self.currentPlayer] = {}
		self.db.realm.reagentsInQueue[self.currentPlayer] = {}
		self:UpdateTradeSkillWindow()
	end
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
	repeat
		command = queue[qpos]
		--DA.DEBUG(1,DA.DUMP1(command))
		if command and command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			craftable = true
			local cooldown = C_TradeSkillUI.GetRecipeCooldown(command.recipeID)
			if cooldown then
				Skillet:Print(L["Skipping"],recipe.name,"-",L["has cooldown of"],SecondsToTime(cooldown))
				craftable = false
			else
				for i=1,#recipe.reagentData,1 do
					local reagent = recipe.reagentData[i]
					local reagentName = GetItemInfo(reagent.reagentID) or reagent.reagentID
					--DA.DEBUG(1,"id= "..tostring(reagent.reagentID)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(reagent.numNeeded))
					local numInBoth = GetItemCount(reagent.reagentID,true)
					local numInBags = GetItemCount(reagent.reagentID)
					local numInBank =  numInBoth - numInBags
					--DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
					if numInBoth < reagent.numNeeded then
						Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],reagent.numNeeded*command.count,"x",reagentName,"("..L["have"],numInBoth..")")
						craftable = false
						break
					end
				end -- for
			end
			if craftable then break end
		end
		qpos = qpos + 1
	until qpos > #queue
	-- if we can't craft anything, show error from first item in queue
	if qpos > #queue then
		qpos = 1
		command = queue[qpos]
	end
	if command and craftable then
		if command.op == "iterate" then
			if self.currentTrade ~= command.tradeID then
				DA.CHAT("Changing profession to "..tostring(command.tradeName)..". Press Process again") -- should be Skillet:Print and localized
				local tradeName = command.tradeName
				if tradeName == "Mining" then tradeName = "Mining Skills" end
				CastSpellByName(tradeName)		-- switch professions
				self.queuecasting = false
				return
			end
			local recipeInfo = C_TradeSkillUI.GetRecipeInfo(command.recipeID)
			--DA.DEBUG(1,"recipeInfo= "..DA.DUMP1(recipeInfo))
			local numAvailable = recipeInfo.numAvailable or 0
			if numAvailable > 0 then
				self.processingSpell = self:GetRecipeName(command.recipeID)
				self.processingSpellID = command.recipeID
				self.processingPosition = qpos
				self.processingCommand = command
				self.adjustInventory = true
				-- if alt down/right click - auto use items / like vellums
				if altMode then
					local itemID = Skillet:GetAutoTargetItem(command.tradeID)
					if itemID then
						self.processingCount = 1
						DA.DEBUG(1,"altMode Crafting: "..tostring(self.processingSpell).." ("..tostring(command.recipeID)..") and using "..tostring(itemID))
						self.queuecasting = true
						self.processingCount = 1
						C_TradeSkillUI.SetRecipeRepeatCount(command.recipeID, 1)
						C_TradeSkillUI.CraftRecipe(command.recipeID, 1)
						UseItemByName(itemID)
						self.queuecasting = false
						return
					end
				end
				local craftCount = command.count
				if craftCount > numAvailable then
					craftCount = numAvailable
				end
				DA.DEBUG(1,"Crafting: "..tostring(command.count).." of "..tostring(self.processingSpell).." ("..tostring(command.recipeID)..")")
				self.queuecasting = true
				self.processingCount = craftCount
				C_TradeSkillUI.SetRecipeRepeatCount(command.recipeID, craftCount)
				C_TradeSkillUI.CraftRecipe(command.recipeID, craftCount)
			else
				DA.CHAT("Insufficent Materials available, count= "..tostring(command.count)..", numAvailable= "..tostring(numAvailable))
				self.queuecasting = false
			end
		else
			DA.DEBUG(0,"unsupported queue op: "..tostring(command.op))
		end
	end
end

-- Adds the currently selected number of items to the queue
function Skillet:QueueItems(count)
	DA.DEBUG(0,"QueueItems("..tostring(count)..")");
	if self.currentTrade and self.selectedSkill and self.selectedSkill then
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
			if recipe then
				local queueCommand = self:QueueCommandIterate(recipeID, count)
				self:QueueAppendCommand(queueCommand, Skillet.db.profile.queue_craftable_reagents)
			end
		end
		return count
	end
	return 0
end

-- Queue the max number of craftable items for the currently selected skill
function Skillet:QueueAllItems()
	DA.DEBUG(0,"QueueAllItems()");
	local count = self:QueueItems()
--	self:UpdateNumItemsSlider(0, false)
	return count
end

-- Adds the currently selected number of items to the queue and then starts the queue
function Skillet:CreateItems(count, mouse)
	DA.DEBUG(0,"CreateItems("..tostring(count)..", "..tostring(mouse)..")")
	if self:QueueItems(count) > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

-- Queue and create the max number of craftable items for the currently selected skill
function Skillet:CreateAllItems(mouse)
	DA.DEBUG(0,"CreateAllItems("..tostring(mouse)..")")
	if self:QueueAllItems() > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

function Skillet:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineID)
	--DA.DEBUG(0,"UNIT_SPELLCAST_SENT("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(target)..", "..tostring(lineID)..")")
end

function Skillet:UNIT_SPELLCAST_START(event, unit, spell, rank, lineID, spellID)
	--DA.DEBUG(0,"UNIT_SPELLCAST_START("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
end

function Skillet:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank, lineID, spellID)
	if unit == "player" and spell == self.processingSpell then
		--DA.DEBUG(0,"UNIT_SPELLCAST_SUCCEEDED("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
		self:ContinueCast(spell,spellID)
	end
end

function Skillet:UNIT_SPELLCAST_FAILED(event, unit, spell, rank, lineID, spellID)
	if unit == "player" and spell == self.processingSpell then
		--DA.DEBUG(0,"UNIT_SPELLCAST_FAILED("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
		self:StopCast(spell,SpellID)
	end
end

function Skillet:UNIT_SPELLCAST_FAILED_QUIET(event, unit, spell, rank, lineID, spellID)
	if unit == "player" and spell == self.processingSpell then
		--DA.DEBUG(0,"UNIT_SPELLCAST_FAILED_QUIET("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
		self:StopCast(spell,spellID)
	end
end

function Skillet:UNIT_SPELLCAST_INTERRUPTED(event, unit, spell, rank, lineID, spellID)
	if unit == "player" and spell == self.processingSpell then
		--DA.DEBUG(0,"UNIT_SPELLCAST_INTERRUPTED("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
		self:StopCast(spell,spellID)
	end
end

function Skillet:UNIT_SPELLCAST_DELAYED(event, unit, spell, rank, lineID, spellID)
--	DA.DEBUG(0,"UNIT_SPELLCAST_DELAYED("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
end

function Skillet:UNIT_SPELLCAST_STOP(event, unit, spell, rank, lineID, spellID)
--	DA.DEBUG(0,"UNIT_SPELLCAST_STOP("..tostring(unit)..", "..tostring(spell)..", "..tostring(rank)..", "..tostring(lineID)..", "..tostring(spellID)..")")
--	if unit == "player" and spell == self.processingSpell then
--		self:ContinueCast(spell,spellID)
--	end
end

-- Continue a trade skill currently in progress. Called from UNIT_SPELLCAST_SUCCEEDED when that event applies to us
-- Counts down each successful completion of the current command and does finish processing when the count reaches zero
function Skillet:ContinueCast(spell, spellID)
	DA.DEBUG(0,"ContinueCast("..tostring(spell)..", "..tostring(spellID)..")")
	if spell == self.processingSpell then
		--DA.DEBUG(0,"ContinueCast: processingCount= "..tostring(Skillet.processingCount))
		local queue = self.db.realm.queueData[self.currentPlayer]
		local qpos = self.processingPosition
		if queue[qpos] and queue[qpos] == self.processingCommand then
			local command = queue[qpos]
			if command.op == "iterate" then
				command.count = command.count - 1
				if command.count == 0 then
					self:RemoveFromQueue(qpos)
				end
			end
		end
		Skillet.processingCount = Skillet.processingCount - 1
		if Skillet.processingCount == 0 then
			self.queuecasting = false
			self.processingSpell = nil
			self.processingSpellID = nil
			self.processingPosition = nil
			self.processingCommand = nil
		end
--		Skillet:AdjustInventory()	-- Adjustment of the inventory and updating the window will happen via other events
	end
end

-- Stop a trade skill currently in progress. Called from UNIT_SPELLCAST_* events that indicate failure
function Skillet:StopCast(spell, spellID)
	DA.DEBUG(0,"StopCast("..tostring(spell)..", "..tostring(spellID)..")")
	if spell == self.processingSpell then
		self.queuecasting = false
		self.processingSpell = nil
		self.processingSpellID = nil
		self.processingPosition = nil
		self.processingCommand = nil
		self.processingCount = nil
	end
end

-- Cancel a trade skill currently in progress. We cannot cancel the current
-- item as that requires a "SpellStopCasting" call which can only be
-- made from secure code. All this does is stop repeating after the current item
function Skillet:CancelCast()
	DA.DEBUG(0,"CancelCast()")
	--C_TradeSkillUI.StopRecipeRepeat()
end

-- Removes an item from the queue
function Skillet:RemoveQueuedCommand(queueIndex)
	DA.DEBUG(0,"RemoveQueuedCommand("..tostring(queueIndex)..")")
	self:RemoveFromQueue(queueIndex)
	self:UpdateTradeSkillWindow()
end

-- Rebuilds reagentsInQueue list
function Skillet:ScanQueuedReagents()
	DA.DEBUG(0,"ScanQueuedReagents()")
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
				reagentsInQueue[reagent.reagentID] = (reagentsInQueue[reagent.reagentID] or 0) - reagent.numNeeded * command.count
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
