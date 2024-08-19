--[[
ReaScript name: BuyOne_Transcribing - Prepare transcript for rendering.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing workflow set of scripts
			alongside
			BuyOne_Transcribing - Create and manage segments.lua  
			BuyOne_Transcribing - Real time preview.lua  
			BuyOne_Transcribing - Format converter.lua  
			BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
			BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua  
			BuyOne_Transcribing - Go to segment marker.lua
			BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua
			
			It's purpose is to allow embedding transcript in a video file or
			audio file.
			
			V I D E O
			
			If VIDEO option is chosen by the user in the pop-up menu the script
			creates a new track named as specified in the RENDER_TRACK_NAME
			setting and inserts on it items with Video processor plugin 
			at markers which correspond to segments start and having segment 
			transcript included in their take names in order to display 
			the transcript within video context.  
			The script deletes from the project all segment markers, i.e. 
			those bearing in their name a time stamp in the format supported 
			by the set Transcribing scripts, and then creates them from scratch
			taking their positions from the transcript time stamps. Existing 
			markers whose name don't conform to the format supported by the 
			Transcribing scripts set are left intact.  
			The items are only inserted for segments with text.  
			All formatting markup is cleared except for the new line tag <n> 
			supported by this set of scripts and the Video processor 
			'Overlay: Text/Timecode' preset.
			
			The said render track must be placed above the track with the 
			video item.  

			When the items are created they become locked so in order to manually
			delete them they must be unlocked first. Or the render track itself
			can be deleted without unlocking the items beforehand.  
			
			Once set up the video can be rendered out as normal.
			
			A U D I O
			
			If AUDIO option is selected the script deletes from the project all 
			segment markers, i.e. those bearing in their name a time stamp in 
			the format supported by the set Transcribing scripts, and then creates 
			them from scratch taking their positions from the segment start time 
			stamps of the transcript.  
			
			The transcript of each segment is added to the corresponding marker
			name. All new line tags <n> supported by this set of scripts and 
			all other formatting markup supported by the SRT or VTT formats is 
			cleared.  
			If 'With chapter tags' option is enabled before opting for AUDIO
			option, in each segment marker the transcript will be preceded with
			'CHAP' tag and will be recognized as a chapter by media players which 
			support it. To have chapter tags embedded in the file the output format
			must be mp3, flac, ogg or opus and 'Add new metadata' option must be 
			enabled in the Render window.  
			To embed the segment markers with the transcript inside files in formats 
			which don't support 'CHAP' tag such as wav, instead of enabling the 
			metadata select 'Markers only' option from the drop-down menu at the 
			bottom of the Render window. Adding chapter tag in this case is 
			unnecessary.
			
			The menu options can be triggered from keyboard by hitting the key
			which corresponds to the first character of the menu item.
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
-- on which items with segment trabscript will be inserted;
-- after the track is created it must be placed above the
-- track with the video item;
-- if the render track isn't found the script will
-- create it automatically
RENDER_TRACK_NAME = "RENDER"

-- If you use the default "Overlay: Text/Timecode" preset
-- of the Video processor to preview transcript in video
-- context, keep this setting as is;
-- if you use a customized version of this preset, specify
-- its name in this setting between the quotes
OVERLAY_PRESET = "Overlay: Text/Timecode"

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



function insert_new_track(tr_name)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
return tr
end


function Get_Track(name_setting)

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



function Remove_All_Segment_Markers()
-- they will be recreated based on the transcript in Insert_Items_At_Markers()

local parse = r.parse_timestr

local retval, mrkr_cnt = r.CountProjectMarkers(0)

local i = mrkr_cnt-1
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn and (parse(name) ~= 0 or name == '00:00:00.000') then
		r.DeleteProjectMarkerByIndex(0, i)
		end
	i = i-1
	until retval == 0

end



function Get_Notes(NOTES_TRACK_NAME)

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

	if #tr_t == 0 then
	Error_Tooltip("\n\n notes tracks weren't found \n\n", 1, 1) -- caps, spaced true
	return end

-- sort the table by integer in the track extended state
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

-- collect Notes from all found tracks
local notes = ''
	for k, t in ipairs(tr_t) do
	notes = notes..(#notes == 0 and '' or '\n')..r.NF_GetSWSTrackNotes(t.tr) -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
	end

	if #notes:gsub('[%s%c]','') == 0 then
	Error_Tooltip("\n\n notes are empty \n\n", 1, 1) -- caps, spaced true
	return end

	if not notes:sub(-1):match('\n') then -- OR notes:sub(-1) ~= '\n' -- to simplify gmatch search
	notes = notes..'\n'
	end

	local function clear_markup(line)
	local t = {'a','b','i','u','v','font'}
		for _, tag in ipairs(t) do
			if tag == 'v' then -- VTT tag
			local speaker = line:match('<v (.-)>')
				if speaker then
				line = line:gsub('<v.->',speaker..': ')
				end
			elseif tag == 'a' then
			line = line:gsub('{\a%d+}','')
			else
			line = line:gsub('[<{]+/?'..tag..'.-[>}]','')
			end
		end
	return line
	end

local notes_t = {}
local time_stamp_exists
	for line in notes:gmatch('(.-)\n') do
		if line and #line:gsub('[%s%c]','') > 0 then -- ignoring empty segments
		notes_t[#notes_t+1] = clear_markup(line)
		time_stamp_exists = time_stamp_exists or line:match('^%s*(%d+:%d+:%d+%.%d+)')
		end
	end

	if not time_stamp_exists then
	Error_Tooltip("\n\n no segment timecode in the notes \n\n", 1, 1) -- caps, spaced true
	return end

return notes_t

end


function Insert_Items_At_Markers(rend_tr, notes_t, NOTES_TRACK_NAME, OVERLAY_PRESET, mrkr_t)
-- only at markers to which there're matching segments
-- in the Notes with transcription, ignoring empty segments
-- mrkr_t arg is obsolete because Get_Segment_Markers() has been superceded with Remove_All_Segment_Markers()
-- so markers are re-created based on the transcript

	function insert_item(rend_tr, pos, len, transcr, OVERLAY_PRESET)
--[[	these are only relevant if inserting with action
	r.SetOnlyTrackSelected(rend_tr)
	r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
]]
	local act = r.Main_OnCommand
	local item = r.GetTrackMediaItem(rend_tr,0) -- select 1st item on the track
	local take = item and r.GetActiveTake(item)
		if not item then -- if absent, create at edit cursor which has been moved to marker
	--[[ WORKS
		act(40214, 0) -- Insert new MIDI item...
		item = r.GetSelectedMediaItem(0,0) -- newly inserted item is exclusively selected
		take = r.GetActiveTake(item)
	]]
		-- ALTERNATIVE WHICH RESULTS IN ALL ITEM BUTTONS BEING HIDDEN EVEN IF ENABLED
		-- SPECIFICALLY LOCK AND FX, LOOKS TIDIER AND THE ITEMS CANNOT BE OPENED IN THE MIDI EDITOR
		-- WHEN CLICKED BEHAVE LIKE EMPTY ITEMS
		item = r.AddMediaItemToTrack(rend_tr)
		take = r.AddTakeToMediaItem(item)

		-- insert Video processor and apply preset
		r.TakeFX_AddByName(take, 'Video processor', -1000) -- instantiate -1000 first fx chain slot
		-- 'Overlay: Text/Timecode' preset doesn't work if applied via the API
		-- without opening the Video processor beforehand
		-- because the parameter values shift downwards between parameters
		-- while 'text height' param ends up at 0 so the text becomes invisible
		-- bug report https://forum.cockos.com/showthread.php?t=293212
		-- fixed in build 7.20
		local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.20
		local show = old and r.TakeFX_Show(take, 0, 3) -- showFlag 3 show floating window
		local ok = r.TakeFX_SetPreset(take, 0, OVERLAY_PRESET) -- fx 0

			if not ok then r.DeleteTrackItem(rend_tr, item) return end -- preset wasn't found

			-- only set parameters if the preset is default because in the user version
			-- everything will be set within the preset itself
			if OVERLAY_PRESET == 'Overlay: Text/Timecode' then
				for parm_idx, val in pairs({[6] = 0, [7] = 1, [8] = 1}) do -- 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
				r.TakeFX_SetParam(take, 0, parm_idx, val)
				end
			end

		local hide = old and r.TakeFX_Show(take, 0, 2) -- showFlag 3 show floating window
		else -- if present, copy and paste at edit cursor which has been moved to marker
		r.SelectAllMediaItems(0, false) -- deselect all
		r.SetMediaItemSelected(item, true) -- selected true
		act(40698,0) -- Edit: Copy items
		act(42398,0) -- Item: Paste items/tracks
		item = r.GetSelectedMediaItem(0,0) -- newly inserted item is exclusively selected action
		take = r.GetActiveTake(item)
		end

		for parm, val in pairs({D_POSITION=pos, D_LENGTH=len, B_LOOPSRC=0, C_LOCK=1}) do
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
	local transcr = transcr:match('^%s*(.-)%s*$'):gsub('%s*<n>%s*','\n') -- stripping trailing spaced and converting new line tag into new line char
	r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', transcr, true) -- setNewValue true
	return true -- if not reached this point, the overlay preset wasn't found
	end


	function get_last_mrkr_pos(NOTES_TRACK_NAME)
	-- get last marker pos in case segment end time stamps aren't listed in the transcript
	-- to be able to determine the length of the last segment preview item
	local notes_tr
		for i = 0, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i)
		local retval, name = r.GetTrackName(tr)
			if name:match('^%s*1 '..NOTES_TRACK_NAME..'%s*$') then
			notes_tr = tr
			end
		end
	local ret, last_mrkr_stamp = r.GetSetMediaTrackInfo_String(notes_tr, 'P_EXT:LASTMARKERPOS', '', false) -- setNewValue false // stored inside PROCESS_SEGMENTS() function of 'BuyOne_Transcribing - Create and manage segments.lua' script
	return r.parse_timestr(last_mrkr_stamp)
	end

local parse, first_mrkr_pos = r.parse_timestr
local mrkr_t = mrkr_t or {}

	for k, segm in ipairs(notes_t) do
	r.SetOnlyTrackSelected(rend_tr)
	local st, fin, transcr = segm:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
		if st then -- could be nil if non-segment content is present
			if k == #notes_t then -- last segment, get last marker pos from the segment end time stamp if any
			local last_mrkr_pos = fin and #fin > 0 and parse(fin) or get_last_mrkr_pos(NOTES_TRACK_NAME)
				if last_mrkr_pos then -- insert last marker at the found time stamp
				r.AddProjectMarker(0, false, last_mrkr_pos, 0, format_time_stamp(last_mrkr_pos), -1) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index
				mrkr_t.last_mrkr = last_mrkr_pos
				end
			end
		local pos = parse(st)
		local mrkr_idx
			if not mrkr_t[st] then -- insert marker if absent
			mrkr_idx = r.AddProjectMarker(0, false, pos, 0, st, -1) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index
			-- look for the next segment marker to add distance between it and the newly inserted one to the field of the latter in the table
				for i = k+1, #notes_t do -- starting from the next segment
				local segm = notes_t[i]
				local st_next, fin_next = segm:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
					if st_next then -- next marker found, store distance to it for the current segment
					mrkr_t[st] = {pos=pos, len=parse(st_next)-pos}
					break end
				end
				if not mrkr_t[st] then -- the newly inserted marker data wasn't included above because next marker wasn't found
				mrkr_t[st] = {pos=pos, len = fin and #fin > 0 and parse(fin)-pos or mrkr_t.last_mrkr and mrkr_t.last_mrkr-pos or r.GetProjectLength()-pos} -- store either distance to the last marker if listed as the last segment end time stamp or to the last marker stored in the table (in fact the last time stamp would be also stored in the table above) or to the project end
				end
			end

			if mrkr_t[st] and #transcr:gsub('[%s%c]','') > 0 then -- there's marker whose pos matches segment start time stamp, only insert if there's segment text
			local ok = insert_item(rend_tr, mrkr_t[st].pos, mrkr_t[st].len, transcr, OVERLAY_PRESET)
				if not ok then r.DeleteProjectMarker(0, mrkr_idx, false) return end -- isrgn false
			first_mrkr_pos = first_mrkr_pos or mrkr_t[st].pos
			end
		end
	end

local move = first_mrkr_pos and r.SetEditCurPos(first_mrkr_pos, true, false) -- moveview true, seekplay false // restore

return true -- if not reached this point, the overlay preset wasn't found

end


function Insert_Markers_For_Audio(notes_t, chapters)

local first_mrkr_idx

	for k, segm in ipairs(notes_t) do
	local st, fin, transcr = segm:match('^%s*(%d+:%d+:%d+%.%d+)%s*([:%d%.]*)(.*)') -- non-greedy operator for fin capture because it may be absent in which case st capture won't be affected
		if transcr and #transcr:gsub('[%s%c]','') > 0 then
		transcr = chapters and 'CHAP='..transcr or transcr
		transcr = transcr:match('^%s*(.-)%s*$'):gsub('%s*<n>%s*',' ') -- stripping trailing spaces, replacing new line tag and surrounding spaces with a single space
		local pos = r.parse_timestr(st)
		local index = r.AddProjectMarker(0, false, pos, 0, transcr, -1) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index, trimming leading space if any
		first_mrkr_pos = first_mrkr_pos or pos
		end
	end

local move = first_mrkr_pos and r.SetEditCurPos(first_mrkr_pos, true, false) -- moveview true, seekplay false // restore

end



function format_time_stamp(pos) -- format by adding leading zeros because r.format_timestr() ommits them
local name = r.format_timestr(pos, '')
return pos/3600 >= 1 and (pos/3600 < 10 and '0'..name or name) -- with hours
or pos/60 >= 1 and (pos/60 < 10 and '00:0'..name or name) -- without hours
or '00:0'..name -- without hours and minutes
end

function space(str)
return str:gsub('.','%0 '):match('(.+) ')
end


NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME
RENDER_TRACK_NAME = #RENDER_TRACK_NAME:gsub(' ','') > 0 and RENDER_TRACK_NAME

local err = 'NOTES_TRACK_NAME \n\n   setting is empty'
err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and err or not RENDER_TRACK_NAME and err:gsub('TARGET', 'RENDER')

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local notes_t = Get_Notes(NOTES_TRACK_NAME)

	if not notes_t then return r.defer(no_undo) end

::RELOAD::
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
local chapt_tags = r.GetExtState(named_ID, 'CHAPTERS')

local pad = ('▓'):rep(5)
function s(n) return (' '):rep(n) end
local menu = '|'..pad..space(' VIDEO ')..pad..'|||'..pad..space(' AUDIO ')..pad 
..'||'..chapt_tags..s(8)..'With chapter tags|'..s(7)..'(toggle, audio only)'
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 or output == 1 or output == 6 then return r.defer(no_undo) end

local video, audio = output == 2, output == 3

	if output == 4 then
	chapt_tags = #chapt_tags > 0 and '' or '!'
	r.SetExtState(named_ID, 'CHAPTERS', chapt_tags, false) -- persist false
	goto RELOAD
	end


r.Undo_BeginBlock()

Error_Tooltip("\n\n the process is underway... \n\n", 1, 1) -- caps, spaced true

	if video then

	local rend_tr = Get_Track(RENDER_TRACK_NAME)
	local itm_cnt = r.CountTrackMediaItems(rend_tr)

		if itm_cnt > 100 then		
		local resp = r.MB(s(8)..'There\'re already '..itm_cnt..' items\n\n'..s(9)
		..'on the "'..RENDER_TRACK_NAME..'" track.'..'\n\n'..s(7)..'Wish to recreate them all?', 'PROMPT', 4)
			if resp == 7 then
			r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
			return r.defer(no_undo) end
		end

	Remove_All_Segment_Markers() --do return end

	r.PreventUIRefresh(1)

		if not Insert_Items_At_Markers(rend_tr, notes_t, NOTES_TRACK_NAME, OVERLAY_PRESET) then
		Error_Tooltip('\n\n the overlay preset wasn\'t found \n\n', 1, 1) -- caps, spaced true
		r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		return r.defer(no_undo) end

	r.SetOnlyTrackSelected(rend_tr)
	r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view

	r.PreventUIRefresh(-1)

	elseif audio then

	Remove_All_Segment_Markers()

	Insert_Markers_For_Audio(notes_t, #chapt_tags > 0)

	end

Error_Tooltip('')	-- undo the 'process underway' tooltip

r.Undo_EndBlock('Transcribing: Prepare transcript for rendering', -1)





