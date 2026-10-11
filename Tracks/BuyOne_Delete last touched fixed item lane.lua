--[[
ReaScript name: BuyOne_Delete last touched fixed item lane.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	Script complementing native lane delete actions.

		Be aware that the script overwrites the clipboard.
]]


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


function no_undo()
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
	elseif t --and #t > 0
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



function Get_Last_Touched_Fixed_Item_Lane()
-- the function takes advantage of the fact
-- that with the paste action items are pasted
-- to the last touched lane;
-- last touched lane doesn't change if lane enable
-- button is clicked

	local function re_store_selected_items(t, keep_last_selected)
	-- at the restoration stage when evaluating whether any items
	-- were saved into the table, 'if next(t) then' statement is used
	-- because the table isn't indexed and 'if #t > 0 then' won't work
		if not t then
		local t = {}
			for i=0, r.CountMediaItems(0)-1 do
			local item = r.GetMediaItem(0,i)
				if r.IsMediaItemSelected(item) then
				t[item] = '' -- dummy entry
				end
			end
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		return t
		elseif t and next(t) then
			if not keep_last_selected then
			r.SelectAllMediaItems(0, false) -- selected false // deselect all
			end
			for item in pairs(t) do
			r.SetMediaItemSelected(item, true) -- selected true
			end
		end
	r.UpdateArrange()
	end

	local function act(ID)
	r.Main_OnCommand(ID, 0) -- Options: Trim content behind media items when editing
	end

local trim = r.GetToggleCommandStateEx(0, 41117) == 1 -- Options: Trim content behind media items when editing
	if trim then act(41117) end -- set to off to prevent overwriting items inder the pasted temporary item

-- store current item pointers
local t = {}
	for i=0, r.CountMediaItems(0)-1 do
	t[r.GetMediaItem(0,i)] = ''
	end
-- store selected items and clear selection to restore later
-- the selection is cleared so that only the temporary items
-- end up being selected, copied and pasted
local sel_itms = re_store_selected_items()
local tr = r.GetLastTouchedTrack()
-- insert temporary item on the last touched track,
-- by the function the item is always inserted in the last lane
-- so by itself the item is useless
local item = r.AddMediaItemToTrack(tr)
r.SetMediaItemSelected(item, true) -- selected true
act(40698) -- Edit: Copy items
r.DeleteTrackMediaItem(tr, item) -- delete temporary item
act(42398) -- Item: Paste items/tracks // paste copied item to the last touched track
local item = r.GetSelectedMediaItem(0,0) -- the pasted item is exclusively selected
local lane = r.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
r.DeleteTrackMediaItem(tr, item) -- delete pasted item
re_store_selected_items(sel_itms) -- restore original item selection

	if trim then act(41117) end -- restore On toggle state

return tr, lane

end


local tr, lane_idx = Get_Last_Touched_Fixed_Item_Lane()

	if not lane_idx then
	Error_Tooltip('\n\n no last touched lane \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end
	
	
local lane_cnt = r.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES')
local t = {}

	for i=0, lane_cnt-1 do
	table.insert(t, r.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..i) > 0)
	end
	

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local sel_tracks_t = re_store_sel_trks()
 
r.SetOnlyTrackSelected(tr) -- select track exclusively so that action doesn't affect other selected tracks
r.SetMediaTrackInfo_Value(tr, 'C_ALLLANESPLAY', 1) -- set all play
r.SetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..lane_idx, 0) -- turn lane off
r.Main_OnCommand(42691, 0) -- Track lanes: Delete lanes (including media items) that are not playing
table.remove(t, lane_idx+1) -- remove playstate field of the deleted lane from the table storing their playstates //  +1 because in this table indices match lane indices in 1-based count

-- restore play state of the remaining lanes
local multiplay
	for idx, playing in ipairs(t) do
	local mode = playing and (multiplay and 2 or 1) or 0 -- when more than a single lane plays, all subsequent playing lanes play mode must be 2 (multi-lane playing) otherwise they will be set exclusively playing
	r.SetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..idx-1, mode) -- -1 because in this table indices match lane indices in 1-based count
	multiplay = multiplay or playing
	end

re_store_sel_trks(sel_tracks_t)	
	
r.TrackList_AdjustWindows(true) -- isMinor, TCP only
r.PreventUIRefresh(-1)
r.Undo_EndBlock('Delete last touched fixed item lane', -1)






