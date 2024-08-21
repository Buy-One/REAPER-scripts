--[[
ReaScript name: BuyOne_Transcribing - Real time preview.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1 #Added overlay preset availability evaluation in builds 7.20 and newer
	       #Optimized undo point creation in cases where overlay preset isn't found
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing workflow set of scripts
	alongside 
	BuyOne_Transcribing - Create and manage segments.lua  
	BuyOne_Transcribing - Format converter.lua  
	BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing - Prepare transcript for rendering.lua  
	BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing - Go to segment marker.lua
	BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua
	
	meant to display the transcript segment by segment in real time
	while REAPER is in play mode or when the edit cursor is located
	within segment markers.			

	The original transcript is retrieved from the Notes of tracks
	whose name is defined in the NOTES_TRACK_NAME setting and is 
	reproduced segment by segment in the Notes of a track defined 
	in the PREVIEW_TRACK_NAME setting. 
	
	When the script is launched the SWS Notes window is auto-opened
	being focused on the preview track unless it's already open and
	unless INSERT_PREVIEW_ITEMS setting is enabled.
	
	If INSERT_PREVIEW_ITEMS setting is enabled, on the preview track 
	an empty item is placed with an instance of the Video processor 
	plugin inserted in its FX chain with the preset defined in the 
	OVERLAY_PRESET setting activated to be able to preview the transcript 
	segment by segment within video context when Video window is open. 
	The segment text is fed into the item name.  
	To have text displayed within the Video window the preview track 
	must be located above the track with a video item.
	The preview items are added dynamically to accommodate segment
	next to the currently active segment which is determined by the 
	location of the edit or play cursor relative to the segment start 
	marker. Therefore in order to insert a preview item for a particular 
	segment without waiting until it'll be added in the course of the
	playback, move the edit cursor to the location immediately preceding 
	the segment start marker. 
	This mechanism has been devised to overcome Video processor 
	limitation which prevents it from processing changes in track/take 
	names as soon as the change occurs so it must be allowed to process
	the content in advance.  
	If everything functions properly there could be no more than 2 preview 
	items on the prevew track at any given in time, one for the current 
	and another for the next segment. There'll be only 1 when the last 
	segment is being played and when the cursor is located to the left 
	of the very first segment marker.		
	
	The script relies on markers location to display segment text.
	If the marker time stamp contained in the marker's name doesn't 
	match its actual position on the time line, a message stating the 
	fact will be displayed in the preview track Notes instead of the 
	actual segment text, if any.  
	Preview items for such segments and for segments with no segment
	text are not created.  
	If you're not sure whether all current project markers match the 
	transcript time stamps, run  
	BuyOne_Transcribing - Prepare transcript for rendering.lua script
	to re-create the marker array. Then the render track created by
	that script can be deleted.
	
	The script must run in the background which it will after the 
	initial launch. To terminate it, launch it again and click 
	'Terminate instances' button in the ReaScript task control dialogue 
	which will pop up. Before doing this it's recommended to checkmark 
	'Remember my answer for this script option' so from then on the 
	script is terminated automatically.
	
	While the script runs a toolbar button linked to it is lit and 
	a menu item is ticked.
	
	The script only works under the project tab it's originally been
	launched under. To use it in another project tab terminate it 
	and re-launch under it.  
	
	For preview another script can be used, which is
	'BuyOne_Transcribing - Prepare transcript for rendering.lua'
	however it's not as flexible as this one, because it recreates
	all segment markers from scratch based on the Notes content
	and ignores segments with no transcript. If segments have been
	updated it will have to be run again to recreate markers based
	on the updated Notes data.
	
	
	IMPORTANT
	
	BE AWARE THAT SWS NOTES CHANGES WHICH IMMEDIATELY PRECEDE
	OR FOLLOW REAPER STATE CHANGE WILL GET UNDONE IF SUCH REAPER 
	STATE CHANGE IS UNDONE.
	This has been reported to the SWS team
	https://github.com/reaper-oss/sws/issues/1880
	https://github.com/reaper-oss/sws/issues/1812
	https://github.com/reaper-oss/sws/issues/1743
	THEREFORE SAVING OFTEN IS SO MUCH MORE IMPORTANT BEACAUSE IT WILL
	ALLOW RESTORATION OF NOTES CHANGES LOST AFTER UNDO, BY MEANS 
	OF PROJECT RELOAD.
	ALTERNATIVELY, IF PREVIOUS STATE CAN BE RESTORED WITHOUT RESORTING
	TO UNDO IT'S ADVISED TO OPT FOR THIS METHOD.
	
	Watch demo '6. Real time preview.mp4' which comes with the set 
	of scripts

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

-- Between the quotes insert the name of the track
-- whose SWS Notes window is designated to display
-- the transcribed text segment by segment from the
-- Notes tracks whose name is defined in the NOTES_TRACK_NAME above;
-- if the prevew track isn't found the script will
-- create it and place at the end of the track list;
-- if INSERT_PREVIEW_ITEMS setting isn't enabled below
-- every time the script is launched it will automatically
-- open SWS Notes window with focus on the preview track,
-- unless it's already open
PREVIEW_TRACK_NAME = "PREVIEW"


-- Enable by inserting any alphanumeric character between
-- the quotes to make the script insert preview items
-- on the preview track defined in the PREVIEW_TRACK_NAME
-- setting above, to be able to preview the transcript
-- in real time segment by segment in the REAPER's built-in
-- Video window;
-- for the transcript to be displayed in the Video window
-- the preview track must precede the track with the video
-- item in the track list
INSERT_PREVIEW_ITEMS = ""


-- Only relevant if INSERT_PREVIEW_ITEMS setting is enabled;
-- if you use the default "Overlay: Text/Timecode" preset
-- of the Video processor to preview transcript in video
-- context, keep this setting as is;
-- if you use a customized version of this preset, specify
-- its name in this setting between the quotes
OVERLAY_PRESET = "Overlay: Text/Timecode"


-- Enable by inserting any alphanumeric character between
-- the quotes to make the script clear notes from the preview
-- track designated in the PREVIEW_TRACK_NAME setting above
-- and delete all preview items on this track, if any were
-- inserted as per INSERT_PREVIEW_ITEMS setting when this
-- script is terminated
CLEANUP = "1"


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


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state, tr, src_tr) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue;
-- tr is preview track, src_tr is Video proc instance source track
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
	if toggle_state == 0 and CLEANUP then
	local clear = tr and r.ValidatePtr(tr, 'MediaTrack*') and r.NF_SetSWSTrackNotes(tr, '') -- clearing preview track notes when exiting the script // pointer validation is used in case the script is terminated under different project tab where the track is absent
		if tr then -- delete preview items
			for i=r.CountTrackMediaItems(tr)-1,0,-1 do
			r.DeleteTrackMediaItem(tr,r.GetTrackMediaItem(tr,i))
			end
		end
	local del = src_tr and r.ValidatePtr(src_tr, 'MediaTrack*') and r.DeleteTrack(src_tr) -- deleting Video proc source track in build older than 7.20
	r.UpdateArrange()
	end
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t,1,6)) end
end


