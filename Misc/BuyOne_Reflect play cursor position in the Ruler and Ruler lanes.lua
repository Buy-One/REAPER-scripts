--[[
ReaScript name: BuyOne_Reflect play cursor position in the Ruler and Ruler lanes.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About: 	The functionality is achieved by linking position
  			of either the edit cursor or a temporary marker or both
  			to the play cursor when the transport is in play mode 
  			(including pause and recording).
  
  			After launch the script will run in the background.
  			To terminate it, launch it again.
  
  			Since ReaScript refresh rate is about 30 ms, that's 
  			the frequency of marker position update, and when 
  			Arrange zoom level is relatively high the marker visibly 
  			lags behind the play cursor.  
  			This problem affects the edit cursor to a much smaller
  			extent.
  
  			The script behavior is configured in the USER SETTINGS
  			below.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- *** MARKER SETTINGS ***

-- Enable by inserting any alphanumeric character
-- between the quotes to have a temporary marker
-- follow the play cursor
MARKER_FOLLOWS = ""

-- Optional
MARKER_NAME = ""

-- Specify marker color in hex format i.e. #F0F0F0;
-- if empty or invalid theme's default marker color
-- will be used
MARKER_COLOR = ""

-- To enable the following settings insert any
-- alphanumeric character between the quotes

-- Enable to apply play cursor color to the marker;
-- the resulting color may not blend in well with
-- the play cursor if modification such as
-- Add, Dodge, Multiply, Overlay etc. is applied
-- to it in the 'Theme development/tweaker' dialogue
-- under 'Play cursor mode'
-- because the script doesn't account for that;
-- the setting overrides MARKER_COLOR setting
USE_PLAY_CURSOR_COLOR = ""

-- Enable to unhide one empty lane in case all are hidden,
-- if some lanes are already visible the marker
-- will be inserted at the top lane,
-- if among hidden lanes there's no empty one, it
-- will be created and made visible, and when playback
-- is stopped or the script is terminated it will
-- be deleted if it's index is below 17 or otherwise
-- hidden because lanes above 16 cannot be deleted
-- with action or ReaScript API;
-- if the setting is disabled and all lanes are hidden
-- the marker will be inserted at the topmost lane
-- but remain hidden as well;
-- the setting is only relevant to REAPER builds
-- 7.62+ where Ruler lanes feature is supported,
-- in older builds the marker will always be visible
SHOW_LANE = "1"


-- *** EDIT CURSOR SETTINGS ***

-- Enable to have the edit cursor follow
-- the play cursor
EDIT_CURSOR_FOLLOWS = "1"

-- Enable to have the edit cursor original
-- position restored once play mode is off
-- of the script is terminated;
-- will only work if the script was launched
-- or was already running before playback
-- has started
RESTORE_EDIT_CUR_POS = "1"


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


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


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+') -- invalid letters
	or not c:match('#%w+') then return '#000000' -- black
	end
return c
end



function Get_Ruler_Lane_Count(want_visible)
-- since as of build 7.65 lane count isn't accessible via API
-- the function uses a hack of creating a temp marker
-- and force moving it to another lane starting from lane
-- at index 100
-- if lane at the destination index doesn't exist the marker
-- is not moved and its original lane index remains the same,
-- but it's moved as soon as a valid lane index is found
-- and since the movement is attempted in reverse,
-- the first lane index associated with successful movement
-- will be the index of the last available lane;
-- alternative function https://forum.cockos.com/showpost.php?p=2928073

	-- only supported since build 7.62
	if not r.GetRegionOrMarker then return end

local lane_count = 0

	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.71 then
	lane_count = r.GetSetProjectInfo(0, 'RULER_LANE_COUNT', 0, false) -- is_set false
	else
	r.PreventUIRefresh(1)
	local index = r.AddProjectMarker(0, false, 0, 0, '', 0xFFFF) -- isrgn false, pos 0, rgnend 0, wantidx 0xFFFF, to be able to easily find it for deletion // insert temp marker
	local obj = r.GetRegionOrMarker(0, 0, '') -- index 0, guidStr empty
	r.SetRegionOrMarkerInfo_Value(0, obj, 'B_HIDDEN', 1) -- hide, although not strictly necessary thanks to PreventUIRefresh()
	local parm = 'I_LANENUMBER'
	local lane_idx_init = r.GetRegionOrMarkerInfo_Value(0, obj, parm)
	local lane_count
		for i=100,0,-1 do -- the max lane count was increased to 48 in build 7.78, so 100 it's a bit much
		r.SetRegionOrMarkerInfo_Value(0, obj, parm, i)
		local lane_idx = r.GetRegionOrMarkerInfo_Value(0, obj, parm)
			if lane_idx ~= lane_idx_init then
			-- if the very last lane is default for markers, the temp marker will be inserted there
			-- and during the loop will only be able to move to a lane at a lower index,
			-- in which case fall back on the original lane index as the heighest
			lane_count = lane_idx < lane_idx_init and lane_idx_init or lane_idx
			break
			end
		end
	r.DeleteProjectMarker(0, index, false) -- isrgn false // delete temp marker
	--r.UpdateTimeline() -- required for proper UI update after change, but unnecessary due to PreventUIRefresh()
	r.PreventUIRefresh(-1)

	-- if there's one lane only the temp marker won't be able to move anywhere
	-- hence fall back on its original lane index
	lane_count = (lane_count or lane_idx_init)+1 -- +1 because lane index returned by GetRegionOrMarkerInfo_Value is 0-based
	end

return lane_count

end



function Get_Lane_Mrkrs_Regns(lane_idx, want_vis)
-- lane_idx can be chosen from lane_count returned by Get_Ruler_Lane_Count()
-- want_vis is boolean to only get visible regions/markers on a visible lane

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local t = {}
	for i=0, r.GetNumRegionsOrMarkers(0)-1 do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local vis = want_vis and Get(0, obj, 'B_VISIBLE') == 1 or not want_vis -- visibility covers both object and its lane visibility
		if vis and Get(0, obj, 'I_LANENUMBER') == lane_idx then
		local st = Get(0, obj, 'D_STARTPOS')
		t[#t+1] = {obj=obj, idx=i, st=st}
		end
	end

return t

end



function Insert_Remove_Marker(mrkr_idx, temp_lane_GUID)
	if not mrkr_idx then
	local playpos = r.GetPlayPosition()
	local col = USE_PLAY_CURSOR_COLOR and r.GetThemeColor('playcursor_color', 0) or MARKER_COLOR -- get default theme color, determined by the settings in the 'Theme development/tweaker' dialogue (NOT in the .ReaperTheme file) ignoring settings in the 'Theme Color Control' dialogue (https://forum.cockos.com/showthread.php?t=291551)
	col = col|0x1000000
	local idx = r.AddProjectMarker2(0, false, playpos, 0, MARKER_NAME, -1, col) -- isrgn false, rgnend 0, wantidx -1 auto
	local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
	local temp_lane_GUID
		if build >= 7.62 then -- OR if r.GetRegionOrMarker
		-- get lane to display the temporary marker on
		local lane_cnt = Get_Ruler_Lane_Count() -- exact count is required to prevent false postives returned by GetSetProjectInfo(), because for every lane index it receives above the actual lane count it may return valid value relevant for an existing lane
		local topmost_vis_lane_idx
			for i=0, lane_cnt-1 do
				if r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0 then -- is_set false // the attribute works without the colon as well
				topmost_vis_lane_idx = i break end
			end
			if not topmost_vis_lane_idx and SHOW_LANE:match('%S') then -- all lanes are hidden
			-- find hidden empty lane
				for i=0, lane_cnt-1 do
				local t = Get_Lane_Mrkrs_Regns(i) -- want_vis nil
					if #t == 0 then -- hidden lane without objects, i.e. empty
					topmost_vis_lane_idx = i break end
				end
				if topmost_vis_lane_idx then -- unhide
				r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..topmost_vis_lane_idx, 0, true) -- is_set true
				local retval
				retval, temp_lane_GUID = r.GetSetProjectInfo_String(0, 'RULER_LANE_GUID:'..topmost_vis_lane_idx, '', false) -- is_set false
				elseif lane_cnt < (build < 7.78 and 16 or 48) then -- 48 lanes is the max as of build 7.78 // create new lane
				r.Main_OnCommand(43541, 0) -- Ruler: Quick add ruler lane // added last
				topmost_vis_lane_idx = lane_cnt
				local retval
				retval, temp_lane_GUID = r.GetSetProjectInfo_String(0, 'RULER_LANE_GUID:'..lane_cnt, '', false) -- is_set false
				else -- lane count is maxed out, unhide first available lane regardless of objects presence on it
				r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:0', 0, true) -- is_set true
				topmost_vis_lane_idx = 0
				end
			end

		-- find marker pointer to move it to the designated lane
		local i, mrkr = 0
			repeat
			local retval, isrgn, pos, rgnend, name, vis_idx, color = r.EnumProjectMarkers3(0,i)
				if retval > 0 and not isrgn and pos == playpos and vis_idx == idx
				and name == MARKER_NAME and color == col then
				mrkr = r.GetRegionOrMarker(0, i, '') -- requires timeline index, not the displayed one
				break end
			i=i+1
			until retval == 0
			if mrkr and topmost_vis_lane_idx then
			r.SetRegionOrMarkerInfo_Value(0, mrkr, 'I_LANENUMBER', topmost_vis_lane_idx) -- move to lane
			end

		end
	return idx, temp_lane_GUID
	else

	r.DeleteProjectMarker(0, mrkr_idx, false) -- isrgn false
		if temp_lane_GUID then -- hide lane
		local lane_idx = r.GetSetProjectInfo(0, 'RULER_LANE_FROM_GUID:'..temp_lane_GUID, 0, false) -- is_set false
			if lane_idx and lane_idx < 16 then -- delete
			local ID = 43524 + lane_idx -- only first 16 lanes can be deleted with action, no API to delete a lane
			r.Main_OnCommand(ID, 0) -- Ruler: Delete ruler lane X
			elseif lane_idx then -- hide
			-- during defer loop, the lane isn't hidden if Ruler lane manager is open, so toggle close-open
			-- this however couldn't be reproduced with a mininal script
			local open = r.GetToggleCommandStateEx(0, 43542) == 1 -- Ruler: Ruler lane manager...
				if open then r.Main_OnCommand(43542, 0) end
			r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..lane_idx, 1, true) -- is_set true
				if open then r.Main_OnCommand(43542, 0) end
			end
		end
	end
end



function Follow_Play_Cursor(mrkr_idx)
	if mrkr_idx then
	r.SetProjectMarker(mrkr_idx, false, r.GetPlayPosition(), 0, MARKER_NAME) -- isrgn false, rgnend 0
	end
end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function cleanup(sect_ID, cmd_ID, mrkr_idx, temp_lane_GUID, pos)
Re_Set_Toggle_State(sect_ID, cmd_ID, 0)
	if playing then -- only clean marker/lane, unless stopped because the cleanup is performed on stop as well
		if mrkr_idx then r.DeleteProjectMarker(0, mrkr_idx, false) end -- isrgn false
		if temp_lane_GUID then -- hide lane
		local lane_idx = r.GetSetProjectInfo(0, 'RULER_LANE_FROM_GUID:'..temp_lane_GUID, 0, false) -- is_set false
			if lane_idx and lane_idx > 15 then -- delete
			local ID = 43524 + lane_idx -- only first 16 lanes can be deleted with action, no API to delete a lane
			r.Main_OnCommand(ID, 0) -- Ruler: Delete ruler lane X
			elseif lane_idx then -- hide
			-- during defer loop, the lane isn't hidden if Ruler lane manager is open, so toggle close-open
			-- this however couldn't be reproduced with a mininal script
			local open = r.GetToggleCommandStateEx(0, 43542) == 1 -- Ruler: Ruler lane manager...
				if open then r.Main_OnCommand(43542, 0) end
			r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..lane_idx, 1, true) -- is_set true
				if open then r.Main_OnCommand(43542, 0) end
			end
		end
	end
-- cursor pos doesn't need restoration at script exit
-- because if transport was stopped beforehand
-- it would be restored in the defer loop, but if playback
-- is still active, at exit the cursor must remain at its
-- latest synced position, looks more natural
end


function sync()

local state = r.GetPlayState()

	if state&1 == 1 then -- playing
		if MARKER_FOLLOWS then -- insert
		mrkr_idx, temp_lane_GUID = table.unpack(mrkr_idx and {mrkr_idx or false, temp_lane_GUID or false}
		or {Insert_Remove_Marker()})
		Follow_Play_Cursor(mrkr_idx)
		end
		if EDIT_CURSOR_FOLLOWS then
		r.Main_OnCommand(40434, 0) -- View: Move edit cursor to play cursor
		end
	playing = 1
	else
		if playing and MARKER_FOLLOWS and mrkr_idx then
		Insert_Remove_Marker(mrkr_idx, temp_lane_GUID) -- remove
		end
		if EDIT_CURSOR_FOLLOWS and RESTORE_EDIT_CUR_POS then
		pos = pos or r.GetCursorPosition()
			if playing and pos then
			r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
			end
		end
	playing, mrkr_idx = nil, nil
	end

r.defer(sync)

end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

	if r.set_action_options then r.set_action_options(1) end -- allow terminating the script by launching it again

Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

MARKER_FOLLOWS = MARKER_FOLLOWS:match('%S')
EDIT_CURSOR_FOLLOWS = EDIT_CURSOR_FOLLOWS:match('%S')
RESTORE_EDIT_CUR_POS = RESTORE_EDIT_CUR_POS:match('%S')
USE_PLAY_CURSOR_COLOR = USE_PLAY_CURSOR_COLOR:match('%S')

	if not USE_PLAY_CURSOR_COLOR then
	MARKER_COLOR = Validate_HEX_Color_Setting(MARKER_COLOR)
	MARKER_COLOR = r.ColorToNative(hex2rgb(MARKER_COLOR))
	end


sync()


r.atexit(function() cleanup(sect_ID, cmd_ID, mrkr_idx, temp_lane_GUID, pos) end)

