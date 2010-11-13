

Skillet.selectedQueueName = ""

function Skillet:QueueLoadDropdown_OnShow()
    UIDropDownMenu_Initialize(SkilletQueueLoadDropdown, Skillet.SkilletQueueLoadDropdown_Initialize)
    SkilletSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square

	UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, 1)

	local i=2
	for k,v in pairs(Skillet.db.profile.SavedQueues) do
		if Skillet.selectedQueueName and Skillet.selectedQueueName == k then
			UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, i)
		end
		i = i + 1
	end
end


function Skillet:SkilletQueueLoadDropdown_Initialize()
    local info
	local i=1

	info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.func = Skillet.QueueLoadDropdown_OnClick
	info.value = i
	i = i + 1
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)

	for k,v in pairs(Skillet.db.profile.SavedQueues) do
		info = UIDropDownMenu_CreateInfo()
		info.text = k
		info.func = Skillet.QueueLoadDropdown_OnClick
		info.value = i
		i = i + 1

		if self then
			info.owner = self:GetParent()
		end

		UIDropDownMenu_AddButton(info)
	end
end


-- Called when the user selects an item in the sorting drop down
function Skillet:QueueLoadDropdown_OnClick()
    UIDropDownMenu_SetSelectedID(SkilletQueueLoadDropdown, self:GetID())
    Skillet.selectedQueueName = self:GetText()
end
