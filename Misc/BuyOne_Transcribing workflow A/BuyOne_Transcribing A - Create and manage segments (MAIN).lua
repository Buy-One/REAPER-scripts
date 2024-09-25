--[[
ReaScript name: BuyOne_Transcribing A - Create and manage segments (MAIN).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 #Fixed time stamp formatting as hours:minutes:seconds.milliseconds
	   1.1 #Added character escaping to NOTES_TRACK_NAME setting evaluation to prevent errors caused unascaped characters
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing workflow set of scripts
	alongside  
	BuyOne_Transcribing - Real time preview.lua  
	BuyOne_Transcribing - Format converter.lua  
	BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing - Prepare transcript for rendering.lua   
	BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing - Go to segment marker.lua
	BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua

	This is the main script of the set geared towards segment 
	manipulation: creation, boundaries change, split, merger.
	
	
	THE MEDIA ITEM WHOSE CONTENT NEEDS TO BE TRANSCRIBED MUST 
	BE LOCATED AT THE VERY PROJECT START FOR THE SEGMENT TIME STAMPS 
	TO BE ACCURATE BECAUSE TIME IS COUNTED FROM THE PROJECT START
	RATHER THAN FROM THE VIDEO ITEM START.
	
	If your aim is to transcribe for .SRT/.VTT formats be aware that
	their support by this set of scripts is very basic. When the
	transcript is converted into these formats with the script
	'BuyOne_Transcribing - Format converter.lua' all textual 
	data which follow the time stamps are moved to the next line, 
	regardless of their nature as if all of them were meant to be 
	displayed on the screen. For .VTT format, data between segment
	lines can be retained at conversion which is useful for keeping
	comments, region metadata etc., if any, but garbage as well 
	because the conversion script doesn't analyze such data.  

	The transcription is meant to be managed in the SWS Track notes.
	Between segment lines, which include the time code and the segment 
	transcript, it may contain other content. Whether such other 
	content is retained depends on the export format of 
	'BuyOne_Transcribing - Format converter.lua' script, however
	it's discarded entirely by the script 
	'BuyOne_Transcribing - Prepare transcript for rendering.lua'.
	
	
	► OPERATIONS PEFRORMED BY THE SCRIPT 

	● A. Segment creation
	
	1. Manually set loop points over the audio segment to be transcribed.  
	2. Run the script to add segment time stamp(s) to the Notes of the 
	Notes track, whose name specified in NOTES_TRACK_NAME setting.
	To see the added notes keep the Notes track selected and SWS Notes
	window open with Track notes section active.  
	3. Tanscribe opposite of the time stamp(s) in the Notes window.
			
	The script also inserts project markers with time stamp in the name
	at loop points so the user can go back to previous segments and 
	modify their properties such as bounds. If there's already a segment
	marker at a loop point, new marker will not be inserted. A 'segment
	marker' is a marker with time stamp in its name in the format supported
	by the script.
	
	The transcribing project will include several Notes tracks if the 
	transcript length exceeds the set limit per track. Such tracks are 
	added automatically by the script as necessary.  
	These tracks all bear the name specified in the NOTES_TRACK_NAME 
	setting prefixed by sequential numbers. See more details further
	below.
	
	To create next segment, the following custom action may be used
	(included with the script set in the file 
	'Transcribing workflow custom actions.ReaperKeyMap' )  
	while the loop points are set to the previous segment bounds:
	
	Custom: Shift loop right by the loop length (loop points must already exist)  
	  Time selection: Copy loop points to time selection  
	  Time selection: Shift right (by time selection length)  
	  Time selection: Copy time selection to loop points  
	  Time selection: Remove (unselect) time selection  
	  
	then manually adjust loop start/end points as needed and run 
	the script again, and so on.
	
	Watch demo '1. Segment creation.mp4' which comes with the 
	set of scripts

	
	● B. Segment bounds adjustment
	
	Position of segment markers created previously can be changed, 
	in which case to have the relevant time stamps updated in the 
	marker names and in the Notes entries, after manually changing 
	marker position(s) perform the following sequence:
	
	1. Place the edit cursor within the segment bounds and run 
	the following custom action (included with the script set 
	in the file 'Transcribing workflow custom actions.ReaperKeyMap' )
	
	Custom: Create loop points between adjacent project markers (place edit cursor between markers or at the left one)  
	  Time selection: Remove (unselect) time selection and loop points  
	  View: Move cursor right 8 pixels  
	  Markers: Go to previous marker/project start  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Markers: Go to previous marker/project start
	  
   OR
  
   Double click the Ruler between two adjacent markers 
   to create loop points between them (default double-click mouse 
   modifier action of the Ruler context).
	
	2. Run this script.
	
	Watch demo '2. Segment bounds adjustment.mp4' which comes with 
	the set of scripts
	
	
	● C. Adding segment within an existing one
	
	New segments can be delimited with project markers within 
	existing ones for this:
	
	1. Manually set loop points between two ADJACENT segment markers
	so that no loop point coincides with such segment markers, otherwise
	'Segment bounds adjustment' operation will be activated.
	2. Run this script.
	
	As a result of the operation two new segment entries will be added
	to the track Notes following the one whose start time stamp matches
	that of the marker immediately preceding the loop start point. If 
	one of these new segments turns out to be redundant because there's 
	no content to transcribe within its bounds its entry can be safely 
	deleted from the Notes.
	
	The script doesn't allow creating new segments when loop points
	are set across existing segments.
	
	Watch demo '3. Adding segment within an existing one.mp4' which 
	comes with the set of scripts

	
	● D. Splitting segments
	
	Existing segments can be split, for this purpose:
	
	1. Run the custom action from step 1 of par. B. above. 	
	2. Manually adjust either start or end point of the loop moving it 
	right or left respectively (the stationary loop point must remain 
	coinciding with one of the existing segment markers, because if both 
	loop points are located within the segment, two new segments will be 
	created as per par. C above instead of the current one being split 
	which only results in creation of one new segment).  
	3. Run this script.

	Watch demo '4. Splitting segments.mp4' which comes with the set 
	of scripts

	
	● E. Merging segments
	
	Existing segments can be merged, for this purpose manually delete 
	segment markers. IF THERE'S GAP BETWEEN TWO SEGMENTS, TO MERGE THEM 
	THE END MARKER OF THE FIRST AND THE START MARKER OF THE SECOND WILL 
	HAVE TO BE DELETED. If there's no gap only the segment marker 
	separating the two will need to be deleted.   
	Once deleted do the following:
	
	1. Run the custom action from step 1 of par. B. above.  
	2. Run this script.
	
	The deleted segments transcript (if any) will be merged into the Notes 
	entry of the segment which starts at the segment marker immediately
	preceding the first of the deleted segment markers.  
	Any non-segment data which precedes the segments being merged will be 
	deleted unless it's a segment into which others are merged.

	
	When several segment markers are deleted from the end or from the start
	such that as a result another segment marker becomes the last or the first
	the segments for which the deleted markers function as start points 
	get deleted from the Notes.  
	This is different from merging segments because in that case there's no 
	change in the first/last marker.
	
	Watch demo '5. Merging segments.mp4' which comes with the set of scripts
	

	● F. Batch segment update
	
	Normally it's recommended to run the script after each segment marker
	properties or segment marker count change to update the segment data 
	in the track Notes.  
	If however for any reason you failed to update the Notes after several 
	segment marker changes, it's possible to batch update the Notes. 
	For this:  
	
	1. Clear loop points.  
	(native action 'Loop points: Remove (unselect) loop point selection'), 
	2. Run this script and assent to the prompt which will pop up.
	
	Batch segment update function carries out in one go the following
	operations in one go:  
	1. Segment marker and segment Notes entries time stamp update.  
	2. Segment transcript merger in the track Notes.  
	3. Marker array update if it was reduced by deletion of markers from
	the start and/or from the end, in which case the track Notes will
	be truncated by as many segment entries as the number of segment
	start markers deleted from the start/end of the marker array.

	------------------------------------------
	
	► RULES OF THUMB
	
	1. When there're no markers at loop points, they're created and a new 
	Notes entry is added.  
	2. When there're segment markers at loop points, either their time stamps 
	are updated if different from their actual positions OR sequential entries 
	with no matching segment markers are deleted from the Notes and text 
	associated with them (transcript) is merged with the entry immediately 
	preceding the orphan entries which all amounts to operation of segment 
	merging.  
	3. When there's a marker at one loop point only, new marker is created 
	at the non-enganged loop point and a new Note entry is added.
	
	-----------------------------------------
	
	A valid segment is always delimited by 2 markers indicating its
	beginning and end.  
	The very last marker is never associated with a segment start. If 
	INCLUDE_END_TIME setting is enabled its time stamp may appear as a 
	segment end, likewise the first marker is never associated with a 
	segment end.
	
	► NOTES SIZE LIMIT
	
	As already mentioned above, there's limit to the SWS Notes. SWS Notes 
	native limit per object is 65,535 bytes, therefore the entire transcript 
	may not fit within a single track Notes.  
	In the script however the limit has been set to 16,383 bytes to make 
	running into the Notes limit within one track less likely in cases where 
	segments are created first and only then the transcript is added to them, 
	because if segment time stamp data hit the Notes native limit of 65,535 
	bytes no further text will be allowed to be added to the Notes and the 
	actual segments transcript will be impossible to add.  
	When in a single track the transcript exceeds 16,383 bytes, additional
	track is automatically created with the name defined in NOTES_TRACK_NAME 
	setting preceded with an ordinal number, i.e. the very first track 
	will be numbered 1 and for each additional track the last number will
	be incremented by 1.	
	
	
	► NEW LINE TAG
	
	The trascript supports new line tag <n> to effect creation of a new
	line for the text which follows the tag during transcript preview 
	within video context with the script
	'BuyOne_Transcribing - Real time preview.lua'.
	and during its conversion into SRT format with the script 
	'BuyOne_Transcribing - Import SRT or VTT file as markers and Notes.lua'
	the tag is supported for SRT and VTT output formats. During conversion 
	into AS IS format the tag will be deleted if present. The tag can be 
	preceded and followed by spaces which will be trimmed at conversion.
	
	
	► SAVING
	
	Don't forget to save the project often since SWS Notes are stored
	inside the project file. 
	While hitting save shortcut make sure that REAPER program window 
	is the last clicked, because if the Notes window is the last clicked
	it will intercept the shortcut and saving won't be performed.
	
	BE AWARE THAT SWS NOTES CHANGES WHICH IMMEDIATELY PRECEDE OR FOLLOW 
	REAPER STATE CHANGE WILL GET UNDONE IF SUCH REAPER STATE CHANGE IS 
	UNDONE.  
	This has been reported to the SWS team  
	https://github.com/reaper-oss/sws/issues/1880  
	https://github.com/reaper-oss/sws/issues/1812  
	https://github.com/reaper-oss/sws/issues/1743  
	THEREFORE SAVING OFTEN IS SO MUCH MORE IMPORTANT BEACAUSE IT WILL
	ALLOW RESTORATION OF NOTES CHANGES LOST AFTER UNDO BY MEANS OF PROJECT 
	RELOAD. ALTERNATIVELY, IF PREVIOUS STATE CAN BE RESTORED WITHOUT 
	RESORTING TO UNDO IT'S ADVISED TO OPT FOR THIS METHOD. 
	
	To ensure saving you can enable SAVE_PROJECT_EVERY_SCRIPT_RUN 
	setting in this script or use the script as part of the following
	custiom action:
	
	Custom: BuyOne_Transcribing - Create and manage segments + Save  
	 BuyOne_Transcribing - Create and manage segments.lua  
	 File: Save project
	

	► ADDITIONAL WORKFLOW AIDS
	
	Disable 'Snap to grid' to be able to mark out a segment with 
	loop points with greater precision. Or hold Ctrl/Cmd when
	creating loop points to temporarily disable snapping.
	
	Custom actions (included with the script set in the file 
	'Transcribing workflow custom actions.ReaperKeyMap' )
	
	Custom: Move loop points to next segment (loop points must already be set)  
	  Time selection: Remove (unselect) time selection  
	  Go to start of loop  
	  Markers: Go to next marker/project end  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Go to start of loop

	Custom: Move loop points to previous segment (loop points must already be set)  
	  Time selection: Remove (unselect) time selection  
	  Go to start of loop  
	  Markers: Go to previous marker/project start  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Go to start of loop
	  
	To jump to a segment marker
	
	A. Either use the native functionality:  
	
	1. Select segment start/end time stamp in the Notes (can be 
	double clicked) and copy it
	2. Double click the Transport or run Ctrl+J shortcut (default)  
	3. Paste the copied time stamp into the dialogue field  
	4. Click OK or hit Enter  
	
	OR
	
	B. Use the script 'BuyOne_Transcribing - Go to segment marker.lua'
	included in this set of scripts.  
	If the script is followed by the custom action from par. B above
	namely 'Create loop points between adjacent project markers' within
	another custom action, then in addition to jumping to marker, loop 
	points can be set to the relevant segment.
	
	C. (Less convenient)
	
	1. Have the Ruler time unit set to Minutes:Seconds  
	2. Copy the time stamp from the segment data  
	3. Open the Region/Marker manager  
	4. Make sure the manager setting 'Seek playback when selecting a marker or region'
		is enabled  
	5. Paste the time stamp into the filter field of the manager
	6. Click the marker entry in the manager		
	
	
	To focus on auditioning a segment:  
	
	1. Enable the following actions:  
	Transport: Toggle stop playback at end of loop if repeat is disabled (available since build 4.30)  
	OR  
	Xenakios/SWS: [Deprecated] Toggle stop playback at end of loop  
	2. Set loop points to the segment using the custom action from step 1 of par. B above.  
	3. Hit Play to audition, at the end of the loop the play cursor will  
	return to the original position  

	To stop playback in the middle of the segment use  
	
	EITHER  
	Transport: Play/pause
	OR  
	Transport: Pause
			
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- If at least one of the Notes tracks, whose name is defined
-- in the NOTES_TRACK_NAME setting below, is record armed
-- these settings, save for NOTES_TRACK_NAME setting itself,
-- can be modified via a menu which is generated by the script
-- instead of its main functionality;
-- the menu items can be triggered from keyboard by hitting
-- the key which corresponds to the first character of the
-- menu item.


-- The name of track(s) where Notes with the transcript
-- will be stored;
-- if in one track the transcript length exceeds 16,383 bytes
-- a new one will be created and the remaining transcript
-- will be stored there;
-- all such tracks will bear the name defined in this setting
-- preceded with an ordinal number;
-- CHANGING THIS SETTING MIDPROJECT IS NOT RECOMMENDED
-- BECAUSE SCRIPT ACCESS TO THE NOTES TRACKS WILL BE LOST
NOTES_TRACK_NAME = "TRANSCRIPT"

-- To enable he following settings insert any alphanumeric character
-- between the quotes

-- Enable to make the script include segment end time stamp
-- in the new notes entry next to the segment start time stamp
INCLUDE_END_TIME = "1"


-- Enable to instruct the script to switch SWS Notes window
-- to Track notes section at each script run;
-- may be of use in situations where other Notes sections
-- must be monitored as well;
-- the drawback is momentary jolt of the UI when
-- the Notes window is closed and re-opened if already open
-- and, which is more annoying, is reset of the Notes window
-- scroll position if it's already open;
-- may also be annoying when previewing the transctibing
-- result in real time with 'BuyOne_Transcribing - Real time preview.lua'
-- script
OPEN_TRACK_NOTES_AT_EACH_SCRIPT_RUN = ""


-- Enable to have markers locked after each script run;
-- this setting will prevent free movement of segment markers
-- manually in case their position needs to be updated
-- which could be annoying
KEEP_MARKERS_LOCKED = ""


-- Enable to save the project every time
-- the script is executed,
-- helps to ensure that any changes to the Notes
-- are stored in the project file without being susceptible
-- to Notes undo problem described in SAVE paragraph under 'About:'
-- tag of this script header
SAVE_PROJECT_EVERY_SCRIPT_RUN = ""

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



function format_time_stamp(pos) -- format by adding leading zeros because r.format_timestr() ommits them
local name = r.format_timestr(pos, '')
return pos/3600 >= 1 and (pos/3600 < 10 and '0'..name or name) -- with hours
or pos/60 >= 1 and (pos/60 < 10 and '00:0'..name or '00:'..name) -- without hours
or '00:0'..name -- without hours and minutes
end



function Match_Notes_To_Markers_Props(INCLUDE_END_TIME)
-- batch data update

local tr_t, cur_notes_init = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local cur_notes = cur_notes_init
	if not cur_notes_init:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- to simplify gmatch search
	cur_notes = cur_notes_init..'\n'
	end

local notes_t = {}
	for line in cur_notes:gmatch('(.-)\n') do
		if line and #line:gsub('[%s%c]','') > 0 then
		notes_t[#notes_t+1] = line
		end
	end

	if #notes_t == 0 then
	Error_Tooltip("\n\n track notes are empty \n\n", 1, 1) -- caps, spaced true
	return end


local form, parse = r.format_timestr, r.parse_timestr

local i, mrkr_t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and (parse(name) ~= 0 or name == '00:00:00.000') then
		mrkr_t[#mrkr_t+1] = {pos=pos, name=name, idx=markr_idx}
		end
	i = i+1
	until retval == 0

	if #mrkr_t < 2 then
	local err = #mrkr_t == 0 and 'no segment markers'
	or #mrkr_t == 1 and 'not enough segment markers \n\n\tfor batch peocessing'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return end

-- 1. Adjust markers time stamps in their names if different from their actual position and update name

	for k, props in ipairs(mrkr_t) do
	local time_stamp = format_time_stamp(props.pos)
		if time_stamp ~= props.name then -- adjust time stamp in the marker name
		r.SetProjectMarker(props.idx, false, props.pos, 0, time_stamp) -- isrgn false, rgnend 0
		mrkr_t[k].name_upd = time_stamp -- include in the props table
		end
	end


-- 2. Truncate Notes from start and end to match the first and the last markers

local first_mrkr_time = mrkr_t[1].name -- original

-- look whether the start time stamp in the first Notes line matches the first marker displayed time stamp
local idx
	for k, line in ipairs(notes_t) do
		if line:match('^%s*'..first_mrkr_time) then
		idx = k
		break
		end
	end

	if idx and idx > 1 then -- the 1st marker displayed time stamp matches start time stamp of a segment the Notes line other than the 1st
		-- TRUNCATE the Notes up until the line the idx belongs to // THE REMOVED SEGMENTS TRANSCRIPT ISN'T PRESERVED BECAUSE THEY LOSE THEIR START POINT AND CEASE BEING VALID SEGMENTS
		for i = idx-1, 1, -1 do -- in reverse because of removal, otherwise once one field is removed the next will have to be decremeted by one because there'll be one field less in the table
		table.remove(notes_t, i)
		end
	elseif not idx then -- entry with the first marker time stamp wasn't found in the Notes, add one as the first entry
	table.insert(notes_t, 1, (mrkr_t[1].name_upd or first_mrkr_time)
	..(INCLUDE_END_TIME and ' '..(mrkr_t[2].name_upd or mrkr_t[2].name) or ''))
	end

-- look for the last marker time stamp appearance in the Notes as segment start time stamp
-- which will only be the case if the very last marker or several markers from the end
-- were deleted after which a segment start marker became the very last
local last_mrkr_time = #mrkr_t > 2 and mrkr_t[#mrkr_t].name

local idx
	if last_mrkr_time then
		for k, line in ipairs(notes_t) do
			if line:match('^%s*'..last_mrkr_time) then
			idx = k
			break
			end
		end
	end

	if idx then -- last marker time stamp matches segment start time stamp in the Notes
	-- TRUNCATE the Notes up until the line the idx belongs to // THE REMOVED SEGMENTS TRANSCRIPT ISN'T PRESERVED BECAUSE THEY LOSE THEIR START POINT AND CEASE BEING VALID SEGMENTS
	local fin = #notes_t -- use a variable because notes_t length will change during the loop, not sure if relying on the table length during the loop will affect the result but just to be on the safe side
		for i = fin, idx, -1 do -- idx+1 because the entry the idx belongs to must be preserved // in reverse because of removal, otherwise once one field is removed the next will have to be decremeted by one because there'll be one field less in the table
		table.remove(notes_t, i)
		end
	end


-- 3. Add marker data to Notes if absent and correct if wrong

	for k, props in ipairs(mrkr_t) do
	local name, name_upd = props.name, props.name_upd
	local idx, idx2
		for k, line in ipairs(notes_t) do
			-- search for corresponding segment entry in the Notes
			if line:match('^%s*'..name) then -- marker displayed time stamp is found as segment start time stamp
			idx = k
			break
			end
		end
		-- correct if wrong
		if idx then
			if name_upd then -- update segment start time in the Notes entry because the idx was found based on 'name' var which at the presence of name_upd var is outdated
			notes_t[idx] = notes_t[idx]:gsub(name,name_upd)
			end
			if name_upd and idx > 1 and INCLUDE_END_TIME and not notes_t[idx-1]:match(name_upd) then -- add or update previous segment end time stamp with the current segment start time stamp
			local st, fin, txt = notes_t[idx-1]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
				if st and parse(st) ~= 0.0 then
				notes_t[idx-1] = st..' '..name_upd..txt -- no space between name_upd and txt because txt includes leading space
				end
			end
		elseif k == #mrkr_t then -- genuine last marker whose time stamp can only be included in the Notes as the last segment end time stamp
		local st, fin = notes_t[#notes_t]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)')
			if #fin > 0 and parse(fin) > parse(form(props.pos, '')) and props.name_upd then -- last segment end time stamp is included but it's different from the last marker time stamp which was updated at step 1, update in the Notes
			notes_t[#notes_t] = notes_t[#notes_t]:gsub(fin, props.name_upd)
			end
		end
	end -- the mrkr_t table loop end


-- 4. Merge Notes segment entries, for which there's no corresponding marker, with previous segment entry

	for i = #notes_t, 1, -1 do -- in reverse because entries may get deleted
	local st, fin, txt = notes_t[i]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
	local match
		if st then
			for k, props in ipairs(mrkr_t) do
				if format_time_stamp(props.pos) == st then
				match = 1
				break end
			end
		end
		if not match then -- no marker matching segment start time stamp was found, merge with previous segment entry and delete from the table
		local prev_segm, next_segm = notes_t[i-1], notes_t[i+1] -- these should be valid because invalid 1st and last segment entries have been processed at step 1 above
		local st_stamp_prev, fin_stamp_prev, transcr_prev = prev_segm:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)')
		local st_stamp_next = next_segm and next_segm:match('^%s*(%d+:%d+:%d+%.%d+)')
		local fin_stamp_repl = i == #notes_t and (#fin > 0 and fin or st) or st_stamp_next -- if deleting the very last segment use its end time stamp to replace the end time stamp of the prev segment whenever possible, if absent use last segment start time stamp, in all other cases use start time stamp of the next segment
		-- update OR add end time stamp in the previous segment entry
			if #fin_stamp_prev > 0 then -- update
			prev_segm = prev_segm:gsub(fin_stamp_prev, fin_stamp_repl) -- replace segment end time stamp with the start time stamp of the last valid segment
			elseif #fin_stamp_prev == 0 and INCLUDE_END_TIME then -- add
			prev_segm = st_stamp_prev..' '..fin_stamp_repl..' '..transcr_prev
			end
		-- add transcribed text from the invalid segment entry and update the prev segment entry in the table
		notes_t[i-1] = prev_segm..' '..(txt and txt:match('%S.*') or '') -- trimming leading space if any with %S
		table.remove(notes_t, i)
		end

	end


-- 5. Include/exclude segment end time stamp depending on the setting

	for k, line in ipairs(notes_t) do
	local st_stamp, fin_stamp, txt = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)')
		if fin_stamp and #fin_stamp > 0 and not INCLUDE_END_TIME then
		notes_t[k] = line:gsub(' '..fin_stamp,'')
		elseif fin_stamp and #fin_stamp == 0 and INCLUDE_END_TIME then
		local txt = line:match('^'..st_stamp..'(.*)') -- re-capture to preserve leading spaces, if any, because they're not included in the capture above
		notes_t[k] = st_stamp..' '..mrkr_t[k+1].name..txt -- mrkr_t[k+1].name is name of the next marker containing its time stamp which will be accurate after the step 1 above, txt isn't separated by space because all spaces are included in it
		end
	end

-- 6. Update the Notes

	if table.concat(notes_t,'\n') ~= cur_notes_init then
--	r.NF_SetSWSTrackNotes(tr, table.concat(notes_t,'\n')) -- OLD
	Update_Track_Notes(tr_t, table.concat(notes_t,'\n'), NOTES_TRACK_NAME)
	else
	Error_Tooltip('\n\n\tthe transcript data \n\n seem to match the markers \n\n', 1, 1) -- caps, spaced true
	end

end



function Insert_Or_Update_Markers_At_Loop_Points(st, fin)
-- adding time stamp as marker name
local i = 0
local st_idx, fin_idx, cross_loop, last_mrkr_pos
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn then
		last_mrkr_pos = r.parse_timestr(name) ~= 0.0 and pos -- only respect segment marker (name contains time stamp)
			if pos == st then
			st_idx = i
			end
			if pos == fin then
			fin_idx = i
			end
			if st < pos and fin > pos then -- loop crosses a marker
			cross_loop = 1
			end
		end
	i = i+1
	until retval == 0

	if cross_loop then
	Error_Tooltip("\n\n   creation of segment across \n\n other segments isn't supported \n\n", 1, 1) -- caps, spaced true
	return 0
	end

	local function insert_or_update(idx, pos, st_idx)
	local form, parse = r.format_timestr, r.parse_timestr
		if not idx then -- marker doesn't exist, insert
		local name = format_time_stamp(pos)
		r.AddProjectMarker(0, false, pos, 0, name, -1) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index
		return 1
		else -- marker exists, correct time stamp if wrong
		local idx = not st_idx and idx+1 or idx -- ONLY APPLIES TO MARKER AT THE LOOP END POINT // when a new segment is being created to the left of the first one (in which case st_idx is nil), after insertion of the marker at the loop start point the original index of the marker at the loop end point will become invalid due to increase in the marker count upstream hence need to be incremented by 1
		local retval, isrgn, mrkr_pos, rgnend, name, markr_idx = r.EnumProjectMarkers(idx)
			if not isrgn then
				if parse(name) ~= 0.0 and name ~= format_time_stamp(pos) then -- 'parse(name, '') ~= 0.0' prevents evaluation against markers which don't contain time stamp in their name if those where added by means other than this script
				local name_upd = format_time_stamp(pos)
				r.SetProjectMarker(markr_idx, false, pos, 0, name_upd) -- isrgn false, rgnend 0
				return name -- name with old time stamp to find it in the Notes and correct
				elseif parse(name) == 0.0 and name ~= '00:00:00.000' then
				Error_Tooltip("\n\n at least one of the marker names \n   doesn\'t contain a time stamp. \n\n"
				.."  new segment hasn't been created \n", 1, 1) -- caps, spaced true
				else
				return -1
				end
			end
		end
	end

local ret_st = insert_or_update(st_idx, st, st_idx)
local ret_fin = ret_st and insert_or_update(fin_idx, fin, st_idx) -- only process loop end point if loops start point didn't produce an error of a marker without time stamp in which case the start point return value will be nil
last_mrkr_pos = ret_fin == 1 and (not last_mrkr_pos or fin > last_mrkr_pos) and fin or last_mrkr_pos -- switch to loop end point if a marker was inserted at it which will be signified by the return value 1

return ret_st, ret_fin, last_mrkr_pos

end



function Update_Notes_With_New_Segment_Data(cur_notes, st, fin, INCLUDE_END_TIME)
-- st/fin are loop start/end time in sec
-- the function inserts a new entry in between existing entries
-- if a new segment has been delimited between two adjacent existing segments
-- i.e. | | has become | | | |
-- and updates existing entries with new start/end time stamps

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- to simplify gmatch search
	cur_notes = cur_notes..'\n'
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
		if line and #line:gsub('[%s%c]','') > 0 then
		t[#t+1] = line
		end
	end

	if #t == 0 then return end

local parse = r.parse_timestr
local last_fin_stamp

	for i = #t, 1, -1 do -- in reverse to avoid false positives in 'st > parse(st_stamp)' condition because it's very likely to be true right at the first line whereas in reverse the last start time stamp which satisfies the condition will be the first one to produce truth
	local line = t[i]
	local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
		if st_stamp and st > parse(st_stamp) then
			if i == #t and fin_stamp and #fin_stamp > 0 and st > parse(fin_stamp) then -- a new segment has been delimited with project markers after the last without being adjacent to it
			local st, fin = format_time_stamp(st), format_time_stamp(fin)
			t[#t+1] = st..(INCLUDE_END_TIME and ' '..fin or '') -- add new entry of the actual new segment
			else -- a new segment has been delimited with project markers within the existing one
				if fin_stamp and #fin_stamp > 0 then -- update fin stamp if exists
				local st = format_time_stamp(st)
				last_fin_stamp = i == #t and fin_stamp -- store for the next loop before updating because if it's the last line its time stamp will have to be split and its fin time stamp carried over as fin time stamp of the new last segment
				t[i] = line:gsub(fin_stamp, st)
				end
		-- insert new entry after the found line
			local st, fin = format_time_stamp(st), format_time_stamp(fin)
			table.insert(t, i+1, st..(INCLUDE_END_TIME and ' '..fin or ''))
			end
		break end
	end


	for k, line in ipairs(t) do
	local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
		if k == 1 and st_stamp and fin < parse(st_stamp) then -- a new segment has been delimited with project markers before the first without being adjacent to it
		local st, fin = format_time_stamp(st), format_time_stamp(fin)
		table.insert(t, 1, st..(INCLUDE_END_TIME and ' '..fin or '')) -- add new entry of the actual new segment	before the original first entry
		break
		elseif st_stamp and fin < parse(st_stamp) then -- a new segment has been delimited with project markers within the first one, continue from the above loop by inserting new entry before the found line
		local st, fin = format_time_stamp(st), format_time_stamp(fin)
		table.insert(t, k, fin..(INCLUDE_END_TIME and ' '..st_stamp or ''))
		break
		elseif k == #t and (last_fin_stamp or not INCLUDE_END_TIME)
		then -- a new segment has been delimited with project markers within the last one, continue from the above loop by inserting new entry after the last line
		local st, fin = format_time_stamp(st), format_time_stamp(fin)
		t[#t+1] = fin..(INCLUDE_END_TIME and last_fin_stamp and ' '..last_fin_stamp or '')
		break
		end
	end


return table.concat(t,'\n')


end


function Update_Notes_With_Split_Segment_Data(cur_notes, st_mrkr, fin_mrkr, st, fin, INCLUDE_END_TIME)
-- st_mrkr, fin_mrkr are return values from Insert_Or_Update_Markers_At_Loop_Points()
-- which are set to 1 if a new marker was inserted
-- st/fin are loop start/end time in sec

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- to simplify gmatch search
	cur_notes = cur_notes..'\n'
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
		if line and #line:gsub('[%s%c]','') > 0 then
		t[#t+1] = line
		end
	end

	if #t == 0 then return end

local t_orig_len = #t -- store Notes length to evaluate at the end of the function
local parse = r.parse_timestr

	-- a scenario where the segment has been split while the loop end point coincides with a marker and its start point is free hanging
	if st_mrkr == 1 then
		for i = #t,1,-1 do -- in reverse to avoid false positives in 'st > parse(st_stamp)' condition because it's very likely to be true right at the first line whereas in reverse the last start time stamp which satisfies the condition will be the first one to produce truth
		local line = t[i]
		local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
			if st_mrkr and st_stamp and st > parse(st_stamp) then
			local st = format_time_stamp(st)
				if fin_stamp and #fin_stamp > 0 then
				t[i] = line:gsub(fin_stamp, st) -- update current line to contain time stamps of the right part of the split
				end
			table.insert(t, i+1, st..(INCLUDE_END_TIME and ' '..fin_stamp or '')) -- insert new line with time stamps of the left part of the split
			break end
		end
	end

	-- a scenario where the segment has been split while the loop start point coincides with a marker and its end point is free hanging
	if fin_mrkr == 1 then
		for k, line in ipairs(t) do
		local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
			if fin_mrkr and st_stamp and fin > parse(st_stamp) and format_time_stamp(st) == st_stamp then -- format_time_stamp(st) == st_stamp to prevent the condition from being true when a new segment is created after the last marker (rather than between two existing markers one of which will be the segment start) in which case the new Notes entry will be added after the last Notes entry outside of this function // form() (or it's alternative format_time_stamp()) function must be used rather than parse(), as in 'st == parse(st_stamp)', because st value is a float which is truncated when converted to string time stamp and won't match the truncated time stamp converted back to seconds
			local fin = format_time_stamp(fin)
				if fin_stamp and #fin_stamp > 0 then
				t[k] = line:gsub(fin_stamp, fin) -- update current line to contain time stamps of the right part of the split
				end
			table.insert(t, k+1, fin..(INCLUDE_END_TIME and ' '..fin_stamp or '')) -- insert new line with time stamps of the left part of the split
			break end
		end
	end

return #t > t_orig_len and table.concat(t,'\n')

end



function Update_Notes_With_Merged_Segment_Data(cur_notes, st, fin)
-- st/fin are loop start/end time in sec

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- to simplify gmatch search
	cur_notes = cur_notes..'\n'
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
		if line and #line:gsub('[%s%c]','') > 0 then
		t[#t+1] = line
		end
	end

	if #t == 0 then return end

local st_idx, fin_idx

	for k, line in ipairs(t) do
	local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
	-- the search ignores fin_stamp because it may be absent if INCLUDE_END_TIME setting is disabled
		if st_stamp and format_time_stamp(st) == st_stamp then -- data of the segment to merge into has been found
		st_idx = k
			if #fin_stamp > 0 then
			t[k] = line:gsub(fin_stamp, format_time_stamp(fin)) -- update segment end time stamp with loop end point time
			end
		elseif st_stamp and format_time_stamp(fin) == st_stamp then -- data of the last segment to be merged has been found
		fin_idx = k-1 -- -1 because fin will match the start time stamp of the segment which follows the last one to be merged
		break
		elseif st_idx then -- keep merging segments content
		local st_stamp, fin_stamp, transcript = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
			if st_stamp then
			t[st_idx] = t[st_idx]..' '..(transcript and transcript:match('%S.*') or '')--:gsub('[\n\r]+','') -- trimming leading space if any with %S
			end
		end
	end

fin_idx = st_idx and (fin_idx or #t) -- if fin_idx wasn't found the segments were merged up to the last marker which isn't included in the Notes, i.e. all entries following the st_idx must be merged

	-- remove data of the deleted segment
	if st_idx then
		for i = fin_idx, st_idx+1, -1  do -- st_idx+1 because entry at st_idx absorbs the merged entries and must be retained; in reverse because of removal, otherwise once one field is removed the next will have to be decremeted by one because there'll be one field less in the table
		table.remove(t,i)
		end
	return table.concat(t, '\n')
	end

end



function Toggle_Show_SWS_Notes_Window(tr, cur_notes)
-- THE VERY FIRST ADDED NOTES ENTRY DOESN'T GET DISPLAYED IN THE NOTES WINDOW, NEED TO TOGGLE THE WINDOW CLOSE/OPEN AND STORE VALUE TO PREVENT REPEATED TOGGLES AFTERWARDS !!!!!!!!!!!!!
-- the notes in this case also show up if the track selection is toggled
-- because for the track notes to be displayed the track must be selected

	if #cur_notes:gsub('[%s%c]','') == 0 and not SWITCH_TO_TRACK_NOTES then -- no Notes content and the user setting isn't enabled
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

end



-- Used inside Get_Notes_Tracks_And_Their_Notes()
-- and Update_Track_Notes()
function insert_new_track(tr_name)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
return tr
end



function Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local tr_t = {}

-- Notes track index is both added to its name and is stored as its extended state
-- the latter is used to sort them inside a folder with Create_And_Maintain_Folder_For_Note_Tracks()
-- so that user cannot affect that
-- by changing their indices in the name field

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index = data:match('^%d+')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index) then
		tr_t[#tr_t+1] = {tr=tr, name=name, idx=index}
		end
	end

	if #tr_t == 0 then -- no Notes tracks yet, insert and return the track table and empty string to be used as Notes
	local name = '1 '..NOTES_TRACK_NAME
	local tr = insert_new_track(name)
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '1', true) -- setNewValue true
	return {[1]={tr=tr, name=name, idx='1'}}, '' -- empty string for not exy existing notes
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



function Update_Track_Notes(tr_t, notes_upd, NOTES_TRACK_NAME, st)
-- tr_t comes from Get_Notes_Tracks_And_Their_Notes()
-- notes_upd comes from inside PROCESS_SEGMENTS()
-- st is loop start points, only used inside PROCESS_SEGMENTS()
-- ommitted inside Match_Notes_To_Markers_Props()
-- because there's no need to select a secific track

	if not notes_upd:sub(-1):match('\n') then -- OR notes_upd:sub(-1) ~= '\n' -- to simplify gmatch search
	notes_upd = notes_upd..'\n'
	end

	local function store_track_ext_state(tr, notes, cntr, NOTES_TRACK_NAME)
	-- store Notes start and end time stamps per Notes track
	-- to use them as a reference for selecting the Notes track
	-- depending on the name of the marker at the edit cursor with script
	-- BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua
	-- index is stored to use for sorting inside folder with Create_And_Maintain_Folder_For_Note_Tracks()
	local st_stamp, end_stamp = notes:match('(%d+:%d+:%d+%.%d+) '), notes:match('.*(%d%d:%d+:%d+%.%d+).*$') -- end_stamp will capture either last segment end time stamp, if any, or its start time stamp, %d%d is used because otherwise only the second digit if hours is captured // start character ^ has been removed from st_stamp pattern to accommodate VTT files which may start with data other than time code
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, cntr..' '..st_stamp..' '..end_stamp, true) -- setNewValue true
	end

local notes, cntr, tr = '', 0

	for line in notes_upd:gmatch('(.-)\n') do
		if #(notes..(#notes == 0 and '' or '\n')..line) > 16383 then -- dump what has been accrued so far, using 16383 instead of 65535 as a limit to provide for manual edits (especially in case the segment transcripts only begin to be added after segment creation, the transcript is projected to be on average 4 times longer than the start and end time stamps, hence 16383 because 16383 x 4 = 65532) which otheriwise would likely be prevented by the limit
		cntr = cntr+1
		tr = tr_t[cntr] and tr_t[cntr].tr or insert_new_track(cntr..' '..NOTES_TRACK_NAME) -- either use existing track or insert a new
		r.NF_SetSWSTrackNotes(tr, notes)
		store_track_ext_state(tr, notes, cntr, NOTES_TRACK_NAME)
			if st and notes:match(format_time_stamp(st)) then -- store track whose Notes contain the change, which will necessarily be associated with loop start point, in order to select it inside PROCESS_SEGMENTS() thereby focusing for Notes display
			end
		notes = line -- re-start accrual
		else -- keep accruing the string until it reaches the length of 40928 bytes
		notes = notes..(#notes == 0 and '' or '\n')..line -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
		end

	end

	if #notes:gsub('[%s%c]','') > 0 then -- if notes var wasn't reset because by the end of the loop it hasn't accrued enough content
	tr = tr_t[cntr+1] and tr_t[cntr+1].tr or insert_new_track((cntr+1)..' '..NOTES_TRACK_NAME) -- either use existing track or insert a new
	r.NF_SetSWSTrackNotes(tr, notes)
	store_track_ext_state(tr, notes, cntr+1, NOTES_TRACK_NAME)
		if st and notes:match(format_time_stamp(st)) then -- store track whose Notes contain the change, which will necessarily be associated with loop start point, in order to select it inside PROCESS_SEGMENTS() thereby focusing for Notes display
		end
	end

return tr -- if there're multiple Notes tracks due to Notes length, returns the last one

end



function Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
-- single depth folder

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


	if #tr_t < 2 then return end -- no stored tracks or 1 track for which folder isn't created

-- look for the first parent track associated with any of the Notes tracks
local parent_tr, idx--, idx2

	for k, props in ipairs(tr_t) do
	local parent = r.GetParentTrack(props.tr)
		if parent then
		local retval, name = r.GetTrackName(parent)
			if name:match(Esc(NOTES_TRACK_NAME)) then
			idx = r.CSurf_TrackToID(props.tr, false)-1 -- mpcView false, index of the first Notes track
			parent_tr = parent
			break end
		end
	end

-- sort after getting index because the original table reflects the actual order of the tracks
-- sorting is needed to arrange the tracks in ascending order;
-- alternatively the loop above could have been allowed to run all the way through without break
-- to search for the smallest index, i.e. closest to the parent track, e.g.
-- local idx_ = r.CSurf_TrackToID(props.tr, false)-1
-- idx = idx and idx_ < idx and idx_ or idx
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

local created

r.PreventUIRefresh(1)

	if not parent_tr then -- create
	created = 1
	idx = r.CSurf_TrackToID(tr_t[1].tr, false)-1 -- mpcView false, index of the first Notes track
	r.InsertTrackAtIndex(idx, true) -- wantDefaults true // create folder parent tr imediately above the first stored track
	local parent_tr = r.GetTrack(0,idx)
	r.SetMediaTrackInfo_Value(parent_tr, 'I_FOLDERDEPTH', 1) -- set depth to parent
	r.GetSetMediaTrackInfo_String(parent_tr, 'P_NAME', NOTES_TRACK_NAME, true) -- setNewValue true
	end


local sel_tr = r.GetSelectedTrack(0,0)	-- store 1st selected track, ideally all selected must be stored and restored

	if created then -- when folder is being created place tracks in it in ascending order
	-- when tracks were created they were inserted at the end of the track list in ascending order
	-- therefore the loop is straightforward
		for k, props in ipairs(tr_t) do
		idx = idx+1 -- start from the track immediately below the first track and increase count as tracks are being added
		r.SetOnlyTrackSelected(props.tr)
		r.ReorderSelectedTracks(idx, 0) -- makePrevFolder 0 no change in depth
		end
	else -- otherwise move tracks from outside of the folder into it, those which were moved outside by the user and those which were created outside by the script to accommodate Notes length
		for k, props in ipairs(tr_t) do
			if r.GetParentTrack(props.tr) ~= parent_tr
			then -- only move tracks whose parent track is different, i.e. outside of the folder or in the subfolder
			r.SetOnlyTrackSelected(props.tr)
			r.ReorderSelectedTracks(idx, 0) -- makePrevFolder 0 no change in depth
			idx = r.CSurf_TrackToID(props.tr, false)-1 -- mpcView false, get new index of the moved track to move the next above it // this accommodates cases when tracks are brought in from both downstream and upstream of the track list, with tracks from upstream simple incremention of the idx var won't work because when they're moved the count of preceding tracks changes
			end
		end

	-- sort inside the folder if some tracks where brought in from outside or their order in the folder has changed;
	-- when brought in from outside in the loop above they're not sorted
	-- while when folder has just been created the tracks do end up sorted
		for k, props in ipairs(tr_t) do
	-- OR in reverse
	--	for i=#tr_t,1,-1 do
		local tr = props.tr
	--	OR in reverse
	--	local tr = tr_t[i].tr
		r.SetOnlyTrackSelected(tr)
		r.ReorderSelectedTracks(idx, 0) -- makePrevFolder 0 no change in depth
		r.SetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH', 0) -- set depth to regular until all tracks are sorted // must be placed here because if the folder isn't followed by a regular track, more than one child track may end up being set to folder last track mode, not sure how this happens if the function precedes the re-ordering, perhaps REAPER sets the last track mode automatically after order changing because it does this when tracks order is changed by dragging
		idx = idx+1
	--	OR in reverse
	--	idx = r.CSurf_TrackToID(tr, false)-1 -- mpcView false, get new index of the moved track to move the next above it
		end
	end

r.SetMediaTrackInfo_Value(tr_t[#tr_t].tr, 'I_FOLDERDEPTH', -1) -- close the folder at the last track

local restore = sel_tr and r.SetOnlyTrackSelected(sel_tr) -- restore

r.PreventUIRefresh(-1)

-- seems to work fine without it, but just in case
r.TrackList_AdjustWindows(r.GetToggleCommandStateEx(0,41146) == 0) -- Mixer: Toggle autoarrange // isMinor arg depends on the setting to only auto-arrange in the Mixer when the setting is enabled

end



function PROCESS_SEGMENTS(tr, INCLUDE_END_TIME)

local st, fin = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, start, end 0, allowautoseek false

	if st == fin then
	Error_Tooltip("\n\n loop points aren't set \n\n", 1, 1) -- caps, spaced true
	return end

local st_mrkr, fin_mrkr, last_mrkr_pos = Insert_Or_Update_Markers_At_Loop_Points(st, fin) -- return values st_mrkr, fin_mrkr can be either 1 (new marker has been inserted at the corresponding loop point), a string (there's an existing marker at the corresponding loop point, the string contains marker old time stamp before adjustment to match actual marker position), -1 (there's an existing marker at the corresponding loop point), nil if marker coinciding with the loop start/end point is not a segment marker (doesn't contain a time stamp in its name) in which case new segment entry in the Notes won't be created
Msg(st_mrkr, 'st_mrkr')
Msg(fin_mrkr, 'fin_mrkr')

local parse = r.parse_timestr

	if st_mrkr == 0 then -- loop points cross segment delimiter, i.e. a project marker, which is disallowed
	return end

local tr_t, cur_notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

-- store last marker position in the first Notes track, marked 1, to use inside Format() function
-- of BuyOne_Transcribing - Format converter.lua script
-- in cases where 'Add/Keep segments end time stamp' (incl_end_time) option is enabled
-- while the Notes only contain segment start time stamps
-- because this will be pretty much the only reliable way to get these data
-- without having to traverse and evaluate names of all the segment markers
local ret, ext_state = r.GetSetMediaTrackInfo_String(tr_t[1].tr, 'P_EXT:LASTMARKERPOS', '', false) -- setNewValue false
	if parse(ext_state) ~= last_mrkr_pos then
	local last_mrkr_pos = format_time_stamp(last_mrkr_pos)
	r.GetSetMediaTrackInfo_String(tr_t[1].tr, 'P_EXT:LASTMARKERPOS', last_mrkr_pos, true) -- setNewValue true
	end

local cur_notes_upd, undo

-- THE VERY FIRST ADDED NOTES ENTRY DOESN'T GET DISPLAYED IN THE NOTES WINDOW, NEED TO TOGGLE THE WINDOW CLOSE/OPEN !!!!!!!!!!!!!
Toggle_Show_SWS_Notes_Window(tr, cur_notes)
--r.TrackList_AdjustWindows(false) -- https://github.com/reaper-oss/sws/issues/1885

	if st_mrkr and fin_mrkr and (st_mrkr == 1 or fin_mrkr == 1) then -- add new entry

	-- INSERT NEW SEGMENTS WITHIN EXISTING ONE, BEFORE THE FIRST OR AFTER THE LAST NON-AJACENT TO THEM
	cur_notes_upd = st_mrkr == 1 and fin_mrkr == 1 and Update_Notes_With_New_Segment_Data(cur_notes, st, fin, INCLUDE_END_TIME) -- two brand new markers have been inserted, a new segment has been delimited either within existing one of outside of all without being adjacent to the first or the last

	undo = 'Insert new segment and update SWS Track Notes'

		if not cur_notes_upd then -- either loop start or end point conicides with project markers, normally when a new segment adjacent to the last on the right or to the first on the left has been delimited
		cur_notes = #cur_notes:gsub('[%s%c]','') > 0 and cur_notes:match('.+[%w%p]')..'\n' or '' -- excluding trailing spaces and control characters

		-- SPLIT an existing segment, i.e. either loop start or end points are located between the segment delimiting markers while the other loop point coincides with an existing delimiting marker
		cur_notes_upd = st ~= last_mrkr_pos and Update_Notes_With_Split_Segment_Data(cur_notes, st_mrkr, fin_mrkr, st, fin, INCLUDE_END_TIME) -- excluding loop which starts at the last marker because in this case there's nothing to split and the next routine has to be activated to add new segment at the end

		undo = 'Split segment and update SWS Track Notes'

			-- INSERT NEW SEGMENT ADJACENT TO EITHER THE FIRST ONE ON THE LEFT OR THE LAST ONE ON THE RIGHT
			if not cur_notes_upd then -- a new segment adjacent to either the last (on its right) or the first (on its left) existing segment has been delimited

			local new_line = format_time_stamp(st)
			..(INCLUDE_END_TIME and ' '..format_time_stamp(fin) or '')
			cur_notes_upd = st_mrkr == 1 and new_line..'\n'..cur_notes or cur_notes..new_line -- new segment is either adjacent to the first on the left or to the last on the right consequently the new Notes entry is added either before the current Notes or after them
			local segm = st_mrkr == 1 and 'first' or 'last'
			undo = 'Insert new '..segm..' segment and update SWS Track Notes'
			end

		end

	-- SEGMENT BOUNDS UPDATED
	-- st_mrkr and/or fin_mrkr contain string time stamp
	elseif type(st_mrkr) == 'string' and (parse(st_mrkr) ~= 0 or st_mrkr == '00:00:00.000')
	or type(fin_mrkr) == 'string'  and parse(fin_mrkr) ~= 0 then -- existing project markers position has been changed, update existing notes entries with new time stamps
		if st_mrkr then
		cur_notes_upd = cur_notes:gsub(st_mrkr, format_time_stamp(st))
		end
		if fin_mrkr then
		cur_notes_upd = (cur_notes_upd or cur_notes):gsub(fin_mrkr, format_time_stamp(fin))
		end
	undo = 'Update segment bounds time stamp in marker names and SWS Track Notes'
	-- MERGE SEGMENT ENTRIES
	else -- some markers have been deleted - merge segments // st_mrkr and fin_mrkr are both nil
	cur_notes_upd = Update_Notes_With_Merged_Segment_Data(cur_notes, st, fin)
	undo = 'Merge segment entries in the SWS Track Notes'
	end

	if cur_notes_upd then
	local tr = Update_Track_Notes(tr_t, cur_notes_upd, NOTES_TRACK_NAME, st)
	r.SetOnlyTrackSelected(tr) -- the Notes are loaded from a selected track
	r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
	r.SetCursorContext(0) -- 0 is TCP // NOTES WINDOW DOESN'T SWITCH TO THE TRACK WITH NOTES IF THE WINDOW WAS THE LAST CLICKED BEFORE RUNNING THE SCRIPT
	Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
	return undo
	elseif st_mrkr == -1 and st_mrkr == fin_mrkr then
	Error_Tooltip("\n\n no change in marker properties \n\n\t   at the loop points. \n\n"
	.."   If you're sure there's change\n\n    try batch update technique.\n\n", 1, 1) -- caps, spaced true
	return
	end

end


function Toggle_Markers_Lock(KEEP_MARKERS_LOCKED)

local locked = r.GetToggleCommandStateEx(0, 40591) == 1 -- Locking: Toggle marker locking mode

	if not locked and KEEP_MARKERS_LOCKED then -- lock
	r.Main_OnCommand(40591, 0)
	end

end


function Settings_Management_Menu(NOTES_TRACK_NAME)

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index = data:match('^%d+')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index)
		and r.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1 then
		armed = 1 break
		end
	end

	if not armed then return end

::RELOAD::

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

-- track name sett is ignored, changing for this script only is pointless
-- because all other scripts in the set must match it
local user_sett = {'INCLUDE_END_TIME','OPEN_TRACK_NOTES_AT_EACH_SCRIPT_RUN',
'KEEP_MARKERS_LOCKED','SAVE_PROJECT_EVERY_SCRIPT_RUN'}
local sett_t, help_t, about = {}, {}
	for line in io.lines(scr_name) do
	-- collect settings
		if line:match('----- USER SETTINGS ------') and #sett_t == 0 then
		sett_t[#sett_t+1] = line
		elseif line:match('END OF USER SETTINGS')
		and not sett_t[#sett_t]:match('END OF USER SETTINGS') then
		sett_t[#sett_t+1] = line
		break
		elseif #sett_t > 0 then
		sett_t[#sett_t+1] = line
		end
	-- collect help
		if #help_t == 0 and line:match('About:') then
		help_t[#help_t+1] = line:match('About:%s*(.+)')
		about = 1
		elseif line:match('----- USER SETTINGS ------') then
		about = nil -- reset to stop collecting lines
		elseif about then
		help_t[#help_t+1] = line:match('%s*(.-)$')
		end
	end

local menu_sett = {}

	for k, v in ipairs(user_sett) do
		for k, line in ipairs(sett_t) do
		local sett = line:match(v..'%s*=%s*"(.-)"')
			if sett then
			menu_sett[#menu_sett+1] = #sett:gsub(' ','') > 0 and '!' or ''
			end
		end
	end

function pad(int)
return ('▓'):rep(int)
end

local title = ('USER SETTINGS'):gsub('.','%0 ')
local menu = pad(3)..'  '..title..' '..pad(3)..'||'..menu_sett[1]..'&Include end time||'
..menu_sett[2]..'Open track notes at each script run||'..menu_sett[3]..'&Keep markers locked||'
..menu_sett[4]..'&Save project every script run|||&View Help||'..pad(22)

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return 1 end -- 1 i.e. truth will trigger script abort to prevent activation of the main routine when menu is exited

	if output < 2 or output > 6 then goto RELOAD end

	if output == 6 then
	r.ShowConsoleMsg(table.concat(help_t,'\n'):match('(.+)%]%]'),r.ClearConsole())
	return 1 end -- 1  i.e. truth will trigger script abort to prevent activation of the main routine when menu is exited

output = output-1 -- offset the 1st menu item which is a title
local src = user_sett[output]
local sett = menu_sett[output] == '!' and '' or '1'
local repl = src..' = "'..sett..'"'
local cur_settings = table.concat(sett_t,'\n')
local upd_settings, cnt = cur_settings:gsub(src..'%s*=%s*".-"', repl, 1)

	if cnt > 0 then
	local f = io.open(scr_name,'r')
	local cont = f:read('*a')
	f:close()
	src = Esc(cur_settings)
	repl = upd_settings:gsub('%%','%%%%')
	cont, cnt = cont:gsub(src, repl)
		if cnt > 0 then
		local f = io.open(scr_name,'w')
		f:write(cont)
		f:close()
		end
	end

goto RELOAD

end



local st, fin = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, start, end 0, allowautoseek false

NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


------------- Display settings menu if notes track is armed ------------

	if Settings_Management_Menu(NOTES_TRACK_NAME) then
	return r.defer(no_undo) -- menu was exited or item is invalid
	end
------------------------------------------------------------------------

SWITCH_TO_TRACK_NOTES = #OPEN_TRACK_NOTES_AT_EACH_SCRIPT_RUN:gsub(' ','') > 0 -- also relied upon inside Toggle_Show_SWS_Notes_Window()

	if SWITCH_TO_TRACK_NOTES then
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


INCLUDE_END_TIME = #INCLUDE_END_TIME:gsub(' ','') > 0
KEEP_MARKERS_LOCKED = #KEEP_MARKERS_LOCKED:gsub(' ','') > 0
SAVE_PROJECT_EVERY_SCRIPT_RUN = #SAVE_PROJECT_EVERY_SCRIPT_RUN:gsub(' ','') > 0

	if st == fin then -- no loop points, match the transcript to the current marker array in a batch
	local retval, mrkr_cnt, reg_cnt = r.CountProjectMarkers(0)
		if mrkr_cnt == 0 then
		Error_Tooltip('\n\n no markers in the project \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end
	local end_time = '\n\n        segment end time stamp \n\n     will be '
	end_time = INCLUDE_END_TIME and end_time..'included where absent.'
	or end_time..'excluded where present.'
	local resp = r.MB('    Clicking OK will allow the script\n\n          to match the transcript'
	..'\n\n       to the markers properties.'..end_time, 'PROMPT', 1)
		if resp == 2 then -- cancelled
		return r.defer(no_undo)
		end
	r.Undo_BeginBlock()
	Match_Notes_To_Markers_Props(INCLUDE_END_TIME)
	Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
	Toggle_Markers_Lock(KEEP_MARKERS_LOCKED)
	r.Undo_EndBlock('Transcribing: Match the transcript to the marker array', -1)
	local save = SAVE_PROJECT_EVERY_SCRIPT_RUN and r.Main_SaveProject(0, false) -- forceSaveAsIn false
	return end

r.Undo_BeginBlock()

local undo = PROCESS_SEGMENTS(tr, INCLUDE_END_TIME)

	if not undo then
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) end

Toggle_Markers_Lock(KEEP_MARKERS_LOCKED)

r.Undo_EndBlock('Transcribing: '..undo, -1)

local save = SAVE_PROJECT_EVERY_SCRIPT_RUN and r.Main_SaveProject(0, false) -- forceSaveAsIn false


