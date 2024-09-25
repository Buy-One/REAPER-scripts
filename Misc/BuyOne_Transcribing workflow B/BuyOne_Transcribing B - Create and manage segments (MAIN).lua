--[[
ReaScript name: BuyOne_Transcribing B - Create and manage segments (MAIN).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing B workflow set of scripts
	alongside  
	BuyOne_Transcribing B - Real time preview.lua  
	BuyOne_Transcribing B - Format converter.lua  
	BuyOne_Transcribing B - Import SRT or VTT file as regions.lua  
	BuyOne_Transcribing B - Prepare transcript for rendering.lua  
	BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
	BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
	BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua

	This is the main script of the set geared towards segment 
	manipulation: creation, boundaries change, split, merger.
	
	This workflow implies that actual transcript will be created
	inside 'Region/Marker Manager'. To set it up for the workflow
	have the Ruler time unit set to Minutes:Seconds so that regions
	time data shown in the Manager is denominated in  
	hours:minutes:seconds.milliseconds.  
	This will allow to quickly navigate between segments by simply 
	clicking their region entries in the Manager. 	

	The script identifies segment regions by color defined in
	the SEGMENT_REGION_COLOR setting of the USER SETTINGS. All
	regions colored differently are ignored.  
	Color coding allows turning segments off by changing color
	of their region.  
	To turn them back on the segment region designated color must 
	be restored, see par. D in the chapter  
	OPERATIONS PEFRORMED BY THE SCRIPT below.  
	If you have regions colored differently in your project, in the
	Region/Marker Manager the segment regions can be grouped together
	by clicking the color column.			
	
	
	THE MEDIA ITEM WHOSE CONTENT NEEDS TO BE TRANSCRIBED MUST 
	BE LOCATED AT THE VERY PROJECT START FOR THE SEGMENT TIME STAMPS 
	TO BE ACCURATE BECAUSE TIME IS COUNTED FROM THE PROJECT START
	RATHER THAN FROM THE MEDIA ITEM START.  
	PROJECT TIME BASE MUST BE SET TO TIME SO THAT THE MEDIA ITEM
	AND REGIONS LENGTH AND LOCATION ARE INDEPENDENT OF PROJECT TEMPO.
	
	If your aim is to transcribe for SRT/VTT formats be aware that
	their support by this set of scripts is very basic. When the
	transcript is converted into these formats with the script
	'BuyOne_Transcribing B - Format converter.lua' all textual 
	data which follow the time stamps are moved to the next line, 
	regardless of their nature as if all of them where meant to be 
	displayed on the screen. For VTT format, data between segment
	lines can be retained at conversion which is useful for keeping
	comments, region data etc., if any, but garbage as well because 
	the conversion script doesn't analyze such data.
	
	Every time the script is executed it resolves overlapping segment
	regions, if any.
	
	
	► OPERATIONS PEFRORMED BY THE SCRIPT 

	● A. Segment creation
	
	1. Manually set loop points over the audio segment to be transcribed.  
	2. Run the script to create segment region.  
	3. Tanscribe using Region/Marker manager to input text into relevan
	region name field.
	
	To create next segment, in builds older than 7.19 the following 
	custom action may be used (included with the script set in the 
	file 'Transcribing workflow custom actions.ReaperKeyMap' )  
	while the loop points are set to the previous segment bounds:
	
	Custom: Transcribing - Shift loop right by the loop length (loop points must already exist)  
	  Time selection: Copy loop points to time selection  
	  Time selection: Shift right (by time selection length)  
	  Time selection: Copy time selection to loop points  
	  Time selection: Remove (unselect) time selection  
	  
	or since build 7.19 the actions
	'Loop points: Move start point to cursor (preserve length)'
	'Loop points: Move end point to cursor (preserve length)'
	then manually adjust loop start/end points as needed and run 
	the script again, and so on.
	
	To set loop points to a region either double click the Ruler 
	within region (default mouse modifier action of the Ruler context)
	or double click the region bar, or run the action 
	'Regions: Set loop points to current region' (since REAPER build 7.10) 
	or run the following custom action which works for regions as well
	(included with the script set in the file 
	'Transcribing workflow custom actions.ReaperKeyMap' ):
	
	Custom: Transcribing - Create loop points between adjacent project markers (place edit cursor between markers or at the left one)
	  Time selection: Remove (unselect) time selection and loop points  
	  View: Move cursor right 8 pixels  
	  Markers: Go to previous marker/project start  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Markers: Go to previous marker/project start
	
	
	Watch demo 'Transcribing B - 1. Segment creation.mp4' which 
	comes with the set of scripts
	
	Rules:
	New segment regions can be created outside of existing segment 
	regions or between them. Loop points can coincide with segment
	regions start/end as long as the loop line is not enclosed within
	a region. New segment regions cannot be created within the existing 
	segment regions or across them. During all operations this script
	is designed to perform except coloring (see par. D below) non-segment 
	regions are ignored as if they don't exist so the above rules don't 
	apply to them.

	
	● B. Splitting segments
	
	Existing segments can be split, for this purpose:
	
	1. Set loop points to a segment region using methods described in
	the par. A above.
	2. Manually adjust either start or end point of the loop moving it 
	right or left respectively (the stationary loop point must remain 
	coinciding with start/end of the segment region).
	3. Run this script.

	As a result the time span which was previously covered by a single 
	segment region will now be covered by two.
	
	Watch demo 'Transcribing B - 2. Splitting segments.mp4' which comes 
	with the set of scripts

	
	● C. Merging segments
	
	Existing segments can be merged, for this purpose:
	
	1. Set loop points such that both are located within different
	regions or coincide with their start/end.
	2. Run this script.
	
	As s result all segment regions encompassed by the loop points 
	except the very first will be deleted while the first one will 
	be extended up to the end of the last deleted segment region.  
	The transcript of the deleted segments (if any) will be merged 
	with the transcript of the segment represented by the first 
	region covered by the loop points.
	
	Watch demo 'Transcribing B - 3. Merging segments.mp4' which comes 
	with the set of scripts
	
	
	● D. Coloring non-segment region
	
	1. Set loop points to a non-segment region start/end.
	2. Run the script.
	
	After coloring such region becomes a valid segment region and
	will be recognized by this script.  
	This functionality also allows turning on a segment region after
	it was turned off by color change.
	
	If not both loop points are set to the non-segment region 
	boundaries the script will create a new segment region instead.
	
	If the targeted non-segment region happens to be overlapped by 
	a segment region the script will focus on the latter and either 
	perform operations B and C or will display an error message.  		
				
	Watch demo 'Transcribing B - 4. Coloring non-segment region.mp4' 
	which comes with the set of scripts
	
	
	At each run the script resolves overlapping segment regions
	if there're any.
	
	
	● E. Displaying this text
	
	In order to display this 'About' text in the ReaScript console
	for reference, place the edit cursor within a segment region,
	clear the loop points and run the script.
	
	
	------------------------------------------
	
	► NEW LINE TAG
	
	The trascript supports new line tag <n> to effect creation of a new
	line for the text which follows the tag during transcript preview 
	within video context with the script
	'BuyOne_Transcribing B - Real time preview.lua'.
	and during its conversion into SRT format with the script 
	'BuyOne_Transcribing B - Import SRT or VTT file as markers and Notes.lua'
	the tag is supported for SRT and VTT output formats. During conversion 
	into AS IS format the tag will be deleted if present. The tag can be 
	preceded and followed by spaces which will be trimmed at conversion.
		

	► ADDITIONAL WORKFLOW AIDS
	
	Disable 'Snap to grid' to be able to mark out a segment with 
	loop points or adjust a segment region bount with greater precision. 
	Or hold Ctrl/Cmd when creating/adjusting loop points and Shift when 
	adjusting region bounds to temporarily disable snapping.
	
	When creating/managing multiple segments back to back it's very 
	convenient to set this script armed by right clicking the 
	toolbar button it's linked to and simply click on the Arrange 
	canvas to run the script.
	
	To focus on auditioning a segment:  
	
	1. Enable the following actions:  
	Transport: Toggle stop playback at end of loop if repeat is disabled (available since build 4.30)  
	OR  
	Xenakios/SWS: [Deprecated] Toggle stop playback at end of loop  
	2. Set loop points to a segment using methods described in par. A above.  
	3. Hit Play to audition, at the end of the loop the play cursor will  
	return to the original position.
				
	To stop playback in the middle of the segment use  
	EITHER  
	Transport: Play/pause  
	OR  
	Transport: Pause		
	
	To navigate between segment regions for auditioning or preview
	within video context with 'BuyOne_Transcribing B - Real time preview.lua' 
	script when the transport is stopped use the following custom 
	actions which also work for regions (included with the script 
	set in the file 'Transcribing workflow custom actions.ReaperKeyMap' ):
	
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
	
	To navigate to a segment at a particular time displayed
	in the Start and End columns of the Region/Marker Manager 
	click the region entry of such segment in the Manager 
	having its option 
	'Seek playback when selecting a marker or region' enabled.			 
	This can be followed by the action 
	'Regions: Set loop points to current region' available since
	REAPER 7.10 to set loop points to the selected region, and in 
	earlier builds - by custom action from par. A above namely  
	'Custom: Transcribing - Create loop points between adjacent project markers',
	and in most builds by double clicking the Ruler within region 
	or the region bar directly.  
	Or more conveniently enable the option  
	'Play region through then repeat or stop when selecting a region'.
	so that loop points are set to the region and it starts playing 
	automatically when selected in the Manager.
	
	To set the edit cursor to region start directly in Arrange 
	if Snap is disabled run the action  
	'Markers: Go to previous marker/project start'  
	after placing the edit cursor within the target region 
	to prime the edit cursor for the action. The action can be 
	run with a shortcut or bound to a mouse modifier in context 
	such as 'Ruler (double)click'. Alternatively, to obviate 
	clicking, instead of the raw action use the following custom 
	action running it with a shortcut:  
	
	Custom: Move edit cursor to marker left of the mouse cursor
	  View: Move edit cursor to mouse cursor (no snapping)
	  Markers: Go to previous marker/project start			  
	
	To find a particular segment region in the Region/Marker Manager
	copy its transcript and paste into the Manager filter field
	or use the scripts   
	'BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua'
	included in the script set which obviate manual copying
	of the region transcript.
	
	To clear loop points run the action  
	'Loop points: Remove (unselect) loop point selection'
	or Ctrl+Alt/Cmd+Opt + click the Ruler (default mouse modifier).
	That's unless the option 'Loop points linked to time selection'
	is enabled (default) in which case the loop points can be cleared
	along with the time selection using Esc (default shortcut).
	
	The segments transcript can be managed in the SWS Extension Notes 
	utility rather than in the Region/Marker Manager. In the Notes 
	utility drop down menu select 'Region names'. Place the edit
	cursor within the segment region bounds so its text is displayed 
	in the Notes. Adding or changing it in the notes is immediately 
	reflected in the region bar in Arrange. The result of operations
	such as segments splitting and merging is conveniently reflected 
	in the Notes.
	
	
	If after you started your project you need to move the transcript
	media source later or earlier (after trimming from the beginning)
	on the time line in order to lengthen/shorten the time between the 
	media start and the transcribed content start within the media 
	(remember, that transcript segments time stamp will only be 
	accurate if the media starts at and is rendered from the project 
	start) you can:
	
	A. 
	1. Enable 'Ripple edit all tracks'.  
	2. Ensure that the media item spans all segment regions otherwise 
	the feature won't work.  
	3. Change the position of the media item by dragging it and the 
	regions will follow.
	
	B. After moving the media item take advantage of the script  
	'BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua'
	included in the script set.
	
	In both cases after regions positions have been changed run this 
	script in Batch segment update mode (see par. F above) in order 
	to update segment time stamps in the regions names and in track Notes.
	
	
	
	► CONVERSION BETWEEN PROJECTS
	
	To convert between Transcribing B and A workflow projects export 
	the source project as an SRT or VTT file and import it back into 
	REAPER using the scripts  
	'BuyOne_Transcribing B - Format converter.lua' to export and
	'BuyOne_Transcribing A - Import SRT or VTT file as regions.lua'
	to import, or vice versa  
	'BuyOne_Transcribing A - Format converter.lua'
	'BuyOne_Transcribing B - Import SRT or VTT file as regions.lua'
	depending on the direction of conversion.	 
	If transcript of Transcribing A workflow source project contains 
	metadata meant to be exported in VTT format, it will be lost as 
	a result of import with 
	'BuyOne_Transcribing B - Import SRT or VTT file as regions.lua'
	script because Transcribing B workflow doesn't support metadata.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes specify HEX color either preceded
-- or not with hash # sign, can consist of only 3 digits
-- if they're are repeated, i.e. #0fc;
-- MUST DIFFER FROM THE THEME DEFAULT REGION COLOR;
-- since region color may not mix well with region
-- text color you may have to tweak the 'Region text'
-- setting in the 'Theme development/tweaker' dialogue,
-- which however will apply to regions globally;
-- default setting is #b564a6
SEGMENT_REGION_COLOR = "#b564a6"


-- Enable by insetring any alphanumeric character between
-- the quotes to have regions locked after each script run;
-- this setting will prevent free movement of segment regions
-- manually in case their position needs to be updated
-- which could be annoying
KEEP_REGIONS_LOCKED = ""


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



function Insert_Or_Update_Region_At_Loop_Points(st, fin, reg_color)

local i = 0
local first_reg_st, last_reg_end, cross_loop
local rgn_t = {}
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0,i)
		if retval > 0 and isrgn and color == reg_color then
		first_reg_st = first_reg_st or pos
		last_reg_end = rgnend
		cross_loop = cross_loop or st < pos and fin > pos or st < rgnend and fin > rgnend
			if pos <= st and rgnend >= st then
			rgn_t.st = {pos=pos,fin=rgnend,name=name,idx=i,index=idx} -- storing both time line and displayed indices
			end
			if pos <= fin and rgnend >= fin then
			rgn_t.fin = {pos=pos,fin=rgnend,name=name,idx=i,index=idx} -- storing both time line and displayed indices
			end
		end
	i = i+1
	until retval == 0

local err = first_reg_st and (st < first_reg_st and fin > last_reg_end -- all segment regions are enclosed within the loop such that the loop points don't coincide with first and last regions start and end points respectively, if they were merging routine would be activated
or not rgn_t.st and not rgn_t.fin and cross_loop) -- some segment regions are enclosed within loop while loop points are outsude of segment regions
and '    segment regions \n\n shouldn\'t be enclosed \n\n  between loop points'
or cross_loop and (rgn_t.st and st >= rgn_t.st.pos and st <= rgn_t.st.fin and not rgn_t.fin
or rgn_t.fin and fin >= rgn_t.fin.pos and fin <= rgn_t.fin.fin and not rgn_t.st)
and '   loop points must be located\n\n\t  inside segment regions'
..'\n\n or coincide with their start/end' -- one loop point is outside of segment regions but not left of the very first or right of the very last while another is within but doesn't coincide with region start/end
or rgn_t.st and rgn_t.fin and rgn_t.st.index == rgn_t.fin.index -- both loop points belong to the same segment region
and (rgn_t.st.pos == st and rgn_t.fin.fin == fin and 'the region is already set \n\n  to the designated color' --'\t  no action is defined \n\n for such loop points location' -- loop points are located exactly at the same segment region start and end points
or rgn_t.st.pos < st and rgn_t.fin.fin > fin
and ' a segment region \n\n cannot be created \n\n   within another \n\n   segment region') -- loop points are enclosed within the same segment region

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return end

local undo = 'Transcribing B: '
local color = reg_color|0x1000000

-- check if there's a non-segment region at the loop points
local mrkr_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, st)
local retval, isrgn, pos, rgnend, name, idx, cur_color = r.EnumProjectMarkers3(0, reg_idx)
local target_non_segm_reg = reg_idx > -1 and pos == st and fin == rgnend and cur_color ~= color

	if not rgn_t.st and not rgn_t.fin and target_non_segm_reg then -- non-segment region at loop points, set its color to segment region color making it a valid segment region
	-- COLOR
	r.SetProjectMarker3(0, idx, true, st, fin, name, color) -- isrgn true
	undo = undo..'Set region to segment color'
	elseif not rgn_t.st and not rgn_t.fin
	and (not first_reg_st -- no segment regions at all
	or first_reg_st and (st < first_reg_st and fin <= first_reg_st or st >= last_reg_end and fin > last_reg_end) -- the loop is left of the very first or right of the very last segment region
	or st > first_reg_st and fin < last_reg_end) -- both loop points are between adjacent segment regions and none coincides with any
	or rgn_t.st and rgn_t.fin and st == rgn_t.st.fin and fin == rgn_t.fin.pos and not cross_loop -- OR 'rgn_t.fin.idx - rgn_t.st.idx == 1' instead of cross_loop // loop points are between adjacent segment regions and both are coninciding with their end/start
	or (rgn_t.st and st == rgn_t.st.fin and not rgn_t.fin or rgn_t.fin and fin == rgn_t.fin.pos and not rgn_t.st) -- loop points are between adjacent segment regions and only one of them coincides with one of the regions start/end
	then
	-- INSERT
	r.AddProjectMarker2(0, true, st, fin, '', -1, color) -- isrgn true, wantidx -1 automatic index assignment
	undo = undo..'Insert new segment region'
	elseif rgn_t.st and rgn_t.fin and 
	(rgn_t.st.index == rgn_t.fin.index -- this is only true when the region is followed by a gap otherwise rgn_t.fin table will be populated with the next region data because loop end point will fall within the next region as well and the condition will be false
	or rgn_t.st.fin == fin) -- this is true when the loop end point coincides with end of a region not followed by a gap because previous conditon in this case will be false
	then -- loop start and end are within the same region	
	-- SPLIT
	local gap = rgn_t.st.index == rgn_t.fin.index
	-- here rgn_t.fin and rgn_t.st are interchangeable because they hold the data of the same segment region
		if rgn_t.st.pos == st and rgn_t.fin.fin > fin then -- loop end point hangs
		-- shorten the region leftwards
		r.SetProjectMarker3(0, rgn_t.st.index, true, st, fin, rgn_t.st.name, color) -- isrgn true, the color is set only because it wasn't stored in the table
		-- add a new one to its right
		r.AddProjectMarker2(0, true, fin, rgn_t.fin.fin, '', -1, color) -- isrgn true, wantidx -1 auto-assignment of index
		undo = undo..'Split segment region'
		elseif rgn_t.st.pos < st
	--[[	REDUNDANT
		(rgn_t.fin.fin == fin -- true when region is followed by a gap
		or rgn_t.st.fin == fin) -- true when region is not followed by a gap
		and
	]]
		then -- loop start point hangs
		-- shorten the region rightwards
		local idx = gap and rgn_t.fin.index or rgn_t.st.index
		local name = gap and rgn_t.fin.name or rgn_t.st.name
		r.SetProjectMarker3(0, idx, true, st, fin, name, color) -- isrgn true, the color is set only because it wasn't stored in the table
		-- add a new one to its left
		local pos = gap and rgn_t.fin.pos or rgn_t.st.pos
		r.AddProjectMarker2(0, true, pos, st, '', -1, color) -- isrgn true, wantidx -1 auto-assignment of index
		end
	undo = undo..'Split segment region'
	elseif rgn_t.st and rgn_t.fin and rgn_t.st.index ~= rgn_t.fin.index then -- loop start and end are within different regions
	-- MERGE
	-- collect all transcripts and delete
	local non_empty = function(str) if #str:gsub(' ','') > 0 then return true end end
	local i, transcr = rgn_t.st.idx, ''
		for i = rgn_t.fin.idx, rgn_t.st.idx+1, -1 do -- rgn_t.st.idx+1 to exclude the region at loop start point in order to keep it and merge all into it // in reverse due to deletion
		local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0,i)
			if isrgn then
			transcr = name..(non_empty(name) and non_empty(transcr) and ' ' or '')..transcr -- storing names in reverse due to looping in reverse so that the last deleted region name also ends up last, only separating by spaces when there's content
			r.DeleteProjectMarkerByIndex(0, i)
			end
		end
	transcr = rgn_t.st.name..(non_empty(rgn_t.st.name) and ' ' or '')..transcr
	-- extend the the region at loop start points
	r.SetProjectMarker3(0, rgn_t.st.index, true, rgn_t.st.pos, rgn_t.fin.fin, transcr, color) -- isrgn true, the color is set only because it wasn't stored in the table
	undo = undo..'Merge segment regions'
	end


