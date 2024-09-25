--[[
ReaScript name: BuyOne_Transcribing B - Real time preview.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.37
About:	The script is part of the Transcribing B workflow set of scripts
			alongside  
			BuyOne_Transcribing B - Create and manage segments (MAIN).lua
			BuyOne_Transcribing B - Format converter.lua  
			BuyOne_Transcribing B - Import SRT or VTT file as regions.lua  
			BuyOne_Transcribing B - Prepare transcript for rendering.lua  
			BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
			BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
			BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua
			
			meant to display the transcript segment by segment in real time
			while REAPER is in play mode or when the edit cursor is located
			within segment regions.			
		
			The transcript is retrieved from the segment region names which 
			are defined by the SEGMENT_REGION_COLOR setting of the USER SETTINGS 
			and is displayed in the Video window segment by segment through 
			empty items which have an instance of the Video processor plugin 
			inserted in their FX chain with the preset defined in the OVERLAY_PRESET 
			setting. The segment transcript is fed into the preview item names.
			
			To have the transcript displayed within the Video window the 
			preview track must be located above the track with a video item.
			The preview items are added dynamically to accommodate segment
			next to the currently active segment which is determined by the 
			location of the edit or play cursor relative to the segment region. 
			Therefore while the transport is in play mode, in order to insert 
			a preview item for a particular segment without waiting until it'll 
			be added in the course of the playback, move the edit cursor to the 
			location immediately preceding the segment region.  
			This mechanism has been devised to overcome Video processor 
			limitation which prevents it from processing changes in track/take 
			names as soon as the change occurs so it must be allowed to process
			the content in advance.  
			If everything functions properly, during playback there should be no 
			more than 2 preview items on the prevew track at any given moment, 
			one for the current and another for the next segment. There'll be 
			only 1 when the last segment is being played and when the cursor is 
			located to the left of the very	first segment region.  
			When the transport is stopped, in order to have a preview item 
			created for a particular segment place the edit cursor directly 
			within the bounds (start and before the end) of the relevant segment 
			region. In this scenario it's possible to prevew the transcript within 
			video context simply by repeatedly running the custom actions 
			'Custom: Transcribing - Move loop points to next/previous segment'
			(included with the script set 
			in the file 'Transcribing workflow custom actions.ReaperKeyMap' )
			for instance by clicking the buttons linked to them on the 
			'Transcribing B toolbar' whose ReaperMenu file can be generated
			with  
			'BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua'
			script.
			
			For non-segment regions, i.e. regions whose color differs from 
			the one defined in the SEGMENT_REGION_COLOR setting, and segment 
			regions with no transcript preview items are not created.
			
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
			'BuyOne_Transcribing B - Prepare transcript for rendering.lua'
			however it's not as flexible as this one, because the preview
			items it creates are static and if segments have been updated 
			it will have to be run again to recreate the static preview items. 
			
			On the other hand this script creates redundant undo points each
			time a new preview item is inserted which cannot be prevented 
			and which increase and lengthen the undo history unnecessarily. 
			So it may be a good idea to use it in a project copy rathen than 
			directly in the main project. 
			
			Watch demo 'Transcribing B - 5. Real time preview.mp4' which comes 
			with the set of scripts

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


-- Between the quotes insert the name of the track
-- on which the previrw items will be placed;
-- if the prevew track isn't found the script will
-- create it and place at the end of the track list
PREVIEW_TRACK_NAME = "PREVIEW"


-- If you use the default "Overlay: Text/Timecode" preset
-- of the Video processor to preview transcript in video
-- context, keep this setting as is;
-- if you use a customized version of this preset, specify
-- its name in this setting between the quotes,
-- it's advised that the customized preset name be different
-- from the default one, otherwise its settings may get
-- affected by the script
OVERLAY_PRESET = "Overlay: Text/Timecode"


-- Enable by inserting any alphanumeric character between
-- the quotes;
-- only relevant if OVERLAY_PRESET setting is the default
-- "Overlay: Text/Timecode" preset
TEXT_WITH_SHADOW = ""


-- Enable by inserting any alphanumeric character between
-- the quotes to make the script delete all preview items
-- from the track named as specified in the PREVIEW_TRACK_NAME
-- setting above when this script is terminated
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
		if tr and r.ValidatePtr(tr, 'MediaTrack*') then -- delete preview items // validate to prevent error if preview track is deleted before the script is terminated
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



function insert_new_track(tr_name)
r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
r.PreventUIRefresh(-1)
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



function Aplly_Video_Proc_Settings(obj, OVERLAY_PRESET, TEXT_WITH_SHADOW)
local track, take = r.ValidatePtr(obj,'MediaTrack*'), r.ValidatePtr(obj,'MediaItem_Take*')
local SetParam = track and r.TrackFX_SetParam or take and r.TakeFX_SetParam
local input_fx_idx = track and 0x1000000 or 0
-- only set parameters if the preset is default because in the user version
-- everything will be set within the preset itself
	if OVERLAY_PRESET == 'Overlay: Text/Timecode' then
		if TEXT_WITH_SHADOW then
		-- table for overlay version with shadow which requires two Video proc instances
		-- the shadow is provided by the 2nd instance
		-- only values different from the default 'Overlay: Text/Timecode' preset are included
		-- 1 - y pos, 2 - x pos, 4 - text bright, 5 - text alpha, 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
		local t = {[0] = {[6]=0, [7]=1, [8]=1}, [1] = {[1]=0.953, [2]=0.504, [4]=0.6, [5]=0.5, [6]=0, [7]=0}}
			for fx_idx, vals_t in pairs(t) do
				for parm_idx, val in pairs(vals_t) do
				SetParam(obj, fx_idx+input_fx_idx, parm_idx, val)
				end
			end
		else
			for parm_idx, val in pairs({[6] = 0, [7] = 1, [8] = 1}) do -- 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
			SetParam(obj, input_fx_idx, parm_idx, val)
			end
		end
	end
end



function Insert_Video_Proc_Src_Track(OVERLAY_PRESET, TEXT_WITH_SHADOW)

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

	local function apply_overlay_preset(tr, newer_build)
	local show = not newer_build and r.TrackFX_Show(tr, 0x1000000, 3) -- showFlag 3 show floating window // in builds older than 7.20 in order to successfully apply Video proc preset the plugin UI must be opened
	local ok = r.TrackFX_SetPreset(tr, 0x1000000, OVERLAY_PRESET) -- fx 0
		if not ok then return end -- overlay reset not found

		-- only set parameters if build isn't newer because only in this case the video proc source track
		-- will be used as a source of video proc instances for preview items
		-- in order to avoid opening and closing its windows if applying directly
		-- as required in the buggy old builds;
		-- in newer builds video proc instances are inserted directly in the preview items
		if not newer_build then
		-- only runs if OVERLAY_PRESET is the default overlay preset
		Aplly_Video_Proc_Settings(tr, OVERLAY_PRESET, TEXT_WITH_SHADOW)
		r.TrackFX_Show(tr, 0x1000000, 2) -- showFlag 2 hide floating window opened above // only needed in older builds
		end

	return true -- if not reached this point, the overlay preset wasn't found
	end

local newer_build = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.20

	if not newer_build then -- search for Video proc source track and apply overlay preset if not applied
		for i=0, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i)
		local retval, fx_name = r.TrackFX_GetNamedConfigParm(tr, 0x1000000, 'fx_name') -- fx index 0 in the input fx chain // the function is the reason for minimal build being 6.37
		local vid_proc = fx_name == 'Video processor'
		local ret, preset = r.TrackFX_GetPreset(tr, 0x1000000, '') -- fx indxe 0 in the input fx chain
		local overlay = preset == OVERLAY_PRESET
		local ret, ext_state = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:SRC VIDEO PROC','',false) -- setNewValue false
			if #ext_state > 0 then
				if vid_proc then
					if overlay then return tr
					else
					local ok = apply_overlay_preset(tr, newer_build, TEXT_WITH_SHADOW)
						if not ok then return
						else return tr
						end
					end
				else
				r.TrackFX_AddByName(tr, 'Video processor', true, -1000-0x1000000) -- recFX true, instantiate -1000 first fx slot in the input fx chain
				local ok = apply_overlay_preset(tr, newer_build, TEXT_WITH_SHADOW)
					if not ok then return
					else return tr
					end
				end
			end
		end
	end

-- if tr wasn't found above, create one
local tr = insert_new_track('')
r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0) -- hide in mixer
r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0) -- hide in TCP
local retval, fx_name = r.TrackFX_GetNamedConfigParm(tr, 0x1000000, 'fx_name') -- fx 0
	if not retval or fx_name ~= 'Video processor' then
	r.TrackFX_AddByName(tr, 'Video processor', true, -1000-0x1000000) -- recFX true, instantiate -1000 first fx slot in the input fx chain
	local second_inst = TEXT_WITH_SHADOW and r.TrackFX_AddByName(tr, 'Video processor', true, -1001-0x1000000) -- for shadow two instance are required
	end
