local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
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

local MAJOR_VERSION = "2.70"
local MINOR_VERSION = ("$Revision$"):match("%d+") or 1
local DATE = string.gsub("$Date$", "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

Skillet = LibStub("AceAddon-3.0"):NewAddon("Skillet", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
Skillet.title   = "Skillet"
Skillet.version = MAJOR_VERSION .. "-" .. MINOR_VERSION .. "LS"
Skillet.date    = DATE
local AceDB = LibStub("AceDB-3.0")

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet
local DA = Skillet -- needed because LibStub changed the definition of Skillet

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
		include_alts = true,	-- Display alt's items in shopping list
		item_order =  false,	-- Order shopping list by item
		merge_items = false,	-- Merge same shopping list items together
		include_guild = false,	-- Use the contents of the Guild Bank
		include_bank = true,	-- Use the contents of the Bank
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
	["filterInventory-owned"] = true,
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

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
Skillet.L = L

-- All the options that we allow the user to control.
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
					disabled = true, -- because of 5.4 changes to trade links 
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
						Skillet:UpdateShoppingListWindow(false)
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
						Skillet:UpdateShoppingListWindow(false)
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
 		config = {
			type = 'execute',
			name = L["Config"],
			desc = L["CONFIGDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ShowOptions()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			guiHidden = true,
			order = 51
		},
		shoppinglist = {
			type = 'execute',
			name = L["Shopping List"],
			desc = L["SHOPPINGLISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:DisplayShoppingList(false)
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 52
		},
		shoppingclear = {
			type = 'execute',
			name = L["Shopping Clear"],
			desc = L["SHOPPINGCLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 53
		},
		flushalldata = {
			type = 'execute',
			name = L["Flush All Data"],
			desc = L["FLUSHALLDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushAllData()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 54
		},
		flushrecipedata = {
			type = 'execute',
			name = L["Flush Recipe Data"],
			desc = L["FLUSHRECIPEDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushRecipeData()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 55
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
			order = 56
		},

		WarnShow = {
			type = "toggle",
			name = "WarnShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.WarnShow
			end,
			set = function(self,value)
				Skillet.db.profile.WarnShow = value
				Skillet.WarnShow = value
				if value then
					Skillet.db.profile.WarnLog = value
					Skillet.WarnLog = value
				end
			end,
			order = 81
		},
		WarnLog = {
			type = "toggle",
			name = "WarnLog",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.WarnLog
			end,
			set = function(self,value)
				Skillet.db.profile.WarnLog = value
				Skillet.WarnLog = value
			end,
			order = 82
		},
		DebugShow = {
			type = "toggle",
			name = "DebugShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugShow
			end,
			set = function(self,value)
				Skillet.db.profile.DebugShow = value
				Skillet.DebugShow = value
				if value then
					Skillet.db.profile.DebugLogging = value
					Skillet.DebugLogging = value
				end
			end,
			order = 83
		},
		DebugLogging = {
			type = "toggle",
			name = "DebugLoggibg",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugLogging
			end,
			set = function(self,value)
				Skillet.db.profile.DebugLogging = value
				Skillet.DebugLogging = value
			end,
			order = 84
		},
		DebugLevel = {
			type = "input",
			name = "DebugLevel",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugLevel
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				Skillet.db.profile.DebugLevel = value
				Skillet.DebugLevel = value
			end,
			order = 85
		},
		TableDump = {
			type = "toggle",
			name = "TableDump",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TableDump
			end,
			set = function(self,value)
				Skillet.db.profile.TableDump = value
				Skillet.TableDump = value
			end,
			order = 86
		},
		TraceShow = {
			type = "toggle",
			name = "TraceShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceShow
			end,
			set = function(self,value)
				Skillet.db.profile.TraceShow = value
				Skillet.TraceShow = value
				if value then
					Skillet.db.profile.TraceLog = value
					Skillet.TraceLog = value
				end
			end,
			order = 87
		},
		TraceLog = {
			type = "toggle",
			name = "TraceLog",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceLog
			end,
			set = function(self,value)
				Skillet.db.profile.TraceLog = value
				Skillet.TraceLog = value
			end,
			order = 88
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				SkilletDBPC = {}
				DA.DebugLog = SkilletDBPC
			end,
			order = 89
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 99
		},        
	}
}

-- replaces the standard bliz frameshow calls with this for supported tradeskills
local function DoNothing()
	DA.DEBUG(0,"Do Nothing")
end

function Skillet:GetIDFromLink(link)	-- works with items or enchants
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
	if not SkilletDBPC then
		SkilletDBPC = {}
	end
	if not SkilletMemory then
		SkilletMemory = {}
	end
	if DA.deepcopy then			-- For serious debugging, start with a clean slate
		SkilletMemory = {}
		SkilletDBPC = {}
	end
	DA.DebugLog = SkilletDBPC
	self.db = AceDB:New("SkilletDB", defaults)
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
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

--
-- Copy the profile debugging variables to the "addon name" global table 
-- where DebugAids.lua is looking for them.
--
-- Warning:	Setting TableDump can be a performance hog, use caution.
--			Setting DebugLogging (without DebugShow) is a minor performance hit.
--			WarnLog (with or without WarnShow) can remain on as warning messages are rare.
--
	if Skillet.db.profile.WarnLog == nil then
		Skillet.db.profile.WarnLog = true
	end
	Skillet.WarnShow = Skillet.db.profile.WarnShow
	Skillet.WarnLog = Skillet.db.profile.WarnLog
	Skillet.DebugShow = Skillet.db.profile.DebugShow
	Skillet.DebugLogging = Skillet.db.profile.DebugLogging
	Skillet.DebugLevel = Skillet.db.profile.DebugLevel
	Skillet.TableDump = Skillet.db.profile.TableDump
	Skillet.TraceShow = Skillet.db.profile.TraceShow
	Skillet.TraceLog = Skillet.db.profile.TraceLog
	--
	Skillet:InitializePlugins()
end

function Skillet:FlushAllData()
	Skillet.data = {}
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.realm.skillDB = {}
	Skillet.db.realm.tradeSkills = {}
	Skillet.db.realm.groupDB = {}
	Skillet.db.realm.queueData = {}
	Skillet.db.realm.auctionData = {}
	Skillet.db.realm.reagentsInQueue = {}
	Skillet.db.realm.inventoryData = {}
	Skillet.db.realm.reagentBank = {}
	Skillet:InitializeDatabase((UnitName("player")))
end

function Skillet:FlushRecipeData()
--	Skillet.data = {}
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.realm.skillDB = {}
	Skillet:InitializeDatabase((UnitName("player")))
end

function Skillet:InitializeDatabase(player, clean)
	DA.DEBUG(0,"initialize database for "..player)
	if self.db.realm.dataVersion then
		self.db.global.dataVersion = self.db.realm.dataVersion
		self.db.realm.dataVersion = nil
	end
	if not self.db.global.dataVersion or self.db.global.dataVersion < 4 then
		self.db.global.dataVersion = 4
		self:FlushAllData()
	end
	if not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end
	if not self.db.realm.groupDB then
		self.db.realm.groupDB = {}
	end
	if not self.db.realm.inventoryData then
		self.db.realm.inventoryData = {}
	end
	if not self.db.realm.inventoryData[player] then
		self.db.realm.inventoryData[player] = {}
	end
	if not self.db.realm.reagentBank then
		self.db.realm.reagentBank = {}
	end
	if not self.db.realm.reagentBank[player] then
		self.db.realm.reagentBank[player] = {}
	end
	if not self.db.realm.reagentsInQueue then
		self.db.realm.reagentsInQueue = {}
	end
	if not self.db.realm.skillDB then
		self.db.realm.skillDB = {}
	end
	if not self.db.realm.skillDB[player] then
		self.db.realm.skillDB[player] = {}
	end
	if not self.db.realm.tradeSkills then
		self.db.realm.tradeSkills = {}
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
	if not self.db.profile.SavedQueues then
		self.db.profile.SavedQueues = {}
	end
	if not self.db.global.recipeDB then
		self.db.global.recipeDB = {}
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
	if not self.data then
		self.data = {}
	end
	if not self.data.recipeList then
		self.data.recipeList = {}
	end
	if not self.data.skillList then
		self.data.skillList = {}
	end
	if not self.data.skillList[player] then
		self.data.skillList[player] = {}
	end
	if not self.data.groupList then
		self.data.groupList = {}
	end
	if not self.data.groupList[player] then
		self.data.groupList[player] = {}
	end
	if not self.data.skillIndexLookup then
		self.data.skillIndexLookup = {}
	end
	if not self.data.skillIndexLookup[player] then
		self.data.skillIndexLookup[player] = {}
	end
	if not self.dataGatheringModules then
		self.dataGatheringModules = {}
	end
	if self.dataGatheringModules[player] then
		local mod = self.dataGatheringModules[player]
		mod.ScanPlayerTradeSkills(mod, player, clean)
	else
		DA.DEBUG(0,"data gather module is nil")
	end
	self:CollectRecipeInformation()
end

function Skillet:RegisterRecipeFilter(name, namespace, initMethod, filterMethod)
	if not self.recipeFilters then
		self.recipeFilters = {}
	end
--	DA.DEBUG(0,"add recipe filter "..name)
	self.recipeFilters[name] = { namespace = namespace, initMethod = initMethod, filterMethod = filterMethod }
end

function Skillet:RegisterRecipeDatabase(name, modules)
	if not self.recipeDataModules then
		self.recipeDataModules = {}
	end
	self.recipeDataModules[name] = modules
end

function Skillet:RegisterPlayerDataGathering(player, modules, recipeDB)
	DA.DEBUG(0,"RegisterPlayerDataGathering "..(player or "nil"))
	if not self.dataGatheringModules then
		self.dataGatheringModules = {}
	end
	if not self.recipeDB then
		self.recipeDB = {}
	end
	self.dataGatheringModules[player] = modules
	self.recipeDB[player] = recipeDB
	DA.DEBUG(0,"done with register")
end

-- Called when the addon is enabled
function Skillet:OnEnable()
	DA.DEBUG(0,"Skillet:OnEnable()");
	-- Hook into the events that we care about
	-- Trade skill window changes
	self:RegisterEvent("TRADE_SKILL_CLOSE", "SkilletClose")
	self:RegisterEvent("TRADE_SKILL_SHOW", "SkilletShow")
	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS", "SkilletShowGuildCrafters")
	-- TODO: Tracks when the number of items on hand changes
	self:RegisterEvent("BAG_UPDATE") -- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED") -- Fires after all applicable BAG_UPADTE events for a specific action have been fired.
	-- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")
	-- May need to show a shopping list when at the bank/guildbank/auction house
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	-- self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE") -- Update event only when the AH is open
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("PLAYER_LOGOUT")
	--
	-- Messages from the Stitch libary
	-- These need to update the tradeskill window, not just the queue
	-- as we need to redisplay the number of items that can be crafted
	-- as we consume reagents.
	self:RegisterMessage("Skillet_Queue_Continue", "QueueChanged")
	self:RegisterMessage("Skillet_Queue_Complete", "QueueChanged")
	self:RegisterMessage("Skillet_Queue_Add",      "QueueChanged")
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
	Skillet:EnablePlugins()
end

function Skillet:PLAYER_LOGOUT()
	DA.DEBUG(0,"PLAYER_LOGOUT")
--
-- Make a copy of the in memory data for debugging. Note: DeepCopy.lua needs to be added to the .toc
--
	if DA.deepcopy then
		self.data.sortedSkillList = {"Removed"} -- This table is huge so don't save it unless needed.
		SkilletMemory = DA.deepcopy(self.data)
	end
end

-- Called when the addon is disabled
function Skillet:OnDisable()
	DA.DEBUG(0,"Skillet:OnDisable()");
	self:UnregisterAllEvents()
	self:EnableBlizzardFrame()
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
--		DA.DEBUG(0,"IsTradeSkillLinked Player "..linkedPlayer);
		return true, linkedPlayer, (IsTradeSkillGuild and IsTradeSkillGuild())
	end
	return false, nil
end

-- show the tradeskill window
-- only gets called from TRADE_SKILL_SHOW and CRAFT_SHOW events
-- this means, the skill being shown is for the main toon (not an alt)
function Skillet:SkilletShow()
	DA.DEBUG(1,"SHOW WINDOW (was showing "..(self.currentTrade or "nil")..")");
	TradeSkillFrame_Update();
	self.linkedSkill, self.currentPlayer = Skillet:IsTradeSkillLinked()
	if self.linkedSkill then
		self:RegisterPlayerDataGathering(self.currentPlayer,SkilletLink,"sk")
	else
		self:InitializeAllDataLinks("All Data")
		self.currentPlayer = (UnitName("player"))
	end
	self.currentTrade = self.tradeSkillIDsByName[(GetTradeSkillLine())] or 2656      -- smelting caveat
	self:InitializeDatabase(self.currentPlayer)
	
	local showBlizzUI = false
	
	-- workaround for enchant illusions which are only supported in the Blizzard UI
	if self.currentTrade == 7411 then
		local numSkills = GetNumTradeSkills()
		for i = 1, numSkills, 1 do
			local _, skillType = GetTradeSkillInfo(i);			
			if skillType ~= "header" and skillType ~= "subheader" then
				if GetTradeSkillRecipeLink(i) == nil then
					showBlizzUI = true
				end		
			end
		end
	end
	if showBlizzUI then
			self:HideAllWindows()
			self:BlizzardTradeSkillFrame_Show()	
	else
		if self:IsSupportedTradeskill(self.currentTrade) then
			self:InventoryScan()
			self.tradeSkillOpen = true
			DA.DEBUG(1,"SkilletShow: "..self.currentTrade)
			self.selectedSkill = nil
			self.dataScanned = false
			self:ScheduleTimer("SkilletShowWindow", 0.5)
		else
			self:HideAllWindows()
			self:BlizzardTradeSkillFrame_Show()
			Skillet.TSMPlugin.TSMShow()
		end	
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

function Skillet:SkilletClose()
	DA.DEBUG(0,"SKILLET CLOSE")
	if self.dataSource == "api" then -- if the skillet system is using the api for data access, then close the skillet window
		self:HideAllWindows()
	end
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill
-- window is open and a trade selected.
function Skillet:RescanBags()
	DA.DEBUG(0,"RescanBags()")
	local start = GetTime()
	Skillet:InventoryScan()
	Skillet:UpdateTradeSkillWindow()
	Skillet:UpdateShoppingListWindow(true)
	local elapsed = GetTime() - start
	if elapsed > 0.5 then
		DA.DEBUG(0,"WARNING: skillet inventory scan took " .. math.floor(elapsed*100+.5)/100 .. " seconds to complete.")
	end
end

function Skillet:BAG_OPEN(event, bagID) -- Fires when a non-inventory container is opened.
	DA.TRACE("BAG_OPEN( "..tostring(bagID).." )") -- We don't really care
end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE(event, bagID)
--	DA.DEBUG(2,"BAG_UPDATE( "..bagID.." )")
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
	-- bagID = tonumber(bagID)
	if showing then
		if bagID >= 0 and bagID <= 4 then
			-- an inventory bag update, do nothing (wait for the BAG_UPDATE_DELAYED).
		end
		if bagID == -1 or bagID >= 5 then
			-- a bank update, process it in ShoppingList.lua
			Skillet:BANK_UPDATE(event,bagID) -- Looks like an event but its not.
		end
	end
	if MerchantFrame and MerchantFrame:IsVisible() then
		-- may need to update the button on the merchant frame window ...
		self:UpdateMerchantFrame()
	end
	-- Most of the shoppingList code is in ShoppingList.lua
	if self.shoppingList and self.shoppingList:IsVisible() then
		Skillet:InventoryScan()
		Skillet:UpdateShoppingListWindow(true)
	end
end

function Skillet:BAG_CLOSED(event, bagID)        -- Fires when the whole bag is removed from 
	DA.TRACE("BAG_CLOSED( "..tostring(bagID).." )") -- inventory or bank. We don't really care. 
end

-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
function Skillet:TRADE_CLOSED()
	self:BAG_UPDATE("FAKE_BAG_UPDATE", 0)
end

function Skillet:SetTradeSkill(player, tradeID, skillIndex)
	DA.DEBUG(0,"SetTradeSkill("..tostring(player)..", "..tostring(tradeID)..", "..tostring(skillIndex)..")")
	if not self.db.realm.queueData[player] then
		self.db.realm.queueData[player] = {}
	end
	if player ~= self.currentPlayer or tradeID ~= self.currentTrade then
		collectgarbage("collect")
	 	self.currentPlayer = player
		local oldTradeID = self.currentTrade
		if player == (UnitName("player")) then	-- we can update the tradeskills if this toon is the current one
			self.dataSource = "api"
			self.dataScanned = false
			self.currentGroup = nil
			self.currentGroupLabel = self:GetTradeSkillOption("grouping")
			self:RecipeGroupDropdown_OnShow()
			--DA.DEBUG(1,"cast: "..self:GetTradeName(tradeID))
			CastSpellByName(self:GetTradeName(tradeID)) -- this will trigger the whole rescan process via a TRADE_SKILL_SHOW/CRAFT_SHOW event
		else
			self.dataSource = "cache"
			CloseTradeSkill()
			self.dataScanned = false
			self:HideNotesWindow();
			self.currentTrade = tradeID
			self.currentGroup = nil
			self.currentGroupLabel = self:GetTradeSkillOption("grouping")
			-- self:RecipeGroupDeconstructDBStrings()
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
	end
	self:SetSelectedSkill(skillIndex, false)
end

-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
	DA.DEBUG(0,"UPDATE TRADE SKILL")
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
		-- remove any filters currently in place
		local filterbox = _G["SkilletFilterBox"];
		local filtertext = self:GetTradeSkillOption("filtertext", self.currentPlayer, new_trade)
		-- this fires off a redraw event, so only change after data has been acquired
		filterbox:SetText(filtertext);
	end
	DA.DEBUG(0,"UPDATE TRADE SKILL complete")
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
	DA.DEBUG(0,"internal_ShowTradeSkillWindow")
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
	DA.DEBUG(0,"internal_ShowTradeSkillWindow complete")
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
	DA.DEBUG(0,"SetSelectedTrade("..tostring(newTrade)..")")
	self.currentTrade = newTrade;
	self:SetSelectedSkill(nil, false)
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skillIndex, wasClicked)
	DA.DEBUG(0,"SetSelectedSkill("..tostring(skillIndex)..", "..tostring(wasClicked)..")")
	if not skillIndex then
		-- no skill selected
		self:HideNotesWindow()
	elseif self.selectedSkill and self.selectedSkill ~= skillIndex then
		-- new skill selected
		self:HideNotesWindow() -- XXX: should this be an update?
	end
	self:ConfigureRecipeControls(false)				-- allow ALL trades to queue up items (enchants as well)
	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
	DA.DEBUG(0,"UpdateFilter")
	self:SetTradeSkillOption("filtertext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
	DA.DEBUG(0,"UpdateFilter complete")
end

-- Called when the queue has changed in some way
function Skillet:QueueChanged()
	DA.DEBUG(0,"QUEUE CHANGED")
	-- Hey! What's all this then? Well, we may get the request to update the
	-- windows while the queue is being processed and the reagent and item
	-- counts may not have been updated yet. So, the "0.5" puts in a 1/2
	-- second delay before the real update window method is called. That
	-- give the rest of the UI (and the API methods called by Stitch) time
	-- to record any used reagents.
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(key)
--	DA.DEBUG(0,"GetItemNote("..tostring(key)..")")
	local result
	if not self.db.realm.notes[self.currentPlayer] then
		return
	end
--	local id = self:GetItemIDFromLink(link)
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- get the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
--	DA.DEBUG(0,"GetItemNote itemID="..tostring(id))
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

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(key, note)
--	DA.DEBUG(0,"SetItemNote("..tostring(key)..", "..tostring(note)..")")
--	local id = self:GetItemIDFromLink(link);
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- store the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
--	DA.DEBUG(0,"SetItemNote itemID="..tostring(id))
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
--	DA.DEBUG(0,"AddItemNotesToTooltip()")
	if IsControlKeyDown() then
		return
	end
	local notes_enabled = self.db.profile.show_item_notes_tooltip or false
	local crafters_enabled = self.db.profile.show_crafters_tooltip or false
	if not notes_enabled and not crafters_enabled then
		return -- nothing to be added to the tooltip
	end
	-- get item name
	local name,link = tooltip:GetItem();
	if not link then 
		DA.DEBUG(0,"Error: Skillet:AddItemNotesToTooltip() could not determine link");
		return;
	end
	local id = self:GetItemIDFromLink(link);
	if not id then
		DA.DEBUG(0,"Error: Skillet:AddItemNotesToTooltip() could not determine id");
		return
	end
--	DA.DEBUG(1,"link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
	if notes_enabled then
		local header_added = false
		for player,notes_table in pairs(self.db.realm.notes) do
			local note = notes_table[id]
--			DA.DEBUG(1,"player= "..tostring(player)..", table= "..DA.DUMP1(notes_table)..", note= '"..tostring(note).."'")
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
	end
-- Blizzard's changes to trade links in 5.4 broke this code.
	if crafters_enabled then
		local crafters = self:GetCraftersForItem(id); -- current implementation always returns nil
		if crafters then
			local header_added = true
			local title_added = false
			for i,name in ipairs(crafters) do
				if not title_added then
					title_added = true
					tooltip:AddDoubleLine(L["Crafted By"], name)
				end
				DA.DEBUG(1,"name= '"..name.."'")
				tooltip:AddDoubleLine(" ", name)
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
	local r
	local player = playerOverride or self.currentPlayer
	local trade = tradeOverride or self.currentTrade
	local options = self.db.realm.options
	if not options or not options[player] or not options[player][trade] then
		r = Skillet.defaultOptions[option]
	elseif options[player][trade][option] == nil then
		r =  Skillet.defaultOptions[option]
	else
		r = options[player][trade][option]
	end
	--DA.DEBUG(0,"GetTradeSkillOption("..tostring(option)..", "..tostring(playerOverride)..", "..tostring(tradeOverride)..")= "..tostring(r)..", player= "..tostring(player)..", trade= "..tostring(trade))
	return r
end

-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(option, value, playerOverride, tradeOverride)
	local player = playerOverride or self.currentPlayer
	local trade = tradeOverride or self.currentTrade
	if not self.db.realm.options then
		self.db.realm.options = {}
	end
	if not self.db.realm.options[player] then
		self.db.realm.options[player] = {}
	end
	if not self.db.realm.options[player][trade] then
		self.db.realm.options[player][trade] = {}
	end
	self.db.realm.options[player][trade][option] = value
end

function ProfessionPopup_SelectPlayerTrade(menuFrame,player,tradeID)
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
	Skillet:SetTradeSkill(player,tradeID)
end

--[[ trade link sample
	|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:[<-{]+|h%[ - [%a%s]+%]|h|r] - ]      -- >
	[3273] = "|cffffd000|Htrade:3274:148:150:23F381A:zD<<t=|h[First Aid]|h|r", -- >

	Patch 5.4
		link |cffffd000|Htrade:010000000000D4C3:2550:333|h[Cooking]|h|r
	Patch 5.3
		addded Player Id and Recipe list (bitset)
		|cffffd000|Htrade:5000000027407E5:110406:600:600:8LPPYdAB|h[First Aid]|h|r
	Patch < 5.3
	link |cffffd000|Htrade:3274:400:450:23F381A:{{{{{{|h[First Aid]|h|r
]]

function ProfessionPopup_SelectTradeLink(menuFrame,player,tradeSkill)
	if player ~= (UnitName("player")) then  -- patch 5.4 issue
		DA.CHAT("Patch 5.4 issue: can't show tradeskill for "..player)
		return 
	end
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
	local _,tradeString
	local link = tradeSkill.link
	if Skillet.wowVersion >= 50400 then
		_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:%d+)")
	elseif Skillet.wowVersion >= 50300 then
		_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:%d+:%d+:[A-Za-z0-9+/:]+)")
	else
		_,_,tradeString = string.find(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")
	end	
	DA.DEBUG(0,"ProfessionPopup_SelectTradeLink ".." player="..player.." link="..link.." "..string.gsub(link,"\124","\124\124").." tradeString="..tradeString)
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
			local skillData = gatherModule.ScanPlayerTradeSkills(gatherModule, player)
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
					local rank, maxRank = list.rank, list.maxRank
					skillButton.text = Skillet:GetTradeName(tradeID).." |cff00ff00["..(rank or "?").."/"..(maxRank or "?").."]|r"
					skillButton.value = tradeID
					skillButton.icon = list.texture
					if gatherModule == SkilletLink then
						skillButton.arg1 = UIDROPDOWNMENU_MENU_VALUE
						skillButton.arg2 = Skillet.db.realm.tradeSkills[UIDROPDOWNMENU_MENU_VALUE][tradeID]
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
	ProfessionPopupFrame = CreateFrame("Frame", "ProfessionPopupFrame", _G["UIParent"], "UIDropDownMenuTemplate")
	Skillet.professionPopupButton = this
	UIDropDownMenu_Initialize(ProfessionPopupFrame, ProfessionPopup_Init, "MENU")
	ToggleDropDownMenu(1, nil, ProfessionPopupFrame, Skillet.professionPopupButton, Skillet.professionPopupButton:GetWidth(), 0)
end

-- workaround for Ace2
function Skillet:IsActive()
	return Skillet:IsEnabled()
end
