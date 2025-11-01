--[[
ReaScript name: BuyOne_Remove invalid project references from 'Recent projects' menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Cleans 'Recent projects' menu from invalid file references.			
		REAPER only allows cleaning the menu project by project
		and only at an attempt to open them.

		The feature was introduced natively in build 7.50:
		* add action (under 'Recent project list display' button on Preferences > General) 
		to remove missing projects from recent project list
]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
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



function ShowMessageBox_Menu(message_lines, buttons_t, list_t, title)
-- message_lines is a multi-line literal string
-- a line per menu item, empty lines are supported
-- buttons_t is a table of button captions
-- title is the dialogue title to be displayed at the very top
-- if invalid 'PROMPT' title is used
-- relies on Reload_Menu_at_Same_Pos() function

	local function center_text(t, max_len)
		for k, line in ipairs(t) do
		local line_len = #line:gsub('[\128-\191]','')
			if line_len < max_len then
		--	local diff = (max_len-line_len)/4
		--	diff = math.floor(diff*3+0.5) -- figured out empirically, 3/4 or 4/5 of the difference give the best result with English though not ideal, for Russian 5/6 // ideally pixels must be counted rather than characters
		-- OR simply
			local diff = math.floor((max_len-line_len) * 4/5 + 0.5)
			t[k] = (' '):rep(diff)..line -- add leading spaces to center the line // may not be accurate if lines text is in different register
			end
		end
	return t
	end

	local function adjust_button_pos(max_len, button)
	return (' '):rep(math.floor((max_len-#button)/2+0.5))..button
	end

message_lines = not message_lines:sub(-1):match('\n') and message_lines..'\n' or message_lines -- OR message_lines:sub(-1) ~= '\n' etc. -- ensures that the last line is captured with gmatch search
local buttons_t = buttons_t or {'Button 1', 'Button 2', 'Button 3'}

local message_t, max_len = {}, 0

	for line in message_lines:gmatch('(.-)\n') do -- accounting for empty lines if any
		if line then
		line = line:match('(%S.-)%s*$') or line -- trimming both leading and trailing spaces if any, leading spaces will be added for centering inside center_text()
		local line_len = #line:gsub('[\128-\191]','') -- removing continuation (trailing) bytes
		max_len = math.max(line_len, max_len)
		message_t[#message_t+1] = line..'|'
		end
	end

	for i = #list_t, 1, -1 do
	local line = list_t[i]
		if #line:gsub('[\128-\191]','') > max_len then
		local collected, idx
			for char in line:gmatch('.') do
				if collected and #collected:gsub('[\128-\191]','') == max_len then
				idx = not idx and i+1 or idx+1
				table.insert(list_t, idx, collected)
				collected = nil -- reset
				end
			collected = collected and collected..char or char
			end
			if collected then
			table.insert(list_t, idx+1, collected)
			end
		table.remove(list_t, i)
		end
	end

-- Center the message
message_t = center_text(message_t, max_len)
buttons_t = center_text(buttons_t, max_len)

local title = title or 'PROMPT'
title = ('  '):rep((max_len-#title)/2)..title
buttons_t[1] = '&1.'..adjust_button_pos(max_len, buttons_t[1])
buttons_t[2] = '&2.'..adjust_button_pos(max_len, buttons_t[2])
buttons_t[3] = '&3.'..adjust_button_pos(max_len, buttons_t[3])..'|'..(' '):rep(40)..'or click away from the menu'
local menu = title..'||'..table.concat(message_t)..'||'..table.concat(buttons_t,'|')..'|||'..table.concat(list_t, '|')

::RELOAD::
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open is true

	if output == 0 then return
	elseif output > #message_t+1 and output < #message_t+6 then -- a button was pressed, +1 to account for the title, +5 to account for the title and dialogue options, excluding the project references list
	return output-#message_t-1 -- return button index, -1 to account for the title
	elseif output <= #message_t+1 or output >= #message_t+6 then -- if title, message menu item was clicked, +1 to account for the title
	goto RELOAD
	end

end


function Clean_Recent_Projects_Menu()

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

local path = r.get_ini_file()
local t = {recent={}}

-- collect reaper.ini content
local recent
	for line in io.lines(path) do
	t[#t+1] = line
		if line:match('%[Recent%]') then recent = 1 -- section start
		elseif recent then
			if line:match('^recent%d+=') then
			t.recent[#t.recent+1] = line
			else recent = nil -- reset, section end
			end
		end
	end

local list_len = #t.recent -- store length because it may change

	if list_len == 0 then
	r.MB('The "Recent projects" list empty.', 'INFO',0)
	return r.defer(no_undo) end

local ini = table.concat(t, '\n')
local source = Esc(table.concat(t.recent,'\n')) -- escape for gsub below

-- remove and collect invalid entries
t.remove = {}
	for i=#t.recent,1,-1 do
	local line = t.recent[i]
	-- file_exists() returns true if passed a file name only and a file with the same name
	-- is found in the current working directory, which is a bug https://forum.cockos.com/showthread.php?t=300386
	-- so must be additionaly validated
		if not line:match('^recent%d+=(.+)'):match('[\\/]') -- excluding file names without a path, i.e. without separators, due to the bug mentioned above
		or not r.file_exists(line:match('^recent%d+=(.+)')) then
		t.remove[#t.remove+1] = line
		table.remove(t.recent,i)
		end
	end

local output

	if #t.recent == list_len then -- or #t.remove == 0
	r.MB('No invalid project references\n\n  in the "Recent projects" list.', 'INFO',0)
	return r.defer(no_undo)
	else
	table.sort(t.remove, function(a,b) return a:match('recent(%d+)') > b:match('recent(%d+)') end) -- sort in descending order, in reaper.ini the order may not be consistent
		-- trim recent keys for the sake of display the entries in the prompt in ShowMessageBox_Menu()
		for k, line in ipairs(t.remove) do
		t.remove[k] = line:match('recent%d+=(.+)') -- trim the keys
		end

	local message_lines = 'The following invalid references will be removed.\nChoose option 1. to quit REAPER so that the changes take effect immediately.\nSave any unsaved work or assent to dialogue(s) which may pop up.\nRestart REAPER manually.\nChoose option 2. to allow the changes to take effect later\nhowever they will be reverted if before quitting REAPER\nyou load another project.\nWhatever your choice is a backup copy of reaper.ini file\nnamed reaper.ini-bak will be created.\nIf after REAPER restart everything is good, you may\ndelete the backup file from REAPER resource directory.\n'
	local space = function(str, num) str = str:gsub('.','%0'..(' '):rep(num or 1)) return str end
	output = ShowMessageBox_Menu(message_lines, {space('CONFIRM AND QUIT REAPER')..'|', space('CONFIRM WITHOUT QUITTING')..'|', space('DECLINE', 3)}, t.remove, space('PROMPT', 4))

		if not output or output > 2 then return r.defer(no_undo) end -- menu exited or user declined

	end


	-- renumber the remaining entries
	for k, line in ipairs(t.recent) do
	local pad = k < 10 and '0' or '' -- only single digit numbers are padded, the recent list length limit is 100
	t.recent[k] = line:gsub('recent%d+', 'recent'..pad..k)
	end

local repl = table.concat(t.recent,'\n'):gsub('%%','%%%%') -- escape
local backup_ini = ini -- assign here because ini var will change
local ini, repl_count = ini:gsub(source, repl)

	if repl_count == 0 then
	r.MB('The "Recent projects" list update failed. Sorry!','ERROR',0)
	return r.defer(no_undo) end

-- create a backup ini file
local backup = r.GetResourcePath()..path:match('[\\/]')..'reaper.ini-bak' -- construct because r.get_ini_file() returns file name in upper case
local f = io.open(backup, 'w')
f:write(backup_ini)
f:close()

-- update reaper.ini file
local f = io.open(path, 'w')
f:write(ini)
f:close()

	if output == 1 then -- user confirmed quitting
	r.Main_OnCommand(40004, 0) -- File: Quit REAPER // the recent project list in reaper.ini is updated without REAPER exit as well, HOWEVER the old list gets restored if another project is loaded after the list has been updated, because the original list is stored in the RAM and gets written into reaper.ini as soon as it's changed, the script obviously cannot access the data in the RAM and so cannot override it completely
	end

end


Clean_Recent_Projects_Menu()



