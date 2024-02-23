--[[
ReaScript name: BuyOne_Create Razor edit area from cursor to mouse on envelope or item lane_META.lua (8 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog:  v1.2 #Fixed individual script installation function
		 #Made individual script installation function more efficient  
	   v1.1 #Fixed error message due to duplicate statement
		 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
Metapackage: true
Licence: WTFPL
REAPER: at least v6.24
Metapackage: true
Provides:	. > BuyOne_Create Razor edit area from cursor to mouse on any lane.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on any lane keeping existing.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on track envelope lane.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on track envelope lane keeping existing.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on track all envelope lanes.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on track all envelope lanes keeping existing.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on item lane.lua
		. > BuyOne_Create Razor edit area from cursor to mouse on item lane keeping existing.lua
About:	If this script name is suffixed with META, when executed it 
	will automatically spawn all individual scripts included in 
	the package into the directory of the META script and will 
	import them into the Action list from that directory.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name.

	The scripts refine the functionality of the native action 
	'Razor edit: Create area from cursor to mouse'
	which can create Razor edit area either on item lane only 
	or on item lane and all envelope lanes but cannot
	create Razor edit area on a single envelope lane, and it works 
	exclusively, removing any existing Razor edit areas on the track
	when the new one is being created.		

	The scripts must be run with a shortcut so that the mouse 
	cursor is free to point at a location on the timeline.
	
	If SWS/S&M extension isn't installed, the target envelope 
	must be selected, otherwise it suffices that the mouse cursor 
	point at it.
	If the extension is installed and the mouse doesn't point at 
	an envelope, a Razor edit area will be created on envelope lanes
	as long as there's selected envelope. 
	EXCEPTIONS
	1) Without the SWS extension being installed, in order to target 
	an envelope lane with the following scripts:
	Create Razor edit area from cursor to mouse on any lane.lua
	AND
	Create Razor edit area from cursor to mouse on any lane keeping existing.lua
	such envelope lane must be both selected and under the mouse.
	2) The following scripts don't require pointing mouse at the envelope
	lane (if the SWS is installed) or having at least one envelope selected
	(if the extension isn't installed), the mouse can point at an item
	lane as well:
	Create Razor edit area from cursor to mouse on track all envelope lanes.lua
	AND
	Create Razor edit area from cursor to mouse on track all envelope lanes keeping existing.lua
			
	In scripts which include 'keeping existing' verbiage in their name
	the existing Razor edit areas on the target lane (item or envelope or
	both, depending on the script designation) are retained, while
	Razor edit areas which fall between the edit and mouse cursor on the 
	target lane(s) get overwritten.
	
	When item lane is the target, if mouse cursor is over the TCP 
	the Razor edit area will be created up to the TCP. When envelope lane 
	is the target, if mouse cursor is over the ECP (envelope control panel) 
	the Razor edit area will be created up to the ECP.
	
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function no_undo()
do return end
end


function space(n) -- number of repeats, integer
return (' '):rep(n)
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

	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then
	
--[[ GETTING PATH FROM THE USER INPUT

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)
	
	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD
	
	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]	
	
		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH
		
		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
		end
		
		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0} do -- Main // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end
		
	end

end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Invalid_Script_Name(scr_name,...)
-- check if necessary elements are found in script name, case agnostic
-- if more than 1 match is needed run twice or more times with different sets of elements which are supposed to appear in the same name, but elements within each set must not be expected to appear in the same name, that is they must be mutually exclusive
-- if running twice or more times the error message and Rep() function must be used outside of this function after expression 'if no_elm1 or no_elm2 then'
local t = {...}
	for k, elm in ipairs(t) do
		if scr_name:lower():match(Esc(elm:lower())) then return end
	end
return true
end


function Parse_Script_Name(scr_name, t)
-- case agnostic
local t_len = #t -- store here since with nils length will be harder to get
	for k, elm in ipairs(t) do
	t[k] = scr_name:lower():match(Esc(elm:lower())) --or false -- to avoid nils in the table, although still works with the method below
	end
-- return table.unpack(t) -- without nils
return table.unpack(t,1,t_len) -- not sure why this works, not documented anywhere, but does return all values if some of them are nil even without the n value (table length) in the 1st field
-- found mentioned at
-- https://stackoverflow.com/a/1677358/8883033
-- https://stackoverflow.com/questions/1672985/lua-unpack-bug
-- https://uopilot.tati.pro/index.php?title=Unpack_(Lua)
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


function Get_Mouse_Pos_Sec()
r.PreventUIRefresh(1)
local cur_pos = r.GetCursorPosition() -- store current edit cur pos
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)
local mouse_pos = r.GetCursorPosition()
r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore edit cur pos
r.PreventUIRefresh(-1)
return mouse_pos
end