return undo ~= 'Transcribing B: ' and undo

end



function Fix_Overlapping_Segment_Regions(reg_color)

local i, rgn_t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0,i)
		if retval > 0 and isrgn and color == reg_color then
		rgn_t[#rgn_t+1] = {pos=pos,fin=rgnend,name=name,idx=idx,color=color}
		end
	i = i+1
	until retval == 0

local fixed

	for k, rgn in ipairs(rgn_t) do
		if k < #rgn_t and rgn.fin > rgn_t[k+1].pos then
		fixed = 'Transcribing B: Fix overlapping segment regions'
		r.SetProjectMarker3(0, rgn.idx, true, rgn.pos, rgn_t[k+1].pos, rgn.name, rgn.color) -- isrgn true
		end
	end

return fixed

end


function Display_Script_Help_Txt(scr_path)
local help_t = {}
	for line in io.lines(scr_path) do
		if #help_t == 0 and line:match('About:') then
		help_t[#help_t+1] = line:match('About:%s*(.+)')
		about = 1
		elseif line:match('----- USER SETTINGS ------') then
		r.ShowConsoleMsg(table.concat(help_t,'\n'):match('(.+)%]%]'), r.ClearConsole()) return -- trimming the first line of user settings section because it's captured by the loop
		elseif about then
		help_t[#help_t+1] = line:match('%s*(.-)$')
		end
	end	
end


function Toggle_Regions_Lock(KEEP_REGIONS_LOCKED)

local locked = r.GetToggleCommandStateEx(0, 40588) == 1 -- Locking: Toggle region locking mode

	if not locked and KEEP_REGIONS_LOCKED then -- lock
	r.Main_OnCommand(40588, 0)
	end

end


------------------------ MAIN ROUTINE -----------------------


local REG_COLOR = Validate_HEX_Color_Setting(SEGMENT_REGION_COLOR)
local err = 'the segment_region_color \n\n'
err = #SEGMENT_REGION_COLOR:gsub(' ','') == 0 and err..'\t  setting is empty'
or not REG_COLOR and err..'\t setting is invalid'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local theme_reg_col = r.GetThemeColor('region', 0)
REG_COLOR = r.ColorToNative(table.unpack{hex2rgb(REG_COLOR)})

	if REG_COLOR == theme_reg_col then
	Error_Tooltip("\n\n the segment_region_color \n\n\tsetting is the same\n\n    as the theme's default"
	.."\n\n     which isn't suitable\n\n\t   for the script\n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local st, fin = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, start, end 0, allowautoseek false

REG_COLOR = REG_COLOR|0x1000000 -- convert color to the native format returned by object functions

local st, fin = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, start, end 0, allowautoseek false

-- with AddProjectMarker() region can be created when both its start and end values are 0.0,
-- in which case it's placed at the start of the project and has 0 length, even though with action 
-- 'Markers: Insert region from time selection' it's not possible, so prevent that unless the edit cursor 
-- is positioned in a way to call the help text
	
	if st == fin then -- no loop points
	local mrkr_idx, rgn_idx = r.GetLastMarkerAndCurRegion(0, r.GetCursorPosition())
		if rgn_idx > -1 then -- open Help
		local color = select(7, r.EnumProjectMarkers3(0,rgn_idx)) == REG_COLOR
			if not color then
			err = 'not a segment region'
			else
			local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
			Display_Script_Help_Txt(scr_name)
			end
		else
		err = "loop points aren't set"		
		end
		if err then 
		Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
		end
	return r.defer(no_undo) end


r.Undo_BeginBlock()

local fixed = Fix_Overlapping_Segment_Regions(REG_COLOR)
local undo = Insert_Or_Update_Region_At_Loop_Points(st, fin, REG_COLOR)

	if undo or fixed then
	Toggle_Regions_Lock(#KEEP_REGIONS_LOCKED:gsub(' ','') > 0)
	undo = undo and fixed and undo..' and '..fixed:match('.+: (.+)'):lower() or undo or fixed
	r.Undo_EndBlock(undo,-1)
	else
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	end


