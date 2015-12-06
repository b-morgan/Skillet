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

--[[
#
# Deals with building and maintaining a shopping list. This is the list
# of items that are required for queued recipes but are not currently
# in the inventory
#
]]--

SKILLET_SHOPPING_LIST_HEIGHT = 16

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")

-- Stolen from the Waterfall Ace2 addon.
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
local FrameBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

local bankFrameOpen = false
local bank                   -- Detailed contents of the bank.

local guildbankFrameOpen = false
local guildbankQuery = 0     -- Need to wait until all the QueryGuildBankTab()s finish
local guildbankOnce = true   -- but only indexGuildBank once for each OPENED
local guildbank              -- Detailed contents of the guildbank

-- Creates and sets up the shopping list window
local function createShoppingListFrame(self)
	local frame = SkilletShoppingList
	if not frame then
		return nil
	end

	frame:SetBackdrop(FrameBackdrop);
	frame:SetBackdropColor(0.1, 0.1, 0.1)

	-- A title bar stolen from the Ace2 Waterfall window.
	local r,g,b = 0, 0.7, 0; -- dark green
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")

	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)

	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)

	titlebar:SetGradientAlpha("VERTICAL",r*0.6,g*0.6,b*0.6,1,r,g,b,1)
	titlebar:SetTexture(r,g,b,1)
	titlebar2:SetGradientAlpha("VERTICAL",r*0.9,g*0.9,b*0.9,1,r*0.6,g*0.6,b*0.6,1)
	titlebar2:SetTexture(r,g,b,1)

	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)

	local titletext = title:CreateFontString("SkilletShoppingListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: " .. L["Shopping List"])

	SkilletShowQueuesFromAllAltsText:SetText(L["Include alts"])
	SkilletShowQueuesFromAllAlts:SetChecked(Skillet.db.char.include_alts)

	SkilletShowQueuesInItemOrderText:SetText(L["Order by item"])
	SkilletShowQueuesInItemOrder:SetChecked(Skillet.db.char.item_order)

	SkilletShowQueuesMergeItemsText:SetText(L["Merge items"])
	SkilletShowQueuesMergeItems:SetChecked(Skillet.db.char.merge_items)

	SkilletShowQueuesIncludeGuildText:SetText(L["Include guild"])
	SkilletShowQueuesIncludeGuild:SetChecked(Skillet.db.char.include_guild)

	-- The frame enclosing the scroll list needs a border and a background .....
	local backdrop = SkilletShoppingListParent
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)

	-- Button to retrieve items needed from the bank
	SkilletShoppingListRetrieveButton:SetText(L["Retrieve"])

	-- Ace Window manager library, allows the window position (and size)
	-- to be automatically saved
	local windowManger = LibStub("LibWindow-1.1")
	local shoppingListLocation = {
		prefix = "shoppingListLocation_"
	}
	windowManger.RegisterConfig(frame, self.db.profile, shoppingListLocation)
	windowManger.RestorePosition(frame)  -- restores scale also
	windowManger.MakeDraggable(frame)
	-- lets play the resize me game!
	Skillet:EnableResize(frame, 300, 165, Skillet.UpdateShoppingListWindow)
	-- so hitting [ESC] will close the window
	tinsert(UISpecialFrames, frame:GetName())
	return frame
end

function Skillet:ShoppingListButton_OnEnter(button)
	local name, link, quality = self:GetItemInfo(button.id)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
	if EnhTooltip and EnhTooltip.TooltipCall then
		local quantity = button.count
		EnhTooltip.TooltipCall(GameTooltip, name, link, quality, quantity)
	end
	CursorUpdate(button)
end

function Skillet:ClearShoppingList(player)
	DA.DEBUG(0,"ClearShoppingList(",player,")")
	local playerList
	if player then
		playerList = { player }
	else
		playerList = {}
		for player,queue in pairs(self.db.realm.reagentsInQueue) do
			table.insert(playerList, player)
		end
	end
	DA.DEBUG(0,"clear shopping list for: "..(player or "all players"))
	for i=1,#playerList,1 do
		local player = playerList[i]
		DA.DEBUG(1,"player: "..player)
		self.db.realm.reagentsInQueue[player] = {}
		self.db.realm.queueData[player] = {}
		self.db.realm.inventoryData[player] = {}
	end
	self:UpdateShoppingListWindow(false)
	self:UpdateTradeSkillWindow()
