--[[
ReaScript name: BuyOne_Multi-action based on mouse cursor position in Arrange.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog: 1.4 #Added 'Envelope manager' window to the list of windows needed in evaluation of docker state
	   1.3 #Set up limitation to script functionality in cases where extensions aren't installed
	       #Updated About and USER SETTINGS text accordingly
	   1.2 #Fixed REAPER version evaluation
	   1.1 #Fixed validation of command IDs of scripts in the MIDI Editor section of the Action list
	   	#Fixed execution of MIDI Editor actions
	   	#Changed the logic of designating an action as the MIDI Editor action in the USER SETTINGS,
	   	updated the explanation accordingly
	   	#Introduced a message to indicate that no action is associated with the slot if it's set to '0'
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
Provides: [main=main,midi_editor] .
About: 	The script allows running up to 7 different actions/functions depending
	on the mouse cursor position within the Arrange view, which is divided 
	into as many zones and subzones as there're enabled presets minus 1, 
	since the 1st enabled action slot, whatever it is, is always hard linked 
	to the TCP and will only be activated when the mouse cursor hovers over 
	the track list.  

	For example if action slots 1, 3 and 4 are enabled, slot 1 will work over 
	the TCP, slot 3 will work within the 1st half of the Arrange view and slot 4
	within the 2nd half of the Arrange view; when slots 3 and 4 are enabled, 
	slot 3 will be activated when the mouse cursor is over the TCP while slot 4 - 
	while it's placed anywhere within the Arrange area which in this case becomes 
	a single zone.

	Further instructions see in the USER SETTINGS.

	If zoning doesn't work accurately on Mac, submit a bug report at the 
	addresses listed in the Website tag above and this will be looked into.

	Bind to a shortcut so that the mouse cursor isn't engaged in clicking
	a toolbar button or a menu item, or to a mouse modifier in the Track context 
	to be able to execute the script by clicking within the empty space 
	of the Arrange canvas.

	Unless it's an action which targets track and assigned to a slot hard 
	linked to the TCP, it's not recommended running actions which target 
	objects under the mouse cursor because by placing the mouse cursor within 
	a particular zone you may inadvertently target the wrong object or not
	be able to target it at all if the script is bound to a mouse modifier
	in the Track context.

	If you're going to use the script in the MIDI Editor as well, in which
	case it doesn't have to be located in the MIDI Editor section of the 
	Action list, make sure that the shortcut which the script is mapped to
	in the Main section of the Action list isn't found in the MIDI Editor 
	section of the Action list because the latter will take priority and 
	instead of the script you'll be running another action.

	CAVEAT
	
	If neither SWS/S&M or js_ReaScriptAPI extension is installed the script
	only supports 4 enabled SLOT settings, that is 4 actions, and doesn't 
	support HORIZ_ZONES setting.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- The acton slots are enabled by inserting an action command ID
-- or a function name between the quotes in the SLOT settings below;
-- the first and last enabled slots, whatever they are,
-- are hard linked to TCP meaning they'll only work when the mouse cursor
-- is over the TCP, depending on the side the TCP is displayed on
-- in the Arrange view, i.e. if it's displayed on the left side and only
-- slots 1 and 4 are enabled, slot 1 will be linked to the TCP, whereas
-- if it's displayed on the right side, slot 4 will be linked to the TCP,
-- if only slots 2, 3 and 6 are enabled, slot 2 or 6 will be linked
-- to the TCP respectively;
-- when the tracklist is displayed on the left side of the Arrange view
-- and is hidden the 1st of enabled slots won't be accessible because it's
-- hard linked to the TCP, for the same reason the last of enabled slots
-- won't be accessible if the tracklist is displayed on the right side
-- of the Arrange view and is hidden;
-- if you don't want any slot to be active over the TCP, enable any
-- slot above (if the TCP is displayed on the left) or below (if the TCP
-- is displayed on the right) those which should be active within
-- the Arrange view by inserting 0 in the SLOT setting instead
-- of a command ID or a function name, i.e. to only be able to use slots 2
-- and 3 within the Arrange view insert 0 in the SLOT1 or SLOT4-SLOT7 settings
-- (depending on the TCP position in the Arrange view), to only be able
-- to use slots 3 - 7 within the Arrange view insert 0 in the SLOT1
-- or SLOT2 settings if the TCP is displayed on the left;
-- for non-TCP linked slots REAPER Arrange view is divided along the X axis
-- into as many zones and subzones as there're enabled slots; to a single
-- enabled slot besides the one linked to the TCP the entire Arrange area
-- is allocated;
-- such slots are activated by positioning the mouse cursor within the zone
-- allocated to it starting from the TCP rightwards if the TCP is on the left
-- or starting from the left edge of the Arrange view rightwards if the TCP
-- is on the right;
-- when the number of enabled slots associated with to the Arrange view
-- exceeds 3 (4 enabled SLOT settings, 1 linked to the TCP) the zones start
-- to be subdivided into two along the Y axis, meaning that each 3d of the
-- Arrange area will be divided into top and bottom subzones; when all slots
-- are enabled there're 6 subzones in the Arrange view (the 7th is linked to
-- the TCP);
-- the upper and lower limits of the the 1st three zones lined up along the
-- X axis in the Arrange view are top and bottom of the screen, upper limit
-- of the top subzones in this case is the screen top, lower limit of the
-- lower subzones is the screen bottom; but it's safer to trigger them while
-- the mouse cursor is inside the Arrange area;
-- see zone allocation maps at 
-- https://github.com/Buy-One/screenshots/blob/main/Multi-action%20based%20on%20mouse%20cursor%20position%20in%20Arrange.pdf
-- or in schematic form at the bottom of this script;
-- due to their hard linkage to the TCP, slot 1 cannot be made to work
-- within the Arrange view when the TCP is displayed on the left while
-- slot 7 cannot when the TCP is displayed on the right;
-- if you don't want any slot to be active in the zone of the Arrange view
-- allocated to it insert 0 in the corresponding SLOT setting instead of
-- a command ID or a function name, this will keep the zone but disable the
-- slot effectively creating holes in the zone sequence within the Arrange view,
-- e.g. if all slots are enabled, insering 0 in the SLOT3 setting will disable
-- action slot 3 for the zone it's supposed to be active in (if the TCP is
-- displayed on the left - bottom half of the first 3d of the Arrange area
-- if HORIZ_ZONES setting isn't enabled below, or right half of the top 3d
-- of the Arrange area if HORIZ_ZONES setting is enabled; if the TCP is
-- displayed on the right - top half of the second 3d of the Arrange view
-- if HORIZ_ZONES setting isn't enabled and left half of the second 3d if
-- HORIZ_ZONES setting is enabled); or if slots 2, 3 and 4 are supposed
-- to be active when the TCP is displayed on the right side of the Arrange view,
-- then inserting 0 in the SLOT2 and SLOT4 settings disables preset 2 in the
-- left half of the Arrange view (bottom half if HORIZ_ZONES setting is enabled
-- below) and disables preset 4 over the TCP;
-- if a SLOT setting is empty or invalid no zone is allocated to it
-- and the Arrange view is divided equally between or allocated in its entirety
-- to the enabled slots, depending on their number


-- By default the Arrange is divided into zones along the X axis,
-- i.e ||||; enable this setting by placing any alphanumeric character
-- between the quotes to make the division into zones occur along the Y axis,
-- i.e. ≡, instead; the first and last enabled slot will still be hard
-- linked to the TCP depending on the TCP position in in tha Arrange view
-- as described above, other enabled slots will be activated by positioning
-- the mouse cursor at a certain height within the Arrange view;
-- the zones follow each other from top to bottom in the same order
-- as the slots in these USER SETTINGS regardless of the Arrange side
-- the TCP is displayed on, with the top being the Ruler bottom edge
-- and the bottom being the top edge of the horizontal scrollbar
-- or of the bottom docker if one is open;
-- positioning the mouse cursor outside of the Arrange area or the program
-- window on the left or the right side will still trigger the slot linked
-- to the TCP;
-- when the number of enabled slots associated with to the Arrange view
-- exceeds 3 (4 enabled SLOT settings, 1 linked to the TCP) the zones start
-- to be subdivided into two along the X axis, meaning that each 3d of the
-- Arrange area will be divided into into left and right subzones;
-- when all slots are enabled there're 6 subzones in the Arrange view
-- (the 7th is linked to the TCP);
-- see zone allocation maps at 
-- https://github.com/Buy-One/screenshots/blob/main/Multi-action%20based%20on%20mouse%20cursor%20position%20in%20Arrange.pdf
-- or in schematic form at the bottom of this script
HORIZ_ZONES = ""

