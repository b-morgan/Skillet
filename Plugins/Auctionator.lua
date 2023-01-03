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
		suffixBuyout = {
			type = "toggle",
			name = "suffixBuyout",
			desc = "Show buyout value",
			get = function()
				return Skillet.db.profile.plugins.ATR.suffixBuyout
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.suffixBuyout = value
			end,
			order = 9
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
			order = 10
		},
		suffixProfitValue = {
			type = "toggle",
			name = "suffixProfitValue",
			desc = "Show profit value",
			get = function()
				return Skillet.db.profile.plugins.ATR.suffixProfitValue
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.suffixProfitValue = value
			end,
			order = 11
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
			order = 12
		},
		suffixProfitPercentage = {
			type = "toggle",
			name = "suffixProfitPercentage",
			desc = "Show profit as percentage",
			get = function()
				return Skillet.db.profile.plugins.ATR.suffixProfitPercentage
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.suffixProfitPercentage = value
			end,
			order = 13
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
			order = 14
		},
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
			order = 15
		},
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
			order = 16,
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
			order = 17,
		},
		journalatorS = {
			type = "toggle",
			name = "Journalator Suffix",
			desc = "Show Journalator sales rate",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return Skillet.db.profile.plugins.ATR.journalatorS
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.journalatorS = value
			end,
			order = 18,
		},
		journalatorC = {
			type = "toggle",
			name = "Journalator Count",
			desc = "Show Journalator success count",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return Skillet.db.profile.plugins.ATR.journalatorC
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.journalatorC = value
			end,
			order = 19,
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

local function GetRecipeData(recipe)
	--DA.DEBUG(0,"GetRecipeData: recipe= "..DA.DUMP1(recipe,1))
	if not recipe then return end
	local buyout, cost, profit, percentage
	local itemID
	if recipe.scrollID then
		itemID = recipe.scrollID
	else
		itemID = recipe.itemID
	end
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
		local value
		if Atr_GetAuctionBuyout then
			value = Atr_GetAuctionBuyout(itemID) or 0
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			value = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0
		else
			return
		end
		buyout = value * recipe.numMade
		cost = 0
		for i=1,#recipe.reagentData do
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
			local value
			if Atr_GetAuctionBuyout then
				value = (Atr_GetAuctionBuyout(id) or 0) * needed
			elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
				value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0) * needed
			else
				value = 0
			end
			if Skillet:VendorSellsReagent(id) then
				if Skillet.db.profile.plugins.ATR.buyablePrices then
					if Skillet.db.profile.plugins.ATR.useVendorCalc then
						local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
						value = ( select(11,GetItemInfo(id)) or 0 ) * needed * buyFactor
					end
				else
					value = 0
				end
			end
			cost = cost + value
		end
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = Skillet.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		percentage = profit * 100 / cost
		--DA.DEBUG(0,"GetRecipeData: buyout= "..tostring(buyout)..", profit= "..tostring(profit)..", percentage= "..tostring(percentage))
		recipe.buyout = buyout
		recipe.profit = profit
		recipe.percentage = percentage
		recipe.suffix = profit
	end
end

--
-- Sort by the Journalator API function GetRealmSuccessCountByItemName
--
-- For enchanting, use the scrollID instead of the itemID
--
function plugin.SortMostSold(skill,a,b)
	if a.subGroup or b.subGroup then
		return NOSORT(skill, a, b)
	end
	local recipeA, recipeB, itemNameA, itemNameB, successCountA, successCountB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeB= "..DA.DUMP1(recipeB))
	if recipeA.scrollID then
		itemNameA = GetItemInfo(recipeA.scrollID)
	elseif recipeA.itemID then
		itemNameA = GetItemInfo(recipeA.itemID)
	end
	if recipeB.scrollID then
		itemNameB = GetItemInfo(recipeB.scrollID)
	elseif recipeB.itemID then
		itemNameB = GetItemInfo(recipeB.itemID)
	end
	--DA.DEBUG(0,"SortMostSold: itemNameA= "..tostring(itemNameA)..", raw itemNameB= "..tostring(itemNameB))
	if Journalator.API and itemNameA and itemNameB then
		successCountA = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameA)
		successCountB = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameB)
	end
	successCountA = successCountA or 0
	successCountB = successCountB or 0
	if successCountA > 0 and successCountB > 0 then
		--DA.DEBUG(0,"SortMostSold: successCountA= "..tostring(successCountA)..", successCountB= "..tostring(successCountB))
	end
	return (successCountA > successCountB)
end

