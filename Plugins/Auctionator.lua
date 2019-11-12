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

--
-- Includes changes from GuardsmanBogo
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
				if value then
					Skillet.db.profile.plugins.ATR.useShort = value
				end
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
				if value then
					Skillet.db.profile.plugins.ATR.onlyPositive = value
				end
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
				if value then
					Skillet.db.profile.plugins.ATR.reagentPrices = value
				end
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = "Show AH prices for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.buyablePrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.buyablePrices = value
				if value then
					Skillet.db.profile.plugins.ATR.buyablePrices = value
				end
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
				if value then
					Skillet.db.profile.plugins.ATR.useVendorCalc = value
				end
			end,
			order = 6
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
			order = 10
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
			end,
			width = "double",
			order = 11,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.ATR then
		Skillet.db.profile.plugins.ATR = {}
		Skillet.db.profile.plugins.ATR.enabled = true
		Skillet.db.profile.plugins.ATR.buyFactor = buyFactorDef
		Skillet.db.profile.plugins.ATR.markup = markupDef
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	if not recipe then return end
	local itemID = recipe.itemID
	if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
		local buyout = ( Atr_GetAuctionBuyout(itemID) or 0 ) * recipe.numMade
		if buyout then
			extra_text = Skillet:FormatMoneyFull(buyout, true)
			label = "|r".. L["Buyout"]..":"
		end
		if Skillet.db.profile.plugins.ATR.reagentPrices then
			local toConcatLabel = {}
			local toConcatExtra = {}
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local reagent = recipe.reagentData[i]
				if not reagent then
					break
				end
				local needed = reagent.numNeeded or 0
				local id = reagent.reagentID
				local itemName
				if id then
					itemName = GetItemInfo(id)
				else
					itemName = tostring(id)
				end
				local text
				local value = ( Atr_GetAuctionBuyout(id) or 0 ) * needed
				local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
				if Skillet:VendorSellsReagent(id) then
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, itemName, L["buyable"])
					if Skillet.db.profile.plugins.ATR.buyablePrices then
						if Skillet.db.profile.plugins.ATR.useVendorCalc then
							value = ( Atr_GetSellValue(id) or 0 ) * needed * buyFactor
						end
						toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
					else
						value = 0
					toConcatExtra[#toConcatExtra+1] = ""
					end
				else
					toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, itemName)
				end
				cost = cost + value
			end
			if Skillet.db.profile.plugins.ATR.useVendorCalc then
				local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
				label = label.."\n\n"..table.concat(toConcatLabel,"\n").."\n   "..L["Reagents"].." * "..(markup * 100).."%:\n"
				extra_text = extra_text.."\n\n"..table.concat(toConcatExtra,"\n").."\n"..Skillet:FormatMoneyFull(cost * markup, true).."\n"
			else
				label = label.."\n\n"..table.concat(toConcatLabel,"\n").."\n   "..L["Reagents"]..":\n"
				extra_text = extra_text.."\n\n"..table.concat(toConcatExtra,"\n").."\n"..Skillet:FormatMoneyFull(cost, true).."\n"
			end
		end
	end
	return label, extra_text
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if not recipe then return end
	DA.DEBUG(0,"RecipeNameSuffix: recipe= "..DA.DUMP1(recipe,1))
	local itemID = recipe.itemID
	DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
	local itemName = GetItemInfo(itemID)
	DA.DEBUG(0,"RecipeNameSuffix: itemName= "..tostring(itemName)..", type= "..type(itemName))
	if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
		local value = Atr_GetAuctionBuyout(itemID) or 0
		DA.DEBUG(0,"RecipeNameSuffix: value= "..tostring(value))
		local buyout = value * recipe.numMade
		if Skillet.db.profile.plugins.ATR.reagentPrices then
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local needed = recipe.reagentData[i].numNeeded or 0
				local id = recipe.reagentData[i].id
				local value = ( Atr_GetAuctionBuyout(id) or 0 ) * needed
				local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
				if Skillet:VendorSellsReagent(id) then
					if Skillet.db.profile.plugins.ATR.buyablePrices then
						if Skillet.db.profile.plugins.ATR.useVendorCalc then
							value = ( Atr_GetSellValue(id) or 0 ) * needed * buyFactor
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
			local profit = buyout - cost
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(profit, true)
			else
				text = Skillet:FormatMoneyFull(profit, true)
			end
			if Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
				text = nil
			end
		end
	end
	return text
end

-- Skillet:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function

--
-- Auctionator support
--  whichOne:
--    false (or nil) will search for the item and reagents in the MainFrame
--    true will search for the items in the ShoppingList
--
function Skillet:AuctionatorSearch(whichOne)
	if not AuctionatorLoaded or not AuctionFrame then
		return
	end
	if not AuctionFrame:IsShown() then
		if whichOne then
			Atr_Error_Display("When the Auction House is open\nclicking this button tells Auctionator\nto scan for the items in the Shopping List.")
		else
			Atr_Error_Display("When the Auction House is open\nclicking this button tells Auctionator\nto scan for the item and all its reagents.")
		end
		return
	end
	local shoppingListName
	local items = {}
	if whichOne then
		shoppingListName = L["Shopping List"]
		local list = Skillet:GetShoppingList(Skillet.currentPlayer, false)
		if not list or #list == 0 then
			--DA.DEBUG(0,"Shopping List is empty")
			return
		end
		for i=1,#list,1 do
			local id  = list[i].id
			local name = GetItemInfo(id)
			if name and not Skillet:VendorSellsReagent(id) then
				table.insert (items, name)
				--DA.DEBUG(0, "Item["..tostring(i).."] "..name.." ("..tostring(id)..") added")
			end
		end
	else
		local recipe, recipeId = Skillet:GetRecipeDataByTradeIndex(Skillet.currentTrade, Skillet.selectedSkill)
		if not recipe then
			return
		end
		shoppingListName = GetItemInfo(recipe.itemID)
		if (shoppingListName == nil) then
			shoppingListName = Skillet:GetRecipeName(recipeId)
		end
		if (shoppingListName) then
			table.insert (items, shoppingListName)
		end
		local numReagents = #recipe.reagentData
		local reagentIndex
		for reagentIndex = 1, numReagents do
			local reagentId = recipe.reagentData[reagentIndex].id
			if reagentId and not Skillet:VendorSellsReagent(reagentId) then
				local reagentName = GetItemInfo(reagentId)
				if (reagentName) then
					table.insert (items, reagentName)
					--DA.DEBUG(0, "Reagent num "..reagentIndex.." ("..reagentId..") "..reagentName.." added")
				end
			end
		end
	end
	local BUY_TAB = 3;
	Atr_SelectPane(BUY_TAB)
	Atr_SearchAH(shoppingListName, items)
end
