local addonName,addonTable = ...
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end
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

--
-- Includes changes from GuardsmanBogo
-- Includes changes from Dranni21312
--

Skillet.ATRPlugin = {}

local plugin = Skillet.ATRPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "Auctionator",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.ATR.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
		useShort = {
			type = "toggle",
			name = "useShort",
			desc = "Use Short money format",
			get = function()
				return Skillet.db.profile.plugins.ATR.useShort
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useShort = value
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = "Only show positive values",
			get = function()
				return Skillet.db.profile.plugins.ATR.onlyPositive
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.onlyPositive = value
			end,
			order = 3
		},
		reagentPrices = {
			type = "toggle",
			name = "reagentPrices",
			desc = "Show prices for reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.reagentPrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.reagentPrices = value
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = "Show vendor prices for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.buyablePrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.buyablePrices = value
			end,
			order = 5
		},
		useVendorCalc = {
			type = "toggle",
			name = "useVendorCalc",
			desc = "Show calculated cost from vendor sell price for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.useVendorCalc
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useVendorCalc = value
			end,
			order = 6
		},
		useSearchExact = {
			type = "toggle",
			name = "useSearchExact",
			desc = "Use MultiSearchExact instead of MultSearch in Auction House shopping list",
			get = function()
				return Skillet.db.profile.plugins.ATR.useSearchExact
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useSearchExact = value
			end,
			order = 7
		},
		extraBuyout = {
			type = "toggle",
			name = "extraBuyout",
			desc = "Show buyout value",
			get = function()
				return Skillet.db.profile.plugins.ATR.extraBuyout
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.extraBuyout = value
			end,
			order = 8
		},
		extraProfitValue = {
			type = "toggle",
			name = "extraProfitValue",
			desc = "Show profit value",
			get = function()
				return Skillet.db.profile.plugins.ATR.extraProfitValue
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.extraProfitValue = value
			end,
			order = 9
		},
		extraProfitPercentage = {
			type = "toggle",
			name = "extraProfitPercentage",
			desc = "Show profit as percentage",
			get = function()
				return Skillet.db.profile.plugins.ATR.extraProfitPercentage
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.extraProfitPercentage = value
			end,
			order = 10
		},
		suffix = {
			type = "select",
			name = "Suffix",
			desc = "Primary suffix text",
			order = 1,
			get = function() 
				return Skillet.db.profile.plugins.ATR.suffix
			end,
			set = function(_, value)
				Skillet.db.profile.plugins.ATR.suffix = value
				Skillet.db.profile.plugins.ATR.suffixBuyout = (value == 1)
				Skillet.db.profile.plugins.ATR.suffixCost = (value == 2)
				Skillet.db.profile.plugins.ATR.suffixProfitValue = (value == 3)
				Skillet.db.profile.plugins.ATR.suffixProfitPercentage = (value == 4)
			end,
			values = {
			[1] = L["Buyout"], 
			[2] = L["Cost"],
			[3] = L["Profit"],
			[4] = L["Percent"],
			},
			width = 0.5,
			style = "radio", -- "dropdown"
			order = 11
		},
		colorCode = {
			type = "toggle",
			name = "colorCode",
			desc = "Add color to the results",
			get = function()
				return Skillet.db.profile.plugins.ATR.colorCode
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.colorCode = value
			end,
--			width = "full",
			order = 20
		},
