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


Skillet.displayDetailPlugins = {}

function Skillet:RegisterDisplayDetailPlugin(moduleName, priority)
	if not priority then priority = 100 end
	
	if type(moduleName)	 == "string" then
		module = Skillet[moduleName]
		if module and type(module) == "table" and module.GetExtraText then
			Skillet.displayDetailPlugins[moduleName]=module
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
	return output_label, output_text
end

function Skillet:InitializePlugins()
	for k,v in pairs(Skillet.displayDetailPlugins) do
		if v and v.OnInitialize then
			v.OnInitialize()
		end
	end
end
