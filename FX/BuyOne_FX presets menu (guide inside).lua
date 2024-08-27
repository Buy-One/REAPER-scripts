--[[
ReaScript name: BuyOne_FX presets menu (guide inside).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 2.1
Changelog: 2.1 #Fixed absence of VST3 default preset in the displayed preset list
	       #Tried to somewat ameliorate the effect of preset navigation ReaScript function bug in builds 7.09 - 7.20 [t=293952]
	       #Thoroughly refactored the code to make preset retrieval hopefully faster
	       #Added a workaround for ampersand in present names to replace it with '+' 
	       for display in the menu, otherwise it won't be visible
	       #Made sure FX selection in the target chain is not affected by the script (except in Monitoring FX chain)
	       #Added two new settings to ignore track main and input/Monitoring FX
	       #Updated 'REAPER' tag in this header
	       #Updated 'About' text in this header
	   v2.0 #Added a setting to keep the menu open after clicking a menu item
		#Added an error message when there's no object under the mouse cursor
		#Increased the size of error tooltips so they're more noticeable 
	   v1.9 Fixed REAPER version evaluation
	   v1.8 #Improved detection of the TCP under mouse when it's displayed on the right side of the Arrange
		view at certain horizontal scroll position 
	   v1.7 #Fixed logic of TCP detection under mouse
	   v1.6 #Added support for TCP on the right side of the Arrange
	   v1.5 #Fixed error on loading preset menu of plugins with embedded presets and no external preset file
	   v1.4 #Fixed Arrange view movement when object under mouse is being detected while the edit cursor is out of sight
	   v1.3 #Fixed losing item focus and unnecessary horizontal scroll for REAPER builds prior to 6.37
		#Fixed transport stop when getting TCP under mouse cursor for REAPER builds prior to 6.37
		#Added MCP support for REAPER builds 6.37 onward
		#Minor code optimizations
		#Updated the Guide
	   v1.2.1 #Minor fix of relational operator
	   v1.2 #Preset menu of FX in a focused take FX chain is now displayed reragdless of the take being active
	 	#Added new option to lock FX chain focus
		#Updated the Guide
	   v1.1 #Added support for displaying FX presets menu when FX chain is focused
		#Updated the Guide
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About:
	#### G U I D E

	- The script displays FX preset menu of the object (track or item/active take)
	either currently found under the mouse cursor or the last selected if 
	SEL_OBJ_IN_CURR_CONTEXT setting is enabled in the USER SETTINGS below, or of the 
	currently or last focused FX chain window. With regard to track FX, for REAPER 
	builds prior to 6.37 only TCP is supported.

	- It's only able to list presets available in REAPER plugin wrapper drop-down list
	including imported .vstpreset files.

	- Since in multi-take items the menu only lists active take FX presets, if you need
	FX presets from a take other then the active simply click on it to have it activated.

	- Track preset menu is divided into two sections, main FX menu (upper) and 
	input FX menu (lower) if both types of FX are present unless IGNORE_INPUT_FX setting
	is enabled.   
	In the Master track FX preset menu instead of the preset menu for input FX a menu 
	for Monitor FX is displayed.

	- If there's active preset and plugin controls configuration matches the preset settings
	the preset name in the menu is checkmarked.

	- The script can be called in the following ways:  
	1) by placing the mouse cursor over the object or its FX chain window and calling
	the script with a shortcut assigned to it;  
	2) by assigning it to a Track AND an Item mouse modifiers under *Preferences -> Mouse modifiers*
	and actually clicking the object to call it;  
	If SEL_OBJ_IN_CURR_CONTEXT setting is enabled in the USER SETTINGS below:  
	3) from an object right click context menu (main menus are not reliable);  
	4) from a toolbar, the toolbar must either float over the Arrange or be docked in the top
	or bottom dockers; Main toolbar or other docker positions are not reliable;  
	5) from the Action list (which is much less practicable)  
	In cases 3)-5) the object must be selected as the mouse cursor is away from it.  
	All five methods can work in parallel.  
	Be aware that when SEL_OBJ_IN_CURR_CONTEXT setting is enabled and the script is run via 
	a keyboard shortcut, the menu will be called even when the mouse cursor is outside of the TCP 
	or Arrange and not over an FX chain window, like over the ruler, TCP bottom, empty Mixer area 
	or any other focused window, in which case it will display a list of the last selected object 
	FX presets.
	
	- LOCK_FX_CHAIN_FOCUS setting in the USER SETTINGS allows displaying presets menu for FX of the last 
	focused open FX chain even when the mouse cursor is outside of the FX chain window and it itself isn't 
	in focus but still open, regardless of the last selected object in case SEL_OBJ_IN_CURR_CONTEXT 
	setting is enabled and regardless of the active take if the focus is locked on a take FX chain.

	- To close the menu after it's been called, without selecting any preset, either click elsewhere
	in REAPER or pres Esc keyboard key.
	
	- Video processor preset menu is supported from REAPER build 6.26 onwards.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the option place any alphanumeric character between
