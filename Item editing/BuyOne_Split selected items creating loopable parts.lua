--[[
ReaScript name: BuyOne_Split selected items creating loopable parts.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script splits selected audio items under 
    		the edit cusrsor making the split parts loopable.
    		
    		Splitting audio items with the native actions 
    		simply creates trimmed instances of the original 
    		item with the same loop iteration length.
    		
    		The script also supports MIDI items but they're 
    		not its primary target because when these are 
    		split with native actions their split parts
    		become loopable automatically.
    		
    		In multi-take items the script only targets the
    		active take.
		
]]

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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


function ReStoreSelectedItems(t, keep_last_selected)
-- keep_last_selected is boolean relevant for the restoration stage
-- to add last selected items to the original selection
	if not t then -- Store selected items
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
		if sel_itms_cnt > 0 then
		local t = {}
		local i = sel_itms_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local item = r.GetSelectedMediaItem(0,i)
			t[#t+1] = item
			r.SetMediaItemSelected(item, false) -- deselect item
			i = i - 1
			end
		return t end
	elseif t then -- Restore selected items
		if not keep_last_selected then
	--	r.Main_OnCommand(40289,0) -- Item: Unselect all items
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		end
	local i = 1
		while i <= #t do
		r.SetMediaItemSelected(t[i],true) -- if in between function runs any item pointers become invalid due to item deletion or split, the function doesn't throw an error, because the data type it expects remains valid
		i = i + 1
		end
	end
r.UpdateArrange()
end


local edit_cur_pos = r.GetCursorPosition()

local t = {}

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
		for itm_idx = 0, r.GetTrackNumMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr,itm_idx)
		local st = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local fin = st + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
			if st < edit_cur_pos and fin > edit_cur_pos
			and r.IsMediaItemSelected(item) then
			t[#t+1] = {tr=tr,itm_idx=itm_idx}
			end
		end
	end

	if #t == 0 then
	Error_Tooltip('\n\n    no selected items \n\n under the edit cursor \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local ACT = r.Main_OnCommand

ACT(40012,0) -- Item: Split items at edit or play cursor

function Process_Take_Section(t, right_part, left_part, reset_fade)
	for k, data in pairs(t) do
	local tr, itm_idx = data.tr, data.itm_idx
	-- left part of the item split retains the original index
	local item1 = r.GetTrackMediaItem(tr, itm_idx)
	r.SetMediaItemSelected(item1, left_part)
	-- to target the right part the original index must be incremented by 1
	local item2 = r.GetTrackMediaItem(tr, itm_idx+1)
	r.SetMediaItemSelected(item2, right_part)
	local item = left_part == 1 and item1 or right_part == 1 and item2
	local take = item and r.GetActiveTake(item)
		if take and not r.TakeIsMIDI(take) then
			if not reset_fade then
			local src = r.GetMediaItemTake_Source(take)
			local section, offset, len, revers = r.PCM_Source_GetSectionInfo(src)
				if section then -- disable in order to re-apply with new section props
				ACT(40547,0) -- Item properties: Loop section of audio item source
				end
			else
			local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
			local ret, chunk = GetObjChunk(item)
			-- reset section fade value to 0 because the action automaticaly sets it to 10 ms
			local sub_chunk = chunk:match('('..Esc(take_GUID)..'.-OVERLAP.-)\n')
			local sub_chunk_new = sub_chunk:gsub('OVERLAP [%.%d]+','OVERLAP 0.0')
			sub_chunk = Esc(sub_chunk)
			chunk = chunk:gsub(sub_chunk, sub_chunk_new)
			SetObjChunk(item, chunk)
			end
		end
	end
end

-- prevent random selected item outside of the edit cursor from being affected by 'Loop section action'
local sel_t = ReStoreSelectedItems() -- store
r.SelectAllMediaItems(0, false) -- selected false // deselect all before applying section

	Process_Take_Section(t, 1, 0) -- left_part 1 select, right_part 0 de-select
	ACT(40547,0) -- Item properties: Loop section of audio item source // apply to all currently selected
	Process_Take_Section(t, 0, 1) -- left_part 0 de-select, right_part 1 select
	ACT(40547,0) -- Item properties: Loop section of audio item source // apply to all currently selected
	-- must be run after applying section with the action inside Process_Take_Section() because it's lagging
	-- and chunk retrieved immediately after applying section doesn't contain section data
	Process_Take_Section(t, 1, 0, true) -- left_part 1 select, right_part 0 de-select, reset_fade true
	Process_Take_Section(t, 0, 1, true) -- left_part 0 de-select, right_part 1 select, reset_fade true

ReStoreSelectedItems(sel_t) -- restore original selection

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Split selected items creating loopable parts',-1)






