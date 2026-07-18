--[[
ReaScript name: BuyOne_Save take envelope preset.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	The script allows saving automation item presets in the context 
        of take envelopes which is not supported natively.
			
			 Before running the script select source take envelope.	
			 The script will trigger Save Automation Item dialogue
			 for manual saving the preset. All the rest is done
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



function Insert_Closing_Env_Point(env, item)
local item_st = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_st + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local last_sel_pt_pos
	for i=0, r.CountEnvelopePoints(env)-1 do
	local ret, pos, val, shape, tens, sel = r.GetEnvelopePoint(env, i)
		if sel then last_sel_pt_pos = pos end
	end
	if last_sel_pt_pos < item_end then
	ACT(40631) -- Go to end of time selection
	ACT(40106) -- Envelope: Insert new point at current position (do not remove nearby points) // the point ends up being added to selected points
	end
end



function ACT(id)
r.Main_OnCommand(id, 0)
end


local is_new_value, script_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = script_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

local save, load = scr_name:match('^Save take envelope preset'), scr_name:match('^Load take envelope preset')

--[[---------------- NAME TESTING
save = 1
load = 1
--]]---------------

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
42088, -- Envelope: Delete automation items, preserve points
40330, -- Envelope: Select points in time selection
40335, -- Envelope: Copy selected points
40005, -- Track: Remove tracks
40630, -- Go to start of time selection // execute after AI insertion because the edit cursor may move to its right edge
42398, -- Item: Paste items/tracks
}


r.Undo_BeginBlock()

local item = r.GetMediaItemTake_Item(take)
r.SetMediaItemSelected(item, true)

-- set source/target item track last touched so that a temp track is inserted with the action immediately after it
local tr = r.GetMediaItemTrack(item)
r.SetOnlyTrackSelected(tr)
ACT(40914) -- Track: Set first selected track as last touched track

local load_aborted
	for _, act in ipairs(actions) do
	ACT(act)
		if save then
			if act == 40330 then -- 'Envelope: Select points in time selection'
			-- if in take envelope there's no point at the right take edge,
			-- then after pasting the points to an AI which always have points at edges
			-- the last segment will slump to the envelope minimum value rather than
			-- contunuing in straight line to the fight edge, so add such point to the take envelope
			Insert_Closing_Env_Point(env, item) -- the new point is added to point selection
			elseif act == 42398 then -- 'Item: Paste items/tracks'
			local env = r.GetSelectedEnvelope(0) -- track envelope will be selected after 'Track: Select volume envelope' and 'Envelope: Insert automation item'
			r.GetSetAutomationItemInfo(env, 0, 'D_UISEL', 1, true) -- is_set true // re-select AI just inserted so that 'Envelope: Save automation item...' can be successfuly executed, because after points are pasted the envelope gets selected and the AI gets deselected
			end
		elseif act == 42093 then -- 'Envelope: Load automation item...'
		local env = r.GetSelectedEnvelope(0) -- vol envelope on the inserted temp track will be selected
			if r.CountAutomationItems(env) == 0 then load_aborted = 1 break end -- the user dismissed the Load dialogue so no AI has been added to the track
		elseif act == 40005 then -- 'Track: Remove tracks', in load operation, after deleting the temp track re-select target take envelope because it will be deselected due to activation of temp track envelope and AI insertion
		r.SetCursorContext(2, env)
		end
	end

ACT(40635) -- Time selection: Remove (unselect) time selection

r.Undo_EndBlock((save and 'Save' or load and 'Load')..' take envelope preset',-1)

	if save or load_aborted then reaper.Undo_DoUndo2(0) end -- nothing has changed so undo which will also remove the temp track, also makes sense if the Save/Load dialogue was dismissed by the user