end

function Skillet:GetShoppingList(player, includeGuildbank)
	DA.DEBUG(0,"GetShoppingList("..tostring(player)..", "..tostring(includeGuildbank)..")")
	self:InventoryScan()
	if not Skillet.db.global.cachedGuildbank then
		Skillet.db.global.cachedGuildbank = {}
	end
 	local cachedGuildbank = Skillet.db.global.cachedGuildbank
	local list = {}
	local playerList
	if player then
		playerList = { player }
	else
		playerList = {}
		for player,queue in pairs(self.db.realm.reagentsInQueue) do
			table.insert(playerList, player)
		end
	end
	DA.DEBUG(0,"shopping list for: "..(player or "all players"))
	local usedInventory = {}  -- only use the items from each player once
	local curPlayer = self.currentPlayer
	local usedGuild = {}
	if not usedInventory[curPlayer] then
		usedInventory[curPlayer] = {}
	end
	local curGuild = GetGuildInfo("player")
	if curGuild and not cachedGuildbank[curGuild] then
		cachedGuildbank[curGuild] = {}
	end
	for i=1,#playerList,1 do
		local player = playerList[i]
		if not usedInventory[player] then
			usedInventory[player] = {}
		end
		local reagentsInQueue = self.db.realm.reagentsInQueue[player]
		DA.DEBUG(1,"player: "..player)
		if reagentsInQueue then
			for id,count in pairs(reagentsInQueue) do
			DA.DEBUG(2,"reagent: "..id.." x "..count)
				local deficit = count -- deficit is usually negative
				local numInBoth, numInBothCurrent, numGuildbank = 0,0,0
				local _
				if not usedInventory[player][id] then
					numInBoth = self:GetInventory(player, id)
				end
				DA.DEBUG(2,"numInBoth= "..numInBoth)
				if numInBoth > 0 then
					usedInventory[player][id] = true
				end
				if player ~= self.currentPlayer then
					if not usedInventory[curPlayer] then
						numInBothCurrent = self:GetInventory(curPlayer, id)
					end
					DA.DEBUG(2,"numInBothCurrent= "..numInBothCurrent)
					if numInBothCurrent > 0 then
						usedInventory[curPlayer][id] = true
					end
				end
				deficit = deficit + numInBoth + numInBothCurrent
				if curGuild and not cachedGuildbank[curGuild][id] then
					cachedGuildbank[curGuild][id] = 0
				end
				if not usedGuild[id] then
					usedGuild[id] = 0
				end
				-- If the Guildbank should be included then
				-- the player must be in the guild to use items from the guild bank and
				-- only count guild bank items when not at the guild bank because
				-- we might start using them.
				if includeGuildbank and curGuild and not guildbankFrameOpen then
					DA.DEBUG(2,"deficit=",deficit,"cachedGuildbank=",cachedGuildbank[curGuild][id],"usedGuild=",usedGuild[id])
					local temp = -1 * math.min(deficit,0) -- calculate exactly how many are needed
					deficit = deficit + cachedGuildbank[curGuild][id] - usedGuild[id]
					usedGuild[id] = usedGuild[id] + temp  -- keep track how many have been used
					usedGuild[id] = math.min(usedGuild[id], cachedGuildbank[curGuild][id]) -- but don't use more than there is
				end
				if deficit < 0 then
					local entry = { ["id"] = id, ["count"] = -deficit, ["player"] = player, ["value"] = 0, ["source"] = "?" }
					table.insert(list, entry)
				end
			end
		end
	end
	return list
end

local function cache_list(self)
	local name = nil
	if not Skillet.db.char.include_alts then
		name = Skillet.currentPlayer
	end
	self.cachedShoppingList = self:GetShoppingList(name, Skillet.db.char.include_guild)
