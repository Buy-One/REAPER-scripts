--[[
ReaScript name: BuyOne_Mixer navigation presets_META.lua (17 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main] .
			 . > BuyOne_Mixer navigation preset 1 (per project).lua
			 . > BuyOne_Mixer navigation preset 2 (per project).lua
			 . > BuyOne_Mixer navigation preset 3 (per project).lua
			 . > BuyOne_Mixer navigation preset 4 (per project).lua
			 . > BuyOne_Mixer navigation preset 5 (per project).lua
			 . > BuyOne_Mixer navigation preset 6 (per project).lua
			 . > BuyOne_Mixer navigation preset 7 (per project).lua
			 . > BuyOne_Mixer navigation preset 8 (per project).lua
			 . > BuyOne_Mixer navigation preset 1 (global).lua
			 . > BuyOne_Mixer navigation preset 2 (global).lua
			 . > BuyOne_Mixer navigation preset 3 (global).lua
			 . > BuyOne_Mixer navigation preset 4 (global).lua
			 . > BuyOne_Mixer navigation preset 5 (global).lua
			 . > BuyOne_Mixer navigation preset 6 (global).lua
			 . > BuyOne_Mixer navigation preset 7 (global).lua
			 . > BuyOne_Mixer navigation preset 8 (global).lua
			 . > BuyOne_Mixer navigation presets (menu).lua
About: 	If this script name is suffixed with META, when
		executed it will automatically spawn all individual
		scripts included in the package into the directory
		of the META script and will import them into the
		Action list from that directory.  
		For global preset scripts this is only true if the
		scripts don't exist yet. If they do, then in order 
		to recreate them they have to be deleted from the 
		disk first.

		If there's no META suffix in this script name it 
		will perfom the operation indicated in its name.

		The scripts allow saving and recalling Mixer scroll
		position for quick navigation between tracks, because
		built-in Track view sets only allow saving tracklist
		scroll position in Arrange.

		SAVING A PRESET

		To save a navigation preset, scroll the Mixer so that
		the track which will serve as the navigation target 
		becomes the leftmost fully visible track. If the 
		visible tracks in the Mixer are too few to allow
		scrolling the desired track to the leftmost position 
		and you still intend to save a preset planning
		to increase the track count going forward (because
		if scrolling isn't possible due to low track count
		there's not much sense in saving the navigation preset)
		what you can do is float the Mixer window if its 
		currently docked) and shrink it so scrolling becomes
		possible with the current track count.

		The name of track saved in a per project preset is
		irrelevant.

		A global type navigation preset can alternatively be 
		saved by simply adding the target track name to the 
		TRACK_NAME setting in the script USER SETTINGS.

		RESETTING A PRESET

		Close the Mixer and run the preset script.

		UPDATING A PRESET

		In order to update a preset it must be reset first
		as described in the previous paragraph.

		A global type navigation preset can alternatively be 
		updated by simply changing the target track name in 
		the TRACK_NAME setting in the script USER SETTINGS.

		RECALLING A PRESET

		Run the preset script to scroll the target track to
		the leftomst position in the Mixer, provided there's 
		enough scrolling space. With global presets, if 
		there're multiple tracks which satisfy the TRACK_NAME 
		setting they will be cycled through.  
		If the target track is inside a collapsed folder its 
		last visible parent track will be scrolled to the 
		leftomst position in the Mixer. 
		Track which is close to the tracklist end and cannot 
		be scrolled to the leftmost position will be selected
		to heighlight it.

		PRESETS MENU SCRIPT

		In the script 'BuyOne_Mixer navigation presets (menu).lua'
		all presets are listed as a menu. The contents of the 
		Global presets menu depend on the physical presence 
		of global preset scripts on the disk in the directory
		of the menu script which is supposed to be the same as 
		the directory of the META script.  
		Menu items of non-empty 'per project' presets end with
		a dot. Menu items of non-empty global presets include
		the track name and the hashtag sign # if STRICT_MATCH
		setting in the corresponding script is enabled.  
		When Mixer scroll position matches the preset, the 
		preset item is checkmarked in the menu.

		A WORKFLOW TIP

		Besides being able to navigate the open Mixer with the 
		preset scripts alone, these can be included in a double
		duty custom action based on the following template. When 
		the Mixer is closed the custom action will open it and 
		activate the preset, when the Mixer is open it will only
		activate the preset:

		Custom: Activate Mixer navigation preset 1 (per project)	
			Action: Skip next action, set CC parameter to relative +1 if action toggle state enabled, -1 if disabled, 0 if toggle state unavailable.  
			View: Toggle mixer visible  
			Action: Skip next action if CC parameter >0/mid  
			View: Toggle mixer visible  
			BuyOne_Mixer navigation preset 1 (per project).lua

		OR

		Custom: Activate Mixer navigation preset 1 (global)  
			Action: Skip next action, set CC parameter to relative +1 if action toggle state enabled, -1 if disabled, 0 if toggle state unavailable.  
			View: Toggle mixer visible  
			Action: Skip next action if CC parameter >0/mid  
			View: Toggle mixer visible  
			BuyOne_Mixer navigation preset 1 (global).lua

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- This setting can be managed manually here
-- or by running the script when the conditions
-- described in the 'About' text in the script
-- header are met
TRACK_NAME = ""


-- Enable by inserting any alphanumeric acharacter
-- between the quotes for the script to search
-- for track(s) whose label matches TRACK_NAME
-- setting exactly;
-- if disabled the script with search for tracks
-- which include the text specified
-- in the TRACK_NAME setting
STRICT_MATCH = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end



local r = reaper


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- ONLY NEEDED IF SCRIPTS INSTALLATION PATH IS PROVIDED BY THE USER, which is disabled in this function and META script path is used automatically
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
	local sep = path:match('[\\/]')
		if not sep then
			-- if path is disk root where the separator isn't listed, use forward slash, which should work on Windows as well
			if path:match('^%u:$') then sep = '/'
			else return -- likely not a string representing a path
			end
		end
	path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed so the path is properly formatted for io.open() and os.rename()
	local OS = r.GetAppVersion()
	local win = not OS:match('/') or OS:match('/x')
		if win then
		local _, mess = io.open(path)
		return #path:gsub('[%c%.]', '') > 0 and mess and mess:match('Permission denied') and path..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
		else
		local ok, mess, code = os.rename(path, path)
		return (ok or code == 13) and path..sep -- 13 is error code for 'exists but permission denied' on some systems
		end
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

	local path = fullpath:match('(.+[\\/])')

	------------------------------------------------------------------------------------
	local content_proj_menu = content:gsub('\n%-.-USER SETTINGS.-END OF USER SETTINGS.-\n.-\n', '', 1) -- create a version of script code for per project preset scripts, i.e. without user settings
		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
		local per_proj_menu = scr_name:match('per project') or scr_name:match('menu')
			if not r.file_exists(path..scr_name) or per_proj_menu then -- only spawn global preset script if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script // per project scripts and menu script are allowed to be recreated even when exist because they don't include USER SETTINGS
			local content = per_proj_menu and content_proj_menu or content
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
			for _, sectID in ipairs{0} do -- Main // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end




function no_undo()
do return end -- unnecessary
end


-- checkmarking menu items when setting is enabled
function check(sett)
return sett and '!' or ''
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
end


function space(num)
return tonumber(num) and (' '):rep(num) or ''
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
-- caps and spaced are booleans, caps doesn't apply to non-ANSI characters
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
--[[ IF USING WITH gfx
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 arguments which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the gfx window
]]
local text = caps and text:upper() or text
local utf8 = '[\0-\127\194-\244][\128-\191]*'
local text = spaced and text:gsub(utf8,'%0 ') or text -- supporting UTF-8 char
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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest instance of a particular character at the start of a menu item
-- can be used as a shortcut provided this character is unique in the menu
-- in this case they don't have to be preceded with ampersand '&'
-- if it's not unique, inputting it from keyboard will select
-- the menu item starting with this character
-- and repeated input will oscilate the selection between menu items
-- which start with it without actually triggering them
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest instance at the start of a menu item
-- some characters still do need ampresand, e.g. < and >;
-- characters which aren't the first in the menu item name
-- must also be explicitly preceded with ampersand

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and keep_menu_open) and gfx.init('', 0, 0)
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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found;
-- if elements are patterns or contain patterns Esc() function
-- in scr_name:lower():match(Esc(elm:lower())) should not be used

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(elm:lower()) then return elm end -- at least one match was found
		end
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



function Get_First_Fully_Visible_MCP() -- used inside Store_Clear_Recall_Preset(), Scroll_To_Next_Global_Preset_Match() and main routine
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local X = r.GetMediaTrackInfo_Value(tr, 'I_MCPX')
		if r.IsTrackVisible(tr, true) -- mixer true // ensures that the MCP is not hidden
		and r.CSurf_TrackToID(tr, true) ~= -1 -- mixer true // ensures that the MCP is not inside a collapsed folder, because if an MCP is in a collapased folder its original I_MCPX value is maintained, simple visibility evaluation with r.IsTrackVisible(tr, true) will result in false positive and a track inside a collapsed folder which precedes the actual first visible MCP will be resurned instead
		and X >= 0 then -- first fully visible on the left
		return tr
		end
	end
end



function Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr) -- used inside Store_Clear_Recall_Preset(), Find_Next_Global_Preset_Match()
-- NO CHUNK IS REQUIRED, ONLY FOR TRACKS 100% VISIBLE IN THE MIXER
-- AS when mcpView is true CSurf_TrackToID() returns -1 for both, hidden completely
-- and hidden in a collapsed folder in the Mixer
local parent = r.GetParentTrack(tr)
local tr_vis = r.IsTrackVisible(tr, true) -- mixer true
	if tr_vis then
		if parent and r.CSurf_TrackToID(tr, true) == -1 -- mcpView true // the function doesn't return index if track is inside a collapsed folder in the Mixer, and since tr is certainly visible, this means that it's certainly inside a visible collapsed folder, because in the Mixer child track in a collapsed folder cannot be visible while its parent is itself hidden
		then return Get_Parent_Of_MCP_First_Uncollapsed_Folder(parent), 1 -- recursive, 1 is parent boolean
		else
		return tr
		end
	end
