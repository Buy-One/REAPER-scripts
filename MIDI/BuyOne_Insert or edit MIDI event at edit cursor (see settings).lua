--[[
ReaScript name: BuyOne_Insert or edit MIDI event at edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	▓ MIDI Channel handling (only applies to CC events)

	When 'All channels' option is enabled in the MIDI filter 
	the inserted CC event is assigned the last active MIDI channel
	which may not be obvious because you may not remember what it was.

	When 'Multichannel' option is enabled in the MIDI filter 
	the inserted CC event is assigned the first active MIDI channel, 
	which can be looked up in the MIDI filter dialogue 
	(action 'Filter: Show/hide filter window...' default shortcut is F).

	In all other cases the inserted event is assigned the MIDI channel 
	currently selected in the MIDI filter.

	▓ Event properties

	An event inserted in a lane with pre-existing events is assigned 
	properties of the event immediately preceding it on the time line 
	or of the first event in the lane if the edit cursor is placed ahead of it.

	An event inserted on an empty lane is assigned the value of 0.  
	To be able to assign such an event desired values enable 
	EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT setting in the USER SETTINGS.

	When the edit cursor position coincides with existing event position 
	no new event is inserted.  
	You can enable EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH setting so that 
	in such cases event properties dialogue is called.

	Notation events are not supported.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert any alphanumeric character
-- between the quotes.

-- Enable so the script can be used
-- then configure the settings below
--ENABLE_SCRIPT = "1"

-- Enable to always have event at the edit cursor selected;
-- when EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT and/or
-- EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH settings are enabled below
-- the very first event and existing events at the edit cursor
-- are selected regardless of this setting;
-- if this setting is enabled and the script is combined with action
-- 'Edit: Event properties' within a custom action, e.g.:
--------| BuyOne_Insert or edit MIDI event at edit curor.lua
--------| Edit: Event properties
-- you can also have event properties dialogue be called as long as
-- there's a CC event at the edit cursor whether new or old,
-- for this to work smoothly
-- EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT and
-- EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH settigs
-- must be disabled otherwise they will cause closure
-- of the event properties dialogue;
-- !!! this setup won't work well with text and sysex events
ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR = ""

-- When an event is inserted in an empty lane, being the 1st one,
-- its values default to 0,
-- enable this setting to evoke event properties dialogue
-- every time such event is inserted so you can set
-- the desired value manually;
-- !!! DOESN'T APPLY to first text and sysex events for which
-- an event properties dialogue is always called
EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT = "1"

-- Enable this setting if you wish to evoke event properties
-- dialogue when the edit cursor position matches an existing event position;
-- but regardless of this setting state in this case no event is inserted
EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH = "1"

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

function no_undo()
do return end
end

function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
--[[
-- a time loop can be added to run when certan condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


function Get_Currently_Active_Chan_And_Filter_State(obj, ME) -- via chunk, ME is MIDI Editor pointer
-- returns channel filter status and the channels currently selected in the filter regardless of its being enabled
-- for a single active channel when filter is enabled see Get_Ch_Selected_In_Ch_Filter() or Ch_Filter_Enabled1()
-- filter enabled status is true when either a single channel is active, multichannel mode is active or 'Show only events that pass the filter' option is checked in Event filter dialogue and can be true when 'All channels' option is active in the menu as well;
-- when the table contains a single channel this means this channel is selected in the filter drop-down menu, in this case the filter status indicates whether this channel is exclusively displayed;
-- when the table contains several channels the filter state is always true;
-- the table's being empty means that ALL channels are active, i.e. 'All channels' option is selected in the filter drop-down menu while filter isn't enabled, filter_state will be false, in this case last active channel will be returned;
-- 16 entries in the table mean that ALL channels are active, i.e. 'All channels' option is selected while the filter is enabled, filter_state will be true
local item = r.ValidatePtr(obj, 'MediaItem*')
local take = r.ValidatePtr(obj, 'MediaItem_Take*')
local item = item and obj or take and r.GetMediaItemTake_Item(obj)
	if not item then return end
local take = take and obj or r.GetActiveTake(item)
local retval, takeGUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
local ret, chunk = r.GetItemStateChunk(item, '', false) -- isundo
local takeGUID = takeGUID:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0') -- escape
local take_found
--local ch_bit_t = {1,2,4,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536}
local act_ch_t, filter_state = {}
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match(takeGUID) then take_found = 1 end
		if take_found and line:match('EVTFILTER') then
		local cnt = 0
			for val in line:gmatch('[%-%d]+') do
			cnt = val and cnt+1 or cnt
				if cnt == 7 then filter_state = val break end -- filter boolean is 7th field
			end
		local val = line:match('EVTFILTER (%d+)')
			if val then
				for i = 0, 15 do
				local bit = 2^i
					if val&bit == bit then -- channel numbers are 0-based logarithm of the value from the chunk with base 2
					act_ch_t[#act_ch_t+1] = i -- 0-based channel number
					end
				end
			break end -- break to prevent chunk loop from continuing and getting data from next takes because take_found remains valid, it could be reset to nil at this point but this wouldn't stop the chunk loop
		end
	end
return #act_ch_t > 0 and act_ch_t or {r.MIDIEditor_GetSetting_int(ME, 'default_note_chan')}, filter_state == '1'
end


function Force_MIDI_Undo_Point(take)
-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points, therefore Undo_Begin/EndBlock() functions must stay
-- https://forum.cockos.com/showpost.php?p=1925555
local item = r.GetMediaItemTake_Item(take)
local is_item_sel = r.IsMediaItemSelected(item)
r.SetMediaItemSelected(item, not is_item_sel)
r.SetMediaItemSelected(item, is_item_sel)
end


local ME = r.MIDIEditor_GetActive()
	if not ME then return r.defer(function() do return end end) end

local take = r.MIDIEditor_GetTake(ME)
local itm = r.GetMediaItemTake_Item(take)
local itm_st = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
local itm_end = itm_st + r.GetMediaItemInfo_Value(itm, 'D_LENGTH')
local cur_pos = r.GetCursorPosition()

local s = ' '

	if cur_pos <= itm_st or cur_pos >= itm_end then
	Error_Tooltip('\n\n'..s:rep(6)..'the edit cursor \n\n is outside of the item \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT = validate_sett(EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT)
EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH = validate_sett(EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH)
ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR = validate_sett(ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR)

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID)

local cur_pos_ppqn = r.MIDI_GetPPQPosFromProjTime(take, cur_pos)
local last_clicked_lane = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane')

local err = last_clicked_lane < 0 and '\n\nthe last clicked lane is undefined\n\n  click any lane to make it active \n\n' -- last clicked lane return value is -1 when the Piano roll was last clicked context
or last_clicked_lane == 520 and '\n\n   notation events \n\n are not supported \n\n'

		if err then Error_Tooltip(err, 1, 1) -- caps, spaced true
		return r.defer(no_undo) end

local lane_chanmsg = (last_clicked_lane >= 0 and last_clicked_lane <= 119 -- regular 7-bit cc lanes
or last_clicked_lane >= 256 and last_clicked_lane <= 287) -- 14-bit lanes
and 176
or last_clicked_lane == 513 and 224 -- pitch
or last_clicked_lane == 514 and 192 -- program change
or last_clicked_lane == 515 and 208 -- channel pressure (aftertouch)
or last_clicked_lane == 516 and 176 -- Bank/Program select // the data in this lane is linked to CC#00 Bank select MSB lane, events created in one automatically appear in the other, for both MIDI_GetCC() chanmsg return value is 176
or last_clicked_lane == 517 and 1 -- text events, between 1 and 14, currently only 9 are available // the value will be fine tuned in the loop so that all text event types are covered
or last_clicked_lane == 518 and -1 -- sysex event
or last_clicked_lane == 520 and 15 -- notation event // left here for completeness even though notation events aren't supported

local non_CC = last_clicked_lane == 517 or last_clicked_lane == 518 or last_clicked_lane == 520

local ch_t, filter_state = Get_Currently_Active_Chan_And_Filter_State(take, ME)

local prev_evts_exist, concur_evt_exists

	if not non_CC then

	msg2_new = lane_chanmsg == 176 and ((last_clicked_lane <= 119 and last_clicked_lane -- 7-bit lanes
	or last_clicked_lane >= 256 and last_clicked_lane <= 287 and last_clicked_lane - 256 -- 14-bit lanes, have the same msg2 value as their 7-bit counterparts, events appear in both lane types simultaneously
	or last_clicked_lane == 516 and 0)) -- for Bank/Program select lane (516) msg2 value is the same as for CC#00 Bank select MSB lane and is always 0
	or 0 -- for other message types msg2 value doesn't represent lane index

	local i = 0
	msg2_new, msg3_new = msg2_new, 0
		repeat
		local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, i)
			if retval and (lane_chanmsg == 176 and chanmsg == 176 and msg2 == msg2_new
			or lane_chanmsg ~= 176 and chanmsg == lane_chanmsg) -- lane_chanmsg ~= 176 is required to prevent false positives when msg2 ~= msg2_new while chanmsg is still 176
			and chan == ch_t[1] then -- in any combination of the filter options and state the relevant channel will be the first in the table or the only one in the table, when Multichannel option is enabled REAPER actions (such as 'Edit: Set or insert CC event at mouse cursor') target the first of the active channels so the script replicates this behavior
			msg2_new, msg3_new = chanmsg == 176 and msg2_new or msg2, msg3
				if ppqpos > cur_pos_ppqn and not prev_evts_exist then -- if cursor precedes the very 1st event in the lane
				prev_evts_exist = 1 -- ensures that event props dialogue isn't triggered if EVENT_PROPS_DIALOGUE is enabled
				break
				elseif ppqpos < cur_pos_ppqn then -- collect values of prev events until the most recent
				prev_evts_exist = 1 -- ensures that event props dialogue isn't triggered if EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT is enabled
				elseif ppqpos == cur_pos_ppqn then -- to prevent stacking of events
				concur_evt_exists = 1
					if EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH or ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR -- in case of EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH the event must be selected for the event properties dialogue action to work
					then
					r.MIDI_SetCC(take, i, true, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, noSortIn) -- selectedIn true
					end
					if not EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH then
					Error_Tooltip('\n\n there\'s already an event \n\n'..s:rep(6)..'at this position \n\n', 1, 1) -- caps, spaced true
					end
				end
			end
		i = i+1
		until not retval

	else
	local i = 0
		repeat
		local retval, sel, muted, ppqpos, typ, msg = r.MIDI_GetTextSysexEvt(take, i)
			if retval and (lane_chanmsg == 1 and typ >= lane_chanmsg and typ <= 14) -- text events, type from 1 to 14
			or typ == lane_chanmsg -- -1 sysex or 15 notation // the conditions cover all event types but notation events are excluded with an error message upstream on the basis of MIDIEditor_GetSetting_int() return value
			then
			chanmsg, msg_new = typ, msg -- chanmsg parameter is required for text events as there're 14 (9 available) types, for sysex and notation events chanmsg will be the same as lane_chanmsg
				if ppqpos > cur_pos_ppqn then
				prev_evts_exist = 1
				break
				elseif ppqpos < cur_pos_ppqn then
				prev_evts_exist = 1
				elseif ppqpos == cur_pos_ppqn then
				concur_evt_exists = 1
					if EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH or ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR then
					r.MIDI_SetTextSysexEvt(take, i, true, mutedIn, ppqposIn, typeIn, msg, noSortIn) -- selectedIn true
					end
					if not EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH then
					Error_Tooltip('\n\n there\'s already an event \n\n'..s:rep(6)..'at this position \n\n', 1, 1) -- caps, spaced true
					end
				end
			end
		i = i+1
		until not retval

	end


local sel = not prev_evts_exist and EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT or ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR
local dialogue = not prev_evts_exist and EVENT_PROPS_DIALOGUE_WHEN_FIRST_EVENT or concur_evt_exists and EVENT_PROPS_DIALOGUE_WHEN_EVENT_MATCH

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

	if not non_CC and not concur_evt_exists then
	r.MIDI_InsertCC(take, sel, false, cur_pos_ppqn, lane_chanmsg, ch_t[1], msg2_new, msg3_new) -- muted false // concur_evt_exists cond addresses the event in the lane which the cursor pos coincides with, so only insert if there's no event at the edit cursor
	elseif non_CC then
		if not prev_evts_exist or concur_evt_exists and dialogue then
		local comm_ID = lane_chanmsg == -1 and 40480 -- Insert sysex event...
		or lane_chanmsg < 15 and 40458 -- Insert text event...
		-- the dialogues also work for editing if there's an event at the edit cursor // when the dialogue is closed all text/sysex events get selected, a weird behavior
		ACT(comm_ID, true) -- midi true
		elseif not concur_evt_exists then
		r.MIDI_InsertTextSysexEvt(take, sel, false, cur_pos_ppqn, chanmsg, msg_new) -- muted false
		end
	end

	if not non_CC and dialogue then ACT(40004, true) end -- Edit: Event properties, midi true


Force_MIDI_Undo_Point(take)

local undo = not concur_evt_exists and dialogue and 'Insert and edit' or not concur_evt_exists and 'Insert' or dialogue and 'Edit' or concur_evt_exists and ALWAYS_SELECT_EVENT_AT_EDIT_CURSOR and 'Select'

	if not undo then return r.defer(no_undo) end

r.Undo_EndBlock(undo..' MIDI event at edit cursor',-1)
r.PreventUIRefresh(-1)