--[[
		alwaysEnchanting = {
			type = "toggle",
			name = "alwaysEnchanting",
			desc = "Always show Enchanting profit (loss)",
			get = function()
				return Skillet.db.profile.plugins.ATR.alwaysEnchanting
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.alwaysEnchanting = value
			end,
			order = 21
		},
--]]
		calcProfitAhTax = {
			type = "toggle",
			name = "calcProfitAhTax",
			desc = "Calc profit after AH Tax(5%)",
			get = function()
				return Skillet.db.profile.plugins.ATR.calcProfitAhTax
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.calcProfitAhTax = value
			end,
			order = 22
		},
		journalatorE = {
			type = "toggle",
			name = "Journalator Extra",
			desc = "Show Journalator statistics",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return Skillet.db.profile.plugins.ATR.journalatorE
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.journalatorE = value
			end,
			order = 23
		},
		journalatorC = {
			type = "toggle",
			name = "Journalator Count",
			desc = "Show Journalator success count suffix",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return Skillet.db.profile.plugins.ATR.journalatorC
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.journalatorC = value
			end,
			order = 24
		},
		journalatorS = {
			type = "toggle",
			name = "Journalator Sales Rate",
			desc = "Show Journalator sales rate suffix",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return Skillet.db.profile.plugins.ATR.journalatorS
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.journalatorS = value
			end,
			order = 25
		},
		qualityBuyout = {
			hidden = not isRetail,
			type = "toggle",
			name = "qualityBuyout",
			desc = "Show all quality buyout values",
			get = function()
				return Skillet.db.profile.plugins.ATR.qualityBuyout
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.qualityBuyout = value
			end,
			order = 26
		},
		minmaxBuyout = {
			hidden = not isRetail,
			type = "toggle",
			name = "minmaxBuyout",
			desc = "Show minimum and maximum buyout values",
			get = function()
				return Skillet.db.profile.plugins.ATR.minmaxBuyout
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.minmaxBuyout = value
			end,
			order = 27
		},
		customPrice = {
			type = "toggle",
			name = "customPrice",
			desc = "Substitute customPrice table values for Auctionator price values",
			get = function()
				return Skillet.db.profile.plugins.ATR.customPrice
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.customPrice = value
			end,
			order = 28
		},
		buyFactor = {
			type = "range",
			name = "buyFactor",
			desc = "Multiply vendor sell price by this to get calculated buy price",
			min = 1, max = 10, step = 1, isPercent = false,
			get = function()
				return Skillet.db.profile.plugins.ATR.buyFactor
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.buyFactor = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 30
		},
		markup = {
			type = "range",
			name = "Markup %",
			min = 0, max = 2, step = 0.01, isPercent = true,
			get = function()
				return Skillet.db.profile.plugins.ATR.markup
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.markup = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 31,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05
local ahtaxDef = 0.95
local toConcatLabel = {}
local toConcatExtra = {}

local function NOSORT(tradeskill,a,b)
	return (a.skillIndex or 0) < (b.skillIndex or 0)
end

local function GetATRSort()
	local sortmethod = Skillet:GetTradeSkillOption("sortmethod")
	--DA.DEBUG(0,"GetATRSort= "..tostring(sortmethod))
	return sortmethod
end

local function IsATRSort()
	local sortmethod = Skillet:GetTradeSkillOption("sortmethod")
	local found = string.find(sortmethod,"ATR:")
	--DA.DEBUG(0,"IsATRSort= "..tostring(found))
	return found
end

local function IsJNLSort()
	local sortmethod = Skillet:GetTradeSkillOption("sortmethod")
	local found = string.find(sortmethod,"JNL:") 
	--DA.DEBUG(0,"IsJNLSort= "..tostring(found))
	return found
end

local function SetATRsuffix(recipe)
	--DA.DEBUG(0,"SetATRsuffix: recipe= "..DA.DUMP1(recipe,1))
	if Skillet.db.profile.plugins.ATR.suffixBuyout then
		--DA.DEBUG(0,"SetATRsuffix: buyout= "..tostring(recipe.buyout))
		return recipe.buyout
	elseif Skillet.db.profile.plugins.ATR.suffixCost then
		--DA.DEBUG(0,"SetATRsuffix: cost= "..tostring(recipe.cost))
		return recipe.cost
	elseif Skillet.db.profile.plugins.ATR.suffixProfitValue then
		--DA.DEBUG(0,"SetATRsuffix: profit= "..tostring(recipe.profit))
		return recipe.profit
	elseif Skillet.db.profile.plugins.ATR.suffixProfitPercentage then
		--DA.DEBUG(0,"SetATRsuffix: percentage= "..tostring(recipe.percentage))
		return recipe.percentage
	end
end


local function GetMinMaxBuyout(recipe)
	local minBuyout = 999999999999
	local maxBuyout = 0
	local buyout, outputItemInfo, hasQ
	local itemID = recipe.itemID
	if recipe.supportsQualities and Auctionator and Auctionator.API.v1.GetAuctionPriceByItemLink and Auctionator.API.v1.GetAuctionPriceByItemID then
		for _, quality in pairs(recipe.qualityIDs) do
			outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, quality)
			if outputItemInfo and outputItemInfo.hyperlink then
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink) or 0) * recipe.numMade
				hasQ = true
			else
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
			end
			minBuyout = min(buyout,minBuyout)
			maxBuyout = max(buyout,maxBuyout)
		end
	elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
		minBuyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
		maxBuyout = minBuyout
	else
		return 0,0
	end
	return minBuyout, maxBuyout, hasQ
end

local function GetBuyout(recipe)
	local buyout, minBuyout, maxBuyout, outputItemInfo, sellout
	local itemID
	if recipe.scrollID then
		itemID = recipe.scrollID
	else
		itemID = recipe.itemID
	end
	sellout = ( select(11,C_Item.GetItemInfo(itemID)) or 0 )
	if isRetail and Skillet.db.profile.plugins.ATR.minmaxBuyout then
		minBuyout, maxBuyout = GetMinMaxBuyout(recipe)
		if Skillet.db.profile.best_quality then
			buyout = maxBuyout
		else
			buyout = minBuyout
		end
	else
		if Atr_GetAuctionBuyout then
			buyout = (Atr_GetAuctionBuyout(itemID) or 0) * recipe.numMade
		elseif Auctionator and Auctionator.API.v1 then
			if isRetail then
				if Skillet.db.profile.best_quality then
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, 8)
				else
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, 4)
				end
			end
			if outputItemInfo and outputItemInfo.hyperlink then
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink) or 0) * recipe.numMade
			else
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
			end
		else
			return 0, sellout or 0
		end
	end
	return buyout or 0, sellout or 0
end