end



function Is_Global_Preset_Stored(scr_path)
	for line in io.lines(scr_path) do
	local track_name, sett_state = line:match('^(%s*TRACK_NAME%s*=%s*)"(.-)"')
		if track_name then
		return sett_state:match('%S') and sett_state
		end
	end
end



function Store_Global_Preset(scr_path, track_name, strict_match)

-- load the settings
local setting
local sett_name = track_name and 'TRACK_NAME' or strict_match and 'STRICT_MATCH'
	for line in io.lines(scr_path) do
	setting = line:match('^%s*'..sett_name..'%s*=%s*".-"')
		if setting then break end
	end

	if setting then
	-- update
	local f = io.open(scr_path,'r')
	local cont = f:read('*a')
	f:close()
	local sett = setting:match('^(%s*'..sett_name..'%s*=%s*)".-"')
	local sett_val = track_name or strict_match
	local sett_upd = sett..'"'..sett_val..'"'
	sett_upd = sett_upd:gsub('%%', '%%%%')
	local cont, cnt = cont:gsub(Esc(setting), sett_upd, 1)
		if cnt > 0 then -- settings were updated, write to file
		local f = io.open(scr_path,'w')
		f:write(cont)
		f:close()
		return 1
		end
	end

end



function Find_Next_Global_Preset_Match(tr_name)

	local function get_next_named_track(start_idx, strict, tr_name)
		for i=start_idx, r.CountTracks(0)-1 do -- search from the next track
		local tr = r.GetTrack(0,i)
			if r.IsTrackVisible(tr, true) then -- mixer true
			local ret, name = r.GetTrackName(tr)
				if STRICT_MATCH and name == tr_name
				or not STRICT_MATCH and name:match(Esc(tr_name)) then
				local track, parent = Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr) -- parent is boolean
					if track then -- can be nil if track is inside a collapsed folder whose parent track is hidden, because in this scenario track itself cannot be visible regardless of its own visibility state
					local tr_idx = r.CSurf_TrackToID(track, false)-1 -- mcpView false to get actual track index independent of hidden tracks in the Mixer
				-- OR
				-- local tr_idx = r.CSurf_TrackToID(tr, true) -- mcpView true to get 0-based index in the Mixer accounting for preceding tracks hidden in the Mixer
						if tr_idx == start_idx or tr_idx == start_idx-1 then -- the found track turned out to be a child track in a collapsed folder, whose 1st visible (grand)parent is either the track the search has started from or immediately preceding track, i.e. the 1st visible MCP, so we've arrived back at the beginning
						-- restart search from the index which follows the found track
						return get_next_named_track(r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER'), strict, tr_name) -- using GetMediaTrackInfo_Value() or r.CSurf_TrackToID(tr, false) -- mcpView false to get actual 1-based track index independent of hidden tracks in the Mixer, equal to 0-based index of the following track
					-- OR
					-- return get_next_named_track(r.CSurf_TrackToID(tr, true)+1, strict, tr_name) -- using CSurf_TrackToID() with mcpView arg being true to calculate 0-based index of the following track in the Mixer accounting for preceding tracks hidden in the Mixer
						else
						return track, parent -- parent is boolean
						end
					end
				end
			end
		end
	end

STRICT_MATCH = STRICT_MATCH:match('%S')

-- search for the next match from the first visible MCP
local tr = Get_First_Fully_Visible_MCP()
local idx = r.CSurf_TrackToID(tr, false) -- mcpView false to get actual 1-based index, which matches 0-based index of the following track, from which the search will resume below in get_next_named_track(); mcpView true returns inaccurate index if there're preceding hidden tracks in the Mixer
-- OR
-- local idx = r.CSurf_TrackToID(tr, true)+1 -- mcpView true to get 0-based index in the Mixer accounting for preceding tracks hidden in the Mixer
local track, parent = get_next_named_track(idx, STRICT_MATCH, tr_name) -- parent is boolean

	if not track then -- search from the start of the tracklist
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
			if r.IsTrackVisible(tr, true) then -- mixer true
			local ret, name = r.GetTrackName(tr)
				if STRICT_MATCH and name == tr_name
				or not STRICT_MATCH and name:match(Esc(tr_name)) then
				track, parent = Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr)
					if track then break end
				end
			end
		end
	end


