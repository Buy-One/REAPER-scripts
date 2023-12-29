--[[
ReaScript name: BuyOne_Prevent Arrange view going past markers with key words.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The idea behind the script is to facilitate focus
		on a specific section of an arrangement preventing
		you from scrolling back and/or forth to other sections
		by placing project markers past which the Arrange
		view cannot be scrolled.  
		
		The start marker must be placed somewhat ahead of the
		section which has to be focused on and the end markers
		somewhat behind it.
		
		After being launched the script runs in the background.
		
		While the script is running a toolbar button or a menu
		item it's linked to will be lit or checkmarked respectivly.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert name of the start and/or end markers;
-- the start marker will prevent Arrange view from being scrolled left
-- while the end marker will prevent it from being scrolled to the right;
-- if the markers are within view and the level of Arrange view zoom-out 
-- prevents scrolling while its start and/or end are already located 
-- outside of the markers, which the script is supposed to prevent, 
-- the script automatically zooms in the Arrange view

START_MARKER_NAME = ""
END_MARKER_NAME = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


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


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state)
-- in deferred scripts can be used to set the toggle state on start
-- and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function RUN()

local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false

-- look for markers
local start_pos, end_pos -- 1st marker pos, 2nd marker pos
local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
	start_pos = not isrgn and name == START_MARKER_NAME and pos or start_pos
	end_pos = not isrgn and name == END_MARKER_NAME and pos or end_pos
	i=i+1
	until retval == 0

	-- restore Arrange view, scroll position and/or zoom
	r.PreventUIRefresh(1)
		if start_pos and start_time < start_pos and end_pos and end_time > end_pos then -- separate condition when both markers are valid, otherwise start and end markers compete with each other and the Arrange flickers
			repeat
			r.GetSet_ArrangeView2(0, true, 0, 0, start_pos, end_pos)
			r.adjustZoom(1, 0, true, -1) -- crucial to prevent endless loop in zoom-out
			local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
			until start_time >= start_pos and end_time <= end_pos
		elseif start_pos and start_time < start_pos then
		local start_time_init
			repeat
			local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
				if start_time ~= start_time_init then
				r.CSurf_OnScroll(1, 0)
				start_time_init = start_time
				else -- prevents endless loop when there's not enough space for scrolling to the marker due to zoom-out, resolved with zoom-in
				r.adjustZoom(1, 0, true, -1) -- amt > 0 zoom in, forceset 0, doupd true
				end
			until start_time >= start_pos
		elseif end_pos and end_time > end_pos then
		local end_time_init
			repeat
			local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
				if end_time ~= end_time_init then
				r.CSurf_OnScroll(-1, 0)
				end_time_init = end_time
				else -- prevents endless loop when there's not enough space for scrolling to the marker due to zoom-out, resolved with zoom-in
				r.adjustZoom(1, 0, true, -1) -- amt > 0 zoom in, forceset 0, doupd true
				end
			until end_time <= end_pos
		end
	r.PreventUIRefresh(-1)


r.defer(RUN)

end


START_MARKER_NAME = #START_MARKER_NAME:gsub(' ','') > 0 and START_MARKER_NAME
END_MARKER_NAME = #END_MARKER_NAME:gsub(' ','') > 0 and END_MARKER_NAME

	if not START_MARKER_NAME and not END_MARKER_NAME then
	Error_Tooltip('\n\n   no marker names \n\n have been specified \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
	start_pos = not isrgn and name == START_MARKER_NAME and pos or start_pos
	end_pos = not isrgn and name == END_MARKER_NAME and pos or end_pos
	i=i+1
	until retval == 0

	if start_pos and end_pos and end_pos <= start_pos then -- prevent going into endless loop
	local err = end_pos < start_pos and 'the end marker precedes \n\n\tthe start marker'
	or end_pos == start_pos and 'marker positions are identical'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

RUN()

r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0))








