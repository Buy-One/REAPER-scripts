--[[
ReaScript name: BuyOne_Open Media Explorer and-or focus its Search field.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI
Provides: [main=main,midi_editor] .
About:	If the Media Explorer is closed, the script opens 
		it and brings its search field into focus for keyboard 
		input.  
		If the Media Explorer is already open it only brings 
		its search field into focus.
		
		In order to be able to run the script regardless 
		of the mouse cursor focus bind this script to a 
		shortcut having selected 'Global+text fields' option 
		in the Scope drop-down menu of keyboard shorcut 
		assignment dialogue.  
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
		t[#t+1] = {child=child, title=txt}
	--[[ -- OR, depending on the design
		t[txt] = child
	]]
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return #t > 0 and t
end



function Get_Child_Windows_JS(parent_hwnd)

	if not parent_hwnd then return end

local child = r.JS_Window_GetRelated(parent_hwnd, 'CHILD')
local child_t = {}
	if child then
		repeat
		local title = r.JS_Window_GetTitle(child)
		child_t[#child_t+1] = {child=child, title=title}
		child = r.JS_Window_GetRelated(child, 'NEXT')
		until not child
	end
return (#child_t > 0 or next(child_t)) and child_t

end


function Focus_Window(sws, js, hwnd)
	if sws then
	r.BR_Win32_SendMessage(hwnd, 0x0007, 0, 0) -- 0x0007 WM_SETFOCUS
	else
	r.JS_WindowMessage_Send(hwnd, 0x0007, 0, 0, 0, 0) -- 'WM_SETFOCUS' string doesn't work for this particular message here
	end
-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
end


local function wrapper(func,...)
-- https://forums.cockos.com/showthread.php?t=218805 Lokasenna
local t = {...}
return function() func(table.unpack(t)) end
end


function SET_FOCUS(GetToggleState, Focus_Window, show_MX, sws, js, hwnd, t)
	if GetToggleState(0, show_MX) == 1 and r.time_precise()-t >= 0.1 then -- since MX window is slow to load, 100 ms seem to be enough for it to load fully and register WM_SETFOCUS message // show_MX action toggle state seems to be updated immediately after opening but is not a good indicator of window being rendered fully
	Focus_Window(sws, js, hwnd)
	return
	end
r.defer(wrapper(SET_FOCUS, GetToggleState, Focus_Window, show_MX, sws, js, hwnd, t))
end



local sws, js = r.BR_Win32_SendMessage, r.JS_WindowMessage_Send

	if not sws and not js then
	Error_Tooltip('\n\n\tthe script requires \n\n SWS/S&M or js_ReaScript API \n\n\t\textensions\n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end


local GetToggleState = r.GetToggleCommandStateEx
local show_MX = 50124 -- Media explorer: Show/hide media explorer
local is_off = GetToggleState(0, show_MX) == 0

	if is_off then -- true when the window itself is closed or a dock it's attached to
	r.Main_OnCommand(show_MX, 0) -- toggle On
	local MX = sws and Find_Window_SWS('Media Explorer', want_main_children) or r.JS_Window_Find('Media Explorer', true) -- both false and true work as 'exact' arg
		if MX then
		local children_t = sws and Get_Child_Windows_SWS(MX) or Get_Child_Windows_JS(MX)
			if children_t[8].child then -- search field is the 8th child window in the returned child window list
			-- start a defer loop to wait until the window is fully loaded and able to register WM_SETFOCUS message
			SET_FOCUS(GetToggleState, Focus_Window, show_MX, sws, js, children_t[8].child, r.time_precise()) -- msg 0x0007 WM_SETFOCUS
			end
		end
	else -- if open, focus search field
	local MX = sws and Find_Window_SWS('Media Explorer', want_main_children)
	MX = MX or r.JS_Window_Find('Media Explorer', true) -- both false and true work as 'exact' arg
	local children_t = sws and Get_Child_Windows_SWS(MX) or Get_Child_Windows_JS(MX)
		if children_t[8].child then
		Focus_Window(sws, js, children_t[8].child)
		end
	end


do return r.defer(no_undo) end






