local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
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
]]
local PT = LibStub("LibPeriodicTable-3.1")
local L = Skillet.L

--[[
	Hooks for Ackis Recipe List (ARL)
]]--
SkilletARL = {}
local ARLProfessionInitialized = {}

local function initFilterButton(name, icon, parent, slot)
	local b = CreateFrame("CheckButton", name)
	b:SetWidth(20)
	b:SetHeight(20)
	b:SetParent(parent)
	b:SetNormalTexture(icon)
	b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetFrameLevel(parent:GetFrameLevel()+5)
	b:SetScript("OnEnter", function(button) SkilletARL:RecipeFilterButton_OnEnter(button) end)
	b:SetScript("OnLeave", function(button) SkilletARL:RecipeFilterButton_OnLeave(button) end)
	b:SetScript("OnClick", function(button) SkilletARL:RecipeFilterButton_OnClick(button) end)
	b:SetScript("OnShow", function(button) SkilletARL:RecipeFilterButton_OnShow(button) end)
	b.slot = slot
	return b
end

function SkilletARL:RecipeFilterButtons_Hide()
	local b = self.arlRecipeSourceButton
	if b then
		b.trainerButton:Hide()
		b.vendorButton:Hide()
		b.questButton:Hide()
		b.dropButton:Hide()
		b.mobButton:Hide()
		b.unknownButton:Hide()
	end
end

function SkilletARL:RecipeFilterButtons_Show()
	local b = self.arlRecipeSourceButton
	if b then
		b.trainerButton:Show()
		b.vendorButton:Show()
		b.questButton:Show()
		b.dropButton:Show()
		b.mobButton:Show()
		b.unknownButton:Show()
	end
end

