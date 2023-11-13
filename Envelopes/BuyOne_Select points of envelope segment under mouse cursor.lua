--[[
ReaScript name: BuyOne_Select points of envelope segment under mouse cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Improved compatibility with automation items in different scenarios
		#Added new setting to ignore SWS extension for certain use cases
		#Updated 'About' text
	   v1.1 #Ensured that automation item points are also deselected along with envelope points outside of a segment
		#Ensured that envelope points overlapped by automation item are ignored
		#Added new setting to allow selecting segment points in take envelopes if item is locked
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
	as described in paragraph A) as long as its position doesn't result in 
	change of context from the selected envelope to another object which is 
	INEVITABLE if the option 'Show envelope in lane' is disabled (action 
	'Envelope: Toggle display in separate lane for selected envelope')
	so that the envelope is displayed over a media item. In this case a 
	minute shift of the mouse cursor from the envelope will result in context 
	change to item. 
	If you have the SWS extension installed, prefer envelopes to be 
	displayed over media items, run the script with a shortcut and wish to 
	avoid this context switch problem you can enable IGNORE_SWS_EXT setting 
	in the USER SETTINGS of this script and use method A) described above.
	Alternatively you can run the script with a mouse modifier (see paragraph
	2 next).  		
	Taking advantage of the SWS extension you can change the context to 
	another envelope by executing the script while simply pointing the 
	mouse cursor at it.
	
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
	
	If envelope segment start or end points are overlapped by an automation 
	item such segment is invalid and its points cannot be selected.  
	This is true also for envelope segment whose start and end points are 
	located outside of an automation item on both sides and mouse cursor 
	is within the automation item bounds, in which case the automation
	item envelope will be the target for point selection.  
	In looped automation item adjacent points belonging to different loop
	iterations aren't considered segment points and hence cannot be selected
	either.
	
	After selecting segment points their values can be adjusted simultaneously
	with the actions 'Item edit: Move items/envelope points up/down one track/a bit'
	or 'Envelopes: Move selected points up/down a little bit'.
	
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


-- If enabled instructs the script to select envelope and/or segment 
-- points in locked items;
-- the setting is mainly relevant when running the script 
-- with a shortcut rather than a mouse modifier because a shortcut
-- allows selecting (when the SWS extension is installed) or otherwise
-- keeping an envelope selected in a locked item, while a mouse click 
-- immediately deselects it without the ability to re-select 
-- as long as the item is locked, which also blocks all mouse modifiers
-- in envelope contexts,
-- and as such the setting is very niche;
-- however it has no effect if global take envelope or item (full) lock 
-- is enabled, because in this case the lock state cannot be overridden
ALLOW_IN_LOCKED_ITEMS = ""


-- See explanation in the paragraph 1. Via a shortcut B) above
IGNORE_SWS_EXT = ""

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
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Is_Item_Under_Mouse_Locked()
local x, y = r.GetMousePosition()
local item = r.GetItemFromPoint(x,y, true) -- allow_locked true
return item and r.GetMediaItemInfo_Value(item, 'C_LOCK') & 1 == 1
end


function Item_Time_2_Proj_Time(item_time, item, take) -- used inside Find_Segment_Points()
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


function Get_Props_Of_AI_Intersecting_Cur_Pos(env, cur_pos)
-- AI start is considered intersecting cursor while its end isn't
	for i = 0, r.CountAutomationItems(env)-1 do
	local pos = r.GetSetAutomationItemInfo(env, i, 'D_POSITION', -1, false) -- value -1, is_set false
	local fin = pos + r.GetSetAutomationItemInfo(env, i, 'D_LENGTH', -1, false) -- value -1, is_set false
		if pos <= cur_pos and fin > cur_pos then -- only AI start is considered belonging to AI so that a segment could be selected rightwards
		return i, pos, fin
		end
	end

end


function Get_Props_Of_AI_Overlapping_Env_Segm(env, pt_pos_st, pt_pos_end, cur_pos)
	for i = 0, r.CountAutomationItems(env)-1 do
	local pos = r.GetSetAutomationItemInfo(env, i, 'D_POSITION', -1, false) -- value -1, is_set false
	local fin = pos + r.GetSetAutomationItemInfo(env, i, 'D_LENGTH', -1, false) -- value -1, is_set false
		if pos <= pt_pos_st and fin >= pt_pos_st -- start point is overlapped
		or pos <= pt_pos_end and fin >= pt_pos_end -- end point is overlapped
		-- segment is overlapped and the cursor is located within the AI bounds
		or pos >= pt_pos_st and fin <= pt_pos_end
		and pos <= cur_pos and fin > cur_pos
		then
		return i, pos, fin
		end
	end
end


