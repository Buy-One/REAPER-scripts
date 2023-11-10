--[[
ReaScript name: BuyOne_Select points of envelope segment under mouse cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M recommended
About:	When executed the script selects active envelope segment points.
	Segment is a line or curve between two closest points.
	
	The script supports both track and take envelopes, and automation
	item envelopes.
	
	This is an alternative to selecting segment points within time
	selection with the action 'Envelope: Select points in time selection'
	
	There're two ways to run the script.
	
	1. Via a shortcut.  
	
	A) If the SWS/S&M extension isn't installed the target envelope must 
	already be selected and the mouse cursor can be placed anywhere on 
	the Y axis which intersects the target segment.  
	
	B) If the SWS/S&M extension IS installed the envelope doesn't have to
	be initially selected but the mouse cursor must point at the envelope. 
	Once the envelope has been selected the mouse cursor position can be
	as described in the previous paragraph as long as its position doesn't
	result in change of context from for example track envelope to take
	envelope and vice versa. But if you wish you can change the context
	by simply pointing the mouse cursor at another envelope.
	
	If the intersection of the Y axis and the envelope segment falls on 
	(when the SWS extension isn't installed) or if the mouse points at 
	(when the SWS extension IS installed) an envelope point the segment 
	which is to the right of such point will be targeted, meaning this 
	envelope point and the next will be selected rather than this point 
	and the previous.
	
	2. Via a mouse modifier of the Envelope segment or Envelope lane 
	double click context.  
	In this case to execute the script double click the envelope segment
	or envelope lane respectively while holding down the relevant mouse 
	modifier.  
	
	It's advised not to map the script under these contexts to combinations 
	which include Ctrl or Shift modifiers because these by default are taken 
	by Insert point or draw envelope actions under Envelope lane left drag 
	context and will intercept the double click adding new points.
	
	When segment points get selected all other envelope points get de-selected
	unless segment isn't found in which case point selection doesn't change.
	
	After selecting segment points their values can be adjusted simultaneously
	with the actions 'Item edit: Move items/envelope points up/down one track/a bit'
	
	The script can be used inside a following custom action mapped to the mousewheel
	to simultaneously select segment points and move them up/down:
	
	Custom: Select segment points and move up/down (map to mousewheel)
		Script: BuyOne_Select envelope segment points under mouse cursor.lua
		Action: Skip next action if CC parameter <0/mid
		Item edit: Move items/envelope points up one track/a bit
		Action: Skip next action if CC parameter >0/mid
		Item edit: Move items/envelope points down one track/a bit
	  
	Be aware however that if no point is selected the action 
	'Item edit: Move items/envelope points up/down one track/a bit'
	moves all envelopes points, and so will affect the envelope even when 
	the script displays 'No segment found' error message.
	
	Or the following custom actions with the script can be mapped to double click 
	with different mouse modifiers to simultaneously select segment points and
	move the up or down:
	
	Custom: Select segment points and move up
		Script: BuyOne_Select envelope segment points under mouse cursor.lua			
		Item edit: Move items/envelope points up one track/a bit
	
	Custom: Select segment points and move down
		Script: BuyOne_Select envelope segment points under mouse cursor.lua		
		Item edit: Move items/envelope points down one track/a bit
		
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert any alphanumeric character
-- between the quotes.

-- If enabled the script will create undo point
-- at each selection of segment points
ENABLE_UNDO = ""

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
end


function Item_Time_2_Proj_Time(item_time, item, take)
-- such as take envelope points, take/stretch markers and transient guides time, item_time is their position within take media source returned by the corresponding functions
-- e.g. take envelope points, take/stretch markers and transient guides time to edit/play cursor, proj markers/regions time

--local cur_pos = r.GetCursorPosition()
local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
--OR
--local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset and take marker pos
local proj_time = item_pos + (item_time - offset)/playrate

return proj_time >= item_pos and proj_time <= item_end and proj_time -- ignoring content outside of item bounds -- OPTIONAL

end


function Deselect_Points_In_Env_All_AIs(env, AI_idx)
-- accounting for points in all loop iterations, visible or not
	for i = 0, r.CountEnvelopePointsEx(env, AI_idx|0x10000000)-1 do
	r.SetEnvelopePointEx(env, AI_idx, i, timeIn, valueIn, shapeIn, tensionIn, false, noSortIn) -- selectedIn false, deselect
	end
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end

	if r.APIExists('BR_GetMouseCursorContext') then
	local wnd_name, segm_name, details = r.BR_GetMouseCursorContext()
		if segm_name == 'envelope' or details == 'env_segment' then -- select envelope under mouse // 1st cond refers to track env, the 2nd - to take env
		local env, isTakeEnv = reaper.BR_GetMouseCursorContext_Envelope()
		r.SetCursorContext(2, env)
		end
	end
	if r.GetCursorContext() ~= 2 then
	Error_Tooltip('\n\n         no envelope\n\n under the mouse cursor \n\n', 1, 1) -- caps, spaced are true
	return r.defer(no_undo)
	end


ENABLE_UNDO = #ENABLE_UNDO:gsub(' ','') > 0
local env = r.GetSelectedEnvelope(0)
local take, fx_idx, parm_idx = table.unpack(env and {r.Envelope_GetParentTake(env)} or {})
local item = take and r.GetMediaItemTake_Item(take)

	if env then

	local cur_pos = r.GetCursorPosition() -- store edit cur pos before moving to the mouse cursor
	r.PreventUIRefresh(1)
	ACT(40514) -- View: Move edit cursor to mouse cursor (no snapping)
	local mouse_pos = r.GetCursorPosition()
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit curs pos
	r.PreventUIRefresh(-1)

	local st_pt_idx, end_pt_idx, AI_idx

	local pt_cnt = r.CountEnvelopePoints(env) -- ignoring automation items
	
		for i = 0, pt_cnt-1 do -- look for segment points
		local retval, pos, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, i) -- autoitem_idx -1, ignore
		pos = take and Item_Time_2_Proj_Time(pos, item, take) or pos
			if pos and not end_pt_idx and pos >= mouse_pos then -- only stored once to allow the loop to finish so that all points are deselected to prevent them from being affected by movement of the selected ones // pos can be nil if take env and the item is trimmed, because only pos of points within view is returned by Item_Time_2_Proj_Time() function
			end_pt_idx, st_pt_idx = i, i-1
			end
		end
		
		if end_pt_idx and st_pt_idx > -1 then -- a safeguard against envelopes with 1 point only
	
			if ENABLE_UNDO then r.Undo_BeginBlock() end
			
			-- deselect all other points
			for i = 0, pt_cnt-1 do
			r.SetEnvelopePointEx(env, -1, i, timeIn, valueIn, shapeIn, tensionIn, false, noSortIn) -- autoitem_idx -1, ignore, selectedIn false, deselect
			end		
			-- select found points
			for i = st_pt_idx, end_pt_idx do
			r.SetEnvelopePointEx(env, -1, i, timeIn, valueIn, shapeIn, tensionIn, true, noSortIn) -- autoitem_idx -1, ignore, selectedIn true, select
			end
		elseif not take then -- look for automation items under the mouse if track env
		local AI_cnt = r.CountAutomationItems(env)
			for i = 0, AI_cnt-1 do
			local pos = r.GetSetAutomationItemInfo(env, i, 'D_POSITION', -1, false) -- value -1, is_set false
			local fin = pos + r.GetSetAutomationItemInfo(env, i, 'D_LENGTH', -1, false) -- value -1, is_set false
				if pos <= mouse_pos and fin > mouse_pos then -- only AI start is considered belonging to AI so that a segment could be selected rightwards
				AI_idx = i break
				end
			end
			if AI_idx then

			pt_cnt = r.CountEnvelopePointsEx(env, AI_idx) -- only respecting visible points
			
				for i = 0, pt_cnt-1 do -- look for segment points
				local retval, pos, val, shape, tens, sel = r.GetEnvelopePointEx(env, AI_idx, i)
					if not end_pt_idx and pos >= mouse_pos then -- only stored once to allow the loop to finish so that all points are deselected
					end_pt_idx, st_pt_idx = i, i-1
					end
				end
				if end_pt_idx and st_pt_idx > -1 then -- a safeguard against envelopes with 1 point only
				
					if ENABLE_UNDO then r.Undo_BeginBlock() end
				
					-- Deselect points in all AIs belonging to the envelope to prevent them from being affected by movement of the selected ones				
					for AI_idx = 0, AI_cnt-1 do -- accounting for all points in all loop iterations, visible or not
					Deselect_Points_In_Env_All_AIs(env, AI_idx)
					end					
					-- select found points
					for i = st_pt_idx, end_pt_idx do
					r.SetEnvelopePointEx(env, AI_idx, i, timeIn, valueIn, shapeIn, tensionIn, true, noSortIn) -- selectedIn true, select
					end
				end

			end -- AI_idx cond end

		end	-- not take cond end

		if not st_pt_idx or st_pt_idx < 0 then
		Error_Tooltip('\n\n no segment found \n\n', 1, 1) -- caps, spaced are true
		return r.defer(no_undo)
		end

		if ENABLE_UNDO then r.Undo_EndBlock('Select envelope segment points', -1) end

	end

	if not ENABLE_UNDO then return r.defer(no_undo) end







