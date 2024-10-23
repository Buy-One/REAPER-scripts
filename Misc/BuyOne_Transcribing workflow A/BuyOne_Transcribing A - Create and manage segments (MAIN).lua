--[[
ReaScript name: BuyOne_Transcribing A - Create and manage segments (MAIN).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog: 1.4 #Fixed track notes evaluation within the Notes window for SWS builds 
		where BR_Win32_GetWindowText() function's buffer size is 1 kb  
	   1.3 #Fixed error on creation of the very first segment while Notes are still empty
		#Fixed script functionality in cases where there're gaps between segments
		and there's no segment time stamp in the Notes and in some corner cases
		#Made segment merging functionality more robust in general
		#Improved logic of splitting Notes between multiple Notes track when non-segment content
		is present in between segment entries
		#If there're multiple Notes tracks, ensured selection of the track whose Notes have been modified
		by the script in non-batch update mode
		#Sorted out script operations relationship with gaps between segments
		#Added support for empty lines and non-segment content between segment lines in the Notes
		#Added error messages when loop points are set to gap between segments
		or to a marker at position not reflected in the transcript
		#Updated script name
		#Updated 'About' text
	    1.2 #Fixed time stamp formatting as hours:minutes:seconds.milliseconds
	    1.1 #Added character escaping to NOTES_TRACK_NAME setting evaluation to prevent errors caused unascaped characters
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M mandatory, js_ReaScriptAPI recommended
About:	The script is part of the Transcribing A workflow set of scripts
	alongside  
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua   
	BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing A - Go to segment marker.lua
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua  
	BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua

	This is the main script of the set geared towards segment 
	manipulation: creation, boundaries change, split, merger.
	
	
	THE MEDIA ITEM WHOSE CONTENT NEEDS TO BE TRANSCRIBED MUST 
	BE LOCATED AT THE VERY PROJECT START FOR THE SEGMENT TIME STAMPS 
	TO BE ACCURATE BECAUSE TIME IS COUNTED FROM THE PROJECT START
	RATHER THAN FROM THE MEDIA ITEM START.  
	PROJECT TIME BASE MUST BE SET TO TIME SO THAT MEDIA ITEM
	LENGTH AND LOCATION AND MARKERS LOCATION ARE INDEPENDENT 
	OF PROJECT TEMPO.  
	For a method of updating segment time stamps when there's a  
	need to move the media item on the time line after segments 
	have been created, refer to ADDITIONAL WORKFLOW AIDS 
	paragraph below.
	
	
	If your aim is to transcribe for SRT/VTT formats be aware that
	their support by this set of scripts is very basic. When the
	transcript is converted into these formats with the script
	'BuyOne_Transcribing A - Format converter.lua' all textual 
	data which follow the time stamps are moved to the next line, 
	regardless of their nature as if all of them were meant to be 
	displayed on the screen. For VTT format, data between segment
	lines can be retained at conversion which is useful for keeping
	comments, region metadata etc., if any, but garbage as well 
	because the conversion script doesn't analyze such data.  

	The transcription is meant to be managed in the SWS Track notes.
	Between segment lines, which include the time code and the segment 
	transcript, it may contain other content. Whether such other 
	content is retained depends on the export format of 
	'BuyOne_Transcribing A - Format converter.lua' script, 
	however it's discarded entirely by the script 
	'BuyOne_Transcribing A - Prepare transcript for rendering.lua'.
	
	
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
	
	Custom: Transcribing - Shift loop right by the loop length (loop points must already exist)  
	  Time selection: Copy loop points to time selection  
	  Time selection: Shift right (by time selection length)  
	  Time selection: Copy time selection to loop points  
	  Time selection: Remove (unselect) time selection  
	  
	then manually adjust loop start/end points as needed and run 
	the script again, and so on.
	
	Watch demo 'Transcribing A - 1. Segment creation.mp4' which comes 
	with the set of scripts

	
	● B. Segment bounds adjustment
	
	Position of segment markers created previously can be changed, 
	in which case to have the relevant time stamps updated in the 
	marker names and in the Notes entries, after manually changing 
	marker position(s) perform the following sequence:
	
	1. Place the edit cursor within the segment bounds and run 
	the following custom action (included with the script set 
	in the file 'Transcribing workflow custom actions.ReaperKeyMap' )
	
	Custom: Transcribing - Create loop points between adjacent project markers (place edit cursor between markers or at the left one)  
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
	
	Watch demo 'Transcribing A - 2. Segment bounds adjustment.mp4' 
	which comes with the set of scripts.
	
	The operation is also allowed within gaps between segments where
	the loop points is set to markers delimiting the gap between segments
	rather than to those delimiting the adjacent segments.
	
	
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
	
	Watch demo 'Transcribing A - 3. Adding segment within an existing one.mp4' 
	which comes with the set of scripts.
	
	The operation is also allowed within gaps between segments.

	
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

	Watch demo 'Transcribing A - 4. Splitting segments.mp4' which comes 
	with the set of scripts.
	
	The operation isn't allowed within gaps between segments.

	
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
	
	Watch demo 'Transcribing A - 5. Merging segments.mp4' which comes with 
	the set of scripts
	

	● F. Batch segment update
	
	Normally it's recommended to run the script after each segment marker
	properties or segment marker count change to update the segment data 
	in the track Notes.  
	If however for any reason you failed to update the Notes after several 
	segment marker changes or you wish to update the Notes with several
	changes at once, it's possible to batch update the Notes. 
	For this:  
	
	1. Clear loop points.  
	(native action 'Loop points: Remove (unselect) loop point selection'), 
	2. Run this script and assent to the prompt which will pop up.
	
	Batch segment update function carries out in one go the following
	operations:  
	1. Segment marker and segment Notes entries time stamp update.  
	2. Segment transcript merger in the track Notes.  
	3. Removal of segment markers not associated with any segment entry.
	4. Marker array update if it was reduced by deletion of markers from
	the start and/or from the end, in which case the track Notes will
	be truncated by as many segment entries as the number of segment
	start markers deleted from the start/end of the marker array.
	5. Adding/removing end time stamp from segment entries depending
	on the INCLUDE_END_TIME setting.
	
	Be aware that while the script runs in this mode REAPER may freeze.
	
	
	● G. Deleting segments
	
	1. One way is to merge segment you wish to delete with the preceding
	or the following segment using technique described in par. E above.
	After such merger delete the segment transcript from the segment entry
	it's been merged with in the track Notes.
	
	2. Another way is to first delete segment entries from the Notes and 
	then run the script in Batch segment update mode described in par. F 
	above to delete markers which are uniquely associated with the deleted
	segments and are now redundant.
	
	3. To delete segments from the very start or the very end of the 
	transcript which will result in the change of the first/last
	marker, either the method 2 must be employed or alternatively markers 
	can be deleted first and their deletion followed by running the 
	script in the Batch segment update mode.
	
	
	● E. Settings management and displaying this text
	
	The user can manage the script settings, save for NOTES_TRACK_NAME
	setting, from a menu which will be dislplayed if any of the Notes
	tracks, i.e. those named according to the NOTES_TRACK_NAME setting
	preceded by a numeral, is record armed. The settings can be toggled
	from the menu by typing the first character of the menu item title
	with the exception of 'Save project every script run' which can be
	triggered with keyboard key 'p'.  
	The menu includes 'Help' item a click on which or typing character 
	'v' will call the ReaScript console with this text for reference 
	if needed.
	
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
	'BuyOne_Transcribing A - Real time preview.lua'.
	and during its conversion into SRT format with the script 
	'BuyOne_Transcribing A - Import SRT or VTT file as markers and Notes.lua'
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
	 BuyOne_Transcribing A - Create and manage segments.lua  
	 File: Save project
	

	► ADDITIONAL WORKFLOW AIDS
	
	Disable 'Snap to grid' to be able to mark out a segment with 
	loop points with greater precision. Or hold Ctrl/Cmd when
	creating loop points to temporarily disable snapping.
	
	When creating/managing multiple segments back to back it's very 
	convenient to set this script armed by right clicking the 
	toolbar button it's linked to and simply click on the Arrange 
	canvas to run the script.			
  
	To jump to a segment marker
	
	A. Either use the native functionality:  
	
	1. Select segment start/end time stamp in the Notes (can be 
	double clicked) and copy it
	2. Double click the Transport or run Ctrl+J shortcut (default)  
	3. Paste the copied time stamp into the dialogue field  
	4. Click OK or hit Enter  
	
	OR
	
	B. Use the script 'BuyOne_Transcribing A - Go to segment marker.lua'
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
	
	
	To navigate between segments for auditioning or preview
	within video context with 'BuyOne_Transcribing A - Real time preview.lua' 
	script when the transport is stopped use the following custom 
	actions (included with the script set in the file 
	'Transcribing workflow custom actions.ReaperKeyMap' ):
	
	Custom: Transcribing - Move loop points to next segment (loop points must already be set)  
	  Time selection: Remove (unselect) time selection  
	  Go to start of loop  
	  Markers: Go to next marker/project end  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Go to start of loop

	Custom: Transcribing - Move loop points to previous segment (loop points must already be set)  
	  Time selection: Remove (unselect) time selection  
	  Go to start of loop  
	  Markers: Go to previous marker/project start  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Go to start of loop

	  
	If after you started your project you need to move the transcript
	media source later or earlier (after trimming from the beginning)
	on the time line in order to lengthen/shorten the time between the 
	media start and the transcribed content start within the media 
	(remember, that transcript segments time stamp will only be 
	accurate if the media starts at and is rendered from the project 
	start) you can:
	
	A. 
	1. Enable 'Ripple edit all tracks'.  
	2. Ensure that the media item spans all segment markers otherwise 
	the feature won't work.  
	3. Change the position of the media item by dragging it and the 
	markers will follow.
	
	B. After moving the media item take advantage of the script  
	'BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua'
	included in the script set.  
	
	In both cases after marker positions have been changed run this 
	script in Batch segment update mode (see par. F above) in order 
	to update segment time stamps in the marker names and in track Notes.

	
	► CONVERSION BETWEEN PROJECTS
	
	To convert between Transcribing A and B workflow projects export 
	the source project as an SRT or VTT file and import it back into 
	REAPER using the scripts  
	'BuyOne_Transcribing A - Format converter.lua' to export and
	'BuyOne_Transcribing B - Import SRT or VTT file as regions.lua'
	to import, or vice versa  
	'BuyOne_Transcribing B - Format converter.lua'
	'BuyOne_Transcribing A - Import SRT or VTT file as regions.lua'
	depending on the direction of conversion.	 
	If transcript of Transcribing A workflow source project contains 
	metadata meant to be exported in VTT format, it will be lost as 
	a result of import with 
	'BuyOne_Transcribing B - Import SRT or VTT file as regions.lua'
	script because Transcribing B workflow doesn't support metadata.
	
	
	►  CAVEATS
	
	When track Notes which due to their length cannot fit within the 
	current Notes window, are getting updated with the script, the 
	Notes window scroll position is reset to the top of the window. 
	So one has to scroll down to search for the target line again 
	in the Notes if it's located outside of the visible area. However 
	this is fixable by installing js_ReaScriptAPI extension from  
	https://github.com/juliansader/ReaExtensions  
	or via ReaPack.  
	The solution is relevant for running the script in Batch update
	mode (see par. 'F. Batch segment update' above) and when 
	SELECT_TRACK_OF_UPDATED_NOTES setting isn't enabled in the USER
	SETTING
	
	The track specific scroll position is also not stored, so when 
	the Notes window is switched between tracks by changing track 
	selection the Notes window scroll position will each time end up 
	being reset to the top. This can't be fixed because these actions
	are performed independently of the script.

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
-- THE TRACK MUST NOT BE CREATED MANUALLY IN ADVANCE
-- IT WILL BE CREATED AUTOMATICALLY BY THE SCRIPT
-- WHEN THE FIRST SEGMENT IS CREATED as described
-- in par. A of the 'About' text in the header above;
-- afterwards if in one track the transcript length exceeds
-- 16,383 bytes a new one will be created and the remaining
-- transcript will be stored there;
-- all such tracks will bear the name defined in this setting
-- preceded with an ordinal number;--
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
-- may also be annoying when previewing the transcribing
-- result in real time with 'BuyOne_Transcribing A - Real time preview.lua'
-- script
OPEN_TRACK_NOTES_AT_EACH_SCRIPT_RUN = ""


-- Enable to make the script select the Notes track
-- whose Notes have been updated so that they're
-- displayed in the Notes window;
-- relevant in case there're multiple Notes tracks
-- due to length of the transcript (see par. NOTES SIZE LIMIT
-- of the 'About:' text in the header)
-- and the script isn't run in 'Batch update' mode
-- (see par. F of the 'About:' text in the header)
-- because in this case Notes of mulitple tracks
-- could end up being updated;
-- this option also enables Notes window scrolling
-- to the segment entry which has been updated
-- (ONLY TESTED ON WINDOWS);
-- if the setting is disabled the Notes track selection
-- doesn't change and no Notes window scrolling occurs
-- even if it's the displayed Notes of the currently
-- selected track which have been updated
SELECT_TRACK_OF_UPDATED_NOTES = "1"


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
-- tag of this script header;
-- irrelevant if the script is run in the Batch update mode
-- (see par. F or the 'About:' text)
-- as a safeguard against saving project changes to file
-- in case the batch update goes wrong, because this allows
-- re-loading the transcript from the project file
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



function GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos)

	if not r.JS_Window_Find then return end

	if not notes_wnd then -- Get
	local parent_wnd
		for k, title in ipairs({'Notes', 'Notes (docked)'}) do -- the names cover docked and undocked wrapper window
		parent_wnd = r.JS_Window_Find(title, true) -- exact true
			if parent_wnd then break end
		end
		if parent_wnd then
		local notes_wnd = r.JS_Window_FindChild(parent_wnd, ':', false) -- exact false, Track notes window containing text can be found with blank space or 0 or colon (:) which is very likely to be included in the Notes, the entire Notes content is returned as Track notes child window title with JS_Window_GetTitle(), if not found there're no Notes
			if notes_wnd then
			local retval, top_pos, pageSize, min_px, max_px, scroll_pos = r.JS_Window_GetScrollInfo(notes_wnd, 'VERT') -- 'v' vertical scrollbar, or 'SB_VERT', or 'VERT' // the shorter the window the greater the bottomost scroll_pos value
			return notes_wnd, scroll_pos
			end
		end
	else -- Set
	r.JS_Window_SetScrollPos(notes_wnd, 'v', scroll_pos) -- 'v' vertical scrollbar, or 'SB_VERT', or 'VERT'
	end

end



function Find_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search windows with BR_Win32_FindWindowEx(), including docked
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtexta#return-value
-- 2. search floating docker with BR_Win32_FindWindowEx() using 2 title options, and loop to find children and siblings
-- 3. search dockers attached to the main window with r.GetMainHwnd() and loop to find children and siblings

	local function Find_Win(title)
	return r.BR_Win32_FindWindowEx('0', '0', '', title, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // does find single windows and single windows docked in floating dockers with '(docked)' appendage in the title, doesn't find children windows, such as docked in multi-tab docks and single docked in dockers attached to the main window, hence the actual function Find_Window_SWS()
	end

	local function get_wnd_siblings(hwnd, val, wnd_name)
	-- val = 2 next; 3 prev doesn't work if hwnd belongs
	-- to the very 1st child returned by BR_Win32_GetWindow() with val 5, which seems to always be the case
	local Get_Win = r.BR_Win32_GetWindow
	-- evaluate found window
	local ret, tit = r.BR_Win32_GetWindowText(hwnd)
		if tit == wnd_name then return hwnd
		elseif tit == 'REAPER_dock' then -- search children of the found window
		-- dock windows attached to the main window have 'REAPER_dock' title and can have many children, each of which is a sibling to others, if nothing is attached the child name is 'Custom1', 15 'REAPER_dock' windows are siblings to each other
		local child = Get_Win(hwnd, 5) -- get child 5, GW_CHILD
		local hwnd = get_wnd_siblings(child, val, wnd_name) -- recursive search for child siblings
			if hwnd then return hwnd end
		end
	local sibl = Get_Win(hwnd, 2) -- get next sibling 2, GW_HWNDNEXT
		if sibl then return get_wnd_siblings(sibl, val, wnd_name) -- proceed with recursive search for dock siblings and their children
		else return end
	end

	local function search_floating_docker(docker_hwnd, docker_open, wnd_name) -- docker_hwnd is docker window handle, docker_open is boolean, wnd_name is a string of the sought window name
		if docker_hwnd and docker_open then -- windows can be found in closed dockers hence toggle state evaluation
	-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
		local child = r.BR_Win32_GetWindow(docker_hwnd, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
		local ret, tit = r.BR_Win32_GetWindowText(child) -- floating docker window 1st child name is 'REAPER_dock', attached windows are 'REAPER_dock' child and/or the child's siblings
		return get_wnd_siblings(child, 2, wnd_name) -- go recursive enumerating child siblings; sibling 2 (next) - GW_HWNDNEXT, 3 (previous) - GW_HWNDPREV, 3 doesn't seem to work regardless of the 1st child position in the docker, probably because BR_Win32_GetWindow with val 5 always retrieves the very 1st child, so all the rest are next
		end
	end

-- search for floating window
local wnd = Find_Win(wnd_name)

	if wnd then return wnd end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker' // non-toolbar windows can be attached to a floating toolbar docker as well
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search for a floating docker with one attached window
local docker = Find_Win(wnd_name..' (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd and (r.JS_Window_IsVisible and r.JS_Window_IsVisible(wnd) or dock) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- search toolbar docker with multiple attached windows which can house regular windows
docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker', non-toolbar windows can be attached to a floating toolbar docker as well
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search floating docker with multiple attached windows which can house toolbars
docker = Find_Win('Docker') -- when a docker attached to the main window is detached from it by toggling 'Attach docker to the main window' and there're several windows in it, the floating docker title is 'Docker'
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search docks attached to the main window
	if dock and not want_main_children or want_main_children then -- windows can be found in closed dockers hence toggle state evaluation
	local main = r.GetMainHwnd() -- the name of the dock window is 'REAPER_dock' of which there're 15 all being children of the main window and siblings of each other, attached windows are dock children and are siblings of each other
	local child = r.BR_Win32_GetWindow(main, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
	return get_wnd_siblings(child, 2, wnd_name)
	end

end



function Scroll_SWS_Notes_Window(parent_wnd, str, tr)
-- parent_wnd is window titled 'Notes' or 'Notes (docked)' found with Find_Window_SWS() function
-- str is string to be found in the Notes
-- tr is selected track
-- no scrolling will occur if the track notes aren't found in the Notes window

	local function string_exists(txt, str)
		for line in txt:gmatch('[^\n]+') do
		-- str is escaped to cover all cases
			if line:match(Esc(str)) then return txt end
		end
	end

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child

	if not child then return end

-- search str in all children of parent_wnd
local i, notes = 1
	repeat
		if child then
		local ret, txt = r.BR_Win32_GetWindowText(child) -- before SWS build 2.14.0.3 was limited to 1kb therefore couldn't return the entire Track Notes content https://github.com/reaper-oss/sws/issues/1896
		-- overcoming BR_Win32_GetWindowText() limitation by falling back on alternatives		
		notes = ret and string_exists(txt, str) or r.JS_Window_GetTitle and string_exists(r.JS_Window_GetTitle(child), str)
			-- this is method of finding str in Track Notes for SWS extention builds
			-- where BR_Win32_GetWindowText() is limited to 1kb
			-- simple fall back on r.NF_GetSWSTrackNotes(tr) will produce false positives
			-- because it will return notes where the window won't
			-- ONLY RELEVANT FOR TRACK NOTES
			if not notes then
			local notes_tmp = r.NF_GetSWSTrackNotes(tr)
				if #notes_tmp:gsub('[%c%s]','') > 0 then
				local test_str = 'ISTRACKNOTES' -- the test string is initialized without line break char to be able to successfully find it in the window text because search with the line break char will fail due to carriage return \r being added to the end of the line and thus preceding the line break, i.e. 'ISTRACKNOTES\r\n'
				r.NF_SetSWSTrackNotes(tr, test_str..'\n'..notes_tmp) -- add a test string to start of the notes so it's sure to be included in the string returned by the limited BR_Win32_GetWindowText() version 
				local ret, txt = r.BR_Win32_GetWindowText(child)
					if ret and txt:match(test_str) and string_exists(notes_tmp, str) then
					notes = notes_tmp
					end
				r.NF_SetSWSTrackNotes(tr, notes_tmp) -- restore original notes without the test string
				end
			end
			if notes then break end
		end
	-- get for evaluation in the next cycle if valid
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child

	--	if string_exists(txt, str) then
	if notes then
	local line_cnt, notes = 0, notes:sub(-1) ~= '\n' and notes..'\n' or notes -- ensures that the last line is captured with gmatch search
		for line in notes:gmatch('(.-)\n') do	-- accounting for empty lines because all must be counted
			if line:match(str) then break end -- stop counting because that's the line which should be reached by scrolling but not scrolled past; to cover all cases str must be escaped with Esc() function but here it's not necessary
		line_cnt = line_cnt+1
		end
	--	r.PreventUIRefresh(1) doesn't affect windows
	--	set scrollbar to top to procede from there on down by lines
	r.BR_Win32_SendMessage(child, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
		for i=1, line_cnt do
		r.BR_Win32_SendMessage(child, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, lParam 0, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll but in fact the message code must be passed here as lParam while wParam must be 0, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage
		end
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

	if not cur_notes_init:match('[%w%p]+') then
	Error_Tooltip("\n\n track notes are empty \n\n", 1, 1) -- caps, spaced true
	return end

local cur_notes = cur_notes_init
	if not cur_notes_init:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- ensures that the last line is captured with gmatch search
	cur_notes = cur_notes_init..'\n'
	end

local notes_t = {}
	for line in cur_notes:gmatch('(.-)\n') do
	notes_t[#notes_t+1] = line
	end


local form, parse = r.format_timestr, r.parse_timestr

local i, mrkr_t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, mrkr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and (parse(name) ~= 0 or name == '00:00:00.000') then
		mrkr_t[#mrkr_t+1] = {pos=pos, name=name, idx=mrkr_idx}
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


-- 2. Add marker data to Notes if absent and correct if wrong

	local function get_next_or_prev_segm_idx(t, start_idx, mode)
	local nxt, prev = mode == 1, mode == 2
	local st, fin, dir = table.unpack(nxt and {start_idx, #t, 1} -- ascending , next segment
	or prev and {start_idx, 1, -1}) -- descending, previous segment
		if st then
			for i=st,fin,dir do
				if t[i]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)')
				then return i
				end
			end
		end
	end

	for k, props in ipairs(mrkr_t) do
	local name, name_upd = props.name, props.name_upd
	local idx, idx_fin, idx2
		for k, line in ipairs(notes_t) do
			-- search for corresponding segment entry in the Notes
			if line:match('^%s*'..name) then -- marker displayed time stamp is found as segment start time stamp		
			idx = k
			break
			elseif line:match('^.-'..name) then -- marker displayed time stamp is found as segment end time stamp
			idx_fin = k -- don't break here because if there's no gap between segments the marker time stamp will be found as next segment start time stamp in the next cycle
			end
			-- break if time stamp is found as segment start time stamp
			-- OR as end time stamp in current segment BUT NOT as start time stamp in the next one
			-- in case they're adjacent, because in this case contuniation of looping over the Notes is pointless
			if idx or idx_fin and k > idx_fin and line:match('^%s*(%d+:%d+:%d+%.%d+)') 
			and not line:match('^%s*'..name) then break end
		end
		-- correct if wrong
		if idx_fin and name_upd then
		notes_t[idx_fin] = notes_t[idx_fin]:gsub(name,name_upd)
		end
		if idx then
			if name_upd then -- update segment start time in the Notes entry because the idx was found based on 'name' var which at the presence of name_upd var is outdated
			notes_t[idx] = notes_t[idx]:gsub(name,name_upd)
			end
			if name_upd and idx > 1 and INCLUDE_END_TIME and not notes_t[idx-1]:match(name_upd) then -- add or update previous segment end time stamp with the current segment start time stamp; updating probably won't be necessary in view of idx_fin var, but adding might be
			local prev_segm_idx = get_next_or_prev_segm_idx(notes_t, idx-1, 2) -- accounting for data between segment entries
				if prev_segm_idx then
				local st, fin, txt = notes_t[prev_segm_idx]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
					if st and parse(st) ~= 0 and (fin == name or #fin == 0) then -- only if there's no gap between prev and current segments, in which case prev segment end time stamp will be identical to current segment start time stamp, OR if prev segment time stamp is blank
					notes_t[idx-1] = st..' '..name_upd..txt -- no space between name_upd and txt because txt includes leading space
					end
				end
			end
		elseif k == #mrkr_t then -- genuine last marker whose time stamp can only be included in the Notes as the last segment end time stamp
		local st, fin = notes_t[#notes_t]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)')
			if fin and #fin > 0 and parse(fin) > parse(form(props.pos, '')) and props.name_upd then -- last segment end time stamp is included but it's different from the last marker time stamp which was updated at step 1, update in the Notes
			notes_t[#notes_t] = notes_t[#notes_t]:gsub(fin, props.name_upd)
			end
		end
	end -- the mrkr_t table loop end


-- 3. Truncate Notes from start and end to match the first and the last markers

local first_mrkr_time = mrkr_t[1].name_upd or mrkr_t[1].name -- updated name if was updated, or original

-- look for the first marker time stamp appearance in the Notes as segment start time stamp
local idx_init
	for k, line in ipairs(notes_t) do
		if line:match('^%s*'..first_mrkr_time) then
		idx_init = k
		break
		end
	end


-- if there's non-segment content which precedes the 1st segment it must be preserved
-- therefore look for the last valid segment before such content
local idx = idx_init and get_next_or_prev_segm_idx(notes_t, idx_init-1, 2) -- mode 2 previous // idx_init-1 to start search from immediately preceding segment otherwise the 1st valid segment itself will be detected and its index returned

local end_time
	if not idx then
	-- look for first_mrkr_time in segment end time stamp which is possible
	-- when the deleted segment markers are followed by a gap between segments
	-- which is the reason first_mrkr_time wasn't found in the segment start time stamp above
		for k, line in ipairs(notes_t) do
			if line:match('^%s%d+:%d+:%d+%.%d+%s+'..first_mrkr_time) then
			idx = k
			end_time = 1 -- set to true
			break
			end
		end
	end


	if idx and idx > 1 or end_time then -- the 1st marker displayed time stamp matches start time stamp of a segment the Notes line other than the 1st or matches segment end time stamp
		-- TRUNCATE the Notes up until the line with index idx+1 // THE REMOVED SEGMENTS TRANSCRIPT ISN'T PRESERVED BECAUSE THEY LOSE THEIR START POINT AND CEASE BEING VALID SEGMENTS
		for i = idx, 1, -1 do -- in reverse because of removal, otherwise once one field is removed the next will have to be decremeted by one because there'll be one field less in the table
		table.remove(notes_t, i)
		end
	end
	if not idx_init or end_time then -- entry with the first marker time stamp wasn't found in the Notes or was found in the end time stamp of a segment which would be deleted, add one as the first entry
	table.insert(notes_t, 1, (mrkr_t[1].name_upd or first_mrkr_time)
	..(INCLUDE_END_TIME and ' '..(mrkr_t[2].name_upd or mrkr_t[2].name) or ''))
	end


-- look for the last marker time stamp appearance in the Notes as segment start time stamp
-- which will only be the case if the very last marker or several markers from the end
-- were deleted after which a segment start marker became the very last
local last_mrkr_time = #mrkr_t > 2 and (mrkr_t[#mrkr_t].name_upd or mrkr_t[#mrkr_t].name)

local idx
	if last_mrkr_time then
		for k, line in ipairs(notes_t) do
			if line:match('^%s*'..last_mrkr_time) then
			idx = k
			break
			end
		end
	end


-- if there's non-segment content which precedes the last (now invalid) segment it must be removed as well
-- therefore look for the last valid segment before such content
idx = idx and get_next_or_prev_segm_idx(notes_t, idx-1, 2) -- mode 2 previous // idx-1 to start search from immediately preceding

	if idx --and idx < #notes_t
	then -- last marker time stamp matches segment start time stamp in the Notes
	-- TRUNCATE the Notes up until the line the idx belongs to // THE REMOVED SEGMENTS TRANSCRIPT ISN'T PRESERVED BECAUSE THEY LOSE THEIR START POINT AND CEASE BEING VALID SEGMENTS
	local fin = #notes_t -- use a variable because notes_t length will change during the loop, not sure if relying on the table length during the loop will affect the result but just to be on the safe side
		for i = fin, idx+1, -1 do -- idx+1 because the entry the idx belongs to must be preserved // in reverse because of removal, otherwise once one field is removed the next will have to be decremeted by one because there'll be one field less in the table
		table.remove(notes_t, i)
		end
	end


-- 4. Include/exclude segment end time stamp depending on the setting

	for k, line in ipairs(notes_t) do
	local st_stamp, fin_stamp, txt = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)')
		if fin_stamp and parse(fin_stamp) ~= 0 and not INCLUDE_END_TIME then -- exclude
		notes_t[k] = line:gsub(' '..fin_stamp,'')
		elseif fin_stamp and #fin_stamp == 0 and INCLUDE_END_TIME and mrkr_t[k+1] then -- include
		local txt = line:match('^'..st_stamp..'(.*)') -- re-capture to preserve leading spaces, if any, because they're not included in the capture above
		notes_t[k] = st_stamp..' '..mrkr_t[k+1].name..txt -- mrkr_t[k+1].name is name of the next marker containing its time stamp which will be accurate after the step 1 above, txt isn't separated by space because all spaces are included in it
		end
	end


-- 5. Remove markers not accounted for in segment entries

	for i=#mrkr_t,1,-1 do
	local pos = mrkr_t[i].name_upd or mrkr_t[i].name
	local match
		for j=#notes_t,1,-1 do
		local st, fin, txt = notes_t[j]:match('^(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)')
			if st and (pos == st or #fin > 0 and pos == fin) then
			match = 1
			break end
		end
		if not match and i < #mrkr_t then -- leaving the last marker intact
		r.DeleteProjectMarker(0, mrkr_t[i].idx, false) -- isrgn false
		table.remove(mrkr_t,i)
		end
	end

-- 6. Merge Notes segment entries, for which there's no corresponding marker, with previous segment entry

	local function time_stamp_valid(t, time_stamp)
		for k, props in ipairs(t) do
			if format_time_stamp(props.pos) == time_stamp
			then return true end
		end
	end

	for i = #notes_t, 1, -1 do -- in reverse because entries may get deleted
		if notes_t[i] then -- may be nil after some fields were merged and deleted
		local st, fin, txt = notes_t[i]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
			if st then
			local st_match, fin_match
				for k, props in ipairs(mrkr_t) do
					if format_time_stamp(props.pos) == st then st_match = 1 end
					if format_time_stamp(props.pos) == fin then fin_match = 1 end
					if st_match and fin_match then break end
				end

				-- both st_match and fin_match may be false if all that was merged were preceding and following gaps
				-- therefore these conditions must not be treated as alternatives through 'if else' statement 
				-- but processed in parallel
				
				if not st_match then -- no marker matching segment start time stamp was found, merge with previous segment entry and delete from the table
				local prev_segm_idx = i > 1 and get_next_or_prev_segm_idx(notes_t, i-1, 2) -- accounting for content and empty lines between segment lines
				local next_segm_idx = i < #notes_t and get_next_or_prev_segm_idx(notes_t, i+1, 1)-- accounting for content and empty lines between segment lines
				local prev_segm, next_segm = notes_t[prev_segm_idx], notes_t[next_segm_idx]
				local st_stamp_prev, fin_stamp_prev, transcr_prev = table.unpack(prev_segm and {prev_segm:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)')} or {})
				local st_stamp_next = next_segm and next_segm:match('^%s*(%d+:%d+:%d+%.%d+)')
				local fin_stamp_repl = i == #notes_t and (parse(fin) ~= 0 and fin or mrkr_t[#mrkr_t].name) or time_stamp_valid(mrkr_t, fin) and fin
				or st_stamp_next or '' -- if merging the very last segment use its end time stamp to replace the end time stamp of the prev segment whenever possible, if absent use last marker time stamp, in all other cases use current segment end time stamp or start time stamp of the next segment, if current segment is followed by a gap the two latter values will differ

				-- update OR add end time stamp in the previous segment entry
					if fin_stamp_prev and parse(fin_stamp_prev) ~= 0 then -- update
					prev_segm = prev_segm:gsub(fin_stamp_prev, fin_stamp_repl) -- replace prev segment end time stamp with the start time stamp of the last valid segment
					elseif fin_stamp_prev and parse(fin_stamp_prev) ~= 0 and INCLUDE_END_TIME then -- add
					prev_segm = st_stamp_prev..' '..fin_stamp_repl..(#transcr_prev > 0 and ' '..transcr_prev:match('%S.*') or '')
					end

				-- add transcribed text from the invalid segment entry and update the prev segment entry in the table
				-- only if prev segment is adjacent to the current, i.e. prev segment end time stamp is identical
				-- to the current segment start time stamp, i.e. they share the same marker, or prev segment end time stamp is absent
				-- or it itself doesn't have a matching marker
					if prev_segm and (#fin_stamp_prev == 0 or fin_stamp_prev == st or not time_stamp_valid(mrkr_t, fin_stamp_prev)) then
					notes_t[prev_segm_idx] = prev_segm..(#txt > 0 and ' '..txt:match('%S.*') or '') -- trimming leading space if any with %S
						-- remove all content between current and previous segment entries including the current one as invalid
						for k = i,prev_segm_idx+1,-1 do
						table.remove(notes_t, k)
						end
					elseif prev_segm and parse(fin_stamp_prev) ~= 0 and fin_stamp_prev ~= st then -- update current segment start time stamp to match prev segment end time stamp if they're different, meaning there's gap between segments, so what's merged is the current segment with the preceding gap
					notes_t[i] = notes_t[i]:gsub(st, fin_stamp_prev)
					end
				end
				
				if parse(fin) ~= 0 and not fin_match then -- there's match for the start time stamp but not for the end time stamp, so update end time stamp of the current segment with the start time stamp of the next segment
				local next_segm_idx = get_next_or_prev_segm_idx(notes_t, i+1, 1) -- accounting for content and empty lines between segment entries
				local st_stamp_next = next_segm_idx and notes_t[next_segm_idx]:match('^%s*(%d+:%d+:%d+%.%d+)')
					if st_stamp_next then
						if not st_match then -- there's a chance that the start time stamp was also updated above, therefore get the updated value
						st = notes_t[i]:match('^%s*(%d+:%d+:%d+%.%d+)')
						end
					notes_t[i] = st..' '..((#fin > 0 or #fin == 0 and INCLUDE_END_TIME) and st_stamp_next)
					..(#txt > 0 and ' '..txt:match('%S.*') or '') -- trimming leading space if any with %S
					end

				end

			end

		end

	end


-- 7. Update the Notes

	if table.concat(notes_t,'\n') ~= cur_notes_init then
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

	if not cur_notes:match('[%w%p]+') then -- Notes are empty, very first run or they were deleted manually
	return format_time_stamp(st)..(INCLUDE_END_TIME and ' '..format_time_stamp(fin) or '')
	end

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- ensures that the last line is captured with gmatch search
	cur_notes = #cur_notes:gsub('[%s%c]','') > 0 and cur_notes..'\n' or cur_notes -- accounting for empty Notes at the very first run
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
	t[#t+1] = line
	end

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

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- ensures that the last line is captured with gmatch search
	cur_notes = cur_notes..'\n'
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
	t[#t+1] = line
	end

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
			break
			elseif st_stamp and format_time_stamp(fin) == st_stamp then
			Delete_Marker_At_Loop_Point(st) -- delete marker at loop start point because that's where it's been inserted
			return 'gap loop'
			end
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
			break
			elseif #fin_stamp > 0 and format_time_stamp(st) == fin_stamp then
			Delete_Marker_At_Loop_Point(fin) -- delete marker at loop end point because that's where it's been inserted
			return 'gap loop'
			end
		end
	end

return #t > t_orig_len and table.concat(t,'\n')

end



function Update_Notes_With_Merged_Segment_Data(cur_notes, st, fin, INCLUDE_END_TIME)
-- st/fin are loop start/end time in sec

	local function get_next_or_prev_segm_idx_idx(t, start_idx, mode)
	local nxt, prev = mode == 1, mode == 2
	local st, fin, dir = table.unpack(nxt and {start_idx, #t, 1} -- ascending , next segment
	or prev and {start_idx, 1, -1}) -- descending, previous segment
		if st then
			for i=st,fin,dir do
				if t[i]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)')
				then return i
				end
			end
		end
	end

	local function get_diff_start_fin_indices(t, start_idx, fin_idx)
	local cnt = 0
		for i=fin_idx,start_idx,-1 do
			if t[i]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') then
			cnt = cnt+1
			end
		end
	return cnt
	end

	if not cur_notes:sub(-1):match('\n') then -- OR cur_notes:sub(-1) ~= '\n' -- ensures that the last line is captured with gmatch search
	cur_notes = cur_notes..'\n'
	end

-- table is used to be able to detect last track Notes entries to update accordingly
local t = {}
	for line in cur_notes:gmatch('(.-)\n') do
	t[#t+1] = line
	end

local st, fin = format_time_stamp(st), format_time_stamp(fin)
Msg(st, 'loop st') Msg(fin, 'loop fin')
local st_idx, fin_idx

	for k, line in ipairs(t) do
	local st_stamp, fin_stamp = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
		if st_stamp and st == st_stamp then -- data of the segment to merge into has been found
		st_idx = k -- index of the segment into which the rest will be merged
			if #fin_stamp > 0 and r.parse_timestr(fin_stamp) ~= 0 then
				if fin == fin_stamp then return end -- abort if loop segment start/end time stamp match loop start/end points meaning that the loop points are set to an existing segment // this is relevant for segments followed by gaps, that is when the segment end time stamp doesn't appear in the Notes as start time stamp of any other segment which results in loop end point not being found in the Notes and Notes being trimmed up to the segment whose start time stamp matches loop start point due to this expression below 'fin_idx = st_idx and (fin_idx or #t)'
			t[k] = line:gsub(fin_stamp, fin) -- update segment end time stamp with loop end point time
			end

		elseif fin_stamp and st == fin_stamp then -- loop start point is set to the segment end marker followed by a gap between segments, meaning the gap has to be merged with the next segment, BUT the loop end point may be set to the next segment start marker, i.e. the gap between segments, in which case there's nothing to merge so an error message will be returned OR it may be set to the next segment, ADJACENT to the current one, i.e. next start time stamp = current end time stamp, in which case there's nothing to merge either
		st_idx = #t > k and get_next_or_prev_segm_idx_idx(t, k+1, 1) -- mode arg is 1 - next; get index of the segment which follows the current one, i.e. next, if any, into which the rest will be merged // the function is employed instead of simple incremention of k by 1 because the table may contain metadata, user comments and empty lines between segment lines

			if st_idx then -- there's next segment
			local st_stamp_next, fin_stamp_next = t[st_idx]:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)')
				if fin == st_stamp_next then -- the loop is set to a gap between markers which is an invalid selection
				return 'gap loop'
				elseif fin_stamp_next and fin == fin_stamp_next and fin_stamp == st_stamp_next then return -- the loop points are actially set to the next segment, adjacent to the current one, whose detection has been foreshadowed by current condition because it evaluates loop start against end time stamp which in the loop precedes the identical start time stamp of the next segment, so abort
				elseif st_stamp_next ~= fin_stamp then -- fin time stamp of current segment differs from the start time stamp of the next segment meaining there's gap between segments, update next segment start time stamp to remove gap
				t[st_idx] = t[st_idx]:gsub(st_stamp_next, fin_stamp)
				end
			-- if the loop end is set to the next segment end marker, return Notes to update them with the next segment start time stamp because there's no content to merge, only to update the next segment bounds
			local st_stamp_next, fin_stamp_next = t[st_idx]:match('^%s*(%d+:%d+:%d+%.%d+) (%d+:%d+:%d+%.%d+)')
				if fin_stamp_next and fin == fin_stamp_next then
				return table.concat(t, '\n')
				end
			end

		elseif st_stamp and fin == st_stamp then -- data of the last segment to be merged has been found
			if st_idx and get_diff_start_fin_indices(t, st_idx, k) == 2 then -- employing function instead of a simple methematical comparison to account for possible data and empty lines between segments // 2 because first and last segments are counted
			-- if difference between indices of the segments whose start time stamps match the loop start and end points is 1 meaning they follow each other so there's nothing to merge, there're two possibilities: if there's gap between them, this means that the end marker of the earlier segment was removed and the segments have become adjacent therefore the end time stamp of the earlier segment, if any, must be set to the start time stamp of the later segment and the Notes have to be updated
			-- if there's no gap, this condition is relevant for cases when there's no end time stamp at least in the segment whose start time stamp matches loop start point, this will result in the 'remove data' loop below not starting because st_idx will be incremented by 1 and end up being greater than the loop start point in the reverse loop, e.g. i=1,2,-1, BUT the function will still return the Notes unmodified which will not trigger the error message in the PROCESS_SEGMENTS() function hence must be aborted; another condition to abort in this case could be 'if st_idx == fin_idx' after this loop because by that point they will be equal due to deduction of 1 from closing segment table index on the next line
			local line = t[st_idx] -- get start segment
			local st_stamp_prev, fin_stamp_prev = line:match('^%s*(%d+:%d+:%d+%.%d+) (%d+:%d+:%d+%.%d+)')
				if fin_stamp_prev and fin_stamp_prev == st_stamp then return table.concat(t, '\n') -- fin time stamp of the first found segment was updated earlier in this loop when it was found
				elseif not fin_stamp_prev and INCLUDE_END_TIME then
				local st_stamp_prev, transcr = line:match('^%s*(%d+:%d+:%d+%.%d+)(.*)')
				t[st_idx] = fin_stamp_prev and line:gsub(fin_stamp_prev, st_stamp) or st_stamp_prev..' '..st_stamp..transcr
				return table.concat(t, '\n')
				end
			return end -- no earlier segment end time stamp update was needed, the loop points where set to the existing segment bounds

		fin_idx = get_next_or_prev_segm_idx_idx(t, k-1, 2) -- mode 2 - previous; get index of the last segment to be merged // the function is employed instead of simple deduction of 1 from k because the table may contain metadata, user comments and empty lines between segment lines

		break -- once last segment to be merged has been found exit to stop merging segments

		elseif fin_stamp and fin == fin_stamp then
		fin_idx = k -- index of the last segment to be merged
		-- merge here because since this is the last segment to be merged the loop will be exited here so no chance to merge further below in the loop
		local st_stamp, fin_stamp, transcript = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
		t[st_idx] = t[st_idx]..' '..(transcript and transcript:match('%S.*') or '')--:gsub('[\n\r]+','') -- trimming leading space if any with %S
		break

		elseif st_stamp and fin < st_stamp then -- accommodates cases where loop end point is set to a marker not accounted for in the Notes
		-- this is a corner case because such non-accounted for marker must be valid in terms of this script, i.e. contain time stamp in the proper format in its name, which isn't very likely, mostly relevant for transcript without end time stamps; the relational operator does work with time stamp strings on the basis of alphabetical order which matches digit ascending order from the smallest to the greatest, but for this to work the strings must have the same number of elements, i.e. '2' < '15' is false but '02' < '15' is true while '02' < '015' is again false https://www.lua.org/pil/3.2.html
		return 'non-accounted for end'
		elseif st_idx and k > st_idx then -- keep merging segments content; 'k > st_idx' enures that if loop start point is set to the a segment end marker, the merger will only begin once the loop advances to the segment which follows the one whose start time stamp was updated above
		local st_stamp, fin_stamp, transcript = line:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
			if st_stamp then
			t[st_idx] = t[st_idx]..' '..(transcript and transcript:match('%S.*') or '')--:gsub('[\n\r]+','') -- trimming leading space if any with %S
			end

		end

	end

	if not st_idx then
	return 'non-accounted for start' end -- loop start point is set to a marker not accounted for in the Notes, corner case, see reasoning behind 'non-accounted for end' within the loop above

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

	if #cur_notes:gsub('[%s%c]','') == 0 and not OPEN_TRACK_NOTES then -- no Notes content and the user setting isn't enabled
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
	return {[1]={tr=tr, name=name, idx='1'}}, '' -- empty string for not existing notes
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


function Update_Track_Notes(tr_t, notes_upd, NOTES_TRACK_NAME, SELECT_TRACK_OF_UPDATED_NOTES, st)
-- tr_t comes from Get_Notes_Tracks_And_Their_Notes()
-- notes_upd comes from inside PROCESS_SEGMENTS() or Match_Notes_To_Markers_Props()
-- SELECT_TRACK_OF_UPDATED_NOTES is only used inside PROCESS_SEGMENTS()
-- st is loop start points, only used inside PROCESS_SEGMENTS()
-- ommitted inside Match_Notes_To_Markers_Props()
-- because there's no need to select a secific track

	local function store_track_ext_state(tr, notes, cntr, NOTES_TRACK_NAME)
	-- store Notes start and end time stamps per Notes track
	-- to use them as a reference for selecting the Notes track
	-- depending on the name of the marker at the edit cursor with script
	-- BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
	-- index is stored to use for sorting inside folder with Create_And_Maintain_Folder_For_Note_Tracks()
	local st_stamp, end_stamp = notes:match('(%d+:%d+:%d+%.%d+)'), notes:match('.*(%d%d:%d+:%d+%.%d+).*$') -- get first segment start time stamp and last segment end time stamp; end_stamp will capture either last segment end time stamp, if any, or its start time stamp, %d%d is used because otherwise only the second digit if hours is captured // start anchor ^ has been removed from st_stamp pattern to accommodate non-segment content preceding the first segment entry
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, cntr..' '..st_stamp..' '..end_stamp, true) -- setNewValue true
	end

	if not notes_upd:sub(-1):match('\n') then -- OR notes_upd:sub(-1) ~= '\n' -- ensures that the last line is captured with gmatch search
	notes_upd = notes_upd..'\n'
	end

-- construct table including non-segment content linked to a segment entry
-- and the segment entry itself inside the same table field
-- this is meant to prevent separating segment entry and non-segment data linked to it
-- when splitting Notes between multiple tracks
local notes_t, segment, new = {}, '', 1
	for line in notes_upd:gmatch('(.-)\n') do
		if line:match('^%s*%d+:%d+:%d+%.%d+') then -- segment entry, dump its content with non-segment data into the table
		notes_t[#notes_t+1] = segment..(#segment == 0 and '' or '\n')..line -- if segment var is empty because segment entries follow each other, don't precede line var with line break char because it'll be the first line of the new segment
		segment = '' -- reset for the next cycle
		new = 1 -- set for the next cycle
		else -- accrue non-segment content, if any			
		segment = segment..(#segment == 0 and new and '' or '\n')..line -- if segment var is empty don't precede line var with line break char because it'll be the first line of the new segment, 'new' var is meant to limit the expression to the very first line of the next segment content, because if such first line is an empty line of non-segment content, it will produce #segment == 0 on the next loop cycle as well and cause loss of the necessary line break which it would have to be followed by in the next cycle
		new = nil -- reset
		end
	end

local notes, cntr, st, targ_tr, tr = '', 0, st and format_time_stamp(st)

	for k, segment in ipairs(notes_t) do
		if #(notes..(#notes == 0 and '' or '\n')..segment) > 16383 then -- dump what has been accrued so far if adding new line will cause overshooting the limit, using 16383 instead of 65535 as a limit to provide for manual edits (especially in case the segment transcripts only begin to be added after segment creation, the transcript is projected to be on average 4 times longer than the start and end time stamps, hence 16383 because 16383 x 4 = 65532) which otheriwise would likely be prevented by the limit
		cntr = cntr+1
		tr = tr_t[cntr] and tr_t[cntr].tr or insert_new_track(cntr..' '..NOTES_TRACK_NAME) -- either use existing track or insert a new
		r.NF_SetSWSTrackNotes(tr, notes)
		store_track_ext_state(tr, notes, cntr, NOTES_TRACK_NAME)
			if not targ_tr and st then
				if notes:match('\n%s*'..st) or notes:match(st..'.-%s*%d+:%d+:%d+%.%d+') -- first look for match in start time stamp, then look in end time stamp of the previous segment line accounting for intervening non-segment content; new line char because notes var contains all track notes so start anchor ^ won't work
				then
				targ_tr = tr -- store track whose Notes contain the change, which will necessarily be associated with loop start point, in order to select it inside PROCESS_SEGMENTS() thereby focusing for Notes display
				elseif tr_t[cntr-1] and r.NF_GetSWSTrackNotes(tr_t[cntr-1].tr):match(st) then -- if not found in current track notes, look in the previous where it will match segment end time stamp
				targ_tr = tr_t[cntr-1].tr
				end
			end
		notes = segment -- re-start accrual
		else -- keep accruing the string until it reaches the length of 40928 bytes
		notes = notes..(#notes == 0 and '' or '\n')..segment -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
		end
	end

	if #notes:gsub('[%s%c]','') > 0 then -- if notes var wasn't reset because by the end of the loop it hasn't accrued enough content
	tr = tr_t[cntr+1] and tr_t[cntr+1].tr or insert_new_track((cntr+1)..' '..NOTES_TRACK_NAME) -- either use existing track or insert a new
	r.NF_SetSWSTrackNotes(tr, notes)
	store_track_ext_state(tr, notes, cntr+1, NOTES_TRACK_NAME)
		if not targ_tr and st then
			if notes:match('\n%s*'..st) or notes:match(st..'.-%s*%d+:%d+:%d+%.%d+') -- first look for match in start time stamp, then look in end time stamp of the previous segment line accounting for intervening non-segment content; new line char because notes var contains all track notes so start anchor ^ won't work
			then
			targ_tr = tr -- store track whose Notes contain the change, which will necessarily be associated with loop start point, in order to select it inside PROCESS_SEGMENTS() thereby focusing for Notes display
			elseif tr_t[cntr-1] and r.NF_GetSWSTrackNotes(tr_t[cntr-1].tr):match(st) then -- if not found in current track notes, look in the previous where it will match segment end time stamp
			targ_tr = tr_t[cntr-1].tr
			end
		end
	end

	local function get_selected_notes_track(tr_t)
		for k, data in ipairs(tr_t) do
			if r.IsTrackSelected(data.tr) then return data.tr end
		end
	end

return SELECT_TRACK_OF_UPDATED_NOTES and targ_tr or get_selected_notes_track(tr_t) or tr_t[1].tr -- return track to which belong Notes affected by the update if the setting is enabled, if the setting isn't enabled or not found for any reason return the first selected Notes track, if no selected return first Notes track

end



function Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
-- single depth folder
-- only runs when notes get updated inside PROCESS_SEGMENTS() and in Batch update routine
-- doesn't run when error message is thrown by the script

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
		--	idx2 = idx
			parent_tr = parent
--Msg('PARENT')
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


function Delete_Marker_At_Loop_Point(pos)
r.UpdateTimeline()
	if pos then
	local mrkr_idx = r.GetLastMarkerAndCurRegion(0, pos)
		if mrkr_idx > -1 and ({r.EnumProjectMarkers3(0, mrkr_idx)})[3] == pos then
		r.DeleteProjectMarkerByIndex(0, mrkr_idx)
		end
	end
return true -- only needed for ternary expression inside PROCESS_SEGMENTS()
end



function PROCESS_SEGMENTS(tr, INCLUDE_END_TIME, SELECT_TRACK_OF_UPDATED_NOTES)

local st, fin = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, start, end 0, allowautoseek false

	if st == fin then
	Error_Tooltip("\n\n loop points aren't set \n\n", 1, 1) -- caps, spaced true
	return end

local st_mrkr, fin_mrkr, last_mrkr_pos = Insert_Or_Update_Markers_At_Loop_Points(st, fin) -- return values st_mrkr, fin_mrkr can be either 1 (new marker has been inserted at the corresponding loop point), a string (there's an existing marker at the corresponding loop point, the string contains marker old time stamp before adjustment to match actual marker position), -1 (there's an existing marker at the corresponding loop point), nil if marker coinciding with the loop start/end point is not a segment marker (doesn't contain a time stamp in its name) in which case new segment entry in the Notes won't be created

	if st_mrkr == 0 then -- loop points cross segment delimiter, i.e. a project marker, which is disallowed
	return end

local tr_t, cur_notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

	if not cur_notes:match('[%w%p]+') and st_mrkr ~= 1 and fin_mrkr ~= 1 then -- Notes are empty and not new segment creation operation which could go through when notes are empty because it adds a new entry and doesn't modify the existing ones
	local delete = st_mrkr == 1 and Delete_Marker_At_Loop_Point(st)
	local delete = fin_mrkr == 1 and Delete_Marker_At_Loop_Point(fin)
	Error_Tooltip("\n\n track notes are empty \n\n", 1, 1) -- caps, spaced true
	return end

local parse = r.parse_timestr

-- store last marker position in the first Notes track, marked 1, to use inside Format() function
-- of BuyOne_Transcribing A - Format converter.lua script
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

	if st_mrkr and fin_mrkr and (st_mrkr == 1 or fin_mrkr == 1) then -- add new entry

	-- INSERT NEW SEGMENTS WITHIN EXISTING ONE, BEFORE THE FIRST OR AFTER THE LAST NON-AJACENT TO THEM
	cur_notes_upd = st_mrkr == 1 and fin_mrkr == 1 and Update_Notes_With_New_Segment_Data(cur_notes, st, fin, INCLUDE_END_TIME) -- two brand new markers have been inserted, a new segment has been delimited either within existing one of outside of all without being adjacent to the first or the last

	undo = 'Insert new segment and update SWS Track Notes'

		if not cur_notes_upd then -- either loop start or end point conicides with project markers, normally when a new segment adjacent to the last on the right or to the first on the left has been delimited

		---------- Addressing corner cases of loop points being set to markers not reflected in segment props --------
		cur_notes_upd = st_mrkr == -1 and not cur_notes:match(format_time_stamp(st)) and Delete_Marker_At_Loop_Point(fin)
		and 'non-accounted for start'
		or fin_mrkr == -1 and not cur_notes:match(format_time_stamp(fin)) and Delete_Marker_At_Loop_Point(st)
		and 'non-accounted for end'

			if not cur_notes_upd then

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
	else -- some markers have been deleted - merge segments // st_mrkr and fin_mrkr are both -1, loop points are set to existing segment markers

	cur_notes_upd = Update_Notes_With_Merged_Segment_Data(cur_notes, st, fin, INCLUDE_END_TIME)

	undo = 'Merge segment entries in the SWS Track Notes'

	end

local function s(int) return (' '):rep(int) end
local point = cur_notes_upd and cur_notes_upd:match('^non%-accounted for ')
and (cur_notes_upd:match('start') and s(3)..'the loop start' or s(4)..'the loop end')
local err = cur_notes_upd == 'gap loop' and '\t loop points are set\n\n   to a gap between segments\n\n which is an invalid selection'
or point and '\t'..point..' point\n\n\t     is set to a marker\n\n not associated with any segment'

	if cur_notes_upd and not err then
	local tr = Update_Track_Notes(tr_t, cur_notes_upd, NOTES_TRACK_NAME, SELECT_TRACK_OF_UPDATED_NOTES, st)
	r.SetOnlyTrackSelected(tr) -- the Notes are loaded from a selected track
	r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
	r.SetCursorContext(0) -- 0 is TCP // NOTES WINDOW DOESN'T SWITCH TO THE TRACK WITH NOTES IF THE WINDOW WAS THE LAST CLICKED BEFORE RUNNING THE SCRIPT
	Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
	return undo, tr -- tr is passed to Scroll_SWS_Notes_Window() if SELECT_TRACK_OF_UPDATED_NOTES setting is enabled
	elseif st_mrkr == -1 and st_mrkr == fin_mrkr -- when merging
	or err then -- when splitting
	err = err or "no change in marker properties \n\n\tto warrant Notes update. \n\n"
	.."   If you're sure there's change\n\n    try batch update technique."
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
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
'SELECT_TRACK_OF_UPDATED_NOTES','KEEP_MARKERS_LOCKED','SAVE_PROJECT_EVERY_SCRIPT_RUN'}
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
..menu_sett[2]..'Open track notes at each script run||'..menu_sett[3]..'&Select track of updated Notes||'
..menu_sett[4]..'&Keep markers locked||'..menu_sett[5]..'Save &project every script run|||&View Help||'..pad(22)

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return 1 end -- 1 i.e. truth will trigger script abort to prevent activation of the main routine when menu is exited

	if output < 2 or output > 7 then goto RELOAD end

	if output == 7 then
	r.ShowConsoleMsg(table.concat(help_t,'\n'):match('(.+)%]%]'),r.ClearConsole())
	return 1 end -- 1  i.e. truth will trigger script abort to prevent activation of the main routine when menu is exited

output = output-1 -- offset the 1st menu item which is a title
local src = user_sett[output]
local sett = menu_sett[output] == '!' and '' or '1' -- fashion toggle
local repl = src..' = "'..sett..'"'
local cur_settings = table.concat(sett_t,'\n')
local upd_settings, cnt = cur_settings:gsub(src..'%s*=%s*".-"', repl, 1)

	if cnt > 0 then -- settings were updated, get script
	local f = io.open(scr_name,'r')
	local cont = f:read('*a')
	f:close()
	src = Esc(cur_settings)
	repl = upd_settings:gsub('%%','%%%%')
	cont, cnt = cont:gsub(src, repl)
		if cnt > 0 then -- settings were updated, write to file
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


OPEN_TRACK_NOTES = #OPEN_TRACK_NOTES_AT_EACH_SCRIPT_RUN:gsub(' ','') > 0 -- also relied upon inside Toggle_Show_SWS_Notes_Window()

	if OPEN_TRACK_NOTES then
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


SELECT_TRACK_OF_UPDATED_NOTES = #SELECT_TRACK_OF_UPDATED_NOTES:gsub(' ','') > 0
INCLUDE_END_TIME = #INCLUDE_END_TIME:gsub(' ','') > 0
KEEP_MARKERS_LOCKED = #KEEP_MARKERS_LOCKED:gsub(' ','') > 0
SAVE_PROJECT_EVERY_SCRIPT_RUN = #SAVE_PROJECT_EVERY_SCRIPT_RUN:gsub(' ','') > 0

	if st == fin then -- no loop points, match the transcript to the current marker array in a batch
	local retval, mrkr_cnt, reg_cnt = r.CountProjectMarkers(0)
		if mrkr_cnt == 0 then
		Error_Tooltip('\n\n no markers in the project \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end
	local end_time = '\n\n        Segment end time stamp \n\n     will be '
	end_time = INCLUDE_END_TIME and end_time..'included where absent.'
	or end_time..'excluded where present.'
	local resp = r.MB('    Clicking OK will allow the script\n\n          to match the transcript'
	..'\n\n       to the markers properties.'..end_time..'\n\n     The project will be saved first\n\n'
	..'    in case something goes wrong.', 'PROMPT', 1)
		if resp == 2 then -- cancelled
		return r.defer(no_undo)
		end
	Error_Tooltip("\n\n the process is underway... \n\n", 1, 1) -- caps, spaced true
	r.Undo_BeginBlock()
	local notes_wnd, scroll_pos = GetSet_Notes_Wnd_Scroll_Pos() -- precede Match_Notes_To_Markers_Props() because notes update resets scroll pos
	Match_Notes_To_Markers_Props(INCLUDE_END_TIME)
	Create_And_Maintain_Folder_For_Note_Tracks(NOTES_TRACK_NAME)
	Toggle_Markers_Lock(KEEP_MARKERS_LOCKED)
	GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos)
	r.Undo_EndBlock('Transcribing A: Match the transcript to the marker array', -1)
	Error_Tooltip("") -- caps, spaced true -- undo the 'process underway' tooltip
	return end


r.Undo_BeginBlock()

local notes_wnd, scroll_pos = GetSet_Notes_Wnd_Scroll_Pos() -- precede PROCESS_SEGMENTS() because notes update resets scroll pos // Get

local undo, tr = PROCESS_SEGMENTS(tr, INCLUDE_END_TIME, SELECT_TRACK_OF_UPDATED_NOTES)

	if not undo then
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) end

Toggle_Markers_Lock(KEEP_MARKERS_LOCKED)

r.Undo_EndBlock('Transcribing A: '..undo, -1)

GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos)

local save = SAVE_PROJECT_EVERY_SCRIPT_RUN and r.Main_SaveProject(0, false) -- forceSaveAsIn false


	if SELECT_TRACK_OF_UPDATED_NOTES then
	local notes_wnd = Find_Window_SWS('Notes', want_main_children) -- want_main_children nil
	Scroll_SWS_Notes_Window(notes_wnd, format_time_stamp(st), tr)
	-- unlike in BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
	-- here execution of Scroll_SWS_Notes_Window() doesn't need to be delayed with a defer loop
	-- probably because this script runs longer giving enough time for the window to load
	-- and be successfully affected by scroll position change
	else -- will only run if js extension is installed
	GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos) -- Set
	end



	