local function GetReagentData(reagent)
	local value = 0
	local needed = 0
	local custom = ""
	local id, name
	if reagent then
		needed = reagent.numNeeded or 0
		if isRetail then
			id = reagent.reagentID
		else
			id = reagent.id
		end
		name = C_Item.GetItemInfo(id) or id
		if Atr_GetAuctionBuyout then
			value = (Atr_GetAuctionBuyout(id) or 0)
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0)
		else
			value = 0
		end
		if Skillet.db.profile.plugins.ATR.customPrice then
			local server = Skillet.data.server or 0
			local customPrice = Skillet.db.global.customPrice[server]
			if customPrice and customPrice[id] then
				--DA.DEBUG(0,"GetReagentData: id= "..tostring(id)..", "..DA.DUMP1(customPrice[id]))
				if customPrice[id].name and customPrice[id].name ~= name then
					--DA.DEBUG(0,"GetReagentData: name mismatch: "..tostring(name)..", "..tostring(customPrice[id].name))
					customPrice[id].name = name
				end
				if customPrice[id].value and customPrice[id].value < value then
					--DA.DEBUG(0,"GetReagentData: substitute: "..tostring(customPrice[id].value).." for: "..tostring(value))
					value = customPrice[id].value
					custom = " |cffff8040*|r"
				end
			end
		end
		value = value * needed
		if Skillet:VendorSellsReagent(id) then
			if Skillet.db.profile.plugins.ATR.buyablePrices then
				if Skillet.db.profile.plugins.ATR.useVendorCalc then
					local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
					value = ( select(11,C_Item.GetItemInfo(id)) or 0 ) * needed * buyFactor
				end
			else
				value = 0
			end
		end
	end
	return value, needed, id, name, custom
end

local function AddExtraText(value, needed, id, name, custom)
	if not Skillet:VendorSellsReagent(id) then
--
-- Not sold by a vendor so use the default
--
		toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s%s", needed, name, custom)
		toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
	else
		toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, name, L["buyable"])
		if Skillet.db.profile.plugins.ATR.buyablePrices then
--
-- If this reagent is sold by a vendor, then use that (calculated) price instead
--
			local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
			value = ( select(11,C_Item.GetItemInfo(id)) or 0 ) * needed * buyFactor
			toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
		else