function Segment_Markers_Exist()
local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and r.parse_timestr(name) ~= 0 then
		return true
		end
	i = i+1
	until retval == 0
end



function insert_new_track(tr_name)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
return tr
end


function Get_Or_Create_Preview_Track(name_setting)

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
		if name:match('^%s*'..name_setting..'%s*$') then
		return tr
		end
	end

-- insert if not found
return insert_new_track(name_setting)

end



function Insert_Video_Proc_Src_Track(OVERLAY_PRESET)

-- in builds older than 7.20 'Overlay: Text/Timecode' preset doesn't work if applied via the API
-- without opening the Video processor beforehand
-- because the parameter values shift downwards between parameters
-- while 'text height' param ends up at 0 so the text becomes invisible
-- bug report https://forum.cockos.com/showthread.php?t=293212
-- hidden source track is used in earlier builds to copy Video proc instance
-- from it to preview items so that there's no need to open and close
-- the plugin UI each time when inserting it on directly a preview item
-- with Insert_Delete_Preview_Items() function which will produce flickering

r.PreventUIRefresh(1)

	local function apply_overlay_preset(tr)
	r.TrackFX_Show(tr, 0x1000000, 3) -- showFlag 3 show floating window
	local ok = r.TrackFX_SetPreset(tr, 0x1000000, OVERLAY_PRESET) -- fx 0
		if not ok then return end -- overlay reset not found
		for parm_idx, val in pairs({[6] = 0, [7] = 1, [8] = 1}) do -- 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
		r.TrackFX_SetParam(tr, 0x1000000, parm_idx, val)
		end
	r.TrackFX_Show(tr, 0x1000000, 2) -- showFlag 3 show floating window
	return true -- if not reached this point, the overlay preset wasn't found
	end

	for i=0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, fx_name = r.TrackFX_GetNamedConfigParm(tr, 0x1000000, 'fx_name')
	local vid_proc = fx_name == 'Video processor'
	local ret, preset = r.TrackFX_GetPreset(tr, 0x1000000, '') -- fx 0
	local overlay = preset == OVERLAY_PRESET
	local ret, ext_state = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:SRC VIDEO PROC','',false) -- setNewValue false
		if #ext_state > 0 then
			if vid_proc and overlay then
			elseif vid_proc and not overlay then
			apply_overlay_preset(tr)
			end
		return tr
		end
	end

