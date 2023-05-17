--[[
ReaScript name: BuyOne_Scroll horizontally with variable speed.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
About: Alternative to the native 'View: Scroll horizontally (MIDI CC relative/mousewheel)' 
       action which scrolls by exactly 122 px regardless of the zoom level.

       The script's scroll unit is 16 px per execution which 
       can be increased with the SPEED setting in the USER SETTINGS.

       Bind to mousewheel (optionally with modifiers).  

       With vertical mousewheel the default direction is up - right, down - left,
       to reverse the direction enable MW_REVERSE setting in the USER SETTINGS

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert integer (whole number) between the quotes;
-- empty or invalid defaults to 16 px per one script execution,
-- otherwise the value is used as a factor
-- by which the default value (16 px) is multiplied
SPEED = ""

-- Enable by placing any alphanumeric character between the quotes,
-- only relevant for SPEED setting above,
-- if enabled, the numeric value of the SPEED setting becomes
-- the number of beats to scroll by rather than a factor
-- to multiply pixels by, empty SPEED setting in this case equals 1;
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


function Get_Arrange_Len_In_Pixels()
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start & screen_x_end both 0 = GET // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true // THE TIME INCLUDES VERTICAL SCROLLBAR 17 px wide which will have to be subtracted to get the exact right edge of the time line
--return math.floor((end_time-start_time)*r.GetHZoomLevel()+0.5) -- GetHZoomLevel() returns px/sec; return rounded since fractional pixel values are invalid
return (end_time-start_time)*r.GetHZoomLevel() -- no need to round as it will be rounded outside anyway
end


function Beat_To_Pixels()
return math.floor(60/r.Master_GetTempo()*r.GetHZoomLevel()+0.5) -- GetHZoomLevel() returns px/sec; return rounded since fractional pixel values are invalid
end


function Mouse_Wheel_Direction(val, mousewheel_reverse) -- mousewheel_reverse is boolean
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = r.get_action_context() -- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards
	if mousewheel_reverse then
	return val > 0 and -1 or val < 0 and 1 -- wheel up (forward) - leftwards/downwards or wheel down (backwards) - rightwards/upwards
	else -- default
	return val > 0 and 1 or val < 0 and -1 -- wheel up (forward) - rightwards/upwards or wheel down (backwards) - leftwards/downwards
	end
end


SPEED = (not tonumber(SPEED) or tonumber(SPEED) and SPEED+0 == 0) and 1 or math.floor(math.abs(tonumber(SPEED))) -- ignoring non-numerals, zero, any decimal and negative values
BY_BEATS = #BY_BEATS:gsub(' ','') > 0
PAGING_SCROLL = #PAGING_SCROLL:gsub(' ','') > 0
MW_REVERSE = #MW_REVERSE:gsub(' ','') > 0

	if PAGING_SCROLL then
	SPEED = math.floor((Get_Arrange_Len_In_Pixels()-17)/16+0.5) -- /16 since its the smallest horiz scroll unit used by CSurf_OnScroll() below, 1 equals 16, round since pixel value cannot be fractional; 17 is the width of vertical scrollbar
	elseif BY_BEATS then
	local arrange_len = Get_Arrange_Len_In_Pixels()
	local step_len = Beat_To_Pixels()*SPEED
		if arrange_len/step_len < 6 then -- for ease of following the time line make sure that the arrange length equals at least 6 steps, dividing the step length until the desired resolution is achieved, this makes scrolling gradual and traceable enough
			while arrange_len/step_len < 6 do
			step_len = step_len/2
			end
		end
	local step_len = math.floor(step_len/16+0.5)
	SPEED = step_len < 1 and 1 or step_len -- at extreme zoom-out make sure that the value never falls lower than 1, which equals 16 px in terms of CSurf_OnScroll() function as it ignores lower values
	end


local dir = Mouse_Wheel_Direction(val, MW_REVERSE)

r.CSurf_OnScroll(SPEED*dir, 0)




