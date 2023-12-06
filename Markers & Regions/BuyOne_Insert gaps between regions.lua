--[[
ReaScript name: BuyOne_Insert gaps between regions.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: v1.1 #Added an option to specify gap length in frames when dialogue is enabled
Licence: WTFPL
REAPER: at least v5.962
About: 	The script inserts gaps between regions shifting them
	rightwards.  
	If time selection encompasses contiguous regions meeting
	points only gaps between regions within the time selection 
	will be inserted. 
	
	If the option 'Options: Move envelope points with media items'
	is turned off the script temporarily enables it so that 
	automation follows regions shift on the time line.
	
	By defult the length of the gap equals the length of division
	in the currently active grid. So to change the gap length change
	the grid resolution before running the script.  
	If DIALOGUE setting is enabled, gaps of arbitrary length in 
	seconds can be inserted.
	
	Alternatively to insert gap between two contiguous regions or
	between the project start and the 1st region the following custom 
	actions can be used:
	
	Custom: Insert gap between two contiguous regions (place edit cursor within the 1st region)
	  Time selection: Remove (unselect) time selection
	  Markers: Go to next marker/project end
	  Time selection: Set start point
	  View: Move cursor right to grid division
	  Time selection: Set end point
	  Time selection: Insert empty space at time selection (moving later items)
	  Time selection: Remove (unselect) time selection
	  
	Custom: Insert gap between project start and the 1st region
	  Transport: Go to start of project
	  Time selection: Set start point
	  View: Move cursor right to grid division
	  Time selection: Set end point
	  Time selection: Insert empty space at time selection (moving later items)
	  Time selection: Remove (unselect) time selection
		 
		
	They work as long as there're no markers within the regions.
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Enable to shift all regions from the project start
-- in case the first or the only region starts at 0

SHIFT_FROM_PROJ_START = ""

-- Enable to be able to use arbitrary gap length in seconds or frames

DIALOGUE = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------a

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Grid_Div_Dur_In_Sec() -- in sec
-- grid division (div) is the one set in the Snap/Grid settings
local retval, div, swingmode, swingamt = r.GetSetProjectGrid(0, false, 0, 0, 0) -- proj is 0, set is false, division, swingmode & swingamt are 0 (disabled for the purpose of fetching the data)
--local convers_t = {[0.015625] = 0.0625, [0.03125] = 0.125, [0.0625] = 0.25, [0.125] = 0.5, [0.25] = 1, [0.5] = 2, [1] = 4} -- number of quarter notes in grid division; conversion from div value
--return grid_div_time = 60/r.Master_GetTempo()*convers_t[div] -- duration of 1 grid division in sec
-- OR
--local grid_div_time = 60/r.Master_GetTempo()*div/0.25 -- duration of 1 grid division in sec; 0.25 corresponds to a quarter note as per GetSetProjectGrid()
--return grid_div_time
-- OR
return 60/r.Master_GetTempo()*div/0.25 -- duration of 1 grid division in sec; 0.25 corresponds to a quarter note as per GetSetProjectGrid()
end


function frames2sec(frames_num)
local frame_rate, isdropFrame = r.TimeMap_curFrameRate(0)
return frames_num/frame_rate
--[[ OR
local sec_per_frame = 1/frame_rate
return frames_num*sec_per_frame
]]
end


local time_st, time_end = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = time_st ~= time_end
local t, i = {}, 0
local region_cnt, prev_end = 0
	repeat
	local retval, isrgn, pos, rgn_end, name, idx = r.EnumProjectMarkers(i)
	region_cnt = isrgn and region_cnt+1 or region_cnt
		if isrgn and prev_end and pos == prev_end 
		and (not time_sel or time_st < prev_end and time_end > pos) -- or > prev_end
		then
		t[#t+1] = prev_end
		end
	prev_end = rgn_end
	i=i+1
	until retval == 0


SHIFT_FROM_PROJ_START = #SHIFT_FROM_PROJ_START:gsub(' ','') > 0

	if SHIFT_FROM_PROJ_START then
	local retval, isrgn, pos, rgn_end, name, idx = r.EnumProjectMarkers(0) -- get 1st region pos
		if pos == 0 then
		table.insert(t, 1, 0)
		end
	end

local err = region_cnt == 0 and 'no regions in the project'
or #t == 0 and region_cnt == 1 and '\t  not enough regons \n\n in the project to insert gaps'
or #t == 0 and 'no regions to insert \n\n\tgaps between'
..(time_sel and ' \n\n   in time selection \n\n      or no regions\n\n    in time selection' or '')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local Act = r.Main_OnCommand

DIALOGUE = #DIALOGUE:gsub(' ','') > 0

::RETRY::
local comm = ',to indicate frame add F or f'
output = output and output..comm or comm
ret, output = table.unpack(DIALOGUE -- global to be able to autofill the dialogue with last entry in RETRY loop
and {r.GetUserInputs('INSERT GAPS BETWEEN REGIONS', 2, 'Gap length in sec or frames, comment:,extrawidth=100', output or '')}
or {})
output = output and output:match('(.+),') -- exclude comment

	if DIALOGUE and (not ret or #output:gsub(' ','') == 0) then return r.defer(no_undo) end
	
local frames = DIALOGUE and output:match('[Ff]+')
val = DIALOGUE and output:gsub('[%-%a%s]+','') -- remove some invalid characters
val = DIALOGUE and tonumber(val) or not DIALOGUE and Grid_Div_Dur_In_Sec()

	if not val or val == 0 then Error_Tooltip('\n\n not a valid input \n\n', 1,1) -- caps, spaced true
	goto RETRY
	end

val = DIALOGUE and frames and frames2sec(val) or val

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local link_env = r.GetToggleCommandStateEx(0, 40070) == 1 -- Options: Move envelope points with media items
local enable = link_env and Act(40070,0) -- Options: Move envelope points with media items

	for i = #t,1,-1 do -- in reverse so that the stored region end values become obsolete after the shift and not before it
	r.GetSet_LoopTimeRange(true, false, t[i], t[i]+val, false) -- isSet true, isLoop, allowautoseek false
	Act(40200,0) -- Time selection: Insert empty space at time selection (moving later items)
	end

local restore = link_env and Act(40070,0) -- Options: Move envelope points with media items
local restore =  r.GetSet_LoopTimeRange(true, false, time_st, time_end, false) -- isSet true, isLoop, allowautoseek false

r.Undo_EndBlock('Insert gaps between regions', -1)
r.PreventUIRefresh(-1)