-- if tr wasn't found above
local tr = insert_new_track('')
r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0) -- hide in mixer
r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0) -- hide in TCP
local retval, fx_name = r.TrackFX_GetNamedConfigParm(tr, 0x1000000, 'fx_name')
	if not retval or fx_name ~= 'Video processor' then
	r.TrackFX_AddByName(tr, 'Video processor', true, -1000-0x1000000) -- recFX true, instantiate -1000 first fx chain slot
	end
local newer_build = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.20
local ret, preset = r.TrackFX_GetPreset(tr, 0x1000000, '') -- fx 0
	if preset ~= OVERLAY_PRESET then -- apply
	local ok = apply_overlay_preset(tr)
		if not ok or ok and newer_build then -- deleting track if not found in any build and if found in newer builds because in this case the track was only needed to check availability of the preset
		r.DeleteTrack(tr)
		return ok and newer_build end -- in newer builds returning true if found to prevent triggering error message outside, in older builds the return value will always be false which will trigger the error message
	end
r.GetSetMediaTrackInfo_String(tr, 'P_NAME','Video processor source',true) -- setNewValue true
r.GetSetMediaTrackInfo_String(tr, 'P_EXT:SRC VIDEO PROC','1',true) -- setNewValue true

r.PreventUIRefresh(-1)

return tr

end



function Insert_Delete_Preview_Items(preview_tr, pos, mrkr_t, src_tr, first_mrkr_pos)
-- pos is location of the current marker
-- when pos is nil all preview items are deleted and the function is exited
-- when pos is -1 it must be accompanied with valid first_mrkr_pos arg
-- in which case the preview item is created at first_mrkr_pos rather than next valid

