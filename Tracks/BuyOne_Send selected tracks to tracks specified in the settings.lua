--[[
ReaScript name: BuyOne_Send selected tracks to tracks specified in the settings.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 	#Added protection against creation of sends if sends with the same
		source and destination channels already exist
		#Added a USER SETTING to include in the routing to the destination tracks
		send destination tracks of the selected tracks along their entire send tree
		#Improved error messages
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script is a derivative of 
	BuyOne_Insert new track automatically sending it to tracks specified in the settings.lua
	meant to be used within custom actions because it only performs one task - send creation.
	
	For example custom actions to create new tracks and send them to a certain other track
	would look like so:
	
		Track: Insert new track
		BuyOne_Send selected tracks to tracks specified in the settings.lua
	
	OR
	
		Track: Insert multiple new tracks...
		BuyOne_Send selected tracks to tracks specified in the settings.lua
	
	OR
	
		Track: Insert new track
		BuyOne_Send selected tracks to tracks specified in the settings.lua
		Track: Insert new track
		BuyOne_Send selected tracks to tracks specified in the settings.lua
		Track: Insert new track
		BuyOne_Send selected tracks to tracks specified in the settings.lua
	
	The script file can be duplicated as many times as needed with each copy
	having different USER SETTINGS, such as the DESTINATION_TRACK_NAME,
	which will allow creating sends to multiple tracks named differently.
	
	See also
	BuyOne_Send selected tracks to designated track for monitoring.lua
	
	
	Configure USER SETTINGS

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the double square brackets insert names
-- of the destination tracks, one line per track name
DESTINATION_TRACK_NAMES = [[

]] -- keep on a separate line

-- Between the quotes insert the number corresponding to the send mode:
-- 1 - post-fader (post-pan), 2 - pre-fader (pre-fx), 3 - pre-fader (post-fx)
-- if not set or invalid, defaults to 1
SEND_MODE = ""


-- To enable the following settings insert any alphanumeric
-- character between the quotes

-- Enable to turn off the Master send of all tracks
-- routed to the destination tracks to prevent duplication of the signal;
-- be circumspect in using this setting, especially if
-- ROUTE_SEND_DESTINATION_TRACKS setting is enabled below because
-- it's easy to ruin the routing to the Master track of a whole
-- bunch of tracks in one go
DISABLE_MASTER_PARENT_SEND = ""

-- Enable to route to the destination tracks send
-- destination tracks along the entire send tree which
-- starts with selected tracks
-- RULES:
-- 1. All send destination tracks along the entire send tree
-- which starts with selected tracks
-- (hereinafter 'send destination tracks') are routed to the
-- destination tracks.
-- 2. Send destination tracks whose Master/Parent send AKA
-- Master send (depending on REAPER build) is disabled aren't
-- routed to the destination tracks.
-- 3. Send destination tracks of child tracks in a folder whose
-- parent track is routed to the destination tracks are also
-- routed to the destination tracks.
-- the setting won't allow routing destination tracks 
-- to each other when they're the only ones selected
ROUTE_SEND_DESTINATION_TRACKS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of caption and value
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local cap, val = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end


local r = reaper

function no_undo()
do return end
end

function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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
		if --r.GetTrackDepth(tr) == 0 and -- top level track
		r.GetMediaTrackInfo_Value(tr, 'B_MAINSEND') == 0 -- isn't routed to Master
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



function Audio_Send_Exists(snd_type, src_tr, dest_tr, send_mode, snd_src_ch, snd_src_ch_mode, snd_dest_ch, snd_dest_ch_mode, loopback_mode)
-- snd_type < 0 receves, 0 track sends, > 0 hardware sends
-- if snd_type > 0 (hw outputs), dest_tr arg is irrelevant;
-- snd_dest_ch_mode arg must be valid only if evaluating mono routing at the destination (integer 1)
-- in all other cases it's identical to snd_src_ch_mode;
-- channel modes, i.e. snd_src_ch_mode and snd_dest_ch_mode: 0 - stereo, 1 mono, 2 - 4 channels, 3 - 6 channels etc.
-- 0-based channel index: when the mode is mono it's straghtforward
-- in stereo mode index is left channel, index+1 is right channel
-- in multichan mode index is the first channel, index-1+mode*2 is last channel
-- snd_src_ch and snd_dest_ch args are 0-based channel indices,
-- for stereo routing only the left channel index
-- for multichannel routing only the lowest channel index;
-- loopback_mode arg is optional, 1 if evaluating rearoute loopback output channels
-- officially supported since REAPER v7, whose count starts from 0-based index of 512,
-- or 2 if evaluating rearoute loopback channels supported unofficially
-- in earlier builds via reaper.ini rearoute_loopback= key, since 6.69 supports 512 channels,
-- whose count starts at 0-based index of 768 IF BOTH TYPES ARE ENABLED,
-- alternatively, to address rearoute outputs enabled via reaper.ini
-- loopback_mode 1 could be used but snd_dest_ch index must start from 256,
-- i.e. 256 - 0, 257 - 1 etc.,
-- only applies to snd_dest_ch arg,
-- if loopback_mode arg is supplied snd_dest_ch index
-- args doesn't need adjustment, value 0 will be mapped to 512 for loopback_mode 1
-- or to 768 for loopback_mode 2, etc.


	local function is_ch_within_range(input_ch_idx, input_ch_mode, ch_idx, ch_mode)
	-- looking if a channel is already present in a send/receive
	-- input_ch_idx is a channel index which is evaluated
	-- ch_idx, ch_mode are props of the send/receive against which input_ch_idx is evaluated
	local key = function(ch_mode) return ch_mode > 1 and -1 or ch_mode end -- creating universal table key for all multichannel mode values for noth input and evaluated mode args
	local hi_t = {[0]=function(ch_idx)return ch_idx+1 end,[1]=function(ch_idx)return ch_idx end,
	[-1]=function(ch_idx,ch_mode)return ch_idx-1+ch_mode*2 end} -- using functions to be able to use the table for both types of arguments
	return input_ch_idx and input_ch_idx >= ch_idx -- lower channel in the range
	and hi_t[key(input_ch_mode)](input_ch_idx, input_ch_mode) <= hi_t[key(ch_mode)](ch_idx, ch_mode) -- upper channel in the range
	end

local snd_dest_ch_mode = snd_dest_ch_mode and 1 or snd_src_ch_mode -- if not explicitly provided, to signify mono routing (integer 1) use snd_src_ch_mode as required by REAPER design
local snd_dest_ch =  snd_dest_ch + (loopback_mode == 1 and 512 or loopback_mode == 2 and 768 or 0)
local SendInfo = r.GetTrackSendInfo_Value

	for i=0, r.GetTrackNumSends(src_tr, snd_type)-1 do
		if SendInfo(src_tr, 0, i, 'P_DESTTRACK') == dest_tr or snd_type > 0 then -- send to the dest_tr already exists or hardware output
		-- Evaluate properties, whether identical
--		local send_mode_cur = SendInfo(src_tr, snd_type, i, 'I_SENDMODE') -- irrelevant
		local bitfield = SendInfo(src_tr, snd_type, i, 'I_SRCCHAN')
		local snd_src_ch_mode_cur = bitfield>>10&0x3ffff -- shifting heigher 10 bits, applying 10 bit mask
		local snd_src_ch_cur = bitfield&0x3ffff - snd_src_ch_mode_cur*1024 -- bit-masking lower 10 bits, 0-based ch index increases by 1024 with each mode hence the subtraction
		local bitfield = SendInfo(src_tr, snd_type, i, 'I_DSTCHAN')
	--[[ this only works for HW outputs
		local snd_dest_ch_mode_cur = bitfield>>10&0x3ffff
		local snd_dest_ch_cur = bitfield&0x3ffff - snd_dest_ch_mode_cur*1024
		]]
		local snd_dest_ch_mode_cur = bitfield&1024==1024 and 1 or snd_src_ch_mode_cur -- dest channel mode is always the same as the source's unless mono
		local snd_dest_ch_cur = snd_dest_ch_mode_cur == 1 and bitfield&0x3ffff-1024 or bitfield&0x3ffff -- subtracting 1024 if mono
			if is_ch_within_range(snd_src_ch, snd_src_ch_mode, snd_src_ch_cur, snd_src_ch_mode_cur)
			and is_ch_within_range(snd_dest_ch, snd_dest_ch_mode, snd_dest_ch_cur, snd_dest_ch_mode_cur)
			then return true -- if the evaluated src and dest channels both feature in any send routing, such send is considered existing, no point in duplicating the signal by creating another send featuring these channels
			end
		end
	end

end


local x, y = r.GetMousePosition()

	if #DESTINATION_TRACK_NAMES:gsub('[%s%c]','') == 0 then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACK NAMES \n\n      SETTING IS EMPTY'):gsub('.','%0 ')
	..' \n\n ', x, y, true) -- topmost true
	return r.defer(no_undo) end

-- add trailing line break in case the setting closing square brackets have been moved
-- to the line of the last track name, otherwise the last line won't be captured with the pattern
-- in the gmatch loop below
DESTINATION_TRACK_NAMES = not DESTINATION_TRACK_NAMES:match('.+\n%s*$') and DESTINATION_TRACK_NAMES..'\n'
or DESTINATION_TRACK_NAMES
-- OR DESTINATION_TRACK_NAMES:sub(-1) ~= '\n' and DESTINATION_TRACK_NAMES..'\n' or ...
-- OR not DESTINATION_TRACK_NAMES:match('\n$') and

local dest_tr_name_t = {}

		for name in DESTINATION_TRACK_NAMES:gmatch('(.-)\n') do
			if #name:gsub(' ','') > 0 then -- ignoring empty lines
			dest_tr_name_t[#dest_tr_name_t+1] = name
			end
		end

local dest_tr_t = {}

	for i=0,r.GetNumTracks()-1 do -- find the destination tracks
	local tr = r.GetTrack(0,i)
	local retval, tr_name = r.GetTrackName(tr)
		for _, name in ipairs(dest_tr_name_t) do
			if tr_name:match('^%s*'..Esc(name)..'%s*$') then -- accounting for leading & trailing spaces
			dest_tr_t[#dest_tr_t+1] = tr
			end
		end
	end

	if #dest_tr_t == 0 then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACKS WEREN\'T FOUND'):gsub('.','%0 ')
	..'\n\n ', x, y, true) -- topmost true
	return r.defer(no_undo)
	elseif #dest_tr_t > #dest_tr_name_t then
	local resp = r.MB('    SOME OR ALL DESTINATION TRACKS NAMES\n\n  HAVE BEEN FOUND IN MORE THAN ONE TRACK', 'PROMPT', 1)
		if resp == 2 then -- canceled
		return r.defer(no_undo) end
	end

SEND_MODE = tonumber(SEND_MODE) or 1 -- default to 1 (post-fader)
SEND_MODE = (SEND_MODE > 0 and SEND_MODE < 3) and SEND_MODE-1 or SEND_MODE > 3 and 1 or SEND_MODE -- -1 to conform to 0-based index of post-fader (0) and pre-fx (1), excluding illegal numbers
ROUTE_SEND_DESTINATION_TRACKS = #ROUTE_SEND_DESTINATION_TRACKS:gsub(' ','') > 0

r.Undo_BeginBlock()

local cntr, snd_src_trks_t = 0, {}

	for i=0, r.CountSelectedTracks(0)-1 do -- tracks inserted with action are always exclusively selected
	local tr = r.GetSelectedTrack(0,i)
	snd_src_trks_t[#snd_src_trks_t+1] = tr
		if ROUTE_SEND_DESTINATION_TRACKS then
		snd_src_trks_t[tr] = tr
		snd_src_trks_t = Collect_Tracks(snd_src_trks_t, fin)
		end
	end

	for k, tr in ipairs(snd_src_trks_t) do
	--	local snds_cnt = r.GetTrackNumSends(tr, 0) -- category 0 (send)
		for k, dest_tr in ipairs(dest_tr_t) do
			if tr ~= dest_tr -- tracks cannot be sent to themselves by default, but employing tr ~= dest_tr condition to prevent disabling master/parent send if a track was sent to itself and to condition an error message
			and (not ROUTE_SEND_DESTINATION_TRACKS or not snd_src_trks_t[dest_tr]) -- preventing sending destination tracks to each other when ROUTE_SEND_DESTINATION_TRACKS is enabled and the script is applied again on the same set of tracks otherwise they will be sent to each other being retrieved via selected tracks sends tree, will also prevent sending destination tracks to each other when ROUTE_SEND_DESTINATION_TRACKS is enabled and they're the only ones selected, each can be added to others in turn
			and not Audio_Send_Exists(0, tr, dest_tr, SEND_MODE, 0, 0, 0, snd_dest_ch_mode, loopback_mode) -- snd_type 0, i.e. sends, snd_src_ch 0, i.e. 1 , snd_src_ch_mode 0, i.e. stereo, snd_dest_ch 0, i.e. 1, all because with CreateTrackSend() sends are created from 1/2 to 1/2 so these channels need evaluation, snd_dest_ch_mode is nil because for stereo/multichannel send it's the same as snd_src_ch_mode, loopback_mode is nil as irrelevant // preventing creation of sends with routing identical to that of existing sends
			then
			cntr = cntr+1
			r.CreateTrackSend(tr, dest_tr)
			r.SetTrackSendInfo_Value(tr, 0, r.GetTrackNumSends(tr, 0)-1, 'I_SENDMODE', SEND_MODE) -- category 0 (send), snds_cnt retrieved above before send creation works as sendidx arg as well, likely because the count is slow to update after send creation; -1 because send indices are 0-based, accounting for previosuly existing sends
				if #DISABLE_MASTER_PARENT_SEND:gsub(' ','') > 0
				and r.GetMediaTrackInfo_Value(tr, 'B_MAINSEND') == 1 then
				r.SetMediaTrackInfo_Value(tr, 'B_MAINSEND', 0)
				end
			end
		end
	end

local err = cntr == 0 and #dest_tr_t == 1 and r.GetSelectedTrack(0,0) == dest_tr_t[1] and '  TRACKS CANNOT BE \n\n SENT TO THEMSELVES' -- only possible if only 1 track is selected and it's the only destination as well, if at least two are selected and both are set to be destination tracks they will be sent to one another
or cntr == 0 and ' NO NEW SENDS WERE CREATED'

	if err then
	r.TrackCtl_SetToolTip('\n\n '..err:gsub('.','%0 ')..' \n\n ', x, y, true) -- topmost true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo)
	end

r.Undo_EndBlock('Send selected tracks to tracks '..table.concat(dest_tr_name_t, '; '), -1)




