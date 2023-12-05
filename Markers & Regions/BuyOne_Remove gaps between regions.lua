--[[
ReaScript name: BuyOne_Remove gaps between regions.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Removed redundant line of code
		#Updated custom actions in the 'About' text
	   v1.1 #Added condition to only remove gaps between regions in time selection if one exists
		#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
About: 	The script removes gaps between regions shifting them
	leftwards.  
	If time selection encompasses regions only gaps between 
	regions within the time selection will be removed.  
	If the option 'Options: Move envelope points with media items'
	is turned off the script temporarily enables it so that 
	automation follows regions shift on the time line.
	
	Alternatively to remove gap between two adjacent regions or
	between the project start and the 1st region the following custom 
	actions can be used:
	
	Custom: Remove gap between two adjacent regions (place edit cursor within the 1st region)
	  Time selection: Remove (unselect) time selection
	  Markers: Go to next marker/project end
	  Time selection: Set start point
	  Markers: Go to next marker/project end
	  Time selection: Set end point
	  Time selection: Remove contents of time selection (moving later items)
	  Time selection: Remove (unselect) time selection
	  
	Custom: Remove gap between project start and the 1st region (place edit cursor before 1st region)
	  Transport: Go to start of project
	  Time selection: Set start point
	  Markers: Go to next marker/project end
	  Time selection: Set end point
	  Time selection: Remove contents of time selection (moving later items)
	  Time selection: Remove (unselect) time selection
	 
	
	They work as long as there're no markers within or outside of the regions
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Enable to move all regions to the project start
-- in case the first or the only region doesn't start at 0;
-- BE MINDFUL OF PRESENCE OF ANY DATA BETWEEN THE PROJECT START
-- AND THE FIRST/ONLY REGION LEST THEY GET ERASED

MOVE_TO_PROJ_START = ""

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

local time_st, time_end = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = time_st ~= time_end
local t, i = {}, 0
local region_cnt, prev_end = 0
	repeat
	local retval, isrgn, pos, rgn_end, name, idx = r.EnumProjectMarkers(i)
	region_cnt = isrgn and region_cnt+1 or region_cnt
		if isrgn and prev_end and pos > prev_end 
		and (not time_sel or time_st <= prev_end and time_end >= pos)
		then
		t[#t+1] = {st=prev_end, fin=pos}
		end
	prev_end = (not prev_end or pos >= prev_end) and rgn_end or prev_end -- if next region end time is smaller than that of the previous one such region is enclosed within the previous hence keep the previous region end because this region is longer, only update if the next region start is equal or greater than the prev region end
	i=i+1
	until retval == 0


MOVE_TO_PROJ_START = #MOVE_TO_PROJ_START:gsub(' ','') > 0

	if MOVE_TO_PROJ_START then
	local retval, isrgn, pos, rgn_end, name, idx = r.EnumProjectMarkers(0) -- get 1st region pos
		if pos > 0 then
		table.insert(t, 1, {st=0, fin=pos})
		end
	end

local err = region_cnt == 0 and 'no regions in the project'
or #t == 0 and region_cnt == 1 and '\tnot enough regons \n\n in the project to have gaps'
or #t == 0 and 'no gaps between regions'
..(time_sel and ' \n\n      in time selection \n\n\t  or no regions\n\n\tin time selection' or '')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local Act = r.Main_OnCommand

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local link_env = r.GetToggleCommandStateEx(0, 40070) == 1 -- Options: Move envelope points with media items
local enable = link_env and Act(40070,0) -- Options: Move envelope points with media items

	for i = #t,1,-1 do -- in reverse so that the stored region end values become obsolete after the shift and not before it
	local st, fin = t[i].st, t[i].fin -- st is prev region end, fin is the next region start
	r.GetSet_LoopTimeRange(true, false, st, fin, false) -- isSet true, isLoop, allowautoseek false
	Act(40201,0) -- Time selection: Remove contents of time selection (moving later items)
	end

local restore = link_env and Act(40070,0) -- Options: Move envelope points with media items
local restore =  r.GetSet_LoopTimeRange(true, false, time_st, time_end, false) -- isSet true, isLoop, allowautoseek false

r.Undo_EndBlock('Remove gaps between regions', -1)
r.PreventUIRefresh(-1)









