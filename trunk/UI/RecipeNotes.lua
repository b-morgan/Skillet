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

SKILLET_NOTES_ITEM_DISPLAYED = 7
SKILLET_NOTES_ITEM_HEIGHT    = SKILLET_TRADE_SKILL_HEIGHT * 3

local L = AceLibrary("AceLocale-2.2"):new("Skillet")
local NO_NOTE = GRAY_FONT_COLOR_CODE .. L["click here to add a note"] .. FONT_COLOR_CODE_CLOSE

local editbox;
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- Called when the list of skills is scrolled
function Skillet:NotesList_OnScroll()
	Skillet:UpdateNotesWindow()
end

-- Shows the recipe notes editor for the current window
function Skillet:ShowRecipeNotes()
	local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
	if not s then
		return
	end

	local frame = SkilletRecipeNotesFrame
	if frame then
		self.recipeNotesFrame = SkilletRecipeNotesFrame
	else
		return
	end

	if frame:IsVisible() then
		-- make it a toggle? why not
		frame:Hide()
		return
	end

	self:UpdateNotesWindow()
	frame:Show()

end

local function get_edit_box()
	local editbox = CreateFrame("EditBox", nil, nil)
	editbox:SetTextInsets(5,5,3,3)
	editbox:SetMaxLetters(256)
	editbox:SetAutoFocus(true)
	editbox:SetMultiLine(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetBackdrop(ControlBackdrop)
	editbox:SetBackdropColor(0,0,0,1)

	editbox:SetScript("OnEnterPressed", function()
		this:Hide()
		local b = this:GetParent()
		local l = b:GetAttribute("recipe_link")
		local n = getglobal(b:GetName() .. "Notes")

		local skillet = this.obj

		skillet:SetItemNote(l, this:GetText())
		n:Show();
		skillet:UpdateNotesWindow()
	end);
	editbox:SetScript("OnEscapePressed", function()
		this:Hide()

		local b = this:GetParent()
		local n = getglobal(b:GetName() .. "Notes")
		n:Show()
	end);

	return editbox
end

function Skillet:RecipeNote_OnClick(button)
	-- update the window so we know that we are starting from a known good location
	self:UpdateNotesWindow()

	local link = button:GetAttribute("recipe_link")

	local notesObject = getglobal(button:GetName() .. "Notes")
	local notes = notesObject:GetText();

	if not editbox then
		editbox = get_edit_box()
	end

	editbox:SetParent(button)
	editbox:SetAllPoints(notesObject);
	editbox:SetFrameStrata("HIGH")

	if notes ~= NO_NOTE then
		editbox:SetText(notes);
		editbox:HighlightText()
	else
		editbox:SetText("");
	end

	editbox.obj = self;

	notesObject:Hide();
	editbox:Show()
	editbox:SetFocus()
end

-- Updates the notes window with the current data.
-- This should display the notes for the recipe item itself and for
-- any reagents that are needed
--
-- XXX: and tools?
function Skillet:UpdateNotesWindow()
	local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
	if not s then
		return
	end

	if editbox then
		editbox:Hide()
	end

	SkilletRecipeNotesFrameLabel:SetText(L["Notes"]);

	local numItems = 1 + #s

	-- Update the scroll frame
	FauxScrollFrame_Update(SkilletNotesList,			    -- frame
	                       numItems,                        -- num items
	                       SKILLET_NOTES_ITEM_DISPLAYED,    -- num to display
	                       SKILLET_NOTES_ITEM_HEIGHT)       -- value step (item height)

	-- Where in the list of skill to start counting.
	local offset = FauxScrollFrame_GetOffset(SkilletNotesList);

	-- now do all that nasty work to fill in the contents of the frame

	for i=1, SKILLET_NOTES_ITEM_DISPLAYED, 1 do
		local index = i + offset

		local button = getglobal("SkilletNotesButton"..i)

		if index <= numItems then
			local text   = getglobal(button:GetName() .. "Text");
			local icon   = getglobal(button:GetName() .. "Icon");
			local notes  = getglobal(button:GetName() .. "Notes");

			-- set the width based on whether or not the scroll bar is displayed
			if ( SkilletNotesList:IsShown() ) then
				button:SetWidth(170)
			else
				button:SetWidth(190)
			end

			local link;

			if index == 1 then
				-- notes for the recipe itself
				text:SetText(s.name)
				icon:SetNormalTexture(s.texture)
				link = s.link
			else
				-- notes for a reagent
				text:SetText(s[index-1].name)
				icon:SetNormalTexture(s[index-1].texture)
				link = s[index-1].link
			end

			button:SetAttribute("recipe_link", link)
			notes_text = self:GetItemNote(link)

			if notes_text then
				notes:SetText(notes_text)
			else
				notes:SetText(NO_NOTE)
			end

			text:Show()
			icon:Show()
			notes:Show()
			button:Show()
		else
			button:Hide()
		end

	end
end

--
-- Hide the Skillet notes window, it it was open
--
function Skillet:HideNotesWindow()
    local closed

    if self.recipeNotesFrame and self.recipeNotesFrame:IsVisible() then
        HideUIPanel(self.recipeNotesFrame);
        closed = true
    end

    return closed
end