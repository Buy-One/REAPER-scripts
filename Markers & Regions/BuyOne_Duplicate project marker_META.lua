--[[
ReaScript name: BuyOne_Duplicate project marker_META.lua (9 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: 	[main=main,midi_editor] .
      			. > BuyOne_Duplicate project marker in time selection to edit cursor.lua
      			. > BuyOne_Duplicate project marker in time selection to mouse cursor.lua
      			. > BuyOne_Duplicate project marker at edit cursor to time selection start.lua
      			. > BuyOne_Duplicate project marker at edit cursor to mouse cursor.lua
      			. > BuyOne_Duplicate project marker at mouse cursor to time selection start.lua
      			. > BuyOne_Duplicate project marker at mouse cursor to edit cursor.lua
      			. > BuyOne_Duplicate project marker in time selection.lua
      			. > BuyOne_Duplicate project marker at edit cursor.lua
      			. > BuyOne_Duplicate project marker at mouse cursor.lua
About:	If this script name is suffixed with META, when executed 
    		it will automatically spawn all individual scripts included 
    		in the package into the directory of the META script and will 
    		import them into the Action list from that directory.  
    		If there's no META suffix in this script name it will perfom 
    		the operation indicated in its name.
    		
    		Scripts in whose name the target position of the duplicated 
    		marker isn't indicated place one at 50 px to the right of the 
    		source marker.
    		
    		Scripts which duplicate marker in time selection only respect
    		first marker found in time selection.
]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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
		-- NO USER SETTINGS
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
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed
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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found
-- only execute once
local t = {...}

	for k, elm in ipairs(t) do
		if scr_name:lower():match(Esc(elm:lower())) then return elm end -- at least one match was found
	end

end
-- USE:
--[[
local keyword = Invalid_Script_Name3(scr_name, 'right', 'left', 'up', 'down')
	if not keyword then r.defer(no_undo) end

	if keyword == 'right' then
	-- DO STUFF
	elseif keyword == 'left' then
	-- DO STUFF
	-- ETC.
	end
]]


function Parse_Script_Name(scr_name, t)
-- meant for multi-functional scripts with mutually exclusive functionalities
-- which depend on the script name, e.g.
-- move forward, move backwards, select next, select previous, etc.
-- t contains strings of key words definding functionality included in the script name
-- case agnostic
-- relies on Esc() function
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



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end



function Get_Set_Marker_Reg_In_Time_Sel_At_Edit_Mouse_Curs(mrkrs, rgns, in_time_sel, at_edit_curs, at_mouse, t, to_time_sel, to_edit_curs, to_mouse)

	local function get_mouse_curs_pos(curs_pos, at_mouse, to_mouse)

		if r.GetTrackFromPoint(r.GetMousePosition()) then -- the edit cursor is not aligned with marker or region start/end // look for these at the mouse cursor // GetTrackFromPoint() prevents this context from activation if the script is run from a toolbar or the Action list window floating over Arrange or if mouse cursor is outside of Arrange

		-- the action for setting stage must not respect snapping to allow placing marker anywhere
		local act = at_mouse and 40513 -- View: Move edit cursor to mouse cursor [with snapping so it can snap to marker / region start/end]
		or to_mouse and 40514 -- View: Move edit cursor to mouse cursor (no snapping)

		r.PreventUIRefresh(1)
		ACT(act)
		local new_cur_pos = r.GetCursorPosition()
		r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig edit curs pos
		r.PreventUIRefresh(-1)
		return new_cur_pos
		end

	end

local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false

local err = (in_time_sel or to_time_sel) and start == fin and 'no active time selection'

local curs_pos = r.GetCursorPosition()
local mouse_pos = (at_mouse or to_mouse) and get_mouse_curs_pos(curs_pos, at_mouse, to_mouse)
curs_pos = (at_mouse or to_mouse) and mouse_pos or (at_edit_curs or to_edit_curs) and curs_pos
err = err or not curs_pos and (at_mouse or to_mouse)
and 'the mouse cursor needs to be \n\n  opposite of a TCP in Arrange' -- that's due to the use of GetTrackFromPoint() as a condition to getting mouse position within get_mouse_curs_pos() function

local max_ID, t = math.huge*-1, t

	if not t and not err then -- GET

	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name, ID, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
			if not isrgn then
			max_ID = ID > max_ID and ID or max_ID
			end

			if rgns and isrgn -- regions
			and (time_sel and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin -- region start or end is within time sel
			or pos >= start and rgnend <= fin) -- whole region is within time sel
			or curs_pos and (pos == curs_pos or rgnend == curs_pos))

			or not isrgn and mrkrs -- markers
			and (in_time_sel and pos >= start and pos <= fin
			or curs_pos and pos == curs_pos)
			then
				if not t then -- only 1st marker found if time selection

				t = {idx=i, isrgn=isrgn, pos=pos, rgnend=rgnend, name=name, ID=ID, col=color}
				end
			-- OR
			-- t = t or {idx=i, isrgn=isrgn, pos=pos, rgnend=rgnend, name=name, ID=ID, col=color}
			end
		i = i+1
		until retval == 0 -- until no more markers/regions

	local refr = 'no project marker \n\n'
	err = err or not t and (in_time_sel and refr..'  in time selection' or at_edit_curs and refr..' at the edit cursor'
	or at_mouse and '  '..refr..' at the mouse cursor')

	elseif t and not err then -- SET

	local refr = 'coincides \n\n with the source marker position'
	err = to_time_sel and start == t.pos and ' time selection start '..refr
	or curs_pos == t.pos and (to_edit_curs and ' edit cursor position '..refr
	or to_mouse and 'mouse cursor position '..refr)

		if not err then

		local pos = to_time_sel and start or (to_edit_curs or to_mouse) and curs_pos or t.pos+50/r.GetHZoomLevel() -- 50 px to the right from the source marker in sec depending on the zoom level

		-- check if there's already a marker at the target position
		local markeridx, regionidx = r.GetLastMarkerAndCurRegion(0, pos) -- includes marker/region at time as well, not only before
			if markeridx > -1 then
			local retval, isrgn, mrkr_pos = r.EnumProjectMarkers3(0, markeridx)
			local targ = to_time_sel and '   (time selection start)'
			or to_edit_curs and '\t   (edit cursor)' or to_mouse and '\t (mouse cursor)'
			err = mrkr_pos == pos and 'there\'s already a marker \n\n   at the target position \n\n'..targ
			end

			if not err then
			r.AddProjectMarker2(0, false, pos, 0, t.name, t.ID+1, t.col) -- isrgn false, rgnend 0
			end

		end

	end

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 to move tooltip away from the mouse so it doesn't block clicks
	return end

	if t then t.ID = max_ID	end
return t

end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Duplicate project marker_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


local elm1 = Invalid_Script_Name(scr_name, 'in time', 'at edit', 'at mouse')
local elm2 = Invalid_Script_Name(scr_name, 'to time', 'to edit', 'to mouse')

	if not (elm1 or elm2) then -- either no keyword was found in the script name or no keyword arguments were supplied
	local err = 'The script name has been changed\n\n    which renders it inoperable. \n\n'
	..' please restore the original name\n\n\t referring to the names\n\n\t\t in the header,\n\n'
	..'\tor reinstall the package.'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo) end


local t = {'in time', 'at edit', 'at mouse', 'to time', 'to edit', 'to mouse'}
--local in_time_sel, at_edit_curs, at_mouse, to_time_sel, to_edit_curs, to_mouse = Parse_Script_Name(scr_name, t)
t = {Parse_Script_Name(scr_name, t)}

local mrkr_t = Get_Set_Marker_Reg_In_Time_Sel_At_Edit_Mouse_Curs(true, rgns, table.unpack(t,1,3)) -- mrkrs true, rgns nil // GET

	if not t then return r.defer(no_undo) end -- error messages are inside the function


r.Undo_BeginBlock()

Get_Set_Marker_Reg_In_Time_Sel_At_Edit_Mouse_Curs(true, rgns, _, _, _, mrkr_t, table.unpack(t,4,6)) -- mrkrs true, rgns nil // table.unpack needs two indices explicitly otherwise nils break it // SET

r.Undo_EndBlock(scr_name,-1)




