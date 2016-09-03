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

Skillet.TSIPlugin = {}

local plugin = Skillet.TSIPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "TradeskillInfo",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.TSI.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.TSI.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.TSI then
		Skillet.db.profile.plugins.TSI = {}
		Skillet.db.profile.plugins.TSI.enabled = true
	end
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet TradeskillInfo", plugin.options)
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet TradeskillInfo", "TradeskillInfo", "Skillet")
end

local TSISourceColor = {
	V = "|cff00ff00",
	Q = "|cffffff00",
	D = "|cffff0000",
}

local function TSIGetRecipeSources(recipe, opposing)
	if not TradeskillInfo.vars.recipes[recipe] then
		return nil
	end
	local found, _, sources, price, level = string.find(TradeskillInfo.vars.recipes[recipe],"[^|]+|(%w+)[|]?(%d*)[|]?(%d*)");
	if not found then return end
	local c = TradeskillInfo.db.profile.ColorRecipeSource;
	local Ltext, Rtext = "";
	if price == "" then
		price = nil
	else
		price = tonumber(price)
	end
	local uf = UnitFactionGroup("player")
	local res = ""
	local number_found = 0;
	opposing = true
	for s,n in string.gmatch(sources,"(%u%l*)(%d*)") do
		if (s=="V" or s=="Q" or s=="D") and n~="" then
			local found,_,vname,znr,fnr,pos,note = string.find(TradeskillInfo.vars.vendors[tonumber(n)],"([^|]+)|(%d+)|(%d+)[|]?([^|]*)[|]?([^|]*)");
			if found then
				if opposing or (uf=="Horde" and fnr~="1") or (uf=="Alliance" and fnr~="2") then
					number_found = number_found + 1;
					local zone = TradeskillInfo.vars.zones[tonumber(znr)];
					local faction = TradeskillInfo.vars.factions[tonumber(fnr)];
					if res ~= "" then
						res = res.."\n";
					end
					if note ~= "" then
						note = " "..note
					end
					if pos ~= "" then
						local found, _, x, y = string.find(pos,"([%d%.]+),([%d%.]+)");
						if found then
							zone = zone or ""
							pos = " |cFF0066FF|Htsicoord:"..zone..":"..x..":"..y..":"..vname.."|h("..x..", "..y..")|h|r"
						else
							pos = " ("..pos..")"
						end
					end
					Rtext = TSISourceColor[s]..vname.."|r: "..zone..pos.."|cff808080"..note.."|r"
					if level ~= "" then
						local rep = _G["FACTION_STANDING_LABEL"..level];
						Rtext = Rtext.."\n(|cff60a0f0"..faction.."|r-"..rep.."|r)";
					end
					res = res..Rtext;
				end
			else
				TradeskillInfo:Print(TradeskillInfo_UnknownNPC_Text,s);
			end
		elseif TradeskillInfo.vars.sources[s] then
			local _,_,f = string.find(s,"%u(%l*)")
			if opposing or (uf=="Horde" and f~="a") or (uf=="Alliance" and f~="h") then
				number_found = number_found + 1;
				if res ~= "" then
					res = res.."\n"
				end
				Rtext = TradeskillInfo.vars.sources[s];
				res = res..Rtext;
			end
		else
			TradeskillInfo:Print(TradeskillInfo_UnknownSource_Text,s);
		end
	end
	if res == "" then
		res = nil
	end
	return number_found,res
end

function plugin.GetExtraText(skill, recipe)
	if not TradeskillInfo or not Skillet.db.profile.plugins.TSI.enabled then return end
	if not skill or not recipe then return end
	local _, bop, extra_text
	local label = GRAY_FONT_COLOR_CODE..L["Source:"]..FONT_COLOR_CODE_CLOSE
	local tsiRecipeID = recipe.spellID
	if tsiRecipeID then
		local combineID = TradeskillInfo:GetCombineRecipe(tsiRecipeID)
		if combineID then
			_, extra_text = TSIGetRecipeSources(combineID, false)
			if not extra_text then
				extra_text = L["Trained"].." ("..( TradeskillInfo:GetCombineLevel(tsiRecipeID) or "??" )..")"
			end
			if TradeskillInfo:ShowingSkillAuctioneerProfit() then -- insert item value and reagent costs from Auctioneer
				local value, cost, profit = TradeskillInfo:GetCombineAuctioneerCost(tsiRecipeID)
				if GetAuctionBuyout and Skillet.scrollData[tsiRecipeID] then
					value = GetAuctionBuyout(Skillet.scrollData[tsiRecipeID]) or 0
					profit = value - cost
				end
				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Auction Profit:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..("%s - %s = %s"):format( TradeskillInfo:GetMoneyString(value), TradeskillInfo:GetMoneyString(cost), TradeskillInfo:GetMoneyString(profit) )
			end
			if TradeskillInfo:ShowingSkillProfit() then -- insert item value and reagent costs
				local value, cost, profit = TradeskillInfo:GetCombineCost(tsiRecipeID)
				if Skillet.scrollData[tsiRecipeID] then
					value = select(11, GetItemInfo(Skillet.scrollData[tsiRecipeID]))
					profit = value - cost
				end
				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Vendor Profit:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..("%s - %s = %s"):format( TradeskillInfo:GetMoneyString(value), TradeskillInfo:GetMoneyString(cost), TradeskillInfo:GetMoneyString(profit) )
			end
			if TradeskillInfo:ShowingSkillLevel() then
				label = label.."\n"..GRAY_FONT_COLOR_CODE.."Skill Levels:"..FONT_COLOR_CODE_CLOSE
				extra_text = extra_text.."\n"..TradeskillInfo:GetColoredDifficulty(tsiRecipeID)
			end
			if Skillet:bopCheck(combineID) then
				bop = true
			end
		else
			extra_text = "|cffff0000"..L["Unknown"].."|r"
		end
	end
	if bop then
		label = label.."\n|cffff0000(*BOP*)|r"
	end
	return label, extra_text
end

Skillet:RegisterDisplayDetailPlugin("TSIPlugin")
