--[[
ReaScript name: BuyOne_Restore FX windows after screenset change.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 	#Added support for FX inside containers
			#Added support for SWS/S&M extension
			#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
About:	To be able to use this script, combine it within a custom action
		with actions which load screensets, e.g.:

		---| BuyOne_Restore FX windows after screenset change.lua
		---| Screenset: Load window set #01

		This will restore FX windows once screenset 01 is loaded.

		Create such custom actions for all screensets after loading which 
		you need FX windows to be restored.

		Whether FX windows are restored after screenset switch can be 
		conditioned by visibility in the relevant context and lock status 
		of their source object (track or item) via USER SETTINGS.  

		As far as visibility is concerned this means that if a track
		is hidden in the Mixer its FX windows and FX windows of items 
		sitting on such track won't be restored when a screenset which 
		features a Mixer is loaded.  
		Conversely FX windows of a track visible in the Mixer but hidden 
		in the Arrange view, won't be restored when changing from 
		a screenset which does feature the Mixer to one which doesn't.  
		
		Empty FX chain windows are not restored.

		CAVEATS

		Without the extensions installed window focus and positions of FX 
		chain windows are not restored. Last positions of floating FX windows 
		are stored in REAPER internally by default.  
		Without the extensions if a screenset has an open docker an FX chain 
		window may get attached to it upon loading such a screenset, despite 
		not being included in it or docked in the initial screenset. 
		All other features aren't affected by absense of extensions.

		When xtensions aee installed FX chain window positions are restored. 
		The script respects position of FX windows included in a screenset. 
		So currently open FX chain window which is docked within the incoming 
		screenset will be docked and floating FX windows included in the incoming 
		screenset will assume their positions stored within the screenset after 
		the screenset is switched to, while positions of all other FX windows 
		will be restored.  
		Focus of FX windows in this case is only restored if screensets are 
		switched with a shortcut, so that mouse click doesn't affect focus.  	

		If the same FX chain window is docked within the outgoing screenset 
		but not included within the incoming screenset, when switching to 
		the incoming screenset the position it was in prior to switching 
		to the outgoing (current) screenset where it's docked, won't be restored. 

		Windows full z-order isn't restored with or without the extensions.

		---

		Input/Monitoring FX floating windows may flicker a little before 
		a screenset is changed.

		Also worth being aware of screenset related FX chain window size quirks 
		unrelated to the script: https://forum.cockos.com/showthread.php?t=278245

		For alternative way or restoring FX windows at screenset change see
		BuyOne_FX windows - store and toggle show windows set_META.lua

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any alphanumeric character
-- between the quotes

-- Applies to open FX windows not included
-- in the incoming screenset,
-- for details see About tag in the header
RESPECT_TRACK_VISIBILITY = ""

-- When enabled, FX windows INCLUDED in the incoming screenset
-- regardless of their being open currently,
-- will not load if their source track is hidden
-- in a relevant context, i.e. Arrange view or Mixer,
-- which is determined by Mixer presence in the screenset;
-- this also applies to FX windows of takes belonging
-- to a particular track;
-- this is the default behavior for FX windows not included
-- in the outgoing and incoming screensets;
-- the setting is independent of the above setting
RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS = ""

-- Enable to prevent restoration of open FX windows
-- not included in the incoming screenset and whose source
-- object (track or item) is locked;
-- currently only relevant for take FX windows, because
-- track FX windows are auto-closed as soon as TCP controls
-- are locked and will remain closed at the moment of screenset switch
RESPECT_OBJECT_LOCKED_STATUS = ""

-- Same as above but applicable to FX windows INCLUDED
-- in the incoming screenset, regardless of their being
-- currently open, so that they are not loaded
-- with the screenset if their source object is locked
RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS = ""

-- If the setting is enabled, FX windows which are included
-- in a current screenset will not be re-loaded after switching
-- to another screenset, meaning only FX windows not attached
-- to any screenset will be re-loaded,
-- FX windows included in the incoming screenset won't be affected;
-- the only time this setting won't work when enabled
-- is at the very 1st screenset activation after project is opened,
-- because at that time there won't be any previously loaded
-- screensets whose FX windows could be stored to be ignored,
-- so FX windows which are open at that moment won't be affected
-- by this setting;
-- tt's not recommended having this setting enabled
-- along with the option 'Auto-save when switching screensets'
-- in the 'Screensets/Layouts' dialogue because this will lead
-- to confusing behavior
DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS = ""

-- The minimum restoration time is 40 ms,
-- in case it works poorly insert a greater value in ms
-- between the quotes
LOAD_TIME_MS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


-- used in Store_Recall_ScreensetEmbedded_FX_Windows() an Re_Store_FX_Windows_Visibility()
function Track_Controls_Locked(tr) -- locked is 1, not locked is nil
	if tr == r.GetMasterTrack(0) then return end -- Master track controls cannot be locked
r.PreventUIRefresh(1)
local mute_state = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state ~ 1) -- flip the state
local mute_state_new = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
local locked
	if mute_state == mute_state_new then locked = 1
	else r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state) -- restore
	end
r.PreventUIRefresh(-1)
return locked
end



