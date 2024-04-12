--[[
ReaScript name: BuyOne_(Re)Store Razor edit areas slots #1-5_META.lua (10 scripts)
Author: BuyOne
Version: 1.4
Changelog:  v1.4 #Added a menu to the META script so it's now functional as well
		 allowing to use from a single menu all options available as individual scripts
		 #Updated About text
	   v1.3 #Fixed individual script installation function
		 #Made individual script installation function more efficient
	   v1.2 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
	   v1.1 #Added REAPER version check
		 #Corrected minimal supported version in the header
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v6.54
Metapackage: true
Provides: 	[main] . > BuyOne_Store Razor edit areas slot 1.lua
		[main] . > BuyOne_Store Razor edit areas slot 2.lua
		[main] . > BuyOne_Store Razor edit areas slot 3.lua
		[main] . > BuyOne_Store Razor edit areas slot 4.lua
		[main] . > BuyOne_Store Razor edit areas slot 5.lua
		[main] . > BuyOne_Restore Razor edit areas slot 1.lua
		[main] . > BuyOne_Restore Razor edit areas slot 2.lua
		[main] . > BuyOne_Restore Razor edit areas slot 3.lua
		[main] . > BuyOne_Restore Razor edit areas slot 4.lua
		[main] . > BuyOne_Restore Razor edit areas slot 5.lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first. It will also display a menu
	allowing to execute all actions available as individual scripts.		
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.
	
	Each menu item of the META script can be triggered from 
	keyboard. STORE menu items with numerals 1 through 5 and 
	RESTORE menu items with characters 'a' through 'e' which 
	are listed next to the menu items. When ADDITIONAL_SLOTS 
	setting is 5 the last STORE menu item must be triggered 
	from keyboard with key 0. When ADDITIONAL_SLOTS setting 
	is greater than 5, letters are added to the STORE menu items 
	to be used as keyboard triggers instead of number keys.
	
	If more store/restore slots are needed, duplicate any two
	of the complementing individual scripts and increase the slot 
	number in their names so it's greater than the currently 
	available maximum number.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes optionally insert the number
-- of additional slots to be available in the META script menu;
-- doesn't apply to non-META scripts;
-- valid settings are 1 through 8, integers only,
-- numerals greater than 8 are clamped to 8,
-- negative numerals are converted to positive,
-- non-integers are rounded down,
-- illegal settings default to 0
ADDITIONAL_SLOTS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


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

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

--[[ GETTING PATH FROM THE USER INPUT

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)

	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD

	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		-- spawn scripts
		-- THERE'RE USER SETTINGS OR THE META SCRIPT IS ALSO FUNCTIONAL SO FILES AREN'T UNNECESSARILY CREATED WHEN IT RUNS
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
			for _, sectID in ipairs{0} do -- Main // per script list
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


function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- only useful for looking up the result of a toggle action, below see a more practical example

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	local init = (old or not old and keep_menu_open) and gfx.init('', 0, 0)
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


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function construct_char_array(up, low, both)
-- up, low, both are booleand to choose case
-- under one case there're 26 alphabetic chars in Latin basic
local capt = both and '%a' or up and '%u' or low and '%l'
local t = {}
	for i = 0, 255 do
	local char = string.char(i)
		if char:match(capt) then
		t[#t+1] = char
		end
	end
return t
end



function Add_Menu_Slots(t, slots_No)
	if slots_No > 0 then
	local last = t[#t]
	t[#t] = last:sub(1,#last-1) -- exclude menu item separator pipe from the last slot
		for i = #t+1, #t+slots_No do
		local pipe = i == slots_No and '|' or ''
		t[i] = 'Slot '..i..pipe
		end
	t[#t] = t[#t]..'|' -- add menu item separator pipe to the last slot
	end
return t
end



function Re_Store_Razor_Edit_Areas(store, restore, slot, META)
-- store, restore is boolean, slot is string

local sect = '(Re)Store Razor edit areas'
local slot = 'SLOT'..slot
local tr_cnt = r.CountTracks(0)
local x = META and -350 or 0

	if store then

	local data = ''
		for i=0, tr_cnt-1 do
		local tr = r.GetTrack(0,i)
		local retval, raz_edit = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS_EXT', '', false) -- setNewValue false
		-- retval is always true as long as the param name is correct so unreliable
			if #raz_edit > 0 then
			data = data..tostring(tr)..':'..raz_edit..';'
			end
		end
		if #data == 0 then
		Error_Tooltip('\n\n no razor edit areas to store \n\n', 1, 1, x) -- caps, spaced true
		return end
	r.SetExtState(sect, slot, data, false) -- persist false

	elseif restore then

	local data = r.GetExtState(sect, slot)
		if #data == 0 then
		Error_Tooltip('\n\n no stored razor edit \n\n area data in the slot \n\n', 1, 1, x) -- caps, spaced true, x to move the tooltip away from the menu in the META script otherwise it will be covered by the reloaded menu
		end
	local t = {}
		for data in data:gmatch('(.-);') do
			if #data > 0 then
			local tr, raz_edits = data:match('(.+):'), data:match('.+:(.+)')
			t[tr] = raz_edits
			end
		end
		for i=0, tr_cnt-1 do
		local tr = r.GetTrack(0,i)
			if t[tostring(tr)] then
			r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS_EXT', t[tostring(tr)], true) -- setNewValue true
			end
		end

	end

end


local is_new_value, fullpath_init, sectionID, cmdID, mode, resolution, val = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, extension and author name // for META scripts with menu // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script

-- doesn't run in non-META scripts
META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_(Re)Store Razor edit areas slots #1-5_META.lua', names_t)

--scr_name = 'Restore Razor edit areas slot 2' ----------- NAME TESTING

local META = scr_name:match('.+_META$')
local slots = {'Slot 1', 'Slot 2', 'Slot 3', 'Slot 4', 'Slot 5|'}
ADDITIONAL_SLOTS = ADDITIONAL_SLOTS:gsub(' ','')
ADDITIONAL_SLOTS = tonumber(ADDITIONAL_SLOTS) and (ADDITIONAL_SLOTS+0 >= 1 and ADDITIONAL_SLOTS+0 <= 8
and math.floor(math.abs(ADDITIONAL_SLOTS+0)) or ADDITIONAL_SLOTS+0 > 8 and 8) or 0 -- max number of additional slots is 8 to be able to evenly mete out the alphabetic quick access shortcuts between store and restore slots, i.e. 5+8 = 13 for one set of slots, which gives 26 for two sets and equals the number of alphabetic characters in basic Latin
slots = Add_Menu_Slots(slots, ADDITIONAL_SLOTS)

::RELOAD::

	if META then

	local tit = ('store razor areas'):upper()..'|'
	menu1 = {tit, table.unpack(slots)}
	menu2 = {'RE'..tit, table.unpack(slots)} -- in two parts because if table.unpack is followed by a comma within a table constructor only the 1st field is unpacked
	local abc = construct_char_array(up, 1, both) -- low true

		if ADDITIONAL_SLOTS > 5 then -- insert characters as quick access shortcuts in the 'store' menu because there're only 10 numerals on the keyboard, 0-9, which only cover 10 slots, i.e. 5 default + 5 additional
			for k, slot in ipairs(menu1) do
				if k > 1 then -- excluding menu title
				local slot = menu1[k]:match('(.+)|') or menu1[k] -- exclude menu item separator pipe from the last Slot item
				menu1[k] = slot..' 「&'..abc[k-1]..'」' -- insert quick access shortcut
				end
			end
		menu1[#menu1] = menu1[#menu1]..'|' -- re-insert menu item separator pipe to the last Slot item
		else -- default 5 slot menu
			for k, slot in ipairs(menu1) do
				if k > 1 then -- excluding menu title
				local slot = slot:match('10') and slot:gsub('0','&0') or slot:gsub('%d','&%0') -- in slot 10 ampersand precedes 0
				menu1[k] = slot -- insert quick access shortcut before numeral
				end
			end
		end

		for k, slot in ipairs(menu2) do -- add checkmarks to 'restore' menu slots for which there're stored data
			if k > 1 then -- excluding menu title
			local state = r.GetExtState('(Re)Store Razor edit areas', 'SLOT'..k-1)
				if #state > 0 then
				menu2[k] = '!'..slot -- offsetting index by the menu title
				end
			-- add quick access shortcuts
			local slot = menu2[k]:match('(.+)|') or menu2[k] -- exclude menu item separator pipe from the last Slot item
			local idx = ADDITIONAL_SLOTS > 5 and (#menu1-1)+(k-1) or k-1 -- offsetting k by the menu title and accounting for menu1 length if the additional slots number exceeds 5, because in this case 'store' menu (menu1) also uses alphabetic quick access shortcuts
			menu2[k] = slot..' 「&'..abc[idx]..'」' -- insert quick access shortcut
			end
		end

	menu2[#menu2] = menu2[#menu2]..'|' -- re-insert menu item separator pipe to the last Slot item

	menu = table.concat(menu1,'|')..'|'..table.concat(menu2,'|')

	end

	local store, restore = scr_name:match('Store'), scr_name:match('Restore')
	local slot = scr_name:match('slot (%d+)')

	local output = META and Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open 1, true

	if output == 0 then return r.defer(no_undo) -- output is 0 when the menu in the META script is clicked away from
	elseif output == 1 or output == 7+ADDITIONAL_SLOTS then -- one of the menu titles has been hit
	goto RELOAD
	elseif output then -- will only be true in the META script
	store, restore = output < 7+ADDITIONAL_SLOTS, output > 7+ADDITIONAL_SLOTS -- 7 is restore menu title in default menu, 5 slots (no additional slots)
	slot = menu1[output] or menu2[output-6-ADDITIONAL_SLOTS] -- -6 to offset corresponding menu item index, -ADDITIONAL_SLOTS to offset extra slots number, because in each table store and restore slots have the same indices, when index matching the output isn't found in the 'store' menu (menu1) this means that the 'restore' menu (menu2) item was hit
	slot = slot:match('%d+')
	end

	if (not restore and not store) or not slot or not scr_name:match('Razor edit area') then
		function space(n) -- number of repeats, integer
		return (' '):rep(n)
		end
	local br = '\n\n'
	local err = [[The script name has been changed]]..br..space(4)..[[which renders it inoperable.]]..br
	..space(5)..[[restore the original name]]..br..space(8)..[[referring to the list]]..br
	..'\t\t'..[[in the header.]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


Re_Store_Razor_Edit_Areas(store, restore, slot, META)

	if META then goto RELOAD
	else return r.defer(no_undo)
	end




