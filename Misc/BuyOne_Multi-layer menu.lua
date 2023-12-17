--[[
ReaScript name: BuyOne_Multi-layer menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Fixed error when MULTY_LAYER_MENU setting doesn't contain a valid menu
		#Added custom error messages for such cases
		#Updated Menu construction guide
  	   v1.1 #Optimized some code redundancy
		#Added menu items sanitization from special menu formatting characters
		#Added title of the currently active layer to the layer menu title
		#Updated the guide
Licence: WTFPL
REAPER: at least v5.962
About: 	The script allows accessing and using multiple menus, constructed by the user 
        within this script, from the same menu interface.
		
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
	
	The entire menu list must be preceded by one layer header. Presence 
	of layer headers further down the list without there being one at 
	the very beginning will result in a script error. 
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

	During the session the script keeps track of the last used menu layer and
	loads it on the next script run, but in each new session the default layer 
	is always the first.

	Compose your multi-layer menu structure between the double square brackets 
	of MULTY_LAYER_MENU variable below.

	At the bottom of this script there's a simple double-layer example menu
	which you can insert inside MULTY_LAYER_MENU section to see how it works.

]]

-----------------------------------------------------------------------------
------------------------------ USER FUNCTIONS --------------------------------
-----------------------------------------------------------------------------

function test()
reaper.MB('TEST', 'TEST',0)
end

-----------------------------------------------------------------------------
-------------------------- END OF USER FUNCTIONS -----------------------------
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
			elseif layer_t then
			layer_t[#layer_t+1] = line
			else -- no layer header	to begin with
			t[#t+1] = line
			end
		end
	end
	

-- construct menu, store actions and layer titles
local menu_t, act_t, layer_titles_t = {}, {}, {}
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
			min_depth = cur_depth < min_depth and cur_depth or min_depth -- EXPERIMENT update min depth if current one is yet smaller so that all subsequent memu items are evaluated against it 
			
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


function Search_For_Global_Function(var_name, typ)
-- var_name is a string
-- typ is a string supported by the Lua type() function, optional
local var = _G[var_name]
return (not typ or typ and type(var) == typ) and var
end



---------------------- MAIN ROUTINE ----------------------


::RELOAD::


local is_new_value, fullpath, sectionID, cmd_ID, mode, resolution, val = r.get_action_context()
local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)

local layer_idx = layer_idx or r.GetExtState(cmd_ID, 'LAST LAYER INDEX')
layer_idx = #layer_idx == 0 and 1 or tonumber(layer_idx)

local layers_menu_t, layers_act_t, layer_titles_t = Parse_Menu_Structure(MULTY_LAYER_MENU, sectionID)

	if #layers_menu_t == 0 then
	Error_Tooltip('\n\n no menu has been defined \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end


local layer_titles_menu = ''
	for k, layer_title in ipairs(layer_titles_t) do
	local checkmark = k == layer_idx and '!' or ''
	layer_titles_menu = layer_titles_menu..(k == #layer_titles_t and '<' or '')
	..checkmark..layer_title..(k < #layer_titles_t and '|' or '')
	end

layer_idx = math.floor(layer_idx) -- remove decimal zero
local layer_title = layer_titles_t[layer_idx]

	if not layer_title then 
	-- in case MULTY_LAYER_MENU contains text which isn't a menu 
	-- or doesn't contain at least 1 menu layer header
	Error_Tooltip('\n\n no valid menu was found \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local layer_titles_menu = '>LAYERS MENU  ['..layer_title..']|'..layer_titles_menu..'||'
local cur_layer_menu = type(layers_menu_t[layer_idx]) == 'table' and table.concat(layers_menu_t[layer_idx])

local err = not cur_layer_menu and '    malformed layer menu. \n\n menu layer '..layer_idx..' wasn\'t found. ' -- layer was removed in between the script runs
or #cur_layer_menu == 0 and 'no menu was found' -- there's header but no menu
	
	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
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