function Find_Segment_Points(env, cur_pos, AI_idx, item, take)

local pt_cnt = not AI_idx and r.CountEnvelopePoints(env) -- ignoring automation items
or r.CountEnvelopePointsEx(env, AI_idx|0x10000000) -- points in full loop iteration incl. hidden
local st_pt_idx, end_pt_idx

	if not AI_idx then -- main envelope
		for i = 0, pt_cnt-1 do -- look for segment points
		local retval, pos_end, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, i) -- autoitem_idx -1, ignore // OR r.GetEnvelopePoint()
		pos_end = take and Item_Time_2_Proj_Time(pos_end, item, take) or pos_end
			if pos_end and not end_pt_idx and pos_end >= cur_pos then -- pos_end can be nil if take env and the item is trimmed, because only pos of points within view is returned by Item_Time_2_Proj_Time() function
			end_pt_idx, st_pt_idx = i, i-1
				-- for track env only return points which aren't overlapped by an automation item
				if not take and st_pt_idx > -1 then -- more than 1 point in the track env
			-------------------------------------------------------
				--[[ THIS ROUTINE ALLOWS SELECTING MAIN ENV SEGMGENT POINTS EVEN IF ONE OF THEM IS OVERLAPPED BY AN AI
				local AI_idx, AI_st, AI_end = Get_Props_Of_AI_Intersecting_Cur_Pos(env, cur_pos)
					if AI_idx then -- overlapping AI found
					local retval, pos_start, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, st_pt_idx) -- autoitem_idx -1, ignore // OR r.GetEnvelopePoint()
						if pos_start >= AI_st or pos_end <= AI_end then
						end_pt_idx, st_pt_idx = nil -- reset as if the points weren't found
						end
					end
				]]
				-- THIS ROUTINE ENSURES THAT SEGMENT WHOSE POINTS ARE OVELAPPED BY AN AUTOMATION ITEM IS IGNORED
			--	local overlap = Get_Props_Of_AI_Overlapping_Env_Pt(env, pos_end)
				local retval, pos_start, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, st_pt_idx) -- autoitem_idx -1, ignore // OR r.GetEnvelopePoint()
				local overlap = Get_Props_Of_AI_Overlapping_Env_Segm(env, pos_start, pos_end, cur_pos)
					if overlap then
					end_pt_idx, st_pt_idx = nil -- reset as if the points weren't found
					end
				end
			------------------------------------------------------
			break end
		end
	else -- AI envelopes
	local st = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POSITION', -1, false) -- value -1, is_set false
	local len = r.GetSetAutomationItemInfo(env, AI_idx, 'D_LENGTH', -1, false)-- value -1, is_set false
	local fin = st + len
	local startoffs = r.GetSetAutomationItemInfo(env, AI_idx, 'D_STARTOFFS', -1, false) -- value -1, is_set false
	local loop_len_QN = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POOL_QNLEN', -1, false) -- value -1, is_set false
	local playrate = r.GetSetAutomationItemInfo(env, AI_idx, 'D_PLAYRATE', -1, false) -- value -1, is_set false
	local loop_len = r.TimeMap_QNToTime(loop_len_QN)/playrate -- convert to sec
	local loop_cnt = len/loop_len < 1 and 1 or math.floor(len/loop_len) -- count number of loop iterations within AI length; only integer is required

	-- calculate loop iteration which falls under the cursor, 
	-- if loop is disabled or AI length < one loop iteration, loop_iter var will be 0
	local loop_iter
		for i=0,loop_cnt do
			if cur_pos >= st-startoffs+loop_len*i and cur_pos < fin
			then loop_iter = i
			end
		end
		for i = 0, pt_cnt-1 do -- look for segment points
		local retval, end_pos, val, shape, tens, sel = r.GetEnvelopePointEx(env, AI_idx|0x10000000, i) -- respecting points in full loop iteration incl. hidden
		end_pos = end_pos+loop_len*loop_iter -- offset by the number of loop iterations before the cursor retrieved above
			if not end_pt_idx and end_pos > cur_pos and end_pos <= fin then -- making sure that the end_pos is within view
			end_pt_idx, st_pt_idx = i, i-1
				if st_pt_idx > -1 then -- make sure that start point is within view
				local retval, st_pos, val, shape, tens, sel = r.GetEnvelopePointEx(env, AI_idx|0x10000000, st_pt_idx) -- respecting points in full loop iteration incl. hidden
				st_pos = st_pos+loop_len*loop_iter -- offset by the number of loop iterations before the cursor retrieved above
					if st_pos < st then
					end_pt_idx, st_pt_idx = nil -- reset as if the points weren't found 
					end
				end
			break end
		end
	end

return st_pt_idx, end_pt_idx