-- used in collect_container_fx()
function Collect_All_Container_FX_Indices(obj, t, recFX, parent_cntnr_idx, parents_fx_cnt)
-- creates table containing indices of fx inside containers in nested tables
-- following container hierarchy;
-- obj is track or take, t must be nil, recFX is boolean to target input/Monitoring FX,
-- parent_cntnr_idx, parents_fx_cnt must be nil
-- fx indices from the outermost fx chain (the object main fx chain) are of course stored as well
-- see Loop_Over_FX_Container_Table() next

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

local FXCount, GetIOSize, GetConfig = table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize,
r.TrackFX_GetNamedConfigParm} or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize,
r.TakeFX_GetNamedConfigParm} or {})

local fx_cnt = not parent_cntnr_idx and (recFX and r.TrackFX_GetRecCount(obj) or FXCount(obj))
fx_cnt = fx_cnt or ({GetConfig(obj, parent_cntnr_idx, 'container_count')})[2]

local t = t or {} -- add table for the outermost FX chain on the very first run

--[-[ LOOP COMBINING TWO LOOPS BELOW INTO ONE, UNTESTED
	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	local retval, cont_fx_cnt = GetConfig(obj, i, 'container_count') -- retval true even if container is empty
		if GetIOSize(obj, i) == 8 and cont_fx_cnt+0 > 0 then -- non-empty container
		t[#t] = {i, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and i or 0x2000000+i+1 -- 0x2000000 is only added once, to the index of the outermost parent container
		local parents_fx_cnt = (parents_fx_cnt or 1) * (fx_cnt+1) -- fx_cnt is fx count in the parent container
		-- the function must not return table here, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[#t][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end
--]]

--[[
	-- collect all fx instances in a chain, including containers
	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	end

	-- search for containers in the fx chain data stored above
	-- and if found go recursive to collect fx instances inside them
	for i, fx_idx in ipairs(t) do
	local container = GetIOSize(obj, fx_idx) == 8
	local retval, cont_fx_cnt = GetConfig(obj, fx_idx, 'container_count') -- retval true even if container is empty
		if container and cont_fx_cnt+0 > 0 then -- non-empty container
		t[i] = {fx_idx, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and fx_idx or 0x2000000+fx_idx+1 -- 0x2000000 is only added once, to the index of the outermost parent container
		local parents_fx_cnt = (parents_fx_cnt or 1) * (#t+1) -- #t is equal to fx count in the parent container
		-- the function must not return table here, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[i][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end

--]]

return t

end



-- used in collect_container_fx()
function Loop_Over_FX_Container_Table(obj, t, t2, vis_t, store)
-- obj is track or take, t is the table returned by Collect_All_Container_FX_Indices() above
-- vis_t stems from Store_Recall_ScreensetEmbedded_FX_Windows() via collect_container_fx()
-- store is finction stemming from collect_container_fx()

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Floating, GetGUID = table.unpack(take and {r.TakeFX_GetFloatingWindow, r.TakeFX_GetFXGUID}
or {r.TrackFX_GetFloatingWindow, r.TrackFX_GetFXGUID})
local obj_type = take and 'takefx' or 'trackfx'

	-- target fx instances in a chain ignoring containers
	for k, fx_idx in ipairs(t) do
		if tonumber(fx_idx) then -- fx instance // if container, evaluation will be false since the value is a table
		local wnd = Floating(obj, fx_idx)
			if wnd then
			store(obj, t2, vis_t, take, fx_idx, wnd) -- no need to return tables because their variable don't change
			end
		end
	end

	-- target containers, ignoring fx instances
	for k, cont in ipairs(t) do
		if not tonumber(cont) then -- a table storing container index and its fx list
		local idx = cont[1]
		local wnd = Floating(obj, idx)
			if wnd then
			store(obj, t2, vis_t, take, idx, wnd) -- no need to return tables because their variable don't change
			end
		Loop_Over_FX_Container_Table(obj, cont[2], t2, vis_t, store) -- go recursive to loop over container fx, cont[2] is the address of the nested table with container fx indices list, at cont[1] container own index is stored
		end
	end

end



-- used in Re_Store_FX_Windows_Visibility() and Store_Recall_ScreensetEmbedded_FX_Windows()
function collect_container_fx(obj, cont_idx, recFX, t, vis_t)
-- t stems from Re_Store_FX_Windows_Visibility() and Store_Recall_ScreensetEmbedded_FX_Windows()
-- vis_t stems from Store_Recall_ScreensetEmbedded_FX_Windows()

	local function store(obj, t, vis_t, take, fx_idx, wnd)
	local obj_type = take and 'takefx' or 'trackfx'
		if not vis_t then
		-- reconstructing table hierarchy depending on the object type
		local tr, item = table.unpack(take and {r.GetMediaItemTake_Track(obj), r.GetMediaItemTake_Item(obj)} or {})
		local temp_t = take and t[tr][obj_type][item][obj] or t[obj][obj_type]
		local len = #temp_t + 1
		temp_t[len] = {idx=fx_idx, float=wnd, ui=nil} -- fx chain cannot be opened with container fx UI shown using FX_Show() hence nil
		else
		local fx_GUID = GetGUID(obj, fx_idx)
		local chain_type = fx_idx-0x2000000 >= 0x1000000 and 'input' or 'main' -- for track fx only
		local temp_t = take and t[obj_type].float or t[obj_type][chain_type].float
		local len = #temp_t+1
		temp_t[len] = fx_GUID
		vis_t[#vis_t+1] = fx_idx
		end
	end

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Count, Get_Parm, Floating, GetIOSize, GetGUID = table.unpack(take and {r.TakeFX_GetCount,r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFloatingWindow, r.TakeFX_GetIOSize, r.TakeFX_GetFXGUID} or tr and {recFX and r.TrackFX_GetRecCount or r.TrackFX_GetCount,  r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFloatingWindow, r.TrackFX_GetIOSize, r.TrackFX_GetFXGUID})

local build = tonumber(r.GetAppVersion():match('[%d%.]+'))

	if build >= 7 and build < 7.06 then
	local cont_fx_t = Collect_All_Container_FX_Indices(obj, _, recFX, 0x2000000+cont_idx+1, Count(obj)+1)
	Loop_Over_FX_Container_Table(obj, cont_fx_t, t, vis_t, store)
	elseif build >= 7.06 then
	local ret, count = Get_Parm(obj, cont_idx, 'container_count')
		if count == '0' then return end
		for i=0, count-1 do
		local ret, fx_idx = Get_Parm(obj, cont_idx, 'container_item.'..i)
		fx_idx = fx_idx+0
		local wnd = Floating(obj, fx_idx)
			if wnd then
			store(obj, t, vis_t, take, fx_idx, wnd) -- no need to return tables because their variable don't change
			end
			if GetIOSize(obj, fx_idx) == 8 then -- container, go recursive
			collect_container_fx(obj, fx_idx, recFX, t, vis_t)
			end
		end
	end

end




-- used in RESTORE() and in the main routine
function Store_Recall_ScreensetEmbedded_FX_Windows(recall) -- recall is boolean
-- serves 2 purposes:
-- a) stores fx windows embedded in the incoming screenset and
-- b) closes such windows if their source tracks are hidden in the relevant context (arrange or mixer)
-- or their source object is locked and a corresponing user setting is enabled;
-- the storage is executed immediately after screenset is loaded,
-- before fx windows restoration with Re_Store_FX_Windows_Visibility();
-- the stored data will be used when some other screenset is loaded later
-- to prevent restoration of fx windows associated with the outgoing (last detected, i.e. current) screenset
-- provided the script is executed at that moment, which is not 100% reliable
-- if in the interim screensets were exchanged without script involvement
-- in which case the stored data will be obsolete

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- to ensure more unique extended state section name

	if not recall then -- store

	-- conditions to be used in closing incoming screenset embedded fx windows
	-- whose source track is hidden in a relevant context
	local mixer_vis = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
	local master_vis_flag = r.GetMasterTrackVisibility()
	local master_vis_TCP, master_vis_MCP = master_vis_flag&1 == 1, master_vis_flag&2 == 2

	local t = {trackfx = { main = {chain={}, float={}}, input = {chain={}, float={}} }, takefx = { chain={}, float={} } } -- to store fx whose windows are embedded in the incoming screenset
	local screenset_vis_t = {} -- used for collecting hidden and locked objects of incoming screenset embedded fx windows to  prevent their re-opening inside Re_Store_FX_Windows_Visibility() in case they had been open before the incoming screenset was loaded and thus stored with the said function, because their closing in this function based on vis_t table data won't suffice
		for i = -1, r.CountTracks(0)-1 do -- i -1 to account for the Master track
		local vis_t = {} -- to be used in closing fx windows included in the incoming screenset when RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and/or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS settings are enabled
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		local tr_GUID = r.GetTrackGUID(tr) -- Master track also has GUID
			for i = 0, r.TrackFX_GetCount(tr)-1 do
			local chain = r.TrackFX_GetOpen(tr, i)
			local float = r.TrackFX_GetFloatingWindow(tr, i)
				if chain and not float then -- chain cond. must be limited by not float because TrackFX_GetOpen() returns true in both cases
				local len = #t.trackfx.main.chain+1
				t.trackfx.main.chain[len] = tr_GUID -- GUIDs are used since they will be stored as ext state for which object pointer storage is inconvenient, using indexed table to be able to easily concatenate list of GUIDs when storing
				vis_t[#vis_t+1] = i
				elseif float then
				local fx_GUID = r.TrackFX_GetFXGUID(tr, i)
				local len = #t.trackfx.main.float+1
				t.trackfx.main.float[len] = fx_GUID
				vis_t[#vis_t+1] = i
				end
				if r.TrackFX_GetIOSize(tr, i) == 8 then -- container
				collect_container_fx(tr, i, recFX, t, vis_t)
				end
			end
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			local i = i+0x1000000
			local chain = r.TrackFX_GetOpen(tr, i)
			local float = r.TrackFX_GetFloatingWindow(tr, i)
			--	if chain and not float and not input_chain_stored then -- the function TrackFX_GetRecChainVisible2() returns true on each loop cycle because unlike the native TrackFX_GetOpen() it's not limited to the fx whose UI is visible in the chain, therefore the condition's truthfulness must be limited to 1 time only so superfluous table entries aren't added -- OLD and inefficient
				if chain and not float then -- chain cond. must be limited by not float because TrackFX_GetOpen() returns true in both cases
				local len = #t.trackfx.input.chain+1
				t.trackfx.input.chain[len] = tr_GUID
				vis_t[#vis_t+1] = i
				elseif float then
				local fx_GUID = r.TrackFX_GetFXGUID(tr, i)
				local len = #t.trackfx.input.float+1
				t.trackfx.input.float[len] = fx_GUID
				vis_t[#vis_t+1] = i
				end
				if r.TrackFX_GetIOSize(tr, i) == 8 then -- container
				collect_container_fx(tr, i, 1, t, vis_t) -- recFX 1 true
				end
			end

		-- close any windows embedded in the incoming screenset not open beforehand,
		-- provided the relevant user settings are enabled,
		-- which is possible because this part of the function runs after loading
		-- the incoming screenset and its windows will be exclusively open,
		-- this however isn't enough if such windows WERE open beforehand
		-- (however unlikely this scenario might be considering locked and hidden states)
		-- because they will be stored with Re_Store_FX_Windows_Visibility()
		-- and after closure here will be re-opened by the said function executed after this one
		local is_master_tr = tr == r.GetMasterTrack(0)
		local hidden = RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and ( not mixer_vis and (is_master_tr and not master_vis_TCP or not r.IsTrackVisible(tr, false)) -- mixer false // invisible in the TCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true)
		or mixer_vis and (is_master_tr and not master_vis_MCP or not r.IsTrackVisible(tr, true)) ) -- mixer true // invisible in the MCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
		local locked = RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS and Track_Controls_Locked(tr)

			if hidden or locked then
			screenset_vis_t[tr] = '' -- collect for Re_Store_FX_Windows_Visibility()
				for _, idx in ipairs(vis_t) do -- close all track fx windows included in the incoming screenset if their track is hidden in the relevant context
				r.TrackFX_SetOpen(tr, idx, false) -- open false // close floating window if any
				r.TrackFX_SetOpen(tr, idx, false) -- open false // close fx chain
				end
			end

		end -- track loop end

		for i = 0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			for i = 0, r.CountTakes(item)-1 do
			local vis_t = {} -- to be used in closing fx windows included in the incoming screenset when RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and/or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS settings are enabled
			local take = r.GetTake(item, i)
			local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
				for i = 0, r.TakeFX_GetCount(take)-1 do
				local chain = r.TakeFX_GetOpen(take, i)
				local float = r.TakeFX_GetFloatingWindow(take, i)
					if chain and not float then -- chain cond. must be limited by not float because TrackFX_GetOpen() returns true in both cases
					local len = #t.takefx.chain+1
					t.takefx.chain[len] = take_GUID
					vis_t[#vis_t+1] = i
					elseif float then
					local fx_GUID = r.TakeFX_GetFXGUID(take, i)
					local len = #t.takefx.float+1
					t.takefx.float[len] = fx_GUID
					vis_t[#vis_t+1] = i
					end
					if r.TakeFX_GetIOSize(take, i) == 8 then -- container
					collect_container_fx(take, i, recFX, t, vis_t)
					end
				end

				-- close any windows embedded in the incoming screenset not open beforehand,
				-- provided the relevant user settings are enabled,
				-- which is possible because this part of the function runs after loading
				-- the incoming screenset and its windows will be exclusively open,
				-- this however isn't enough if such windows WERE open beforehand
				-- (however unlikely this scenario might be considering locked and hidden states)
				-- because they will be stored with Re_Store_FX_Windows_Visibility()
				-- and after closure here will be re-opened by the said function executed after this one
				if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS then
				local tr = r.GetMediaItemTake_Track(take)
				local item = r.GetMediaItemTake_Item(take)
					if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and
					( not mixer_vis and not r.IsTrackVisible(tr, false) -- mixer false // invisible in the TCP
					or mixer_vis and not r.IsTrackVisible(tr, true) ) -- mixer true // invisible in the MCP
					or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1
					then
					screenset_vis_t[item] = '' -- collect for Re_Store_FX_Windows_Visibility()
						for _, idx in ipairs(vis_t) do -- close all take fx windows included in the incoming screenset if take source track is hidden in the relevant context
						r.TakeFX_SetOpen(take, idx, false) -- open false // close floating window if any
						r.TakeFX_SetOpen(take, idx, false) -- open false // close fx chain
						end
					end
				end

			end -- take loop end

		end -- item loop end

		-- store as extended state
		if DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS then
			for fx_type, t in pairs(t.trackfx) do -- fx_type is main or input
				for wnd_type, t in pairs(t) do -- wnd_type is chain or float
					if #t > 0 then
					r.SetExtState(named_ID..fx_type, wnd_type, table.concat(t, ' '), false) -- persist false
					end
				end
			end
			for wnd_type, t in pairs(t.takefx) do
				if #t > 0 then
				r.SetExtState(named_ID, wnd_type, table.concat(t, ' '), false) -- persist false
				end
			end
		end

	return screenset_vis_t -- to be used in Re_Store_FX_Windows_Visibility()

	else -- recall

	local t = {trackfx = { main = {chain={}, float={}}, input = {chain={}, float={}} }, takefx = { chain={}, float={} } }
	local wnd_type_t = {'chain','float'}
	-- trackfx
	for _, fx_type in ipairs({'main','input'}) do
		for _, wnd_type in ipairs(wnd_type_t) do
		local GUIDs = r.GetExtState(named_ID..fx_type, wnd_type)
			if #GUIDs > 0 then
				for GUID in GUIDs:gmatch('{.-}') do
					if GUID and #GUID > 0 then
					t.trackfx[fx_type][wnd_type][GUID] = '' -- dummy field, storing GUID as table key allows direct evaluation without looping
					end
				end
			end
		end
	end
	-- takefx
	for _, wnd_type in ipairs(wnd_type_t) do
	local GUIDs = r.GetExtState(named_ID, wnd_type)
		if #GUIDs > 0 then
			for GUID in GUIDs:gmatch('{.-}') do
				if GUID and #GUID > 0 then
				t.takefx[wnd_type][GUID] = '' -- dummy field
				end
			end
		end
	end

	return t -- to be used inside Re_Store_FX_Windows_Visibility()

	end -- recall cond end

end




-- used in RESTORE() and in the main routine
function Re_Store_FX_Windows_Visibility(t, screenset_vis_t)
-- SCRIPT CORE FUNCTION
-- if screenset wasn't changed, simply stores and restores fx windows,
-- i.e. if the script was executed by itself in which case nothing happens visually,
-- OR if the current screenset has been reloaded after script launch regardless of
-- DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS sett being enabled and last screenset fx windows data present,
-- which is possible because when current screenset is reloaded
-- windows embedded in it are not closed and reloaded but remain open,
-- whereas when another screenset is called, all current windows are auto-closed
-- so you can choose not to re-open those embedded in the outgoing screenset based on the data
-- stored with Store_Recall_ScreensetEmbedded_FX_Windows() when the outgoing screenset was incoming;
-- doesn't restore focus and z-order
-- take fx windows are linked to track to be able to ignore them when the track is hidden;
-- screenset_vis_t table stems from Store_Recall_ScreensetEmbedded_FX_Windows()
-- containing parent tracks and takes of incoming screenset embedded fx windows
-- which were closed in the said function after screenset loading due to
-- satisfying conditions expected by RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS
-- and RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS user settings

	-- store
	if not t then
	local t, take_name_t = {}, {} -- take_name_t is only used when js_ReaScriptAPI is available because it will be used to get windows by names which must be unique for which purpose takes are temporarily renamed
		for i = -1, r.CountTracks(0)-1 do -- i -1 to account for the Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		t[tr] = {trackfx = {}, takefx = {}}
			for i = 0, r.TrackFX_GetCount(tr)-1 do
				if r.TrackFX_GetOpen(tr, i) then -- is open in the FX chain window or a floating window
				local len = #t[tr].trackfx+1
				-- storing floating status and fx chain UI visibility status even if the UI is floating
				t[tr].trackfx[len] = {idx=i, float=r.TrackFX_GetFloatingWindow(tr, i), ui=r.TrackFX_GetChainVisible(tr)==i}
				end
				if r.TrackFX_GetIOSize(tr, i) == 8 then -- container
				collect_container_fx(tr, i, recFX, t)
				end
			end
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			local i = i+0x1000000
			local open_fx_idx = r.TrackFX_GetRecChainVisible(tr)+0x1000000 -- returns regular 0-based index hence addition of 0x1000000
				if r.TrackFX_GetOpen(tr, i) then -- is open in the FX chain window or a floating window
				local len = #t[tr].trackfx+1
				t[tr].trackfx[len] = {idx=i, float=r.TrackFX_GetFloatingWindow(tr, i), ui=open_fx_idx==i}
				end
				if r.TrackFX_GetIOSize(tr, i) == 8 then -- container
				collect_container_fx(tr, i, 1, t) -- recFX 1 true
				end
			end
			for i = 0, r.GetTrackNumMediaItems(tr)-1 do
			local itm = r.GetTrackMediaItem(tr,i)
			t[tr].takefx[itm] = {}
				for i = 0, r.CountTakes(itm)-1 do
				local take = r.GetTake(itm, i)
				t[tr].takefx[itm][take] = {}
				local has_fx
					for i = 0, r.TakeFX_GetCount(take)-1 do
						if r.TakeFX_GetOpen(take, i) then -- is open in the FX chain window or a floating window
						has_fx = true
						local len = #t[tr].takefx[itm][take]+1
						t[tr].takefx[itm][take][len] = {idx=i, float=r.TakeFX_GetFloatingWindow(take, i), ui=r.TakeFX_GetChainVisible(take)==i}
						end
						if r.TakeFX_GetIOSize(take, i) == 8 then -- container
						collect_container_fx(take, i, recFX, t) -- recFX false
						end
					end

				end
			end
		end

	return t

	-- restore
	elseif t then

	screenset_vis_t = screenset_vis_t or {} -- to prevent error when it's nil because RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and/or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS user settings aren't enabled and Store_Recall_ScreensetEmbedded_FX_Windows() doesn't run inside RESTORE() function

		for tr in pairs(t) do
		local mixer_vis = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
		local master_vis_flag = r.GetMasterTrackVisibility()
		local master_vis_TCP, master_vis_MCP = master_vis_flag&1 == 1, master_vis_flag&2 == 2
		local is_master_tr = tr == r.GetMasterTrack(0)

			if r.ValidatePtr(tr, 'MediaTrack*') and RESPECT_TRACK_VISIBILITY
			and (not mixer_vis and (is_master_tr and master_vis_TCP or r.IsTrackVisible(tr, false)) -- mixer false // visible in the TCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or mixer_vis and (is_master_tr and master_vis_MCP or r.IsTrackVisible(tr, true)) ) -- mixer true // visible in the MCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or not RESPECT_TRACK_VISIBILITY -- track is visible for RESPECT_TRACK_VISIBILITY user setting
			and not screenset_vis_t[tr] -- track is visible and not locked to satisfy RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS user settings
			then

			-- create conditions to prevent re-loading fx chain windows embedded in the last (outgoing) screenset,
			-- will only work if the last stored data stems from the outgoing screenset
			-- which will only be the case if it was loaded with the script involvement;
			-- last_screenset_wnds stems from Store_Recall_ScreensetEmbedded_FX_Windows()
			-- returned as a global variable table at the very start of the routine
			local tr_GUID = r.GetTrackGUID(tr)
			local main_chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.main.chain[tr_GUID]
			local input_mon_chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.input.chain[tr_GUID]

				if not RESPECT_OBJECT_LOCKED_STATUS or not Track_Controls_Locked(tr) then -- redundant with the current REAPER features because track fx windows are auto-closed as soon as their source track control panel is locked so by the moment of screenset switch the windows will be already closed, but leaving anyway, the condition will just always be false

					for _, fx_data in ipairs(t[tr].trackfx) do
					local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_data.idx)

					-- create conditions to prevent re-loading floating fx windows embedded in the last (outgoing) screenset
					local main_float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.main.float[fx_GUID]
					local input_mon_float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.input.float[fx_GUID]
					local no_restore_chain, no_restore_float = main_chain or input_mon_chain, main_float or input_mon_float
						if fx_data.ui and not no_restore_chain then r.TrackFX_Show(tr, fx_data.idx, 1) end -- showFlag 1 (open FX chain with fx ui shown) // OR r.TrackFX_SetOpen(tr, fx_idx, true) -- open true
						if fx_data.float and not no_restore_float then r.TrackFX_Show(tr, fx_data.idx, 3) end -- showFlag 3 (open in a floating window)

					end

				end -- respect locked cond. end

				for itm, takes_t in pairs(t[tr].takefx) do

				local itm_locked = r.GetMediaItemInfo_Value(itm, 'C_LOCK')&1 == 1

					if (not RESPECT_OBJECT_LOCKED_STATUS or not itm_locked)
					and not screenset_vis_t[itm] -- item is not locked to satisfy RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS user setting
					then

						for take, fx_t in pairs(takes_t) do

						local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
						local no_restore_chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.takefx.chain[take_GUID] -- condition to prevent re-loading fx chain windows embedded in the last (outgoing) screenset

							for _, fx_data in ipairs(fx_t) do

							local fx_GUID = r.TakeFX_GetFXGUID(take, fx_data.idx)
							local no_restore_float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.takefx.float[fx_GUID] -- condition to prevent re-loading floating fx windows embedded in the last (outgoing) screenset

								if fx_data.ui and not no_restore_chain then r.TakeFX_Show(take, fx_data.idx, 1) end -- showFlag 1 (open FX chain with fx ui shown) // OR r.TakeFX_SetOpen(take, fx_data.idx, true) -- open true
								if fx_data.float and not no_restore_float then r.TakeFX_Show(take, fx_data.idx, 3) end -- showFlag 3 (open in a floating window)
							end

						end -- take loop end

					end -- respect locked cond. end

				end -- item loop end

			end -- visibility conditions end

		end -- track loop end

	end

end




-- used in Re_Store_Windows_Props_By_Names()
function Find_Child_SWS(parent_hwnd, child_title, want_exact)
-- want exact is boolean to search for exact title match,
-- if false, child_title will be searched as a subtring in window titles

local child = r.BR_Win32_GetWindow(parent_hwnd, 5) -- 5 = GW_CHILD

	if not child then return end

	repeat
	local ret, txt = r.BR_Win32_GetWindowText(child)
		if want_exact and txt == child_title or not want_exact and txt:match(child_title) then
		return child
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT
	until not child

end


-- Get_FX_Windows()
function Get_Sibling_Windows(wnd, excl_orig)
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
-- excl_orig is boolean to ignore wnd when collecting data

	if not wnd then return end

local sws, js = r.BR_Win32_GetWindow, r.JS_Window_GetRelated

	if not sws and not js then return end

local Get = r.BR_Win32_GetWindow or r.JS_Window_GetRelated

-- get first sibling window
local dir = sws and 3 or 'PREV' -- 3 = GW_HWNDPREV
local wnd, sibl = wnd
	repeat
	wnd = Get(wnd, dir)
	sibl = wnd or sibl
	until not wnd

	if not sibl then return end

local dir = sws and 2 or 'NEXT' -- 2 = GW_HWNDNEXT
local t = {}
	repeat
	sibl = Get(sibl, 2)
		if sibl and (excl_orig and sibl ~= wnd or not excl_orig) then
		t[#t+1] = sibl
		end
	until not sibl

return t

end



-- used in Get_FX_Windows()
function Get_Docked_Windows(t)
-- t is table stemming from Get_Sibling_Windows()
-- to continue collecting window handles

local sws, js = r.BR_Win32_GetWindow, r.JS_Window_GetRelated

	if not sws and not js then return end

local Get = r.BR_Win32_GetWindow or r.JS_Window_GetRelated

local main = r.GetMainHwnd()
local dock_t = {}
local get_child = sws and 5 or 'CHILD' -- 5 = GW_CHILD
local child = Get(main, get_child)

	if not child then return dock_t end

-- collect all docker windows, which are children of the main window
local nxt = sws and 2 or 'NEXT' -- 2 = GW_HWNDNEXT
	repeat
	local ret, txt = table.unpack(sws and {r.BR_Win32_GetWindowText(child)} or {nil, r.JS_Window_GetTitle(child)}) -- the js extension function only returns a single value so matching to 2 return values of the sws function
		if txt == 'REAPER_dock' then dock_t[child] = '' end
	child = Get(child, nxt)
	until not child

local t = t or {}
	-- collect children of all collected dockers
	for docker in pairs(dock_t) do
	local child = Get(docker, get_child)
		if child then
			repeat
				if child then t[#t+1] = child
				end
			child = Get(child, nxt)
			until not child
		end
	end

return t

end



-- used in Re_Store_Windows_Props_By_Names()
function Get_FX_Windows()

local sws, js = r.BR_Win32_GetWindow, r.JS_Window_GetRelated

	if not sws and not js then return end

local substr = {
'FX: Track','FX: Item','FX: Master','FX: Monitoring', -- chain
'- Track','- Item','- Master','- Monitoring', -- floating windows
'/ Track','/ Item','/ Master','/ Monitoring' -- containers
}
local wnd_t = {}
local t = Get_Sibling_Windows(r.GetMainHwnd(), 1) -- excl_orig 1 true, to not store the main window in the table
t = Get_Docked_Windows(t)
	for k, wnd in ipairs(t) do
	local ret, title = table.unpack(sws and {r.BR_Win32_GetWindowText(wnd)} or {nil, r.JS_Window_GetTitle(wnd)}) -- the js extension function only returns a single value so matching to 2 return values of the sws function
		for k, str in ipairs(substr) do
			if title:match(Esc(str)) then
			wnd_t[#wnd_t+1] = wnd
			break end
		end
	end

return wnd_t

end



-- used in RESTORE() and in the main routine
function Re_Store_Windows_Props_By_Names(t)
-- position of fx floating windows seem to be stored automatically
-- and is not affected by screenset change or recall of the current screenset
-- so essentially would not need storage here,
-- but fx chain windows positions are,
-- even though some windows do keep their postions in this scenario;
-- supports docked windows
-- https://forums.cockos.com/showthread.php?p=2538915
-- https://forum.cockos.com/showthread.php?t=249817

local sws, js = r.BR_Win32_IsWindowVisible, r.JS_Window_IsVisible

	if not sws and not js then return end

local IsVisible, GetRect, GetForegrnd, SetFocus, SetForegrnd = table.unpack(sws and {r.BR_Win32_IsWindowVisible,
r.BR_Win32_GetWindowRect, r.BR_Win32_GetForegroundWindow, r.BR_Win32_SetFocus, r.BR_Win32_SetForegroundWindow}
or {r.JS_Window_IsVisible, r.JS_Window_GetRect, r.JS_Window_GetForeground, r.JS_Window_SetFocus, r.JS_Window_SetForeground})

	if not t then
	local wnd_t = Get_FX_Windows() -- collecting both fx chain and fx floating windows even though positions of the latter are restored when re-opened, just to be able to exclude them inside Exclude_Screenset_Embedded_Visible_Windows() from the table returned by this function in case they're embedded in the incoming screenset where their stored positions must be respected according to script design
	local t = {}
		for k, hwnd in ipairs(wnd_t) do
			if IsVisible(hwnd) -- FX chain windows may happen to be visible even when closed, there're no fx and the object is hidden in Arrange, fx floating window are only visible when floating
			then
			local ret, title = table.unpack(sws and {r.BR_Win32_GetWindowText(hwnd)}
			or {nil, r.JS_Window_GetTitle(hwnd)}) -- the js extension function only returns a single value so matching to 2 return values of the sws function
			local retval, lt, tp, rt, bt = GetRect(hwnd)
			local w, h = rt-lt, r.GetOS():match('OSX') and tp-bt or bt-tp -- isn't necessary if r.JS_Window_Move() is used for restoration rather than r.JS_Window_SetPosition()
			t[#t+1] = {tit=title, lt=lt, tp=tp, w=w, h=h, foregrnd=GetForegrnd()==hwnd}
			end
		end

	return t

	else
		for _, wnd in ipairs(t) do
		local hwnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(r.GetMainHwnd()), '0', '', wnd.tit, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // OR r.BR_Win32_FindWindowEx('0', '0', '', wnd.tit, false, true)
		or r.JS_Window_Find(wnd.tit, true) -- exact true
		-- when switching to a screenset with an open docker a window may get attached to it
		-- even without being included in the screenset at all whether docked or non-docked,
		-- docked fx windows included in the incoming screenset are filtered out from the table
		-- by Exclude_Screenset_Embedded_Visible_Windows() because they're included in the table
		-- teturned by the storage routine of this functon, if after that any fx window
		-- ends up being docked it must be made floating
		local dock_idx, isFloatingDocker = r.DockIsChildOfDock(hwnd)
			if dock_idx > -1 then
			local child_hwnd = sws and Find_Child_SWS(hwnd, 'List1', 1) or r.JS_Window_FindChild(hwnd, 'List1', true) -- want_exact and exact true respectively // get internal List1 window of FX chain window to set focus to
			SetFocus(child_hwnd)
			ACT(41172) -- Dock/undock currently focused dockable window, or attach/unattach focused docker
			end
			-- SetPosition functions of both extensions seem to set positions
			-- in reverse and affecting the z-order, making foreground window background and vice versa
			-- so if floating fx windows are displayed in front of fx chain window,
			-- after restoration they end up behind it;
			-- JS_Window_Move() on the other hand doesn't affect z-order in which windows
			-- were opened, fx chain is opened first inside Re_Store_FX_Windows_Visibility()
			-- hence it remains in the background, that's why JS_Window_Move() is preferred
			if not js then
			r.JS_Window_Move(hwnd, wnd.lt, wnd.tp) -- restore position
			-- OR
			--	r.JS_Window_SetPosition(hwnd, wnd.lt, wnd.tp, wnd.w, wnd.h) -- ZOrder, flags are omitted
			else
			r.BR_Win32_SetWindowPos(hwnd, '', wnd.lt, wnd.tp, wnd.w, wnd.h, 0x0040) -- hwndInsertAfter empty string, optional, flags 0x0200 SWP_NOREPOSITION or SWP_NOOWNERZORDER does not change the owner window's position in the Z-order, ensures that whatever window which is now in focus has Z order priority as is usually the case, 0x0040 SWP_SHOWWINDOW Displays the window, flags can simply be 0 // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos
			end
			if wnd.foregrnd then SetForegrnd(hwnd) end -- only restored if the script is run via a shortcut because clicking changes foreground window, r.JS_Window_SetZOrder() should be avoided as it's global to the OS
		end
	end
end




-- used in RESTORE()
function Exclude_Screenset_Embedded_Visible_Windows(t)
-- to keep positions of any windows included in the incoming screenset
-- rather than restoring them with Re_Store_Windows_Props_By_Names()
-- in case they were open at the moment of screenset change
-- and stored in Re_Store_Windows_Props_By_Names() where t argument stems from;
-- t arg table stems from Re_Store_Windows_Props_By_Names() returned
-- at the start of the routine

	if t then
	local sws, js = r.BR_Win32_IsWindowVisible, r.JS_Window_IsVisible
		for i=#t,1,-1 do -- in reverse because of removal below
		local wnd = t[i]
		local hwnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(r.GetMainHwnd()), '0', '', wnd.tit, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // OR r.BR_Win32_FindWindowEx('0', '0', '', wnd.tit, false, true)
		or js and r.JS_Window_Find(wnd.tit, true) -- exact true
			if sws and r.BR_Win32_IsWindowVisible(hwnd) or js and r.JS_Window_IsVisible(hwnd) -- OR Window_Is_Visible(hwnd), visible after screenset is loaded
			then
			table.remove(t,i)
			end
		end
	end
end





function RESTORE()
	if next(fx_t) and r.time_precise() - time >= LOAD_TIME_MS -- wait allowing the screenset to load // usually takes longer here but still doesn't fall through, 1 ms does
	then
		if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS
		or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS
		or DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS then
		screenset_vis_t = Store_Recall_ScreensetEmbedded_FX_Windows() -- store, recall is nil // optionally prevent restoration of screenset embedded fx windows after the screenset change and/or close them if their source track/item is hidden in the relevant context (arrange or mixer) or locked and return table to prevent their re-opening inside Re_Store_FX_Windows_Visibility() if they were open before screenset switch
		end
	Exclude_Screenset_Embedded_Visible_Windows(wnd_t) -- supposed to run immediately after screenset change and before fx windows visibility restoration to detect any windows which load with the incoming screenset to prevent restoring their position with Re_Store_Windows_Props_By_Names() and affecting their screenset stored position
	Re_Store_FX_Windows_Visibility(fx_t, screenset_vis_t)
		if extensions then
		Re_Store_Windows_Props_By_Names(wnd_t)
		end
	return end
r.defer(RESTORE)
end


RESPECT_TRACK_VISIBILITY = validate_sett(RESPECT_TRACK_VISIBILITY)
RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS = validate_sett(RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS)
RESPECT_OBJECT_LOCKED_STATUS = validate_sett(RESPECT_OBJECT_LOCKED_STATUS)
RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS = validate_sett(RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS)
DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS = validate_sett(DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS)
LOAD_TIME_MS = (not tonumber(LOAD_TIME_MS) or tonumber(LOAD_TIME_MS) <= 40) and 0.04 or tonumber(LOAD_TIME_MS)/1000
sws, js_ReaScriptAPI = r.BR_Win32_FindWindowEx, r.JS_Window_Find
extensions = sws or js_ReaScriptAPI

r.PreventUIRefresh(1)

fx_t, take_name_t = Re_Store_FX_Windows_Visibility() -- store currently open fx windows before screenset is loaded
wnd_t = extensions and Re_Store_Windows_Props_By_Names() -- store handles of currently open fx windows to be able to restore their positions // must come after Re_Store_FX_Windows_Visibility() because in it take names are changed which is necessary for getting unique windows data
last_screenset_wnds = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and Store_Recall_ScreensetEmbedded_FX_Windows(true) -- recall true // recall from extended state stored with Store_Recall_ScreensetEmbedded_FX_Windows() when the outgoing (current) screenset was just loaded; not 100% failproof because the screenset can be changed in-between without involvement of the script and its new window content won't be reflected in the stored data

time = r.time_precise()

RESTORE()

r.PreventUIRefresh(-1)

