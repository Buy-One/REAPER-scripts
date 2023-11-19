--[[
ReaScript name: BuyOne_Color ruler depending on play-record mode.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is supposed to run in the background monitoring
    		play/record mode and coloring the ruler to indicate currently
    		active mode according to the USER SETTINGS below.
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Insert color codes in HEX format between the quotes;
-- if any of the colors isn't set, no change in color
-- will occur in the corresponding mode;
-- font color settings have beed added because not all font
-- and background colors mix well,
-- against colored background black font color (hex 000000) seems optimal

-- Play modes
PLAY_COLOR = ""
PLAY_FONT_COLOR = ""
PLAY_PAUSE_COLOR = ""
PLAY_PAUSE_FONT_COLOR = ""

-- Record modes
RECORD_NORMAL_COLOR = ""
RECORD_NORMAL_FONT_COLOR = ""
RECORD_NORMAL_PAUSE_COLOR = ""
RECORD_NORMAL_PAUSE_FONT_COLOR = ""

TIME_SEL_AUTOPUNCH_COLOR = ""
TIME_SEL_AUTOPUNCH_FONT_COLOR = ""
TIME_SEL_AUTOPUNCH_REC_PAUSE_COLOR = ""
TIME_SEL_AUTOPUNCH_REC_PAUSE_FONT_COLOR = ""

AUTOPUNCH_SEL_ITEMS_COLOR = ""
AUTOPUNCH_SEL_ITEMS_FONT_COLOR = ""
AUTOPUNCH_SEL_ITEMS_REC_PAUSE_COLOR = ""
AUTOPUNCH_SEL_ITEMS_REC_PAUSE_FONT_COLOR = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
local hex = HEX_COLOR:sub(2) -- trimming leading '#'
return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function Convert_HEX_Color_Setting(HEX_COLOR, color_init)

local HEX_COLOR = type(HEX_COLOR) == 'string' and HEX_COLOR:gsub('%s','') -- remove empty spaces just in case

--[[ default to original color black if color is improperly formatted
local HEX_COLOR = (not HEX_COLOR or type(HEX_COLOR) ~= 'string' or HEX_COLOR == '' or #HEX_COLOR < 4 or #HEX_COLOR > 7) and '#000' or HEX_COLOR
]]

-- alternative to defaulting to black color above, return original color setting if HEX_COLOR var is malformed
local HEX_COLOR = type(HEX_COLOR) == 'string' and #HEX_COLOR >= 4 and #HEX_COLOR <= 7 and HEX_COLOR
--	if not HEX_COLOR then return color_init end
	if not HEX_COLOR then return -1 end -- -1 to set to theme's default color with SetThemeColor() as color arg, so color_init arg of this Convert_HEX_Color_Setting() function isn't used

-- extend shortened (3 digit) hex color code, duplicate each digit
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or not HEX_COLOR:match('^#') and '#'..HEX_COLOR or HEX_COLOR -- adding '#' if absent
-- return HEX_COLOR -- TO USE THE RETURN VALUE AS ARG IN hex2rgb() function UNLESS IT'S INCLUDED IN THIS ONE AS FOLLOWS
local R,G,B = hex2rgb(HEX_COLOR)
return r.ColorToNative(R,G,B)

end


function SetColors(ruler_col, font_col)
SetColor('col_tl_bg', ruler_col, 0)
SetColor('col_tl_fg', font_col, 0)
SetColor('col_tl_fg2', font_col, 0)
r.UpdateTimeline()
end


function Restore_Orig_Colors()
r.SetThemeColor('col_tl_bg', -1, 0) -- -1 to set to theme's default color
SetColor('col_tl_fg', -1, 0)
SetColor('col_tl_fg2', -1, 0)
r.UpdateTimeline()
end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state, restore_colors) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination // restore_colors is boolean
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
	if restore_colors then
	Restore_Orig_Colors()
	end
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function COLOR_RULER()
-- is_set ensures that within the defer loop update only occurs once, otherwise the color will flicker
	if not is_set
	or is_set and r.GetPlayState() > 0 and r.GetPlayState() ~= is_set then -- after stop or when play state has changed
	local playstate = r.GetPlayState()
	local plays, paused, records = playstate&1 == 1, playstate&2 == 2, playstate&4 == 4
		if plays and not records -- plays but doesn't record, recording requires evaluation because play and record flags are set at the same time
		then
		SetColors(PLAY_COLOR, PLAY_FONT_COLOR)
		is_set = playstate
		elseif paused and not records -- play pause, recording is off, recording requires evaluation because pause and record flags are set at the same time
		then
		SetColors(PLAY_PAUSE_COLOR, PLAY_PAUSE_FONT_COLOR)
		is_set = playstate
		elseif records then -- recording
		local normal = GetToggleState(0, 40252) == 1 -- Record: Set record mode to normal
		local time_sel_autopunch = GetToggleState(0, 40076) == 1 -- Record: Set record mode to time selection auto-punch
		local sel_itms_autopunch = GetToggleState(0, 40253) == 1 -- Record: Set record mode to selected item auto-punch
			if paused then -- record paused
			local ruler_color = normal and RECORD_NORMAL_PAUSE_COLOR or time_sel_autopunch and TIME_SEL_AUTOPUNCH_REC_PAUSE_COLOR
			or sel_itms_autopunch and AUTOPUNCH_SEL_ITEMS_REC_PAUSE_COLOR
			local font_color = normal and RECORD_NORMAL_PAUSE_FONT_COLOR or time_sel_autopunch and TIME_SEL_AUTOPUNCH_REC_PAUSE_FONT_COLOR or sel_itms_autopunch and AUTOPUNCH_SEL_ITEMS_REC_PAUSE_FONT_COLOR
			SetColors(ruler_color, font_color)
			elseif normal then
			SetColors(RECORD_NORMAL_COLOR, RECORD_NORMAL_FONT_COLOR)
			elseif time_sel_autopunch then
			SetColors(TIME_SEL_AUTOPUNCH_COLOR, TIME_SEL_AUTOPUNCH_FONT_COLOR)
			elseif sel_itms_autopunch then
			SetColors(AUTOPUNCH_SEL_ITEMS_COLOR, AUTOPUNCH_SEL_ITEMS_FONT_COLOR)
			end
		is_set = playstate
		end
	elseif is_set and r.GetPlayState() == 0 then -- stopped
	SetColors(-1, -1) -- -1 set to theme's default
	is_set = nil
	end

r.defer(COLOR_RULER)

end

SetColor, GetToggleState = r.SetThemeColor, r.GetToggleCommandStateEx

PLAY_COLOR = Convert_HEX_Color_Setting(PLAY_COLOR)
PLAY_FONT_COLOR = Convert_HEX_Color_Setting(PLAY_FONT_COLOR)
PLAY_PAUSE_COLOR = Convert_HEX_Color_Setting(PLAY_PAUSE_COLOR)
PLAY_PAUSE_FONT_COLOR = Convert_HEX_Color_Setting(PLAY_PAUSE_FONT_COLOR)

RECORD_NORMAL_COLOR = Convert_HEX_Color_Setting(RECORD_NORMAL_COLOR)
RECORD_NORMAL_FONT_COLOR = Convert_HEX_Color_Setting(RECORD_NORMAL_FONT_COLOR)
RECORD_NORMAL_PAUSE_COLOR = Convert_HEX_Color_Setting(RECORD_NORMAL_PAUSE_COLOR)
RECORD_NORMAL_PAUSE_FONT_COLOR = Convert_HEX_Color_Setting(RECORD_NORMAL_PAUSE_FONT_COLOR)
TIME_SEL_AUTOPUNCH_COLOR = Convert_HEX_Color_Setting(TIME_SEL_AUTOPUNCH_COLOR)
TIME_SEL_AUTOPUNCH_FONT_COLOR = Convert_HEX_Color_Setting(TIME_SEL_AUTOPUNCH_FONT_COLOR)
TIME_SEL_AUTOPUNCH_REC_PAUSE_COLOR = Convert_HEX_Color_Setting(TIME_SEL_AUTOPUNCH_REC_PAUSE_COLOR)
TIME_SEL_AUTOPUNCH_REC_PAUSE_FONT_COLOR = Convert_HEX_Color_Setting(TIME_SEL_AUTOPUNCH_REC_PAUSE_FONT_COLOR)
AUTOPUNCH_SEL_ITEMS_COLOR = Convert_HEX_Color_Setting(AUTOPUNCH_SEL_ITEMS_COLOR)
AUTOPUNCH_SEL_ITEMS_FONT_COLOR = Convert_HEX_Color_Setting(AUTOPUNCH_SEL_ITEMS_FONT_COLOR)
AUTOPUNCH_SEL_ITEMS_REC_PAUSE_COLOR = Convert_HEX_Color_Setting(AUTOPUNCH_SEL_ITEMS_REC_PAUSE_COLOR)
AUTOPUNCH_SEL_ITEMS_REC_PAUSE_FONT_COLOR = Convert_HEX_Color_Setting(AUTOPUNCH_SEL_ITEMS_REC_PAUSE_FONT_COLOR)

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol,val = r.get_action_context()

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

COLOR_RULER()

-- ensures that the original color is restored if the script is terminated during play mode which won't allow it to be restored inside the defer loop
r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0, true)) -- restore_colors is true to trigger Restore_Orig_Colors() inside Re_Set_Toggle_State()









