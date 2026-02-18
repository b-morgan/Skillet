local addonName,addonTable = ...
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end
local tek = tekDebug and tekDebug:GetFrame("Skillet")
--
-- Chat and Debugging Aids
--
-- Add the first two lines of this file to all
-- the files in your addon (that use these functions).
-- Add this file (DebugAids.lua) to the .toc for
-- your addon. The functions and variables in this 
-- file are added to the global table of the addon.
--
-- Note:
--		For addons using ACE, the file with the 
--		"LibStub("AceAddon-3.0"):NewAddon(...)" may need
--		to add a "local DA = <>" after the LibStub with
--		"<>" changed to the name of the addon. 
--
-- Incorporate the commented out code at the bottom
-- of this file (or the equivalent) into your addon 
-- for run time control of these debugging functions.
--
-- DA.DebugLog is a circular table which has DA.MAXDEBUG entries.
--
-- Setting DA.WarnLog, DA.DebugLogging, or DA.TraceLog
-- will add the respective text to the circular table
-- without printing to the default chat frame. 
-- 
-- Setting DA.WarnShow or DA.TraceShow will cause 
-- DA.WARN or DA.TRACE to print their argument(s)
-- to the default chat frame.
-- 
-- Setting DA.DebugShow will cause DA.DEBUG to print 
-- its argument(s) to the default chat frame if 
-- its first argument, level, is less than DA.DebugLevel.
-- This level should be a number between 0 and 9. If it
-- is not a number between 0 and 9, it is assumed to
-- be the first argument to be printed.
--
-- DA.DebugLevel should constrained to be a 
-- number between 1 and 10.
--
-- DA.LogLevel is a boolean with false meaning log all
-- DA.DEBUG calls regardless of level and true meaning
-- only log calls when they are less than DA.DebugLevel
--
--
DA.WarnShow = false
DA.WarnLog = true
DA.DebugShow = false
DA.DebugLogging = true
DA.DebugLevel = 1
DA.TableDump = false
DA.TraceShow = false
DA.TraceLog = false
DA.TraceLog2 = false
DA.TraceLog3 = false
DA.ProfileShow = false
DA.DebugLog = {} -- Add to SavedVariables for debugging
DA.MAXDEBUG = 4000
DA.DebugProfile = {} -- Add to SavedVariables for debugging
DA.MAXPROFILE = 2000
DA.STATUS_COLOR = "|c0033CCFF"
DA.DEBUG_COLOR  = "|c00A0FF00"
DA.TRACE_COLOR  = "|c0000FFA0"
DA.WARN_COLOR   = "|c0000FFE0"

local function print(msg)
	(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME):AddMessage(msg)
end

local function tekD(text)
	print(text)
	if tek then 
		tek:AddMessage(text)
	end
end

function DA.CHAT(text)
	print(DA.STATUS_COLOR..addonName..": "..text)
end

--
-- If any logging is enabled, insert text into the debug log
--
function DA.MARK(text)
	if DA.WarnLog or DA.DebugLogging or DA.TraceLog then
		table.insert(DA.DebugLog,date().."(M): "..text)
		if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
			table.remove(DA.DebugLog,1)
		end
	end
end

--
-- Print and MARK the text
--
function DA.MARK2(text)
	print(text)
	DA.MARK(text)
end

--
-- CHAT and MARK the text
--
function DA.MARK3(text)
	DA.CHAT(text)
	DA.MARK(text)
end