local ret, preset = r.TrackFX_GetPreset(tr, 0x1000000, '') -- fx 0
	if preset ~= OVERLAY_PRESET then -- apply
	local ok = apply_overlay_preset(tr, newer_build, TEXT_WITH_SHADOW)
		if not ok or ok and newer_build then -- deleting track if not found in any build and if found in newer builds because in this case the track was only needed to check availability of the preset
		r.DeleteTrack(tr)
		return ok and newer_build end -- in newer builds returning true if found to prevent triggering error message outside, in older builds the return value will always be false which will trigger the error message informing that the preset wasn't found
	end
r.GetSetMediaTrackInfo_String(tr, 'P_NAME','Video processor source',true) -- setNewValue true
r.GetSetMediaTrackInfo_String(tr, 'P_EXT:SRC VIDEO PROC','1',true) -- setNewValue true

r.PreventUIRefresh(-1)

return tr

end



function Insert_Delete_Preview_Items(preview_tr, pos, reg_t, src_tr, first_reg_pos)
-- pos is location of the current marker
-- when pos is nil all preview items are deleted and the function is exited
-- when pos is -1 it must be accompanied with valid first_reg_pos arg
-- in which case the preview item is created at first_reg_pos rather than next valid

	-- prevent error message when the project is reloaded while the script is running
	if not r.ValidatePtr(preview_tr, 'MediaTrack*') then return end

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


