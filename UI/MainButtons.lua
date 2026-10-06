local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
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

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")

local nonLinkingTrade
if Skillet.isRetail then
	nonLinkingTrade = { [2656] = true, [53428] = true, [193290] = true, [250046] = true } -- smelting, runeforging, herbalism, skinning
else
	nonLinkingTrade = { [2656] = true, [53428] = true }	-- smelting, runeforging
end

function Skillet:TradeButton_OnEnter(this)
	GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local bName = this:GetName()
	local _, player, tradeID = string.split("-", bName)
	local sName = C_Spell.GetSpellName(tradeID)
	DA.DEBUG(0,"TradeButton_OnEnter: "..tostring(bName).."), player= "..tostring(player)..", tradeID= "..tostring(tradeID)..", sName= "..tostring(sName))
	GameTooltip:AddLine(sName)
	tradeID = tonumber(tradeID)
	local data
	data = self:GetSkillRanks(player, tradeID)
	if not data or data == {} then
		GameTooltip:AddLine(L["No Data"],1,0,0)
	else
		local rank, maxRank = data.rank, data.maxRank
		GameTooltip:AddLine("["..tostring(rank).."/"..tostring(maxRank).."]",0,1,0)
		if tradeID == self.currentTrade then
			GameTooltip:AddLine("shift-click to link")
		end
		local thisIcon = _G[this:GetName().."Icon"]
		local r,g,b = thisIcon:GetVertexColor()
		if g == 0 then
			GameTooltip:AddLine("scan incomplete...",1,0,0)
		end
		if nonLinkingTrade[tradeID] and player ~= UnitName("player") then
			GameTooltip:AddLine(sName.." not available for alts")
		end
	end
	GameTooltip:Show()
end

function Skillet:TradeButton_OnClick(this,button)
	local bName = this:GetName()
	local _, player, tradeID = string.split("-", bName)
	local sName = C_Spell.GetSpellName(tradeID)
	DA.DEBUG(0,"TradeButton_OnClick: bName= "..tostring(bName)..", player= "..tostring(player)..", tradeID= "..tostring(tradeID)..", sName= "..tostring(sName))
	tradeID = tonumber(tradeID)
	local data =  self:GetSkillRanks(player, tradeID)
	if button == "LeftButton" then
		if player == UnitName("player") or (data and data ~= nil) then
			if IsShiftKeyDown() then
				if self.currentTrade == tradeID then
					local link = C_TradeSkillUI.GetTradeSkillListLink()
					if link then
						if not ChatEdit_InsertLink(link) then
							DA.DEBUG(0,"TradeButton_OnClick: link= "..DA.PLINK(link))
						end
					else
						DA.WARN(sName.." ("..tostring(tradeID)..") is not linkable")
					end
				else
					return
				end
			else
				if player == UnitName("player") then
					self:SetTradeSkill(self.currentPlayer, tradeID)
				else
					local link = self.db.realm.tradeSkills[player][tradeID].link
					local _,tradeString
					if Skillet.wowVersion >= 50400 then
						_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:[a-zA-Z0-9+/:]+)")
					elseif Skillet.wowVersion >= 50300 then
						_,_,tradeString = string.find(link, "(trade:[0-9a-fA-F]+:%d+:%d+:%d+:[a-zA-Z0-9+/:]+)")
					else
						_,_,tradeString = string.find(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[a-zA-Z0-9+/]+)")
					end
					if tradeString then
						SetItemRef(tradeString,link,"LeftButton")
					end
				end
				this:SetChecked(true)
			end
		else
			this:SetChecked(false)
		end
	end
	GameTooltip:Hide()
end

function Skillet:TradeButtonAdditional_OnEnter(this)
	--DA.DEBUG(0,"TradeButtonAdditional_OnEnter("..tostring(this)..")")
	DA.DEBUG(0,"TradeButtonAdditional_OnEnter: this= "..DA.DUMP(this))
	GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	local spellID = this:GetID()
	local spellName = C_Spell.GetSpellName(spellID)
	if this.Toy then
		_, spellName = C_ToyBox.GetToyInfo(spellID)
	end
	--DA.DEBUG(1,"TradeButtonAdditional_OnEnter: spellName= "..tostring(spellName))
	GameTooltip:AddLine(spellName)
	if not this.Toy then
		local itemID = Skillet:GetAutoTargetItem(spellID)
		if itemID and IsAltKeyDown() then
			GameTooltip:AddLine("/use "..C_Item.GetItemInfo(itemID))
		end
	end
	GameTooltip:Show()
