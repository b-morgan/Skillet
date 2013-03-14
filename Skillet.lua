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

local MAJOR_VERSION = "2.43"
local MINOR_VERSION = ("$Revision$"):match("%d+") or 1
local DATE = string.gsub("$Date$", "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

Skillet = LibStub("AceAddon-3.0"):NewAddon("Skillet", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
Skillet.title   = "Skillet"
Skillet.version = MAJOR_VERSION .. "-" .. MINOR_VERSION .. "LS"
Skillet.date    = DATE
local AceDB = LibStub("AceDB-3.0")

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

local defaults = {
	profile = {
	    -- user configurable options
	    vendor_buy_button = true,
	    vendor_auto_buy   = false,
	    show_item_notes_tooltip = false,
	    show_crafters_tooltip = true,
	    show_detailed_recipe_tooltip = true,        -- show any tooltips?
	    display_full_tooltip = true,		         -- show full blizzards tooltip
		display_item_tooltip = true,                    -- show item tooltip or recipe tooltip
	    link_craftable_reagents = true,
	    queue_craftable_reagents = true,
	    queue_glyph_reagents = false,
	    display_required_level = false,
	    display_shopping_list_at_bank = false,
	    display_shopping_list_at_guildbank = false,
	    display_shopping_list_at_auction = false,
	    transparency = 1.0,
	    scale = 1.0,
	    plugins = {},
		SavedQueues = {},
	},
	realm = {
	    -- notes added to items crafted or used in crafting.
	    notes = {},
	},
	char = {
	    -- options specific to a current tradeskill
	    tradeskill_options = {},
	    -- Display alt's items in shopping list
	    include_alts = true,
	},
}

-- default options for each player/tradeskill

Skillet.defaultOptions = {
	["sortmethod"] = "None",
	["grouping"] = "Blizzard",
	["filtertext"] = "",
	["filterInventory-bag"] = true,
	["filterInventory-vendor"] = true,
	["filterInventory-bank"] = true,
	["filterInventory-alts"] = false,
	["filterLevel"] = 1,
	["hideuncraftable"] = false,
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
}


function DebugSpam(message)
--	DEFAULT_CHAT_FRAME:AddMessage(message)
end

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
Skillet.L = L

-- All the options that we allow the user to control.
local Skillet = Skillet
Skillet.options =
{
	handler = Skillet,
	type = 'group',
	args = {
		features = {
			type = 'group',
			name = L["Features"],
			desc = L["FEATURESDESC"],
			order = 10,
			args = {
				header = {
					type = "header",
					name = L["Skillet Trade Skills"].." "..MAJOR_VERSION,
					order = 11
				},
				vendor_buy_button = {
					type = "toggle",
					name = L["VENDORBUYBUTTONNAME"],
					desc = L["VENDORBUYBUTTONDESC"],
					get = function()
						return Skillet.db.profile.vendor_buy_button;
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_buy_button = value;
					end,
					width = "double",
					order = 12
				},
				vendor_auto_buy = {
					type = "toggle",
					name = L["VENDORAUTOBUYNAME"],
					desc = L["VENDORAUTOBUYDESC"],
					get = function()
						return Skillet.db.profile.vendor_auto_buy;
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_auto_buy = value;
					end,
					width = "double",
					order = 13
				},
				show_item_notes_tooltip = {
					type = "toggle",
					name = L["SHOWITEMNOTESTOOLTIPNAME"],
					desc = L["SHOWITEMNOTESTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_item_notes_tooltip;
					end,
					set = function(self,value)
						Skillet.db.profile.show_item_notes_tooltip = value;
					end,
					width = "double",
					order = 14
				},
                show_detailed_recipe_tooltip = {
                    type = "toggle",
                    name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
                    desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_detailed_recipe_tooltip;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.show_detailed_recipe_tooltip = value;
                    end,
					width = "double",
                    order = 15
                },
                display_full_tooltip = {
                    type = "toggle",
                    name = L["SHOWFULLTOOLTIPNAME"],
                    desc = L["SHOWFULLTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.display_full_tooltip;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_full_tooltip = value;
                    end,
					width = "double",
                    order = 16
                },
				display_item_tooltip = {
                    type = "toggle",
                    name = L["SHOWITEMTOOLTIPNAME"],
                    desc = L["SHOWITEMTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.display_item_tooltip;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_item_tooltip = value;
                    end,
					width = "double",
                    order = 17
				},
                show_crafters_tooltip = {
                    type = "toggle",
                    name = L["SHOWCRAFTERSTOOLTIPNAME"],
                    desc = L["SHOWCRAFTERSTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_crafters_tooltip;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.show_crafters_tooltip = value;
                    end,
					width = "double",
                    order = 18
                },
                link_craftable_reagents = {
                    type = "toggle",
                    name = L["LINKCRAFTABLEREAGENTSNAME"],
                    desc = L["LINKCRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.link_craftable_reagents;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.link_craftable_reagents = value;
                    end,
					width = "double",
                    order = 19
                },
                queue_craftable_reagents = {
                    type = "toggle",
                    name = L["QUEUECRAFTABLEREAGENTSNAME"],
                    desc = L["QUEUECRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.queue_craftable_reagents;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.queue_craftable_reagents = value;
                    end,
					width = "double",
                    order = 20
                },
                queue_glyph_reagents = {
                    type = "toggle",
                    name = L["QUEUEGLYPHREAGENTSNAME"],
                    desc = L["QUEUEGLYPHREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.queue_glyph_reagents;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.queue_glyph_reagents = value;
                    end,
					width = "double",
                    order = 21
                },
                display_shopping_list_at_bank = {
                    type = "toggle",
                    name = L["DISPLAYSHOPPINGLISTATBANKNAME"],
                    desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_bank;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_shopping_list_at_bank = value;
                    end,
					width = "double",
                    order = 22
                },
                display_shopping_list_at_guildbank = {
                    type = "toggle",
                    name = L["DISPLAYSHOPPINGLISTATGUILDBANKNAME"],
                    desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_guildbank;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_shopping_list_at_guildbank = value;
                    end,
					width = "double",
                    order = 23
                },
                display_shopping_list_at_auction = {
                    type = "toggle",
                    name = L["DISPLAYSGOPPINGLISTATAUCTIONNAME"],
                    desc = L["DISPLAYSGOPPINGLISTATAUCTIONDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_auction;
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_shopping_list_at_auction = value;
                    end,
					width = "double",
                    order = 24
                },
                show_craft_counts = {
                    type = "toggle",
                    name = L["SHOWCRAFTCOUNTSNAME"],
                    desc = L["SHOWCRAFTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_craft_counts
                    end,
                    set = function(self,value)
                        Skillet.db.profile.show_craft_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
					width = "double",
                    order = 25,
                },
            }
        },
        appearance = {
            type = 'group',
            name = L["Appearance"],
            desc = L["APPEARANCEDESC"],
            order = 12,
            args = {
                display_required_level = {
                    type = "toggle",
                    name = L["DISPLAYREQUIREDLEVELNAME"],
                    desc = L["DISPLAYREQUIREDLEVELDESC"],
                    get = function()
                        return Skillet.db.profile.display_required_level
                    end,
                    set = function(self,value)
                        Skillet.db.profile.display_required_level = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
					width = "double",
                    order = 1
                },
                transparency = {
                    type = "range",
                    name = L["Transparency"],
                    desc = L["TRANSPARAENCYDESC"],
                    min = 0.1, max = 1, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.transparency
                    end,
                    set = function(self,t)
                        Skillet.db.profile.transparency = t
                        Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow()
						Skillet:UpdateStandaloneQueueWindow()
                    end,
					width = "double",
                    order = 2,
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    desc = L["SCALEDESC"],
                    min = 0.1, max = 1.25, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.scale
                    end,
                    set = function(self,t)
                        Skillet.db.profile.scale = t
                        Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow()
						Skillet:UpdateStandaloneQueueWindow()
                    end,
					width = "double",
                    order = 3,
                },
                enhanced_recipe_display = {
                    type = "toggle",
                    name = L["ENHANCHEDRECIPEDISPLAYNAME"],
                    desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
                    get = function()
                        return Skillet.db.profile.enhanced_recipe_display
                    end,
                    set = function(self,value)
                        Skillet.db.profile.enhanced_recipe_display = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
					width = "double",
                    order = 2,
                },
            },
        },
 --[[
		inventory = {
            type = "group",
            name = L["Inventory"],
            desc = L["INVENTORYDESC"],
            order = 13,
            args = {
                addons = {
                    type = 'execute',
                    name = L["Supported Addons"],
                    desc = L["SUPPORTEDADDONSDESC"],
                    func = function()
                        Skillet:ShowInventoryInfoPopup()
                    end,
                    order = 1,
                },
                show_bank_alt_counts = {
                    type = "toggle",
                    name = L["SHOWBANKALTCOUNTSNAME"],
                    desc = L["SHOWBANKALTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_bank_alt_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_bank_alt_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
            },
        },
]]
		config = {
			type = 'execute',
			name = L["Config"],
			desc = L["CONFIGDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ShowOptions()
				else
					DebugSpam("|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
            guiHidden = true,
			order = 51
		},
		standby = {
			type = 'execute',
			name = L["STANDBYNAME"],
			desc = L["STANDBYDESC"],
			func = function()
				if Skillet:IsEnabled() then
					Skillet:Disable()
					Skillet:Print(RED_FONT_COLOR_CODE..L["is now disabled"]..FONT_COLOR_CODE_CLOSE)
				else
					Skillet:Enable()
					Skillet:Print(GREEN_FONT_COLOR_CODE..L["is now enabled"]..FONT_COLOR_CODE_CLOSE)
				end
			end,
            guiHidden = true,
			order = 55
		},
        shoppinglist = {
            type = 'execute',
            name = L["Shopping List"],
            desc = L["SHOPPINGLISTDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    Skillet:DisplayShoppingList(false)
                else
                    DebugSpam("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            order = 52
        },
        reset = {
            type = 'execute',
            name = L["Reset"],
            desc = L["RESETDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    SkilletFrame:SetWidth(700);
                    SkilletFrame:SetHeight(600);
                    SkilletFrame:SetPoint("TOPLEFT",200,-100);                    
					SkilletStandalonQueue:SetWidth(385);
                    SkilletStandalonQueue:SetHeight(240);
                    SkilletStandalonQueue:SetPoint("TOPLEFT",300,-150);
                    local windowManger = LibStub("LibWindow-1.1")
                    windowManger.SavePosition(SkilletFrame)
                    windowManger.SavePosition(SkilletStandalonQueue) 
                else
                    DebugSpam("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            order = 99
        },        
	}
}


-- replaces the standard bliz frameshow calls with this for supported tradeskills
function DoNothing()
	DebugSpam("Do Nothing")
end


function Skillet:GetIDFromLink(link)				-- works with items or enchants
	if (link) then
		local found, _, string = string.find(link, "^|c%x+|H(.+)|h%[.+%]")

		if found then
			local _, id = strsplit(":", string)

			return tonumber(id);
		else
			return nil
		end
	end
end


function Skillet:DisableBlizzardFrame()
	if self.BlizzardTradeSkillFrame == nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end

		self.BlizzardTradeSkillFrame = TradeSkillFrame
		self.BlizzardTradeSkillFrame_Show = TradeSkillFrame_Show

		TradeSkillFrame_Show = DoNothing
	end
end

function Skillet:EnableBlizzardFrame()
	if self.BlizzardTradeSkillFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		TradeSkillFrame = self.BlizzardTradeSkillFrame
		TradeSkillFrame_Show = self.BlizzardTradeSkillFrame_Show

		self.BlizzardTradeSkillFrame = nil
		self.BlizzardTradeSkillFrame_Show = nil
	end
end

-- Called when the addon is loaded
function Skillet:OnInitialize()
	self.db = AceDB:New("SkilletDB", defaults)

	local _,_,_,wowVersion = GetBuildInfo();
	self.wowVersion = wowVersion

	self:InitializeDatabase((UnitName("player")), false)  --- force clean rescan for now

	-- hook default tooltips
	local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
	for _, tooltip in pairs(tooltipsToHook) do
		if tooltip and tooltip:HasScript("OnTooltipSetItem") then
			if tooltip:GetScript("OnTooltipSetItem") then
				local oldOnTooltipSetItem = tooltip:GetScript("OnTooltipSetItem")
				tooltip:SetScript("OnTooltipSetItem", function(tooltip)
					oldOnTooltipSetItem(tooltip)
					Skillet:AddItemNotesToTooltip(tooltip)
				end)
			else
				tooltip:SetScript("OnTooltipSetItem", function(tooltip)
					Skillet:AddItemNotesToTooltip(tooltip)
				end)
			end
		end
	end

	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet", self.options, "skillet")
    acecfg:RegisterOptionsTable("Skillet Features", self.options.args.features)
	acecfg:RegisterOptionsTable("Skillet Appearance", self.options.args.appearance)
	acecfg:RegisterOptionsTable("Skillet Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))

	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet Features", "Skillet")
	acedia:AddToBlizOptions("Skillet Appearance", "Appearance", "Skillet")
	acedia:AddToBlizOptions("Skillet Profiles", "Profiles", "Skillet")

	Skillet:InitializePlugins()

end


function Skillet:FlushAllData()
	Skillet.data = {}
	Skillet.data.recipeDB = {}

	Skillet.db.realm.skillRanks = {}
	Skillet.db.realm.skillDB = {}
	Skillet.db.realm.linkDB = {}
	Skillet.db.realm.groupDB = {}
	Skillet.db.realm.queueData = {}
	Skillet.db.realm.reagentsInQueue = {}
	Skillet.db.realm.inventoryData = {}

	Skillet:InitializeDatabase((UnitName("player")))
end


function Skillet:InitializeDatabase(player, clean)
DebugSpam("initialize database for "..player)

	if not self.db.realm.groupDB then
		self.db.realm.groupDB = {}
	end

	if not self.db.realm.inventoryData then
		self.db.realm.inventoryData = {}
	end

	if not self.db.realm.inventoryData[player] then
		self.db.realm.inventoryData[player] = {}
	end

	if not self.db.realm.reagentsInQueue then
		self.db.realm.reagentsInQueue = {}
	end

	if not self.db.realm.skillDB then
		self.db.realm.skillDB = {}
	end

	if not self.db.realm.skillRanks then
		self.db.realm.skillRanks = {}
	end

	if not self.data then
		self.data = {}
	end

	if not self.data.recipeList then
		self.data.recipeList = {}
	end

	if not self.data.skillList then
		self.data.skillList = {}
	end

	if not self.db.realm.linkDB then
		self.db.realm.linkDB = {}
	end

	if not self.data.groupList then
		self.data.groupList = {}
	end

	if not self.data.groupList[player] then
		self.data.groupList[player] = {}
	end

	if not self.data.recipeDB then
		self.data.recipeDB = {}
	end

	if not self.db.realm.queueData then
		self.db.realm.queueData = {}
	end

	if not self.db.realm.queueData[player] then
 		self.db.realm.queueData[player] = {}
 	end

    if not self.data.skillIndexLookup then
        self.data.skillIndexLookup = {}
    end

    if not self.data.skillIndexLookup[player] then
        self.data.skillIndexLookup[player] = {}
    end

	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end

	if not self.db.profile.SavedQueues then
		self.db.profile.SavedQueues = {}
	end

    if not self.dataGatheringModules then
        self.dataGatheringModules = {}
    end

 	if self.dataGatheringModules[player] then
 		local mod = self.dataGatheringModules[player]

 		mod.ScanPlayerTradeSkills(mod, player, clean)
 	else
		DebugSpam("data gather module is nil")
 	end

	self:CollectRecipeInformation()

--	self:RecipeGroupDeconstructDBStrings()
end


function Skillet:RegisterRecipeFilter(name, namespace, initMethod, filterMethod)
	if not self.recipeFilters then
		self.recipeFilters = {}
	end
--DEFAULT_CHAT_FRAME:AddMessage("add recipe filter "..name)
	self.recipeFilters[name] = { namespace = namespace, initMethod = initMethod, filterMethod = filterMethod }
end



function Skillet:RegisterRecipeDatabase(name, modules)
	if not self.recipeDataModules then
		self.recipeDataModules = {}
	end

	self.recipeDataModules[name] = modules
end


function Skillet:RegisterPlayerDataGathering(player, modules, recipeDB)
DebugSpam("RegisterPlayerDataGathering "..(player or "nil"))
	if not self.dataGatheringModules then
		self.dataGatheringModules = {}
	end

	if not self.recipeDB then
		self.recipeDB = {}
	end

	self.dataGatheringModules[player] = modules
	self.recipeDB[player] = recipeDB
DebugSpam("done with register")
end


-- Called when the addon is enabled
function Skillet:OnEnable()
    -- Hook into the events that we care about

    -- Trade skill window changes
	self:RegisterEvent("TRADE_SKILL_CLOSE",				"SkilletClose")
	self:RegisterEvent("TRADE_SKILL_SHOW",				"SkilletShow")
--	self:RegisterEvent("TRADE_SKILL_UPDATE")

	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS", "SkilletShowGuildCrafters")

    -- TODO: Tracks when the number of items on hand changes
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_OPEN")
--    self:RegisterEvent("TRADE_CLOSED")
--	self:RegisterEvent("CHAT_MSG_LOOT")

    -- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
    self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")

    -- May need to show a shopping list when at the bank/auction house
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED", "BANKFRAME_OPENED")
    self:RegisterEvent("GUILDBANKFRAME_CLOSED", "BANKFRAME_CLOSED")
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")

    -- Messages from the Stitch libary
    -- These need to update the tradeskill window, not just the queue
    -- as we need to redisplay the number of items that can be crafted
    -- as we consume reagents.
	self:RegisterMessage("Skillet_Queue_Continue", "QueueChanged")
	self:RegisterMessage("Skillet_Queue_Complete", "QueueChanged")
	self:RegisterMessage("Skillet_Queue_Add",      "QueueChanged")

--    self:RegisterMessage("SkilletStitch_Scan_Complete",  "ScanCompleted")


    self.hideUncraftableRecipes = false
    self.hideTrivialRecipes = false
    self.currentTrade = nil
    self.selectedSkill = nil
	self.currentPlayer = (UnitName("player"))
    self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil

    -- run the upgrade code to convert any old settings
    self:UpgradeDataAndOptions()


 	self:EnableQueue("Skillet")
	self:EnableDataGathering("Skillet")

	Skillet:UpdateAutoTradeButtons()

	self:DisableBlizzardFrame()
end

-- Called when the addon is disabled
function Skillet:OnDisable()
    --self:DisableDataGathering("Skillet")
    --self:DisableQueue("Skillet");

    self:UnregisterAllEvents()

	self:EnableBlizzardFrame()
end


local scan_in_progress = false
local need_rescan_on_open = false
local forced_rescan = false

function Skillet:ScanCompleted()
--    if scan_in_progress then
--        if forced_rescan and not need_rescan_on_open then
            -- only print this if we are not not doing a bag rescan,
            -- i.e. a first time or forced rescan.
--            local name = self:GetTradeSkillLine()
--            self:Print(L["Scan completed"] .. ": " .. name);
--        end

 --       self:UpdateScanningText("")
--        scan_in_progress = false
--        need_rescan_on_open = false
--        forced_rescan = false
        self:UpdateTradeSkillWindow()
 --   end
end

function Skillet:IsTradeSkillLinked()
	if IsTradeSkillLinked() or (IsTradeSkillGuild and IsTradeSkillGuild()) then
		local guildSkills = IsTradeSkillGuild and IsTradeSkillGuild()
		local _, linkedPlayer = IsTradeSkillLinked()

		if not linkedPlayer then
			if guildSkills then
				linkedPlayer = "Guild Recipes"
			else
				return
			end
		end
		return true, linkedPlayer, (IsTradeSkillGuild and IsTradeSkillGuild())
	end
	return false, nil
end

-- show the tradeskill window
-- only gets called from TRADE_SKILL_SHOW and CRAFT_SHOW events
-- this means, the skill being shown is for the main toon (not an alt)
function Skillet:SkilletShow()
DebugSpam("SHOW WINDOW (was showing "..(self.currentTrade or "nil")..")");


	TradeSkillFrame_Update();
	
	self.linkedSkill, self.currentPlayer = Skillet:IsTradeSkillLinked()
	
	if self.linkedSkill then

		if (self.currentPlayer == UnitName("player")) then
			self.currentPlayer = "All Data"
		end
		self:RegisterPlayerDataGathering(self.currentPlayer,SkilletLink,"sk")
	else
		self:InitializeAllDataLinks("All Data")

		self.currentPlayer = (UnitName("player"))
	end

--DEFAULT_CHAT_FRAME:AddMessage("SkilletShow")

	self.currentTrade = self.tradeSkillIDsByName[(GetTradeSkillLine())] or 2656      -- smelting caveat


	self:InitializeDatabase(self.currentPlayer)

	if self:IsSupportedTradeskill(self.currentTrade) then
		self:InventoryScan()


		self.tradeSkillOpen = true
DebugSpam("SkilletShow: "..self.currentTrade)

		self.selectedSkill = nil

		self.dataScanned = false
		self:ScheduleTimer("SkilletShowWindow", 0.5)
	else
		self:HideAllWindows()
		self:BlizzardTradeSkillFrame_Show()
	end

end

function Skillet:SkilletShowWindow()
		if IsControlKeyDown() then
			self.db.realm.skillDB[self.currentPlayer][self.currentTrade] = {}
		end

		self:RescanTrade()

		self.currentGroup = nil
		self.currentGroupLabel = self:GetTradeSkillOption("grouping")
		self:RecipeGroupDropdown_OnShow()

		self:ShowTradeSkillWindow()

		local filterbox = _G["SkilletFilterBox"]
		local oldtext = filterbox:GetText()
		local filterText = self:GetTradeSkillOption("filtertext")

		-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
		if filterText ~= oldtext then
			filterbox:SetText(filterText)
		else
			self:UpdateTradeSkillWindow()
		end

		self.dataSource = "api"
end

function Skillet:FreeCaches()
--	collectgarbage("collect")
--	if not cache then
--		cache = Skillet.data
--	end

--	local kbA = collectgarbage("count")
--	Skillet.data = {}
--	collectgarbage("collect")
--	local kbB = collectgarbage("count")
-- DEFAULT_CHAT_FRAME:AddMessage("free'd " .. data .. " (" .. math.floor((kbA - kbB)*100+.5)/100 .. " Kb)")
end


function Skillet:SkilletClose()
DebugSpam("SKILLET CLOSE")
	if self.dataSource == "api" then			-- if the skillet system is using the api for data access, then close the skillet window
		self:HideAllWindows()
		self:FreeCaches()
	end
end


-- Rescans the trades (and thus bags). Can only be called if the tradeskill
-- window is open and a trade selected.
function Skillet:RescanBags()
	local start = GetTime()


	Skillet:InventoryScan()
	Skillet:UpdateTradeSkillWindow()
    Skillet:UpdateShoppingListWindow()


	local elapsed = GetTime() - start

	if elapsed > 0.5 then
		DEFAULT_CHAT_FRAME:AddMessage("WARNING: skillet inventory scan took " .. math.floor(elapsed*100+.5)/100 .. " seconds to complete.")
	end
	self.rescan_bags_timer = nil
end

function Skillet:BAG_OPEN()
	Skillet:UpdateAutoTradeButtons()
end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE()

	if not self.rescan_auto_targets_timer then
		self.rescan_auto_targets_timer = self:ScheduleTimer("UpdateAutoTradeButtons", 0.3)
	end
		
	local showing = false
    if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
        showing = true
    end
    if self.shoppingList and self.shoppingList:IsVisible() then
        showing = true
    end

	if showing then
		-- bag updates can happen fairly frequently and we don't want to
		-- be scanning all the time so ... buffer updates to a single event
		-- that fires after a 1/5 second.
		if not self.rescan_bags_timer then
			self.rescan_bags_timer = self:ScheduleTimer("RescanBags", 0.2)
		end
    else
       -- no trade window open, but something change, we will need to rescan
       -- when the window is next opened.
       need_rescan_on_open = true
	end

    if MerchantFrame and MerchantFrame:IsVisible() then
        -- may need to update the button on the merchant frame window ...
        self:UpdateMerchantFrame()
    end
end


function Skillet:CHAT_MSG_LOOT()
--	DebugSpam("CHAT_MSG_LOOT: "..arg1.." "..arg2)
end


-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
function Skillet:TRADE_CLOSED()
    self:BAG_UPDATE()
end



function Skillet:SetTradeSkill(player, tradeID, skillIndex)
DebugSpam("setting tradeskill to "..player.." "..tradeID.." "..(skillIndex or "nil"))
    if not self.db.realm.queueData[player] then
 		self.db.realm.queueData[player] = {}
 	end

 	if player ~= self.currentPlayer or tradeID ~= self.currentTrade then
--		local kbA = collectgarbage("count")
--		self.data.recipeList = {}
--		self.data.skillList = {}
--		self.data.groupList = {}
--		collectgarbage("collect")
--		local kbB = collectgarbage("count")
--DEFAULT_CHAT_FRAME:AddMessage("free'd " .. math.floor((kbA - kbB)*100+.5)/100 .. " Kb")

		collectgarbage("collect")

	 	self.currentPlayer = player
		local oldTradeID = self.currentTrade

		if player == (UnitName("player")) then								-- we can update the tradeskills if this toon is the current one
			self.dataSource = "api"
			self.dataScanned = false
			self.currentGroup = nil

			self.currentGroupLabel = self:GetTradeSkillOption("grouping")
			self:RecipeGroupDropdown_OnShow()

-- DebugSpam("cast: "..self:GetTradeName(tradeID))

			CastSpellByName(self:GetTradeName(tradeID))				-- this will trigger the whole rescan process via a TRADE_SKILL_SHOW/CRAFT_SHOW event
        else
            self.dataSource = "cache"
			CloseTradeSkill()

			self.dataScanned = false

			self:HideNotesWindow();

			self.currentTrade = tradeID
			self.currentGroup = nil
			self.currentGroupLabel = self:GetTradeSkillOption("grouping")

--			self:RecipeGroupDeconstructDBStrings()

			self:RecipeGroupGenerateAutoGroups()

			self:RecipeGroupDropdown_OnShow()

			if not self.data.skillList[player] then
				self.data.skillList[player] = {}
			end

			if not self.data.skillList[player][tradeID] then
				self.data.skillList[player][tradeID] = {}
			end

			-- remove any filters currently in place
			local filterbox = _G["SkilletFilterBox"]
	        local oldtext = filterbox:GetText()
	        local filterText = self:GetTradeSkillOption("filtertext")

	    	-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
	    	if filterText ~= oldtext then
	    		filterbox:SetText(filterText)
	    	else
	    		self:UpdateTradeSkillWindow()
	    	end
	 	end

DebugSpam("Tradeskill is set to "..(self.currentPlayer or "nil").." "..(self.currentTrade or "nil"))
    end
 	self:SetSelectedSkill(skillIndex, false)
end


-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
DebugSpam("UPDATE TRADE SKILL")

	local trade_changed = false
	local new_trade = self:GetTradeSkillLine()

	if not self.currentTrade and new_trade then
		trade_changed = true
	elseif self.currentTrade ~= new_trade then
		trade_changed = true
	end

	if true or trade_changed then
		self:HideNotesWindow();

		self.sortedRecipeList = {}

	   	-- And start the update sequence through the rest of the mod
		self:SetSelectedTrade(new_trade)

--		self:RescanTrade()

		-- remove any filters currently in place
		local filterbox = _G["SkilletFilterBox"];
        local filtertext = self:GetTradeSkillOption("filtertext", self.currentPlayer, new_trade)
    	-- this fires off a redraw event, so only change after data has been acquired
    	filterbox:SetText(filtertext);
    end
DebugSpam("UPDATE TRADE SKILL complete")
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
DebugSpam("internal_ShowTradeSkillWindow")
	local frame = self.tradeSkillFrame
    if not frame then
        frame = self:CreateTradeSkillWindow()
        self.tradeSkillFrame = frame
    end

    self:ResetTradeSkillWindow()

	Skillet:ShowFullView()

    if not frame:IsVisible() then
		frame:Show()
		self:UpdateTradeSkillWindow()
    else
    	self:UpdateTradeSkillWindow()
    end
DebugSpam("internal_ShowTradeSkillWindow complete")
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:internal_HideTradeSkillWindow()

    local closed -- was anything closed by us?
    local frame = self.tradeSkillFrame

    if frame and frame:IsVisible() then
        self:StopCast()
        frame:Hide()
        closed = true
    end

    return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:internal_HideAllWindows()
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

-- Show the options window
function Skillet:ShowOptions()
	InterfaceOptionsFrame_OpenToCategory("Skillet")
end

-- Notes when a new trade has been selected
function Skillet:SetSelectedTrade(newTrade)
	self.currentTrade = newTrade;
	self:SetSelectedSkill(nil, false)
--	self.headerCollapsedState = {};

--	self:UpdateTradeSkillWindow()

	-- Stop the stitch queue and nuke anything in it.
	-- would be nice to allow queuing items from different
	-- trades, but the Blizzard design does not allow that
--	self:CancelCast();
--	self:StopCast();
--	self:ClearQueue();
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skillIndex, wasClicked)
	if not skillIndex then
		-- no skill selected
		self:HideNotesWindow()
	elseif self.selectedSkill and self.selectedSkill ~= skillIndex then
		-- new skill selected
		self:HideNotesWindow() -- XXX: should this be an update?
	end

--	if skillIndex then
--		local recipe = self:GetRecipeDataByProfessionIndex(self.currentTrade, skillIndex)
--
--		self:ConfigureRecipeControls(recipe.numMade==0)			-- numMade==0 indicates an enchantment
--	else
--		self:ConfigureRecipeControls(false)
--	end

	self:ConfigureRecipeControls(false)				-- allow ALL trades to queue up items (enchants as well)

	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
end


-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
DebugSpam("UpdateFilter")
    self:SetTradeSkillOption("filtertext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
DebugSpam("UpdateFilter complete")
end

-- Called when the queue has changed in some way
function Skillet:QueueChanged()

DebugSpam("QUEUE CHANGED")
    -- Hey! What's all this then? Well, we may get the request to update the
    -- windows while the queue is being processed and the reagent and item
    -- counts may not have been updated yet. So, the "0.5" puts in a 1/2
    -- second delay before the real update window method is called. That
    -- give the rest of the UI (and the API methods called by Stitch) time
    -- to record any used reagents.
--    if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
--        if not AceEvent:IsEventScheduled("Skillet_UpdateWindows") then
--            AceEvent:ScheduleEvent("Skillet_UpdateWindows", Skillet.UpdateTradeSkillWindow, 0.5, self)
--        end
--    end

--    if SkilletShoppingList and SkilletShoppingList:IsVisible() then
--        if not AceEvent:IsEventScheduled("Skillet_UpdateShoppingList") then
--            AceEvent:ScheduleEvent("Skillet_UpdateShoppingList", Skillet.UpdateShoppingListWindow, 0.25, self)
--        end
--    end

--    if MerchantFrame and MerchantFrame:IsVisible() then
--        if not AceEvent:IsEventScheduled("Skillet_UpdateMerchantFrame") then
--            AceEvent:ScheduleEvent("Skillet_UpdateMerchantFrame", Skillet.UpdateMerchantFrame, 0.25, self)
 --       end
 --   end
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(key)
	local result

    if not self.db.realm.notes[self.currentPlayer] then
        return
    end

--    local id = self:GetItemIDFromLink(link)
	local kind, id = string.split(":", key)

	if id and self.db.realm.notes[self.currentPlayer] then
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

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(key, note)
--	local id = self:GetItemIDFromLink(link);
	local kind, id = string.split(":", key)

    if not self.db.realm.notes[self.currentPlayer] then
        self.db.realm.notes[self.currentPlayer] = {}
    end

	if id then
		self.db.realm.notes[self.currentPlayer][id] = note
	else
		self:Print("Error: Skillet:SetItemNote() could not determine item ID for " .. key);
	end

end

-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
function Skillet:AddItemNotesToTooltip(tooltip)
    if IsControlKeyDown() then
        return
    end

    local notes_enabled = self.db.profile.show_item_notes_tooltip or false
    local crafters_enabled = self.db.profile.show_crafters_tooltip or false

    -- nothing to be added to the tooltip
    if not notes_enabled and not crafters_enabled then
        return
    end

    -- get item name
    local name,link = tooltip:GetItem();
    if not link then return; end

    local id = self:GetItemIDFromLink(link);
    if not id then return end;

    if notes_enabled then
        local header_added = false
        for player,notes_table in pairs(self.db.realm.notes) do
            local note = notes_table[id]
            if note then
                if not header_added then
                    tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
                    header_added = true
                end
                if player ~= UnitName("player") then
                    note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
                end
                tooltip:AddLine(" " .. note, 1, 1, 1, 1) -- r,g,b, wrap
            end
        end
    end

    if crafters_enabled then
        local crafters = self:GetCraftersForItem(id);
        if crafters then
            header_added = true
            local title_added = false

            for i,name in ipairs(crafters) do
                if not title_added then
                    title_added = true
                    tooltip:AddDoubleLine(L["Crafted By"], name)
                else
                    tooltip:AddDoubleLine(" ", name)
                end
            end
        end
    end

    return header_added
end


function Skillet:ToggleTradeSkillOption(option)
	local v = self:GetTradeSkillOption(option)

	self:SetTradeSkillOption(option, not v)
end


-- Returns the state of a craft specific option
function Skillet:GetTradeSkillOption(option, playerOverride, tradeOverride)
    local player = playerOverride or self.currentPlayer
	local trade = tradeOverride or self.currentTrade

	local options = self.db.global.options

    if not options or not options[player] or not options[player][trade] then
       return Skillet.defaultOptions[option]
    end

	if options[player][trade][option] == nil then
		return Skillet.defaultOptions[option]
	end

    return options[player][trade][option]
end


-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(option, value, playerOverride, tradeOverride)
	local player = playerOverride or self.currentPlayer
	local trade = tradeOverride or self.currentTrade

	if not self.db.global.options then
		self.db.global.options = {}
	end

	if not self.db.global.options[player] then
		self.db.global.options[player] = {}
	end

    if not self.db.global.options[player][trade] then
        self.db.global.options[player][trade] = {}
    end

    self.db.global.options[player][trade][option] = value
end


function ProfessionPopup_SelectPlayerTrade(menuFrame,player,tradeID)
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
	Skillet:SetTradeSkill(player,tradeID)
end

--|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:[<-{]+|h%[[%a%s]+%]|h|r]]
--	[3273] = "|cffffd000|Htrade:3274:148:150:23F381A:zD<<t=|h[First Aid]|h|r",

function ProfessionPopup_SelectTradeLink(menuFrame,player,link)
--	link = "|cffffd000|Htrade:3274:400:450:23F381A:{{{{{{|h[First Aid]|h|r"
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
	local _,_,tradeString = string.find(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

	SetItemRef(tradeString,link,"LeftButton")
end


function ProfessionPopup_Init(menuFrame, level)
	if (level == 1) then  -- character names
		local title = {}
		local playerMenu = {}

		title.text = "Select Player and Tradeskill"
		title.isTitle = true

		UIDropDownMenu_AddButton(title)

		local i=1
		for player, gatherModule in pairs(Skillet.dataGatheringModules) do
			skillData = gatherModule.ScanPlayerTradeSkills(gatherModule, player)

			if skillData then
				playerMenu.text = player
				playerMenu.hasArrow = true
				playerMenu.value = player
				playerMenu.disabled = false


				UIDropDownMenu_AddButton(playerMenu)
				i = i + 1
			end
		end

		if (i == 1) then
			playerMenu.text = "[no players scanned]";
			playerMenu.disabled = true;

			playerMenu.arg1 = "";
			playerMenu.arg2 = "";
			playerMenu.func = nil;

			UIDropDownMenu_AddButton(playerMenu, level);
		end
	end

	if (level == 2) then  -- skills per player
		local gatherModule = Skillet.dataGatheringModules[UIDROPDOWNMENU_MENU_VALUE]

		local skillRanks = gatherModule.ScanPlayerTradeSkills(gatherModule, UIDROPDOWNMENU_MENU_VALUE)
		local skillButton = {}



		for i=1,#Skillet.tradeSkillList do
			local tradeID = Skillet.tradeSkillList[i]
			local list = Skillet:GetSkillRanks(UIDROPDOWNMENU_MENU_VALUE, tradeID)

			if not nonLinkingTrade[tradeID] or UIDROPDOWNMENU_MENU_VALUE == UnitName("player") then
				if list then

					local rank, maxRank = string.split(" ", list)

					skillButton.text = Skillet:GetTradeName(tradeID).." |cff00ff00["..(rank or "?").."/"..(maxRank or "?").."]|r"
					skillButton.value = tradeID

					skillButton.icon = list.texture


					if gatherModule == SkilletLink then
						skillButton.arg1 = UIDROPDOWNMENU_MENU_VALUE
						skillButton.arg2 = Skillet.db.realm.linkDB[UIDROPDOWNMENU_MENU_VALUE][tradeID]
						skillButton.func = ProfessionPopup_SelectTradeLink
					else
						skillButton.arg1 = UIDROPDOWNMENU_MENU_VALUE
						skillButton.arg2 = tradeID
						skillButton.func = ProfessionPopup_SelectPlayerTrade
					end

					if tradeID == Skillet.currentTrade and UIDROPDOWNMENU_MENU_VALUE == Skillet.currentPlayer then
						skillButton.checked = true
					else
						skillButton.checked = false
					end

					if UIDROPDOWNMENU_MENU_VALUE ~= (UnitName("player")) and not list then
						skillButton.disabled = true
					else
						skillButton.disabled = false
					end

					UIDropDownMenu_AddButton(skillButton, level)
				end
			end
		end
	end
end

function ProfessionPopup_Show(this)
--	if not ProfessionPopupFrame then
	ProfessionPopupFrame = CreateFrame("Frame", "ProfessionPopupFrame", _G["UIParent"], "UIDropDownMenuTemplate")
--	end

	Skillet.professionPopupButton = this

	UIDropDownMenu_Initialize(ProfessionPopupFrame, ProfessionPopup_Init, "MENU")
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
end

-- workaround for Ace2
function Skillet:IsActive()
	return Skillet:IsEnabled()
end

