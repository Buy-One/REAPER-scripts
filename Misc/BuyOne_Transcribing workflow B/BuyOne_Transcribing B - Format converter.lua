--[[
ReaScript name: BuyOne_Transcribing B - Format converter.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing B workflow set of scripts
			alongside  
			BuyOne_Transcribing B - Create and manage segments (MAIN).lua  
			BuyOne_Transcribing B - Real time preview.lua  
			BuyOne_Transcribing B - Import SRT or VTT file as markers and SWS track Notes.lua  
			BuyOne_Transcribing B - Prepare transcript for rendering.lua  
			BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
			BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
			BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua
			
			meant to format and export a transcript created with the script 
			BuyOne_Transcribing B - Create and manage segments.lua			
			
			SRT and VTT formats conversion is very basic. Conversion into
			the VTT format is more basic than possible with Transcription 1
			script set, meaning that no metadata is supported.  	
				
			The formatted transcript is dumped to a .srt, .vtt or .txt file 
			named after the project file which will be placed in the project 
			directory. The dialogue will guide you through the process. The 
			dialogue options respond to keyboard input, options 1 through 3 
			to keys 1 - 3, .SRT - S, .VTT - V, and AS IS - A. 
			
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes specify HEX color either preceded
-- or not with hash # sign, can consist of only 3 digits
-- if they're are repeated, i.e. #0fc;
-- MUST DIFFER FROM THE THEME DEFAULT REGION COLOR
-- AND MATCH THE SAME SETTING IN THE SCRIPT
-- 'BuyOne_Transcribing B - Create and manage segments (MAIN).lua'
SEGMENT_REGION_COLOR = "#b564a6"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
end



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return
	end
return c
end


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest appearence of a particular character in the menu can be used as a shortcut
-- in this case they don't have to be preceded with ampersand '&'
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest appearance in the menu
-- some characters still do need ampresand, e.g. < and >

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
-- therefore enabled with keep_menu_open is valid
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
-- screen reader used by blind users with OSARA extension may be affected
-- by the absence if the gfx window therefore only disable it in builds
-- newer than 6.82 if OSARA extension isn't installed
-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
local init = (old or OSARA or not old and not OSARA and keep_menu_open) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if keep_menu_open is enabled the menu opens every time at the same spot
		if keep_menu_open and not coord_t then -- keep_menu_open is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not keep_menu_open then
		coord_t = nil
		end

	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y

	return gfx.showmenu(menu) -- menu string

	end

end



function format_time_stamp(pos) -- format by adding leading zeros because r.format_timestr() ommits them
local stamp = r.format_timestr(pos, '')
return pos/3600 >= 1 and (pos/3600 < 10 and '0'..stamp or stamp) -- with hours
or pos/60 >= 1 and (pos/60 < 10 and '00:0'..stamp or '00:'..stamp) -- without hours
or '00:0'..stamp -- without hours and minutes
end



function Get_Transcript(reg_color)

local i, t = 0, {}
local cnt = i
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
		if retval > 0 and isrgn and color == reg_color then
		local space = #name:gsub('[%s%c]','') > 0 and ' ' or ''
		t[#t+1] = format_time_stamp(pos)..' '..format_time_stamp(rgnend)..space..name
		cnt = #space > 0 and cnt+1 -- count segment regions with text
		end
	i = i+1
	until retval == 0

return t, cnt

end



function Format(transcr_t, mode, skip_empty_segm, incl_end_time, remove_timecode)
-- https://docs.fileformat.com/ru/video/srt/
-- https://docs.fileformat.com/video/srt/
-- https://en.wikipedia.org/wiki/SubRip
-- https://ale5000.altervista.org/subtitles.htm
-- https://www.w3.org/wiki/VTT_Concepts
-- https://www.w3.org/TR/webvtt1/
-- https://w3c.github.io/webvtt.js/parser.html VALIDATOR
-- https://github.com/1c7/vtt-test-file/tree/master/vtt%20files
-- https://www.simultrans.com/blog/what-is-a-vtt-file


local SRT = mode == 1
local VTT = mode == 2

-- 1. Remove segments with no text; must be run in a separate loop to then be able to apply sequential indices to segments if SRT/VTT format is selected (in VTT format indices aren't required though)

	if skip_empty_segm then
		for i = #transcr_t,1,-1 do
		local line = transcr_t[i]
		local st, fin, txt = line:match('^(%d+:%d+:%d+%.%d+) ([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
			if not txt or txt and #txt:gsub('[%s%c]','') == 0 then -- segment without text
			table.remove(transcr_t, i)
			end
		end
	end

-- 2. Format Notes

	for k, line in ipairs(transcr_t) do
	local st, fin, txt = line:match('^(%d+:%d+:%d+%.%d+) ([:%d%.]+)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
	txt = txt and txt:match('%S.*') or '' -- trimming leading space from the text
		if SRT or VTT then
		transcr_t[k] = k..'\n'..(VTT and st or st:gsub('%.',','))..' --> '
		..(VTT and fin or fin:gsub('%.',','))..'\n'..txt:gsub('%s*<n>%s*','\n')
		..(#txt:gsub('[%s%c]','') > 0 and '\n\n' or '\n') -- replacing the ms decimal dot with comma to conform to SRT format, replacing new line tag and surrounding spaces, if any, with new line control character, adding trailing empty line to separate segments as per the format but preventing double empty line in cases where the segment text is empty
		else -- AS IS
		transcr_t[k] = (remove_timecode and '' or st..(incl_end_time and ' '..fin or '')..' ')
		..txt:gsub('%s*<n>%s*',' ')..'\n' -- replacing new line tags and surrounding spaces, if any, with single space
		end
	end

return (VTT and 'WEBVTT\n\n' or '')..table.concat(transcr_t, '')

end



function spaceout(str)
return str:gsub('.','%0 ')
end


REG_COLOR = Validate_HEX_Color_Setting(SEGMENT_REGION_COLOR)

local err = 'the segment_region_color \n\n'
err = #SEGMENT_REGION_COLOR:gsub(' ','') == 0 and err..'\t  setting is empty'
or not REG_COLOR and err..'\t setting is invalid'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local theme_reg_col = r.GetThemeColor('region', 0)
REG_COLOR = r.ColorToNative(table.unpack{hex2rgb(REG_COLOR)})

	if REG_COLOR == theme_reg_col then
	Error_Tooltip("\n\n the segment_region_color \n\n\tsetting is the same\n\n"
	.."    as the theme's default\n\n     which isn't suitable\n\n\t   for the script \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

REG_COLOR = REG_COLOR|0x1000000 -- convert color to the native format returned by object functions
local transcr_t, text_regions = Get_Transcript(REG_COLOR)
err = #transcr_t == 0 and 'no segment regions were found' or text_regions == 0 and 'no text in segment regions'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


::RELOAD::

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local state = r.GetExtState(cmd_ID, 'OPTIONS')
local opt1, opt2, opt3 = state:match('(%d)(%d)(%d)')

	function check(opt)
	return opt == '1' and '!' or ''
	end

local options = check(opt1)..'1. Skip segments without transcription|'
..(#check(opt3) == 0 and check(opt2) or '#')..'2. Add/Keep segment end time stamps|'
..check(opt3)..'3. Remove timecode|' -- if enabled disables option 2
..' [ 2, 3 are irrelevant for SRT and VTT formats ]||'
function rep(int) return ('▓'):rep(int) end
local menu = rep(10)..spaceout(' OPTIONS')..rep(9)..'||'..options..rep(9)..spaceout(' FORMAT AS')..rep(8)
..'||.&SRT||.&VTT (basic)||&AS IS (depending on the Options)| |'..rep(29)
local choice = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open is true

	if choice == 0 then return r.defer(no_undo)
	elseif choice < 2 or choice == 5 or choice == 6 or choice > 9 then goto RELOAD
	end

local undo, transcr_form, tr_name = 'Transcribing B: '

	if choice > 1 and choice < 5 then
	local options = (choice == 2 and (opt1 == '1' and '0' or '1') or opt1 or '0')
	..(choice == 3 and (opt2 == '1' and '0' or '1') or opt2 or '0')
	..(choice == 4 and (opt3 == '1' and '0' or '1') or opt3 or '0')
	local i = 0
	options = options:match('%d11')
	and options:gsub('%d', function() i = i+1 if i == 2 then return '0' end end) -- option 3 excludes option 2
	or options
	r.SetExtState(cmd_ID, 'OPTIONS', options, false) -- persist false
	goto RELOAD
	elseif choice > 6 then
	local mode = choice == 7 and 1 or choice == 8 and 2 -- SRT or VTT
	transcr_form = Format(transcr_t, mode, opt1 == '1', opt2 == '1', opt3 == '1')
	tr_name = choice == 7 and '.SRT format' or choice == 8 and '.VTT format'
	or choice == 9 and 'As Is (depending on the Options)'
	undo = choice < 9 and undo..'Convert Notes to '..tr_name or undo..'Format Notes according to Options'
	end

	if transcr_form then
	local space = function(int) return (' '):rep(int) end
	local ret, path = r.EnumProjects(-1)
		if #path == 0 then -- very unlikely but just in case
		r.MB("Project file wasn't found.\n\nPlease save project first.",'ERROR',0)
		return r.defer(no_undo) end
	local ext = choice == 7 and '.srt' or choice == 8 and '.vtt' or '.txt'
	path = path:gsub('%.[Rr][Pp]+', ext) -- OR path:match('(.+)%.[RrPp]+$')..ext
	local older_ver = r.file_exists(path)
		if older_ver then
		local resp = r.MB('There\'s an older version of the exported file'
		..'\n\n\t  in the project directory.\n\n\tShould it be overwritten?', 'PROMPT', 1)
			if resp == 2 then -- canceled by user
			return r.defer(no_undo) end
		end
	local f = io.open(path,'w')
	f:write(transcr_form)
	f:close()
		if not older_ver then -- only display when writing new file
		local mess = r.file_exists(path) and 'The file  was created\n\n\tsuccessfully'
		or space(6).."Something went wrong \n\n and file couldn\'t be created "
		Error_Tooltip("\n\n "..mess.."\n\n", 1, 1) -- caps, spaced true
		end
	end


do return r.defer(no_undo) end



