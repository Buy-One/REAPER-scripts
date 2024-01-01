--[[
ReaScript name: BuyOne_Switch to next;previous active CC envelope_META.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: v1.1 #Added functionality to export individual scripts included in the package
		#Updated About text
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides: 	. > BuyOne_Switch to next active CC envelope.lua
		. > BuyOne_Switch to previous active CC envelope.lua
About:	If this script name is suffixed with META it will spawn 
	all individual scripts included in the package into 
	the directory supplied by the user in a dialogue.
	These can then be manually imported into the Action 
	list from any other location. If there's no META 
	suffix in this script name it will perfom the 
	operation indicated in its name.	

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


function META_Spawn_Scripts(fullpath, scr_name, names_t)

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

	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

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

	local user_path = Dir_Exists(output) -- validate user supplied path
		if not user_path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(user_path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
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


local _, fullpath, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext
	if scr_name:match(' next ') then nxt = 1
	elseif scr_name:match(' previous ') then prev = 1
	end
	
	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, 'BuyOne_Switch to next;previous active CC envelope_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

local err = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') == -1 and '\tlast clicked cc lane \n\n'..string.rep(' ', 10)..' was\'t found. \n\n click at least one cc lane.' -- happens when a lane was closed
or not CC_Evts_Exist(take) and 'no active cc envelopes'

	if err then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n '..err..' \n\n '):upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
	return r.defer(function() do return end end) end


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
			if chanmsg == 176 and msg2 == cur_CC_lane then return msg2  -- -- CC message, chanmsg = 176 // as soon as event is found in the current lane
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



