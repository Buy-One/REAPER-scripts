--[[
ReaScript name: BuyOne_Adjust track volume at selected resolution with mousewheel.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About:	The script only makes sense if the options
	'Ignore mousewheel on all faders'
	AND/OR
	'Ignore mousewheel on track panel controls'
	are enabled at Preferences -> Editing Behavior -> Mouse

	Otherwise control with the mousewheel is supported natively.
	
	Bind to a mousewheel, preferably with a modifier if your
	aim is to be able to adjust track panel controls with
	the mousewheel while preventing bare mousewheel from
	affecting controls when it's placed over the TCP.
	
	With builds prior to 6.36 the mouse cursor doesn't 
	have to be over the volume control for the script to work,
	but hovering over the TCP is essential.		
	
	MCP is only supported in builds 6.36 and later provided
	the preference at 
	Preferences -> Editing behavior -> Mouse -> Mousewheel targets
	is set to 'Window with focus', the Mixer window is not in
	focus and the mouse cursor hovers over the volume control.
	If the Mixer window is in focus REAPER's built-in Mixer scroll
	will take over and override the script.
	
	See also script 
	BuyOne_Adjust track, item, envelope points, FX parameters with mousewheel.lua
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- One mousewheel nudge equals 0.05 dB, while scrolling several 
-- such nudges are performed in a row
-- which amount to about 0.2-0.3 dB;
-- Specify the desired value if coarser resolution is needed, 
-- empty or invalid defaults to 0.05 dB
RESOLUTION = ""

-- For regular and stereo pan modes the default direction is:
-- mousewheel out/up - ascending order,
-- mousewheel in/down - descending order;
-- enable by inserting any alphanumeric character
-- between the quotes to reverse the direction
MOUSEWHEEL_REVERSE = ""

-- Enable by inserting any alphanumeric character 
-- between the quotes to make the script create undo point 
-- after every run;
-- MAY NOT BE DESIRABLE because scrolling with the mousewheel 
-- will inundate the undo history with multiple undo points
UNDO = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
r.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
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


function Get_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end


function round(num, idp) -- idp = number of decimal places, 0 means rounding to integer
-- http://lua-users.org/wiki/SimpleRound
-- round to N decimal places
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


function Process_Mouse_Wheel_Direction(val, mousewheel_reverse) 
-- val comes from r.get_action_context()
-- mousewheel_reverse is boolean
-- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards
local left_down, right_up = table.unpack(mousewheel_reverse 
and {val > 0, val < 0} or {val < 0, val > 0}) -- left/down, right/up
return left_down, right_up
end


RESOLUTION = validate_sett(RESOLUTION) and tonumber(RESOLUTION) and tonumber(RESOLUTION) or 0.05 -- TO USE WITH API
UNDO = validate_sett(UNDO)
MOUSEWHEEL_REVERSE = validate_sett(MOUSEWHEEL_REVERSE)
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local tr, ui_obj = table.unpack(r.GetThingFromPoint and {r.GetThingFromPoint(r.GetMousePosition())} or {}) -- GetThingFromPoint is only supported since build 6.36
tr = ui_obj and ui_obj:match('[mt]cp.volume') and tr or not ui_obj and Get_TCP_Under_Mouse()
local down, up = Process_Mouse_Wheel_Direction(val, MOUSEWHEEL_REVERSE)
local err = mode == 0 and '\tthe script must be \n\n    run with a mousewheel \n\n or MIDI CC in relative mode'
or not tr and (ui_obj and #ui_obj > 0 and 'no volume control \n\n   under the mouse' or 'no track at the mouse cursor') 

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo)
	end


local vol = r.GetMediaTrackInfo_Value(tr, 'D_VOL')	
local sign = down and -1 or up and 1
local vol_dB = 20*math.log(vol, 10) + RESOLUTION*sign
local vol_dB = vol_dB > 12 and 12 or vol_dB < -144 and -144 or vol_dB -- cap the extremes to prevent going beyond the acceptable range limits // -144 is the dynamic range lower limit of 24 bit audio
local vol_new = 10^(vol_dB/20)	
local displ_sign = vol_dB > 0 and '+' or ''
Error_Tooltip('\n  '..displ_sign..round(vol_dB, 2)..' dB \n ', false, false, 0, -60) -- caps, spaced false, x2 0, y2 -60 // truncating the value down to 2 decimal places
	
local undo = UNDO and r.Undo_BeginBlock()

r.SetMediaTrackInfo_Value(tr, 'D_VOL', vol_new)

	if UNDO then
	local by = (vol_dB == -144 or vol_dB == 12) and 0 or RESOLUTION*sign
	r.Undo_EndBlock('Adjust track volume by '..by..' dB to '..vol_dB..' dB', -1)
	else
	return r.defer(no_undo)
	end
	



	
