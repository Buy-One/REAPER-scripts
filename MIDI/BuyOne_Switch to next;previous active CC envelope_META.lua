--[[
ReaScript name: BuyOne_Switch to next;previous active CC envelope_META.lua (2 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.4
Changelog:  v1.4 #Added a menu to the META script so it's now functional as well
		 allowing to use from a single menu all options available as individual scripts
		 #Added wrong script name error message
		 #Updated About text
	    v1.3 #Fixed individual script installation function
		 #Made individual script installation function more efficient
	    v1.2 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
	    v1.1 #Added functionality to export individual scripts included in the package
		 #Updated About text
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides: 	[main=midi_editor] .
		[main=midi_editor] . > BuyOne_Switch to next active CC envelope.lua
		[main=midi_editor] . > BuyOne_Switch to previous active CC envelope.lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first. It will also display a menu
	allowing to execute all actions available as individual scripts.
	Each menu item is preceded with a quick access shortcut so
	it can be triggered from keyboard.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.

	The individual script works for the last clicked CC lane 
	if several are open.

	If next/previous active CC envelope is already open in
	another visible lane, in the active lane it's skipped. 

	If all active envelopes are already open in visible lanes
	no switching occurs.

	Also supports Pitch bend, Channel pressure and Program change
	envelopes.  
	Ignores Velocity, Off Velocity, Text events, Notation enents 
	and SySex lanes.  
	CC00-31 14 bit CC lanes currently aren't supported either.
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end
		
		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{32060} do -- MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end
		
	end

end


function CC_Evts_Exist(take)
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- Velocity / Off Velocity / Text events / Notation enents / SySex lanes are ignored
		if retval then return retval end -- as soon as a selected event is found
	evt_idx = evt_idx + 1
	until not retval
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



local _, fullpath_init, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script


-- doesn't run in non-META scripts
META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Switch to next;previous active CC envelope_META.lua', names_t)


local menu_t = {' |SWITCH TO ACTIVE CC ENVELOPE|', '&1. NEXT', '&2. PREVIOUS| '}
local META = scr_name:match('.+_META$')

::RELOAD::
local output = META and Reload_Menu_at_Same_Pos(table.concat(menu_t,'|'), 1) -- keep_menu_open true

	if output == 0 then 
	return r.defer(no_undo) -- output is 0 when the menu in the META script is clicked away from
	elseif output and (output < 3 or output > 4) then -- menu title was clicked
	goto RELOAD
	elseif output == 3 or scr_name:match(' next ') then nxt = 1
	elseif output == 4 or scr_name:match(' previous ') then prev = 1
	end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

local err = not nxt and not prev and 'wrong script name'
or r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') == -1 and '\tlast clicked cc lane \n\n'..string.rep(' ', 10)..' was\'t found. \n\n click at least one cc lane.' -- happens when a lane was closed
or not CC_Evts_Exist(take) and 'no active cc envelopes'

local installer_scr = scr_name:match('^script updater and installer') -- whether this script is run via installer script in which case get_action_context() returns the installer script path

	if err and not installer_scr then
	local x, y = r.GetMousePosition()
	local x = META and x-400 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
	r.TrackCtl_SetToolTip(('\n\n '..err..' \n\n '):upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
		if META then goto RELOAD
		else return r.defer(no_undo) end
	end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function is_CC_Env_active(ME, take) -- whether there're events
local cur_CC_lane = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') -- last clicked if several lanes are displayed, otherwise currently visible lane
local cur_CC_lane = cur_CC_lane == 513 and 224 or cur_CC_lane == 515 and 208 or cur_CC_lane == 514 and 192 or cur_CC_lane -- converting  MIDIEditor_GetSetting_int() function return values to MIDI_GetCC() chanmsg return value: pitch bend, channel pressure, program change, regular CC
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- Velocity / Off Velocity / Text events / Notation enents / SySex lanes are ignored
		if retval then
			if chanmsg == 176 and msg2 == cur_CC_lane then
			return msg2  -- -- CC message, chanmsg = 176 // as soon as event is found in the current lane
			elseif chanmsg == cur_CC_lane then -- non-CC message (chanmsg =/= 176)
			return chanmsg == 192 and 'Program change' or chanmsg == 208 and 'Channel pressure' or chanmsg == 224 and 'Pitch bend'
			end
		end
	evt_idx = evt_idx + 1
	until not retval
end


function Switch_2_Next_Prev_Active_CCLane(ME, take, lane_cnt, nxt, prev)
local i = 0
	repeat
	local comm_ID = nxt and 40234 or prev and 40235
	-- both actions skip envelopes already open in other visible lanes
	-- 40235 -- CC: Previous CC lane // after the 1st lane (Velocity) returns to 119, , ignoring 14 bit lanes; only switches to 14 lanes if one such lane is already open // 14 bit lanes contain the same envelopes as their 7 bit counterparts
	-- 40234 -- CC: Next CC lane // after the last 7 bit lane (119) returns to the 1st (Velocity), ignoring 14 bit lanes; only switches to 14 lanes if one such lane is already open
	ACT(comm_ID, 0) -- 0 here is a boolean to activate MIDI function
	local CC = is_CC_Env_active(ME, take)
		if CC then return CC end
	i = i+1
	until CC or i == lane_cnt -- 129 is the number of lanes between Velocity and 119, the actions 'CC: Next/Previous CC lane' switch to every available lane, not just CC
end


	if nxt or prev then -- won't run if the META script is executed via dofile() or loadfile() from the installer script

	r.PreventUIRefresh(1)
	r.Undo_BeginBlock()

	local CC = Switch_2_Next_Prev_Active_CCLane(ME, take, 129, nxt, prev)

	-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points, therefore Undo_Begin/EndBlock() functions must stay
	-- https://forum.cockos.com/showpost.php?p=1925555
	local item = r.GetMediaItemTake_Item(take)
	local is_item_sel = r.IsMediaItemSelected(item)
	r.SetMediaItemSelected(item, not is_item_sel) -- unset
	r.SetMediaItemSelected(item, is_item_sel) -- restore


	r.Undo_EndBlock('Switch to '..(tonumber(CC) and 'CC'..CC or CC)..' lane', -1)
	r.PreventUIRefresh(-1)
	
	if META then goto RELOAD end

	end

