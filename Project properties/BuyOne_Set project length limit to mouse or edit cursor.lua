--[[
ReaScript name: BuyOne_Set project length limit to mouse or edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
Provides: [main=main,midi_editor] .
About:	The script allows enabling and setting Project length limit
    		for the current project optionally placing a marker signifying
    		the limit on the time line.  
    		
    		If the mouse cursor doesn't hover directly over the Arrange
    		the edit cursor position will be the target position instead,
    		unless it hovers over a Mixer track.
    		This allows running the script from a toolbar button, a menu item,
    		from the Action list and when the mouse cursor is outside of the 
    		Arrange.
    		
    		Since REAPER build 7.16 project length limit is indicated with a 
    		STOP icon in the Ruler but the icon cannot be dragged to change 
    		the setting.
    		So the script can be useful in both earlier and later builds.
    
    		If the setting INSERT_PROJ_LIMIT_MARKER was disabled after the 
    		project length limit marker was inserted, the marker will be 
    		removed because otherwise it will be misleading.
    		
    		To bake the new setting in the project file the project must be
    		saved therefore it's advised to use the script as part of a custom
    		action:
    		
    			BuyOne_Set project length limit to mouse or edit cursor.lua
    			File: Save project

]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character
-- between the quotes to have the script place
-- a project marker at the time point set to be
-- the project length limit
INSERT_PROJ_LIMIT_MARKER = "1"

-- Project length limit marker name, if empty
-- defaults to '*** PROJECT LIMIT ***'
MARKER_NAME = ""

-- Insert HEX color code between the quotes
-- e.g. "#000000",
-- shortened color format, e.g. "#000", is supported,
-- the preceding hash sign is optional;
-- if no or invalid color code is supplied the theme
-- current default marker color set in the 'Theme development/tweaker'
-- dialogue will be used
MARKER_HEX_COLOR = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub('[%s%c]','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub('[%s%c]','') > 0 or type(sett) == 'number'
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Center_Message_Text(mess, spaced)
-- to be used before Error_Tooltip()
-- spaced is boolean, must be true if the same argument is true in  Error_Tooltip()
local t, max = {}, 0
	for line in mess:gmatch('[^%c]+') do
		if line then
		t[#t+1] = line
		max = #line > max and #line or max
		end
	end
local coeff = spaced and 1.5 or 2 -- 1.5 seems to work when the text is spaced out inside Error_Tooltip(), otherwise 2 needs to be used
	for k, line in ipairs(t) do
	local shift = math.floor((max - #line)/2*coeff+0.5)
	local lb = k < #t and '\n\n' or ''
	t[k] = (' '):rep(shift)..line..lb
	end
return table.concat(t)
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


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','')
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return '0'
	end
return c
end


function Get_Mouse_Pos_Sec(want_over_arrange, want_snapping)

	if want_over_arrange and not r.GetTrackFromPoint(r.GetMousePosition()) -- look for the mouse cursor pos // GetTrackFromPoint() prevents getting mouse position if the script is run from a toolbar or the Action list window floating over Arrange or if mouse cursor is outside of Arrange because in this case GetTrackFromPoint() returns nil; usually in this case the script should fall back on getting edit cursor position; this condition doesn't apply to mouse over a Mixer track
	then return end

local comm_id = want_snapping and 40513 -- View: Move edit cursor to mouse cursor
or 40514 -- View: Move edit cursor to mouse cursor (no snapping)
r.PreventUIRefresh(1)
local cur_pos = r.GetCursorPosition() -- store current edit cur pos
r.Main_OnCommand(comm_id,0)
local mouse_pos = r.GetCursorPosition()
r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore edit cur pos
r.PreventUIRefresh(-1)
return mouse_pos
end


	if not r.SNM_SetDoubleConfigVar then
	Error_Tooltip('\n\nthe script requires sws/s&m extension.', 1, 1, -200) -- caps, spaced true, x2 -200
	return r.defer(no_undo) end


local mouse_pos = Get_Mouse_Pos_Sec(1) -- want_over_arrange 1 true, ignores mouse cursor not directly over the Arrange
local curs_pos = mouse_pos or r.GetCursorPosition()

	if curs_pos == 0 then
	local err = mouse_pos and 'the cursor is either outside \n\n\tof the Arrange area'
	..'\n\n\t or at position 0.0 \n\n\t  which is invalid' or 'position 0.0 is invalid'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200) -- caps, spaced true, x2 -200
	return r.defer(no_undo) end


INSERT_PROJ_LIMIT_MARKER = validate_sett(INSERT_PROJ_LIMIT_MARKER)
MARKER_NAME = #MARKER_NAME:gsub('[%s%c]','') > 0 and MARKER_NAME or '*** PROJECT LIMIT ***'
local MARKER_COLOR = Validate_HEX_Color_Setting(MARKER_HEX_COLOR)
MARKER_COLOR = MARKER_COLOR ~= '0' and r.ColorToNative(table.unpack{hex2rgb(MARKER_COLOR)})
or r.GetThemeColor('marker', 0) -- default to theme current default marker color, the one displayed in the 'Theme development/tweaker' window, not necessarily the one set in the .ReaperTheme file; modified color settings are stored in reaper.ini

r.SNM_SetDoubleConfigVar('projmaxlen', curs_pos) -- set the value
r.SNM_SetDoubleConfigVar('projmaxlenuse', 1) -- enable checkbox

-- search for a pre-existing marker
local i, mrkr_idx = 0
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
		if not isrgn and name:match('^%s*(.-)%s*$') == MARKER_NAME then -- previously placed marker
		mrkr_idx = idx
		break end
	i=i+1
	until retval == 0


	if INSERT_PROJ_LIMIT_MARKER then
		if mrkr_idx then -- pre-existing marker
		r.SetProjectMarker3(0, mrkr_idx, false, curs_pos, 0, MARKER_NAME, MARKER_COLOR|0x1000000) -- isrgn false, rgnend 0, setting color in case it was changed
		else -- no pre-existing marker
		r.AddProjectMarker2(0, false, curs_pos, 0, MARKER_NAME, -1, MARKER_COLOR|0x1000000) -- isrgn false, rgnend 0, wantidx -1 to set index automatically
		end
	elseif mrkr_idx then -- INSERT_PROJ_LIMIT_MARKER setting was disabled after marker had been added, remove it
	r.DeleteProjectMarker(0, mrkr_idx, false) -- isrgn false
	Error_Tooltip('\n\n new project limit has been set. \n\n\tthe project limit marker \n\n'
	..'\t     has been deleted. \n\n', 1, 1, -200) -- caps, spaced true, x2 -200
	end

do return r.defer(no_undo) end -- prevent undo point creation