local next_pos = pos > -1 and reg_t and reg_t[pos].pos -- pos arg is -1 when first_reg_pos arg is included to insert 1st preview item when cursor is to the left of the 1st region, in which case next_pos must be the first region position itself, see expression below, rather than next region position as designed to be by the table structure in Get_Segment_Regions()
next_pos = first_reg_pos or next_pos

	if not next_pos then return end -- no next region data has been found, likely the last region or not a segment region

-- Insert next preview item at the next region

-- Create explicit undo point because TakeFX_AddByName, TakeFX_SetPreset and Item properties: Loop item source
-- create them anyway and 3 rather than 1
r.Undo_BeginBlock()

local act = r.Main_OnCommand
--[[ WORKS
r.SetOnlyTrackSelected(preview_tr)
--r.SetEditCurPos(next_pos, false, false) -- moveview, seekplay false
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
	-- if TEXT_WITH_SHADOW sett is enabled, two video proc instances are used
	-- copy the second one
	local copy = TEXT_WITH_SHADOW and r.TrackFX_CopyToTake(src_tr, 1+0x1000000, take, 1, false) -- ismove false
	else -- directly, which is supported since 7.20 where there's no need to open Video proc UI to apply preset correctly
	r.TakeFX_AddByName(take, 'Video processor', -1000) -- instantiate -1000 first fx chain slot
--	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.20
--	r.TakeFX_Show(take, 0, 3) -- showFlag 3 show floating window
	r.TakeFX_SetPreset(take, 0, OVERLAY_PRESET) -- fx 0
	-- if TEXT_WITH_SHADOW sett is enabled two video proc instances are used
	local copy = TEXT_WITH_SHADOW and r.TakeFX_CopyToTake(take, 0, take, 1, false) -- ismove false
	end

-- only runs if OVERLAY_PRESET is the default overlay preset
Aplly_Video_Proc_Settings(take, OVERLAY_PRESET, TEXT_WITH_SHADOW)

local len = reg_t[next_pos] and reg_t[next_pos].fin -- if next_pos is the last region position, reg_t[next_pos] will be invalid

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

r.Undo_EndBlock('Transcribing B: Insert preview item',-1)

return take -- return next preview item take

end



function Get_Segment_Regions(reg_color)

local i, reg_t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
		if retval > 0 and isrgn and color == reg_color and #name:gsub('[%s%c]','') > 0 then
		reg_t[pos] = {pos=pos, fin=rgnend-pos, txt=name}
		reg_t.first_reg_pos = reg_t.first_reg_pos or pos
		reg_t.last_reg_fin = rgnend
		end
	i = i+1
	until retval == 0

return reg_t

end



function Get_Next_Segment(start_idx, reg_color, cur_pos)
-- accounts for invalid regions which should
-- always be ignored as if non-existent and looked past in search
-- of the next segment region;
-- if there're very short gaps between segments
-- the next segment preview item must be created before
-- such gap has been reached because if created while
-- the cursor is within the gap the time is too short
-- for the Video proc to pocess the upcoming preview item
-- which results in the lag in the segment display within Video window

	if cur_pos then -- current region idx is -1 (cursor is outside of all regions) therefore the only way to get a meaningful start_idx value is to search from the cursor pos
	local i, proj_len = 0, r.GetProjectLength(0)
		repeat
		cur_pos = cur_pos+0.1 -- increment by 100 ms until a region is found
		local mrkr_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, cur_pos)
			if reg_idx > -1 then start_idx = reg_idx break end
		i=i+1
		until reg_idx > -1 or cur_pos >= proj_len -- if not found stop at the end of project
	end

	if start_idx then
	local i = start_idx
		repeat
		local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0,i)
			if retval > 0 and isrgn and color == reg_color and #name:gsub('[%s%c]','') > 0 then
			return pos, name
			end
		i = i+1
		until retval == 0
	end