-- the quotation marks.

-- Enable to make the script ignore track input FX
-- and Master track Monitor FX presets
local IGNORE_INPUT_FX = ""

-- Enable to make the script ignore tracks main FX presets
local IGNORE_MAIN_FX = ""

-- If mouse cursor is outside of Arrange/TCP/MCP,
-- i.e. docked toolbar button click, execution from the Action list,
-- selected track or item will be targeted depending on the current mouse
-- cursor context;
-- to change the context click within the track list or within the Arrange;
-- only one object selection per context is supported.
local SEL_OBJ_IN_CURR_CONTEXT = ""

-- If FX chain window is open and was last focused
local LOCK_FX_CHAIN_FOCUS = ""

-- Enable to keep the menu open after a menu item
-- has been clicked, which is convenient if you need
-- to try and audition different presets in turn;
-- to close the menu click away or hit Escape key
local KEEP_MENU_OPEN = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function StoreSelectedObjects()

-- Store selected items
local sel_itms_cnt = r.CountSelectedMediaItems(0)
local itm_sel_t = {}
	if sel_itms_cnt > 0 then
	local i = 0
		while i < sel_itms_cnt do
		itm_sel_t[#itm_sel_t+1] = r.GetSelectedMediaItem(0,i)
		i = i+1
		end
	end

-- Store selected tracks
local sel_trk_cnt = reaper.CountSelectedTracks2(0,1) -- plus Master
local trk_sel_t = {}
	if sel_trk_cnt > 0 then
	local i = 0
		while i < sel_trk_cnt do
		trk_sel_t[#trk_sel_t+1] = r.GetSelectedTrack2(0,i,1) -- plus Master
		i = i+1
		end
	end
return itm_sel_t, trk_sel_t
end



function RestoreSavedSelectedObjects(itm_sel_t, trk_sel_t)
-- if none were selected keep the latest selection

r.PreventUIRefresh(1)

r.Main_OnCommand(40289,0) -- Item: Unselect all items
	if #itm_sel_t > 0 then
	local i = 0
		while i < #itm_sel_t do
		r.SetMediaItemSelected(itm_sel_t[i+1],1)
		i = i + 1
		end
	end

r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	if #trk_sel_t > 0 then -- not needed if Master track is being gotten without its selection
	r.SetTrackSelected(r.GetMasterTrack(0),0) -- unselect Master
		for _,v in next, trk_sel_t do
		r.SetTrackSelected(v,1)
		end
	end

r.UpdateArrange()
r.TrackList_AdjustWindows(0)
r.PreventUIRefresh(-1)
end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end



function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end



local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



function FX_Chain_Chunk(chunk, path, sep) -- isolate object fx chain
local fx_chunk
	if chunk and #chunk > 0 then
	fx_chunk = chunk:match('(<FXCHAIN.*>)\n<FXCHAIN_REC') or chunk:match('(<FXCHAIN.->)\n<ITEM') or chunk:match('(<FXCHAIN.*WAK.*>)\n>')
	end
return fx_chunk
end



function Collect_VideoProc_Instances(fx_chunk)

local video_proc_t = {} -- collect indices of video processor instances, because detection by fx name is unreliable as not all its preset names contain 'video processor' phrase due to length
local counter = 0 -- to store indices of video processor instances

	if fx_chunk and #fx_chunk > 0 then
		for line in fx_chunk:gmatch('[^\n\r]*') do -- all fx must be taken into account for video proc indices to be accurate
		local plug = line:match('<VST') or line:match('<AU') or line:match('<JS') or line:match('<DX') or line:match('<LV2') or line:match('<VIDEO_EFFECT')
			if plug then
				if plug == '<VIDEO_EFFECT' then
				video_proc_t[counter] = '' -- dummy value as we only need indices
				end
			counter = counter + 1
			end
		end
	end

return video_proc_t

end



function Collect_FX_Preset_Names(temp_track, src_fx_cnt, src_fx_idx, pres_cnt)
-- getting all preset names in a roundabout way by travesring them in an instance on a temp track
-- cannot traverse in the source track because if plugin parameters haven't been stored in a preset
-- after traversing they will be lost and will require prior storage and restoration whose accuracy isn't guaranteed

r.TrackFX_SetPresetByIndex(temp_track, src_fx_idx, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, src_fx_idx) -- actually redundant as pres_cnt is passed as argument

local preset_name_t = {}
-- in builds 7.09 - 7.20 FX_NavigatePresets() function glitched on VST2 plugins with no default preset
-- but it worked if instead of 1 and -1 for navigation, actual index was passed as 'presetmove' arg
-- 0,1,2 etc (0-based) for navigation from top, -1,-2,-3 etc (1-based) for navigation from bottom
-- https://forum.cockos.com/showthread.php?t=293952
local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local bug = build > 7.08 and build < 7.21
local st, fin = table.unpack(bug and {0, pres_cnt-1} or {1, pres_cnt})

	for i = st, fin do
		if bug then
		r.TrackFX_SetPresetByIndex(temp_track, src_fx_idx, i) -- alternative in case in buggy builds passing index into FX_NavigatePresets() will glitch out, however it itelf doesn't work if no preset is selected
		else
		r.TrackFX_NavigatePresets(temp_track, src_fx_idx, 1)
		end
	local _, pres_name = r.TrackFX_GetPreset(temp_track, src_fx_idx, '')
	preset_name_t[bug and i+1 or i] = pres_name..'|' -- in buggy builds loop starts from 0 hence i must be incremented by 1
	end

	if src_fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<')
	end

	if #preset_name_t > 0 and
	(#preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt) -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end



function Collect_VideoProc_Preset_Names(temp_track, fx_cnt, src_fx_idx, pres_cnt)
-- builtin_video_processor.ini file only stores user added presets to the exclusion of the stock ones
-- getting all preset names in a roundabout way by travesring them in an instance on a temp track

r.TrackFX_SetPresetByIndex(temp_track, src_fx_idx, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, src_fx_idx) -- actually redundant as pres_cnt is passed as argument

local preset_name_t = {}

	for i = 1, pres_cnt do
	r.TrackFX_NavigatePresets(temp_track, src_fx_idx, 1) -- forward
	local _, pres_name = r.TrackFX_GetPreset(temp_track, src_fx_idx, '')
	preset_name_t[i] = pres_name..'|'
	end

	if fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<')
	end

	if #preset_name_t > 0 and #preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end


function Collect_VST3_Instances(fx_chunk) -- replicates Collect_VideoProc_Instances()

-- required to get hold of .vstpreset file names stored in the plugin dedicated folder and list those in the menu

local vst3_t = {} -- collect indices of vst3 plugins instances, because detection by fx name is unreliable as it can be changed by user in the FX browser
local counter = 0 -- to store indices of vst3 plugin instances

	if fx_chunk and #fx_chunk > 0 then
		for line in fx_chunk:gmatch('[^\n\r]*') do -- all fx must be taken into account for vst3 plugin indices to be accurate
		local plug = line:match('<VST') or line:match('<AU') or line:match('<JS') or line:match('<DX') or line:match('<LV2') or line:match('<VIDEO_EFFECT')
			if plug then
				if line:match('VST3') then
				vst3_t[counter] = '' -- dummy value as we only need indices
				end
			counter = counter + 1
			end
		end
	end

return vst3_t

end



function Collect_VST3_Preset_Names(temp_track, src_fx_cnt, src_fx_idx, pres_cnt) -- replicates Collect_VideoProc_Preset_Names()

-- getting all preset names incuding .vstpreset file names in a roundabout way by travesring them in an instance on a temp track


r.TrackFX_SetPresetByIndex(temp_track, src_fx_idx, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, src_fx_idx) -- actually redundant as pres_cnt is passed as argument

local preset_name_t = {}

	for i = 1, pres_cnt do
	r.TrackFX_NavigatePresets(temp_track, src_fx_idx, 1) -- forward
	local _, pres_name = r.TrackFX_GetPreset(temp_track, src_fx_idx, '')
	-- VST3 plugins may contain default preset whose name is returned as an empty string, so concatenate
	pres_name = #pres_name:gsub(' ','') > 0 and pres_name or 'Default'
	local pres_name = pres_name:match('.+[\\/](.+)%.vstpreset$') or pres_name
	preset_name_t[i] = pres_name..'|'
	end

	if src_fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<')
	end

	if #preset_name_t > 0 and
	(#preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt) -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function Get_Object(LOCK_FX_CHAIN_FOCUS)

-- Before build 6.37 GetCursorContext() and r.GetTrackFromPoint(x, y) are unreliable in getting TCP since the track context and coordinates are true along the entire timeline as long as it's not another context
-- using edit cursor to find TCP context instead since when mouse cursor is over the TCP edit cursor doesn't respond to action 'View: Move edit cursor to mouse cursor' // before build 6.37 STOPS PLAYBACK WHILE GETTING TCP
-- Before build 6.37 no MCP support; when mouse is over the Mixer on the Arrange side the trick to detect track panel doesn't work, because with 'View: Move edit cursor to mouse cursor' the edit cursor does move to the mouse cursor

	local function GetMonFXProps() -- get mon fx accounting for floating window, GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

		local master_tr = r.GetMasterTrack(0)
		local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
		local is_mon_fx_float = false -- only relevant if there's need to reopen the fx in floating window
			if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
				for i = 0, r.TrackFX_GetRecCount(master_tr) do
					if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
					src_mon_fx_idx = i; is_mon_fx_float = true break end
				end
			end
		return src_mon_fx_idx, is_mon_fx_float
	end

r.PreventUIRefresh(1)

local retval, tr, item = r.GetFocusedFX() -- account for focused FX chains and Mon FX chain in builds prior to 6.20
local fx_chain_focus = LOCK_FX_CHAIN_FOCUS or r.GetCursorContext() == -1

local obj, obj_type

	if (retval > 0 or GetMonFXProps() >= 0) and fx_chain_focus then -- (last) focused FX chain as GetFocusedFX() returns last focused which is still open
	obj, obj_type = table.unpack(retval == 2 and tr > 0 and {r.GetTrackMediaItem(r.GetTrack(0,tr-1), item), 1} or retval == 1 and tr > 0 and {r.GetTrack(0,tr-1), 0} or {r.GetMasterTrack(0), 0})
	else -- not FX chain
	local x, y = r.GetMousePosition()
		if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37 then -- SUPPORTS MCP
		local retval, info_str = r.GetThingFromPoint(x, y)
		obj, obj_type = table.unpack(info_str == 'arrange' and {({r.GetItemFromPoint(x, y, true)})[1], 1} -- allow locked is true
		or info_str:match('[mt]cp') and {r.GetTrackFromPoint(x, y), 0} or {nil})
		else
		-- First get item to avoid using edit cursor actions
		--[-[------------------------- WITHOUT SELECTION --------------------------------------------
		obj, obj_type = ({r.GetItemFromPoint(x, y, true)})[1], 1 -- get without selection, allow locked is true, the function returns both item and take pointers, here only item's is collected, works for focused take FX chain as well
		--]]
		--[[-----------------------------WITH SELECTION -----------------------------------------------------
		r.Main_OnCommand(40289,0) -- Item: Unselect all items;  -- when SEL_OBJ_IN_CURR_CONTEXT option in the USER SETTINGS is OFF to prevent getting any selected item when mouse cursor is outside of Arrange proper (e.g. at the Mixer or Ruler or a focused Window), forcing its recognition only if the item is under mouse cursor, that's because when cursor is within Arrange and there's no item under it the action 40528 (below) itself deselects all items (until their selection is restored at script exit) and GetSelectedMediaItem() returns nil so there's nothing to fetch the data from, but when the cursor is outside of the Arrange proper (e.g. at the Mixer or Ruler) this action does nothing, the current item selection stays intact and so GetSelectedMediaItem() does return first selected item identificator
		r.Main_OnCommand(40528,0) -- Item: Select item under mouse cursor
		obj, obj_type = r.GetSelectedMediaItem(0,0), 1
		--]]
			if not obj then -- before build 6.37, EDIT CURSOR ACTIONS MAKE RUNNING TRANSPORT STOP !!!!!
			local curs_pos = r.GetCursorPosition() -- store current edit curs pos
			local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true
			local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
			local edge = right_tcp and start_time-5 or end_time+5
			r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0
			r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
			local new_cur_pos = r.GetCursorPosition()
				if new_cur_pos == edge or new_cur_pos == 0 then -- the edit cursor stayed put at the pos set above since the mouse cursor is over the TCP // if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
				--[-[------------------------- WITHOUT SELECTION --------------------------------------------
				obj, obj_type = r.GetTrackFromPoint(x, y), 0 -- get without selection, works for focused track FX chain as well
				--]]
				--[[-----------------------------WITH SELECTION -----------------------------------------------------
				r.Main_OnCommand(41110,0) -- Track: Select track under mouse
				obj, obj_type = r.GetSelectedTrack2(0,0, true), 0 -- account for Master is true
				--]]
				end
			-- restore edit cursor position
		--[[
			local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
			or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
			or {0,0})
			r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
		--]]
		-- OR SIMPLY
			r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
			end
		end
	end

r.PreventUIRefresh(-1)

	return obj, obj_type

end



function Insert_Delete_Temp_Track(obj, input_fx, temp_tr)
-- input_fx is boolean to modify fx indices

	if not temp_tr then
	r.PreventUIRefresh(1)
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
	local temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange

	local countFX, copyFX = table.unpack(r.ValidatePtr(obj, 'MediaItem_Take*')
	and {r.TakeFX_GetCount, r.TakeFX_CopyToTrack}
	or r.ValidatePtr(obj, 'MediaTrack*')
	and {input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_CopyToTrack} or {})

		if countFX then
			for i=0, countFX(obj)-1 do
			local src_fx_idx = input_fx and i+0x1000000 or i
			copyFX(obj, src_fx_idx, temp_tr, i, false) -- is_move false
			end
		r.PreventUIRefresh(-1)
		return temp_tr
		end

	else
	r.DeleteTrack(temp_tr)
	end

end




function GetSet_FX_Selected_In_FX_Chain(obj, sel_idx, chunk, input_fx)
-- functions FX_Copy_To_Take(), FX_Copy_To_Track() in particular change fx selection in the source chain, making selected the last addressed fx
-- so the original selection requires restoration
-- sel_idx is string, input_fx is boolean to address input fx chain
-- chunk comes from GetObjChunk(), relevant at both stages
-- used in builds older than 7.06, as well as SetObjChunk()
-- Since 7.06 FX_GetNamedConfigParm() 'chain_sel' can be used, e.g.
-- FX_GetNamedConfigParm(obj, -1, 'chain_sel')
-- FX_SetNamedConfigParm(obj, -1, 'chain_sel', fx_idx) -- fx_idx is a string
-- https://forum.cockos.com/showthread.php?t=285177#19
-- so chunk arg can be ommitted
-- doesn't support containers
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
local take, tr = r.ValidatePtr(obj, 'MediaItem_Take*'), r.ValidatePtr(obj, 'MediaItem_Track*')
local FX_Chain_Vis, FX_Open, Get_Conf_Parm, Set_Conf_Parm = table.unpack(take and {r.TakeFX_GetChainVisible, r.TakeFX_SetOpen, r.TakeFX_GetNamedConfigParm,r.TakeFX_SetNamedConfigParm} or tr and {r.TrackFX_GetChainVisible, r.TrackFX_SetOpen, r.TrackFX_GetNamedConfigParm, r.TrackFX_SetNamedConfigParm} or {})
local input_fx = tr and input_fx -- validate so it's only valid if object is track

	if not sel_idx then -- GET
		if old or input_fx then -- use chunk, chunk holds the selected index even if none is visually selected
		local found
			for line in chunk:gmatch('[^\n\r]+') do
				if not input_fx and line:match('LASTSEL') then return line:match('%d+')
				elseif input_fx and obj ~= r.GetMasterTrack(0) then -- Monitoring FX selection cannot be set via chunk because their chunk is stored in reaper-hwoutfx.ini file rather than in the master track chunk and the file cannot be updated as long as REAPER runs
					if line:match('<FXCHAIN_REC') then found = 1
					elseif found and line:match('LASTSEL') then return line:match('%d+')
					end
				end
			end
		else
		return select(2, Get_Conf_Parm(obj, -1, 'chain_sel')) -- returns value even if none is visually selected as long as there're fx in the chain
		end
	else -- SET
		if old or input_fx then -- use chunk
		-- if object data changed in between the function executions
		-- the chunk must be re-get for the restoration stage
		local fx_chain = ''
			for line in chunk:gmatch('[^\n\r]+') do
			-- collect chunk up to LASTSEL token
				if not input_fx then
				fx_chain = fx_chain..'\n'..line
					if line:match('LASTSEL') then break end
				elseif input_fx and obj ~= r.GetMasterTrack(0) then -- regarding master track see comment above
					if line:match('<FXCHAIN_REC') or #fx_chain > 0 then
					fx_chain = fx_chain..'\n'..line
						if line:match('LASTSEL') then break end
					end
				end
			end
			-- weirdly enough after using FX_Copy_To_Take(), FX_Copy_To_Track()
			-- selection changes visually without LASTSEL update in the chunk
			-- thefore comparison with the original value doesn't make sense
			-- the chunk must be updated regardless, only then the selection gets restored
			if #fx_chain > 0 --and fx_chain:match('LASTSEL (%d+)') ~= sel_idx
			then
			local fx_chain_upd = fx_chain:gsub('LASTSEL %d+', 'LASTSEL '..sel_idx)
			fx_chain = Esc(fx_chain)
			local chunk = chunk:gsub(fx_chain, fx_chain_upd)
			SetObjChunk(obj, chunk)
			end
		elseif #sel_idx > 0 then -- only when certain fx was selected, would be empty string if no fx in the chain
		Set_Conf_Parm(obj, -1, 'chain_sel', sel_idx)
		end
	end

end



function MAIN(menu_t, action_t, path, sep, temp_tr, obj_chunk, input_fx)
-- input_fx is boolean to store input fx indices

local fx_cnt = r.TrackFX_GetCount(temp_tr)

	local fx_chunk = FX_Chain_Chunk(obj_chunk, path, sep) -- needed for video processor and VST3 plugin instances detection with Collect_VideoProc_Instances() and Collect_VST3_Instances functions, detection video proc by fx name is unreliable as not all its preset names which are also instance names contain 'video processor' phrase due to length, neither it's reliable for VST3 plugins for the sake of getting .vstpreset file names as it can be changed by user in the FX browser
	local video_proc_t = Collect_VideoProc_Instances(fx_chunk)
	local vst3_t = Collect_VST3_Instances(fx_chunk)
		for i = 0, fx_cnt-1 do
		local pres_cnt = select(2,r.TrackFX_GetPresetIndex(temp_tr, i))
		local pres_fn = r.TrackFX_GetUserPresetFilename(temp_tr, i, '')
		local pres_fn = pres_fn:match('[^\\/]+$') -- isolate preset file name
		local fx_name = select(2,r.TrackFX_GetFXName(temp_tr, i, ''))
		local act, act_pres_name = r.TrackFX_GetPreset(temp_tr, i, '')
		local div = #menu_t > 0 and i == 0 and '|||' or '' -- divider between main fx and input fx lists only if there're main fx and so menu_t table is already populated
			if pres_cnt == 0 then
			menu_t[#menu_t+1] = div..'#'..fx_name..' (n o  p r e s e t s)|'
			-- take the grayed out entry into account in the action_t as a disabled grayed out entry still counts against the total number of the menu entries
			action_t[1][#action_t[1]+1] = '' -- dummy value
			action_t[2][#action_t[2]+1] = '' -- same
			elseif pres_cnt > 0 then -- only plugins with presets
			-- collect presets depending on the type of fx at the current index
			local preset_name_t = video_proc_t[i] and Collect_VideoProc_Preset_Names(temp_tr, fx_cnt, i, pres_cnt) or vst3_t[i] and Collect_VST3_Preset_Names(temp_tr, fx_cnt, i, pres_cnt) or Collect_FX_Preset_Names(temp_tr, fx_cnt, i, pres_cnt)
			local preset_name_list = preset_name_t and table.concat(preset_name_t)
				if preset_name_list then -- add active preset checkmark
					if act and act_pres_name ~= '' --and not act_pres_name:match('%.vstpreset')
					then -- if active preset matches the plug actual settings, not 'No preset', and not a path to VST3 preset file
					local act_pres_name = act_pres_name:match('.+%.vstpreset') and act_pres_name:match('([^\\/]+)%.%w+$') or act_pres_name
					local act_pres_name_esc = Esc(act_pres_name) -- escape special chars just in case
					preset_name_list = preset_name_list:gsub(act_pres_name_esc, '!'..act_pres_name) -- add checkmark to indicate active preset in the menu
					end
				local div = fx_cnt > 1 and div..'>' or '' -- only add submenu tag if more than 1 plugin in the chain because submenu only makes sense in this scenario, addition of the closure tag < is conditioned within collect preset names functions
				local fx_name = fx_cnt > 1 and fx_name..'|' or '' -- only include plugin name as submenu header if more than 1 plugin in the chain because submenu only makes sense in this scenario otherwise it counts agains the preset entry indices and disrupts their correspondence to preset indices
				menu_t[#menu_t+1] = div..fx_name..preset_name_list:gsub('&', '+') -- ampersand is a quick access shortcut in the menu and won't be displayed
					for j = 0, pres_cnt-1 do
					action_t[1][#action_t[1]+1] = input_fx and i+0x1000000 or i -- fx indices, repeated as many times as there're fx presets per fx to be triggered by the input form the menu
					action_t[2][#action_t[2]+1] = j -- preset indices, repeated as many times as there're fx presets, starts from 0 with every new fx index
					end
				end
			end
		end

return menu_t, action_t

end



------- START MAIN ROUTINE ------------

local itm_sel_t, trk_sel_t = StoreSelectedObjects()

local sep = r.GetOS():match('Win') and '\\' or '/' -- or r.GetResourcePath():match([\\/])
local path = r.GetResourcePath()
SEL_OBJ_IN_CURR_CONTEXT = SEL_OBJ_IN_CURR_CONTEXT:gsub(' ','') ~= '' -- or #SEL_OBJ_IN_CURR_CONTEXT:gsub(' ','') > 0
LOCK_FX_CHAIN_FOCUS = LOCK_FX_CHAIN_FOCUS:gsub(' ','') ~= ''
IGNORE_INPUT_FX = IGNORE_INPUT_FX:gsub(' ','') ~= ''
IGNORE_MAIN_FX = IGNORE_MAIN_FX:gsub(' ','') ~= ''
local space = (' '):rep(15)


	if not SEL_OBJ_IN_CURR_CONTEXT then
	obj, obj_type = Get_Object(LOCK_FX_CHAIN_FOCUS)
	RestoreSavedSelectedObjects(itm_sel_t, trk_sel_t) -- only if they were deselected by Get_Object() function due to the use of 'WITH SELECTION' routine
	end

	if not obj and SEL_OBJ_IN_CURR_CONTEXT then -- if called via menu or from a toolbar after explicitly selecting the object e.g. by clicking it first
	local cur_ctx = r.GetCursorContext2(true) -- true is last context; unlike r.GetCursorContext() this function stores last context if current one is invalid; object must be clicked to change context
		if cur_ctx == 0 then
		local trk_cnt = r.CountSelectedTracks2(0, true) -- incl. Master
		mess = trk_cnt == 0 and '\n\n  NO SELECTED TRACKS  \n\n'..space or trk_cnt > 1 and '\n\n   MULTIPLE TRACK SELECTION  \n\n'..space
		obj, obj_type = r.GetSelectedTrack2(0,0, true), 0 -- incl. Master
		elseif cur_ctx == 1 then
		local itm_cnt = r.CountSelectedMediaItems(0)
		mess = itm_cnt == 0 and '\n\n  NO SELECTED ITEMS  \n\n'..space or itm_cnt > 1 and '\n\n   MULTIPLE ITEM SELECTION  \n\n'..space
		obj, obj_type = r.GetSelectedMediaItem(0,0), 1
		end
	end


	if obj_type == 0 and IGNORE_INPUT_FX and IGNORE_MAIN_FX then
	mess = '\n\n\t LISTING PRESETS OF BOTH\n\n\tTRACK MAIN AND INPUT FX\n\n IS DISABLED IN THE SCRIPT SETTINGS \n'
	end

	if mess then
	local x, y = r.GetMousePosition(); r.TrackCtl_SetToolTip(mess:gsub('.', '%0 '), x, y-20, 1)
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) -- prevent undo point creation // might be redundant in this script
	elseif not obj then
	local x, y = r.GetMousePosition();
	r.TrackCtl_SetToolTip((' \n\nNO OBJECT UNDER THE MOUSE CURSOR\n\n '):gsub('.', '%0 '), x, y-20, 1)
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1)
	return r.defer(no_undo) -- prevent undo point creation // might be redundant in this script
	end


	if obj then -- prevent error when no item and when no track (empty area at bottom of the TCP, in MCP or the ruler or focused window) and prevent undo point creation

	r.Undo_BeginBlock() -- have to use this otherwise FX_Copy functions create their own undo points, as many as there're plugins in the chains, in the end since the undo point title is only displayed in the status bar and not listed in the undo history, not sure why because some changes to project are being made, such as temp track creation, anyway suits the task perfectly

		if obj_type == 1 then -- item
		local fx_chain_focus = LOCK_FX_CHAIN_FOCUS or r.GetCursorContext() == -1
			if r.GetFocusedFX() == 2 and fx_chain_focus then -- (last) focused take FX chain
			take = r.GetTake(obj,(select(4,r.GetFocusedFX()))>>16) -- make presets menu of focused take FX chain independent of the take being active
			else
			take = r.GetActiveTake(obj)
			end
		end

	local fx_cnt = obj_type == 0 and not IGNORE_MAIN_FX and r.TrackFX_GetCount(obj) or obj_type == 1 and r.TakeFX_GetCount(take)

		if obj_type == 0 then -- track
		rec_fx_cnt = not IGNORE_INPUT_FX and r.TrackFX_GetRecCount(obj) -- count input fx
			if rec_fx_cnt then
			fx_cnt = fx_cnt or 0 -- set to 0 if IGNORE_MAIN_FX is enabled
				if fx_cnt + rec_fx_cnt == 0 then mess = '\n\n  NO FX IN THE TRACK FX CHAINS  \n\n'..space
				elseif rec_fx_cnt > 0 then -- find out if input chain plugins contain any presets
				rec_fx_pres = 0
					for i = 0, rec_fx_cnt-1 do
					local retval, pres_cnt = r.TrackFX_GetPresetIndex(obj, i+0x1000000)
					rec_fx_pres = rec_fx_pres + pres_cnt
					end
				end
			end
			if fx_cnt > 0 then -- find out if main chain plugins contain any presets
			main_fx_pres = 0
				for i = 0, fx_cnt-1 do
				local retval, pres_cnt = r.TrackFX_GetPresetIndex(obj, i)
				main_fx_pres = main_fx_pres + pres_cnt
				end
			end
		elseif obj_type == 1 then -- item
			if fx_cnt == 0 then mess = '\n\n  NO FX IN THE TAKE FX CHAIN  \n\n'..space
			elseif fx_cnt > 0 then -- find out if plugins contain any presets
			take_fx_pres = 0
				for i = 0, fx_cnt-1 do
				local retval, pres_cnt = r.TakeFX_GetPresetIndex(take, i)
				take_fx_pres = take_fx_pres + pres_cnt
				end
			end
		end

		if not mess then -- additional conditions
		mess = (obj_type == 0 and (fx_cnt and fx_cnt > 0 and rec_fx_cnt and rec_fx_cnt > 0 and main_fx_pres + rec_fx_pres == 0 -- main and input fx but no presets
		or fx_cnt and fx_cnt == 0 and rec_fx_cnt and (rec_fx_cnt > 0 and rec_fx_pres == 0 or rec_fx_cnt == 0) -- only input fx with no presets or no main and input fx
		or fx_cnt and fx_cnt > 0 and (not rec_fx_cnt or rec_fx_cnt == 0) and main_fx_pres == 0) -- only main but no presets
		or obj_type == 1 and fx_cnt and fx_cnt > 0 and take_fx_pres == 0) and '\n\n  EITHER NO PRESETS OR NO PRESETS  \n\tACCESSIBLE TO THE SCRIPT\n\n'..space
		end

		if mess then
		local x, y = r.GetMousePosition(); r.TrackCtl_SetToolTip(mess:gsub('.', '%0 '), x, y-20, 1) -- y-20 raise tooltip above mouse cursor by that many px
		r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		return r.defer(no_undo) end


	local action_t = {{},{}} -- stores fx and preset indices as values for each key matching a preset index
	local menu_t = {}

-- NOW THE TEMP TRACK IS ONLY CREATED TWICE AT THE MOST IF TARGET TRACK CONTAINS BOTH MAIN AND INPUT/MINITORING FX,
-- INSTEAD OF ONE TEMP TRACK PER EACH FX IN THE CHAIN

		if fx_cnt and fx_cnt > 0 then

		-- Get selected fx index in the source chain to restore it after copying fx to temp track becase the functions FX_Copy_To_Take(), FX_Copy_To_Track() change fx selection in the source chain, making selected the last addressed fx
		local sel_fx_idx
		local _, src_chunk = GetObjChunk(obj)
			if src_chunk then -- source chunk could be retrieved
			sel_fx_idx = GetSet_FX_Selected_In_FX_Chain(take or obj, nil, src_chunk) -- sel_idx, input fx are nil
			end

		local temp_tr = Insert_Delete_Temp_Track(take or obj)
		local ret, obj_chunk = GetObjChunk(temp_tr)

			if ret == 'err_mess' and (not rec_fx_cnt or rec_fx_cnt == 0) then -- only if no input track fx when obj is track
			Err_mess()
			Insert_Delete_Temp_Track(obj, input_fx, temp_tr) -- input_fx nil, delete temp track
			return r.defer(no_undo) end -- chunk size is over the limit and no SWS extention is installed to fall back on

		menu_t, action_t = MAIN(menu_t, action_t, path, sep, temp_tr, obj_chunk)

		Insert_Delete_Temp_Track(obj, input_fx, temp_tr) -- input_fx nil, delete temp track

			if sel_fx_idx then -- sel_fx_idx could be retrieved above
			GetSet_FX_Selected_In_FX_Chain(take or obj, sel_fx_idx, src_chunk) -- -- input fx is nil
			end

		end

		if rec_fx_cnt and rec_fx_cnt > 0 then

		-- Get selected fx index in the source chain to restore it after copying fx to temp track becase the functions FX_Copy_To_Take(), FX_Copy_To_Track() change fx selection in the source chain, making selected the last addressed fx
		local sel_fx_idx
		local _, src_chunk = GetObjChunk(obj)
			if src_chunk then -- source chunk could be retrieved
			sel_fx_idx = GetSet_FX_Selected_In_FX_Chain(take or obj, nil, src_chunk, 1) -- sel_idx is nil, input_fx is true
			end

		local temp_tr = Insert_Delete_Temp_Track(obj, 1) -- input_fx 1 true
		local ret, obj_chunk = GetObjChunk(temp_tr, 0) -- obj_type 0 i.e. temp track

			if ret == 'err_mess' and #menu_t == 0 then -- only if no main track fx when obj is track
			Err_mess()
			Insert_Delete_Temp_Track(obj, input_fx, temp_tr) -- input_fx nil, delete temp track
			return r.defer(no_undo) end -- chunk size is over the limit and no SWS extention is installed to fall back on

		menu_t, action_t = MAIN(menu_t, action_t, path, sep, temp_tr, obj_chunk, 1) -- input_fx is 1 true to collect fx indices in correct format

		Insert_Delete_Temp_Track(obj, input_fx, temp_tr) -- input_fx nil, delete temp track

			if sel_fx_idx then -- sel_fx_idx could be retrieved above
			GetSet_FX_Selected_In_FX_Chain(take or obj, sel_fx_idx, src_chunk, 1) -- input_fx is true
			end

		end

	r.Undo_EndBlock('Get FX presets',-1)

	KEEP_MENU_OPEN = #KEEP_MENU_OPEN:gsub(' ','') > 0

	::KEEP_MENU_OPEN::

	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::KEEP_MENU_OPEN::
	-- therefore enabled when KEEP_MENU_OPEN is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and KEEP_MENU_OPEN) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor
		if KEEP_MENU_OPEN and not coord_t then
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not KEEP_MENU_OPEN then
		coord_t = nil
		end
	-- open menu at the mouse cursor
	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y

	local input = gfx.showmenu(table.concat(menu_t))

	Msg('MENU INPUT = '..tostring(input))

		if input > 0 then
		local select_pres = obj_type == 0 and r.TrackFX_SetPresetByIndex(obj, action_t[1][input], action_t[2][input]) or obj_type == 1 and r.TakeFX_SetPresetByIndex(take, action_t[1][input], action_t[2][input])
			if KEEP_MENU_OPEN then goto KEEP_MENU_OPEN end
		end

	end

