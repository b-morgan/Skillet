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

local MAJOR_VERSION = "1.12"
local MINOR_VERSION = ("$Revision$"):match("%d+") or 1
local DATE = string.gsub("$Date$", "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

Skillet = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "AceHook-2.1")
Skillet.title   = "Skillet"
Skillet.version = MAJOR_VERSION .. "-" .. MINOR_VERSION
Skillet.date    = DATE

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet

-- Is a copy of LibPossessions is avaialable, use it for alt
-- character inventory checks
Skillet.inventoryCheck = LibStub and LibStub:GetLibrary('LibPossessions')

-- Register to have the AceDB class handle data and option persistence for us
Skillet:RegisterDB("SkilletDB", "SkilletDBPC")

-- Global ( across all alts ) options
Skillet:RegisterDefaults('profile', {
    -- user configurable options
    vendor_buy_button = true,
    vendor_auto_buy   = false,
    show_item_notes_tooltip = false,
    show_detailed_recipe_tooltip = true,
    link_craftable_reagents = true,
    queue_craftable_reagents = true,
    display_required_level = false,
    display_shopping_list_at_bank = false,
    display_shopping_list_at_auction = false,
    transparency = 1.0,
    scale = 1.0,
} )

-- Options specific to a single character
Skillet:RegisterDefaults('server', {
    -- we tell Stitch to keep the "recipes" table up to data for us.
    recipes = {},

    -- and any queued up recipes
    queues = {},

    -- notes added to items crafted or used in crafting.
    notes = {},
} )

-- Options specific to a single character
Skillet:RegisterDefaults('char', {
    -- options specific to a current tradeskill
    tradeskill_options = {},

    -- Display alt's items in shopping list
    include_alts = true,
} )

-- Localization
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Events
local AceEvent = AceLibrary("AceEvent-2.0")

