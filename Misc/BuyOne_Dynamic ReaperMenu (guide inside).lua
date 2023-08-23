--[[
ReaScript name: BuyOne_Dynamic ReaperMenu (guide inside).lua
Provides: [main=main,midi_editor] .
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.3
Changelog: 	
		v1.3 #Added submenu of menu/toolbar files located in the same directory
		     as the currently loaded one for quick access
		v1.2 #Added buttons to cycle menu/toolbar files in the current directory
		     #Updated About text
		     #Moved utility buttons to the top of the menu
		     #Added more error proofing
		v1.1 #Added KEEP_MENU_OPEN setting
		     #Simplified display of error messages which don't require user input
		     #Did minor code optimizations
About:

	#### GUIDE
	
	- The script is designed to allow using REAPER menus independently of REAPER
	menu system by loading .ReaperMenu files on demand, which essentially allows
	potentially having and using many more menus and toolbars than the REAPER
	native menu system provides.
	
	- The dynamic part implies that a currently loaded menu can at any moment be
	replaced with another one.
	
	- .ReaperMenu files are menu and toolbar dumps which can be created with
	*Export -> Export current menu/toolbar to ReaperMenu file...* option in the
	*Customize menus/toolbars* section accessible from the main *Options* menu
	in the default REAPER installation.
	
	- So when you need another menu/toolbar but have used up all menus/toolbars
	available in REAPER natively, you can create a backup copy of one of the current
	menus/toolbars, put together a new one in its place, export the newly created 
	menu/toolbar to a .ReaperMenu file, then restore the previous one and use such 
	exported menu/toolbar via this script.
	
	- Toolbars loaded with this script are formatted as regular menus.
	
	- In the USER SETTINGS below the script provides options to specify the full
	path to the .ReaperMenu file per supported section of the Action list.    
	If such path isn't specified, at the first run the script will offer loading 
	a file from a location on a hard drive, whose full path will then be stored so 
	it can be loaded automatically on next runs until another menu file is loaded.
	
	- The default directory which the load dialogue is pointed to is \MenuSets in the
	REAPER resource directory, the one to which REAPER offers to save its .ReaperMenu
	files by default. But the file can be browsed to and loaded from elsewhere.  
	The file path specified in the USER SETTINGS may point to a .ReaperMenu file located
	anywhere on the hard drive.
	
	- A menu item titled 'LOAD REAPER MENU FILE' will allow loading another file via
	file browser. Two menu items 'Cycle to next/previous menu/toolbar file' at the top 
	of the menu allow switching to other valid .ReaperMenu files located in the same 
	directory as the last loaded file. These will be disabled when there're no valid
	menu files in the directory besides the one currently loaded. Finally a submenu 
	of valid .ReaperMenu files located in the directory of the currently loaded menu 
	file is available under the menu item immediately preceding the first separator 
	and indicating the file name of the currently loaded menu. If there're no valid 
	files the submenu isn't available.
	
	- If no .ReaperMenu file path is specified in the USER SETTINGS for a particular 
	context, the last loaded file is stored and will be the first to load on the next 
	script run. If a path is specified for a particular context, nothing is stored for 
	such context and while other files can still be accessed while the menu is still 
	open, the menu file which will be loaded at each scrpt run is the file whose path 
	is specified in the USER SETTINGS.
	
	- When the full path to the .ReaperMenu file is specified in the USER SETTINGS below,
	the load dialogue menu item is inactive because if you load another file, on the
	next run the script will still default to the file located at the path specified in
	the USER SETTINGS.
	
	- The same script can be added to and run from 3 sections of the Action list:
	*Main*, *MIDI Editor* and *MIDI Event List Editor* and maintain different menus.   
	The sections *Main* and *Main (alt recording)* share the same content, therefore
	the script added to the *Main* section in the *Main (alt recording)* section will have 
	the same menu.  
	If this script has been installed via ReaPack application it has been automaticaly 
	added to both *Main* and *MIDI Event List Editor* sections of the Action list.   
	Besides that, multiple instances of the script can be created under slightly different
	names, loaded into any or all 3.5 mentioned sections of the Action list and used with
	different .ReaperMenu files in parallel.  
	If you prefer specifying the path to the menu file in the USER SETTINGS below use the
	option proper for the section of the Action list the script is going to be run from.
	
	- Actions in *Media Explorer* section of the Action list cannot be launched with this
	script and using it from *MIDI Inline Editor* section is impractical therefore it has
	been made incompatible with them.
	
	- You can run MIDI Editor menus from Arrange even if the MIDI Editor is closed.
	If you do so while working with the MIDI Inline Editor be aware that the grid and snap
	settings which will be used by the menu actions (such as Split and the like) are those
	of the main MIDI Editor.  
	If MIDI Editor is closed toggle state indicators (if any) won't appear next to the menu
	items.
	
	- Likewise Arrange menus can be run from inside the MIDI Editor.
	
	- If your menu is long, to be able to scroll it all the way down quickly use up/down 
	arrow keys on the keyboard wile the mouse cursor is placed over the menu.

]]
---------------------------------------------------------------------------------------
------------------------------------- USER SETTINGS -----------------------------------
---------------------------------------------------------------------------------------
-- OPTIONAL
-- Insert full path to the .ReaperMenu file between the double square brackets.
-- All options can be filled out, the menu will depend on the current Action list section.
-- FILE_PATH_MAIN when running this script from the 'Main' section of the Action list.
-- FILE_PATH_MIDI_Ed when running this script from the 'MIDI Editor' section.
-- FILE_PATH_MIDI_EvLst when running this script from the 'MIDI Event List' section.

