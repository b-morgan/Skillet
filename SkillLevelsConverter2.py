#!/usr/bin/python3
#
# SkillLevelsConverter2.py
#
# This program takes up to three SkillLineAbility file name arguments on the command line which are
# .csv tables from https://wago.tools/db2/SkillLineAbility and https://wago.tools/db2/SpellName
#
# The output will be .lua tables containing the data for inclusion in 
# Skillet-Classic's SkillLevelData1.lua, SkillLevelData4.lua, or SkillLevelData5.lua
#
# Skillet (retail) will use SkillLevelData2.lua (which is empty in the Skillet-Classic release)
#
# There may be some post-processing needed for names that include the double quote character.
#

import sys
import os
import csv

#
# Open the .csv file and extract the necessary data
#
def spells_list_read(file_name):
	f = open(file_name)
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		if int(row['TrivialSkillLineRankLow']) + int(row['TrivialSkillLineRankHigh']) > 0:
			spell_id = int(row['Spell'])
			skill_line = int(row['SkillLine'])
			spell_to_skill_line[spell_id] = skill_line
			min_skill_line_rank[spell_id] = int(row['MinSkillLineRank'])
			trivial_skill_line_rank_low[spell_id] = int(row['TrivialSkillLineRankLow'])
			trivial_skill_line_rank_high[spell_id] = int(row['TrivialSkillLineRankHigh'])
	f.close()
	spellname_file = file_name.replace("SkillLineAbility", "SpellName")
	with open(spellname_file) as f:
		reader = csv.DictReader(f, delimiter=',')
		for row in reader:
			spell_to_name[int(row['ID'])] = row['Name_lang']
	f.close()
	return

#
# Generate a line of output 
#
def spells_list_str(item_id):
	result = "[" + str(item_id) + "] = '"
	result = result + str(min_skill_line_rank[item_id]) + "/"
	result = result + str(trivial_skill_line_rank_low[item_id]) + "/"
	result = result + str(int((trivial_skill_line_rank_low[item_id]+trivial_skill_line_rank_high[item_id])/2)) + "/"
	result = result + str(trivial_skill_line_rank_high[item_id])
	if item_id in spell_to_name:
		result = result + "',    -- "
		result = result + str(spell_to_name[item_id])
		result = result + "\n"
	else:
		result = result + "',\n"
	return result

#
# Open the .lua file (overwrite existing) and output the data
#
def spells_list_write(file_name):
	output_file = os.path.splitext(file_name)[0] + '.lua'
	dirname, basename = os.path.split(output_file)
	filename, ext = basename.split('.', 1)
	o = open(output_file, "w")
	o.write("-- " + output_file + "\n")
	o.write("Skillet.db.global.SkillLineAbility = {\n")
	spell_name_output = output_file.replace("SkillLineAbility", "SpellName")
	n = open(spell_name_output, "w")
	n.write("-- " + spell_name_output + "\n")
	n.write("Skillet.db.global.NameToSpellID = {\n")
	for item_id in spell_to_skill_line:
		o.write(spells_list_str(item_id))
		if item_id in spell_to_name:
			name = spell_to_name[item_id].replace('"','\\"')
			result = '["' + name + '"] = '
			result = result + str(item_id)
			result = result + ",\n"
			n.write(result)
	o.write("}\n")
	o.close()
	n.write("}\n")
	n.close()

#
# Initialize the data storage
#
if len(sys.argv) < 2:
	print("Usage:")
	exit()

if len(sys.argv) >= 2:
	spell_to_skill_line = {}
	min_skill_line_rank = {}
	trivial_skill_line_rank_low = {}
	trivial_skill_line_rank_high = {}
	spell_to_name = {}
#
# Read the data from the .csv file
#
	spells_list_read(sys.argv[1])
	print(str(len(spell_to_skill_line))+" records processed in "+sys.argv[1])
#
# Change the input file name extension and write the data
#
	spells_list_write(sys.argv[1])

#
# Initialize the data storage again and repeat the process
#
if len(sys.argv) >= 3:
	spell_to_skill_line = {}
	min_skill_line_rank = {}
	trivial_skill_line_rank_low = {}
	trivial_skill_line_rank_high = {}
	spell_to_name = {}

	spells_list_read(sys.argv[2])
	print(str(len(spell_to_skill_line))+" records processed in "+sys.argv[2])
	spells_list_write(sys.argv[2])

if len(sys.argv) >= 4:
	spell_to_skill_line = {}
	min_skill_line_rank = {}
	trivial_skill_line_rank_low = {}
	trivial_skill_line_rank_high = {}
	spell_to_name = {}

	spells_list_read(sys.argv[3])
	print(str(len(spell_to_skill_line))+" records processed in "+sys.argv[3])
	spells_list_write(sys.argv[3])
	
