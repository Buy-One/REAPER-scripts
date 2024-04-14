--[[
ReaScript name: BuyOne_Adjust track pan and volume at selected resolution with mousewheel.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.63
Extensions: 
Provides: [main=main,midi_editor] .
About:	The script only makes sense if the options
	'Ignore mousewheel on all faders'
	AND/OR
	'Ignore mousewheel on track panel controls'
	are enabled at Preferences -> Editing Behavior -> Mouse

	Otherwise control with the mousewheel is supported natively.
	
	To target a control the mouse cursor must be placed
	directly over it.
	
	With respect to pan control the script applies to all 
	pan modes, that is stereo pan and dual pan as well.
	
	Bind to a mousewheel, preferably with a modifier if your
	aim is to be able to adjust track panel controls with
	the mousewheel while preventing bare mousewheel from
	affecting controls when it's placed over the TCP.
	
	The script is able to affect relevant MCP controls provided
	the preference at 
	Preferences -> Editing behavior -> Mouse -> Mousewheel targets
	is set to 'Window with focus', the Mixer window is not in
	focus and the mouse cursor hovers over the pan/width control.
	If the Mixer window is in focus REAPER's built-in Mixer scroll
	will take over and override the script.
	
	See also script 
	BuyOne_Adjust track, item, envelope points, FX parameters with mousewheel.lua
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- One mousewheel nudge equals 1%, while scrolling several
-- such nudges are performed in a row which amount to about
-- between the quotes specify the desired value of pan persentage
-- per one mousewheel nudge if coarser resolution is needed;
-- supported values are 1 through 100, 1 equals default,
-- empty or invalid defaults to 1%;
-- the settings applies to regular pan, dual pan and stereo pan modes
PAN_RESOLUTION = ""

-- One mousewheel nudge equals 0.05 dB, while scrolling several
-- such nudges are performed in a row
-- which amount to about 0.2-0.3 dB;
-- Specify the desired value if coarser resolution is needed,
-- empty or invalid defaults to 0.05 dB
VOL_RESOLUTION = ""

-- For regular and stereo pan modes the default direction is:
-- mousewheel out/up - ascending order,
-- mousewheel in/down - descending order;
-- in dual pan mode for both sliders the default direction is:
-- mousewheel out/up - rightwards,
-- mousewheel in/down - leftwards;
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


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.36 then
	Error_Tooltip('\n\n\tthe script requires \n\n reaper build 6.36 and later \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


PAN_RESOLUTION = validate_sett(PAN_RESOLUTION) and tonumber(PAN_RESOLUTION) and tonumber(PAN_RESOLUTION) or 1
VOL_RESOLUTION = validate_sett(VOL_RESOLUTION) and tonumber(VOL_RESOLUTION) and tonumber(VOL_RESOLUTION) or 0.05
UNDO = validate_sett(UNDO)
MOUSEWHEEL_REVERSE = validate_sett(MOUSEWHEEL_REVERSE)
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local tr, ui_obj = r.GetThingFromPoint(r.GetMousePosition()) -- GetThingFromPoint is only supported since build 6.36
local pan, vol = ui_obj:match('[mt]cp.pan') or ui_obj:match('[mt]cp.width'), ui_obj:match('[mt]cp.volume')
local down, up = Process_Mouse_Wheel_Direction(val, MOUSEWHEEL_REVERSE)
local elm = ui_obj and ui_obj:match('%.(.+)')
local err = mode == 0 and '\tthe script must be \n\n    run with a mousewheel \n\n or MIDI CC in relative mode'
or not pan and not vol and 'no pan/width or volume control \n\n\t     under the mouse'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo)
	end

	if pan then

	local pan_mode = r.GetMediaTrackInfo_Value(tr, 'I_PANMODE')
	local st_pan, dual_pan = pan_mode == 5, pan_mode == 6
	PARM = st_pan and (ui_obj == 'tcp.pan' and 'D_PAN' or ui_obj == 'tcp.width' and 'D_WIDTH')
	or dual_pan and (ui_obj == 'tcp.pan' and 'D_DUALPANL' or ui_obj == 'tcp.width' and 'D_DUALPANR') or 'D_PAN'
	local pan_val = r.GetMediaTrackInfo_Value(tr, PARM) -- range -1 - +1
	local sign = down and -1 or up and 1
	val_new = down and pan_val <= -1 and -1 or up and pan_val >= 1 and 1 or pan_val+(PAN_RESOLUTION/100)*sign -- pan_val is never equal -1 or 1 even though it's displayed as such in the Console, hence < and > are used to prevent going above 100%L or 100%R which happens because there's no cap in the API

	-- concatenate readout
	local parm = st_pan and (ui_obj == 'tcp.pan' and 'pan' or ui_obj == 'tcp.width' and 'width')
	or dual_pan and (ui_obj == 'tcp.pan' and 'left pan' or ui_obj == 'tcp.width' and 'right pan') or 'pan'
	local displ_val = math.floor(val_new*100+0.5)
	readout = parm:match('pan') and parm..': '..(displ_val < 0 and math.abs(displ_val)..'L' or displ_val == 0 and '0' or displ_val..'R')..'%'
	or parm == 'width' and parm..': '..displ_val..'%'
	local by = (pan_val <= -1 and val_new == -1 or pan_val >= 1 and val_new == 1) and 0 or PAN_RESOLUTION*sign

	undo = 'Adjust track '..parm..' by '..by..'% to '..displ_val..'%'

	elseif vol then

	PARM = 'D_VOL'
	local vol = r.GetMediaTrackInfo_Value(tr, PARM)
	local sign = down and -1 or up and 1
	local vol_dB = 20*math.log(vol, 10) + VOL_RESOLUTION*sign
	local vol_dB = vol_dB > 12 and 12 or vol_dB < -144 and -144 or vol_dB -- cap the extremes to prevent going beyond the acceptable range limits // -144 is the dynamic range lower limit of 24 bit audio
	val_new = 10^(vol_dB/20)
	local displ_sign = vol_dB > 0 and '+' or ''
	readout = displ_sign..round(vol_dB, 3)..' dB'
	local by = (vol_dB == -144 or vol_dB == 12) and 0 or VOL_RESOLUTION*sign
	undo = 'Adjust track volume by '..by..' dB to '..vol_dB..' dB'

	end

local displ = readout and Error_Tooltip('\n '..readout..' \n ', pan, pan, 0, -60) -- caps, spaced are only true if pan, x2 0, y2 60

	if UNDO then r.Undo_BeginBlock() end

r.SetMediaTrackInfo_Value(tr, PARM, val_new)

	if UNDO then
	r.Undo_EndBlock(undo, -1)
	else
	return r.defer(no_undo)
	end