--
-- If this reagent is sold by a vendor, don't use the Auctionator price
--
			value = 0
			toConcatExtra[#toConcatExtra+1] = ""
		end
	end
	return value
end

local function GetRecipeData(recipe)
	--DA.DEBUG(0,"GetRecipeData: recipe= "..DA.DUMP(recipe,1))
	if not recipe then return end
	local buyout, cost, profit, percentage, sellout, vprofit, vpercentage
	local itemID
	if recipe.scrollID then
		itemID = recipe.scrollID
	else
		itemID = recipe.itemID
	end
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
		buyout, sellout = GetBuyout(recipe)
		cost = 0
		for i=1,#recipe.reagentData do
			local value = GetReagentData(recipe.reagentData[i])
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetRecipeData: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value = GetReagentData(recipe.modifiedData[i])
				cost = cost + value
			end
		end
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = Skillet.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		percentage = profit * 100 / cost
		vprofit = sellout - cost
		vpercentage = vprofit * 100 / cost
		--DA.DEBUG(0,"GetRecipeData: buyout= "..tostring(buyout)..", profit= "..tostring(profit)..", percentage= "..tostring(percentage))
		--DA.DEBUG(0,"GetRecipeData: sellout= "..tostring(sellout)..", vprofit= "..tostring(vprofit)..", vpercentage= "..tostring(vpercentage))
		recipe.cost = cost or 0
		recipe.buyout = buyout or 0
		recipe.profit = profit or 0
		recipe.percentage = percentage or 0
		recipe.sellout = sellout or 0
		recipe.vprofit = vprofit or 0
		recipe.vpercentage = vpercentage or 0
		recipe.suffix = SetATRsuffix(recipe)
	end
end

--
-- Sort by Auctionator Buyout price
--
function plugin.SortByBuyout(skill,a,b)
	--DA.DEBUG(0,"SortByBuyout: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, buyoutA, buyoutB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByBuyout: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByBuyout: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.buyout then
		GetRecipeData(recipeA)
	end
	buyoutA = recipeA.buyout or 0
	if not recipeB.buyout then
		GetRecipeData(recipeB)
	end
	buyoutB = recipeB.buyout or 0
	--DA.DEBUG(0,"SortByBuyout: buyoutA= "..tostring(buyoutA)..", buyoutB= "..tostring(buyoutB))
	return (buyoutA > buyoutB)
end

--
-- Sort by Auctionator Sell to Vendor price
--
function plugin.SortBySellout(skill,a,b)
	--DA.DEBUG(0,"SortBySellout: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, selloutA, selloutB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortBySellout: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortBySellout: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.sellout then
		GetRecipeData(recipeA)
	end
	selloutA = recipeA.sellout or 0
	if not recipeB.sellout then
		GetRecipeData(recipeB)
	end
	selloutB = recipeB.sellout or 0
	--DA.DEBUG(0,"SortBySellout: selloutA= "..tostring(selloutA)..", selloutB= "..tostring(selloutB))
	return (selloutA > selloutB)
end

--
-- Sort by Auctionator Cost
--
function plugin.SortByCost(skill,a,b)
	--DA.DEBUG(0,"SortByCost: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, costA, costB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByCost: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByCost: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.cost then
		GetRecipeData(recipeA)
	end
	costA = recipeA.cost or 0
	if not recipeB.cost then
		GetRecipeData(recipeB)
	end
	costB = recipeB.cost or 0
	--DA.DEBUG(0,"SortByCost: costA= "..tostring(costA)..", costB= "..tostring(costB))
	return (costA > costB)
end

--
-- Sort by calculated profit value
--
function plugin.SortByProfit(skill,a,b)
	--DA.DEBUG(0,"SortByProfit: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, profitA, profitB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.profit then
		GetRecipeData(recipeA)
	end
	profitA = recipeA.profit or 0
	if not recipeB.profit then
		GetRecipeData(recipeB)
	end
	profitB = recipeB.profit or 0
	--DA.DEBUG(0,"SortByProfit: profitA= "..tostring(profitA)..", profitB= "..tostring(profitB))
	return (profitA > profitB)
end

--
-- Sort by sell to vendor profit value
--
function plugin.SortByVProfit(skill,a,b)
	--DA.DEBUG(0,"SortByVProfit: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, vprofitA, vprofitB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.vprofit then
		GetRecipeData(recipeA)
	end
	vprofitA = recipeA.vprofit or 0
	if not recipeB.vprofit then
		GetRecipeData(recipeB)
	end
	vprofitB = recipeB.vprofit or 0
	--DA.DEBUG(0,"SortByProfit: vprofitA= "..tostring(vprofitA)..", vprofitB= "..tostring(vprofitB))
	return (vprofitA > vprofitB)
end

--
-- Sort by calculated profit percentage
--
function plugin.SortByPercent(skill,a,b)
	--DA.DEBUG(0,"SortByPercent: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		--DA.DEBUG(1,"SortByPercent: a= "..DA.DUMP1(a,1))
		--DA.DEBUG(1,"SortByPercent: b= "..DA.DUMP1(b,1))
		if a.subGroup or b.subGroup then
--			return NOSORT(skill, a, b)
			return false
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, percentA, percentB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(1,"SortByPercent: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(1,"SortByPercent: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.percentage then
		GetRecipeData(recipeA)
	end
	percentA = recipeA.percentage or 0
	if not recipeB.percentage then
		GetRecipeData(recipeB)
	end
	percentB = recipeB.percentage or 0
	--DA.DEBUG(1,"SortByPercent: percentA= "..tostring(percentA)..", percentB= "..tostring(percentB))
	return (percentA > percentB)
end

--
-- Sort by the Journalator API function GetRealmSuccessCountByItemName
--
-- For enchanting, use the scrollID instead of the itemID
--
function plugin.SortMostSold(skill,a,b)
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return
	end
	local recipeA, recipeB, itemNameA, itemNameB, successCountA, successCountB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeB= "..DA.DUMP1(recipeB))
	if recipeA.scrollID then
		itemNameA = C_Item.GetItemInfo(recipeA.scrollID)
	elseif recipeA.itemID then
		itemNameA = C_Item.GetItemInfo(recipeA.itemID)
	end
	if recipeB.scrollID then
		itemNameB = C_Item.GetItemInfo(recipeB.scrollID)
	elseif recipeB.itemID then
		itemNameB = C_Item.GetItemInfo(recipeB.itemID)
	end
	--DA.DEBUG(0,"SortMostSold: itemNameA= "..tostring(itemNameA)..", itemNameB= "..tostring(itemNameB))
	successCountA = 0
	successCountB = 0
	if Journalator and Journalator.API and itemNameA and itemNameB then
		successCountA = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameA)
		successCountB = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameB)
	end
	if successCountA > 0 and successCountB > 0 then
		--DA.DEBUG(0,"SortMostSold: successCountA= "..tostring(successCountA)..", successCountB= "..tostring(successCountB))
	end
	return (successCountA > successCountB)
end

--
-- Sort by the Sales Rate using the Journalator API functions
--   GetRealmSuccessCountByItemName and GetRealmFailureCountByItemName
--
-- For enchanting, use the scrollID instead of the itemID
--
function plugin.SortSalesRate(skill,a,b)
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return
	end
	local recipeA, recipeB, itemNameA, itemNameB, successCountA, successCountB
	local failedCountA, failedCountB, salesRateA, salesRateB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortSalesRate: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortSalesRate: recipeB= "..DA.DUMP1(recipeB))
	if recipeA.scrollID then
		itemNameA = C_Item.GetItemInfo(recipeA.scrollID)
	elseif recipeA.itemID then
		itemNameA = C_Item.GetItemInfo(recipeA.itemID)
	end
	if recipeB.scrollID then
		itemNameB = C_Item.GetItemInfo(recipeB.scrollID)
	elseif recipeB.itemID then
		itemNameB = C_Item.GetItemInfo(recipeB.itemID)
	end
	--DA.DEBUG(0,"SortSalesRate: itemNameA= "..tostring(itemNameA)..", itemNameB= "..tostring(itemNameB))
	salesRateA = 0
	salesRateB = 0
	if Journalator and Journalator.API and itemNameA and itemNameB then
		successCountA = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameA)
		failedCountA = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemNameA)
		successCountB = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameB)
		failedCountB = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemNameB)
		if successCountA > 0 then
			salesRateA = successCountA / (successCountA + failedCountA) * 100
		end
		if successCountB > 0 then
			salesRateB = successCountB / (successCountB + failedCountB) * 100
		end
	end
	if salesRateA > 0 and salesRateB > 0 then
		--DA.DEBUG(0,"SortSalesRate: salesRateA= "..tostring(salesRateA)..", salesRateB= "..tostring(salesRateB))
	end
	return (salesRateA > salesRateB)
end

function plugin.OnInitialize()
	--DA.DEBUG(0,"ATR:OnInitialize()")
	if not Skillet.db.profile.plugins.ATR then
		Skillet.db.profile.plugins.ATR = {}
		Skillet.db.profile.plugins.ATR.enabled = true
		Skillet.db.profile.plugins.ATR.buyFactor = buyFactorDef
		Skillet.db.profile.plugins.ATR.markup = markupDef
	end
	if Skillet.db.profile.plugins.ATR.showProfitValue == nil then
		Skillet.db.profile.plugins.ATR.showProfitValue = true
	end
	Skillet:AddPluginOptions(plugin.options)
	Skillet:AddRecipeSorter("ATR: "..L["Buyout"], plugin.SortByBuyout)
	Skillet:AddRecipeSorter("ATR: "..L["Cost"], plugin.SortByCost)
	Skillet:AddRecipeSorter("ATR: "..L["Profit"], plugin.SortByProfit)
	Skillet:AddRecipeSorter("ATR: "..L["Percent"], plugin.SortByPercent)
	Skillet:AddRecipeSorter("ATR: "..L["Sellout"], plugin.SortBySellout)
	Skillet:AddRecipeSorter("ATR: "..L["VProfit"], plugin.SortByVProfit)
	if Journalator and Journalator.API then
		Skillet:AddRecipeSorter("JNL: "..L["Most Sold"], plugin.SortMostSold)
		Skillet:AddRecipeSorter("JNL: "..L["Sales Rate"], plugin.SortSalesRate)
	end
end

local function profitPctText(profit,cost,limit)
	local profitPct, proPctTxt
	if cost and cost ~= 0 then
		profitPct = profit * 100 / cost
		if profitPct > limit then
			proPctTxt = ">"..tostring(limit)
		else
			proPctTxt = string.format("%.0d", profitPct)
			if proPctTxt == "" then
				proPctTxt = "0"
			end
		end
	else
		profitPct = 0.0
		proPctTxt = "0"
	end
	--DA.DEBUG(0,"profitPctText: profit= "..tostring(profit)..", cost= "..tostring(cost)..", limit= "..tostring(limit)..", proPctTxt= "..tostring(proPctTxt))
	return proPctTxt,profitPct
end

function plugin.GetExtraText(skill, recipe)
	local label = ""
	local extra_text = ""
	if not recipe then return end
	if not Auctionator then return end
	local itemID = recipe.itemID
--
-- Check for Enchanting. 
--   In Classic Era, Most recipes don't produce an item but we still should get reagent prices.
--   In Wrath, Enchants can be applied to vellum to produce scrolls so use the scroll price instead.
--
	if Skillet.isCraft then
		--DA.DEBUG(0,"GetExtraText: itemID= "..tostring(itemID)..", type= "..type(itemID))
		--DA.DEBUG(0,"GetExtraText: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
		if itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
			--DA.DEBUG(0,"GetExtraText: Change via EnchantSpellToItem, itemID= "..tostring(itemID))
		end
	elseif recipe.tradeID == 7411 and itemID == 0 then
		itemID = recipe.scrollID
		--DA.DEBUG(0,"GetExtraText: Change to scrollID, itemID= "..tostring(itemID))
	end
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
--
-- buyout is Auctionator's price (for one) times the number this recipe makes
--
		local buyout, minBuyout, maxBuyout, hasQ
		buyout = GetBuyout(recipe)
		if buyout and Skillet.db.profile.plugins.ATR.extraBuyout then
			if Skillet.db.profile.plugins.ATR.minmaxBuyout and recipe.supportsQualities then
				minBuyout, maxBuyout, hasQ = GetMinMaxBuyout(recipe)
			end
			if hasQ then
				label = "|r".."ATR "..L["Buyout"].." (min):"
				extra_text = Skillet:FormatMoneyFull(minBuyout, true)
				label = label.."\n".."ATR "..L["Buyout"].." (max):"
				extra_text = extra_text.."\n"..Skillet:FormatMoneyFull(maxBuyout, true)
			else
				label = "|r".."ATR "..L["Buyout"]..":"
				extra_text = Skillet:FormatMoneyFull(buyout, true)
			end
			if Skillet.db.profile.plugins.ATR.qualityBuyout and recipe.supportsQualities then
				label = label.."\n"
				extra_text = extra_text.."\n"
--
-- The hyperlink label can be taller than normal text so 
-- add a transparent icon of the same size to the extra_text
--
				local h = 18
				local price, age, buyout, outputItemInfo
				for _, quality in pairs(recipe.qualityIDs) do
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, quality)
					if outputItemInfo and outputItemInfo.hyperlink then
						age = Auctionator.API.v1.GetAuctionAgeByItemLink(addonName, outputItemInfo.hyperlink)
						if age and age < 2 then
							price = Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink)
							buyout = (price or 0) * recipe.numMade
							--DA.DEBUG(0,"GetExtraText: quality= "..tostring(quality)..", buyout= "..tostring(buyout)..", outputItemInfo= "..DA.DUMP1(outputItemInfo))
							local effectiveILvl, isPreview, baseILvl = GetDetailedItemLevelInfo(outputItemInfo.hyperlink)
							--DA.DEBUG(0,"GetExtraText: effectiveILvl= "..tostring(effectiveILvl)..", itemType= "..tostring(recipe.itemType)..", classID= "..tostring(recipe.classID))
							if recipe.classID == 0 or recipe.classID == 7 then
								label = label.."\n"..outputItemInfo.hyperlink
								extra_text = extra_text.."\n".."|T982414:"..tostring(h)..":1|t"..Skillet:FormatMoneyFull(buyout, true)
							else
--								label = label.."\n"..recipe.name.." ("..tostring(effectiveILvl)..")".." <"..tostring(age)..">"
								label = label.."\n"..recipe.name.." ("..tostring(effectiveILvl)..")"
								extra_text = extra_text.."\n"..Skillet:FormatMoneyFull(buyout, true)
							end
						end
					end
				end
			end
		end
--
-- Collect the price of reagents
--
		toConcatLabel = {}
		toConcatExtra = {}
		local cost = 0
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			local value, needed, id, name, custom = GetReagentData(recipe.reagentData[i])
			value = AddExtraText(value, needed, id, name, custom)
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetExtraText: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value, needed, id, name, custom = GetReagentData(recipe.modifiedData[i])
				value = AddExtraText(value, needed, id, name, custom)
				cost = cost + value
			end
		end
--
-- Show all the reagent information?
--
		if Skillet.db.profile.plugins.ATR.reagentPrices then
			label = label.."\n\n"..table.concat(toConcatLabel,"\n").."\n"
			extra_text = extra_text.."\n\n"..table.concat(toConcatExtra,"\n").."\n"
		else
			label = label.."\n"
			extra_text = extra_text.."\n"
		end
--
-- If reagents were priced as bought from a vendor, should we markup the price? 
--
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			label = label.."\n   "..L["Cost"].." * "..(markup * 100).."%:\n"
			cost = cost * markup
		else
			label = label.."\n   "..L["Cost"]..":\n"
		end
		extra_text = extra_text.."\n"..Skillet:FormatMoneyFull(cost, true).."\n"
--
-- If we craft this item, will we make a profit?
--
		if buyout then
			local ah_tax = Skillet.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
			local profit = buyout * ah_tax - cost
			if Skillet.db.profile.plugins.ATR.extraProfitValue or Skillet.db.profile.plugins.ATR.extraProfitPercentage then
				label = label.."\n"
				extra_text = extra_text.."\n"
			end
--
-- Show the profit absolute value and as a percentage of the cost
--
			if Skillet.db.profile.plugins.ATR.extraProfitValue then
				label = label.."   Profit:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(profit, true).."\n"
			end
			if Skillet.db.profile.plugins.ATR.extraProfitPercentage then
				label = label.."   Profit percentage:\n"
				extra_text = extra_text..profitPctText(profit,cost,9999).."%\n"
			end
		end
--
-- Show Journalator sales info
--
		if addonName and Journalator and Skillet.db.profile.plugins.ATR.journalatorE then
			label = label.."\n"
			extra_text = extra_text.."\n"
			local itemName = C_Item.GetItemInfo(itemID)
			local salesRate, successCount, failedCount, lastSold, lastBought
			if Journalator.API and itemName then
				successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemName)
				failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemName)
				if successCount > 0 then
					salesRate = string.format("%.0d", successCount / (successCount + failedCount) * 100).."%"
				else
					salesRate = nil
				end
				lastSold = Journalator.API.v1.GetRealmLastSoldByItemName(addonName, itemName)
				lastBought = Journalator.API.v1.GetRealmLastBoughtByItemName(addonName, itemName)
				--DA.DEBUG(0,"GetExtraText(1): itemName= "..tostring(itemName)..", successCount= "..tostring(successCount)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			elseif itemName then
				salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)
				--DA.DEBUG(0,"GetExtraText(2): itemName= "..tostring(itemName)..", salesRate= "..tostring(salesRate)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			end
			if salesRate and (string.find(salesRate,"%%") or DA.DebugShow) then
				label = label.."   salesRate:\n"
				extra_text = extra_text..tostring(salesRate).."\n"
			end
			if successCount and (successCount > 0 or DA.DebugShow) then
				label = label.."   successCount:\n"
				extra_text = extra_text..tostring(successCount).."\n"
			end
			if failedCount and (failedCount > 0 or DA.DebugShow) then
				label = label.."   failedCount:\n"
				extra_text = extra_text..tostring(failedCount).."\n"
			end
			if lastSold and (lastSold > 0 or DA.DebugShow) then
				label = label.."   lastSold:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(lastSold, true).."\n"
			end
			if lastBought and (lastBought > 0 or DA.DebugShow) then
				label = label.."   lastBought:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(lastBought, true).."\n"
			end
		end
	end
	return label, extra_text
end

--
-- Returns a text string suffix
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text, buyout, cost, profit, percentage, sellout, vprofit
	local successCount = 0
	local failedCount = 0
	local salesRate = nil
	if not recipe then return end
	--DA.DEBUG(0,"RecipeNameSuffix: recipe= "..DA.DUMP1(recipe,1))
	local itemID = recipe.itemID
	--DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
--
-- Check for Enchanting. Most recipes don't produce an item but
-- we still should get reagent prices.
--
	if Skillet.isCraft then
		--DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
		--DA.DEBUG(0,"RecipeNameSuffix: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
		if itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
			--DA.DEBUG(0,"RecipeNameSuffix: Change via EnchantSpellToItem, itemID= "..tostring(itemID))
		end
	elseif recipe.tradeID == 7411 and itemID == 0 then
		itemID = recipe.scrollID
		--DA.DEBUG(0,"RecipeNameSuffix: Change to scrollID, itemID= "..tostring(itemID))
	end
	local itemName
	if itemID then itemName = C_Item.GetItemInfo(itemID) end
	--DA.DEBUG(0,"RecipeNameSuffix: itemName= "..tostring(itemName)..", type= "..type(itemName))
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
		buyout, sellout = GetBuyout(recipe)
		cost = 0
		for i=1,#recipe.reagentData do
			local value = GetReagentData(recipe.reagentData[i])
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetRecipeData: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value = GetReagentData(recipe.modifiedData[i])
				cost = cost + value
			end
		end
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = Skillet.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		vprofit = sellout - cost
		if cost ~= 0 then
			percentage = profit * 100 / cost
		end

		if addonName and Journalator and Journalator.API then
			if itemName then
				successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemName)
				failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemName)
				if (successCount + failedCount) > 0 then
					salesRate = string.format("%2.0f", successCount / (successCount + failedCount) * 100).."%"
				else
					salesRate = string.format("%2.0f", 0).."%"
				end
			end
			--DA.DEBUG(0, "RecipeNameSuffix: itemName= "..tostring(itemName)..", successCount="..tostring(successCount)..", failedCount="..tostring(failedCount)..", salesRate="..tostring(salesRate))
		end