end

local function indexBank()
	DA.DEBUG(0,"indexBank()")
-- bank contains detailed contents of each tab,slot which 
-- is only needed while the bank is open.
--
	bank = {}
	local player = Skillet.currentPlayer
	local bankBags = {-1,5,6,7,8,9,10,11,-3}
	for _, container in pairs(bankBags) do
		for i = 1, GetContainerNumSlots(container), 1 do
			local item = GetContainerItemLink(container, i)
			if item then
				local _,count = GetContainerItemInfo(container, i)
				local id = Skillet:GetItemIDFromLink(item)
				if id then
					table.insert(bank, {
						["bag"]   = container,
						["slot"]  = i,
						["id"]  = id,
						["count"] = count,
					})
				end
			end
		end
	end
end

local function indexGuildBank(tab)
	DA.DEBUG(0,"indexGuildBank("..tostring(tab)..")")
	--
	-- Build a current view of the contents of the Guildbank (one tab at a time).
	--
	-- guildbank contains detailed contents of each tab,slot which 
	-- is only needed while the guildbank is open.
	--
	-- cachedGuildbank is a count by item, usable (but not necessarily 
	-- accurate) when the Guildbank is closed.
	-- It is in db.global instead of db.realm because of connected realms 
	-- This means it is broken if this account is in guilds on 
	-- different realms (not connected) with the same name.
	--
	local guildName = GetGuildInfo("player")
	local cachedGuildbank = Skillet.db.global.cachedGuildbank
	local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab);
	DA.DEBUG(1,"indexGuildBank tab="..tab..", isViewable="..tostring(isViewable)..", numWithdrawals="..numWithdrawals)
	if(isViewable and numWithdrawals~=0) then
		for slot=1, MAX_GUILDBANK_SLOTS_PER_TAB or 98, 1 do
			local item = GetGuildBankItemLink(tab, slot)
			if item then
				local _,count = GetGuildBankItemInfo(tab, slot)
				local id = Skillet:GetItemIDFromLink(item)
				if id then
					table.insert(guildbank, {
						["bag"]   = tab,
						["slot"]  = slot,
						["id"]  = id,
						["count"] = count,
					})
					if not cachedGuildbank[guildName][id] then
						cachedGuildbank[guildName][id] = 0
					end
					cachedGuildbank[guildName][id] = cachedGuildbank[guildName][id] + count
				end
			end
		end
	end
end

function Skillet:indexAllGuildBankTabs()
	local numTabs = GetNumGuildBankTabs()
	for tab=1, numTabs, 1 do
		indexGuildBank(tab)
	end
	guildbankFrameOpen = true
end

-- Called when the bank frame is opened
function Skillet:BANKFRAME_OPENED()
	DA.DEBUG(0,"BANKFRAME_OPENED")
	bankFrameOpen = true
	indexBank()
	if not self.db.profile.display_shopping_list_at_bank then
		return
	end
	Skillet.bankBusy = false
	Skillet.bankQueue = {}
	bank = {}
	cache_list(self)
	if #self.cachedShoppingList == 0 then
		return
	end
	self:DisplayShoppingList(true) -- true -> at a bank
end

-- Called when the bank frame is closed
function Skillet:BANKFRAME_CLOSED()
	DA.DEBUG(0,"BANKFRAME_CLOSED")
	bankFrameOpen = false
	self:HideShoppingList()
end

function Skillet:GUILDBANKFRAME_OPENED()
	DA.DEBUG(0,"GUILDBANKFRAME_OPENED")
	guildbankQuery = 0
	guildbankOnce = true
	Skillet.guildBusy = false
	Skillet.guildQueue = {}
	guildbank = {}
	local guildName = GetGuildInfo("player")
	Skillet.db.global.cachedGuildbank[guildName] = {}
	local numTabs = GetNumGuildBankTabs()
	for tab=1, numTabs, 1 do
		QueryGuildBankTab(tab)  -- event GUILDBANKBAGSLOTS_CHANGED will fire when the data is available
	end
	if not self.db.profile.display_shopping_list_at_guildbank then
		return
	end
	cache_list(self)
	if #self.cachedShoppingList == 0 then
		return
	end
	self:DisplayShoppingList(true) -- true -> at a bank