r.PreventUIRefresh(1)

	if pos then
	-- delete all preview items previous to the current marker at pos
		for i=r.CountTrackMediaItems(preview_tr)-1,0,-1  do
		local item = r.GetTrackMediaItem(preview_tr, i)
		local item_pos = r.GetMediaItemInfo_Value(item,'D_POSITION')
			if item_pos < pos then
			r.DeleteTrackMediaItem(preview_tr, item)
			end
		end
	r.UpdateArrange() -- must be used in case the playback continues on after the last marker, because no new preview items will be inserted and Arrange won't be updated, so the last preview item will remain visible
	else
	-- delete all preview items, in practice it's later preview items,
	-- because earlier ones are deleted as cursor moves forward,
	-- pos arg comes in as nil in the RUN_PREVIEW() when current cursor pos is smaller
	-- than the last stored one, meaning the cursor has been moved left,
	-- preview item for the next segment will be created
	-- later in the RUN_PREVIEW() routine
		for i=r.CountTrackMediaItems(preview_tr)-1,0,-1 do
		local item = r.GetTrackMediaItem(preview_tr, i)
		r.DeleteTrackMediaItem(preview_tr, item)
		end
	r.UpdateArrange() -- same reason as above when the playback comes around to the loop start or cursor is move left
	return
	end


local next_pos = pos > -1 and mrkr_t and mrkr_t[pos] -- pos arg is -1 when first_mrkr_pos arg is included to insert 1st preview item when cursor is to the left of the 1st marker, in which case next_pos must be the first marker position itself, see expression below,  rather than next marker position as designed to be by the table structure in Get_Segment_Markers()
next_pos = first_mrkr_pos or next_pos

	if not next_pos then return end -- no next marker data has been found, likely the last marker or not a segment marker

-- Insert next preview item at the next marker

local act = r.Main_OnCommand
--local item = r.GetTrackMediaItem(rend_tr,0) -- select 1st item on the track
--local take = item and r.GetActiveTake(item)
--[[ WORKS
act(40214, 0) -- Insert new MIDI item...
item = r.GetSelectedMediaItem(0,0) -- newly inserted item is exclusively selected
take = r.GetActiveTake(item)
]]
-- ALTERNATIVE WHICH RESULTS IN ALL ITEM BUTTONS BEING HIDDEN EVEN IF ENABLED
-- SPECIFICALLY LOCK AND FX, LOOKS TIDIER AND THE ITEMS CANNOT BE OPENED IN THE MIDI EDITOR
-- WHEN CLICKED BEHAVE LIKE EMPTY ITEMS
local item = r.AddMediaItemToTrack(preview_tr)
local take = r.AddTakeToMediaItem(item)

	-- Insert Video processor and apply preset
	if src_tr then -- by copying from the src_tr
	-- src track is an invisible track created with Insert_Video_Proc_Src_Track()
	-- housing an instance of Video proc with overlay preset
	-- to paste to the preview items from, in builds older than 7.20 in order
	-- to prevent flickering UI when adding the plugin directly
	-- and applying the preset while opening and closing its UI
	-- which is necessary due to bug in builds older than 7.20
	-- bug report https://forum.cockos.com/showthread.php?t=293212
	r.TrackFX_CopyToTake(src_tr, 0x1000000, take, 0, false) -- ismove false
	else -- directly, which is supported since 7.20 where there's no need to open Video proc UI to apply preset correctly
	r.TakeFX_AddByName(take, 'Video processor', -1000) -- instantiate -1000 first fx chain slot
	r.TakeFX_SetPreset(take, 0, OVERLAY_PRESET) -- fx 0
	end
		-- only set parameters if the preset is default because in the user version
		-- everything will be set within the preset itself
		if OVERLAY_PRESET == 'Overlay: Text/Timecode' then
			for parm_idx, val in pairs({[6] = 0, [7] = 1, [8] = 1}) do -- 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
			r.TakeFX_SetParam(take, 0, parm_idx, val)
			end
		end

