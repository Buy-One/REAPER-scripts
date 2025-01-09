--[[
ReaScript name: BuyOne_Zoom in to project (to be used inside a custom action).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script is meant to be used inside horizontal zoom
	custom action to prevent zooming out beyond project bounds, e.g.:
	
	Custom: Zoom horizontally respecting project bounds when zooming out
		View: Zoom horizontally (MIDI CC relative/mousewheel)
		Script: BuyOne_Zoom in to project (to be used inside a custom action).lua
	
	Project left bound is 0 sec on the time line while project right bound
	is the location of one of the following: end of the last media item, 
	the last marker, end of the last region, the last tempo envelope point, 
	whichever is the farthest on the time line.  
	So the script prevents zooming out beyond the project farthest coordinate
	which as i was told some other DAWs do automatically.
			
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



local proj_len = r.GetProjectLength(0)
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true

	if end_time-start_time > proj_len then -- prevent zooming out beyond project length or zoom in to project
	r.PreventUIRefresh(1) -- makes scrolling applied below unnoticeable
	-- all the manipulations make the project end being as close as possible to the right vertical scroll bar,
	-- which is not where it ends after the action 'View: Zoom out project' is applied leaving some dead space on the right
	local arrange_len_px = math.floor(r.GetHZoomLevel()*(end_time-start_time)+0.5)
	local lt, top, rt, bot = r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true) -- wantWorkArea true - work area, false - the entire screen
--[-[ VERSION 1
	r.GetSet_ArrangeView2(0, true, 0, arrange_len_px-20, 0, proj_len) -- isSet true, screen_x_end is arrange_len_px-20 to account for the right vertical scroll bar which isn't considered the Arrange end and whose width is 17 px, end_time is proj_len
	r.CSurf_OnScroll(-1000,0) -- after changing Arrange view, horizontal scroll position may end up farther from 0, so adjust that as well, -1000 is 16*-1000 which should siffice
--]]
--[[ VERSION 2
	-- A BIT CONVOLUTED due to the use of adjustZoom() in which amt value depends on the program window width but the exact relationship isn't clear, although current values should more or less suffice in most cases
	r.GetSet_ArrangeView2(0, true, 0, 0, 0, proj_len) -- isSet true, screen_x_start & screen_x_end are 0, start_time is 0, end_time is proj_len
	local amt = arrange_len_px > rt/2 and -0.125 or -0.5 -- values in sec
	r.adjustZoom(amt, 0, true, -1) -- forceset 0, doupd true, centermode -1 default // GetSet_ArrangeView2() doesn't take into account the width of the right vertical scrollbar so the project end ends up going beyond it to the program window right edge, zoom adusts that by zooming out by the amt value
	r.CSurf_OnScroll(-1,0) -- after changing the zoom, horizontal scroll position may end up farther from 0, so adjust that as well, -1 which is -16 px should siffice
--]]
	r.PreventUIRefresh(-1)
	end


do return r.defer(no_undo) end -- prevent creation of undo points