end


function Deselect_All_Env_Points(env)

	local function Deselect_Points_In_Env_All_AIs(env, AI_idx)
		-- respecting points in full loop iteration incl. hidden
		for i = 0, r.CountEnvelopePointsEx(env, AI_idx|0x10000000)-1 do
		r.SetEnvelopePointEx(env, AI_idx, i, timeIn, valueIn, shapeIn, tensionIn, false, noSortIn) -- selectedIn false, deselect // when setting 0x10000000 addition isn't needed
		end
		-- only respecting visible points incl. all loop iterations
		for i = 0, r.CountEnvelopePointsEx(env, AI_idx)-1 do
		r.SetEnvelopePointEx(env, AI_idx, i, timeIn, valueIn, shapeIn, tensionIn, false, noSortIn) -- selectedIn false, deselect
		end
	end

	-- in the envelope
	for i = 0, r.CountEnvelopePoints(env)-1 do -- in the envelope, ignoring automation items
	r.SetEnvelopePointEx(env, -1, i, timeIn, valueIn, shapeIn, tensionIn, false, noSortIn) -- autoitem_idx -1, ignore, selectedIn false, deselect
	end
	-- in the automation items
	for AI_idx = 0, r.CountAutomationItems(env)-1 do
	Deselect_Points_In_Env_All_AIs(env, AI_idx)
	end
	
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


ALLOW_IN_LOCKED_ITEMS = #ALLOW_IN_LOCKED_ITEMS:gsub(' ','') > 0
local sws = r.APIExists('BR_GetMouseCursorContext') and #IGNORE_SWS_EXT:gsub(' ','') == 0
local env_init = r.GetSelectedEnvelope(0)
local item_locked = Is_Item_Under_Mouse_Locked()

	if sws then
	local wnd_name, segm_name, details = r.BR_GetMouseCursorContext()
		if segm_name == 'envelope' or (details == 'env_segment' or details == 'env_point' or details == 'item')
		then -- select envelope under mouse // 1st cond refers to track env, the 2nd - to take env
		local env, isTakeEnv = reaper.BR_GetMouseCursorContext_Envelope()
			if item_locked and ALLOW_IN_LOCKED_ITEMS or not item_locked then
			r.SetCursorContext(2, env)
			end
		end
	end

local env = r.GetSelectedEnvelope(0)

	if r.GetCursorContext() ~= 2 or -- if the cursor context above wasn't set due to item being locked this cond is only true if the SWS ext is installed and env context wasn't already active
	item_locked and not ALLOW_IN_LOCKED_ITEMS and env_init == env then 
	local err = item_locked and not ALLOW_IN_LOCKED_ITEMS 
	and 'envelopes in locked items \n\n\t are disallowed'
	or ' no (selected) envelope\n\n under the mouse cursor'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced are true	
	return r.defer(no_undo)
	end


ENABLE_UNDO = #ENABLE_UNDO:gsub(' ','') > 0
local take, fx_idx, parm_idx = table.unpack(env and {r.Envelope_GetParentTake(env)} or {})
local item = take and r.GetMediaItemTake_Item(take)

	if env then

	local cur_pos = r.GetCursorPosition() -- store edit cur pos before moving to the mouse cursor
	r.PreventUIRefresh(1)
	ACT(40514) -- View: Move edit cursor to mouse cursor (no snapping)
	local mouse_pos = r.GetCursorPosition()
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit curs pos
	r.PreventUIRefresh(-1)

	local st_pt_idx, end_pt_idx = Find_Segment_Points(env, mouse_pos, AI_idx, item, take)

		if end_pt_idx and st_pt_idx > -1 then -- a safeguard against envelopes with 1 point only

			if ENABLE_UNDO then r.Undo_BeginBlock() end

			Deselect_All_Env_Points(env)
			
			-- select found points
			for i = st_pt_idx, end_pt_idx do
			r.SetEnvelopePointEx(env, -1, i, timeIn, valueIn, shapeIn, tensionIn, true, noSortIn) -- autoitem_idx -1, ignore, selectedIn true, select
			end

		elseif not take then -- look for automation items under the mouse if track env

		local AI_idx = Get_Props_Of_AI_Intersecting_Cur_Pos(env, mouse_pos)

			if AI_idx then

			st_pt_idx, end_pt_idx = Find_Segment_Points(env, mouse_pos, AI_idx) -- item & take args aren't used here and AI playrate is irrelevant because the returned point pos is always based on the project time line

				if end_pt_idx and st_pt_idx > -1 then -- a safeguard against envelopes with 1 point only

					if ENABLE_UNDO then r.Undo_BeginBlock() end

					Deselect_All_Env_Points(env)
					
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