local len = mrkr_t[next_pos] and mrkr_t[next_pos]-next_pos -- if next_pos is the last marker position, mrkr_t[next_pos] will be invalid

	if len then

		for parm, val in pairs({D_POSITION=next_pos, D_LENGTH=len, B_LOOPSRC=0, C_LOCK=0}) do
		r.SetMediaItemInfo_Value(item, parm, val)
		end

	-- When new MIDI item is inserted either with action or the API
	-- (commented out above), its loop source setting is disabled
	-- and length is increased a visible notch is created in the
	-- item UI at the spot where the new loop iteration would start
	-- which spoils the optics, wiggling item edge with a mouse or
	-- toggling Item properties On/Off manually fixes this, but via
	-- API this doesn't work, hence actions must be applied;
	-- although the item length will change in real time to only
	-- last one segment (a space between two adjacent markers)
	-- the initial length is set to project length because when
	-- a shorter item is extented via the API it's affected with
	-- the same notch issue which doesn't occur when the longer item
	-- is shortened
	act(40636, 0) -- Item properties: Loop item source // re-sable
	act(40636, 0) -- Item properties: Loop item source // disnable
	end

r.PreventUIRefresh(-1)

return take -- return next preview item take

end



function Get_Segment_Markers()

local parse = r.parse_timestr

local i, mrkr_t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and (parse(name) ~= 0 or name == '00:00:00.000') then
		local pos_next
		local ii = i+1
			repeat
			local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(ii) -- get next marker
				if retval > 0 and not isrgn and (parse(name) ~= 0 or name == '00:00:00.000') then
				pos_next = pos
				break
				end
			ii = ii+1
			until retval == 0
			if pos_next then
			mrkr_t[pos] = pos_next
			end
		mrkr_t.first_mrkr_pos = mrkr_t.first_mrkr_pos or pos
		mrkr_t.last_mrkr_pos = pos
		end
	i = i+1
	until retval == 0

return mrkr_t

end



function Get_Next_Segment_Pos_And_Text(start_idx, notes_init)
-- accounts for regions and invalid markers which should
-- always be ignored as if non-existent and looked past in search
-- of the next segment marker;
-- if there're very short gaps between segments
-- the next segment preview item must be created before
-- such gap has been reached because if created while
-- the cursor is within the gap the time is too short
-- for the Video proc to pocess the upcoming preview item
-- which results in the lag in the segment display within Video window
local i = start_idx
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and (r.parse_timestr(name) ~= 0 or name == '00:00:00.000') then
		local segment_txt = Get_Current_Segment_From_Track_Notes(notes_init, name)
			if segment_txt then return pos, segment_txt end
		end
	i = i+1
	until retval == 0
end



function Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local tr_t = {}

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index = data:match('^%d+')
		if name:match('^%s*%d+ '..NOTES_TRACK_NAME..'%s*$') and tonumber(index) then
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



function Get_Current_Segment_From_Track_Notes(notes, mrkr_name)

	for line in notes:gmatch('[^\n]+') do -- leaving out \r because it lingers between transcripts from different segments after merger and prevents getting full merged segment transcript
		if line and #line:gsub('[%s%c]','') > 0 and line:match('^%s*'..mrkr_name) then -- only start time stamp is evaluated
		return line:match('^%s*%d+:%d+:%d+%.%d+%s*[:%d%.]*(.*)') -- non greedy operator for fin_stamp capture because it may be absent in which case st_stamp capture won't be affected
		or '< NO TEXT ASSOCIATED WITH THE SEGMENT >' -- an alternative to nil return value but seems to be redundant, duplicated in the main RUN_PREVIEW() function
		end
	end

end


function format_time_stamp(pos) -- format by adding leading zeros because r.format_timestr() ommits them
local name = r.format_timestr(pos, '')
return pos/3600 >= 1 and (pos/3600 < 10 and '0'..name or name) -- with hours
or pos/60 >= 1 and (pos/60 < 10 and '00:0'..name or name) -- without hours
or '00:0'..name -- without hours and minutes
end



function Show_SWS_Notes_Window()
local act = r.Main_OnCommand
local cmd_ID = r.NamedCommandLookup('_S&M_TRACKNOTES') -- SWS/S&M: Open/close Notes window (track notes)
-- When in the Notes window other Notes source section is open the action will switch it to tracks
-- if it's track Notes section is already open the action will close the window;
-- evaluating visibility of a particular Notes section using actions isn't possible
-- because the toggle state of all section actions is ON as long as the Notes window is open
act(cmd_ID,0) -- toggle
	if r.GetToggleCommandStateEx(0, cmd_ID) == 0 then -- if got closed because the window was already set to track Notes
	r.Main_OnCommand(cmd_ID,0) -- re-open
	end
