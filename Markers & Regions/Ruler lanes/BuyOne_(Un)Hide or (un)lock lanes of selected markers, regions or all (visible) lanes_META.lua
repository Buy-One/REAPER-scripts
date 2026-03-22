--[[
ReaScript name: BuyOne_(Un)Hide or (un)lock lanes of selected markers, regions or all (visible) lanes_META.lua (18 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v7.62
Provides: 	[main=main,midi_editor] .
				. > BuyOne_Hide lanes of selected markers, regions.lua
				. > BuyOne_Lock lanes of selected markers, regions.lua
				. > BuyOne_Unlock lanes of selected markers, regions.lua
				. > BuyOne_Toggle lock lanes of selected markers, regions.lua
				. > BuyOne_Hide all Ruler lanes.lua
				. > BuyOne_Unhide all Ruler lanes.lua
				. > BuyOne_Lock all visible Ruler lanes.lua
				. > BuyOne_Unlock all visible Ruler lanes.lua
				. > BuyOne_Toggle lock all visible Ruler lanes.lua
				. > BuyOne_Hide empty Ruler lanes.lua
				. > BuyOne_Hide markers only Ruler lanes
				. > BuyOne_Hide regions only Ruler lanes
				. > BuyOne_Unhide markers only Ruler lanes
				. > BuyOne_Unhide regions only Ruler lanes
				. > BuyOne_Hide non-empty lanes without selected markers, regions
				. > BuyOne_Lock non-empty lanes without selected markers, regions
				. > BuyOne_Unlock non-empty lanes without selected markers, regions
				. > BuyOne_Toggle lock non-empty lanes without selected markers, regions
About: 	If this script name is suffixed with META, when 
			executed it will automatically spawn all individual 
			scripts included in the package into the directory 
			of the META script and will import them into the 
			Action list from that directory.

			If there's no META suffix in this script name it will 
			perfom the operation indicated in its name.

			In 'Toggle lock' scripts locking is toggled to off
			if at least one lane is locked.
			
			In '(Unhide) markers/regions only Ruler lanes' scripts
			a lane is valid as long as the object of the corresponding
			type isn't hidden on it, i.e. if all markers are hidden
			on a markers only lane, then even though there're no regions 
			on it, such lane still won't be considered valid for the 
			script.

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
			for _, sectID in ipairs{0,32060,32062} do -- Main, MIDI Ed, Media Ex // per script list
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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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
			if scr_name:lower():match(Esc(elm:lower())) then return elm end -- at least one match was found
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



function Get_Ruler_Lane_Count(hide, lock, unlock, toggle, empty)
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

r.PreventUIRefresh(1)
local index = r.AddProjectMarker(0, false, 0, 0, '', 0xFFFF) -- isrgn false, pos 0, rgnend 0, wantidx 0xFFFF, to be able to easily find it for deletion // insert temp marker
local obj = r.GetRegionOrMarker(0, 0, '') -- index 0, guidStr empty
r.SetRegionOrMarkerInfo_Value(0, obj, 'B_HIDDEN', 1) -- hide, although not strictly necessary thanks to PreventUIRefresh()
local lane_idx_init = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
local lane_count
	for i=100,0,-1 do
	r.SetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER', i)
	local lane_idx = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
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
lane_count = (lane_count or lane_idx_init)+1 -- +1 because lane index returned by GetRegionOrMarkerInfo_Value is 0-based

local GetSet = r.GetSetProjectInfo
local t = {}
	for i=0, lane_count-1 do
	local vis = GetSet(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0
	local locked = GetSet(0, 'RULER_LANE_LOCKED:'..i, 0, false) == 1
		if (hide or lock and not locked or unlock and locked or toggle) and vis
		or not hide and not lock and not unlock and not vis -- for hide, lock or unlock only visible lanes are relevant, for unhide obviously hidden are
		then
		t[i] = ''
			if not empty then -- not needed in 'hide empty lanes' script where because of these fields next(t) is likely to produce false positive at error messages display stage
			t.locked = t.locked or locked -- store to determine toggle direction			
			t.count = lane_count -- store within the loop to prevent false positive at error messages display stage produced by next(t) in the case of storing outside of the loop while there're no visible lanes
			end			
		end
	end

return t

end




function Collect_Lanes_Of_Visible_Selected_Mrkrs_Regns(hide, lock, unlock, toggle, empty, lanes_t, only, markers, without)

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local GetSet = r.GetSetProjectInfo
local t = {}

	for i=0, r.GetNumRegionsOrMarkers(0)-1 do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local lane_idx = Get(0, obj, 'I_LANENUMBER')
	local lane_vis = GetSet(0, 'RULER_LANE_HIDDEN:'..lane_idx, 0, false) == 0 -- isSet false // the attribute works without the colon as well // for scripts other than 'only', essentially redundant because B_VISIBLE is also false when the entire lane is hidden

		if lanes_t then -- lanes_t will be valid when empty var is
		lanes_t[lane_idx] = nil -- in 'hide empty lanes' script exclude lanes with objects for evaluation whether there're any empty lanes at the error message display stage to prevent running the main action and creating undo point when there're none
		end
	
		if only and (hide and lane_vis or not hide and not lane_vis) then -- only var goes along with markers var, hidden lanes are supported, the action (hide/unhide) is determined in the main routine
		t[lane_idx] = t[lane_idx] or {}
		local vis = Get(0, obj, 'B_HIDDEN') == 0 -- independent of lane visibility status, unlike B_VISIBLE
		local reg = Get(0, obj, 'B_ISREGION') == 1
			if vis and reg then
			t[lane_idx].r = '' -- region exist on the lane
			elseif vis and not reg then
			t[lane_idx].m = '' -- marker exists on the lane
			end
		elseif not only then
		local lane_locked = GetSet(0, 'RULER_LANE_LOCKED:'..lane_idx, 0, false) == 1
		local vis = Get(0, obj, 'B_VISIBLE') == 1
		local sel = Get(0, obj, 'B_UISEL') == 1
			if lane_vis and vis and (empty or without or sel) -- when looking for empty lanes or lanes without selected objects selection is irrelevant
			and (lock and not lane_locked or unlock and lane_locked or toggle or hide)
			then
				if not without then
				t[lane_idx] = '' -- valid lane
				t.locked = t.locked or lane_locked -- store to determine toggle direction
					if hide then -- when hiding lanes also deselect object
					r.SetRegionOrMarkerInfo_Value(0, obj, 'B_UISEL', 0)
					end
				else
				t[lane_idx] = t[lane_idx] or {}
					if sel then
					t[lane_idx].s = '' -- lane woth selected object
					end
				end				
			end
		end
	end
	
	if only then
	-- for lanes with mixed and incompatible object types nil is stored 
	-- so that next(t) at error message display stage evaluates to false
	-- when there're lanes with no content compatible with the scripts;
	-- markers/regions only lanes on which all objects are hidden
	-- are regarded as incompatible
	-- OBJECTS AREN'T DESELECTED WHEN LANES GET HIDDEN, ALTHOUGH IDEALLY THEY SHOULD BE
		for lane_idx, obj_type_t in pairs(t) do
		local m, r = obj_type_t.m, obj_type_t.r			
			if r and m or not r and not m
			or markers and r or not markers and m then
			t[lane_idx] = nil -- invalidate lane with incompatible content
			end
		end
	elseif without then	
	local locked -- declate outside to only store within the table if there're valid lanes; if added to the table in advance next(t) at the error message display stage will produce false positive; besides that, adding a field to the associative array during the loop interrupts it
		for lane_idx, sel_obj_t in pairs(t) do
			if type(sel_obj_t) == 'table' then  -- evaluating whether table to prevent error when this happens to be 'locked' field created below
				if sel_obj_t.s then				
				t[lane_idx] = nil -- invalidate lane with selected object
				else
				-- store to determine toggle direction
				locked = locked or GetSet(0, 'RULER_LANE_LOCKED:'..lane_idx, 0, false) == 1
				end
			end
		end
		if next(t) then -- only store within the table if there're valid lanes so that next(t) at the error message display stage doesn't produce false positive
		t.locked = locked
		end
	end

return t

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts


	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_(Un)Hide or (un)lock lanes of selected markers, regions or all (visible) lanes_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[-------- NAME TESTING ------------
local t = {
'Hide lanes of selected markers, regions',
'Lock lanes of selected markers, regions',
'Unlock lanes of selected markers, regions',
'Toggle lock lanes of selected markers, regions',
'Hide all Ruler lanes',
'Unhide all Ruler lanes',
'Lock all visible Ruler lanes',
'Unlock all visible Ruler lanes',
'Toggle lock all visible Ruler lanes',
'Hide empty Ruler lanes',

'Hide markers only Ruler lanes',
'Hide regions only Ruler lanes',
'Unhide markers only Ruler lanes',
'Unhide regions only Ruler lanes',

'Hide non-empty lanes without selected markers, regions',
'Lock non-empty lanes without selected markers, regions',
'Unlock non-empty lanes without selected markers, regions',
'Toggle lock non-empty lanes without selected markers, regions'
}
scr_name = t[9]
--]]-----------------------------------


	if not Invalid_Script_Name(scr_name, 'unhide', 'hide', 'unlock', 'lock', 'toggle lock')
	or not Invalid_Script_Name(scr_name, 'selected', 'ruler lanes')
	then return r.defer(no_undo) end

scr_name = scr_name:lower()
local hide = scr_name:match('^hide')
local unhide = scr_name:match('unhide')
local lock = scr_name:match('^lock') or scr_name:match(' lock')
local unlock = scr_name:match('unlock')
local sel = scr_name:match('selected')
local toggle = scr_name:match('^toggle')
local empty = scr_name:match(' empty') -- preceded with space to disambiguate from non-empty
local only = scr_name:match('only')
local markers = scr_name:match('markers')
local without = scr_name:match('without')

local lanes_t = not sel and not only and Get_Ruler_Lane_Count(hide, lock, unlock, toggle, empty)
local obj_vis_lanes_t = (sel or empty or only) and Collect_Lanes_Of_Visible_Selected_Mrkrs_Regns(hide, lock, unlock, toggle, empty, lanes_t, only, markers, without) -- lanes_t is valid in 'empty' scripts where obj_vis_lanes_t is only used for reference in the main loop
local no_vis_lanes = 'no %svisible lanes'
local no_vis_obj = without and '    no visible populated \n\n\t    lanes without \n\n selected markers/regions ' or 'no visible selected \n\n   markers/regions'
local already = without and ' \n\n or they\'re already ' or ' \n\n    or their lanes \n\n are already '
local err = only and not next(obj_vis_lanes_t) and 'no '..(hide and 'visible ' or 'hidden ')..(markers or 'regions')..' only lanes' 
or not sel and not toggle and lanes_t and not next(lanes_t) and (empty and 'no visible empty lanes' or hide and no_vis_lanes:format('')
or unhide and 'no hidden lanes' or lock and no_vis_lanes:format('unlocked ') or unlock and no_vis_lanes:format('locked '))
or sel and not only and not next(obj_vis_lanes_t) and ((not toggle and hide or toggle and lock) and no_vis_obj
or lock and no_vis_obj..already..'locked' -- when lanes are locked selection with mouse isn't possible howeber already selected objects stay selected after locked and they still can be elected via API on locked lanes, so the error message addresses this unlikely scenario
or unlock and no_vis_obj..already..'unlocked')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local t = lanes_t or obj_vis_lanes_t -- depends on script action, lanes_t will be false in scripts which target lanes of selected objects and lanes without selected objects; obj_vis_lanes_t will be false in scripts which target all lanes or only lanes with objects of certain type, both will be valid in hide empty lanes script, but obj_vis_lanes_t is only used for reference in it

r.Undo_BeginBlock()

local parm = (hide or unhide) and 'HIDDEN:' or (lock or unlock or toggle) and 'LOCKED:'

	for lane_idx in pairs(t) do		
	local do_unlock = toggle and t.locked -- determines toggle direction	
	local cur_val = r.GetSetProjectInfo(0, 'RULER_LANE_'..parm..lane_idx, 0, false) -- is_set false
	local val = do_unlock and 0 or toggle and cur_val~1 or (hide or lock) and 1 or 0 -- last value is for unhide/unlock
		if val ~= cur_val and not empty
		or empty and not obj_vis_lanes_t[lane_idx]
		or only and t[lane_idx]
		then
		-- ensuring that lane_idx is not the 'locked' field which makes no sense for the function
		local set = tonumber(lane_idx) and r.GetSetProjectInfo(0, 'RULER_LANE_'..parm..lane_idx, val, true) -- is_set true
		end
	end

r.Undo_EndBlock(scr_name,-1)

