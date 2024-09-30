--[[
ReaScript name: BuyOne_Open item properties dialogue, focus on property X_META.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
Metapckage: true
Provides: [main=main,midi_editor] .
			. > BuyOne_Open item properties dialogue, focus on property 'Position'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Length'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Time unit'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-in'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-in curve strength'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-in curve menu'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-out'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-out curve strength'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Fade-out curve menu'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Snap offset'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Time base'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Mix behavior'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Active take'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Start in source'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Pitch adjust'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Playback rate'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Volume'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Pan'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Pitch shift; time stretch mode'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Stretch markers fade size'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Stretch markers mode'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Section length'.lua
			. > BuyOne_Open item properties dialogue, focus on property 'Section fade'.lua

About: 	If this script name is suffixed with META, when executed it will automatically spawn 
			all individual scripts included in the package into the directory of the META script
			and will import them into the Action list from that directory.  			
			That's provided such scripts don't exist yet, if they do, then in order to recreate 
			them they have to be deleted from the Action list and from the disk first.  

			If there's no META suffix in this script name, it will perfom the operation indicated 
			in its name.

			The script puts into keyboard focus in the open Media Item Property dialogue a property
			of selected item, indicated in the script name, so it's accessible for keyboard input. 
			Text fields will be accessible for typing, drop-down and pop-up menus will be accessible 
			for navigation with up/down arrow keys. If the dialogue is closed it will be opened by 
			the script.
			
			The script is known to work on Windows.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable the following settings by inserting any
-- alphanumeric character between the quotes

-- The settings are incompatible with one another,
-- if HIGHLIGHT_TEXT is enabled MOVE_CURSOR_TO_START
-- will be ignored;
-- The settings don't apply to drop-down menus

-- Enable to have the text within the target field
-- highlighted (selected) when the field is focused;
-- while Media Item Properties dialogue is open, if the text
-- in the target field was highlighted at least once,
-- when its field is focused again it will be highlighted
-- again regardless of this setting
HIGHLIGHT_TEXT = ""

-- Enable to make the typing cursor move to the start
-- of the target field once it's focused;
-- while Media Item Properties dialogue is open, if this
-- setting is NOT enabled, when the target field is focused again
-- the cursor within the field will be automatically placed
-- at the last position it had been at before the field lost focus
MOVE_CURSOR_TO_START = ""

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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
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




function Find_Item_Props_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search floating toolbars with BR_Win32_FindWindowEx(), including docked
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtexta#return-value
-- 2. search floating docker with BR_Win32_FindWindowEx() using 2 title options, and loop to find children and siblings
-- 3. search dockers attached to the main window with r.GetMainHwnd() and loop to find children and siblings

	local function Find_Win(title)
	return r.BR_Win32_FindWindowEx('0', '0', '', title, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // does find single windows and single windows docked in floating dockers with '(docked)' appendage in the title, doesn't find children windows, such as docked in multi-tab docks and single docked in dockers attached to the main window, hence the actual function Find_Item_Props_Window_SWS()
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

-- search for a floating docker with one attached window // toolbars can be attached to a regular floating docker and regular windows can be attached to a floating toolbar docker
local docker = Find_Win('Item Properties (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
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

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child

	if not child then return end -- no children

local ret, txt = r.BR_Win32_GetWindowText(child)
local i, t = 0, {[1] = {child=child, txt=txt}}  -- storing 1st found child props
	repeat
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
		if child then
		local ret, txt = r.BR_Win32_GetWindowText(child)
		t[#t+1] = {child=child, txt=txt}
		end
	i=i+1
	until not child
return #t > 0 and t
end



function Focus_Item_Property(child_t, prop, take, was_closed, parent_wnd) -- parent_wnd was used for experimentation

-- table of matches between property name in the script name
-- and property window name in the Item Properties dialogue
-- the name list is up-to-date as of build 7.22
local props_t = {Position='Position:', Length='Length:',
-- 'Time unit' drop down menu name depends on the selected item
-- therefore isn't evaluated and the table field is only a placeholder
-- but must not be left blank so that it doesn't end up matching nameless child windows
['Time unit']='unit', ['Fade-in']='Fade in:',
-- 'Curve:' window name isn't evaluated because it's shared by two windows
-- curve menu window name isn't evaluated either because the name depends on the active curve
-- therefore the associated fields in the table are just placeholders
-- but must not be left blank so that they don't end up matching nameless child windows
['Fade-in curve strength']='(Fade in:) Curve:', ['Fade-in curve menu']='curve menu',
['Fade-out']='Fade out:', ['Fade-out curve strength']='(Fade out:) Curve:', ['Fade-out curve menu']='curve menu',
['Snap offset']='Snap offset:', ['Time base']='Item time&base:', ['Mix behavior']='Item mix behavior:',
['Active take']='Active take:', ['Start in source']='Start in source:',
['Pitch adjust']='Pitch adjust (semitones):', ['Playback rate']='Playback rate:', Set='Set...',
Volume='Volume/', Pan='/pan:', Normalize='&Normalize', ['Channel mode']='Channel mode',
['Take envelopes']='Take envelopes...',
['Pitch shift; time stretch mode']='Take pitch shift/time stretch mode',
-- Take pitch shift/time stretch mode options menu window name isn't evaluated
-- because it depends on the currently active option
-- therefore the associated field in the table is just a placeholder
-- but must not be left blank so that it doesn't end up matching nameless child windows
['Pitch shift; time stretch mode options']='options',
['Stretch markers fade size']='fade size:', ['Stretch markers mode']='Mode:',
-- section 'Length:' window name isn't evaluated therefore the associated field in the table are just a placeholder
['Section length']='(Section) Length:', ['Section fade']='Fade:', -- section props, only if enabled
['Properties']='&Properties...', ['Rename file']='&Rename file...', ['Choose new file']='&Choose new file...',
['Nudge-Set']='Nudge/Set...', ['Take FX']='Take FX...',
-- checkboxes
['Loop source']='&Loop source', Mute='&Mute', Lock='Lock', ['No autofades']='No autofades',
['Play all takes']='Play all ta&kes', ['Preserve pitch when changing rate']='Preserve pitc&h when changing rate',
['Invert phase']='&Invert phase', Section='Section:', Reverse='Reverse'}

	local function checkbox_or_button(prop, want_checkboxes)
	local t = { buttons={'curve', 'Set', 'Normalize', 'Channel mode', 'Take', -- 'Take' covers envelopes and FX
	'stretch mode options', 'Properties', 'Nudge', 'file'},
	checkboxes={'Loop source', 'Mute', 'Lock', 'No autofades', 'Play all takes',
	'Preserve pitch when changing rate', 'Invert phase', 'Section', 'Reverse'} }
		if want_checkboxes then t.buttons = nil end -- clear buttons table if only checkboxes need evaluation
		for _, tab in pairs(t) do
			for _, name in ipairs(tab) do
				if prop:match(name) then
				return true end
			end
		end
	end

--prop = 'Section' ---------------- TESTING WINDOW NAMES

	-- prevent targeting section options if Section is disabled and Section if take is MIDI
	if r.TakeIsMIDI(take) and prop:match('Section') or prop:match('Section.+') then
	local retval, offs, len, rev = r.PCM_Source_GetSectionInfo(r.GetMediaItemTake_Source(take))
	local err = r.TakeIsMIDI(take) and 'midi takes don\'t support section'
	or not retval and 'take section is disabled'
		if err then -- section isn't enabled
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
		return end
	end

local wnd_name = props_t[prop]

	if not wnd_name then -- what was retrieved from script name doesn't have matches in the table
	prop = #prop > 0 and 'INVALID PROPERTY NAME \n\n "'..prop or ('property name is empty'):upper()
	Error_Tooltip('\n\n '..prop..' \n\n', nil, 1) -- caps nil, spaced true
	return end

local SendMsg = r.BR_Win32_SendMessage

	for k, data in ipairs(child_t) do
	local wnd, txt = data.child, data.txt
	local k_next = ( prop=='Volume' -- volume input field is removed from window titled 'Volume' by 3 places
	or prop:match('Fade.-curve strength') -- 'Curve:' field name is ignored, otherwise the conditions and calculation would have to be different, counted from 'Fade-in/out' window which is 3 places ahead
	or prop=='Section length' ) and k+3 -- section 'Length:' window is ignored in order to be disambiguated from regular 'Length:' window and counted from window titled 'Section:' which is 3 places ahead

	or ( prop:match('Fade.-curve menu') -- curve menu window name is ignored because it depends on the currently active curve, instead it's counted from 'Fade-in/out' window which is 4 places ahead
	or prop=='Pan' -- pan input field is removed from window titled 'Volume' by 4 places
	or prop=='Time unit' ) and k+4 -- the title of time unit drop-down menu window depends on the currently selected menu item, so to simplfy search it's counted from window titled 'Position:' instead which is 4 places ahead

	or checkbox_or_button(prop) and k -- these button and checkbox windows have their own names so must be accessed directly

	or prop:match('stretch mode options') and k+2 -- the name of 'Take pitch shift/time stretch mode' options menu window (the pop-up, not the drop-down) depends on the selected option therefore is calculated from the 'Take pitch shift/time stretch mode' window which is 2 places ahead

	or k+1 -- other input field windows immediately follow title windows hence k+1

		if child_t[k_next] and ( txt == 'Position:' and prop=='Time unit'
		or txt:match('Fade in:') and ( prop:match('in curve strength') or prop:match('in curve menu') )
		or txt:match('Fade out:') and ( prop:match('out curve strength') or prop:match('out curve menu') )
		or txt:match('pitch shift/time') and prop:match('stretch mode options')
		or txt == 'Section:' and prop == 'Section length'
		or wnd_name and txt:match(Esc(wnd_name)) ) then

		wnd = child_t[k_next].child
		r.BR_Win32_SetFocus(wnd)

		-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#keystroke-message-flags -- scan codes are listed in a table in 'Scan 1 Make' colum in Scan Codes paragraph
		-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel

			if not checkbox_or_button(prop) then
				-- these two are mutually exclusive, because once cursor is moved
				-- within the line of hihglighted (selected) text the selection is clear
				-- just as it happens in direct keyboard input
				if HIGHLIGHT_TEXT then
				SendMsg(wnd, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index
				elseif MOVE_CURSOR_TO_START then
				SendMsg(wnd, 0x0100, 0x24, 0xE047) -- 0x0100 WM_KEYDOWN, virtual key code 0x24 VK_HOME HOME key, 0xE047 HOME key scan code // move cursor to start of the line
				--[[ OR
					for i=1,#txt do
					SendMsg(wnd, 0x0100, 0x25, 0xE04B) -- 0x0100 WM_KEYDOWN, LEFT ARROW key virtual key code 0x25, scan code 0xE04B
					end
				]]
				end
			else
				if checkbox_or_button(prop, 1) and was_closed then return end -- want_checkboxes true // don't toggle a checkbox if the Item Properties dialogue has just been opened, so that it's current state is apparent, the toglle will work if the gialogue is already open
		--	https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
		-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
		-- fade curve menu is opened on button-up hence two stages
			SendMsg(wnd, 0x0201, 0x0001, 1+1<<16) -- WM_LBUTTONDOWN 0x0201, MK_LBUTTON 0x0001, x and y are 1, in lParam client window refers to the actual target window, x and y coordinates are relative to the client window and have nothing to do with the actual mouse cursor position, 1 px for both is enough to hit the window
			SendMsg(wnd, 0x0202, 0x0001, 1+1<<16) -- WM_LBUTTONUP 0x0201, MK_LBUTTON 0x0001, x and y are 1
			end
		return -- exit once window has been activated
		end
	end

end


function Search_For_Item_Properties_Dialogue(name)
local wnd_name = 'Media Item Properties:  '..name -- works, TWO SPACES GAP
-- must be run in stages like this, because within loop fails probably because the loop runs too quickly
-- in a floating window asterisk is added when properties have changed, but not when docked
local parent_wnd = Find_Item_Props_Window_SWS(wnd_name, want_main_children)
parent_wnd = parent_wnd or Find_Item_Props_Window_SWS(wnd_name..'*', want_main_children) -- props have been edited
return parent_wnd
end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 
	'BuyOne_Open item properties dialogue, focus on property X_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

local prop = scr_name:match(".+property '(.+)'") -- property name must be enclosed within single quotes in the script name 

local err = not r.BR_Win32_GetWindow and 'the sws/s&m extension \n\n     is not installed'
or not r.GetSelectedMediaItem(0,0) and 'no selected items' or not prop and '\t  item property \n\n could not be recognized'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local take = r.GetActiveTake(r.GetSelectedMediaItem(0,0))
local ret, name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- setNewValue false

local parent_wnd = Search_For_Item_Properties_Dialogue(name)
local was_closed

	if not parent_wnd then -- likely not open, so open it
	r.Main_OnCommand(40009,0) -- Item properties: Show media item/take properties
	parent_wnd = Search_For_Item_Properties_Dialogue(name)
	was_closed = 1
	end

local child_t = Get_Child_Windows_SWS(parent_wnd)
HIGHLIGHT_TEXT = #HIGHLIGHT_TEXT:gsub(' ','') > 0
MOVE_CURSOR_TO_START = #MOVE_CURSOR_TO_START:gsub(' ','') > 0
Focus_Item_Property(child_t, prop, take, was_closed, parent_wnd) -- parent_wnd is for experimentation only


do return r.defer(no_undo) end -- no generic 'ReaScript: Run' undo readout




