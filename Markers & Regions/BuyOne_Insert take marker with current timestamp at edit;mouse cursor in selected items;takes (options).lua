--[[
ReaScript name: BuyOne_Insert take marker with current timestamp at edit;mouse cursor in selected items;takes.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 	v1.2 #Added safeguard against inserting multiple markers at the same position
		     #Obviated item selection when a marker is inserted at the mouse cursor
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
-- a marker will be added to ALL SELECTED items under
-- the edit cursor,
-- any other number - at the Mouse cursor,
-- the marker will only be added to the item 
-- under the mouse, item SELECTON ISN'T NECESSARY;
-- in multi-take items the marker will be added 
-- to the active take;
-- if the the target position is already occupied
-- by another marker, no marker will be added
local POS_POINTER = 1

-- To have the 'Edit marker' dialogue appear
-- along with marker insertion set to 1, 
-- any other number disables the setting;
-- for this setting to work the target item 
-- MUST BE SELECTED, even though selection 
-- isn't otherwise necessary when inserting 
-- a marker at the mouse cursor;
-- if a marker is set to be inserted at the edit 
-- cursor and there're several selected items 
-- under the edit cursor, the edit dialogue
-- isn't called;
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
r.TrackCtl_SetToolTip(text, x+10, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


local item_cnt = POS_POINTER == 1 and r.CountSelectedMediaItems(0) or r.CountMediaItems(0)

	if item_cnt == 0 then
	local mess = POS_POINTER == 1 and 'no selected items/takes' or 'no items'
	Error_Tooltip('\n\n '..mess..' \n\n ', 1, 1) -- caps and spaced are true
	return r.defer(function() do return end end) end

local err1 = (not TIME_FORMAT or type(TIME_FORMAT) ~= 'number' or TIME_FORMAT < 1 or TIME_FORMAT > 9) and '       Incorrect timestamp format.\n\nMust be a number between 1 and 9.'
local err2 = not POS_POINTER or type(POS_POINTER) ~= 'number' and 'Incorrect position pointer format.\n\n\tMust be a number.'
local err = err1 or err2

	if err then r.MB(err,'USER SETTINGS error',0) return r.defer(function() do return end end) end


function Take_Marker_Exists(take, pos)
local i = 0
	repeat
	local src_pos, name, color = r.GetTakeMarker(take, i)
		if src_pos == pos then return true end
	i = i+1
	until src_pos == -1
end
	
	
function Edit_Dialogue_Error(itm_under_mouse, mess_var) -- mess_var is boolean
-- used when POS_POINTER ~= 1, i.e. for item under mouse
local mess = '\n\n to have the edit dialogue \n\n     displayed, the item \n\n       must be selected \n\n '
local mess = mess_var and '\n\n   marker already exists. '..mess or mess
	if itm_under_mouse and not r.IsMediaItemSelected(itm_under_mouse) then
	Error_Tooltip(mess, 1, 1) -- caps and spaced true
	end
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
'%x - %X'			   -- 9
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
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or HEX_COLOR
local R,G,B = hex2rgb(HEX_COLOR) -- R because r is already taken by reaper, the rest is for consistency

local x,y = r.GetMousePosition()
local itm_under_mouse, take_under_mouse = r.GetItemFromPoint(x, y, false) -- allow_locked false

	if POS_POINTER ~= 1 and not take_under_mouse then
	local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false) -- moveview, seekplay false
	Error_Tooltip('\n\n         no valid item \n\n under the mouse cursor \n\n', 1, 1) -- caps and spaced true
	r.PreventUIRefresh(-1)
	return r.defer(function() do return end end) end
	
local itms_under_edit_cursor_cnt = 0
local mrkr_pos_t = {}

	for i = 0, item_cnt-1 do
	local item = POS_POINTER ~= 1 and r.GetMediaItem(0,i) or r.GetSelectedMediaItem(0,i)
		if POS_POINTER ~= 1 and item == itm_under_mouse or POS_POINTER == 1 then
		local take = r.GetActiveTake(item)
			if take then
			take = (POS_POINTER ~= 1 and take_under_mouse or POS_POINTER == 1 and take)
			local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
			local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
			local item_under_edit_cursor = item_pos <= cur_pos and item_end > cur_pos -- take marker isn't inserted at the very right edge of an item so >= is redundant and prevents triggering 'no item under mouse' message 
			itms_under_edit_cursor_cnt = item_under_edit_cursor and itms_under_edit_cursor_cnt+1 or itms_under_edit_cursor_cnt
			local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
			local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
			local mark_pos = (cur_pos - item_pos + offset)*playrate
			local marker_exists = Take_Marker_Exists(take, mark_pos)
				if not marker_exists and (take_under_mouse or item_under_edit_cursor) then
				mrkr_pos_t[#mrkr_pos_t+1] = {take=take, pos=mark_pos}		
				end
				if POS_POINTER ~= 1 then break end -- no point to continue because there can only be one item under mouse
			end
		end
	end

	if #mrkr_pos_t == 0 then -- markers already exist at the target position(s)	or no item under the edit cursor
		if POS_POINTER == 1 and itms_under_edit_cursor_cnt == 0 then
		Error_Tooltip('\n\n     no selected item \n\n under the edit cursor \n\n', 1, 1) -- caps and spaced true
		elseif (POS_POINTER ~= 1 or itms_under_edit_cursor_cnt == 1) and MARKER_EDIT_DIALOGUE == 1 then -- when the target position is already taken, only display marker edit dailogue if the target is item under mouse or if there's only one selected item under the edit cursor
		Edit_Dialogue_Error(itm_under_mouse, 1) -- mess_var is true, 'Edit take marker' dialogue action doesn't work if the item isn't selected, display message
		r.Main_OnCommand(42385, 0) -- 'Item: Add/edit take marker at play position or edit cursor' // only works when item is selected
		elseif MARKER_EDIT_DIALOGUE ~= 1 then
		Error_Tooltip('\n\n markers already exist \n\n', 1, 1) -- caps and spaced true
		end
	local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false) -- moveview, seekplay false
	r.PreventUIRefresh(-1)
	return r.defer(function() do return end end) end


r.Undo_BeginBlock()

	for _, data in ipairs(mrkr_pos_t) do
	r.SetTakeMarker(data.take, -1, timestamp, data.pos, r.ColorToNative(R,G,B)|0x1000000)
	end
	
local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false) -- moveview, seekplay false
	
r.PreventUIRefresh(-1)

	if MARKER_EDIT_DIALOGUE == 1 and (POS_POINTER ~= 1 or itms_under_edit_cursor_cnt == 1) then -- only display marker edit dailogue if the target is item under mouse or if there's only one selected item under the edit cursor // done in a separate PreventUIRefresh() block to ensure inserted marker visibility
	r.PreventUIRefresh(1)
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // repeat moving the edit cursor to mouse cursor because the below action relies on the edit cursor position
	r.Main_OnCommand(42385, 0) -- 'Item: Add/edit take marker at play position or edit cursor' // only works if item is selected
	Edit_Dialogue_Error(itm_under_mouse) -- mess_var is omitted, so nil, 'Edit take marker' dialogue action doesn't work if the item isn't selected, display message
	r.SetEditCurPos(store_curs_pos, false, false) -- moveview, seekplay false // restore
	r.PreventUIRefresh(-1)
	end

r.Undo_EndBlock('Insert take marker(s) time stamped to '..timestamp,-1)


