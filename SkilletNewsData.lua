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
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

Skillet.NewsName = "Skillet News"
Skillet.NewsData = {
	{	version = "5.33",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Separate skill level data into two files" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Shopping List", body = "Fix issue #98, items outside of frame" },
				},
			},
		},
	},
	{	version = "5.32",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "All", body = "Fix GetSpellInfo calls" },
				},
			},
		},
	},
	{	version = "5.31",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 110002" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Inventory", body = "Add Warband Bank" },
					{ header = "TradeSkills", body = "Fix TradeSkill buttons" },
				},
			},
		},
	},
	{	version = "5.30",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 110000" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "ShowOptions", body = "Fix ShowOptions()" },
					{ header = "Display required level", body = "Fix width when Grouping is 'Flat'" },
				},
			},
		},
	},
	{	version = "5.28",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100207" },
					{ header = "TOC", body = "Sync SkillLevelData with Skillet-Classic" },
				},
			},
		},
	},
	{	version = "5.27",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100206" },
				},
			},
		},
	},
	{	version = "5.26",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100205" },
				},
			},
		},
	},
	{	version = "5.25",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issues", body = "Fix attempt to perform arithmetic on local 'have' (a nil value)" },
				},
			},
		},
	},
	{	version = "5.24",
		data = {
			{	name = "New Features",
				data = {
					{ header = "Queuing", body = "Ignore queued reagents. Queuing recipes which share reagents will queue all of them" },
					{ header = "Shopping", body = "Ignore items on hand. The shopping list will reflect everything needed to process the queue" },
				},
			},
		},
	},
	{	version = "5.23",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100200" },
				},
			},
		},
	},
	{	version = "5.22",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100107" },
				},
			},
		},
	},
	{	version = "5.21",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC to 100105" },
				},
			},
		},
	},
	{	version = "5.20",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Clean up", body = "Move db.char to db.profile" },
					{ header = "Reagents", body = "Add more reagent slots" },
					{ header = "Required Reagents", body = "Add required reagents (optionals with required=true)" },
				},
			},
		},
	},
	{	version = "5.19",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Auctionator", body = "Fix plugin quality issues\nMove the Auctionator button" },
					{ header = "Queuing", body = "Add one at a time option\n    false = Queue items with modified reagents all at once\n    true  = Queue items with modified reagents one by one" },
				},
			},
		},
	},
	{	version = "5.18",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Cleanup", body = "Code Cleanup" },
				},
			},
		},
	},
	{	version = "5.17",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issues", body = "Fix scrolling" },
				},
			},
		},
	},
	{	version = "5.16",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Add addon icon" },
				},
			},
		},
	},
	{	version = "5.14",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "TOC", body = "Update TOC to 100100" },
				},
			},
			{	name = "New Features",
				data = {
					{ header = "Table", body = "Add customPrice table" },
					{ header = "Commands", body = "Add \"/skillet customadd\", \"/skillet customdel\", \"/skillet customshow\", \"/skillet customclear\"," },
					{ header = "Plugins", body = "Auctionator refactor code and use customPrice table for costs" },
				},
			},
		},
	},
	{	version = "5.13",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issues", body = "Fix #86, Blizzard Frame is invisible" },
				},
			},
		},
	},
	{	version = "5.10",
		data = {
			{	name = "New Features",
				data = {
					{ header = "Filter", body = "Add an option to display learned and unlearned recipes at the same time. Unlearned recipes will be prefixed with a '-' sign"},
					{ header = "Queue", body = "Add right-click on the \"Queue\" button to queue to the front" },
				},
			},
		},
	},
	{	version = "5.09",
		data = {
			{	name = "New Features",
				data = {
					{ header = "News", body = "Add News with options to display Always, Once (each version change) per Account, Once (each version change) per Player, and Never" },
					{ header = "Commands", body = "Add \"/skillet news\" to open (or close) the news frame" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Queuing", body = "Better queuing of modified craftable reagents" },
					{ header = "Tooltips", body = "Add tooltip to unselected salvage, optional, and finishing reagents" },
				},
			},
		},
	},
	{	version = "5.08",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issues", body = "Fix #84, fetch modified reagents from banks" },
				},
			},
		},
	},
	{	version = "5.07",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issues", body = "Fix #84, reorder local ShoppingList functions" },
				},
			},
		},
	},
	{	version = "5.06",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Titlebar", body = "Fix gradient" },
					{ header = "Shoppinglist", body = "Fix sort error" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Wago", body = "Add X-Wago-ID" },
					{ header = "Debug", body = "Add second level trace function" },
					{ header = "Plugins", body = "Add ProcessQueue plugin hook" },
					{ header = "Events", body = "Move bag events to ShoppingList.lua" },
				},
			},
		},
	},
	{	version = "5.05",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Titlebar", body = "Restore gradient" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Right-Click", body = "Move Salvage, Modified, Optional, and Finishing list opening to Right-Click (or Alt-Click)" },
					{ header = "Shift-Click", body = "Add links to Modified reagents" },
					{ header = "Left-Click", body = "Add open modified craftable reagents" },
					{ header = "Plugins", body = "Add ProcessQueue plugin hook" },
					{ header = "Events", body = "Move bag events to ShoppingList.lua" },
				},
			},
		},
	},
}