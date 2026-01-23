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
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

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
					width = "full",
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
					width = "full",
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
					width = "full",
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
					width = "full",
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
					width = "full",
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
					width = "full",
					order = 17
				},
				display_item_tooltip = {
					type = "toggle",
					name = L["SHOWITEMTOOLTIPNAME"],
					desc = L["SHOWITEMTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.display_item_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.display_item_tooltip = value
					end,
					width = "full",
					order = 18
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
					width = "full",
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
					width = 1.5,
					order = 20
				},
				ignore_banked_reagents = {
					type = "toggle",
					name = L["IGNOREBANKEDREAGENTSNAME"],
					desc = L["IGNOREBANKEDREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.ignore_banked_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.ignore_banked_reagents = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_queued_reagents = {
					type = "toggle",
					name = L["IGNOREQUEUEDREAGENTSNAME"],
					desc = L["IGNOREQUEUEDREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.ignore_queued_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.ignore_queued_reagents = value
					end,
					width = 1.5,
					order = 21
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
					width = "full",
					order = 22
				},
				queue_one_at_a_time = {
					type = "toggle",
					name = L["QUEUEONEATATIMENAME"],
					desc = L["QUEUEONEATATIMEDESC"],
					get = function()
						return Skillet.db.profile.queue_one_at_a_time
					end,
					set = function(self,value)
						Skillet.db.profile.queue_one_at_a_time = value
					end,
					width = "full",
					order = 23
				},
--[[
				queue_to_front = {
					type = "toggle",
					name = L["QUEUETOFRONTNAME"],
					desc = L["QUEUETOFRONTDESC"],
					get = function()
						return Skillet.db.profile.queue_to_front
					end,
					set = function(self,value)
						Skillet.db.profile.queue_to_front = value
					end,
					width = "full",
					order = 23
				},
--]]
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
					width = "full",
					order = 24
				},
				header = {
					type = "header",
					name = L["DISPLAYSHOPPINGLIST"],
					order = 25
				},
					display_shopping_list_at_bank = {
						type = "toggle",
						name = L["Bank"],
						desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_bank
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_bank = value
						end,
							width = 0.75,
						order = 26
					},
					display_shopping_list_at_guildbank = {
						type = "toggle",
						name = L["Guild bank"],
						desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_guildbank
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_guildbank = value
						end,
							width = 0.75,
						order = 27
					},
					display_shopping_list_at_auction = {
						type = "toggle",
						name = L["Auction"],
						desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_auction
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_auction = value
						end,
							width = 0.75,
						order = 28
					},
					display_shopping_list_at_merchant = {
						type = "toggle",
						name = L["Merchant"],
						desc = L["DISPLAYSHOPPINGLISTATMERCHANTDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_merchant
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_merchant = value
						end,
							width = 0.75,
						order = 29
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
					width = "full",
					order = 30
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
					width = "full",
					order = 31
				},
			}
		},
		appearance = {
			type = 'group',
			name = L["Appearance"],
			desc = L["APPEARANCEDESC"],
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
					width = "full",
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
					width = "full",
					order = 2
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
					width = "full",
					order = 3
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
					width = "full",
					order = 4
				},
				recipe_source_first = {
					type = "toggle",
					name = L["RECIPESOURCEFIRSTNAME"],
					desc = L["RECIPESOURCEFIRSTDESC"],
					get = function()
						return Skillet.db.profile.recipe_source_first
					end,
					set = function(self,value)
						Skillet.db.profile.recipe_source_first = value
					end,
					width = "full",
					order = 5
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
					width = "full",
					order = 6
				},
--[[
				use_blizzard_for_optional = {
					type = "toggle",
					name = L["USEBLIZZFOROPTIONNAME"],
					desc = L["USEBLIZZFOROPTIONDESC"],
					get = function()
						return Skillet.db.profile.use_blizzard_for_optional
					end,
					set = function(self,value)
						Skillet.db.profile.use_blizzard_for_optional = value
					end,
					width = "full",
					order = 7
				},
--]]
				always_show_progress_bar = {
					type = "toggle",
					name = L["SHOWPROGRESSBARNAME"],
					desc = L["SHOWPROGRESSBARDESC"],
					get = function()
						return Skillet.db.profile.always_show_progress_bar
					end,
					set = function(self,value)
						Skillet.db.profile.always_show_progress_bar = value
					end,
					width = "full",
					order = 8
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
					width = "full",
					order = 9
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
					width = "full",
					order = 10
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
					width = "full",
					order = 11
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
					width = "full",
					order = 12
				},
				tsm_compat = {
					type = "toggle",
					name = L["TSMCOMPATNAME"],
					desc = L["TSMCOMPATDESC"],
					get = function()
						return Skillet.db.profile.tsm_compat
					end,
					set = function(self,value)
						Skillet.db.profile.tsm_compat = value
					end,
					width = "full",
					order = 13
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
					width = "full",
					order = 14
				},
				sound_on_empty_queue = {
					type = "toggle",
					name = L["SOUNDONEMPTYQUEUENAME"],
					desc = L["SOUNDONEMPTYQUEUEDESC"],
					get = function()
						return Skillet.db.profile.sound_on_empty_queue
					end,
					set = function(self,value)
						Skillet.db.profile.sound_on_empty_queue = value
					end,
--					width = "full",
					width = 1.5,
					order = 15,
				},
				flash_on_empty_queue = {
					type = "toggle",
					name = L["FLASHONEMPTYQUEUENAME"],
					desc = L["FLASHONEMPTYQUEUEDESC"],
					get = function()
						return Skillet.db.profile.flash_on_empty_queue
					end,
					set = function(self,value)
						Skillet.db.profile.flash_on_empty_queue = value
					end,
--					width = "full",
					width = 1.5,
					order = 16,
				},
				sound_on_remove_queue = {
					type = "toggle",
					name = L["SOUNDONREMOVEQUEUENAME"],
					desc = L["SOUNDONREMOVEQUEUEDESC"],
					get = function()
						return Skillet.db.profile.sound_on_remove_queue
					end,
					set = function(self,value)
						Skillet.db.profile.sound_on_remove_queue = value
					end,
--					width = "full",
					width = 1.5,
					order = 17,
				},
				flash_on_remove_queue = {
					type = "toggle",
					name = L["FLASHONREMOVEQUEUENAME"],
					desc = L["FLASHONREMOVEQUEUEDESC"],
					get = function()
						return Skillet.db.profile.flash_on_remove_queue
					end,
					set = function(self,value)
						Skillet.db.profile.flash_on_remove_queue = value
					end,
--					width = "full",
					width = 1.5,
					order = 18,
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
					width = "full",
					order = 20
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
					width = "full",
					order = 21
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
					width = "full",
					order = 22
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
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
					if Skillet:IsShoppingListVisible() then
						Skillet:HideShoppingList()
					else
						Skillet:DisplayShoppingList(false)
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 55
		},
		flushcustomdata = {
			type = 'execute',
			name = "Flush Custom Data",
			desc = "Flush Custom Group Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushCustomData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 56
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 57
		},
		flushplayerdata = {
			type = 'execute',
			name = L["Flush Player Data"],
			desc = L["Flush Player Data"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushPlayerData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 58
		},
		flushdetaildata = {
			type = 'execute',
			name = "Flush Detail Data",
			desc = "Clear the collected bag, bank, guildbank details",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushDetailData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 59
		},
		collectdetails = {
			type = "toggle",
			name = "Collect details",
			desc = "Disable/Enable collecting bag, bank, guildbank details",
			get = function()
				return Skillet.db.profile.collect_details
			end,
			set = function(self,value)
				Skillet.db.profile.collect_details = value
			end,
			order = 60
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
			order = 61
		},
		ignorelist = {
			type = 'execute',
			name = L["Ignored Materials List"],
			desc = L["IGNORELISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:DisplayIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 62
		},
		ignoreclear = {
			type = 'execute',
			name = L["Ignored Materials Clear"],
			desc = L["IGNORECLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 63
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
			order = 64
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
			order = 65
		},
		resetrecipefilter = {
			type = 'execute',
			name = L["Reset Recipe Filter"],
			desc = L["RESETRECIPEFILTERDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ResetTradeSkillFilter()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 66
		},
		printsaved = {
			type = 'execute',
			name = "PrintSaved",
			desc = "Print list of SavedQueues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintSaved()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 67
		},
		printqueue = {
			type = 'execute',
			name = "PrintQueue",
			desc = "Print Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 68
		},
		printallqueues = {
			type = 'execute',
			name = "PrintAllQueues",
			desc = "Print All Player Queues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintAllQueues()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 68
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
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 69
		},
		clearqueue = {
			type = 'execute',
			name = "ClearQueue",
			desc = "Clear Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 70
		},
		printauction = {
			type = 'execute',
			name = "PrintAuctionData",
			desc = "Print Auction Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintAuctionData()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 71
		},
		printriq = {
			type = 'execute',
			name = "printriq",
			desc = "Print Reagents In Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintRIQ()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 72
		},
		printshop = {
			type = 'execute',
			name = "printshop",
			desc = "Print ShoppingList",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 73
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
					ShowUIPanel(ProfessionsFrame)
					Skillet.BlizzardUIshowing = true
				else
					HideUIPanel(ProfessionsFrame)
					Skillet.BlizzardUIshowing = false
				end
			end,
			order = 74
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
			order = 75
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
			order = 76
		},
		utsw = {
			type = 'execute',
			name = "UpdateTradeSkillWindow",
			desc = "Update (Skillet's) TradeSkill Window",
			func = function()
				Skillet:UpdateTradeSkillWindow()
			end,
			order = 77
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
			order = 78
		},
		nomodkeys = {
			type = "toggle",
			name = "NoModKeys",
			desc = "Disable/Enable Mod Keys to open the Blizzard frames",
			get = function()
				return Skillet.db.profile.nomodkeys
			end,
			set = function(self,value)
				Skillet.db.profile.nomodkeys = value
			end,
			order = 79
		},
		swapshiftkey = {
			type = "toggle",
			name = "SwapShiftKey",
			desc = "Swap Shift Key to open the Blizzard frames",
			get = function()
				return Skillet.db.profile.swapshiftkey
			end,
			set = function(self,value)
				Skillet.db.profile.swapshiftkey = value
			end,
			order = 80
		},
		news = {
			type = 'execute',
			name = "Display news",
			desc = "Display the news frame",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet.NewsGUI:Toggle()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 81
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
		TraceLog2 = {
			type = "toggle",
			name = "TraceLog2",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceLog2
			end,
			set = function(self,value)
				Skillet.db.profile.TraceLog2 = value
				Skillet.TraceLog2 = value
			end,
			order = 88
		},
		TraceLog3 = {
			type = "toggle",
			name = "TraceLog3",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceLog3
			end,
			set = function(self,value)
				Skillet.db.profile.TraceLog3 = value
				Skillet.TraceLog3 = value
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
				if Skillet.db.profile.TraceLog2 then
					Skillet.db.profile.TraceLog2 = false
					Skillet.TraceLog2 = false
				end
				if Skillet.db.profile.TraceLog3 then
					Skillet.db.profile.TraceLog3 = false
					Skillet.TraceLog3 = false
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
						SkilletShoppingList:SetHeight(240);
						SkilletShoppingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletShoppingList)
					end
					if SkilletIgnoreList and SkilletIgnoreList:IsVisible() then
						SkilletIgnoreList:SetWidth(320);
						SkilletIgnoreList:SetHeight(150);
						SkilletIgnoreList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletIgnoreList)
					end
					if SkilletOptionalList and SkilletOptionalList:IsVisible() then
						SkilletOptionalList:SetWidth(420);
						SkilletOptionalList:SetHeight(230);
						SkilletOptionalList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletOptionalList)
					end
					if SkilletModifiedList and SkilletModifiedList:IsVisible() then
						SkilletModifiedList:SetWidth(420);
						SkilletModifiedList:SetHeight(230);
						SkilletModifiedList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletModifiedList)
					end
					if SkilletSalvageList and SkilletSalvageList:IsVisible() then
						SkilletSalvageList:SetWidth(420);
						SkilletSalvageList:SetHeight(230);
						SkilletSalvageList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletSalvageList)
					end
					if SkilletFinishingList and SkilletFinishingList:IsVisible() then
						SkilletFinishingList:SetWidth(420);
						SkilletFinishingList:SetHeight(230);
						SkilletFinishingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletFinishingList)
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 99
		},
		BlizzOR = {
			type = "toggle",
			name = "BlizzOR",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.BlizzOR
			end,
			set = function(self,value)
				Skillet.db.profile.BlizzOR = value
				Skillet.BlizzOR = value
			end,
			order = 100
		},
