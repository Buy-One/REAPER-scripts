--[[
ReaScript name: BuyOne_Scroll horizontally with variable speed.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Added means to prevent scrolling beyond project end
	   v1.1 #Added support for fractional beats
Licence: WTFPL
REAPER: at least v5.962
About: 	Alternative to the native 'View: Scroll horizontally (MIDI CC relative/mousewheel)' 
	action which scrolls by exactly 122 px regardless of the zoom level.
	   
	Bind to mousewheel (optionally with modifiers).  
	   
	With vertical mousewheel the default direction is up - right, down - left,
	to reverse the direction enable MW_REVERSE setting in the USER SETTINGS

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
-- setting is enabled) per single mousewheel nudge,
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


function Mouse_Wheel_Direction(mousewheel_reverse) -- mousewheel_reverse is boolean
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = r.get_action_context() -- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards
	if mousewheel_reverse then
	return val > 0 and -1 or val < 0 and 1 -- wheel up (forward) - leftwards/downwards or wheel down (backwards) - rightwards/upwards
	else -- default
	return val > 0 and 1 or val < 0 and -1 -- wheel up (forward) - rightwards/upwards or wheel down (backwards) - leftwards/downwards
	end
end


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
local dir = Mouse_Wheel_Direction(MW_REVERSE)
local right = MW_REVERSE and dir < 0 or dir > 0

	if right and end_time-vert_scrollbar_w_sec >= proj_len then SPEED = 0 -- accounting for vertical scrollbar which is included in the Arrange view length and is 17 px wide although here it's not really necessary due to the size of scroll step
	Error_Tooltip('\n\n end of ptoject reached \n\n', 1, 1) -- caps and spaced are true
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

r.CSurf_OnScroll(SPEED*dir, 0)