function SkilletARL:RecipeFilterButton_OnClick(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	Skillet:ToggleTradeSkillOption(option)
	self:RecipeFilterButton_OnEnter(button)
	self:RecipeFilterButton_OnShow(button)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function SkilletARL:RecipeFilterButton_OnEnter(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	local value = Skillet:GetTradeSkillOption(option)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	if value then
		GameTooltip:SetText(slot.." on")
	else
		GameTooltip:SetText(slot.." off")
	end
--	GameTooltip:AddLine(player,1,1,1)
	GameTooltip:Show()
end

function SkilletARL:RecipeFilterButton_OnLeave(button)
	GameTooltip:Hide()
end

function SkilletARL:RecipeFilterButton_OnShow(button)
	local slot = button.slot or ""
	local option = "recipeSourceFilter-"..slot
	local value = Skillet:GetTradeSkillOption(option)
	if value then
		button:SetChecked(true)
	else
		button:SetChecked(false)
	end
end

function SkilletARL:RecipeFilterToggleButton_OnShow(button)
	local filter = Skillet:GetTradeSkillOption("recipeSourceFilter")
	--DA.DEBUG(0,"RecipeFilterToggleButton_OnShow("..tostring(button)..")")
	if filter then
		button:SetChecked(true)
	else
		button:SetChecked(false)
	end
end

function SkilletARL:RecipeFilterToggleButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	GameTooltip:SetText("Filter recipes by source", nil, nil, nil, nil, true)
	GameTooltip:AddLine("Left-Click to toggle", .7, .7, .7)
	GameTooltip:AddLine("Right-Click for filtering options", .7, .7, .7)
	GameTooltip:Show()
	GameTooltip:Show()
end

function SkilletARL:RecipeFilterToggleButton_OnLeave(button)
	GameTooltip:Hide()
end

function SkilletARL:RecipeFilterToggleButton_OnClick(button, mouse)
	if mouse=="LeftButton" then
		SkilletARL:RecipeFilterButtons_Hide()
		if button:GetChecked() then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON); -- "igMainMenuOptionCheckBoxOn"
		end
		local before = Skillet:GetTradeSkillOption("recipeSourceFilter")
		Skillet:SetTradeSkillOption("recipeSourceFilter", not before)
		Skillet:SortAndFilterRecipes()
		Skillet:UpdateTradeSkillWindow()
	else
		if ARLRecipeSourceTrainerButton:IsVisible() then
			SkilletARL:RecipeFilterButtons_Hide()
		else
			SkilletARL:RecipeFilterButtons_Show()
		end
		if Skillet:GetTradeSkillOption("recipeSourceFilter") then
			button:SetChecked(true)
		else
			button:SetChecked(false)
		end
	end
end

function SkilletARL:RecipeSourceButtonInit()
	if not self.arlRecipeSourceButton then
		local b = CreateFrame("CheckButton", "ARLRecipeSourceFilterButton")
		b:SetWidth(20)
		b:SetHeight(20)
		b:SetNormalTexture("Interface\\Icons\\INV_Scroll_03")
		b:SetPushedTexture("Interface\\Icons\\INV_Scroll_03")
		b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
		b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		b:SetDisabledTexture("Interface\\Icons\\INV_Scroll_03")
		b:RegisterForClicks("LeftButtonUp", "RightButtonDown")
		self.arlRecipeSourceButton = b
		b:SetScript("OnClick", function(self,button) SkilletARL:RecipeFilterToggleButton_OnClick(self, button) end)
		b:SetScript("OnEnter", function(self) SkilletARL:RecipeFilterToggleButton_OnEnter(self) end)
		b:SetScript("OnLeave", function(self) SkilletARL:RecipeFilterToggleButton_OnLeave(self) end)
		b:SetScript("OnShow", function(self) SkilletARL:RecipeFilterToggleButton_OnShow(self) end)
		b.trainerButton = initFilterButton("ARLRecipeSourceTrainerButton", "Interface\\Addons\\Skillet\\Icons\\vendor_icon.tga", b, "trainer")
		b.trainerButton:SetPoint("TOP", b:GetName(), "BOTTOM", -50,0)
		b.trainerButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.vendorButton = initFilterButton("ARLRecipeSourceVendorButton", "Interface\\Addons\\Skillet\\Icons\\vendor_icon.tga", b, "vendor")
		b.vendorButton:SetPoint("LEFT", "ARLRecipeSourceTrainerButton", "RIGHT", 0,0)
		b.vendorButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.questButton = initFilterButton("ARLRecipeSourceQuestButton", "Interface\\Icons\\INV_Misc_Map_01", b, "quest")
		b.questButton:SetPoint("LEFT", "ARLRecipeSourceVendorButton", "RIGHT", 0,0)
		b.questButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.dropButton = initFilterButton("ARLRecipeSourceDropButton", "Interface\\Icons\\Ability_DualWield", b, "drop")
		b.dropButton:SetPoint("LEFT", "ARLRecipeSourceQuestButton", "RIGHT", 0,0)
		b.dropButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.mobButton = initFilterButton("ARLRecipeSourceMobButton", "Interface\\Icons\\INV_Scroll_06", b, "mob")
		b.mobButton:SetPoint("LEFT", "ARLRecipeSourceDropButton", "RIGHT", 0,0)
		b.mobButton:SetFrameLevel(b:GetFrameLevel()+5)
		b.unknownButton = initFilterButton("ARLRecipeSourceUnknownButton", "Interface\\Icons\\INV_Misc_QuestionMark", b, "unknown")
		b.unknownButton:SetPoint("LEFT", "ARLRecipeSourceMobButton", "RIGHT", 0,0)
		b.unknownButton:SetFrameLevel(b:GetFrameLevel()+5)
	end
	local _,_,icon = GetSpellInfo(Skillet.currentTrade)
	if icon then
		self.arlRecipeSourceButton.trainerButton:SetNormalTexture(icon)
	end
	self:RecipeFilterButtons_Hide()
	return self.arlRecipeSourceButton
end

-- return true if the skill needs to be filtered out
function SkilletARL:RecipeFilterOperator(skillIndex)
	return false
end

function SkilletARL:RecipeFilterOperatorOLD(skillIndex)
	if Skillet:GetTradeSkillOption("recipeSourceFilter") then
		local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, skillIndex)
		local _, recipeList, mobList, trainerList = AckisRecipeList:InitRecipeData()
		local recipeData = AckisRecipeList:GetRecipeData(skill.id)
		if recipeData == nil and not ARLProfessionInitialized[Skillet.currentTrade] then
			local profession = GetSpellInfo(Skillet.currentTrade)
			AckisRecipeList:AddRecipeData(profession)
			ARLProfessionInitialized[Skillet.currentTrade] = true
			recipeData = AckisRecipeList:GetRecipeData(skill.id)
		end
		if recipeData then
			local recipeSource = recipeData["Acquire"]
			for i,data in pairs(recipeSource) do
				if data["Type"] == 1 and Skillet:GetTradeSkillOption("recipeSourceFilter-trainer") then
					return false
				end
				if data["Type"] == 2 and Skillet:GetTradeSkillOption("recipeSourceFilter-vendor") then
					return false
				end
				if data["Type"] == 3 and Skillet:GetTradeSkillOption("recipeSourceFilter-mob") then
					return false
				end
				if data["Type"] == 4 and Skillet:GetTradeSkillOption("recipeSourceFilter-quest") then
					return false
				end
				if data["Type"] == 5 and Skillet:GetTradeSkillOption("recipeSourceFilter-drop") then
					return false
				end
			end
		else
			if Skillet:GetTradeSkillOption("recipeSourceFilter-unknown") then
				return false
			end
		end
		return true
	end
	return false
end

function SkilletARL:Enable()
--	if AckisRecipeList then
	if false then
		Skillet:RegisterRecipeFilter("arlRecipeSource", self, self.RecipeSourceButtonInit, self.RecipeFilterOperator)
		Skillet.defaultOptions["recipeSourceFilter"] = false
		Skillet.defaultOptions["recipeSourceFilter-drop"] = true
		Skillet.defaultOptions["recipeSourceFilter-vendor"] = true
		Skillet.defaultOptions["recipeSourceFilter-trainer"] = true
		Skillet.defaultOptions["recipeSourceFilter-quest"] = true
		Skillet.defaultOptions["recipeSourceFilter-mob"] = true
		Skillet.defaultOptions["recipeSourceFilter-unknown"] = true
	end
end
