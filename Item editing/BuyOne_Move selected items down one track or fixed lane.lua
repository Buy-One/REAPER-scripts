--[[
ReaScript name: BuyOne_Move selected items down one track or fixed lane.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions:
Provides: [main=main,midi_editor] .
About: 	When fixed item lanes are enabled on the track
		of the selected item, the item is only moved by lanes
		if the lanes are not collapsed. When they are collapsed
		and the visible lane is not the selected item's lane,
		the item is ignored.

		See USER SETTINGS below.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert any
-- alphanumeric acharacter between the quotes

-- Enable to prevent movement of an item
-- if another item happens on its path;
-- however regardless of this setting the script
-- ignores the enabled option 'Trim content behind media items when editing'
-- so even if this setting isn't enabled but the said option is,
-- items which happen on the selected item's path
-- won't be deleted or trimmed, the selected item
-- will move on top of them
PREVENT_ITEM_COLLISION = ""

-- Enable to move item to the next available
-- track/lane if another item on the closest
-- track/lane happens on its path;
-- the setting only applies when the setting
-- PREVENT_ITEM_COLLISION is enabled above
MOVE_TO_NEXT_AVAILABLE_TRACK_OR_LANE = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end


local r = reaper


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



function Get_Next_Lane_Idx(item, lane_idx, item_tr, ID)

local lane = ID == 40107 or ID == 40068 -- down/up lane
local next_lane_idx = lane and (ID == 40107 and lane_idx+1 or lane_idx-1)
local item_tr_idx = r.CSurf_TrackToID(item_tr, false)-1 -- mpcView false
local next_tr_idx = not lane and (ID == 40118 and item_tr_idx+1 or item_tr_idx-1) -- down/up track

-- either moving to another track or within the same track between lanes
local next_tr = next_tr_idx and r.GetTrack(0, next_tr_idx) or item_tr
Msg(next_tr)
-- if moving to a track and it has fixed lanes, select target lane depending on the movement direction
local next_tr_lane_cnt = r.GetMediaTrackInfo_Value(next_tr, 'I_NUMFIXEDLANES')
next_lane_idx = next_lane_idx or next_tr_lane_cnt > 1 and (ID == 40118 and 0 or next_tr_lane_cnt-1) -- down/up track

	-- if moving to next track whose lanes are collapsed or disabled
	-- search for index of the visible lane because that's where the item will move
	if not lane and r.GetMediaTrackInfo_Value(next_tr, 'C_LANESCOLLAPSED') > 0 then
		for i=0, next_tr_lane_cnt-1 do
			if r.GetMediaTrackInfo_Value(next_tr, 'C_LANEPLAYS:'..i) > 0 then
			next_lane_idx = i
			break end
		end
	end

local move_item_func

	if PREVENT_ITEM_COLLISION then

	local collision
	local st = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local fin = st+r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		for i=0, r.CountTrackMediaItems(next_tr)-1 do
		local tr_item = r.GetTrackMediaItem(next_tr,i)
		local tr_itm_lane_idx = r.GetMediaItemInfo_Value(tr_item, 'I_FIXEDLANE')
				if tr_item ~= item
				-- next_lane_idx may be false if next track don't have multiple fixed lanes
				-- in which case the index of the only lane will be 0
				and (next_lane_idx and tr_itm_lane_idx == next_lane_idx or not next_lane_idx and tr_itm_lane_idx == 0)
				then
				local tr_itm_st = r.GetMediaItemInfo_Value(tr_item, 'D_POSITION')
				local tr_itm_end = tr_itm_st+r.GetMediaItemInfo_Value(tr_item, 'D_LENGTH')
					if st >= tr_itm_st and st < tr_itm_end
					or fin > tr_itm_st and fin <= tr_itm_end
					then
					collision = 1
					break
					end
				end
			end

			if collision and not MOVE_TO_NEXT_AVAILABLE_TRACK_OR_LANE then

			return

			elseif collision then

			next_lane_idx = nil

			local function MOVE(item, tr, lane_idx)
			r.MoveMediaItemToTrack(item, tr)
			-- item won't be moved to the designated lane
			-- without the UI update after moving to a track
			r.UpdateItemInProject(item)
			r.UpdateArrange()
			r.UpdateItemLanes()
				if lane_idx then
				r.SetMediaItemInfo_Value(item, 'I_FIXEDLANE', lane_idx)
				end
			end

			next_tr_idx = next_tr_idx or item_tr_idx
			local down = ID == 40107 or ID == 40118
			-- determine track loop direction depending on the item movement direction
			-- to select the available track/lane closest to the item
			local a, b, dir = table.unpack(down and {next_tr_idx, r.GetNumTracks()-1, 1}  -- down
			or {next_tr_idx, 0, -1}) -- up
				for i=a, b, dir do
				local tr = r.GetTrack(0,i)
				local tr_lane_cnt = r.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES')
				local lanes_collapsed = r.GetMediaTrackInfo_Value(tr, 'C_LANESCOLLAPSED') == 1
			--	local lanes_disabled = r.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:0') == -1 -- undocumented value // same as 'C_LANESCOLLAPSED' 2 or 3 the latter undocumented either // the variable is UNUSED
				local tr_item_cnt = r.CountTrackMediaItems(tr)

					if tr_item_cnt == 0 then -- good to be used // when no items fixed lanes cannot exist so can be ignored
					collision = nil
					move_item_func = function(item) MOVE(item, tr, next_lane_idx) end -- next_lane_idx here nil
					break
					end

				local itm_lane_idx = r.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
				local invalid_lane_indices = {}

				-- collect all invalid lanes the item cannot be moved to
				-- obviously only lanes with items are evaluated,
				-- empty lanes will be evaluated below
					for ii=0, tr_item_cnt-1 do
					local tr_item = r.GetTrackMediaItem(tr, ii)
					local itm_st = r.GetMediaItemInfo_Value(tr_item, 'D_POSITION')
					local itm_end = itm_st+r.GetMediaItemInfo_Value(tr_item, 'D_LENGTH')
					local lane_vis = r.GetMediaItemInfo_Value(tr_item, 'C_LANEPLAYS') ~= -1 -- item on a visible (active) lane // only relevant for FIL tracks with disabled FIL, on tracks with FIL enabled, collapsed or not, items on all lanes produce truth // OR 'B_FIXEDLANE_HIDDEN' ~= 1 to query lane visibility
					local lane_plays = r.GetMediaItemInfo_Value(tr_item, 'C_LANEPLAYS') == 1 -- plays exclusively, in the state of collapsed lanes, only one lane plays, the one visible
					local tr_itm_lane_idx = r.GetMediaItemInfo_Value(tr_item, 'I_FIXEDLANE')
						if (st >= itm_st and st < itm_end or fin > itm_st and fin <= itm_end) -- stands in item's way
						-- invisible
						or not lane_vis
						or lanes_collapsed and not lane_plays -- if this condition is absent the lane which hasn't been filtered out here will be in lanes loop below
					-- OR both above conditions can be replaced with r.GetMediaItemInfo_Value(tr_item, 'B_FIXEDLANE_HIDDEN') == 1
						then
						invalid_lane_indices[tr_itm_lane_idx] = tr_itm_lane_idx
						end
					end

				-- determine lanes loop direction depending on the item movement direction
				-- to select the available lane closest to the item;
				-- here either lane with no intervening items or empty lane will be selected
				-- both necessarily visible
				local a, b, dir = table.unpack(down and {0, tr_lane_cnt-1, 1} or {tr_lane_cnt-1, 0, -1})
					for i=a, b, dir do
						if not invalid_lane_indices[i]
						and (not lanes_collapsed or r.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..i) > 0) -- when FIL are collapsed the playing lane is necessarily visible
						then
						next_lane_idx = tr_lane_cnt > 1 and i -- lane index will end up being false if there're no fixed lanes in the target track
						collision = nil
						move_item_func = function(item) MOVE(item, tr, next_lane_idx) end
						break end
					end

					if not collision then break end -- collision var was reset // exit the track loop

				end -- track loop end

				if collision then return end -- abort if collision var hasn't been reset

			end -- collision cond end
	end

return true, next_lane_idx, move_item_func

end



	if not r.GetSelectedMediaItem(0,0) then
	Error_Tooltip('\n\n no selected items \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

------------- NAME TESTING ---------
-- local scr_name = 'down'
------------------------------------

local up, down = scr_name:match('up'), scr_name:match('down')

	if not up and not down then
	Error_Tooltip('\n\n the script name is not recognized \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end

PREVENT_ITEM_COLLISION = PREVENT_ITEM_COLLISION:match('%S')
MOVE_TO_NEXT_AVAILABLE_TRACK_OR_LANE = MOVE_TO_NEXT_AVAILABLE_TRACK_OR_LANE:match('%S')

-- determine loop direction so that if there're items
-- on the adjacent lanes, their relatonship is preserved
-- otherwise the previous item will be moved over the next item
local sel_itms_cnt = r.CountSelectedMediaItems(0)-1
local a, b, dir = table.unpack(down and {sel_itms_cnt, 0, -1}  -- down
or {0, sel_itms_cnt, 1}) -- up

local sel_items = {}
	for i=a, b, dir do
	local item = r.GetSelectedMediaItem(0,i)
	table.insert(sel_items, item)
	end

r.Undo_BeginBlock()
r.PreventUIRefresh(1) -- make toggling item selection unnoticeable

local trim = r.GetToggleCommandStateEx(0, 41117) == 1 -- Options: Trim content behind media items when editing

	if trim then r.Main_OnCommand(41117, 0) end

	for k, item in ipairs(sel_items) do
	r.SelectAllMediaItems(0, false) -- deselect all
	r.SetMediaItemSelected(item, true)
	local tr = r.GetMediaItemTrack(item)
	local lane_idx = r.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
	local FIL_count = r.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES')
	local FIL_On = r.GetMediaTrackInfo_Value(tr, 'I_FREEMODE') == 2
	local FIL_collapsed = r.GetMediaTrackInfo_Value(tr, 'C_LANESCOLLAPSED') > 0
	local lane_vis = r.GetMediaItemInfo_Value(item, 'B_FIXEDLANE_HIDDEN') == 0
	-- 40107 -- Track lanes: Move items down one lane
	-- 40068 -- Track lanes: Move items up one lane
	-- 40118 -- Item edit: Move items/envelope points down one track/a bit
	-- 40117 -- Item edit: Move items/envelope points up one track/a bit
	local ID
		if FIL_count > 1 and FIL_On and not FIL_collapsed then -- move to track or lane
		ID = up and (lane_idx == 0 and 40117 or 40068) or down and (lane_idx == FIL_count-1 and 40118 or 40107)
		elseif FIL_count == 1 or FIL_collapsed and lane_vis then -- move to track
		ID = up and 40117 or 40118
		end
		-- prevent movement down from the last visible track
		-- because the action creates a new track
		if ID and down then
		local tr_cnt = r.GetNumTracks()-1
		local last_tr = r.GetTrack(0, tr_cnt)
		local last_lane = FIL_count == 1 or FIL_count > 1 and lane_idx == FIL_count-1
			if tr == last_tr and last_lane then
			ID = nil
			elseif last_lane then
			ID = nil -- invalidate here to restore below if at least a single visible track is found
			local nxt_tr_idx = r.CSurf_TrackToID(tr, false) -- mpcView false
				for i=nxt_tr_idx, tr_cnt do
				local tr = r.GetTrack(0,i)
					if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1
					then -- at least one other visible track below the current
					ID = 40118
					break
					end
				end
			end
		end
		if ID then
		local retval, next_lane_idx, move_item_func = Get_Next_Lane_Idx(item, lane_idx, tr, ID)
			if retval then -- will be true if can be moved to the next/first available track/lane
			-- next_lane_idx may be false if next track doesn't have multiple lanes

			-- MOVE IMMEDIATELY SO THAT IF ON ADJACENT TRACKS OR LANES
			-- THERE'RE SELECTED ITEMS WHOSE POSITIONS ON THE TIMELINE OVERLAP,
			-- THE DESTINATION OF THE NEXT IN LINE CAN BE ACCURATELY DETERMINED,
			-- BECAUSE IT WILL DEPEND ON THE NEW POSITION OF THE PRECEDING ITEM

			-- address bug where an item formerly located in FIL
			-- causes creation of 256 lanes on the FIL track it's moved to
			-- https://forum.cockos.com/showthread.php?t=309049
			local y = r.GetMediaItemInfo_Value(item, 'F_FREEMODE_Y')
			local h = r.GetMediaItemInfo_Value(item, 'F_FREEMODE_H')
				if y == 0.99609375 and h == 0.00390625 then
				r.SetMediaItemInfo_Value(item, 'F_FREEMODE_Y', 0)
				r.SetMediaItemInfo_Value(item, 'F_FREEMODE_H', 1)
				end
			--[[ -- LESS EFFICIENT THAN USE OF FUNCTIONS ABOVE
			local ret, chunk = r.GetItemStateChunk(item, '', false) -- isundo false
				if chunk:match('YPOS 0.996094 0.003906') then
				chunk = chunk:gsub('YPOS 0.996094 0.003906\n', '')
				r.SetItemStateChunk(item, chunk, false) -- isundo false
				end
			--]]
				if move_item_func then -- the function gets priority because ID will always be valid
				move_item_func(item)
				else
				r.Main_OnCommand(ID, 0)
					if next_lane_idx then
					r.SetMediaItemInfo_Value(item, 'I_FIXEDLANE', next_lane_idx)
					end
				end
			end
		end

	end

	-- reselect all
	for k, item in ipairs(sel_items) do
	r.SetMediaItemSelected(item, true) -- selected true
	r.UpdateItemInProject(item)
	end

	if trim then r.Main_OnCommand(41117, 0) end

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Move selected items '..(up or down)..' one track or fixed lane', -1)



