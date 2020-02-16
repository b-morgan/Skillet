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

--
-- All the options that we allow the user to control.
--
local MAJOR_VERSION = GetAddOnMetadata("Skillet", "Version");

--
-- All the options that we allow the user to control.
--
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
				show_crafters_tooltip = {
					type = "toggle",
					name = L["SHOWCRAFTERSTOOLTIPNAME"],
					desc = L["SHOWCRAFTERSTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_crafters_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_crafters_tooltip = value
					end,
					width = "double",
					order = 15
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
					order = 16
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
					order = 17
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
						Skillet:UpdateTradeSkillWindow()
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
				queue_only_view = {
					type = "toggle",
					name = L["QUEUEONLYVIEWNAME"],
					desc = L["QUEUEONLYVIEWDESC"],
					get = function()
						return Skillet.db.profile.queue_only_view
					end,
					set = function(self,value)
						Skillet.db.profile.queue_only_view = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "double",
					order = 5,
				},
				dialog_switch = {
					type = "toggle",
					name = L["DIALOGSWITCHNAME"],
					desc = L["DIALOGSWITCHDESC"],
					get = function()
						return Skillet.db.profile.dialog_switch
					end,
					set = function(self,value)
						Skillet.db.profile.dialog_switch = value
					end,
					width = "double",
					order = 6,
				},
				scale_tooltip = {
					type = "toggle",
					name = L["SCALETOOLTIPNAME"],
					desc = L["SCALETOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.scale_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.scale_tooltip = value
					end,
					width = "double",
					order = 7,
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
					order = 10,
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
					order = 11,
				},
				ttscale = {
					type = "range",
					name = L["Tooltip Scale"],
					desc = L["TOOLTIPSCALEDESC"],
					min = 0.1, max = 1.25, step = 0.05, isPercent = true,
					get = function()
						return Skillet.db.profile.ttscale
					end,
					set = function(self,t)
						Skillet.db.profile.ttscale = t
						Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow(false)
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "double",
					order = 12,
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
		printsaved = {
			type = 'execute',
			name = "PrintSaved",
			desc = "Print list of SavedQueues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintSaved()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 62
		},
		printqueue = {
			type = 'execute',
			name = "PrintQueue",
			desc = "Print Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 63
		},
		printsavedqueue = {
			type = 'input',
			name = "PrintSavedQueue",
			desc = "Print Named Saved Queue",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintQueue(value)
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 64
		},
		clearqueue = {
			type = 'execute',
			name = "ClearQueue",
			desc = "Clear Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 65
		},
		printauction = {
			type = 'execute',
			name = "PrintAuctionData",
			desc = "Print Auction Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintAuctionData()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 66
		},
--
-- commands to toggle Blizzard's frames (beats using "/run")
--
		btsui = {
			type = "toggle",
			name = "BTSUI",
			desc = "Show/Hide the Blizzard TradeSkill frame",
			get = function()
				return Skillet.data.btsui
			end,
			set = function(self,value)
				Skillet.data.btsui = value
				if value then
					ShowUIPanel(TradeSkillFrame)
				else
					HideUIPanel(TradeSkillFrame)
				end
			end,
			order = 68
		},
		bcui = {
			type = "toggle",
			name = "BCUI",
			desc = "Show/Hide the Blizzard Crafting frame",
			get = function()
				return Skillet.data.bcui
			end,
			set = function(self,value)
				Skillet.data.bcui = value
				if value then
					ShowUIPanel(CraftFrame)
				else
					HideUIPanel(CraftFrame)
				end
			end,
			order = 69
		},
--
-- commands to update Skillet's main windows
--
		uslw = {
			type = 'execute',
			name = "UpdateShoppingListWindow",
			desc = "Update (Skillet's) Shopping List Window",
			func = function()
				Skillet:UpdateShoppingListWindow(false)
			end,
			order = 71
		},
		utsw = {
			type = 'execute',
			name = "UpdateTradeSkillWindow",
			desc = "Update (Skillet's) TradeSkill Window",
			func = function()
				Skillet:UpdateTradeSkillWindow()
			end,
			order = 72
		},
--
-- command to turn on/off custom groups 
-- (i.e. panic/debug button if they aren't working)
--
		customgroups = {
			type = "toggle",
			name = "CustomGroups",
			desc = "Enable / Disable Custom Groups button",
			get = function()
				return Skillet.data.customgroups
			end,
			set = function(self,value)
				Skillet.data.customgroups = value
				if value then
					SkilletRecipeGroupOperations:Enable()
				else
					SkilletRecipeGroupOperations:Disable()
				end
			end,
			order = 73
		},
--
-- additional database flush commands
--
		flushcustomdata = {
			type = 'execute',
			name = "Flush Custom Data",
			desc = "Flush Custom Group Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushCustomData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 74
		},
		flushqueuedata = {
			type = 'execute',
			name = "Flush Queue Data",
			desc = "Flush Queue Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushQueueData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 75
		},

--
-- commands to manipulate the state of debugging code flags
-- (See DebugAids.lua)
--
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
		ClearProfileLog = {
			type = "execute",
			name = "ClearProfileLog",
			desc = "Option for debugging",
			func = function()
				SkilletProfile = {}
				DA.DebugProfile = SkilletProfile
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
			order = 94
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
			order = 95
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
			order = 96
		},
		FixBugs = {
			type = "toggle",
			name = "FixBugs",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.FixBugs
			end,
			set = function(self,value)
				Skillet.db.profile.FixBugs = value
				Skillet.FixBugs = value
				if value then
					Skillet.db.profile.TraceLog = value
					Skillet.TraceLog = value
				end
			end,
			order = 97
		},
		DebugMark = {
			type = 'input',
			name = "DebugMark",
			desc = "Adds a comment to logs",
			get = function()
			end,
			set = function(self,value)
				DA.MARK(value)
			end,
			order = 98
		},

--
-- command to reset the position of the major Skillet frames
--
		reset = {
			type = 'execute',
			name = L["Reset"],
			desc = L["RESETDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					local windowManager = LibStub("LibWindow-1.1")
					if SkilletFrame and SkilletFrame:IsVisible() then
						SkilletFrame:SetWidth(750);
						SkilletFrame:SetHeight(580);
						SkilletFrame:SetPoint("TOPLEFT",200,-100);
						windowManager.SavePosition(SkilletFrame)
					end
						if SkilletStandaloneQueue and SkilletStandaloneQueue:IsVisible() then
						SkilletStandaloneQueue:SetWidth(385);
						SkilletStandaloneQueue:SetHeight(170);
						SkilletStandaloneQueue:SetPoint("TOPLEFT",950,-100);
						windowManager.SavePosition(SkilletStandaloneQueue)
					end
					if SkilletShoppingList and SkilletShoppingList:IsVisible() then
						SkilletShoppingList:SetWidth(385);
						SkilletShoppingList:SetHeight(170);
						SkilletShoppingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletShoppingList)
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 99
		},
	}
}

function Skillet:ConfigureOptions()
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
end

local function get_panel_name(panel)
	local tp = type(panel)
	local cat = INTERFACEOPTIONS_ADDONCATEGORIES
	if tp == "string" then
		for i = 1, #cat do
			local p = cat[i]
			if p.name == panel then
				if p.parent then
					return get_panel_name(p.parent)
				else
					return panel
				end
			end
		end
	elseif tp == "table" then
		for i = 1, #cat do
			local p = cat[i]
			if p == panel then
				if p.parent then
					return get_panel_name(p.parent)
				else
					return panel.name
				end
			end
		end
	end
end

local doNotRun
local function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
	if doNotRun or InCombatLockdown() then return end
	local panelName = get_panel_name(panel)
	if not panelName then return end -- if its not part of our list return early
	local noncollapsedHeaders = {}
	local shownpanels = 0
	local mypanel
	local t = {}
	local cat = INTERFACEOPTIONS_ADDONCATEGORIES
	for i = 1, #cat do
		local panel = cat[i]
		if not panel.parent or noncollapsedHeaders[panel.parent] then
			if panel.name == panelName then
				panel.collapsed = true
				t.element = panel
				InterfaceOptionsListButton_ToggleSubCategories(t)
				noncollapsedHeaders[panel.name] = true
				mypanel = shownpanels + 1
			end
			if not panel.collapsed then
				noncollapsedHeaders[panel.name] = true
			end
			shownpanels = shownpanels + 1
		end
	end
	local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
	if shownpanels > 15 and Smin < Smax then
		local val = (Smax/(shownpanels-15))*(mypanel-2)
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
	end
	doNotRun = true
	InterfaceOptionsFrame_OpenToCategory(panel)
	doNotRun = false
end

--
-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
--
function Skillet:FixOpenToCategory()
	if (not IsAddOnLoaded("!BlizzBugsSuck")) then
		DA.DEBUG(0,"FixOpenToCategory executed")
		hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
	else
		DA.DEBUG(0,"FixOpenToCategory skipped")
	end
end