-- All the options that we allow the user to control.
local Skillet = Skillet
Skillet.options =
{
    handler = Skillet,
    type = 'group',
    args = {
        features = {
            type = 'group',
            name = L["Features"],
            desc = L["FEATURESDESC"],
            order = 11,
            args = {
                vendor_buy_button = {
                    type = "toggle",
                    name = L["VENDORBUYBUTTONNAME"],
                    desc = L["VENDORBUYBUTTONDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_buy_button;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_buy_button = value;
                    end,
                    order = 12
                },
                vendor_auto_buy = {
                    type = "toggle",
                    name = L["VENDORAUTOBUYNAME"],
                    desc = L["VENDORAUTOBUYDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_auto_buy;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_auto_buy = value;
                    end,
                    order = 12
                },
                show_item_notes_tooltip = {
                    type = "toggle",
                    name = L["SHOWITEMNOTESTOOLTIPNAME"],
                    desc = L["SHOWITEMNOTESTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_item_notes_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_item_notes_tooltip = value;
                    end,
                    order = 13
                },
                show_detailed_recipe_tooltip = {
                    type = "toggle",
                    name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
                    desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_detailed_recipe_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_detailed_recipe_tooltip = value;
                    end,
                    order = 14
                },
                link_craftable_reagents = {
                    type = "toggle",
                    name = L["LINKCRAFTABLEREAGENTSNAME"],
                    desc = L["LINKCRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.link_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.link_craftable_reagents = value;
                    end,
                    order = 14
                },
                queue_craftable_reagents = {
                    type = "toggle",
                    name = L["QUEUECRAFTABLEREAGENTSNAME"],
                    desc = L["QUEUECRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.queue_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.queue_craftable_reagents = value;
                    end,
                    order = 15
                },
                display_shopping_list_at_bank = {
                    type = "toggle",
                    name = L["DISPLAYSHOPPINGLISTATBANKNAME"],
                    desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_bank;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_bank = value;
                    end,
                    order = 16
                },
                display_shopping_list_at_auction = {
                    type = "toggle",
                    name = L["DISPLAYSGOPPINGLISTATAUCTIONNAME"],
                    desc = L["DISPLAYSGOPPINGLISTATAUCTIONDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_auction;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_auction = value;
                    end,
                    order = 17
                },
                show_craft_counts = {
                    type = "toggle",
                    name = L["SHOWCRAFTCOUNTSNAME"],
                    desc = L["SHOWCRAFTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_craft_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_craft_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 18,
                },
            }
        },
        appearance = {
            type = 'group',
            name = L["Appearance"],
            desc = L["APPEARANCEDESC"],
            order = 12,
            args = {
                display_required_level = {
                    type = "toggle",
                    name = L["DISPLAYREQUIREDLEVELNAME"],
                    desc = L["DISPLAYREQUIREDLEVELDESC"],
                    get = function()
                        return Skillet.db.profile.display_required_level
                    end,
                    set = function(value)
                        Skillet.db.profile.display_required_level = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 1
                },
                transparency = {
                    type = "range",
                    name = L["Transparency"],
                    desc = L["TRANSPARAENCYDESC"],
                    min = 0.1, max = 1, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.transparency
                    end,
                    set = function(t)
                        Skillet.db.profile.transparency = t
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    desc = L["SCALEDESC"],
                    min = 0.1, max = 1.25, step = 0.05, isPercent = true,
                    get = function()
                        return Skillet.db.profile.scale
                    end,
                    set = function(t)
                        Skillet.db.profile.scale = t
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 3,
                },
                enhanced_recipe_display = {
                    type = "toggle",
                    name = L["ENHANCHEDRECIPEDISPLAYNAME"],
                    desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
                    get = function()
                        return Skillet.db.profile.enhanced_recipe_display
                    end,
                    set = function(value)
                        Skillet.db.profile.enhanced_recipe_display = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
            },
        },
        inventory = {
            type = "group",
            name = L["Inventory"],
            desc = L["INVENTORYDESC"],
            order = 13,
            args = {
                addons = {
                    type = 'execute',
                    name = L["Supported Addons"],
                    desc = L["SUPPORTEDADDONSDESC"],
                    func = function()
                        Skillet:ShowInventoryInfoPopup()
                    end,
                    order = 1,
                },
                show_bank_alt_counts = {
                    type = "toggle",
                    name = L["SHOWBANKALTCOUNTSNAME"],
                    desc = L["SHOWBANKALTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_bank_alt_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_bank_alt_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
            },
        },

        about = {
            type = 'execute',
            name = L["About"],
            desc = L["ABOUTDESC"],
            func = function()
                Skillet:PrintAddonInfo()
            end,
            order = 50
        },
        config = {
            type = 'execute',
            name = L["Config"],
            desc = L["CONFIGDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    AceLibrary("Waterfall-1.0"):Open("Skillet")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            guiHidden = true,
            order = 51
        },
        shoppinglist = {
            type = 'execute',
            name = L["Shopping List"],
            desc = L["SHOPPINGLISTDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    Skillet:DisplayShoppingList(false)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                                                  " Leave combat and try again.")
                end
            end,
            order = 52
        },
    }
}

-- Called when the addon is loaded
function Skillet:OnInitialize()

    -- hook default tooltips
    local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
    for _, tooltip in pairs(tooltipsToHook) do
        if tooltip and tooltip:HasScript("OnTooltipSetItem") then
            if tooltip:GetScript("OnTooltipSetItem") then
                local oldOnTooltipSetItem = tooltip:GetScript("OnTooltipSetItem")
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    oldOnTooltipSetItem(tooltip)
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            else
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            end
        end
    end

    -- no need to be spammy about the fact that we are here, they'll find out seen enough
    -- self:Print("Skillet v" .. self.version .. " loaded");

    -- Track trade skill creation
    self.stitch = AceLibrary("SkilletStitch-1.1")

    -- Make sure this is done in initialize, not enable as we want the chat
    -- commands to be available even when the mod is disabled. Otherwise,
    -- how would the mod be enabled again?
    self:RegisterChatCommand({"/skillet"}, self.options, "SKILLET")

end

-- Returns the number of items across all characters, including the
-- current one.
local function alt_item_lookup(link)
    local item = Skillet:GetItemIDFromLink(link)
    return Skillet.inventoryCheck:GetItemCount(item)
end

-- Called when the addon is enabled
function Skillet:OnEnable()

    -- Hook into the events that we care about

    -- Trade skill window changes
    self:RegisterEvent("TRADE_SKILL_CLOSE")
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("TRADE_SKILL_UPDATE")

    -- Learning or unlearning a tradeskill
    self:RegisterEvent('SKILL_LINES_CHANGED')

    -- Tracks when the bumber of items on hand changes
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("TRADE_CLOSED")

    -- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_UPDATE")
    self:RegisterEvent("MERCHANT_CLOSED")

    -- May need to show a shopping list when at the bank/auction house
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")

    -- Messages from the Stitch libary
    -- These need to update the tradeskill window, not just the queue
    -- as we need to redisplay the number of items that can be crafted
    -- as we consume reagents.
    self:RegisterEvent("SkilletStitch_Queue_Continue", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Complete", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Add",      "QueueChanged")

    self:RegisterEvent("SkilletStitch_Scan_Complete",  "ScanCompleted")

    -- These we have to handle ourselves becuase we do crafts directly,
    -- rather than through the Stitch libary.
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",   "CraftCastEnded")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED",      "CraftCastEnded")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "CraftCastEnded")

    self.hideUncraftableRecipes = false
    self.hideTrivialRecipes = false
    self.currentTrade = nil
    self.selectedSkill = nil

    -- run the upgrade code to convert any old settings
    self:UpgradeDataAndOptions()

    if self.stitch.SetAltCharacterItemLookupFunction and self.inventoryCheck and self.inventoryCheck:IsAvailable() then
        -- Older version of the Stitch-1.1 library may not have this
        -- routine. If they don't then we just don't included item
        -- counts from alt characters.
        self.stitch:SetAltCharacterItemLookupFunction(alt_item_lookup)
    end

    -- hook up our copy of stitch to the data for this character
    if self.db.server.recipes[UnitName("player")] then
        self.stitch.data = self.db.server.recipes[UnitName("player")]
    end
    self.db.server.recipes[UnitName("player")] = self.stitch.data

    self.stitch:EnableDataGathering("Skillet")
    self.stitch:EnableQueue("Skillet")

    AceLibrary("Waterfall-1.0"):Register("Skillet",
                   "aceOptions", Skillet.options,
                   "title",      L["Skillet Trade Skills"],
                   "colorR",     0,
                   "colorG",     0.7,
                   "colorB",     0
                   )
    AceLibrary("Waterfall-1.0"):Open("Skillet")

end

-- Called when the addon is disabled
function Skillet:OnDisable()
    self.stitch:DisableDataGathering("Skillet")
    self.stitch:DisableQueue("Skillet");

    self:UnregisterAllEvents()

    AceLibrary("Waterfall-1.0"):Close("Skillet")
    AceLibrary("Waterfall-1.0"):UnRegister("Skillet")
end

local function is_known_trade_skill(name)
    -- Check to see if we actually know this skill or if the user is
    -- opening a tradeskill that was linked to them. We can't just check 
    -- the cached list of skills as this might also be a tradeskill that
    -- the user has just learned.
    local numSkills = GetNumSkillLines()
    for skillIndex=1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil and skillName == name then
            return true
        end
    end

    -- must not be a trade skill we know about.
    return false
end

-- Checks to see if the current trade is one that we support. 
local function is_supported_trade(parent)
    local name = parent:GetTradeSkillLine()

    -- EnchantingSell does not play well with the Skillet window, so
    -- if it is enabled, and it was the craft frame hidden, do not
    -- show Skillet for enchanting.
    --
    -- EnchantingSell does some odd things to the enchanting toggle,
    -- so expect some odd bug reports about this.
    if ESeller and ESeller:IsActive() and ESeller.db.char.DisableDefaultCraftFrame then
         return false
    end

    return is_known_trade_skill(name) and not IsTradeSkillLinked()

end

local scan_in_progress = false
local need_rescan_on_open = false
local forced_rescan = false

function Skillet:ScanCompleted()
    if scan_in_progress then
        if forced_rescan and not need_rescan_on_open then
            -- only print this if we are not not doing a bag rescan,
            -- i.e. a first time or forced rescan.
            local name = self:GetTradeSkillLine()
            self:Print(L["Scan completed"] .. ": " .. name);
        end

        self:UpdateScanningText("")
        scan_in_progress = false
        need_rescan_on_open = false
        forced_rescan = false
        self:UpdateTradeSkillWindow()
    end
end

-- Checks to see if the list of recipes has been cached
-- before and if not, scans them. This only works on the
-- currently selected tradeskill
local function cache_recipes_if_needed(self, force)
    if scan_in_progress then
        return true
    end

    local trade = self:GetTradeSkillLine()

    if not trade or trade == "UNKNOWN" then
        return
    end

    local count = self:GetNumTradeSkills(trade)
    if count <= 0 and not force then
        -- no recipes == no scan
        return false
    end

    local recipes_known = (self.stitch:GetItemDataByIndex(trade, count) ~= nil)

    if force or not recipes_known then
        forced_rescan = true
        self:RescanTrade(true)
        return true
    end

    return false
end

local function Skillet_rescan_skills()
    local numSkills = GetNumSkillLines()
    local skills = {}
    for skillIndex=1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil then
            skills[skillName] = skillName
        end
    end

    local player = UnitName("player")

    local changed = false
    for profession, _ in pairs(Skillet.db.server.recipes[player]) do
        if not skills[profession] then
            changed = true
            if profession ~= "UNKNOWN" then
                -- where the hell does this come from?
                Skillet:Print("No longer know: " .. profession)
            end
            Skillet.db.server.recipes[player][profession] = nil
        end
    end

    if changed == true then
        Skillet:HideAllWindows()
        if Skillet.db.server.recipes[player] then
            Skillet.stitch.data = Skillet.db.server.recipes[player]
        end
        Skillet.db.server.recipes[player] = Skillet.stitch.data
        Skillet:internal_ResetCharacterCache()
    end
end

-- Called when the list of trade skills know by the player has changed
function Skillet:SKILL_LINES_CHANGED()
    if not AceEvent:IsEventScheduled("Skillet_rescan_skills") and not IsTradeSkillLinked() then
        AceEvent:ScheduleEvent("Skillet_rescan_skills", Skillet_rescan_skills, 10.0)
    end
end

-- Called when the trade skill window is opened
-- or when the window is open and the user selects another tradeskill
function Skillet:TRADE_SKILL_SHOW()
    if is_supported_trade(self) then
        self:UpdateTradeSkill()
        self:ShowTradeSkillWindow()
        self.stitch:TRADE_SKILL_SHOW()
    else
        self:HideAllWindows()
    end
end

function Skillet:TRADE_SKILL_UPDATE()
    if IsTradeSkillLinked() then
        return
    end
    self:UpdateTradeSkill()
    if not AceEvent:IsEventScheduled("Skillet_redo_the_update") then
        self:ResetTradeSkillWindow()
        self:UpdateTradeSkillWindow()
    end
end

-- Called when the trade skill window is closed
function Skillet:TRADE_SKILL_CLOSE()
    show_after_scan = false
    self:HideAllWindows()
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill
-- window is open and a trade selected.
local function Skillet_rescan_bags()
    cache_recipes_if_needed(Skillet, false)
    Skillet:UpdateTradeSkillWindow()
    Skillet:UpdateShoppingListWindow()
end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE()
    local showing = false
    if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
        showing = true
    end
    if self.shoppingList and self.shoppingList:IsVisible() then
        showing = true
    end

    if showing then
        -- bag updates can happen fairly frequently and we don't want to
        -- be scanning all the time so ... buffer updates to a single event
        -- that fires after a 1/4 second.
        if not AceEvent:IsEventScheduled("Skillet_rescan_bags") then
            AceEvent:ScheduleEvent("Skillet_rescan_bags", Skillet_rescan_bags, 0.25)
        end
    else
       -- no trade window open, but something change, we will need to rescan
       -- when the window is next opened.
       need_rescan_on_open = true
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        -- may need to update the button on the merchant frame window ...
        self:UpdateMerchantFrame()
    end
end

-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
function Skillet:TRADE_CLOSED()
    self:BAG_UPDATE()
end

-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
    local trade_changed = false
    local new_trade = self:GetTradeSkillLine()

    if not self.currentTrade and new_trade then
        trade_changed = true
    elseif self.currentTrade ~= new_trade then
        trade_changed = true
    end

    if trade_changed then
        self:HideNotesWindow();

        -- remove any filters currently in place
        local filterbox = getglobal("SkilletFilterBox");
        local filtertext = self:GetTradeSkillOption(new_trade, "filtertext") or ""
        filterbox:SetText(filtertext);

        -- And start the update sequence through the rest of the mod
        self:SetSelectedTrade(new_trade)

        cache_recipes_if_needed(self, need_rescan_on_open)

        -- Load up any saved queued items for this profession
        self:LoadQueue(self.db.server.queues, new_trade)

    end
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
    local frame = self.tradeSkillFrame
    if not frame then
        frame = self:CreateTradeSkillWindow()
        self:UpdateTradeSkillWindow()
        self.tradeSkillFrame = frame
    end

    self:ResetTradeSkillWindow()

    if not frame:IsVisible() then
        ShowUIPanel(frame)
    end
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:internal_HideTradeSkillWindow()

    local closed -- was anything closed by us?
    local frame = self.tradeSkillFrame

    if frame and frame:IsVisible() then
        self.stitch:StopCast()
        HideUIPanel(frame)
        closed = true
    end

    return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:internal_HideAllWindows()
    local closed -- was anything closed?

    -- Cancel anything currently being created
    self.stitch:CancelCast()

    if self:HideTradeSkillWindow() then
        closed = true
    end

    if self:HideNotesWindow() then
        closed = true
    end

    if self:HideShoppingList() then
        closed = true
    end

    self.currentTrade = nil
    self.selectedSkill = nil

    return closed
end

-- Show the options window
function Skillet:ShowOptions()
    AceLibrary("Waterfall-1.0"):Open("Skillet");
end

-- Triggers a rescan of the currently selected tradeskill
function Skillet:RescanTrade(forced)
    scan_in_progress = true
    local trade = self:GetTradeSkillLine()
    if trade and trade ~= "UNKNOWN" and is_known_trade_skill(trade) and not IsTradeSkillLinked() then
        if forced then
            forced_rescan = true
        end

        if forced_rescan and not need_rescan_on_open then
            -- only print this for first time and forced rescans
            -- not when a bag is changed
            self:Print(L["Scanning tradeskill"] .. ": " .. trade);
        end

        self:UpdateScanningText(L["Scanning tradeskill"] .. " ...")

        Skillet.stitch:ScanTrade()
    else
        scan_in_progress = false
    end
end

-- Notes when a new trade has been selected
function Skillet:SetSelectedTrade(new_trade)
    self.currentTrade = new_trade;
    self:SetSelectedSkill(nil, false);
    self.headerCollapsedState = {};

    self:UpdateTradeSkillWindow()

    -- Stop the stitch queue and nuke anything in it.
    -- would be nice to allow queuing items from different
    -- trades, but the Blizzard design does not allow that
    self.stitch:CancelCast();
    self.stitch:StopCast();
    self.stitch:ClearQueue();
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skill_index, was_clicked)
    if not skill_index then
        -- no skill selected
        self:HideNotesWindow()
    elseif self.selectedSkill and self.selectedSkill ~= skill_index then
        -- new skill selected
        self:HideNotesWindow() -- XXX: should this be an update?
    end

    self.selectedSkill = skill_index
    self:UpdateDetailsWindow(skill_index)
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
    self:SetTradeSkillOption(self.currentTrade, "filtertext", text)
    self:UpdateTradeSkillWindow()
end

-- Called when the queue has changed in some way
function Skillet:QueueChanged()
    -- Hey! What's all this then? Well, we may get the request to update the
    -- windows while the queue is being processed and the reagent and item
    -- counts may not have been updated yet. So, the "0.5" puts in a 1/2
    -- second delay before the real update window method is called. That
    -- give the rest of the UI (and the API methods called by Stitch) time
    -- to record any used reagents.
    if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateWindows") then
            AceEvent:ScheduleEvent("Skillet_UpdateWindows", Skillet.UpdateTradeSkillWindow, 0.5, self)
        end
    end

    if SkilletShoppingList and SkilletShoppingList:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateShoppingList") then
            AceEvent:ScheduleEvent("Skillet_UpdateShoppingList", Skillet.UpdateShoppingListWindow, 0.25, self)
        end
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateMerchantFrame") then
            AceEvent:ScheduleEvent("Skillet_UpdateMerchantFrame", Skillet.UpdateMerchantFrame, 0.25, self)
        end
    end
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(link)
    local result

    if not self.db.server.notes[UnitName("player")] then
        return
    end

    local id = self:GetItemIDFromLink(link)
    if id and self.db.server.notes[UnitName("player")] then
        result = self.db.server.notes[UnitName("player")][id]
    else
        self:Print("Error: Skillet:GetItemNote() could not determine item ID for " .. link);
    end

    if result and result == "" then
        result = nil
        self.db.server.notes[UnitName("player")][id] = nil
    end

    return result
end

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(link, note)
    local id = self:GetItemIDFromLink(link);

    if not self.db.server.notes[UnitName("player")] then
        self.db.server.notes[UnitName("player")] = {}
    end

    if id then
        self.db.server.notes[UnitName("player")][id] = note
    else
        self:Print("Error: Skillet:SetItemNote() could not determine item ID for " .. link);
    end

end

-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
function Skillet:AddItemNotesToTooltip(tooltip)
    local enabled = self.db.profile.show_item_notes_tooltip or false
    if enabled == false or IsControlKeyDown() then
        return
    end

    -- get item name
    local name,link = tooltip:GetItem();
    if not link then return; end

    local id = self:GetItemIDFromLink(link);
    if not id then return end;

    local header_added = false
    for player,notes_table in pairs(self.db.server.notes) do
        local note = notes_table[id]
        if note then
            if not header_added then
                tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
                header_added = true
            end
            if player ~= UnitName("player") then
                note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
            end
            tooltip:AddLine(" " .. note, 1, 1, 1, 1) -- r,g,b, wrap
        end
    end

    local crafters = self:GetCraftersForItem(id);
    if crafters then
        header_added = true
        local title_added = false

        for i,name in ipairs(crafters) do
            if not title_added then
                title_added = true
                tooltip:AddDoubleLine(L["Crafted By"], name)
            else
                tooltip:AddDoubleLine(" ", name)
            end
        end

    end

    return header_added
end

-- Returns the state of a craft specific option
function Skillet:GetTradeSkillOption(trade, option)
    local options = self.db.char.tradeskill_options;

    if not options or not options[trade] then
        return false
    end

    return options[trade][option]
end

-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(trade, option, value)
    local options = self.db.char.tradeskill_options;

    if not options[trade] then
        options[trade] = {}
    end

    options[trade][option] = value
end
