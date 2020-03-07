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

Skillet = LibStub("AceAddon-3.0"):NewAddon("Skillet", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet
local DA = Skillet -- needed because LibStub changed the definition of Skillet

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
Skillet.L = L

-- Get version info from the .toc file
local MAJOR_VERSION = GetAddOnMetadata("Skillet", "Version");
local PACKAGE_VERSION = GetAddOnMetadata("Skillet", "X-Curse-Packaged-Version");
local ADDON_BUILD = (select(4, GetBuildInfo())) < 20000 and "Classic" or "Retail"
Skillet.version = MAJOR_VERSION
Skillet.package = PACKAGE_VERSION
Skillet.build = ADDON_BUILD
Skillet.project = WOW_PROJECT_ID
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

Skillet.gttScale = GameTooltip:GetScale()

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

local defaults = {
	profile = {
--
-- user configurable options
--
		vendor_buy_button = true,
		vendor_auto_buy   = false,
		show_item_notes_tooltip = false,
		show_crafters_tooltip = false,
		show_detailed_recipe_tooltip = true,	-- show any tooltips?
		display_full_tooltip = true,			-- show full blizzards tooltip
		link_craftable_reagents = true,
		queue_craftable_reagents = true,
		queue_glyph_reagents = false,
		display_required_level = false,
		display_shopping_list_at_bank = true,
		display_shopping_list_at_guildbank = true,
		display_shopping_list_at_auction = true,
		display_shopping_list_at_merchant = false,
		use_blizzard_for_followers = false,
		show_recipe_source_for_learned = false,
		use_guildbank_as_alt = false,
		use_altcurrency_vendor_items = false,
		show_max_upgrade = true,
		enhanced_recipe_display = false,
		confirm_queue_clear = false,
		queue_only_view = true,
		dialog_switch = false,
		scale_tooltip = false,
		transparency = 1.0,
		scale = 1.0,
		ttscale = 1.0,
		plugins = {},
		SavedQueues = {},
	},
	realm = {
--
-- notes added to items crafted or used in crafting
--
		notes = {},
	},
	char = {
--
-- options specific to a current tradeskill
--
		tradeskill_options = {},
		include_alts = true,	-- Display alt's items in shopping list
		same_faction = true,	-- Display same faction alt items only
		item_order =  false,	-- Order shopping list by item
		merge_items = false,	-- Merge same shopping list items together
		include_guild = false,	-- Use the contents of the Guild Bank
	},
}

--
-- default options for each player/tradeskill
--
Skillet.defaultOptions = {
	["sortmethod"] = "None",
	["grouping"] = "Blizzard",
	["searchtext"] = "",
	["filterInventory-bag"] = true,
	["filterInventory-crafted"] = true,
	["filterInventory-vendor"] = true,
	["filterInventory-alts"] = false,
	["filterInventory-owned"] = true,
	["filterLevel"] = 1,
	["hideuncraftable"] = false,
	["favoritesOnly"] = false,
}

Skillet.unknownRecipe = {
	tradeID = 0,
	name = "unknown",
	tools = {},
	reagentData = {},
	cooldown = 0,
	itemID = 0,
	numMade = 0,
	spellID = 0,
	numCraftable = 0,
	numCraftableVendor = 0,
	numCraftableAlts = 0,
}

function Skillet:DisableBlizzardFrame()
	DA.DEBUG(0,"DisableBlizzardFrame()")
	if self.BlizzardTradeSkillFrame == nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		self.BlizzardTradeSkillFrame = TradeSkillFrame
		self.tradeSkillHide = TradeSkillFrame:GetScript("OnHide")
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
	else
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
	end
end

function Skillet:EnableBlizzardFrame()
	DA.DEBUG(0,"EnableBlizzardFrame()")
	if self.BlizzardTradeSkillFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		self.BlizzardTradeSkillFrame = nil
		TradeSkillFrame:SetScript("OnHide", Skillet.tradeSkillHide)
		Skillet.tradeSkillHide = nil
		--ShowUIPanel(TradeSkillFrame)
	end
end

--
-- Called when the addon is loaded
--
function Skillet:OnInitialize()
	if not SkilletDBPC then
		SkilletDBPC = {}
	end
	if not SkilletProfile then
		SkilletProfile = {}
	end
	if not SkilletMemory then
		SkilletMemory = {}
	end
	if DA.deepcopy then			-- For serious debugging, start with a clean slate
		SkilletMemory = {}
		SkilletDBPC = {}
	end
	DA.DebugLog = SkilletDBPC
	DA.DebugProfile = SkilletProfile
	self.db = AceDB:New("SkilletDB", defaults)

--
-- Clean up obsolete data
--
	if self.db.realm.dataVersion then
		self.db.global.dataVersion = self.db.realm.dataVersion
		self.db.realm.dataVersion = nil
	end
	if self.db.realm.reagentBank then
		self.db.realm.reagentBank = nil
	end
	if self.db.global.AllRecipe then
		self.db.global.AllRecipe = nil
	end
	if self.db.realm.Filtered then
		self.db.realm.Filtered = nil
	end
	if self.db.realm.recipeInfo then
		self.db.realm.recipeInfo = nil
	end
	if self.db.realm.skillDB then
		self.db.realm.skillDB = nil
	end

--
-- Change the dataVersion when (major) code changes
-- obsolete the current saved variables database.
--
-- Change the customVersion when code changes obsolete 
-- the custom group specific saved variables data.
--
-- Change the queueVersion when code changes obsolete 
-- the queue specific saved variables data.
--
-- Change the recipeVersion when code changes obsolete 
-- the recipe specific saved variables data.
--
-- When Blizzard releases a new build, there's a chance that
-- recipes have changed (i.e. different reagent requirements) so
-- we clear the saved variables recipe data just to be safe.
--
	local dataVersion = 9
	local queueVersion = 1
	local customVersion = 1
	local recipeVersion = 1
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
	self.wowVersion = wowVersion
	if not self.db.global.dataVersion or self.db.global.dataVersion ~= dataVersion then
		self.db.global.dataVersion = dataVersion
		self:FlushAllData()
	elseif not self.db.global.customVersion or self.db.global.customVersion ~= customVersion then
		self.db.global.customVersion = customVersion
--		self:FlushCustomData()			-- allow one release before doing anything
	elseif not self.db.global.queueVersion or self.db.global.queueVersion ~= queueVersion then
		self.db.global.queueVersion = queueVersion
--		self:FlushQueueData()			-- allow one release before doing anything
	elseif not self.db.global.recipeVersion or self.db.global.recipeVersion ~= recipeVersion then
		self.db.global.recipeVersion = recipeVersion
		self:FlushRecipeData()
	elseif not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end

--
-- Initialize global data
--
	self.db.global.version = self.version	-- save a copy for
	self.db.global.package = self.package	-- post-mortem purposes
	if not self.db.global.recipeDB then
		self.db.global.recipeDB = {}
	end
	if not self.db.global.recipeNameDB then
		self.db.global.recipeNameDB = {}
	end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
	if not self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = {}
	end
	if not self.db.global.Categories then
		self.db.global.Categories = {}
	end
	if not self.db.global.MissingVendorItems then
		self:InitializeMissingVendorItems()
	end
	if not self.db.global.AdjustNumMade then
		self.db.global.AdjustNumMade = {}
	end
	if not self.db.global.spellIDtoName then
		self.db.global.spellIDtoName = {}
	end

--
-- Hook default tooltips
--
	local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
	for _, tooltip in pairs(tooltipsToHook) do
		if tooltip then
			tooltip:HookScript("OnTooltipSetItem", function(tooltip)
				Skillet:AddItemNotesToTooltip(tooltip)
			end)
		end
	end
--
-- configure the addon options and the slash command handler
-- (Skillet.options is defined in SkilletOptions.lua)
--
	Skillet:ConfigureOptions()
--
-- Copy the profile debugging variables to the global table 
-- where DebugAids.lua is looking for them.
--
-- Warning:	Setting TableDump can be a performance hog, use caution.
--			Setting DebugLogging (without DebugShow) is a minor performance hit.
--			WarnLog (with or without WarnShow) can remain on as warning messages are rare.
--
-- Note:	Undefined is the same as false so we only need to predefine true variables
--
	if Skillet.db.profile.WarnLog == nil then
		Skillet.db.profile.WarnLog = true
	end

	Skillet.WarnLog = Skillet.db.profile.WarnLog
	Skillet.WarnShow = Skillet.db.profile.WarnShow
	Skillet.DebugShow = Skillet.db.profile.DebugShow
	Skillet.DebugLogging = Skillet.db.profile.DebugLogging
	Skillet.DebugLevel = Skillet.db.profile.DebugLevel
	Skillet.LogLevel = Skillet.db.profile.LogLevel
	Skillet.MAXDEBUG = Skillet.db.profile.MAXDEBUG or 4000
	Skillet.MAXPROFILE = Skillet.db.profile.MAXPROFILE or 2000
	Skillet.TableDump = Skillet.db.profile.TableDump
	Skillet.TraceShow = Skillet.db.profile.TraceShow
	Skillet.TraceLog = Skillet.db.profile.TraceLog
	Skillet.ProfileShow = Skillet.db.profile.ProfileShow
--
-- Profile variable to control Skillet fixes for Blizzard bugs.
-- Can be toggled [or turned off] with "/skillet fixbugs [off]"
--
	if Skillet.db.profile.FixBugs == nil then
		Skillet.db.profile.FixBugs = true
	end
	Skillet.FixBugs = Skillet.db.profile.FixBugs

--
-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
--
	if Skillet.FixBugs then
		Skillet:FixOpenToCategory()
	end

--
-- Create static popups for changing professions
--
StaticPopupDialogs["SKILLET_CONTINUE_CHANGE"] = {
	text = "Skillet-Classic\n"..L["Press Okay to continue changing professions"],
	button1 = OKAY,
	OnAccept = function( self )
		Skillet:ContinueChange()
		return
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["SKILLET_MANUAL_CHANGE"] = {
	text = "Skillet\n"..L["Press your button which opens %s"],
--	button1 = OKAY,
--	OnAccept = function( self )
--		Skillet:ContinueChange(true)
--		return
--	end,
	OnCancel = function( self )
		Skillet:FinishChange()
		return
	end,
	OnHide = function( self )
		Skillet:FinishChange()
		return
	end,
	timeout = 30,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

--
-- Create our frame
--
	if not Skillet.tradeSkillFrame then
		Skillet.tradeSkillFrame = Skillet:CreateTradeSkillWindow()
		tinsert(UISpecialFrames, Skillet.tradeSkillFrame:GetName())
	end

--
-- Now do the character initialization
--
	self:InitializeDatabase(UnitName("player"))
end

--
-- These functions reset parts of the database primarily
-- when code changes obsolete the current database.
--
-- FlushAllData covers everything and (hopefully) is
-- rarely used. There is a dataVersion number to
-- increment to trigger a call.
--
function Skillet:FlushAllData()
	Skillet.data = {}
	Skillet.db.realm.tradeSkills = {}
	Skillet.db.realm.auctionData = {}
	Skillet.db.realm.inventoryData = {}
	Skillet.db.realm.bagData = {}
	Skillet.db.realm.bagDetails = {}
	Skillet.db.realm.bankData = {}
	Skillet.db.realm.bankDetails = {}
	Skillet.db.realm.userIgnoredMats = {}
	Skillet:FlushCustomData()
	Skillet:FlushQueueData()
	Skillet:FlushRecipeData()
	Skillet:InitializeMissingVendorItems()
end

--
-- Custom Groups data could represent significant
-- effort by the player so don't clear it without
-- good cause.
--
function Skillet:FlushCustomData()
	Skillet.db.realm.groupDB = {}
end

--
-- Saved queues are in the profile so
-- clearing these tables is just the current
-- queue and should have minimal impact.
--
function Skillet:FlushQueueData()
	Skillet.db.realm.queueData = {}
	Skillet.db.realm.reagentsInQueue = {}
end

--
-- Recipe data is constantly getting rebuilt so
-- clearing it should have minimal (if any) impact.
-- Blizzard's "stealth" changes to recipes are the
-- primary reason this function exists.
--
function Skillet:FlushRecipeData()
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.recipeNameDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.global.Categories = {}
	Skillet.db.global.spellIDtoName = {}
	if Skillet.data and Skillet.data.recipeInfo then
		Skillet.data.recipeInfo = {}
	end
end

--
-- MissingVendorItem entries can be a string when bought with gold
-- or a table when bought with an alternate currency
-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
--
function Skillet:InitializeMissingVendorItems()
	self.db.global.MissingVendorItems = {
		[30817] = "Simple Flour",
		[4539]  = "Goldenbark Apple",
		[17035] = "Stranglethorn Seed",
		[17034] = "Maple Seed",
		[4399]	= "Wooden Stock",
		[3857]	= "Coal",
		[52188] = "Jeweler's Setting",
		[38682] = "Enchanting Vellum",
	}
end

function Skillet:InitializeDatabase(player)
	DA.DEBUG(0,"Initialize database for "..tostring(player))
	if self.linkedSkill or self.isGuild then  -- Avoid adding unnecessary data to savedvariables
		return
	end
	if not self.data then
		self.data = {}
	end
	if not self.data.recipeInfo then
		self.data.recipeInfo = {}
	end
	if not self.data.recipeList then
		self.data.recipeList = {}
	end
	if not self.data.skillList then
		self.data.skillList = {}
	end
	if not self.data.groupList then
		self.data.groupList = {}
	end
	if not self.data.skillIndexLookup then
		self.data.skillIndexLookup = {}
	end
	if player then
		if not self.db.realm.groupDB then
			self.db.realm.groupDB = {}
		end
		if not self.db.realm.queueData then
			self.db.realm.queueData = {}
		end
		if not self.db.realm.queueData[player] then
			self.db.realm.queueData[player] = {}
		end
		if not self.db.realm.auctionData then
			self.db.realm.auctionData = {}
		end
		if not self.db.realm.auctionData[player] then
			self.db.realm.auctionData[player] = {}
		end
		if not self.db.realm.tradeSkills then
			self.db.realm.tradeSkills = {}
		end
		if not self.db.realm.faction then
			self.db.realm.faction = {}
		end
		if not self.db.realm.guid then
			self.db.realm.guid = {}
		end
		if not self.db.global.faction then
			self.db.global.faction = {}
		end
		if not self.db.global.server then
			self.db.global.server = {}
		end
		if player == UnitName("player") then
			if not self.db.realm.inventoryData then
				self.db.realm.inventoryData = {}
			end
			if not self.db.realm.inventoryData[player] then
				self.db.realm.inventoryData[player] = {}
			end
--
-- For debugging, having the contents of bags could be useful.
--
			if not self.db.realm.bagData then
				self.db.realm.bagData = {}
			end
			if not self.db.realm.bagData[player] then
				self.db.realm.bagData[player] = {}
			end
			if not self.db.realm.bagDetails then
				self.db.realm.bagDetails = {}
			end
			if not self.db.realm.bagDetails[player] then
				self.db.realm.bagDetails[player] = {}
			end
--
-- For debugging, having the contents of the bank could be useful.
--
			if not self.db.realm.bankData then
				self.db.realm.bankData = {}
			end
			if not self.db.realm.bankData[player] then
				self.db.realm.bankData[player] = {}
			end
			if not self.db.realm.bankDetails then
				self.db.realm.bankDetails = {}
			end
			if not self.db.realm.bankDetails[player] then
				self.db.realm.bankDetails[player] = {}
			end

			if not self.db.realm.reagentsInQueue then
				self.db.realm.reagentsInQueue = {}
			end
			if not self.db.realm.reagentsInQueue[player] then
				self.db.realm.reagentsInQueue[player] = {}
			end
			if not self.db.realm.userIgnoredMats then
				self.db.realm.userIgnoredMats = {}
			end
			if not self.db.realm.userIgnoredMats[player] then
				self.db.realm.userIgnoredMats[player] = {}
			end
			if not self.db.profile.SavedQueues then
				self.db.profile.SavedQueues = {}
			end
			if not self.db.profile.plugins then
				self.db.profile.plugins = {}
			end
			if self.db.profile.plugins.recipeNamePlugin then
				if not self.db.profile.plugins.recipeNameSuffix then
					self.db.profile.plugins.recipeNameSuffix = self.db.profile.plugins.recipeNamePlugin
				end
				self.db.profile.plugins.recipeNamePlugin = nil
			end
			Skillet:InitializePlugins()
		end
	end
end

function Skillet:RegisterRecipeFilter(name, namespace, initMethod, filterMethod)
	if not self.recipeFilters then
		self.recipeFilters = {}
	end
	--DA.DEBUG(0,"add recipe filter "..name)
	self.recipeFilters[name] = { namespace = namespace, initMethod = initMethod, filterMethod = filterMethod }
end

-- Called when the addon is enabled
function Skillet:OnEnable()
	DA.DEBUG(0,"OnEnable()");
--
-- Hook into the events that we care about
--
-- Trade skill window changes
--
	self:RegisterEvent("TRADE_SKILL_CLOSE")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_NAME_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGING")
	self:RegisterEvent("TRADE_SKILL_DETAILS_UPDATE")
--	self:RegisterEvent("TRADE_SKILL_FILTER_UPDATE")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS", "SkilletShowGuildCrafters")
	self:RegisterEvent("GARRISON_TRADESKILL_NPC_CLOSED")
	self:RegisterEvent("BAG_UPDATE") -- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED") -- Fires after all applicable BAG_UPADTE events for a specific action have been fired.
--
-- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
--
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")
--
-- To show a shopping list when at the bank/guildbank/auction house
--
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANK_UPDATE_TEXT")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
--
-- Events needed to process the queue and to update
-- the tradeskill window to update the number of items
-- that can be crafted as we consume reagents.
--
--	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--
-- Not sure these are needed for crafting but they
-- are useful for debugging.
--
--	self:RegisterEvent("UNIT_SPELLCAST_SENT")
--	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
--	self:RegisterEvent("UNIT_SPELLCAST_STOP")
--	self:RegisterEvent("CHAT_MSG_SKILL")
	self:RegisterEvent("SKILL_LINES_CHANGED") -- replacement for CHAT_MSG_SKILL?
	self:RegisterEvent("LEARNED_SPELL_IN_TAB") -- arg1 = professionID
	self:RegisterEvent("NEW_RECIPE_LEARNED") -- arg1 = recipeID
--	self:RegisterEvent("SPELL_NAME_UPDATE") -- arg1 = spellID, arg2 = spellName
--
-- Debugging cleanup if enabled
--
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.hideUncraftableRecipes = false
	self.hideTrivialRecipes = false
	self.currentTrade = nil
	self.selectedSkill = nil
	self.currentPlayer = UnitName("player")
	self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil
	self.dataScanned = false
--
-- run the upgrade code to convert any old settings
--

	self:UpgradeDataAndOptions()
	self:CollectTradeSkillData()
	self:CollectCurrencyData()
	self:EnablePlugins()
end

function Skillet:PLAYER_LOGIN()
	DA.TRACE("PLAYER_LOGIN")
end

function Skillet:PLAYER_ENTERING_WORLD()
	DA.TRACE("PLAYER_ENTERING_WORLD")
	local player, realm = UnitFullName("player")
	local faction = UnitFactionGroup("player")
	local guid = UnitGUID("player") or ""	-- example: guid="Player-970-0002FD64" kind=="Player" server=="970" ID="0002FD64" 
	local kind, server, ID = strsplit("-", guid)
	DA.DEBUG(1,"player="..tostring(player)..", faction="..tostring(faction)..", guid="..tostring(guid)..", server="..tostring(server))
	self.db.realm.guid[player]= guid
	self.db.realm.faction[player] = faction
	if (server) then
		self.data.server = server
		self.data.realm = realm
		if not self.db.global.server[server] then
			self.db.global.server[server] = {}
		end
		self.db.global.server[server][realm] = player
		if not self.db.global.faction[server] then
			self.db.global.faction[server] = {}
		end
		self.db.global.faction[server][player] = faction
	end
end

function Skillet:PLAYER_LOGOUT()
	DA.TRACE("PLAYER_LOGOUT")
--
-- Make a copy of the in memory data for debugging. Note: DeepCopy.lua needs to be added to the .toc
--
	if DA.deepcopy then
		self.data.sortedSkillList = {"Removed"} -- This table is huge so don't save it unless needed.
--		SkilletMemory = DA.deepcopy(self.data)	-- Everything else
--
-- For RecipeGroups debugging:
--
		local tradeID, rest
		for tradeID in pairs(self.db.realm.tradeSkills[self.currentPlayer]) do
			DA.DEBUG(0,"tradeID= "..tostring(tradeID))
			if self.data.groupList[self.currentPlayer][tradeID] then
				self.data.groupList[self.currentPlayer][tradeID]["Blizzard"] = {"Removed"}
			end
		end
		SkilletMemory = DA.deepcopy(self.data.groupList) -- minus all the group "Blizzard" stuff
	end
end

function Skillet:CHAT_MSG_SKILL()	-- Replaced by SKILL_LINES_CHANGED?
	DA.TRACE("CHAT_MSG_SKILL")
	if Skillet.tradeSkillOpen then
		Skillet:RescanTrade()
		Skillet:UpdateTradeSkillWindow()
	end
end

function Skillet:SKILL_LINES_CHANGED()
	DA.TRACE("SKILL_LINES_CHANGED")
	if Skillet.tradeSkillOpen then
--		Skillet:RescanTrade()
--		Skillet:UpdateTradeSkillWindow()
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function Skillet:LEARNED_SPELL_IN_TAB(event, profession)
	DA.TRACE("LEARNED_SPELL_IN_TAB")
	DA.TRACE("profession= "..tostring(profession))
	if Skillet.tradeSkillOpen then
		Skillet:RescanTrade()				-- Untested
		Skillet:UpdateTradeSkillWindow()	-- Untested
	end
end

function Skillet:NEW_RECIPE_LEARNED(event, recipeID)
	DA.TRACE("NEW_RECIPE_LEARNED")
	DA.TRACE("recipeID= "..tostring(recipeID))
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function Skillet:SPELL_NAME_UPDATE(event, spellID, spellName)
	DA.TRACE("SPELL_NAME_UPDATE")
	DA.TRACE("spellID= "..tostring(spellID)..", spellName= "..tostring(spellName))
	Skillet.db.global.spellIDtoName[spellID] = spellName
end

function Skillet:GetSpellName(spellID)
	DA.DEBUG(0,"GetSpellName")
	DA.DEBUG(0,"spellID= "..tostring(spellID)..", spellName= "..tostring(spellName))
	if Skillet.db.global.spellIDtoName[spellID] then
		return Skillet.db.global.spellIDtoName[spellID]
	else
		GetSpellInfo(spellID)	-- Name will be returned asynchronously 
		return "Unknown"
	end
end

function Skillet:TRADE_SKILL_SHOW()
	DA.TRACE("TRADE_SKILL_SHOW")
	Skillet.dataSourceChanged = false
	Skillet.detailsUpdate = false
	Skillet.skillListUpdate = false
	Skillet.adjustInventory = false
	Skillet:SkilletShow()
end

function Skillet:TRADE_SKILL_CLOSE()
	DA.TRACE("TRADE_SKILL_CLOSE")
	Skillet:SkilletClose()
	Skillet.dataSourceChanged = false
	Skillet.detailsUpdate = false
	Skillet.skillListUpdate = false
	Skillet.adjustInventory = false
end

function Skillet:TRADE_SKILL_DATA_SOURCE_CHANGED()
	DA.TRACE("TRADE_SKILL_DATA_SOURCE_CHANGED")
	DA.TRACE("tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true
		Skillet:SkilletShowWindow()
		if Skillet.delaySelectedSkill then
			self:SetSelectedSkill(Skillet.delaySkillIndex)
			Skillet.delaySelectedSkill = false
		end
	end
end

function Skillet:TRADE_SKILL_DATA_SOURCE_CHANGING()
	DA.TRACE("TRADE_SKILL_DATA_SOURCE_CHANGING")
	DA.TRACE("tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	if Skillet.tradeSkillOpen then
		Skillet:SkilletShow()
	end
end

function Skillet:TRADE_SKILL_DETAILS_UPDATE()
	DA.TRACE("TRADE_SKILL_DETAILS_UPDATE")
	DA.TRACE("tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	if Skillet.tradeSkillOpen then
		Skillet.detailsUpdate = true
		Skillet:RescanTrade()
		Skillet:UpdateTradeSkillWindow()
	end
end

function Skillet:TRADE_SKILL_FILTER_UPDATE()
	DA.TRACE("TRADE_SKILL_FILTER_UPDATE")
end

function Skillet:TRADE_SKILL_LIST_UPDATE()
	DA.TRACE("TRADE_SKILL_LIST_UPDATE")
	--DA.TRACE("tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	--DA.TRACE("dataSourceChanged= "..tostring(Skillet.dataSourceChanged))
	--DA.TRACE("adjustInventory= "..tostring(Skillet.adjustInventory))
	if Skillet.tradeSkillOpen and Skillet.dataSourceChanged then
		Skillet.dataSourceChanged = false
		Skillet.adjustInventory = false
		Skillet.skillListUpdate = true
		Skillet:SkilletShowWindow()
	end
	if Skillet.tradeSkillOpen and Skillet.adjustInventory then
		Skillet.skillListUpdate = true
		Skillet:AdjustInventory()
	end
end

function Skillet:TRADE_SKILL_NAME_UPDATE()
	DA.TRACE("TRADE_SKILL_NAME_UPDATE")
	DA.TRACE("linkedSkill= "..tostring(Skillet.linkedSkill))
	if Skillet.linkedSkill then
		Skillet:SkilletShow()
	end
end

function Skillet:GARRISON_TRADESKILL_NPC_CLOSED()
	DA.TRACE("GARRISON_TRADESKILL_NPC_CLOSED")
end

--
-- Called when the addon is disabled
--
function Skillet:OnDisable()
	DA.DEBUG(0,"Skillet:OnDisable()");
	self:UnregisterAllEvents()
	self:EnableBlizzardFrame()
end

function Skillet:IsTradeSkillLinked()
	local isGuild = C_TradeSkillUI.IsTradeSkillGuild()
	local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
	DA.DEBUG(0,"IsTradeSkillLinked: isGuild="..tostring(isGuild)..", isLinked="..tostring(isLinked)..", linkedPlayer="..tostring(linkedPlayer))
	if isLinked or isGuild then
		if not linkedPlayer then
			if isGuild then
				linkedPlayer = "Guild Recipes" -- This can be removed when InitializeDatabase gets smarter.
			end
		end
		return true, linkedPlayer, isGuild
	end
	return false, nil, false
end

--
-- Show the tradeskill window, called from TRADE_SKILL_SHOW event, clicking on links, or clicking on guild professions
--
function Skillet:SkilletShow()
	DA.DEBUG(0,"SkilletShow: (was showing "..tostring(self.currentTrade)..")");
	self.linkedSkill, self.currentPlayer, self.isGuild = self:IsTradeSkillLinked()
	StaticPopup_Hide("SKILLET_MANUAL_CHANGE")
	if self.linkedSkill then
		if not self.currentPlayer then
			return -- Wait for TRADE_SKILL_NAME_UPDATE
		end
	else
		self.currentPlayer = (UnitName("player"))
	end
	local frame = self.tradeSkillFrame
	if not frame then
		frame = self:CreateTradeSkillWindow()
		self.tradeSkillFrame = frame
		tinsert(UISpecialFrames, frame:GetName())
	end
	self:ScanPlayerTradeSkills(self.currentPlayer)
	local skillLineID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier, parentSkillLineID, parentSkillLineName =
		C_TradeSkillUI.GetTradeSkillLine()
	DA.DEBUG(0,"SkilletShow: skillLineID= "..tostring(skillLineID)..", skillLineName= "..tostring(skillLineName)..
		", skillLineRank= "..tostring(skillLineRank)..", skillLineMaxRank= "..tostring(skillLineMaxRank)..
		", skillLineModifier= "..tostring(skillLineModifier)..
		", parentSkillLineID= "..tostring(parentSkillLineID)..", parentSkillLineName= "..tostring(parentSkillLineName))
	if (parentSkillLineID) then
		self.currentTrade = self.SkillLineIDList[parentSkillLineID]	-- names are localized so use a table to translate
	else
		self.currentTrade = self.SkillLineIDList[skillLineID]		-- names are localized so use a table to translate
	end
	DA.DEBUG(0,"SkilletShow: trade= "..tostring(self.currentTrade))
	local link = C_TradeSkillUI.GetTradeSkillListLink()
	if not link then
		DA.DEBUG(0,"SkilletShow: "..tostring(skillLineName).." not linkable")
	end
	-- Use the Blizzard UI for any garrison follower that can't use ours.
	if self:IsNotSupportedFollower(self.currentTrade) then
		DA.DEBUG(3,"SkilletShow: "..tostring(self.currentTrade).." IsNotSupportedFollower")
		self:HideAllWindows()
		self:EnableBlizzardFrame()
		ShowUIPanel(TradeSkillFrame)
	elseif self:IsSupportedTradeskill(self.currentTrade) then
		DA.DEBUG(3,"SkilletShow: "..tostring(self.currentTrade).." IsSupportedTradeskill")
		self:DisableBlizzardFrame()
		self.tradeSkillOpen = true
		self.selectedSkill = nil
		self.dataScanned = false
		self:SetTradeSkillLearned()
		DA.DEBUG(3,"SkilletShow: waiting for TRADE_SKILL_DATA_SOURCE_CHANGED")
--		self:SkilletShowWindow() -- Need to wait until TRADE_SKILL_DATA_SOURCE_CHANGED
	else
		DA.DEBUG(3,"SkilletShow: "..tostring(self.currentTrade).." not IsSupportedTradeskill")
		self:HideAllWindows()
		self:EnableBlizzardFrame()
		ShowUIPanel(TradeSkillFrame)
	end
end

--
-- Only called from SkilletShow() after a short delay
--
function Skillet:SkilletShowWindow()
	DA.DEBUG(0,"SkilletShowWindow: "..tostring(self.currentTrade))
	if self.tradeSkillOpen then
		HideUIPanel(TradeSkillFrame)
	end
--	if not self.currentPlayer or not self.currentTrade then
--		return
--	end
	if not self:RescanTrade() then
		if self.useBlizzard then
			self.useBlizzard = false
			return
		end
		DA.DEBUG(0,"No headers, reset filter")
		self.ResetTradeSkillFilter()
		if not self:RescanTrade() then
			if TSMAPI_FOUR then
				DA.CHAT(L["Conflict with the addon TradeSkillMaster"])
				self.db.profile.TSMAPI_FOUR = true
			else
				DA.CHAT(L["No headers, try again"])
			end
			return
		end
	end
	self.currentGroup = nil
	self.currentGroupLabel = self:GetTradeSkillOption("grouping")
	self:RecipeGroupDropdown_OnShow()
	self:ShowTradeSkillWindow()
	local searchbox = _G["SkilletSearchBox"]
	local oldtext = searchbox:GetText()
	local searchText = self:GetTradeSkillOption("searchtext")
--
-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
--
	if searchText ~= oldtext then
		searchbox:SetText(searchText)
	end
end

function Skillet:SkilletClose()
	DA.DEBUG(0,"SKILLET CLOSE")
	self.tradeSkillOpen = false
	self:HideAllWindows()
	if Skillet.wasNPCCrafting then
		DA.DEBUG(0,"wasNPCCrafting")
		C_Garrison.CloseGarrisonTradeskillNPC()
		C_Garrison.CloseTradeskillCrafter()
	end
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill window is open and a trade selected.
function Skillet:RescanBags()
	DA.DEBUG(0,"RescanBags()")
	local start = GetTime()
	Skillet:InventoryScan()
	Skillet:UpdateTradeSkillWindow()
	local elapsed = GetTime() - start
	if elapsed > 0.5 then
		DA.DEBUG(0,"WARNING: skillet inventory scan took " .. math.floor(elapsed*100+.5)/100 .. " seconds to complete.")
	end
end

function Skillet:BAG_OPEN(event, bagID) -- Fires when a non-inventory container is opened.
	DA.TRACE("BAG_OPEN( "..tostring(bagID).." )") -- We don't really care
end

--
-- So we can track when the players inventory changes and update craftable counts
--
function Skillet:BAG_UPDATE(event, bagID)
	DA.TRACE("BAG_UPDATE( "..bagID.." )")
	local showing = false
	if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
		showing = true
	end
	if self.shoppingList and self.shoppingList:IsVisible() then
		showing = true
	end
--	bagID = tonumber(bagID)
	if showing then
		if bagID >= 0 and bagID <= 4 then
--
-- an inventory bag update, do nothing (wait for the BAG_UPDATE_DELAYED).
--
		end
		if bagID == -1 or bagID >= 5 then
--
-- a bank update, process it in ShoppingList.lua
--
			Skillet:BANK_UPDATE(event,bagID) -- Looks like an event but its not.
		end
	end
	if MerchantFrame and MerchantFrame:IsVisible() then
		-- may need to update the button on the merchant frame window ...
		self:UpdateMerchantFrame()
	end
	-- Most of the shoppingList code is in ShoppingList.lua
	if self.shoppingList and self.shoppingList:IsVisible() then
		self:InventoryScan()
		self:UpdateShoppingListWindow()
	end
end

function Skillet:BAG_CLOSED(event, bagID)        -- Fires when the whole bag is removed from
	DA.TRACE("BAG_CLOSED( "..tostring(bagID).." )") -- inventory or bank. We don't really care.
end

--
-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
--
function Skillet:TRADE_CLOSED()
	self:BAG_UPDATE("FAKE_BAG_UPDATE", 0)
end

--
-- Make sure profession changes are spaced out
--   delayChange is set when ChangeTradeSkill is called
--     and cleared here when the timer expires.
--
function Skillet:DelayChange()
	DA.DEBUG(0,"DelayChange()")
	Skillet.delayChange = false
	if Skillet.delayNeeded then
		Skillet.delayNeeded = false
		Skillet:ChangeTradeSkill(Skillet.delayTrade, Skillet.changingName)
	end
end

--
-- Change to a different profession but
-- not more often than once every .5 seconds
-- If called too quickly, delayNeeded is set and
--   the change is deferred until DelayChange is called.
--
function Skillet:ChangeTradeSkill(tradeID, tradeName)
	DA.DEBUG(0,"ChangeTradeSkill("..tostring(tradeID)..", "..tostring(tradeName)..")")
	if not self.delayChange then
		if self.db.profile.dialog_switch and not self.dialogSwitch then
			self:HideAllWindows()
			C_TradeSkillUI.CloseTradeSkill()
			self.changingTrade = tradeID
			self.changingName = self.tradeSkillNamesByID[tradeID]
			self.dialogSwitch = true
			if tradeName == "Mining" then tradeName = "Mining Skills" end
			DA.DEBUG(0,"ChangeTradeSkill: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName))
			StaticPopup_Show("SKILLET_MANUAL_CHANGE", self.changingName)
		else
			if tradeName == "Mining" then tradeName = "Mining Skills" end
			DA.DEBUG(1,"ChangeTradeSkill: executing CastSpellByName("..tostring(tradeName)..")")
			CastSpellByName(tradeName) -- trigger the whole rescan process via a TRADE_SKILL_SHOW event
			self.delayTrade = tradeID
			self.delayName = tradeName
			self.delayChange = true
			self.dialogSwitch = false
			Skillet:ScheduleTimer("DelayChange", 0.5)
		end
	else
		DA.DEBUG(1,"ChangeTradeSkill: waiting for callback")
		Skillet.delayNeeded = true
	end
end

--
-- Called from the static popups to change professions
--   changingTrade and changingName should be set to
--   the target profession.
--
function Skillet:ContinueChange(manual)
	DA.DEBUG(0,"ContinueChange("..tostring(manual)..")")
	DA.DEBUG(1,"ContinueChange: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName))
	if not manual then
		self.currentTrade = Skillet.changingTrade
		Skillet:ChangeTradeSkill(Skillet.changingTrade, Skillet.changingName)
	end
end

--
-- Called from the static popup when hidden or canceled
--
function Skillet:FinishChange()
	DA.DEBUG(0,"FinishChange()")
	self.changingTrade = nil
	self.changingName = nil
	self.dialogSwitch = nil
end

--
-- Either change to a different profession or change the currently selected recipe
--
function Skillet:SetTradeSkill(player, tradeID, skillIndex)
	DA.DEBUG(0,"SetTradeSkill("..tostring(player)..", "..tostring(tradeID)..", "..tostring(skillIndex)..")")
	if not self.db.realm.queueData[player] then
		self.db.realm.queueData[player] = {}
	end
	if tradeID ~= self.currentTrade then
		local oldTradeID = self.currentTrade
		local tradeName = self:GetTradeName(tradeID)
		self.currentPlayer = player
		self.currentTrade = nil
		self.selectedSkill = nil
		self.currentGroup = nil
		self:ChangeTradeSkill(tradeID, tradeName)
		self.delaySelectedSkill = true
		self.delaySkillIndex = skillIndex
		self.dataScanned = false
	end
	if not self.delaySelectedSkill then
		self:SetSelectedSkill(skillIndex)
	end
end

--
-- Shows the trade skill frame.
--
function Skillet:ShowTradeSkillWindow()
	--DA.DEBUG(0,"ShowTradeSkillWindow()")
	if UnitAffectingCombat("player") then
		print("|cff8888ffSkillet|r: Combat lockdown restriction." ..
		  " Leave combat and try again.")
		self.dataSourceChanged = false
		self.detailsUpdate = false
		self.skillListUpdate = false
		self.adjustInventory = false
		self:SkilletClose()
		return
	end
	local frame = self.tradeSkillFrame
	if not frame then
		frame = self:CreateTradeSkillWindow()
		self.tradeSkillFrame = frame
		tinsert(UISpecialFrames, frame:GetName())
	end
	self:ResetTradeSkillWindow()
	Skillet:ShowFullView()
	if not frame:IsVisible() then
		frame:Show()
	end
	self:UpdateTradeSkillWindow()
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:HideTradeSkillWindow()
	local closed -- was anything closed by us?
	local frame = self.tradeSkillFrame
	if frame and frame:IsVisible() then
		frame:Hide()
		closed = true
	end
	return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:HideAllWindows()
	local closed -- was anything closed?
	-- Cancel anything currently being created
	if self:HideTradeSkillWindow() then
		closed = true
	end
	if self:HideNotesWindow() then
		closed = true
	end
	if self:HideShoppingList() then
		closed = true
	end
	if self:HideStandaloneQueue() then
		closed = true
	end
	self.currentTrade = nil
	self.selectedSkill = nil
	return closed
end

--
-- Show the options window
--
function Skillet:ShowOptions()
	InterfaceOptionsFrame_Show()
	InterfaceOptionsFrame_OpenToCategory("Skillet")
end

--
-- Notes when a new trade has been selected
--
function Skillet:SetSelectedTrade(newTrade)
	DA.DEBUG(0,"SetSelectedTrade("..tostring(newTrade)..")")
	self.currentTrade = newTrade;
	self:SetSelectedSkill(nil)
end

--
-- Sets the specific trade skill that the user wants to see details on.
--
function Skillet:SetSelectedSkill(skillIndex)
	--DA.DEBUG(0,"SetSelectedSkill("..tostring(skillIndex)..")")
	self:HideNotesWindow()
	self:ConfigureRecipeControls(false)
	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
	self:ClickSkillButton(skillIndex)
end

--
-- Updates the text we filter the list of recipes against.
--
function Skillet:UpdateSearch(text)
	DA.DEBUG(0,"UpdateSearch("..tostring(text)..")")
	self:SetTradeSkillOption("searchtext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

--
-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
--
function Skillet:GetItemNote(key)
	--DA.DEBUG(0,"GetItemNote("..tostring(key)..")")
	local result
	if not self.db.realm.notes[self.currentPlayer] then
		return
	end
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- get the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"GetItemNote itemID="..tostring(id))
	if id then
		result = self.db.realm.notes[self.currentPlayer][id]
	else
		self:Print("Error: Skillet:GetItemNote() could not determine item ID for " .. key);
	end
	if result and result == "" then
		result = nil
		self.db.realm.notes[self.currentPlayer][id] = nil
	end
	return result
end

--
-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
--
function Skillet:SetItemNote(key, note)
	--DA.DEBUG(0,"SetItemNote("..tostring(key)..", "..tostring(note)..")")
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- store the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"SetItemNote itemID="..tostring(id))
	if not self.db.realm.notes[self.currentPlayer] then
		self.db.realm.notes[self.currentPlayer] = {}
	end
	if id then
		self.db.realm.notes[self.currentPlayer][id] = note
	else
		self:Print("Error: Skillet:SetItemNote() could not determine item ID for " .. key);
	end
end

--
-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
--
function Skillet:AddItemNotesToTooltip(tooltip)
	--DA.DEBUG(0,"AddItemNotesToTooltip()")
	if IsControlKeyDown() then
		return
	end
	local notes_enabled = self.db.profile.show_item_notes_tooltip or false
	local crafters_enabled = self.db.profile.show_crafters_tooltip or false
	if not notes_enabled and not crafters_enabled then
		return -- nothing to be added to the tooltip
	end
--
-- get item name
--
	local name,link = tooltip:GetItem();
	if not link then
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine link")
		return;
	end
	local id = self:GetItemIDFromLink(link)
	if not id then
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine id from "..DA.PLINK(link))
		return
	end
	--DA.DEBUG(0,"link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
	local header_added = false
	if notes_enabled then
		for player,notes_table in pairs(self.db.realm.notes) do
			local note = notes_table[id]
			--DA.DEBUG(1,"player= "..tostring(player)..", table= "..DA.DUMP1(notes_table)..", note= '"..tostring(note).."'")
			if note then
				if not header_added then
					tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
					header_added = true
				end
				if player ~= UnitName("player") then
					note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
				end
				tooltip:AddLine(" " .. note, 1, 1, 1, true) -- r,g,b, wrap
			end
		end
		if self:VendorSellsReagent(id) then
			if not header_added then
				tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
				header_added = true
			end
			tooltip:AddLine(" Buyable")
		end
	end	-- notes_enabled
	if crafters_enabled then
		if self.db.global.itemRecipeSource[id] then
			if not header_added then
				tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
				header_added = true
			end
			tooltip:AddLine(" Craftable")
			for recipeID in pairs(self.db.global.itemRecipeSource[id]) do
				local recipe = self:GetRecipe(recipeID)
				tooltip:AddDoubleLine(" Source: ",(self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..self:GetRecipeName(recipeID),0,1,0,1,1,1)
				local lookupTable = self.data.skillIndexLookup
				local player = self.currentPlayer
				if lookupTable[recipeID] then
					local rankData = self:GetSkillRanks(player, recipe.tradeID)
					if rankData then
						local rank, maxRank = rankData.rank, rankData.maxRank
						tooltip:AddDoubleLine("  "..player,"["..(rank or "?").."/"..(maxRank or "?").."]",1,1,1)
					else
						tooltip:AddDoubleLine("  "..player,"[???/???]",1,1,1)
					end
				end
			end
		end
		if self.db.realm.reagentsInQueue[self.currentPlayer] then
			local inQueue = self.db.realm.reagentsInQueue[self.currentPlayer][id]
			if inQueue then
				if not header_added then
					tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
					header_added = true
				end
				if inQueue < 0 then
					tooltip:AddDoubleLine(" Used in queued skills:",-inQueue,1,1,1)
				else
					tooltip:AddDoubleLine(" Created from queued skills:",inQueue,1,1,1)
				end
			end
		end
	end	-- crafters_enabled
	return header_added
end

function Skillet:ToggleTradeSkillOption(option)
	local v = self:GetTradeSkillOption(option)
	self:SetTradeSkillOption(option, not v)
end

--
-- Returns the state of a craft specific option
--
function Skillet:GetTradeSkillOption(option)
	local r
	local player = self.currentPlayer
	local trade = self.currentTrade
	local options = self.db.realm.options
	if not options or not player or not options[player] or not trade or not options[player][trade] then
		r = Skillet.defaultOptions[option]
	elseif options[player][trade][option] == nil then
		r =  Skillet.defaultOptions[option]
	else
		r = options[player][trade][option]
	end
	return r
end

--
-- sets the state of a craft specific option
--
function Skillet:SetTradeSkillOption(option, value)
	if not self.linkedSkill and not self.isGuild then
		local player = self.currentPlayer
		local trade = self.currentTrade
		if not self.db.realm.options then
			self.db.realm.options = {}
		end
		if player and trade then
			if not self.db.realm.options[player] then
				self.db.realm.options[player] = {}
			end
			if not self.db.realm.options[player][trade] then
				self.db.realm.options[player][trade] = {}
			end
			self.db.realm.options[player][trade][option] = value
		end
	end
end

function Skillet:IsActive()
	return Skillet:IsEnabled()
end