end

--
-- A SecureActionButtonTemplate button can't override the OnClick so 
-- this function will never be called.
--
function Skillet:TradeButtonAdditional_OnClick(this,button)
	--DA.DEBUG(0,"TradeButtonAdditional_OnClick("..DA.DUMP1(this)..", "..tostring(button)..")")
	local name = this:GetName()
	--DA.DEBUG(0,"TradeButtonAdditional_OnClick: name= "..tostring(name))
	GameTooltip:Hide()
end

function Skillet:BlizzardUIButton_OnEnter(this)
	--DA.DEBUG(0,"BlizzardUIButton_OnEnter("..tostring(this)..")")
	GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Toggle Blizzard UI")
	GameTooltip:Show()
end

function Skillet:BlizzardUIButton_OnClick(this,button)
	--DA.DEBUG(0,"BlizzardUIButton_OnClick")
	GameTooltip:Hide()
	if Skillet.BlizzardUIshowing then
		if Skillet.isRetail then
			HideUIPanel(ProfessionsFrame)
		else
			ProfessionsFrame:SetScale(Skillet.db.profile.scale_blizzard_frame or 0.1)
		end
		Skillet.BlizzardUIshowing = false
	else
		if Skillet.isRetail then
			ShowUIPanel(ProfessionsFrame)
			ProfessionsFrame.CloseButton:HookScript("OnClick",function(...) Skillet.BlizzardUIshowing = false end)
		else
			ProfessionsFrame:SetScale(1.0)
		end
		ProfessionsFrame:Refresh()
		Skillet.BlizzardUIshowing = true
		if SkilletFrame.selectedSkill and SkilletFrame.selectedSkill ~= -1 then
			Skillet:SetSelectedSkill(SkilletFrame.selectedSkill)
		end
	end
end

function Skillet:CreateAdditionalButtonsList()
	--DA.DEBUG(0,"CreateAdditionalButtonsList()")
	Skillet.AdditionalButtonsList = {}
	local seenButtons = {}
	local tradeSkillList = self.tradeSkillList
	for i=1,#tradeSkillList,1 do
		local tradeID = tradeSkillList[i]
		local ranks = self:GetSkillRanks(Skillet.currentPlayer, tradeID)
		if ranks then	-- this player knows this skill
			local additionalSpellTab = Skillet.TradeSkillAdditionalAbilities[tradeID]
			if additionalSpellTab then -- this skill has additional abilities
				if type(additionalSpellTab[1]) == "table" then
					for j=1,#additionalSpellTab,1 do
						--DA.DEBUG(1,"CreateAdditionalButtonsList: tradeID= "..tostring(tradeID)..", additionalSpellTab["..tostring(j).."]= "..DA.DUMP1(additionalSpellTab[j]))
						local spellID = additionalSpellTab[j][1]
						if not seenButtons[spellID] then
							if additionalSpellTab[j][5] then
								local name = C_Spell.GetSpellName(spellID)	-- always returns data
								if name then
									name = C_Spell.GetSpellName(name)		-- only returns data if you have this spell in your spellbook
								end
								--DA.DEBUG(1,"CreateAdditionalButtonsList: name= "..tostring(name))
								if name then
									table.insert(Skillet.AdditionalButtonsList, additionalSpellTab[j])
								end
							else
								table.insert(Skillet.AdditionalButtonsList, additionalSpellTab[j])
							end
							seenButtons[spellID] = true
						end
					end
				else
					local spellID = additionalSpellTab[1]
					if not seenButtons[spellID] then
						--DA.DEBUG(1,"CreateAdditionalButtonsList: tradeID= "..tostring(tradeID)..", additionalSpellTab= "..DA.DUMP1(additionalSpellTab))
						table.insert(Skillet.AdditionalButtonsList, additionalSpellTab)
						seenButtons[spellID] = true
					end
				end
			end		-- additionalSpellTab
		end		-- ranks
	end		-- for
	--DA.DEBUG(0,"CreateAdditionalButtonsList: AdditionalButtonsList= "..DA.DUMP(Skillet.AdditionalButtonsList))
end

