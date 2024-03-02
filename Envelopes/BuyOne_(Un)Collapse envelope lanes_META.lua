--[[
ReaScript name: BuyOne_(Un)Collapse envelope lanes_META.lua (18 scripts)
Author: BuyOne
Version: 1.8
Changelog:  v1.8 #Added a menu to the META script so it's now functional as well
		 allowing to use from a single menu all options available as individual scripts
		 #Updated About text
	    v1.7 #Added error messages
		 #Made sure that invisible envelopes are ignored
		 #Fixed behavior of script
		 Toggle collapse selected envelope lane or all lanes in selected tracks.lua
	    v1.6 #Fixed behavior of scripts
		 (Toggle) (Un)Collapse selected envelope lane or all lanes in selected tracks.lua
		 #Updated About text
	    v1.5 #Fixed individual script installation function
		 #Made individual script installation function more efficient
	    v1.4 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
	    v1.3 #Added functionality to export individual scripts included in the package
		 #Updated About text
	    v1.2 #Added support for theme's default uncollapsed height if starts out from collapsed state
	    v1.1 #Fixed bug of un-arming envelope
		 #Added a screenshot
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/(Un)Collapse%20envelope%20lanes.gif
REAPER: at least v5.962  		
Metapackage: true
Provides: 	. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane uncollapse others in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane collapse others in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Alternate collapsing selected envelope lane and other lanes in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse all envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse all envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse all envelope lanes in selected tracks.lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first. It will also display a menu
	allowing to execute all actions available as individual scripts.
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.

	In these '(un)collapse envelope lane' scripts 
	'track envelope' means envelope of TCP controls, those 
	which are listed in the 'trim' (envelope) button context 
	menu or under 'Track Envelopes' heading in the track 
	envelope panel, including Send envelopes.  
	
	'FX envelope' means envelope of a track FX control.  
	With toggle scripts uncollapsed state gets priority, so
	if at least one envelope lane in selected tracks is 
	uncollapsed, it will be collapsed while collapsed lanes 
	will stay as they are.  
	
	Unidirectional scripts will always work according to their name.
	
	If there're no lanes to collapse or uncollapse nothing will happen.  
	
	In toggle scripts the uncollapsed state gets priority 
	meaning that if at least one envelope lane in selected tracks
	is uncollapsed the state of all is considered uncollapsed
	and the script collapses them. 
	
	The scripts 
	(Toggle) (Un)Collapse selected envelope lane or all lanes in selected tracks.lua
	in tracks with no selected envelope lane all lanes are affected
	while in track with selected envelope lane this lane is the
	only one affected.
	
	The scripts don't support creation of undo point due 
	to REAPER internal design. 		

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- This setting is only relevant for envelope lanes which are fully collapsed
-- before the script is first run and there're no previously stored data
-- of such lanes height. Such data are saved with the project file and is
-- available across project sessions.
-- If empty or malfromed defaults to theme's default uncollapsed height

DEFAULT_UNCOLLAPSED_HEIGHT = ""

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

		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
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


function Is_Envelope_Vis(env)
-- in REAPER builds prior to 7.06 CountTrack/TakeEnvelopes() lists ghost envelopes when fx parameter modulation was enabled at least once without the parameter having an active envelope, hence must be validated with CountEnvelopePoints(env) because in this case there're no points; ValidatePtr(env, 'TrackEnvelope*'), ValidatePtr(env, 'TakeEnvelope*') and ValidatePtr(env, 'Envelope*') on the other hand always return 'true' therefore are useless
	if env and tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
	and r.CountEnvelopePoints(env) > 0
	or env then
	local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	return env_chunk:match('\nVIS 1 ')
	end
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


function Get_Envcp_Min_Height(ext_state_sect, env, cond) -- required to condition toggle and storage of current env lane height

local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
local env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT 1.0') -- passing 1 sets envcp to its minimum (collapsed) height
r.SetEnvelopeStateChunk(env, env_chunk_new, false) -- isundo false
local min_height = r.GetEnvelopeInfo_Value(env, 'I_TCPH') -- chunk LANEHEIGHT val corresponds to value of the I_TCPH parameter, NOT of the I_TCPH_USED one
r.SetEnvelopeStateChunk(env, env_chunk, false) -- isundo false // restore chunk
local store = cond and r.SetExtState(ext_state_sect, 'envcp_min_h', min_height, false) -- persist false // store
return min_height

end


function Is_Any_Autom_Lane_UnCollapsed_And_Min_Height(ext_state_sect, scr_mode3, scr_mode4, scr_mode5, scr_mode6, theme_changed, envcp_min_h_stored, sel_env, par_tr)
local envcp_min_h
local cond = #envcp_min_h_stored == 0 or theme_changed
local envcp_min_h_stored = tonumber(envcp_min_h_stored)
	for i = 0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0, i, true) -- wantmaster true
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local tr_env = r.GetTrackEnvelope(tr, i)
		local is_fx_env = Is_Track_Envelope_FX_Envelope(tr, tr_env)
			if scr_mode3 and (tr_env == sel_env or par_tr ~= tr) -- only respect selected env, otherwise any env
			or scr_mode4 and not is_fx_env
			or scr_mode5 and is_fx_env
			or scr_mode6 then
			local env_h = r.GetEnvelopeInfo_Value(tr_env, 'I_TCPH')
			envcp_min_h = cond and not envcp_min_h and Get_Envcp_Min_Height(ext_state_sect, tr_env, cond) or envcp_min_h_stored or envcp_min_h -- ensure that Get_Envcp_Min_Height() function only runs once during the loop
				if env_h > envcp_min_h then
				return true, envcp_min_h end
			end
		end
	end
return false, envcp_min_h
end


function Un_Collapse_Envelope_Lane(env, envcp_min_h, is_uncollapsed)
local env_h = r.GetEnvelopeInfo_Value(env, 'I_TCPH')
local retval, env_h_data = r.GetSetEnvelopeInfo_String(env, 'P_EXT:height', '', false) -- setNewValue false
local uncollapse_px	= env_h <= envcp_min_h and not is_uncollapsed and env_h_data -- either uncollapse or collapse // 24 is minimum possible in v5 default theme, 27 in v6 // is_uncollapsed is for toggle script instances to make sure that if at least one env lane is uncollapsed only collapse action is possible // if envelope starts out collapsed before any height data is stored env_h_data var is an empty string
local store = (toggle or unidir_collapse) and env_h > envcp_min_h and r.GetSetEnvelopeInfo_String(env, 'P_EXT:height', env_h, true) -- setNewValue true // store current env lane height // do not store when unidir_uncollapse so multiple script runs don't store the new value in the background // the condition is applied here because for some reason the data aren't stored in 'toggle and not uncollapse_px or unidir_collapse' block below without it
local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
local LANEHEIGHT = env_chunk:match('LANEHEIGHT.-\n')
local env_chunk_new
local is_uncollapsed -- for alternating script instances
	if toggle and not uncollapse_px or unidir_collapse then -- collapse
	env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT 1.0') -- 1.0 ensures that envcp gets collapsed fully
	elseif uncollapse_px and (toggle or unidir_uncollapse) -- uncollapse
	then
	local uncollapse_px = #uncollapse_px == 0 and DEFAULT_UNCOLLAPSED_HEIGHT or uncollapse_px -- if no previously stored data, use default/user setting
	env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT '..uncollapse_px)
	is_uncollapsed = 1 -- for alternating script instances
	end
local update = env_chunk_new and r.SetEnvelopeStateChunk(env, env_chunk_new, false) -- isundo false
return is_uncollapsed -- for alternating script instances
end


function Is_Track_Envelope_FX_Envelope(tr, env)
	for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
		for parm_idx = 0, r.TrackFX_GetNumParams(tr, fx_idx)-1 do
		local fx_env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create
			if fx_env == env then return true end
		end
	end
end


local _, fullpath_init, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script
local ext_state_sect = '(Un)Collapse envelope lanes' -- extended state will be shared by all script instances


-- doesn't run in non-META scripts
META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_(Un)Collapse envelope lanes_META.lua', names_t)

DEFAULT_UNCOLLAPSED_HEIGHT = DEFAULT_UNCOLLAPSED_HEIGHT:gsub(' ','')
DEFAULT_UNCOLLAPSED_HEIGHT = tonumber(DEFAULT_UNCOLLAPSED_HEIGHT) and DEFAULT_UNCOLLAPSED_HEIGHT or 0--63 -- 0 sets env lane height to theme's default from both collapsed and uncollapsed states, but in the script it's only relevant when the script is first run while the lane is collapsed

local theme_stored = r.GetExtState(ext_state_sect, 'theme_cur')
local theme_cur = r.GetLastColorThemeFile():match('.+[\\/](.+)')
local theme_changed = theme_stored ~= theme_cur
	if theme_changed then
	r.SetExtState(ext_state_sect, 'theme_cur', theme_cur, false) -- persist false
	end

local META = scr_name:match('.+_META$')
local indiv_script = scr_name:match(' envelope ')
local p = '|'
local names_t = {('COLLAPSE'):gsub('.','%0 ')..p, -- the pipe must follow spacing out instead of being included in the subtitle to prevent creation of an empty line
'Collapse selected envelope lane in track',
'Collapse selected envelope lane or all lanes in selected tracks',
'Collapse selected envelope lane uncollapse others in track',
'Collapse track envelope lanes in selected tracks',
'Collapse FX envelope lanes in selected tracks',
'Collapse all envelope lanes in selected tracks|',
('UNCOLLAPSE'):gsub('.','%0 ')..p,
'Uncollapse selected envelope lane in track',
'Uncollapse selected envelope lane or all lanes in selected tracks',
'Uncollapse selected envelope lane collapse others in track',
'Uncollapse track envelope lanes in selected tracks',
'Uncollapse FX envelope lanes in selected tracks',
'Uncollapse all envelope lanes in selected tracks|',
'Alternate collapsing selected envelope lane and other lanes in track|',
('TOGGLE'):gsub('.','%0 ')..p,
'Toggle collapse selected envelope lane in track',
'Toggle collapse selected envelope lane or all lanes in selected tracks',
'Toggle collapse track envelope lanes in selected tracks',
'Toggle collapse FX envelope lanes in selected tracks',
'Toggle collapse all envelope lanes in selected tracks| '
}

function remove_redundancy(t)
local t2 = {}
	for k, v in ipairs(t) do
	t2[k] = v:gsub('Collapse ',''):gsub('Uncollapse ',''):gsub('Toggle ','')
	end
return t2
end

::RELOAD::

local output = META and Reload_Menu_at_Same_Pos(table.concat(remove_redundancy(names_t),'|'), 1) -- keep_menu_open 1, true
or indiv_script

	if output == 0 then return r.defer(no_undo) end -- output is 0 when the menu in the META script is clicked away from

scr_name = META and names_t[output] or scr_name

	if META and not scr_name:match('envelope') then goto RELOAD end -- menu subtitle or empty line was clicked in a META script, META condition makes sure that the statement is only true when the META script is run directly, otherwise when it's run from the installer script this would create an endless loop because scr_name:match('envelope') would be false due to installer script path being returned by get_action_context()

local scr_name = scr_name:lower()
-- conditions to set unidirectional or toggle operation
toggle = scr_name:match('toggle') or scr_name:match('alternate')
unidir_collapse = not toggle and scr_name:match('^collapse')
unidir_uncollapse = not toggle and scr_name:match('^uncollapse')

local scr_mode1 = scr_name:match('selected envelope')
--[[covers:
(Un)Collapse selected envelope lane in track
Toggle collapse selected envelope lane in track
]]
local scr_mode2 = scr_name:match('other') -- 2 complements 1
--[[covers:
(Un)Collapse selected envelope lane (un)collapse others in track
 Alternate collapsing selected envelope lane and other lanes in track
]]
local scr_mode3 = scr_name:match('all lanes') -- 3 bridges between 1 and 4-6
--[[covers:
(Un)Collapse selected envelope lane or all lanes in selected tracks
Toggle collapse selected envelope lane or all lanes in selected tracks
]]
local scr_mode4_6 = scr_name:match('selected tracks') -- 4_6 complements 4-6
-- 4, 5, 6 are mutually exclusive
local scr_mode4 = scr_name:match('track envelope')
--[[covers:
(Un)Collapse track envelope lanes in selected tracks
Toggle collapse track envelope lanes in selected tracks
]]
local scr_mode5 = scr_name:match('fx envelope')
--[[covers:
(Un)Collapse FX envelope lanes in selected tracks
Toggle collapse FX envelope lanes in selected tracks
]]
local scr_mode6 = scr_name:match('all envelope')
--[[covers:
(Un)Collapse all envelope lanes in selected tracks
Toggle collapse all envelope lanes in selected tracks
]]

local installer_scr = scr_name:match('^script updater and installer') -- whether this script is run via installer script in which case get_action_context() returns the installer script path

	-- error if script name was changed beyond recognition
	-- unless the script is run from the installer script
	-- in which case get_action_context() returns installer script path
	if not installer_scr and not toggle
	and not unidir_collapse and not unidir_uncollapse and not scr_mode1
	and not scr_mode2 and not scr_mode2 and not scr_mode4_6
	and not scr_mode4 and not scr_mode5 and not scr_mode6 then
		function rep(n) -- number of repeats, integer
		return (' '):rep(n)
		end
	local br = '\n\n'
	r.MB([[The script name has been changed]]..br..rep(7)..[[which renders it inoperable.]]..br..
	[[   please restore the original name]]..br..[[  referring to the list in the header,]]..br..
	rep(9)..[[or reinstall the package.]], 'ERROR', 0)
	return r.defer(no_undo) end


	if not installer_scr and not r.GetSelectedTrack(0,0) then
	local x = META and -500 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
	Error_Tooltip('\n\n no selected tracks \n\n', 1, 1, x) -- caps, spaced are true
		if META then goto RELOAD
		else return r.defer(no_undo) end
	end


local env = r.GetSelectedEnvelope(0)
local par_tr = env and r.GetEnvelopeInfo_Value(env, 'P_TRACK') -- get selected env parent track

local env_cnt = 0

	if scr_mode3 and not env or scr_mode4_6	then
	local envcp_min_h_stored = r.GetExtState(ext_state_sect, 'envcp_min_h')
	local is_uncollapsed, envcp_min_h = Is_Any_Autom_Lane_UnCollapsed_And_Min_Height(ext_state_sect, scr_mode3, scr_mode4, scr_mode5, scr_mode6, theme_changed, envcp_min_h_stored, env, par_tr) -- condition collapsing all lanes of selected tracks if at least one lane is uncollapsed // not vice versa to ensure that uncollapsed lane height is stored as it's designed to only get stored before collapsing
	local is_uncollapsed = toggle and is_uncollapsed -- make this var only relevant for toggle scripts to allow non-toggle ones work one way regardless of differences between env lanes height (collapsed vs uncollapsed)

	r.PreventUIRefresh(1) -- must be placed after Is_Any_Autom_Lane_UnCollapsed_And_Min_Height() which includes Get_Envcp_Min_Height() function because it prevents changing envcp height and getting the minimum height value via chunk

		for i = 0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
		local tr = r.GetSelectedTrack2(0, i, true) -- wantmaster true
			for i = 0, r.CountTrackEnvelopes(tr)-1 do
			local tr_env = r.GetTrackEnvelope(tr, i)
				if Is_Envelope_Vis(tr_env) then
				env_cnt = env_cnt + 1
				local is_fx_env = Is_Track_Envelope_FX_Envelope(tr, tr_env)
					if scr_mode3 and (tr_env == env or par_tr ~= tr) -- only affect selected env, if any, otherwise all envs
					or scr_mode4 and not is_fx_env
					or scr_mode5 and is_fx_env
					or scr_mode6 then
					Un_Collapse_Envelope_Lane(tr_env, envcp_min_h, is_uncollapsed)
					end
				end
			end
		end

	r.PreventUIRefresh(-1) -- same

		if env_cnt == 0 then
		local x = META and -500 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
		Error_Tooltip('\n\n no visible envelopes \n\n', 1, 1, x) -- caps, spaced are true
		end

	elseif scr_mode1 and env and par_tr and par_tr ~= 0 then -- the selected envelope isn't take envelope
	local envcp_min_h_stored = r.GetExtState(ext_state_sect, 'envcp_min_h')
	local cond = #envcp_min_h_stored == 0 or theme_changed -- not stored or the stored val is outdated due to theme change
	local envcp_min_h = cond and Get_Envcp_Min_Height(ext_state_sect, env, cond) or tonumber(envcp_min_h_stored)
	-- If after switching to another theme its def_uncollapsed_h value differs but the previous theme value is already stored in the envelope extension data P_EXT, the latter will be used; the current theme value will only be relevant for newly created or re-created envelopes
	r.PreventUIRefresh(1) -- must be placed after Get_Envcp_Min_Height() function as it prevents changing envcp height and getting the minimum height value via chunk
	local is_uncollapsed = Un_Collapse_Envelope_Lane(env, envcp_min_h)
		if scr_mode2 then
		-- 1st two conditions are for alternating unidirectional script instances
		if not is_uncollapsed and unidir_collapse then unidir_collapse, unidir_uncollapse = x, 1 -- x is nil
		elseif not toggle then unidir_collapse, unidir_uncollapse = 1, x
		-- condition for alternating toggle script instance to prevent collapse of all when all are uncollapsed
		elseif not is_uncollapsed then toggle, unidir_uncollapse = x, 1
		end
			for i = 0, r.CountTrackEnvelopes(par_tr)-1 do
			local tr_env = r.GetTrackEnvelope(par_tr, i)
			local act = tr_env ~= env and Un_Collapse_Envelope_Lane(tr_env, envcp_min_h, is_uncollapsed)
			end
		end
	r.PreventUIRefresh(-1) -- same

	elseif scr_mode1 then

	local x = META and -500 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
	Error_Tooltip('\n\n no selected track envelope \n\n', 1, 1, x) -- caps, spaced are true

	end

	if META then goto RELOAD
	else
	return r.defer(no_undo) -- TCP/EnvCP height changes cannot be undone even if they're registered in the undo history, native actions affecting TCP height don't even create undo points https://forums.cockos.com/showthread.php?t=262356 // must be placed outside of the block because at its end only the second condition is covered
	end