end



function RUN_PREVIEW()

local proj, projfn = r.EnumProjects(-1)

	if projfn == projfn_init then -- only run under the same project which the script was initially launched under

	local tr_t, notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)
	local mrkr_t = Get_Segment_Markers()
	local plays = r.GetPlayState()&1 == 1

		if src_tr and not r.ValidatePtr(src_tr, 'MediaTrack*') then
		-- recreate Video proc src track if was deleted after initial creation
		src_tr = Insert_Video_Proc_Src_Track(OVERLAY_PRESET)
		end

		if not last_playpos or plays and r.GetPlayPosition() < last_playpos
		or not plays and r.GetCursorPosition() < last_playpos then
		Insert_Delete_Preview_Items(preview_tr) -- pos nil will trigger deletion of all later preview items when cursor has been moved left
		mrkr_idx_init = nil -- reset // ensures that the content associated with the very first marker can be retriggered if the play cursor has been moved back before reaching the 2nd marker and before mrkr_idx has changed to the 2nd one
		end

			if #notes:gsub('[%s%c]','') > 0 and notes ~= notes_init then
			notes_init = notes
			end

		-- update active segment in response to play or edit cursor position
		local mrkr_idx = plays and r.GetLastMarkerAndCurRegion(0, r.GetPlayPosition()) -- playing
		or r.GetLastMarkerAndCurRegion(0, r.GetCursorPosition()) -- returns -1 if not preceded by any marker contrary to the API doc

		local retval, isrgn, pos, rgnend, name, index = r.EnumProjectMarkers(mrkr_idx) -- get first marker name to find 1st segment transcript to add to the first segment preview item

			if mrkr_idx == -1 -- cursor is to the left of the very first project marker/region // considering the next cond this one is actually redundant
			or pos < mrkr_t.first_mrkr_pos -- cursor is to the left of the very first segment marker
			or not isrgn and pos == mrkr_t.last_mrkr_pos -- cursor is to the right of the last segment marker (which will be last segment end marker)
			then -- clear notes and insert 1st segment preview item when the playhead is to the left of the very first marker or to the right of the very last, the latter is meant to accommodate cases where the very 1st segment marker is located at the very beginning of the project in which case there'll be no other way to insert 1st segment preview item in advance

				if pos < mrkr_t.first_mrkr_pos -- mrkr_idx == -1  cond isn't used because it's covered by this one
				or pos == mrkr_t.last_mrkr_pos
				then -- clear Notes from preview track
				local clear = preview_tr and r.ValidatePtr(preview_tr, 'MediaTrack*') and r.NF_SetSWSTrackNotes(preview_tr, '')  -- pointer validation is used in case the track is deleted manually while the script runs
				end

				if INSERT_PREVIEW_ITEMS and not first_preview_take then -- first_preview_take cond ensures that the function runs only once when the cursor has moved to the left of the very 1st marker, otherwise the first segment preview item will keep being created and deleted here
				Insert_Delete_Preview_Items(preview_tr) -- pos nil will trigger deletion of all preview items
				local pos, segment_txt = Get_Next_Segment_Pos_And_Text(0, notes_init) -- start_idx is 0 // get first marker pos and 1st segment transcript to add to the first segment preview item
					if segment_txt and #segment_txt:gsub('[%s%c]','') > 0 then
					first_preview_take = Insert_Delete_Preview_Items(preview_tr, -1, mrkr_t, src_tr, pos) -- insert 1st segment, pos is equal to mrkr_t.first_marker_pos
					local insert = first_preview_take and r.ValidatePtr(first_preview_take, 'MediaItem_Take*') and r.GetSetMediaItemTakeInfo_String(first_preview_take, 'P_NAME', segment_txt:match('%S.+'):gsub('%s*<n>%s*','\n'), true) -- setNewValue true // trimming leading spaces and converting new line tag into the new line control character
					end
				end

			last_playpos = 0 -- initialize, used as a condition to allow updating preview track notes and triggering later preview items deletion when cursor has been moved left past the 1st marker; also prevents deletion of the 1st segment preview item inserted above while the cursor is to the left of the 1st marker because of last_playpos being nil

			elseif mrkr_idx ~= mrkr_idx_init then -- new marker has come along during playback or as a result of cursor movement

			first_preview_take = nil -- reset once 1st segment marker has been reached so that when the loop comes around or cursor is moved left of the very first marker the first segment preview item creation condition could be true again

			mrkr_idx_init = mrkr_idx -- prevents the routine from running until new marker comes along

			last_playpos = plays and r.GetPlayPosition() or r.GetCursorPosition() -- update, used as a condition to allow updating preview track notes and triggering later preview items deletion when cursor has been moved left

			local retval, isrgn, pos, rgnend, name, index = r.EnumProjectMarkers(mrkr_idx) -- get current marker pos to delete all preceding preview items if INSERT_PREVIEW_ITEMS is enabled, and to get current segment transctipt for display in the preview track notes

			local segment_txt, segment_txt_next, pos_next

				if not isrgn then

					if format_time_stamp(pos) ~= name then -- not a segment marker or not a valid one
					segment_txt = r.parse_timestr(name) ~= 0 and name ~= '00:00:00.000'
					and '< MARKER TIME STAMP DOESN\'T MATCH ITS POSITION >'
					or '< NOT A SEGMENT MARKER >' -- marker doesn't contain time stamp
					--------------------------------------------
					-- insert preview item for the segment which follows the invalid marker if its own marker is valid
						if INSERT_PREVIEW_ITEMS then
						local pos, segment_txt_next = Get_Next_Segment_Pos_And_Text(mrkr_idx+1, notes_init) -- start_idx is mrkr_idx+1 // get next marker pos and next segment transcript to insert next segment preview item
							if segment_txt_next and #segment_txt_next:gsub('[%s%c]','') > 0 then
							local preview_take = Insert_Delete_Preview_Items(preview_tr, -1, mrkr_t, src_tr, pos)
							local insert = preview_take and r.ValidatePtr(preview_take, 'MediaItem_Take*') and r.GetSetMediaItemTakeInfo_String(preview_take, 'P_NAME', segment_txt_next:match('%S.+'):gsub('%s*<n>%s*','\n'), true) -- setNewValue true // trimming leading spaces and converting new line tag into the new line control character
							end
						end
					----------------------------------------------
					else -- valid segment marker, only if actual position matches the time stamp in its name
					segment_txt = Get_Current_Segment_From_Track_Notes(notes_init, name) -- get current segment transcript for display in track Notes
						if INSERT_PREVIEW_ITEMS then
						pos_next, segment_txt_next = Get_Next_Segment_Pos_And_Text(mrkr_idx+1, notes_init) -- start_idx is mrkr_idx+1 // get next segment marker pos and next segment transcript to insert next segment preview item
						end
					end
				end -- not isrgn cond end

				if segment_txt then -- this will be true always
				segment_txt = #segment_txt:gsub('[%s%c]','') == 0 and '< NO TEXT ASSOCIATED WITH THE SEGMENT >'
				or segment_txt:match('%S.+') -- trimming leading spaces
				-- change segment text in the preview track Notes window
				local insert = preview_tr and r.ValidatePtr(preview_tr, 'MediaTrack*') and r.NF_SetSWSTrackNotes(preview_tr, segment_txt) -- validation is used in case the object becomes unavailable while the script runs
				end

			-- manage preview items
			Insert_Delete_Preview_Items(preview_tr, pos) -- mrkr_t arg is nil to trigger deletion of previous preview item INCLUDING the penulimate when the last segment is being played AND the last when the cursor has moved past last marker, which won't occur if the deletion is conditioned by segment_txt_next below because in this case segment_txt_next will be nil due to absense of the next segment and the function won't run AND INCLUDING item previous to invalid marker

			-- shorten current preview item if it's followed by an invalid marker
			-- so it only extends until such invalid marker,
			-- because originally it will extend to the next valid marker
			-- (due to the mrkr_t table content which only includes valid markers)
			-- spanning the segment starting with the invalid marker, where transcript
			-- isn't supposed to be displayed;
			-- even though such item is deleted with Insert_Delete_Preview_Items() above
			-- as soon as the invalid marker comes along, if it's not shortened in advance
			-- its content will linger in the Video window
			local retval, isrgn, next_mrkr_pos, rgnend, name, index = r.EnumProjectMarkers(mrkr_idx+1)
				if retval > 0 and not isrgn and r.parse_timestr(name) == 0 then
				local item = r.GetTrackMediaItem(preview_tr,0)
				local extend = item and r.SetMediaItemInfo_Value(item, 'D_LENGTH', next_mrkr_pos-pos)
				end
				-- add segment transcript to the next preview item
				if segment_txt_next and #segment_txt_next:gsub('[%s%c]','') > 0 then
				local preview_take = Insert_Delete_Preview_Items(preview_tr, -1, mrkr_t, src_tr, pos_next)
				local insert = preview_take and r.ValidatePtr(preview_take, 'MediaItem_Take*') and r.GetSetMediaItemTakeInfo_String(preview_take, 'P_NAME', segment_txt_next:match('%S.+'):gsub('%s*<n>%s*','\n'), true) -- setNewValue true // trimming leading spaces and converting new line tag into the new line control character
				end

		end -- elseif mrkr_idx ~= mrkr_idx_init cond end

	end

