--[[
ReaScript name: BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog: 1.4 #Fixed track notes evaluation within the Notes window for SWS builds 
		where BR_Win32_GetWindowText() function's buffer size is 1 kb 
	   1.3 	#Added HIGHLIGHT_SEGMENT_ENTRY settings
	   1.2 	#Added scrolling of the Notes window to the line contaning 
	       	the time stamp of the marker at the edit cursor
		#Improved accuracy of the error message when there's 
	 	no segment marker at the edit or play cursor
	 	#Improved detection of Notes track absence
		#Updated script name
	    1.1 #Added character escaping to NOTES_TRACK_NAME setting evaluation 
		to prevent errors caused unascaped characters
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M mandatory, js_ReaScriptAPI recommended
About:	The script is part of the Transcribing A workflow set of scripts
	alongside  
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua  
	BuyOne_Transcribing A - Go to segment marker.lua
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua  
	BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua
	
	It's a kind of the opposite of the script  
	'BuyOne_Transcribing A - Go to segment marker.lua'
	
	Since the transcript can be divided between several tracks
	due to SWS Notes size limit per object, this script allows
	selecting the Notes track in which the time stamp of the
	marker closest to the edit cursor on the left or currently 
	at the edit cursor is found which simplifies the workflow.
	When there's enough scrolling space the Notes window will 
	be scrolled to the line which contains the time stamp 
	matching the marker at the cursor.
	
	When REAPER is in play mode the reference position is taken
	from the play cursor, otherwise from the edit cursor.
	
	If you find it more convenient to point at a marker or a space
	between them with the mouse cursor, the following custom action
	can be used being mapped to a shortcut:
	
	Custom: Transcribing - Select Notes track based on marker at edit cursor  
		View: Move edit cursor to mouse cursor  
		BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
		
	
	If the Notes window is closed the script will open it.
		
	The script doesn't create an undo point.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of track(s)
-- where Notes with the transcript are stored;
-- must match the same setting in the script
-- 'BuyOne_Transcribing A - Create and manage segments (MAIN).lua'
-- CHANGING THIS SETTING MIDPROJECT IS NOT RECOMMENDED
-- BECAUSE SCRIPT ACCESS TO THE NOTES TRACKS WILL BE LOST
NOTES_TRACK_NAME = "TRANSCRIPT"

-- Enable by inserting any alphanumeric character
-- between the quotes to have the segment entry in the Notes
-- window highlighted when the Notes window is scrolled 
-- to the entry containing segment marker time stamp
-- so it stands out;
-- THIS HOWEVER MAKES THE NOTES WINDOW FOCUSED FOR KEYBOARD INPUT
-- therefore any keyboard shortcut you might use immediately
-- afterwards will land inside the Notes window as text, unless
-- it was set to be global in the action shortcut dialogue,
-- and hitting Delete will delete the highlighted text
HIGHLIGHT_SEGMENT_ENTRY = ""

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



function Find_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search windows with BR_Win32_FindWindowEx(), including docked
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
local wnd = Find_Win(wnd_name)

	if wnd then return wnd end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker' // non-toolbar windows can be attached to a floating toolbar docker as well
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search for a floating docker with one attached window
local docker = Find_Win(wnd_name..' (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd and (r.JS_Window_IsVisible and r.JS_Window_IsVisible(wnd) or dock) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- search toolbar docker with multiple attached windows which can house regular windows
docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker', non-toolbar windows can be attached to a floating toolbar docker as well
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search floating docker with multiple attached windows which can house toolbars
docker = Find_Win('Docker') -- when a docker attached to the main window is detached from it by toggling 'Attach docker to the main window' and there're several windows in it, the floating docker title is 'Docker'
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search docks attached to the main window
	if dock and not want_main_children or want_main_children then -- windows can be found in closed dockers hence toggle state evaluation
	local main = r.GetMainHwnd() -- the name of the dock window is 'REAPER_dock' of which there're 15 all being children of the main window and siblings of each other, attached windows are dock children and are siblings of each other
	local child = r.BR_Win32_GetWindow(main, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
	return get_wnd_siblings(child, 2, wnd_name)
	end

end



function Scroll_SWS_Notes_Window(parent_wnd, str, tr)
-- parent_wnd is window titled 'Notes' or 'Notes (docked)' found with Find_Window_SWS() function
-- str is string to be found in the Notes
-- tr is selected track
-- no scrolling will occur if the track notes aren't found in the Notes window

	local function string_exists(txt, str)
		for line in txt:gmatch('[^\n]+') do
		-- str is escaped to cover all cases
			if line:match(Esc(str)) then return txt end
		end
	end

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child

	if not child then return end

-- search str in all children of parent_wnd
local i, notes = 1
	repeat
		if child then
		local ret, txt = r.BR_Win32_GetWindowText(child) -- before SWS build 2.14.0.3 was limited to 1kb therefore couldn't return the entire Track Notes content https://github.com/reaper-oss/sws/issues/1896
		-- overcoming BR_Win32_GetWindowText() limitation by falling back on alternatives	
		notes = ret and string_exists(txt, str) or r.JS_Window_GetTitle and string_exists(r.JS_Window_GetTitle(child), str)
			-- this is method of finding str in Track Notes for SWS extention builds
			-- where BR_Win32_GetWindowText() is limited to 1kb
			-- simple fall back on r.NF_GetSWSTrackNotes(tr) will produce false positives
			-- because it will return notes where the window won't
			-- ONLY RELEVANT FOR TRACK NOTES
			if not notes then
			local notes_tmp = r.NF_GetSWSTrackNotes(tr)
				if #notes_tmp:gsub('[%c%s]','') > 0 then
				local test_str = 'ISTRACKNOTES' -- the test string is initialized without line break char to be able to successfully find it in the window text because search with the line break char will fail due to carriage return \r being added to the end of the line and thus preceding the line break, i.e. 'ISTRACKNOTES\r\n'
				r.NF_SetSWSTrackNotes(tr, test_str..'\n'..notes_tmp) -- add a test string to start of the notes so it's sure to be included in the string returned by the limited BR_Win32_GetWindowText() version
				local ret, txt = r.BR_Win32_GetWindowText(child)
					if ret and txt:match(test_str) and string_exists(notes_tmp, str) then
					notes = notes_tmp
					end
				r.NF_SetSWSTrackNotes(tr, notes_tmp) -- restore original notes without the test string
				end
			end
			if notes then break end
		end
	-- get for evaluation in the next cycle if valid
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child

	--	if string_exists(txt, str) then
	if notes then
	local SendMsg = r.BR_Win32_SendMessage
	local line_cnt, notes = 0, notes:sub(-1) ~= '\n' and notes..'\n' or notes -- ensures that the last line is captured with gmatch search
	local target_line
		for line in notes:gmatch('(.-)\n') do	-- accounting for empty lines because all must be counted
			if line:match(str) then 
			target_line = line
			break end -- stop counting because that's the line which should be reached by scrolling but not scrolled past; to cover all cases str must be escaped with Esc() function but here it's not necessary
		line_cnt = line_cnt+1
		end
	--	r.PreventUIRefresh(1) doesn't affect windows
	--	set scrollbar to top to procede from there on down by lines
	r.BR_Win32_SendMessage(child, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
		for i=1, line_cnt do
		r.BR_Win32_SendMessage(child, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, lParam 0, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll but in fact the message code must be passed here as lParam while wParam must be 0, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage
		end
		if HIGHLIGHT_SEGMENT_ENTRY then
		r.BR_Win32_SetFocus(child) -- window must be focused for selection to work
		notes = notes:gsub('[\128-\191]','') -- remove extra (continuation or trailing) bytes in case text is Unicode so string.find counts characters accurately
		-- THE FOLLOWING line_st VALUE IS ONLY ACCURATE BECAUSE notes VAR STEMS FROM BR_Win32_GetWindowText()
		-- or JS_Window_GetTitle() WHICH RETURN TEXT FROM WINDOW AND IN THE WINDOW EACH LINE IS TERMINATED 
		-- WITH CARRIAGE RETURN \r WHICH IS COUNTED AS WELL. THIS WOULDN'T HAVE BEEN THE CASE IF notes VAR STEMMED
		-- FROM NF_GetSWSTrackNotes()
		local line_st = notes:find(Esc('\n'..target_line)) or 0 -- if not the first line, new line char must be taken into account for start value to refer to the visible start of the line otherwise the start will be offset by 1
		local line_len = #target_line:match('(.+:%d+.%d+)') -- in segment entry only heghlight the time stamp(s)
		-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
		SendMsg(child, 0x00B1, line_st, line_st+line_len) -- EM_SETSEL 0x00B1, wParam line_st, lParam line_st+line_len
		--	r.BR_Win32_SetFocus(r.GetMainHwnd()) -- removing focus clears selection
		end
	end

end



function Get_Segment_Mrkr_At_Edit_Play_Curs()

local play_pos, curs_pos, plays = r.GetPlayPosition(), r.GetCursorPosition(), r.GetPlayState()&1 == 1
local mrkr_idx = plays and r.GetLastMarkerAndCurRegion(0, play_pos)
or r.GetLastMarkerAndCurRegion(0, curs_pos)

	if mrkr_idx > -1 then -- there're markers left of the cursor
	local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(mrkr_idx)
		if r.parse_timestr(name) ~= 0 or name == '00:00:00.000' then
		return name
		end
	end

end


function Get_Notes_Track(mrkr_name, NOTES_TRACK_NAME)
-- the function accounts for missing tracks
-- in which case the 'not found' message is displayed

local tr_t = {}

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index, st_stamp, end_stamp = data:match('^(%d+) (.-) (.*)')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index) then
		tr_t[#tr_t+1] = {tr=tr, name=name, idx=index, st=st_stamp, fin=end_stamp}
		end
	end

	if #tr_t == 0 then return end
	
-- sort the table by integer in the track extended state
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

	local function time_stamp_exists(tr, stamp)
	local notes = r.NF_GetSWSTrackNotes(tr)
		for line in notes:gmatch('[^\n].*') do
			if line:match(stamp) then return
			true
			end
		end
	end

local parse = r.parse_timestr

	for k, props in ipairs(tr_t) do
	local st_stamp, end_stamp = props.st, props.fin
		if not st_stamp then -- in case the time stamps aren't stored in the track extended state, look in the notes
		local notes = r.NF_GetSWSTrackNotes(props.tr)
		-- %d%d is used because otherwise only the second digit if hours is captured
		st_stamp = notes:match('.-(%d%d:%d+:%d+%.%d+)') -- first segment entry start time stamp
		end_stamp = notes:match('.+(%d%d:%d+:%d+%.%d+)') -- last segment entry end time stamp or its start if end time stamp is absent
		end
		if st_stamp and parse(st_stamp) > parse(mrkr_name) then
		local tr = k > 1 and tr_t[k-1].tr -- previous track
			if tr and time_stamp_exists(tr, st_stamp) then return tr end
		elseif end_stamp and parse(end_stamp) >= parse(mrkr_name) then
		return props.tr -- current track
		end
	end


-- if there's only 1 Notes track
local tr = tr_t[1].tr
	if tr then
	local st_stamp, end_stamp = tr_t[1].st, tr_t[1].fin
		if not st_stamp then -- in case the time stamps aren't stored in the track extended state, look in the notes
		local notes = r.NF_GetSWSTrackNotes(tr)
		-- %d%d is used because otherwise only the second digit if hours is captured
		st_stamp = notes:match('.-(%d%d:%d+:%d+%.%d+)') -- first segment entry start time stamp
		end_stamp = notes:match('.+(%d%d:%d+:%d+%.%d+)') -- last segment entry end time stamp or its start if end time stamp is absent
		end
		if st_stamp and end_stamp
		and parse(mrkr_name) >= parse(st_stamp)
		and parse(mrkr_name) <= parse(end_stamp)
		then return tr
		end
	end

end



function SCROLL()
	if r.time_precise() - time_init > 0.1 then -- 0.03 also works but leaving 100 ms for a leeway
	Scroll_SWS_Notes_Window(a, b, c) -- a, b, c are notes_wnd, mrkr_name, tr
	return end
r.defer(SCROLL)
end



function Open_SWS_Notes_Window()
local act = r.Main_OnCommand
local cmd_ID = r.NamedCommandLookup('_S&M_TRACKNOTES') -- SWS/S&M: Open/close Notes window (track notes)
-- When in the Notes window other Notes source section is open the action will switch it to tracks
-- if it's track Notes section is already open the action will close the window;
-- evaluating visibility of a particular Notes section using actions isn't possible
-- because the toggle state of all section actions is ON as long as the Notes window is open
	if r.GetToggleCommandStateEx(0, cmd_ID) == 0 then
	act(cmd_ID,0) -- open
	end
end


NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local mrkr_name = Get_Segment_Mrkr_At_Edit_Play_Curs()

local cursor = r.GetPlayState()&1 == 1 and 'play' or 'edit'
local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'
or not mrkr_name and 'no segment marker \n\n at the '..cursor..' cursor'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return end

local sel_tr = r.GetSelectedTrack(0,0) -- Track Notes only display notes for the 1st selected track
-- track with which the Notes containing the marker name as a segment time stamp are associated
local tr = Get_Notes_Track(mrkr_name, NOTES_TRACK_NAME)

	if not tr then
	Error_Tooltip("\n\n relevant notes track \n\n\twasn't found \n\n", 1, 1) -- caps, spaced true
	return end

r.SetOnlyTrackSelected(tr)
r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
Open_SWS_Notes_Window()

local notes_wnd = Find_Window_SWS('Notes', want_main_children) -- want_main_children nil

HIGHLIGHT_SEGMENT_ENTRY = #HIGHLIGHT_SEGMENT_ENTRY:gsub(' ','') > 0

	if tr == sel_tr then -- same track, the window is already loaded so can respond to the scroll message
	Scroll_SWS_Notes_Window(notes_wnd, mrkr_name, tr)
	else -- track selection has changed
	-- deferred function must be used to wait until the window is fully loaded
	-- because when changing track selection window update takes time
	-- and the script fails to make the window scroll due to running through faster
	-- that's unlike in BuyOne_Transcribing A - Create and manage segments (MAIN).lua
	-- where execution of Scroll_SWS_Notes_Window() doesn't need to be delayed with a defer loop
	-- probably because that script runs longer giving enough time for the window to load
	-- and be successfully affected by scroll position change
	a, b, c, time_init = notes_wnd, mrkr_name, tr, r.time_precise() -- assign as globals to be used in SCROLL() function
	SCROLL()
	end

do return r.defer(no_undo) end