----------/////////////// SLOTS //////////////////

-- To enable insert an action/script command ID or a function name;
-- disabled when empty or invalid;
-- if 0 is insetred instead, the slot will ony have a zone allocated
-- to it without any action/function being associated with it;
-- if a function is going to be used it's recommended to declare
-- it in the USER FUNCTIONS area below so as to not mix
-- user functions with those native to this script
SLOT1 = ""

-- If a function name is specified in the SLOT1 setting
-- and such function accepts arguments, list the arguments
-- in this setting between the braces delimited by comma
-- e.g. {1, 10.4, true, "name", false, nil} etc.
SLOT1_args = {}

-- Enable by inserting any alphanumeric character
-- if the native / SWS (cycle) action whose command ID
-- is specified in the SLOT1 setting is located
-- in the MIDI Editor section of the Action list
-- because via API there's no way to determine theirs 
-- and SWS actions association with a particular
-- Action list section;
-- will be ignored if SLOT1 setting contains a custom
-- action / script command ID because these allow
-- to determine the section they reside in
SLOT1_midi = ""

-- The name of the action you want to be listed
-- in the Undo history;
-- only relevant for functions because actions/scripts
-- will create their own Undo point;
-- if empty, the function name will be used;
-- if your function is designed to create an undo point
-- because its name depends on certain conditions, insert
-- 0 here so that the function based undo point name is used
SLOT1_act_name = ""

-------------------

-- Explanation for the following settings
-- is the same as above mutatis mutandis

SLOT2 = ""
SLOT2_args  = {}
SLOT2_midi = ""
SLOT2_act_name = ""
-------------------
SLOT3 = ""
SLOT3_args  = {}
SLOT3_midi = ""
SLOT3_act_name = ""
-------------------
SLOT4 = ""
SLOT4_args  = {}
SLOT4_midi = ""
SLOT4_act_name = ""
-------------------
SLOT5 = ""
SLOT5_args  = {}
SLOT5_midi = ""
SLOT5_act_name = ""
-------------------
SLOT6 = ""
SLOT6_args  = {}
SLOT6_midi = ""
SLOT6_act_name = ""
-------------------
SLOT7 = ""
SLOT7_args  = {}
SLOT7_midi = ""
SLOT7_act_name = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
------------------------------ USER FUNCTIONS --------------------------------
-----------------------------------------------------------------------------

-- Your functions go here




-----------------------------------------------------------------------------
-------------------------- END OF USER FUNCTIONS -----------------------------
-----------------------------------------------------------------------------



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function test1_function()
undo_block()
r.Main_OnCommand(40157,0) -- Markers: Insert marker at current position
undo_block('function own undo')
end

function no_undo()
do return end
end


function undo_block(undo) -- undo is string
	if not undo then r.Undo_BeginBlock()
	else r.Undo_EndBlock(undo, -1)
	end
end


local function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function validate_settings(...) -- if actual setting value is immaterial
local t = {...}
	for k, sett in ipairs(t) do
		if type(sett) == 'string' and #sett:gsub(' ','') > 0
		or type(sett) == 'number' then t[k] = true
		else t[k] = false
		end
	end
return table.unpack(t)
end


function validate_SLOTS(...) -- if actual value matters
local slot_t = {...}
local inval_cnt = 0
	for k, slot in ipairs(slot_t) do
	slot_t[k] = #slot:gsub(' ','') > 0 and slot:gsub(' ','') or false
		if not slot_t[k] then inval_cnt = inval_cnt+1 end
	end
