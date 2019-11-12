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

This file contains functions intended to be used by authors of other mods.
I will make every effort never to change the names or behaviour of any of the
methods listed in this file. All bets are off for methods in other files though.

If you would like to see a method added here that would benefit your mod, by all
means contact me and let me know.

While I have provided "Hooking" documentation, I do not recommend or support it's use.
I have left the documentation in this file for historical purposes. 
In the time since this file was first created, some newer methods of interfacing with
Skillet have been created. See the Skillet\Plugins folder for some examples.

Hooking a Method Using AceHook
------------------------------

To hook this routine with an Ace2 mod, use (for example):

	self:Hook(Skillet, "GetExtraItemDetailText")

and write your method:

	function MyMod:GetExtraItemDetailText(skill, recipe)
		-- get the previous value from the hook chain
		local before = self.hooks["GetExtraItemDetailText"](obj, skill, recipe)
		local myvalue = "samplething"
		if before then
			return before .. "\n" .. myvalue
		else
			return myvalue
		end
	end

Hooking a Method Without Using AceHook
--------------------------------------

local orig_get_extra = Skillet.GetExtraItemDetailText
Skillet.GetExtraItemDetailText = function(obj, skill, recipe)
	local before = orig_get_extra(obj, skill, recipe)
	local myvalue = "samplething"
	if before then
		return before .. "\n" .. myvalue
	else
		return myvalue
	end
end

In both methods, the 'obj' passed in will be a copy of the 'Skillet' main object.

Of course, the action you take with the previous value is entirely dependent
of what the method does. For methods that return text, you should probably
concatenetate the values. For something like Skillet:GetMinSkillButtonWidth()
you should return the maximum of the previous value and you value.

Please remember that there may be multple mods hooking these methods so please
be courteous and make sure not to discard their data, but rather combine it with
your own in as sane a fashion as possible.

]]

--=================================================================================
--                ******* Start of the public API ********
--
-- NOTE: This file documents functions that are defined (and used) in other
--       Skillet source files. The function line is copied here as a comment.
--=================================================================================

--
--== function Skillet:AddButtonToTradeskillWindow(button) ==
--
-- Adds a button to the tradeskill window. The button will be
-- reparented and placed appropriately in the window.
--
-- You should not hook this method, you should call it directly.
--
-- The frame representing the main tradeskill window will be
-- returned in case you need to pop up a frame attached to it.
--
--
--== function Skillet:AddRecipeSorter(text, sorter) ==
--
-- Adds a sort method to those used for recipe names.
--
-- You should not hook this method, you should call it directly.
--
-- With this method you can add your own custom sorting to the
-- list of recipes in the scrolling list.
--
-- @param text The name of you sorting method, will be shown to the
--        user in a drop-down menu
-- @param method Your sorting method (described below)
--
-- Your sorting method must have the following signature
--
--    function sort(tradeskill, index_a, index_b)
--
-- where:
--    tradeskill is the name of the currently selected tradeskill
--    index_a in the skill index of the first recipe
--    index_b is the skill index of the second recipe
--
-- Your method must return 'true' if a should be before b and 'false'
-- if a should be after b.
--

--
-- The following four functions, RecipeNamePrefix, RecipeNameSuffix, Update, and GetExtraText are
-- documented here but are used by plugins written like those in the Skillet\Plugins folder.
--
--== function plugin.RecipeNamePrefix(skill, recipe) ==
--
-- A function called to get text to prefix the name of the recipe in the scrolling list of recipes.
--
-- @param skill table containing name of the currently selected tradeskill (see documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (see documentation below)
--
-- @return text string (left side)
--
--
--== function plugin.RecipeNameSuffix(skill, recipe) ==
--
-- A function called to get text to append to the name of the recipe in the scrolling list of recipes
--
-- @param skill table containing name of the currently selected tradeskill (see documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (see documentation below)
--
-- @return text string (right side)
--
--== function plugin.Update() ==
--
-- A function called by the UpdateTradeSkillWindow function to do any plugin specific 
-- SkilletFrame updates. 
--
-- @return is ignored
--
--== function plugin.GetExtraText(skill, recipe) ==
--
-- A function called to display extra information about a recipe. Any text returned from this function
-- will be displayed in the recipe details frame when the user clicks on the recipe name.
-- The text will be added to the bottom the frame, after the list of reagents.
--
-- @param skill table containing name of the currently selected tradeskill (need to add documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (need to update documentation below)
--
-- @return label string (left side)
-- @return text string (right side)
--

--
--== function Skillet:AddPreButtonShowCallback(method) ==
--
-- Adds a method that will be called before a button in the recipe list
-- is shown. If multiple methods are added, they will be called in the
-- order they are registered.
--
-- The method you provide *must* have the following signature and behaviour:
--
--   function yourfunc(button, tradeskill, skillIndex, listOffset, recipeID)
--
--     where:
--        o button the button that is about to be displayed
--        o tradeskill the name of the currently selected tradeskill
--        o skillIndex the index of recipe this button is used for
--        o listOffset how far down in the scrolling this button is located.
--          No matter where the list is scrolled to, the first visible recipe
--          is at listOffset 0
--        o recipeID is the id of the recipe of this button
--
--     returns:
--        the button who's :Show() method is to be called
--
-- If you return your own button (instead of returning the button passed in),
-- you are responsible for attaching it properly in the list. The listOffset
-- parameter might be useful here as you could use this to determine the name
-- of the button immediately before this one in the list and attach to it.
--

--
--== function Skillet:AddPreButtonHideCallback(method) ==
--
-- Adds a method that will be called before a button in the recipe list
-- is hidden. If multiple methods are added, they will be called in the
-- order they are registered.
--
-- The method you provide *must* have the following signature and behaviour:
--
--   function yourfunc(button, tradeskill, skillIndex, listOffset)
--
--     where:
--        o button the button that is about to be displayed
--        o tradeskill the name of the currently selected tradeskill
--        o skillIndex the index of recipe thius button is used for
--        o listOffset how far down in the scrolling this button is located.
--          No matter where the list is scrolled to, the first visible recipe
--          is at listOffset 0
--
--     returns:
--        the button who's :Hide() method is to be called
--
-- If you return your own button (instead of returning the button passed in),
-- you are responsible for attaching it properly in the list. The listOffset
-- parameter might be useful here as you could use this to determine the name
-- of the button immediately before this one in the list and attach to it.
--

-- =================================================================
--                Skillet Recipe API
-- =================================================================

--[[

All data returned from theses methods is to be considered READ-ONLY

Data Formats
============

Skill = {
	["parentIndex"] = number
	["skillData"] = {table}
	["name"] = string
	["skillIndex"] = number
	["parent"] = {table}
	["depth"] = number
	["recipeID"] = number 
	["spellID"] = number (same as recipeID)
}

Recipe = {
	["name"] = string
	["numMade"] = number (how many this recipe make)
	["vendorOnly"] = boolean
	["itemID"] = number
	["tradeID"] = number
	["spellID"] = number
	["reagentData] = {table} with number of reagents for this recipe
		[index 1] = Reagent
		[index 2] = Reagent
		...
}

Reagent = {
	["reagentID"] = number
	["numNeeded"] = number

}

]]