FILE_PATH_MAIN = [[]]
FILE_PATH_MIDI_Ed = [[]]
FILE_PATH_MIDI_EvLst = [[]]


-- Enable by inserting any alphanumeric character
-- between the quotes to keep the menu open after a menu item
-- has been clicked, which is convenient if you need
-- to change toggle state of several actions or just 
-- run several actions sequentially;
-- to close the menu click away or hit Escape key
KEEP_MENU_OPEN = ""

----------------------------------------------------------------------------------------
---------------------------------- END OF USER SETTINGS --------------------------------
----------------------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
--[[
-- a time loop can be added to run when certan condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function Select_Next_Previous_File_Or_Get_File_Table(file, nxt, prev)
-- selecting in the same directory as the current one
local path = file:match('.+[\\/]')
-- store in a table
local file_t = {}
local i = 0
	repeat
	local file_n = r.EnumerateFiles(path, i)
		if file_n and file_n:match('%.ReaperMenu') then
		local file_tmp = io.open(path..file_n, 'r')
		local menu_code = file_tmp:read('*a')
		file_tmp:close()
			if #menu_code > 0 and menu_code:match('item_%d*=') then -- only collect valid menu files
			file_t[#file_t+1] = path..file_n
			end
		end
	i = i+1
	until not file_n
r.EnumerateFiles(r.GetResourcePath(),0) -- clear cache, works across different builds https://forum.cockos.com/showthread.php?t=203235
-- select next/prev
	if nxt or prev then
	local found
		for k, f in ipairs(file_t) do
			if f == file then found = 1 end
			if found and nxt then
			file = k+1 <= #file_t and file_t[k+1] or file_t[1]
			break
			elseif found and prev then
			file = k-1 >= 1 and file_t[k-1] or file_t[#file_t]
			break
			end			
		end
	end

return file, #file_t > 0 and file_t
end


function Concat_File_Submenu(file, file_t) -- file_t stems from Select_Next_Previous_File_Or_Get_File_Table()
	if file_t and #file_t > 0 then
	local submenu_t = {} -- to avoid changing contents of the table being fed in because it will be needed to extract file paths
		for k, f in ipairs(file_t) do
		local form = '|'..(k == #file_t and '<' or '')
			if f == file then
			submenu_t[k] = form..'#[current]'
			else
			submenu_t[k] = form..f:match('([^\\/]+)%.ReaperMenu') -- closing submenu at the last item
			end
		end
	return table.concat(submenu_t)
	end
end



local _,scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

	if sect_ID == 32062 or sect_ID == 32063 then
	Error_Tooltip('\n\n    The script wasn\'t meant \n\n to be run from this section \n\n\t of the Action list.\n\n', true, true) -- caps, spaced true
	return r.defer(function() do return end end) end


local sect_ID_t = {
[0] = {'Main', FILE_PATH_MAIN},
[32060] = {'MIDI_Ed', FILE_PATH_MIDI_Ed},
[32061] = {'MIDI_EvLst', FILE_PATH_MIDI_EvLst}
}


local file = sect_ID_t[sect_ID][2]
local file = file:match('%s*(.*)%s*') -- trim leading and trailing spaces just in case
-- evaluate path
local file_exists = r.file_exists(file)
local file_tmp = io.open(file, 'r')
local menu_code = file_tmp and file_tmp:read('*a') -- to prevent error when file is invalid
local f_close = file_tmp and file_tmp:close() -- to prevent error when file is invalid
local empty = menu_code and menu_code == '' and 'is empty'
local invalid = menu_code and not menu_code:match('item_%d*=') and 'is invalid' -- no menu tags


-- if user defined file not found
local err = file ~= '' and not file_exists and 'wasn\'t found' or empty or invalid

	if err then resp = r.MB('The user defined ReaperMenu file '..err..'.\n\n\t    "YES" — to load new file\n\n    "NO" — to switch to the last used file (if any)','PROMPT',3)
		if resp == 7 then file = '' -- to trigger GetExtState() below
		elseif resp == 6 then resp = 1 -- to trigger file load dialogue below
		else return r.defer(function() do return end end) end
	end

	-- load file from the saved path
	if file == '' then -- load saved file path
	file = r.GetExtState(scr_name..'_'..sect_ID_t[sect_ID][1], 'menu_file_path')
	-- check if it's not become empty or invalid, an extremely edge case, almost improbable
	local file_tmp = io.open(file, 'r')
	local menu_code = file_tmp and file_tmp:read('*a')
	local f_close = file_tmp and file_tmp:close()
	file = menu_code and (menu_code == '' and 'empty' or not menu_code:match('item_%d*=') and 'invalid') or file
	end 

local err = file == '' and 'saved ReaperMenu path' or not r.file_exists(file) and 'used ReaperMenu file'
err = err and 'The last '..err..' wasn\'t found'
err = (file == 'empty' or file == 'invalid') and '\tReaperMenu file is '..file or err
	if err and resp ~= 1 then resp = r.MB(err..'.\n\n         Click "OK" to load a new menu file.','ERROR',1) -- ~=1 cond stems from user defined file prompt dialogue above
		if resp == 2 then return r.defer(function() do return end end) end
	end

	::RETRY::
	
	if file == '' or not file:match('%.ReaperMenu') or resp == 1 or LOAD_NEW then -- =1 cond stems from user defined file prompt dialogue above, LOAD_NEW stems from the utility menu items below

		if tonumber(LOAD_NEW) then -- cycle to next/previous
	
		local f = Select_Next_Previous_File_Or_Get_File_Table(file, LOAD_NEW == 2, LOAD_NEW == 3) -- 2 - next, 3 - prev
		
		local err = not f and 'No files or no valid files in the directory.' or f == file and 'There\'s only one valid file in the directory.'
			
			if err then r.MB(err, 'ERROR', 0) end
			
		file = f or file -- either new or the same

		else -- load via dialogue

		resp = nil -- reset to prevent re-triggering of the dialogue when the menu remains open after file has been loaded and utility menu item 4 (which doesn't have any action associated with it) is clicked
		
		local path = reaper.GetResourcePath()
		local sep = r.GetOS():match('Win') and '\\' or '/'

		retval, file = r.GetUserFileNameForRead(path..sep..'MenuSets'..sep, 'Select and load ReaperMenu file', '.ReaperMenu')
			if not retval then return r.defer(function() do return end end) end
			if not file:match('%.ReaperMenu$') then resp = r.MB('        The selected file desn\'t\n\nappear to be a ReaperMenu file.\n\n            Click "OK" to retry.','ERROR',1)
				if resp == 1 then goto RETRY
				else return r.defer(function() do return end end) end
			end

		local file_tmp = io.open(file, 'r')
		local menu_code = file_tmp:read('*a')
		file_tmp:close()
		local err = menu_code == '' and 'empty' or not menu_code:match('item_%d*=') and 'invalid'
			if err then resp = r.MB('          ReaperMenu file is '..err..'.\n\n\tClick "OK" to retry.','ERROR',1)
				if resp == 1 then goto RETRY
				else return r.defer(function() do return end end) end
			end

		end
			
	r.SetExtState(scr_name..'_'..sect_ID_t[sect_ID][1], 'menu_file_path', file, true) -- save selected file path

	end

local act_t, menu_t, cap_t = {}, {}, {}
local form_t = {['-1'] = '|', ['-2'] = '>', ['-3'] = '<', ['-4'] = '#'} -- menu formatting special characters
local cntr = 1
local close_submenu

	for line in io.lines(file) do
		if cntr == 1 then -- cntr prevents evaluation of lines other than the 1st
		menu_name = line:match('%[(.+)%]')  -- to be added to the menu at the bottom
		MIDI = menu_name and menu_name:match('MIDI') -- the var is used to condition way of calling actions from the menu
		end
		if line:match('=') and line:match('[%s]') or line:match('[%-]') then -- the last 2 conditions target toolbars to avoid capturing icons and text formatting lines whose tags lack these characters
		local action = line:match('=([^%s%-]+)')
			if action then act_t[#act_t+1] = action
			cap_t[#cap_t+1] = line:match('%s(.+)') end -- collect menu item names to display as undo cap // undo has been discontinued but cap_t is still useful in detecting menu items for chekmark update when KEEP_MENU_OPEN setting is enabled
		local form, item = line:match('=(%-%d)'), line:match('%s(.+)$')
		local menu_elem = form and (form == '-2' or form == '-4') and form_t[form]..item..'|' or form and form ~= '-3' and form_t[form] or item and item..'|'
		menu_t[#menu_t+1] = menu_elem and menu_elem
		-- Submenu closures, respecting several closures in a row, when there're several nested submenus
			if form == '-3' and not close_submenu -- 1st closure
			then table.insert(menu_t,#menu_t,'<') close_submenu = true -- insert closure tag before the most recent line  pushing it to a later position
			elseif form == '-3' and close_submenu then menu_t[#menu_t+1] = form_t[form]..'|' -- every next closure
			else close_submenu = false end -- reset the value if no closures
		end -- cond. end
	cntr = cntr + 1
	end -- loop end


::KEEP_MENU_OPEN::

-- Add toggle ON indicator to menu items, including when the menu is reloaded triggered by KEEP_MENU_OPEN setting being enabled
	for k1,v1 in next, act_t do
	local sect = MIDI and 32060 or 0
	local togg_state = r.GetToggleCommandStateEx(sect,r.NamedCommandLookup(v1))
		if togg_state >= 0 then
		local cap = cap_t[k1]:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0') -- escape special chars, doesn't work directly inside string.match()
			for k2,v2 in next, menu_t do
				if togg_state > 0 and v2:match(cap) and v2:sub(0,1) ~= '!' then -- some actions may return 2 instead of 1, probably those which have Off state but don't have an explicit On state, e.g. 'View: Show notation text on notes' in the MIDI Editor section
				menu_t[k2] = '!'..v2 -- add checkmark
				break
				elseif togg_state == 0 and v2:match('!'..cap) then -- cap_t entries aren't updated with the checkmark therefore it should be added
				menu_t[k2] = v2:sub(2) -- remove checkmark; if it's the same menu item line in all tables
				break
				end
			end
		end
	end


-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82 then gfx.init('Dynamic ReaperMenu', 0, 0) end
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y


_, file_t = Select_Next_Previous_File_Or_Get_File_Table(file) -- nxt, prev are nil to prevent unnecessary running irrelevant pieces of code
local file_cnt = #file_t > 1 and #file_t or 0 -- store length to be used to offset main menu items count and extract correct index for loading another menu file from the submenu, only if there're more than 1 menu files in the directory
local submenu = file_cnt > 0 and Concat_File_Submenu(file, file_t)
local off = submenu and '♦' or '#' -- when there's no submenu because there're no other menu files in the directory, next/prev menu items will be disabled
local utility_menu = '♦  LOAD REAPER MENU/TOOLBAR FILE|'..off..' Cycle to next menu/toolbar file ▬>|'..off..' Cycle to previous menu/toolbar file <▬|◊ menu name: '..menu_name..'|'..(submenu and '>' or '')..(submenu and '♦' or '◊')..' file name: '..file:match('[^\\/]-$')..(submenu or '')..'||' -- display currently loaded menu and file names in the menu and a submenu if relevant

local input = gfx.showmenu(utility_menu..table.concat(menu_t))

	if (submenu and input > file_cnt+4 or not submenu and input > 5) and input <= #act_t then -- menu returns 0 upon closure so the relational operator is meant to prevent error at r.NamedCommandLookup(act_t[input]) function when the menu closes since there's no 0 key in the table // accounting for first utility menu items, 4 since submenu button isn't counted
	input = submenu and input-file_cnt-4 or input-5 -- offset first utility menu items accounting for menu files submenu if any, 4 since submenu button isn't counted
		if r.NamedCommandLookup(act_t[input]) == 0 then
		Error_Tooltip('\n\n The (custom) action / script \n\n\t    wasn\'t found.\n\n', true, true) -- caps, spaced true
		return r.defer(function() do return end end) end
		if sect_ID == 32060 or sect_ID == 32061 then -- MIDI Editor sections
			if not MIDI then
			r.Main_OnCommand(r.NamedCommandLookup(act_t[input]),0)
			else
			r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), r.NamedCommandLookup(act_t[input])) -- run action associated with pressed menu item
			end
		elseif sect_ID == 0 or sect_ID == 100 then
			if MIDI then
			local is_open = r.MIDIEditor_GetActive()
				if not is_open then r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor
				end
			local HWND = r.MIDIEditor_GetActive()
			r.MIDIEditor_OnCommand(HWND, r.NamedCommandLookup(act_t[input]))
				if not is_open then r.MIDIEditor_OnCommand(HWND, 2) -- File: Close window
				end
			else local ID = r.Main_OnCommand(r.NamedCommandLookup(act_t[input]),0)
			end
		end
		if #KEEP_MENU_OPEN:gsub(' ', '') > 0 then goto KEEP_MENU_OPEN end
	elseif input >= 1 then -- when utility menu items are clicked
	LOAD_NEW = nil -- if the next/previous switch is used without reset, selection of menu files from the submenu glitches
		if input == 1 then LOAD_NEW = true -- 'LOAD REAPER MENU FILE'
		elseif input > 1 and input < 4 then -- 2 & 3 menu items, cycle to next/previous
		LOAD_NEW = input
		elseif input > 4 and submenu then
		file = file_t[input-4]
		r.SetExtState(scr_name..'_'..sect_ID_t[sect_ID][1], 'menu_file_path', file, true) -- save selected file path // must be stored here because there's no option to store it after jumping to RETRY
		end	
	goto RETRY
	elseif input == 0 then return r.defer(function() do return end end) end -- prevent 'Script: Run' caption when menu closes without action


gfx.quit()



