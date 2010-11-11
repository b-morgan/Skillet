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


Skillet.ARLPlugin = {}

local plugin = Skillet.ARLPlugin

function plugin.GetExtraText(skill, recipe)
	local extra_text, label
	local bop

	if AckisRecipeList and AckisRecipeList.InitRecipeData then
		local _, recipeList, mobList, trainerList = AckisRecipeList:InitRecipeData()

		local recipeData = AckisRecipeList:GetRecipeData(skill.id)

		if recipeData == nil and not ARLProfessionInitialized[recipe.tradeID] then
			ARLProfessionInitialized[recipe.tradeID] = true

			local profession = GetSpellInfo(recipe.tradeID)

			AckisRecipeList:AddRecipeData(profession)

			recipeData = AckisRecipeList:GetRecipeData(skill.id)
		end


		if recipeData then
			extra_text = AckisRecipeList:GetRecipeLocations(skill.id)

--DEFAULT_CHAT_FRAME:AddMessage("ARL Data "..(extra_text or "nil"))

			if extra_text == "" then extra_text = nil end
		end
	end
	label = "Source:"
	return label, extra_text
end

--Skillet:RegisterDisplayDetailPlugin("ARLPlugin")
