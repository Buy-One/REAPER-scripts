--[[
ReaScript name: BuyOne_Run custom actions and scripts from external .ReaperKeyMap file.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI for full functionality
Provides: [main=main,midi_editor] .
About: 	The script allows running custom actions and scripts
		from an external .ReaperKeyMap file via dynamically
		generated menu. This means that custom actions and 
		scripts don't have to reside directly in the Action
		list. Scripts however must be avaialble at the paths 
		they're associated with in the .ReaperKeyMap file.

		Custom actions are supported for the sections Main,
		MIDI Editor, MIDI Event List Editor and Media Explorer.
		To be able to run custom actions which include SWS/S&M
		extension actions the extension is obviously required
		otherwise some or all components of such actions will
		be missing. Extensions are also required to run Media 
		Explorer custom actions regardless of their reliance
		on SWS/S&M extension actions.

		.ReaperKeyMap files available at the script path or
		the one defined in the CUSTOM_PATH setting can be 
		switched via 'ReaperKeyMaps' submenu.

		.ReaperKeyMap files which don't contain custom action
		or script data are grayed out in the menu.

		To accommodate large number of entries in the active
		.ReaperKeyMap file, submenus are created housing a max
		of 20 entries each.

		The identity of the last active .ReaperKeyMap file is
		kept in the memory during the session and stored with
		the project once it's saved.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the double square brackets
-- specify the path to the folder wherefrom
-- you'd like the script to load a list of
-- .ReaperKeyMap files;
-- if empty, script's own path will be used,
-- i.e. the files have to be located where
-- the script is installed
CUSTOM_PATH = [[ ]]

-- To enable the following settigns insert
-- any alphanumeric character between the quotes;
-- these settings can be managed dynamically
-- via the menu;
-- at least one of them must be enabled
-- at all times, otherwise the script
-- doesn't make sense, therefore if both
-- settings are disabled here, LIST_CUST_ACTIONS
-- will be auto-enabled for the duration
-- of the script execution;
-- when the settings are manually updated
-- in the menu they're updated here as well

-- Enable to have custom actions stored inside
-- .ReaperKeyMap files appear in the menu
LIST_CUST_ACTIONS = "1"

-- Enable to have scripts stored inside
-- .ReaperKeyMap files appear in the menu
LIST_SCRIPTS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper


function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
end


function menu_check(sett)
return sett and '!' or ''
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



function Create_Submenus_Dynamically(t, limit)
-- meant for creation of a menu with a limited number
-- of items in the main menu in order to fit within the screen height
-- and placing all items in excess inside submenus
-- accessible from the main menu;
-- t is either a table with values to be displayed as menu items
-- or integer in which case numerals will be used as menu items;
-- limit is integer denoting main menu max item count,
-- if exceeded, for every next menu items count which equals the limit
-- a submenu is created;
-- the main menu is shortened by the number of submenus
-- to accommodate submenu items and prevent exceeding the limit
-- in the main menu itself;
-- if the limit is smaller than the submenu count,
-- main_menu_cnt var will end up being negative
-- and submenus will be created from the very first menu item;
-- one extra submenu over submenu_count value could be added
-- to accommodate remaining outstanding menu items

local tab = type(t) == 'table'
local max_cnt = tab and #t or t
local int, frac = math.modf(max_cnt/limit)
-- count submenus
local submenu_count = int < 1 and 0 or int + (frac ~= 0 and 1 or 0) - 1 -- if there's fractional part count it as another submenu, because it exceeds the items count limit per submenu, subtract 1 to exclude the main menu items because these don't go into the submenu but this isn't mandatory
local main_menu_cnt = limit-submenu_count -- allocate as many items to the main menu as there're going to be submenus by shortening it by submenu count so that main menu's own item count doesn't exceed the limit when submenus are created // the var will be negative if the limit is smaller than the submenu count
local menu, count = '', 0
	for k = 1, max_cnt do
	local v = tab and t[k] or k
	count = k > main_menu_cnt and (count == limit and 1 or count+1) or 0 -- reset once the limit is reached to start next submenu, keeping at 0 while main menu is being concatenated, i.e. as long as main_menu_cnt hasn't been exceeded
	local opening = count == 1 and '>'..k..'-'..(max_cnt-k > limit and k+limit-1 or max_cnt)..'|' or ''
	local closure = count == limit and '<' or ''
--	menu = menu..(#menu > 0 and '|' or '')..opening..closure..v
	menu = menu..(#menu > 0 and (#opening == 0 and '||' or '|') or '')..opening..closure..v
	end
return menu

end



function Toggle_Settings_From_Menu(idx, sett_t, scr_path, exclusive_t)
-- idx is menu output value, i.e. index of the menu item
-- corresponding to the setting being toggled
-- and to the setting index within the table of settings
-- contructed below from the USER SETTINGS section,
-- if in the menu settings don't start at index 1
-- their indices will have to be offset and so idx,
-- because list of settings retrieved from the USER SETTINGS section
-- is indexed from 1;
-- sett_t is table of all settings boolean values in the order
-- they're listed in the USER SETTINGS section;
-- scr_path comes from get_action_context();
-- exclusive_t is and optional argument, a table of toggle settings
-- which are mutually exclusive, where keys are indices of the settings
-- in the menu, offset so that the 1st setting has index 1 to match
-- USER SETTING section sequence, and where values are their boolean values;
-- the function is not designed to work
-- with menu loaded from extended state
-- see USE EXAMPLE below

-- load the settings
local settings, found = {}
	for line in io.lines(scr_path) do
		if #settings == 0 and line:match('----- USER SETTINGS ------') then
		found = 1
		elseif found and line:match('^%s*[%u%w_]+%s*=%s*".-"') then -- ensuring that it's the setting line and not reference to it elsewhere
		settings[#settings+1] = line
		elseif line:match('END OF USER SETTINGS') then
		break
		end
	end

local sett_new_state = sett_t[idx] and '' or '1' -- toggle, relying on the actual user facing value, which may differ from the value in the USER SETTINGS used in the line above
local sett_name = settings[idx]:match('^(%s*[%u%w_]+%s*=)')

-- handle mutually exclusive settings
local exclusive_toggle = exclusive_t and exclusive_t[idx] ~= nil and sett_new_state == '1' -- exclusive_t[idx] may be true or false
	if exclusive_toggle then
		for k in pairs(exclusive_t) do
			if k ~= idx and exclusive_t[k] then -- only if mutually exclusive setting is true to avoid unnecessary writing to this file
			exclusive_t[k] = ''
			end
		end
	end

-- update
local f = io.open(scr_path,'r')
local cont = f:read('*a')
f:close()
local sett_upd = sett_name..' "'..sett_new_state..'"'
local cont, cnt = cont:gsub(settings[idx], sett_upd, 1)

-- update mutually exclusive settings state
	if exclusive_toggle then
		for k, state in pairs(exclusive_t) do
			if k ~= idx and state == '' then
			local sett_name = settings[k]:match('^(%s*[%u%w_]+%s*=)')
			local sett_upd = sett_name..' ""'
			cont, cnt = cont:gsub(settings[k], sett_upd, 1)
			end
		end
	end

	if cnt > 0 then -- settings were updated, write to file
	local f = io.open(scr_path,'w')
	f:write(cont)
	f:close()
	end

return sett_new_state == '1'

end



function ACT(comm_ID, midi, listview)
-- midi and listview are boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, listview)
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end



function MediaExplorer_OnCommand(action_cmdID)
-- https://forum.cockos.com/showthread.php?p=2863268
-- this function has to be run from inside
-- MX section of the Action list or from the Main
-- section when MX window is already open

	if r.GetToggleCommandStateEx(0,50124) == 0 then return end -- MX is closed

-- get handle of an already open MX
local MX = r.OpenMediaExplorer('', false) -- play false
local action_cmdID = r.NamedCommandLookup(action_cmdID) -- works with numeric command IDs of native actions as well passed as either integer or string

	if r.BR_Win32_SendMessage then
	r.BR_Win32_SendMessage(MX, 0x0111, action_cmdID, 0) -- 0x0111 is 'WM_COMMAND'
	elseif r.JS_WindowMessage_Send then
	r.JS_WindowMessage_Send(MX, 'WM_COMMAND', action_cmdID, 0, 0, 0)
	end

end



function MIDIEditor_GetActiveAndVisible()
-- solution to the problem described at https://forum.cockos.com/showthread.php?t=278871
local ME = r.MIDIEditor_GetActive()
local dockermode_idx, floating = r.DockIsChildOfDock(ME) -- floating is true regardless of the floating docker visibility
local dock_pos = r.DockGetPosition(dockermode_idx) -- -1=not found, 0=bottom, 1=left, 2=top, 3=right, 4=floating
-- OR
-- local floating = dock_pos == 4 -- another way to evaluate if docker is floating
-- the MIDI Editor is either not docked or docked in an open docker attached to the main window
	if ME and (dockermode_idx == -1 or dockermode_idx > -1 and not floating
	and r.GetToggleCommandStateEx(0,40279) == 1) -- View: Show docker
	then return ME, dock_pos
-- the MIDI Editor is docked in an open floating docker
	elseif ME and floating then
		-- INSTEAD OF THE LOOP below the following function can be used
		local ret, val = r.get_config_var_string('dockermode'..dockermode_idx)
			if val == '32768' then -- OR val ~= '98304' // open floating docker OR not closed floating docker
			return ME, 4
			end
		--[[ OR
		for line in io.lines(r.get_ini_file()) do
			if line:match('dockermode'..dockermode_idx)
			and line:match('32768') -- open floating docker
			-- OR
			-- and not line:match('98304') -- not closed floating docker
			then return ME, 4 -- here dock_pos will always be floating i.e. 4
			end
		end
		--]]
	end
end




function Esc_Menu_Ops(str)
-- useful when user input or parsed content
-- can affect menu formatting
	for k, op in ipairs({'!','#','>','<','|'}) do
		if str:match('^%s*|') or str:match('^%s*'..'\226\157\152') then -- if pipe (Vetcial Line (U+007C) '\124') or Light Vertical Bar (U+2758) '\226\157\152' which is interpreted by REAPER as pipe, replace with Full Width Vertical Line (U+FF5C) '\239\189\156', OR can be replaced with Box Drawings Light Vertical (U+2502) '\226\148\132' or with Hangul character for /i/ (U+3163) '\227\133\163'
		str = str:gsub('[|\226\157\152]', '\239\189\156', 1)
		elseif str:sub(1,1) == op then
		str = ' '..str -- OR '\r'..str OR '\n'..str // when operator other than pipe is preceeded by space or any other character it's ignored by gfx library, so if it's not the very first character in the string it doesn't need fixing
		end
	end
return str
end



function UnEsc_Menu_Ops(str, pipe)
-- function which reverses the result of Esc_Menu_Ops
-- by stripping leading space and restoring pipe replaced with
-- Full Width Vertical Line (U+FF5C) '\239\189\156';
-- pipe arg is boolean to reinstate the pipe char,
-- i.e. Vetcial Line (U+007C) '\124',
-- if invalid, Light Vertical Bar (U+2758) '\226\157\152'
-- will be reinstated instead which is also replaced
-- with Full Width Vertical Line inside Esc_Menu_Ops()
-- because of being interpreted by REAPER as menu
-- formatting character
local str = str:match('%S.*'):gsub('\239\189\156', pipe and '|' or '\226\157\152')
return str
end



function Dir_Exists(path)
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
local sep = path:match('[\\/]') or '/' -- extract the separator, if path is disk root where the separator isn't listed, use forward slash, which should work on Windows as well
	if not sep then return end -- likely not a string representing a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed so the path is properly formatted for io.open()
local _, mess = io.open(path)
return #path:gsub('[%c%.]', '') > 0 and mess and mess:match('Permission denied') and path--..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
end



function Get_KeyMap_Files(path)

	local function valid_file(f_path)
		for line in io.lines(f_path) do
			if line:match('^[ACRST]+ %d+ %d+') then
			return true
			end
		end
	end

local i, t, sep = 0, {}, path:match('[\\/]')
	repeat
	local file = r.EnumerateFiles(path, i)
		if file and file:match('.+%.ReaperKeyMap$')
	--	and valid_file(path..sep..file)
		then
		t[#t+1] = (valid_file(path..sep..file) and '' or '#')..file:match('(.+)%.ReaperKeyMap')
		end
	i=i+1
	until not file

return t

end



function Extract_Custom_Action_x_Script_Names(path, want_cust_act, want_scr)
local t = {names={},data={}}
local patt = want_cust_act and want_scr and '[ACRTS]+' or want_cust_act and 'ACT' or want_scr and 'SCR'
	for line in io.lines(path) do
		if line:match('^'..patt..' %d+ %d+') then
		-- after escaping the original characters will have to be reinstated
		-- in order to find the name inside the keymap file
		table.insert(t.names, Esc_Menu_Ops(line:match('Custom: (.-)"')))
		-- store the entire entry to seacrh custom action by command ID
		-- rather than name, because name isn't necessarily unique
		table.insert(t.data, line)
		end
	end
-- sort ignoring register, in the original keymap file
-- the names are sorted by register, first upper case then lower
table.sort(t, function(a,b) return a:lower() < b:lower() end)
return t
end



function file_exists(path) -- used inside get_component()
local f, mess = io.open(path, 'r')
	if mess and mess:match('No such file or directory') then return
	else f:close() return true
	end
end



function get_component(ID, scr_name) -- used inside Parse_Custom_Actions_x_Scripts()
-- script or nested custom action,
-- if found in the Action list, can be executed directly by ID
-- otherwise search in the keymap file
-- to execute the script with dofile() if path is valid
-- and execute nested custom action by executing
-- its own components 1 by 1

	local function search(line, ID, file_exists, sep, want_data)
	-- want_data will only be true when nested custom action or script
	-- weren't found in the Action list so cannot be executed directly via
	-- command ID, but were found outside of it to be executed
	-- action by action or with dofile() respectively
		if not ID:match('^RS') then -- custom action
		return '_'..ID, want_data and line -- reinstate the underscore needed for numeric ID retrieval and return the entire custom action data for further parsing
		else -- script, validate existence at the specified path
		local path = line:match('.+" "(.+)"$') or line:match('.+" (.+)$') -- paths with spaces are enclosed within quotes
		path = path:match('^%u:') and path -- absolute path, starts with volume upper case letter, the script is served from outside of the \Scripts folder
		or r.GetResourcePath()..sep..'Scripts'..sep..path
			if file_exists(path) then
			return '_'..ID, want_data and path -- reinstate the underscore needed for numeric ID retrieval and return script path
			end
		end
	end

local ID = ID:sub(1,1) == '_' and ID:sub(2) or ID -- trim leading underscope because IDs are stored in reapr-kb.ini and exported into keymap file without it
local path = r.GetResourcePath()
local sep = path:match('[\\/]')

	-- search in reaper-kb.ini file
	for line in io.lines(path..sep..'reaper-kb.ini') do
		if line:match('^[ACRTS]+ %d+ %d+ "?'..ID) then -- prefix is ACT or SCR custom action IDs are enclosed within quotes
		return search(line, ID, file_exists, sep)
		end
	end

-- not found in reaper-kb.ini file, search in the keymap file
local last_keymap = r.GetExtState(scr_name, 'LAST OPEN ReaperKeyMap')
	for line in io.lines(last_keymap) do
		if line:match('^[ACRTS]+ %d+ %d+ "?'..ID) then -- prefix is ACT or SCR custom action IDs are enclosed within quotes
		return search(line, ID, file_exists, sep, 1) -- want_data true
		end
	end

end



function Parse_Custom_Actions_x_Scripts(data_init, scr_name)

local section = data_init:match('^[ACRST]+ %d+ (%d+)')
local cust_act_ID = data_init:match('^ACT %d+ %d+ "(.-)"')
local executed_script = data_init:match('^SCR') -- when a script is executed directly from the menu
local MX = section == '32063'
local midi = section == '32060' or section == '32061'
local data = data_init:match('.+" (.+)')
local pattern = executed_script and '[^"]+' or '%S+' -- if script is executed directly from the menu adjust pattern so that ID var in the loop below ends up listing its full path, accounting for script names with spaces which are enclosed within quotes
local t = {}

	for ID in data:gmatch(pattern) do
		if ID then

			if cust_act_ID and ID:sub(2) == cust_act_ID then -- SUPER CORNER CASE of custom action being nested inside itself which can only result from manual intervention because REAPER custom action editor doesn't allow such nesting; removing 1st character from ID to strip off the leading underscore if it happens to be a custom action ID;
			Error_Tooltip('\n\n custom action cannot be \n\n     nested inside itself \n\n', 1, 1) -- caps, spaced true
			pause(2)
			return
			end

		ID = executed_script and data_init:match('(RS.+) ') or ID -- when a script is executed directly from the menu extract its ID
		local script, nested_cust_act = ID:match('^_?RS') and 'script', ID:match('^_[%l%d]+') and 'custom action' -- '^_?RS' accommodates cases if script execution directly from the menu because main resource IDs aren't preceded by underscore
		local data
			if script or nested_cust_act then -- script or custom action
			-- search for them in the action list or in the keymap file
			ID, data = get_component(ID, scr_name) -- for nested custom action data var contains action sequence, for script the path
			end
		local id = ID and not data and r.NamedCommandLookup(ID)
			if (not ID or id == 0) then -- nested custom action or script or sws action weren't found in the Action list
			local comp = script or nested_cust_act or 'SWS/S&M action'
			local err = executed_script and 'the script ' or comp and 'a component '..comp..' \n\n'..(' '):rep(script and 6 or 11)
			Error_Tooltip('\n\n '..err..'wasn\'t found \n\n', 1, 1) -- caps, spaced true
			pause(2)
			return
			elseif data then -- wasn't found in the Action list but was in the keymap file
				if nested_cust_act then -- parse
				t = Parse_Custom_Actions_x_Scripts(data, scr_name, t) -- go recursive to parse the nested custom action
				elseif script then
				-- wrapping in anonymous function to prevent immediate execution while storing in the table
				t[#t+1] = function() return dofile(data) end
				end
			else -- neither nested custom action, nor script or either was found in the Action list
			-- wrapping in anonymous function to prevent immediate execution while storing in the table
			t[#t+1] = MX and function() return MediaExplorer_OnCommand(id) end
			or function() return ACT(id, midi, section == '32061') end
			end
		end
	end

return t

end




Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_path:match('([^\\/]+)%.%w+') -- without path and extension
local path = Dir_Exists(CUSTOM_PATH) --returns path without trailing separator, if any

	if CUSTOM_PATH:match('%S') and not path
	and r.MB('The custom path wasn\'t found.\n\nWish to switch to script path?','PROMPT',4) == 7 then
	return r.defer(no_undo)
	end

path = path or scr_path:match('.+[\\/]') -- without trailing separator
local sep = path:match('[\\/]')
local keymaps_t = Get_KeyMap_Files(path)

	if #keymaps_t == 0 then
	Error_Tooltip('\n\n  no supported files \n\n at the current path \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local file_menu = '>ReaperKeyMaps|'..table.concat(keymaps_t,'|')
local i = 0
file_menu = file_menu:gsub('|', function(c) i=i+1; if i==#keymaps_t then return '|<' end end) -- close submenu
local key = 'LAST OPEN ReaperKeyMap'

local list_scr = LIST_SCRIPTS:match('%S')
local cust_act = LIST_CUST_ACTIONS:match('%S')
local sett_t = {cust_act or not list_scr, list_scr or false} -- maintaining the order of settings in the script USER SETTINGS; alternative for disable settings must be 'false' to maintain table integrity for further manipulation as nil breaks it; at least one setting must always be active otherwise script doesn't make sense, if both happen to be disabled in the script settings LIST_CUST_ACTIONS is auto-enabled here

::RELOAD::

local sett_menu = '>SETTINGS|'..menu_check(sett_t[1])..'List custom actions|'..menu_check(sett_t[2])..'<List scripts'
local last_keymap = r.GetExtState(scr_name, key)
local ret
	if #last_keymap == 0 then
	ret, last_keymap = r.GetProjExtState(0, scr_name, key)
		if ret == 1 then -- store to global ext state
		r.SetExtState(scr_name, key, last_keymap, false) -- persist false
		end
	end

	-- if since the last use user has changed the path
	-- reset the extended state so that actions from
	-- file in the old location aren't displayed in the menu
	if #last_keymap > 0 and last_keymap:match('(.+)[\\/]') ~= path
	then
	last_keymap = ''
	end

	if #keymaps_t > 1 and #last_keymap > 0 then
	-- add checmark to the active keymap file in the menu if there're several
	file_menu = file_menu:gsub('|<?!', function(c) return c:match('<') and '|<' or '|' end) -- remove checkmark from all other menu items
	local f_name = last_keymap:match('([^\\/]+)%.ReaperKeyMap')
	local esc_f_name = Esc(f_name)
	file_menu = file_menu:gsub('|'..esc_f_name..'|', '|!'..f_name..'|', 1) -- limit capture by pipes which separate menu items to prevent false positives where file name is found within another menu item name
		if not file_menu:match('|!') then -- checkmark wasn't added likely because the name belongs to the last item which is preceded by < and isn't followed by pipe
		file_menu = file_menu:gsub('|<'..esc_f_name, '|<!'..f_name, 1)
		end
	end

local cust_act_t = #last_keymap > 0 and Extract_Custom_Action_x_Script_Names(last_keymap, sett_t[1], sett_t[2]) -- want_cust_ac and want_scr depend on in the settings

	if cust_act_t and #cust_act_t.names == 0 then
	local act, scr = sett_t[1] and 'custom actions', sett_t[2] and 'scripts'
	local resourse = act and scr and act..' \n\n  or '..scr or act or scr
	Error_Tooltip('\n\n no '..resourse..' found \n\n', 1, 1) -- caps, spaced true
		if act and scr then
		-- delete path of the last selected file
		r.DeleteExtState(scr_name, key, true) -- persist true
		r.SetProjExtState(0, scr_name, key, '') -- delete the value
		pause(1)
		end
	end

local cust_act_menu = cust_act_t and #cust_act_t.names > 0 and Create_Submenus_Dynamically(cust_act_t.names, 20)
local menu = sett_menu..'|||'..file_menu..(cust_act_menu and '|||' or '|')..(cust_act_menu or '')
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo)
	elseif output <= #sett_t then -- toggle settings
	sett_t[output] = Toggle_Settings_From_Menu(output, sett_t, scr_path) -- exclusive_t false, not used here
	local active
		for k, sett in ipairs(sett_t) do
			if sett then active = 1 break end
		end
		if not active then -- no enabled settings
		Error_Tooltip('\n\n all settings cannot be disabled \n\n', 1, 1) -- caps, spaced true
		pause(2)
		sett_t[output] = true -- re-enable what has just been disabled
		end
	elseif output > 2 and output <= #sett_t+#keymaps_t then -- select keymap files
	local output = output-#sett_t -- offset by sett_t table length
	local keymap = path..sep..keymaps_t[output]..'.ReaperKeyMap'
	r.SetExtState(scr_name, key, keymap, false) -- persist false
	r.SetProjExtState(0, scr_name, key, keymap)
	elseif output > #sett_t+#keymaps_t then -- run custom action
	local output = output - #keymaps_t - #sett_t -- offset by the keymaps_t and sett_t tables length

	local data = UnEsc_Menu_Ops(cust_act_t.data[output], 1) -- pipe arg true, reinstate escaped menu formatting special chars

		if not data then -- reinstatement of pipe char failed to restore the original cutom action name
		-- reinstate Light Vertical Bar
		data = UnEsc_Menu_Ops(cust_act_t.data[output]) -- pipe arg false in case pipe hadn't been the original character which was replaced
		end

		if not data then -- usually should not happen but just in case
		Error_Tooltip('\n\n    couldn\'t parse \n\n the custom action \n\n', 1, 1) -- caps, spaced true
		pause(2)
		else
		local sect = data:match('ACT %d+ (%d+)')
		local err = sect == '32063' and not r.BR_Win32_SendMessage and not r.JS_WindowMessage_Send
		and 'SWS/S&M or js_reascript_API \n\n    extensions are required\n\n     to run media explorer\n\n\t   custom actions'
		err = err or (sect == '32060' or sect == '32061') -- MIDI Ed, MIDI Event List
		and not MIDIEditor_GetActiveAndVisible() and 'the midi editor is closed'
		or sect == '32063' -- MX
		and r.GetToggleCommandStateEx(0, 50124) == 0 -- Media explorer: Show/hide media explorer
		and 'the media explorer is closed'
			if err then
			Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
			pause(3)
			else -- execute
			local custom_act_t = Parse_Custom_Actions_x_Scripts(data, scr_name) -- get all the component actions
				if custom_act_t then -- execute
				r.Undo_BeginBlock()
					for k, act in ipairs(custom_act_t) do
					act()
					end
				r.Undo_EndBlock(cust_act_t.names[output], -1)
				end
			end
		end
	end

goto RELOAD



