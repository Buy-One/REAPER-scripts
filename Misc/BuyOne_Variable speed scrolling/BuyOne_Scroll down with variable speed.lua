--[[
ReaScript name: BuyOne_Scroll down with variable speed.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Fixed scrolling all the way down when BY_TRACKS setting is enabled
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
About: Alternative to the native 'View: Scroll view down' which
       doesn't allow variable scroll step size and scrolls exactly
       by tracks although not very precise when tracks have 
       different heights.

       The script's scroll unit is 8 px per execution which 
       can be increased with the SPEED setting in the USER SETTINGS.


       Bind to down arrow key (optionally with modifiers).

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert integer (whole number) between the quotes;
-- empty defaults to 8 px per one script execution,
-- otherwise the value is used as a factor
-- by which the default value (8 px) is multiplied
SPEED = ""

-- Enable by placing any alphanumeric character between the quotes,
-- only relevant for SPEED setting above,
-- if enabled, the numeric value of the SPEED setting becomes
-- the number of tracks to scroll by rather than a factor
-- to multiply pixels by, empty SPEED setting in this case equals 1;
-- doesn't have any effect if PAGING_SCROLL setting is enabled below;
-- if neither SWS/S&M or js_ReaScriptAPI extension is installed
-- will only work when the program window is maximized,
-- may not work consistently and for a second will slightly affect UX
-- when the script retrieves new data if the program window configuration changes
BY_TRACKS = ""

-- Alternative to the native
-- 'View: Scroll view vertically one page (MIDI CC relative/mousewheel)'
-- which as the name suggests only works with the mousewheel;
-- if enabled by placing any alphanumeric character
-- between the quotes, disables SPEED value and instead
-- makes the script scroll by the visible tracklist height;
-- if neither SWS/S&M or js_ReaScriptAPI extension is installed
-- will only work when the program window is maximized,
-- may not work consistently and for a second will slightly affect UX
-- when the script retrieves new data if the program window configuration changes
PAGING_SCROLL = ""

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


function Invalid_Script_Name(scr_name,...)
-- check if necessary elements are found in script name and return the one found
-- only execute once
local t = {...}

	for k, elm in ipairs(t) do
		if scr_name:match(Esc(elm)) then return elm end -- at least one match was found
	end

	local function Rep(n) -- number of repeats, integer
	return (' '):rep(n)
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end


function Is_Ctrl_And_Shift()
-- check if the script is bound to a shortcut containing both Ctrl & Shift
-- which is not advised when the version of Get_Arrange_and_Header_Heights() function is used which creates temporary project tab to fetch the Arrange height data because in this case if the key combination is long pressed a prompt will appear offering to load project with FX offline
-- only relevant if SWS and js_ReaScriptAPI extensions are not installed
-- because only in this case to get the Arrange height a track max zoom is used in a temp proj tab
local is_new_value,filename,sectID,cmdID,mode,resol,val = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmdID) -- convert numeric returned by get_action_context to alphanumeric listed in reaper-kb.ini
local res_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') -- path with separator
local s,R = ' ', string.rep
	for line in io.lines(res_path..'reaper-kb.ini') do
		if line:match('_'..named_ID) then -- in the shortcut data section command IDs are preceded with the underscore
		local modif = line:match('KEY (%d+)')
			if modif == '13' or modif == '29' then -- Ctrl+Shift or Ctrl+Shift+Alt
			r.MB(R(s,3)..'The script is bound to a shotrcut\n\n'..R(s,5)..'containing Ctrl and Shift keys.\n\n'..R(s,12)..'This will unfortunately\n\n intefere with the script performance.\n\n'..R(s,7)..'It\'s strongly advised to remap\n\n'..R(s,6)..'the script to another shortcut.\n\n\tSincere apologies!','ERROR',0)
			return true
			end
		end
	end
end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
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


local wnd_ident_t = {
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


function Detect_Docker_Pane_Change(wnd_ident_t, pos)
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
		if wnd_ident_t[v] then
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
-- fetches data from a temporary project tab, isn't ideal because of being way too intrusive, project loading process is usually visible
-- BUT is the only workable solution in the absence of extensions after botched track zoom overhaul in 6.76 https://forum.cockos.com/showthread.php?t=278646
-- if no SWS or js_ReaScriptAPI exstension only works if the program window is fully open, change in program window size isn't detected
-- only updates values when there's track or item under mouse cursor
-- the project under which the script using this function is run must be already saved to a file in order for smooth closure of the temp project tab to work because this project file is used to close the temp tab without save prompt; for edge cases a dummy project file is  generated for this purpose
-- relies on Error_Tooltip() function

local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

	if sws or js then -- if SWS/js_ReaScriptAPI ext is installed
	-- thanks to Mespotine https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/blob/master/ultraschall_api/misc/misc_docs/Reaper-Windows-ChildIDs.txt
	local main_wnd = r.GetMainHwnd()
	-- trackview wnd height includes bottom scroll bar, which is equal to track 100% max height + 17 px, also changes depending on the header height and presence of the bottom docker
	local arrange_wnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, '', 'trackview', false, true) -- search by window name // OR r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, 'REAPERTrackListWindow', '', true, false) -- search by window class name
	or js and r.JS_Window_Find('trackview', true) -- exact true // OR r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000)
	local retval, rt1, top1, lt1, bot1 = table.unpack(sws and {r.BR_Win32_GetWindowRect(arrange_wnd)}
	or js and {r.JS_Window_GetRect(arrange_wnd)})
	local retval, rt2, top2, lt2, bot2 = table.unpack(sws and {r.BR_Win32_GetWindowRect(main_wnd)} or js and {r.JS_Window_GetRect(main_wnd)})
	local top2 = top2 == -4 and 0 or top2 -- top2 can be negative (-4) if window is maximized
	local arrange_h, header_h, wnd_h_offset = bot1-top1-17, top1-top2, top2  -- !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
	return arrange_h, header_h, wnd_h_offset -- arrange_h tends to be 1 px smaller than the one obtained via calculations following 'View: Toggle track zoom to maximum height' when extensions aren't installed, using 16 px instead of 17 fixes the discrepancy
	end

-- Item condition isn't necessary, works perfectly without it // on the other hand it makes sure that there's at least one track so that ref_tr var below is valid
local x, y = r.GetMousePosition() -- the coordinates are absolute, relative to the full screen size
--local item, take = r.GetItemFromPoint(x, y, false) -- allow_locked false // item is needed to have some anchor to restore scroll state after track heights restoration, item under cursor is 100% within view so is a good reference
local track, info = r.GetTrackFromPoint(x, y)
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

	if #arrange_h == 0 or dock_change then -- pos is 0 (bottom) and 2 (top) because properties of both dockers affect Arrange height relevant in this application

	-- get 'Maximum vertical zoom' set at Preferences -> Editing behavior, which affects max track height set with 'View: Toggle track zoom to maximum height', introduced in build 6.76

	Error_Tooltip(' \n\n\t     updating data \n\n sorry about the interruption \n\n ', 1, 1) -- caps, spaced true

	local cont
		if tonumber(r.GetAppVersion():match('(.+)/')) >= 6.76 then
		local f = io.open(r.get_ini_file(),'r')
		cont = f:read('*a')
		f:close()
		end

	local max_zoom = cont and cont:match('maxvzoom=([%.%d]+)\n') -- min value is 0.125 (13%) which is roughly 1/8th, max is 8 (800%)
	local max_zoom = not max_zoom and 100 or max_zoom*100 -- ignore in builds prior to 6.76 by assigning 100 so that when track height is divided by 100 and multiplied by 100% nothing changes, otherwise convert to conventional percentage value; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is accurate, otherwise there's ±1 px diviation, because the actual track height in pixels isn't fractional like the one obtained through calculation therefore some part is lost

	-- Get Arrange and window header height
	local cur_proj, projfn = r.EnumProjects(-1) -- store cur project pointer
	-- r.PreventUIRefresh(1) -- PREVENTS GetMediaTrackInfo_Value RETURN VALUE PROBABLY BECAUSE THE HIGHT ISN'T UPDATED AFTER ACTION
	r.Main_OnCommand(41929, 0) -- New project tab (ignore default template) // open new proj tab

	-- USEFUL to be able to smoothly close temp project tab when the user's current session doesn't have an associated project file which is supposed to be used for that purpose
	local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
	local dummy_proj = scr_name:match('.+[\\/]')..'BuyOne_dummy project (do not rename).RPP'
		if projfn == '' and not r.file_exists(dummy_proj) then -- create a dummy project file next to the script
		local f = io.open(dummy_proj,'w')
		f:write('<REAPER_PROJECT\n>')
		f:close()
		end

	local projfn = projfn == '' and dummy_proj or projfn -- if no saved project in the current tab, use dummy for the new tab

	r.InsertTrackAtIndex(0, false) -- wantDefaults false
	local ref_tr = r.GetTrack(0,0)
	--	if r.GetToggleCommandStateEx(0,40113) == 0 then
		r.Main_OnCommand(40113, 0) -- View: Toggle track zoom to maximum height (i.e. height of the Arrange) // selection isn't needed, all are toggled
	--	end
	local tr_h = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPH')/max_zoom*100 -- not including envelopes, action 40113 doesn't take envs into account; calculating track height as if it were zoomed out to the entire Arrange height by taking into account 'Maximum vertical zoom' setting at Preferences -> Editing behavior
	local tr_h = math.floor(tr_h+0.5) -- round; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is integer, otherwise the calculated Arrange height is fractional because the actual track height in pixels is integer which is not what it looks like after calculation based on percentage (max_zoom) value, which means the value is rounded in REAPER internally because pixels cannot be fractional and the result is ±1 px diviation compared to the Arrange height calculated at percentages by which 100 can be divided without remainder

	r.SetExtState('ARRANGE HEIGHT','arrange_height', tr_h, false) -- persist false
	r.SetProjExtState(cur_proj, 'ARRANGE HEIGHT','arrange_height', tr_h)

	-- Close temp project tab without save prompt; when a freshly opened project closes there's no prompt
	-- the problem may emerge if the script is bound to a shortcut where Ctrl & Shift are used because this modifier combination is used to generate a prompt to load project with fx offlined, so the script shortcut must not include this combination which is ensured with the function Is_Ctrl_And_Shift(); in reaper-kb.ini KEY codes Ctrl+Shift code (the first number) seems to be consistently 13, Ctrl+Alt+Shift is 29
	r.Main_openProject('noprompt:'..projfn) -- load proj in the temp tab without save prompt
	r.Main_OnCommand(40860, 0) -- Close current (temp) project tab
	r.SelectProjectInstance(cur_proj) -- re-open orig proj tab

	local header_h = bot-tr_h-23 -- size between program window top edge and Arrange // 18 is horiz scrollbar height (regardless of the theme) and 'bot' / 'window_h' value is greater by 4 px than the actual program window height hence 18+4 = 22 has to be subtracted + 1 more pixel for greater precision in targeting item top/bottom edges
	return tr_h, header_h, 0 -- tr_h represents Arrange height, 0 is window height offset, that is screen 0 Y coordinate // return updated data

	else

	return tonumber(arrange_h), bot-arrange_h-23, 0 -- return previously stored arrange_h, header height and window height offset which is 0 when no extension is installed, that is screen 0 Y coordinate // calculation explication see above

	end

end


function Get_Combined_Tracks_Height(down, up, arrange_h, SPEED)
-- when BY_TRACKS user setting is enabled SPEED value represents the number of tracks to scroll by
local tracks_h, found = 0
local tr_cnt = r.CountTracks(0)-1 -- or r.CSurf_NumTracks(false); r.GetNumTracks()
local st, fin, step = table.unpack(down and {0, tr_cnt, 1} or up and {tr_cnt, 0, -1})
	for i = st, fin, step do
	local tr = r.GetTrack(0,i)
	local tr_y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
	local tr_h = r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl. envelopes
		if tracks_h == 0 and
		(down and tr_y > arrange_h -- first track out of sight at the bottom
		or up and tr_y < 0) -- first track out of sight at the top
		then found = i end -- tracks_h cond prevents the whole condition be true repeatedly in order to preserve index stored in found var
		if found then
		tracks_h = tracks_h+tr_h
		end
		if found and math.abs(found-i) == SPEED-1 then return math.abs(tracks_h) end -- 1st math.abs to account for negative result when the loop runs in forward direction, 2nd to rectify negative value for scrolling up because it will be multiplied by -1 outside of the function anyway; SPEED-1 because by the time the difference is equal to original SPEED value the tracks_h will have stored height if 4 tracks, e.g. when SPEED = 3 and found = 10 the forward loop should exit at i=13 because 13-10=3, but the height of the first track was already stored at 10 so by 13 it will be storing height of 4 tracks: 10,11,12,13, hence the subtraction, alternatively found = i+1 could be used or a counter which would be more straightforward
	end
return tracks_h > 0 and tracks_h*5 or 600 -- when nothing is returned from the loop because there're not enough or no tracks out of sight to satisfy the condition of equality to SPEED value // *5 or 600 are provisional values just to make sure that the tracklist is scrolled all the way down, because at the end of the tracklist there's some empty space which can still be scrolled through, upward scrolling naturally stops at the top of the topmost track
end


function Calc_and_Store_Diviation(val, diviation, ext_state_sect, ext_state_key)
-- to account for scroll drifting due to division by 8 and rounding
local int, fract = math.modf(val)
local SPEED = math.floor(val+diviation+0.5) -- round since pixel value cannot be fractional
local fract = SPEED <= int and fract or SPEED > int and fract*-1 -- if SPEED ends up greater after rounding the fractional part will have to be subtracted in the next run during rounding to maintain balance, otherwise - added
r.SetExtState(ext_state_sect, ext_state_key, fract, false) -- persist false // store diviation to adjust the value by in the next run; the scroll still drifts but much more slowly
return SPEED
end


local is_new_value,scr_name,sectID,cmdID,mode,resol,val = r.get_action_context()
local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

local keyword = Invalid_Script_Name(scr_name,' down ',' up ')

	if not keyword then return r.defer(no_undo)
	elseif not sws and not js and Is_Ctrl_And_Shift() then return r.defer(no_undo) -- prevent using script with Ctrl+Shift modifier when no extension is installed since it's likely to interfere with loading temporary project to get updated Arrange height from track max zoom as this will generate prompt to load project with fx offline; this will be true regardless of existence of any alternative shortcuts, if more than one is assigned, because it's impossible to determine which one is used to run the script // ONLY RELEVANT FOR DOWN/UP
	end

local down, up = keyword == ' down ', keyword == ' up '

SPEED = (not tonumber(SPEED) or tonumber(SPEED) and (#SPEED:gsub(' ','') == 0 or SPEED + 0 == 0)) and 1 or math.floor(math.abs(tonumber(SPEED))) -- ignoring non-numerals, zero, any decimal and negative values
BY_TRACKS = #BY_TRACKS:gsub(' ','') > 0
PAGING_SCROLL = #PAGING_SCROLL:gsub(' ','') > 0

	if PAGING_SCROLL then
	local diviation = r.GetExtState(cmdID, 'paging scroll diviation')
	local diviation = #diviation > 0 and diviation or 0
	local tracklist_h = Get_Arrange_and_Header_Heights()/8 -- only the 1st return value is used, arrange height //  /8 since its the smallest vert scroll unit used by CSurf_OnScroll() below, 1 equals 8
	SPEED = Calc_and_Store_Diviation(tracklist_h, diviation, cmdID, 'paging scroll diviation')
	elseif BY_TRACKS then
	local diviation = r.GetExtState(cmdID, 'by-track diviation')
	local diviation = #diviation > 0 and diviation or 0
	local arrange_h = Get_Arrange_and_Header_Heights() -- only the 1st return value is used, arrange height
	local tracks_h = Get_Combined_Tracks_Height(down, up, arrange_h, SPEED)/8
	SPEED = Calc_and_Store_Diviation(tracks_h, diviation, cmdID, 'by-track diviation')
	end


local dir = down and 1 or up and -1
r.CSurf_OnScroll(0, SPEED*dir)







