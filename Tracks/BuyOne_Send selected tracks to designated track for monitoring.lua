--[[
ReaScript name: BuyOne_Send selected tracks to designated track for monitoring.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Added a USER SETTING to include in the routing to the designated track
	  send destination tracks of the selected tracks along their entire send tree.
	  #Added SEND_MODE setting.
	  #Done away with 'ReaScript task control' dialogue when the script is re-launched
	  while already running in AUTO mode. Relevant for users of REAPER 7.03+
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About:	The script creates sends from selected tracks 
	to the designated track whose name is specified
	in the MONITOR_TRACK_NAME setting in the USER SETTINGS
	below.
	
	It's designed to mimic the 'Current track' feature of
	FL Studio: https://www.youtube.com/watch?v=0zcZum7BPeM, quote
	"The specially named 'Current' track can only receive audio 
	from the currently selected track. Its main purpose is to 
	hold an Edison plugin, ready to record any selected tracks 
	audio OR visualization plugins, such as WaveCandy"
	(https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/mixer_iorouting.htm)
	
	Needless to say that it can also be used for monitoring
	purposes housing analyzers and such.
	
	In the case of this script however all selected tracks are 
	routed to the designated track.
	
	The Master send on the designated track is disabled to prevent
	duplication of the signal on the Master track.
	
	Receives from selected tracks on the designated track are 
	mutually exclusive, any current receive whose source track 
	isn't selected is automatically removed, unless no track or
	only the designated track is selected in which case receives
	remain intact. Sends from tracks already routed to the designated
	track aren't duplicated in case the same track is featured 
	in different track selections.
	
	The script can be executed in manual and auto modes. In manual
	mode to make it perform operations described above it much be 
	run each time new track selection has to be sent to the designated
	track. If AUTO setting is enabled in the USER SETTINGS the script
	will run in the background and automatically send any selected 
	track to the designated track.  
	
	When the script runs in AUTO mode toolbar button or menu item 
	it's linked to are lit or checkmarked respectively.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Specify the name of the designated track
-- to be used for monitoring;
-- the match between this setting and
-- the actual name of the designated track in the project
-- must be exact disregarding leading and trailing spaces
MONITOR_TRACK_NAME = "Current"

-- Between the quotes insert number corresponding
-- to the send mode:
-- 1 - Post-Fader (Post-Pan)
-- 2 - Pre-Fader (Post-FX)
-- 3 - Pre-Fader (Pre-FX)
-- if the setting is empty or invalid defaults to 1 - Post-Fader (Post-Pan)
SEND_MODE = ""

-- Insert any alphanumeric character between the quotes
-- to enable routing to the designated track track send
-- destination tracks along the entire send tree which starts
-- with selected tracks
-- RULES:
-- 1. All send destination tracks along the entire send tree
-- which starts with selected tracks
-- (hereinafter 'send destination tracks') are routed to the
-- designated track.
-- 2. Send destination tracks whose Master/Parent send AKA
-- Master send (depending on REAPER build) is disabled aren't
-- routed to the designated track.
-- 3. Send destination tracks of child tracks in a folder whose
-- parent track is routed to the designated track are also
-- routed to the designated track.
ROUTE_SEND_DESTINATION_TRACKS = ""

-- To enable, insert any alphanumeric
-- character between the quotes
AUTO = ""

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


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function Get_Designated_Track(tr, MONITOR_TRACK_NAME)
local tr_name = tr and r.GetTrackState(tr)
	if tr and tr_name:match('[%w%p]*[%w%p]') == MONITOR_TRACK_NAME
	then return tr
	else
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local tr_name = r.GetTrackState(tr)
			if tr_name:match('[%w%p]*[%w%p]') == MONITOR_TRACK_NAME -- trimming any leading and trailing spaces and accounting for 1 character name
			then return tr
			end
		end
	end
end


function Track_Selection_Changed(t)
local sel_tr_cnt = r.CountSelectedTracks(0)
	if sel_tr_cnt > 0 and t then -- if no selected, everything remains the same
		if sel_tr_cnt ~= #t then return true -- count has changes
		else
			for _, tr_idx in ipairs(t) do
			local tr = r.GetTrack(0,tr_idx-1) -- -1 since in the passed table they're stored in 1-based count
				if not r.IsTrackSelected(tr) then
				return true end -- track selection has changed
			end
		end
	elseif
	-- takes care of cases when the script was launched in AUTO mode
	-- without tracks or a designated track in a project
	sel_tr_cnt > 0 then return true
	end
end


function Remove_Track_Receives(tr)
-- single loop isn't enough, if more than 2 receives
-- after the loop GetTrackNumSends() still returns a number greater than 0
-- probably due to sluggish update
-- the result is duplcation of send from the some tracks
-- since original send couldn't be deleted fast enough, before another one was created
	for i=0, r.GetTrackNumSends(tr, -1)-1 do -- category -1 receives
	r.RemoveTrackSend(tr, -1, i) -- category -1 receives
	end
	if r.GetTrackNumSends(tr, -1) > 0 then
	Remove_Track_Receives(tr)
	end
end


function get_track_parents(parent)
	return function()
	parent = r.GetParentTrack(parent) -- assigning to a global value (or upvalue passed as the argument) is crucial to make it work so that the var is constantly updated during the loop, returning r.GetParentTrack(parent) directly won't work because the var isn't updated, the var won't be accessible outside of the loop
	return parent
	end
end

function Is_Track_Parent_Included(tr, t)
	for parent in get_track_parents(tr) do
		if t[parent] and
		r.GetMediaTrackInfo_Value(parent, 'B_MAINSEND') == 1
		then
		return true end
	end
end


function get_track_children_and_grandchildren(tr)
local st_idx = r.CSurf_TrackToID(tr, false) -- mcpView false // starting loop from the 1st child
local depth = r.GetTrackDepth(tr)
return function()
	local chld_tr = r.GetTrack(0,st_idx)
		if chld_tr and r.GetTrackDepth(chld_tr) > depth then
		st_idx=st_idx+1
		return chld_tr
		end
	end
end


function Collect_Tracks(t, fin)

	local function collect_send_dest_tracks(i, t, tr)
	local snd_cnt = r.GetTrackNumSends(tr, 0) -- category 0 sends
		if snd_cnt > 0 then
			for snd_idx=0, snd_cnt-1 do
			local dest_tr = r.GetTrackSendInfo_Value(tr, 0, snd_idx, 'P_DESTTRACK') -- category 0 send
				if not t[dest_tr] then -- if it's not one of the selected or stored inside the recursive loop
				t[#t+1] = dest_tr
				t[dest_tr] = '' -- dummy value // store to be able to evaluate whether the track has already been stored without having to search for it in the entire table
				end
			end
		t = Collect_Tracks(t,i+1) -- go recursive collecting the entire send tree, fin arg is i+1 to stop where the main loop inside Collect_Tracks() left off for efficiency because the table length may increase and running full table loop is likely to cause endless recursive loop because the same sends will be detected over and over in tracks which have already been processed in higher lever recursive loops
		end
	return t
	end

local fin = fin or 1

	for i=#t,fin,-1 do -- in reverse because of removal of irrelevant tracks
	local tr = t[i]
		if r.GetMediaTrackInfo_Value(tr, 'B_MAINSEND') == 0 -- isn't routed to Master
		or Is_Track_Parent_Included(tr, t) -- a parent of a child track has already been stored and has its Master/parent send enabled so no need to store and route the child track as well
		then
		table.remove(t,i)
		t[tr] = false
		end

		if ROUTE_SEND_DESTINATION_TRACKS then

		-- Get destinaton tracks of the track and its children (if any) sends

		if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and t[tr] then -- current track is a folder or subfolder parent track and hasn't been deleted above so is going to be routed to the designated track while its children won't so their send desitnation tracks must be included in the routing
			for child in get_track_children_and_grandchildren(tr) do
			t = collect_send_dest_tracks(i, t, child) -- passing table index of the current track as i argument because the child track is not stored and passing its index would be wrong because it would refer to a completely different track in the table
			end
		end
		t = collect_send_dest_tracks(i, t, tr)
		end

	end

return t

end


function Create_Sends_From_Sel_Tracks(mon_tr, send_mode)
	if mon_tr then
		if r.GetMediaTrackInfo_Value(mon_tr, 'B_MAINSEND') == 1 then
		r.SetMediaTrackInfo_Value(mon_tr, 'B_MAINSEND', 0) -- disable master/parent send just in case it isn't
		end
		-- clear current recieves
		if not (r.CountSelectedTracks(0,0) == 1 and r.IsTrackSelected(mon_tr)) then
		-- the condition prevents receives removal when in AUDO mode
		-- the designated track is the only one selected
		Remove_Track_Receives(mon_tr)
		end
	local tr_numbers = {} -- to be used in the undo point description and in Track_Selection_Changed() function
	local tr_t = {} -- collect tracks to send to the designated track

		for i=0, r.CountTracks(0)-1 do -- counting all tracks instead of selected to be able to get actual indices for storage in the table
		local tr = r.GetTrack(0,i)
			if r.IsTrackSelected(tr) then
			tr_numbers[#tr_numbers+1] = i+1
			-- Collect selected tracks
				if not tr_t[tr] then -- prevent adding and processing selected tracks which were already added and processed in previous loop cycles as send destination tracks of other tracks in case ROUTE_SEND_DESTINATION_TRACKS is enabled // will also be valid before any track was added and when ROUTE_SEND_DESTINATION_TRACKS is disabled, so covers all cases
				tr_t[#tr_t+1] = tr
					if ROUTE_SEND_DESTINATION_TRACKS then -- collect selected tracks send destination tracks along the enire send tree
					tr_t[tr] = '' -- dummy value
					tr_t = Collect_Tracks(tr_t, fin)
					end
				end
			end
		end

	--[[-- OR
			-- First collect all selected tracks
			for i=0, r.CountTracks(0)-1 do -- counting all tracks instead of selected to be able to get actual indices for storage in the table
			local tr = r.GetTrack(0,i)
				if r.IsTrackSelected(tr) then
				tr_numbers[#tr_numbers+1] = i+1
				tr_t[#tr_t+1] = tr
				tr_t[tr] = '' -- dummy value
				end
			end

			-- Collect selected tracks send destination tracks along the enire send tree
			if ROUTE_SEND_DESTINATION_TRACKS then
			tr_t = Collect_Tracks(tr_t, fin)
			end
	]]

		for k, tr in ipairs(tr_t) do -- create sends from the stored tracks to the esignated track
		r.CreateTrackSend(tr, mon_tr)
		end

		-- disable MIDI sends https://forum.cockos.com/showthread.php?t=287218
		for i=0, r.GetTrackNumSends(mon_tr, -1)-1 do -- category -1 receives
		r.SetTrackSendInfo_Value(mon_tr, -1, i, 'I_MIDIFLAGS', 31) -- category -1 receives
			if send_mode ~= 0 then -- by default send mode is Post-Fader (Post-Pan), i.e. 0
			r.SetTrackSendInfo_Value(mon_tr, -1, i, 'I_SENDMODE', send_mode) -- category -1 receives
			end
		end
	return tr_numbers, tr_t
	end
end


function RUN()

	if Track_Selection_Changed(tr_numbers) then
	mon_tr = Get_Designated_Track(mon_tr, MONITOR_TRACK_NAME)
	tr_numbers = Create_Sends_From_Sel_Tracks(mon_tr, send_mode)
	end

r.defer(RUN)

end


MONITOR_TRACK_NAME = MONITOR_TRACK_NAME:match('[%w%p]*[%w%p]') -- trimming any leading and trailing spaces and accounting for 1 character name
AUTO = #AUTO:gsub(' ','') > 0

local err = not r.GetTrack(0,0) and 'no tracks in the project'
or not r.GetTrack(0,1) and '\tthere\'s only 1 \n\n track in the project'
or not r.GetSelectedTrack(0,0) and 'no selected tracks'
or #MONITOR_TRACK_NAME:gsub(' ','') == 0 and 'designated track name is not set'

	if err and not AUTO then -- only in manual mode
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

mon_tr = Get_Designated_Track(tr, MONITOR_TRACK_NAME)

err = not mon_tr and '    the designated monitor \n\n track "'..MONITOR_TRACK_NAME..'" wasn\'t found'
or r.IsTrackSelected(mon_tr) and not r.GetSelectedTrack(0,1) and 'the designated monitor track \n\n     is the only one selected'

	if err and not AUTO then -- only in manual mode
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()

	if not AUTO then
	r.Undo_BeginBlock()
	end


ROUTE_SEND_DESTINATION_TRACKS = #ROUTE_SEND_DESTINATION_TRACKS:gsub(' ','') > 0
local send_modes_t = {['1'] = 0, ['2'] = 3, ['3'] = 1}
send_mode = send_modes_t[SEND_MODE] or 0 -- global to accommodate AUTO mode

local tr_numbers, tr_t = Create_Sends_From_Sel_Tracks(mon_tr, send_mode)
local snd_dest_trks = ROUTE_SEND_DESTINATION_TRACKS and #tr_t > #tr_numbers and ' and their send tree' or ''

	if not AUTO then
	r.Undo_EndBlock('Send tracks '..table.concat(tr_numbers, ', ')..snd_dest_trks..'  to designated monitor track',-1)
	else
		-- prevent ReaScript task control dialogue when the running script is clicked again to be terminated,
		-- supported since build 7.03
		-- script flag for auto-relaunching after termination in reaper-kb.ini is 4, e.g. SCR 4, but if changed
		-- directly while REAPER is running the change doesn't take effect, so in builds older than 7.03 user input is required
		if r.set_action_options then r.set_action_options(1) end	
	Re_Set_Toggle_State(sect_ID, cmd_ID, 1)
	RUN()
	end

	if AUTO then
	r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0)) -- for defer scripts
	end





