--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

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

local AceEvent = AceLibrary("AceEvent-2.0")

local QUEUE_DEBUG = false

-- Adds the recipe to the queue of recipes to be processed. If the recipe
-- is already in the queue, then the count of items to be created is increased,
-- otherwise the recipe is added it the end
--
-- If there are item needs to make the recipe that are not currently in your
-- inventory, but you can craft them, then they are added to the queue before the
-- requested recipe.
local function add_items_to_queue(skillIndex, recipe, count)
    assert(tonumber(skillIndex) and recipe and tonumber(count),"Usage: add_items_to_queue(skillIndex, recipe, count)")

    -- if we need mats that are not in the inventory, but are craftable, add
    -- the mats to the queue first

    if QUEUE_DEBUG then
        Skillet:Print("Adding " .. count .. "x" .. recipe.link)
    end

    if Skillet.db.profile.queue_craftable_reagents then
        -- never more that 8 reagents
        for i=1, 8, 1 do
            reagent = recipe[i]

            if not reagent then
                break
            end

            local needed = (reagent.needed * count)
            local   have = GetItemCount(reagent.link, true)

            if QUEUE_DEBUG then
                Skillet:Print("  have " .. have .. "x" .. reagent.link .. ", need " .. needed)
            end

            if have < needed then
				-- see if we can make this! only scan current trade though.  (adding items to OTHER trades might also be interesting, but needs a bit of rewriting /mikk)
                local item = Skillet.stitch:GetItemDataByName(reagent.name, Skillet.currentTrade)

                if item and item.link == reagent.link then
                    -- we can craft this
                    -- the extra check for an exact name match is because the
                    -- Stitch search will fall back on a wild card across all
                    -- skills if an exact match is not found

                    -- Try and guard against infinite recursion here. This will
                    -- not prevent the error, but will help detect it and generate
                    -- more meaningful error
                    assert(recipe.link ~= item.link, "Recursive loop detected Recipe item: " ..
                                                     recipe.link .. " has reagent " .. reagent.link)
                    add_items_to_queue(item.index, item, (needed - have))
                end
            end
        end
    end

	Skillet.stitch:AddToQueue(skillIndex, count)

    -- XXX: This is a bit hacky, try to think of something smarter
    Skillet:SaveQueue(Skillet.db.server.queues, Skillet.currentTrade)
end

-- Save the current queue into the provided database
function Skillet:SaveQueue(db, tradeskill)
    if not db[UnitName("player")] then
        db[UnitName("player")] = {}
    end

    db[UnitName("player")][tradeskill] = self.stitch.queue
end

-- Loads the queue for the provided tradeskill name from the database
function Skillet:LoadQueue(db, tradeskill)
    if not db[UnitName("player")] then
        db[UnitName("player")] = {}
    end
    if not db[UnitName("player")][tradeskill] then
        db[UnitName("player")][tradeskill] = {}
    end

    self.stitch.queue = db[UnitName("player")][tradeskill]

    AceEvent:TriggerEvent("SkilletStitch_Queue_Add")
end

-- Queue the max number of craftable items for the currently selected skill
function Skillet:QueueAllItems()
	if self.currentTrade and self.selectedSkill then
		local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill)
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable/factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                add_items_to_queue(self.selectedSkill, s, count)
            end
			-- queued all that could be created, reset the create count
			-- back down to 0
			self:UpdateNumItemsSlider(0, false);
		end
	end
end

-- Adds the currently selected number of items to the queue
function Skillet:QueueItems()
	self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

	if self.numItemsToCraft > 0 then
		if self.currentTrade and self.selectedSkill then
			local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
			if s then
				add_items_to_queue(self.selectedSkill, s, self.numItemsToCraft)
			end
		end
	end
end

-- Queue and create the max number of craftable items for the currently selected skill
function Skillet:CreateAllItems()
	if self.currentTrade and self.selectedSkill then
		local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable/factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                add_items_to_queue(self.selectedSkill, s, count)
                self:ProcessQueue()
            end
            -- created all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false)
		end
	end
end

-- Adds the currently selected number of items to the queue and then starts the queue
function Skillet:CreateItems()
	self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

	if self.numItemsToCraft > 0 then
		if self.currentTrade and self.selectedSkill then
			local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
			if s then
				add_items_to_queue(self.selectedSkill, s, self.numItemsToCraft)
				self:ProcessQueue();
			end
		end
	end
end

-- Starts Processing any items in the queue
function Skillet:ProcessQueue()
	local queue = self.stitch:GetQueueInfo()
	if not queue then
		return
	end

	self.stitch:ProcessQueue()
end

-- Clears the current queue, this will not cancel an
-- items currently being crafted.
function Skillet:EmptyQueue()
	self.stitch:ClearQueue()
    self:SaveQueue(self.db.server.queues, self.currentTrade)
end

-- Removes an item from the queue
function Skillet:RemoveQueuedItem(id)
    local queue = self.stitch:GetQueueInfo();
    if not queue then
        -- this should never happen, log an error?
        return
    end

    if id == 1 then
        self.stitch:CancelCast()
    end

    self.stitch:RemoveFromQueue(id)
    self:SaveQueue(self.db.server.queues, self.currentTrade)

    self:UpdateQueueWindow()
end

-- Returns a table {playername, queues} containing all queued
-- items
function Skillet:GetAllQueues()
    if not self.db.server.queues then
        return {}
    end

    return self.db.server.queues
end

-- Returns the list of queues for the specified player
function Skillet:GetQueues(player)
    assert(tostring(player),"Usage: GetQueues('player_name')")

    if not self.db.server.queues then
        return {}
    end

    if not self.db.server.queues[player] then
        return {}
    end

    return self.db.server.queues[player]
end

-- Returns the list of queues for the current player
function Skillet:GetPlayerQueues()
    return self:GetQueues(UnitName("player"))
end

-- Updates the list with the required number of items
-- of "link". If "name" is already in the list, the count in updated,
-- otherwise it is appended to the end of the list.
local function update_queued_list(list, player, name, link, needed)
    for i=1,#list,1 do
        if list[i]["name"] == name then
            list[i]["count"] = list[i]["count"] + needed
            if list[i].player and not string.find(list[i].player, player) then
                list[i].player = list[i].player .. ", " .. player
            end
            return
        end
    end

    table.insert(list, {
        ["name"]  = name,
        ["link"]  = link,
        ["count"] = needed,
        ["player"] = player,
    })
end

--
-- Checks the queued items and calculates how many of each reagent is required.
-- The table of reagents and counts is returned. The will examine the queues for
-- all professions, not just the currently selected on.
--
-- If the player name is not provided, then the queues for all players are checked.
--
-- The returned table contains:
--     name : name of the item
--     link : link for the item
--     count : how many of this item is needed
--     player : comma separated list of players that need the item for their queues
--
function Skillet:GetReagentsForQueuedRecipes(playername)
    local list = {}

    for player,playerqueues in pairs(self:GetAllQueues()) do
        -- check the queues for all professions
        if not playername or playername == player then
            for _,queue in pairs(playerqueues) do
                -- this is what we need
                if queue and #queue > 0 then
                    for i=1,#queue,1 do
                        local recipe = self.stitch:DecodeRecipe(queue[i].recipe)
                        local count = queue[i]["numcasts"]

                        for i=1, 8, 1 do
                            -- no recipes have more than 8 reagents
                            local reagent = recipe[i]
                            if reagent then
                                local needed = (count * reagent.needed)
                                if needed > 0 then
                                    update_queued_list(list, player, reagent.name, reagent.link, needed)
                                end
                            end
                        end

                    end
                end
            end
        end
    end

    return list
end
