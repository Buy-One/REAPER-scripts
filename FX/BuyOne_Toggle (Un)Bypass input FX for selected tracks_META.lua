--[[
ReaScript name: BuyOne_Toggle (Un)Bypass input FX for selected tracks_META.lua (27 scripts for various permutations)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1	#Added functionality of automatic creation and installation 
		of individual scripts. These are created in the directory the META script 
		is located in and from there are imported into the Action list.
		#Updated 'About' text
Metapackage: true
Provides: [main]
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 1 bypass for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 2 bypass for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 3 bypass for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 4 bypass for selected tracks.lua

	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 1 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 2 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 3 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 4 for selected tracks.lua

	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 1 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 2 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 3 for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 4 for selected tracks.lua

	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 1) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 2) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 3) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 4) for selected tracks.lua

	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 1) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 2) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 3) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 4) for selected tracks.lua

	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 1) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 2) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 3) for selected tracks.lua
	. > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 4) for selected tracks.lua
About: 	If this script name is suffixed with META, when executed it will automatically spawn 
	all individual scripts included in the package into the directory of the META script
	and will import them into the Action list from that directory.
	
	If there's no META suffix in this script name it will perfom the operation indicated 
	in its name.

	To complement similar actions of the SWS extension for the track main FX chain.   
	Supports Monitoring FX if the Master track is selected.  
	If slots with greater number are required, duplicate the sctipt which
	performs the desired action and change the FX slot number in its name.    	
	Toggle scripts affecting all input FX on selected tracks target each FX
	individually so their state is reversed independently of the other FX state.	

]]



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
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
		-- spawn scripts
		-- NO USER SETTINGS
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
		end
		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0} do -- Main, MIDI Ed, MIDI Evnt List, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end



local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // for META scripts with menu // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script

	-- doesn't run in non-META scripts	
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Toggle (Un)Bypass input FX for selected tracks_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

-- local scr_name = 'Unbypass input FX (except 2) for selected tracks' --------- NAME TESTING

local fx_idx = scr_name:match('input FX (%d+)') or scr_name:match('%(except (%d+)%)')
local except = scr_name:match('%(except %d+%)')
local toggle = scr_name:match('Toggle input FX')-- or scr_name:match('Toggle all input FX')
local unbypass = scr_name:match('Unbypass input FX')-- or scr_name:match('Unbypass all input')
local bypass = scr_name:match('Bypass input FX')
local fx_idx = fx_idx and 0x1000000+tonumber(fx_idx)-1

local tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true

local err = tr_cnt == 0 or not toggle and not unbypass and not bypass

	if err then
	Error_Tooltip(tr_cnt == 0 and '\n\n no selected tracks \n\n' or not toggle and not unbypass and '\n\n invalid script name \n\n')
	return r.defer(no_undo) end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local fx_cnt = 0

	for i = 0, tr_cnt-1 do -- wantmaster true
	local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
		if except then
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			fx_cnt = fx_cnt+1
				if i+0x1000000 ~= fx_idx then
				local state = toggle and not r.TrackFX_GetEnabled(tr, i+0x1000000) or unbypass and true or false
				r.TrackFX_SetEnabled(tr, i+0x1000000, state)
				end
			end
		elseif fx_idx then
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			fx_cnt = fx_cnt+1
				 if i+0x1000000 == fx_idx then found = 1 break end
			end
			if tr_cnt == 1 and not found then Error_Tooltip('\n\n no fx in slot '..(fx_idx-0x1000000+1)..' \n\n') return r.defer(no_undo) end
		local state = toggle and not r.TrackFX_GetEnabled(tr, fx_idx) or unbypass and true or false -- 'not' is meant to flip the state
		r.TrackFX_SetEnabled(tr, fx_idx, state)
		else -- all fx
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			fx_cnt = fx_cnt+1
			local state = toggle and not r.TrackFX_GetEnabled(tr, i+0x1000000) or unbypass and true or false
			r.TrackFX_SetEnabled(tr, i+0x1000000, state)
			end
		end
	end

	if fx_cnt == 0 then
	Error_Tooltip('\n\n no input fx in selected tracks \n\n')
	return r.defer(no_undo) end

r.Undo_EndBlock(scr_name, -1)
r.PreventUIRefresh(-1)