--return table.unpack(slot_t), inval_cnt == #slot_t -- can't return another value after table.unpack, therefore adding it to the table
slot_t[#slot_t+1] = inval_cnt == #slot_t
return table.unpack(slot_t)
end


function MIDIEditor_GetActiveAndVisible()
-- solution to the problem described at https://forum.cockos.com/showthread.php?t=278871
local ME = r.MIDIEditor_GetActive()
local dockermode_idx, floating = r.DockIsChildOfDock(ME) -- floating is true regardless of the floating docker visibility
-- OR
-- local floating = r.DockGetPosition(dockermode_idx) == 4 -- another way to evaluate if docker is floating
-- the MIDI Editor is either not docked or docked in an open docker attached to the main window
	if ME and (dockermode_idx == -1 or dockermode_idx > -1 and not floating
	and r.GetToggleCommandStateEx(0,40279) == 1) -- View: Show docker
	then return ME
-- the MIDI Editor is docked in an open floating docker
	elseif ME and floating then
		for line in io.lines(r.get_ini_file()) do
			if line:match('dockermode'..dockermode_idx)
			and line:match('32768') -- open floating docker
			-- OR
			-- and not line:match('98304') -- not closed floating docker
			then return ME
			end
		end
	end
end



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


local wnd_ident_t = { -- used by Detect_Docker_Pane_Change()
-- the keys are those appearing in reaper.ini [REAPERdockpref] section
-- visibility key isn't used, the preceding action command ID is used instead to evaluate visibility
-- dockheight_t= height of the top docker // doesn't change when a new window with greater height is added to the docker, only when the docker is resized manually, just like toppane= value
-- transport docked pos in the top or bottom dockers can't be ascertained;
-- transport_dock=0 any time it's not docked at its reserved positions in the main window (see below)
-- which could be floating or docked in any other docker;
-- When 'Dock transport in the main window' option is enabled the values of the 'transport_dock_pos' key
-- corresponding to options under 'Docked transport position' menu item are:
-- 0 - Below arrange (default) [above bottom docker]; 1 - Above ruler [below top docker];
-- 2 - Bottom of main window [below bottom docker]; 3 - Top of main window [above top docker]
-- FX chain, MIDI Editor, IDE windows, of course scripts which have dockable windows aren't covered
transport = {'transport_dock_pos', 'transport_dock', 40259}, -- View: Toggle transport visible // transport_dock_pos must be 1 or 3; see 2nd key explanation above
-- mixer = {'mixwnd_dock', 'mixwnd_vis'},
mixer = {
40083, -- Mixer: Toggle docking in docker
40078 -- View: Toggle mixer visible ('Mixer')
},
actions = {'%[actions%]', 'dock', 40605, 'wnd_vis'}, -- Show action list ('Actions')
--=============== 'Project Bay' // 8 actions ===============
projbay_0 = {'%[projbay_0%]', 'dock', 41157, 'wnd_vis'}, -- View: Show project bay window
projbay_1 = {'%[projbay_1%]', 'dock', 41628, 'wnd_vis'}, -- View: Show project bay window 2
projbay_2 = {'%[projbay_2%]', 'dock', 41629, 'wnd_vis'}, -- View: Show project bay window 3
projbay_3 = {'%[projbay_3%]', 'dock', 41630, 'wnd_vis'}, -- View: Show project bay window 4
projbay_4 = {'%[projbay_4%]', 'dock', 41631, 'wnd_vis'}, -- View: Show project bay window 5
projbay_5 = {'%[projbay_5%]', 'dock', 41632, 'wnd_vis'}, -- View: Show project bay window 6
projbay_6 = {'%[projbay_6%]', 'dock', 41633, 'wnd_vis'}, -- View: Show project bay window 7
projbay_7 = {'%[projbay_7%]', 'dock', 41634, 'wnd_vis'}, -- View: Show project bay window 8
--============================== Matrices ======================================
routing = {'routing_dock', 'routingwnd_vis', 40768, 40251, 42031, 41888}, -- 3 toggles: View: Show track grouping matrix window ('Grouping Matrix'); View: Show routing matrix window ('Routing Matrix'); View: Show track wiring diagram ('Track Wiring Diagram'); one non-toggle: View: Show region render matrix window ('Region Render Matrix') -- so using reaper.ini is more reliable because it reflects the state of the 'Region Render Matrix' as well
--===========================================================================
regmgr = {'%[regmgr%]', 'dock', 40326, 'wnd_vis'}, -- View: Show region/marker manager window ('Region/Marker Manager')	// doesn't keep size
explorer = {'%[reaper_explorer%]', 'docked', 50124, 'visible'}, -- Media explorer: Show/hide media explorer ('Media Explorer') // doesn't keep size
trackmgr = {'%[trackmgr%]', 'dock', 40906, 'wnd_vis'}, -- View: Show track manager window ('Track Manager') // doesn't keep size
envmgr = {'%[envmgr%]', 'dock', 42678, 'wnd_vis'} -- View: Show envelope manager window ('Envelope Manager')
grpmgr = {'%[grpmgr%]', 'dock', 40327, 'wnd_vis'}, -- View: Show track group manager window ('Track Group Manager')
bigclock = {'%[bigclock%]', 'dock', 40378, 'wnd_vis'}, -- View: Show big clock window ('Big Clock') // doesn't keep size
video = {'%[reaper_video%]', 'docked', 50125, 'visible'}, -- Video: Show/hide video window ('Video Window')
perf = {'%[perf%]', 'dock', 40240, 'wnd_vis'}, -- View: Show performance meter window ('Performance Meter') // doesn't keep size
navigator = {'%[navigator%]', 'dock', 40268, 'wnd_vis'}, -- View: Show navigator window ('Navigator') // doesn't keep size
vkb = {'%[vkb%]', 'dock', 40377, 'wnd_vis'}, -- View: Show virtual MIDI keyboard ('Virtual MIDI Keyboard') // doesn't keep size
fadeedit = {'%[fadeedit%]', 'dock', 41827, 'wnd_vis'}, -- View: Show crossfade editor window ('Crossfade Editor')
undo = {'undownd_dock', 40072, 'undownd_vis'}, -- View: Show undo history window ('Undo History')
fxbrowser = {'fxadd_dock', 40271}, -- View: Show FX browser window ('Add FX to Track #' or 'Add FX to: Item' or 'Browse FX')  // fxadd_vis value doesn't change hence action to check visibility
itemprops = {'%[itemprops%]', 'dock', 41589, 'wnd_vis'}, -- Item properties: Toggle show media item/take properties ('Media Item Properties')
-- MIDI editor assignment to dockermode index only changes when it's being docked by dragging
-- if it's being docked via context menu the dockermode it's already assigned to is re-pointed to the new location
-- could be applicable to any window
-- midiedit key dockermode data only changes for the last active MIDI Editor even if there're several in the project
-- MIDI editor dock state (Options: Toggle window docking) like any MIDI editior toggle action
-- can only be retrieved when MIDI editor is active
-- if there're more than one MIDI editor window open each one will have to be activated in turn and its dock state checked
-- which is impossible; decided to use it anyway so any change in MIDI Editor window regardless of its dock position
-- will trigger update just in case;
-- besides, MIDIEditor_GetActive() isn't reliable since it returns the pointer of the last focused MIDI Editor
-- attached to a docker when the docker is closed https://forum.cockos.com/showthread.php?t=278871
-- but since docker state is evaluated as well this doesn't pose a problem
midiedit = {'%[midiedit%]', 'dock', r.MIDIEditor_GetActive()},
--=========== TOOLBARS // the ident strings are provisional ==========
-- when a toolbar is positioned at the top of the main window its dock and visibility states are 0
['toolbar:1'] = {'%[toolbar:1%]', 'dock', 41679, 'wnd_vis'}, -- Toolbar: Open/close toolbar 1 ('Toolbar 1')
['toolbar:2'] = {'%[toolbar:2%]', 'dock', 41680, 'wnd_vis'}, -- Toolbar: Open/close toolbar 2 ('Toolbar 2')
['toolbar:3'] = {'%[toolbar:3%]', 'dock', 41681, 'wnd_vis'}, -- Toolbar: Open/close toolbar 3 ('Toolbar 3')
['toolbar:4'] = {'%[toolbar:4%]', 'dock', 41682, 'wnd_vis'}, -- Toolbar: Open/close toolbar 4 ('Toolbar 4')
['toolbar:5'] = {'%[toolbar:5%]', 'dock', 41683, 'wnd_vis'}, -- Toolbar: Open/close toolbar 5 ('Toolbar 5')
['toolbar:6'] = {'%[toolbar:6%]', 'dock', 41684, 'wnd_vis'}, -- Toolbar: Open/close toolbar 6 ('Toolbar 6')
['toolbar:7'] = {'%[toolbar:7%]', 'dock', 41685, 'wnd_vis'}, -- Toolbar: Open/close toolbar 7 ('Toolbar 7')
['toolbar:8'] = {'%[toolbar:8%]', 'dock', 41686, 'wnd_vis'}, -- Toolbar: Open/close toolbar 8 ('Toolbar 8')
['toolbar:9'] = {'%[toolbar:9%]', 'dock', 41936, 'wnd_vis'}, -- Toolbar: Open/close toolbar 9 ('Toolbar 9')
['toolbar:10'] = {'%[toolbar:10%]', 'dock', 41937, 'wnd_vis'}, -- Toolbar: Open/close toolbar 10 ('Toolbar 10')
['toolbar:11'] = {'%[toolbar:11%]', 'dock', 41938, 'wnd_vis'}, -- Toolbar: Open/close toolbar 11 ('Toolbar 11')
['toolbar:12'] = {'%[toolbar:12%]', 'dock', 41939, 'wnd_vis'}, -- Toolbar: Open/close toolbar 12 ('Toolbar 12')
['toolbar:13'] = {'%[toolbar:13%]', 'dock', 41940, 'wnd_vis'}, -- Toolbar: Open/close toolbar 13 ('Toolbar 13')
['toolbar:14'] = {'%[toolbar:14%]', 'dock', 41941, 'wnd_vis'}, -- Toolbar: Open/close toolbar 14 ('Toolbar 14')
['toolbar:15'] = {'%[toolbar:15%]', 'dock', 41942, 'wnd_vis'}, -- Toolbar: Open/close toolbar 15 ('Toolbar 15')
['toolbar:16'] = {'%[toolbar:16%]', 'dock', 41943, 'wnd_vis'}, -- Toolbar: Open/close toolbar 16 ('Toolbar 16')
['toolbar:17'] = {'%[toolbar:17%]', 'dock', 42404, 'wnd_vis'} -- Toolbar: Open/close media explorer toolbar ('Toolbar 17')
}


function Detect_Docker_Pane_Change(wnd_ident_t, pos) -- used inside Get_Arrange_and_Header_Heights()
-- pos is integer signifying docker position: 0 - bottom, 1 - left, 2 - top, 3 - right
-- a) store current dock and visibility state values of windows from wnd_ident_t table as extended state
-- b) recall them and collate with their current values if their dockermode belongs to the docker corresponding to the 'pos' arg, if pos is 2 (top) it's needed because main window header height affects Arrange height
-- c) if change is detected, update the stored values and return truth to trigger Get_Arrange_and_Header_Heights() function to get the new Arrange height

	local function get_windows(t, dockermode)
		for _, v in ipairs(t) do
			if v == dockermode then return true end
		end
	end
	local function vis(cmdID)
	return r.GetToggleCommandStateEx(0,cmdID) == 1
	end
	local function get_ini_cont()
	local f = io.open(r.get_ini_file(), 'r')
	local cont = f:read('*a')
	f:close()
	return cont
	end
	local function concat_updated_vals(ref_t)
		for k, v in ipairs(ref_t) do -- string keys and non-sequential numeric keys such as action command IDs will be ignored
		local tab = ref_t[v]
		ref_t[k] = (k >= 1 and k <= 4 or k > 47) and tab or k == 5 and tab[1]..tab[2]..tab[3] or tab[1]..tab[2] -- update values in numeric keys with values from string keys; values for the first 4 numeric and 48+ keys of ref_t are singular without a nested table; for transport (5) it's a triplet; the rest are dual - dock state & visibility
		end
	-- first concatenate, then return, otherwise what will be returned is the function
	local upd_vals = table.concat(ref_t, ' ') -- concatenation ignores non-numeric and non-sequential keys
	return upd_vals
	end
	local function vals_changed(dock, vis, dock_ref, vis_ref)
	return dock == '1' and dock ~= dock_ref and (vis == '1' and vis ~= vis_ref or vis_ref == '1') -- window became docked AND visible or WHILE being visible
	or dock == '0' and dock ~= dock_ref and vis == '1' and vis == vis_ref -- window became undocked from the top WHILE being visible
	or dock == '1' and dock == dock_ref and vis ~= vis_ref -- docked window visibility changed
	end

-- Store/retrieve stored values, storage disregards attachment of a window to the top docker, all are stored