local mess
	if track == tr then
	mess = parent and 'the parent of the only visible \n\n'..space(12)..'matching track \n\n\tis already within view'
	or 'the only visible matching track \n\n\tis already within view'
	end
-- returning track even if the above message is valid, in order to still scroll
-- to it in case the Mixer is closed and the preset script is run from a custom action
-- listed in the About text of the script header under WORKFLOW TIP,
-- otherwise when the closed Mixer is opened its scroll position will be reset,
-- not sure why it is reset because simple toggling of View: Toggle Mixer visible
-- doesn't reset it, could be because of SetMixerScroll() behavior
return track, tr, parent, mess

end



function Parse_Project_Presets(preset_cnt, first_vis_mcp)
local sect = 'BUYONE_MIXER_NAVIGATION_PRESETS'
local ret, ref_GUID = r.GetSetMediaTrackInfo_String(first_vis_mcp, 'GUID', '', false) -- isSet false
local t = {}
local key = 'MIXER_NAVIGATION_PRESET '
	for i=1, preset_cnt do
	local ret, GUID = r.GetProjExtState(0, sect, key..i)
	t[i] = {ret == 1, GUID == ref_GUID}
	end
return t
end


function Parse_Global_Presets(preset_cnt, scr_path, first_vis_mcp)

	local function get_setting(scr)
	local name, strict_match
		for line in io.lines(scr) do
		name = name or line:match('^%s*TRACK_NAME%s*=%s*"(.-)"')
		strict_match = strict_match or line:match('^%s*STRICT_MATCH%s*=%s*"(.-)"')
			if strict_match then
			return name, strict_match
			end
		end
	end