--
-- When one of our sorts is active, the suffix is the sort value
-- If none of our sorts is active, the suffix is determined by the option settings
--
		local getSort = GetATRSort()
		local isSortA = IsATRSort()
		local isSortJ = IsJNLSort()
		local isSort = isSortA or isSortJ
		--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort))
		if getSort == "ATR: "..L["Buyout"] or ((not isSortA or isSortJ) and Skillet.db.profile.plugins.ATR.suffixBuyout) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixBuyout= "..tostring(Skillet.db.profile.plugins.ATR.suffixBuyout))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(buyout, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(buyout, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["Cost"] or ((not isSortA or isSortJ) and Skillet.db.profile.plugins.ATR.suffixCost) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixCost= "..tostring(Skillet.db.profile.plugins.ATR.suffixCost))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(cost, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(cost, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["Profit"] or ((not isSortA or isSortJ) and Skillet.db.profile.plugins.ATR.suffixProfitValue) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitValue= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitValue))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
			if not isSort and Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
				text = nil
			end
		elseif getSort == "ATR: "..L["Percent"] or ((not isSortA or isSortJ) and Skillet.db.profile.plugins.ATR.suffixProfitPercentage) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitPercentage))
			if text then
				text = text.." ("..profitPctText(profit,cost,999).."%)"
			else
				text = "("..profitPctText(profit,cost,999).."%)"
			end
		elseif getSort == "ATR: "..L["Sellout"] then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitPercentage))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(sellout, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(sellout, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["VProfit"] then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitPercentage))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(vprofit, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(vprofit, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
			if Skillet.db.profile.plugins.ATR.onlyPositive and vprofit <= 0 then
				text = nil
			end
		end
		if Journalator and Skillet.db.profile.plugins.ATR.journalatorC then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", journalatorC= "..tostring(Skillet.db.profile.plugins.ATR.journalatorC))
				if text then
					text = text.." ["..string.format("%3.0f", successCount).."]"
				else
					text = "["..string.format("%3.0f", successCount).."]"
				end
		end
		if Journalator and Skillet.db.profile.plugins.ATR.journalatorS then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", journalatorS= "..tostring(Skillet.db.profile.plugins.ATR.journalatorS))
			if salesRate and string.find(salesRate,"%%") then
				if text then
					text = text.." ["..tostring(salesRate).."]"
				else
					text = "["..tostring(salesRate).."]"
				end
			end
		end
	end
	recipe.buyout = buyout
	recipe.cost = cost
	recipe.profit = profit
	recipe.percentage = percentage
	recipe.sellout = sellout
	recipe.vprofit = vprofit
	recipe.mostsold = successCount
	recipe.salesrate = salesRate
	recipe.suffix = SetATRsuffix(recipe)
	return text
