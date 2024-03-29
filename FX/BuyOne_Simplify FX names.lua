--[[
ReaScript Name: BuyOne_Simplify FX names.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog: v1.4 #Updated About text
	   v1.3 #Fixed incorrect user option storage
		#Fixed trimming JSFX down to file name when no description is displayed in the name
		#Added an option to apply the script to FX in all takes of multi-take items
		#Added internal check for user renamed FX instances to prevent changing custom name by accident
	   v1.2 #Added FX container support
	   v1.1 #Changed the logic so that the script only targets selected objects, non-selected are ignored
		#Added a feature of user preferences storage between script runs
Licence: WTFPL
REAPER: v6.37+
About: 	Trims FX names in FX chains according to user preferences.
		
	Only applies to original FX names. If FX name in FX chain
	differs from the one displayed in the FX browser, which 
	may be a result of renaming by the user, no change occurs 
	to prevent butchering user custom FX instance name.

]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Reload_Menu_at_Same_Pos(menu, OPTION) -- still doesn't allow keeping the menu open after clicking away
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
-- local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
-- local init = old and gfx.init('', 0, 0)
-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::, hence commented out
gfx.init('', 0, 0)
-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
	-- ensure that if OPTION is enabled the menu opens every time at the same spot
	if OPTION and not coord_t then -- OPTION is the one which enables menu reload
	coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
	elseif not OPTION then
	coord_t = nil
	end
gfx.x = coord_t and coord_t.x or gfx.mouse_x
gfx.y = coord_t and coord_t.y or gfx.mouse_y
return gfx.showmenu(menu) -- menu string

end



function Process_FX_Incl_In_All_Containers(obj, recFX, parent_cntnr_idx, parents_fx_cnt, prefix, dev_name, jsfx_filename)
-- https://forum.cockos.com/showthread.php?t=282861
-- https://forum.cockos.com/showthread.php?t=282861#18
-- https://forum.cockos.com/showthread.php?t=284400

-- obj is track or take, recFX is boolean to target input/Monitoring FX
-- parent_cntnr_idx, parents_fx_cnt must be nil

local tr, take = r.ValidatePtr(obj, 'MediaTrack*') and obj, r.ValidatePtr(obj, 'MediaItem_Take*') and obj

local FXCount, GetIOSize, GetConfig, SetConfig, GetFXName = 
table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, 
r.TrackFX_SetNamedConfigParm, r.TrackFX_GetFXName}
or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, 
r.TakeFX_SetNamedConfigParm, r.TakeFX_GetFXName} or {})

local fx_cnt = not parent_cntnr_idx and (recFX and r.TrackFX_GetRecCount(obj) or FXCount(obj))
fx_cnt = fx_cnt or ({GetConfig(obj, parent_cntnr_idx, 'container_count')})[2]

	if tr or take then
		for i = 0, fx_cnt-1 do
		-- only add 0x1000000 to fx index to target input/Monitoring fx inside the outermost fx chain
		-- (at this stage parent_cntnr_idx is nil)
		local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
		-- only use formula to calculate indices of fx in containers once parent_cntnr_idx var is valid
		-- to keep the indices of fx in the root (outermost) fx chain intact
		i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
		local container = GetIOSize(obj, i) == 8
			if container then
			-- DO STUFF TO CONTAINER (if needed) and proceed to its FX;
			-- the following vars must be local to not interfere with the current loop and break i expression above
			-- only add 0x2000000+1 to the very 1st (belonging to the outermost FX chain) container index 
			-- (at this stage parent_cntnr_idx is nil)
			-- and then keep container index obtained via the formula above throughout the recursive loop
			local parent_cntnr_idx = parent_cntnr_idx and i or 0x2000000+i+1
			-- multiply fx counts of all (grand)parent containers by the fx count 
			-- of the current one + 1 as per the formula;
			-- accounting for the outermost fx chain where parents_fx_cnt is nil
			local parents_fx_cnt = (parents_fx_cnt or 1) * (fx_cnt+1)
			Process_FX_Incl_In_All_Containers(obj, recFX, parent_cntnr_idx, parents_fx_cnt, prefix, dev_name, jsfx_filename) -- recFX can be nil/false
			else -- PROCESS FX
			Simplify_FX_Name(tr, take, i, recFX, prefix, dev_name, jsfx_filename)
			end
		end
	end

end


function Simplify_FX_Name(tr, take, fx_idx, recFX, prefix, dev_name, jsfx_filename)

	if tr or take then
	local GetFXName, FXCount, GetConfigParm, SetConfigParm = table.unpack(take and 
	{r.TakeFX_GetFXName, r.TakeFX_GetCount, r.TakeFX_GetNamedConfigParm, r.TakeFX_SetNamedConfigParm}
	or {r.TrackFX_GetFXName, r.TrackFX_GetCount, r.TrackFX_GetNamedConfigParm, r.TrackFX_SetNamedConfigParm})
	FXCount = recFX and r.TrackFX_GetRecCount or FXCount
	local obj = take or tr
	local _, fx_name = GetFXName(obj, fx_idx, '')
	-- check if fx instance was likely renamed by the user to avoid accidentally butchering 
	-- it if it happens to match the captures
	local _, name_in_fx_brwser = GetConfigParm(obj, fx_idx, 'original_name') -- or 'fx_name'
		if fx_name ~= name_in_fx_brwser then return end
	local simple_name = prefix and fx_name:match('.-: (.+)') or fx_name
	simple_name = dev_name and simple_name:match('(.+) [%(%[]+') or simple_name
	simple_name = jsfx_filename and simple_name:match('.+/([^%[%]]+)') or simple_name -- covers desc + file path and file path only
		if simple_name ~= fx_name then
		SetConfigParm(obj, fx_idx, 'renamed_name', simple_name)
		end
	end

