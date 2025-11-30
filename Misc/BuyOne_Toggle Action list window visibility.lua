--[[
ReaScript name: BuyOne_Toggle Action list window visibility.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1 #Added support for floating docker 
					and accounted for various docking scenarios
					#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI
Provides: [main=main,midi_editor] .
About:	The script provides the ability to toggle
			the Action list window, which is not possible
			with the action 'Show action list' because
			it doesn't allow closing the window. A floating
			Action list window can be closed with Esc key
			but a docked window can't. This script covers
			both cases.

			If the window is docked in a closed docker
			the script will open the docker along with all
			other open windows docked in the same docker. 
			And if the docker is split, only open windows 
			on the same side of the split as the Action list 
			window will be shown along with it.

			In order to be able to toggle the Action list
			window regardless of the mouse cursor focus
			bind this script to a shortcut having selected
			Global+text fields option in the Scope drop-down
			menu of keyboard shorcut assignment dialogue.
			Otherwise you will have to bring REAPER main window
			into focus in order for the shortcut to be registered.

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
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
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


function Is_Window_Docked(wnd)
-- includes floating docker as well
local GetParent = r.BR_Win32_GetParent or r.JS_Window_GetParent
	if not GetParent then return end -- no extension is installed
local wnd, retval, title = wnd
	repeat
	wnd = GetParent(wnd)
		if r.BR_Win32_GetWindowText then
		retval, title = r.BR_Win32_GetWindowText(wnd)
		elseif r.JS_Window_GetTitle then
		title = r.JS_Window_GetTitle(wnd)
		end
		if title == 'REAPER_dock' then return true end
	until not wnd
end


function Is_Wnd_Docked_In_Floating_Docker(hwnd)
-- hwnd is window handle which can be obtained with
-- Find_Window_SWS() or reaper.JS_Window_Find()
-- unlike Is_Wnd_Docked_In_Floating_Docker1() this function
-- only works for open windows, because hwnd
-- must be valid;
-- the window can be opened in a closed floating docker
-- https://github.com/Buy-One/Dox/blob/main/reaper.ini%20toolbars%20and%20dockers
-- returns nil if window is not docked in the floating docker

local dockermode, isFloatingDocker = r.DockIsChildOfDock(hwnd)

	if isFloatingDocker then
		for line in io.lines(r.get_ini_file()) do -- determine dockermode status
		local status = line:match('^dockermode'..dockermode..'=(%d+)')
			if status then
			return status+0 < 90000 and 1 -- i.e. 32768 or 32770, open floating docker
			or 2 -- i.e. 98304 or 98306, closed floating docker
			end
		end
	end

end


function Close_Action_List(sws, js, hwnd)
	if sws then
	r.BR_Win32_SendMessage(hwnd, 0x0010, 0, 0) -- 0x0010 WM_CLOSE; 0x0002 WM_DESTROY contributes to creation of ghost windows if followed by window toggle action, doesn't destroy floating window; 0x0012 WM_QUIT leaves tab if window is docked and doesn't set toggle state to off
	else
	r.JS_WindowMessage_Send(hwnd, 'WM_CLOSE', 0, 0, 0, 0)
	end
-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
end


local function wrapper(func,...)
-- https://forums.cockos.com/showthread.php?t=218805 Lokasenna
local t = {...}
return function() func(table.unpack(t)) end
end


function monitor_toggle_state(GetToggleState, show_act_lst)
	if GetToggleState(0, show_act_lst) == 0 then
	r.Main_OnCommand(show_act_lst, 0) -- toggle On
	return
	end
r.defer(wrapper(monitor_toggle_state, GetToggleState, show_act_lst))
end




local sws, js = r.BR_Win32_SendMessage, r.JS_WindowMessage_Send

	if not sws and not js then
	Error_Tooltip('\n\n\tthe script requires \n\n SWS/S&M or js_ReaScript API \n\n\t\textensions\n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local GetToggleState = r.GetToggleCommandStateEx
local show_act_lst = 40605 -- Show action list
local show_docker = 40279 -- View: Show docker
local is_off = GetToggleState(0, show_act_lst) == 0

	if is_off then -- true when the window itself is closed, NOT a dock it's attached to; the condition also applies to scenario when not only the window is closed but the dock it's docked at as well

	r.Main_OnCommand(show_act_lst, 0) -- toggle On

	else -- hide if visible docked or floating, or show if open and docked in a closed docker

	local action_list = sws and Find_Window_SWS('Actions', want_main_children)
	action_list = action_list or r.JS_Window_Find('Actions', true) -- both false and true work as 'exact' arg
	local is_docked = Is_Window_Docked(action_list)
	local dock_open = GetToggleState(0, show_docker) == 1

		if action_list and (not is_docked or dock_open) then -- visible, floating or docked in an open docker, hide

		-- Determine if the window while being open (handle is valid) 
		-- is attached to a closed floating docker
		-- in which case WM_CLOSE will close it in the docker instead of making the docker
		-- visible and the script will have to be run twice in order to show the window,
		-- so if this is the case, close it and then re-open witin one script execution;
		-- if using function which requires window handle, the evaluation must be done
		-- before closure, otherwise the handle will become invalid,
		-- if using function which requires window reaper.ini identifier, 
		-- the evaluation can be done after closure
		local status = Is_Wnd_Docked_In_Floating_Docker(action_list) -- floating docker status 1 open, 2 closed, nil - window is not docked in the floating docker		

		-- WM_DESTROY message alone doesn't work for a floating window, causes creation
		-- of window duplicates when it's re-opened with action,
		-- works for docked window but decolorizes window background,
		-- and after the docked window is manually moved within the docker
		-- or to another docker, ghost window gets created on top of decoloration,
		-- so when other docked windows are activated by click on their tab
		-- the target window graphics keep being displayed instead,
		-- preceding WM_DESTROY message with ShowWindow SW_HIDE (0) makes it work
		-- without glitches for floating window and prevents background decoloration
		-- in the docked window, but can't prevent glitches after the docked window
		-- is moved within the docker or to another docker,
		-- these glitches can only be cured by REAPER restart, undocking the window
		-- before changing its dock position, closing and re-opening the docker don't help;
		-- the solution for both docked and undocked window is use of WM_CLOSE message alone
		-- instead of WM_DESTROY or in combination with SW_HIDE

		Close_Action_List(sws, js, action_list)

			if status and status == 2 then -- re-open the window docked in the closed floating docker which will cause the docker to open as well; after WM_CLOSE the window toggle state is set to Off BUT not fast enough for the script, hence the defer function to monitor toggle state change and then trigger re-opening
			monitor_toggle_state(GetToggleState, show_act_lst)
			end

		elseif action_list then -- open but invisible, likely because of being docked in a closed docker, in which case window toggle state wasn't set to Off so cannot be toggled to On right away, therefore first close and then re-open; this is preferable over toggling the docker open with the action 'View: Show docker' because the action opens all dockers, including floating, while toggling the window open - only opens the docker it's attached to

		Close_Action_List(sws, js, action_list)		
		monitor_toggle_state(GetToggleState, show_act_lst) -- after WM_CLOSE the window toggle state is set to Off BUT not fast enough for the script, hence the defer function to monitor toggle state change and then trigger re-opening

		end

	end


do return r.defer(no_undo) end