--
-- Sort by Auctionator Buyout price
--
function plugin.SortByBuyout(skill,a,b)
	if a.subGroup or b.subGroup then
		return NOSORT(skill, a, b)
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
-- Sort by calculated profit value
--
function plugin.SortByProfit(skill,a,b)
	if a.subGroup or b.subGroup then
		return NOSORT(skill, a, b)
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
-- Sort by calculated profit percentage
--
function plugin.SortByPercent(skill,a,b)
	if a.subGroup or b.subGroup then
		return NOSORT(skill, a, b)
	end
	local recipeA, recipeB, idA, idB, percentA, percentB
	recipeA = Skillet:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByPercent: recipeA= "..DA.DUMP1(recipeA))
	recipeB = Skillet:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByPercent: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.percentage then
		GetRecipeData(recipeA)
	end
	percentA = recipeA.percentage or 0
	if not recipeB.percentage then
		GetRecipeData(recipeB)
	end
	percentB = recipeB.percentage or 0
	--DA.DEBUG(0,"SortByPercent: percentA= "..tostring(percentA)..", percentB= "..tostring(percentB))
	return (percentA > percentB)
end

function plugin.OnInitialize()
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
	Skillet:AddRecipeSorter("ATR: "..L["Profit"], plugin.SortByProfit)
	Skillet:AddRecipeSorter("ATR: "..L["Percent"], plugin.SortByPercent)
	if Journalator and Journalator.API then
		Skillet:AddRecipeSorter("JNL: "..L["Most Sold"], plugin.SortMostSold)
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
		local buyout
		if Atr_GetAuctionBuyout then
			buyout = (Atr_GetAuctionBuyout(itemID) or 0) * recipe.numMade
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
		else
			return
		end
		if buyout and Skillet.db.profile.plugins.ATR.extraBuyout then
			label = "|r".."ATR "..L["Buyout"]..":"
			extra_text = Skillet:FormatMoneyFull(buyout, true)
		end
--
-- Collect the price of reagents
--
		local toConcatLabel = {}
		local toConcatExtra = {}
		local cost = 0
		for i=1,#recipe.reagentData do
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
			local itemName = ""
			if id then
				itemName = GetItemInfo(id)
				if not itemName then
					itemName = ""
				end
			end
--
-- Default value for a reagent is the Auctionator price
--
			local value
			if Atr_GetAuctionBuyout then
				value = (Atr_GetAuctionBuyout(id) or 0) * needed
			elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
				value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0) * needed
			else
				value = 0
			end
			if not Skillet:VendorSellsReagent(id) then
--
-- Not sold by a vendor so use the default
--
				toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, itemName)
				toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
			else
				toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, itemName, L["buyable"])
				if Skillet.db.profile.plugins.ATR.buyablePrices then
--
-- If this reagent is sold by a vendor, then use that (calculated) price instead
--
					local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
					value = ( select(11,GetItemInfo(id)) or 0 ) * needed * buyFactor
					toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
				else
