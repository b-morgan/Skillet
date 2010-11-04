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

-- German localizations provided by Farook (from wowinterface.com) and Stan (from wowace)

-- If you are doing localization and would like your name added here, please feel free
-- to do so, or let me know and I will be happy to add you to the credits
--[[ 
2009-10-14, RaverJK:
I did a complete review and proof reading  of the German translation. I changed a lot.
Many terms have been shortened to have the lables more intuitive and the descriptions 
more... erm..  descriptive. 
]]--

local L = AceLibrary("AceLocale-2.2"):new("Skillet")
L:RegisterTranslations("deDE", function() return {
    ["Skillet Trade Skills"]                = "Skillet Trade Skills",
    ["Sorting"] 				 			= "Sortierung",    
    ["Create"]                              = "Erstellen",
    ["Queue All"]                           = "Alle in Warteschlange",
    ["Create All"]                          = "Alle erstellen",
    ["Create"]                              = "Erstellen",
    ["Queue"]                               = "Warteschlange",
    ["Enchant"]                             = "Verzaubern",
    ["Rescan"]                              = "Erneut scannen",
    ["Number of items to queue/create"]     = "Anzahl der Gegenst\195\164nde in Warteschlange/zum Erstellen",
    ["buyable"]                             = "k\195\164uflich",
    ["reagents in inventory"]               = "Reagenzien im Inventar",
    ["bank"]                                = "Reagenzien in der Bank", -- "reagents in bank"
    ["alts"]                                = "Reagenzien auf Twinks", -- "reagents on alts"
    ["can be created from reagents in your inventory"]  = "herstellbar mit den Reagenzien in deinem Inventar",
    ["can be created from reagents in your inventory and bank"] = "herstellbar mit den Reagenzien in deinem Inventar und der Bank",
    ["can be created from reagents on all characters"] = "herstellbar mit den Reagenzien auf allen Charakteren",
    ["Scanning tradeskill"]                 = "Scanne Berufe",
    ["Scan completed"]                      = "Scan abgeschlossen",
    ["Filter"]                              = "Filter",
    ["Hide uncraftable"]                    = "Nur herstellbare",
    ["Hide trivial"]                        = "Graue verstecken",
    ["Options"]                             = "Optionen",
    ["Notes"]                               = "Notizen",
    ["Purchased"]                           = "Eingekauft",
    ["Total spent"]                         = "Ausgegeben total",
    ["This merchant sells reagents you need!"]      = "Dieser H\195\164ndler verkauft Reagenzien die du brauchst!",
    ["Buy Reagents"]                        = "Reagenzien kaufen",
    ["click here to add a note"]            = "Hier klicken um eine Notiz hinzuzuf\195\188gen",
    ["not yet cached"]                      = "noch nicht im Cache",

    -- Options
    ["About"]						= "Über Skillet",
    ["ABOUTDESC"]					= "Gibt Informationen über Skillet aus",
    ["Config"]						= "Konfiguraton",
    ["CONFIGDESC"]					= "Öffnet ein Konfigurationsfenster für Skillet",
    ["Shopping List"]					= "Einkaufsliste",
    ["SHOPPINGLISTDESC"]				= "Zeigt die Einkaufsliste",

    ["Features"]					= "Optionen",
    ["FEATURESDESC"]					= "Optionale Funktionen die ein- oder ausgeschaltet werden können.",
    ["VENDORBUYBUTTONNAME"]				= "Kaufen-Schaltfläche beim Händler",
    ["VENDORBUYBUTTONDESC"]				= "Hat ein Händler Reagenzien, die in der Einkaufsliste sind, wird eine Schaltfläche zum Kaufen der Reagenzien angezeigt.",
    ["VENDORAUTOBUYNAME"]				= "Reagenzien automatisch kaufen",
    ["VENDORAUTOBUYDESC"]				= "Hat ein Händler Reagenzien, die in der Einkaufsliste sind, werden diese automatisch gekauft.",
    ["SHOWITEMNOTESTOOLTIPNAME"]			= "Notizen im Tooltip",
    ["SHOWITEMNOTESTOOLTIPDESC"]			= "Zeigt die benutzerdefinierten Notizen für einen Gegenstand im Tooltip an.",
    ["SHOWDETAILEDRECIPETOOLTIPNAME"]			= "Detaillierter Tooltip für Rezepte",
    ["SHOWDETAILEDRECIPETOOLTIPDESC"]			= "Zeigt einen detaillierten Tooltip, wenn der Mauszeiger über ein Rezept auf der linken Seite gehalten wird.",
    ["LINKCRAFTABLEREAGENTSNAME"]			= "Reagenzien anklickbar",
    ["LINKCRAFTABLEREAGENTSDESC"]			= "Wenn ein Reagenz für das aktuelle Rezept hergestellt werden kann, führt ein Klick auf das Reagenz zu dessen Rezept.",
    ["QUEUECRAFTABLEREAGENTSNAME"]			= "Herstellbare Reagenzien zur Warteschlange",
    ["QUEUECRAFTABLEREAGENTSDESC"]			= "Wenn ein Reagenz für das aktuelle Rezept hergestellt werden kann aber nicht genug fertige davon da sind, wird das Reagenz zur Warteschlange hinzugefügt.",
    ["DISPLAYSHOPPINGLISTATBANKNAME"]			= "Einkaufsliste in der Bank",
    ["DISPLAYSHOPPINGLISTATBANKDESC"]			= "Zeigt eine Liste der in deinen Taschen fehlenden Ragenzien, die für die Herstellung der Gegenstände in der Warteschlange benötigt werden.",
    ["DISPLAYSGOPPINGLISTATAUCTIONNAME"]		= "Einkaufsliste im Auktionshaus",
    ["DISPLAYSGOPPINGLISTATAUCTIONDESC"]		= "Zeigt eine Liste der in deinen Taschen fehlenden Ragenzien, die für die Herstellung der Gegenstände in der Warteschlange benötigt werden.",

    ["Appearance"]					= "Aussehen",
    ["APPEARANCEDESC"]					= "Einstelungen die das Aussehen von Skillet ändern",
    ["DISPLAYREQUIREDLEVELNAME"]			= "Zeige benötigte Stufe",
    ["DISPLAYREQUIREDLEVELDESC"]			= "Wenn der hergestellte Gegenstand eine Charakter-Mindeststufe erfordert, wird die Stufe im Rezept angezeigt",
    ["Transparency"]					= "Transparenz",
    ["TRANSPARAENCYDESC"]				= "Transparenz des Skillet-Fensters",

    -- New in version 1.6
    ["Shopping List"]               = "Einkaufsliste",
    ["Retrieve"]                    = "Abfragen",
    ["Include alts"]                = "Twinks miteinbeziehen",

    -- New in vesrsion 1.9
    ["Start"]                       = "Start",
    ["Pause"]                       = "Pause",
    ["Clear"]                       = "Leeren",
    ["None"]                        = "Nichts",
    ["By Name"]                     = "Nach Name",
    ["By Difficulty"]               = "Nach Schwierigkeit",
    ["By Level"]                    = "Nach Stufe",
    ["Scale"]                       = "Skalierung",
    ["SCALEDESC"]                   = "Skalierung des Berufsfensters (Standard 1.0)",
    ["Could not find bag space for"] = "Kann keinen Taschenplatz finden für",
    ["SORTASC"]                     = "Sortiere aufsteigend",
    ["SORTDESC"]                    = "Sortiere absteigend",
    ["By Quality"]                  = "Nach Qualität",

    -- New in version 1.10
    ["Inventory"]                   = "Inventar",
    ["INVENTORYDESC"]               = "Inventar-Information",
    ["Supported Addons"]            = "Unterstützte Addons",
    ["Selected Addon"]              = "Gewähltes Addon",
    ["Library"]                     = "Bibliothek",
    ["SUPPORTEDADDONSDESC"]         = "Unterstützte Addons die Dazu benutzt werden könnten oder benutzt werden um das Inventar aufzuzeichnen.",
    -- ["SHOWBANKALTCOUNTSNAME"]       = "Include bank and alt character contents",
    -- ["SHOWBANKALTCOUNTSDESC"]       = "When calculating and displaying craftable itemn counts, include items from your bank and from your other characters",
    -- ["ENHANCHEDRECIPEDISPLAYNAME"]  = "Show recipe difficulty as text",
    -- ["ENHANCHEDRECIPEDISPLAYDESC"]  = "When enabled, recipe names will have one or more '+' characters appeneded to their name to inidcate the difficulty of the recipe.",
    -- ["SHOWCRAFTCOUNTSNAME"]         = "Show craftable counts",
    -- ["SHOWCRAFTCOUNTSDESC"]         = "Show the number of times you can craft a recipe, not the total number of items producable",

    -- New in version 1.11
    ["Crafted By"]                  = "Herstellbar von",

    -- New in 1.13
    ["SHOWCRAFTERSTOOLTIPNAME"]     = "Hersteller im Tooltip anzeigen",
    ["SHOWCRAFTERSTOOLTIPDESC"]     = "Zeigt im Tooltip eines Gegenstandes die Twinks an, die ihn herstellen können.",


    -- New in 1.4
    ["QUEUEGLYPHREAGENTSNAME"]			= "Queue reagents for Glyphs",
    ["QUEUEGLYPHREAGENTSDESC"]			= "If you can create a reagent needed for the current recipe, and don't have enough, then that reagent will be added to the queue. This option is separate for Glyphs only.",

    -- New in 2.00
    ["SHOWFULLTOOLTIPNAME"]     = "Use standard tooltips",
    ["SHOWFULLTOOLTIPDESC"]     = "Display all informations about an item to be crafted. If you turn it off you will only see compressed tooltip (hold Ctrl to show full tooltip)",

} end)
