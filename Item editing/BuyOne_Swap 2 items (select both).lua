--[[
ReaScript name: BuyOne_Swap 2 items (select both).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 	#Did away with SWS extension dependency
			#Fixed item swap on the same track
			#Ensured preservation of original track and item selection, edit cursor position
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	Whether track envelopes and automation items
		follow the swapped media items depends on the option
		'Options: Move envelope points with media items'
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


function ACT(comm_ID)
-- both string and integer work
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end



function re_store_sel_trks(t)
-- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do -- not >= 0 because sel_trk_cnt is not reduced by 1, i-1 is on the next line
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- selected 0 or false // unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t and #t > 0
	then
	r.PreventUIRefresh(1)
	-- deselect all tracks, this ensures that if none was selected originally
	-- none will end up selected because re-selection loop below won't start
	--	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	-- OR
	local master = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master) -- select master
	r.SetTrackSelected(master, 0) -- immediately deselect
		for _,v in next, t do
		r.SetTrackSelected(v,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
	end
end



local function vertically()

-- without SWS actions
-- ReaScript API functions are wrapped in anonymous function to prevent their execusion as table is constructed
local t = {
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetTrackSelected(item2_track, true) end, -- selected true
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
function() r.SetOnlyTrackSelected(item1_track) end,
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
function() r.SetOnlyTrackSelected(item2_track) end,
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40001, -- Track: Insert new track
40118, -- Item edit: Move items/envelope points down one track/a bit
function() r.SetOnlyTrackSelected(item2_track) end,
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
40285, -- Track: Go to next track // temp track
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
40005, -- Track: Remove tracks // remove temp track
function() r.SetOnlyTrackSelected(item1_track) end,
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
}

	for _, id in ipairs(t) do
		if tonumber(id) then ACT(id)
		else id() end
	end

end



local function horizontally()

-- without SWS actions
-- ReaScript API functions are wrapped in anonymous function to prevent their execusion as table is constructed
local cur_pos1, cur_pos2 = 0,0
local t = {
function() r.SetOnlyTrackSelected(item1_track) end,
41173, -- Item navigation: Move cursor to start of items
function() cur_pos1 = r.GetCursorPosition() end,
not adjacent and 40319, -- Item navigation: Move cursor right to edge of item
40319, -- Item navigation: Move cursor right to edge of item
function() cur_pos2 = r.GetCursorPosition() end,
40289, -- Item: Unselect all items
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
function() r.SetEditCurPos(cur_pos1, false, false) end, -- moveview, seekplay false
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40001, -- Track: Insert new track
40118, -- Item edit: Move items/envelope points down one track/a bit
function() r.SetOnlyTrackSelected(item1_track) end,
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
40285, -- Track: Go to next track // temp track
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
40005, -- Track: Remove tracks // remove temp track
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetEditCurPos(cur_pos2, false, false) end, -- moveview, seekplay false
42398, -- Item: Paste items/tracks
function() r.SetEditCurPos(cur_pos1, false, false) end, -- moveview, seekplay false
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
}

	for _, id in ipairs(t) do
		if id then
			if tonumber(id) then ACT(id)
			else id() end
		end
	end

end



local function diagonally_bottom_top() -- alignment /

-- without SWS actions
-- ReaScript API functions are wrapped in anonymous function to prevent their execusion as table is constructed
local cur_pos1, cur_pos2 = 0,0
local t = {
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetTrackSelected(item2_track, true) end, -- selected true
41173, -- Item navigation: Move cursor to start of items
function() cur_pos1 = r.GetCursorPosition() end,
40319, -- Item navigation: Move cursor right to edge of item
not overlap and 40319, -- Item navigation: Move cursor right to edge of item
function() cur_pos2 = r.GetCursorPosition() end,
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
function() r.SetOnlyTrackSelected(item2_track) end,
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetEditCurPos(cur_pos2, false, false) end, -- moveview, seekplay false
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40001, -- Track: Insert new track
40118, -- Item edit: Move items/envelope points down one track/a bit
function() r.SetOnlyTrackSelected(item1_track) end,
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
40285, -- Track: Go to next track // temp track
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
40005, -- Track: Remove tracks // remove temp track
function() r.SetOnlyTrackSelected(item2_track) end,
function() r.SetEditCurPos(cur_pos1, false, false) end, -- moveview, seekplay false
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
}

	for _, id in ipairs(t) do
		if id then
			if tonumber(id) then ACT(id)
			else id() end
		end
	end

end



local function diagonally_top_bottom() -- alignment \

-- without SWS actions
-- ReaScript API functions are wrapped in anonymous function to prevent their execusion as table is constructed
local cur_pos1, cur_pos2 = 0,0
local t = {
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetTrackSelected(item2_track, true) end, -- selected true
41173, -- Item navigation: Move cursor to start of items
function() cur_pos1 = r.GetCursorPosition() end,
40319, -- Item navigation: Move cursor right to edge of item
not overlap and 40319, -- Item navigation: Move cursor right to edge of item
function() cur_pos2 = r.GetCursorPosition() end,
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
function() r.SetOnlyTrackSelected(item1_track) end,
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
function() r.SetOnlyTrackSelected(item2_track) end,
function() r.SetEditCurPos(cur_pos2, false, false) end, -- moveview, seekplay false
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40001, -- Track: Insert new track
40118, -- Item edit: Move items/envelope points down one track/a bit
function() r.SetOnlyTrackSelected(item2_track) end,
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
40289, -- Item: Unselect all items
40285, -- Track: Go to next track // temp track
41666, -- View: Move cursor left 8 pixels
40417, -- Item navigation: Select and move to next item
40699, -- Edit: Cut items
40005, -- Track: Remove tracks // remove temp track
function() r.SetOnlyTrackSelected(item1_track) end,
function() r.SetEditCurPos(cur_pos1, false, false) end, -- moveview, seekplay false
42398, -- Item: Paste items/tracks
41173, -- Item navigation: Move cursor to start of items
}

	for _, id in ipairs(t) do
		if id then
			if tonumber(id) then ACT(id)
			else id() end
		end
	end

end





local item1 = r.GetSelectedMediaItem(0,0)
item1_track = r.GetMediaItemTrack(item1) -- must be global to be accessible inside functions
local item1_pos = r.GetMediaItemInfo_Value(item1, "D_POSITION")
local item1_end = r.GetMediaItemInfo_Value(item1, "D_LENGTH") + item1_pos
local item2 = r.GetSelectedMediaItem(0,1)
item2_track = r.GetMediaItemTrack(item2) -- must be global to be accessible inside functions
local item2_pos = r.GetMediaItemInfo_Value(item2, "D_POSITION")
local item2_end = r.GetMediaItemInfo_Value(item2, "D_LENGTH") + item2_pos

local itms_cnt = r.CountSelectedMediaItems(0)
local error_mess = itms_cnt == 0 and "No items selected."
or itms_cnt ~= 2 and "Exactly 2 items must be selected."
or item1_track == item2_track and item2_pos < item1_end and 'Items are overlapping.'

	if error_mess then r.MB(error_mess,"ERROR",0) return r.defer(no_undo) end


local GetToggle = r.GetToggleCommandStateEx


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local group = GetToggle(0, 1156) == 1 -- Options: Toggle item grouping override
	if group then ACT(1156) end -- Options: Toggle item grouping override (set to OFF)

local ripple_per_track = GetToggle(0, 41990) == 1 -- Toggle ripple editing per-track
local ripple_all_tracks = GetToggle(0, 41991) == 1 -- Toggle ripple editing all tracks

	if ripple_per_track or ripple_all_tracks
	then ACT(40309) -- Set ripple editing off
	end

local t = re_store_sel_trks()
local cur_pos = r.GetCursorPosition()


	if item1_pos == item2_pos and item1_track ~= item2_track then
	vertically(); undo = "items vertically"
	elseif item1_pos ~= item2_pos then
		if item1_track == item2_track then
			if item1_end == item2_pos then adjacent = true end
		horizontally(); undo = "items horizontally"
		elseif item1_track ~= item2_track then
			if item1_pos > item2_pos then
				if item1_pos > item2_end then
				undo = "items diagonally /"
				else overlap = true;
				undo = "overlapping items diagonally /"
				end
			diagonally_bottom_top()
			elseif item1_pos < item2_pos then
				if item2_pos > item1_end then
				 undo = "items diagonally \\"
				else
				overlap = true;
				undo = "overlapping items diagonally \\"
				end
			diagonally_top_bottom()
			end
		end
	end

	if group then ACT(1156) end -- Options: Toggle item grouping override (set back to ON)

	-- Re-enable Ripple mode
	if ripple_per_track then ACT(40310) -- Set ripple editing per-track
	elseif ripple_all_tracks then ACT(40311) -- Set ripple editing all tracks
	end

re_store_sel_trks(t)
-- restore selection of both items
r.SetMediaItemSelected(item1, true) -- selected true
r.SetMediaItemSelected(item2, true) -- selected true
r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false

r.Undo_EndBlock("Swap 2 "..undo,-1)
r.PreventUIRefresh(-1)