end

Skillet:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function

--
-- Auctionator button support
--  whichOne:
--    true will search for the items in the ShoppingList
--    false (or nil) will search for the item and reagents in the MainFrame
--
function Skillet:AuctionatorSearch(whichOne)
	DA.DEBUG(0, "AuctionatorSearch("..tostring(whichOne)..")")
	local shoppingListName
	local items = {}
	local recipe = Skillet:GetRecipeDataByTradeIndex(Skillet.currentTrade, Skillet.selectedSkill)
	local useSearchExact = Skillet.db.profile.plugins.ATR.useSearchExact
	--DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
	if whichOne then
		shoppingListName = L["Shopping List"]
		local name = nil
		if not Skillet.db.profile.include_alts then
			name = Skillet.currentPlayer
		end
		local list = Skillet:GetShoppingList(name, Skillet.db.profile.same_faction, Skillet.db.profile.include_guild)
		if not list or #list == 0 then
			DA.DEBUG(0,"AuctionatorSearch: Shopping List is empty")
			return
		end
		for i=1,#list,1 do
			local id  = list[i].id
			local name = C_Item.GetItemInfo(id)
			if name and not Skillet:VendorSellsReagent(id) then
				table.insert (items, name)
				DA.DEBUG(1, "AuctionatorSearch: Item["..tostring(i).."] "..name.." ("..tostring(id)..") added")
			end
		end
	else
		if not recipe then
			return
		end
		local itemID = recipe.itemID
