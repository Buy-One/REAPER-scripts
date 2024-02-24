--[[
ReaScript name: BuyOne_Move edit cursor to snap offset cursor; fades; take, stretch markers; media cues; razor edit area and automation item edges_META.lua (18 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.6
Changelog:  v1.6 #Fixed compatibility with installer script
	    v1.5 #Fixed failed META sctript name update in v1.3
	    v1.4 #Creation of individual scripts has been made hands-free. 
	    These are created in the directory the META script is located in
	    and from there are imported into the Action list.
	    #Updated About text
	    v1.3 #Added 2 new scripts to move cursor to automation item edge
	    #Added functionality to export individual scripts included in the package				 
	    #Added code to prevent generic undo point listing in the undo history readout
	    when cursor position change isn't supposed to create an undo point
	    #Added some error messages
	    #Updated the script name
	    #Updated About text
	    v1.2 #Fixed REAPER version evaluation
	    v1.1 #Made values in bitwise operation compatible with Lua 5.4
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M for media cue navigation scripts
Metapackage: true
Provides: 	. > BuyOne_Move edit cursor right to snap offset cursor in items.lua
		. > BuyOne_Move edit cursor left to snap offset cursor in items.lua
		. > BuyOne_Move edit cursor right to fade in items.lua
		. > BuyOne_Move edit cursor left to fade in items.lua
		. > BuyOne_Move edit cursor right to take marker.lua
		. > BuyOne_Move edit cursor left to take marker.lua
		. > BuyOne_Move edit cursor right to stretch marker.lua
		. > BuyOne_Move edit cursor left to stretch marker.lua
		. > BuyOne_Move edit cursor right to media cue.lua
		. > BuyOne_Move edit cursor left to media cue.lua
		. > BuyOne_Move edit cursor right to edge of Razor Edit area.lua
		. > BuyOne_Move edit cursor left to edge of Razor Edit area.lua
		. > BuyOne_Move edit cursor right to edge of item Razor Edit area.lua
		. > BuyOne_Move edit cursor left to edge of item Razor Edit area.lua
		. > BuyOne_Move edit cursor right to edge of envelope Razor Edit area.lua
		. > BuyOne_Move edit cursor left to edge of envelope Razor Edit area.lua
		. > BuyOne_Move edit cursor right to automation item edge on selected envelope.lua
		. > BuyOne_Move edit cursor left to automation item edge on selected envelope.lua			
About: 	The set of 18 scripts is meant to complement 
	REAPER stock navigation actions.  
	
	
	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name.
	
	
	► Snap offset cursor, Fades, Take/Stretch markers & Media cues
	
	Scripts which move the edit cursor to snap offset cursor 
	and fades in items only apply to selected items if any
	are selected, otherwise they move the edit cursor to snap 
	offset cursor and fades in all items.  
	Scripts which move the edit cursor to take/stretch markers
	and media cues additionally only apply to active take in items.  
	If any tracks are selected, these scripts only apply to items
	on selected tracks provided no items are selected or all items 
	which are selected belong to selected tracks.  
	!!! The scripts will get stuck if simultaneously on the one 
	hand there're no selected items on selected tracks and on the 
	other tracks of selected items are not selected !!!  
	Snap offset cursor position is only respected if it differs
	from item start.  
	
	► Razor Edit areas
	
	Scripts which move the edit cursor to Razor Edit area edges
	only apply to these on selected tracks if any are selected,
	otherwise they apply to Razor Edit area edges on all tracks. 
	If certain Razor Edit area covers both item and envelope on 
	the same track the scripts don't dicriminate between them 
	and move the edit cursor to the area edges regardless of the 
	script name, however track selection condition applies.  
	If certain Razor Edit area covers items and envelopes on 
	multiple tracks, neither script names nor track selection 
	condition apply, the edit cursor will always move to its edges.  
	If certain Razor Edit area covers an item on one track and 
	an envelope on the previous track the script names and selection 
	conditions described above apply as normal.  
	The Master track is supported for builds 6.72 onwards. 

	► Automation items
	
	If there're selected automation items on the selected envelope
	the edit cursor will only move between selected automation
	item edges, otherwise it'll move to the edge of each and every
	automation item in sequence.
	
	
	In the USER SETTINGS you can enable MOVE_VIEW setting so that
	the the Arrange view scrolls when the edit cursor moves to out
	of sight areas.  
	
	In line with behavior of the stock navigation actions, the scripts 
	only create meaningful undo points if 'cursor position' option
	is enabled at Preferences -> General -> Undo settings.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable settings insert any alphanumeric character between the quotes

-- Enable to make the Arrange view scroll when the time point
-- the cursor moves to is out of sight
MOVE_VIEW = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Rep(n) -- number of repeats, integer
return (' '):rep(n)
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


function GetUndoSettings()
-- Checking settings at Preferences -> General -> Undo settings -> Include selection:
-- thanks to Mespotine https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
local undoflags = cont:match('undomask=(%d+)')+0 -- +0 is accommodating for Lua 5.4 where implicit conversion of strings to integers doesn't work in bitwise operations
local t = {
1, -- item selection
2, -- time selection
4, -- full undo, keep the newest state
8, -- cursor pos
16, -- track selection
32 -- env point selection
}
	for k, bit in ipairs(t) do
	t[k] = undoflags&bit == bit
	end
return t
end


function Invalid_Script_Name(scr_name,...)
-- check if necessary elements are found in script name
-- if more than 1 match is needed run twice with different sets of elements which are supposed to appear in the same name, but elements within each set must not be expected to appear in the same name
local t = {...}

	for k, v in ipairs(t) do
		if scr_name:match(v) then return end -- at least one match was found
	end

return true

end


function REAPER_Ver_Check(build) -- build is REAPER build number, the function must be followed by 'do return end'
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < build then -- or match('[%d%.]+')
	local x,y = r.GetMousePosition()
	local mess = '\n\n   THE SCRIPT REQUIRES\n\n  REAPER '..build..' AND ABOVE  \n\n '
	local mess = mess:gsub('.','%0 ')
	r.TrackCtl_SetToolTip(mess, x, y+10, true) -- topmost true
	return true
	end
end


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end
	
	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed 
			return true end
		end
	end

	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then
	
--[[ GETTING PATH FROM THE USER INPUT

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)
	
	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD
	
	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]	
	
		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH
		
		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end

		
		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0} do -- Main // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end
		
	end

end




function Move_EditCur_To_SnapoffsetCur(dir, sel_tracks, curs_undo) -- if snap offset differs from item start
-- dir is string 'right' or 'left' taken from the script name
-- if sel_tracks true only applies to items on selected tracks, see next condition
-- if some items are selected, only applies to them, otherwise to all items either on selected or all tracks depending on the above condition

	if not r.GetMediaItem(0,0) then
	Error_Tooltip('\n\n no items in the project \n\n')
	return end

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local GetItem = sel_itm_cnt > 0 and r.GetSelectedMediaItem or r.GetMediaItem(0,0) and r.GetMediaItem
local itm_cnt = sel_itm_cnt > 0 and sel_itm_cnt or GetItem and r.CountMediaItems(0) or 0

	if itm_cnt > 0 then
	local GetVal = r.GetMediaItemInfo_Value
	local t = {}
		for i = 0, itm_cnt-1 do
		local item = GetItem(0,i)
		local pos = GetVal(item, 'D_POSITION')
		local snapoffs = pos + GetVal(item, 'D_SNAPOFFSET')
		local itm_tr = r.GetMediaItemTrack(item)
		local retval, tr_flags = r.GetTrackState(itm_tr)
		local tr_vis = tr_flags&512 ~= 512 -- visible in TCP
		local is_track_sel = r.IsTrackSelected(itm_tr)
			if tr_vis and (sel_tracks and is_track_sel or not sel_tracks)
			and snapoffs ~= pos then t[#t+1] = snapoffs end
		end

	local err = sel_tracks and #t == 0 and (sel_itm_cnt == 0 and 'no items on selected tracks'
	or 'selected items don\'t belong \n\n\tto selected tracks')

		if err then
		Error_Tooltip('\n\n '..err..' \n\n')
		return end

		if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

		if curs_undo and #t > 0 then r.Undo_BeginBlock() end

		for _, snapoffs in ipairs(t) do
			if right and snapoffs > edit_cur_pos or left and snapoffs < edit_cur_pos then
			r.SetEditCurPos(snapoffs, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
			break end
		end

	local edit_cur_pos_new = r.GetCursorPosition() -- evaluate whether there was a change

		if curs_undo and edit_cur_pos_new ~= edit_cur_pos then
		r.Undo_EndBlock(dir..' at '..r.format_timestr(edit_cur_pos_new, ''), -1) end -- dir argument is the script name

	end

end


function Move_EditCur_To_Fade(dir, sel_tracks, curs_undo)
-- dir is string 'right' or 'left' taken from the script name
-- if sel_tracks true only applies to items on selected tracks, see next condition
-- if some items are selected, only applies to them, otherwise to all items either on selected or all tracks depending on the above condition

	if not r.GetMediaItem(0,0) then
	Error_Tooltip('\n\n no items in the project \n\n')
	return end

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local GetItem = sel_itm_cnt > 0 and r.GetSelectedMediaItem or r.GetMediaItem(0,0) and r.GetMediaItem
local itm_cnt = sel_itm_cnt > 0 and sel_itm_cnt or GetItem and r.CountMediaItems(0) or 0

	if itm_cnt > 0 then
	local GetVal = r.GetMediaItemInfo_Value
	local t = {}
		for i = 0, itm_cnt-1 do
		local item = GetItem(0,i)
		local itm_tr = r.GetMediaItemTrack(item)
		local retval, tr_flags = r.GetTrackState(itm_tr)
		local tr_vis = tr_flags&512 ~= 512 -- visible in TCP
		local is_track_sel = r.IsTrackSelected(itm_tr)
		local pos = GetVal(item, 'D_POSITION')
		local fin = pos + GetVal(item, 'D_LENGTH')
		local fadein = GetVal(item, 'D_FADEINLEN_AUTO')
		local fadein = fadein > 0 and fadein or GetVal(item, 'D_FADEINLEN')
		local fadeout = GetVal(item, 'D_FADEOUTLEN_AUTO')
		local fadeout = fadeout > 0 and fadeout or GetVal(item, 'D_FADEOUTLEN')
			if tr_vis and (sel_tracks and is_track_sel or not sel_tracks) then
				if fadein > 0 then t[#t+1] = pos+fadein end
				if fadeout > 0 then t[#t+1] = fin-fadeout end
			end
		end


	local err = sel_tracks and #t == 0 and (sel_itm_cnt == 0 and 'no items on selected tracks'
	or 'selected items don\'t belong \n\n\tto selected tracks')

		if err then
		Error_Tooltip('\n\n '..err..' \n\n')
		return end

		if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

		if curs_undo and #t > 0 then r.Undo_BeginBlock() end

		for _, fade in ipairs(t) do
			if right and fade > edit_cur_pos or left and fade < edit_cur_pos then
			r.SetEditCurPos(fade, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
			break end
		end

	local edit_cur_pos_new = r.GetCursorPosition() -- evaluate whether there was a change

		if curs_undo and edit_cur_pos_new ~= edit_cur_pos then
		r.Undo_EndBlock(dir..' at '..r.format_timestr(edit_cur_pos_new, ''), -1) end -- dir argument is the script name

	end

end


function Move_EditCur_To_TakeOrStretch_Marker(dir, sel_tracks, curs_undo, wantstretchmarkers, wantmediacues) -- wantstretchmarkers and wantmediacues are booleans to target stretch markers and media cues
-- dir is string 'right' or 'left' taken from the script name
-- if sel_tracks true only applies to items on selected tracks, see next condition
-- if some items are selected, only applies to them, otherwise to all items either on selected or all tracks depending on the above condition
-- only applies to active takes

	if not r.GetMediaItem(0,0) then
	Error_Tooltip('\n\n no items in the project \n\n')
	return end

	local function CollectTakeOrStretchMarkersOrMediaCues(t, act_take, mrkr_cnt, itm_pos, itm_end, startoffs, playrate, wantstretchmarkers, wantmediacues)
		if wantstretchmarkers or not wantstretchmarkers and not wantmediacues then
		local GetMarker = not wantstretchmarkers and r.GetTakeMarker or r.GetTakeStretchMarker
			for i = 0, mrkr_cnt-1 do
			local take_mrkr_pos, stretch_mrkr_pos = GetMarker(act_take, i)
			local mrkr_pos = not wantstretchmarkers and take_mrkr_pos or stretch_mrkr_pos
			local startoffs = not wantstretchmarkers and startoffs or 0 -- for stretch_mrkr_pos val start offset is irrelevant because it's relative to item start, its position in source value is ignored here, start offset would be relevant if that value were used
			local mrkr_pos = itm_pos + (mrkr_pos - startoffs)/playrate -- calculate pos of marker in project
				if mrkr_pos >= itm_pos and mrkr_pos <= itm_end then -- if visible
				t[#t+1] = mrkr_pos
				end
			end
		elseif wantmediacues and r.APIExists('CF_EnumMediaSourceCues') then
		local src = r.GetMediaItemTake_Source(act_take)
		local sect, startoffs, len, rev = r.PCM_Source_GetSectionInfo(src) -- if sect is false src_startoffs and src_len are 0
		local src = (sect or rev) and r.GetMediaSourceParent(src) or src -- retrieve original media source if section or reversed
		local i = 0 -- to start at 0 because CF_EnumMediaSourceCues returns props of the next media cue
			repeat
			local retval, pos, endTime, isRegion, name = r.CF_EnumMediaSourceCues(src, i)
				if retval > 0 then
				local pos = itm_pos + (pos - startoffs)/playrate
				local endTime = itm_pos + (endTime - startoffs)/playrate
					if pos >= itm_pos and pos <= itm_end then
					t[#t+1] = pos
					end
					if isRegion and endTime >= itm_pos and endTime <= itm_end then
					t[#t+1] = endTime
					end
				end
			i = i+1
			until retval == 0
		elseif not r.APIExists('CF_EnumMediaSourceCues') then
		Error_Tooltip('\n\n       The script requires \n\n SWS/S&M extension to work. \n\n')
		end
	end

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local GetItem = sel_itm_cnt > 0 and r.GetSelectedMediaItem or r.GetMediaItem(0,0) and r.GetMediaItem
local itm_cnt = sel_itm_cnt > 0 and sel_itm_cnt or GetItem and r.CountMediaItems(0) or 0

	if itm_cnt > 0 then
	local GetVal, GetTakeVal = r.GetMediaItemInfo_Value, r.GetMediaItemTakeInfo_Value
	local t = {}
		for i = 0, itm_cnt-1 do
		local item = GetItem(0,i)
		local act_take = r.GetActiveTake(item)
		local mrkr_cnt = wantmediacues and 1 or not wantstretchmarkers and r.GetNumTakeMarkers(act_take) or r.GetTakeNumStretchMarkers(act_take) -- media cues cannot be counted without direct enumeration hence a value greater than 0 is assigned to make the routine go through
			if mrkr_cnt > 0 then
			local itm_pos = GetVal(item, 'D_POSITION')
			local itm_end = itm_pos + GetVal(item, 'D_LENGTH')
			local startoffs = GetTakeVal(act_take, 'D_STARTOFFS')
			local playrate = GetTakeVal(act_take, 'D_PLAYRATE')
			local itm_tr = r.GetMediaItemTrack(item)
			local retval, tr_flags = r.GetTrackState(itm_tr)
			local tr_vis = tr_flags&512 ~= 512 -- visible in TCP
			local is_track_sel = r.IsTrackSelected(itm_tr)
				if tr_vis and (sel_tracks and is_track_sel or not sel_tracks) then
				CollectTakeOrStretchMarkersOrMediaCues(t, act_take, mrkr_cnt, itm_pos, itm_end, startoffs, playrate, wantstretchmarkers, wantmediacues)
				end
			 end
		end

		local err = sel_tracks and #t == 0 and (sel_itm_cnt == 0 and 'no items on selected tracks'
		or 'selected items don\'t belong \n\n\tto selected tracks')

			if err then
			Error_Tooltip('\n\n '..err..' \n\n')
			return end

		if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

		if curs_undo and #t > 0 then r.Undo_BeginBlock() end

		for _, val in ipairs(t) do
			if right and val > edit_cur_pos or left and val < edit_cur_pos then
			r.SetEditCurPos(val, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
			break end
		end

	local edit_cur_pos_new = r.GetCursorPosition() -- evaluate whether there was a change

		if curs_undo and edit_cur_pos_new ~= edit_cur_pos then
		r.Undo_EndBlock(dir..' at '..r.format_timestr(edit_cur_pos_new, ''), -1) end -- dir argument is the script name

	end

end


function Move_EditCur_To_RazEdAreaEdge(dir, items, envs, curs_undo)
-- dir is string 'right' or 'left' taken from the script name
-- if any tracks are selected only applies to RazEd areas on them, otherwise to RazEd areas on all tracks
-- if items and envs are both true or both are false, the function applies to both item and env RazEd areas

	if REAPER_Ver_Check(6.24) then return end -- Razor Edit and API were introduced in 6.24

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local master_raz = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.72 -- Razor Edit for Master track was added in 6.72
local sel_tr_cnt = not master_raz and r.CountSelectedTracks(0) or r.CountSelectedTracks2(0, true) -- wantmaster true
local GetTr = sel_tr_cnt > 0 and r.GetSelectedTrack or r.GetTrack
local tr_cnt = sel_tr_cnt > 0 and sel_tr_cnt or GetTr and r.CountTracks(0) or 0
local t = {}
	for i = -1, tr_cnt-1 do -- -1 account for the Master track in builds where it supports Razor Edits
	local master = r.GetMasterTrack(0)
	local master_sel = r.IsTrackSelected(master)
	local tr = GetTr(0,i) or master_raz and (sel_tr_cnt > 0 and master_sel or sel_tr_cnt == 0) and r.GetMasterTrack(0)
	local retval, tr_flags = table.unpack(tr and {r.GetTrackState(tr)} or {})
	local tr_vis = tr_flags and tr_flags&512 ~= 512 -- works for the Master track as well
		if tr and tr_vis then
		local ret, razor_data = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false) -- setNewValue false
			if ret then
				for area in razor_data:gmatch('.-".-"') do
				local itm = area:match('""') -- unlike env area data, item area data instead of GUID contain just quotes
				local env = area:match('".+"')
					if items and not envs and itm or envs and not items and env
					or (not items and not envs or items and envs) and (itm or env) then
					local st, fin = area:match('([%d%.]+) ([%d%.]+)')
					t[#t+1] = st+0 -- converting to number
					t[#t+1] = fin+0
					end
				end
			end
		end
	end

	local err = #t == 0 and (sel_tr_cnt > 0 and 'no razor edit areas\n\n  on selected tracks'
	or 'razor edit areas weren\'t found')

			if err then
			Error_Tooltip('\n\n '..err..' \n\n')
			return end

	if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

	if curs_undo and #t > 0 then r.Undo_BeginBlock() end

	for _, raz_edge in ipairs(t) do
		if right and raz_edge > edit_cur_pos or left and raz_edge < edit_cur_pos then
		r.SetEditCurPos(raz_edge, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
		break end
	end

	local edit_cur_pos_new = r.GetCursorPosition() -- evaluate whether there was a change

		if curs_undo and edit_cur_pos_new ~= edit_cur_pos then
		r.Undo_EndBlock(dir..' at '..r.format_timestr(edit_cur_pos_new, ''), -1)  -- dir argument is the script name
		end

end


function Move_EditCur_To_AI_Edge(dir, curs_undo)
-- dir is string 'right' or 'left' taken from the script name
-- dir is string 'right' or 'left' taken from the script name
-- if some AIs are selected, only applies to them, otherwise to all AIs on selected track envelope

local sel_env = r.GetSelectedTrackEnvelope(0)
local edit_cur_pos = r.GetCursorPosition()
local right = dir:match('right')
local left = dir:match('left')
local AI_cnt = sel_env and r.CountAutomationItems(sel_env)-1
local err = not sel_env and 'no selected track envelope'
or AI_cnt < 0 and 'no automation items \n\n on selected envelope'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n')
	return end

local GetSetAI = r.GetSetAutomationItemInfo
local st, fin, step = table.unpack(right and {0, AI_cnt, 1} or left and {AI_cnt, 0, -1}) -- in reverse when moving left
local closest_edge, selected_exist

	if curs_undo then r.Undo_BeginBlock() end

	-- the loop is used to find and/or move edit cursor to selected AIs
	-- and store the closest edge if selected AI wasn't found
	for i = st, fin, step do
	local AI_start = GetSetAI(sel_env, i, 'D_POSITION', -1, false) -- is_set false
	local AI_end = AI_start + GetSetAI(sel_env, i, 'D_LENGTH', -1, false) -- is_set false
	local AI_sel = GetSetAI(sel_env, i, 'D_UISEL', -1, false) ~= 0 -- is_set false
	local AI_edge = right and (AI_start > edit_cur_pos and AI_start or AI_end > edit_cur_pos and AI_end)
	or left and (AI_end < edit_cur_pos and AI_end or AI_start < edit_cur_pos and AI_start)
	closest_edge = closest_edge or AI_edge
	selected_exist = selected_exist or AI_sel -- used as a boolean to prevent moving to non-selected AI after the loop when there're selected but behind the edit cursor
		if AI_edge then
			if AI_sel then
			r.SetEditCurPos(AI_edge, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
			break
			end
		end
	end

	if r.GetCursorPosition() == edit_cur_pos and not selected_exist and closest_edge then -- no selected AI, move to non-selected
	r.SetEditCurPos(closest_edge, MOVE_VIEW, false)
	end

local edit_cur_pos_new = r.GetCursorPosition() -- evaluate whether there was a change

	if curs_undo and edit_cur_pos_new ~= edit_cur_pos then
	r.Undo_EndBlock(dir..' at '..r.format_timestr(edit_cur_pos_new, ''), -1) -- dir argument is the script name
	end

end



local _, fullpath_init, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name & ext

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Move edit cursor to snap offset cursor; fades;'
	..' take, stretch markers; media cues; razor edit area and automation item edges_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not

local type_t = {'snap offset', 'fade', 'take marker', 'stretch marker', 'media cue', 'Razor Edit', 'automation item'}

-- validate script name
local no_elm1 = Invalid_Script_Name(scr_name,table.unpack(type_t))
local no_elm2 = Invalid_Script_Name(scr_name,'left','right')
	if no_elm1 or no_elm2 then
	local br = '\n\n'
	r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
	[[   please restore the original name]]..br..[[  referring to the list in the header,]]..br..
	Rep(9)..[[or reinstall the package.]], 'ERROR', 0)
	return r.defer(no_undo) end

local cur_pos = r.GetCursorPosition()
local err = not r.GetTrack(0,0) and 'no tracks in the project'
or scr_name:match('right') and cur_pos == r.GetProjectLength() and 'project end reached'
or scr_name:match('left') and cur_pos == 0 and 'project start reached'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n')
	return r.defer(no_undo) end


	for _, v in ipairs(type_t) do -- get script type to condition the selection of functions below
		if scr_name:match(v) then
		Type = scr_name:match(v) break
		end
	end


MOVE_VIEW = #MOVE_VIEW:gsub(' ','') > 0

local sel_tracks = r.CountSelectedTracks(0) > 0

local curs_undo = GetUndoSettings()[4] -- only create a meaningful undo point if edit cursor pos is saved in the undo state as per the Preferences

	if Type == 'snap offset' then
	Move_EditCur_To_SnapoffsetCur(scr_name, sel_tracks, curs_undo) -- dir arg is scr_name, sel_track boolean depends on presence of selected tracks
	elseif Type == 'fade' then
	Move_EditCur_To_Fade(scr_name, sel_tracks, curs_undo) -- dir arg is scr_name, sel_track flag depends on presence of selected tracks
	elseif Type == 'take marker' then
	Move_EditCur_To_TakeOrStretch_Marker(scr_name, sel_tracks, curs_undo)
	elseif Type == 'stretch marker' then
	Move_EditCur_To_TakeOrStretch_Marker(scr_name, sel_tracks, curs_undo, true) -- wantstretchmarkers true
	elseif Type == 'media cue' then
	Move_EditCur_To_TakeOrStretch_Marker(scr_name, sel_tracks, curs_undo, wantstretchmarkers, true) -- wantmediacues true
	elseif Type == 'Razor Edit' then
	Move_EditCur_To_RazEdAreaEdge(scr_name, scr_name:match('item'), scr_name:match('envelope'), curs_undo) -- dir arg is scr_name, items & envs booleans are obtained from scr_name capture
	elseif Type == 'automation item' then
	Move_EditCur_To_AI_Edge(scr_name, curs_undo) -- dir arg is scr_name
	end


do return r.defer(no_undo) end -- if curs_undo not enabled



