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
  Contains methods to upgrade Skillet from previous versions. This is
  for when I screw up the SavedVariables layout and need to fix it somehow.
]]--

-- Runs all the update functions, should they be required
function Skillet:UpgradeDataAndOptions()

    if SkilletDB.servers then
       SkilletDB.realms = SkilletDB.servers
	   SkilletDB.servers = nil

	   self.db = LibStub("AceDB-3.0"):New("SkilletDB")
    end

	if self.db.profile.transparency<0.1 or self.db.profile.transparency>1 then
		self.db.profile.transparency=1
	end

	if self.db.profile.scale<0.1 or self.db.profile.scale>2 then
		self.db.profile.scale=1
	end

    -- Upgrade from Skillet 1.2 and earlier where recipes where (stupidly)
    -- stored per-charcter where no one else could see them
    if self.db.char.recipes then
        self.db.char.recipes = nil
    end

	if self.db.realm.recipes then
        self.db.realm.recipes = nil
    end

    -- Update from Skillet 1.5 or earlier where profile options were
    -- actually stored per character
    if self.db.char.vendor_buy_button then
        self.db.profile.vendor_buy_button = self.db.char.vendor_buy_button
        self.db.char.vendor_buy_button = nil
    end
    if self.db.char.vendor_auto_buy then
        self.db.profile.vendor_auto_buy = self.db.char.vendor_auto_buy
        self.db.char.vendor_auto_buy = nil
    end
    if self.db.char.show_item_notes_tooltip then
        self.db.profile.show_item_notes_tooltip = self.db.char.show_item_notes_tooltip
        self.db.char.show_item_notes_tooltip = nil
    end
    if self.db.char.show_detailed_recipe_tooltip then
        self.db.profile.show_detailed_recipe_tooltip = self.db.char.show_detailed_recipe_tooltip
        self.db.char.show_detailed_recipe_tooltip = nil
    end
    if self.db.char.link_craftable_reagents then
        self.db.profile.link_craftable_reagents = self.db.char.link_craftable_reagents
        self.db.char.link_craftable_reagents = nil
    end

    -- Moved any recipe notes to the server level so all alts can see then
    if self.db.char.notes then
        self.db.realm.notes[UnitName("player")] = self.db.char.notes
        self.db.char.notes = nil
    end

end