function Get_Vis_Env_GUID(env)
local retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
return chunk:match('\nVIS 1 ') and chunk:match('{.-}') -- OR chunk:match('EGUID (.-)\n')
end


function Exclude_Raz_Edit_Areas(raz_edit_data, start, fin, env_lane, item_lane, any_lane, env_GUID)
local capt = '[%d%.]+ [%d%.]+ '
local capt = any_lane and capt..'".-"' or env_lane and capt..'"{.-}"' or item_lane and capt..'""'
local data = ''
	for area in raz_edit_data:gmatch(capt) do
	local area_st, area_end, guid = area:match('([%d%.]+) ([%d%.]+) "(.-)"')
		if start <= area_end+0 and fin >= area_st+0
		and (not any_lane or any_lane and (env_lane and env_GUID == guid or item_lane and guid == ''))
		then -- do not exclude area which is overlapped by the one being created, that is allow overwtiring it
		else
		data = data..area
		end
	end
return data
end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.24 then
	-- in 6.24 Razor edit feature was added and 'P_RAZOREDITS' parm was added to GetSetMediaTrackInfo_String()
	Error_Tooltip('\n\n\tthe script is supported \n\n in REAPER builds 6.24 onwards \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, fullpath_init, sectionID, cmdID, mode, resolution, val = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('[^\\/_]+') -- without path, author's namee


	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Create Razor edit area from cursor to mouse on envelope or item lane_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not

--scr_name = 'any lane keeping existing.lua' --------------- NAME TESTING

local not_elm1 = Invalid_Script_Name(scr_name,'item','envelope','any')
local not_elm2 = Invalid_Script_Name(scr_name,'item lane','track envelope','track all envelope','any lane')
local not_elm3 = Invalid_Script_Name(scr_name,'lanes.lua','lane.lua','keeping existing')

	if not_elm1 or not_elm2 or not_elm3 then
	local br = '\n\n'
	local err = [[The script name has been changed]]..br..space(4)..[[which renders it inoperable.]]..br
	..space(5)..[[restore the original name]]..br..space(8)..[[referring to the list]]..br
	..'\t\t'..[[in the header.]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local item_lane, env_lane, all_env_lanes, any_lane, keeping = Parse_Script_Name(scr_name, {'item', 'envelope', 'all envelope lanes', 'any lane','keeping existing'})

local env_sel = r.GetSelectedTrackEnvelope(0)
local sws = r.APIExists('BR_GetMouseCursorContext_Envelope')
local wnd, segm, details = table.unpack(sws and {r.BR_GetMouseCursorContext()} or {}) -- must come before BR_GetMouseCursorContext_Envelope() because it relies on it
local env, takeEnv = table.unpack(sws and {r.BR_GetMouseCursorContext_Envelope()} or {})
env = env or env_sel
local tr = (item_lane or any_lane) and r.GetTrackFromPoint(r.GetMousePosition()) -- item lane must have priority because if any_lane, the cursor is over the item lane and there's selected envelope, envelope will be the target and not the item lane
or (env_lane or any_lane) and env and r.GetEnvelopeInfo_Value(env, 'P_TRACK')
or all_env_lanes and r.GetTrackFromPoint(r.GetMousePosition()) -- if mouse points at any lane

local err = env_lane and (sws and (takeEnv and '    take envelopes cannot be \n\n manipulated with Razor edits'
-- not tr condition prevents error when mouse points at item lane in 'all envelope lanes' scripts, which is a supported context
or not env and not tr and 'no visible track envelope \n\n  under mouse or selected')
or not env and not tr and 'no selected track envelope')
or item_lane and not tr and 'no track under the mouse cursor'

	if err then
	Error_Tooltip('\n\n '..err..'\n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

-- for any lane scripts
item_lane = not item_lane and not env and any_lane and tr or item_lane
env_lane = not env_lane and env and any_lane and tr or env_lane

local edit_cur_pos = r.GetCursorPosition()
local mouse_cur_pos = Get_Mouse_Pos_Sec()
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time)
mouse_cur_pos = mouse_cur_pos == edit_cur_pos and (right_tcp and end_time or 0) or mouse_cur_pos -- if mouse is over TCP, in targeting item lane
local ret, raz_edit_data = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false) -- setNewValue false
local st, fin = math.min(edit_cur_pos, mouse_cur_pos), math.max(edit_cur_pos, mouse_cur_pos)
local data = ''

	if any_lane then
	-- Create Razor edit area from cursor to mouse on any lane
	-- Create Razor edit area from cursor to mouse on any lane keeping existing
	local env_GUID = env and Get_Vis_Env_GUID(env)

		if keeping then
		data = Exclude_Raz_Edit_Areas(raz_edit_data, st, fin, env_lane, item_lane, any_lane, env_GUID)
		end

		if env and ({r.GetTrackFromPoint(r.GetMousePosition())})[2] == 1 then -- envelope is either selected or pointed at // the 2nd condition ensures that envelope lane is the target only if mouse cursor points at it even if it's selected, otherwise selected envelope with hijack the focus from item lane when the latter under the mouse
			if env_GUID then
			data = data..st..' '..fin..' "'..env_GUID..'"'
			end
		elseif tr then
		data = data..st..' '..fin..' ""'
		end

	elseif env_lane and all_env_lanes then
	-- Create Razor edit area from cursor to mouse on track all envelope lanes
	-- Create Razor edit area from cursor to mouse on track all envelope lanes keeping existing
		if keeping then
		data = Exclude_Raz_Edit_Areas(raz_edit_data, st, fin, env_lane, item_lane)
		end

		for i=0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
		local env_GUID = Get_Vis_Env_GUID(env)
			if env_GUID then
			data = data..st..' '..fin..' "'..env_GUID..'"' -- trailing separator space isn't necessary, REAPER can handle different tripples without it
			end
		end

		if #data == 0 then
		Error_Tooltip('\n\n no visible track envelopes \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end

	elseif env_lane then -- only selected or pointed at envelope
	-- Create Razor edit area from cursor to mouse on track envelope lane
	-- Create Razor edit area from cursor to mouse on track envelope lane keeping existing
	local env_GUID = Get_Vis_Env_GUID(env)

		if env_GUID then -- either selected and visible or pointed at with mouse cursor in which case it's necessarily visible; hidden envelope can't stay selected
			if keeping then
			data = Exclude_Raz_Edit_Areas(raz_edit_data, st, fin, env_lane, item_lane)
			end
		data = data..st..' '..fin..' "'..env_GUID..'"'
		end

	elseif item_lane then
	-- Create Razor edit area from cursor to mouse on item lane
	-- Create Razor edit area from cursor to mouse on item lane keeping existing		
		if keeping then
		data = Exclude_Raz_Edit_Areas(raz_edit_data, st, fin, env_lane, item_lane)
		end
	data = data..st..' '..fin..' ""'
	end

	if #data > 0 then
	r.Undo_BeginBlock()
	r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', data, true) -- setNewValue true
	r.Undo_EndBlock(scr_name:sub(1,-5), -1) -- excluding extension
	end



