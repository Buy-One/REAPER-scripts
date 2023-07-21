--[[
ReaScript name: BuyOne_Insert take marker with current timestamp at edit;mouse cursor in selected items;takes.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 	v1.2 #Added safeguard against inserting multiple markers at the same position
		     #Updated annotations in the USER SETTINGS
		v1.1 #Added setting to open 'Edit take marker' dialogue along with marker insertion
About:
Licence: WTFPL
REAPER: at least v5.962
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Timestamp formats:
-- 1 = dd.mm.yyyy - hh:mm:ss
-- 2 = dd.mm.yy - hh:mm:ss
-- 3 = dd.mm.yyyy - H:mm:ss AM/PM
-- 4 = dd.mm.yy - H:mm:ss AM/PM
-- 5 = mm.dd.yyyy - hh:mm:ss
-- 6 = mm.dd.yy - hh:mm:ss
-- 7 = mm.dd.yyyy - H:mm:ss
-- 8 = mm.dd.yy - H:mm:ss AM/PM
-- 9 = current system locale

-- Number of timestamp format from the above list
local TIME_FORMAT = 1

-- Color code in HEX format, 6 or 3 digits preceded
-- with the hash sign,
-- defaults to black if the format is incorrect
local HEX_COLOR = "#000"

-- Set to 1 to have marker inserted at the Edit cursor, 
-- a marker will be added to all selected items under
-- the edit cursor,
-- any other number - at the Mouse cursor,
-- the marker will only be added to the item 
-- under the mouse;
-- in multi-take items the marker will be added 
-- to the active take;
-- if the the target position is already occupied
-- by another marker, no marker will be added
local POS_POINTER = 1

-- To have the 'Edit marker' dialogue appear
-- along with marker insertion set to 1, 
-- any other number disables the setting;
-- when the dialogue appears the marker which
-- has been inserted isn't visible;
-- if the dialogue is canceled the marker will 
-- still be inserted;
-- if the the target position is already occupied
-- by another marker, the dialogue will belong
-- to the existing marker at the target position
local MARKER_EDIT_DIALOGUE = 0

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end

local sel_item_cnt = r.CountSelectedMediaItems(0)

	if sel_item_cnt == 0 then r.MB('No selected items/takes.','ERROR',0) r.defer(function() end) return end

local err1 = (not TIME_FORMAT or type(TIME_FORMAT) ~= 'number' or TIME_FORMAT < 1 or TIME_FORMAT > 9) and '       Incorrect timestamp format.\n\nMust be a number between 1 and 9.'
local err2 = not POS_POINTER or type(POS_POINTER) ~= 'number' and 'Incorrect position pointer format.\n\n\tMust be a number.'
local err = err1 or err2

	if err then r.MB(err,'USER SETTINGS error',0) r.defer(function() end) return end


function Take_Marker_Exists(take, pos)
local i = 0
	repeat
	local src_pos, name, color = r.GetTakeMarker(take, i)
		if src_pos == pos then return true end
	i = i+1
	until src_pos == -1
end


local t = {
'%d.%m.%Y - %H:%M:%S', -- 1
'%d.%m.%y - %H:%M:%S', -- 2
'%d.%m.%Y - %I:%M:%S', -- 3
'%d.%m.%y - %I:%M:%S', -- 4
'%m.%d.%Y - %H:%M:%S', -- 5
'%m.%d.%y - %H:%M:%S', -- 6
'%m.%d.%Y - %I:%M:%S', -- 7
'%m.%d.%y - %I:%M:%S', -- 8
'%x - %X'	       -- 9
}

os.setlocale('', 'time')

local store_curs_pos = r.GetCursorPosition() -- if mouse cursor is enabled as pointer

r.PreventUIRefresh(1)

local move_curs = POS_POINTER ~= 1 and r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)
local cur_pos = r.GetCursorPosition()

local daytime = tonumber(os.date('%H')) < 12 and ' AM' or ' PM' -- for 3,4,7,8 using 12 hour cycle
local daytime = (TIME_FORMAT == 3 or TIME_FORMAT == 4 or TIME_FORMAT == 7 or TIME_FORMAT == 8) and daytime or ''
local timestamp = os.date(t[TIME_FORMAT])..daytime

function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    hex = HEX_COLOR:sub(2)
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end

local HEX_COLOR = type(HEX_COLOR) == 'string' and HEX_COLOR:gsub('%s','') -- remove empty spaces just in case
-- default to black if color is improperly formatted
local HEX_COLOR = (not HEX_COLOR or type(HEX_COLOR) ~= 'string' or HEX_COLOR == '' or #HEX_COLOR < 4 or #HEX_COLOR > 7) and '#000' or HEX_COLOR
-- extend shortened (3 digit) hex color code, duplicate each digit
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or HEX_COLOR
local R,G,B = hex2rgb(HEX_COLOR) -- R because r is already taken by reaper, the rest is for consistency

local x,y = r.GetMousePosition()
local itm_under_mouse, take_under_mouse = r.GetItemFromPoint(x, y, false) -- allow_locked false
local itms_under_cursor_cnt = 0
local mrkr_pos_t = {}

	for i = 0, sel_item_cnt-1 do
	local item = r.GetSelectedMediaItem(0,i)
		if POS_POINTER ~= 1 and item == itm_under_mouse or POS_POINTER == 1 then
		local take = r.GetActiveTake(item)
			if take then
			local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
			local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
			itms_under_cursor_cnt = item_pos <= cur_pos and item_end >= cur_pos and itms_under_cursor_cnt+1 or itms_under_cursor_cnt
			local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
			local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
			local mark_pos = (cur_pos - item_pos + offset)*playrate
			local marker_exists = Take_Marker_Exists(take, mark_pos)
				if not marker_exists then
				mrkr_pos_t[#mrkr_pos_t+1] = {take=take, pos=mark_pos}			
				end
			end
		end
	end

	if #mrkr_pos_t == 0 then -- markers already exist at the target position(s)
	local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false)
		if (POS_POINTER ~= 1 or itms_under_cursor_cnt == 1) and MARKER_EDIT_DIALOGUE == 1 then -- when the target position is already take, only display marker edit dailogue if the target is item under mouse or if there's only one selected item under the edit cursor
		r.Main_OnCommand(42385, 0) -- 'Item: Add/edit take marker at play position or edit cursor'
		elseif MARKER_EDIT_DIALOGUE ~= 1 then
		Error_Tooltip('\n\n markers already exists \n\n', 1, 1) -- caps and spaced true
		end		
	r.PreventUIRefresh(-1)
	return r.defer(function() do return end end) end

r.Undo_BeginBlock()

	for _, data in ipairs(mrkr_pos_t) do
	r.SetTakeMarker(data.take, -1, timestamp, data.pos, r.ColorToNative(R,G,B)|0x1000000)
	end

local open_edit_dialogue = MARKER_EDIT_DIALOGUE == 1 and r.Main_OnCommand(42385, 0) -- 'Item: Add/edit take marker at play position or edit cursor'

r.Undo_EndBlock('Insert take marker(s) time stamped to '..timestamp,-1)

local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false) -- if mouse cursor is enabled as pointer

r.PreventUIRefresh(-1)