end



function RUN_PREVIEW()

local proj, projfn = r.EnumProjects(-1)

	if projfn == projfn_init then -- only run under the same project which the script was initially launched under

	local reg_t = Get_Segment_Regions(REG_COLOR)
	local plays = r.GetPlayState()&1 == 1

		if src_tr and not r.ValidatePtr(src_tr, 'MediaTrack*') then
		-- recreate Video proc src track if was deleted after initial creation
		src_tr = Insert_Video_Proc_Src_Track(OVERLAY_PRESET, TEXT_WITH_SHADOW)
		end

		if not last_playpos or plays and r.GetPlayPosition() < last_playpos
		or not plays and r.GetCursorPosition() < last_playpos then
		Insert_Delete_Preview_Items(preview_tr) -- pos nil will trigger deletion of all later preview items when cursor has been moved left
		reg_idx_init = nil -- reset // ensures that the content associated with the very first region can be retriggered if the play cursor has been moved back before reaching the 2nd region and before reg_idx has changed to the 2nd one
		end

	-- update active segment in response to play or edit cursor position
	local cur_pos = plays and r.GetPlayPosition() -- playing
	or r.GetCursorPosition()
	local mrkr_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, cur_pos) -- returns -1 if not preceded by any marker/region contrary to the API doc
	local pos_next, segment_txt_next = Get_Next_Segment(reg_idx+1, REG_COLOR, reg_idx == -1 and cur_pos) -- start_idx is reg_idx+1, if reg_idx is -1 search is perfomed from cur_pos // get next segment region pos and next segment transcript to insert next segment preview item

		-- only relevant in play mode
		if plays and (cur_pos < reg_t.first_reg_pos -- cursor is to the left of the very first segment region
		or cur_pos >= reg_t.last_reg_fin) -- cursor is to the right of the last segment region (which will be last segment region end)
		then -- insert 1st segment preview item when the playhead is to the left of the very first region or to the right of the very last, the latter is meant to accommodate cases where the very 1st segment region is located at the very beginning of the project in which case there'll be no other way to insert 1st segment preview item in advance

			if not first_preview_take then -- first_preview_take cond ensures that the function runs only once when the cursor has moved to the left of the very 1st region, otherwise the first segment preview item will keep being created and deleted here
			Insert_Delete_Preview_Items(preview_tr) -- pos nil will trigger deletion of all preview items
			local pos, segment_txt = Get_Next_Segment(0, REG_COLOR) -- start_idx is 0 // get first region pos and 1st segment transcript to add to the first segment preview item
				if pos then -- pos is equal to reg_t.first_reg_pos
				first_preview_take = Insert_Delete_Preview_Items(preview_tr, -1, reg_t, src_tr, pos) -- insert 1st segment preview item, -1 is pos argument to trigger creation of a preview item at pos which is first_reg_pos argument rather than at reg_t[pos]
				local insert = first_preview_take and r.ValidatePtr(first_preview_take, 'MediaItem_Take*') and r.GetSetMediaItemTakeInfo_String(first_preview_take, 'P_NAME', segment_txt:match('%S.+'):gsub('%s*<n>%s*','\n'), true) -- setNewValue true // trimming leading spaces and converting new line tag into the new line control character
				end
			end

		last_playpos = 0 -- initialize, used as a condition to allow riggering later preview items deletion when cursor has been moved left past the very 1st region; also prevents deletion of the 1st segment preview item inserted above while the cursor is to the left of the 1st region because of last_playpos being nil

		elseif reg_idx > -1 and reg_idx ~= reg_idx_init or reg_idx == -1 and pos_next_init ~= pos_next then -- new region or a gap between regions has come along during playback or as a result of cursor movement // region index comparison doesn't cover all cases of cursor location between regions, e.g. when cursor is moved from one inter-region location to another in which case reg_idx will be equal to reg_idx_init, i.e. -1, and the condition will be false preventing creation of preview item relative to the new location, whereas pos_next will be different in this case; comparing cursor position instead is flawed because during playback it constantly changes while running between two adjacent regions and the condition unnecessarily triggers this routine resulting in creation of multiple preview items at the next pos

		first_preview_take = nil -- reset once 1st segment region has been reached so that when the loop comes around or cursor is moved left of the very first region the first segment preview item creation condition could be true again

		reg_idx_init = reg_idx -- prevents the routine from running until new region comes along

		last_playpos = cur_pos -- update, used as a condition to allow triggering later preview items deletion when cursor has been moved left and prevent the routine from running as long as cursor position hasn't changed

		-- manage preview items
		local retval, isrgn, pos_cur, rgnend, name, idx = r.EnumProjectMarkers(reg_idx)
		local pos = retval > 0 and pos_cur or pos_next -- if reg_idx is valid get current region pos (non-segment regions are allowed) otherwise use next found segment region pos
		Insert_Delete_Preview_Items(preview_tr, pos) -- reg_t arg is nil to trigger deletion of previous preview item INCLUDING the penulimate when the last segment is being played AND the last when the cursor has moved past last region, which won't occur if the deletion is conditioned by pos_next below because in this case pos_next will be nil due to absense of the next segment and the function won't run AND INCLUDING item previous to invalid region or region gap // after deletion the function exits due to lack of other arguments

				-- when stopped, set pos_next to current segment region pos (if valid) and current segment text,
				-- rather than the next, this ensures that when not playing, prevew items are placed at the current
				-- segment region because in this scenario timely change of transcript in the video context isn't
				-- necessary and placing cursor ahead of the segment region for item creation creates an inconvenience
				-- of text not being updated in the video window right away so you have to additionally move the cursor
				-- to within the next region where prevew item has been created to see the new text
				if not plays then
					if reg_idx > -1 then -- OR if reg_t[pos_cur] to only insert when there's a valid region at cursor
					segment_txt_next = select(2, Get_Next_Segment(reg_idx, REG_COLOR))
					pos_next = pos_cur -- set to current cursor position rather than the next
					else -- ensures the pos_next var below is false so item cannot be created when the edit cursor is in between regions
					pos_next = nil
					end
				end

			-- insert next preview item
			if pos_next and reg_t[pos_cur] -- reg_t[pos_cur] ensures that item is only inserted when current region is valid which prevents duplication of an already inserted item when an invalid region comes along
			then
			local preview_take = Insert_Delete_Preview_Items(preview_tr, -1, reg_t, src_tr, pos_next) -- insert preview item after a region or after a gap between valid ones, -1 is pos argument to trigger creation of the preview item at pos_next which is first_mrkr_pos arg rather than at reg_t[pos]
			local insert = preview_take and r.ValidatePtr(preview_take, 'MediaItem_Take*') and r.GetSetMediaItemTakeInfo_String(preview_take, 'P_NAME', segment_txt_next:match('%S.+'):gsub('%s*<n>%s*','\n'), true) -- setNewValue true // trimming leading spaces and converting new line tag into the new line control character
			pos_next_init = pos_next
			end

		end -- reg_idx > -1 and reg_idx ~= reg_idx_init cond end

	end

