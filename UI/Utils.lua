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

-- Handy utilities for Skillet UI methods.

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
local Dialog = LibStub("LibDialog-1.0")

Dialog:Register("SKILLETMSG", {
	text = "",
	on_show = function(self, data)
		self.text:SetText(data.msg)
	end,
	buttons = {
		{
			text = OKAY,
		},
	},
	show_while_dead = true,
	hide_on_escape = true,
})

function Skillet:MessageBox(msg)
	Dialog:Spawn("SKILLETMSG", {
		msg = msg,
	})
end

Dialog:Register("SKILLETASKFOR", {
	text = "",
	on_show = function(self, data)
		self.text:SetText(data.msg)
	end,
	buttons = {
		{
			text = YES,
			on_click = function(self, data)
				data.handler()
			end,
		},
		{
			text = NO,
		},
	},
	show_while_dead = true,
	hide_on_escape = true,
})

function Skillet:AskFor(msg, handler)
	Dialog:Spawn("SKILLETASKFOR", {
		msg = msg,
		handler = handler,
	})
end

-- Adds resizing to a window. Resizing is both width and height from the
-- lower right corner only
function Skillet:EnableResize(frame, min_width, min_height, refresh_method)
	-- lets play the resize me game!
	frame:SetMinResize(min_width,min_height) -- magic numbers
	local sizer_se = CreateFrame("Frame", frame:GetName() .. "_SizerSoutheast", frame)
	sizer_se:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
	sizer_se:SetWidth(25)
	sizer_se:SetHeight(25)
	sizer_se:EnableMouse()
	sizer_se:SetScript("OnMouseDown", function(self)
		self:GetParent():StartSizing("BOTTOMRIGHT")
	end)
	sizer_se:SetScript("OnMouseUp", function(self)
		self:GetParent():StopMovingOrSizing()
		-- 'Skillet' is passed for the hidden 'self' variable
		pcall(refresh_method, Skillet)
	end)
	frame:SetScript("OnSizeChanged", function()
		-- 'Skillet' is passed for the hidden 'self' variable
		pcall(refresh_method, Skillet)
	end)

	-- Stole this from LibRockConfig (ya ckkinght!). Draws 3 diagonal lines in the
	-- lower right corner of the window
	local line1 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line1", "BACKGROUND")
	line1:SetWidth(14)
	line1:SetHeight(14)
	line1:SetPoint("BOTTOMRIGHT", -4, 4)
	line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 14/17
	line1:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)

	local line2 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line2", "BACKGROUND")
	line2:SetWidth(11)
	line2:SetHeight(11)
	line2:SetPoint("BOTTOMRIGHT", -4, 4)
	line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 11/17
	line2:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)

	local line3 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line3", "BACKGROUND")
	line3:SetWidth(8)
	line3:SetHeight(8)
	line3:SetPoint("BOTTOMRIGHT", -4, 4)
	line3:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 8/17
	line3:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)
end