function DA.WARN(...)
	if not DA.WarnLog and not DA.DebugLogging then return "" end
	local text = ""
	local comma = ""
	for i = 1, select("#", ...), 1 do
		if (i > 2) then 
			comma = ", "
		end
		local value = select(i,...)
		local vtype = type(value)
		if (vtype == "nil") then 
			text = text..comma.."(nil)"
		elseif (vtype == "number") then 
			text = text..comma..tostring(value)
		elseif (vtype == "string") then
			local t = string.sub(value,1,2)
			if t == ", " then
				text = text..value
			else
				text = text..comma..value
			end
		elseif (vtype == "boolean") then 
			if (value) then
				text = text..comma.."true" 
			else 
				text = text..comma.."false" 
			end
		elseif (vtype == "table" or vtype == "function" or vtype == "thread" or vtype == "userdata") then 
			text = text..comma.."("..vtype..")"
		else                               
			text = text..comma.."(unknown)"
		end
	end
	if (DA.WarnShow or DA.DebugShow) then
		tekD(DA.WARN_COLOR..addonName..": "..text)
	end
	table.insert(DA.DebugLog,date().."(W): "..text)
	if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
		table.remove(DA.DebugLog,1)
	end
end

function DA.DEBUG(...)
	if not DA.DebugLogging then return "" end
	local k = select("#",...)
	local level = select(1, ...)
	local text = ""
	local comma = ""
	local j = 2
	local t = type(level)
	if (t == "number" and level == -1) then
		return
	end
	if (t ~= "number" or level < 0 or level > 10) then
		level = 0  -- assume this is a deprecated call and
		j = 1      -- process it as the first parameter.
	end
	for i = j, k, 1 do
		if (i > 2) then 
			comma = ", "
		end
		local value = select(i,...)
		local vtype = type(value)
		if (vtype == "nil") then 
			text = text..comma.."(nil)"
		elseif (vtype == "number") then 
			text = text..comma..tostring(value)
		elseif (vtype == "string") then
			t = string.sub(value,1,2)
			if t == ", " then
				text = text..value
			else
				text = text..comma..value
			end
		elseif (vtype == "boolean") then 
			if (value) then
				text = text..comma.."true" 
			else 
				text = text..comma.."false" 
			end
		elseif (vtype == "table" or vtype == "function" or vtype == "thread" or vtype == "userdata") then 
			text = text..comma.."("..vtype..")"
		else                               
			text = text..comma.."(unknown)"
		end
	end
	local dlevel = tonumber(DA.DebugLevel) -- sanity check
	if not dlevel then dlevel = 1
	elseif dlevel < 1 then dlevel = 1
	elseif dlevel > 9 then dlevel = 10 end
	if (DA.DebugShow and level < dlevel) then
		tekD(DA.DEBUG_COLOR..addonName..": "..text)
	end
	if (not DA.LogLevel or level < dlevel) then
		table.insert(DA.DebugLog,date().."(D"..level.."): "..text)
		if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
			table.remove(DA.DebugLog,1)
		end
	end
end

function DA.TRACE2(...)
	if not DA.TraceLog2 then return "" end
	DA.TRACE(...)
end

function DA.TRACE3(...)
	if not DA.TraceLog3 then return "" end
	DA.TRACE(...)
end

function DA.TRACE(...)
	if not DA.TraceLog then return "" end
	local text = ""
	local comma = ""
	for i = 1, select("#", ...), 1 do
		if (i > 2) then 
			comma = ", "
		end
		local value = select(i,...)
		if issecretvalue and issecretvalue(value) then
			text = text..comma.."(secret)"
		else
			local vtype = type(value)
			if (vtype == "nil") then 
				text = text..comma.."(nil)"
			elseif (vtype == "number") then 
				text = text..comma..tostring(value)
			elseif (vtype == "string") then
				local t = string.sub(value,1,2)
				if t == ", " then
					text = text..value
				else
					text = text..comma..value
				end
			elseif (vtype == "boolean") then 
				if (value) then
					text = text..comma.."true" 
				else 
					text = text..comma.."false" 
				end
			elseif (vtype == "table" or vtype == "function" or vtype == "thread" or vtype == "userdata") then 
				text = text..comma.."("..vtype..")"
			else                               
				text = text..comma.."(unknown)"
			end
		end
	end
	if (DA.TraceShow) then
		tekD(DA.TRACE_COLOR..addonName..": "..text)
	end
	table.insert(DA.DebugLog,date().."(T): "..text)
	if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
		table.remove(DA.DebugLog,1)
	end
