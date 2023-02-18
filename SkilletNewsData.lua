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

Skillet.NewsName = "Skillet News"
Skillet.NewsData = {
	{
		version = "5.09",
		data = {
			{
				name = "Changes",
				data = {
					{ header = "Hide in combat", body = "Bidding UI will now automatically hide in combat and show when out of combat. You can disable this behavior in configuration." },
					{ header = "Bidding UI Config reset", body = "Auto update bid values and close on bid settings were reset due to database restructure needed for hiding in combat. |cff44ee44Be sure to re-check your settings!|r" },
					{ header = "Auction", body = "Another batch of auction bugs fixes." },
					{ header = "Rounding", body = "Fixed missing rounding in point statistics." },
				},
			},
		},
	},
	{
		version = "5.08",
		data = {
			{
				name = "Fixes",
				data = {
					{ header = "Tax", body = "Tax is now properly applied." },
					{ header = "Invalid bid", body = "Invalid bid marking after award should now work properly." },
					{ header = "History UI", body = "You can now link history entry in chat. You can't select multiple entries anymore." },
					{ header = "Auctioning UI", body = "Auctioning UI won't open anymore outside UI when modifier-clicking on link or items." },
				},
			},
		},
	},
	{
		version = "5.07",
		data = {
			{
				name = "Hotfix",
				data = {
					{ header = "Bidding UI", body = "Bidding UI shouldn't error out on laggy servers anymore." },
				},
			},
		},
	},
	{
		version = "5.06",
		data = {
			{
				name = "Notes",
				data = {
					{ header = "Apache License 2.0", body = "Classic Loot Manager has been relicensed from MIT to Apache2. That means Skillet is still fully FOSS but now when reusing the code you not only need to attribute ownership to the Skillet creators but you also have to explicitly state which parts are reused and modified." },
					{ header = "v3.0.0", body = "Be sure to read v3.0.0 release note if you haven't yet!" },
				},
			},
			{
				name = "Changes",
				data = {
					{ header = "Moving items to the pending queue", body = "Auctioner UI behavior was modified slightly. When right clicking on items they are moved to the pending queue (the additonal queue that is hidden and populated automatically when current auction is in progress) instead of being removed. This means that after current auction is completed and cleared those will still show up. This allows players to easily utilize tracking if not auctioning all the items at the same time. You can still completely remove item from the queue through |ff44ee44Ctrl + Right click|r." },
				},
			},
			{
				name = "Fixes",
				data = {
					{ header = "Missing items", body = "Multi Item Auction should no longer have missing items or errors. You will notice that sometimes items might load with a slight delay which is expected on laggy realms." },
					{ header = "Boss Kill Bonus", body = "Ulduar boss encounter IDs are updated now per Blizzard changes and should work properly." },
				},
			},
		},
	},
	{
		version = "5.0",
		data = {
			{
				name = "Notes",
				data = {
					{ header = "Important!", body = "With Skillet v3 There comes a big mentality shift in the auctioning system towards becoming a more robust, point-based loot management framework. Notion of |cff44ee44English|r or |cff44ee44Swedish|r auction has been dropped towards bigger flexibility. This is a major change and as a consequence Skillet v2 communication is not compatible with Skillet v3 (but the database is preserved unlike when migrating from v1 to v2). Be aware that Skillet does not allow multiple MAJOR versions to be used in one guild thus all v2 users will have their Skillet disabled once someone starts to use v3."},
					{ header = "Thank you patrons!", body = "Thank you patrons, especially: |cffff8000Allcoast|r, |cffff8000BigSpoon|r, |cffff8000naimious|r, |cffff8000Nosirrahdrof|r" },
				},
			},
			{
				name = "Multi Item Auction",
				data = {
					{ header = "Notes", body = "Classic Loot Manager now allows you to auction virtually any amount of items simultaneously. There are however some quirks that need to be looked into by officers for this to work as expected." },
					{ header = "Configuration", body = "This rework brings some changes to auctioning configuration. Be sure to review them to ensure your auction is working as expected. Most significant changes are related to minimum, all-in and equal bids in Open Auction Mode." },
					{ header = "Invalid Bids", body = "Bids are validated during auction. However the correctness might not apply anymore after items were awarded. To solve this, after every item award, Skillet re-calculates if the bids would be accepted and marks invalid bid with red color. This way the bids are not lost and it's up to Loot Master to decide how to handle it." },
					{ header = "Rolling", body = "Skillet includes internal rolling system (random) that appends a new random value to players bid whenever a bid comes in for the first time. This value is guarnateed to be unique and is meant for the ML to help with solving ties. However it does not come from |cff44ee44/random|r server-side call thus is not visible in the chat." },
					{ header = "Handling items in the auction", body = "Items can be added to the auction same as previously through alt-click (configurable). In addition to that, the previous Loot Queue has been merged with Auctioning into auto-fill auction feature. Skillet can automatically add looted (received) items and items seen on corpse to the current auction. This can be configured per Master Looter prefference. Important! If items are added to auction during existing auction (manually or automatically) then Skillet will remember it in a pending auction and display them when current auction is cleared of all items. Auctioneer can manually remove items from auction by right clicking item icon on the list." },
					{ header = "Bidding GUI", body = "Bidding GUI was reworked and now is more flexible. You can move the bar separately (and even test it through |cff44ee44/Skillet testbar|r or through configuration button) and modify it's width. You should now more verbosely see if your bid was accepted, denied, or you passed or cancelled."},
					{ header = "Chat bidding", body = "Chat bidding is currently disabled." },
				},
			},
			{
				name = "Refinements",
				data = {
					{ header = "Hard Mode support", body = "Ulduar hard mode is now supported through configuration. If Boss Kill Bonus is enabled with normal and hardmode bonuses set to different (non-zero) values, after the kill a popup will show to decide if it was a normal or hard mode kill."},
					{ header = "History", body = "Loot history now shows simple history when hovering over items but more extensive if hovering while holding |cff44ee44CTRL|r modifier." },
					{ header = "Migration", body = "Migration should now be slightly more resilient when executed multiple times by accident." },
					{ header = "Renames", body = "Several options were renamed" },
					{ header = "Multi AddOn", body = "Classic Loot Manager is now split into multiple smaller addons. This is a first step towards even greater modularity. If you are using external |cff44ee44Integration|r you will need to enable that module first! Export is currently only accessible through |cff44ee44/Skillet export|r slash command." },
				},
			},
			{
				name = "Feedback",
				data = {
					{ header = "Please post your feedback", body = "Be sure to post feedback about the changes, suggestions and bug reports on our discord (link can be found in the configuration, README and github)." },
				},
			},
			{
				name = "Fixes",
				data = {
					{ header = "All-in", body = "All-in should no longer be denied unexpectedly." },
					{ header = "History error", body = "History should no longer get stuck on |cff44ee44Loading...|r or generate lua-error when handling old historical data." },
					{ header = "Alerts", body = "Alerts should now display proper currency." },
					{ header = "B.E.T.A.", body = "Fixed all bugs found during B.E.T.A. testing. Thank you all for participating!"},
				},
			},
			{
				name = "Known issues",
				data = {
					{ header = "Multi Item Auction", body = "Award value Multiplier is not stored nor configurable." },
					{ header = "Scaling", body = "Bidding GUI cannot be scaled at this time." },
					{ header = "GUI", body = "Bidding GUI still needs some refinements and might change anytime." },
					{ header = "ElvUI skins", body = "ElvUI bidding UI reskin might not be ideal. Best way to ensure the bidding UI looks properly you should not open the UI manually before first auction, otherwise `/reload` will be required for the UI to get fixed. Another option is to disable Ace3 reskin."}
				},
			},
		},
	},
}