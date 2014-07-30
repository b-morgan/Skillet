local addonName,addonTable = ...
local DA = _G[addonName]
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
-- DA.WARN and DA.DEBUG always add their text to
-- DA.DebugLog, a circular table which has DA.MAXDEBUG
-- entries. DA.TRACE optionally adds its text to the 
-- same circular table. 
--
-- Setting DA.TraceLog will add the DA.TRACE 
-- text to the circular table without printing to 
-- the default chat frame. 
-- 
DA.WarnShow = false
DA.DebugShow = false
DA.TraceShow = false
DA.TraceLog = false
DA.DebugLevel = 1
DA.DebugLog = {} -- Add to SavedVariables for debugging
DA.MAXDEBUG = 2000
DA.STATUS_COLOR = "|c0033CCFF"
DA.DEBUG_COLOR  = "|c0000FF00"
DA.TRACE_COLOR  = "|c0000FFA0"
DA.WARN_COLOR   = "|c0000FFE0"

function DA.CHAT(text)
	print(DA.STATUS_COLOR..text)
end

function DA.WARN(...)
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
	if (DA.WarnShow) then
		DA.CHAT(DA.WARN_COLOR..addonName..": "..text)
	end
	table.insert(DA.DebugLog,date().."(W): "..text)
	if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
		table.remove(DA.DebugLog,1)
	end
end

function DA.DEBUG(...)
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
		level = 0 -- assume this is a deprecated call and
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
		DA.CHAT(DA.DEBUG_COLOR..addonName..": "..text)
	end
	table.insert(DA.DebugLog,date().."(D"..level.."): "..text)
	if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
		table.remove(DA.DebugLog,1)
	end
end

function DA.TRACE(...)
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
	if (DA.TraceShow) then
		DA.CHAT(DA.TRACE_COLOR..addonName..": "..text)
	end
	if (DA.TraceShow or DA.TraceLog) then
		table.insert(DA.DebugLog,date().."(T): "..text)
		if (table.getn(DA.DebugLog) > DA.MAXDEBUG) then
			table.remove(DA.DebugLog,1)
		end
	end
end

-- Convert a table into a string with line breaks and indents.
function DA.DUMP(o,n)
    if type(o) == 'table' then
        local s
		local i = ""
		if (n) then
			i = string.rep(" ",n)
		else
			n = 0
		end
		s = i..'{\n'
        for k,v in pairs(o) do
			if type(k) ~= 'number' then 
				k = "'"..k.."'" 
			end
			s = s..i..'['..k..'] = '..DA.DUMP(v,n+1)..'\n'
        end
        return s..i..'}\n'
    else
        return tostring(o)
    end
end

-- Convert a table into a one line string.
function DA.DUMP1(o)
    if type(o) == 'table' then
        local s
		s = '{ '
        for k,v in pairs(o) do
			if type(k) ~= 'number' then 
				k = "'"..k.."'"
			end
			s = s..'['..k..'] = '..DA.DUMP1(v)..', '
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
		DA.Warn()                         -- Undocumented: Enable warning output
	elseif(command == "debug") then
		DA.Debug()                        -- Undocumented: Enable debug output
	elseif(command == "dlevel") then
		DA.DLevel(options)                 -- Undocumented: Set debug level
	elseif(command == "trace") then
		DA.Trace()                        -- Undocumented: Enable trace output
	elseif(command == "clear") then
		DA.ClearDebugLog()                -- Undocumented: Clear debug storage
	elseif(command == "tlog") then
		DA.TLog()                         -- Undocumented: Clear debug storage
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

function DA.Debug()
   DA.DebugShow = not DA.DebugShow
   if (DA.DebugShow) then
      DA.DEBUG(0,"Debug output enabled.")
   else
      DA.CHAT("Debug output disabled.")
   end
end

function DA.ClearDebugLog()
	DA.CHAT("DebugLog initialized.")
	DA.DebugLog = {}
end

function DA.Trace()
	DA.TraceShow = not DA.TraceShow
	if (DA.TraceShow) then
		DA.TRACE("Trace output enabled.")
	else
		DA.CHAT("Trace output disabled.")
	end
end

function DA.DLevel(options)
	local dl = tonumber(options)
	if not dl then dl = 1
	elseif dl < 1 then dl = 1
	elseif dl > 9 then dl = 10 end
	DA.DebugLevel = dl
end

function DA.TLog()
	DA.TraceLog = not DA.TraceLog
	if (DA.TraceLog) then
		DA.CHAT("Trace logging enabled.")
	else
		DA.CHAT("Trace logging disabled.")
	end
end
]]--