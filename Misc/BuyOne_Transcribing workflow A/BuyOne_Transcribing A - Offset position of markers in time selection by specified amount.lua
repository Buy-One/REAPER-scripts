--[[
ReaScript name: BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing A workflow set of scripts
	alongside  
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua   
	BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing A - Go to segment marker.lua
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua

	The script can be used for general purposes because it
	affects all markers in time selection, which is something
	to be aware of if you're using it as part of Transcribing A 
	workflow in cases where you only wish to offset segment 
	markers and leave any other markers at their original positions.
	In this scenario also be aware that the script doesn't update
	segment markers time stamp included in their name. To do this
	run 'BuyOne_Transcribing A - Create and manage segments (MAIN).lua'
	script in 'Batch segment update' mode described in par. F of its
	'About:' text. The time stamps will be updated both in segment
	marker names and in the segment entries in the Notes.  
	
	In the offset amount dialogue which will pop up fields which 
	aren't necessary can be left empty. In 'Direction' field enter
	any character (to add negative sign to the offset amount) if 
	markers must be moved left.
]]


local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
	if want_color then
	local color_init = r.GetThemeColor('col_tl_bg', 0)
	local color = color_init ~= 255 and 255 or 65535 -- use red or yellow of red is taken
		if want_blink then
		    for i = 1, 100 do
				if i == 1 or i == 40 or i == 80 then
				r.SetThemeColor('col_tl_bg', color, 0)
				elseif i == 20 or i == 60 or i == 100 then
				r.SetThemeColor('col_tl_bg', color_init, 0)
				end
				r.UpdateTimeline()
			end
		else
		r.SetThemeColor('col_tl_bg', color, 0) -- Timeline background
			for i = 1, 200 do -- ensures that the warning color sticks for some time
			-- without the function inside the loop the end (200) value must be much greater
			r.UpdateTimeline()
			end
		r.SetThemeColor('col_tl_bg', color_init, 0) -- Timeline background // restore the orig color
		r.UpdateTimeline() -- without this function the color will only be restored when user clicks within the Arrange
		end
	end
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end




function GetUserInputs_Alt(title, field_cnt, field_names, field_cont, separator, comment_field, comment)
-- title string, field_cnt integer, field_names string separator delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string unless they must be initially filled
-- to fill out only specific fields precede them with as many separator characters 
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5
-- separator is a string, character which delimits the fields
-- comment_field is boolean, comment is string to be displayed in the comment field
-- extrawidth parameter is inside the function
	if field_cnt == 0 then return end

	local function add_separators(field_cnt, field_cont, sep) 
	-- add delimiting separators when they're fewer than field_cnt
	-- due to lacking field names or field content
	local _, sep_cnt = field_cont:gsub(sep,'')
	return sep_cnt == field_cnt-1 and field_cont -- -1 because the last field isn't followed by a separator
	or sep_cnt < field_cnt-1 and field_cont..(sep):rep(field_cnt-1-sep_cnt)
	end

-- for field names sep must be a comma because that's what field names list is delimited by 
-- regardless of internal 'separator=' argument
local field_names = type(field_names) == 'table' and table.concat(field_names,',') or field_names
field_names = add_separators(field_cnt, field_names, ',')
field_names = field_names:gsub(', ', ',') -- if there's space after comma, remove because with multiple fields the names will not line up vertically
local sep = separator or ','
local field_cont = add_separators(field_cnt, field_cont, sep)
local comment = comment_field and comment and type(comment) == 'string' and #comment > 0 and comment or ''
local field_cnt = comment_field and #comment > 0 and field_cnt+1 or field_cnt
field_names = comment_field and #comment > 0 and field_names..',Comment:' or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = separator and ',separator='..separator or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=0'..separator, field_cont)
output = #comment > 0 and output:match('(.+'..sep..')') or output -- exclude comment field keeping separator to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement
	if not ret or (field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0) then return end
	--[[ OR
	-- to condition action by the type of the button pressed
	if not ret then return 'cancel'
	elseif field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0 then return 'empty' end
	]]
