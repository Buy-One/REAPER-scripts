--[[
ReaScript name: BuyOne_Move edit cursor to next selected note end.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=midi_editor] .
About: 	Selected notes in all MIDI channels are targeted
      	unless Channel filter is enabled.
]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
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


function no_undo()
do return end
end


function space(num)
return (' '):rep(num)
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


function Ch_Filter_Enabled(obj) -- via chunk, no need to open the MIDI Ed
-- filter enabled status is true when either a single channel is active,
-- multichannel mode is active or 'Show only events that pass the filter'
-- option is checked in Event filter dialogue and can be true when
-- 'All channels' option is active in the menu as well

	local function get_enabled_channels(channel_bitfield)
	local t = {}
		for i = 0, 15 do
		local bit = 2^i
		local set = channel_bitfield+0&bit == bit
			if set then t[i] = set end -- i is 0-based channel number
		end
	return t
	end

local item = r.ValidatePtr(obj, 'MediaItem*')
local take = r.ValidatePtr(obj, 'MediaItem_Take*')
local item = item and obj or take and r.GetMediaItemTake_Item(obj)
	if not item then return end
local take = take and obj or r.GetActiveTake(item)
local retval, takeGUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
local ret, chunk = r.GetItemStateChunk(item, '', false) -- isundo
local takeGUID = takeGUID:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0') -- escape
local take_found, channel_bitfield
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match(takeGUID) then take_found = 1 end
		if take_found and line:match('EVTFILTER') then
		local cnt = 0
			for val in line:gmatch('[%-%d]+') do
			cnt = val and cnt+1 or cnt
			channel_bitfield = channel_bitfield or cnt == 1 and val
				if cnt == 7 then -- filter boolean is 7th field
				return val == '1', get_enabled_channels(channel_bitfield) end
			end
		end
	end
end



local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

	if sect_ID ~= 32060 then
	Error_Tooltip('\n\n'..space(4)..'the script must be run \n\n'
	..space(5)..'from the midi editor \n\n section of the action list \n\n', 1,1) -- caps, spaced
	return r.defer(no_undo)
	end

local cur_pos = r.GetCursorPosition()
local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)
local item = r.GetMediaItemTake_Item(take)
local item_end = r.GetMediaItemInfo_Value(item, 'D_POSITION') + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take) -- returns count in all MIDI channels regardless of channel filter being enabled, so 'no notes' error mess below only applies when no notes in all channels, when no notes in the enabled channel this error message isn't triggered
local err = notecnt == 0 and 'no notes' or cur_pos >= item_end and 'midi take end has been reached'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced
	return r.defer(no_undo)
	end


scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local left_edge, right_edge = scr_name:match('start'), scr_name:match('end')
local i = 0
local sel_exist
	repeat
	local retval, sel, muted, start_pos, end_pos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only addresses notes in MIDI channels enabled in the MIDI channel filter or all notes if no channel is enabled or all are enabled
		if sel then
		sel_exist = 1
		local pos = left_edge and start_pos or right_edge and end_pos
		pos = r.MIDI_GetProjTimeFromPPQPos(take, pos)
			if pos > cur_pos then
		--	r.Undo_BeginBlock()
			r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
		--	r.Undo_EndBlock('Move edit cursor to next selected note', -1)
			return r.defer(no_undo)
			end
		end
	i=i+1
	until not retval


err = sel_exist and 'no next selected note'
or 'no selected notes'..(Ch_Filter_Enabled(take) and '\n\n in enabled midi channels' or '')

	if err then
	err = err:match('channel') and '\t'..err or err
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced
	return r.defer(no_undo)
	end