local path = scr_path:match('.+[\\/]')
local scr_name = 'BuyOne_Mixer navigation preset '
local ret, ref_name = r.GetSetMediaTrackInfo_String(first_vis_mcp, 'P_NAME', '', false) -- isSet false
local t = {strict_match={}}
	for i=1, preset_cnt do
	local script = path..scr_name..i..' (global).lua'
		if r.file_exists(script) then -- since global presets, unlike pre project presets, depend on physical presence of scripts only list presets for which there're scripts
		local name, strict_match = get_setting(script)
		local active = name:match('%S') and (strict_match:match('%S') and ref_name == name or ref_name:match(Esc(name)) )
		t[#t+1] = {name or '', i, active} -- i is preset number, which may not be sequential if not all preset scripts are available
		table.insert(t.strict_match, strict_match)
		end
	end

return t

end



function Store_Clear_Recall_Preset(preset_No, global, track_name, strict_match, scr_path, menu)

local mixer_open = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible
local sect = 'BUYONE_MIXER_NAVIGATION_PRESETS' -- using section name independent of the script name so that it's uniform across the individual scripts
local key = 'MIXER_NAVIGATION_PRESET '
local scr_path = not menu and scr_path or scr_path:match('.+[\\/]')..'BuyOne_Mixer navigation preset '..preset_No..' (global).lua'
local stored, GUID = r.GetProjExtState(0, sect, key..preset_No)
stored = not global and stored == 1 or global and Is_Global_Preset_Stored(scr_path)
local track_name = global and (not menu and track_name or stored)

	if not mixer_open then -- clear preset
	local strict_match = strict_match:match('%S')
	::RELOAD::
	local mess = not stored and {'Cannot save the preset with closed Mixer.', 'INFO', 0}
	or not global and {'Wish to reset the current preset '..preset_No..'?', 'PROMPT', 1}
	or {'YES  —  Reset the current preset\n\nNO  —  '
	..(strict_match and 'Dis' or 'En')..'able strict name match setting'
	..'\n\n(it\'s recommended to configure the setting first\nand only then to reset the preset, because\n'
	..'otherwise this dialogue will only be accessible\nagain when the Mixer is open)', 'PROMPT', 3}
	local resp = mess and r.MB(table.unpack(mess))
		if resp == 2 then return -- only for global presets
		elseif stored then -- reset the preset
			if global then
			local clear_preset = resp == 6
			Store_Global_Preset(scr_path, clear_preset and '', not clear_preset and (strict_match and '' or '1'))
				if not clear_preset then strict_match = not strict_match goto RELOAD end -- flip strict_match value to update prompt text
			elseif resp == 1 then -- per project
			r.SetProjExtState(0, sect, key..preset_No, '')
			r.MB('The new preset state will become permanent\n\n\tonce the project is saved.', 'INFO', 0) -- caps, spaced true
			end
		else return -- not stored, INFO message displayed above
		end
	elseif not stored then -- store
	local tr = Get_First_Fully_Visible_MCP()
		if not tr then
		Error_Tooltip('\n\n no visible mcp was found \n\n', 1, 1) -- caps, spaced true // no visible tracks in the Mixer
		elseif global then
		local ret, name = r.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false) -- setNewValue false
			if not name:match('%S') then
			Error_Tooltip('\n\n\t'..space(4)..'the first visible \n\n track in the Mixer is unnamed, \n\n'
			..space(6)..'cannot save the preset \n\n', 1, 1) -- caps, spaced true
				if not menu then pause(2) end -- in menu script pause() is activated outside before the menu is reloaded
			else
			local strict_match = strict_match:match('%S')
			::RELOAD::
			local resp = r.MB('YES  —  Save the preset\n\nNO  —  '
			..(strict_match and 'Dis' or 'En')..'able strict name match setting'
			..'\n\n(it\'s recommended to configure the setting first\nand only then to save the preset, because\n'
			..'otherwise this dialogue will only be accessible\nagain when the Mixer is closed)', 'PROMPT', 3)
				if resp == 2 then return 1 end -- user aborted // returning 1 ensures that pause() isn't activated outside after the dialogue is closed in the menu script before the menu is reloaded
			local save_preset = resp == 6
			local ok = Store_Global_Preset(scr_path, save_preset and name, not save_preset and (strict_match and '' or '1'))
				if save_preset and not menu then
				-- only display tooltip to inform about preset status in non-menu script, because when menu is reloaded
				-- the stored track name is displayed in the preset menu item,
				-- the setting status is obvious because the dialogue is auto-reloaded with updated text above
				Error_Tooltip('\n\n '..(ok and 'the preset has been saved' or 'preset save failed')..' \n\n', 1, 1) -- caps, spaced true
				elseif not save_preset then -- reload the dialogue after setting update (resp == 7)
				strict_match = not strict_match goto RELOAD -- flip strict_match value to update prompt text
				elseif menu then return 1 -- the dialogue is exited after preset update // 1 ensures that pause() isn't activated outside after the dialogue is closed in the menu script before the menu is reloaded
				end
			end
		else -- per project
			if r.MB(space(11)..'Wish to store track '..r.CSurf_TrackToID(tr, false)..'\n\n'
			..space(9)..'in the navigation preset?', 'PROMPT', 1) == 1 then
			local ret, GUID = r.GetSetMediaTrackInfo_String(tr, 'GUID', '', false) -- setNewValue false
			r.SetProjExtState(0, sect, key..preset_No, GUID)
			end
		return 1 -- ensures that pause() isn't activated outside after the dialogue is closed in the menu script before the menu is reloaded
		end
	else -- recall
	local err
		if global then
		local target_tr, first_vis_mcp, parent, mess = Find_Next_Global_Preset_Match(track_name)
			if first_vis_mcp then
				if target_tr then -- only return if track is valid in order to otherwise prevent 'nowehere to scroll' error message outside and instead display 'visible track wasn't found' initialized at the end of this block
					if mess then
					Error_Tooltip('\n\n '..mess..' \n\n', 1,1) -- caps, spaced true
						if not menu then pause(2) end -- in menu script pause() is activated outside before the menu is reloaded
					return -- do not return track so that if it or its parent is the first fully visible they're not nudged to the left edge of the Mixer when preceded by a partially visible track
					end
				return target_tr, first_vis_mcp, parent -- returning first vis MCP as well for evaluation of the result after scrolling is applied and display of 'nowhere to scroll' and 'parent' messages
				end
			end
		else -- per project
			for i=0, r.CountTracks(0)-1 do
			local tr = r.GetTrack(0,i)
			local ret, tr_GUID = r.GetSetMediaTrackInfo_String(tr, 'GUID', '', false) -- setNewValue false
			local vis = r.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER') == 1 -- OR r.IsTrackVisible(tr, true) -- mixer true
				if tr_GUID == GUID then
					if not vis then
					-- in the Mixer the child track is also hidden when it's inside a collapsed folder whose parent is hidden
					err = 'the track is hidden'
					else
					local tr, parent = Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr)
						if tr then
						return tr, Get_First_Fully_Visible_MCP(), parent -- two last return values are first_vis_mcp and parent to generate 'nowhere to scroll' and 'parent' mesages outside
						else
					--	in the Mixer child track in a collapsed folder cannot be visible while its parent is itself hidden
					-- even if its own visibility state isn't set to hidden;
					-- for global presets in this scenario due to specifics of its functionality,
					-- i.e. earch for the next matching trrack,
					-- identical message isn't gererated, instead the 'visible track wasn\'t found' message is generated below
						err = '\tthe track is inside \n\n\ta collapsed folder \n\n whose parent track is hidden'
						end
					end
				break
				end
			end
		end
	err = err or 'visible track wasn\'t found' -- if the routine has reached this line without error, the track wasn't found
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	end