--
-- If this reagent is sold by a vendor, don't use the Auctionator price
--
					value = 0
					toConcatExtra[#toConcatExtra+1] = ""
				end
			end
			cost = cost + value
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
			local itemName = GetItemInfo(itemID)
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
				--DA.DEBUG(0,"itemName= "..tostring(itemName)..", successCount= "..tostring(successCount)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			elseif itemName then
				salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)
				--DA.DEBUG(0,"itemName= "..tostring(itemName)..", salesRate= "..tostring(salesRate)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			end
			if salesRate and string.find(salesRate,"%%") then
				label = label.."   salesRate:\n"
				extra_text = extra_text..tostring(salesRate).."\n"
			end
			if successCount and successCount > 0 then
				label = label.."   successCount:\n"
				extra_text = extra_text..tostring(successCount).."\n"
			end
			if failedCount and failedCount > 0 then
				label = label.."   failedCount:\n"
				extra_text = extra_text..tostring(failedCount).."\n"
			end
			if lastSold and lastSold > 0 then
				label = label.."   lastSold:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(lastSold, true).."\n"
			end
			if lastBought and lastBought > 0 then
				label = label.."   lastBought:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(lastBought, true).."\n"
			end
		end
	end
	return label, extra_text
end

--
-- Returns a text representation of profit, numerical value of profit (for sorting purposes)
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text, buyout, cost, profit, percentage
	if not recipe then return end
	--DA.DEBUG(0,"RecipeNameSuffix: recipe= "..DA.DUMP1(recipe,1))
	local itemID = recipe.itemID
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
	if itemID then itemName = GetItemInfo(itemID) end
	--DA.DEBUG(0,"RecipeNameSuffix: itemName= "..tostring(itemName)..", type= "..type(itemName))
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
		local value
		if Atr_GetAuctionBuyout then
			value = Atr_GetAuctionBuyout(itemID) or 0
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			value = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0
		else
			return
		end
		--DA.DEBUG(0,"RecipeNameSuffix: value= "..tostring(value))
		buyout = value * recipe.numMade
		cost = 0
		for i=1,#recipe.reagentData do
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
			local name = GetItemInfo(id) or id
			local value
			if Atr_GetAuctionBuyout then
				value = (Atr_GetAuctionBuyout(id) or 0) * needed
			elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
				value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0) * needed
			else
				value = 0
			end
			if Skillet:VendorSellsReagent(id) then
				if Skillet.db.profile.plugins.ATR.buyablePrices then
					if Skillet.db.profile.plugins.ATR.useVendorCalc then
						local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
						value = ( select(11,GetItemInfo(id)) or 0 ) * needed * buyFactor
					end
				else
					value = 0
				end
			end
			--DA.DEBUG(1, "RecipeNameSuffix: reagent["..i.."] ("..id..") "..tostring(name)..", value= "..tostring(value))
			cost = cost + value
		end
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = Skillet.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		percentage = profit * 100 / cost

--
-- When one of our sorts is active, the suffix is the sort value
-- If none of our sorts is active, the suffix is determined by the option settings
--
		local getSort = GetATRSort()
		local isSort = IsATRSort()
		--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort))
		if getSort == "ATR: "..L["Buyout"] or (not isSort and Skillet.db.profile.plugins.ATR.suffixBuyout) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixBuyout= "..tostring(Skillet.db.profile.plugins.ATR.suffixBuyout))
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(buyout, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(buyout, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
		else
			if getSort == "ATR: "..L["Profit"] or (not isSort and Skillet.db.profile.plugins.ATR.suffixProfitValue) then
				--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitValue= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitValue))
				if Skillet.db.profile.plugins.ATR.useShort then
					text = Skillet:FormatMoneyShort(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
				else
					text = Skillet:FormatMoneyFull(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
				end
			end
			if getSort == "ATR: "..L["Percent"] or (not isSort and Skillet.db.profile.plugins.ATR.suffixProfitPercentage) then
				--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(Skillet.db.profile.plugins.ATR.suffixProfitPercentage))
				if text then
					text = text.." ("..profitPctText(profit,cost,999).."%)"
				else
					text = "("..profitPctText(profit,cost,999).."%)"
				end
			end
		end
--
-- Enchants don't have any profit so if checked, always display the (negative) cost.
--
		if recipe.tradeID == 7411 then
			if not Skillet.db.profile.plugins.ATR.alwaysEnchanting then
				if not isSort and Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
					text = nil
				end
			end
		elseif not isSort and Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
			text = nil
		end
--
-- Show Journalator salesRate or successCount
--
		if addonName and itemName and Journalator and Skillet.db.profile.plugins.ATR.journalatorS then
			local salesRate, successCount, failedCount, lastSold, lastBought
			if Journalator.API then
				successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemName)
				failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemName)
				if successCount > 0 then
					salesRate = string.format("%.0d", successCount / (successCount + failedCount) * 100).."%"
				else
					salesRate = nil
				end
				--DA.DEBUG(0,"itemName= "..tostring(itemName)..", successCount= "..tostring(successCount)..", failedCount= "..tostring(failedCount)..", salesRate= "..tostring(salesRate))
			else
				salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)
				--DA.DEBUG(0,"itemName= "..tostring(itemName)..", salesRate= "..tostring(salesRate)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			end
			if Skillet.db.profile.plugins.ATR.journalatorC then
				if successCount and successCount > 0 then
					if text then
						text = text.." ["..tostring(successCount).."]"
					else
						text = "["..tostring(successCount).."]"
					end
				end
			else
				if salesRate and string.find(salesRate,"%%") then
					if text then
						text = text.." ["..tostring(salesRate).."]"
					else
						text = "["..tostring(salesRate).."]"
					end
				end
			end
		end
	end
	--DA.DEBUG(0,"RecipeNameSuffix: text= "..tostring(text)..", buyout= "..tostring(buyout)..", profit= "..tostring(profit)..", percentage= "..tostring(percentage))
	recipe.buyout = buyout
	recipe.profit = profit
	recipe.percentage = percentage
	recipe.suffix = profit
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
	DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
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
			local name = GetItemInfo(id)
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
			shoppingListName = GetItemInfo(itemID)
		else
			shoppingListName = recipe.name
		end
		if (shoppingListName) then
			if recipe.tradeID == 7411 and not Skillet.isCraft then
				if recipe.scrollID then
					local scrollName = GetItemInfo(recipe.scrollID)
					table.insert(items, scrollName)
				end
			else
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
				local reagentName = GetItemInfo(id)
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
		if recipe.numModified then
			for i=1, recipe.numModified do
--[[
				for j=1, #recipe.modifiedData[i].schematic.reagents do
					local id = recipe.modifiedData[i].schematic.reagents[j].itemID
				end
--]]
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
	elseif Skillet.db.profile.plugins.ATR.useSearchExact and Auctionator.API.v1.MultiSearchExact then
		DA.DEBUG(0, "AuctionatorSearch: (exact) addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
		Auctionator.API.v1.MultiSearchExact(addonName, items)
	elseif Auctionator.API.v1.MultiSearch then
		DA.DEBUG(0, "AuctionatorSearch: addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
		Auctionator.API.v1.MultiSearch(addonName, items)
	end
end
