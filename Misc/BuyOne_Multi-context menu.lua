--[[
ReaScript name: BuyOne_Multi-context menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script allows accessing and using different menus, constructed 
	by the user within this script, from the same menu interface, depending
	on the mouse cursor context. The context is activated by pointing
	the mouse cursor at a certain area (see USER SETTINGS for details).
	For this reason the script is mainly designed to be executed with
	a shortcut so that the mouse cursor is not engaged.  
	Still it can be run from another menu or from a toolbar button, however
	in this case its behavior slightly differs because no valid context can
	be detected. So on the very first run it will load the menu layer for 
	the context which is active first in the list of contexts of the 
	USER SETTINGS. After the first run it will store the currently displayed
	layer and will reload it on the next run. Layers can be switched at will
	via the layer submenu. Thus in this scenario the script behaves exactly
	like BuyOne_Multi-layer menu.lua.  
	The last displayed layer will also be reloaded when the script is run
	with a shortcut without valid layer having been detected.  
	During the session the script keeps track of the last used menu layer and
	loads it when no valid context is detected, but in each new session the 
	default layer to be loaded when there's no valid context is always the 
	first one active in the USER SETTINGS.
	
	
	## M E N U  C O N S T R U C T I O N  G U I D E
	
	▒ MENU ITEMS

	The format of a menu item is as follows:
	
	[tab space][action/script command ID/function name][single space][menu item label]

	To be recognized all user functions must be suffixed with double parenthesis
	in the menu and be global in the script, local functions won't be recognized 
	even with the suffix, e.g.:

	12345 My menu item <---- REAPER action
	My_Function() My function menu label <---- User function

	Since the script doesn't create undo points on its own make sure that
	your functions are configured to create their own undo points if necessary.
	For ease of organization it's recommended to place all your user functions
	in the USER FUNCTIONS section of this script but in any event it's not 
	recommended placing them after the MAIN ROUTINE line of the script.

	To add a separator after a menu item append a pipe character '|' to it, 
	to thicken the separator add several of them, e.g.:

	12345 My menu item|
	6789 My menu item|||


	▒ NESTED MENUS (SUBMENUS)

	Submenu items must be indented by 1 tab space relative to the menu items
	of am immediately preceding higher level. That's submenu depth. More than 
	1 tab space may also work but it will complicate things and is likely to 
	break the menu structure if the depth isn't maintained consistently. 	
	A list of submenu items must be preceded with the submenu title which will 
	function as a point of access to the submenu from a higher level menu. 
	The depth (indentation) of a submenu title must be the same as that of the 
	menu level immediately preceding the submenu. A submenu title format isn't
	prescribed because it's not designed to trigger actions, e.g.

	12345 My menu item 1 <--------- Top level
	My submenu TITLE <--------- Top level
		6789 My submenu item 1 <--------- 2nd level
		My sub-submenu TITLE <--------- 2nd level
			9876 My sub-submenu item 1 <--------- 3d level
		9876 My submenu item 2 <--------- 2nd level
	5431 My menu item 2 <--------- Top level

	If a submenu isn't explicitly preceded with a title, the menu item 
	immediately preceding the submenu will be used instead because its depth 
	is 1 tab space smaller than than of the submenu, which isn't something 
	you'd want, e.g.:
	
	12345 My menu item 1 <--------- A top level item turned title of the next submenu
						<---------  No title
		6789 My submenu item 1 <--------- 2nd level item turned title of the next submenu
						<---------  No title
			9876 My sub-submenu item 1 <--------- 3d level
		9876 My submenu item 2 <--------- 2nd level
	5431 My menu item 2 <--------- Top level
	
	
	The menu can start off with a submenu (see below).

	The very first menu item is considered a top level item regardless of its 
	indentation from the left edge of the page and its depth considered 
	to be the smallest, all other levels will be processed relative to it. 
	The first menu item whose identation is smaller than that of the top level 
	sets the new top level depth and all subsequent items will be processed 
	relative to it, e.g:

		My submenu 1 TITLE <--------- Top level
			12345 My submenu 1 item 1 <--------- 2nd level
		6789 My top menu item 1 <--------- Top level
		My submenu 2 TITLE <--------- Top level
			9876 My submenu 2 item 1 <--------- 2nd level
	9876 My top menu item 2 <--------- Item at tew top level depth
	My submenu 3 TITLE <--------- Menu title at new top level depth
		5431 My submenu 3 item 2 <--------- A submenu relative to the new top level depth
	6941 My top menu item 3 <--------- Item at tew top level depth

	To add a separator after a nested menu (submenu) title append a pipe 
	character '|' to the last item in the submenu, e.g.:

	12345 My menu item 1
	My submenu TITLE
		6789 My submenu item| <--- The separator will follow 'My submenu TITLE' in the actual menu
	5431 My menu item 2

	▒ MENU LAYERS

	A menu layer is a separate full-fledged menu which in the main menu
	can be accessed from the list of layers or with next/previous 
	navigation menu items.

	To define a menu layer precede the list of menu items with the menu 
	layer header enclosed within square brackets, e.g.:

	[My menu layer 1]

	12345 My menu item 1
	My submenu TITLE
		6789 My submenu item|
	543121 My menu item 2
	
	The menu layer header format effectively means that menu item labels
	should not contain square brackets lest they're mistaken for layer
	header.
	
	The entire menu list must be either preceded by one layer header or
	not contain any layer headers at all. Presence of layer headers further
	down the list without there being one at the very beginning will result
	in a script error. 
	The error may also be thrown if a layer header of the last used layer
	was removed from the list between script runs which is a fairly unlikely
	scenario.
	
	▒ MISCELLANEOUS

	Empty lines in the menu list are allowed, they won't be converted into 
	menu items but can help to visually organize the list.

	Don't precede menu item labels with the following characters: <,>,|,#,! 
	because these reserved for menu formatting and their presence is likely 
	to break the menu structure in the process of the menu list conversion 
	into the actual menu. Ampersand '&' character isn't displayed in the menu 
	because it can be used as a quick access shortcut to activate a menu item 
	from the computer keyboard, e.g.
	
	12345 &My menu item 1 <----- Can be activated by pressing 'm' on the keyboard
	6789 My men&u item 2 <----- Can be activated by pressing 'u' on the keyboard
	
	Only one such quick access shortcut is supported per menu item.

	Toggle state is only reflected for actions in the same context as the one
	the script is run under. If run from the Main section MIDI Editor toggle 
	states won't be indicated and vice versa.

	Compose your multi-layer menu structure between the double square brackets 
	of MULTY_LAYER_MENU variable below.

	At the bottom of this script there's a simple double-layer example menu
	which you can insert inside MULTY_LAYER_MENU section to see how it works.

]]