end

-- Called when the guild bank frame is closed
function Skillet:GUILDBANKFRAME_CLOSED()
	DA.DEBUG(0,"GUILDBANKFRAME_CLOSED")
	guildbankFrameOpen = false
	self:HideShoppingList()
end

-- Called when the cursor has changed (should only be needed while debugging)
function Skillet:CURSOR_UPDATE()
	local type, data, subType, subData = GetCursorInfo()
	DA.TRACE("CURSOR_UPDATE - type=",type,", data=",data,", subType=",subType)
end

-- Called when the auction frame is opened
function Skillet:AUCTION_HOUSE_SHOW()
	self:AuctionScan()
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	if not self.db.profile.display_shopping_list_at_auction then
		return
	end
	cache_list(self)
	if #self.cachedShoppingList == 0 then
		return
	end
	self:DisplayShoppingList(false) -- false -> not at a bank
end

-- Called when the auction frame is closed
function Skillet:AUCTION_HOUSE_CLOSED()
	self:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
	self:HideShoppingList()
end

--	Called when the auction list updates and the auction frame is opened.
function Skillet:AUCTION_OWNED_LIST_UPDATE()
	self:AuctionScan()
 end

-- checks to see if this is a normal bag (not ammo, herb, enchanting, etc)
-- I borrowed this code from ClosetGnome.
local function isNormalBag(bagId)
	-- backpack and bank are always normal
	if bagId == 0 or bagId == -1 then return true end
	local id = GetInventoryItemID("player", ContainerIDToInventoryID(bagId))
	if not id then return false end
	local bagType = select(7, GetItemInfo(id))
	-- INVTYPE_BAG is defined by Blizzard
	if bagType and bagType == INVTYPE_BAG then return true end
	return false
end

-- Returns a bag that the item can be placed in.
local function findBagForItem(itemID, count)
	if not itemID then return nil end
	local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemID)
	for container = 0, 4, 1 do
		if isNormalBag(container) then
			local bag_size = GetContainerNumSlots(container) -- 0 if there is no bag
			for slot = 1, bag_size, 1 do
				local bagitem = GetContainerItemID(container, slot)
				if bagitem then
					if itemID == bagitem then
						-- found some of the same, it is a full stack or locked?
						local _, num_in_bag, locked  = GetContainerItemInfo(container, slot)
						local space_available = itemStackCount - num_in_bag
						if space_available >= count and not locked then
							return container, slot, true
						end
					end
				else
					-- no item there, this looks like a good place to put something.
					return container, slot, false
				end
			end
		end
	end
	return nil, nil
end

local function getItemFromBank(itemID, bag, slot, count)
	DA.DEBUG(0,"getItemFromBank(", itemID, bag, slot, count,")")
	ClearCursor()
	local _, available = GetContainerItemInfo(bag, slot)
	local num_moved = 0
	if available then
		if available == 1 or count >= available then
			DA.DEBUG(1,"PickupContainerItem(",bag,", ", slot,")")
			PickupContainerItem(bag, slot)
			num_moved = available
		else
			DA.DEBUG(1,"SplitContainerItem(",bag, slot, count,")")
			SplitContainerItem(bag, slot, count)
			num_moved = count
		end
		local tobag, toslot = findBagForItem(itemID, num_moved)
		DA.DEBUG(1,"tobag=", tobag, " toslot=", toslot, " findBagForItem(", itemID, num_moved,")")
		if not tobag then
			Skillet:Print(L["Could not find bag space for"]..": "..GetContainerItemLink(bag, slot))
			ClearCursor()
			return 0
		end
		if tobag == 0 then
			DA.DEBUG(1,"PutItemInBackpack()")
			PutItemInBackpack()
		else
			DA.DEBUG(1,"PutItemInBag(",ContainerIDToInventoryID(tobag),")")
			PutItemInBag(ContainerIDToInventoryID(tobag))
		end
	end
	ClearCursor()
	return num_moved
