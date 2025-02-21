--[[
ReaScript name: BuyOne_Apply next;previous TCP;MCP layout to selected tracks_META.lua (4 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962, 6.36+ recommended
Metapackage: true
Provides:	[main=main,midi_editor] .
		. > BuyOne_Apply next TCP layout to selected tracks.lua
		. > BuyOne_Apply previous TCP layout to selected tracks.lua
		. > BuyOne_Apply next MCP layout to selected tracks.lua
		. > BuyOne_Apply previous MCP layout to selected tracks.lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.

	The script name is self-explanatory.

	The Master track is supported.

	The Master track is given priority, i.e. if the Master 
	track is selected or is under mouse cursor when SYNC_TO_TRACK 
	setting is set to 2, all other selected tracks are ignored 
	and Master track layouts are cycled.	

	Cycling Master track layouts essentially cycles its Global  
	default layouts, those listed under 
	Options -> Layouts -> Master Track panel / Master Mixer panel
	which means that once its layout is switched to it will apply 
	to all new and other projects.

	If the Master track isn't selected and is not under the mouse
	cursor when SYNC_TO_TRACK setting is set to 2 the script will 
	target other selected tracks, if any.

	Master track layout change doesn't create an undo point
	due to REAPER design.

	To cycle layouts with the individual scripts in both 
	directions, use the following custom actions:

	Custom: Cycle selected tracks TCP layouts  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Apply previous TCP layout to selected tracks.lua  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Apply next TCP layout to selected tracks.lua


	Custom: Cycle selected tracks MCP layouts  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Apply previous MCP layout to selected tracks.lua  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Apply next MCP layout to selected tracks.lua


	Custom: Cycle selected tracks TCP and MCP layouts  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Apply previous TCP layout to selected tracks.lua 
		BuyOne_Apply previous MCP layout to selected tracks.lua  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Apply next TCP layout to selected tracks.lua  
		BuyOne_Apply next MCP layout to selected tracks.lua


	And map them to the mousewheel. The associaton between 
	the mousewheel scroll direction and the action type is as 
	follows: mousewheel forward/out/up - next,  
	mousewheel backward/in/down - previous. 
	To reverse the direction add action   
	'Action: Modify MIDI CC/mousewheel: Negative'  
	at the very beginning of each custom action sequence.

]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable to make the script sync layouts of all selected tracks
-- to the layout of one track so their layouts are cycled in sync
-- 1 - sync to the first selected track;
-- 2 - sync to the track at mouse cursor,
-- the mouse cursor must hover over the TCP/MCP,
-- if no track under mouse cursor, mode 1 is activated;
-- MODE 1 DOESN'T APPLY TO THE MASTER TRACK
-- MODE 2 allows to detect the Master track panel under the mouse
-- cursor, i.e. TCP or MCP depending on the script name;
-- if the setting is disabled or invalid, layouts of selected tracks
-- are cycled relative to current layout of each track while the type
-- of selected Master track layouts which are cycled depend
-- on the script name, i.e. either TCP or MCP
SYNC_TO_TRACK = ""

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


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

		if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

local names_t, content = names_t

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		------------------------------------------------------------------------------------
		-- THERE'RE USER SETTINGS OR THE META SCRIPT IS ALSO FUNCTIONAL SO FILES AREN'T UNNECESSARILY CREATED WHEN IT RUNS
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end
		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

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


function Get_TCP_MCP_Under_Mouse(want_mcp)
-- takes advantage of the fact that the action 'View: Move edit cursor to mouse cursor'
-- doesn't move the edit cursor when the mouse cursor is over the TCP;
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP;
-- master track is supported;
-- want_mcp is boolean to address MCP under mouse, supported in builds 6.36+

-- in builds < 6.36 the function also detects MCP under mouse regardless of want_mcp argument
-- because when the mouse cursor is over the MCP the action 'View: Move edit cursor to mouse cursor'
-- does move the edit cursor unless the focused MCP is situated to the left of the project start
-- which makes 'new_cur_pos == edge' expression true because the edit cursor
-- being unable to move to the mouse cursor is moved to the project start,
-- in later builds this is prevented by conditioning the return value with info:match('tcp')
-- so that the focus is solely on TCP if want_mcp arg is false

-- for builds 6.36+ where GetThingFromPoint() is supported
local tr, info = table.unpack(r.GetThingFromPoint and {r.GetThingFromPoint(r.GetMousePosition())} or {})
	if info then
	return (want_mcp and info:match('mcp') or not want_mcp and info:match('tcp')) and tr
	end

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

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end



function Apply_Next_Previous_Track_Layout(tr, layout_t, layout_type, dir, attr)

local nxt, prev = dir == 'next', dir == 'previous'
local master = tr == r.GetMasterTrack(0)
local retval, layout

	if not master then
	retval, layout = r.GetSetMediaTrackInfo_String(tr, attr, '', false) -- setNewValue false // if layout is set to 'Global default', layout val is an empty string which can't be used to apply next/previous because it's not returned by ThemeLayout_GetLayout() and so isn't included in the table; Global default layout is enabled via Options -> Layouts
	--Msg('layout before', layout)
		if #layout == 0 then -- Global default is applied, look up its actual name
		retval, layout = r.ThemeLayout_GetLayout(layout_type, -1) -- -1 to quiery current default value
	--[[	-- OR via reaper.ini
		local key = layout_type == 'TCP' and 'layout_tcp' or layout_type == 'MCP' and 'layout_mcp'
		retval, layout = r.get_config_var_string(key)
	]]
		end
	else -- with Master track current is always Global default, so essentially changing the layout changes the Global default
	retval, layout = r.ThemeLayout_GetLayout(layout_type, -1) -- -1 to quiery current default value
--[[-- OR via reaper.ini
	local key = layout_type == 'TCP' and 'layout_master_tcp' or layout_type == 'MCP' and 'layout_master_mcp'
	retval, layout = r.get_config_var_string(key)
	]]
	end

layout = #layout == 0 and layout_t[1] or layout -- if empty string or in reaper.ini no name is stored or the key is absent, the very first layout is used as default
local cur_layout_idx = layout_t[layout] or 1 -- if the returned by ThemeLayout_GetLayout() Master track Global default layout stored in reaper.ini at the key layout_master_mcp=/layout_master_tcp= belongs to another theme, layout_t[layout] will be nil in which case fall back on index 1 of the table holding current theme layouts

	if cur_layout_idx then
	layout = nxt and (layout_t[cur_layout_idx+1] or layout_t[1])
	or prev and (layout_t[cur_layout_idx-1] or layout_t[#layout_t]) -- if out of range, wrap around
		if not master then
		r.GetSetMediaTrackInfo_String(tr, attr, layout, true) -- setNewValue true
		else
		r.ThemeLayout_SetLayout(layout_type, layout) -- this will change Global default layout
		end
	return layout
	end

end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Apply next;previous MCP;TCP layout to selected tracks_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not


--scr_name = 'next track TCP' ------------------ NAME TESTING

local layout_type = scr_name:match('TCP') or scr_name:match('MCP')

local sync_type = #SYNC_TO_TRACK:gsub(' ','') > 0 and tonumber(SYNC_TO_TRACK)

-- when Master is selected all other selected tracks are ignored
local master = r.GetMasterTrack(0)
master = (r.IsTrackSelected(r.GetMasterTrack(0)) -- OR r.GetSelectedTrack2(0,0, true)
or sync_type and sync_type == 2 and Get_TCP_MCP_Under_Mouse(layout_type == 'MCP') == master) and master -- for the Master track SYNC_TO_TRACK value 2 allows to target Master track type under mouse cursor, i.e. TCP or MCP, depending on the script name
local tr_cnt = master and 1 or r.CountSelectedTracks(0)

	if tr_cnt == 0 then
	local addendum = sync_type and sync_type == 2
	and '\n\n and no Master track '..layout_type..'\n\n under the mouse cursor ' or ''
	local s = (' '):rep(4)
	Error_Tooltip('\n\n'..(#addendum>0 and s or '')..' no selected tracks '..addendum..'\n\n', 1, 1, 50) -- caps, spaced true, x2 50
	return r.defer(no_undo) end

local nxt, prev = scr_name:match('next'), scr_name:match('previous')
local attr = layout_type == 'TCP' and 'P_TCP_LAYOUT' or layout_type == 'MCP' and 'P_MCP_LAYOUT'
local layout_type = master and 'master_'..layout_type or layout_type

	if not nxt and not prev or not layout_type then
	Error_Tooltip('\n\n  script name is not recognized. \n\n please restore the original name\n\n', 1, 1, 50) -- caps, spaced true, x2 50
	return r.defer(no_undo)
	end

local i, layout_t = 0, {}

	repeat
	local retval, layout = r.ThemeLayout_GetLayout(layout_type, i) -- layout_type arg is apparently case agnostic // doesn't include 'Global Default' layout returned by GetSetMediaTrackInfo_String() as an empty string
		if retval and #layout > 0 then
		local idx = #layout_t+1
		layout_t[idx] = layout
		layout_t[layout] = idx
		end
	i = i+1
	until not retval


	if #layout_t < 2 then
	Error_Tooltip('\n\n no layouts to switch to \n\n', 1, 1, 50) -- caps, spaced true, x2 50
	return r.defer(no_undo) end


	if not master and sync_type and sync_type > 0 and sync_type < 3 then
	local tr = sync_type == 2 and Get_TCP_MCP_Under_Mouse(layout_type == 'MCP') or r.GetSelectedTrack(0,0) -- want_mcp true
	local retval, layout = r.GetSetMediaTrackInfo_String(tr, attr, '', false) -- setNewValue false // if layout is set to 'Global default' layout val is an empty string which can be passed for setting, but won't do for applying next/previous; Global default layout is enabled via Options -> Layouts
		for i = 0, tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		r.GetSetMediaTrackInfo_String(tr, attr, layout, true) -- setNewValue true
		end
	end


	if not master then r.Undo_BeginBlock() end -- Master track layout change only creates undo point once and cannot be undone probably because it's written into reaper.ini

	for i = 0, tr_cnt-1 do
	layout = Apply_Next_Previous_Track_Layout(master or r.GetSelectedTrack2(0,i,true), layout_t, layout_type, nxt or prev, attr) -- wantmaster true // when Master is selected all other selected tracks are ignored, tr_cnt is 1
		if layout and (sync_type or master or tr_cnt == 1) then
		Error_Tooltip('\n\n '..layout..' \n\n ', nil, nil, 50) -- caps, spaced nil, x2 50
		end
	end

	if not master then
	local undo = string.format('Apply %s%s layout %sto selected tracks',
	sync_type and '' or (nxt or prev)..' ', layout_type, sync_type and '"'..layout..'" ' or '')
	r.Undo_EndBlock(undo, -1)
	else
	return r.defer(no_undo)
	end













