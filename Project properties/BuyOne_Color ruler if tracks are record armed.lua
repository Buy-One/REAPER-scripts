--[[
ReaScript name: BuyOne_Color ruler if tracks are record armed.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is supposed to run in the background monitoring
      	record arm state of tracks to color the ruler when any of them
	becomes record armed as long as REAPER doesn't record.  
	While the script is running it reports On toggle state 
	so if it's linked to the toolbar button or a menu item these 
	will reflect the current toggle state.  
	For color and additional settings refer to the USER SETTING
	below.
		
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Insert color codes in HEX format between the quotes;
-- If RULER_COLOR isn't set or malformed an error message will me thrown,
-- if FONT_COLOR isn't set, no change in color will occur;
-- font color setting has beed added because not all font
-- and background colors mix well,
-- against colored background black font color (hex 000000) seems optimal
-- default ruler color is red (FF0000)

RULER_COLOR = "FF0000"
FONT_COLOR = "000000"

-- Insert between the quotes a value in seconds
-- to enable blinking color change with the specified frequency;
-- if the setting is not empty but malformed defaults to 0.3 (300 ms)
-- which seems optimal, not very annoying,
-- so if you find this frequency suitable, to enable the setting
-- any non-numeral can be used
BLINK = ""

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
	if not HEX_COLOR then return -1 end -- -1 to throw an error for RULER_COLOR and to set FONT_COLOR to theme's default color with SetThemeColor(), color_init arg of this Convert_HEX_Color_Setting() function isn't used

-- extend shortened (3 digit) hex color code, duplicate each digit
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or not HEX_COLOR:match('^#') and '#'..HEX_COLOR or HEX_COLOR -- adding '#' if absent
-- return HEX_COLOR -- TO USE THE RETURN VALUE AS ARG IN hex2rgb() function UNLESS IT'S INCLUDED IN THIS ONE AS FOLLOWS
local R,G,B = hex2rgb(HEX_COLOR)
return r.ColorToNative(R,G,B)

end


function SetColors(ruler_col, font_col)
SetColor('col_tl_bg', ruler_col, 0) -- Timeline background, ruler
SetColor('col_tl_fg', font_col, 0) -- Timeline foreground, ruler text
SetColor('col_tl_fg2', font_col, 0) -- Timeline foreground (secondary markings), ruler text
r.UpdateTimeline()
end


function Restore_Orig_Colors()
--r.SetThemeColor('col_tl_bg', color_init, 0)
SetColor('col_tl_bg', -1, 0) -- Timeline background, ruler // -1 to set to theme's default color
SetColor('col_tl_fg', -1, 0) -- Timeline foreground, ruler text
SetColor('col_tl_fg2', -1, 0) -- Timeline foreground (secondary markings), ruler text
r.UpdateTimeline()
end


function Is_Track_Record_Armed()
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local retval, flags = r.GetTrackState(tr)
		if flags&64 == 64 then return 1 end -- record armed
	end
end


function Blink(ruler_col, font_col, orig_col_t)
local cur_rul_col = GetColor('col_tl_bg', 0) -- Timeline background, ruler // get current color
local cur_font_col_fg = GetColor('col_tl_fg', 0) -- Timeline foreground and background, ruler text
cur_rul_col = cur_rul_col ~= ruler_col and ruler_col or orig_col_t.rul_col
cur_font_col_fg = cur_font_col_fg ~= font_col and font_col or orig_col_t.font_col_fg
SetColors(cur_rul_col, cur_font_col_fg)
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
	if not is_set and Is_Track_Record_Armed() and r.GetPlayState()&4 ~= 4 then
	SetColors(RULER_COLOR, FONT_COLOR)
	is_set = r.time_precise()
	elseif is_set and (r.GetPlayState()&4 == 4 or not Is_Track_Record_Armed()) then -- records or not records and no armed tracks
	SetColors(-1, -1) -- -1 set to theme's default
	is_set = nil
	elseif is_set and BLINK and r.time_precise()-is_set >= BLINK then
	Blink(RULER_COLOR, FONT_COLOR, orig_col_t)
	is_set = r.time_precise()
	end

r.defer(COLOR_RULER)

end

GetColor, SetColor, GetToggleState = r.GetThemeColor, r.SetThemeColor, r.GetToggleCommandStateEx

RULER_COLOR = Convert_HEX_Color_Setting(RULER_COLOR)
	if RULER_COLOR == -1 then
	Error_Tooltip('\n\n no color has been set \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

FONT_COLOR = Convert_HEX_Color_Setting(FONT_COLOR)
BLINK = BLINK:gsub(' ','')
BLINK = #BLINK > 0 and (tonumber(BLINK) or 0.3) -- default to 0.3 if malformed

orig_col_t = {}
local set = 0xFFFF
orig_col_t.rul_col = GetColor('col_tl_bg', set) -- Timeline background, ruler // set low 16 (right) bits to get original color
orig_col_t.font_col_fg = GetColor('col_tl_fg', set) -- Timeline foreground, ruler text
orig_col_t.font_col_fg2 = GetColor('col_tl_fg2', set) -- Timeline foreground (secondary markings), ruler text

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol,val = r.get_action_context()

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)


COLOR_RULER()

-- ensures that the original color is restored if the script is terminated which won't allow it to be restored inside the defer loop
r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0, true)) -- restore_colors is true to trigger Restore_Orig_Colors() inside Re_Set_Toggle_State()


