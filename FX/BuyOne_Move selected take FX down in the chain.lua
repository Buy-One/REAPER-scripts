--[[
ReaScript name: BuyOne_Move selected take FX down in the chain.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M not mandatory but recommended
About: 	The script first looks for a take under the mouse cursor,
		if not found, looks for selected items and in them only targets
		selected FX in the FX chain of the active take.
		
		After the selected FX has reached the bottom of the chain it will 
		not move in cycle back to its top.
		
		!!!! IMPORTANT !!!!
		
		If you choose to run the script with a shortcut, the shortcut scope
		must be global (select appropriate option from the 'Scope' menu in 
		the 'Keyboard/MIDI/OSC input' dialogue in the Action list). This will
		ensure script operability when take under mouse cursor is targeted 
		while its FX chain window is in focus.
		
		The script doesn't support FX containers.
		
		Also be aware that until fixed, after changing FX order by dragging
		the FX which is visually selected is not the one which is recognized 
		by REAPER as selected. In order to get the selection data updated 
		toggle FX selection, i.e. select another FX and re-select the previous.
		Bug report https://forum.cockos.com/showthread.php?t=284621
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Enable by inserting any alphanumeric character between the quotes
-- to instruct the script to select the envelope in locked items
ALLOW_LOCKED = ""

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


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end


local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end


function Get_FX_Selected_In_FX_Chain(chunk)
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match('LASTSEL') then return line:match('%d+') end
	end
end


function MOVE(item, take, dir, sel_itm_cnt, take_at_mouse, ALLOW_LOCKED)

local ret, chunk = GetObjChunk(item)

	if (sel_itm_cnt == 1 or take_at_mouse) and ret == 'err_mess' then -- only if exactly 1 take is targeted
	local err = 'the data could not be processed \n\n due to absence of the sws extension'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 10, 10) -- caps, spaced are true, x2, y2 are 10 px //  x2, y2 so that the tooltip position is outside of the mouse cursor, otherwise the tooltip hijacks the context and on the next run without changing the cursor position item under cursor won't be found and an irrelevant message will be displayed
	return err

	elseif ret then

		if r.GetMediaItemInfo_Value(item, 'C_LOCK') & 1 == 1 and not ALLOW_LOCKED then
		return end

	local fx_cnt = r.TakeFX_GetCount(take)
		if fx_cnt == 0 then return end

	local up, down = dir == 'up', dir == 'down'

	local fx_idx = Get_FX_Selected_In_FX_Chain(chunk)

	local err = 'the selected fx is already \n\nat the position'
	local err = fx_idx == '0' and up and err:gsub('at the', (' '):rep(6)..'%0 top')
	or fx_idx+1 == fx_cnt and down and err:gsub('at the', '   %0 bottom')

		if (sel_itm_cnt == 1 or take_at_mouse) and err then -- only if exactly 1 take is targeted
		Error_Tooltip('\n\n '..err..'\n\n', 1, 1, 10, 10) -- caps, spaced are true, x2, y2 are 10 px
		return end

		-- if more than 1 take is targeted only move if the FX hasn't already reached the top
		-- or the bottom of the chain
		-- if exactly 1 take this will be prevented by the error message above
		if up and fx_idx+0 ~= 0 or down and fx_idx+0 ~= fx_cnt-1 then

		local fx_idx_new = up and fx_idx-1 or down and fx_idx+1
		r.TakeFX_CopyToTake(take, fx_idx+0, take, fx_idx_new, true) -- is_move true

		local ret, chunk = GetObjChunk(item) -- get chunk after reordering
		local chunk_new = chunk:gsub('LASTSEL '..fx_idx, 'LASTSEL '..fx_idx_new)
		SetObjChunk(item, chunk_new)

		else
		
		return err
		
		end

	end

end


ALLOW_LOCKED = #ALLOW_LOCKED:gsub(' ','') > 0
local dir = 'down' -- up or down

local x,y = r.GetMousePosition()
local item_at_mouse, take_at_mouse = r.GetItemFromPoint(x, y, true) -- allow_locked true, will be taken care of below
local item = item_at_mouse or r.GetSelectedMediaItem(0,0)
local take = take_at_mouse or item and r.GetActiveTake(item)
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local fx_cnt = take and r.TakeFX_GetCount(take)

	if not take then
	Error_Tooltip('\n\n\tno selected items \n\n or under the mouse cursor\n\n', 1, 1) -- caps, spaced are true
	return r.defer(no_undo)
	-- Generate error messages if all items are prevented from being affected by the script
	elseif take_at_mouse or take then -- under mouse
	sel_itm_cnt = take_at_mouse and 1 or sel_itm_cnt -- accounting for a single take under mouse
	local empty_chain_cnt, locked_cnt = 0, 0
		for i = 0, sel_itm_cnt-1 do
		local item = item_at_mouse or r.GetSelectedMediaItem(0,i) -- accounting for a single item under mouse
		local take = take_at_mouse or r.GetActiveTake(item) -- accounting for a single take under mouse
		empty_chain_cnt = r.TakeFX_GetCount(take) < 2 and empty_chain_cnt+1 or empty_chain_cnt
		locked_cnt = not ALLOW_LOCKED and r.GetMediaItemInfo_Value(item, 'C_LOCK') & 1 == 1 and locked_cnt+1 or locked_cnt
		end
		if empty_chain_cnt + locked_cnt == sel_itm_cnt then
		local err1 = empty_chain_cnt > 0 and 'no or only 1 fx in the chain(s)' or ''
		local err2 = locked_cnt > 0 and ' locked items are disallowed' or ''
		local space = #err1 > 0 and #err2 > 0 and (' '):rep(1) or ''
		local lb = #err1 > 0 and #err2 > 0 and '\n\n' or ''
			if err1 or err2 then
			Error_Tooltip('\n\n '..err1..lb..space..err2..' \n\n', 1, 1, 10, 10) -- caps, spaced are true, x2, y2 are 10 px //  x2, y2 so that the tooltip position is outside of the mouse cursor, otherwise the tooltip hijacks the context and on the next run without changing the cursor position item under cursor won't be found and an irrelevant message will be displayed
			return r.defer(no_undo)
			end
		end
	r.Undo_BeginBlock()
		for i = 0, sel_itm_cnt-1 do
		local item = item_at_mouse or r.GetSelectedMediaItem(0,i) -- accounting for a single item under mouse
		local take = take_at_mouse or r.GetActiveTake(item) -- accounting for a single take under mouse
		local fx_exist = r.TakeFX_GetCount(take) > 1
		local locked = not ALLOW_LOCKED and r.GetMediaItemInfo_Value(item, 'C_LOCK') & 1 == 1
			if fx_exist and not locked then -- ignoring takes with empty chains, 1 FX and locked unless allowed
			local err = MOVE(item, take, dir, sel_itm_cnt, take_at_mouse, ALLOW_LOCKED)
		-- ensure that with multiple targeted takes the error message is only displayed
		-- when it applies to all valid FX chains,
		-- mess will only be nil at the 1st evaluation, if next err value differs from the previous stored in mess,
		-- mess var will evaluate to false
			mess = mess == nil and (err or '') or err == mess and mess
			end
		end

		if mess and #mess > 0 then
		Error_Tooltip('\n\n '..mess..' \n\n', 1, 1, 10, 10) -- caps, spaced are true, x2, y2 are 10 px //  x2, y2 so that the tooltip position is outside of the mouse cursor, otherwise the tooltip hijacks the context and on the next run without changing the cursor position item under cursor won't be found and an irrelevant message will be displayed
		end

	r.Undo_EndBlock('Move selected take FX '..dir..' in the chain', -1)

	end