end

local function getItemFromGuildBank(itemID, bag, slot, count)
	DA.DEBUG(0,"getItemFromGuildBank(",itemID, bag, slot, count,")")
	ClearCursor()
	local _, available = GetGuildBankItemInfo(bag, slot)
	local num_moved = 0
	if available then
		if available == 1 or count >= available then
			DA.DEBUG(1,"PickupGuildBankItem(",bag, slot,")")
			PickupGuildBankItem(bag, slot)
			num_moved = available
		else
			DA.DEBUG(1,"SplitGuildBankItem(",bag, slot, count,")")
			SplitGuildBankItem(bag, slot, count)
			num_moved = count
		end
		local tobag, toslot = findBagForItem(itemID, num_moved)
		DA.DEBUG(1,"tobag=", tobag, " toslot=", toslot, " findBagForItem(", itemID, num_moved,")")
		if not tobag then
			Skillet:Print(L["Could not find bag space for"]..": "..GetGuildBankItemLink(bag, slot))
			ClearCursor()
			return 0
		else
			DA.DEBUG(1,"PickupContainerItem(",tobag, toslot,")")
			PickupContainerItem(tobag, toslot) -- actually puts the item in the bag
		end
	end
	ClearCursor()
	return num_moved
end

-- Called once to get things started and then is called after both
-- BANK_UPDATE (subset of BAG_UPDATE) and BAG_UPDATE_DELAYED events have fired.
local function processBankQueue(where)
	DA.DEBUG(1,"processBankQueue("..where..")")
	local bankQueue = Skillet.bankQueue
	if Skillet.bankBusy then
		DA.DEBUG(1,"BANK_UPDATE and bankBusy")
		while true do
			local queueitem = table.remove(bankQueue,1)
			if queueitem then
				local id = queueitem["id"]
				local j = queueitem["j"]
				local v = queueitem["list"]
				local i = queueitem["i"]
				local item = queueitem["item"]
--				DA.DEBUG(3,"j=",j,", v=",DA.DUMP1(v))
--				DA.DEBUG(3,"i=",i,", item=",DA.DUMP1(item))
				Skillet.gotBankEvent = false
				Skillet.gotBagUpdateEvent = false
				local moved = getItemFromBank(id, item.bag, item.slot, v.count)
				if moved > 0 then
					v.count = v.count - moved
					item.count = item.count - moved -- adjust our cached copy
					break
				end
			else
				Skillet.bankBusy = false
				break
			end
		end
	end
end

-- Subset of the BAG_UPDATE event processed in Skillet.lua
-- It may look like a real Blizzard event but its not.
function Skillet:BANK_UPDATE(event,bagID) 
	DA.DEBUG(2,"BANK_UPDATE( "..tostring(bagID).." )")
	if Skillet.bankBusy then
		DA.DEBUG(1, "BANK_UPDATE and bankBusy")
		Skillet.gotBankEvent = true
		if Skillet.gotBankEvent and Skillet.gotBagUpdateEvent then
			processBankQueue("bank update")
		end
	end
end

-- Called once to get things started and then is called after both
-- GUILDBANKBAGSLOTS_CHANGED and BAG_UPDATE_DELAYED events have fired.
local function processGuildQueue(where)
	DA.DEBUG(1,"processGuildQueue("..where..")")
	local guildQueue = Skillet.guildQueue
	if Skillet.guildBusy then
		while true do
			local queueitem = table.remove(guildQueue,1)
			if queueitem then
				local id = queueitem["id"]
				local j = queueitem["j"]
				local v = queueitem["list"]
				local i = queueitem["i"]
				local item = queueitem["item"]
				DA.DEBUG(2,"j=",j,", v=",DA.DUMP1(v))
				DA.DEBUG(2,"i=",i,", item=",DA.DUMP1(item))
				Skillet.gotGuildbankEvent = false
				Skillet.gotBagUpdateEvent = false
				local moved = getItemFromGuildBank(id, item.bag, item.slot, v.count)
				if moved > 0 then
					v.count = v.count - moved
					item.count = item.count - moved -- adjust our cached copy
					break
				end
			else
				Skillet.guildBusy = false
				break
			end
		end
	end
