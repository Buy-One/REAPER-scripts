--[[
ReaScript name: BuyOne_Create rectangular segment in time selection in current CC lane.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	Meant to be a counterpart of the native action 
		'Envelope: Insert 4 envelope points at time selection'
		but for the MIDI Editor.

		Current CC lane is the last clicked.

		The most obvious use is creating a segment for
		a particular note event or a number of such.			
		To automate this task use the script inside a custom
		action as follows:

		Custom: Insert square segment in CC envelope at selected notes  
			Edit: Set time selection to selected notes  
			Script: BuyOne_Insert square segment in CC envelope in time selection.lua  
			Time selection: Remove time selection

		The inserted segment shape is square which 
		consists of 2 points rather than 4 because
		square 4 point segment isn't supported in 
		CC envelopes and falls apart in response 
		to click.

		The segment is inserted in the currently active
		MIDI channel (the one selected in the channel filter)
		or in the last active channel if 'All Channels' 
		or 'Multichannel' options are selected.
		If the option   
		'Selecting a single note sets the channel for new events'
		is enabled, active MIDI channel will change as
		soon as a note is selected with a click.

	Also see USER SETTINGS below.
			
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric acharacter
-- between the quotes to be able to specify
-- custom value for the segment via a dialogue;
-- if disabled, the value defaults to maximum
-- value of the effective range which for the pitch
-- envelope is either custom or 63 and for all other
-- supported envelopes is 127;
-- when the range of the pitch envelope
-- is in semitones, cents are supported as well
-- as fractions of 1, i.e. 0.01 - 1 cent,
-- 0.2 - 20 cents, 1.55 - 1 semitone 55 cents
DIALOGUE = "1"


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


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



function no_undo()
-- do return end
end


function act(ID)
r.MIDIEditor_LastFocused_OnCommand(ID, false) -- islistviewcommand false
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
-- caps and spaced are booleans, caps doesn't apply to non-ANSI characters
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
--[[ IF USING WITH gfx
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 arguments which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the gfx window
]]
local text = caps and text:upper() or text
local utf8 = '[\0-\127\194-\244][\128-\191]*'
local text = spaced and text:gsub(utf8,'%0 ') or text -- supporting UTF-8 char
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


function Lane_Type_To_Event_Data(ME, last_clicked_lane) -- relies on Error_Tooltip() for error message
-- further implementation see in Insert or edit MIDI event at edit cursor.lua
local ME = not ME and r.MIDIEditor_GetActive()
local last_clicked_lane = last_clicked_lane or r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane')

	if last_clicked_lane == -1 then  -- last clicked lane return value is -1 when the Piano roll was last clicked context
	Error_Tooltip('\n\nthe last clicked lane is undefined\n\n  click any lane to make it active \n\n', 1, 1) -- caps, spaced true
	return end

local t = {
[513] = 224, -- pitch
[514] = 192, -- program change
[515] = 208, -- channel pressure (aftertouch)
[516] = 176, -- Bank/Program select // the data in this lane is linked to CC#00 Bank select MSB lane, events created in one automatically appear in the other, for both MIDI_GetCC() chanmsg return value is 176
[517] = 1, -- text events, between 1 and 14, currently only 9 are available // the value will be fine tuned in the loop so that all text event types are covered
[518] = -1, -- sysex event
[520] = 15, -- notation event
[521] = 160 -- poly aftertouch
}

return t[last_clicked_lane] or (last_clicked_lane >= 0 and last_clicked_lane <= 119 -- regular 7-bit cc lanes
or last_clicked_lane >= 256 and last_clicked_lane <= 287) -- 14-bit lanes
and 176

end



function Delete_CC_Events_Within_Time(ME, take, data_type, CC_No, st, fin)
-- ME is MIDI Editor handle returned by r.MIDIEditor_GetActive();
-- data_type, integer, see values of chanmsg attribute below,
-- passed either manually or converted from current lane type
-- with Lane_Type_To_Event_Data();
-- CC_No only relevant if expected data_type is 176
-- to only be able to affect events in a particular CC envelope,
-- if data_type is fed from current lane type via Lane_Type_To_Event_Data()
-- CC_No will be the actual value
-- returned by r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane')

-- chanmsg (event type):
-- 0 - non-CC: (off) velocity, text/notation/sysex events, 160 - Poly Aftertouch, 176 - CC, Bank/Program select, Bank select, 192 - Program change, 208 - Channel pressure (aftertouch), 224 - Pitch (bend)
-- msg2:
-- always 0 for non-CC, Bank/Program select, 00 Bank select MSB events
-- first 7 bits (MSB) of event value for Pitch (msg3 provides second 7 bits (LSB))
-- program number for Program
-- event value for Channel pressure
-- CC message number for CC events starting from 0
-- msg3:
-- always 0 for non-CC, Program, Channel pressure
-- second 7 bits (LSB) of event value for Pitch (msg2 provides first 7 bits (MSB))
-- bank MSB for Bank/Program select and 00 Bank select MSB events, 0 if Bank/Program select event doesn't have .reabank loaded
-- event value for CC events

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

	if ccevtcnt == 0 then return end

-- table of supported data types,
-- if all data types should be supported, the table is useless
-- and t[chanmsg] condition should be removed from the loop
local t = {
[160] = 'poly aftertouch',
[176] = 'CC', -- includes Bank/Program select, Bank select but these aren't supported by the script and trigger error message if selected in CC lane
[192] = 'program',
[208] = 'ch press',
[224] = 'pitch'
}

local st = r.MIDI_GetPPQPosFromProjTime(take, st)
local fin = r.MIDI_GetPPQPosFromProjTime(take, fin)
local cur_ch = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15 // returns last channel when channel filter is set to 'All Channels' or 'Multichannel'

	for i=ccevtcnt,0,-1 do
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, i) -- point indices are based on their time position hence points with sequential indices are likely to belong to different CC envelopes // only targets events in the current MIDI channel if Channel filter is enabled
		if ppqpos >= st and ppqpos <= fin and chan == cur_ch
		and t[chanmsg] and data_type == chanmsg
		and (data_type == 176 and msg2 == CC_No or data_type ~= 176)
		then
		r.MIDI_DeleteCC(take, i)
		end
	end

end


local t = {
[512] = 'vel',
[516] = 'bank/prog sel',
[517] = 'text events',
[518] = 'sysex events',
[519] = 'off vel',
[520] = 'notation events',
[528] = 'media item lane'
}

local ME = r.MIDIEditor_GetActive()
local take = ME and r.MIDIEditor_GetTake(ME)
local item = take and r.GetMediaItemTake_Item(take)
local item_st = take and r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_st and item_st + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local last_focused = ME and r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane')
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop false, start/end 0, allowautoseek false
local err = not ME and 'No active MIDI Editor' --or r.MIDI_EnumSelNotes(take, -1) == -1 and 'No selected notes'
or st == fin and 'no time selection' or (st > item_end or fin < item_st) and '\ttime selection \n\n is outside of the item'
or last_focused == -1 and 'The last clicked lane \n\n\t is undefined. \n\n\tclick any lane \n\n    to make it active' -- last clicked lane return value is -1 when the Piano roll was last clicked context
or t[last_focused] and 'The last clicked lane type \n\n\t  is not supported'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

DIALOGUE = DIALOGUE:match('%S')
local data_type = Lane_Type_To_Event_Data()
local pitch_env = data_type == 224
local ch_press = data_type == 208
local prog = data_type == 192
local range

	if DIALOGUE and pitch_env and r.MIDIEditorFlagsForTrack then -- pitch
	range = r.MIDIEditorFlagsForTrack(r.GetMediaItemTake_Track(take), 0, 0, false) -- is_set false
	range = range ~= 0 and range
	end

local val

	if DIALOGUE then

	local title = 'Value in the range of '..(range and '-'..range..' — '..range or pitch_env and '-63 — 63' or '0 — 127')
	title = range and title..' semitones' or title
	local field = 'Value'..(range and ' (relative to center, i.e. 0):' or ':')

	::RETRY::

	local ret, output = r.GetUserInputs(title, 1, field..',extrawidth=100', val or '')

	if not ret or not output:match('%S') then return r.defer(no_undo) end

	val = tonumber(output)

		if not val then
		Error_Tooltip('\n\n Invalid input \n\n', 1, 1, x, -150) -- caps, spaced true, y2 is -150
		val = output
		goto RETRY
		else
		local unit = range and 8191/range or 8191/63 -- 8191 with subsequent use of LSB and MSB seems to produce more accurate pitch
		-- clamp
		val = pitch_env and (range and (val < range*-1 and range*-1 or val > range+0 and range)
		or not range and (val < -63 and -63 or val > 63 and 63)) or not pitch_env and (val < 0 and 0 or val > 127 and 127) or val
		val = not pitch_env and val or math.floor(8191 + unit*val + 0.5) -- pitch center is 8191 i.e. 0
		end
	end


r.Undo_BeginBlock()

act(40671) -- Unselect all CC events // to be able to identify the selected point(s) which are made selection on insertion

Delete_CC_Events_Within_Time(ME, take, data_type, last_focused, st, fin)

-- top point values
local msg2_lsb = data_type == 176 and last_focused
or val and (pitch_env and val & 127 or (ch_press or prog) and val) or (ch_press or prog) and 127 or 0
local msg3_msb = val and (pitch_env and (val >> 7) & 127 or val) or (ch_press or prog) and 0 or 127
-- bottom point values
_msg2_lsb = pitch_env and 8191&127 or data_type == 176 and last_focused or 0
_msg3_msb = pitch_env and 8191>>7&127 or 0

st = r.MIDI_GetPPQPosFromProjTime(take, st)
fin = r.MIDI_GetPPQPosFromProjTime(take, fin)
local chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan')

r.MIDI_InsertCC(take, true, false, st, data_type, chan, msg2_lsb, msg3_msb) -- selected true, muted false // point 1 // selected true to be able to identify this point in order to set its segment shape to square although the square shape seems to be default for a new point but just in case
r.MIDI_SetCCShape(take, r.MIDI_EnumSelCC(take, -1), 0, 0, true) -- shape 0 square, beztension 0, noSortIn true
r.MIDI_InsertCC(take, false, false, fin, data_type, chan, _msg2_lsb, _msg3_msb) -- selected false, muted false // point 2

r.MIDI_Sort(take)

act(40671) -- Unselect all CC events

r.Undo_EndBlock('Create rectangular segment in CC envelope in time selection.lua', -1)

