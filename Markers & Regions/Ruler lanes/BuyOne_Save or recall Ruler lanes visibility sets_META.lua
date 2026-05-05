--[[
ReaScript name: BuyOne_Save or recall Ruler lanes visibility sets_META.lua (13 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog:	#Added support for lane set storage based on lane GUID since REAPER build 7.71
			#Fixed lane set visibility evaluation for indicator display in sets menu
			#Updated 'About' text
Licence: WTFPL
REAPER: at least v7.62, but v7.71 and later are recommended
Provides: 	[main=main,midi_editor] .
			. > BuyOne_Save Ruler lanes visibility set 1.lua
			. > BuyOne_Save Ruler lanes visibility set 2.lua
			. > BuyOne_Save Ruler lanes visibility set 3.lua
			. > BuyOne_Save Ruler lanes visibility set 4.lua
			. > BuyOne_Save Ruler lanes visibility set 5.lua
			. > BuyOne_Save Ruler lanes visibility set 6.lua
			. > BuyOne_Recall Ruler lanes visibility set 1.lua
			. > BuyOne_Recall Ruler lanes visibility set 2.lua
			. > BuyOne_Recall Ruler lanes visibility set 3.lua
			. > BuyOne_Recall Ruler lanes visibility set 4.lua
			. > BuyOne_Recall Ruler lanes visibility set 5.lua
			. > BuyOne_Recall Ruler lanes visibility set 6.lua
			. > BuyOne_Save and recall Ruler lanes visibility sets (menu).lua
About: 	If this script name is suffixed with META, when 
		executed it will automatically spawn all individual 
		scripts included in the package into the directory 
		of the META script and will import them into the 
		Action list from that directory.

		If there's no META suffix in this script name it will 
		perfom the operation indicated in its name.

		To save a lane visibility set select at least one
		marker/region on lanes you wish to save into a set.

		In builds older than 7.71 lane storage is based on custom 
		lane names, because lane name in those builds are the only 
		property which lends lane a unique identity. For this 
		reason unnamed lanes cannot be saved into a set and it's 
		strongly advised to avoid giving same names to different 
		lanes, because on set recall all lanes which match the 
		saved name will be shown, even if only one such lane was 
		targeted at the storage stage.  
		Renaming lanes saved in a set is also discouraged 
		because these won't be recalled. Or after renaming one
		the set must be re-saved.  
		These limitations don't apply to sets storage and recall 
		inside REAPER build 7.71 and later.			
		
		Lanes order isn't saved with a set, they load in their
		current relative order determined inside Ruler Lane Manager.

		Sets are project specific. To make sure new or updated 
		set is retained for future use the project must be saved.

		If you need more than 6 sets, add as many script name
		entries to the list under 'Provides:' tag in the META 
		script header copying the format of other entries, and 
		execute it so it spawns new files. However for the script  
		BuyOne_Save and recall Ruler lanes visibility sets (menu).lua
		to include more sets, modification of the code is
		required.

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end



local r = reaper


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

	local path = fullpath:match('(.+[\\/])')

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
			for _, sectID in ipairs{0,32060,32063} do -- Main, MIDI Ed, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end



function no_undo()
do return end
end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
end



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function space(num)
return (' '):rep(num)
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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(Esc(elm:lower()))
			or scr_name:lower():match(elm) -- in case pattern is used
			then return elm end -- at least one match was found
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




function REAPER_Ver_Check(build, want_later, want_earlier, want_current)
-- build is REAPER build number or sring, the function must be followed by 'do return end'
-- want_later, want_earlier and want_current are booleans
-- obviously want_later and want_earlier are mutually exclusive
-- want_later includes current, want_earlier is the up-to version
local build = build and tonumber(build)
local cur_buld = tonumber(r.GetAppVersion():match('[%d%.]+'))
local later, earlier, current = cur_buld >= build, cur_buld < build, cur_buld == build
local err = '   the script requires \n\n  '
local err = want_later and not later and err..'reaper '..build..' and later '
or want_earlier and not earlier and err..'reaper no later than '..build
or want_current and not current and 'reaper build '..build
	if err then
--[[
	local x,y = r.GetMousePosition()
	err = err:upper():gsub('.','%0 ')
	r.TrackCtl_SetToolTip(err, x, y+10, true) -- topmost true
--]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return true
	end -- 'ReaScript:Run' caption is displayed in the menu bar but no actual undo point is created because Undo_BeginBlock() isn't yet initialized, here and elsewhere
end



function Get_Saved_Sets()
local i, t = 0, {}
	repeat
	local ret, set, content = r.EnumProjExtState(0, 'BUYONE RULER LANE VISIBILITY SETS', i)
		if ret then
		t[set:match('%d+')+0] = content
		end
	i=i+1
	until not ret
return t
end



function Get_Sets_Status(saved_sets_t, lane_count)
-- saved_sets_t stems from Get_Saved_Sets()
-- lane_count stems from Get_Ruler_Lane_Count(), for restoration stage

local t = {} -- using new table because saved_sets_t will be needed for conditioning of menu indicators for save actions
	
	-- parse sets into tables
	for set_idx, set in pairs(saved_sets_t) do
	t[set_idx] = {}
		for ID in set:gmatch('[^\n]+') do
		local ID = ID and ID:match('LANE%d+:(.+)')
			if ID then
			table.insert(t[set_idx], ID)
			end
		end
	end
	
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.71 -- support for lane GUID was added which obviates reliance on lane names as the source of their identity
local PARM = old_build and 'RULER_LANE_NAME:' or 'RULER_LANE_GUID:'
	
	-- evaluate equality against visible lanes
--[[ -- THIS EVALUATES TO TRUTH WHEN ALL LANES FROM THE SET ARE VISIBLE, BY ITSELF OR AMONG OTHER UNRELARED LANES
	for set_idx, set in pairs(t) do
	local match_count = 0
		for k, ID in ipairs(set) do
			for i=0, lane_count-1 do
				if r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0 then -- isSet false // visible lane
				local ret, lane_ID = r.GetSetProjectInfo_String(0, PARM..i, '', false) -- is_set false
					if lane_ID == ID then -- one match is enough
					match_count = match_count+1
					end
				end
			end		
		end
	t[set_idx] = match_count == #set and not stray_lane
	end
	--]]
	-- THIS EVALUATES TO TRUTH WHEN ONLY LANES FROM THE SET ARE VISIBLE AND NOTHING ELSE
	for set_idx, set in pairs(t) do
	local all_match
		for i=0, lane_count-1 do
			if r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0 then -- isSet false // visible lane
			local ret, lane_ID = r.GetSetProjectInfo_String(0, PARM..i, '', false) -- is_set false
				if lane_ID:match('%S') then
					for k, ID in ipairs(set) do
					all_match = nil -- reset at each cycle because being an upvalue the var won't be reset if were true at least once
						if lane_ID == ID then
						all_match = 1
						break	
					--	else -- same as resetting at the cycle start above
					--	all_match = nil -- reset because being an upvalue the var won't be reset if were true at least once
						end
					end
					if not all_match then break end -- at least one lane name isn't found in the set, exit lanes loop
				end				
			end
		end
	t[set_idx] = all_match
	end

return t

end



function Collect_Lanes_Of_Visible_Selected_Mrkrs_Regns()

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local t = {}

	for i=0, r.GetNumRegionsOrMarkers(0)-1 do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local lane_idx = Get(0, obj, 'I_LANENUMBER')
	local lane_vis = r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..lane_idx, 0, false) == 0 -- isSet false // the attribute works without the colon as well // essentially redundant because B_VISIBLE is also false when the entire lane is hidden
		if lane_vis and Get(0, obj, 'B_VISIBLE') == 1 and Get(0, obj, 'B_UISEL') == 1	then
		t[lane_idx] = '' -- use lane_idx as key to only collect unique lanes in case several objects are selected on the same lane
		end
	end

return t

end



function Save_Recall_Set(set, lane_count, lanes_t)
-- lane_count stems from Get_Ruler_Lane_Count(), for restoration stage
-- lanes_t stems from Collect_Lanes_Of_Visible_Selected_Mrkrs_Regns(), for storage stage

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62
	
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.71 -- support for lane GUID was added which obviates reliance on lane names as the source of their identity
local PARM = old_build and 'RULER_LANE_NAME:' or 'RULER_LANE_GUID:'

local section = 'BUYONE RULER LANE VISIBILITY SETS'

	if lanes_t then -- save	
	local lane_count, stored_count = 0,0
		for lane_idx in pairs(lanes_t) do
		lane_count = lane_count+1
		local ret, lane_ID = r.GetSetProjectInfo_String(0, PARM..lane_idx, '', false) -- is_set false
			if lane_ID:match('%S') then
			lanes_t[lane_idx] = lane_ID
			stored_count = stored_count+1
			end
		end
		if old_build and lane_count ~= stored_count then
		local all = stored_count == 0
		local resp = r.MB((all and space(7)..'All' or space(4)..'Some')..' lanes seem to be unnamed.\n\n  Those cannot be saved into the set.'
		..(not all and '\n\n'..space(9)..'Wish to save without them?' or ''), 'WARNING', all and 0 or 1)
			if all or resp == 2 then return end
		end
	local data, count = '', 0
		for lane_idx, lane_ID in pairs(lanes_t) do
			if #lane_ID > 0 then
			count = count+1
			data = data..'LANE'..count..':'..lane_ID..'\n' -- lane numbers are immaterial because they don't represent either their indices or their order, used only for convenience
			end
		end
		if #data > 0 then
		r.SetProjExtState(0, section, 'LANESET'..set, data:sub(1,-2)) -- -2 removing trailing new line
		end
	return true
	else -- recall data
	local ret, set = r.GetProjExtState(0, section, 'LANESET'..set)
		if ret == 0 then return -- no stored set under this number
		else -- find lane indices
		local t = {IDs={}, indices={}}
			for ID in set:gmatch('[^\n]+') do
			local ID = ID and ID:match('LANE%d+:(.+)')
				if ID then
				t.IDs[ID] = ''
				end
			end	
			for i=0, lane_count-1 do
			local ret, ID = r.GetSetProjectInfo_String(0, PARM..i, '', false) -- is_set false
				if t.IDs[ID] then -- in old builds where storage is based on lane name, lanes with identical names will all be included regardless of which was originally saved
				t.indices[i] = ''
				end
			end
		return t.indices
		end
	end

end





function Get_Ruler_Lane_Count() -- used inside Load_Lane_Set()
-- since as of build 7.65 lane count isn't accessible via API
-- the function uses a hack of creating a temp marker
-- and force moving it to another lane starting from lane
-- at index 100
-- if lane at the destination index doesn't exist the marker
-- is not moved and its original lane index remains the same,
-- but it's moved as soon as a valid lane index is found
-- and since the movement is attempted in reverse,
-- the first lane index associated with successful movement
-- will be the index of the last available lane

	-- only supported since build 7.62
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end
	-- OR
	-- if not r.GetRegionOrMarker then return end
	
	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.71 then
	return r.GetSetProjectInfo(0, 'RULER_LANE_COUNT', 0, false) -- is_set false
	else
	r.PreventUIRefresh(1)
	local index = r.AddProjectMarker(0, false, 0, 0, '', 0xFFFF) -- isrgn false, pos 0, rgnend 0, wantidx 0xFFFF, to be able to easily find it for deletion // insert temp marker
	local obj = r.GetRegionOrMarker(0, 0, '') -- index 0, guidStr empty
	r.SetRegionOrMarkerInfo_Value(0, obj, 'B_HIDDEN', 1) -- hide, although not strictly necessary thanks to PreventUIRefresh()
	local parm = 'I_LANENUMBER'
	local lane_idx_init = r.GetRegionOrMarkerInfo_Value(0, obj, parm)
	local lane_count
		for i=100,0,-1 do
		r.SetRegionOrMarkerInfo_Value(0, obj, parm, i)
		local lane_idx = r.GetRegionOrMarkerInfo_Value(0, obj, parm)
			if lane_idx ~= lane_idx_init then
			-- if the very last lane is default for markers, the temp marker will be inserted there
			-- and during the loop will only be able to move to a lane at a lower index
			-- in which case fall back on the original lane index as the heighest
			lane_count = lane_idx < lane_idx_init and lane_idx_init or lane_idx
			break
			end
		end
	r.DeleteProjectMarker(0, index, false) -- isrgn false // delete temp marker
	--r.UpdateTimeline() -- required for proper UI update after change, but unnecessary due to PreventUIRefresh()
	r.PreventUIRefresh(-1)

	-- if there's one lane only the temp marker won't be able to move anywhere
	-- hence fall back on its original lane index
	return (lane_count or lane_idx_init)+1 -- +1 because lane index returned by GetRegionOrMarkerInfo_Value is 0-based
	end

end



function Load_Lane_Set(lane_set_t, lane_count)
-- lane_set_t stems from Save_Recall_Set()
-- lane_count stems from Get_Ruler_Lane_Count()

local GetSet = r.GetSetProjectInfo
local parm = 'RULER_LANE_HIDDEN:'

-- first hide all
	for i=0,lane_count-1 do
	local vis = GetSet(0, parm..i, 0, false) == 0
		if vis and not lane_set_t[i] then -- hide if not lane from the set
		GetSet(0, parm..i, 1, true) -- isSet true
		end
	end

-- unhide lanes of the set
	for lane_idx in pairs(lane_set_t) do
	local vis = GetSet(0, parm..lane_idx, 0, false) == 0
		if not vis then -- unhide
		GetSet(0, parm..lane_idx, 0, true) -- isSet true
		end
	end

end




Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button


	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Save or recall Ruler lanes visibility sets_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[-[-------- NAME TESTING ------------
local t = {
'Save Ruler lanes visibility set 1',
'Recall Ruler lanes visibility set 1',
'Save and recall Ruler lanes visibility sets (menu)'
}
scr_name = t[3]
--]]-----------------------------------


	if not Invalid_Script_Name(scr_name, 'save', 'recall')
	or not Invalid_Script_Name(scr_name, 'set %d+', 'menu')
	then return r.defer(no_undo) end

local menu = scr_name:match('menu')
local lane_count = (menu or not save) and Get_Ruler_Lane_Count()

::RELOAD::

local MENU = ''

	if menu then
	local saved_sets_t = menu and Get_Saved_Sets()
	local sets_status_t = menu and Get_Sets_Status(saved_sets_t, lane_count)
	local dot = ' \226\128\162' -- Bullet U+2022
		for i=1,12 do
		 MENU =  MENU..(#MENU == 0 and '' or i == 7 and '|||' or '|')
		..(i < 7 and 'Save' or 'Recall')..' Ruler lanes set '
		..(i < 7 and i or i-6)..((saved_sets_t[i] or sets_status_t[i-6]) and dot or '') -- both saved_sets_t and sets_status_t can include a max of fields because that's the max number of sets
		end
	MENU = ('RULER LANE SETS'):gsub('.','%0 ')..'||'..MENU
	end

local output = menu and Reload_Menu_at_Same_Pos(MENU, 1) -- keep_menu_open true

	if output == 0 then return -- menu exited
	elseif output then
		if output == 1 then goto RELOAD end -- title was clicked
	output = output-1 -- offset menu title
	end


save = output and output < 7 or not output and scr_name:match('Save')
set = output and (output > 6 and output-6 or output) or scr_name:match('%d+')
set = math.floor(set+0) -- trim trailing decimal 0 left fron the output value
--Msg(save, 'save') Msg(set)
local lanes_t = save and Collect_Lanes_Of_Visible_Selected_Mrkrs_Regns()

	if save and not next(lanes_t) then
	Error_Tooltip('\n\n no visible selected \n\n   markers/regions \n\n', 1, 1) -- caps, spaced true
	pause(1.5)
		if menu then goto RELOAD end
	return r.defer(no_undo) end

local set_t = Save_Recall_Set(set, not save and lane_count, save and lanes_t) -- returns set table in recall scripts

	if save and not set_t then -- user declined to save set without unnamed lanes
		if menu then goto RELOAD end
	return r.defer(no_undo) end


	if not save then -- load

	local err = not set_t and 'no saved lane set '..set
	or not next(set_t) and 'contents of lane set '..set..' \n\n\tweren\'t found'

		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
		pause(1.5)
			if menu then goto RELOAD end
		return r.defer(no_undo) end

	r.PreventUIRefresh(1)
	r.Undo_BeginBlock()

	Load_Lane_Set(set_t, lane_count)

	r.Undo_EndBlock(scr_name,-1)
	r.PreventUIRefresh(-1)

	end

	if menu then goto RELOAD end


