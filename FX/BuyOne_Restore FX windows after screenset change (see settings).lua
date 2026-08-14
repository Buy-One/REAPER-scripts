--[[
ReaScript name: BuyOne_Restore FX windows after screenset change.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: js_ReaScriptAPI recommended
About:  To be able to use this script, combine it within a custom action
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
		is hidden in the Mixer its FX windows and FX windows of items sitting 
		on such track won't be restored when a screenset which features a Mixer 
		is loaded.  
		Conversely FX windows of a track visible in the Mixer but hidden 
		in the Arrange view, won't be restored when changing from a screenset
		featuring the Mixer to one which doesn't.  
		
		CAVEATS
		
		Without js_ReaScriptAPI extension installed window focus and positions 
		of FX chain windows are not restored. Last positions of floating FX windows 
		are stored in REAPER internally by default.  
		Without the js_ReaScriptAPI extension if a screenset has an open docker 
		an FX chain window may get attached to it upon loading such a screenset, 
		despite not being included in it or docked in the initial screenset. 
		All other features aren't affected by absense of js_ReaScriptAPI extension.
		
		When js_ReaScriptAPI extension is installed FX chain window positions 
		are restored. The script respects position of FX windows included in 
		a screenset. So an FX window which is docked within a screenset will 
		remain docked and a floating FX window will retain its position after 
		the screenset is switched to, while all other FX window positions will 
		be restored.  
		Window focus in this case is only restored if screensets are switched 
		with a shortcut, so that mouse click doesn't affect focus.  		
		
		If the same FX chain window is docked within one screenset but not 
		saved within another screenset, when switching to such other screenset 
		the position it was in prior to switching to the screenset where it's 
		docked, won't be restored. 
		
		Windows full z-order isn't restored with or without the extension.
		
		---
		
		Input/Monitoring FX floating windows may flicker a little before 
		a screenset is changed.  
		
		Also worth being aware of screenset related FX chain window size quirks 
		unrelated to the script: https://forum.cockos.com/showthread.php?t=278245
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any alphanumeric character
-- between the quotes

-- Applies to FX windows not attached to any screenset,
-- for details see About tag in the header
RESPECT_TRACK_VISIBILITY = ""

-- When enabled, FX windows included in the incoming screenset
-- will not load if their source track is hidden
-- in a relevant context, i.e. Arrange view or Mixer,
-- which is determined by Mixer presence in the screenset;
-- this also applies to FX windows of takes belonging
-- to a particular track;
-- this is the default behavior for FX windows not attached
-- to outgoing and incoming screensets;
-- the setting is independent of the above setting
RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS = ""

-- Enable to prevent restoration of FX windows which are not
-- included in the outgoing screenset and whose source
-- object (track or item) is locked;
-- currently only relevant for take FX windows, because
-- track FX windows are auto-closed as soon as TCP controls
-- are locked and will remain closed at the moment of screenset switch
RESPECT_OBJECT_LOCKED_STATUS = ""

-- The same as above but applicable to FX windows included
-- in the incoming screenset, so that they are not loaded
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
-- by this setting
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


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


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


function TrackFX_GetRecChainVisible1(tr)
-- when fx is selected in the chain and its is UI floating
-- in track main and take fx chains such fx is determined
-- with TrackFX_GetChainVisible() but it doesn't support input and monitoring fx chains
	if not tr or not r.ValidatePtr(tr, 'MediaTrack*') then return end
	if tr then
	local t = {}
	local CountFX = r.TrackFX_GetRecCount
	r.PreventUIRefresh(1)
		for i = 0, CountFX(tr)-1 do -- close and store all floating windows
		local idx = 0x1000000+i
			if r.TrackFX_GetFloatingWindow(tr, idx) then
			r.TrackFX_SetOpen(tr, idx, false) -- open false // close floating window
			-- OR
			-- r.TrackFX_Show(tr, idx, 2) -- showFlag 2 - close floating window
			t[#t+1] = idx
			end
		end
	local open_fx_idx -- get fx whose UI is open in FX chain
		for i = 0, CountFX(tr)-1 do
		local idx = i+0x1000000
			if r.TrackFX_GetOpen(tr, idx) then
			open_fx_idx = idx break end
		end
	-- restore floating windows	// z-order and focused window won't be restored, the foreground will be occupied but the window of the fx selected in the fx chain if its window was floating, otherwise the windows are loaded in the fx order
		for _, fx_idx in ipairs(t) do
		r.TrackFX_Show(tr, fx_idx, 3) -- showFlag 3 - open in a floating window
		end
	r.PreventUIRefresh(-1)
	return open_fx_idx
	end
end


function TrackFX_GetRecChainVisible2(tr)
-- only returns fx chain window status
	if not tr or not r.ValidatePtr(tr, 'MediaTrack*') then return end
r.PreventUIRefresh(1)
local chain_open, shown_fx
	for i = 0, r.TrackFX_GetRecCount(tr)-1 do
	local i = i+0x1000000
		if r.TrackFX_GetOpen(tr, i)
		and not r.TrackFX_GetFloatingWindow(tr, i) then
		chain_open, shown_fx = true, i
		break
		elseif r.TrackFX_GetOpen(tr, i) then
		shown_fx = i
		end
	end
	if not chain_open then -- retry in case the chain is open but empty or the fx open in the chain but also floating which in itself isn't reliable because it returns true even when the chain is closed
	r.TrackFX_AddByName(tr, 'ReaGate', true, -1000) -- recFX true, instantiate -1000 (1st slot) // insert temporary stock fx to evaluate against it, its UI will be automatically shown in the chain
	local idx = 0x1000000 -- 1st slot
	chain_open = r.TrackFX_GetOpen(tr, idx)
	r.TrackFX_Delete(tr, idx)
	local restore = shown_fx and r.TrackFX_SetOpen(tr, shown_fx, true) -- open true // restore // will bring the fx floating window, if any, to the fore
	end
r.PreventUIRefresh(-1)
return chain_open
end


function Re_Store_FX_Windows_Visibility(t)
-- restores positions if screenset wasn't changed
-- doesn't restore focus and z-order
-- take fx windows are linked to track to be able to ignore them when the track is hidden
	if not t then
	t, take_name_t = {}, {} -- take_name_t is only used when js_ReaScriptAPI is available because it will be used to get windows by names which must be unique for which purpose takes are temporarily renamed
		for i = -1, r.CountTracks(0)-1 do -- i -1 to account for the Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		t[tr] = {trackfx = {}, takefx = {}}
			for i = 0, r.TrackFX_GetCount(tr)-1 do
				if r.TrackFX_GetOpen(tr, i) then -- is open in the FX chain window or a floating window
				local len = #t[tr].trackfx+1
				-- storing floating status and fx chain UI visibility status even if the UI is floating
				t[tr].trackfx[len] = {idx=i, float=r.TrackFX_GetFloatingWindow(tr, i), ui=r.TrackFX_GetChainVisible(tr)==i}
				end
			end
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			local i = i+0x1000000
			local open_fx_idx = TrackFX_GetRecChainVisible1(tr)
				if r.TrackFX_GetOpen(tr, i) then -- is open in the FX chain window or a floating window
				local len = #t[tr].trackfx+1
				t[tr].trackfx[len] = {idx=i, float=r.TrackFX_GetFloatingWindow(tr, i), ui=open_fx_idx==i}
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
					end

					if has_fx and js_ReaScriptAPI then -- store original name (not mandatory, depends on the restoration method of either re-applying the full name or removing the appendage and applying the resulting string) and temporarily rename take to make it 100% unique for windows search, because they're stored and set by name with Re_Store_Windows_Props_By_Names() // only makes sense when js_ReaScriptAPI is installed
					local ret, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- setNewValue false
					local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
					take_name_t[take] = take_name
					r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', take_name..' '..take_GUID, true) -- setNewValue true
					end

				end
			end
		end
	return t, take_name_t
	elseif t then
		for tr in pairs(t) do
		local mixer_vis = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
		local master_vis_flag = r.GetMasterTrackVisibility()
		local master_vis_TCP, master_vis_MCP = master_vis_flag&1 == 1, master_vis_flag&2 == 2
		local is_master_tr = tr == r.GetMasterTrack(0)
		--[[
			if r.ValidatePtr(tr, 'MediaTrack*')
			and (not mixer_vis and (is_master_tr and master_vis_TCP or r.IsTrackVisible(tr, false)) -- mixer false // visible in the TCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or mixer_vis and (is_master_tr and master_vis_MCP or r.IsTrackVisible(tr, true)) ) -- mixer true // visible in the MCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or IGNORE_TRACK_VISIBILITY
			then
		]]
			if r.ValidatePtr(tr, 'MediaTrack*') and RESPECT_TRACK_VISIBILITY
			and (not mixer_vis and (is_master_tr and master_vis_TCP or r.IsTrackVisible(tr, false)) -- mixer false // visible in the TCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or mixer_vis and (is_master_tr and master_vis_MCP or r.IsTrackVisible(tr, true)) ) -- mixer true // visible in the MCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
			or not RESPECT_TRACK_VISIBILITY
			then

			-- create conditions to prevent re-loading fx chain windows embedded in the last (outgoing) screenset
			local tr_GUID = r.GetTrackGUID(tr)
			local main_chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.main.chain[tr_GUID]
			local input_mon_chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.input.chain[tr_GUID]

				if RESPECT_OBJECT_LOCKED_STATUS and not Track_Controls_Locked(tr) or not RESPECT_OBJECT_LOCKED_STATUS then -- redundant with the current REAPER features because track fx windows are auto-closed as soon as their source track control panel is locked so by the moment of screenset switch the windows will be already closed, but leaving anyway, the condition will just always be false

					for _, fx_data in ipairs(t[tr].trackfx) do

					local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_data.idx)

					-- create conditions to prevent re-loading floating fx windows embedded in the last (outgoing) screenset
					local main_float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.main.float[fx_GUID]
					local input_mon_float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.trackfx.input.chain[fx_GUID]

					local chain = main_chain and fx_data.idx < 0x1000000 or input_mon_chain and fx_data.idx >= 0x1000000
					local float = main_float and fx_data.idx < 0x1000000 or input_mon_float and fx_data.idx >= 0x1000000

						if fx_data.ui and not chain then r.TrackFX_Show(tr, fx_data.idx, 1) end -- showFlag 1 (open FX chain with fx ui shown) // OR r.TrackFX_SetOpen(tr, fx_idx, true) -- open true
						if fx_data.float and not float then r.TrackFX_Show(tr, fx_data.idx, 3) end -- showFlag 3 (open in a floating window)

					end

				end -- respect locked cond. end

				for itm, takes_t in pairs(t[tr].takefx) do

				local itm_locked = r.GetMediaItemInfo_Value(itm, 'C_LOCK')&1 == 1

					if RESPECT_OBJECT_LOCKED_STATUS and not itm_locked or not RESPECT_OBJECT_LOCKED_STATUS then

						for take, fx_t in pairs(takes_t) do

						local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
						local chain = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.takefx.chain[take_GUID] -- condition to prevent re-loading fx chain windows embedded in the last (outgoing) screenset

							for _, fx_data in ipairs(fx_t) do

							local fx_GUID = r.TakeFX_GetFXGUID(take, fx_data.idx)
							local float = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and last_screenset_wnds.takefx.float[fx_GUID] -- condition to prevent re-loading floating fx windows embedded in the last (outgoing) screenset

								if fx_data.ui and not chain then r.TakeFX_Show(take, fx_data.idx, 1) end -- showFlag 1 (open FX chain with fx ui shown) // OR r.TakeFX_SetOpen(take, fx_data.idx, true) -- open true
								if fx_data.float and not float then r.TakeFX_Show(take, fx_data.idx, 3) end -- showFlag 3 (open in a floating window)
							end

						end -- take loop end

					end -- respect locked cond. end

				end -- item loop end

			end -- visibility conditions end

		end -- track loop end

	end

end


-- CURRENTLY NOT USED, BUT LET IT STAY
function Close_ScreensetWindows_Of_HiddenTracks(title) -- windows which are included in a screenset

-- get track from window titles
local track_idx = title:match('Track (%d+)') or title:match('Master') or title:match('Monitor')
local input_mon_fx_chain = title:match('input FX') or title:match('Monitor')
local take_GUID = not track_idx and title:match('.+({.+)') -- included in the temporarily renamed take label
local tr, take
	if track_idx then
	tr = not tonumber(track_idx) and r.GetMasterTrack(0)
	or r.CSurf_TrackFromID(tonumber(track_idx), false) -- mcpView false
	elseif take_GUID then
	take = r.GetMediaItemTakeByGUID(0, take_GUID)
	tr = r.GetMediaItemTake_Track(take)
	end
-- check visibility
local mixer_vis = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
local master = tr == r.GetMasterTrack()
local track_hidden = not mixer_vis and (master and r.GetMasterTrackVisibility()&1 ~= 1
or not r.IsTrackVisible(tr, false)) -- mixer false
or (master and r.GetMasterTrackVisibility()&2 ~= 2 or not r.IsTrackVisible(tr, true)) -- mixer true
	if track_hidden then
	-- close all fx windows
	local GetFXCount, FXSetOpen, FXShow = table.unpack(track_idx and {input_mon_fx_chain and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_SetOpen, r.TrackFX_Show} or take_GUID and {r.TakeFX_GetCount, r.TakeFX_SetOpen, r.TakeFX_Show} or {} )
	local obj = take or tr
		for i = 0, GetFXCount(obj)-1 do
		local i = input_mon_fx_chain and i+0x1000000 or i
		FXSetOpen(obj, i, false) -- open false // 1st time to close floating window if any
		FXSetOpen(obj, i, false) -- open false // 2nd time to close the chain if was open
	--[[ OR
		FXShow(obj, i, 2) -- showFlag 0 (close floating window)
		FXShow(obj, i, 0) -- showFlag 0 (close chain)
	  ]]
		end
	end

end


function Exclude_Screenset_Embedded_Visible_Windows(t)
-- to keep positions of any windows included in the incoming screenset in case they were open at the moment of screenset change and stored in Re_Store_Windows_Props_By_Names()
	if t then
		for i=#t,1,-1 do
		local wnd = t[i]
		local hwnd = r.JS_Window_Find(wnd.tit, true) -- exact true
			if r.JS_Window_IsVisible(hwnd) --or Window_Is_Visible(hwnd)
			then
			--[[ WORKS, BUT MOVED TO Store_Recall_ScreensetEmbedded_FX_Windows(), that routine doesn't require js_ReaScript extension;
			this particular version works in such a way that if the source track of an FX window included within the incoming screenset is hidden in the relevant context and this FX window is open when such screenset is being loaded then it won't be restored, i.e. won't load in a screenset it's supposed to appear in, but if the screenset is reloaded in place afterwards it will re-appear; the currently enabled version hides windows included in the incoming screenset regardless of whether they had been open before the screenset was switched to and doesn't allow reloading them by simply retriggering screenset load action, seems more straightforward
			if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS then
			Close_ScreensetWindows_Of_HiddenTracks(wnd.tit)
			end
			--]]
			table.remove(t,i)
			end
		end
	end
end


function Store_Recall_ScreensetEmbedded_FX_Windows(recall) -- recall is boolean
-- serves 2 purposes a) stores fx windows embedded in the incoming screenset and b) closes such windows if their source tracks are hidden in the relevant context or their source object is locked and a corresponing user setting is enabled
-- to be run immediately after screenset is loaded, before fx windows restoration

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- to ensure more unique extended state section name

	if not recall then

	-- conditions to be used in closing incoming screenset embedded fx windows whose source track is hidden in a relevant context
	local mixer_vis = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
	local master_vis_flag = r.GetMasterTrackVisibility()
	local master_vis_TCP, master_vis_MCP = master_vis_flag&1 == 1, master_vis_flag&2 == 2

	local t = {trackfx = { main = {chain={}, float={}}, input = {chain={}, float={}} }, takefx = { chain={}, float={} } }
		for i = -1, r.CountTracks(0)-1 do -- i -1 to account for the Master track
		local vis_t = {} -- to be used in closing fx windows included in the incoming screenset when RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS setting is enabled
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		local tr_GUID = r.GetTrackGUID(tr) -- Master track also has GUID
			for i = 0, r.TrackFX_GetCount(tr)-1 do
			local chain = r.TrackFX_GetOpen(tr, i)
			local float = r.TrackFX_GetFloatingWindow(tr, i)
				if chain and not float then -- chain cond. must be limited by not float because TrackFX_GetOpen() returns true in both cases
				local len = #t.trackfx.main.chain
				t.trackfx.main.chain[len+1] = tr_GUID -- GUIDs are used since they will be stored as ext state for which object pointer storage is inconvenient, using indexed table to be able to easily concatenate list of GUIDs when storing
				vis_t[#vis_t+1] = i
				elseif float then
				local fx_GUID = r.TrackFX_GetFXGUID(tr, i)
				local len = #t.trackfx.main.float
				t.trackfx.main.float[len+1] = fx_GUID
				vis_t[#vis_t+1] = i
				end
			end
		local input_chain_stored
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			local i = i+0x1000000
			local chain = TrackFX_GetRecChainVisible2(tr) -- fx idx isn't needed here, only chain window status
			local float = r.TrackFX_GetFloatingWindow(tr, i)
				if chain and not float and not input_chain_stored then -- the function TrackFX_GetRecChainVisible2() returns true on each loop cycle because unlike the native TrackFX_GetOpen() it's not limited to the fx whose UI is visible in the chain, therefore the condition's truthfulness must be limited to 1 time only so superfluous table entries aren't added
				local len = #t.trackfx.input.chain
				t.trackfx.input.chain[len+1] = tr_GUID
				input_chain_stored = true
				vis_t[#vis_t+1] = i
				elseif float then
				local fx_GUID = r.TrackFX_GetFXGUID(tr, i)
				local len = #t.trackfx.input.float
				t.trackfx.input.float[len+1] = fx_GUID
				vis_t[#vis_t+1] = i
				end
			end

		local is_master_tr = tr == r.GetMasterTrack(0)
		local hidden = RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and ( not mixer_vis and (is_master_tr and not master_vis_TCP or not r.IsTrackVisible(tr, false)) -- mixer false // invisible in the TCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true)
		or mixer_vis and (is_master_tr and not master_vis_MCP or not r.IsTrackVisible(tr, true)) ) -- mixer true // invisible in the MCP // IsTrackVisible DOESN'T APPLY TO MASTER TRACK, always returns true
		local locked = RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS and Track_Controls_Locked(tr)

			if hidden or locked then
				for _, idx in ipairs(vis_t) do -- close all track fx windows included in the incoming screenset if their track is hidden in the relevant context
				r.TrackFX_SetOpen(tr, idx, false) -- open false // close floating window if any
				r.TrackFX_SetOpen(tr, idx, false) -- open false // close fx chain
				end
			end

		end -- track loop end

		for i = 0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			for i = 0, r.CountTakes(item)-1 do
			local vis_t = {}
			local take = r.GetTake(item, i)
			local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
				for i = 0, r.TakeFX_GetCount(take)-1 do
				local chain = r.TakeFX_GetOpen(take, i)
				local float = r.TakeFX_GetFloatingWindow(take, i)
					if chain and not float then
					local len = #t.takefx.chain
					t.takefx.chain[len+1] = take_GUID
					vis_t[#vis_t+1] = i
					elseif float then
					local fx_GUID = r.TakeFX_GetFXGUID(take, i)
					local len = #t.takefx.float
					t.takefx.float[len+1] = fx_GUID
					vis_t[#vis_t+1] = i
					end
				end

				if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS then
				local tr = r.GetMediaItemTake_Track(take)
				local item = r.GetMediaItemTake_Item(take)
					if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS and
					( not mixer_vis and not r.IsTrackVisible(tr, false) -- mixer false // invisible in the TCP
					or mixer_vis and not r.IsTrackVisible(tr, true) ) -- mixer true // invisible in the MCP
					or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1
					then
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
			for fx_type, t in pairs(t.trackfx) do
				for wnd_type, t in pairs(t) do
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

	return t

	end -- recall cond end

end


function Re_Store_Windows_Props_By_Names(t) -- position of fx floating windows seem to be stored and are not affected by screenset change so essentially would not need storage here, but fx chain windows positions are
-- supports docked windows
-- https://forums.cockos.com/showthread.php?p=2538915
-- https://forum.cockos.com/showthread.php?t=249817
	if not t then
	local main_HWND = r.GetMainHwnd()
	local t = {}
		for k, name in pairs({'FX:','- Track','- Item','- Master','- Monitor'}) do
		local array = r.new_array({}, 1023)
		r.JS_Window_ArrayFind(name, false, array) -- exact false
		local array = array.table()
			for k, address in ipairs(array) do -- duplicate names with different hwnd may occur, such as FX chain windows, so the number of windows which satisfy the search may be greater than the number of visible windows
			local hwnd = r.JS_Window_HandleFromAddress(address)
				if r.JS_Window_IsVisible(hwnd) -- FX chain windows may happen to be visible even when closed, there're no fx and the object is hidden in Arrange, fx floating window are only visible when floating
				then
				local title = r.JS_Window_GetTitle(hwnd)
				local retval, lt, tp, rt, bt = r.JS_Window_GetRect(hwnd)
				local w, h = rt-lt, r.GetOS():match('OSX') and tp-bt or bt-tp -- isn't necessary if r.JS_Window_Move() is used for restoration rather than r.JS_Window_SetPosition()
				t[#t+1] = {tit=title, lt=lt, tp=tp, w=w, h=h, foregrnd=r.JS_Window_GetForeground()==hwnd}
				end
			end
		end
	return t
	else
		for _, wnd in ipairs(t) do
		local hwnd = r.JS_Window_Find(wnd.tit, true) -- exact true
		-- when switching to a screenset with an open docker a window may get attached to it even without being included in the screenset at all whether docked or non-docked, docked fx windows included in the incoming screenset are filtered out from the table by Exclude_Screenset_Embedded_Visible_Windows(), if after that any fx window ends up being docked it must be made floating
		local dock_idx, isFloatingDocker = r.DockIsChildOfDock(hwnd)
			if dock_idx > -1 then
			local child_hwnd = r.JS_Window_FindChild(hwnd, 'List1', true) -- exact true
			r.JS_Window_SetFocus(child_hwnd)
			ACT(41172) -- Dock/undock currently focused window
		--	r.DockWindowRemove(hwnd) -- removes and hides so unsuitable
			end
		r.JS_Window_Move(hwnd, wnd.lt, wnd.tp) -- restore position
	--  OR
	--	r.JS_Window_SetPosition(hwnd, wnd.lt, wnd.tp, wnd.w, wnd.h) -- ZOrder, flags are omitted
			if wnd.foregrnd then r.JS_Window_SetForeground(hwnd) end -- only restored if the script is run via a shortcut because clicking changes foreground window, r.JS_Window_SetZOrder() should be avoided as it's global to the OS
		end
	end
end


function RESTORE()
	if next(fx_t) and r.time_precise() - time >= LOAD_TIME_MS -- wait allowing the screenset to load // usually takes longer here but still doesn't fall through, 1 ms does
	then
		if RESPECT_TRACK_VISIBILITY_FOR_SCREENSET_WINDOWS
		or RESPECT_OBJECT_LOCKED_STATUS_FOR_SCREENSET_WINDOWS
		or DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS then
		Store_Recall_ScreensetEmbedded_FX_Windows() -- store, recall is nil // optionally prevent restoration of screenset embedded fx windows after the screenset change and/or close them if their source track is hidden in the relevant context
		end
	Exclude_Screenset_Embedded_Visible_Windows(wnd_t) -- supposed to run immediately after screenset change and before fx windows visibility restoration to detect any windows which load with the incoming screenset to prevent restoring their position and affecting their screenset stored position
	Re_Store_FX_Windows_Visibility(fx_t)
		if js_ReaScriptAPI then
		Re_Store_Windows_Props_By_Names(wnd_t)
		-- restore take names
			for take, take_name in pairs(take_name_t) do
			r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', take_name, true) -- setNewValue true
			end
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
js_ReaScriptAPI = r.APIExists('JS_Window_Find')

r.PreventUIRefresh(1)

fx_t, take_name_t = Re_Store_FX_Windows_Visibility() -- store
wnd_t = js_ReaScriptAPI and Re_Store_Windows_Props_By_Names() -- store // must come after Re_Store_FX_Windows_Visibility because in it take names are changed which is necessary for getting unique windows data
last_screenset_wnds = DO_NOT_RESTORE_LAST_SCREENSET_WINDOWS and Store_Recall_ScreensetEmbedded_FX_Windows(true) -- recall true // recall from extended state stored with Store_Recall_ScreensetEmbedded_FX_Windows() when the screenset was just loaded; not 100% failproof because the screenset can be changed in-between switching to another one and its new window content won't be reflected in the stored data
time = r.time_precise()


RESTORE()


r.PreventUIRefresh(-1)