-----------------------------------------------------------------------------
------------------------------ USER FUNCTIONS -------------------------------
-----------------------------------------------------------------------------

function test()
reaper.MB('TEST', 'TEST',0)
end

-----------------------------------------------------------------------------
-------------------------- END OF USER FUNCTIONS ----------------------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the title of the menu layer
-- from MULTY_LAYER_MENU setting below which you wish 
-- to open by default when the context reflected in the 
-- name of the context setting is active;
-- the layer title can be either enclosed within 
-- square brackets or not;
-- the same layer can of course can be associated 
-- with more than one context;
-- if a context setting is empty the menu won't open 
-- when the corresponding context is active

-- Contexts supported since build 6.36: MCP, TRANSPORT

TCP = ""
MCP = ""

-- Valid over FX windows in Arrange and FX slots in the Mixers
FX = ""

-- Item context is valid for single take items
ITEM = ""
-- Take context is valid for multi-take items
TAKE = ""

-- Track envelope context is valid when the mouse cursor 
-- hovers over the envelope within Arrange
-- Take envelope context is a click context,
-- only active if take envelope is selected
-- while the mouse cursor hovers over the take
ENVELOPE = ""

-- Arrange doesn't include items
ARRANGE = ""
TRANSPORT = ""

-- These contexts are only valid if the script is run
-- from the MIDI Editor section of the Action list,
-- that is when the MIDI Editor is in use;
-- they're click contexts, meaning they're only
-- activated by a mouse click, hovering the mouse cursor 
-- is not sufficient
MIDI_PIANO_ROLL = ""
MIDI_CC = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------------------------------- USER MENU ----------------------------------
-----------------------------------------------------------------------------

