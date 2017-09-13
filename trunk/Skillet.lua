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
Skillet.version = MAJOR_VERSION
Skillet.package = PACKAGE_VERSION

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

local defaults = {
	profile = {
		-- user configurable options
		vendor_buy_button = true,
		vendor_auto_buy   = false,
		show_item_notes_tooltip = false,
		show_crafters_tooltip = true,
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
					name = L["Skillet Trade Skills"].." "..Skillet.version,
					order = 11
				},
				vendor_buy_button = {
					type = "toggle",
					name = L["VENDORBUYBUTTONNAME"],
					desc = L["VENDORBUYBUTTONDESC"],
					get = function()
						return Skillet.db.profile.vendor_buy_button
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_buy_button = value
					end,
					width = "double",
					order = 12
				},
				vendor_auto_buy = {
					type = "toggle",
					name = L["VENDORAUTOBUYNAME"],
					desc = L["VENDORAUTOBUYDESC"],
					get = function()
						return Skillet.db.profile.vendor_auto_buy
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_auto_buy = value
					end,
					width = "double",
					order = 13
				},
				show_item_notes_tooltip = {
					type = "toggle",
					name = L["SHOWITEMNOTESTOOLTIPNAME"],
					desc = L["SHOWITEMNOTESTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_item_notes_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_item_notes_tooltip = value
					end,
					width = "double",
					order = 14
				},
				show_detailed_recipe_tooltip = {
					type = "toggle",
					name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
					desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_detailed_recipe_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_detailed_recipe_tooltip = value
					end,
					width = "double",
					order = 15
				},
				display_full_tooltip = {
					type = "toggle",
					name = L["SHOWFULLTOOLTIPNAME"],
					desc = L["SHOWFULLTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.display_full_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.display_full_tooltip = value
					end,
					width = "double",
					order = 16
				},
				link_craftable_reagents = {
					type = "toggle",
					name = L["LINKCRAFTABLEREAGENTSNAME"],
					desc = L["LINKCRAFTABLEREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.link_craftable_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.link_craftable_reagents = value
					end,
					width = "double",
					order = 19
				},
				queue_craftable_reagents = {
					type = "toggle",
					name = L["QUEUECRAFTABLEREAGENTSNAME"],
					desc = L["QUEUECRAFTABLEREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.queue_craftable_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.queue_craftable_reagents = value
					end,
					width = "double",
					order = 20
				},
				queue_glyph_reagents = {
					type = "toggle",
					name = L["QUEUEGLYPHREAGENTSNAME"],
					desc = L["QUEUEGLYPHREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.queue_glyph_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.queue_glyph_reagents = value
					end,
					width = "double",
					order = 21
				},
				display_shopping_list_at_bank = {
					type = "toggle",
					name = L["DISPLAYSHOPPINGLISTATBANKNAME"],
					desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
					get = function()
						return Skillet.db.profile.display_shopping_list_at_bank
					end,
					set = function(self,value)
						Skillet.db.profile.display_shopping_list_at_bank = value
					end,
					width = "double",
					order = 22
				},
				display_shopping_list_at_guildbank = {
					type = "toggle",
					name = L["DISPLAYSHOPPINGLISTATGUILDBANKNAME"],
					desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
					get = function()
						return Skillet.db.profile.display_shopping_list_at_guildbank
					end,
					set = function(self,value)
						Skillet.db.profile.display_shopping_list_at_guildbank = value
					end,
					width = "double",
					order = 23
				},
				display_shopping_list_at_auction = {
					type = "toggle",
					name = L["DISPLAYSHOPPINGLISTATAUCTIONNAME"],
					desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
					get = function()
						return Skillet.db.profile.display_shopping_list_at_auction
					end,
					set = function(self,value)
						Skillet.db.profile.display_shopping_list_at_auction = value
					end,
					width = "double",
					order = 24
				},
				display_shopping_list_at_merchant = {
					type = "toggle",
					name = L["DISPLAYSHOPPINGLISTATMERCHANTNAME"],
					desc = L["DISPLAYSHOPPINGLISTATMERCHANTDESC"],
					get = function()
						return Skillet.db.profile.display_shopping_list_at_merchant
					end,
					set = function(self,value)
						Skillet.db.profile.display_shopping_list_at_merchant = value
					end,
					width = "double",
					order = 25
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
					order = 26,
				},
				show_recipe_source_for_learned = {
					type = "toggle",
					name = L["SHOWRECIPESOURCEFORLEARNEDNAME"],
					desc = L["SHOWRECIPESOURCEFORLEARNEDDESC"],
					get = function()
						return Skillet.db.profile.show_recipe_source_for_learned
					end,
					set = function(self,value)
						Skillet.db.profile.show_recipe_source_for_learned = value
					end,
					width = "double",
					order = 28
				},
				use_guildbank_as_alt = {
					type = "toggle",
					name = L["USEGUILDBANKASALTNAME"],
					desc = L["USEGUILDBANKASALTDESC"],
					get = function()
						return Skillet.db.profile.use_guildbank_as_alt
					end,
					set = function(self,value)
						Skillet.db.profile.use_guildbank_as_alt = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "double",
					order = 29
				},
				use_altcurrency_vendor_items = {
					type = "toggle",
					name = L["USEALTCURRVENDITEMSNAME"],
					desc = L["USEALTCURRVENDITEMSDESC"],
					get = function()
						return Skillet.db.profile.use_altcurrency_vendor_items
					end,
					set = function(self,value)
						Skillet.db.profile.use_altcurrency_vendor_items = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "double",
					order = 30
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
				show_max_upgrade = {
					type = "toggle",
					name = L["SHOWMAXUPGRADENAME"],
					desc = L["SHOWMAXUPGRADEDESC"],
					get = function()
						return Skillet.db.profile.show_max_upgrade
					end,
					set = function(self,value)
						Skillet.db.profile.show_max_upgrade = value
					end,
					width = "double",
					order = 2
				},
				use_blizzard_for_followers = {
					type = "toggle",
					name = L["USEBLIZZARDFORFOLLOWERSNAME"],
					desc = L["USEBLIZZARDFORFOLLOWERSDESC"],
					get = function()
						return Skillet.db.profile.use_blizzard_for_followers
					end,
					set = function(self,value)
						Skillet.db.profile.use_blizzard_for_followers = value
					end,
					width = "double",
					order = 3
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
					order = 4,
				},
				confirm_queue_clear = {
					type = "toggle",
					name = L["CONFIRMQUEUECLEARNAME"],
					desc = L["CONFIRMQUEUECLEARDESC"],
					get = function()
						return Skillet.db.profile.confirm_queue_clear
					end,
					set = function(self,value)
						Skillet.db.profile.confirm_queue_clear = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "double",
					order = 5,
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
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "double",
					order = 10,
				},
				scale = {
					type = "range",
					name = L["Scale"],
					desc = L["SCALEDESC"],
					min = 0.1, max = 1.50, step = 0.05, isPercent = true,
					get = function()
						return Skillet.db.profile.scale
					end,
					set = function(self,t)
						Skillet.db.profile.scale = t
						Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "double",
					order = 11,
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
		resetrecipefilter = {
			type = 'execute',
			name = L["Reset Recipe Filter"],
			desc = L["RESETRECIPEFILTERDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ResetTradeSkillFilter()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 61
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
			name = "DebugLogging",
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
			order = 89
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				SkilletDBPC = {}
				DA.DebugLog = SkilletDBPC
			end,
			order = 90
		},
		DebugStatus = {
			type = 'execute',
			name = "DebugStatus",
			desc = "Print Debug Status",
			func = function()
				DA.DebugAidsStatus()
			end,
			order = 91
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
			order = 92
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
			order = 93
		},
		MaxDebug = {
			type = "input",
			name = "MaxDebug",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.MAXDEBUG
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 4000 end
				Skillet.db.profile.MAXDEBUG = value
				Skillet.MAXDEBUG = value
			end,
			order = 94
		},
		MaxProfile = {
			type = "input",
			name = "MaxProfile",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.MAXPROFILE
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 2000 end
				Skillet.db.profile.MAXPROFILE = value
				Skillet.MAXPROFILE = value
			end,
			order = 95
		},

		reset = {
			type = 'execute',
			name = L["Reset"],
			desc = L["RESETDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					SkilletFrame:SetWidth(710);
					SkilletFrame:SetHeight(545);
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
		self.tradeSkillHide = TradeSkillFrame:GetScript("OnHide")
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
	else
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
	end
end

function Skillet:EnableBlizzardFrame()
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

-- Clean up if database is stale
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
	self.wowVersion = wowVersion
	if not self.db.global.dataVersion or self.db.global.dataVersion ~= 8 then
		self.db.global.dataVersion = 8
		self:FlushAllData()
	elseif not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end

-- Initialize global data
	self.db.global.version = self.version	-- save a copy for
	self.db.global.package = self.package	-- post-mortem purposes
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
	if not self.db.global.Categories then
		self.db.global.Categories = {}
	end
	if not self.db.global.MissingVendorItems then
		self:InitializeMissingVendorItems()
	end
	if not self.db.global.AdjustNumMade then
		self.db.global.AdjustNumMade = {}
	end
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
	acecfg:RegisterOptionsTable("Skillet Plugins", Skillet.pluginsOptions)
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet Features", "Skillet")
	acedia:AddToBlizOptions("Skillet Appearance", "Appearance", "Skillet")
	acedia:AddToBlizOptions("Skillet Profiles", "Profiles", "Skillet")
	acedia:AddToBlizOptions("Skillet Plugins", "Plugins", "Skillet")

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
	Skillet.LogLevel = Skillet.db.profile.LogLevel
	Skillet.MAXDEBUG = Skillet.db.profile.MAXDEBUG or 4000
	Skillet.MAXPROFILE = Skillet.db.profile.MAXPROFILE or 2000
	Skillet.TableDump = Skillet.db.profile.TableDump
	Skillet.TraceShow = Skillet.db.profile.TraceShow
	Skillet.TraceLog = Skillet.db.profile.TraceLog
	Skillet.ProfileShow = Skillet.db.profile.ProfileShow
end

function Skillet:FlushAllData()
	Skillet.data = {}
	Skillet.db.realm.tradeSkills = {}
	Skillet.db.realm.groupDB = {}
	Skillet.db.realm.queueData = {}
	Skillet.db.realm.auctionData = {}
	Skillet.db.realm.reagentsInQueue = {}
	Skillet.db.realm.inventoryData = {}
	Skillet.db.realm.userIgnoredMats = {}
	Skillet:FlushRecipeData()
	Skillet:InitializeMissingVendorItems()
end

function Skillet:FlushRecipeData()
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.global.Categories = {}
	if Skillet.data and Skillet.data.recipeInfo then
		Skillet.data.recipeInfo = {}
	end
end

-- MissingVendorItem entries can be a string when bought with gold or a table when bought with an alternate currency
-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
function Skillet:InitializeMissingVendorItems()
	self.db.global.MissingVendorItems = {
		[30817] = "Simple Flour",
		[4539]  = "Goldenbark Apple",
		[17035] = "Stranglethorn Seed",
		[17034] = "Maple Seed",
		[52188] = "Jeweler's Setting",
		[4399]	= "Wooden Stock",
		[38682] = "Enchanting Vellum",
		[3857]	= "Coal",
	}
end

function Skillet:InitializeDatabase(player)
	DA.DEBUG(0,"initialize database for "..tostring(player))
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
		if player == UnitName("player") then
			if not self.db.realm.inventoryData then
				self.db.realm.inventoryData = {}
			end
			if not self.db.realm.inventoryData[player] then
				self.db.realm.inventoryData[player] = {}
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
	DA.DEBUG(0,"Skillet:OnEnable()");
	-- Hook into the events that we care about
	-- Trade skill window changes
	self:RegisterEvent("TRADE_SKILL_CLOSE")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_NAME_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGING")
	self:RegisterEvent("TRADE_SKILL_DETAILS_UPDATE")
	self:RegisterEvent("TRADE_SKILL_FILTER_UPDATE")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS", "SkilletShowGuildCrafters")
	self:RegisterEvent("GARRISON_TRADESKILL_NPC_CLOSED")
	self:RegisterEvent("BAG_UPDATE") -- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED") -- Fires after all applicable BAG_UPADTE events for a specific action have been fired.
	-- MERCHANT_* events needed for auto buying.
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")
	-- May need to show a shopping list when at the bank/guildbank/auction house
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
	self:RegisterEvent("PLAYER_LOGOUT")
--	self:RegisterEvent("UNIT_SPELLCAST_START")
--	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
--	self:RegisterEvent("UNIT_SPELLCAST_STOP")
--	self:RegisterEvent("CHAT_MSG_SKILL")
	self:RegisterEvent("SKILL_LINES_CHANGED") -- replacement for CHAT_MSG_SKILL?
	self:RegisterEvent("LEARNED_SPELL_IN_TAB") -- arg1 = professionID
	self:RegisterEvent("NEW_RECIPE_LEARNED") -- arg1 = recipeID

	self.hideUncraftableRecipes = false
	self.hideTrivialRecipes = false
	self.currentTrade = nil
	self.selectedSkill = nil
	self.currentPlayer = UnitName("player")
	self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil
	self.dataScanned = false
	-- run the upgrade code to convert any old settings
	self:UpgradeDataAndOptions()
	self:CollectTradeSkillData()
	self:CollectCurrencyData()
	self:EnablePlugins()
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

function Skillet:CHAT_MSG_SKILL()	-- Replaced by SKILL_LINES_CHANGED?
	DA.DEBUG(0,"CHAT_MSG_SKILL")
	if Skillet.tradeSkillOpen then
		Skillet:ScanTrade()
		Skillet:UpdateTradeSkillWindow()
	end
end

function Skillet:SKILL_LINES_CHANGED()
	--DA.DEBUG(0,"SKILL_LINES_CHANGED")
	if Skillet.tradeSkillOpen then
--		Skillet:ScanTrade()
--		Skillet:UpdateTradeSkillWindow()
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function Skillet:LEARNED_SPELL_IN_TAB(event, profession)
	DA.DEBUG(0,"LEARNED_SPELL_IN_TAB")
	DA.DEBUG(0,"profession= "..tostring(profession))
	if Skillet.tradeSkillOpen then
		Skillet:ScanTrade()					-- Untested
		Skillet:UpdateTradeSkillWindow()	-- Untested
	end
end

function Skillet:NEW_RECIPE_LEARNED(event, recipeID)
	DA.DEBUG(0,"NEW_RECIPE_LEARNED")
	DA.DEBUG(0,"recipeID= "..tostring(recipeID))
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function Skillet:TRADE_SKILL_SHOW()
	DA.DEBUG(0,"TRADE_SKILL_SHOW")
	Skillet.dataSourceChanged = false
	Skillet.detailsUpdate = false
	Skillet.skillListUpdate = false
	Skillet.adjustInventory = false
	Skillet:SkilletShow()
end

function Skillet:TRADE_SKILL_CLOSE()
	DA.DEBUG(0,"TRADE_SKILL_CLOSE")
	Skillet:SkilletClose()
	Skillet.dataSourceChanged = false
	Skillet.detailsUpdate = false
	Skillet.skillListUpdate = false
	Skillet.adjustInventory = false
end

function Skillet:TRADE_SKILL_DATA_SOURCE_CHANGED()
	DA.DEBUG(0,"TRADE_SKILL_DATA_SOURCE_CHANGED")
	DA.DEBUG(0,"tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
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
	DA.DEBUG(0,"TRADE_SKILL_DATA_SOURCE_CHANGING")
	DA.DEBUG(0,"tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	if Skillet.tradeSkillOpen then
		Skillet:SkilletShow()
	end
end

function Skillet:TRADE_SKILL_DETAILS_UPDATE()
	DA.DEBUG(0,"TRADE_SKILL_DETAILS_UPDATE")
	DA.DEBUG(0,"tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	if Skillet.tradeSkillOpen then
		Skillet.detailsUpdate = true
		Skillet:ScanTrade()
		Skillet:UpdateTradeSkillWindow()
	end
end

function Skillet:TRADE_SKILL_FILTER_UPDATE()
	DA.DEBUG(0,"TRADE_SKILL_FILTER_UPDATE")
end

function Skillet:TRADE_SKILL_LIST_UPDATE()
	DA.DEBUG(0,"TRADE_SKILL_LIST_UPDATE")
	DA.DEBUG(0,"tradeSkillOpen= "..tostring(Skillet.tradeSkillOpen))
	DA.DEBUG(0,"dataSourceChanged= "..tostring(Skillet.dataSourceChanged))
	DA.DEBUG(0,"adjustInventory= "..tostring(Skillet.adjustInventory))
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
	DA.DEBUG(0,"TRADE_SKILL_NAME_UPDATE")
	DA.DEBUG(0,"linkedSkill= "..tostring(Skillet.linkedSkill))
	if Skillet.linkedSkill then
		Skillet:SkilletShow()
	end
end

function Skillet:GARRISON_TRADESKILL_NPC_CLOSED()
	DA.DEBUG(0,"GARRISON_TRADESKILL_NPC_CLOSED")
end

-- Called when the addon is disabled
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

-- Show the tradeskill window, called from TRADE_SKILL_SHOW event, clicking on links, or clicking on guild professions
function Skillet:SkilletShow()
	DA.DEBUG(0,"SkilletShow: (was showing "..tostring(self.currentTrade)..")");
	self.linkedSkill, self.currentPlayer, self.isGuild = self:IsTradeSkillLinked()
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
	end
	self:ScanPlayerTradeSkills(self.currentPlayer)
	self:UpdateAutoTradeButtons()
	local skillLineID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier = C_TradeSkillUI.GetTradeSkillLine();
	DA.DEBUG(0,"SkilletShow: skillLineName= "..tostring(skillLineName)..", skillLineRank= "..tostring(skillLineRank)..
		", skillLineRank= "..tostring(skillLineRank)..", skillLineModifier= "..tostring(skillLineModifier))
	self.currentTrade = self.tradeSkillIDsByName[skillLineName]
	DA.DEBUG(0,"SkilletShow: trade= "..tostring(self.currentTrade))
	local link = C_TradeSkillUI.GetTradeSkillListLink()
	if link then
		DA.DEBUG(0,"SkilletShow: link= "..link..", "..DA.PLINK(link))
	else
		DA.DEBUG(0,"SkilletShow: "..tostring(skillLineName).." not linkable")
	end
	-- Use the Blizzard UI for any garrison follower that can't use ours.
	if self:IsNotSupportedFollower(self.currentTrade) then
		self:HideAllWindows()
		self:EnableBlizzardFrame()
		ShowUIPanel(TradeSkillFrame)
	else
		if self:IsSupportedTradeskill(self.currentTrade) then
			self:DisableBlizzardFrame()
			self:InitializeDatabase(self.currentPlayer)
			self.tradeSkillOpen = true
			self.selectedSkill = nil
			self.dataScanned = false
			self:SetTradeSkillLearned()
--			self:SkilletShowWindow() -- Need to wait until TRADE_SKILL_DATA_SOURCE_CHANGED
		else
			self:HideAllWindows()
			self:EnableBlizzardFrame()
			ShowUIPanel(TradeSkillFrame)
		end
	end
end

function Skillet:SkilletShowWindow()
	DA.DEBUG(0,"SkilletShowWindow: "..tostring(self.currentTrade))
	if self.tradeSkillOpen then
		HideUIPanel(TradeSkillFrame)
	end
	if not self:RescanTrade() then
		DA.DEBUG(0,"No headers, reset filter")
		self.ResetTradeSkillFilter()
		if not self:RescanTrade() then
			DA.CHAT("No headers, try again");
			return
		end
	end
	self.currentGroup = nil
	self.currentGroupLabel = self:GetTradeSkillOption("grouping")
	self.dataSource = "api"
	self:RecipeGroupDropdown_OnShow()
	self:ShowTradeSkillWindow()
	local searchbox = _G["SkilletSearchBox"]
	local oldtext = searchbox:GetText()
	local searchText = self:GetTradeSkillOption("searchtext")
	-- if the text is changed, set the new text (which fires off an update)
	if searchText ~= oldtext then
		searchbox:SetText(searchText)
	end
end

function Skillet:SkilletClose()
	DA.DEBUG(0,"SKILLET CLOSE")
	self.tradeSkillOpen = false
	if self.dataSource == "api" then -- if the skillet system is using the api for data access, then close the skillet window
		self:HideAllWindows()
		if Skillet.wasNPCCrafting then
			DA.DEBUG(0,"wasNPCCrafting")
			C_Garrison.CloseGarrisonTradeskillNPC()
			C_Garrison.CloseTradeskillCrafter()
		end
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

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE(event, bagID)
	--DA.DEBUG(0,"BAG_UPDATE( "..bagID.." )")
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
		self:InventoryScan()
		self:UpdateShoppingListWindow()
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
		self.currentPlayer = player
		local oldTradeID = self.currentTrade
		if player == (UnitName("player")) then	-- we can update the tradeskills if this toon is the current one
			self.dataSource = "api"
			self.dataScanned = false
			self.currentGroup = nil
			self.currentGroupLabel = self:GetTradeSkillOption("grouping")
			self:RecipeGroupDropdown_OnShow()
			local orig = self:GetTradeName(tradeID)
			local spellID = tradeID
			if tradeID == 2575 then spellID = 2656 end		-- Ye old Mining vs. Smelting issue
			local spell = self:GetTradeName(spellID)
			DA.DEBUG(0,"SetTradeSkill: orig= "..tostring(orig).." ("..tostring(tradeID).."), spell= "..tostring(spell).." ("..tostring(spellID)..")")
			CastSpellByName(spell)		-- this will trigger the whole rescan process via a TRADE_SKILL_SHOW event
			Skillet.delaySelectedSkill = true
			Skillet.delaySkillIndex = skillIndex
		else
			self.dataSource = "cache"
			CloseTradeSkill()
			self.dataScanned = false
			self:HideNotesWindow();
			self.currentTrade = tradeID
			self.currentGroup = nil
			self.currentGroupLabel = self:GetTradeSkillOption("grouping")
			self:RecipeGroupGenerateAutoGroups()
			self:RecipeGroupDropdown_OnShow()
			if not self.data.skillList[tradeID] then
				self.data.skillList[tradeID] = {}
			end
			-- remove any filters currently in place
			local searchbox = _G["SkilletSearchBox"]
			local oldtext = searchbox:GetText()
			local searchText = self:GetTradeSkillOption("searchtext")
			-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
			if searchText ~= oldtext then
				searchbox:SetText(searchText)
			else
				self:UpdateTradeSkillWindow()
			end
		end
	end
	self:SetSelectedSkill(skillIndex)
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
		local searchbox = _G["SkilletSearchBox"];
		local searchtext = self:GetTradeSkillOption("searchtext", self.currentPlayer, new_trade)
		-- this fires off a redraw event, so only change after data has been acquired
		searchbox:SetText(searchtext);
	end
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
	--DA.DEBUG(0,"internal_ShowTradeSkillWindow")
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
function Skillet:internal_HideTradeSkillWindow()
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
	self:SetSelectedSkill(nil)
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skillIndex)
	--DA.DEBUG(0,"SetSelectedSkill("..tostring(skillIndex)..")")
	self:HideNotesWindow()
	self:ConfigureRecipeControls(false)
	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
	self:ClickSkillButton(skillIndex)
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
	DA.DEBUG(0,"UpdateFilter("..tostring(text)..")")
	self:SetTradeSkillOption("searchtext", text)
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
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine link")
		return;
	end
	local id = self:GetItemIDFromLink(link)
	if not id then
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine id from "..DA.PLINK(link))
		return
	end
	--DA.DEBUG(1,"link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
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
	end
	return header_added
end

function Skillet:ToggleTradeSkillOption(option)
	local v = self:GetTradeSkillOption(option)
	self:SetTradeSkillOption(option, not v)
end

-- Returns the state of a craft specific option
function Skillet:GetTradeSkillOption(option)
	local r
	local player = self.currentPlayer
	local trade = self.currentTrade
	local options = self.db.realm.options
	if not options or not options[player] or not options[player][trade] then
		r = Skillet.defaultOptions[option]
	elseif options[player][trade][option] == nil then
		r =  Skillet.defaultOptions[option]
	else
		r = options[player][trade][option]
	end
	return r
end

-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(option, value)
	if not self.linkedSkill and not self.isGuild then
		local player = self.currentPlayer
		local trade = self.currentTrade
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