-- ref_t is list of stored values a change in which will trigger arrange height update with Get_Arrange_and_Header_Heights()
-- the order of values corresponds to the order of keys in wnd_ident_t with 4 additional fields added at the beginning for non-dual values and which will be evaluated separately
-- 47 native window fields
local dock_h = pos == 0 and 'dockheight' or pos == 1 and 'dockheight_l' or pos == 2 and 'dockheight_t' or pos == 3 and 'dockheight_r'
local pane = pos == 0 and 'invalid' or pos == 1 and 'leftpanewid' or pos == 2 and 'toppane'
or pos == 3 and (r.GetToogleCommandStateEx(0,42373) and 'leftpanewid' or 'invalid') -- View: Show TCP on right side of arrange // 'leftpanewid' is also relevant when pos argument is 3 (right) and the tracklist is on the right, otherwise irrelevant)
local ref_t = {41297, 40279, dock_h, pane, 'transport', 'mixer', 'actions', 'projbay_0',
'projbay_1', 'projbay_2', 'projbay_3', 'projbay_4', 'projbay_5', 'projbay_6', 'projbay_7', 'routing',
'regmgr', 'explorer', 'trackmgr', 'envmgr', 'grpmgr', 'bigclock', 'video', 'perf', 'navigator', 'vkb', 'fadeedit',
'undo', 'fxbrowser', 'itemprops', 'midiedit', 'toolbar:1', 'toolbar:2', 'toolbar:3', 'toolbar:4', 'toolbar:5',
'toolbar:6', 'toolbar:7', 'toolbar:8', 'toolbar:9', 'toolbar:10', 'toolbar:11', 'toolbar:12', 'toolbar:13',
'toolbar:14', 'toolbar:15', 'toolbar:16', 'toolbar:17'}

