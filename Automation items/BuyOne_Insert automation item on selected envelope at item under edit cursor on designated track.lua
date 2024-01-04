--[[
ReaScript name: BuyOne_Insert automation item on selected envelope at item under edit cursor on designated track.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Added support for getting envelope under mouse cursor if SWS extension is installed
		#Updated About text
	   v1.1 #Added code to deselect newly inserted AI if pooled
		so that the original pool source AI is the same for all script runs
		#Optimized behavior when pool source AI is itself located inder
		the media item
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
About: 	The script creates an automaion item (AI) of the same length as the item
	under the edit cursor on selected track or track under the mouse cursor. 
	The item and the selected envelope must belong to the same track. 
	An item considered to be under the edit cursor if the edit cursor is 
	located between the item start and item end or at the item start. Edit 
	cursor aligned with the item end is condsidered to be outside of the item.
	
	If there's no selected track the script will look for track under the mouse
	which is either TCP, MCP, envelope lane or the Arrange along the entire time
	line opposite of the TCP.
	
	If there's a selected AI on the selected envelope, the newly inserted AI 
	will be its pooled copy, otherwise it will be an independent non-pooled AI. 
	When a pooled copy is created if there're envelope points at the location 
	where the new AI is inserted these will be preserved and the AI will be placed 
	over them. Only the first selected AI is treated as a pool source for the
	new AI. The pooled copy is stretched or shrunk to fit item length if necessary.
	If a non-pooled AI is created, the existing envelope points, if any, will 
	be absorbed into it instead.  		
	
	If SWS/S&M extension is installed neither the track nor the envelope have 
	to be selected if the mouse cursor points at an envelope.
	
	Whether the newly inserted AI overwrites any AI present at the location it's 
	inserted at or whether it's inserted on top of it on a new AI lane depends 
	on the option  
	'Options: Trim content behind automation items when editing or writing automation'
	
	However if as a result of insertion of the new AI the pool source AI is going
	to be trimmed due to overlap, the above option won't affect the pool source AI 
	even if enabled and the pooled AI will be inserted on another AI lane.
	
	Without pooling the same operation can be realized as a custom action:
	
	Custom: Insert AI on selected envelope at item under edit cursor on selected track 
	(select track & envelope, place edit cursor over item)
	  Time selection: Set start point
	  View: Move cursor right 8 pixels
	  Time selection: Set end point
	  Item: Select all items on selected tracks in current time selection
	  Time selection: Set time selection to items
	  Envelope: Insert automation item
	  Time selection: Remove (unselect) time selection

]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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


local tr = r.GetSelectedTrack(0,0)
local x, y = r.GetMousePosition()
local tr, info = not tr and r.GetTrackFromPoint(x,y) or tr

	if not tr then
	Error_Tooltip('\n\n    no selected track \n\n or track under mouse \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end	

local env_sel = r.GetSelectedTrackEnvelope(0)
local sws = r.APIExists('BR_GetMouseCursorContext_Envelope')
local wnd, segm, details = table.unpack(sws and {r.BR_GetMouseCursorContext()} or {}) -- must come before BR_GetMouseCursorContext_Envelope() because it relies on it
local env, takeEnv = table.unpack(sws and {r.BR_GetMouseCursorContext_Envelope()} or {})
env = env or env_sel
local err = sws and (takeEnv and '    take envelopes don\'t \n\n support automation items' 
or not env and 'no track envelope under \n\n      mouse or selected') or not env and 'no selected track envelope'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end
	
local edit_cur_pos = r.GetCursorPosition()
local item, item_st, item_len
		for i = 0, r.GetTrackNumMediaItems(tr)-1 do
		local itm = r.GetTrackMediaItem(tr, i)
		local st = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
		local len = r.GetMediaItemInfo_Value(itm, 'D_LENGTH')
			if edit_cur_pos >= st and edit_cur_pos < st+len then
			item, item_st, item_len = itm, st, len
			break end
		end

	if not item then
	Error_Tooltip('\n\n   no item under the edit cursor '
	..'\n\n on selected or under mouse track\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local itm_tr = r.GetMediaItemTrack(item) -- or r.GetMediaItem_Track()
local env_tr = r.GetEnvelopeInfo_Value(env, 'P_TRACK')

	if itm_tr ~= env_tr then
	Error_Tooltip('\n\n  the item and the envelope '
	..'\n\n belong to different tracks \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


-- get index of the first selected AI on the envelope, which will be pool source for the newly inserted AI
local GetSetAI = r.GetSetAutomationItemInfo
local pool_src_idx
	for AI_idx = 0, r.CountAutomationItems(env)-1 do
		if GetSetAI(env, AI_idx, 'D_UISEL', -1, false) > 0 -- selected; value -1, is_set false
		then
		pool_src_idx = AI_idx
		break
		end
	end

r.Undo_BeginBlock()

	if pool_src_idx then
	-- collect props of the pool source AI
	local pool_ID = GetSetAI(env, pool_src_idx, 'D_POOL_ID', -1, false)
	local src_start = GetSetAI(env, pool_src_idx, 'D_POSITION', -1, false)
	local src_len = GetSetAI(env, pool_src_idx, 'D_LENGTH', -1, false)
	local src_playrate = GetSetAI(env, pool_src_idx, 'D_PLAYRATE', -1, false) -- pool source playrate isn't preserved in the inserted pooled instance, it defaults to 1, therefore the source playrate needs to be retrieved from the source

	local overlap = src_start >= item_st and src_start < item_st+item_len -- partial overlap incl. enclosed overlap
	or src_start+src_len > item_st and src_start+src_len <= item_st+item_len -- partial overlap incl. enclosed overlap
	or src_start <= item_st and src_start+src_len >= item_st+item_len -- full overlap

	local trim_ON = overlap and r.GetToggleCommandStateEx(0, 42206)	== 1 -- Options: Trim content behind automation items when editing or writing automation
	local disable = trim_ON and r.Main_OnCommand(42206, 0) -- toggle off to prevent trimming the pool source AI with the newly inserted one if they are going to overlap before playrate and length are fitted to match the item length
	-- however if there's a pre-existing AI under the item, turning off trimming to spare the pool source will prevent trimming such AIs as well

	-- trimming behind only works when pasting, it doesn't work when the length is changed,
	-- so if there's pre-existing AI under item and the pool source is shorter, in the pre-exiting AI
	-- only the part equal to the pool source length will be trimmed
	-- therefore the new AI must be created at full item length and playrate is dealt with afterwards
	local new_AI_idx = r.InsertAutomationItem(env, pool_ID, item_st, item_len)
	
	-- always set playrate to cover all cases, including cases when the pool source is already under the item
	-- and has the same length when inserting a new AI on top of the pool source
	local src_orig_len = src_len*src_playrate -- calculate orig pool source length, new length is created by division of orig length by playrate, so this is reverse operation
	local new_playrate = src_orig_len/item_len -- calc playrate required for fitting AI length to item length
	GetSetAI(env, new_AI_idx, 'D_PLAYRATE', new_playrate, true) -- is_set true
		
		if trim_ON then r.Main_OnCommand(42206, 0) end -- re-enable
		
	GetSetAI(env, new_AI_idx, 'D_UISEL', 0, true) -- value 0, is_set true // de-select the newly added AI
	local new_AI_st = GetSetAI(env, new_AI_idx, 'D_POSITION', -1, false)
	pool_src_idx = new_AI_st < src_start and pool_src_idx+1 or pool_src_idx
	GetSetAI(env, pool_src_idx, 'D_UISEL', 1, true) -- value 1, is_set true // re-select pool source AI because at insertion of the new AI it gets de-selected, so all subsequent new AI if any use the same source
	
	pool = '& pool'
	
	else
	r.InsertAutomationItem(env, -1 , item_st, item_len) -- if no selected AI pool_id -1 absorbs env points
	Error_Tooltip('\n\n no selected ai to pool with \n\n', 1, 1) -- caps, spaced true
	end

r.Undo_EndBlock('Insert automation item on selected envelope at item under edit cursor on designated track '..(pool or ''), -1)



