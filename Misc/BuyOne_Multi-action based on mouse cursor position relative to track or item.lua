--[[
ReaScript name: BuyOne_Multi-action based on mouse cursor position relative to track or item.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI
About: 	The script allows running up to 14 different actions/functions depending
    		on the mouse cursor position relative to track/item/envelope lane which are
    		divided into segments (maximum 3), and subdivided into slots if number 
    		of enabled slots exceeds the number of segments.  
    		
    		Setup instructions see in the USER SETTINGS.
    		
    		If action slot locations are incorrect on Mac, submit a bug report at the 
    		addresses listed in the Website tag above and this will be looked into.
    		
    		Bind to a shortcut so that the mouse cursor isn't engaged in clicking
    		a toolbar button or a menu item. It's not recommented biding it to mouse
    		modifiers in Media item / Track / Envelope control panel and Envelope
    		lane contexts because it will prevent running actions meant for other 
    		contexs or locations.
    		
    		If you're going to use the script in the MIDI Editor as well, in which
    		case it doesn't have to be located in the MIDI Editor section of the 
    		Action list, make sure that the shortcut which the script is mapped to
    		in the Main section of the Action list isn't already used in the MIDI Editor 
    		section of the Action list because the latter will take priority and 
    		instead of the script you'll be running another action.

]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- [OBJECT]_SEGMENTS setting divides item/TCP under the mouse cursor
-- into horizontal segments, i.e. ≡.
-- If number of enabled slots is equal or smaller than the number
-- of segments defined in the [OBJECT]_SEGMENTS setting, slot area
-- will be identical to the entire segment area.

-- For items:
-- If number of enabled slots is greater than the number of defined
-- segments, each segment is divided into two to accommodate one extra
-- slot such that each slot is allocated the edge of the segment while
-- the middle of a segment which has been divided into two is not
-- recognized by the script.
-- There're two modes of slot allocation which depend on
-- ALLOCATE_SEQUENTIALLY setting below.
-- To target an action associated with a slot allocated to the edge
-- of a segment the mouse cursor must be placed near item edge inside
-- the item bounds within the limits of the segment height.
-- The number of takes in an item has no bearing on the slot layout
-- and item is always treated as a whole.
-- For tracks:
-- If number of enabled slots is greater than the number of defined
-- segments, new segments are created from top to bottom within Arrange
-- opposite of the TCP of the track under the mouse cursor. Their height
-- is the same as that of the segments within the TCP.

-- !!!! At the bottom of this script see slot map which illustrates all
-- possible slot layouts.

-- When number of enabled slots is smaller than the number of segments,
-- the extra segments will capture mouse cursor hits but won't trigger
-- any action, a message will be displayed instead.

-- Slots are allocated starting from the first enabled slot in the list
-- of the SLOT settings which can have gaps between them and the first
-- enabled slot doesn't have to be SLOT1, so the actual slot order is
-- determined not by SLOT setting number but by the order in which they
-- are enabled, however be aware that if later you enable slots above
-- or in between, the slot layout will change and so the location of the
-- slots you may have gotten used to, therefore to keep the layout as
-- consistent as possible enable SLOT settings sequentially.

-- There're two ways to disable actions over an object:
-- either by keeping [OBJECT]_SEGMENTS setting empty or if it's
-- not empty - by keeping all SLOT settings empty.

----------------------- ITEM -----------------------

-- If ITEM_SEGMENTS setting isn't empty or if it's empty
-- and at least one item slot is enabled, track slots cannot
-- be targeted while the mouse cursor hovers over an item
-- in case there're enabled track slots within Arrange.

-- Max value is 3, which seems to be optimal,
-- if invalid, such as 0, a negative, decimal, not base-10
-- number, not a number, defaults to 1;
-- if greater than 3 defaults to 3;
-- if empty invalidates all ITEM_SLOT settings
ITEM_SEGMENTS = "3"

-- Enable by inserting any alphanumeric character between the quotes;
-- only relevant when the number of enabled SLOT settings
-- is greater than the number of segments specified above;
-- when this is the case in order to accommodate enabled
-- slots the segments are split into two, and the number
-- of such split segments depends on the number of additional
-- slots which must be accommodated, e.g. if there're 2 or 3
-- segments and there's only 1 enabled extra slot, only the
-- top segment will be split into two;
-- when this setting is enabled allocation of slots is done
-- in the order in which they're enabled in the script,
-- e.g. if there're 2 segments and 2 extra slots, the slots
-- will be allocated between segments as follows:
-- 1st enabled slot - top segment left edge
-- 2nd enabled slot - top segment right edge
-- 3d enabled slot (extra) - bottom segment left edge
-- 4th enabled slot (extra) - bottom segment right edge,
-- which means that the segment the 2nd slot is associated with
-- will change relative to the one it had been associated with before
-- extra slots were enabled, which would be the bottom segment;
-- on the other hand if the setting is not enabled the allocation
-- is done 'as required' so to speak, the original association between
-- slots and segments won't change, only their location which comes
-- to be the segment left edge after segment split, while the extra
-- enabled slots are assigned the segment right edge from top to bottom,
-- so in the scenario decribed above the allocation would be as follows:
-- 1st enabled slot - top segment left edge
-- 2nd enabled slot - bottom segment left edge
-- 3d enabled slot (extra) - top segment right edge
-- 4th enabled slot (extra) - bottom segment right edge;
-- see graphic illustration of the difference between these two modes
-- at the bottom of this script
ALLOCATE_SEQUENTIALLY = ""

-- To enable insert an action/script command ID or a function name;
-- disabled when empty or invalid;
-- if 0 is insetred instead, the slot will ony have an area
-- allocated to it without any action/function being associated
-- with it;
-- if a function is going to be used it's recommended to declare
-- it in the USER FUNCTIONS section below so as to not mix
-- user functions with those native to this script
ITEM_SLOT1 = ""

-- Enable by inserting any alphanumeric character between the quotes
-- if the native / SWS (cycle) action whose command ID
-- is specified in the previous ITEM_SLOT setting is located
-- in the MIDI Editor section of the Action list
-- because via API there's no way to determine theirs
-- and SWS actions association with a particular
-- Action list section;
-- will be ignored if previous ITEM_SLOT setting contains
-- a custom action / script command ID because these allow
-- to determine the section they reside in
ITEM_SLOT1_midi = ""

-- If a function name is specified in the SLOT setting above
-- and such function accepts arguments, list the arguments
-- in this setting between the braces delimited by comma
-- e.g. {1, 10.4, true, "name", false, nil} etc.
ITEM_SLOT1_args = {}

-- The name of the action you want to be listed
-- in the Undo history;
-- only relevant if ITEM_SLOT setting above references a function
-- because actions/scripts will create their own Undo point;
-- if empty, the function name will be used;
-- if your function is designed to create an undo point
-- because the undo point name depends on certain conditions,
-- insert 0 here so that the function based undo point name is used
ITEM_SLOT1_undo = ""
-------------------------

ITEM_SLOT2 = "Hello_World"
ITEM_SLOT2_midi = ""
ITEM_SLOT2_args = {'Item \t Hello World!!!'}
ITEM_SLOT2_undo = ""
-------------------------
ITEM_SLOT3 = ""
ITEM_SLOT3_midi = ""
ITEM_SLOT3_args = {}
ITEM_SLOT3_undo = ""
-------------------------
ITEM_SLOT4 = ""
ITEM_SLOT4_midi = ""
ITEM_SLOT4_args = {}
ITEM_SLOT4_undo = ""
-------------------------
ITEM_SLOT5 = ""
ITEM_SLOT5_midi = ""
ITEM_SLOT5_args = {}
ITEM_SLOT5_undo = ""
-------------------------
ITEM_SLOT6 = ""
ITEM_SLOT6_midi = ""
ITEM_SLOT6_args = {}
ITEM_SLOT6_undo = ""

----------------------- TRACK -----------------------

-- If ITEM_SEGMENTS setting is empty or if it's not empty
-- and no item slot is enabled, and there're more than
-- 3 enabled TRACK_SLOT settings, the 4th - 6th track slots
-- will be recognized within Arrange even if the mouse
-- hovers over an item

-- Explanation for the following settings
-- is the same as for ITEM settings mutatis mutandis;
-- track SLOTS don't have ALLOCATE_SEQUENTIALLY setting
-- because enabled slots which exceed the number of segments
-- are always allocated to the Arrange area of the track,
-- which is how item slots are allocated when
-- ALLOCATE_SEQUENTIALLY is not enabled if we think
-- of TCP and Arrange sides of the track as two sides
-- of a split track segment

TRACK_SEGMENTS = "3"

TRACK_SLOT1 = "Hello_World"
TRACK_SLOT1_midi = ""
TRACK_SLOT1_args = {'Track \t Hello World!!!'}
TRACK_SLOT1_undo = ""
-------------------------
TRACK_SLOT2 = ""
TRACK_SLOT2_midi = ""
TRACK_SLOT2_args = {}
TRACK_SLOT2_undo = ""
-------------------------
TRACK_SLOT3 = ""
TRACK_SLOT3_midi = ""
TRACK_SLOT3_args = {}
TRACK_SLOT3_undo = ""
-------------------------
TRACK_SLOT4 = ""
TRACK_SLOT4_midi = ""
TRACK_SLOT4_args = {}
TRACK_SLOT4_undo = ""
-------------------------
TRACK_SLOT5 = ""
TRACK_SLOT5_midi = ""
TRACK_SLOT5_args = {}
TRACK_SLOT5_undo = ""
-------------------------
TRACK_SLOT6 = ""
TRACK_SLOT6_midi = ""
TRACK_SLOT6_args = {}
TRACK_SLOT6_undo = ""

--------------------- ENVELOPE ---------------------

-- Only two slots are possible:
-- the 1st enabled one is allocated to the entire
-- envelope control panel (ECP) regardless of the number
-- of open envelopes, the 2nd one - to the entire
-- time line within the limits of the combined ECP height
-- of all open envelopes,
-- see slot map at the bottom of this script

ENV_SLOT1 = "0"
ENV_SLOT1_midi = ""
ENV_SLOT1_args = {}
ENV_SLOT1_undo = ""
-------------------------
ENV_SLOT2 = "Hello_World"
ENV_SLOT2_midi = ""
ENV_SLOT2_args = {'Env Hello World!!!'}
ENV_SLOT2_undo = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
------------------------------ USER FUNCTIONS -------------------------------
-----------------------------------------------------------------------------

-- Your functions go here, they must be global to be visible to the script

function Hello_World(arg)
reaper.MB(arg, 'FUNCTION TEST', 0)
end


-----------------------------------------------------------------------------
-------------------------- END OF USER FUNCTIONS ----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function undo_block(undo) -- undo arg is a string, which isn't used at the beginning of the block and only used at its end
	if not undo then r.Undo_BeginBlock()
	else r.Undo_EndBlock(undo, -1)
	end
end


function Error_Tooltip(text, caps, spaced, x2) -- caps and spaced are booleans, x2 is integer
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2 = x2 and math.floor(x2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end



function Get_Arrange_and_Header_Heights()

local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

	if sws or js then -- if SWS/js_ReaScriptAPI ext is installed
	-- thanks to Mespotine https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/blob/master/ultraschall_api/misc/misc_docs/Reaper-Windows-ChildIDs.txt
	local main_wnd = r.GetMainHwnd()
	-- trackview wnd height includes bottom scroll bar, which is equal to track 100% max height + 17 px, also changes depending on the header height and presence of the bottom docker
	local arrange_wnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, '', 'trackview', false, true) -- search by window name // OR r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, 'REAPERTrackListWindow', '', true, false) -- search by window class name
	or js and r.JS_Window_Find('trackview', true) -- exact true // OR r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000)
	local retval, rt1, top1, lt1, bot1 = table.unpack(sws and {r.BR_Win32_GetWindowRect(arrange_wnd)}
	or js and {r.JS_Window_GetRect(arrange_wnd)})
	local retval, rt2, top2, lt2, bot2 = table.unpack(sws and {r.BR_Win32_GetWindowRect(main_wnd)} or js and {r.JS_Window_GetRect(main_wnd)})
	local top2 = top2 == -4 and 0 or top2 -- top2 can be negative (-4) if window is maximized
	local arrange_h, header_h, wnd_h_offset = bot1-top1-17, top1-top2, top2  -- !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
	return bot_t, arrange_h, header_h, wnd_h_offset -- bot_t is nil used to conform with the design so that there're 4 return values, arrange_h tends to be 1 px smaller than the one obtained via calculations following 'View: Toggle track zoom to maximum height' when extensions aren't installed, using 16 px instead of 17 fixes the discrepancy
	end

end


function Get_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end



function Get_Item_Edge_At_Mouse() -- Combined with Get_Arrange_and_Header_Heights2() can be used to get 4 item corners at the mouse cursor
local cur_pos = r.GetCursorPosition()
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x,y, false) -- allow_locked false
local left_edge, right_edge
	if item then
	r.PreventUIRefresh(1)
	local px_per_sec = r.GetHZoomLevel() -- 100 px per 1 sec = 1 px per 0.01 sec or 10 ms
	local left = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local right = left + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	r.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping)
	local new_cur_pos = r.GetCursorPosition()
		if math.abs(left - new_cur_pos) <= 0.01*(1000/px_per_sec) -- condition the minimal distance by the zoom resolution, the greater the zoom-in the smaller is the required distance, the base value of 10 ms or 1 px which is valid for zoom at 100 px per 1 sec seems optimal, 1000/px_per_sec is ms per pixel; OR 0.01/(px_per_sec/1000) px_per_sec/1000 is pixels per ms // only cursor position inside item is respected
		then
		left_edge = true
		elseif math.abs(right - new_cur_pos) <= 0.01*(1000/px_per_sec) then
		right_edge = true
		end
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit cursor pos
	r.PreventUIRefresh(-1)
	end