end

--
-- Convert a table into a string with line breaks and indents.
--   if specified, m is the maximum recursion depth.
--
function DA.DUMP(o,m,n)
	if o and type(o) == 'table' then
		if not DA.TableDump then return "{table}" end
		local s
		local i = ""
		if n then
			i = string.rep("  ",n)
		else
			n = 0
		end
		s = i..'{\n'
		for k,v in pairs(o) do
			if type(k) ~= 'number' then 
				k = "'"..k.."'" 
			end
			if m and n > m then
				s = s..i..'['..k..'] = {table}\n'
			else
				s = s..i..'['..k..'] = '..DA.DUMP(v,m,n+1)..'\n'
			end
		end
		return string.gsub(s..i..'}\n',"\n\n","\n")
	else
		return tostring(o)
	end
end

--
-- Convert a table into a one line string.
--   if specified, m is the maximum recursion depth.
--
function DA.DUMP1(o,m,n)
	if o and type(o) == 'table' then
		if not DA.TableDump then return "{table}" end
		local s
		if not n then n = 0 end
		s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then 
				k = "'"..k.."'"
			end
			if m and n > m then
				s = s..'['..k..'] = {table}, '
			else
				s = s..'['..k..'] = '..DA.DUMP1(v,m,n+1)..', '
			end
		end
		if strlen(s) > 2 then
			return strsub(s,1,strlen(s)-2)..' }'
		else
			return s..'}'
		end
	else
		return tostring(o)
	end
end

function DA.PROFILE(text)
	local stackstring = debugstack(2, 5, 0) -- start, countTop, countBot
	local now = date()
	table.insert(DA.DebugProfile, now..": "..tostring(text).."\n"..stackstring)
	if (table.getn(DA.DebugProfile) > DA.MAXPROFILE) then
		table.remove(DA.DebugProfile, 1)
	end
	if (DA.ProfileShow) then
		print(DA.DEBUG_COLOR..addonName..": "..text)
	end
	if DA.DebugLogging then
		table.insert(DA.DebugLog, now.."(P): "..tostring(text))
		if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
			table.remove(DA.DebugLog, 1)
		end
	end
end

--
-- Convert a link into a printable string
--
function DA.PLINK(text)
	if text then
		return text:gsub('\124','\124\124')
	end
	return nil
end

function DA.TABLE(text, tab)
	if not DA.DebugShow then return "" end
	if ViragDevTool_AddData then
		ViragDevTool_AddData(tab, addonName..": "..text)
	end
end

