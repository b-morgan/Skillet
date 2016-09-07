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

local function Skillet_NOP()
	-- do nothing!
end

--=================================================================================
--                ******* Start of the public API ********
--=================================================================================

-- Adds a button to the tradeskill window. The button will be
-- reparented and placed appropriately in the window.
--
-- You should not hook this method, you should call it directly.
--
-- The frame representing the main tradeskill window will be
-- returned in case you need to pop up a frame attached to it.
function Skillet:AddButtonToTradeskillWindow(button)
	if not SkilletFrame.added_buttons then
		SkilletFrame.added_buttons = {}
	end
	button:Hide()
	-- See if this button has already been added ....
	for i=1, #SkilletFrame.added_buttons, 1 do
		if SkilletFrame.added_buttons[i] == button then
			-- ... yup
			return SkilletFrame
		end
	end
	-- ... nope
	table.insert(SkilletFrame.added_buttons, button)
	return SkilletFrame
end

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
function Skillet:AddRecipeSorter(text, sorter)
	self:internal_AddRecipeSorter(text, sorter)
end

--
-- A hook to get the reagent label
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param tradeskill name of the currently selected tradeskill
-- @param skillIndex the index of the currently selected recipe
-- @param recipeID the ID of the currently selected recipe
--
function Skillet:GetReagentLabel(tradeskill, skillIndex, recipeID)
	return SPELL_REAGENTS
end