return left_edge, right_edge
end


function Collect_Valid_Slots(...)
local t = {...}
	for idx, slot in ipairs(t) do
	t[idx] = #slot:gsub(' ','') > 0 and {slot_idx=idx, action=slot} -- storing slot index to be able to associate other settings with it since slots can be enabled non-sequentially and not from the 1st one in which case the table own indices won't correspond to those of the slots due to removal of invalid slots below, 0 is considered a valid setting to be able to exclude certain slots while keeping the slot layout
	end
	for i = #t,1,-1 do -- remove invalid slots
		if not t[i] then -- false
		table.remove(t,i)
		end
	end
return t
end


function Get_Disabled_Slots(t)
	for idx, slot in ipairs(t) do
		if slot.action:gsub(' ','') ~= '0'
		then return end
	end
return true
end


function Get_Item_Track_Segment_At_Mouse(header_h, wnd_h_offset, want_item, want_takes) -- horizontal segments, targets item or track under mouse cursor, supports overlapping items displayed in lanes // want_item is boolean in which case item under mouse is considered otherwise segments will be valid along the entire time line for the track under mouse; want_takes is boolean and only relevant if want_item is true, if true and the item arg is true and the item is multi-take, each take will be divided into 2 segments

local x, y = r.GetMousePosition()
-- itm_slots_t length evaluation conditions below allow targeting track segments within Arrange over the item if no item slot is enabled, i.e. don't contain action ID or 0, while track slots are
local item, take = table.unpack(want_item and #itm_slots_t > 0 and {r.GetItemFromPoint(x, y, false)} or {nil}) -- allow_locked false
local tr, info = table.unpack((not item or #itm_slots_t == 0) and {r.GetTrackFromPoint(x, y)} or {nil})
local env = info == 1

	if item then -- without item the segments would be relevant for the track along the entire timeline which is also useful, in which case item parameters aren't needed; if limited to TCP with Get_TCP_Under_Mouse() can be used to divide TCP to segments;
	local tr = r.GetMediaItemTrack(item)
	local tr_y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
	local tr_h = r.GetMediaTrackInfo_Value(tr, 'I_TCPH') -- no envelopes
	local itm_y = r.GetMediaItemInfo_Value(item, 'I_LASTY') -- within track
	local itm_h = r.GetMediaItemInfo_Value(item, 'I_LASTH')
	local take_cnt = r.CountTakes(item)
	local tr_y_glob = tr_y + header_h + wnd_h_offset -- distance between the screen top and the track top edge accounting for shrunk program window if sws extension is installed
	local itm_y_glob = tr_y_glob + itm_y -- distance between the screen top and the item top edge
	local itm_h_glob = itm_y_glob + itm_h -- distance between the screen top and the item bottom edge // only needed if table isn't used below
		if take_cnt == 1 or take_cnt > 1 and not want_takes then
		local itm_segm_h = itm_h/ITEM_SEGMENTS -- item segment height // can be divided by more or less than 3 in which case the following vars and return values must be adjusted accordingly
		--[[ if the table isn't used
		local segm_bot = y <= itm_h_glob and y >= itm_h_glob - itm_segm_h
		local segm_mid = y <= itm_h_glob - itm_segm_h and y >= itm_h_glob - itm_segm_h*2
		local segm_top = y <= itm_h_glob - itm_segm_h*2 and y >= itm_h_glob - itm_h
		return segm_top, segm_mid, segm_bot
		--]]
		--[-[ OR same as for takes below
		local t = {}
			for i = 1, ITEM_SEGMENTS do
			t[i] = y >= itm_y_glob+itm_segm_h*(i-1) and y <= itm_y_glob+itm_segm_h*i
			end
		return t
		--]]

		elseif take_cnt > 1 and want_takes then -- UNUSED IN THIS SCRIPT
		local itm_segm_h = itm_h/take_cnt/2 -- two segments per take, can be more
		local segm_cnt = 2*take_cnt -- multiply by segments per take
		local t = {}
			for i = 1, segm_cnt do -- store truth and falsehood
			t[i] = y >= itm_y_glob+itm_segm_h*(i-1) and y <= itm_y_glob+itm_segm_h*i
			end
		return t
		end
--	elseif not want_item and tr then -- do not target track when want_item is true // AN OPTION
	elseif tr then -- if limited to TCP with Get_TCP_Under_Mouse() can be used to divide TCP to segments
	local tr_y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
	local tr_h = r.GetMediaTrackInfo_Value(tr, 'I_TCPH') -- no envelopes
	local tr_h_env = r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- with envelopes
	local tr_y_glob = tr_y + header_h + wnd_h_offset -- distance between the program window top and the track top edge
	local t = {}
		if env then t[1] = y >= tr_y_glob+tr_h and y <= tr_y_glob+tr_h_env -- using table for the sake of unifomity
		else
		local tr_segm_h = tr_h/TRACK_SEGMENTS -- 3 segments, or more or less
			for i = 1, TRACK_SEGMENTS do -- store truth and falsehood
			t[i] = y >= tr_y_glob+tr_segm_h*(i-1) and y <= tr_y_glob+tr_segm_h*i
			end
		end
	return t
	end

end


function MIDIEditor_GetActiveAndVisible()
-- solution to the problem described at https://forum.cockos.com/showthread.php?t=278871
local ME = r.MIDIEditor_GetActive()
local dockermode_idx, floating = r.DockIsChildOfDock(ME) -- floating is true regardless of the floating docker visibility
-- OR
-- local floating = r.DockGetPosition(dockermode_idx) == 4 -- another way to evaluate if docker is floating
-- the MIDI Editor is either not docked or docked in an open docker attached to the main window
	if ME and (dockermode_idx == -1 or dockermode_idx > -1 and not floating
	and r.GetToggleCommandStateEx(0,40279) == 1) -- View: Show docker
	then return ME
-- the MIDI Editor is docked in an open floating docker
	elseif ME and floating then
		for line in io.lines(r.get_ini_file()) do
			if line:match('dockermode'..dockermode_idx)
			and line:match('32768') -- open floating docker
			-- OR
			-- and not line:match('98304') -- not closed floating docker
			then return ME
			end
		end
	end
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function Validate_Action_Type(action) -- used in Execute() function; action is the value assigned to SLOT variable

-- if global function, REAPER's native ReaScript API, including 3d party APIs
local func = _G[action]
local func = func and type(func) == 'function' and func -- ascertain that the function has been declared by the user in case it's global, existence of a local function will be ascertained outside

local commID = tonumber(action) -- native action
local script = action:match('_?RS') and (#action == 43 or #action == 42 or #action == 47 or #action == 48) -- count with or without underscore, accounting for greater length in the MIDI Editor section due to 7d3c_ infix
local cust_act = action:match('^_?[%l%d]+$') and (#action == 33 or #action == 32) -- count with or without underscore, not failproof against function name whose length happens to be identical
local sws_act = action:match('^_?[%u%p%d]+$')
local sws_act = sws_act and r.NamedCommandLookup(sws_act) > 0 and sws_act -- needed to distingush SWS command ID from all caps global function name

local sect
	if not func and not commID and (script or cust_act or sws_act)
	then
		local reaper_kb = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-kb.ini'
		local id = action:sub(1,1) == '_' and action:sub(2) or action -- remove underscore if any since scripts/custom actions ID don't contain it in reaper-kb.ini but KEY data do and will produce false result
			for line in io.lines(reaper_kb) do
				if line:match(id) then
				sect = line:match('^.- %d+ (%d+) ')
				break end
			end
		commID = (sect or sws_act) and action:sub(1,1) ~= '_' and '_'..action or action -- either script/custom action if section was retrieved or SWS action // add underscore to script/custom action command ID if absent
	end
return commID, sect, func
end


function Execute(action, midi, args, undo)
local commID, sect, func = Validate_Action_Type(action)

	if commID then
	midi = #midi:gsub(' ','') > 0
	local ME = MIDIEditor_GetActiveAndVisible()
	commID = (not sect and (tonumber(commID) or commID:match('[%u%p%d]+')) or sect and (sect == '32060' and ME or sect == '0')) and commID -- either native/SWS (cycle) action for which section cannot be retrieved and midi var is used instead or script/custom action
	local err = (sect and sect == '32060' or tonumber(commID) and midi) and not ME and 'no active midi editor' or not commID and ' the script/custom action \n\n\t     isn\'t found \n\n\t  in the relevant\n\n section of the action list' -- no error is raised if there's a mismatch between a native or an extension action midi var validity and the MainOn function which runs it or if such action IDs do not exist
		if err then Error_Tooltip('\n\n'..err..'\n\n ', 1, 1) -- caps and spaced are true
		return r.defer(no_undo)
		elseif commID then
		ACT(commID, midi or sect == '32060') -- midi is boolean
		end
	elseif func then -- global function
	local undo = #undo:gsub(' ','') == 0 and action or undo:match('[%w%p].*[%w%p]*') ~= '0' and undo -- if undo sett is disabled, the function name will be used, if not 0 then undo sett will be used, otherwise function custom undo point name; only relevant for function
	local u = undo and undo_block()
	func(table.unpack(args))
	local u = undo and undo_block(undo)
	end

end


function Center_Message_Text(mess, spaced)
-- to be used before Error_Tooltip()
-- spaced is boolean, must be true if the same argument is true in  Error_Tooltip()
local t, max = {}, 0
	for line in mess:gmatch('[^%c]+') do
		if line then
		t[#t+1] = line
		max = #line > max and #line or max
		end
	end
local coeff = spaced and 1.5 or 2 -- 1.5 seems to work when the text is spaced out inside Error_Tooltip(), otherwise 2 needs to be used
	for k, line in ipairs(t) do
	local shift = math.floor((max - #line)/2*coeff+0.5)
	local lb = k < #t and '\n\n' or ''
	t[k] = (' '):rep(shift)..line..lb
	end
return table.concat(t)
end


function PROCESS_AND_EXECUTE(itm_slots_t, want_item, want_takes, itm_act_cnt, tr_act_cnt) -- the args aren't strictly necessary if these exact vars are global

	if not r.GetTrack(0,0) then return end -- terminate if no tracks

-- local arrange_h, header_h, wnd_h_offset = Get_Arrange_and_Header_Heights() -- this function could be run here instead of outside

local x, y = r.GetMousePosition()
-- itm_slots_t length evaluation conditions below allow targeting track segments within Arrange over the item if no item slot is enabled, i.e. don't contain action ID or 0, while track slots are
local item, take = table.unpack(want_item and #itm_slots_t > 0 and {r.GetItemFromPoint(x, y, false)} or {nil}) -- allow_locked false
local tr, info = table.unpack((not item or #itm_slots_t == 0) and {r.GetTrackFromPoint(x, y)} or {nil})
local env = info == 1
local segm_t = Get_Item_Track_Segment_At_Mouse(header_h, wnd_h_offset, want_item, want_takes)

-- Process the segment table
	if segm_t then
	local act_idx, obj
		for segm_idx, truth in ipairs(segm_t) do -- only one field will be true, corresponding to the segment hit by mouse cursor, the rest will be false
			if truth then
				if item then -- must be evaluated 1st because track is valid along the entire timeline
				local left, right = table.unpack(itm_act_cnt > ITEM_SEGMENTS and {Get_Item_Edge_At_Mouse()} or {}) -- or diff > 0
					if not ALLOCATE_SEQUENTIALLY then
					local diff = itm_act_cnt-ITEM_SEGMENTS
					act_idx = diff > 0 and (segm_idx <= diff and (right and segm_idx*2 or left and segm_idx*2-1)
					or segm_idx > diff and segm_idx+diff) or diff == 0 and segm_idx -- when there're more valid slots than segments each slot is divided by 2 // the conditions must be very particular to prevent recognizing middle of a segment when it's already divided into two
					else
					act_idx = itm_act_cnt > ITEM_SEGMENTS and (right and segm_idx+ITEM_SEGMENTS or left and segm_idx) or itm_act_cnt <= ITEM_SEGMENTS and segm_idx -- the conditions must be very particular to prevent recognizing middle of a segment when it's already divided into two
					end
				obj = 'item'
				elseif tr then
				local tcp = Get_TCP_Under_Mouse()
					if env then
					act_idx = tcp and segm_idx or segm_idx+1
					obj = 'envelope'
					else
					act_idx = tr_act_cnt > TRACK_SEGMENTS and not tcp and segm_idx+TRACK_SEGMENTS or segm_idx -- when there're more valid slots than segments extra slots are valid outside of the tcp, that is within Arrange at the same levels as the first ones, i.e. ≡ ≡ hence +TRACK_SEGMENTS
					obj = 'track'
					end
				end
			break end
		end

		if item and (not act_idx or not itm_slots_t[act_idx]) or env and not env_slots_t[act_idx]
		or tr and not tr_slots_t[act_idx] then
		local mess = Center_Message_Text('no '..obj..' slot is associated\n\n with this location', 1) -- spaced is 1
		Error_Tooltip('\n\n '..mess..' \n\n ', 1, 1) -- caps and spaced are true
		return r.defer(no_undo)

		elseif act_idx then
			local function get_slot_idx_and_action(idx, t, field_name)
			return t[idx] and t[idx][field_name]
			end
		local action = item and get_slot_idx_and_action(act_idx, itm_slots_t, 'action')
		or env and get_slot_idx_and_action(act_idx, env_slots_t, 'action')
		or tr and get_slot_idx_and_action(act_idx, tr_slots_t, 'action')
		local slot_idx = item and get_slot_idx_and_action(act_idx, itm_slots_t, 'slot_idx')
		or env and get_slot_idx_and_action(act_idx, env_slots_t, 'slot_idx')
		or tr and get_slot_idx_and_action(act_idx, tr_slots_t, 'slot_idx')
			if action and action:match('[%w%p].*[%w%p]*') == '0' then
			local mess = Center_Message_Text('no action is associated\n\n with this '..obj..' slot', 1) -- spaced is 1
			Error_Tooltip('\n\n '..mess..' \n\n ', 1, 1) -- caps and spaced are true
			return r.defer(no_undo) end
		local midi = item and itm_midi_t[slot_idx] or env and env_midi_t[slot_idx] or tr and tr_midi_t[slot_idx]
		local args = item and itm_args_t[slot_idx] or env and env_args_t[slot_idx] or tr and tr_args_t[slot_idx]
		local undo = item and itm_undo_t[slot_idx] or env and env_undo_t[slot_idx] or tr and tr_undo_t[slot_idx]
		Execute(action, midi, args, undo)

		end

	end

end


function validate_segment_setting(sett)
sett = #sett:gsub(' ','') > 0 and sett
sett = tonumber(sett) and math.abs(tonumber(sett))
sett = sett and (sett >= 0 and sett < 1 and 1 or math.floor(sett))
return sett and (sett > 3 and 3 or sett)
end


local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

	if not sws and not js then
	Error_Tooltip('\n\n     NEITHER SWS/S&M \n\n   NOR js_ReaScriptAPI \n\n EXTENSION IS INSTALLED \n\n', false, 1) -- caps false, spaced true
	return r.defer(no_undo) end


local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, true) -- allow_locked true // needed to condition tooltip below
local tr, info = r.GetTrackFromPoint(x, y)
local env = info == 1

ALLOCATE_SEQUENTIALLY = #ALLOCATE_SEQUENTIALLY:gsub(' ','') > 0
-- must be global to be accessible to PROCESS_AND_EXECUTE() without being passed as arguments
ITEM_SEGMENTS = validate_segment_setting(ITEM_SEGMENTS)
TRACK_SEGMENTS = validate_segment_setting(TRACK_SEGMENTS)
itm_slots_t = ITEM_SEGMENTS and Collect_Valid_Slots(ITEM_SLOT1,ITEM_SLOT2,ITEM_SLOT3,ITEM_SLOT4,ITEM_SLOT5,ITEM_SLOT6) or {}
tr_slots_t = TRACK_SEGMENTS and Collect_Valid_Slots(TRACK_SLOT1,TRACK_SLOT2,TRACK_SLOT3,TRACK_SLOT4,TRACK_SLOT5,TRACK_SLOT6) or {}
env_slots_t = Collect_Valid_Slots(ENV_SLOT1,ENV_SLOT2)
itm_midi_t = {ITEM_SLOT1_midi,ITEM_SLOT2_midi,ITEM_SLOT3_midi,ITEM_SLOT4_midi,ITEM_SLOT5_midi,ITEM_SLOT6_midi}
tr_midi_t = {TRACK_SLOT1_midi,TRACK_SLOT2_midi,TRACK_SLOT3_midi,TRACK_SLOT4_midi,TRACK_SLOT5_midi,TRACK_SLOT6_midi}
env_midi_t = {ENV_SLOT1_midi,ENV_SLOT2_midi}
itm_args_t = {ITEM_SLOT1_args,ITEM_SLOT2_args,ITEM_SLOT3_args,ITEM_SLOT4_args,ITEM_SLOT5_args,ITEM_SLOT6_args}
tr_args_t = {TRACK_SLOT1_args,TRACK_SLOT2_args,TRACK_SLOT3_args,TRACK_SLOT4_args,TRACK_SLOT5_args,TRACK_SLOT6_args}
env_args_t = {ENV_SLOT1_args,ENV_SLOT2_args}
itm_undo_t = {ITEM_SLOT1_undo,ITEM_SLOT2_undo,ITEM_SLOT3_undo,ITEM_SLOT4_undo,ITEM_SLOT5_undo,ITEM_SLOT6_undo}
tr_undo_t = {TRACK_SLOT1_undo,TRACK_SLOT2_undo,TRACK_SLOT3_undo,TRACK_SLOT4_undo,TRACK_SLOT5_undo,TRACK_SLOT6_undo}
env_undo_t = {ENV_SLOT1_undo,ENV_SLOT2_undo}

local itm_act_cnt = ITEM_SEGMENTS and (#itm_slots_t > ITEM_SEGMENTS and #itm_slots_t or ITEM_SEGMENTS) -- limit for number of segments is 3 set inside validate_segment_setting() // can be false because in this case the script will be aborted with a message
local tr_act_cnt = TRACK_SEGMENTS and (#tr_slots_t > TRACK_SEGMENTS and #tr_slots_t or TRACK_SEGMENTS) -- same

-------------- Generate error messages -------------------

-- slots without any setting
local mess = 'no enabled slots'
local err = #itm_slots_t+#env_slots_t+#tr_slots_t == 0 and mess
err = err or (item and #itm_slots_t == 0 and #tr_slots_t == 0 and mess:gsub('slots', 'item %0') -- '#tr_slots_t == 0' cond allows targeting track segments within Arrange over an item if no item slot is valid while track segments are
or env and #env_slots_t == 0 and mess:gsub('slots', 'envelope %0')
or (not item or #itm_slots_t == 0) and tr and #tr_slots_t == 0 and mess:gsub('slots', 'track %0'))

	if err then
	Error_Tooltip(' \n\n'..err..'\n\n ', 1, 1) -- caps and spaced are true
	return r.defer(no_undo) end

-- slots disabled with '0' setting to keep slot layout
local disabled_itm, disabled_tr, disabled_env =
Get_Disabled_Slots(itm_slots_t), Get_Disabled_Slots(tr_slots_t), Get_Disabled_Slots(env_slots_t)
local err = ' no action is asscociated \n\n'
err = disabled_itm and disabled_tr and disabled_env and err..'\t  with any slot'
or item and disabled_itm and #itm_slots_t > 0 and err..'\t    with items' -- additional '#itm_slots_t > 0' cond due to use of '#tr_slots_t == 0' cond in the error generation above which prevents item error if track slots are valid and therefore makes this expression without the additional cond falsely valid
or env and disabled_env and err..'        with envelopes'
or not item and tr and disabled_tr and err..'\t   with tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n ', 1, 1) -- caps and spaced are true
	return r.defer(no_undo) end

------------------- error messages end -------------------

bot_t, arrange_h, header_h, wnd_h_offset = Get_Arrange_and_Header_Heights() -- these stay global to be accessible inside PROCESS_AND_EXECUTE() without being passed as arguments, bot_t is irrelevant in this design but is left for convenience
local want_item, want_takes = true, false -- boolean arguments of Get_Item_Track_Segment_At_Mouse() inside of PROCESS_AND_EXECUTE()
PROCESS_AND_EXECUTE(itm_slots_t, want_item, want_takes, itm_act_cnt, tr_act_cnt)


--[[------------------------------------------------
-------------------- SLOT MAP ----------------------
----------------------------------------------------


Filled areas are enabled slots.

Enabled slots whose ordinal number is greater
than the doubled number of segments are ignored,
i.e. when 2 segments are enabled with ITEM_SEGMENT
setting, max number of slots is 4, enabled slots
from 5th onward (that is 5th and 6th) will be ignored.
If the number of enabled slots is smaller than the number
of segments, the extra segments simply won't have any slot
associated with them

▓ ITEMS slot layout

1 Segment

1 enabled slot
(entire item)
  _______
 │░░░░░░░│
 │░░░1░░░│
 │░░░░░░░│
  ¯¯¯¯¯¯¯
2 enabled slots
(only item edges)
  _______
 │░     ░│
1│░     ░│2
 │░     ░│
  ¯¯¯¯¯¯¯
2 Segments

2 enabled slots
(top and bottom halves)
  _______
 │░░░1░░░│
 │-------│
 │░░░2░░░│
  ¯¯¯¯¯¯¯
3 enabled slots
(top half edges, bottom half)

 sequential
  _______        _______
1│░     ░│2    1│░     ░│3
 │-------│      │-------│
 │░░░3░░░│      │░░░2░░░│
  ¯¯¯¯¯¯¯        ¯¯¯¯¯¯¯
4 enabled slots
(top and bottom half edges)

 sequential
  _______        _______
1│░     ░│2    1│░     ░│3
 │-------│      │-------│
3│░     ░│4    2│░     ░│4
  ¯¯¯¯¯¯¯        ¯¯¯¯¯¯¯
3 Segments

3 enabled slots
(top, middle and bottom thirds)
 _______
│###1###│
│###2###│
│###3###│
 ¯¯¯¯¯¯¯
4 enabled slots
(top third edges, middle and bottom thirds)

 sequential
  _______        _______
1│░_____░│2    1│░_____░│4
 │###3###│      │###2###│
 │###4###│      │###3###│
  ¯¯¯¯¯¯¯        ¯¯¯¯¯¯¯
5 enabled slots
(top & middle third edges, bottom third)

 sequential
  _______        _______
1│░_____░│2    1│░_____░│4
3│░_____░│4    2│░_____░│5
 │###5###│      │###3###│
  ¯¯¯¯¯¯¯        ¯¯¯¯¯¯¯
6 enabled slots
(top, middle & bottom third edges)

 sequential
  _______        _______
1│░_____░│2    1│░_____░│4
3│░_____░│4    2│░_____░│5
5│░_____░│6    3│░_____░│6


▓ TRACK slot layout

1 Segment

1 enabled slot
(entire TCP)

   TCP
 _______
│░░░░░░░│
│░░░1░░░│
│░░░░░░░│
 ¯¯¯¯¯¯¯
2 enabled slots
(entire TCP and entire track height in Arrange)

   TCP     Arrange
 _______ ___________
│░░░░░░░│░░░░░░░░░░░
│░░░1░░░│░░░░░2░░░░░
│░░░░░░░│░░░░░░░░░░░
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
2 Segments

2 enabled slots
(top and bottom halves in TCP)

   TCP
 _______
│░░░1░░░│
│-------│
│░░░2░░░│
 ¯¯¯¯¯¯¯
3 enabled slots
(top and bottom halves in TCP, and top half in Arrange)

   TCP     Arrange
 _______ ___________
│░░░1░░░│░░░░░3░░░░░
│-------│-----------
│░░░2░░░│
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
4 enabled slots
(top and bottom halves both in TCP and in Arrange)

   TCP     Arrange
 _______ ___________
│░░░1░░░│░░░░░3░░░░░
│-------│-----------
│░░░2░░░│░░░░░4░░░░░
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
3 Segments

3 enabled slots
(top, middle and bottom thirds in TCP)

   TCP
 _______
│###1###│
│###2###│
│###3###│
 ¯¯¯¯¯¯¯
4 enabled slots
(top, middle and bottom thirds in TCP, and top third in Arrange)

   TCP     Arrange
 _______ ___________
│###1###│░░░░░4░░░░░
│###2###│
│###3###│
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
5 enabled slots
(top, middle and bottom thirds in TCP, and top and middle thirds in Arrange)

   TCP     Arrange
 _______ ___________
│###1###│#####4#####
│###2###│#####5#####
│###3###│
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
6 enabled slots
(top, middle and bottom thirds both in TCP and in Arrange)

   TCP     Arrange
 _______ ___________
│###1###│#####4#####
│###2###│#####5#####
│###3###│#####6#####
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯

▓ ENVELOPE slot layout

Then number of envelope slots depends
on the number of enabled SLOT settings

1 enabled slot
(entire ECP)

   ECP
 _______
│░░░░░░░│
│░░░1░░░│
│░░░░░░░│
 ¯¯¯¯¯¯¯
2 enabled slots
(entire ECP and entire envelope hight in Arrange)

   ECP     Arrange
 _______ ___________
│░░░░░░░│░░░░░░░░░░░
│░░░1░░░│░░░░░2░░░░░
│░░░░░░░│░░░░░░░░░░░
 ¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯

]]