local t = {}
	for s in output:gmatch('(.-)'..sep) do
		if s then t[#t+1] = s end
	end
	if #comment == 0 then 
	-- if the last field isn't comment, 
	-- add it to the table because due to lack of separator at its end 
	-- it wasn't caught in the above loop
	t[#t+1] = output:match('.+'..sep..'(.*)')
	end
return t, #comment > 0 and output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it
end



function Get_Markers_Regions_In_Time_Sel(obj)
local mrkrs, rgns = obj == 'markers', obj == 'regions'
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local t, i = {}, 0
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0,i)
		if retval > 0 and (mrkrs and not isrgn or rgns and isrgn) then
		local pos = pos >= st and pos <= fin and pos -- applies to both markers and region
		local fin = rgns and rgnend >= st and rgnend <= fin and rgnend
			if pos or fin then -- region start or end may be outside of tieme selection
			t[#t+1] = {idx=i, st=pos, fin=fin}
			elseif #t > 0 then break -- as soon as the loop reaches time selection end
			end
		end
	i = i+1
	until retval == 0
return t
end


function Offset_Markers_Regions_In_Time_Sel(t, val, obj)
-- in reverse if shifting rightwards, and in ascending order if shifting leftwards
-- helps to keep orderly movement and maintain indices on the time line
local rgns = obj == 'regions'
local st, fin, dir = table.unpack(val > 0 and {#t,1,-1} or val < 1 and {1,#t,1})
	for i=st, fin, dir do
	local idx, st, fin = t[i].idx, t[i].st, t[i].fin
	-- get props to keep them while setting
	local retval, isrgn, pos, rgnend, name, ID, color = r.EnumProjectMarkers3(0,idx)
	pos = st and st+val or pos -- if region start is outside of time selection t[i].st will be nil
	fin = fin and (rgns and fin+val or 0) or rgnend -- if region end is outside of time selection t[i].fin will be nil
	r.SetProjectMarkerByIndex(0, idx, rgns, pos, fin, ID, name, color) -- the function clears region/marker selection in builds 7.16 and later, but report https://forum.cockos.com/showthread.php?t=294573
	-- SetProjectMarker() functions don't do that but they're unreliable because of targeting objects
	-- by displayed index which can be identical in several objects if explicitly changed by the user
	-- so one would have to first resolve all duplicates, the action
	-- 'Markers: Renumber all markers and regions in timeline order'
	-- isn't suitable because it renumbers all in ascending order irrespective of duplicate indices
	end
end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local obj = scr_name:match('.+[\\/].-of (%a+)')
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false

local err = obj ~= 'markers' and obj ~= 'regions' and ' the script name \n\n has been altered'
or st == fin and 'time selection is not set'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local obj_t = Get_Markers_Regions_In_Time_Sel(obj)

	if #obj_t == 0 then
	Error_Tooltip("\n\n no "..obj.." in time selection \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end
	
local output_t, output

::RETRY::

output_t, output = GetUserInputs_Alt(('project '..obj):upper()..' OFFSET AMOUNT', 5, 
'Hours (or empty), Minutes (or empty), Seconds (or empty), Milliseconds (or empty),' -- the string break can be fashioned with \z without concatenation but this isn't supported in earlier Lua vesrions
..'Direction (any character — )', output or '', ',')

	if not output_t then return r.defer(no_undo) end
	
local val = ''
	
	for i=1, #output_t-1 do -- ignoring last field 'Direction'
	local unit = output_t[i]
	unit = #unit > 0 and tonumber(unit) and unit or '0'
	val = val..unit..(i < 3 and ':' or i == 3 and '.' or '') -- 3 because there're 3 components in the time stamp separated by the colon, the last, milliseconds are separated by the period and not followed by any separator
	end

val = r.parse_timestr(val)

	if val == 0 then	
	Error_Tooltip("\n\n invalid amount \n\n", 1, 1) -- caps, spaced true
	goto RETRY
	end

val = #output_t[5]:gsub('[%c%s]','') > 0 and val*-1 or val -- convert to genative if 'Direction' field isn't empty

	if val < 0 and (obj_t[1].st and obj_t[1].st+val < 0 or obj_t[1].fin and obj_t[1].fin+val < 0) then
	Error_Tooltip("\n\n the amount overshoots \n\n\t project start \n\n", 1, 1) -- caps, spaced true
	goto RETRY
	end

r.Undo_BeginBlock()

Offset_Markers_Regions_In_Time_Sel(obj_t, val, obj)

r.Undo_BeginBlock('Transcribing A: Offset position of '..obj..' by '..val)






