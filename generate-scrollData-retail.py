#!/usr/bin/python3
# Inspired by:
# https://github.com/Auctionator/Auctionator/blob/master/DB2_Scripts/convert-enchant-spell-to-enchant-mainline.py
#
# This script converts the csv output from: 
# https://wago.tools/db2/Item 
# https://wago.tools/db2/ItemEffect (Classic, row['ParentItemID'])
# https://wago.tools/db2/ItemXItemEffect (Retail only)
# https://wago.tools/db2/SpellName
#
# to get a mapping of the enchant spell id to the enchant item 
# (for searching the AH for the enchant or
# calculation crafting profit), and spell level/equipped slot (for the vellum
# needed for crafting cost/profit)
#
# One command line argument of the form "5.5.0.62258" is added to the .csv file name(s)
#
import csv
import sys
import os

#
# Initialize the data storage
#
if len(sys.argv) < 2:
	print("Usage:")
	exit()
else:
	build = sys.argv[1]

enchants_only = {}
with open('Item.'+build+'.csv', newline='') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		if row['ClassID'] == '8': # Item Enhancement
			itemID = int(row['ID'])
			enchants_only[itemID] = []

with open('ItemXItemEffect.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		itemid = int(row['ItemID'])
		if itemid in enchants_only:
			enchants_only[itemid].append(int(row['ItemEffectID']))

effects_to_spell = {}
with open('ItemEffect.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		effects_to_spell[int(row['ID'])] = int(row['SpellID'])

enchants_to_items = {}
for itemID in enchants_only:
	item_effects = enchants_only[itemID]
	if len(item_effects) == 1:
		spellID = effects_to_spell[item_effects[0]]
		if spellID not in enchants_to_items:
			enchants_to_items[spellID] = [itemID]
		else:
			enchants_to_items[spellID].append(itemID)

spell_to_name = {}
with open('SpellName.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_name[int(row['ID'])] = row['Name_lang']

data_format = """\
	[{}] = {}, -- {} {}\
"""

o = open('scrollData.'+build+'.lua', "w")
o.write("-- " + build + "\n")
o.write("Skillet.scrollData = {\n")
for spell_id in enchants_to_items:
	item_id = enchants_to_items[spell_id]
	if spell_id in spell_to_name:
		spell_name = spell_to_name[spell_id]
#
#	Retail Enchants can create multiple scrolls (different iLvls)
#	For now, put the lowest id in the table and
#	the complete list in the comment.
#
	if len(item_id) > 1:
		item_id.sort()
		o.write(data_format.format(spell_id, item_id[0], spell_name, item_id) + "\n")
	else:
		o.write(data_format.format(spell_id, item_id[0], spell_name, "") + "\n")
o.write("}\n")
o.close()
