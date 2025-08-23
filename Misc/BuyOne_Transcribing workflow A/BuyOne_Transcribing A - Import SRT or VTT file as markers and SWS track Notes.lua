--[[
ReaScript name: BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 	#Updated script name and 'About' text
	  	   1.1 	#Made sure that all old Notes tracks are deleted on import
				#Changed the behavior so that all project markers are deleted on import, not just old segment markers
	      		#Made content update more visually consistent when a user prompt is displayed on VTT file import
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing A workflow set of scripts
	alongside  
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua 
	BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing A - Go to segment marker.lua
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua  
	BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua  
	BuyOne_Transcribing A - Search or replace text in the transcript.lua
	
	It allows import of SRT and VTT code from .srt. .vtt or .txt 
	files and converts it into markers and track Notes ready for 
	editing with 'BuyOne_Transcribing A - Create and manage segments.lua'
	script.
	
	Before converting the SRT/VTT time stamps into markers the 
	script deletes from the project all project markers, if any. 
	It also deletes all old Notes tracks, if any.

	SWS Notes limit per object is 65,535 bytes, therefore the 
	entire SRT/VTT transcript may not fit within a single track 
	Notes. In this script however the limit has been set to 
	16,383 bytes per track to accommodate for edits after the 
	import so running into the Notes limit within one track becomes 
	less likely. Therefore for every 16,383 bytes of converted 
	SRT/VTT code a new track is created with the name defined in 
	NOTES_TRACK_NAME setting preceded with an ordinal number, i.e. 
	the very first track will be numbered 1 and so on.  
	All such tracks are put in a folder for ease of management.
	
	Since the transcript format supported by the set of scripts 
	mentioned above is very basic, all metadata such as text 
	position/coordinates which follow the time stamps on the same 
	line will be ignored. Only the text meant to be displayed on 
	the screen and its inline formatting markup will be preserved. 
	In .VTT code, metadata between cues (cue = time code followed 
	by text without intervening empty lines) can be optionally 
	preserved. Lines in multi-line captions are delimited with the 
	new line tag <n> supported by this set of scripts.
	
	Multi-line captions are imported as one line in which the 
	original lines are separated by the new line tag <n>. These
	are converted back to multi-line captions when previewed 
	in video mode with  
	'BuyOne_Transcribing A - Real time preview.lua',  
	when exported in SRT/VTT format with  
	'BuyOne_Transcribing A - Format converter.lua',  
	and when the transcript is set up for video rendering with  
	'BuyOne_Transcribing A - Prepare transcript for rendering.lua'
	scripts. For audio rendering with the latter script the tag
	is removed.
	
	This script along with  
	'BuyOne_Transcribing A - Prepare transcript for rendering.lua'
	can be used to embed 3d party SRT/VTT subtitles in a video/audio 
	file.
	
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes specify the name of the track
-- the converted SRT/VTT code will be attached to as Notes;
-- the track will be created automatically;
-- if the SRT/VTT code is longer than 65,535 bytes which is Notes length
-- limit per object, several tracks with this name will be created
-- to accommodate all of the SRT/VTT code, and numbered sequentially;
-- either this setting must match the same setting in the script
-- 'BuyOne_Transcribing A - Create and manage segments (MAIN).lua'
-- or you can change it in the said and other scripts to match
-- this script
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


function Create_Folder_For_Adjacent_Tracks(t, parent_name)
-- single depth folder
-- t is an array which either already contains tracks
-- or contains their start and end 1-based indices, e.g. {5,10}

	if not r.ValidatePtr(t[1],'MediaTrack*') then -- the table doesn't contain tracks
	local st, fin = t[1],t[2]
	t = {}
		for i=st, fin do
		t[#t+1] = r.GetTrack(0,i-1)
		end
	end

	if #t == 1 then return end -- prevent creation of a folder for a single track

local idx = r.CSurf_TrackToID(t[1], false)-1 -- mpcView false
r.InsertTrackAtIndex(idx, true) -- wantDefaults true // create folder parent tr imediately above the first stored track
local parent_tr = r.GetTrack(0,idx)
r.SetMediaTrackInfo_Value(parent_tr, 'I_FOLDERDEPTH', 1) -- set depth to parent
r.GetSetMediaTrackInfo_String(parent_tr, 'P_NAME', parent_name, true) -- setNewValue true
r.SetMediaTrackInfo_Value(t[#t], 'I_FOLDERDEPTH', -1) -- close the folder at the last track

end



function Remove_All_Markers_And_Notes_Tracks(name_setting) -- used inside Process_SRT_VTT_Code

local parse = r.parse_timestr

local retval, mrkr_cnt = r.CountProjectMarkers(0)

local i = mrkr_cnt-1
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn then
		r.DeleteProjectMarkerByIndex(0, i)
		end
	i = i-1
	until retval == 0
	
	for i=r.GetNumTracks()-1,0,-1 do
	local tr = r.GetTrack(0,i)
	local ret, tr_name = r.GetTrackName(tr)
		if tr_name:match('^%s*%d+ '..Esc(name_setting)..'%s*$') then
		r.DeleteTrack(tr)
		end
	end

end



function Process_SRT_VTT_Code(code, tr_name)
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


local VTT = code:match('^WEBVTT')
local VT_metadata = VTT and r.MB('Wish to import VTT metadata, if any, as well?'
..'\n\n  (cue position metadata will still be ignored)', 'PROMPT', 4) == 6


Remove_All_Markers_And_Notes_Tracks(tr_name) -- placed in here so that when the above message is displayed the old content is still intact which wouldn't be the case it this function preceded Process_SRT_VTT_Code() in the main routine


local t = {}
local found
local line_cnt = 0

-- 1. Parse the code

	for line in code:gmatch('(.-)\n') do
		if not found and line:match('^%s*[:%d,%.]+ %-%->') then -- time code part
		found = 1
		local st, fin = line:match('^%s*([:%d,%.]+) %-%-> ([:%d,%.]+)')
		local st, fin = #st == 9 and '00:'..st or st, #fin == 9 and '00:'..fin or fin -- VTT time stamps may lack hours placeholder so append
		t[#t+1] = (VTT and st or st:gsub(',','.'))..' '..(VTT and fin or fin:gsub(',','.'))
		elseif not line or #line:gsub('[%s%c]','') == 0 then
		found, line_cnt = nil, 0 -- reset
		elseif found and #line:gsub('[%s%c]','') > 0 then -- text part
		line_cnt = line_cnt+1
		local new_ln = line_cnt > 1 and '<n>' or ''
		line = line:match('^%s*(.-)%s*$') -- truncating leading and trailing spaces if any
		t[#t] = t[#t]..' '..new_ln..line -- add to the time code line, preceding with new line tag if it's not the 1st caption line
		end
		-- keep metadata between cues for VTT format
		if not found and VT_metadata and #line:gsub('[%s%c]','') > 0 and not line:match('WEBVTT') then
		t[#t+1] = line
		end
	end

	if #t == 0 then
	local typ = VTT and 'vtt' or 'srt'
	Error_Tooltip("\n\n the "..typ.." code could not be parsed\n\n", 1, 1) -- caps, spaced true
	return end


r.Undo_BeginBlock()

-- 2. Insert markers

local parse = r.parse_timestr
local prev_stamp, first_mrkr_pos

	for k, line in ipairs(t) do
	local st, fin = line:match('^(%d+:%d+:%d+%.%d+) (%d+:%d+:%d+%.%d+)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
		if st then
		first_mrkr_pos = first_mrkr_pos or parse(st)
			if st ~= prev_stamp then -- only if current start time stamp and prev end time stamp are different
			r.AddProjectMarker(0, false, parse(st), 0, st, -1) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index
			end
		r.AddProjectMarker(0, false, parse(fin), 0, fin, -1)
		prev_stamp = fin
		end
	end

r.SetEditCurPos(first_mrkr_pos, true, false) -- moveview true, seekplay false // go to the first marker

-- 3. Add track Notes (Notes limit is 65,535 bytes (2^16) therefore one track may prove to be insufficient to accommodate the entire SRT/VTT code)

	local function insert_new_track(tr_name)
	r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
	local tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
	return tr
	end

	local function store_track_ext_state(tr, notes, cntr, NOTES_TRACK_NAME)
	-- store Notes start and end time stamps per Notes track
	-- to use them as a reference for selecting the Notes track
	-- depending on the name of the marker at the edit cursor with script
	-- BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
	-- index is stored to use for sorting inside folder with Create_And_Maintain_Folder_For_Note_Tracks()
	local st_stamp, end_stamp = notes:match('(%d+:%d+:%d+%.%d+) '), notes:match('.*(%d%d:%d+:%d+%.%d+).*$') -- end_stamp will capture either last segment end time stamp, if any, or its start time stamp, %d%d is used because otherwise only the second digit if hours is captured // start anchor ^ has been removed from st_stamp pattern to accommodate non-segment content preceding the first segment entry
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, cntr..' '..st_stamp..' '..end_stamp, true) -- setNewValue true
	end

local notes, cnt, tr_t, tr = '', 0, {}

	for k, line in ipairs(t) do
		if #(notes..'\n'..line) > 16383 then -- dump what has been accrued so far, using 16383 (previously 40928) instead of 65535 as a limit to provide for possible edits and translation into other languages, whose alphabet characters are multi-byte, after the import which otheriwise would likely be prevented by the limit; no point in using value different than the one used in BuyOne_Transcribing A - Create and manage segments.lua to begin with because once that script is run the number of Notes tracks will increase anyway
		cnt = cnt+1
		tr = insert_new_track(cnt..' '..tr_name)
		tr_t[#tr_t+1] = tr
		r.NF_SetSWSTrackNotes(tr, notes)
		store_track_ext_state(tr, notes, cnt, NOTES_TRACK_NAME)
		notes = line -- re-start accrual
		else -- keep accruing the string until it reaches the length of 40928 bytes
		notes = notes..(#notes == 0 and '' or '\n')..line -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
		end
	end

	if #notes:gsub('[%s%c]','') > 0 then -- if notes var wasn't reset because by the end of the loop it hasn't accrued enough content
	tr = insert_new_track((cnt+1)..' '..tr_name)
	tr_t[#tr_t+1] = tr
	r.NF_SetSWSTrackNotes(tr, notes)
	store_track_ext_state(tr, notes, cnt+1, NOTES_TRACK_NAME)
	end

	if #tr_t > 1 then
	Create_Folder_For_Adjacent_Tracks(tr_t, tr_name)
	end

r.SetOnlyTrackSelected(tr) -- to focus the Notes on it, will be the last track if notes have been split between multiple ones
r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
r.SetCursorContext(0) -- 0 is TCP // NOTES WINDOW DOESN'T SWITCH TO THE TRACK WITH FORMATTED NOTES IF THE WINDOW WAS THE LAST CLICKED BEFORE RUNNING THE SCRIPT
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

local typ = VTT and 'VTT' or 'SRT'
r.Undo_EndBlock('Transcribing A: Import '..typ..' file as markers and Notes', -1)

end


NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

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


Process_SRT_VTT_Code(code, NOTES_TRACK_NAME)



