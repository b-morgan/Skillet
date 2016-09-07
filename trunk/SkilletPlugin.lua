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

local L = Skillet.L

Skillet.displayDetailPlugins = {}		-- each plugin will register if it has something to add
Skillet.RecipeNamePlugins = {}			-- each plugin will register, only one can be active

Skillet.pluginsOrder = 2
Skillet.pluginsOptions = {
		name = "Plugins",
		type = "group",
		childGroups = "tree",
		args = {
			RecipeNamePlugins = {
				type = "select",
				name = "RecipeNamePlugins",
				desc = "Only one plugin can supply prefix and/or suffix text",
				order = 1,
				get = function() 
					return Skillet.db.profile.plugins.recipeNamePlugin
				end,
				set = function(_, value)
					Skillet.db.profile.plugins.recipeNamePlugin = value
					Skillet:UpdateTradeSkillWindow()
				end,
				values = {
					[" "] = " ",
--					Additional entries filled in dynamically by RegisterRecipeNamePlugin
				},
			},
-- 			Filled in dynamically by AddPluginOptions
		},
	}

function Skillet:AddPluginOptions(options)
	options.order = Skillet.pluginsOrder
	Skillet.pluginsOrder = Skillet.pluginsOrder + 1
	Skillet.pluginsOptions.args[options.name] = options
end

function Skillet:RegisterRecipeNamePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterRecipeNamePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = Skillet[moduleName]
		if module and type(module) == "table" and (module.RecipeNamePrefix or module.RecipeNameSuffix) then
			Skillet.RecipeNamePlugins[moduleName] = module
			Skillet.pluginsOptions.args.RecipeNamePlugins.values[module.options.name] = module.options.name
		end
	end
end

function Skillet:IsRecipeNamePluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return Skillet.RecipeNamePlugins[moduleName] ~= nil
	end
end

function Skillet:RegisterDisplayDetailPlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterDisplayDetailPlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = Skillet[moduleName]
		if module and type(module) == "table" and module.GetExtraText then
			Skillet.displayDetailPlugins[moduleName] = module
		end
	end
end

function Skillet:IsDisplayDetailPluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return Skillet.displayDetailPlugins[moduleName] ~= nil
	end
end

function Skillet:GetExtraText(skill, recipe)
	local output_label, output_text
	for k,v in pairs(Skillet.displayDetailPlugins) do
		local label,text = v.GetExtraText(skill, recipe)
		if label and label ~= "" then
			if output_label then
				output_label = output_label.."\n\n"
			else
				output_label = ""
			end
			output_label = output_label..label
		end
		if text and text ~= "" then
			if output_text then
				output_text = output_text.."\n\n"
			else
				output_text = ""
			end
			output_text = output_text..text
		end
	end
--	call the ThirdPartyHooks function and process any returns
	local label,text = Skillet:GetExtraItemDetailText(skill, recipe)
	if label and label ~= "" then
		if output_label then
			output_label = output_label.."\n\n"
		else
			output_label = ""
		end
		output_label = output_label..label
	end
	if text and text ~= "" then
		if output_text then
			output_text = output_text.."\n\n"
		else
			output_text = ""
		end
		output_text = output_text..text
	end
	return output_label, output_text
end

function Skillet:RecipeNamePrefix(skill, recipe)
	local text
	local recipeNamePlugin = self.db.profile.plugins.recipeNamePlugin
	if recipeNamePlugin and recipeNamePlugin ~= " " then
		for k,v in pairs(Skillet.RecipeNamePlugins) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNamePrefix and v.options.name == recipeNamePlugin then
				text = v.RecipeNamePrefix(skill, recipe)
				break
			end
		end
	else
--		call the ThirdPartyHooks function and process any returns
		text = Skillet:GetRecipeNamePrefix(skill, recipe)
	end
	return text
end

function Skillet:RecipeNameSuffix(skill, recipe)
	local text
	local recipeNamePlugin = self.db.profile.plugins.recipeNamePlugin
	if recipeNamePlugin and recipeNamePlugin ~= " " then
		for k,v in pairs(Skillet.RecipeNamePlugins) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNameSuffix and v.options.name == recipeNamePlugin then
				text = v.RecipeNameSuffix(skill, recipe)
				break
			end
		end
	else
--		call the ThirdPartyHooks function and process any returns
		text = Skillet:GetRecipeNameSuffix(skill, recipe)
	end
	return text
end

function Skillet:InitializePlugins()
	DA.DEBUG(0,"InitializePlugins()")
	for k,v in pairs(Skillet.displayDetailPlugins) do
		DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
		if v and v.OnInitialize then
			v.OnInitialize()
		end
	end
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet Plugins", Skillet.pluginsOptions)
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:AddToBlizOptions("Skillet Plugins", "Plugins", "Skillet")
end

function Skillet:EnablePlugins()
	DA.DEBUG(0,"EnablePlugins()")
	for k,v in pairs(Skillet.displayDetailPlugins) do
		DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
		if v and v.OnEnable then
			v.OnEnable()
		end
	end
end