r.defer(RUN_PREVIEW)

end



REG_COLOR = Validate_HEX_Color_Setting(SEGMENT_REGION_COLOR)

local err = 'the segment_region_color \n\n'
err = #SEGMENT_REGION_COLOR:gsub(' ','') == 0 and err..'\t  setting is empty'
or not REG_COLOR and err..'\t setting is invalid'
or #PREVIEW_TRACK_NAME:gsub('[%s%c]','') == 0 and 'PREVIEW_TRACK_NAME \n\n   setting is empty'
or #OVERLAY_PRESET:gsub('[%s%c]','') == 0 and 'OVERLAY_PRESET setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local theme_reg_col = r.GetThemeColor('region', 0)
REG_COLOR = r.ColorToNative(table.unpack{hex2rgb(REG_COLOR)})
err = REG_COLOR == theme_reg_col and " the segment_region_color \n\n\tsetting is the same"
.."\n\n    as the theme's default\n\n     which isn't suitable\n\n\t   for the script"
or not next(Get_Segment_Regions(REG_COLOR|0x1000000)) and 'no segment regions' -- converting color to the native format returned by object functions

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


TEXT_WITH_SHADOW = OVERLAY_PRESET == "Overlay: Text/Timecode" and #TEXT_WITH_SHADOW:gsub(' ','') > 0

r.Undo_BeginBlock()

src_tr = Insert_Video_Proc_Src_Track(OVERLAY_PRESET, TEXT_WITH_SHADOW)

	if not src_tr then
	Error_Tooltip('\n\n the overlay preset wasn\'t found \n\n', 1, 1) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo)
	end

src_tr = r.ValidatePtr(src_tr,'MediaTrack*') and src_tr -- src_tr is returned as 'true' when the overlay preset was found in builds 7.20 and later, but the src_tr itself isn't needed there because the preset can be applied without opening the Video proc UI, hence turned into false

preview_tr = Get_Or_Create_Preview_Track(PREVIEW_TRACK_NAME)

r.Undo_EndBlock('Transcribing B: Create preview track', -1)

CLEANUP = #CLEANUP:gsub(' ','') > 0
REG_COLOR = REG_COLOR|0x1000000 -- convert color to the native format returned by object functions

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

proj_init, projfn_init = r.EnumProjects(-1)
local reg_idx_init, last_playpos, playstate, pos_next_init

RUN_PREVIEW()

r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0, preview_tr, src_tr))









