--[[
ReaScript name: BuyOne_Scroll left with variable speed.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.3
Changelog: v1.3 #Corrected typo in the end of project tooltip
	   v1.2 #Added means to prevent scrolling beyond project end
	   v1.1 #Added support for fractional beats
Licence: WTFPL
REAPER: at least v5.962
About: Alternative to the native 'View: Scroll view left' action
       which scrolls by exactly 488 px regardless of the zoom level.

       Bind to left arrow key (optionally with modifiers).

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert a number between the quotes,
-- when BY_BEATS setting is enabled below, both integers (whole numbers)
-- and decimal numbers are supported, numbers less than 1 will shorten
-- 1 beat: 0.5 to half (= 1/8), 0.75 to 3/4th (= 1/8 dotted), 
-- 0.25 to 1/4th (= 1/16) etc., non-musical divisions and values 
-- in the format of '1/2' are supported as well;
-- when BY_BEATS setting isn't enabled only integers are supported;
-- empty or invalid defaults to either 16 px or 1 beat (if BY_BEATS
-- setting is enabled) per one script execution,
-- otherwise the value is used as a factor
-- by which the default value (16 px or 1 beat) is multiplied
SPEED = ""

-- Enable by placing any alphanumeric character between the quotes,
-- only relevant for SPEED setting above,
-- if enabled, the numeric value of the SPEED setting becomes
-- the number of beats to scroll by rather than a factor
-- to multiply pixels by, empty or invalid SPEED setting 
-- in this case equals 1;
-- doesn't have any effect if PAGING_SCROLL setting is enabled below;
-- at higher zoom-in levels scroll step (beat * SPEED) is reduced
-- to ensure slower scrolling for ease of following the time line
BY_BEATS = ""

-- Alternative to the native
-- View: Scroll view horizontally one page (MIDI CC relative/mousewheel)
-- which only scrolls by about half of the Arrange width;
-- if enabled by placing any alphanumeric character
-- between the quotes, disables SPEED value and instead
-- makes the script scroll by the visible Arrange width;
-- basically the same as the native
PAGING_SCROLL = ""

-- Reverse the default mousewheel direction,
-- to enable insert any alphanumeric character between the quotes
MW_REVERSE = ""

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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Invalid_Script_Name(scr_name,...)
-- check if necessary elements are found in script name and return the one found
-- only execute once
local t = {...}

	for k, elm in ipairs(t) do
		if scr_name:match(Esc(elm)) then return elm end -- at least one match was found
	end

	local function Rep(n) -- number of repeats, integer
	return (' '):rep(n)
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


local is_new_value,scr_name,sectID,cmdID,mode,resol,val = r.get_action_context()

local keyword = Invalid_Script_Name(scr_name,' right ',' left ')
	if not keyword then return r.defer(no_undo) end

local right, left = keyword == ' right ', keyword == ' left '

BY_BEATS = #BY_BEATS:gsub(' ','') > 0
local a,b = SPEED:match('(%d+)/(%d+)')
SPEED = BY_BEATS and a and b and a/b or SPEED
SPEED = (not tonumber(SPEED) or tonumber(SPEED) and SPEED+0 == 0 or not BY_BEATS and SPEED:match('%.')) and 1 or BY_BEATS and math.abs(SPEED) or math.floor(math.abs(SPEED)) -- ignoring non-numerals, zero, decimals when beats aren't enabled and negative values // negative numerals math.floor rounds down to a greater natural number, -1.1 is rounded down to -2
PAGING_SCROLL = #PAGING_SCROLL:gsub(' ','') > 0
MW_REVERSE = #MW_REVERSE:gsub(' ','') > 0

local proj_len = r.GetProjectLength(0)
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start & screen_x_end both 0 = GET // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true // THE TIME INCLUDES VERTICAL SCROLLBAR 17 px wide which will have to be subtracted to get the exact right edge of the time line
local vert_scrollbar_w_sec = 17/r.GetHZoomLevel() -- in sec; vertical scrollbar which is included in the Arrange view length, is 17 px wide and must be subtracted to get true visible area size
local arrange_len_in_px = (end_time-start_time)*r.GetHZoomLevel()-17 -- 17 px is the width of vertical scrollbar included in the Arrange view length which must be subtracted to get true visible area size

	if right and end_time-vert_scrollbar_w_sec >= proj_len then SPEED = 0 -- accounting for vertical scrollbar which is included in the Arrange view length and is 17 px wide
	Error_Tooltip('\n\n end of project reached \n\n', 1, 1) -- caps and spaced are true
	elseif PAGING_SCROLL then
	SPEED = math.floor(arrange_len_in_px/16+0.5) -- /16 since its the smallest horiz scroll unit used by CSurf_OnScroll() below, 1 equals 16, round since pixel value cannot be fractional;
	elseif BY_BEATS then
	local beat_len_in_sec = 60/r.Master_GetTempo()*SPEED
	local step_len_in_px = beat_len_in_sec*r.GetHZoomLevel() -- GetHZoomLevel() returns px/sec
		if arrange_len_in_px/step_len_in_px < 6 then -- for ease of following the time line make sure that the arrange length equals at least 6 steps, dividing the step length until the desired resolution is achieved, this makes scrolling gradual and traceable enough
			while arrange_len_in_px/step_len_in_px < 6 do
			step_len_in_px = step_len_in_px/2
			end
		end
	local step_len_in_px = math.floor(step_len_in_px/16+0.5)
	SPEED = step_len_in_px < 1 and 1 or step_len_in_px -- at extreme zoom-out make sure that the value never falls lower than 1, which equals 16 px in terms of CSurf_OnScroll() function as it ignores lower values
	end

local dir = right and 1 or left and -1
r.CSurf_OnScroll(SPEED*dir, 0)
