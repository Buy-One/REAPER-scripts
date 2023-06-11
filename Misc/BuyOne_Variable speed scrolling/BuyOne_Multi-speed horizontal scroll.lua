--[[
ReaScript name: BuyOne_Multi-speed horizontal scroll.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Updated info text in the USER SETTINGS 
	   v1.1 #Corrected typo in the end of project tooltip
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
About: Alternative to the native 'View: Scroll horizontally (MIDI CC relative/mousewheel)' 
       action which scrolls by exactly 122 px regardless of the zoom level 
       and certainly doesn't support multi-speed functionality.

       The script offers 4 scroll speed presets. The active scroll preset is
       determined by the position of the mouse cursor within the Arrange view, 
       which is divided into as many zones as there're enabled presets minus 1, 
       since the 1st enabled preset, whatever it is, is always hard linked 
       to the TCP and will only be activated when the mouse cursor hovers over 
       the track list.  
       For example if presets 1, 3 and 4 are enabled, the 1st preset will 
       work over the TCP, the 3d will work within the 1st half of the Arrange 
       view and the 4th - within the 2nd half of the Arrange view; when presets
       3 and 4 are enabled, preset 3 will be activated when the mouse cursor
       is over the TCP while preset 4 - while it's placed anywhere within 
       the Arrange view which in this case becomes a single zone. 

       If zoning doesn't work accurately on Mac, submit a bug report at the 
       addresses listed in the Website tag above and this will be looked into.

       Bind to mousewheel (optionally with modifiers).  

       With vertical mousewheel the default direction is up - right, down - left,
       to reverse the direction enable MW_REVERSE setting in the USER SETTINGS

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable insert any alphanumeric character between the quotes
MW_REVERSE = ""

-- The first and last enabled scroll speed presets, whatever they are,
-- are hard linked to TCP meaning they'll only work when the mouse cursor
-- is over the TCP, depending on the side the TCP is displayed on
-- in the Arrange view, i.e. if it's displayed on the left side and only
-- presets 1 and 4 are enabled, preset 1 will be linked to the TCP, whereas
-- if it's displayed on the right side, preset 4 will be linked to the TCP,
-- if only presets 2, 3 and 4 are enabled, preset 2 or 4 will be linked
-- to the TCP respectively;
-- when the tracklist is displayed on the left side of the Arrange view
-- and is hidden the 1st of enabled presets won't be accessible because it's
-- hard linked to the TCP, for the same reason the last of enabled presets
-- won't be accessible if the tracklist is displayed on the right side
-- of the Arrange view and is hidden;
-- if you don't want any preset to be active over the TCP, enable any
-- preset above (if the TCP is displayed on the left) or below (if the TCP
-- is displayed on the right) those which should be active within
-- the Arrange view by inserting 0 in the SPEED_No setting instead
-- of a natural number, i.e. to only be able to use presets 2 and 3 within
-- the Arrange view insert 0 in the SPEED_1 or SPEED_4 setting (depending
-- on the TCP position in the Arrange view), to only be able to use presets 3
-- and 4 within the Arrange view insert 0 in the SPEED_1 or SPEED_2
-- settings if the TCP is displayed on the left;
-- for other presets REAPER Arrange view is divided along the X axis
-- into as many equal width zones as there're enabled presets, to a single
-- enabled preset besides the one linked to the TCP the entire Arrange area
-- is allocated;
-- such scroll speed presets are activated by positioning the mouse cursor
-- within the zone allocated to it starting from the TCP rightwards if the
-- TCP is on the left or starting from the left edge of the Arrange view
-- rightwards if the TCP is on the right and they're valid across the entire
-- screen hight within the limits of the zone, that is when the mouse cursor
-- is above or below the Arrange view and even below or above the program 
-- window, but it's safer to trigger them while the mouse cursor is inside
-- the Arrange area;
-- due to their hard linkage to the TCP, preset 1 cannot be made to work
-- within the Arrange view when the TCP is displayed on the left while
-- preset 4 cannot when the TCP is displayed on the right;
-- if you don't want any preset to be active in the zone of the Arrange view
-- allocated to it insert 0 in its SPEED_No setting instead of a natural number,
-- this will keep the zone but disable the preset effectively creating holes
-- in the zone sequence within the Arrange view, e.g. if all presets are enabled,
-- insering 0 in the SPEED_3 setting will disable preset 3 for the zone it's
-- supposed to be active in (middle 3d of the Arrange area if the TCP is displayed
-- on the left or if HORIZ_ZONES setting is enabled below, or its right 3d if
-- the TCP is displayed on the right), or if presets 2, 3 and 4 are supposed
-- to be active when the TCP is displayed on the right side of the Arrange view,
-- then inserting 0 in the SPEED_2 and SPEED_4 settings disables preset 2 in the
-- left half of the Arrange view (bottom half if HORIZ_ZONES setting is enabled
-- below) and disables preset 4 over the TCP;
-- if a preset SPEED_No setting is empty or invalid no zone is allocated to it
-- and the Arrange view is divided equally between or allocated in its entirety
-- to the enabled presets, depending on their number;
-- if you wish to have the same behavior regardless of the mouse cursor
-- position, enable all presets and configure them identically


-- By default the Arrange is divided into zones along the X axis, i.e ||||;
-- enable this setting by placing any alphanumeric character between
-- the quotes to make the division into zones occur along the Y axis,
-- i.e. ≡, instead; the first and last enabled scroll speed preset will
-- still be hard linked to the TCP depending on the TCP position in
-- in tha Arrange view as described above, other enabled presets will be
-- activated by positioning the mouse cursor at a certain height within
-- the Arrange view;
-- positioning the mouse cursor outside of the program window on the left 
-- or the right side will still trigger the scroll speed preset linked 
-- to the TCP;
-- the zones follow each other from top to bottom in the same order
-- as the scroll speed presets in these USER SETTINGS
-- regardless of the Arrange side which TCP is displayed on,
-- with the top being the Ruler bottom edge and the bottom being
-- the top edge of the horizontal scrollbar or of the bottom docker
-- if one is open;
-- if neither SWS/S&M or js_ReaScriptAPI extension is installed
-- such division will only work when the program window is fully open,
-- may not work consistently and for a second will slightly affect UX
-- when the script retrieves new data if the program window
-- configuration changes;
-- if this setting doesn't work accurately on Mac, submit a bug report 
-- at the addresses listed in the Website tag above and this will be 
-- looked into.
HORIZ_ZONES = ""

--/////////////// SCROLL SPEED PRESETS //////////////////

-- To enable any of the scroll speed presets below insert
-- a numeric character between the quotes of a SPEED_No setting

-- Insert a number between the quotes,
-- when BY_BEATS setting is enabled below, both integers (whole numbers)
-- and decimal numbers are supported, numbers less than 1 will shorten
-- 1 beat: 0.5 to half (= 1/8), 0.75 to 3/4th (= 1/8 dotted),
-- 0.25 to 1/4th (= 1/16) etc., non-musical divisions and values
-- in the format of '1/2' are supported as well;
-- when BY_BEATS setting isn't enabled only integers are supported;
-- empty or invalid defaults to either 16 px or 1 beat (if BY_BEATS
-- setting is enabled) per single mousewheel nudge,
-- otherwise the value is used as a factor
-- by which the default value (16 px or 1 beat) is multiplied
SPEED_1 = "1"

-- Enable by placing any alphanumeric character between the quotes,
-- only relevant for SPEED setting above,
-- if enabled, the numeric value of the SPEED setting becomes
-- the number of beats to scroll by rather than a factor
-- to multiply pixels by, empty or invalid SPEED setting
-- in this case equals 1;
-- doesn't have any effect if PAGING_SCROLL_1 or FULL_SCROLL_1 
-- settings are enabled below;
-- at higher zoom-in levels scroll step (beat * SPEED) is reduced
-- to ensure slower scrolling for ease of following the time line
BY_BEATS_1 = ""

-- Alternative to the native
-- View: Scroll view horizontally one page (MIDI CC relative/mousewheel)
-- which only scrolls by about half of the Arrange width;
-- if enabled by placing any alphanumeric character
-- between the quotes, disables SPEED value and instead
-- makes the script scroll by the visible Arrange width
PAGING_SCROLL_1 = ""

-- Enable to be able to scroll all the way to the end and start
-- of the project with a single mouswheel nudge;
-- if enabled by placing any alphanumeric character
-- between the quotes, disables all preceeding settings
FULL_SCROLL_1 = ""

--------------------------------------------------

-- Explanation for the following settings is the same
-- as above mutatis mutandis

SPEED_2 = ""
BY_BEATS_2 = ""
PAGING_SCROLL_2 = ""
FULL_SCROLL_2 = ""

SPEED_3 = ""
BY_BEATS_3 = ""
PAGING_SCROLL_3 = ""
FULL_SCROLL_3 = ""

SPEED_4 = ""
BY_BEATS_4 = ""
PAGING_SCROLL_4 = ""
FULL_SCROLL_4 = ""


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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x+10, y-70, true) -- topmost true; -70 to display above mouse cursor thereby preventing cursor being blocked by it which impedes script execution
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


function validate_SPEED(...) -- if numeric values matter
local t = {...}
	for i = 1, #t/2 do -- only traverse SPEED fields, the table should contain both SPEED and BY_BEATS fields
	local sett = t[i]
	local by_beats = t[i+4] -- all BY_BEATS vars follow SPEED vars in the table, there're 4 of each
	local a,b = sett:match('(%d+)/(%d+)')
	local sett = by_beats and a and b and a/b or sett
	t[i] = tonumber(sett) and ( not by_beats and sett:match('%.') and 1 or by_beats and math.abs(sett) or math.floor(math.abs(sett)) )
	or false -- ignoring non-numerals, decimals when beats aren't enabled and negative values // negative numerals math.floor rounds down to a greater natural number, -1.1 is rounded down to -2; false is to prevent storing nil and thereby impeding table.unpack because without saved n value (number of fields) it will only unpack up until the first nil
	end
return table.unpack(t, 1, 4) -- only unpack SPEED vals
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
trackmgr = {'%[trackmgr%]', 'dock', 40906, 'wnd_vis'}, -- View: Show track manager window ('Track Manager')	// doesn't keep size
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
-- MIDI editor dock state like any MIDI editior toggle action can only be retrieved when MIDI editor is active
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
'regmgr', 'explorer', 'trackmgr', 'grpmgr', 'bigclock', 'video', 'perf', 'navigator', 'vkb', 'fadeedit',
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
			ref_t[ref_t[cntr]] = c and {a, b, c} or b and {a, b} or a -- a, b, c are dock, reserved, visible for transport; a, b are dock, visible; a - dock for keys 1-4, and visibility for key 48+ (SWS ext)
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
-- unnecessarily causing the ugly temporary project tab routine to run twice
local dock_change = Detect_Docker_Pane_Change(wnd_ident_t, 0)
local dock_change = Detect_Docker_Pane_Change(wnd_ident_t, 2) or dock_change

	-- track cond can be added after adding a user setting to only scroll when cursor is over the tracklist in a version of the script working both ways and supposed to be bound to the mousewheel, namely right/left and down/up --- DONE OUTSIDE WITH Get_TCP_Under_Mouse()
	if #arrange_h == 0 or dock_change then -- pos is 0 (bottom) and 2 (top) because properties of both dockers affect Arrange height relevant in this application

	Error_Tooltip(' \n\n          updating data \n\n sorry about the artefacts \n\n ', 1, 1) -- caps, spaced true

	-- get 'Maximum vertical zoom' set at Preferences -> Editing behavior, which affects max track height set with 'View: Toggle track zoom to maximum height', introduced in build 6.76
	local cont
		if tonumber(r.GetAppVersion():match('(.+)/')) >= 6.76 then
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
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
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
return y >= zones_t.start and y <= zones_t.fin -- start is zone top edge, fin is its bottom edge
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

	if not r.GetTrack(0,0) then return r.defer(no_undo)	end

MW_REVERSE = #MW_REVERSE:gsub(' ','') > 0
HORIZ_ZONES = #HORIZ_ZONES:gsub(' ','') > 0

BY_BEATS_1, PAGING_SCROLL_1, FULL_SCROLL_1 = validate_settings(BY_BEATS_1, PAGING_SCROLL_1, FULL_SCROLL_1)
BY_BEATS_2, PAGING_SCROLL_2, FULL_SCROLL_2 = validate_settings(BY_BEATS_2, PAGING_SCROLL_2, FULL_SCROLL_2)
BY_BEATS_3, PAGING_SCROLL_3, FULL_SCROLL_3 = validate_settings(BY_BEATS_3, PAGING_SCROLL_3, FULL_SCROLL_3)
BY_BEATS_4, PAGING_SCROLL_4, FULL_SCROLL_4 = validate_settings(BY_BEATS_4, PAGING_SCROLL_4, FULL_SCROLL_4)

SPEED_1, SPEED_2, SPEED_3, SPEED_4 = validate_SPEED(SPEED_1, SPEED_2, SPEED_3, SPEED_4, BY_BEATS_1, BY_BEATS_2, BY_BEATS_3, BY_BEATS_4)

	if not SPEED_1 and not SPEED_2 and not SPEED_3 and not SPEED_4 then
	Error_Tooltip('\n\n no enabled scroll speed presets\n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

-- validate presets for zone allocation
-- a zone is only to be allocated to enabled presets which are not the 1st enabled preset when TCP is displayed on the left side of the Arrange and not the last enabled when it's displayed on the right side of the Arrange because these are always linked to the TCP and doesn't need a zone allocated to it
-- a preset is not the 1st enabled one as long as there's at least one enabled preset preceding it in the order in which they're listed in the USER SETTINGS and it's not the last enabled as long as at least one enabled preset follows it in such order
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local preset_t = {SPEED_1, SPEED_2, SPEED_3, SPEED_4, truth={}}
-- after the loop in the table only those slot vars will be true which aren't the 1st or not the last enabled (depending on the TCP position) because to these no zone is allocated as they're hard linked to the TCP
	for k1, pres1 in ipairs(preset_t) do -- evaluate each next preset against all preceding presets or against all following depending on which side the TCP is displayed on in Arrange view
	preset_t.truth[k1] = false
		for k2, pres2 in ipairs(preset_t) do
			if pres1 and (not right_tcp and k2 < k1 or right_tcp and k2 > k1) and pres2 then -- k2 < k1 and k2 > k1 to prevent evaluation against itself, doesn't apply to the very 1st and the very last entry because in this case k2 == k1
			preset_t.truth[k1] = true
			break end
			if not right_tcp and k2 == k1 then break end -- exit as soon as the same preset entry is selected to prevent evaluation against next preset, doesn't apply in evaluation against following presets since the evaluation only starts after k2 == k1
		end
	end

local zones = {}
	for k, truth in ipairs(preset_t.truth) do
		if truth then zones[#zones+1] = 'SPEED_'..k -- store preset name to be used as a key // creating an indexed table to be able to traverse it in ascending order below while storing zone ranges
		end
	end

local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start & screen_x_end both 0 = GET // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and stop_time should be on the screen when non-zero when isSet is true // THE TIME INCLUDES VERTICAL SCROLLBAR 17 px wide which will have to be subtracted to get the exact right edge of the time line
local arrange_h, header_h, wnd_h_offset = table.unpack(HORIZ_ZONES and {Get_Arrange_and_Header_Heights()} or {}) -- DATA FOR HORIZONTAL ZONES
local zone_size = not HORIZ_ZONES and (end_time-start_time)/#zones or arrange_h/#zones

	for k, preset in ipairs(zones) do -- associate preset name as a key with zone bounds
	zones[preset] = not HORIZ_ZONES and {start=start_time+zone_size*(k-1), fin=start_time+zone_size*k}
	or {start=zone_size*(k-1), fin=zone_size*k} -- MAY NOT WORK ON MAC since there Y axis starts at the bottom
	end


local proj_len = r.GetProjectLength(0)
local vert_scrollbar_w_sec = 17/r.GetHZoomLevel() -- in sec; vertical scrollbar which is included in the Arrange view length, is 17 px wide and must be subtracted to get true visible area size
local arrange_len_px = (end_time-start_time)*r.GetHZoomLevel()-17 -- 17 px is the width of vertical scrollbar included in the Arrange view length which must be subtracted to get true visible area size
local dir = Mouse_Wheel_Direction(MW_REVERSE)
local right = MW_REVERSE and dir < 0 or dir > 0

	if right and end_time-vert_scrollbar_w_sec >= proj_len then SPEED = 0 -- project end has been reached, accounting for vertical scrollbar which is included in the Arrange view length and is 17 px wide
	Error_Tooltip('\n\n end of project reached \n\n', 1, 1) -- caps and spaced are true
	return r.defer(no_undo) end

local TCP = Get_Mouse_TimeLine_Pos() -- targeting the TCP (no table argument)
local TCP_left = not right_tcp and (SPEED_1 and TCP and 'SPEED_1' or SPEED_2 and TCP and 'SPEED_2' or SPEED_3 and TCP and 'SPEED_3' or SPEED_4 and TCP and 'SPEED_4')
local TCP_right = right_tcp and (SPEED_4 and TCP and 'SPEED_4' or SPEED_3 and TCP and 'SPEED_3' or SPEED_2 and TCP and 'SPEED_2' or SPEED_1 and TCP and 'SPEED_1')
local pres1, pres2, pres3, pres4 = TCP_left == 'SPEED_1' or TCP_right == 'SPEED_1', TCP_left == 'SPEED_2' or TCP_right == 'SPEED_2',  TCP_left == 'SPEED_3' or TCP_right == 'SPEED_3', TCP_left == 'SPEED_4' or TCP_right == 'SPEED_4'
local disabled = pres1 and SPEED_1 == 0 or pres2 and SPEED_2 == 0 or pres3 and SPEED_3 == 0 or pres4 and SPEED_4 == 0 -- evaluate if there's a disabled preset (only relevant for the 1st or the last in the list with SPEED_n var being valid, depending on the TCP position) so that no scrolling will take place when the mouse cursor is over the TCP


function By_Beats_Scroll(arrange_len_px, SPEED)
local beat_len_in_sec = 60/r.Master_GetTempo()*SPEED
local step_len_in_px = beat_len_in_sec*r.GetHZoomLevel() -- GetHZoomLevel() returns px/sec
	if arrange_len_px/step_len_in_px < 6 then -- for ease of following the time line make sure that the arrange length equals at least 6 steps, dividing the step length until the desired resolution is achieved, this makes scrolling gradual and traceable enough
		while arrange_len_px/step_len_in_px < 6 do
		step_len_in_px = step_len_in_px/2
		end
	end
local step_len_in_px = math.floor(step_len_in_px/16+0.5) -- WORKS, NO DIVIATION SUPPORT
return step_len_in_px < 1 and 1 or step_len_in_px -- at extreme zoom-out make sure that the value never falls lower than 1, which equals 16 px in terms of CSurf_OnScroll() function as it ignores lower values
end


function validate_preset(a,b) -- validate_SPEED() doesn't filter out 0 value since it's used to disable preset over the TCP or while keeping the zone
return a and a ~= 0 and b
end

function ZONE_SCROLL(SPEED, FULL_SCROLL, PAGING_SCROLL, BY_BEATS, right, proj_len, start_time, arrange_len_px)
	if FULL_SCROLL then
	local scroll_dist_sec = not right and proj_len or proj_len-start_time
	local scroll_dist_px = scroll_dist_sec*r.GetHZoomLevel() - arrange_len_px + 17 -- '- arrange_len_px' to ensure that scrolling stops at the right side of the Arrange rather than on the left; +17 to account for vert scrollbar width already subtracted from arrange_len_px outside of the function, otherwise the scrolling stops short of the project end reaching right edge of visible Arrange area and then it can't move any further due to SPEED being assigned 0 value outside of the function
	SPEED = math.floor(scroll_dist_px/16+0.5) -- /16 since it's the smallest horizontal scroll unit in CSurf_OnScroll()
	elseif PAGING_SCROLL then
	SPEED = math.floor(arrange_len_px/16+0.5) -- /16 since its the smallest horiz scroll unit used by CSurf_OnScroll() below, 1 equals 16, round since pixel value cannot be fractional
	elseif BY_BEATS then
	SPEED = By_Beats_Scroll(arrange_len_px, SPEED)
--	else
--	SPEED = SPEED
	end
return SPEED
end


	if (TCP_left or TCP_right) and not disabled then -- targeting the TCP, 1st enabled preset is always linked to the TCP when it's displayed on the left and the last enabled is linked to it when it's displayed on the right, unless it's disabled with '0' value
	local FULL_SCROLL = pres1 and FULL_SCROLL_1 or pres2 and FULL_SCROLL_2 or pres3 and FULL_SCROLL_3 or pres4 and FULL_SCROLL_4
	local PAGING_SCROLL = pres1 and PAGING_SCROLL_1 or pres2 and PAGING_SCROLL_2 or pres3 and PAGING_SCROLL_3 or pres4 and PAGING_SCROLL_4
	local BY_BEATS = pres1 and BY_BEATS_1 or pres2 and BY_BEATS_2 or pres3 and BY_BEATS_3 or pres4 and BY_BEATS_4
	SPEED = pres1 and SPEED_1 or pres2 and SPEED_2 or pres3 and SPEED_3 or pres4 and SPEED_4
	SPEED = ZONE_SCROLL(SPEED, FULL_SCROLL, PAGING_SCROLL, BY_BEATS, right, proj_len, start_time, arrange_len_px)

	elseif validate_preset(SPEED_1, zones.SPEED_1) and (not HORIZ_ZONES and Get_Mouse_TimeLine_Pos(zones.SPEED_1) or HORIZ_ZONES and not TCP and Get_Mouse_Y_Axis_Pos(zones.SPEED_1, header_h, wnd_h_offset)) then --  'or HORIZ_ZONES' cond is required to prevent error when HORIZ_ZONES sett is disabled and the cursor is outside of the zone which will otherwise make next option, that is Get_Mouse_Y_Axis_Pos(), automatically active with header_h and wnd_h_offset vars being nil; 'not TCP' ensures that the preset won't work over the TCP when the linkage to the TCP is disabled by activating a preset earlier in the list with '0' value because horizontal zone covers the TCP as well -- here and below
	SPEED = ZONE_SCROLL(SPEED_1, FULL_SCROLL_1, PAGING_SCROLL_1, BY_BEATS_1, right, proj_len, start_time, arrange_len_px)

	elseif validate_preset(SPEED_2, zones.SPEED_2) and (not HORIZ_ZONES and Get_Mouse_TimeLine_Pos(zones.SPEED_2) or HORIZ_ZONES and not TCP and Get_Mouse_Y_Axis_Pos(zones.SPEED_2, header_h, wnd_h_offset)) then
	SPEED = ZONE_SCROLL(SPEED_2, FULL_SCROLL_2, PAGING_SCROLL_2, BY_BEATS_2, right, proj_len, start_time, arrange_len_px)

	elseif validate_preset(SPEED_3, zones.SPEED_3) and (not HORIZ_ZONES and Get_Mouse_TimeLine_Pos(zones.SPEED_3) or HORIZ_ZONES and not TCP and Get_Mouse_Y_Axis_Pos(zones.SPEED_3, header_h, wnd_h_offset)) then
	SPEED = ZONE_SCROLL(SPEED_3, FULL_SCROLL_3, PAGING_SCROLL_3, BY_BEATS_3, right, proj_len, start_time, arrange_len_px)

	elseif validate_preset(SPEED_4, zones.SPEED_4) and (not HORIZ_ZONES and Get_Mouse_TimeLine_Pos(zones.SPEED_4) or HORIZ_ZONES and not TCP and Get_Mouse_Y_Axis_Pos(zones.SPEED_4, header_h, wnd_h_offset)) then
	SPEED = ZONE_SCROLL(SPEED_4, FULL_SCROLL_4, PAGING_SCROLL_4, BY_BEATS_4, right, proj_len, start_time, arrange_len_px)
	end


	if SPEED then -- can be nil if only one preset is enabled (which is limited to the TCP) and the mouse cursor is outside of the TCP or if zone of a preset is disabled // alternatively SPEED = not SPEED and 0 could be used instead of the 'if' block
	r.CSurf_OnScroll(SPEED*dir, 0)
	end



