--[[
ReaScript name: BuyOne_Transcribing B - Import SRT or VTT file as regions.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Fixed script name
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing B workflow set of scripts
	alongside  
	BuyOne_Transcribing B - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing B - Real time preview.lua  
	BuyOne_Transcribing B - Format converter.lua  
	BuyOne_Transcribing B - Prepare transcript for rendering.lua 
	BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
	BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
	BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua  
	BuyOne_Transcribing B - Replace text in the transcript.lua
	
	It allows import of SRT and VTT code from .srt. .vtt or .txt 
	files and converts it into regions ready for editing with 
	'BuyOne_Transcribing B - Create and manage segments.lua'
	script.
	
	Before converting the SRT/VTT time stamps into regions the 
	script deletes from the project all segment regions, i.e. 
	those colored as defined in the SEGMENT_REGION_COLOR setting. 
	Existing regions colored differently are left intact.	

	Since the transcript format supported by the set of scripts 
	mentioned above is very basic, all metadata such as text 
	position/coordinates which follow the time stamps on the same 
	line, metadata located between cues in VTT files such as regions,
	chapter names, comments	will be ignored. Only the text meant 
	to be displayed on the screen and its inline formatting markup 
	will be preserved. Lines in multi-line captions are delimited 
	with the new line tag <n> supported by this set of scripts.
	
	Multi-line captions are imported as one line in which the 
	original lines are separated by the new line tag <n>. These
	are converted back to multi-line captions when previewed 
	in video mode with  
	'BuyOne_Transcribing B - Real time preview.lua',  
	when exported in SRT/VTT format with  
	'BuyOne_Transcribing B - Format converter.lua',  
	and when the transcript is set up for video rendering with  
	'BuyOne_Transcribing B - Prepare transcript for rendering.lua'
	scripts. For audio rendering with the latter script the tag
	is removed.

	This script along with  
	'BuyOne_Transcribing B - Prepare transcript for rendering.lua'
	can be used to embed 3d party SRT/VTT subtitles in a video/audio 
	file.

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



function Remove_All_Segment_Regions(reg_color)
local i = r.CountProjectMarkers(0)-1
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx, color = r.EnumProjectMarkers3(0,i)
		if retval > 0 and isrgn and color == reg_color then
		r.DeleteProjectMarkerByIndex(0, i)
		end
	i = i-1
	until retval == 0
end



function Process_SRT_VTT_Code(code, reg_color)
-- https://docs.fileformat.com/ru/video/srt/
-- https://docs.fileformat.com/video/srt/
-- https://en.wikipedia.org/wiki/SubRip
-- https://ale5000.altervista.org/subtitles.htm
-- https://www.w3.org/wiki/VTT_Concepts
-- https://www.w3.org/TR/webvtt1/
-- https://w3c.github.io/webvtt.js/parser.html VALIDATOR
-- https://github.com/1c7/vtt-test-file/tree/master/vtt%20files
-- https://www.simultrans.com/blog/what-is-a-vtt-file

	if not code:sub(-1):match('\n') then -- OR code:sub(-1) ~= '\n' -- to simplify gmatch search
	code = code..'\n'
	end

local t = {}
local found--, segm_idx
local line_cnt = 0

-- 1. Parse the code

	for line in code:gmatch('(.-)\n') do
		if not found and line:match('^%s*[:%d,%.]+ %-%->') then -- time code part
		found = 1
		local st, fin = line:match('^%s*([:%d,%.]+) %-%-> ([:%d,%.]+)')
		t[#t+1] = (VTT and st or st:gsub(',','.'))..' '..(VTT and fin or fin:gsub(',','.'))
		elseif not line or #line:gsub('[%s%c]','') == 0 then
		found, line_cnt = nil, 0 -- reset
		elseif found and #line:gsub('[%s%c]','') > 0 then -- text part
		line_cnt = line_cnt+1
		local new_ln = line_cnt > 1 and '<n>' or ''
		line = line:match('^%s*(.-)%s*$') -- truncating leading and trailing spaces if any
		t[#t] = t[#t]..' '..new_ln..line -- add to the time code line, preceding with new line tag if it's not the 1st caption line
		end
	end

	if #t == 0 then
	local typ = VTT and 'vtt' or 'srt'
	Error_Tooltip("\n\n the "..typ.." code could not be parsed\n\n", 1, 1) -- caps, spaced true
	return end

r.Undo_BeginBlock()

-- 2. Insert regions with transcript

local parse = r.parse_timestr
local first_reg_pos

	for k, line in ipairs(t) do
	local st, fin, transcr = line:match('^(%d+:%d+:%d+%.%d+) (%d+:%d+:%d+%.%d+) (.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
		if st then
		first_reg_pos = first_reg_pos or parse(st)
		r.AddProjectMarker2(0, true, parse(st), parse(fin), transcr, -1, reg_color) -- isrgn true, wantidx -1 auto-assignment of index
		end
	end

r.SetEditCurPos(first_reg_pos, true, false) -- moveview true, seekplay false // go to the first marker

local typ = VTT and 'VTT' or 'SRT'
r.Undo_EndBlock('Transcribing B: Import '..typ..' file as markers and Notes', -1)

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

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
scr_name = scr_name:match('.+[\\/](.+)') -- whole script name without path
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named

local ret, last_path = r.GetProjExtState(0, scr_name, 'LAST_ACCESSED_PATH')
last_path = #last_path > 0 and last_path or r.GetExtState(named_ID,'LAST_ACCESSED_PATH')

local retval, file = r.GetUserFileNameForRead(last_path, 'OPEN FILE CONTAINING SRT/VTT CODE (.srt, .vtt, .txt)', '')

	if not retval then return r.defer(no_undo) end -- user cancelled the dialogue

r.SetExtState(named_ID,'LAST_ACCESSED_PATH',file:match('.+[\\/]'), false) -- persist false
r.SetProjExtState(0, scr_name, 'LAST_ACCESSED_PATH', file:match('.+[\\/]'))

local file = io.open(file, 'r')
local code = file:read('*a')
file:close()

	if #code:gsub('[%s%c]','') == 0 then
	Error_Tooltip('\n\n the file is empty \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

Remove_All_Segment_Regions(REG_COLOR)
Process_SRT_VTT_Code(code, REG_COLOR)