r.defer(RUN_PREVIEW)

end



NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME
PREVIEW_TRACK_NAME = #PREVIEW_TRACK_NAME:gsub(' ','') > 0 and PREVIEW_TRACK_NAME

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'
or not PREVIEW_TRACK_NAME and 'PREVIEW_TRACK_NAME \n\n   setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local tr_t, notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local err = 'tracks named "" \n\n weren\'t found'
err = #tr_t == 0 and err:gsub('""', '"'..NOTES_TRACK_NAME..'"')
--or not preview_tr and err:gsub('tracks','track'):gsub('were','was'):gsub('""','"'..PREVIEW_TRACK_NAME..'"')
or #notes:gsub('[%s%c]','') == 0 and 'No Notes in the tracks'
or not Segment_Markers_Exist() and 'no segment markers'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

r.Undo_BeginBlock()

preview_tr = Get_Or_Create_Preview_Track(PREVIEW_TRACK_NAME)

INSERT_PREVIEW_ITEMS = #INSERT_PREVIEW_ITEMS:gsub(' ','') > 0

	if INSERT_PREVIEW_ITEMS then
	src_tr = Insert_Video_Proc_Src_Track(OVERLAY_PRESET)	
		if not src_tr then
		Error_Tooltip('\n\n the overlay preset wasn\'t found \n\n', 1, 1) -- caps, spaced true		
		r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		return r.defer(no_undo)
		end
	src_tr = type(src_tr) ~= 'boolean' and src_tr -- src_tr is returned as 'true' when the overlay preset was found in builds 7.20 and later, but the src_tr isn't needed because the preset can be applied without opening the Video proc UI, hence turned into false
	else
	r.SetOnlyTrackSelected(preview_tr)
	Show_SWS_Notes_Window()
	end

r.Undo_EndBlock('Transcribing: Create preview track', -1)


CLEANUP = #CLEANUP:gsub(' ','') > 0

local notes_init, mrkr_idx_init, last_playpos, playstate

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

proj_init, projfn_init = r.EnumProjects(-1)

RUN_PREVIEW()

r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0, preview_tr, src_tr))