end



	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.37 then
	Error_Tooltip('\n\n   the script is only compatible \n\n with reaper builds 6.37 and later\n\n ', 1, 1)	-- caps, spaced true
	return r.defer(no_undo) end
	
local is_new_value, fullpath, sectionID, cmdID, mode, resolution, val = r.get_action_context()
local cmdID = r.ReverseNamedCommandLookup(cmdID) -- convert to named
local state = r.GetExtState(cmdID,'USER_PREFS')
local state1, state2, state3, state4, state5 = state:match('(.-);(.-);(.-);(.-);(.*)')


::RELOAD::

--[[ these expressions allowed targeting all objects if none was selected
--local itm_cnt = r.CountSelectedMediaItems(0) > 0 and r.CountSelectedMediaItems(0) or r.CountMediaItems(0)
--local tr_cnt = r.CountSelectedTracks2(0, true) > 0 and r.CountSelectedTracks2(0, true) or r.CountTracks(0) -- wantmaster true
]]
local itm_cnt = r.CountSelectedMediaItems(0)
local tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true

	if itm_cnt + tr_cnt == 0 then

	Error_Tooltip('\n\n no selected objects \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)

	elseif itm_cnt + tr_cnt > 0 then

	state1, state2, state3, state4, state5 = state1 or '', state2 or '', state3 or '', state4 or '', state5 or ''
	local menu = '(Un)Set preferences by clicking them:||'..state1..'Trim prefix, e.g. VST(i): etc.|'
	..state2..'Trim developer name (file path in JSFX)|'..state3..'Only leave JSFX file name|'
	..state4..'Apply to FX in all takes of multi-take items|'
	..state5..'Include insert / Monitor FX||R U N| ||'
	..'Affects FX in selected objects.|'
	..'If option "Apply to all takes ..."  isn\'t|enabled, the script only affects FX|'
	..'in active takes of multi-take items.|'
	..'Options "Apply to all takes ..."|and "Include insert / Monitor FX"|'
	..'can only be enabled if at least one|other option is enabled.|'
	..'User preferences are only stored|during the session.'

	local index = Reload_Menu_at_Same_Pos(menu, 1) -- 1 - open at the same pos 

		if index == 0 then return r.defer(no_undo) -- menu closed
		elseif index == 2 then state1 = #state1 == 0 and '!' or '' -- toggle
		elseif index == 3 then state2 = #state2 == 0 and '!' or ''
		elseif index == 4 then state3 = #state3 == 0 and '!' or ''
		elseif index == 5 then 
		state4 = #(state1..state2..state3) > 0 and #state4 == 0 and '!' or '' -- allows disabling when 3 main prefs are unchecked
		elseif index == 6 then
		state5 = #(state1..state2..state3) > 0 and #state5 == 0 and '!' or '' -- allows disabling when 3 main prefs are unchecked
		end
		if index ~= 7 then goto RELOAD end -- not RUN and not 0

		if #(state1..state2..state3) == 0 then -- state4 and state5 aren't evaluated because by they're optional
		Error_Tooltip('\n\n no option has been enabled \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end

	-- store until the next script run, only if the script was run, if aborted nothing will be stored
	-- since it will exit above
	r.SetExtState(cmdID, 'USER_PREFS', state1..';'..state2..';'..state3..';'..state4..';'..state5, false) -- pesrist false
	
	TRIM_PREFIX = #state1 > 0
	TRIM_DEV_NAME = #state2 > 0
	ONLY_LEAVE_JSFX_FILENAME = #state3 > 0
	APPLY_TO_ALL_TAKES = #state4 > 0
	INCL_INSERT_MON_FX = #state5 > 0

	r.Undo_BeginBlock()

		for i = -1, tr_cnt-1 do -- -1 to account for the Master when no track is selected // a holdover from the version in which non-selected objects could be targeted
		local tr = r.GetSelectedTrack(0,i,true) or r.GetTrack(0,i) or r.GetMasterTrack(0) -- same
			if tr then	
			Process_FX_Incl_In_All_Containers(tr, recFX, parent_cntnr_idx, parents_fx_cnt, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- recFX false
				if INCL_INSERT_MON_FX then
				Process_FX_Incl_In_All_Containers(tr, INCL_INSERT_MON_FX, parent_cntnr_idx, parents_fx_cnt, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- recFX true
				end
			end
		end

		for i = 0, itm_cnt-1 do
		local item = r.GetSelectedMediaItem(0,i) or r.GetMediaItem(0,i) -- a holdover from the version in which non-selected objects could be targeted
		local take_cnt = r.CountTakes(item)
			if not APPLY_TO_ALL_TAKES or take_cnt == 1 then
			local take = r.GetActiveTake(item)
			Process_FX_Incl_In_All_Containers(take, recFX, parent_cntnr_idx, parents_fx_cnt, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- recFX false
			elseif APPLY_TO_ALL_TAKES then
				for i = 0, take_cnt-1 do
				local take = r.GetMediaItemTake(item,i)
				Process_FX_Incl_In_All_Containers(take, recFX, parent_cntnr_idx, parents_fx_cnt, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- recFX false
				end
			end
		end

	r.Undo_EndBlock('Simplify FX names', -1)

	else return r.defer(no_undo)
	
	end








