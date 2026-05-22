--[[
ReaScript name: BuyOne_Lock track order.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: js_ReaScriptAPI not required but may be useful
Provides: [main=main,midi_editor] .
About: 	To do its thing the script must run in
		the background. Once launched it will
		continue to run until explicitly stopped
		by a direct click on its entry in the 
		Action list, in the list of running 
		scripts in the Actions menu, on a toolbar
		button or a menu item its linked to.

		As long as the script runs it prevents 
		changes to the track order in the TCP,
		and in MCP as well unless the option
		'Auto-arrange track in Mixer' is disabled,
		but it allows adding new tracks after
		which their position gets locked by the
		script.

		If the script is linked to a toolbar
		button or a menu item they will be lit
		or checkmarked respectively, while the
		script runs.

		Pinned tracks maintain their position
		in the general tracklist which is restored
		once unpinned.

		The only drawback of the script activity
		is that it MUST create an undo point 
		every time it restores the original track 
		order. This is the ReaScript API requirement 
		which there's no way around.

		See USER SETTINGS for a way of allowing
		certain tracks to be moved to another 
		position within the tracklist despite 
		the script locking activity.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert any alphanumeric character between the quotes
-- to disallow changing tracks state within folders by
-- using TCP buttons or - if js_ReaScriptAPI extension 
-- is not intalled - by dragging without changing track
-- position in the tracklist which is possible when the 
-- tracklist ends with a folder and parent tracks of subfolders 
-- inside this folder or its very last track are dragged down;
-- if disabled, tracks can be freely included in or
-- excluded from folders, but only by manipulating folder
-- status buttons in the TCP, not by track movement unless,
-- as mentioned above, js_ReaScriptAPI extension 
-- is not intalled and the dragged track is a parent track 
-- of a subfolder inside a folder which ends the tracklist
-- or its very last track;
-- if js_ReaScriptAPI extension IS installed track state 
-- within folder won't be allowed to change by dragging 
-- by default without this setting being enabled, it will only 
-- prevent its change via TCP buttons;
-- to allow movement of certain tracks see the next setting
LOCK_TRACK_STATE_WITHIN_FOLDER = ""


-- Insert any alphanumeric character between the quotes
-- to disallow unpinning of pinned tracks by dragging;
-- if js_ReaScriptAPI extension isn't installed unpinning
-- via track settings will be disallowed as well
LOCK_PINNED_TRACKS = ""


-- Within the quotes insert a character, a word, or a phrase
-- to serve as an unlock tag for a track;
-- movement of tracks whose label starts with this tag 
-- as well as other tracks moved along with them 
-- within the tracklist will be allowed by the script;
-- tagged folder parent tracks will be moved along with their
-- children tracks
UNLOCK_TAG = "$"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end



local r = reaper


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end



function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end



function re_store_sel_trks(t)
-- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = r.CountSelectedTracks(0)
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do -- not >= 0 because sel_trk_cnt is not reduced by 1, i-1 is on the next line
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- selected 0 or false // unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t
	then
	r.PreventUIRefresh(1)
--	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	-- deselect all tracks, this ensures that if none was selected originally
	-- none will end up selected because re-selection loop below won't start
	local master = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master) -- select master
	r.SetTrackSelected(master, false) -- selected false, immediately deselect
		for _,v in next, t do
		r.SetTrackSelected(v,true) -- selected true
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
	end
end



function Store_Update_Reference_Track_Order(tracks_t, change)
local tr_cnt = r.CountTracks(0)
	if not tracks_t or #tracks_t == 0 or tr_cnt ~= #tracks_t or change == 2 then
	local tracks_t = {ptrs={}}
		for i=0, tr_cnt-1 do
		local tr = r.GetTrack(0,i)
		local depth = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH')
		local pinned = r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN')
		local parent = r.GetParentTrack(tr)
		table.insert(tracks_t, {tr=tr, parent=parent, depth=depth, pinned=pinned}) -- parent track is stored only as boolean value to indicate whether the track is a child inside a folder // indexed array will be used for order restoration in Order_Tracks_In_TCP_By_Reference_Order()
		tracks_t.ptrs[tr] = {idx=i, parent=parent, depth=depth, pinned=pinned} -- store in associative array as well to simplify evaluation inside Track_Order_Changed()
		end
	return tracks_t
	end
end


function mouse_cursor_moved(x, y) -- EXPERIMENT
local a, b = r.GetMousePosition()
return x and a ~= x or y and b ~= y
end


function track_likely_dragged()

	if not r.JS_Mouse_GetState then return end

local LMB = r.JS_Mouse_GetState(1) -- LMB press
local tr, info = r.GetTrackFromPoint(r.GetMousePosition())
tr = tr and info < 1 and tr -- not envelope or FX chain
local sel = tr and r.IsTrackSelected(tr) -- a dragged track is always selected

	if LMB == 1 and sel then
	x, y = r.GetMousePosition()
	end

	if y and LMB == 0 then
	local x, Y = r.GetMousePosition()
	local dragged = Y ~= y
	x, y = nil -- reset
	return dragged
	end

end


local x, y

function Track_Order_Changed(tracks_t)

local change
-- when LOCK_TRACK_STATE_WITHIN_FOLDER is enabled, track folder role
-- can be changed without it being selected therefore monitor
-- all tracks, otherwise only selected because tracks dragged
-- to another position are necessarily selected
local Count = LOCK_TRACK_STATE_WITHIN_FOLDER and r.CountTracks(0) or r.CountSelectedTracks(0)
local Get = LOCK_TRACK_STATE_WITHIN_FOLDER and r.GetTrack or r.GetSelectedTrack
local dragged = track_likely_dragged()

	if tracks_t and #tracks_t > 0 and r.GetNumTracks() == #tracks_t then -- only when track count is the same, which allows adding new tracks without triggering order restoration
		-- loop over selected tracks because dragged tracks
		-- are necessarily selected
		for i=0, Count-1 do
		local tr = Get(0,i)
		local tr_idx = r.CSurf_TrackToID(tr, false)-1 -- mcpView false
	-- OR
	-- local tr_idx = r.GetMediaTrackInfo_Value(ref_tr, 'IP_TRACKNUMBER')-1 -- returns 1-based index
		local depth = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH')
		local pinned = r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN')
		local parent = r.GetParentTrack(tr)
			if tracks_t.ptrs[tr] and (tr_idx ~= tracks_t.ptrs[tr].idx
			or parent ~= tracks_t.ptrs[tr].parent or depth ~= tracks_t.ptrs[tr].depth
			or dragged and pinned ~= tracks_t.ptrs[tr].pinned)
			then
			change = 1 -- to trigger restoration
			local ret, name = r.GetTrackName(tr)
			-- trigger update with the changed props, i.e. position and folder role
			-- if label of at least one of the selected, i.e. dragged, tracks includes unlock tag,
			-- or folder role has changed via TCP buttons, not by movement (except in cases mentioned below),
			-- while LOCK_TRACK_STATE_WITHIN_FOLDER is disabled;
			-- tracks can be dragged out of folders and have their folder role changed
			-- without change in their position in the tracklist
			-- provided they're the very last track which is folder child or parent of the very last subfolder
			-- at its depth in the tracklist, so this won't be prevented unless
			-- LOCK_TRACK_STATE_WITHIN_FOLDER is enabled OR js_ReaScriptAPI extension is installed
				if name:match('^%s*'..UNLOCK_TAG)
				or not LOCK_TRACK_STATE_WITHIN_FOLDER and tr_idx == tracks_t.ptrs[tr].idx
				and (parent ~= tracks_t.ptrs[tr].parent or depth ~= tracks_t.ptrs[tr].depth)
				and not dragged
				or not LOCK_PINNED_TRACKS and pinned ~= tracks_t.ptrs[tr].pinned
				then change = 2
				break end
			break end
		end
	end

return change

end


function Order_Tracks_In_TCP_By_Reference_Order(tracks_t)
-- tracks_t contains reference order

local sel_tr = re_store_sel_trks()

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local ref_tr = tracks_t[#tracks_t].tr -- very last track of the stored order

-- move last track to the top to restore
-- the order of all tracks relative to it,
-- this along with restoring parent child relationship
-- within the loop seems to ensure that folder structure
-- is restored along with the track order after tracks
-- are dragged into or out of folders
local parent = tracks_t[#tracks_t].parent
r.SetOnlyTrackSelected(ref_tr)
r.ReorderSelectedTracks(0, parent and 1 or 0)
r.SetMediaTrackInfo_Value(ref_tr, 'B_TCPPIN', tracks_t[#tracks_t].pinned)

local ref_tr_idx = r.CSurf_TrackToID(ref_tr, false)-1 -- mcpView false
-- OR
-- local ref_tr_idx = r.GetMediaTrackInfo_Value(ref_tr, 'IP_TRACKNUMBER')-1 -- returns 1-based index

	for k, props in ipairs(tracks_t) do
	local tr, parent, depth, pinned = props.tr, props.parent, props.depth, props.pinned
	local idx = r.CSurf_TrackToID(tr, false)-1 -- mcpView false

		if tr ~= ref_tr then

		r.SetMediaTrackInfo_Value(tr, 'B_TCPPIN', pinned)

		r.SetOnlyTrackSelected(tr)

		-- this only restores parent-child relationship when child
		-- immediately follows the parent, the rest are restored
		-- in the additional loop following this one
		local makePrevFolder = prev_tr and parent == prev_tr and 1 or 0
		r.ReorderSelectedTracks(ref_tr_idx, makePrevFolder)

		r.SetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH', depth)

		-- only increment if track index was greater that the ref_track index
		-- because after movin the track before the ref_track the index of the latter will increase
		ref_tr_idx = idx < ref_tr_idx and ref_tr_idx or ref_tr_idx+1

		end

	end

	-- restore parent-child relationship after reordering
	-- because it's likely to break and not be fully restored in the preceding loop
	for k, props in ipairs(tracks_t) do
	r.SetMediaTrackInfo_Value(props.tr, 'I_FOLDERDEPTH', props.depth)
	end

r.TrackList_AdjustWindows(true) -- isMinor true, TCP only
re_store_sel_trks(sel_tr)
r.PreventUIRefresh(-1)
r.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view // in case after order restoration the dragged track goes out of view
r.Undo_EndBlock('Restore tracks order in TCP',-1)

end



function MAINTAIN_ORDER()

local change = Track_Order_Changed(tracks_t) -- returns 1 if change in non-tagged tracks to trigger Order_Tracks_In_TCP_By_Reference_Order() and 2 if change in tagged tracks (including any additional selected tracks) to trigger Store_Update_Reference_Track_Order()

-- the routines must be separated, otherwise
-- Track_Order_Changed() and Store_Update_Reference_Track_Order()
-- continue to run concurrently with Order_Tracks_In_TCP_By_Reference_Order()
-- which sets off an endless reorder loop
	if tracks_t and change == 1 then
	Order_Tracks_In_TCP_By_Reference_Order(tracks_t)
	else
	tracks_t = Store_Update_Reference_Track_Order(tracks_t, change) or tracks_t
	end

r.defer(MAINTAIN_ORDER)

end


	if r.set_action_options then r.set_action_options(1) end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

UNLOCK_TAG = Esc(UNLOCK_TAG)
LOCK_TRACK_STATE_WITHIN_FOLDER = LOCK_TRACK_STATE_WITHIN_FOLDER:match('%S')
LOCK_PINNED_TRACKS = LOCK_PINNED_TRACKS:match('%S')

MAINTAIN_ORDER()

r.atexit(function() Re_Set_Toggle_State(sect_ID, cmd_ID, 0) end)