end

-- Event is fired when the guild bank contents change.
-- Called as a result of a QueryGuildBankTab call or as a result of a change in the guildbank's contents.
function Skillet:GUILDBANKBAGSLOTS_CHANGED(event)
	DA.DEBUG(2,"GUILDBANKBAGSLOTS_CHANGED")
	if guildbankOnce then
		guildbankQuery = guildbankQuery + 1
		if guildbankQuery == GetNumGuildBankTabs() then
			guildbankOnce = false
			self:ScheduleTimer("indexAllGuildBankTabs", 0.5)
		end
	end
	if Skillet.guildBusy then
		DA.DEBUG(1," GUILDBANKBAGSLOTS_CHANGED and guildBusy")
		Skillet.gotGuildbankEvent = true
		if Skillet.gotGuildbankEvent and Skillet.gotBagUpdateEvent then
			processGuildQueue("guild bank")
		end
	end
end

-- Event is fired when the main bank (bagID == -1) contents change.
function Skillet:PLAYERBANKSLOTS_CHANGED(event,slot)
	DA.DEBUG(2,"PLAYERBANKSLOTS_CHANGED"..", slot="..tostring(slot))
	if Skillet.bankBusy then
		DA.DEBUG(1,"PLAYERBANKSLOTS_CHANGED and bankBusy")
		Skillet.gotBankEvent = true
		if Skillet.gotBankEvent and Skillet.gotBagUpdateEvent then
			processBankQueue("bag update")
		end
	end
end

-- Event is fired when the reagent bank (bagID == -3) contents change.
function Skillet:PLAYERREAGENTBANKSLOTS_CHANGED(event,slot)
	DA.DEBUG(2,"PLAYERREAGENTBANKSLOTS_CHANGED"..", slot="..tostring(slot))
	if Skillet.bankBusy then
		DA.DEBUG(1,"PLAYERREAGENTBANKSLOTS_CHANGED and bankBusy")
		Skillet.gotBankEvent = true
		if Skillet.gotBankEvent and Skillet.gotBagUpdateEvent then
			processBankQueue("bag update")
		end
	end
end

-- Event fires after all applicable BAG_UPDATE events for a specific action have been fired.
-- It doesn't happen as often as BAG_UPDATE so its a better event for us to use.
function Skillet:BAG_UPDATE_DELAYED(event)
	DA.DEBUG(2,"BAG_UPDATE_DELAYED")
	if Skillet.bankBusy then
		DA.DEBUG(1,"BAG_UPDATE_DELAYED and bankBusy")
		Skillet.gotBagUpdateEvent = true
		if Skillet.gotBankEvent and Skillet.gotBagUpdateEvent then
			processBankQueue("bag update")
		end
	end
	if Skillet.guildBusy then
		DA.DEBUG(1,"BAG_UPDATE_DELAYED and guildBusy")
		Skillet.gotBagUpdateEvent = true
		if Skillet.gotGuildbankEvent and Skillet.gotBagUpdateEvent then
			processGuildQueue("bag update")
		end
	end
end