MULTY_LAYER_MENU = [[

-- REPLACE THIS LINE WITH YOUR MENU
	
]]

-----------------------------------------------------------------------------
---------------------------- END OF USER MENU -------------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Parse_Menu_Structure(str, sectionID)

-- parse menu list, breaking up into layers
local t, layer_t = {}
	for line in str:gmatch('[^\n\r]+') do
		if line and #line:gsub('[\t%s]','') > 0 then -- ignore empty lines
		local layer = line:match('.*(%[.+%])') -- isolate layer title in case it's preceded by (tab) spaces etc.
			if layer then
			t[#t+1] = {[layer] = {}}
			layer_t = t[#t][layer] -- for simplicity, to be used further
			else
				if layer_t then
				layer_t[#layer_t+1] = line
				else -- no layer header	to begin with
				t[#t+1] = line
				end
			end
		end
	end


-- construct menu, store actions and layer titles
local menu_t, act_t, layer_titles_t = {}, {}, {}

	local function construct_OLD()
	local depth = 0
		for i, line in ipairs(t) do
		local line, cur_depth = line:gsub('[\t]','')
		line = line:match('^%s*(.+[%w%p])')
			if cur_depth > depth then -- first line of a summenu
			menu_t[#menu_t+1] = '>'..line..'|'
			depth = cur_depth
			elseif cur_depth < depth then -- first line of a higher level menu after last submenu has been exited
			-- close previous submenu
			menu_t[#menu_t] = '<'..menu_t[#menu_t]
			-- add label at the current depth level
			local label = line:match(' (.+)')..'|'
			menu_t[#menu_t+1] = label
			depth = cur_depth
			else -- not first or last line of a submmenu
			local act = line:match('(.-) ')
			local label = line:match(' (.+)')..'|'
			menu_t[#menu_t+1] = label
			act_t[#act_t+1] = act
			end
		end
	end


local last_depth, min_depth = 0

	for i, line in ipairs(t) do
	local layer = type(line) == 'table' and next(line) -- get layer title
		if layer then layer_titles_t[#layer_titles_t+1] = layer:match('%[(.+)%]') end -- store layer title stripping off square brackets
	local st, fin = table.unpack(layer and {1, #line[layer]} or {0,0}) -- if layer table found traverse it, otherwise keep traversing the t table
		if layer then -- add a nested table for the layer
		menu_t[#menu_t+1], act_t[#act_t+1] = {}, {}
		end
	-- if no layer, use the main table for storage otherwise use the nested table just added
	local tbl_menu = layer and menu_t[#menu_t] or menu_t
	local tbl_act = layer and act_t[#act_t] or act_t
	last_depth = layer and 0 or last_depth -- if a layer ends with a nested menu, reset the val for the next one

		for i = st, fin do
		local line = layer and line[layer][i] or line -- if no layer use line from the main table t
		line = line:match('.+[%w%p]') -- strip trailing spaces and tab spaces
		line, cur_depth = line:gsub('[\t]','') -- remove tab spaces and while doing that count them to determine the line's depth

		min_depth = min_depth or cur_depth -- store min depth in case it's greater than 0 tab spaces because the menu starts off with indentation, that's to be able to accurately calculate exit to higher levels which is relative to the top level, in 'cur_depth < last_depth' block below

		line = line:match('^%s*(.+)') -- stripping leading spaces just in case

			if cur_depth > last_depth then -- first line of a submenu

			-- this subroutine supports several submenus in a row in which case submenu title must not be indented relative to the current level, i.e. must be outdented relative to the submenu depth
			-- re-insert submenu title which has likely been botched by splitting in the previous cycle when it was encountered
			local label = tbl_menu[#tbl_menu]
				if label then
				local act = tbl_act[#tbl_act] -- get data stored last when submenu title was encountered
				local orig_submenu_tit = #act > 0 and act..' '..label or label -- reconstruct submenu title which might have got split
				orig_submenu_tit = orig_submenu_tit:match('^[%s<>|#!]*(.+)') -- removing all formatting characters + spaces, if any, from the submenu title start
				tbl_menu[#tbl_menu] = '>'..orig_submenu_tit -- re-insert submenu title
				table.remove(tbl_act, #tbl_act) -- remove blank action added in the block below when submenu title was encountered in the immediately preceding cycle
				end

			last_depth = cur_depth -- update for subsequent cycles

			elseif cur_depth < last_depth then -- first line of a higher level menu after last submenu has been exited

			local new_lvl_cnt = cur_depth < min_depth and last_depth-min_depth or last_depth-cur_depth -- count level diff between current and previous to add exit tag accounting for cases where current level's depth is smaller than the mininal depth because the menu started off with indentation

				if new_lvl_cnt > 0 then -- if 0 there's no difference in depth so no exit tags are needed, ensures proper handling of cases where a menu item with depth smaller than the minimum is found so that such new depth items and their followers aren't ignored

				local exit_tag = ('|<'):rep(new_lvl_cnt-1)..'|' -- multiplying by the difference between the last and the current depths to go up to the corresponding level; -1 because 1 exit tag raises menu 2 levels up, 1 level up is a single < preceding the last menu item of the level; if difference is negative string.rep function will simply produce an empty string
				local last_item = tbl_menu[#tbl_menu]:match('(.+)|') -- excluding last pipe since it will be re-added with exit tag

				tbl_menu[#tbl_menu] = '<'..last_item..exit_tag -- close previous submenu

				end

			last_depth = cur_depth -- update for subsequent cycles
			min_depth = cur_depth < min_depth and cur_depth or min_depth -- update min depth if current one is yet smaller so that all subsequent memu items are evaluated against it

			end

		-- add label at the current depth level and store action
		local label = line:match(' (.+)') or line -- either regular menu item or single word submenu title or random text
		label = label:match('^[%s<>|#!]*(.+)') -- removing all formatting characters + spaces, if any, from the label start
		local act = line:match('(.-) ')
		tbl_act[#tbl_act+1] = act or ''
		-- toggle state will only be reflected for actions in the same context the script is run under
		-- if run from the Main section MIDI Editor toggle states won't be indicated and vice versa
		local togg_state = act and r.GetToggleCommandStateEx(sectionID, r.NamedCommandLookup(act)) == 1
		tbl_menu[#tbl_menu+1] = (togg_state and '!' or '')..label..'|'

		end

	end

return menu_t, act_t, layer_titles_t

end


function no_undo()
do return end
end

function ACT(comm_ID, islistviewcommand, midi) -- islistviewcommand, midi are boolean
-- islistviewcommand is based on evaluation of sectionID returned by get_action_context()
-- e.g. sectionID == 32061
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, islistviewcommand)
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
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


function Is_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse

end

function Cursor_outside_pianoroll(take)

local stored_edit_cur_pos = r.GetCursorPosition()
local item = r.GetMediaItemTake_Item(take)
local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_start + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
r.PreventUIRefresh(1)
r.MIDIEditor_LastFocused_OnCommand(40443, false) -- View: Move edit cursor to mouse cursor // islistviewcommand false
local edit_cur_pos = r.GetCursorPosition()
r.SetEditCurPos(stored_edit_cur_pos, 0, 0) -- restore edit cursor pos; moveview is 0, seekplay is 0
r.PreventUIRefresh(-1)

	if edit_cur_pos >= item_end or edit_cur_pos <= item_start then
	return true end

end


function Get_Mouse_Coordinates_MIDI(wantSnapped) -- wantsnapped is boolean
-- inserts a note at mouse cursor, gets its pitch and start position and then deletes it
-- advised to use with Get_Note_Under_Mouse() to avoid other notes, that is only run this function if that function returns nil to be sure that there's no note under mouse and Cursor_outside_pianoroll() to make sure than the mouse cursor if within the piano roll because 'Edit: Insert note at mouse cursor' which is used here inserts notes even if the cursor is outside of the MIDI item bounds, see details in the comment to the action below

local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)
local is_snap = r.GetToggleCommandStateEx(32060, 1014) -- View: Toggle snap to grid
local ACT = r.MIDIEditor_LastFocused_OnCommand

r.PreventUIRefresh(1)
r.Undo_BeginBlock() -- to prevent creation of undo point by 'Edit: Insert note at mouse cursor' and 'Edit: Delete notes'

	if wantSnapped and is_snap == 0 or not wantSnapped and is_snap == 1 then
	ACT(1014, false) -- View: Toggle snap to grid // islistviewcommand false
	end

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

local sel_note_t = {}
	for i = 0, notecnt-1 do -- store currently selected notes
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel // if looking for all notes use Clear_Restore_MIDI_Channel_Filter() to disable filter if enabled and re-enable afterwards
		if sel then sel_note_t[#sel_note_t+1] = i end
	end

r.MIDI_SelectAll(take, false) -- deselect all notes so the inserted one is the only selected and can be gotten hold of

ACT(40001, false) -- Edit: Insert note at mouse cursor // islistviewcommand false // inserts a note even if mouse cursor already points at a note; if outside of the MIDI item left edge inserts a note at the item start, if outside of the right edge - inserts and extends the item if 'Loop item source' option is OFF or inserts in the parallel position within the item if this option is ON

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take) -- re-count after insertion
local idx, x_coord, y_coord

		for i = 0, notecnt-1 do -- get index and cordinates of the inserted note which is selected by default and the only one selected since the rest have been deselected above; the coordinates correspond to the mouse cursor position wihtin piano roll
		local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel // if looking for all notes use Clear_Restore_MIDI_Channel_Filter() to disable filter if enabled and re-enable afterwards
			if sel then idx, x_coord, y_coord = i, startpos, pitch break end
		end

--r.MIDI_DeleteNote(take, idx) -- delete the inserted note // buggy, lengthens the note overlaped by the one being deleted
-- https://forum.cockos.com/showthread.php?t=159848
-- https://forum.cockos.com/showthread.php?t=195709

ACT(40002, false) -- Edit: Delete notes // islistviewcommand false

	-- restore note selection
	for _, idx in ipairs(sel_note_t) do
	r.MIDI_SetNote(take, idx, true, x, x, x, x, x, x, true) -- selectedIn true, mutedIn, startppqposIn, endppqposIn, chanIn, noSortIn are nil, noSort true since multiple notes
	end
	r.MIDI_Sort(take)
	-- restore orig Snap state
	local rest = r.GetToggleCommandStateEx(32060, 1014) ~= is_snap and ACT(1014, false)

r.PreventUIRefresh(-1)
r.Undo_EndBlock('',-1) -- to prevent creation of undo point by 'Edit: Insert note at mouse cursor' and 'Edit: Delete notes'

	if idx then
	return x_coord, y_coord, r.MIDI_GetProjTimeFromPPQPos(take, x_coord)
	-- OR return {x_coord, y_coord, r.MIDI_GetProjTimeFromPPQPos(take, x_coord)}
	end

end



function Is_Mouse_Over_Arrange(ignore_items)
-- relies on Is_TCP_Under_Mouse()
-- ignore_items is boolean, if true, only cursor outside of items in Arrange is respected

local x, y = r.GetMousePosition()

	-- if there's item under mouse it's surely over Arrange unless ignore_items is true
	if r.GetItemFromPoint(x, y, true) -- allow_locked true
	then return not ignore_items end

local tr, info = r.GetTrackFromPoint(x, y)
	if tr and info ~= 2 and not Is_TCP_Under_Mouse() then return tr end

	if not tr then -- info 2 is FX
--	r.PreventUIRefresh(1) -- doesn't help much
	local tr_idx = not r.GetTrack(0,0) and 0 or r.GetNumTracks()-1 -- insert temp track if no tracks or cursor is lower than the last track in which case tr cannot be valid
	r.InsertTrackAtIndex(tr_idx, false) -- wantDefaults false
	local temp_tr = r.GetTrack(0, tr_idx) -- track to be deleted
		if r.GetTrackFromPoint(x, y) and not Is_TCP_Under_Mouse()
		then
		r.DeleteTrack(temp_tr) -- temp track
	--	r.PreventUIRefresh(-1)
		return true
	--	else
	--	r.PreventUIRefresh(-1)
		end
	-- if not found at cursor, encrease height
	r.SetMediaTrackInfo_Value(temp_tr, 'I_HEIGHTOVERRIDE', 800)
	r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275
--	r.PreventUIRefresh(1)
	local tr  = r.GetTrackFromPoint(x, y)
	r.DeleteTrack(temp_tr) -- temp track
--	r.PreventUIRefresh(-1)
	r.CSurf_OnScroll(0,1000) -- scroll back to the track list end since expansion of the last makes the list scroll up
	return not Is_TCP_Under_Mouse() and tr
	end

end


function Get_Cursor_Contexts(allow_locked, sectionID, cmd_ID)
-- uses Cursor_outside_pianoroll(), Get_Mouse_Coordinates_MIDI(),
-- Is_TCP_Under_Mouse() and Is_Mouse_Over_Arrange()

local allow_locked = not allow_locked and false or true
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, allow_locked) -- allow_locked boolean
local build_6_36 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.36
local tr, info = table.unpack(build_6_36 and {r.GetThingFromPoint(x, y)} or {r.GetTrackFromPoint(x, y)})
	if item then
	local env = r.GetSelectedEnvelope(0)
	local parent_take, fx_idx, parm_idx = table.unpack(env and {r.Envelope_GetParentTake(env)} or {})
	return parent_take == take and 'envelope' or r.CountTakes(item) == 1 and 'item' or 'take'
	elseif tr then
		if build_6_36 then
		local tcp, mcp, fx, env, arrange = info:match('tcp'), info:match('mcp'), info:match('fx'),
		info:match('env'), -- regardless of env selection
		info:match('arrange') -- arrange excluding items because items are evaluated earlier
		return arrange or fx or env and 'envelope' or tcp or mcp -- in this order because when env and fx, tcp or mcp are also true
		else
		local env, fx = info == 1 and 'envelope', info == 2 and 'fx' -- env regardless of env selection
		return env or fx or tr and (Is_TCP_Under_Mouse() and 'tcp' or 'arrange')
		end
	elseif sectionID == 32060 then
	local ME = r.MIDIEditor_GetActive()
	local ctx = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') -- click context, returns -1 if Piano roll/Event list, > -1 if any lane
		if ctx and ctx > -1 then return 'cc' -- ctx may be false if the Main section script instance is triggered
		elseif not Cursor_outside_pianoroll(r.MIDIEditor_GetTake(ME))
		and Get_Mouse_Coordinates_MIDI() -- wantSnapped false
		then return 'pianoroll'
		elseif Is_Mouse_Over_Arrange() then return 'arrange'
		end
	else
	local trans = info:match('trans')
	return trans and 'transport'
	end

end


function validate_title(sett)
return type(sett) == 'string' and sett:match('[%w%p].+[%w%p]')
end


function Search_For_Global_Function(var_name, typ)
-- var_name is a string
-- typ is a string supported by the Lua type() function, optional
local var = _G[var_name]
return (not typ or typ and type(var) == typ) and var
end



---------------------- MAIN ROUTINE ----------------------

local is_new_value, fullpath, sectionID, cmd_ID, mode, resolution, val = r.get_action_context()
--local fullpath = fullpath:match('([^\\/]+)%.%w+') -- without path and extension
local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local ctx = Get_Cursor_Contexts(true, sectionID, cmd_ID) -- allow_locked items true // run before ::RELOAD:: because when while the menu item is clicked the mouse is below the track list Is_Mouse_Over_Arrange() will run inside Get_Cursor_Contexts() creating a temorary track which in this scenario is unnecessary because the context has already been detected and the menu opened

local ctx_titles_t = {tcp=TCP, mcp=MCP, fx=FX, item=ITEM, take=TAKE, envelope=ENVELOPE,
arrange=ARRANGE, transport=TRANSPORT, pianoroll=MIDI_PIANO_ROLL, cc=MIDI_CC}

local layer_title, layer_idx

	if not ctx then -- no valid context
	layer_idx = r.GetExtState(cmd_ID, 'LAST LAYER INDEX') -- get last used layer index
	-- before the index of the last valid layer was stored, look for the 1st set layer
	-- doing it this way because ctx_titles_t isn't indexed sequentially whereas we're searching for the 1st set layer
	layer_title = validate_title(TCP) or validate_title(MCP) or validate_title(FX) or validate_title(TAKE)
	or validate_title(ENV) or validate_title(ARRANGE) or validate_title(TRANSPORT) or validate_title(MIDI_PIANO_ROLL)
	or validate_title(MIDI_CC)
	else
	layer_title = ctx_titles_t[ctx]
	end

local err = ctx and #layer_title == 0 and '\tno menu layer \n\n  has been associated \n\n'
..'    with the current \n\n      "'..ctx..'" context'
or not layer_title and '\tno menu layer \n\n  has been associated \n\n    with any context'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
		if ctx == 'fx' or ctx == 'mcp' then -- make the error message stick for a while because if the mouse cursor is over TCP FX button or MCP elements the error tooltip is overriden by the element tooltip
		local i = 1
			repeat
			i=i+1
			until i == 70000000
		end
	return r.defer(no_undo) end


::RELOAD::

local layers_menu_t, layers_act_t, layer_titles_t = Parse_Menu_Structure(MULTY_LAYER_MENU, sectionID)

	if #layers_menu_t == 0 then
	Error_Tooltip('\n\n no menu has been defined \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

-- get index of the layer associated with the current valid context
-- unless the context isn't valid and the index was retrieved from the extended state
layer_idx = layer_idx and tonumber(layer_idx) -- if index was retrieved from the extended state
	if not layer_idx then
		for k, title in ipairs(layer_titles_t) do
			if title == layer_title -- layer title without square brackets
			or title == layer_title:match('^%s*%[(.+)%]') -- with square brackets
			then layer_idx = k break
			end
		end
	end

err = not layer_idx and (ctx and 'the layer associated \n\n with the context "'..ctx..'"\n\nwasn\'t found in the menu'
or '  the layer associated \n\n with the 1st set context \n\n    in the user settings \n\n wasn\'t found in the menu') -- the 2nd option is only valid when the context is invalid and there's no stored last used layer index

	if err then
	-- in case MULTY_LAYER_MENU contains text which isn't a menu
	-- or the name of the layer in the USER SETTINGS isn't found in the menu
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local layer_titles_menu = ''
	for k, layer_title in ipairs(layer_titles_t) do
	local checkmark = k == layer_idx and '!' or ''
	layer_titles_menu = layer_titles_menu..(k == #layer_titles_t and '<' or '')
	..checkmark..layer_title..(k < #layer_titles_t and '|' or '')
	end


layer_idx = math.floor(layer_idx) -- remove decimal zero
local layer_titles_menu = '>LAYERS MENU  ['..layer_titles_t[layer_idx]..']|'..layer_titles_menu..'||'
local cur_layer_menu = type(layers_menu_t[layer_idx]) == 'table' and table.concat(layers_menu_t[layer_idx])

	if not cur_layer_menu then
	Error_Tooltip('\n\n    malformed layer menu. \n\n menu layer '
	..layer_idx..' wasn\'t found. \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local menu = 'Next layer -->|Previous layer <--||'..layer_titles_menu..cur_layer_menu
local output = Reload_Menu_at_Same_Pos(menu, true) -- keep_menu_open true, left_edge_dist false
	if output == 0 then return
	else
	local layer_cnt = #layer_titles_t
		if output == 1 then
		layer_idx = layer_idx == layer_cnt and 1 or layer_idx+1 -- switch to next layer
		elseif output == 2 then
		layer_idx = layer_idx == 1 and layer_cnt or layer_idx-1 -- switch to prev layer
		elseif output > 2 and output <= 2+layer_cnt then -- select layer from the submenu, +2 because layer menu is preceded by 2 menu items
		layer_idx = output - 2 -- offset by 2 because layer menu is preceded by 2 menu items while layer tables are indexed from 1
		else -- actual menu layer // act
		act_idx = output - (2+layer_cnt)
		local act = layers_act_t[layer_idx][act_idx] -- command ID or function

			if act:match('.+%(%)') then
			local func_name = act:match('(.+)%(%)')
			local func = Search_For_Global_Function(func_name, 'function') -- type 'function'
				if func then
				func() -- execute
				else -- if local or non-existing function func var will be false
				Error_Tooltip('\n\n '..func_name..' FUNCTION \n\n      WASN\'T FOUND \n\n', false,1, -300, -30) -- caps false, spaced true, x -300, y-30 to move tooltip farther from the cursor otherwise it'll be covered by the reloaded menu, the values must be adjusted for each menu width, cannot be made to display over the menu because once the menu opens the script execution halts
				end
			elseif sectionID == 32060 or sectionID == 32061 then -- MIDI Editor or MIDI Event list
			ACT(act, sectionID == 32061, true) -- islistviewcommand is boolean, midi true
			elseif sectionID >= 0 and sectionID <= 16 or sectionID == 100 then
			-- accounting for REAPER 7 Main alt sections and Rec alt section
			ACT(act, false, false)
			end

		end

		if output <= 2+layer_cnt then -- store layer index for the next run, +2 because layer menu is preceded by 2 menu items

		r.SetExtState(cmd_ID, 'LAST LAYER INDEX', layer_idx, false) -- persist false

		end

	goto RELOAD

	end


do return r.defer(no_undo) end	-- prevent creation of an undo item


--===============================================================================


-- EXAMPLE MENU
--[[

[My Layer 1]

42314 Item H:M:S:F
42315 Item beats (constant time signature)
42359 Item beats, minimal (constant time signature)|
	Submenu 1
	42313 Source time
	42358 Source H:M:S:F
	40176 Take channel mode: Normal
		Submenu 2
		40177 Take channel mode: Reverse Stereo
		40178 Take channel mode: Mono (Downmix)
		40179 Take channel mode: Mono (Left)

	40180 Take channel mode: Mono (Right)|

41194 Toggle enable/disable default fadein/fadeout
41117 Trim content behind media items when editing

[My Layer 2]

42314 Item H:M:S:F
42315 Item beats (constant time signature)
42359 Item beats, minimal (constant time signature)|
Submenu 3
	42313 Source time
	42358 Source H:M:S:F
	40176 Take channel mode: Normal
	Submenu 4
		40177 Take channel mode: Reverse Stereo
		40178 Take channel mode: Mono (Downmix)
		40179 Take channel mode: Mono (Left)

	40180 Take channel mode: Mono (Right)|

41194 Toggle enable/disable default fadein/fadeout
41117 Trim content behind media items when editing

]]







