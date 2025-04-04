--[[
ReaScript name: BuyOne_Move edit cursor right by grid division size (relative).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script follows the actual grid resolution, not visible grid
	which depends on the zoom level.

	See also BuyOne_Move edit cursor left by grid division size (relative).lua
	
	To move the edit cursor both left and right with the mousewheel
	set up the following custom action and bind it to the mousweheel:
	
	Custom: Move edit cursor by grid division size (relative)
		Action: Skip next action if CC parameter >0/mid
		BuyOne_Move edit cursor left by grid division size (relative).lua
		Action: Skip next action if CC parameter <0/mid
		BuyOne_Move edit cursor right by grid division size (relative).lua
		
	This custom action implies the following scrolling direction: 
	forwards/out/up - right, backwards/in/down - left
	To reverse the direction swap the order of the scripts within
	the custom action sequence without swapping the order of the
	native actions.
			
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character
-- between the quotes to have the script create
-- an undo point for each cursor movement
UNDO = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only display output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
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

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

local left, right = scr_name:match('left'), scr_name:match('right')
local cur_pos = r.GetCursorPosition()
local distance = r.GetToggleCommandStateEx(0, 41885) == 0 and Grid_Div_Dur_In_Sec() -- Grid: Toggle framerate grid
or 1/r.TimeMap_curFrameRate(0) -- frame duration doesn't depend on the tempo, 1 because the rate is per second
local err = not left and not right and '\t  the script name \n\n\tis not recognized, \n\n restore its original name'
or r.GetToggleCommandStateEx(0, 40145) == 0 and 'grid is disabled' -- Options: Toggle grid lines
or left and (cur_pos == 0 or cur_pos - distance < 0) and '\tcannot move \n\n beyond project start'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

UNDO = #UNDO:gsub(' ','') > 0

	if UNDO then r.Undo_BeginBlock() end

r.SetEditCurPos(cur_pos + (left and distance*-1 or distance), true, false) -- moveview true, seekplay false

	if UNDO then r.Undo_EndBlock(scr_name, -1)
	else
	return r.defer(no_undo)
	end





