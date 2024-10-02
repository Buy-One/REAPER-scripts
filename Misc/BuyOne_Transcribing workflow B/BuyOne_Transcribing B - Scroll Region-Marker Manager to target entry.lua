--[[
ReaScript name: BuyOne_Transcribing B - Scroll Region-Marker Manager to target entry.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: js_ReaScriptAPI preferable, or SWS/S&M
About:	The script is part of the Transcribing B workflow set of scripts
	alongside  
	BuyOne_Transcribing B - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing B - Real time preview.lua  
	BuyOne_Transcribing B - Format converter.lua  
	BuyOne_Transcribing B - Import SRT or VTT file as regions.lua  
	BuyOne_Transcribing B - Prepare transcript for rendering.lua  
	BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
	BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua
	
	If js_ReaScriptAPI extension is installed the script either scrolls 
	'Region/Marker Manager' to the entry of region currently selected in Arrange 
	(since REAPER build 7.16). If the build you're using is older or no region 
	is selected the script scrolls to the entry of a region at the edit or mouse 
	(if the setting AT_MOUSE_CURSOR is enabled) cursor provided the region name 
	field isn't empty.  
	If only SWS/S&M extension is installed, REAPER build is immeterial. The script 
	searches for region at the edit or mouse (if the setting AT_MOUSE_CURSOR is 
	enabled) cursor, and if the found region's name isn't empty or if ANCHOR_STRING
	setting is enabled the script places its name into the Manager's filter field 
	thereby isolating its entry in the Manager's list.	
	
	If the Region/Marker Manager is closed the script will open it.
	
	The script was tested on Windows only.
	
	To point at a region place the edit or point the mouse cursor at its start 
	or place within its bounds.	
	
	Another way of targeting a region with the mouse cursor other than by enabling 
	AT_MOUSE_CURSOR setting, is using the following custom action bound to a shortcut:
	
	Custom: Transcribing - Show entry of region at mouse cursor in Region-Marker Manager  
		View: Move edit cursor to mouse cursor  
		BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua			

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- This setting is only needed if you're using the script
-- as part of the transcribing workflow while only having
-- SWS/S&M extension installed, because only in this case
-- the region name will be placed into the Region/Marker
-- Manager filter field to isolate its entry (see 'About:'
-- text in the header) for managing the transcript;
-- While editing segment transcript which is contained in
-- segment region name you'd want the region entry in the
-- Manager to always be visible, however since the region
-- entry is filtered by name, as soon as you apply the edited
-- region name, that is transcript text, the region entry will
-- disappear from the list because it will no longer match
-- the filter search term. To overcome this problem the script
-- will append an anchor string defined by this setting
-- (one character suffices, but there's no limit) to the very
-- start of the transcript text so that even if you edit the
-- transcript text in the region name the region entry will
-- remain visible in the Manager as long as the anchor string
-- is there. Once you've done editing the segment transcript,
-- manually delete this anchor string from its beginning;
-- This setting allows targeting unnamed regions as well;
-- Example anchor string: §
ANCHOR_STRING = "§"


-- Enable by inserting any alphanumeric character between
-- the quotes to force the script to first search for region
-- at mouse cursor,
-- the mouse cursor must be located within Arrange, i.e.
-- below the ruler, not be blocked by other windows
-- and be opposite of any track TCP;
-- if none of the conditions are met or no region is found
-- at mouse cursor the script it will search
-- for a region at the edit cursor;
AT_MOUSE_CURSOR = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
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



function Get_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end



function Get_Marker_Region_At_Time(time)
-- can be used to get marker/region at edit cursor
-- if r.GetCursorPosition() is passed as time argument
-- without the need to traverse all of them
local mrkr_idx, rgn_idx = r.GetLastMarkerAndCurRegion(0, time)
local t = {}
t.mrkr = mrkr_idx > -1 and {r.EnumProjectMarkers3(0,mrkr_idx)}
t.rgn = rgn_idx > -1 and {r.EnumProjectMarkers3(0,rgn_idx)}
	if t.mrkr then table.insert(t.mrkr,1,t.mrkr[3] == time) end
	if t.rgn then table.insert(t.rgn,1,t.rgn[3] == time) end
-- fields:
-- 1 - true if marker or region start are exactly at the time, false if last marker before time
-- or region start before time
-- 2 - sequential index on the time line, same as mrkr_idx and rgn_idx
-- 3 - isrgn, 4 - position, 5 - rgn_end, 6 - name, 7 - displayed index, 8 - color
-- empty t.mrkr or t.rgn table - no marker or region respectively before or at the time
return t
end


function Find_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search windows with BR_Win32_FindWindowEx(), including docked
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtexta#return-value
-- 2. search floating docker with BR_Win32_FindWindowEx() using 2 title options, and loop to find children and siblings
-- 3. search dockers attached to the main window with r.GetMainHwnd() and loop to find children and siblings

	local function Find_Win(title)
	return r.BR_Win32_FindWindowEx('0', '0', '', title, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // does find single windows and single windows docked in floating dockers with '(docked)' appendage in the title, doesn't find children windows, such as docked in multi-tab docks and single docked in dockers attached to the main window, hence the actual function Find_Window_SWS()
	end

	local function get_wnd_siblings(hwnd, val, wnd_name)
	-- val = 2 next; 3 prev doesn't work if hwnd belongs
	-- to the very 1st child returned by BR_Win32_GetWindow() with val 5, which seems to always be the case
	local Get_Win = r.BR_Win32_GetWindow
	-- evaluate found window
	local ret, tit = r.BR_Win32_GetWindowText(hwnd)
		if tit == wnd_name then return hwnd
		elseif tit == 'REAPER_dock' then -- search children of the found window
		-- dock windows attached to the main window have 'REAPER_dock' title and can have many children, each of which is a sibling to others, if nothing is attached the child name is 'Custom1', 15 'REAPER_dock' windows are siblings to each other
		local child = Get_Win(hwnd, 5) -- get child 5, GW_CHILD
		local hwnd = get_wnd_siblings(child, val, wnd_name) -- recursive search for child siblings
			if hwnd then return hwnd end
		end
	local sibl = Get_Win(hwnd, 2) -- get next sibling 2, GW_HWNDNEXT
		if sibl then return get_wnd_siblings(sibl, val, wnd_name) -- proceed with recursive search for dock siblings and their children
		else return end
	end

	local function search_floating_docker(docker_hwnd, docker_open, wnd_name) -- docker_hwnd is docker window handle, docker_open is boolean, wnd_name is a string of the sought window name
		if docker_hwnd and docker_open then -- windows can be found in closed dockers hence toggle state evaluation
	-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
		local child = r.BR_Win32_GetWindow(docker_hwnd, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
		local ret, tit = r.BR_Win32_GetWindowText(child) -- floating docker window 1st child name is 'REAPER_dock', attached windows are 'REAPER_dock' child and/or the child's siblings
		return get_wnd_siblings(child, 2, wnd_name) -- go recursive enumerating child siblings; sibling 2 (next) - GW_HWNDNEXT, 3 (previous) - GW_HWNDPREV, 3 doesn't seem to work regardless of the 1st child position in the docker, probably because BR_Win32_GetWindow with val 5 always retrieves the very 1st child, so all the rest are next
		end
	end

-- search for floating window
local wnd = Find_Win(wnd_name)

	if wnd then return wnd end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker' // non-toolbar windows can be attached to a floating toolbar docker as well
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search for a floating docker with one attached window
local docker = Find_Win(wnd_name..' (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd and (r.JS_Window_IsVisible and r.JS_Window_IsVisible(wnd) or dock) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- search toolbar docker with multiple attached windows which can house regular windows
docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker', non-toolbar windows can be attached to a floating toolbar docker as well
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search floating docker with multiple attached windows which can house toolbars
docker = Find_Win('Docker') -- when a docker attached to the main window is detached from it by toggling 'Attach docker to the main window' and there're several windows in it, the floating docker title is 'Docker'
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search docks attached to the main window
	if dock and not want_main_children or want_main_children then -- windows can be found in closed dockers hence toggle state evaluation
	local main = r.GetMainHwnd() -- the name of the dock window is 'REAPER_dock' of which there're 15 all being children of the main window and siblings of each other, attached windows are dock children and are siblings of each other
	local child = r.BR_Win32_GetWindow(main, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
	return get_wnd_siblings(child, 2, wnd_name)
	end

end



function Insert_String_Into_Field(parent_wnd, str)
-- parent_wnd is window titled 'Region/Marker Manager' or 'Region/Marker Manager (docked)'
-- found with Find_Window_SWS() function
-- str is string to be inserted into the filter field of 'Region/Marker Manager'

	if not parent_wnd then return end

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child

	if not child then return end


	local function is_filter_field(title)
	-- 'Region/Marker Manager' filter field window is nameless unless filled out
	-- the window title list is as of build 7.22
		for k, tit in ipairs({'Clear', 'List2', 'Markers',
		'Options', 'Regions', 'Render Matrix...', 'Take markers'}) do
			if title == tit then return end
		end
	return true
	end


local SendMsg = r.BR_Win32_SendMessage
local i = 1
	repeat
	local ret, txt = r.BR_Win32_GetWindowText(child)
		if ret and is_filter_field(txt) then -- 'Region/Marker Manager' filter field window is nameless unless filled out
		--------------- CLEAR ROUTINE  --------------------------------------------
			if #txt > 0 then -- clear filter string, if any
		--	r.BR_Win32_SetFocus(child)	-- this is unnecessary unless the window must be made a target for keyboard input
		--	SendMsg(child, 0x0007, 0, 0) -- WM_SETFOCUS 0x0007 -- makes the Manager unresponsive to clicks even though does place a cursor in the filter field
		-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#keystroke-message-flags	-- scan codes are listed in a table in 'Scan 1 Make' colum in Scan Codes paragraph
		-- https://handmade.network/forums/articles/t/2823-keyboard_inputs_-_scancodes%252C_raw_input%252C_text_input%252C_key_names
		-- 'Home' (extended key) scan code 0xE047 (move cursor to start of the line) or 0x0047, 'Del' (extended key) scan code 15, Backspace scancode 0x000E or 0x0E (14), Forward delete (regular delete) 0xE053 (extended), Left arrow 0xE04B (extended key), Left Shift 0x002A or 0x02A, Right shift 0x0036 or 0x036 // all extended key codes start with 0xE0
		-- BR_Win32_SendMessage only needs the scan code, not the entire composite 32 bit value, not even the extended key flag, the repeat count, i.e. bits 0-15, is ignored, no matter the integer the command only runs once
			-- #txt count works accurately here for Unicode characters as well for some reason
			-- move cursor to start of the line
			SendMsg(child, 0x0100, 0x24, 0xE047) -- 0x0100 WM_KEYDOWN, 0x24 VK_HOME HOME key, HOME key 0xE047 scan code
				for i=1,#txt do -- run Delete for each character
				SendMsg(child, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, DEL key 0xE053 scan code
				end
			--[[ -- OR
				for i=1,#txt do -- move cursor from line end left character by character deleting them
				SendMsg(child, 0x0100, 0x25, 0xE04B) -- 0x25 LEFT ARROW key, 0xE04B scan code
				SendMsg(child, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 scan code
				end
			--]]
			--[[ -- OR
			-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
			-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-clear
			SendMsg(child, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index
			SendMsg(child, 0x0303, 0, 0) -- WM_CLEAR 0x0303
			--]]			
			end
	--------------------------------------------------------------
		r.CF_SetClipboard(str)
		SendMsg(child, 0x0302, 0, 0) -- WM_PASTE 0x0302 // gets input from clipboard
	-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-paste
	--	https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
		break
	--]]
		end
	-- get for the next cycle
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found or the right one is found above

	i=i+1
	until not child

end



function Scroll_Region_Mngr_To_Highlighted_Item(rgn_mngr_closed, rgn_name)
-- supports selected markers as well
-- rgn_mngr_closed value must be obtained before opening the Manager
-- rgn_name is only relevant when no region/marker is selected
-- because in this case the entry for scrolling into view
-- is searched for by region name

	if not r.JS_Window_Find then return end

local parent_wnd = r.JS_Window_Find('Region/Marker Manager', true) -- exact true // covers both docked and undocked window

	if parent_wnd then

	local mngr_list_wnd = r.JS_Window_FindChild(parent_wnd, 'List2', true) -- exact true, 'Region/Marker Manager' list window is named 'List2', address is '0x10033C', discovered with Get_All_Child_Wnds(), the hex value with JS_Window_ListAllChild()

	local list_itm_cnt = r.JS_ListView_GetItemCount(mngr_list_wnd)
		for idx=0, list_itm_cnt-1 do
			if not rgn_name then -- look for highlighted item in the list
			local highlighted = r.JS_ListView_GetItemState(mngr_list_wnd, idx) == 2 -- items in the Region/Marker Manager aren't selected by a click on a region/marker in Arrange but are highlighted, they're selected when clicked directly, code is 3 which is irrelevant for this script
				if highlighted then
				-- this doesn't need scrolling with JS_Window_SetScrollPos() at all;
				-- if Region/Marker Manager is closed when the script is executed
				-- and then is opened by the script, JS_ListView_GetItemState()
				-- sometimes seems to make the color of entries of non-selected objects
				-- brighter than the selected MARKERS (within range between 10 to 30
				-- counting from the 1st marker), same with JS_ListView_GetItem()
				-- which returns both text and state,
				-- never happens with selected regions and when moving into view based
				-- on the region/marker name below;
				-- to compensate for this added JS_Window_SetFocus() so that
				-- if the Manager window is initially closed, when opened
				-- the entry of the selected object becomes darker and thus more discernible,
				-- JS_Window_Update() doesn't help in this regard
				local focus = rgn_mngr_closed and r.JS_Window_SetFocus(mngr_list_wnd)
				r.JS_ListView_EnsureVisible(mngr_list_wnd, idx, false) -- partialOK false
				return true end
			else -- no item is highlighted, search by text in the column, in this case region name
				for col_idx=0,15 do -- currently (build 7.22) there're 10 columns in Region/Marker Manager, but using 16 in case the number will increase in the future
				-- colums can be reordered therefore all must be traversed to find the right one
					if r.JS_ListView_GetItemText(mngr_list_wnd, idx, col_idx) == rgn_name then -- item arg is row index, subitem is column index, both 0-based
					r.JS_ListView_EnsureVisible(mngr_list_wnd, idx, false) -- partialOK false
					end
				end
			end
		end
	end

end



local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local region, marker = scr_name:match('.+[\\/].-of (region)'), scr_name:match('.+[\\/].-of (marker)')
local obj = region or marker
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.16 -- before this build regions/markers could not be set selected in Arrange and hence its entry in the Manager didn't get highlighted
local space = function(int) return (' '):rep(int) end
local cnt, mrkr_cnt, rgn_cnt = r.CountProjectMarkers(0)
local sws, js = r.CF_SetClipboard, r.JS_Window_Find
local rgn_mngr_closed = r.GetToggleCommandStateEx(0, 40326) == 0 -- View: Show region/marker manager window
local err = not region and not marker and 'the script name has been altered'
or not sws and not js and 'sws/s&m and js_reascriptapi\n\n  extensions aren\'t installed'
or js and not old_build and cnt == 0 and 'no markers or regions\n\n\tin the project' -- when js extension is installed selected markers can be targeted as well in builds 7.16 onwards
or sws and (not js and not old_build or old_build) and (region and rgn_cnt == 0 or marker and mrkr_cnt == 0) and 'no '..obj..'s in the project' -- in old builds or in new without js extension but in both cases with sws, only either regions or markers at cursor can be targeted

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

	if rgn_mngr_closed then
	r.Main_OnCommand(40326,0) -- View: Show region/marker manager window // toggle to open
	end


local highlighted_found = js and Scroll_Region_Mngr_To_Highlighted_Item(rgn_mngr_closed) -- supports selected markers as well // will also be false if there's selected object but the Manager list is filtered and it's not found there

		if not highlighted_found then -- this part depends on the scrpt name and targets either regions or markers

		local cur_pos

			if #AT_MOUSE_CURSOR:gsub(' ','') > 0 then
			local tr, info = r.GetTrackFromPoint(r.GetMousePosition())
			-- ensuring that mouse cursor is over Arrange allows ignoring mouse position
			-- when the script is run via toolbar button, menu item or from the Action list
				if tr and not Get_TCP_Under_Mouse() and info ~= 2 then -- not FX window
				r.PreventUIRefresh(1)
				local cur_pos_orig = r.GetCursorPosition() -- store
				r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
				cur_pos = r.GetCursorPosition()
				r.SetEditCurPos(cur_pos_orig, false, false) -- moveview, seekplay false // restore orig. edit curs pos
				r.PreventUIRefresh(-1)
				end
			end

		local t = Get_Marker_Region_At_Time(cur_pos or r.GetCursorPosition()) -- if mouse is enabled and it's not over Arrange, look for region at edit cursor

		-- to target project marker use t.mrkr instead or t.rgn -- depends on the script name

			if cur_pos and (region and not t.rgn or marker and not t.mrkr) then -- if not found at mouse cursor, look at edit cursor
			t = Get_Marker_Region_At_Time(r.GetCursorPosition())
			end

		ANCHOR_STRING = #ANCHOR_STRING:gsub(' ','') > 0 and ANCHOR_STRING
		local obj_t = region and t.rgn or marker and t.mrkr
		local no_selected = js and (not old_build and '   no selected region\n\n\t   or marker,\n\n or the list is filtered,' or '')
		or '' -- no_selected because highlighted_found is false or js_ReaScriptAPI extension isn't installed
		local old_or_not_js = old_build or not js
		err = not obj_t and no_selected..(old_build and '\t  ' or js and '\n\n\tand ' or '\t  ')..'the cursor \n\n  is outside of '..obj..'s'
		or #obj_t[6]:gsub('[%s%c]','') == 0
		and (js or sws and not ANCHOR_STRING) and -- this condition allows targeting unnamed regions/markers by placing the anchor string into their name field
		no_selected:gsub('%s%s','\t ')..(old_build and '' or js and '\n\n and ' or '')
		..('the name of the '..obj..' \n\n\tat cursor is empty'):gsub(old_or_not_js and '\t' or '', old_or_not_js and space(4) or '')

			if err then
			Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
			return r.defer(no_undo) end

			if js then
			Scroll_Region_Mngr_To_Highlighted_Item(nil, obj_t[6]) -- rgn_mngr_closed arg is nil as unnecessary
			elseif sws then
			local mngr_wnd = Find_Window_SWS('Region/Marker Manager', want_main_children) -- want_main_children nil
			local name = obj_t[6] -- table index 6 name
				if ANCHOR_STRING then
				name = name:match('^'..ANCHOR_STRING..'%s*(.*)$') or name -- removing anchor string from the name if it was left behind by the user
				name = ANCHOR_STRING..' '..name
				r.Undo_BeginBlock()
				r.SetProjectMarker3(0, obj_t[2], region and true, obj_t[4],
				obj_t[5], name, obj_t[8]) -- table index 2 is index on the timeline, isrgn  is region, true if the script is aimed at regions, table index 4 pos, table index 5 rgnend, table index 6 name, table index 8 color
				r.Undo_EndBlock('Transcribing B: Add anchor string to '..(region or marker)..' name',-1)
				end
			Insert_String_Into_Field(mngr_wnd, name)
			end

		end


do return r.defer(no_undo) end





