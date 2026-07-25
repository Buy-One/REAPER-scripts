--[[
ReaScript name: BuyOne_Take envelope preset - Save.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Added support for take playrate other than 1
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	The script allows loading automation item presets in the context 
        of take envelopes which is not supported natively.
			
        Before running the script select target take envelope.	
        The script will trigger Load Automation Item dialogue
        for manual loading the preset. All the rest is done
        by the script.
]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper


function no_undo()
-- do return end
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



function Insert_Closing_Env_Point(env, take, item)
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local item_end = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local first_sel_pt_pos, first_sel_pt_val
local last_sel_pt_pos, last_sel_pt_val
	for i=0, r.CountEnvelopePoints(env)-1 do
	local ret, pos, val, shape, tens, sel = r.GetEnvelopePoint(env, i) -- pos is within take, affected by playrate
	pos = pos/playrate
		if sel then
		first_sel_pt_pos, first_sel_pt_val = first_sel_pt_pos or pos, first_sel_pt_val or val
		last_sel_pt_pos, last_sel_pt_val = pos, val		
		end
	end
	if first_sel_pt_pos > 0 then
	r.InsertEnvelopePoint(env, 0, first_sel_pt_val, 0, 0, true, true) -- time 0 - take start (start offet is taken into account automatically, shape, tension 0, selected true, noSortIn true
	end
	if last_sel_pt_pos < item_end then
	r.InsertEnvelopePoint(env, item_end*playrate, last_sel_pt_val, 0, 0, true, true) -- shape, tension 0, selected true, noSortIn true
	end
r.Envelope_SortPoints(env)
end



function Offset_Playrate_In_Point_Position(take, ai_idx, tr_env, take_env, save)
-- save is boolean

	local function calc_playrate(src_playrate, targ_itm_st, targ_itm_length, targ_pt_pos)
	-- targ_itm_st arg is only relevant for AI because their envelope points position is counted from the project start
	-- and the value will be needed to calculate the local position within the AI
	local pos = targ_itm_st and targ_pt_pos - targ_itm_st or targ_pt_pos -- convert to pos within item
	local pos_percentage = targ_itm_length/100*pos -- or 100/(length/pos) // calculate point position percentage relative to the item end to then be able to calculate corresponding playrate percentage because full playrate value, i.e. 100%, only applies at the item end
	local rate_at_pos = src_playrate/100*pos_percentage -- calculate the amount of playrate which correponds to the position percentage within the target item // TARGET ITEM'S OWN PLAYRATE DOESN'T MATTER
	local playrate = src_playrate + (src_playrate < 1 and rate_at_pos or rate_at_pos*-1) -- since full playrate value, i.e. 100%, only applies at the end of the item, the closer the point to its start the closer the playrate is to 1, so calculate the playrate which applies at specific point by adding rate_at_pos value to or subtracting from the known playrate depending on the rate value relative to 1, thereby bringing it closer to 1
	return playrate, pos
	end
	
local GetAI_Info = r.GetSetAutomationItemInfo

	if save then
	-- source take properties
	local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
	-- target AI properties
	local st = GetAI_Info(tr_env, ai_idx, 'D_POSITION', 0, false)
	local length = GetAI_Info(tr_env, ai_idx, 'D_LENGTH', 0, false)
		if playrate ~= 1 then
			for i = 1, r.CountEnvelopePointsEx(tr_env, ai_idx)-2 do -- excluding 1st and last points which in AI are anchors // the loop direction doesn't matter because the points aren't sorted during the loop, otherwise for playrates < 1 it would have to be run in reverse because the points would be moved forward so the first to move would have to be the last (penultimate in this case) point
			local ret, pos = r.GetEnvelopePointEx(tr_env, ai_idx, i)
			pos = pos - st -- convert to pos within item
			local pos_percentage = length/100*pos -- or 100/(length/pos) // calculate point position percentage relative to the AI end to then be able to calculate corresponding playrate percentage because full playrate value, i.e. 100%, only applies at the AI end
			local rate_at_pos = playrate/100*pos_percentage -- calculate the amount of playrate which correponds to the position percentage within the target AI // TARGET AI OWN PLAYRATE DOESN'T MATTER
			playrate = playrate + (playrate < 1 and rate_at_pos or rate_at_pos*-1) -- since full playrate value, i.e. 100%, only applies at the end of the AI, the closer the point to its start the closer the playrate is to 1, so calculate the playrate which applies at specific point by adding rate_at_pos value to or subtracting from the known playrate depending on the rate value relative to 1, thereby bringing it closer to 1
			r.SetEnvelopePointEx(tr_env, ai_idx, i, st+pos/playrate, nil, nil, nil, nil, true) -- noSortIn true
			end
		r.Envelope_SortPointsEx(tr_env, ai_idx)
		end
	else
	-- source AI properties
	local src_playrate = GetAI_Info(tr_env, ai_idx, 'D_PLAYRATE', 0, false) -- is_set false // in fact when importing AI preset, playrate is always 1 because point positions are always saved at this playrate and the actual AI playrate is ignored when AI preset is saved
	local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
	playrate = playrate/src_playrate
		for i=0, r.CountEnvelopePoints(take_env)-1 do -- the loop direction doesn't matter because the points aren't sorted during the loop, otherwise for playrate < 1 it would have to be run in reverse because the points would be moved forward so the first to move would have to be the last point
		local ret, pos, val, shape, tension, sel = r.GetEnvelopePoint(take_env, i)
			if sel then -- after pasting the pasted points will be exclusively selected, if some points pre-dated points passting these will be non-selected
			r.SetEnvelopePoint(take_env, i, pos*playrate, nil, nil, nil, nil, true) -- noSortIn true
			end
		end
	r.Envelope_SortPoints(take_env)
	r.UpdateItemInProject(r.GetMediaItemTake_Item(take))
	end
r.UpdateArrange()
end




function ACT(id)
r.Main_OnCommand(id, 0)
end


local is_new_value, script_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = script_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

--[[---------------- NAME TESTING
--scr_name = 'Take envelope preset - Save'
--scr_name = 'Take envelope preset - Load'
--]]---------------

local save, load = scr_name:match('^Take envelope preset %- Save'), scr_name:match('^Take envelope preset %- Load')

	if not save and not load then
	Error_Tooltip('\n\n the script name isn\'t recognized \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local env = r.GetSelectedEnvelope(0)
local take = env and r.Envelope_GetParentTake(env)

	if not take then
	Error_Tooltip('\n\n no selected take envelope \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local actions = save and {
40290, -- Time selection: Set time selection to items
40330, -- Envelope: Select points in time selection
40335, -- Envelope: Copy selected points
40001, -- Track: Insert new track
41866, -- Track: Select volume envelope
42082, -- Envelope: Insert automation item
40630, -- Go to start of time selection
42398, -- Item: Paste items/tracks
42092, -- Envelope: Save automation item...
}
or
{
40290, -- Time selection: Set time selection to items
40001, -- Track: Insert new track
41866, -- Track: Select volume envelope
42093, -- Envelope: Load automation item...

-- create a copy of the AI in order to get its playrate for Offset_Playrate_In_Point_Position() function otherwise after 'Envelope: Delete automation items' no AI would be available to get the playrate from, and although currently AI preset playrate is always 1 this may change in the future
40057, -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
40631, -- Go to end of time selection
42398, -- Item: Paste items/tracks

40630, -- Go to start of time selection
40330, -- Envelope: Select points in time selection
42088, -- Envelope: Delete automation items, preserve points // in order to be able to paste points of an AI envelope to take envelope the points must be copied from a bare track envelope rather than from an AI envelope for which purpose the AI has to be deleted
40335, -- Envelope: Copy selected points
42398, -- Item: Paste items/tracks
40630, -- Go to start of time selection // restore edit cursor position which after pasting may end up very far from the target take if its playrate is very low in which case Arrange horiz scroll position will change as well
40005, -- Track: Remove tracks
}


r.Undo_BeginBlock()

local item = r.GetMediaItemTake_Item(take)
r.SetMediaItemSelected(item, true)


-- set source/target item track last touched so that a temp track is inserted with the action immediately after it
local tr = r.GetMediaItemTrack(item)
r.SetOnlyTrackSelected(tr)
ACT(40914) -- Track: Set first selected track as last touched track

local load_aborted, tr_env
	for k, act in ipairs(actions) do
	ACT(act)
		if save then
			if act == 40330 then -- 'Envelope: Select points in time selection'
			-- if in take envelope there's no point at the left/right take edge,
			-- then after pasting the points to an AI which always have points at edges
			-- the first/last segment will be slanted towards the envelope minimum value rather than
			-- continue in straight line to the left/right edge, so add such anchor points to the take envelope
			Insert_Closing_Env_Point(env, take, item) -- the new point is added to point selection
			elseif act == 42398 then -- 'Item: Paste items/tracks'
			local take_env = env -- change var
			local env = r.GetSelectedEnvelope(0) -- track envelope will be selected after 'Track: Select volume envelope' and 'Envelope: Insert automation item' actions
			Offset_Playrate_In_Point_Position(take, 0, env, take_env, save) -- ai_idx 0 // when envelope source take playrate is other than 1, the offset isn't transeferred to the target AI envelope at pasting, the points positions revert to their values unaffected by the playrate, therefore the offset must be effected separately, the playrate of the  target envelope source AI itself doesn't matter because it doesn't affect the offset of the pasted points
			r.GetSetAutomationItemInfo(env, 0, 'D_UISEL', 1, true) -- is_set true // re-select AI just inserted so that 'Envelope: Save automation item...' can be successfuly executed, because after 'Track: Select volume envelope' and 'Envelope: Insert automation item' the envelope remains selected and the AI gets deselected
			end
		else -- load
			if act == 42093 then -- 'Envelope: Load automation item...'
			local tr_env = r.GetSelectedEnvelope(0) -- vol envelope on the inserted temp track will be selected
				if r.CountAutomationItems(tr_env) == 0 then load_aborted = 1 break end -- the user dismissed the Load dialogue so no AI has been added to the track
			elseif act == 40335 then -- 'Envelope: Copy selected points'
			tr_env = r.GetSelectedEnvelope(0) -- vol envelope on the inserted temp track will be selected // store
			r.SetCursorContext(2, env) -- re-select target take envelope because it will be deselected due to activation of temp track envelope and AI insertion
			elseif act == 42398 and k == 12 then -- 'Item: Paste items/tracks' // 2nd instance of the action
			Offset_Playrate_In_Point_Position(take, 0, tr_env, r.GetSelectedEnvelope(0)) -- ai_idx 0, the selected envelope here is the target take envelope selected after the action 'Envelope: Copy selected points' above // points from an AI envelope are always pasted at playrate 1 and their spacing in the target take envelope is affected by the target take playrate, so in order to restore the original points spacing the take playrate has to be offset
			end
		end
	end

ACT(40635) -- Time selection: Remove (unselect) time selection

r.Undo_EndBlock((save and 'Save' or load and 'Load')..' take envelope preset',-1)

	if save or load_aborted then reaper.Undo_DoUndo2(0) end -- nothing has changed so undo which will also remove the temp track, also makes sense if the Save/Load dialogue was dismissed by the user




