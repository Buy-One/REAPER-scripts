--[[
ReaScript name: BuyOne_Select take Pitch envelope.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script first looks for a take under the mouse cursor,
	if not found, looks for the active take of the first 
	selected item.
	
	If the envelope isn't visible (in which case it's always deselected) 
	or bypassed, it's toggled visible or unbypassed and then selected.  
	If it's bypassed while being already selected, it's unbypassed.
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


function no_undo()
do return end
end

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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
	elseif t and #t > 0 then -- Restore selected items
		if not keep_last_selected then
	--	r.Main_OnCommand(40289,0) -- Item: Unselect all items
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		end
	local i = 0
		while i < #t do
		r.SetMediaItemSelected(t[i+1],true) -- +1 since item count is 1 based while the table is indexed from 1
		i = i + 1
		end
	end
r.UpdateArrange()
end

function Select_Take_Envelope(item, take, env_type)
local env = r.GetTakeEnvelopeByName(take, env_type)
--local env = env and r.CountEnvelopePoints(env) > 0 and env
local sel_env = r.GetSelectedEnvelope(0)
local retval, chunk, bypassed
	if env then
	retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	bypassed = chunk:match('ACT 0')
	end
	if env and env == sel_env and not bypassed then -- preventing nil equality in env == sel_env
	Error_Tooltip('\n\n the '..env_type..' envelope \n\n is already selected \n\n', 1, 1, 10, 10) -- caps, spaced are true, x2, y2 are 10 px
	-- the tooltip position must be outside of the mouse cursor otherwise the cursor hijacks the context and on the next run
	-- 'no item under cursor' error message is displayed
	return end
	if not env then
	local cmd_t = {Mute=40695,Pan=40694,Pitch=41612,Volume = 40693}
	r.Main_OnCommand(cmd_t[env_type], 0) -- Take: Toggle take ... envelope
	env = r.GetTakeEnvelopeByName(take, env_type)
	elseif bypassed then
	chunk = chunk:gsub('ACT 0', 'ACT 1') -- activate
	r.SetEnvelopeStateChunk(env, chunk, false)-- isundo false
	end
r.SetCursorContext(2, env)
r.UpdateTimeline()
end


ALLOW_LOCKED = #ALLOW_LOCKED:gsub(' ','') > 0
local env_type = 'Pitch' -- Mute, Pan, Pitch, Volume

local x,y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, ALLOW_LOCKED)
local item = item or r.GetSelectedMediaItem(0,0)
local take = take or item and r.GetActiveTake(item)

	if not take then
	Error_Tooltip('\n\n\tno selected items \n\n or under the mouse cursor\n\n', 1, 1) -- caps, spaced are true
	return r.defer(no_undo)
	elseif take then -- under mouse
	env_type = env_type:gsub(' ','') -- remove spaces if any
	local not_selected = not r.IsMediaItemSelected(item)
	r.Undo_BeginBlock()
		if not_selected then -- item under mouse and not selected
		r.PreventUIRefresh(1)
		t = ReStoreSelectedItems()
		r.SetMediaItemSelected(item, true) -- selected true // select to be able to toggle visible via action
		end
	Select_Take_Envelope(item, take, env_type)
		if not_selected then -- restore original selection state
		ReStoreSelectedItems(t)
		r.PreventUIRefresh(-1)
		end
	r.Undo_EndBlock('Select take '..env_type..' envelope', -1)
	end












