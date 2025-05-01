--[[
ReaScript name: BuyOne_Copy or move selected items source media to the specified directory.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Fixed error when settigs aren't managed via menu
	   and no setting is enabled;
	   #Added error messages when selected items have no audio takes;
	   #Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,mediaexplorer] .
Extensions: SWS/S&M or js_ReaScriptAPI for extended functionality
About: 	The script may be useful for quick storage of sampled 
	or sound design audio along with categorizing it within 
	your sample library.

	In its basic functionality the script uses destination
	directory supplied by the user via a dialogue.

	When settings UPDATE_FILE_ASSOCIATION_SEL_ITEMS and 
	UPDATE_FILE_ASSOCIATION_ALL_ITEMS are not enabled the
	script only targets active take in selected items. 
	Therefore if source file only need to be copied to
	another folder without file association update, the
	script will have to be executed for each take in selected 
	item if source media of all their takes need to be copied.

	If the SWS/S&M extension is installed and MEDIA_EXPLORER
	setting is enabled in the USER SETTINGS, the script will
	only work if the Media Explorer (MX) is open and will take 
	the destination directory from the MX path box.

	If in addition to the SWS/S&M extension js_ReaScriptAPI 
	extension is installed or it alone is installed and 
	MEDIA_EXPLORER setting is enabled the script will also 
	scroll the last copied/stored file into view in the MX 
	file list.

	If js_ReaScriptAPI extension isn't installed, sometimes, 
	for reasons which have nothing to do with the script, the 
	file may not appear immediately in the directory open in 
	the MX.  
	This is fixable by refreshing the MX window through either 
	pressing F5 key, toggling MX window visiblity off and on, or 
	running the actions 'Browser: Go to parent folder'
	and 'Browser: Go to previous folder in history'
	as a custom action.			

	The script USER SETTINGS can be managed in real time and 
	tailored to suit the specific use case at each script
	execution provided MANAGE_SETTINGS_VIA_MENU setting is
	enabled in the USER SETTINGS section.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric
-- character between the quotation marks

-- Enable to have the script display settings
-- menu before every run allowing managing
-- them in real time
MANAGE_SETTINGS_VIA_MENU = "1"


-- The setting is only relevant if SWS/S&M or
-- js_ReaScriptAPI extensions are installed,
-- to instruct the script to only work
-- if the Media Explorer is open retrieving the
-- destination directory path from the Media Explorer
-- directory box
MEDIA_EXPLORER = ""


-- Enable to instruct the script to associate
-- selected item take(s) with the file copy
-- placed in the directory open in the Media Explorer
-- as their source media;
-- if the selected item is multi-take, a prompt
-- will allow to select whether to target
-- the active take or all takes in an item;
-- if this setting is enabled, after script execution
-- the project must be saved so new file paths
-- are written into the .RPP file
UPDATE_FILE_ASSOCIATION_SEL_ITEMS = ""


-- Enable to instruct the script to associate
-- all takes in selected items with the file copies
-- placed in the directory open in the Media Explorer
-- as their source media AND in addition to do so
-- for all non-selected items in the project whose takes
-- are using the same source media as all takes in selected items;
-- this setting overrides UPDATE_FILE_ASSOCIATION_SEL_ITEMS
-- setting above;
-- if this setting is enabled, after script execution
-- the project must be saved so new file paths
-- are written into the .RPP file
UPDATE_FILE_ASSOCIATION_ALL_ITEMS = ""


-- Enable to instruct the script to delete the media
-- file from its original location after moving
-- it to the directory open in the Media Explorer;
-- THE SETTING IS ONLY RELEVANT IF UPDATE_FILE_ASSOCIATION_SEL_ITEMS
-- setting is enaled above and the media file is ONLY associated
-- with takes whose source media was updated after file moving,
-- to prevent breaking any other takes which also
-- use the file at its original location as their source,
-- OR IF UPDATE_FILE_ASSOCIATION_ALL_ITEMS setting is enabled above
-- because it leaves no take being associated with the source
-- media at its original location;
-- !!! ENABLE WITH CAUTION BECAUSE FILES MAY BE USED BY OTHER PROJECTS
-- !!! DO NOT EXECUTE UNDO AFTER SCRIPT EXECUTION WITH THIS
-- SETTING ENABLED because items/takes source will be switched
-- to files at their old location where they no longer exist
-- resuling in blank items/takes,
-- if you did execute undo and noticed blank items/takes,
-- reverse it by executing redo with Ctrl+Shift+Z
DELETE_FILE_FROM_OLD_LOCATION = ""

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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest instance of a particular character at the start of a menu item
-- can be used as a shortcut provided this character is unique in the menu
-- in this case they don't have to be preceded with ampersand '&'
-- if it's not unique, inputting it from keyboard will select
-- the menu item starting with this character
-- and repeated input will oscilate the selection between menu items
-- which start with it without actually triggering them
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest instance at the start of a menu item
-- some characters still do need ampresand, e.g. < and >;
-- characters which aren't the first in the menu item name
-- must also be explicitly preceded with ampersand

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and keep_menu_open) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if keep_menu_open is enabled the menu opens every time at the same spot
		if keep_menu_open and not coord_t then -- keep_menu_open is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not keep_menu_open then
		coord_t = nil
		end

	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y

	return gfx.showmenu(menu) -- menu string

	end

end



function Settings_Management_Menu(scr_name, want_help)
-- manage script settings from a menu
-- the function updates the actual script file
-- used in Transcribing A - Create and manage segments (MAIN).lua
-- relies on Reload_Menu_at_Same_Pos2() and Esc() functions
-- want_help is boolean if About text needs to be displayed to the user

::RELOAD::

local sett_t, help_t, about = {}, want_help and {} -- help_t is optional if help is important enough
	for line in io.lines(scr_name) do
	-- collect settings
		if line:match('----- USER SETTINGS ------') and #sett_t == 0 then
		sett_t[#sett_t+1] = line
		elseif line:match('END OF USER SETTINGS')
		and not sett_t[#sett_t]:match('END OF USER SETTINGS') then
		sett_t[#sett_t+1] = line
		break
		elseif #sett_t > 0 then
		sett_t[#sett_t+1] = line
		end
	-- collect help
		if want_help and #help_t == 0 and line:match('About:') then
		help_t[#help_t+1] = line:match('About:%s*(.+)')
		about = 1
		elseif line:match('----- USER SETTINGS ------') then
		about = nil -- reset to stop collecting lines
		elseif about then
		help_t[#help_t+1] = line:match('%s*(.-)$')
		end
	end

local user_sett = {'UPDATE_FILE_ASSOCIATION_SEL_ITEMS','UPDATE_FILE_ASSOCIATION_ALL_ITEMS',
'DELETE_FILE_FROM_OLD_LOCATION'} -- POPULATE WITH ACTUAL SETTING VARIABLES
local menu_sett = {}
	for k, v in ipairs(user_sett) do
		for k, line in ipairs(sett_t) do
		local sett = line:match(v..'%s*=%s*"(.-)"')
			if sett then
			menu_sett[#menu_sett+1] = #sett:gsub(' ','') > 0 and '!' or ''
			end
		end
	end

-- type in actual setting names
local menu = ('USER SETTINGS'):gsub('.','%0 ')..'|(optional, details inside the script)||Update File Association For:|'
..(#menu_sett[2] > 0 and '#!' or menu_sett[1])..'&Selected items|' -- gray out and checkmark if next setting is enabled
..menu_sett[2]..'&All items with same source as selected||'
..((#menu_sett[1] > 0 or #menu_sett[2] > 0) and menu_sett[3] or '#')..'Delete source file from old location||'
..('&RUN'):gsub('.','%0 ')

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return
	elseif output < 4 then goto RELOAD
	elseif output == 6 and #menu_sett[output-3] == 0 then -- delete file from old location setting // offseting the 1st 3 menu items which are titles
		if r.MB((' '):rep(10)..'The file(s) may be used\n\n\tby other projects.\n\n\t Enable anyway?','WARNING',1) == 2 then goto RELOAD -- canceled by the user
		end
	elseif output == 7 then return menu_sett -- return settings changes via the menu and RUN
	end

output = output-3 -- offseting the 1st 3 menu items which are titles
local src = user_sett[output]
local sett = menu_sett[output] == '!' and '' or '1' -- fashion toggle
local repl = src..' = "'..sett..'"'
local cur_settings = table.concat(sett_t,'\n')
local upd_settings, cnt = cur_settings:gsub(src..'%s*=%s*".-"', repl, 1)

	if cnt > 0 then -- settings were updated, get script
	local f = io.open(scr_name,'r')
	local cont = f:read('*a')
	f:close()
	cur_settings = Esc(cur_settings)
	upd_settings = upd_settings:gsub('%%','%%%%')
	cont, cnt = cont:gsub(cur_settings, upd_settings)
		if cnt > 0 then -- settings were updated, write to file
		local f = io.open(scr_name,'w')
		f:write(cont)
		f:close()
		end
	end

goto RELOAD

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
		t[#t+1] = {child=child,title=txt}
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return next(t) and t
end



function Get_Window_And_Children_JS(wnd_title, want_exact_title)
-- want_exact_title is boolean

local want_exact_title = want_exact_title or false -- the argument in the function doesn't support nil

local Find = r.JS_Window_Find
-- more reliable if want_exact_title is true to ignore string appearances
-- for example in script/action names in the Action list
local wnd = not want_exact_title and Find(wnd_title, want_exact_title)
or want_exact_title and Find(wnd_title, want_exact_title) or (Find(wnd_title..' (docked)', want_exact_title) )
local child = wnd and r.JS_Window_GetRelated(wnd, 'CHILD')
local child_t = {}
	if child then
		repeat
		local title = r.JS_Window_GetTitle(child)
	--	child_t[title] = child
	--[-[ OR, depending on the design
		child_t[#child_t+1] = {title=title, child=child}
	 --]]
		child = r.JS_Window_GetRelated(child, 'NEXT')
		until not child
	end

return wnd, child_t

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
	--	set scrollbar to top to procede from there on down by lines
		if r.BR_Win32_SendMessage then
		r.BR_Win32_SendMessage(wnd, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, wParam 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP, lParam 0, https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
		elseif r.JS_WindowMessage_Send then
		r.JS_WindowMessage_Send(wnd, 'WM_VSCROLL', 6, 0, 0, 0) -- wParamHighWord and lParamHighWord 0
		end
		for i=1, line_idx-1 do -- -1 to stop scrolling at the target line and not scroll past it
			if r.BR_Win32_SendMessage then
			r.BR_Win32_SendMessage(wnd, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage. lParam 0
		-- WM_VSCROLL is equivalent of EM_SCROLL 0x00B5 https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll
			elseif r.JS_WindowMessage_Send then
			r.JS_WindowMessage_Send(wnd, 'WM_VSCROLL', 1, 0, 0, 0) -- wParamHighWord and lParamHighWord 0
			end
		end
	end

end



function SCROLL()
row_idx = Get_List_Item_Idx(list_wnd, col_cnt, file_name) -- isolating file name to the exclusion of its extension because it may be turned off in the 'Show' settings
	if row_idx then
	Scroll_Window(list_wnd, row_idx+1) -- +1 because row_idx return value is 0-based
--	r.JS_ListView_EnsureVisible(list_wnd, file_idx, false) -- partialOK false
	return
	end
r.defer(SCROLL)
end


function Get_Media_Path(take)
local source = r.GetMediaItemTake_Source(take) -- OR r.GetMediaItemTakeInfo_Value(take, 'P_SOURCE')
local path = r.GetMediaSourceFileName(source, '')
return path, source
end



function Find_Takes_Using_Same_Media_Source(src_take, src_path)
-- used inside Move_And_Update_Media_Source()
	for i=0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		for i=0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, i)
			if take ~= src_take then
			local source = r.GetMediaItemTake_Source(take)
			local path = r.GetMediaSourceFileName(source, '')
				if path == src_path then return true end
			end
		end
	end
end


function Apply_New_PCM_Source(take, dest_path, old_source)
-- used inside Move_And_Update_Media_Source()
local src = r.PCM_Source_CreateFromFile(dest_path)
r.SetMediaItemTake_Source(take, src)
	if old_source then
	r.PCM_Source_Destroy(old_source)
	end
end


function Move_And_Update_Media_Source(take, media_path, old_source, dest_path)

local dest_path = dest_path:match('.+[\\/]$') and dest_path
or dest_path..dest_path:match('[\\/]') -- adding separator if none
local dest_file_path = dest_path..media_path:match('.+[\\/](.+)')

	-- Copy
	if not r.file_exists(dest_file_path) then -- if the file hasn't been moved/copied yet
	local f = io.open(media_path,'rb') -- read binary mode
	local content = f:read('*a')
	f:close()
	local f = io.open(dest_file_path,'wb') -- write binary mode
	f:write(content)
	f:close()
	end

	-- Update file association and optionally delete the flie from its original location
	if r.file_exists(dest_file_path) then -- successful or existing copy

		if --UPDATE_FILE_ASSOCIATION
		(UPDATE_FILE_ASSOCIATION_SEL_ITEMS or UPDATE_FILE_ASSOCIATION_ALL_ITEMS)
		and media_path ~= dest_file_path then -- only if take isn't already associated with the file at the destination path
		Apply_New_PCM_Source(take, dest_file_path, old_source) -- apply new source deleting the old, the source pointer is unique so its deletion won't affect other takes
		end

		if not Find_Takes_Using_Same_Media_Source(take, media_path) -- only delete the source file from the original location if it's not associated with other takes, if it's only associated with the takes in selected items it will be deleted after file association of the last such take has been updated AND provided all takes were affected and not just the active which depends on the user response to the prompt
		and DELETE_FILE_FROM_OLD_LOCATION then
		os.remove(media_path)
		os.remove(media_path..'.reapeaks') -- and the peaks file if there's any
		end

	return dest_file_path

	end

end


function Dir_Exists(path)
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string represening a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


function Audio_Take_Exists_In_Selected_Items(want_active_take)
	for i=0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
		if want_active_take and not r.TakeIsMIDI(r.GetActiveTake(item)) then return true
		elseif not want_active_take then
			for i=0, r.CountTakes(item, i)-1 do
				if not r.TakeIsMIDI(r.GetTake(item, i)) then return true end
			end
		end
	end
end



local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
or scr_name -- if an non-installed script is run via 'ReaScript: Run (last) ReaScript (EEL2 or lua)' actions get_action_context() won't return valid command ID, in which case fall back on the script full path


local extensions = r.BR_Win32_SendMessage or r.JS_ListView_GetItemCount
MEDIA_EXPLORER = extensions and #MEDIA_EXPLORER:gsub(' ','') > 0

local err = not r.GetSelectedMediaItem(0,0) and 'no selected items'
or MEDIA_EXPLORER and r.GetToggleCommandStateEx(0,50124) == 0 and 'the media explorer is closed' -- Media explorer: Show/hide media explorer

	if err then
	Error_Tooltip('\n\n '..err..' \n\n',1,1) -- caps, spaced true
	return r.defer(no_undo) end

local displayall = Check_reaper_ini('reaper_explorer', 'displayall')
local mx_options = Get_Media_Explorer_Show_Submenu_Options(displayall+0)

	if MEDIA_EXPLORER and not mx_options[6] then
	-- when the path field is turned off, even though the string can be inserted into it
	-- it doesn't respond to Enter key input to make the inserted path open in the list view
	Error_Tooltip('\n\n   "Path drop-down box" option \n\n is disabled in the "show" submenu\n\n'
	..'nowhere to insert the stored path \n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local dest_path

	if MEDIA_EXPLORER then -- extensions are installed and MX is open
	local MX, child_t
		if r.BR_Win32_SendMessage then
		MX = Find_Window_SWS('Media Explorer')
		child_t = Get_Child_Windows_SWS(MX) -- path window is the 7th
		elseif r.JS_ListView_GetItemCount then
		MX, child_t = Get_Window_And_Children_JS('Media Explorer' , 1) -- want_exact_title true
		end

	list_wnd = nil -- must remain global to be accessible for SCROLL() defer function
		for k, wnd_data in ipairs(child_t) do
			if wnd_data.title == 'Details' or wnd_data.title == 'List' then
			dest_path = child_t[k-2].title -- the path field precedes the field titled 'Details' or 'List' by two indices, their order seems constant so indices are reliable
			end
			if wnd_data.title == 'List1' then -- MX list view window title is List1
			list_wnd = wnd_data.child
			end
			if dest_path and list_wnd then break end
		end

	local err = not dest_path and 'the destination directory \n\n    could not be retrieved'
	or #dest_path == 0 and 'the directory address box seems empty'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end
	end


local menu = #MANAGE_SETTINGS_VIA_MENU:gsub(' ','') > 0

::RELOAD::
local user_sett = menu and Settings_Management_Menu(scr_path, want_help) -- want_help nil

	if menu and not user_sett
	then return r.defer(no_undo) -- menu exited
	end


function validate_sett(sett, menu_sett)
return #(menu_sett or sett or ''):gsub(' ','') > 0
end


UPDATE_FILE_ASSOCIATION_SEL_ITEMS = validate_sett(UPDATE_FILE_ASSOCIATION_SEL_ITEMS, user_sett and user_sett[1])
UPDATE_FILE_ASSOCIATION_ALL_ITEMS = validate_sett(UPDATE_FILE_ASSOCIATION_ALL_ITEMS, user_sett and user_sett[2])
DELETE_FILE_FROM_OLD_LOCATION = validate_sett(DELETE_FILE_FROM_OLD_LOCATION, user_sett and user_sett[3])
and (UPDATE_FILE_ASSOCIATION_SEL_ITEMS or UPDATE_FILE_ASSOCIATION_ALL_ITEMS)


local set_items_cnt = r.CountSelectedMediaItems(0)
local all_takes = UPDATE_FILE_ASSOCIATION_ALL_ITEMS

	if UPDATE_FILE_ASSOCIATION_SEL_ITEMS and not all_takes then
		for i=0, set_items_cnt-1 do
		local item = r.GetSelectedMediaItem(0,i)
			if r.CountTakes(item) > 1 then
			local s = function(int) return (' '):rep(int) end
			local resp = r.MB('    Multi-take selected items have been detected.\n\n'
			..'\t'..s(10)..'Should source files\n\n'..s(14)..'of all takes be moved/copied (YES)\n\n'
			..s(16)..'or of the active take only (NO) ?', 'PROMPT', 3)
				if resp == 2 then return r.defer(no_undo) -- aborted by the user
				elseif resp == 6 then all_takes = 1
				end
			break
			end
		end
		if not Audio_Take_Exists_In_Selected_Items(not all_takes) then
		err = all_takes and 'no audio takes in selected items' or 'no active audio take \n\n    in selected items'
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -100) -- caps, spaced true
			if menu then goto RELOAD
			else return r.defer(no_undo)
			end
		end
	elseif not Audio_Take_Exists_In_Selected_Items(not all_takes) then
	err = all_takes and 'no audio takes in selected items' or 'no active audio take \n\n    in selected items'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 0, 50) -- caps, spaced true
		if menu then goto RELOAD
		else return r.defer(no_undo)
		end
	end


	if not MEDIA_EXPLORER then -- extensions aren't installed or installed but MEDIA_EXPLORER setting isn't enabled
	::RETRY::
	dest_path = r.GetExtState(named_ID, 'LAST_USED_DEST_PATH')
	local ret, path = r.GetUserInputs('INPUT DESTINATION DIRECTORY',1,'Last used path:,extrawidth=200',dest_path or '')
		if not ret or #path:gsub(' ','') == 0 then return r.defer(no_undo)
		else
		dest_path = path
			if not Dir_Exists(path) then
			Error_Tooltip('\n\n invalid directory \n\n', 1, 1, x2, 30) -- caps, spaced true, y2 is 30 to prevent tooltip from blocking buttons
			goto RETRY
			end
		end
	r.SetExtState(named_ID, 'LAST_USED_DEST_PATH', dest_path, false) -- persist false
	end


	if (UPDATE_FILE_ASSOCIATION_SEL_ITEMS or UPDATE_FILE_ASSOCIATION_ALL_ITEMS)
	and not DELETE_FILE_FROM_OLD_LOCATION then r.Undo_BeginBlock() end -- only create undo point if not deleting because if file is deleted from its old location, undoing will turn the item blank

local path_t, sel_itm_t = {}, {}
local file_path

	for i=0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
	-- REAPER devs don't recommend using CountSelectedMediaItems()
	-- and GetSelectedMediaItem but to rely on CountMediaItems()
	-- and IsMediaItemSelected() instead
	-- https://forum.cockos.com/showthread.php?p=2807092#post2807092
		if r.IsMediaItemSelected(item) then
		sel_itm_t[item] = item
			for i=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item,i)
				if not r.TakeIsMIDI(take) then
					if all_takes or not all_takes
					and take == r.GetActiveTake(item) then -- OR r.GetMediaItemInfo_Value(item, 'I_CURTAKE') == i
					local media_path, cur_source = Get_Media_Path(take)
					path_t[media_path] = media_path
					file_path = Move_And_Update_Media_Source(take, media_path, cur_source, dest_path)
				--	file_name = file_path:match('.+[\\/](.+)')
					end
				end
			end
		r.UpdateItemInProject(item)
		end
	end


	if UPDATE_FILE_ASSOCIATION_ALL_ITEMS then
	r.PreventUIRefresh(1)
		for i = 0, r.CountMediaItems(0)-1 do
		r.SelectAllMediaItems(0, false) -- selected false // delected all
		local item = r.GetMediaItem(0,i)
			if not sel_itm_t[item] then -- an item different from any of the previously selected ones
				for i=0, r.CountTakes(item)-1 do
				local take = r.GetTake(item,i)
				local media_path, cur_source = Get_Media_Path(take)
					if path_t[media_path] then -- same file as one associated with any of the selected items
					local offline = DELETE_FILE_FROM_OLD_LOCATION and r.Main_OnCommand(40440, 0) -- Item: Set selected media temporarily offline
					local file_path = Move_And_Update_Media_Source(take, media_path, cur_source, dest_path)
					local online = DELETE_FILE_FROM_OLD_LOCATION and r.Main_OnCommand(40439, 0) -- Item: Set selected media online
					end
				end
			end
		end
	-- restore original item selection
	r.SelectAllMediaItems(0, false) -- selected false // delected all
		for item in pairs(sel_itm_t) do
		r.SetMediaItemSelected(item, true) -- selected true
		r.UpdateItemInProject(item)
		end
	r.PreventUIRefresh(-1)
	end


	if --UPDATE_FILE_ASSOCIATION
	(UPDATE_FILE_ASSOCIATION_SEL_ITEMS or UPDATE_FILE_ASSOCIATION_ALL_ITEMS)
	and not DELETE_FILE_FROM_OLD_LOCATION then
	r.Undo_EndBlock('Update item-file association',-1)
	end


	if UPDATE_FILE_ASSOCIATION_SEL_ITEMS or UPDATE_FILE_ASSOCIATION_ALL_ITEMS then
	r.Main_OnCommand(40047, 0) -- Peaks: Build any missing peaks // re-create peaks files for the new file location because peaks files are media file location specific, not file name specific; if DELETE_FILE_FROM_OLD_LOCATION setting is enabled the peaks files will be deleted from there as well, if any; if a peaks file is stored at the location configured at Pref -> General -> Paths it will be re-created there but the old file won't be deleted
	end


	-- Scroll
	if MEDIA_EXPLORER and file_path and r.JS_ListView_GetItemCount then -- only if js_ReaScriptAPI extension is installed
	-- Refresh MX list view with F5 key press message, otherwise the copied/moved file
	-- won't be found in the list and no scrolling will occur;
	-- without refresh the files may not show up visually either;
	-- instead of F5 a custom action where acions
	-- 'Browser: Go to parent folder' and 'Browser: Go to previous folder in history'
	-- could follow the script once it launches the SCROLL() defer function could be used
	-- or 'Media explorer: Show/hide media explorer' action could be run twice twice to refresh the MX window
	-- but since for srolling js_ReaScriptAPI extension is required anyway
	-- inside Get_MX_Column_Count() function
	-- it makes much more sense, is less intrusive and more efficient
	-- to simply use it to refresh the MX file list with F5

--	r.BR_Win32_SendMessage(list_wnd, 0x0100, 0x74, 0x003F) -- 0x0100 WM_KEYDOWN, F5 virtual key code 0x74 VK_F5, F5 scan code 0x003F // DOESN'T WORK
	r.JS_WindowMessage_Post(list_wnd, 'WM_KEYDOWN', 0x74, 0, 0x003F, 0) -- 0x0100 WM_KEYDOWN, F5 virtual key code 0x74 VK_F5, F5 scan code 0x003F
	-- both following vars are global to be accessible inside defer SCROLL()
	file_name = mx_options[3] and file_path:match('.+[\\/](.+)') or file_path:match('.+[\\/](.+)%.') -- exclude extension if disabled in 'Show' settings as 'File extension even if file type displayed'
	col_cnt = Get_MX_Column_Count()
	-- using SCROLL() function in a defer loop
	-- to wait until window is likely to update, which isn't immediate,
	-- so that scrolling does work
	SCROLL()
	end





