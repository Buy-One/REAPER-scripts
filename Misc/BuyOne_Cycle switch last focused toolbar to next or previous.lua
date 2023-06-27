--[[
ReaScript name: BuyOne_Cycle switch last focused toolbar to next or previous.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
About: 	▒ THE CONCEPT

	The script only works when exactly one toolbar is open in 
	the relevant context (besides main toolbars), that is either 
	in Arrange or in the MIDI Editor contexts, thus at any given 
	moment it only tolerates the total of two open toolbars.   
	If several toolbars per context were allowed, then when cycling 
	would reach another toolbar already open, the latter would be 
	auto-closed and the focused toolbar content would be switched 
	to it, which is messy.  
	The script is designed to allow freeing up some screen real estate 
	by always having only one toolbar open per context so using it 
	with multiple toolbars also defeats its purpose.
	
	To be able to use the script in the MIDI Editor context it must
	be imported into the MIDI Editor section of the Action list as well.
	To be able to switch to a MIDI toolbar and switch between MIDI 
	toolbars the MIDI Editor must be active, that is have keyboard focus 
	for which it's enough to click anywhere within it. When the MIDI 
	Editor is first open it becomes active automatically. Once the MIDI 
	Editor is closed Arrange context automatically becomes active. 
	While the MIDI Editor is open contexts can be switched by clicking
	within the Arrange or the MIDI Editor.
	
	▒ SETTING THE FOCUS
	
	If the extensions are installed a toolbar appropriate for the context 
	is brought into focus automatically, so no additional moves are 
	required. Otherwise the script targets the last focused toolbar 
	regardless of whether it is visibly focused currently (whether its 
	title bar is colorized) and whether any other window (other than 
	a toolbar) is focused (its title bar is colorized).   
	To bring a floating toolbar into focus its body or the title bar must 
	be clicked, this also applies to a toolbar docked in a floating docker.   
	To bring into focus a toolbar docked in a docker attached to the main 
	window its body must be clicked (it doesn't have a title bar), clicking 
	a docked toolbar tab doesn't change focus.
	
	▒ WAYS TO RUN THE SCRIPT

	If you prefer to run the script with a shortcut there're two options
	which are dictated by the fact that keyboard input is blocked when
	a toolbar is visibly in focus, that is when its title bar is colorized
	(REAPER limitation https://forum.cockos.com/showthread.php?t=279932).
	The position of the mouse cursor is immaterial.

	1) On the one hand you can make the scope of the shortcut in the Main
	section of the Action list global which allows running the script in
	Arrange context regardless of a toolbar being in focus. However in this
	case the shortcut the script is bound to in the MIDI Editor section of
	the Action list must be different otherwise the global shortcut will
	have priority and you won't be able to run the script from the MIDI
	Editor context (global scope isn't supported for MIDI Editor section
	shortcuts).  
	When extensions are installed the toolbar is never left in focus 
	therefore using a shortcut with global scope is pointless.   
	2) On the other hand the script can be bound to identical non-global
	shortcuts in both contexts but then to be able to run the script the
	toolbar will have to be explcitly not in focus.    
	In both abovelisted scenarios when the MIDI Editor is open the focus 
	must be set manually to either the Arrange or the MIDI Editor window 
	by clicking them, depending on the context you wish to manipulate the 
	toolbar in. When the MIDI Editor is closed the script defaults to the 
	Arrange context.  
	
	The limitation stemming from a toolbar being in focus doesn't apply to 
	toolbars docked in the floating docker in Arrange context because visual 
	focus of the docker window doesn't inhibit the functionality. Neither 
	does the aforementioned limitation apply to the mousewheel but there's 
	another detailed in the description of the MOUSEWHEEL setting in the 
	USER SETTINGS.

	The script cannot be run from a toolbar button in the main toolbar
	in either context, becuse main toolbar can be switched as well if
	comes into focus which happens exactly at the moment of a button click
	and the script has a safeguard against switching the main toolbar
	to another one because this is likely not what you'd want happening.
	Running the script with a button on all other toolbars though possible
	doesn't make much sense because this way you might as well run native
	'switch to toolbar' actions, although admittedly to be able to switch
	back and forth two buttons will be needed which takes additional space.	
	
	▒ LAST ACTIVE TOOLBAR STORAGE
	
	The script stores the last open toolbar for each context and opens it 
	for such context if a toolbar appropriate for it is not already open. 
	If no toolbar has been stored yet for a context, toolbar 1 will be opened. 
	To store these data with the project file so that they're available in 
	the next session make sure to save the project at least before closing it.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by placing any alphanumeric character between
-- the quotes to only have one toolbar open at any given
-- moment, besides main toolbars in Arrange and MIDI Editor
-- contexts;
-- when context change is detected, a toolbar appropriate
-- for the incoming context gets opened while toolbar appropriate
-- for the outgoing context gets closed or the latter is switched
-- to the former;
-- if extensions aren't installed this is more  convenient than
-- having two toolbars always open, one for each context, because
-- this is more likely to ensure that the same toolbar stays in
-- focus all the time and the script doesn't generate focus related
-- error messages, provided you don't manually open a toolbar from
-- another context and bring it into focus;
-- if extensions are installed and there's a docked toolbar from
-- the outgoing context whose window is inactive in the docker, it
-- will be closed as well
ONE_TOOLBAR_PER_PROJECT = ""


-- Only relevant if MOUSEWHEEL setting isn't enabled;
-- if empty the cycling will be performed in ascending order,
-- if not empty - in descending order
DIRECTION = ""


-- If enabled by placing any alphanumeric character between
-- the quotes the script can be run with the mousewheel but
-- for this to work the mouse cursor must be located outside
-- of the target toolbar rather than over it, but unlike with
-- the shortcut, whether the toolbar is in focus is immateral
MOUSEWHEEL = ""


-- The default is wheel up (outwards) - switching in ascending order,
-- wheel down (inwards) - switching in descending order;
-- enable by placing any alphanumeric character between
-- the quotes to revserse this behavior
MOUSEWHEEL_REVERSE = ""


-- Between the quotes insert number of nudges to effect
-- switch to next/previous toolbar;
-- the higher the number the lower the sensitivity;
-- normally a single scroll consists of 5-6 nudges;
-- when empty the sensitivity is at the maximum, i.e. 1
MOUSEWHEEL_SENSITIVITY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function Get_Open_Toolbars(tb_No, tb_No_midi) -- tb_No and tb_No_midi args are only used on the focus evaluation stage
local t = {41679, 41680, 41681, 41682, 41683, 41684, 41685, 41686,
41936, 41937, 41938, 41939, 41940, 41941, 41942, 41943} -- Toolbar: Open/close toolbar N
local t_midi = {41687, 41688, 41689, 41690, 41944, 41945, 41946, 41947} -- Toolbar: Open/close MIDI toolbar N
	local function GET(t, tb_No)
	local count_open, idx = 0
		for k, ID in ipairs(t) do
		local open = r.GetToggleCommandStateEx(0, ID) == 1
		--	if open then return k end
		idx = open and k or idx
		count_open = open and count_open+1 or count_open
			if count_open > 1 then return 0 end
		end
	return not tb_No and idx or tb_No and idx and idx == tb_No -- for the stage of focus evaluation after the toolbar switch, idx == tb_No when no toolbar was focused so no change
	end
return GET(t, tb_No), GET(t_midi, tb_No_midi)
end


function Mouse_Wheel_Direction(val, mousewheel_reverse) -- mousewheel_reverse is boolean
--local is_new_value,filename,sectionID,cmdID,mode,resolution,val = r.get_action_context() -- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards // val seems to not be able to co-exist with itself retrieved outside of the function, in such cases inside the function it's returned as 0
	if mousewheel_reverse then
	return val > 0 and -1 or val < 0 and 1 -- wheel up (forward) - leftwards/downwards or wheel down (backwards) - rightwards/upwards
	else -- default
	return val > 0 and 1 or val < 0 and -1 -- wheel up (forward) - rightwards/upwards or wheel down (backwards) - leftwards/downwards
	end
end


function Find_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful fot validating visibility of windows which can be docked

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

-- search for floating toolbar
local wnd = Find_Win(wnd_name)
-- search for a floating docker with one attached toolbar window // toolbars can be attached to a regular floating docker as well
or Find_Win(wnd_name..' (docked)') -- when a single toolbar is attached to a floating docker its title is 'MIDI 1 (docked)' or 'Toolbar 1 (docked)' or whatever the toolbar custom name is with '(docked)' added regardless of whether this a toolbar docker or a regular docker

	if wnd and r.JS_Window_IsVisible(tb) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker'
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search floating docker with multiple attached windows
local docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker'
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

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


function JS_Window_IsVisible(hwnd)
-- visibility functions JS_Window_IsVisible() and BR_Win32_IsWindowVisible() aren't suitable for visibility validation of windows in multi-window dockers because these return false if a docked window is inactive, but they're accurate if there's only one window in a docker
local parent, parent_tit
local toggle_state = r.GetToggleCommandStateEx
local docker = toggle_state(0, 40279) == 1 -- 'View: Show docker'
	for i = 1, 2 do
	parent = r.JS_Window_GetParent(hwnd)
	parent_tit = r.JS_Window_GetTitle(parent)
		-- floating dockers
		if parent_tit == 'Toolbar Docker' and toggle_state(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker'
		or parent_tit == 'Docker' and docker -- regular docker
		or parent_tit:match('(docked)') and r.JS_Window_IsVisible(hwnd) -- single window in a floating toolbar / regular docker
		then return hwnd end
	hwnd = parent -- update for the next cycle
	end
	-- if floating docker wasn't found, search docker attached to the main window
	-- it cannot be searched in the loop above because being a child of the floating docker window it precedes it in the parent search and would cause loop exit before the floating docker window title could be evaluated
	if parent_tit == 'REAPER_dock' and docker then return hwnd end

end


function Find_x_Focus_Toolbar(tb_No, midi)
-- tb_No is a toolbar number, integer
-- midi is boolean, if true, tb_No refers to a MIDI toolbar number
-- an edge case which will fail the function is if the toolbar name was changed while it was docked
-- because docked toolbar names aren't auto-updated
-- https://forum.cockos.com/showthread.php?t=280103
local tb_No = tb_No and math.floor(tb_No) -- truncating decimal 0 otherwise after concatenation it's prone to giving false results
local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')
local t_open = midi and {41687, 41688, 41689, 41690, 41944, 41945, 41946, 41947} -- Toolbar: Open/close MIDI toolbar N
or {41679, 41680, 41681, 41682, 41683, 41684, 41685, 41686, 41936, 41937, 41938,
41939, 41940, 41941, 41942, 41943} -- Toolbar: Open/close toolbar N

	if sws or js then -- if no extensions, will return what was fed in
	local menus = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-menu.ini'
	local reaper_menu = r.file_exists(menus)
	local tb
		if tb_No then
		tb = 'toolbar '
		local tb_tit = midi and 'Floating MIDI '..tb..tb_No or 'Floating '..tb..tb_No -- must be exact otherwise MIDI toolbar name will intefrere because its name's last part is identical to the regular toolbar name, plus the title key may not exist in reaper-menu.ini in which case the default name will be searched for // REAPER allows naming toolbars identically
		local found
			if reaper_menu then
				for line in io.lines(menus) do
					if line:match(tb_tit) then found = 1
					elseif found and line:match('^title=') then
					tb_tit = line:match('^title=(.+)') break
					elseif found and line:match('%[.+%]') then -- next section, will be true if found section doesn't include 'title' key and the loop didn't exit earlier
					found = nil
					break
					end
				end
			end
		tb_tit = found and tb_tit or (midi and 'MIDI '..tb_No or 'Toolbar '..tb_No) -- if not found use default title
		-- here visibility validation for js function isn't needed because toolbar has already been found
		tb = js and r.JS_Window_Find(tb_tit, true) -- exact true // ensures that 'Toolbar 1' and 'Toolbar 11' and the like are not confused
		or sws and Find_Window_SWS(tb_tit) -- sws native function doesn't find children windows, such as docked ones, hence the custom one
		else -- no open toolbar was detected, either none is open or some are open but docked and their window is inactive, so search dockers
		local title, len = midi and 'MIDI ' or 'Toolbar ', midi and 8 or 16
		local t = {}
			for i = 1, len do -- construct table dynamically
			t[i] = title..i
			end
			if reaper_menu then
			local patt = midi and '%[.+MIDI toolbar %d+%]' or '%[Floating toolbar %d+%]'
				for line in io.lines(menus) do -- collect names of all toolbars in the relevant context
					if line:match(patt) then tb_No = line:match('%d+')
					elseif tb_No and line:match('%[.+%]') then -- next section, will be true if found section doesn't include 'title' key // leaving just in case because sections of toolbars from different contexts don't seem to be mixed which could make the next conditon falsely true if the found section didn't include the title= key but the next one from different context did
					tb_No = nil -- reset
					elseif tb_No and line:match('^title=') then -- if no title, the default title remains in the table
					t[tb_No+0] = line:match('^title=(.+)')
					tb_No = nil -- reset
					end
				end
			end
			for k, name in ipairs(t) do
			tb = js and r.JS_Window_Find(name, true) or sws and Find_Window_SWS(name) -- sws native function doesn't find children windows, such as docked ones, hence the custom one
			tb = js and JS_Window_IsVisible(tb) or sws and tb -- windows are found irrespective of their visibility, hence the validation, if only SWS ext is available the visibility is evaluated inside Find_Window_SWS()
				if tb then tb_No = k break end -- exist as soon as inactive docked toolbar appropriate for the context is found
			end
		end
		
		if tb_No then -- may be nil if toolbar is closed
		local commID = t_open[tb_No]
		local activate = r.GetToggleCommandStateEx(0, commID) == 0 and r.Main_OnCommand(commID, 0) -- activate inactive toolbar, makes the tab of a docked toolbar active
		end
		
		
	local set_focus = js and r.JS_Window_SetFocus(tb) or sws and r.BR_Win32_SetFocus(tb)
	-- https://forum.cockos.com/showthread.php?t=221096
	-- https://forum.cockos.com/showthread.php?t=212174&page=5
	local activate = js and r.JS_WindowMessage_Send(tb, 'WM_MOUSEACTIVATE', 0, 0, 0, 0) or sws and r.BR_Win32_SendMessage(tb, 0x0021, 0, 0) -- in the js function instead of 'WM_MOUSEACTIVATE' its numeric value '0x0021' string can be used; activates toolbar in a floating and attached docker as well; thanks to Edgemeal for showing that coordinates aren't necessary if the window is focused https://forum.cockos.com/showthread.php?t=212174&page=5#161, also FeedTheCat https://forum.cockos.com/showthread.php?t=259184#8 the parameter is taken from https://github.com/justinfrankel/WDL/blob/6a7ba42ab175a859c565c4f68b890048d53b94c7/WDL/swell/swell-types.h#L959, not sure about other arguments, but works with all being 0

	-- switch focus to relevant main window elements to move it from the found toolbar to which it was set above because when a toolbar is focused running the script with a shortcut won't work unless it's global, and global scope is only available for shortcuts in the Main section of the Action list
		if not midi then -- not midi when the script is run from the Main section of the Action list, that is sectionID returned by get_action_context() is not 32060
	--	r.JS_Window_SetFocus(r.GetMainHwnd()) -- DOESN'T SET FOCUS TO THE MAIN WINDOW if the open MIDI Editor is docked and attached to the main window because the MIDI Editor ends up being focused instead which prevents targeting Arrange toolbars while the MIDI Editor is open
		local main_wnd = js and r.JS_Window_Find('trackview', true) or sws and Find_Window_SWS('trackview', true) -- want_main_children true
		local focus = js and r.JS_Window_SetFocus(main_wnd) or sws and r.BR_Win32_SetFocus(main_wnd)
		else -- no additional conditions are required because if midi is true, the script is run from inside an open MIDI Editor window
	--	r.JS_Window_SetFocus(r.MIDIEditor_GetActive()) -- DOESN'T MAKE MIDI EDITOR DOCKED IN A DOCKER ATTACHED TO THE MAIN WINDOW FOCUSED, BUT DOES WORK FOR FLOATING MIDI EDITOR DOCKED OR NOT
		local ME_wnd = js and r.JS_Window_Find('midiview', true) or sws and Find_Window_SWS('midiview')
		local focus = js and r.JS_Window_SetFocus(ME_wnd) or sws and r.BR_Win32_SetFocus(ME_wnd) -- 'midiview' window parent title is 'Edit MIDI' after toggling the MIDI Editor (docked or not) but focusing this parent doesn't work; alternative to 'midiview' is 'midipianoview', when either is focused without toggling the MIDI Editor, the parent is the window titled 'MIDI take: <MIDI take name>'
	--	r.Main_OnCommand(40716,0) r.Main_OnCommand(40716,0) -- View: Toggle show MIDI editor windows // DOES MAKE MIDI EDITOR DOCKED IN A DOCKER ATTACHED TO THE MAIN WINDOW FOCUSED, and works generally in other window states, BUT FLICKERING LOOKS UGLY
		end

	end

return tb_No

end



function Process_Mousewheel_Sensitivity(val, cmdID, MOUSEWHEEL_SENSITIVITY)
-- val & cmdID stem from get_action_context()
-- MOUSEWHEEL_SENSITIVITY unit is one mousewheel nudge, normally a single scroll consists of 5-6 nudges
	if MOUSEWHEEL_SENSITIVITY == 1 then return true end
local cmdID = r.ReverseNamedCommandLookup(cmdID) -- command ID differs in different Action list sections
local data = r.GetExtState(cmdID, 'MOUSEWHEEL')
local val = #data == 0 and val or data+0 + val
local val = math.abs(val/MOUSEWHEEL_SENSITIVITY) >= 15 and 0 or val
r.SetExtState(cmdID, 'MOUSEWHEEL', val, false) -- persist false
return val == 0
end



function Close_Toolbars(midi, t_open, t_open_midi)
local t_outgo_ctx = midi and t_open or not midi and t_open_midi
	for k, ID in ipairs(t_outgo_ctx) do -- close all toolbars from the outgoing context
		if r.GetToggleCommandStateEx(0,ID) == 1 then
		r.Main_OnCommand(ID, 0)
		end
	end
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


ONE_TOOLBAR_PER_PROJECT = #ONE_TOOLBAR_PER_PROJECT:gsub(' ','') > 0
-- these actions target a focused toolbar window, therefore focus is the primary means of toolbar identification
local t_switch_reg = {41105, 41106, 41107, 41108, 41647, 41648, 41649, 41650,
41948, 41949, 41950, 41951, 41952, 41953, 41954, 41955}	-- Toolbars: Switch to toolbar N
local t_switch_midi = {41659, 41660, 41661, 41662, 41956, 41957, 41958, 41959} -- Toolbars: Switch to MIDI toolbar N
local t_open = {41679, 41680, 41681, 41682, 41683, 41684, 41685, 41686,
41936, 41937, 41938, 41939, 41940, 41941, 41942, 41943} -- Toolbar: Open/close toolbar N
local t_open_midi = {41687, 41688, 41689, 41690, 41944, 41945, 41946, 41947} -- Toolbar: Open/close MIDI toolbar N
local is_new_value,filename,sectionID,cmdID_orig,mode,resolution,val = r.get_action_context() -- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards // the function must be outside as it cannot work properly inside more than 1 user function, in which case val will be 0
local midi = sectionID == 32060
local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')
local ext = js or sws
local tb_No, tb_No_midi = Get_Open_Toolbars() -- returns 0 if there're several open toolbars for the same context // when more than one toolbar is open for a particular context but only one is active (in the docker or floating) the rest are ignored, since only the first active toolbar is being detected, the inactive ones are only searched no active was found and extensions are installed 


	if ONE_TOOLBAR_PER_PROJECT then
	local tb_idx = midi and tb_No_midi or not midi and tb_No -- select toolbar number relevant for the incoming context
	local t = midi and t_open_midi or not midi and t_open -- same to be able to evaluate incoming context toolbar state
	SWITCHED = tb_idx and tb_idx > 0 and r.GetToggleCommandStateEx(0, t[tb_idx]) == 0 or not tb_idx -- will be used in toolbars closing routine to abort if the incoming context toolbar was inactive since there's no point in proceeding otherwise the toolbar just activated by switching from another toolbar will be switched again to the next/previous in the main routine which is counter-intuitive
	end

local ABORT = not midi and not tb_No or midi and not tb_No_midi

	if ext then
		if not ONE_TOOLBAR_PER_PROJECT then -- only search for a toolbar compatible with the current context
		tb_No, tb_No_midi = not midi and (not tb_No ~= 0 and Find_x_Focus_Toolbar(tb_No) or tb_No), midi and (tb_No_midi ~= 0 and Find_x_Focus_Toolbar(tb_No_midi, midi) or tb_No_midi) -- toolbar number is 0 when there're several open for the same context as returned by Get_Open_Toolbars(), keeping it so the error message can be generated // the function only runs if extensions are installed, otherwise returns the same value // RETURN VALUE FOR A TOOLBAR FROM THE OUTGOING CONTEXT IS FALSE EVEN IF Get_Open_Toolbars() RETURNED A VALID ONE, BECAUSE IT'S IRRELEVANT
			if ABORT and (not midi and tb_No or midi and tb_No_midi) then
			return r.defer(no_undo()) end -- if toolbar wasn't found with Get_Open_Toolbars() but was found with Find_x_Focus_Toolbar() which it would if it was docked and inactive, there's no point in proceeding otherwise the toolbar just switched to will be switched again to the next/previous in the main routine which is counter-intuitive // this condition can only be true if ONE_TOOLBAR_PER_PROJECT sett isn't enabled because in this case the validity of Get_Open_Toolbars() return values may change

		else -- search for toolbars from both contexts
		tb_No, tb_No_midi = tb_No ~= 0 and Find_x_Focus_Toolbar(tb_No) or tb_No, tb_No_midi ~= 0 and Find_x_Focus_Toolbar(tb_No_midi, true) or tb_No_midi -- WHEN ONE_TOOLBAR_PER_PROJECT SETT IS ENABLED BOTH TOOLBAR NUMBERS MUST BE RETURNED REGARDLESS OF THE INCOMING CONTEXT SO THAT THE ONE FROM THE OUTGOING CONTEXT CAN STILL BE DETECTED AND CLOSED

		-- re-store focus of the current context after running Find_x_Focus_Toolbar() above because it may be switched inside it
			local wnd = midi and 'midiview' or 'trackview'
			local wnd = js and r.JS_Window_Find(wnd, true) or sws and Find_Window_SWS(wnd, true) -- want_main_children true to target 'trackview'
			local focus = js and r.JS_Window_SetFocus(wnd) or sws and r.BR_Win32_SetFocus(wnd)

		end
	end


local cmdID = r.ReverseNamedCommandLookup(cmdID_orig):sub(-40) -- using last 40 chars of alphanumeric command ID which are identical for the same script in all sections of the Action list // cmdID_orig is used in Process_Mousewheel_Sensitivity()

	if ONE_TOOLBAR_PER_PROJECT then
	-- close toolbar of the outgoing context if any
		if tb_No and tb_No_midi then -- after context change toolbars of both types are open, close outgoing context toolbar
		local t = midi and t_open or not midi and t_open_midi -- reverse so that toolbar from another context is closed
		local tb_idx = midi and tb_No or not midi and tb_No_midi -- same
		local commID = tb_idx and t[tb_idx]
			if commID then			
			local open = r.GetToggleCommandStateEx(0, commID) == 1
				if open then
				ACT(commID)
				else -- if the outgoing context toolbar is docked and inactive, activate and close 
				ACT(commID) ACT(commID)
				end
			end
		local tb_idx = midi and tb_No_midi or not midi and tb_No -- direct relationship, to be able to set focus to the remaining toolbar
		Close_Toolbars(midi, t_open, t_open_midi) -- close any other open toolbars from the outgoing context, won't affect docked and inactive ones since their visibility cannot be ascertained because in this case the associated open/close action toggle state is Off // must be inside each block because if placed at the top may close a single open toolbars from the outgoing context and there'll be nothing to switch
			if ext and tb_idx > 0 then Find_x_Focus_Toolbar(tb_idx, midi) end -- re-focus toolbar and context after deletion above, only runs if extensions are installed
	-- switch to a toolbar of the incoming context or open one
		elseif midi and not tb_No_midi and tb_No or not midi and not tb_No and tb_No_midi then -- after context change only toolbar(s) from the outgoing context is open, switch it to one appropriate for the context or open it
		SWITCHED = true
		
		-- When several outgoing context toolbars are open (toolbar number is 0), first close all, then open the incoming context toolbar, this is safer, otherwise the main toolbar main end up being switched because no other toolbar will have focus
		-- When only one outgoing context toolbar is open, switch it to the incoming context toolbar
		-- When there's a mix of open toolbars from different contexts, those from the outgoing context are closed, and either one from the incoming context is switched or the error mesaage is thrown if more than one are open
		
			if midi and tb_No == 0 or not midi and tb_No_midi == 0 then -- when there're several open from the outgoing context
			Close_Toolbars(midi, t_open, t_open_midi) -- close any open toolbars from the outgoing context, won't affect docked and inactive ones since their visibility cannot be ascertained because in this case the associated open/close action toggle state is Off // must be inside each block because if placed at the top may close a single open toolbars from the outgoing context and there'll be nothing to switch
			end			
		local key = midi and 'MIDI_ED_CTX_LAST_TOOLBAR' or 'ARRANGE_CTX_LAST_TOOLBAR'
		local ret, tb_idx = r.GetProjExtState(0, cmdID, key)
		local tb_idx = ret == 1 and math.floor(tb_idx+0)
		local tb_idx = tb_idx and tb_idx > 0 and tb_idx or 1 -- if not stored or 0 value was stored accidentally, open toolbar 1
		local t = midi and (tb_No > 0 and t_switch_midi or t_open_midi) or not midi and (tb_No_midi > 0 and t_switch_reg or t_open)
		ACT(t[tb_idx])
			if midi and tb_No > 0 or not midi and tb_No_midi > 0 then -- when there's one open from the outgoing context
			Close_Toolbars(midi, t_open, t_open_midi)
			end
			if ext and tb_idx > 0 then Find_x_Focus_Toolbar(tb_idx, midi) end -- re-focus context, only runs if extensions are installed
		r.SetProjExtState(0, cmdID, key, tb_idx) -- store the incoming context toolbar
		local tb_No, tb_No_midi = Get_Open_Toolbars() -- evaluate the switch
		local err = not midi and tb_No ~= tb_idx or midi and tb_No_midi ~= tb_idx -- the number of toolbar just switched to isn't what it's supposed to be
			if err then Error_Tooltip('\n\n no focused toolbar \n\n',1,1) -- caps, spaced true
			return r.defer(no_undo()) end
		end
	-- store outgoing context toolbar
	local tb_idx = midi and tb_No or not midi and tb_No_midi
	local key = midi and 'ARRANGE_CTX_LAST_TOOLBAR' or 'MIDI_ED_CTX_LAST_TOOLBAR' -- reverse, because storing outgoing context toolbar
	local store = tb_idx and tb_idx ~= 0 and r.SetProjExtState(0, cmdID, key, tb_idx) -- store the one which was closed or switched, if any, toolbar idx is 0 when more than one toolbar is open for the same context
		if SWITCHED then return r.defer(no_undo()) end -- abort since there's no point in proceeding otherwise the toolbar just switched to will be switched again to the next/previous in the main routine which is counter-intuitive
	end


local key = midi and 'MIDI_ED_CTX_LAST_TOOLBAR' or 'ARRANGE_CTX_LAST_TOOLBAR'

	if not midi and not tb_No or midi and not tb_No_midi then -- if no toolbar which corresponds to the current context, open one
	local ret, tb_idx = r.GetProjExtState(0, cmdID, key)
	local tb_idx = ret == 1 and tb_idx+0 or 1 -- if not stored, open toolbar 1
	local t = midi and t_open_midi or not midi and t_open
	ACT(t[tb_idx]) -- toggle state of a docked toolbar in inactive tab is OFF as if it were closed and Get_Open_Toolbars() function cannot detect it, so if a toolbar from incoming context sits in a docker and is inactive the action activates it, but not brings into focus and later in the routine the focused toobar from outgoing context sitting in another docker (if any) tab will be switched instead // if the toolbar isn't inactive in a docker the action will open it
		if ext then Find_x_Focus_Toolbar(tb_idx, midi) end -- only runs if extensions are installed
	local store = r.SetProjExtState(0, cmdID, key, tb_idx) -- store to be able to re-open next time if needed
	return r.defer(no_undo()) end -- abort since there's no point in proceeding otherwise the toolbar just opened will be immediately switched to the next/previous in the main routine provided it was already focused (in a docker for example), or the focused toolbar from the outgoing context will be switched instead, all of which is counter-intuitive

	if midi and tb_No_midi == 0 or not midi and tb_No == 0 -- 0 is returned by Get_Open_Toolbars() when there're several open toolbars of the same type // having several open doesn't make sense because they're mutually exclusive, when the focused one is switched to another open toolbar the latter auto-closes, the same toolbar cannot be open in more than one windows simultaneously
	then
	local err = 'more than one toolbar is open \n\n\tin the current context'
	Error_Tooltip('\n\n '..err..' \n\n',1,1) -- caps, spaced true
	return r.defer(no_undo()) end

MOUSEWHEEL = #MOUSEWHEEL:gsub(' ','') > 0
MOUSEWHEEL_REVERSE = #MOUSEWHEEL_REVERSE:gsub(' ','') > 0
MOUSEWHEEL_SENSITIVITY = MOUSEWHEEL_SENSITIVITY:gsub(' ','')
MOUSEWHEEL_SENSITIVITY = tonumber(MOUSEWHEEL_SENSITIVITY) and tonumber(MOUSEWHEEL_SENSITIVITY) > 1 and math.floor(math.abs(tonumber(MOUSEWHEEL_SENSITIVITY))) or 1
MOUSEWHEEL_SENSITIVITY = MOUSEWHEEL and val == 63 and 1 or MOUSEWHEEL_SENSITIVITY -- if mousewheel and mousewheel sensitivity are enabled but the script is run via a shortcut (val returned by get_action_context() is 63), disable the mousewheel sensitivity otherwise if it's greater than 4 the script won't be triggered at the first run because the expected value will be at least 5x15 = 75 (val returned by get_action_context() is ±15) while val will only produce 63 per execution, it will only be triggered on the next run since 63x2 = 126 > 75
DIRECTION = #DIRECTION:gsub(' ','') > 0


	if MOUSEWHEEL and Process_Mousewheel_Sensitivity(val, cmdID_orig, MOUSEWHEEL_SENSITIVITY)
	or not MOUSEWHEEL then

	local idx = midi and tb_No_midi or tb_No

	local t_switch = midi and t_switch_midi or t_switch_reg

	local dir = Mouse_Wheel_Direction(val, MOUSEWHEEL_REVERSE)

	local ascend, descend = idx+1 <= #t_switch and idx+1 or 1, idx-1 > 0 and idx-1 or #t_switch
	local idx = MOUSEWHEEL and (dir > 0 and ascend or dir < 0 and descend)
	or DIRECTION and descend or ascend

	local main_tb_open = r.GetToggleCommandStateEx(0,41651) == 1 -- Toolbar: Open/close main toolbar

	local act = idx and ACT(t_switch[idx])

		if not ext then

		local main_tb_closed = r.GetToggleCommandStateEx(0,41651) == 0 -- Toolbar: Open/close main toolbar

			if main_tb_open and main_tb_closed then -- main toolbar was focused and itself got switched to the next toolbar instead of the regular toolbar which was open // MIDI Editor and Arrange main toolbars areas seem linked and when MIDI Editor main toolbar area is the last focused the swithing still occures at the main toolbar in the Arrange
			ACT(41646) -- Toolbars: Switch to main toolbar // restore main
			Error_Tooltip('\n\n wrong focus - main toolbar \n\n',1,1) -- caps, spaced true
			return r.defer(no_undo()) end

		local retval, retval_midi = Get_Open_Toolbars(tb_No, tb_No_midi)

		local err = ' no focused toolbar '
			if retval == 0 and tb_No_midi and not retval_midi
			or retval_midi == 0 and tb_No and not retval -- two toolbars for two contexts were open and a toolbar from another context got switched after the context had become invalid because the focus hadn't changed, thus creating two toolbars for the same context which is contrary to the design // if a docked toolbar is focused but its tab is inactive it will still be switched regardless of its context, however there's no way to detect it with the native API since toolbar open/close action toggle state will be Off so an error tooltip will still be displayed and no further cycling will be possible; if after such switch any other toolbar is brought into focus and the script is executed again the docked toolbar under the inactive tab will auto-close because the focused toolbar will be switched to the toolbar which the inactive toolbar has been already switched to in the background and because a toolbar cannot be open in two different windows simultaneously
			then
			local idx, t = table.unpack(retval_midi and {tb_No, t_switch_reg} or retval and {tb_No_midi, t_switch_midi})
			ACT(t[idx]) -- restore originally open toolbars by switching back
			local err = ONE_TOOLBAR_PER_PROJECT and err or '\tfocused toolbar \n\n does not match context ' -- the 2nd error message isn't suitable when one toolbar per project setting is enabled because toolbar from another context will either auto-close or will be switched so that there'll always be only one open toolbar
			Error_Tooltip('\n\n'..err..'\n\n',1,1) -- caps, spaced true
			elseif not midi and retval or midi and retval_midi then -- no focused toolbar // normally happens when a focused toolbar was closed
			Error_Tooltip('\n\n'..err..'\n\n',1,1) -- caps, spaced true
			return r.defer(no_undo()) end

		end

	local store = idx and r.SetProjExtState(0, cmdID, key, idx) -- store to be able to re-open next time if needed

	return r.defer(no_undo()) end

