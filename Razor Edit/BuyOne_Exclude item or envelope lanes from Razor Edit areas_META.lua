--[[
ReaScript name: BuyOne_Exclude item or envelope lanes from Razor Edit areas_META.lua (4 scripts)
Author: BuyOne
Version: 1.3
Changelog:  v1.3 #Fixed individual script installation function
		 #Made individual script installation function more efficient 
	    v1.2 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
	    v1.1 #Added REAPER version check
		 #Corrected minimal supported version in the header
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v6.24
Metapackage: true
Provides: 	[main] . > BuyOne_Exclude item lanes from Razor Edit areas on all tracks.lua
		[main] . > BuyOne_Exclude item lanes from Razor Edit areas on selected tracks.lua
		[main] . > BuyOne_Exclude envelope lanes from Razor Edit areas on all tracks.lua
		[main] . > BuyOne_Exclude envelope lanes from Razor Edit areas on selected tracks.lua
About:	If this script name is suffixed with META, when executed it 
	will automatically spawn all individual scripts included in 
	the package into the directory of the META script and will 
	import them into the Action list from that directory.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name.

	The target lane is only excluded from a Razor Edit area
	if the area includes both item and envelope lanes, otherwise
	Razor Edit area remains intact. 
	When envelope is displayed in the item lane due to option
	'Move to media liane' being enabled, the envelope isn't excluded
	from a Razor Edit area because in this case envelope lane doesn't
	exist and usual Razor Edit operations cannot be performed on such
	envelope.
	
	The scripts:
	Exclude item lanes from Razor Edit areas on all tracks.lua
	Exclude item lanes from Razor Edit areas on selected tracks.lua
	
	Can be used inside a custom action alongside the native action
	'Razor edit: Create area from cursor to mouse'
	to only create Razor Edit area on envelope lanes because the native
	action doesn't allow isolating them, e.g.
	
	Custom: Create Razor edit area from cursor to mouse on envelope lane
		Razor edit: Create area from cursor to mouse
		Script: BuyOne_Exclude item lanes from Razor Edit areas on selected tracks.lua

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


function Exclude_From_RazEdit_Areas(want_selected_trks, envs, itms)
-- envs and itms args are indicator of the type of objects to be excluded from razor edit areas
local tr_cnt = want_selected_trks and r.CountSelectedTracks(0) or r.CountTracks(0)
local err = ' in the project'
err = tr_cnt == 0 and (want_selected_trks and 'no selected tracks \n\n   '..err or 'no tracks'..err)
local GetTrack = want_selected_trks and r.GetSelectedTrack or r.GetTrack
local raz_edit_exists, target_raz_edit
	for i = 0, tr_cnt-1 do
	local tr = GetTrack(0,i)
	local retval, raz_edit = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false) -- setNewValue false
	raz_edit_exists = #raz_edit > 0 or raz_edit_exists
	target_raz_edit = (itms and raz_edit:match('""') or envs and raz_edit:match('"{.-}"')) or target_raz_edit
	raz_edit = itms and raz_edit:match('"{.-}"') and raz_edit:gsub('[%d%.]+ [%d%.]+ ""','')
	or envs and raz_edit:match('""') and raz_edit:gsub('[%d%.]+ [%d%.]+ "{.-}"','')
		if raz_edit then
		r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', raz_edit, true) -- setNewValue true
		end
	end

local err1 = 'no razor edit areas \n\n'
local err2 = 'within razor edit areas '..(want_selected_trks and '\n\n     on selected tracks' or '')
err = err or not raz_edit_exists and (want_selected_trks and err1..'  on selected tracks' or err1..'     in the project')
or not target_raz_edit and (envs and '     no envelope lanes \n\n  '..err2 or itms and '\t  no item lanes \n\n '..err2)

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	end

end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.24 then
	-- in 6.24 Razor edit feature was added and 'P_RAZOREDITS' parm was added to GetSetMediaTrackInfo_String() 
	Error_Tooltip('\n\n\tthe script is supported \n\n in REAPER builds 6.24 onwards \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, fullpath_init, sectionID, cmdID, mode, resolution, val = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, extension and author name

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Exclude item or envelope lanes from Razor Edit areas_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not

--scr_name = 'Exclude item lanes from Razor Edit areas on all tracks' ------------------- NAME TEST

local not_elm1 = Invalid_Script_Name(scr_name, 'item', 'envelope')
local not_elm2 = Invalid_Script_Name(scr_name, 'selected tracks', 'all tracks')
local not_elm3 = Invalid_Script_Name(scr_name, 'Razor Edit')

	if not_elm1 or not_elm2 or not_elm3 then
	local br = '\n\n'
	local err = [[The script name has been changed]]..br..space(4)..[[which renders it inoperable.]]..br
	..space(5)..[[restore the original name]]..br..space(8)..[[referring to the list]]..br
	..'\t\t'..[[in the header.]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local item, envelope, selected = Parse_Script_Name(scr_name, {'item', 'envelope', 'selected'})

r.Undo_BeginBlock()

Exclude_From_RazEdit_Areas(selected, envelope, item)

r.Undo_EndBlock(scr_name,-1)


