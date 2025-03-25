--[[
ReaScript name: BuyOne_Jump to the directory of the file being previewed in the Media Explorer.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v7.35
Extensions: SWS/S&M for basic functionality, js_ReaScriptAPI for extended functionality
Provides: [main=main,mediaexplorer] .
About:	In its basic functionality for which the SWS/S&M 
	extension will suffice the script will paste the
	address of the file currently being previewed
	into the path bar of the Media Explorer. To open 
	that directory you will have to manually hit the 
	Enter key. To locate the file in the lust look up 
	its name in the Media Explorer footer.

	If js_ReaScriptAPI extension is installed alongside
	the SWS/S&M extension, the stored directory will be
	opened automatically and the file being previewed 
	will be scrolled into view at the top of the list.

]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only display output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
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



function Check_reaper_ini(section, key, value)
-- the args must be strings
-- section is the one found in reaper.ini file
-- and needs not to include square brackets
-- if the key isn't subsumed under any section
-- section arg can be nil
-- however to get values of standalone keys
-- reaper.get_config_var_string() is more efficient;
-- value arg is optional, only useful if
-- you expect a certain value to be able
-- to verify if it's set

--[-[-- METHOD 1
local found
	for line in io.lines(r.get_ini_file()) do
		if section and line == '['..section..']' then found = 1
		elseif not section then
		val = line:match(key..'=(.+)')
			if val then return val, val == value end
		elseif found then
		local val = line:match(key..'=(.+)')
			if val then return val, val == value end
		end
	end
--]]

--[[
---- METHOD 2
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
cont = cont..'\n' -- add in case there's no terminating new line so that the capture works on the very last line as well
local patt = '.-\n'..key..'=(.-)\n'
local patt = section and '['..section..']'..patt or patt
local val = cont:match(patt)
--local val = cont:match(key..'=([%.%d]+)') == value -- OR '=(.-)\n'
-- OR SIMPLY: return cont:match(key..'=([%.%d]+)') == value
return val, val == value
--]]
end


function Get_Media_Explorer_Show_Submenu_Options(bitfield)
-- bitfield stems from Check_reaper_ini() with section arg '[reaper_explorer]'
-- and key arg 'displayall'
-- evaluates whether option is enabled
-- so enabled true, disabled false

	if bitfield+0 == 1228 then return end -- all are disabled

local opts = {
-- unused bits: &16, &512
-- values are logarithm for base 2
[1]=0, -- All files // &1
[2]=7, -- Folders // &128 disabled
[3]=6, -- File extension even when file type displayed // &64 disabled

-- next two options are mutually exclusive but both can be turned off
[4]=2, -- Leading path in databases and searches // &4 disabled
[5]=8, -- Full path in databases and searches // &256 disabled

[6]=3, -- Path drop-down box // &8 disabled
[7]=10, -- Scrollbars on preview waveform // &1024 disabled
[8]=11, -- Automatically expand shortcuts while browsing file list // &2048 disabled
[9]=12, -- Display preview position in beats for audio files, using embedded or estimated tempo // &4096 disabled
[10]=1, -- Display preview position in wholes seconds and beats // &2
}
	for k, exp in ipairs(opts) do
	local bit = 2^exp
	-- only for two options bits are set when they are enabled
	-- for the rest bits are set when they're disabled
	opts[k] = exp < 2 and bitfield+0&bit == bit or exp > 1 and bitfield+0&bit ~= bit
	end
return opts
end



function Get_MX_Column_Count()
-- as of build 7.22 default column count is 25
-- on top of which custom user columns may exist
-- when column is hidden its valye in reaper.ini is 0
-- in the format colX=0 where X is a column 0-based index
-- whether default or user column
-- hidden colums are still accessible to the functions
-- but only traversing the visible ones may not yield
-- the positive result because the loop
-- won't reach the correct one and the item won't be found
-- so all columns must be traversed

local hidden_col_count, total_col_cnt, found = 0, 25
	for line in io.lines(r.get_ini_file()) do
		if line == '[reaper_explorer]' then found = 1
		elseif found then
			if line:match('col%d+=0') then
			hidden_col_count = hidden_col_count+1
			elseif line:match('user%d+_key=') then
			total_col_cnt = total_col_cnt+1 -- adding user colums to the total
			end
			if line:match('%[.-%]') then -- new section
			break end
		end
	end

return total_col_cnt, total_col_cnt - hidden_col_count -- total, visible, the latter is unused

end



function Find_Window_SWS(wnd_name, want_main_children)
-- THE FUNCTION IS CASE-AGNOSTIC
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search floating toolbars with BR_Win32_FindWindowEx(), including docked
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
-- won't be found if closed
local wnd = Find_Win(wnd_name)

	if wnd then return wnd end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker' // non-toolbar windows can be attached to a floating toolbar docker as well
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search for a floating docker with one attached window // toolbars can be attached to a regular floating docker and regular windows can be attached to a floating toolbar docker
-- !!!! if in the floating docker the window name differs from the original apart from the '(docked)' prefix
-- here the alternative name must be passed in full rather than in concatenated form
local docker = Find_Win(wnd_name..' (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd and (r.JS_Window_IsVisible and r.JS_Window_IsVisible(wnd) or dock) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- search toolbar docker with multiple attached windows which can house regular windows
local docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker', non-toolbar windows can be attached to a floating toolbar docker as well
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search floating docker with multiple attached windows which can house toolbars
local docker = Find_Win('Docker') -- when a docker attached to the main window is detached from it by toggling 'Attach docker to the main window' and there're several windows in it, the floating docker title is 'Docker'
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search docks attached to the main window
	if dock and not want_main_children or want_main_children then -- windows can be found in closed dockers hence toggle state evaluation
	local main = r.GetMainHwnd() -- the name of the dock window is 'REAPER_dock' of which there're 15 all being children of the main window and siblings of each other, attached windows are dock children and are siblings of each other
	local child = r.BR_Win32_GetWindow(main, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
	return get_wnd_siblings(child, 2, wnd_name)
	end

end


function Get_Child_Windows_SWS(parent_wnd)
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
-- the function doesn't cover grandchildren
-- once window handles have been collected
-- they can be analyzed further for presence of certain string
-- using BR_Win32_GetWindowText()

	if not parent_wnd then return end

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child
	if not child then return end -- no children
local i, t = 0, {}
	repeat
		if child then
		local ret, txt = r.BR_Win32_GetWindowText(child)
	--	t[txt] = child
		t[#t+1] = {child=child,title=txt}
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return next(t) and t
end



function Insert_String_Into_Field_SWS(child_wnd, txt, str)
-- child_t is table stemms from Get_Child_Windows_SWS()
-- txt is optional, only if routines which select
-- the current field text character by character are employed
-- in order to delete the current text before pasting new

local SendMsg = r.BR_Win32_SendMessage

--------------- CLEAR ROUTINE  --------------------------------------------

--	SendMsg(child_wnd, 0x0007, 0, 0) -- WM_SETFOCUS 0x0007 -- makes window unresponsive to clicks even though does place a cursor in the filter field
-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#keystroke-message-flags -- scan codes are listed in a table in 'Scan 1 Make' column in Scan Codes paragraph
-- https://handmade.network/forums/articles/t/2823-keyboard_inputs_-_scancodes%252C_raw_input%252C_text_input%252C_key_names
-- 'Home' (extended key) scan code 0xE047 (move cursor to start of the line) or 0x0047, 'Del' (extended key) scan code 15, Backspace scancode 0x000E or 0x0E (14), Forward delete (regular delete) 0xE053 (extended), Left arrow 0xE04B (extended key), Left Shift 0x002A or 0x02A, Right shift 0x0036 or 0x036 // all extended key codes start with 0xE0
-- 0xFFFFFFFF -- 32 bits all are set
-- BR_Win32_SendMessage only needs the scan code, not the entire composite 32 bit value, not even the extended key flag, the repeat count, i.e. bits 0-15, is ignored, no matter the integer the command only runs once
	-- #txt count works accurately here for Unicode characters as well for some reason
	--[[
	-- move cursor to start of the line
	SendMsg(child_wnd, 0x0100, 0x24, 0xE047) -- 0x0100 WM_KEYDOWN, 0x24 VK_HOME HOME key, 0xE047 HOME key scan code
		for i=1,#txt do -- run Delete for each character
		SendMsg(child_wnd, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 DEL key scan code
		end
	--]]
	--[[ OR
		for i=1,#txt do -- move cursor from line end left character by character deleting them
		SendMsg(child_wnd, 0x0100, 0x25, 0xE04B) -- 0x0100 WM_KEYDOWN, 0x25 LEFT ARROW key, 0xE04B scan code
		SendMsg(child_wnd, 0x0100, 0x2E, 0xE053) -- 0x0100 WM_KEYDOWN, VK_DELETE DEL key virtual key code 0x2E, its scan code is 0xE053
		end
	--]]
	--[-[ OR
	-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
	-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-clear
	r.BR_Win32_SetFocus(child_wnd) -- necessary to make EM_SETSEL work // NOT REQUIRED FOR TEXT DELETION WITH THE ABOVE ALTERNATIVES
	SendMsg(child_wnd, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index
	SendMsg(child_wnd, 0x0303, 0, 0) -- WM_CLEAR 0x0303
	--[=[ OR
	r.JS_Window_SetFocus(child_wnd)
	r.JS_WindowMessage_Send(child_wnd, 0x00B1, 0, 0, -1, 0)
	r.JS_WindowMessage_Send(child_wnd, 0x0303, 0, 0, 0, 0)
	]=]

	--]]

r.CF_SetClipboard(str)
-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-paste
SendMsg(child_wnd, 0x0302, 0, 0) -- WM_PASTE 0x0302 // gets input from clipboard

	if r.JS_WindowMessage_Post then -- using this function because SendMessage() doesn't work with the Enter key codes OR if sent to the MX directory address field
	--r.JS_WindowMessage_Send(child_wnd, 'WM_KEYDOWN', 0x0D, 0, 0x001C, 0) --------- DOESN'T WORK
	r.JS_WindowMessage_Post(child_wnd, 'WM_KEYDOWN', 0x0D, 0, 0x001C, 0) -- 0x0100 WM_KEYDOWN, 0x0D is VK_RETURN i.e. Enter key virtual key code, its scan code is 0x001C, on the keypad its 0xE01C
	else
	r.BR_Win32_SetFocus(child_wnd) -- focus so that text heighlighting is visible
	SendMsg(child_wnd, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index // heighlight text
--	SendMsg(child_wnd, 0x0100, 0x0D, 0x001C) -- 0x0100 WM_KEYDOWN, 0x0D is VK_RETURN i.e. Enter key virtual key code, its scan code is 0x001C, on the keypad its 0xE01C --------- DOESN'T WORK
	Error_Tooltip('\n\n\thit "enter" key \n\n to switch the directory \n\n',1,1) -- caps, spaced true
	end

end


function Get_List_Item_Idx(list_wnd, col_cnt, item_text)
-- go over rows for each column

	if not list_wnd then return end

local col_cnt = col_cnt or 1 -- only traverse 1st column if arg isn't provided
local itm_cnt = r.JS_ListView_GetItemCount(list_wnd) -- number of rows

	if itm_cnt == 0 then return end

local col_idx = 0
	repeat
	local row_idx, text = 0
		repeat
		text = r.JS_ListView_GetItemText(list_wnd, row_idx, col_idx)
			if text == item_text then return row_idx end
		row_idx=row_idx+1
		until row_idx == itm_cnt or not text
	col_idx=col_idx+1
	until col_idx == col_cnt

end


function Scroll_Window(wnd, line_idx)
-- line_idx is 1-based index of the target line

	if not line_idx or line_idx == 0 then return end

	if wnd then
	local SendMsg = r.BR_Win32_SendMessage
	--	set scrollbar to top to procede from there on down by lines
	SendMsg(wnd, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
		for i=1, line_idx-1 do -- -1 to stop scrolling at the target line and not scroll past it
		SendMsg(wnd, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, lParam 0, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll but in fact the message code must be passed here as lParam while wParam must be 0, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage
		-- WM_VSCROLL is equivalent of EM_SCROLL 0x00B5 https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll
		end
	end
end



function SCROLL()
	if r.time_precise() - time_init >= 0.03 then -- waiting 30 ms before scrolling
	local list_wnd
		for k, data in ipairs(child_t) do
			if data.title == 'List1' then -- MX list view window title is List1
			list_wnd  = data.child break
			end
		end
		if list_wnd then
		local file_name = options[3] and cur_path:match('.+[\\/](.+)') or cur_path:match('.+[\\/](.+)%.') -- include extension if enabled in 'Show' settings as 'File extension even if file type displayed'
		local col_cnt = Get_MX_Column_Count()
		local row_idx = Get_List_Item_Idx(list_wnd, col_cnt, file_name) -- isolating file name to the exclusion of its extension because it may be turned off in the 'Show' settings
			if row_idx then
			Scroll_Window(list_wnd, row_idx+1) -- +1 because row_idx return value is 0-based
			end
		--	r.JS_ListView_EnsureVisible(list_wnd, file_idx, false) -- partialOK false
		end
	return
	end
r.defer(SCROLL)
end




-- the SWS extension cannot be fully substitited with js_ReaScriptAPI extension
-- because of CF_SetClipboard() function required for pasting
-- the path into the path box which isn't available in js_ReaScriptAPI extension

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local err = not r.MediaExplorerGetLastPlayedFileInfo and '\nthe script requires\n\nreaper build 7.35 and later'
or not r.BR_Win32_SendMessage and 'the sws/s&m extension \n\n\tisn\'t installed'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n',1,1) -- caps, spaced true
		if r.set_action_options then r.set_action_options(1) end -- auto-terminate just in case
	return r.defer(no_undo) end

retval, cur_path, filemode, selstart, selend, pitchshift, voladj, rateadj, sourcebpm, extrainfo = r.MediaExplorerGetLastPlayedFileInfo() -- keeping global so that cur_path var is accesible inside SCROLL() function

	if not retval then -- OR #cur_path == 0
	Error_Tooltip('\n\n no file is being previewed \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local MX = Find_Window_SWS('Media Explorer')
child_t = Get_Child_Windows_SWS(MX) -- path window is the 7th // must stay global to be accesible inside SCROLL() function
local path_field_wnd
	for k, wnd_data in ipairs(child_t) do
		if wnd_data.title == 'Details' or wnd_data.title == 'List' then
		path_field_wnd = child_t[k-2] -- the path field precedes the field titled 'Details' or 'List' by two indices, their order seems constant so indices are reliable
		break end
	end
local open_folder_path = path_field_wnd.title
local sep = open_folder_path:match('[\\/]')
open_folder_path = open_folder_path:sub(1,-2) == sep and open_folder_path:sub(1,-2) or open_folder_path -- remove trailing separator if any to conform to the pattern for comparison with the stored path

local displayall = Check_reaper_ini('reaper_explorer', 'displayall')
options = Get_Media_Explorer_Show_Submenu_Options(displayall+0) -- must stay global to be accesible inside SCROLL() function

	if not options[6] then
	-- when the path field is turned off, even though the string can be inserted into it
	-- it doesn't respond to Enter key input to make the inserted path open in the list view
	Error_Tooltip('\n\n   "Path drop-down box" option \n\n is disabled in the "show" submenu\n\n'
	..'nowhere to insert the stored path \n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

	if open_folder_path == cur_path:match('(.+)[\\/]') then
	Error_Tooltip('\n\n the directory is currently open \n\n', 1, 1) -- caps, spaced true
	else
	Insert_String_Into_Field_SWS(path_field_wnd.child, path_field_wnd.title, cur_path:match('(.+)[\\/]')) -- path_field_wnd.title arg is optional and isn't used in this design // excluding the file name and last separator to conform to the format of the path displayed in the MX
	end

-- Scroll the file into view
--	MX window is slow to update after directory switching
-- and when the script tries to find the file in the list
-- immediately after switching, the list available to it will
-- still belong to the outgoing directory and the file won't be found;
-- therefore using SCROLL() function in a defer loop
-- to wait until window is likely to update
-- so that scrolling does work;
-- even if the directory is currently open
-- because it will bring the file into view
	if r.JS_WindowMessage_Post then
	-- if the target file remains selected (but not highlighted),
	-- after path switching it's brought into view by MX automatically
	-- this routine however scrolls it regardless of the file status
	-- conditioned by presence of js_ReaScriptAPI extension even though it's not needed for scrolling
	-- because scrolling only makes sense when the target file list is available
	-- which can only be ensured by sending 'Enter' keypress with JS_WindowMessage_Post()
	time_init = r.time_precise() -- must stay global to be accesible inside SCROLL() function
	SCROLL()
	end


do return r.defer(no_undo) end



