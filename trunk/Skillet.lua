local addonName,addonTable = ...
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
local MAJOR_VERSION = GetAddOnMetadata("Skillet-Classic", "Version");
local PACKAGE_VERSION = GetAddOnMetadata("Skillet-Classic", "X-Curse-Packaged-Version");
local ADDON_BUILD = (select(4, GetBuildInfo())) < 20000 and "Classic" or "Retail"
Skillet.version = MAJOR_VERSION
Skillet.package = PACKAGE_VERSION
Skillet.build = ADDON_BUILD
Skillet.project = WOW_PROJECT_ID
local isClassic = WOW_PROJECT_ID == 2

Skillet.isCraft = false			-- true for the Blizzard Craft UI, false for the Blizzard TradeSkill UI
Skillet.ignoreClose = false		-- when switching from the Craft UI to the TradeSkill UI, ignore the other's close.

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

local defaults = {
	profile = {
		-- user configurable options
		vendor_buy_button = true,
		vendor_auto_buy   = false,
		show_item_notes_tooltip = false,
		show_crafters_tooltip = true,
		show_detailed_recipe_tooltip = true,			-- show any tooltips?
		display_full_tooltip = true,					-- show full blizzards tooltip
		display_item_tooltip = true,					-- show item tooltip or recipe tooltip
		link_craftable_reagents = true,
		queue_craftable_reagents = true,
		queue_glyph_reagents = false,					-- not in Classic
		display_required_level = false,
		display_shopping_list_at_bank = true,
		display_shopping_list_at_guildbank = false,		-- not in Classic
		display_shopping_list_at_auction = true,
		use_blizzard_for_followers = false,				-- not in Classic
		hide_blizzard_frame = true,
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
	},
}

-- default options for each player/tradeskill

