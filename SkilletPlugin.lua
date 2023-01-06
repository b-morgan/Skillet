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

Skillet.registeredPlugins = {}		-- plugins that have registered a function
Skillet.updatePlugins = {}			-- each plugin will register if it has an Update function
Skillet.displayDetailPlugins = {}	-- each plugin will register if it has a GetExtraText function
Skillet.RecipeNamePrefixes = {}			-- each plugin will register, only one can be active
Skillet.RecipeNameSuffixes = {}			-- each plugin will register, only one can be active

Skillet.pluginsOrder = 2
Skillet.pluginsOptions = {
		name = "Plugins",
		type = "group",
		childGroups = "tree",
		args = {
			RecipeNamePrefix = {
				type = "select",
				name = "RecipeNamePrefix",
				desc = "Only one plugin can supply prefix text",
				order = 1,
				get = function() 
					return Skillet.db.profile.plugins.recipeNamePrefix
				end,
				set = function(_, value)
					Skillet.db.profile.plugins.recipeNamePrefix = value
					Skillet:UpdateTradeSkillWindow()
				end,
				values = {
					[" "] = " ",
--					Additional entries filled in dynamically by RegisterRecipeNamePlugin
				},
			},
			RecipeNameSuffix = {
				type = "select",
				name = "RecipeNameSuffix",
				desc = "Only one plugin can supply suffix text",
				order = 1,
				get = function() 
					return Skillet.db.profile.plugins.recipeNameSuffix
				end,
				set = function(_, value)
					Skillet.db.profile.plugins.recipeNameSuffix = value
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
		if module and type(module) == "table" then
			if module.RecipeNamePrefix then
				Skillet.RecipeNamePrefixes[moduleName] = module
				Skillet.registeredPlugins[moduleName] = module
				Skillet.pluginsOptions.args.RecipeNamePrefix.values[module.options.name] = module.options.name
			end
			if module.RecipeNameSuffix then
				Skillet.RecipeNameSuffixes[moduleName] = module
				Skillet.registeredPlugins[moduleName] = module
				Skillet.pluginsOptions.args.RecipeNameSuffix.values[module.options.name] = module.options.name
			end
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
			Skillet.registeredPlugins[moduleName] = module
		end
	end
end

function Skillet:IsDisplayDetailPluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return Skillet.displayDetailPlugins[moduleName] ~= nil
	end
end

function Skillet:RegisterUpdatePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterUpdatePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = Skillet[moduleName]
		if module and type(module) == "table" and module.Update then
			Skillet.updatePlugins[moduleName] = module
			Skillet.registeredPlugins[moduleName] = module
		end
	end
end

function Skillet:IsUpdatePluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return Skillet.updatePlugins[moduleName] ~= nil
	end
end

function Skillet:UpdatePlugins()
	for k,v in pairs(Skillet.updatePlugins) do
		v.Update()
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
	return output_label, output_text
end

function Skillet:RecipeNamePrefix(skill, recipe)
	local text
	local recipeNamePrefix = self.db.profile.plugins.recipeNamePrefix
	if recipeNamePrefix and recipeNamePrefix ~= " " then
		for k,v in pairs(Skillet.RecipeNamePrefixes) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNamePrefix and v.options.name == recipeNamePrefix then
				text = v.RecipeNamePrefix(skill, recipe)
				--DA.DEBUG(1,"text= "..tostring(text))
				break
			end
		end
	end
	return text
end

function Skillet:RecipeNameSuffix(skill, recipe)
	local text
	local recipeNameSuffix = self.db.profile.plugins.recipeNameSuffix
	if recipeNameSuffix and recipeNameSuffix ~= " " then
		for k,v in pairs(Skillet.RecipeNameSuffixes) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNameSuffix and v.options.name == recipeNameSuffix then
				text = v.RecipeNameSuffix(skill, recipe)
				--DA.DEBUG(1,"text= "..tostring(text))
				break
			end
		end
	end
	return text
end

function Skillet:InitializePlugins()
	DA.DEBUG(0,"InitializePlugins()")
	for k,v in pairs(Skillet.registeredPlugins) do
		--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
		if v and v.OnInitialize then
			v.OnInitialize()
		end
	end
end

function Skillet:EnablePlugins()
	DA.DEBUG(0,"EnablePlugins()")
	for k,v in pairs(Skillet.registeredPlugins) do
		DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
		if v and v.OnEnable then
			v.OnEnable()
		end
	end
end