function Skillet:UpdateTradeButtons(player)
	--DA.DEBUG(0,"UpdateTradeButtons("..tostring(player)..")")
	local position = 0 -- pixels
	local tradeSkillList = self.tradeSkillList
	local frameName = "SkilletFrameTradeButtons-"..player
	local frame = _G[frameName]
	if not frame then
		frame = CreateFrame("Frame", frameName, SkilletFrame)
	end
	frame:Show()
	for i=1,#tradeSkillList,1 do	-- iterate thru all skills in defined order for neatness (professions, secondary, class skills)
		local tradeID = tradeSkillList[i]
		local ranks = self:GetSkillRanks(player, tradeID)
		local tradeLink
		if self.db.realm.tradeSkills[player] then
			if nonLinkingTrade[tradeID] then
				tradeLink = nil
			else
				local tradePlayer = self.db.realm.tradeSkills[player][tradeID]
				if tradePlayer then
					tradeLink = tradePlayer.link
				end
			end
		end
		if ranks then
			local spellName, spellIcon 
			local spellInfo = C_Spell.GetSpellInfo(tradeID)
			--DA.DEBUG(1,"UpdateTradeButtons: spellInfo= "..DA.DUMP1(spellInfo))
			spellName = spellInfo.name
			spellIcon = spellInfo.iconID
			local buttonName = "SkilletFrameTradeButton-"..player.."-"..tradeID
			local button = _G[buttonName]
			if not button then
				--DA.DEBUG(1,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
				button = CreateFrame("CheckButton", buttonName, frame, "SkilletTradeButtonTemplate")
			end
			if player ~= UnitName("player") and not tradeLink then		-- fade out buttons that don't have data collected
				button:SetAlpha(.4)
				button:SetHighlightTexture("")
				button:SetPushedTexture("")
				button:SetCheckedTexture("")
			end
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
			local buttonIcon = _G[buttonName.."Icon"]
			buttonIcon:SetTexture(spellIcon)
			position = position + button:GetWidth()
			if tradeID == self.currentTrade then
				button:SetChecked(true)
				if Skillet.data.skillList[tradeID].scanned then
					buttonIcon:SetVertexColor(1,1,1)
				else
					buttonIcon:SetVertexColor(1,0,0)
				end
			else
				button:SetChecked(false)
			end
			button:Show()
		end
	end -- for
--
-- Add some space
--
	position = position + 10
--
-- Create list of additional skills (if it doesn't exist)
--
	if not Skillet.AdditionalButtonsList then
		self:CreateAdditionalButtonsList()
	end
--
-- Iterate thru the list of additional skills and add buttons for each one
--
-- Each entry is {spellID, "Name", isToy, isPet, isKnown}
--   isToy is true if the spellID is a toyID instead
--   isPet is true if the name is a pet
--   isKnown is true if the spellID must be known by the player.
--
	--DA.DEBUG(1,"UpdateTradeButtons: doing "..tostring(#Skillet.AdditionalButtonsList).." AdditionalButtonsList entries")
	for i=1,#Skillet.AdditionalButtonsList,1 do
		local additionalSpellTab = Skillet.AdditionalButtonsList[i]
		local additionalSpellId = additionalSpellTab[1]
		local additionalSpellName = additionalSpellTab[2]
		local additionalToy = additionalSpellTab[3]
		local additionalPet = additionalSpellTab[4]
		local spellInfo, spellName, spellIcon, petGUID
		if additionalToy then
			if (PlayerHasToy(additionalSpellId) and C_ToyBox.IsToyUsable(additionalSpellId)) then
				_, spellName, spellIcon = C_ToyBox.GetToyInfo(additionalSpellId)
			else
				spellName = nil
			end
		else
			local spellInfo = C_Spell.GetSpellInfo(additionalSpellId)
			if spellInfo then
				--DA.DEBUG(1,"UpdateTradeButtons: spellInfo= "..DA.DUMP1(spellInfo))
				spellName = spellInfo.name
				spellIcon = spellInfo.iconID
			else
				spellName = nil
				spellIcon = nil
			end
		end
		if additionalPet then
			_, petGUID = C_PetJournal.FindPetIDByName(additionalSpellName)
			if petGUID then
				spellName = additionalSpellName
			else
				spellName = nil
			end
		end
		if spellName then
			--DA.DEBUG(1,"UpdateTradeButtons: i= "..tostring(i)..", additionalSpellId= "..tostring(additionalSpellId)..", spellName= "..tostring(spellName)..", spellIcon= "..tostring(spellIcon))
			local buttonName = "SkilletDo"..additionalSpellName
			local button = _G[buttonName]
			if not button then
				--DA.DEBUG(0,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
				button = CreateFrame("Button", buttonName, frame, "SkilletTradeButtonAdditionalTemplate")
				button:SetID(additionalSpellId)
				if additionalToy then
					button.Toy = true
				end
				if additionalPet then
					button.Pet = true
					button.PetGUID = petGUID
				end
			end
--
-- https://wowpedia.fandom.com/wiki/SecureActionButtonTemplate 
--
--[[
--
-- pure spell on left-click
--
			local spellName, _, texture = C_Spell.GetSpellName(additionalSpellId)
			DA.DEBUG(1,"UpdateTradeButtons: additionalSpellId= "..tostring(additionalSpellId)..", spellName= "..tostring(spellName))
			button:SetAttribute("type1", "spell")
			button:SetAttribute("spell1", spellName)
--]]
--
-- execute a macro on any click
--
			button:SetAttribute("type", "macro");
			local macrotext = Skillet:GetAutoTargetMacro(additionalSpellId, button.Toy, button.Pet, petGUID)
			--DA.DEBUG(1,"UpdateTradeButtons: macrotext= "..tostring(macrotext))
			button:SetAttribute("macrotext", macrotext)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
			local buttonIcon = _G[buttonName.."Icon"]
			if spellIcon then
				buttonIcon:SetTexture(spellIcon)
			end
			position = position + button:GetWidth()
			button:Show()
			if additionalToy then
				local isToyUsable = C_ToyBox.IsToyUsable(additionalSpellId)
				--DA.DEBUG(1,"UpdateTradeButtons: IsToyUsable("..tostring(additionalSpellId)..")= "..tostring(isToyUsable))
				if isToyUsable then
					button:Enable()
					button:SetAlpha(1.0)
				else
					button:Disable()
					button:SetAlpha(0.2)
				end
			end
			if additionalPet then
				--DA.DEBUG(1,"UpdateTradeButtons: petName= "..tostring(additionalSpellName)..", petGUID= "..tostring(petGUID))
				if petGUID then
					button:Enable()
					button:SetAlpha(1.0)
				else
					button:Disable()
					button:SetAlpha(0.2)
				end
			end
		end
	end
--
-- One more button to toggle the Blizzard TradeSkillFrame
--
	position = position + 10	-- Add some space
	local buttonName = "SkilletBlizzardUI"
	local button = _G[buttonName]
	if not button then
		--DA.DEBUG(0,"UpdateTradeButtons: CreateFrame for "..tostring(buttonName))
		button = CreateFrame("Button", buttonName, frame, "SkilletBlizzardUITemplate")
		button:SetID(2)
	end
	button:ClearAllPoints()
	button:SetPoint("BOTTOMLEFT", SkilletRankFrame, "TOPLEFT", position, 3)
	local buttonIcon = _G[buttonName.."Icon"]
	buttonIcon:SetTexture(3573824)
	position = position + button:GetWidth()
	button:Show()
end

function Skillet.PluginDropdown_OnClick(this)
	--DA.DEBUG(0,"PluginDropdown_OnClick()")
	local oldScript = this.oldButton:GetScript("OnClick")
	oldScript(this)
	for i=1,#SkilletFrame.added_buttons do
		local buttonName = "SkilletPluginDropdown"..i
		local button = _G[buttonName]
		if button then
			button:Hide()
		end
	end
end

function Skillet:PluginButton_OnClick(button)
	--DA.DEBUG(0,"PluginButton_OnClick()")
	if SkilletFrame.added_buttons then
		for i=1,#SkilletFrame.added_buttons do
			local oldButton = SkilletFrame.added_buttons[i]
			local buttonName = "SkilletPluginDropdown"..i
			local button = _G[buttonName]
			if not button then
				button = CreateFrame("button", buttonName, SkilletPluginButton, "UIPanelButtonTemplate")
				button:Hide()
			end
			--DA.DEBUG(1,"PluginButton_OnClick: "..buttonName)
			button:SetText(oldButton:GetText())
			button:SetWidth(100)
			button:SetHeight(22)
			button:SetFrameLevel(SkilletFrame:GetFrameLevel()+10)
			button:SetScript("OnClick", Skillet.PluginDropdown_OnClick)
			button:SetPoint("TOPLEFT", 0, -i*20)
			button.oldButton = oldButton
			oldButton:Hide()
			if button:IsVisible() then
				button:Hide()
			else
				button:Show()
			end
		end
	end
end
