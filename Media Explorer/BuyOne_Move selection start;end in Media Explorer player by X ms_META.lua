--[[
ReaScript name: BuyOne_Move selection start;end in Media Explorer player by X ms_META.lua (9 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Fixed defaulting to 100 ms when user selected value is 0
	   #Added error when the Media Explorer is closed
	   #Added 2 new scripts to the META set
	   #Updated 'About' text
Licence: WTFPL
REAPER: 7.12 and newer
Extensions: SWS/S&M
Provides: [main=main,mediaexplorer]
	. > BuyOne_Move selection start in Media Explorer player right by X ms.lua
	. > BuyOne_Move selection start in Media Explorer player left by X ms.lua
	. > BuyOne_Move selection end in Media Explorer player right by X ms.lua
	. > BuyOne_Move selection end in Media Explorer player left by X ms.lua
	. > BuyOne_Move selection in Media Explorer player right by X ms.lua
	. > BuyOne_Move selection in Media Explorer player left by X ms.lua
	. > BuyOne_Move selection start in Media Explorer player by X ms with mousewheel.lua
	. > BuyOne_Move selection end in Media Explorer player by X ms with mousewheel.lua
	. > BuyOne_Move selection in Media Explorer player by X ms with mousewheel.lua
About:	If this script name is suffixed with META it will spawn 
	all individual scripts included in the package into the 
	directory of the META script and will import them into 
	the Action list from that directory. That's provided such 
	scripts don't exist yet, if they do, then in order to 
	recreate them they have to be deleted from the Action list 
	and from the disk first.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name.			
	
	The script doesn't create undo points.
				
	If the current script contains the word 'start' in its name
	it can be used to move MX player playback start position. 
	If there's no selection it will be created automatically
	as soon as the selection start position change.
	
	If the current script contains the word 'mousewheel' in its 
	name, it can be run with the mousewheel only if installed in 
	the Main section of the Action list. For the mousewheel input 
	to be registered the Media Explorer window, Arrange or Track 
	must be focused but not the Media Explorer player because 
	this switches mousewheel focus to the player scrollbar.  
	The mousewheel input isn't registered by the script instance 
	installed in the Media Explorer section.  
	Mousewheel direction is in/down - left, out/up - right.
	
	The behavior of each mousewheel script can be simulated with 
	a custom action made up of non-mousewheel scripts and modifier
	actions mapped to the mousewheel, e.g.
	
	Custom: Move selection start in Media Explorer player by X ms with mousewheel 
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Move selection start in Media Explorer player right by X ms.lua  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Move selection start in Media Explorer player left by X ms.lua
		
	Custom: Move selection end in Media Explorer player by X ms with mousewheel 
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Move selection end in Media Explorer player right by X ms.lua  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Move selection end in Media Explorer player left by X ms.lua
						
	Custom: Move selection in Media Explorer player by X ms with mousewheel  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Move selection in Media Explorer player right by X ms.lua  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Move selection in Media Explorer player left by X ms.lua

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotation marks insert value in milliseconds
-- by which to change MX player time selection start/end position or both
-- depending on the script name,
-- if the setting is empty, zero, negative or invalid it defaults to 100 ms
VALUE_IN_MS = ""

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



function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

	if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

local names_t, content = names_t

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

	-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		-- spawn scripts
		-- THERE'RE USER SETTINGS
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32063} do -- Main, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

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
		t[#t+1] = {child=child,title=txt}
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return next(t) and t
end


function Insert_String_Into_Field_SWS(child_wnd, str)
-- child_t is table with Region/Marker Manager children windows
-- stemming from Get_Child_Windows_SWS()
-- one of which is the filter field window that's nameless if empty

local SendMsg = r.BR_Win32_SendMessage

--------------- CLEAR ROUTINE  --------------------------------------------

--	r.BR_Win32_SetFocus(child_wnd) -- this is unnecessary unless the window must be made a target for keyboard input

-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#keystroke-message-flags -- scan codes are listed in a table in 'Scan 1 Make' column in Scan Codes paragraph
-- https://handmade.network/forums/articles/t/2823-keyboard_inputs_-_scancodes%252C_raw_input%252C_text_input%252C_key_names
-- 'Home' (extended key) scan code 0xE047 (move cursor to start of the line) or 0x0047, 'Del' (extended key) scan code 15, Backspace scancode 0x000E or 0x0E (14), Forward delete (regular delete) 0xE053 (extended), Left arrow 0xE04B (extended key), Left Shift 0x002A or 0x02A, Right shift 0x0036 or 0x036 // all extended key codes start with 0xE0
	-- #filter_cont count works accurately here for Unicode characters as well for some reason
	--[[
	-- move cursor to start of the line
	SendMsg(child_wnd, 0x0100, 0x24, 0xE047) -- 0x0100 WM_KEYDOWN, 0x24 VK_HOME HOME key, 0xE047 HOME key scan code
		for i=1,#filter_cont do -- run Delete for each character
		SendMsg(child_wnd, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 DEL key scan code
		end
	--]]
	--[[ OR
		for i=1,#filter_cont do -- move cursor from line end left character by character deleting them
		SendMsg(child_wnd, 0x0100, 0x25, 0xE04B) -- 0x25 LEFT ARROW key, 0xE04B scan code
		SendMsg(child_wnd, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 scan code
		end
	--]]
	--[-[ OR
	-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
	-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-clear
	SendMsg(child_wnd, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index
	SendMsg(child_wnd, 0x0303, 0, 0) -- WM_CLEAR 0x0303
	--]]
--------------------------------------------------------------
r.CF_SetClipboard(str)
SendMsg(child_wnd, 0x0302, 0, 0) -- WM_PASTE 0x0302 // gets input from clipboard
-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-paste

end


function Dir_Exists(path) -- short
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string represening a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


Error_Tooltip('') -- clear any stuck tooltips, especially relevant for mousewheel run scripts

local err = not r.BR_Win32_SendMessage and 'the SWS/S&M extension \n\n       isn\'t installed '
or tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.12 and 'the script is only suported \n\n     in reaper builds 7.12+'
or r.GetToggleCommandStateEx(0, 50124) == 0 and 'the media explorer is closed'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local is_new_value, fullpath_init, sectID, cmdID, mode, resol, val, contextstr = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('([^\\/]+)%.lua') -- without path & ext

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Move selection start;end in Media Explorer player by X ms_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

--scr_name = ' start mousewheel ' ------------------- NAME TESTING, must be padded

local sel_start, sel_end, right, left, mousewheel = scr_name:match(' start '), scr_name:match(' end '),
scr_name:match(' right '), scr_name:match(' left '), scr_name:match('mousewheel')

local err = not ((sel_start or sel_end) and (right or left)) and not mousewheel and 'the script name has been altered \n\n please restore the original name' or mousewheel and val > 15 and 'the script isn\'t run \n\n with the mousewheel '

	if err then
	Error_Tooltip('\n\n '..err..'\n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


VAL = VALUE_IN_MS:gsub(' ','')
VAL = #VAL > 0 and tonumber(VAL) or 100
VAL = math.abs(VAL)/1000 -- rectify negative value in case not default and convert to seconds
VAL = VAL > 0 and VAL or 0.1 -- converting to seconds


local MX_hwnd = Find_Window_SWS('Media Explorer', want_main_children)
local child_t = Get_Child_Windows_SWS(MX_hwnd)

-- Find selection start input window
local start_input_wnd_idx

	for k, data in ipairs(child_t) do
		if data.title:match('^%d+:%d+%.%d+$') then start_input_wnd_idx = k break end
	end

	if not start_input_wnd_idx then -- the window is either empty or the value format is not 0:00.000 which isn't suitable for this script
	Error_Tooltip('\n\n\teither no file is loaded \n\n\t  into the MX player or \n\n'
	..'      "display preview position\n\n in beats" option is/was enabled \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local start_props, end_props = child_t[start_input_wnd_idx], child_t[start_input_wnd_idx+1]
local target_wnd = sel_start and start_props.child or sel_end and end_props.child

local parse = r.parse_timestr

-- GET FILE LENTH to be able to compare selection end position with it and generate an error if it exceeds it
local length, selection_bounds
-- must be searched within a loop because child window index changes depending on the shown windows
	for k, data in ipairs(child_t) do
	selection_bounds = selection_bounds or data.title:match('^%d+:%d+%.%d+  /  %d+:%d+%.%d+$') -- won't be found if option 'Display preview position in beats for audio files...' or 'Display preview position in whole seconds or beats' because the second value will have decimal format or the first value won't include miliseconds respectively
	length = length or data.title:match('Length: (.-)\n') -- works even if 'Media information box' is closed
		if selection_bounds and length then break end
	end


length = length and parse(length)

-- file length is also listed in the 'Length' column of the file browser but it cannot be accessed with SWS API

	if not length then -- alternative to info box, use file pcm source to get the length // normally unnecessary
	-- look for file path window in a loop below because if some windows are closed looking by window index won't work,
	-- will be found even if 'Path drowdown box' is closed
	local file_path
		for k, data in ipairs(child_t) do
		file_path = Dir_Exists(data.title)
			if file_path then break end
		end
	-- as of build 7.28 file name readout window follows end props window, which start props window index + 2
	local file_name = child_t[start_input_wnd_idx+2].title
	file_path = file_path and file_name and file_path..file_name -- file path includes trminating separator returned by Dir_Exists()
	local pcm_src = r.PCM_Source_CreateFromFile(file_path)
	local ret, offs, rev
	ret, offs, length, rev = r.PCM_Source_GetSectionInfo(pcm_src) -- doesn't need to be run through parse_timestr() afterwards because the return value is number
	length = math.floor(length*(1000)+0.5)/1000 -- length value is a long float, so round down to 3 decimal places to be able to accurately compare with selection end value taken from the end readout window
	end


-- Determine whether there's active selection
-- won't be possible if options 'Display preview position in beats for audio files...'
-- or 'Display preview position in whole seconds or beats' because they change readout format
local sel_st, sel_fin = table.unpack(selection_bounds and {selection_bounds:match('^(%d+:%d+%.%d+)  /  (%d+:%d+%.%d+)$')} or {})
sel_st, sel_fin = sel_st and parse(sel_st), sel_fin and parse(sel_fin)

	-- when there's no selection, moving its end beyond media length or its start beyond zero position doesn't auto-create selection
	-- so must be aborted, selection is auto-created if start/end are moved in the opposite direction though
	-- technically the cursor can be located at the very start and then the values will resemble the state
	-- when the selection encompasses the entire media, however this is not very likely
	if sel_st and sel_st ~= 0 and (sel_fin == length or sel_fin-0.001 == length) -- when there's no selection the readout left hand value shows cursor position while the right hand value shows total media length // sel_fin value displayed in the selection end readout may be greater by 1 ms than the length value displayed in the 'Media information box' and will actually match the length returned by PCM_Source_GetSectionInfo() and rounded down
	and (not mousewheel and (left or right)
	or mousewheel and (sel_start and val < 0 or sel_end and val > 0) -- mousewheel dedicated to either start or end
	or mousewheel and not sel_start and not sel_end) -- mousewheel dedicated to both start and end, moving entire selection
	then
	local addition = mousewheel and (sel_start or sel_end) and ' try in the opposite direction \n\n' or '' -- only add in scripts where mousewheel only controls one end of the selection
	Error_Tooltip('\n\n there\'s no active selection \n\n'..addition, 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local st, fin = parse(start_props.title), parse(end_props.title)

local parm = sel_start and st or sel_end and fin

	if not mousewheel and (parm and (left and parm <= 0 or right and parm >= length) or left and st <= 0 or right and fin >= length)
	or mousewheel and parm and (val < 0 and parm <= 0 or val > 0 and parm >= length) -- mousewheel dedicated to either start or end
	or mousewheel and not parm and (val < 0 and st <= 0 or val > 0 and fin >= length) -- mousewheel dedicated to both start and end, moving entire selection
	then
	Error_Tooltip('\n\n    the limit has been reached \n\n or there\'s no active selection \n\n', 1, 1) -- caps, spaced true // if options 'Display preview position in beats for audio files...' and/or 'Display preview position in whole seconds or beats' are enabled the 'no active time selection' error message won't be generated above and the script will continue running up until this point, here 'no active selection' alternative is based on the fact that when there's no active selection st and fin values will be equal to 0 and media length respectively resembling the state when the selection encompasses the entire media, but it's impossible to determine what the actual state is hence two suggestions
	return r.defer(no_undo)
	end

VAL = mousewheel and parm and (val < 0 and parm-VAL or val > 0 and val < 63 and parm+VAL) -- mousewheel dedicated to either start or end
or mousewheel and (val < 0 and {st-VAL, fin-VAL} or val > 0 and val < 63 and {st+VAL, fin+VAL}) -- mousewheel dedicated to both start and end, moving entire selection
or not mousewheel and (parm and (right and parm+VAL or left and parm-VAL) or right and {st+VAL, fin+VAL} or left and {st-VAL, fin-VAL})
-- prevent going beyond limits, which is technically possible
VAL = tonumber(VAL) and (VAL < 0 and 0 or VAL > length and length)
or type(VAL) == 'table' and (VAL[1] < 0 and {0, VAL[2]-VAL[1]}  or VAL[2] > length and {VAL[1]+length-VAL[2], length})
or VAL

	if tonumber(VAL) and (sel_start and VAL >= fin or sel_end and VAL <= st) then -- impossible if both selection ends move simultaneously
	Error_Tooltip('\n\n new position clears selection \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

	if tonumber(VAL) then
	Insert_String_Into_Field_SWS(target_wnd, r.format_timestr(VAL,''))
	else -- table // mousewheel affects both start and end of the selection
		for k, val in ipairs(VAL) do
		local child_wnd = k == 1 and start_props.child or end_props.child
		Insert_String_Into_Field_SWS(child_wnd, r.format_timestr(val,''))
		end
	end

do return r.defer(no_undo) end