--
-- Check for Enchanting. For Wrath, Add the scroll for the enchant instead
--
		if Skillet.isCraft and itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
		end
		if itemID ~= 0 then
			shoppingListName = C_Item.GetItemInfo(itemID)
		else
			shoppingListName = recipe.name
		end
		if (shoppingListName) then
			if recipe.tradeID == 7411 and not Skillet.isCraft then
				if recipe.scrollID then
					local scrollName = C_Item.GetItemInfo(recipe.scrollID)
					table.insert(items, scrollName)
				end
			elseif not recipe.salvage then
				table.insert(items, shoppingListName)
			end
		end
--
-- Add the reagent names
--
		local i
		for i=1, #recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if not reagent then
				break
			end
			local needed = reagent.numNeeded or 0
			local id
			if isRetail then
				id = reagent.reagentID
			else
				id = reagent.id
			end
			if id then
				local reagentName = C_Item.GetItemInfo(id)
				if (reagentName) then
					if not Skillet:VendorSellsReagent(id) then
						table.insert (items, reagentName)
						DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..reagentName)
					else
						DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..reagentName)
					end
				end
			end
		end
		if recipe.salvage then
			--DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
			--DA.DEBUG(1, "AuctionatorSearch: numSalvage= "..tostring(#recipe.salvage)..", salvage= "..DA.DUMP(recipe.salvage))
			useSearchExact = true
			for i=1, #recipe.salvage do
				local id = recipe.salvage[i]
				local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)
				if quality == nil or quality == 1 then
					local name, bname = self:nameWithQuality(id)
					if (bname) then
						if not Skillet:VendorSellsReagent(id) then
							table.insert (items, bname)
							DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..bname)
						else
							DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..bname)
						end
					end
				end
			end
		end
		if recipe.numModified then
			for i=1, recipe.numModified do
				local id = recipe.modifiedData[i].reagentID
				local name, bname = self:nameWithQuality(id)
				if (bname) then
					if not Skillet:VendorSellsReagent(id) then
						table.insert (items, bname)
						DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..bname)
					else
						DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..bname)
					end
				end
			end
		end
	end
	if Atr_SelectPane and Atr_SearchAH then
		DA.DEBUG(0, "AuctionatorSearch: shoppingListName= "..tostring(shoppingListName)..", items= "..DA.DUMP1(items))
		local BUY_TAB = 3;
		Atr_SelectPane(BUY_TAB)
		Atr_SearchAH(shoppingListName, items)
	elseif useSearchExact and Auctionator.API.v1.MultiSearchExact then
		DA.DEBUG(0, "AuctionatorSearch: (exact) addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
		Auctionator.API.v1.MultiSearchExact(addonName, items)
	elseif Auctionator.API.v1.MultiSearch then
		DA.DEBUG(0, "AuctionatorSearch: addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
		Auctionator.API.v1.MultiSearch(addonName, items)
	end
end