-- Gets all the reagents possible for queued recipes from the bank
function Skillet:GetReagentsFromBanks()
	DA.DEBUG(0,"GetReagentsFromBanks")
	local list = self.cachedShoppingList
	local incAlts = Skillet.db.char.include_alts
	local name = UnitName("player")

	-- Do things using a queue and events.
	if bankFrameOpen then
		DA.DEBUG(0,"#list=",#list)
		local bankQueue = Skillet.bankQueue
		for j,v in pairs(list) do
			DA.DEBUG(2,"j=",j,", v=",DA.DUMP1(v))
			local id = v.id
			if incAlts or v.player == name then
				for i,item in pairs(bank) do
					if item.id == id then
						DA.DEBUG(2,"i=",i,", item=",DA.DUMP1(item))
						if item.count > 0 and v.count > 0 then
							table.insert(bankQueue, {
								["id"]    = id,
								["bag"]   = item.bag,
								["slot"]  = item.slot,
								["j"]     = j,
								["list"]  = v,
								["i"]     = i,
								["item"]  = item,
							})
							if not Skillet.bankBusy then
								Skillet.bankBusy = true
								processBankQueue("get reagents")
							end
						end
					end
				end
			end
		end
	end

	-- Do things using a queue and events.
	if guildbankFrameOpen then
		DA.DEBUG(0,"#list=",#list)
		local guildQueue = Skillet.guildQueue
		for j,v in pairs(list) do
			DA.DEBUG(2,"j=",j,", v=",DA.DUMP1(v))
			local id = v.id
			if incAlts or v.player == name then
				for i,item in pairs(guildbank) do
					if item.id == id then
						DA.DEBUG(2,"i=",i,", item=",DA.DUMP1(item))
						if item.count > 0 and v.count > 0 then
							table.insert(guildQueue, {
								["id"]    = id,
								["bag"]   = item.bag,
								["slot"]  = item.slot,
								["j"]     = j,
								["list"]  = v,
								["i"]     = i,
								["item"]  = item,
							})
							if not Skillet.guildBusy then
								Skillet.guildBusy = true
								processGuildQueue("get reagents")
							end
						end
					end
				end
			end
		end
	end
end

function Skillet:ShoppingListToggleShowAlts()
	Skillet.db.char.include_alts = not Skillet.db.char.include_alts
end

function Skillet:ShoppingListToggleItemOrder()
	Skillet.db.char.item_order = not Skillet.db.char.item_order
end

function Skillet:ShoppingListToggleMergeItems()
	Skillet.db.char.merge_items = not Skillet.db.char.merge_items
end

function Skillet:ShoppingListToggleIncludeGuild()
	Skillet.db.char.include_guild = not Skillet.db.char.include_guild
end

local function get_button(i)
	local button = _G["SkilletShoppingListButton"..i]
	if not button then
		button = CreateFrame("Button", "SkilletShoppingListButton"..i, SkilletShoppingListParent, "SkilletShoppingListItemButtonTemplate")
		button:SetParent(SkilletShoppingList)
		button:SetPoint("TOPLEFT", "SkilletShoppingListButton"..(i-1), "BOTTOMLEFT")
	end
	if not button.valueText then
		button.valueText = button:CreateFontString(nil, nil, "GameFontNormal")
		button.valueText:SetPoint("LEFT",button,"RIGHT",0,0)
		button.valueText:SetText("00 00")
		button.valueText:SetWidth(60)
		button.valueText:SetHeight(button:GetHeight())
	end
	return button
end

-- Called to update the shopping list window
function Skillet:UpdateShoppingListWindow(use_cached_recipes)
	DA.DEBUG(0,"UpdateShoppingListWindow(",use_cached_recipes,")")
	local num_buttons = 0
	if not self.shoppingList or not self.shoppingList:IsVisible() then
		return
	end
	if not use_cached_recipes then
		cache_list(self)
	end
	SkilletShoppingList:SetAlpha(self.db.profile.transparency)
	SkilletShoppingList:SetScale(self.db.profile.scale)
	local numItems = #self.cachedShoppingList
	if numItems == 0 then
		SkilletShoppingListRetrieveButton:Disable()
	else
		SkilletShoppingListRetrieveButton:Enable()
	end
	if Skillet.db.char.item_order then
		--sort by item
		table.sort(self.cachedShoppingList, function(a,b)
			return (a.id > b.id)
		end)
		if Skillet.db.char.merge_items then
			--merge counts of same item
			local tryAgain = true
			while tryAgain do
				local o = nil
				local oitem = { ["id"] = 0, ["count"] = 0, ["player"] = "", ["value"] = 0, ["source"] = "?" }
				local removedOne = false
				for i,item in pairs(self.cachedShoppingList) do
					if oitem.id == item.id then
						item.count = item.count + oitem.count
						item.player = ""
						table.remove(self.cachedShoppingList,o)
						removedOne = true
					end
				o = i
				oitem = self.cachedShoppingList[o]
				end
				if not removedOne then
					tryAgain = false
				end
			end
			numItems = #self.cachedShoppingList
		end
	else
		--sort by name
		table.sort(self.cachedShoppingList, function(a,b)
			return (b.player > a.player)
		end)
	end
	local button_count = SkilletShoppingListList:GetHeight() / SKILLET_SHOPPING_LIST_HEIGHT
	button_count = math.floor(button_count)
	-- Update the scroll frame
	FauxScrollFrame_Update(SkilletShoppingListList,          -- frame
							numItems,                        -- num items
							button_count,                    -- num to display
							SKILLET_SHOPPING_LIST_HEIGHT)    -- value step (item height)
	-- Where in the list of items to start counting.
	local itemOffset = FauxScrollFrame_GetOffset(SkilletShoppingListList)
	local width = SkilletShoppingListList:GetWidth()
	local totalPrice = 0
	for i=1, button_count, 1 do
		num_buttons = math.max(num_buttons, i)
		local itemIndex = i + itemOffset
		local button = get_button(i)
		local count  = _G[button:GetName() .. "CountText"]
		local name   = _G[button:GetName() .. "NameText"]
		local player = _G[button:GetName() .. "PlayerText"]
		button:SetWidth(width)
		local button_width = width - 5
		local count_width  = math.max(button_width * 0.1, 30)
		local player_width = math.max(button_width * 0.3, 100)
		local name_width   = math.max(button_width - count_width - player_width, 125)
		count:SetWidth(count_width)
		name:SetWidth(name_width)
		name:SetPoint("LEFT", count:GetName(), "RIGHT", 4)
		player:SetWidth(player_width)
		player:SetPoint("LEFT", name:GetName(), "RIGHT", 4)
		if itemIndex <= numItems then
			count:SetText(self.cachedShoppingList[itemIndex].count)
			name:SetText(GetItemInfo(self.cachedShoppingList[itemIndex].id))
			player:SetText(self.cachedShoppingList[itemIndex].player)
			button.valueText:Hide()
			button.id  = self.cachedShoppingList[itemIndex].id
			button.count = self.cachedShoppingList[itemIndex].count
			button.player = self.cachedShoppingList[itemIndex].player
			button:Show()
			name:Show()
			count:Show()
			player:Show()
		else
			button.id = nil
			button:Hide()
			name:Hide()
			count:Hide()
			player:Hide()
		end
	end
	-- Hide any of the buttons that we created, but don't need right now
	for i = button_count+1, num_buttons, 1 do
	   local button = get_button(i)
	   button:Hide()
	end
end

-- Called when the list of reagents is scrolled
function Skillet:ShoppingList_OnScroll()
	Skillet:UpdateShoppingListWindow(true) -- true == use the cached list of recipes
end

-- Fills out and displays the shopping list frame
function Skillet:internal_DisplayShoppingList(atBank)
	DA.TRACE("internal_DisplayShoppingList")
	if not self.shoppingList then
		self.shoppingList = createShoppingListFrame(self)
	end
	local frame = self.shoppingList
	if atBank then
		SkilletShoppingListRetrieveButton:Show()
	else
		SkilletShoppingListRetrieveButton:Hide()
	end
	cache_list(self)
	if not frame:IsVisible() then
	DA.TRACE("wants to show shopping list")
		frame:Show()
	end
	-- true == use cached recipes, we just loaded them after all
	self:UpdateShoppingListWindow(true)
	DA.TRACE("internal_DisplayShoppingList complete")
end

-- Hides the shopping list window
function Skillet:internal_HideShoppingList()
	if self.shoppingList then
		self.shoppingList:Hide()
	end
	self.cachedShoppingList = nil
end
