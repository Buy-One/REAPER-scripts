--[[
ReaScript name: BuyOne_Toggle minimize floating windows.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
Screenshot: https://github.com/Buy-One/screenshots/blob/main/Toggle%20minimize%20floating%20windows.mp4
About:	When the script is first applied to a floating window, the window 
	gets minimized and placed at the bottom of the REAPER main window.
	When it's applied to the window which was minimized by it, the
	window original size and location on the screen are restored.
	
	Minimized windows line up in a row from left to right at the 
	bottom of the REAPER main window. When one minimized window is 
	maximized the gap which has been left in the row is filled up 
	by following minimized windows to. 
	They can be moved around freely, this will not affect the ability
	to restore their original properties.

	The minimized windows can be closed manually without restoring
	their orginal size and location. As long as the size and coordinates
	haven't been restored by the script they are kept in the project 
	during the session (and after quitting REAPER, provided the project 
	was saved), can be recalled later and a gap which is left in the 
	minimized windows row isn't filled up by the following windows,
	so when re-opened, it will occupy the same screen space it occupied 
	before closure. So if you wish to avoid creation of gaps in the 
	minimized windows row as a result of window closing, before closing
	toggle it back to its original properies with the script.  
	Once a minimized window original properties have been restored by 
	the script (even if it was resized manually after being minimized) 
	its data are cleared.  
	When a window from the middle or the very beginning of the minimized 
	windows row is restored, the minimized windows to its right will 
	shift leftward to close the gap left by it. Such shift will work as 
	long as such minimized windows weren't closed and then re-opened or,
	if they were closed, their name hasn't changed.
	
	The script can be executed either with a shortcut, with a click
	on a toolbar button, on the 'Run' button in the Action list window
	or by direct double click on the script entry in the Action list.
	Still execution with a shortcut is the most reliable.

	Regardless of the execution method the target window must be first
	brought into focus with a mouse click, so that its top bar becomes
	highlighted.
	
	A shortcut the script is bound to must be applied with the scope
	being 'Global+text fields' which will ensure that REAPER main
	window receives keyboard input even when it's not in focus because
	the target window is in focus at that moment.
	
	If the script is executed with a shortcut while these windows are 
	in focus, it will still target the window which was focused before 
	the focus was moved to these windows.
	
	It's advised to save the project after every script execution so
	that windows properties are stored in the project data and can be 
	recalled in the next project session. For this purpose execute 
	the script from within a custom action 
	
	Custom: Toggle minimize floating windows and save the project
		BuyOne_Toggle minimize floating windows.lua
		File: Save project
				
	
	BATCH ACTIONS
	
	When project tabs are switched back and forth, minimized FX chain
	window width and floating FX windows width and height will be reset
	to their original size. To restore their minimized size arm the script
	(which is convenient to do by right-clicking a toolbar button linked
	to the script) and follow the dialogue options.  
	The same technique can be applied for batch restoration of windows 
	initial minimized coordinates and size after they have been moved 
	elsewhere on the screen or for batch restoration of their original 
	coordinates and size, including after project load. Restoration of
	minimized window properties after REAPER launch under the project 
	they were stored in may not always succeed 100% because that depends 
	on whether the window is open which isn't the case with such windows 
	as Routing or track/take Envelope Manager windows because these don't 
	auto-reopen when REAPER is started.
				

	LIMITATIONS
	
	The script can be run only from a toolbar which has 'toolbar' word 
	in its title (regardless of the characters register). Otherwise it 
	will target the very toolbar window it's being executed from.
	
	Docked, toolbar windows (unless their name doesn't include 'toolbar'
	word in it regardless of the characters register) and 'Actions' 
	window aren't supported. If these windows happen to be in focus
	when the script is run with a shortcut, a first supported window 
	located below them in the Z order will be minimized instead.
	'Routing' window minimization isn't supported when MINIMIZE_FULLY 
	user setting is enabled.
	
	If the target window is modal, i.e. blocks access to other UI 
	elements, the script cannot be executed because keyboard input won't 
	be sent to REAPER main window and a toolbar, or a menu, or the 
	interface won't be accessible for the mouse click to execute 
	the script by other means.	
	
	Pinned windows (with the pressed pin in their title bar) cannot
	be minimized.
	
	It's not recommended to change names of takes if any windows 
	associated with them (such as FX chain, floating FX, Envelope Manager 
	windows) are minimized, or close such minimized windows after take 
	name was changed because this decreases the chances of being able to 
	restore their original properties. If this happens you will have to 
	restore such windows manually.
	
	If a minimized FX chain window is closed, when reopened by clicking 
	the TCP or take FX button, its original non-minimized dimensions get 
	restored while its minimized position is maintained so its original 
	position on the screen can still be restored with the script.
	
	Floating window of a bridged 32 bit plugin on a 64 bit system 
	cannot be minimized unless the option 'Run as -> Embed bridged UI' 
	is enabled for it, which is accessible via the plugin entry right 
	click context menu in the FX browser. If not enabled, when such
	window is in focus the script cannot be executed regardless of
	the method probably because it's not related to REAPER main window.
	
	The script was developed and only tested on Windows.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character
-- between the quotes to have windows minimized down
-- to their title bar as if they were displayed in a taskbar,
-- this leaves more screen space but has some drawbacks:
-- 1. if REAPER program window is minimized and then
-- maximized again the minimized windows will automatically
-- restore their default minimal dimensions,
-- to prevent that, instead of minimizing REAPER main window
-- to access windows of other applications, activate their
-- windows directly, for example by clicking their tabs in
-- the taskbar; this however won't work if you need access
-- to the desktop since there's no way around minimizing windows,
-- windows also won't keep their fully minimized state when
-- the project is just opened;
-- 2. to restore original properties of a fully minimized window,
-- in the pop-up menu which appears when its title bar is clicked,
-- click 'Restore' option, which will restore the minimized window
-- to its default minimal dimensions and coordinates, after which
-- its original properties can be restored with the script;
-- 3. a fully minimized window which has been closed loses
-- its fully minimized dimensions and on reopening will be restored
-- to its default minimal dimensions, so to recall its fully
-- minimized state arm the script, click on the Arrange canvas
-- and select appropriate options in the prompt dialogue;
-- 4. if a fully minimized window was dragged manually
-- to another location on the screen, next time it's fully
-- minimized it will be placed at the same screen coordinates
-- rather than at the bottom of the REAPER main window next
-- to other minimized windows or, if there's none, at the
-- bottom left hand corner like a minimized window would
-- as per the script design
MINIMIZE_FULLY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of caption and value
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local cap, val = t[i], t[i+1]
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


function Find_Win(title)
-- the function is case-agnostic
return r.BR_Win32_FindWindowEx('0', '0', '', title, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // does find single windows and single windows docked in floating dockers with '(docked)' appendage in the title, doesn't find children windows, such as docked in multi-tab docks and single docked in dockers attached to the main window
end



function Get_Top_Parent_Window(wnd)
-- get window top parent window
-- the one inclding the window title,
-- excluding REAPER main window,
-- useful for windows with many child windows
-- which may be parents to one another
-- in which case a single instance of BR_Win32_GetParent won't be enough
-- as is the case with track routing window
local wnd = wnd
	repeat
	local parent = r.BR_Win32_GetParent(wnd)
	local retval, title = r.BR_Win32_GetWindowText(parent)
		if title:match('REAPER')
		then return wnd -- if REAPER main window, return the previous window, also covers REAPER_dock window which suits this script because docked windows aren't supported
		else
		wnd = parent
		end
	until not parent
end



function Is_Window_Docked(wnd)
-- includes floating docker as well
local wnd = wnd
	repeat
	wnd = r.BR_Win32_GetParent(wnd)
	local retval, title = r.BR_Win32_GetWindowText(wnd)
		if title == 'REAPER_dock' then return true end
	until not wnd
end



function Get_Minimized_Wnd_Righmost_X_Coord(scr_cmdID, main_l)
local i = 0
local farthest_rt = main_l > -1 and main_l or 3 -- 3 is to give some distance from the screen left edge
	repeat
	local retval, title, coord = r.EnumProjExtState(0, scr_cmdID, i)
		if retval then
		local wnd = Find_Win(title) -- window will be found if open regardless of visibility
			if not wnd then -- minimized window name has changed
			wnd = r.BR_Win32_StringToHwnd(coord:match('.+,(.+)::')) -- find by the handle
			wnd = r.BR_Win32_IsWindow(wnd) and wnd -- will only be true if the window has never been closed otherwise the handle will become invalid
				if not wnd then -- the window had been closed and reopened hence couldn't be found by the stored handle because it became invalid
				local title = Find_Alternative_Window_Title(scr_cmdID, wnd, title)
				wnd = Find_Win(title)
				end
			end
			if wnd then
			local retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(wnd) -- get minimized window coordinates
				if rt > farthest_rt then
				farthest_rt = rt
				end
			end
		end
	i=i+1
	until not retval
return farthest_rt
end



function Get_Wnd_Title_By_Handle(scr_cmdID, wnd)
-- used inside Find_Alternative_Window_Title()
local i = 0
	repeat
	local retval, title, coord = r.EnumProjExtState(0, scr_cmdID, i)
		if retval --and title ~= 'NEXT_WND_LT' -- OLD, excluding 'NEXT_WND_LT' extended state since it doesn't store window data
		then
		local handle = r.BR_Win32_StringToHwnd(coord:match('.+,(.+)::')) -- find by the handle
			if handle == wnd and r.BR_Win32_IsWindow(handle) then -- will only be true if the window has never been closed otherwise the handle will become invalid
			return title, retval, coord
			end
		end
	i=i+1
	until not retval
end


function Find_Alternative_Window_Title(scr_cmdID, wnd, cur_title, ret, coord_init)
-- Find extended state data of minimized windows whose title has changed

-- FX browser window titles are 'Add FX to Track N' / 'Add FX to: Track N'
-- OR 'FX Browser' if last touched track wasn't found
-- if FX Browser window was opened from the View menu without any track being last touched
-- so it's not linked to a particular track, minimized and then track FX chain 'Add' button was clicked
-- the FX Browser window will become accosiated with such track which will result in its title change
-- therefore after minimizing it, restoration of the FX browser window based on the title won't be possible
-- due to title change, the message  'The window isn't resizable' will be displayed instead
-- if FX browser window is opened while there's last touched track it's title is 'Add FX to Track N'
-- but once track FX button of the same or another track is clicked a colon is added
-- and it turns into 'Add FX to: Track N' without track number change
-- when 'Add' button is clicked in the track FX chain the colon is removed
-- and if it is another track FX chain the number changes to reflect such track index
-- same applies to input FX, in this the FX window window title ends with '(input FX chain)' verbiage;
-- the colon transmigration does't apply to take FX chain;
-- when FX browser is focused on take FX chain, clicking checkmarked FX Browser item
-- in the View menu causes the FX Browser to switch focus to the take parent track
-- with title change to reflect that while the menu option remains checkmarked
-- FX Browser is closed only on the second click of the menu item, that is it's only
-- immediately closed if focused on a track FX chain

-- Will only work if the window wasn't closed and reopened,
-- if window has not been stored yet
local title, retval, coord = Get_Wnd_Title_By_Handle(scr_cmdID, wnd, cur_title, ret, coord_init)

	if title then return title, retval, coord end

-- title is stored as extended state key and in project ext state these are automatically capitalized
-- hence everything is capitalized for accurate evaluation

local t = {['ROUTING MATRIX']=0,['TRACK WIRING DIAGRAM']=0,
['TRACK GROUPING MATRIX']=0, ['REGION RENDER MATRIX']=0,
['FX BROWSER']=1, ['ADD FX TO']=1}
--local cur_title = cur_title:upper()

local alt_name = t[cur_title:upper()] or cur_title:match('Add FX to')
or cur_title:match('Media Item Properties:') or Get_Window_Parent_Object(cur_title) -- other windows with variable title

	if alt_name then
	local i = 0
		repeat
		local retval, title, coord = r.EnumProjExtState(0, scr_cmdID, i)
			if retval then
			local cur_title = cur_title:upper()
				if title ~= cur_title then
				local a = t[title] or t[title:match('ADD FX TO')] or title:match('MEDIA ITEM PROPERTIES:')
				or Get_Window_Parent_Object(title) or title:gsub('%[BYPASSED%]','') -- [BYPASSED] applies to track main FX chain window
				local b = t[cur_title] or t[cur_title:match('ADD FX TO')] or cur_title:match('MEDIA ITEM PROPERTIES:')
				or Get_Window_Parent_Object(cur_title) or cur_title:gsub('%[BYPASSED%]','')
					if a and a == b then -- preventing equality of falsehoods
					return title, 1, coord -- 1 is retval, matching value returned by GetProjExtState()
					end
				end
			end
		i=i+1
		until not retval
	end

return cur_title, ret, coord_init -- return original data if no match found

end



function Get_Window_Parent_Object(title)
-- used inside Find_Alternative_Window_Title() to identify window parent object
-- if the object label has changed, for restoration routine;
-- these windows title depends on the label of the object they're associated with,
-- track FX chain window title is also affected by the chain bypass status;

local pattern_t = {
'FX: Track %d+', --'FX: Item', --'FX: Item'..('.?'):rep(6), -- FX chain (excluding "FX: Item" take FX chain title patterns because in Find_Alternative_Window_Title() the 2nd pattern will make equality evaluation fail if take name was completely deleted while the 1st pattern will produce false positive at the minimization stage if there's at least one minimized take FX chain such that a not yet minimized take FX chain windows will be identified with a minimized one; in contrast to track FX chain window title where track index is an immutable part, in take FX chain window title there's no unique identifier to link it to any take in particular if take name is empty, therefore if several minimized take FX chain windows are associated with takes whose name changed while they were minimized there's no telling which one will be restored because any of them will match the pattern, same applies to take envelope manager)
'Add FX to:? Track %d+', 'Add FX to Item', -- FX browser
'Track %d+:', '(Track %d+) %-', --'Take:', --'Take:  %d+', -- global track Envelope manager (regarding excluded patterns see comment for FX chain above)
'Media Item Properties'} -- this value is redundant because media item properties window title is evaluated separately inside Find_Alternative_Window_Title()

	for k, v in ipairs(pattern_t) do
	local substr = title:lower():match(v:lower())
		if substr then
		return substr end
	end

return title
end


function Is_Floating_FX_Window(title)
return title:match('[2ACDJLPSTUVX]+i?:') or title:match(' %[%d+/%d+%]')
or title:match(' %- Item') or title:match(' %- Track %d+')
or title:match(' %- Master Track') or title:match(' %- Monitoring')
end


function Is_FX_Chain_Window(title)
return title:match('FX: Track') or title:match('FX: Item')
or title:match('FX: Master') or title:match('FX: Monitoring')
end


function ProjExtStates_2_Table(scr_cmdID)
-- used inside Shift_Minimized_Windows_Left()
-- project extended state keys are iterated over
-- in the alphabetic order
-- so if the order in which data was stored
-- is important, the keys should preferably
-- be numeric or the data must be collected
-- into a table and the table must be sorted
-- based on certain criteria
local i, t = 0, {}
	repeat
	local retval, title, coord = r.EnumProjExtState(0, scr_cmdID, i)
		if retval then
		t[#t+1] = {title=title,coord=coord}
		end
	i=i+1
	until not retval

-- sorting by the left x coordinate of the minimized window
	if #t > 0 then
	table.sort(t, function(a,b) return a.coord:match('::(%d+)') < b.coord:match('::(%d+)') end)
	end

return t

end



function Shift_Minimized_Windows_Left(scr_cmdID, new_lt)

local ext_state_t = ProjExtStates_2_Table(scr_cmdID)
local retval, main_l, main_t, main_r, main_b = r.BR_Win32_GetWindowRect(r.GetMainHwnd())
local new_lt = new_lt

	for k, ext_state in ipairs(ext_state_t) do
	local title, coord = ext_state.title, ext_state.coord
	local wnd = Find_Win(title) -- window will be found if open regardless of visibility
		if not wnd then -- minimized window name has changed
		wnd = r.BR_Win32_StringToHwnd(coord:match('.+,(.+)::')) -- find by the handle
		wnd = r.BR_Win32_IsWindow(wnd) and wnd -- will only be true if the window has never been closed otherwise the handle will become invalid
		end
		if wnd then
		local retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(wnd) -- get minimized window coordinates
			if lt >= new_lt then -- only if the minimized window is to the right of the restored one
			local w, h = rt-lt, b-t
			-- if fully minimized, restore the window regular minimized state to get its coordinates
			-- because minimized window coordinates and its fully minimized (collapsed) version coordinates
			-- are different, as if these were two separate types of window,
			-- so that when 'Restore' option of the fully minimized window is selected
			-- the window doesn't jump to its old location
			local minimized_fully = w == 160 and h == 24
				if minimized_fully then
				r.BR_Win32_ShowWindow(wnd, 1) -- 1 SW_NORMAL/SW_SHOWNORMAL, if fully minimized, restore the original dimensions applied with BR_Win32_SetWindowPos() before full minimization, because fully minimized window and a regular window are different entities and change in coordinates of one doesn't apply to the other
				retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(wnd) -- get minimized window coordinates
				end

			-- update coordinates of the window in its regular minimized state
			w, h = rt-lt, b-t
			r.BR_Win32_SetWindowPos(wnd, 0, new_lt, t, w, h, 0x0040) -- hWndInsertAfter is 0 HWND_TOP, place at top of the Z order, flags 0x0040 SWP_SHOWWINDOW Displays the window

			-- restore the fully minimized window state and update its coordinates so its shifted as well
			-- because regular and fully minimized windows seem to be different entities each with it own coordinates
			-- !!!!! sometimes Track Manager's fully minimized window won't shift it it's the last in the row
				if minimized_fully then
			-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
				r.BR_Win32_ShowWindow(wnd, 2) -- 2 SW_SHOWMINIMIZED, only leaves window title bar
				local retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(wnd) -- get fully minimized window coordinates
				r.BR_Win32_SetWindowPos(wnd, '', new_lt, main_b-46, rt-lt, b-t, 0x0040) -- x is new_lt, y is main_b-46 accounting for the bottom scrollbar, instead if calculating width/height 160/24 could used directly, 0x0040 SWP_SHOWWINDOW Displays the window
				end

			local i = 0
			coord = coord:gsub('%d+', function() i=i+1 if i==6 then return new_lt end end) -- update minimized window new left coordinate for re-applying with Re_Apply_Windows_Porps() if needed and to prevent triggering the re-applying condition after the window has been shifted because without update sthe actual and stored coordinate will differ
			r.SetProjExtState(0, scr_cmdID, title, coord)
			new_lt = new_lt + (minimized_fully and 160 or w) -- update for the next window in the next loop cycle
			end
		end
	end

end



function Re_Apply_Windows_Porps(scr_cmdID)

local ext_state_t = ProjExtStates_2_Table(scr_cmdID)
local resp

	if #ext_state_t > 0 then
	resp = r.MB('Click the button which corresponds to the desired outcome\n\n'
	..'Y E S  —  re-apply windows minimized size and coordinates\n\n'
	..'N O  —  restore windows original size and coordinates\n\n'
	..'The operation will succeed only if the window wasn\'t closed\n\n'
	..'and reopened, or if it was, its title didn\'t change.','PROMPT',3)
		if resp == 2 then return end -- cancelled
	else
	Error_Tooltip('\n\n no stored windows data \n\n', 1, 1) -- caps, spaced true
	return end

local re_apply, restore = resp == 6, resp == 7

local retval, main_l, main_t, main_r, main_b = r.BR_Win32_GetWindowRect(r.GetMainHwnd()) -- for re-applying minimized coordinates
local confirmed

	for i = #ext_state_t, 1, -1 do-- in reverse in case of restoration because extended states will be deleted in the process
	local title, coord = ext_state_t[i].title, ext_state_t[i].coord
	local wnd = Find_Win(title) -- window will be found if open regardless of visibility
		if not wnd then
		wnd = r.BR_Win32_StringToHwnd(coord:match('::.+,(%d+)')) -- find by the handle
		wnd = r.BR_Win32_IsWindow(wnd) and wnd -- will only be true if the window has never been closed otherwise the handle will become invalid
		end
		if wnd then
		local patt = restore and ('(%d+),?'):rep(4) or re_apply and '::'..('(%d+),?'):rep(4)
		local l, t, w, h = coord:match(patt)
		local retval, lt, top, rt, b = r.BR_Win32_GetWindowRect(wnd) -- get minimized window coordinates which are NOT fully minimized window coordinates, hence next condition
		local minimized_fully = rt-lt == 160 and b-top == 24
			if re_apply and (l+0~=lt or t+0~= top or w+0~=rt-lt or h+0~=b-top -- +0 converting string to numeral
			or minimized_fully ~= MINIMIZE_FULLY) -- after proj tabs switching Envelope Manager window keeps size but gets auto-closed and when re-opened doesn't maintain coordinates, FX chain window doesn't keep width, floating FX windows don't keep width and height, all other windows keep both coordinates and size in all cases
			or restore
			then
			confirmed = 1
			r.BR_Win32_ShowWindow(wnd, 1) -- 1 SW_NORMAL/SW_SHOWNORMAL, if fully minimized, restore the original minimized dimensions applied with BR_Win32_SetWindowPos(), because fully minimized window and a regular window are different entities and change in coordinates of one doesn't apply to the other
			r.BR_Win32_SetWindowPos(wnd, 0, l, t, w, h, 0x0040) -- hWndInsertAfter is 0 HWND_TOP, place at top of the Z order, flags 0x0040 SWP_SHOWWINDOW Displays the window
				if re_apply and (MINIMIZE_FULLY or minimized_fully) then
			-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
				r.BR_Win32_ShowWindow(wnd, 2) -- 2 SW_SHOWMINIMIZED
				-- adjust Y coordinate because by default the window is collapsed to the very bottom of REAPER main window
				r.BR_Win32_SetWindowPos(wnd, '', l, main_b-46, w, h, 0x0040) -- y coordinate is  main_b-46 accounting for the bottom scrollbar, 0x0040 SWP_SHOWWINDOW Displays the window
				elseif restore then
				r.SetProjExtState(0, scr_cmdID, title, '') -- clear extended state
				end
			end
		end
	end

	if confirmed then r.BR_Win32_SetFocus(r.GetMainHwnd())  -- set focus to the main window prevening minimizied window which was processed last from becoming immediately available for restoration because it may not be user's intention
	else
	local err = re_apply and (' '):rep(6)..'no minimized window size \n\n and coorindates were re-applied'
	or restore and 'no window original size\n\nand coorindates were restored'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	end

return confirmed

end



function Condition_Action_By_Armed_State(scr_cmdID, scr_section)
local cmd, section = r.GetArmedCommand() -- cmd is 0 when no armed action, empty string section is 'Main' section
local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
['MIDI Inline Editor']=32062,['Media Explorer']=32063}
	if cmd == scr_cmdID and (sect_t[section] == scr_section
	or sect_t[section:match('alt')] and scr_section == 0) then
	r.ArmCommand(0, section) -- 0 unarm all
	return true
	end
end



Error_Tooltip('') -- when executing the script from a toolbar the toolbar button tooltip (which is also a window) may interfere and end up intercepting cursor focus which was set to the target window before the click, so the script will affect the tooltip window instead of the target window, this function call clears any tooltips at the moment of script execution from a toolbar

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
or scr_name -- if an non-installed script is run via 'ReaScript: Run (last) ReaScript (EEL2 or lua)' actions get_action_context() won't return valid command ID, in which case fall back on the script full path
MINIMIZE_FULLY = #MINIMIZE_FULLY:gsub(' ','') > 0

	-- Prompt to re-apply after project load or project tabs switch which result in window width reset;
	-- tabs switching results in reset of FX chain window width
	-- and in reset of floating FX windows width and height
	-- Envelope manager window doesn't stay open when tabs are switched
	-- and when re-opened doesn't maintain the minimized window coordinates, only the size
	if Condition_Action_By_Armed_State(cmd_ID, sect_ID) then
	Re_Apply_Windows_Porps(named_ID) -- to minimized windows which were closed and reopened and whose title has changed in the interim the size won't be re-applied because finding they by their new title isn't trivial without them having focus
	return r.defer(no_undo) end -- aborting if re-applied to prevent re-applying and continuing the routine towards restoration stage in one go


local wnd = r.BR_Win32_GetFocus and r.BR_Win32_GetFocus()
local retval, title = r.BR_Win32_GetWindowText(wnd)
	if title:lower():match('toolbar') or title:match('Run') then -- either toolbar button or Action list 'Run' button click
	wnd = title:match('Run') and Find_Win('Actions') or wnd
	wnd = r.BR_Win32_GetWindow(wnd, 2) -- 2 GW_HWNDNEXT, a window directly below the toolbar or the Actions window in the Z order
	end


local parent_wnd = wnd and Get_Top_Parent_Window(wnd) -- get the actual application window in case its child window is focused, one instance of BR_Win32_GetParent() function may not suffice
wnd = parent_wnd and parent_wnd ~= r.GetMainHwnd() and parent_wnd or wnd
local retval, title = r.BR_Win32_GetWindowText(wnd)

	if title:match('Actions') then -- the script entry in the Action list was clicked directly
	-- there're two windows titled 'Actions',
	-- so first get the 2nd 'Actions' window directly under the first user facing one in the Z order
	-- and then get a window below this 2nd 'Actions' window in the Z order
	wnd = r.BR_Win32_GetWindow(wnd, 2) -- 2 GW_HWNDNEXT, window below the Actions windiw in the Z order
	wnd = r.BR_Win32_GetWindow(wnd, 2)
--	wnd = r.BR_Win32_GetParent(wnd) -- also works instead of the 2nd instance of BR_Win32_GetWindow(), not sure why
	end

local retval, title = r.BR_Win32_GetWindowText(wnd)

local err = not r.BR_Win32_GetFocus and 'the sws/s&m extension\n\nisn\'t installed'
or not wnd and 'no focused window' or wnd == r.GetMainHwnd() and 'the main window is in focus' -- these seem to never be true, leaving just in case
or ( #title == 0 or title:match('REAPER') or title:lower():match('toolbar')
or not title:match('%u') or Is_Window_Docked(wnd)) and 'no valid focused window' --'last focused application \n\n   window was not found'
or title:match('Routing for') and MINIMIZE_FULLY and r.GetProjExtState(0, named_ID, title) == 0 and 'window full minimization \n\n\tis not supported' -- because fully minimized routing window cannot be placed into focus like all fully minimized windows, without restoring them to their regular minimized dimensions, but it also cannot be restored to its regular minimized dimensions // conditioning by existence of extended state to be able to restore an already minimized window instead of throwing the error message

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local handle = r.BR_Win32_HwndToString(wnd) -- storing window handle as a string to avoid searching windows by title inside Shift_Minimized_Windows_Left() because title is unreliable for windows with variable title like FX Browser, 'Routing/Wiring/Track groiping etc.', floating FX windows, FX chain window if bypassed, global track Envelope Manager, Media Item Properties window, which can change in the intrerim; BUT AFTER WINDOW IS CLOSED ITS HANDLE BECOMES INVALID EVEN THOUGH THE ORGINAL ONE WILL STILL BE RETRIEAVBLE FROM THE STRING; as far as floating FX windows are concerned change FX instance position within the FX chain which affects the window title properties, i.e. [1/2] where the 1st number is index in the chainand the 2nd number is the total of FX in the chain, doesn't affect their accessibility for restoration because until the plugin is removed from the FX chain its window maintains valid handle by which it can be identified after title change
local ret, coord = r.GetProjExtState(0, named_ID, title)

	if ret == 0 then -- to accommodate windows with variable titles in case they're not found in extended state which is based on title as the key because the title has changed in the meantime // will run at minimization stage because at this stage extended data are absent and at restoration stage if the data associated with a particular window name wasn't found
	title, ret, coord = Find_Alternative_Window_Title(named_ID, wnd, title, ret, coord) -- if window has not been stored yet, returns the above title, ret, coord values
	end


-- MAIN ROUTINE

	if ret == 0 then -- minimize

	-- if the label of the object (track/take/item) the window is associated with
	-- is long, it won't be possible to sufficiently
	-- minimize the window width, so only minimize as much as needed
	-- to leave visible the part which shows their
	-- association with the object, where appropriate

	local length = #title:gsub('[\128-\191]','') -- accounting for non-ASCII chars
	local max_width = Is_FX_Chain_Window(title) and 400 -- if FX chain, the minimum width is 400 px regardless of the title length because the window cannot be minimized any furter
	or Is_Floating_FX_Window(title) and 11*14 -- floating FX window, pruning window titles which depend on the name of the plugin instance to allow sufficent width minimization when the plugin name displayed in the window title bar is long but ensuring that plugin name remains visible; upper case W width in window titles in all default themes is 11 px so providing for the length equal to 14 Ws which seems sufficient
	or length*11 -- in other windows incliding SWS extension where the title may be preceded with an icon, taking a bit of leeway of 11 px per character which is W character width, because it's too laborious to accurately count the title length in pixels, a table with px values per character in both registers would have to be used

	local retval, main_l, main_t, main_r, main_b = r.BR_Win32_GetWindowRect(r.GetMainHwnd())
	main_l = main_l+3 -- accounding for the window left edge
	local retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(wnd)
	local val = lt..','..t..','..(rt-lt)..','..(b-t)..','..handle -- val to be stored as ext state below, handle is evaluated inside Shift_Minimized_Windows_Left()

	-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos
	-- flags: 0x0004 SWP_NOZORDER retains the current Z order (ignores the hWndInsertAfter arg (2nd))
	-- but when another window is opened after the focused one is minimized the new one gets
	-- Z order priority and if the minimized window is dragged with mouse it goes behind the newly
	-- opened window, so not very intuitive
	-- 0x0200 SWP_NOREPOSITION or SWP_NOOWNERZORDER does not change the owner window's position in the Z order
	-- ensures that whatever window which is now in focus has Z order priority as is usually the case;
	-- 1. First minimize and get the resulting height to then calculate by how much it must be moved to bottom of the main window
	-- because Y coordinate refers to the top edge, and setting Y to main_b will result in the window being hidden
	-- outside of the main window at the bottom,
	-- usually they won't get minimized to 30 x 30 size unless it's an FX floating window
	-- which can be shrunk down to 24 x 28 px
	r.BR_Win32_SetWindowPos(wnd, '', main_l, t, max_width, 30, 0x0200) -- hWndInsertAfter is empty srting, i.e. ommitted, x is main_l, y top, width is max_width, height is 30 which ensures that at least the title bar remains wisible
	-- 2. Get height of the minimized window at its current Y coordinate
	local retval, left, top, right, bottom = r.BR_Win32_GetWindowRect(wnd)
	local height = bottom-top
	local width = right-left -- actual width after minimization which can be greater than 30 px

	local next_wnd_lt = Get_Minimized_Wnd_Righmost_X_Coord(named_ID, main_l) -- this method is more consistent with the design than storage of the coordinate as extended state, because it ensures that a window just minimized is placed next to the last minimized window in the row and to its right, whereas the stored rightmost coordinate won't necessarily refer to the last minimized window right X coordinate if the last restored window was manually moved away from preceding minimized window, in which case the coordinate stored as extended state inside Shift_Minimized_Windows_Left() will refer to the left X coordinate of such last restored window therefore the new minimized window will be removed from the last minimized window by the gap which existed between the last restored window and other minimized windows to its left

	-- prevent adding windows to the row if they end up sticking by more than 1/3
	-- outside of the main window on the right
	err = next_wnd_lt + width > main_r-17 and 'no avalable space left' -- right-left is the minimized window width, 17 is the main window vertical scroll bar width
	or height == b-t and width == rt-lt and not MINIMIZE_FULLY and 'the window can\'t be minimized \n\n     or it\'s name has changed'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
		-- restore the window original size
		r.BR_Win32_SetWindowPos(wnd, 0, lt, t, rt-lt, b-t, 0x0040) -- hWndInsertAfter is 0 HWND_TOP, place at top of the Z order, flags 0x0040 SWP_SHOWWINDOW Displays the window
		return r.defer(no_undo) end

	-- 3. Move to bottom of the main window
	r.BR_Win32_SetWindowPos(wnd, '', next_wnd_lt, main_b-22-height, width, 30, 0x0200) -- hWndInsertAfter is empty srting, i.e. ommitted, x left, y main_b-22-height, 22 is accounting for the height of the bottom scrollbar so that the window is placed above it, width is width, height is 30 which ensures that at least the window title bar remains wisible

	local retval, left, top, right, bottom = r.BR_Win32_GetWindowRect(wnd) -- get minimized window final dimensions for storage so that they can be re-applied after project load or switching project tabs because they get reset in these cases
	val = val..'::'..next_wnd_lt..','..top..','..(right-left)..','..(bottom-top)
	r.SetProjExtState(0, named_ID, title, val) -- store original window coordinates // STORAGE UNDER TITLE AS THE KEY ALLOWS RESTORING WINDOWS AFTER CLOSING AND REOPENING THEM WHILE THEY'RE MINIMIZED AS LONG AS THE TITLE HASN'T CHANGED OR CAN BE FIGURED OUT, STORAGE UNDER STRINGIFIED HANDLE IS UNRELIABLE BECAUSE IT BECOMES INVALID WHEN A WINDOW IS CLOSED (DESTROYED)

		if MINIMIZE_FULLY then
		-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
		r.BR_Win32_ShowWindow(wnd, 2) -- 2 SW_SHOWMINIMIZED, only leaves window title bar, but only stays minimized as long as REAPER main window wasn't minimized and maximized back in which case the dimensions set by SetWindowPos() get retored, if other application windows outide of REAPER were brought into focus like for example by clicking their tabs in the taskbar, the minimized state of REAPER windows won't be affected; when window fully minimized state is reset after if was moved on the screen to another location its non-fully minimized location is reset as well and there's no way to store and restore fully minimized window latest coordinates with the available APIs
		-- adjust Y coordinate because by default the window is collapsed to the very bottom of REAPER main window
		r.BR_Win32_SetWindowPos(wnd, '', next_wnd_lt, main_b-46, right-left, bottom-top, 0x0040) -- y coordinate is main_b-46 accounting for the bottom scrollbar, 0x0040 SWP_SHOWWINDOW Displays the window
		end

	else -- restore
	local retval, left, top, right, bottom = r.BR_Win32_GetWindowRect(wnd) -- collect minimized coordinates to pass to Shift_Minimized_Windows_Left() below

	local lt,t,w,h = coord:match(('(%d+),'):rep(4)) -- get stored original coordinates for restoration

	r.BR_Win32_ShowWindow(wnd, 1) -- 1 SW_NORMAL/SW_SHOWNORMAL, if fully minimized, restore the original dimensions applied with BR_Win32_SetWindowPos() before full minimization, without this the window original properties won't be restored; relevant if the window was minimized and immediately restored which is only possible if the script is run from the Action list; that's because fully minimized window and a regular window are different entities and change in coordinates of one doesn't apply to the other
	r.BR_Win32_SetWindowPos(wnd, 0, lt, t, w, h, 0x0040) -- hWndInsertAfter is 0 HWND_TOP, place at top of the Z order, flags 0x0040 SWP_SHOWWINDOW Displays the window
	r.SetProjExtState(0, named_ID, title, '') -- clear extended data
	Shift_Minimized_Windows_Left(named_ID, left) -- to fill up the space left by the restored window // minimized windows which were closed and reopened and whose title has changed in the interim won't be shifted because finding they by their new title isn't trivial without them having focus // SOMETIMES FULLY MINIMIZED WINDOW MIGHT FAIL TO SHIFT, WASN'T ABLE TO FIND PATTERN OR CAUSE OF THE USSUE, DEBUGGING DOESN'T SHOW ANYTHING ODD
	end


do return r.defer(no_undo) end