local retval, vals = r.GetProjExtState(0, 'DOCK'..pos..' WINDOWS STATE', 'stored_vals')
local vals = (not retval or #vals == 0) and r.GetExtState('DOCK'..pos..' WINDOWS STATE', 'stored_vals') or vals
	if #vals == 0 then -- initial storage
	local cont = get_ini_cont()
		for k, v in ipairs(ref_t) do
		local tab = wnd_ident_t[v]
			if k >= 1 and k <= 4 then
			ref_t[k] = k < 3 and (vis(v) and '1' or '0') -- Toolbar: Show/hide toolbar at top of main window, View: Show docker
			or k >= 3 and cont:match(v..'=(%d-)\n') or '0' -- dock height and pane height/width, the latter is only relevant for top/left panes hence alternative 0 for bottom which is invalid, leftpane is also relevant when the tracklist is displayed on the right and pos argument is 3 (right) but otherwise won't be valid either
			-- next store dock state:visibility
			-- first windows with mixed values and without dedicated section in reaper.ini
			elseif v == 'transport' then -- 1st field holds dock state key, 2nd - docked status outside of the reserved positions, 3d holds command ID
			ref_t[k] = (cont:match(tab[1]..'=(%d-)\n') or '0')..(cont:match(tab[2]..'=(%d-)\n') or '0')..(vis(tab[3]) and '1' or '0')
			elseif v == 'mixer' then -- both fields in the nested table hold command IDs
			ref_t[k] = (vis(tab[1]) and '1' or '0')..(vis(tab[2])  and '1' or '0')
			elseif v == 'routing' then -- only 1st two fields are used, both hold reaper.ini keys
			local dock, vis = cont:match(tab[1]..'=(%d-)\n') or '0', cont:match(tab[2]..'=(%d-)\n') or '0'
			ref_t[k] = dock..vis
			elseif v == 'undo' or v == 'fxbrowser' then -- 1st field holds dock state key, 2nd holds command ID
			local dock, vis = cont:match(tab[1]..'=(%d-)\n') or '0', vis(tab[2]) and '1' or '0'
			ref_t[k] = dock..vis
			elseif v:match('[%u]') then -- SWS ext window identifier name, they all have upper case chars unlike the native ones // ignored if ref_t doesn't contain them
			ref_t[k] = r.GetToggleCommandStateEx(0, r.NamedCommandLookup(v)) == 1 and '1' or '0' -- only visibility since it's impossible to get SWS ext windows dock state
			-- then windows with dedicated section in reaper.ini and hence 3 fields in the nested table
			else -- section and key may not exist yet so must be ascertained, if not found zeros are stored
			local sect = cont:match(tab[1])
			local dock = sect and cont:match(sect..'.-'..tab[2]..'=(%d-)\n') or '0' -- sect is already escaped
			local vis = v == 'midiedit' and tab[3] or v ~= 'midiedit' and vis(tab[3]) -- for MIDI editor visibility evaluation a function is used
			ref_t[k] = dock..(vis and '1' or '0')
			end
		end
	local vals = table.concat(ref_t, ' ')
	r.SetExtState('DOCK'..pos..' WINDOWS STATE', 'stored_vals', vals, false) -- persist false
	r.SetProjExtState(0, 'DOCK'..pos..' WINDOWS STATE', 'stored_vals', vals)
	return true -- exit function and trigger initial arrange props storage in Get_Arrange_and_Header_Heights()
	else -- retrieve stored values
	local cntr = 0
		for data in vals:gmatch('%d+') do
			if data then
			cntr = cntr+1
		--	add as string keys in ref_t for easier evaluation against reaper.ini data, won't interfere with the already present numeric keys
			local a, b, c = table.unpack((cntr >= 1 and cntr <= 4 or cntr > 47) and {data} or cntr == 5 and {data:match('(%d)(%d)(%d)')} or {data:match('(%d)(%d)')}) -- first 4 vals and 48+ are singular, 5th (transport) is a triplet, the rest are dual - dock state:visibility
			ref_t[ref_t[cntr]] = c and {a, b, c} or b and {a, b} or a -- a, b, c are dock, reserved, visible for transport; a, b are dock, visible; a - dock for keys 1-4
			end
		end
	end

-- Compare stored values with the current one looking for changes and update stored values if there's any change

local update

-- top toolbar visibility
local tb_top, tb_top_ref = vis(41297) and '1' or '0', ref_t[41297] -- Toolbar: Show/hide toolbar at top of main window
	if tb_top ~= tb_top_ref then
	ref_t[41297] = tb_top; update = 1
	end
-- docker visibility
local dock, dock_ref = vis(40279) and '1' or '0', ref_t[40279] -- View: Show docker // there not necessarily should be an active top docker, but since it's difficult to ascertain, trigger whenever the action toggle state changes
	if dock ~= dock_ref then
	ref_t[40279] = dock; update = 1
	end
-- top docker/pane hight change
local cont = get_ini_cont()
local dock_h_ref, pane_ref = ref_t[dock_h], ref_t[pane]
local dock_h_cur, pane_cur = cont:match(ref_t[3]..'=(%d-)\n'), cont:match(ref_t[4]..'=(%d-)\n')
		if dock_h_cur ~= dock_h_ref then
		ref_t[dock_h] = dock_h_cur; update = 1
		elseif pane_cur and pane_cur ~= pane_ref then -- pane_cur var can be nil if pos argument is 0 (bottom), or 3 (right) and the tracklist isn't displayed on the right
		ref_t[pane] = pane_cur; update = 1
		end
-- 'transport', 1st field holds dock state key, 2nd - floating or docked elsewhere; 3d holds command ID; transport dock position other than the reserved ones attached in the main window cannot be ascertained, see comments to wnd_ident_t table, therefore its evaluated outside of the loop below separately from windows whose dock position can be ascertained
local tab = wnd_ident_t.transport
local dock, reserv, visib = cont:match(tab[1]..'=(%d)\n') or '0', cont:match(tab[2]..'=(%d)\n') or '0', vis(tab[3]) and '1' or '0'

local tab = ref_t.transport
local dock_ref, reserv_ref, vis_ref = tab[1], tab[2], tab[3] -- ref nested table only holds 2 values, dock state and visibility
	if reserv ~= reserv_ref and (dock_ref == '1' or dock_ref == '3') and visib == '1' and visib == vis_ref -- window got detached from or attached to reserved position at the top while being visible
	or (dock == '1' or dock == '3') and dock_ref ~= '1' and dock_ref ~= '3' and (visib == '1' and visib ~= vis_ref
	or vis_ref == '1') -- window became docked at the top at one of the reserved positions AND visible or WHILE being visible
	or dock ~= '1' and dock ~= '3' and (dock_ref == '1' or dock_ref == '3') and visib == '1' and visib == vis_ref -- window became docked in one of the reserved positions OTHER than at the top WHILE being visible
	or (dock == '1' or dock == '3') and dock == dock_ref and visib ~= vis_ref -- visibility of transport docked at the top in one of the reserved positions changed
	then
	ref_t.transport = {dock, reserv, visib}
	update = 1
	end

local ini_path = r.get_ini_file()
local top_t = {}
	for line in io.lines(ini_path) do -- collect all dockermode indices pointing to the docker specified in pos arg
	local dockermode = line:match('dockermode(%d+)='..pos)
		if dockermode then
		top_t[#top_t+1] = dockermode end
	end

local wnd_t, found = {}
	-- lines don't capture line break
	for line in io.lines(ini_path) do -- collect key names of all windows attached to the collected dockermodes
		if line:match('REAPERdockpref') then found = 1
		elseif found and line:match('%[.-%]') then break -- new section
		elseif found and get_windows(top_t, line:match('.+ (%d+)')) then -- before the capture space is required otherwise double digit dockermode index won't be captured since the greedy operator will only stop at the last digit
		wnd_t[#wnd_t+1] = line:match('(.+)=')
		end
	end

	for _, v in ipairs(wnd_t) do -- evaluate collected windows docker and visibility status against stored retrieved values, first 4 have been evaluated above // by itself assignment of a window to a dockermode isn't significant as this is merely the last known value of the docked window which currently can be floating, therefore the actual dock and visibility status must be evaluated
		if wnd_ident_t[v] then -- only target suported windows
		local sws = v:match('[%u]') -- SWS ext window identifier name, they all have upper case chars unlike the native ones // ignored if wnd_ident_t doesn't contain them
		local tab = wnd_ident_t[v]
		local dock_ref, vis_ref, dock, visib = ref_t[v][1], ref_t[v][2] -- visib instead of vis to prevent clash with vis() function
			if v == 'mixer' then -- both fields in the nested table hold command IDs
			dock, visib = vis(tab[1]) and '1' or '0', vis(tab[2]) and '1' or '0'
			update = vals_changed(dock, visib, dock_ref, vis_ref) or update
			elseif v == 'routing' then -- only 1st two fields are used, both hold reaper.ini keys
			dock, visib = cont:match(tab[1]..'=(%d-)\n') or '0', cont:match(tab[2]..'=(%d-)\n') or '0' -- in case the key hasn't been added yet to reaper.ini
			update = vals_changed(dock, visib, dock_ref, vis_ref) or update
			elseif (v == 'undo' or v == 'fxbrowser') then -- 1st field holds dock state key, 2nd holds command ID
			dock, visib = cont:match(tab[1]..'=(%d-)\n') or '0', vis(tab[2]) and '1' or '0'
			update = vals_changed(dock, visib, dock_ref, vis_ref) or update
			elseif sws then
			visib = r.GetToggleCommandStateEx(0, r.NamedCommandLookup(v)) == 1 and '1' or '0'
			update = ref_t[v] ~= visib or update -- SWS ext only ref value (visibility) isn't stored in a nested table
			else -- windows with dedicated section in reaper.ini and hence 3 fields in the nested table
			dock = cont:match(tab[1]..'.-'..tab[2]..'=(%d-)\n') or '0'
			visib = v == 'midiedit' and (tab[3] and '1' or '0') or v ~= 'midiedit' and (vis(tab[3]) and '1' or '0') -- for MIDI editor visibility evaluation the MIDIEditor_GetActive() function stored in the nested table is used, but the function isn't reliable in determining visibilty when the MIDI editor is attached to a closed docker because in this case it still returns its pointer when no other MIDI editor window has focus, as if it were visible https://forum.cockos.com/showthread.php?t=278871
			update = vals_changed(dock, visib, dock_ref, vis_ref) or update
			end
			if update then -- store under window identifier name used as a string key in the same table which won't interfere with its indexed part
			ref_t[v] = sws and visib or {dock, visib} -- SWS ext windows only have visibility stored // ignored if wnd_ident_t doesn't contain them
			end
		end
	end
	if update then
	local vals = concat_updated_vals(ref_t)
	r.SetExtState('DOCK'..pos..' WINDOWS STATE','stored_vals', vals, false) -- persist false
	r.SetProjExtState(0, 'DOCK'..pos..' WINDOWS STATE', 'stored_vals', vals)
	return true end -- exit function and trigger initial arrange props storage in Get_Arrange_and_Header_Heights()

end


-- THE PART OF THE FUNCTION MEANT FOR CASES WHEN EXTENSIONS AREN'T INSTALLED IS NOT USED BECAUSE AN ERROR MESSAGE PREVENTS
-- THE SCRIPT FROM REACHING ITS STAGE WHEN HORIZ_ZONES SETTING OR OVER 4 SLOT SSETTINGS ARE ENABLED
-- when bottom docker is open the action 'View: Toggle track zoom to maximum height' used to get Arrange height in such cases
-- only allows track to be zoomed in vertically up to the bottom docker edge so full Arrange height value will be unavalable
-- which effectively makes all calculations useless
-- in theory for more than 4 slots, to get Arrange height one would have to close all windows docked at the bottom docker
-- in order to avoid closing the docker itself because top docker relevant for calculation will be closed as well
-- in case some windows are docked in it, then get max track size, then re-open the closed windows docked at the bottom docker
-- and to calculate Arrange size between the bottom docker and the Ruler for horizontal zones 
-- before all that one would have to get max track size while the bottom docker is open
-- which is super unreliable because docked MIDI Editor, FX chain and script GFX windows cannot be closed and restored
-- with the native API
function Get_Arrange_and_Header_Heights()
-- if no SWS or js_ReaScriptAPI exstension only works if the program window is fully open, change in program window size isn't detected
-- relies of Error_Tooltip() function

local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

	if sws or js then -- if SWS/js_ReaScriptAPI ext is installed
	-- thanks to Mespotine https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/blob/master/ultraschall_api/misc/misc_docs/Reaper-Windows-ChildIDs.txt
	local main_wnd = r.GetMainHwnd()
	-- trackview wnd height includes bottom scroll bar, which is equal to track 100% max height + 17 px, also changes depending on the header height and presence of the bottom docker
	local arrange_wnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, '', 'trackview', false, true) -- search by window name // OR r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, 'REAPERTrackListWindow', '', true, false) -- search by window class name
	or js and r.JS_Window_Find('trackview', true) -- exact true // OR r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000)
	local retval, lt1, top1, rt1, bot1 = table.unpack(sws and {r.BR_Win32_GetWindowRect(arrange_wnd)}
	or js and {r.JS_Window_GetRect(arrange_wnd)})
	local retval, lt2, top2, rt2, bot2 = table.unpack(sws and {r.BR_Win32_GetWindowRect(main_wnd)} or js and {r.JS_Window_GetRect(main_wnd)})
	local top2 = top2 == -4 and 0 or top2 -- top2 can be negative (-4) if window is maximized
	local arrange_h, header_h, wnd_h_offset = bot1-top1-17, top1-top2, top2  -- !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
	return arrange_h, header_h, wnd_h_offset -- arrange_h tends to be 1 px smaller than the one obtained via calculations following 'View: Toggle track zoom to maximum height' when extensions aren't installed, using 16 px instead of 17 fixes the discrepancy
	end

local lt, top, rt, bot = r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true) -- true/1 - work area, false/0 - the entire screen // https://forum.cockos.com/showthread.php?t=195629#4 // !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
local retval, arrange_h = r.GetProjExtState(0,'ARRANGE HEIGHT','arrange_height')
local arrange_h = not retval and r.GetExtState('ARRANGE HEIGHT','arrange_height') or arrange_h

-- Update/evaluate data for both docks at once so that dock_change is only true once
-- if the functions are placed in sequence like 'or A or B', the data is updated/evaluated in sequence
-- on one script run one instance returns true, another is ignored, on the next run it's vice versa
-- which makes the condition triggering arrange height value update below true 2 times in a row
-- unnecessarily causing arrange height measurement routine to run twice
local dock_change = Detect_Docker_Pane_Change(wnd_ident_t, 0)
local dock_change = Detect_Docker_Pane_Change(wnd_ident_t, 2) or dock_change

	-- track cond can be added after adding a user setting to only scroll when cursor is over the tracklist in a version of the script working both ways and supposed to be bound to the mousewheel, namely right/left and down/up --- DONE OUTSIDE WITH Get_TCP_Under_Mouse()
	if #arrange_h == 0 or dock_change then -- pos is 0 (bottom) and 2 (top) because properties of both dockers affect Arrange height relevant in this application

	Error_Tooltip(' \n\n          updating data \n\n sorry about the artefacts \n\n ', 1, 1) -- caps, spaced true

	-- get 'Maximum vertical zoom' set at Preferences -> Editing behavior, which affects max track height set with 'View: Toggle track zoom to maximum height', introduced in build 6.76
	local cont
		if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.76 then
		local f = io.open(r.get_ini_file(),'r')
		cont = f:read('*a')
		f:close()
		end
	local max_zoom = cont and cont:match('maxvzoom=([%.%d]+)\n') -- min value is 0.125 (13%) which is roughly 1/8th, max is 8 (800%)
	local max_zoom = not max_zoom and 100 or math.floor(max_zoom*100+0.5) -- ignore in builds prior to 6.76 by assigning 100 so that when track height is divided by 100 and multiplied by 100% nothing changes, otherwise convert to conventional percentage value

	-- Store track heights
	local t = {}
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		t[#t+1] = r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
		end
	local ref_tr = r.GetTrack(0,0) -- reference track (any) to scroll back to in order to restore scroll state after track heights restoration
	local ref_tr_y = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPY')

	-- Get the data
	-- When the actions are applied the UI jolts, but PreventUIRefresh() is not suitable because it blocks the function GetMediaTrackInfo_Value() from getting the return value
	-- toggle to minimum and to maximum height are mutually exclusive // selection isn't needed, all are toggled
	r.Main_OnCommand(40110, 0) -- View: Toggle track zoom to minimum height
	r.Main_OnCommand(40113, 0) -- View: Toggle track zoom to maximum height
	local tr_h = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPH')/max_zoom*100 -- not including envelopes, action 40113 doesn't take envs into account; calculating track height as if it were zoomed out to the entire Arrange height by taking into account 'Maximum vertical zoom' setting at Preferences -> Editing behavior
	local tr_h = math.floor(tr_h+0.5) -- round; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is integer, otherwise the calculated Arrange height is fractional because the actual track height in pixels is integer which is not what it looks like after calculation based on percentage (max_zoom) value, which means the value is rounded in REAPER internally because pixels cannot be fractional and the result is ±1 px diviation compared to the Arrange height calculated at percentages by which 100 can be divided without remainder
	r.Main_OnCommand(40110, 0) -- View: Toggle track zoom to minimum height
	r.SetExtState('ARRANGE HEIGHT','arrange_height', tr_h, false) -- persist false
	r.SetProjExtState(0, 'ARRANGE HEIGHT','arrange_height', tr_h)

	-- Restore
		for k, height in ipairs(t) do -- restore track heights
		local tr = r.GetTrack(0,k-1)
		r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', height)
		end
	r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275

	r.PreventUIRefresh(1)
	r.CSurf_OnScroll(0, -1000) -- scroll all the way up as a preliminary measure to simplify scroll pos restoration because in this case you only have to scroll in one direction so no need for extra conditions
	local Y_init = 0
		repeat -- restore track scroll
		r.CSurf_OnScroll(0, 1) -- 1 vert scroll unit is 8 px
		local Y = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y else break end -- when the track list is scrolled all the way down and the script scrolls up the loop tends to become endless because for some reason the 1st track whose Y coord is used as a reference can't reach its original pos, this happens regardless of the preliminary scroll direction above, therefore exit loop if it's got stuck, i.e. Y value hasn't changed in the next cycle; this doesn't affect the actual scrolling result, tracks end up where they should // unlike track size value, track Y coordinate accessibility for monitoring isn't affected by PreventUIRefresh()
		until Y <= ref_tr_y
	r.PreventUIRefresh(-1)

	local header_h = bot - tr_h - 23 -- size between program window top edge and Arrange // 18 is horiz scrollbar height (regardless of the theme) and 'bot / window_h' value is greater by 4 px than the actual program window height hence 18+4 = 22 has to be subtracted + 1 more pixel for greater precision in targeting item top/bottom edges
	return tr_h, header_h, 0 -- tr_h represents Arrange height, 0 is window height offset, that is screen 0 Y coordinate // return updated data

	else

	return tonumber(arrange_h), bot-arrange_h-23, 0 -- return previously stored arrange_h, header height and window height offset which is 0 when no extension is installed, that is screen 0 Y coordinate // calculation explication see above

	end

end


function Get_Mouse_TimeLine_Pos(zones_t)
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
local target
	if not zones_t then
	target = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
	else
	target = new_cur_pos >= zones_t.start and new_cur_pos <= zones_t.fin -- when HORIZ_ZONES setting is enabled start is zone top edge, fin is its bottom edge and they're evaluated inside Get_Mouse_Y_Axis_Pos()
	end
-- Restore orig. edit cursor pos
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
r.PreventUIRefresh(-1)
return target

end


function Get_Mouse_Y_Axis_Pos(zones_t, header_h, wnd_h_offset)
-- MAY NOT WORK ON MAC since Y coord count starts from the bottom
local _, y = r.GetMousePosition()
local y = y - header_h - wnd_h_offset
return zones_t.top and y >= zones_t.top and y <= zones_t.bot -- extra zones, 4 zone coordinates, start/fin on the X axis evaluated in Get_Mouse_TimeLine_Pos(), top/bottom on the Y axis
or not zones_t.top and y >= zones_t.start and y <= zones_t.fin -- regular zones, 2 zone coordinates, evaluated here if HORIZ_ZONES sett is enabled, in which case start is zone top edge, fin is its bottom edge
end


function Mouse_Wheel_Direction(mousewheel_reverse) -- mousewheel_reverse is boolean
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = r.get_action_context() -- val seems to not be able to co-exist with itself retrieved outside of the function, in such cases inside the function it's returned as 0
	if mousewheel_reverse then
	return val > 0 and -1 or val < 0 and 1 -- wheel up (forward) - leftwards/downwards or wheel down (backwards) - rightwards/upwards
	else -- default
	return val > 0 and 1 or val < 0 and -1 -- wheel up (forward) - rightwards/upwards or wheel down (backwards) - leftwards/downwards
	end
end


local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

HORIZ_ZONES = #HORIZ_ZONES:gsub(' ','') > 0

SLOT1, SLOT2, SLOT3, SLOT4, SLOT5, SLOT6, SLOT7, all_off = validate_SLOTS(SLOT1, SLOT2, SLOT3, SLOT4, SLOT5, SLOT6, SLOT7)
local SLOT_t = {SLOT1, SLOT2, SLOT3, SLOT4, SLOT5, SLOT6, SLOT7} --- validated

	if all_off then Error_Tooltip('\n\n no enabled slots\n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

-- validate slots for zone allocation
-- a zone is only to be allocated to enabled slots which are not the 1st enabled slot when TCP is displayed on the left side of the Arrange and not the last enabled when it's displayed on the right side of the Arrange because these are always linked to the TCP and doesn't need a zone allocated to it
-- a slot is not the 1st enabled one as long as there's at least one enabled slot preceding it in the order in which they're listed in the USER SETTINGS and it's not the last enabled as long as at least one enabled slot follows it in such order
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local slot_t = {truth={}, table.unpack(SLOT_t)}
-- after the loop in the table only those slot vars will be true which aren't the 1st or not the last enabled (depending on the TCP position) because to these no zone is allocated as they're hard linked to the TCP
	for k1, slot1 in ipairs(slot_t) do -- evaluate each next slot against all preceding slots or against all following depending on which side the TCP is displayed on in Arrange view
	slot_t.truth[k1] = false
		for k2, slot2 in ipairs(slot_t) do
			if slot1 and (not right_tcp and k2 < k1 or right_tcp and k2 > k1) and slot2 then -- k2 < k1 and k2 > k1 to prevent evaluation against itself, doesn't apply to the very 1st and the very last entry because in this case k2 == k1
			slot_t.truth[k1] = true
			break end
			if not right_tcp and k2 == k1 then break end -- exit as soon as the same slot entry is selected to prevent evaluation against next slot, doesn't apply in evaluation against following slots since the evaluation only starts after k2 == k1
		end
	end


local zones = {}
	for k, truth in ipairs(slot_t.truth) do
		if truth then zones[#zones+1] = 'SLOT'..k -- store slot name to be used as a key // creating an indexed table to be able to traverse it in ascending order below while storing zone ranges
		end
	end

local err = (not sws and not js) and (#zones+1 > 4 and '   without extensions only 4 \n\n enabled slots are supported' -- +1 is accounting for the TCP zone
or HORIZ_ZONES and ' without extensions horizontal \n\n\tzones aren\'t supported')

	if err then Error_Tooltip('\n\n'..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local extra_zones = #zones > 3 -- extra zones within the Arrange view, of which max number of regular zones is 3
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start & screen_x_end both 0 = GET // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true // THE TIME INCLUDES VERTICAL SCROLLBAR 17 px wide which will have to be subtracted to get the exact right edge of the time line
local vert_scrollbar_w_sec = 17/r.GetHZoomLevel() -- in sec; vertical scrollbar which is included in the Arrange view length, is 17 px wide and must be subtracted to get true visible area size
local end_time = end_time-vert_scrollbar_w_sec
local arrange_h, header_h, wnd_h_offset = table.unpack((HORIZ_ZONES or extra_zones) and {Get_Arrange_and_Header_Heights()} or {}) -- DATA FOR HORIZONTAL ZONES
local breakpoint_index = (#zones - 3)*2 -- index of the last slot to be given additional zone coordiates when the zones count exceeds 4 (default 3 in the Arrange + 1 over the TCP which isn't taken into account) because in this case a standard zone will have to be divided into two to accommodate additional slots (#zones is representing the total of enabled slots), i.e. if 4 slots are enabled then the 1st zone out of the default 3 associated with the Arrange view will have to be made into 2 so that their total number equals 4, 4 - 3 = 1 -> 1*2 + 2 = 4, when 5 are enabled then the first 2 will have to be made into 2 each, 5 - 3 = 2 -> 2*2 + 1 = 5, in the first example the breakpoint index is 2 (1*2) because the 2nd enabled slot is the last to be given additional zone coordinates since it's moved from the default second 3d to the bottom half of the default first 3d, in the second example the breakpoint index is 4 (2*2) because the last slot to be given additional coordinates is 4 (1+2 = first default 3d, 3+4 = second default 3d); max is 6 zones within the Arrange view since the 7th is always linked to the TCP; when Arrange zone count is 3 or less breakpoint index is 0 or invalid -> (3 - 3)*2 = 0 or (1 - 3)*2 = -4, otherwise it's always an even number because of division of regular zones by 2
local zone_cnt = #zones > 3 and 3 or #zones -- max number of base zones is always 3 regardless of subzones presence
local zone_size = not HORIZ_ZONES and (end_time-start_time)/zone_cnt or arrange_h/zone_cnt
local subzone_size = extra_zones and (not HORIZ_ZONES and arrange_h/2 or (end_time-start_time)/2) -- subzone is the one created by halving the regular zone when number of slots active in the Arrange exceeds 3

	for k, slot in ipairs(zones) do -- associate slot name as a key with zone bounds // the table only contains active slots within the Arrange view and k represents its ordinal number from left to right or top to bottom on which allocation is based which isn't necessarily the same as their variable number in the USER SETTINGS when only some are enabled
		if k <= breakpoint_index then
		local odd = k%2 ~= 0
		local mult = k < 3 and 0 or k < 5 and 1 or 2
		zones[slot] = not HORIZ_ZONES and
		(odd and {start=start_time+zone_size*mult, fin=start_time+zone_size*(mult+1), top=0, bot=subzone_size} -- top subzone, index is odd // top and bot coordinates MAY NOT WORK ON MAC since there Y axis starts at the bottom
		or {start=start_time+zone_size*mult, fin=start_time+zone_size*(mult+1), top=subzone_size, bot=subzone_size*2}) -- bottom subzone, index is even
		or HORIZ_ZONES and
		(odd and {start=start_time, fin=start_time+subzone_size, top=zone_size*mult, bot=zone_size*(mult+1)} -- left subzone
		or {start=start_time+subzone_size, fin=start_time+subzone_size*2, top=zone_size*mult, bot=zone_size*(mult+1)} ) -- right subzone
		-- couldn't devise universal formula for both following cases
		elseif extra_zones then -- OR breakpoint_index > 0, k is greater than the breakpoint index
		local mult = math.floor(k/2) -- this happens to calculate the number of regular zones already parsed so far
		zones[slot] = not HORIZ_ZONES and {start=start_time+zone_size*mult, fin=start_time+zone_size*(mult+1)}
		or {start=zone_size*mult, fin=zone_size*(mult+1)} -- MAY NOT WORK ON MAC since there Y axis starts at the bottom
		else -- breakpoint index is invalid since the number of zones in Arrange view doesn't exceed 3
		zones[slot] = not HORIZ_ZONES and {start=start_time+zone_size*(k-1), fin=start_time+zone_size*k}
		or {start=zone_size*(k-1), fin=zone_size*k} -- MAY NOT WORK ON MAC since there Y axis starts at the bottom
		end
	end


function Associate_Slot_w_TCP(TCP, right_tcp, ...) -- TCP is boolean indicating if mouse cursor is over the TCP
local slot_val_t = {...}
local st, fin, step = table.unpack(not right_tcp and {1,#slot_val_t,1} or {#slot_val_t,1,-1})
-- traverse in reverse when the TCP is on the right because in this case
-- the last enabled slot is associated with the TCP
	for i = st, fin, step do
	local slot_val = slot_val_t[i]
		if slot_val and TCP then return 'SLOT'..i, slot_val:match('[%w%p].*[%w%p]*') end -- returning var name to be able to validate it by looking for it in the _G table in case it's a function, and its value stripping spaces from the value if any, accommodating single character value
	end
end


function Is_Slot_Associated_w_TCP_Disabled(slot_var, ...)
local slot_val_t = {...}
	for k, slot_val in ipairs(slot_val_t) do
		if slot_var == 'SLOT'..k -- if TCP_left_var or TCP_right_var are passed
		and slot_val == '0' then return true
		end
	end
end


local name_t = {SLOT1_act_name, SLOT2_act_name, SLOT3_act_name, SLOT4_act_name, SLOT5_act_name, SLOT6_act_name, SLOT7_act_name}

function Associate_ActNameSett_With_Slot(slot_var, name_t)
	for k, act_name in ipairs(name_t) do
		if slot_var == 'SLOT'..k then
		return act_name:match('[%w%p].*[%w%p]*') -- strip leading/trailing spaces; accommodating 0 setting as a means to yield to user's own undo point name within their function
		end
	end
end


function Validate_Type(slot_val) -- slot_val is the value assigned to SLOT variable

-- if global function, REAPER's native ReaScript API, including 3d party APIs
local func = slot_val ~= '0' and _G[slot_val]
local func = func and type(func) == 'function' and func -- ascertain that the function has been declared by the user in case it's global, existence of a local function will be ascertained outside // regarding 0 see comment above
local commID = slot_val ~= '0' and tonumber(slot_val) -- native action // slot_val ~= '0' here is essentially redundant because this condition is used outside with 'not disabled' for the TCP and inside validate_preset() for zones
local script = slot_val:match('_?RS') and (#slot_val == 43 or #slot_val == 42 or #slot_val == 47 or #slot_val == 48) -- count with or without underscore, accounting for greater length in the MIDI Editor section due to 7d3c_ infix
local cust_act = slot_val:match('^_?[%l%d]+$') and (#slot_val == 33 or #slot_val == 32) -- count with or without underscore, not failproof against local function name whose length happens to be identical
local sws_act = slot_val:match('^_?[%u%p%d]+$')
local sws_act = sws_act and r.NamedCommandLookup(sws_act) > 0 and sws_act -- needed to distingush SWS command ID from all caps global function name

local sect
	if not func and not commID and (script or cust_act or sws_act) then
		-- validate custom action/script by searching for the command ID in reaper-kb.ini, for scripts 7d3c infix could have been used to determine the section but not for custom actions
		local reaper_kb = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-kb.ini'
		local id = slot_val:sub(1,1) == '_' and slot_val:sub(2) or slot_val -- remove underscore if any since scripts/custom actions ID don't contain it in reaper-kb.ini but KEY data do and will produce false result
			for line in io.lines(reaper_kb) do
				if line:match(id) then
				sect = line:match('^.- %d+ (%d+) ')
				break end
			end
		commID = (sect or sws_act) and slot_val:sub(1,1) ~= '_' and '_'..slot_val or slot_val -- either script/custom action if section was retrieved or SWS action // add underscore to script/custom action command ID if absent
	end
return commID, sect, func
end


local TCP = Get_Mouse_TimeLine_Pos() -- targeting the TCP (no table argument)
local TCP_slot_var, TCP_slot_val = Associate_Slot_w_TCP(TCP, right_tcp, table.unpack(SLOT_t))
local disabled = Is_Slot_Associated_w_TCP_Disabled(TCP_left_var or TCP_right_var, table.unpack(SLOT_t)) -- evaluate if the slot associated with the TCP is disabled (only relevant for the 1st or the last in the list with SLOTn var being valid, depending on the TCP position) so that action won't be executed when the mouse cursor is over the TCP
local disabled = Is_Slot_Associated_w_TCP_Disabled(TCP_slot_var, table.unpack(SLOT_t))

function validate_slot(a,b) -- validate_SLOTS() doesn't filter out 0 value since it's used to disable preset over the TCP or while keeping the zone
return a and a ~= "0" and b -- a:match('[%w%p].*[%w%p]*') ~= '0' isn't required since slot value was validated with validate_SLOTS() at the start of the routine
end

local arg_t = {SLOT1_args, SLOT2_args, SLOT3_args, SLOT4_args, SLOT5_args, SLOT6_args, SLOT7_args}
local midi_t = {table.unpack({validate_settings(SLOT1_midi, SLOT2_midi, SLOT3_midi, SLOT4_midi, SLOT5_midi, SLOT6_midi, SLOT7_midi)})}

function Select_Additional_Setting(slot_var, t)
return t[tonumber(slot_var:match('%d'))]
end

local var_t = {header_h, wnd_h_offset, extra_zones, HORIZ_ZONES, TCP}
function validate_slot_and_zone(slot, slot_coord_t, var_t)
local header_h, wnd_h_offset, extra_zones, HORIZ_ZONES, TCP = table.unpack(var_t)
	if validate_slot(slot, slot_coord_t) then
	local subzone = slot_coord_t.top -- only subzones have this key in their coordinates table
	local X_hit, Y_hit = Get_Mouse_TimeLine_Pos(slot_coord_t), header_h and Get_Mouse_Y_Axis_Pos(slot_coord_t, header_h, wnd_h_offset) -- header_h and wnd_h_offset are only valid when extra_zones or HORIZ_ZONES are true
	return (not extra_zones or not subzone) and (not HORIZ_ZONES and X_hit or HORIZ_ZONES and not TCP and Y_hit) or extra_zones and X_hit and not TCP and Y_hit
	end
end


function EXECUTE(slot_var, slot_val, name_t, midi_t)
local commID, sect, func = Validate_Type(slot_val)
local undo_txt = (Associate_ActNameSett_With_Slot(slot_var, name_t) or slot_val) -- only relevant for functions // if no custom undo point string is provided the function name will be used
local undo_txt = undo_txt ~= '0' and undo_txt -- undo not disabled by the user
local err
	if commID then
	local midi = Select_Additional_Setting(slot_var, midi_t)
	local ME = MIDIEditor_GetActiveAndVisible()
	commID = (not sect and (tonumber(commID) or commID:match('[%u%p%d]+')) or sect and (sect == '32060' and ME or sect == '0')) and commID -- either native/SWS (cycle) action for which section cannot be retrieved and midi var is used instead or script/custom action
		if commID then
		ACT(commID, midi or sect == '32060') -- midi is boolean
		end
	err = (sect and sect == '32060' or tonumber(commID) and midi) and not ME and ' no active midi editor ' or not commID and ' the script/custom action \n\n\t     isn\'t found \n\n\t  in the relevant\n\n section of the action list' -- no error is raised if there's a mismatch between a native or an extension action midi var validity and the MainOn function which runs it or if such action IDs do not exist
	elseif func then -- global function
	local args = Select_Additional_Setting(slot_var, arg_t)
	local u = undo_txt and undo_block()
	func(table.unpack(args))
	local u = undo_txt and undo_block(undo_txt)
	end
return commID, func, undo_txt, err
end

function EXECUTE_FUNC(slot_var, func, arg_t, undo_txt)
	if func then
	local args = Select_Additional_Setting(slot_var, arg_t)
	local u = undo_txt and undo_block()
	func(table.unpack(args))
	local u = undo_txt and undo_block(undo_txt)
	end
end


	if TCP_slot_var and not disabled then -- targeting the TCP, 1st enabled slot is always linked to the TCP when it's displayed on the left and the last enabled is linked to it when it's displayed on the right, unless it's disabled with '0' value
	commID, func, undo_txt, err = EXECUTE(TCP_slot_var, TCP_slot_val, name_t, midi_t) -- global for the sake of err var
		if not commID and not func then -- if not action and not global function, check if it's a local function
		-- https://stackoverflow.com/questions/2834579/print-all-local-variables-accessible-to-the-current-scope-in-lua
		-- https://www.gammon.com.au/scripts/doc.php?lua=debug.getlocal
		-- this loop must not be enclosed in a function otherwise only variables local to the function will be traversed
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == TCP_slot_val and type(val) == 'function' and val -- or tostring(val):match('function'); TCP_slot_val is supposed to contain value of TCP_slot_var which would be the name of the function
				if func then break end
			i = i+1
			until not name
		EXECUTE_FUNC(TCP_slot_var, func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT1, zones.SLOT1, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT1', SLOT1, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT1 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT1 is supposed to contain value of SLOT1 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT1', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT2, zones.SLOT2, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT2', SLOT2, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT2 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT2 is supposed to contain value of SLOT2 which would be the name of the function
				if func then break end
			i = i+1
			until not name
		EXECUTE_FUNC('SLOT2', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT3, zones.SLOT3, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT3', SLOT3, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT3 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT3 is supposed to contain value of SLOT3 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT3', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT4, zones.SLOT4, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT4', SLOT4, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT4 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT4 is supposed to contain value of SLOT4 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT4', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT5, zones.SLOT5, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT5', SLOT5, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT5 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT5 is supposed to contain value of SLOT5 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT5', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT6, zones.SLOT6, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT6', SLOT6, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT6 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT6 is supposed to contain value of SLOT6 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT6', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	elseif validate_slot_and_zone(SLOT7, zones.SLOT7, var_t) then
	commID, func, undo_txt, err = EXECUTE('SLOT7', SLOT7, name_t, midi_t)
		if not commID and not func then -- if not action and not global function, check if it's a local function
		local i = 1
			repeat
			local name, val = debug.getlocal(1, i) -- 1 is stack level
			func = name == SLOT7 and type(val) == 'function' and val -- or tostring(val):match('function'); SLOT7 is supposed to contain value of SLOT7 which would be the name of the function
				if func then break end
			i = i+1
			until not name
			EXECUTE_FUNC('SLOT7', func, arg_t, undo_txt)
		end
	err = err or not commID and not func and 'invalid slot data'

	end

err = err or not commID and not func and 'no action is associated \n\n        with the slot'
	
	if err then Error_Tooltip('\n\n '..err..' \n\n', 1, 1) return r.defer(no_undo) end -- caps and spaced are booleans




--[[

HORIZ_ZONES isn't enabled

zone allocation depending on enabled slots

1 slot - TCP zone only

the following options all include the TCP zone

2 slots │ 2 │

3 slots │2│3│

4 slots │2│3│4│

         2
5 slots │_│4│5│
        │ │ │ │
         3
	
         2 4	
6 slots │_│_│6│
        │ │ │ │
         3 5

         2 4 6
7 slots │_│_│_│
        │ │ │ │
         3 5 7
		
HORIZ_ZONES is enabled

1 slot - TCP zone only

the following options all include the TCP zone

2 slots 
        —————
          2
        ¯¯¯¯¯
3 slots	
        —————
          2
        ¯¯¯¯¯
          3
        ¯¯¯¯¯
4 slots	
        —————
          2
        ¯¯¯¯¯
          3
        ¯¯¯¯¯
          4
        ¯¯¯¯¯
5 slots
        _____
      2 __│__ 3
          4
        ¯¯¯¯¯
          5
        ¯¯¯¯¯
6 slots
        _____
      2 __│__ 3
      4 __│__ 5
          6
        ¯¯¯¯¯
7 slots
        _____
      2 __│__ 3
      4 __│__ 5
      6 __│__ 7
]]