--
-- A hook to get text to prefix the name of the recipe in the scrolling list of recipes.
-- If you hook this method, make sure to include any text you get from calling the hooked method.
-- This will allow more than one mod to use the hook.
--
-- This will be called for both crafts and tradeskills, you can use Skillet:IsCraft()
-- to determine if it's a craft. This avoid having to localize the tradeskill name just to
-- see if it is a craft or a tradeskill.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param skill table containing name of the currently selected tradeskill (see documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (see documentation below)
--
-- @return text string (left side)
--
function Skillet:GetRecipeNamePrefix(skill, recipe)
	local text
	return text
end

--
-- A hook to get text to append to the name of the recipe in the scrolling list of recipes
-- If you hook this method, make sure to include any text you get from calling the hooked method.
-- This will allow more than one mod to use the hook.
--
-- This will be called for both crafts and tradeskills, you can use Skillet:IsCraft()
-- to determine if it's a craft. This avoid having to localize the tradeskill name just to
-- see if it is a craft or a tradeskill.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param skill table containing name of the currently selected tradeskill (see documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (see documentation below)
--
-- @return text string (right side)
--
function Skillet:GetRecipeNameSuffix(skill, recipe)
	local text
	return text
end

--
-- A hook to display extra information about a recipe. Any text returned from this function
-- will be displayed in the recipe details frame when the user clicks on the recipe name.
-- The text will be added to the bottom the frame, after the list of reagents.
--
-- This will be called for both crafts and tradeskills, you can use Skillet:IsCraft()
-- to determine if it's a craft. This avoids having to localize the tradeskill name just to
-- see if it is a craft or a tradeskill.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param skill table containing name of the currently selected tradeskill (need to add documentation below)
-- @param recipe table containing the index and ID of the currently selected recipe (need to update documentation below)
--
-- @return label string (left side)
-- @return text string (right side)
--
function Skillet:GetExtraItemDetailText(skill, recipe)
end

--
-- Returns the minimum width of the skill button. This is the
-- button that displays the name of the recipe in the scrolling
-- list. If you were to add text to the button and need more room,
-- then hook this method and return a minimum width for the button
-- that works for your mod.
--
-- The hard limit is 165, any size below this will be ignored
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @return the minimum width allow for a recipe button
--
function Skillet:GetMinSkillButtonWidth()
end

--
-- Called immediately before the button containng the name of a
-- tradeskill recipe is displayed in the scrolling list
--
-- The value you return from this method (if not nil) will have it's
-- :Show() method called. You can return the button based in to have
-- Skillet's button shown, or you can return your own button.
--
-- If you return your own button, you are responsible for attaching
-- properly in the list. The listOffset parameter might be useful
-- here as you could use this to determine the name of the button
-- immediately before this one in the list and attach to it.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param button the button that is about to be displayed
-- @param tradeskill the name of the currently selected tradeskill
-- @param skillIndex the index of recipe thius button is used for
-- @param listOffset how far down in the scrolling this button is located.
--        No matter where the list is scrolled to, the first visible recipe
--        is at listOffset 0
-- @param recipeID the ID of the currently selected recipe
--
-- @return a button who's :Show() method is to be called. Use nil to have
--         the default button used.
--
function Skillet:BeforeRecipeButtonShow(button, tradeskill, skillIndex, listOffset, recipeID)
	-- these tests are in here to make sure that I don't
	-- accidentally break the hooking code.
	assert(button, "Button cannot be nil")
	assert(tradeskill  and tostring(tradeskill), "Tradeskill cannot be nil")
	assert(skillIndex and tonumber(skillIndex) and skillIndex > 0, "Recipe index cannot be nil")
	assert(listOffset and tonumber(listOffset) and listOffset > 0, "List offset cannot be nil")
	assert(recipeID and tonumber(recipeID) and recipeID >= 0, "Recipe ID cannot be nil")
	return button
end

--
-- Called immediately before the button containing the name of a
-- tradeskill recipe is hidden in the scrolling list
--
-- The value you return from this method (if not nil) will have it's
-- :Hide() method called. You can return the button based in to have
-- Skillet's button hidden, or you can return your own button.
--
-- If you return your own button, you are responsible for attaching
-- properly in the list. The listOffset parameter might be useful
-- here as you could use this to determine the name of the button
-- immediately before this one in the list and attach to it.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param button the button that is about to be hidden
-- @param tradeskill the name of the currently selected tradeskill
-- @param skillIndex the index of the recipe this button is used for
-- @param listOffset how far down in the scrolling this button is located.
--        No matter where the list is scrolled to, the first visible recipe
--        is at listOffset 0
--
-- @return a button who's :Hide() method is to be called. Use nil to have
--         the default button used.
--
function Skillet:BeforeRecipeButtonHide(button, tradeskill, skillIndex, listOffset)
	-- these tests are in here to make sure that I don't
	-- accidentally break the hooking code.
	assert(button, "Button cannot be nil")
	assert(tradeskill  and tostring(tradeskill), "Tradeskill cannot be nil")
	assert(skillIndex and tonumber(skillIndex) and skillIndex >= 0, "Recipe index cannot be nil")
	assert(listOffset and tonumber(listOffset) and listOffset >= 0, "List offset cannot be nil")
	return button
end

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
function Skillet:AddPreButtonShowCallback(method)
	assert(method and type(method) == "function",
		"Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
	self:internal_AddPreButtonShowCallback(method)
end

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
function Skillet:AddPreButtonHideCallback(method)
	assert(method and type(method) == "function",
		"Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
	self:internal_AddPreButtonHideCallback(method)
end

--
-- Shows the trade skill frame for the currently selected tradeskill or craft.
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be shown.
--
function Skillet:ShowTradeSkillWindow()
	return self:internal_ShowTradeSkillWindow()
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be hidden.
--
--
function Skillet:HideTradeSkillWindow()
	return self:internal_HideTradeSkillWindow()
end

--
-- Called to update the trade skill window. This will redraw the main
-- tradeskill window with the current settings.
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be updated.
--
function Skillet:UpdateTradeSkillWindow()
	return self:internal_UpdateTradeSkillWindow()
end

--
-- Hides any and all Skillet windows that are open
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- windows will not be hidden.
--
--
function Skillet:HideAllWindows()
	return self:internal_HideAllWindows()
end

--
-- Fills out and displays the shopping list frame
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be shown.
--
-- @param atBank whether or not we are displaying the shopping list at a bank
--
function Skillet:DisplayShoppingList(atBank)
	return self:internal_DisplayShoppingList(atBank)
end

--
-- Hides the shopping list window
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be hidden.
--
function Skillet:HideShoppingList()
	return self:internal_HideShoppingList()
end

--
-- Fills out and displays the ignored materials list frame
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be shown.
--
function Skillet:DisplayIgnoreList()
	return self:internal_DisplayIgnoreList()
end

--
-- Hides the ignored materials list window
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be hidden.
--
function Skillet:HideIgnoreList()
	return self:internal_HideIgnoreList()
end

--
-- Causes the list of recipes to be resorted. This should only be called
-- when the trade skill window is open.
--
-- You should not hook this method, you should call it directly.
--
--
-- returns the number of trade skills in the sorted and filtered list
function Skillet:SortAndFilterRecipes()
	return self:internal_SortAndFilterRecipes()
end

--
-- Can be hooked to add custom text to the tooltip
--
function Skillet:AddCustomTooltipInfo(tooltip, recipe)
end

--
-- Can be hooked customize counts column
--
function Skillet:CustomizeCountsColumn(recipe, countsButton)
end

-- =================================================================
--                Skillet Recipe API
-- =================================================================

--[[

All data returned from theses methods is to be considered READ-ONLY

Data Formats
============

Reagent = {
	["numNeeded"] = number
	["reagentID"] = number
}

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
	["nummade"] = number (how many this recipe make)
	["vendorOnly"] = boolean
	["itemID"] = number
	["tradeID"] = number
	["spellID"] = number
	["reagentData] = {table} with number of reagents for this recipe
		[index 1] = Reagent
		[index 2] = Reagent
		...
}

]]