function DA.DebugAidsStatus()
	print("WarnShow= "..tostring(DA.WarnShow)..", WarnLog= "..tostring(DA.WarnLog))
	print("DebugShow= "..tostring(DA.DebugShow)..", DebugLogging= "..tostring(DA.DebugLogging)..", DebugLevel= "..tostring(DA.DebugLevel))
	print("TraceShow= "..tostring(DA.TraceShow)..", TraceLog= "..tostring(DA.TraceLog)..", 2= "..tostring(DA.TraceLog2)..", 3= "..tostring(DA.TraceLog3))
	print("ProfileShow= "..tostring(DA.ProfileShow))
	print("TableDump= "..tostring(DA.TableDump))
	print("LogLevel= "..tostring(DA.LogLevel))
	print("#DebugLog= "..tostring(#DA.DebugLog).." ("..tostring(DA.MAXDEBUG)..")")
	print("#DebugProfile= "..tostring(#DA.DebugProfile).." ("..tostring(DA.MAXPROFILE)..")")
end

--
-- These example functions should be incorporated
-- into the slash command processing function
-- (or somewhere else) in your addon.
--
--[[
function DA.Command(msg)
	local _,_,command,options = string.find(msg,"([%w%p]+)%s*(.*)$")
	command = string.lower(command)
	options = string.lower(options)
	if(command == "warn") then  
		DA.Warn()                           -- Undocumented: Enable warning output
	elseif(command == "wlog") then
		DA.WarnL()                          -- Undocumented: Enable warning logging
	elseif(command == "debug") then
		DA.Debug()                          -- Undocumented: Enable debug output
	elseif(command == "dlog") then
		DA.DebugL()                         -- Undocumented: Enable debug logging
	elseif(command == "dlevel") then
		DA.DLevel(options)                  -- Undocumented: Set debug level
	elseif(command == "tdump") then
		DA.TDump(options)                   -- Undocumented: Enable table dumps (recursive functions)
	elseif(command == "trace") then
		DA.Trace()                          -- Undocumented: Enable trace output
	elseif(command == "tlog") then
		DA.TraceL()                         -- Undocumented: Clear debug storage
	elseif(command == "profile") then
		DA.Profile()                        -- Undocumented: Enable trace output
	elseif(command == "clearlog") then
		DA.ClearDebugLog()                  -- Undocumented: Clear debug storage
	elseif(command == "clearprofile") then
		DA.ClearProfileLog()                -- Undocumented: Clear debug storage
	end
end

--
-- Example Slash Command
-- Replace ? with the appropriate name.
--
function DA.OnLoad()
	SLASH_?1 = "/?"
	SlashCmdList["?"] = DA.Command
end
]]--
--
-- Slash command functions
--
-- These functions are called from the slash command snippet at
-- the beginning of this file.
--
--[[
function DA.Warn()
   DA.WarnShow = not DA.WarnShow
   if (DA.WarnShow) then
		DA.WARN("Warning output enabled.")
   else
		DA.CHAT("Warning output disabled.")
   end
end

function DA.WarnL()
   DA.WarnLog = not DA.WarnLog
   if (DA.WarnLog) then
		DA.CHAT("Warning logging enabled.")
   else
		DA.CHAT("Warning logging disabled.")
   end
end

function DA.Debug()
   DA.DebugShow = not DA.DebugShow
   if (DA.DebugShow) then
	  DA.DEBUG(0,"Debug output enabled.")
   else
	  DA.CHAT("Debug output disabled.")
   end
end

function DA.DebugL()
   DA.DebugLogging = not DA.DebugLogging
   if (DA.DebugLogging) then
		DA.CHAT(0,"Debug logging enabled.")
   else
		DA.CHAT("Debug logging disabled.")
   end
end

function DA.DLevel(options)
	local dl = tonumber(options)
	if not dl then dl = 1
	elseif dl < 1 then dl = 1
	elseif dl > 9 then dl = 10 end
	DA.DebugLevel = dl
end

function DA.TDump()
	DA.TableDump= not DA.TableDump
	if (DA.TableDump) then
		DA.CHAT("Table dump enabled.")
	else
		DA.CHAT("Table dump disabled.")
	end
end

function DA.Trace()
	DA.TraceShow = not DA.TraceShow
	if (DA.TraceShow) then
		DA.TRACE("Trace output enabled.")
	else
		DA.CHAT("Trace output disabled.")
	end
end

function DA.TraceL()
	DA.TraceLog = not DA.TraceLog
	if (DA.TraceLog) then
		DA.CHAT("Trace logging enabled.")
	else
		DA.CHAT("Trace logging disabled.")
	end
end

function DA.Profile()
	DA.ProfileShow = not DA.ProfileShow
	if (DA.ProfileShow) then
		DA.CHAT("Profile output enabled.")
	else
		DA.CHAT("Profile output disabled.")
	end
end

function DA.ClearDebugLog()
	DA.CHAT("DebugLog initialized.")
	DA.DebugLog = {}
end

function DA.ClearProfileLog()
	DA.CHAT("ProfileLog initialized.")
	DA.DebugProfile = {}
end
]]--