Skillet.defaultOptions = {
	["sortmethod"] = "None",
	["grouping"] = "Blizzard",
	["filtertext"] = "",
	["filterInventory-bag"] = true,
	["filterInventory-crafted"] = true,
	["filterInventory-vendor"] = true,
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
--[[
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
]]--
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
--[[
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
]]--
				display_shopping_list_at_auction = {
					type = "toggle",
					name = L["DISPLAYSHOPPINGLISTATAUCTIONNAME"],
					desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
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
						self:UpdateTradeSkillWindow()
					end,
					width = "double",
					order = 25,
				},
--[[
				use_blizzard_for_followers = {
					type = "toggle",
					name = L["USEBLIZZARDFORFOLLOWERSNAME"],
					desc = L["USEBLIZZARDFORFOLLOWERSDESC"],
					get = function()
						return Skillet.db.profile.use_blizzard_for_followers;
					end,
					set = function(self,value)
						Skillet.db.profile.use_blizzard_for_followers = value;
					end,
					width = "double",
					order = 26
				},
]]--
				hide_blizzard_frame = {
					type = "toggle",
					name = L["HIDEBLIZZARDFRAMENAME"],
					desc = L["HIDEBLIZZARDFRAMEDESC"],
					get = function()
						return Skillet.db.profile.hide_blizzard_frame;
					end,
					set = function(self,value)
						Skillet.db.profile.hide_blizzard_frame = value;
					end,
					width = "double",
					order = 26
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
					Skillet:InitializeDatabase(UnitName("player"))
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
					Skillet:InitializeDatabase(UnitName("player"))
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
		ignorelist = {
			type = 'execute',
			name = L["Ignored Materials List"],
			desc = L["IGNORELISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:DisplayIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 57
		},
		ignoreclear = {
			type = 'execute',
			name = L["Ignored Materials Clear"],
			desc = L["IGNORECLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 58
		},
		ignoreadd = {
			type = "input",
			name = "IgnoreAdd",
			desc = "Add to userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return Skillet.db.realm.userIgnoredMats[UnitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				Skillet.db.realm.userIgnoredMats[UnitName("player")][value] = 1
			end,
			order = 59
		},
		ignoredel = {
			type = "input",
			name = "IgnoreDel",
			desc = "Delete from userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return Skillet.db.realm.userIgnoredMats[UnitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				Skillet.db.realm.userIgnoredMats[UnitName("player")][value] = nil
			end,
			order = 60
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
		LogLevel = {
			type = "toggle",
			name = "LogLevel",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.LogLevel
			end,
			set = function(self,value)
				Skillet.db.profile.LogLevel = value
				Skillet.LogLevel = value
			end,
			order = 86
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
			order = 87
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
			order = 88
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
			order = 89
		},
		ProfileShow = {
			type = "toggle",
			name = "ProfileShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.ProfileShow
			end,
			set = function(self,value)
				Skillet.db.profile.ProfileShow = value
				Skillet.ProfileShow = value
			end,
			order = 90
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				SkilletDBPC = {}
				DA.DebugLog = SkilletDBPC
			end,
			order = 91
		},
		DebugStatus = {
			type = 'execute',
			name = "DebugStatus",
			desc = "Print Debug Status",
			func = function()
				DA.DebugAidsStatus()
			end,
			order = 92
		},
		DebugOff = {
			type = 'execute',
			name = "DebugOff",
			desc = "Turn Debug Off",
			func = function()
				if Skillet.db.profile.WarnShow then
					Skillet.db.profile.WarnShow = false
					Skillet.WarnShow = false
				end
				if Skillet.db.profile.WarnLog then
					Skillet.db.profile.WarnLog = false
					Skillet.WarnLog = false
				end
				if Skillet.db.profile.DebugShow then
					Skillet.db.profile.DebugShow= false
					Skillet.DebugShow = false
				end
				if Skillet.db.profile.DebugLogging then
					Skillet.db.profile.DebugLogging = false
					Skillet.DebugLogging = false
				end
--
-- DebugLevel is left alone but
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if Skillet.db.profile.LogLevel then
					Skillet.db.profile.LogLevel = false
					Skillet.LogLevel = false
				end
				if Skillet.db.profile.TraceShow then
					Skillet.db.profile.TraceShow = false
					Skillet.TraceShow = false
				end
				if Skillet.db.profile.TraceLog then
					Skillet.db.profile.TraceLog = false
					Skillet.TraceLog = false
				end
				if Skillet.db.profile.ProfileShow then
					Skillet.db.profile.ProfileShow = false
					Skillet.ProfileShow = false
				end
			end,
			order = 93
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
					SkilletStandaloneQueue:SetWidth(385);
					SkilletStandaloneQueue:SetHeight(240);
					SkilletStandaloneQueue:SetPoint("TOPLEFT",300,-150);
					local windowManager = LibStub("LibWindow-1.1")
					windowManager.SavePosition(SkilletFrame)
					windowManager.SavePosition(SkilletStandaloneQueue) 
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
	end
	if self.BlizzardCraftFrame == nil then
		if (not IsAddOnLoaded("Blizzard_CraftUI")) then
			LoadAddOn("Blizzard_CraftUI");
		end
		self.BlizzardCraftFrame = CraftFrame
		self.craftHide = CraftFrame:GetScript("OnHide")
		CraftFrame:SetScript("OnHide", nil)
		HideUIPanel(CraftFrame)
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
		ShowUIPanel(TradeSkillFrame)
	end
	if self.BlizzardCraftFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_CraftUI")) then
			LoadAddOn("Blizzard_CraftUI");
		end
		self.BlizzardCraftFrame = nil
		CraftFrame:SetScript("OnHide", Skillet.craftHide)
		Skillet.craftHide = nil
		ShowUIPanel(CraftFrame)
	end
end

-- Called when the addon is loaded
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

-- Clean up obsolete data
	if self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = nil
	end

-- Clean up if database is stale 
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
	self.wowVersion = wowVersion
--
-- Change the dataVersion when code changes obsolete 
-- the current saved variables database.
--
-- When Blizzard releases a new build, there's a chance that
-- recipes have changed (i.e. different reagent requirements) so
-- we clear the saved variables recipe data just to be safe.
--
	local dataVersion = 2
	if not self.db.global.dataVersion or self.db.global.dataVersion ~= dataVersion then
		self.db.global.dataVersion = dataVersion
		self:FlushAllData()
	elseif not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end

-- Initialize global data
	if not self.db.global.recipeDB then
		self.db.global.recipeDB = {}
	end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
--
-- Classic doesn't have a Guild Bank
-- Currently this only effects ShoppingList.lua
--
--[[
	if not self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = {}
	end
]]--
	self:InitializeDatabase(UnitName("player"))

-- Hook default tooltips
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

	Skillet.WarnShow = Skillet.db.profile.WarnShow
	Skillet.WarnLog = Skillet.db.profile.WarnLog
	Skillet.DebugShow = Skillet.db.profile.DebugShow
	Skillet.DebugLogging = Skillet.db.profile.DebugLogging
	Skillet.DebugLevel = Skillet.db.profile.DebugLevel
	Skillet.LogLevel = Skillet.db.profile.LogLevel
	Skillet.TableDump = Skillet.db.profile.TableDump
	Skillet.TraceShow = Skillet.db.profile.TraceShow
	Skillet.TraceLog = Skillet.db.profile.TraceLog
	Skillet.ProfileShow = Skillet.db.profile.ProfileShow
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
	Skillet.db.realm.bagData = {}
	Skillet.db.realm.bagDetails = {}
	Skillet.db.realm.bankData = {}
	Skillet.db.realm.bankDetails = {}
	Skillet.db.realm.userIgnoredMats = {}
	Skillet:FlushRecipeData()
end

function Skillet:FlushRecipeData()
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.realm.skillDB = {}
end

function Skillet:InitializeDatabase(player)
	DA.DEBUG(0,"initialize database for "..tostring(player))
	if self.linkedSkill or self.isGuild then  -- Avoid adding unnecessary data to savedvariables
		return
	end
	if player then
		if not self.db.realm.groupDB then
			self.db.realm.groupDB = {}
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
		if not self.db.realm.tradeSkills[player] then
			self.db.realm.tradeSkills[player] = {}
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
-- In Classic, you can't craft from the bank but
-- for debugging, having the contents of the bank could be useful.
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
--
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
			self:ScanPlayerTradeSkills(player)
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
	self:RegisterEvent("TRADE_SKILL_UPDATE")
	self:RegisterEvent("TRADE_SKILL_NAME_UPDATE")
	self:RegisterEvent("CRAFT_CLOSE")				-- craft event (could call SkilletClose)
	self:RegisterEvent("CRAFT_SHOW")				-- craft event (could call SkilletShow)
	self:RegisterEvent("CRAFT_UPDATE")				-- craft event
	self:RegisterEvent("UNIT_PET_TRAINING_POINTS")	-- craft event

	self:RegisterEvent("UNIT_INVENTORY_CHANGED") 	-- Not sure if this is helpful but we will track it.
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")		-- Not sure if this is helpful but we will track it.
	self:RegisterEvent("SPELLS_CHANGED")			-- Not sure if this is helpful but we will track it.

	self:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPADTE events for a specific action have been fired.
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
	self:RegisterEvent("BANKFRAME_CLOSED")
--[[
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
]]--
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	--
	-- Events needed to process the queue and to update
	-- the tradeskill window to update the number of items
	-- that can be crafted as we consume reagents.
	--
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	--
	-- Not sure these are needed for crafting but they
	-- are useful for debugging.
	--
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	--
	-- Debugging cleanup if enabled
	--
	self:RegisterEvent("PLAYER_LOGOUT")

	self.bagsChanged = true
	self.hideUncraftableRecipes = false
	self.hideTrivialRecipes = false
	self.currentTrade = nil
	self.selectedSkill = nil
	self.currentPlayer = UnitName("player")
	self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil
	-- run the upgrade code to convert any old settings
	self:UpgradeDataAndOptions()
	self:CollectTradeSkillData()
	self:UpdateAutoTradeButtons()
	self:EnablePlugins()
	self:DisableBlizzardFrame()
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

function Skillet:TRADE_SKILL_NAME_UPDATE()
	DA.DEBUG(4,"TRADE_SKILL_NAME_UPDATE")
	Skillet.isCraft = false
	if Skillet.linkedSkill then
		Skillet:SkilletShow()
	end
end

function Skillet:TRADE_SKILL_UPDATE()
	DA.DEBUG(4,"TRADE_SKILL_UPDATE")
	Skillet.isCraft = false
	if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
		Skillet:AdjustInventory()
	end
end

function Skillet:UNIT_PORTRAIT_UPDATE()
	DA.DEBUG(4,"UNIT_PORTRAIT_UPDATE")
end

function Skillet:SPELLS_CHANGED()
	DA.DEBUG(4,"SPELLS_CHANGED")
end

function Skillet:TRADE_SKILL_CLOSE()
	DA.DEBUG(4,"TRADE_SKILL_CLOSE")
	if Skillet.ignoreClose then
		Skillet.ignoreClose = false
		return
	end
	Skillet:SkilletClose()
	Skillet.isCraft = false
end

function Skillet:TRADE_SKILL_SHOW()
	DA.DEBUG(4,"TRADE_SKILL_SHOW")
	Skillet.isCraft = false
	Skillet:SkilletShow()
end

function Skillet:CRAFT_UPDATE()
	DA.DEBUG(4,"CRAFT_UPDATE")
	Skillet.isCraft = true
	if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
		Skillet:AdjustInventory()
	end
end

function Skillet:UNIT_PET_TRAINING_POINTS()
	DA.DEBUG(4,"UNIT_PET_TRAINING_POINTS")
end

function Skillet:CRAFT_CLOSE()
	DA.DEBUG(4,"CRAFT_CLOSE")
	if Skillet.ignoreClose then
		Skillet.ignoreClose = false
		return
	end
	Skillet:SkilletClose()
	Skillet.isCraft = false
end

function Skillet:CRAFT_SHOW()
	DA.DEBUG(4,"CRAFT_SHOW")
	Skillet.isCraft = true
	Skillet:SkilletShow()
end

-- Called when the addon is disabled
function Skillet:OnDisable()
	DA.DEBUG(0,"OnDisable()");
	self:UnregisterAllEvents()
	self:EnableBlizzardFrame()
end

function Skillet:IsTradeSkillLinked()
--[[
	local isGuild = IsTradeSkillGuild()
	local isLinked, linkedPlayer = IsTradeSkillLinked()
	DA.DEBUG(0,"IsTradeSkillLinked, isGuild="..tostring(isGuild)..", isLinked="..tostring(isLinked)..", linkedPlayer="..tostring(linkedPlayer))
	if isLinked or isGuild then
		if not linkedPlayer then
			if isGuild then
				linkedPlayer = "Guild Recipes" -- This can be removed when InitializeDatabase gets smarter.
			end
		end
		return true, linkedPlayer, isGuild
	end
]]--
	return false, nil, false
end

-- Show the tradeskill window, called from TRADE_SKILL_SHOW event, clicking on links, or clicking on guild professions
function Skillet:SkilletShow()
	DA.DEBUG(1,"SHOW WINDOW (was showing "..(self.currentTrade or "nil")..")");
	self.linkedSkill, self.currentPlayer, self.isGuild = Skillet:IsTradeSkillLinked()
	if self.linkedSkill then
		if not self.currentPlayer then
			return -- Wait for TRADE_SKILL_NAME_UPDATE
		end
	else
		self.currentPlayer = (UnitName("player"))
	end
	local name
	if self.isCraft then
		name = GetCraftDisplaySkillLine()
	else
		name = GetTradeSkillLine()
	end
	--DA.DEBUG(1,"name= '"..tostring(name).."'")
	self.currentTrade = self.tradeSkillIDsByName[name]
	if not self.linkedSkill and not self.isGuild then
		self:InitializeDatabase(self.currentPlayer)
	end 
	if self:IsSupportedTradeskill(self.currentTrade) then
		self:InventoryScan()
		DA.DEBUG(1,"SkilletShow: "..self.currentTrade)
		self.selectedSkill = nil
		self.dataScanned = false
		self:ScheduleTimer("SkilletShowWindow", 0.5)
		if Skillet.db.profile.hide_blizzard_frame then
			if self.isCraft then
				HideUIPanel(CraftFrame)
			else
				HideUIPanel(TradeSkillFrame)
			end
		end
	else
		self:HideAllWindows()
		if self.isCraft then
			ShowUIPanel(CraftFrame)
		else
			ShowUIPanel(TradeSkillFrame)
		end
	end
end

function Skillet:SkilletShowWindow()
	DA.DEBUG(0,"SkilletShowWindow, (was showing "..(self.currentTrade or "nil")..")");
	if IsControlKeyDown() then
		self.db.realm.skillDB[self.currentPlayer][self.currentTrade] = {}
	end
	if not self:RescanTrade() then
		if TSMAPI_FOUR then
			DA.CHAT("Conflict between Skillet-Classic and TradeSkillMaster")
		else
			DA.CHAT("No headers, try again")
		end
		return
	end
	self.currentGroup = nil
	self.currentGroupLabel = self:GetTradeSkillOption("grouping")
	self:RecipeGroupDropdown_OnShow()
	self:ShowTradeSkillWindow()
	local searchbox = _G["SkilletSearchBox"]
	local oldtext = searchbox:GetText()
	local filterText = self:GetTradeSkillOption("filtertext")
	-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
	if filterText ~= oldtext then
		searchbox:SetText(filterText)
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

function Skillet:BAG_OPEN(event, bagID) -- Fires when a non-inventory container is opened.
	DA.TRACE("BAG_OPEN( "..tostring(bagID).." )") -- We don't really care
end

function Skillet:BAG_CLOSED(event, bagID)        -- Fires when the whole bag is removed from 
	DA.TRACE("BAG_CLOSED( "..tostring(bagID).." )") -- inventory or bank. We don't really care. 
end

function Skillet:UNIT_INVENTORY_CHANGED(event, unit)
	--DA.TRACE("UNIT_INVENTORY_CHANGED( "..tostring(unit).." )")
	DA.DEBUG(4,"UNIT_INVENTORY_CHANGED("..tostring(unit)..")")
end

--
-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
--
function Skillet:TRADE_CLOSED()
	self:BAG_UPDATE("FAKE_BAG_UPDATE", 0)
end

local function indexBags()
	DA.DEBUG(4,"indexBags()")
	local player = Skillet.currentPlayer
	if player then
		local details = {}
		local data = {}
		local bags = {0,1,2,3,4}
		for _, container in pairs(bags) do
			for i = 1, GetContainerNumSlots(container), 1 do
				local item = GetContainerItemLink(container, i)
				if item then
					local _,count = GetContainerItemInfo(container, i)
					local id = Skillet:GetItemIDFromLink(item)
					local name = string.match(item,"%[.+%]")
					if name then 
						name = string.sub(name,2,-2)	-- remove the brackets
					else
						name = item						-- when all else fails, use the link
					end
					if id then
						table.insert(details, {
							["bag"] = container,
							["slot"] = i,
							["id"] = id,
							["name"] = name,
							["count"] = count,
						})
						if not data[id] then
							data[id] = 0
						end
						data[id] = data[id] + count
					end
				end
			end
		Skillet.db.realm.bagData[player] = data
		Skillet.db.realm.bagDetails[player] = details
		end
	end
end

--
-- So we can track when the players inventory changes and update craftable counts
--
function Skillet:BAG_UPDATE(event, bagID)
	DA.DEBUG(4,"BAG_UPDATE( "..bagID.." )")
	if bagID >= 0 and bagID <= 4 then
		self.bagsChanged = true -- an inventory bag update, do nothing until BAG_UPDATE_DELAYED.
	end
	if UnitAffectingCombat("player") then
		return
	end
	local showing = false
	if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
		showing = true
	end
	if self.shoppingList and self.shoppingList:IsVisible() then
		showing = true
	end
	if showing then
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

--
-- Event fires after all applicable BAG_UPDATE events for a specific action have been fired.
-- It doesn't happen as often as BAG_UPDATE so its a better event for us to use.
--
function Skillet:BAG_UPDATE_DELAYED(event)
	DA.DEBUG(4,"BAG_UPDATE_DELAYED")
	if Skillet.bagsChanged and not UnitAffectingCombat("player") then
		indexBags()
		Skillet.bagsChanged = false
	end
	if Skillet.bankBusy then
		DA.DEBUG(1,"BAG_UPDATE_DELAYED and bankBusy")
		Skillet.gotBagUpdateEvent = true
		if Skillet.gotBankEvent and Skillet.gotBagUpdateEvent then
			Skillet:UpdateBankQueue("bag update") -- Implemented in ShoppingList.lua
		end
	end
--[[
	if Skillet.guildBusy then
		DA.DEBUG(1,"BAG_UPDATE_DELAYED and guildBusy")
		Skillet.gotBagUpdateEvent = true
		if Skillet.gotGuildbankEvent and Skillet.gotBagUpdateEvent then
			Skillet:UpdateGuildQueue("bag update")
		end
	end
]]--
end

function Skillet:SetTradeSkill(player, tradeID, skillIndex)
	DA.DEBUG(0,"SetTradeSkill("..tostring(player)..", "..tostring(tradeID)..", "..tostring(skillIndex)..")")
	if player ~= self.currentPlayer then
		DA.DEBUG(0,"player not currentPlayer is not supported in Classic")
		return
	end
	if tradeID ~= self.currentTrade then
		local oldTradeID = self.currentTrade
		if self.skillIsCraft[oldTradeID] ~= self.skillIsCraft[TradeID] then
			self.ignoreClose = true
		end
		self.dataSource = "api"
		self.dataScanned = false
		self.currentGroup = nil
		self.currentGroupLabel = self:GetTradeSkillOption("grouping")
		self:RecipeGroupDropdown_OnShow()
		local spellName = self:GetTradeName(tradeID)
		DA.DEBUG(0,"cast: "..tostring(spellName))
		if spellName == "Mining" then spellName = "Smelting" end
		CastSpellByName(spellName) -- trigger the whole rescan process via a TRADE_SKILL_SHOW or CRAFT_SHOW event
	end
	self:SetSelectedSkill(skillIndex, false)
end

--[[
-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
	DA.DEBUG(0,"UpdateTradeSkill()")
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
		local searchbox = _G["SkilletSearchBox"];
		local filtertext = self:GetTradeSkillOption("filtertext", self.currentPlayer, new_trade)
		-- this fires off a redraw event, so only change after data has been acquired
		searchbox:SetText(filtertext);
	end
	DA.DEBUG(0,"UpdateTradeSkill complete")
end
]]--
-- Shows the trade skill frame.
function Skillet:ShowTradeSkillWindow()
	DA.DEBUG(0,"ShowTradeSkillWindow()")
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
	DA.DEBUG(0,"ShowTradeSkillWindow complete")
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:HideTradeSkillWindow()
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

-- Show the options window
function Skillet:ShowOptions()
	InterfaceOptionsFrame_Show()
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
	self:ConfigureRecipeControls(self.isCraft)				-- allow ALL trades to queue up items, but not Crafts
	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateSearch(text)
	DA.DEBUG(0,"UpdateSearch("..tostring(text)..")")
	self:SetTradeSkillOption("filtertext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(key)
	--DA.DEBUG(0,"GetItemNote("..tostring(key)..")")
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

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(key, note)
	--DA.DEBUG(0,"SetItemNote("..tostring(key)..", "..tostring(note)..")")
--	local id = self:GetItemIDFromLink(link);
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
--		DA.DEBUG(0,"Error: Skillet:AddItemNotesToTooltip() could not determine link");
		return;
	end
	local id = self:GetItemIDFromLink(link);
	if not id then
		DA.DEBUG(0,"Error: Skillet:AddItemNotesToTooltip() could not determine id");
		return
	end
	--DA.DEBUG(1,"link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
	if notes_enabled then
		local header_added = false
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
	if not self.linkedSkill and not self.isGuild then
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
end

-- workaround for Ace2
function Skillet:IsActive()
	return Skillet:IsEnabled()
end