--
-- If set, FakeIt will not execute C_TradeSkillUI.CraftRecipe
-- FakeIt is not stored in the saved variables file.
--
		FakeIt = {
			type = "toggle",
			name = "FakeIt",
			desc = "Option for debugging",
			get = function()
				return Skillet.FakeIt
			end,
			set = function(self,value)
				Skillet.FakeIt = value
				if Skillet.FakeIt then
					Skillet:Print(RED_FONT_COLOR_CODE.."FakeIt is on"..FONT_COLOR_CODE_CLOSE)
				else
					Skillet:Print(GREEN_FONT_COLOR_CODE.."FakeIt is off"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 101
		},
--
-- commands to manage the customPrice table
--
		customadd = {
			type = 'input',
			name = "customadd",
			desc = "Add a custom price for a reagent (customadd id|link,price)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local item, id, price, name, link
						local server = Skillet.data.server or 0
						DA.DEBUG(0,"value= "..value)
						item, price = string.split(",",value)
						if string.find(item,"|H") then
							id = Skillet:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = C_Item.GetItemInfo(id)
						price = tonumber(price)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", price= "..tostring(price)..", link= "..tostring(link))
						Skillet.db.global.customPrice[server][id] = { ["name"] = name, ["value"] = price }
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 105
		},
		customdel = {
			type = 'input',
			name = "customdel",
			desc = "Delete a custom reagent (customdel id|link)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local id
						local server = Skillet.data.server or 0
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = Skillet:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						Skillet.db.global.customPrice[server][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 106
		},
		customshow = {
			type = 'execute',
			name = "customshow",
			desc = "Print the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				for id,entry in pairs(Skillet.db.global.customPrice[server]) do
					print(tostring(entry.name)..", "..Skillet:FormatMoneyFull(entry.value,true))
				end
			end,
			order = 107
		},
		customdump = {
			type = 'execute',
			name = "customdump",
			desc = "Print the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				for id,entry in pairs(Skillet.db.global.customPrice[server]) do
					print("id= "..tostring(id)..", name= "..tostring(entry.name)..", value= "..tostring(entry.value))
				end
			end,
			order = 108
		},
		customclear = {
			type = 'execute',
			name = "customclear",
			desc = "Clear the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				Skillet.db.global.customPrice[server] = {}
			end,
			order = 109
		},
--
-- If set, MissAll will add all Merchant items to the MissingVendorItems table
-- MissAll is not stored in the saved variables file.
--
		MissAll = {
			type = "toggle",
			name = "MissAll",
			desc = "Option for debugging",
			get = function()
				return Skillet.MissAll
			end,
			set = function(self,value)
				Skillet.MissAll = value
				if Skillet.MissAll then
					Skillet:Print(RED_FONT_COLOR_CODE.."MissAll is on"..FONT_COLOR_CODE_CLOSE)
				else
					Skillet:Print(GREEN_FONT_COLOR_CODE.."MissAll is off"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 111
		},
--
-- commands to manage the MissingVendorItems table
--
		missingshow = {
			type = 'input',
			name = "missingshow",
			desc = "Print the MissingVendorItems table",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						DA.DEBUG(0,"value= "..value)
						local id
						for id,entry in pairs(Skillet.db.global.MissingVendorItems) do
							if type(entry) == 'table' then	-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
								if #entry ~= tonumber(value) then
									print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
								end
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 112
		},
		missingdel = {
			type = 'execute',
			name = "missingdel",
			desc = "Delete MissingVendorItems entries that are tables and not the correct size",
			func = function()
				if not (UnitAffectingCombat("player")) then
					if not Skillet.db.global.RemovedVendorItems then
						Skillet.db.global.RemovedVendorItems = {}
					end
					for id,entry in pairs(Skillet.db.global.MissingVendorItems) do
						if type(entry) == 'table' then
							local size = #entry
							if not (size == 5 or size == 9) then
								print("id= "..tostring(id)..", size= "..tostring(size)..", "..DA.DUMP(entry))
								Skillet.db.global.RemovedVendorItems[id] = entry
								Skillet.db.global.MissingVendorItems[id] = nil
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 113
		},
		missingclear = {
			type = 'execute',
			name = "missingclear",
			desc = "Clear the MissingVendorItems table",
			func = function()
				Skillet.db.global.MissingVendorItems = {}
			end,
			order = 114
		},
--
-- commands to manage the RemovedVendorItems table
--
		removedshow = {
			type = 'execute',
			name = "removedshow",
			desc = "Print the RemovedVendorItems table",
			func = function()
				if not (UnitAffectingCombat("player")) then
					if Skillet.db.global.RemovedVendorItems then
						for id,entry in pairs(Skillet.db.global.RemovedVendorItems) do
							print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction." ..
												  " Leave combat and try again.")
				end
			end,
			order = 116
		},
		removedclear = {
			type = 'execute',
			name = "removedclear",
			desc = "Clear the RemovedVendorItems table",
			func = function()
				Skillet.db.global.RemovedVendorItems = {}
			end,
			order = 117
		},
--
-- Debug options to deal with bag update events slowing bag and bank sorting
--
		bagevents = {
			type = "toggle",
			name = "bagevents",
			desc = "Option for debugging",
			get = function()
				return Skillet.BagEvents
			end,
			set = function(self,value)
				Skillet.BagEvents = value
				if Skillet.BagEvents then
					Skillet:UnregisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					Skillet:UnregisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					Skillet:UnregisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					Skillet:Print(RED_FONT_COLOR_CODE.."BAG_UPDATE events are off"..FONT_COLOR_CODE_CLOSE)
				else
					Skillet:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					Skillet:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					Skillet:RegisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					Skillet:Print(GREEN_FONT_COLOR_CODE.."BAG_UPDATE events are on"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 120
		},
		bagcounts = {
			type = 'execute',
			name = "bagcounts",
			desc = "Option for debugging",
			func = function()
				Skillet:Print("bagUpdateCounts= "..DA.DUMP1(Skillet.bagUpdateCounts))
				Skillet:Print("bagUpdateDelayedCount= "..tostring(Skillet.bagUpdateDelayedCount))
				Skillet:Print("unitInventoryChangedCount= "..tostring(Skillet.unitInventoryChangedCount))
				Skillet:Print("bankUpdateCount= "..tostring(Skillet.bankUpdateCount))
			end,
			order = 121
		},
		bagclear = {
			type = 'execute',
			name = "bagclear",
			desc = "Option for debugging",
			func = function()
				Skillet.bagUpdateCounts = {}
				Skillet.bagUpdateDelayedCount = 0
				Skillet.unitInventoryChangedCount = 0
				Skillet.bankUpdateCount = 0
			end,
			order = 122
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
	Skillet.optionsFrame, Skillet.categoryID = acedia:AddToBlizOptions("Skillet Features", "Skillet")
	acedia:AddToBlizOptions("Skillet Appearance", "Appearance", "Skillet")
	acedia:AddToBlizOptions("Skillet Profiles", "Profiles", "Skillet")
	acedia:AddToBlizOptions("Skillet Plugins", "Plugins", "Skillet")
end

--
-- Show the options window
--
function Skillet:ShowOptions()
--	Settings.OpenToCategory("Skillet")
	Settings.OpenToCategory(Skillet.categoryID)
end