end


function Set_Mixer_Scroll()
-- The defer function is meant to ensure that presets can work when the Mixer is initially closed
-- through the use of custom action:
-- View: Toggle mixer visible
-- [script]
-- When the Mixer is just opened script does manage to make the Mixer scroll with the native SetMixerScroll() function alone but then reaper.ini settings appear to kick in and Mixer scroll reverts to position stored previously if it wasn't at the target track, this happens instantaneously and can only be noticed if the script is paused before exiting, so defer() is meant to override that by keeping the scroll pushed to the target track past the moment of reversal to reaper.ini (?) settings
-- Track pointer validation or time limiting SetMixerScroll()
-- is meant to prevent error message of invalid track when
-- the global preset is activated via the menu once and immediately activated
-- again without there being another matching track in which case no track is returned
-- and a message initialized inside Find_Next_Global_Preset_Match() is displyed instead,
-- because the defer loop seems to contiue running while the menu keeps being open,
-- the script isn't terminated, targ_tr var isn't garbage collected but assigned nil
-- at the second preset activation
--[-[
	if r.ValidatePtr(targ_tr, 'MediaTrack*') then
	r.SetMixerScroll(targ_tr)
		if r.time_precise() - time_init < .100 then r.defer(Set_Mixer_Scroll) end
	end
--]]
--[[ OR
	if r.time_precise() - time_init < .100 then
	r.defer(Set_Mixer_Scroll)
	r.SetMixerScroll(targ_tr)
	end
--]]
end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Mixer navigation presets_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[-------- NAME TESTING -------------
local t = {
'Mixer navigation preset 1 (per project)',
'Mixer navigation preset 1 (global)',
'Mixer navigation presets (menu)'
}
scr_name = t[3]
--]]------------------------------------


	if not Invalid_Script_Name(scr_name, 'navigation preset %d+', 'menu')
	or not Invalid_Script_Name(scr_name, 'project', 'global', 'menu')
	then return r.defer(no_undo) end

	if r.CountTracks(0) == 0 then
	Error_Tooltip('\n\n no tracks in the project \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local global = scr_name:match('global')
local preset_No = scr_name:match('preset (%d+)')
local menu = scr_name:match('menu')
local mixer_open = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible

	::RETRY::
	if menu then
	local first_vis_mcp = Get_First_Fully_Visible_MCP()
		if not first_vis_mcp then
		Error_Tooltip('\n\n no visible mcp was found \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo)
		end
	local proj_presets = Parse_Project_Presets(8, first_vis_mcp) -- preset_cnt arg will have to be update if the number of available presets changes
	local glob_presets = Parse_Global_Presets(8, fullpath_init, first_vis_mcp) -- same regarding preset_cnt arg
	local dot = ' \226\128\162' -- Bullet U+2022
		for k, props in ipairs(proj_presets) do
		local stored, active = props[1], props[2]
		local grayout = not stored and not mixer_open and '#' or '' -- preset item will be grayed out if preset isn't stored and the mixer is closed because there's no point in keeping it active
		proj_presets[k] = grayout..check(active)..'Preset '..k..(stored and dot or '')
		end
		for k, props in ipairs(glob_presets) do
		local name, No, active = props[1], props[2], props[3]  -- since not all global preset scripts may be present on the disk, their list in the menu may not be sequential hence their numbers are stored separately
		local grayout = not name:match('%S') and not mixer_open and '#' or '' -- preset item will be grayed out if preset isn't stored and the mixer is closed because there's no point in keeping it active
		local strict = glob_presets.strict_match[k]:match('%S') and ' #' or ''
		glob_presets[k] = grayout..check(active)..'Preset '..No..strict..(name:match('%S') and '  "'..name..'"' or '')
		end
	local menu = 'MIXER NAVIGATION PRESETS|||PROJECT PRESETS||'..table.concat(proj_presets,'|')..'||GLOBAL PRESETS||'
	..(#glob_presets > 0 and table.concat(glob_presets,'|') or '#global preset scripts weren\'t found')-- global presets may be unavailable if their scripts are absent on the disk at the META script path
	local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true
		if output == 0 then return r.defer(no_undo)
		elseif output < 3 or output == 11 then -- menu labels
		goto RETRY
		else
		global = output > 11
		local t = output < 11 and proj_presets or glob_presets
		output = output < 11 and output-2 or output-11
		preset_No = t[output]:match('%d+') -- retrieving preset number from its name because not all global presets may be listed in the menu if not all global preset scripts are available and menu index won't match the actual preset number
		STRICT_MATCH = global and t.strict_match[output]
		end
	end


targ_tr, first_vis_mcp, parent = Store_Clear_Recall_Preset(preset_No, global, TRACK_NAME, STRICT_MATCH, fullpath_init, menu) -- keeping global so that targ_tr is accessible inside defer function Set_Mixer_Scroll()

	if type(targ_tr) == 'userdata' then
	time_init = r.time_precise()
	Set_Mixer_Scroll()
	end


local mess1 = parent and 'parent track' or ''
local cur_first_vis_mcp = Get_First_Fully_Visible_MCP()
local to_select = type(targ_tr) == 'userdata' and not r.IsTrackSelected(targ_tr) and 'the track has been selected'
local mess2 = first_vis_mcp and cur_first_vis_mcp == first_vis_mcp
and (to_select and '\t' or '')..'nowhere to scroll'..(to_select and ' \n\n the track has been selected' or '') or ''

	if type(targ_tr) == 'userdata' and (#mess2 > 0 or targ_tr ~= cur_first_vis_mcp) then -- select track which cannot be scrolled to the leftmost position
	r.SetOnlyTrackSelected(targ_tr)
	end

	if #mess1 > 0 or #mess2 > 0 then
	local br = #mess1 > 0 and #mess2 > 0 and ' \n\n ' or ''
	Error_Tooltip('\n\n '..(space(#br > 0 and 4)..mess1..br..mess2)..' \n\n', 1, 1, 20) -- caps, spaced true, x = 20 to move the tooltip away from the mouse cursor because it blocks clicks
	end

	if menu then
		if not targ_tr and mixer_open or parent or #mess2 > 0 then
		pause(2) -- pause to allow the message above to stick around longer before it's obscured by the reloaded menu
		end
	goto RETRY
	end

do return r.defer(no_undo) end

