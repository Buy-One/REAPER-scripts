--[[
ReaScript name: BuyOne_Transcribing - Format converter.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 #Fixed time stamp formatting as hours:minutes:seconds.milliseconds
	       #Fixed extension type when exporting as an SRT format file, added .vtt extension support
	   1.1 #Added character escaping to NOTES_TRACK_NAME setting evaluation to prevent errors caused unascaped characters
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing workflow set of scripts
	alongside  
	BuyOne_Transcribing - Create and manage segments.lua  
	BuyOne_Transcribing - Real time preview.lua  
	BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing - Prepare transcript for rendering.lua  
	BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing - Go to segment marker.lua
	BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua
	
	meant to format a transcript created with the script 
	BuyOne_Transcribing - Create and manage segments.lua
	and display the result in the SWS/S&M Notes
	
	The formatted version of the original transcript retrieved from 
	the Notes tracks named according to the NOTES_TRACK_NAME setting 
	is displayed as Notes of a new track enserted at the end of the 
	tracklist.
	
	.SRT and .VTT formats conversion is very basic. All textual data
	which follow the time stamps are moved to the next line, regardless
	of their nature as if all of them where meant to be displayed
	on the screen. Conversion into the .VTT allows keeping metadata 
	between cue lines, such as comments, region data, provided 
	such were included in the Notes between segment lines.  	
		
	Since SWS Notes length limit is set to 65535 bytes (65.5 kb)
	if transcript length exceeds the limit, the formatted transcript
	rathen than being displayed in a new track Notes will be dumped 
	to a .srt, .vtt or .txt file named after the project file which 
	will be placed in the project directory or replaced if one was 
	exported earlier. The dialogue will guide you through the process. 
	The dialogue options respond to keyboard input, options 1 through 
	4 to keys 1 - 4, .SRT - S, .VTT - V, and AS IS - A.  
	If the converted transcript doesn't exceed the limit, the resulting 
	code is displayed in track Notes named after the selected format. 
	The track is reused in subsequent conversions as long as its name
	and the format remain the same.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of track(s)
-- where Notes with the transcript are stored;
-- must match the same setting in the script
-- 'BuyOne_Transcribing - Create and manage segments.lua';
-- CHANGING THIS SETTING MIDPROJECT IS NOT RECOMMENDED
-- BECAUSE SCRIPT ACCESS TO THE NOTES TRACKS WILL BE LOST
NOTES_TRACK_NAME = "TRANSCRIPT"

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


function Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local tr_t = {}

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index = data:match('^%d+')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index) then
		tr_t[#tr_t+1] = {tr=tr, name=name, idx=index}
		end
	end

-- sort the table by integer in the track extended state
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

-- collect Notes from all found tracks
local notes = ''
	for k, t in ipairs(tr_t) do
	notes = notes..(#notes == 0 and '' or '\n')..r.NF_GetSWSTrackNotes(t.tr) -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
	end

return tr_t, notes

end


function format_time_stamp(pos) -- format by adding leading zeros because r.format_timestr() ommits them
local name = r.format_timestr(pos, '')
return pos/3600 >= 1 and (pos/3600 < 10 and '0'..name or name) -- with hours
or pos/60 >= 1 and (pos/60 < 10 and '00:0'..name or '00:'..name) -- without hours
or '00:0'..name -- without hours and minutes
end



function Format(tr_t, notes, mode, skip_empty_segm, skip_non_segm_lines, incl_end_time, remove_timecode)
-- https://docs.fileformat.com/ru/video/srt/
-- https://docs.fileformat.com/video/srt/
-- https://en.wikipedia.org/wiki/SubRip
-- https://ale5000.altervista.org/subtitles.htm
-- https://www.w3.org/wiki/VTT_Concepts
-- https://www.w3.org/TR/webvtt1/
-- https://w3c.github.io/webvtt.js/parser.html VALIDATOR
-- https://github.com/1c7/vtt-test-file/tree/master/vtt%20files
-- https://www.simultrans.com/blog/what-is-a-vtt-file

	if not notes:sub(-1):match('\n') then -- OR notes:sub(-1) ~= '\n' -- to simplify gmatch search
	notes = notes..'\n'
	end

local SRT = mode == 1
local VTT = mode == 2

local notes_t = {}
	for line in notes:gmatch('(.-)\n') do
	--	if line and (VTT or SRT and line:match('%d+:%d+:%d+%.%d+') -- VTT supports empty lines and non-segment lines i.e. metadata (extra empty lines will be dealt with later), if SRT ignore everything that's between the segment lines
	--	or not SRT and skip_non_segm_lines and line:match('%d+:%d+:%d+%.%d+') or not skip_non_segm_lines) then -- AS IS format allows ignoring empty and non-segment lines if relevant settings are enabled
		if line and (SRT and line:match('%d+:%d+:%d+%.%d+') -- always skip non-segment lines for SRT format
		or not SRT and skip_non_segm_lines and (line:match('%d+:%d+:%d+%.%d+') --or VTT and #line:gsub('[%s%c]','') == 0
		) -- if VTT allow empty lines while disallowing non-segment lines, extra empty lines will be dealt with at the end of the function
		or not SRT and not skip_non_segm_lines) -- allow all lines if VTT or AS IS; keeping all lines for VTT format helps to preserve formatting of metadata located between cues
		then
		notes_t[#notes_t+1] = line
		end
	end

	if #notes_t == 0 then
	Error_Tooltip("\n\n track notes are empty \n\n", 1, 1) -- caps, spaced true
	return end


local notes_t_proc = {} -- the new table is required to preserve original complete notes_t in case skip_empty_segm and incl_end_time options are enabled and there're empty segments which will end up being deleted, to be able to extract end time stamp of the last valid segment from the start time stamp of next segment which is empty, which would otherwise be impossible because such empty segment would have been deleted from the original table

-- 1. Remove segments with no text; must be run in a separate loop to then be able to apply sequential indices to segments if SRT/VTT format is selected (in VTT format indices aren't required though)

	if skip_empty_segm then
		for k, line in ipairs(notes_t) do
		local st, fin, txt = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
			if txt and #txt:gsub('[%s%c]','') > 0 -- segment with text, let through
			or not txt and VTT then -- if VTT and not a segment line, let through, because it could be either empty line or metadata
			notes_t_proc[#notes_t_proc+1] = line
			end
		end
	else
	notes_t_proc = notes_t
	end

-- 2. Format Notes

local segm_idx = 0

	for k, line in ipairs(notes_t_proc) do
	local st, fin, txt = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
		if st then -- may be nil if line contains VTT metadata rather than time stamps or it's empty
		segm_idx = segm_idx+1
		local txt = #fin == 0 and line:match('^'..st..'(.*)') or txt -- re-capture to preserve leading spaces, if any, if end time stamp is empty because they're not included in the capture above
		txt = txt and txt:match('%S.*') or '' -- trimming leading space from the text
		local ret, last_mrkr_stamp = r.GetSetMediaTrackInfo_String(tr_t[1].tr, 'P_EXT:LASTMARKERPOS', '', false) -- setNewValue false // stored inside PROCESS_SEGMENTS() function of 'BuyOne_Transcribing - Create and manage segments.lua' script
		fin = #fin > 0 and fin or notes_t[k+1] and notes_t[k+1]:match('^%s*%d+:%d+:%d+%.%d+')
		or #last_mrkr_stamp > 0 and last_mrkr_stamp --or format_time_stamp(itm_len)
		or format_time_stamp(r.GetProjectLength(0))
		or '' -- using original complete table to retrieve segment end time stamp from next segment start time stamp because if the next line was empty and skip_empty_segm option is enabled such line will have not been available in the notes_t_proc table; in case last_mrkr_stamp is not available use project length as the last segment end time stamp
			if SRT or VTT then
			notes_t_proc[k] = segm_idx..'\n'..(VTT and st or st:gsub('%.',','))..' --> '
			..(VTT and fin or fin:gsub('%.',','))..'\n'..txt:gsub('%s*<n>%s*','\n')
			..(#txt:gsub('[%s%c]','') > 0 and '\n' or '') -- replacing the ms decimal dot with comma to conform to SRT format, replacing new line tag and surrounding spaces, if any, with new line control character, adding trailing empty line to separate segments as per the format but preventing double empty line in cases where the segment text is empty
			else -- AS IS
			notes_t_proc[k] = (remove_timecode and '' or st..(incl_end_time and ' '..fin or '')..' ')..txt:gsub('%s*<n>%s*',' ') -- replacing new line tags and surrounding spaces, if any, with single space
			end
			if SRT or VTT and (skip_non_segm_lines or notes_t_proc[k+1] and #notes_t_proc[k+1]:gsub('[%s%c]','') > 0) -- in VTT format only add line break if the segment line isn't followed by an empty line to prevent double empty line
			or not SRT and not VTT then
			notes_t_proc[k] = notes_t_proc[k]..'\n' -- one closing new line in SRT and VTT formats was added when segment line was re-formatted above
			end
		else -- non-segm line in VTT or AS IS formats
		notes_t_proc[k] = notes_t_proc[k]..'\n'
		end
	end

--return (VTT and 'WEBVTT\n\n' or '')..table.concat(notes_t_proc, '\n'):gsub('\n\n[\n]+','\n\n') -- only replace when ther're more than 2 new lines in a row which is relevant for VTT format because in SRT all non-segment lines including empty are ignored
return (VTT and 'WEBVTT\n\n' or '')..table.concat(notes_t_proc, '')

end



function insert_new_track(tr_name)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
return tr
end



function Get_Or_Insert_Track(tr_name)

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
		if name:match('^%s*'..Esc(tr_name)..'%s*$') then
		return tr
		end
	end

-- insert if not found
return insert_new_track(tr_name)

end



function Toggle_Show_SWS_Notes_Window()
local act = r.Main_OnCommand
local cmd_ID = r.NamedCommandLookup('_S&M_TRACKNOTES') -- SWS/S&M: Open/close Notes window (track notes)
-- When in the Notes window other Notes source section is open the action will switch it to tracks
-- if it's track Notes section is already open the action will close the window;
-- evaluating visibility of a particular Notes section using actions isn't possible
-- because the toggle state of all section actions is ON as long as the Notes window is open
act(cmd_ID,0) -- toggle
	if r.GetToggleCommandStateEx(0, cmd_ID) == 0 then -- if got closed because the window was already set to track Notes
	act(cmd_ID,0) -- re-open
	end
end


function spaceout(str)
return str:gsub('.','%0 ')
end


NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local tr_t, notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)
local err = #tr_t == 0 and 'Tracks named "'..NOTES_TRACK_NAME..'" \n\n weren\'t found'
or #notes:gsub('[%s%c]','') == 0 and 'No Notes in the tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


::RELOAD::

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local state = r.GetExtState(cmd_ID, 'OPTIONS')
local opt1, opt2, opt3, opt4 = state:match('(%d)(%d)(%d)(%d)')

	function check(opt)
	return opt == '1' and '!' or ''
	end

local options = check(opt1)..'1. Skip segments without transcription|'
..check(opt2)..'2. Skip non-segment lines [always On for SRT]|'
..(#check(opt4) == 0 and check(opt3) or '#')..'3. Add/Keep segment end time stamps|'
..check(opt4)..'4. Remove timecode|' -- if enabled disables option 2
..' [ 3, 4 are irrelevant for SRT and VTT formats ]||'
function rep(int) return ('▓'):rep(int) end
local menu = rep(10)..spaceout(' OPTIONS')..rep(9)..'||'..options..rep(9)..spaceout(' FORMAT AS')..rep(8)
..'||.&SRT||.&VTT (basic)||&AS IS (depending on the Options)| |'..rep(29)
local choice = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open is true

	if choice == 0 then return r.defer(no_undo)
	elseif choice < 2 or choice == 6 or choice == 7 or choice > 10 then goto RELOAD
	end

local undo, notes_form, tr_name = 'Transcribing: '

	if choice > 1 and choice < 6 then
	local options = (choice == 2 and (opt1 == '1' and '0' or '1') or opt1 or '0')
	..(choice == 3 and (opt2 == '1' and '0' or '1') or opt2 or '0')
	..(choice == 4 and (opt3 == '1' and '0' or '1') or opt3 or '0')
	..(choice == 5 and (opt4 == '1' and '0' or '1') or opt4 or '0')
	local i = 0
	options = options:match('%d%d11')
	and options:gsub('%d', function() i = i+1 if i == 3 then return '0' end end) -- option 4 excludes option 3
	or options
	r.SetExtState(cmd_ID, 'OPTIONS', options, false) -- persist false
	goto RELOAD
	elseif choice > 7 then
	local mode = choice == 8 and 1 or choice == 9 and 2 -- SRT or VTT
	notes_form = Format(tr_t, notes, mode, opt1 == '1', opt2 == '1', opt3 == '1', opt4 == '1')
	tr_name = choice == 8 and '.SRT format' or choice == 9 and '.VTT format'
	or choice == 10 and 'As Is (depending on the Options)'
	undo = choice < 10 and undo..'Convert Notes to '..tr_name or undo..'Format Notes according to Options'
	end


	if not notes_form then return r.defer(no_undo)
	else
	local space = function(int) return (' '):rep(int) end
		if #notes_form > 65535
		then -- SWS Notes limit is 65,535 bytes per object, excess will prevent fitting the string within one Notes window
		local resp = r.MB(space(8)..'The transcript length prevents it\n\n  from fitting within a single Notes window.\n\n'
		..space(10)..'Click OK to dump it into a file\n\nwhich will be placed in the project directory\n\n'
		..space(11)..'named after the project file.','PROMPT',1)
			if resp == 1 then -- assented
			local ret, path = r.EnumProjects(-1)
				if #path == 0 then -- very unlikely but just in case
				r.MB("Project file wasn't found.\n\nPlease save project first.",'ERROR',0)
				return r.defer(no_undo) end
			local ext = choice == 8 and '.srt' or choice == 9 and '.vtt' or '.txt'
			local f = io.open(path:gsub('%.[Rr][Pp]+', ext),'w')
			f:write(notes_form)
			f:close()
			end
		return r.defer(no_undo) end
	r.Undo_BeginBlock()
	local tr = Get_Or_Insert_Track(tr_name)
	r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
	r.NF_SetSWSTrackNotes(tr, notes_form)
	r.SetOnlyTrackSelected(tr) -- to focus the Notes on it
	r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
	Toggle_Show_SWS_Notes_Window()
	r.SetCursorContext(0) -- 0 is TCP // NOTES WINDOW DOESN'T SWITCH TO THE TRACK WITH FORMATTED NOTES IF THE WINDOW WAS THE LAST CLICKED BEFORE RUNNING THE SCRIPT
	r.Undo_EndBlock(undo, -1)
	end




