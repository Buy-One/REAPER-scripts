--[[
ReaScript name: BuyOne_Exclusively select note under mouse cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog:	#Initial release
Licence: WTFPL
About: 	If MIDI channel filter is enabled in the MIDI Editor
	only notes in the active channel are considered both
	for selection and for deselection, otherwise notes in
	all channels.
	
	It's not recommended to bind the script
	or a custom action it's used in, to a shortcut 
	identical to one mapped to a split action in
	the Main section of the Action list.  
	Because if the edit cursor is located outside
	of the MIDI item bounds or the MIDI Editor
	isn't an active window, such shortcut will trigger
	the split action causing the split of the MIDI
	item, which is though reparable still annoying.
]]


local r = reaper

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only display output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
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


function Mouse_Cursor_outside_painoroll(take)

local edit_cur_pos = r.GetCursorPosition()
local item = r.GetMediaItemTake_Item(take)
local item_st = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_st + r.GetMediaItemInfo_Value(item, 'D_LENGTH')

return edit_cur_pos >= item_end or edit_cur_pos <= item_st

end


function Re_Store_Edit_Cursor_Pos_In_MIDI_Ed(stored_pos)
-- moves to mouse cursor, then restores
-- HOWEVER if within the MIDI Editor the edit cursor was initially located
-- to the left of the start in item which starts exactly at the project start
-- the cursor position will be registered as 0
-- and upon restoration the cursor will be moved to the item start
-- i.e. the project start, because it cannot be moved left past it
-- into the negative even if manually it can

r.PreventUIRefresh(1)

	if not stored_pos then -- store

	local ACT = r.MIDIEditor_LastFocused_OnCommand
	local stored_pos = r.GetCursorPosition()
	ACT(40443, false) -- View: Move edit cursor to mouse cursor // islistviewcommand false
	return stored_pos

	else -- restore

	r.SetEditCurPos(stored_pos, 0, 0) -- restore edit cursor pos; moveview is 0, seekplay is 0

	end

r.PreventUIRefresh(-1)

end


function Deselect_All_Notes(ME, take)
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
	for i=0,notecnt-1 do
	local retval, sel, muted, startppqpos, endppqpos, chan, pitch, numbevel = r.MIDI_GetNote(take, 0)
	r.MIDI_SetNote(take, i, false)--, muted, startppqposIn, endppqposIn, chanIn, pitchIn, velIn, noSortIn) -- selectedIn false
	end
end


function Get_Note_Under_Mouse(hwnd, midi_take)
-- returns note index or nil if no note under mouse cursor
-- advised to use with Mouse_Cursor_outside_painoroll() because if mouse is outside of the MIDI item
-- the result will be nil as when there's no note under mouse

r.PreventUIRefresh(1)
local retval, notecntA, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(midi_take)
local props_t = {}
	for i = 0, notecntA-1 do -- collect current notes properties
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(midi_take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel
	props_t[#props_t+1] = {startppq, endppq, pitch}
	end
local snap = r.GetToggleCommandStateEx(32060, 1014) == 1 -- View: Toggle snap to grid
local off = snap and r.MIDIEditor_OnCommand(hwnd, 1014) -- disable snap
r.MIDIEditor_OnCommand(hwnd, 40052)	-- Edit: Split notes at mouse cursor
local on = snap and r.MIDIEditor_OnCommand(hwnd, 1014) -- re-enable snap
local retval, notecntB, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(midi_take) -- re-count after split
local idx, fin, note
	if notecntB > notecntA then -- some note was split
		for i = 0, notecntB-1  do
		retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(midi_take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel
		local v = props_t[i+1] -- +1 since table index is 1-based while note count is 0-based; the 1st part of the note will keep the note original index after split and after restoration
			if v and startppq == v[1] and endppq ~= v[2] and pitch == v[3] then
			idx, fin, note = i, endppq, pitch
			end
			if idx and startppq == fin and pitch == note then -- locate the 2nd part of the split note
			r.MIDI_DeleteNote(midi_take, i) -- delete the 2nd part
			r.MIDI_SetNote(midi_take, idx, x, x, x, endppq, x, x, x, false) -- restore the note original length // selected, muted, startppq, chan, pitch, vel all nil, noSort false because only one note is affected
			return idx end
		end
	end
r.PreventUIRefresh(-1)
end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

	if notecnt == 0 then
	Error_Tooltip('\n\n no notes \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

-- if the edit cursor is outside item bounds in the MIDI Editor
-- move to mouse cursor, then restore;
-- this is a workaround for cases where in the MIDI Editor section
-- of the Action list the script is mapped to a shortcut
-- identical to one active in the Main section of the Action list
-- such as one which a split action is mapped to, in which case
-- it will be triggered which is undesirable
local stored_pos = Mouse_Cursor_outside_painoroll(take) and Re_Store_Edit_Cursor_Pos_In_MIDI_Ed(stored_pos) -- move to mouse and store

local note_idx = Get_Note_Under_Mouse(ME, take)

	if note_idx then
	Deselect_All_Notes(ME, take)
	local retval, sel, muted, startppqpos, endppqpos, chan, pitch, numbevel = r.MIDI_GetNote(take, note_idx)
	r.MIDI_SetNote(take, note_idx, true)--, muted, startppqposIn, endppqposIn, chanIn, pitchIn, velIn, noSortIn) -- selectedIn true
	else
	Error_Tooltip('\n\n no note under mouse \n\n', 1,1) -- caps, spaced true
	end

	if stored_pos then
	Re_Store_Edit_Cursor_Pos_In_MIDI_Ed(stored_pos) -- restore
	end

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Exclusively select note under mouse cursor', -1)







